# La cuenta atrás de arriba de la pantalla (M64), la misma para las cuatro: la horda del rescate (supervivientes.gd),
# la barricada del ferretero (barricada.gd), la avería del electricista (averia.gd) y la alarma de la joyería
# (joyeria.gd). Para que pegue con el HUD de abajo, la barra va en el marco de metal de la barra de vida
# (barra-vida.png, al mismo tamaño: ×1,5) y se llena como la sangre, con su brillo arriba y su sombra abajo. Encima,
# el texto con su contorno, sin caja. Los últimos diez segundos, el número en grande y latiendo.
class_name CuentaAtras

const MARCO := preload("res://assets/ui/barra-vida.png")
const ANCHO := 236.0      # el dibujo de la barra (como en hud.gd)
const ALTO := 26.0
const HUECO := Rect2(0.046 * ANCHO, 0.28 * ALTO, 0.908 * ANCHO, 0.44 * ALTO)
const ESCALA := 1.5       # la del HUD, para que se vea igual que la barra de vida
const ARRIBA := 30.0      # dónde empieza la barra (el texto va justo encima)


# "lleno": lo hecho, de 0 a 1. "relleno": el color de la barra (el que toque: parpadeando si algo va mal).
# "falta": los segundos que quedan; "latido", de 0 a 1, hace latir el número grande, que solo sale si "numero"
static func dibujar(capa: Control, texto: String, color_texto: Color, lleno: float, relleno: Color, falta: int,
		latido: float, numero: bool) -> void:
	var letra := Tema.FUENTE
	var tam := capa.size
	var x := roundf((tam.x - ANCHO * ESCALA) / 2.0)
	capa.draw_set_transform(Vector2(x, ARRIBA), 0.0, Vector2(ESCALA, ESCALA))
	capa.draw_rect(HUECO, Color("#1a1620"))
	var hecho := HUECO
	hecho.size.x *= clampf(lleno, 0.0, 1.0)
	capa.draw_rect(hecho, relleno)
	capa.draw_rect(Rect2(hecho.position, Vector2(hecho.size.x, hecho.size.y * 0.45)), relleno.lightened(0.3))
	capa.draw_rect(Rect2(hecho.position + Vector2(0, hecho.size.y * 0.8), Vector2(hecho.size.x, hecho.size.y * 0.2)),
		relleno.darkened(0.35))
	capa.draw_texture_rect(MARCO, Rect2(0, 0, ANCHO, ALTO), false)
	capa.draw_set_transform(Vector2.ZERO)
	capa.draw_string_outline(letra, Vector2(0, ARRIBA - 4), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, 4, Tema.LINEA)
	capa.draw_string(letra, Vector2(0, ARRIBA - 4), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, color_texto)
	if numero and falta <= 10:
		var grande := 64 if latido < 0.5 else 72
		capa.draw_string_outline(letra, Vector2(0, 150), str(falta), HORIZONTAL_ALIGNMENT_CENTER, tam.x, grande, 10, Tema.LINEA)
		capa.draw_string(letra, Vector2(0, 150), str(falta), HORIZONTAL_ALIGNMENT_CENTER, tam.x, grande, Tema.AMARILLO)
