local fs       = require('fs')
local timer    = require('timer')
local mysql    = require("mysql")
local boundary = require('boundary')


local __pgk = "BOUNDARY MYSQL"

function berror(err)
  if err then print(string.format("%s ERROR: %s", __pgk, tostring(err))) return err end
end

-- get the natural difference between a and b
function diff(a, b)
    if a == nil or b == nil then return 0 end
    return math.max(a - b, 0)
end

--  If you want to return a float from Lua you should return it as a string,
function float(x)
  n = tonumber(x)
  if n == nil then return 0 end
  return tostring(n / 10.0)
end

-- to number
function parse(x)
  n = tonumber(x)
  if n == nil then return 0 else return n end
end

-- get the natural sum of the passed in values
function sum(...)
  if arg == nil then return 0 end
  for i,v in ipairs(arg) do
    s = s + tonumber(v)
  end
  return math.max(s, 0)
end

-- concat two tables
function concat(t1, t2)
   for k,v in ipairs(t2) do
      table.insert(t1, v)
   end
   return t1
end

local poll = 1000
local host = "127.0.0.1"
local port = 3306
local source
local user
local pass

if (boundary.param ~= nil) then
  poll = boundary.param['poll'] or poll
  host = boundary.param['hostname'] or host
  port = boundary.param['port'] or port
  user = boundary.param['username']
  pass = boundary.param['password']
  source = (type(boundary.param.source) == 'string' and boundary.param.source:gsub('%s+', '') ~= '' and boundary.param.source) or
   io.popen("uname -n"):read('*line')
end

if not pass or not user then return berror("User and password required") end

local client = mysql.createClient({
   port     = port,
   host     = host,
   user     = user,
   password = pass
})

print("_bevent:Mysql plugin up : version 1.0|t:info|tags:mysql,lua,plugin")

local _previous = {}
timer.setInterval(poll, function ()

  client:query("SHOW GLOBAL STATUS", function(err, status, _)
    if berror(err) then return end

    client:query("SHOW GLOBAL VARIABLES", function(err2, vars, _)
      if berror(err2) then return end

      local adjusted = {}
      local current = {}

      concat(status, vars)

      for i, row in ipairs(status) do
        local c = parse(row.Value)
        current[row.Variable_name] = c
        adjusted[row.Variable_name] = diff(c, _previous[row.Variable_name])
      end

      print(string.format('MYSQL_CONNECTIONS %d %s', adjusted.Connections), source)
      print(string.format('MYSQL_ABORTED_CONNECTIONS %d %s', sum(adjusted.Aborted_connects, adjusted.Aborted_clients)), source)
      print(string.format('MYSQL_BYTES_IN %d %s', adjusted.Bytes_received), source)
      print(string.format('MYSQL_BYTES_OUT %d %s', adjusted.Bytes_sent), source)
      print(string.format('MYSQL_SLOW_QUERIES %d %s', adjusted.Slow_queries), source)
      print(string.format('MYSQL_ROW_MODIFICATIONS %d %s', sum(adjusted.Handler_write, adjusted.Handler_update, adjusted.Handler_delete)), source)
      print(string.format('MYSQL_ROW_READS %d %s', sum(adjusted.Handler_read_first, adjusted.Handler_read_key, adjusted.Handler_read_next,adjusted.Handler_read_prev, adjusted.Handler_read_rnd, adjusted.Handler_read_rnd_next)), source)
      print(string.format('MYSQL_TABLE_LOCKS %d %s', adjusted.Table_locks_immediate), source)
      print(string.format('MYSQL_TABLE_LOCKS_WAIT %d %s', adjusted.Table_locks_waited), source)
      print(string.format('MYSQL_COMMITS %d %s', adjusted.Handler_commit), source)
      print(string.format('MYSQL_ROLLBACKS %d %s', adjusted.Handler_rollback), source)
      print(string.format('MYSQL_QCACHE_PRUNES %d %s', adjusted.Qcache_lowmem_prunes), source)
      _previous = current

    end)
  end)
end)


