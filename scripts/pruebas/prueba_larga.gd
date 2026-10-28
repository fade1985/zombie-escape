# La prueba larga (--captura a secas, en _process) y lo que mira por el camino: el ordenador, la historia, las
# Colecciones, los objetos, los menús... También --banco. Parte de la cadena de la partida de
# prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_varias.gd"

var tiempo := 0.0            # los segundos que lleva la prueba larga (_process)


func contar_planta() -> void:
	print("Planta: ", planta.nombre)
	for i in range(1, planta.sitios.size()):
		var s: Dictionary = planta.sitios[i]
		if not s.has("apt"):
			print("  %s [%s]: %d muebles" % [s.nombre, s.tipo, s.muebles.size()])
			continue
		var salas := []
		for sala in s.apt.salas:
			salas.append("%s(%d)" % [sala.nombre, sala.casillas])
		var tipos := {}
		for z in s.zombis:
			tipos[z.tipo] = tipos.get(z.tipo, 0) + 1
		print("  %s [%s] %dx%d casillas: %s | %d muebles | zombis: %s" % [s.nombre, s.tipo, s.apt.cols, s.apt.filas,
			" ".join(salas), s.muebles.size(), tipos])
	print("  pasillo: %d muebles | llave en %s" % [planta.sitios[0].muebles.size(),
		planta.sitios[planta.llave.sitio].nombre if planta.llave.sitio >= 0
		else "el guardia del pasillo" if ed.cerrojo == "tarjeta" else "un zombi al azar"])


