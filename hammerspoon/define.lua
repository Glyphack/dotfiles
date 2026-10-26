-- Floating English dictionary panel. The panel is a web view that renders
-- define.html, which talks back to this module over a message port.
-- Everything is read from macOS itself through JavaScript for Automation run
-- inside Hammerspoon: autocomplete and spelling corrections come from the
-- system spell checker, and meanings, synonyms and antonyms come from the
-- dictionaries installed for Dictionary.app (the New Oxford American
-- Dictionary and the Oxford American Writer's Thesaurus). The page receives
-- the raw entry XML and turns it into the view.

---@class Define
local define = {}

local PANEL_SIZE = hs.geometry.size(1040, 640)
local SCREEN_MARGIN = 60
local MESSAGE_PORT = "define"
local MAX_GUESSES = 6
local MAX_COMPLETIONS = 12
local MAX_NOT_FOUND_SUGGESTIONS = 8

local moduleDir = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$") or "."
local PAGE_PATH = moduleDir .. "/define.html"

-- Asks the macOS English spell checker about one piece of text and returns a
-- JSON string with whether it is misspelled, likely corrections, and ranked
-- completions of it as a word prefix. The placeholders are the text as a
-- JavaScript string literal, then the two list limits.
local SPELL_SCRIPT = [[
ObjC.import("AppKit");
(function (text, maxGuesses, maxCompletions) {
	function toArray(list, limit) {
		var items = [];
		if (!list || list.isNil()) {
			return items;
		}
		var count = Math.min(list.count, limit);
		for (var i = 0; i < count; i++) {
			items.push(ObjC.unwrap(list.objectAtIndex(i)));
		}
		return items;
	}
	var checker = $.NSSpellChecker.sharedSpellChecker;
	var str = $(text);
	var range = $.NSMakeRange(0, str.length);
	var wordCount = Ref();
	var bad = checker.checkSpellingOfStringStartingAtLanguageWrapInSpellDocumentWithTagWordCount(
		str, 0, "en", false, 0, wordCount
	);
	var guesses = checker.guessesForWordRangeInStringLanguageInSpellDocumentWithTag(range, str, "en", 0);
	var completions = checker.completionsForPartialWordRangeInStringLanguageInSpellDocumentWithTag(range, str, "en", 0);
	return JSON.stringify({
		text: text,
		misspelled: bad.length > 0,
		guesses: toArray(guesses, maxGuesses),
		completions: toArray(completions, maxCompletions),
	});
})(%s, %d, %d)
]]

-- Looks a word up in the Dictionary.app dictionaries and returns a JSON
-- string with the matching entries as XML: "entries" from the dictionary and
-- "thesaurus" from the thesaurus. Records whose headword is the word itself
-- win; when none match that way, every record the dictionary returned is
-- kept, which is how an inflected form such as "ran" reaches "run". The
-- placeholder is the word as a JavaScript string literal.
local DICTIONARY_SCRIPT = [=[
ObjC.import("CoreServices");
ObjC.bindFunction("DCSCopyAvailableDictionaries", ["id", []]);
ObjC.bindFunction("DCSDictionaryGetName", ["id", ["id"]]);
ObjC.bindFunction("DCSCopyRecordsForSearchString", ["id", ["id", "id", "unsigned long", "unsigned long"]]);
ObjC.bindFunction("DCSRecordCopyData", ["id", ["id", "unsigned long"]]);
ObjC.bindFunction("DCSRecordGetHeadword", ["id", ["id"]]);
(function (word) {
	var EXACT_MATCH = 0;
	var XML_FORMAT = 0;
	var SOURCES = [
		{ key: "entries", pattern: /New Oxford American Dictionary/ },
		{ key: "thesaurus", pattern: /Oxford American Writer.s Thesaurus/ },
	];
	function recordsOf(dictionary) {
		var list = $.DCSCopyRecordsForSearchString(dictionary, $(word), EXACT_MATCH, 0);
		var records = [];
		if (!list || list.isNil()) {
			return records;
		}
		for (var i = 0; i < list.count; i++) {
			var record = list.objectAtIndex(i);
			records.push({
				headword: $.DCSRecordGetHeadword(record).js,
				xml: $.DCSRecordCopyData(record, XML_FORMAT).js,
			});
		}
		var wanted = word.toLowerCase();
		var same = records.filter(function (r) { return r.headword.toLowerCase() === wanted; });
		return same.length > 0 ? same : records;
	}
	var result = { word: word, entries: [], thesaurus: [] };
	var dictionaries = $.DCSCopyAvailableDictionaries().allObjects;
	for (var i = 0; i < dictionaries.count; i++) {
		var dictionary = dictionaries.objectAtIndex(i);
		var name = $.DCSDictionaryGetName(dictionary).js;
		SOURCES.forEach(function (source) {
			if (source.pattern.test(name)) {
				result[source.key] = recordsOf(dictionary);
			}
		});
	}
	return JSON.stringify(result);
})(%s)
]=]

local log = hs.logger.new("define", "info")

define.webview = nil
define.speaker = nil
define.lookupSeq = 0
define.previousWindow = nil

local function readPage()
	local file, err = io.open(PAGE_PATH, "r")
	if not file then
		error("define page missing: " .. tostring(err))
	end
	local html = file:read("a")
	file:close()
	return html
end

local function jsString(text)
	local escaped = text:gsub('[%c"\\]', function(c)
		return string.format("\\u%04x", c:byte())
	end)
	return '"' .. escaped .. '"'
end

local function runScript(script, label)
	local ok, result = hs.osascript.javascript(script)
	if not ok or type(result) ~= "string" then
		log.wf("%s failed: %s", label, tostring(result))
		return nil
	end
	return hs.json.decode(result)
end

-- Returns the spell checker's view of text as a table with the keys text,
-- misspelled, guesses and completions, or nil when the check fails.
function define:spellCheck(text)
	local script = string.format(SPELL_SCRIPT, jsString(text), MAX_GUESSES, MAX_COMPLETIONS)
	return runScript(script, "spell check")
end

-- Returns the dictionary and thesaurus records for word as a table with the
-- keys word, entries and thesaurus, or nil when the lookup fails.
function define:dictionaryLookup(word)
	return runScript(string.format(DICTIONARY_SCRIPT, jsString(word)), "dictionary lookup")
end

function define:sendToPage(fn, payload)
	if not self.webview then
		return
	end
	local script = "window.defineApp && defineApp." .. fn .. "(" .. hs.json.encode(payload) .. ")"
	self.webview:evaluateJavaScript(script, function(_, err)
		if err and err.code ~= 0 then
			log.wf("page call %s failed: %s", fn, hs.inspect(err))
		end
	end)
end

-- WordSet keeps words in insertion order with one entry per word, ignoring
-- letter case.
local WordSet = {}
WordSet.__index = WordSet

function WordSet.new()
	return setmetatable({ words = {}, seen = {} }, WordSet)
end

function WordSet:add(word)
	if type(word) ~= "string" or word == "" then
		return
	end
	local key = word:lower()
	if self.seen[key] then
		return
	end
	self.seen[key] = true
	table.insert(self.words, word)
end

function WordSet:addAll(words)
	if type(words) ~= "table" then
		return
	end
	for _, word in ipairs(words) do
		self:add(word)
	end
end

function WordSet:list(limit)
	return { table.unpack(self.words, 1, math.min(#self.words, limit)) }
end

function define:notFoundPayload(word)
	local suggestions = WordSet.new()
	local spelling = self:spellCheck(word)
	if spelling then
		suggestions:addAll(spelling.guesses)
		suggestions:addAll(spelling.completions)
	end
	return {
		word = word,
		notFound = true,
		suggestions = suggestions:list(MAX_NOT_FOUND_SUGGESTIONS),
	}
end

function define:lookup(word)
	self.lookupSeq = self.lookupSeq + 1
	local result = self:dictionaryLookup(word)
	local found = result and (#result.entries > 0 or #result.thesaurus > 0)
	if not found then
		self:sendToPage("onResult", self:notFoundPayload(word))
		return
	end
	self:sendToPage("onResult", {
		word = word,
		entries = result.entries,
		thesaurus = result.thesaurus,
	})
end

function define:suggest(text, seq)
	local spelling = self:spellCheck(text)
	if not spelling then
		return
	end
	spelling.seq = seq
	self:sendToPage("onSuggest", spelling)
end

function define:speak(word)
	if not self.speaker then
		self.speaker = hs.speech.new()
	end
	if self.speaker:isSpeaking() then
		self.speaker:stop()
	end
	self.speaker:speak(word)
end

function define:onMessage(body)
	if type(body) ~= "table" then
		return
	end
	if body.type == "suggest" then
		self:suggest(tostring(body.text or ""), body.seq)
	elseif body.type == "lookup" then
		self:lookup(tostring(body.word or ""))
	elseif body.type == "speak" then
		self:speak(tostring(body.word or ""))
	elseif body.type == "close" then
		self:hide(true)
	elseif body.type == "open" and type(body.url) == "string" then
		hs.urlevent.openURL(body.url)
	end
end

function define:createPanel()
	local controller = hs.webview.usercontent.new(MESSAGE_PORT):setCallback(function(message)
		self:onMessage(message.body)
	end)
	self.webview = hs.webview
		.new(hs.geometry.rect(0, 0, PANEL_SIZE.w, PANEL_SIZE.h), { developerExtrasEnabled = false }, controller)
		:windowStyle(hs.webview.windowMasks.borderless)
		:allowTextEntry(true)
		:transparent(true)
		:shadow(true)
		:level(hs.drawing.windowLevels.floating)
		:behaviorAsLabels({ "moveToActiveSpace", "transient" })
		:windowCallback(function(action, _, focused)
			if action == "focusChange" and focused == false and self.webview and self.webview:isVisible() then
				self:hide(false)
			end
		end)
	self.webview:html(readPage())
end

function define:show()
	if not self.webview then
		self:createPanel()
	end
	self.previousWindow = hs.window.focusedWindow()
	local screen = hs.screen.mainScreen():frame()
	local width = math.min(PANEL_SIZE.w, screen.w - SCREEN_MARGIN)
	local height = math.min(PANEL_SIZE.h, screen.h - SCREEN_MARGIN)
	local frame = hs.geometry.rect(0, 0, width, height)
	frame.center = hs.geometry.point(screen.center.x, screen.y + screen.h * 0.45)
	self.webview:frame(frame)
	self.webview:show():bringToFront()
	self.webview:hswindow():focus()
	self:sendToPage("onShow", {})
end

-- Hides the panel. restoreFocus puts the window that was active before the
-- panel opened back in front.
function define:hide(restoreFocus)
	if not self.webview then
		return
	end
	self.webview:hide()
	if restoreFocus and self.previousWindow then
		self.previousWindow:focus()
	end
	self.previousWindow = nil
end

function define:toggle()
	if self.webview and self.webview:isVisible() then
		self:hide(true)
		return
	end
	self:show()
end

return define
