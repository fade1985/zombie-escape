"""Saca las piernas de Johnny de la hoja de un arma cuerpo a cuerpo.

  py tools/piernas.py            las cinco armas de golpe (fregona, bate, cuchillo, motosierra y katana)
  py tools/piernas.py bate       solo esa
  py tools/piernas.py --ver      además deja en capturas/ dos fotos por arma para repasar el recorte a ojo

Al golpear andando, Johnny se pinta partido por la cintura: el dibujo del golpe pone el cuerpo y el de andar pone las
piernas (cintura.gdshader). Para eso hay que saber, en cada dibujo, qué píxeles son piernas. Antes lo adivinaba el
shader por el color mientras se jugaba y fallaba: lo claro del vaquero no contaba (piernas con agujeros y trozos
sueltos) y todo lo oscuro de cerca de los pies sí (se colaba la motosierra del dibujo de andar). Ahora se decide aquí,
con calma, y se guarda en assets/sprites/<hoja>-piernas.png: una imagen del tamaño de la hoja que solo tiene las
piernas, en su sitio, de las filas de andar y de golpe. El shader ya no adivina: de las filas de andar pinta esas
piernas, y del golpe quita lo que esta imagen dice que es pierna.

Cómo se decide en cada dibujo, de la cintura (17 píxeles por encima de los pies) para abajo:
  1. el vaquero: lo azul. Empieza por lo azul de verdad y se extiende a lo azulado que lo toca (los brillos)
  2. los zapatos: lo marrón de cerca del suelo que queda justo debajo del vaquero
  3. el borde: lo negro pegado a lo anterior (cerca del suelo, un poco más: la suela)
  4. andando, el zapato del pie que se levanta por detrás (queda al lado de la pierna)
  5. lo que queda rodeado de pierna (los brillos del zapato, las motas oscuras del vaquero)
  6. en la katana, se quita lo fino: su vaina es azul marino como el vaquero y cruza por delante de las piernas
Lo demás (el arma, el barrido, el agua) no entra.

Y en las filas de andar se rellena lo que el arma tapa: andando, la motosierra va delante de los muslos y la vaina de la
katana cruza las piernas, así que al quitar el arma quedaría un hueco. Cada píxel tapado que tiene pierna debajo, en
su columna, se pinta del color de esa pierna (y de negro en los cantos, como el borde del dibujo).

Las skins solo cambian la cabeza: las piernas de la hoja de siempre valen para todas (se comprueba aquí: si una skin
tuviera otras piernas, avisa). Si se rehace el paso o el golpe de una hoja, hay que volver a pasar esto.
"""
import json, os, sys, glob
import numpy as np
from PIL import Image

ARMAS = {"fregona": "conserje-48-guardia", "bate": "conserje-48-bate", "cuchillo": "conserje-48-cuchillo",
	"motosierra": "conserje-48-motosierra", "katana": "conserje-48-katana"}
# La motosierra, al golpear, baja hasta el suelo y tiene los mismos marrones que los zapatos: en ella solo es zapato
# el que está pegado al vaquero, no el que cae debajo sin tocarlo
SIN_ZAPATOS_SUELTOS = ["motosierra"]
# La katana lleva la vaina azul marino cruzada por delante de las piernas: en ella se quita lo fino
QUITAR_LO_FINO = ["katana"]
CINTURA = 17      # píxeles del dibujo por encima de los pies (como en cintura.gdshader)
SUELO = 9         # hasta qué altura sobre los pies puede haber zapato
ANCHO = 22        # hasta dónde se buscan piernas a cada lado de los pies
ALTO_RODILLA = 8  # desde qué altura sobre los pies una columna de pierna es muslo o rodilla (se rellena hacia arriba)

ver = "--ver" in sys.argv
pedidas = [a for a in sys.argv[1:] if not a.startswith("--")] or list(ARMAS)


