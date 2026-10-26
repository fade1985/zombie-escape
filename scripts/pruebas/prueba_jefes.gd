# Pruebas de los jefes: su presentación (--presentacion) y lo que mira la prueba larga de cada jefe y de las
# azoteas. Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_jefes_salas.gd"


# Con "--captura --presentacion" (y --jefe gloton, u otro): la presentación del jefe (ui/presentacion.gd). Entra en el
# piso del jefe de la 1ª planta; mientras el jefe tarda en salir, mira que Johnny no se mueve aunque se le dé a andar;
# cuando él aparece, mira al gritar (captura-presentacion-grito.png) que no sale
# ninguna frase escrita y que Johnny está callado; a mitad de la presentación (captura-presentacion.png), que la
# cámara está acercada y sobre el jefe, Johnny quieto y sin poder recibir daño, el jefe gritando, el nombre en
# pantalla y la barra de vida aún oculta; y al acabar, que la cámara ha vuelto, Johnny se mueve (y dice lo que se ha
# callado), el jefe anda y la barra ha salido. Con la Modista (--edificio centro --jefe modista), que entra
# escondida, ni zoom ni grito: solo franjas, nombre y rugido, y sigue escondida al acabar. Johnny lleva las mutaciones
# que actúan solas (mutaciones.gd), listas y con un zombi quieto al lado: ninguna actúa mientras dura, y cada una 1 s
# después de acabar (captura-presentacion-vomito.png, con el vómito en el aire); el acompañante que ataca (el policía
# del guardado de la prueba), igual: con lo suyo listo, no ataca hasta 1 s después (aliado.gd, calma). Cuenta todo en
# la terminal, con lo esperado, y se cierra
func probar_presentacion() -> void:
	set_process(false)
	presentar_en_prueba = true
	nueva_planta(2)   # la 1ª planta: con --jefe X, el suyo
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	# con las mutaciones que actúan solas, listas (como en la partida, esperando a quién): se apunta cuándo actúa cada
	# una (al actuar, su cuenta vuelve a "cada": se ve en el fotograma siguiente) y si la presentación seguía
	var ids := ["gastro", "tentacular", "locura", "flatulento"]
	for id in ids:
		mutaciones.tengo.append(id)
		mutaciones.espera[id] = 0.0
	# el reloj del juego (el de las mutaciones: en los parones de los golpes, Temblor.parar, casi no avanza)
	var reloj := get_tree().create_timer(1000.0)
	var ahora := func() -> float: return 1000.0 - reloj.time_left
	var actua: Array = []   # [mutación, cuándo (s del juego), si la presentación seguía]
	# y lo mismo con los acompañantes que atacan (al atacar, su cuenta vuelve a "cada", igual que las mutaciones)
	var ataques: Array = []   # [cuándo (s del juego), si la presentación seguía]
	get_tree().physics_frame.connect(func() -> void:
		for id in ids:
			if mutaciones.espera[id] == Mutaciones.MUT[id].cada:
				actua.append([id, ahora.call(), presentacion.activa])
		for a in get_tree().get_nodes_in_group("aliados"):
			if a.modo == "equipo" and a.ataca() and a.hab_t == a.def.habilidad.cada:
				ataques.append([ahora.call(), presentacion.activa]))
	montar(idx, 0, false)   # (sin await: la presentación va dentro, y hay que mirarla a medias)
	# Johnny, a 200 de donde saldrá el jefe (en medio de la sala): desde la puerta, el vómito (420) no le llegaría
	johnny.position = Vector2(planta.sitios[idx].ancho / 2.0, planta.sitios[idx].alto / 2.0 + 200.0)
	johnny.get_node("Camara").reset_smoothing()
	# hasta que empieza la presentación (lo que tarda el jefe en salir), Johnny parado aunque se le dé a andar
	var antes: Vector2 = johnny.position
	var suelto := false
	Input.action_press("derecha")
	# y, nada más empezar la presentación (hasta ahí, sin nadie a quien hacérselo, esperan listas), un zombi quieto a su
	# lado, para que Tentacular, Locura y Flatulento tengan a quién (el vómito también va a él; con mucha vida, que no
	# lo maten)
	while not presentacion.activa:
		await get_tree().physics_frame
		suelto = suelto or johnny.is_physics_processing()
	Input.action_release("derecha")
	print("Presentación, antes de salir el jefe: Johnny suelto algún fotograma %s · se ha movido %d dándole a andar (esperado: false, 0)" % [
		suelto, roundi(johnny.position.distance_to(antes))])
	var vecino := meter_zombi("normal", johnny.position + Vector2(40, 0))
	vecino.set_physics_process(false)
	vecino.vida = 100000
	# y los acompañantes que atacan, con lo suyo listo (como las mutaciones): atacan en cuanto se les acaba la calma
	var acompanan: Array = get_tree().get_nodes_in_group("aliados").filter(func(a): return a.modo == "equipo" and a.ataca())
	for a in acompanan:
		a.hab_t = 0.0
	# a 0,6 s, recién soltado el grito: ningún texto flotando en la sala (el jefe no dice ninguna frase escrita) y
	# Johnny callado (lo de la habitación lo dice al acabar)
	await get_tree().create_timer(0.6).timeout
	var flotando: Array = jefa.get_parent().get_children().filter(func(n): return n is Label).map(func(n): return n.text)
	print("Presentación, al gritar: textos flotando en la sala %d %s (esperado: 0: el grito es la pose y el rugido, sin frase escrita) · Johnny dice algo %s (esperado: false: se calla hasta el final)" % [
		flotando.size(), flotando, aviso.modulate.a > 0.0 and aviso.text != ""])
	Captura.foto("captura-presentacion-grito.png")
	await get_tree().create_timer(0.5).timeout   # a 1,1 s de empezar la presentación
	var camara: Camera2D = johnny.get_node("Camara")
	print("Presentación (jefe %s), a mitad: zoom %.2f (esperado: %.1f; 1 si entra escondido, como la Modista) · cámara desplazada %d hacia el jefe (esperado: más de 0; 0 si escondido) · a %d del jefe (esperado: menos de 60, que enfoca algo por encima; da igual si escondido) · Johnny quieto %s y sin daño %s (esperado: true, true) · el jefe gritando %s (esperado: true; false si escondido) · nombre «%s» a la vista %s (esperado: true) · barra oculta %s (esperado: true)" % [
		planta.jefe, camara.zoom.x, presentacion.ZOOM, roundi(camara.offset.length()),
		roundi(camara.get_screen_center_position().distance_to(jefa.global_position)), not johnny.is_physics_processing(),
		johnny.invulnerable > 0.0, jefa.estado == "grito", presentacion.nombre.text,
		presentacion.visible and presentacion.nombre.modulate.a > 0.9, not $Pantalla/Jefa.visible])
	# el foco que alumbra al jefe mientras grita (presentacion.gd): ninguno al Gymbro (se ve con la luz de su gimnasio)
	var focos: int = jefa.get_children().filter(func(n): return n is PointLight2D and n.texture_scale == Presentacion.LUZ_RADIO / 128.0).size()
	print("  (focos sobre el jefe %d (esperado: %s))" % [focos, "0, no lleva (SIN_FOCO)" if planta.jefe in Presentacion.SIN_FOCO else "1; 0 si entra escondido, como la Modista"])
	print("  (jefe en %s, a %d del medio de la sala (esperado: menos de 60) · centro de la cámara %s · offset %s · límites %d-%d x %d-%d · zoom %s)" % [jefa.global_position.round(),
		roundi(jefa.global_position.distance_to(Vector2(planta.sitios[idx].ancho / 2.0, planta.sitios[idx].alto / 2.0))),
		camara.get_screen_center_position().round(), camara.offset, camara.limit_left, camara.limit_right, camara.limit_top, camara.limit_bottom, camara.zoom])
	Captura.foto("captura-presentacion.png")
	while presentacion.activa:
		await get_tree().physics_frame
	var acabo: float = ahora.call()
	await get_tree().create_timer(0.5).timeout
	print("Presentación, al acabar: zoom %.2f (esperado: 1) · cámara desplazada %d (esperado: 0) · Johnny se mueve %s (esperado: true) · el jefe en «%s» (esperado: no «grito») · barra a la vista %s (esperado: true) · franjas y nombre ocultos %s (esperado: true) · Johnny dice «%s» (esperado: lo de la habitación, si tiene peligro: en la del bombero, «¡La habitación está en llamas!…»; si no, nada)" % [
		camara.zoom.x, roundi(camara.offset.length()), johnny.is_physics_processing(), jefa.estado, $Pantalla/Jefa.visible,
		not presentacion.visible, aviso.text if aviso.modulate.a > 0.0 else ""])
	# la primera vez de cada una después, y el primer ataque de los acompañantes (se espera hasta 2,5 s del juego); y
	# la foto, con el vómito ya en el aire
	var primera := {}
	var primer_ataque := ""
	while (primera.size() < ids.size() or (not acompanan.is_empty() and primer_ataque == "")) and ahora.call() - acabo < 2.5:
		await get_tree().physics_frame
		for a in actua:
			if a[1] >= acabo and not primera.has(a[0]):   # (las de antes de salir el jefe no cuentan)
				primera[a[0]] = "%.2f" % (a[1] - acabo)
		for a in ataques:
			if a[0] >= acabo and primer_ataque == "":
				primer_ataque = "%.2f" % (a[0] - acabo)
	print("Mutaciones: veces que actúan durante la presentación %d (esperado: 0) · la primera de cada una, en s después de acabar: %s (esperado: las 4, a 1, con un fotograma de margen: entre 0,95 y 1,1)" % [
		actua.filter(func(a): return a[2]).size(), primera])
	print("Acompañantes que atacan %s: ataques durante la presentación %d (esperado: 0) · el primero, en s después de acabar: %s (esperado: a 1, como las mutaciones: entre 0,95 y 1,1; sin acompañantes, «»)" % [
		acompanan.map(func(a): return a.def.id), ataques.filter(func(a): return a[1]).size(), primer_ataque])
	await get_tree().create_timer(0.15).timeout
	Captura.foto("captura-presentacion-vomito.png")
	get_tree().quit()


