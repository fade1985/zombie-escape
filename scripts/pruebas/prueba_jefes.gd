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
	await get_tree().create_timer(0.2).timeout
	var rugidos: int = jefa.get_parent().get_children().filter(func(n): return n is EfectoSuelo and n.tipo == "rugido" and not n.de_calentar).size()
	print("Presentación, el rugido (M57): efectos %d (esperado: 1; 0 si entra escondido) · precalentado %s (esperado: true; false si escondido)" % [
		rugidos, EfectoSuelo.calentados.has("rugido")])
	Captura.foto("captura-presentacion-rugido.png")   # (las ondas del grito, a media salida)
	await get_tree().create_timer(0.3).timeout   # a 1,1 s de empezar la presentación
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


# Con "--captura --edificio centro --jefe modista --cambios": cuántas veces se cambia de maniquí la modista (M88) en
# 20 s normal y 20 s enfadada, con Johnny quieto (sin que pueda caer) y lejos de ella: si se le acerca, salta junto al
# maniquí más lejano, para que no lo tenga pegado (pegada a él no se cambia)
func probar_cambios() -> void:
	if not await ir_a_la_sala_del_jefe("modista"):
		return
	johnny.set_physics_process(false)   # quieto
	for f in [1, 2]:
		jefa.fase = f   # enfadada sin los maniquíes vivos: solo cuenta los cambios de sitio
		var cambios := 0
		var antes: String = jefa.estado
		for pasos in 1200:   # 20 s
			johnny.vida = johnny.stats.vida_max
			if jefa.global_position.distance_to(johnny.global_position) < 300.0:
				# se le ha acercado: Johnny salta junto al maniquí más lejos de ella (como si huyera)
				var lejos: Node2D = jefa.maniquies().reduce(func(x, m): return m if m.global_position.distance_to(
					jefa.global_position) > x.global_position.distance_to(jefa.global_position) else x)
				johnny.global_position = lejos.global_position + Vector2(0, 40)
			if jefa.estado == "ojos" and antes != "ojos":
				cambios += 1
			antes = jefa.estado
			await get_tree().physics_frame
		print("Modista · cambios de maniquí en 20 s (%s): %d · cada %.1f s, otra vez %d%%" % [
			"enfadada" if f == 2 else "normal", cambios, jefa.CAMBIOS[f - 1], int(jefa.OTRA_VEZ[f - 1] * 100)])


# Con "--captura --edificio centro --jefe modista --maniquies": los maniquíes vivos de la modista (M89) con sus
# animaciones de PixelLab. Con Johnny quieto (sin que pueda caer) y mirando al otro lado, para que anden. Fotos:
# despertando (captura-maniquies-despertar.png), andando a saltitos (-andar.png) y rompiéndose (-romper.png) y rotos (-rotos.png)
func probar_maniquies() -> void:
	if not await ir_a_la_sala_del_jefe("modista"):
		return
	johnny.set_physics_process(false)   # quieto
	jefa.set_physics_process(false)     # la modista, quieta: solo se miran los maniquíes
	jefa.despertar_maniquies(johnny)
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-maniquies-despertar.png")
	# Johnny, de espaldas al maniquí más cercano: los maniquíes andan
	var cerca: Node2D = jefa.vivos.reduce(func(x, m): return m if m.global_position.distance_to(johnny.global_position) 		< x.global_position.distance_to(johnny.global_position) else x)
	var hacia: Vector2 = johnny.global_position - cerca.global_position
	johnny.direccion = johnny.DIRS[posmod(roundi(hacia.angle() / (PI / 4.0)), 8)]
	for i in 90:
		johnny.vida = johnny.stats.vida_max
		await get_tree().physics_frame
	print("Maniquíes: %s" % [jefa.vivos.map(func(m): return "%s, fotograma %d" % [m.estado, m.sprite.frame])])
	Captura.foto("captura-maniquies-andar.png")
	for m in jefa.vivos:
		m.recibir_golpe(999, Vector2.RIGHT)
	await get_tree().create_timer(0.4, false).timeout
	Captura.foto("captura-maniquies-romper.png")
	await get_tree().create_timer(1.0, false).timeout
	Captura.foto("captura-maniquies-rotos.png")


# Con "--captura --edificio torre --jefe directora --despacho": la directora de Recursos Humanos (parte 5 de la torre,
# directora.gd) en su Despacho de Recursos Humanos, con Johnny quieto delante y ella sin moverse de su sitio (cada ataque
# se le manda a mano). Fotos: el despacho (captura-despacho.png), el sello cayendo (captura-directora-sello.png), Johnny
# despedido (-despedido), la lluvia de cajas (-cajas), la evaluación con sus oficinistas (-evaluacion), enfadada con los
# tres sellos (-enfadada) y caída (-muerta). Lo que comprueba, en la terminal
func probar_despacho() -> void:
	if not await ir_a_la_sala_del_jefe("directora"):
		return
	var espera := func(s: float) -> void:
		await get_tree().create_timer(s, false).timeout
	jefa.quieto = true
	jefa.espera_sello = 999.0
	jefa.espera_cajas = 999.0
	jefa.espera_evaluacion = 999.0
	johnny.vida = 999
	johnny.global_position = jefa.global_position + Vector2(0, 190)
	johnny.get_node("Camara").reset_smoothing()
	johnny.sostener("fuego")
	var muebles := get_tree().get_nodes_in_group("muebles").filter(func(m): return m.get("datos") is Dictionary)
	print("Despacho: sala «%s», %d muebles (esperado: Despacho de Recursos Humanos, 17): %s" % [planta.sitios[aqui].nombre,
		muebles.size(), ", ".join(muebles.map(func(m): return str(m.datos.get("tipo", "?"))))])
	# el despacho: Johnny arriba, junto a la mesa de dirección, para que salgan los muebles del fondo y de los lados
	var mesa: Array = muebles.filter(func(m): return m.datos.get("tipo", "") == "execdesk")
	johnny.global_position = (mesa[0].global_position if mesa else jefa.global_position) + Vector2(0, 160)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(0.8)
	Captura.foto("captura-despacho.png")
	johnny.global_position = jefa.global_position + Vector2(0, 190)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(0.3)
	# el sello: cae donde está Johnny
	jefa.cambiar("sello", {"cuantos": 1, "lanzados": 0})
	await espera.call(1.0)
	Captura.foto("captura-directora-sello.png")
	await espera.call(0.45)
	print("Sello: despedido %.1f s, en la mano «%s» (esperado: unos 2,5 y cuerpo)" % [johnny.despedido_t, johnny.mano])
	johnny.cambiar_mano()
	print("Sello: al intentar sacar el arma de fuego, en la mano «%s» (esperado: cuerpo)" % johnny.mano)
	await espera.call(0.3)
	Captura.foto("captura-directora-despedido.png")
	await espera.call(3.0)
	johnny.cambiar_mano()
	print("Sello: pasados los 3 s, en la mano «%s» (esperado: fuego)" % johnny.mano)
	# la lluvia de cajas
	jefa.cambiar("cajas")
	await espera.call(0.85)
	print("Cajas: cayendo %d (esperado: 6)" % get_tree().get_nodes_in_group("balas_zombi").filter(func(c): return c is CaeEncima).size())
	Captura.foto("captura-directora-cajas.png")
	await espera.call(2.0)
	# la evaluación de desempeño: 3 oficinistas y la mitad del daño
	jefa.cambiar("llamar")
	await espera.call(1.1)
	var antes: int = jefa.vida
	jefa.recibir_golpe(20, Vector2.UP)
	print("Evaluación: %d oficinistas, un golpe de 20 le quita %d (esperado: 3 y 10)" % [jefa.evaluados().size(), antes - jefa.vida])
	await espera.call(0.3)
	Captura.foto("captura-directora-evaluacion.png")
	for z in jefa.evaluados():
		z.recibir_golpe(999, Vector2.RIGHT)
	await espera.call(0.4)
	antes = jefa.vida
	jefa.recibir_golpe(20, Vector2.UP)
	print("Evaluación: sin oficinistas, %d; un golpe de 20 le quita %d (esperado: 0 y 20); estado «%s» (esperado: disgusto)" % [
		jefa.evaluados().size(), antes - jefa.vida, jefa.estado])
	# enfadada: tres sellos seguidos (donde vaya estando Johnny: aquí se le mueve entre uno y otro)
	jefa.vida = int(jefa.vida_max * 0.45)
	await espera.call(1.8)
	print("Enfadada: fase %d (esperado: 2)" % jefa.fase)
	jefa.cambiar("sello", {"cuantos": jefa.SELLOS[1], "lanzados": 0})
	for i in 3:
		await espera.call(jefa.ENTRE_SELLOS)
		johnny.global_position += Vector2(70, 0)
	print("Enfadada: sellos lanzados %d (esperado: 3)" % jefa.datos.get("lanzados", 0))
	Captura.foto("captura-directora-enfadada.png")
	await espera.call(2.0)
	jefa.recibir_golpe(99999, Vector2.UP)
	await espera.call(1.4)   # (a los 2 s sale la mutación, que para el juego)
	Captura.foto("captura-directora-muerta.png")


