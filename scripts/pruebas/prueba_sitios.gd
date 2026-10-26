# Pruebas de sitios: la sala de mantenimiento (--sala), el ascensor (--ascensor), las viviendas (--viviendas),
# el piso de los apartamentos (--piso), el pasillo de la planta y su cartel (--pasillo), la joyería (--joyeria) y cómo suena la pistola en cada sitio
# (--acustica). Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
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


# Con "--captura --piso": el piso de los apartamentos (apartamento.gd: PLANO_PASILLO), siempre el mismo. Primero lo
# genera con la puerta abajo y con ella arriba y mira que esté bien: la puerta en el centro y justo un salón, una
# cocina, un dormitorio de matrimonio y otro individual, cada uno con su baño dentro (con una sola puerta, a él). Luego,
# en la 1ª planta, entra en uno con la puerta abajo (los de encima del pasillo del edificio) y en otro con ella arriba
# (los de debajo), sin zombis, y de cada uno dice sus habitaciones, si está sin muebles, si la puerta está en el centro
# y si desde ella se llega andando a todas, y dibuja su plano con letras (S salón, C cocina, M dormitorio de
# matrimonio, I individual, B baño, . pasillo, # muro, E la entrada). Fotos: lo que se ve al entrar
# (captura-piso-abajo-entrada.png y -arriba-entrada.png), el dormitorio de matrimonio con Johnny dentro y la penumbra,
# para ver sus muebles y la luz de las mesillas (captura-piso-abajo-matrimonio.png y -arriba-matrimonio.png) y el piso
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
		# el dormitorio de matrimonio, con Johnny dentro: sus muebles y la luz de las mesillas, con la penumbra
		for s in apt.salas:
			if s.uso == "dormitorio" and s.get("tipo", "") == "matrimonio":
				johnny.position = s.centro
				await get_tree().create_timer(0.8).timeout
				Captura.foto("captura-piso-%s-matrimonio.png" % lado)
		print("Piso (puerta %s): %d × %d casillas · %s" % [lado, apt.cols, apt.filas,
			" · ".join(apt.salas.map(func(s): return "%s %d×%d" % [s.nombre, s.ancho, s.fondo]))])
		# (de momento, solo los puestos a mano: los 4 del dormitorio de matrimonio, con la puerta abajo y con la puerta arriba)
		print("Piso (puerta %s): muebles %d (esperado: 4, los puestos a mano; Muebles.de_piso)" % [lado,
			get_tree().get_nodes_in_group("muebles").size()])
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
		# el piso entero: todo descubierto, sin penumbra y con la cámara alejada para que quepa
		for s in apt.salas:
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
		Captura.foto("captura-piso-%s.png" % lado)
		Luz.apagada = not Luz.apagada
		$Pantalla.show()
		camara.zoom = Vector2.ONE
		Temblor.desplazamiento = Vector2.ZERO
		encuadrar(sitio)
	get_tree().quit()


# Con "--captura --viviendas": las viviendas de los supervivientes rescatados (mapa/viviendas.gd), detrás de la puerta
# de la derecha de la sala de mantenimiento. Entrar, las puertas cerradas y abiertas, cada uno en su habitación,
# acompañar y volver, y desde la 1ª planta por el ascensor (supervivientes.gd: probar_viviendas); luego los seis a la
# vez, el guiño de la cafetera y las cámaras del técnico. Cada línea de la terminal dice lo esperado. Deja el guardado
# como estaba y se cierra
func probar_viviendas() -> void:
	await get_tree().create_timer(0.3).timeout
	await supervivientes.probar_viviendas()
	await supervivientes.probar_los_seis()
	await supervivientes.probar_cafetera()
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
	await montar(0, puerta_de_tipo("llegada"), false)
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
