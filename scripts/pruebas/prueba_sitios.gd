# Pruebas de sitios: la sala de mantenimiento (--sala), el ascensor (--ascensor), las viviendas (--viviendas),
# el piso de los apartamentos (--piso), las puertas de dentro (--puertas), el pasillo de la planta y su cartel (--pasillo),
# la joyería (--joyeria) y cómo suena la pistola en cada sitio (--acustica). Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_fotos.gd"


# Con "--captura --pasillo": el pasillo de las cuatro plantas con ascensor (la baja y la 1ª a la 3ª), con su cartel
# pintado junto al ascensor (el número de la planta, de suelo a moldura) y, de momento, sin muebles. De cada una dice
# cuántos muebles tiene (esperado: 0) y saca captura-pasillo-<planta>.png, con Johnny delante del ascensor. Luego se cierra
func probar_pasillo() -> void:
	for num in [1, 2, 3, 4]:
		nueva_planta(num)
		await montar(0, 0, false)
		johnny.position = Vector2(planta.sitios[0].ancho / 2.0, planta.sitios[0].alto / 2.0)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		print("Pasillo de la planta %d: muebles %d (esperado: 0, de momento va vacío)" % [num - 1,
			get_tree().get_nodes_in_group("muebles").size()])
		Captura.foto("captura-pasillo-%d.png" % (num - 1))
	get_tree().quit()


# Con "--captura --salida": la salida de incendios del fondo del pasillo (la puerta roja de las escaleras, en el muro de la
# derecha, y su cartel EXIT en la pared de arriba), con Johnny delante: primero con la planta sin pasar (cartel apagado) y
# luego, al caer el jefe, con el cartel encendido y alumbrando. Dice si cada cosa está como toca y, al volver al pasillo de una
# planta ya pasada, que el cartel nace encendido y sin parpadeo. Fotos: captura-salida-cerrada.png y captura-salida-abierta.png.
# Luego se cierra
func probar_salida() -> void:
	nueva_planta(2)
	await montar(0, puerta_de_llegada(), false)
	var escaleras: Node2D = mapa.puertas[puerta_de_tipo("escaleras")]
	johnny.position = escaleras.llegada()
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.8).timeout
	print("Salida (planta sin pasar): se puede pasar %s, cartel encendido %s (esperado: false, false)" % [
		escaleras.abierta, escaleras.cartel.luce()])
	Captura.foto("captura-salida-cerrada.png")
	planta.jefa_muerta = true
	actualizar_puertas()
	print("Salida (cae el jefe): se puede pasar %s, cartel encendido %s, arrancando %s (esperado: true, true, true)" % [
		escaleras.abierta, escaleras.cartel.encendido, escaleras.cartel.arrancando >= 0.0])
	await get_tree().create_timer(2.0).timeout
	print("Salida (2 s después): cartel encendido %s, ya fijo %s (esperado: true, true)" % [
		escaleras.cartel.luce(), escaleras.cartel.arrancando < 0.0])
	Captura.foto("captura-salida-abierta.png")
	await montar(0, puerta_de_llegada(), false)
	escaleras = mapa.puertas[puerta_de_tipo("escaleras")]
	print("Salida (al volver al pasillo ya pasado): cartel encendido %s, ya fijo %s (esperado: true, true)" % [
		escaleras.cartel.luce(), escaleras.cartel.arrancando < 0.0])
	get_tree().quit()


# Con "--captura --llegada": por dónde se llega a cada planta. La planta baja (el portal del edificio) y la azotea (la
# escalera por la que se sube) tienen su puerta de llegada a la izquierda; las demás plantas, ninguna: se llega por las
# escaleras de la derecha, las mismas por las que se sale. De cada una dice cuántas puertas tiene a la izquierda, por
# cuál se llega y a cuánto de ella aparece Johnny; y subiendo de verdad (subir, de la 1ª a la 2ª y de la 3ª a la azotea) dónde
# aparece. Fotos: captura-llegada-<planta>.png (la 1ª y la 2ª, con Johnny recién llegado) y captura-llegada-izquierda.png (el otro extremo del
# pasillo de la 1ª, sin puerta). Luego se cierra
func probar_llegada() -> void:
	for num in [1, 2, 3, 5]:
		nueva_planta(num)
		await montar(0, puerta_de_llegada(), false)
		await get_tree().create_timer(0.6).timeout
		avisar_llegada("Montada")
		if num in [2, 3]:
			Captura.foto("captura-llegada-%d.png" % num)
		if num == 2:
			# y el otro extremo del pasillo, donde estaba la puerta de llegada: ahora, pared lisa
			johnny.position = Vector2(150, planta.sitios[0].alto / 2.0)
			johnny.get_node("Camara").reset_smoothing()
			await get_tree().create_timer(0.6).timeout
			Captura.foto("captura-llegada-izquierda.png")
	for num in [2, 4]:
		nueva_planta(num)
		await montar(0, puerta_de_llegada(), false)
		await subir()
		await get_tree().create_timer(0.6).timeout
		avisar_llegada("Subiendo a la planta %d" % (num + 1))
	get_tree().quit()


