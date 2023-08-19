---
sidebar_position: 7
---

# Filtering

When you add Sentry to your app, you get a lot of valuable information about errors and performance. And lots of
information is good -- as long as it's the right information, at a reasonable volume.

The Sentry SDKs have several configuration options to help you filter out events.

Sentry also offers [Inbound Filters](https://docs.sentry.io/product/data-management-settings/filtering/) to filter
events in sentry.io. We recommend filtering at the client level though, because it removes the overhead of sending
events you don't actually want. Learn more about the
[fields available in an event](https://develop.sentry.dev/sdk/event-payloads/).

## Filtering Error Events

Configure your SDK to filter error events by using the `beforeSend` callback method and configuring, enabling, or
disabling integrations.

### Using `beforeSend`

All Sentry SDKs support the `beforeSend` callback method. `beforeSend` is called immediately before the event is sent to
the server, so it’s the final place where you can edit its data. It receives the event object as a parameter, so you can
use that to modify the event’s data or drop it completely (by returning `nil`) based on custom logic and the data
available on the event.

In Lua, you can use a function to modify the event or return a completely new one. You can either return `nil` or an
event payload. If you return `nil`, the event will be discarded.

```lua
Sentry.init({
    dsn = "__DSN__",

    -- Called for message and error events
    beforeSend = function(event)
        -- Modify or drop the event here
        if event.user then
            -- Don't send user's email address
            event.user.email = nil
        end
        return event
    end,
})
```

Note also that breadcrumbs can be filtered, as discussed in the
[Breadcrumbs documentation](https://docs.sentry.io/product/error-monitoring/breadcrumbs/).

#### Event Hints

The `beforeSend` callback is passed both the `event` and a second argument, `hint`, that holds one or more hints.

Typically a `hint` holds the original exception so that additional data can be extracted or grouping is affected. In
this example, the fingerprint is forced to a common value if an exception of a certain type has been caught:

```lua
Sentry.init({
    -- ...
    beforeSend = function(event, hint)
        local error = hint.originalException
        local message = error and error.message
        if string.match(message, "database unavailable") then
            event.fingerprint = { "database-unavailable" }
        end
        return event
    end,
})
```

For information about which hints are available see [hints in Lua](/docs/configuration/filtering#using-hints).

When the SDK creates an event or breadcrumb for transmission, that transmission is typically created from some sort of
source object. For instance, an error event is typically created from a log record or exception instance. For better
customization, SDKs send these objects to certain callbacks (`beforeSend`, `beforeBreadcrumb` or the event processor
system in the SDK).

### Using Hints

Hints are available in two places:

1. `beforeSend` / `beforeBreadcrumb`
2. `eventProcessors`

Event and breadcrumb `hints` are objects containing various information used to put together an event or a breadcrumb.
Typically `hints` hold the original exception so that additional data can be extracted or grouping can be affected.

For events, hints contain properties such as `event_id`, `originalException`, `syntheticException` (used internally to
generate cleaner stack trace), and any other arbitrary `data` that you attach.

For breadcrumbs, the use of hints is implementation dependent.

#### Hints for Events

`originalException`

The original exception that caused the Sentry SDK to create the event. This is useful for changing how the Sentry SDK
groups events or to extract additional information.

`syntheticException`

When a string or a non-error object is raised, Sentry creates a synthetic exception so you can get a basic stack trace.
This exception is stored here for further data extraction.

#### Hints for Breadcrumbs

`event`

For breadcrumbs created from engine events, the Sentry SDK often supplies the event to the breadcrumb as a hint.

`level` / `input`

For breadcrumbs created from console log interceptions. This holds the original console log level and the original input
data to the log function.

### Using `ignoreErrors`

You can use the `ignoreErrors` option to filter out errors that match a certain pattern. This option receives a list of
strings and regular expressions to match against the error message.

```lua
Sentry.init({
    dsn = "__DSN__",
    ignoreErrors = { "fb_xd_fragment", RegExp([[^Exact Match Message$]]) },
})
```

## Filtering Transaction Events

To prevent certain transactions from being reported to Sentry, use the `tracesSampler` or `beforeSendTransaction`
configuration option, which allows you to provide a function to evaluate the current transaction and drop it if it's not
one you want.

### Using `tracesSampler`

**Note**: The `tracesSampler` and `tracesSampleRate` config options are mutually exclusive. If you define a
`tracesSampler` to filter out certain transactions, you must also handle the case of non-filtered transactions by
returning the rate at which you'd like them sampled.

In its simplest form, used just for filtering the transaction, it looks like this:

```lua
Sentry.init({
    -- ...

    tracesSampler = function(samplingContext)
        if "..." then
            -- Drop this transaction, by setting its sample rate to 0%
            return 0
        else
            -- Default sample rate for all others (replaces tracesSampleRate)
            return 1
        end
    end,
})
```

It also allows you to sample different transactions at different rates.

If the transaction currently being processed has a parent transaction (from an upstream service calling this service),
the parent (upstream) sampling decision will always be included in the sampling context data, so that your
`tracesSampler` can choose whether and when to inherit that decision. In most cases, inheritance is the right choice, to
avoid breaking distributed traces. A broken trace will not include all your services. See
[Inheriting the parent sampling decision](/docs/configuration/sampling#inheritance) to learn more.

Learn more about [configuring the sample rate](/docs/configuration/sampling).

### Using `beforeSendTransaction`

```lua
Sentry.init({
    dsn = "__DSN__",

    -- Called for transaction events
    beforeSendTransaction = function(event)
        -- Modify or drop the event here
        if event.transaction == "/unimportant/route" then
            -- Don't send the event to Sentry
            return nil
        end
        return event
    end,
})
```

### Using `ignoreTransactions`

You can use the `ignoreTransactions` option to filter out transactions that match a certain pattern. This option
receives a list of strings and regular expressions to match against the transaction name.

```lua
Sentry.init({
    dsn = "__DSN__",
    ignoreTransactions = { "partial/match", RegExp([[^Exact Match Message$]]) },
})
```
