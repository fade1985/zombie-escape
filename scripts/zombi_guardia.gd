# El guardia de seguridad del centro comercial, el jefe de seguridad: lleva la llave maestra de la planta (abre todas sus
# puertas) y ronda por el pasillo de la planta (17 nov, lo pidió el dueño; antes pitaba, huía y se cansaba):
#   - Mientras no te ha visto, hace su ronda despacio, de una punta del pasillo a la otra.
#   - Cuando te ve (o le das sin que te haya visto), se para mirando de frente a la pantalla y ruge: «¡¡¡GRRR!!!» en rojo
#     encima de la cabeza, con las letras de los gritos de Johnny. Solo una vez. Mientras ruge, Johnny se queda
#     petrificado por el sonido: no puede moverse ni atacar hasta que acaba (para que no saque ventaja). Con el rugido llegan sus guardias (los saca la partida: señal
#     "rugido"; 4 en la planta baja y 2 más en cada planta de arriba).
#   - Hasta que ruge, nada le hace daño (18 nov, lo pidió el dueño: inmune(); los golpes le empujan y sale «¡INMUNE!»), y
#     el primero le hace rugir.
#   - Después, va a por Johnny con ellos y le ataca a zarpazos hasta que caigan todos.
# Lleva su propio dibujo (hecho con GPT: assets/sources/zombi-guardia-gpt/), distinto del de los vigilantes que llama.
extends Zombi

signal rugido   # ha rugido: la partida trae a sus guardias

const RONDA := 55.0          # su velocidad haciendo la ronda
const PERSECUCION := 165.0   # y persiguiendo a Johnny: la de sus guardias (Johnny anda a 210)
const RUGIDO_DURA := 1.4     # lo que se queda parado rugiendo
const PASO_CORRIENDO := 2.0  # lo rápido que pasa su andar al perseguir: su dibujo anda despacio (12 pasos a 8 por
                             # segundo, para la ronda) y, a 165, parecía que patinaba

var alerta := false          # si ya ha rugido (entonces ya no hace la ronda: va a por Johnny)
var rugir_ya := false        # le han dado sin que hubiera visto a Johnny: ruge en cuanto pueda
var rugiendo := 0.0          # lo que le queda de rugido
var meta := Vector2.INF      # la punta del pasillo a la que va en la ronda
var puntas: Array = []       # los dos extremos del pasillo, los pone la partida


# El agente de navegación limita la velocidad a la del zombi (85 en la escena): sin esto no pasaría de ~80
func _ready() -> void:
	super()
	velocidad = PERSECUCION
	agente.max_speed = PERSECUCION
	se_enfurece = false   # (el grito de la dependienta no le enfurece: es el jefe de la planta)


func andar(delta: float, johnny: Node2D) -> void:
	if not alerta:
		var lo_ve: bool = distancia_a(johnny) < VISTA * Skins.camuflaje(johnny.get("skin") if johnny.get("skin") != null else "") \
				and se_ve(johnny)   # (con la skin de la modista, le ve a la mitad de distancia)
		if lo_ve or rugir_ya:
			rugir(johnny)
		else:
			if helor == 0.0:   # (con frío del lanza hielo, lo despacio que se mueve lo lleva zombi.gd)
				sprite.speed_scale = 1.0
			rondar(delta)
		return
	# a por Johnny, como cualquier zombi (y a zarpazos al llegar)
	if helor == 0.0:
		sprite.speed_scale = PASO_CORRIENDO
	super(delta, johnny)


# La ronda: de una punta a la otra, despacio
func rondar(delta: float) -> void:
	if puntas.size() < 2:
		pedir_velocidad(Vector2.ZERO)
		poner_animacion("reposo")
		return
	if meta == Vector2.INF or global_position.distance_to(meta) < 40.0:
		meta = puntas[0] if meta != puntas[0] else puntas[1]
	ir_hacia(delta, camino_hacia(meta), RONDA)


# El rugido: se para mirando de frente (su animación solo está de frente), el «¡¡¡GRRR!!!» en rojo y el gruñido del
# botón «JUGAR»; Johnny, petrificado mientras dura (sin_mandos, en johnny.gd); y llama a sus guardias
func rugir(johnny: Node2D) -> void:
	alerta = true
	rugir_ya = false
	estado = "rugido"
	rugiendo = RUGIDO_DURA
	pedir_velocidad(Vector2.ZERO)
	direccion = "s"
	if helor == 0.0:
		sprite.speed_scale = 1.0
	poner_animacion("grito", true)
	Sonido.grunir()   # (el gruñido del botón «JUGAR» de la pantalla de inicio: lo pidió el dueño, 17 nov)
	var grito := Zombi.texto_flotante(get_parent(), global_position + Vector2(0, -110), Idioma.t("¡¡¡GRRR!!!"), Tema.ROJO,
		32, true, RUGIDO_DURA)
	var sin_luz := CanvasItemMaterial.new()   # (como los gritos de Johnny: que no lo apague la penumbra)
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	grito.material = sin_luz
	if "sin_mandos" in johnny:
		johnny.sin_mandos = maxf(johnny.sin_mandos, RUGIDO_DURA)
	rugido.emit()


func estado_propio(delta: float, johnny: Node2D) -> void:
	if estado == "rugido":
		pedir_velocidad(Vector2.ZERO)
		rugiendo -= delta
		if rugiendo <= 0.0:
			estado = "andar"
		return
	super(delta, johnny)


# Antes de rugir, nada le hace daño
func inmune() -> bool:
	return not alerta


# Si le dan antes de que haya visto a Johnny, ruge igual (en cuanto se recupere del golpe)
func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	super(cantidad, fuerza)
	if not alerta:
		rugir_ya = true
