analyze: example-sourcemap
    curl -O https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua
    luau-lsp analyze --definitions=globalTypes.d.lua --base-luaurc=.luaurc --sourcemap=example-sourcemap.json --settings=.vscode/settings.json --flag:LuauTinyControlFlowAnalysis=true --no-strict-dm-types packages/

build:
    rojo build --output SentrySdk.rbxm

build-example: example-sourcemap
    rojo build --output example/SentryExample.rbxl example.project.json

example-sourcemap:
    echo "{}" > example-sourcemap.json
    rojo sourcemap --output example-sourcemap.json example.project.json
