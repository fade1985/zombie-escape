# Una persona dibujada con formas, como drawHuman de src/draw.js en el juego JS: pies que andan, cuerpo con
# camisa y pantalón, manos, cabeza con pelo, ojos que miran hacia donde va, y gorra o casco. La usan los
# supervivientes (aliado.gd), que en el JS no tenían pixel art. Si lleva arma, se dibuja en su mano
# (drawHeld de src/weapons.js), apuntando hacia "apunte".
# Las medidas son las del JS (unidades del mundo) y se multiplican por "s" (su escala). El origen es su
# centro en el suelo (su círculo de choque); los pies quedan un poco más abajo.
class_name Persona
extends Node2D

const LINEA := Color("#1d1b2c")   # el contorno "de dibujo animado"
const SOMBRA := Color(0.024, 0.016, 0.055)

var look := {}             # colores: skin, hair, shirt, pants, shoes; hat {kind, color}; cross
var s := 0.82              # su escala (la de los compañeros en el JS)
var mira := Vector2.DOWN   # hacia dónde mira
var mueve := Vector2.ZERO  # hacia dónde anda
var andando := 0.0         # de 0 (quieto) a 1 (andando a buen paso)
var paso := 0.0            # la fase de la animación de andar
var blanco := false        # todo blanco (le acaban de dar)
var arma := ""             # "pistola", "rifle" o nada
var apunte := PI / 2.0     # hacia dónde lleva el arma
var retroceso := 0.0       # de 1 (acaba de disparar) a 0
var fogonazo := false


func _process(_delta: float) -> void:
	queue_redraw()


func col(c: Color) -> Color:
	return Color.WHITE if blanco else c


func _draw() -> void:
	var detras := arma != "" and sin(apunte) < -0.3   # apuntando hacia arriba, el arma va detrás del cuerpo
	if detras:
		dibujar_arma()
	dibujar_persona()
	if arma != "" and not detras:
		dibujar_arma()


