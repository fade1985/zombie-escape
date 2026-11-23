# La ola del cocinero (fase 2, «servicio de urgencia»; docs/JEFES_CENTRO.md): vuelca la olla y una ola de guiso
# hirviendo cruza la sala de pared a pared. Es el barrido del antidisturbios (barrido_electrico.gd: cómo avanza, su
# hueco y cuándo da) con otro dibujo: una ola verde del color del guiso (hasta el 24 nov era aceite dorado), con el
# frente que ondula, burbujas, tropezones y gotas, y el hueco marcado con dos montones de espuma. Solo se pasa por el hueco.
# Se crea con OlaAceite.new(); se le ponen "dir", "olas" y "dueno" y se mete en la escena donde está la olla.
class_name OlaAceite
extends BarridoElectrico

const ANCHO_OLA := 22.0   # medio grueso de la franja de guiso


func _init() -> void:
	velocidad = 150.0
	dano = 16
	sonido_sale = "chof"
	sonido_da = "chisporroteo"


# Los colores del guiso (los de la olla, assets/sources/salas/centro/olla-gigante.png), de oscuro a claro
const GUISO := [Color("#2c4a12"), Color("#4f7a1a"), Color("#77a826"), Color("#a3cc3c"), Color("#cbe668"), Color("#eef8b0")]
const HUESO := Color("#eadcc4")
const CARNE := Color("#a8323a")
const PASO := 4.0         # el ancho de cada tira con la que se pinta la ola (2 píxeles del dibujo)


# Una ola de guiso hirviendo (24 nov, el dueño: que parezca un líquido y del color de lo que cae de la olla): por cada
# tira a lo ancho, el frente ondula (dos ondas que se cruzan), detrás va el cuerpo verde con su cresta clara y una
# película que se queda mojando el suelo; por encima, burbujas que crecen y revientan, tropezones (huesos y carne) que
# flotan y, por delante, gotas que saltan
func pintar_ola(d: float, hueco: float) -> void:
	var base := dir * d
	for tramo in [[desde, hueco - HUECO], [hueco + HUECO, hasta]]:
		var a: float = maxf(tramo[0], desde)
		var b: float = minf(tramo[1], hasta)
		if b - a < 4.0:
			continue
		var x := floorf(a / PASO) * PASO
		while x < b:
			var ancho := minf(PASO, b - x)
			# el frente: cuánto va adelantada esta tira (las puntas del tramo, redondeadas, como una lengua de líquido)
			var punta := minf(1.0, minf(x - a, b - x) / 40.0)
			var f := (6.0 * sin(x * 0.045 + t * 7.0) + 3.0 * sin(x * 0.11 - t * 11.0)) * punta - (1.0 - punta) * 18.0
			var grueso := ANCHO_OLA * 1.6 + 5.0 * sin(x * 0.07 + t * 5.0)
			# la película de detrás, cada vez más fina
			banda(base, x, ancho, f - grueso * 3.2, f - grueso * 2.1, Color(GUISO[1], 0.22))
			banda(base, x, ancho, f - grueso * 2.1, f - grueso, Color(GUISO[1], 0.45))
			# el cuerpo, la parte clara de encima, la cresta y el canto oscuro del frente
			banda(base, x, ancho, f - grueso, f, GUISO[2])
			banda(base, x, ancho, f - grueso * 0.75, f - grueso * 0.3, GUISO[3])
			banda(base, x, ancho, f - 10.0, f - 4.0, GUISO[4])
			banda(base, x, ancho, f - 2.0, f + 2.0, GUISO[0])
			# un brillo suelto en la cresta, que corre con la onda
			if absi(hash(Vector2i(int(x / PASO), int(t * 8.0)))) % 9 == 0:
				banda(base, x, ancho, f - 8.0, f - 6.0, GUISO[5])
			x += PASO
		cosas(base, a, b)


