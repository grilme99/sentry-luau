---
sidebar_position: 4
---

# Usage

The Sentry SDK hooks into your runtime environment and automatically reports errors, uncaught exceptions, and unhandled
rejections as well as other types of errors depending on the platform.

> Key terms:
>
> - An *event* is one instance of sending data to Sentry. Generally, this data is an error or exception.
> - An *issue* is a grouping of similar events.
> - The reporting of an event is called *capturing*. When an event is captured, it’s sent to Sentry.

The most common form of capturing is to capture errors. What can be captured as an error varies by platform. In general,
if you have something that looks like an exception, it can be captured. For some SDKs, you can also omit the argument to
`captureException` and Sentry will attempt to capture the current exception. It is also useful for manual reporting of
errors or messages to Sentry.

While capturing an event, you can also record the breadcrumbs that lead up to that event. Breadcrumbs are different from
events: they will not create an event in Sentry, but will be buffered until the next event is sent. Learn more about
breadcrumbs in the [Breadcrumbs documentation](/docs/enriching-events/breadcrumbs).

## Capturing Errors

You can pass an `Error` object to `captureException()` to get it captured as event. It's also possible to pass
non-`Error` objects and strings, but be aware that the resulting events in Sentry may be missing a stacktrace and other
metadata.

> If you are using Roblox, the `LuauPolyfill` library exposes a JavaScript `Error` object which this SDK is designed to
> work with.

```lua
local Sentry = require(Path.To.Sentry)

local success, result = pcall(function()
    return aFunctionThatMightFail()
end)

if not success then
    Sentry.captureException(result)
end
```

## Capturing Messages

Another common operation is to capture a bare message. A message is textual information that should be sent to Sentry.
Typically, the SDKs don't automatically capture messages, but you can capture them manually.

```lua
Sentry.captureMessage("Something went wrong")
```
