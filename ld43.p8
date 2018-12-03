pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- general

function _init()
	crs_init()
	cyc_init()
	lth_init()
	ent_init()
	map_init()
	spa_init()
	tma_init()
end
function _update()
	crs_update()
	map_update()
	lth_update()
	ent_update()
	spa_update()
	cyc_update()
	tma_update()
end
function _draw()
	cls()
	palt(0,false)
	palt(11,true)

	-- world
	map_draw()
	hou_draw()
	ent_draw()
	tma_draw()

	pnt_flush()

	-- ui
	lth_draw()
	crs_draw()
	cyc_draw()
end

-- tama

tma_stages = {
	{
		idl_spr = 1,
		eat_spr = 3,
	},
	{
		idl_spr = 32,
		eat_spr = 34,
	},
	{
		idl_spr = 8,
		eat_spr = 10,
	},
}

function tma_init()
	tma_stage = tma_stages[1]
	tma_x = 96
	tma_y = 96
	tma_frame = 0
	tma_eat_frame = -99
end
function tma_update()
	if tma_dst then
		local tma_new_x = mid(tma_x+1, tma_x-1, tma_dst_x)
		local tma_new_y = mid(tma_y+1, tma_y-1, tma_dst_y)
		local col_x = fget(mget((tma_new_x-4)/8,tma_y/8),0) or fget(mget((tma_new_x+4)/8,tma_y/8),0)
		local col_y = fget(mget((tma_x-3)/8,tma_new_y/8),0) or fget(mget((tma_x+3)/8,tma_new_y/8),0)
		tma_new_x = col_x and tma_x or tma_new_x
		tma_new_y = col_y and tma_y or tma_new_y
		if tma_new_x != tma_x or tma_new_y != tma_y then
			tma_x = tma_new_x
			tma_y = tma_new_y
		else
			tma_dst = false
		end
	end
	tma_stage = tma_stages[min(3,ceil(cyc_day()))]
	tma_frame += 1
end
function tma_draw()
	local sprite = tma_stage.idl_spr
	local off_x = -8
	local off_y = -14
	if tma_dst and tma_frame % 6 < 2 then
		off_y -= 1
	end
	if tma_dst and tma_frame%6==5 then
		sfx_step()
	end
	if tma_eat_frame>=tma_frame-16 and tma_frame%6<3 then
		sprite = tma_stage.eat_spr
	end
	pnt_add(tma_y,function()
		spr(sprite,tma_x-map_x+off_x,tma_y-map_y+off_y,2,2)
	end)
end
function tma_goto(x, y)
	tma_dst = true
	tma_dst_x = x
	tma_dst_y = y
	ent_cur_act = nil -- ugh
end
function tma_ate()
	tma_eat_frame = tma_frame
end

-- map

function map_init()
	map_x = 0
	map_y = 0
end
function map_update()
	if map_x+32 < tma_x then map_move(1,0) end
	if map_x+96 > tma_x then map_move(-1,0) end
	if map_y+32 < tma_y then map_move(0,1) end
	if map_y+96 > tma_y then map_move(0,-1) end
end
function map_draw()
	map(map_x/8, map_y/8, -(map_x%8), -(map_y%8), 17, 17)
end
function map_move(x, y)
	-- return true if actually moved
	local old_map_x = map_x
	local old_map_y = map_y
	map_x = mid(0, map_x+x, 128)
	map_y = mid(0, map_y+y, 128)
	return old_map_x != map_x or old_map_x != map_y
end

-- cursor
function crs_init()
	crs_x = 64
	crs_y = 64
	crs_last_m_x = -1
	crs_last_m_y = -1
	poke(0x5f2d, 1)