# La modista, en la prueba: cuántos maniquíes hay en su tienda, que se cambie de sitio con uno y que cobren vida
# tres (al caer ella, se caen)
func probar_modista(jefa: Node2D) -> void:
	var antes: Vector2 = jefa.position
	print("Modista: %d maniquíes en %s | al entrar, escondida: %s" % [jefa.maniquies().size(), planta.sitios[aqui].nombre,
		jefa.estado == "escondida"])
	jefa.cambiarse(johnny)
	print("Modista: se cambia de sitio con un maniquí (a %d unidades) | ahora: %s" % [antes.distance_to(jefa.position), jefa.estado])
	jefa.despertar_maniquies(johnny)
	print("Modista: cobran vida %d maniquíes | quedan %d de mueble" % [jefa.vivos.size(), jefa.maniquies().size()])
	jefa.murio.connect(func(): (func():
		print("Modista: al caer ella, maniquíes vivos: %d" % jefa.vivos.filter(func(v): return v.estado != "muerto").size())
		).call_deferred())


# El Glotón: la sangre ácida (primero, la bala de un superviviente: le hace daño a él y a Johnny no le salpica; luego
# dos golpes de Johnny seguidos: solo el primero salpica, un 1 % de su vida) y el aspirado (hasta dónde llega: al
# borde de la elipse limpia de su habitación, mire a donde mire; y Johnny puesto a 220 de él: 0,15 s al abrir la boca
# y otros 0,15 s con toda su fuerza; antes de la foto de los 7,7)
func probar_gloton() -> void:
	# la bala de verdad, encima de él, con un paso suyo hecho a mano (para que no tarde nada)
	var antes_vida: int = johnny.vida
	var antes_jefe: int = jefa.vida
	var bala := preload("res://escenas/armas/bala.tscn").instantiate()
	bala.velocidad = Vector2.RIGHT * 620.0
	bala.dano = 10
	bala.de_aliado = true
	bala.set_physics_process(false)
	jefa.get_parent().add_child(bala)
	bala.global_position = jefa.global_position
	bala._physics_process(1.0 / 60.0)
	print("Sangre ácida (bala de 10 de un superviviente): Glotón -%d, Johnny -%d (esperado: 10 y 0)" % [
		antes_jefe - jefa.vida, antes_vida - johnny.vida])
	antes_vida = johnny.vida
	jefa.recibir_golpe(10, Vector2.RIGHT * 300.0)
	jefa.recibir_golpe(10, Vector2.RIGHT * 300.0)
	print("Sangre ácida (dos golpes seguidos de 10): Johnny -%d" % (antes_vida - johnny.vida))
	for i in 60:
		var p: Vector2 = jefa.position + Vector2.from_angle(randf() * TAU) * 220.0
		if mapa.zona_en(p) >= 0:
			johnny.position = p
			break
	# hasta dónde llega: a la derecha, abajo, a la izquierda y arriba, y que las puntas caen en el borde de la elipse
	var ov: Dictionary = jefa.la_elipse()
	if ov.is_empty():
		print("Aspirar: no encuentra la elipse limpia de su habitación (¡mal!)")
	else:
		var largos := PackedStringArray()
		var en_borde := true
		for a in [0.0, PI / 2.0, PI, -PI / 2.0]:
			var largo: float = jefa.largo_aspirado(a, jefa.global_position)
			largos.append("%.1f" % (largo / 32.0))
			var punta: Vector2 = jefa.global_position + Vector2.from_angle(a) * largo
			en_borde = en_borde and absf(((punta - ov.centro) / Vector2(ov.rx, ov.ry)).length() - 1.0) < 0.001
		print("Aspirar: llega al borde de la elipse (de %.1f × %.1f casillas) mire a donde mire: a la derecha, abajo, a la izquierda y arriba %s casillas · las puntas, en el borde %s (esperado: true)" % [
			ov.rx * 2.0 / 32.0, ov.ry * 2.0 / 32.0, " / ".join(largos), en_borde])
	jefa.mirada = (johnny.position - jefa.position).normalized()
	jefa.cambiar("aspirar")
	# va de menos a más: lo que tira a 3, 5, 8 y 12 casillas al abrir la boca, y lo que acerca a Johnny (quieto) en
	# 0,15 s; luego lo mismo ya con toda su fuerza (Johnny anda a 210: de cerca le arrastra, de lejos no, pero le frena)
	var sitio: Vector2 = johnny.position
	var flojo := [3, 5, 8, 12].map(func(c): return roundi(jefa.tiron_aspirado(c * 32.0)))
	var d0: float = johnny.position.distance_to(jefa.position)
	await get_tree().create_timer(0.15, false).timeout
	var d1: float = johnny.position.distance_to(jefa.position)
	johnny.position = sitio
	johnny.velocity = Vector2.ZERO
	jefa.t = jefa.CRECE_ASPIRAR
	var fuerte := [3, 5, 8, 12].map(func(c): return roundi(jefa.tiron_aspirado(c * 32.0)))
	await get_tree().create_timer(0.15, false).timeout
	print("Aspirar (0,15 s, Johnny quieto): al empezar de %d a %d; con toda su fuerza de %d a %d (le ve: %s)" % [
		d0, d1, d0, johnny.position.distance_to(jefa.position), jefa.se_ve(johnny)])
	print("Aspirar, tirón a 3/5/8/12 casillas (Johnny anda a 210): al empezar %s; con toda su fuerza %s (esperado: [327, 211, 84, 70])" % [flojo, fuerte])
	# y la foto del cono, aspirando con toda su fuerza: hasta el borde de la elipse
	print("Aspirar: foto en captura-gloton-aspira.png (aspirando: %s)" % (jefa.estado == "aspirar"))
	Captura.foto("captura-gloton-aspira.png")


