# La directora de Recursos Humanos: el primer minijefe de Torre Velaria (parte 5 del plan, docs/PLAN_TERCER_EDIFICIO.md,
# «Los cuatro minijefes»; su sala, el Despacho de Recursos Humanos). Traje chaqueta, moño tirante, gafas de pasta y un
# sello de goma enorme. Lo común de los minijefes, en minijefe.gd.
#
#   - Sello de despido: lanza el sello hacia arriba y cae donde está Johnny (su marca roja y su sombra, antes: se esquiva
#     apartándose). Si le pilla, «¡DESPEDIDO!»: DANO_SELLO y DESPIDO segundos sin el arma de fuego (johnny.gd, despedir()).
#     Lo que cae, en cae_encima.gd.
#   - Evaluación de desempeño: llama a 3 oficinistas. Mientras quede alguno de pie, a ella le entra la mitad del daño (se
#     ve una línea de ella a cada uno y, al pegarle, «½»). Cuando cae el último, se lleva un disgusto («¡INACEPTABLE!»).
#   - Lluvia de cajas: caen CAJAS cajas de cartón alrededor de Johnny (una, encima), cada una con su marca antes.
# Enfadada (a media vida): el sello cae en tres sitios seguidos (donde vaya estando Johnny) y llama a 5.
# Números provisionales: se ajustan jugando.
extends Minijefe

const VELOCIDAD := 75.0
const REFUERZO := "oficinista"
const EVALUADOS := [3, 5]          # los que llama (normal y enfadada)
const ESPERA_EVALUACION := 14.0    # entre una llamada y la siguiente
const PROTECCION := 0.5            # lo que le entra de cada golpe mientras queda alguno de los suyos
const SELLOS := [1, 3]             # los que caen seguidos
const AVISO_SELLO := 1.0           # lo que tarda en caer cada uno (lo que se ve su marca)
const ENTRE_SELLOS := 0.45
const DANO_SELLO := 15
const DESPIDO := 3.0
const LANZA := 0.25                # cuándo suelta el sello en su animación (lo que tarda en levantarlo)
const DURA_SELLO := 0.75           # lo que dura la animación de lanzarlo
const CAJAS := 6
const AVISO_CAJA := 0.9
const DANO_CAJA := 10
const LEJOS_CAJAS := 170.0         # hasta dónde de Johnny caen
const PIE := 30.0                  # a qué altura dibuja los pies respecto a su centro

var espera_sello := 1.5
var espera_cajas := 5.0
var espera_evaluacion := 3.0
var medio_t := 0.0                 # para no llenar la pantalla de «½»
var tenia := 0                     # cuántos de los suyos quedaban en el paso anterior (para ver cuándo cae el último)


func pensar(delta: float, johnny: Node2D) -> void:
	espera_sello -= delta
	espera_cajas -= delta
	espera_evaluacion -= delta
	medio_t -= delta
	var quedan := evaluados().size()
	if tenia > 0 and quedan == 0 and estado == "andar":
		# se le ha acabado la evaluación: un disgusto (el golpe, sin daño)
		cambiar("disgusto")
		gritar(Idioma.t("¡INACEPTABLE!"), Color("#ff5d73"))
	tenia = quedan
	match estado:
		"andar":
			mirada = global_position.direction_to(johnny.global_position)
			perseguir(delta, johnny, VELOCIDAD)
			if t >= dur:
				elegir()
		"sello":
			frenar(delta)
			mirada = global_position.direction_to(johnny.global_position)
			# el primero, al acabar de levantarlo; los demás (enfadada), seguidos
			while datos.lanzados < datos.cuantos and t >= LANZA + datos.lanzados * ENTRE_SELLOS:
				datos.lanzados += 1
				soltar("sello", johnny.global_position, AVISO_SELLO, DANO_SELLO, DESPIDO)
			if t >= LANZA + (datos.cuantos - 1) * ENTRE_SELLOS + 0.5:
				andar(0.5 if enfadado() else 0.9)
		"llamar":
			frenar(delta)
			if t >= 0.5 and not datos.get("hecho", false):
				datos.hecho = true
				llamar(REFUERZO, EVALUADOS[fase - 1], 120.0)
			if t >= 1.0:
				andar(0.4)
		"cajas":
			frenar(delta)
			if t >= 0.4 and not datos.get("hecho", false):
				datos.hecho = true
				lluvia(johnny)
			if t >= 1.0:
				andar(0.6)
		"disgusto":
			frenar(delta)
			if t >= 0.6:
				andar(0.3)


