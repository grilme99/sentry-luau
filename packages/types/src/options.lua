export type ClientOptions<TO = BaseTransportOptions> = TO & {
    --- Sample rate to determine trace sampling.
    ---
    --- 0.0 = 0% chance of a given trace being sent (send no traces) 1.0 = 100% chance of a given trace being sent (send
    --- all traces)
    ---
    --- Tracing is enabled if either this or `tracesSampler` is defined. If both are defined, `tracesSampleRate` is
    --- ignored.
    tracesSampleRate: number?,

    --- If this is enabled, transactions and trace data will be generated and captured.
    --- This will set the `tracesSampleRate` to the recommended default of `1.0` if `tracesSampleRate` is undefined.
    --- Note that `tracesSampleRate` and `tracesSampler` take precedence over this option.
    enableTracing: boolean?,

    --- A global sample rate to apply to all events.
    ---
    --- 0.0 = 0% chance of a given event being sent (send no events) 1.0 = 100% chance of a given event being sent (send
    --- all events)
    sampleRate: number?,

    --- Function to compute tracing sample rate dynamically and filter unwanted traces.
    ---
    --- Tracing is enabled if either this or `tracesSampleRate` is defined. If both are defined, `tracesSampleRate` is
    --- ignored.
    ---
    --- Will automatically be passed a context object of default and optional custom data. See
    --- {@link Transaction.samplingContext} and {@link Hub.startTransaction}.
    ---
    --- @return A sample rate between 0 and 1 (0 drops the trace, 1 guarantees it will be sent). Returning `true` is
    --- equivalent to returning 1 and returning `false` is equivalent to returning 0.
    tracesSampler: ((samplingContext: SamplingContext) -> number | boolean)?,
}

--- Base configuration options for every SDK.
export type Options<TO = BaseTransportOptions> = ClientOptions<TO> & {}

return {}
