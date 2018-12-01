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
	lth_draw()
	cyc_update()
	tma_update()
end
function _draw()
	cls()
	map_draw()
	lth_draw()
	cyc_draw()
	tma_draw()
	crs_draw()
end

-->8
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
			-- todo handle collision
			tma_x = tma_new_x
			tma_y = tma_new_y
		else
			tma_dst = false
		end
	end
	tma_frame += 1
end
function tma_draw()
	-- handle map offset
	local off_x = -8
	local off_y = -8
	if tma_dst and tma_frame % 6 < 2 then
		off_y -= 1
	end
	spr(1, tma_x+off_x, tma_y+off_y, 2, 2)
end
function tma_goto(x, y)
	tma_dst = true
	tma_dst_x = x
	tma_dst_y = y
end

-->8o
-- map

function map_init()
	map_x = 0
	map_y = 0
end
function map_draw()
	map(map_x, map_y, 0, 0, 16, 16)
end
function map_move(x, y)
	-- return true if actually moved
	local old_map_x = map_x
	local old_map_y = map_y
	map_x = mid(0, map_x+x, 16)
	map_y = mid(0, map_y+y, 16)
	return old_map_x != map_x or old_map_x != map_y
end

-->8
-- cursor
function crs_init()
	crs_x = 8
	crs_y = 8
end
function crs_update()
	if btnp(4) then -- action
		local act = act_get(crs_x, crs_y)
		if act then
			act.f()
		else -- tama destination
			-- todo handle map offset
			tma_goto(crs_x*8+4, crs_y*8+4)
		end
	end
	if btnp(0) then crs_x -= 1 end
	if btnp(1) then crs_x += 1 end
	if btnp(2) then crs_y -= 1 end
	if btnp(3) then crs_y += 1 end
	crs_x = mid(0, crs_x, 15)
	crs_y = mid(0, crs_y, 15)
end
function crs_draw()
	local act = act_get(crs_x, crs_y)
	local sprite = btn(4) and 81 or 80
	if act then
		pal(7, 12)
	end
	spr(sprite, crs_x*8, crs_y*8)
	pal()
end

-->8
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

-->8
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

-->8
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
end
function cyc_minute() return cyc_frame / 30 end
function cyc_hour() return cyc_minute() / 60 end
function cyc_day() return cyc_hour() / 24 end
function cyc_is_day() return abs(cyc_hour() % 24 - 12) < 8 end
function cyc_is_night() return not cyc_is_day() end

