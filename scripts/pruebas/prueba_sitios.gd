# Pruebas de sitios: la sala de mantenimiento (--sala), el ascensor (--ascensor), las viviendas (--viviendas),
# el piso de los apartamentos (--piso), las puertas de dentro (--puertas), el pasillo de la planta y su cartel (--pasillo),
# la joyería (--joyeria) y cómo suena la pistola en cada sitio (--acustica). Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_fotos.gd"


# Con "--captura --muebles-paso" (18 nov): genera muchas plantas de los tres edificios (las cuatro de cada uno, con cada
# minijefe y "--semillas N" semillas, 12 si no se dice) y, en cada sitio, repasa los muebles como al final de
# Planta.generar (Muebles.repasar, sin quitar nada): ningún mueble puede tapar una puerta ni dejar suelo al que no se
# llega. Dice cuántos sitios ha mirado y cada mueble que corta el paso (esperado: ninguno). Luego se cierra
func probar_muebles_paso() -> void:
	var n_semillas := int(Captura.dato("--semillas", "12"))
	var antes := Planta.semilla
	var sitios := 0
	var malos := 0
	var dibujados := {}   # una foto de cada sala con algún mueble mal puesto
	var quitados_al_generar := 0   # los repasos de Planta.generar que han tenido que quitar algo
	Muebles.apuntar = true
	for ed_id in ["apartamentos", "centro", "torre"]:
		var jefes: Array = Edificios.datos(ed_id).get("minijefes", [""])
		for k in n_semillas:
			for num in range(1, Planta.PLANTAS):
				Planta.semilla = 1000 + k * 37
				var su_jefe: String = jefes[(k + num) % jefes.size()]
				Muebles.apuntados = []
				var p := Planta.generar(num, ed_id, su_jefe)
				for ap in Muebles.apuntados:
					quitados_al_generar += 1
					var clave_q := "q-%s-%s" % [ed_id, ap.sitio.get("nombre", "?")]
					if not dibujados.has(clave_q):
						dibujados[clave_q] = true
						var ahora: Array = ap.sitio.muebles
						ap.sitio.muebles = ap.muebles   # (el plano con los muebles de antes del repaso)
						Muebles.repasar(ap.sitio, false)
						dibujar_paso(Muebles.ultimo_paso, ap.sitio, "captura-muebles-paso-%d.png" % dibujados.size())
						ap.sitio.muebles = ahora
				for sitio in p.sitios:
					sitios += 1
					var mal := Muebles.repasar(sitio, false)
					for q in mal:
						malos += 1
						print("Muebles-paso · %s planta %d (semilla %d, %s) «%s»: %s" % [ed_id, num, Planta.semilla, su_jefe,
							sitio.get("nombre", "?"), q])
					var clave := "%s-%s" % [ed_id, sitio.get("nombre", "?")]
					if not mal.is_empty() and not dibujados.has(clave):
						dibujados[clave] = true
						dibujar_paso(Muebles.ultimo_paso, sitio, "captura-muebles-paso-%d.png" % dibujados.size())
	Planta.semilla = antes
	Muebles.apuntar = false
	print("Muebles-paso · %d sitios mirados, %d muebles que cortan el paso (esperado: 0); %d sitios a los que el repaso ha tenido que quitar algún mueble al generarlos (mejor 0: que los puestos a mano no lo necesiten)" % [
		sitios, malos, quitados_al_generar])
	if malos > 0:
		Captura.fallar("hay muebles que cortan el paso")


# Con "--captura --atasco-johnny" (18 nov): la salida de emergencia de Johnny (johnny.gd, desatascar). En un piso:
#   1. Johnny metido a la fuerza dentro de un mueble y queriendo andar 2 s: sale al hueco libre más cercano
#   2. Johnny empujando la pared de arriba del pasillo 2 s: no se le mueve (contra una pared no está atascado)
# Foto: captura-atasco-johnny.png (ya fuera del mueble). Luego se cierra
func probar_atasco_johnny() -> void:
	nueva_planta(2)
	var piso := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "apartamento" and not planta.sitios[i].muebles.is_empty():
			piso = i
			break
	await montar(piso, 0, false)
	var mueble: Node2D = get_tree().get_nodes_in_group("muebles").reduce(func(a, m): return m if a == null or \
		m.datos.w * m.datos.h > a.datos.w * a.datos.h else a, null)
	var dentro: Vector2 = mueble.global_position + Vector2(0, -mueble.datos.h / 2.0)
	johnny.global_position = dentro
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().physics_frame
	var encerrado_antes: bool = johnny.encerrado()
	Input.action_press("derecha")
	await get_tree().create_timer(2.0).timeout
	Input.action_release("derecha")
	await get_tree().create_timer(0.3).timeout
	print("Atasco (dentro de «%s»): encerrado al meterlo %s · ya fuera %s · se ha ido a %d unidades (esperado: true, true, menos de 120)" % [
		mueble.datos.tipo, encerrado_antes, not johnny.encerrado(), roundi(johnny.global_position.distance_to(dentro))])
	Captura.foto("captura-atasco-johnny.png")
	await montar(0, puerta_de_llegada(), false)
	johnny.global_position = Vector2(mapa.sitio.ancho / 2.0 + 200.0, Planta.MURO + 30.0)
	await get_tree().create_timer(0.3).timeout
	var antes: Vector2 = johnny.global_position
	Input.action_press("arriba")
	await get_tree().create_timer(2.0).timeout
	Input.action_release("arriba")
	print("Atasco (empujando la pared del pasillo): se ha movido %d unidades (esperado: menos de 20)" % roundi(
		johnny.global_position.distance_to(antes)))
	get_tree().quit()


# El plano de un repaso, a 4 píxeles por cuadrito de media casilla: muro en negro, suelo al que se llega en gris, suelo
# sin salida en rojo, los muebles en marrón (el que corta el paso, en amarillo) y los puntos de las puertas en verde
func dibujar_paso(paso: Muebles.Paso, sitio: Dictionary, archivo: String) -> void:
	var img := Image.create(paso.cols * 4, paso.filas * 4, false, Image.FORMAT_RGB8)
	var visto := PackedByteArray()
	visto.resize(paso.libre.size())
	var pila: Array[int] = [paso.metas[0]]
	visto[paso.metas[0]] = 1
	while not pila.is_empty():
		var i: int = pila.pop_back()
		for j in [i - paso.cols, i + paso.cols, i - 1 if i % paso.cols > 0 else -1, i + 1 if i % paso.cols < paso.cols - 1 else -1]:
			if j >= 0 and j < paso.libre.size() and paso.libre[j] == 1 and visto[j] == 0:
				visto[j] = 1
				pila.append(j)
	for i in paso.libre.size():
		var color := Color.BLACK
		if paso.libre[i] == 1:
			color = Color(0.45, 0.45, 0.45) if visto[i] == 1 else Color(0.9, 0.15, 0.15)
		img.fill_rect(Rect2i((i % paso.cols) * 4, (i / paso.cols) * 4, 4, 4), color)
	var malos := Muebles.repasar(sitio, false)
	for m in sitio.muebles:
		var r := Muebles.choque(m)
		var mal := malos.any(func(q): return q.begins_with("%s en %s" % [m.tipo, Vector2(m.x, m.y).round()]))
		img.fill_rect(Rect2i(Vector2i(r.position / 4.0), Vector2i((r.size / 4.0).ceil())),
			Color(1, 0.85, 0.1) if mal else Color(0.55, 0.35, 0.2))
	for meta in paso.metas:
		img.fill_rect(Rect2i((meta % paso.cols) * 4, (meta / paso.cols) * 4, 4, 4), Color(0.1, 0.9, 0.2))
	img.save_png("res://capturas/" + archivo)
	print("Muebles-paso · %s: %s" % [archivo, sitio.get("nombre", "?")])


# Con "--captura --pasillo": el pasillo de las cuatro plantas con ascensor (la baja y la 1ª a la 3ª), con su cartel
# pintado junto al ascensor (el número de la planta, de suelo a moldura) y, de momento, sin muebles. De cada una dice
# cuántos muebles tiene (esperado: 0) y cómo se llaman la planta y dos de sus puertas en el idioma de la prueba (en inglés,
# ruso y chino, un número más que en español: Planta.CALLE_ES_LA_PRIMERA), y saca captura-pasillo-<planta>.png, con Johnny
# delante del ascensor. Luego se cierra
func probar_pasillo() -> void:
	for num in [1, 2, 3, 4]:
		nueva_planta(num)
		await montar(0, 0, false)
		johnny.position = Vector2(planta.sitios[0].ancho / 2.0, planta.sitios[0].alto / 2.0)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		print("Pasillo de la planta %d: muebles %d (esperado: 3, las plantas junto al ascensor y junto a los pisos A y B; en la planta baja, la A es la sala de mantenimiento)" % [num - 1,
			get_tree().get_nodes_in_group("muebles").size()])
		print("  [%s] «%s» · puertas «%s» y «%s» (en español: «%s», «%s» y «%s»)" % [Idioma.actual, Planta.nombre_de(planta),
			Planta.nombre_de_sitio({"nombre": Planta.nombre_puerta(num, "A")}),
			Planta.nombre_de_sitio({"nombre": Planta.nombre_puerta(num, "D")}), planta.nombre,
			Planta.nombre_puerta(num, "A"), Planta.nombre_puerta(num, "D")])
		Captura.foto("captura-pasillo-%d.png" % (num - 1))
	get_tree().quit()


# Con "--captura --cartel-sala": la puerta de acero de la sala de mantenimiento en el pasillo de la planta baja (la A, de
# tools/puerta_servicio.py) y su cartel a la derecha (tools/cartel_mantenimiento.py), con Johnny delante: «MANTENIMIENTO»
# escrito en la placa lisa, en español, inglés, francés, ruso y chino. Fotos:
# captura-cartel-sala-<idioma>.png. Luego se cierra
func probar_cartel_sala() -> void:
	var antes := Idioma.actual
	await montar(0, 0, false)
	var puerta: Node2D = mapa.puertas[0]
	johnny.position = puerta.position + Vector2(-60, 90)
	johnny.get_node("Camara").reset_smoothing()
	for codigo in ["es", "en", "fr", "ru", "zh_CN"]:
		Idioma.poner(codigo, false)
		puerta.queue_redraw()
		await get_tree().create_timer(0.5).timeout
		print("Cartel de la sala en %s: «%s»" % [codigo, Idioma.t("Mantenimiento").to_upper()])
		Captura.foto("captura-cartel-sala-%s.png" % codigo)
	Idioma.poner(antes, false)
	get_tree().quit()


