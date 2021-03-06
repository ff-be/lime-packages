#!/usr/bin/lua

--! LibreMesh is modular but this doesn't mean parallel,
--! modules are executed sequencially, so we don't need
--! to worry about transaction and all other stuff that
--! affects parrallels database, at moment we don't need
--! parallelism as this is just some configuration stuff
--! and is not performance critical.

local libuci = require("uci")

config = {}

config.uci = libuci:cursor()

function config.get(sectionname, option, default)
	return config.uci:get("lime", sectionname, option) or config.uci:get("lime-defaults", sectionname, option, default)
end

function config.foreach(configtype, callback)
	return config.uci:foreach("lime", configtype, callback)
end

function config.get_all(sectionname)
	local lime_section = config.uci:get_all("lime", sectionname)
	local lime_default_section = config.uci:get_all("lime-defaults", sectionname)
	local section_exists = (lime_section ~= nil) or (lime_default_section ~= nil)

	if section_exists then
		local ret = lime_section or {}

		if lime_default_section then
			for key,value in pairs(lime_default_section) do
				if (ret[key] == nil) then
					ret[key] = value
				end
			end
		end

		return ret
	end

	return nil
end

function config.get_bool(sectionname, option, default)
	local val = config.get(sectionname, option, default)
	return (val and ((val == '1') or (val == 'on') or (val == 'true') or (val == 'enabled')))
end

config.batched = false

function config.init_batch()
	config.batched = true
end

function config.set(...)
	config.uci:set("lime", unpack(arg))
	if(not config.batched) then config.uci:save("lime") end
end

function config.delete(...)
	config.uci:delete("lime", unpack(arg))
	if(not config.batched) then config.uci:save("lime") end
end

function config.end_batch()
	if(config.batched) then
		config.uci:save("lime")
		config.batched = false
	end
end

function config.autogenerable(section_name)
	return ( (not config.get_all(section_name)) or config.get_bool(section_name, "autogenerated") )
end


return config
