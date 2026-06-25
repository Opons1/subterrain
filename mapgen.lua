--ylimits
local YMIN = -3000
local YMAX = -400
--Cave threshold: 1 = small rare caves,
-- 0.5 = 1/3rd ground volume, 0 = 1/2 ground volume.
local TCAVE = 0.5
-- Blend distance near top/bottom limits
local BLEND = 128
-- 3D cave noise definition
local np_cave = {
	offset = 0,
	scale = 1,
	spread = {x = 768, y = 256, z = 768},
	seed = 59033,
	octaves = 6,
	persist = 0.63
}
-- Blend boundaries
local yblmin = YMIN + BLEND * 1.5
local yblmax = YMAX - BLEND * 1.5
local c_air = core.get_content_id("air")
core.register_on_generated(function(vm, minp, maxp, blockseed)
	if minp.y > YMAX or maxp.y < YMIN then
		return
	end
	local t1 = os.clock()
	local x0, y0, z0 = minp.x, minp.y, minp.z
	local x1, y1, z1 = maxp.x, maxp.y, maxp.z
	local emin, emax = vm:get_emerged_area()
	local area = VoxelArea:new({
		MinEdge = emin,
		MaxEdge = emax
	})
	local data = vm:get_data()
    local sidelen = x1 - x0 + 1
	local chulens = {x = sidelen, y = sidelen, z = sidelen}
	local minposxyz = {x = x0, y = y0, z = z0}
	-- Perlin map for this chunk
	local nobj_cave = core.get_perlin_map(np_cave, chulens)
	local nvals_cave = nobj_cave:get3dMap_flat(minposxyz)
	local nixyz = 1
	for z = z0, z1 do
	    for y = y0, y1 do
		    -- Cave threshold varies near world limits
		    local tcave
		    if y < yblmin then
			    tcave = TCAVE + ((yblmin - y) / BLEND) ^ 2
		    elseif y > yblmax then
			    tcave = TCAVE + ((y - yblmax) / BLEND) ^ 2
		    else
			    tcave = TCAVE
		    end
		    local vi = area:index(x0, y, z)
		    for x = x0, x1 do
			    -- Carve cave where noise exceeds threshold
			    if nvals_cave[nixyz] > tcave then
				    data[vi] = c_air
			    end
			    nixyz = nixyz + 1
			    vi = vi + 1
		    end
	    end
	end

	vm:set_data(data)
	vm:calc_lighting()
end)

