-- upstream: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/types/src/extra.ts

type Record<K, V> = { [K]: V }

export type Extra = unknown;
export type Extras = Record<string, Extra>;

return {}
