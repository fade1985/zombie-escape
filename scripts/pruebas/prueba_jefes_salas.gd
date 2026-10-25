# Pruebas de las habitaciones de los jefes de los Apartamentos (--porqueria, --gimnasio, --cubos, --llamas, con
# su --jefe) y de ir derecho a ellas (--ir-jefe). Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_comun.gd"


# Con "--captura --jefe gloton --porqueria": la habitación del Glotón (peligros/porqueria.gd): sin muebles y con la
# franja de porquería pegada a las paredes, que quema. Monta su piso (la 1ª planta) con todo descubierto y sin
# que salga él, y cuenta en la terminal: los muebles (ninguno, ni lámparas), cuántas casillas están sucias (parte del suelo), que donde
# aparece Johnny está limpio, que el centro está limpio y lo pegado a las paredes sucio (y cuánto mide la franja), que
# en medio queda una elipse limpia perfecta, como un ring, que sale igual con otra semilla, que la puerta está en el
# centro de la pared y de ella se llega al centro por un paso limpio, recto y holgado, lo que pierde Johnny en 1 s sobre una casilla sucia (unos 7) y que en una limpia,
# pasado el escozor, no pierde nada; las salpicaduras de la pared de arriba, los pegotes de los lomos de las otras y las luces del resplandor. Saca captura-porqueria.png
# (Johnny sobre la porquería) y captura-porqueria-medio.png (desde el medio: la elipse limpia y la franja alrededor)
# y se cierra
func probar_porqueria() -> void:
	set_process(false)
	nueva_planta(2)   # la 1ª planta: con --jefe gloton, la suya
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true   # que no aparezca el Glotón: aquí se prueba la habitación
	await montar(idx, 0, false)
	for sala in sitio.apt.salas:
		mapa.vistas[sala.id] = true   # todo descubierto
		mapa.niebla[sala.id] = 0.0
	mapa.actualizar_niebla(0.0)   # (y la niebla, repintada ya: si no, la foto sale tapada)
	var lista: Array = sitio.get("peligros", []).filter(func(q): return q.tipo == "porqueria")
	if lista.is_empty():
		print("Porquería: el piso del jefe (%s) no tiene porquería (¡mal!)" % planta.jefe)
		get_tree().quit()
		return
	var p: Dictionary = lista[0]
	var sala: Dictionary = sitio.apt.salas[0]
	var total: int = sala.ancho * sala.fondo
	var montones: int = p.casillas.values().count(2)
	print("Porquería (jefe %s): muebles %d (esperado: 0, ni lámparas) · casillas sucias %d de %d (%d %%, esperado: entre 35 y 55) · montones %d · donde aparece Johnny, limpio %s (esperado: true)" % [
		planta.jefe, sitio.muebles.size(), p.casillas.size(), total,
		roundi(100.0 * p.casillas.size() / total), montones, not p.casillas.has(Peligros.casilla(johnny.position))])
	# la franja junto a las paredes y la elipse limpia: el centro limpio, y las casillas pegadas a cada pared sucias (en la
	# de la puerta, a un lado de ella), con la franja de al menos 2 casillas de grosor en sus puntos medios
	var medio := Vector2i(sala.c0 + sala.ancho / 2, sala.f0 + sala.fondo / 2)
	var lado_puerta: int = sala.f0 if sitio.apt.entrada.lado == "arriba" else sala.f0 + sala.fondo - 1
	var puntos := [Vector2i(sala.c0, medio.y), Vector2i(sala.c0 + sala.ancho - 1, medio.y),
		Vector2i(medio.x, sala.f0), Vector2i(medio.x, sala.f0 + sala.fondo - 1)]
	for i in puntos.size():
		if puntos[i].y == lado_puerta:
			# a un lado del acceso limpio de la puerta: al otro lado del centro (el pasillo va de la puerta hacia él)
			puntos[i].x += -7 if sitio.apt.entrada.c + 1 > medio.x else 7
	var sucios := puntos.filter(func(q): return p.casillas.has(q)).size()
	var grosor := 99
	for q in puntos:
		var hacia: Vector2i = (medio - q).sign()
		var n := 0
		var k: Vector2i = q
		while p.casillas.has(k):
			n += 1
			k += hacia
		grosor = mini(grosor, n)
	print("Porquería: el centro limpio %s (esperado: true) · pegado a las paredes, sucio en %d de 4 puntos (esperado: 4) · la franja mide al menos %d casillas de grosor (esperado: 2 o más)" % [
		not p.casillas.has(medio), sucios, grosor])
	# siempre igual: con otra semilla, las mismas casillas sucias (los montones sí cambian)
	var otro: Dictionary = sitio.duplicate()
	otro.surtido = int(sitio.surtido) + 1
	print("Porquería: la elipse limpia del medio, de %.1f × %.1f casillas, es perfecta: casillas que no cuadran %d (esperado: 0) · con otra semilla sale igual %s (esperado: true)" % [
		p.ovalo.rx * 2.0, p.ovalo.ry * 2.0, descuadradas(sitio, p), Peligros.del_gloton(otro)[0].casillas.keys() == p.casillas.keys()])
	# el acceso: la puerta en el centro de la pared y de ella al centro de la sala, recto y sin pisar nada
	print("Porquería: %s · %s · de donde aparece Johnny al centro, sin pisar nada y holgado (3 casillas de ancho como poco) %s (esperado: true)" % [
		puerta_en_medio(sitio), paso_recto(sitio), paso_holgado(sala, p.casillas, Peligros.casilla(johnny.position))])
	# 1 s sobre una casilla sucia rodeada de sucias (que el borde no engañe)
	var sucia := Vector2i(-1, -1)
	for c in p.casillas:
		if sucia == Vector2i(-1, -1) and Peligros.LADOS.all(func(d): return p.casillas.has(c + d)):
			sucia = c
	johnny.vida = johnny.stats.vida_max
	johnny.position = Peligros.centro(sucia)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(1.0).timeout
	print("Porquería: 1 s sobre una casilla sucia, Johnny pierde %d (esperado: entre 5 y 9) · estado «porqueria» %s (esperado: true)" % [
		johnny.stats.vida_max - johnny.vida, johnny.estados.has("porqueria")])
	Captura.foto("captura-porqueria.png")
	# en una limpia (sin sucias alrededor), pasado el escozor de 1 s, ya no pierde nada
	var limpia := Vector2i(-1, -1)
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			var k := Vector2i(c, f)
			if limpia == Vector2i(-1, -1) and not p.casillas.has(k) and Peligros.LADOS.all(func(d): return not p.casillas.has(k + d)):
				limpia = k
	johnny.position = Peligros.centro(limpia)
	await get_tree().create_timer(1.3).timeout
	var antes: int = johnny.vida
	await get_tree().create_timer(1.0).timeout
	var salpicaduras: int = mapa.caras.get(sala.id, []).reduce(func(acc, cara): return acc + cara.adornos.size(), 0)
	print("Porquería: en una casilla limpia, pasado el escozor, pierde %d en 1 s (esperado: 0) · estado «porqueria» %s (esperado: false) · salpicaduras en la pared de arriba %d y pegotes en los lomos de las otras %d (esperado: más de 0 las dos) · luces del resplandor %d (esperado: entre 4 y 8)" % [
		antes - johnny.vida, johnny.estados.has("porqueria"), salpicaduras, p.get("paredes", {}).size(), mapa.get_node("Porqueria").luces.size()])
	print("Porquería: %s (se suma al resplandor)" % await luz_fija_de_jefe())
	# y desde el medio de la zona de pelea, con la cámara alejada: la elipse limpia y la franja sucia alrededor
	johnny.position = Peligros.centro(medio)
	johnny.direccion = "n"
	johnny.get_node("Camara").zoom = Vector2(0.66, 0.66)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-porqueria-medio.png")
	get_tree().quit()


