# Pruebas sueltas: los niveles de alerta (--alerta N), el reto del día (--reto), la caza del acompañante (--caza),
# el vómito de la Gastroenteritis (--gastro), la llave en el suelo (--llave), los números del equilibrio (--equilibrio) y
# la rama Químico de los talentos (--quimico).
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


# Con "--captura --escudo": el escudo de Acero (M23) y su barra en el HUD (M22). Mientras le queda, lo que le quitan
# sale del escudo y la vida no se toca: un golpe de 20, otro de 20 con Durito 3 (al escudo, lo rebajado), el daño poco a
# poco de un charco (quitar_vida) y el golpe que lo rompe (lo que sobra, a la vida). Fotos de la barra, pegada encima
# de la de vida y con las balas encima: llena (captura-escudo.png), recién golpeada, con lo perdido en claro
# (captura-escudo-golpe.png), y ya rota, sin barra y con las balas en su sitio (captura-escudo-roto.png). Se cierra
func probar_escudo() -> void:
	set_process(false)
	var hud: Control = $Pantalla/HUD
	johnny.escudo = 0.0
	aplicar_talentos({"acero": 1})
	johnny.vida = johnny.stats.vida_max
	await get_tree().create_timer(1.5).timeout   # (la barra se llena poco a poco)
	print("Escudo · con Acero: %d (esperado: 50), barra a la vista %s (esperado: true)" % [roundi(johnny.escudo), hud.con_escudo()])
	Captura.foto("captura-escudo.png")
	var vida: int = johnny.vida
	var golpe := func(n: int) -> void:
		johnny.invulnerable = 0.0
		johnny.recibir_dano(n)
	golpe.call(20)
	print("Escudo · golpe de 20: escudo %d, vida -%d (esperado: 30 y 0)" % [roundi(johnny.escudo), vida - johnny.vida])
	await get_tree().create_timer(0.15).timeout
	Captura.foto("captura-escudo-golpe.png")
	aplicar_talentos({"acero": 1, "durito": 3})
	golpe.call(20)
	print("Escudo · golpe de 20 con Durito 3: escudo %d, vida -%d (esperado: 13 y 0)" % [roundi(johnny.escudo), vida - johnny.vida])
	johnny.quitar_vida(4)
	print("Escudo · 4 de un charco: escudo %d, vida -%d (esperado: 9 y 0)" % [roundi(johnny.escudo), vida - johnny.vida])
	aplicar_talentos({"acero": 1})
	golpe.call(24)
	print("Escudo · golpe de 24 con 9 de escudo: escudo %d, vida -%d (esperado: 0 y 15)" % [roundi(johnny.escudo), vida - johnny.vida])
	await get_tree().create_timer(3.0).timeout   # (lo perdido, en claro, tarda en bajar como en la de vida)
	print("Escudo · roto: barra a la vista %s (esperado: false)" % hud.con_escudo())
	Captura.foto("captura-escudo-roto.png")
	get_tree().quit()


