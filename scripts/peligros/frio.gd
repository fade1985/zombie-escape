# El frío de la cámara frigorífica (peligros.gd): toda la cámara. A quien esté dentro (Johnny y los zombis
# despiertos) le pone el estado "frio" (estados.gd): le quita vida poco a poco y le frena, y le sale vaho al
# respirar. A Johnny se le hiela el borde de la pantalla (ui/ambiente.gd) y a los zombis que se quedan un rato
# dentro los congela (zombi.gd: congelar). Por el aire caen copos; la escarcha del suelo y de las paredes ya la
# llevan sus dibujos (ESTILO_TIENDA en mapa.gd).
extends Node2D

const CASILLA := 32
const COPOS := 36

var datos: Dictionary
var mapa: Node
var zona: Rect2           # la cámara, en unidades
var copos: Array = []     # [x, y, velocidad de caída, vaivén, semilla], dentro de la cámara
var t := 0.0


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Frio"   # no-tr (nombre de nodo)
	var sala: Dictionary = m.sitio.apt.salas[d.sala]
	zona = Rect2(sala.c0 * CASILLA, sala.f0 * CASILLA, sala.ancho * CASILLA, sala.fondo * CASILLA)
	z_index = 4                          # los copos caen por delante de los personajes
	light_mask = Luz.capa_sala(d.sala)   # y los alumbra lo que alumbre la cámara (la linterna, dentro)
	for i in COPOS:
		copos.append([randf() * zona.size.x, randf() * alto_copos(), randf_range(16.0, 32.0), randf_range(3.0, 9.0), randf() * TAU])


# Hasta dónde caen: las dos últimas filas las tapa la cara del muro de abajo
func alto_copos() -> float:
	return maxf(zona.size.y - CASILLA * 2, CASILLA)


func dentro(p: Vector2) -> bool:
	return zona.has_point(p)


func _physics_process(delta: float) -> void:
	t += delta
	var frio := {"frio": {"dps": Peligros.FRIO.dps, "frena": Peligros.FRIO.frena, "despues": Peligros.FRIO.despues}}
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny and johnny.vivo and dentro(johnny.global_position):
		johnny.pisar(frio)
		Peligros.avisar(self, datos, Idioma.t("¡Brrr! Qué frío hace en la cámara"))
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi.has_method("pisar") and not zombi.get("dormido") and dentro(zombi.global_position):
			zombi.pisar(frio)
	for c in copos:
		c[1] += c[2] * delta
		if c[1] > alto_copos():
			c[1] -= alto_copos()
			c[0] = randf() * zona.size.x
	# en una cámara aún sin descubrir no se ven (van por encima de la niebla)
	modulate.a = 1.0 - mapa.niebla.get(datos.sala, 0.0)
	queue_redraw()


# Cada copo, un píxel del dibujo (2 unidades) que cae meciéndose
func _draw() -> void:
	for c in copos:
		var x: float = zona.position.x + fposmod(c[0] + sin(t * 1.3 + c[4]) * c[3], zona.size.x)
		var y: float = zona.position.y + c[1]
		draw_rect(Rect2(roundf(x / 2.0) * 2.0, roundf(y / 2.0) * 2.0, 2, 2), Color(0.93, 0.97, 1.0, 0.8 if int(c[4] * 10.0) % 3 else 0.5))
