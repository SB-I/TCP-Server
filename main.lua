TCP = TCP or {};
--TCP.make_client(host, port, ConnectionMade, line_handle, disconn_handle)
--host, port, conn_handler, line_handler, disconn_handler

--[[
local function conn_handle()
  print("Connected.");
  conn:Send("Test")
end;

local function disconn_handle()
  print("Disconnected.");
end;

local function line_handle()
  print("Incoming Line.");
end;
]]--[[
connect = function(host, port)
    local host = "25.27.158.232";

    local body = ""
    local header = {}
    header.status = false
    local buffer = ""
    local to_body = false
    local active = false
    local appended = false
    local _, path, sock, type, length, rest
    local port = 1904
    local gotit = false
    local nolen = false
    local postthis = ""
    local callback = nil;

local function callcallback(suc, hd, pg)
  active = false
  if (sock) and (sock.tcp) then
      sock.tcp:Disconnect()
  end
  sock = nil
  if not (callback == nil) then
      return callback(suc, hd, pg)
  end
end


local function ConnectionTimeOut()
  if active and sock then
      return callcallback("Connection timed out", nil, nil)
  end
end



local function LineReceived(con, line)
  if line == '\r' then
to_body = true
  end
  if not header.status and string.find(line, "^HTTP") then
      header.status = tonumber(string.sub(line, 10, 10+3))
  end

  if to_body then
      body = body..line..'\n'
      local curlen = string.len(body)
      if not (length == nil) then
          if curlen == length or curlen > length or length == 0 then
              gotit = true
              return callcallback(false, header, body)
          end
      else
          if not nolen then
              print('-- don\'t know the length, waiting for the connection to get closed by the webserver')
              nolen = true
          end
      end
  else
      local var, val
      _, _, var, val = string.find(line, "(.*): (.*)")
      if not (var == nil) and not (val == nil) then
          for wanted, real in pairs(wanted_headers) do
              if var == real then
                  header[wanted] = val
              end
          end
      end

      if string.find(line, "^Content(.*)Length") and length == nil then
          _, _, _, length = string.find(line, "Content(.*): (.*)$")
          length = tonumber(length)
      end
  end
end

local function ConnectionMade(con, suc)
  if not (suc == nil) then
      return callcallback(suc, nil, nil)
  else
      con:Send(200)
      local t = Timer()
      active = true
      t:SetTimeout(15000, ConnectionTimeOut)
  end
end

local function ConnectionLost(con)
  print("Server connection lost.");
  --print('TCFT Data Collector lost connection')
  if (header.status) then
      return callcallback(false, header, body)
  else
      return callcallback("Unknown error", nil, nil)
  end
end
print("Host:"..host.."  Port:"..port)

sock = TCP.make_client(host, port, ConnectionMade, LineReceived, ConnectionLost)

end;
-- This whole thing was written by Andy Sloane, a1k0n, one of the Vendetta
-- Online developers over at Guild Software
-- http://a1k0n.net/vendetta/lua/tcpstuff/
-- http://www.guildsoftware.com/company.html

local function SetupLineInputHandlers(conn, conn_handler, line_handler, disconn_handler)
  local buf = ''
  local match
  local connected

  conn.tcp:SetReadHandler(function()
    local msg, errcode = conn.tcp:Recv()
    if not msg then
      if not errcode then return end
      local err = conn.tcp:GetSocketError()
      conn.tcp:Disconnect()
      disconn_handler(conn)
      conn = nil
      return
    end
    buf = buf..msg
    repeat
      buf,match = string.gsub(buf, "^([^\n]*)\n", function(line)
        pcall(line_handler, conn, line)
        return ''
      end)
    until match==0
  end)

  local writeq = {}
  local qhead,qtail=1,1

  -- returns true if some data was written
  -- returns false if we need to schedule a write callback to write more data
  local write_line_of_data = function()
    --print(tostring(conn)..': sending  '..writeq[qtail])
    local bsent = conn.tcp:Send(writeq[qtail])
    -- if we sent a partial line, keep the rest of it in the queue
    if bsent == -1 then
      -- EWOULDBLOCK?  dunno if i can check for that
      return false
      --error(string.format("write(%q) failed!", writeq[qtail]))
    elseif bsent < string.len(writeq[qtail]) then
      -- consume partial line
      writeq[qtail] = string.sub(writeq[qtail], bsent+1, -1)
      return false
    end
    -- consume whole line
    writeq[qtail] = nil
    qtail = qtail + 1
    return true
  end

  -- returns true if all available data was written
  -- false if we need a subsequent write handler
  local write_available_data = function()
    while qhead ~= qtail do
      if not write_line_of_data() then
        return false
      end
    end
    qhead,qtail = 1,1
    return true
  end

  local writehandler = function()
    if write_available_data() then
      conn.tcp:SetWriteHandler(nil)
    end
  end

  function conn:Send(line)
    --print(tostring(conn)..': queueing '..line)
    writeq[qhead] = line
    qhead = qhead + 1
    if not write_available_data() then
      conn.tcp:SetWriteHandler(writehandler)
    end
  end

  local connecthandler = function()
    conn.tcp:SetWriteHandler(writehandler)
    connected = true
--    local err = conn.tcp:GetSocketError()
--    if err then
--      if string.find(err,'WSAEWOULDBLOCK') then
--        for count = 1,1000000 do end
--        err = conn.tcp:GetSocketError()
--      end
--    end
--    if err then
----    if not string.find(err, "BLOCK") then
--      conn.tcp:Disconnect()
--      return conn_handler(nil, err)
--    end
    return conn_handler(conn)
  end

  conn.tcp:SetWriteHandler(connecthandler)
end

-- raw version
function TCP.make_client(host, port, conn_handler, line_handler, disconn_handler)
  local conn = {tcp=TCPSocket()}

  SetupLineInputHandlers(conn, conn_handler, line_handler, disconn_handler)

  local success,err = conn.tcp:Connect(host, port)
  if not success then return conn_handler(nil, err) end

  return conn
end

function TCP.make_server(port, conn_handler, line_handler, disconn_handler)
  local conn = TCPSocket()
  local connected = false
  local buf = ''
  local match

  conn:SetConnectHandler(function()
    local newconn = conn:Accept()
    --print('Accepted connection '..newconn:GetPeerName())
    SetupLineInputHandlers({tcp=newconn}, conn_handler, line_handler, disconn_handler)
  end)
  local ok, err = conn:Listen(port)
  if not ok then error(err) end

  return conn
end

]]




