# La partida de prueba ("-- --captura", ver CLAUDE.md): la partida de siempre (partida.gd) y, encima, las fotos
# y las comprobaciones que van saliendo en la terminal. La monta escenas/partida_prueba.tscn, que es la escena de
# la partida con este script en vez del suyo; con --captura, el menú abre esa en vez de la normal.
# Sin nada más, la prueba larga (_process, abajo): cuenta en la terminal qué planta ha salido, mete a Johnny en un
# apartamento, dispara para despertar a los zombis, guarda una foto en captura.png, sube a la planta siguiente,
# prueba al jefe, los menús, el ordenador, el inventario... y se cierra. Con algo más, solo una parte:
#   --fotos-tiendas, --fotos-luz, --fotos-ayudas   las fotos de las tiendas, de la luz o de las ayudas
#   --evento X     la prueba de ese evento sorpresa (eventos.gd)
#   --alerta N     las reglas de esa alerta (alerta.gd)
#   --jefe X       el minijefe de la 1ª planta del centro comercial (si no, el antidisturbios)
extends "res://scripts/partida.gd"

var tiempo := 0.0            # los segundos que lleva la prueba larga (_process)
var grito_visto := false     # fotos_tiendas: la foto del grito de la dependienta, solo una vez
var peligros_vistos := {}    # fotos_tiendas: los peligros que ya tienen sus fotos (fotos_peligros)


func _ready() -> void:
	captura = true
	super()


func preparar_prueba() -> void:
	Guardado.archivo = "user://guardado-prueba.json"   # la prueba no toca el guardado de verdad
	# con "--alerta 5", la prueba se juega con esa alerta (alerta.gd); sin él, sin alerta
	Alerta.nivel = int(Captura.dato("--alerta", "0"))
	# con "--evento apagon" (incendio, horda, vendedor), la prueba de ese evento sorpresa (eventos.gd)
	eventos.forzado = Captura.dato("--evento")


# En la prueba, el jefe que se ve es el de la 1ª planta (la segunda): que sea el antidisturbios, u otro con
# "--jefe cocinero", "--jefe modista" o "--jefe mascota"
func ordenar_jefes_prueba() -> void:
	var probar := Captura.dato("--jefe", "antidisturbios")
	if probar in orden_jefes:
		orden_jefes.erase(probar)
		orden_jefes.insert(1, probar)


# Ya en la sala de mantenimiento: la prueba que se haya pedido (si no, la larga, que sigue en _process)
func empezar_prueba() -> void:
	var args := OS.get_cmdline_user_args()
	if "--fotos-tiendas" in args:
		fotos_tiendas()
	elif "--fotos-luz" in args:
		fotos_luz()
	elif "--fotos-ayudas" in args:
		fotos_ayudas()
	elif eventos.forzado != "":
		set_process(false)   # sin la prueba larga
		eventos.probar(eventos.forzado)
	elif Reto.activo:
		set_process(false)   # sin la prueba larga
		probar_reto()
	elif Alerta.nivel > 0:
		set_process(false)   # sin la prueba larga
		probar_alerta()
	else:
		contar_planta()


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