# Con "--captura --hud": el HUD (hud.gd), con las armas y los lanzables en la esquina de abajo a la derecha. Con
# tres lanzables a mano, saca el HUD quieto (captura-hud.png), a medio cambiar de arma con la Q
# (captura-hud-cambio.png), ya cambiada, sin el nombre encima (captura-hud-q.png), a medio cambiar de lanzable con la
# F (captura-hud-f.png), el aviso del modo de atacar (captura-hud-modo.png) y como va en el móvil, al lado de la barra (captura-hud-movil.png). Se cierra
func probar_hud() -> void:
	set_process(false)
	for t in ["granada", "atraedora"]:
		lanzables.meter(t, 2)
		lanzables.a_la_mano(lanzables.repuesto.find(t))
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
# portero); el daño mínimo de un golpe (Durito 3 con Insensible); Ninja (mata al zombi de al lado, pero como mucho una
# vez cada 5 s; lo que le quitaría a un jefe); Ajolote (1 cada 5 s; con la Alerta 4, cada 10); la fregona, el
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
	johnny.stats.armadura = 3   # (Durito al máximo: 3 desde el 28 oct)
	johnny.stats.dano_recibido = 0.5
	johnny.invulnerable = 0.0
	var v0: int = johnny.vida
	johnny.recibir_dano(10)
	var con_las_dos: int = v0 - johnny.vida
	johnny.stats.dano_recibido = 1.0
	johnny.invulnerable = 0.0
	v0 = johnny.vida
	johnny.recibir_dano(10)
	print("Un golpe de 10 con Durito 3 e Insensible quita %d (esperado: 3) · con Durito 3 solo, %d (esperado: 7)" % [
		con_las_dos, v0 - johnny.vida])

	# ── Ninja: sin moverse en la esquiva (velocidad 0), un zombi duro pegado a Johnny ──
	johnny.invencible = true
	johnny.stats.ninja = true
	johnny.stats.velocidad = 0.0
	johnny.ninja_t = 0.0
	var muere := []
	for espera in [0.0, 1.2, 3.5]:   # esquivas a 0, ~1,5 y ~5,3 s: la del medio cae dentro de los 5 s
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

	# ── Ajolote: 1 punto, por debajo de la mitad de la vida (hasta donde cura) ──
	johnny.stats.regenera = 1
	johnny.vida = roundi(johnny.stats.vida_max * johnny.REGENERA_TOPE) - 10
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
	print("Ajolote 1: en 5,3 s cura %d (esperado: 1) · con la Alerta 4, en 5,3 s %d y en 10,3 s %d (esperado: 0 y 1)" % [
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
		if b.text == Idioma.t("Tutorial"):   # (en francés es «Tutoriel»)
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


# Con "--captura --logros": las ayudas de Opciones apagan los logros (logros.gd, AYUDAS). Sin ayudas, se consigue Manitas;
# con cada una de las tres encendida, no. Si se enciende a media partida sale el aviso y, aunque se apague luego, esa
# partida ya no da logros (la siguiente, sí). Con ayudas, los logros que ya se tenían se siguen cobrando, el ordenador lo
# avisa y los zombis matados no suman para Exterminador (ni en el guardado). Fotos: el aviso en pantalla
# (captura-logros-aviso.png), Opciones → Ayudas (captura-logros-opciones.png) y el programa Logros del ordenador
# (captura-logros-ordenador.png). Cuenta todo en la terminal, con lo esperado, y se cierra
func probar_logros() -> void:
	set_process(false)
	await get_tree().create_timer(0.3).timeout
	var limpiar := func() -> void:
		Guardado.cambiar(func(g):
			for a in Logros.AYUDAS:
				g.ajustes[a] = false
			g.logros = {}
			g.dolares = 100
			g.muertos = 0
			g.muertos_con_ayudas = 0)
		logros.con_ayudas = false
	var poner := func(ayuda: String, valor: bool) -> void:
		Guardado.cambiar(func(g): g.ajustes[ayuda] = valor)
	var estado := func(id: String) -> String:
		return Logros.estado(Guardado.cargar(), id)
	limpiar.call()
	# 1) sin ayudas se consigue
	logros.cumplir("manitas")
	print("Logros · sin ayudas, Manitas: %s · sin_logros: %s (esperado: conseguido, false)" % [estado.call("manitas"), logros.sin_logros()])
	# 2) con cada ayuda por separado, no
	for a in Logros.AYUDAS:
		limpiar.call()
		poner.call(a, true)
		logros.cumplir("manitas")
		print("Logros · con %s, Manitas: %s · sin_logros: %s (esperado: pendiente, true)" % [a, estado.call("manitas"), logros.sin_logros()])
	# 3) encendida a media partida: avisa, y apagada otra vez la partida sigue sin logros
	limpiar.call()
	await get_tree().process_frame
	poner.call("vida_entera", true)
	await get_tree().create_timer(0.3).timeout
	print("Logros · encendida a media partida: con_ayudas %s · aviso «%s» (esperado: true, «Con ayudas encendidas, en esta partida ya no se consiguen logros»)" % [
		logros.con_ayudas, aviso.text])
	Captura.foto("captura-logros-aviso.png")
	poner.call("vida_entera", false)
	logros.cumplir("manitas")
	print("Logros · apagada otra vez, Manitas: %s · sin_logros: %s (esperado: pendiente, true: toda la partida)" % [estado.call("manitas"), logros.sin_logros()])
	# 4) los conseguidos antes se cobran igual, y el ordenador avisa
	Guardado.cambiar(func(g): g.logros = {"desahucio": "conseguido"})
	var antes: int = Guardado.cargar().dolares
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("logros")
	await get_tree().create_timer(0.3).timeout
	for sc in ordenador.ventana.find_children("*", "ScrollContainer", true, false):
		sc.scroll_vertical = 0   # la lista arriba del todo, para que se vea la nota
	await get_tree().process_frame
	Captura.foto("captura-logros-ordenador.png")
	ordenador.cobrar_logro("desahucio")
	print("Logros · con ayudas, cobrar Desahucio: %s · dólares +%d (esperado: cobrado, +20)" % [
		estado.call("desahucio"), Guardado.cargar().dolares - antes])
	await get_tree().create_timer(0.3).timeout   # (cobrar abre la ventana otra vez: que se pinte antes de cerrarla)
	ordenador.abrir("")
	ordenador.apagar()
	# 5) Exterminador: los zombis de una partida con ayudas no suman
	logros.muertos_antes = 10
	muertos = 5
	var con: int = logros.progreso("exterminador")
	logros.con_ayudas = false
	var sin: int = logros.progreso("exterminador")
	print("Logros · Exterminador, 10 de otras partidas y 5 de esta: con ayudas %d, sin ellas %d (esperado: 10, 15)" % [con, sin])
	await probar_logros_nuevos(limpiar)
	# 6) las partidas siguientes: a quien jugó con ayudas no se le cuentan en el guardado
	Guardado.cambiar(func(g): g.muertos = 20)
	logros.con_ayudas = true
	terminar(false)
	var fin := Guardado.cargar()
	print("Logros · al acabar con ayudas, 5 zombis: muertos %d, de ellos con ayudas %d · al empezar otra partida contarían %d (esperado: 25, 5, 20)" % [
		fin.muertos, fin.muertos_con_ayudas, fin.muertos - fin.muertos_con_ayudas])
	await get_tree().create_timer(0.5).timeout
	# 7) la advertencia, en Opciones → Ayudas
	var o := Opciones.abrir(self, null, johnny)
	o.ver("ayudas")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-logros-opciones.png")
	o.cerrar()
	limpiar.call()
	get_tree().quit()


# Parte de --logros: los logros del M17 (28 oct). Lo que piden los que salen del guardado (meta) y el repaso que los da
# por conseguidos (revisar), con un solo aviso para todos (captura-logros-varios.png); los de los jefes (Desahucio solo
# con la portera, Sin un rasguño, Por los pelos, Visto y no visto y Cazajefes); Racha imparable (y que un golpe la
# corta); Arsenal completo; los de ganar (Jornada exprés, Sin tiritas, las alertas, Buena compañía, Empleado del mes y,
# en el reto del día, Reto aceptado y Ninguna regla me para); Contra la marea, y el programa Logros del ordenador por
# apartados (captura-logros-temas.png, arriba, y captura-logros-temas-abajo.png). Deja el guardado como estaba
func probar_logros_nuevos(limpiar: Callable) -> void:
	var copia := Guardado.cargar()
	var claves := ["skins", "skin", "bestiario", "paginas", "encontrados", "rescatados", "talentos", "edificios",
		"logros_cuentas", "dolares"]
	limpiar.call()
	logros.repasar = true
	var estados := func(ids: Array) -> String:
		var s := Guardado.cargar()
		return ", ".join(ids.map(func(id): return "%s %s" % [id, Logros.estado(s, id)]))
	var conseguidos := func() -> Array:
		var s := Guardado.cargar()
		return Logros.LISTA.filter(func(l): return Logros.estado(s, l.id) != "pendiente").map(func(l): return l.id)
	# 1) lo que piden los que salen del guardado
	var metas := {}
	for l in Logros.LISTA:
		if l.has("mira"):
			metas[l.id] = Logros.meta(l)
	print("Logros nuevos · %d en total · metas %s (esperado: 40; comunidad 3, plantilla 3, vestuario 4, naturalista 22, investigador 10, chatarrero 8, especialista 36, conserje_total 108, arsenal 9, todas_reglas 7, cazajefes 25, empleado_mes 10, liquidacion 1, cambio_look 1)" % [
		Logros.LISTA.size(), metas])
	# 2) el repaso: con todo eso en el guardado, conseguidos de golpe y en un solo aviso
	Guardado.cambiar(func(g):
		g.skins = Skins.LISTA.keys()
		g.skin = "gymbro"
		g.bestiario = Bestiario.LISTA.keys()
		g.paginas = []
		for id in Historia.DOSIERES:
			g.paginas.append_array(Historia.DOSIERES[id].paginas.map(func(p): return p.id))
		g.encontrados = Objetos.NOMBRES.keys()
		g.rescatados = supervivientes.de_edificio("apartamentos")
		g.talentos = {}
		for t in Talentos.LISTA:
			if t.rama == "militar":
				g.talentos[t.id] = t.max
		Guardado.edificio(g, "centro").completado = true
		g.logros_cuentas = {})
	logros.revisar()
	print("Logros nuevos · repaso: %s (esperado: liquidacion, especialista, comunidad, cambio_look, vestuario, naturalista, investigador, chatarrero)" % [
		conseguidos.call()])
	await get_tree().create_timer(0.3).timeout
	print("Logros nuevos · el aviso: «%s» (esperado: ¡8 logros conseguidos! Míralos y cobra los premios en el ordenador)" % aviso.text)
	Captura.foto("captura-logros-varios.png")
	# 3) los jefes
	Guardado.cambiar(func(g): g.logros = {})
	var jefes := ["desahucio", "sin_rasguno", "por_los_pelos", "visto_y_no_visto"]
	var z1 := Node2D.new()
	johnny.vida = johnny.stats.vida_max
	logros.jefe_sale(z1)
	logros.pelea_t = 40.0
	logros.tocado_jefe = true
	logros.jefe_muerto("gloton", z1)
	print("Logros nuevos · el Glotón, 40 s de pelea, tocado y con toda la vida: %s (esperado: los cuatro pendientes)" % estados.call(jefes))
	var z2 := Node2D.new()
	johnny.vida = int(johnny.stats.vida_max * 0.05)
	logros.jefe_sale(z2)
	logros.pelea_t = 10.0
	logros.jefe_muerto("portera", z2)
	johnny.vida = johnny.stats.vida_max
	print("Logros nuevos · la portera, 10 s de pelea, sin tocar y con el 5 %% de vida: %s (esperado: los cuatro conseguidos)" % estados.call(jefes))
	z1.free()
	z2.free()
	var jefes_contados := int(Guardado.cargar().logros_cuentas.get("jefes", 0))
	Guardado.cambiar(func(g): g.logros_cuentas.jefes = 24)
	logros.jefe_muerto("gymbro", null)
	logros.revisar()
	print("Logros nuevos · jefes contados %d; con 24 y uno más: %s (esperado: 2, cazajefes conseguido)" % [
		jefes_contados, estados.call(["cazajefes"])])
	# 4) la racha: 29 seguidos no, 30 sí; un golpe la corta
	logros.racha = 0
	logros.mejor_racha = 0
	for i in 29:
		logros.zombi_muerto("pistola", false)
	var con_29 := estados.call(["racha"]) as String
	logros.zombi_muerto("pistola", false)
	logros.vida_antes = 100
	johnny.vida_cambiada.emit(90, 100)
	print("Logros nuevos · racha: con 29 %s, con 30 %s · tras un golpe racha %d, la mejor %d (esperado: pendiente, conseguido, 0, 30)" % [
		con_29, estados.call(["racha"]), logros.racha, logros.mejor_racha])
	# 5) el arsenal: con todas menos el MP5, el rifle no cuenta y el MP5 lo completa
	var sin_mp5: Array = Logros.arsenal().filter(func(id): return id != "mp5")
	Guardado.cambiar(func(g): g.logros_cuentas.armas = sin_mp5)
	logros.armas_usadas = sin_mp5.duplicate()
	logros.zombi_muerto("rifle", false)
	logros.revisar()
	var con_rifle := estados.call(["arsenal"]) as String
	logros.zombi_muerto("mp5", false)
	logros.revisar()
	print("Logros nuevos · arsenal: tras el rifle %s, tras el MP5 %s (esperado: pendiente, conseguido)" % [con_rifle, estados.call(["arsenal"])])
	# 6) ganar: con la Alerta 5, en 100 s, sin curarse, con un vecino y con 9 ganadas antes
	var ganar := ["fin_jornada", "jornada_expres", "sin_tiritas", "alerta_naranja", "alerta_maxima", "buena_compania",
		"empleado_mes", "reto_aceptado", "todas_reglas"]
	Guardado.cambiar(func(g):
		g.logros = {}
		g.logros_cuentas.victorias = 9)
	var vecino: Aliado = supervivientes.crear(Supervivientes.DATOS.policia, "equipo")
	vecino.es_vecino = true
	supervivientes.equipo.append(vecino)
	var duracion_antes := duracion
	Alerta.nivel = 5
	duracion = 100.0
	logros.curado = false
	logros.partida_ganada()
	logros.revisar()
	print("Logros nuevos · ganar con la Alerta 5: %s (esperado: los 7 primeros conseguidos, reto_aceptado y todas_reglas pendientes)" % estados.call(ganar))
	supervivientes.equipo.erase(vecino)
	vecino.free()
	# y el reto del día: en 2000 s, curándose y sin vecino; con las 7 reglas, Ninguna regla me para
	Guardado.cambiar(func(g):
		g.logros = {}
		g.logros_cuentas.victorias = 0)
	Alerta.nivel = 0
	duracion = 2000.0
	logros.curado = true
	Reto.activo = true
	Reto.regla = "cuerpo"
	logros.partida_ganada()
	var reglas: Array = Guardado.cargar().logros_cuentas.get("reglas", [])
	Guardado.cambiar(func(g): g.logros_cuentas.reglas = Reto.REGLAS.keys())
	logros.revisar()
	print("Logros nuevos · ganar el reto «cuerpo»: reglas %s · %s (esperado: [cuerpo]; fin_jornada y reto_aceptado conseguidos y, con las 7 reglas, todas_reglas; los demás pendientes, salvo buena_compania si la prueba lleva acompañante)" % [
		reglas, estados.call(ganar)])
	Reto.activo = false
	Reto.regla = ""
	duracion = duracion_antes
	logros.curado = false
	# 7) la horda del pasillo: el logro, cuando ya se ha leído lo del premio
	Guardado.cambiar(func(g): g.logros = {})
	eventos.premio()
	var al_momento := estados.call(["contra_marea"]) as String
	await get_tree().create_timer(3.8, false).timeout
	print("Logros nuevos · horda vencida: al momento %s, a los 3,8 s %s (esperado: pendiente, conseguido)" % [al_momento, estados.call(["contra_marea"])])
	# 8) el ordenador, por apartados (con unos cuantos conseguidos, cobrados y a medias)
	Guardado.cambiar(func(g):
		g.logros = {"primer_turno": "cobrado", "fin_jornada": "cobrado", "desahucio": "conseguido", "vestuario": "conseguido"}
		g.logros_cuentas = {"jefes": 7, "victorias": 3, "armas": ["fregona", "pistola", "bate"]}
		g.skins = ["portero", "gloton"]
		g.skin = ""
		g.rescatados = ["policia"]
		g.talentos = {}
		g.edificios.erase("centro"))
	logros.repasar = false   # (para que se vea a medias lo que ya tiene en el guardado)
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("logros")
	await get_tree().create_timer(0.3).timeout
	for sc in ordenador.ventana.find_children("*", "ScrollContainer", true, false):
		sc.scroll_vertical = 0
	await get_tree().process_frame
	Captura.foto("captura-logros-temas.png")
	print("Logros nuevos · ordenador: apartados %s (esperado: Edificios, Jefes, Combate, Armas y talentos, Supervivientes, Sorpresas y retos, Colecciones)" % [
		ordenador.ventana.find_children("*", "Label", true, false).map(func(l): return l.text).filter(func(t): return t in Logros.TEMAS.values())])
	for sc in ordenador.ventana.find_children("*", "ScrollContainer", true, false):
		sc.scroll_vertical = 100000
	await get_tree().process_frame
	Captura.foto("captura-logros-temas-abajo.png")
	ordenador.abrir("")
	ordenador.apagar()
	# el guardado, como estaba
	Guardado.cambiar(func(g):
		for k in claves:
			g[k] = copia[k])
	limpiar.call()


# Con "--captura --flatulento": el alcance de la mutación Flatulento (mutaciones.gd, MUT; antes 70, ahora 140). En
# un apartamento con todo descubierto, Johnny en medio de su habitación más grande y tres zombis quietos en fila: a 50
# (dentro del alcance de antes), a 110 (solo dentro del de ahora) y a 190 (fuera de los dos). Al soltar los gases,
# los dos primeros se quedan paralizados 2 s y con el estado de gases (queman); el tercero, nada. Foto de la nube con
# ellos (captura-flatulento.png). Cuenta todo en la terminal, con lo esperado, y se cierra
func probar_flatulento() -> void:
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
	johnny.position = grande.centro
	johnny.get_node("Camara").reset_smoothing()
	luz.alternar()   # (sin penumbra, para ver la nube)
	await get_tree().process_frame
	var zombis := []
	for d in [50.0, 110.0, 190.0]:
		var z := meter_zombi("normal", johnny.position + Vector2(d, 0))
		z.set_physics_process(false)   # quietos, para la prueba
		z.vida = 100000
		zombis.append(z)
	var lanzo: bool = mutaciones.actuar("flatulento")
	await get_tree().create_timer(0.25).timeout
	Captura.foto("captura-flatulento.png")
	print("Flatulento · alcance %d · ¿suelta los gases? %s (esperado: 140 y true)" % [roundi(Mutaciones.MUT.flatulento.radio), lanzo])
	for k in zombis.size():
		print("Flatulento · zombi a %d: paralizado %s, con gases %s (esperado: %s)" % [
			roundi(johnny.position.distance_to(zombis[k].position)), zombis[k].aturdido > 0.0,
			zombis[k].estados.has("gases"), "true, true" if k < 2 else "false, false"])
	get_tree().quit()


# Con "--captura --quimico": la rama Químico del árbol de talentos (M14), con sus números en la terminal y lo esperado
# al lado. En la sala más grande del apartamento más grande, sin zombis y con todos los de Químico al máximo: Catalizador
# (el lanzallamas y la congeladora), Guantes de goma (lo que quita un segundo de fuego), Incendiario, Desatascador,
# Criogenia (las congeladoras del principio, las que caben y lo que dejan quietos) y los tres del nivel 3 con su foto:
# Reacción en cadena (captura-quimico-reaccion.png), Residuo tóxico (captura-quimico-residuo.png) y Pararrayos
# (captura-quimico-pararrayos.png). Al final, el árbol en el ordenador, con una pestaña por rama: la de Militar
# (captura-quimico-arbol-militar.png) y la de Químico, arriba y abajo (captura-quimico-arbol.png y
# captura-quimico-arbol-abajo.png). Se cierra
func probar_quimico() -> void:
	var centro: Vector2 = await sala_de_talentos()
	var todos := {"catalizador": 5, "guantes_goma": 5, "incendiario": 5, "desatascador": 5, "criogenia": 3, "reaccion": 1,
		"residuo": 1, "pararrayos": 1}

	# ── Catalizador: el lanzallamas, sin y con ──
	aplicar_talentos({})
	johnny.coger("lanzallamas")
	var sin: float = johnny.arma().dano
	aplicar_talentos(todos)
	print("Catalizador 5: el lanzallamas quita %.0f (sin él, %.0f; esperado: 30 y 45) y lo que arde el prendido × %.1f (esperado: 1.5)" % [
		johnny.arma().dano, sin, johnny.arma().get("quema", 1.0)])

	# ── Criogenia: las congeladoras del principio y las que caben ──
	lanzables.reiniciar(johnny.stats)
	print("Criogenia 3: empieza con %d congeladoras (esperado: 3), a mano %s (esperado: con la congeladora) y caben %d (esperado: 6)" % [
		lanzables.cuantas("congeladora"), lanzables.mano, lanzables.maximo("congeladora")])

	# ── Guantes de goma: un segundo dentro del fuego (y los 2 s que sigue quemando al salir) ──
	johnny.vida = johnny.stats.vida_max
	var v0: int = johnny.vida
	for k in 60:
		johnny.pisar({"fuego": {"dps": 12.0}})
		await get_tree().physics_frame
	await get_tree().create_timer(2.3, false).timeout
	print("Guantes de goma 5: un segundo de fuego (12 por segundo, y 2 s más al salir) quita %d (esperado: unos 18; sin guantes, 36)" % [
		v0 - johnny.vida])

	# ── Incendiario y Desatascador ──
	var z1: Node2D = meter_zombi("normal", centro + Vector2(-200, 0))
	await get_tree().process_frame
	z1.vida = 9999
	z1.aturdido = 30.0
	z1.prender()
	ArmasCreadas.herir(z1, "acido", 10)
	print("Incendiario 5: el zombi prendido arde %.1f s (esperado: 2 + 2,5 = 4,5) · Desatascador 5: con ácido, un golpe de 100 le quita %d (esperado: 200; sin el talento, 150)" % [
		z1.arder_t, ArmasCreadas.con_acido(z1, 100)])
	z1.queue_free()

	# ── Criogenia y Catalizador en la congeladora: lanzada a un zombi duro, lejos de Johnny ──
	var z2: Node2D = meter_zombi("normal", centro + Vector2(170, 0))
	await get_tree().process_frame
	z2.vida = 500
	z2.aturdido = 30.0   # quieto hasta justo antes de que explote (a los 2 s), y entonces se suelta para medir lo suyo
	lanzables.tipo = "congeladora"
	lanzables.lanzar(z2.position)
	await get_tree().create_timer(1.95, false).timeout
	z2.aturdido = 0.0
	var vida_antes: int = z2.vida
	await get_tree().create_timer(0.15, false).timeout
	print("Criogenia 3 y Catalizador 5: la congeladora le quita %d (esperado: 50 × 1,5 = 75; antes de explotar había perdido %d, esperado: 0) y lo deja quieto %.1f s (esperado: unos 4,5)" % [
		vida_antes - z2.vida, 500 - vida_antes, z2.aturdido])
	z2.queue_free()
	await get_tree().create_timer(0.8, false).timeout   # (que se apague la explosión antes de la foto siguiente)

	# ── Reacción en cadena: muere ardiendo; uno a 40 y otro a 70 (el estallido llega a 80; muere antes de contagiar) ──
	var a: Node2D = meter_zombi("normal", centro + Vector2(110, 0))
	var b: Node2D = meter_zombi("normal", centro + Vector2(150, 0))
	var c: Node2D = meter_zombi("normal", centro + Vector2(180, 0))
	await get_tree().process_frame
	for z in [a, b, c]:
		z.vida = 500
		z.aturdido = 30.0
	# los otros, desde donde ha quedado el primero (puede haber chocado con la pared) y sin moverse ni empujarse entre ellos
	for k in 2:
		var otro: Node2D = [b, c][k]
		otro.position = a.position + Vector2([40, 70][k], 0)
		otro.set_physics_process(false)
	a.prender()
	await get_tree().create_timer(0.1, false).timeout
	print("Reacción en cadena: antes de morir, los de al lado arden %s y %s (esperado: false y false)" % [b.arder_t > 0.0, c.arder_t > 0.0])
	a.recibir_golpe(9999, Vector2.ZERO)
	await get_tree().create_timer(0.12, false).timeout
	print("Reacción en cadena: al morir ardiendo, los de al lado arden %s y %s (esperado: true y true)" % [b.arder_t > 0.0, c.arder_t > 0.0])
	for z in [b, c]:
		z.set_physics_process(true)   # (para que se les pinten las llamas)
	await get_tree().create_timer(0.1, false).timeout
	Captura.foto("captura-quimico-reaccion.png")
	for z in [a, b, c]:
		z.queue_free()

	# ── Residuo tóxico: muere con ácido; uno encima del charco y Johnny encima ──
	var d: Node2D = meter_zombi("normal", centro + Vector2(150, 0))
	await get_tree().process_frame
	d.aturdido = 30.0
	ArmasCreadas.herir(d, "acido", 10)
	d.recibir_golpe(9999, Vector2.ZERO)
	await get_tree().create_timer(0.4, false).timeout
	var residuos := get_tree().get_nodes_in_group("charcos").filter(func(ch): return ch.tipo == "residuo")
	var e: Node2D = meter_zombi("normal", d.position + Vector2(8, 0))
	await get_tree().process_frame
	e.vida = 500
	e.aturdido = 30.0
	johnny.position = d.position + Vector2(-8, 0)
	for k in 6:
		await get_tree().physics_frame
	print("Residuo tóxico: deja %d charco (esperado: 1); el zombi de encima lleva ácido %s (esperado: true) y Johnny encima %s (esperado: false)" % [
		residuos.size(), e.estados.has("acido"), johnny.estados.has("acido")])
	johnny.position = centro
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-quimico-residuo.png")
	e.queue_free()
	for ch in residuos:
		ch.queue_free()

	# ── Pararrayos: el que pega, pegado a Johnny, y otro a 70 de él ──
	var f: Node2D = meter_zombi("normal", centro + Vector2(40, 0))
	var g: Node2D = meter_zombi("normal", centro + Vector2(110, 0))
	await get_tree().process_frame
	for z in [f, g]:
		z.vida = 500
		z.aturdido = 0.0
	johnny.invulnerable = 0.0
	johnny.pararrayos_t = 0.0
	johnny.recibir_dano(10, f)
	await get_tree().process_frame
	Captura.foto("captura-quimico-pararrayos.png")
	print("Pararrayos: al que pega le quita %d (esperado: 20 × 1,5 = 30) y lo aturde %s (esperado: true); al de al lado le quita %d (esperado: 15)" % [
		500 - f.vida, f.aturdido > 0.0, 500 - g.vida])
	var antes: int = f.vida
	johnny.invulnerable = 0.0
	johnny.recibir_dano(10, f)
	print("Pararrayos: otra vez al momento le quita %d (esperado: 0: como mucho cada 3 s)" % [antes - f.vida])
	f.queue_free()
	g.queue_free()

	# ── El árbol con las tres ramas en el ordenador ──
	var guardado_antes := Guardado.cargar()
	Guardado.cambiar(func(gu):
		gu.puntos = 4
		gu.talentos = {"ataque": 5, "punteria": 2, "corpulento": 5, "durito": 3, "catalizador": 5, "guantes_goma": 2,
			"incendiario": 3})
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.rama_abierta = "militar"
	ordenador.abrir("puntos")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-quimico-arbol-militar.png")
	ordenador.ver_rama("quimico")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-quimico-arbol.png")
	for desliza: ScrollContainer in ordenador.find_children("*", "ScrollContainer", true, false):
		desliza.scroll_vertical = 99999
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-quimico-arbol-abajo.png")
	print("Árbol: pestañas %s (esperado: las tres) · se ve la rama %s (esperado: quimico)" % [
		ordenador.find_children("b_rama_*", "", true, false).map(func(b): return b.name), ordenador.rama_abierta])
	Guardado.cambiar(func(gu):
		gu.puntos = guardado_antes.puntos
		gu.talentos = guardado_antes.talentos)
	get_tree().quit()


# Para las pruebas de talentos: Johnny en la sala más grande del apartamento más grande, sin zombis, quieto (que no pegue
# ni dispare solo), con la skin de siempre y sin el acompañante de la partida de prueba (quieto: que no pegue).
# Devuelve el centro de la sala, donde está Johnny
func sala_de_talentos() -> Vector2:
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
	johnny.modo = "quieto"
	johnny.vestir("conserje")
	for aliado in get_tree().get_nodes_in_group("aliados"):
		aliado.process_mode = Node.PROCESS_MODE_DISABLED
	return grande.centro


# Con "--captura --equilibrio-talentos": los cambios de las ramas Militar y Superviviente (M15), con sus números en la
# terminal y lo esperado al lado: Durito llega a 3 (y a quien tenía más se le devuelven los puntos), Ajolote cura solo
# hasta la mitad, Puntería lanza más lejos y Mirilla da un crítico de cada 3 disparos, con su número en amarillo
# (captura-talentos-critico.png). Al final, las tarjetas del ordenador con lo que dan ahora y con otro punto
# (captura-talentos-militar.png y captura-talentos-superviviente.png). Ninja cada 5 s: en --equilibrio. Se cierra
func probar_equilibrio_talentos() -> void:
	var centro: Vector2 = await sala_de_talentos()
	var guardado_antes := Guardado.cargar()

	# ── Durito: como mucho 3, y los puntos de más vuelven ──
	Guardado.cambiar(func(g):
		g.talentos.durito = 5
		g.puntos = 1)
	var leido := Guardado.cargar()
	print("Durito: con 5 puestos en un guardado viejo, al cargar se queda en %d y los puntos pasan de 1 a %d (esperado: 3 y 3)" % [
		leido.talentos.durito, leido.puntos])
	aplicar_talentos({"corpulento": 5, "durito": 3})
	johnny.escudo = 0.0
	johnny.invulnerable = 0.0
	var v0: int = johnny.vida
	johnny.recibir_dano(10)
	print("Durito 3: un zarpazo de 10 quita %d (esperado: 7; con Durito 5, antes, 5) · vida máxima con Corpulento 5: %d (esperado: 150)" % [
		v0 - johnny.vida, johnny.stats.vida_max])

	# ── Ajolote: cura hasta la mitad, no más ──
	aplicar_talentos({"corpulento": 5, "lobezno": 5})
	johnny.vida = 72
	johnny.regenera_t = 0.0
	await get_tree().create_timer(5.3, false).timeout
	var a_los_5: int = johnny.vida
	await get_tree().create_timer(5.3, false).timeout
	print("Ajolote 5 con 150 de vida: de 72, a los 5 s %d y a los 10 s %d (esperado: 75 y 75: la mitad, sin pasarse)" % [
		a_los_5, johnny.vida])
	johnny.vida = 100
	await get_tree().create_timer(5.3, false).timeout
	print("Ajolote 5: con 100 de 150 (más de la mitad), a los 5 s %d (esperado: 100)" % johnny.vida)

	# ── Puntería: lanza más lejos ──
	aplicar_talentos({})
	var sin_punteria: float = lanzables.alcance()
	aplicar_talentos({"ataque": 5, "punteria": 5})
	print("Puntería 5: se lanza hasta %.0f (sin ella, %.0f; esperado: 450 y 300) · el molotov quema × %.1f (esperado: 1.5)" % [
		lanzables.alcance(), sin_punteria, johnny.stats.dano_lanzar])

	# ── Mirilla: uno de cada 3 disparos, crítico (sin críticos al azar) ──
	aplicar_talentos({})
	johnny.stats.mirilla = true
	johnny.stats.critico = 0.0
	johnny.coger("pistola")
	johnny.disparos = 0
	var diana: Node2D = meter_zombi("normal", centro + Vector2(120, 0))
	await get_tree().process_frame
	diana.vida = 9999
	diana.aturdido = 60.0
	var golpes := []
	diana.herido.connect(func(n, _golpe): golpes.append(n))
	for k in 6:
		johnny.balas = 10
		johnny.disparar((diana.global_position - johnny.global_position).angle())
		if k < 5:
			await get_tree().create_timer(0.35, false).timeout
	for espera in 30:   # la 6.ª: la foto, con su número recién salido
		if golpes.size() >= 6:
			break
		await get_tree().physics_frame
	await get_tree().create_timer(0.1, false).timeout
	Captura.foto("captura-talentos-critico.png")
	print("Mirilla: lo que quitan 6 balas seguidas %s (esperado: la 3.ª y la 6.ª, el doble; esos números, en amarillo)" % [golpes])
	diana.queue_free()

	# ── Las tarjetas del ordenador: lo que dan ahora y con otro punto ──
	Guardado.cambiar(func(g):
		g.puntos = 4
		g.talentos = {"ataque": 5, "punteria": 3, "camorrista": 2, "corpulento": 5, "lobezno": 2, "durito": 1})
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.rama_abierta = "militar"
	ordenador.abrir("puntos", "b_punteria")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-talentos-militar.png")
	ordenador.ver_rama("superviviente")
	ordenador.abrir("puntos", "b_lobezno")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-talentos-superviviente.png")
	print("Tarjetas: Puntería 3 «%s» · Durito 1 «%s» (esperado: Ahora: ... · Con otro: ...)" % [
		"Ahora: %s · Con otro: %s" % [Talentos.efecto("punteria", 3), Talentos.efecto("punteria", 4)],
		"Ahora: %s · Con otro: %s" % [Talentos.efecto("durito", 1), Talentos.efecto("durito", 2)]])
	Guardado.cambiar(func(g):
		g.puntos = guardado_antes.puntos
		g.talentos = guardado_antes.talentos)
	get_tree().quit()


# Con "--captura --talentos-altos": los niveles 4 y 5 de las tres ramas (M16), con sus números en la terminal y lo
# esperado al lado. Militar: Frenesí y Gatillo fácil (rapidez y recarga), Racimo (lo que sueltan el molotov y la
# granada, con la foto de las granaditas: captura-altos-racimo.png) y Veterano. Superviviente: Blindaje, Sombra, Segundo
# aliento (una vez por planta: captura-altos-aliento.png) y Adrenalina (daño y velocidad: captura-altos-adrenalina.png).
# Químico: Napalm, Pegajoso, Alto voltaje (el rayo de Pararrayos salta a 4 más: captura-altos-voltaje.png) y Mezcla
# explosiva (captura-altos-mezcla.png). Al final, en el ordenador, la corona de Militar bloqueada y la de Superviviente
# comprada (captura-altos-arbol-militar.png y captura-altos-arbol-superviviente.png). Se cierra
func probar_talentos_altos() -> void:
	var centro: Vector2 = await sala_de_talentos()
	var guardado_antes := Guardado.cargar()
	var sala: Node = johnny.get_parent()

	# ── Frenesí y Gatillo fácil ──
	aplicar_talentos({})
	var fregona: Dictionary = johnny.arma_de("fregona")
	var pistola: Dictionary = johnny.arma_de("pistola")
	aplicar_talentos({"frenesi": 3, "gatillo": 3})
	print("Frenesí 3: la fregona da %.2f golpes por segundo (sin él, %.2f; esperado: × 1,3) · Gatillo fácil 3: la pistola dispara %.2f por segundo (sin él, %.2f; esperado: × 1,3) y recarga en %.2f s (sin él, %.2f; esperado: × 0,7)" % [
		johnny.arma_de("fregona").ritmo, fregona.ritmo, johnny.arma_de("pistola").ritmo, pistola.ritmo,
		johnny.arma_de("pistola").recarga, pistola.recarga])

	# ── Racimo: el molotov y la granada, 3 pequeños más (lanzados lejos de Johnny) ──
	aplicar_talentos({"racimo": 3})
	lanzables.reiniciar(johnny.stats)
	lanzables.tipo = "molotov"
	lanzables.lanzar(centro + Vector2(-220, 0))
	var botella: Node = sala.get_child(-1)
	lanzables.tipo = "granada"
	lanzables.lanzar(centro + Vector2(220, 0))
	var granada: Node = sala.get_child(-1)
	print("Racimo 3: el molotov soltará %d botellitas y la granada %d granaditas (esperado: 3 y 3; sin el talento, 0 si no son Épicas)" % [
		botella.racimo, granada.racimo])
	var hijas := []
	for espera in 200:   # hasta que la granada explota y salen sus granaditas
		hijas = sala.get_children().filter(func(n): return n.get("hija") == true)
		if not hijas.is_empty():
			break
		await get_tree().physics_frame
	await get_tree().create_timer(0.8, false).timeout   # (las granaditas explotan a los 0,7 s)
	Captura.foto("captura-altos-racimo.png")
	print("Racimo 3: al explotar la granada salen %d granaditas (esperado: 3)" % hijas.size())
	await get_tree().create_timer(0.7, false).timeout
	for ch in get_tree().get_nodes_in_group("charcos"):
		ch.queue_free()

	# ── Veterano ──
	aplicar_talentos({"veterano": 1})
	print("Veterano: críticos el %d %% de las veces (esperado: 15) y un crítico de un golpe de 10 quita %d (esperado: 30; sin él, 20)" % [
		roundi(johnny.stats.critico * 100.0), johnny.con_critico(10, true)])

	# ── Blindaje y Sombra ──
	aplicar_talentos({})
	johnny.escudo = 0.0
	aplicar_talentos({"acero": 1, "blindaje": 3, "sombra": 3})
	print("Blindaje 3: escudo de %d al comprarlo (esperado: 50 + 75 = 125) · Sombra 3: la esquiva se recarga en %.2f s (esperado: 0,9 × 0,55 = 0,50)" % [
		roundi(johnny.escudo), johnny.stats.esquiva_espera])

	# ── Segundo aliento: de 40, un golpe de 15; y otra vez en la misma planta ──
	aplicar_talentos({"aliento": 3})
	johnny.escudo = 0.0
	johnny.vida = 40
	johnny.tercios = 3
	johnny.aliento_usado = false
	johnny.invulnerable = 0.0
	johnny.recibir_dano(15)
	var tras_aliento: int = johnny.vida
	await get_tree().create_timer(0.25, false).timeout
	Captura.foto("captura-altos-aliento.png")
	johnny.vida = 40
	johnny.tercios = 3
	johnny.invulnerable = 0.0
	johnny.recibir_dano(15)
	print("Segundo aliento 3: de 40, un golpe de 15 lo deja en 25 y se cura hasta %d (esperado: 67: +45, sin pasar de los dos tercios, que recupera uno) · otra vez en la misma planta: %d (esperado: 25)" % [
		tras_aliento, johnny.vida])

	# ── Adrenalina: por debajo de la mitad, más daño y más velocidad ──
	aplicar_talentos({"adrenalina": 1})
	johnny.vida = 100
	johnny.tercios = 3
	johnny.con_adrenalina = false
	var golpe_lleno: float = johnny.arma_de("fregona").dano
	var corre_lleno: float = await correr_un_rato(centro)
	johnny.invulnerable = 0.0
	johnny.vida = 55
	johnny.recibir_dano(15)
	johnny.tercios = 3   # (para medir solo la Adrenalina: sin el tercio perdido, que le hace ir más lento)
	await get_tree().create_timer(0.25, false).timeout
	Captura.foto("captura-altos-adrenalina.png")
	var corre_bajo: float = await correr_un_rato(centro)
	print("Adrenalina: con 100 de vida la fregona quita %.1f y con 40, %.1f (esperado: × 1,3) · corre a %.0f y a %.0f (esperado: 210 y 252)" % [
		golpe_lleno, johnny.arma_de("fregona").dano, corre_lleno, corre_bajo])
	johnny.vida = 100

	# ── Napalm: el fuego del molotov dura 3 s más ──
	aplicar_talentos({"napalm": 3})
	lanzables.reiniciar(johnny.stats)
	lanzables.tipo = "molotov"
	lanzables.lanzar(centro + Vector2(-220, 0))
	var fuego: Node = null
	for espera in 200:
		var fuegos := get_tree().get_nodes_in_group("charcos").filter(func(ch): return ch.tipo == "fuego")
		if not fuegos.is_empty():
			fuego = fuegos[0]
			break
		await get_tree().physics_frame
	print("Napalm 3: el fuego del molotov dura %.1f s (esperado: 4 + 3 = 7)" % (fuego.vida_max if fuego else -1.0))
	for ch in get_tree().get_nodes_in_group("charcos"):
		ch.queue_free()

	# ── Pegajoso: lo rápido que anda un zombi, sin ácido y con ácido ──
	aplicar_talentos({"pegajoso": 3})
	var lento: Node2D = meter_zombi("normal", centro + Vector2(-300, 0))
	await get_tree().process_frame
	lento.vida = 9999
	await get_tree().create_timer(0.3, false).timeout   # (que eche a andar)
	var sin_acido: float = await rapidez_media(lento)
	ArmasCreadas.herir(lento, "acido", 1)
	var con_acido: float = await rapidez_media(lento)
	print("Pegajoso 3: el zombi anda a %.0f sin ácido y a %.0f con ácido (esperado: el 70 %%, unos %.0f; lleva ácido: %s)" % [
		sin_acido, con_acido, sin_acido * 0.7, lento.con_acido()])
	lento.queue_free()

	# ── Alto voltaje: el rayo de Pararrayos, del que pega a 4 más en fila (a 70 uno de otro) ──
	aplicar_talentos({"pararrayos": 1, "voltaje": 3})
	var fila := []
	for k in 6:
		var z: Node2D = meter_zombi("normal", centro + Vector2(40 + 70 * k, 0))
		fila.append(z)
	await get_tree().process_frame
	for k in fila.size():
		fila[k].vida = 500
		fila[k].aturdido = 30.0
		fila[k].position = centro + Vector2(40 + 70 * k, 0)
		fila[k].set_physics_process(false)
	johnny.invulnerable = 0.0
	johnny.pararrayos_t = 0.0
	johnny.recibir_dano(10, fila[0])
	await get_tree().process_frame
	Captura.foto("captura-altos-voltaje.png")
	print("Alto voltaje 3: lo que quita el rayo a los 6 de la fila %s (esperado: 20 al que pega, 10 a los 4 siguientes y 0 al último)" % [
		fila.map(func(z): return 500 - z.vida)])
	for z in fila:
		z.queue_free()
	await get_tree().create_timer(0.3, false).timeout

	# ── Mezcla explosiva: uno con un solo efecto (nada) y otro con dos (explota, y a Johnny no le hace nada) ──
	aplicar_talentos({"mezcla": 1})
	johnny.vida = 100
	johnny.invulnerable = 0.0
	var m: Node2D = meter_zombi("normal", centro + Vector2(60, 0))
	var vecinos := [meter_zombi("normal", centro + Vector2(120, 0)), meter_zombi("normal", centro + Vector2(60, 60))]
	await get_tree().process_frame
	for z in [m] + vecinos:
		z.vida = 500
		z.aturdido = 30.0
		z.set_physics_process(false)
	m.position = centro + Vector2(60, 0)
	vecinos[0].position = centro + Vector2(120, 0)
	vecinos[1].position = centro + Vector2(60, 60)
	ArmasCreadas.aturdir(m, 0.5)   # solo el rayo
	m.recibir_golpe(9999, Vector2.ZERO)
	await get_tree().create_timer(0.1, false).timeout
	print("Mezcla explosiva: el que muere solo con el rayo no explota: a los de al lado les quita %s (esperado: [0, 0])" % [
		vecinos.map(func(z): return 500 - z.vida)])
	var m2: Node2D = meter_zombi("normal", centro + Vector2(60, 0))
	await get_tree().process_frame
	m2.vida = 500
	m2.set_physics_process(false)
	m2.position = centro + Vector2(60, 0)
	m2.prender()
	ArmasCreadas.herir(m2, "acido", 1)   # fuego y ácido
	print("Mezcla explosiva: lleva %d efectos (esperado: 2)" % m2.efectos_puestos())
	m2.recibir_golpe(9999, Vector2.ZERO)
	await get_tree().create_timer(0.15, false).timeout
	Captura.foto("captura-altos-mezcla.png")
	print("Mezcla explosiva: el que muere con fuego y ácido explota: a los de al lado les quita %s (esperado: [30, 30]) y a Johnny, a 60, %d (esperado: 0)" % [
		vecinos.map(func(z): return 500 - z.vida), 100 - johnny.vida])
	for z in [m, m2] + vecinos:
		z.queue_free()

	# ── El ordenador: 36 puntos por rama, la corona de Militar bloqueada y la de Superviviente comprada ──
	var por_rama := {}
	for t in Talentos.LISTA:
		por_rama[t.rama] = por_rama.get(t.rama, 0) + t.max
	var casi := {"ataque": 5, "punteria": 5, "camorrista": 5, "tirador": 5, "artificiero": 3, "larguirucho": 1,
		"mirilla": 1, "fabricante": 1, "frenesi": 3, "gatillo": 3, "racimo": 1}
	var prueba := {"puntos": 4, "talentos": casi}
	print("Árbol: puntos por rama %s (esperado: 36 cada una) · Veterano con Racimo a 1: %s, falta %s (esperado: bloqueado y Racimo); con Racimo a 3: «%s» (esperado: «»)" % [
		por_rama, Talentos.motivo(prueba, "veterano"), Talentos.nombres(Talentos.faltan(prueba, "veterano")),
		Talentos.motivo({"puntos": 4, "talentos": casi.merged({"racimo": 3}, true)}, "veterano")])
	Guardado.cambiar(func(g):
		g.puntos = 4
		g.talentos = casi.merged({"corpulento": 5, "lobezno": 5, "durito": 3, "reflejos": 5, "sanitario": 5, "acero": 1,
			"ninja": 1, "desfibrilador": 1, "blindaje": 3, "sombra": 3, "aliento": 3, "adrenalina": 1}))
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.rama_abierta = "militar"
	ordenador.abrir("puntos", "b_veterano")
	await get_tree().create_timer(0.3).timeout
	for desliza: ScrollContainer in ordenador.find_children("*", "ScrollContainer", true, false):
		desliza.scroll_vertical = 99999
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-altos-arbol-militar.png")
	ordenador.ver_rama("superviviente")
	ordenador.abrir("puntos", "b_adrenalina")
	await get_tree().create_timer(0.3).timeout
	for desliza: ScrollContainer in ordenador.find_children("*", "ScrollContainer", true, false):
		desliza.scroll_vertical = 99999
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-altos-arbol-superviviente.png")
	Guardado.cambiar(func(g):
		g.puntos = guardado_antes.puntos
		g.talentos = guardado_antes.talentos)
	get_tree().quit()


# Para Pegajoso: lo rápido que va un zombi, de media, durante un segundo
func rapidez_media(z: Node2D) -> float:
	var suma := 0.0
	for k in 60:
		await get_tree().physics_frame
		suma += z.velocity.length()
	return suma / 60.0


# Para Adrenalina: Johnny corre hacia la derecha medio segundo (como con la flecha) y devuelve lo rápido que iba. Vuelve
# a dejarlo en "centro"
func correr_un_rato(centro: Vector2) -> float:
	johnny.position = centro + Vector2(-120, 0)
	johnny.velocity = Vector2.ZERO
	Input.action_press("derecha")
	await get_tree().create_timer(0.5, false).timeout
	var rapidez: float = johnny.velocity.length()
	Input.action_release("derecha")
	await get_tree().create_timer(0.2, false).timeout
	johnny.position = centro
	return rapidez


# Con "--captura --tentaculos": el zombi de tentáculos con su hoja de PixelLab (zombi_tentaculos.gd). En la sala de
# pruebas, dos vienen andando hacia Johnny, uno por cada lado (captura-tentaculos-andar.png); luego uno, ya cerca,
# avisa del latigazo echando los tentáculos atrás (captura-tentaculos-aviso.png) y los lanza al dar el golpe
# (captura-tentaculos-latigazo.png); luego se queda parado a su distancia, con el reposo que mueve los tentáculos
# (captura-tentaculos-reposo.png); se le pega (captura-tentaculos-golpe.png) y se le mata
# (captura-tentaculos-muerte.png, ya tendido). Luego, el tentáculo que pega (pintado con código) con Johnny abajo,
# arriba, de lado, en diagonal y junto a una pared (que lo corta): avisando, con el aviso de las cargas de los jefes
# (captura-tentaculos-aviso-abajo.png, -arriba, -lado, -diagonal, -pared) y dando el latigazo
# (captura-tentaculos-latigazo-abajo.png...). En la terminal, la animación y el fotograma de cada momento
func probar_tentaculos() -> void:
	await pulsar_y_esperar(KEY_F9)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no tape las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	if not SalaArmas.escondido:   # ni el panel de daño ni las líneas, que taparían al de la izquierda
		await pulsar_y_esperar(KEY_MINUS)
	johnny.modo = "quieto"
	johnny.global_position = sala.diana.global_position + Vector2(0, 200)
	johnny.direccion = "s"
	johnny.get_node("Camara").reset_smoothing()
	var que_hace := func(z: Node2D) -> String:
		return "%s %s/%d" % [z.estado, z.sprite.animation, z.sprite.frame]

	# andando: uno desde la izquierda (andar_e) y otro desde la derecha (andar_o, el mismo en espejo)
	var z: Node2D = meter_zombi("tentaculos", johnny.position + Vector2(-330, -20))
	var otro: Node2D = meter_zombi("tentaculos", johnny.position + Vector2(330, -20))
	z.espera = 99.0   # que no ataquen todavía
	otro.espera = 99.0
	var visto := []
	for i in 8:
		await get_tree().create_timer(0.1).timeout
		visto.append("%s | %s" % [que_hace.call(z), que_hace.call(otro)])
	Captura.foto("captura-tentaculos-andar.png")
	print("Tentáculos andando: %s (esperado: andar andar_e y andar andar_o, con el fotograma cambiando de 0 a 4)" % [visto])
	otro.remove_from_group("zombis")
	otro.queue_free()

	# el latigazo: a tiro y sin esperar, avisa (fotogramas 0 a 2 del ataque) y lo da (del 3 en adelante)
	z.position = johnny.position + Vector2(-180, -20)
	z.espera = 0.0
	await get_tree().create_timer(0.5).timeout
	var en_aviso: String = que_hace.call(z)
	Captura.foto("captura-tentaculos-aviso.png")
	while z.estado == "aviso":
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	var en_latigazo: String = que_hace.call(z)
	Captura.foto("captura-tentaculos-latigazo.png")
	while z.estado == "latigazo":
		await get_tree().physics_frame
	await get_tree().physics_frame
	print("Tentáculos: avisando %s · al dar el latigazo %s · después %s (esperado: aviso ataque_e/1 o 2, latigazo ataque_e/3 y andar o reposo)" % [
		en_aviso, en_latigazo, que_hace.call(z)])

	# parado a su distancia (más cerca que PARARSE), esperando: el reposo va cambiando de fotograma
	z.espera = 99.0
	var reposo := []
	for i in 40:
		await get_tree().create_timer(0.1).timeout
		if z.sprite.animation.begins_with("reposo"):
			reposo.append(z.sprite.frame)
		if reposo.size() >= 10:
			break
	Captura.foto("captura-tentaculos-reposo.png")
	print("Tentáculos parados: fotogramas del reposo %s (esperado: diez, cambiando entre el 0 y el 7)" % [reposo])

	# un golpe (se encoge) y luego otro que lo mata (se cae y se queda tendido)
	z.recibir_golpe(5, Vector2(-60, 0))
	await get_tree().create_timer(0.12).timeout
	var en_golpe: String = que_hace.call(z)
	Captura.foto("captura-tentaculos-golpe.png")
	await get_tree().create_timer(0.6).timeout
	var tras_golpe: String = que_hace.call(z)
	z.recibir_golpe(999, Vector2(-60, 0))
	await get_tree().create_timer(1.4).timeout
	Captura.foto("captura-tentaculos-muerte.png")
	print("Tentáculos: con el golpe %s, luego %s · muerto %s (esperado: golpe golpe_e, andar o reposo, muerto muerte_e/8)" % [
		en_golpe, tras_golpe, que_hace.call(z)])

	# el tentáculo de código en otras direcciones, para ver que sale del hombro: con Johnny abajo (le pega mirando
	# al sur, de frente), arriba (al norte, de espaldas), de lado (al este) y en diagonal (al suroeste). Y con Johnny
	# a 40 de la pared de la derecha: el latigazo se para en ella (con la estrella en el aviso). Johnny, invencible y
	# lejos de la diana. Cada caso: nombre, dónde está Johnny (desde la diana) y dónde el zombi (desde Johnny)
	johnny.invencible = true
	for caso in [["abajo", Vector2(260, 60), Vector2(0, -170)], ["arriba", Vector2(260, 60), Vector2(0, 170)],
			["lado", Vector2(260, 60), Vector2(-170, -10)], ["diagonal", Vector2(260, 60), Vector2(130, -120)],
			["pared", Vector2(440, 60), Vector2(-150, 0)]]:
		johnny.global_position = sala.diana.global_position + caso[1]
		johnny.get_node("Camara").reset_smoothing()
		var t: Node2D = meter_zombi("tentaculos", johnny.position + caso[2])
		t.espera = 0.0
		var esperado := 0
		while not (t.estado == "aviso" and t.t_ataque >= 0.5) and esperado < 300:
			await get_tree().physics_frame
			esperado += 1
		await RenderingServer.frame_post_draw
		Captura.foto("captura-tentaculos-aviso-%s.png" % caso[0])
		var avisando: String = que_hace.call(t)
		while not (t.estado == "latigazo" and t.t_ataque >= 0.08) and esperado < 400:
			await get_tree().physics_frame
			esperado += 1
		await RenderingServer.frame_post_draw
		Captura.foto("captura-tentaculos-latigazo-%s.png" % caso[0])
		print("Tentáculo con Johnny %s: avisando %s · latigazo %s · llega a %d%s (esperado: ataque_%s y %s; sin pasarse de los 400 pasos: %d)" % [
			caso[0], avisando, que_hace.call(t), t.tentaculo.llega, ", choca" if t.tentaculo.choca else "",
			{"abajo": "s", "arriba": "n", "lado": "e", "diagonal": "so", "pared": "e"}[caso[0]],
			"choca antes de 220" if caso[0] == "pared" else "220 sin chocar", esperado])
		t.remove_from_group("zombis")
		t.queue_free()
	get_tree().quit()


# --latigazos: los tres latigazos del gerente mutado (tentaculo.gd), en la sala de pruebas (F9), con Johnny abajo,
# arriba, de lado, en diagonal, en diagonal por detrás (de espaldas) y junto a la pared de la derecha (que los corta):
# avisando (captura-latigazos-aviso-abajo.png, -arriba, -lado, -diagonal, -espalda, -pared) y dando el latigazo
# (captura-latigazos-latigazo-abajo.png...). La cámara, algo más lejos, sin los límites de la sala y centrada en el
# gerente y sus latigazos. En la terminal, la animación y hasta dónde llega cada tentáculo (y si choca)
func probar_latigazos() -> void:
	await pulsar_y_esperar(KEY_F9)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no tape las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	if not SalaArmas.escondido:   # ni el panel de daño ni las líneas
		await pulsar_y_esperar(KEY_MINUS)
	johnny.modo = "quieto"
	johnny.invencible = true
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(0.85, 0.85)   # (de los tentáculos levantados a las puntas no cabe a tamaño normal)
	camara.limit_left = -100000
	camara.limit_top = -100000
	camara.limit_right = 100000
	camara.limit_bottom = 100000
	print("Latigazos: la sala mide %d x %d" % [mapa.sitio.ancho, mapa.sitio.alto])
	var gerente: Node2D = meter_zombi("gerente", sala.diana.global_position + Vector2(200, -60))
	await get_tree().create_timer(0.2).timeout
	gerente.mutar()
	await get_tree().create_timer(1.5).timeout
	# Cada caso: nombre, dónde está Johnny (desde la diana), dónde el gerente (desde Johnny) y hacia dónde mira
	for caso in [["abajo", Vector2(200, 160), Vector2(0, -220), "s"],
			["arriba", Vector2(200, -160), Vector2(0, 220), "n"], ["lado", Vector2(300, 40), Vector2(-240, 0), "e"],
			["diagonal", Vector2(120, 140), Vector2(170, -170), "so"],
			["espalda", Vector2(100, -160), Vector2(160, 170), "no"],
			["pared", Vector2(430, 40), Vector2(-200, 0), "e"]]:
		johnny.global_position = sala.diana.global_position + caso[1]
		gerente.global_position = johnny.global_position + caso[2]
		gerente.velocity = Vector2.ZERO
		gerente.marcha = Vector2.ZERO
		gerente.espera_mutado.embestida = 99.0   # (que solo dé latigazos, y cuando se le dice)
		gerente.espera_mutado.latigazo = 99.0
		Temblor.desplazamiento = caso[2] + (-caso[2].normalized() * 340.0 + Vector2(0, -350)) / 2.0
		camara.reset_smoothing()
		gerente.empezar("aviso_latigazo", (johnny.global_position - gerente.global_position).angle())
		while not (gerente.estado == "aviso_latigazo" and gerente.t >= 0.55):
			await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		Captura.foto("captura-latigazos-aviso-%s.png" % caso[0])
		var avisando := "%s/%d" % [gerente.sprite.animation, gerente.sprite.frame]
		while not (gerente.estado == "latigazo" and gerente.t >= 0.08):
			await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		Captura.foto("captura-latigazos-latigazo-%s.png" % caso[0])
		var llegan := []
		for tentaculo in gerente.tentaculos:
			llegan.append("%d%s" % [tentaculo.llega, " (choca)" if tentaculo.choca else ""])
		print("Latigazos con Johnny %s: avisando %s · latigazo %s/%d · llegan a %s (esperado: latigazo_%s; %s)" % [
			caso[0], avisando, gerente.sprite.animation, gerente.sprite.frame, ", ".join(llegan), caso[3],
			"chocan antes de 340" if caso[0] == "pared" else "340 sin chocar"])
		while gerente.estado == "latigazo":
			await get_tree().physics_frame
	Temblor.desplazamiento = Vector2.ZERO
	get_tree().quit()


# --lenguas: las lenguas del Glotón y de la criatura del científico mutado (lengua.gd), en la sala de pruebas (F9):
# avisando (captura-lenguas-<quién>-aviso-<caso>.png) y dando el golpe (captura-lenguas-<quién>-golpe-<caso>.png), con
# Johnny abajo, arriba, de lado, en diagonal y junto a la pared de la derecha (que las corta: el aviso acaba en
# estrella); el Glotón, también enfadado (seis lenguas). La cámara, algo más lejos, sin los límites de la sala y
# centrada entre el jefe y sus lenguas; y, de cerca (a 2, -cerca), la boca y el principio de las lenguas abajo y de
# lado. En la terminal, la animación y hasta dónde llega cada lengua (y si choca)
func probar_lenguas() -> void:
	await pulsar_y_esperar(KEY_F9)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no tape las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	if not SalaArmas.escondido:   # ni el panel de daño ni las líneas
		await pulsar_y_esperar(KEY_MINUS)
	johnny.modo = "quieto"
	johnny.invencible = true
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(0.85, 0.85)
	camara.limit_left = -100000
	camara.limit_top = -100000
	camara.limit_right = 100000
	camara.limit_bottom = 100000
	var gloton: Node2D = meter_zombi("gloton", sala.diana.global_position + Vector2(200, -60))
	var criatura: Node2D = meter_zombi("cientifico_jefe", sala.diana.global_position + Vector2(-200, -300))
	await get_tree().create_timer(0.2).timeout
	criatura.mutar()
	await get_tree().create_timer(1.6).timeout
	criatura.global_position = sala.diana.global_position + Vector2(-2000, 0)   # (fuera y quieta, mientras va el Glotón)
	criatura.process_mode = Node.PROCESS_MODE_DISABLED
	# Cada caso: quién, nombre, dónde está Johnny (desde la diana), dónde el jefe (desde Johnny) y hacia dónde mira
	for caso in [["gloton", "abajo", Vector2(200, 160), Vector2(0, -220), "s"],
			["gloton", "arriba", Vector2(200, -160), Vector2(0, 220), "n"],
			["gloton", "lado", Vector2(300, 40), Vector2(-220, 0), "e"],
			["gloton", "diagonal", Vector2(120, 140), Vector2(160, -160), "so"],
			["gloton", "enfadado", Vector2(200, 160), Vector2(-150, -160), "se"],
			["gloton", "pared", Vector2(430, 40), Vector2(-180, 0), "e"],
			["gloton", "abajo-cerca", Vector2(200, 160), Vector2(0, -220), "s"],
			["gloton", "lado-cerca", Vector2(300, 40), Vector2(-220, 0), "e"],
			["criatura", "abajo", Vector2(200, 160), Vector2(0, -240), "s"],
			["criatura", "arriba", Vector2(200, -160), Vector2(0, 240), "n"],
			["criatura", "lado", Vector2(300, 40), Vector2(-240, 0), "e"],
			["criatura", "espalda", Vector2(100, -160), Vector2(170, 170), "no"],
			["criatura", "pared", Vector2(430, 40), Vector2(-200, 0), "e"],
			["criatura", "abajo-cerca", Vector2(200, 160), Vector2(0, -240), "s"],
			["criatura", "lado-cerca", Vector2(300, 40), Vector2(-240, 0), "e"]]:
		var jefe: Node2D = gloton if caso[0] == "gloton" else criatura
		if caso[0] == "criatura" and gloton != null:
			gloton.global_position = sala.diana.global_position + Vector2(-2000, 400)
			gloton.process_mode = Node.PROCESS_MODE_DISABLED
			gloton = null
			criatura.process_mode = Node.PROCESS_MODE_INHERIT
		johnny.global_position = sala.diana.global_position + caso[2]
		jefe.global_position = johnny.global_position + caso[3]
		jefe.velocity = Vector2.ZERO
		jefe.marcha = Vector2.ZERO
		var angulo: float = (johnny.global_position - jefe.global_position).angle()
		var cerca: bool = caso[1].ends_with("cerca")
		camara.zoom = Vector2(2, 2) if cerca else Vector2(0.85, 0.85)
		Temblor.desplazamiento = caso[3] - caso[3].normalized() * (70.0 if cerca else 150.0) + Vector2(0,
			-60 if caso[0] == "gloton" else -110)
		camara.reset_smoothing()
		var aviso := "aviso_latigazo" if caso[0] == "gloton" else "aviso_lenguas"
		var golpe := "latigazo" if caso[0] == "gloton" else "lenguas"
		if caso[0] == "gloton":
			jefe.fase = 2 if caso[1] == "enfadado" else 1
			jefe.espera_latigazo = 99.0   # (que solo dé latigazos, y cuando se le dice)
			jefe.espera_aspirar = 99.0
			jefe.mirada = Vector2.from_angle(angulo)
			jefe.cambiar(aviso, {"angulo": angulo})
		else:
			for k in jefe.espera_criatura:
				jefe.espera_criatura[k] = 99.0
			jefe.empezar(aviso, angulo)
		while not (jefe.estado == aviso and jefe.t >= 0.55):
			await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		Captura.foto("captura-lenguas-%s-aviso-%s.png" % [caso[0], caso[1]])
		var avisando := "%s/%d" % [jefe.sprite.animation, jefe.sprite.frame]
		while not (jefe.estado == golpe and jefe.t >= 0.12):
			await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		Captura.foto("captura-lenguas-%s-golpe-%s.png" % [caso[0], caso[1]])
		var llegan := []
		for lengua in jefe.lenguas.slice(0, jefe.angulos_lenguas().size()):
			llegan.append("%d%s" % [lengua.llega, " (choca)" if lengua.choca else ""])
		print("Lenguas del %s con Johnny %s: avisando %s · golpe %s/%d · llegan a %s (esperado: mirando al %s; %s)" % [
			caso[0], caso[1], avisando, jefe.sprite.animation, jefe.sprite.frame, ", ".join(llegan), caso[4],
			"chocan antes de su largo" if caso[1] == "pared" else "todas a su largo, sin chocar"])
		while jefe.estado == golpe:
			await get_tree().physics_frame
	Temblor.desplazamiento = Vector2.ZERO
	get_tree().quit()


# --disparos: las barras de aviso de los disparos de los jefes (aviso.gd, barra) en la sala de pruebas (F9): los
# contratos del gerente, los alfileres de la modista, los cuchillos del cocinero y las bolas de fuego de la criatura del
# científico, junto a la pared de la derecha (que las corta, como corta a los disparos) y en campo abierto
# (captura-disparos-<quién>-<caso>.png). Cada jefe, quieto y con el aviso casi lleno. En la terminal, hasta dónde llega
# cada barra, a cuánto queda la pared de verdad (un rayo de la capa 1) y lo largas que serían sin pared
func probar_disparos() -> void:
	await pulsar_y_esperar(KEY_F9)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no tape las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	if not SalaArmas.escondido:   # ni el panel de daño ni las líneas
		await pulsar_y_esperar(KEY_MINUS)
	johnny.modo = "quieto"
	johnny.invencible = true
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(0.85, 0.85)
	camara.limit_left = -100000
	camara.limit_top = -100000
	camara.limit_right = 100000
	camara.limit_bottom = 100000
	print("Sala de pruebas: %d x %d" % [mapa.sitio.ancho, mapa.sitio.alto])
	# Cada caso: quién, nombre, dónde está Johnny (desde la diana) y dónde el jefe (desde Johnny)
	for caso in [["gerente", "pared", Vector2(430, 40), Vector2(-200, 0)],
			["gerente", "libre", Vector2(200, 160), Vector2(0, -220)],
			["modista", "pared", Vector2(430, 40), Vector2(-200, 0)],
			["modista", "libre", Vector2(200, 160), Vector2(0, -220)],
			["cocinero", "pared", Vector2(430, 40), Vector2(-200, 0)],
			["cocinero", "libre", Vector2(200, 160), Vector2(0, -220)],
			["cientifico_jefe", "pared", Vector2(430, 40), Vector2(-200, 0)],
			["cientifico_jefe", "libre", Vector2(200, 160), Vector2(0, -220)]]:
		johnny.global_position = sala.diana.global_position + caso[2]
		var jefe: Node2D = meter_zombi(caso[0], johnny.global_position + caso[3])
		await get_tree().create_timer(0.2).timeout
		if caso[0] == "cientifico_jefe":
			jefe.mutar()
			await get_tree().create_timer(1.6).timeout
		jefe.global_position = johnny.global_position + caso[3]
		jefe.velocity = Vector2.ZERO
		jefe.marcha = Vector2.ZERO
		var angulo: float = (johnny.global_position - jefe.global_position).angle()
		Temblor.desplazamiento = caso[3] - caso[3].normalized() * 150.0 + Vector2(0, -60)
		camara.reset_smoothing()
		var dura := 0.5
		var entero := 0.0   # lo larga que sería la barra sin pared
		match caso[0]:
			"gerente":
				dura = jefe.AVISO_CONTRATOS[0]
				entero = jefe.radio + jefe.LARGO_RAYAS
				jefe.empezar("aviso_contratos", angulo)
			"modista":
				dura = jefe.AVISO_ALFILERES[0]
				entero = jefe.radio + jefe.ALCANCE_ALFILERES
				jefe.apuntar_alfileres(Vector2.from_angle(angulo))
			"cocinero":
				dura = jefe.AVISO_ABANICO
				entero = jefe.radio + jefe.LARGO_RAYAS
				jefe.empezar("aviso_abanico", angulo)
			"cientifico_jefe":
				dura = jefe.AVISO_FUEGO
				entero = jefe.radio + 320.0
				jefe.empezar("aviso_fuego", angulo)
		jefe.set_physics_process(false)   # quieto, con el aviso a mano
		jefe.t = dura * 0.9
		for i in 6:   # (sin pensar, el jefe no se repinta solo)
			jefe.queue_redraw()
			await RenderingServer.frame_post_draw
		Captura.foto("captura-disparos-%s-%s.png" % [caso[0], caso[1]])
		var barras := []
		for hijo in jefe.get_children():
			if hijo is Aviso and hijo.forma == 2 and hijo.visible:
				var origen: Vector2 = jefe.to_global(hijo.desde)
				var rayo := PhysicsRayQueryParameters2D.create(origen, origen + Vector2.from_angle(hijo.angulo) * 3000.0, 1)
				var choque := jefe.get_world_2d().direct_space_state.intersect_ray(rayo)
				barras.append("%d%s (pared a %s)" % [roundi(hijo.largo), " con estrella" if hijo.choca else "",
					str(roundi(origen.distance_to(choque.position))) if not choque.is_empty() else "ninguna"])
		print("Disparos del %s, caso %s: %d barras, llegan a %s · sin pared serían de %d (esperado: a 1 o 2 de la pared y con estrella si queda antes; si no, enteras y sin ella)" % [
			caso[0], caso[1], barras.size(), ", ".join(barras), roundi(entero)])
		jefe.queue_free()
		await get_tree().create_timer(0.2).timeout
	Temblor.desplazamiento = Vector2.ZERO
	get_tree().quit()


# --golpes-pared: ¿los golpes de los jefes (porrazo, fregonazo, tijeretazo, cuchillazo, maletinazo y hachazo, y los de
# área: el círculo de la portera, los saltos de la mascota y del Gymbro y la onda de la criatura) atraviesan las
# paredes? En la sala de pruebas (F9), cada jefe pegando (se llama a su golpe) con Johnny justo al otro lado de la
# pared de la derecha, a su alcance, y, de control, con Johnny a la misma distancia en campo abierto. En la terminal,
# si el golpe le quita vida y si hay pared entre los dos (un rayo de la capa 1); y, con fotos, el aviso de cada uno a
# 45 de la pared (captura-golpes-pared-<nombre>.png): cortado donde el golpe se pararía
func probar_golpes_pared() -> void:
	await pulsar_y_esperar(KEY_F9)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no tape las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	if not SalaArmas.escondido:   # ni el panel de daño ni las líneas
		await pulsar_y_esperar(KEY_MINUS)
	johnny.modo = "quieto"
	johnny.invencible = false   # (que se le quite vida de verdad)
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(2, 2)
	camara.limit_left = -100000
	camara.limit_top = -100000
	camara.limit_right = 100000
	camara.limit_bottom = 100000
	# dónde está la pared de la derecha, de un borde al otro (un rayo desde cada lado)
	var espacio: PhysicsDirectSpaceState2D = johnny.get_world_2d().direct_space_state
	var y := sala.diana.global_position.y + 40.0
	var x0 := sala.diana.global_position.x
	var izq: Dictionary = espacio.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x0 + 300, y), Vector2(x0 + 900, y), 1))
	var der: Dictionary = espacio.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x0 + 900, y), Vector2(x0 + 300, y), 1))
	var borde_izq: float = izq.position.x
	var borde_der: float = der.position.x
	print("Pared de la derecha: de %d a %d (grosor %d)" % [borde_izq, borde_der, borde_der - borde_izq])
	for tipo in ["antidisturbios", "portera", "modista", "cocinero", "gerente", "bombero", "portera_circulo", "mascota_salto",
			"gymbro_salto", "criatura_onda"]:
		for caso in ["pared", "abierto"]:
			var sitio_jefe := Vector2(borde_izq - 4.0, y)
			var sitio_johnny := Vector2(borde_der + 6.0, y)
			if caso == "abierto":
				sitio_johnny.x = sitio_jefe.x - (sitio_johnny.x - sitio_jefe.x)
			var clase: String = {"portera_circulo": "portera", "mascota_salto": "mascota", "gymbro_salto": "gymbro",
					"criatura_onda": "cientifico_jefe"}.get(tipo, tipo)
			var jefe: Node2D = meter_zombi(clase, sitio_jefe)
			await get_tree().create_timer(0.2).timeout
			if tipo == "criatura_onda":
				jefe.mutar()
				await get_tree().create_timer(1.6).timeout
			jefe.set_physics_process(false)   # quieto: el golpe se le pide a mano
			jefe.global_position = sitio_jefe
			johnny.global_position = sitio_johnny
			johnny.velocity = Vector2.ZERO
			johnny.vida = 100
			johnny.escudo = 0.0
			johnny.invulnerable = 0.0
			johnny.esquiva_t = 0.0
			var angulo: float = (sitio_johnny - sitio_jefe).angle()
			jefe.mirada = Vector2.from_angle(angulo)
			jefe.datos = {"angulo": angulo, "hasta": sitio_jefe}
			camara.reset_smoothing()
			match tipo:
				"antidisturbios":
					jefe.porrazo(johnny)
				"portera":
					jefe.fregonazo(johnny)
				"modista":
					jefe.tijeretazo(johnny)
				"cocinero":
					jefe.cuchillazo(johnny)
				"gerente":
					jefe.maletinazo(johnny)
				"bombero":
					jefe.dar_hachazo(johnny)
				"portera_circulo":
					jefe.fregonazo_circulo(johnny)
				"mascota_salto", "gymbro_salto":
					jefe.aterrizar(johnny)
				"criatura_onda":
					jefe.t = jefe.DURA_ONDA
					jefe.onda(johnny)
			var tapado: bool = not espacio.intersect_ray(PhysicsRayQueryParameters2D.create(sitio_jefe, sitio_johnny, 1)).is_empty()
			print("Ataque «%s», caso %s: a %d de Johnny, con pared en medio %s · le quita %d de vida (si no atraviesa: con pared, 0; en abierto, más de 0)" % [
				tipo, caso, sitio_jefe.distance_to(sitio_johnny), "sí" if tapado else "no", 100 - johnny.vida])
			jefe.queue_free()
			await get_tree().create_timer(0.1).timeout
	# Y el aviso de cada golpe, a 45 de la pared de la derecha y mirando hacia ella: cortado donde el golpe se pararía
	# (captura-golpes-pared-<nombre>.png). Cada caso: nombre, jefe, estado del aviso, constante de lo que dura y zoom
	for g in [["antidisturbios", "antidisturbios", "aviso_porrazo", "AVISO_PORRAZO", 2.0],
			["portera", "portera", "aviso_fregonazo", "AVISO_FREGONAZO", 2.0],
			["modista", "modista", "aviso_tijeretazo", "AVISO_TIJERETAZO", 2.0],
			["cocinero", "cocinero", "aviso_cuchillazo", "AVISO_CUCHILLAZO", 2.0],
			["gerente", "gerente", "aviso_maletinazo", "AVISO_MALETINAZO", 2.0],
			["bombero", "bombero", "aviso_hacha", "AVISO_HACHA", 2.0],
			["portera-circulo", "portera", "aviso_circulo", "AVISO_CIRCULO", 1.2],
			["mascota-salto", "mascota", "salto", "VUELO", 1.2],
			["gymbro-salto", "gymbro", "salto", "VUELO", 1.2],
			["criatura-onda", "cientifico_jefe", "aviso_punetazo", "AVISO_PUNETAZO", 1.2]]:
		var sitio_jefe := Vector2(borde_izq - 45.0, y)
		var jefe: Node2D = meter_zombi(g[1], sitio_jefe)
		await get_tree().create_timer(0.2).timeout
		jefe.set_physics_process(false)   # quieto, con el aviso a mano
		jefe.global_position = sitio_jefe
		johnny.global_position = sitio_jefe + Vector2(-120, 0)
		var dura = jefe.get_script().get_script_constant_map()[g[3]]
		if dura is Array:
			dura = dura[0]
		jefe.mirada = Vector2.RIGHT
		jefe.cambiar(g[2], {"angulo": 0.0, "desde": sitio_jefe, "hasta": sitio_jefe, "vuelo": dura, "quedan": 0})
		jefe.t = dura * 0.9
		camara.zoom = Vector2(g[4], g[4])
		Temblor.desplazamiento = Vector2(150, -20) if g[4] > 1.5 else Vector2(120, 0)
		camara.reset_smoothing()
		for i in 6:   # (sin pensar, el jefe no se repinta solo)
			jefe.queue_redraw()
			await RenderingServer.frame_post_draw
		Captura.foto("captura-golpes-pared-%s.png" % g[0])
		jefe.queue_free()
		await get_tree().create_timer(0.1).timeout
	Temblor.desplazamiento = Vector2.ZERO
	get_tree().quit()


