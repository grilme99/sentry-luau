build:
    rojo build --output SentrySdk.rbxm

build-example: example-sourcemap
    rojo build --output example/SentryExample.rbxl example.project.json

example-sourcemap:
    echo "{}" > example-sourcemap.json
    rojo sourcemap --output example-sourcemap.json example.project.json
