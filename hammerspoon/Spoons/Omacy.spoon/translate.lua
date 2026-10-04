-- Popup with the Google Translate translation of the selected text.
-- Source: https://github.com/Hammerspoon/Spoons (Source/PopupTranslateSelection.spoon/init.lua)
--
-- The MIT License (MIT)
--
-- Copyright (c) 2017 Diego Zamboni
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local translate = {}

local POPUP_STYLE = hs.webview.windowMasks.utility
	| hs.webview.windowMasks.HUD
	| hs.webview.windowMasks.titled
	| hs.webview.windowMasks.closable

-- Size of the popup window.
translate.popup_size = hs.geometry.size(770, 610)

-- Closes the popup when escape is pressed.
translate.popup_close_on_escape = true

translate.webview = nil

-- options is a table { from = "...", to = "...", popup_style = ... }, all optional.
-- from and to are two letter language codes such as "nl", listed at
-- https://cloud.google.com/translate/docs/languages. A missing from lets Google
-- Translate detect the language, and a missing to uses the last language picked
-- in the popup, or English.
-- popup_style is the window style of the popup, a combination of
-- hs.webview.windowMasks values.
function translate:translatePopup(text, options)
	options = options or {}
	local query = hs.http.encodeForQuery(text)
	local url = "http://translate.google.com/translate_t?"
		.. (options.from and ("sl=" .. options.from .. "&") or "")
		.. (options.to and ("tl=" .. options.to .. "&") or "")
		.. "text="
		.. query
	if self.webview == nil then
		local rect = hs.geometry.rect(0, 0, self.popup_size.w, self.popup_size.h)
		rect.center = hs.screen.mainScreen():frame().center
		self.webview = hs.webview
			.new(rect)
			:allowTextEntry(true)
			:closeOnEscape(self.popup_close_on_escape)
	end
	self.webview:windowStyle(options.popup_style or POPUP_STYLE):url(url):bringToFront():show()
	self.webview:hswindow():focus()
	return self
end

local function currentSelection()
	local elem = hs.uielement.focusedElement()
	local sel = nil
	if elem then
		sel = elem:selectedText()
	end
	if not sel or sel == "" then
		hs.eventtap.keyStroke({ "cmd" }, "c")
		hs.timer.usleep(20000)
		sel = hs.pasteboard.getContents()
	end
	return sel or ""
end

-- Same as translatePopup, for the text selected in the frontmost window.
function translate:translateSelectionPopup(options)
	return self:translatePopup(currentSelection(), options)
end

return translate