end
function crs_update()
	if btnp(4) or stat(34)!=0 then -- action
		local ent = ent_at(crs_x+map_x,crs_y+map_y)
		if ent and ent.act then
			ent_act(ent)
		else -- tama destination
			tma_goto(crs_x+map_x, crs_y+map_y)
		end
	end
	if btn(0) then crs_x -= 2 end
	if btn(1) then crs_x += 2 end
	if btn(2) then crs_y -= 2 end
	if btn(3) then crs_y += 2 end
	if stat(32) != crs_last_m_x then
		crs_x = stat(32)
		crs_last_m_x = stat(32)
	end
	if stat(33) != crs_last_m_y then
		crs_y = stat(33)
		crs_last_m_y = stat(33)
	end
	crs_x = mid(0, crs_x, 128)
	crs_y = mid(0, crs_y, 128)
end
function crs_draw()
	local sprite = (btn(4) or stat(34)!=0) and 81 or 80
	local crs_draw_x = crs_x
	local crs_draw_y = crs_y
	local ent = ent_at(crs_x+map_x, crs_y+map_y)
	if ent and ent.act then
		pal(7, 12)
		crs_draw_x = ent.x-map_x
		crs_draw_y = ent.y-map_y
	end
	spr(sprite, crs_draw_x-4, crs_draw_y-4)
	pal(7,7)
end

-- health

function lth_init()
	lth = 5
	lth_max = 5
	lth_frame = 0
end
function lth_update()
	lth_frame += 1
	if lth_frame%240==0 then
		lth -= 1
	end
end
function lth_draw()
	for i=1,lth_max do
		local sprite = i>lth and 64 or 65
		spr(sprite, i*9-7, 0)
	end
end
function lth_add(v)
	lth = max(v,lth+v)
	lth_frame = 0
end

-- paint
-- painter's algorithm

function pnt_add(y,f)
	if not pnt_cmd_list or (pnt_cmd_list and y<pnt_cmd_list.y) then
		pnt_cmd_list = {
			y=y,f=f,n=pnt_cmd_list
		}
	else
		cmd = pnt_cmd_list
		while cmd.n and y> cmd.n.y do
			cmd = cmd.n
		end
		cmd.n = {
			y=y,f=f,n=cmd.n
		}
	end
end
function pnt_flush()
	while pnt_cmd_list do
		pnt_cmd_list.f()
		pnt_cmd_list = pnt_cmd_list.n
	end
end

-- entities
-- entities have draws and actions associated to them
-- actions get called when tama is near enough

function ent_init()
	ents = {}
	ent_cur_act = nil
end
function ent_update()
	if ent_cur_act and ent_cur_act.act
	and mid(tma_x,ent_cur_act.x-4,ent_cur_act.x+4) == tma_x
	and mid(tma_y,ent_cur_act.y-4,ent_cur_act.y+4) == tma_y then
		ent_cur_act:act()
		ent_cur_act = nil
	end
end
function ent_draw()
	for ent in all(ents) do
		ent:draw()
	end
end
function ent_add(e)
	add(ents,e)
end
function ent_rem(e)
	del(ents,e)
end
function ent_at(x,y)
	-- todo handle entity size?
	for ent in all(ents) do
		if mid(ent.x,x-4,x+4) == ent.x
		and mid(ent.y,y-4,y+4) == ent.y then
			return ent
		end
	end
	return nil
end
function ent_act(e)
	tma_goto(e.x,e.y)
	ent_cur_act = e
end

-- spawn

spa_candy = {
	draw = function(o)
		pnt_add(o.y,function()
			spr(96,o.x-map_x-4,o.y-map_y-4)
		end)
	end,
	act = function(o)
		lth_add(2)
		tma_ate()
		ent_rem(o)
	end,
}
spa_villager = {
	draw = function(o)
		pnt_add(o.y,function()
			spr(202,o.x-map_x-8,o.y-map_y-14,2,2)
		end)
	end,
}
function spa_init()
	spas = {}
	add(spas,{
		x=85,y=130,ent=spa_candy,
	})
	add(spas,{
		x=48,y=48,ent=spa_villager,
	})
