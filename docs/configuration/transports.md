---
sidebar_position: 4
---

# Transports

The Lua SDKs use a `transport` to send events to Sentry. On Roblox, the `HttpService` API is used to send events.
Transports will drop an event if it fails to send due to a lack of connection.

## `HttpServiceTransport`

This transport is enabled by default for Roblox, and likely will not need to be changed. It exposes some basic
configuration:

```lua
type RobloxTransportOptions = {
    --- Custom headers for the transport.
    headers: Map<string, string>?,
}
```
