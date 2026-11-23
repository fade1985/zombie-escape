# Los fogones en damero del cocinero (minijefe del centro comercial; docs/JEFES_CENTRO.md): el suelo de su cocina,
# partido en cuadros grandes (de 4×4 casillas) como un tablero de ajedrez, se pone al rojo: primero los cuadros
# "blancos" (avisan: se van encendiendo de naranja y palpitan) y queman un momento (en cada uno, el efecto
# "fogon-llamas" de efecto_suelo.gd); luego los "negros". Para no
# quemarse hay que ir pasando de un cuadro al de al lado. Si Johnny está en uno mientras quema, le quita lo suyo (una vez
# por tanda; esquivando, también: hay que salir del cuadro). Llega de pared a pared (los muebles no lo paran: queda
# por debajo de ellos). El aviso se dibuja con código, a cuadraditos de 2, y se borra solo al acabar.
# Se crea con FogonesDamero.new(); se le pone "dueno" y "aviso" (lo que avisa cada tanda) y se mete en la escena
# en el sitio del jefe.
class_name FogonesDamero
extends Node2D

const CELDA := 128.0       # lo que mide cada cuadro (4×4 casillas; 24 nov: con 2×2 casi no cabía Johnny)
const QUEMA := 0.7         # lo que quema cada tanda
const DANO := 12
const MAX_LADO := 1400.0

var dueno: Node2D = null
var aviso := 1.1
var t := 0.0
var caja := Rect2()        # la sala, de pared a pared (en coordenadas del suelo, ya en la cuadrícula de cuadros)
var sala := Rect2()        # la sala tal cual, sin ajustar a los cuadros (el aviso no se pinta fuera, sobre las paredes)
var dio := [false, false]  # si ya le ha dado a Johnny cada tanda
var prendio := [false, false]   # si ya han salido las llamas de cada tanda


func _ready() -> void:
	z_index = -1   # en el suelo, por debajo de todos
	var izq := hasta_pared(Vector2.LEFT)
	var der := hasta_pared(Vector2.RIGHT)
	var arr := hasta_pared(Vector2.UP)
	var aba := hasta_pared(Vector2.DOWN)
	# la cuadrícula, pegada a la de las casillas del suelo (desde el origen del mapa)
	var x0 := floorf((global_position.x - izq) / CELDA) * CELDA
	var y0 := floorf((global_position.y - arr) / CELDA) * CELDA
	var x1 := ceilf((global_position.x + der) / CELDA) * CELDA
	var y1 := ceilf((global_position.y + aba) / CELDA) * CELDA
	caja = Rect2(x0, y0, x1 - x0, y1 - y0)
	sala = Rect2(global_position.x - izq, global_position.y - arr, izq + der, arr + aba)
	Sonido.tocar("chisporroteo")
	EfectoSuelo.precalentar(get_parent(), "fogon-llamas")


# Lo que hay desde aquí hasta la pared (los muros del mapa; los muebles no lo paran)
func hasta_pared(hacia: Vector2) -> float:
	var espacio := get_world_2d().direct_space_state
	var rayo := PhysicsRayQueryParameters2D.create(global_position, global_position + hacia * MAX_LADO, 1)
	for i in 12:
		var choque := espacio.intersect_ray(rayo)
		if choque.is_empty():
			return MAX_LADO * 0.5
		if (choque.collider as Node).is_in_group("muros"):
			return global_position.distance_to(choque.position)
		rayo.exclude = rayo.exclude + [choque.rid]
	return MAX_LADO * 0.5


# Cuándo empieza cada tanda a avisar y a quemar
func empieza(tanda: int) -> float:
	return tanda * (aviso + QUEMA)


