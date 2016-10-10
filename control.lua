--capture the flag, a Halo inspired concept (think sidewinder)
--A 3Ra Gaming creation
--Starting Variables
global.red_count_total = 0
global.blue_count_total = 0

red_color = {b = 0.1, r= 0.9, g = 0.1, a = 0.8}
blue_color = {b = 0.9, r= 0.1, g = 0.1, a = 0.8}

d = 32*3
bd = d*3

script.on_event(defines.events.on_player_created, function(event)
	if global.red_count == nil then
		global.red_count = 0
	end
	if global.blue_count == nil then
		global.blue_count = 0
	end
	local player = game.players[event.player_index]
	player.teleport({0,8},game.surfaces["Lobby"])
	player.print({"msg-intro1"})
	player.print({"msg-intro2"})
	make_team_option(player)
 
	if game.tick > 90*60 then
		make_team_option(player)
	else 
		player.print({"msg-intro3"})
	end
end)
 
script.on_event(defines.events.on_player_joined_game, function(event)
	local player = game.players[event.player_index]
    if player.gui.left.flashlight == nil then
        local frame = player.gui.left.add{name = "flashlight", type = "button", direction = "horizontal", caption = "flashlight"}
    end
	
	if player.admin == true then
        if player.gui.left.spectate == nil then
            local adminframe = player.gui.left.add{name = "spectate", type = "button", direction = "horizontal", caption = "spectate"}
        end
		if game.tick > 60 then
			for k, p in pairs (game.players) do
				p.print("All Hail Admin "..player.name)
			end
		end
	end
	show_update_score()
	update_count()
 end)
 
script.on_event(defines.events.on_player_left_game, function(event)
  update_count()
end)

script.on_init(function ()
	load_global_tables()
  	make_forces()  
	make_lobby()
	spawn_loot()
	set_spawns()
	spawn_flags()
	global.chests = {}
	global.flags_items = {}
end)

script.on_event(defines.events.on_entity_died, function(event)
 local entity = event.entity
	if entity.type == "player" then
	
	local pos = entity.surface.find_non_colliding_position(
		"steel-chest", entity.position, 8, 1)
		if not pos then return end
    
		local grave = entity.surface.create_entity{
		name="steel-chest", position=pos, force="neutral"}
		if protective_mode then
			grave.destructible = false
		end
			local grave_inv = grave.get_inventory(defines.inventory.chest)
			local count = 0
		for i, id in ipairs{
			defines.inventory.player_ammo,
			defines.inventory.player_quickbar,
			defines.inventory.player_main,
			defines.inventory.player_item_active,
			defines.inventory.player_trash} do
			local inv = entity.get_inventory(id)
			for j = 1, #inv do
			if inv[j].valid_for_read then
			count = count + 1
			if count > #grave_inv then return end
			grave_inv[count].set_stack(inv[j])
			end
			end
		end	
	end	
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.players[event.player_index]
  give_starting_inventory(player)
  give_equipment(player)
end)

global.timer_value = 0
global.timer_wait = 610
global.timer_display = 1
global.loot_timer_value = 0
global.loot_timer_wait = 122
global.loot_timer_display = 1

script.on_event(defines.events.on_tick, function(event)
	local current_time = game.tick / 60 - global.timer_value
	local current_loot_time = game.tick / 60 - global.loot_timer_value
	local message_display = "test"
	local loot_message_display = "test"
	show_health()
	
	if current_time >= global.timer_wait then
		if global.timer_display == 1 then
			message_display = {"msg-announce1"}
			global.timer_display = 2
		else
			message_display = {"msg-announce2"}
			global.timer_display = 1
		end
		for k, player in pairs(game.players) do
			player.print(message_display)
		end
		global.timer_value = game.tick / 60
	end
	if current_loot_time >= global.loot_timer_wait then
		if global.timer_display == 1 then
			loot_message_display = {"msg-announce3"}
			global.loot_timer_display = 2
			spawn_loot()
		else
			loot_message_display = {"msg-announce3"}
			global.loot_timer_display = 1
			spawn_loot()
		end
		for k, player in pairs(game.players) do
			player.print(loot_message_display)
		end
		global.loot_timer_value = game.tick / 60
	end
		-- PLAYER TRANSFER
	for _, player in pairs(game.players) do
		if player.connected and player.character and player.vehicle == nil then
			teleport_into(player)
			teleport_out(player)
		end
	end
	check_chest()
end)