# Con "--captura --edificio torre --jefe informatico --datos": el informático (parte 5 de la torre, informatico.gd) en su
# Centro de datos, quieto (cada ataque se le manda a mano) y con Johnny delante. Fotos: la sala con sus armarios
# (captura-datos.png), los teclados en abanico (captura-informatico-teclados.png), el aviso del cortocircuito con sus
# chispitas (-corto-aviso) y dando corriente (-corto), el apagón con las lucecitas (-apagon), enfadado reiniciándose
# (-reinicio, y -vuelto junto a otro armario) y caído (-muerto). Lo que comprueba, en la terminal
func probar_datos() -> void:
	if not await ir_a_la_sala_del_jefe("informatico"):
		return
	var espera := func(s: float) -> void:
		await get_tree().create_timer(s, false).timeout
	jefa.quieto = true
	jefa.espera_teclados = 999.0
	jefa.espera_corto = 999.0
	jefa.espera_apagon = 999.0
	jefa.espera_reinicio = 999.0
	johnny.vida = 999
	var armarios: Array = jefa.armarios()
	var muebles := get_tree().get_nodes_in_group("muebles").filter(func(m): return m.get("datos") is Dictionary)
	print("Datos: sala «%s», %d muebles, %d armarios de servidores, %d con lucecitas (esperado: Centro de datos)" % [
		planta.sitios[aqui].nombre, muebles.size(), armarios.size(), jefa.lucecitas.size()])
	print("Datos: el suelo de la sala %s, %d franjas" % [jefa.sala(), ceili(jefa.sala().size.y / Cortocircuito.FRANJA)])
	# la sala entera: Johnny en medio, un poco arriba
	johnny.global_position = jefa.sala().get_center() + Vector2(0, -60)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(0.8)
	Captura.foto("captura-datos.png")
	johnny.global_position = jefa.global_position + Vector2(0, 200)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(0.3)
	# los teclados
	jefa.cambiar("teclados", {"angulo": PI / 2, "lanzado": false})
	await espera.call(0.6)
	print("Teclados: volando %d (esperado: 8)" % get_tree().get_nodes_in_group("balas_zombi").filter(func(b): return b is Teclado).size())
	Captura.foto("captura-informatico-teclados.png")
	await espera.call(1.5)
	# el cortocircuito: el aviso y luego dando corriente (Johnny, en una franja de las que dan)
	jefa.cambiar("corto")
	await espera.call(0.4 + 0.7)
	var corto: Array = get_tree().get_nodes_in_group("balas_zombi").filter(func(b): return b is Cortocircuito)
	print("Cortocircuito: %d (esperado: 1), turnos %s" % [corto.size(), corto[0].turnos if corto else "-"])
	Captura.foto("captura-informatico-corto-aviso.png")
	if corto:
		var sala: Rect2 = jefa.sala()
		johnny.global_position.y = sala.position.y + Cortocircuito.FRANJA * 2.5 - 12.0   # en la franja 2 (par: da en el primer turno)
	var antes: int = johnny.vida
	await espera.call(0.6)
	print("Cortocircuito: a Johnny en una franja que da le quita %d (esperado: 12)" % (antes - johnny.vida))
	Captura.foto("captura-informatico-corto.png")
	await espera.call(2.5)
	johnny.global_position = jefa.global_position + Vector2(0, 200)
	# el apagón
	var luz_antes := Luz.evento
	jefa.cambiar("apagon")
	await espera.call(1.6)
	print("Apagón: oscuridad de más %.2f (antes %.2f, esperado 0,45)" % [Luz.evento, luz_antes])
	Captura.foto("captura-informatico-apagon.png")
	await espera.call(jefa.APAGON)
	print("Apagón: pasados %d s, oscuridad de más %.2f (esperado %.2f)" % [jefa.APAGON, Luz.evento, luz_antes])
	# enfadado: se reinicia junto a otro armario
	jefa.vida = int(jefa.vida_max * 0.45)
	await espera.call(1.8)
	print("Enfadado: fase %d (esperado: 2)" % jefa.fase)
	var desde: Vector2 = jefa.global_position
	jefa.espera_reinicio = 0.0
	jefa.elegir(johnny)
	print("Reinicio: estado «%s» (esperado: reinicio)" % jefa.estado)
	await espera.call(0.3)
	Captura.foto("captura-informatico-reinicio.png")
	await espera.call(jefa.SE_VA + jefa.FUERA)
	print("Reinicio: se ha movido %.0f (esperado: más de 120), a %.0f de Johnny (esperado: más de %.0f)" % [
		desde.distance_to(jefa.global_position), jefa.global_position.distance_to(johnny.global_position), jefa.LEJOS_REINICIO])
	johnny.global_position = jefa.global_position + Vector2(0, 160)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(0.4)
	Captura.foto("captura-informatico-vuelto.png")
	# muere en pleno apagón: la luz vuelve
	jefa.estado = "andar"
	jefa.apagar()
	await espera.call(0.3)
	jefa.recibir_golpe(99999, Vector2.UP)
	print("Muerto: oscuridad de más %.2f (esperado %.2f)" % [Luz.evento, luz_antes])
	await espera.call(1.4)   # (a los 2 s sale la mutación, que para el juego)
	Captura.foto("captura-informatico-muerto.png")


# Con "--captura --edificio torre --jefe presentador --plato": el presentador (parte 5 de la torre, presentador.gd) en su
# Plató de presentaciones, quieto (cada ataque se le manda a mano) y con Johnny delante. Fotos: la sala con las butacas y
# el público sentado (captura-plato.png), el cono del grito (captura-presentador-grito-aviso.png) y la onda (-grito), el
# foco siguiendo a Johnny (-foco) y la pantalla blanca al mirarlo (-cegado), los cañones de confeti (-confeti-aviso y
# -confeti), enfadado con el público en pie (-enfadado) y caído (-muerto). Lo que comprueba, en la terminal
func probar_plato() -> void:
	if not await ir_a_la_sala_del_jefe("presentador"):
		return
	var espera := func(s: float) -> void:
		await get_tree().create_timer(s, false).timeout
	jefa.quieto = true
	jefa.espera_grito = 999.0
	jefa.espera_focos = 999.0
	jefa.espera_confeti = 999.0
	johnny.vida = 999
	var butacas := get_tree().get_nodes_in_group("muebles").filter(func(m): return m.get("datos") is Dictionary 		and m.datos.get("tipo", "") == jefa.BUTACAS)
	var sentados: Array = jefa.publico.filter(func(z): return z.sentado)
	print("Plató: sala «%s», %d filas de butacas, %d focos, %d sentados (esperado: Plató de presentaciones, 10 sentados)" % [
		planta.sitios[aqui].nombre, butacas.size(), jefa.focos().size(), sentados.size()])
	# la sala entera, con el público sentado: Johnny en medio (con un tiro al aire: no se despiertan)
	johnny.global_position = jefa.global_position + Vector2(0, 260)
	johnny.get_node("Camara").reset_smoothing()
	for z in get_tree().get_nodes_in_group("zombis"):
		if z.has_method("oir_disparo"):
			z.oir_disparo(johnny.global_position)
	await espera.call(0.8)
	print("Plató: tras el tiro, siguen sentados %d (esperado: 10)" % jefa.publico.filter(func(z): return z.sentado).size())
	Captura.foto("captura-plato.png")
	# el escenario: la pantalla, el atril y los focos
	var sala_: Rect2 = jefa.sala()
	johnny.global_position = Vector2(sala_.get_center().x, sala_.position.y + 230)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(0.4)
	Captura.foto("captura-plato-escenario.png")
	print("Plató: el suelo %s, el presentador en %s" % [sala_, jefa.global_position])
	# el grito al micrófono: el cono y la onda, con Johnny dentro (le empuja hacia atrás)
	johnny.global_position = jefa.global_position + Vector2(0, 170)
	await espera.call(0.3)
	jefa.cambiar("microfono", {"angulo": PI / 2, "gritos": 0})
	await espera.call(0.5)
	Captura.foto("captura-presentador-grito-aviso.png")
	var antes: int = johnny.vida
	var desde: Vector2 = johnny.global_position
	await espera.call(0.42)
	Captura.foto("captura-presentador-grito.png")
	await espera.call(0.3)
	print("Grito: le quita %d (esperado: 12) y le aparta %.0f (esperado: más de 60)" % [antes - johnny.vida,
		johnny.global_position.distance_to(desde) if johnny.global_position.y > desde.y else -1.0])
	await espera.call(0.8)
	# los focos: el haz sigue a Johnny; mirando al foco, ciega
	johnny.global_position = jefa.global_position + Vector2(0, 220)
	jefa.cambiar("focos")
	await espera.call(1.2)
	print("Focos: encendidos %d (esperado: 1)" % jefa.haces.size())
	Captura.foto("captura-presentador-foco.png")
	if not jefa.haces.is_empty():
		var h: Dictionary = jefa.haces[0]
		johnny.global_position = h.punto
		johnny.direccion = Minijefe.DIRS[posmod(roundi((h.foco.global_position + jefa.CABEZA_FOCO - h.punto).angle() / (PI / 4.0)), 8)]
		johnny.set_physics_process(false)   # (quieto, mirando al foco)
		await espera.call(0.25)
		print("Focos: mirándolo, cegado %.2f (esperado: más de 0)" % jefa.cegado_t)
		Captura.foto("captura-presentador-cegado.png")
		johnny.set_physics_process(true)
	await espera.call(jefa.HAZ)
	# el confeti: cuatro cañones donde va estando Johnny (que anda hacia la derecha)
	johnny.global_position = jefa.global_position + Vector2(-140, 200)
	jefa.cambiar("confeti", {"puestos": 0})
	for i in 12:
		johnny.global_position.x += 24.0
		await espera.call(0.13)
	print("Confeti: cañones %d (esperado: 4)" % get_tree().get_nodes_in_group("balas_zombi").filter(func(b): return b is Confeti).size())
	Captura.foto("captura-presentador-confeti-aviso.png")
	await espera.call(0.6)
	Captura.foto("captura-presentador-confeti.png")
	await espera.call(1.2)
	# enfadado: el público se levanta
	jefa.vida = int(jefa.vida_max * 0.45)
	await espera.call(2.2)
	print("Enfadado: fase %d (esperado: 2), sentados %d (esperado: 0)" % [jefa.fase,
		jefa.publico.filter(func(z): return is_instance_valid(z) and z.sentado).size()])
	johnny.global_position = jefa.global_position + Vector2(0, 240)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(0.3)
	Captura.foto("captura-presentador-enfadado.png")
	jefa.recibir_golpe(99999, Vector2.UP)
	await espera.call(1.4)   # (a los 2 s sale la mutación, que para el juego)
	Captura.foto("captura-presentador-muerto.png")


