# Pruebas sueltas: los niveles de alerta (--alerta N), el reto del día (--reto), la caza del acompañante (--caza),
# el vómito de la Gastroenteritis (--gastro), la llave en el suelo (--llave) y los números del equilibrio (--equilibrio).
# Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_sitios.gd"


# Con "--captura --alerta N" (en vez de la prueba larga): comprueba las reglas de esa alerta (alerta.gd) con sus
# números en la terminal y saca captura-alerta.png (el aviso del principio), captura-alerta-llave.png (en los
# Apartamentos, el zombi que lleva la llave (con la Alerta 5, con el doble de vida; al caer suelta la llave, y al
# salir y volver a entrar no la lleva otra vez; al cogerla, el grito ¡¡¡LA LLAVE!!! encima de Johnny, en
# captura-alerta-llave-cogida.png, y su hueco encendido en el inventario, en captura-alerta-llave-inventario.png; la
# llave en el suelo, con su resplandor, en captura-alerta-llave-suelo.png y, con la penumbra, en
# captura-alerta-llave-suelo-oscuro.png);
# en el centro comercial, el guardia) y
# captura-alerta-fin.png (el cartel del final con los dólares de más y la alerta que se abre). Luego se cierra
func probar_alerta() -> void:
	var n := Alerta.nivel
	print("Prueba de la %s en %s: %s" % [Alerta.nombre(), ed.el_nombre, Alerta.REGLAS[n]])
	decir("%s: %s
%s: %s" % [planta.nombre, ed.objetivo, Alerta.nombre(), Alerta.REGLAS[n]], 4.0)
	await get_tree().create_timer(0.5, false).timeout
	Captura.foto("captura-alerta.png")
	# A1: los zombis de cinco plantas, sin alerta y con ella (las mismas: con las mismas semillas)
	var contar := func() -> String:
		var total := 0
		var coste := 0.0   # lo que "cuestan" (planta.gd, COSTE): los caros son los duros
		for i in 5:
			Planta.semilla = 1000 + i
			for s in Planta.generar(2, edificio, jefe_de(2)).sitios:
				for z in s.get("zombis", []):
					total += 1
					coste += Planta.COSTE[z.tipo]
		Planta.semilla = 0
		return "%d (coste %.0f)" % [total, coste]
	Alerta.nivel = 0
	var sin: String = contar.call()
	Alerta.nivel = n
	print("A1 · zombis en cinco plantas: %s sin alerta, %s con ella (x%.2f)" % [sin, contar.call(), Alerta.mas_zombis()])
	# A2 y A3: un zombi normal y el jefe de la planta, recién sacados
	var normal := meter_zombi("normal", Vector2(200, 200))
	var jefe := meter_zombi("portera", Vector2(300, 200))
	print("A2 · velocidad del zombi normal: %.0f (sin alerta, %.0f)" % [normal.velocidad, ZOMBIS.normal.instantiate().velocidad])
	print("A3 · vida de la portera en la planta baja: %d · se enfada a %d %% de la vida" % [jefe.vida_max, roundi(jefe.enfado * 100)])
	normal.queue_free()
	jefe.queue_free()
	$Pantalla/Jefa.hide()
	# A4 y A5
	print("A4 · un botiquín cura %d (sin alerta, %d)" % [cura_de("botiquin"), Objetos.USABLES.botiquin.cura + johnny.stats.botiquin_extra])
	print("A5 · los disparos se oyen a %.0f (sin alerta, %.0f)" % [Zombi.OIDO * Alerta.oido(), Zombi.OIDO])
	# el guardia (centro) o el zombi de la llave (Apartamentos), en su sitio y sin penumbra para que se vea bien
	if ed.cerrojo == "tarjeta":
		await montar(0, 0, false)
		print("A5 · el guardia: vida %d" % guardia.vida_max)
		johnny.position = guardia.position + Vector2(-160, 40)   # (que no se quede en la puerta, que la cruzaría)
	else:
		var vecino := -1
		var con_llave := 0
		for i in planta.sitios.size():
			var cuantos: int = planta.sitios[i].get("zombis", []).filter(func(z): return z.get("llave", false)).size()
			con_llave += cuantos
			if cuantos > 0:
				vecino = i
		print("Llave · en el suelo: %s | zombis que la llevan: %d, en %s (esperado: ninguna en el suelo y uno)" % [
			planta.llave.sitio >= 0, con_llave, planta.sitios[vecino].nombre if vecino >= 0 else "ningún sitio"])
		if vecino >= 0:
			await montar(vecino, 0, false)
			for z in get_tree().get_nodes_in_group("zombis"):
				if z.has_meta("llave"):
					print("Llave · el zombi (%s): vida %d (el doble solo con la Alerta 5)" % [
						z.scene_file_path.get_file().get_basename(), z.vida_max])
					johnny.position = z.position + Vector2(0, 90)
					for k in 16:   # Johnny, cerca de él y en su misma habitación
						var p: Vector2 = z.position + Vector2.from_angle(k * TAU / 16.0) * 90.0
						if mapa.zona_en(p) == z.zona:
							johnny.position = p
							break
					luz.alternar()
					johnny.get_node("Camara").reset_smoothing()
					await get_tree().create_timer(0.4, false).timeout
					Captura.foto("captura-alerta-llave.png")
					luz.alternar()
					z.recibir_golpe(9999, Vector2.ZERO)
					await get_tree().create_timer(0.5, false).timeout
					print("Llave · al caer: llave en %s, en el suelo: %s" % [planta.sitios[planta.llave.sitio].nombre
						if planta.llave.sitio >= 0 else "ningún sitio", mapa.cosas.has_node("Llave")])
					# si sale del sitio sin limpiar y vuelve, la llave sigue en el suelo y nadie más la lleva
					await montar(vecino, 0, false)
					await get_tree().create_timer(0.4, false).timeout
					print("Llave · al volver a entrar: zombis con llave %d, llave en el suelo: %s (esperado: 0 y true)" % [
						get_tree().get_nodes_in_group("zombis").filter(func(o): return o.has_meta("llave")).size(),
						mapa.cosas.has_node("Llave")])
					# la llave en el suelo, con Johnny cerca (captura-alerta-llave-suelo.png)
					johnny.position = planta.llave.pos + Vector2(0, 90)
					johnny.get_node("Camara").reset_smoothing()
					await get_tree().create_timer(0.3, false).timeout
					Captura.foto("captura-alerta-llave-suelo-oscuro.png")   # (con la penumbra de siempre: el resplandor)
					luz.alternar()   # (sin penumbra, para que se vea bien)
					await get_tree().create_timer(0.3, false).timeout
					Captura.foto("captura-alerta-llave-suelo.png")
					luz.alternar()
					# y Johnny la coge: sale el grito encima de él (captura-alerta-llave-cogida.png)
					johnny.position = planta.llave.pos
					johnny.get_node("Camara").reset_smoothing()
					await get_tree().create_timer(0.3, false).timeout
					print("Llave · al cogerla: la lleva %s, en el suelo: %s (esperado: true y false)" % [
						planta.tiene_llave, mapa.cosas.has_node("Llave")])
					Captura.foto("captura-alerta-llave-cogida.png")
					# y en el inventario, su hueco encendido (captura-alerta-llave-inventario.png)
					abrir_cosas("inventario")
					await get_tree().create_timer(0.4).timeout   # (con el juego en pausa: el temporizador de siempre)
					Captura.foto("captura-alerta-llave-inventario.png")
					inventario.cerrar()
					break
	if ed.cerrojo == "tarjeta":
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.4, false).timeout
		Captura.foto("captura-alerta-llave.png")
	# el final: con 50 dólares recogidos, y la alerta de la partida como la más alta abierta
	Guardado.cambiar(func(g): Guardado.edificio(g, edificio).alerta_max = n)
	dolares = 50
	planta.num = Planta.PLANTAS
	terminar(true)
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-alerta-fin.png")
	var e: Dictionary = Guardado.cargar().edificios[edificio]
	print("Final · dólares: 50 + %d · alerta más alta abierta: %d" % [Alerta.dolares_extra(50), e.alerta_max])
	get_tree().quit()


