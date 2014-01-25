local function combine_textures(t1, t2, t3, t4)
	return "[combine:32x32:0,0="..t1..":0,16="..t2..":16,16="..t3..":16,0="..t4
end

minetest.register_node("mblocks:container", {
	drawtype = "airlike",
	paramtype = "light",
	pointable = "false",
	tiles = {combine_textures("default_wood.png", "default_mese.png", "default_dirt.png", "default_stone.png")},
	groups = {crumbly = 3},
})

local nodeboxes = {
	{-1/2, -1/2, -1/2, 0,   0,   0  },
	{0,    -1/2, -1/2, 1/2, 0,   0  },
	{-1/2, 0,    -1/2, 0,   1/2, 0  },
	{0,    0,    -1/2, 1/2, 1/2, 0  },
	{-1/2, -1/2, 0,    0,   0,   1/2},
	{0,    -1/2, 0,    1/2, 0,   1/2},
	{-1/2, 0,    0,    0,   1/2, 1/2},
	{0,    0,    0,    1/2, 1/2, 1/2},
}

local function get_contained_nodes(pos, all_if_empty)
	local meta = minetest.get_meta(pos)
	local s = meta:get_string("contained_nodes")
	if s == "" then
		if all_if_empty then
			return {"", "", "", "", "", "", "", ""}
		else
			return {}
		end
	end
	return minetest.deserialize(s)
end

