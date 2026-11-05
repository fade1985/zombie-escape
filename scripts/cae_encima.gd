# Lo que la directora de Recursos Humanos (minijefa de Torre Velaria, directora.gd) hace caer del techo, dibujado con
# código como el cuchillo del cocinero: su sello de despido gigante ("sello") y las cajas de cartón de recoger la mesa
# al irte ("caja"). En el suelo, desde el principio, se ve su marca (y su sombra, que crece según baja: siempre se puede
# esquivar). Al caer, si Johnny está dentro, le quita lo suyo; el sello, además, le «despide»: unos segundos sin el arma
# de fuego (johnny.gd, despedir()). Luego el sello deja su tinta roja en el suelo un rato y la caja se rompe en papeles.
# Se crea con CaeEncima.new() y se le ponen tipo, donde, aviso, dano, despido y dueno antes de meterlo en la escena.
class_name CaeEncima
extends Node2D

const ALTURA := 340.0       # desde dónde cae (lo alto que empieza)
const RADIO := {"sello": 62.0, "caja": 34.0}   # lo que ocupa su marca (media anchura; de alto, el 60 %)
const TINTA := 4.0          # lo que dura la tinta del sello en el suelo
const PAPELES := 1.2        # lo que tardan en irse los trozos de la caja
const ROJO := Color("#c8283a")
const CARTON := Color("#b98a52")
const CARTON_OSCURO := Color("#8a6238")

var tipo := "caja"
var donde := Vector2.ZERO   # dónde cae (el centro de la marca)
var aviso := 0.9            # lo que tarda en caer (lo que se ve la marca antes)
var dano := 10
var despido := 0.0          # el sello: los segundos que deja a Johnny sin el arma de fuego
var dueno: Node2D = null    # quien lo tira, la directora (para la skin del glotón: johnny.gd, devolver())
var t := 0.0
var caido := -1.0           # lo que lleva en el suelo (-1 = aún cae)
var alto := ALTURA
var giro := 0.0             # (la caja da vueltas al caer)


func _ready() -> void:
	add_to_group("balas_zombi")   # así, al enfadarse ella, se borra lo que aún esté cayendo
	global_position = donde
	z_index = 5
	giro = randf_range(-0.5, 0.5)
	# la marca va aparte, por debajo y sin que le afecte la penumbra (luce por sí misma, como los avisos de los jefes:
	# a oscuras también se tiene que ver venir)
	marca = Node2D.new()
	marca.z_as_relative = false
	marca.z_index = -1   # en el suelo, por debajo de todos (como los charcos)
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	marca.material = sin_luz
	marca.draw.connect(_pintar_marca)
	add_child(marca)


var marca: Node2D


func radio() -> float:
	return RADIO[tipo]


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	marca.queue_redraw()
	if caido >= 0.0:
		caido += delta
		var dura := TINTA if tipo == "sello" else PAPELES
		modulate.a = clampf((dura - caido) / 0.6, 0.0, 1.0)
		if caido >= dura:
			queue_free()
		return
	# baja cada vez más deprisa (como si cayera de verdad)
	var k := minf(1.0, t / aviso)
	alto = ALTURA * (1.0 - k * k)
	if tipo == "caja":
		giro += delta * 3.0
	if k >= 1.0:
		caer()


func caer() -> void:
	alto = 0.0
	caido = 0.0
	z_index = -1   # ya en el suelo: por debajo de los personajes
	remove_from_group("balas_zombi")
	if tipo == "sello":
		Sonido.tocar("pisoton")
		Temblor.temblar(8.0)
	else:
		Sonido.tocar("portazo")
		Temblor.temblar(3.0)
		for i in 10:
			var color := CARTON if i % 3 else Color("#f2efe4")   # cartón y algún papel
			Particulas.soltar(self, global_position, Vector2(randf_range(-120, 120), randf_range(-110, -30)), color, 3, 0.5)
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and dentro(johnny.global_position, johnny.RADIO * 0.5) and johnny.esquiva_t <= 0.0:
		johnny.recibir_dano(dano, dueno)
		if despido > 0.0:
			johnny.despedir(despido)
		else:
			var hacia: Vector2 = johnny.global_position - global_position
			johnny.empujar((hacia.normalized() if hacia != Vector2.ZERO else Vector2.DOWN) * 380.0)


# La marca es una elipse (el suelo se ve un poco desde arriba)
func dentro(punto: Vector2, margen: float) -> bool:
	var d := punto - global_position
	var r := radio() + margen
	return (d.x / r) ** 2 + (d.y / (r * 0.6)) ** 2 <= 1.0


