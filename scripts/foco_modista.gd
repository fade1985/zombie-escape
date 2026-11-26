# El foco de la pasarela (fase 2 de la modista, «la pasarela»; modista.gd y docs/JEFES_CENTRO.md). Con las luces de la
# tienda apagadas, un círculo de luz recorre la sala de lado a lado (y va bajando y subiendo despacio, para pasar por
# toda ella). Lo que pilla dentro:
#   - la modista, si la pilla de lleno (en medio: CENTRO), se queda cegada y aturdida (modista.gd, "congelada": le
#     entra el doble) y el foco se para encima de ella mientras tanto, más brillante (parar);
#   - los maniquíes vivos se quedan quietos (maniqui_vivo.gd).
# Son dos luces de Godot (la del suelo y la de lo demás, como las lámparas: luz.gd) y, para que se vea bien el borde,
# un aro de cuadraditos que luce por sí mismo. Se crea con FocoModista.new() y se mete en la escena.
class_name FocoModista
extends Node2D

const RADIO := 150.0             # (25 nov, el dueño: algo más grande; era 120)
const VELOCIDAD := 115.0       # lo deprisa que cruza de lado a lado
const VUELTA_ALTO := 14.0      # lo que tarda en bajar y volver a subir (segundos)
const COLOR := Color(1.0, 0.96, 0.84)
const CENTRO := 68.0           # la modista se ciega si tiene los pies a menos de esto del centro (de lleno)

var zona := Rect2()            # por donde puede ir su centro (dentro de las paredes)
var ida := 1.0                 # hacia dónde va ahora (1 a la derecha, -1 a la izquierda)
var tiempo := 0.0
var luces: Array[PointLight2D] = []
var encendido := 0.0           # se enciende poco a poco al empezar
var parado := 0.0              # mientras sea > 0, quieto encima de la modista cegada, y más brillante (parar)


func _ready() -> void:
	add_to_group("foco_modista")
	z_index = -1
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sin_luz.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = sin_luz
	for capa in [Luz.CAPA_SUELO, Luz.TODAS & ~Luz.CAPA_SUELO]:
		var luz := PointLight2D.new()
		luz.texture = Luz.TEXTURA
		luz.texture_scale = RADIO * 1.25 / 128.0
		luz.color = COLOR
		luz.energy = 0.0
		luz.range_item_cull_mask = capa
		add_child(luz)
		luces.append(luz)
	var mapa := get_tree().get_first_node_in_group("mapa")
	if mapa and mapa.get("sitio") is Dictionary and mapa.sitio.has("ancho"):
		var borde: float = mapa.MURO + RADIO * 0.5
		var a: Vector2 = mapa.to_global(Vector2(borde, borde))
		var b: Vector2 = mapa.to_global(Vector2(mapa.sitio.ancho - borde, mapa.sitio.alto - borde))
		zona = Rect2(a, (b - a).max(Vector2.ONE))
	else:
		zona = Rect2(global_position - Vector2(400, 250), Vector2(800, 500))
	global_position = Vector2(zona.position.x, zona.get_center().y)


func _physics_process(delta: float) -> void:
	encendido = minf(1.0, encendido + delta * 1.5)
	if parado > 0.0:
		# quieto, latiendo más fuerte: que se vea que ahora es cuando
		parado -= delta
		var late := 0.5 + 0.5 * sin(parado * 18.0)
		luces[0].energy = (1.9 + 0.5 * late) * encendido
		luces[1].energy = (1.5 + 0.4 * late) * encendido
		queue_redraw()
		return
	tiempo += delta
	var x := global_position.x + ida * VELOCIDAD * delta
	if x >= zona.end.x:
		x = zona.end.x
		ida = -1.0
	elif x <= zona.position.x:
		x = zona.position.x
		ida = 1.0
	# baja y sube despacio, para pasar por toda la sala
	var y := zona.get_center().y - cos(tiempo * TAU / VUELTA_ALTO) * zona.size.y * 0.5
	global_position = Vector2(x, y)
	luces[0].energy = 1.5 * encendido
	luces[1].energy = 1.2 * encendido
	queue_redraw()


# ¿Le da la luz a ese punto? ("centro": solo si le da de lleno, en medio del círculo)
func alumbra(p: Vector2, centro := false) -> bool:
	return encendido >= 0.5 and p.distance_to(global_position) < (CENTRO if centro else RADIO * 0.9)


# Se para un rato (la modista se ha quedado cegada en medio)
func parar(segundos: float) -> void:
	parado = segundos


static func alumbrado(arbol: SceneTree, p: Vector2, centro := false) -> bool:
	for foco in arbol.get_nodes_in_group("foco_modista"):
		if foco.alumbra(p, centro):
			return true
	return false


# Un poco de luz encima (que se note el círculo aunque el suelo sea oscuro) y el aro del borde, a cuadraditos
func _draw() -> void:
	var a := encendido
	Formas.disco(self, Vector2.ZERO, RADIO * 0.95, Color(1.0, 0.95, 0.8, (0.16 if parado > 0.0 else 0.07) * a))
	var n := 72
	for i in n:
		if i % 3 == 2:
			continue   # (a trozos: como el borde de un foco de teatro)
		var ang := i * TAU / n + tiempo * 0.15
		var p := (Vector2.from_angle(ang) * RADIO / 2.0).floor() * 2.0
		draw_rect(Rect2(p, Vector2(2, 2)), Color(1.0, 0.92, 0.7, 0.35 * a))
