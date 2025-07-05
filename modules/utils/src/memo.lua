-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/utils/src/memo.ts

local Memo = {}

export type MemoFunc = {
    memoize: (obj: any) -> boolean,
    unmemoize: (obj: any) -> (),
}

function Memo.memoBuilder(): MemoFunc
    local inner: { any } = {}

    local function memoize(obj: any): boolean
        for _, value in inner do
            if value == obj then
                return true
            end
        end

        table.insert(inner, obj)
        return false
    end

    local function unmemoize(obj: any)
        table.remove(inner, table.find(inner, obj))
    end

    return {
        memoize = memoize,
        unmemoize = unmemoize,
    }
end

return Memo
