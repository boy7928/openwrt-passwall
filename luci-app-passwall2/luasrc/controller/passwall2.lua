-- Copyright (C) 2022 xiaorouji

module("luci.controller.passwall2", package.seeall)
local api = require "luci.model.cbi.passwall2.api.api"
local appname = api.appname
local ucic = luci.model.uci.cursor()
local http = require "luci.http"
local util = require "luci.util"
local i18n = require "luci.i18n"
local brook = require("luci.model.cbi." .. appname ..".api.brook")
local v2ray = require("luci.model.cbi." .. appname ..".api.v2ray")
local xray = require("luci.model.cbi." .. appname ..".api.xray")
local hysteria = require("luci.model.cbi." .. appname ..".api.hysteria")

function index()
	appname = require "luci.model.cbi.passwall2.api.api".appname
	entry({"admin", "vpn", appname}).dependent = true
	entry({"admin", "vpn", appname, "reset_config"}, call("reset_config")).leaf = true
	entry({"admin", "vpn", appname, "show"}, call("show_menu")).leaf = true
	entry({"admin", "vpn", appname, "hide"}, call("hide_menu")).leaf = true
	if not nixio.fs.access("/etc/config/passwall2") then return end
	if nixio.fs.access("/etc/config/passwall2_show") then
		e = entry({"admin", "vpn", appname}, alias("admin", "vpn", appname, "settings"), _("PassWall 2"), -1)
		e.dependent = true
		e.acl_depends = { "luci-app-passwall2" }
	end
	--[[ Client ]]
	entry({"admin", "vpn", appname, "settings"}, cbi(appname .. "/client/global"), _("Basic Settings"), 1).dependent = true
	entry({"admin", "vpn", appname, "node_list"}, cbi(appname .. "/client/node_list"), _("Node List"), 2).dependent = true
	entry({"admin", "vpn", appname, "node_subscribe"}, cbi(appname .. "/client/node_subscribe"), _("Node Subscribe"), 3).dependent = true
	entry({"admin", "vpn", appname, "auto_switch"}, cbi(appname .. "/client/auto_switch"), _("Auto Switch"), 4).leaf = true
	entry({"admin", "vpn", appname, "other"}, cbi(appname .. "/client/other", {autoapply = true}), _("Other Settings"), 92).leaf = true
	entry({"admin", "vpn", appname, "app_update"}, cbi(appname .. "/client/app_update"), _("App Update"), 95).leaf = true
	entry({"admin", "vpn", appname, "rule"}, cbi(appname .. "/client/rule"), _("Rule Manage"), 96).leaf = true
	entry({"admin", "vpn", appname, "node_subscribe_config"}, cbi(appname .. "/client/node_subscribe_config")).leaf = true
	entry({"admin", "vpn", appname, "node_config"}, cbi(appname .. "/client/node_config")).leaf = true
	entry({"admin", "vpn", appname, "shunt_rules"}, cbi(appname .. "/client/shunt_rules")).leaf = true
	entry({"admin", "vpn", appname, "acl"}, cbi(appname .. "/client/acl"), _("Access control"), 98).leaf = true
	entry({"admin", "vpn", appname, "acl_config"}, cbi(appname .. "/client/acl_config")).leaf = true
	entry({"admin", "vpn", appname, "log"}, form(appname .. "/client/log"), _("Watch Logs"), 999).leaf = true

	--[[ Server ]]
	entry({"admin", "vpn", appname, "server"}, cbi(appname .. "/server/index"), _("Server-Side"), 99).leaf = true
	entry({"admin", "vpn", appname, "server_user"}, cbi(appname .. "/server/user")).leaf = true

	--[[ API ]]
	entry({"admin", "vpn", appname, "server_user_status"}, call("server_user_status")).leaf = true
	entry({"admin", "vpn", appname, "server_user_log"}, call("server_user_log")).leaf = true
	entry({"admin", "vpn", appname, "server_get_log"}, call("server_get_log")).leaf = true
	entry({"admin", "vpn", appname, "server_clear_log"}, call("server_clear_log")).leaf = true
	entry({"admin", "vpn", appname, "link_add_node"}, call("link_add_node")).leaf = true
	entry({"admin", "vpn", appname, "autoswitch_add_node"}, call("autoswitch_add_node")).leaf = true
	entry({"admin", "vpn", appname, "autoswitch_remove_node"}, call("autoswitch_remove_node")).leaf = true
	entry({"admin", "vpn", appname, "get_now_use_node"}, call("get_now_use_node")).leaf = true
	entry({"admin", "vpn", appname, "get_redir_log"}, call("get_redir_log")).leaf = true
	entry({"admin", "vpn", appname, "get_log"}, call("get_log")).leaf = true
	entry({"admin", "vpn", appname, "clear_log"}, call("clear_log")).leaf = true
	entry({"admin", "vpn", appname, "status"}, call("status")).leaf = true
	entry({"admin", "vpn", appname, "socks_status"}, call("socks_status")).leaf = true
	entry({"admin", "vpn", appname, "connect_status"}, call("connect_status")).leaf = true
	entry({"admin", "vpn", appname, "ping_node"}, call("ping_node")).leaf = true
	entry({"admin", "vpn", appname, "urltest_node"}, call("urltest_node")).leaf = true
	entry({"admin", "vpn", appname, "set_node"}, call("set_node")).leaf = true
	entry({"admin", "vpn", appname, "copy_node"}, call("copy_node")).leaf = true
	entry({"admin", "vpn", appname, "clear_all_nodes"}, call("clear_all_nodes")).leaf = true
	entry({"admin", "vpn", appname, "delete_select_nodes"}, call("delete_select_nodes")).leaf = true
	entry({"admin", "vpn", appname, "update_rules"}, call("update_rules")).leaf = true
	entry({"admin", "vpn", appname, "brook_check"}, call("brook_check")).leaf = true
	entry({"admin", "vpn", appname, "brook_update"}, call("brook_update")).leaf = true
	entry({"admin", "vpn", appname, "v2ray_check"}, call("v2ray_check")).leaf = true
	entry({"admin", "vpn", appname, "v2ray_update"}, call("v2ray_update")).leaf = true
	entry({"admin", "vpn", appname, "xray_check"}, call("xray_check")).leaf = true
	entry({"admin", "vpn", appname, "xray_update"}, call("xray_update")).leaf = true
	entry({"admin", "vpn", appname, "hysteria_check"}, call("hysteria_check")).leaf = true
	entry({"admin", "vpn", appname, "hysteria_update"}, call("hysteria_update")).leaf = true
