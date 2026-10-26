# El aura del arma que Johnny lleva en la mano, según su calidad (Armas.AURA; la Normal no tiene): una luz del color de la
# calidad pegada al arma y, en las mejores, chispas que saltan de su punta. Va de hija de Johnny y cada fotograma mira qué
# lleva (el arma y su calidad), así que se pone sola al cambiar de arma con Q, al mejorarla en el banco o al cogerla del suelo.
# La luz es la de los fuegos (luz/fuego.gd): sin sombras, pensada para durar poco, y aquí late despacio. Las chispas las
# pinta este nodo (no Particulas) para que luzcan por sí mismas aunque la sala esté a oscuras.
#
# Dónde está la punta: las armas de fuego traen su boca en cada dirección (Armas.DATOS, "boca"); las de cuerpo a cuerpo no, y
# se usa un punto aproximado de la mano, hacia donde mira (MANO).
class_name AuraArma
extends Node2D

const HALO := preload("res://escenas/luces/luz_suave.tres")   # el brillo suave de las luces, pintado de color
const MANO := 24.0       # lo lejos del centro de Johnny, hacia donde mira, que lleva la mano el arma de cuerpo a cuerpo
const MANO_ALTO := -4.0   # y a qué altura de su centro
const DIRECCIONES := {"e": Vector2(1, 0), "se": Vector2(0.7071, 0.7071), "s": Vector2(0, 1), "so": Vector2(-0.7071, 0.7071),
	"o": Vector2(-1, 0), "no": Vector2(-0.7071, -0.7071), "n": Vector2(0, -1), "ne": Vector2(0.7071, -0.7071)}

var johnny: Node2D
var luz: PointLight2D
var calidad := 0                      # la calidad que se ve ahora (0 = ninguna)
var suave := Vector2.ZERO             # dónde está la luz respecto a Johnny (va detrás de la punta, sin saltos al girar)
var chispa_t := 0.0                   # lo que falta para la siguiente chispa
var chispas: Array[Dictionary] = []   # las que vuelan: {"p", "v", "c", "s" (lado), "t", "max"}


func _ready() -> void:
	johnny = get_parent()
	top_level = true   # en el mundo, en el origen: las chispas se quedan donde saltaron aunque Johnny ande
	z_index = 5        # por encima de Johnny, como la gota del lanza ácido
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # el halo y las chispas lucen por sí mismos
	propio.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD        # y suman luz a lo que tienen debajo
	material = propio


func _process(delta: float) -> void:
	var q: int = johnny.calidad(johnny.huecos[johnny.mano]) if johnny.vivo else 0
	if q != calidad:
		cambiar(q)
	if calidad > 0:
		var punta := punta_del_arma()
		suave = suave.lerp(punta * 0.8, 1.0 - exp(-delta * 14.0))
		luz.position = johnny.global_position + suave
		var por_segundo: float = Armas.AURA[calidad].chispas
		if por_segundo > 0.0 and is_visible_in_tree():
			chispa_t -= delta
			if chispa_t <= 0.0:
				chispa_t = randf_range(0.5, 1.5) / por_segundo
				chispa(johnny.global_position + punta)
	var vuelan := not chispas.is_empty()
	for c in chispas:
		c.t -= delta
		c.p += c.v * delta
		c.v *= exp(-delta * 2.0)
	chispas = chispas.filter(func(c): return c.t > 0.0)
	if vuelan or calidad > 0:
		queue_redraw()


# Pasa a otra calidad: la luz, de su color y su tamaño (la crea la primera vez); con la Normal, se apaga
func cambiar(q: int) -> void:
	calidad = q
	if q <= 0:
		if luz:
			luz.hide()
		return
	var a: Dictionary = Armas.AURA[q]
	if luz == null:
		luz = Llamas.LUZ.instantiate()
		luz.name = "LuzArma"
		luz.latido = true
		luz.position = johnny.global_position + punta_del_arma() * 0.8
		suave = punta_del_arma() * 0.8
		add_child(luz)
	luz.color = Armas.color(q)
	luz.radio = a.luz
	luz.texture_scale = a.luz / 128.0
	luz.fuerza = a.fuerza
	luz.show()


# Dónde está la punta del arma que lleva, respecto al centro de Johnny: la boca del cañón o el extremo del arma de cuerpo a
# cuerpo (Armas.DATOS, "boca" y "punta": como en johnny.tiro, en píxeles del dibujo desde los pies, x2 para pasar a
# unidades; los pies van 16 unidades por debajo del centro) o, si no la tiene, un punto aproximado de la mano
func punta_del_arma() -> Vector2:
	var w: Dictionary = Armas.datos(johnny.huecos[johnny.mano])
	var puntas: Dictionary = w.get("boca", w.get("punta", {}))
	var hacia: String = johnny.direccion
	if puntas.has(hacia):
		var b: Vector2 = puntas[hacia] * 2.0
		return Vector2(b.x, 16.0 + b.y)
	return DIRECCIONES.get(hacia, Vector2.DOWN) * MANO + Vector2(0, MANO_ALTO)


# Una chispa del color de la calidad: sale de la punta, sube un poco y se apaga
func chispa(donde: Vector2) -> void:
	var tonos := Armas.traza(calidad)
	var vida := randf_range(0.35, 0.65)
	chispas.append({"p": donde + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)),
		"v": Vector2(randf_range(-28.0, 28.0), randf_range(-80.0, -30.0)), "c": tonos[randi() % 3],
		"s": 4.0 if randf() < 0.3 else 2.0, "t": vida, "max": vida})


func _draw() -> void:
	if calidad > 0 and luz != null and luz.is_visible_in_tree():
		# el halo: un brillo suave del color de la calidad sobre el arma, que late despacio
		var a: Dictionary = Armas.AURA[calidad]
		var r: float = a.halo
		var latido := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.004)
		draw_texture_rect(HALO, Rect2(johnny.global_position + suave - Vector2(r, r), Vector2(r, r) * 2.0), false,
			Color(Armas.color(calidad), a.brillo * latido))
	for c in chispas:
		var k: float = c.t / c.max
		var p: Vector2 = (c.p / 2.0).round() * 2.0   # en píxeles enteros del dibujo
		draw_rect(Rect2(p, Vector2(c.s, c.s)), Color(c.c, minf(1.0, k * 2.0)))