func elegir() -> void:
	# la evaluación, si no le queda ninguno de los suyos (y no hay ya muchos zombis por ahí)
	if espera_evaluacion <= 0.0 and evaluados().is_empty() and secuaces() <= 2:
		espera_evaluacion = ESPERA_EVALUACION
		cambiar("llamar")
		Sonido.tocar("rugido")
		gritar(Idioma.t("¡EVALUACIÓN DE DESEMPEÑO!"), Color("#ffd23f"), 18)
		return
	if espera_sello <= 0.0:
		espera_sello = 3.0 if enfadado() else 4.0
		cambiar("sello", {"cuantos": SELLOS[fase - 1], "lanzados": 0})
		gritar(Idioma.t("¡FUERA!"), Color("#ff5d73"))
		return
	if espera_cajas <= 0.0:
		espera_cajas = 7.0 if enfadado() else 9.0
		cambiar("cajas")
		gritar(Idioma.t("¡RECOGE TUS COSAS!"), Color("#ffd23f"), 18)
		return
	andar(0.3)


# Hace caer algo del techo (cae_encima.gd) en "donde"
func soltar(tipo: String, donde: Vector2, aviso: float, dano: int, despido := 0.0) -> void:
	var cosa := CaeEncima.new()
	cosa.tipo = tipo
	cosa.donde = donde
	cosa.aviso = aviso
	cosa.dano = dano
	cosa.despido = despido
	cosa.dueno = self
	get_parent().add_child(cosa)
	if tipo == "sello":
		Sonido.tocar("barrido")


# La lluvia de cajas: una justo encima de Johnny y las demás repartidas a su alrededor, cada una un poco después (por
# donde se pueda estar: no dentro de una pared ni de un mueble)
func lluvia(johnny: Node2D) -> void:
	var mapa := agente.get_navigation_map()
	for i in CAJAS:
		var donde: Vector2 = johnny.global_position
		if i > 0:
			var a := float(i) / (CAJAS - 1) * TAU + randf_range(-0.4, 0.4)
			donde += Vector2(cos(a), sin(a) * 0.7) * randf_range(60.0, LEJOS_CAJAS)
			donde = NavigationServer2D.map_get_closest_point(mapa, donde)
		soltar("caja", donde, AVISO_CAJA + i * 0.12, DANO_CAJA)


# Los oficinistas que le quedan de pie (los que llama en la evaluación: en su sala no hay otros)
func evaluados() -> Array:
	return get_tree().get_nodes_in_group("zombis").filter(func(z): return z.get_meta("tipo", "") == REFUERZO)


# Mientras le queden oficinistas, la mitad del daño
func danar(cantidad: int, _fuerza: Vector2, _de_lleno: bool) -> int:
	if evaluados().is_empty():
		return cantidad
	if medio_t <= 0.0:
		medio_t = 0.4
		Zombi.texto_flotante(get_parent(), global_position + Vector2(24, -arriba - 10), "½", Color("#ffd23f"), 26)
	return maxi(1, ceili(cantidad * PROTECCION))


func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, Idioma.t("¡ESTÁS DESPEDIDO!"))


# En la foto de la prueba (--captura): lanzando el sello
func foto(_johnny: Node2D) -> void:
	cambiar("sello", {"cuantos": SELLOS[fase - 1], "lanzados": 0})


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"sello":
			fijar("sello", dir, avance("sello_" + dir, minf(1.0, t / DURA_SELLO)))
		"llamar", "cajas":
			fijar("llamar", "s", avance("llamar_s", t / 1.0))
		"disgusto":
			fijar("golpe", dir, avance("golpe_" + dir, t / 0.6))
		"grito":
			fijar("llamar", "s", 2)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)


func _ready() -> void:
	super()
	# las líneas de la evaluación van en el suelo y lucen por sí mismas (como los avisos: también a oscuras)
	lineas = Node2D.new()
	lineas.z_as_relative = false
	lineas.z_index = -1
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	lineas.material = sin_luz
	lineas.draw.connect(_pintar_lineas)
	add_child(lineas)


var lineas: Node2D


func _draw() -> void:
	lineas.queue_redraw()


# En el suelo: la línea de la evaluación desde sus pies hasta cada uno de los suyos (discontinua, como de un organigrama)
func _pintar_lineas() -> void:
	if estado == "muerto":
		return
	for z in evaluados():
		var hasta: Vector2 = to_local(z.global_position) + Vector2(0, 20)
		var desde := Vector2(0, PIE - 4)
		var largo := desde.distance_to(hasta)
		var paso := 14.0
		var i := 0.0
		while i < largo:
			var a := desde.lerp(hasta, i / largo)
			var b := desde.lerp(hasta, minf(i + paso * 0.6, largo) / largo)
			lineas.draw_line(a, b, Color("#ffd23f", 0.7), 2.0)
			i += paso
