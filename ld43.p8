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
end
function _update()
	crs_update()
	lth_draw()
	cyc_update()
end
function _draw()
	cls()
	map_draw()
	crs_draw()
	lth_draw()
	cyc_draw()
end

-->8
-- map
function map_init()

end
function map_draw()
	map(0, 0, 0, 0, 16, 16)
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
		end
	elseif btnp(0) then crs_x -= 1
	elseif btnp(1) then crs_x += 1
	elseif btnp(2) then crs_y -= 1
	elseif btnp(3) then crs_y += 1
	end
	crs_x = mid(0, crs_x, 15)
	crs_y = mid(0, crs_y, 15)
end
function crs_draw()
	local act = act_get(crs_x, crs_y)
	if act then
		pal(7, 12)
	end
	spr(80, crs_x*8, crs_y*8)
	pal()
end

-->8
-- health

function lth_init()
	lth = 3
	lth_max = 3
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
	print(time_str, 108, 1)
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
00077000000000000000000000000000000000000000000000000000000000000005000000050000000500000005000000050000000500000000000000000000
00700700000000000000000000000000000000000000000000000000000000000005000000050000000500000005000000050000000500000000000000000000
00000000000000000000000000000000000000000000000000000000000000000005050005050000000505000505000000050500050500000000000000000000
00000000000000000000000000000000000000000000000000000000000000000050005050005000005000505000500000500050500050000000000000000000
00000000000005555550000000000555555000000000000000000000000000000050000000005000005000000000500000500000000050000000000000000000
00000000000050000005000000005000000500000000000000000000000000000050000000005000005000000000500000500000000050000000000000000000
00000000000500500500500000050050050050000000000000000000000000000050005550005000005005555508500000500055500050000000000000000000
00000000000500500500500000050050050050000000000000000000000000000050050005005000005050505050500000500500080050000000000000000000
00000000000500000000500000050000000050000000000000000000000000000550000000005500055050505850550005500800008055000000000000000000
00000000000500055000500000050005500050000000000000000000000000000500000000000500050805850500850005080800008005000000000000000000
00000000000050000005000000005005500500000000000000000000000000000500000550000500050000808000050005080005500005000000000000000000
00000000000005555550000000000555555000000000000000000000000000000555555005555500055555558555550005555550055555000000000000000000
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
00000000000000007000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07707700077077000700007000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70070070777777700007700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000070777777707077770007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000700077777000077770707770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000007770000007700007777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000000700000700007000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700000000000000005505500000666666666666566600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700000000000000557555575000666666666666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777000550000005505055550500666666666656665600000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000550000055555570555500666666666666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700005555000057550555555550666666666665666600000000000000000000000000000000000000000000000000000000000000000000000000000000
77777700000550000005555555570550666666666666665600000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000005555000055575555555500666666666566666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000005005000005055570555500666666666666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000005555555575000566666560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000705055550000666566560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000505000000666566660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000550000000656665660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000550000000656665660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000550000000666666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000550000000665666560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000005555000000665666560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4141414040646464646464646442430064646464646464646464646464646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
50516464646464646464646464646400646464000000000000000000000000640000000000000000000000000000000000000000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646464640064640000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646464640064640000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646460646464646464646464610064640000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6460646464646464646461646464640064640000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646460646464646464646464640064000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646461640064000000000000000000000000002d64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646565747474646464646464640064000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
646465656574747464646464646464006464494a4b4c000000000000000000642d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64646565657474746464646464646400646400005b5c00000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
646464646464646464646464646464006464696a6b6c00000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646464647b6464797a7b7c0000000000000000006400002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
646464646464646464646464646464006464494a4b4c48494a4b4c48494a4b640000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
646464646464646464646464646464006464595a5b5c58595a5b5c58595a5b640000002d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000006464696a6b6c68696a6b6c68696a6b64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
646464646464646464646464646464646464797a7b7c78797a7b7c78797a7b6400000000002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
64646464646464646464646448494a4b4c48494a4b4c48494a4b4c48494a4b6400000000002d2d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464640000000058595a5b5c58595a5b5c58595a5b5c58595a5b5c58595a5b640000000000002d2d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464000000000068696a6b6c68696a6b6c68696a6b6c68696a6b6c68696a6b64000000000000002d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464000000000078797a7b7c78797a7b7c78797a7b7c78797a7b7c78797a7b6400000000000000002d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
646400000000000000000000000000000048494a4b4c590056000068696a6b640000000000002d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
646400000000000000000000000000000058595a5b5c000000000078797a7b64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
640000000000000000000000000000000068696a6b6c00000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
646400000000000000000000000000000078797a7b7c00000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464000000000000000000000000000000000000000000000000000000006464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464000000000000000000000000000000000000000000000000000000006464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6400000000000000000000000000000000000000000000000000000000006464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6400000000000000000000000000000000000000000000000000000000006464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6400000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6400000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6464646464646464646464646464646464646464646464646464646464646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