# Una franja de la ola: la tira que va de "x" a "x + ancho" a lo ancho, entre "de" y "a" hacia delante
func banda(base: Vector2, x: float, ancho: float, de: float, a: float, c: Color) -> void:
	var p := ((base + lado * x + dir * de) / 2.0).floor() * 2.0
	var q := ((base + lado * (x + ancho) + dir * a) / 2.0).floor() * 2.0
	var r := Rect2(p, Vector2.ZERO).expand(q).abs()
	if r.size.x >= 2.0 and r.size.y >= 2.0:
		draw_rect(r, c)


# Lo que flota y salta en un tramo de la ola: burbujas, tropezones y gotas (cada cosa en su sitio, siempre la misma)
func cosas(base: Vector2, a: float, b: float) -> void:
	var s := floorf(a / 18.0) * 18.0
	while s < b:
		var h := absi(hash(Vector2i(int(s), 7)))
		var x := s + float(h % 14)
		if x > a + 6.0 and x < b - 6.0:
			var atras := 8.0 + float(h % 28)
			var p: Vector2 = ((base + lado * x - dir * atras) / 2.0).floor() * 2.0
			match h % 5:
				0, 1:
					# una burbuja que crece y revienta (cada una a su ritmo)
					var k := fmod(t * 1.6 + float(h % 100) / 100.0, 1.0)
					var r := 2.0 + floorf(k * 4.0) * 2.0
					if k < 0.85:
						draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), GUISO[4])
						draw_rect(Rect2(p - Vector2(r, r) + Vector2(2, 2), Vector2(r, r) * 2.0 - Vector2(4, 4)), GUISO[2])
						draw_rect(Rect2(p - Vector2(r, r) + Vector2(2, 2), Vector2(2, 2)), GUISO[5])
					else:
						for g in 4:   # al reventar, cuatro gotitas
							var o := Vector2.from_angle(g * PI / 2.0 + 0.6) * (r + 4.0)
							draw_rect(Rect2((p + o).floor(), Vector2(2, 2)), GUISO[4])
				2:
					# un hueso que flota, cabeceando
					var cabecea := Vector2(0, 2) * floorf(sin(t * 4.0 + h) + 1.0)
					draw_rect(Rect2(p + cabecea - Vector2(6, 2), Vector2(12, 4)), HUESO)
					draw_rect(Rect2(p + cabecea - Vector2(8, 4), Vector2(4, 4)), HUESO)
					draw_rect(Rect2(p + cabecea + Vector2(4, -4), Vector2(4, 4)), HUESO)
				3:
					# un trozo de carne
					var cabecea := Vector2(0, 2) * floorf(sin(t * 3.0 + h * 0.5) + 1.0)
					draw_rect(Rect2(p + cabecea - Vector2(4, 4), Vector2(8, 8)), CARNE)
					draw_rect(Rect2(p + cabecea - Vector2(4, 4), Vector2(4, 2)), CARNE.lightened(0.3))
				4:
					# una gota que salta por delante del frente y vuelve a caer
					var k := fmod(t * 2.2 + float(h % 100) / 100.0, 1.0)
					var delante := 6.0 + k * 22.0
					var sube := sin(k * PI) * 14.0
					var g: Vector2 = ((base + lado * x + dir * delante) / 2.0).floor() * 2.0 - Vector2(0, floorf(sube / 2.0) * 2.0)
					draw_rect(Rect2(g, Vector2(4, 4)), GUISO[3])
					draw_rect(Rect2(g, Vector2(2, 2)), GUISO[5])
		s += 18.0


# Los bordes del hueco: dos montones de espuma del guiso que burbujean
func postes(base: Vector2, hueco: float) -> void:
	for borde in [hueco - HUECO, hueco + HUECO]:
		if borde < desde or borde > hasta:
			continue
		var p: Vector2 = ((base + lado * borde) / 2.0).floor() * 2.0
		var late := 1.0 + sin(t * 16.0 + borde) * 0.15
		Formas.disco(self, p, 14.0 * late, Color(GUISO[3], 0.6))
		Formas.disco(self, p, 9.0 * late, GUISO[4])
		Formas.disco(self, p - Vector2(2, 2), 4.0 * late, GUISO[5])