func _physics_process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t > empieza(2):
		queue_free()
		return
	var johnny := get_tree().get_first_node_in_group("jugador")
	for tanda in 2:
		if not prendio[tanda] and t >= empieza(tanda) + aviso:
			prendio[tanda] = true
			prender(tanda)
	for tanda in 2:
		var q := t - empieza(tanda) - aviso
		if q < 0.0 or q > QUEMA or dio[tanda] or johnny == null or not johnny.vivo:
			continue
		if de_tanda(johnny.global_position) == tanda and caja.has_point(johnny.global_position):
			dio[tanda] = true
			if johnny.esquiva_t > 0.0:
				johnny.invulnerable = 0.0   # (esquivando dentro del cuadro también quema: hay que salir)
			johnny.recibir_dano(DANO, dueno)
			Sonido.tocar("chisporroteo")
	# las chispitas que saltan de los cuadros que están a punto de prender
	for tanda in 2:
		var e := t - empieza(tanda)
		if e >= aviso * 0.4 and e < aviso and randf() < 0.5:
			var p := Vector2(randf_range(caja.position.x, caja.end.x), randf_range(caja.position.y, caja.end.y))
			if de_tanda(p) == tanda:
				Particulas.soltar(get_parent(), p, Vector2(randf_range(-10, 10), randf_range(-70, -40)),
					Color("#ffd23f") if randf() < 0.5 else Color("#ff7a2a"), randf_range(2, 4), 0.3)


# Salen las llamas en todos los cuadros de una tanda (el efecto de pixelfx, uno en el centro de cada cuadro)
func prender(tanda: int) -> void:
	var y := caja.position.y
	while y < caja.end.y:
		var x := caja.position.x
		while x < caja.end.x:
			if de_tanda(Vector2(x + 1, y + 1)) == tanda:
				EfectoSuelo.soltar(get_parent(), "fogon-llamas", Vector2(x, y) + Vector2(CELDA, CELDA) / 2.0)
			x += CELDA
		y += CELDA


# De qué tanda es el cuadro donde cae "p" (0, los "blancos"; 1, los "negros")
func de_tanda(p: Vector2) -> int:
	return (floori(p.x / CELDA) + floori(p.y / CELDA)) % 2


func _draw() -> void:
	draw_set_transform(-global_position)   # (dibuja en las coordenadas del suelo, como la cuadrícula)
	for tanda in 2:
		var e := t - empieza(tanda)
		if e < 0.0:
			continue
		if e >= aviso:
			continue   # (quemando: las llamas son el efecto de pixelfx)
		var k := e / aviso
		var y := caja.position.y
		while y < caja.end.y:
			var x := caja.position.x
			while x < caja.end.x:
				if de_tanda(Vector2(x + 1, y + 1)) == tanda:
					var r := Rect2(x, y, CELDA, CELDA).intersection(sala)
					pintar_aviso(r, k)
				x += CELDA
			y += CELDA


# Avisando: el borde naranja (palpita cada vez más deprisa) y el cuadro que se va poniendo rojo por dentro, del borde
# hacia el centro, como una barra que se llena
func pintar_aviso(r: Rect2, k: float) -> void:
	var late := 0.5 + 0.5 * sin(t * (10.0 + k * 22.0))
	draw_rect(r.grow(-2), Color(1.0, 0.45, 0.15, 0.10 + 0.20 * k))
	var dentro := r.grow(-2.0 - (1.0 - k) * (minf(r.size.x, r.size.y) / 2.0 - 4.0))
	draw_rect(Rect2((dentro.position / 2.0).floor() * 2.0, (dentro.size / 2.0).floor() * 2.0), Color(1.0, 0.35, 0.1, 0.18 + 0.12 * k))
	var borde := Color(1.0, 0.55 + 0.3 * late, 0.2, 0.55 + 0.35 * late)
	draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 2)), borde)
	draw_rect(Rect2(r.position + Vector2(2, r.size.y - 4), Vector2(r.size.x - 4, 2)), borde)
	draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(2, r.size.y - 4)), borde)
	draw_rect(Rect2(r.position + Vector2(r.size.x - 4, 2), Vector2(2, r.size.y - 4)), borde)
	if k > 0.85 and int(t * 30.0) % 2 == 0:
		draw_rect(r.grow(-2), Color(1, 0.95, 0.8, 0.25))   # (el destello del final)
