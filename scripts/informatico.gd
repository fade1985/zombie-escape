# El informático: el segundo minijefe de Torre Velaria (parte 5 del plan, docs/PLAN_TERCER_EDIFICIO.md, «Los cuatro
# minijefes»; su sala, el Centro de datos, con filas de armarios de servidores con lucecitas). Sudadera, gafas, cables
# colgando del cuello y una taza de café pegada a la mano. Lo común de los minijefes, en minijefe.gd.
#
#   - Teclados: los tira en abanico (TECLADOS), dando vueltas en el aire (teclado.gd).
#   - Cortocircuito («¡SOBRECARGA!»): el suelo de la sala se electrifica por franjas, por turnos; antes, chispitas
#     (cortocircuito.gd). Hay que ir saltando de franja segura en franja segura.
#   - Apagón («¡CTRL+ALT+SUPR!»): corta la luz de su sala APAGON segundos: solo se ve con la linterna y las lucecitas
#     de los servidores (que también lucen en la oscuridad: pintar_lucecitas).
# Enfadado (a media vida): se «reinicia» cada ESPERA_REINICIO segundos: parpadea como una pantalla rota, desaparece y
# vuelve a aparecer junto a otro armario, lejos de Johnny (el de destino avisa con sus lucecitas en rojo). Y el
# cortocircuito tiene un turno más y tira más teclados.
# Números provisionales: se ajustan jugando.
extends Minijefe

const VELOCIDAD := 80.0
const TECLADOS := [8, 10]            # los que tira en cada abanico (normal y enfadado)
const ABRE := [0.17, 0.15]           # lo que se separan (en radianes)
const VELOCIDAD_TECLADO := [320.0, 380.0]
const DANO_TECLADO := 10
const LANZA := 0.4                   # cuándo salen los teclados en su animación (lo que tarda en echar el brazo atrás)
const DURA_LANZAR := 0.8
const TURNOS := [[0, 1], [0, 1, 0]]  # las franjas del cortocircuito: pares, impares... (cortocircuito.gd)
const AVISO_CORTO := [1.1, 0.85]     # lo que echan chispitas antes de dar corriente
const APAGON := 5.0                  # lo que dura el apagón
const OSCURO := 0.45                 # la oscuridad de más (con la de la sala de un jefe, casi negro: luz.gd)
const ESPERA_REINICIO := 8.0
const SE_VA := 0.5                   # el reinicio: lo que parpadea antes de desaparecer...
const FUERA := 1.0                   # ...lo que está desaparecido...
const VUELVE := 0.5                  # ...y lo que parpadea al volver
const LEJOS_REINICIO := 260.0        # vuelve junto a un armario al menos así de lejos de Johnny
const PIE := 30.0                    # a qué altura dibuja los pies respecto a su centro
const ARMARIO := "serverrack"
const LAMPARA := "res://escenas/luces/lampara.tscn"

var espera_teclados := 1.5
var espera_corto := 4.0
var espera_apagon := 9.0
var espera_reinicio := 2.0
var apagon_t := 0.0                  # lo que le queda al apagón
var antes_apagon := 0.0              # la oscuridad de evento que había antes (eventos.gd), para dejarla igual
var lamparas := {}                   # las lámparas apagadas y su fuerza, para encenderlas otra vez
var lucecitas: Array = []            # los dibujos de las lucecitas, uno por armario (pintar_lucecitas)


func pensar(delta: float, johnny: Node2D) -> void:
	espera_teclados -= delta
	espera_corto -= delta
	espera_apagon -= delta
	espera_reinicio -= delta
	match estado:
		"andar":
			mirada = global_position.direction_to(johnny.global_position)
			perseguir(delta, johnny, VELOCIDAD)
			if t >= dur:
				elegir(johnny)
		"teclados":
			frenar(delta)
			if not datos.get("lanzado", false):
				datos.angulo = global_position.direction_to(johnny.global_position).angle()
				mirada = Vector2.from_angle(datos.angulo)
			if t >= LANZA and not datos.get("lanzado", false):
				datos.lanzado = true
				lanzar_teclados()
			if t >= DURA_LANZAR:
				andar(0.5 if enfadado() else 0.8)
		"corto":
			frenar(delta)
			if t >= 0.4 and not datos.get("hecho", false):
				datos.hecho = true
				cortocircuito()
			if t >= 1.0:
				andar(0.6)
		"apagon":
			frenar(delta)
			if t >= 0.5 and not datos.get("hecho", false):
				datos.hecho = true
				apagar()
			if t >= 1.0:
				andar(0.4)
		"reinicio":
			frenar(delta, 30.0)
			reiniciar(johnny)


