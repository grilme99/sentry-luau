curl -O https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua
rojo sourcemap test.project.json > sourcemap.json

luau-lsp analyze --sourcemap sourcemap.json --platform roblox --settings .vscode/settings.json modules/