# Con "--captura --pasillo-baja" (M95): el pasillo de la planta baja de los Apartamentos con lo que lleva colgado en la pared
# de arriba (cuadros, la manguera de incendios y el extintor) y su alfombra larga, con Johnny a la izquierda, en medio y a la
# derecha (captura-pasillo-baja-izquierda.png, -medio.png y -derecha.png), y el de la 2ª planta, con la misma alfombra (M99,
# captura-pasillo-planta2.png). Dice qué cuelga en cada planta de las cuatro primeras (cuadros distintos en cada una: cuatro
# en la baja y cinco en las demás; la manguera y el extintor, solo en la baja) y si lleva alfombra (todas). Luego se cierra
func probar_pasillo_baja() -> void:
	await montar(0, 0, false)
	for donde in [["izquierda", 260.0], ["medio", 900.0], ["derecha", 1500.0]]:
		johnny.position = Vector2(donde[1], planta.sitios[0].alto / 2.0)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.5).timeout
		Captura.foto("captura-pasillo-baja-%s.png" % donde[0])
	nueva_planta(2)
	await montar(0, puerta_de_llegada(), false)
	johnny.position = Vector2(900.0, planta.sitios[0].alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-pasillo-planta2.png")
	for num in range(1, 5):
		var pasillo: Dictionary = Planta.generar(num).sitios[0]
		var cuadros: Array = pasillo.colgados.map(func(c): return c.dibujo).filter(func(d): return d.begins_with("cuadro"))
		var otros: Array = pasillo.colgados.map(func(c): return c.dibujo).filter(func(d): return not d.begins_with("cuadro"))
		var distintos := {}
		for d in cuadros:
			distintos[d] = true
		print("Pasillo de la planta %d: %d cuadros (%d distintos) %s · además %s · alfombra %s" % [num, cuadros.size(),
			distintos.size(), cuadros, otros, pasillo.get("alfombra", false)])
	print("(esperado: en la 1, 4 cuadros distintos, manguera y dos extintores; en las demás, 5 distintos y un extintor (M94); alfombra en todas)")
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


# Con "--captura --portal": el felpudo de rejilla metálica del portal de los Apartamentos, de pie delante de la puerta de
# la calle (la de la izquierda de la planta baja; tools/felpudo_portal_gpt.py), con Johnny apartado para que se vea entero.
# Foto: captura-portal.png. Luego se cierra
func probar_portal() -> void:
	nueva_planta(1)
	await montar(0, puerta_de_llegada(), false)
	johnny.position = Vector2(300, planta.sitios[0].alto / 2.0 + 90)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-portal.png")
	get_tree().quit()


# Con "--captura --llegada": por dónde se llega a cada planta. La planta baja (el portal del edificio) tiene su puerta de
# llegada a la izquierda; las demás plantas, ninguna: se llega por las escaleras de la derecha, las mismas por las que se
# sale, y la azotea, por la escalera de su derecha (como la salida de incendios). De cada una dice cuántas puertas tiene a la izquierda, por
# cuál se llega y a cuánto de ella aparece Johnny; y subiendo de verdad (subir, de la 1ª a la 2ª y de la 3ª a la azotea) dónde
# aparece. Fotos: captura-llegada-<planta>.png (la planta baja, con la puerta de la calle, y la 1ª y la 2ª, con Johnny recién llegado) y captura-llegada-izquierda.png (el otro extremo del
# pasillo de la 1ª, sin puerta). Luego se cierra
func probar_llegada() -> void:
	for num in [1, 2, 3, 5]:
		nueva_planta(num)
		await montar(0, puerta_de_llegada(), false)
		await get_tree().create_timer(0.6).timeout
		avisar_llegada("Montada")
		if num in [1, 2, 3]:
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
	var baja: bool = planta.num == 1   # (solo el portal tiene la puerta a la izquierda; la azotea, como las demás, a la derecha)
	print("%s: planta %d, puertas a la izquierda %d (esperado %d), llega por la %s (esperado %s), Johnny a %d de ella (esperado 60)" % [
		texto, planta.num, izquierda, 1 if baja else 0, llega.salida.dir, "izquierda" if baja else "derecha",
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
		# L36: el pasillo, con sus manchas de sangre sueltas (de 6 a 8, distintas, con salpicones alrededor) y el suelo ya sin la mancha pintada; Johnny,
		# junto a la primera, para que se vea con su linterna
		var de_sangre: Array = mapa.restos.filter(func(r): return r.dibujo.resource_path.get_file().begins_with("sangre-suelo"))
		if not de_sangre.is_empty():
			johnny.position = de_sangre[0].pos + Vector2(-50, 0)
			await get_tree().create_timer(0.8).timeout
			Captura.foto("captura-piso-%s-pasillo.png" % lado)
		var sangre: Array = de_sangre.map(func(r): return r.dibujo.resource_path.get_file())
		var distintas := {}
		for n in sangre:
			distintas[n] = true
		print("Piso (puerta %s): manchas de sangre en el pasillo %s, distintas %d (esperado: de 6 a 8, todas distintas) · gotas de salpicón %d (esperado: muchas)" % [
			lado, sangre, distintas.size(), mapa.salpicones.size()])
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


# Con "--captura --zombis-sala": cuántos zombis hay en cada habitación de los apartamentos (planta.gd, horda: el reparto
# del presupuesto y, además, EXTRA_POR_SALA de más en cada una). En doce plantas (de la baja a la 5ª) cuenta los
# zombis de cada piso y dice qué habitaciones se quedan con menos de 2 (esperado: ninguna, salvo que no quepan), si hay
# alguno a menos de LEJOS_PUERTA de la puerta de entrada o dos a menos de 60 uno de otro (esperado: 0 y 0), y saca
# captura-zombis-sala.png con el piso con más zombis, entero. Las tiendas del centro comercial no cuentan. Luego se cierra
# Con "--captura --edificio centro --zombis-tienda": cuántos zombis hay en las tiendas del centro comercial (planta.gd,
# horda; M84). En doce plantas (de la baja a la 4ª) cuenta los de cada tienda (sin las de los jefes) y los de cada
# sala, por tipo de sala, y dice si hay alguno a menos de LEJOS_PUERTA de la puerta o dos a menos de 60. Saca
# captura-zombis-tienda.png con la tienda con más zombis, entera y sin penumbra. Luego se cierra
func probar_zombis_tienda() -> void:
	var tiendas := 0
	var total := 0
	var minimo := 999
	var maximo := 0
	var por_uso := {}      # uso de la sala → [salas, zombis]
	var cerca_puerta := 0
	var juntos := 0
	var mejor := {}
	for i in 12:
		Planta.semilla = 1000 + i
		var num := 1 + i % 4
		var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
		for idx in p.sitios.size():
			var s: Dictionary = p.sitios[idx]
			if s.get("tienda", "") == "" or s.tipo == "jefe":
				continue
			tiendas += 1
			var n: int = s.zombis.size()
			total += n
			minimo = mini(minimo, n)
			maximo = maxi(maximo, n)
			if mejor.is_empty() or n > mejor.n:
				mejor = {"n": n, "semilla": 1000 + i, "num": num, "idx": idx}
			var puerta := Vector2(s.salidas[0].en, Planta.MURO + 52 if s.salidas[0].dir == "arriba" else s.alto - Planta.MURO - 52)
			var cuenta := {}
			for z in s.zombis:
				var id: int = s.apt.dueno[int(z.pos.y / Planta.CASILLA) * s.apt.cols + int(z.pos.x / Planta.CASILLA)]
				cuenta[id] = cuenta.get(id, 0) + 1
				if z.pos.distance_to(puerta) < Planta.LEJOS_PUERTA:
					cerca_puerta += 1
			for a in n:
				for b in range(a + 1, n):
					if s.zombis[a].pos.distance_to(s.zombis[b].pos) < 60.0:
						juntos += 1
			for sala in s.apt.salas:
				var u: String = sala.uso
				var par: Array = por_uso.get(u, [0, 0])
				por_uso[u] = [par[0] + 1, par[1] + cuenta.get(sala.id, 0)]
	print("Zombis por tienda: %d tiendas | %d zombis | media %.1f | mínimo %d | máximo %d" % [tiendas, total,
		float(total) / maxi(tiendas, 1), minimo, maximo])
	for u in por_uso:
		print("  sala «%s»: %d salas, media %.1f zombis" % [u, por_uso[u][0], float(por_uso[u][1]) / maxi(por_uso[u][0], 1)])
	print("Cerca de la puerta: %d (esperado 0) | parejas a menos de 60: %d (esperado 0)" % [cerca_puerta, juntos])
	# la foto: la tienda con más zombis, sin penumbra y con todo a la vista
	Planta.semilla = mejor.semilla
	nueva_planta(mejor.num)
	Planta.semilla = 0
	luz.alternar()
	montar(mejor.idx, 0, false)
	for sala in planta.sitios[mejor.idx].apt.salas:
		mapa.vistas[sala.id] = true
	var sitio: Dictionary = planta.sitios[mejor.idx]
	johnny.position = Vector2(sitio.ancho / 2.0, sitio.alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.8).timeout
	Captura.foto("captura-zombis-tienda.png")
	get_tree().quit()


# Con "--captura --durmientes-planta": cuántos durmientes (zombis que no son jefes) trae cada planta de cada edificio al
# generarse, con 8 semillas por planta (el guardia de la llave maestra, aparte). No cuenta los que llegan luego (la horda del
# rescate, los eventos, los que llama un jefe, los escoltas de la alarma). Para saber cuánto mutágeno da una partida
func probar_durmientes_planta() -> void:
	for ed in Edificios.LISTA:
		var linea := []
		var suma := 0.0
		for num in range(1, Planta.PLANTAS + 1):
			var total := 0
			var minimo := 9999
			var maximo := 0
			for i in 8:
				Planta.semilla = 2000 + i * 7 + num
				var minis: Array = Edificios.LISTA[ed].minijefes
				var jefe: String = minis[num - 1] if num <= minis.size() else Edificios.LISTA[ed].final
				var p: Dictionary = Planta.generar(num, ed, jefe)
				var n := 0
				for s in p.sitios:
					for z in s.zombis:
						if not z.tipo in JEFES:
							n += 1
				if p.get("guardia", {}).size() > 0:
					n += 1
				total += n
				minimo = mini(minimo, n)
				maximo = maxi(maximo, n)
			suma += total / 8.0
			linea.append("planta %d: %.0f (%d-%d)" % [num, total / 8.0, minimo, maximo])
		print("Durmientes de %s: %s | partida entera: %.0f" % [ed, " · ".join(linea), suma])
	Planta.semilla = 0
	get_tree().quit()


func probar_zombis_sala() -> void:
	var pisos := 0
	var total := 0
	var mas := 0
	var pocos := {}        # habitaciones con menos de 2 zombis: cuántas veces, por nombre
	var cerca_puerta := 0
	var juntos := 0
	var salas_n := 0
	var tipos := {}   # cuántos de cada tipo (la vecina, desde el 8 nov, en los apartamentos)
	for i in 12:
		Planta.semilla = 1000 + i
		var num := 1 + i % 5
		var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
		for idx in p.sitios.size():
			var s: Dictionary = p.sitios[idx]
			if s.tipo != "apartamento" or s.get("tienda", "") != "":
				continue
			pisos += 1
			total += s.zombis.size()
			var puerta := Vector2(s.salidas[0].en, Planta.MURO + 52 if s.salidas[0].dir == "arriba" else s.alto - Planta.MURO - 52)
			var cuenta := {}
			for z in s.zombis:
				tipos[z.tipo] = tipos.get(z.tipo, 0) + 1
				var c := int(z.pos.x / Planta.CASILLA)
				var f := int(z.pos.y / Planta.CASILLA)
				var id: int = s.apt.dueno[f * s.apt.cols + c]
				cuenta[id] = cuenta.get(id, 0) + 1
				if z.pos.distance_to(puerta) < Planta.LEJOS_PUERTA:
					cerca_puerta += 1
			for a in s.zombis.size():
				for b in range(a + 1, s.zombis.size()):
					if s.zombis[a].pos.distance_to(s.zombis[b].pos) < 60.0:
						juntos += 1
			var cerrada: int = p.superviviente.sala if p.superviviente.get("sitio", -1) == idx else -1
			for sala in s.apt.salas:
				if sala.id == cerrada or sala.uso == "acorazada":
					continue
				salas_n += 1
				if cuenta.get(sala.id, 0) < 2:
					var clave := "%s %d×%d" % [sala.nombre, sala.ancho, sala.fondo]
					pocos[clave] = pocos.get(clave, 0) + 1
	Planta.semilla = 0
	print("Zombis por habitación: %d pisos, %d habitaciones, %d zombis (%.1f por piso, %.1f por habitación)" % [
		pisos, salas_n, total, float(total) / maxi(pisos, 1), float(total) / maxi(salas_n, 1)])
	print("Zombis por habitación: con menos de 2: %s (esperado: ninguna)" % [pocos])
	print("Zombis por habitación: de cada tipo %s (esperado: entre ellos, vecinas)" % [tipos])
	print("Zombis por habitación: a menos de %d de la puerta %d, dos a menos de 60: %d (esperado: 0 y 0)" % [
		int(Planta.LEJOS_PUERTA), cerca_puerta, juntos])
	# la foto: un piso de la 3ª planta, con todos sus zombis a la vista
	nueva_planta(3)
	var mejor := -1
	for idx in planta.sitios.size():
		var s: Dictionary = planta.sitios[idx]
		if s.tipo == "apartamento" and s.get("tienda", "") == "" and (mejor < 0 or s.zombis.size() > planta.sitios[mejor].zombis.size()):
			mejor = idx
	var sitio: Dictionary = planta.sitios[mejor]
	print("Zombis por habitación: foto del piso con %d zombis" % sitio.zombis.size())
	await montar(mejor, 0, false)
	await get_tree().create_timer(0.4).timeout
	await foto_entera(sitio, "captura-zombis-sala.png")
	get_tree().quit()


# ── Volver a un sitio ──

# Cómo está el sitio ahora: cada zombi vivo (dónde, con cuánta vida y si duerme), los cuerpos, lo que hay por el suelo,
# la sangre y cuántos nodos tiene (si al volver se pusiera algo dos veces, aquí se notaría)
func foto_sitio() -> Dictionary:
	var vivos := {}
	for z in get_tree().get_nodes_in_group("zombis"):
		vivos[z.get_instance_id()] = [z.position, z.vida, z.get("dormido")]
	var cosas: Array = mapa.cosas.get_children().filter(func(n): return n != johnny and not n in supervivientes.equipo)
	var sangre := 0
	for n in cosas:
		if n is Mancha:
			sangre += n.celdas.size()
	return {"vivos": vivos, "cuerpos": cosas.filter(func(n): return n.get("estado") == "muerto").size(),
		"suelo": cosas.filter(func(n): return n.get_script() == BILLETE).size(), "sangre": sangre,
		"nodos": cosas.size() + mapa.get_child_count()}


# Va al sitio "fuera", espera un poco, vuelve y dice si lo que había sigue igual
func ida_y_vuelta(que: String, fuera: int) -> void:
	var idx := aqui
	var el_mapa := mapa
	var antes := foto_sitio()
	await montar(fuera, 0, false)
	var parado: bool = mapas.get(idx) == el_mapa and not el_mapa.is_inside_tree()
	var minimapa: int = $Pantalla/Minimapa.zombis_en(idx)
	await get_tree().create_timer(0.4).timeout
	await montar(idx, 0, false)
	var ahora := foto_sitio()
	var distinto: Array = antes.keys().filter(func(k): return antes[k] != ahora[k])
	print("Volver · %s: el mismo mapa %s, parado fuera %s, en el minimapa %d · %d vivos, %d cuerpos, %d por el suelo, %d de sangre, %d nodos · distinto: %s (esperado: true, true, nada)" % [
		que, is_same(mapa, el_mapa), parado, minimapa, ahora.vivos.size(), ahora.cuerpos, ahora.suelo, ahora.sangre, ahora.nodos, distinto])


# Cuántos nodos hay, en la escena y fuera de ella, y la memoria
func nodos_ahora() -> String:
	return "%d nodos (%d fuera de la escena), %.0f MB" % [Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), Performance.get_monitor(Performance.MEMORY_STATIC) / 1000000.0]


# Con "--captura --minimapa": el minimapa (minimapa.gd) en cada sitio: la sala de mantenimiento (captura-minimapa-mant.png),
# el pasillo con todos los pisos del mismo tamaño (-pasillo), un piso al entrar (-piso) y tras pasar a otra habitación
# (-piso2), con las cámaras del técnico (-camaras) y la habitación del jefe, con su barra y sin el nombre del sitio (-jefe) y,
# al quitarse la barra, con él (-jefe-sin-barra). Luego se cierra
func probar_minimapa() -> void:
	johnny.vida = 9999
	var mini = $Pantalla/Minimapa
	await get_tree().create_timer(0.5).timeout
	print("Minimapa · en «%s», plano del sitio: %s (esperado: mantenimiento, true)" % [planta.sitios[aqui].tipo, mini.dentro()])
	Captura.foto("captura-minimapa-mant.png")
	await montar(0, 0, false)
	await get_tree().create_timer(0.5).timeout
	var anchos := {}
	for c in mini.casillas():
		if c.get("sitio", 0) > 0:
			anchos[c.r.size] = true
	print("Minimapa · pasillo, plano del sitio: %s · tamaños de los pisos: %s (esperado: false, uno solo)" % [mini.dentro(), anchos.keys()])
	Captura.foto("captura-minimapa-pasillo.png")
	var piso := eventos.piso(false)
	await montar(piso, 0, false)
	await get_tree().create_timer(1.0).timeout
	Captura.foto("captura-minimapa-piso.png")
	var salas: Array = planta.sitios[piso].apt.salas
	var otra: Dictionary = salas[0]   # (el salón)
	johnny.position = (Vector2(otra.c0, otra.f0) + Vector2(otra.ancho, otra.fondo) / 2.0) * 32.0
	await get_tree().create_timer(1.5).timeout
	print("Minimapa · piso: en la habitación %d (%s), vistas %s" % [mapa.zona_en(johnny.position), otra.uso, planta.sitios[piso].vistas.keys()])
	Captura.foto("captura-minimapa-piso2.png")
	mini.camaras = true
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-minimapa-camaras.png")
	mini.camaras = false
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			await montar(i, 0, false)
			await get_tree().create_timer(1.0).timeout
			Captura.foto("captura-minimapa-jefe.png")
			var con_barra := [$Pantalla/Jefa.visible, lugar.visible]
			$Pantalla/Jefa.hide()   # (como al morir el jefe)
			print("Minimapa · jefe: con su barra %s, el nombre del sitio %s; sin ella, el nombre %s (esperado: true, false; true)" % [
				con_barra[0], con_barra[1], lugar.visible])
			await get_tree().create_timer(0.2).timeout
			Captura.foto("captura-minimapa-jefe-sin-barra.png")
			break
	get_tree().quit()


# Con "--captura --minimapa-hud": dónde va el minimapa (M104): abajo en el medio, con su borde de abajo a la altura del de
# la barra de vida, con dos curas y tres lanzables (captura-minimapa-hud.png); en una pantalla de 960 de ancho, donde no
# cabe en el medio y tiene que correrse o subir (-960); y en el móvil, arriba bajo la vida (-movil, M114). En cada
# una dice si pisa la parte de la vida o la de las armas. Luego se cierra
func probar_minimapa_hud() -> void:
	johnny.vida = 9999
	mochila.append_array(["vendas", "botiquin"])
	for k in ["molotov", "granada", "atraedora"]:
		lanzables.meter(k, 2)
	var hud: Control = $Pantalla/HUD
	var mini: Control = $Pantalla/Minimapa
	var ver := func(que: String) -> void:
		var mapa := mini.get_global_rect()
		var vida: Rect2 = hud.fila.get_global_rect()
		var armas: Rect2 = hud.derecha.get_global_rect()
		var barra_abajo: float = hud.barra.get_global_rect().end.y
		poner_lugar()
		print("Minimapa HUD · %s: pantalla %s, mapa %s · abajo %d, el de la barra %d · pisa la vida %s, pisa las armas %s (esperado: false, false) · arriba «%s» a %d" % [
			que, get_viewport().get_visible_rect().size, mapa, mapa.end.y, barra_abajo, mapa.intersects(vida), mapa.intersects(armas),
			lugar.text, lugar.get_theme_font_size("font_size")])
	await get_tree().create_timer(0.8).timeout
	ver.call("ancha")
	Captura.foto("captura-minimapa-hud.png")
	var ventana := get_window()   # (la pantalla de 960 × 640, con bandas a los lados)
	var antes := [ventana.content_scale_size, ventana.content_scale_aspect, ventana.content_scale_mode]
	ventana.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	ventana.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	ventana.content_scale_size = Vector2i(960, 640)
	await get_tree().create_timer(0.5).timeout
	ver.call("960")
	Captura.foto("captura-minimapa-hud-960.png")
	ventana.content_scale_size = antes[0]
	ventana.content_scale_aspect = antes[1]
	ventana.content_scale_mode = antes[2]
	await get_tree().create_timer(0.5).timeout
	Tactil.activo = true
	Tactil.con_dedo = true
	await get_tree().create_timer(0.3).timeout
	ver.call("móvil")
	Captura.foto("captura-minimapa-hud-movil.png")
	Tactil.activo = false
	get_tree().quit()


# Con "--captura --hud-movil" (M114): el HUD del móvil, con los dos modos de atacar (con Disparo asistido y con el joystick
# derecho), en la pantalla de la ventana y en una de 960 × 640, y con la barra de un jefe. Dice dónde quedan la vida (con
# sus balas encima), el minimapa, el nombre del sitio y la barra del jefe, si alguno pisa a otro o a un botón, y que las
# casillas de las armas, los lanzables y las curas no salen (están en los botones). Fotos: captura-hud-movil-<modo>.png,
# captura-hud-movil-960.png y captura-hud-movil-jefe.png. Luego se cierra
func probar_hud_movil() -> void:
	johnny.vida = 9999
	mochila.append_array(["vendas", "botiquin"])
	for k in ["molotov", "granada", "atraedora"]:
		lanzables.meter(k, 2)
	Tactil.activo = true
	Tactil.con_dedo = true
	var hud: Control = $Pantalla/HUD
	var mini: Control = $Pantalla/Minimapa
	var tactil: Tactil = find_children("*", "Tactil", true, false)[0]
	var ver := func(que: String) -> void:
		var vida: Rect2 = hud.barra.get_global_rect()
		vida = vida.grow_side(SIDE_TOP, (24.0 + hud.ALTO_ESCUDO + 6.0) * hud.ESCALA)   # (con las balas encima)
		vida.size.x = hud.ANCHO * hud.ESCALA
		var mapa := mini.get_global_rect()
		var nombre: Label = lugar
		var ancho_nombre: float = nombre.get_theme_font("font").get_string_size(nombre.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			nombre.get_theme_font_size("font_size")).x
		var texto := Rect2(nombre.global_position + Vector2((nombre.size.x - ancho_nombre) / 2.0, 0), Vector2(ancho_nombre, nombre.size.y))
		var jefa: Control = $Pantalla/Jefa
		var barra_jefe := Rect2(jefa.global_position - Vector2(0, 32), Vector2(BarraJefe.ANCHO, BarraJefe.ALTO + 32))
		var partes := {"vida": vida, "minimapa": mapa}
		if jefa.visible:
			partes["jefe"] = barra_jefe
		else:
			partes["nombre"] = texto
		var pisan := []
		var nombres := partes.keys()
		for i in nombres.size():
			for j in range(i + 1, nombres.size()):
				if partes[nombres[i]].intersects(partes[nombres[j]]):
					pisan.append("%s-%s" % [nombres[i], nombres[j]])
			for b in tactil.botones():
				var c: Vector2 = tactil.botones()[b][0]
				var r: float = tactil.botones()[b][1]
				if partes[nombres[i]].intersects(Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)):
					pisan.append("%s-botón %s" % [nombres[i], b])
		var fuera := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
		var salen := nombres.filter(func(n): return not fuera.encloses(partes[n]))
		print("HUD móvil · %s: pantalla %s · vida %s · minimapa %s · %s · letra del nombre %d" % [que, fuera.size, vida, mapa,
			("jefe %s" % barra_jefe) if jefa.visible else ("nombre «%s» %s" % [nombre.text, texto]), nombre.get_theme_font_size("font_size")])
		print("HUD móvil · %s: se pisan %s, se salen %s · casillas de armas %s, de curas %s (esperado: [], [], false, false)" % [
			que, pisan, salen, hud.derecha.visible, hud.curas.visible])
	for modo in ["asistido", "libre"]:
		johnny.poner_modo(modo)
		await get_tree().create_timer(0.5).timeout
		ver.call(modo)
		Captura.foto("captura-hud-movil-%s.png" % modo)
	# disparando: el número de balas del botón baja
	var antes: int = johnny.balas
	johnny.balas = maxi(0, antes - 3)
	await get_tree().create_timer(0.2).timeout
	print("HUD móvil · balas en el botón: %d (esperado: %d)" % [johnny.balas, maxi(0, antes - 3)])
	Captura.foto("captura-hud-movil-balas.png")
	johnny.balas = antes
	# la barra de un jefe (en su sitio, sin jefe de verdad)
	var jefa: Control = $Pantalla/Jefa
	$Pantalla/Jefa/Nombre.text = "La portera"
	jefa.show()
	await get_tree().create_timer(0.3).timeout
	ver.call("jefe")
	Captura.foto("captura-hud-movil-jefe.png")
	# en una pantalla de 960 × 640 (una tableta 3:2), también con la barra del jefe
	var ventana := get_window()
	ventana.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	ventana.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	ventana.content_scale_size = Vector2i(960, 640)
	await get_tree().create_timer(0.5).timeout
	ver.call("960 jefe")
	Captura.foto("captura-hud-movil-960-jefe.png")
	jefa.hide()
	await get_tree().create_timer(0.3).timeout
	ver.call("960")
	Captura.foto("captura-hud-movil-960.png")
	Tactil.activo = false
	await get_tree().create_timer(0.3).timeout
	print("HUD ordenador otra vez: casillas de armas %s, nombre en x %d de %d de ancho, jefe en x %d (esperado: true, 12, %d, %d)" % [
		hud.derecha.visible, lugar.position.x, lugar.size.x, jefa.position.x, 960 - 24, (960 - BarraJefe.ANCHO) / 2])
	get_tree().quit()


# Con "--captura --volver": salir de un sitio y volver lo deja como estaba (mapas de partida.gd). Un piso a medias, el
# mismo ya limpio cruzando la puerta de verdad, el pasillo, la sala del jefe, la joyería (con --edificio centro --joyeria),
# el superviviente, el incendio, la horda y la sala de pruebas; y lo que ocupa una planta entera y lo que se tarda en
# entrar. Fotos: captura-volver-antes.png y captura-volver-despues.png. Luego se cierra
func probar_volver() -> void:
	johnny.vida = 9999   # (que nadie lo tumbe a media prueba)
	var piso := eventos.piso(false)
	var sitio: Dictionary = planta.sitios[piso]
	await montar(piso, 0, false)
	await get_tree().create_timer(0.3).timeout
	var zombis := get_tree().get_nodes_in_group("zombis")
	for i in zombis.size():
		if i % 2 == 0:
			zombis[i].recibir_golpe(999999, Vector2(200, 0))
	zombis[1].dormido = false   # este va a por Johnny
	soltar_billetes(2, zombis[0].position)
	soltar_objeto("vendas", zombis[0].position + Vector2(30, 0))
	await get_tree().create_timer(1.8).timeout
	await foto_entera(sitio, "captura-volver-antes.png")
	zombis[1].destellar()   # (sale a medio destello: al volver acaba, no se queda blanco)
	await ida_y_vuelta("Piso a medias", 0)
	await get_tree().create_timer(0.3).timeout
	print("Volver · el que estaba a medio destello: %.2f (esperado: 0.00)" % zombis[1].sprite.material.get_shader_parameter("destello"))
	await foto_entera(sitio, "captura-volver-despues.png")
	# la puerta se sigue cerrando al alejarse, y se abre al acabar con todos; luego, por la puerta de verdad, con fundido
	johnny.position = sitio.zombis[0].pos
	await get_tree().create_timer(0.1).timeout
	var se_cierra := cerrada
	for z in get_tree().get_nodes_in_group("zombis"):
		z.recibir_golpe(999999, Vector2.ZERO)
	await get_tree().create_timer(0.3).timeout
	print("Volver · puerta: se cierra al alejarse %s, piso limpio %s, abierta otra vez %s (esperado: true, true, true)" % [
		se_cierra, sitio.limpio, not cerrada])
	johnny.position = mapa.puertas[0].llegada()
	await get_tree().create_timer(1.8).timeout
	var antes := foto_sitio()
	await cruzar(0)
	var fuera := aqui
	await cruzar(sitio.salidas[0].vuelta)
	var ahora := foto_sitio()
	print("Volver · piso limpio, por la puerta: pasó por el sitio %d y volvió al %d · %d vivos, %d cuerpos (antes %d), %d por el suelo (antes %d), %d de sangre (antes %d) (esperado: 0 y %d, 0 vivos, lo demás igual)" % [
		fuera, aqui, ahora.vivos.size(), ahora.cuerpos, antes.cuerpos, ahora.suelo, antes.suelo, ahora.sangre, antes.sangre, piso])
	# el pasillo: uno vivo y uno muerto (en el centro comercial, también el guardia: no puede salir otro)
	await montar(0, 0, false)
	var vivo := meter_zombi("normal", mapa.punto_libre(johnny.position, 500.0))
	var muerto := meter_zombi("normal", mapa.punto_libre(johnny.position, 500.0))
	await get_tree().physics_frame
	muerto.recibir_golpe(999999, Vector2.ZERO)
	await get_tree().create_timer(1.8).timeout
	await ida_y_vuelta("Pasillo", piso)
	vivo.queue_free()
	# el jefe, herido: el mismo, con su barra, y no sale otro ni se presenta otra vez
	var sala := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			sala = i
	await montar(sala, 0, false)
	await get_tree().create_timer(0.3).timeout   # (jugando no se puede salir nada más aparecer: la presentación lo para)
	var jefe := jefa
	jefe.vida = int(jefe.vida * 0.6)
	await ida_y_vuelta("Jefe herido", 0)
	var barra: bool = $Pantalla/Jefa.visible
	await get_tree().create_timer(JEFE_TARDA + 0.2).timeout
	print("Volver · jefe: el mismo %s, vida %d de %d, barra a la vista %s, ya había salido %s, zombis en la sala %d (esperado: true, 60 %%, true, true, 1)" % [
		is_same(jefa, jefe), jefe.vida, jefe.vida_max, barra, jefa_salio, get_tree().get_nodes_in_group("zombis").size()])
	await probar_volver_joyeria()
	await probar_volver_superviviente()
	# la sala de mantenimiento, con un arma en el suelo (la que cae al comprar otra), y las viviendas: un vecino, no dos
	await montar(planta.mantenimiento, 0, false)
	soltar_arma("bate", johnny.position + Vector2(0, 120))
	await get_tree().process_frame
	await ida_y_vuelta("Sala de mantenimiento", 0)
	var vecino: String = Supervivientes.DATOS.keys().filter(func(id): return not supervivientes.equipo.any(func(a): return a.def.id == id))[0]
	Guardado.cambiar(func(g): g.rescatados = [vecino])
	await montar(planta.viviendas, 0, false)
	await ida_y_vuelta("Viviendas", planta.mantenimiento)
	print("Volver · viviendas: %d vecinos, en el mapa %d (esperado: 1, 1)" % [supervivientes.vecinos.size(),
		mapa.cosas.get_children().filter(func(n): return n is Aliado and n.modo == "vecino").size()])
	await probar_volver_eventos()
	# la sala de pruebas siempre empieza de cero, y F9 vuelve al mismo mapa
	await montar(0, 0, false)
	var pasillo := mapa
	await pruebas()
	var guardada := mapas.has(planta.armas)
	await pruebas()
	print("Volver · sala de pruebas: se guarda %s, de vuelta en el mismo mapa %s (esperado: false, true)" % [guardada, is_same(mapa, pasillo)])
	await probar_volver_planta()
	get_tree().quit()


func probar_volver_joyeria() -> void:
	var d: Dictionary = joyeria.datos()
	if d.is_empty():
		return
	await montar(d.sitio, 0, false)
	d.dorada = "guardia"
	joyeria.soltar_dorada(mapa.punto_libre(johnny.position, 200.0))
	await get_tree().process_frame
	await ida_y_vuelta("Joyería, cerrada y con la llave dorada en el suelo", 0)
	joyeria.abrir("prueba")
	await get_tree().create_timer(0.6).timeout
	await ida_y_vuelta("Joyería, abierta y con su vitrina", 0)


# El encerrado y su puerta: cerrada (se quitan y se vuelven a poner) y abierta (la puerta se queda en el mapa). Solo en
# los Apartamentos: en el centro comercial cada uno tiene su rescate y sus pruebas (--rescate)
func probar_volver_superviviente() -> void:
	if edificio != "apartamentos":
		return
	await supervivientes.probar_aqui(false)
	var zombi := meter_zombi("normal", mapa.punto_libre(johnny.position, 400.0))
	await get_tree().process_frame
	await ida_y_vuelta("Superviviente, puerta cerrada", 0)
	print("Volver · superviviente: uno encerrado %s, puerta %s (esperado: true, true)" % [
		is_instance_valid(supervivientes.npc), is_instance_valid(supervivientes.puerta)])
	zombi.recibir_golpe(999999, Vector2.ZERO)
	await get_tree().create_timer(1.8).timeout
	await ida_y_vuelta("Superviviente, puerta abierta", 0)


# El incendio no moja dos veces y la horda sigue donde estaba, sin volver a salir por los extremos
func probar_volver_eventos() -> void:
	eventos.forzado = "incendio"
	nueva_planta(2)
	await montar(0, 0, false)
	await montar(eventos.piso(false), 0, false)
	await get_tree().create_timer(0.2).timeout
	await ida_y_vuelta("Incendio", 0)
	eventos.forzado = "horda"
	nueva_planta(2)
	await montar(0, 0, false)
	johnny.position.x = planta.sitios[0].ancho / 2.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	eventos.horda.t = 0.0
	await get_tree().create_timer(1.0).timeout
	await ida_y_vuelta("Horda", eventos.piso(false))
	print("Volver · horda: esperando a salir otra vez %d (esperado: 0)" % eventos.horda.quedan.size())
	eventos.forzado = ""


# Una planta entera guardada: lo que ocupa, lo que se tarda en entrar la primera vez y al volver, y que al subir se va todo
func probar_volver_planta() -> void:
	nueva_planta(3)
	await montar(0, 0, false)
	await get_tree().process_frame
	await get_tree().process_frame
	print("Volver · planta recién llegada: %s" % nodos_ahora())
	var pisos: Array = range(1, planta.sitios.size()).filter(func(i): return planta.sitios[i].tipo == "apartamento")
	var t := Time.get_ticks_usec()
	for i in pisos:
		await montar(i, 0, false)
	var hacer := (Time.get_ticks_usec() - t) / 1000.0 / pisos.size()
	await montar(0, 0, false)
	t = Time.get_ticks_usec()
	for i in pisos:
		await montar(i, 0, false)
	var sacar := (Time.get_ticks_usec() - t) / 1000.0 / pisos.size()
	await get_tree().process_frame
	await get_tree().process_frame
	print("Volver · %d pisos guardados: %s · entrar la primera vez %.1f ms, al volver %.1f ms" % [pisos.size(), nodos_ahora(), hacer, sacar])
	nueva_planta(4)
	await montar(0, 0, false)
	await get_tree().process_frame
	await get_tree().process_frame
	print("Volver · al subir de planta: %s, mapas guardados %d (esperado: como recién llegada, 1)" % [nodos_ahora(), mapas.size()])


# Una foto del sitio montado entero: todo descubierto, sin penumbra y con la cámara alejada para que quepa
func foto_entera(sitio: Dictionary, nombre: String, con_luz := false) -> void:
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true
		mapa.niebla[s.id] = 0.0
	mapa.actualizar_niebla(0.0)
	var camara: Camera2D = johnny.get_node("Camara")
	var pantalla := get_viewport_rect().size
	var arriba := float(sitio.get("arriba_extra", ARRIBA_EXTRA))   # (con "cajas", también el tabique de encima)
	var zoom := minf(pantalla.x / sitio.ancho, pantalla.y / (sitio.alto + arriba))
	camara.zoom = Vector2(zoom, zoom)
	camara.limit_left = -100000
	camara.limit_top = -100000
	camara.limit_right = 100000
	camara.limit_bottom = 100000
	Temblor.desplazamiento = Vector2(sitio.ancho / 2.0, (sitio.alto - arriba) / 2.0) - johnny.position
	camara.reset_smoothing()
	$Pantalla.hide()
	if not con_luz:
		Luz.apagada = not Luz.apagada   # sin penumbra, para que se vea todo (con_luz: con la luz y la penumbra del juego)
	await get_tree().create_timer(0.6).timeout
	Captura.foto(nombre)
	if not con_luz:
		Luz.apagada = not Luz.apagada
	$Pantalla.show()
	camara.zoom = Vector2.ONE
	Temblor.desplazamiento = Vector2.ZERO
	encuadrar(sitio)


# Con "--captura --edificio centro --escondites" (M81): en 200 plantas sorteadas, sin que le toque su tienda, en qué tienda
# y en qué sala se esconde el superviviente (esperado: en el aseo de cualquier tienda, no solo de las que lo tenían antes).
# Luego se cierra
func probar_escondites() -> void:
	var cuenta := {}
	var fija: Dictionary = Planta.tienda_fija
	Planta.tienda_fija = {}
	for i in 200:
		Planta.semilla = 5000 + i
		var num := 1 + i % 4
		var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
		var s: Dictionary = p.get("superviviente", {})
		var k: String = "(ninguno)" if s.is_empty() else "%s/%s" % [p.sitios[s.sitio].tienda, p.sitios[s.sitio].apt.salas[s.sala].uso]
		cuenta[k] = cuenta.get(k, 0) + 1
	Planta.semilla = 0
	Planta.tienda_fija = fija
	print("Escondites del superviviente: %s" % cuenta)
	get_tree().quit()


# Con "--captura --eventos-planta": en 200 plantas sorteadas (con el superviviente en cada una, menos en la baja), que
# nunca haya dos eventos en el mismo apartamento (superviviente, tele de las noticias y científico muerto) y cuántas
# plantas se quedan sin tele. Esperado: «repetidos 0». Luego se cierra
func probar_eventos_planta() -> void:
	var antes: int = Planta.rescate_planta
	var repetidos := 0
	var sin_tele := 0
	var sin_cientifico := 0
	for i in 200:
		Planta.semilla = 7000 + i
		var num := 1 + i % 4
		Planta.rescate_planta = num if num > 1 else 0
		var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
		var usados := []
		if Planta.rescate_planta == num and not p.superviviente.is_empty():
			usados.append(p.superviviente.sitio)
		var tele := -1
		for k in p.sitios.size():
			if p.sitios[k].has("tele"):
				tele = k
		if tele < 0:
			sin_tele += 1
		else:
			usados.append(tele)
		if p.cientifico.is_empty():
			sin_cientifico += 1
		else:
			usados.append(p.cientifico.sitio)
		var unicos := {}
		for u in usados:
			unicos[u] = true
		if unicos.size() != usados.size():
			repetidos += 1
			print("  repetido en la semilla %d (planta %d): %s" % [7000 + i, num, usados])
	Planta.semilla = 0
	Planta.rescate_planta = antes
	print("Eventos de la planta: repetidos %d · sin tele %d · sin científico %d (de 200)" % [repetidos, sin_tele, sin_cientifico])
	get_tree().quit()


# Con "--captura --edificio centro --galeria" (M77): la galería de las cuatro primeras plantas, entera y sin penumbra,
# con sus muebles puestos a mano (Catalogo.SALAS["galeria"].colocados). De cada una dice cuántos muebles tiene (esperado:
# los puestos a mano), qué hay en la pared de arriba (puertas, escaparates) y saca captura-galeria-<planta>.png (y, con
# la penumbra, para ver la luz de los neones, captura-galeria-<planta>-luz.png)
func probar_galeria() -> void:
	for num in [1, 2, 3, 4]:
		nueva_planta(num)
		await montar(0, 0, false)
		var pasillo: Dictionary = planta.sitios[0]
		johnny.position = Vector2(pasillo.ancho / 2.0, pasillo.alto / 2.0 + 64)
		await get_tree().create_timer(0.4).timeout
		print("Galería de la planta %d: muebles %d (esperado: %d) · puertas %s · escaparates %s" % [num - 1,
			get_tree().get_nodes_in_group("muebles").size(), Catalogo.SALAS.galeria.get("colocados", {}).get("abajo", []).size(),
			pasillo.salidas.map(func(s): return "%s %s %d" % [s.tipo, s.dir, s.en / Planta.CASILLA]),
			pasillo.escaparates.map(func(e): return e.x / Planta.CASILLA)])
		# entera (como foto_entera, que es para los sitios con salas)
		var camara: Camera2D = johnny.get_node("Camara")
		var zoom := minf(get_viewport_rect().size.x / pasillo.ancho, get_viewport_rect().size.y / (pasillo.alto + pasillo.arriba_extra))
		camara.zoom = Vector2(zoom, zoom)
		camara.limit_left = -100000
		camara.limit_right = 100000
		camara.limit_top = -100000
		camara.limit_bottom = 100000
		Temblor.desplazamiento = Vector2(pasillo.ancho / 2.0, (pasillo.alto - pasillo.arriba_extra) / 2.0) - johnny.position
		camara.reset_smoothing()
		# (17 nov) también con su luz, para ver la de los neones de la pared
		await get_tree().create_timer(0.6).timeout
		Captura.foto("captura-galeria-%d-luz.png" % (num - 1))
		$Pantalla.hide()
		Luz.apagada = not Luz.apagada   # sin penumbra
		await get_tree().create_timer(0.6).timeout
		Captura.foto("captura-galeria-%d.png" % (num - 1))
		Luz.apagada = not Luz.apagada
		$Pantalla.show()
		camara.zoom = Vector2.ONE
		Temblor.desplazamiento = Vector2.ZERO
	get_tree().quit()


# Con "--captura --edificio centro --puerta-super [tienda]" (17 nov): la puerta automática del supermercado (o de la tienda
# que se diga detrás: "farmacia"...) de la galería (en la primera planta que la tenga en la pared de arriba), de cerca:
# cerrada con llave (lucecita roja), con Johnny delante aún sin la llave maestra (no se abre), ya con la llave (se abre) y
# al irse (se cierra). Fotos captura-puerta-super-<paso>.png. Luego se cierra
func probar_puerta_super() -> void:
	var tienda := "supermercado"
	var args := OS.get_cmdline_user_args()
	var i_arg: int = args.find("--puerta-super") + 1
	if i_arg < args.size() and not args[i_arg].begins_with("--"):
		tienda = args[i_arg]
	var puerta: Node2D = null
	# (las tiendas salen al azar: se prueban plantas hasta dar con una)
	for intento in 24:
		var num := 1 + intento % 4
		if intento >= 4:   # (las 4 primeras plantas, con la semilla de siempre; si no sale, otras semillas)
			Planta.semilla = 1000 + intento
		if tienda == "joyeria":   # (a la joyería no la sortea nadie: se la pone en esta planta)
			Planta.joyeria_planta = num
		nueva_planta(num)
		if not planta.sitios[0].salidas.any(func(s): return s.dir == "arriba" and s.get("neon", "") == tienda):
			continue
		await montar(0, 0, false)
		for p in mapa.puertas:
			if p.salida.get("neon", "") == tienda and p.salida.dir == "arriba":
				puerta = p
		if puerta:
			print("Puerta automática de «%s»: en la planta %d" % [tienda, num - 1])
			break
	if puerta == null:
		print("ERROR DE LA PRUEBA: ninguna planta tiene «%s» en la pared de arriba" % tienda)
		get_tree().quit(1)
		return
	# (sin zombis, sin penumbra y sin el HUD, para que se vea bien la puerta)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	$Pantalla.hide()
	Luz.apagada = not Luz.apagada
	var camara: Camera2D = johnny.get_node("Camara")
	var lejos := puerta.position + Vector2(0, 200)
	# la fachada entera con lo que tiene al lado (palmeras, neones de la pared), a tamaño normal
	johnny.position = lejos
	Temblor.desplazamiento = puerta.position + Vector2(0, 40) - johnny.position
	camara.reset_smoothing()
	await get_tree().create_timer(0.6).timeout
	print("Puerta en pantalla (píxeles de la foto): ", puerta.get_global_transform_with_canvas().origin)
	Captura.foto("captura-puerta-super-fachada.png")
	camara.zoom = Vector2(3, 3)
	var delante := puerta.position + Vector2(0, 80)
	var pasos := [["cerrada", lejos, false], ["sin-llave", delante, false], ["abierta", delante, true],
		["se-cierra", lejos, true]]
	for paso in pasos:
		planta.tiene_llave = paso[2]
		actualizar_puertas()
		johnny.position = paso[1]
		Temblor.desplazamiento = puerta.position + Vector2(0, -50) - johnny.position
		camara.reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		print("Puerta del súper · %s: abierta %s · apertura %.2f" % [paso[0], puerta.abierta, puerta.apertura])
		Captura.foto("captura-puerta-super-%s.png" % paso[0])
	# a medio abrir, para ver cómo se corren las hojas
	johnny.position = delante
	Temblor.desplazamiento = puerta.position + Vector2(0, -50) - johnny.position
	await get_tree().create_timer(SUPER_MEDIO).timeout
	Captura.foto("captura-puerta-super-medio.png")
	# los neones de dentro de los escaparates (la farmacia): encendidos, cuántas veces les falla la luz, y luego los dos con
	# la luz ida
	var neones: Array = mapa.cosas.find_children("*", "Node2D", true, false).filter(func(n): return n.get_script() == preload("res://scripts/mapa/neon_galeria.gd") and not n.halo)
	if not neones.is_empty():
		var vista := puerta.position + Vector2(0, -40)
		johnny.position = puerta.position + Vector2(0, 200)
		Temblor.desplazamiento = vista - johnny.position
		camara.zoom = Vector2(2.5, 2.5)
		camara.reset_smoothing()
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-puerta-super-neones.png")
		for n in neones:
			var apagones := 0
			var antes_n := 1.0
			var ultimo_n := -99.0
			for i in 6000:
				var b: float = n.luz.brillo(i * 0.01)
				if antes_n >= 0.5 and b < 0.5 and i * 0.01 - ultimo_n > 1.0:
					apagones += 1
					ultimo_n = i * 0.01
				antes_n = b
			print("Neón %s: se le va la luz %d veces en un minuto (esperado: unas 3-6)" % [n.nombre, apagones])
			var mas_oscuro := 0.0   # (el momento del minuto en que luce menos)
			for i in 6000:
				if n.luz.brillo(i * 0.01) < n.luz.brillo(mas_oscuro):
					mas_oscuro = i * 0.01
			n.tiempo = mas_oscuro
			n.luz.tiempo = mas_oscuro
			n.set_process(false)
			n.luz.set_process(false)
			n.queue_redraw()
		await get_tree().create_timer(0.1).timeout
		Captura.foto("captura-puerta-super-neones-apagados.png")
	if not preload("res://scripts/mapa/neon.gd").CHISPAS_EN.has(tienda):   # (sin letrero con chispas: acaba aquí)
		Luz.apagada = not Luz.apagada
		$Pantalla.show()
		camara.zoom = Vector2.ONE
		Temblor.desplazamiento = Vector2.ZERO
		get_tree().quit()
		return
	# el letrero: chispas de la E caída (un chispazo a mano, para la foto) y cuántas veces se le va la luz en un minuto
	var letrero: Node2D = null
	for n in mapa.cosas.get_children():
		if n.get("tipo") == tienda and n.get("chispas") != null:
			letrero = n
	if letrero == null:
		print("ERROR DE LA PRUEBA: el letrero de «%s» no tiene chispas" % tienda)
		get_tree().quit(1)
		return
	letrero.chispazo()
	for i in 8:   # (seguidas, para ver cómo saltan y caen)
		await get_tree().create_timer(0.07).timeout
		Captura.foto("captura-puerta-super-chispas-%d.png" % i)
	var apagones := 0
	var antes := 1.0
	var ultimo := -99.0
	for i in 6000:
		var b: float = letrero.luz.brillo(i * 0.01)
		if antes >= 0.5 and b < 0.5 and i * 0.01 - ultimo > 1.0:   # (los guiños de un mismo fallo, uno solo)
			apagones += 1
			ultimo = i * 0.01
		antes = b
	print("Letrero de «%s»: chispas %d · se le va la luz %d veces en un minuto (esperado: unas 3-6)" % [
		tienda, letrero.chispas.amount, apagones])
	# y con la luz ida: el letrero y su lámpara, llevados a un momento de apagón
	var mas_oscuro := 0.0   # (el momento del minuto en que luce menos)
	for i in 6000:
		if letrero.luz.brillo(i * 0.01) < letrero.luz.brillo(mas_oscuro):
			mas_oscuro = i * 0.01
	letrero.tiempo = mas_oscuro
	letrero.luz.tiempo = mas_oscuro
	letrero.set_process(false)
	letrero.luz.set_process(false)
	letrero.queue_redraw()
	await get_tree().create_timer(0.1).timeout
	Captura.foto("captura-puerta-super-apagon.png")
	letrero.set_process(true)
	letrero.luz.set_process(true)
	Luz.apagada = not Luz.apagada
	$Pantalla.show()
	camara.zoom = Vector2.ONE
	Temblor.desplazamiento = Vector2.ZERO
	get_tree().quit()
const SUPER_MEDIO := 0.17


# Con "--captura --edificio centro --tienda-cerca" (17 nov): Johnny llega delante de cada puerta de tienda de la pared de
# abajo de la galería de la planta baja y dice qué tienda es encima de la cabeza (partida.decir_tienda); una foto por puerta
# (captura-tienda-cerca-<tipo>.png). Luego se cierra
func probar_tienda_cerca() -> void:
	await montar(0, 0, false)
	var pasillo: Dictionary = planta.sitios[0]
	for puerta in mapa.puertas:
		if puerta.salida.dir != "abajo" or puerta.salida.get("tipo", "") != "puerta":
			continue
		johnny.position = Vector2(pasillo.ancho / 2.0, pasillo.alto / 2.0 - 40)   # lejos, en medio
		await get_tree().create_timer(0.3).timeout
		johnny.position = puerta.position + Vector2(0, -70)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.35).timeout   # (el grito sube y se apaga en 1,4 s: a medio subir)
		var tipo: String = planta.sitios[puerta.salida.a].get("tienda", "")
		print("Puerta de abajo en la casilla %d: %s · dice «%s»" % [puerta.salida.en / Planta.CASILLA, tipo, aviso.text])
		Captura.foto("captura-tienda-cerca-%s.png" % tipo)
	get_tree().quit()