# Con "--captura --derrota": el cartel de derrota (menus.gd, fin). Primero, quién le pega a Johnny (johnny.gd,
# golpe_de): un zombi, la explosión del dinamitero, su propia granada y el fuego del suelo. Luego cae de verdad por
# un crío, con un logro, una skin, una página, un enemigo y un objeto nuevos y su mejor marca (captura-derrota.png);
# «Otra vez» y la R no hacen caso el primer medio segundo y luego sí. Y el cartel otra vez: por el fuego y sin nada
# nuevo (captura-derrota-fuego.png), por un jefe grande (captura-derrota-jefe.png) y ganando (captura-derrota-gana.png)
func probar_derrota() -> void:
	await get_tree().create_timer(0.5).timeout
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no se meta)
		a.process_mode = Node.PROCESS_MODE_DISABLED
	johnny.resucitado = true   # (sin el Desfibrilador, por si lo tiene el guardado de prueba)
	johnny.vida = 99999        # (que los golpes de prueba no lo tiren)
	# 1) quién le pega: cada golpe apunta quién ha sido
	var quien: Array = []
	for de in ["explosivo", "granada"]:
		johnny.invulnerable = 0.0
		var bum: Node2D = load("res://escenas/armas/explosion.tscn").instantiate()
		bum.de = de
		bum.position = johnny.global_position - mapa.cosas.global_position
		mapa.cosas.add_child(bum)
		await get_tree().process_frame
		quien.append(johnny.golpe_de)
	var paso := 0.0
	while paso < 0.5:   # el fuego del suelo, medio segundo
		johnny.pisar({"fuego": {}})
		await get_tree().physics_frame
		paso += get_physics_process_delta_time()
	quien.append(johnny.golpe_de)
	johnny.estados.clear()
	var crio: Node2D = meter_zombi("rapido", johnny.position + Vector2(120, 0))
	johnny.invulnerable = 0.0
	johnny.recibir_dano(1, crio)
	quien.append(johnny.golpe_de)
	print("Quién le pega: %s (esperado: [\"explosivo\", \"granada\", \"fuego\", \"rapido\"])" % [quien])
	# 2) lo conseguido: que al empezar le faltasen un logro, una skin, una página, un enemigo y un objeto, y que esta
	# sea su planta más alta
	Guardado.cambiar(func(g):
		g.logros["primer_turno"] = "conseguido"
		for par in [["skins", "portero"], ["paginas", "vd7_protocolo"], ["bestiario", "rapido"], ["encontrados", "vendas"]]:
			if not par[1] in g[par[0]]:
				g[par[0]].append(par[1]))
	al_empezar.logros.erase("primer_turno")
	for par in [["skins", "portero"], ["paginas", "vd7_protocolo"], ["bestiario", "rapido"], ["encontrados", "vendas"]]:
		al_empezar[par[0]].erase(par[1])
	al_empezar.mejor_planta = 2
	var empezo := al_empezar.duplicate(true)
	planta.num = 3
	planta.nombre = Planta.nombre_planta_es(3)
	# 3) cae por el crío: el cartel sale solo, al segundo
	johnny.invulnerable = 0.0
	johnny.vida = 10
	johnny.recibir_dano(9999, crio)
	while menus.abierto != "fin":
		await get_tree().process_frame
	# «Otra vez» y la R: sin volver a empezar de verdad, se cuenta cuántas veces piden volver a empezar
	for c in menus.reintentar.get_connections():
		menus.reintentar.disconnect(c.callable)
	var otra_vez := [0]
	menus.reintentar.connect(func(): otra_vez[0] += 1)
	var boton: Button = menus.fondo.find_children("*", "Button", true, false)[0]
	boton.pressed.emit()
	pulsar_r()
	await get_tree().create_timer(0.1).timeout
	var antes: int = otra_vez[0]
	await get_tree().create_timer(0.6).timeout
	print("Cae por «%s» · «%s» · conseguido: %d filas · al abrirse, «Otra vez» y la R: %d veces (esperado: 0)" % [
		johnny.golpe_de, boton.text, conseguido(Guardado.cargar()).size(), antes])
	Captura.foto("captura-derrota.png")
	boton.pressed.emit()
	pulsar_r()
	await get_tree().create_timer(0.1).timeout
	print("Pasado medio segundo, «Otra vez» y la R: %d veces (esperado: 2)" % otra_vez[0])
	# 4) por el fuego y sin nada nuevo; por un jefe grande (con todo lo nuevo); y ganando (con todo lo nuevo)
	for caso in [["fuego", false, false], ["gloton", true, false], ["", true, true]]:
		terminada = false
		al_empezar = empezo.duplicate(true) if caso[1] else {}
		johnny.golpe_de = caso[0]
		if caso[2]:
			planta.num = Planta.PLANTAS
			planta.nombre = Planta.nombre_planta_es(Planta.PLANTAS)
		terminar(caso[2])
		await get_tree().create_timer(0.5).timeout
		Captura.foto("captura-derrota-%s.png" % ("gana" if caso[2] else "jefe" if caso[1] else caso[0]))
	get_tree().quit()


