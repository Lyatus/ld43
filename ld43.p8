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
	map_draw()
	hou_draw()
	lth_draw()
	ent_draw()
	tma_draw()
	crs_draw()
	cyc_draw()
end

-- tama

tma_stages = {
	{
		idl_spr = 1,
		eat_spr = 3,
	},
}

function tma_init()
	tma_stage = 1
	tma_x = 64
	tma_y = 64
	tma_frame = 0
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
	tma_frame += 1
end
function tma_draw()
	local off_x = -8
	local off_y = -14
	if tma_dst and tma_frame % 6 < 2 then
		off_y -= 1
	end
	spr(1,tma_x-map_x+off_x,tma_y-map_y+off_y,2,2)
end
function tma_goto(x, y)
	tma_dst = true
	tma_dst_x = x
	tma_dst_y = y
	ent_cur_act = nil -- ugh
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
	pal()
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
		spr(sprite, i*8-7, 0)
	end
end
function lth_add(v)
	lth = max(v,lth+v)
	lth_frame = 0
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
		spr(96,o.x-map_x-4,o.y-map_y-4)
	end,
	act = function(o)
		lth_add(2)
		ent_rem(o)
	end,
}
function spa_init()
	spas = {}
	add(spas,{
		x=55,y=70,ent=spa_candy,
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
	spr(cyc_icon, 99, 0)

	local time_str = leftpad(ceil(cyc_hour()%12),"0",2)
	.. ":" .. leftpad(flr(cyc_minute()%60),"0",2)
	print(time_str, 108, 1, 7)

	if cyc_is_night() then
		pal(5,1,1)
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
		x=13,y=4,
		sw=5,sh=4,
		spr=133,
	},
	{
		x=20,y=4,
		sw=5,sh=4,
		spr=138,
	},
}
houses = {} -- for now

