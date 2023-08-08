-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/user.ts

type Map<K, V> = { [K]: V }

export type User = Map<string, any> & {
    id: (string | number)?,
    ip_address: string?,
    email: string?,
    username: string?,
    segment: string?,
}

export type UserFeedback = {
    event_id: string,
    email: string,
    name: string,
    comments: string,
}

return {}
