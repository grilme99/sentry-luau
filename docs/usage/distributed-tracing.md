---
sidebar_position: 3
---

# Distributed Tracing

If the overall application landscape that you want to observe with Sentry consists of more than just a single service or
application, distributed tracing can add a lot of value.

## What is Distributed Tracing?

In the context of tracing events across a distributed system, distributed tracing acts as a powerful debugging tool.
Imagine your application as a vast network of interconnected parts. For example, your system might be spread across
different servers or your application might split into different backend and frontend services, each potentially having
their own technology stack.

When an error or performance issue occurs, it can be challenging to pinpoint the root cause due to the complexity of
such a system. Distributed tracing helps you follow the path of an event as it travels through this intricate web,
recording every step it takes. By examining these traces, you can reconstruct the sequence of events leading up to the
event of interest, identify the specific components involved, and understand their interactions. This detailed
visibility enables you to diagnose and resolve issues more effectively, ultimately improving the reliability and
performance of your distributed system.

## Basic Example

Here's an example showing a distributed trace in Sentry:

![Distributed Tracing Example](/distributed-trace-in-sentry.png)

This distributed trace shows a Vue app's `pageload` making a request to a Python backend, which then calls the `/api`
endpoint of a Ruby microservice.

What happens in the background is that Sentry uses reads and further propagates two HTTP headers between your
applications:

- `sentry-trace`
- `baggage`

If you run any Luau applications (like your Roblox game!) in your distributed system, make sure that those two headers
won't be blocked or stripped by your proxy servers, gateways, or firewalls.

## How to Use Distributed Tracing?

TODO: Distributed tracing is not currently implemented in the Luau SDK.
