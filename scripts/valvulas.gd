# El rescate propio de la limpiadora de noche de Torre Velaria (docs/PLAN_TERCER_EDIFICIO.md, «Los supervivientes»;
# otra como Johnny). Se ha encerrado en el cuarto de la limpieza de Recursos Humanos (planta.gd, cuarto_limpieza) y el
# gas del aire acondicionado (peligros/gas.gd) se le ha metido dentro: tose y pide que cierren el gas. En su planta, el
# departamento tiene tres válvulas (peligros.gd, gas con "tres"), una por rejilla: en el archivo, en las entrevistas y
# en la pared de arriba de la sala grande. Hay que cerrarlas todas (cada una, una vez y para siempre: valvula.gd) para
# que se vaya el gas del cuarto y se abra la puerta; limpiar el departamento no la abre.
#
# Mientras tanto, los zombis del departamento duermen por el gas (zombi.gd, gasear, con un sueño largo): quietos y con
# su "z". Cada válvula que se cierra silba fuerte y despierta frenéticos (más rápidos) a los que tiene cerca, y la
# última, a todos; un golpe también los despierta. Con la puerta abierta, Johnny se le arrima y se une, como siempre
# (sin horda después: el reto son las válvulas).
#
# Lo monta supervivientes.gd: montar() al montar su departamento, dibujar() en su capa de la pantalla. Los números son
# provisionales.
class_name Valvulas
extends Node

const SUENO := 600.0        # lo que duermen por el gas los zombis del departamento (en la práctica, hasta que pase algo)
const DESPIERTA := 340.0    # a esta distancia de la válvula que se cierra, se despiertan frenéticos
const TOS := [5.0, 9.0]     # cada cuánto tose dentro (segundos, al azar entre los dos)
# Lo que se dice (en español; sale con Idioma.t)
# [traducir]
const AL_CERRAR := ["¡Una menos! Quedan dos", "¡Ya casi! Solo queda una"]   # lo que grita ella al cerrarse la 1ª y la 2ª
const TOSES := ["*cof, cof*", "¡No respiro!", "¡Date prisa, chico!"]
# [/traducir]

var sup: Supervivientes
var gas: Node2D = null       # el gas del departamento (peligros/gas.gd), mientras se está en él con ella encerrada
var nube: Node2D = null      # el gas dentro de su cuarto (se dibuja con código)
var tos_t := 3.0
var tiempo := 0.0


func activa() -> bool:
	return gas != null and is_instance_valid(gas)


static func es_suyo(def: Dictionary) -> bool:
	return def.get("rescate", "") == "valvulas"


# Recién montado su departamento con ella aún encerrada: duerme a los zombis (si queda alguna válvula abierta),
# escucha a las válvulas y llena su cuarto de gas
func montar() -> void:
	gas = null
	var mapa: Node = sup.partida.mapa
	for p in mapa.peligros:
		if p.datos.tipo == "gas" and p.datos.has("valvulas"):
			gas = p
	if gas == null:
		return
	gas.cerrada.connect(al_cerrar)
	if not gas.todo_cerrado():
		dormir_zombis.call_deferred()   # (partida.gd mete los zombis justo después de esto)
	var sala: Dictionary = sup.partida.planta.sitios[sup.partida.aqui].apt.salas[sup.partida.planta.superviviente.sala]
	nube = Nube.new()
	nube.caja = Rect2(sala.c0 * Planta.CASILLA, sala.f0 * Planta.CASILLA, sala.ancho * Planta.CASILLA,
		sala.fondo * Planta.CASILLA)
	nube.llena = 0.0 if gas.todo_cerrado() else 1.0
	mapa.cosas.add_child(nube)


# Los zombis del departamento, dormidos por el gas (quietos, con su "z"): ya no se despiertan al ver a Johnny, solo con
# una válvula cerca o un golpe
func dormir_zombis() -> void:
	if not activa():
		return
	for z in get_tree().get_nodes_in_group("zombis"):
		if not z is Minijefe and z.has_method("gasear"):
			z.dormido = false
			z.gasear(SUENO)


