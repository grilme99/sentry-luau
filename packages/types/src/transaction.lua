-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/transaction.ts

local PackageRoot = script.Parent

local Context = require(PackageRoot.context)
type Context = Context.Context

local Envelope = require(PackageRoot.envelope)
type DynamicSamplingContext = Envelope.DynamicSamplingContext

local Instrumenter = require(PackageRoot.instrumenter)
type Instrumenter = Instrumenter.Instrumenter

local Measurement = require(PackageRoot.measurement)
type MeasurementUnit = Measurement.MeasurementUnit

local Misc = require(PackageRoot.misc)
-- type ExtractedNodeRequestData = Misc.ExtractedNodeRequestData
type Primitive = Misc.Primitive
-- type WorkerLocation = Misc.WorkerLocation

local Span = require(PackageRoot.span)
type Span = Span.Span
type SpanContext = Span.SpanContext

type Map<K, V> = { [K]: V }

-- deviation: Luau has no equivalent of Typescript's Partial type
type Partial<T> = T

--- Interface holding Transaction-specific properties
export type TransactionContext = SpanContext & {

    --- Human-readable identifier for the transaction
    name: string,

    --- If true, sets the end timestamp of the transaction to the highest timestamp of child spans, trimming
    --- the duration of the transaction. This is useful to discard extra time in the transaction that is not
    --- accounted for in child spans, like what happens in the idle transaction Tracing integration, where we finish the
    --- transaction after a given "idle time" and we don't want this "idle time" to be part of the transaction.
    trimEnd: boolean?,

    --- If this transaction has a parent, the parent's sampling decision
    parentSampled: boolean?,

    --- Metadata associated with the transaction, for internal SDK use.
    metadata: Partial<TransactionMetadata>,
}

-- deviation: Luau has no equivalent of Typescript's Pick type, manually write the interface
--- Data pulled from a `sentry-trace` header
-- export type TraceparentData = Pick<TransactionContext, "traceId" | "parentSpanId" | "parentSampled">
export type TraceparentData = {
    traceId: string?,
    parentSpanId: string?,
    parentSampled: boolean?,
}

--- Transaction "Class", inherits Span only has `setName`
export type Transaction = TransactionContext & Span & {

    --- @inheritDoc
    spanId: string,

    --- @inheritDoc
    traceId: string,

    --- @inheritDoc
    startTimestamp: number,

    --- @inheritDoc
    tags: Map<string, Primitive>,

    --- @inheritDoc
    data: Map<string, any>,

    --- Metadata about the transaction
    metadata: TransactionMetadata,

    --- The instrumenter that created this transaction.
    instrumenter: Instrumenter,

    --- Set the name of the transaction
    setName: (self: Transaction, name: string, source: TransactionSource?) -> (),

    --- Set the context of a transaction event
    setContext: (self: Transaction, key: string, context: Context) -> (),

    --- Set observed measurement for this transaction.
    ---
    --- @param name Name of the measurement
    --- @param value Value of the measurement
    --- @param unit Unit of the measurement. (Defaults to an empty string)
    setMeasurement: (self: Transaction, name: string, value: number, unit: MeasurementUnit) -> (),

    --- Returns the current transaction properties as a `TransactionContext`
    toContext: (self: Transaction) -> TransactionContext,

    ---Updates the current transaction with a new `TransactionContext`
    updateWithContext: (self: Transaction, transactionContext: TransactionContext) -> Transaction,

    --- Set metadata for this transaction.
    --- @hidden
    setMetadata: (self: Transaction, newMetadata: Partial<TransactionMetadata>) -> (),

    --- Return the current Dynamic Sampling Context of this transaction
    getDynamicSamplingContext: (self: Transaction) -> Partial<DynamicSamplingContext>,
}

--- Context data passed by the user when starting a transaction, to be used by the tracesSampler method.
export type CustomSamplingContext = Map<string, any>

--- Data passed to the `tracesSampler` function, which forms the basis for whatever decisions it might make.
---
--- Adds default data to data provided by the user. See {@link Hub.startTransaction}
export type SamplingContext = CustomSamplingContext & {

    --- Context data with which transaction being sampled was created
    transactionContext: TransactionContext,

    --- Sampling decision from the parent transaction, if any.
    parentSampled: boolean?,

    --- Object representing the URL of the current page or worker script. Passed by default when using the `BrowserTracing`
    --- integration.
    -- location: WorkerLocation?,

    --- Object representing the incoming request to a node server. Passed by default when using the TracingHandler.
    -- request: ExtractedNodeRequestData?,
}

export type TransactionMetadata = {
    --- The sample rate used when sampling this transaction
    sampleRate: number?,

    --- The Dynamic Sampling Context of a transaction. If provided during transaction creation, its Dynamic Sampling
    --- Context Will be frozen
    dynamicSamplingContext: Partial<DynamicSamplingContext>,

    --- For transactions tracing server-side request handling, the request being tracked.
    --- deviation: Not applicable to Luau currently.
    -- request: PolymorphicRequest?,

    ---Compatibility shim for transitioning to the `RequestData` integration. The options passed to our Express request
    --- handler controlling what request data is added to the event.
    --- TODO (v8): This should go away
    requestDataOptionsFromExpressHandler: Map<string, unknown>?,

    --- For transactions tracing server-side request handling, the path of the request being tracked.
    ---TODO: If we rm -rf `instrumentServer`, this can go, too
    requestPath: string?,

    ---Information on how a transaction name was generated.
    source: TransactionSource,

    ---Metadata for the transaction's spans, keyed by spanId
    spanMetadata: Map<string, Map<string, unknown>>,
}

--- Contains information about how the name of the transaction was determined. This will be used by the server to decide
--- whether or not to scrub identifiers from the transaction name, or replace the entire name with a placeholder.
export type TransactionSource =
    ---User-defined name 
    "custom"
    ---Raw URL, potentially containing identifiers 
    | "url"
    ---Parametrized URL / route 
    | "route"
    ---Name of the view handling the request 
    | "view"
    ---Named after a software component, such as a function or class name. 
    | "component"
    ---Name of a background task (e.g. a Celery task) 
    | "task"

return {}