func _process(delta: float) -> void:
	tiempo += delta
	var antes := tiempo - delta
	# primero, fotos de la sala de mantenimiento (donde empieza) y de la exposición
	if antes < 0.3 and tiempo >= 0.3:
		Captura.foto("captura-mantenimiento.png")
		montar(planta.expo, 0, false)
		johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, 420)
		johnny.get_node("Camara").reset_smoothing()
	if antes < 0.7 and tiempo >= 0.7:
		Captura.foto("captura-expo.png")
		# y las últimas filas de zombis (los del centro comercial, la portera y los minijefes): captura-expo-zombis.png
		var filas := []
		for s in mapa.expo_sprites:
			if s.position.y not in filas:
				filas.append(s.position.y)
		filas.sort()
		johnny.position = Vector2(560, filas[-1] - 140.0)
		johnny.get_node("Camara").reset_smoothing()
	if antes < 0.9 and tiempo >= 0.9:
		Captura.foto("captura-expo-zombis.png")
	# al segundo, a un apartamento normal (el que tiene más zombis)
	if antes < 1.0 and tiempo >= 1.0:
		var mejor := 1
		for i in range(1, planta.sitios.size()):
			if planta.sitios[i].zombis.size() > planta.sitios[mejor].zombis.size():
				mejor = i
		print("Entra en ", planta.sitios[mejor].nombre)
		montar(mejor, 0, false)
	# el botiquín del baño: herido, delante del armarito
	if antes < 1.1 and tiempo >= 1.1 and not mapa.armaritos.is_empty():
		var a: Node2D = mapa.armaritos[0]
		johnny.vida = 40
		johnny.position = a.position + Vector2(0, 40)
		johnny.get_node("Camara").reset_smoothing()
		$Pantalla/HUD.hide()   # para que se vea la pared de arriba en la foto
	if antes < 1.4 and tiempo >= 1.4:
		var a: Node2D = mapa.armaritos[0] if not mapa.armaritos.is_empty() else null
		print("Armaritos en el piso: %d | vida tras el botiquín: %d | cogido: %s" % [mapa.armaritos.size(), johnny.vida,
			a.datos.cogido if a else "-"])
		Captura.foto("captura-botiquin.png")
		$Pantalla/HUD.show()
	# poca vida: la pantalla roja y la barra con lo perdido en claro (luego se le devuelve la vida)
	if antes < 1.45 and tiempo >= 1.45:
		johnny.quitar_vida(johnny.vida - 18)
	if antes < 1.6 and tiempo >= 1.6:
		Captura.foto("captura-poca-vida.png")
		johnny.vida = johnny.stats.vida_max
		johnny.tercios = 3
	# una granada a un lado (explota antes de la foto)
	if antes < 2.0 and tiempo >= 2.0:
		lanzables.cambiar()
		lanzables.lanzar(johnny.global_position + Vector2(-180, 90))
		lanzables.cambiar()
	# un tiro de pistola para despertar a los de cerca
	if antes < 2.5 and tiempo >= 2.5:
		johnny.coger("pistola")
	if antes < 2.6 and tiempo >= 2.6:
		Input.action_press("atacar")
	# las trazadoras (normal, perdigón y crítica), quietas al lado de Johnny para la foto
	if antes < 2.65 and tiempo >= 2.65:
		for i in 3:
			var bala := preload("res://escenas/armas/bala.tscn").instantiate()
			bala.velocidad = Vector2.from_angle(-0.4 + i * 0.4) * 600.0
			bala.radio = 3.0 if i == 1 else 4.0
			bala.critico = i == 2
			bala.altura = 22.0
			bala.set_physics_process(false)
			bala.name = "BalaFoto%d" % i
			johnny.get_parent().add_child(bala)
			bala.global_position = johnny.global_position + Vector2(-70 + i * 50, 30)
	if antes < 2.7 and tiempo >= 2.7:
		Captura.foto("captura-balas.png")
		for n in johnny.get_parent().get_children():
			if n.name.begins_with("BalaFoto"):
				n.queue_free()
	if antes < 3.2 and tiempo >= 3.2:
		Input.action_release("atacar")
		# un molotov al zombi más cercano (o por delante)
		var prueba := meter_zombi("lento", mapa.punto_libre(johnny.position, 120.0))
		var donde: Vector2 = prueba.global_position
		lanzables.lanzar(donde)
		print("Molotov hacia ", donde, " | quedan ", lanzables.cantidades)
		# un zombi que cae al lado de Johnny: revienta y deja su mancha
		var muerto := meter_zombi("normal", johnny.position + Vector2(-60, 40))
		muerto.recibir_golpe(999, Vector2.ZERO)
		# y dos que mueren ardiendo: uno se queda en brasas y al otro se le adelanta el reloj hasta los huesos
		for i in 2:
			var quemado := meter_zombi("normal", johnny.position + Vector2(-90 + i * 130, 10))
			quemado.name = "QuemadoFoto%d" % i
			quemado.prender()
			quemado.recibir_golpe(999, Vector2.ZERO)
	if antes < 4.3 and tiempo >= 4.3:
		for i in 2:
			var cuerpo: Node = mapa.cosas.get_node_or_null("QuemadoFoto%d" % i)
			if cuerpo:
				var q: Quemado = cuerpo.get_children().filter(func(n): return n is Quemado)[0]
				q.t = q.caida + 3.0 if i == 0 else 99.0   # uno en brasas y humo; el otro, ya en huesos
	if antes < 4.4 and tiempo >= 4.4:
		Captura.foto("captura-quemado.png")
	if antes < 3.35 and tiempo >= 3.35:
		Captura.foto("captura-sangre.png")
		# las balas: sin ninguna, a la de cuerpo a cuerpo; una caja de munición devuelve la de fuego y recarga
		var antes_balas := "%s %d +%d" % [johnny.huecos.fuego, johnny.balas, johnny.reserva()]
		johnny.balas = 0
		johnny.municion.clear()
		johnny.sostener("fuego")
		johnny.lista_para_disparar()
		var sin: String = johnny.mano
		johnny.sumar_municion()
		print("Balas: %s | sin balas pasa a %s | con una caja: %s %d +%d recargando %s" % [antes_balas, sin,
			johnny.mano, johnny.balas, johnny.reserva(), johnny.recargando > 0.0])
	if antes < 4.2 and tiempo >= 4.2:
		var ardiendo := 0
		for z in get_tree().get_nodes_in_group("zombis"):
			if z.get("arder_t") != null and z.arder_t > 0.0:
				ardiendo += 1
		print("Charcos: %d | zombis ardiendo: %d | manchas: %d" % [get_tree().get_nodes_in_group("charcos").size(), ardiendo,
			get_tree().get_nodes_in_group("manchas").size()])
	if int(tiempo * 2.0) != int(antes * 2.0) and tiempo > 1.2:
		var dormidos := 0
		var despiertos := 0
		for z in get_tree().get_nodes_in_group("zombis"):
			if z.get("dormido"):
				dormidos += 1
			else:
				despiertos += 1
		print("t=%.1f vida=%d puerta %s | dormidos %d, despiertos %d | %s" % [tiempo, johnny.vida,
			"cerrada" if cerrada else "abierta", dormidos, despiertos, lugar.text.replace("\n", " / ")])
	if antes < 4.5 and tiempo >= 4.5:
		Captura.foto("captura.png")
		print("Foto guardada. Prueba de las escaleras:")
		planta.jefa_muerta = true
		cerrada = false
		montar(0, puerta_de_tipo("escaleras"), false)
	if antes < 4.7 and tiempo >= 4.7:
		cruzar(puerta_de_tipo("escaleras"))
	# en el centro comercial, el guardia: Johnny se le acerca (silbato y refuerzos), foto, y cae con su tarjeta
	if antes < 5.35 and tiempo >= 5.35 and guardia:
		johnny.position = mapa.punto_libre(guardia.position, 0.0)
		for i in 60:
			var p: Vector2 = guardia.position + Vector2.from_angle(randf() * TAU) * 220.0
			if mapa.zona_en(p) >= 0:
				johnny.position = p
				break
		johnny.get_node("Camara").reset_smoothing()
	if antes < 5.5 and tiempo >= 5.5 and guardia:
		print("Guardia: vida %d/%d | alerta %s | silbidos %d | zombis en el pasillo %d" % [guardia.vida, guardia.vida_max,
			guardia.alerta, guardia.silbidos, get_tree().get_nodes_in_group("zombis").size()])
		Captura.foto("captura-guardia.png")
		guardia.recibir_golpe(99999, Vector2.ZERO)
	if antes < 5.6 and tiempo >= 5.6:
		if planta.has("guardia"):
			print("Tarjeta: en el sitio %d, en %s | guardia vivo: %s" % [planta.llave.sitio, planta.llave.pos, planta.guardia.vivo])
		print("Ahora en: ", planta.nombre, " (", planta.sitios.size() - 1, " puertas)")
		Captura.foto("captura-pasillo.png")
		# Johnny pisa la puerta A del pasillo, como si fuera andando
		johnny.position = mapa.puertas[0].position + Vector2(0, 20)
	if antes < 6.6 and tiempo >= 6.6:
		print("Tras pisar la puerta A: en %s (aviso: '%s')" % [planta.sitios[aqui].nombre, aviso.text])
		# Prueba de la jefa: con la llave, a su apartamento
		planta.tiene_llave = true
		for i in planta.sitios.size():
			if planta.sitios[i].tipo == "jefe":
				montar(i, 0, false)
	if antes < 7.3 and tiempo >= 7.3 and jefa and planta.jefe == "gloton":   # (aparece a los 7,2)
		probar_gloton()   # la sangre ácida y el aspirado (lo escribe en la terminal)
	if antes < 7.3 and tiempo >= 7.3 and jefa and planta.jefe == "gymbro":
		probar_gymbro()   # los suplementos (la armadura) y las pesas (lo escribe en la terminal)
	if antes < 7.3 and tiempo >= 7.3 and jefa and planta.jefe == "bombero":
		probar_bombero()   # inmune al fuego, las bolas y los molotovs (lo escribe en la terminal)
	if antes < 7.7 and tiempo >= 7.7 and jefa:
		if jefa.has_method("cambiarse"):
			probar_modista(jefa)   # antes de poner a Johnny delante: se cambia de sitio
		# Johnny, delante del jefe (para que salga en la foto)
		for i in 60:
			var p: Vector2 = jefa.position + Vector2.from_angle(jefa.mirada.angle() + randf_range(-0.7, 0.7)) * 230.0
			if mapa.zona_en(p) >= 0:
				johnny.position = p
				break
		johnny.get_node("Camara").reset_smoothing()
		if jefa is Minijefe:
			jefa.mirada = (johnny.position - jefa.position).normalized()
		if jefa.has_method("lluvia"):
			probar_cocinero()
		if planta.jefe == "antidisturbios":
			# el antidisturbios. El escudo: un golpe de 10 por delante, de lado, por la espalda y de una explosión
			# (la fuerza va hacia donde empuja el golpe: el de delante empuja hacia atrás)
			var m: Vector2 = jefa.mirada
			var quita := []
			for golpe in [[-m, false], [m.orthogonal(), false], [m, false], [m, true]]:
				var antes_vida: int = jefa.vida
				jefa.recibir_golpe(10, golpe[0] * 300.0, golpe[1])
				quita.append(antes_vida - jefa.vida)
			print("Escudo (golpes de 10): de frente -%d, de lado -%d, por la espalda -%d, explosión -%d" % quita)
		if jefa.has_method("foto"):   # que salga en la foto haciendo lo suyo (el antidisturbios, preparando la carga; la mascota, saltando)
			jefa.foto(johnny)
		if jefa.has_method("cambiarse"):   # la modista: que salga en la foto tirando alfileres
			jefa.apuntar_alfileres(johnny.position - jefa.position)
			jefa.datos.aviso = 0.15
	if antes < 8.0 and tiempo >= 8.0 and jefa:
		Captura.foto("captura-jefe.png")
	if antes < 8.05 and tiempo >= 8.05:
		print("El jefe (%s) ha salido en '%s': %s | vida %d | puerta %s" % [planta.jefe, planta.sitios[aqui].nombre,
			jefa != null, jefa.vida_max if jefa else 0, "cerrada" if cerrada else "abierta"])
		if jefa:
			jefa.invulnerable = false   # (la mascota de la foto está en el aire, donde no se le puede dar)
			jefa.recibir_golpe(99999, Vector2.ZERO)
	if antes < 9.5 and tiempo >= 9.5:
		print("Jefa muerta: ", planta.jefa_muerta, " | ", aviso.text)
		probar_menus()


