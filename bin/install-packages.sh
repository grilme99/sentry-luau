wally install
rojo sourcemap test.project.json > sourcemap.json
wally-package-types --sourcemap sourcemap.json Packages/
wally-package-types --sourcemap sourcemap.json DevPackages/