function hou_draw()
	for h in all(houses) do
		if mid(tma_x,h.x*8,(h.x+h.sw)*8) != tma_x
		or mid(tma_y,h.y*8,(h.y+h.sh)*8) != tma_y then
			spr(h.spr,h.x*8-map_x,h.y*8-map_y,h.sw,h.sh)
		end
	end
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

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000055555000000000005555500000000000555550000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000550005500000000055000550000000005500055000000000000000000000
00077000000000000000000000000000000000000000005550000000000000000005000000050000000500000005000000050000000500000000000000000000
00700700000000000000000000000000000000000000005550000000000000000005000000050000000500000005000000050000000500000000000000000000
00000000000000000000000000000000000000000000005550000000000000000005050005050000000505000505000000050500050500000000000000000000
00000000000000000000000000000000000000000000000500000000000000000050005050005000005000505000500000500050500050000000000000000000
00000000000005555550000000000555555000000000055555000000000000000050000000005000005000000000500000500000000050000000000000000000
00000000000056666665000000005666666500000000055555000000000000000050000000005000005000000000500000500000000050000000000000000000
00000000000566566566500000056656656650000000505550500000000000000050005550005000005005555508500000500055500050000000000000000000
00000000000566566566500000056656656650000000005550000000000000000050050005005000005050505050500000500500080050000000000000000000
00000000000566666666500000056666666650000000005550000000000000000550000000005500055050505850550005500800008055000000000000000000
00000000000566655666500000056665566650000000005550000000000000000500000000000500050805850500850005080800008005000000000000000000
00000000000056666665000000005665566500000000005550000000000000000500000550000500050000808000050005080005500005000000000000000000
00000000000005555550000000000555555000000000005550000000000000000555555005555500055555558555550005555550055555000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055555000000000005555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000500000500000000050000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000500000500000000050000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005055055050000000505505505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005005005050000000500500505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005000000050000000500000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000500000500000000050000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000505550500000000050555050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000500000500000000050555050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000500000500000000050000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000055555000000000005555500000000000000000000000000000000000000000000000000000000000000000000066666000000000000000000000000000
00000000000000007000700700000000666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600000000
07707700077077000700007000070000666655575555566666666666666666666666666666666666665555556666666666666666666666666666666600000000
70070070777777700007700000700000666556555575556666666666666666666666666555666655666666655565566666666656565656566566666600000000
70000070777777707077770007700000665575555755555666666666666666666666655665556665556556656566556666566555555555555556656600000000
07000700077777000077770707770070665755555555575566666666666666666666556666655566665655656566655566655666666656666665566600000000
00707000007770000007700007777700656555575555755566666666666666666666566665566555555665656566656556656666655666666666566500000000
00070000000700000700007000777000665575557555565566666666666666666665566665566555556565656555665565566655665666555566655600000000
00000000000000007007000700000000656555755557556566666666666666666655556555666555556565555555665565656666666566666666565600000000
00000000000000000000000066666666655557555575555566666666666666666656555556556555556565555565565565666566566665666656665600000000
07000070000000000000000066666666655655565555665566666666666666666655655556656655556565565565565565656666655566666666565600000000
00700700007007000000000066666666565555655556555666666666666666666655656555656655556556565565565565656656666566566566565600000000
00000000000770000000000066666666656556555565555566666666666666666655656555656655556556556565565655656655666566555566565500000000
00000000000770000000000066666666655665655556555566666666666666666655656555655555656555556565565665665666566656666665665600000000
00700700007007000000000066666666665556555565655666666666666666666555656555656565565565555565555655666666655666666666665500000000
07000070000000000000000066666666656556655566566666666666666666666555656655656565565565555555555665666655665666555566665600000000
00000000000000000000000066666666665565555556655666666666666666666665655655656565565565555555555665566666666566666666655600000000
00000700000000000000000066666666666566655566556666666666666666666655655656656555565565555655555665656666666566666666565600000000
00000700000000000000000066666666666666655566666666666666666666666565655656656555565555655656655565566655665666555566655600000000
00777777000000000000000066666666666666655556666665666656665556666565555656565555565555656555556556656666655666666666566500000000
00777700000000000000000065665665666666655566666665566556555655566555555656566565556555556565556566655666666656666665566600000000
00777700000000555000000066565656665666655566666665555556555655566655556556566566556555556565556566566555555555555556656600000000
77777700000000555000000066666666665565655566566655566555665556666655556556566566556556556565556566666656565656566566666600000000
00700000000000555000000066666666666565655566565665566556566566566655556556566555556556565565556566666666666666666666666600000000
00700000000000050000000066666666666665555556665665566556555655566655656555556555556656565565556566666666666666666666666600000000
00000000000005555500000066666666666666666666666666666666655565556666656555556665556656565565656666666666000000000000000000000000
00000000000005555500000066566666666666666666666666566566666555666666656655566665556665565565666666666666000000000000000000000000
00000000000050555050000065656666666655666655566665655656656656656666656665566665556665566566666666666666000000000000000000000000
00000000000000555000000066566666666555566555556665565566655565556666656665666665556665666566666666666666000000000000000000000000
00000000000000555000000066666566656665556555565665555656655555556666656665666665556665666566666666666666000000000000000000000000
00000000000000555000000066665656555556556655655665565566665555566666666666666655556666666666666666666666000000000000000000000000
00000000000000555000000066666566555556556666666666555566666666666666666666666555555666666666666666666666000000000000000000000000
00000000000000555000000066666666665566666666666666666666666666666666666666666555555666666666666666666666000000000000000000000000
55555555555555555555555500000000000000006665555555555555555556660000000000000000000000000000000055555555000000000000000000000000
50000000000000000000000566666666000000006655555555555555555555660000000000000000000000000000000050000005055555500000000000000000
50000000000000000000000566666666000000006550555555555555555505560000000000000000000000000000000005505550055555500000000000000000
50000000000000000000000566666666000000005550555555555555555505550000000000000000000000000000000005500550055555500000000000000000
50000000000000000000000566666666000000005550555555555555555505550000000000000000000000000000000005550550055555500000000000000000
50000000000000000000000566666666000000005550555555555555555505550000000000000000000000000000000005550550055555500000000000000000
50000000000000000000000566666666000000005550555555555555555505550000000000000000000000000000000005550550055555500000000000000000
50000000000000000000000566666666000000005550555555555555555505550000000000000000000000000000000005550550000000000000000000000000
50000000555555550000000500000000000000005550555555555555555505550000000000000000000000000000000005550550555555550000000000000000
50000000000000000000000500000000000000005550555555555555555505550000000000000000000000000000000005550550555555550000000000000000
50000000000000000000000500000000000000005550555555555555555505550000000000000000000000000000000005550550555555550000000000000000
50000000055555500000000500000000000000005550555555555555555505550000000000000000000000000000000000000000000000000000000000000000
50000000555665550000000505050500000000005550555555555555555505550000000000000000000000000000000005555550505005050000000000000000
50000000565665650000000500505000000000005550555555555555555505550000000000000000000000000000000050000005555555550000000000000000
50000000565665650000000500000000000000005550555555555555555505550000000000000000000000000000000055555555555555550000000000000000
50000000555555550000000566666666000000005550555555555555555505550000000000000000000000000000000055555555555555550000000000000000
50000000000000000000000500000000500000005550555555555555555505555555555555555555555555555555555500000000000000000000000000000000
50000000000000000000000500000000500000005550555555555555555505555555500000055555555000000000055500000000000000000000000000000000
50000000000000000000000500000000500000005550555555555555555505555555055555505555550555555555505500000000000000000000000000000000
50000000000000000000000500000000500000005550000000000000000005555550555005550555550500000000505500000000000000000000000000000000
50000000000000000000000500000000500000005505555550555505555550555505500550055055550505505550505500000000000000000000000000000000
50000000000000000000000500000000555555555055000000000000000055055505055555505055550505505550505500000000000000000000000000000000
50000000000000000000000500000000500000000550555555555555555505505500055555500055550500000000505500000000000000000000000000000000
55555555555555555555555500000000500000000005555555555555555550005505055555505055550505550550505500000000000000000000000000000000
00000000000000000000000050000000000000056555555555555555555555565505055555505055550505550550505500000000000000000000000000000000
00000000000000000000000050000000000000056555555555555555555555565505055555505055550500000000505500000000000000000000000000000000
00000000000000000000000050000000000000056555555555555555555555565505055550505055550505505500005500000000000000000000000000000000
00000000000000000000000050000000000000056555555555555555555555565505055505505055550505505550505500000000000000000000000000000000
00000000000000000000000050000000000000056555555555555555555555565505055555505055550500000000505500000000000000000000000000000000
00000000000000005555555555555555555555556555555555555555555555565500055555500055550555555555505500000000000000000000000000000000
00000050050000000000000000000000000000056555555555555555555555565505055555505055550555555555505500000000000000000000000000000000
55555550055555550000000000000000000000056555555555555555555555565005055555505005550555555555505500000000000000000000000000000000
00000005500000000000000000000000000005005000000000000000500000000000000000000000000000000000000000000000000000000000000000000000
00000005500000000000000000000000000550005000000000000000500000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000050000505055555000000000505555500000000000000000000000000000000000000000000000000000000000000000
00055555555550000005555555000000055555505055005000000000505555500000000000000000000000000000000000000000000000000000000000000000
00055555555550000005555555000000000000005055005000000000505555500000000000000000000000000000000000000000000000000000000000000000
50055555555550055005555555005000055555505055055500000000505000500000000000000000000000000000000000000000000000000000000000000000
50055555555550055005555555005000055555505050005000000000505000500000000000000000000000000000000000000000000000000000000000000000
50055555555550055005555555005000050000505050505000000000505000500000000000000000000000000000000000000000000000000000000000000000
55055555555550555505555555055000000000005005550000000000505555500000000000000000000000000000000000000000000000000000000000000000
00055555555550000005555555000000000000005050505500000000505000500000000000000000000000000000000000000000000000000000000000000000
50055555555550055005555555050000000000005055055000000000505555500000000000000000000000000000000000000000000000000000000000000000
00055555555550000005555555000000000000005055555000000000505555500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005000000000000000500000000000000000000000000000000000000000000000000000000000000000000000
00005555555500000000555550000000000000005055555000000000505555500000000000000000000000000000000000000000000000000000000000000000
00005000000500000000500050000000000000005055555000000000505555500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000005000000000000000500000000000000000000000000000000000000000000000000000000000000000000000
55555555000000005555555500000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555550000000000000000000000000005555000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000000555555000000000050000500055055000000000000000000000000000000000000000000000000000000000000000000000000000000000
50555505000000000566665000000000505555050550505500000000000000000000000000000000000000000000000000000000000000000000000000000000
55000055000000000566665000000000550000550055055000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000000555555000000000500000050005550000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000000000000000000000500000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000
50005505055555505555555505555550500055050005550500000000000000000000000000000000000000000000000000000000000000000000000000000000
50000505055555505555555505555550500005055005550500000000000000000000000000000000000000000000000000000000000000000000000000000000
50000505000000000000000000000000500005055005550500000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005055555505550055505555550500000055505550500000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005055005505000000505555550500000050005550500000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000005055550505555550500000050505550500000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005055555505000000505555550550000550000000500000000000000000000000000000000000000000000000000000000000000000000000000000000
05555550055005505555555505555550055555500005050500000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010100000000000000000000000000010101000000000001010100000000000101010000000000000000000001010000000000
0101010000101010000000000000000001010100000000000000000000000000010101000100000000000000000000000101010101000000000000000000000001010101000000000000000000000000010101010000000000000000000000000000000000000000000000000000000001010101010000000000000000000000
__map__
6767676767676767676767676767676767676767676767676767676767676767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67536353535353535353535353535353535353535353535353535353536353670000000000000000000000000000000000000000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535380e2e0e282536353535353535353535353535353535353535353536700008b009f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353a4b2f0f1b4535353535353535353535373737373737373735353536700008b85868686868686878b8b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67635353c700e50092535353535353535353537380e481e2818191827353536700008b958686868686869700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353d7000000f55353535353535353535373a4f4f1f2f3c4b2b47353536700008b958686868686869700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353900000009253535353535353535353739000000000c2c3927353536700008ba5a6a6a6a6a6a6a700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353a0b093b1a253535353535353535353679000000000d2d3926753536700008ab58c86a8a9868cb78a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753536666665366666653535353535353537577a0a1b09393b1a1a27753536700009ab59c86b8b9869cb79a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67536353537353737453535363535353635353538383835353838383535353672d008b8b8b8b8b8b8b8b8b8b8b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
675353537553535353535353535353535353535373737353737373535353536700008b8b8b8b8b8b8b8b8b8b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353535353535353535353535353635353537373537373535353535367000000000000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
676353535353635353535363535363535353535366666653666666635353536700002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353535353535344455353535353535353535353635353755353535353670000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353536353535455535353535353535353535353535353535353535367000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353535353536465535353535353535353535353535353535353535c5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753536353535353535353535353535353535353535353535353535353535c5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353535353535353535353535353535353535353635353535353535d5d00000000002d2d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
675353535353535353535353535353535353535353535353535353535c5d5d5d0000000000002d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353538091918181e281e08253535353535353535353535353535c5d5d5d000000000000002d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353a4b2b2c4f3f2f1f0b4535353535353535363535353745353535d5d00000000000000002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353c5000000000000d9925353635353535353535363535353535d5d5d0000000000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353d500000000c0c10092535353535353535353535353535d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353539000000000d0d100925353535353535353535353535c5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353a0b093b1a1a1a1a1a25353535353535363534445535c5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353537673537376535353535353535348494a4b535455536c5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353666676537666665353535353535358595a5b536465444553535d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353537373537373535353535353535368696a6b6353535455535c5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67535353535353535353535353535353535378797a7b5363536465535c5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6753535353535353535353535353535353535353535353535353535c5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
676767676767676767676767676767676767676767674d4d4d4d4d5d5d5d5d5d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646464646464646464646464646464646464646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
