---
sidebar_position: 8
---

# Shutdown and Draining

The default behavior of most SDKs is to send out events over the network asynchronously in the background. This means
that some events might be lost if the application shuts down unexpectedly. The SDKs provide mechanisms to cope with
this.

The `close` method optionally takes a timeout in seconds and returns a promise that resolves when all pending
events are flushed, or the timeout kicks in.

```lua
Sentry.close(2):andThen(function()
    -- perform something after close
end);
```

After a call to `close`, the current client cannot be used anymore. It's important to only call `close` immediately
before shutting down the application.

Alternatively, the `flush` method drains the event queue while keeping the client enabled for continued use.
