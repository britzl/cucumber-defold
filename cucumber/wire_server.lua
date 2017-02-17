local tcp_server = require "defnet.tcp_server"


local cucumber = require "cucumber.cucumber"
local rxi_json = require "cucumber.json"

local M = {}



function M.create(port)
	local instance = {}
	
	local has_client = false
	
	local function on_data(data, ip)
		local request = json.decode(data)
		local response = cucumber.respond_to_wire_request(request)
		return rxi_json.encode(response):gsub("{}", "[]") .. "\n"
	end
	
	local function on_client_connected(ip)
		if has_client then
			error("Already connected")
		else
			has_client = true
			print("Client connected", ip)
		end
	end
	
	local function on_client_disconnected(ip)
		has_client = false
		print("Client disconnected", ip)
	end
	
	
	local server = tcp_server.create(port, on_data, on_client_connected, on_client_disconnected)
	
	function instance.start()
		server.start()
	end
	
	function instance.stop()
		server.stop()
	end
	
	function instance.update()
		server.update()
	end
	
	function instance.send_wire_response(response, ip)
		server.send(response)
	end
	
	return instance
end


return M