# Las pruebas que sacan fotos para mirarlas: --fotos-tiendas (y los peligros), --fotos-luz, --fotos-ayudas y
# --fotos-supervivientes. Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_inventario.gd"

var grito_visto := false     # fotos_tiendas: la foto del grito de la dependienta, solo una vez
var peligros_vistos := {}    # fotos_tiendas: los peligros que ya tienen sus fotos (fotos_peligros)


# Con "--captura --fotos-ayudas": prueba las ayudas de Opciones. Abre la pestaña Ayudas y las pone en Sí
# (captura-ayudas-opciones.png); luego le quita casi toda la vida a Johnny, lo cura y dispara la pistola, y
# cuenta en la terminal la vida, los tercios y las balas, sin ayudas y con ellas (captura-ayudas-hud.png).
# Para lanzar apuntando solo, con el ratón lejos, mete un zombi y cuenta adónde iría el lanzable: con la
# ayuda, al zombi (captura-ayudas-lanzar.png, con un molotov en el aire).
# Al acabar las deja en No y se cierra
func fotos_ayudas() -> void:
	set_process(false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var probar := func(nombre: String) -> void:
		johnny.tercios = 3
		johnny.vida = johnny.stats.vida_max
		johnny.quitar_vida(roundi(johnny.stats.vida_max * 0.8))
		johnny.curar(1000)
		johnny.coger("pistola")
		var antes: int = johnny.balas
		for i in 5:
			johnny.disparar(0.0)
		print("Ayudas %s: vida %d/%d tras curar · tercios %d · balas %d -> %d · recargando %s" % [nombre,
			johnny.vida, johnny.stats.vida_max, johnny.tercios_vivos(), antes, johnny.balas, johnny.recargando > 0.0])
	var zombi := meter_zombi("normal", johnny.global_position + Vector2(-150, 60))
	zombi.set_physics_process(false)   # quieto, para la prueba
	var probar_lanzar := func(nombre: String) -> void:
		johnny.con_raton = true
		var donde: Vector2 = lanzables.objetivo()
		print("Ayudas %s: el lanzable caería a %d del zombi" % [nombre, roundi(donde.distance_to(zombi.global_position))])
	probar.call("no")
	probar_lanzar.call("no")
	var o := Opciones.abrir(self, null, johnny)
	o.ver("ayudas")
	await get_tree().process_frame
	for b in o.contenido.get_children():
		if b is Button:
			b.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ayudas-opciones.png")
	o.cerrar()
	probar.call("sí")
	probar_lanzar.call("sí")
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-ayudas-hud.png")
	lanzables.lanzar(lanzables.objetivo())   # un molotov de verdad, en pleno vuelo hacia el zombi
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ayudas-lanzar.png")
	Guardado.cambiar(func(g):
		g.ajustes.vida_entera = false
		g.ajustes.pistola_sin_fin = false
		g.ajustes.lanzar_solo = false)
	get_tree().quit()


# Con "--captura --fotos-supervivientes": los tres supervivientes del edificio con su hoja de PixelLab (aliado.gd,
# HOJAS; con "--edificio centro", los del centro comercial). En las viviendas, de vecinos, cada uno en su habitación
# (captura-supervivientes-sala.png); luego se unen al equipo y, en un piso sin zombis, andan tras él
# (captura-supervivientes-andar.png), hacen lo suyo (captura-supervivientes-accion.png: el fogonazo de la pistola y
# del fusil y la jeringa, o el martillazo y la descarga; la farmacéutica no tiene gesto) y el último cae, con su vida
# encima como en la horda (captura-supervivientes-caido.png). Luego se cierra
func fotos_supervivientes() -> void:
	set_process(false)
	var ids := ["ferretero", "farmaceutica", "tecnico"] if edificio == "centro" else ["policia", "medico", "militar"]
	# en las viviendas, con sus puertas abiertas (sin los vecinos de siempre: se ponen los de la prueba)
	var rescatados_antes: Array = Guardado.cargar().rescatados.duplicate()
	Guardado.cambiar(func(g): g.rescatados = ids)
	await montar(planta.viviendas, 0, false)
	Guardado.cambiar(func(g): g.rescatados = rescatados_antes)
	for v in supervivientes.vecinos:
		v.queue_free()
	supervivientes.vecinos = []
	for id in ids:
		if supervivientes.equipo.any(func(a): return a.def.id == id):
			continue   # ya acompaña a Johnny (el guardado de la prueba trae al policía de acompañante)
		# (sin su rescate: al unirse, la farmacéutica y el técnico no empiezan la escolta ni la avería)
		var datos: Dictionary = Supervivientes.DATOS[id].duplicate()
		datos.erase("rescate")
		var v := supervivientes.crear(datos, "vecino")
		v.es_vecino = true
		v.casa = Viviendas.casa(id)
		v.position = v.casa
		mapa.cosas.add_child(v)
		supervivientes.vecinos.append(v)
	# en el pasillo, delante de la habitación del medio de su fila
	var medio := Viviendas.casa(ids[1])
	johnny.position = Vector2(medio.x, (Viviendas.PASILLO_F + (1 if medio.y < Viviendas.PASILLO_F * 32 else 4)) * 32)
	johnny.direccion = "n" if medio.y < Viviendas.PASILLO_F * 32 else "s"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.8).timeout
	Captura.foto("captura-supervivientes-sala.png")
	print("Foto supervivientes: en la sala, de vecinos")
	for v in supervivientes.vecinos.duplicate():
		supervivientes.unir(v)
	# a un apartamento (el de más habitaciones) sin zombis y con todo descubierto, como en fotos_luz
	var i := 1
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and planta.sitios[j].tipo != "viviendas" and (not planta.sitios[i].has("apt")
				or planta.sitios[j].apt.salas.size() > planta.sitios[i].apt.salas.size()):
			i = j
	montar(i, 0, false)
	for sala in planta.sitios[i].apt.salas:
		mapa.vistas[sala.id] = true
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().create_timer(0.5).timeout
	# andando tras Johnny: él se aparta y ellos van a su alrededor
	johnny.position += Vector2(150, 0)
	johnny.direccion = "e"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-supervivientes-andar.png")
	print("Foto supervivientes: andando")
	await get_tree().create_timer(1.2).timeout
	# lo suyo: el policía y el militar sacan el arma, la médica la jeringa, el ferretero alza el martillo y el técnico
	# saca el aparato (la foto, en el fotograma del fogonazo; el rayo de la descarga, a mano, que no hay zombis)
	var hacia := {"policia": Vector2.RIGHT, "medico": Vector2.DOWN, "militar": Vector2.LEFT,
		"ferretero": Vector2.RIGHT, "farmaceutica": Vector2.DOWN, "tecnico": Vector2.LEFT}
	for k in supervivientes.equipo.size():
		var a: Aliado = supervivientes.equipo[k]
		# en fila, que no se tapen, y quietos ahí mirando a su lado (como en la horda, delante de la cerradura)
		a.position = johnny.position + Vector2(-210 + k * 140, 90)
		a.velocity = Vector2.ZERO
		a.forzando = true
		a.sitio_forzar = a.position
		a.mira_forzar = hacia[a.def.id]
		a.animar("reposo", hacia[a.def.id])
		if a.sprite.sprite_frames.has_animation("ataque_s"):
			a.empezar_accion()
	await get_tree().create_timer(0.17).timeout
	for a in supervivientes.equipo:
		if a.def.id == "tecnico":
			a.rayo_t = 0.6
			a.rayo_a = a.global_position + Vector2(-180, -24)
	await get_tree().create_timer(0.05).timeout   # (que se llegue a dibujar el rayo)
	Captura.foto("captura-supervivientes-accion.png")
	print("Foto supervivientes: lo suyo de cada uno")
	await get_tree().create_timer(0.8).timeout
	for a in supervivientes.equipo:
		a.forzando = false
	# el último del edificio cae (como en la horda: forzando la cerradura, con su vida encima)
	var p: Aliado = supervivientes.equipo.filter(func(a): return a.def.id in ids).back()
	p.forzando = true
	p.sitio_forzar = p.position
	p.vida = 0
	p.caido = true
	await get_tree().create_timer(0.9).timeout
	Captura.foto("captura-supervivientes-caido.png")
	print("Foto supervivientes: cae %s" % p.def.nombre)
	get_tree().quit()