# Lo que dice probar_llegada de la planta en la que se está
func avisar_llegada(texto: String) -> void:
	var izquierda: int = planta.sitios[0].salidas.filter(func(s): return s.dir == "izquierda").size()
	var llega: Node2D = mapa.puertas[puerta_de_llegada()]
	var baja_o_azotea: bool = planta.num == 1 or planta.get("azotea", false)
	print("%s: planta %d, puertas a la izquierda %d (esperado %d), llega por la %s (esperado %s), Johnny a %d de ella (esperado 60)" % [
		texto, planta.num, izquierda, 1 if baja_o_azotea else 0, llega.salida.dir, "izquierda" if baja_o_azotea else "derecha",
		roundi(johnny.position.distance_to(llega.position))])


# Con "--captura --piso": el piso de los apartamentos (apartamento.gd: PLANO_PASILLO), siempre el mismo. Primero lo
# genera con la puerta abajo y con ella arriba y mira que esté bien: la puerta en el centro y justo un salón, una
# cocina, un dormitorio de matrimonio y otro individual, cada uno con su baño dentro (con una sola puerta, a él). Luego,
# en la 1ª planta, entra en uno con la puerta abajo (los de encima del pasillo del edificio) y en otro con ella arriba
# (los de debajo), sin zombis, y de cada uno dice sus habitaciones, si está sin muebles, si la puerta está en el centro
# y si desde ella se llega andando a todas, y dibuja su plano con letras (S salón, C cocina, M dormitorio de
# matrimonio, I individual, B baño, . pasillo, # muro, E la entrada). Fotos: lo que se ve al entrar
# (captura-piso-abajo-entrada.png y -arriba-entrada.png), cada dormitorio, el salón, la cocina y los dos baños con
# Johnny dentro y la penumbra, para ver sus muebles y sus luces (captura-piso-abajo-matrimonio.png, -individual.png,
# -salon.png, -cocina.png, -bano-matrimonio.png, -bano-individual.png, y las mismas con -arriba) y el piso
# entero, sin niebla ni penumbra (captura-piso-abajo.png y -arriba.png). Luego se cierra
func probar_piso() -> void:
	var mal := []
	for lado in ["abajo", "arriba"]:
		var otro := Apartamento.generar(false, lado)
		if otro.get("forma", "") != "pasillo" or otro.entrada.c != (otro.cols - Apartamento.PUERTA) / 2:
			mal.append(lado)
			continue
		var hay: Array = otro.salas.map(func(s): return s.get("tipo", "") if s.uso == "dormitorio" else s.uso)
		hay.sort()
		var banos_bien := true
		for b in otro.salas.filter(func(s): return s.uso == "bano"):
			if b.puertas.size() != 1 or otro.salas[b.dueno_bano].get("bano", -1) != b.id or not b.dueno_bano in [b.puertas[0].a, b.puertas[0].b]:
				banos_bien = false
		if hay != ["bano", "bano", "cocina", "individual", "matrimonio", "pasillo", "salon"] or not banos_bien:
			mal.append(lado)
	print("Piso: con la puerta abajo y arriba, mal %s (esperado: [])" % [mal])
	nueva_planta(2)
	var letra := {"salon": "S", "cocina": "C", "matrimonio": "M", "individual": "I", "bano": "B", "pasillo": "."}
	for lado in ["abajo", "arriba"]:
		var idx := -1
		for i in planta.sitios.size():
			if planta.sitios[i].tipo == "apartamento" and planta.sitios[i].apt.entrada.lado == lado:
				idx = i
				break
		if idx < 0:
			print("Piso: en la 1ª planta no hay ninguno con la puerta %s" % lado)
			continue
		var sitio: Dictionary = planta.sitios[idx]
		var apt: Dictionary = sitio.apt
		sitio.limpio = true   # sin zombis: aquí se mira el piso
		await montar(idx, 0, false)
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-piso-%s-entrada.png" % lado)
		# los dos dormitorios, el salón, la cocina y los dos baños, con Johnny dentro: sus muebles y sus luces, con la penumbra
		for s in apt.salas:
			if s.uso in ["dormitorio", "salon", "cocina", "bano"]:
				johnny.position = s.centro
				await get_tree().create_timer(0.8).timeout
				var nombre: String = s.get("tipo", s.uso) if s.uso != "bano" else "bano-" + apt.salas[s.dueno_bano].tipo
				Captura.foto("captura-piso-%s-%s.png" % [lado, nombre])
		print("Piso (puerta %s): %d × %d casillas · %s" % [lado, apt.cols, apt.filas,
			" · ".join(apt.salas.map(func(s): return "%s %d×%d" % [s.nombre, s.ancho, s.fondo]))])
		# (de momento, solo los puestos a mano: los 4 del dormitorio de matrimonio, los 4 del individual, los 7 del salón, los 5
		# de la cocina y los 3 de cada baño)
		print("Piso (puerta %s): muebles %d (esperado: 26, los puestos a mano; Muebles.de_piso)" % [lado,
			get_tree().get_nodes_in_group("muebles").size()])
		# las lámparas encendidas del piso (las de pie y las lamparitas de las mesillas) parpadean todas, como si fallase la luz
		var lamparas := 0
		var parpadean := 0
		for m in get_tree().get_nodes_in_group("muebles"):
			for hijo in m.get_children():
				if hijo.get("parpadea") != null:
					lamparas += 1
					parpadean += 1 if hijo.parpadea else 0
		print("Piso (puerta %s): lámparas encendidas %d, parpadean %d (esperado: las mismas)" % [lado, lamparas, parpadean])
		var salida: Dictionary = sitio.salidas[0]
		print("Piso (puerta %s): la puerta, en la pared de %s %s y en su centro %s (esperado: true y true)" % [
			lado, salida.dir, salida.dir == lado, is_equal_approx(salida.en, sitio.ancho / 2.0)])
		var red: RID = mapa.get_node("Navegacion").get_navigation_map()
		var llega := []
		for s in apt.salas:
			# (al punto andable más cercano a su centro, que puede caer en un mueble; el baño del superviviente, cerrado)
			if planta.superviviente.get("sitio", -1) == idx and planta.superviviente.sala == s.id:
				llega.append("%s cerrado, con el superviviente" % s.nombre)
				continue
			var meta := NavigationServer2D.map_get_closest_point(red, s.centro)
			var camino := NavigationServer2D.map_get_path(red, johnny.position, meta, true)
			llega.append("%s %s" % [s.nombre, mapa.zona_en(meta) == s.id and not camino.is_empty() and camino[-1].distance_to(meta) < 24.0])
		print("Piso (puerta %s): desde la entrada se llega andando a %s (esperado: todas true)" % [lado,
			" · ".join(llega)])
		for f in apt.filas:
			var linea := ""
			for c in apt.cols:
				var v: int = apt.dueno[f * apt.cols + c]
				var entrada: bool = (c - apt.entrada.c) in [0, 1] and (f < Apartamento.BORDE if lado == "arriba" else f >= apt.filas - Apartamento.BORDE)
				var sala: Dictionary = apt.salas[maxi(v, 0)]
				linea += "E" if entrada else "#" if v == -1 else " " if v == -2 else letra[sala.tipo if sala.uso == "dormitorio" else sala.uso]
			print("    " + linea)
		await foto_entera(sitio, "captura-piso-%s.png" % lado)
	get_tree().quit()