end

local function http_write_json(content)
	http.prepare_content("application/json")
	http.write_json(content or {code = 1})
end

function reset_config()
	luci.sys.call('/etc/init.d/passwall2 stop')
	luci.sys.call('[ -f "/usr/share/passwall2/0_default_config" ] && cp -f /usr/share/passwall2/0_default_config /etc/config/passwall2')
	luci.http.redirect(api.url())
end

function show_menu()
	luci.sys.call("touch /etc/config/passwall2_show")
	luci.sys.call("rm -rf /tmp/luci-*")
	luci.sys.call("/etc/init.d/rpcd restart >/dev/null")
	luci.http.redirect(api.url())
end

function hide_menu()
	luci.sys.call("rm -rf /etc/config/passwall2_show")
	luci.sys.call("rm -rf /tmp/luci-*")
	luci.sys.call("/etc/init.d/rpcd restart >/dev/null")
	luci.http.redirect(luci.dispatcher.build_url("admin", "status", "overview"))
end

function link_add_node()
	local lfile = "/tmp/links.conf"
	local link = luci.http.formvalue("link")
	luci.sys.call('echo \'' .. link .. '\' > ' .. lfile)
	luci.sys.call("lua /usr/share/passwall2/subscribe.lua add log")
end

function autoswitch_add_node()
	local key = luci.http.formvalue("key")
	if key and key ~= "" then
		for k, e in ipairs(api.get_valid_nodes()) do
			if e.node_type == "normal" and e["remark"]:find(key) then
				luci.sys.call(string.format("uci -q del_list passwall2.@auto_switch[0].node='%s' && uci -q add_list passwall2.@auto_switch[0].node='%s'", e.id, e.id))
			end
		end
	end
	luci.http.redirect(api.url("auto_switch"))
end

function autoswitch_remove_node()
	local key = luci.http.formvalue("key")
	if key and key ~= "" then
		for k, e in ipairs(ucic:get(appname, "@auto_switch[0]", "node") or {}) do
			if e and (ucic:get(appname, e, "remarks") or ""):find(key) then
				luci.sys.call(string.format("uci -q del_list passwall2.@auto_switch[0].node='%s'", e))
			end
		end
	end
	luci.http.redirect(api.url("auto_switch"))
end

function get_now_use_node()
	local e = {}
	local data, code, msg = nixio.fs.readfile("/tmp/etc/passwall2/id/global")
	if data then
		e["global"] = util.trim(data)
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function get_redir_log()
	local id = luci.http.formvalue("id")
	if nixio.fs.access("/tmp/etc/passwall2/" .. id .. ".log") then
		local content = luci.sys.exec("cat /tmp/etc/passwall2/" .. id .. ".log")
		content = content:gsub("\n", "<br />")
		luci.http.write(content)
	else
		luci.http.write(string.format("<script>alert('%s');window.close();</script>", i18n.translate("Not enabled log")))
	end
