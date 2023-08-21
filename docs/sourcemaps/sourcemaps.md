---
sidebar_position: 5
---

# Source Maps

By default, the errors Sentry receives from Roblox will use the Instance path of scripts. For example:

![Datamodel Stacktraces Example](/datamodel-stacktraces.png)

This works fine, but prevents you from accessing several useful Sentry features (such as [GitHub Stacktrace Linking](https://docs.sentry.io/product/integrations/source-code-mgmt/github/#stack-trace-linking) and [GitHub Code Owners](https://docs.sentry.io/product/integrations/source-code-mgmt/github/#code-owners)). Additionally, Instance paths are not the easiest to parse
when debugging issues in production.

The Roblox SDK supports using [Rojo sourcemaps](https://github.com/rojo-rbx/rojo/pull/530) to map Instance paths back to
their original path on the file system. This works for both full-managed and partially-managed Rojo projects, as long as
the scripts in your stacktrace are included in the sourcemap. If an Instance path cannot be resolved from the sourcemap,
the SDK will fall back to the original Instance path and output a warning (in debug mode).

## Sourcemap Setup

Sourcemaps must be manually built with the Rojo CLI, and then included in your relevant `*.project.json` file.
To generate a sourcemap file, run the following command (replacing `default.project.json` as required):

```sh
rojo sourcemap default.project.json --output sourcemap.json
```

Once you've built a sourcemap, you should include it in your Rojo project. For example:

```json
{
    "name": "project-name",
    "tree": {
        "$className": "DataModel",
        "ReplicatedStorage": {
            "Sourcemap": {
                "$path": "sourcemap.json"
            }
        },
    }
}
```

Note that there are a few gotchas with this approach, so please refer to the
[Troubleshooting Guide](/docs/sourcemaps/troubleshooting) if you run into any problems.

## Configuration

Once you have a sourcemap included in your project, you need to add it to the Sentry configuration. Rojo converts `json`
files to standard tables in a `ModuleScript`, so you can import your sourcemap like you would any other module.

```lua
local Sourcemap = require(Path.To.Sourcemap)

Sentry.init({
    dsn = "__DSN__",

    -- Depending on your Luau configuration, your imported Sourcemap file may
    -- not be given the correct type statically. Unfortunately, the only way
    -- to get around this is casting to `any`.
    projectSourcemap = Sourcemap :: any,
})
```

Once configured, your errors should start sending with filesystem paths:

![Path Stacktraces Example](/path-stacktraces.png)
