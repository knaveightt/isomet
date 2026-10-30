local files={};local refuseReplace=true;local failFinal=false
local originalRename=os.rename
love={filesystem={
 write=function(name,text)files[name]=text;return true end,
 read=function(name)return files[name]end,
 getInfo=function(name)return files[name]and {}end,
 getSaveDirectory=function()return '/save'end,
 remove=function(name)files[name]=nil;return true end
}}
os.rename=function(from,to)
 from=from:gsub('^/save/','');to=to:gsub('^/save/','')
 if not files[from]then return nil,'missing'end
 if failFinal and from:match('%.tmp$')then return nil,'write denied'end
 if refuseReplace and files[to]then return nil,'already exists'end
 files[to]=files[from];files[from]=nil;return true
end
local S=require('savefile')
assert(S.write('journey','first'));assert(S.read('journey')=='first')
assert(S.write('journey','second'));assert(S.read('journey')=='second' and files['journey.bak']=='first')
failFinal=true;assert(not S.write('journey','third'));assert(S.read('journey')=='second')
files['journey']=nil;assert(S.read('journey')==nil) -- rollback consumed backup restoring primary
files['journey.bak']='recovered';assert(S.read('journey')=='recovered')
os.rename=originalRename
print('Save replacement, Windows-style backup, failed-write rollback and backup recovery passed.')
