--control.lua

require "globals"
local Func = require "functionality"

script.on_nth_tick(10,
function (e)
	-- a cargo pod lands on a surfave, then becomes invalid. this means the player has landed
	for i=#Temporary.players_in_rocket,1,-1 do
		local pod = Temporary.players_in_rocket[i]
		if not pod.valid then
			table.remove(Temporary.players_in_rocket, i)
		end
	end


	for index,player in pairs(game.connected_players) do  --loop through all online players on the server

		-- check if player stands on non-manmade tiling
		if not player.surface.get_tile(player.physical_position).valid then return nil end
		-- if not player.controller_type == defines.controllers.character then return nil end
		-- don't burn in space
		if string.find(player.surface.name, "platform-") then
			return
		end
		if Temporary.players_in_rocket[player.index] then return nil end

		local undertile = player.surface.get_tile(player.physical_position)
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
				player.physical_position.x == Temporary.last_position[index].x and
				player.physical_position.y == Temporary.last_position[index].y) or
				settings.global["tfil-burn-instantly"].value then

				if player.vehicle and vehicle_damage_multiplier == 0 then
				else
					player.surface.create_entity{name="fire-flame", position=player.physical_position, force="neutral"}
				end
			end

			-- keep track of position every 3rd second to see if player stands still
			Temporary.last_position[index] = {x=player.physical_position.x, y=player.physical_position.y}


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

script.on_event(defines.events.on_player_driving_changed_state,
function(event)
	if not event.entity.name == "cargo-pod" then return end
	-- when we launch from a planet, we start driving a cargo pod
	-- when reaching a space platform, we exit the pod and stop driving it
	-- landing on a planet however does not trigger this event
	if game.players[event.player_index].driving then 
		Temporary.players_in_rocket[event.player_index] = event.entity
	else
		Temporary.players_in_rocket[event.player_index] = nil
	end
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

