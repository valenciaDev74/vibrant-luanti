shader_complements = {}

local player_state = {}
local storage = minetest.get_mod_storage()
local default_shadow = tonumber(minetest.settings:get("shader_complements_shadow_intensity") or 0.33)
local shadow_intensity = tonumber(storage:get("shadow_intensity") or default_shadow)

local function is_underwater(player)
	local pos = player:get_pos()
	if not pos then
		return false
	end
	pos.y = pos.y + 1.5
	local node = minetest.get_node(pos)
	if node.name == "ignore" then
		return false
	end
	return minetest.get_item_group(node.name, "liquid") > 0
end

local function apply_enhanced_sky(player)
	player:set_sky({
		type = "regular",
		sky_color = {
			day_sky = "#1A3E6A",
			day_horizon = "#4A8AB5",
			dawn_sky = "#F4A53D",
			dawn_horizon = "#F7C86A",
			night_sky = "#0A1A3A",
			night_horizon = "#1C3A6A",
			indoors = "#646464",
		},
		clouds = true,
		fog = {
			fog_color = "#00000000",
			fog_distance = -1,
			fog_start = -1,
		},
	})
	player:set_sun()
	player:set_lighting({
		shadows = { intensity = shadow_intensity },
		bloom = {
			intensity = 0.01,
		},
		volumetric_light = {
			strength = 0.3,
		},
	})
end

local function lerp_color(c1, c2, t)
	local function hex_to_rgb(h)
		return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
	end
	local r1, g1, b1 = hex_to_rgb(c1)
	local r2, g2, b2 = hex_to_rgb(c2)
	local r = math.floor(r1 + (r2 - r1) * t + 0.5)
	local g = math.floor(g1 + (g2 - g1) * t + 0.5)
	local b = math.floor(b1 + (b2 - b1) * t + 0.5)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function get_underwater_fog_color()
	local nightness = math.abs(minetest.get_timeofday() - 0.5) * 2.0
	return lerp_color("#081018", "#020406", nightness)
end

local function apply_underwater_fog(player)
	local fog_c = get_underwater_fog_color()
	player:set_sky({
		type = "regular",
		sky_color = {
			day_sky = fog_c,
			day_horizon = fog_c,
			dawn_sky = fog_c,
			dawn_horizon = fog_c,
			night_sky = fog_c,
			night_horizon = fog_c,
			indoors = fog_c,
		},
		clouds = false,
		fog = {
			fog_color = fog_c,
			fog_distance = 30,
			fog_start = 0.15,
		},
	})
	player:set_lighting({
		shadows = { intensity = shadow_intensity },
		bloom = {
			intensity = 0,
		},
		volumetric_light = {
			strength = 0,
		},
	})
end

minetest.register_globalstep(function()
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local underwater = is_underwater(player)
		local state = player_state[name]

		if underwater then
			apply_underwater_fog(player)
			if not state then
				state = {}
			end
			state.was_underwater = true
			player_state[name] = state
		else
			if not state or state.was_underwater then
				apply_enhanced_sky(player)
			end
			player_state[name] = { was_underwater = false }
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	player_state[name] = { was_underwater = false }
	apply_enhanced_sky(player)
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	player_state[name] = nil
end)

minetest.register_chatcommand("shadow_intensity", {
	params = "<0-1>",
	description = "Set shadow intensity (0 = no shadows, 1 = max)",
	func = function(name, param)
		local new = tonumber(param)
		if not new or new < 0 or new > 1 then
			return false, "Usage: /shadow_intensity <0-1>"
		end
		shadow_intensity = new
		storage:set_float("shadow_intensity", new)
		for _, player in ipairs(minetest.get_connected_players()) do
			apply_enhanced_sky(player)
		end
		return true, "Shadow intensity set to " .. new
	end,
})
