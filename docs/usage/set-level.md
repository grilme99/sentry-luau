---
sidebar_position: 1
---

# Set the Level

The level - similar to logging levels - is generally added by default based on the integration. You can also override it
within an event.

To set the level out of scope, you can call `captureMessage()` per event:

```lua
Sentry.captureMessage("this is a debug message", "debug")
```

Available levels are `"fatal"`, `"error"`, `"warning"`, `"log"`, `"info"`, and `"debug"`

To set the level within scope, you can call `setLevel()`:

```lua
Sentry.configureScope(function(scope)
    scope:setLevel("warning")
end)
```

or per event:

```lua
Sentry.withScope(function(scope)
    scope:setLevel("info")

    -- The exception has the event level set by the scope (info).
    Sentry.captureException(Error.new("custom error"))
end)

-- Outside of withScope, the Event level will have their previous value restored.
-- The exception has the event level set (error).
Sentry.captureException(Error.new("custom error 2"))
```
