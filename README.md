<p align="center">
  <a href="https://sentry.io/?utm_source=github&utm_medium=logo" target="_blank">
    <img src="https://sentry-brand.storage.googleapis.com/sentry-wordmark-dark-280x84.png" alt="Sentry" width="280" height="84">
  </a>
</p>

[![CI](https://github.com/Neura-Studios/sentry-lua/actions/workflows/ci.yml/badge.svg)](https://github.com/Neura-Studios/sentry-lua/actions/workflows/ci.yml)

# Unofficial Sentry SDKs for Lua

A set of Sentry SDKs for various Lua environments. Primarily built for Roblox, PRs are welcome for other platforms.
To simplify design and implementation, these SDKs are hand-translated from the [Sentry JavaScript SDK](https://github.com/getsentry/sentry-javascript) (with deviations for Lua and Roblox specific constructs).

## Links

- [![Documentation](https://img.shields.io/badge/documentation-github-green.svg)](https://Neura-Studios.github.io/sentry-lua)
- [![Discord](https://img.shields.io/discord/621778831602221064)](https://discord.gg/MWHzBd68aR)

## Contents

- [Contributing](https://github.com/Neura-Studios/sentry-lua/blob/main/CONTRIBUTING.md)
- [Supported Platforms](#supported-platforms)
- [Installation and Usage](#installation-and-usage)
- [Other Packages](#other-packages)

## Supported Platforms

We want to support all major Lua platforms with a high-level SDK, but only have the bandwidth to support the platforms
we use ourselves. If you'd like to add support for a Lua-based platform that isn't already supported, please refer to
our [contribution guide](https://github.com/Neura-Studios/sentry-lua/blob/main/CONTRIBUTING.md)!

Please refer to the README and instructions of each SDK for more detailed information:

- [`sentry-roblox`](https://github.com/Neura-Studios/sentry-lua/tree/main/packages/roblox): SDK for Roblox

## Installation and Usage

To install an SDK, add the high-level package. For example, with [Wally](https://wally.run):

```toml
# wally.toml
[dependencies]
Sentry = "neura-studios/sentry-roblox@1.0.0"
```

```sh
wally install
```

Setup and usage of these SDKs always follows the same principle.

```lua
local Sentry = require(Path.To.Sentry)

Sentry.init({
  dsn = "__DSN__",
  -- ...
})

Sentry.captureMessage("Hello, world!")
```

## Other Packages

Besides the high-level SDKs, this repository contains shared packages, helpers and configuration used for SDK
development. If you're thinking about contributing to or creating a Lua-based SDK, have a look at the resources
below:

- [`sentry-core`](https://github.com/Neura-Studios/sentry-lua/blob/main/packages/core): The base for all
  Lua SDKs with type definitions and base classes.
- [`sentry-utils`](https://github.com/Neura-Studios/sentry-lua/blob/main/packages/utils): A set of helpers and
  utility functions useful for various SDKs.
- [`sentry-types`](https://github.com/Neura-Studios/sentry-lua/blob/main/packages/types): Types used in all
  packages.