# Una foto del sitio montado entero: todo descubierto, sin penumbra y con la cámara alejada para que quepa
func foto_entera(sitio: Dictionary, nombre: String) -> void:
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true
		mapa.niebla[s.id] = 0.0
	mapa.actualizar_niebla(0.0)
	var camara: Camera2D = johnny.get_node("Camara")
	var pantalla := get_viewport_rect().size
	var zoom := minf(pantalla.x / sitio.ancho, pantalla.y / (sitio.alto + ARRIBA_EXTRA))
	camara.zoom = Vector2(zoom, zoom)
	camara.limit_left = -100000
	camara.limit_top = -100000
	camara.limit_right = 100000
	camara.limit_bottom = 100000
	Temblor.desplazamiento = Vector2(sitio.ancho / 2.0, (sitio.alto - ARRIBA_EXTRA) / 2.0) - johnny.position
	camara.reset_smoothing()
	$Pantalla.hide()
	Luz.apagada = not Luz.apagada   # sin penumbra, para que se vea todo
	await get_tree().create_timer(0.6).timeout
	Captura.foto(nombre)
	Luz.apagada = not Luz.apagada
	$Pantalla.show()
	camara.zoom = Vector2.ONE
	Temblor.desplazamiento = Vector2.ZERO
	encuadrar(sitio)


# Con "--captura --edificio centro --tiendas": cada tienda de las tres primeras plantas, entera, sin zombis, sin
# penumbra y con todo descubierto (captura-tiendas-<tipo>-<lado de su puerta>.png), para ver sus habitaciones de dentro
# y lo que tapan sus paredes. La joyería, en la 1ª planta. Luego se cierra
func probar_tiendas() -> void:
	Planta.joyeria_planta = 2
	for num in [1, 2, 3]:
		if num > 1:
			nueva_planta(num)
		for i in range(1, planta.sitios.size()):
			var s: Dictionary = planta.sitios[i]
			if s.get("tienda", "") == "" or s.tipo == "jefe":
				continue
			s.limpio = true   # sin zombis: aquí se mira la tienda
			await montar(i, 0, false)
			await get_tree().create_timer(0.4).timeout
			var nombre := "captura-tiendas-%s-%s.png" % [s.tienda, s.apt.entrada.lado]
			print("Tienda: ", s.nombre, " -> ", nombre)
			await foto_entera(s, nombre)
	get_tree().quit()