# Con "--captura --jefe gymbro --gimnasio": el gimnasio del Gymbro (catalogo.gd, "jefe-gymbro", muebles.gd, fijos,
# peligros/luz_jefe.gd y peligros/tropiezos.gd). Monta su piso (la 1ª planta) con todo descubierto y sin que salga
# él, y cuenta en la terminal: las máquinas (29) y cuántas de cada tipo hay en cada pared (la derecha, 8 cintas; la
# izquierda, 6 bancos de press y 2 pilas de discos; el fondo, 2 taquillas, 4 pilas de discos, 3 poleas y 4 estantes,
# nada en la de abajo), que ninguna se pisa ni toca un muro, que el fondo es simétrico con una polea justo enfrente de
# la puerta, ninguna lámpara, las luces fijas (5) encendidas, qué parte del suelo queda libre, la puerta en el centro
# de la pared, las mancuernas (12, separadas, lejos de la puerta y de los muebles); que al pasar andando por encima de
# una Johnny se cae, no se mueve ni ataca aunque se le pida, no pierde vida y se levanta a los 2 s, y la mancuerna sale
# rodando; y que rodando (la esquiva) se pasa por encima sin caer. Cada línea dice lo esperado. Saca
# captura-gimnasio.png (la sala entera, con la cámara alejada y sin penumbra), captura-gimnasio-luz.png (lo mismo, con
# la penumbra de siempre: lo que alumbran las luces) y captura-gimnasio-caido.png (Johnny en el suelo con las
# estrellitas) y se cierra
func probar_gimnasio() -> void:
	set_process(false)
	nueva_planta(2)   # la 1ª planta: con --jefe gymbro, la suya
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true   # que no aparezca el Gymbro: aquí se prueba la habitación
	await montar(idx, 0, false)
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true   # todo descubierto
		mapa.niebla[s.id] = 0.0
	var lista: Array = sitio.get("peligros", []).filter(func(q): return q.tipo == "tropiezos")
	if lista.is_empty():
		print("Gimnasio: el piso del jefe (%s) no tiene mancuernas (¡mal!)" % planta.jefe)
		get_tree().quit()
		return
	var datos: Dictionary = lista[0]
	var sala: Dictionary = sitio.apt.salas[0]
	var maquinas := ["treadmill", "benchpress", "cablemachine", "dumbbellrack", "weightplates", "lockers"]
	var de_gimnasio: Array = sitio.muebles.filter(func(m): return m.tipo in maquinas)
	var lamparas: int = sitio.muebles.filter(func(m): return m.tipo == "lamp").size()
	var paredes := {}   # pared -> {tipo -> cuántos}
	var ocupado := 0.0
	for m in sitio.muebles:
		paredes[m.lado] = paredes.get(m.lado, {})
		paredes[m.lado][m.tipo] = paredes[m.lado].get(m.tipo, 0) + 1
		ocupado += m.w * m.h
	var esperadas := {"derecha": {"treadmill": 8}, "izquierda": {"benchpress": 6, "weightplates": 2},
		"arriba": {"lockers": 2, "weightplates": 4, "cablemachine": 3, "dumbbellrack": 4}}
	var suelo: float = sala.ancho * sala.fondo * Peligros.CASILLA * Peligros.CASILLA
	print("Gimnasio (jefe %s): muebles %d (esperado: 29), de gimnasio %d (esperado: 29) · lámparas %d (esperado: 0) · por pared %s (esperado: %s) · suelo libre %d %% (esperado: menos de 92)" % [
		planta.jefe, sitio.muebles.size(), de_gimnasio.size(), lamparas, paredes, "igual" if paredes == esperadas else "OTRO: %s" % esperadas,
		roundi(100.0 * (1.0 - ocupado / suelo))])
	# ni se pisan ni tocan un muro, el fondo es simétrico (y la polea del medio, justo enfrente de la puerta)
	var geo := {"cols": sitio.apt.cols, "filas": sitio.apt.filas, "dueno": sitio.apt.dueno}
	var pisados := 0
	for i in sitio.muebles.size():
		for j in range(i + 1, sitio.muebles.size()):
			if Muebles.hueco(sitio.muebles[i]).intersects(Muebles.hueco(sitio.muebles[j])):
				pisados += 1
	var en_muro: int = sitio.muebles.filter(func(m): return not Muebles.en_suelo(geo, Muebles.hueco(m))).size()
	var fondo: Array = sitio.muebles.filter(func(m): return m.lado == "arriba")
	fondo.sort_custom(func(a, b): return a.x < b.x)
	var medio: float = (sitio.apt.entrada.c + 1) * Peligros.CASILLA
	var simetrico := not fondo.is_empty()
	for i in fondo.size():
		var otro: Dictionary = fondo[fondo.size() - 1 - i]
		simetrico = simetrico and fondo[i].tipo == otro.tipo and absf((fondo[i].x - medio) + (otro.x - medio)) <= 2.0
	print("Gimnasio: muebles que se pisan %d (esperado: 0) · metidos en un muro %d (esperado: 0) · el fondo, simétrico %s (esperado: true) · el del medio %s, en x = %d (esperado: cablemachine, en x = %d)" % [
		pisados, en_muro, simetrico, fondo[fondo.size() / 2].tipo if not fondo.is_empty() else "-",
		roundi(fondo[fondo.size() / 2].x) if not fondo.is_empty() else 0, roundi(medio)])
	print("Gimnasio: %s" % puerta_en_medio(sitio))
	var entrada: Rect2 = Muebles.delante_de({"cols": sitio.apt.cols, "filas": sitio.apt.filas}, sitio.apt.entrada.lado,
		(sitio.apt.entrada.c + 1) * Peligros.CASILLA)
	print("Gimnasio: la puerta, en la pared de %s (esperado: abajo) · muebles delante de la puerta %d (esperado: 0)" % [
		sitio.apt.entrada.lado, sitio.muebles.filter(func(m): return Muebles.hueco(m).intersects(entrada)).size()])
	# y en 40 plantas más, cada una con el piso del jefe detrás de una puerta (y una semilla) distinta: siempre abajo
	# y sin muebles delante
	var malos := 0
	var viejo := Planta.semilla
	for k in 40:
		Planta.semilla = 3000 + k
		var otra: Dictionary = Planta.generar(1 + k % 4, "apartamentos", "gymbro")
		for s in otra.sitios:
			if s.tipo != "jefe":
				continue
			var delante: Rect2 = Muebles.delante_de({"cols": s.apt.cols, "filas": s.apt.filas}, s.apt.entrada.lado,
				(s.apt.entrada.c + 1) * Peligros.CASILLA)
			if s.apt.entrada.lado != "abajo" or s.muebles.size() != 29 or s.muebles.any(func(m): return Muebles.hueco(m).intersects(delante)):
				malos += 1
	Planta.semilla = viejo
	print("Gimnasio: en 40 plantas más, con el piso del jefe en otra puerta, con la puerta en otro sitio o con muebles delante: %d (esperado: 0)" % malos)
	var cerca := 9999.0
	for a in datos.cosas:
		for b in datos.cosas:
			if a != b:
				cerca = minf(cerca, a.pos.distance_to(b.pos))
	print("Gimnasio: mancuernas %d (esperado: 12) · la más cercana a otra, a %d (esperado: 110 o más) · alguna junto a la puerta %s (esperado: false) · alguna junto a un mueble %s (esperado: false) · donde aparece Johnny, sin mancuerna %s (esperado: true)" % [
		datos.cosas.size(), roundi(cerca), datos.cosas.any(func(k): return entrada.grow(60.0).has_point(k.pos)),
		datos.cosas.any(func(k): return sitio.muebles.any(func(m): return Muebles.hueco(m).grow(20.0).has_point(k.pos))),
		datos.cosas.all(func(k): return k.pos.distance_to(johnny.position) > 60.0)])
	# la sala entera, desde el medio y con la cámara alejada
	var camara: Camera2D = johnny.get_node("Camara")
	johnny.position = sala.centro
	johnny.direccion = "s"
	camara.zoom = Vector2(0.66, 0.66)
	camara.reset_smoothing()
	luz.alternar()   # sin penumbra, para que se vea todo
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-gimnasio.png")
	luz.alternar()
	await get_tree().create_timer(0.6).timeout
	print("Gimnasio: %s" % await luz_fija_de_jefe())
	Captura.foto("captura-gimnasio-luz.png")   # con la penumbra de siempre: lo que alumbran las luces
	camara.zoom = Vector2.ONE
	await probar_tropezar("Gimnasio", "una mancuerna", "mancuernas", sitio, datos, "captura-gimnasio-caido.png")
	get_tree().quit()