# Con "--captura --edificio centro --tiendas": cada tienda de las cuatro primeras plantas, entera, sin zombis, sin
# penumbra y con todo descubierto (captura-tiendas-<tipo>-<lado de su puerta>.png; la del minijefe de la planta,
# captura-tiendas-jefe-<minijefe>-<lado>.png), para ver sus habitaciones de dentro y lo que tapan sus paredes. La
# joyería, en la 1ª planta. Luego se cierra
func probar_tiendas() -> void:
	Planta.joyeria_planta = 2
	for num in [1, 2, 3, 4]:
		if num > 1:
			nueva_planta(num)
		for i in range(1, planta.sitios.size()):
			var s: Dictionary = planta.sitios[i]
			if s.get("tienda", "") == "" and s.tipo != "jefe":
				continue
			s.limpio = true   # sin zombis: aquí se mira la tienda
			await montar(i, 0, false)
			await get_tree().create_timer(0.4).timeout
			var tipo: String = "jefe-" + planta.jefe if s.tipo == "jefe" else s.tienda
			var nombre := "captura-tiendas-%s-%s.png" % [tipo, s.apt.entrada.lado]
			print("Tienda: ", s.nombre, " -> ", nombre)
			await foto_entera(s, nombre)
	get_tree().quit()


# Con "--captura --edificio centro --tiendas-fijas" (M77): las tiendas que ya tienen plano (Tienda.PLANOS), siempre
# iguales. De cada una, con la puerta abajo y arriba: si el plano está bien (Apartamento.fallos), sus salas, cuántos
# muebles lleva (los puestos a mano) y cuántos armaritos con botiquín tiene su aseo (M81), y su plano con letras. Luego la
# busca en una planta, la monta sin zombis y saca captura-fija-<tipo>-<lado>.png (entera, sin penumbra) y
# captura-fija-<tipo>-<lado>-aseo.png (Johnny en el aseo de empleados). Con "--tipo X", solo esa. Luego se cierra
func probar_tiendas_fijas() -> void:
	var args := OS.get_cmdline_user_args()
	var solo: String = args[args.find("--tipo") + 1] if "--tipo" in args else ""
	var letra := {}
	for l in Tienda.LETRAS:
		letra[Tienda.LETRAS[l].uso] = l
	for tipo in Tienda.PLANOS:
		if solo != "" and tipo != solo or not Tienda.TIPOS.has(tipo):   # (ropa-antigua: el plano viejo, solo para la torre)
			continue
		for lado in ["abajo", "arriba"]:
			var t := Tienda.generar(0, tipo, false, lado)
			var esperado: int = 0
			for s in t.salas:
				esperado += Catalogo.SALAS.get("%s-%s" % [s.uso, tipo], {}).get("colocados", {}).get(lado, []).size()
			print("Fija %s (puerta %s): %d × %d casillas, fallos %s (esperado: []) · %s" % [tipo, lado, t.cols, t.filas,
				Apartamento.fallos(Tienda.generar(0, tipo)),   # (fallos busca la entrada abajo: se mira sin voltear)
				" · ".join(t.salas.map(func(s): return "%s %d×%d" % [s.nombre, s.ancho, s.fondo]))])
			for f in t.filas:
				var linea := ""
				for c in t.cols:
					var v: int = t.dueno[f * t.cols + c]
					var entrada: bool = (c - t.entrada.c) in [0, 1] and (f < Tienda.BORDE if lado == "arriba" else f >= t.filas - Tienda.BORDE)
					linea += "E" if entrada else "#" if v == -1 else " " if v == -2 else letra[t.salas[v].uso]
				print("    " + linea)
			# la busca en una planta (las tiendas de cada puerta se sortean)
			var hallada := {}
			for i in 200:
				Planta.semilla = 3000 + i
				var num := 1 + i % 4
				var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
				for idx in p.sitios.size():
					if p.sitios[idx].get("tienda", "") == tipo and p.sitios[idx].tipo != "jefe" and p.sitios[idx].apt.entrada.lado == lado:
						hallada = {"semilla": 3000 + i, "num": num, "idx": idx}
						break
				if not hallada.is_empty():
					break
			if hallada.is_empty():
				Planta.semilla = 0
				print("Fija %s (puerta %s): no sale en ninguna planta" % [tipo, lado])
				continue
			Planta.semilla = hallada.semilla
			nueva_planta(hallada.num)
			Planta.semilla = 0
			var sitio: Dictionary = planta.sitios[hallada.idx]
			sitio.limpio = true   # sin zombis: aquí se mira la tienda
			await montar(hallada.idx, 0, false)
			await get_tree().create_timer(0.4).timeout
			print("Fija %s (puerta %s): muebles %d (esperado: %d, los puestos a mano), armaritos %s" % [tipo, lado,
				get_tree().get_nodes_in_group("muebles").size(), esperado, sitio.get("armaritos", []).map(func(a): return a.dentro)])
			# los peligros: el frío de la cámara; en la electrónica, el charco dibujado en el plano y el cuadro, en el almacén
			for pel in sitio.peligros:
				print("Fija %s (puerta %s): peligro %s%s" % [tipo, lado, pel.tipo, " de %d casillas (en el plano: %d), cuadro en %s" % [
					pel.casillas.size(), sitio.apt.get("agua", []).size(), sitio.apt.salas[pel.cuadro.sala].nombre] if pel.tipo == "agua" else ""])
			for s in sitio.apt.salas:
				if s.uso == "bano":
					johnny.position = s.centro
					johnny.get_node("Camara").reset_smoothing()
					await get_tree().create_timer(0.8).timeout
					Captura.foto("captura-fija-%s-%s-aseo.png" % [tipo, lado])
				if s.uso == "almacen":
					johnny.position = s.centro
					johnny.get_node("Camara").reset_smoothing()
					await get_tree().create_timer(0.8).timeout
					Captura.foto("captura-fija-%s-%s-almacen.png" % [tipo, lado])
			johnny.position = Vector2(sitio.ancho / 2.0, sitio.alto / 2.0)
			await foto_entera(sitio, "captura-fija-%s-%s.png" % [tipo, lado])
			# y con todas las puertas de dentro abiertas (captura-fija-<tipo>-<lado>-abiertas.png)
			for hoja in mapa.hojas:
				hoja.abrir()
			await get_tree().create_timer(1.0).timeout
			await foto_entera(sitio, "captura-fija-%s-%s-abiertas.png" % [tipo, lado])
			# y la misma con la luz del juego y Johnny delante de la puerta de entrada (captura-fija-<tipo>-<lado>-luz.png; 19 nov, el dueño)
			for p in mapa.puertas:
				johnny.position = p.position + Vector2(0, -90 if p.salida.dir == "abajo" else 150)
			await foto_entera(sitio, "captura-fija-%s-%s-luz.png" % [tipo, lado], true)
			# los muebles que se abren (Objetos.MUEBLES_CON_PIEZA; 19 nov: en la de ropa, todos los de la sala de venta, la taquilla
			# del aseo y las estanterías y cajas del almacén) y Johnny delante de la caja, con su contorno amarillo, y luego abriéndola
			# (captura-fija-<tipo>-<lado>-abrir.png y ...-abierto.png)
			var se_abren: Array = mapa.muebles.filter(func(m): return m.has_node("Zona"))
			print("Fija %s (puerta %s): se abren %d muebles: %s" % [tipo, lado, se_abren.size(),
				", ".join(se_abren.map(func(m): return m.datos.tipo))])
			for m in se_abren:
				if m.datos.tipo == "ropamostrador":
					johnny.position = m.position + Vector2(0, 30)
					johnny.get_node("Camara").reset_smoothing()
					await get_tree().create_timer(0.8).timeout
					Captura.foto("captura-fija-%s-%s-abrir.png" % [tipo, lado])
					m.usar.emit()
					await get_tree().create_timer(0.5).timeout
					Captura.foto("captura-fija-%s-%s-abierto.png" % [tipo, lado])
			# la puerta de entrada vista desde dentro, de cerca, con Johnny delante (captura-fija-<tipo>-<lado>-entrada.png; 19 nov: la
			# de ropa, la de cristal negro desde arriba, puerta.gd ABAJO_ROPA)
			$Pantalla/HUD.hide()   # (sin el marcador ni el minimapa, que tapan la puerta de abajo)
			$Pantalla/Minimapa.hide()
			for p in mapa.puertas:
				johnny.position = p.position + Vector2(0, -90 if p.salida.dir == "abajo" else 150)
				johnny.get_node("Camara").reset_smoothing()
				await get_tree().create_timer(0.8).timeout
				Captura.foto("captura-fija-%s-%s-entrada.png" % [tipo, lado])
			$Pantalla/HUD.show()
			$Pantalla/Minimapa.show()
	get_tree().quit()


# Con "--captura --edificio centro --puerta-dependienta" (--tipo X: otra tienda; si no, la de ropa): la dependienta, de
# 112 px, junto a las puertas de dentro de la tienda, para ver si su altura y la de las puertas casan. En cada puerta de
# frente, una dependienta delante (justo debajo del hueco) y Johnny a su lado, con la puerta cerrada
# (captura-puerta-dependienta-<n>.png) y luego abierta, con ella de pie dentro del hueco (...-<n>-hueco.png)
func probar_puerta_dependienta() -> void:
	var args := OS.get_cmdline_user_args()
	var tipo: String = args[args.find("--tipo") + 1] if "--tipo" in args else "ropa"
	var hallada := {}
	for i in 200:
		Planta.semilla = 3000 + i
		var num := 1 + i % 4
		var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
		for idx in p.sitios.size():
			if p.sitios[idx].get("tienda", "") == tipo and p.sitios[idx].tipo != "jefe" and p.sitios[idx].apt.entrada.lado == "abajo":
				hallada = {"semilla": 3000 + i, "num": num, "idx": idx}
				break
		if not hallada.is_empty():
			break
	if hallada.is_empty():
		Planta.semilla = 0
		print("Puerta y dependienta: %s no sale en ninguna planta" % tipo)
		get_tree().quit()
		return
	Planta.semilla = hallada.semilla
	nueva_planta(hallada.num)
	Planta.semilla = 0
	planta.sitios[hallada.idx].limpio = true   # sin zombis: los pone la prueba
	await montar(hallada.idx, 0, false)
	await get_tree().create_timer(0.4).timeout
	johnny.modo = "quieto"
	johnny.invencible = true
	johnny.direccion = "s"
	for sala in planta.sitios[hallada.idx].apt.salas:   # todo a la vista y sin penumbra, para ver bien las alturas
		mapa.vistas[sala.id] = true
		mapa.niebla[sala.id] = 0.0
	mapa.actualizar_niebla(0.0)
	$Pantalla.hide()
	Luz.apagada = not Luz.apagada
	var de_frente: Array = mapa.hojas.filter(func(h): return h.de_frente)
	print("Puerta y dependienta (%s): %d puertas de frente" % [tipo, de_frente.size()])
	for n in de_frente.size():
		var h: Node2D = de_frente[n]
		var pie := Vector2(h.caja.get_center().x, h.caja.end.y + 6)   # los pies, justo debajo del hueco
		var z: Node2D = meter_zombi("dependienta", pie)
		z.gritado = true
		z.process_mode = Node.PROCESS_MODE_DISABLED   # quieta
		z.global_position = pie
		for hijo in z.get_children():
			if hijo is CanvasItem and hijo != z.sprite and hijo.name != "Sombra":
				hijo.visible = false
		z.sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		z.sprite.play("quieto_s")
		z.visible = true
		z.sprite.visible = true
		if n == 0:   # lo alto de cada uno, en unidades, de los pies a lo más alto de su dibujo
			print("Puerta y dependienta: la hoja %s de alto, hasta el marco %s; dependienta %s; Johnny %s" % [h.alto, h.dintel,
				alto_dibujo(z.sprite), alto_dibujo(johnny.sprite)])
		johnny.position = pie + Vector2(70, 0)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		Captura.foto("captura-puerta-dependienta-%d.png" % n)
		# abierta, con ella de pie en medio del hueco
		if h.abierta < 1.0:
			h.usar_a_mano()
		await get_tree().create_timer(0.7).timeout
		z.global_position = Vector2(h.caja.get_center().x, h.caja.get_center().y + 4)
		await get_tree().create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		Captura.foto("captura-puerta-dependienta-%d-hueco.png" % n)
		z.queue_free()
		await get_tree().create_timer(0.2).timeout
	get_tree().quit()


# Lo alto de un personaje (lo que se ve de su dibujo, de lo más alto a la última fila con algo pintado), en unidades del mundo
func alto_dibujo(spr: AnimatedSprite2D) -> String:
	var tex: Texture2D = spr.sprite_frames.get_frame_texture(spr.animation, spr.frame)
	var img: Image = tex.get_image()
	if img.is_compressed():
		img.decompress()
	var usado := img.get_used_rect()
	var escala: float = spr.global_scale.y
	return "%.0f (dibujo %dx%d, con algo %d filas, escala %.1f)" % [usado.size.y * escala, img.get_width(), img.get_height(),
		usado.size.y, escala]


# El sitio de esta planta con más puertas de dentro, si tiene al menos dos (las tiendas se sortean: unas tienen dos y otras más), o -1
func piso_con_mas_puertas() -> int:
	var idx := -1
	var mas := 1
	for i in planta.sitios.size():
		var s: Dictionary = planta.sitios[i]
		var cuantas: int = s.apt.puertas.filter(func(d): return not d.get("cerrada", false)).size() if s.tipo == "apartamento" else 0
		if cuantas > mas:
			idx = i
			mas = cuantas
	return idx


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
	var idx := piso_con_mas_puertas()
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
	print("Puertas: cerradas al empezar, con su zona para abrirlas a mano %d de %d (esperado: todas)" % [
		mapa.hojas.filter(func(h): return h.uso != null).size(), mapa.hojas.size()])
	# una cerrada desde el principio, abierta a mano desde lejos (a 50, donde aún no se abre sola al arrimarse)
	var primera: Node2D = mapa.hojas[0]
	var hacia_fuera := Vector2(0, 1) if primera.de_frente else Vector2(1, 0)
	var medio0: float = (primera.caja.size.y if primera.de_frente else primera.caja.size.x) / 2
	johnny.position = primera.caja.get_center() + hacia_fuera * (medio0 + 50.0)
	await get_tree().create_timer(0.3).timeout
	var zona0: Area2D = primera.uso.get_node("Zona") if primera.uso else null
	var delante0: bool = zona0 != null and johnny.ante_mueble == zona0 and zona0.activa() and not zona0.cierra
	if zona0:
		zona0.abrir()
	await get_tree().create_timer(0.6).timeout
	print("Puertas: una cerrada desde el principio, a 50 se puede usar %s y se abre a mano %s (esperado: true las dos)" % [
		delante0, primera.abierta == 1.0])
	# (y se vuelve a cerrar, para que el resto de la prueba empiece como antes)
	primera.usar_a_mano()
	await get_tree().create_timer(0.6).timeout

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
	await probar_cerrar_puerta(una)
	await probar_atacar_ante_puerta(una)

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
	# la metálica del taller (de lado): Johnny se arrima, la abre y la cierra a mano como en el piso
	var metal: Array = mapa.hojas.filter(func(h): return h.madera == h.METAL)
	if not metal.is_empty():
		var m: Node2D = metal[0]
		johnny.position = m.caja.get_center() + (Vector2(0, m.caja.size.y / 2 + 20) if m.de_frente else Vector2(m.caja.size.x / 2 + 20, 0))
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		print("Puertas: la metálica del taller, de lado %s, se abre %s (esperado: true las dos)" % [not m.de_frente, m.abierta == 1.0])
		await probar_cerrar_puerta(m)
		Captura.foto("captura-puertas-metal-abierta.png")
	for h in mapa.hojas:
		h.abrir()
	await get_tree().create_timer(0.6).timeout
	await foto_entera(planta.sitios[sala], "captura-puertas-sala.png")
	get_tree().quit()


# De probar_puertas: Johnny, delante de la puerta que acaba de abrir, la cierra a mano como el baúl (zona_usar.gd:
# contorno amarillo y la acción de atacar); cerrada, aunque siga delante no se vuelve a abrir sola; usándola otra vez,
# se abre; cerrada otra vez, al irse y volver se abre sola; y con un zombi en el hueco no se cierra (tiembla).
# Fotos: captura-puertas-contorno.png (abierta, con el contorno) y captura-puertas-cerrada-a-mano.png
# Con "--captura --puerta-aliado": un acompañante se queda al otro lado de una puerta que Johnny ha cerrado a mano (11 nov, bloque L).
# Johnny la abre, la cierra con la médica detrás (por el lado contrario) y se queda cerca de ella, y la médica, que quiere llegar
# a él, tiene que abrirla ella. Comprueba también que, con la médica del mismo lado que Johnny, no la abre.
func probar_puerta_aliado() -> void:
	nueva_planta(2)
	johnny.invencible = true
	var idx := piso_con_mas_puertas()
	if idx < 0:
		print("Puerta del acompañante: en la 1ª planta no hay ningún sitio con dos puertas de dentro")
		get_tree().quit()
		return
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true
	await montar(idx, 0, false)
	await get_tree().create_timer(0.3).timeout
	for a in supervivientes.equipo:
		a.queue_free()
	supervivientes.equipo.clear()
	var datos: Dictionary = Supervivientes.DATOS.medico.duplicate()
	datos.erase("rescate")
	var medica: Aliado = supervivientes.crear(datos, "equipo")
	medica.idx = 0
	supervivientes.equipo.append(medica)
	johnny.get_parent().add_child(medica)
	var una: Node2D = mapa.hojas[0]
	var hacia := Vector2(0, 1) if una.de_frente else Vector2(1, 0)
	var medio: float = (una.caja.size.y if una.de_frente else una.caja.size.x) / 2
	var centro: Vector2 = una.caja.get_center()
	# 1) abierta; Johnny y la médica (quieta) del mismo lado, a 20; Johnny la cierra a mano: sigue cerrada
	una.abrir()
	await get_tree().create_timer(0.7).timeout
	johnny.position = centro + hacia * (medio + 20.0)
	medica.set_physics_process(false)
	medica.global_position = centro + hacia * (medio + 14.0) + Vector2(hacia.y, hacia.x) * 14.0
	await get_tree().create_timer(0.3).timeout
	una.usar_a_mano()
	await get_tree().create_timer(1.2).timeout
	print("Puerta del acompañante: la cierra Johnny con la médica de su lado: sigue cerrada %s (esperado: true)" % (una.abierta == 0.0))
	# 2) la médica, al otro lado, pegada a la puerta, con Johnny cerca de ella: la abre ella
	medica.global_position = centro - hacia * (medio + 14.0)
	await get_tree().create_timer(0.8).timeout
	Captura.foto("captura-puerta-aliado.png")
	print("Puerta del acompañante: médica detrás de la puerta, Johnny del otro lado: la abre %s (esperado: true)" % (una.abierta > 0.0))
	get_tree().quit()


# Delante de una puerta Johnny ataca sin tocarla (desde el 13 nov atacar solo ataca; zona_usar.gd): con J o el clic
# encima ataca y la puerta se queda como está; E la cierra y la abre; con el mando, RT solo ataca y B la usa; en
# el móvil, el joystick derecho solo ataca. Cada línea dice lo esperado
func probar_atacar_ante_puerta(una: Node2D) -> void:
	if una.uso == null:
		return
	if una.abierta < 1.0:
		una.usar_a_mano()
		await get_tree().create_timer(0.6).timeout
	johnny.position = una.caja.get_center() + (Vector2(0, una.caja.size.y / 2 + 20) if una.de_frente else Vector2(una.caja.size.x / 2 + 20, 0))
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	johnny.modo = "libre"
	johnny.con_raton = true
	Controles.con_mando = false
	# J: ataca y no la toca; E la cierra
	pulsar_accion("atacar", true)
	var al_pulsar := await ataca_en(8)
	await get_tree().create_timer(0.6, false).timeout
	var cerrada: bool = una.abierta == 1.0
	var luego := await ataca_en(10)
	pulsar_accion("atacar", false)
	print("Puertas, atacando · con J no la toca %s, ataca al pulsar %s y sigue atacando %s (esperado: true las tres)" % [
		cerrada, al_pulsar, luego])
	pulsar_accion("usar", true)
	await get_tree().physics_frame
	pulsar_accion("usar", false)
	await get_tree().create_timer(0.6, false).timeout
	print("Puertas, atacando · con E la cierra %s (esperado: true)" % (una.abierta == 0.0))
	await get_tree().create_timer(0.3, false).timeout
	# el clic encima de la puerta (ya cerrada con E): ataca y no la abre
	var zona: Area2D = una.uso.get_node("Zona") if una.uso else null
	var sobre: Vector2 = zona.dibujo.get_global_transform() * zona.dibujo.get_rect().get_center() if zona and zona.dibujo else una.caja.get_center()
	clic_raton(sobre, true)
	al_pulsar = await ataca_en(8)
	await get_tree().create_timer(0.6, false).timeout
	var abierta: bool = una.abierta == 0.0
	luego = await ataca_en(10)
	clic_raton(sobre, false)
	print("Puertas, atacando · con el clic encima no la abre %s, ataca al pulsar %s y sigue atacando %s (esperado: true las tres)" % [
		abierta, al_pulsar, luego])
	pulsar_accion("usar", true)
	await get_tree().physics_frame
	pulsar_accion("usar", false)
	await get_tree().create_timer(0.6, false).timeout
	await get_tree().create_timer(0.3, false).timeout
	# el mando: RT ataca y no la toca; B la cierra
	Controles.con_mando = true
	pulsar_accion("atacar", true)
	al_pulsar = await ataca_en(8)
	await get_tree().create_timer(0.6, false).timeout
	var sin_tocar: bool = una.abierta == 1.0
	pulsar_accion("atacar", false)
	await get_tree().create_timer(0.2, false).timeout
	pulsar_accion("usar", true)
	await get_tree().physics_frame
	pulsar_accion("usar", false)
	await get_tree().create_timer(0.6, false).timeout
	print("Puertas, atacando · con el mando RT ataca %s sin tocarla %s y B la cierra %s (esperado: true las tres)" % [
		al_pulsar, sin_tocar, una.abierta == 0.0])
	Controles.con_mando = false
	# el móvil: el joystick derecho ataca delante de ella (cerrada, y abierta) y no la toca
	var antes := [Tactil.activo, Tactil.con_dedo]
	Tactil.activo = true
	Tactil.con_dedo = true
	johnny.con_raton = false
	una.usar_a_mano()
	await get_tree().create_timer(0.6, false).timeout
	Input.action_press("apuntar_derecha", 1.0)
	al_pulsar = await ataca_en(10)
	sin_tocar = una.abierta == 1.0
	Input.action_release("apuntar_derecha")
	Tactil.activo = antes[0]
	Tactil.con_dedo = antes[1]
	johnny.con_raton = true
	print("Puertas, atacando · en el móvil, delante de ella abierta, el joystick derecho ataca %s y no la toca %s (esperado: true las dos)" % [
		al_pulsar, sin_tocar])
	await get_tree().create_timer(0.3, false).timeout


# Una acción como si se pulsara (o soltara) su tecla o botón: un evento de acción, como los botones del móvil (tactil.gd)
func pulsar_accion(nombre: String, abajo: bool) -> void:
	var e := InputEventAction.new()
	e.action = nombre
	e.pressed = abajo
	e.strength = 1.0 if abajo else 0.0
	Input.parse_input_event(e)


# Si Johnny ataca en los próximos "pasos" pasos de física (el hueco entre ataques, a cero antes, para que se note)
func ataca_en(pasos: int) -> bool:
	johnny.espera = 0.0
	johnny.ataque_t = -1.0
	for n in pasos:
		await get_tree().physics_frame
		if johnny.espera > 0.0 or johnny.ataque_t >= 0.0:
			return true
	return false


func probar_cerrar_puerta(una: Node2D) -> void:
	# (los compañeros de Johnny, quietos y lejos: si se quedan en el hueco al seguirle, con razón no se cierra)
	var aliados := get_tree().get_nodes_in_group("aliados")
	for a in aliados:
		a.set_physics_process(false)
		a.position = johnny.position + (johnny.position - una.caja.get_center()).normalized() * 200.0
	var zona: Area2D = una.uso.get_node("Zona") if una.uso else null
	await get_tree().create_timer(0.2).timeout
	print("Puertas, cerrar: tiene zona %s, Johnny delante %s, se puede usar %s, el botón dice «Cerrar» %s (esperado: true las cuatro)" % [
		zona != null, zona != null and johnny.ante_mueble == zona, zona != null and zona.activa(), zona != null and zona.cierra])
	if zona == null:
		return
	Captura.foto("captura-puertas-contorno.png")
	zona.abrir()   # (lo mismo que el clic, J, RT o el botón del móvil)
	await get_tree().create_timer(0.6).timeout
	var choca := una.get_children().any(func(h): return h is CollisionShape2D and not h.disabled)
	print("Puertas, cerrar: se cierra %s, choca %s, apuntada cerrada en su hueco %s (esperado: true las tres)" % [
		una.abierta == 0.0, choca, not una.hueco.get("abierta", true)])
	Captura.foto("captura-puertas-cerrada-a-mano.png" if una.de_frente else "captura-puertas-metal-cerrada.png")
	await get_tree().create_timer(0.5).timeout
	print("Puertas, cerrar: con Johnny aún delante sigue cerrada %s (esperado: true)" % (una.abierta == 0.0))
	# usarla otra vez, sin moverse: se abre
	zona = una.uso.get_node("Zona") if una.uso else null
	await get_tree().create_timer(0.2).timeout
	if zona:
		zona.abrir()
	await get_tree().create_timer(0.6).timeout
	print("Puertas, cerrar: usándola otra vez se abre %s (esperado: true)" % (una.abierta == 1.0))
	# cerrada otra vez, Johnny se va lejos y vuelve: se abre sola
	await get_tree().create_timer(0.2).timeout
	una.usar_a_mano()
	await get_tree().create_timer(0.6).timeout
	var delante: Vector2 = johnny.position
	johnny.position = delante + (delante - una.caja.get_center()).normalized() * 120.0
	await get_tree().create_timer(0.3).timeout
	var cerrada_lejos: bool = una.abierta == 0.0
	johnny.position = delante
	await get_tree().create_timer(0.6).timeout
	print("Puertas, cerrar: cerrada otra vez %s, al irse y volver se abre sola %s (esperado: true las dos)" % [
		cerrada_lejos, una.abierta == 1.0])
	# un zombi (dormido, quieto) en el hueco: no se cierra, tiembla
	var zombi: Node2D = meter_zombi("lento", una.caja.get_center())
	zombi.dormido = true
	await get_tree().create_timer(0.2).timeout
	una.usar_a_mano()
	var tiembla: bool = una.golpes > 0.0
	await get_tree().create_timer(0.6).timeout
	print("Puertas, cerrar: con un zombi en el hueco sigue abierta %s y tiembla %s (esperado: true las dos)" % [
		una.abierta == 1.0, tiembla])
	zombi.queue_free()
	# más lejos, a 50 del hueco (fuera de donde se abre arrimándose): también se cierra a mano, y se vuelve a abrir
	await get_tree().create_timer(0.2).timeout
	var medio: float = (una.caja.size.y if una.de_frente else una.caja.size.x) / 2
	johnny.position = una.caja.get_center() + (delante - una.caja.get_center()).normalized() * (medio + 50.0)
	await get_tree().create_timer(0.3).timeout
	zona = una.uso.get_node("Zona") if una.uso else null
	var lejos_delante: bool = zona != null and johnny.ante_mueble == zona and zona.activa()
	if zona:
		zona.abrir()
	await get_tree().create_timer(0.6).timeout
	var lejos_cierra: bool = una.abierta == 0.0
	una.usar_a_mano()
	await get_tree().create_timer(0.6).timeout
	print("Puertas, cerrar: a 50 del hueco se puede usar %s, se cierra %s y se vuelve a abrir %s (esperado: true las tres)" % [
		lejos_delante, lejos_cierra, una.abierta == 1.0])
	# la de lado: junto a la parte de arriba de la hoja abierta (que se queda de pie por encima del hueco), también
	if not una.de_frente:
		# (del lado de la hoja: la del taller se abre hacia la izquierda, "al_reves")
		johnny.position = Vector2(una.caja.position.x - 24.0 if una.al_reves else una.caja.end.x + 24.0, una.caja.position.y - 70.0)
		await get_tree().create_timer(0.3).timeout
		zona = una.uso.get_node("Zona") if una.uso else null
		var arriba_delante: bool = zona != null and johnny.ante_mueble == zona and zona.activa()
		if zona:
			zona.abrir()
		await get_tree().create_timer(0.6).timeout
		var arriba_cierra: bool = una.abierta == 0.0
		una.usar_a_mano()
		await get_tree().create_timer(0.6).timeout
		print("Puertas, cerrar: de lado, junto a lo alto de la hoja se puede usar %s, se cierra %s y se vuelve a abrir %s (esperado: true las tres)" % [
			arriba_delante, arriba_cierra, una.abierta == 1.0])
	johnny.position = delante
	for a in aliados:
		a.set_physics_process(true)
	await get_tree().create_timer(0.1).timeout


