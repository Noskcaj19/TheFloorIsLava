--functionality.lua


local Func = {}

local function area_within_radius(area, center)
   local r = settings.global["tfil-beginning-path-radius"].value
   return area.left_top.x-center.x < r and area.right_bottom.x-center.x > -r and
      area.left_top.y-center.y < r and area.right_bottom.y-center.y > -r
end


local function make_brick_circle(area, center, surface)
   local changed_tiles = {}
   
   -- fill changed_tiles with tiles that are within a radius of the 0,0 position
   -- and designate them to be 'stone-path's
   local r = settings.global["tfil-beginning-path-radius"].value
   for x = area.left_top.x - center.x, area.right_bottom.x - center.x do
      for y = area.left_top.y - center.y, area.right_bottom.y - center.y do
	 if math.sqrt(x*x + y*y) < r then
	    table.insert(changed_tiles, {name="stone-path", position={x+center.x, y+center.y}})
	 end
      end
   end
   
   -- apply the stone path tiles
   if #changed_tiles > 0 then
      surface.set_tiles(changed_tiles)
   end
end



function let_player_start(plr_ind)
   local plr = game.players[plr_ind]

   -- give the player some bricks initially
   if not global.freeplay_interface_called then
      plr.insert({name="stone-brick", count=30})
   end

   -- make sure the player isn't set on fire uppon world creation
   local undertile = plr.surface.get_tile(plr.position)
   if not undertile.valid then return nil end
   if not not (undertile.hidden_tile or string.find(undertile.name, "factory")) then
      plr.surface.set_tiles{{name="stone-path", position=plr.position}}
   end

   --
   Temporary.last_position[plr_ind] = {x=plr.position.x, y=plr.position.y}

   local r = settings.global["tfil-beginning-path-radius"].value
   Func.make_brick_circle({left_top={x=plr.position.x-r, y=plr.position.y-r},
                           right_bottom={x=plr.position.x+r, y=plr.position.y+r}},
         plr.position, plr.surface)

end



Func.area_within_radius = area_within_radius
Func.make_brick_circle = make_brick_circle
Func.let_player_start = let_player_start

return Func