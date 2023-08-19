---
sidebar_position: 2
---

# SDK Fingerprinting

All events have a fingerprint. Events with the same fingerprint are grouped together into an issue.

By default, Sentry will run one of our built-in grouping algorithms to generate a fingerprint based on information
available within the event such as `stacktrace`, `exception`, and `message`. To extend the default grouping behavior or
change it completely, you can use a combination of the following options:

1. In your SDK, using SDK Fingerprinting, as documented below
2. In your project, using [Fingerprint Rules](https://docs.sentry.io/product/data-management-settings/event-grouping/fingerprint-rules/) or [Stack Trace Rules](https://docs.sentry.io/product/data-management-settings/event-grouping/stack-trace-rules/)

In supported SDKs, you can override Sentry's default grouping that passes the fingerprint attribute as an array of
strings. The length of a fingerprint's array is not restricted. This works similarly to the
[fingerprint rules functionality](https://docs.sentry.io/product/data-management-settings/event-grouping/fingerprint-rules/),
which is always available and can achieve similar results.

## Basic Example

In the most basic case, values are passed directly:

```lua
local function makeRequest(method, path, options)
    return fetch(method, path, options):catch(function(err)
        Sentry.withScope(function (scope)
            -- group errors together based on their request and response
            scope:setFingerprint({method, path, tostring(err.statusCode)})
            Sentry.captureException(err)
        end)
    end)
end
```

You can use variable substitution to fill dynamic values into the fingerprint generally computed on the server. For
instance, the value `{{ default }}` can be added to add the entire normally generated grouping hash into the
fingerprint. These values are the same as for server-side fingerprinting. See
[Variables](https://docs.sentry.io/product/data-management-settings/event-grouping/fingerprint-rules/#variables) for
more information.

## Group Errors With Greater Granularity

In some scenarios, you'll want to group errors more granularly.

For example, if your application queries a Remote Procedure Call Model (RPC) interface or external Application
Programming Interface (API) service, the stack trace is generally the same, even if the outgoing request is very
different.

The following example will split up the default group Sentry would create (represented by `{{ default }}`) further,
taking some attributes on the error object into account:

```lua
local LuauPolyfill = require(Path.To.LuauPolyfill)
local Error = LuauPolyfill.Error
local extend = LuauPolyfill.extend
local instanceof = LuauPolyfill.instanceof

local MyRPCError = extends(Error, "MyRPCError", function(self, message, functionName, errorCode)
    self.name = "MyRPCError"
    self.message = message
    -- The name of the RPC function that was called (e.g. "getAllBlogArticles")
    self.functionName = functionName
    -- For example a HTTP status code returned by the server.
    self.errorCode = errorCode
end)

Sentry.init({
    -- ...
    beforeSend = function(event, hint)
        local exception = hint.originalException

        if exception and instanceof(exception, MyRPCError) then
            event.fingerprint = {
                "{{ default }}",
                tostring(exception.functionName),
                tostring(exception.errorCode),
            }
        end

        return event
    end,
})
```

## Group Errors More Aggressively

You can also overwrite Sentry's grouping entirely.

For example, if a generic error, such as a database connection error, has many different stack traces and never groups
them together, you can overwrite Sentry's grouping by omitting `{{ default }}` from the array:

```lua
local DatabaseConnectionError = extends(Error, "DatabaseConnectionError", function(self, message)
    self.name = "DatabaseConnectionError"
    self.message = message
end)

Sentry.init({
    -- ...
    beforeSend = function(event, hint)
        local exception = hint.originalException

        if exception and instanceof(exception, DatabaseConnectionError) then
            event.fingerprint = { "database-connection-error" }
        end

        return event
    end,
})
```