# Con "--captura --edificio torre --jefe becario --fotocopias": el becario (parte 5 de la torre, becario.gd) en su Sala de
# fotocopias, quieto (cada ataque se le manda a mano) y con Johnny delante. Fotos: la sala (captura-fotocopias.png), las
# copias recién salidas, con el de verdad reflejado en la máquina (captura-becario-copias.png y, de cerca, -reflejo), el
# aviso del carrito (-carrito-aviso) y la embestida (-carrito), los vasos de café en el aire (-cafe-aviso) y sus charcos
# (-cafe), enfadado con más copias (-enfadado) y caído, con las copias deshechas (-muerto). Lo que comprueba, en la terminal
func probar_fotocopias() -> void:
	if not await ir_a_la_sala_del_jefe("becario"):
		return
	var espera := func(s: float) -> void:
		await get_tree().create_timer(s, false).timeout
	jefa.quieto = true
	jefa.espera_copias = 999.0
	jefa.espera_carrito = 999.0
	jefa.espera_cafe = 999.0
	johnny.vida = 999
	# (sin los demás zombis de la sala, como el escolta de la alarma: que no se metan en las fotos)
	var limpiar := func() -> void:
		for z in get_tree().get_nodes_in_group("zombis"):
			if z != jefa and not "jefe" in z:
				z.queue_free()
	limpiar.call()
	for al in get_tree().get_nodes_in_group("aliados"):   # (ni el superviviente que acompaña a Johnny: dispara a las copias)
		al.process_mode = Node.PROCESS_MODE_DISABLED
		al.visible = false
	for cam in get_tree().get_nodes_in_group("camaras"):   # (sin alarmas que traigan escoltas)
		cam.queue_free()
	johnny.set_physics_process(false)   # (quieto y sin pegar: que no rompa las copias antes de la foto)
	print("Fotocopias: sala «%s», %d fotocopiadoras (esperado: Sala de fotocopias, 3)" % [planta.sitios[aqui].nombre,
		jefa.copiadoras().size()])
	var sala_: Rect2 = jefa.sala()
	johnny.global_position = Vector2(sala_.get_center().x, sala_.position.y + 260)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(0.5)
	Captura.foto("captura-fotocopias.png")
	# las copias: va a la fotocopiadora más cercana y salen tres; el de verdad, con sombra y en el frontal de la máquina
	jefa.quieto = false
	var c: Node2D = jefa.copiadora_cercana()
	jefa.cambiar("a_copiar", {"copiadora": c})
	var t0 := 0.0
	while jefa.estado == "a_copiar" and t0 < 4.0:
		await espera.call(0.1)
		t0 += 0.1
	jefa.quieto = true
	await espera.call(jefa.COPIANDO * 0.5 + 0.15)
	print("Copias: %d (esperado: 3), con sombra: %d (esperado: 0), el de verdad junto a la máquina: %s" % [
		jefa.copias_vivas().size(), jefa.copias_vivas().filter(func(x): return x.has_node("Sombra")).size(),
		jefa.global_position.distance_to(jefa.boca_de(c)) < 200.0])
	johnny.global_position = jefa.global_position + Vector2(0, 70)
	johnny.get_node("Camara").reset_smoothing()
	for x in jefa.copias_vivas():
		x.quieto = true
	limpiar.call()
	await espera.call(0.35)
	Captura.foto("captura-becario-copias.png")
	print("Reflejo: la fotocopiadora en pantalla, en %s" % (c.get_global_transform_with_canvas().origin))
	# una copia se deshace de un golpe, sin quitarle vida al becario
	var vida_antes: int = jefa.vida
	var golpeada: Node2D = jefa.copias_vivas()[0]
	golpeada.recibir_golpe(10, Vector2.UP)
	await espera.call(0.2)
	print("Copia golpeada: deshecha %s (esperado: true), al becario le quitó %d (esperado: 0)" % [
		not is_instance_valid(golpeada), vida_antes - jefa.vida])
	for x in jefa.copias_vivas():
		x.deshacer()
	johnny.set_physics_process(true)
	# el carrito: la franja y la embestida, con Johnny delante
	jefa.global_position = sala_.get_center() + Vector2(-200, 40)
	johnny.global_position = jefa.global_position + Vector2(260, 0)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(0.3)
	jefa.quieto = false
	jefa.mirada = Vector2.RIGHT
	limpiar.call()
	jefa.cambiar("aviso_carrito", {"aviso": 0.8})
	await espera.call(0.6)
	Captura.foto("captura-becario-carrito-aviso.png")
	var antes: int = johnny.vida
	await espera.call(0.35)
	Captura.foto("captura-becario-carrito.png")
	await espera.call(0.8)
	print("Carrito: le quita %d (esperado: 14), estado del becario «%s»" % [antes - johnny.vida, jefa.estado])
	jefa.quieto = true
	jefa.andar(999.0)
	# el café: cuatro vasos donde está Johnny y alrededor, y sus charcos de café
	johnny.global_position = jefa.global_position + Vector2(0, 200)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(1.0)
	limpiar.call()
	jefa.cambiar("cafe")
	await espera.call(0.75)
	Captura.foto("captura-becario-cafe-aviso.png")
	await espera.call(0.8)
	print("Café: charcos %d (esperado: 4)" % jefa.get_parent().get_children().filter(func(ch): return ch.get("tipo") == "cafe").size())
	Captura.foto("captura-becario-cafe.png")
	# enfadado: saca cinco copias, que pegan
	jefa.vida = int(jefa.vida_max * 0.45)
	await espera.call(1.8)
	limpiar.call()
	jefa.fotocopiar(null)
	print("Enfadado: al copiar salen %d (esperado: 5)" % jefa.copias_vivas().size())
	await espera.call(0.3)
	print("Enfadado: fase %d (esperado: 2), copias %d (esperado: 5), pegan %d (esperado: 5)" % [jefa.fase,
		jefa.copias_vivas().size(), jefa.copias_vivas()[0].CONTACTO if jefa.enfadado() else 0])
	for x in jefa.copias_vivas():
		x.quieto = true
	johnny.global_position = jefa.global_position + Vector2(0, 230)
	johnny.get_node("Camara").reset_smoothing()
	await espera.call(0.3)
	Captura.foto("captura-becario-enfadado.png")
	jefa.recibir_golpe(99999, Vector2.UP)
	await espera.call(0.6)
	print("Muerto: quedan %d copias (esperado: 0)" % get_tree().get_nodes_in_group("zombis").filter(
		func(z): return "jefe" in z).size())
	await espera.call(0.8)   # (a los 2 s sale la mutación, que para el juego)
	Captura.foto("captura-becario-muerto.png")


# Con "--captura --edificio centro --jefe cocinero --cocina": la Cocina central del cocinero (M82), con sus 9 fogones y
# freidoras (tres en cada pared), que rebosan aceite hirviendo. Johnny quieto en medio y el cocinero quieto (aquí se le hace rebosar a mano).
# Fotos: el aviso del primero que rebosa (captura-cocina-aviso.png), su charco a medio extender (-crece) y todos los
# muebles con su charco ya extendido (-llena-izquierda y -llena-derecha). Cuenta cuántos rebosan en 60 s, normal y enfadado, y cuántas veces dos a la vez
func probar_cocina() -> void:
	if not await ir_a_la_sala_del_jefe("cocinero"):
		return
	jefa.set_physics_process(false)
	johnny.set_physics_process(false)
	var fogones: Array = jefa.fogones()
	print("Cocina: %d muebles que rebosan (esperado: 9, tres arriba, tres a la izquierda y tres a la derecha): %s" % [fogones.size(), fogones.map(func(m): return "%s en %s" % [
		m.datos.tipo, m.datos.lado])])
	if fogones.is_empty():
		return
	# Johnny, en medio de la cocina (entre los muebles)
	var medio := Vector2.ZERO
	for m in fogones:
		medio += m.global_position / fogones.size()
	johnny.global_position = medio
	var paso := 1.0 / 60.0
	var correr := func(segundos: float) -> void:
		for i in roundi(segundos * 60.0):
			jefa.tiempo += paso
			jefa.rebosar(paso, johnny)
			await get_tree().physics_frame
	# el primero, a mano: el de la pared de arriba más cerca de Johnny (que salga en la foto)
	var cerca: Node2D = fogones.filter(func(m): return m.datos.lado == "arriba").reduce(func(x, m): return m if 		m.global_position.distance_to(medio) < x.global_position.distance_to(medio) else x)
	jefa.rebosando.append([cerca, jefa.AVISO_REBOSE])
	jefa.mojado[cerca] = jefa.tiempo + jefa.AVISO_REBOSE + jefa.DURA_REBOSE
	jefa.rebose = 99.0
	await correr.call(0.6)
	print("Cocina: avisando %d (esperado: 1)" % jefa.rebosando.size())
	Captura.foto("captura-cocina-aviso.png")
	await correr.call(3.4)
	var charcos := get_tree().get_nodes_in_group("charcos").filter(func(c): return c.tipo == "hirviendo")
	print("Cocina: charcos %d, extendido a los 3 s %s (esperado: 1, entre 0,7 y 0,85)" % [charcos.size(),
		charcos.map(func(c): return "%.2f" % c.extendido())])
	Captura.foto("captura-cocina-crece.png")
	# todos los demás, a la vez (para ver dónde queda el charco de cada uno)
	for m in fogones:
		if jefa.mojado.get(m, 0.0) <= jefa.tiempo:
			jefa.derramar(m)
	await correr.call(6.5)
	# la cocina no cabe entera en la pantalla: una foto con Johnny hacia cada lado (la pared de arriba sale en las dos)
	var bordes: Array = fogones.map(func(m): return m.global_position.x)
	for lado in ["izquierda", "derecha"]:
		johnny.global_position = Vector2(lerpf(bordes.min(), bordes.max(), 0.15 if lado == "izquierda" else 0.85), medio.y + 60.0)
		await get_tree().create_timer(1.0, false).timeout   # (la cámara va suave: que llegue)
		Captura.foto("captura-cocina-llena-%s.png" % lado)
	johnny.global_position = medio
	# cuántos rebosan en 60 s (sin esperar de verdad: los charcos, fuera al momento), normal y enfadado
	for c in get_tree().get_nodes_in_group("charcos"):
		c.remove_from_group("charcos")
		c.queue_free()
	for fase in [1, 2]:
		jefa.fase = fase
		jefa.mojado.clear()
		jefa.rebosando.clear()
		jefa.rebose = 0.0
		var soltados := 0
		var dobles := 0
		for i in 3600:
			jefa.tiempo += paso
			var antes: int = jefa.rebosando.size()
			jefa.rebosar(paso, johnny)
			if jefa.rebosando.size() - antes >= 2:
				dobles += 1
			for c in get_tree().get_nodes_in_group("charcos"):
				if not c.is_queued_for_deletion():
					soltados += 1
					c.remove_from_group("charcos")
					c.queue_free()
		print("Cocina, %s: rebosan %d en 60 s (esperado: %s), %d veces dos a la vez (esperado: %s)" % [
			"enfadado" if fase == 2 else "normal", soltados, "13 o 14" if fase == 1 else "unos 30", dobles,
			"0" if fase == 1 else "unas 10"])


