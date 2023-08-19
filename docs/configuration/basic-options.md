---
sidebar_position: 1
---

# Basic Options

SDKs are configurable using a variety of options. The options are largely standardized among SDKs, but there are some
differences to better accommodate platform peculiarities. Options are set when the SDK is first initialized.

Options are passed to the `init()` function as a table:

```lua
Sentry.init({
  dsn = "__DSN__",
  maxBreadcrumbs = 50,
  debug = true,
})
```

## Common Options

The list of common options across SDKs. These work more or less the same in all SDKs, but some subtle differences will
exist to better support the platform.

### `dsn`

The DSN tells the Sentry SDK where to send events. If this value is not provided, the SDK will not send events.

Learn more about [DSN utilization](https://docs.sentry.io/product/sentry-basics/dsn-explainer/#dsn-utilization).

### `debug`

Turns debug mode on or off. If debug is enabled SDK will attempt to print out useful debugging information if something
goes wrong with sending the event. The default is always false. It's generally not recommended to turn it on in
production, though turning debug mode on will not cause any safety concerns.

### `release`

Sets the release. Some SDKs will try to automatically configure a release out of the box, but it's a better idea to
manually set it to guarantee that the release is in sync with your deploy integrations. Release names are strings, but
some formats are detected by Sentry and might be rendered differently. Learn more about how to send release data so
Sentry can tell you about regressions between releases and identify the potential source in
[the releases documentation](https://docs.sentry.io/product/releases/)
or the [sandbox](https://try.sentry-demo.com/demo/start/?scenario=releases&projectSlug=react&source=docs).

By default the SDK will try to read this value from the `SENTRY_RELEASE` global variable (in the Roblox SDK, this
will be read off of the `_G_.__SENTRY_RELEASE__` if available).

### `environment`

Sets the environment. This string is freeform and not set by default. A release can be associated with more than one
environment to separate them in the UI (think staging vs prod or similar).

### `sampleRate`

Configures the sample rate for error events, in the range of `0.0` to `1.0`. The default is `1.0` which means that 100%
of error events are sent. If set to `0.1` only 10% of error events will be sent. Events are picked randomly.

### `maxBreadcrumbs`

This variable controls the total amount of breadcrumbs that should be captured. This defaults to `100`, but you can set
this to any number. However, you should be aware that Sentry has a [maximum payload size](https://develop.sentry.dev/sdk/envelopes/#size-limits) and any events exceeding that payload size will be dropped.

### `attachStacktrace`

When enabled, stack traces are automatically attached to all messages logged. Stack traces are always attached to exceptions; however, when this option is set, stack traces are also sent with messages. This option, for instance, means that stack traces appear next to all log messages.

This option is `off` by default.

Grouping in Sentry is different for events with stack traces and without. As a result, you will get new groups as you
enable or disable this flag for certain events.

### `ignoreErrors`

A list of strings or regex patterns that match error messages that shouldn't be sent to Sentry. Messages that match
these strings or regular expressions will be filtered out before they're sent to Sentry. When using strings, partial
matches will be filtered out, so if you need to filter by exact match, use regex patterns instead. By default, all
errors are sent.

### `ignoreTransactions`

A list of strings or regex patterns that match transaction names that shouldn't be sent to Sentry. Transactions that
match these strings or regular expressions will be filtered out before they're sent to Sentry. When using strings,
partial matches will be filtered out, so if you need to filter by exact match, use regex patterns instead. By default,
all transactions are sent.

### `denyUrls`

A list of strings or regex patterns that match error URLs that should not be sent to Sentry. Errors whose entire file
URL contains (string) or matches (regex) at least one entry in the list will not be sent. As a result, if you add
`'foo.com'` to the list, it will also match on `https://bar.com/myfile/foo.com`. By default, all errors are sent.

### `autoSessionTracking`

When set to `true`, the SDK will send session events to Sentry. This doesn't have much application in the Roblox SDK.

### `initialScope`

Data to be set to the initial scope. Initial scope can be defined either as an object or a callback function, as shown
below.

Object:

```lua
Sentry.init({
  dsn = "__DSN__",
  debug = true,
  initialScope = {
    tags = {
        myTag = "my value",
    },
    user = { id = 42, username = "johndoe" },
  },
})
```

Callback function:

```lua
Sentry.init({
  dsn = "__DSN__",
  debug = true,
  initialScope = function(scope)
    scope:setTags({ a = "b" });
    return scope;
  end,
})
```

### `maxValueLength`

Maximum number of characters a single value can have before it will be truncated (defaults to `250`).

### `normalizeDepth`

Sentry SDKs normalize any contextual data to a given depth. Any data beyond this depth will be trimmed and marked using
its type instead (`[Object]` or `[Array]`), without walking the tree any further. By default, walking is performed three
levels deep.

### `normalizeMaxBreadth`

This is the maximum number of properties or entries that will be included in any given object or array when the SDK is
normalizing contextual data. Any data beyond this depth will be dropped. (defaults to 1000)

### `enabled`

Specifies whether this SDK should send events to Sentry. Defaults to `true`. Setting this to `enabled = false` doesn't
prevent all overhead from Sentry instrumentation. To disable Sentry completely, depending on environment, call
`Sentry.init` conditionally.

### `sendClientReports`

Set this boolean to `false` to disable sending of client reports. Client reports are a protocol feature that let clients
send status reports about themselves to Sentry. They are currently mainly used to emit outcomes for events that were
never sent.

## Integration Configuration

For many platform SDKs, integrations can be configured alongside it. On some platforms that happens as part of the
`init()` call, in some others, different patterns apply.

### `integrations`

In some SDKs, the integrations are configured through this parameter on library initialization. For more information,
please see the documentation for a specific integration.

### `defaultIntegrations`

This can be used to disable integrations that are added by default. When set to `false`, no default integrations are
added.

## Hooks

These options can be used to hook the SDK in various ways to customize the reporting of events.

### `beforeSend`

This function is called with an SDK-specific message or error event object, and can return a modified event object, or
`nil` to skip reporting the event. This can be used, for instance, for manual PII stripping before sending.

### `beforeSendTransaction`

This function is called with an SDK-specific transaction event object, and can return a modified transaction event
object, or `nil` to skip reporting the event. One way this might be used is for manual PII stripping before sending.

### `beforeBreadcrumb`

This function is called with an SDK-specific breadcrumb object before the breadcrumb is added to the scope. When nothing
is returned from the function, the breadcrumb is dropped. To pass the breadcrumb through, return the first argument,
which contains the breadcrumb object. The callback typically gets a second argument (called a "hint") which contains the
original object from which the breadcrumb was created to further customize what the breadcrumb should look like.

## Transport Options

Transports are used to send events to Sentry. Transports can be customized to some degree to better support highly
specific deployments.

### `transport`

Switches out the transport used to send events. How this works depends on the SDK. It can, for instance, be used to
capture events for unit-testing or to send it through some more complex setup that requires proxy authentication.

### `transportOptions`

Options used to configure the transport. This is an object with the following possible optional keys:

- `headers`: An object containing headers to be sent with every request. Used by the SDK's Roblox `HttpService`
  transport.

## Tracing Options

### `enableTracing`

A boolean value, if `true`, transactions and trace data will be generated and captured. This will set the
`tracesSampleRate` to the recommended default of `1.0` if `tracesSampleRate` is not defined. Note that
`tracesSampleRate` and `tracesSampler` take precedence over this option.

### `tracesSampleRate`

A number between 0 and 1, controlling the percentage chance a given transaction will be sent to Sentry.
(0 represents 0% while 1 represents 100%.) Applies equally to all transactions created in the app. Either this or
`tracesSampler` must be defined to enable tracing.

### `tracesSampler`

A function responsible for determining the percentage chance a given transaction will be sent to Sentry. It will
automatically be passed information about the transaction and the context in which it's being created, and must return a
number between `0` (0% chance of being sent) and `1` (100% chance of being sent). Can also be used for filtering
transactions, by returning `0` for those that are unwanted. Either this or `tracesSampleRate` must be defined to enable
tracing.
