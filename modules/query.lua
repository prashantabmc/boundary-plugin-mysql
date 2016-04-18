--[[

Copyright 2012 Kengo Nakajima. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

local Parser = require("parser")
local Util = require("util")
local Constants = require("_constants")
local table = require("table")
local math = require("math")

-- OK,RESULT_SET_HEADER, FIELD, EOF, ROW_DATA, ROW_DATA,EOF : 1,3,4,5,6,6,5,

Query={}
function Query:new(conf)
  local q = {
    sql = conf.sql,
    typeCast = conf.typeCast,
    log = conf.logfunc
  }
  q.callbacks = {}
  function q:on( evname, fn )
    self.callbacks[evname] = fn
  end

  function q:emit( evname, a,b )
    local cb = self.callbacks[evname]
    self.log("Query:emitting event. name:",evname, "func:", cb )
    if cb then cb(a,b) end
  end
  

  function q:handlePacket(packet)
    self.log( "query.handlePacket called. type:", packet.type )
    --[[print("DEBUG:","packet:",packet,"::::packet.length:",#packet)
          for k, v in ipairs(packet) 
          do
            print("DEBUG:","k,v::", k, v )
            for ki, va in ipairs(v)
	     do
		print("DEBUG::","ki,va::", ki,va)
             end
          end
    --]]
    if packet.type == Constants.OK_PACKET then
      self:emit("end", Util.packetToUserObject(packet) )
    elseif packet.type == Constants.ERROR_PACKET then
      packet.sql = self.sql
      self:emit( "error", Util.packetToUserObject(packet))
    elseif packet.type == Constants.FIELD_PACKET then
      if not self.fields then self.fields = {} end
      table.insert( self.fields, packet)
      self:emit( "field", packet )
    elseif packet.type == Constants.EOF_PACKET then
      if not self.eofs then
        self.eofs = 1
      else
        self.eofs = self.eofs + 1
      end
      if self.eofs == 2 then
        self:emit( "end", nil, self.rows, self.fields )
      end
    elseif packet.type == Constants.ROW_DATA_PACKET then
      self.row = {}
      self.rowIndex = 1 -- it's lua!
      self.field = nil
      packet:on("data", function(buffer,remaining)
          self.log("query row_data_packet receives data. buffer:", buffer, "remaining:", remaining, "nfields:", #self.fields, "ri:", self.rowIndex, "f:", self.field  )
          --print("DEBUG","query row_data_packet receives data. buffer:", buffer, "remaining:", remaining, "nfields:", #self.fields, "ri:", self.rowIndex, "f:", self.field  )

	  --print("DEBUG:","self.field", self.field)		
	  --print("DEBUG:","self.fields:", self.fields)
          --[[
          for k, v in ipairs(self.fields) 
          do
            print("DEBUG:","k,v::", k, v )
            for ki, va in ipairs(v)
	     do
		print("DEBUG::","ki,va::", ki,va)
             end
          end
          --]]
          if not self.field then
            --print("DEBUG:(inside if)", "self.rowIndex:",self.rowIndex)
	    --print("DEBUG:(inside if)","self.field", self.field,"#self.fields[self.rowIndex]:",self.fields[self.rowIndex])		
	    --print("DEBUG:","self.rowIndex:", self.rowIndex)
	    --if self.rowIndex > 2 then self.rowIndex=1 self.field=nil self.row ={} end -- prashanta
            self.field = self.fields[ self.rowIndex ]
	    --print("DEBUG(insife if after assignment):","self.field", self.field)		
	    if self.field ~= nil  then  -- prashanta added
	    
            	--print("DEBUG","self.field.name:",self.field.name)
            	--print("DEBUG","self.row[self.field.name]:",self.row[self.field.name])
			self.row[ self.field.name ] = ""
	    end -- prashanta added
          end
     
           if self.field ~= nil then  -- prashanta added
          if buffer then
            self.row[ self.field.name ] = self.row[ self.field.name ] .. buffer
          else
            self.row[ self.field.name ] = nil
          end
	  end  -- prashanta added

	  --print("DEBUG:","remaining:",remaining)  -- prashanta added
          if remaining and remaining > 0 then
            return
          end

	   -- print("DEBUG:befire","self.rowIndex:", self.rowIndex)
          self.rowIndex = self.rowIndex + 1
	    --print("DEBUG:after","self.rowIndex:", self.rowIndex)

          --print("DEBUG:","buffer:",buffer)  
          if self.typeCast and buffer then
	    if self.field ~= nil then -- prashanta added
            if self.field.fieldType == Constants.FIELD_TYPE_TIMESTAMP or self.field.fieldType == Constants.FIELD_TYPE_DATE or self.field.fieldType == Constants.FIELD_TYPE_DATETIME or self.field.fieldType == Constants.FIELD_TYPE_NEWDATE then
              self.row[self.field.name] = Util.convertStringDateToTable( self.row[self.field.name] )
            elseif self.field.fieldType == Constants.FIELD_TYPE_TINY or self.field.fieldType == Constants.FIELD_TYPE_SHORT or self.field.fieldType == Constants.FIELD_TYPE_LONG or self.field.fieldType == Constants.FIELD_TYPE_LONGLONG or self.field.fieldType == Constants.FIELD_TYPE_INT24 or self.field.fieldType == Constants.FIELD_TYPE_YEAR then
              self.row[self.field.name] = math.floor(tonumber( self.row[self.field.name], 10) )
            elseif self.field.fieldType == Constants.FIELD_TYPE_FLOAT or self.field.fieldType == Constants.FIELD_TYPE_DOUBLE then
              -- decimal types cannot be parsed as floats because
              -- V8 Numbers have less precision than some MySQL Decimals (lua too)
              self.row[self.field.name] = tonumber( self.row[self.field.name] )
            end
	    end -- prashanta added
          end

          if self.rowIndex == (#self.fields+1) then
            self:emit( "row", self.row )
            return
          end
          
          self.field = nil
        end)
    end
  end
  
  return q
end


return Query