local function get_texture(name, index)
	index =  math.min(#minetest.registered_nodes[name].tiles, index)
	return minetest.registered_nodes[name].tiles[index]
end

local function gt(name1, name2, index)
	if name1 ~= nil then
		return get_texture(name1, index)
	elseif name2 ~= nil then
		return get_texture(name2, index)
	else
		return "blank.png"
	end
end

local function get_node_textures(T)
	return {
		combine_textures(gt(T[7], T[5], 1), gt(T[3], T[1], 1), gt(T[4], T[2], 1), gt(T[8], T[6], 1)),
		combine_textures(gt(T[1], T[3], 2), gt(T[5], T[7], 2), gt(T[6], T[8], 2), gt(T[2], T[4], 2)),
		combine_textures(gt(T[4], T[3], 3), gt(T[2], T[1], 3), gt(T[6], T[5], 3), gt(T[8], T[7], 3)),
		combine_textures(gt(T[7], T[8], 4), gt(T[5], T[6], 4), gt(T[1], T[2], 4), gt(T[3], T[4], 4)),
		combine_textures(gt(T[8], T[4], 5), gt(T[6], T[2], 5), gt(T[5], T[1], 5), gt(T[7], T[3], 5)),
		combine_textures(gt(T[3], T[7], 6), gt(T[1], T[5], 6), gt(T[2], T[6], 6), gt(T[4], T[8], 6)),
	}
end

local function get_nodebox(T)
	local nodebox = {}
	for key, _ in pairs(T) do
		nodebox[#nodebox+1] = nodeboxes[key]
	end
	return {type = "fixed", fixed = nodebox}
end

local function change_node(pos, T)
	local node = {name = "mblocks:container"}
	minetest.set_node_with_def(pos, node, minetest.registered_nodes["mblocks:container"],
		{
			drawtype = "nodebox",
			pointable = "true",
			paramtype = "light",
			node_box = get_nodebox(T),
			tiles = get_node_textures(T),
			selection_box = get_nodebox(T),
		})
	local meta = minetest.get_meta(pos)
	meta:set_string("contained_nodes", minetest.serialize(T))
end

local function get_index(x, y, z)
	s = 1
	if x >= 0 then s = s+1 end
	if y >= 0 then s = s+2 end
	if z >= 0 then s = s+4 end
	return s
end

local function raytrace(ppos, dir, under, above)
	local T = get_contained_nodes(under, true)
	local xint, yint, zint, t, index
	print(dump(dir))
	if under.x ~= above.x then
		xint = (above.x+under.x)/2
		t = (xint-ppos.x)/dir.x
		yint = ppos.y+dir.y*t - under.y
		zint = ppos.z+dir.z*t - under.z
		print(yint, zint, "x")
		index = get_index(above.x - under.x, yint, zint)
		if T[index] ~= nil and math.abs(yint) <= 0.5 and math.abs(zint) <= 0.5 then
			return above, get_index(under.x - above.x, yint, zint)
		end
		t = (under.x-ppos.x)/dir.x
		yint = ppos.y+dir.y*t - under.y
		zint = ppos.z+dir.z*t - under.z
		print(yint, zint, "x")
		index = get_index(under.x - above.x, yint, zint)
		if T[index] ~= nil and math.abs(yint) <= 0.5 and math.abs(zint) <= 0.5 then
			return under, get_index(above.x - under.x, yint, zint)
		end
	elseif under.y ~= above.y then
		yint = (above.y+under.y)/2
		t = (yint-ppos.y)/dir.y
		xint = ppos.x+dir.x*t - under.x
		zint = ppos.z+dir.z*t - under.z
		index = get_index(xint, above.y - under.y, zint)
		print(xint, zint, "y")
		if T[index] ~= nil and math.abs(xint) <= 0.5 and math.abs(zint) <= 0.5 then
			return above, get_index(xint, under.y - above.y, zint)
		end
		t = (under.y-ppos.y)/dir.y
		xint = ppos.x+dir.x*t - under.x
		zint = ppos.z+dir.z*t - under.z
		print(xint, zint, "y")
		index = get_index(xint, under.y - above.y, zint)
		if T[index] ~= nil and math.abs(xint) <= 0.5 and math.abs(zint) <= 0.5 then
			return under, get_index(xint, above.y - under.y, zint)
		end
	else
		zint = (above.z+under.z)/2
		t = (zint-ppos.z)/dir.z
		yint = ppos.y+dir.y*t - under.y
		xint = ppos.x+dir.x*t - under.x
		index = get_index(xint, yint, above.z - under.z)
		print(xint, yint, "z")
		if T[index] ~= nil and math.abs(yint) <= 0.5 and math.abs(xint) <= 0.5 then
			return above, get_index(xint, yint, under.z - above.z)
		end
		t = (under.z-ppos.z)/dir.z
		yint = ppos.y+dir.y*t - under.y
		xint = ppos.x+dir.x*t - under.x
		print(xint, yint, "z")
		index = get_index(xint, yint, under.z - above.z)
		if T[index] ~= nil and math.abs(yint) <= 0.5 and math.abs(xint) <= 0.5 then
			return under, get_index(xint, yint, above.z - under.z)
		end
	end
end

local function on_place(itemstack, user, pointed_thing)
	if pointed_thing.type ~= "node" then return end
	local above = pointed_thing.above
	local under = pointed_thing.under
	local node = minetest.get_node(under)
	if not minetest.registered_nodes[node.name] then return end
	local dir = user:get_look_dir()
	local ppos = user:getpos()
	ppos.y = ppos.y + 1.5 -- Camera
	
	local newpos, index = raytrace(ppos, dir, under, above)
	if newpos ~= nil then
		local T = get_contained_nodes(newpos)
		if T[index] == nil then
			T[index] = minetest.registered_items[itemstack:get_name()].sname
			change_node(newpos, T)
		end
	end
end

minetest.register_craftitem("mblocks:wood", {
	description = "Wood microblock",
	inventory_image = "default_wood.png",
	on_place = on_place,
	sname = "default:wood",
})

minetest.register_craftitem("mblocks:stone", {
	description = "Stone microblock",
	inventory_image = "default_stone.png",
	on_place = on_place,
	sname = "default:stone",
})

minetest.register_craftitem("mblocks:mese", {
	description = "Mese microblock",
	inventory_image = "default_mese.png",
	on_place = on_place,
	sname = "default:mese",
})
