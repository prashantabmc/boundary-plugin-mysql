-- Copyright 2015 Boundary, Inc.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local framework = require('framework')
local Plugin = framework.Plugin
local DataSource = framework.DataSource
local Accumulator = framework.Accumulator
local mysql = require('mysql')
local parseValue = framework.util.parseValue
local sum = framework.util.sum
local merge = framework.table.merge

local params = framework.params

local acc = Accumulator:new()

local MySQLDataSource = DataSource:extend()
function MySQLDataSource:initialize(opts)
  self.host = opts.host or 'localhost'
  self.port = opts.port or '3306'
  self.user = opts.user or 'root'
  self.password = opts.password
  self.logging = false
  self.client = mysql.createClient(self)
end

function MySQLDataSource:fetch(context, callback, params)
  self.client:query('SHOW GLOBAL STATUS', function (err, status, fields) 
    if err then
      p(err.message)
    else
      self.client:query('SHOW GLOBAL VARIABLES', function (err, variables, fields)
        local result = merge(status, variables)
        callback(result)
      end)
    end
  end)
end

local function parse(data)
  local result = {}
  for _, row in ipairs(data) do
    local value = tonumber(row.Value)
    if value then
      result[row.Variable_name] = acc:accumulate(row.Variable_name, value)
    end
  end
  return result
end

local ds = MySQLDataSource:new(params)

local plugin = Plugin:new(params, ds)
function plugin:onParseValues(data)
  local result = {}
  local parsed = parse(data)
  result['MYSQL_CONNECTIONS'] = parsed.Connections
  result['MYSQL_ABORTED_CONNECTIONS'] = sum({ parsed.Aborted_connects, parsed.Aborted_clients }) 
  result['MYSQL_BYTES_IN'] = parsed.Bytes_received
  result['MYSQL_BYTES_OUT'] = parsed.Bytes_sent
  result['MYSQL_SLOW_QUERIES'] = parsed.Slow_queries
  result['MYSQL_ROW_MODIFICATIONS'] = sum({ parsed.Handler_write, parsed.Handler_update, parsed.Handler_delete })
  result['MYSQL_ROW_READS'] = sum({ parsed.Handler_read_first, parsed.Handler_read_key, parsed.Handler_read_next, parsed.Handler_read_prev, parsed.Handler_read_rnd, parsed.Handler_read_rnd_next })
  result['MYSQL_TABLE_LOCKS'] = parsed.Table_locks_immediate
  result['MYSQL_TABLE_LOCKS_WAIT'] = parsed.Table_locks_waited
  result['MYSQL_COMMITS'] = parsed.Handler_commit
  result['MYSQL_ROLLBACKS'] = parsed.Handler_rollback
  result['MYSQL_QCACHE_PRUNES'] = parsed.Qcache_lowmem_prunes
  return result
end

plugin:run()