# El Gymbro: se enfada ya (los suplementos): un golpe de 20 le quita 10 de vida y 10 de armadura, y sale la barra
# de armadura. El salto: qué cae dentro de la zona (a un lado y arriba, justo dentro y justo fuera del borde) y uno de
# verdad, en el sitio, con Johnny de pie justo fuera del borde: la foto con él en el aire y, al caer, no le da (0,35 s;
# antes de la foto de los 7,7). Y lanza sus pesas (enfadado, 4) para que salgan en la foto de los 8,0
func probar_gymbro() -> void:
	jefa.fase = 2
	jefa.al_enfadarse(johnny)
	var vida_antes: int = jefa.vida
	var armadura_antes: int = jefa.armadura
	jefa.recibir_golpe(20, Vector2.RIGHT * 300.0)
	var barra: Node = $Pantalla/Jefa.get_node_or_null("Armadura")
	print("Gymbro con suplementos (golpe de 20): vida -%d, armadura -%d de %d | barra de armadura: %s" % [
		vida_antes - jefa.vida, armadura_antes - jefa.armadura, jefa.armadura_max, barra != null and barra.visible])
	# la zona del salto, en el suelo a sus pies (con el margen de Johnny, como al caer)
	var r: float = jefa.RADIO_SALTO
	var suelo: Vector2 = jefa.global_position + Vector2(0, jefa.PIE - 6)
	var margen: float = johnny.RADIO * 0.6
	var dentro := [Vector2(r - 10.0, 0), Vector2(r + 30.0, 0), Vector2(0, -(r * 0.6 - 10.0)), Vector2(0, -(r * 0.6 + 30.0))].map(
		func(d): return jefa.en_la_zona(suelo + d, margen))
	print("Gymbro, zona del salto (%d de ancho y %d de alto): a un lado, justo dentro %s y justo fuera %s; arriba, justo dentro %s y justo fuera %s (esperado: true, false, true, false)" % [
		r * 2.0, r * 1.2, dentro[0], dentro[1], dentro[2], dentro[3]])
	for lado in [1.0, -1.0]:
		var p: Vector2 = jefa.position + Vector2(0, jefa.PIE - 6) + Vector2(lado * (r + 30.0), -16.0)
		if mapa.zona_en(p) >= 0:
			johnny.position = p
			break
	johnny.get_node("Camara").reset_smoothing()
	jefa.mirada = (johnny.position - jefa.position).normalized()
	jefa.cambiar("salto", {"desde": jefa.global_position, "hasta": jefa.global_position, "vuelo": jefa.VUELO[0]})
	jefa.t = jefa.VUELO[0] * 0.75
	var antes_johnny: int = johnny.vida
	await get_tree().create_timer(0.1, false).timeout
	print("Gymbro: foto del salto en captura-gymbro-salto.png (en el aire: %s; Johnny, a %d del centro de la zona)" % [
		jefa.estado == "salto", (johnny.global_position + Vector2(0, 16) - suelo).length()])
	Captura.foto("captura-gymbro-salto.png")
	await get_tree().create_timer(0.25, false).timeout
	print("Gymbro: cae del salto (%s) con Johnny justo fuera del borde: Johnny -%d (esperado: 0)" % [
		jefa.estado == "aterrizar", antes_johnny - johnny.vida])
	jefa.lanzar_pesas(johnny)
	print("Gymbro: pesas en el aire: %d" % get_tree().get_nodes_in_group("balas_zombi").size())