# Con "--captura --reto" (y "--reto oscuras", "--reto cuerpo"..., con esa regla en vez de la de hoy): la prueba
# del reto del día (reto.gd). Saca el aviso del principio (captura-reto.png); comprueba que la 1ª planta sale
# igual dos veces con la semilla de hoy y distinta con la de otro día; dice en la terminal lo que cambia cada
# regla y, con la que se juega, cómo queda el primer piso (armaritos, balas, lanzables, lo oscuro que está:
# captura-reto-piso.png); y acaba dos veces, cayendo en la 3ª planta (captura-reto-derrota.png) y completando
# el edificio (captura-reto-fin.png, con la marca mejorada). Al final mira el guardado: la marca de hoy, y que
# el edificio sigue sin contar como completado y sin abrir alertas
func probar_reto() -> void:
	print("Reto del día (%s) en %s: %s · %s · semilla %d" % [Reto.fecha, ed.el_nombre, Reto.nombre(), Reto.desc(), Planta.semilla])
	decir("%s: %s
%s" % [planta.nombre, ed.objetivo, Reto.aviso()], 4.0)
	await get_tree().create_timer(0.5, false).timeout
	Captura.foto("captura-reto.png")
	# la 1ª planta, dos veces con la semilla de hoy y una con la de otro día
	var una := var_to_str(Planta.generar(2, edificio, jefe_de(2)).sitios)
	var otra := var_to_str(Planta.generar(2, edificio, jefe_de(2)).sitios)
	var semilla := Planta.semilla
	Planta.semilla = Reto.semilla_de("2000-01-01", edificio)
	var de_otro_dia := var_to_str(Planta.generar(2, edificio, jefe_de(2)).sitios)
	Planta.semilla = semilla
	print("Semilla · la 1ª planta sale igual dos veces: %s · con la de otro día, distinta: %s" % [una == otra, una != de_otro_dia])
	# lo que cambia cada regla (la vida de Johnny y la velocidad de un zombi normal, recién puestos)
	var regla := Reto.regla
	var talentos: Dictionary = Guardado.cargar().talentos
	for r in Reto.REGLAS:
		Reto.regla = r
		aplicar_talentos(talentos)
		var z := meter_zombi("normal", Vector2(200, 200))
		print("%s · munición: %s · oscuras: %s · curas: %s · velocidad %.0f · vida %d · zombis x%.1f · oído %.0f" % [
			Reto.nombre(), not Reto.sin_municion(), Reto.oscuras(), not Reto.sin_curas(),
			z.velocidad, johnny.stats.vida_max, Reto.mas_zombis(), Zombi.OIDO * Reto.oido()])
		z.queue_free()
	Reto.regla = regla
	aplicar_talentos(talentos)
	# con la regla que se juega, el primer piso: los armaritos, las balas y los lanzables, y lo oscuro que está
	var piso := 1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "apartamento":
			piso = i
			break
	await montar(piso, 0, false)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.4, false).timeout
	var lamparas := mapa.find_children("*", "", true, false).filter(func(n): return n.scene_file_path == Eventos.LAMPARA)
	print("Con «%s», en %s · armaritos vacíos: %d de %d · balas %d (+%d) · molotovs %d, granadas %d · oscuridad %.2f (Luz.evento %.2f) · lámparas apagadas: %d de %d · arriba: «%s»" % [
		Reto.nombre(), planta.sitios[piso].nombre, mapa.armaritos.filter(func(a): return a.datos.cogido).size(), mapa.armaritos.size(),
		johnny.balas, johnny.reserva(), lanzables.cantidades.molotov, lanzables.cantidades.granada, Luz.nivel, Luz.evento,
		lamparas.filter(func(n): return n.fuerza == 0.0).size(), lamparas.size(), lugar.text])
	Captura.foto("captura-reto-piso.png")
	# el final, dos veces: cayendo en la 3ª planta y luego completando el edificio (las dos mejoran la marca de hoy)
	var antes: Dictionary = Guardado.cargar().edificios[edificio].duplicate()
	planta.num = 3
	planta.nombre = Planta.nombre_planta(3)
	terminar(false)
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-reto-derrota.png")
	var f: Dictionary = Guardado.cargar().retos[edificio]
	print("Caída en la %s · marca de hoy: %s · intentos: %d" % [planta.nombre.to_lower(), Reto.marca(f), f.intentos])
	terminada = false
	planta.num = Planta.PLANTAS
	planta.nombre = Planta.nombre_planta(Planta.PLANTAS)
	dolares = 50
	terminar(true)
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-reto-fin.png")
	var s := Guardado.cargar()
	f = s.retos[edificio]
	var e: Dictionary = s.edificios[edificio]
	print("Completado · marca de hoy: %s (regla %s, intentos %d) · dólares ahorrados: %d" % [Reto.marca(f), f.regla, f.intentos, s.dolares])
	print("El edificio sigue igual (completado %s, victorias %d, alerta más alta %d, mejor planta %d, mejor tiempo %.0f): %s" % [
		e.completado, e.victorias, e.alerta_max, e.mejor_planta, e.mejor_tiempo,
		e.completado == antes.completado and e.victorias == antes.victorias and e.alerta_max == antes.alerta_max
		and e.mejor_planta == antes.mejor_planta and e.mejor_tiempo == antes.mejor_tiempo])
	get_tree().quit()


