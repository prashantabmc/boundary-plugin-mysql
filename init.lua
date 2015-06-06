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
  self.client:query('SHOW /*!50002 GLOBAL */ STATUS', function (err, status, fields) 
    if err then
      self:emit('error', err.message)
    else
      self.client:query('SHOW GLOBAL VARIABLES', function (err, variables, fields)
        if (err) then
          self:emit('error', err.message)
        else
          local result = merge(status, variables)
          callback(result)
        end
      end)
    end
  end)
end

local function parse(data)
  local result = { curr = {}, diff = {}}
  for _, row in ipairs(data) do
    local value = tonumber(row.Value)
    if value then
      result.diff[row.Variable_name] = acc:accumulate(row.Variable_name, value)
      result.curr[row.Variable_name] = value
    end
  end
  return result
end

local ds = MySQLDataSource:new(params)

local plugin = Plugin:new(params, ds)
function plugin:onParseValues(data)
  local result = {}
  local parsed = parse(data)
  local curr = parsed.curr
  local diff = parsed.diff
  local qcache_memory_usage = (curr.query_cache_size - curr.Qcache_free_memory) / curr.query_cache_size;
  local qcache_hits = (diff.Com_select + diff.Qcache_hits) ~= 0 and (diff.Qcache_hits / (diff.Com_select + diff.Qcache_hits)) or 0
  result['MYSQL_CONNECTIONS'] = diff.Connections
  result['MYSQL_ABORTED_CONNECTIONS'] = sum({ diff.Aborted_connects, diff.Aborted_clients }) 
  result['MYSQL_BYTES_IN'] = diff.Bytes_received
  result['MYSQL_BYTES_OUT'] = diff.Bytes_sent
  result['MYSQL_SLOW_QUERIES'] = diff.Slow_queries
  result['MYSQL_ROW_MODIFICATIONS'] = sum({ diff.Handler_write, diff.Handler_update, diff.Handler_delete })
  result['MYSQL_ROW_READS'] = sum({ diff.Handler_read_first, diff.Handler_read_key, diff.Handler_read_next, diff.Handler_read_prev, diff.Handler_read_rnd, diff.Handler_read_rnd_next })
  result['MYSQL_TABLE_LOCKS'] = diff.Table_locks_immediate
  result['MYSQL_TABLE_LOCKS_WAIT'] = diff.Table_locks_waited
  result['MYSQL_COMMITS'] = diff.Handler_commit
  result['MYSQL_ROLLBACKS'] = diff.Handler_rollback
  result['MYSQL_QCACHE_HITS'] = qcache_hits
  result['MYSQL_QCACHE_PRUNES'] = diff.Qcache_lowmem_prunes
  result['MYSQL_QCACHE_MEMORY'] = qcache_memory_usage
  return result
end

plugin:run()
