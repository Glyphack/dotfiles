local json = require("hs.json")
local FuzzyChooser = dofile(hs.spoons.resourcePath("fuzzy_chooser.lua"))

local BOOKMARKS_PATH = os.getenv("HOME")
	.. "/Library/Application Support/BraveSoftware/Brave-Browser/Default/Bookmarks"
local BRAVE_BUNDLE_ID = "com.brave.Browser"
local ROOT_KEYS = { "bookmark_bar", "other", "synced" }

local BookmarkChooser = {
	chooser = nil,
}

local function collectBookmarks(node, folderPath, icon, choices)
	if not node.children then
		return
	end
	for _, child in ipairs(node.children) do
		if child.type == "url" then
			table.insert(choices, {
				text = child.name,
				subText = folderPath,
				image = icon,
				url = child.url,
			})
		elseif child.type == "folder" then
			local childPath = folderPath == "" and child.name or (folderPath .. " / " .. child.name)
			collectBookmarks(child, childPath, icon, choices)
		end
	end
end

function BookmarkChooser:load()
	local choices = {}
	local file = io.open(BOOKMARKS_PATH, "r")
	if not file then
		hs.alert.show("No Brave bookmarks found")
		return choices
	end
	local contents = file:read("*a")
	file:close()
	local data = json.decode(contents)
	if not data or not data.roots then
		return choices
	end
	local icon = hs.image.imageFromAppBundle(BRAVE_BUNDLE_ID)
	for _, key in ipairs(ROOT_KEYS) do
		local root = data.roots[key]
		if root then
			collectBookmarks(root, root.name or "", icon, choices)
		end
	end
	return choices
end

function BookmarkChooser:open(choice)
	hs.urlevent.openURLWithBundle(choice.url, BRAVE_BUNDLE_ID)
end

function BookmarkChooser:show()
	self.chooser:show()
end

BookmarkChooser.chooser = FuzzyChooser.new("Bookmark", function()
	return BookmarkChooser:load()
end, function(choice)
	BookmarkChooser:open(choice)
end)

return BookmarkChooser
