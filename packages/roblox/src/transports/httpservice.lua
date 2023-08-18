-- based on: https://github.com/getsentry/sentry-javascript/blob/540adac9ec81803f86a3a7f5b34ebbc1ad2a8d23/packages/browser/src/transports/fetch.ts

local PackageRoot = script.Parent
local Packages = PackageRoot.Parent.Parent

local Promise = require(Packages.Promise)

local Types = require(Packages.SentryTypes)
type Transport = Types.Transport
type TransportMakeRequestResponse = Types.TransportMakeRequestResponse
type TransportRequest = Types.TransportRequest
type PromiseLike<T> = Types.PromiseLike<T>

local Core = require(Packages.SentryCore)
local createTransport = Core.createTransport

local TransportTypes = require(script.Parent.types)
type RobloxTransportOptions = TransportTypes.RobloxTransportOptions

type Map<K, V> = { [K]: V }

local HttpServiceTransport = {}

-- This isn't typed by the Roblox API
type HttpServiceRequest = {
    Body: string?,
    Headers: Map<string, string>?,
    Method: ("CONNECT" | "DELETE" | "GET" | "HEAD" | "OPTIONS" | "PATCH" | "POST" | "PUT" | "TRACE")?,
    Url: string,
}

--- Creates a Transport that uses the HTTPService API to send events to Sentry.
function HttpServiceTransport.makeHttpServiceTransport(options: RobloxTransportOptions)
    local HttpService = game:GetService("HttpService")

    local function makeRequest(request: TransportRequest): PromiseLike<TransportMakeRequestResponse>
        local requestOptions: HttpServiceRequest = {
            Url = options.url :: any,
            Body = request.body,
            Method = "POST",
            Headers = options.headers,
        }

        return Promise.new(function(resolve, reject)
            local success, result = pcall(HttpService.RequestAsync, HttpService, requestOptions)
            if success then
                local encodeSuccess, encodeResult = pcall(HttpService.JSONDecode, HttpService, result.Body or "")
                local body = if encodeSuccess then encodeResult else result.Body

                local response: TransportMakeRequestResponse = {
                    statusCode = result.StatusCode,
                    body = body,
                    headers = {
                        ["x-sentry-rate-limits"] = result.Headers["X-Sentry-Rate-Limits"],
                        ["retry-after"] = result.Headers["Retry-After"],
                    },
                }

                return resolve(response)
            else
                return reject(result)
            end
        end)
    end

    return createTransport(options, makeRequest)
end

return HttpServiceTransport
