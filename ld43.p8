pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- general

function _init()
	crs_init()
	cyc_init()
	lth_init()
	map_init()
	act_reset()
	tma_init()
end
function _update()
	crs_update()
	map_update()
	lth_update()
	cyc_update()
	tma_update()
end
function _draw()
	cls()
	map_draw()
	hou_draw()
	lth_draw()
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
		if tma_new_x != tma_x or tma_new_y != tma_y then
			local col_x = fget(mget((tma_new_x-4)/8,tma_y/8),0) or fget(mget((tma_new_x+4)/8,tma_y/8),0)
			local col_y = fget(mget(tma_x/8,tma_new_y/8),0)
			tma_x = col_x and tma_x or tma_new_x
			tma_y = col_y and tma_y or tma_new_y
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
	crs_x = 8
	crs_y = 8
	crs_last_m_x = -1
	crs_last_m_y = -1
	poke(0x5f2d, 1)
end
function crs_update()
	if btnp(4) or stat(34)!=0 then -- action
		local act = act_get(crs_x, crs_y)
		if act then
			act.f()
		else -- tama destination
			tma_goto(crs_x*8+map_x+4, crs_y*8+map_y+4)
		end
	end
	if btnp(0) then crs_x -= 1 end
	if btnp(1) then crs_x += 1 end
	if btnp(2) then crs_y -= 1 end
	if btnp(3) then crs_y += 1 end
	if stat(32) != crs_last_m_x then
		crs_x = flr(stat(32)/8)
		crs_last_m_x = stat(32)
	end
	if stat(33) != crs_last_m_y then
		crs_y = flr(stat(33)/8)
		crs_last_m_y = stat(33)
	end
	crs_x = mid(0, crs_x, 15)
	crs_y = mid(0, crs_y, 15)
end
function crs_draw()
	local act = act_get(crs_x, crs_y)
	local sprite = (btn(4) or stat(34)!=0) and 81 or 80
	if act then
		pal(7, 12)
	end
	spr(sprite, crs_x*8, crs_y*8)
	pal()
end

-- health

function lth_init()
	lth = 5
	lth_max = 5
end
function lth_update()

end
function lth_draw()
	for i=1,lth_max do
		local sprite = i>lth and 64 or 65
		spr(sprite, i*8-8, 0)
	end
end

-- actions
function act_reset()
	act_i = 1
	acts = {}
end
function act_add(x, y, f)
	local act = {
		x=x,y=y,f=f,
	}
	acts[act_i] = act
	act_i += 1
	return act
end
function act_rem(act)
	-- todo
