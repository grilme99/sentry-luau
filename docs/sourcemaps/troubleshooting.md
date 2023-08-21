---
sidebar_position: 1
---

# Troubleshooting Source Maps

Setting up source maps can be tricky, but it's worth it to get it right. This page contains a list of common issues you
might encounter. If you run into anything not listed here, please consider contributing solutions you found!

## Rojo project cannot build without an existing Sourcemap file

In the sourcemap guide, you're instructed to add a `sourcemap.json` file to to your Rojo project file. This causes an
issue, because Rojo cannot build your project or the sourcemap unless a `sourcemap.json` file already exists. The error
might look like this:

```txt
[ERROR rojo] Rojo project referred to a file using $path that could not be turned into a Roblox Instance by Rojo.
        Check that the file exists and is a file type known by Rojo.
        
        Project path: {PROJECT_PATH}/example.project.json
        File $path: sourcemap.json
```

The solution to this problem is to create an empty `sourcemap.json` file before you build the real sourcemap. Here's the
commands we use:

```sh
echo "{}" > sourcemap.json
rojo sourcemap --output sourcemap.json example.project.json
```

Once you've generated the real sourcemap file, you can build your Rojo project as normal.