# Con "--captura --puertas": las puertas de dentro (mapa/puerta_bano.gd con "libre"), en el sitio de la 1ª planta que
# más tenga (un piso; con --edificio centro, una tienda), sin zombis: que haya una en cada hueco (menos en los cerrados con llave) y empiecen
# cerradas; Johnny se arrima a una y se abre; un zombi despierto, encerrado en una habitación de una sola puerta, va a
# por Johnny, la empuja y la abre; uno dormido pegado a otra no la abre, ni ve a Johnny a través de ella. Al volver a
# entrar, las abiertas siguen abiertas y las demás, cerradas. Y la sala de mantenimiento, con las suyas. Fotos: el
# sitio entero con todas cerradas (captura-puertas-cerradas.png), Johnny abriendo una (captura-puertas-abriendo.png),
# el zombi empujando (captura-puertas-zombi.png), el sitio entero con todas abiertas (captura-puertas-abiertas.png), de
# cerca con Johnny en una habitación (captura-puertas-cerca.png) y la sala (captura-puertas-sala.png). Luego se cierra
func probar_puertas() -> void:
	nueva_planta(2)
	johnny.invencible = true
	# el sitio con más puertas de dentro (las tiendas se sortean: unas tienen dos y otras más)
	var idx := -1
	var mas := 1
	for i in planta.sitios.size():
		var s: Dictionary = planta.sitios[i]
		var cuantas: int = s.apt.puertas.filter(func(d): return not d.get("cerrada", false)).size() if s.tipo == "apartamento" else 0
		if cuantas > mas:
			idx = i
			mas = cuantas
	if idx < 0:
		print("Puertas: en la 1ª planta no hay ningún sitio con dos puertas de dentro")
		get_tree().quit()
		return
	var sitio: Dictionary = planta.sitios[idx]
	var apt: Dictionary = sitio.apt
	sitio.limpio = true   # sin zombis: los pone la prueba
	await montar(idx, 0, false)
	await get_tree().create_timer(0.3).timeout
	var libres: Array = apt.puertas.filter(func(d): return not d.get("cerrada", false))
	print("Puertas (%s): %d en %d huecos sin llave, cerradas %d (esperado: las mismas las tres)" % [sitio.nombre,
		mapa.hojas.size(), libres.size(), mapa.hojas.filter(func(h): return h.abierta == 0.0).size()])
	await foto_entera(sitio, "captura-puertas-cerradas.png")

	# Johnny se arrima a una de frente (o a la primera, si no hay) desde abajo
	var de_frente: Array = mapa.hojas.filter(func(h): return h.de_frente)
	var una: Node2D = de_frente[0] if not de_frente.is_empty() else mapa.hojas[0]
	johnny.position = una.caja.get_center() + (Vector2(0, una.caja.size.y / 2 + 20) if una.de_frente else Vector2(una.caja.size.x / 2 + 20, 0))
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.25).timeout
	Captura.foto("captura-puertas-abriendo.png")
	await get_tree().create_timer(0.6).timeout
	var choca := una.get_children().any(func(h): return h is CollisionShape2D and not h.disabled)
	print("Puertas: Johnny se arrima y se abre %s, ya no choca %s, apuntada en su hueco %s (esperado: true las tres)" % [
		una.abierta == 1.0, not choca, una.hueco.get("abierta", false)])

	# un zombi despierto en una habitación de una sola puerta (cerrada); Johnny, en la de al lado
	var otra: Node2D = null
	var dentro: Dictionary = {}
	for h in mapa.hojas:
		if h.abierta > 0.0:
			continue
		for id in [h.hueco.a, h.hueco.b]:
			if apt.salas[id].puertas.size() == 1:
				otra = h
				dentro = apt.salas[id]
		if otra:
			break
	if otra == null:
		print("Puertas: no hay ninguna habitación de una sola puerta para el zombi")
	else:
		var fuera: Dictionary = apt.salas[otra.hueco.b if otra.hueco.a == dentro.id else otra.hueco.a]
		# el zombi, dentro y a 90 de la puerta (ahí no hay muebles: muebles.gd deja libre delante de cada puerta), y
		# Johnny, al otro lado
		var hacia: Vector2 = dentro.centro - otra.caja.get_center()
		hacia = Vector2(0, signf(hacia.y)) if otra.de_frente else Vector2(signf(hacia.x), 0)
		var zombi: Node2D = meter_zombi("lento", otra.caja.get_center() + hacia * 90.0)
		zombi.zona = dentro.id
		johnny.position = otra.caja.get_center() - hacia * 110.0
		johnny.get_node("Camara").reset_smoothing()
		mapa.vistas[dentro.id] = true   # (para que se vea en la foto)
		var t := 0.0
		var foto := false
		while otra.abierta == 0.0 and t < 10.0:
			await get_tree().create_timer(0.1).timeout
			t += 0.1
			if not foto and otra.empuje >= 0.2:
				foto = true
				Captura.foto("captura-puertas-zombi.png")
		print("Puertas: el zombi de «%s» abre la de «%s» empujando %s, en %.1f s (esperado: true, unos segundos) · foto %s" % [
			dentro.nombre, fuera.nombre, otra.abierta > 0.0, t, foto])
		zombi.queue_free()

	# uno dormido pegado a otra cerrada, por detrás; Johnny, delante, fuera de su alcance
	var tercera: Node2D = null
	for h in mapa.hojas:
		if h.abierta == 0.0:
			tercera = h
			break
	if tercera:
		var hacia := Vector2(0, 1) if tercera.de_frente else Vector2(1, 0)
		var medio: float = (tercera.caja.size.y if tercera.de_frente else tercera.caja.size.x) / 2
		var dormido: Node2D = meter_zombi("lento", tercera.caja.get_center() - hacia * (medio + 20))
		dormido.dormido = true
		dormido.zona = mapa.zona_en(dormido.position)
		johnny.position = tercera.caja.get_center() + hacia * (medio + 70)
		await get_tree().create_timer(1.2).timeout
		print("Puertas: un zombi dormido pegado a una cerrada no la abre %s, ni ve a Johnny a través de ella %s, y sigue dormido %s (esperado: true las tres)" % [
			tercera.abierta == 0.0, not dormido.se_ve(johnny), dormido.dormido])
		dormido.queue_free()

	# al volver a entrar, las abiertas siguen abiertas
	var abiertas: int = mapa.hojas.filter(func(h): return h.abierta > 0.0).size()
	await montar(idx, 0, false)
	await get_tree().create_timer(0.3).timeout
	print("Puertas: al volver a entrar, abiertas %d de %d (esperado: %d)" % [
		mapa.hojas.filter(func(h): return h.abierta == 1.0).size(), mapa.hojas.size(), abiertas])
	for h in mapa.hojas:
		h.abrir()
	await get_tree().create_timer(0.6).timeout
	await foto_entera(sitio, "captura-puertas-abiertas.png")
	var cuarto: Array = apt.salas.filter(func(s): return s.get("tipo", "") == "individual")
	johnny.position = (cuarto[0] if not cuarto.is_empty() else apt.salas[0]).centro
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.8).timeout
	Captura.foto("captura-puertas-cerca.png")

	# la sala de mantenimiento (en la planta baja)
	nueva_planta(1)
	var sala: int = planta.mantenimiento
	await montar(sala, 0, false)
	await get_tree().create_timer(0.3).timeout
	print("Puertas: la sala de mantenimiento, %d en %d huecos (esperado: los mismos)" % [mapa.hojas.size(),
		planta.sitios[sala].apt.puertas.size()])
	for h in mapa.hojas:
		h.abrir()
	await get_tree().create_timer(0.6).timeout
	await foto_entera(planta.sitios[sala], "captura-puertas-sala.png")
	get_tree().quit()