-->8
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
00000000000000007000700700000000000055055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07707700077077000700007000070000005575555750000000005505500000000000000000000000000000000000000000000000000000000000000000000000
70070070777777700007700000700000055050555505000000555555555000000000000000000000000000000000000000000000000000000000000000000000
70000070777777707077770007700000555555705555000005505055550500000000000000000000000000000000000000000000000000000000000000000000
07000700077777000077770707770070575505555555500055555550555500000000000000000000000000000000000000000000000000000000000000000000
00707000007770000007700007777700055555555705500055550555555550000000000000000000000000000000000000000000000000000000000000000000
00070000000700000700007000777000555755555555000005555555550550000000000000000000000000000000000000000000000000000000000000000000
00000000000000007007000700000000050555705555000055555555555500000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000066666666055555555750000005055550555500000000000000000000000000000000000000000000000000000000000000000000
07000070000000000000000066666666007550555500000005555555555000000000000000000000000000000000000000000000000000000000000000000000
00700700007007000000000066666666000005050000000000555055550000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000066666666000005500000000000000505000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000066666666000005550000000000000550000000000000000000000000000000000000000000000000000000000000000000000000
00700700007007000000000066666666000005500000000000000550000000000000000000000000000000000000000000000000000000000000000000000000
07000070000000000000000066666666000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000066666666000555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700000000000000000066666666000005500000000066666666666666660000000000000000000000000000000000000000000000000000000000000000
00000700000000000000000066666666000005500000000066666666666666660000000000000000000000000000000000000000000000000000000000000000
00777777000000000000000066666666000005500000000066655666666666660000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000066665666000005500000000066555566666666660000000000000000000000000000000000000000000000000000000000000000
00777700000000555000000066565656000005500000000056665556665566660000000000000000000000000000000000000000000000000000000000000000
77777700000000555000000065566556000005500000000055556555665556660000000000000000000000000000000000000000000000000000000000000000
00700000000000555000000056665665000005500000000055556555655555660000000000000000000000000000000000000000000000000000000000000000
00700000000000050000000066656656000055550000000065566666666666660000000000000000000000000000000000000000000000000000000000000000
00000000000005555500000066666666000000000000000066666666000000000000000000000000000000000000000000000000000000000000000000000000
00000000000005555500000066566666000000000000000066666666000000000000000000000000000000000000000000000000000000000000000000000000
00000000000050555050000065656666000000000000000066666666000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000555000000066566666000000000000000066666666000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000555000000066666566000000000000000066666666000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000555000000066665656000000000000000066666666000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000555000000066666566000000000000000066666666000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000555000000066666666000000000000000066666666000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555555555555555555555555555550555555555555555555555555555555555555550000555555555555555555555555555555555500000000000
50000000000000000000000000000000000000050000000000000000000000000000000000000000005555555555555555555555555555555555550000000000
50000000000000000000000000000000000000050500500555005005550050055555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050555055505550555055505555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050555555505555555055555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050500500555000005550055555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050005550050055500500555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050555055505555555055555555555555555555550055555555555555555555555555555555555555000000000
55555555555555555555555555555555555555550555055555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050005550055555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050500500555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050555055555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050555555555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050555555555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000000000000000000000000000000000000050555555555555555555555555555555555555550055555555555555555555555555555555555555000000000
50000000000000000000000000000000000000050555555555555555555555555555555555555550055555555555555555555555555550005555555000000000
50000000000000000000000000000000000000050555000000055000000000555555555555555550055500050005500050005555555505550555555000000000
50000000000000000000000000000000000000050555055055055055050550555555050505555550055505050505505050505555550055055005555000000000
50000000000000000000000000000000000000050555055055055055050550555550000000555550055505050505505050505555550550505505555000000000
50000000000000000000000000000000000000050555050005055050000050555500555550055550055500050005500050005555550505550505555000000000
50000000000000000000000000000000000000050555055055055055050550555505550555055550055505050505505050505555550505550505555000000000
50000000000000000000000000000000000000050555055055055055050550555505005005055500055505050505505050505555550505550505555000000000
50000000000000000000000000000000000000050555000000055000000000555505055505055550055505050505505050505555550505550505555000000000
50000000000000000000000000000000000000050555055555055055555550555505055505055500055505050505505050505555550505550505555000000000
50000000000000000000000000000000000000050555000000055000000000555505055505055550055500050005500050005555550505550505555000000000
50000000000000000000000000000000000000050555505050555550505055555505055505055500055555555555555555555555550505500505555000000000
50000000000000000000000000000000000000050555555555555555555555555505055505055550055500050005500050005555550505550505555000000000
50000000000000000000000000000000000000050555555555555555555555555505055505055500055505050505505050505555550505550505555000000000
50000000000000000000005000000000500000050555555555555555555555555505055505055550055500050005500050005555550505550505555000000000
55555555555555555555555000000000555555550555555555555555555555555005055505005550055555555555555555555555550505550505555000000000
55550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000001000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
c9cacbc6c7c8c9cacbc6c7c5c6c7c8c9c5c6c7c8c9c5c6c7c8c9c5c6c7c8c964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9dadbd6d7d8d9dadbd6d7d5d6d7d8d9d5d6d7d8d9d5d6d7d8d9d5d6d7d8d9640000000000000000000000000000000000000000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e9eaebe6e7e8e9eaebe6c6e5e6e7e8e9e5e6e7e8e9e5e6e7e8e9e5e6e7e8e964000000009f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f9fafbf6f7f8f9fafbf6d6c5c6c7c8c9c5c6c7c8c90000000000000000000064000000009f9f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c9cacbc6c7c8c9cacbc6e6d5d68081828384d7d880818283840000000000006400000000009f9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d9dadbd6d7d8d9dadbd6f6e5e69091929394e7e89091929394000000000000640000000000009f9f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e9eaebe6e7e8e9eaebe6e7e8e9a0a1a2a3a4c7c8a0a1a2a3a400000000000064000000000000009f9f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f9fafbf6f7f8f9fafbf6f7f8f9b0b1b2b3b4d7d8b0b1b2b3b400000000002d6400000000000000009f9f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c6c7c8d6d7d8d9dadbdbf8f9fafbeb00e5e6e7e8e90000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d6d7d8e6e7e8e9eaebebf7c5c6c7c8c9c5c6c7c8c94c000000000000000000642d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c7c8c9c5c6c7c8c9c8c9e7d5d6d7d8d9d5d6d7d8d95c00000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d7d8d9d5d6d7d8d9d8d9f7e5e6e7e8e9e5e6e7e8e96c00000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e7e8e9e5e6e7e8e9e8e9f8f9fad6d7d8d9dadb7a7b7c0000000000000000006400002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c9c5c6c7c8c9c5c6c7c8c9c5c6c7c8c9c5c6c7c8c94b4c48494a4b640000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d9d5d6d7d8d9d5d6d7d8d9d5d6d7d8d9d5d6d7d8d95b5c58595a5b640000002d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e9e5e6e7e8e9e5e6e7e8e9e5e6e7e8e9e5e6e7e8e96b6c68696a6b64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c9c5c6c7c8c9c5c6c7c8c9c5c6c7c8c97b7c78797a7b7c78797a7b6400000000002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d9d5d6d7d8d9d5d6d7d8d9d5d6d7d8d94b4c48494a4b4c48494a4b6400000000002d2d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e9e5e6e7e8e9e5e6e7e8e9e5e6e7e8e95b5c5859c5c6c7c8c95a5b640000000000002d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c9c5c6c7c8c96b6c68696a6b6c68696a6b6c6869d5d6d7d8d96a6b64000000000000002d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d9d5d6d7d8d97b7c78797a7b7c78797a7b7c7879e5e6e7e8e97a7b6400000000000000002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e9e5e6e7e8e90000000000000048494a4b4c5900c5c6c7c8c96a6b640000000000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c9fafb0000000000000000000058595a5b5c0000d5c5c6c7c8c97b64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d900000000000000000000000068696a6b6c0000e5d5d6d7d8d90064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e900000000000000000000000078797a7b7c0000c5e5c5c6c7c8c964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c900000000000000000000000000000000000000d5c5d5d6d7d8d964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d900000000000000000000000000000000000000c5d5e5e6e7e8e964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e900000000000000000000000000000000000000d5e5e6e7e8e9d964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c5c6c7c8c900000000000000000000000000000000000000e5e5e5e6e7e8e964000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d5d6d7d8d900000000000000000000000000000000000000e5e6e7e8e9000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e5e6e7e8e9000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646464646464646464646464646464646464646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
