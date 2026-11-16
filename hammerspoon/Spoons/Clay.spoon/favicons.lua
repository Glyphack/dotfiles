local sqlite3 = require("hs.sqlite3")

local log = hs.logger.new("clay.favicons", "info")

-- Finds the largest tab icon saved for a page. Icon type 1 is the icon shown on the tab,
-- the other types are touch and web app icons that look different.
local ICON_QUERY = [[
SELECT favicon_bitmaps.image_data
FROM icon_mapping
JOIN favicons ON favicons.id = icon_mapping.icon_id
JOIN favicon_bitmaps ON favicon_bitmaps.icon_id = favicons.id
WHERE icon_mapping.page_url = ?
	AND favicons.icon_type = 1
	AND length(favicon_bitmaps.image_data) > 0
ORDER BY favicon_bitmaps.width DESC
LIMIT 1]]

local function imageFromPng(png)
	return hs.image.imageFromURL("data:image/png;base64," .. hs.base64.encode(png))
end

-- Reads the page icons a Chromium browser saved in the Favicons database of a profile.
local Favicons = {}
Favicons.__index = Favicons

function Favicons.new(profileDir)
	return setmetatable({
		path = profileDir .. "/Favicons",
		-- images made in the latest setImages call, by their png data
		images = {},
	}, Favicons)
end

-- The database is opened as immutable because the browser keeps it locked while it runs.
function Favicons:uri()
	local path = self.path:gsub("[%%?#]", function(char)
		return string.format("%%%02X", char:byte())
	end)
	return "file:" .. path .. "?immutable=1"
end

-- Returns the png data of the icon saved for url, or nil when there is none.
function Favicons:savedPng(db, query, url)
	query:reset()
	query:bind_values(url)
	local result = query:step()
	if result == sqlite3.ROW then
		return query:get_value(0)
	end
	if result ~= sqlite3.DONE then
		log.e("could not read the icon of " .. url .. ": " .. db:errmsg())
	end
	return nil
end

-- Sets the image of each choice to the icon the browser shows for its url.
-- Choices whose page has no saved icon keep their image.
function Favicons:setImages(choices)
	local db, _, message = sqlite3.open(self:uri(), sqlite3.OPEN_READONLY + sqlite3.OPEN_URI)
	if not db then
		log.e("could not open " .. self.path .. ": " .. tostring(message))
		return
	end
	local query = db:prepare(ICON_QUERY)
	if not query then
		log.e("could not read " .. self.path .. ": " .. db:errmsg())
		db:close()
		return
	end
	local images = {}
	for _, choice in ipairs(choices) do
		local png = self:savedPng(db, query, choice.url)
		if png then
			images[png] = images[png] or self.images[png] or imageFromPng(png)
			choice.image = images[png] or choice.image
		end
	end
	self.images = images
	query:finalize()
	db:close()
end

return Favicons