def clases(c):
	"""De cada píxel: si es azul de verdad, azulado, zapato (marrón oscuro), marrón o negro"""
	r, g, b, a = [c[..., k].astype(int) for k in range(4)]
	hay = a > 0
	luz = 0.299 * r + 0.587 * g + 0.114 * b
	negro = hay & (np.maximum(np.maximum(r, g), b) < 42)
	azulado = hay & ~negro & (b - r >= 30) & (b >= g) & (luz < 170) & (r * 10 >= b * 3)   # (el agua es más viva)
	azul = azulado & (r * 100 <= b * 68) & (luz < 150)
	marron = hay & ~negro & ~azulado & (r > b + 10) & (r >= g) & (luz < 105) & (b * 100 <= g * 74)   # (el rojo de la sierra tiene más azul)
	zapato = marron & (luz < 60)
	return azul, azulado, zapato, marron, negro


def vecinos(m, ocho=True):
	"""Los píxeles que tocan a alguno de m"""
	v = np.zeros_like(m)
	v[1:, :] |= m[:-1, :]
	v[:-1, :] |= m[1:, :]
	v[:, 1:] |= m[:, :-1]
	v[:, :-1] |= m[:, 1:]
	if ocho:
		v[1:, 1:] |= m[:-1, :-1]
		v[1:, :-1] |= m[:-1, 1:]
		v[:-1, 1:] |= m[1:, :-1]
		v[:-1, :-1] |= m[1:, 1:]
	return v


def abrir(m, n):
	"""Deja solo lo que cabe en un cuadrado de n x n píxeles (quita lo fino)"""
	alto, ancho = m.shape
	dentro = np.ones((alto - n + 1, ancho - n + 1), dtype=bool)
	for dy in range(n):
		for dx in range(n):
			dentro &= m[dy:dy + alto - n + 1, dx:dx + ancho - n + 1]
	fuera = np.zeros_like(m)
	for dy in range(n):
		for dx in range(n):
			fuera[dy:dy + alto - n + 1, dx:dx + ancho - n + 1] |= dentro
	return fuera


def encerrado(m, hay, abajo, mayor=40):
	"""Los trozos del dibujo que no son pierna pero están encerrados en ella: no tocan nada vacío"""
	alto, ancho = m.shape
	resto = hay & abajo & ~m
	visto = np.zeros_like(m)
	sale = np.zeros_like(m)
	for y0, x0 in zip(*np.nonzero(resto)):
		if visto[y0, x0]:
			continue
		trozo, cola, cerrado = [], [(y0, x0)], True
		visto[y0, x0] = True
		while cola:
			y, x = cola.pop()
			trozo.append((y, x))
			for yy, xx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
				if not (0 <= yy < alto and 0 <= xx < ancho):
					cerrado = False
				elif not abajo[yy, xx]:
					pass   # (la cintura cierra por arriba)
				elif not hay[yy, xx]:
					cerrado = False
				elif resto[yy, xx] and not visto[yy, xx]:
					visto[yy, xx] = True
					cola.append((yy, xx))
		if cerrado and len(trozo) <= mayor:
			for y, x in trozo:
				sale[y, x] = True
	return sale