end
function spa_update()
	local today = flr(cyc_day())
	for spa in all(spas) do
		if not spa.last or spa.last != today then
			local new_ent = copy(spa.ent)
			new_ent.x = spa.x
			new_ent.y = spa.y
			ent_add(new_ent)
			spa.last = today
		end
	end
end

-- cycle

function cyc_init()
	cyc_frame = 0
end
function cyc_update()
	cyc_frame += 1
end
function cyc_draw()
	local cyc_icon = cyc_is_day() and 66 or 67
	
	outline(7,0,98,0,function(x,y)
		spr(cyc_icon, x, y)
	end)

	local time_str = leftpad(ceil(cyc_hour()%12),"0",2)
	.. ":" .. leftpad(flr(cyc_minute()%60),"0",2)

	outline(7,0,108,1,function(x,y)
		print(time_str, x, y, 7)
	end)

	if cyc_is_night() then
		pal(5,1,1)
	--	pal(0,6,1)
	--	pal(6,0,1)			
	else
		pal(5,5,1)
	end
end
function cyc_minute() return cyc_frame end
function cyc_hour() return cyc_minute() / 60 end
function cyc_day() return cyc_hour() / 24 end
function cyc_is_day() return abs(cyc_hour() % 24 - 12) < 8 end
function cyc_is_night() return not cyc_is_day() end

-- houses

houses = {
	{
		x=4,y=2,
		mx=35,my=11,
		w=5,h=6,
	},
	{
		x=20,y=3,
		mx=35,my=3,
		w=8,h=6,
	},
	{
		x=5,y=19,
		mx=45,my=3,
		w=9,h=6,
	},

	-- trees
	{x=9, y=13,mx=35,my=19,w=2,h=2,p=true},
	{x=23,y=24,mx=35,my=19,w=2,h=2,p=true},
	{x=25,y=26,mx=35,my=19,w=2,h=2,p=true},
	{x=18,y=25,mx=37,my=19,w=4,h=4,p=true},
}

function hou_draw()
	for h in all(houses) do
		if h.p
		or mid(tma_x,h.x*8,(h.x+h.w)*8) != tma_x
		or mid(tma_y,h.y*8,(h.y+h.h)*8) != tma_y then
			pnt_add((h.y+h.h)*8,function()
				map(h.mx,h.my,h.x*8-map_x,h.y*8-map_y,h.w,h.h)
			end)
		end
	end
end

-- sound

function sfx_step()
	sfx(8,-1,flr(rnd(5)),1)
end

-- util

function leftpad(str, pad, n)
	str = str .. ""
	while #str < n do
		str = pad .. str
	end
	return str;
end
function copy(t)
	local c = {}
	for k, v in pairs(t) do
		c[k] = v
	end
	return c
end
function outline(old_c,new_c,x,y,f)
	pal(old_c,new_c)
	for i=-1,1 do
		for j=-1,1 do
			f(x+i,y+j)
		end
	end
	pal(old_c,old_c)
	f(x,y)
end