func elegir(johnny: Node2D) -> void:
	if enfadado() and espera_reinicio <= 0.0:
		var destino := armario_lejos(johnny)
		if destino:
			espera_reinicio = ESPERA_REINICIO
			cambiar("reinicio", {"destino": destino, "ido": false, "vuelto": false})
			gritar(Idioma.t("¡REINICIANDO…!"), Color("#7fe0ff"), 18)
			Sonido.tocar("apagon")
			return
	if espera_corto <= 0.0 and get_tree().get_nodes_in_group("balas_zombi").filter(func(b): return b is Cortocircuito).is_empty():
		espera_corto = 6.0 if enfadado() else 7.5
		cambiar("corto")
		gritar(Idioma.t("¡SOBRECARGA!"), Color("#7fe0ff"), 18)
		Sonido.tocar("chispa")
		return
	if espera_apagon <= 0.0 and apagon_t <= 0.0:
		espera_apagon = 13.0 if enfadado() else 17.0
		cambiar("apagon")
		gritar(Idioma.t("¡CTRL+ALT+SUPR!"), Color("#ffd23f"), 18)
		return
	if espera_teclados <= 0.0:
		espera_teclados = 2.4 if enfadado() else 3.2
		cambiar("teclados", {"angulo": mirada.angle(), "lanzado": false})
		return
	andar(0.3)


# ── Los teclados ──

# Salen en línea recta, repartidos alrededor de donde apuntó
func lanzar_teclados() -> void:
	var n: int = TECLADOS[fase - 1]
	for i in n:
		var a: float = datos.angulo + (i - (n - 1) / 2.0) * ABRE[fase - 1]
		var tk := Teclado.new()
		tk.dueno = self
		tk.position = global_position + Vector2.from_angle(a) * (radio + 6.0)
		tk.velocidad = Vector2.from_angle(a) * VELOCIDAD_TECLADO[fase - 1] * randf_range(0.95, 1.05)
		tk.dano = DANO_TECLADO
		get_parent().add_child(tk)
	Sonido.tocar("lanzar")


# ── El cortocircuito ──

func cortocircuito() -> void:
	var corto := Cortocircuito.new()
	corto.sala = sala()
	corto.turnos = TURNOS[fase - 1]
	corto.aviso = AVISO_CORTO[fase - 1]
	corto.dueno = self
	get_parent().add_child(corto)


# El suelo de su sala (la principal del sitio), en unidades
func sala() -> Rect2:
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa and mapa.sitio.has("apt") and not mapa.sitio.apt.salas.is_empty() and mapa.sitio.apt.salas[0].has("c0"):
		var s: Dictionary = mapa.sitio.apt.salas[0]
		return Rect2(Vector2(s.c0, s.f0) * 32.0, Vector2(s.ancho, s.fondo) * 32.0)
	return Rect2(global_position - Vector2(400, 300), Vector2(800, 600))


# ── El apagón ──

# Se va la luz de la sala: más oscuridad y las lámparas, apagadas (como el apagón de los eventos, eventos.gd, pero solo
# un rato)
func apagar() -> void:
	if apagon_t <= 0.0:
		antes_apagon = Luz.evento
		Luz.evento = maxf(antes_apagon, OSCURO)
		var mapa := get_tree().get_first_node_in_group("mapa")
		if mapa:
			for n in mapa.find_children("*", "", true, false):
				if n.scene_file_path == LAMPARA and n.fuerza > 0.0:
					lamparas[n] = n.fuerza
					n.fuerza = 0.0
	apagon_t = APAGON
	Sonido.tocar("apagon")


func encender() -> void:
	if apagon_t <= 0.0 and lamparas.is_empty():
		return
	apagon_t = 0.0
	Luz.evento = antes_apagon
	for n in lamparas:
		if is_instance_valid(n):
			n.fuerza = lamparas[n]
	lamparas.clear()
	Sonido.tocar("encendido")


func _process(delta: float) -> void:
	if apagon_t > 0.0:
		apagon_t -= delta
		if apagon_t <= 0.0:
			apagon_t = 0.001   # (para que encender() sepa que hay algo que encender)
			encender()
	for l in lucecitas:
		if is_instance_valid(l):
			l.queue_redraw()


func _exit_tree() -> void:
	encender()


func morir() -> void:
	encender()
	super()


# ── El reinicio ──

# Un armario lejos de Johnny junto al que volver a aparecer (el punto andable más cercano a su frente)
func armario_lejos(johnny: Node2D) -> Node2D:
	var lejos := armarios().filter(func(a): return a.global_position.distance_to(johnny.global_position) > LEJOS_REINICIO \
		and a.global_position.distance_to(global_position) > 120.0)
	if lejos.is_empty():
		return null
	return lejos[randi() % lejos.size()]