script.on_event(defines.events.on_gui_click, function(event)
	local s = game.surfaces.nauvis
	local player = game.players[event.player_index]
	local force = player.force
    local index = event.player_index
    local element = event.element.name
		
	if player.gui.top.flashlight == nil then
        if element ~= nil then
            if element == "flashlight" then
                if player.character == nil then return end
                if global.player_flashlight_state == nil then
                    global.player_flashlight_state = {}
                end
                
                if global.player_flashlight_state[event.player_index] == nil then
                    global.player_flashlight_state[event.player_index] = true
                end
    
                if global.player_flashlight_state[event.player_index] then
                    global.player_flashlight_state[event.player_index] = false
                    player.character.disable_flashlight()
                else
                    global.player_flashlight_state[event.player_index] = true
                    player.character.enable_flashlight()
                end
            end
        end
	end	
	if player.gui.left.choose_team ~= nil then
		if (event.element.name == "red") then
		 if player.character == nil then
                if player.connected then
					if global.red_count > global.blue_count then player.print("Too many Players on that team") return end
                    local character = player.surface.create_entity{name = "player", position = player.surface.find_non_colliding_position("player", player.force.get_spawn_position(player.surface), 10, 2), force = force}
                    player.set_controller{type = defines.controllers.character, character = character}
                    end
            end
			global.red_count_total = global.red_count_total + 1
			player.teleport(game.forces["Red"].get_spawn_position(s), game.surfaces.nauvis)
			player.color = red_color
			player.force = game.forces["Red"]
			player.gui.left.choose_team.destroy()
			give_starting_inventory(player)
			give_equipment(player)
			update_count()
			player.print("Capture the Blue Flag")      
			for k, p in pairs (game.players) do
				p.print(player.name.." has joined team Red")
			end
		end
	end
	if player.gui.left.choose_team ~= nil then
		if (event.element.name == "blue") then
            if player.character == nil then
                if player.connected then
					if global.blue_count > global.red_count then player.print("Too many Players on that team") return end
                    local character = player.surface.create_entity{name = "player", position = player.surface.find_non_colliding_position("player", player.force.get_spawn_position(player.surface), 10, 2), force = force}
                    player.set_controller{type = defines.controllers.character, character = character}
                    end
            end
			global.blue_count_total = global.blue_count_total + 1
			player.teleport(game.forces["Blue"].get_spawn_position(s), game.surfaces.nauvis)-- needs updating
			player.color = blue_color
			player.force = game.forces["Blue"]
			player.gui.left.choose_team.destroy()
			give_starting_inventory(player)
			give_equipment(player)
			update_count()
			player.print("Capture the Red Flag")
			for k, p in pairs (game.players) do
				p.print(player.name.." has joined team Blue")
			end
		end
	end
    
	if player.gui.left.choose_team ~= nil then
		if (event.element.name == "spectator") then
			force_spectators(index)
		end
		--destroy.character
		--make controller ghost
	end
    
    if player.gui.left.spectate ~= nil then
        if element ~= nil then
            if element == "spectate" then
                force_spectators(index)
            end
        end
    end
end)

	
script.on_event(defines.events.on_player_died, function(event)

end)

