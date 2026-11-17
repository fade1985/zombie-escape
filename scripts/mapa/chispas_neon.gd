# Las chispas de un letrero o un neón roto del centro comercial (17 nov, el dueño): puntitos de un píxel, amarillos y
# blancos, que saltan hacia los lados y caen, sumando su luz (se ven aunque el pasillo esté a oscuras). Las usa el
# letrero del súper (neon.gd, de su E caída); listas para otros letreros rotos. Quien las usa les pone el
# sitio (position), las añade como hija y las lanza con restart()
extends RefCounted


static func crear() -> CPUParticles2D:
	var chispas := CPUParticles2D.new()
	chispas.emitting = false
	chispas.one_shot = true
	chispas.amount = 14
	chispas.lifetime = 0.7
	chispas.explosiveness = 0.9
	chispas.local_coords = false
	chispas.direction = Vector2(0, -1)
	chispas.spread = 75.0
	chispas.initial_velocity_min = 40.0
	chispas.initial_velocity_max = 120.0
	chispas.gravity = Vector2(0, 420)
	chispas.scale_amount_min = 2.0   # un píxel del dibujo
	chispas.scale_amount_max = 2.0
	var apagarse := Gradient.new()
	apagarse.set_color(0, Color(1, 1, 0.85, 1))
	apagarse.set_color(1, Color(1, 0.45, 0.1, 0))
	apagarse.add_point(0.35, Color(1, 0.85, 0.3, 1))
	chispas.color_ramp = apagarse
	var suma := CanvasItemMaterial.new()
	suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	suma.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	chispas.material = suma
	chispas.z_index = 5
	return chispas