# El jefe de bomberos: el fuego no le hace nada (un pellizco de la llamarada del lanzallamas, el fogonazo de un molotov
# y un charco de fuego debajo de él no le quitan vida, y grita «¡INMUNE!»), pero un golpe sí (antes de que se ponga a girar para
# la foto: girando, su burbuja de fuego no deja); y lanza sus bolas de fuego y un molotov (para que salgan en la foto
# de los 8,0, con el giro)
func probar_bombero() -> void:
	var vida_antes: int = jefa.vida
	# (la llamarada, puesta a 40 de él apuntándole, y un pellizco)
	johnny.llamarada.mantener(jefa.global_position - Vector2(40, 0), 0.0, {"alcance": 320.0, "dano": 60.0, "empuje": 0.5})
	johnny.llamarada.tope = 320.0
	johnny.llamarada.quemar()
	var sin_lanzallamas: int = vida_antes - jefa.vida
	var molotov: Node2D = load("res://escenas/armas/proyectil.tscn").instantiate()
	molotov.tipo = "molotov"
	molotov.desde = jefa.position
	molotov.hasta = jefa.position
	add_child(molotov)
	molotov.llamarada(60.0)
	molotov.queue_free()
	var sin_molotov: int = vida_antes - jefa.vida
	# el golpe, ya (a los 7,7 se pone a girar para la foto, y girando la burbuja no deja que nada le quite vida)
	var antes_golpe: int = jefa.vida
	jefa.recibir_golpe(10, Vector2.RIGHT * 300.0)
	var golpe: int = antes_golpe - jefa.vida
	vida_antes = jefa.vida
	var fuego: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
	fuego.tipo = "fuego"
	fuego.position = jefa.position
	add_child(fuego)
	# (0,6 s: el charco prende a los zombis cada medio segundo; y hay que acabar antes de la foto de los 8,0 y de
	# que la prueba mate al jefe a los 8,05)
	await get_tree().create_timer(0.6, false).timeout
	var sin_fuego: int = vida_antes - jefa.vida
	print("Bombero inmune al fuego: lanzallamas -%d, molotov -%d, charco de fuego (0,6 s) -%d | un golpe de 10: -%d" % [
		sin_lanzallamas, sin_molotov, sin_fuego, golpe])
	jefa.mirada = (johnny.position - jefa.position).normalized()
	jefa.lanzar_bolas(johnny)
	jefa.lanzar_molotovs(johnny)
	var molotovs := 0
	for n in jefa.get_parent().get_children():
		if n.get("tipo") == "molotov_jefe":
			molotovs += 1
	print("Bombero: bolas de fuego en el aire: %d | molotovs: %d" % [get_tree().get_nodes_in_group("balas_zombi").size(), molotovs])


