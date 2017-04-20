-- This thread accepts incoming requests on one channel, and pushes back responses
-- on another channel.
-- These two channels can be passed as var args, or will otherwise default to
-- "http_requests" and "http_responses".
-- Requests need to be a single URL. This module currently only supports GET
-- requests.
local http = require("socket.http")

-- the channels that will be used to listen for incoming requests, and to return
-- responses
local request_channel, response_channel = ...
request_channel = request_channel or love.thread.getChannel("http_requests")
response_channel = response_channel or love.thread.getChannel("http_responses")

assert(request_channel)
assert(response_channel)
while(true) do
  local request_url = request_channel:demand()
  assert(type(request_url) == "string")
  local response, response_status, _,
        response_status_line = http.request(request_url)
  if not response then
    local err = response_status
    response_channel:push({
      url = request_url,
      success = false,
      error = err,
    })
  else
    response_channel:push({
      url = request_url,
      success = true,
      response = response,
      response_status = response_status,
      response_status_line = response_status_line,
    })
  end
end