# El ordenador: con $60 en el guardado de prueba compra puntos, sube Ataque, compra la escopeta y hace fotos
func probar_ordenador() -> void:
	Guardado.cambiar(func(g):
		g.dolares = 60
		g.puntos = 0
		g.talentos = {}
		g.armas = [])
	ahorrados = 60
	aplicar_talentos({})
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("puntos")
	ordenador.comprar(3)
	ordenador.subir("ataque")
	ordenador.subir("punteria")
	ordenador.subir("tirador")   # bloqueado: no tiene Ataque al máximo
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ordenador.png")
	ordenador.abrir("armas")
	ordenador.comprar_arma("escopeta")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-tienda.png")
	# los logros: uno cobrado, uno por cobrar y algo de progreso en los demás
	Guardado.cambiar(func(g): g.logros = {"primer_turno": "cobrado", "desahucio": "conseguido"})
	logros.fregonazos = 4
	ordenador.abrir("logros", "b_desahucio")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-logros.png")
	ordenador.cobrar_logro("desahucio")
	print("Logros: %s | $%d ahorrados tras cobrar" % [Guardado.cargar().logros, Guardado.cargar().dolares])
	var g := Guardado.cargar()
	print("Ordenador: $%d ahorrados, %d puntos, talentos %s, armas %s | daño x%.2f | lleva %s" % [g.dolares, g.puntos,
		g.talentos, g.armas, johnny.stats.dano, johnny.huecos])
	ordenador.abrir("")
	ordenador.apagar()