# Con "--captura --viviendas": las viviendas de los supervivientes rescatados (mapa/viviendas.gd), detrás de la puerta
# de la derecha de la sala de mantenimiento. Entrar, las puertas cerradas y abiertas, cada uno en su habitación,
# acompañar y volver, y desde la 1ª planta por el ascensor (supervivientes.gd: probar_viviendas); luego los seis a la
# vez. Cada línea de la terminal dice lo esperado. Deja el guardado
# como estaba y se cierra
func probar_viviendas() -> void:
	await get_tree().create_timer(0.3).timeout
	await supervivientes.probar_viviendas()
	await supervivientes.probar_los_seis()
	await supervivientes.averia.probar_mejora()
	get_tree().quit()


# Con "--captura --sala": la sala de mantenimiento y sus tres estancias (planta.gd). Cuenta en la terminal las
# estancias, sus puertas y en cuál ha quedado cada mueble, y si desde donde se empieza se llega a todo (por donde andan
# los zombis): a la puerta del pasillo, a la de las viviendas y delante de cada mueble que se usa. Fotos: la sala entera
# (captura-sala.png) y, recortada de la pantalla, cada estancia con Johnny dentro y lo que pone arriba
# (captura-sala-vestuario.png, captura-sala-despacho.png y captura-sala-taller.png). Luego cruza la puerta de las
# viviendas, vuelve y sale al pasillo, y cuenta adónde ha llegado cada vez. Luego se cierra
func probar_sala() -> void:
	var sitio: Dictionary = planta.sitios[aqui]
	var apt: Dictionary = sitio.apt
	print("Sala: %d × %d casillas (%d × %d) · estancias: %s · puertas de dentro: %s" % [apt.cols, apt.filas, sitio.ancho,
		sitio.alto, ", ".join(apt.salas.map(func(s): return "%s %d×%d" % [s.nombre, s.ancho, s.fondo])),
		", ".join(apt.puertas.map(func(d): return "%s-%s" % [apt.salas[d.a].nombre, apt.salas[d.b].nombre]))])
	# los que se usan: [nodo, cómo se dice "delante de él"]
	var usables := {"Ordenador": [mapa.ordenador, "del ordenador"], "Banco": [mapa.banco, "del banco"],
		"Baúl": [mapa.baul, "del baúl"], "Taquilla": [mapa.taquilla, "de la taquilla"]}
	var donde := []
	for n in usables:
		donde.append("%s en %s" % [n, mapa.nombre_zona(mapa.zona_en(usables[n][0].position - Vector2(0, 4)))])
	# ninguno lleva ya su nombre escrito debajo
	var con_nombre := usables.keys().filter(func(n): return not usables[n][0].find_children("*", "Label").is_empty())
	print("Muebles de la sala con su nombre escrito: %s (esperado: ninguno)" % ("ninguno" if con_nombre.is_empty() else ", ".join(con_nombre)))
	for m in mapa.muebles:
		donde.append("%s en %s" % [m.datos.tipo, mapa.nombre_zona(m.zona)])
	var corcho: Node2D = mapa.cosas.get_node_or_null("Corcho")
	donde.append("corcho en %s" % (mapa.nombre_zona(mapa.zona_en(corcho.position)) if corcho else "ningún sitio"))
	print("Muebles: " + " · ".join(donde))
	await get_tree().create_timer(0.2).timeout
	var red: RID = mapa.get_node("Navegacion").get_navigation_map()
	var inicio: Vector2 = johnny.position
	var metas := {"la puerta del pasillo": mapa.puertas[0].llegada(), "la de las viviendas": mapa.puertas[1].llegada()}
	for n in usables:
		metas["delante " + usables[n][1]] = usables[n][0].position + Vector2(0, 22)
	var llega := []
	for n in metas:
		var camino := NavigationServer2D.map_get_path(red, inicio, metas[n], true)
		llega.append("%s %s" % [n, not camino.is_empty() and camino[-1].distance_to(metas[n]) < 24.0])
	print("Desde %s (en el %s) se llega a: %s" % [inicio, mapa.nombre_zona(mapa.zona_en(inicio)).to_lower(), " · ".join(llega)])
	johnny.direccion = "s"
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-sala.png")
	# cada estancia, de cerca: Johnny en medio y, de la pantalla, el trozo de la estancia con sus paredes (sin lo de
	# encima de la pantalla: el minimapa y el letrero tapan la esquina del taller)
	$Pantalla.hide()
	for s in apt.salas:
		johnny.position = s.centro + Vector2(0, 40)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.3).timeout
		print("En el %s, arriba pone «%s»" % [s.nombre.to_lower(), lugar.text])
		var pantalla := get_viewport().get_texture().get_image()
		var escala := Vector2(pantalla.get_size()) / get_viewport().get_visible_rect().size
		var a := get_viewport().get_canvas_transform() * Vector2((s.c0 - 1) * Planta.CASILLA, -48.0) * escala
		var b := get_viewport().get_canvas_transform() * Vector2((s.c0 + s.ancho + 1) * Planta.CASILLA, sitio.alto) * escala
		var trozo := Rect2i(Vector2i(a), Vector2i(b - a)).intersection(Rect2i(Vector2i.ZERO, pantalla.get_size()))
		pantalla.get_region(trozo).save_png("res://captura-sala-%s.png" % s.uso)
	$Pantalla.show()
	# las dos puertas de fuera: a las viviendas (y vuelta, por la misma) y al pasillo
	await cruzar(1)
	print("Por la puerta de la derecha: en «%s» (esperado: viviendas)" % planta.sitios[aqui].tipo)
	await cruzar(0)
	print("De vuelta: en «%s», en el %s (esperado: mantenimiento, taller)" % [planta.sitios[aqui].tipo,
		mapa.nombre_zona(mapa.zona_en(johnny.position)).to_lower()])
	await cruzar(0)
	print("Por la puerta de abajo: en «%s» (esperado: pasillo)" % planta.sitios[aqui].tipo)
	get_tree().quit()