# El cocinero, para la foto del jefe: un charco de aceite debajo de él (no le quema) y otro debajo de Johnny,
# unos cuchillos ya clavados, la lluvia marcando el suelo y el abanico recién lanzado
func probar_cocinero() -> void:
	var antes_johnny: int = johnny.vida
	# que nadie le dispare mientras tanto (ni Johnny solo, ni el superviviente que le acompaña): así se ve lo que
	# le quita su aceite
	var modo: String = johnny.modo
	johnny.modo = "quieto"
	for a in get_tree().get_nodes_in_group("aliados"):
		a.process_mode = Node.PROCESS_MODE_DISABLED
	for donde in [jefa.position, johnny.position]:
		var charco: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
		charco.tipo = "hirviendo"
		charco.dueno = jefa
		charco.position = donde
		mapa.cosas.add_child(charco)
	for i in 3:
		var c := Cuchillo.new()
		c.modo = "cae"
		c.aviso = 0.05
		c.position = jefa.position.lerp(johnny.position, 0.5) + Vector2((i - 1) * 50.0, 50.0)
		mapa.cosas.add_child(c)
	jefa.lluvia(johnny)
	jefa.empezar("aviso_abanico", (johnny.position - jefa.position).angle())
	jefa.t = 0.3   # el aviso ya casi acabado: en la foto acaba de lanzar el abanico
	await get_tree().create_timer(0.1, false).timeout   # (las balas que ya volaban, que lleguen antes de contar)
	var antes_jefe: int = jefa.vida
	await get_tree().create_timer(0.19, false).timeout
	print("Cocinero: su aceite le quita %d (tiene que ser 0); a Johnny, %d | cuchillos: %d" % [antes_jefe - jefa.vida,
		antes_johnny - johnny.vida, get_tree().get_nodes_in_group("balas_zombi").size()])
	# tras la foto, se recoge todo y Johnny vuelve como estaba (si no, las pruebas de después le pillan herido)
	await get_tree().create_timer(0.1, false).timeout
	johnny.modo = modo
	for a in get_tree().get_nodes_in_group("aliados"):
		a.process_mode = Node.PROCESS_MODE_INHERIT
	for cosa in get_tree().get_nodes_in_group("balas_zombi") + get_tree().get_nodes_in_group("charcos"):
		cosa.queue_free()
	johnny.estados.clear()
	johnny.pisando.clear()
	johnny.vida = antes_johnny


