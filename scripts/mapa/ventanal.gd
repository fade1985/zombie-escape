# El ventanal del fondo del pasillo de Torre Velaria (lo pone mapa.gd en la pared de arriba, al principio del pasillo): un
# cristal grande con la ciudad de noche detrás, vista desde muy arriba (el cielo oscuro, los edificios de lejos con sus ventanas
# encendidas, algún piloto rojo de aviso que parpadea y la luna). Dibujado con código, a píxeles de 2 unidades como el resto del
# juego, y sin que le afecte la penumbra: se ve la ciudad aunque el pasillo esté a oscuras. Siempre igual (la semilla es fija).
extends Node2D

const ANCHO := 176.0
const ALTO := 76.0
const PIE := 10.0        # a qué altura, por encima del pie del muro, acaba el cristal
const PX := 2.0
const CIELO_ARRIBA := Color("0b1226")
const CIELO_ABAJO := Color("2a2a52")
const MARCO := Color("3b4250")
const MARCO_LUZ := Color("6c7686")

var edificios := []      # [{x, ancho, alto, tono, ventanas: [Vector2]}]
var pilotos := []        # [Vector2]
var tiempo := 0.0


func _ready() -> void:
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = propio
	var rng := RandomNumberGenerator.new()
	rng.seed = 40
	var x := 0.0
	while x < ANCHO - 8:
		var w := float(rng.randi_range(5, 11)) * PX
		var h := float(rng.randi_range(8, 30)) * PX
		var ventanas := []
		var vy := ALTO - h + 4
		while vy < ALTO - 4:
			var vx := 3.0
			while vx < w - 3:
				if rng.randf() < 0.32:
					ventanas.append(Vector2(x + vx, vy))
				vx += 4.0
			vy += 6.0
		edificios.append({"x": x, "ancho": w, "alto": h, "tono": rng.randf_range(0.0, 1.0), "ventanas": ventanas})
		if h > 40 and rng.randf() < 0.6:
			pilotos.append(Vector2(x + w / 2.0, ALTO - h - 2))
		x += w + float(rng.randi_range(0, 2)) * PX


func _process(delta: float) -> void:
	tiempo += delta
	queue_redraw()


func _draw() -> void:
	var x0 := -ANCHO / 2.0
	var y0 := -PIE - ALTO
	# el marco
	draw_rect(Rect2(x0 - 6, y0 - 6, ANCHO + 12, ALTO + 12), MARCO)
	draw_rect(Rect2(x0 - 6, y0 - 6, ANCHO + 12, 2), MARCO_LUZ)
	# el cielo, a franjas
	var franjas := 12
	for i in franjas:
		var c := CIELO_ARRIBA.lerp(CIELO_ABAJO, float(i) / (franjas - 1))
		draw_rect(Rect2(x0, y0 + ALTO * i / franjas, ANCHO, ALTO / franjas + 1), c)
	draw_rect(Rect2(x0 + 128, y0 + 10, 8, 8), Color("d9dff0"))   # la luna
	draw_rect(Rect2(x0 + 130, y0 + 8, 4, 12), Color("d9dff0"))
	draw_rect(Rect2(x0 + 126, y0 + 12, 12, 4), Color("d9dff0"))
	for e in edificios:
		var ex: float = x0 + e.ancho * 0.0 + e.x
		var tono: float = 0.12 + 0.1 * e.tono
		draw_rect(Rect2(ex, y0 + ALTO - e.alto, e.ancho, e.alto), Color(tono, tono + 0.02, tono + 0.08))
		draw_rect(Rect2(ex, y0 + ALTO - e.alto, e.ancho, 2), Color(0.3, 0.32, 0.45))
		for v in e.ventanas:
			draw_rect(Rect2(x0 + v.x, y0 + v.y, 2, 4), Color(1.0, 0.85, 0.5, 0.9))
	for p in pilotos:
		if fmod(tiempo + p.x * 0.07, 2.0) < 1.0:
			draw_rect(Rect2(x0 + p.x - 1, y0 + p.y, 2, 2), Color("ff3b30"))
	# la neblina del cristal y los montantes (tres cristales)
	draw_rect(Rect2(x0, y0, ANCHO, ALTO), Color(0.7, 0.8, 1.0, 0.06))
	for k in [1, 2]:
		draw_rect(Rect2(x0 + ANCHO * k / 3.0 - 2, y0, 4, ALTO), MARCO)
		draw_rect(Rect2(x0 + ANCHO * k / 3.0 - 2, y0, 1, ALTO), MARCO_LUZ)
	draw_rect(Rect2(x0 - 6, y0 + ALTO, ANCHO + 12, 6), MARCO)   # el alféizar
	draw_rect(Rect2(x0 - 6, y0 + ALTO, ANCHO + 12, 2), MARCO_LUZ)
