--------------------------------------------------------------------------
-- Module to extract Mysql Process Information for Boundary Lua Mysql Plugin
--
-- Author: Yegor Dia
-- Email: yegordia at gmail.com
--
--------------------------------------------------------------------------

local object = require('core').Object
local ffi = require("ffi")
local MySQL = require("luvit-mysql/mysql")
local uv = require('uv')
local timer = require('timer')

_G.KEEP_ALIVE_TIME_MS = 1000000

--[[ Check os for binding library path

if ffi.os == "Windows" then
	p("windows OS")
end
]]

local function callIfNotNil(callback, ...)
    if callback ~= nil then
        callback(...)
    end
end

local MySQLInfo = object:extend()

--[[ Initialize MySQLInfo with connection parameters
]]
function MySQLInfo:initialize(host, port, user, pwd, database, source)	
	self.host = host
	self.port = port
	self.user = user
	self.pwd = pwd
	self.db = database
	self.source = source
	self.connection = nil
	return self
end

--[[ Establishing method required to be used before every query
]]
function MySQLInfo:establish(queries_callback)
	self.connection = MySQL.createClient( { host = self.host, database = self.db, user = self.user, port = self.port, password = self.pwd, logfunc=nil } )	
	callIfNotNil(queries_callback, self.connection)
	
	return self
end


--[[ Abort TCP MySQL connection
]]
function MySQLInfo:abort(connection, queries_callback)
	self.connection.socket:shutdown()
	callIfNotNil(queries_callback)
end


--[[ Test function
]]
function MySQLInfo:test(connection, callback)

	connection:query( string.format("CREATE DATABASE %s", self.db .. self.source), function(err)
		if err and err.number ~= MySQL.ERROR_DB_CREATE_EXISTS then
			error("cannot create db" )
		end
	end)

	connection:query( string.format("USE %s", self.db .. self.source) )

	connection:query( "DROP TABLE IF EXISTS testtable", function(err,res,fields)
		assert(not err)
	end)

	connection:query( "CREATE TABLE testtable (id INT(11) AUTO_INCREMENT, name VARCHAR(255), age INT(11), created DATETIME, PRIMARY KEY (id) )",
		function(err,res,fields)
			assert( not err )
			
			
			connection:query( "INSERT INTO testtable SET name = 'ken', age = 40, created=now()",
			function(err)
				assert( not err )
			end)
			
			connection:query( "SELECT * FROM testtable", function(err,res,fields)
			
				p(fields.name.fieldType, MySQL.FIELD_TYPE_VAR_STRING)
				for i,v in ipairs(res) do
					p(v.id, v.name, v.age, v.created.year, v.created.month, v.created.day )
				end
				callIfNotNil(callback)
		end)
	end)
	
	
end

--[[ Get main server status metrics
]]
function MySQLInfo:get_server_status_metrics(connection, callback)

	connection:query( "SHOW GLOBAL STATUS WHERE Variable_name = 'Queries' OR 1=1;", function(err, res)
		timer.setTimeout(80, function ()
			local result = {}
			for index, value in ipairs(res) do
				result[value["Variable_name"]] = value["Value"]
			end
			callIfNotNil(callback, result)
		end)
	end)
	
end


--[[ Get stats per sec
]]
function MySQLInfo:get_stats_per_sec(connection, callback)

	connection:query( "SHOW GLOBAL STATUS;", function(err, firstQueryRes)
		local firstQuery = {}
		for index, value in ipairs(firstQueryRes) do
			firstQuery[value["Variable_name"]] = value["Value"]
		end
		timer.setTimeout(1000, function ()
			connection:query( "SHOW GLOBAL STATUS;", function(err, secondQueryRes)
				local secondQuery = {}
				for index, value in ipairs(secondQueryRes) do
					secondQuery[value["Variable_name"]] = value["Value"]
				end
				
				local QueriesPerSecValue = tonumber(secondQuery['Queries']) - tonumber(firstQuery['Queries'])
				
				
				callIfNotNil(callback, {Queries_per_sec = QueriesPerSecValue})
			end)
		end)
	end)
	
end


return MySQLInfo