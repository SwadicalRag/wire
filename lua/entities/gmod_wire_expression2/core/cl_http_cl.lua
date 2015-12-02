--[[

	Clientside HTTP library
	 - swadical 🍌

]]

--	Clientside HTTP is separate from serverside HTTP:
--		Serverside HTTP allows greater speeds than clientside HTTP and it is
--		up to the server owner to decide which extension should be enabled
--		through a convar (found in core/http.lua)

--	This library will mirror the functionality of core/http.lua as best as
--	possible, making sure any existing e2s which make use of the http library
--	are not broken by this extension

E2Lib.clHTTP = {}
local lib = E2Lib.clHTTP

lib.netMsgID = "wire_expression2_cl_http" -- open to change

-- string function(void)
function lib:newUID()
	return ("0x%08xf"):format(math.random(1,0xD4A51000))-- return 0x(hex) between 0 and 10^12
end

lib.rawRequest = http.Fetch
lib.segmentSize = 4 * 1024-- 4 kilobytes
lib.segmentBits = math.min(math.ceil(math.log(lib.segmentSize,2)) + 2,32)
lib.sendInterval = 0.5-- seconds
lib.HTTP_REQUEST_FAILED = 1024--enum for HTTP failure

-- void function(string id, number interval, function func)
-- Internal: Do not call.
function lib.timerCoroutine(id,interval,func)
	func = coroutine.wrap(func)
	timer.Create(id,interval,0,function()
		if func() then
			timer.Remove(id)
		end
	end)
end

-- string, string function(void)
-- Internal: Do not call.
function lib:decodeRequest()
	return net.ReadString(),net.ReadString()
end

-- void function(void)
-- Internal: Do not call.
function lib:handleIncomingRequest()
	local url,uid = self:decodeRequest()

	self:performRequest(url,uid)
end

-- void function(string url, string uid)
-- Internal: Do not call.
function lib:performRequest(url,uid)
	self.rawRequest(url,function(body,length,headers,code)
		self.timerCoroutine("wire_e2_cl_http_"..uid,self.sendInterval,function()
			return self:returnData(uid,body,length,headers,code)
		end)
	end,function(err)
		self:returnFailure(uid,err)
	end)
end

-- void function(string uid, string body, number length, table headers, number code)
-- Internal: Do not call.
function lib:returnData(uid,body,length,headers,code)
	local body_compressed = util.Compress(body) or ""

	self:writeHTTPBody(uid,body_compressed,#body_compressed)
	self:writeMetadata(uid,length,headers,code)

	return true
end

-- void function(string uid, string body_compressed, number length)
-- Internal: Do not call.
function lib:writeHTTPBody(uid,body,length)
	local segments = math.ceil(length/self.segmentSize)

	-- reliable netmessages are always sent in order
	for i=1,segments do
		local segment = body:sub(self.segmentSize * (i-1) + 1,self.segmentSize * i)
		net.Start(self.netMsgID)
			net.WriteString(uid)						-- this is who we are
			net.WriteBool(false)						-- No; the request did not error
			net.WriteBool(true)							-- yes we are writing a body
			net.WriteInt(#segment,self.segmentBits)		-- the body is this much long
			net.WriteData(segment,#segment)				-- and here is the body
		net.SendToServer()

		coroutine.yield()
	end
end

-- void function(string uid, number length, table headers, number code)
-- Internal: Do not call.
function lib:writeMetadata(uid,length,headers,code)
	net.Start(self.netMsgID)
		net.WriteString(uid)						-- this is who we are
		net.WriteBool(false)						-- No; the request did not error
		net.WriteBool(false)						-- we are ready to finalise the message
		-- CAPITAL SIN: net.WriteTable is horribly
		-- unoptimised; but there is no other
		-- elegant solution to write in a variable
		-- table
		net.WriteTable(headers)						-- these are the headers
		net.WriteInt(code,12)						-- and this is the code
	net.SendToServer()
end

-- void function(string uid, string err)
-- Internal: Do not call.
function lib:returnFailure(uid,err)
	net.Start(self.netMsgID)
		net.WriteString(uid)	-- this is who we are
		net.WriteBool(true)		-- unfortunately, the request caused an error
		net.WriteString(err)	-- and this is the code
	net.SendToServer()
end

net.Receive(lib.netMsgID,function(_,ply)
	lib:handleIncomingRequest(ply)
end)