function update_count()
  local red_total = global.red_count_total
  local blue_total = global.blue_count_total
  local red_online = global.blue_count
  local blue_online = global.red_count
  for k, p in pairs (game.players) do
	if p.force == game.forces.Red then
		if p.connected then
			red_online = red_online + 1
		end
	end	
  end
  for k,p in pairs(game.players) do
	if p.force == game.forces.Blue then
		if p.connected then
			blue_online = blue_online + 1
		end
	end	
  end
  local red_status = "red("..red_online.."/"..global.red_count_total..")"
  local blue_status = "blue("..blue_online.."/"..global.blue_count_total..")"
  for k,p in pairs(game.players) do
    if p.gui.left.persons == nil then
		local frame = p.gui.left.add{name="persons",type="frame",direction="horizontal",caption="Players"}
		frame.add{type="label",name="red",caption=red_status}.style.font_color = red_color
		frame.add{type="label", name="Vs", caption= "VS", style="caption_label_style"}
		frame.add{type="label",name="blue",caption=blue_status,}.style.font_color = blue_color
    else
		p.gui.left.persons.red.caption = red_status
		p.gui.left.persons.blue.caption = blue_status
    end
  end
end

function show_update_score()
	if global.flag_score_red > 0 or global.flag_score_blue > 0 then
		for index, player in pairs(game.players) do
			if player.gui.left.flag_score == nil then
				local frame = player.gui.left.add{name = "flag_score", type = "frame", direction = "horizontal", caption="Flags Captured"}
				frame.add{type = "label", caption = global.flag_score_red, name = "flag_score_red"}.style.font_color = red_color
				frame.add{type = "label", caption = global.flag_score_blue, name = "flag_score_blue"}.style.font_color = blue_color
			else
				player.gui.left.flag_score.flag_score_blue.caption = tostring(global.flag_score_blue)
				player.gui.left.flag_score.flag_score_red.caption = tostring(global.flag_score_red)
			end
		end
	end
end

function check_loc(player)
    local p = player
    if p.surface.index == 1 then
        local s = 1
    else
        local s = p.surface.index
    end
    local x = p.position.x
    local y = p.position.y
    p.print({"", "surface.index = ", s, " (", x, ", ", y, ")"})
end

function force_spectators(index)
    local player = game.players[index]
    if global.player_spectator_state == nil then global.player_spectator_state = {} end
    if global.player_spectator_character == nil then global.player_spectator_character = {}  end
    if global.player_spectator_force == nil then global.player_spectator_force = {} end
    if global.player_spectator_state[index] then
        --remove spectator mode
        if player.character == nil and global.player_spectator_character[index] ~= nil then
            local pos = player.position
			player.set_controller{type=defines.controllers.character, character=global.player_spectator_character[index]}
            player.teleport(pos)
			player.force = game.forces[global.player_spectator_force[index].name]
		end
        global.player_spectator_state[index] = false
        player.print("Summoning your character")
    else
        --put player in spectator mode
        if player.surface.name == "Lobby" then
            player.teleport(game.forces["Spectators"].get_spawn_position(game.surfaces.nauvis), game.surfaces.nauvis)
        end
        if player.character then
            global.player_spectator_character[index] = player.character
            global.player_spectator_force[index] = player.force
    		player.set_controller{type = defines.controllers.god}
        end
        player.force = game.forces["Spectators"]
        global.player_spectator_state[index] = true
		player.print("You are now a spectator")
    end
end

function make_lobby()
	game.create_surface("AB", {width = 32, height = 96})
	game.create_surface("CD", {width = 96, height = 32})
	game.create_surface("Red", {width = 96, height = 32}) 
	game.create_surface("Blue", {width = 96, height = 32}) 
	game.create_surface("Lobby", {width = 96, height = 32})
end

function make_forces()
	local s = game.surfaces["nauvis"]
	game.forces["player"].chart(s,{{ global.blue_team_x - bd,  global.blue_team_y - bd}, { global.blue_team_x + bd,  global.blue_team_y + bd}} )
	game.forces["player"].chart(s,{{ global.red_team_x - bd,  global.red_team_y - bd}, { global.red_team_x + bd,  global.red_team_y + bd}} )
	game.create_force("Blue")
	game.create_force("Red")
	game.create_force("Spectators")
end

