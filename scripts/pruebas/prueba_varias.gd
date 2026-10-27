# Pruebas sueltas: los niveles de alerta (--alerta N), el reto del día (--reto), la caza del acompañante (--caza)
# y el vómito de la Gastroenteritis (--gastro). Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_sitios.gd"


# Con "--captura --alerta N" (en vez de la prueba larga): comprueba las reglas de esa alerta (alerta.gd) con sus
# números en la terminal y saca captura-alerta.png (el aviso del principio), captura-alerta-llave.png (en los
# Apartamentos, el zombi que lleva la llave (con la Alerta 5, con el doble de vida; al caer suelta la llave, y al
# salir y volver a entrar no la lleva otra vez; al cogerla, el grito ¡¡¡LA LLAVE!!! encima de Johnny, en
# captura-alerta-llave-cogida.png, y su hueco encendido en el inventario, en captura-alerta-llave-inventario.png; la
# llave en el suelo, en captura-alerta-llave-suelo.png);
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
	print("A4 · un botiquín cura %d (sin alerta, %d)" % [cura_botiquin(), BOTIQUIN + johnny.stats.botiquin_extra])
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
					# la llave en el suelo, con un bidón de ácido al lado para comparar el tamaño y Johnny cerca
					# (captura-alerta-llave-suelo.png)
					soltar_objeto("bidon_acido", planta.llave.pos + Vector2(60, 0))
					johnny.position = planta.llave.pos + Vector2(0, 90)
					johnny.get_node("Camara").reset_smoothing()
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