# Con "--captura --hud": el HUD (hud.gd), con las armas y los lanzables en la esquina de abajo a la derecha. Con
# tres lanzables a mano, saca el HUD quieto (captura-hud.png), a medio cambiar de arma con la Q
# (captura-hud-cambio.png), ya cambiada, sin el nombre encima (captura-hud-q.png), a medio cambiar de lanzable con la
# F (captura-hud-f.png), el aviso del modo de atacar (captura-hud-modo.png) y como va en el móvil, al lado de la barra (captura-hud-movil.png). Se cierra
func probar_hud() -> void:
	set_process(false)
	for t in ["granada", "atraedora"]:
		lanzables.meter(t, 2)
		lanzables.a_la_mano(t)
	await get_tree().create_timer(0.5).timeout
	print("HUD · lanzables a mano: %s, el de ahora: %s" % [lanzables.tipos(), lanzables.tipo])
	Captura.foto("captura-hud.png")
	johnny.cambiar_mano()
	await get_tree().create_timer(0.1).timeout
	Captura.foto("captura-hud-cambio.png")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-hud-q.png")
	lanzables.cambiar()
	await get_tree().create_timer(0.08).timeout
	Captura.foto("captura-hud-f.png")
	# el modo de atacar con su tecla (F1 o C): ya no hay línea de teclas abajo, sale un aviso
	var modo_antes: String = johnny.modo
	johnny.cambiar_modo()
	await get_tree().create_timer(0.3).timeout
	print("HUD · modo de atacar: %s → %s, aviso: %s" % [modo_antes, johnny.modo, aviso.text])
	Captura.foto("captura-hud-modo.png")
	johnny.poner_modo(modo_antes)
	Guardado.cambiar(func(g): g.ajustes.modo = modo_antes)
	await get_tree().create_timer(0.5).timeout
	Tactil.activo = true   # (solo el HUD: los botones del móvil no se montan a mitad de partida)
	await get_tree().create_timer(0.1).timeout
	Captura.foto("captura-hud-movil.png")
	Tactil.activo = false
	get_tree().quit()


# Con "--captura --llave": la llave de la jefa en el suelo (mapa.poner_llave), en la habitación más grande de un
# apartamento sin zombis y con la penumbra de siempre, con un arma épica al lado (soltar_arma: su luz morada también
# alumbra el suelo). Tres fotos: con la luz blanca de la llave (captura-llave-con.png), sin ella, oculta
# (captura-llave-sin.png), y con todo iluminado (captura-llave-luz.png). Se cierra
func probar_llave() -> void:
	set_process(false)
	var i := 1   # el apartamento con más habitaciones
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and planta.sitios[j].tipo != "viviendas" and (not planta.sitios[i].has("apt")
				or planta.sitios[j].apt.salas.size() > planta.sitios[i].apt.salas.size()):
			i = j
	await montar(i, 0, false)
	var apt: Dictionary = planta.sitios[i].apt
	for sala in apt.salas:
		mapa.vistas[sala.id] = true   # todo descubierto: sin niebla
		mapa.niebla[sala.id] = 0.0
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var grande: Dictionary = apt.salas[0]
	for s in apt.salas:
		if s.casillas > grande.casillas:
			grande = s
	# Johnny en medio de la habitación y la llave a 90 de él (donde siga siendo la misma habitación), con el bidón al lado
	var llave_en: Vector2 = grande.centro + Vector2(0, -90)
	for d in [Vector2(0, -90), Vector2(0, 90), Vector2(-90, 0), Vector2(90, 0)]:
		if mapa.zona_en(grande.centro + d) == grande.id:
			llave_en = grande.centro + d
			break
	johnny.position = grande.centro
	mapa.poner_llave(llave_en)
	soltar_arma("bate", llave_en + Vector2(70, 0), 3)   # y un arma épica al lado: su luz morada, como la de la llave pero de su color
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.7, false).timeout
	print("Llave en el suelo: la llave existe %s · su resplandor %s (esperado: true y true)" % [
		mapa.cosas.has_node("Llave"), mapa.cosas.get_node("Llave").has_node("Resplandor")])
	Captura.foto("captura-llave-con.png")
	var resplandor: PointLight2D = mapa.cosas.get_node("Llave/Resplandor")
	resplandor.visible = false
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-llave-sin.png")
	resplandor.visible = true
	luz.alternar()   # (sin penumbra)
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-llave-luz.png")
	get_tree().quit()


