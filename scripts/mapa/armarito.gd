# El armarito del baño (Armarito en src/props.js del JS): colgado en la pared de arriba, con un botiquín dentro.
# Se coge plantándose delante (o delante del mueble que tenga debajo, hasta "alcance"): avisa con "usar" y la
# partida cura a Johnny (o le dice que tiene la vida al máximo, y no se gasta). Ya cogido, se queda abierto y
# vacío. El nodo va en el pie de la pared, para ordenarse con la cara del muro (como los apliques).
extends Node2D

signal usar

var datos: Dictionary      # {x, y, alcance, cogido} (planta.gd): se queda en la planta al salir del piso
var johnny: Node2D
var mapa: Node = null      # para mirar la niebla de su habitación (en una sin descubrir, queda a oscuras)
var zona := -1
var listo := true          # hay que apartarse antes de volver a intentarlo
var dibujo: Sprite2D
var brillo: PointLight2D
var t := 0.0


func montar(d: Dictionary) -> void:
	datos = d
	name = "Armarito"
	position = Vector2(d.x, d.y + 1)
	dibujo = Sprite2D.new()
	dibujo.texture = load("res://assets/sprites/armarito.png")
	dibujo.hframes = 2
	dibujo.scale = Vector2(2, 2)
	dibujo.position = Vector2(0, -56)   # en la cara del muro, a media altura
	add_child(dibujo)
	# un brillo verde mientras tiene el botiquín, para que se vea en la penumbra
	brillo = PointLight2D.new()
	brillo.texture = load("res://escenas/luces/luz_suave.tres")
	brillo.texture_scale = 0.25
	brillo.color = Color("#80ed99")
	brillo.position = Vector2(0, -50)
	add_child(brillo)
	vaciar(d.cogido)


func vaciar(si := true) -> void:
	datos.cogido = si
	dibujo.frame = 1 if si else 0
	brillo.visible = not si


func _physics_process(delta: float) -> void:
	t += delta
	# como las caras de muro: en una habitación aún sin descubrir se oscurece, y su brillo se apaga
	var oscuro: float = mapa.niebla.get(zona, 0.0) if mapa and zona >= 0 else 0.0
	dibujo.modulate = Color.WHITE.lerp(Color(0.07, 0.063, 0.11), 0.9 * oscuro)
	brillo.energy = (0.5 + sin(t * 3.0) * 0.15) * (1.0 - oscuro)
	brillo.enabled = oscuro < 0.98
	if datos.cogido or johnny == null or not johnny.vivo:
		return
	var p := johnny.global_position
	var delante: bool = absf(p.x - global_position.x) < 46.0 and p.y > datos.y - 10.0 and p.y - datos.y < datos.alcance
	if not delante:
		listo = true
	elif listo:
		listo = false
		usar.emit()