# La marca roja en el suelo, que se llena según baja, con la sombra de lo que cae, que crece; ya en el suelo, la tinta
# del sello
func _pintar_marca() -> void:
	var r := radio()
	if caido >= 0.0:
		if tipo == "sello":
			tinta(marca, r)
		return
	var k := minf(1.0, t / aviso)
	var rojo := Color(1, 0.24, 0.35)
	marca.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.6))
	Formas.disco(marca, Vector2.ZERO, r * k, Color(rojo, 0.22 + 0.25 * k))
	Formas.arco(marca, Vector2.ZERO, r, 0.0, TAU, 28, Color(rojo, 0.7 + 0.3 * k), 4.0)
	Formas.disco(marca, Vector2.ZERO, r * (0.25 + 0.6 * k), Color(0, 0, 0, 0.25 + 0.25 * k))


func _draw() -> void:
	var r := radio()
	if caido < 0.0:
		if tipo == "sello":
			sello(self, Vector2(0, -alto), r)
		else:
			caja(self, Vector2(0, -alto), giro)
	# (en el suelo, la tinta del sello va en la marca; la caja, rota, solo deja sus trozos, que son partículas)


# El sello gigante, de lado: la goma roja abajo (donde "pie"), el mango de madera encima
static func sello(lienzo: CanvasItem, pie: Vector2, r: float) -> void:
	var ancho := r * 1.3
	lienzo.draw_set_transform(pie)
	lienzo.draw_rect(Rect2(-ancho / 2.0 - 2, -22, ancho + 4, 24), Color("#2b1b20"))   # contorno
	lienzo.draw_rect(Rect2(-ancho / 2.0, -20, ancho, 20), ROJO)                       # la base
	lienzo.draw_rect(Rect2(-ancho / 2.0, -20, ancho, 4), Color("#e2525f"))              # su brillo
	lienzo.draw_rect(Rect2(-ancho / 2.0, -4, ancho, 4), Color("#5a0f18"))               # la goma, con tinta
	lienzo.draw_rect(Rect2(-12, -66, 24, 48), Color("#2b1b20"))                         # el mango
	lienzo.draw_rect(Rect2(-10, -64, 20, 46), Color("#8a4b2a"))
	lienzo.draw_rect(Rect2(-10, -64, 6, 46), Color("#b0683c"))
	Formas.disco(lienzo, Vector2(0, -74), 17.0, Color("#2b1b20"))                      # el pomo
	Formas.disco(lienzo, Vector2(0, -74), 15.0, ROJO)
	Formas.disco(lienzo, Vector2(-4, -78), 5.0, Color("#e2525f"))
	lienzo.draw_set_transform(Vector2.ZERO)


# La caja de cartón (una de las de recoger la mesa al irte), centrada en "centro" y girada "angulo"
static func caja(lienzo: CanvasItem, centro: Vector2, angulo: float) -> void:
	lienzo.draw_set_transform(centro, angulo)
	lienzo.draw_rect(Rect2(-24, -20, 48, 40), Color("#3a2614"))
	lienzo.draw_rect(Rect2(-22, -18, 44, 36), CARTON)
	lienzo.draw_rect(Rect2(-22, -18, 44, 10), CARTON_OSCURO)   # la tapa abierta, por dentro
	lienzo.draw_rect(Rect2(-22, -6, 44, 3), Color("#d6a96b"))
	lienzo.draw_rect(Rect2(-8, 2, 16, 6), Color("#3a2614"))     # el asa
	lienzo.draw_rect(Rect2(-14, -22, 10, 8), Color("#f2efe4"))  # un papel que asoma
	lienzo.draw_set_transform(Vector2.ZERO)


# La tinta que deja el sello en el suelo: un recuadro rojo con «DESPEDIDO» dentro
func tinta(lienzo: CanvasItem, r: float) -> void:
	var w := r * 1.7
	var h := r * 0.75
	var color := Color(ROJO, 0.75)
	lienzo.draw_rect(Rect2(-w / 2.0, -h / 2.0, w, h), color, false, 4.0)
	lienzo.draw_rect(Rect2(-w / 2.0 + 7, -h / 2.0 + 7, w - 14, h - 14), color, false, 2.0)
	var letra := Tema.FUENTE
	var texto := Idioma.t("DESPEDIDO")
	var tam := 16
	var largo := letra.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	if largo > w - 20:   # (en algún idioma es más largo: se encoge)
		tam = 8
		largo = letra.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	lienzo.draw_string(letra, Vector2(-largo / 2.0, tam * 0.35), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)