# La azotea del centro comercial: Johnny llega por la escalera y sale el jefe (captura-azotea.png); la azotea entera,
# sin penumbra y desde lejos (captura-azotea-entera.png); y, quitado el jefe, la escalera de incendios abierta
# (captura-azotea-incendios.png)
func probar_azotea() -> void:
	nueva_planta(Planta.PLANTAS)
	await montar(0, puerta_de_tipo("llegada"), false)
	var s: Dictionary = planta.sitios[0]
	var tipos := {}
	for m in s.muebles:
		tipos[m.tipo] = tipos.get(m.tipo, 0) + 1
	print("Azotea: %d x %d | aparatos %s | manchas %d | restos %d | jefe: %s (%s)" % [s.ancho, s.alto, tipos,
		s.manchas.size(), mapa.restos.size(), planta.jefe, planta.el_jefe])
	johnny.position = mapa.puertas[0].llegada() + Vector2(200, 0)   # se aleja de la escalera: se cierra detrás
	await get_tree().create_timer(1.4).timeout
	Captura.foto("captura-azotea.png")
	print("  ha salido el jefe: %s | escalera de llegada %s | incendios %s | aviso: '%s'" % [jefa != null,
		"cerrada" if cerrada else "abierta", "abierta" if mapa.puertas[1].abierta else "cerrada", aviso.text])
	var camara: Camera2D = johnny.get_node("Camara")
	# el gerente, con Johnny delante, lanzándole los contratos (captura-gerente.png)
	if jefa and jefa.has_method("lanzar_contratos"):
		for i in 60:
			johnny.position = jefa.position + Vector2.from_angle(PI + randf_range(-0.8, 0.8)) * 300.0
			if mapa.zona_en(johnny.position) >= 0 and jefa.a_la_vista(johnny):   # sin aparatos en medio
				break
		camara.reset_smoothing()
		jefa.foto(johnny)
		await get_tree().create_timer(0.45).timeout
		Captura.foto("captura-gerente.png")
		print("  el gerente: vida %d/%d | barra: '%s' | contratos volando: %d" % [jefa.vida, jefa.vida_max,
			$Pantalla/Jefa/Nombre.text, get_tree().get_nodes_in_group("balas_zombi").size()])
		# el maletinazo, con Johnny pegado (captura-gerente-maletinazo.png)
		for i in 60:
			johnny.position = jefa.position + Vector2.from_angle(PI + randf_range(-0.5, 0.5)) * 115.0
			if mapa.zona_en(johnny.position) >= 0:
				break
		camara.reset_smoothing()
		for papel in get_tree().get_nodes_in_group("balas_zombi"):
			papel.queue_free()   # (que no le dé antes un contrato: luego Johnny es invulnerable un momento)
		johnny.invulnerable = 0.0
		var vida_johnny: int = johnny.vida
		jefa.empezar("aviso_maletinazo", (johnny.position - jefa.position).angle())
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-gerente-maletinazo.png")
		await get_tree().create_timer(0.4).timeout
		# y «¡A TRABAJAR!»: llegan dos dependientas y un vigilante (captura-gerente-trabajar.png)
		print("  maletinazo: a Johnny le ha quitado %d (con su escudo y sus mutaciones de la prueba)" % (vida_johnny - johnny.vida))
		var antes_zombis: int = jefa.secuaces()
		jefa.cambiar("a_trabajar")
		jefa.gritar("¡A TRABAJAR!", Color("#ffd23f"), 26)
		await get_tree().create_timer(0.9).timeout
		Captura.foto("captura-gerente-trabajar.png")
		print("  ¡A TRABAJAR!: han llegado %d" % (jefa.secuaces() - antes_zombis))
		await probar_mutado(camara)
	elif jefa and jefa.has_method("lanzar_probetas"):
		await probar_cientifico_jefe(camara)
	luz.alternar()
	johnny.position = Vector2(s.ancho / 2.0, s.alto / 2.0)
	camara.zoom = Vector2(0.66, 0.66)
	camara.reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-azotea-entera.png")
	camara.zoom = Vector2.ONE
	luz.alternar()
	# sin el jefe se abre la escalera de incendios. El gerente cae de verdad (el jefe final no saca mutaciones); la
	# portera (si aún no estuviera el gerente), quitada sin que caiga: así no salen las mutaciones
	var es_final := jefa != null and not final_de(planta.jefe).is_empty()
	if es_final:
		# que su página del dosier salga al caer (probar_historia ya la ha apuntado)
		Guardado.cambiar(func(g):
			g.paginas.erase("cc_recogida")
			g.paginas.erase("vd7_sujeto_cero"))
	if jefa:
		for z in get_tree().get_nodes_in_group("zombis"):
			if z != jefa:
				z.queue_free()   # (los empleados del gerente)
		if es_final:
			jefa.invulnerable = false
			jefa.recibir_golpe(99999, Vector2.ZERO)
		else:
			jefa.queue_free()
			$Pantalla/Jefa.hide()
	johnny.position = mapa.puertas[1].llegada() + Vector2(-90, 0)
	camara.reset_smoothing()
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-azotea-incendios.png")
	print("  sin el jefe: jefe muerto %s | incendios %s | aviso: '%s'" % [planta.jefa_muerta,
		"abierta" if mapa.puertas[1].abierta else "cerrada", aviso.text])
	if es_final:
		# al rato, su página del dosier (con el juego parado); al cerrarla, el helicóptero (captura-helicoptero.png)
		await get_tree().create_timer(1.3).timeout
		print("  al caer el gerente: página del dosier abierta %s | juego parado %s" % [menus.abierto == "pagina",
			get_tree().paused])
		menus.leida()
		var helipuerto: Vector2 = s.get("helipuerto", johnny.position)
		johnny.position = helipuerto + Vector2(-170, 150)
		camara.zoom = Vector2(0.8, 0.8)
		camara.reset_smoothing()
		await get_tree().create_timer(0.8 + Helicoptero.LLEGADA + 0.5).timeout
		Captura.foto("captura-helicoptero.png")
		var helis: Array = mapa.cosas.get_children().filter(func(n): return n is Helicoptero)
		print("  helicóptero de Velaria: %d | sobre el helipuerto %s | aviso: '%s'" % [helis.size(),
			not helis.is_empty() and helis[0].llegado and helis[0].position.distance_to(helipuerto) < 1.0, aviso.text])
		camara.zoom = Vector2.ONE
		print("  al caer el gerente, mutación: %s" % ("sí (¡no debería!)" if menus.abierto == "mutacion" else "no"))