# Con "--captura --ascensor": el ascensor (partida.gd, arreglar_ascensor). En la planta baja no se arregla (la sala
# está ahí mismo); en la 1ª planta está averiado hasta que cae el jefe (se hace como si cayera: Johnny entra en su
# sala y el jefe no llega a salir), y al salir al pasillo Johnny dice que lo ha arreglado. Con cosas en la mochila,
# baja en él a la sala de mantenimiento, las guarda en el baúl y vuelve a la 1ª planta, delante del ascensor. En la
# 2ª planta vuelve a estar averiado, y en la azotea no hay. Cada línea de la terminal dice lo esperado. Saca
# captura-placas.png (antes de nada, el pasillo de la planta baja con las placas de las puertas y el cartel de la
# planta, pintado junto al ascensor), captura-ascensor-arreglado.png (el ascensor ya arreglado, con el aviso de Johnny), captura-ascensor-sala.png (la
# sala, ya abajo) y captura-ascensor-baul.png (lo de la mochila, ya en el baúl). Deja el baúl como estaba y se cierra
func probar_ascensor() -> void:
	var antes := Guardado.cargar()
	# en el pasillo de la planta baja, delante de la sala de mantenimiento (la puerta A): su placa, con la llave
	# inglesa, y junto al ascensor el cartel de la planta, con el 0 (captura-placas.png)
	await montar(0, 0, false)
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-placas.png")
	var sala_de_siempre: int = planta.mantenimiento
	arreglar_ascensor()
	var asc := puerta_de_tipo("ascensor")
	print("Planta baja, como si cayera el jefe: la sala %d (esperado: %d, la de siempre) · el ascensor «%s» (esperado: nunca)" % [
		planta.mantenimiento, sala_de_siempre, planta.sitios[0].salidas[asc].cerrojo])
	# a la 1ª planta, al pasillo (por la llegada, como al subir)
	nueva_planta(2)
	await montar(0, puerta_de_llegada(), false)
	asc = puerta_de_tipo("ascensor")
	cruzar(asc)
	await get_tree().process_frame
	print("1ª planta, antes del jefe: ascensor abierto %s · al empujarlo, sigue en el sitio %d y dice «%s» (esperado: false, 0, El ascensor está averiado)" % [
		mapa.puertas[asc].abierta, aqui, aviso.text])
	# en la sala del jefe, como si ya hubiera caído: sin zombis y sin que llegue a salir
	var del_jefe := -1
	for k in planta.sitios.size():
		if planta.sitios[k].tipo == "jefe":
			del_jefe = k
	montar(del_jefe, 0, false)
	jefa_salio = true
	await get_tree().create_timer(0.3).timeout
	var salida: Dictionary = planta.sitios[0].salidas[asc]
	# (la sala es el penúltimo sitio: detrás van sus viviendas)
	print("Cae el jefe: escaleras abiertas %s · el ascensor «%s» lleva al sitio %d, «%s» (esperado: true, «», %d, mantenimiento)" % [
		planta.jefa_muerta, salida.cerrojo, salida.a, planta.sitios[salida.a].tipo, planta.sitios.size() - 2])
	await cruzar(0)
	print("Al salir al pasillo: Johnny dice «%s» (esperado: que ha arreglado el ascensor) · ascensor abierto %s (esperado: true)" % [
		aviso.text, mapa.puertas[asc].abierta])
	johnny.position = mapa.puertas[asc].llegada() + Vector2(0, 40)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ascensor-arreglado.png")
	# con cosas en la mochila, abajo
	mochila.clear()
	mochila.append_array(["gasolina", "gasolina", "pieza_cuerpo"])
	Guardado.cambiar(func(g2): g2.baul = {})
	await cruzar(asc)
	var minimapa = $Pantalla/Minimapa
	print("Abajo: en «%s» (esperado: mantenimiento) · arriba pone «%s» (esperado: Planta baja · Mantenimiento) · el minimapa, «%s» (esperado: Planta baja) · la planta sigue siendo la %d (esperado: 2)" % [
		planta.sitios[aqui].tipo, lugar.text, Planta.nombre_planta(1) if minimapa.abajo() else planta.nombre, planta.num])
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ascensor-sala.png")
	# al baúl: se guarda todo lo de la mochila
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	var abierto: bool = inventario.abierto == "baul"
	if abierto:
		inventario.guardar_todo()
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-ascensor-baul.png")
	var g := Guardado.cargar()
	print("Baúl: abierto %s · guardado gasolina %d, pieza_cuerpo %d · en la mochila %d (esperado: true, 2, 1, 0)" % [
		abierto, g.baul.get("gasolina", 0), g.baul.get("pieza_cuerpo", 0), mochila.size()])
	inventario.cerrar()
	await get_tree().process_frame
	# y de vuelta: la puerta de la sala lleva al ascensor de la 1ª planta
	await cruzar(0)
	print("De vuelta: planta %d, en el sitio %d, a %d del ascensor · dice «%s» (esperado: 2, 0, 0, 1ª planta)" % [
		planta.num, aqui, roundi(johnny.position.distance_to(mapa.puertas[asc].llegada())), aviso.text])
	# en la 2ª planta, averiado otra vez (y la sala de la planta baja, como siempre)
	await subir()
	asc = puerta_de_tipo("ascensor")
	print("2ª planta: el ascensor «%s», abierto %s · la puerta de la sala de siempre, «%s» (esperado: nunca, false, puerta)" % [
		planta.sitios[0].salidas[asc].cerrojo, mapa.puertas[asc].abierta, sala_mantenimiento.salidas[0].tipo])
	# en la azotea no hay ascensor: no se arregla nada (ni falla)
	await ir_a_azotea()
	arreglar_ascensor()
	print("Azotea: sala de mantenimiento %d (esperado: -1)" % planta.mantenimiento)
	Guardado.cambiar(func(g2): g2.baul = antes.baul)
	get_tree().quit()