def piernas(dibujo, px, py, sueltos, andando, fino):
	"""La máscara de las piernas de un dibujo (una casilla de la hoja)"""
	alto, ancho = dibujo.shape[:2]
	ys, xs = np.mgrid[0:alto, 0:ancho]
	abajo = ys > py - CINTURA
	zona = abajo & (np.abs(xs - px + 0.5) < ANCHO)
	azul, azulado, zapato, marron, negro = clases(dibujo)
	hay = dibujo[..., 3] > 0
	# 1. el vaquero: lo azul de verdad y lo azulado que lo va tocando
	m = azul & zona
	while True:
		mas = vecinos(m, False) & azulado & abajo & ~m
		if not mas.any():
			break
		m |= mas
	# 2. los zapatos: lo marrón de cerca del suelo que queda justo debajo del vaquero o de su borde, y lo que siga de
	# ese zapato (4 píxeles como mucho: así no se mete por el arma si la toca). Con "sueltos", también el marrón oscuro
	# que cae debajo del vaquero sin tocarlo (el barrido blanco tapa la pierna y deja el zapato suelto)
	cerca_suelo = ys > py - SUELO
	base = m | (vecinos(m) & negro & abajo)
	encima = np.zeros_like(base)
	encima[1:, :] = base[:-1, :]
	z = marron & cerca_suelo & zona & encima
	if sueltos:
		debajo = m.any(axis=0)   # las columnas donde hay vaquero (y dos más a cada lado)
		debajo = debajo | np.roll(debajo, 1) | np.roll(debajo, -1) | np.roll(debajo, 2) | np.roll(debajo, -2)
		z |= zapato & cerca_suelo & zona & debajo[np.newaxis, :]
	for _ in range(4):
		z |= vecinos(z, False) & marron & cerca_suelo & zona
	m |= z
	# 3. el borde negro pegado a todo lo anterior; cerca del suelo, un poco más (la suela y el zapato en sombra)
	m |= vecinos(m) & negro & abajo
	for _ in range(2):
		m |= vecinos(m, False) & negro & cerca_suelo & zona
	# 4. andando, el pie que se levanta por detrás: su zapato queda al lado de la pierna, no debajo. Lo marrón y lo
	# negro de cerca del suelo que sigue a la pierna, 6 píxeles como mucho
	if andando:
		pie = m.copy()
		for _ in range(6):
			pie |= vecinos(pie, False) & (marron | negro) & (ys > py - SUELO - 2) & zona
		# (solo lo que abulta: una raya de un píxel es el borde del arma, no un zapato)
		m |= abrir(pie, 2)
	# 5. lo que queda rodeado de pierna (los brillos del zapato, las motas más oscuras del vaquero)
	for _ in range(2):
		rodeado = sum(np.roll(m, s, axis=e).astype(int) for s in (1, -1) for e in (0, 1)) >= 3
		m |= hay & abajo & rodeado
	# (y las manchas: la motosierra le salpica de sangre el pantalón. Lo que está encerrado del todo entre pierna y
	# cintura, sin tocar nada vacío, y es pequeño, es una mancha del pantalón)
	m |= encerrado(m, hay, abajo)
	# 6. fuera lo fino: la vaina de la katana es azul marino como el vaquero y cruza por delante de las piernas, pero
	# es una barra de 2 o 3 píxeles de gorda y una pierna tiene 4 por lo menos. Se queda lo gordo y lo que esté a 3
	# píxeles de lo gordo (los tobillos, la punta del zapato)
	if fino:
		gordo = abrir(m, 4)
		for _ in range(3):
			gordo |= vecinos(gordo) & m
		m = gordo
	return m


def rellenar(dibujo, m, py):
	"""Las piernas de un dibujo de andar, con lo que tapa el arma relleno. Devuelve la imagen (solo las piernas)"""
	alto, ancho = dibujo.shape[:2]
	sale = np.zeros_like(dibujo)
	sale[m] = dibujo[m]
	hay = dibujo[..., 3] > 0
	azulado = clases(dibujo)[1]
	negro = clases(dibujo)[4]
	lleno = m.copy()
	nuevos = np.zeros_like(m)
	for x in range(ancho):
		filas = np.nonzero(m[:, x])[0]
		# solo las columnas donde la pierna llega alto (muslo o rodilla); encima de la punta de un pie, no
		if filas.size == 0 or filas[0] > py - ALTO_RODILLA:
			continue
		color = None
		for y in filas:   # el primer píxel de vaquero de esa columna
			if azulado[y, x]:
				color = dibujo[y, x]
				break
		if color is None:
			continue
		for y in range(py - CINTURA + 1, filas[-1]):
			if not m[y, x] and hay[y, x]:
				sale[y, x] = color
				lleno[y, x] = True
				nuevos[y, x] = True
		# el borde negro del arma que se quedó pegado a la pierna, justo debajo o encima de lo relleno: también
		for _ in range(2):
			for y in filas:
				if negro[y, x] and not nuevos[y, x] and (nuevos[y - 1, x] or nuevos[min(y + 1, alto - 1), x]):
					sale[y, x] = color
					nuevos[y, x] = True
	# un píxel más a cada lado, si ahí también tapa el arma: el muslo es más ancho que la espinilla de la que sale
	for paso in (1, -1):
		al_lado = np.roll(nuevos, paso, axis=1) & hay & ~lleno
		sale[al_lado] = np.roll(sale, paso, axis=1)[al_lado]
		lleno |= al_lado
		nuevos |= al_lado
	# el canto de lo relleno, de negro (como el borde del dibujo)
	lado = np.zeros_like(m)
	lado[:, 1:] |= ~lleno[:, :-1]
	lado[:, :-1] |= ~lleno[:, 1:]
	sale[nuevos & lado] = (1, 0, 0, 255)
	return sale


