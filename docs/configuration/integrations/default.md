---
sidebar_position: 1
---

# Default Integrations

The below system integrations are part of the standard library or the interpreter itself and are enabled by default. To
understand what they do and how to disable them if they cause issues, read on.

## What's Enabled by Default

### InboundFilters

*Import name: `Sentry.Integrations.InboundFilters`*

This integration allows you to ignore specific errors based on the type, message, or URLs in a given exception.

To configure this integration, use the `ignoreErrors`, `ignoreTransactions`, `denyUrls`, and `allowUrls` SDK options
directly. Keep in mind that `denyURLs` and `allowURLs` only work for captured exceptions, not raw message events.

### GlobalHandlers

*Import name: `Sentry.Integrations.GlobalHandlers`*

This integration attaches global handlers to capture uncaught exceptions and unhandled rejections.

Available options:

```lua
{
    onerror = boolean
    onunhandledrejection = boolean
}
```

### InApp

*Import name: `Sentry.Integrations.InApp`*

This integration marks stack frames from project dependencies as `in_app = false`, which allows Sentry to display
stacktraces in a more useful way. By default, any frames whose lowercase `filename` starts with:

- `replicatedstorage.packages`
- `replicatedfirst.packages`
- `packages/`
- `dependencies/`
- `deps/`

Will be marked as not `in_app`. The default configuration supports projects all projects, regardless of if they use
stacktraces or not.

### Dedupe

*Import name: `Sentry.Integrations.Dedupe`*

This integration is enabled by default for Roblox, but only deduplicates certain events. It can be helpful if you're
receiving many duplicate errors. Note, that Sentry only compares stack traces and fingerprints

```lua
local Sentry = require(Path.To.Sentry)
local DedupeIntegration = Sentry.Integrations.Dedupe

Sentry.init({
    dsn = "__DSN__",
    integrations = {DedupeIntegration.new()}
})
```

## Modifying System Integrations

To disable system integrations, set `defaultIntegrations = false` when calling `init()`.

To override their settings, provide a new instance with your config to the `integrations` option. For example, to turn
off Roblox capturing global errors:

```lua
Sentry.init({
    dsn = "__DSN__",
    
    integrations = {
        Sentry.Integrations.GlobalHandlers.new({
            onerror = false,
            onunhandledrejection = false,
        }),
    },
})
```

### Removing an Integration

This example removes the default-enabled integration for deduplicating events:

```lua
local LuauPolyfill = require(Path.To.LuauPolyfill)
local Array = LuauPolyfill.Array

Sentry.init({
    -- ...
    integrations = function(integrations)
        -- integrations will be all default integrations
        return Array.filter(integrations, function(integration)
            return integration.name ~= "Dedupe"
        end)
    end,
})
```