# Con "--captura --jefe gloton --sangre": la sangre ácida de Johnny. Johnny quieto a 3 y a 10 casillas: dos golpes
# seguidos, solo el primero salpica, no le quita vida y el chorro tarda más cuanto más lejos; al caer, deja en su
# sitio un charco (enfadado, dos). Fotos: el chorro volando (captura-gloton-chorro.png) y los charcos donde estaba
# Johnny (captura-gloton-charcos.png)
func probar_sangre_gloton() -> void:
	if not await ir_a_la_sala_del_jefe("gloton"):
		return
	johnny.set_physics_process(false)   # quieto
	jefa.set_physics_process(false)
	var charcos := func() -> Array:
		return get_tree().get_nodes_in_group("charcos").filter(func(c): return c.tipo == "sangre_gloton")
	for prueba in [[1, 3], [2, 10]]:
		var f: int = prueba[0]
		for c in charcos.call():
			c.free()
		jefa.fase = f
		jefa.acido_t = 0.0
		var sitio: Vector2 = jefa.global_position + Vector2(0, -prueba[1] * 32.0)
		johnny.global_position = sitio
		var antes_vida: int = johnny.vida
		jefa.recibir_golpe(10, Vector2.UP * 300.0)
		jefa.recibir_golpe(10, Vector2.UP * 300.0)
		var vuelo: float = jefa.vuelo_acido(prueba[1] * 32.0)
		var t := 0.0
		var foto := false
		while charcos.call().is_empty() and t < 2.0:
			if f == 2 and not foto and t >= vuelo * 0.5:
				Captura.foto("captura-gloton-chorro.png")
				foto = true
			await get_tree().physics_frame
			t += 1.0 / 60.0
		var lejos := 0.0
		for c in charcos.call():
			lejos = maxf(lejos, c.global_position.distance_to(sitio))
		print("Sangre ácida (fase %d, Johnny a %d casillas, dos golpes de 10): Johnny -%d · charcos %d (esperado: %d), a %.0f de donde estaba Johnny como mucho · caen a los %.2f s (esperado: %.2f)" % [
			f, prueba[1], antes_vida - johnny.vida, charcos.call().size(), f, lejos, t, vuelo])
	await get_tree().create_timer(0.4, false).timeout
	Captura.foto("captura-gloton-charcos.png")


# Con "--captura --jefe gloton --aspirar": solo lo del Glotón de probar_gloton (la sangre ácida y el aspirado, con lo que
# tira a 3, 5, 8 y 12 casillas, normal y enfadado), sin la prueba larga. Deja la foto captura-gloton-aspira.png
func probar_aspirar() -> void:
	if await ir_a_la_sala_del_jefe("gloton"):
		await probar_gloton()


# Con "--captura --edificio centro --jefe mascota --crios": los críos que salen sin parar en el combate de la mascota
# (M85). 20 s normal y 20 s enfadada, con Johnny quieto y sin que pueda caer (los críos se le echan encima y se quedan:
# así se ve que no pasan del máximo). Cuenta los que salen, los que hay a la vez como mucho y a qué distancia de Johnny
# aparecen. Foto con los críos encima: captura-mascota-crios.png
func probar_crios() -> void:
	if not await ir_a_la_sala_del_jefe("mascota"):
		return
	johnny.set_physics_process(false)   # quieto
	var distancias: Array[float] = []
	jefa.pide_zombi.connect(func(tipo, donde):
		if tipo == "rapido":
			distancias.append(johnny.global_position.distance_to(donde)))
	for f in [1, 2]:
		jefa.fase = f
		jefa.espera_crio = 0.0
		distancias.clear()
		var a_la_vez := 0
		for pasos in 1200:   # 20 s
			johnny.vida = johnny.stats.vida_max
			a_la_vez = maxi(a_la_vez, jefa.crios())
			await get_tree().physics_frame
		print("Mascota · críos en 20 s (%s): salen %d (cada %.1f s) · a la vez como mucho %d (máximo %d) · a %s de Johnny" % [
			"enfadada" if f == 2 else "normal", distancias.size(), jefa.CRIOS_CADA[f - 1], a_la_vez,
			jefa.CRIOS_MAX[f - 1], distancias.map(func(d): return int(d))])
		if f == 1:
			Captura.foto("captura-mascota-crios.png")
			for z in get_tree().get_nodes_in_group("zombis"):
				if z.get_meta("tipo", "") == "rapido":
					z.recibir_golpe(999, Vector2.RIGHT)
			await get_tree().create_timer(0.5, false).timeout


# Va a la habitación del jefe de la 1ª planta (el de --jefe X) y espera a que salga, sin la prueba larga. Dice si está
func ir_a_la_sala_del_jefe(tipo: String) -> bool:
	set_process(false)
	nueva_planta(2)   # la 1ª planta: con --jefe X, la suya
	planta.tiene_llave = true
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			await montar(i, 0, false)
			break
	await get_tree().create_timer(0.5).timeout
	if jefa == null or planta.jefe != tipo:
		print("No está el jefe «%s» (¿falta --jefe %s?)" % [tipo, tipo])
		return false
	return true


# Con "--captura --jefe portera --atascado" (vale con cualquier --jefe de una habitación): que ningún zombi se quede metido
# en un muro o fuera de la sala del jefe, donde no se le puede matar y el combate no se termina nunca (10 nov: un vecino
# de la portera salió dentro del muro de abajo, junto a la puerta). En la sala de verdad, con el jefe ya fuera, mira:
#   1. el jefe pegado a la pared de abajo, junto a la puerta, llamando a los suyos 6 veces: ninguno sale en un muro
#   2. un zombi pedido justo dentro del muro (meter_zombi): sale en el suelo
#   3. dos zombis metidos a la fuerza, uno dentro del muro de abajo y otro fuera del mapa: la red de seguridad
#      (partida.rescatar_atascados) los devuelve al suelo en menos de un segundo
#   4. dos zombis pegados a la pared de abajo y empujados contra ella con un golpe muy fuerte (el doble que una
#      explosión): no la cruzan
#   5. muertos todos, el combate se termina (la habitación, limpia; la puerta, abierta)
# Cada línea dice lo esperado. Foto: captura-atascado.png (los rescatados, ya dentro, junto a la pared de abajo)
func probar_atascado() -> void:
	if not await ir_a_la_sala_del_jefe(Captura.dato("--jefe", "portera")):
		return
	johnny.set_physics_process(false)   # quieto
	johnny.vida = 99999   # (que no lo tiren)
	var sitio: Dictionary = planta.sitios[aqui]
	var sala: Dictionary = sitio.apt.salas[0]
	var abajo: float = (sala.f0 + sala.fondo) * mapa.CASILLA   # el filo de la pared de abajo
	var puerta_x: float = (sitio.apt.entrada.c + 1) * mapa.CASILLA   # el medio de la puerta de entrada
	johnny.position = Vector2(puerta_x, sala.f0 * mapa.CASILLA + 120.0)
	johnny.get_node("Camara").reset_smoothing()
	var en_muro := func() -> int:
		return get_tree().get_nodes_in_group("zombis").filter(func(z): return mapa.zona_en(z.position) < 0).size()
	# 1. el jefe junto a la pared de abajo, a la derecha de la puerta, llamando
	jefa.quieto = true
	var cuenta := {"pedidos": 0, "mal": 0}
	jefa.pide_zombi.connect(func(_tipo, donde):
		cuenta.pedidos += 1
		if mapa.zona_en(donde) < 0:
			cuenta.mal += 1)
	for i in 6:
		jefa.position = Vector2(puerta_x + 90.0, abajo - 30.0)
		if jefa.has_method("llamar"):
			jefa.llamar("normal", 4, 110.0)   # (los minijefes: Minijefe.llamar)
		else:
			jefa.cambiar("llamar")   # (la portera: su estado "llamar", que los saca al rato)
			await get_tree().create_timer(1.0).timeout
	await get_tree().physics_frame
	print("Atascado 1 (jefe %s, junto a la pared de abajo): pedidos %d (esperado: más de 0) · pedidos dentro de un muro %d (esperado: 0) · zombis en un muro %d (esperado: 0)" % [
		planta.jefe, cuenta.pedidos, cuenta.mal, en_muro.call()])
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != jefa:
			z.remove_from_group("zombis")
			z.queue_free()
	# 2. pedido dentro del muro
	var pedido: Node2D = meter_zombi("normal", Vector2(puerta_x + 140.0, abajo + 40.0))
	print("Atascado 2: pedido dentro del muro, sale en el suelo %s (esperado: true)" % (mapa.zona_en(pedido.position) >= 0))
	# 3. metidos a la fuerza: uno dentro del muro de abajo, a la derecha de la puerta, y otro fuera del mapa
	var dentro: Node2D = meter_zombi("normal", Vector2(puerta_x + 120.0, abajo - 40.0))
	var fuera: Node2D = meter_zombi("rapido", Vector2(puerta_x - 120.0, abajo - 40.0))
	for z in [pedido, dentro, fuera]:
		z.set_physics_process(false)   # (quietos: que no se vayan hacia Johnny)
	await get_tree().physics_frame
	dentro.position = Vector2(puerta_x + 120.0, abajo + 40.0)
	fuera.position = Vector2(puerta_x - 120.0, abajo + mapa.CASILLA * 4)
	var espera := 0.0
	while espera < 1.0 and en_muro.call() > 0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	print("Atascado 3: el del muro, de vuelta en el suelo %s · el de fuera del mapa, de vuelta %s (esperado: true, true) · en %.2f s (esperado: menos de 1)" % [
		mapa.zona_en(dentro.position) >= 0, mapa.zona_en(fuera.position) >= 0, espera])
	johnny.position = Vector2(puerta_x, abajo - 150.0)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-atascado.png")
	# 4. empujados contra la pared con un golpe muy fuerte (la explosión empuja 374)
	var empujados: Array = []
	for x in [puerta_x + 60.0, puerta_x - 200.0]:
		empujados.append(meter_zombi("normal", Vector2(x, abajo - 24.0)))
	await get_tree().physics_frame
	for z in empujados:
		z.recibir_golpe(1, Vector2(0, 800.0))
	var cruzan := 0
	for i in 60:
		await get_tree().physics_frame
		for z in empujados:
			if is_instance_valid(z) and mapa.zona_en(z.position) < 0:
				cruzan += 1
	print("Atascado 4: empujados contra la pared, pasos con el centro en el muro %d · por debajo del filo %d (esperado: 0, 0)" % [
		cruzan, empujados.filter(func(z): return is_instance_valid(z) and z.position.y > abajo).size()])
	# 5. muertos todos: el combate se termina
	for z in get_tree().get_nodes_in_group("zombis"):
		z.morir()
	espera = 0.0
	while espera < 3.0 and not sitio.limpio:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	print("Atascado 5: muertos todos, combate terminado %s · puerta abierta %s (esperado: true, true)" % [sitio.limpio, not cerrada])


