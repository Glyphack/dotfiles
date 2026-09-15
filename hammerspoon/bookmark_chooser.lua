-- Bookmark chooser: lists Brave bookmarks, flattened out of their folders,
-- and opens the one picked in Brave. Typing filters the list on the
-- bookmark name and its folder path.

local chooser = require("hs.chooser")
local json = require("hs.json")
local FuzzyQuery = require("fuzzy_query")

local BOOKMARKS_PATH = os.getenv("HOME")
	.. "/Library/Application Support/BraveSoftware/Brave-Browser/Default/Bookmarks"
local BRAVE_BUNDLE_ID = "com.brave.Browser"
local ROOT_KEYS = { "bookmark_bar", "other", "synced" }

local BookmarkChooser = {
	choices = {},
	chooser = nil,
}

local function collectBookmarks(node, folderPath, choices)
	if not node.children then
		return
	end
	for _, child in ipairs(node.children) do
		if child.type == "url" then
			table.insert(choices, {
				text = child.name,
				subText = folderPath,
				image = hs.image.imageFromAppBundle(BRAVE_BUNDLE_ID),
				url = child.url,
			})
		elseif child.type == "folder" then
			local childPath = folderPath == "" and child.name or (folderPath .. " / " .. child.name)
			collectBookmarks(child, childPath, choices)
		end
	end
end

function BookmarkChooser:refresh()
	self.choices = {}
	local file = io.open(BOOKMARKS_PATH, "r")
	if not file then
		return
	end
	local contents = file:read("*a")
	file:close()
	local data = json.decode(contents)
	if not data or not data.roots then
		return
	end
	for _, key in ipairs(ROOT_KEYS) do
		local root = data.roots[key]
		if root then
			collectBookmarks(root, root.name or "", self.choices)
		end
	end
end

function BookmarkChooser:filterChoices(query)
	if query == "" then
		return self.choices
	end
	local texts = {}
	for _, choice in ipairs(self.choices) do
		table.insert(texts, choice.text .. " " .. choice.subText)
	end
	local result = {}
	for _, index in ipairs(FuzzyQuery.new(query):rank(texts)) do
		table.insert(result, self.choices[index])
	end
	return result
end

function BookmarkChooser:open(choice)
	if not choice then
		return
	end
	hs.urlevent.openURLWithBundle(choice.url, BRAVE_BUNDLE_ID)
end

function BookmarkChooser:show()
	self:refresh()
	self.chooser:query("")
	self.chooser:choices(self.choices)
	self.chooser:show()
end

BookmarkChooser.chooser = chooser
	.new(function(choice)
		BookmarkChooser:open(choice)
	end)
	:placeholderText("Bookmark")
	:queryChangedCallback(function(query)
		BookmarkChooser.chooser:choices(BookmarkChooser:filterChoices(query))
	end)

return BookmarkChooser
