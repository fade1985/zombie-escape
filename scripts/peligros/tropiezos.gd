# Las cosas tiradas por el suelo con las que se tropieza (peligros.gd, TROPIEZOS): las mancuernas del gimnasio del
# Gymbro. Se reparten al generar la planta (Peligros.del_gymbro) y aquí se dibujan y se vigilan: si los pies de
# Johnny pasan por encima de una (sin rodar), se cae y tarda en levantarse (johnny.gd, caer), y la cosa sale rodando
# hacia donde iba él hasta que se para o choca con una pared o un mueble. Dónde se queda se apunta en el sitio: al
# volver, sigue ahí. A los zombis y al jefe no les pasa nada.
# Cada cosa tiene su forma ("mancuerna": el mismo dibujo que las pesas que lanza el Gymbro, pesa.gd). Para otra
# (los cubos de la portera...), basta con darle su tamaño en caja() y su dibujo en _draw().
extends Node2D

const RUEDA_T := 0.5      # lo que tarda en pararse la cosa que sale rodando
const PIES := 14.0        # los pies de Johnny, por debajo de su centro (donde apoya: su sombra)

var datos: Dictionary
var mapa: Node
var rodando := {}         # cosa que sale rodando (su índice) -> {desde, hasta, t}


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Tropiezos"
	z_index = -1   # en el suelo, como los charcos: los personajes pasan por encima
	light_mask = Luz.CAPA_SUELO   # la alumbra la linterna de Johnny, como al suelo


func _physics_process(delta: float) -> void:
	for i in rodando.keys():
		var r: Dictionary = rodando[i]
		r.t += delta
		var k := minf(1.0, r.t / RUEDA_T)
		# frena poco a poco, en píxeles enteros del dibujo
		datos.cosas[i].pos = (r.desde.lerp(r.hasta, 1.0 - (1.0 - k) * (1.0 - k)) / 2.0).round() * 2.0
		if k >= 1.0:
			rodando.erase(i)
		queue_redraw()
	var johnny := get_tree().get_first_node_in_group("jugador")
	if not johnny or not johnny.vivo:
		return
	if mapa.zona_en(johnny.global_position) == datos.sala:
		Peligros.avisar(self, datos, "Cuidado con las mancuernas del suelo: si piso una, me la pego")
	var pies: Vector2 = johnny.global_position + Vector2(0, PIES)
	for i in datos.cosas.size():
		if rodando.has(i) or not caja(datos.cosas[i]).grow(Peligros.TROPIEZOS.pie).has_point(pies):
			continue
		var iba: Vector2 = johnny.velocity
		if johnny.caer(Peligros.TROPIEZOS.caido):
			rodar(i, iba if iba.length() > 10.0 else datos.cosas[i].pos - pies)
		break


# Lo que ocupa una cosa en el suelo (la mancuerna: 14 × 8 píxeles del dibujo, tumbada a lo ancho o a lo largo)
func caja(c: Dictionary) -> Rect2:
	var tam := Vector2(28, 16)
	if absf(c.giro) > 0.1:
		tam = Vector2(tam.y, tam.x)
	return Rect2(c.pos - tam / 2.0, tam)


# La cosa del tropiezo sale rodando hacia donde iba Johnny (más lejos cuanto más rápido iba), hasta donde pueda
# llegar sin meterse en una pared o en un mueble
func rodar(i: int, hacia: Vector2) -> void:
	var desde: Vector2 = datos.cosas[i].pos
	var dir := hacia.normalized() if hacia != Vector2.ZERO else Vector2.RIGHT
	var largo: float = Peligros.TROPIEZOS.rueda * clampf(hacia.length() / 220.0, 0.5, 1.0)
	var hasta := desde
	var paso := 4.0
	while paso <= largo and cabe(desde + dir * paso):
		hasta = desde + dir * paso
		paso += 4.0
	rodando[i] = {"desde": desde, "hasta": hasta, "t": 0.0}
	for k in 6:
		Particulas.soltar(self, desde, Vector2(randf_range(-60, 60), randf_range(-50, -10)), Color("#8a7a66"), 3, 0.35)


# ¿Cabe ahí una cosa rodando? En el suelo de su sala, sin tocar las paredes ni los muebles
func cabe(p: Vector2) -> bool:
	for d in [Vector2(-14, -10), Vector2(14, -10), Vector2(-14, 10), Vector2(14, 10)]:
		if mapa.zona_en(p + d) != datos.sala:
			return false
	for m in mapa.sitio.muebles:
		if Muebles.hueco(m).grow(14.0).has_point(p):
			return false
	return true


func _draw() -> void:
	for c in datos.cosas:
		var p := to_local(c.pos)
		match c.forma:
			"mancuerna":
				# su sombra en el suelo y la mancuerna tumbada (la misma que lanza el Gymbro)
				draw_set_transform(p + Vector2(0, 5), 0.0, Vector2(1, 0.45))
				draw_circle(Vector2.ZERO, 17.0, Color(0, 0, 0, 0.3))
				Pesa.dibujar(self, p, c.giro)
	draw_set_transform(Vector2.ZERO)