# El científico jefe (el jefe final de los Apartamentos): las probetas (captura-cientifico.png), la cúpula a
# golpes hasta rompérsela (captura-cientifico-cupula.png), el suero a dos vecinos (captura-cientifico-suero.png), la
# jeringa a media vida (captura-cientifico-jeringa.png) y el cambio (captura-cientifico-muta.png); la criatura con
# las lenguas (captura-criatura.png), el puñetazo (captura-criatura-punetazo.png) y escupiendo fuego
# (captura-criatura-fuego.png). Lo que comprueba lo escribe en la terminal
func probar_cientifico_jefe(camara: Camera2D) -> void:
	var cerca := func(lejos: float, hacia := PI / 2.0) -> void:   # Johnny cerca de él, donde se pueda estar y a la vista
		for i in 60:
			johnny.position = jefa.position + Vector2.from_angle(hacia + randf_range(-0.6, 0.6)) * lejos
			if mapa.zona_en(johnny.position) >= 0 and jefa.a_la_vista(johnny):
				break
		camara.reset_smoothing()
	# las probetas, recién tiradas
	cerca.call(300.0, PI)
	jefa.foto(johnny)
	await get_tree().create_timer(0.35).timeout
	Captura.foto("captura-cientifico.png")
	var en_el_aire := jefa.get_parent().get_children().filter(func(n): return str(n.get("tipo")).begins_with("probeta")).size()
	print("  el científico: vida %d/%d | barra: '%s' | probetas en el aire: %d | estado %s" % [jefa.vida, jefa.vida_max,
		$Pantalla/Jefa/Nombre.text, en_el_aire, jefa.estado])
	await get_tree().create_timer(1.3).timeout
	var charcos: Array = jefa.get_parent().get_children().filter(func(n): return n.get("tipo") in ["acido", "veneno", "aceite"])
	print("  al caer: charcos %s" % [charcos.map(func(c): return c.tipo)])
	# la cúpula: se mete y Johnny le da hasta rompérsela (los golpes se los lleva ella, con su barra azul)
	jefa.subir_cupula()
	await get_tree().create_timer(0.6).timeout
	var vida_antes: int = jefa.vida
	jefa.recibir_golpe(60, Vector2.RIGHT * 300.0)
	await get_tree().create_timer(0.1).timeout
	Captura.foto("captura-cientifico-cupula.png")
	print("  cúpula: %d/%d tras un golpe de 60 | a él le ha quitado %d | barra azul visible %s" % [jefa.cupula,
		jefa.CUPULA_VIDA, vida_antes - jefa.vida, armadura_jefe().visible])
	jefa.recibir_golpe(200, Vector2.RIGHT * 300.0)
	print("  otro de 200: cúpula %d | estado %s | vida %d" % [jefa.cupula, jefa.estado, jefa.vida])
	# el suero: dos vecinos al lado, inyectados
	var vecinos := []
	for i in 2:
		vecinos.append(meter_zombi("normal", jefa.position + Vector2(130.0 * (i * 2 - 1), 70.0)))
	await get_tree().physics_frame
	# (inyecta a los tres más cercanos: puede que a alguno de los sujetos que ya ha llamado él, en vez de a estos)
	var antes := vecinos.map(func(z): return [z.vida_max, int(z.velocidad), z.dano])
	jefa.cambiar("suero", {"hecho": true})
	jefa.inyectar()
	await get_tree().create_timer(0.15).timeout
	Captura.foto("captura-cientifico-suero.png")
	var con_suero: Array = get_tree().get_nodes_in_group("zombis").filter(func(z): return z.has_meta("suero"))
	print("  suero: un vecino normal (vida máx, velocidad, daño) %s | inyectados %d: %s" % [antes[0], con_suero.size(),
		con_suero.map(func(z): return [z.vida_max, int(z.velocidad), z.dano])])
	await get_tree().create_timer(1.1).timeout
	# a media vida: la jeringa y el cambio
	jefa.andar(5.0)
	cerca.call(190.0, PI)
	jefa.recibir_golpe(int(jefa.vida - jefa.vida_max * 0.5), Vector2.ZERO)
	await get_tree().create_timer(1.6).timeout
	Captura.foto("captura-cientifico-jeringa.png")
	print("  a media vida: %s (fotograma %d) | vida %d/%d | invulnerable %s" % [jefa.estado, jefa.sprite.frame,
		jefa.vida, jefa.vida_max, jefa.invulnerable])
	for i in 300:
		if jefa.mutado:
			break
		await get_tree().physics_frame
	await get_tree().create_timer(0.12).timeout
	Captura.foto("captura-cientifico-muta.png")
	while jefa.estado == "mutar":
		await get_tree().physics_frame
	print("  la criatura: %s | dibujo %s | radio %d | vida %d/%d | barra: '%s'" % [jefa.estado,
		jefa.sprite.sprite_frames.resource_path.get_file(), jefa.radio, jefa.vida, jefa.vida_max, $Pantalla/Jefa/Nombre.text])
	# las lenguas, recién soltadas
	cerca.call(200.0, 0.0)
	johnny.invulnerable = 0.0
	var vida_johnny: int = johnny.vida
	jefa.foto(johnny)
	await get_tree().create_timer(0.14).timeout
	Captura.foto("captura-criatura.png")
	print("  lenguas: %s | a Johnny le han quitado %d" % [jefa.estado, vida_johnny - johnny.vida])
	# el puñetazo: el círculo rojo y la onda
	await get_tree().create_timer(0.5).timeout
	cerca.call(150.0, 0.0)
	johnny.invulnerable = 0.0
	vida_johnny = johnny.vida
	jefa.empezar("aviso_punetazo", (johnny.position - jefa.position).angle())
	jefa.t = jefa.AVISO_PUNETAZO - 0.3
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-criatura-punetazo.png")
	await get_tree().create_timer(0.5).timeout
	print("  puñetazo: %s | a Johnny le ha quitado %d" % [jefa.estado, vida_johnny - johnny.vida])
	# y escupe fuego
	await get_tree().create_timer(0.5).timeout
	cerca.call(380.0, 0.0)
	jefa.empezar("aviso_fuego", (johnny.position - jefa.position).angle())
	jefa.t = jefa.AVISO_FUEGO - 0.05
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-criatura-fuego.png")
	print("  fuego: %s | bolas en el aire %d" % [jefa.estado, get_tree().get_nodes_in_group("balas_zombi").size()])
	for z in vecinos:
		if is_instance_valid(z):
			z.queue_free()