function set_spawns()
	s = game.surfaces["nauvis"]
	blue = game.forces["Blue"]
	red = game.forces["Red"]
	s.daytime = 0.9
	bpnc = s.find_non_colliding_position("player",  global.blue_team_position, 32,2)
	rpnc = s.find_non_colliding_position("player",  global.red_team_position, 32,2)

	if bpnc ~= nil and rpnc ~= nil then
		blue.set_spawn_position({bpnc.x,bpnc.y}, s)
		red.set_spawn_position({rpnc.x,rpnc.y}, s)
		--for k, object in pairs (s.find_entities{{bpnc.x-5,bpnc.y-15},{bpnc.x+5,bpnc.y-5}}) do object.destroy() end
		red.chart(s, {{bpnc.x-32,bpnc.y-42},{bpnc.x+32,bpnc.y+22}})
		--for k, object in pairs (s.find_entities{{rpnc.x-5,rpnc.y-15},{rpnc.x+5,rpnc.y-5}}) do object.destroy() end
		blue.chart(s, {{rpnc.x-32,rpnc.y-42},{rpnc.x+32,rpnc.y+22}})
		for k, p in pairs (game.players) do
			p.print("Teams are now unlocked")
		end
	end
end

function make_team_option(player)
	if player.gui.left.choose_team == nil then
		local frame = player.gui.left.add{name = "choose_team", type = "frame", direction = "vertical", caption="Choose your Team"}
		frame.add{type = "button", caption = "Join Red Team", name = "red"}.style.font_color = red_color
        frame.add{type = "button", caption = "Join Blue Team", name = "blue"}.style.font_color = blue_color
		if player.admin == true then
			frame.add{type = "button", caption = "Join Spectators", name = "spectator"}.style.font_color = {r = 0.1,b = 0.4,g = 1}
		end
	end
end

function give_starting_inventory(player)
  if player.connected then
    if player.character then
      for k, item in pairs (global.starting_inventories) do
        player.insert{name = item.name, count = item.count}
      end
    end
  end
end

function give_equipment(player)
  if player.connected then
      player.insert{name="heavy-armor", count = 1}
     -- local p_armor = player.get_inventory(5)[1].grid
     --p_armor.put({name = "fusion-reactor-equipment"})
     -- p_armor.put({name = "exoskeleton-equipment"})
     -- p_armor.put({name = "exoskeleton-equipment"})
    end
  end
  
function format_time(ticks)
  local seconds = ticks / 60
  local minutes = math.floor((seconds)/60)
  local seconds = math.floor(seconds - 60*minutes)
  return string.format("%d:%02d", minutes, seconds)
end

function spawn_flags()
if not global.chests then global.chests = {} end
local surface = game.surfaces["nauvis"]
	global.flags_items = {}
	global.flags_items.name = "processing-unit" and "advanced-circuit"
		for k, object in pairs (surface.find_entities{{640,-447},{641,-446}}) do object.destroy() end
		global.chest_blue = surface.create_entity{name = "steel-chest", position = {640,-447}, force = "neutral"}
		global.chest_blue.minable = false
		global.chest_blue.destructible = false
		global.chest_blue.insert{name = "processing-unit", count = 1}
		for k, object in pairs (surface.find_entities{{640,-447},{641,-446}}) do
		table.insert(global.chests, index) end
		
		for k, object in pairs (surface.find_entities{{190,430},{191,431}}) do object.destroy() end
		global.chest_red = surface.create_entity{name = "steel-chest", position = {190,430}, force = "neutral"}
		global.chest_red.minable = false
		global.chest_red.destructible = false
		global.chest_red.insert{name = "advanced-circuit", count = 1}
		for k, object in pairs (surface.find_entities{{190,430},{191,431}}) do
		table.insert(global.chests, index) end
end