# Con "--captura --atasco-puertas": varios zombis de cada tipo (--zombis N, 18 si no se dice) salen a la vez por una misma
# puerta de un piso, por cada lado de cada puerta con más salas detrás. Dos vueltas: sin ver a Johnny, que está en la
# sala más lejana (empiezan con la puerta cerrada y la abren ellos; tienen que pasar todos), y viéndole, con la puerta ya
# abierta y él enfrente (el venenoso y el de tentáculos se quedan a distancia a propósito, pero no en el hueco: tienen
# que pasar los demás). Cuenta cuántos pasan y el parón mayor: lo más que está la puerta abierta sin que pase nadie. Foto
# del grupo en la puerta (captura-atasco-puertas.png). Va a toda prisa (ATASCO_RITMO). Luego se cierra
const ATASCO_TIPOS := ["normal", "venenoso", "tentaculos", "lento", "explosivo", "rapido"]
const ATASCO_DE_LEJOS := ["venenoso", "tentaculos"]
const ATASCO_RITMO := 8.0
const ATASCO_TOPE := 40.0

func probar_atasco() -> void:
	nueva_planta(2)
	johnny.invencible = true
	johnny.invulnerable = 1.0   # (quieto, no se le gasta: que sus golpes no paren el tiempo de la prueba)
	johnny.set_physics_process(false)   # (quieto: que no los mate ni gaste las balas él solo en el modo asistido)
	var idx := piso_con_mas_puertas()
	var sitio: Dictionary = planta.sitios[idx]
	var apt: Dictionary = sitio.apt
	sitio.limpio = true   # sin zombis: los pone la prueba
	var cuantos := int(Captura.dato("--zombis", "18"))
	Engine.time_scale = ATASCO_RITMO
	for visto in [false, true]:
		var cuenta := {"total": 0, "pasan": 0, "paron": 0.0, "foto": not visto}
		for n in apt.puertas.size():
			if apt.puertas[n].get("cerrada", false):
				continue
			for lado in [1.0, -1.0]:
				for d in apt.puertas:
					d.abierta = false
				apt.puertas[n].abierta = visto
				await montar(idx, 0, false)
				await get_tree().create_timer(1.0).timeout   # (a que esté listo el mapa de caminos del sitio nuevo)
				var hoja: Node2D = mapa.hojas.filter(func(h): return h.hueco == apt.puertas[n])[0]
				await atasco_en(hoja, lado, cuantos, visto, cuenta)
		print("Atasco, %s: pasan %d de %d, parón mayor %.1f s (esperado: todos, y menos de 6 s)" % [
			"viendo a Johnny" if visto else "sin ver a Johnny", cuenta.pasan, cuenta.total, cuenta.paron])
	Engine.time_scale = 1.0
	get_tree().quit()


# Una tanda de probar_atasco: el grupo, al lado "lado" de la puerta, y los que van pasando al otro se quitan de en medio
func atasco_en(hoja: Node2D, lado: float, cuantos: int, visto: bool, cuenta: Dictionary) -> void:
	var hacia := Vector2(0, lado) if hoja.de_frente else Vector2(lado, 0)
	var a_lo_largo := hacia.orthogonal()
	var medio: float = absf(hoja.caja.size.dot(hacia)) / 2
	var centro: Vector2 = hoja.caja.get_center()
	var red := get_world_2d().navigation_map
	var salas: Array = planta.sitios[aqui].apt.salas
	var aca: int = mapa.zona_en(centro + hacia * (medio + 30))
	var alla: int = mapa.zona_en(centro - hacia * (medio + 30))
	if salas[alla].puertas.size() < 2:
		return   # (un baño: sin más salas detrás, Johnny estaría a la vista)
	var donde: Vector2 = centro - hacia * (medio + 124) if visto else sala_mas_lejana(alla, hoja.hueco, centro)
	johnny.position = NavigationServer2D.map_get_closest_point(red, donde)
	johnny.get_node("Camara").reset_smoothing()
	var puestos := []
	for fila in 8:
		for col in 7:
			var p: Vector2 = centro + hacia * (medio + 44 + fila * 40) + a_lo_largo * ((col - 3) * 40 + (fila % 2) * 12)
			if mapa.zona_en(p) != aca:
				continue
			p = NavigationServer2D.map_get_closest_point(red, p)
			if puestos.size() < cuantos and puestos.all(func(o): return o.distance_to(p) > 36.0):
				puestos.append(p)
	puestos.shuffle()
	var quedan := []
	for i in puestos.size():
		quedan.append(meter_zombi(ATASCO_TIPOS[i % ATASCO_TIPOS.size()], puestos[i]))
	var todos := quedan.duplicate()
	var cuentan := func(z: Node2D) -> bool:
		return not visto or z.get_meta("tipo") not in ATASCO_DE_LEJOS
	var deben := 0
	for z in todos:
		if cuentan.call(z):
			deben += 1
	var t := 0.0
	var ultimo := 0.0   # cuándo ha pasado el último (o cuándo se ha abierto la puerta)
	while t < ATASCO_TOPE and quedan.any(cuentan):
		await get_tree().create_timer(0.2, true, true).timeout   # (en pasos de física: a toda prisa, un fotograma lento no les come tiempo)
		t += 0.2
		if hoja.abierta == 0.0:
			ultimo = t
		cuenta.paron = maxf(cuenta.paron, t - ultimo)
		if not cuenta.foto and t >= 5.0:
			cuenta.foto = true
			for s in salas:
				mapa.vistas[s.id] = true
				mapa.niebla[s.id] = 0.0
			mapa.actualizar_niebla(0.0)
			Captura.foto("captura-atasco-puertas.png")
		for z in quedan.duplicate():
			if z.estado == "muerto":
				quedan.erase(z)
				if cuentan.call(z):
					deben -= 1   # (un explosivo que ha reventado, por ejemplo: ya no tiene que pasar)
			elif mapa.zona_en(z.global_position) == alla and z.global_position.distance_to(centro) > medio + 44:
				quedan.erase(z)
				if cuentan.call(z):
					cuenta.pasan += 1
					ultimo = t
				z.agente.avoidance_enabled = false
				z.position = Vector2(-9000, -9000)
				z.process_mode = Node.PROCESS_MODE_DISABLED
	cuenta.total += deben
	var se_quedan: Array = quedan.filter(cuentan).map(func(z): return "%s %s %s" % [z.get_meta("tipo"), (z.global_position - centro).round(), z.estado])
	if not se_quedan.is_empty():
		print("Atasco: en %s, por el lado %+d, se quedan %s" % [centro, int(lado), se_quedan])
	await get_tree().create_timer(2.0).timeout   # (a que caigan los escupitajos: el charco lleva quién lo escupió)
	for z in todos:
		z.queue_free()


# La sala más lejana a la que se llega desde "sala" sin pasar por el hueco "hueco" (donde se pone a Johnny para que nadie le vea)
func sala_mas_lejana(sala: int, hueco: Dictionary, desde: Vector2) -> Vector2:
	var salas: Array = planta.sitios[aqui].apt.salas
	var mejor: Vector2 = salas[sala].centro
	var pila := [sala]
	var vistas := [sala]
	while not pila.is_empty():
		for d in salas[pila.pop_back()].puertas:
			if d == hueco or d.get("cerrada", false):
				continue
			for otra in [d.a, d.b]:
				if otra not in vistas:
					vistas.append(otra)
					pila.append(otra)
					if salas[otra].centro.distance_to(desde) > mejor.distance_to(desde):
						mejor = salas[otra].centro
	return mejor


# Con "--captura --viviendas": las viviendas de los supervivientes rescatados (mapa/viviendas.gd), detrás de la puerta
# de la derecha de la sala de mantenimiento. Entrar, las puertas cerradas y abiertas, cada uno en su habitación,
# acompañar y volver, y desde la 1ª planta por el ascensor (supervivientes.gd: probar_viviendas); luego los seis a la
# vez. Cada línea de la terminal dice lo esperado. Deja el guardado
# como estaba y se cierra
# Con "--captura --edificio torre --programador": el informático joven (copia.gd)
func probar_programador() -> void:
	await get_tree().create_timer(0.3).timeout
	await supervivientes.copia.probar()
	get_tree().quit()


# Con "--captura --edificio torre --limpiadora": la limpiadora de noche (valvulas.gd)
func probar_limpiadora() -> void:
	await get_tree().create_timer(0.3).timeout
	await supervivientes.valvulas.probar()
	get_tree().quit()


# Con "--captura --edificio torre --recepcionista": la recepcionista (tornos.gd)
func probar_recepcionista() -> void:
	await get_tree().create_timer(0.3).timeout
	await supervivientes.tornos.probar()
	get_tree().quit()


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
# (captura-sala-vestuario.png, captura-sala-despacho.png y captura-sala-taller.png). Luego se pone delante del banco, de
# la estantería y del baúl y cuenta cuál se usaría (y, con la puerta del taller abierta, que delante del banco se usa
# el banco); comprueba que los muebles se abren con el clic y no al arrimarse
# (probar_abrir_muebles); cruza la puerta de las viviendas, vuelve y sale al pasillo, y cuenta
# adónde ha llegado cada vez. Luego se cierra
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
	# el banco y el baúl, con la estantería en medio: delante de cada sitio, qué se usaría
	var en_zona := func(m: Node) -> bool: return johnny.ante_mueble == m.zona
	for n in [["banco", mapa.banco.position.x], ["estantería", 918.0], ["baúl", mapa.baul.position.x]]:
		johnny.position = Vector2(n[1], mapa.MURO + 36.0 + 22.0)
		await get_tree().create_timer(0.1).timeout
		print("Delante de: %s · se usaría: banco %s, baúl %s" % [n[0], en_zona.call(mapa.banco), en_zona.call(mapa.baul)])
	# con la puerta del despacho al taller abierta (su hoja se queda de pie junto al banco): delante del banco se usa el
	# banco, y apartado del banco, junto a la puerta, la puerta
	var metal: Node = null
	for h in mapa.hojas:
		if h.madera == mapa.PUERTA_BANO.METAL:
			metal = h
	if metal:
		metal.usar_a_mano()
		await get_tree().create_timer(0.8).timeout
		johnny.position = Vector2(mapa.banco.position.x, mapa.MURO + 36.0 + 22.0)
		await get_tree().create_timer(0.1).timeout
		var zona_puerta: Node = metal.uso.get_node("Zona") if metal.uso else null
		print("Puerta del taller abierta, delante del banco · se usaría: banco %s, puerta %s (esperado: true, false)" % [
			en_zona.call(mapa.banco), zona_puerta != null and johnny.ante_mueble == zona_puerta])
		johnny.position = Vector2(metal.caja.position.x - 24.0, metal.caja.get_center().y)   # (del lado del despacho, el de la hoja)
		await get_tree().create_timer(0.1).timeout
		zona_puerta = metal.uso.get_node("Zona") if metal.uso else null
		print("Puerta del taller abierta, junto al hueco · se usaría: banco %s, puerta %s (esperado: false, true)" % [
			en_zona.call(mapa.banco), zona_puerta != null and johnny.ante_mueble == zona_puerta])
		# (y su contorno amarillo, encima de la hoja abierta: captura-sala-puerta-taller.png)
		await get_tree().create_timer(0.2).timeout
		Captura.foto("captura-sala-puerta-taller.png")
		# a 80 del hueco, del lado del taller (con la zona más amplia, también se usa)
		johnny.position = Vector2(metal.caja.end.x + 80.0, metal.caja.get_center().y)
		await get_tree().create_timer(0.1).timeout
		print("Puerta del taller abierta, a 80 del hueco por el taller · se usaría la puerta %s (esperado: true)" % [
			zona_puerta != null and johnny.ante_mueble == zona_puerta])
		metal.usar_a_mano()
		await get_tree().create_timer(0.8).timeout
	await probar_abrir_muebles(usables)
	# las dos puertas de fuera: a las viviendas (y vuelta, por la misma) y al pasillo
	await cruzar(1)
	print("Por la puerta de la derecha: en «%s» (esperado: viviendas)" % planta.sitios[aqui].tipo)
	await cruzar(0)
	print("De vuelta: en «%s», en el %s (esperado: mantenimiento, taller)" % [planta.sitios[aqui].tipo,
		mapa.nombre_zona(mapa.zona_en(johnny.position)).to_lower()])
	await cruzar(0)
	print("Por la puerta de abajo: en «%s» (esperado: pasillo)" % planta.sitios[aqui].tipo)
	get_tree().quit()


# Con "--captura --marcas-sala": los «!» de la sala de mantenimiento en la primera partida (mapa.marcas_sala). Al
# empezar, los cinco a la vista (captura-marcas-sala.png); la puerta del pasillo no deja salir y Johnny dice
# «¡MEJOR INVESTIGO UN POCO MÁS!» (captura-marcas-no-sale.png), sin flecha de la guía. Luego abre la taquilla,
# el banco y el baúl (cada uno, su tutorial; el del banco en captura-marcas-tutorial-banco.png) y el ordenador, cuyo
# «!» sigue mientras haya algo nuevo dentro: abre cada programa, con su tutorial (captura-marcas-escritorio.png y
# captura-marcas-tutorial-talentos.png), hasta que no queda ningún «!» en los iconos; entra en los trasteros (su tutorial nuevo: captura-marcas-trasteros.png) y
# vuelve. Sin ningún «!» que falte, sale la flecha (captura-marcas-flecha.png) y ya se sale al pasillo. Hay un enemigo
# nuevo sin mirar en Sujetos: su «!» se queda en Colecciones y en la mesa del ordenador, pero no impide salir (L37,
# ordenador.falta_ver). Luego se cierra
func probar_marcas_sala() -> void:
	var nuevos_antes: Array = Guardado.cargar().sujetos_nuevos.duplicate()
	Guardado.cambiar(func(g): g.sujetos_nuevos = [Bestiario.LISTA.keys()[0]])
	var nombres := ["taquilla", "ordenador", "banco", "baúl", "trasteros"]
	var activas := func() -> String:
		var lista := []
		for i in mapa.marcas_sala.size():
			mapa.marcas_sala[i].refrescar()
			if mapa.marcas_sala[i].activa:
				lista.append(nombres[i])
		return ", ".join(lista) if not lista.is_empty() else "ninguno"
	await get_tree().create_timer(1.2).timeout
	print("Guía activa: %s · «!» en la sala: %s (esperado: true; los cinco)" % [guia.activa, activas.call()])
	johnny.direccion = "s"
	Captura.foto("captura-marcas-sala.png")
	await cruzar(0)
	await get_tree().create_timer(0.3).timeout
	print("Al ir al pasillo: sigue en «%s» · flecha %s (esperado: mantenimiento, false)" % [planta.sitios[aqui].tipo,
		guia.flecha.visible])
	Captura.foto("captura-marcas-no-sale.png")
	# la taquilla, el banco y el baúl, como con el clic: sale su tutorial y, al cerrarlo, su pantalla
	await usar_con_tutorial(abrir_taquilla, taquilla.cerrar, "taquilla")
	await usar_con_tutorial(abrir_cosas.bind("banco"), inventario.cerrar, "banco", "captura-marcas-tutorial-banco.png")
	await usar_con_tutorial(abrir_cosas.bind("baul"), inventario.cerrar, "baul")
	await usar_con_tutorial(abrir_ordenador, ordenador.apagar, "ordenador")
	print("Tras abrir taquilla, banco, baúl y ordenador, «!»: %s (esperado: ordenador, trasteros: aún hay algo nuevo dentro)" % activas.call())
	# dentro del ordenador: cada icono lleva su «!» hasta ver su tutorial, que sale al abrir el programa la primera vez
	abrir_ordenador()
	await get_tree().create_timer(1.0).timeout
	var con_marca := func() -> String:
		var lista := []
		for i in ordenador.ICONOS:
			var b: Node = ordenador.iconos.get_node_or_null("icono_" + i[0])
			if b and b.get_node_or_null("marca_nuevo"):
				lista.append(i[0])
		return ", ".join(lista) if not lista.is_empty() else "ninguno"
	print("En el escritorio, iconos con «!»: %s (esperado: puntos, armas, logros, dosier, colecciones, videos)" % con_marca.call())
	Captura.foto("captura-marcas-escritorio.png")
	var vistos := []
	for programa in ["puntos", "armas", "logros", "dosier", "colecciones", "videos"]:
		ordenador.abrir(programa)
		await get_tree().create_timer(0.6).timeout
		var tuto := ventana_tutorial()
		vistos.append(tuto.id if tuto else "ninguno")
		if programa == "puntos":
			Captura.foto("captura-marcas-tutorial-talentos.png")
		if tuto:
			tuto.cerrar()
		await get_tree().create_timer(0.6).timeout
		if programa == "puntos":
			print("Visto el de Talentos, iconos con «!»: %s (esperado: armas, logros, dosier, colecciones, videos)" % con_marca.call())
	ordenador.abrir("")
	await get_tree().create_timer(0.3).timeout
	print("Al abrir cada programa, su tutorial: %s (esperado: talentos, tienda, logros, dosier, colecciones, videos) · iconos con «!»: %s (esperado: colecciones, el enemigo sin mirar)" % [
		", ".join(vistos), con_marca.call()])
	Captura.foto("captura-marcas-escritorio-sin.png")
	ordenador.apagar()
	await get_tree().create_timer(0.3).timeout
	print("Visto lo de dentro del ordenador, «!»: %s · ¿le falta ver algo al ordenador? %s (esperado: ordenador, trasteros · false: el de Sujetos no cuenta)" % [
		activas.call(), mapa.ordenador.falta_ver(Guardado.cargar())])
	await cruzar(0)
	print("Al ir al pasillo otra vez: sigue en «%s» (esperado: mantenimiento)" % planta.sitios[aqui].tipo)
	# los trasteros: al entrar, su tutorial
	await cruzar(1)
	await get_tree().create_timer(1.0).timeout
	var ventana := ventana_tutorial()
	print("En «%s»: tutorial «%s» (esperado: viviendas, trasteros)" % [planta.sitios[aqui].tipo, ventana.id if ventana else "ninguno"])
	Captura.foto("captura-marcas-trasteros.png")
	if ventana:
		ventana.cerrar()
	await get_tree().create_timer(0.4).timeout
	await cruzar(0)
	await get_tree().create_timer(1.2).timeout
	print("De vuelta en «%s», «!»: %s · falta algo: %s · flecha %s (esperado: mantenimiento, ordenador (el de Sujetos), false, true)" % [
		planta.sitios[aqui].tipo, activas.call(), falta_sala(), guia.flecha.visible])
	Captura.foto("captura-marcas-flecha.png")
	for i in mini(planta.sitios[aqui].salidas.size(), mapa.puertas.size()):
		if planta.sitios[aqui].salidas[i].get("a", -1) == 0:
			await cruzar(i)
	print("Por la puerta del pasillo: en «%s» (esperado: pasillo)" % planta.sitios[aqui].tipo)
	Guardado.cambiar(func(g): g.sujetos_nuevos = nuevos_antes)
	get_tree().quit()


# Con "--captura --regalo": Johnny empieza solo con la fregona (Armas.SIEMPRE) y sin lanzables (15 nov), y la puerta del
# pasillo no deja salir sin el regalo de bienvenida. En el ordenador, ARMAS.EXE con su «!» (captura-regalo-escritorio.png);
# al abrir la tienda, su tutorial (captura-regalo-tutorial.png); luego la tienda con «¡COMPRA UN ARMA!» y el «!» en la
# pistola, el molotov, la granada y la atraedora (captura-regalo-tienda.png) y la ficha de la pistola, «Regalo de
# bienvenida» (captura-regalo-ficha.png). Se cogen gratis: van al baúl (con el primer lanzable, su tutorial:
# captura-regalo-lanzables.png); ya cuestan lo de siempre (captura-regalo-comprada.png). El baúl, con su «!»; al abrirlo
# se quita y se saca todo; al cerrarlo, «Cambiar de arma» (captura-regalo-cambiar-arma.png). Sin «!», se sale al pasillo
func probar_regalo() -> void:
	var guardado_antes := Guardado.cargar()
	Guardado.cambiar(func(g):   # (con el baúl vacío, como en la primera partida: lo de otras pruebas no cabría)
		g.baul = {}
		g.baul_equipo = [])
	await get_tree().create_timer(1.2).timeout
	print("Al empezar: huecos %s · lanzables %s · regalo cogido %s · «!» del ordenador %s (esperado: fuego vacío, [], false, true)" % [
		johnny.huecos, lanzables.montones(), Guardado.cargar().regalo_cogido, mapa.ordenador.marca.activa])
	await cruzar(0)
	print("Al ir al pasillo sin el regalo: sigue en «%s» (esperado: mantenimiento)" % planta.sitios[aqui].tipo)
	get_tree().paused = true
	ordenador.encender(self)
	await get_tree().create_timer(1.0).timeout
	var icono: Node = ordenador.iconos.get_node_or_null("icono_armas")
	print("ARMAS.EXE con su «!»: %s (esperado: true)" % (icono != null and icono.get_node_or_null("marca_nuevo") != null))
	Captura.foto("captura-regalo-escritorio.png")
	ordenador.abrir("armas")
	await get_tree().create_timer(0.6).timeout
	var ventana := ventana_tutorial()
	print("Al abrir la tienda: tutorial «%s» (esperado: tienda)" % (ventana.id if ventana else "ninguno"))
	Captura.foto("captura-regalo-tutorial.png")
	if ventana:
		ventana.cerrar()
	await get_tree().create_timer(0.6).timeout
	var tienda: Node = ordenador.ventana.find_child("tienda", true, false) if ordenador.ventana else null
	if tienda == null:
		print("ERROR DE LA PRUEBA: no se ha abierto la tienda")
		get_tree().quit(1)
		return
	var marcas: Array = tienda.regalos_a_la_vista()
	marcas.sort()
	print("Tienda sin nada elegido: ficha «%s» · «!» en %s (esperado: «», [atraedora, granada, molotov, pistola])" % [tienda.ficha_id, marcas])
	Captura.foto("captura-regalo-tienda.png")
	tienda.ficha_id = "pistola"
	tienda.comprar.visible = true
	tienda.queue_redraw()
	await get_tree().create_timer(0.3).timeout
	print("Ficha de la pistola: «%s» (esperado: Regalo de bienvenida)" % tienda.texto_comprar("pistola"))
	Captura.foto("captura-regalo-ficha.png")
	var antes: int = Guardado.cargar().dolares
	tienda.comprar_esto("pistola")
	await get_tree().create_timer(0.6).timeout
	ventana = ventana_tutorial()
	print("Coge la pistola: dice «%s» · tutorial «%s» · en el hueco de fuego «%s» (esperado: ¡Regalo! Pistola va al baúl..., ninguno, «»)" % [
		ordenador.info.text, ventana.id if ventana else "ninguno", johnny.huecos.fuego])
	print("ARMAS.EXE aún con «!»: %s (esperado: true, quedan los lanzables)" % (
		ordenador.iconos.get_node_or_null("icono_armas").get_node_or_null("marca_nuevo") != null))
	ordenador.comprar_lanzable("molotov")
	await get_tree().create_timer(0.9, true).timeout
	ventana = ventana_tutorial()
	print("Coge el molotov: tutorial «%s» (esperado: lanzables)" % (ventana.id if ventana else "ninguno"))
	Captura.foto("captura-regalo-lanzables.png")
	if ventana:
		ventana.cerrar()
	await get_tree().create_timer(0.6).timeout
	ordenador.comprar_lanzable("granada")
	await get_tree().process_frame
	ordenador.comprar_lanzable("atraedora")
	await get_tree().create_timer(0.3).timeout
	var s := Guardado.cargar()
	tienda = ordenador.ventana.find_child("tienda", true, false)
	print("Cogido: dólares %d → %d · regalo cogido %s · lanzables del regalo %s · dice «%s» (esperado: iguales, true, los 3, ¡Regalo! Atraedora va al baúl (tienes 1 allí).)" % [
		antes, s.dolares, s.regalo_cogido, s.regalos_lanzables, ordenador.info.text])
	print("En el baúl: %s (esperado: pistola, molotov ×1, granada ×1, atraedora ×1)" % [
		s.baul_equipo.map(func(e): return "%s%s" % [e.id, " ×%d" % e.n if e.has("n") else ""])])
	print("Ahora cuestan: pistola $%d, molotov $%d, atraedora $%d · «!» %s · ARMAS.EXE con «!» %s (esperado: 25, 5, 10, [], false)" % [
		tienda.precio("pistola"), tienda.precio("molotov"), tienda.precio("atraedora"), tienda.regalos_a_la_vista(),
		ordenador.iconos.get_node_or_null("icono_armas").get_node_or_null("marca_nuevo") != null])
	tienda.ficha_id = "atraedora"
	tienda.queue_redraw()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-regalo-comprada.png")
	ordenador.apagar()
	await get_tree().create_timer(1.2).timeout
	get_tree().paused = false
	for m in mapa.marcas_sala:
		m.refrescar()
	print("Novedades del ordenador: %s · «!» del baúl: %s (esperado: sin «armas» (lo demás, de otras pruebas), true)" % [
		mapa.ordenador.novedades(Guardado.cargar()), mapa.marcas_sala[3].activa])
	# el baúl: al abrirlo se quita su «!»; se saca todo
	abrir_cosas("baul")
	await get_tree().create_timer(0.4).timeout
	for id in ["pistola", "molotov", "granada", "atraedora"]:
		var i: int = inventario.cosas_baul(Guardado.cargar()).map(func(o): return o.id).find(id)
		inventario.tocar("b%d" % i)
		await get_tree().process_frame
		inventario.sacar()
		await get_tree().process_frame
	print("Sacado del baúl: huecos %s · lanzables %s · «!» del baúl apuntado %s (esperado: fregona y pistola, [molotov 1, granada 1, atraedora 1], false)" % [
		johnny.huecos, lanzables.montones(), Guardado.cargar().baul_nuevo])
	inventario.cerrar()
	await get_tree().create_timer(1.5).timeout
	ventana = ventana_tutorial()
	print("Al cerrar el baúl: tutorial «%s» (esperado: cambiar_arma)" % (ventana.id if ventana else "ninguno"))
	Captura.foto("captura-regalo-cambiar-arma.png")
	if ventana:
		ventana.cerrar()
	await get_tree().create_timer(0.6).timeout
	for m in mapa.marcas_sala:
		m.refrescar()
	await cruzar(0)
	print("Por la puerta del pasillo, con el regalo: en «%s» (esperado: pasillo)" % planta.sitios[aqui].tipo)
	Guardado.cambiar(func(g):
		g.baul = guardado_antes.baul
		g.baul_equipo = guardado_antes.baul_equipo)
	get_tree().quit()


# De probar_marcas_sala: abre algo de la sala como con el clic, cuenta qué tutorial sale (y le saca su foto), lo cierra
# y cierra la pantalla que se abre detrás
func usar_con_tutorial(abrir: Callable, cerrar: Callable, id: String, foto := "") -> void:
	abrir.call()
	await get_tree().create_timer(0.5).timeout
	var ventana := ventana_tutorial()
	print("Al abrir: tutorial «%s» (esperado: %s)" % [ventana.id if ventana else "ninguno", id])
	# su «!» se quita ya, con el menú todavía abierto (exclamacion.gd sigue mirando en pausa y apuntar los refresca)
	var con_marca: Array = get_tree().get_nodes_in_group("exclamaciones").filter(func(m): return m.visible).map(
		func(m): return String(m.get_parent().name))
	print("  con el menú abierto, «!» en: %s (esperado: sin el de lo que se acaba de abrir)" % ", ".join(con_marca))
	if foto != "":
		Captura.foto(foto)
	if ventana:
		ventana.cerrar()
	await get_tree().create_timer(0.4).timeout
	cerrar.call()
	await get_tree().create_timer(0.3).timeout


# La ventana de tutorial abierta (ui/tutorial.gd), o null
func ventana_tutorial() -> Tutorial:
	for h in get_children():
		if h is Tutorial and not h.is_queued_for_deletion():
			return h
	return null


