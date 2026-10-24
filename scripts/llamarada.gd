# La llamarada del lanzallamas de Johnny (Armas.CREADAS.lanzallamas): mientras se ataca, un chorro de fuego fijo que
# sale de la boca del tubo, estrecho, y se abre en cono hasta su alcance (las paredes y los muebles lo cortan).
# Quema a todos los zombis que pilla dentro, uno detrás de otro: cada TICK les quita su parte del daño por segundo y
# los deja ardiendo, y uno de cada EMPUJA pellizcos (cada medio segundo) los empuja un poco. Solo a los zombis: ni a
# Johnny, ni a los que le acompañan, ni deja fuego en el suelo. Al jefe de bomberos no le hace nada (inmune_fuego).
#
# Va de hija de Johnny. Johnny la mantiene encendida llamando a mantener() en cada paso en que echa fuego (johnny.gd,
# echar_fuego); el paso en que no la llama, se apaga sola. Como la bala, la llama "de verdad" va por el suelo (desde
# debajo de la boca) y se dibuja más arriba: sale a la altura de la boca y va bajando hasta el cuerpo de los zombis.
# El dibujo es provisional (fase A): un cono de cuadraditos que pasa de amarillo a naranja y rojo, con humo al final.
class_name Llamarada
extends Node2D

const TICK := 0.25          # cada cuánto quita vida a los que están dentro
const EMPUJA := 2           # empuja uno de cada tantos pellizcos (cada medio segundo)
const ABRE := 0.2           # cuánto se abre el cono a cada lado (radianes, unos 11°): a 10 casillas, 70 de ancho a cada lado
const BOCA := 6.0           # medio ancho de la llama en la boca
const ALTURA := 50.0        # a qué altura sale de la boca (como la bala)
const ALTURA_CUERPO := 26.0 # y a cuál llega al final
const CRECE := 0.12         # lo que tarda en estirarse hasta su alcance al encenderla (y en encogerse al apagarla)
const EMPUJE := 170.0       # empuje base, como el de las balas
const HUMO := Color(0.16, 0.14, 0.16, 0.7)

var pedida := false         # se ha pedido fuego en este paso (mantener)
var encendida := false
var angulo := 0.0
var alcance := 320.0
var dps := 0.0
var empuje := 0.0
var quema := 1.0
var tope := 0.0             # hasta dónde llega, por el suelo: su alcance o la pared
var largo := 0.0            # lo que se ve ahora (crece al encenderla y se encoge al apagarla)
var tick_t := TICK          # (empieza lleno: el primer pellizco, en cuanto sale)
var ticks := 0
var tiempo := 0.0


func _ready() -> void:
	z_index = 4   # por encima de Johnny y de los zombis, como el bumerán
	var propio := CanvasItemMaterial.new()
	propio.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED   # el fuego luce por sí mismo
	material = propio
	visible = false


# Johnny echa fuego en este paso: "desde", el suelo debajo de la boca; "a", hacia dónde; "w", su arma (arma())
func mantener(desde: Vector2, a: float, w: Dictionary) -> void:
	pedida = true
	global_position = desde
	angulo = a
	alcance = w.alcance
	dps = w.dano
	empuje = w.empuje
	quema = w.get("quema", 1.0)


func _physics_process(delta: float) -> void:
	encendida = pedida
	pedida = false
	tiempo += delta
	if encendida:
		tope = medir()
		largo = minf(largo + alcance / CRECE * delta, tope)
		Sonido.tocar("llamarada")
		# el reloj de los pellizcos solo corre con la llama encendida (soltar y volver a pulsar no quema más deprisa)
		tick_t += delta
		if tick_t >= TICK:
			tick_t -= TICK
			quemar()
	else:
		largo = maxf(0.0, largo - alcance / CRECE * delta)
	visible = largo > 0.0
	queue_redraw()


# Hasta dónde llega la llama por el suelo: su alcance o, si antes hay una pared o un mueble, hasta ahí. Si la boca
# queda al otro lado de una pared (Johnny pegado a ella), nada
func medir() -> float:
	var espacio := get_world_2d().direct_space_state
	var johnny: Node2D = get_parent()
	if not espacio.intersect_ray(PhysicsRayQueryParameters2D.create(johnny.global_position, global_position, 1)).is_empty():
		return 0.0
	var fin := global_position + Vector2.from_angle(angulo) * alcance
	var choque := espacio.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, fin, 1))
	return alcance if choque.is_empty() else global_position.distance_to(choque.position)