# Con "--captura --caza": el acompañante va a por los zombis que ve (aliado.gd, cazar). En un apartamento con todo
# descubierto, solo el ferretero (martillo, alcance 80) acompaña a Johnny, quieto en lo más despejado de la habitación
# más grande. Un zombi en otra habitación, con pared en medio: el ferretero se queda en la fila. Otro despierto y
# quieto a unos 250, a la vista: deja la fila y va a por él (captura-caza-va.png), le da martillazos hasta matarlo y
# vuelve a su puesto junto a Johnny (captura-caza-vuelve.png). Cuenta en la terminal distancias y vida, con lo esperado
func probar_caza() -> void:
	set_process(false)
	var i := 1   # el apartamento con más habitaciones
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and planta.sitios[j].tipo != "viviendas" and (not planta.sitios[i].has("apt")
				or planta.sitios[j].apt.salas.size() > planta.sitios[i].apt.salas.size()):
			i = j
	await montar(i, 0, false)
	var sitio: Dictionary = planta.sitios[i]
	var apt: Dictionary = sitio.apt
	for sala in apt.salas:
		mapa.vistas[sala.id] = true   # todo descubierto: nada a oscuras
		mapa.niebla[sala.id] = 0.0
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	# solo el ferretero en el equipo (el guardado de la prueba trae al policía, que mataría al zombi a tiros desde la fila)
	for a in supervivientes.equipo:
		a.queue_free()
	supervivientes.equipo.clear()
	var datos: Dictionary = Supervivientes.DATOS.ferretero.duplicate()
	datos.erase("rescate")
	var ferre: Aliado = supervivientes.crear(datos, "equipo")
	ferre.idx = 0
	supervivientes.equipo.append(ferre)
	mapa.cosas.add_child(ferre)
	# Johnny, quieto en lo más despejado de la habitación más grande; el ferretero, a su lado
	var grande: Dictionary = apt.salas[0]
	for s in apt.salas:
		if s.casillas > grande.casillas:
			grande = s
	johnny.position = grande.centro
	johnny.direccion = "e"
	johnny.get_node("Camara").reset_smoothing()
	ferre.position = johnny.position + Vector2(-40, 20)
	Aliado.borrar_huellas()
	await get_tree().create_timer(0.8).timeout
	var d_fila: float = ferre.position.distance_to(johnny.position)
	# 1) un zombi en otra habitación, con pared en medio: no lo ve, así que se queda en la fila
	var otra: Dictionary = {}
	for s in apt.salas:
		if s.id != grande.id and not mapa.muro_entre(ferre.position, s.centro).is_empty() and otra.is_empty():
			otra = s
	if otra.is_empty():
		print("Caza: ninguna habitación con pared en medio (no se prueba lo de no verlo)")
	else:
		var tras := meter_zombi("normal", otra.centro)
		tras.dormido = false
		tras.set_physics_process(false)
		await get_tree().create_timer(1.5).timeout
		print("Caza, zombi en otra habitación (a %d, con pared): el ferretero sigue en la fila, a %d de Johnny (esperado: menos de 80) · de caza %s (esperado: false)" % [
			roundi(ferre.position.distance_to(tras.position)), roundi(ferre.position.distance_to(johnny.position)), ferre.cazando])
		tras.queue_free()
		await get_tree().process_frame
	# 2) un zombi despierto y quieto a unos 250, a la vista, en la misma habitación
	var donde := Vector2.INF
	for lejos in [250.0, 200.0, 160.0]:
		for k in 64:
			var pos: Vector2 = johnny.position + Vector2.from_angle(k * TAU / 64.0) * lejos
			if donde == Vector2.INF and Planta.despejado(apt, pos, 20.0, grande.id) and Planta.lejos_de_muebles(sitio, pos, 34.0) \
					and mapa.muro_entre(ferre.position, pos).is_empty():
				donde = pos
		if donde != Vector2.INF:
			break
	if donde == Vector2.INF:
		print("Caza: no hay sitio para el zombi a la vista (¡mal!)")
		get_tree().quit()
		return
	var z := meter_zombi("normal", donde)
	z.dormido = false
	z.set_physics_process(false)   # quieto: ni anda ni ataca, para medir
	var d0: float = ferre.position.distance_to(z.position)
	await get_tree().create_timer(0.7).timeout
	print("Caza, zombi a la vista a %d de Johnny: el ferretero va a por él, de %d a %d (esperado: baja) · a %d de Johnny (esperado: más de %d) · de caza %s (esperado: true)" % [
		roundi(johnny.position.distance_to(z.position)), roundi(d0), roundi(ferre.position.distance_to(z.position)),
		roundi(ferre.position.distance_to(johnny.position)), roundi(d_fila), ferre.cazando])
	Captura.foto("captura-caza-va.png")
	var t := 0.0
	while is_instance_valid(z) and z.estado != "muerto" and t < 8.0:
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	var como: String = "muerto" if not is_instance_valid(z) or z.estado == "muerto" else "vivo con %d" % z.vida
	print("Caza: a los %.1f s el zombi está %s (esperado: muerto) · el ferretero a %d de donde estaba el zombi (esperado: menos de 100)" % [
		t, como, roundi(ferre.position.distance_to(donde))])
	await get_tree().create_timer(2.5).timeout
	print("Caza: sin zombis a la vista, vuelve a la fila: a %d de Johnny (esperado: menos de 80) · de caza %s (esperado: false)" % [
		roundi(ferre.position.distance_to(johnny.position)), ferre.cazando])
	Captura.foto("captura-caza-vuelve.png")
	get_tree().quit()