# Con "--captura --fotos-luz": para ver si la luz se cuela por las paredes. Entra en el apartamento con más
# habitaciones, todas descubiertas (las lámparas encendidas) y sin zombis, y saca una foto con Johnny en
# cada habitación, justo debajo de un tabique con otra habitación detrás y mirándolo (captura-luz-<n>.png):
# la linterna tiene que quedarse en la pared y no alumbrar el suelo de detrás. Luego se cierra
func fotos_luz() -> void:
	set_process(false)
	$Pantalla/HUD.hide()
	var i := 1   # el apartamento con más habitaciones
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and (not planta.sitios[i].has("apt")
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


# Con "--captura --alerta N" (en vez de la prueba larga): comprueba las reglas de esa alerta (alerta.gd) con sus
# números en la terminal y saca captura-alerta.png (el aviso del principio), captura-alerta-llave.png (en los
# Apartamentos, el vecino que lleva la llave, que solo sale con la Alerta 5; en el centro comercial, el guardia) y
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
				for z in s.get("zombis", []).filter(func(z): return not z.get("llave", false)):
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
	# las rarezas del banco, en 2000 armas
	var rarezas := {"verde": 0, "azul": 0, "morada": 0}
	for i in 2000:
		rarezas[Recetas.rareza_al_azar()] += 1
	print("Banco · de 2000 armas: %d verdes, %d azules, %d moradas" % [rarezas.verde, rarezas.azul, rarezas.morada])
	# el guardia (centro) o el vecino de la llave (Apartamentos), en su sitio y sin penumbra para que se vea bien
	if ed.cerrojo == "tarjeta":
		await montar(0, 0, false)
		print("A5 · el guardia: vida %d" % guardia.vida_max)
		johnny.position = guardia.position + Vector2(-160, 40)   # (que no se quede en la puerta, que la cruzaría)
	else:
		var vecino := -1
		for i in planta.sitios.size():
			if planta.sitios[i].get("zombis", []).any(func(z): return z.get("llave", false)):
				vecino = i
		print("A5 · llave en el suelo: %s | vecino de la llave en %s" % [planta.llave.sitio >= 0,
			planta.sitios[vecino].nombre if vecino >= 0 else "ningún sitio"])
		if vecino >= 0:
			await montar(vecino, 0, false)
			for z in get_tree().get_nodes_in_group("zombis"):
				if z.has_meta("llave"):
					print("A5 · el vecino: vida %d" % z.vida_max)
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
					print("A5 · al caer: llave en %s, en el suelo: %s" % [planta.sitios[planta.llave.sitio].nombre
						if planta.llave.sitio >= 0 else "ningún sitio", mapa.cosas.has_node("Llave")])
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
		print("%s · munición: %s · oscuras: %s · botiquines: %s · vende botiquín/munición: %s/%s · velocidad %.0f · vida %d · zombis x%.1f · oído %.0f" % [
			Reto.nombre(), not Reto.sin_municion(), Reto.oscuras(), not Reto.sin_botiquines(), Reto.se_vende("botiquin"),
			Reto.se_vende("municion"), z.velocidad, johnny.stats.vida_max, Reto.mas_zombis(), Zombi.OIDO * Reto.oido()])
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
		johnny.balas, johnny.reserva, lanzables.cantidades.molotov, lanzables.cantidades.granada, Luz.nivel, Luz.evento,
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
		else "el guardia del pasillo" if ed.cerrojo == "tarjeta" else "un vecino (Alerta 5)"])


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
		Input.action_press("arma_4")
	if antes < 2.6 and tiempo >= 2.6:
		Input.action_release("arma_4")
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
		var antes_balas := "%s %d +%d" % [johnny.huecos.fuego, johnny.balas, johnny.reserva]
		johnny.balas = 0
		johnny.reserva = 0
		johnny.sostener("fuego")
		johnny.lista_para_disparar()
		var sin: String = johnny.mano
		johnny.sumar_municion()
		print("Balas: %s | sin balas pasa a %s | con una caja: %s %d +%d recargando %s" % [antes_balas, sin,
			johnny.mano, johnny.balas, johnny.reserva, johnny.recargando > 0.0])
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


# El cocinero, para la foto del jefe: un charco de aceite debajo de él (no le quema) y otro debajo de Johnny,
# unos cuchillos ya clavados, la lluvia marcando el suelo y el abanico recién lanzado
func probar_cocinero() -> void:
	var antes_johnny: int = johnny.vida
	# que nadie le dispare mientras tanto (ni Johnny solo, ni el superviviente que le acompaña): así se ve lo que
	# le quita su aceite
	var modo: String = johnny.modo
	johnny.modo = "mira"
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