# Con "--captura --jefe gymbro --pesas": solo lo del Gymbro de probar_gymbro (suplementos, salto y pesas), sin la prueba
# larga, con dos fotos de las pesas que lanza (el dibujo de PixelLab, como el de las del suelo): en el aire
# (captura-gymbro-pesas-aire.png) y ya caídas en el suelo (captura-gymbro-pesas-suelo.png)
func probar_pesas() -> void:
	if not await ir_a_la_sala_del_jefe("gymbro"):
		return
	await probar_gymbro()
	await get_tree().create_timer(0.4, false).timeout
	Captura.foto("captura-gymbro-pesas-aire.png")
	await get_tree().create_timer(1.4, false).timeout
	Captura.foto("captura-gymbro-pesas-suelo.png")


# Con "--captura --jefe gymbro --metal": el Gymbro de metal (sus suplementos, gymbro.gd), quieto y con Johnny al lado.
# Fotos: normal (captura-gymbro-metal-0.png), con el metal subiendo (-1-subiendo), de metal entero (-2-entero), a media
# armadura y casi sin ella (-3-desconchado y -4-casi), y al reventar (-5-revienta, con las esquirlas). Lo que comprueba,
# en la terminal. Los tres sonidos nuevos van a capturas/ (sonido-acero.wav, sonido-metalizar.wav y sonido-chatarra.wav)
# para oírlos (la prueba va sin sonido)
func probar_metal() -> void:
	if not await ir_a_la_sala_del_jefe("gymbro"):
		return
	for nombre in ["acero", "metalizar", "chatarra"]:
		Sonido.sintetizar(Sonido.EFECTOS[nombre].notas).save_to_wav(Captura.CARPETA + "sonido-%s.wav" % nombre)
	jefa.quieto = true
	johnny.position = jefa.position + Vector2(-150, 30)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5, false).timeout
	Captura.foto("captura-gymbro-metal-0.png")
	# a media vida se enfada él solo (como en la partida)
	jefa.vida = int(jefa.vida_max * jefa.enfado) - 1
	await get_tree().create_timer(0.35, false).timeout
	print("Gymbro: se enfada %s | metal subiendo %.2f (esperado: entre 0 y 1) | suena «%s» (esperado: acero)" % [
		jefa.fase == 2, jefa.metal, jefa.sonido_golpe])
	Captura.foto("captura-gymbro-metal-1-subiendo.png")
	await get_tree().create_timer(1.3, false).timeout
	print("  de metal entero: %.2f (esperado: 1)" % jefa.metal)
	Captura.foto("captura-gymbro-metal-2-entero.png")
	# a golpes, hasta media armadura y casi sin ella
	for paso in [[0.5, "3-desconchado"], [0.15, "4-casi"]]:
		while jefa.armadura > jefa.armadura_max * paso[0]:
			johnny.vida = johnny.stats.vida_max
			jefa.recibir_golpe(20, Vector2.RIGHT * 300.0)
			await get_tree().physics_frame
		await get_tree().create_timer(0.3, false).timeout
		var pelado: float = jefa.sprite.material.get_shader_parameter("pelado")
		print("  armadura %d de %d: desconchado %.2f (esperado: %.2f más o menos)" % [
			jefa.armadura, jefa.armadura_max, pelado, 1.0 - paso[0]])
		Captura.foto("captura-gymbro-metal-%s.png" % paso[1])
	while jefa.armadura > 0:
		jefa.recibir_golpe(20, Vector2.RIGHT * 300.0)
		await get_tree().physics_frame
	await get_tree().create_timer(0.08, false).timeout
	print("  sin armadura: metal %.2f (esperado: 0) | suena «%s» (esperado: golpe) | rojo de enfadado otra vez %s (esperado: true)" % [
		jefa.metal, jefa.sonido_golpe, jefa.sprite.modulate != Color.WHITE])
	Captura.foto("captura-gymbro-metal-5-revienta.png")


# El Glotón: la sangre ácida (la bala de un superviviente: le hace daño a él y no salpica; lo de Johnny, en
# probar_sangre_gloton) y el aspirado (hasta dónde llega: al
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
	print("Aspirar, tirón a 3/5/8/12 casillas (Johnny anda a 210): al empezar %s (esperado: el 30 %%: [98, 63, 40, 32]); con toda su fuerza %s (esperado: [327, 211, 132, 105]: de cerca igual, de lejos más)" % [flojo, fuerte])
	jefa.fase = 2   # y enfadado
	var enfadado := [3, 5, 8, 12].map(func(c): return roundi(jefa.tiron_aspirado(c * 32.0)))
	jefa.fase = 1
	print("Aspirar enfadado, con toda su fuerza: %s (esperado: [655, 422, 203, 170])" % [enfadado])
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


# --azotea: solo la azotea (la de los Apartamentos, con el científico; con --edificio centro, la del gerente)
func probar_azotea_sola() -> void:
	await get_tree().create_timer(0.3).timeout
	await probar_azotea(true)
	get_tree().quit()


# --cupula: la cúpula de cristal del científico jefe con balas de verdad, desde ocho lados y desde dentro: rebotan en su
# borde con su onda y el daño se lo lleva ella (captura-cupula-sube.png, captura-cupula.png y, con las grietas y el
# fogonazo, captura-cupula-rebote-1.png y -2); rota, ya le dan a él (captura-cupula-rota.png). Lo que comprueba lo
# escribe en la terminal
func probar_cupula() -> void:
	await get_tree().create_timer(0.3).timeout
	nueva_planta(Planta.PLANTAS)
	await montar(0, puerta_de_llegada(), false)
	johnny.position = mapa.puertas[0].llegada() - Vector2(60, 200)
	await get_tree().create_timer(1.4).timeout
	var s: Dictionary = planta.sitios[0]
	johnny.position = Vector2(Planta.plataforma(s).end.x - 60.0, s.helipuerto.y)   # sube al ring: deja de esperar
	await get_tree().create_timer(0.5).timeout
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(1.25, 1.25)
	camara.reset_smoothing()
	var encuadre := func() -> void:   # las fotos, con él en medio
		Temblor.desplazamiento = jefa.position + Vector2(0, -50) - johnny.position
	encuadre.call()
	jefa.subir_cupula()
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-cupula-sube.png")
	await get_tree().create_timer(0.4).timeout
	encuadre.call()
	await get_tree().process_frame
	Captura.foto("captura-cupula.png")
	var vida_antes: int = jefa.vida
	var bordes := []
	for i in 8:
		await bala_al_jefe(TAU * i / 8.0, 140.0, 10)
		bordes.append(int(jefa.ondas[-1].donde.length()))
	print("Cúpula: 8 balas de 10: a ella le quedan %d de %d (esperado: %d) | a él le quitan %d (esperado: 0) | ondas a %s del centro (esperado: su borde, %d) | barra azul %s" % [
		jefa.cupula, jefa.CUPULA_VIDA, jefa.CUPULA_VIDA - 80, vida_antes - jefa.vida, bordes, int(jefa.CUPULA_RADIO),
		armadura_jefe().visible])
	await bala_al_jefe(PI, 30.0, 1)
	print("  desde dentro, disparando hacia la derecha: la onda sale en %s (izquierda = el borde que queda detrás de quien dispara)" % jefa.ondas[-1].donde.round())
	encuadre.call()
	await bala_al_jefe(0.0, 140.0, 10)
	await get_tree().process_frame
	await get_tree().process_frame
	Captura.foto("captura-cupula-rebote-1.png")
	await get_tree().create_timer(0.06).timeout
	Captura.foto("captura-cupula-rebote-2.png")
	vida_antes = jefa.vida
	await bala_al_jefe(PI, 140.0, 500)
	print("  una bala de 500: cúpula %d | estado %s | a él le quita %d (esperado: 0, lo que sobra se pierde)" % [jefa.cupula,
		jefa.estado, vida_antes - jefa.vida])
	await get_tree().create_timer(0.45).timeout
	encuadre.call()
	await get_tree().process_frame
	Captura.foto("captura-cupula-rota.png")
	vida_antes = jefa.vida
	var ondas: int = jefa.ondas.size()
	await bala_al_jefe(0.0, 140.0, 10)
	print("  rota: otra bala le quita %d a él (esperado: 10) | ondas nuevas %d (esperado: 0)" % [vida_antes - jefa.vida,
		jefa.ondas.size() - ondas])
	Temblor.desplazamiento = Vector2.ZERO
	get_tree().quit()