# Pulsa y suelta la R (la del cartel del final)
func pulsar_r() -> void:
	for pulsada in [true, false]:
		var evento := InputEventKey.new()
		evento.keycode = KEY_R
		evento.physical_keycode = KEY_R
		evento.pressed = pulsada
		Input.parse_input_event(evento)


# Con "--captura --continuar": la partida a medias (partida_guardada.gd). Primero, con Johnny cambiado (menos vida, un
# bate Raro, vendas, una mutación, dólares y molotov), sube a la 1ª planta: se guarda. Luego, como si se cerrara el
# juego, al menú (captura-menu.png, con «Continuar partida») y de él a la partida guardada, que tiene que salir en la
# misma planta, igual, y con lo mismo encima (captura-continuar.png). Se borra la guardada y se cierra
static var continuar_antes := {}   # lo de la primera vuelta, para compararlo en la segunda

func probar_continuar() -> void:
	var firma := func() -> String:
		return str(planta.sitios.map(func(x): return [x.get("nombre", ""), x.get("ancho", 0), x.get("alto", 0)]))
	var lleva := func() -> Dictionary:
		return {"planta": planta.num, "firma": firma.call(), "vida": johnny.vida, "huecos": johnny.huecos.duplicate(),
			"calidades": johnny.calidades.duplicate(), "mochila": mochila.duplicate(), "dolares": dolares,
			"mutaciones": mutaciones.tengo.duplicate(), "molotov": lanzables.cantidades.molotov,
			"jefes": orden_jefes.duplicate(), "partidas": Guardado.cargar().partidas}
	await get_tree().create_timer(0.5).timeout
	if continuar_antes.is_empty():
		johnny.vida = 40
		llevar_arma("bate", 2, true, false)
		mochila.append("vendas")
		elegir_mutacion(Mutaciones.LISTA[0].id)
		dolares = 12
		lanzables.cantidades.molotov = 5
		await subir()
		await get_tree().create_timer(0.5).timeout
		continuar_antes = lleva.call()
		var foto := PartidaGuardada.guardada()
		print("Continuar · guardada al subir: %s, en la planta %d (esperado: true y 2)" % [not foto.is_empty(), foto.get("planta", 0)])
		# como si se cerrara el juego: de vuelta al menú, que la abre él solo (menu_principal.gd)
		get_tree().change_scene_to_file("res://escenas/menu_principal.tscn")
		return
	var ahora: Dictionary = lleva.call()
	for clave in continuar_antes:
		if clave != "vida":
			print("Continuar · %s igual: %s (esperado: true)" % [clave, ahora[clave] == continuar_antes[clave]])
	# (la vida es la de la foto, tomada antes de subir: subir no cura)
	print("Continuar · vida %d (esperado: %d)" % [ahora.vida, continuar_antes.vida])
	Captura.foto("captura-continuar.png")
	PartidaGuardada.borrar()
	print("Continuar · borrada al acabar: %s (esperado: true)" % PartidaGuardada.guardada().is_empty())
	get_tree().quit()