# Con "--captura --fotos-luz": para ver si la luz se cuela por las paredes. Entra en el apartamento con más
# habitaciones, todas descubiertas (las lámparas encendidas) y sin zombis, y saca una foto con Johnny en
# cada habitación, justo debajo de un tabique con otra habitación detrás y mirándolo (captura-luz-<n>.png):
# la linterna tiene que quedarse en la pared y no alumbrar el suelo de detrás. Luego se cierra
func fotos_luz() -> void:
	set_process(false)
	$Pantalla/HUD.hide()
	var i := 1   # el apartamento con más habitaciones
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and planta.sitios[j].tipo != "viviendas" and (not planta.sitios[i].has("apt")
				or planta.sitios[j].apt.salas.size() > planta.sitios[i].apt.salas.size()):
			i = j
	montar(i, 0, false)
	var s: Dictionary = planta.sitios[i]
	for sala in s.apt.salas:
		mapa.vistas[sala.id] = true
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	for sala in s.apt.salas:
		# justo debajo de un tabique que tenga otra habitación detrás (el del medio, si hay varios)
		var sitios := []
		for f in range(3, mapa.filas):
			for c in mapa.cols:
				var aqui_d: int = mapa.dueno[f * mapa.cols + c]
				var detras: int = mapa.dueno[(f - 2) * mapa.cols + c]
				if aqui_d == sala.id and mapa.dueno[(f - 1) * mapa.cols + c] == -1 and detras >= 0 and detras != sala.id:
					sitios.append(Vector2(c + 0.5, f + 0.7) * 32.0)
		if sitios.is_empty():
			continue
		johnny.position = sitios[sitios.size() / 2]
		johnny.direccion = "n"
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		Captura.foto("captura-luz-%d.png" % sala.id)
		print("Foto luz: ", s.nombre, " · ", sala.nombre)
	get_tree().quit()