# --criatura: lo seguido que ataca la criatura del científico (M69). Lo hace mutar y deja a Johnny quieto a unos 200
# de ella, sin que pueda caer, durante 10 s: escribe cuántos ataques empieza de cada tipo y saca una foto a mitad
# (captura-criatura-seguido.png)
func probar_criatura() -> void:
	await get_tree().create_timer(0.3).timeout
	nueva_planta(Planta.PLANTAS)
	await montar(0, puerta_de_llegada(), false)
	johnny.position = mapa.puertas[0].llegada() - Vector2(60, 200)
	await get_tree().create_timer(1.4).timeout
	var s: Dictionary = planta.sitios[0]
	johnny.position = Vector2(Planta.plataforma(s).end.x - 60.0, s.helipuerto.y)   # sube al ring: deja de esperar
	await get_tree().create_timer(0.5).timeout
	jefa.recibir_golpe(int(jefa.vida - jefa.vida_max * 0.5), Vector2.ZERO)
	for i in 600:
		if jefa.mutado and jefa.estado != "mutar" and jefa.estado != "jeringa":
			break
		await get_tree().physics_frame
	johnny.set_physics_process(false)   # quieto
	var ataques := {}
	var antes: String = jefa.estado
	var pasos := 0
	while pasos < 600:   # 10 s
		johnny.vida = johnny.stats.vida_max
		if jefa.global_position.distance_to(johnny.global_position) > 230.0 or pasos == 0:
			johnny.position = jefa.position + Vector2(200, 0)
			johnny.get_node("Camara").reset_smoothing()
		if jefa.estado != antes and jefa.estado.begins_with("aviso_"):
			ataques[jefa.estado] = ataques.get(jefa.estado, 0) + 1
		antes = jefa.estado
		if pasos == 300:
			Captura.foto("captura-criatura-seguido.png")
		pasos += 1
		await get_tree().physics_frame
	var total: int = ataques.values().reduce(func(x, y): return x + y, 0)
	print("Criatura · ataques en 10 s: %d %s · esperas %s" % [total, ataques, jefa.ESPERAS_CRIATURA])
	get_tree().quit()


# Una bala de verdad hacia el jefe, desde "lejos" por el lado "angulo"; espera a que choque
func bala_al_jefe(angulo: float, lejos: float, dano: int) -> void:
	var bala: Node2D = load("res://escenas/armas/bala.tscn").instantiate()
	bala.velocidad = Vector2.from_angle(angulo + PI) * 900.0
	bala.dano = dano
	bala.vida = 1.0
	jefa.get_parent().add_child(bala)
	bala.global_position = jefa.global_position + Vector2.from_angle(angulo) * lejos
	var espera := 0.0
	while is_instance_valid(bala) and espera < 1.0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()


# El helipuerto de la azotea (planta.gd, mapa.gd y partida.gd, mirar_ring), la imagen de GPT entera, a ras de suelo:
# que el jefe está en el aro, dentro de las líneas blancas; que no hay aparatos; que los muros van por la barandilla
# (arriba 4 filas, abajo 3, a los lados 2); que Johnny llega por la derecha, fuera de las líneas, y desde ahí se va
# andando al aro; que el jefe espera sin recibir daño y que, al entrar Johnny en las líneas, empieza la pelea
# (captura-azotea-ring.png)
func probar_helipuerto(s: Dictionary, camara: Camera2D) -> void:
	var p := Planta.plataforma(s)
	print("  helipuerto: el aro %s dentro de las líneas %s (esperado: true)" % [s.helipuerto, p.has_point(s.helipuerto)])
	# los aparatos (planta.gd, AZOTEA_APARATOS): en el suelo, sin tapar el aro con su dibujo ni la llegada; los aires
	# acondicionados, con AZOTEA_RODEO libre hasta la barandilla por los cuatro lados (para rodearlos)
	var suelo := Rect2(Planta.MURO, Planta.AZOTEA_MURO_ARRIBA * Planta.CASILLA, s.ancho - 2.0 * Planta.MURO,
		s.alto - (Planta.AZOTEA_MURO_ARRIBA + Planta.AZOTEA_MURO_ABAJO) * Planta.CASILLA)
	var malos := 0
	for m in s.muebles:
		var r := Muebles.hueco(m)
		var alto: float = load("res://assets/sprites/mueble-%s.png" % m.tipo).get_height() * 2.0
		var dibujo := Rect2(r.position.x, r.end.y - alto, r.size.x, alto)
		var rodeo := Planta.AZOTEA_RODEO - 1.0 if m.tipo == "acunit" else 0.0
		if not suelo.grow(-rodeo).encloses(r) or dibujo.get_center().distance_to(s.helipuerto) < Planta.AZOTEA_ARO_LIBRE:
			malos += 1
		if r.grow(johnny.RADIO).has_point(mapa.puertas[0].llegada()):
			malos += 1
	print("  aparatos: %d | mal puestos %d (esperado: 5, 0)" % [s.muebles.size(), malos])
	# y de verdad: en el hueco de cada lado de cada aire acondicionado cabe la criatura del doctor Salas (radio 48)
	var circulo := CircleShape2D.new()
	circulo.radius = 48.0
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = circulo
	consulta.collision_mask = 1
	var atascos := 0
	for m in s.muebles:
		if m.tipo != "acunit":
			continue
		var r := Muebles.hueco(m)
		var c := r.get_center()
		for punto in [Vector2(c.x, (r.position.y + suelo.position.y) / 2.0), Vector2(c.x, (r.end.y + suelo.end.y) / 2.0),
				Vector2((r.position.x + suelo.position.x) / 2.0, c.y), Vector2((r.end.x + suelo.end.x) / 2.0, c.y)]:
			consulta.transform = Transform2D(0.0, punto)
			if not mapa.get_world_2d().direct_space_state.intersect_shape(consulta, 1).is_empty():
				atascos += 1
	print("  la criatura cabe alrededor de cada aire acondicionado: huecos con choque %d (esperado: 0)" % atascos)
	# los muros, por la barandilla: en cada columna de dentro, muro hasta la fila 3 y desde la 27; suelo entre medias
	var mal := 0
	for c in range(2, mapa.cols - 2):
		if not (mapa.es_muro(c, Planta.AZOTEA_MURO_ARRIBA - 1) and not mapa.es_muro(c, Planta.AZOTEA_MURO_ARRIBA)
				and not mapa.es_muro(c, mapa.filas - Planta.AZOTEA_MURO_ABAJO - 1) and mapa.es_muro(c, mapa.filas - Planta.AZOTEA_MURO_ABAJO)):
			mal += 1
	for f in range(Planta.AZOTEA_MURO_ARRIBA, mapa.filas - Planta.AZOTEA_MURO_ABAJO):
		if not (mapa.es_muro(1, f) and not mapa.es_muro(2, f) and not mapa.es_muro(mapa.cols - 3, f) and mapa.es_muro(mapa.cols - 2, f)):
			mal += 1
	print("  muros por la barandilla: %d casillas mal (esperado: 0)" % mal)
	# Johnny llega por la derecha, fuera de las líneas, y hay camino andando hasta el aro
	var nav := mapa.get_world_2d().navigation_map
	var llegada: Vector2 = mapa.puertas[0].llegada()
	var camino := NavigationServer2D.map_get_path(nav, llegada, s.helipuerto, true)
	print("  llegada %s: fuera de las líneas %s | camino hasta el aro %s (esperado: true, true)" % [llegada,
		not mapa.en_plataforma(llegada, johnny.RADIO + 6.0), not camino.is_empty() and camino[-1].distance_to(s.helipuerto) < 4.0])
	# el jefe espera en el aro: los golpes no le hacen nada
	if jefa is Minijefe:
		var vida_antes: int = jefa.vida
		jefa.recibir_golpe(50, Vector2.RIGHT * 300.0)
		print("  el jefe espera: %s | estado %s | en el ring %s | un golpe le quita %d (esperado: 0)" % [jefa.esperando,
			jefa.estado, mapa.en_plataforma(jefa.position), vida_antes - jefa.vida])
	# Johnny, en la pasarela (fuera de las líneas): el jefe sigue esperando
	johnny.position = Vector2(p.end.x + 40.0, s.helipuerto.y)
	camara.reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("  fuera de las líneas: el jefe espera %s (esperado: true)" % (jefa is Minijefe and jefa.esperando))
	# y entra en ellas: empieza la pelea
	johnny.position = Vector2(p.end.x - 60.0, s.helipuerto.y)
	await get_tree().create_timer(0.5).timeout
	camara.zoom = Vector2(0.8, 0.8)
	camara.reset_smoothing()
	Captura.foto("captura-azotea-ring.png")
	camara.zoom = Vector2.ONE
	print("  dentro de las líneas: el jefe espera %s | aviso: '%s' (esperado: false)" % [jefa is Minijefe and jefa.esperando, aviso.text])


