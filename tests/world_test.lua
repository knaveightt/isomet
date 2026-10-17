local W=require('world')
for seed=1,200 do
  math.randomseed(seed)
  local rooms=W.generate(math.random)
  assert(#rooms==12); W.validate(rooms)
  local decoded={}
  for id,r in ipairs(rooms) do
    decoded[id]=W.decode(W.encode(r),id)
    assert(W.encode(decoded[id])==W.encode(r))
    for _,p in ipairs(r.pillars) do assert(math.abs(p.x-r.width/2)>=1.6 and math.abs(p.y-r.height/2)>=1.6) end
  end
  W.validate(decoded)
end
assert(not pcall(W.decode,'size = 0 4',1))
assert(not pcall(W.decode,'size = 8 8\nexit = XX 2',1))
assert(not pcall(W.decode,'size = 8 8\npillar = 99 2',1))
print('200 generated worlds passed connectivity, reciprocal exits, portal, clear paths, and file round-trip checks.')