# El gerente, a media vida, se pincha VD-7 (captura-gerente-jeringa.png) y muta con un fogonazo
# (captura-gerente-muta.png); el mutado, con los latigazos (captura-mutado.png) y avisando la embestida
# (captura-mutado-embestida.png)
func probar_mutado(camara: Camera2D) -> void:
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != jefa:
			z.queue_free()   # (los empleados del gerente)
	for papel in get_tree().get_nodes_in_group("balas_zombi"):
		papel.queue_free()
	var cerca := func(lejos: float, hacia := PI / 2.0) -> void:   # Johnny cerca de él, donde se pueda estar y a la vista
		for i in 60:
			johnny.position = jefa.position + Vector2.from_angle(hacia + randf_range(-0.6, 0.6)) * lejos
			if mapa.zona_en(johnny.position) >= 0 and jefa.a_la_vista(johnny):
				break
		camara.reset_smoothing()
	cerca.call(170.0, PI)   # (a un lado: así se le ve entero, con la jeringa)
	jefa.andar(5.0)
	jefa.recibir_golpe(int(jefa.vida - jefa.vida_max * 0.5), Vector2.ZERO)
	await get_tree().create_timer(1.5).timeout
	Captura.foto("captura-gerente-jeringa.png")
	print("  a media vida: %s (fotograma %d) | vida %d/%d | invulnerable %s" % [jefa.estado, jefa.sprite.frame,
		jefa.vida, jefa.vida_max, jefa.invulnerable])
	for i in 300:
		if jefa.mutado:
			break
		await get_tree().physics_frame
	await get_tree().create_timer(0.12).timeout
	Captura.foto("captura-gerente-muta.png")
	while jefa.estado == "mutar":
		await get_tree().physics_frame
	print("  mutado: %s | dibujo %s | radio %d | vida %d/%d | barra: '%s'" % [jefa.estado,
		jefa.sprite.sprite_frames.resource_path.get_file(), jefa.radio, jefa.vida, jefa.vida_max, $Pantalla/Jefa/Nombre.text])
	# los latigazos, recién soltados
	cerca.call(200.0, 0.0)
	johnny.invulnerable = 0.0
	var vida_johnny: int = johnny.vida
	jefa.foto(johnny)
	await get_tree().create_timer(0.14).timeout
	Captura.foto("captura-mutado.png")
	print("  latigazos: %s | a Johnny le han quitado %d" % [jefa.estado, vida_johnny - johnny.vida])
	# y la embestida: la franja roja, y luego sale corriendo
	await get_tree().create_timer(0.5).timeout
	cerca.call(400.0, 0.0)
	jefa.empezar("aviso_embestida", (johnny.position - jefa.position).angle())
	await get_tree().create_timer(0.55).timeout
	Captura.foto("captura-mutado-embestida.png")
	var estados := []
	for i in 30:
		await get_tree().create_timer(0.05).timeout
		if estados.is_empty() or estados[-1] != jefa.estado:
			estados.append(jefa.estado)
	print("  embestida: %s" % " → ".join(estados))
