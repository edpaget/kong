local BasePlugin = require "kong.plugins.base_plugin"
local singletons = require "kong.singletons"
local responses = require "kong.tools.responses"
local constants = require "kong.constants"
local meta = require "kong.meta"

local RequestTerminationHandler = BasePlugin:extend()

RequestTerminationHandler.PRIORITY = 2
RequestTerminationHandler.VERSION = "0.1.0"

function RequestTerminationHandler:new()
  RequestTerminationHandler.super.new(self, "request-termination")
end

function RequestTerminationHandler:access(conf)
  RequestTerminationHandler.super.access(self)

  local status_code = conf.status_code
  local content_type = conf.content_type
  local body = conf.body
  local message = conf.message
  if body then
    ngx.status = status_code

    if not content_type then
      content_type = "application/json; charset=utf-8";
    end
    ngx.header["Content-Type"] = content_type

    if singletons.configuration.enabled_headers[constants.HEADERS.SERVER] then
      ngx.header["Server"] = meta._SERVER_TOKENS

    else
      ngx.header["Server"] = nil
    end

    ngx.say(body)

    return ngx.exit(status_code)
   else
    return responses.send(status_code, message)
  end
end

return RequestTerminationHandler