# Con "-- --captura --edificio centro --fotos-tiendas": sin penumbra y con todo descubierto, una foto de la sala de
# venta de cada tienda de las dos primeras plantas (captura-tienda-<tipo>.png) y otra de la galería, y se cierra.
# Además, la primera vez que sale cada peligro, sus fotos (fotos_peligros)
func fotos_tiendas() -> void:
	set_process(false)
	luz.alternar()
	Planta.joyeria_planta = 2   # la joyería, en la 1ª planta: así sale en las fotos
	for num in [1, 2]:
		if num > 1:
			nueva_planta(num)
		for i in range(1, planta.sitios.size()):
			var s: Dictionary = planta.sitios[i]
			if s.get("tienda", "") == "":
				continue
			montar(i, 0, false)
			for sala in s.apt.salas:
				mapa.vistas[sala.id] = true
			for z in get_tree().get_nodes_in_group("zombis"):
				z.queue_free()
			var venta: Dictionary = s.apt.salas[0]
			johnny.position = Vector2(venta.c0 + venta.ancho / 2.0, venta.f0 + venta.fondo / 2.0) * 32.0
			johnny.get_node("Camara").reset_smoothing()
			await get_tree().create_timer(0.8).timeout
			var nombre: String = "jefe" if s.tipo == "jefe" else s.tienda
			Captura.foto("captura-tienda-%s.png" % nombre)
			var cuenta := {}
			for z in s.zombis:
				cuenta[z.tipo] = cuenta.get(z.tipo, 0) + 1
			print("Foto: ", s.nombre, " (", nombre, ") | zombis: ", cuenta)
			if not grito_visto and s.tipo != "jefe":
				grito_visto = true
				await foto_grito()
			await fotos_peligros(s)
		montar(0, 0, false)
		johnny.position = Vector2(planta.sitios[0].ancho / 2.0, planta.sitios[0].alto / 2.0)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		Captura.foto("captura-galeria-%d.png" % num)
	# los peligros que no hayan salido en esas dos plantas (las tiendas cambian en cada partida), en las siguientes
	for num in range(3, 9):
		if peligros_vistos.size() >= 3:
			break
		nueva_planta(num)
		for i in range(1, planta.sitios.size()):
			var s: Dictionary = planta.sitios[i]
			if not s.get("peligros", []).any(func(d): return not peligros_vistos.has(d.tipo)):
				continue
			montar(i, 0, false)
			for sala in s.apt.salas:
				mapa.vistas[sala.id] = true
			for z in get_tree().get_nodes_in_group("zombis"):
				z.queue_free()
			await fotos_peligros(s)
	get_tree().quit()


# La dependienta (zombi_dependienta.gd): dormida delante de Johnny, se despierta, grita «¡OFERTAS!», despierta a los
# vigilantes dormidos de al lado y les mete prisa (captura-grito.png); luego, los nuevos de cerca (captura-nuevos.png)
func foto_grito() -> void:
	var dep := meter_zombi("dependienta", johnny.position + Vector2(120, 0))
	dep.dormido = true
	var otros := []
	for i in 3:
		var v := meter_zombi("vigilante", johnny.position + Vector2(-140 + i * 90, 110))
		v.dormido = true
		otros.append(v)
	# se despierta sola al ver a Johnny (en la misma sala) y grita enseguida
	await get_tree().create_timer(0.25).timeout
	Captura.foto("captura-grito.png")
	print("Grito: estado %s | despiertos %d/3 | prisa %s | velocidad máxima %s" % [dep.estado,
		otros.filter(func(o): return not o.dormido).size(), otros.map(func(o): return snappedf(o.prisa, 0.1)),
		otros.map(func(o): return o.agente.max_speed)])
	await get_tree().create_timer(2.0).timeout
	print("Dependienta a %d de Johnny (se aparta) | estado %s" % [dep.global_position.distance_to(johnny.global_position), dep.estado])
	Captura.foto("captura-nuevos.png")
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().process_frame