# Con "--captura --gastro": el vómito de Gastroenteritis (mutaciones.gd) no cruza las paredes. En un apartamento,
# Johnny pegado a un tabique con un zombi justo detrás: el vómito no sale (no lo ve). El charco del vómito junto al
# tabique no quema a ese zombi, pero sí a otro de este lado. Y con otro zombi más lejos pero a la vista, el vómito
# sale a ese (captura-gastro-vuelo.png, captura-gastro-charco.png). Cuenta todo en la terminal y se cierra
func probar_gastro() -> void:
	set_process(false)
	var i := 1   # el apartamento con más habitaciones
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and planta.sitios[j].tipo != "viviendas" and (not planta.sitios[i].has("apt")
				or planta.sitios[j].apt.salas.size() > planta.sitios[i].apt.salas.size()):
			i = j
	await montar(i, 0, false)
	var sitio: Dictionary = planta.sitios[i]
	for sala in sitio.apt.salas:
		mapa.vistas[sala.id] = true   # todo descubierto: nada a oscuras
		mapa.niebla[sala.id] = 0.0
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().process_frame
	# un tabique de una casilla con una habitación a cada lado, a la altura de una fila (Johnny a un lado, el zombi al otro)
	var johnny_en := Vector2.INF
	var tras_en := Vector2.INF
	var dc := 1
	for f in range(3, mapa.filas - 3):
		for c in range(3, mapa.cols - 3):
			for d in [1, -1]:
				var a: int = mapa.dueno[f * mapa.cols + c]
				var b: int = mapa.dueno[f * mapa.cols + c + 2 * d]
				if a >= 0 and b >= 0 and a != b and mapa.dueno[f * mapa.cols + c + d] == -1 and johnny_en == Vector2.INF \
						and mapa.dueno[f * mapa.cols + c - d] == a and mapa.dueno[f * mapa.cols + c + 3 * d] == b:
					dc = d
					johnny_en = Vector2(c + 0.5, f + 0.5) * 32.0
					tras_en = johnny_en + Vector2(52.0 * d, 0)   # 4 de la pared hacia dentro: dentro del charco
	if johnny_en == Vector2.INF:
		print("Gastro: no he encontrado ningún tabique (¡mal!)")
		get_tree().quit()
		return
	johnny.position = johnny_en
	johnny.get_node("Camara").reset_smoothing()
	var tras := meter_zombi("normal", tras_en)
	tras.set_physics_process(false)   # quietos, para la prueba
	var vomitos := func() -> Array:
		return johnny.get_parent().get_children().filter(func(n): return n.get("tipo") == "vomito" and not n.is_in_group("charcos"))
	# 1) solo hay un zombi, y está tras la pared (a unos 52 de Johnny, muy a tiro): no debe lanzar
	var lanzo: bool = mutaciones.actuar("gastro")
	print("Gastro, un zombi tras la pared (a %d): ¿lanza? %s (esperado: false) · vómitos en el aire %d (esperado: 0)" % [
		roundi(johnny.position.distance_to(tras.position)), lanzo, vomitos.call().size()])
	# 2) un charco de vómito en los pies de Johnny, pegado al tabique: no quema al de detrás pero sí a uno de este lado
	var cerca := meter_zombi("normal", johnny_en - Vector2(28.0 * dc, 0))
	cerca.set_physics_process(false)
	var charco: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
	charco.tipo = "vomito"
	charco.position = johnny_en
	johnny.get_parent().add_child(charco)
	await get_tree().create_timer(0.4).timeout
	print("Gastro, charco pegado al tabique: el de este lado lo pisa %s (esperado: true) · el de detrás lo pisa %s (esperado: false)" % [
		cerca.pisando.has("acido"), tras.pisando.has("acido")])
	Captura.foto("captura-gastro-charco.png")
	charco.queue_free()
	# 3) otro zombi, más lejos que el de detrás pero a la vista: el vómito sale a ese y cae en él, no en la pared
	var lejos_en := Vector2.INF
	for f in range(2, mapa.filas - 2):
		for c in range(2, mapa.cols - 2):
			var pos := Vector2(c + 0.5, f + 0.5) * 32.0
			var dist := pos.distance_to(johnny_en)
			if dist > 110.0 and dist < 260.0 and mapa.dueno[f * mapa.cols + c] == mapa.dueno[int(johnny_en.y / 32.0) * mapa.cols + int(johnny_en.x / 32.0)] \
					and mapa.muro_entre(johnny_en, pos).is_empty() and Planta.lejos_de_muebles(sitio, pos, 34.0) and lejos_en == Vector2.INF:
				lejos_en = pos
	if lejos_en == Vector2.INF:
		print("Gastro: no he encontrado sitio para el zombi lejano (¡mal!)")
		get_tree().quit()
		return
	var lejos := meter_zombi("normal", lejos_en)
	lejos.set_physics_process(false)
	cerca.queue_free()
	await get_tree().process_frame   # que ya no esté en el grupo: si no, el vómito iría a él (el más cercano)
	lanzo = mutaciones.actuar("gastro")
	var aire: Array = vomitos.call()
	var cae := Vector2.INF
	if not aire.is_empty():
		cae = aire[0].hasta
	print("Gastro, con otro zombi a %d a la vista: ¿lanza? %s (esperado: true) · cae a %d de ese zombi y a %d del de detrás de la pared" % [
		roundi(johnny.position.distance_to(lejos.position)), lanzo, roundi(cae.distance_to(lejos.position)), roundi(cae.distance_to(tras.position))])
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-gastro-vuelo.png")
	await get_tree().create_timer(0.6).timeout
	print("Gastro: el charco cae sobre el zombi a la vista, que lo pisa %s (esperado: true) · el de detrás de la pared %s (esperado: false)" % [
		lejos.pisando.has("acido"), tras.pisando.has("acido")])
	get_tree().quit()