# Con "--captura --jefe portera --cubos": el cuarto de la limpieza de la portera (catalogo.gd, "jefe-portera"; mapa.gd,
# colgados; peligros/tropiezos.gd). Monta su piso (la 1ª planta) con todo descubierto y sin que salga ella, y cuenta en
# la terminal: cómo se llama la sala, los muebles (contenedores, cubos de basura y carros de limpieza, y 3 lámparas) y en
# qué paredes están, la puerta en el centro de la pared, lo que cuelga de la pared de arriba (fregonas y cubos, nada
# delante de la puerta), los cubos del
# suelo (10, de pie, separados, lejos de la puerta y de los muebles) y el aviso de Johnny al entrar; luego lo mismo que
# en el gimnasio (probar_tropezar), y que el cubo con el que tropieza vuelca. Saca captura-cubos.png (la sala entera,
# con la cámara alejada), captura-cubos-pared.png (la pared de arriba de cerca) y captura-cubos-caido.png (Johnny en
# el suelo junto al cubo volcado) y se cierra
func probar_cubos() -> void:
	set_process(false)
	nueva_planta(2)   # la 1ª planta: con --jefe portera, la suya
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true   # que no aparezca la portera: aquí se prueba la habitación
	await montar(idx, 0, false)
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true   # todo descubierto
		mapa.niebla[s.id] = 0.0
	var lista: Array = sitio.get("peligros", []).filter(func(q): return q.tipo == "tropiezos")
	if lista.is_empty():
		print("Cubos: el piso del jefe (%s) no tiene cubos por el suelo (¡mal!)" % planta.jefe)
		get_tree().quit()
		return
	var datos: Dictionary = lista[0]
	var sala: Dictionary = sitio.apt.salas[0]
	var de_limpieza: Array = sitio.muebles.filter(func(m): return m.tipo in ["wheeliebin", "trashcan", "janitorcart"])
	var lamparas: int = sitio.muebles.filter(func(m): return m.tipo == "lamp").size()
	var tipos := {}
	for m in de_limpieza:
		tipos[m.tipo] = tipos.get(m.tipo, 0) + 1
	var paredes := {}
	for m in sitio.muebles:
		paredes[m.lado] = paredes.get(m.lado, 0) + 1
	print("Cubos (jefe %s): la sala se llama «%s» (esperado: Cuarto de la limpieza) · muebles %d, de limpieza %d %s (esperado: de 8 a 11, con 1 o 2 carros, janitorcart) · lámparas %d (esperado: 3) · otros %d (esperado: 0) · por pared %s (esperado: en 3 o 4)" % [
		planta.jefe, sala.nombre, sitio.muebles.size(), de_limpieza.size(), tipos, lamparas,
		sitio.muebles.size() - de_limpieza.size() - lamparas, paredes])
	# lo que cuelga de la pared de arriba (en unidades del mapa, para mirar la puerta)
	var colgados := []
	for cara in mapa.caras.get(sala.id, []):
		for a in cara.adornos:
			if a.dibujo.resource_path.contains("colgado-"):
				colgados.append({"x": cara.position.x + a.x * 2.0, "w": a.dibujo.get_width() * 2.0,
					"fregona": a.dibujo.resource_path.contains("fregona")})
	var puertas: Array = sitio.salidas.filter(func(s): return s.dir == "arriba").map(func(s): return s.en)
	var fregonas := colgados.filter(func(k): return k.fregona).size()
	print("Cubos: colgados en la pared de arriba %d (esperado: 10 o más): fregonas %d y cubos %d (esperado: más de 0 los dos) · alguno delante de la puerta %s (esperado: false; puertas arriba: %d)" % [
		colgados.size(), fregonas, colgados.size() - fregonas,
		colgados.any(func(k): return puertas.any(func(en): return k.x < en + 32.0 and k.x + k.w > en - 32.0)), puertas.size()])
	print("Cubos: %s" % puerta_en_medio(sitio))
	var entrada: Rect2 = Muebles.delante_de({"cols": sitio.apt.cols, "filas": sitio.apt.filas}, sitio.apt.entrada.lado,
		(sitio.apt.entrada.c + 1) * Peligros.CASILLA)
	var cerca := 9999.0
	for a in datos.cosas:
		for b in datos.cosas:
			if a != b:
				cerca = minf(cerca, a.pos.distance_to(b.pos))
	var colores := {}
	for k in datos.cosas:
		colores[k.color] = colores.get(k.color, 0) + 1
	print("Cubos: en el suelo %d (esperado: 10) · todos cubos y de pie %s (esperado: true) · de qué color %s (esperado: de 2 o 3) · el más cercano a otro, a %d (esperado: 110 o más) · alguno junto a la puerta %s (esperado: false) · alguno junto a un mueble %s (esperado: false) · donde aparece Johnny, sin cubo %s (esperado: true)" % [
		datos.cosas.size(), datos.cosas.all(func(k): return k.forma == "cubo" and k.volcado == 0), colores, roundi(cerca),
		datos.cosas.any(func(k): return entrada.grow(60.0).has_point(k.pos)),
		datos.cosas.any(func(k): return sitio.muebles.any(func(m): return Muebles.hueco(m).grow(20.0).has_point(k.pos))),
		datos.cosas.all(func(k): return k.pos.distance_to(johnny.position) > 60.0)])
	await get_tree().create_timer(0.3).timeout
	print("Cubos: al entrar, Johnny avisa %s (esperado: true) · «%s» (esperado: habla de cubos)" % [
		datos.avisado, mapa.get_node("Tropiezos").aviso])
	# la sala entera, desde el medio y con la cámara alejada
	var camara: Camera2D = johnny.get_node("Camara")
	johnny.position = sala.centro
	johnny.direccion = "s"
	camara.zoom = Vector2(0.66, 0.66)
	camara.reset_smoothing()
	luz.alternar()   # sin penumbra, para que se vea todo
	await get_tree().create_timer(0.6).timeout
	print("Cubos: %s (se suma a las lámparas)" % await luz_fija_de_jefe())
	Captura.foto("captura-cubos.png")
	# y la pared de arriba de cerca, con lo colgado (desde un sitio sin cubos cerca: si no, se caería ya aquí)
	camara.zoom = Vector2.ONE
	var junto_pared := Vector2(sala.centro.x, (sala.f0 + 4) * Peligros.CASILLA)
	for paso in range(0, 640, 32):
		var p := junto_pared + Vector2(paso if paso % 64 == 0 else -paso, 0)
		if datos.cosas.all(func(k): return k.pos.distance_to(p + Vector2(0, 14)) > 80.0) \
				and sitio.muebles.all(func(m): return not Muebles.hueco(m).grow(30.0).has_point(p)):
			junto_pared = p
			break
	johnny.position = junto_pared
	camara.reset_smoothing()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-cubos-pared.png")
	luz.alternar()
	await probar_tropezar("Cubos", "un cubo", "cubos", sitio, datos, "captura-cubos-caido.png")
	get_tree().quit()


# Lo que se prueba igual en el gimnasio y en el cuarto de la limpieza (probar_gimnasio, probar_cubos), con la cosa del
# suelo que toque ("uno": "una mancuerna" o "un cubo"; "varios", en plural): que al pasar andando por encima de una Johnny se cae, no se mueve ni
# ataca aunque se le pida, no pierde vida y se levanta a los 2 s, y la cosa sale rodando (el cubo, volcado); y que
# rodando (la esquiva) se pasa por encima de otra sin caer. Saca la foto "foto" (Johnny en el suelo con las estrellitas)
func probar_tropezar(titulo: String, uno: String, varios: String, sitio: Dictionary, datos: Dictionary, foto: String) -> void:
	var sala: Dictionary = sitio.apt.salas[0]
	var camara: Camera2D = johnny.get_node("Camara")
	# una cosa con sitio libre a los dos lados para pasar por encima (sin muebles ni otras cosas)
	var tropiezos: Node = mapa.get_node("Tropiezos")
	var hueco_para := func(k: Dictionary, dir: Vector2) -> bool:
		for paso in range(-100, 181, 8):
			var p: Vector2 = k.pos + dir * paso
			if absi(paso) > 30 and not Peligros.libre_para_cosas(sitio, sala.id, p, 22.0):
				return false
			for otra in datos.cosas:
				if otra != k and otra.pos.distance_to(p) < 40.0:
					return false
		return true
	# (las más cerca del medio, primero: que en la foto no quede Johnny pegado al borde)
	var orden: Array = datos.cosas.duplicate()
	orden.sort_custom(func(a, b): return a.pos.distance_to(sala.centro) < b.pos.distance_to(sala.centro))
	var buscar := func(menos: Dictionary) -> Array:
		for k in orden:
			if k == menos:
				continue
			for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
				if hueco_para.call(k, dir):
					return [k, dir]
		return []
	var accion := {Vector2.RIGHT: "derecha", Vector2.LEFT: "izquierda", Vector2.DOWN: "abajo", Vector2.UP: "arriba"}
	if johnny.caido_t > 0.0:
		print("%s: Johnny ya estaba en el suelo antes de empezar (¡mal! la prueba no valdría)" % titulo)
		return
	var elegida: Array = buscar.call({})
	if elegida.is_empty():
		print("%s: no hay %s con sitio para pasar por encima (¡mal!)" % [titulo, varios])
		return
	var cosa: Dictionary = elegida[0]
	var dir: Vector2 = elegida[1]
	var antes: Vector2 = cosa.pos
	# andando hacia ella: se cae
	johnny.vida = johnny.stats.vida_max
	johnny.velocity = Vector2.ZERO
	johnny.position = cosa.pos - dir * 90.0 - Vector2(0, tropiezos.PIES)
	camara.reset_smoothing()
	Input.action_press(accion[dir])
	var espera := 0.0
	while johnny.caido_t <= 0.0 and espera < 2.0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	var t0 := Time.get_ticks_msec()
	print("%s: andando hacia %s, se cae %s (esperado: true)" % [titulo, uno, johnny.caido_t > 0.0])
	await get_tree().create_timer(0.4).timeout
	var tumbado := absf(rad_to_deg(johnny.sprite.rotation))
	var quieto: Vector2 = johnny.position
	Input.action_press("atacar")
	camara.reset_smoothing()
	await get_tree().create_timer(0.4).timeout
	Captura.foto(foto)
	await get_tree().create_timer(0.6).timeout
	var volcado := " · volcado %s (esperado: true)" % (cosa.volcado != 0) if cosa.forma == "cubo" else ""
	print("%s: en el suelo, tumbado %d° (esperado: 90) · pidiéndole andar 1 s, se mueve %d (esperado: menos de 5) · atacando %s (esperado: false) · ha salido rodando %d (esperado: entre 30 y 120)%s" % [
		titulo, roundi(tumbado), roundi(johnny.position.distance_to(quieto)), johnny.ataque_t >= 0.0,
		roundi(cosa.pos.distance_to(antes)), volcado])
	Input.action_release("atacar")
	while johnny.caido_t > 0.0 and Time.get_ticks_msec() - t0 < 4000:
		await get_tree().physics_frame
	var dura := (Time.get_ticks_msec() - t0) / 1000.0
	var de_pie: Vector2 = johnny.position
	await get_tree().create_timer(0.4).timeout
	Input.action_release(accion[dir])
	print("%s: se levanta a los %.2f s (esperado: 2,0) · derecho %s (esperado: true) · luego anda %d en 0,4 s (esperado: más de 30) · vida perdida %d (esperado: 0)" % [
		titulo, dura, is_zero_approx(johnny.sprite.rotation), roundi(johnny.position.distance_to(de_pie)),
		johnny.stats.vida_max - johnny.vida])
	# rodando por encima de otra: no se cae
	await get_tree().create_timer(0.8).timeout
	var otra: Array = buscar.call(cosa)
	if otra.is_empty():
		print("%s: no hay más %s con sitio para rodar por encima (¡mal!)" % [titulo, varios])
		return
	johnny.velocity = Vector2.ZERO
	johnny.position = otra[0].pos - otra[1] * 60.0 - Vector2(0, tropiezos.PIES)
	await get_tree().physics_frame
	johnny.esquivar(otra[1])
	await get_tree().create_timer(0.6).timeout
	var pasada: float = (johnny.position + Vector2(0, tropiezos.PIES) - otra[0].pos).dot(otra[1])
	print("%s: rodando por encima de %s, se cae %s (esperado: false) · ha pasado al otro lado %s (esperado: true)" % [
		titulo, uno, johnny.caido_t > 0.0, pasada > 20.0])