# --guiado: el tutorial disimulado de la primera partida (guia.gd): las pistas encima de Johnny en orden, el latido del
# HUD, la flecha del suelo, el apartamento fácil, la llavecita del zombi de la llave y que no sale ninguna ventana
func probar_guiado() -> void:
	johnny.invencible = true
	var ventanas := func() -> int:
		return get_children().filter(func(h): return h is Tutorial).size()
	# espera a que salga la pista "id" (o se canse) y saca su foto
	var esperar := func(id: String, foto: String) -> void:
		for _i in 40:
			if guia.pista == id:
				break
			await get_tree().create_timer(0.1).timeout
		await get_tree().create_timer(0.4).timeout
		print("Guía · pista «%s» (esperado: %s) · latido «%s»" % [guia.pista, id, get_node("Pantalla/HUD").latido])
		Captura.foto(foto)
	await get_tree().create_timer(0.5).timeout
	print("Guía · activa: %s (esperado: true)" % guia.activa)
	await esperar.call("moverse", "captura-guiado-moverse.png")
	johnny.position += Vector2(120, 0)
	await get_tree().create_timer(1.6).timeout
	await esperar.call("esquivar", "captura-guiado-esquivar.png")
	johnny.esquivar(Vector2.LEFT)
	await get_tree().create_timer(1.8).timeout
	print("Guía · flecha a la vista en la sala de mantenimiento: %s (esperado: true)" % guia.flecha.visible)
	Captura.foto("captura-guiado-flecha.png")
	# el pasillo: el aviso y la flecha hacia el apartamento fácil
	await montar(0, planta.sitios[aqui].salidas[0].vuelta)
	await get_tree().create_timer(0.8).timeout
	var facil: Dictionary = planta.sitios[guia.facil]
	var puerta_facil := -1
	for i in planta.sitios[0].salidas.size():
		if planta.sitios[0].salidas[i].get("a", -1) == guia.facil:
			puerta_facil = i
	print("Guía · en el pasillo la flecha lleva al fácil: %s · visto «apartamentos»: %s (esperado: true, true)" % [
		guia.destino() == mapa.puertas[puerta_facil], Tutoriales.visto("apartamentos")])
	Captura.foto("captura-guiado-pasillo.png")
	print("Guía · el fácil: %d zombis, con la llave %s, armarito %s (esperado: ≤%d, false, vendas)" % [facil.zombis.size(),
		facil.zombis.any(func(z): return z.get("llave", false)),
		facil.armaritos[0].dentro if not facil.get("armaritos", []).is_empty() else "sin baño", Guia.FACIL])
	# el apartamento fácil: los zombis, despiertos y quietos, a la vista
	await montar(guia.facil, 0)
	await get_tree().create_timer(0.3).timeout
	var zombis := get_tree().get_nodes_in_group("zombis")
	for i in zombis.size():
		zombis[i].dormido = false
		zombis[i].set_physics_process(false)
		zombis[i].position = johnny.position + Vector2(-200 + 200 * i, -330)   # (más lejos que Guia.CERCA)
	johnny.set_physics_process(false)   # (quieto: que no los mate ni gaste las balas él solo en el modo asistido)
	await esperar.call("atacar", "captura-guiado-atacar.png")
	await get_tree().create_timer(4.2).timeout   # (en el modo asistido se va sola a los 4 s)
	await esperar.call("pistola", "captura-guiado-pistola.png")
	johnny.cambiar_mano()
	await get_tree().create_timer(1.7).timeout
	johnny.balas = 2
	await esperar.call("recargar", "captura-guiado-recargar.png")
	johnny.empezar_recarga()
	await get_tree().create_timer(1.7).timeout
	mochila.append("vendas")
	johnny.vida = johnny.stats.vida_max - 30
	await esperar.call("vendas", "captura-guiado-vendas.png")
	usar_cura("vendas")
	await get_tree().create_timer(1.7).timeout
	for i in zombis.size():
		zombis[i].position = johnny.position + Vector2(-120 + 120 * i, -150)
	await esperar.call("lanzar", "captura-guiado-lanzar.png")
	lanzables.cantidades[lanzables.tipo] -= 1
	await get_tree().create_timer(1.7).timeout
	print("Guía · vistos jugar %s, municion %s, curas %s, lanzables %s · ventanas abiertas: %d (esperado: true ×4, 0)" % [
		Tutoriales.visto("jugar"), Tutoriales.visto("municion"), Tutoriales.visto("curas"), Tutoriales.visto("lanzables"),
		ventanas.call()])
	# el zombi de la llave, en otro apartamento: su llavecita y el aviso al despertar
	for z in zombis:
		z.queue_free()
	johnny.set_physics_process(true)
	var con_llave := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "apartamento" and planta.sitios[i].zombis.any(func(z): return z.get("llave", false)):
			con_llave = i
	await montar(con_llave, 0)
	await get_tree().create_timer(0.3).timeout
	for z in get_tree().get_nodes_in_group("zombis"):
		if z.has_meta("llave"):
			z.dormido = false
			z.set_physics_process(false)
			z.position = johnny.position + Vector2(0, -170)
			print("Guía · el zombi de la llave lleva su llavecita: %s (esperado: true)" % (z.get_node_or_null("MarcaLlave") != null))
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-guiado-llave.png")
	# al subir a la planta siguiente, se apaga
	nueva_planta(2)
	print("Guía · en la 1ª planta: activa %s (esperado: false)" % guia.activa)
	get_tree().quit()