end

function get_log()
	-- luci.sys.exec("[ -f /tmp/log/passwall2.log ] && sed '1!G;h;$!d' /tmp/log/passwall2.log > /tmp/log/passwall2_show.log")
	luci.http.write(luci.sys.exec("[ -f '/tmp/log/passwall2.log' ] && cat /tmp/log/passwall2.log"))
end

function clear_log()
	luci.sys.call("echo '' > /tmp/log/passwall2.log")
end

function status()
	local e = {}
	e["global_status"] = luci.sys.call(string.format("top -bn1 | grep -v -E 'grep|acl/|acl_' | grep '%s/bin/' | grep -i 'global\\.json' >/dev/null", appname)) == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function socks_status()
	local e = {}
	local index = luci.http.formvalue("index")
	local id = luci.http.formvalue("id")
	e.index = index
	e.socks_status = luci.sys.call(string.format("top -bn1 | grep -v -E 'grep|acl/|acl_' | grep '%s/bin/' | grep '%s' | grep 'SOCKS_' > /dev/null", appname, id)) == 0
	local use_http = ucic:get(appname, id, "http_port") or 0
	e.use_http = 0
	if tonumber(use_http) > 0 then
		e.use_http = 1
		e.http_status = luci.sys.call(string.format("top -bn1 | grep -v -E 'grep|acl/|acl_' | grep '%s/bin/' | grep '%s' | grep -E 'HTTP_|HTTP2SOCKS' > /dev/null", appname, id)) == 0
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function connect_status()
	local e = {}
	e.use_time = ""
	local url = luci.http.formvalue("url")
	local result = luci.sys.exec('curl --connect-timeout 3 -o /dev/null -I -skL -w "%{http_code}:%{time_starttransfer}" ' .. url)
	local code = tonumber(luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $1}'") or "0")
	if code ~= 0 then
		local use_time = luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $2}'")
		if use_time:find("%.") then
			e.use_time = string.format("%.2f", use_time * 1000)
		else
			e.use_time = string.format("%.2f", use_time / 1000)
		end
		e.ping_type = "curl"
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function ping_node()
	local index = luci.http.formvalue("index")
	local address = luci.http.formvalue("address")
	local port = luci.http.formvalue("port")
	local e = {}
	e.index = index
	local nodes_ping = ucic:get(appname, "@global_other[0]", "nodes_ping") or ""
	if nodes_ping:find("tcping") and luci.sys.exec("echo -n $(command -v tcping)") ~= "" then
		if api.is_ipv6(address) then
			address = api.get_ipv6_only(address)
		end
		e.ping = luci.sys.exec(string.format("echo -n $(tcping -q -c 1 -i 1 -t 2 -p %s %s 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null", port, address))
	end
	if e.ping == nil or tonumber(e.ping) == 0 then
		e.ping = luci.sys.exec("echo -n $(ping -c 1 -W 1 %q 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null" % address)
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function urltest_node()
	local index = luci.http.formvalue("index")
	local id = luci.http.formvalue("id")
	local e = {}
	e.index = index
	local result = luci.sys.exec(string.format("/usr/share/passwall2/test.sh url_test_node %s %s", id, "urltest_node"))
	local code = tonumber(luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $1}'") or "0")
	if code ~= 0 then
		local use_time = luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $2}'")
		if use_time:find("%.") then
			e.use_time = string.format("%.2f", use_time * 1000)
		else
			e.use_time = string.format("%.2f", use_time / 1000)
		end
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function set_node()
	local protocol = luci.http.formvalue("protocol")
	local section = luci.http.formvalue("section")
	ucic:set(appname, "@global[0]", protocol .. "_node", section)
	ucic:commit(appname)
	luci.sys.call("/etc/init.d/passwall2 restart > /dev/null 2>&1 &")
	luci.http.redirect(api.url("log"))
end

function copy_node()
	local section = luci.http.formvalue("section")
	local uuid = api.gen_uuid()
	ucic:section(appname, "nodes", uuid)
	for k, v in pairs(ucic:get_all(appname, section)) do
		local filter = k:find("%.")
		if filter and filter == 1 then
		else
			xpcall(function()
				ucic:set(appname, uuid, k, v)
			end,
			function(e)
			end)
		end
	end
	ucic:delete(appname, uuid, "add_from")
	ucic:set(appname, uuid, "add_mode", 1)
	ucic:commit(appname)
	luci.http.redirect(api.url("node_config", uuid))
end