--[[
local function connect(host, port)

end;

local function read(line)
	if(not line)then
		print("Server:: read:: Nothing to read!");
		return false;
	else
		print("Server:: Read:: "..line);
	end;
end;

local function write(line)
	if(not line)then
		print("Server:: Write:: Nothing to write!");
		return false;
	else
		print("Server:: Write:: "..line);
	end;
end;




]]





local function SetupLineInputHandlers(conn, conn_handler, line_handler, disconn_handler)
	local buf = ''
	local match
	local connected

	conn.tcp:SetReadHandler(function()
	  local msg, errcode = conn.tcp:Recv()
	  if not msg then
		if not errcode then return end
		local err = conn.tcp:GetSocketError()
		conn.tcp:Disconnect()
		disconn_handler(conn)
		conn = nil
		return
	  end
	  --print("Server:: :: msg: "..msg)
	  --[[buf = buf..msg
	  repeat
		buf,match = string.gsub(buf, "^([^\n]*)\n", function(line)
		  pcall(line_handler, conn, line)
		  return ''
		end)
	  until match==0]]
	end)

	local writeq = {}
	local qhead,qtail=1,1

	-- returns true if some data was written
	-- returns false if we need to schedule a write callback to write more data
	local write_line_of_data = function()
	  --print(tostring(conn)..': sending  '..writeq[qtail])
	  local bsent = conn.tcp:Send(writeq[qtail])
	  -- if we sent a partial line, keep the rest of it in the queue
	  if bsent == -1 then
		-- EWOULDBLOCK?  dunno if i can check for that
		return false
		--error(string.format("write(%q) failed!", writeq[qtail]))
	  elseif bsent < string.len(writeq[qtail]) then
		-- consume partial line
		writeq[qtail] = string.sub(writeq[qtail], bsent+1, -1)
		return false
	  end
	  -- consume whole line
	  writeq[qtail] = nil
	  qtail = qtail + 1
	  return true
	end

	-- returns true if all available data was written
	-- false if we need a subsequent write handler
	local write_available_data = function()
	  while qhead ~= qtail do
		if not write_line_of_data() then
		  return false
		end
	  end
	  qhead,qtail = 1,1
	  return true
	end

	local writehandler = function()
	  if write_available_data() then
		conn.tcp:SetWriteHandler(nil)
	  end
	end

	function conn:Send(line)
	  --print(tostring(conn)..': queueing '..line)
	  writeq[qhead] = line
	  qhead = qhead + 1
	  if not write_available_data() then
		conn.tcp:SetWriteHandler(writehandler)
	  end
	end

	local connecthandler = function()
	  conn.tcp:SetWriteHandler(writehandler)
	  connected = true
  --    local err = conn.tcp:GetSocketError()
  --    if err then
  --      if string.find(err,'WSAEWOULDBLOCK') then
  --        for count = 1,1000000 do end
  --        err = conn.tcp:GetSocketError()
  --      end
  --    end
  --    if err then
  ----    if not string.find(err, "BLOCK") then
  --      conn.tcp:Disconnect()
  --      return conn_handler(nil, err)
  --    end
	  return conn_handler(conn)
	end

	conn.tcp:SetWriteHandler(connecthandler)
  end





TCP = TCP or {};
Server = {
  host = "25.27.158.232",
  port = "1904"
};
local connected = false;
local _, host, path, sock, type, length, rest
--connect(Server.host, Server.port);



local function disconnect(con)
	connected = false;
	if(sock) and (sock.tcp)then
		con:Send("101");--"Logout";
	end;
	sock = nil;
	print("Server:: Connection lost.")
end;

local function ConnectionTimeOut()
	if connected and sock then
		return disconnect();
	end
end

local function connection(con, err)
	if(err)then
		return print(err);
	else
	con:Send("100"); --"Login";
	local t = Timer();
	connected = true;
	t:SetTimeout(15000, ConnectionTimeOut)--If no response in 15s, end connection.
	end;
end

local function read(con, line)
	print("Server:: Con: "..con);
	print("Server:: Line: "..line);
  print("Server:: Read:: "..line);


  if(line == "100")then
    print("Logged in.");
  elseif(line == "101")then
    print("Logged out.");
    sock.tcp:Disconnect();
  else
    print("Unknown Serer Command: ["..line.."]");
  end;
end;

local function start()
	TCP.make_client(Server.host, Server.port, connection, read, disconnect);
end;

-- raw version
function TCP.make_client(host, port, connhandler, linehandler, disconnhandler)
	local conn = {tcp=TCPSocket()}

	SetupLineInputHandlers(conn, connhandler, linehandler, disconnhandler)

	local success,err = conn.tcp:Connect(host, port)
	if not success then return connhandler(nil, err) end

	return conn
end


RegisterUserCommand("conn", start);
RegisterUserCommand("disc", disconnect);