# De probar_sala: los muebles ya no se abren solos al arrimarse (zona_usar.gd). Delante de cada uno, sin pulsar nada,
# no se abre; con un clic izquierdo se abre, y Johnny (en el modo libre) no dispara. Lejos de los
# muebles, el clic vuelve a disparar. En el móvil, delante de un mueble sale el botón «Abrir» y tocarlo lo abre. Las
# pantallas no llegan a abrirse: mientras dura, "usar" solo se cuenta. Fotos: captura-sala-ordenador.png (Johnny delante
# del ordenador, sin que se abra) y captura-sala-movil.png (delante de la taquilla, con los botones del móvil)
func probar_abrir_muebles(usables: Dictionary) -> void:
	var antes_modo: String = johnny.modo
	johnny.modo = "libre"
	johnny.con_raton = true
	var veces := {}
	var guardadas := {}
	for n in usables:
		var m: Node = usables[n][0]
		guardadas[n] = m.usar.get_connections().map(func(c): return c.callable)
		for c in guardadas[n]:
			m.usar.disconnect(c)
		veces[n] = 0
		m.usar.connect(func(): veces[n] += 1)
	for n in usables:
		var m: Node = usables[n][0]
		johnny.position = m.position + Vector2(0, 22)
		johnny.espera = 0.0
		await get_tree().create_timer(0.4).timeout
		var sin_clic: int = veces[n]
		if n == "Ordenador":
			Captura.foto("captura-sala-ordenador.png")
		var sobre: Vector2 = m.position + Vector2(0, -30)   # encima del dibujo del mueble
		clic_raton(sobre, true)
		await get_tree().create_timer(0.15).timeout
		clic_raton(sobre, false)
		await get_tree().physics_frame
		print("%s: al arrimarse se abre %d veces (esperado: 0) · con el clic se abre %d (esperado: 1) · dispara %s (esperado: false)"
			% [n, sin_clic, veces[n], johnny.espera > 0.0])
	# en el móvil: delante de la taquilla sale el botón «Abrir», y tocarlo la abre (foto: captura-sala-movil.png)
	var tactil: Tactil = null
	for hijo in get_children():
		if hijo is Tactil:
			tactil = hijo
	Tactil.activo = true
	Tactil.con_dedo = true
	await get_tree().create_timer(0.2).timeout
	var antes: int = veces["Taquilla"]
	var boton: Array = tactil.botones().get("abrir", [])
	Captura.foto("captura-sala-movil.png")
	if not boton.is_empty():
		for pulsado in [true, false]:
			var t := InputEventScreenTouch.new()
			t.position = get_viewport().get_final_transform() * Vector2(boton[0])   # (de la pantalla del juego a la ventana)
			t.pressed = pulsado
			Input.parse_input_event(t)
			await get_tree().physics_frame
	print("Móvil, delante de la taquilla: botón «Abrir» %s (esperado: true) · al tocarlo se abre %d (esperado: 1)"
		% [not boton.is_empty(), veces["Taquilla"] - antes])
	Tactil.activo = false
	tactil.visible = false
	johnny.con_raton = true
	# lejos de los muebles, el clic dispara como siempre
	johnny.position = mapa.ordenador.position + Vector2(0, 140)
	johnny.espera = 0.0
	await get_tree().create_timer(0.3).timeout
	var lejos: Vector2 = johnny.position + Vector2(120, 0)
	clic_raton(lejos, true)
	await get_tree().create_timer(0.15).timeout
	clic_raton(lejos, false)
	print("Lejos de los muebles: delante de alguno %s (esperado: false) · el clic dispara %s (esperado: true)"
		% [johnny.ante_mueble != null, johnny.espera > 0.0 or johnny.ataque_t >= 0.0])
	johnny.modo = antes_modo
	for n in usables:
		var m: Node = usables[n][0]
		for c in m.usar.get_connections():
			m.usar.disconnect(c.callable)
		for c in guardadas[n]:
			m.usar.connect(c)


# Un clic del ratón en "donde" (un punto del mapa): primero lo mueve ahí y luego pulsa o suelta el botón izquierdo
func clic_raton(donde: Vector2, abajo: bool) -> void:
	var en_ventana := get_viewport().get_final_transform() * (get_viewport().get_canvas_transform() * donde)
	var m := InputEventMouseMotion.new()
	m.position = en_ventana
	Input.parse_input_event(m)
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = abajo
	e.position = en_ventana
	Input.parse_input_event(e)


# Con "--captura --contorno-mueble": el contorno amarillo de los muebles de la sala (zona_usar.gd). Con Johnny lejos del
# baúl, el ratón encima ya no lo enciende (captura-contorno-raton.png); con Johnny delante se enciende (captura-contorno-delante.png),
# esté el ratón donde esté (desde el 13 nov, con E no hay que apuntar). Cada línea dice lo esperado
func probar_contorno_mueble() -> void:
	var baul: Node = mapa.baul
	var raton := func(donde: Vector2) -> void:
		var m := InputEventMouseMotion.new()
		m.position = get_viewport().get_final_transform() * (get_viewport().get_canvas_transform() * donde)
		Input.parse_input_event(m)
	johnny.position = baul.position + Vector2(0, 200)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	raton.call(baul.position + Vector2(0, -30))
	await get_tree().create_timer(0.2).timeout
	print("Contorno: ratón encima del baúl, Johnny lejos · se ve %s (esperado: false) · el del banco %s (esperado: false)" % [
		baul.zona.contorno.visible, mapa.banco.zona.contorno.visible])
	Captura.foto("captura-contorno-raton.png")
	raton.call(johnny.position + Vector2(120, 40))
	await get_tree().create_timer(0.2).timeout
	print("Contorno: ratón fuera · se ve %s (esperado: false)" % baul.zona.contorno.visible)
	johnny.position = baul.position + Vector2(0, 22)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.4).timeout
	raton.call(johnny.position + Vector2(160, 90))   # el ratón lejos del baúl
	await get_tree().create_timer(0.2).timeout
	print("Contorno: Johnny delante con el ratón lejos · se ve %s (esperado: true)" % baul.zona.contorno.visible)
	johnny.con_raton = false   # como si jugara con el mando
	await get_tree().create_timer(0.2).timeout
	print("Contorno: Johnny delante sin ratón · se ve %s (esperado: true)" % baul.zona.contorno.visible)
	Captura.foto("captura-contorno-delante.png")
	get_tree().quit()


# Con "--captura --clic-mueble": con Johnny delante del baúl (zona_usar.gd), un clic lejos del baúl no lo abre y Johnny
# ataca hacia allí; un clic encima del baúl tampoco lo abre y Johnny ataca (desde el 13 nov atacar solo ataca); E lo abre. La pantalla del
# baúl no llega a abrirse: "usar" solo se cuenta. Foto: captura-clic-mueble.png (Johnny delante del baúl). Luego se cierra
func probar_clic_mueble() -> void:
	var baul: Node = mapa.baul
	var guardadas: Array = baul.usar.get_connections().map(func(c): return c.callable)
	for c in guardadas:
		baul.usar.disconnect(c)
	var veces := [0]
	baul.usar.connect(func(): veces[0] += 1)
	johnny.position = baul.position + Vector2(0, 22)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	johnny.modo = "libre"   # (después de esperar: al empezar, la partida le pone el de Opciones)
	johnny.con_raton = true
	Captura.foto("captura-clic-mueble.png")
	print("Clic mueble: Johnny delante del baúl %s (esperado: true)" % [johnny.ante_mueble == baul.zona])
	# un clic lejos, a la derecha y abajo, en el suelo
	johnny.espera = 0.0
	var lejos: Vector2 = johnny.position + Vector2(160, 90)
	clic_raton(lejos, true)
	await get_tree().create_timer(0.15).timeout
	var ataca: bool = johnny.espera > 0.0 or johnny.ataque_t >= 0.0
	clic_raton(lejos, false)
	await get_tree().create_timer(0.6).timeout
	print("Clic mueble: clic lejos · se abre %d (esperado: 0) · ataca %s (esperado: true)" % [veces[0], ataca])
	# un clic encima del baúl
	johnny.espera = 0.0
	johnny.ataque_t = -1.0
	var sobre: Vector2 = baul.position + Vector2(0, -30)
	clic_raton(sobre, true)
	await get_tree().create_timer(0.15).timeout
	ataca = johnny.espera > 0.0 or johnny.ataque_t >= 0.0
	clic_raton(sobre, false)
	await get_tree().physics_frame
	print("Clic mueble: clic encima · se abre %d (esperado: 0) · ataca %s (esperado: true)" % [veces[0], ataca])
	# J no lo abre; E, sí, aunque el ratón esté lejos
	for abajo in [true, false]:
		var k := InputEventKey.new()
		k.physical_keycode = KEY_J
		k.pressed = abajo
		Input.parse_input_event(k)
		await get_tree().physics_frame
		await get_tree().physics_frame
	print("Clic mueble: con J · se abre %d (esperado: 0)" % veces[0])
	for abajo in [true, false]:
		var k := InputEventKey.new()
		k.physical_keycode = KEY_E
		k.pressed = abajo
		Input.parse_input_event(k)
		await get_tree().physics_frame
		await get_tree().physics_frame
	print("Clic mueble: con E · se abre %d (esperado: 1)" % veces[0])
	get_tree().quit()


# Con "--captura --armarito-clic": delante del armarito de un baño, con el ratón y el clic mantenido encima de él: se abre,
# Johnny no ataca ni mientras sigue pulsado (ya vacío, el armarito deja de valer, y antes ahí disparaba) y al soltar y
# volver a hacer clic en otra parte, ataca como siempre. Y la primera vez que se abre sale el tutorial de las curas
# (captura-armarito-tutorial.png). Luego se cierra
func probar_armarito_clic() -> void:
	var bano := -1
	for j in planta.sitios.size():
		if not planta.sitios[j].get("armaritos", []).is_empty():
			bano = j
			break
	if bano < 0:
		print("Armarito clic · no hay ningún baño en esta planta")
		get_tree().quit()
		return
	await montar(bano, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var a: Node2D = mapa.armaritos[0]
	a.datos.dentro = "botiquin"
	a.vaciar(false)
	johnny.position = a.position + Vector2(0, 50)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5, false).timeout
	johnny.modo = "libre"   # (después de esperar: al empezar, la partida le pone el de Opciones)
	johnny.con_raton = true
	mochila.clear()
	# primera parte, sin tutorial (con él el juego se para y no se ve si dispara): el clic se mantiene encima del armarito
	var sobre: Vector2 = a.position + Vector2(0, -56)
	johnny.espera = 0.0
	johnny.ataque_t = -1.0
	var disparos := 0
	clic_raton(sobre, true)
	for n in 20:
		await get_tree().physics_frame
		if johnny.espera > 0.0 or johnny.ataque_t >= 0.0:
			disparos += 1
	print("Armarito clic · abierto con el clic %s (esperado: false) · fotogramas disparando con el clic pulsado %d (esperado: más de 0)" % [a.datos.cogido, disparos])
	clic_raton(sobre, false)
	pulsar_accion("usar", true)
	await get_tree().physics_frame
	pulsar_accion("usar", false)
	await get_tree().create_timer(0.3, false).timeout
	print("Armarito clic · abierto con E %s (esperado: true)" % a.datos.cogido)
	await get_tree().create_timer(0.3, false).timeout
	# un clic lejos, en el suelo: ataca como siempre
	johnny.espera = 0.0
	johnny.ataque_t = -1.0
	var lejos: Vector2 = johnny.position + Vector2(160, 40)
	clic_raton(lejos, true)
	await get_tree().create_timer(0.15, false).timeout
	var ataca: bool = johnny.espera > 0.0 or johnny.ataque_t >= 0.0
	clic_raton(lejos, false)
	print("Armarito clic · el clic lejos después ataca %s (esperado: true)" % ataca)
	await get_tree().create_timer(0.5, false).timeout
	# segunda parte, con tutorial: la primera vez que se abre, sale el de las curas
	a.vaciar(false)
	Tutoriales.olvidar()
	tutoriales_prueba = true
	a.get_node("Zona").abrir()
	await get_tree().create_timer(0.8).timeout
	var ventana: Tutorial = null
	for h in get_children():
		if h is Tutorial and not h.is_queued_for_deletion():
			ventana = h
	print("Armarito clic · tutorial abierto: %s (esperado: curas)" % (ventana.id if ventana else "ninguno"))
	Captura.foto("captura-armarito-tutorial.png")
	if ventana:
		ventana.cerrar()
	await get_tree().create_timer(0.5).timeout
	# y la segunda vez que se abre, no
	a.vaciar(false)
	a.get_node("Zona").abrir()
	await get_tree().create_timer(0.5).timeout
	var otra := "ninguno"
	for h in get_children():
		if h is Tutorial and not h.is_queued_for_deletion():
			otra = h.id
	print("Armarito clic · al abrir otro armarito, tutorial abierto: %s (esperado: ninguno: el de las curas ya salió y es el mismo para vendas y botiquín, M110)" % otra)
	get_tree().quit()


# Con "--captura --ascensor": el ascensor (partida.gd, arreglar_ascensor). En la planta baja no se arregla (la sala
# está ahí mismo); en la 1ª planta está averiado hasta que cae el jefe (se hace como si cayera: Johnny entra en su
# sala y el jefe no llega a salir), y al salir al pasillo Johnny dice que lo ha arreglado. Con cosas en la mochila,
# baja en él a la sala de mantenimiento, las guarda en el baúl y vuelve a la 1ª planta, delante del ascensor. En la
# 2ª planta vuelve a estar averiado, y en la azotea no hay. Cada línea de la terminal dice lo esperado. Saca
# captura-placas.png (antes de nada, el pasillo de la planta baja con las placas de las puertas y el cartel de la
# planta, pintado junto al ascensor), captura-ascensor-averiado.png (el de la 1ª planta antes del jefe, con su cinta), captura-ascensor-arreglado.png (el ascensor ya arreglado, con el aviso de Johnny), captura-ascensor-sala.png (la
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
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ascensor-averiado.png")
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
	await get_tree().create_timer(0.3).timeout
	mapa.baul.zona.abrir()   # (ya no se abre solo al arrimarse: con el clic, zona_usar.gd)
	await get_tree().create_timer(0.3).timeout
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
# planta baja. Johnny delante de la puerta blindada cerrada (captura-joyeria-camara.png); arrimarse a la cerradura sin
# llave: el aviso y, a la segunda, la alarma con el cartel y los primeros zombis (captura-joyeria-alarma.png); la
# cuenta adelantada hasta el final: la puerta se abre (captura-joyeria-abierta.png). Luego la otra manera: en el
# pasillo cae el guardia y suelta las dos llaves (captura-joyeria-dorada.png), Johnny coge la dorada y, con la
# cámara otra vez cerrada, la cerradura la abre sin alarma. Lo cuenta todo en la terminal
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
	var molotovs_antes: int = lanzables.cuantas("molotov")
	johnny.position = d.premio.pos + Vector2(0, 170)   # (más lejos que el imán de las cosas del suelo: que no vuele aún)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.6, false).timeout
	Captura.foto("captura-joyeria-premio.png")
	johnny.position = d.premio.pos
	await get_tree().create_timer(0.6, false).timeout
	print("Cogido: %s · manos %s → %s · guardadas %s · calidad de la nueva %d (esperado: 3) · dólares %d → %d · molotovs %d → %d · dice «%s»" % [d.premio.cogido,
		manos_antes, johnny.huecos, armas_guardadas, johnny.calidad(d.premio.arma), dolares_antes, dolares, molotovs_antes,
		lanzables.cuantas("molotov"), aviso.text])
	# la segunda apertura, más abajo, prepara otro premio
	d.erase("premio")
	# la otra manera: el guardia cae en el pasillo y suelta la llave dorada junto a la maestra
	await montar(0, 0, false)
	print("Guardia en el pasillo: %s · dorada: %s" % [guardia != null, d.dorada])
	johnny.position = guardia.position + Vector2(-120, 30)
	guardia.recibir_golpe(9999, Vector2.ZERO)
	await get_tree().create_timer(0.6, false).timeout
	johnny.get_node("Camara").reset_smoothing()
	print("Al caer: dorada %s en %s · en el suelo: llave %s, dorada %s" % [d.dorada, d.suelo, mapa.cosas.has_node("Llave"), mapa.cosas.has_node("Dorada")])
	Captura.foto("captura-joyeria-dorada.png")
	johnny.position = d.suelo.pos
	await get_tree().create_timer(0.4, false).timeout
	print("Cogida: dorada %s · dice «%s»" % [d.dorada, aviso.text])
	# con la cámara otra vez cerrada, la cerradura la abre con la llave dorada y sin alarma
	d.abierta = false
	d.puerta.merge({"cerrada": true, "abierta": false}, true)   # (su hueco también: mapa/puerta_bano.gd)
	d.alarma = -1.0
	await montar(d.sitio, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	johnny.position = centro + fuera * 52.0
	joyeria.listo = true
	joyeria.mirar_lector()
	print("Con la llave dorada: abierta %s · alarma %s · dorada %s · dice «%s»" % [d.abierta, joyeria.alarma(), d.dorada, aviso.text])
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


# Con "--captura --dificultad" (M72, el equilibrio): lo que cambia de una planta a otra. Para cada planta (de la baja a
# la 4ª), la vida y el zarpazo de un zombi normal, de un rápido y del guardia (partida.gd, ZOMBI_POR_PLANTA) y la vida
# de la portera (JEFE_POR_PLANTA), con lo que eran antes; y, en doce plantas generadas, cuántos armaritos llevan
# botiquín y cuántos vendas (M12: un solo armarito por apartamento, con botiquín o vendas a medias; planta.gd,
# armaritos). Solo números, sin fotos. Luego se cierra
func probar_dificultad() -> void:
	await get_tree().create_timer(0.3).timeout
	nueva_planta(1)
	await montar(0, 0, false)
	var donde: Vector2 = johnny.position + Vector2(0, 300)
	var antes_zarpazo := {"normal": 10, "rapido": 8, "guardia": 12}
	for num in range(1, Planta.PLANTAS + 1):
		planta.num = num
		var linea := "Dificultad · planta %d:" % (num - 1)
		for tipo in ["normal", "rapido", "guardia"]:
			var z := meter_zombi(tipo, donde)
			linea += " %s vida %d zarpazo %d (antes %d y %d) ·" % [tipo, z.vida_max, z.dano,
				ZOMBIS[tipo].instantiate().vida_max, antes_zarpazo[tipo]]
			z.queue_free()
		var j := meter_zombi("portera", donde)
		var base: int = ZOMBIS["portera"].instantiate().vida_max
		linea += " portera vida %d (antes %d)" % [j.vida_max, int(base * pow(1.25, num - 1))]
		j.queue_free()
		print(linea)
		await get_tree().physics_frame
	var botiquines := 0
	var vendas := 0
	var con_bano := 0
	var mal := 0              # M12: sitios con baño que no tienen justo un armarito
	for i in 12:
		Planta.semilla = 2000 + i
		var p: Dictionary = Planta.generar(1 + i % 5, edificio, jefe_de(1 + i % 5))
		for s in p.sitios:
			var lista: Array = s.get("armaritos", [])
			if not lista.is_empty():
				con_bano += 1
				if lista.size() != 1:
					mal += 1
			for a in lista:
				if a.dentro == "botiquin":
					botiquines += 1
				else:
					vendas += 1
	Planta.semilla = 0
	print("Dificultad · armaritos en 12 plantas: %d botiquines y %d vendas (%.1f armaritos por planta) · sitios con baño: %d" % [
		botiquines, vendas, (botiquines + vendas) / 12.0, con_bano])
	print("M12 · un armarito por apartamento: %d sitios sin justo uno (esperado 0) · botiquines %d y vendas %d (esperado: más o menos a medias)" % [
		mal, botiquines, vendas])
	get_tree().quit()


# Con "--captura --edificio centro --guardia" (M83; 17 nov, el rugido): el guardia de la llave maestra. Primero, de cerca
# junto a Johnny (captura-guardia-de-cerca.png); luego le ve: ruge una sola vez, con el «¡¡¡GRRR!!!» en rojo encima
# (captura-guardia-ruge.png), llegan sus guardias (4 en la planta baja y 2 más por planta) y van todos a por Johnny
# (captura-guardia-persigue.png); al caer, sus guardias no sueltan nada y él, un dólar y un mutágeno por guardia y uno más
func probar_guardia() -> void:
	await montar(0, 0, false)
	if guardia == null:
		print("Guardia: no hay en este pasillo")
		get_tree().quit()
		return
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != guardia:
			z.queue_free()
	var rugidos := [0]
	guardia.rugido.connect(func(): rugidos[0] += 1)
	johnny.vida = 100000   # que no le maten entre todos
	var sitio: Dictionary = planta.sitios[aqui]
	guardia.global_position = Vector2(sitio.ancho / 2.0, sitio.alto / 2.0 + 100)   # (fuera del banco de en medio)
	johnny.position = guardia.global_position + Vector2(-90, 0)
	johnny.get_node("Camara").reset_smoothing()
	guardia.set_physics_process(false)   # (quieto para la foto, mientras se aclara la pantalla)
	await get_tree().create_timer(0.8, false).timeout
	Captura.foto("captura-guardia-de-cerca.png")
	print("Guardia · antes de verle: alerta %s · dibujo %s (esperado: false, zombi-guardia.tres)" % [guardia.alerta,
		guardia.sprite.sprite_frames.resource_path.get_file()])
	# (18 nov) antes de rugir, inmune: ni un golpe ni el fuego le quitan vida (el golpe sí le hace rugir luego)
	var vida0: int = guardia.vida
	guardia.recibir_golpe(50, Vector2(100, 0))
	guardia.herir(20.0)
	print("Guardia · inmune antes de rugir: vida %d → %d tras un golpe de 50 y 20 de fuego (esperado: igual) · rugirá %s (esperado: true)" % [
		vida0, guardia.vida, guardia.rugir_ya])
	guardia.rugir_ya = false   # (que ruja al verle, como siempre en esta prueba)
	await get_tree().create_timer(0.15, false).timeout
	Captura.foto("captura-guardia-inmune.png")
	# le ve: ruge
	johnny.position = guardia.global_position + Vector2(-230, 0)
	johnny.get_node("Camara").reset_smoothing()
	guardia.set_physics_process(true)
	Input.action_press("izquierda")   # (intenta irse: mientras ruge, petrificado)
	await get_tree().create_timer(0.35, false).timeout
	var quieto0: Vector2 = johnny.position
	var grito: Array = guardia.get_parent().get_children().filter(func(n): return n is Label and "GRRR" in n.text)
	print("Guardia · al verle: estado %s · animación %s · rugidos %d · «%s» en %s (esperado: rugido, grito_s, 1, ¡¡¡GRRR!!! en rojo %s)" % [
		guardia.estado, guardia.sprite.animation, rugidos[0], grito[0].text if grito else "nada",
		grito[0].get_theme_color("font_color").to_html(false) if grito else "-", Tema.ROJO.to_html(false)])
	print("Guardia · su sonido: el gruñido del botón JUGAR hace %d ms (esperado: menos de 500)" % (Time.get_ticks_msec() - Sonido.ultimo_grunido))
	Captura.foto("captura-guardia-ruge.png")
	await get_tree().create_timer(0.3, false).timeout
	var vida1: int = guardia.vida
	guardia.recibir_golpe(10, Vector2.ZERO)
	print("Guardia · ya ha rugido: vida %d → %d tras un golpe de 10 (esperado: 10 menos)" % [vida1, guardia.vida])
	print("Guardia · Johnny mientras ruge, pulsando a la izquierda: se mueve %.0f · sin mandos %.2f s más (esperado: 0, algo más de 0)" % [
		johnny.position.distance_to(quieto0), johnny.sin_mandos])
	print("Guardia · encima de Johnny: %s (esperado: ¡¡¡QUÉ SUSTO!!!)" % [johnny.get_parent().get_children().filter(func(n):
		return n is Label and "SUSTO" in n.text).map(func(n): return n.text)])
	var suyos: Array = get_tree().get_nodes_in_group("zombis").filter(func(z): return z != guardia)
	print("Guardia · llegan %d guardias (esperado %d en la planta %d) · todos marcados «llamado»: %s" % [suyos.size(),
		guardias_del_rugido(), planta.num, suyos.all(func(r): return r.has_meta("llamado"))])
	# (los vigilantes salen, al azar, de hombre o de mujer: los dos dibujos de GPT)
	var dibujos := {}
	for r in suyos:
		var hoja: String = r.sprite.sprite_frames.resource_path.get_file()
		dibujos[hoja] = dibujos.get(hoja, 0) + 1
	print("Guardia · sus guardias, por dibujo: %s (esperado: zombi-vigilante.tres y zombi-vigilante-mujer.tres, más o menos mitad y mitad)" % dibujos)
	# (foto con uno de cada, quietos a la derecha de Johnny, en la luz: captura-guardia-vigilantes.png)
	var el: Array = suyos.filter(func(r): return r.sprite.sprite_frames.resource_path.get_file() == "zombi-vigilante.tres")
	var ella: Array = suyos.filter(func(r): return r.sprite.sprite_frames.resource_path.get_file() == "zombi-vigilante-mujer.tres")
	if el and ella:
		for k in 2:
			var r: Node2D = [el[0], ella[0]][k]
			r.set_physics_process(false)
			r.global_position = johnny.position + Vector2(70 + 60 * k, 0)
		await get_tree().create_timer(0.1, false).timeout
		Captura.foto("captura-guardia-vigilantes.png")
		el[0].set_physics_process(true)
		ella[0].set_physics_process(true)
	print("Guardia · cuántos llama en cada planta (baja, 1ª, 2ª, 3ª): %s (esperado: 4, 6, 8, 10)" % [range(1, 5).map(func(n):
		var antes: int = planta.num
		planta.num = n
		var cuantos := guardias_del_rugido()
		planta.num = antes
		return cuantos)])
	# después del rugido, a por Johnny
	quieto0 = johnny.position
	await get_tree().create_timer(1.2, false).timeout
	print("Guardia · Johnny, acabado el rugido: se mueve %.0f (esperado: más de 0, ya anda)" % johnny.position.distance_to(quieto0))
	Input.action_release("izquierda")
	var d0: float = guardia.global_position.distance_to(johnny.position)
	await get_tree().create_timer(0.5, false).timeout
	print("Guardia · tras rugir: estado %s · animación %s a x%.1f · se acerca %.0f (esperado: andar o zarpazo, andar a x2.0, se acerca)" % [
		guardia.estado, guardia.sprite.animation, guardia.sprite.speed_scale, d0 - guardia.global_position.distance_to(johnny.position)])
	Captura.foto("captura-guardia-persigue.png")
	await get_tree().create_timer(4.0, false).timeout
	print("Guardia · en 6 s, rugidos %d (esperado 1: ruge una sola vez)" % rugidos[0])
	# lo que sueltan: sus guardias, nada; él, la llave aparte y un dólar y un mutágeno por guardia y uno más
	var cosas := func() -> int:
		return mapa.cosas.get_children().filter(func(c): return c.has_signal("cogido") and not c.is_queued_for_deletion()).size()
	# (lejos de Johnny, que si no lo recoge todo al momento)
	johnny.position = Vector2(Planta.MURO + 80, sitio.alto / 2.0)
	var lejos := Vector2(sitio.ancho - 300, sitio.alto / 2.0)
	var n0: int = cosas.call()
	suyos = get_tree().get_nodes_in_group("zombis").filter(func(z): return z != guardia and z.estado != "muerto")
	for r in suyos:
		r.global_position = lejos
		r.recibir_golpe(99999, Vector2.ZERO)
	await get_tree().create_timer(0.6, false).timeout
	print("Guardia · sus %d guardias, al caer, sueltan %d cosas (esperado 0)" % [suyos.size(), cosas.call() - n0])
	n0 = cosas.call()
	guardia.global_position = lejos + Vector2(0, 80)
	guardia.recibir_golpe(99999, Vector2.ZERO)
	await get_tree().create_timer(0.8, false).timeout
	print("Guardia · él, al caer, suelta %d cosas (esperado %d: %d dólares y %d mutágenos; la llave aparte)" % [cosas.call() - n0,
		2 * (guardias_del_rugido() + 1), guardias_del_rugido() + 1, guardias_del_rugido() + 1])
	get_tree().quit()


# Con "--captura --edificio centro --maestra" (17 nov): la llave maestra del guardia. En el pasillo de la planta baja,
# todas las puertas cerradas (tiendas, jefe y sala de mantenimiento): Johnny prueba cada una y no pasa, y el mapa con
# sus candados (captura-maestra-antes.png); cae el guardia y suelta la llave (captura-maestra-suelo.png; y, solo para la
# foto, la dorada de la joyería al lado: captura-maestra-dorada.png); Johnny la coge:
# el grito y todas las puertas abiertas, con la calavera y el casco en el mapa (captura-maestra-cogida.png); el
# inventario con «Maestra» (captura-maestra-inventario.png); entra en una tienda y en la sala del jefe, y la llave
# sigue; el portal y la salida de incendios dicen lo de los Apartamentos; y en la planta de arriba ya no la tiene
func probar_maestra() -> void:
	await montar(0, 0, false)
	johnny.vida = 100000
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != guardia:
			z.queue_free()
	var sitio: Dictionary = planta.sitios[0]
	var cerradas := []
	for i in sitio.salidas.size():
		var s: Dictionary = sitio.salidas[i]
		if s.tipo == "puerta":
			cerradas.append("%s:%s(luz %s)" % [planta.sitios[s.a].tipo, s.cerrojo, "verde" if mapa.puertas[i].abierta else "roja"])
	print("Maestra · antes: guardia vivo %s · puertas %s" % [planta.guardia.vivo, cerradas])
	# Johnny prueba cada puerta: no pasa y dice la frase de los Apartamentos
	for i in sitio.salidas.size():
		if sitio.salidas[i].tipo == "puerta":
			await cruzar(i)
			print("Maestra · prueba la puerta %d: sigue en %s · lo dicho: %s" % [i, planta.sitios[aqui].nombre, avisos_dichos.keys()])
	print("Maestra · frase: «%s» (esperado: la de los Apartamentos con ¡¡¡ !!!)" % falta_llave())
	# (y los bancos de en medio, delante de las tiendas de abajo: Johnny al lado de uno, y uno que choca)
	var bancos: Array = mapa.muebles.filter(func(c): return c.datos.get("tipo", "") == "bancogaleria")
	print("Maestra · bancos en la galería: %d (esperado: 3)" % bancos.size())
	if not bancos.is_empty():
		johnny.position = bancos[0].position + Vector2(70, 40)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.4, false).timeout
		Captura.foto("captura-maestra-banco.png")
		# Johnny anda hacia el banco desde abajo: tiene que quedarse fuera
		johnny.position = bancos[0].position + Vector2(0, 60)
		var antes: Vector2 = johnny.position
		for k in 20:
			johnny.velocity = Vector2(0, -200)
			johnny.move_and_slide()
		print("Maestra · contra el banco: de %s a %s, el banco en %s (esperado: no lo atraviesa)" % [antes, johnny.position,
			bancos[0].position])
	johnny.position = Vector2(sitio.ancho / 2.0, sitio.alto / 2.0 + 60)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5, false).timeout
	Captura.foto("captura-maestra-antes.png")
	# cae el guardia: la llave en el suelo, sin más aviso
	guardia.global_position = johnny.position + Vector2(160, 0)
	guardia.recibir_golpe(99999, Vector2.ZERO)
	await get_tree().create_timer(0.8, false).timeout
	johnny.get_node("Camara").reset_smoothing()
	print("Maestra · al caer: llave en el suelo %s · tiene_llave %s · aviso «%s» (esperado: true, false y nada del guardia)" % [
		mapa.cosas.has_node("Llave"), planta.tiene_llave, aviso.text if aviso.visible else ""])
	Captura.foto("captura-maestra-suelo.png")
	# (y la llave dorada de la joyería, al lado, con su luz dorada, solo para la foto: aquí no hay joyería)
	mapa.poner_llave(planta.llave.pos + Vector2(44, 0), true)
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-maestra-dorada.png")
	mapa.cosas.get_node("Dorada").free()
	# la coge: el grito y todas las puertas abiertas
	johnny.position = planta.llave.pos
	await get_tree().create_timer(0.35, false).timeout
	var abiertas := []
	for i in sitio.salidas.size():
		if sitio.salidas[i].tipo == "puerta":
			abiertas.append(mapa.puertas[i].abierta)
	print("Maestra · cogida: tiene_llave %s · luces verdes %s · aviso «%s» (esperado: true, todas, nada: solo el grito)" % [
		planta.tiene_llave, abiertas, aviso.text if aviso.visible else ""])
	Captura.foto("captura-maestra-cogida.png")
	abrir_cosas("inventario")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-maestra-inventario.png")
	inventario.cerrar()
	# entra en una tienda y vuelve; luego en la sala del jefe: la llave no se gasta
	for i in sitio.salidas.size():
		var s: Dictionary = sitio.salidas[i]
		if s.tipo == "puerta" and planta.sitios[s.a].tipo == "apartamento":
			await cruzar(i)
			print("Maestra · tienda: dentro de %s (esperado: la tienda)" % planta.sitios[aqui].nombre)
			await montar(0, i, false)
			break
	for i in sitio.salidas.size():
		var s: Dictionary = sitio.salidas[i]
		if s.tipo == "puerta" and planta.sitios[s.a].tipo == "jefe":
			await cruzar(i)
			print("Maestra · jefe: dentro de %s · tiene_llave %s (esperado: la sala del jefe y true)" % [planta.sitios[aqui].nombre,
				planta.tiene_llave])
			for z in get_tree().get_nodes_in_group("zombis"):
				z.queue_free()
			await montar(0, i, false)
			break
	johnny.position = Vector2(sitio.ancho / 2.0, sitio.alto / 2.0 + 60)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.4, false).timeout
	Captura.foto("captura-maestra-despues.png")
	# el portal y la salida de incendios
	avisos_dichos.clear()
	await cruzar(puerta_de_tipo("llegada"))
	await cruzar(puerta_de_tipo("escaleras"))
	print("Maestra · portal y salida de incendios: %s · frases «%s» y «%s»" % [avisos_dichos.keys(), Idioma.t("¡¡¡ESTÁ BLOQUEADO!!!"), falta_llave()])
	# la planta de arriba: la llave se ha quedado abajo
	planta.jefa_muerta = true
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await cruzar(puerta_de_tipo("escaleras"))
	await get_tree().create_timer(0.5, false).timeout
	print("Maestra · planta %d: tiene_llave %s · guardia vivo %s · puertas %s (esperado: false, true y todas «maestra»/«llave»)" % [
		planta.num, planta.tiene_llave, planta.guardia.vivo,
		planta.sitios[0].salidas.filter(func(s): return s.tipo == "puerta").map(func(s): return s.cerrojo)])
	get_tree().quit()