# Se ha cerrado una válvula: silba, despierta a los de cerca (o a todos, la última) y ella lo celebra; con las tres,
# se va el gas del cuarto y se abre la puerta
func al_cerrar(cuantas: int, de: int) -> void:
	var partida: Node = sup.partida
	var donde: Vector2 = sup.johnny.global_position
	Sonido.tocar("siseo")
	for z in get_tree().get_nodes_in_group("zombis"):
		if z.has_method("espabilar_gas") and (cuantas >= de or z.global_position.distance_to(donde) < DESPIERTA):
			z.espabilar_gas()
	if cuantas < de:
		partida.decir(Idioma.t("Válvula cerrada: %d de %d") % [cuantas, de], 2.5)
		if sup.npc:
			sup.npc.decir(Idioma.t(AL_CERRAR[1 if de - cuantas == 1 else 0]))
		return
	partida.decir(Idioma.t("¡Gas cortado! Se abre el cuarto de la limpieza"), 3.0)
	partida.logros.cumplir("buen_vecino")
	if nube:
		nube.vaciar = true
	sup.abrir_escondite(partida.aqui)


func _physics_process(delta: float) -> void:
	tiempo += delta
	if not activa() or sup.partida.cambiando:
		return
	# dentro tose (cuando no le toca gritar)
	if sup.encerrado() and sup.npc:
		tos_t -= delta
		if tos_t <= 0.0:
			tos_t = randf_range(TOS[0], TOS[1])
			sup.npc.decir(Idioma.t(TOSES.pick_random()))


# Se sale de su departamento (supervivientes.gd: recoger)
func soltar() -> void:
	if activa() and gas.cerrada.is_connected(al_cerrar):
		gas.cerrada.disconnect(al_cerrar)
	gas = null
	if is_instance_valid(nube):
		nube.queue_free()
	nube = null


# En la pantalla, mientras sigue encerrada y se está en su departamento: cuántas válvulas faltan
func dibujar(capa: Control) -> void:
	if not activa() or not sup.encerrado():
		return
	var de: int = gas.datos.rejillas.size()
	var hechas: int = gas.datos.rejillas.filter(func(r): return r.get("cerrada", false)).size()
	CuentaAtras.dibujar(capa, Idioma.t("Cierra las válvulas del gas · %d/%d") % [hechas, de], Tema.TINTA,
		float(hechas) / de, Color("#c77dff"), 0, 0.0, false)


# El gas de dentro del cuarto: bocanadas moradas por todo el suelo (como las de gas.gd) y, al abrirse, se van
class Nube extends Node2D:
	var caja: Rect2
	var llena := 1.0
	var vaciar := false
	var bocanadas: Array = []   # [x, y, vx, vy, edad, dura, tamaño]
	var t := 0.0

	func _ready() -> void:
		z_index = 4
		var propio := CanvasItemMaterial.new()
		propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = propio

	func _physics_process(delta: float) -> void:
		t += delta
		if vaciar:
			llena = move_toward(llena, 0.0, delta * 0.5)
		if randf() < 14.0 * delta * llena:
			var dentro := caja.grow(-14.0)
			bocanadas.append([randf_range(dentro.position.x, dentro.end.x), randf_range(dentro.position.y + 20.0, dentro.end.y),
				randf_range(-14, 14), randf_range(-12, 4), 0.0, randf_range(1.6, 2.8), randf_range(14, 24)])
		var vivas := []
		for b in bocanadas:
			b[4] += delta
			b[0] += b[2] * delta
			b[1] += b[3] * delta
			if b[4] < b[5]:
				vivas.append(b)
		bocanadas = vivas
		queue_redraw()

	func _draw() -> void:
		for b in bocanadas:
			var k: float = b[4] / b[5]
			var r := roundf(b[6] * (0.5 + k) / 2.0)
			var color := Color(0.55, 0.3, 0.75, 0.32 * sin(k * PI))
			var centro := Vector2(roundf(b[0] / 2.0) * 2.0, roundf(b[1] / 2.0) * 2.0)
			for y in range(-r, r + 1):
				var ancho := roundf(sqrt(maxf(r * r - y * y, 0.0)))
				draw_rect(Rect2(centro.x - ancho * 2.0, centro.y + y * 2.0, ancho * 4.0, 2), color)