# La historia: el científico muerto de la planta (con su página sin encontrar), la página al cogerla y el Dosier
# del ordenador con dos páginas
# La sangre, en la sala de mantenimiento (con luz, para que se vea): el destello de un golpe, un zombi muerto a
# golpes que deja su charco, el lento arrastrándose con su rastro y los casquillos de unos disparos
func probar_sangre() -> void:
	# si sigue abierta la mutación de la portera, se elige una que no deja charcos (para que no salgan en la foto)
	if menus.abierto == "mutacion":
		menus.elegir("insensible")
	await montar(planta.mantenimiento, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var centro := Vector2(planta.sitios[aqui].ancho / 2.0, 330)
	johnny.position = centro
	johnny.get_node("Camara").reset_smoothing()
	johnny.invulnerable = 99.0
	johnny.coger("pistola")   # con la pistola (si lleva el desintegrador, el ácido tapa la sangre)
	# los acompañantes, quietos (si no, matan al lento antes de que se arrastre)
	for a in get_tree().get_nodes_in_group("presa"):
		if a != johnny:
			a.process_mode = Node.PROCESS_MODE_DISABLED
	var golpeado := meter_zombi("normal", centro + Vector2(110, -10))
	var lento := meter_zombi("lento", centro + Vector2(-300, 60))
	lento.despertar()
	var muerto := meter_zombi("normal", centro + Vector2(-60, 150))
	await get_tree().create_timer(0.3).timeout
	muerto.recibir_golpe(999, Vector2(-120, 60))
	golpeado.recibir_golpe(1, Vector2(150, 0))
	await get_tree().process_frame
	await get_tree().process_frame
	Captura.foto("captura-destello.png")
	await get_tree().create_timer(0.3).timeout
	golpeado.recibir_golpe(999, Vector2(170, 0))
	johnny.coger("pistola")
	johnny.balas = 8
	for i in 5:
		johnny.disparar(-0.3 + i * 0.15)
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(2.5).timeout
	var rastro: Node = lento.get_parent().get_node_or_null("Rastro")
	print("Sangre: rastro %d | gotas %d | casquillos %d | charco %s" % [rastro.celdas.size() if rastro else 0,
		lento.get_parent().get_node("Gotas").celdas.size() if lento.get_parent().has_node("Gotas") else 0,
		lento.get_parent().get_node("Casquillos").celdas.size() if lento.get_parent().has_node("Casquillos") else 0,
		golpeado.a_golpes])
	Captura.foto("captura-sangre2.png")
	johnny.invulnerable = 0.0
	for a in get_tree().get_nodes_in_group("presa"):
		a.process_mode = Node.PROCESS_MODE_INHERIT


func probar_historia() -> void:
	Guardado.cambiar(func(g): g.paginas = [])
	var c: Dictionary = planta.cientifico
	await montar(c.sitio, 0, false)
	johnny.position = c.pos + Vector2(-70, 0)
	johnny.get_node("Camara").reset_smoothing()
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().create_timer(1.2).timeout
	Captura.foto("captura-cientifico.png")
	print("Científico en pantalla: ", get_viewport().get_canvas_transform() * c.pos)
	johnny.position = c.pos + Vector2(28, 30)
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-pagina.png")
	print("Página cogida: %s | en el guardado: %s" % [c.get("pagina", {}).get("id", "-"), Guardado.cargar().paginas])
	menus.leida()
	# los muertos que no llevan bata (en el centro comercial: el jefe de seguridad y la secretaria), en fila sobre
	# un fondo liso, por encima de todo (sin penumbra ni paredes): captura-cuerpos.png
	var con_ropa: Array = Historia.dosier(edificio).paginas.filter(func(p): return p.look.has("ropa"))
	if not con_ropa.is_empty():
		var capa := CanvasLayer.new()
		capa.layer = 50
		add_child(capa)
		var fondo := ColorRect.new()
		fondo.color = Color("#5a5d66")
		fondo.position = Vector2(240, 230)
		fondo.size = Vector2(480, 180)
		capa.add_child(fondo)
		for i in con_ropa.size():
			var cuerpo := CIENTIFICO.new()
			cuerpo.montar(con_ropa[i], Vector2(370 + i * 220, 320))
			cuerpo.z_index = 0
			capa.add_child(cuerpo)
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-cuerpos.png")
		capa.queue_free()
	# en el ordenador, la primera y la tercera página del dosier de este edificio (en los Apartamentos, el correo)
	# y la primera de cada uno de los otros edificios: el Dosier las enseña todas, sea cual sea el edificio
	var ids: Array = Historia.dosier(edificio).paginas.map(func(p): return p.id)
	var de_otros: Array = Historia.DOSIERES.keys().filter(func(e): return e != edificio).map(
		func(e): return Historia.DOSIERES[e].paginas[0].id)
	Guardado.cambiar(func(g): g.paginas = [ids[0], ids[2]] + de_otros)
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	ordenador.abrir("dosier", "b_" + ids[2])
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-dosier.png")
	# la del jefe, si este edificio la tiene (el centro comercial): sin encontrar en el ordenador y luego soltada
	var del_jefe := Historia.del_jefe(Guardado.cargar(), edificio)
	if not del_jefe.is_empty():
		ordenador.abrir("dosier", "b_" + del_jefe.id)
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-dosier-falta.png")
	ordenador.abrir("")
	ordenador.apagar()
	if not del_jefe.is_empty():
		pagina_del_jefe()
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-pagina-jefe.png")
		print("Página del jefe: %s | en el guardado: %s" % [del_jefe.id, Guardado.cargar().paginas])
		menus.leida()
	await montar(planta.mantenimiento, 0, false)
	await probar_noticias()


# Colecciones (bestiario.gd y el programa del ordenador): deja en el guardado parte de lo que hay (6 objetos,
# cuatro o siete enemigos) y hace las fotos: el escritorio con el aviso de "¡NUEVO!"
# (captura-escritorio-nuevo.png), los objetos de este edificio (captura-colecciones.png), la ficha del vecino
# (captura-bestiario.png) y la del gerente, sin ver (captura-bestiario-falta.png). Luego cuenta en la terminal lo
# encontrado y visto de cada edificio, y comprueba los totales
func probar_colecciones() -> void:
	# lo que la prueba ha ido apuntando sola (meter_zombi avisa al bestiario con cada enemigo que nace)
	print("Bestiario apuntado por la prueba hasta aquí: %s" % [Guardado.cargar().get("bestiario", [])])
	var encontrados: Array = Objetos.de_edificio(edificio).slice(0, 6)
	var vistos: Array = ["normal", "lento", "rapido", "portera"]
	if edificio == "centro":
		vistos += ["dependienta", "guardia", "antidisturbios"]
	Guardado.cambiar(func(g):
		g.encontrados = encontrados
		g.bestiario = vistos
		g.colecciones_nuevo = true)
	abrir_ordenador()
	await get_tree().create_timer(0.5).timeout   # el encendido del monitor dura 0,35 s
	Captura.foto("captura-escritorio-nuevo.png")   # el icono avisa de que hay algo nuevo
	ordenador.abrir("colecciones", "c_%s_objetos" % edificio)
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-colecciones.png")
	ordenador.abrir("colecciones", "z_normal")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-bestiario.png")
	ordenador.abrir("colecciones", "z_gerente")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-bestiario-falta.png")
	# los recuentos que enseña el programa, edificio por edificio
	var g := Guardado.cargar()
	for e in Edificios.LISTA:
		var objetos: Array = Objetos.de_edificio(e)
		var bichos: Array = Bestiario.de_edificio(e)
		print("Colecciones de %s: objetos %d/%d | bestiario %d/%d" % [e,
			objetos.filter(func(id): return id in g.encontrados).size(), objetos.size(),
			bichos.filter(func(id): return id in g.bestiario).size(), bichos.size()])
	if Objetos.de_edificio("apartamentos").size() != 7 or Objetos.de_edificio("centro").size() != 8:
		push_error("Colecciones: los objetos por edificio no son 7 y 8")
	if Bestiario.LISTA.size() != 22:
		push_error("Colecciones: el bestiario no tiene 22 fichas")
	if Bestiario.retrato("gerente_mutado") == null:
		push_error("Colecciones: el retrato del gerente mutado es null")
	if g.colecciones_nuevo:
		push_error("Colecciones: el aviso de nuevo sigue puesto después de abrir el programa")
	ordenador.abrir("")
	ordenador.apagar()


# Las noticias: en los Apartamentos, con la página del correo encontrada salen tres emisiones (dos sin ver); en el
# centro comercial, con los Apartamentos completados y sus dos primeras páginas, salen cinco (dos sin ver). Abre el
# programa, deja hablar a la reportera un poco y hace la foto; luego otra con todo lo que dice
func probar_noticias() -> void:
	var ids: Array = Historia.dosier(edificio).paginas.map(func(p): return p.id)
	var centro := edificio == "centro"
	Guardado.cambiar(func(g):
		g.paginas = [ids[0], ids[1]] if centro else ["vd7_protocolo", "vd7_correo"]
		g.noticias_vistas = ["n_cierre", "n_buscado", "n_reformas"] if centro else ["n_cierre"]
		# los edificios completados, siempre igual (el final de la prueba vuelve a completar el de la partida): en el
		# centro, los Apartamentos sí y el centro no (la del helicóptero, aún sin emitir)
		Guardado.edificio(g, "apartamentos").completado = centro
		Guardado.edificio(g, "centro").completado = false)
	print("Noticias emitidas: %s | nuevas: %s" % [Historia.noticias_emitidas(Guardado.cargar()).map(func(n): return n.id),
		Historia.noticias_nuevas(Guardado.cargar()).map(func(n): return n.id)])
	avisar_noticias()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-aviso-noticias.png")
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-escritorio.png")
	# el marco de madera sigue al ratón: pasar por encima de «Logros» lo marca
	ordenador.iconos.get_child(2).mouse_entered.emit()
	print("Escritorio · ratón sobre Logros, marcado: %s (esperado: icono_logros)" % get_viewport().gui_get_focus_owner().name)
	ordenador.abrir("noticias")
	await get_tree().create_timer(3.0).timeout
	Captura.foto("captura-noticias.png")
	# luego, sin el rótulo del nombre (sale solo al empezar) y con todo lo que dice la reportera (¿cabe en su cuadro?)
	await get_tree().create_timer(2.0).timeout
	for t in ordenador.find_children("*", "", true, false):
		if t is Tele:
			t.saltar()
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-noticias-entera.png")
	print("Noticias vistas tras abrir: ", Guardado.cargar().noticias_vistas)
	ordenador.abrir("")
	ordenador.apagar()


# Con "--captura --historia": todos los textos de historia.gd, para ver si caben. Cada página del dosier de cada
# edificio en su hoja, como al cogerla (captura-hoja-<id>.png), y cada noticia en la tele con todo lo que dice la
# reportera (captura-tele-<id>.png). Al acabar, el guardado de prueba vuelve a tener sus páginas y sus noticias
func probar_historia_entera() -> void:
	var antes := Guardado.cargar().duplicate(true)
	for e in Historia.DOSIERES:
		var paginas: Array = Historia.DOSIERES[e].paginas
		for i in paginas.size():
			menus.pagina(paginas[i], i + 1, paginas.size(), func(): pass)
			await get_tree().create_timer(0.3).timeout
			Captura.foto("captura-hoja-%s.png" % paginas[i].id)
			menus.leida()
	# todas las noticias emitidas: todas las páginas encontradas y los dos edificios completados
	Guardado.cambiar(func(g):
		for e in Historia.DOSIERES:
			for p in Historia.DOSIERES[e].paginas:
				if not p.id in g.paginas:
					g.paginas.append(p.id)
		for e in Historia.DOSIERES:
			Guardado.edificio(g, e).completado = true)
	print("Noticias emitidas: %d de %d" % [Historia.noticias_emitidas(Guardado.cargar()).size(), Historia.NOTICIAS.size()])
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	for n in Historia.NOTICIAS:
		ordenador.abrir("noticias", "b_" + n.id)
		await get_tree().create_timer(0.3).timeout
		for t in ordenador.find_children("*", "", true, false):
			if t is Tele:
				t.saltar()
		await get_tree().create_timer(2.5).timeout   # que se vaya el rótulo del nombre de la reportera
		Captura.foto("captura-tele-%s.png" % n.id)
	ordenador.abrir("")
	ordenador.apagar()
	Guardado.cambiar(func(g):
		g.paginas = antes.paginas
		g.noticias_vistas = antes.noticias_vistas
		for e in Historia.DOSIERES:
			Guardado.edificio(g, e).completado = antes.edificios.get(e, {}).get("completado", false))


# Con "--captura --banco": lo de las recetas en un guardado viejo (las armas creadas del baúl, "baul_armas"; las
# recetas aprendidas, "recetas", y las armas creadas alguna vez, "creadas", de Colecciones), que se quitó el 25 oct, y
# los objetos quitados ese día (los de las armas de cuerpo a cuerpo y los clavos, el spray, la lejía, la pistola de
# agua, la cinta americana, la bombona, la jeringuilla, el aceite y el bocadillo) y los que se quitaron con las piezas
# (los explosivos, el despertador, el extintor, el trapo y el alcohol) en el baúl y en los encontrados (Colecciones):
# al cargar desaparece todo (guardado.gd); la gasolina, que sigue, se queda. Luego, el baúl abierto con lo
# que queda (captura-banco-baul.png), la mochila, el banco de trabajo y el baúl (probar_cosas), los arrojables y las
# armas de efecto (probar_efectos) y las Colecciones (probar_colecciones). Cada línea dice lo esperado y se cierra
func probar_banco() -> void:
	var s := Guardado.cargar()
	s["baul_armas"] = [{"receta": "atraedora", "nombre": "Atraedora", "hueco": "arrojadiza", "icono": "despertador",
		"rareza": "azul", "dano": 96, "unidades": 4}]
	s["recetas"] = ["atraedora", "congeladora"]
	s["creadas"] = ["atraedora"]
	var quitados := ["mechero", "llave_inglesa", "hacha", "cuchillas", "taser", "cuerda", "mancuernas", "cadena", "perchas",
		"hielo_seco", "cable", "clavos", "spray", "lejia", "pistola_agua", "cinta_americana", "bombona", "jeringuilla",
		"aceite", "bocadillo", "explosivos", "despertador", "extintor", "trapo", "alcohol"]
	s.baul = {"gasolina": 1}
	for id in quitados:
		s.baul[id] = 2
	s.encontrados = quitados + ["gasolina"]
	Guardado.escribir(s)
	var leido := Guardado.cargar()
	print("Lo de las recetas, viejo, al cargar: baul_armas %s · recetas %s · creadas %s (esperado: false, false, false)" % [
		leido.has("baul_armas"), leido.has("recetas"), leido.has("creadas")])
	print("Los %d objetos quitados, viejos, al cargar: baúl %s · encontrados %s (esperado: { \"gasolina\": 1 }, [\"gasolina\"])" % [
		quitados.size(), leido.baul, leido.encontrados])
	abrir_cosas("baul")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-banco-baul.png")
	inventario.cerrar()
	await get_tree().process_frame
	await probar_cosas()
	await probar_efectos()
	await probar_colecciones()
	get_tree().quit()


# La mochila, el banco y el baúl: unos objetos en la mochila y en el baúl, compra el bate (la fregona va al
# inventario), abre el banco de trabajo (como al arrimarse; lo de mejorar, en --banco-mejorar) y hace fotos
func probar_cosas() -> void:
	Guardado.cambiar(func(g):
		g.dolares = 20
		g.baul = {"pieza_cuerpo": 1, "pieza_especial": 2})
	ahorrados = 20
	mochila = ["gasolina", "gasolina", "pieza_especial", "pieza_cuerpo", "pieza_arrojable"]
	soltar_objeto("pieza_distancia", johnny.position + Vector2(30, 0))
	await get_tree().create_timer(0.6).timeout
	abrir_ordenador()
	ordenador.abrir("armas")
	ordenador.comprar_arma("bate")
	ordenador.abrir("")
	ordenador.apagar()
	abrir_cosas("inventario")
	inventario.tocar("m0")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-inventario.png")
	inventario.cerrar()
	if mapa.banco:
		mapa.banco.usar.emit()   # como al arrimarse
	else:
		abrir_cosas("banco")   # (la prueba larga llega aquí desde la sala de un jefe, donde no hay banco: lo mismo que haría)
	await get_tree().process_frame
	print("Banco: abre la pantalla «%s» (esperado: banco)" % inventario.abierto)
	inventario.cerrar()
	abrir_cosas("baul")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-baul.png")
	inventario.cerrar()
	var g := Guardado.cargar()
	print("Cosas: mochila %s | guardadas %s | mano %s | baúl %s" % [mochila, armas_guardadas, johnny.huecos.cuerpo, g.baul])


# Los arrojables y las armas de efecto: coge congeladoras y atraedoras, lleva el lanza ácido y el lanza rayos
# (de la tienda de armas), dispara el lanza rayos, se pone el lanza ácido desde el inventario y dispara, y lanza
# la congeladora. Cuenta lo que pasa y hace una foto
func probar_efectos() -> void:
	dar_lanzable("congeladora")
	dar_lanzable("atraedora")
	llevar_arma("desintegrador")
	# dos de fuego como mucho (partida.llevar_arma): se deja la de repuesto, para que el lanza ácido pase a serlo
	armas_guardadas.assign(armas_guardadas.filter(func(id): return Armas.datos(id).tipo != "fuego"))
	llevar_arma("pistola_electrica")
	print("Armas de efecto: mano %s | guardadas %s | lanzables a mano %s, de repuesto %s" % [
		[Objetos.nombre(johnny.huecos.cuerpo), Objetos.nombre(johnny.huecos.fuego)], armas_guardadas.map(Objetos.nombre),
		lanzables.mano, lanzables.repuesto])
	print("En la tienda de armas: %s (esperado: Lanzallamas $60, Lanza ácido $60, Lanza rayos $45)" % [
		["lanzallamas", "desintegrador", "pistola_electrica"].map(func(id): return "%s $%d" % [Armas.DATOS[id].nombre, Armas.PRECIOS[id]])])
	johnny.direccion = "e"
	johnny.sostener("fuego")
	var z1 := meter_zombi("lento", johnny.position + Vector2(80, 0))
	var z2 := meter_zombi("lento", johnny.position + Vector2(140, 10))
	z1.vida = 500   # que no muera ninguno (saldría el recuadro de las mutaciones y pararía el juego)
	z2.vida = 500
	await get_tree().create_timer(0.1).timeout
	johnny.disparar(0.0)
	await get_tree().create_timer(0.3).timeout
	print("Lanza rayos: balas %d | zombi 1 aturdido %.1f vida %d | zombi 2 aturdido %.1f vida %d" % [johnny.balas,
		z1.aturdido, z1.vida, z2.aturdido, z2.vida])
	abrir_cosas("inventario")
	inventario.tocar("g%d" % armas_guardadas.find(armas_guardadas.filter(func(id): return Objetos.nombre(id) == "Lanza ácido")[0]))
	inventario.poner_guardada()
	inventario.cerrar()
	for i in 6:
		johnny.disparar(0.0)
		await get_tree().create_timer(0.08).timeout
	await get_tree().create_timer(0.2).timeout
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().process_frame
	Captura.foto("captura-efectos.png")
	menus.visible = true
	print("Lanza ácido: mano %s balas %d | zombi 2 vida %d heridas %s | charcos %d" % [Objetos.nombre(johnny.huecos.fuego),
		johnny.balas, z2.vida, z2.get_children().filter(func(n): return n.name.begins_with("herida")).map(func(n): return n.name),
		get_tree().get_nodes_in_group("charcos").size()])
	var z3 := meter_zombi("lento", johnny.position + Vector2(-120, 30))
	z3.vida = 500
	lanzables.tipo = "congeladora"
	lanzables.lanzar(z3.global_position)
	await get_tree().create_timer(2.3).timeout
	print("Congeladora: zombi 3 aturdido %.1f vida %d | vida de Johnny %d | quedan %s" % [z3.aturdido, z3.vida, johnny.vida, lanzables.tipos()])


# El reparto de objetos (parte 6 del centro comercial): cuenta qué sale en cada sitio de los dos edificios y
# comprueba que las vendas (del centro) no salen en los Apartamentos y que ni las piezas ni lo de un solo zombi salen al
# azar. Luego deja en el suelo los del centro (SOLO_CENTRO), mete las piezas en el baúl (lo de «Piezas al baúl» del panel de pruebas) y hace una
# foto del baúl
func probar_objetos() -> void:
	var fallos := []
	for ed_id in ["apartamentos", "centro"]:
		for tienda in [""] + (Objetos.TIENDAS.keys() if ed_id == "centro" else []):
			var salen := {}
			for i in 2000:
				var id := Objetos.al_azar(ed_id, tienda)
				salen[id] = salen.get(id, 0) + 1
				if id in Objetos.DE_UN_ZOMBI or id in Objetos.PIEZAS or (ed_id == "apartamentos" and id in Objetos.SOLO_CENTRO):
					fallos.append("%s %s: %s" % [ed_id, tienda, id])
			print("Objetos en %s %s: %d distintos %s" % [ed_id, tienda if tienda != "" else "(pasillo)", salen.size(), salen.keys()])
	print("Reparto de objetos: ", "bien" if fallos.is_empty() else "MAL %s" % str(fallos.slice(0, 5)))
	for i in Objetos.SOLO_CENTRO.size():
		soltar_objeto(Objetos.SOLO_CENTRO[i], johnny.position + Vector2(-176 + i * 44, -100), true)
	await get_tree().create_timer(0.5).timeout
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().process_frame
	Captura.foto("captura-objetos-nuevos.png")
	menus.visible = true
	for cosa in mapa.cosas.get_children():
		if cosa.get_script() == BILLETE:
			cosa.queue_free()
	var baul_antes: Dictionary = Guardado.cargar().baul
	dar_objetos()
	abrir_cosas("baul")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-todo.png")
	inventario.cerrar()
	print("Baúl con las piezas: %d casillas de %d (esperado: 4)" % [Objetos.casillas_baul(Guardado.cargar()), Objetos.BAUL])
	Guardado.cambiar(func(g): g.baul = baul_antes)


# El recuadro de las mutaciones: foto, elige la primera y comprueba que cambia los atributos
func probar_mutaciones() -> void:
	abrir_mutacion()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-mutacion.png")
	var primera: String = menus.cartas[0].id
	menus.elegir(primera)
	elegir_mutacion("insensible")
	print("Mutaciones: %s | daño recibido x%.2f | pausa %s" % [mutaciones.tengo, johnny.stats.dano_recibido, get_tree().paused])


# Fotos de la pausa y del cartel de victoria (con el juego parado solo cuentan los temporizadores)
func probar_menus() -> void:
	set_process(false)
	# Johnny, como nuevo y sin charcos alrededor: el bombero deja el suelo ardiendo y le seguía quemando hasta
	# dejarle en un tercio; con la vida tan baja las curas no se podían usar (se quedaba el inventario abierto y
	# el juego en pausa, y la prueba no se cerraba nunca) y en la azotea moría
	for c in get_tree().get_nodes_in_group("charcos"):
		c.remove_from_group("charcos")
		c.queue_free()
	johnny.estados.clear()
	johnny.tercios = 3
	johnny.vida = johnny.stats.vida_max
	soltar_billetes(3, johnny.position + Vector2(60, 0))
	await get_tree().create_timer(1.2).timeout
	print("Dólares de la partida: %d | muertos: %d" % [dolares, muertos])
	await probar_ordenador()
	await probar_cosas()
	await probar_efectos()
	await probar_objetos()
	await probar_curas()
	await supervivientes.probar()
	await probar_sangre()
	await probar_mutaciones()
	await probar_historia()
	await probar_colecciones()
	if ed.get("azotea", false):
		await probar_azotea()
	pausar()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-pausa.png")
	seguir()
	terminar(true)
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-fin.png")
	print("Guardado de prueba: ", Guardado.cargar())
	get_tree().quit()
