---
sidebar_position: 2
---

# Custom Integrations

Add a custom integration to your Lua using the following format:

```lua
-- All integrations that come with an SDK can be found on Sentry.Integrations object
-- Custom integration must conform to the Integration interface: https://github.com/Neura-Studios/sentry-lua/blob/78ee9d053dd572e2e34ebe6653161ac1fdf9b521/packages/types/src/_recursiveModules.lua#L989-L1000

Sentry.init({
  -- ...
  integrations = {MyAwesomeIntegration.new()},
});
```
