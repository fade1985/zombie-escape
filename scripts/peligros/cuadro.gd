# El cuadro eléctrico de la tienda de electrónica (agua.gd): colgado en la pared de arriba del almacén o de las
# taquillas, como el armarito del baño (armarito.gd). Delante de él (o delante del mueble que tenga debajo, hasta
# "alcance") se baja la palanca con la acción de usar, como los muebles y las puertas (zona_usar.gd: la E, el botón B
# del mando o el botón «Usar» del móvil; 18 nov, lo pidió el dueño: antes bastaba con acercarse y se encendía y se
# apagaba sin querer): se va la corriente de la tienda, el agua deja de dar calambrazos y todo se queda a oscuras.
# Otra vez, se sube. Con Johnny delante, el contorno amarillo de los muebles que se usan. Se dibuja con código, a píxeles de 2 unidades:
# la caja gris con su pegatina de peligro, la palanca (arriba con corriente, abajo sin ella) y un piloto rojo.
# El nodo va en el pie de la pared, para ordenarse con la cara del muro.
extends Node2D

const ARRIBA := -80.0        # dónde empieza la caja, por encima del pie de la pared
const PILOTO := Color("#ff3b3b")
const ZONA_USAR := preload("res://scripts/mapa/zona_usar.gd")

var datos: Dictionary        # {x, y, alcance, sala} (peligros.gd)
var agua: Node               # el charco con corriente, que es quien la quita y la da
var mapa: Node
var zona: Area2D             # delante de él: ahí se usa (zona_usar.gd)
var contorno: Node2D         # el contorno amarillo, sin penumbra, mientras se puede usar
var brillo: PointLight2D
var t := 0.0


func montar(d: Dictionary, charco: Node, m: Node) -> void:
	datos = d
	agua = charco
	mapa = m
	name = "Cuadro"   # no-tr (nombre de nodo)
	position = Vector2(d.x, d.y + 1)
	# un brillo rojo mientras hay corriente, para que se vea en la penumbra
	brillo = PointLight2D.new()
	brillo.texture = preload("res://escenas/luces/luz_suave.tres")
	brillo.texture_scale = 0.3
	brillo.color = PILOTO
	brillo.position = Vector2(-6, ARRIBA + 10)
	add_child(brillo)
	# la zona de delante (la del armarito del baño), y el contorno: la caja dibujada con código no es un dibujo del que
	# zona_usar.gd pueda sacar el suyo, así que se pinta aquí, un píxel alrededor de la caja
	zona = ZONA_USAR.new()
	zona.montar_rect(Rect2(-46, -11, 92, d.alcance + 10))
	zona.al_pie = true
	zona.boton = Idioma.t("Usar")
	add_child(zona)
	zona.usar.connect(bajar_palanca)
	contorno = Node2D.new()
	contorno.name = "Contorno"   # no-tr (nombre de nodo)
	var sin_luz := CanvasItemMaterial.new()
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	contorno.material = sin_luz
	contorno.draw.connect(func(): contorno.draw_rect(Rect2(-16, ARRIBA - 2, 32, 40), ZONA_USAR.COLOR_CONTORNO, false, 2.0))
	contorno.visible = false
	add_child(contorno)


func _physics_process(delta: float) -> void:
	t += delta
	# como el armarito: en una habitación aún sin descubrir se oscurece y su brillo se apaga
	var oscuro: float = mapa.niebla.get(datos.sala, 0.0)
	modulate = Color.WHITE.lerp(Color(0.07, 0.063, 0.11), 0.9 * oscuro)
	brillo.enabled = agua.datos.corriente and oscuro < 0.98
	brillo.energy = (0.55 + sin(t * 4.0) * 0.15) * (1.0 - oscuro)
	queue_redraw()
	contorno.visible = zona.resaltado()


# La palanca: abajo si estaba arriba y al revés, con su chasquido y unas chispas
func bajar_palanca() -> void:
	Sonido.tocar("palanca")
	for i in 8:
		Particulas.soltar(self, global_position + Vector2(8, ARRIBA + 20), Vector2(randf_range(-70, 70), randf_range(-80, 20)),
			Color.WHITE if i % 2 else Color("#9fe8ff"), 2, 0.25)
	agua.cambiar_corriente()


# Un rectángulo en píxeles del dibujo (cada uno, 2 unidades) contando desde la esquina de arriba de la caja
func px(x: int, y: int, w: int, h: int, color: Color) -> void:
	draw_rect(Rect2(Vector2(x * 2 - 14, ARRIBA + y * 2), Vector2(w * 2, h * 2)), color)


func _draw() -> void:
	var luz: bool = agua.datos.corriente
	# el tubo de los cables, de la caja al suelo
	draw_rect(Rect2(-4, ARRIBA + 36, 6, -ARRIBA - 36), Color("#3a3d44"))
	draw_rect(Rect2(-4, ARRIBA + 36, 2, -ARRIBA - 36), Color("#5a5f68"))
	# la caja: borde oscuro, chapa gris con brillo arriba y la raya de la puerta
	px(0, 0, 14, 18, Color("#24262b"))
	px(1, 1, 12, 16, Color("#7d838c"))
	px(1, 1, 12, 1, Color("#a3aab3"))
	px(1, 16, 12, 1, Color("#5b616a"))
	px(9, 2, 1, 14, Color("#5b616a"))
	# la pegatina amarilla de peligro con su rayo
	for i in 4:
		px(4 - i, 3 + i, 1 + i * 2, 1, Color("#ffd23f"))
	px(4, 4, 1, 2, Color("#1a1a1a"))
	px(3, 6, 1, 1, Color("#1a1a1a"))
	# el piloto: rojo con corriente
	px(2, 12, 2, 2, PILOTO if luz and sin(t * 4.0) > -0.6 else Color("#3a1414"))
	# la palanca, en su ranura: arriba con corriente, abajo sin ella
	px(11, 4, 1, 10, Color("#2b2d33"))
	var y := 4 if luz else 11
	px(10, y, 3, 3, Color("#c7342b"))
	px(10, y, 3, 1, Color("#f06a5c"))