# Con "--captura --edificio centro --joyeria": la prueba de la cámara acorazada (joyeria.gd), con la joyería en la
# planta baja. Johnny delante de la puerta blindada cerrada (captura-joyeria-camara.png); arrimarse al lector sin
# tarjeta: el aviso y, a la segunda, la alarma con el cartel y los primeros zombis (captura-joyeria-alarma.png); la
# cuenta adelantada hasta el final: la puerta se abre (captura-joyeria-abierta.png). Luego la otra manera: en el
# pasillo cae el guardia y suelta las dos tarjetas (captura-joyeria-dorada.png), Johnny coge la dorada y, con la
# cámara otra vez cerrada, el lector la abre sin alarma. Lo cuenta todo en la terminal
func probar_joyeria() -> void:
	var d: Dictionary = planta.get("joyeria", {})
	print("Joyería en la planta baja: %s · cámara: sala %d, puerta en (%d, %d) · dorada: %s" % [not d.is_empty(),
		d.get("sala", -1), d.get("puerta", {}).get("c", -1), d.get("puerta", {}).get("f", -1), d.get("dorada", "-")])
	if d.is_empty():
		get_tree().quit()
		return
	Luz.apagada = not Luz.apagada
	await montar(d.sitio, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var sitio: Dictionary = planta.sitios[d.sitio]
	for sala in sitio.apt.salas:
		mapa.vistas[sala.id] = true
	# Johnny delante de la puerta blindada, por el lado de la sala de venta
	var centro: Vector2 = joyeria.puerta.caja.get_center()
	var dentro: Vector2 = sitio.apt.salas[d.sala].centro
	var fuera := Vector2(0, signf(centro.y - dentro.y)) if joyeria.puerta.de_frente else Vector2(signf(centro.x - dentro.x), 0)
	johnny.position = centro + fuera * 52.0
	johnny.get_node("Camara").reset_smoothing()
	print("Puerta blindada: montada %s · choca %s · abierta %s · zombis dentro de la cámara: %d" % [joyeria.puerta != null,
		joyeria.puerta.is_in_group("obstaculos"), d.abierta, sitio.zombis.filter(func(z): return mapa.zona_en(z.pos) == d.sala).size()])
	await get_tree().create_timer(0.5, false).timeout
	Captura.foto("captura-joyeria-camara.png")
	# el lector sin tarjeta: la primera vez avisa, la segunda dispara la alarma
	joyeria.listo = true
	joyeria.mirar_lector()
	print("Lector, 1ª vez: alarma %s · dice «%s»" % [joyeria.alarma(), aviso.text])
	joyeria.listo = true
	joyeria.mirar_lector()
	print("Lector, 2ª vez: alarma %s (quedan %.0f s)" % [joyeria.alarma(), d.alarma])
	joyeria.grupo_t = 0.5
	await get_tree().create_timer(1.6, false).timeout
	print("Alarma: zombis en la tienda %d · quedan %.0f s" % [get_tree().get_nodes_in_group("zombis").size(), d.alarma])
	Captura.foto("captura-joyeria-alarma.png")
	# la cuenta, adelantada hasta el final: se abre
	d.alarma = 1.0
	await get_tree().create_timer(1.6, false).timeout
	print("Al acabar la cuenta: abierta %s · la puerta choca %s · dice «%s»" % [d.abierta,
		joyeria.puerta.is_in_group("obstaculos") if is_instance_valid(joyeria.puerta) else false, aviso.text])
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().create_timer(0.8, false).timeout
	Captura.foto("captura-joyeria-abierta.png")
	# el premio: la vitrina dentro de la cámara y el logro; al pisarla, el arma a la mano y el fajo
	print("Premio: %s, calidad %d (esperado: un arma de la tienda que no llevas, Épica: 3; manos %s, guardadas %s) · fajo $%d · vitrina en %s · logro Caja fuerte: %s" % [
		d.premio.arma, d.premio.calidad, johnny.huecos, armas_guardadas, d.premio.fajo, d.premio.pos, Logros.estado(Guardado.cargar(), "caja_fuerte")])
	var manos_antes: Dictionary = johnny.huecos.duplicate()
	var dolares_antes := dolares
	var molotovs_antes: int = lanzables.cantidades.molotov
	johnny.position = d.premio.pos + Vector2(0, 170)   # (más lejos que el imán de las cosas del suelo: que no vuele aún)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.6, false).timeout
	Captura.foto("captura-joyeria-premio.png")
	johnny.position = d.premio.pos
	await get_tree().create_timer(0.6, false).timeout
	print("Cogido: %s · manos %s → %s · guardadas %s · calidad de la nueva %d (esperado: 3) · dólares %d → %d · molotovs %d → %d · dice «%s»" % [d.premio.cogido,
		manos_antes, johnny.huecos, armas_guardadas, johnny.calidad(d.premio.arma), dolares_antes, dolares, molotovs_antes,
		lanzables.cantidades.molotov, aviso.text])
	# la segunda apertura, más abajo, prepara otro premio
	d.erase("premio")
	# la otra manera: el guardia cae en el pasillo y suelta la tarjeta dorada junto a la suya
	await montar(0, 0, false)
	print("Guardia en el pasillo: %s · dorada: %s" % [guardia != null, d.dorada])
	johnny.position = guardia.position + Vector2(-120, 30)
	guardia.recibir_golpe(9999, Vector2.ZERO)
	await get_tree().create_timer(0.6, false).timeout
	johnny.get_node("Camara").reset_smoothing()
	print("Al caer: dorada %s en %s · en el suelo: tarjeta %s, dorada %s" % [d.dorada, d.suelo, mapa.cosas.has_node("Llave"), mapa.cosas.has_node("Dorada")])
	Captura.foto("captura-joyeria-dorada.png")
	johnny.position = d.suelo.pos
	await get_tree().create_timer(0.4, false).timeout
	print("Cogida: dorada %s · dice «%s»" % [d.dorada, aviso.text])
	# con la cámara otra vez cerrada, el lector la abre con la tarjeta y sin alarma
	d.abierta = false
	d.puerta.merge({"cerrada": true, "abierta": false}, true)   # (su hueco también: mapa/puerta_bano.gd)
	d.alarma = -1.0
	await montar(d.sitio, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	johnny.position = centro + fuera * 52.0
	joyeria.listo = true
	joyeria.mirar_lector()
	print("Con la tarjeta dorada: abierta %s · alarma %s · dorada %s · dice «%s»" % [d.abierta, joyeria.alarma(), d.dorada, aviso.text])
	print("Segundo premio: %s (esperado: un arma de la tienda que no llevas; manos %s, guardadas %s) · fajo $%d" % [d.premio.arma,
		johnny.huecos, armas_guardadas, d.premio.fajo])
	get_tree().quit()


# Con "--captura --acustica" (y "--edificio centro" para las tiendas): cómo suena la pistola en cada sitio de la
# planta baja, habitación a habitación, y en la azotea (mapa.acustica_en); dispara una vez en cada una
func probar_acustica() -> void:
	await get_tree().create_timer(0.3).timeout
	johnny.coger("pistola")
	var vistos := {}
	for i in planta.sitios.size():
		await montar(i, 0, false)
		var s: Dictionary = planta.sitios[i]
		var salas: Array = s.apt.salas if s.has("apt") else [{"id": 0, "uso": "-"}]
		for sala in salas:
			var clave := "%s/%s/%s" % [s.tipo, s.get("tienda", ""), sala.uso]
			if vistos.has(clave):
				continue
			vistos[clave] = true
			# el centro de la primera casilla de suelo de esa habitación
			var pos := Vector2(-1, -1)
			for n in mapa.cols * mapa.filas:
				if mapa.dueno[n] == sala.id:
					pos = Vector2(n % mapa.cols + 0.5, n / mapa.cols + 0.5) * mapa.CASILLA
					break
			print("ACUSTICA %-40s %s" % [clave, mapa.acustica_en(pos)])
			Sonido.tocar("pistola_" + mapa.acustica_en(pos))
	await montar(0, 0, false)   # de vuelta al pasillo: el minimapa no sabría dónde está si salta desde otro sitio
	await ir_a_azotea()
	print("ACUSTICA %-40s %s" % ["azotea", mapa.acustica_en(johnny.global_position)])
	get_tree().quit()
