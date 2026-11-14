# El cuerpo de un zombi que muere con ácido encima (el de un charco o el que le sigue royendo del lanza ácido), como
# quemado.gd con el fuego, del que aprovecha casi todo (los píxeles de su dibujo tendido, la mancha del suelo y los
# huesos). Contando desde que toca el suelo: cae con sus manchas, burbujas y luz verde; el ácido le cubre entero
# (COMIDO); se lo come a agujeros, antes la cabeza, con un borde verde que hierve y vapor que sube (DESHECHO), y quedan
# un charco verdoso que no hace daño y se va secando, y sus huesos. El agujereado lo pinta su shader
# (escenas/personajes/quemaduras.gdshaderinc: "comido" y "deshecho"). Si muere ardiendo y con ácido, gana el fuego.
class_name Disuelto
extends Quemado

const COMIDO := 1.0     # segundos en cubrirle el ácido entero
const DESHECHO := 3.2   # hasta aquí se lo come (a la vez aparecen debajo su charco y sus huesos)
const SECA := 6.0       # lo que tarda el charco en secarse (se apaga, pero se queda)
const VAPOR := [Color(0.66, 0.94, 0.29, 0.75), Color(0.55, 0.68, 0.42, 0.55)]
const VAHO := [Color("#6f8f4a"), Color("#9bb07a")]   # las columnas de vapor (como el humo de los quemados)

var sonado := 0   # los siseos que ya han sonado (al tocar el suelo y al empezar a deshacerse)


# Lo llama el zombi al morir con ácido. "cae": si tiene animación de caer (el de tentáculos no: se tumba en 0,35 s)
static func disolver(z: Node2D, s: AnimatedSprite2D, talla_restos: String, cae: bool) -> void:
	var d := Disuelto.new()
	d.zombi = z
	d.sprite = s
	d.talla = talla_restos
	d.z_index = 1   # el vapor, encima del cuerpo
	if cae:
		var anim := s.animation
		d.caida = s.sprite_frames.get_frame_count(anim) / s.sprite_frames.get_animation_speed(anim)
	else:
		d.caida = 0.35
	z.add_child(d)


func _process(delta: float) -> void:
	t += delta
	var tg := t - caida   # desde que tocó el suelo (negativo: aún cae)
	if (tg >= 0.0 and sonado == 0) or (tg >= COMIDO and sonado == 1):
		Sonido.tocar("siseo")
		sonado += 1
	var luz: Node = zombi.get_node_or_null("LuzAcido")
	if tg < DESHECHO:
		var comido := clampf(tg / COMIDO, 0.0, 1.0)
		var deshecho := clampf((tg - COMIDO) / (DESHECHO - COMIDO), 0.0, 1.0)
		pintar_acido(comido, deshecho)
		restos.modulate.a = deshecho
		if luz:
			luz.fuerza = 0.55 * (1.0 - deshecho)
		if tg >= 0.0:
			vapor(delta, 24.0 if deshecho > 0.0 else 14.0)
	else:
		# ya no queda nada: el charco y los huesos, que se van secando
		pintar_acido(0.0, 0.0, 0.0)
		sprite.hide()
		if luz:
			luz.queue_free()
		restos.modulate = Color(1, 1, 1, 1).lerp(Color(0.72, 0.72, 0.62, 0.8), clampf((tg - DESHECHO) / SECA, 0.0, 1.0))
		if tg >= DESHECHO + SECA:
			set_process(false)
	queue_redraw()


# El ácido de su shader (Zombi.quemaduras, con las manchas del todo) y lo que se lo come
func pintar_acido(comido: float, deshecho: float, acido := 1.0) -> void:
	Zombi.quemaduras(sprite, 0.0, acido, t)
	var m := sprite.material as ShaderMaterial
	m.set_shader_parameter("comido", comido)
	m.set_shader_parameter("deshecho", deshecho)


# Bolitas de vapor verde que salen de los píxeles de su cuerpo ("cuantas" por segundo)
func vapor(delta: float, cuantas: float) -> void:
	var n := cuantas * delta
	while n > 0.0:
		if n < 1.0 and randf() > n:
			break
		n -= 1.0
		var p: Vector2 = puntos.pick_random()[0] if not puntos.is_empty() else Vector2(0, -10)
		Particulas.soltar(zombi, zombi.global_position + p + Vector2(randf_range(-4, 4), 0),
			Vector2(randf_range(-12, 12), randf_range(-70, -35)), VAPOR[randi() % 2], randf_range(2.0, 4.0),
			randf_range(0.4, 0.8))


# Tres columnas de vaho que suben del cuerpo mientras se deshace (las del humo de quemado.gd, más claras y bajas)
func _draw() -> void:
	var tg := t - caida
	if tg < 0.0 or tg >= DESHECHO + 0.8:
		return
	var queda := minf(1.0, (DESHECHO + 0.8 - tg) / 0.8)   # se apaga al final
	var reloj := Time.get_ticks_msec() / 1000.0
	for i in mini(3, puntos.size()):
		var p: Vector2 = puntos[i][0]
		var fase: float = puntos[i][1]
		for k in 6:
			var c := fmod(reloj * 0.8 + fase + k / 6.0, 1.0)   # 0 = sale, 1 = se deshace
			var lado := 2.0 * (2.0 + c * 4.0)
			var color: Color = VAHO[0] if c < 0.35 else VAHO[1]
			color.a = (1.0 - c) * 0.45 * queda
			var centro := p + Vector2(sin(c * 6.0 + fase) * 6.0, -c * 50.0)
			draw_rect(Rect2(encajar(centro - Vector2(lado, lado) / 2.0), Vector2(lado, lado)), color)


# El charco que deja: verde sucio, más oscuro en el centro, con alguna burbuja clara (no hace daño)
func color_suelo(d: float) -> Color:
	if randf() < 0.06:
		return Color8(150, 210, 70, 190)   # burbuja
	elif d < 0.45:
		return Color8(38, 48, 22, 225)
	elif d < 0.75:
		return Color8(66, 92, 34, 175)
	return Color8(98, 130, 48, 100)
