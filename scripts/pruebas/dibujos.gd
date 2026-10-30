# Lo que cuesta cada tipo de dibujo (-- --captura --dibujos): pinta "n" formas de un tipo en cada fotograma y la prueba
# (probar_dibujos, en prueba_varias.gd) mide lo que tarda el fotograma. En la web, unos tipos (círculos, arcos, polígonos)
# cuestan mucho más que otros (rectángulos, líneas, primitivas): docs/WEB.md
extends Node2D

var tipo := "circulo"
var n := 100


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if tipo == "comparar":
		comparar()
		return
	var rojo := Color(0.9, 0.2, 0.2, 0.6)
	for i in n:
		var p := Vector2(60 + (i % 40) * 22, 80 + (i / 40) * 26)
		match tipo:
			"circulo":
				draw_circle(p, 6.0, rojo)
			"circulo-grande":
				draw_circle(p, 60.0, Color(rojo, 0.05))
			"arco":
				draw_arc(p, 8.0, 0.0, TAU, 24, rojo, 3.0)
			"poligono":
				draw_colored_polygon(PackedVector2Array([p, p + Vector2(10, 4), p + Vector2(4, 12)]), rojo)
			"polilinea":
				draw_polyline(PackedVector2Array([p, p + Vector2(8, 6), p + Vector2(14, 0), p + Vector2(20, 6)]), rojo, 3.0)
			"linea":
				draw_line(p, p + Vector2(14, 8), rojo, 4.0)
			"rect":
				draw_rect(Rect2(p, Vector2(10, 10)), rojo)
			"rect-pequeno":   # como los cuadraditos del fuego y la porquería (4×4), repartidos por la pantalla
				draw_rect(Rect2(Vector2(20 + (i % 150) * 5, 40 + (i / 150) * 5) * 1.0, Vector2(4, 4)), rojo)
			"abanico":   # un círculo hecho con 12 triángulos (primitivas)
				for k in 12:
					var a0 := TAU * k / 12.0
					var a1 := TAU * (k + 1) / 12.0
					draw_primitive(PackedVector2Array([p, p + Vector2.from_angle(a0) * 6.0, p + Vector2.from_angle(a1) * 6.0]),
						PackedColorArray([rojo]), PackedVector2Array())
			"anillo":   # un arco hecho con 24 cuadriláteros (primitivas)
				for k in 24:
					var a0 := TAU * k / 24.0
					var a1 := TAU * (k + 1) / 24.0
					var d0 := Vector2.from_angle(a0)
					var d1 := Vector2.from_angle(a1)
					draw_primitive(PackedVector2Array([p + d0 * 6.5, p + d0 * 9.5, p + d1 * 9.5, p + d1 * 6.5]),
						PackedColorArray([rojo]), PackedVector2Array())
			"primitiva":
				draw_primitive(PackedVector2Array([p, p + Vector2(10, 0), p + Vector2(10, 10), p + Vector2(0, 10)]),
					PackedColorArray([rojo]), PackedVector2Array())


# ── Comparar con las de CanvasItem (--formas) ──
# Pinta las mismas formas con las funciones de siempre (nuevo = false) y con las de Formas (nuevo = true): la prueba
# (probar_formas) saca una foto de cada una y las compara píxel a píxel

var nuevo := false


func disco(p: Vector2, r: float, color: Color) -> void:
	if nuevo:
		Formas.disco(self, p, r, color)
	else:
		draw_circle(p, r, color)


func arco(p: Vector2, r: float, a: float, b: float, pasos: int, color: Color, ancho: float) -> void:
	if nuevo:
		Formas.arco(self, p, r, a, b, pasos, color, ancho)
	else:
		draw_arc(p, r, a, b, pasos, color, ancho)


func poligono(puntos: PackedVector2Array, color: Color) -> void:
	if nuevo:
		Formas.poligono(self, puntos, color)
	else:
		draw_colored_polygon(puntos, color)


func polilinea(puntos: PackedVector2Array, color: Color, ancho: float) -> void:
	if nuevo:
		Formas.polilinea(self, puntos, color, ancho)
	else:
		draw_polyline(puntos, color, ancho)


func comparar() -> void:
	draw_rect(Rect2(0, 0, 640, 400), Color("#6b5a48"))   # el suelo, para que se vea lo translúcido
	for i in 4:   # círculos opacos pequeños, de 1 a 9
		disco(Vector2(30 + i * 30, 30), [1.0, 3.0, 6.0, 9.0][i], Color("#e0303a"))
	disco(Vector2(170, 40), 14.0, Color(1, 1, 1, 0.5))        # translúcidos
	disco(Vector2(230, 50), 30.0, Color(0.1, 0.1, 0.9, 0.3))
	disco(Vector2(110, 130), 60.0, Color(1, 0.4, 0.1, 0.25))   # grande
	arco(Vector2(280, 130), 40.0, 0.0, TAU, 48, Color(1, 1, 0, 0.7), 4.0)   # anillos
	arco(Vector2(280, 130), 30.0, 0.0, TAU, 32, Color(0, 1, 1, 0.5), 10.0)
	arco(Vector2(380, 130), 40.0, PI * 1.05, PI * 1.55, 16, Color(1, 1, 1, 0.8), 5.0)   # un trozo
	arco(Vector2(380, 130), 20.0, -PI / 2.0, 0.6, 12, Color("#ff5d73"), 3.0)
	poligono(PackedVector2Array([Vector2(20, 230), Vector2(60, 250), Vector2(30, 280)]), Color(0.9, 0.9, 0.2))   # triángulo
	poligono(PackedVector2Array([Vector2(90, 230), Vector2(150, 230), Vector2(140, 280), Vector2(100, 280)]), Color(0.2, 0.9, 0.5, 0.6))
	var estrella := PackedVector2Array()
	for k in 10:   # una estrella (no convexa)
		estrella.append(Vector2(210, 255) + Vector2.from_angle(TAU * k / 10.0 - PI / 2.0) * (26.0 if k % 2 == 0 else 11.0))
	poligono(estrella, Color("#ffd23f"))
	var rayo := PackedVector2Array([Vector2(280, 230), Vector2(300, 260), Vector2(310, 235), Vector2(335, 275), Vector2(350, 240)])
	polilinea(rayo, Color(0.7, 0.9, 1.0, 0.9), 3.0)
	var rayo2 := PackedVector2Array()
	for q in rayo:
		rayo2.append(q + Vector2(0, 50))
	polilinea(rayo2, Color(1, 0.8, 0.3, 0.6), 8.0)
	polilinea(PackedVector2Array([Vector2(400, 230), Vector2(480, 230), Vector2(480, 300)]), Color.WHITE, 6.0)
	polilinea(PackedVector2Array([Vector2(520, 230), Vector2(600, 260)]), Color("#ff5d73"), 12.0)
