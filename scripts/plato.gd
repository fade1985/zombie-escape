# Un plato que tira la camarera cuando te acompaña (supervivientes.gd): vuela como una bala (bala.gd), pero se
# ve como un plato blanco que gira y, al dar con algo, se rompe en trocitos con ruido de cristal.
extends "res://scripts/bala.gd"

const BLANCO := Color("#fbf7ee")
const BORDE := Color("#7fb0d8")   # la raya azul del borde, como los platos de un bar

var giro := 0.0


func _physics_process(delta: float) -> void:
	giro += delta * 14.0
	super(delta)


func chocar(_pared := false) -> void:
	var donde := global_position + Vector2(0, -altura)
	Sonido.tocar("cristal")
	for i in 7:
		var v := Vector2.from_angle(randf() * TAU) * randf_range(60.0, 180.0) + Vector2(0, -40)
		Particulas.soltar(self, donde, v, BLANCO if i % 3 else BORDE, 4.0 if i < 3 else 2.0, randf_range(0.2, 0.4))
	queue_free()


# Visto un poco desde arriba: un óvalo blanco con su borde azul que se estrecha y se ensancha al girar
func _draw() -> void:
	var c := Vector2(0, -altura)
	var ancho := 7.0
	var alto := 2.5 + absf(sin(giro)) * 3.0
	var pts := PackedVector2Array()
	for i in 16:
		var a := i / 16.0 * TAU
		pts.append(c + Vector2(cos(a) * ancho, sin(a) * alto))
	draw_colored_polygon(pts, BLANCO)
	pts.append(pts[0])
	var dentro := PackedVector2Array()
	for p in pts:
		dentro.append(c + (p - c) * 0.6)
	draw_polyline(dentro, BORDE, 1.0)
	draw_polyline(pts, LINEA, 2.0)