# Con "--captura --jefe bombero --llamas": la habitación del jefe de bomberos (catalogo.gd, "jefe-bombero";
# peligros/cerco.gd) y su giro con el lanzallamas (bombero.gd). Monta su piso (la 1ª planta) con todo descubierto y sin
# que salga él, y cuenta en la terminal: cómo se llama la sala, que no tiene muebles, cómo arde (la parte del suelo,
# el centro sin fuego, todo lo pegado a la pared ardiendo menos el acceso de la puerta, en medio una elipse limpia
# perfecta, como un ring, que sale igual con otra semilla, la puerta en el centro de la pared y de ella al centro un
# paso sin fuego, recto y holgado, y sitio de sobra para el giro en el medio), el aviso de
# Johnny al entrar, las luces del fuego y lo que quema quedarse 1 s en el fuego.
# Luego mete al bombero en el medio y le hace girar (vuelta_de_giro), con Johnny moviéndose como con el mando: el
# sentido sale a cada lado; el cono se abre 40 grados; llega hasta la pared en todo su ancho; corriendo delante de él,
# en su sentido, Johnny no se quema; en contra, sí; rodando a través de él, también; su burbuja de fuego
# (burbuja_de_fuego): girando, nada le quita vida, y en el aviso y acabado el giro, sí; y enfadado, corriendo por el
# hueco entre los dos conos a su paso, no. Al final, sus bolas de fuego y sus molotovs, enfadado (bolas_y_molotovs).
# Cada línea dice lo esperado. Saca captura-llamas.png (la sala entera ardiendo, con la cámara alejada),
# captura-llamas-aviso.png (el cono rojo y las flechas del aviso), captura-llamas-giro.png (Johnny corriendo delante
# del cono), captura-llamas-burbuja.png (la burbuja de cerca, brillando donde le da una bala) y
# captura-llamas-enfadado.png (los dos conos) y captura-llamas-bolas.png (el abanico de bolas y los molotovs) y se
# cierra
func probar_llamas() -> void:
	set_process(false)
	nueva_planta(2)   # la 1ª planta: con --jefe bombero, la suya
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true   # que no aparezca solo: se le mete a mano cuando toca
	await montar(idx, 0, false)
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true   # todo descubierto
		mapa.niebla[s.id] = 0.0
	mapa.actualizar_niebla(0.0)   # (y la niebla, repintada ya: si no, la foto sale tapada)
	var lista: Array = sitio.get("peligros", []).filter(func(q): return q.tipo == "cerco")
	if lista.is_empty():
		print("Llamas: el piso del jefe (%s) no tiene el borde en llamas (¡mal!)" % planta.jefe)
		get_tree().quit()
		return
	var cerco: Dictionary = lista[0]
	var apt: Dictionary = sitio.apt
	var sala: Dictionary = apt.salas[0]
	var total: int = sala.ancho * sala.fondo
	# la parte del suelo que arde, el centro sin fuego y, contadas aquí por su cuenta, las casillas pegadas a la pared
	# (menos el acceso limpio de la puerta, el de Peligros.franja_y_ovalo) y las de delante de la puerta (las de sus 2
	# casillas y una más a cada lado, en las 2 filas de esa pared)
	var limpio := Peligros.acceso(apt)
	var en: float = (apt.entrada.c + 1) * Peligros.CASILLA
	var pegadas := 0
	var pegadas_arden := 0
	var puerta := 0
	var puerta_arde := 0
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			var k := Vector2i(c, f)
			var en_hueco := limpio.has(k)
			var lejos: int = mini(mini(c - sala.c0, sala.c0 + sala.ancho - 1 - c), mini(f - sala.f0, sala.f0 + sala.fondo - 1 - f))
			var pared_puerta: int = sala.f0 + sala.fondo - 1 - f if apt.entrada.lado == "abajo" else f - sala.f0
			if pared_puerta < 2 and absf((c + 0.5) * Peligros.CASILLA - en) < 64.0:
				puerta += 1
				puerta_arde += 1 if cerco.casillas.has(k) else 0
			if lejos == 0 and not en_hueco:
				pegadas += 1
				pegadas_arden += 1 if cerco.casillas.has(k) else 0
	var medio := Vector2i(sala.c0 + sala.ancho / 2, sala.f0 + sala.fondo / 2)
	print("Llamas (jefe %s): la sala se llama «%s» (esperado: Apartamento en llamas) · muebles %d (esperado: 0) · arden %d de %d casillas (%d %%, esperado: entre 35 y 55, como la porquería) · el centro sin fuego %s (esperado: true) · pegadas a la pared arden %d de %d (esperado: todas) · delante de la puerta arden %d de %d (esperado: 0 de 8) · donde aparece Johnny, sin fuego %s (esperado: true)" % [
		planta.jefe, sala.nombre, sitio.muebles.size(), cerco.casillas.size(), total, roundi(100.0 * cerco.casillas.size() / total),
		not cerco.casillas.has(medio), pegadas_arden, pegadas, puerta_arde, puerta, not cerco.casillas.has(Peligros.casilla(johnny.position))])
	# siempre igual: con otra semilla, las mismas casillas
	var otro: Dictionary = sitio.duplicate()
	otro.surtido = int(sitio.surtido) + 1
	print("Llamas: la elipse limpia del medio, de %.1f × %.1f casillas, es perfecta: casillas que no cuadran %d (esperado: 0) · con otra semilla sale igual %s (esperado: true)" % [
		cerco.ovalo.rx * 2.0, cerco.ovalo.ry * 2.0, descuadradas(sitio, cerco), Peligros.del_bombero(otro)[0].casillas == cerco.casillas])
	# el acceso: la puerta en el centro de la pared y de ella al centro de la sala, recto y sin pisar el fuego
	print("Llamas: %s · %s · de donde aparece Johnny al centro, sin pisar el fuego y holgado (3 casillas de ancho como poco) %s (esperado: true)" % [
		puerta_en_medio(sitio), paso_recto(sitio), paso_holgado(sala, cerco.casillas, Peligros.casilla(johnny.position))])
	await get_tree().create_timer(0.3).timeout
	var nodo: Node = mapa.get_node("Cerco")
	print("Llamas: al entrar, Johnny avisa %s (esperado: true) · luces del fuego %d (esperado: entre 8 y 10)" % [
		cerco.avisado, nodo.luces.size()])
	print("Llamas: %s (se suma al fuego)" % await luz_fija_de_jefe())
	# lo más cerca que llega el fuego del medio de la sala (donde gira el bombero): Johnny corre a unas 6 casillas de él
	var centro: Vector2 = mapa.centro_libre()   # (ya con el mapa de navegación listo)
	var hueco_giro := INF
	for k in cerco.casillas:
		var caja := Rect2(Vector2(k) * Peligros.CASILLA, Vector2.ONE * Peligros.CASILLA)
		hueco_giro = minf(hueco_giro, centro.distance_to(centro.clamp(caja.position, caja.end)))
	print("Llamas: el fuego, a %d del medio de la sala como poco (esperado: más de 250, que deja sitio para correr el giro a 190-210)" % roundi(hueco_giro))
	# la sala entera, desde el medio y con la cámara alejada (con su luz de verdad: solo la del fuego)
	var camara: Camera2D = johnny.get_node("Camara")
	johnny.position = centro + Vector2(0, 120)
	johnny.direccion = "n"
	camara.zoom = Vector2(0.66, 0.66)
	camara.reset_smoothing()
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-llamas.png")
	# 1 s en el fuego, en el medio del borde de la izquierda; y luego en el medio, pasado el ardor, nada
	johnny.vida = johnny.stats.vida_max
	johnny.position = Peligros.centro(Vector2i(sala.c0, sala.f0 + sala.fondo / 2))
	await get_tree().create_timer(1.0).timeout
	print("Llamas: 1 s en el fuego del borde, Johnny pierde %d (esperado: entre 10 y 14) · ardiendo %s (esperado: true)" % [
		johnny.stats.vida_max - johnny.vida, johnny.estados.has("fuego")])
	johnny.position = centro + Vector2(0, 120)
	await get_tree().create_timer(2.3).timeout
	var antes: int = johnny.vida
	await get_tree().create_timer(1.0).timeout
	print("Llamas: en el medio, pasado el ardor, pierde %d en 1 s (esperado: 0) · ardiendo %s (esperado: false)" % [
		antes - johnny.vida, johnny.estados.has("fuego")])
	# el bombero, en el medio; que nadie le dispare (ni Johnny solo, ni los que le acompañan)
	johnny.modo = "quieto"
	for a in get_tree().get_nodes_in_group("aliados"):
		a.process_mode = Node.PROCESS_MODE_DISABLED
	var jefe: Node2D = meter_zombi("bombero", centro)
	await get_tree().create_timer(0.3).timeout
	var lados := {1.0: 0, -1.0: 0}
	for i in 40:
		jefe.avisar_giro(johnny)
		lados[jefe.datos.sentido] += 1
	print("Llamas: el sentido del giro, en 40 avisos: %d como las agujas del reloj y %d al revés (esperado: más de 5 los dos)" % [
		lados[1.0], lados[-1.0]])
	# lo abierto que es el cono: 40 grados (20 a cada lado del medio), a 200 del jefe (la lengua de antes, solo unos 8)
	var cerca := func(grados: float) -> bool:
		return jefe.en_cono(jefe.global_position + Vector2.from_angle(deg_to_rad(grados)) * 200.0, 0.0, 0.0)
	print("Llamas: el cono se abre %d grados (esperado: 40): a 200 del jefe, pilla lo que está a 17 grados del medio %s (esperado: true) y no lo que está a 23 %s (esperado: true)" % [
		roundi(rad_to_deg(jefe.ABERTURA * 2.0)), cerca.call(17.0), not cerca.call(23.0)])
	jefe.andar(5.0)
	var con := await vuelta_de_giro(jefe, centro, "con", 1.0, PI / 2.0, 190.0, "captura-llamas-aviso.png", "captura-llamas-giro.png")
	print("Llamas: el cono llega a la pared en todo su ancho: por el medio, entre %d y %d de largo, y lo más que se queda un rayo de la pared, de borde a borde, %d (esperado: 2 o menos)" % [
		roundi(con.largo[0]), roundi(con.largo[1]), roundi(con.pared)])
	print("Llamas: corriendo delante del cono, en su sentido (a %d-%d del jefe), Johnny pierde %d (esperado: 0) · arde %s (esperado: false)" % [
		roundi(con.radio[0]), roundi(con.radio[1]), con.vida, con.arde])
	var contra := await vuelta_de_giro(jefe, centro, "contra", -1.0, PI / 2.0, 190.0)
	print("Llamas: corriendo en contra (a %d-%d del jefe), Johnny pierde %d (esperado: más de 0) · arde %s (esperado: true)" % [
		roundi(contra.radio[0]), roundi(contra.radio[1]), contra.vida, contra.arde])
	var rodar := await vuelta_de_giro(jefe, centro, "rodar", 1.0, 0.0, 190.0)
	print("Llamas: rodando a través del cono, Johnny rueda %s (esperado: true) · pierde %d (esperado: más de 0) · arde %s (esperado: true)" % [
		rodar.rodado, rodar.vida, rodar.arde])
	await burbuja_de_fuego(jefe, centro)
	# enfadado: dos conos opuestos (Johnny, lejos del empujón del grito y a un lado, donde la elipse limpia es más ancha)
	johnny.position = centro + Vector2(300, 0)
	jefe.fase = 2
	jefe.al_enfadarse(johnny)
	await get_tree().create_timer(0.5).timeout
	var entre := await vuelta_de_giro(jefe, centro, "entre", -1.0, PI / 2.0, 210.0, "", "captura-llamas-enfadado.png")
	print("Llamas: enfadado, corriendo por el hueco entre los dos conos, a su paso (a %d-%d del jefe), Johnny pierde %d (esperado: 0) · arde %s (esperado: false) · conos %d (esperado: 2)" % [
		roundi(entre.radio[0]), roundi(entre.radio[1]), entre.vida, entre.arde, entre.conos])
	await bolas_y_molotovs(jefe, centro)
	get_tree().quit()


