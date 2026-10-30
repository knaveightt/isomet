local Campaign=require('campaign')
local P={};P.__index=P
local function escape(s)return (tostring(s):gsub('([^%w% ._-])',function(c)return string.format('%%%02X',c:byte())end))end
local function unescape(s)return (s:gsub('%%(%x%x)',function(h)return string.char(tonumber(h,16))end))end
function P.new(now)
 return setmetatable({room=1,hearts=5,heartAt=now or os.time(),solved={},unlocked={},seen={[1]=true},inspected={},notes={},finalStep=0,rescued=false,cells=1,bright=0,lightOn=false,freeCellAt=0,practice=0,capacity=30,materials={shards=0,scrap=0,thread=0},overflow={shards=0,scrap=0,thread=0},profile={name='Traveler',variant=1,origin='City',companion=5}},P)
end
function P:items()
 local items={['Personal keepsake']=true}
 for id in pairs(self.solved) do local _,_,d=Campaign.info(id);if d and d[4] then items[d[4]]=true end end
 return items
end
function P:missing(id)
 local _,_,d=Campaign.info(id);local missing={};if not d then return missing end
 local items=self:items();for _,item in ipairs(d[5]) do if not items[item] then missing[#missing+1]=item end end
 return missing
end
function P:locked(id)
 local l,s,d=Campaign.info(id)
 if s==7 and not self.solved[Campaign.id(l,14)] then return 'The guardian still blocks the exit landing.' end
 if d then local n=s-7
  if n==5 or n==7 or n==8 or (l==2 and n==3) or (l==4 and n==6) then
   local missing=self:missing(id);if #missing>0 then return 'Need: '..table.concat(missing,', ') end
  end
 end
end
function P:note(key,text) self.notes[key]=text end
function P:complete(id)
 if self.solved[id] then return false end
 self.solved[id]=true
 local _,slot=Campaign.info(id);if slot==11 then self:addMaterial('thread',1)end
 local l,_,d=Campaign.info(id)
 if d and d[4] then self:note('reward'..id,d[4]..' — '..d[6]) end
 if d and d[3]=='story' then
  self:note('evidence'..l,Campaign.worlds[l].record)
  self:note('trace'..l,Campaign.origins[self.profile.origin].traces[l])
 end
 return true
end
function P:addMaterial(kind,count)
 local used=self.materials.shards+self.materials.scrap+self.materials.thread
 local fit=math.max(0,math.min(count,self.capacity-used))
 self.materials[kind]=self.materials[kind]+fit;self.overflow[kind]=self.overflow[kind]+count-fit
end
function P:claimMaterials()
 for _,kind in ipairs({'shards','scrap','thread'})do local count=self.overflow[kind];self.overflow[kind]=0;self:addMaterial(kind,count)end
end
function P:practiceReward()
 self.practice=self.practice+1;local kind=self.practice%2==1 and 'shards' or 'scrap';self:addMaterial(kind,1);return kind
end
function P:available(kind)return self.materials[kind]+self.overflow[kind]end
function P:takeMaterial(kind,count)
 local stored=math.min(count,self.materials[kind]);self.materials[kind]=self.materials[kind]-stored;self.overflow[kind]=self.overflow[kind]-(count-stored)
end
function P:craftCell()
 if self:available('shards')<2 or self:available('scrap')<1 then return false end
 self:takeMaterial('shards',2);self:takeMaterial('scrap',1);self.cells=self.cells+1;self:claimMaterials();return true
end
function P:expand()
 if self:available('scrap')<3 or self:available('thread')<2 then return false end
 self:takeMaterial('scrap',3);self:takeMaterial('thread',2);self.capacity=self.capacity+10;self:claimMaterials();return true
end
function P:freeCell(now)
 now=now or os.time();if now<self.freeCellAt then return false end
 self.cells=self.cells+1;self.freeCellAt=now+1200;return true
end
function P:regenerate(now)
 now=now or os.time()
 -- Do not grant a windfall if the system clock is moved backwards.
 if now<self.heartAt then self.heartAt=now end
 if self.hearts>=5 then self.heartAt=now;return false end
 local gain=math.floor((now-self.heartAt)/1200)
 if gain<1 then return false end
 self.hearts=math.min(5,self.hearts+gain);self.heartAt=self.hearts==5 and now or self.heartAt+gain*1200
 return true
end
function P:wait(now)return math.max(0,1200-((now or os.time())-self.heartAt))end
function P:loseLife(now)
 if self.hearts<=0 then return false end
 if self.hearts==5 then self.heartAt=now or os.time() end
 self.hearts=self.hearts-1;local l=Campaign.info(self.room);self.room=Campaign.id(l,1);self.x=nil;self.y=nil
 self:note('warning'..l,Campaign.worlds[l].warning)
 return true
end
function P.edge(a,b)return math.min(a,b)..'-'..math.max(a,b)end
function P:encode()
 local out={'version=1','room='..self.room,'hearts='..self.hearts,'heartAt='..self.heartAt,'finalStep='..self.finalStep,'rescued='..tostring(self.rescued)}
 for _,k in ipairs({'cells','bright','freeCellAt','practice','capacity'})do out[#out+1]=k..'='..self[k]end
 out[#out+1]='lightOn='..tostring(self.lightOn)
 for _,kind in ipairs({'shards','scrap','thread'})do out[#out+1]='material='..kind..':'..self.materials[kind];out[#out+1]='overflow='..kind..':'..self.overflow[kind]end
 if self.x then out[#out+1]='x='..self.x;out[#out+1]='y='..self.y end
 for _,k in ipairs({'name','variant','origin','companion'}) do out[#out+1]=k..'='..escape(self.profile[k]) end
 for _,k in ipairs({'solved','seen','inspected','unlocked'}) do
  local keys={};for key in pairs(self[k]) do keys[#keys+1]=tostring(key) end;table.sort(keys)
  for _,key in ipairs(keys) do out[#out+1]=k..'='..key end
 end
 local keys={};for k in pairs(self.notes) do keys[#keys+1]=k end;table.sort(keys)
 for _,k in ipairs(keys) do out[#out+1]='note='..escape(k)..':'..escape(self.notes[k]) end
 return table.concat(out,'\n')..'\n'
end
function P.decode(text)
 local p=P.new();local version
 for line in text:gmatch('[^\r\n]+') do local k,v=line:match('^(%w+)=(.*)$')
  if k=='version' then version=tonumber(v)
  elseif k=='room' or k=='hearts' or k=='heartAt' or k=='x' or k=='y' or k=='finalStep' then p[k]=assert(tonumber(v),'Invalid save number')
  elseif k=='rescued' or k=='lightOn' then p[k]=v=='true'
  elseif k=='cells' or k=='bright' or k=='freeCellAt' or k=='practice' or k=='capacity' then p[k]=assert(tonumber(v))
  elseif k=='material' or k=='overflow' then local kind,count=v:match('^(%w+):(%d+)$');assert(p.materials[kind] and count,'Invalid material');local target=k=='material' and p.materials or p.overflow;target[kind]=tonumber(count)
  elseif k=='name' or k=='origin' then p.profile[k]=unescape(v)
  elseif k=='variant' or k=='companion' then p.profile[k]=assert(tonumber(v),'Invalid character')
  elseif k=='solved' or k=='seen' or k=='inspected' then local id=tonumber(v);assert(id and id%1==0 and id>=1 and id<=60,'Invalid saved room');p[k][id]=true
  elseif k=='unlocked' then assert(v:match('^%d+%-%d+$'),'Invalid passage');p.unlocked[v]=true
  elseif k=='note' then local key,value=v:match('^(.-):(.*)$');assert(key);p.notes[unescape(key)]=unescape(value) end
 end
 assert(version==1 and p.room%1==0 and p.room>=1 and p.room<=60,'Invalid journey version or room')
 assert(p.hearts%1==0 and p.hearts>=0 and p.hearts<=5 and p.heartAt==p.heartAt and p.heartAt<1e12,'Invalid life data')
 assert(p.profile.variant%1==0 and p.profile.variant>=1 and p.profile.variant<=8 and p.profile.companion%1==0 and p.profile.companion>=1 and p.profile.companion<=8,'Invalid appearance')
 assert(Campaign.origins[p.profile.origin] and #p.profile.name>0 and #p.profile.name<=100,'Invalid profile')
 assert(p.finalStep%1==0 and p.finalStep>=0 and p.finalStep<=4,'Invalid finale checkpoint')
 if p.x then assert(p.y and p.x==p.x and p.y==p.y and p.x>=0 and p.x<=16 and p.y>=0 and p.y<=16,'Invalid position') end
 for _,k in ipairs({'cells','bright','freeCellAt','practice','capacity'})do assert(p[k]==p[k] and p[k]>=0 and p[k]<1e12,'Invalid supplies')end
 assert(p.capacity>=30 and p.capacity%1==0 and p.cells%1==0 and p.practice%1==0,'Invalid quantities')
 return p
end
return P