end
function act_get(x, y)
	-- todo: use map offset
	for act in all(acts) do
		if act.x==x and act.y==y then
			return act
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
00000000000050000005000000005000000500000000055555000000000000000050000000005000005000000000500000500000000050000000000000000000
00000000000500500500500000050050050050000000505550500000000000000050005550005000005005555508500000500055500050000000000000000000
00000000000500500500500000050050050050000000005550000000000000000050050005005000005050505050500000500500080050000000000000000000
00000000000500000000500000050000000050000000005550000000000000000550000000005500055050505850550005500800008055000000000000000000
00000000000500055000500000050005500050000000005550000000000000000500000000000500050805850500850005080800008005000000000000000000
00000000000050000005000000005005500500000000005550000000000000000500000550000500050000808000050005080005500005000000000000000000
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
00000055555000000000005555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000700700000000666666756556666666666655655666660000000000000000000000000000000000000000000000000000000000000000
07707700077077000700007000070000666655575555566666665555555556660000000000000000000000000000000000000000000000000000000000000000
70070070777777700007700000700000666556555575656666655656555565660000000000000000000000000000000000000000000000000000000000000000
70000070777777707077770007700000665575555755556666555555565555660000000000000000000000000000000000000000000000000000000000000000
07000700077777000077770707770070665755555555575666555565555555560000000000000000000000000000000000000000000000000000000000000000
00707000007770000007700007777700666555575555755666655555555565560000000000000000000000000000000000000000000000000000000000000000
00070000000700000700007000777000665575557555565666555555555555660000000000000000000000000000000000000000000000000000000000000000
00000000000000007007000700000000666555755557556666656555565555660000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000066666666666557555575566666655555555556660000000000000000000000000000000000000000000000000000000000000000
07000070000000000000000066666666666655565555666666665556555566660000000000000000000000000000000000000000000000000000000000000000
00700700007007000000000066666666666666655566666666666655556666660000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000066666666666666655666666666666665566666660000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000066666666666666655566666666666665566666660000000000000000000000000000000000000000000000000000000000000000
00700700007007000000000066666666666666655666666666666555566666660000000000000000000000000000000000000000000000000000000000000000
07000070000000000000000066666666666666655666666666666665566666660000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000066666666666665555666666666666665566666660000000000000000000000000000000000000000000000000000000000000000
00000700000000000000000066666666666666655666666666666666000000000000000000000000000000000000000000000000000000000000000000000000
00000700000000000000000066666666666666655666666666666666000000000000000000000000000000000000000000000000000000000000000000000000
00777777000000000000000066666666666666655666666665566556000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000065665665666666655666666665566556000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000555000000066565656666666655666666655555555000000000000000000000000000000000000000000000000000000000000000000000000
77777700000000555000000066666666666666655666666655555555000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000555000000066666666666666655666666665566556000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000050000000066666666666666555566666665566556000000000000000000000000000000000000000000000000000000000000000000000000
00000000000005555500000066666666666666666666666666666666000000000000000000000000000000000000000000000000000000000000000000000000
00000000000005555500000066566666666666666666666666566566000000000000000000000000000000000000000000000000000000000000000000000000
00000000000050555050000065656666666655666655566665655656000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000555000000066566666666555566555556665565566000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000555000000066666566656665556555565665555656000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000555000000066665656555556556655655665565566000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000555000000066666566555556556666666666555566000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000555000000066666666665566666666666666666666000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555500000000000000000555555555555555555555555555555555555550000555555555555555555555555555555555500000000000
50000000000000000000000566666666000000000000000000000000000000000000000000000000005555555555555555555555555555555555550000000000
50000000000000000000000566666666000000000500500555005005550050055555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000566666666000000000555055505550555055505555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000566666666000000000555555505555555055555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000566666666000000000500500555000005550055555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000566666666000000000005550050055500500555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000566666666000000000555055505555555055555555555555555555550055555555555555555555555555555555555555000000000
50000000555555550000000500000000000000000555055555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000500000000000000000005550055555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000500000000000000000500500555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000055555500000000500000000000000000555055555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000555005550000000505050500000000000555555555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000505005050000000500505000000000000555555555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000505005050000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000000555555550000000566666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000000000000000000000500000000000000000555555555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000500000000000000000555555555555555555555555555555555555550055555555555555555555555555550005555555000000000
50000000000000000000000500000000000000000555000000055000000000555555555555555550055500050005500050005555555505550555555000000000
50000000000000000000000500000000000000000555055055055055050550555555050505555550055505050505505050505555550055055005555000000000
50000000000000000000000500000000000000000555055055055055050550555550000000555550055505050505505050505555550550505505555000000000
50000000000000000000000500000000000000000555050005055050000050555500555550055550055500050005500050005555550505550505555000000000
50000000000000000000000500000000000000000555055055055055050550555505550555055550055505050505505050505555550505550505555000000000
55555555555555555555555500000000000000000555055055055055050550555505005005055500055505050505505050505555550505550505555000000000
00000000000000000000000050000000000000050555000000055000000000555505055505055550055505050505505050505555550505550505555000000000
00000000000000000000000050000000000000050555055555055055555550555505055505055500055505050505505050505555550505550505555000000000
00000000000000000000000050000000000000050555000000055000000000555505055505055550055500050005500050005555550505550505555000000000
00000000000000000000000050000000000000050555505050555550505055555505055505055500055555555555555555555555550505500505555000000000
00000000000000000000000050000000000000050555555555555555555555555505055505055550055500050005500050005555550505550505555000000000
00000000000000005555555555555555555555550555555555555555555555555505055505055500055505050505505050505555550505550505555000000000
00000050050000000000000050000000000000050555555555555555555555555505055505055550055500050005500050005555550505550505555000000000
55555550055555550000000050000000000000050555555555555555555555555005055505005550055555555555555555555555550505550505555000000000
00000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50055555555550050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50055555555550050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50055555555550050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55055555555550550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50055555555550050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00005000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555550000000000000000000000000005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000000000000000000000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50555505000000000000000000000000505555050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55000055000000000000000000000000550000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000000000000000000000500000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000000000000000000000500000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50005505055555505555555505555550500055050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000505055555505555555505555550500005050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000505000000000000000000000000500005050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005055555505550055505555550500000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005055005505000000505555550500000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005000000005055550505555550500000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000005055555505000000505555550550000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555550055005505555555505555550055555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000001000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
5353535353535353535353535353535353535353535353535353535353535364000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53536353535353535353535353535353535353535353535353535353536353640000000000000000000000000000000000000000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5353535353536353535353535353535353535353535353535353535353535364000000009f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5353535353535353535353535353535353535353737373737373737353535364000000009f9f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
536353536353535353535353535353535353537380e48181818191827353536400000080e481818181918200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5353535353535353535353535353535353535373b3f4f1f2f3b2b2b473535364000000b3f4f1f2f3b2b2b400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53535353534445535353535353535353535353739000000094c0c192735353640000009000000094c0c19200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5353535353545553535353535353535353535373900000e2a4d0d19273765364000000900000e2a4d0d19200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5353535363646553535353535353535353537573a0a1b093b1a1a1a273535364000000a0a1b093b1a1a1a200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53536353535353745353535363535353635353538383835383838383535353642d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5353535375535353535353535353535353535353737373537373735353675364000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5353535353535353535353535353535353635353537373537373535353535364000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
535353535353535353535363535363535353535366666653666666635353536400002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53535353535353535353535353535353535353535353635353755353535353640000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
53535374535353535353535353535353535353535353535353535353535353640000002d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e9e5e6e7e8e9e5e6e7e8e9e5e6e7e8e9e5e6535353535368696a6b64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c9c5c6c7c8c9c580e4818181819182c97b63535353537c78797a7b6400000000002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d9d5d6d773d9d5b3f4f1f2f3b2b2b4d94b53535353534c48494a4b6400000000002d2d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e9e5e6e7e8e9e59000000094c0c192e95b5353535353c7c8c95a5b640000000000002d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c9c5c6c7c8736b900000e2a4d0d1926a536353535353d7d8d96a6b64000000000000002d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d9d5d6d7d8d97ba0a1b093b1a1a1a253535376795353e7e8e97a7b6400000000000000002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e9e5e6e7e8e900537653535376535353535353535353c7c8c96a6b640000000000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c9fafb00730000535353535353535363535353535353c6c7c8c97b64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d900000000000000000000000068696a6b6c0000e5d5d6d7d8d90064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e900000000000000000000000078797a7b7c0000c5e5c5c6c7c8c964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c900000000000000000000000000000000000000d5c5d5d6d7d8d964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d900000000000000000000000000000000000000c5d5e5e6e7e8e964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e900000000000000000000000000000000000000d5e5e6e7e8e9d964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c900000000000000000000000000000000000000e5e5e5e6e7e8e964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d900000000000000000000000000000000000000e5e6e7e8e9000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e9000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646464646464646464646464646464646464646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