# Las bolas de fuego y los molotovs del bombero ("jefe", ya enfadado, puesto en "centro"; bombero.gd), con Johnny
# quieto a un lado: 5 bolas en abanico (de 15 grados en 15) y 3 molotovs en fila, separados para no caer unos encima de
# otros. Saca captura-llamas-bolas.png (el abanico de bolas volando y los molotovs con sus marcas rojas)
func bolas_y_molotovs(jefe: Node2D, centro: Vector2) -> void:
	jefe.andar(5.0)
	jefe.position = centro
	jefe.marcha = Vector2.ZERO
	johnny.position = centro + Vector2(300, 0)
	johnny.velocity = Vector2.ZERO
	johnny.vida = johnny.stats.vida_max
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(0.8, 0.8)
	camara.reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	jefe.mirada = (johnny.position - jefe.position).normalized()
	jefe.lanzar_bolas(johnny)
	jefe.lanzar_molotovs(johnny)
	var bolas: Array = get_tree().get_nodes_in_group("balas_zombi").filter(func(n): return n is BolaFuego)
	var abanico := 0.0
	for b in bolas:
		abanico = maxf(abanico, absf(angle_difference(jefe.mirada.angle(), b.velocidad.angle())))
	var caen: Array = jefe.get_parent().get_children().filter(func(n): return n.get("tipo") == "molotov_jefe").map(
		func(n): return n.hasta)
	var separados := INF
	for i in caen.size():
		for j in range(i + 1, caen.size()):
			separados = minf(separados, caen[i].distance_to(caen[j]))
	print("Llamas: enfadado, bolas de fuego %d (esperado: 5) en abanico de %d grados de punta a punta (esperado: 60) · molotovs %d (esperado: 3), separados %d como poco (esperado: 100 o más)" % [
		bolas.size(), roundi(rad_to_deg(abanico * 2.0)), caen.size(), roundi(separados)])
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-llamas-bolas.png")


