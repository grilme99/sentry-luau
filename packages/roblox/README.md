<p align="center">
  <a href="https://sentry.io/?utm_source=github&utm_medium=logo" target="_blank">
    <img src="https://sentry-brand.storage.googleapis.com/sentry-wordmark-dark-280x84.png" alt="Sentry" width="280" height="84">
  </a>
</p>

# Unofficial Sentry SDK for Roblox

## Usage

To use this SDK, call `Sentry.init(options)` as early as possible after the game starts (on the client or server).
This will initialize the SDK and hook into the environment. Note that you can turn off almost all side effects using the respective options.

```lua
local Sentry = require("@packages/sentry-roblox")

Sentry.init({
  dsn = "__DSN__",
  -- ...
})
```

To set context information or send manual events, use the exported functions of `sentry-roblox`. Note that these
functions will not perform any action before you have called `Sentry.init()`:

```lua
local Sentry = require("@packages/sentry-roblox")

-- Set user information, as well as tags and further extras
Sentry.configureScope(function(scope)
  scope:setExtra("battery", 0.7),
  scope:setTag("user_mode", "admin"),
  scope:setUser({ id = "4711" }),
  -- scope:clear(),
end)

-- Add a breadcrumb for future events
Sentry.addBreadcrumb({
  message = "My Breadcrumb",
  -- ...
})

-- Capture exceptions, messages or manual events
Sentry.captureMessage("Hello, world!")
Sentry.captureException(Error.new("Good bye")) -- `Error` from LuauPolyfill
Sentry.captureEvent({
  message = "Manual",
  stacktrace: {
    -- ...
  },
})
```