func armarios() -> Array:
	return get_tree().get_nodes_in_group("muebles").filter(func(m): return m.get("datos") is Dictionary \
		and m.datos.get("tipo", "") == ARMARIO)


func reiniciar(_johnny: Node2D) -> void:
	invulnerable = true
	contacto = 0
	if t >= SE_VA and not datos.ido:
		datos.ido = true
		visible = false
		$Choque.set_deferred("disabled", true)
		Particulas.soltar(get_parent(), global_position + Vector2(0, -40), Vector2(0, -60), Color("#7fe0ff"), 4, 0.4)
	if t >= SE_VA + FUERA and not datos.vuelto:
		datos.vuelto = true
		var destino: Node2D = datos.destino
		var donde := global_position
		if is_instance_valid(destino):
			donde = NavigationServer2D.map_get_closest_point(agente.get_navigation_map(), destino.global_position + Vector2(0, 44))
		global_position = donde
		visible = true
		$Choque.set_deferred("disabled", false)
		Sonido.tocar("encendido")
	if t >= SE_VA + FUERA + VUELVE:
		andar(0.4)


# ── Las lucecitas de los armarios ──

# A cada armario de servidores de la sala le pone sus lucecitas, que parpadean y lucen en la oscuridad
func poner_lucecitas() -> void:
	for a in armarios():
		if a.has_node("Lucecitas"):
			lucecitas.append(a.get_node("Lucecitas"))
			continue
		var l := Node2D.new()
		l.name = "Lucecitas"
		var sin_luz := CanvasItemMaterial.new()
		sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		l.material = sin_luz
		l.draw.connect(pintar_lucecitas.bind(l, a))
		a.add_child(l)
		lucecitas.append(l)


# En el cristal de la puerta del armario (el dibujo, de 28x77 píxeles, apoyado en sus pies): filas de lucecitas verdes y
# ámbar que parpadean, cada una a su ritmo. El armario adonde va a volver al reiniciarse, en rojo y deprisa
func pintar_lucecitas(l: Node2D, armario: Node2D) -> void:
	var ahora := Time.get_ticks_msec() / 1000.0
	var alerta: bool = estado == "reinicio" and datos.get("destino") == armario and not datos.get("vuelto", false)
	var semilla := float(absi(hash(armario.get_instance_id())) % 1000)
	for fila in 9:
		for col in 4:
			var s := sin(semilla * 0.37 + fila * 12.9898 + col * 78.233) * 43758.5453
			s -= floorf(s)
			var ritmo := 1.5 + s * 4.0
			var encendida := sin(ahora * ritmo + s * 20.0) > -0.3
			var color := Color("#6dff8a") if s < 0.6 else Color("#ffc94a")
			if alerta:
				encendida = sin(ahora * 18.0 + fila) > 0.0
				color = Color("#ff4d5e")
			if not encendida:
				continue
			l.draw_rect(Rect2(Vector2(-8 + col * 6, -112 + fila * 10), Vector2(2, 2)), color)
			l.draw_rect(Rect2(Vector2(-9 + col * 6, -113 + fila * 10), Vector2(4, 4)), Color(color, 0.25))


func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, Idioma.t("¡ERROR FATAL!"))
	espera_reinicio = 2.0


# En la foto de la prueba (--captura): tirando los teclados
func foto(_johnny: Node2D) -> void:
	cambiar("teclados", {"angulo": mirada.angle(), "lanzado": false})


func _ready() -> void:
	super()
	poner_lucecitas.call_deferred()


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	sprite.self_modulate = Color.WHITE
	match estado:
		"teclados":
			fijar("lanzar", dir, avance("lanzar_" + dir, minf(1.0, t / DURA_LANZAR)))
		"corto", "apagon":
			fijar("teclear", "s", avance("teclear_s", t / 1.0))
		"grito":
			fijar("teclear", "s", 4)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		"reinicio":
			# parpadea como una pantalla rota: se desplaza a saltos y cambia de color
			fijar("teclear", "s", 2)
			var k := randf()
			sprite.position.x = (randf() - 0.5) * 10.0
			sprite.self_modulate = Color(0.5, 1.0, 1.0, 0.3 + 0.7 * k) if k > 0.4 else Color(1.0, 0.4, 1.0, 0.6)
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)


func _draw() -> void:
	if estado != "reinicio" or not visible:
		return
	# las rayas de la pantalla rota, por encima de su cuerpo
	for i in 4:
		var y := randf_range(-arriba + 10.0, PIE)
		draw_rect(Rect2(Vector2(randf_range(-40, 0), y), Vector2(randf_range(20, 50), 3)),
			Color("#7fe0ff", 0.7) if i % 2 == 0 else Color("#ff6bd6", 0.6))