# Con "--captura --ir-jefe": desde la sala de mantenimiento, pulsa Mayús + la tecla de cada minijefe de los
# Apartamentos (SALAS_JEFE e ir_al_jefe, partida.gd; la última, el jefe de bomberos) y cuenta en la terminal, de cada
# uno: que está en la planta que le tocó en el sorteo, que Johnny está en la habitación del jefe, junto a la puerta, y
# que el jefe que ha salido es ese. Saca captura-ir-jefe.png (el jefe de bomberos en su habitación en llamas) y se
# cierra
func probar_ir_jefe() -> void:
	var teclas: Array = SALAS_JEFE.keys()
	teclas.erase(KEY_9)
	teclas.append(KEY_9)   # (el jefe de bomberos, el último: el de la foto)
	for tecla in teclas:
		var tipo: String = SALAS_JEFE[tecla]
		johnny.vida = johnny.stats.vida_max
		for pulsada in [true, false]:
			var evento := InputEventKey.new()
			evento.keycode = tecla
			evento.shift_pressed = true
			evento.pressed = pulsada
			Input.parse_input_event(evento)
		# hasta que empieza a cambiar de sitio (mientras se funde a negro, "jefa" aún es el de antes) y luego, hasta que
		# sale el jefe (en la prueba, sin presentación)
		var espera := 0.0
		while not cambiando and espera < 1.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
		while (cambiando or not is_instance_valid(jefa)) and espera < 6.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
		var sitio: Dictionary = planta.sitios[aqui]
		print("Ir al jefe (Mayús + %s): a la %s, la suya del sorteo %s (esperado: true) · en la habitación del jefe %s (esperado: true) · Johnny, a %d de la puerta (esperado: menos de 100) · ha salido %s (esperado: %s)" % [
			OS.get_keycode_string(tecla), planta.nombre, planta.num == orden_jefes.find(tipo) + 1, sitio.tipo == "jefe",
			roundi(johnny.position.distance_to(mapa.puertas[0].llegada())),
			jefa.scene_file_path.get_file().get_basename() if is_instance_valid(jefa) else "nadie", ZOMBIS[tipo].resource_path.get_file().get_basename()])
	await get_tree().create_timer(1.0).timeout
	Captura.foto("captura-ir-jefe.png")
	get_tree().quit()


# Las casillas de la habitación del jefe que no cuadran con una elipse perfecta, la de "datos.ovalo" (la porquería del
# Glotón y el cerco de fuego del bombero, de Peligros.franja_y_ovalo): fuera de ella tiene que estar todo cubierto,
# menos el acceso limpio de la puerta (Peligros.acceso: el hueco de delante y el pasillo hacia el centro), y dentro,
# nada (sin ondas ni manchas sueltas)
func descuadradas(sitio: Dictionary, datos: Dictionary) -> int:
	var apt: Dictionary = sitio.apt
	var sala: Dictionary = apt.salas[0]
	var limpio := Peligros.acceso(apt)
	var ov: Dictionary = datos.ovalo
	var n := 0
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			var k := Vector2i(c, f)
			var fuera: bool = Vector2((c + 0.5 - ov.centro.x) / ov.rx, (f + 0.5 - ov.centro.y) / ov.ry).length() > 1.0
			if datos.casillas.has(k) != (fuera and not limpio.has(k) and Peligros.dueno(apt, c, f) == sala.id):
				n += 1
	return n


# La luz fija de la habitación del jefe de los Apartamentos (peligros/luz_jefe.gd): cuántas luces tiene y cuántas están
# encendidas, con lo esperado (espera un momento a que se enciendan)
func luz_fija_de_jefe() -> String:
	await get_tree().create_timer(0.1).timeout
	var nodos: Array = mapa.peligros.filter(func(p): return p.datos.tipo == "luz_jefe")
	if nodos.is_empty():
		return "luz fija: ninguna (esperado: %d luces blancas, ¡mal!)" % Peligros.LUZ_JEFE.luces.size()
	var luces: Array = nodos[0].luces
	return "luz fija: %d luces (esperado: %d), encendidas %d (esperado: todas)" % [luces.size(), Peligros.LUZ_JEFE.luces.size(),
		luces.filter(func(l): return l.energy > 0.0).size()]


# La puerta de entrada de la habitación del jefe, en el centro de su pared (Apartamento.probar). Devuelve el trozo de
# línea que lo cuenta, con lo esperado
func puerta_en_medio(sitio: Dictionary) -> String:
	var apt: Dictionary = sitio.apt
	var en: int = (apt.entrada.c + 1) * Peligros.CASILLA
	var medio: int = apt.cols * Peligros.CASILLA / 2
	return "la puerta, en x %d, en el centro de la pared (x %d) %s (esperado: true)" % [en, medio, en == medio]


# El acceso limpio de la habitación del jefe (Peligros.acceso, el de la porquería del Glotón y el del cerco de fuego del
# bombero), recto: de la puerta al centro de la sala por las mismas columnas a un lado y a otro de la puerta (torcido,
# sobraría por un lado). Devuelve el trozo de línea que lo cuenta, con lo esperado
func paso_recto(sitio: Dictionary) -> String:
	var apt: Dictionary = sitio.apt
	var columnas := {}
	for k in Peligros.acceso(apt):
		columnas[k.x] = true
	var de: int = columnas.keys().min()
	var a: int = columnas.keys().max()
	var en: int = (apt.entrada.c + 1) * Peligros.CASILLA
	return "el paso limpio va recto, de la columna %d a la %d, lo mismo a cada lado de la puerta %s (esperado: true)" % [
		de, a, (de + a + 1) * Peligros.CASILLA == 2 * en]


# ¿Se va de "desde" al centro de la habitación del jefe ("sala") sin pisar "casillas", y holgado? Por casillas de la
# sala con las 8 de alrededor también limpias (los muros no cuentan): un paso de 3 casillas de ancho como poco, no un
# hueco por el que apenas se cuela
func paso_holgado(sala: Dictionary, casillas: Dictionary, desde: Vector2i) -> bool:
	var pasa := {}
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			var k := Vector2i(c, f)
			var libre := true
			for df in range(-1, 2):
				for dc in range(-1, 2):
					if casillas.has(k + Vector2i(dc, df)):
						libre = false
			if libre:
				pasa[k] = true
	return not Peligros.camino(pasa, desde, Vector2i(sala.c0 + sala.ancho / 2, sala.f0 + sala.fondo / 2)).is_empty()


# Una vuelta del giro del bombero ("jefe", puesto en "centro"), con Johnny a "radio" de él, hacia "desde" (ángulo), y
# girando hacia "sentido" (1, como las agujas del reloj). "como" dice qué hace Johnny, moviéndose como con el mando:
# "con" (corre delante del cono, en su sentido), "contra" (corre en contra), "rodar" (quieto, con el medio del cono
# empezando 1,2 rad por detrás de él, y cuando le va a llegar el borde rueda a través de él) o "entre" (enfadado: en el
# aviso corre en el sentido del giro y luego va por el hueco entre los dos conos, a su paso: si se le acerca el de
# detrás, se arrima al jefe, que así da la vuelta antes; si se le acerca el de delante, se aleja). Saca "foto_aviso" en
# el aviso y "foto_giro" a los 2,5 s de girar. Devuelve {vida (la que pierde), arde (si ha llegado a arder), radio
# ([mín, máx] de lo lejos que ha ido del jefe), largo ([mín, máx] del primer cono, por el medio), pared (lo más que se
# ha quedado de la pared un cono, por el medio o cualquiera de sus rayos), conos, rodado}. Si le quema, acaba un poco
# después
func vuelta_de_giro(jefe: Node2D, centro: Vector2, como: String, sentido: float, desde: float, radio: float,
		foto_aviso := "", foto_giro := "") -> Dictionary:
	var sala: Dictionary = mapa.sitio.apt.salas[0]
	var cas := float(Peligros.CASILLA)
	var caja := Rect2(sala.c0 * cas, sala.f0 * cas, sala.ancho * cas, sala.fondo * cas)   # las paredes de la sala
	var hasta_caja := func(p: Vector2, dir: Vector2) -> float:
		var tx := INF if absf(dir.x) < 0.0001 else ((caja.end.x if dir.x > 0.0 else caja.position.x) - p.x) / dir.x
		var ty := INF if absf(dir.y) < 0.0001 else ((caja.end.y if dir.y > 0.0 else caja.position.y) - p.y) / dir.y
		return minf(tx, ty)
	jefe.position = centro
	jefe.marcha = Vector2.ZERO
	johnny.position = centro + Vector2.from_angle(desde) * radio
	johnny.velocity = Vector2.ZERO
	johnny.tercios = 3
	johnny.vida = johnny.stats.vida_max
	johnny.estados.clear()
	johnny.pisando.clear()
	johnny.invulnerable = 0.0
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(0.66, 0.66)
	camara.reset_smoothing()
	await get_tree().physics_frame
	jefe.avisar_giro(johnny, sentido)
	if como == "rodar":
		jefe.datos.angulo = desde - sentido * 1.2
	var r := {"vida": 0, "arde": false, "radio": [INF, 0.0], "largo": [INF, 0.0], "pared": 0.0, "conos": 0, "rodado": false}
	var vida0: int = johnny.vida
	var fotos := {"aviso": foto_aviso == "", "giro": foto_giro == ""}   # (las que ya están o no hacen falta)
	var quemado := -1.0
	var espera := 0.0
	while jefe.estado in ["aviso_giro", "giro"] and espera < 10.0:
		var d: Vector2 = johnny.global_position - jefe.global_position
		var lejos := d.length()
		var fuera := d / lejos
		var hacia := Vector2.from_angle(d.angle() + PI / 2.0 * sentido)   # por donde va el cono
		var pedido := Vector2.ZERO
		match como:
			"con":
				pedido = hacia + fuera * clampf((radio - lejos) / 40.0, -1.0, 1.0)
			"contra":
				pedido = -hacia + fuera * clampf((radio - lejos) / 40.0, -1.0, 1.0)
			"entre":
				var meta := radio
				if jefe.estado == "giro":
					# lo que le lleva al medio del cono de detrás (de 0 a PI): lo mejor, PI / 2, en medio de los dos
					var va := fposmod((d.angle() - jefe.datos.angulo) * sentido, PI)
					meta = clampf(radio + (va - PI / 2.0) * 120.0, 110.0, 300.0)
				pedido = hacia + fuera * clampf((meta - lejos) / 40.0, -1.0, 1.0)
			"rodar":
				var falta := fposmod((d.angle() - jefe.datos.angulo) * sentido, TAU)   # lo que le falta al medio del cono para llegarle
				if jefe.estado == "giro" and not r.rodado and falta < jefe.ABERTURA + 0.12:   # (ya le llega el borde)
					r.rodado = true
					johnny.esquiva_espera = 0.0
					johnny.esquivar(-hacia)
		pedir_andar(pedido.normalized() if pedido != Vector2.ZERO else Vector2.ZERO)
		if jefe.estado == "giro":
			r.radio = [minf(r.radio[0], lejos), maxf(r.radio[1], lejos)]
			r.conos = jefe.datos.largos.size()
			var pies: Vector2 = jefe.global_position + Vector2(0, jefe.PIE - 6)
			for i in jefe.datos.largos.size():
				var a: float = jefe.datos.angulo + i * TAU / jefe.datos.largos.size()
				var largo: float = jefe.datos.largos[i]
				r.pared = maxf(r.pared, absf(largo - hasta_caja.call(jefe.global_position, Vector2.from_angle(a))))
				if i == 0:
					r.largo = [minf(r.largo[0], largo), maxf(r.largo[1], largo)]
				# y cada rayo del cono, de borde a borde (desde sus pies, hasta donde se dibuja)
				for j in jefe.RAYOS + 1:
					var dir := Vector2.from_angle(jefe.angulo_rayo(a, j))
					r.pared = maxf(r.pared, absf(float(jefe.datos.puntas[i][j]) - hasta_caja.call(pies, dir)))
		r.arde = r.arde or johnny.estados.has("fuego")
		if quemado < 0.0 and johnny.vida < vida0:
			quemado = espera
		if not fotos.aviso and jefe.estado == "aviso_giro" and jefe.t >= 0.7:
			fotos.aviso = true
			Captura.foto(foto_aviso)
		if not fotos.giro and jefe.estado == "giro" and jefe.t >= 2.5:
			fotos.giro = true
			Captura.foto(foto_giro)
		if quemado >= 0.0 and espera > quemado + 0.4:
			break   # ya le ha quemado
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	pedir_andar(Vector2.ZERO)
	r.vida = vida0 - johnny.vida
	jefe.andar(5.0)   # que pare de girar (y no ataque hasta la siguiente)
	return r


