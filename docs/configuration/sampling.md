---
sidebar_position: 6
---

# Sampling

Adding Sentry to your app gives you a great deal of very valuable information about errors and performance you wouldn't
otherwise get. And lots of information is good -- as long as it's the right information, at a reasonable volume.

## Sampling Error Events

To send a representative sample of your errors to Sentry, set the `sampleRate` option in your SDK configuration to a
number between `0` (0% of errors sent) and `1` (100% of errors sent). This is a static rate, which will apply equally to
all errors. For example, to sample 25% of your errors:

```lua
Sentry.init({ sampleRate = 0.25 })
```

> Changing the error sample rate requires re-deployment. In addition, setting an SDK sample rate limits visibility into
> the source of events. Setting a rate limit for your project (which only drops events when volume is high) may better
> suit your needs.

## Sampling Transaction Events

Sentry recommends sampling your transactions for two reasons:

- Capturing a single trace involves minimal overhead, but capturing traces for *every* page load or *every* API request
  may add an undesirable load to your system.
- Enabling sampling allows you to better manage the number of events sent to Sentry, so you can tailor your volume to
  your organization's needs.

Choose a sampling rate with the goal of finding a balance between performance and volume concerns with data accuracy.
You don't want to collect too much data, but you want to collect sufficient data from which to draw meaningful
conclusions. If you’re not sure what rate to choose, start with a low value and gradually increase it as you learn more
about your traffic patterns and volume.

## Configuring the Transaction Sample Rate

The Sentry SDKs have two configuration options to control the volume of transactions sent to Sentry, allowing you to
take a representative sample:

1. Uniform sample rate (`tracesSampleRate`):
   - Provides an even cross-section of transactions, no matter where in your app or under what circumstances they
     occur.
   - Uses default [inheritance](/docs/configuration/sampling#inheritance) and [precedence](/docs/configuration/sampling#precedence) behavior
2. Sampling function (`tracesSampler`) which:
   - Samples different transactions at different rates
   - [Filters](/docs/configuration/filtering) out some transactions entirely
   - Modifies default [inheritance](/docs/configuration/sampling#inheritance) and [precedence](/docs/configuration/sampling#precedence) behavior

### Setting a Uniform Sample Rate

To do this, set the `tracesSampleRate` option in your `Sentry.init()` to a number between 0 and 1. With this option set,
every transaction created will have that percentage chance of being sent to Sentry. (So, for example, if you set
`tracesSampleRate` to `0.5`, approximately 50% of your transactions will get recorded and sent.) That looks like this:

```lua
Sentry.init({
    -- ...
    tracesSampleRate = 0.5,
})
```

### Setting a Sampling Function

To use the sampling function, set the `tracesSampler` option in your `Sentry.init()` to a function that will accept a
`samplingContext` object and return a sample rate between 0 and 1. For example:

```lua
Sentry.init({
    -- ...

    tracesSampler = function(samplingContext)
        -- Examine provided context data (including parent decision, if any) along
        -- with anything in the global namespace to compute the sample rate or
        -- sampling decision for this transaction

        if "..." then
            -- These are important - take a big sample
            return 1
        elseif "..." then
            -- These are less important or happen much more frequently - only take 1%
            return 0.01
        elseif "..." then
            -- These aren't something worth tracking - drop all transactions like this
            return 0
        else
            -- Default sample rate
            return 0.5
        end
    end,
})
```

For convenience, the function can also return a boolean. Returning `true` is equivalent to returning `1`, and will
guarantee the transaction will be sent to Sentry. Returning `false` is equivalent to returning `0` and will guarantee
the transaction will not be sent to Sentry.

## Sampling Context Data

### Default Sampling Context Data

The information contained in the `samplingContext` object passed to the `tracesSampler` when a transaction is created
varies by platform and integration.

For Roblox-based SDKs, it includes at least the following:

```lua
-- contents of `samplingContext`
{
    transactionContext = {
        name = string, -- human-readable identifier, like "GET /users"
        op = string, -- short description of transaction type, like "pageload"
    },
    parentSampled = boolean, -- if this transaction has a parent, its sampling decision
    ... -- custom context as passed to `startTransaction`
}
```

### Custom Sampling Context Data

When using custom instrumentation to create a transaction, you can add data to the `samplingContext` by passing it as an
optional second argument to `startTransaction`. This is useful if there's data to which you want the sampler to have
access but which you don't want to attach to the transaction as `tags` or `data`, such as information that's sensitive
or that’s too large to send with the transaction. For example:

```lua
Sentry.startTransaction(
    {
        -- `transactionContext` - will be recorded on transaction
        name = "Search from navbar",
        op = "search",
        tags = {
            testGroup = "A3",
            treatmentName = "eager load",
        },
    },
    -- `customSamplingContext` - won't be recorded
    {
        -- PII
        userId = "12312012",
        -- too big to send
        resultsFromLastSearch = { ... },
    }
)
```

## Inheritance

Whatever a transaction's sampling decision, that decision will be passed to its child spans and from there to any
transactions they subsequently cause in other services.

(See [Distributed Tracing](/docs/usage/distributed-tracing) for more about how that propagation is done.)

If the transaction currently being created is one of those subsequent transactions (in other words, if it has a parent
transaction), the upstream (parent) sampling decision will be included in the sampling context data. Your
`tracesSampler` can use this information to choose whether to inherit that decision. In most cases, inheritance is the
right choice, to avoid breaking distributed traces. A broken trace will not include all your services.

In some SDKs, for convenience, the `tracesSampler` function can return a boolean, so that a parent's decision can be
returned directly if that's the desired behavior.

```lua
tracesSampler = function(samplingContext)
    -- always inherit
    if samplingContext.parentSampled ~= nil then
        return samplingContext.parentSampled
    end

    ...
    -- rest of sampling logic here
end
```

If you're using a `tracesSampleRate` rather than a `tracesSampler`, the decision will always be inherited.

## Forcing a Sampling Decision

If you know at transaction creation time whether or not you want the transaction sent to Sentry, you also have the
option of passing a sampling decision directly to the transaction constructor (note, not in the `customSamplingContext`
object). If you do that, the transaction won't be subject to the `tracesSampleRate`, nor will `tracesSampler` be run, so
you can count on the decision that's passed not to be overwritten.

```lua
Sentry.startTransaction({
    name = "Search from navbar",
    sampled = true,
})
```

## Precedence

There are multiple ways for a transaction to end up with a sampling decision.

- Random sampling according to a static sample rate set in `tracesSampleRate`
- Random sampling according to a sample function rate returned by `tracesSampler`
- Absolute decision (100% chance or 0% chance) returned by `tracesSampler`
- If the transaction has a parent, inheriting its parent's sampling decision
- Absolute decision passed to `startTransaction`

When there's the potential for more than one of these to come into play, the following precedence rules apply:

1. If a sampling decision is passed to `startTransaction`, that decision will be used, overriding everything else.
2. If `tracesSampler` is defined, its decision will be used. It can choose to keep or ignore any parent sampling
   decision, use the sampling context data to make its own decision, or choose a sample rate for the transaction. We
   advise against overriding the parent sampling decision because it will break distributed traces)
3. If `tracesSampler` is not defined, but there's a parent sampling decision, the parent sampling decision will be used.
4. If `tracesSampler` is not defined and there's no parent sampling decision, `tracesSampleRate` will be used.