# Las fotos de los peligros (peligros.gd), con la penumbra puesta y unos zombis despiertos dentro:
#   captura-peligro-frio.png     Johnny dentro de la cámara (escarcha en la pantalla) y los zombis, congelándose
#   captura-peligro-fuego.png    desde la puerta de la cocina, con zombis ardiendo
#   captura-peligro-agua.png     en pleno calambrazo, con zombis en el agua
#   captura-peligro-sin-luz.png  después de bajar la palanca (la tienda a oscuras)
#   captura-peligro-cuadro.png   delante del cuadro eléctrico (que la vuelve a subir)
func fotos_peligros(s: Dictionary) -> void:
	for nodo in mapa.peligros:
		var d: Dictionary = nodo.datos
		if peligros_vistos.has(d.tipo):
			continue
		peligros_vistos[d.tipo] = true
		luz.alternar()
		luz.poner_sitio(s.tipo)
		var sala: Dictionary = s.apt.salas[d.sala]
		var donde: Vector2 = sala.centro
		var zombis := []
		match d.tipo:
			"frio":
				var dentro := Rect2(sala.c0 * 32.0, sala.f0 * 32.0, sala.ancho * 32.0, sala.fondo * 32.0).grow(-24.0)
				for k in [Vector2(-70, -30), Vector2(70, -20), Vector2(0, 50)]:
					zombis.append((sala.centro + k).clamp(dentro.position, dentro.end))
			"fuego":
				var puerta: Dictionary = s.apt.puertas.filter(func(p): return (p.a == d.sala or p.b == d.sala) and (p.a == 0 or p.b == 0))[0]
				donde = Peligros.centro(Peligros.al_lado_de(s.apt, puerta, d.sala)) + Vector2(16, 0)
				for c in d.arde.keys().filter(func(c): return not c in d.focos).slice(0, 3):
					zombis.append(Peligros.centro(c))
			"agua":
				for c in d.casillas:
					for v in Peligros.LADOS:
						if not c + v in d.casillas and Peligros.dueno(s.apt, c.x + v.x, c.y + v.y) == 0 and not Peligros.bajo_mueble(s, c + v):
							donde = Peligros.centro(c + v)
				var lista: Array = d.casillas.duplicate()
				lista.shuffle()
				for c in lista.slice(0, 3):
					zombis.append(Peligros.centro(c))
		johnny.position = donde
		johnny.get_node("Camara").reset_smoothing()
		for p in zombis:
			var zombi := meter_zombi("normal", p)
			zombi.vida = 300   # para que aguanten hasta la foto
		await get_tree().create_timer(4.6 if d.tipo == "frio" else 1.5).timeout
		if d.tipo == "agua":
			# la foto, en pleno calambrazo
			for i in 60:
				if nodo.destello > 0.12:
					break
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
		Captura.foto("captura-peligro-%s.png" % d.tipo)
		var vivos: Array = get_tree().get_nodes_in_group("zombis").filter(func(z): return z.estado != "muerto")
		print("Peligro %s en %s: Johnny %d de vida | zombis vivos %d (vida %s) | congelados %d | ardiendo %d" % [d.tipo, s.nombre,
			johnny.vida, vivos.size(), vivos.map(func(z): return z.vida), vivos.filter(func(z): return z.congelado > 0.0).size(),
			vivos.filter(func(z): return z.arder_t > 0.0).size()])
		if d.tipo == "fuego":
			print("  arden %d casillas de %d (tope %d), quemadas %d" % [d.arde.size(), d.casillas.size(), d.tope, d.quemadas.size()])
		if d.tipo == "agua":
			nodo.cambiar_corriente()
			await get_tree().create_timer(1.2).timeout
			Captura.foto("captura-peligro-sin-luz.png")
			print("  sin corriente: oscuridad %.2f | corriente %s" % [Luz.nivel, d.corriente])
			johnny.position = Vector2(d.cuadro.x, d.cuadro.y + 40.0)
			johnny.get_node("Camara").reset_smoothing()
			await get_tree().create_timer(1.2).timeout
			Captura.foto("captura-peligro-cuadro.png")
			print("  delante del cuadro: corriente %s | oscuridad %.2f" % [d.corriente, Luz.nivel])
		for z in get_tree().get_nodes_in_group("zombis"):
			z.queue_free()
		johnny.vida = johnny.stats.vida_max
		johnny.tercios = 3
		johnny.estados.clear()
		luz.alternar()
		luz.poner_sitio(s.tipo)
