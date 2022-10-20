--control.lua

require "config"
require "globals"
local Func = require "functionality"

script.on_nth_tick(10,
 function (e)
	for index,player in pairs(game.connected_players) do  --loop through all online players on the server

		-- check if player stands on non-manmade tiling
		if not player.surface.get_tile(player.position).valid then return nil end
		local undertile = player.surface.get_tile(player.position)
		if player.character and not (undertile.hidden_tile or string.find(undertile.name, "factory") or undertile.name == "water") then
			-- "factory" catches factorissimo buildings
			local env_damage = Config.environment_damage
			if player.vehicle then
				env_damage = Config.environment_damage * Config.vehicle_damage_modifier
			end

			-- do damage
			player.character.damage(env_damage, player.force, "fire")

			-- if last position is nil, set it to zeros to avoid errors
			if not Temporary.last_position then
				Temporary.last_position[index] = {x=0, y=0}
			end

			-- if player is standing still, light a fire underneath player
			if Temporary.last_position[index] and
				player.position.x == Temporary.last_position[index].x and
				player.position.y == Temporary.last_position[index].y then
				player.surface.create_entity{name="fire-flame", position=player.position, force="neutral"}
			end

			-- keep track of position every 3rd second to see if player stands still
			Temporary.last_position[index] = {x=player.position.x, y=player.position.y}
		end
	end
 end
)

script.on_init(
	function()
		if remote.interfaces["freeplay"] then
			local ship_items = remote.call("freeplay", "get_ship_items")
			ship_items["stone-brick"] = 30
			remote.call("freeplay", "set_ship_items", ship_items)
			local respawn_items = remote.call("freeplay", "get_respawn_items")
			respawn_items["stone-brick"] = 10
			remote.call("freeplay", "set_respawn_items", respawn_items)

			global.freeplay_interface_called = true
		end
	end
)

script.on_event(defines.events.on_player_changed_surface,
 function(event)
    Func.let_player_start(event.player_index)
 end
)

script.on_event(defines.events.on_cutscene_cancelled,
 function(event)
    Func.let_player_start(event.player_index)
 end
)

script.on_event(defines.events.on_player_respawned,
	function(event)
    	Func.let_player_start(event.player_index)
	end
)

script.on_event(defines.events.on_player_created,
 function(event)
	local player = game.get_player(event.player_index)
	if player.character then
		Func.let_player_start(event.player_index)
	end
 end
)


