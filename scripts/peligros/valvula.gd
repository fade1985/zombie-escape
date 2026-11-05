# La válvula del gas de Recursos Humanos (gas.gd): colgada en la pared de arriba del archivo, como el cuadro eléctrico de
# la electrónica (cuadro.gd). Plantándose delante (o delante del mueble que tenga debajo, hasta "alcance") se gira la
# rueda: se corta el gas de las rejillas. Apartándose y volviendo, se abre otra vez. Se dibuja con código, a píxeles de
# 2 unidades: la tubería que baja al suelo, la rueda roja (con una raya que gira) y un reloj con la aguja. El nodo va en el
# pie de la pared, para ordenarse con la cara del muro. Las de la planta de la limpiadora de noche ("rejilla" en sus
# datos) cortan solo su rejilla y no se vuelven a abrir.
extends Node2D

const ARRIBA := -80.0        # dónde empieza el dibujo, por encima del pie de la pared

var datos: Dictionary        # {x, y, alcance, sala} (peligros.gd)
var gas: Node                # el gas de las rejillas, que es quien se abre y se cierra
var mapa: Node
var listo := true            # hay que apartarse antes de volver a usarla
var giro := 0.0              # lo girada que está la rueda (se ve girar al usarla)
var t := 0.0


func montar(d: Dictionary, g: Node, m: Node) -> void:
	datos = d
	gas = g
	mapa = m
	name = "Valvula"   # no-tr (nombre de nodo)
	position = Vector2(d.x, d.y + 1)


# ¿Sale gas por lo suyo? (la de siempre, todo el gas; las de la limpiadora, su rejilla)
func abierta() -> bool:
	if datos.has("rejilla"):
		return gas.datos.abierto and not gas.datos.rejillas[datos.rejilla].get("cerrada", false)
	return gas.datos.abierto


func _physics_process(delta: float) -> void:
	t += delta
	var meta := 0.0 if abierta() else PI * 1.5
	giro = move_toward(giro, meta, delta * 6.0)
	# como el cuadro: en una habitación aún sin descubrir se oscurece
	var oscuro: float = mapa.niebla.get(datos.sala, 0.0)
	modulate = Color.WHITE.lerp(Color(0.07, 0.063, 0.11), 0.9 * oscuro)
	queue_redraw()
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny == null or not johnny.vivo:
		return
	var p: Vector2 = johnny.global_position
	var delante: bool = absf(p.x - global_position.x) < 46.0 and p.y > datos.y - 10.0 and p.y - datos.y < datos.alcance
	if not delante:
		listo = true
	elif listo and not (datos.has("rejilla") and not abierta()):
		listo = false
		Sonido.tocar("palanca")
		Sonido.tocar("siseo")
		for i in 8:
			Particulas.soltar(self, global_position + Vector2(0, ARRIBA + 24), Vector2(randf_range(-70, 70), randf_range(-80, 20)),
				Color("#c77dff") if i % 2 else Color.WHITE, 2, 0.3)
		if datos.has("rejilla"):
			gas.cerrar_rejilla(datos.rejilla)
		else:
			gas.cambiar()


func px(x: int, y: int, w: int, h: int, color: Color) -> void:
	draw_rect(Rect2(Vector2(x * 2 - 12, ARRIBA + y * 2), Vector2(w * 2, h * 2)), color)


func _draw() -> void:
	# la tubería que baja al suelo, con su codo
	draw_rect(Rect2(-4, ARRIBA + 30, 8, -ARRIBA - 30), Color("#4b4f57"))
	draw_rect(Rect2(-4, ARRIBA + 30, 2, -ARRIBA - 30), Color("#757b85"))
	# el reloj de presión: blanco con su aguja (en rojo si sale gas)
	px(1, 0, 6, 6, Color("#24262b"))
	px(2, 1, 4, 4, Color("#e8e6df"))
	px(3, 3 if abierta() else 2, 2, 1, Color("#c7342b") if abierta() else Color("#3a3d44"))
	# la rueda roja: un aro con sus radios, que gira
	var centro := Vector2(4, ARRIBA + 30)
	draw_circle(centro, 11.0, Color("#24262b"))
	draw_circle(centro, 9.0, Color("#c7342b"))
	draw_circle(centro, 5.0, Color("#24262b"))
	for k in 3:
		var a := giro + k * TAU / 3.0
		var punta := centro + Vector2.from_angle(a) * 8.0
		draw_rect(Rect2(roundf(punta.x / 2.0) * 2.0 - 2, roundf(punta.y / 2.0) * 2.0 - 2, 4, 4), Color("#f06a5c"))
	draw_rect(Rect2(centro.x - 2, centro.y - 2, 4, 4), Color("#d9d9d9"))