# Con "--captura --equilibrio": los números del equilibrio del 27 oct, contados en la terminal con lo esperado. En el
# apartamento más grande, sin zombis: los talentos y la skin se suman (Ataque 5 y Camorrista 5 con el gymbro y con el
# portero); el daño mínimo de un golpe (Durito 5 con Insensible); Ninja (mata al zombi de al lado, pero como mucho una
# vez cada 3 s; lo que le quitaría a un jefe); Lobezno (1 cada 5 s; con la Alerta 4, cada 10); la fregona, el
# cuchillo, la MP5 y la cura de la médica; su propia granada a los pies (como mucho 25); los premios del reto
# del día y los billetes de los jefes. La segunda parte (27 oct, tarde): el tope de curas (2 botiquines y 3 vendas; un
# armarito abierto con la mochila llena deja el botiquín en el suelo con «Ya llevas 2», captura-equilibrio-tope.png) y
# qué hay en los armaritos de la planta; Ninja con el guardia o el zombi de la llave (un 25 %); los números de los
# jefes, las mutaciones y los aliados; el reto «Sin curas» en la farmacia. Al final sube a la planta 2 con el incendio
# superado: el aviso con su premio (captura-equilibrio-incendio.png). Se cierra
func probar_equilibrio() -> void:
	set_process(false)
	var i := 1   # el apartamento con más habitaciones
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and planta.sitios[j].tipo != "viviendas" and (not planta.sitios[i].has("apt")
				or planta.sitios[j].apt.salas.size() > planta.sitios[i].apt.salas.size()):
			i = j
	await montar(i, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var grande: Dictionary = planta.sitios[i].apt.salas[0]
	for s in planta.sitios[i].apt.salas:
		if s.casillas > grande.casillas:
			grande = s
	johnny.position = grande.centro
	johnny.modo = "quieto"   # que no pegue ni dispare solo
	var antes: Dictionary = johnny.stats.duplicate()
	var skin_antes: String = johnny.skin

	# ── Los talentos y la skin se suman ──
	johnny.stats.dano = 1.5
	johnny.stats.dano_cuerpo = 1.5
	johnny.coger("cuchillo")
	johnny.vestir("gymbro")
	var cuchillo: float = johnny.arma().dano
	johnny.coger("fregona")
	johnny.vestir("portero")
	var fregona: float = johnny.arma().dano
	print("Ataque 5 + Camorrista 5: cuchillo con el gymbro %.1f (esperado: 9 × 2,5 = 22,5) · fregona con el portero %.1f (esperado: 10 × 3 = 30)" % [
		cuchillo, fregona])
	johnny.vestir(skin_antes)

	# ── El daño mínimo de un golpe ──
	johnny.stats.esquiva_sola = 0
	johnny.escudo = 0.0
	johnny.stats.armadura = 5
	johnny.stats.dano_recibido = 0.5
	johnny.invulnerable = 0.0
	var v0: int = johnny.vida
	johnny.recibir_dano(10)
	var con_las_dos: int = v0 - johnny.vida
	johnny.stats.dano_recibido = 1.0
	johnny.invulnerable = 0.0
	v0 = johnny.vida
	johnny.recibir_dano(10)
	print("Un golpe de 10 con Durito 5 e Insensible quita %d (esperado: 3) · con Durito 5 solo, %d (esperado: 5)" % [
		con_las_dos, v0 - johnny.vida])

	# ── Ninja: sin moverse en la esquiva (velocidad 0), un zombi duro pegado a Johnny ──
	johnny.invencible = true
	johnny.stats.ninja = true
	johnny.stats.velocidad = 0.0
	johnny.ninja_t = 0.0
	var muere := []
	for espera in [0.0, 1.2, 2.0]:   # esquivas a 0, ~1,5 y ~3,8 s: la del medio cae dentro de los 3 s
		await get_tree().create_timer(espera, false).timeout
		var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(40, 0))
		zombi.vida = 500
		await get_tree().process_frame
		johnny.esquiva_espera = 0.0
		johnny.esquivar(Vector2.RIGHT)
		await get_tree().create_timer(0.3, false).timeout
		muere.append(not is_instance_valid(zombi) or zombi.estado == "muerto")
		if is_instance_valid(zombi):
			zombi.queue_free()
	print("Ninja: el zombi de al lado muere en cada esquiva %s (esperado: [true, false, true]) · a un jefe de 1500 le quitaría %d (esperado: 30)" % [
		muere, ceili(1500 * johnny.NINJA_JEFE)])
	johnny.invencible = false

	# ── Lobezno: 1 punto, por debajo del tope del tercio ──
	johnny.stats.regenera = 1
	johnny.vida = johnny.vida_tope() - 10
	johnny.regenera_t = 0.0
	v0 = johnny.vida
	await get_tree().create_timer(5.3, false).timeout
	var sin_alerta: int = johnny.vida - v0
	Alerta.nivel = 4
	johnny.regenera_t = 0.0
	v0 = johnny.vida
	await get_tree().create_timer(5.3, false).timeout
	var a_medias: int = johnny.vida - v0
	await get_tree().create_timer(5.0, false).timeout
	print("Lobezno 1: en 5,3 s cura %d (esperado: 1) · con la Alerta 4, en 5,3 s %d y en 10,3 s %d (esperado: 0 y 1)" % [
		sin_alerta, a_medias, johnny.vida - v0])
	Alerta.nivel = 0
	johnny.stats = antes

	# ── Las armas, la médica y la granada propia ──
	var fr: Dictionary = Armas.datos("fregona")
	var cu: Dictionary = Armas.datos("cuchillo")
	var mp: Dictionary = Armas.datos("mp5")
	var med: Dictionary = Supervivientes.DATOS.medico.habilidad
	print("Fregona %d por golpe (esperado: 10) · cuchillo %.1f golpes por segundo (esperado: 3.0) · MP5 %d por bala (esperado: 5) · la médica cura %d cada %.1f s (esperado: 5 cada 6.0)" % [
		fr.dano, cu.ritmo, mp.dano, med.cura, med.cada])
	# una granada a los pies de Johnny: le quita como mucho 25 (menos, si lleva Durito)
	johnny.invulnerable = 0.0
	johnny.escudo = 0.0
	lanzables.cantidades.granada = maxi(lanzables.cantidades.granada, 1)
	lanzables.tipo = "granada"
	lanzables.lanzar(johnny.global_position)
	v0 = johnny.vida
	await get_tree().create_timer(2.8, false).timeout
	print("Su propia granada, a sus pies, le quita %d (esperado: 25 o menos, y más de 0; Durito del guardado %d)" % [
		v0 - johnny.vida, johnny.stats.armadura])

	# ── El tope de curas y los armaritos ──
	print("Tope: con 1 botiquín cabe otro %s, con 2 %s · con 2 vendas cabe otra %s, con 3 %s (esperado: true, false, true, false)" % [
		Objetos.cabe(["botiquin"], "botiquin"), Objetos.cabe(["botiquin", "botiquin"], "botiquin"),
		Objetos.cabe(["vendas", "vendas"], "vendas"), Objetos.cabe(["vendas", "vendas", "vendas"], "vendas")])
	var dentro := []
	for sitio in planta.sitios:
		if not sitio.get("armaritos", []).is_empty():
			dentro.append(sitio.armaritos.map(func(a): return a.dentro))
	print("Los armaritos de la planta, piso a piso: %s (esperado: en cada piso, botiquin y luego vendas)" % [dentro])
	if not mapa.armaritos.is_empty():
		var armarito: Node2D = mapa.armaritos[0]
		mochila.assign(["botiquin", "botiquin"])
		johnny.position = armarito.position + Vector2(0, 70)
		armarito.datos.dentro = "botiquin"
		abrir_armarito(armarito)
		await get_tree().create_timer(1.0, false).timeout
		var en_el_suelo: Array = mapa.cosas.get_children().filter(func(c): return c.get("al_no_caber") is Callable and c.al_no_caber.is_valid())
		if not en_el_suelo.is_empty():
			johnny.position = en_el_suelo[0].position   # lo pisa: no le cabe y lo dice
		await get_tree().create_timer(0.4, false).timeout
		Captura.foto("captura-equilibrio-tope.png")
		print("Armarito con 2 botiquines en la mochila: sigue habiendo %d (esperado: 2) · el botiquín se queda en el suelo %s (esperado: true)" % [
			mochila.count("botiquin"), not en_el_suelo.is_empty() and is_instance_valid(en_el_suelo[0])])
		mochila.clear()

	# ── Ninja con el guardia (o el zombi de la llave): un 25 % de su vida por golpe, no de un golpe ──
	var stats_antes: Dictionary = johnny.stats.duplicate()
	johnny.invencible = true
	johnny.stats.ninja = true
	johnny.stats.velocidad = 0.0
	johnny.ninja_t = 0.0
	var guardia_n: Node2D = meter_zombi("normal", johnny.position + Vector2(40, 0))
	guardia_n.vida_max = 180   # como el zombi de la llave con la Alerta 5 (el guardia, igual: Zombi.importante)
	guardia_n.vida = 180
	guardia_n.importante = true
	await get_tree().process_frame
	johnny.esquiva_espera = 0.0
	johnny.esquivar(Vector2.RIGHT)
	await get_tree().create_timer(0.3, false).timeout
	print("Ninja al zombi de la llave de 180: le deja %d (esperado: 135)" % (guardia_n.vida if is_instance_valid(guardia_n) else -1))
	if is_instance_valid(guardia_n):
		guardia_n.queue_free()
	johnny.invencible = false
	johnny.stats = stats_antes

	# ── Los jefes, las mutaciones y los aliados ──
	var vidas := {}
	for jefe in ["bombero", "cocinero", "modista", "mascota"]:
		var uno: Node = ZOMBIS[jefe].instantiate()
		vidas[jefe] = uno.vida_max
		uno.free()
	print("Vidas: %s (esperado: bombero 500, cocinero 500, modista 480, mascota 480)" % vidas)
	print("Bombero gira cada %s s (esperado: [22, 18]) · ácido del Glotón cada %.1f s (esperado: 1.0) · salto del Gymbro %s s (esperado: [1.1, 0.7]) · aviso del rebote de la mascota %.1f s (esperado: 0.3)" % [
		load("res://scripts/bombero.gd").ESPERA_GIRO, load("res://scripts/gloton.gd").ACIDO_CADA,
		load("res://scripts/gymbro.gd").VUELO, load("res://scripts/mascota.gd").AVISO_REBOTE])
	var mut: Dictionary = Mutaciones.MUT
	print("Mutaciones: Caníbal %.2f · Insensible %.2f · Endurecimiento %d · Ansiedad +%d %% por zombi · Locura cada %.0f s a %.0f (esperado: 0.02, 0.65, 60, 10, 4 y 200)" % [
		mut.canibal.cura, mut.insensible.dano, mut.endurecimiento.escudo, roundi(mut.ansiedad.cada_zombi * 100),
		mut.locura.cada, mut.locura.radio])
	var poli: Dictionary = Supervivientes.DATOS.policia.habilidad
	var tec: Dictionary = Supervivientes.DATOS.tecnico.habilidad
	print("Policía dispara cada %.1f s (esperado: 0.8) · el técnico aturde %.1f s cada %.1f s (esperado: 1.5 cada 3.0)" % [
		poli.cada, tec.segundos, tec.cada])
	Reto.activo = true
	Reto.regla = "curas"
	var de_farmacia := []
	for k in 6:
		de_farmacia.append(Objetos.al_azar("centro", "farmacia"))
	Reto.activo = false
	print("Reto «Sin curas» en la farmacia: %s (esperado: objetos, sin vendas ni vacíos)" % [de_farmacia])

	# ── El dinero ──
	var s := {"retos": {}}
	var primera := Reto.premio(s, "apartamentos")
	s.retos.apartamentos.completado = true
	print("Premio del reto: la primera vez de hoy $%d, ya completado $%d (esperado: 10 y 0) · billetes de un jefe %d (esperado: 8)" % [
		primera, Reto.premio(s, "apartamentos"), BILLETES_JEFA])
	eventos.evento = "incendio"
	eventos.empezado = true
	var d0: int = dolares
	await subir()
	print("Subiendo con el incendio superado: dólares %d → %d (esperado: +3) · planta %d (esperado: 2) · dice «%s»" % [
		d0, dolares, planta.num, aviso.text])
	await get_tree().create_timer(0.4, false).timeout
	Captura.foto("captura-equilibrio-incendio.png")
	get_tree().quit()