# La burbuja de fuego del bombero ("jefe", puesto en "centro"; bombero.gd), con Johnny cerca y el cono empezando
# lejos de él. En el aviso del giro aún no la tiene: un golpe de 10 le quita 10. Girando, la tiene: ni un golpe de 10,
# ni una explosión de 40 (que tampoco le corta el giro), ni una bala de 10 le quitan vida, y la burbuja brilla donde
# le da la bala (captura-llamas-burbuja.png, de cerca). Acabado el giro, un golpe de 10 vuelve a quitarle 10 y la
# burbuja baja
func burbuja_de_fuego(jefe: Node2D, centro: Vector2) -> void:
	await get_tree().create_timer(0.5).timeout   # (que acabe de bajar la burbuja de la vuelta de antes)
	jefe.position = centro
	jefe.marcha = Vector2.ZERO
	johnny.position = centro + Vector2(-130, 70)
	johnny.velocity = Vector2.ZERO
	johnny.vida = johnny.stats.vida_max
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(1.25, 1.25)
	camara.reset_smoothing()
	await get_tree().physics_frame
	jefe.avisar_giro(johnny, 1.0)
	jefe.datos.angulo += PI   # (el cono, al otro lado: tarda unos 2,7 s en llegarle a Johnny)
	await get_tree().create_timer(0.3).timeout
	var antes: int = jefe.vida
	jefe.recibir_golpe(10, Vector2.RIGHT * 300.0)
	var aviso := [jefe.burbuja == 0.0, antes - jefe.vida]
	var espera := 0.0
	while jefe.estado == "aviso_giro" and espera < 3.0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	await get_tree().create_timer(0.5).timeout   # (ya subida)
	var girando: bool = jefe.estado == "giro"
	var subida: bool = jefe.burbuja >= 1.0
	antes = jefe.vida
	jefe.recibir_golpe(10, Vector2.RIGHT * 300.0)
	var explosion: Node2D = load("res://escenas/armas/explosion.tscn").instantiate()
	explosion.dano = 40
	explosion.position = jefe.position + Vector2(50, 0)
	jefe.get_parent().add_child(explosion)
	await get_tree().create_timer(0.2).timeout
	var sigue: bool = jefe.estado == "giro"
	espera = 0.0
	while is_instance_valid(explosion) and espera < 1.5:   # (que no tape la burbuja en la foto)
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	Temblor.desplazamiento = jefe.position + Vector2(0, -50) - johnny.position   # la foto, con el jefe en medio
	var bala: Node2D = load("res://escenas/armas/bala.tscn").instantiate()
	bala.velocidad = johnny.position.direction_to(jefe.position) * 900.0
	bala.dano = 10
	bala.vida = 1.0
	jefe.get_parent().add_child(bala)
	bala.global_position = johnny.position
	espera = 0.0
	while is_instance_valid(bala) and espera < 1.0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	var brilla: bool = jefe.destello > 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	Captura.foto("captura-llamas-burbuja.png")
	Temblor.desplazamiento = Vector2.ZERO
	var girando_quita: int = antes - jefe.vida
	jefe.andar(5.0)   # se acaba el giro
	await get_tree().physics_frame
	await get_tree().physics_frame
	antes = jefe.vida
	jefe.recibir_golpe(10, Vector2.RIGHT * 300.0)
	var fuera_quita: int = antes - jefe.vida
	await get_tree().create_timer(0.5).timeout
	print("Llamas: la burbuja de fuego, en el aviso aún no está %s (esperado: true) y un golpe de 10 le quita %d (esperado: 10) · girando está %s (esperado: true) y un golpe de 10, una explosión de 40 y una bala de 10 le quitan %d (esperado: 0) · la explosión no le corta el giro %s (esperado: true) · brilla donde le da la bala %s (esperado: true) · acabado el giro, un golpe de 10 le quita %d (esperado: 10) y la burbuja baja %s (esperado: true)" % [
		aviso[0], aviso[1], girando and subida, girando_quita, sigue, brilla, fuera_quita, jefe.burbuja == 0.0])


# Pide andar hacia "dir" como con el stick del mando (cada tecla con su fuerza); Vector2.ZERO, nada
func pedir_andar(dir: Vector2) -> void:
	for par in [["derecha", dir.x], ["izquierda", -dir.x], ["abajo", dir.y], ["arriba", -dir.y]]:
		if par[1] > 0.01:
			Input.action_press(par[0], par[1])
		else:
			Input.action_release(par[0])


