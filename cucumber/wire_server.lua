local socket = require "builtins.scripts.socket"
local cucumber = require "cucumber.cucumber"
local rxi_json = require "cucumber.json"

local M = {}


function M.log(...)
	print(...)
end

function M.create(port)
	local instance = {}
	
	local main_co
	local wire_co
	
	function instance.start()
		M.log("Starting wire server")
		main_co = coroutine.create(function()
		
			local host = "*"
			local port = 9666
			local server_socket = assert(socket.bind(host, port))
			local ip, port = server_socket:getsockname()
			server_socket:settimeout(0)
	
			while true do
				do
					M.log("Waiting for a connection")
					-- wait for connection
					local client, error
					repeat
						client, error = server_socket:accept()
						coroutine.yield()
					until client or (error and error ~= "timeout")
					if error then
						M.log("Connection error", error)
						break
					end
					
					-- request-response loop
					while true do
						client:settimeout(1)

						M.log("Waiting for a wire request")
						-- wait for request
						local data, error
						repeat
							data, error = client:receive()
							coroutine.yield()
						until (data and #data > 0) or (error and error ~= "timeout")
						if error then
							M.log("An error occurred while waiting for a request", error)
							break
						end
						
						-- handle request and send response
						-- do this in a separate coroutine so that the responder
						-- can do long running tasks before providing a response
						wire_co = coroutine.create(function()
							M.log("Handling request", data)
							local request = json.decode(data)
							local response = cucumber.respond_to_wire_request(request)
							local response_json = rxi_json.encode(response):gsub("{}", "[]")
							M.log("Sending response", response_json)
							client:send(response_json .. "\n")
						end)
						coroutine.resume(wire_co)
						
						-- wait for the responder coroutine to finish
						while wire_co and coroutine.status(wire_co) ~= "dead" do
							coroutine.yield()
						end
					end
				end
			end
		end)
	end
	
	function instance.stop()
		main_co = nil
		wire_co = nil
	end
	
	function instance.update(dt)
		if main_co then
			local status = coroutine.status(main_co)
			if status == "suspended" then
				local ok, err = coroutine.resume(main_co)
				if not ok then
					M.log("Resume of main coroutine ended in an error", err)
				end
			elseif status == "dead" then
				main_co = nil
			end
		end
	end
	
	return instance
end


return M