# ═════════════ Para probar ═════════════

# Con --captura --edificio torre --limpiadora (prueba_sitios.gd): la limpiadora en el cuarto de la limpieza de Recursos
# Humanos, con el gas dentro y los zombis dormidos (captura-limpiadora-cuarto.png); cerrar la primera válvula, que
# despierta frenéticos a los de cerca (captura-limpiadora-valvula.png); las otras dos y la puerta que se abre
# (captura-limpiadora-abierta.png); unirse; fregar unos charcos (captura-limpiadora-charcos.png, antes, y
# captura-limpiadora-fregar.png, fregando); la fregona ancha; y su
# habitación en las viviendas (captura-limpiadora-sala.png). Se deja el equipo y el guardado como estaban
func probar() -> void:
	var partida: Node = sup.partida
	var johnny: Node2D = sup.johnny
	var antes: Array = sup.equipo
	for a in antes:
		if a.get_parent():
			a.get_parent().remove_child(a)
	sup.equipo = []
	sup.rescate = {}
	await sup.probar_aqui(false, "limpiadora")
	var sitio: Dictionary = partida.planta.sitios[partida.aqui]
	var sala: Dictionary = sitio.apt.salas[partida.planta.superviviente.get("sala", 0)]
	print("Limpiadora: sale en «%s» · en «%s» · muebles del cuarto %s" % [Planta.nombre_de_sitio(sitio), sala.nombre,
		sitio.muebles.filter(func(m): return m.zona == sala.id).map(func(m): return m.tipo)])
	await get_tree().create_timer(0.5, false).timeout
	if not activa():
		print("Limpiadora: ERROR, no hay gas con tres válvulas: %s · encerrada %s" % [sitio.get("peligros", []).map(
			func(p): return [p.tipo, p.get("valvulas", p.get("valvula", {})).size() if p.tipo == "gas" else 0]), sup.encerrado()])
		dejar(antes)
		return
	# unos cuantos zombis más, repartidos por la sala grande (que se vea que duermen)
	var grande: Dictionary = sitio.apt.salas[0]
	for i in 6:
		partida.meter_zombi(["normal", "rapido", "oficinista"][i % 3], Vector2((grande.c0 + 3 + i * 4) * Planta.CASILLA,
			(grande.f0 + grande.fondo / 2.0) * Planta.CASILLA))
	dormir_zombis()
	var zombis := get_tree().get_nodes_in_group("zombis")
	print("Limpiadora: válvulas %d · zombis %d, dormidos por el gas %d · encerrada %s" % [gas.valvulas.size(),
		zombis.size(), zombis.filter(func(z): return z.gaseado > 100.0).size(), sup.encerrado()])
	johnny.position = sup.puerta.position + Vector2(0, 60) if sup.puerta else sup.npc.position + Vector2(0, 80)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(1.2, false).timeout
	Captura.foto("captura-limpiadora-cuarto.png")
	# las válvulas, una a una
	for i in gas.valvulas.size():
		var v: Node2D = gas.valvulas[i]
		johnny.position = v.position + Vector2(0, 30)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.5, false).timeout
		var dormidos: int = get_tree().get_nodes_in_group("zombis").filter(func(z): return z.gaseado > 100.0).size()
		var frenetic: int = get_tree().get_nodes_in_group("zombis").filter(func(z): return z.frenesi > 0.0).size()
		print("Limpiadora: válvula %d en la sala %d cerrada %s · siguen dormidos %d, frenéticos %d · encerrada %s" % [i + 1,
			v.datos.sala, not v.abierta(), dormidos, frenetic, sup.encerrado()])
		if i == 0:
			Captura.foto("captura-limpiadora-valvula.png")
		johnny.position += Vector2(0, 120)   # apartarse
		await get_tree().create_timer(0.2, false).timeout
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().create_timer(1.0, false).timeout
	print("Limpiadora: tras las tres, gas cortado %s · encerrada %s (esperado: true y false)" % [gas.todo_cerrado(),
		sup.encerrado()])
	var npc: Aliado = sup.npc
	if npc:
		johnny.position = sup.puerta.position + Vector2(0, 50) if sup.puerta else npc.position + Vector2(0, 60)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.8, false).timeout
		Captura.foto("captura-limpiadora-abierta.png")
		johnny.position = npc.position + Vector2(0, 30)
		await get_tree().create_timer(0.5, false).timeout
	var a = sup.rescate.get("amigo")
	print("Limpiadora: en el equipo %s · dice '%s'" % [a != null and a in sup.equipo, a.dicho if a else ""])
	if a == null:
		dejar(antes)
		return
	# fregar: tres charcos a su lado (veneno, lejía y aceite) y uno de fuego, que no se friega
	var sitio_fregar: Vector2 = gas.valvulas.back().position + Vector2(0, 110)   # (delante de la pared: sin cubículos)
	johnny.position = sitio_fregar + Vector2(90, 20)
	Aliado.borrar_huellas()   # (que no se vaya por el rastro de donde estaba Johnny)
	a.position = sitio_fregar
	await get_tree().create_timer(1.2, false).timeout
	var charcos := []
	for k in [["veneno", Vector2(-60, 20)], ["lejia", Vector2(50, 30)], ["aceite", Vector2(0, 70)], ["fuego", Vector2(-240, 0)]]:
		var c: Node2D = preload("res://escenas/armas/charco.tscn").instantiate()
		c.tipo = k[0]
		c.position = a.position + k[1]
		partida.mapa.cosas.add_child(c)
		charcos.append(c)
	a.hab_t = 0.4
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-limpiadora-charcos.png")
	await get_tree().create_timer(0.35, false).timeout
	Captura.foto("captura-limpiadora-fregar.png")
	await get_tree().create_timer(1.0, false).timeout
	print("Limpiadora: charcos que quedan %s (esperado: solo el fuego)" % [charcos.filter(func(c): return is_instance_valid(c)).map(
		func(c): return c.tipo)])
	# la fregona arreglada
	var antes_arco: float = johnny.arma_de("fregona").arco
	johnny.fregona_ancha = true
	print("Limpiadora: abanico de la fregona %.0f° → %.0f° (esperado: 140 → 200)" % [antes_arco, johnny.arma_de("fregona").arco])
	johnny.fregona_ancha = false
	# su habitación en las viviendas, con ella dentro
	var g := Guardado.cargar()
	var guardado := [g.rescatados.duplicate(), g.acompanante]
	Guardado.cambiar(func(x): x.rescatados = ["limpiadora"])
	for x in sup.equipo:
		x.queue_free()
	sup.equipo = []
	partida.nueva_planta(1)
	await partida.montar(partida.planta.mantenimiento, 0, false)
	johnny.position = partida.mapa.puertas[1].position + Vector2(-16, 0)
	await get_tree().create_timer(1.0, false).timeout
	johnny.position = Viviendas.casa("limpiadora") + Vector2(-70, 50)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	print("Limpiadora: en las viviendas, vecinos %s" % [sup.vecinos.map(func(v): return v.def.id)])
	Captura.foto("captura-limpiadora-sala.png")
	Guardado.cambiar(func(x):
		x.rescatados = guardado[0]
		x.acompanante = guardado[1])
	dejar(antes)


func dejar(antes: Array) -> void:
	for a in sup.equipo:
		if is_instance_valid(a):
			a.queue_free()
	sup.equipo = antes
	sup.rescate = {}
