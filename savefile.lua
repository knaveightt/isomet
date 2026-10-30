-- Keep a recoverable previous file if replacing an existing destination fails.
local S={}
function S.write(name,text)
 local ok,err=love.filesystem.write(name..'.tmp',text)
 if not ok then return nil,err end
 local root=love.filesystem.getSaveDirectory()..'/'
 ok,err=os.rename(root..name..'.tmp',root..name)
 if ok then return true end
 -- Windows may refuse a rename over an existing file. Preserve it first.
 if love.filesystem.getInfo(name)then
  love.filesystem.remove(name..'.bak')
  local backed,backupErr=os.rename(root..name,root..name..'.bak')
  if not backed then return nil,backupErr end
  ok,err=os.rename(root..name..'.tmp',root..name)
  if not ok then os.rename(root..name..'.bak',root..name)end
 end
 return ok,err
end
function S.read(name)
 return love.filesystem.read(love.filesystem.getInfo(name) and name or name..'.bak')
end
return S