# La azotea del centro comercial: Johnny llega por la escalera y sale el jefe (captura-azotea.png); la azotea entera,
# sin penumbra y desde lejos (captura-azotea-entera.png); y, quitado el jefe, el helicóptero con su escalera de cuerda
# (captura-helicoptero.png). "acabar": que Johnny llegue a la escalera de verdad y se acabe la partida (la prueba larga
# la acaba ella, más tarde: ahí solo se comprueba que la escalera lo agarra)
func probar_azotea(acabar := false) -> void:
	nueva_planta(Planta.PLANTAS)
	await montar(0, puerta_de_llegada(), false)
	var s: Dictionary = planta.sitios[0]
	print("Azotea: %d x %d | manchas %d | restos %d | jefe: %s (%s)" % [s.ancho, s.alto,
		s.manchas.size(), mapa.restos.size(), planta.jefe, planta.el_jefe])
	johnny.position = mapa.puertas[0].llegada() + Vector2(-10, 120)   # se aleja de la escalera por la pasarela, sin entrar en las líneas: se cierra detrás
	await get_tree().create_timer(1.4).timeout
	Captura.foto("captura-azotea.png")
	print("  ha salido el jefe: %s | escalera de llegada %s | puertas %d (esperado: 1, sin escalera de incendios) | aviso: '%s'" % [
		jefa != null, "cerrada" if cerrada else "abierta", mapa.puertas.size(), aviso.text])
	var camara: Camera2D = johnny.get_node("Camara")
	await probar_helipuerto(s, camara)
	# el gerente, con Johnny delante, lanzándole los contratos (captura-gerente.png)
	if jefa and jefa.has_method("lanzar_contratos"):
		for i in 60:
			johnny.position = jefa.position + Vector2.from_angle(PI + randf_range(-0.8, 0.8)) * 220.0
			if mapa.en_plataforma(johnny.position, johnny.RADIO) and jefa.a_la_vista(johnny):   # dentro del ring
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
			if mapa.en_plataforma(johnny.position, johnny.RADIO):
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
	# sin el jefe llega el helicóptero. El gerente cae de verdad (el jefe final no saca mutaciones); la
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
	johnny.position = s.helipuerto + Vector2(-150, 120)
	camara.reset_smoothing()
	await get_tree().create_timer(0.6).timeout
	print("  sin el jefe: jefe muerto %s | valla del helipuerto %s | aviso: '%s'" % [planta.jefa_muerta,
		"ninguna" if not "valla" in mapa else "puesta", aviso.text])
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
		await get_tree().create_timer(0.8 + Helicoptero.LLEGADA * 0.5).timeout
		Captura.foto("captura-helicoptero-llegando.png")   # (aún bajando, con el morro inclinado)
		await get_tree().create_timer(Helicoptero.LLEGADA * 0.5 + 0.5).timeout
		var helis: Array = mapa.cosas.get_children().filter(func(n): return n is Helicoptero)
		print("  helicóptero de Velaria: %d | sobre el helipuerto %s | escalera recogida (bajada %.1f) | aviso: '%s'" % [helis.size(),
			not helis.is_empty() and helis[0].llegado and helis[0].position.distance_to(helipuerto) < 1.0,
			helis[0].escalera if not helis.is_empty() else -1.0, aviso.text])
		await get_tree().create_timer(Helicoptero.ESCALERA_ESPERA + Helicoptero.ESCALERA_TIEMPO * 0.5).timeout
		Captura.foto("captura-helicoptero-escalera-bajando.png")
		await get_tree().create_timer(Helicoptero.ESCALERA_TIEMPO * 0.5 + 0.4).timeout
		Captura.foto("captura-helicoptero.png")
		print("  la escalera llega al suelo: %s | aviso: '%s'" % [helis[0].escalera >= 1.0, aviso.text])
		camara.zoom = Vector2.ONE
		# lejos de la escalera no se agarra; junto a ella, sí, y se acaba el edificio
		var agarro := [false]
		helis[0].agarrada.connect(func(): agarro[0] = true)
		johnny.position = helis[0].punta() + Vector2(0, 120)
		await get_tree().create_timer(0.3).timeout
		var lejos: bool = agarro[0]
		cambiando = not acabar   # (en la prueba larga no se acaba aquí: ya lo hace ella al final)
		johnny.position = helis[0].punta() + Vector2(0, 24)
		await get_tree().create_timer(0.3).timeout
		print("  Johnny lejos de la escalera: agarrada %s (esperado: false) | junto a ella: agarrada %s (esperado: true) | partida acabada %s (esperado: %s)" % [
			lejos, agarro[0], terminada, acabar])
		cambiando = false
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
			if mapa.en_plataforma(johnny.position, johnny.RADIO) and jefa.a_la_vista(johnny):   # (dentro del ring)
				break
		camara.reset_smoothing()
		johnny.vida = johnny.stats.vida_max   # (en el ring siempre hay charcos cerca: que no caiga a media prueba)
	# las probetas, recién tiradas
	cerca.call(220.0, PI)
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
	cerca.call(250.0, 0.0)
	jefa.empezar("aviso_fuego", (johnny.position - jefa.position).angle())
	jefa.t = jefa.AVISO_FUEGO - 0.05
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-criatura-fuego.png")
	print("  fuego: %s | bolas en el aire %d" % [jefa.estado, get_tree().get_nodes_in_group("balas_zombi").size()])
	# M41 y M42: a la criatura el fuego del suelo no le hace nada, una granada le hace la mitad y, si quedan pocos
	# zombis, ruge y llegan tres vecinos
	await get_tree().create_timer(0.6).timeout
	var antes_vida: int = jefa.vida
	jefa.herir(20.0, Llamas.FUEGO[2])
	print("  fuego del suelo (20): le quita %d (esperado: 0, «¡INMUNE!»)" % (antes_vida - jefa.vida))
	johnny.position = jefa.position + Vector2(400, 0)
	antes_vida = jefa.vida
	var ex: Node2D = load("res://escenas/armas/explosion.tscn").instantiate()
	ex.dano = Lanzables.GRANADA.dano
	ex.radio = Lanzables.GRANADA.radio
	ex.position = jefa.position
	jefa.get_parent().add_child(ex)
	await get_tree().physics_frame
	print("  una granada (%d): le quita %d (esperado: %d, la mitad)" % [Lanzables.GRANADA.dano, antes_vida - jefa.vida,
		roundi(Lanzables.GRANADA.dano * Lanzables.A_JEFES)])
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != jefa:
			z.queue_free()
	await get_tree().physics_frame
	jefa.espera_criatura.sujetos = 0.0
	jefa.elegir_criatura(johnny, 400.0)
	await get_tree().physics_frame
	print("  sin zombis, ruge: llegan %d (esperado: 3)" % jefa.secuaces())
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-criatura-ruge.png")
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
			if mapa.en_plataforma(johnny.position, johnny.RADIO) and jefa.a_la_vista(johnny):   # (dentro del ring)
				break
		camara.reset_smoothing()
		johnny.vida = johnny.stats.vida_max   # (en el ring siempre hay charcos cerca: que no caiga a media prueba)
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
	cerca.call(250.0, 0.0)
	jefa.empezar("aviso_embestida", (johnny.position - jefa.position).angle())
	await get_tree().create_timer(0.55).timeout
	Captura.foto("captura-mutado-embestida.png")
	var estados := []
	for i in 30:
		await get_tree().create_timer(0.05).timeout
		if estados.is_empty() or estados[-1] != jefa.estado:
			estados.append(jefa.estado)
	print("  embestida: %s" % " → ".join(estados))


# --laboratorio (con --edificio torre): la planta 40 de Torre Velaria, el laboratorio (parte 6), con el jefe que haya (el
# Sujeto 1 cuando esté; si no, el de relleno). La sala entera con la cabina de la presidenta (captura-lab.png), un láser
# con su aviso y su rayo (captura-lab-laser-aviso.png y captura-lab-laser.png: quema a Johnny una vez), dos cápsulas
# abiertas con sus sujetos (captura-lab-capsulas.png), el gas (captura-lab-gas.png: a Johnny nada, al sujeto lo pone
# frenético), la cabina rota con la presidenta huyendo (captura-lab-rota.png) y, al caer el jefe, la puerta del
# helipuerto abierta (captura-lab-puerta.png). Lo que comprueba lo escribe en la terminal
func probar_laboratorio() -> void:
	await get_tree().create_timer(0.3).timeout
	var espera := func(s: float) -> void:
		await get_tree().create_timer(s, false).timeout
	nueva_planta(Planta.PLANTAS)
	await montar(0, puerta_de_llegada(), false)
	for al in get_tree().get_nodes_in_group("aliados"):
		al.process_mode = Node.PROCESS_MODE_DISABLED
		al.visible = false
	var s: Dictionary = planta.sitios[0]
	var lab: Node2D = mapa.laboratorio
	print("Laboratorio: sitio «%s», estilo %s, %d cápsulas, %d mesas, laboratorio.gd montado: %s (esperado: Laboratorio, laboratorio, 6, 6, true)" % [
		s.nombre, s.estilo, s.laboratorio.capsulas.size(), s.muebles.filter(func(m): return m.tipo == "labbench").size(), lab != null])
	johnny.vida = 999
	johnny.position = Vector2(s.ancho / 2.0 + 160, 420)
	johnny.set_physics_process(false)
	await espera.call(1.2)
	print("  jefe: %s, la presidenta lo sigue: %s" % [planta.jefe, lab.jefe == jefa])
	jefa.process_mode = Node.PROCESS_MODE_DISABLED   # (quieto: que no se meta en las fotos)
	lab.espera = 999.0
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != jefa:
			z.queue_free()
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(0.75, 0.75)
	Temblor.desplazamiento = Vector2(s.ancho / 2.0, 330) - johnny.position
	camara.reset_smoothing()
	await espera.call(0.4)
	Captura.foto("captura-lab.png")
	# un láser horizontal justo por los pies de Johnny
	lab.lasers.append({"horizontal": true, "pos": johnny.position.y + 12, "t": 0.0, "pillados": {}})
	var vida: int = johnny.vida
	await espera.call(0.5)
	Captura.foto("captura-lab-laser-aviso.png")
	var en_aviso: int = vida - johnny.vida
	await espera.call(0.8)
	Captura.foto("captura-lab-laser.png")
	await espera.call(1.2)
	print("Láser: en el aviso le quita %d (esperado: 0); con el rayo, %d (esperado: %d, una sola vez)" % [en_aviso,
		vida - johnny.vida - en_aviso, lab.LASER.dano])
	# las cápsulas
	lab.abrir_capsulas()
	await espera.call(0.6)
	var sujetos := get_tree().get_nodes_in_group("zombis").filter(func(z): return z != jefa)
	print("Cápsulas: abiertas %d, cerradas %d, sujetos fuera %d (esperado: 2, 4, 2)" % [6 - lab.cerradas.size(),
		lab.cerradas.size(), sujetos.size()])
	for z in sujetos:
		z.process_mode = Node.PROCESS_MODE_DISABLED
	Temblor.desplazamiento = Vector2(260, 260) - johnny.position
	await espera.call(0.3)
	Captura.foto("captura-lab-capsulas.png")
	# el gas: un sujeto encima de una rejilla
	var z0: Node2D = sujetos[0]
	z0.process_mode = Node.PROCESS_MODE_INHERIT
	z0.position = s.laboratorio.rejillas[0]
	var vida_j: int = johnny.vida
	johnny.position = s.laboratorio.rejillas[0] + Vector2(40, 10)
	lab.echar_gas()
	Temblor.desplazamiento = Vector2(s.laboratorio.rejillas[0]) - johnny.position
	await espera.call(1.5)
	Captura.foto("captura-lab-gas.png")
	print("Gas: a Johnny le quita %d (esperado: 0); el sujeto frenético: %s (esperado: true)" % [vida_j - johnny.vida,
		z0.frenesi > 0.0])
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != jefa:
			z.queue_free()
	await espera.call(lab.GAS.dura)
	# a media vida: la cabina se rompe y la presidenta huye
	jefa.vida = jefa.vida_max / 2
	jefa.process_mode = Node.PROCESS_MODE_INHERIT
	johnny.position = Vector2(s.ancho / 2.0 + 160, 420)
	Temblor.desplazamiento = Vector2(s.ancho / 2.0, 200) - johnny.position
	camara.zoom = Vector2(1.25, 1.25)
	await espera.call(0.15)
	jefa.process_mode = Node.PROCESS_MODE_DISABLED
	await espera.call(0.6)
	Captura.foto("captura-lab-rota.png")
	print("Cabina: rota %s (esperado: true), en automático: %s" % [lab.rota, lab.rota])
	await espera.call(1.6)
	# cae el jefe: la puerta del helipuerto se abre
	jefa.process_mode = Node.PROCESS_MODE_INHERIT
	for z in get_tree().get_nodes_in_group("zombis"):   # (los que haya llamado el jefe)
		if z != jefa:
			z.queue_free()
	await espera.call(0.1)
	jefa.vida = 0
	jefa.vida_cambiada.emit(0, jefa.vida_max)
	jefa.morir()
	var t0 := 0.0
	while not lab.salida_abierta and t0 < 8.0:
		if get_tree().paused:   # (la página del dosier: se cierra)
			get_tree().paused = false
			menus.cerrar()
		# (con un reloj que corre también en pausa: el de "espera" se pararía con la página abierta y la prueba se colgaría)
		await get_tree().create_timer(0.2, true).timeout
		t0 += 0.2
	await espera.call(1.0)
	camara.zoom = Vector2(1.25, 1.25)
	johnny.position = Vector2(lab.datos.puerta + 90, 200)
	Temblor.desplazamiento = Vector2(lab.datos.puerta, 120) - johnny.position
	await espera.call(0.3)
	Captura.foto("captura-lab-puerta.png")
	print("Puerta del helipuerto: abierta %s (esperado: true) | jefe muerto %s, vida %s, zombis %d" % [lab.salida_abierta,
		planta.jefa_muerta, jefa.vida if is_instance_valid(jefa) else -1, get_tree().get_nodes_in_group("zombis").size()])
	johnny.position = Vector2(lab.datos.puerta, Planta.MURO + 24)
	await get_tree().create_timer(0.4, true).timeout   # (el relato del final pone el juego en pausa)
	print("  al llegar a ella: se acaba el edificio %s (esperado: true)" % lab.salido)


