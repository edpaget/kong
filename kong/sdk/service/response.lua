local checks = require "kong.sdk.private.checks"


local bit = bit
local ngx = ngx
local sub = string.sub
local fmt = string.format
local gsub = string.gsub
local type = type
local error = error
local lower = string.lower
local tonumber = tonumber
local getmetatable = getmetatable
local check_phase = checks.check_phase
local ALL_PHASES = checks.phases.ALL_PHASES
local RESPONSE_PHASES = bit.bor(checks.phases.HEADER_FILTER,
                                checks.phases.BODY_FILTER,
                                checks.phases.LOG)


local function headers(response_headers)
  local mt = getmetatable(response_headers)
  local index = mt.__index
  mt.__index = function(_, name)
    if type(name) == "string" then
      local var = fmt("upstream_http_%s", gsub(lower(name), "-", "_"))
      if not ngx.var[var] then
        return nil
      end
    end

    return index(response_headers, name)
  end

  return response_headers
end


local function new(sdk, major_version)
  local response = {}


  local MIN_HEADERS            = 1
  local MAX_HEADERS_DEFAULT    = 100
  local MAX_HEADERS            = 1000


  function response.get_status()
    check_phase(RESPONSE_PHASES)

    return tonumber(sub(ngx.var.upstream_status or "", -3))
  end


  function response.get_headers(max_headers)
    check_phase(RESPONSE_PHASES)

    if max_headers == nil then
      return headers(ngx.resp.get_headers(MAX_HEADERS_DEFAULT))
    end

    if type(max_headers) ~= "number" then
      error("max_headers must be a number", 2)

    elseif max_headers < MIN_HEADERS then
      error("max_headers must be >= " .. MIN_HEADERS, 2)

    elseif max_headers > MAX_HEADERS then
      error("max_headers must be <= " .. MAX_HEADERS, 2)
    end

    return headers(ngx.resp.get_headers(max_headers))
  end


  function response.get_header(name)
    check_phase(RESPONSE_PHASES)

    if type(name) ~= "string" then
      error("name must be a string", 2)
    end

    local header_value = response.get_headers()[name]
    if type(header_value) == "table" then
      return header_value[1]
    end

    return header_value
  end


  function response.get_raw_body()
    check_phase(ALL_PHASES)

    -- TODO: implement
  end


  function response.get_body()
    check_phase(ALL_PHASES)

    -- TODO: implement
  end


  return response
end


return {
  new = new,
}
