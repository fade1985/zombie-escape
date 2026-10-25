# Prueba de las skins de Johnny (--skins). Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_armas.gd"


# Con "--captura --skins": las skins de Johnny (skins.gd). En la sala de mantenimiento, sin ninguna skin:
#   - sin desbloquear, la taquilla no deja ponérsela (y dice cómo se consigue; captura-skins-taquilla-sin.png)
#   - la portera cae y desbloquea el portero (se guarda; no se pone sola), con su aviso (captura-skins-desbloqueo.png);
#     una segunda vez ya no es nueva. Y el Glotón, el glotón (captura-skins-desbloqueo-gloton.png), el Gymbro, el
#     gymbro (captura-skins-desbloqueo-gymbro.png), y el jefe de bomberos, el bombero (captura-skins-desbloqueo-bombero.png)
#   - la taquilla: se abre al arrimarse, enseña el portero y se elige (captura-skins-taquilla.png); Johnny cambia de
#     hoja en el acto y se guarda; uno que no existe no se puede; lo mismo con el glotón, el gymbro y el bombero
#     (captura-skins-taquilla-<id>.png); la tecla Z da la vuelta sin guardar
#   - la cara en las 8 direcciones (con la fregona) y con las otras cinco armas, mirando al sur, al lado del
#     conserje de siempre (captura-skins-caras.png, el portero; captura-skins-caras-<id>.png, las demás); y Johnny
#     andando con la skin, que sigue con su paso
#   - el daño de la fregona: × 4 con el portero (con el bate, igual), contado y con un golpe de verdad
#   - el daño cuerpo a cuerpo: × 3 con el gymbro con todas (la fregona, el bate y el cuchillo) y las de fuego, igual;
#     contado y con un golpe de verdad (con el bate)
#   - el daño de las armas que queman: × 3 con el bombero (el lanzallamas y el molotov) y las demás, igual; contado y de verdad, con el golpe, el disparo o la llama y lo que
#     sigue ardiendo el zombi (y un molotov de verdad); con la pistola y el bate, igual
#   - el bombero, inmune al fuego: el fuego del suelo, un charco de molotov, los molotovs, el cono y las bolas del jefe
#     de bomberos, de verdad: sin la skin Johnny pierde vida y sigue ardiendo; con ella, nada; el hachazo, sí le quita
#   - el poder del glotón: un zombi normal que le da un zarpazo de verdad muere; el Gymbro (con su armadura) pierde
#     un 10 % de su vida con un golpe suyo y con una pesa suya, y la armadura no se lo para; sin la skin, nada; y nada
#     si Johnny es invulnerable o si el daño no es de nadie
# Cada línea dice lo esperado. Deja el guardado de la prueba sin skins y se cierra
func probar_skins() -> void:
	set_process(false)
	Guardado.cambiar(func(g): g.skins = []; g.skin = "")
	johnny.vestir("")
	johnny.coger("fregona")
	print("Al empezar: skins %s · puesta «%s» · Johnny lleva «%s» (esperado: [], «», «»)" % [Skins.tenidas(),
		Skins.puesta(), johnny.skin])
	# sin desbloquear: la taquilla no deja
	johnny.position = Vector2(mapa.TAQUILLA_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	if taquilla.abierta():
		var puesto: bool = taquilla.elegir("portero")
		# (la foto con todas en «???»: que su pista quepa en la carta, también la larga del jefe de bomberos)
		await get_tree().create_timer(0.2).timeout
		Captura.foto("captura-skins-taquilla-sin.png")
		print("Sin desbloquear: ¿puesto? %s (esperado: false) · Johnny lleva «%s» · dice «%s»" % [
			puesto, johnny.skin, taquilla.info.text])
		taquilla.cerrar()
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout

	# ── El desbloqueo: cae la portera ──
	var portera: Node2D = meter_zombi("portera", johnny.position + Vector2(220, 0))
	await get_tree().create_timer(0.2).timeout
	for i in 20:
		if portera.estado == "muerto":
			break
		portera.recibir_golpe(99999, Vector2.ZERO)
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-skins-desbloqueo.png")
	print("Cae la portera (muerta: %s): skins %s · puesta «%s» (esperado: [\"portero\"], «»: no se pone sola)" % [
		portera.estado == "muerto", Skins.tenidas(), Skins.puesta()])
	print("Otra vez: ¿nueva? %s (esperado: false) · skins %s" % [Skins.desbloquear("portero"), Skins.tenidas()])
	# las mutaciones que salen al caer la portera: se elige una y sigue
	await get_tree().create_timer(2.0).timeout
	if menus.abierto == "mutacion":
		menus.elegir("insensible")
	get_tree().paused = false
	$Pantalla/Jefa.hide()
	# y el Glotón (le pega un aliado: que su ácido no salpique a Johnny)
	var gloton: Node2D = meter_zombi("gloton", johnny.position + Vector2(220, 0))
	await get_tree().create_timer(0.2).timeout
	for i in 20:
		if gloton.estado == "muerto":
			break
		gloton.recibir_golpe(99999, Vector2.ZERO, false, true)
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-skins-desbloqueo-gloton.png")
	print("Cae el Glotón (muerto: %s): skins %s · puesta «%s» (esperado: [\"portero\", \"gloton\"], «»)" % [
		gloton.estado == "muerto", Skins.tenidas(), Skins.puesta()])
	print("Otra vez: ¿nueva? %s (esperado: false) · un jefe sin skin (el cocinero): «%s» (esperado: «»)" % [
		Skins.desbloquear("gloton"), Skins.de_jefe("cocinero")])
	await get_tree().create_timer(2.0).timeout
	if menus.abierto == "mutacion":
		menus.elegir("canibal")
	get_tree().paused = false
	$Pantalla/Jefa.hide()
	# y el Gymbro
	var jefe_gymbro: Node2D = meter_zombi("gymbro", johnny.position + Vector2(220, 0))
	await get_tree().create_timer(0.2).timeout
	for i in 60:
		if jefe_gymbro.estado == "muerto":
			break
		jefe_gymbro.recibir_golpe(99999, Vector2.ZERO, false, true)
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-skins-desbloqueo-gymbro.png")
	print("Cae el Gymbro (muerto: %s): skins %s · puesta «%s» (esperado: [\"portero\", \"gloton\", \"gymbro\"], «»)" % [
		jefe_gymbro.estado == "muerto", Skins.tenidas(), Skins.puesta()])
	print("Otra vez: ¿nueva? %s (esperado: false)" % Skins.desbloquear("gymbro"))
	await get_tree().create_timer(2.0).timeout
	if menus.abierto == "mutacion":
		menus.elegir("insensible")
	get_tree().paused = false
	$Pantalla/Jefa.hide()
	# y el jefe de bomberos (le pega un aliado, como al Glotón)
	var jefe_bombero: Node2D = meter_zombi("bombero", johnny.position + Vector2(220, 0))
	await get_tree().create_timer(0.2).timeout
	for i in 60:
		if jefe_bombero.estado == "muerto":
			break
		jefe_bombero.recibir_golpe(99999, Vector2.ZERO, false, true)
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-skins-desbloqueo-bombero.png")
	print("Cae el jefe de bomberos (muerto: %s): skins %s · puesta «%s» (esperado: [\"portero\", \"gloton\", \"gymbro\", \"bombero\"], «»)" % [
		jefe_bombero.estado == "muerto", Skins.tenidas(), Skins.puesta()])
	print("Otra vez: ¿nueva? %s (esperado: false)" % Skins.desbloquear("bombero"))
	await get_tree().create_timer(2.0).timeout
	if menus.abierto == "mutacion":
		menus.elegir("canibal")
	get_tree().paused = false
	$Pantalla/Jefa.hide()
	# (lo que haya dejado ardiendo al caer: fuera)
	for c in get_tree().get_nodes_in_group("charcos"):
		c.queue_free()

	# ── La taquilla ──
	johnny.position = Vector2(mapa.TAQUILLA_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Taquilla: abierta al arrimarse %s · juego en pausa %s (esperado: true, true)" % [taquilla.abierta(), get_tree().paused])
	if taquilla.abierta():
		taquilla.marcar("portero")
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-skins-taquilla.png")
		taquilla.elegir("portero")
		print("Elegido el portero: Johnny lleva «%s» · guardado «%s» · su hoja %s · dice «%s»" % [johnny.skin,
			Guardado.cargar().skin, johnny.sprite.sprite_frames.resource_path.get_file(), taquilla.info.text])
		print("Uno que no existe: ¿puesto? %s (esperado: false) · Johnny sigue con «%s»" % [taquilla.elegir("astronauta"),
			johnny.skin])
		# (las fotos del glotón, del gymbro y del bombero, ya puestas: que su efecto quepa también con «Puesta»)
		taquilla.marcar("gloton")
		taquilla.elegir("gloton")
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-skins-taquilla-gloton.png")
		print("Elegido el glotón: Johnny lleva «%s» · guardado «%s» · su hoja %s · dice «%s»" % [johnny.skin,
			Guardado.cargar().skin, johnny.sprite.sprite_frames.resource_path.get_file(), taquilla.info.text])
		taquilla.marcar("gymbro")
		taquilla.elegir("gymbro")
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-skins-taquilla-gymbro.png")
		print("Elegido el gymbro: Johnny lleva «%s» · guardado «%s» · su hoja %s · dice «%s»" % [johnny.skin,
			Guardado.cargar().skin, johnny.sprite.sprite_frames.resource_path.get_file(), taquilla.info.text])
		taquilla.marcar("bombero")
		taquilla.elegir("bombero")
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-skins-taquilla-bombero.png")
		print("Elegido el bombero: Johnny lleva «%s» · guardado «%s» · su hoja %s · dice «%s»" % [johnny.skin,
			Guardado.cargar().skin, johnny.sprite.sprite_frames.resource_path.get_file(), taquilla.info.text])
		taquilla.cerrar()
	print("Taquilla cerrada: juego en pausa %s (esperado: false)" % get_tree().paused)
	var vuelta := []
	var s := ""
	for i in Skins.LISTA.size() + 1:
		s = Skins.siguiente(s)
		vuelta.append(Skins.nombre(s))
	print("Tecla Z: %s (esperado: El portero > El glotón > El gymbro > El bombero > Conserje)" % " > ".join(vuelta))

	# ── La cara: las 8 direcciones con la fregona, y las otras armas mirando al sur (una foto por skin) ──
	johnny.position = Vector2(690, 330)
	johnny.get_node("Camara").reset_smoothing()
	johnny.hide()
	var dirs := ["s", "se", "e", "ne", "n", "no", "o", "so"]
	var armas := ["fregona", "bate", "cuchillo", "pistola", "escopeta", "mp5"]
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		var copias := []
		var hojas_bien := 0
		for i in dirs.size() + armas.size() + 1:
			var arma: String = "fregona" if i < dirs.size() else ("fregona" if i == dirs.size() else armas[i - dirs.size() - 1])
			var w: Dictionary = Armas.datos(arma)
			var copia := Node2D.new()   # los pies, como el dibujo de Johnny (sprite.position)
			if i < dirs.size():
				copia.position = johnny.position + Vector2(-350 + 100 * i, -40)
			else:
				copia.position = johnny.position + Vector2(-350 + 100 * (i - dirs.size()), 110)
			var dibujo := AnimatedSprite2D.new()
			# el último de la segunda fila, el conserje de siempre, para comparar
			dibujo.sprite_frames = Skins.hoja(w.hoja, "" if i == dirs.size() else skin)
			if dibujo.sprite_frames.resource_path.ends_with("-%s.tres" % skin):
				hojas_bien += 1
			dibujo.centered = false
			dibujo.offset = -w.pies
			dibujo.scale = Vector2(2, 2)
			dibujo.material = johnny.sprite.material.duplicate()
			copia.add_child(dibujo)
			dibujo.play("reposo_" + (dirs[i] if i < dirs.size() else "s"))
			mapa.cosas.add_child(copia)
			copias.append(copia)
		await get_tree().create_timer(0.6).timeout
		Captura.foto("captura-skins-caras.png" if skin == "portero" else "captura-skins-caras-%s.png" % skin)
		print("Foto caras: arriba %s en %s; abajo el conserje y %s con %s · sus hojas %d de %d (esperado: 14 de 14)" % [
			Skins.nombre(skin), ", ".join(dirs), Skins.nombre(skin), ", ".join(armas), hojas_bien, dirs.size() + armas.size()])
		for c in copias:
			c.queue_free()
	johnny.show()
	# andando: ponerse la skin no le corta el paso (sigue con la misma animación, en el mismo dibujo)
	johnny.vestir("")
	johnny.sprite.play("andar_e")
	johnny.sprite.set_frame_and_progress(3, 0.5)
	johnny.vestir("portero")
	print("Andando: después de ponérsela «%s», dibujo %d, en marcha %s (esperado: andar_e, 3, true) · hoja %s" % [
		johnny.sprite.animation, johnny.sprite.frame, johnny.sprite.is_playing(),
		johnny.sprite.sprite_frames.resource_path.get_file()])

	# ── El daño de la fregona ──
	johnny.coger("fregona")
	johnny.vestir("")
	var de_siempre: float = johnny.arma().dano
	johnny.vestir("portero")
	var con_portero: float = johnny.arma().dano
	johnny.coger("bate")
	var bate_portero: float = johnny.arma().dano
	johnny.vestir("")
	var bate_siempre: float = johnny.arma().dano
	print("Daño de la fregona: conserje %.1f · portero %.1f (× %.1f; esperado: × 4) · bate: conserje %.1f, portero %.1f (esperado: igual)" % [
		de_siempre, con_portero, con_portero / de_siempre, bate_siempre, bate_portero])
	# un golpe de verdad, sin críticos, a un zombi delante
	johnny.coger("fregona")
	var critico: float = johnny.stats.critico
	johnny.stats.critico = 0.0
	var quitado := {}
	for skin in ["", "portero"]:
		johnny.vestir(skin)
		var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(40, 0))
		zombi.vida = 500
		await get_tree().process_frame
		var vida_antes: float = zombi.vida
		johnny.golpear(0.0)
		quitado[skin] = vida_antes - zombi.vida
		zombi.queue_free()
		await get_tree().process_frame
	johnny.stats.critico = critico
	print("Un golpe de fregona a un zombi: conserje le quita %d · portero %d (esperado: el cuádruple)" % [
		quitado[""], quitado["portero"]])

	# ── El daño cuerpo a cuerpo del gymbro: × 3 con todas; las de fuego, igual ──
	var cuentas := []
	for arma in ["fregona", "bate", "cuchillo", "pistola", "escopeta", "mp5"]:
		johnny.coger(arma)
		johnny.vestir("")
		var siempre: float = johnny.arma().dano
		johnny.vestir("gymbro")
		cuentas.append("%s × %.1f" % [Objetos.nombre(arma), johnny.arma().dano / siempre])
	print("Daño con el gymbro: %s (esperado: × 3 las tres primeras, × 1 las de fuego)" % " · ".join(cuentas))
	# golpes de verdad, sin críticos, con el bate
	johnny.stats.critico = 0.0
	var golpes := []
	for arma in ["bate"]:
		johnny.coger(arma)
		var quita := {}
		for skin in ["", "gymbro"]:
			johnny.vestir(skin)
			var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(40, 0))
			zombi.vida = 500
			await get_tree().process_frame
			var vida_antes: float = zombi.vida
			johnny.golpear(0.0)
			quita[skin] = vida_antes - zombi.vida
			zombi.queue_free()
			await get_tree().process_frame
		golpes.append("%s: conserje %d, gymbro %d" % [Objetos.nombre(arma), quita[""], quita["gymbro"]])
	johnny.stats.critico = critico
	print("Un golpe a un zombi: %s (esperado: el triple)" % " · ".join(golpes))
	johnny.coger("fregona")
	johnny.coger("pistola")
	johnny.vestir("")

	await probar_skin_bombero()

	# ── El poder del glotón: quien le hace daño lo paga ──
	var modo: String = johnny.modo
	johnny.modo = "quieto"   # que Johnny no pegue solo
	var a_punto := func() -> void:   # con toda la vida y sin el parpadeo de invulnerable, para que el golpe entre
		johnny.vida = johnny.stats.vida_max
		johnny.invulnerable = 0.0
	for skin in ["", "gloton"]:
		johnny.vestir(skin)
		# un zombi normal, al lado: le da un zarpazo de verdad
		# (se sabe que le ha dado porque se queda un rato invulnerable: Caníbal le cura al morir el zombi)
		var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(46, 0))
		a_punto.call()
		for i in 300:
			if johnny.invulnerable > 0.0:
				break
			await get_tree().physics_frame
		await get_tree().process_frame
		var pego: bool = johnny.invulnerable > 0.0
		var muerto: bool = not is_instance_valid(zombi) or zombi.estado == "muerto"
		if is_instance_valid(zombi):
			zombi.queue_free()   # (que no le siga pegando)
		# el Gymbro, quieto y con su armadura: un golpe suyo y una pesa suya que le cae encima
		var gymbro: Node2D = meter_zombi("gymbro", johnny.position + Vector2(200, 0))
		await get_tree().process_frame
		gymbro.process_mode = Node.PROCESS_MODE_DISABLED
		gymbro.armadura_max = int(gymbro.vida_max * gymbro.ARMADURA)
		gymbro.armadura = gymbro.armadura_max
		var v0: int = gymbro.vida
		a_punto.call()
		johnny.recibir_dano(20, gymbro)
		var v1: int = gymbro.vida
		a_punto.call()
		var pesa := Pesa.new()
		pesa.dueno = gymbro
		pesa.desde = johnny.global_position + Vector2(80, 0)
		pesa.hasta = johnny.global_position
		pesa.vuelo = 0.2
		gymbro.get_parent().add_child(pesa)
		await get_tree().create_timer(0.5).timeout
		var v2: int = gymbro.vida
		var diez := ceili(gymbro.vida_max * 0.1)
		print("Poder del glotón, con «%s»: el zombi le pega %s y muere %s · el Gymbro (vida %d) pierde %d con su golpe y %d con su pesa, armadura %d de %d (esperado: %s)" % [
			skin, pego, muerto, gymbro.vida_max, v0 - v1, v1 - v2, gymbro.armadura, gymbro.armadura_max,
			"true, true · %d y %d, armadura entera" % [diez, diez] if skin == "gloton" else "true, false · 0 y 0, armadura entera"])
		gymbro.queue_free()
		await get_tree().process_frame
	# con el glotón, invulnerable o sin dueño: nada
	var otro: Node2D = meter_zombi("normal", johnny.position + Vector2(300, 0))
	await get_tree().process_frame
	johnny.invulnerable = 1.0
	johnny.recibir_dano(10, otro)
	var tras_invulnerable: bool = otro.estado != "muerto"
	a_punto.call()
	johnny.recibir_dano(10)
	print("Poder del glotón, invulnerable: el zombi sigue vivo %s · sin dueño (una explosión): Johnny pierde %d y nada más (esperado: true, 10 o menos)" % [
		tras_invulnerable, johnny.stats.vida_max - johnny.vida])
	otro.queue_free()
	johnny.modo = modo
	Guardado.cambiar(func(g): g.skins = []; g.skin = "")
	get_tree().quit()


