# Borra las lenguas dibujadas por PixelLab de los fotogramas del golpe del latigazo del Glotón (5 a 8, las 8 direcciones),
# porque las pinta el código (lengua.gd). YA SE HA PASADO (19 nov): no volver a pasarlo con «guardar» (borraría más).
# Uso: py tools/gloton_sin_lengua.py [guardar] [vista.png]
import re, sys
from PIL import Image
from collections import deque
GUARDAR = len(sys.argv) > 1 and sys.argv[1] == "guardar"
s=open('assets/sprites/jefe-gloton.tres',encoding='utf-8').read()
reg={m[0]:tuple(map(int,m[1:])) for m in re.findall(r'id="(t\d+)"\]\natlas = ExtResource\("hoja"\)\nregion = Rect2\((\d+), (\d+), (\d+), (\d+)\)',s)}
h=Image.open('assets/sprites/jefe-gloton.png').convert('RGBA')
def rojo(c):
    r,g,b,a=c
    return a>0 and r>=g*1.5+8 and r>=b*1.4+8
prev=Image.new('RGBA',(129*8,109*8),(60,60,60,255))
for d in range(8):
    base=80+d*9
    for f in range(5,9):
        x0,y0,w,hh=reg[f't{base+f}']
        im=h.crop((x0,y0,x0+w,y0+hh)); px=im.load()
        vis=[[False]*hh for _ in range(w)]
        borrar=set()
        for x in range(w):
            for y in range(hh):
                if vis[x][y] or not rojo(px[x,y]): continue
                comp=[]; toca=0; q=deque([(x,y)]); vis[x][y]=True
                while q:
                    a,b=q.popleft(); comp.append((a,b))
                    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                        u,v=a+dx,b+dy
                        if not(0<=u<w and 0<=v<hh): continue
                        c=px[u,v]
                        if c[3]==0: toca+=1
                        elif not vis[u][v] and (rojo(c) or (c[0]<70 and c[1]<40 and c[3]>0)):
                            vis[u][v]=True; q.append((u,v))
                if len(comp)>=25 and toca>=6: borrar.update(comp)
        # solo lo rojo de la lengua (no lo oscuro de la boca)
        todo=set(borrar)
        def fuera_de(u,v,quitar):
            n=0
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                a,b=u,v
                for _ in range(12):
                    a+=dx; b+=dy
                    if 0<=a<w and 0<=b<hh and px[a,b][3] and (a,b) not in quitar: n+=1; break
            return n<4
        # lo rojo, siempre; lo oscuro (contorno de la lengua), solo si queda fuera del cuerpo
        rojos={(a,b) for (a,b) in todo if rojo(px[a,b])}
        def fino(a,b):
            n=sum(1 for dx in (-1,0,1) for dy in (-1,0,1) if (dx or dy) and 0<=a+dx<w and 0<=b+dy<hh and px[a+dx,b+dy][3] and (a+dx,b+dy) not in rojos)
            return n<5
        borrar=rojos|{(a,b) for (a,b) in todo if (a,b) not in rojos and fuera_de(a,b,rojos) and fino(a,b)}
        def opaco(u,v): return 0<=u<w and 0<=v<hh and px[u,v][3] and (u,v) not in borrar
        dentro=set()
        for (a,b) in borrar:
            lados=0
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                u,v=a,b
                for _ in range(12):
                    u+=dx; v+=dy
                    if opaco(u,v): lados+=1; break
            if lados==4: dentro.add((a,b))
        for (a,b) in borrar: px[a,b]=(0,0,0,0)
        falta=set(dentro)
        while falta:
            hecho=[]
            for (a,b) in falta:
                vec=[px[a+dx,b+dy] for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)) if 0<=a+dx<w and 0<=b+dy<hh and px[a+dx,b+dy][3]]
                if vec: hecho.append(((a,b),vec[(a+b)%len(vec)]))
            if not hecho: break
            for (q,c) in hecho: px[q]=c; falta.discard(q)
        # motitas sueltas que quedan (grupos de menos de 15 píxeles separados del cuerpo)
        vis=[[False]*hh for _ in range(w)]
        for x in range(w):
            for y in range(hh):
                if vis[x][y] or px[x,y][3]==0: continue
                comp=[]; q=deque([(x,y)]); vis[x][y]=True
                while q:
                    a,b=q.popleft(); comp.append((a,b))
                    for dx in (-1,0,1):
                        for dy in (-1,0,1):
                            u,v=a+dx,b+dy
                            if 0<=u<w and 0<=v<hh and not vis[u][v] and px[u,v][3]:
                                vis[u][v]=True; q.append((u,v))
                if len(comp)<15:
                    for a,b in comp: px[a,b]=(0,0,0,0)
        prev.alpha_composite(im,((f-5)*129+(d%2)*129*4,(d//2)*109*2))
        prev.alpha_composite(h.crop((x0,y0,x0+w,y0+hh)),((f-5)*129+(d%2)*129*4,(d//2)*109*2+109))
        if GUARDAR: h.paste(im,(x0,y0))
if GUARDAR: h.save('assets/sprites/jefe-gloton.png')
prev.resize((prev.width*2//2*1, prev.height)).save(sys.argv[-1] if len(sys.argv)>2 else 'capturas/gloton-sin-lengua.png')