function check_chest()
	if global.chests then
		if global.flags_items then 
			if global.chest_blue.get_item_count("processing-unit") >= 1 and global.chest_blue.get_item_count("advanced-circuit") >= 1 then
				global.flag_score_blue = global.flag_score_blue + 1
				game.print("Blue Team Scores!")
				spawn_flags()
				show_update_score()
			end	
			if global.chest_blue.get_item_count("processing-unit") < 1 then
				global.blue_alarm = global.blue_alarm + 1 
			end
			if global.chest_red.get_item_count("processing-unit") >= 1 and global.chest_red.get_item_count("advanced-circuit") >= 1 then
				global.flag_score_red = global.flag_score_red + 1
				game.print("Red Team Scores!")
				spawn_flags()
				show_update_score()
			end	
			if global.chest_red.get_item_count("advanced-circuit") < 1 then
				global.red_alarm = global.red_alarm + 1 
			end
			if global.red_alarm == 1 then 
				game.print("Red Team Flag has been taken")
			end
			if global.blue_alarm == 1 then
				game.print("Blue Team Flag has been taken")
			end
			if global.chest_blue.get_item_count("processing-unit") == 1 then
				global.blue_alarm = 0
			end
			if global.chest_red.get_item_count("advanced-circuit") == 1 then
				global.red_alarm = 0
			end
		end
	end	
end

function spawn_loot()
	local surface = game.surfaces["nauvis"]
		for k, object in pairs (surface.find_entities{{627,-447},{628,-446}}) do object.destroy() end
		global.loot_chest_c = surface.create_entity{name = "steel-chest", position = {627,-447}, force = "neutral"}
		global.loot_chest_c.minable = false
		global.loot_chest_c.destructible = false
		global.loot_chest_c.insert{name = "solid-fuel", count = 50}
		global.loot_chest_c.insert{name = "car", count = 2}
		
		for k, object in pairs (surface.find_entities{{190,420},{191,421}}) do object.destroy() end
		global.loot_chest_b = surface.create_entity{name = "steel-chest", position = {190,420}, force = "neutral"}
		global.loot_chest_b.minable = false
		global.loot_chest_b.destructible = false
		global.loot_chest_b.insert{name = "solid-fuel", count = 50}
		global.loot_chest_b.insert{name = "car", count = 2}
	
		for k, object in pairs (surface.find_entities{{-29,-339},{-30,-340}}) do object.destroy() end
		global.loot_chest_l = surface.create_entity{name = "steel-chest", position = {-29,339}, force = "neutral"}
		global.loot_chest_l.minable = false
		global.loot_chest_l.destructible = false
		global.loot_chest_l.insert{name = "cluster-grenade", count = 4}
	
		for k, object in pairs (surface.find_entities{{95,-336},{96,-337}}) do object.destroy() end
		global.loot_chest_r = surface.create_entity{name = "steel-chest", position = {95,-336}, force = "neutral"}
		global.loot_chest_r.minable = false
		global.loot_chest_r.destructible = false
		global.loot_chest_r.insert{name = "explosive-rocket", count = 5}
		global.loot_chest_r.insert{name = "rocket-launcher", count = 1}

		for k, object in pairs (surface.find_entities{{52, -371},{53, -372}}) do object.destroy() end
		global.loot_chest_r = surface.create_entity{name = "steel-chest", position = {52, -371}, force = "neutral"}
		global.loot_chest_r.minable = false
		global.loot_chest_r.destructible = false
		global.loot_chest_r.insert{name = "flame-thrower-ammo", count = 5}
		global.loot_chest_r.insert{name = "flame-thrower", count = 1}
		
		for k, object in pairs (surface.find_entities{{88, -302},{89, -303}}) do object.destroy() end
		global.loot_chest_r = surface.create_entity{name = "steel-chest", position = {88, -302}, force = "neutral"}
		global.loot_chest_r.minable = false
		global.loot_chest_r.destructible = false
		global.loot_chest_r.insert{name = "distractor-capsule", count = 3}
		
		for k, object in pairs (surface.find_entities{{-15,-300},{-14,-301}}) do object.destroy() end
		global.loot_chest_r = surface.create_entity{name = "steel-chest", position = {-15,-1}, force = "neutral"}
		global.loot_chest_r.minable = false
		global.loot_chest_r.destructible = false
		global.loot_chest_r.insert{name = "defender-capsule", count = 5}
		
		for k, object in pairs (surface.find_entities{{-16,-390},{-15,-391}}) do object.destroy() end
		global.loot_chest_r = surface.create_entity{name = "steel-chest", position = {-16,90}, force = "neutral"}
		global.loot_chest_r.minable = false
		global.loot_chest_r.destructible = false
		global.loot_chest_r.insert{name = "car", count = 1}
		global.loot_chest_r.insert{name = "solid-fuel", count = 50}
