---
sidebar_position: 1
---

# Sentry Roblox

> The Roblox SDK enables automatic reporting of errors and exceptions.

On this page, we get you up and running with the Sentry Roblox SDK, so that it will automatically report errors and
exceptions in your game.

Don't already have an account and Sentry project established? Head over to [sentry.io](https://sentry.io/signup/), then
return to this page.

## Install

To get started using the Sentry Roblox SDK, you need to install it. This can be done in several ways, but we recommend
[Wally](https://wally.run):

```toml
# wally.toml
[dependencies]
Sentry = "neura-studios/sentry-roblox@1.0.0"
```

```sh
wally install
```

## Configure

Configuration should happen as early as possible in your games's lifecycle.

Once this is done, the Roblox SDK captures all unhandled exceptions and transactions based on the sample rates set.

```lua
local Sentry = require(Path.To.Sentry)
local Sourcemap = require(Path.To.Sourcemap)

Sentry.init({
    dsn = "__DSN__",

    release = "my-game-name@2.3.12",
    integrations = {},

    -- Include stacktraces in error events.
    attachStacktrace = true,

    -- If you project is managed by Rojo, you can include
    -- a sourcemap for converting datamodel paths back to
    -- their original path on the file system.
    projectSourcemap = Sourcemap,
})
```

## Verify

This snippet includes an intentional error, so you can test that everything is working as soon as you set it up.

```lua
myUndefinedFunction()
```

> Errors triggered from within the Studio command bar are sandboxed, so will not trigger an error handler. Place the snippet directly in your code instead.

> Learn more about manually capturing an error or message in the [Usage documentation](/docs/usage).

To view and resolve the recorded error, log into [sentry.io](https://sentry.io/) and open your project. Clicking on the
error's title will open a page where you can see detailed information and mark it as resolved.

## Next Steps

- [Installation Methods](/docs/installation-methods)
  Review our alternate installation methods.
- [Configuration](/docs/configuration)
  Additional configuration options for the SDK.
- [Usage](/docs/usage)
  Use the SDK to manually capture errors and other events.
- [Source Maps](/docs/source-maps)
  Learn how to enable more usable stack traces in your Sentry errors.
- [Data Management](/docs/data-management)
  Manage your events by pre-filtering, scrubbing sensitive information, and forwarding them to other systems.