# La skin del bombero (skins.gd), dentro de probar_skins(). Johnny en el despacho, sin pegar ni disparar solo y sin
# críticos:
#   - el daño contado: × 3 las armas que queman (el lanzallamas, y lo que quema el molotov) y × 1 las seis de siempre
#   - de verdad, a un zombi quieto delante: el disparo o la llama (0,3 s) y lo que sigue ardiendo después, sin
#     la skin y con ella (con el bate y la pistola, igual y sin arder); y un molotov de verdad
#   - inmune al fuego, de verdad, sin la skin y con ella: el fuego del suelo (lo que hace cada paso al pisarlo) y lo
#     que sigue ardiendo al salir, un charco de molotov a sus pies (con la skin, captura-skins-bombero-fuego.png), los
#     molotovs, el cono y las bolas de fuego del jefe de bomberos; y su hachazo, que sí le quita
func probar_skin_bombero() -> void:
	var modo: String = johnny.modo
	johnny.modo = "quieto"   # que Johnny no pegue ni dispare solo
	var critico: float = johnny.stats.critico
	johnny.stats.critico = 0.0
	johnny.direccion = "e"
	# ── contado ──
	var cuentas := []
	for arma in ["fregona", "bate", "cuchillo", "pistola", "escopeta", "mp5", "lanzallamas"]:
		johnny.coger(arma)
		johnny.vestir("")
		var siempre: float = johnny.arma().dano
		johnny.vestir("bombero")
		cuentas.append("%s × %.1f" % [Objetos.nombre(arma), johnny.arma().dano / siempre])
	print("Daño con el bombero: %s (esperado: × 1 las seis de siempre, × 3 la que quema)" % " · ".join(cuentas))
	var lanzados := []
	for tipo in ["molotov"]:
		var cuanto := {}
		for skin in ["", "bombero"]:
			johnny.vestir(skin)
			lanzables.cantidades.molotov = maxi(lanzables.cantidades.molotov, 1)
			lanzables.tipo = tipo
			lanzables.lanzar(johnny.global_position + Vector2(-200, 100))
			var p: Node = johnny.get_parent().get_children().filter(func(n): return n.get("hasta") != null and n.get("dano_lanzar") != null).back()
			cuanto[skin] = p.dano_lanzar
			p.queue_free()   # (que no caiga: solo se mira lo que quemará)
		lanzados.append("%s × %.1f" % [lanzables.nombre(tipo), cuanto.bombero / cuanto[""]])
	lanzables.tipo = "molotov"
	print("Lo que quema lo que se lanza, con el bombero: %s (esperado: × 3)" % " · ".join(lanzados))

	# ── de verdad: el golpe o el disparo, y lo que sigue ardiendo el zombi ──
	var de_verdad := []
	for arma in ["lanzallamas", "bate", "pistola"]:
		johnny.coger(arma)
		var cuerpo: bool = Armas.datos(arma).tipo == "cuerpo"
		var quita := {}
		# el lanzallamas, más a la izquierda: a 46 por la derecha está el tabique del taller, y la llama no lo cruza (las
		# balas y las gotas sí llegan: nacen en la boca, que ya está al otro lado)
		var sitio: Vector2 = johnny.position
		if Armas.datos(arma).has("deposito"):
			johnny.position.x -= 200.0
		for skin in ["", "bombero"]:
			johnny.vestir(skin)
			johnny.balas = 50
			var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(50 if cuerpo else 80, 0))
			zombi.vida = 2000
			await get_tree().process_frame
			zombi.aturdido = 5.0   # quieto, delante
			var vida_antes: int = zombi.vida
			johnny.direccion = "e"
			if cuerpo:
				johnny.golpear(0.0)
			elif Armas.datos(arma).has("deposito"):
				# el lanzallamas: 0,3 s de llama, dos pellizcos (el primero, al salir), igual con la skin y sin ella
				johnny.deposito = 8.0
				johnny.llamarada.tick_t = Llamarada.TICK
				await echar_fuego(0.0, 0.3)
				await get_tree().create_timer(0.1).timeout
			else:
				johnny.disparar(0.0)
				await get_tree().create_timer(0.3).timeout   # (lo que tarda en llegar)
			var golpe: int = vida_antes - zombi.vida
			zombi.position = johnny.position + Vector2(220, 0)   # lejos mientras arde (pegado a Johnny, algo le pellizca)
			await get_tree().create_timer(2.6).timeout
			quita[skin] = [golpe, vida_antes - zombi.vida - golpe]
			zombi.queue_free()
			await get_tree().process_frame
		johnny.position = sitio
		de_verdad.append("%s: golpe %d → %d, ardiendo %d → %d" % [Objetos.nombre(arma), quita[""][0], quita.bombero[0],
			quita[""][1], quita.bombero[1]])
	print("De verdad a un zombi, sin la skin → con el bombero: %s (esperado: el triple el que quema, redondeando cada pellizco; el bate y la pistola, igual y sin arder)" % " · ".join(de_verdad))
	var molotov := {}
	for skin in ["", "bombero"]:
		johnny.vestir(skin)
		var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(170, 0))
		zombi.vida = 2000
		await get_tree().process_frame
		zombi.aturdido = 6.0
		lanzables.cantidades.molotov = maxi(lanzables.cantidades.molotov, 1)
		lanzables.tipo = "molotov"
		var vida_antes: int = zombi.vida
		lanzables.lanzar(zombi.global_position)
		await get_tree().create_timer(3.0).timeout
		molotov[skin] = vida_antes - zombi.vida
		zombi.queue_free()
		for c in get_tree().get_nodes_in_group("charcos"):
			c.queue_free()
		await get_tree().process_frame
	print("Un molotov de verdad a un zombi quieto: en 3 s le quita %d sin la skin y %d con el bombero (× %.1f; esperado: × 3, más o menos)" % [
		molotov[""], molotov.bombero, molotov.bombero / maxf(1.0, molotov[""])])

	# ── inmune al fuego (que los que le acompañan no le disparen al jefe) ──
	var aliados: Array = get_tree().get_nodes_in_group("aliados")
	for a in aliados:
		a.process_mode = Node.PROCESS_MODE_DISABLED
	var puesto: Vector2 = johnny.position
	var jefe: Node2D = meter_zombi("bombero", puesto + Vector2(-160, 0))   # (en el despacho: a la derecha está la pared)
	await get_tree().create_timer(0.2).timeout
	jefe.process_mode = Node.PROCESS_MODE_DISABLED   # quieto: lo que hace, se le manda
	$Pantalla/Jefa.hide()
	var a_punto := func() -> void:   # en su sitio, con toda la vida, sin parpadeo y sin arder
		johnny.position = puesto
		johnny.velocity = Vector2.ZERO
		johnny.vida = johnny.stats.vida_max
		johnny.invulnerable = 0.0
		johnny.estados.clear()
		johnny.estado_dano = 0.0
	var pierde := func() -> int:
		return johnny.stats.vida_max - johnny.vida
	for skin in ["", "bombero"]:
		johnny.vestir(skin)
		var r := {}
		# el fuego del suelo (la cocina, el cerco de la sala del jefe): lo que le hace a cada paso mientras lo pisa
		a_punto.call()
		for i in 60:
			johnny.pisar({"fuego": {"dps": Peligros.FUEGO.dps}})
			await get_tree().physics_frame
		r.suelo = pierde.call()
		r.ardiendo = johnny.estados.has("fuego")
		await get_tree().create_timer(1.0).timeout
		r.sigue = pierde.call() - r.suelo
		# un charco de fuego de molotov a sus pies
		a_punto.call()
		var charco: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
		charco.tipo = "fuego"
		charco.position = johnny.position
		johnny.get_parent().add_child(charco)
		await get_tree().create_timer(1.5).timeout
		if skin == "bombero":
			Captura.foto("captura-skins-bombero-fuego.png")
		r.charco = pierde.call()
		charco.queue_free()
		# los molotovs del jefe, encima (la botella y su fuego)
		a_punto.call()
		jefe.lanzar_molotovs(johnny)
		await get_tree().create_timer(1.8).timeout
		r.molotov = pierde.call()
		for c in get_tree().get_nodes_in_group("charcos"):
			c.queue_free()
		# su cono, 1 s apuntándole
		a_punto.call()
		var a: float = (johnny.global_position - jefe.global_position).angle()
		var puntas := []
		puntas.resize(jefe.RAYOS + 1)
		puntas.fill(150.0)
		for i in 60:
			jefe.quemar_cono(a, johnny, puntas)
			await get_tree().physics_frame
		r.cono = pierde.call()
		# sus bolas de fuego
		a_punto.call()
		jefe.mirada = (johnny.global_position - jefe.global_position).normalized()
		jefe.lanzar_bolas(johnny)
		await get_tree().create_timer(1.2).timeout
		r.bolas = pierde.call()
		# y su hachazo, de cerca
		a_punto.call()
		jefe.position = puesto + Vector2(-50, 0)
		jefe.mirada = Vector2.RIGHT
		jefe.dar_hachazo(johnny)
		r.hacha = pierde.call()
		jefe.position = puesto + Vector2(-160, 0)
		print("Inmune al fuego, con «%s»: pisando fuego 1 s pierde %d · ardiendo %s, y al salir %d más en 1 s · un charco de molotov 1,5 s, %d · los molotovs del jefe, %d · su cono 1 s, %d · sus bolas, %d · su hachazo, %d (esperado: %s)" % [
			skin, r.suelo, r.ardiendo, r.sigue, r.charco, r.molotov, r.cono, r.bolas, r.hacha,
			"0 · false, 0 · 0 · 0 · 0 · 0 · más de 0" if skin == "bombero" else "más de 0 en todo y ardiendo true"])
	a_punto.call()
	jefe.queue_free()
	for a in aliados:
		if is_instance_valid(a):
			a.process_mode = Node.PROCESS_MODE_INHERIT
	johnny.stats.critico = critico
	johnny.modo = modo
	johnny.coger("fregona")
	johnny.coger("pistola")
	johnny.vestir("")
	await get_tree().process_frame
