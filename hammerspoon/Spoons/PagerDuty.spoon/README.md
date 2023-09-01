# PagerDuty Spoon

Periodically check pager duty incidents assigned to a user and send notifications when new incidents happen.

## Install

Install Hammerspoon.

Copy this spoon to your `.hammerspoon` config.

Add the following to your `init.lua`:

```
local PagerDuty = hs.loadSpoon("PagerDuty")

PagerDuty:start(60, secrets.pagerduty_user_id, secrets.pagerduty_api_key)
```


## Options

### User ID

Can be found in the URL of user profile.
If user ID is `nil` then all incidents are monitored.

### Delay

The delay between check in seconds.