function clear_all_nodes()
	ucic:set(appname, '@global[0]', "enabled", "0")
	ucic:set(appname, '@global[0]', "node", "nil")
	ucic:set_list(appname, "@auto_switch[0]", "node", {})
	ucic:foreach(appname, "socks", function(t)
		ucic:delete(appname, t[".name"])
	end)
	ucic:foreach(appname, "acl_rule", function(t)
		ucic:set(appname, t[".name"], "node", "default")
	end)
	ucic:foreach(appname, "nodes", function(node)
		ucic:delete(appname, node['.name'])
	end)

	ucic:commit(appname)
	luci.sys.call("/etc/init.d/" .. appname .. " stop")
end

function delete_select_nodes()
	local ids = luci.http.formvalue("ids")
	local auto_switch_node_list = ucic:get(appname, "@auto_switch[0]", "node") or {}
	string.gsub(ids, '[^' .. "," .. ']+', function(w)
		for k, v in ipairs(auto_switch_node_list) do
			if v == w then
				luci.sys.call(string.format("uci -q del_list passwall2.@auto_switch[0].node='%s'", w))
			end
		end
		if (ucic:get(appname, "@global[0]", "node") or "nil") == w then
			ucic:set(appname, '@global[0]', "node", "nil")
		end
		ucic:foreach(appname, "socks", function(t)
			if t["node"] == w then
				ucic:delete(appname, t[".name"])
			end
		end)
		ucic:foreach(appname, "acl_rule", function(t)
			if t["node"] == w then
				ucic:set(appname, t[".name"], "node", "default")
			end
		end)
		ucic:delete(appname, w)
	end)
	ucic:commit(appname)
	luci.sys.call("/etc/init.d/" .. appname .. " restart > /dev/null 2>&1 &")
end

function update_rules()
	local update = luci.http.formvalue("update")
	luci.sys.call("lua /usr/share/passwall2/rule_update.lua log '" .. update .. "' > /dev/null 2>&1 &")
	http_write_json()
end

function server_user_status()
	local e = {}
	e.index = luci.http.formvalue("index")
	e.status = luci.sys.call(string.format("top -bn1 | grep -v 'grep' | grep '%s/bin/' | grep -i '%s' >/dev/null", appname .. "_server", luci.http.formvalue("id"))) == 0
	http_write_json(e)
end

function server_user_log()
	local id = luci.http.formvalue("id")
	if nixio.fs.access("/tmp/etc/passwall2_server/" .. id .. ".log") then
		local content = luci.sys.exec("cat /tmp/etc/passwall2_server/" .. id .. ".log")
		content = content:gsub("\n", "<br />")
		luci.http.write(content)
	else
		luci.http.write(string.format("<script>alert('%s');window.close();</script>", i18n.translate("Not enabled log")))
	end
end

function server_get_log()
	luci.http.write(luci.sys.exec("[ -f '/tmp/log/passwall2_server.log' ] && cat /tmp/log/passwall2_server.log"))
end

function server_clear_log()
	luci.sys.call("echo '' > /tmp/log/passwall2_server.log")
end

function brook_check()
	local json = brook.to_check("")
	http_write_json(json)
end

function brook_update()
	local json = nil
	local task = http.formvalue("task")
	if task == "move" then
		json = brook.to_move(http.formvalue("file"))
	else
		json = brook.to_download(http.formvalue("url"), http.formvalue("size"))
	end

	http_write_json(json)
end

function v2ray_check()
	local json = v2ray.to_check("")
	http_write_json(json)
end

function v2ray_update()
	local json = nil
	local task = http.formvalue("task")
	if task == "extract" then
		json = v2ray.to_extract(http.formvalue("file"), http.formvalue("subfix"))
	elseif task == "move" then
		json = v2ray.to_move(http.formvalue("file"))
	else
		json = v2ray.to_download(http.formvalue("url"), http.formvalue("size"))
	end

	http_write_json(json)
end

function xray_check()
	local json = xray.to_check("")
	http_write_json(json)
end

function xray_update()
	local json = nil
	local task = http.formvalue("task")
	if task == "extract" then
		json = xray.to_extract(http.formvalue("file"), http.formvalue("subfix"))
	elseif task == "move" then
		json = xray.to_move(http.formvalue("file"))
	else
		json = xray.to_download(http.formvalue("url"), http.formvalue("size"))
	end

	http_write_json(json)
end

function hysteria_check()
	local json = hysteria.to_check("")
	http_write_json(json)
end

function hysteria_update()
	local json = nil
	local task = http.formvalue("task")
	if task == "move" then
		json = hysteria.to_move(http.formvalue("file"))
	else
		json = hysteria.to_download(http.formvalue("url"), http.formvalue("size"))
	end

	http_write_json(json)
end