# Colecciones (bestiario.gd y el programa del ordenador): deja en el guardado parte de lo que hay (8 objetos y los
# explosivos, tres o cuatro armas, cuatro o siete enemigos) y hace las fotos: el escritorio con el aviso de "¡NUEVO!"
# (captura-escritorio-nuevo.png), los objetos de este edificio (captura-colecciones.png), la ficha del vecino
# (captura-bestiario.png) y la del gerente, sin ver (captura-bestiario-falta.png). Luego cuenta en la terminal lo
# encontrado, creado y visto de cada edificio, y comprueba los totales
func probar_colecciones() -> void:
	# lo que la prueba ha ido apuntando sola (meter_zombi avisa al bestiario con cada enemigo que nace)
	print("Bestiario apuntado por la prueba hasta aquí: %s" % [Guardado.cargar().get("bestiario", [])])
	var encontrados: Array = Objetos.de_edificio(edificio).slice(0, 8)
	if not "explosivos" in encontrados:
		encontrados.append("explosivos")
	var creadas: Array = ["molotov", "lanza", "supermaza"]
	var vistos: Array = ["normal", "lento", "rapido", "portera"]
	if edificio == "centro":
		creadas.append("bate_helado")
		vistos += ["dependienta", "guardia", "antidisturbios"]
	Guardado.cambiar(func(g):
		g.encontrados = encontrados
		g.creadas = creadas
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
		var armas: Array = Recetas.de_edificio(e)
		var bichos: Array = Bestiario.de_edificio(e)
		print("Colecciones de %s: objetos %d/%d | armas %d/%d | bestiario %d/%d" % [e,
			objetos.filter(func(id): return id in g.encontrados).size(), objetos.size(),
			armas.filter(func(id): return id in g.creadas).size(), armas.size(),
			bichos.filter(func(id): return id in g.bestiario).size(), bichos.size()])
	if Objetos.de_edificio("apartamentos").size() != 17 or Objetos.de_edificio("centro").size() != 21:
		push_error("Colecciones: los objetos por edificio no son 17 y 21")
	if Recetas.de_edificio("apartamentos").size() != 15 or Recetas.de_edificio("centro").size() != 9:
		push_error("Colecciones: las recetas por edificio no son 15 y 9")
	if Bestiario.LISTA.size() != 17:
		push_error("Colecciones: el bestiario no tiene 17 fichas")
	if Bestiario.retrato("gerente_mutado") == null:
		push_error("Colecciones: el retrato del gerente mutado es null")
	if g.colecciones_nuevo:
		push_error("Colecciones: el aviso de nuevo sigue puesto después de abrir el programa")
	ordenador.abrir("")
	ordenador.apagar()


# Las noticias: en los Apartamentos, con la página del correo encontrada salen tres emisiones (dos sin ver); en el
# centro comercial, con los Apartamentos completados y sus dos primeras páginas, salen cinco (dos sin ver). Abre el
# programa, deja hablar a la reportera un poco y hace la foto
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
	ordenador.abrir("noticias")
	await get_tree().create_timer(3.0).timeout
	Captura.foto("captura-noticias.png")
	print("Noticias vistas tras abrir: ", Guardado.cargar().noticias_vistas)
	ordenador.abrir("")
	ordenador.apagar()


# La mochila, el banco y el baúl: unos objetos en la mochila y en el baúl, compra el bate (la fregona va al
# inventario), crea un arma con una receta sabida, prueba una sin saber, y hace fotos. Luego, las recetas que
# sueltan los jefes (probar_soltar_recetas)
func probar_cosas() -> void:
	Guardado.cambiar(func(g):
		g.dolares = 20
		g.baul = {"clavos": 1, "lejia": 2}
		g.baul_armas = []
		g.recetas = ["molotov", "aplastacabezas", "partecuerpos", "lanza"])
	ahorrados = 20
	mochila = ["gasolina", "gasolina", "cuchillas", "taser", "cuerda"]
	soltar_objeto("mechero", johnny.position + Vector2(30, 0))
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
	abrir_cosas("banco")
	inventario.tocar("r_aplastacabezas")   # el bate de la mano y los clavos del baúl
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-banco.png")
	inventario.crear_arma()
	inventario.tocar("r_bate_fuego")   # tiene la gasolina, pero no la receta (ni ya el bate): no hace nada
	inventario.crear_arma()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-banco2.png")
	print("Banco: creadas %s (solo el aplastacabezas)" % Guardado.cargar().baul_armas.map(func(a): return a.receta))
	inventario.cerrar()
	abrir_cosas("baul")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-baul.png")
	inventario.cerrar()
	var g := Guardado.cargar()
	print("Cosas: mochila %s | guardadas %s | mano %s | baúl %s | armas del baúl %s" % [mochila, armas_guardadas,
		johnny.huecos.cuerpo, g.baul, g.baul_armas.map(func(a): return "%s %s %d" % [a.nombre, a.rareza, a.dano])])


# Las armas creadas (fase 7b2): saca cinco del baúl, golpea con la inmovilizadora, lanza el bumerán, se pone
# el desintegrador desde el inventario y dispara, y lanza la congeladora. Cuenta lo que pasa y hace una foto
func probar_creadas() -> void:
	Guardado.cambiar(func(g): g.baul_armas = [Recetas.crear("inmovilizadora", "morada"), Recetas.crear("desintegrador"),
		Recetas.crear("bumeran"), Recetas.crear("congeladora"), Recetas.crear("molotov")])
	var molotovs: int = lanzables.cantidades.molotov
	abrir_cosas("baul")
	for i in 5:
		inventario.tocar("a0")
		inventario.sacar()
	inventario.cerrar()
	print("Creadas sacadas: mano %s | guardadas %s | molotovs %d -> %d | lanzables %s | baúl %d" % [
		[Objetos.nombre(johnny.huecos.cuerpo), Objetos.nombre(johnny.huecos.fuego)], armas_guardadas.map(Objetos.nombre),
		molotovs, lanzables.cantidades.molotov, lanzables.tipos(), Guardado.cargar().baul_armas.size()])
	johnny.direccion = "e"
	johnny.sostener("cuerpo")
	var z1 := meter_zombi("lento", johnny.position + Vector2(40, 0))
	var z2 := meter_zombi("lento", johnny.position + Vector2(100, 10))
	z1.vida = 500   # que no muera ninguno (saldría el recuadro de las mutaciones y pararía el juego)
	z2.vida = 500
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	print("Inmovilizadora: zombi 1 aturdido %.1f vida %d | zombi 2 aturdido %.1f vida %d" % [z1.aturdido, z1.vida, z2.aturdido, z2.vida])
	johnny.sostener("fuego")
	johnny.disparar(0.0)
	await get_tree().create_timer(0.3).timeout
	print("Bumerán: balas %d (no gasta) | zombi 1 vida %d | zombi 2 vida %d" % [johnny.balas, z1.vida, z2.vida])
	abrir_cosas("inventario")
	inventario.tocar("g%d" % armas_guardadas.find(armas_guardadas.filter(func(id): return Objetos.nombre(id) == "Desintegrador")[0]))
	inventario.poner_guardada()
	inventario.cerrar()
	for i in 6:
		johnny.disparar(0.0)
		await get_tree().create_timer(0.08).timeout
	await get_tree().create_timer(0.2).timeout
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().process_frame
	Captura.foto("captura-creadas.png")
	menus.visible = true
	print("Desintegrador: mano %s balas %d | zombi 2 vida %d heridas %s | charcos %d" % [Objetos.nombre(johnny.huecos.fuego),
		johnny.balas, z2.vida, z2.get_children().filter(func(n): return n.name.begins_with("herida")).map(func(n): return n.name),
		get_tree().get_nodes_in_group("charcos").size()])
	var z3 := meter_zombi("lento", johnny.position + Vector2(-120, 30))
	z3.vida = 500
	lanzables.tipo = "congeladora"
	lanzables.lanzar(z3.global_position)
	await get_tree().create_timer(2.3).timeout
	print("Congeladora: zombi 3 aturdido %.1f vida %d | vida de Johnny %d | quedan %s" % [z3.aturdido, z3.vida, johnny.vida, lanzables.tipos()])


# El reparto de objetos (parte 6 del centro comercial): cuenta qué sale en cada sitio de los dos edificios y
# comprueba que las cosas de casa no salen en el centro ni las del centro en los Apartamentos. Luego deja en el
# suelo los nueve nuevos, mete uno de cada objeto en el baúl (lo de la tecla U) y hace fotos del banco y del baúl
func probar_objetos() -> void:
	var fallos := []
	for ed_id in ["apartamentos", "centro"]:
		for tienda in [""] + (Objetos.TIENDAS.keys() if ed_id == "centro" else []):
			var salen := {}
			for i in 2000:
				var id := Objetos.al_azar(ed_id, tienda)
				salen[id] = salen.get(id, 0) + 1
				if id == "explosivos" or (ed_id == "centro" and id in Objetos.SOLO_CASA) \
						or (ed_id == "apartamentos" and id in Objetos.SOLO_CENTRO):
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
	abrir_cosas("banco")
	inventario.tocar("r_pistola_electrica")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-banco-todo.png")
	inventario.cerrar()
	abrir_cosas("baul")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-todo.png")
	inventario.cerrar()
	print("Baúl con uno de cada: %d casillas de %d" % [Objetos.casillas_baul(Guardado.cargar()), Objetos.BAUL])
	Guardado.cambiar(func(g): g.baul = baul_antes)
	await probar_soltar_recetas()


# Las recetas que sueltan los jefes: sabiendo todas menos dos, suelta tres (la tercera ya no sale: las dos que
# quedan están en el suelo), foto del papel en el suelo, lo coge y foto del aviso
func probar_soltar_recetas() -> void:
	var faltan := ["garfio", "mangual"]
	Guardado.cambiar(func(g): g.recetas = Recetas.LISTA.keys().filter(func(r): return not r in faltan))
	var donde: Vector2 = johnny.position + Vector2(220, 0)
	var soltadas := [soltar_receta(donde), soltar_receta(donde), soltar_receta(donde)]
	print("Recetas soltadas: %s (dos distintas de %s y la tercera vacía)" % [soltadas, faltan])
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-receta-suelo.png")
	for cosa in mapa.cosas.get_children():
		if cosa.get_script() == BILLETE and cosa.icono == ICONO_RECETA:
			cosa.cogido.emit()
			cosa.queue_free()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-receta-cogida.png")
	print("Aviso al coger la receta: '%s' (se ve: %s)" % [aviso.text, aviso.modulate.a > 0.5 and aviso.is_visible_in_tree()])
	menus.visible = true
	print("Recetas sabidas: %d de %d | en el suelo: %s | otra al morir un jefe: '%s'" % [
		Recetas.sabidas(Guardado.cargar()).size(), Recetas.LISTA.size(), recetas_en_suelo, soltar_receta(donde)])


# Las armas de las recetas nuevas (parte 6 del centro comercial): comprueba que las nueve recetas salen en el banco
# y prueba cada arma contra zombis lentos de 500 de vida (que no muera ninguno), contando en la terminal lo que pasa
# y con una foto de cada una: captura-arma-<receta>.png
func probar_recetas() -> void:
	var nuevas := ["bate_helado", "mangual", "latigo_electrico", "pistola_electrica", "garfio", "bomba_aceite",
		"mina_despertador", "nube_somnifera", "bomba_clavos"]
	print("Recetas nuevas en el banco: ", nuevas.all(func(r): return Recetas.buscar(Recetas.LISTA[r].con[1], Recetas.LISTA[r].con[0]) == r))
	# en medio del cuarto, mirando a la derecha, y sin atacar por su cuenta (aquí ataca la prueba)
	johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, planta.sitios[aqui].alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	johnny.direccion = "e"
	johnny.espera = 1000.0
	# cuerpo a cuerpo: el bate helado congela, el mangual echa a todos lejos y el látigo eléctrico salta a otro
	var z := zombis_de_prueba([Vector2(40, 0)])
	johnny.coger(Armas.apuntar(Recetas.crear("bate_helado")))
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	await foto_arma("bate_helado")
	print("Bate helado: congelado %.1f vida %d" % [z[0].congelado, z[0].vida])
	z = zombis_de_prueba([Vector2(45, 0), Vector2(-45, 10), Vector2(0, 45)])
	johnny.coger(Armas.apuntar(Recetas.crear("mangual")))
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	await get_tree().create_timer(0.25).timeout
	await foto_arma("mangual")
	print("Mangual: distancias %s | aturdidos %s" % [z.map(func(o): return roundi(o.distancia_a(johnny))), z.map(func(o): return o.aturdido > 0.0)])
	z = zombis_de_prueba([Vector2(90, 0), Vector2(150, 30)])
	johnny.coger(Armas.apuntar(Recetas.crear("latigo_electrico")))
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	await foto_arma("latigo_electrico")
	print("Látigo eléctrico: aturdidos %s | vidas %s" % [z.map(func(o): return snappedf(o.aturdido, 0.1)), z.map(func(o): return o.vida)])
	# a distancia: las chispas de la pistola eléctrica y el garfio
	z = zombis_de_prueba([Vector2(160, 0), Vector2(220, 40)])
	johnny.coger(Armas.apuntar(Recetas.crear("pistola_electrica")))
	await get_tree().create_timer(0.1).timeout
	for i in 4:
		johnny.disparar(0.0)
		await get_tree().create_timer(0.08).timeout
	await foto_arma("pistola_electrica")
	await get_tree().create_timer(0.3).timeout
	print("Pistola eléctrica: balas %d | aturdidos %s | vidas %s" % [johnny.balas, z.map(func(o): return snappedf(o.aturdido, 0.1)),
		z.map(func(o): return o.vida)])
	z = zombis_de_prueba([Vector2(260, 0)])
	johnny.coger(Armas.apuntar(Recetas.crear("garfio")))
	await get_tree().create_timer(0.1).timeout
	var lejos := roundi(z[0].distancia_a(johnny))
	johnny.disparar(0.0)
	await get_tree().create_timer(0.4).timeout
	await foto_arma("garfio")
	await get_tree().create_timer(0.75).timeout
	print("Garfio: distancia %d -> %d | balas %d (no gasta) | vida %d" % [lejos, roundi(z[0].distancia_a(johnny)), johnny.balas, z[0].vida])
	# arrojadizas: el aceite resbala y luego arde, la mina espera a que pase un zombi, la nube duerme y los clavos
	z = zombis_de_prueba([Vector2(170, 0), Vector2(190, 30)])
	for r in ["bomba_aceite", "mina_despertador", "nube_somnifera", "bomba_clavos"]:
		lanzables.sacar(Recetas.crear(r))
	for o in z:
		o.aturdido = 4.0   # que se queden en el charco
	lanzables.tipo = "bomba_aceite"
	lanzables.lanzar(johnny.global_position + Vector2(180, 10))
	await get_tree().create_timer(1.0).timeout
	var aceite := get_tree().get_nodes_in_group("charcos").filter(func(c): return c.tipo == "aceite").size()
	await foto_arma("bomba_aceite")
	await get_tree().create_timer(2.0).timeout
	print("Bomba de aceite: charcos de aceite %d | luego fuegos %d | zombis ardiendo %s" % [aceite,
		get_tree().get_nodes_in_group("charcos").filter(func(c): return c.tipo == "fuego").size(), z.map(func(o): return o.arder_t > 0.0)])
	await foto_arma("bomba_aceite_arde")
	z = zombis_de_prueba([])
	lanzables.tipo = "mina_despertador"
	lanzables.lanzar(johnny.global_position + Vector2(-170, 0))
	await get_tree().create_timer(1.3).timeout
	await foto_arma("mina_despertador")
	var mina: Node2D = johnny.get_parent().get_children().filter(func(n): return n.get_script() == Lanzables.BOMBA)[-1]
	var donde: Vector2 = mina.global_position - johnny.global_position
	z = zombis_de_prueba([Vector2(-330, 0)])   # viene hacia Johnny y pasa por encima
	for i in 40:
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(mina):
			break
	await get_tree().create_timer(0.1).timeout
	print("Mina despertador: en %s | ha explotado %s | el zombi que pasa, vida %d (de 500) | vida de Johnny %d" % [
		donde.round(), not is_instance_valid(mina), z[0].vida, johnny.vida])
	z = zombis_de_prueba([Vector2(180, 0), Vector2(200, 40), Vector2(150, -30)])
	lanzables.tipo = "nube_somnifera"
	lanzables.lanzar(johnny.global_position + Vector2(180, 10))
	await get_tree().create_timer(1.9).timeout
	await foto_arma("nube_somnifera")
	print("Nube somnífera: dormidos %s" % [z.map(func(o): return snappedf(o.aturdido, 0.1))])
	z = zombis_de_prueba([Vector2(120, 0), Vector2(200, 50), Vector2(80, -60)])
	lanzables.tipo = "bomba_clavos"
	lanzables.lanzar(johnny.global_position + Vector2(150, 0))
	await get_tree().create_timer(2.15).timeout
	await foto_arma("bomba_clavos")
	await get_tree().create_timer(0.35).timeout
	print("Bomba de clavos: vidas %s | sangran %s | quedan %s" % [z.map(func(o): return o.vida),
		z.map(func(o): return o.has_node("herida_sangra")), lanzables.tipos()])
	zombis_de_prueba([])
	johnny.vida = johnny.stats.vida_max
	johnny.espera = 0.0


# Para probar_recetas: quita los zombis y los charcos que haya, cura a Johnny y saca zombis lentos de 500 de vida
# en esos sitios (respecto a Johnny)
func zombis_de_prueba(donde: Array) -> Array:
	for o in get_tree().get_nodes_in_group("zombis") + get_tree().get_nodes_in_group("charcos"):
		o.remove_from_group("zombis")
		o.queue_free()
	johnny.vida = johnny.stats.vida_max
	var lista := []
	for d in donde:
		var zombi := meter_zombi("lento", johnny.position + d)
		zombi.vida = 500
		lista.append(zombi)
	return lista


# Para probar_recetas: la foto de un arma nueva (sin el recuadro de las mutaciones, si ha salido)
func foto_arma(nombre: String) -> void:
	menus.visible = false
	await get_tree().process_frame
	Captura.foto("captura-arma-%s.png" % nombre)
	menus.visible = true


# El recuadro de las mutaciones: foto, elige la primera y comprueba que cambia los atributos
func probar_mutaciones() -> void:
	abrir_mutacion()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-mutacion.png")
	var primera: String = menus.cartas[0].id
	menus.elegir(primera)
	elegir_mutacion("insensible")
	print("Mutaciones: %s | daño recibido x%.2f | pausa %s" % [mutaciones.tengo, johnny.stats.dano_recibido, get_tree().paused])


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
		Guardado.cambiar(func(g): g.paginas.erase("cc_recogida"))
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


# Fotos de la pausa y del cartel de victoria (con el juego parado solo cuentan los temporizadores)
func probar_menus() -> void:
	set_process(false)
	soltar_billetes(3, johnny.position + Vector2(60, 0))
	await get_tree().create_timer(1.2).timeout
	print("Dólares de la partida: %d | muertos: %d" % [dolares, muertos])
	await probar_ordenador()
	await probar_cosas()
	await probar_creadas()
	await probar_objetos()
	await probar_recetas()
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
