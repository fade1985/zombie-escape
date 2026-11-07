# Pruebas de sitios: la sala de mantenimiento (--sala), el ascensor (--ascensor), las viviendas (--viviendas),
# el piso de los apartamentos (--piso), las puertas de dentro (--puertas), el pasillo de la planta y su cartel (--pasillo),
# la joyería (--joyeria) y cómo suena la pistola en cada sitio (--acustica). Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_fotos.gd"


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
		print("Pasillo de la planta %d: muebles %d (esperado: 0, de momento va vacío)" % [num - 1,
			get_tree().get_nodes_in_group("muebles").size()])
		print("  [%s] «%s» · puertas «%s» y «%s» (en español: «%s», «%s» y «%s»)" % [Idioma.actual, Planta.nombre_de(planta),
			Planta.nombre_de_sitio({"nombre": Planta.nombre_puerta(num, "A")}),
			Planta.nombre_de_sitio({"nombre": Planta.nombre_puerta(num, "D")}), planta.nombre,
			Planta.nombre_puerta(num, "A"), Planta.nombre_puerta(num, "D")])
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


# Con "--captura --llegada": por dónde se llega a cada planta. La planta baja (el portal del edificio) tiene su puerta de
# llegada a la izquierda; las demás plantas, ninguna: se llega por las escaleras de la derecha, las mismas por las que se
# sale, y la azotea, por la escalera de su derecha (como la salida de incendios). De cada una dice cuántas puertas tiene a la izquierda, por
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


func probar_zombis_sala() -> void:
	var pisos := 0
	var total := 0
	var mas := 0
	var pocos := {}        # habitaciones con menos de 2 zombis: cuántas veces, por nombre
	var cerca_puerta := 0
	var juntos := 0
	var salas_n := 0
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
	await ida_y_vuelta("Joyería, cerrada y con la tarjeta dorada en el suelo", 0)
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
func foto_entera(sitio: Dictionary, nombre: String) -> void:
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
	Luz.apagada = not Luz.apagada   # sin penumbra, para que se vea todo
	await get_tree().create_timer(0.6).timeout
	Captura.foto(nombre)
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


