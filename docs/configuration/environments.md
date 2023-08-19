---
sidebar_position: 2
---

# Environments

Environments tell you where an error occurred, whether that's in your production system, your staging server, or
elsewhere.

Sentry automatically creates an environment when it receives an event with the `environment` parameter set.

Environments are case sensitive. The environment name can't contain newlines, spaces or forward slashes, can't be the string "None", or exceed 64 characters. You can't delete environments, but you can [hide](https://docs.sentry.io/product/sentry-basics/environments/#hidden-environments) them.

```lua
Sentry.init({
  environment = "production",
})
```

Environments help you better filter issues, releases, and user feedback in the Issue Details page of sentry.io, which
you learn more about in the [documentation that covers using environments](https://docs.sentry.io/product/sentry-basics/environments/).