# Con "--captura --edificio torre --torre" (tercer edificio, parte 1: el esqueleto): de cada planta de Torre Velaria, su
# nombre, sus departamentos y las tres cifras del código con dónde está cada ordenador; luego, en la planta 10, el pasillo
# (captura-torre-pasillo.png), un departamento con su ordenador sin leer (captura-torre-departamento.png), Johnny
# leyéndolo (los zombis de allí se despiertan; captura-torre-terminal.png) y, leídos los tres, la sala del jefe ya se
# puede abrir. Y el nombre de la última planta (la 40). Luego se cierra
func probar_torre() -> void:
	for num in range(1, Planta.PLANTAS + 1):
		Planta.semilla = 4100 + num
		var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
		var lista := []
		for s in p.sitios:
			if s.tipo in ["apartamento", "jefe"] and not s.get("azotea", false):
				lista.append("%s%s (%s)" % ["[jefe] " if s.tipo == "jefe" else "", s.nombre, ", ".join(s.apt.salas.map(func(x): return x.nombre))])
		print("Torre, %s (%s): %s" % [Planta.nombre_de(p), p.nombre, " · ".join(lista) if not lista.is_empty() else "sin departamentos"])
		if p.has("codigo"):
			print("    código %s: %s" % [p.codigo.cifras, " · ".join(p.codigo.terminales.map(func(d):
				return "%s en %s, %s" % [d.cifra, p.sitios[d.sitio].nombre, p.sitios[d.sitio].apt.salas[d.sala].nombre]))])
	Planta.semilla = 4102
	nueva_planta(2)
	Planta.semilla = 0
	await montar(0, 0, false)
	await get_tree().create_timer(0.6).timeout
	print("Torre: lugar «%s», %d ordenadores (esperado: 3)" % [lugar.text, planta.codigo.terminales.size()])
	johnny.position = Vector2(planta.sitios[0].ancho * 0.3, planta.sitios[0].alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-torre-pasillo.png")
	var d: Dictionary = planta.codigo.terminales[0]
	await montar(d.sitio, 0, false)
	await get_tree().create_timer(0.6).timeout
	var dormidos := func() -> int:
		return get_tree().get_nodes_in_group("zombis").filter(func(z): return z.get("dormido")).size()
	print("Torre: en %s, %d zombis dormidos antes de leer" % [Planta.nombre_de_sitio(planta.sitios[d.sitio]), dormidos.call()])
	await foto_entera(planta.sitios[d.sitio], "captura-torre-departamento.png")
	# antes de leerlo, Johnny a un paso y el ordenador brillando (la foto del tutorial «Torre Velaria»)
	johnny.position = d.pos + Vector2(100, 40)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-torre-terminal-cerca.png")
	johnny.position = d.pos + Vector2(0, 40)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-torre-terminal.png")
	for n in mapa.cosas.get_children():
		if n.name.begins_with("Terminal"):
			print("Torre: ordenador en %s (Johnny en %s), visible %s, modulate %s, z %d" % [n.global_position, johnny.global_position, n.is_visible_in_tree(), n.modulate, n.z_index])
	print("Torre: leído %s (esperado: true), dormidos después %d (esperado: 0), tiene_llave %s (esperado: false)" % [
		d.leido, dormidos.call(), planta.tiene_llave])
	for otro in planta.codigo.terminales:
		if not otro.leido:
			otro.leido = true
			_al_leer_terminal()
	var jefe_idx: int = planta.sitios.find(planta.sitios.filter(func(s): return s.tipo == "jefe")[0])
	print("Torre: con las tres, tiene_llave %s (esperado: true); la sala del jefe: %s" % [planta.tiene_llave,
		Planta.nombre_de_sitio(planta.sitios[jefe_idx])])
	print("Torre: la última planta se llama «%s» (esperado: Planta 40)" % Planta.nombre_de(Planta.generar(Planta.PLANTAS, edificio, "")))
	get_tree().quit()


# Con "--captura --edificio torre --departamentos" (tercer edificio, parte 2: cómo se ve; --tipo X, solo ese): el pasillo del
# vestíbulo y el de la planta 10, enteros y sin penumbra, y cada departamento, con la puerta abajo y arriba, sin zombis: cuántos
# muebles lleva (esperado: los puestos a mano en Catalogo.SALAS "<sala>-<tipo>"; los "libre" cuentan igual) y su foto
# (captura-torre-<tipo>-<lado>.png). Luego se cierra
func probar_departamentos() -> void:
	var args := OS.get_cmdline_user_args()
	var solo: String = args[args.find("--tipo") + 1] if "--tipo" in args else ""
	if solo == "":
		for num in [1, 2]:
			Planta.semilla = 3300 + num
			nueva_planta(num)
			Planta.semilla = 0
			planta.sitios[0].limpio = true
			await montar(0, 0, false)
			await get_tree().create_timer(0.4).timeout
			print("Pasillo de la torre, %s: estilo %s, muebles %d (esperado: %d)" % [Planta.nombre_de(planta), planta.sitios[0].estilo,
				get_tree().get_nodes_in_group("muebles").size(), Catalogo.SALAS[planta.sitios[0].estilo].colocados.abajo.size()])
			for lado in ["izq", "cen", "der"]:   # (el pasillo es más largo que la pantalla: sus dos puntas y el ascensor, en medio)
				johnny.position = Vector2(planta.sitios[0].ancho * {"izq": 0.2, "cen": 0.5, "der": 0.8}[lado], planta.sitios[0].alto / 2.0)
				johnny.get_node("Camara").reset_smoothing()
				await get_tree().create_timer(0.5).timeout
				Captura.foto("captura-torre-pasillo-%d-%s.png" % [num, lado])
	for tipo in Tienda.de_edificio("torre"):
		if solo != "" and tipo != solo:
			continue
		for lado in ["abajo", "arriba"]:
			var t := Tienda.generar(0, tipo, false, lado)
			var esperado: int = 0
			for s in t.salas:
				esperado += Catalogo.SALAS.get("%s-%s" % [s.uso, tipo], {}).get("colocados", {}).get(lado, []).size()
			var hallada := {}
			for i in 300:
				Planta.semilla = 3500 + i
				var num := 1 + i % 4
				var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
				for idx in p.sitios.size():
					if p.sitios[idx].get("tienda", "") == tipo and p.sitios[idx].tipo != "jefe" and p.sitios[idx].apt.entrada.lado == lado:
						hallada = {"semilla": 3500 + i, "num": num, "idx": idx}
						break
				if not hallada.is_empty():
					break
			if hallada.is_empty():
				Planta.semilla = 0
				print("Departamento %s (puerta %s): no sale en ninguna planta" % [tipo, lado])
				continue
			Planta.semilla = hallada.semilla
			nueva_planta(hallada.num)
			Planta.semilla = 0
			var sitio: Dictionary = planta.sitios[hallada.idx]
			sitio.limpio = true
			await montar(hallada.idx, 0, false)
			await get_tree().create_timer(0.4).timeout
			print("Departamento %s (puerta %s): muebles %d (esperado: %d)" % [tipo, lado, get_tree().get_nodes_in_group("muebles").size(), esperado])
			johnny.position = Vector2(sitio.ancho / 2.0, sitio.alto / 2.0)
			await foto_entera(sitio, "captura-torre-%s-%s.png" % [tipo, lado])
	get_tree().quit()


# ── Los peligros de Torre Velaria (parte 3) ──

# Monta un departamento de ese tipo, con la puerta "lado" y sin zombis (busca una planta en la que salga). Devuelve el sitio
# (vacío si no sale en ninguna) y deja todas sus salas vistas
func ir_a_departamento(tipo: String, lado := "arriba") -> Dictionary:
	for i in 300:
		Planta.semilla = 3500 + i
		var num := 1 + i % 4
		var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
		for idx in p.sitios.size():
			var s: Dictionary = p.sitios[idx]
			if s.get("tienda", "") == tipo and s.tipo != "jefe" and s.apt.entrada.lado == lado:
				nueva_planta(num)
				Planta.semilla = 0
				var sitio: Dictionary = planta.sitios[idx]
				sitio.limpio = true
				await montar(idx, 0, false)
				for sala in sitio.apt.salas:
					mapa.vistas[sala.id] = true
					mapa.niebla[sala.id] = 0.0
				mapa.actualizar_niebla(0.0)
				await get_tree().create_timer(0.3).timeout
				return sitio
	Planta.semilla = 0
	print("Departamento %s (puerta %s): no sale en ninguna planta" % [tipo, lado])
	return {}


func peligro_de(tipo: String) -> Node:
	for p in mapa.peligros:
		if p.datos.tipo == tipo:
			return p
	return null


# Con "--captura --edificio torre --viento": el ventanal roto de Marketing. Johnny en medio de la sala, quieto, y dos
# zombis despiertos cerca del ventanal: dice cuánto arrastra el viento a Johnny (al aire y al abrigo de un mueble), si se
# agarra al borde (y lo que le quita) y si los zombis salen volando (cuentan como muertos). Fotos: captura-torre-viento-1.png
# (los zombis cerca del ventanal) y -2.png (ya fuera). Luego se cierra
func probar_viento() -> void:
	var sitio: Dictionary = await ir_a_departamento("marketing")
	var v: Node = peligro_de("viento")
	print("Viento: %s (esperado: el ventanal en un lado de la sala grande)" % (v.datos if v else "NO HAY"))
	if v == null:
		get_tree().quit(1)
		return
	var sala: Dictionary = sitio.apt.salas[0]
	var medio_y: float = (v.datos.y0 + v.datos.y1) / 2.0
	var hacia: float = v.hacia
	# Johnny, a media sala: sin moverse, ¿cuánto le arrastra en 2 s?
	johnny.position = Vector2((sala.c0 + sala.ancho / 2.0) * 32.0, medio_y)
	johnny.invulnerable = 0.0
	v.t = Peligros.VIENTO.calma - 0.5   # (a punto de empezar una racha)
	var antes: float = johnny.position.x
	var muertos_antes: int = muertos
	var z1 := meter_zombi("normal", Vector2(v.datos.x - hacia * 90.0, medio_y - 20.0))
	var z2 := meter_zombi("lento", Vector2(v.datos.x - hacia * 130.0, medio_y + 30.0))
	await get_tree().create_timer(0.7).timeout
	Captura.foto("captura-torre-viento-1.png")
	await get_tree().create_timer(1.5).timeout
	print("Viento: Johnny arrastrado %.0f unidades hacia el ventanal en 2 s (esperado: unas 60-120)" % ((johnny.position.x - antes) * hacia))
	print("Viento: zombis tirados por la ventana %d de 2, muertos contados %d (esperado: 2 y 2)" % [
		[z1, z2].filter(func(z): return z.has_meta("ventana")).size(), muertos - muertos_antes])
	johnny.position = Vector2(v.datos.x - hacia * 300.0, medio_y)   # (la foto, con el ventanal en medio)
	await get_tree().create_timer(0.1).timeout
	Captura.foto("captura-torre-viento-2.png")
	# al borde: se agarra
	var vida: int = johnny.vida
	johnny.invulnerable = 0.0
	johnny.position = Vector2(v.datos.x - hacia * 20.0, medio_y)
	await get_tree().create_timer(0.3).timeout
	print("Viento: en el borde, vida %d -> %d (esperado: %d menos) y lo echa hacia dentro: a %.0f del muro (esperado: más de 30)" % [
		vida, johnny.vida, Peligros.VIENTO.dano, absf(johnny.position.x - v.datos.x)])
	# al abrigo: un mueble entre Johnny y el ventanal, pegado a él
	var abrigo := Vector2.ZERO
	for m in get_tree().get_nodes_in_group("muebles"):
		var p: Vector2 = m.global_position - mapa.global_position + Vector2(-hacia * 40.0, 0)
		if sala.c0 * 32.0 < p.x and p.x < (sala.c0 + sala.ancho) * 32.0 and sala.f0 * 32.0 < p.y and p.y < (sala.f0 + sala.fondo) * 32.0 \
				and v.empuje(p, johnny) == Vector2.ZERO:
			abrigo = p
			break
	print("Viento: al abrigo de un mueble en %s, empuje %s (esperado: (0, 0))" % [abrigo, v.empuje(abrigo, johnny) if abrigo != Vector2.ZERO else "SIN SITIO"])
	get_tree().quit()


# Con "--captura --edificio torre --camaras": las cámaras de Seguridad corporativa (3). Un zombi dormido en la sala y
# Johnny delante de una cámara, en su cono: dice cuándo salta la alarma (esperado: en 0,6 s), si despierta al zombi y
# cuántos refuerzos llegan por la puerta (2; la segunda alarma de la misma cámara, ninguno). Luego le pega un tiro a la
# pared junto a una cámara y dice si se rompe. Fotos: captura-torre-camaras-1.png (vigilando, con la barrita llenándose),
# -2.png (la alarma) y -3.png (una rota). Luego se cierra
func probar_camaras() -> void:
	var sitio: Dictionary = await ir_a_departamento("seguridad")
	var c: Node = peligro_de("camaras")
	print("Cámaras: %d (esperado: 3)" % (c.datos.camaras.size() if c else 0))
	if c == null:
		get_tree().quit(1)
		return
	var sala: Dictionary = sitio.apt.salas[0]
	var dormido := meter_zombi("normal", Vector2((sala.c0 + sala.ancho / 2.0) * 32.0, (sala.f0 + sala.fondo - 2) * 32.0))
	dormido.dormido = true
	var zombis_antes: int = get_tree().get_nodes_in_group("zombis").size()
	# Johnny, en el cono de la primera, donde mira ahora mismo
	c.t = 0.0
	johnny.position = c.ojo(0) + Vector2.from_angle(c.angulo(0)) * 150.0
	var ve: bool = c.ve(0, johnny.global_position, johnny)
	# con la skin del informático (skins.gd), en el mismo sitio no le ve
	var skin_antes: String = johnny.skin
	johnny.skin = "informatico"
	print("Cámaras: con la skin del informático, le ve %s (esperado: false)" % c.ve(0, johnny.global_position, johnny))
	johnny.skin = skin_antes
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-torre-camaras-1.png")
	await get_tree().create_timer(0.4).timeout
	print("Cámaras: le ve %s; alarma %s, zombi despierto %s, refuerzos %d (esperado: true, true, true, 2)" % [ve,
		c.alarma > 0.0, not dormido.dormido, get_tree().get_nodes_in_group("zombis").size() - zombis_antes])
	Captura.foto("captura-torre-camaras-2.png")
	var escoltas := get_tree().get_nodes_in_group("zombis").filter(func(z): return z.get_meta("tipo", "") == "escolta").size()
	print("Cámaras: escoltas de Velaria entre los refuerzos %d (esperado: 2)" % escoltas)
	# otra alarma de la misma cámara: ya no llama a nadie más
	var ahora: int = get_tree().get_nodes_in_group("zombis").size()
	c.alarma = 0.0
	c.saltar(0)
	await get_tree().create_timer(0.2).timeout
	print("Cámaras: la segunda alarma de la misma, refuerzos %d (esperado: 0)" % (get_tree().get_nodes_in_group("zombis").size() - ahora))
	# un tiro a la pared junto a la segunda
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	c.alarma = 0.0
	var cam: Dictionary = c.datos.camaras[c.datos.camaras.size() - 1]
	johnny.position = Vector2(cam.x, cam.y + 140.0)
	var bala: Node2D = load("res://escenas/armas/bala.tscn").instantiate()
	bala.position = Vector2(cam.x, cam.y + 60.0)
	bala.velocidad = Vector2(0, -900)
	mapa.add_child(bala)
	await get_tree().create_timer(0.3).timeout
	print("Cámaras: tiro a la pared junto a la última, rota %s (esperado: true); ve a Johnny %s (esperado: false)" % [cam.rota,
		c.ve(c.datos.camaras.size() - 1, johnny.global_position, johnny)])
	johnny.position = Vector2(cam.x + 120.0, cam.y + 120.0)
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-torre-camaras-3.png")
	# salir del departamento (el mapa se guarda fuera de la escena, partida.gd dejar_mapa) y volver: las cámaras
	# siguen en la pared (antes se borraban al salir y, al volver, el juego se paraba con un error)
	var guardado: Node = mapa
	remove_child(guardado)
	await get_tree().physics_frame
	add_child(guardado)
	await get_tree().create_timer(0.3).timeout
	print("Cámaras: tras salir y volver, dibujos enteros %s (esperado: true)" % c.cuerpos.all(func(n): return is_instance_valid(n)))
	get_tree().quit()


# Con "--captura --edificio torre --gas": el gas de Recursos Humanos. Un zombi despierto encima de una rejilla que echa
# gas: dice si se duerme (y a Johnny, encima de otra, no le pasa nada) y si al rato despierta frenético (más rápido).
# Luego Johnny va a la válvula del archivo y dice si corta el gas. Fotos: captura-torre-gas-1.png (la nube con el zombi
# dormido), -2.png (frenético) y -3.png (la válvula cerrada). Luego se cierra
func probar_gas() -> void:
	await ir_a_departamento("rrhh")
	var g: Node = peligro_de("gas")
	print("Gas: %d rejillas, válvula %s (esperado: 3 y en el archivo)" % [g.datos.rejillas.size() if g else 0,
		g.datos.valvula if g else "NO HAY"])
	if g == null:
		get_tree().quit(1)
		return
	# las dos primeras, echando gas ya
	var r0: Dictionary = g.datos.rejillas[0]
	g.t = Peligros.GAS.parada - r0.fase + 0.2
	for i in g.nubes.size():
		g.nubes[i] = 1.0 if g.echando(i) else 0.0
	var zombi := meter_zombi("normal", Vector2(r0.x, r0.y))
	johnny.position = Vector2(r0.x + 160.0, r0.y)
	var vida: int = johnny.vida
	var velocidad: float = zombi.agente.max_speed
	await get_tree().create_timer(0.6).timeout
	print("Gas: echando %s, zombi dormido %s (esperado: true y true)" % [g.echando(0), zombi.gaseado > 0.0])
	johnny.position = Vector2(r0.x + 40.0, r0.y + 10.0)
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-torre-gas-1.png")
	print("Gas: Johnny dentro de la nube %s, vida %d -> %d (esperado: true y la misma)" % [g.dentro(johnny.global_position), vida, johnny.vida])
	johnny.position = Vector2(r0.x + 260.0, r0.y)
	await get_tree().create_timer(Peligros.GAS.duerme - 0.8).timeout
	print("Gas: frenético %s, rapidez %.0f -> %.0f (esperado: true y x%.1f)" % [zombi.frenesi > 0.0, velocidad, zombi.agente.max_speed,
		Peligros.GAS.rapido])
	Captura.foto("captura-torre-gas-2.png")
	zombi.queue_free()
	# la válvula: Johnny se planta delante
	var val: Dictionary = g.datos.valvula
	johnny.position = Vector2(val.x, val.y + 30.0)
	await get_tree().create_timer(0.4).timeout
	print("Gas: con Johnny en la válvula, abierto %s; echa la primera %s (esperado: false y false)" % [g.datos.abierto, g.echando(0)])
	Captura.foto("captura-torre-gas-3.png")
	get_tree().quit()


# Cuántos oficinistas y escoltas de Velaria salen en cada tipo de departamento de la torre (tercer edificio, parte 4):
# genera 30 plantas de cada número y cuenta lo que pone Planta.horda en cada departamento. Lo usan --oficinista y --escolta
func contar_torre(tipo_zombi: String) -> void:
	var cuenta := {}
	for i in 30:
		for num in [1, 2, 3, 4]:
			Planta.semilla = 7100 + i * 10 + num
			var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
			for s in p.sitios:
				if s.get("tienda", "") == "" or s.tipo == "jefe" or Tienda.TIPOS[s.tienda].get("edificio", "") != "torre":
					continue
				var clave := "%s (planta %d)" % [s.tienda, num]
				var n := Planta.horda(s, 1, num).filter(func(z): return z.tipo == tipo_zombi).size()
				if not cuenta.has(clave):
					cuenta[clave] = [0, 0, 99]
				cuenta[clave][0] += 1
				cuenta[clave][1] += n
				cuenta[clave][2] = mini(cuenta[clave][2], n)
	Planta.semilla = 0
	var claves := cuenta.keys()
	claves.sort()
	for clave in claves:
		print("%s: %s en %s, de media %.1f, como mínimo %d" % [tipo_zombi.capitalize(), clave, "%d departamentos" % cuenta[clave][0],
			float(cuenta[clave][1]) / cuenta[clave][0], cuenta[clave][2]])


# El centro de la habitación más grande de un sitio (la sala grande del departamento), en una casilla sin mueble
func centro_sala_grande(sitio: Dictionary) -> Vector2:
	var sala: Dictionary = sitio.apt.salas[0]
	for s in sitio.apt.salas:
		if s.casillas > sala.casillas:
			sala = s
	return Vector2((sala.c0 + sala.ancho / 2.0) * 32.0, (sala.f0 + sala.fondo / 2.0) * 32.0)


# Con "--captura --edificio torre --oficinista": el oficinista. Cuenta cuántos salen en cada departamento; luego, en Atención
# al cliente, uno despierto a media distancia de Johnny (quieto): dice si le tira algo y cuánto le quita, y, con Johnny
# pegado a él, si se aparta. Fotos: captura-torre-oficinista-1.png (la taza o la grapadora volando) y -2.png (apartándose).
# Luego se cierra
func probar_oficinista() -> void:
	contar_torre("oficinista")
	var sitio: Dictionary = await ir_a_departamento("atencion")
	if sitio.is_empty():
		get_tree().quit(1)
		return
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no dispare ni tape en las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	var centro := centro_sala_grande(sitio)
	johnny.position = centro + Vector2(-110, 0)
	var zombi := meter_zombi("oficinista", centro + Vector2(110, 0))
	var vida: int = johnny.vida
	var tirado := ""
	for k in 40:
		await get_tree().create_timer(0.1).timeout
		for b in get_tree().get_nodes_in_group("balas_zombi"):
			if tirado == "":
				tirado = b.forma
				Captura.foto("captura-torre-oficinista-1.png")
		johnny.position = centro + Vector2(-110, 0)   # quieto, que no le empujen
	print("Oficinista: ha tirado %s, vida de Johnny %d -> %d (esperado: taza o grapadora, y 8 menos)" % [tirado if tirado != "" else "NADA",
		vida, johnny.vida])
	# Johnny, pegado: se aparta (o le da un manotazo)
	johnny.position = zombi.position + Vector2(-60, 0)
	var antes: float = zombi.position.distance_to(johnny.position)
	await get_tree().create_timer(0.8).timeout
	Captura.foto("captura-torre-oficinista-2.png")
	print("Oficinista: con Johnny a %.0f, se aparta hasta %.0f (esperado: más lejos)" % [antes, zombi.position.distance_to(johnny.position)])
	get_tree().quit()


# Con "--captura --edificio torre --escolta": el escolta de Velaria. Cuenta cuántos salen en cada departamento; luego, en
# Seguridad corporativa, uno quieto (de diana) mirando a Johnny: dice cuánto le hace una bala de frente y una por la espalda
# (la de frente, la mitad: el chaleco); luego, despierto y pegado a Johnny, si el táser le quita vida y lo deja tieso.
# Fotos: captura-torre-escolta-1.png (la bala en el chaleco) y -2.png (Johnny tieso). Luego se cierra
func probar_escolta() -> void:
	contar_torre("escolta")
	var sitio: Dictionary = await ir_a_departamento("seguridad")
	if sitio.is_empty():
		get_tree().quit(1)
		return
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no dispare ni tape en las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	var c: Node = peligro_de("camaras")
	if c:
		c.queue_free()   # (que no salte la alarma y lleguen más)
	var centro := centro_sala_grande(sitio)
	johnny.position = centro + Vector2(0, 130)
	johnny.set_physics_process(false)   # quieto y sin pegar (si no, le dispara solo y lo gira)
	var zombi := meter_zombi("escolta", centro)
	zombi.diana = true
	zombi.casa = zombi.position   # (la diana se queda en su sitio, mirando a Johnny)
	var danos := []
	zombi.herido.connect(func(cantidad, golpe): if golpe: danos.append(cantidad))
	await get_tree().create_timer(0.5).timeout
	# de frente (desde Johnny, abajo) y por la espalda (desde arriba)
	for desde in [Vector2(0, 90), Vector2(0, -90)]:
		var bala: Node2D = load("res://escenas/armas/bala.tscn").instantiate()
		bala.position = centro + desde
		bala.velocidad = -desde.normalized() * 900.0
		bala.dano = 20
		mapa.add_child(bala)
		await get_tree().create_timer(0.12).timeout
		if desde.y > 0:
			Captura.foto("captura-torre-escolta-1.png")
		await get_tree().create_timer(1.2).timeout   # (que vuelva a su sitio: la bala lo empuja)
		zombi.position = zombi.casa
	print("Escolta: bala de 20 de frente %s, por la espalda %s (esperado: 10 y 20)" % [danos[0] if danos.size() > 0 else "NADA",
		danos[1] if danos.size() > 1 else "NADA"])
	# el táser
	zombi.diana = false
	johnny.position = zombi.position + Vector2(0, 40)
	var vida: int = johnny.vida
	var tieso := false
	for k in 40:
		await get_tree().create_timer(0.05).timeout
		if johnny.vida < vida:
			johnny.set_physics_process(true)   # (para que se le ponga el calambre)
			await get_tree().create_timer(0.05).timeout
			johnny.set_physics_process(false)
			tieso = johnny.estados.has("calambre")
			Captura.foto("captura-torre-escolta-2.png")
			break
	print("Escolta: táser, vida de Johnny %d -> %d, tieso %s (esperado: 6 menos, o 7 con lo que sube por planta, y true)" % [vida, johnny.vida, tieso])
	get_tree().quit()


# Con "--captura --congelados": los zombis de verdad de los apartamentos de varias plantas (--plantas N, 4, desde la
# --desde N, 1; con --semilla N, siempre las mismas), todos
# despiertos, y Johnny (quieto e invencible) cambiando de habitación cada CONGELADOS_CAMBIO s para que tengan que ir a por
# él por las puertas. Cada medio segundo (en pasos de física) mira quién lleva CONGELADOS_QUIETO s sin moverse estando
# lejos de Johnny: un zombi «congelado». Dice qué le pasa a cada uno (su estado, su animación, su camino, quién tiene
# pegado) y saca una foto de los cuatro primeros (captura-congelados-N.png; sin ninguno, del primer piso al acabar,
# captura-congelados.png). Va a toda prisa (ATASCO_RITMO). Esperado: ninguno. Luego se cierra
const CONGELADOS_CAMBIO := 8.0
const CONGELADOS_QUIETO := 4.0
const CONGELADOS_TIEMPO := 32.0

func probar_congelados() -> void:
	johnny.invencible = true
	johnny.set_physics_process(false)   # (quieto: que no los mate él solo en el modo asistido)
	Engine.time_scale = ATASCO_RITMO
	var total := 0
	var congelados := 0
	var fotos := 0
	Planta.semilla = int(Captura.dato("--semilla", "0"))   # (con --semilla N, las plantas salen siempre iguales)
	var desde := int(Captura.dato("--desde", "1"))
	for num in range(desde, desde + int(Captura.dato("--plantas", "4"))):
		nueva_planta(num)
		for idx in planta.sitios.size():
			var sitio: Dictionary = planta.sitios[idx]
			if sitio.tipo != "apartamento" or sitio.get("tienda", "") != "" or sitio.zombis.is_empty():
				continue
			await montar(idx, 0, false)
			await get_tree().create_timer(1.0, true, true).timeout   # (a que esté listo el mapa de caminos)
			johnny.invulnerable = 999.0
			var red := get_world_2d().navigation_map
			# (las habitaciones a las que se puede llegar: no el baño cerrado del superviviente ni la cámara acorazada)
			var salas: Array = sitio.apt.salas.filter(func(s): return s.puertas.any(func(d): return not d.get("cerrada", false)))
			var zombis: Array = get_tree().get_nodes_in_group("zombis").filter(func(z): return z is Zombi)
			total += zombis.size()
			for z in zombis:
				z.despertar()
			var sitios_de := {}   # dónde estaba cada uno hace CONGELADOS_QUIETO s
			var avisado := {}
			var t := 0.0
			var sala_n := 0
			while t < CONGELADOS_TIEMPO:
				if fmod(t, CONGELADOS_CAMBIO) < 0.01:
					sala_n += 1
					johnny.position = NavigationServer2D.map_get_closest_point(red, salas[sala_n % salas.size()].centro)
					johnny.get_node("Camara").reset_smoothing()
					sitios_de.clear()
				await get_tree().create_timer(0.5, true, true).timeout
				t += 0.5
				for z in zombis:
					if not is_instance_valid(z) or z.estado == "muerto" or avisado.has(z):
						continue
					var hist: Array = sitios_de.get(z, [])
					hist.append(z.global_position)
					if hist.size() > int(CONGELADOS_QUIETO / 0.5):
						hist.pop_front()
					sitios_de[z] = hist
					if hist.size() < int(CONGELADOS_QUIETO / 0.5):
						continue
					var lejos: float = z.global_position.distance_to(johnny.global_position)
					var movido := 0.0
					for p in hist:
						movido = maxf(movido, p.distance_to(z.global_position))
					if movido > 6.0 or lejos < 140.0:
						continue
					avisado[z] = true
					congelados += 1
					var ag: NavigationAgent2D = z.agente
					print("Congelado: planta %d, sitio %d, %s en %s (sala %d, Johnny en la %d, a %d): estado %s, animación %s %s, " % [
						num, idx, z.get_meta("tipo"), z.global_position.round(), mapa.zona_en(z.global_position),
						mapa.zona_en(johnny.global_position), lejos, z.estado, z.sprite.animation,
						"en marcha" if z.sprite.is_playing() else "parada"] +
						"dormido %s, espabilando %.1f, aturdido %.1f, liado %.1f, apretado %s, ve a Johnny %s, " % [
						z.dormido, z.espabilando, z.aturdido, z.liado, z.apretado, z.se_ve(johnny)] +
						"camino: acabado %s, llega %s, siguiente %s, velocidad %s, pedida %s, evitar %s, capa %s" % [
						ag.is_navigation_finished(), ag.is_target_reachable(), (ag.get_next_path_position() - z.global_position).round(),
						z.velocity.round(), ag.velocity.round(), ag.avoidance_enabled, z.get_collision_mask_value(Zombi.CAPA_ZOMBIS)])
					var pegados := []
					for o in zombis:
						if is_instance_valid(o) and o != z and o.estado != "muerto" and o.global_position.distance_to(z.global_position) < 44.0:
							pegados.append("%s %s %s" % [o.get_meta("tipo"), (o.global_position - z.global_position).round(), o.estado])
					var choques := []
					for k in z.get_slide_collision_count():
						var c: KinematicCollision2D = z.get_slide_collision(k)
						choques.append("%s %s" % [c.get_collider().name if c.get_collider() else "?", c.get_normal().round()])
					var puertas := []
					for h in mapa.hojas:
						if h.caja.get_center().distance_to(z.global_position) < 120.0:
							puertas.append("%s abierta %.1f libre %s" % [(h.caja.get_center() - z.global_position).round(), h.abierta, h.libre])
					print("   pegados %s, choca con %s, puertas %s" % [pegados, choques, puertas])
					if fotos < 4:
						# la foto, con la cámara de Johnny sobre el zombi (sin mover a Johnny, que le atacarían)
						fotos += 1
						for s in sitio.apt.salas:
							mapa.vistas[s.id] = true
							mapa.niebla[s.id] = 0.0
						mapa.actualizar_niebla(0.0)
						var cam: Camera2D = johnny.get_node("Camara")
						var antes := cam.offset
						cam.offset = z.global_position - johnny.global_position
						cam.reset_smoothing()
						await get_tree().process_frame
						await get_tree().process_frame
						Captura.foto("captura-congelados-%d.png" % fotos)
						cam.offset = antes
						cam.reset_smoothing()
			if fotos == 0 and num == desde:
				Captura.foto("captura-congelados.png")   # (sin congelados: cómo van a por Johnny al acabar el primer piso)
	print("Congelados: %d de %d zombis (esperado: 0)" % [congelados, total])
	Planta.semilla = 0
	Engine.time_scale = 1.0
	get_tree().quit()


# Con "--captura --cocinas" (17 nov): con alguien viviendo en los trasteros y la ventana de las cocinas sin ver, Johnny
# limpia un apartamento: al acabar, sale la ventana «Las cocinas» (captura-cocinas.png). Luego deja el guardado como
# estaba y se cierra
func probar_cocinas() -> void:
	var antes := Guardado.cargar().duplicate(true)
	tutoriales_prueba = true
	Guardado.cambiar(func(g):
		g.ajustes.tutoriales = true
		g.tutoriales.erase("cocinas")
		if g.rescatados.is_empty():
			g.rescatados.append(Supervivientes.DATOS.keys()[0]))
	Tutoriales.vistos_de = ""   # (que lo vuelva a leer)
	var donde := -1
	for j in planta.sitios.size():
		if planta.sitios[j].tipo == "apartamento" and not planta.sitios[j].limpio:
			donde = j
			break
	if donde < 0:
		Captura.fallar("esta planta no tiene apartamentos sin limpiar")
		return
	await montar(donde, 0, false)
	johnny.invencible = true
	for z in get_tree().get_nodes_in_group("zombis"):
		z.recibir_golpe(9999, Vector2.ZERO)
	var t := 0.0
	while not "cocinas" in cola_tutoriales and not Tutoriales.visto("cocinas") and t < 8.0:
		await get_tree().create_timer(0.2, true).timeout
		t += 0.2
	await get_tree().create_timer(1.0, true).timeout
	print("Las cocinas: piso limpio %s · su ventana %s (esperado: true, sale)" % [planta.sitios[donde].limpio,
		"sale" if "cocinas" in cola_tutoriales or Tutoriales.visto("cocinas") else "no sale"])
	Captura.foto("captura-cocinas.png")
	Guardado.cambiar(func(g):
		g.rescatados = antes.rescatados
		g.tutoriales = antes.tutoriales)
	get_tree().quit()


# Con "--captura --cientifico-durmientes" (17 nov): en 8 plantas de cada edificio, a qué distancia del medio de su
# habitación queda el científico muerto (esperado: casi siempre 0; si hay un mueble en medio, poco más) y cuántos
# durmientes salen sin mejora y con la mejora 2 del VD-7, con la misma semilla (esperado: un 40 % más). Luego se cierra
func probar_cientifico_durmientes() -> void:
	var antes := Alerta.nivel
	for ed in ["apartamentos", "centro", "torre"]:
		var lejos: Array[int] = []
		var sin := 0
		var con := 0
		for k in 8:
			Alerta.nivel = 0
			Planta.rng.seed = 1000 + k
			var p: Dictionary = Planta.generar(1 + k % 4, ed)
			var c: Dictionary = p.get("cientifico", {})
			if not c.is_empty():
				# (la habitación en la que está: de las que lo tienen dentro de su recuadro, la de su medio más cerca; el
				# recuadro del pasillo, con forma de L, tapa los de las demás)
				var cerca := INF
				for s2 in p.sitios[c.sitio].apt.salas:
					var caja := Rect2(s2.c0 * Planta.CASILLA, s2.f0 * Planta.CASILLA, s2.ancho * Planta.CASILLA, s2.fondo * Planta.CASILLA)
					if caja.has_point(c.pos):
						cerca = minf(cerca, c.pos.distance_to(s2.centro))
				lejos.append(int(cerca) if cerca < INF else -1)
			for sitio in p.sitios:
				sin += sitio.zombis.size()
			Alerta.nivel = 2
			Planta.rng.seed = 1000 + k
			p = Planta.generar(1 + k % 4, ed)
			for sitio in p.sitios:
				con += sitio.zombis.size()
		print("Científico y durmientes (%s): el científico, a %s del medio de su habitación · durmientes sin mejora %d, con la mejora 2 %d (+%d %%; esperado: unos +40 %%)" % [
			ed, lejos, sin, con, roundi((float(con) / maxf(sin, 1) - 1.0) * 100.0)])
	Alerta.nivel = antes
	get_tree().quit()


# Con "--captura --vueltas" (F24, 16 nov): los durmientes de los apartamentos de varias plantas (--plantas N, 4, desde la
# --desde N, 1; con --semilla N, siempre las mismas). Johnny (quieto e invencible) entra andando en cada habitación que
# tiene durmientes, por una de sus puertas, hasta el centro, y se queda VUELTAS_TIEMPO s: los despierta y van a por él.
# En cada paso de física mira cuánto gira cada zombi (hacia dónde mira su dibujo): el que en VUELTAS_VENTANA s da más de
# una vuelta entera sin moverse VUELTAS_SITIO del sitio, estando lejos de Johnny, «da vueltas». Dice qué le pasa (su camino, si ve a
# Johnny, si está fuera del mapa de caminos) y saca una foto de los cuatro primeros (captura-vueltas-N.png). Va a toda
# prisa (ATASCO_RITMO). Esperado: ninguno. Luego se cierra
const VUELTAS_TIEMPO := 6.0
const VUELTAS_VENTANA := 2.0
const VUELTAS_SITIO := 40.0

func probar_vueltas() -> void:
	johnny.invencible = true
	johnny.set_physics_process(false)   # (quieto: lo movemos a mano)
	Engine.time_scale = ATASCO_RITMO
	var total := 0
	var dan := 0
	var fotos := 0
	var maximo := {}   # (de cada zombi, lo que más ha girado sin moverse del sitio)
	var paso := 1.0 / Engine.physics_ticks_per_second
	var ventana := int(VUELTAS_VENTANA / paso)
	Planta.semilla = int(Captura.dato("--semilla", "0"))
	var desde := int(Captura.dato("--desde", "1"))
	for num in range(desde, desde + int(Captura.dato("--plantas", "4"))):
		nueva_planta(num)
		for idx in planta.sitios.size():
			var sitio: Dictionary = planta.sitios[idx]
			if sitio.tipo != "apartamento" or sitio.get("tienda", "") != "" or sitio.zombis.is_empty():
				continue
			await montar(idx, 0, false)
			await get_tree().create_timer(1.0, true, true).timeout   # (a que esté listo el mapa de caminos)
			johnny.invulnerable = 999.0
			var red := get_world_2d().navigation_map
			var zombis: Array = get_tree().get_nodes_in_group("zombis").filter(func(z): return z is Zombi)
			total += zombis.size()
			var avisado := {}
			for sala in sitio.apt.salas:
				var dentro: Array = zombis.filter(func(z): return is_instance_valid(z) and z.dormido and z.zona == sala.id)
				var abiertas: Array = sala.puertas.filter(func(d): return not d.get("cerrada", false))
				if dentro.is_empty() or abiertas.is_empty():
					continue
				# Johnny entra por la puerta (desde un poco fuera) hasta el centro, a su paso, y se queda allí
				var d: Dictionary = abiertas[0]
				var hueco := Vector2((d.c + d.ancho / 2.0) * Apartamento.CASILLA, (d.f + d.fondo / 2.0) * Apartamento.CASILLA)
				var meta := NavigationServer2D.map_get_closest_point(red, sala.centro)
				var desde_p := hueco + hueco.direction_to(meta) * -40.0
				var giros := {}   # de cada zombi: [ángulo girado en cada paso], [dónde estaba]
				var t := 0.0
				while t < VUELTAS_TIEMPO:
					var p := desde_p.move_toward(meta, t * 160.0)   # (más o menos a lo que anda Johnny)
					johnny.global_position = p
					johnny.get_node("Camara").reset_smoothing()
					await get_tree().physics_frame
					t += paso
					for z in zombis:
						if not is_instance_valid(z) or z.estado == "muerto" or z.dormido or avisado.has(z):
							continue
						# (lo que se ve: hacia dónde mira su dibujo, una de las 8 direcciones)
						var mira: float = Zombi.DIRS.find(z.direccion) * PI / 4.0
						var g: Array = giros.get(z, [[], [], mira])
						g[0].append(wrapf(mira - g[2], -PI, PI))
						g[1].append(z.global_position)
						g[2] = mira
						if g[0].size() > ventana:
							g[0].pop_front()
							g[1].pop_front()
						giros[z] = g
						if g[0].size() < ventana or z.estado != "andar" or z.espabilando > 0.0:
							continue
						var girado := 0.0
						for a in g[0]:
							girado += a
						var movido := 0.0
						for q in g[1]:
							movido = maxf(movido, q.distance_to(z.global_position))
						var lejos: float = z.global_position.distance_to(johnny.global_position)
						if movido <= VUELTAS_SITIO and absf(girado) > maximo.get(z, [0.0])[0]:
							maximo[z] = [absf(girado), "%s planta %d sitio %d en %s, a %d de Johnny, movido %d, estado %s" % [
								z.get_meta("tipo"), num, idx, z.global_position.round(), lejos, movido, z.estado]]
						if absf(girado) < TAU or movido > VUELTAS_SITIO or lejos < z.radio + johnny.RADIO + z.alcance + 4.0:
							continue
						avisado[z] = true
						dan += 1
						var ag: NavigationAgent2D = z.agente
						var camino := ag.get_current_navigation_path()
						print("Vueltas: planta %d, sitio %d, %s en %s (sala %d, Johnny en la %d, a %d): girado %.1f vueltas, movido %d, " % [
							num, idx, z.get_meta("tipo"), z.global_position.round(), mapa.zona_en(z.global_position),
							mapa.zona_en(johnny.global_position), lejos, girado / TAU, movido] +
							"ve a Johnny %s, fuera del mapa de caminos %d, siguiente %s, acabado %s, punto %d de %d, " % [
							z.se_ve(johnny), z.global_position.distance_to(NavigationServer2D.map_get_closest_point(red, z.global_position)),
							(ag.get_next_path_position() - z.global_position).round(), ag.is_navigation_finished(),
							ag.get_current_navigation_path_index(), camino.size()] +
							"velocidad %s, pedida %s, rumbo %s, apretado %s, sin esquivar %.1f" % [
							z.velocity.round(), ag.velocity.round(), z.rumbo, z.apretado, z.sin_esquivar])
						var choques := []
						for k in z.get_slide_collision_count():
							var c: KinematicCollision2D = z.get_slide_collision(k)
							choques.append("%s %s" % [c.get_collider().name if c.get_collider() else "?", c.get_normal().round()])
						var pegados := []
						for o in zombis:
							if is_instance_valid(o) and o != z and o.estado != "muerto" and o.global_position.distance_to(z.global_position) < 48.0:
								pegados.append("%s %s" % [o.get_meta("tipo"), (o.global_position - z.global_position).round()])
						print("   camino %s, choca con %s, pegados %s" % [
							Array(camino).map(func(v): return (v - z.global_position).round()), choques, pegados])
						if fotos < 4:
							fotos += 1
							for s in sitio.apt.salas:
								mapa.vistas[s.id] = true
								mapa.niebla[s.id] = 0.0
							mapa.actualizar_niebla(0.0)
							var cam: Camera2D = johnny.get_node("Camara")
							var antes := cam.offset
							cam.offset = z.global_position - johnny.global_position
							cam.reset_smoothing()
							await get_tree().process_frame
							Captura.foto("captura-vueltas-%d.png" % fotos)
							cam.offset = antes
							cam.reset_smoothing()
	var peores := maximo.values()
	peores.sort_custom(func(x, y): return x[0] > y[0])
	for w in peores.slice(0, 8):
		print("   lo que más gira sin moverse: %.2f vueltas · %s" % [w[0] / TAU, w[1]])
	print("Vueltas: %d de %d zombis dan vueltas (esperado: 0)" % [dan, total])
	Planta.semilla = 0
	Engine.time_scale = 1.0
	get_tree().quit()


# Con "--captura --cartel" (L41, 16 nov; con --edificio centro o torre): lo que pone el cartel de arriba en el pasillo y en
# cada puerta de las plantas 1 y 2 (en los Apartamentos, «Apartamento 1ºB»; en el centro, el nombre de la tienda; en la
# torre, «Oficina N», de izquierda a derecha). Foto de la primera tienda u oficina de la planta 2
# (captura-cartel-<edificio>.png). Luego se cierra
func probar_cartel() -> void:
	johnny.invencible = true
	var edificio: String = Captura.dato("--edificio", "apartamentos")
	for num in [1, 2]:
		nueva_planta(num)
		var pasillo: int = planta.sitios.find(planta.sitios.filter(func(s): return s.tipo == "pasillo")[0])
		await montar(pasillo, 0, false)
		var puertas := []
		for salida in planta.sitios[pasillo].salidas:
			if salida.tipo == "puerta" and planta.sitios[salida.a].tipo in ["apartamento", "jefe"]:
				puertas.append(salida)
		puertas.sort_custom(func(x, y): return x.en < y.en or (x.en == y.en and x.dir == "arriba"))
		var textos := ["pasillo «%s»" % lugar.text]
		var foto := false
		for salida in puertas:
			var sitio: Dictionary = planta.sitios[salida.a]
			await montar(salida.a, 0, false)
			textos.append("%s %d %s (%s) «%s»" % [salida.dir, salida.en, sitio.tipo, sitio.nombre, lugar.text])
			if num == 2 and not foto:
				foto = true
				await get_tree().create_timer(0.5).timeout
				Captura.foto("captura-cartel-%s.png" % edificio)
		print("Cartel · %s, planta %d: %s" % [edificio, num, " · ".join(textos)])
	get_tree().quit()


# Con "--captura --cama" (F23, 16 nov): el dormitorio de matrimonio de un piso con la puerta abajo y de otro con ella
# arriba (el de la cama en la pared de la izquierda). De la cama y de las mesillas, en la terminal, su choque y su dibujo
# (rectángulos en el mundo), y una foto de cada dormitorio (captura-cama-abajo.png y -arriba.png; con
# --debug-collisions se ven los choques). Luego se cierra
func probar_cama() -> void:
	nueva_planta(1)
	for lado in ["abajo", "arriba"]:
		var idx := -1
		for i in planta.sitios.size():
			if planta.sitios[i].tipo == "apartamento" and planta.sitios[i].apt.entrada.lado == lado:
				idx = i
				break
		if idx < 0:
			print("Cama: en la planta baja no hay ningún piso con la puerta %s" % lado)
			continue
		var sitio: Dictionary = planta.sitios[idx]
		sitio.limpio = true
		await montar(idx, 0, false)
		var sala: Dictionary = sitio.apt.salas.filter(func(s): return s.get("tipo", "") == "matrimonio")[0]
		for s in sitio.apt.salas:
			mapa.vistas[s.id] = true
			mapa.niebla[s.id] = 0.0
		mapa.actualizar_niebla(0.0)
		johnny.position = sala.centro
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		for m in get_tree().get_nodes_in_group("muebles"):
			if m.datos.zona != sala.id or not m.datos.tipo in ["doublebed", "nightstand"]:
				continue
			var sprite: Sprite2D = m.get_node("Sprite")
			var dib := Rect2(sprite.global_position + sprite.offset * 2.0, sprite.texture.get_size() * 2.0)
			var choque := Rect2(m.position + Vector2(-m.datos.w / 2.0, -m.datos.h), Vector2(m.datos.w, m.datos.h))
			print("Cama (puerta %s, %s): %s en la pared %s · choque %s · dibujo %s" % [lado, sitio.nombre, m.datos.tipo, m.datos.lado, choque, dib])
		# todos los choques (no las zonas) que caen en el dormitorio
		var cuarto := Rect2(sala.c0 * 32.0, sala.f0 * 32.0, sala.ancho * 32.0, sala.fondo * 32.0)
		print("Cama (puerta %s): el dormitorio %s" % [lado, cuarto])
		for f in get_tree().root.find_children("*", "CollisionShape2D", true, false):
			if f.disabled or not f.get_parent() is PhysicsBody2D or not f.shape is RectangleShape2D:
				continue
			var tam: Vector2 = (f.shape as RectangleShape2D).size * f.global_scale
			var r := Rect2(f.global_position - tam / 2.0, tam)
			if r.intersects(cuarto) and not r.encloses(cuarto) and r.size.x < 600 and r.size.y < 600:
				print("   choque de %s (%s): %s" % [f.get_parent().name, f.get_parent().get_class(), r])
		Captura.foto("captura-cama-%s.png" % lado)
	get_tree().quit()


# Con "--captura --mueble-puerta" (F25, 16 nov): un mueble que se abre (Objetos.MUEBLES_CON_PIEZA) cuya zona se pisa con
# la de una puerta de dentro. Johnny donde llegan las dos, más cerca de la puerta pero sin tocarla: la E abre el mueble y
# la puerta se queda como estaba (captura-mueble-puerta.png). Tocando la puerta, la puerta ya no cede. Luego se cierra
func probar_mueble_puerta() -> void:
	var rect_de := func(zona: Area2D) -> Rect2:
		var forma: CollisionShape2D = zona.get_children().filter(func(c): return c is CollisionShape2D)[0]
		var tam: Vector2 = (forma.shape as RectangleShape2D).size
		return Rect2(forma.global_position - tam / 2.0, tam)
	for num in [2, 3, 4]:
		nueva_planta(num)
		for idx in planta.sitios.size():
			var sitio: Dictionary = planta.sitios[idx]
			if not sitio.has("apt") or not sitio.get("muebles", []).any(func(m): return m.tipo in Objetos.MUEBLES_CON_PIEZA):
				continue
			sitio.limpio = true
			await montar(idx, 0, false)
			await get_tree().create_timer(0.2).timeout
			for m in mapa.muebles:
				if not m.datos.tipo in Objetos.MUEBLES_CON_PIEZA or not m.has_node("Zona"):
					continue
				var zm: Area2D = m.get_node("Zona")
				for h in mapa.hojas:
					if h.uso == null:
						continue
					var zp: Area2D = h.uso.get_node("Zona")
					var juntas: Rect2 = rect_de.call(zm).intersection(rect_de.call(zp))
					if juntas.size.x < 8 or juntas.size.y < 8:
						continue
					# el punto de las dos zonas más cerca de la puerta, sin tocarla
					var mejor := Vector2.INF
					for i in 9:
						for j in 9:
							var p := juntas.position + juntas.size * Vector2(0.05 + 0.1125 * i, 0.05 + 0.1125 * j)
							if h.caja.grow(h.ARRIMADO + 4).has_point(p):
								continue
							var ventaja := func(q: Vector2) -> float: return q.distance_to(m.global_position) - q.distance_to(h.caja.get_center())
							if mejor == Vector2.INF or ventaja.call(p) > ventaja.call(mejor):
								mejor = p
					if mejor == Vector2.INF:
						continue
					for z in get_tree().get_nodes_in_group("zombis"):
						z.queue_free()
					johnny.position = mejor
					johnny.get_node("Camara").reset_smoothing()
					await get_tree().create_timer(1.2).timeout   # (que la puerta acabe lo que estuviera haciendo)
					var abierta_antes: float = h.abierta
					var cerca_puerta: bool = zp.distancia() < zm.distancia()
					pulsar_accion("usar", true)
					await get_tree().physics_frame
					pulsar_accion("usar", false)
					await get_tree().create_timer(0.6).timeout
					print("Mueble y puerta (%s, %s): Johnny en las dos zonas, más cerca de la puerta %s · E: mueble abierto %s, puerta igual %s (%.2f → %.2f) (esperado: true, true)" % [
						sitio.nombre, m.datos.tipo, cerca_puerta, m.datos.get("abierto", false), h.abierta == abierta_antes, abierta_antes, h.abierta])
					Captura.foto("captura-mueble-puerta.png")
					# tocando la puerta (pegado al hueco, por fuera), la puerta no cede
					var fuera := Vector2(0, 1) if h.de_frente else Vector2(1, 0)
					var medio: float = (h.caja.size.y if h.de_frente else h.caja.size.x) / 2.0
					johnny.position = h.caja.get_center() + fuera * (medio + h.HOLGURA + 6.0)
					# (arrimado, se abre sola; mientras, no tiene zona: se hace de nuevo cada vez que acaba de abrirse o cerrarse)
					for espera in 40:
						await get_tree().create_timer(0.1).timeout
						if h.uso != null:
							break
					zp = h.uso.get_node("Zona")
					print("Mueble y puerta: tocando la puerta, cede %s (esperado: false)" % zp.cede())
					get_tree().quit()
					return
	print("Mueble y puerta: no se ha encontrado ningún mueble junto a una puerta")
	get_tree().quit()


# Con "--captura --muebles-familias" (16 nov): los muebles solo dan materiales de las familias de las armas que lleva Johnny
# (partida.familias_que_lleva: la de la mano, las de repuesto y los lanzables si lleva alguno). Para cada equipo cuenta, en
# 4000 aperturas, de qué familias salen materiales (cada línea dice lo esperado). Se cierra
func probar_muebles_familias() -> void:
	await get_tree().create_timer(0.5).timeout
	var cuenta := func() -> Dictionary:
		var c := {}
		for i in 4000:
			var p := Objetos.pieza_de_mueble(familias_que_lleva())
			c[p] = c.get(p, 0) + 1
		c.erase("")
		return c
	lanzables.vaciar()
	armas_guardadas.clear()
	johnny.huecos = Armas.SIEMPRE.duplicate()
	print("Muebles familias · solo la fregona: lleva %s, salen %s (esperado: [cuerpo], solo pieza_cuerpo)" % [familias_que_lleva(), cuenta.call().keys()])
	llevar_arma("pistola", 0, true, false)
	print("Muebles familias · fregona y pistola: lleva %s, salen %s (esperado: cuerpo y distancia)" % [familias_que_lleva(), cuenta.call().keys()])
	llevar_arma("lanzallamas", 0, true, false)
	print("Muebles familias · y el lanzallamas (la pistola, de repuesto): lleva %s, salen %s (esperado: cuerpo, distancia y especial)" % [familias_que_lleva(), cuenta.call().keys()])
	lanzables.sumar("molotov")
	print("Muebles familias · y un molotov: lleva %s, salen %s (esperado: las cuatro)" % [familias_que_lleva(), cuenta.call().keys()])
	armas_guardadas.clear()
	johnny.huecos = Armas.SIEMPRE.duplicate()
	print("Muebles familias · fregona y un molotov: lleva %s, salen %s (esperado: cuerpo y arrojable)" % [familias_que_lleva(), cuenta.call().keys()])
	get_tree().quit()


# Con "--captura --muebles-materiales" (Fase 4): los muebles que se abren (el armario, la mesilla, el escritorio y la
# librería, Objetos.MUEBLES_CON_PIEZA). Johnny delante de uno de la pared de arriba: el contorno amarillo
# (captura-mueble-contorno.png); se abre con E y suelta un material (si sale vacío, «Vacío», se cierra a mano y se vuelve
# a abrir hasta que salga uno; captura-mueble-material.png, con Johnny apartado para que se vea en el suelo); ya abierto,
# sin contorno y E no lo vuelve a abrir; al coger el material sale el tutorial de los materiales
# (captura-mueble-tutorial.png). Y cuántos muebles de esos hay en la planta. Luego se cierra
func probar_muebles_materiales() -> void:
	var cuantos := 0
	var sitio := -1
	for j in planta.sitios.size():
		for m in planta.sitios[j].get("muebles", []):
			if m.tipo in Objetos.MUEBLES_CON_PIEZA:
				cuantos += 1
				if sitio < 0 and m.lado == "arriba":
					sitio = j
	print("Muebles materiales · en esta planta se abren %d muebles (con un 35 %% de material, unos %d)" % [cuantos, roundi(cuantos * Objetos.PIEZA_MUEBLE)])
	if sitio < 0:
		print("Muebles materiales · no hay ninguno en la pared de arriba")
		get_tree().quit()
		return
	await montar(sitio, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var mueble: Node2D = null
	for m in mapa.muebles:
		if m.datos.tipo in Objetos.MUEBLES_CON_PIEZA and m.datos.lado == "arriba":
			mueble = m
			break
	# todo el piso descubierto, para que se vea el mueble
	for s in planta.sitios[sitio].apt.salas:
		mapa.vistas[s.id] = true
		mapa.niebla[s.id] = 0.0
	mapa.actualizar_niebla(0.0)
	johnny.position = mueble.position + Vector2(0, 20)
	johnny.get_node("Camara").reset_smoothing()
	mochila.clear()
	await get_tree().create_timer(0.6, false).timeout
	var zona: Area2D = mueble.get_node("Zona")
	print("Muebles materiales · %s: contorno con Johnny delante %s (esperado: true)" % [mueble.datos.tipo, zona.contorno.visible])
	Captura.foto("captura-mueble-contorno.png")
	# se abre con E; si sale vacío, se cierra a mano y otra vez (hasta 30), para ver un material (sin imán, para que se
	# quede en el suelo y salga en la foto)
	var iman: float = johnny.stats.iman
	johnny.stats.iman = 0.0
	var vacios := 0
	var piezas: Array = []
	for intento in 30:
		mueble.datos.abierto = false
		pulsar_accion("usar", true)
		await get_tree().physics_frame
		pulsar_accion("usar", false)
		if intento == 0:   # el nombre de lo que da, encima de Johnny (17 nov)
			await get_tree().create_timer(0.25, false).timeout
			var avisos := johnny.get_parent().get_children().filter(func(c): return c is Label and c.modulate.a > 0.0 and c.size.y > 30)
			print("Muebles materiales · aviso encima de Johnny: %s (esperado: VACÍO o el nombre del material en mayúsculas)" % [avisos.map(func(c): return c.text)])
			Captura.foto("captura-mueble-aviso.png")
		johnny.position = mueble.position + Vector2(140, 60)   # apartado, para que el material se quede en el suelo
		await get_tree().create_timer(0.15, false).timeout
		piezas = mapa.cosas.get_children().filter(func(c): return c.get("icono") is Texture2D \
			and c.icono.resource_path.contains("obj-pieza") and not c.is_queued_for_deletion())
		if not piezas.is_empty():
			break
		vacios += 1
		if vacios == 1:
			await get_tree().create_timer(0.2, false).timeout
			Captura.foto("captura-mueble-vacio.png")
		johnny.position = mueble.position + Vector2(0, 20)
		await get_tree().create_timer(0.3, false).timeout
	await get_tree().create_timer(0.8, false).timeout
	print("Muebles materiales · vacíos antes del primer material %d · materiales en el suelo %d (esperado: 1) · %s" % [
		vacios, piezas.size(), piezas[0].icono.resource_path.get_file() if piezas else "-"])
	print("Muebles materiales · abierto %s (esperado: true) · contorno %s (esperado: false)" % [mueble.datos.abierto, zona.contorno.visible])
	Captura.foto("captura-mueble-material.png")
	# ya abierto: delante otra vez, E no lo vuelve a abrir
	johnny.position = mueble.position + Vector2(0, 20)
	# solo queda sin ver el tutorial de los materiales (si no, sale antes otro, como el de cambiar de arma)
	Tutoriales.olvidar()
	for id in Tutoriales.LISTA:
		if id != "piezas":
			Tutoriales.apuntar(id)
	tutoriales_prueba = true
	# (desde aquí, relojes que corren también en pausa: si Johnny pisa el material, el tutorial para el juego)
	await get_tree().create_timer(0.3).timeout
	var antes := piezas.size()
	pulsar_accion("usar", true)
	await get_tree().physics_frame
	pulsar_accion("usar", false)
	await get_tree().create_timer(0.3).timeout
	var ahora: int = mapa.cosas.get_children().filter(func(c): return c.get("icono") is Texture2D \
		and c.icono.resource_path.contains("obj-pieza") and not c.is_queued_for_deletion()).size()
	print("Muebles materiales · al pulsar E otra vez, materiales en el suelo %d (esperado: %d o menos)" % [ahora, antes])
	# a coger el material: sale el tutorial
	johnny.stats.iman = iman
	if piezas:
		johnny.position = piezas[0].position
	await get_tree().create_timer(1.0).timeout
	var ventana: Tutorial = null
	for h in get_children():
		if h is Tutorial and not h.is_queued_for_deletion():
			ventana = h
	print("Muebles materiales · en la mochila %s · tutorial: %s (esperado: una pieza_* y piezas)" % [mochila, ventana.id if ventana else "ninguno"])
	Captura.foto("captura-mueble-tutorial.png")
	get_tree().quit()


# Con "--captura --comida" (M124, 16 nov): la comida favorita de los supervivientes. Con la médica y el policía viviendo
# en los trasteros: cuántas neveras y encimeras se abren en la planta; delante de una, su contorno, y con E suelta una
# comida (la manzana o el dónut; si sale vacía, se cierra a mano y otra vez: captura-comida-nevera.png) y su tutorial
# (captura-comida-tutorial.png). Luego en los trasteros: delante de la médica, sin su manzana, «¿NO TENDRÁS POR AHÍ UNA MANZANA?» en blanco
# (captura-comida-debil.png); con el dónut en la mochila, el policía se lo come y te acompaña
# (captura-comida-acompana.png); y con la manzana en el baúl, la médica (y el policía vuelve a su trastero). Al final, el
# guardado como estaba
# --charla (17 nov): en los trasteros, el contorno amarillo del vecino con Johnny delante y la ventana de su vida al pulsar
# la E: con la comida en amarillo, «Seguir» y «Dar de comer» (apagado sin su comida; con ella, te acompaña)
func probar_charla() -> void:
	var g := Guardado.cargar()
	var antes := [g.rescatados.duplicate(), g.acompanante, g.baul.duplicate()]
	Guardado.cambiar(func(x):
		x.rescatados = ["policia", "tecnico", "limpiadora"]
		x.acompanante = ""
		x.baul.erase("donut")
		x.baul.erase("energetica"))
	mochila.clear()
	await montar(planta.viviendas, 0, false)
	var sup: Supervivientes = supervivientes
	var policia: Aliado = sup.vecinos.filter(func(v): return v.def.id == "policia")[0]
	var tecnico: Aliado = sup.vecinos.filter(func(v): return v.def.id == "tecnico")[0]
	var zona: Area2D = policia.get_node("Zona")
	print("Charla · lejos del policía: contorno %s (esperado: false)" % zona.contorno.visible)
	await sup.arrimarse(policia)
	johnny.position = policia.position + (johnny.position - policia.position).normalized() * 60.0   # (que no le tape)
	await get_tree().create_timer(0.2, false).timeout
	print("Charla · delante del policía: contorno %s, mismo fotograma %s (esperado: true, true)" % [zona.contorno.visible,
		zona.contorno.frame == policia.sprite.frame and zona.contorno.animation == policia.sprite.animation])
	Captura.foto("captura-charla-contorno.png")
	# sin su dónut: «Dar de comer», apagado, y la nota de dónde sale
	await sup.usar_delante()
	await get_tree().create_timer(0.7, true).timeout   # (los botones se encienden a las 0,6 s)
	print("Charla · el policía sin dónut: ventana %s · título «%s» · el dónut en amarillo %s · apagado %s · nota «%s» · juego parado %s" % [
		sup.charla != null, sup.charla.titulo if sup.charla else "", sup.charla.texto.contains("[color=") if sup.charla else false,
		sup.charla.apagado(1) if sup.charla else false, sup.charla.nota if sup.charla else "", get_tree().paused])
	print("        (esperado: true, Policía, true, true, No llevas su comida favorita..., true)")
	Captura.foto("captura-charla-sin-comida.png")
	await sup.responder(0)
	print("Charla · tras «Seguir»: ventana %s · juego parado %s · acompaña '%s' (esperado: false, false, '')" % [
		sup.charla != null, get_tree().paused, Guardado.cargar().acompanante])
	# con su bebida energética en la mochila: «Dar de comer» encendido y te acompaña
	mochila.append("energetica")
	await sup.arrimarse(tecnico)
	await sup.usar_delante()
	await get_tree().create_timer(0.7, true).timeout
	print("Charla · el técnico con su bebida: apagado %s · nota «%s» (esperado: false, '')" % [
		sup.charla.apagado(1) if sup.charla else true, sup.charla.nota if sup.charla else "?"])
	Captura.foto("captura-charla-con-comida.png")
	await sup.responder(1)
	await get_tree().create_timer(0.4, false).timeout
	print("Charla · tras «Dar de comer»: acompaña '%s' · mochila %s · contorno del técnico %s (esperado: tecnico, [], false)" % [
		Guardado.cargar().acompanante, mochila, tecnico.get_node("Zona").contorno.visible])
	# los textos de todos, con su comida entre asteriscos (la que sale en amarillo)
	var mal := Supervivientes.DATOS.keys().filter(func(id): return Supervivientes.VIDAS.get(id, "").count("*") != 2)
	print("Charla · vidas sin su comida entre dos asteriscos: %s (esperado: [])" % [mal])
	Guardado.cambiar(func(x):
		x.rescatados = antes[0]
		x.acompanante = antes[1]
		x.baul = antes[2])
	get_tree().quit()


func probar_comida() -> void:
	var g := Guardado.cargar()
	var antes := [g.rescatados.duplicate(), g.acompanante, g.baul.duplicate()]
	Guardado.cambiar(func(x):
		x.rescatados = ["policia", "medico"]
		x.acompanante = ""
		x.baul.erase("manzana")
		x.baul.erase("donut"))
	var cuantos := 0
	var sitio := -1
	for j in planta.sitios.size():
		for m in planta.sitios[j].get("muebles", []):
			if m.tipo in Objetos.MUEBLES_CON_COMIDA:
				cuantos += 1
				if sitio < 0 and m.lado == "arriba":
					sitio = j
	print("Comida · en esta planta, neveras y encimeras %d (con un 35 %% de comida, unas %d)" % [cuantos, roundi(cuantos * Objetos.COMIDA_MUEBLE)])
	var salidas := []
	for i in 400:
		var c := Objetos.comida_de_mueble()
		if c != "":
			salidas.append(c)
	print("Comida · de 400 aperturas, con comida %d (esperado: unas 140) · solo dónut y manzana %s (esperado: true)" % [
		salidas.size(), salidas.all(func(c): return c in ["donut", "manzana"])])
	if sitio < 0:
		print("Comida · no hay ninguna nevera ni encimera en la pared de arriba")
		get_tree().quit()
		return
	await montar(sitio, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var mueble: Node2D = null
	for m in mapa.muebles:
		if m.datos.tipo in Objetos.MUEBLES_CON_COMIDA and m.datos.lado == "arriba":
			mueble = m
			break
	for s in planta.sitios[sitio].apt.salas:
		mapa.vistas[s.id] = true
		mapa.niebla[s.id] = 0.0
	mapa.actualizar_niebla(0.0)
	johnny.position = mueble.position + Vector2(0, 20)
	johnny.get_node("Camara").reset_smoothing()
	mochila.clear()
	await get_tree().create_timer(0.6, false).timeout
	var zona: Area2D = mueble.get_node_or_null("Zona")
	print("Comida · %s: zona %s, contorno con Johnny delante %s (esperado: true, true)" % [mueble.datos.tipo, zona != null,
		zona.contorno.visible if zona and zona.contorno else false])
	var iman: float = johnny.stats.iman
	johnny.stats.iman = 0.0
	var vacios := 0
	var comidas: Array = []
	for intento in 30:
		mueble.datos.abierto = false
		pulsar_accion("usar", true)
		await get_tree().physics_frame
		pulsar_accion("usar", false)
		johnny.position = mueble.position + Vector2(140, 60)   # apartado, para que la comida se quede en el suelo
		await get_tree().create_timer(0.15, false).timeout
		comidas = mapa.cosas.get_children().filter(func(c): return c.get("icono") is Texture2D \
			and Objetos.COMIDAS.any(func(id): return c.icono.resource_path.ends_with("obj-%s.png" % id)) and not c.is_queued_for_deletion())
		if not comidas.is_empty():
			break
		vacios += 1
		johnny.position = mueble.position + Vector2(0, 20)
		await get_tree().create_timer(0.3, false).timeout
	await get_tree().create_timer(0.5, false).timeout
	print("Comida · vacías antes de la primera %d · en el suelo %s (esperado: obj-donut u obj-manzana)" % [vacios,
		comidas.map(func(c): return c.icono.resource_path.get_file())])
	Captura.foto("captura-comida-nevera.png")
	# su tutorial (sale al abrir la primera que la tiene: partida.abrir_mueble)
	Tutoriales.olvidar()
	for id in Tutoriales.LISTA:
		if id != "comida":
			Tutoriales.apuntar(id)
	tutoriales_prueba = true
	tutorial("comida")
	await get_tree().create_timer(1.0, true).timeout
	var ventana: Tutorial = null
	for h in get_children():
		if h is Tutorial and not h.is_queued_for_deletion():
			ventana = h
	print("Comida · tutorial: %s (esperado: comida)" % [ventana.id if ventana else "ninguno"])
	Captura.foto("captura-comida-tutorial.png")
	if ventana:
		ventana.cerrar()
	await get_tree().create_timer(0.5, true).timeout
	johnny.stats.iman = iman
	# en los trasteros
	mochila.clear()
	await montar(planta.viviendas, 0, false)
	var sup: Supervivientes = supervivientes
	var medica: Aliado = sup.vecinos.filter(func(v): return v.def.id == "medico")[0]
	var policia: Aliado = sup.vecinos.filter(func(v): return v.def.id == "policia")[0]
	await sup.arrimarse(medica)
	await sup.usar_delante()
	print("Comida · la médica sin su manzana: charla %s · «Dar de comer» apagado %s (esperado: true, true)" % [
		sup.charla != null, sup.charla.apagado(1) if sup.charla else false])
	Captura.foto("captura-comida-debil.png")
	await sup.responder(1)   # (apagado: no hace nada más que cerrarla)
	print("Comida · la médica, tras «Dar de comer» sin manzana: acompaña '%s' (esperado: '')" % Guardado.cargar().acompanante)
	mochila.append("donut")
	await sup.arrimarse(policia)
	await sup.usar_delante()
	await sup.responder(1)
	await get_tree().create_timer(0.4, false).timeout
	print("Comida · el policía con el dónut en la mochila: acompaña '%s' · equipo %s · mochila %s (esperado: policia, [Policía], [])" % [
		Guardado.cargar().acompanante, sup.equipo.map(func(a): return a.def.nombre), mochila])
	Captura.foto("captura-comida-acompana.png")
	Guardado.cambiar(func(x): x.baul["manzana"] = 1)
	await sup.arrimarse(medica)
	await sup.usar_delante()
	await sup.responder(1)
	print("Comida · la médica con la manzana en el baúl: acompaña '%s' · manzanas en el baúl %d · el policía, en «%s» (esperado: medico, 0, Policía)" % [
		Guardado.cargar().acompanante, int(Guardado.cargar().baul.get("manzana", 0)), mapa.nombre_zona(mapa.zona_en(policia.position))])
	Guardado.cambiar(func(x):
		x.rescatados = antes[0]
		x.acompanante = antes[1]
		x.baul = antes[2])
	get_tree().quit()


# Con "--captura --edificio centro --rodear-muebles" (19 nov, el dueño): en la sala de venta de la tienda de ropa (--tipo X, otra
# tienda), normal e inversa, que a cada mueble suelto (el que no está pegado a una pared) se llega por sus cuatro lados, para
# rodearlo, y que no hay rincones encerrados entre muebles donde quedarse atascado. Se mira con el cuerpo de Johnny (un círculo de
# 18 de radio) en una rejilla de 8 en 8 unidades: los puntos donde cabe, y cuáles se alcanzan andando desde la entrada. Al final,
# «Rodear: TODO BIEN» o los fallos, y una foto de cada una con los rincones encerrados en rojo (captura-rodear-<tipo>-<lado>.png)
const RODEAR_PASO := 8.0
const RODEAR_RADIO := 18.0

func probar_rodear_muebles() -> void:
	var args := OS.get_cmdline_user_args()
	var tipo: String = args[args.find("--tipo") + 1] if "--tipo" in args else "ropa"
	var fallos := 0
	for lado in ["abajo", "arriba"]:
		var hallada := {}
		for i in 200:
			Planta.semilla = 3000 + i
			var num := 1 + i % 4
			var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
			for idx in p.sitios.size():
				if p.sitios[idx].get("tienda", "") == tipo and p.sitios[idx].tipo != "jefe" and p.sitios[idx].apt.entrada.lado == lado:
					hallada = {"semilla": 3000 + i, "num": num, "idx": idx}
					break
			if not hallada.is_empty():
				break
		if hallada.is_empty():
			print("Rodear %s (puerta %s): no sale en ninguna planta" % [tipo, lado])
			fallos += 1
			continue
		Planta.semilla = hallada.semilla
		nueva_planta(hallada.num)
		Planta.semilla = 0
		var sitio: Dictionary = planta.sitios[hallada.idx]
		sitio.limpio = true
		await montar(hallada.idx, 0, false)
		await get_tree().create_timer(0.4).timeout
		var sala: Dictionary = {}
		for s in sitio.apt.salas:
			if s.uso == "tienda":
				sala = s
		# los puntos de la sala de venta donde cabe Johnny
		var espacio: PhysicsDirectSpaceState2D = johnny.get_world_2d().direct_space_state
		var consulta := PhysicsShapeQueryParameters2D.new()
		var circulo := CircleShape2D.new()
		circulo.radius = RODEAR_RADIO
		consulta.shape = circulo
		consulta.collision_mask = johnny.collision_mask
		consulta.exclude = [johnny.get_rid()]
		var cabe := {}
		var ancho := int(sitio.ancho / RODEAR_PASO)
		var alto := int(sitio.alto / RODEAR_PASO)
		for gy in alto:
			for gx in ancho:
				var q := Vector2((gx + 0.5) * RODEAR_PASO, (gy + 0.5) * RODEAR_PASO)
				if mapa.zona_en(q) != sala.id:
					continue
				consulta.transform = Transform2D(0.0, q)
				if espacio.intersect_shape(consulta, 1).is_empty():
					cabe[Vector2i(gx, gy)] = true
		# los que se alcanzan andando desde la entrada (el punto donde cabe más cerca de Johnny, que entra por ella)
		var inicio := Vector2i(-1, -1)
		var mejor := INF
		for k in cabe:
			var d: float = ((Vector2(k) + Vector2(0.5, 0.5)) * RODEAR_PASO).distance_to(johnny.global_position)
			if d < mejor:
				mejor = d
				inicio = k
		var llega := {inicio: true}
		var cola: Array = [inicio]
		while not cola.is_empty():
			var k: Vector2i = cola.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = k + d
				if cabe.has(n) and not llega.has(n):
					llega[n] = true
					cola.append(n)
		# los muebles sueltos de la sala de venta: los que tienen sala por sus cuatro lados (a 24 de cada borde)
		var sueltos := []
		for m in mapa.muebles:
			var forma: CollisionShape2D = null
			for h in m.get_children():
				if h is CollisionShape2D:
					forma = h
			if forma == null:
				continue
			var tam: Vector2 = (forma.shape as RectangleShape2D).size
			var caja := Rect2(m.global_position + forma.position - tam / 2.0, tam)
			if mapa.zona_en(caja.get_center()) != sala.id:
				continue
			var suelto := true
			for q in [Vector2(caja.get_center().x, caja.position.y - 24), Vector2(caja.get_center().x, caja.end.y + 24),
					Vector2(caja.position.x - 24, caja.get_center().y), Vector2(caja.end.x + 24, caja.get_center().y)]:
				if mapa.zona_en(q) != sala.id:
					suelto = false
			if suelto:
				sueltos.append({"tipo": m.datos.tipo, "caja": caja})
		# los que están tan juntos que Johnny no pasa entre ellos (menos de su ancho, 36), un solo bloque: se rodean juntos
		var bloques := []
		for s in sueltos:
			var junto: Array = bloques.filter(func(b): return b.any(func(o): return o.caja.grow(RODEAR_RADIO).intersects(s.caja.grow(RODEAR_RADIO))))
			var nuevo := [s]
			for b in junto:
				nuevo += b
				bloques.erase(b)
			bloques.append(nuevo)
		for b in bloques:
			var caja: Rect2 = b[0].caja
			for o in b:
				caja = caja.merge(o.caja)
			var nombre: String = " + ".join(b.map(func(o): return o.tipo))
			# por cada lado, algún punto alcanzable pegado a él (a menos de 34 del borde, a lo largo de todo el lado)
			var sin_llegar := []
			for l in ["arriba", "abajo", "izquierda", "derecha"]:
				var hay := false
				for k in llega:
					var q := (Vector2(k) + Vector2(0.5, 0.5)) * RODEAR_PASO
					var dentro: bool
					match l:
						"arriba":
							dentro = q.x > caja.position.x and q.x < caja.end.x and q.y < caja.position.y and q.y > caja.position.y - RODEAR_RADIO - 16
						"abajo":
							dentro = q.x > caja.position.x and q.x < caja.end.x and q.y > caja.end.y and q.y < caja.end.y + RODEAR_RADIO + 16
						"izquierda":
							dentro = q.y > caja.position.y and q.y < caja.end.y and q.x < caja.position.x and q.x > caja.position.x - RODEAR_RADIO - 16
						_:
							dentro = q.y > caja.position.y and q.y < caja.end.y and q.x > caja.end.x and q.x < caja.end.x + RODEAR_RADIO + 16
					if dentro:
						hay = true
						break
				if not hay:
					sin_llegar.append(l)
			var juntos := " (juntos: Johnny no pasa entre ellos)" if b.size() > 1 else ""
			if sin_llegar.is_empty():
				print("Rodear %s (puerta %s): %s se rodea%s" % [tipo, lado, nombre, juntos])
			else:
				fallos += 1
				print("Rodear %s (puerta %s): FALLO %s en (%d, %d)%s: no se llega por %s" % [tipo, lado, nombre, caja.get_center().x,
					caja.get_center().y, juntos, ", ".join(sin_llegar)])
		# los rincones encerrados: grupos de puntos donde cabe Johnny pero a los que no se llega
		var vistos := {}
		var rincones := []
		for k in cabe:
			if llega.has(k) or vistos.has(k):
				continue
			var grupo := [k]
			vistos[k] = true
			var i := 0
			while i < grupo.size():
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = grupo[i] + d
					if cabe.has(n) and not llega.has(n) and not vistos.has(n):
						vistos[n] = true
						grupo.append(n)
				i += 1
			rincones.append(grupo)
		for g in rincones:
			fallos += 1
			var centro := Vector2.ZERO
			for k in g:
				centro += (Vector2(k) + Vector2(0.5, 0.5)) * RODEAR_PASO
			centro /= g.size()
			print("Rodear %s (puerta %s): FALLO rincón encerrado de %d puntos en (%d, %d)" % [tipo, lado, g.size(), centro.x, centro.y])
		print("Rodear %s (puerta %s): %d muebles sueltos (%d bloques), %d puntos donde cabe Johnny, %d alcanzables, %d rincones encerrados" % [
			tipo, lado, sueltos.size(), bloques.size(), cabe.size(), llega.size(), rincones.size()])
		# la foto, con los rincones encerrados en rojo
		var marcas := Node2D.new()
		marcas.z_index = 100
		marcas.draw.connect(func():
			for g in rincones:
				for k in g:
					marcas.draw_rect(Rect2(Vector2(k) * RODEAR_PASO, Vector2(RODEAR_PASO, RODEAR_PASO)), Color(1, 0, 0, 0.6)))
		mapa.add_child(marcas)
		johnny.position = Vector2(sitio.ancho / 2.0, sitio.alto / 2.0)
		await foto_entera(sitio, "captura-rodear-%s-%s.png" % [tipo, lado])
		marcas.queue_free()
	if fallos > 0:   # (así tools/antes_de_version.py la da por mala)
		Captura.fallar("Rodear: %d FALLOS (mira las líneas de «FALLO» de más arriba)" % fallos)
		return
	print("Rodear: TODO BIEN")
	get_tree().quit()


# Con "--captura --edificio centro --dependientas" (19 nov, el dueño: «en todas las tiendas de ropa habrá una dependienta»): en 200
# plantas sorteadas, cuántas dependientas tiene cada tienda de ropa (esperado: siempre una) y, para comparar, las demás tiendas
# (como mucho una, a suertes). Falla (código 1) si alguna tienda de ropa no tiene justo una. Y fotos de una tienda de ropa con sus
# zombis y la dependienta rodeada (captura-dependienta-tienda.png y -cerca.png). Luego se cierra
func probar_dependientas() -> void:
	var ropa := {}
	var otras := {}
	for i in 200:
		Planta.semilla = 7000 + i
		var num := 1 + i % 4
		var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
		for s in p.sitios:
			if s.get("tienda", "") == "" or not s.has("zombis") or s.tipo == "jefe":   # (la del jefe, sin zombis de los de siempre)
				continue
			var n: int = s.zombis.filter(func(z): return z.tipo == "dependienta").size()
			var cuenta: Dictionary = ropa if s.tienda == "ropa" else otras
			cuenta[n] = cuenta.get(n, 0) + 1
	Planta.semilla = 0
	print("Dependientas en las tiendas de ropa (cuántas tiendas con 0, 1, 2...): %s (esperado: todas con 1)" % ropa)
	print("Dependientas en las demás tiendas: %s (como mucho 1, a suertes)" % otras)
	if ropa.is_empty() or ropa.keys() != [1]:
		Captura.fallar("alguna tienda de ropa no tiene justo una dependienta: %s" % ropa)
		return
	# y una tienda de ropa entera con sus zombis dormidos y la dependienta rodeada en amarillo (captura-dependienta-tienda.png; el
	# recorte de cerca, captura-dependienta-cerca.png)
	for i in 200:
		Planta.semilla = 7000 + i
		var num := 1 + i % 4
		var p: Dictionary = Planta.generar(num, edificio, jefe_de(num))
		var idx := -1
		for k in p.sitios.size():
			if p.sitios[k].get("tienda", "") == "ropa" and p.sitios[k].tipo != "jefe" and p.sitios[k].apt.entrada.lado == "abajo":
				idx = k
		if idx < 0:
			continue
		nueva_planta(num)
		Planta.semilla = 0
		await montar(idx, 0, false)
		await get_tree().create_timer(0.4).timeout
		var sitio: Dictionary = planta.sitios[idx]
		var ella: Node2D = null
		for z in get_tree().get_nodes_in_group("zombis"):
			if z.get_script().resource_path.ends_with("zombi_dependienta.gd"):
				ella = z
		if ella == null:
			Captura.fallar("la tienda de ropa montada no tiene dependienta")
			return
		var aro := Node2D.new()
		aro.z_index = 100
		aro.draw.connect(func(): aro.draw_arc(ella.global_position + Vector2(0, -50), 75.0, 0.0, TAU, 48, Color(1, 0.85, 0.1), 4.0))
		mapa.add_child(aro)
		for p2 in mapa.puertas:
			johnny.position = p2.position + Vector2(0, -90)
		await foto_entera(sitio, "captura-dependienta-tienda.png")
		aro.queue_free()
		# de cerca: la cámara encima de ella (Johnny lejos, en la entrada: sigue dormida)
		var camara: Camera2D = johnny.get_node("Camara")
		$Pantalla.hide()
		Temblor.desplazamiento = ella.global_position + Vector2(0, -40) - johnny.position
		camara.reset_smoothing()
		Luz.apagada = not Luz.apagada
		await get_tree().create_timer(0.6).timeout
		Captura.foto("captura-dependienta-cerca.png")
		Luz.apagada = not Luz.apagada
		Temblor.desplazamiento = Vector2.ZERO
		$Pantalla.show()
		print("Dependientas: foto de la tienda %d de la planta %d (semilla %d), ella en (%d, %d)" % [idx, num, 7000 + i,
			ella.global_position.x, ella.global_position.y])
		break
	print("Dependientas: TODO BIEN")
	get_tree().quit()