# Con "--captura --edificio centro --galeria" (M77): la galería de las cuatro primeras plantas, entera y sin penumbra,
# con sus muebles puestos a mano (Catalogo.SALAS["galeria"].colocados). De cada una dice cuántos muebles tiene (esperado:
# los puestos a mano), qué hay en la pared de arriba (puertas, escaparates) y saca captura-galeria-<planta>.png
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
		$Pantalla.hide()
		Luz.apagada = not Luz.apagada   # sin penumbra
		await get_tree().create_timer(0.6).timeout
		Captura.foto("captura-galeria-%d.png" % (num - 1))
		Luz.apagada = not Luz.apagada
		$Pantalla.show()
		camara.zoom = Vector2.ONE
		Temblor.desplazamiento = Vector2.ZERO
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
		if solo != "" and tipo != solo:
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
			johnny.position = Vector2(sitio.ancho / 2.0, sitio.alto / 2.0)
			await foto_entera(sitio, "captura-fija-%s-%s.png" % [tipo, lado])
	get_tree().quit()


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
# la estantería y del baúl y cuenta cuál se usaría; comprueba que los muebles se abren con el clic y no al arrimarse
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
# baúl, el ratón encima lo enciende (captura-contorno-raton.png) y fuera lo apaga; con Johnny delante, sin ratón (mando,
# teclado o móvil), se enciende (captura-contorno-delante.png), y con el ratón lejos, no. Cada línea dice lo esperado
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
	print("Contorno: ratón encima del baúl, Johnny lejos · se ve %s (esperado: true) · el del banco %s (esperado: false)" % [
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
	print("Contorno: Johnny delante con el ratón lejos · se ve %s (esperado: false)" % baul.zona.contorno.visible)
	johnny.con_raton = false   # como si jugara con el mando
	await get_tree().create_timer(0.2).timeout
	print("Contorno: Johnny delante sin ratón · se ve %s (esperado: true)" % baul.zona.contorno.visible)
	Captura.foto("captura-contorno-delante.png")
	get_tree().quit()


# Con "--captura --clic-mueble": con Johnny delante del baúl (zona_usar.gd), un clic lejos del baúl no lo abre y Johnny
# ataca hacia allí; un clic encima del baúl lo abre y no ataca; y J (sin puntero) también lo abre. La pantalla del
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
	print("Clic mueble: clic encima · se abre %d (esperado: 1) · ataca %s (esperado: false)" % [veces[0], ataca])
	# J, sin puntero: lo abre aunque el ratón esté lejos
	for abajo in [true, false]:
		var k := InputEventKey.new()
		k.physical_keycode = KEY_J
		k.pressed = abajo
		Input.parse_input_event(k)
		await get_tree().physics_frame
		await get_tree().physics_frame
	print("Clic mueble: con J · se abre %d (esperado: 2)" % veces[0])
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


# Con "--captura --dificultad" (M72, el equilibrio): lo que cambia de una planta a otra. Para cada planta (de la baja a
# la 4ª), la vida y el zarpazo de un zombi normal, de un rápido y del guardia (partida.gd, ZOMBI_POR_PLANTA) y la vida
# de la portera (JEFE_POR_PLANTA), con lo que eran antes; y, en doce plantas generadas, cuántos armaritos llevan
# botiquín y cuántos vendas, y en qué baño cae el botiquín (M78: uno por apartamento, en un baño al azar; planta.gd,
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
	var botiquines_antes := 0
	var con_bano := 0
	var mal := 0              # M78: apartamentos con baño que no tienen justo un botiquín
	var en_bano := [0, 0, 0]  # M78: en qué baño (el 1º, el 2º, el 3º) cae el botiquín
	for i in 12:
		Planta.semilla = 2000 + i
		var p: Dictionary = Planta.generar(1 + i % 5, edificio, jefe_de(1 + i % 5))
		for s in p.sitios:
			var lista: Array = s.get("armaritos", [])
			if not lista.is_empty():
				con_bano += 1
				var cuantos: int = lista.filter(func(a): return a.dentro == "botiquin").size()
				if cuantos != 1:
					mal += 1
				else:
					en_bano[mini(lista.map(func(a): return a.dentro).find("botiquin"), 2)] += 1
			for k in lista.size():
				if lista[k].dentro == "botiquin":
					botiquines += 1
				else:
					vendas += 1
				if k % 2 == 0:   # antes: en cada piso, el primero un botiquín y el siguiente unas vendas
					botiquines_antes += 1
	Planta.semilla = 0
	print("Dificultad · armaritos en 12 plantas: %d botiquines y %d vendas (%.1f botiquines por planta; antes %d botiquines, %.1f por planta) · sitios con baño: %d" % [
		botiquines, vendas, botiquines / 12.0, botiquines_antes, botiquines_antes / 12.0, con_bano])
	print("M78 · botiquines por apartamento: %d apartamentos sin justo uno (esperado 0) · en el 1er baño %d, en el 2º %d, en el 3º o más %d (esperado: repartidos)" % [
		mal, en_bano[0], en_bano[1], en_bano[2]])
	get_tree().quit()


# Con "--captura --edificio centro --guardia" (M83): el guardia de la tarjeta, con Johnny quieto a la vista: cuenta los
# silbatos y los refuerzos que llegan en ~14 s, y a qué velocidad huye y corren los refuerzos
func probar_guardia() -> void:
	await montar(0, 0, false)
	if guardia == null:
		print("Guardia: no hay en este pasillo")
		get_tree().quit()
		return
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != guardia:
			z.queue_free()
	var silbatos := [0]
	guardia.silbato.connect(func(): silbatos[0] += 1)
	guardia.vida = guardia.vida_max * 10   # que no caiga a media vida por el camino
	guardia.vida_max = guardia.vida
	johnny.vida = 100000   # que no le maten los refuerzos
	var sitio: Dictionary = planta.sitios[aqui]
	guardia.global_position = Vector2(sitio.ancho / 2.0, sitio.alto / 2.0)
	johnny.position = guardia.global_position + Vector2(-250, 0)
	await get_tree().create_timer(0.3, false).timeout
	for seg in 14:
		var p0: Vector2 = guardia.global_position
		await get_tree().create_timer(1.0, false).timeout
		print("Guardia seg %d: avanza %.0f · silbatos %d · cansado %.1f · alerta %s" % [seg, p0.distance_to(guardia.global_position), silbatos[0], guardia.cansado, guardia.alerta])
		if seg == 0:
			var llegados: int = get_tree().get_nodes_in_group("zombis").filter(func(z): return z != guardia).size()
			print("Guardia: tras el primer silbato llegan %d refuerzos (esperado 4, +%d por la planta)" % [llegados, planta.num / 2])
	var refuerzos: Array = get_tree().get_nodes_in_group("zombis").filter(func(z): return z != guardia and z.get_meta("tipo", "") == "vigilante")
	var vel: float = refuerzos[0].velocidad if not refuerzos.is_empty() else 0.0
	print("Guardia en ~14 s: silbatos %d (esperado 3: al verte y cada 6 s) · refuerzos vivos %d (Johnny va matando) · velocidad de un refuerzo %.0f (esperado 165)" % [
		silbatos[0], refuerzos.size(), vel])
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