def casillas(meta, anim):
	cw, ch = meta["cell"]
	for direccion, i in meta["anims"][anim]["dirs"].items():
		for k in range(i["frames"]):
			yield direccion, k, (i.get("col", 0) + k) * cw, i["row"] * ch


def foto(hoja, salida, meta, anim, ruta):
	"""Para repasar a ojo: arriba cada dibujo con las piernas en rosa; debajo, andando, las piernas que pintará el juego
	(con lo relleno) y, en el golpe, lo que queda al quitarle las piernas"""
	cw, ch = meta["cell"]
	px, py = meta["pivot"]
	x0, y0, x1, y1 = px - 26, py - 24, px + 26, min(ch, py + 8)
	w, h = x1 - x0, y1 - y0
	dirs = list(meta["anims"][anim]["dirs"])
	n = max(i["frames"] for i in meta["anims"][anim]["dirs"].values())
	lienzo = np.zeros((len(dirs) * h * 2, n * w, 4), dtype=np.uint8)
	lienzo[..., :3] = 95
	lienzo[..., 3] = 255
	for direccion, k, cx, cy in casillas(meta, anim):
		d = hoja[cy + y0:cy + y1, cx + x0:cx + x1].astype(float)
		s = salida[cy + y0:cy + y1, cx + x0:cx + x1].astype(float)
		m = s[..., 3] > 0
		fila = dirs.index(direccion) * h * 2
		for parte in (0, 1):
			e = d.copy()
			if parte == 0:
				e[m, :3] = e[m, :3] * 0.35 + np.array([255, 40, 200]) * 0.65
			elif anim == "walk":
				e = s
			else:
				e[m, 3] = 0
			a = e[..., 3:4] / 255.0
			trozo = lienzo[fila + parte * h:fila + (parte + 1) * h, k * w:(k + 1) * w]
			trozo[..., :3] = (e[..., :3] * a + trozo[..., :3] * (1 - a)).astype(np.uint8)
	Image.fromarray(lienzo).resize((n * w * 3, len(dirs) * h * 6), Image.NEAREST).save(ruta)


for arma in pedidas:
	nombre = ARMAS[arma]
	meta = json.load(open(f"assets/sprites/{nombre}.json", encoding="utf-8"))
	hoja = np.array(Image.open(f"assets/sprites/{nombre}.png").convert("RGBA"))
	cw, ch = meta["cell"]
	px, py = meta["pivot"]
	mascara = np.zeros(hoja.shape[:2], dtype=bool)
	salida = np.zeros(hoja.shape, dtype=np.uint8)
	for anim in ("walk", "attack"):
		for direccion, k, cx, cy in casillas(meta, anim):
			dibujo = hoja[cy:cy + ch, cx:cx + cw]
			m = piernas(dibujo, px, py, arma not in SIN_ZAPATOS_SUELTOS, anim == "walk", arma in QUITAR_LO_FINO)
			mascara[cy:cy + ch, cx:cx + cw] = m
			if anim == "walk":
				salida[cy:cy + ch, cx:cx + cw] = rellenar(dibujo, m, py)
			else:
				salida[cy:cy + ch, cx:cx + cw][m] = dibujo[m]
	Image.fromarray(salida).save(f"assets/sprites/{nombre}-piernas.png", optimize=True)
	print(f"{arma}: assets/sprites/{nombre}-piernas.png ({int(mascara.sum())} píxeles de pierna)")
	# Las skins: sus piernas tienen que ser las mismas (solo cambia la cabeza)
	distintas = []
	for ruta in sorted(glob.glob(f"assets/sprites/{nombre}-*.png")):
		if ruta.endswith("-piernas.png") or ruta.endswith("_n.png"):
			continue
		otra = np.array(Image.open(ruta).convert("RGBA"))
		if otra.shape != hoja.shape or (otra[mascara] != hoja[mascara]).any():
			distintas.append(os.path.basename(ruta))
	if distintas:
		print(f"  OJO: estas skins no tienen las mismas piernas: {', '.join(distintas)}")
	if ver:
		os.makedirs("capturas", exist_ok=True)
		foto(hoja, salida, meta, "walk", f"capturas/piernas-{arma}-andar.png")
		foto(hoja, salida, meta, "attack", f"capturas/piernas-{arma}-golpe.png")
