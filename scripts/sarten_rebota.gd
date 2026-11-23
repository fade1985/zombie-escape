# Una sartén del cocinero que rebota por la sala (minijefe del centro comercial; docs/JEFES_CENTRO.md), dibujada con
# código. Sale girando de su mano y rebota en las paredes y los muebles sin pararse nunca (como las pelotas de goma del
# antidisturbios: pelota_goma.gd), soltando gotas de aceite hirviendo (charquitos que queman un poco y se secan). No se
# van solas: se acumulan hasta que el cocinero las recoge («¡A FREGAR!», cocinero.gd): tiemblan un momento (el aviso)
# y vuelven volando en línea recta a su mano, dando a quien pillen por el camino. No se rompen.
# Se crea con SartenRebota.new(); se le pone "velocidad" y "dueno" antes de meterla en la escena.
class_name SartenRebota
extends Node2D

const RADIO := 12.0
const DANO := 10
const ESPERA_GOLPE := 0.6  # tras darle a Johnny, lo que tarda en poder darle otra vez
const CADA_GOTA := 0.8     # cada cuánto suelta una gota de aceite
const CHARCO := "res://escenas/armas/charco.tscn"
const TIEMBLA := 0.6       # el aviso antes de volver a la mano del cocinero
const VUELTA := 620.0      # lo deprisa que vuelve

var velocidad := Vector2.ZERO
var dueno: Node2D = null
var t := 0.0
var espera := 0.0
var gota := 0.4
var volver := -1.0         # >= 0: la está recogiendo (lo que lleva desde que se lo ha pedido)


func _ready() -> void:
	add_to_group("balas_zombi")   # (el bot las esquiva como las demás balas)
	add_to_group("sartenes")
	z_index = 4


func _physics_process(delta: float) -> void:
	t += delta
	espera -= delta
	queue_redraw()
	if volver >= 0.0:
		recoger(delta)
		return
	var antes := global_position
	var despues := antes + velocidad * delta
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	var choque := get_world_2d().direct_space_state.intersect_ray(rayo)
	if not choque.is_empty():
		velocidad = velocidad.bounce(choque.normal)
		global_position = choque.position + choque.normal * 2.0
		Sonido.tocar("clonc")
		return
	global_position = despues
	gota -= delta
	if gota <= 0.0:
		gota = CADA_GOTA
		soltar_gota()
	tocar_johnny()


# Si le da a Johnny (no esquivando), le quita lo suyo
func tocar_johnny() -> void:
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny == null or not johnny.vivo or espera > 0.0 or johnny.esquiva_t > 0.0:
		return
	var hacia: Vector2 = johnny.global_position - global_position
	if hacia.length() < johnny.RADIO + RADIO:
		johnny.recibir_dano(DANO, dueno)
		espera = ESPERA_GOLPE
		if volver < 0.0:
			velocidad = velocidad.bounce(hacia.normalized())   # rebota en él
		Sonido.tocar("clonc")


# Una gota de aceite hirviendo en el suelo: un charquito que quema y se seca enseguida
func soltar_gota() -> void:
	var charco: Node2D = load(CHARCO).instantiate()
	charco.tipo = "hirviendo"
	charco.escala = 0.4
	charco.extra = -3.0   # (dura 3 s: el de la sartén, 6)
	charco.dueno = dueno
	charco.position = (global_position / 2.0).round() * 2.0
	get_parent().add_child(charco)


# El cocinero la recoge: tiembla un momento y vuelve recta a su mano (dando a quien pille por el camino)
func recoger(delta: float) -> void:
	volver += delta
	if volver < TIEMBLA or not is_instance_valid(dueno):
		if not is_instance_valid(dueno) and volver >= TIEMBLA:
			queue_free()
		return
	var hacia: Vector2 = dueno.global_position + Vector2(0, -20) - global_position
	if hacia.length() < VUELTA * delta + 10.0:
		queue_free()
		return
	global_position += hacia.normalized() * VUELTA * delta
	tocar_johnny()


func pedir_vuelta() -> void:
	if volver < 0.0:
		volver = 0.0


func _draw() -> void:
	var temblor := Vector2(sin(t * 70.0) * 2.0, 0) if volver >= 0.0 and volver < TIEMBLA else Vector2.ZERO
	# la sombra en el suelo y la sartén por encima, girando
	Formas.disco(self, Vector2(0, 10), 10.0, Color(0, 0, 0, 0.25))
	var giro := t * 14.0
	var c := ((temblor + Vector2(0, -10)) / 2.0).floor() * 2.0
	var mango := Vector2.from_angle(giro)
	for i in 6:
		var p := ((c + mango * (12.0 + i * 2.0)) / 2.0).floor() * 2.0
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color("#3a2a20"))
	Formas.disco(self, c, 12.0, Color("#1d1b2c"))
	Formas.disco(self, c, 10.0, Color("#4a4a58"))
	Formas.disco(self, c + Vector2(-2, -2), 7.0, Color("#2e2e3a"))
	# el aceite que le queda dentro, brillando
	Formas.disco(self, c + Vector2(1, 1), 4.0, Color("#e8c547"))
	if volver >= 0.0 and volver < TIEMBLA and int(t * 10.0) % 2 == 0:
		Formas.disco(self, c, 14.0, Color(1, 0.3, 0.3, 0.35))
