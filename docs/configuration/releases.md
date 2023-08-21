---
sidebar_position: 5
---

# Releases & Health

A release is a version of your code that is deployed to an [environment](/docs/configuration//environments.md). When
you give Sentry information about your releases, you can:

- Determine issues and regressions introduced in a new release
- Predict which commit caused an issue and who is likely responsible
- Resolve issues by including the issue number in your commit message
- Receive email notifications when your code gets deployed

## Bind the Version

Include a release ID (often called a "version") when you initialize the SDK.

The release name cannot:

- contain newlines, tabulator characters, forward slashes(/) or back slashes(\\)
- be (in their entirety) period (.), double period (..), or space ( )
- exceed 200 characters

The value can be arbitrary, but we recommend either of these naming strategies:

- **Semantic Versioning**: `package@version` or `package@version+build` (for example, `my.project.name@2.3.12+1234`)
  - `package` is the unique identifier of the project/app
  - `version` is the semver-like structure `<major>.<minor?>.<patch?>.<revision?>-<prerelease?>`
  - `build` is the number that identifies an iteration of your app
- **Commit SHA**: If you use a version control system like Git, we recommend using the identifying hash (for example,
  the commit SHA, `da39a3ee5e6b4b0d3255bfef95601890afd80709`). You can let Sentry CLI automatically determine this hash
  for supported version control systems. Learn more in the [Sentry CLI](https://docs.sentry.io/product/cli/releases/#creating-releases) documentation.

> Releases are global per organization; prefix them with something project-specific for easy differentiation.

The behavior of a few features depends on whether a project is using semantic or time-based versioning.

- Regression detection
- `release:latest`

Sentry automatically detects whether a project is using semantic or time-based versioning based on:

- If ≤ 2 releases total: Sentry looks at most recent release.
- If 3-9 releases (inclusive): if any of the most recent 3 releases is semver, project is semver.
- If 10 or more releases: if any of the most recent 3 releases is semver, and 3 out of the most recent 10 releases is
  semver, then - the project is semver.

## Setting a Release

```lua
Sentry.init({
    release = "my-project-name@2.3.12",
})
```

How you make the release name (or version) available to your code is up to you. For example, you could use a global `_G`
variable that is set during the build process (using [Darklua](https://darklua.com)) or during initial start-up.

Setting the release name tags each event with that release name. We recommend that you tell Sentry about a new release
before sending events with that release name, as this will unlock a few more features. Learn more in the
[Releases](https://docs.sentry.io/product/releases/) documentation.

If you don't tell Sentry about a new release, Sentry will automatically create a release entity in the system the first
time it sees an event with that release ID.

After configuring your SDK, you can install a repository integration or manually supply Sentry with your own commit
metadata. Read the documentation about [setting up releases](https://docs.sentry.io/product/releases/setup/) for further
information about integrations, associating commits, and telling Sentry when deploying releases.

## Release Health

Monitor the [health of releases](https://docs.sentry.io/product/releases/health/) by observing user adoption, usage of
the application, percentage of crashes, and session data. Release health will provide insight into the impact of crashes
and bugs as it relates to user experience, and reveal trends with each new issue through the Release Details graphs and
filters.

> App hang detection are not available for Roblox.

In order to monitor release health, the SDK sends session data.

### Sessions

A session represents the interaction between the user and the application. Sessions contain a timestamp, a status
(if the session was OK or if it crashed), and are always linked to a release. Most Sentry SDKs can manage sessions
automatically.

We mark the session as:

- crashed if an unhandled error or unhandled promise rejection bubbled up to the global handler.
- errored if the SDK captures an event that contains an exception (this includes manually captured errors).

To receive data on user adoption, such as users crash free rate percentage, and the number of users that have adopted a specific release, set the user on the [initialScope](/docs/configuration/options#initialscope) when initializing the SDK.

By default, the Roblox SDKs are sending sessions. To disable sending sessions, set the `autoSessionTracking` flag to
`false`:

```lua
Sentry.init({
  autoSessionTracking = false, -- default: true
})
```
