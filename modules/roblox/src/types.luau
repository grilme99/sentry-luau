-- note: no upstream

type Array<T> = { T }

export type SourcemapEntry = {
    name: string,
    className: string,
    filePaths: Array<string>,
    children: Array<SourcemapEntry>?,
}

-- note: Moved here to avoid cyclic dependency between client.lua and stackparser.lua
export type RobloxStackParserOptions = {
    --- Rojo sourcemap for project, used for turning instance paths back to file system paths in stacktraces.
    projectSourcemap: SourcemapEntry?,
}

return {}
