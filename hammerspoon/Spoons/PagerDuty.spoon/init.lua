local obj = {}
obj.__index = obj

-- Metadata
obj.name = "PagerDuty"
obj.version = "1.0"
obj.license = "LGPLv3 - https://www.gnu.org/licenses/lgpl-3.0.en.html"

obj.logger = hs.logger.new("PagerDuty")

-- List to store unique incident numbers
local seenIncidents = {}
local function checkPagerDuty(sinceXSecondsAgo, userId, token, onlyTriggered)
	local currentTime = os.time()
	local time20MinutesAgo = currentTime - sinceXSecondsAgo -- 20 minutes * 60 seconds
	local formattedTime = os.date("!%Y-%m-%dT%H:%M:%SZ", time20MinutesAgo)
	local urlEncodedTime = formattedTime:gsub(":", "%%3A")

	local userQueryString = userId and ("&user_ids%5B%5D=" .. userId) or ""
	local sinceQueryString = "&since=" .. urlEncodedTime
	local statusQueryString = ""
	if onlyTriggered then
		statusQueryString = "&statuses%5B%5D=triggered"
	end
	local url = "https://api.pagerduty.com/incidents?total=true"
		.. userQueryString
		.. "&time_zone=UTC"
		.. statusQueryString
		.. sinceQueryString
	local headers = {
		["accept"] = "application/vnd.pagerduty+json;version=2",
		["authorization"] = "Token token=" .. token,
		["content-type"] = "application/json",
	}

	print("Checking PagerDuty status")
	local status, body, _ = hs.http.get(url, headers)

	if status ~= 200 then
		print("Error: " .. status)
		return
	end

	local bodyJson = hs.json.decode(body)

	if not bodyJson.incidents then
		obj.logger.i("No incidents")
		return
	end

	for _, incident in ipairs(bodyJson.incidents) do
		local incidentNumber = incident.incident_number
		if not seenIncidents[incidentNumber] then
			seenIncidents[incidentNumber] = true

			local function notificationCallback()
				hs.urlevent.openURL(incident.html_url) -- Replace with the correct index if needed
			end
			local notificationTitle = "New Incident"
			local notificationSubtitle = "Incident Number: " .. incidentNumber
			local notificationAdditionalActions = {
				"Open Incident",
			}
			local notification = hs.notify.new(notificationCallback, {
				alwaysPresent = true,
				autoWithdraw = false,
				title = notificationTitle,
				informativeText = notificationSubtitle,
				additionalActions = notificationAdditionalActions,
				soundName = "Hero",
			})
			notification:send()
		end
	end
end

function obj:start(everyXSeconds, userId, token, onlyTriggered)
	self.logger.i("Starting PagerDuty checker")
	checkPagerDuty(everyXSeconds, userId, token, onlyTriggered)
	self.timer = hs.timer.doEvery(everyXSeconds, function()
		checkPagerDuty(everyXSeconds, userId, token, onlyTriggered)
	end)
end

function obj:stop()
	self.logger.i("Stopping PagerDuty checker")
	self.timer:stop()
end

return obj