# Con "--captura --jefe portera --gotas": el abanico de agua sucia de la portera (bala_zombi.gd) en su cuarto de la
# limpieza, con Johnny quieto delante. Cuenta las gotas y las salpicaduras (salpicadura.gd) y que se secan solas.
# Saca captura-gotas.png (las gotas volando), captura-gotas-salpica.png (la que le da a Johnny) y
# captura-gotas-pared.png (de lejos), captura-gotas-cerca.png (tres salpicaduras de cerca, con su mancha) y, ya
# enfadada, captura-gotas-roja.png (el agua rojiza), captura-gotas-polvo.png (el polvo del giro) y el vapor de la
# cabeza: captura-gotas-vapor-grito.png (el chorro al enfadarse) y captura-gotas-vapor.png (las bocanadas). Se cierra
func probar_gotas() -> void:
	set_process(false)
	nueva_planta(2)   # la 1ª planta: con --jefe portera, la suya
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true   # que no aparezca sola: se la mete a mano
	await montar(idx, 0, false)
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true   # todo descubierto
		mapa.niebla[s.id] = 0.0
	mapa.actualizar_niebla(0.0)
	luz.alternar()   # sin penumbra, para que se vea todo
	var centro: Vector2 = sitio.apt.salas[0].centro
	johnny.modo = "quieto"
	johnny.position = centro + Vector2(230, 0)
	johnny.velocity = Vector2.ZERO
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(1.0, 1.0)
	camara.reset_smoothing()
	var jefa: Node2D = meter_zombi("portera", centro - Vector2(60, 0))
	await get_tree().create_timer(0.3, false).timeout
	jefa.position = centro - Vector2(60, 0)
	johnny.position = centro + Vector2(230, 0)
	camara.reset_smoothing()
	print("Gotas: Johnny en %s, la portera en %s, centro %s" % [johnny.position, jefa.position, centro])
	jefa.cambiar("aviso_abanico")
	jefa.t = jefa.AVISO_ABANICO - 0.02
	await get_tree().create_timer(0.32, false).timeout
	print("Gotas: volando %d (esperado: 7 o más)" % get_tree().get_nodes_in_group("balas_zombi").size())
	Captura.foto("captura-gotas.png")
	await get_tree().create_timer(0.75, false).timeout
	print("Gotas: salpicaduras %d (esperado: varias)" % get_tree().get_nodes_in_group("salpicaduras").size())
	Captura.foto("captura-gotas-salpica.png")
	jefa.process_mode = Node.PROCESS_MODE_DISABLED
	camara.zoom = Vector2(0.7, 0.7)
	camara.reset_smoothing()
	await get_tree().create_timer(0.9, false).timeout
	Captura.foto("captura-gotas-pared.png")
	# de cerca: tres salpicaduras junto a Johnny, una recién chocada, otra cayendo y otra ya en el suelo
	camara.zoom = Vector2(2.0, 2.0)
	camara.reset_smoothing()
	for i in 3:
		Salpicadura.lanzar(mapa.cosas, johnny.position + Vector2(-90 + i * 70, 50), Vector2(1, -0.3), BalaZombi.AGUA)
		await get_tree().create_timer(0.15, false).timeout
	Captura.foto("captura-gotas-cerca.png")
	await get_tree().create_timer(8.0, false).timeout   # (la 2ª tanda tarda en llegar a la pared)
	print("Gotas: tras 8 s quedan %d salpicaduras (esperado: 0, se secan)" % get_tree().get_nodes_in_group("salpicaduras").size())
	# enfadada: el abanico, rojizo, y luego el giro, que escupe nubecitas de polvo
	johnny.vida = johnny.stats.vida_max
	jefa.fase = 2
	jefa.process_mode = Node.PROCESS_MODE_INHERIT
	jefa.position = centro - Vector2(60, 0)
	camara.zoom = Vector2(1.0, 1.0)
	camara.reset_smoothing()
	jefa.cambiar("aviso_abanico")
	jefa.t = jefa.AVISO_ABANICO - 0.02
	await get_tree().create_timer(0.32, false).timeout
	var rojas: Array = get_tree().get_nodes_in_group("balas_zombi").filter(func(b): return b.agua == BalaZombi.AGUA_ROJA)
	print("Gotas: enfadada, rojizas %d (esperado: 10 o más)" % rojas.size())
	Captura.foto("captura-gotas-roja.png")
	await get_tree().create_timer(1.5, false).timeout
	johnny.vida = johnny.stats.vida_max
	jefa.position = centro - Vector2(60, 0)
	jefa.cambiar("giro", {"siguiente": 0.0})
	await get_tree().create_timer(0.7, false).timeout
	var polvo: Array = get_tree().get_nodes_in_group("balas_zombi").filter(func(b): return b.forma == "polvo")
	print("Gotas: el giro, nubecitas de polvo %d (esperado: 10 o más)" % polvo.size())
	Captura.foto("captura-gotas-polvo.png")
	# el vapor de la cabeza, de cerca: el chorro de golpe al enfadarse y luego las bocanadas
	for b in get_tree().get_nodes_in_group("balas_zombi"):
		b.queue_free()
	jefa.cambiar("andar")
	jefa.dur = 9.0   # que no ataque mientras tanto
	jefa.process_mode = Node.PROCESS_MODE_DISABLED
	jefa.position = johnny.position + Vector2(-110, 0)
	jefa.process_mode = Node.PROCESS_MODE_INHERIT
	camara.zoom = Vector2(2.0, 2.0)
	camara.reset_smoothing()
	jefa.enfadarse(johnny)
	johnny.position = jefa.position + Vector2(90, -100)   # (más arriba: así la cabeza de ella sale en medio de la foto)
	johnny.velocity = Vector2.ZERO
	camara.reset_smoothing()
	await get_tree().create_timer(0.35, false).timeout
	print("Gotas: vapor al enfadarse, %d nubecitas (esperado: 8 o más)" % jefa.vapor.bocanadas.size())
	Captura.foto("captura-gotas-vapor-grito.png")
	await get_tree().create_timer(1.6, false).timeout
	print("Gotas: vapor andando, %d nubecitas (esperado: de 1 a 6)" % jefa.vapor.bocanadas.size())
	Captura.foto("captura-gotas-vapor.png")
	get_tree().quit()


# Con "--captura --vapor": el vapor de la cabeza (vapor_rabia.gd) de cada minijefe que echa, de uno en uno junto a
# Johnny (que no recibe daño): se le baja la vida a la mitad para que se enfade solo. Cuenta las nubecitas y saca
# captura-vapor-<jefe>-grito.png (el chorro al enfadarse) y captura-vapor-<jefe>.png (las bocanadas) y se cierra
func probar_vapor() -> void:
	set_process(false)
	nueva_planta(2)
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true   # que no aparezca su jefe: se meten a mano
	await montar(idx, 0, false)
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true
		mapa.niebla[s.id] = 0.0
	mapa.actualizar_niebla(0.0)
	luz.alternar()
	var centro: Vector2 = sitio.apt.salas[0].centro
	johnny.modo = "quieto"
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(2.0, 2.0)
	for tipo in ["antidisturbios", "cocinero", "modista", "mascota", "gloton", "gymbro", "bombero"]:
		var jefe: Node2D = meter_zombi(tipo, centro)
		await get_tree().create_timer(0.1, false).timeout
		jefe.vida = int(jefe.vida_max * jefe.enfado)   # en el siguiente paso, se enfada
		await get_tree().create_timer(0.05, false).timeout
		johnny.invulnerable = 999.0
		johnny.position = jefe.position + Vector2(90, -100)   # (más arriba: así la cabeza sale en medio de la foto)
		johnny.velocity = Vector2.ZERO
		camara.reset_smoothing()
		await get_tree().create_timer(0.3, false).timeout
		print("Vapor (%s): al enfadarse %d nubecitas (esperado: 8 o más)" % [tipo, jefe.rabia.bocanadas.size()])
		Captura.foto("captura-vapor-%s-grito.png" % tipo)
		await get_tree().create_timer(1.3, false).timeout
		johnny.position = jefe.position + Vector2(90, -100)
		camara.reset_smoothing()
		await get_tree().process_frame
		print("Vapor (%s): luego, %d nubecitas (esperado: de 1 a 12)" % [tipo, jefe.rabia.bocanadas.size()])
		Captura.foto("captura-vapor-%s.png" % tipo)
		for cosa in get_tree().get_nodes_in_group("zombis") + get_tree().get_nodes_in_group("balas_zombi"):
			cosa.queue_free()
		await get_tree().create_timer(0.1, false).timeout
	get_tree().quit()


# --franja: el aviso de las cargas (aviso.gd) del antidisturbios y de la mascota, congelado a medio llenar y casi
# lleno (con el destello): captura-franja-<jefe>-<llenado>.png
func probar_franja() -> void:
	set_process(false)
	nueva_planta(2)
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true
	await montar(idx, 0, false)
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true
		mapa.niebla[s.id] = 0.0
	mapa.actualizar_niebla(0.0)
	luz.alternar()
	var centro: Vector2 = sitio.apt.salas[0].centro
	johnny.modo = "quieto"
	johnny.invulnerable = 999.0
	var camara: Camera2D = johnny.get_node("Camara")
	for par in [["antidisturbios", "aviso_carga"], ["mascota", "aviso_embestida"]]:
		var jefe: Node2D = meter_zombi(par[0], centro)
		await get_tree().create_timer(0.1, false).timeout
		jefe.set_physics_process(false)   # quieto, con el aviso a mano
		jefe.mirada = Vector2.from_angle(0.5)
		jefe.cambiar(par[1], {"quedan": 1, "aviso": 1.0})
		johnny.position = jefe.position + Vector2(150, 40)
		johnny.velocity = Vector2.ZERO
		camara.reset_smoothing()
		for k in [0.3, 0.75, 0.95]:
			jefe.t = k
			jefe.queue_redraw()
			await get_tree().create_timer(0.1, false).timeout
			Captura.foto("captura-franja-%s-%d.png" % [par[0], roundi(k * 100)])
		jefe.queue_free()
		await get_tree().create_timer(0.1, false).timeout
	print("Franja: casillas calculadas %d (esperado: 1 o más)" % Aviso.franjas.size())
	get_tree().quit()
