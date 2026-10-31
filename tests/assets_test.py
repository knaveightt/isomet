"""Read-only validation of illustrated source atlases and runtime source rectangles."""
from pathlib import Path
from PIL import Image
import hashlib
import re
root=Path(__file__).resolve().parents[1]
text=(root/'cartoon_atlas.lua').read_text()
expected={'scenery':12,'travelers':8,'terrain':4,'puzzle':12,'ground':4,'backdrops':4,'kiln':15,'harbor':15,'snowfair':15,'orchard':15}
for sheet,count in expected.items():
    section=re.search(r' '+sheet+r'=\{file="([^"]+)",width=(\d+),height=(\d+),rects=\{(.*?)\n \}\}',text,re.S)
    assert section, sheet
    path,width,height,values=section.groups()
    image=Image.open(root/path)
    assert image.size==(int(width),int(height))
    assert min(image.size)>800
    opaque=sheet in {'ground','backdrops'}
    assert image.mode=='RGB' if opaque else image.mode=='RGBA' and image.getchannel('A').getextrema()[0]==0
    rects=[tuple(map(int,m)) for m in re.findall(r'\{(\d+),(\d+),(\d+),(\d+)\}',values)]
    assert len(rects)==count
    hashes=set()
    for x,y,w,h in rects:
        assert w>100 and h>100 and x>=0 and y>=0 and x+w<=image.width and y+h<=image.height
        region=image.crop((x,y,x+w,y+h))
        assert opaque or region.getchannel('A').getextrema()[1]>200
        hashes.add(hashlib.sha256(region.tobytes()).hexdigest())
    assert len(hashes)==count, f'{sheet} contains duplicate art'
    print(f'{sheet}: {count} distinct source regions; source rectangles valid')
