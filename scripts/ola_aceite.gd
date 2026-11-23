# La ola de aceite del cocinero (fase 2, «servicio de urgencia»; docs/JEFES_CENTRO.md): vuelca la olla y una ola de
# aceite hirviendo cruza la sala de pared a pared. Es el barrido del antidisturbios (barrido_electrico.gd: cómo avanza,
# su hueco y cuándo da) con otro dibujo: una franja de aceite dorado que burbujea y humea, y el hueco marcado con dos
# charquitos de espuma. Solo se pasa por el hueco.
# Se crea con OlaAceite.new(); se le ponen "dir", "olas" y "dueno" y se mete en la escena donde está la olla.
class_name OlaAceite
extends BarridoElectrico

const ANCHO_OLA := 22.0   # medio grueso de la franja de aceite


func _init() -> void:
	velocidad = 150.0
	dano = 16
	sonido_sale = "chof"
	sonido_da = "chisporroteo"


# Una ola: la franja de aceite (por delante, la cresta clara; por detrás, lo que va dejando, más oscuro) con burbujas
# que revientan y algo de humo
func pintar_ola(d: float, hueco: float) -> void:
	var base := dir * d
	var cuadro := int(t * 12.0)
	for tramo in [[desde, hueco - HUECO], [hueco + HUECO, hasta]]:
		var a: float = maxf(tramo[0], desde)
		var b: float = minf(tramo[1], hasta)
		if b - a < 4.0:
			continue
		# lo de detrás (el aceite que se va enfriando), la franja y la cresta
		draw_rect(Rect2(base + lado * a - dir * ANCHO_OLA * 2.5, Vector2.ZERO).expand(base + lado * b - dir * ANCHO_OLA).abs(),
			Color("#8a5a18", 0.35))
		draw_rect(Rect2(base + lado * a - dir * ANCHO_OLA, Vector2.ZERO).expand(base + lado * b + dir * ANCHO_OLA * 0.4).abs(),
			Color("#c88a20", 0.9))
		draw_rect(Rect2(base + lado * a + dir * ANCHO_OLA * 0.1, Vector2.ZERO).expand(base + lado * b + dir * ANCHO_OLA * 0.6).abs(),
			Color("#f0c850"))
		draw_rect(Rect2(base + lado * a + dir * ANCHO_OLA * 0.5, Vector2.ZERO).expand(base + lado * b + dir * ANCHO_OLA * 0.7).abs(),
			Color("#fff0b0"))
		# burbujas: cada pocos píxeles, una que crece y revienta
		var s := a
		while s < b:
			var h := absi(hash(Vector2i(int(s), cuadro / 3)))
			if h % 3 == 0:
				var p: Vector2 = ((base + lado * s - dir * float(h % 30)) / 2.0).floor() * 2.0
				var r := 2.0 + float((cuadro + h) % 4)
				draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), Color("#ffe9a0", 0.8))
				draw_rect(Rect2(p - Vector2(r, r) + Vector2(2, 2), Vector2(r, r) * 2.0 - Vector2(4, 4)), Color("#d89a30"))
			s += 14.0


# Los bordes del hueco: dos montoncitos de espuma blanca que burbujean
func postes(base: Vector2, hueco: float) -> void:
	for borde in [hueco - HUECO, hueco + HUECO]:
		if borde < desde or borde > hasta:
			continue
		var p: Vector2 = ((base + lado * borde) / 2.0).floor() * 2.0
		var late := 1.0 + sin(t * 16.0 + borde) * 0.15
		Formas.disco(self, p, 12.0 * late, Color("#fff4d0", 0.5))
		Formas.disco(self, p, 7.0 * late, Color("#ffffff"))