# --sujeto (con --edificio torre --jefe sujeto_1): el Sujeto 1, el jefe final de Torre Velaria, en el laboratorio de la
# planta 40 (parte 6). Quieto (captura-sujeto.png), el aviso del fregonazo y el golpe (captura-sujeto-fregonazo-aviso.png y
# captura-sujeto-fregonazo.png: 22 y un empujón), el cubo levantado, los cubos volando con sus anillos y los charcos de
# agua (captura-sujeto-cubo-aviso.png, captura-sujeto-cubos.png y captura-sujeto-charcos.png), rodando para librarse de
# una bala (captura-sujeto-rodar.png), partiéndose (captura-sujeto-partirse.png), las dos mitades
# (captura-sujeto-partido.png), una enfadada al caer la otra (captura-sujeto-enfadado.png) y, al caer las dos, la puerta
# del helipuerto. Lo que comprueba lo escribe en la terminal
func probar_sujeto() -> void:
	await get_tree().create_timer(0.3).timeout
	var espera := func(s: float) -> void:
		await get_tree().create_timer(s, false).timeout
	nueva_planta(Planta.PLANTAS)
	await montar(0, puerta_de_llegada(), false)
	for al in get_tree().get_nodes_in_group("aliados"):
		al.process_mode = Node.PROCESS_MODE_DISABLED
		al.visible = false
	var s: Dictionary = planta.sitios[0]
	var lab: Node2D = mapa.laboratorio
	johnny.vida = 999
	johnny.position = Vector2(s.ancho / 2.0 + 160, 520)
	johnny.set_physics_process(false)
	await espera.call(1.2)
	lab.espera = 999.0   # (sin trucos de la presidenta: que no se metan en las fotos)
	var suj: Node2D = jefa
	print("Sujeto 1: jefe %s, script sujeto_1.gd %s, vida %d, la presidenta lo sigue %s" % [planta.jefe,
		suj.get_script().resource_path.ends_with("sujeto_1.gd"), suj.vida, lab.jefe == suj])
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != suj:
			z.queue_free()
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(1.0, 1.0)
	var centro := Vector2(s.ancho / 2.0, 500)
	var mirar := func(donde: Vector2) -> void:
		Temblor.desplazamiento = donde - johnny.position
		camara.reset_smoothing()
	suj.position = centro
	suj.process_mode = Node.PROCESS_MODE_DISABLED
	johnny.position = centro + Vector2(130, 30)
	mirar.call(centro + Vector2(60, -40))
	await espera.call(0.4)
	Captura.foto("captura-sujeto.png")
	# el fregonazo
	suj.process_mode = Node.PROCESS_MODE_INHERIT
	suj.foto(johnny, "fregonazo")
	suj.t = 0.25
	var vida: int = johnny.vida
	await espera.call(0.15)
	Captura.foto("captura-sujeto-fregonazo-aviso.png")
	await espera.call(0.3)
	Captura.foto("captura-sujeto-fregonazo.png")
	print("Fregonazo: a Johnny le quita %d (esperado: 22), le empuja %s" % [vida - johnny.vida, johnny.velocity.length() > 100.0])
	await espera.call(1.6)
	# los cubos
	johnny.position = centro + Vector2(300, 60)
	mirar.call(centro + Vector2(160, -20))
	suj.position = centro
	suj.espera.cubo = 0.0
	suj.foto(johnny, "cubo")
	suj.t = 0.2
	johnny.invulnerable = 0.0   # (con su física parada, lo invulnerable del fregonazo no se le pasa solo)
	vida = johnny.vida
	await espera.call(0.15)
	Captura.foto("captura-sujeto-cubo-aviso.png")
	await espera.call(0.55)
	Captura.foto("captura-sujeto-cubos.png")
	await espera.call(0.8)
	var charcos := get_tree().get_nodes_in_group("charcos").filter(func(c): return c.tipo == "agua_cubo")
	suj.process_mode = Node.PROCESS_MODE_DISABLED
	Captura.foto("captura-sujeto-charcos.png")
	print("Cubos: charcos de agua %d (esperado: 3), a Johnny le quita %d (esperado: 8)" % [charcos.size(), vida - johnny.vida])
	for c in charcos:
		c.queue_free()
	# rodar: las balas que le darían (bala.gd le pregunta)
	suj.process_mode = Node.PROCESS_MODE_INHERIT
	suj.andar(5.0)
	suj.rodo = -10.0
	suj.balas = 0
	var esquiva := []
	for i in 3:
		esquiva.append(suj.esquivar_bala(Vector2(-600, 0)))
	await espera.call(0.25)
	mirar.call(suj.position + Vector2(0, -40))
	Captura.foto("captura-sujeto-rodar.png")
	print("Rodar: tres balas seguidas %s (esperado: alguna true), estado %s (esperado: rodar)" % [esquiva, suj.estado])
	await espera.call(0.6)
	print("  después de rodar, otra bala enseguida: %s (esperado: false, cada 2,5 s como mucho)" % suj.esquivar_bala(Vector2(-600, 0)))
	# partirse
	suj.position = centro
	johnny.position = centro + Vector2(260, 60)
	mirar.call(centro + Vector2(60, -40))
	suj.vida = suj.vida_max / 2
	await espera.call(1.0)
	Captura.foto("captura-sujeto-partirse.png")
	print("Partirse: estado %s (esperado: partirse), cabina rota %s" % [suj.estado, lab.rota])
	await espera.call(0.9)
	var mitades: Array = suj.mitades
	for m in mitades:
		m.process_mode = Node.PROCESS_MODE_DISABLED
	await espera.call(0.1)
	Captura.foto("captura-sujeto-partido.png")
	print("Partido: mitades %d (esperado: 2), vida de cada una %s (esperado: la mitad de %d), barra %d/%d, cabina rota %s, el grande en zombis %s (esperado: false), la pelea sigue %s" % [
		mitades.size(), mitades.map(func(m): return m.vida), suj.vida_max, suj.vida, suj.vida_max, lab.rota,
		suj.is_in_group("zombis"), lab.activo()])
	# cae una: la otra se enfada
	mitades[1].process_mode = Node.PROCESS_MODE_INHERIT
	mitades[0].process_mode = Node.PROCESS_MODE_INHERIT
	mitades[0].quitar_vida(99999, Vector2.ZERO)
	await espera.call(0.5)
	mitades[1].process_mode = Node.PROCESS_MODE_DISABLED
	mirar.call(mitades[1].position + Vector2(0, -40))
	Captura.foto("captura-sujeto-enfadado.png")
	print("Cae una: la otra enfadada %s (esperado: true), velocidad %.0f (esperado: %.0f), barra %d" % [mitades[1].fase == 2,
		mitades[1].velocidad(), suj.VELOCIDAD[1] * suj.ENFADADO, suj.vida])
	# cae la otra: cae el jefe y se abre la puerta del helipuerto
	mitades[1].process_mode = Node.PROCESS_MODE_INHERIT
	mitades[1].quitar_vida(99999, Vector2.ZERO)
	var t0 := 0.0
	while not lab.salida_abierta and t0 < 8.0:
		if get_tree().paused:   # (la página del dosier: se cierra)
			get_tree().paused = false
			menus.cerrar()
		await get_tree().create_timer(0.2, true).timeout
		t0 += 0.2
	print("Caen las dos: el jefe muerto %s, vida %d, puerta del helipuerto abierta %s (esperado: true, 0, true)" % [
		planta.jefa_muerta, suj.vida, lab.salida_abierta])
