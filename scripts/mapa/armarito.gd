# El armarito del baño (Armarito en src/props.js del JS): colgado en la pared de arriba, con un botiquín o unas vendas
# dentro ("dentro", planta.gd; uno por apartamento). Se abre como el ordenador (M11): con Johnny delante (o delante del
# mueble que tenga debajo, hasta "alcance") y el clic encima del armarito, J o RT (zona_usar.gd, con su contorno amarillo).
# Avisa con "usar" y la partida lo suelta al suelo (abrir_armarito), que Johnny recoge pasando por encima y usa luego con su tecla.
# Ya abierto, se queda abierto y vacío. El nodo va en el pie de la pared, para ordenarse con la cara del muro (como los apliques).
extends Node2D

signal usar

const ZONA_USAR := preload("res://scripts/mapa/zona_usar.gd")

var datos: Dictionary      # {x, y, alcance, cogido} (planta.gd): se queda en la planta al salir del piso
var johnny: Node2D
var mapa: Node = null      # para mirar la niebla de su habitación (en una sin descubrir, queda a oscuras)
var habitacion := -1       # la habitación que tiene delante (para la niebla)
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
	# la zona de delante donde se para Johnny para abrirlo (la misma que el ordenador): solo mientras está lleno
	var zona := ZONA_USAR.new()
	zona.montar_rect(Rect2(-46, -11, 92, d.alcance + 10))
	zona.puede = func() -> bool: return not datos.cogido
	zona.al_pie = true   # (si no, con el dibujo alto en la pared, la puerta del baño le quitaría el sitio)
	add_child(zona)
	zona.usar.connect(usar.emit)
	vaciar(d.cogido)


func vaciar(si := true) -> void:
	datos.cogido = si
	dibujo.frame = 1 if si else 0
	brillo.visible = not si


func _physics_process(delta: float) -> void:
	t += delta
	# como las caras de muro: en una habitación aún sin descubrir se oscurece, y su brillo se apaga
	var oscuro: float = mapa.niebla.get(habitacion, 0.0) if mapa and habitacion >= 0 else 0.0
	dibujo.modulate = Color.WHITE.lerp(Color(0.07, 0.063, 0.11), 0.9 * oscuro)
	brillo.energy = (0.5 + sin(t * 3.0) * 0.15) * (1.0 - oscuro)
	brillo.enabled = oscuro < 0.98