__gfx__
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000bbbbb5bbbb5bbbbbbbbbb5bbbb5bbbbbbbbbb5bbbb5bbbbb0000000000000000
00700700bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000bbbb565bb565bbbbbbbb565bb565bbbbbbbb565bb565bbbb0000000000000000
00077000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000bbbb565bb565bbbbbbbb565bb565bbbbbbbb565bb565bbbb0000000000000000
00077000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000bbb5665bb5665bbbbbb5665bb5665bbbbbb5665bb5665bbb0000000000000000
00700700bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000bbb5665555665bbbbbb5665555665bbbbbb5665555665bbb0000000000000000
00000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000bb556666666655bbbb556666666655bbbb556666666655bb0000000000000000
00000000bbbbb5bbbb5bbbbbbbbbb5bbbb5bbbbb000000000000000000000000b56655666655665bb56655666655665bb56655666655665b0000000000000000
bbbbbbbbbbbbb555555bbbbbbbbbb555555bbbbb000000000000000000000000b56659566595665bb56659566595665bb56659566595665b0000000000000000
bbbbbbbbbbbb56666665bbbbbbbb56666665bbbb0000000000000000000000005666555665556665566655566555666556665556655566650000000000000000
bbbbbbbbbbb5665665665bbbbbb5665665665bbb0000000000000000000000005656656666566565565665666656656556566566665665650000000000000000
bbbbbbbbbbb5665665665bbbbbb5665665665bbb0000000000000000000000005656666666666565565666555566656856566666666665650000000000000000
bbbbbbbbbbb5666666665bbbb55666666666655b000000000000000000000000b5b5666556665b5bb5b5656556565b5bb5b5666556665b8b0000000000000000
bbbbbbbbbb556665566655bbbb566665566665bb000000000000000000000000bbb5665665665bbbb8b5655555565b8bbbb8665665865bbb0000000000000000
bbbbbbbbbbbb56666665bbbbbbb5566556655bbb000000000000000000000000bbbb56666665bbbb8bbb58566585bbbbbbb8568668858bbb0000000000000000
bbbbbbbbbbbbb555555bbbbbbbbbb555555bbbbb000000000000000000000000bbbbb555555bbbbbbbbbb855855bbbbbbbbbb585558bbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbb5bbbb5bbbbbbbbbb5bbbb5bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb565bb565bbbbbbbb565bb565bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb565bb565bbbbbbbb565bb565bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb5666556665bbbbbb5666556665bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb5666666665bbbbb566666666665bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb565556655565bbb56655566555665b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b5665c5665c5665bbb565c5665c565bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb565556655565bbbb565566665565bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb566566665665bbbb566566665665bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb5666666665bbbbb566665566665bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbb5665555665bbbbb566655556665bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbb56666665bbbbbbb5565555655bbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbb555555bbbbbbbbbb555555bbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbb7bbb7bb7bbbbbbbbbbbbbbbbbbbbbbbb6666666666666666bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666666666666666666600000000
b77b77bbb77b77bbb7bbbb7bbbb7bbbbbbbb555e55555bbb6666666666666666bbbbbbbbbbbbbbbbbb555555bbbbbbbb66666666666666666666666600000000
7bb7bb7b7777777bbbb77bbbbb7bbbbbbbb55b5555e555bb6666666666666666bbbbbbb555bbbb55bbbbbbb555b55bbb66666656565656566566666600000000
7bbbbb7b7777777b7b7777bbb77bbbbbbb55e5555e55555b6666666666666666bbbbb55bb555bbb555b55bb5b5bb55bb66566555555555555556656600000000
b7bbb7bbb77777bbbb7777b7b777bb7bbb5e555555555e556666666666666666bbbb55bbbbb555bbbb5b55b5b5bbb55566655666666656666665566600000000
bb7b7bbbbb777bbbbbb77bbbb77777bbb5b5555e5555e5556666666666666666bbbb5bbbb55bb555555bb5b5b5bbb5b556656666655666666666566500000000
bbb7bbbbbbb7bbbbb7bbbb7bbb777bbbbb55e555e5555b556666666666666666bbb55bbbb55bb55555b5b5b5b555bb5565566655665666555566655600000000
bbbbbbbbbbbbbbbb7bb7bbb7bbbbbbbbb5b555e5555e55b56666666666666666bb5555b555bbb55555b5b5555555bb5565656666666566666666565600000000
bbbbbbbbbbbbbbbb0000000066666666b5555e5555e555556666666566666666bb5b55555b55b55555b5b55555b55b5565666566566665666656665600000000
b7bbbb7bbbbbbbbb0000000066666666be5b555b5555bb556656656666666666bb55b5555bb5bb5555b5b55b55b55b5565656666655566666666565600000000
bb7bb7bbbb7bb7bb00000000666666665b5555b5555b555b6666666666666666bb55b5b555b5bb5555b55b5b55b55b5565656656666566566566565600000000
bbbbbbbbbbb77bbb0000000066666666b5b55e5555be55e56665665666666666bb55b5b555b5bb5555b55b55b5b55b5b55656655666566555566565500000000
bbbbbbbbbbb77bbb0000000066666666b55be5b55e5be5556566666666666666bb55b5b555b55555b5b55555b5b55b5b65665666566656666665665600000000
bb7bb7bbbb7bb7bb0000000066666666bb555b5555b5b55b6666656666666666b555b5b555b5b5b55b55b55555b5555b55666666655666666666665500000000
b7bbbb7bbbbbbbbb0000000066666666b5b5ebbe55bb5bbb6656666566666666b555b5bb55b5b5b55b55b5555555555b65666655665666555566665600000000
bbbbbbbbbbbbbbbb0000000066666666bb55b555555bb55b6666566666666666bbb5b55b55b5b5b55b55b5555555555b65566666666566666666655600000000
bbbbb0bb00000000000000006666666666656665556655666666666666666666bb55b55b5bb5b5555b55b5555b55555b65656666666566666666565600000000
bb000e0b00000000000000006666666666666665556666666666666666666666b5b5b55b5bb5b5555b5555b55b5bb55565566655665666555566655600000000
b0eeeee000000000000000006666666666666665555666666066660666555666b5b5555b5b5b55555b5555b5b55555b556656666655666666666566500000000
b0eeee0b00000000000000006566566566666665556666666006600655565556b555555b5b5bb5b555b55555b5b555b566655666666656666665566600000000
b0eeee0b00000000000000006656565666566665556666666000000655565556bb5555b55b5bb5bb55b55555b5b555b566566555555555555556656600000000
0eeeee0b00000000000000006666666666556565556656660006600066555666bb5555b55b5bb5bb55b55b55b5b555b566666656565656566566666600000000
b0e000bb00000000000000006666666666656565556656566006600656656656bb5555b55b5bb55555b55b5b55b555b566666666666666666666666600000000
bb0bbbbb00000000000000006666666666666555555666566006600655565556bb55b5b55555b55555bb5b5b55b555b566666666666666666666666600000000
0000000000000000000000006666666666666666666666666666666665556555bbbbb5b5555566655566565655b5b5bb66666666556666550000000000000000
0000000000000000000000006656666666666666666666666656656666655566bbbbb5bb555666655566655655b5bbbb66666666556665550000000000000000
0000000000000000000000006565666666665566665556666565565665665665bbbbb5bb6556666555666556b5bbbbbb66666666666666560000000000000000
0000000000000000000000006656666666655556655555666556556665556555bbbbb5bb6566666555666566b5bbbbbb66666666666556660000000000000000
0000000000000000000000006666656665666555655556566555565665555555bbbbb5bb6566666555666566b5bbbbbb66666666655555660000000000000000
0000000000000000000000006666565655555655665565566556556666555556bbbbbbbb6666665555666666bbbbbbbb66666666655555660000000000000000
0000000000000000000000006666656655555655666666666655556666666666bbbbbbbb6666655555566666bbbbbbbb66666666655566650000000000000000
0000000000000000000000006666666666556666666666666666666666666666bbbbbbbb6666655555566666bbbbbbbb66666666666666660000000000000000
6555555555555555555555566666666600000000bbb555555555555555555bbb0000000055055555000000005555555555555555500000055555555600000000
6500000000000000000000566666666600055000bb55555555555555555555bb0000000055055555000000005000000550000005505555055555555600000000
6500000000000000000000566666666600500500b5550555555555555550555b0000000000000000000000000555555005505550505505055555555600000000
65000000000000000000005666666666050550505555055555555555555055550000000055555505000000000555055005500550505055050000000600000000
65000000000000000000005666666666005005005555055555555555555055550000000055555505000000000550555005550550500550055050050600000000
65000000000000000000005666666666000550005555055555555555555055550000000000000000000000000505505005050500505505055055550600000000
65000000000000000000005666666666000000005555055555555555555055550000000055055555000000000555055000550050505555055055550600000000
65000000000000000000005666666666666666665555055555555555555055550000000055055555000000000555555005500550500000055055550600000000
65000000555555550000005600000000000000005055055555505550555055050000000000000000000000000000000005050500555555556555555500000000
65000000000000000000005600000000000000000555055555505550555055500000000000000000000000000505505005550050555555556555555500000000
65000000000000000000005600000000000000005555055555505550555055550000000000000000000000000505505005550550555555556555555500000000
65000000055555500000005600005050505050005555055500050005555055550000000000000000000000000000000000000000000000006000000000000000
65000000555665550000005600000505050500005055055550555055555055050000000000000000000000000555555005555550505005056050050500000000
65000000565665650000005600005050505050000555055550555055555055500000000000000000000000005000000550000005505555056055550500000000
65000000565665650000005600000000000000005555055550555055555055550000000000000000000000005555555555555555505555056055550500000000
65000000555555550000005666666666666666665555055505000500555055550000000000000000000000005555555555555555505555056055550500000000
65000000000000000000005600000000650000005555055555505550555055555555555555555555555555555555555555555555555555550000000000000000
65000000000000000000005600000000650000005555055555555555555055555555000000005555555000000000055500000000555555550000000000000000
65000000000000000000005600000000650000005555055555555555555055555550555555550555550555555555505555555555555555550000000000000000
65000000000000000000005600000000650000005550000000000000000005555505550000555055550500000000505500000000555555550000000000000000
65000000000000000000005600000000650000005505555550555505555550555055005555005505550505505550505505555550555555550000000000000000
65000000000000000000005600000000655555555055000000000000000055055050555555550505550505505550505505000050555555550000000000000000
65000000000000000000005600000000650000000550555555555555555505505000555555550005550500000000505505000050555555550000000000000000
65555555555555555555555600000000650000000005555555555555555550005050555555550505550505550550505505000050555555550000000000000000
0000000000000000000000000500000000000056b5555555555555555555555b5050555555550505550505550550505505000050555555550000000000000000
0000000000000000000000000500000000000056b5555555555555555555555b5050555555550505550500000000505505000050555555550000000000000000
0000000000000000000000000500000000000056b5555555555555555555555b5050555555050505550505505500005505000050555555550000000000000000
0000000000000000000000000500000000000056b5555555555555555555555b5050555550550505550505505550505505555550555555550000000000000000
0000000000000000000000000500000000000056b5555555555555555555555b5050555555550505550500000000505505555050555555550000000000000000
0000000000000000555555550555555555555556b5555555555555555555555b5000555555550005550555555555505505550550555555550000000000000000
0000000000000000000000000000000000000056b5555555555555555555555b5050555555550505550555555555505505555550555555550000000000000000
5555550550555555000000000000000000000056b5555555555555555555555b5050555555550505550555555555505505555550555555550000000000000000
00000005500000000000000000000000000005006500000000000000650000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000005500000000000000000000000000550006500000000000000650000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00000000000000000000000000000000050000506505555500000000650555550000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
00055555555550000005555555000000055555506505500500000000650555550000000000000000bbbbbb555bbbbbbbbbbbbbbb55bbbbbbbbbbbbbbb55bbbbb
00055555555550000005555555000000000000006505500500000000650555550000000000000000bbbbbb555bbbbbbbbbbbbbbb55bbbbbbbbbbbbbbb55bbbbb
50055555555550055005555555005000055555506505505550000000650550550000000000000000bbbbbb555bbbbbbbbbbbbbbb55bbbbbbbbbbbbbbb55bbbbb
50055555555550055005555555005000055555506505000500000000650500050000000000000000bbbbbbb5bbbbbbbbbbbbbbbb5bbbbbbbbbbbbbbbb5bbbbbb
50055555555550055005555555005000050000506505050500000000650000000000000000000000bbbb55bbb55bbbbbbbbbbb5555bbbbbbbbbbbbb555bbbbbb
55055555555550555505555555055000000000006500555000000000650500050000000000000000bbbbb55555bbbbbbbbbbbbb555bbbbbbbbbbbbb555bbbbbb
00055555555550000005555555000000000000006505050550000000650550550000000000000000bbbbbb555bbbbbbbbbbbbbbb555bbbbbbbbbbbbb555bbbbb
50055555555550055005555555050000000000006505505500000000650555550000000000000000bbbb5b555b5bbbbbbbbbbb5b555bbbbbbbbbbb5b555bbbbb
00055555555550000005555555000000000000006505555500000000650555550000000000000000bbbb5bbbbb5bbbbbbbbbbb5bbbbbbbbbbbbbbb5bbbbbbbbb
00000000000000000000000000000000000000006500000000000000650000000000000000000000bbbbbb5b5bbbbbbbbbbbbbb5555bbbbbbbbbbbb5555bbbbb
00005555555500000000555550000000000000006505555500000000650555550000000000000000bbbbbb5b5bbbbbbbbbbbbbb5bbb5bbbbbbbbbbbb5b5bbbbb
00005000000500000000500050000000000000006505555500000000650500050000000000000000bbbbbb5b5bbbbbbbbbbbbbb5bbb5bbbbbbbbbbbb5b5bbbbb
00000000000000000000000000000000000000006500000000000000650000000000000000000000bbbbbb5b5bbbbbbbbbbbbbb5bbbb5bbbbbbbbbbbb5bbbbbb
555555550000000055555555000000005555555500000000000000000000000000000000000000000000000000000000bbbbbbb7bbbbbbbbbbbbbbbbbbbbbbbb
000000000000000000000000000000000000000000005000000000000055555555555500000000000000000000000000bbb7bbb7bbb7bbbbbbbbbbbbbbbbbbbb
055555500000000000000000000000000055550000055500000000005550000000000555000000000000000000000000bbbb7bbbbb7bbbbbbbbbbbbbbbbbbbbb
500000050000000005555550000000000500005000550550000000005050000000000505000000000000000000000000bbbbbb555bbbbbbbbbbbbbbbbbbbbbbb
505555050000000005666650000000005055550505505055000000005555555555555555000000000000000000000000bbbbbb555bbbbbbbbbbbbbbbbbbbbbbb
550000550000000005666650000000005500005500550550000000005555555555555555000000000000000000000000bb5bbb505bbb5bbbbbbbbbbbbbbbbbbb
500000050000000005555550000000005000000500055500000000005000000000000005000000000000000000000000bbb5bbb5bbb5bbbbbbbbbbbbbbbbbbbb
500000050000000000000000000000005000000500005000000000000000000000000000000000000000000000000000bbbbb5bbb5bbbbbbbbbbbbbbbbbbbbbb
500055050555555055555555055555505000550500055056000000005555555555555555555555550000000000000000bbbbb55555bbbbbbbbbbbbbbbbbbbbbb
500005050555555055555555055555505000050550055056000000005555555555555555555555550000000000000000bbbbbb555bbbbbbbbbbbbbbbbbbbbbbb
500005050000000000000000000000005000050550055056000000005555555555555555555555550000000000000000bbbbbb555bbbbbbbbbbb5bbbbbb8bbbb
500000050555555055500555055555505000000555055056000000005555555555555555555555550000000000000000bbbbbbbbbbbbbbbbbbb58bb8bb585bbb
500000050550055050000005055555505000000500055056000000005555555555555555555555550000000000000000bbbbbb5555bbbbbbbb8888b5555b555b
500000050000000050555505055555505000000505055056000000005555555555555555555555550000000000000000bbbbbb5bb5bbbbbbbb5bbb85b858bbbb
500000050555555050000005055555505500005500000056000000000555555555555555555555500000000000000000bbbbb5bbbb5bbbbbbbbb55558bb88bbb
055555500550055055555555055555500555555000055056000000000055555555555555555555000000000000000000bbbbb5bbbb5bbbbbbbbbbbbbbbbbbbbb
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010100000000000000000000000000010101000000000001010100000000000101010000000000000000000001010000000000
0101010000101010000000000000000001010100000000000000000000000000010101000100000000000000000000000101010101000000000000000000000001010101010100010000000000000000010101010001000100000000000000000100010001000000000000000000000001010101010100000000000000000000
__map__
6767676767676767676767676767676767676767676767676767676767676767000000414141404000000042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67536373737373737373535353535353535353535353535353535353536353670000f7f8f8f8f8f8f900f7f8f8f8f8f8f9000000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535680e2e0e2825663535353535363535353535353535353535353535367000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535356a4b2f0f1b45653535353535353535353737373737373737353535367000000859696969696968700008596969696969696870000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67635356c700e50092565353536353535353537380e481e28181918273535367000000959696969696969700009596969696969696970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535356d7000000f55653535353535353535373a4f4f1f2f3c4b2b473535367000000959696969696969700009596969696969696970000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535356900000009256535353535353535353739000000000c2c39273535367000000a5a6a6a6a6a6a6a70000a5a6a6a6a6a6a6a6a70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535356a0b084b1a256535353535353535353679000000000d2d3926753536700008ab58c86a8a9868cb78a00b586aaab868b8b86b70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753536666665366666653535353535353537577a0a1b09394b1a1a27753536700009ab59c86b8b9869cb79a00b586babb869b9b86b70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67536356567356735656535363535353635353538383835656838383535353672d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535375535653755353535353535353535353737373565673735353535367000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353535653535353535353535353635353537373565673535353535367000000859696968700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
676353535353565656565656565656565653535366666656666666635353536700002d959696969700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353535353534646535353537356735353535373567375535353535367000000959696969700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353536353534646535353535356565656565656565353535353535367000000a5a6a6a6a700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353535353536465535353535356735353535353535353535353537d7d000000b58dac8db700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753536353535353535353535353535356535353535353535353535353537d5d0000009e9dbc9d8e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353535353535353535353535353565353535353536353535353537d5d5d00000000002d2d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
675353535353535353535353535353535653535353535353535353537d5d5d5d0000000000002d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353538091918181e281e08253535653535353535353535353537d5d5d5d000000444548494a4b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353a4b2b2c4f3f2f1f0b45353565353535353635353537453537d5d5d000000545558595a5b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353c5000000000000d9925353565353535353535363535353537d5d5d000000000068696a6b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353d500000000c0c100925353565353666666666666667d7d7d5d5d5d00000000007810107b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353539000000000d0d100925353565353535353535353537d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353a0b08484b1a1a1a1a25353565353535363535353537d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353767356567376535353535356535757575753535353537d7d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353666676565676666653535353565357575757536465535353537d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
675353535373735656735353535353535653575757576353535353537d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353535353535653535353535356565357797a575363536465537d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353535353565656565656565353535353565656535353537d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
676767676767676767676767676767676767676767677d7d7d7d7d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646464646464646464646464646464646464646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000b0500d0501105018050000002205000000000002c0502c050190501305011050120500000000000170501a05000000000000000000000000002a05000000000002e050000002e0501b0501b0501c050
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0104000000210022100421005210072100d2000f2001020009200152001620009200000000c2000d2000d200082000d2000d2000d200000000b2000c2000c200092000d2000d2000d200000000c2000000000000
01100000050000600008000080000c0000f00012000170000d0002000023000100002d00000000000000000011000000000000000000110000000000000000001100000000110000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a000000000168501785018850198501a8501b8501c8501e8501e85020850218502285023850248502485026850278502785028850298502a8502b8502b8502b8502c8502d8502e8502e8502f8502f8502f850
000a00001c000010000200005000300003300035000360003700038000380003600033000300002b00027000240000000022000000000000021000000002100000000240000000027000000002a000000002d000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000000000000002580025800258002580025800258000a80008800088000a8000e800000001280000000188000f8000c80000000000000000000000000000000000000000000000000000000000000000000
__music__
00 50514344
00 50424344