func dibujar_persona() -> void:
	var lw := 3.0 * s
	var lx := mira.x
	var ly := mira.y
	var paso_k := sin(paso) * andando
	var bote := absf(sin(paso)) * andando * 2.0 * s
	var m := mueve if mueve.length() > 0.01 else mira

	# sombra
	var ancho := 30.0 * s
	var alto := maxf(6.0, ancho * 0.38)
	rellenar(elipse(Vector2(0, 15 * s), ancho / 2, alto / 2), Color(SOMBRA, 0.4))
	rellenar(elipse(Vector2(0, 15 * s), ancho * 0.31, alto * 0.3), Color(SOMBRA, 0.3))

	# pies (se adelantan y atrasan al andar)
	var fx := m.x * paso_k * 4 * s
	var fy := m.y * paso_k * 3 * s
	for lado: int in [-1, 1]:
		forma(elipse(Vector2(lado * 6 * s + lado * fx, 13 * s + lado * fy), 5.5 * s, 4 * s), col(look.get("shoes", Color("#3b3550"))), lw)

	var by := 2 * s - bote   # el centro del cuerpo
	var de_espaldas := ly < -0.45
	if de_espaldas:
		manos(by, fx, fy, lw)

	# cuerpo: la camisa y, abajo, el pantalón
	var cuerpo := caja_redonda(Rect2(-11 * s, by - 9 * s, 22 * s, 20 * s), 9 * s)
	rellenar(cuerpo, col(look.shirt))
	if not blanco:
		recortado(cuerpo, rect(Rect2(-12 * s, by + 4 * s, 24 * s, 10 * s)), look.get("pants", Color("#3d4a7a")))
	borde(cuerpo, lw)
	# cruz roja en el pecho (la médica)
	if look.get("cross", false) and not blanco and not de_espaldas:
		draw_rect(Rect2(-1.6 * s, by + 1 * s, 3.2 * s, 8 * s), Color("#ff5d73"))
		draw_rect(Rect2(-4 * s, by + 3.4 * s, 8 * s, 3.2 * s), Color("#ff5d73"))
	if not de_espaldas:
		manos(by, fx, fy, lw)

	# cabeza
	var r := 15.0 * s
	var cabeza_c := Vector2(0, by - 15 * s)
	var cabeza := elipse(cabeza_c, r, r)
	rellenar(cabeza, col(look.skin))
	if not blanco:
		var pelo: Color = look.get("hair", Color("#6b3e26"))
		# flequillo: casquete arriba; nuca: se va al lado contrario de la mirada (de espaldas tapa la cabeza)
		recortado(cabeza, elipse(cabeza_c + Vector2(-lx * 3 * s, -9 * s), 17 * s, 11 * s), pelo)
		recortado(cabeza, elipse(cabeza_c + Vector2(-lx * 11 * s, -6 * s - ly * 8 * s), 15 * s, 15 * s), pelo)
		recortado(cabeza, elipse(cabeza_c + Vector2(2 * s, 12 * s), r, r), Color(0, 0, 0, 0.1))   # sombreado
		rellenar(elipse(cabeza_c + Vector2(-6 * s, -8 * s), 4 * s, 2.4 * s, -0.7), Color(1, 1, 1, 0.4))   # brillo
	borde(cabeza, lw)

	# gorra de policía o casco militar
	var gorro: Dictionary = look.get("hat", {})
	if not gorro.is_empty() and not blanco:
		if gorro.kind == "helmet":
			forma(elipse(cabeza_c + Vector2(0, -4 * s), 17.5 * s, 14 * s, 0.0, PI * 1.02, PI * 1.98, true), gorro.color, lw)
			for d: Vector2 in [Vector2(-6, -10), Vector2(4, -13), Vector2(8, -6)]:
				rellenar(elipse(cabeza_c + d * s, 2.2 * s, 2.2 * s), Color(0, 0, 0, 0.18))
		else:
			forma(elipse(cabeza_c + Vector2(0, -6 * s), 15.5 * s, 11 * s, 0.0, PI, TAU, true), gorro.color, lw)
			if not de_espaldas:
				# la visera, hacia donde mira
				rellenar(elipse(cabeza_c + Vector2(lx * 8 * s, -5 * s), 11 * s, 4 * s, lx * 0.3, 0.0, PI, true), LINEA)
			rellenar(elipse(cabeza_c + Vector2(0, -12 * s), 2.6 * s, 2.6 * s), Color("#ffd23f"))

	# la cara (de espaldas no se ve)
	if not de_espaldas:
		ojos(cabeza_c + Vector2(lx * 4 * s, 8 * s), r, lx, ly)
		if ly > -0.1 and not blanco:
			for k: int in [-1, 1]:
				rellenar(elipse(cabeza_c + Vector2(lx * 4 * s + k * 9.5 * s, 11.5 * s), 2.8 * s, 1.8 * s), Color(1, 0.47, 0.55, 0.45))


# Las manos, con balanceo opuesto a los pies. La del arma la dibuja el arma
func manos(by: float, fx: float, fy: float, lw: float) -> void:
	for lado: int in [-1, 1]:
		if arma != "" and lado == 1:
			continue
		var p := Vector2(lado * 13 * s - lado * fx * 0.7, by + 3 * s - lado * fy * 0.7)
		forma(elipse(p, 4.5 * s, 4.5 * s), col(look.skin), lw)


# Los ojos (eyes de src/draw.js): blancos con su contorno y la pupila mirando hacia donde mira
func ojos(c: Vector2, r: float, lx: float, ly: float) -> void:
	var ex := r * 0.34
	var er := r * 0.27
	var cy := c.y - r * 0.15 + ly * r * 0.1
	var ox := lx * r * 0.16
	for lado: int in [-1, 1]:
		var cx := c.x + lado * ex + ox
		forma(elipse(Vector2(cx, cy), er * 0.85, er), Color.WHITE, maxf(2.0, r * 0.09))
		var p := Vector2(cx + lx * er * 0.35, cy + ly * er * 0.4)
		rellenar(elipse(p, er * 0.5, er * 0.5), LINEA)
		rellenar(elipse(p - Vector2(er * 0.18, er * 0.2), er * 0.16, er * 0.16), Color.WHITE)


