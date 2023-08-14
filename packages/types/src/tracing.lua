-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/tracing.ts

local PackageRoot = script.Parent

local Envelope = require(PackageRoot.envelope)
type DynamicSamplingContext = Envelope.DynamicSamplingContext

type Array<T> = { T }

-- deviation: No support for RegExp currently
-- export type TracePropagationTargets = Array<string | RegExp>;
export type TracePropagationTargets = Array<string>

export type PropagationContext = {
    traceId: string,
    spanId: string,
    sampled: boolean,
    parentSpanId: string?,
    dsc: DynamicSamplingContext?,
}

return {}