# Con "--captura --tutorial": los tutoriales (tutoriales.gd, ui/tutorial.gd). Empieza con todos sin ver: la ventana de
# «Cómo se juega» con el juego parado (captura-tutorial-ventana.png); otro pedido mientras está abierta sale detrás
# (captura-tutorial-cola.png); al cerrarlos, el juego sigue y no se repiten. La lista del apartado Tutorial desde la
# pausa (con su botón: captura-tutorial-pausa.png), con los vistos y los «???» (captura-tutorial-lista.png). El del
# baúl sale antes de abrirlo y, al cerrarlo, se abre el baúl; con la casilla de Ayudas apagada no sale ninguno. Y el
# texto de una ficha con teclado y en el móvil
func probar_tutorial() -> void:
	Tutoriales.olvidar()
	tutoriales_prueba = true
	var ventana := func() -> Tutorial:
		for h in get_children():
			if h is Tutorial and not h.is_queued_for_deletion():
				return h
		return null
	await get_tree().create_timer(0.3).timeout
	tutorial("jugar")
	await get_tree().create_timer(0.8).timeout
	print("Tutorial · «Cómo se juega» abierta: %s · juego parado: %s (esperado: true, true)" % [ventana.call() != null, get_tree().paused])
	Captura.foto("captura-tutorial-ventana.png")
	tutorial("lanzables")
	tutorial("jugar")   # (repetido: no se pone dos veces en la cola)
	print("Tutorial · en la cola: %s (esperado: jugar y lanzables)" % [cola_tutoriales])
	ventana.call().cerrar()
	await get_tree().create_timer(1.2).timeout
	var t: Tutorial = ventana.call()
	print("Tutorial · al cerrar, la siguiente: %s (esperado: lanzables)" % (t.id if t else "ninguna"))
	Captura.foto("captura-tutorial-cola.png")
	t.cerrar()
	await get_tree().create_timer(0.5).timeout
	print("Tutorial · cerrados: juego parado %s, cola %s · vistos jugar %s, lanzables %s (esperado: false, [], true, true)" % [
		get_tree().paused, cola_tutoriales, Tutoriales.visto("jugar"), Tutoriales.visto("lanzables")])
	tutorial("jugar")
	await get_tree().create_timer(0.5).timeout
	print("Tutorial · «Cómo se juega» otra vez: %s (esperado: no sale)" % ("sale" if ventana.call() else "no sale"))
	# el texto, con las teclas del jugador y con los botones del móvil
	var limpio := func(texto: String) -> String:
		var r := RegEx.create_from_string(r"\[/?color[^\]]*\]")
		return r.sub(texto, "", true)
	print("Tutorial · texto con teclado:\n" + limpio.call(Tutoriales.texto("jugar")))
	Tactil.activo = true
	print("Tutorial · texto en el móvil:\n" + limpio.call(Tutoriales.texto("lanzables")))
	Tactil.activo = false
	# la lista, desde la pausa
	pausar()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-tutorial-pausa.png")
	for b: Button in menus.fondo.find_children("*", "Button", true, false):
		if b.text == "Tutorial":
			b.pressed.emit()
	await get_tree().create_timer(0.4).timeout
	var lista: Tutorial = null
	for h in menus.get_children():
		if h is Tutorial:
			lista = h
	print("Tutorial · lista abierta desde la pausa: %s · pausa escondida: %s · ??? : %d de %d (esperado: true, true, %d)" % [
		lista != null, not menus.fondo.visible, lista.botones.values().filter(func(b): return b.disabled).size(),
		Tutoriales.LISTA.size(), Tutoriales.LISTA.size() - 2])
	lista.ver("lanzables")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-tutorial-lista.png")
	lista.cerrar()
	await get_tree().create_timer(0.2).timeout
	print("Tutorial · lista cerrada: pausa a la vista %s, abierto «%s» (esperado: true, pausa)" % [menus.fondo.visible, menus.abierto])
	seguir()
	await get_tree().create_timer(0.3).timeout
	# el del baúl, antes del baúl
	abrir_cosas("baul")
	await get_tree().create_timer(0.8).timeout
	t = ventana.call()
	print("Tutorial · al abrir el baúl, primero su ficha: %s · baúl abierto: «%s» (esperado: baul, «»)" % [
		t.id if t else "ninguna", inventario.abierto])
	t.cerrar()
	await get_tree().create_timer(0.3).timeout
	print("Tutorial · cerrada la ficha, abierto: «%s» · juego parado %s (esperado: «baul», true)" % [
		inventario.abierto, get_tree().paused])
	inventario.cerrar()
	await get_tree().create_timer(0.3).timeout
	# apagados en Opciones → Ayudas
	Guardado.cambiar(func(g): g.ajustes.tutoriales = false)
	tutorial("dolares")
	await get_tree().create_timer(0.5).timeout
	print("Tutorial · con la casilla de Ayudas apagada: %s (esperado: no sale)" % ("sale" if ventana.call() else "no sale"))
	Guardado.cambiar(func(g): g.ajustes.tutoriales = true)
	get_tree().quit()