# --pantalla: la pantalla completa del ordenador (pantalla.gd): F11 y Alt+Intro la ponen y la quitan, el ajuste se guarda
# y F9 (la sala de pruebas) sigue yendo aparte
func probar_pantalla() -> void:
	var pulsar := func(tecla: Key, alt := false) -> void:
		for pulsada in [true, false]:
			var evento := InputEventKey.new()
			evento.keycode = tecla
			evento.alt_pressed = alt
			evento.pressed = pulsada
			Input.parse_input_event(evento)
		await get_tree().create_timer(0.6).timeout
	var estado := func() -> String:
		return "completa" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "ventana"
	await get_tree().create_timer(0.5).timeout
	Guardado.cambiar(func(g): g.ajustes.pantalla_completa = false)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await get_tree().create_timer(0.3).timeout
	print("Pantalla · al empezar: %s (esperado: ventana)" % estado.call())
	await pulsar.call(KEY_F11)
	print("Pantalla · tras F11: %s · guardado %s (esperado: completa, true)" % [estado.call(), Guardado.ajuste("pantalla_completa")])
	await pulsar.call(KEY_ENTER, true)
	print("Pantalla · tras Alt+Intro: %s · guardado %s (esperado: ventana, false)" % [estado.call(), Guardado.ajuste("pantalla_completa")])
	await pulsar.call(KEY_ENTER)
	print("Pantalla · Intro sin Alt: %s (esperado: ventana)" % estado.call())
	await pulsar.call(KEY_F11)
	await pulsar.call(KEY_F11)
	print("Pantalla · F11 dos veces: %s (esperado: ventana)" % estado.call())
	get_tree().quit()