# El arma en la mano (drawHeld): sale de la mano hacia el apunte, va hacia atrás con el retroceso, no queda boca
# abajo al apuntar a la izquierda y, al disparar, lleva un fogonazo en la boca. Encima, la mano
func dibujar_arma() -> void:
	var mano := Vector2(cos(apunte) * 13, 3 + sin(apunte) * 9) - Vector2.from_angle(apunte) * retroceso * 6
	var voltea := -1.0 if cos(apunte) < 0 else 1.0
	draw_set_transform(mano, apunte, Vector2(s, s * voltea))
	if arma == "rifle":
		forma(caja_redonda(Rect2(-8, -4, 16, 8), 3), Color("#4b5320"), 3)
		forma(caja_redonda(Rect2(6, -3, 28, 6), 2), Color("#3a3d47"), 3)
		forma(caja_redonda(Rect2(10, 2, 5, 9), 2), Color("#2f3240"), 3)
	else:
		forma(caja_redonda(Rect2(-4, -4, 26, 8), 2), Color("#4a4e5c"), 3)
		forma(caja_redonda(Rect2(-2, 2, 7, 9), 2), Color("#2f3240"), 3)
	if fogonazo:
		var boca := (34.0 if arma == "rifle" else 24.0) + 6.0
		var estrella := PackedVector2Array()
		for i in 10:
			estrella.append(Vector2(boca, 0) + Vector2.from_angle(i / 10.0 * TAU) * (4.0 if i % 2 else 11.0))
		forma(estrella, Color("#ffd23f"), 2, Color("#ff9f1c"))
	draw_set_transform(Vector2.ZERO)
	forma(elipse(mano, 4.5 * s, 4.5 * s), col(look.skin), 3)


# ── Formas ──

# Una elipse (o un trozo, de a0 a a1) girada "giro", como puntos. "cerrar": el trozo se cierra con su cuerda
func elipse(c: Vector2, rx: float, ry: float, giro := 0.0, a0 := 0.0, a1 := TAU, cerrar := false) -> PackedVector2Array:
	var n := 28 if a1 - a0 > PI else 16
	var pts := PackedVector2Array()
	for i in (n + 1 if cerrar else n):
		var a := a0 + (a1 - a0) * i / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(giro))
	return pts


func rect(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


func caja_redonda(r: Rect2, radio: float) -> PackedVector2Array:
	radio = minf(radio, minf(r.size.x, r.size.y) / 2.0)
	var pts := PackedVector2Array()
	var esquinas := [[r.end - Vector2(radio, radio), 0.0], [Vector2(r.position.x + radio, r.end.y - radio), PI / 2.0],
		[r.position + Vector2(radio, radio), PI], [Vector2(r.end.x - radio, r.position.y + radio), PI * 1.5]]
	for e in esquinas:
		for i in 5:
			pts.append(e[0] + Vector2.from_angle(e[1] + PI / 2.0 * i / 4.0) * radio)
	return pts


func rellenar(pts: PackedVector2Array, color: Color) -> void:
	if pts.size() >= 3:
		draw_colored_polygon(pts, color)


func borde(pts: PackedVector2Array, grueso: float, color := LINEA) -> void:
	var cerrado := pts.duplicate()
	cerrado.append(pts[0])
	draw_polyline(cerrado, color, grueso, true)


func forma(pts: PackedVector2Array, color: Color, grueso: float, linea := LINEA) -> void:
	rellenar(pts, color)
	borde(pts, grueso, linea)


# Pinta solo la parte de "pts" que cae dentro de "dentro" (lo que en el JS hacía ctx.clip)
func recortado(dentro: PackedVector2Array, pts: PackedVector2Array, color: Color) -> void:
	for trozo in Geometry2D.intersect_polygons(dentro, pts):
		rellenar(trozo, color)