end

function show_health()
    for k, player in pairs(game.players) do
		if player.connected then
			if player.character then
				if player.character.health == nil then return end
				local index = player.index
				local health = math.ceil(player.character.health)
				if global.player_health == nil then global.player_health = {} end
				if global.player_health[index] == nil then global.player_health[index] = health end
				if global.player_health[index] ~= health then
					global.player_health[index] = health
					if health < 80 then
						if health > 50 then
							player.surface.create_entity{name="flying-text", color={b = 0.2, r= 0.1, g = 1, a = 0.8}, text=(health), position= {player.position.x, player.position.y-2}}
						elseif health > 29 then
							player.surface.create_entity{name="flying-text", color={r = 1, g = 1, b = 0}, text=(health), position= {player.position.x, player.position.y-2}}
						else
							player.surface.create_entity{name="flying-text", color={b = 0.1, r= 1, g = 0, a = 0.8}, text=(health), position= {player.position.x, player.position.y-2}}
						end
					end
				end
            end
        end
    end 
end	
	
function load_global_tables()
	global.blue_team_x = 656
	global.blue_team_y = -433
	global.blue_team_position = { global.blue_team_x, global.blue_team_y}
	global.blue_team_area = {{ global.blue_team_x - d,  global.blue_team_y - d},{ global.blue_team_x + d,  global.blue_team_y + d}}
	global.red_team_x = 171
	global.red_team_y = 423
	global.red_team_position = { global.red_team_x, global.red_team_y}
	global.red_team_area = {{ global.red_team_x - d,  global.red_team_y - d},{ global.red_team_x + d,  global.red_team_y + d}}

	global.red_count = 0
	global.blue_count = 0
	
	global.red_alarm = 0
	global.blue_alarm = 0
	
	global.flag_score_blue = 0
	global.flag_score_red = 0
	
	global.starting_inventories = 
    {
		{name = "steel-axe", count = 1},
		{name = "submachine-gun", count = 1},
		{name = "firearm-magazine", count=20},
    }
end

--teleporting mumbo
function teleport_into(player)
	--B
	if player.surface.index == 1 and player.position.x >= 10 and player.position.x <= 12 and player.position.y >= -551 and player.position.y <= -549 then
		player.teleport({0,-40}, 2)
	end
	--A
	if player.surface.index == 1 and player.position.x >= 294 and player.position.x <= 296 and player.position.y >= 46 and player.position.y <= 48 then
		player.teleport({0,40}, 2)
	end
	--C
	if player.surface.index == 1 and player.position.x >= -330 and player.position.x <= -328 and player.position.y >= -287 and player.position.y <= -285 then
		player.teleport({-40,0}, 3)
	end
	--D
	if player.surface.index == 1 and player.position.x >= 418 and player.position.x <= 420 and player.position.y >= -208 and player.position.y <= -206 then
		player.teleport({40,0}, 3)
	end
end

function teleport_out(player)
	if player.surface.index == 3 and player.position.x >= 45 and player.position.x <= 47 and player.position.y >= -15 and player.position.y <= 15 then
	player.teleport({422,-208}, 1)
	end
	if player.surface.index == 3 and player.position.x >= -47 and player.position.x <= -45 and player.position.y >= -15 and player.position.y <= 15 then
	player.teleport({-330,-290}, 1)
	end
	if player.surface.index == 2 and player.position.x >= -15 and player.position.x <= 15 and player.position.y >= -47 and player.position.y <= -45 then
	player.teleport({15,-546}, 1)
	end
	if player.surface.index == 2 and player.position.x >= -15 and player.position.x <= 	15 and player.position.y >= 45 and player.position.y <= 47 then
	player.teleport({290,50}, 1)
	end	
end
