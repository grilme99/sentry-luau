-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/span.ts

local Instrumenter = require("./instrumenter")
type Instrumenter = Instrumenter.Instrumenter

local Misc = require("./misc")
type Primitive = Misc.Primitive

local Transaction = require("./transaction")
type Transaction = Transaction.Transaction

type Map<K, V> = { [K]: V }

--- Interface holding all properties that can be set on a Span on creation.
export type SpanContext = {
    --- Description of the Span.
    description: string?,

    --- Operation of the Span.
    op: string?,

    --- Completion status of the Span.
    --- See: {@sentry/tracing SpanStatus} for possible values
    status: string?,

    --- Parent Span ID
    parentSpanId: string?,

    --- Was this span chosen to be sent as part of the sample?
    sampled: boolean?,

    --- Span ID
    spanId: string?,

    --- Trace ID
    traceId: string?,

    --- Tags of the Span.
    tags: Map<string, Primitive>?,

    --- Data of the Span.
    data: Map<string, any>?,

    --- Timestamp in seconds (epoch time) indicating when the span started.
    startTimestamp: number?,

    --- Timestamp in seconds (epoch time) indicating when the span ended.
    endTimestamp: number?,

    --- The instrumenter that created this span.
    instrumenter: Instrumenter?,
}

--- Span holding trace_id, span_id
export type Span = SpanContext & {
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

    --- The transaction containing this span
    transaction: Transaction?,

    --- The instrumenter that created this span.
    instrumenter: Instrumenter,

    --- Sets the finish timestamp on the current span.
    --- @param endTimestamp Takes an endTimestamp if the end should not be the time when you call this function.
    finish: (self: Span, endTimestamp: number?) -> (),

    --- Sets the tag attribute on the current span.
    ---
    --- Can also be used to unset a tag, by passing `undefined`.
    ---
    --- @param key Tag key
    --- @param value Tag value
    setTag: (self: Span, key: string, value: Primitive) -> Span,

    --- Sets the data attribute on the current span
    --- @param key Data key
    --- @param value Data value
    setData: (self: Span, key: string, value: any) -> Span,

    --- Sets the status attribute on the current span
    --- See: {@sentry/tracing SpanStatus} for possible values
    --- @param status http code used to set the status
    setStatus: (self: Span, status: string) -> Span,

    --- Sets the status attribute on the current span based on the http code
    --- @param httpStatus http code used to set the status
    setHttpStatus: (self: Span, httpStatus: number) -> Span,

    --- Creates a new `Span` while setting the current `Span.id` as `parentSpanId`.
    --- Also the `sampled` decision will be inherited.
    startChild: (self: Span, spanContext: SpanContext?) -> Span,

    --- Determines whether span was successful (HTTP200)
    isSuccess: (self: Span) -> boolean,

    --- Return a traceparent compatible header string
    toTraceparent: (self: Span) -> string,

    --- Returns the current span properties as a `SpanContext`
    toContext: (self: Span) -> SpanContext,

    --- Updates the current span with a new `SpanContext`
    updateWithContext: (self: Span, spanContext: SpanContext) -> Span,

    --- Convert the object to JSON for w. spans array info only
    getTraceContext: (
        self: Span
    ) -> {
        data: Map<string, any>?,
        description: string?,
        op: string?,
        parent_span_id: string?,
        span_id: string,
        status: string?,
        tags: Map<string, Primitive>?,
        trace_id: string,
    },

    --- Convert the object to JSON
    toJSON: (
        self: Span
    ) -> {
        data: Map<string, any>,
        description: string?,
        op: string?,
        parent_span_id: string?,
        span_id: string,
        start_timestamp: number,
        status: string?,
        tags: Map<string, Primitive>?,
        timestamp: number?,
        trace_id: string,
    },
}

return {}
