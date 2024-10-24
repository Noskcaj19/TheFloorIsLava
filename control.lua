--control.lua

require "globals"
local Func = require "functionality"

script.on_nth_tick(10,
 function (e)
	for index,player in pairs(game.connected_players) do  --loop through all online players on the server

		-- check if player stands on non-manmade tiling
		if not player.surface.get_tile(player.position).valid then return nil end
		local undertile = player.surface.get_tile(player.position)
		-- "factory" catches factorissimo buildings
		if player.character and not (string.find(undertile.name, "factory") or string.find(undertile.name, "water")) then
			if undertile.hidden_tile and (undertile.name ~= "nuclear-ground") then
				if (undertile.hidden_tile == "nuclear-ground" and settings.global["tfil-evil-nuke"].value) then
					goto burn
				end
				goto continue
			end
			::burn::
			-- Don't burn when flying in a jetpack
			if remote.interfaces.jetpack and remote.call("jetpack", "is_jetpacking", {character=player.character}) then
				return nil
			end

			local env_damage = settings.global["tfil-environment-damage"].value
			local vehicle_damage_multiplier = settings.global["tfil-vehicle-damage-modifier"].value

			if player.vehicle then
				env_damage = settings.global["tfil-environment-damage"].value * vehicle_damage_multiplier
			end


			if settings.global["tfil-bypass-armor"].value then
				local fraction_of_health = settings.global["tfil-bypass-armor-damage-modifier"].value

				local damage = (player.character.prototype.max_health * fraction_of_health)

				if player.vehicle then
					damage = damage * vehicle_damage_multiplier
				end

				player.character.health = player.character.health - damage
				if player.character.health == 0 then
					player.character.die()
				end
			else
				-- do damage
				player.character.damage(env_damage, "neutral", "fire")
			end


			-- if last position is nil, set it to zeros to avoid errors
			if not Temporary.last_position then
				Temporary.last_position[index] = {x=0, y=0}
			end

			-- if player is standing still, light a fire underneath player
			if (Temporary.last_position[index] and
				player.position.x == Temporary.last_position[index].x and
				player.position.y == Temporary.last_position[index].y) or
				settings.global["tfil-burn-instantly"].value then

				if player.vehicle and vehicle_damage_multiplier == 0 then
				else
					player.surface.create_entity{name="fire-flame", position=player.position, force="neutral"}
				end
			end

			-- keep track of position every 3rd second to see if player stands still
			Temporary.last_position[index] = {x=player.position.x, y=player.position.y}


			if settings.global["tfil-die-instantly"].value then
				player.character.die()
			end
		end
		::continue::
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

			storage.freeplay_interface_called = true
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
	if player.character or player.cutscene_character then
		Func.let_player_start(event.player_index or player.cutscene_character)
	end
 end
)