# Un pellizco a todos los zombis que están dentro de la llama (y, uno de cada EMPUJA, con empujón)
func quemar() -> void:
	ticks += 1
	var johnny: Node2D = get_parent()
	var u := Vector2.from_angle(angulo)
	var empuja := ticks % EMPUJA == 1
	johnny.oir_disparo()   # el fuego se oye: despierta a los que duermen cerca
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if not dentro(zombi, johnny, u):
			continue
		if zombi.get("inmune_fuego"):
			zombi.prender()   # al jefe de bomberos el fuego no le hace nada
			continue
		var d: int = johnny.con_critico(dps * TICK)
		if empuja:
			zombi.recibir_golpe(d, u * EMPUJE * empuje)
		else:
			zombi.herir(d, Llamas.FUEGO[2])   # sin empujón ni encogerse, con el número del color del fuego
		ArmasCreadas.prender(zombi, quema)


# ¿Está el zombi dentro de la llama? Por el suelo: en el cono que sale de la boca (estrecho en ella, y se abre hasta
# donde llega) o, si está más cerca que la boca (a quemarropa), en la franja entre Johnny y la boca. Y sin una pared
# en medio
func dentro(zombi: Node2D, johnny: Node2D, u: Vector2) -> bool:
	var r: float = zombi.radio
	var p := zombi.global_position - global_position
	var delante := p.dot(u)
	var desde := global_position
	if delante < 0.0:
		var q := zombi.global_position - johnny.global_position
		if q.dot(u) < -r or absf(q.cross(u)) > BOCA * 2.0 + r:
			return false
		desde = johnny.global_position
	elif delante > tope + r or absf(p.cross(u)) > BOCA + delante * tan(ABRE) + r:
		return false
	var rayo := PhysicsRayQueryParameters2D.create(desde, zombi.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# Provisional: a trozos de 8 unidades por el suelo, de la boca a la punta, y en cada trozo una fila de cuadraditos de
# lado a lado. Cada uno, de su color según lo "caliente" que esté: amarillo claro en el medio junto a la boca, luego
# naranja, y rojo en los bordes y lejos; al final, humo. Ondula y tiembla con el tiempo
func _draw() -> void:
	if largo <= 0.0:
		return
	var u := Vector2.from_angle(angulo)
	var n := u.orthogonal()
	var d := 0.0
	var i := 0
	while d < largo:
		var f := d / alcance
		var ancho := BOCA + d * tan(ABRE)
		var alto := lerpf(ALTURA, ALTURA_CUERPO, f)
		var ola := sin(tiempo * 13.0 - d * 0.045) * d * 0.06
		var lado_paso := clampf(ancho / 3.0, 3.0, 8.0)
		var m := ceili(ancho / lado_paso)
		for k in range(-m, m + 1):
			var lado := absf(k * lado_paso) / ancho
			if lado > 1.0:
				continue
			# los bordes y la punta, deshilachados: a ratos, nada
			if (lado > 0.75 or d > largo - 24.0) and fmod(i * 7.3 + k * 3.1 + tiempo * 31.0, 5.0) < 1.6:
				continue
			var calor := 1.0 - maxf(f * 0.95, lado) - f * lado * 0.3 + sin(tiempo * 17.0 - d * 0.08 + k * 1.9) * 0.1
			var color: Color
			if d > largo - 28.0 and largo >= tope - 1.0 and f > 0.7:
				color = HUMO
			elif calor > 0.72:
				color = Llamas.FUEGO[0]
			elif calor > 0.52:
				color = Llamas.FUEGO[1]
			elif calor > 0.34:
				color = Llamas.FUEGO[2]
			elif calor > 0.17:
				color = Llamas.FUEGO[3]
			else:
				color = Llamas.FUEGO[4]
			var tam := roundf(lerpf(4.0, 10.0, f) / 2.0) * 2.0
			var p := u * d + n * (k * lado_paso + ola) + Vector2(0, -alto)
			p = (p / 2.0).round() * 2.0
			draw_rect(Rect2(p - Vector2(tam, tam) / 2.0, Vector2(tam, tam)), color)
		d += 8.0
		i += 1
