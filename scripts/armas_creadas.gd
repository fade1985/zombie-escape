# Lo que hacen las armas con efecto (fase 7b2; src/armas-creadas.js del JS): el lanzallamas, el lanza ácido y el
# lanza rayos, que eran armas creadas del banco de trabajo y desde el 25 oct se compran en la tienda de armas.
# Sus números están en Armas.DATOS (su "efecto"); aquí, lo que hacen:
#   - Las gotas y chispas sueltas (chorro.gd, disparar y golpe): de cuando eran armas a distancia; desde el 26 oct las tres
#     echan un chorro continuo que va aparte (llamarada.gd: la llamarada, el chorro de ácido y el rayo, que aturde y
#     salta de un zombi a otro), y ya no las usa ninguna.
#   - Lo que dejan en el zombi: la quemadura (que se contagia a los de al lado: zombi.gd) y el ácido que sigue
#     royendo y le come la armadura (con_acido).
#   - El estallido de las Épicas (estallido): el zombi que matan revienta y pasa su efecto a los de al lado. Los jefes no se aturden ni arden; el ácido sí les hace daño. (La
#     herida que sangra, la de los clavos de la bomba de clavos, se quitó del juego con ella el 25 oct.)
class_name ArmasCreadas

const CHORRO := preload("res://scripts/chorro.gd")
const EMPUJE := 170.0   # empuje base, como el de las balas
# Los efectos de las armas que queman: el lanzallamas (con la skin del bombero, +50 %: johnny.gd, arma_de())
const QUEMAN := ["llama"]

# Números de los efectos (provisionales, como EFECTOS en el JS)
const EFECTOS := {
	# el ácido sigue royendo (el triple de un pellizco) y, mientras le dura, le come la armadura: todo le quita un
	# 50 % más ("corroe": con_acido)
	"acido": {"t": 3.0, "total": 3.0, "color": Color("#c7e04a"), "corroe": 1.5},
	"descarga": {"salto": 130.0, "dano": 0.5},                       # salta al más cercano con medio daño
	"chispa": 0.4,                                                   # el calambre del estallido del lanza rayos Épico: aturde 0,4 s
	"tick": 0.5,                                                     # cada cuánto se quitan los pellizcos
}


# La descarga: aturde al zombi y salta al más cercano (a menos de "salto"), que se lleva medio daño y también
# se queda aturdido; mejorada ("saltos" más, por su calidad), sigue saltando de ese al más cercano que aún no ha
# pillado. La usaban las chispas sueltas; el rayo continuo (llamarada.gd) usa sus mismos números ("descarga")
static func descarga(zombi: Node2D, dano: float, aturde: float, saltos := 0) -> void:
	aturdir(zombi, aturde)
	var pillados: Array = [zombi]
	var desde := zombi
	for vez in 1 + saltos:
		var otro: Node2D = null
		var mejor: float = EFECTOS.descarga.salto
		for o in zombi.get_tree().get_nodes_in_group("zombis"):
			var d: float = o.global_position.distance_to(desde.global_position)
			if not o in pillados and d < mejor:
				mejor = d
				otro = o
		if otro == null:
			return
		rayo(zombi, desde.global_position + Vector2(0, -40), otro.global_position + Vector2(0, -40))
		var hacia := (otro.global_position - desde.global_position).normalized()
		otro.recibir_golpe(roundi(dano * EFECTOS.descarga.dano), hacia * EMPUJE * 0.5)
		aturdir(otro, aturde)
		pillados.append(otro)
		desde = otro


# El truco de las Épicas especiales (Armas.TRUCO): el zombi que acaban de matar revienta y pasa su efecto a los que
# tiene a menos de "estallido": los prende (el fuego; "quema", como la llamarada), les deja la herida de ácido o les da
# un calambre (los aturde y les quita medio daño, con su rayo). Se ve un anillo y unas chispas de su color
static func estallido(zombi: Node2D, tipo: String, dano: float, quema := 1.0) -> void:
	var color: Color = {"llama": Llamas.FUEGO[2], "acido": EFECTOS.acido.color, "chispa": Color("#9fe8ff")}[tipo]
	var sala: Node = zombi.get_parent()
	var donde: Vector2 = zombi.global_position
	Particulas.anillo(sala, donde + Vector2(0, -20), Armas.TRUCO.estallido, color, 0.35)
	for i in 10:
		var v := Vector2.from_angle(randf() * TAU) * randf_range(80.0, 200.0)
		Particulas.soltar(sala, donde + Vector2(0, -24), v, color if i % 3 else Color.WHITE, randf_range(3.0, 5.0), 0.35)
	Sonido.tocar({"llama": "fuego", "acido": "escupitajo", "chispa": "chispa"}[tipo])
	for otro in zombi.get_tree().get_nodes_in_group("zombis"):
		if otro == zombi or otro.global_position.distance_to(donde) > Armas.TRUCO.estallido + otro.radio:
			continue
		match tipo:
			"llama":
				if not otro.get("inmune_fuego"):
					prender(otro, quema)
			"acido":
				herir(otro, "acido", dano)
			"chispa":
				rayo(sala, donde + Vector2(0, -40), otro.global_position + Vector2(0, -40))
				otro.recibir_golpe(roundi(dano * EFECTOS.descarga.dano), (otro.global_position - donde).normalized() * EMPUJE * 0.5)
				aturdir(otro, EFECTOS.chispa)


# Se queda quieto echando chispitas amarillas (como con la mutación Tentacular). Los jefes, no
static func aturdir(zombi: Node2D, t: float) -> void:
	if zombi is Zombi and zombi.is_in_group("zombis"):
		zombi.aturdido = maxf(zombi.aturdido, t)


# Lo prende como el molotov ("quema": cuánto más arde; la skin del bombero, × 1,5). Los jefes no arden
static func prender(zombi: Node2D, quema := 1.0) -> void:
	if zombi is Zombi and zombi.is_in_group("zombis"):
		zombi.prender(quema)


# El ácido: quita poco a poco una parte del golpe (con cada golpe vuelve a empezar)
static func herir(zombi: Node2D, tipo: String, dano: float) -> void:
	if not zombi.is_in_group("zombis") or not zombi.has_method("herir"):
		return
	var ef: Dictionary = EFECTOS[tipo]
	var h: Herida = zombi.get_node_or_null("herida_" + tipo)
	if h == null:
		h = Herida.new()
		h.name = "herida_" + tipo
		h.color = ef.color
		h.acido = tipo == "acido"
		zombi.add_child(h)
	h.t = ef.t
	h.dps = dano * ef.total / ef.t


# El ácido le come la armadura: mientras lo lleva (el que le sigue royendo o el de un charco: se le ven las manchas),
# todo lo que le hace daño le quita "corroe" veces más, también el propio ácido. Lo miran los que reciben los golpes
# (zombi.gd, minijefe.gd, portera.gd y maniqui_vivo.gd). A Johnny, no
static func con_acido(nodo: Node, cantidad: int) -> int:
	if nodo.has_node("herida_acido") or (nodo is Zombi and nodo.estados.has("acido")):
		return roundi(cantidad * EFECTOS.acido.corroe)
	return cantidad


# El rayo de la descarga: una línea en zigzag de puntitos azules y blancos
static func rayo(desde: Node, a: Vector2, b: Vector2) -> void:
	Sonido.tocar("click")
	var n := maxi(4, roundi(a.distance_to(b) / 8.0))
	for i in n + 1:
		var lado := 1.0 if i % 2 else -1.0
		var p := a.lerp(b, float(i) / n) + Vector2(lado * randf_range(2, 6), lado * randf_range(2, 6))
		Particulas.soltar(desde, p, Vector2.ZERO, Color("#9fe8ff") if i % 3 else Color.WHITE, 3, 0.2)


# ── A distancia ──

# Disparo de un arma creada a distancia desde la boca del arma: suelta gotas de fuego, ácido o chispas que
# atraviesan a los zombis
static func disparar(johnny: Node2D, angulo: float, w: Dictionary, salida: Vector2) -> void:
	var sala: Node = johnny.get_parent()
	Sonido.tocar({"acido": "escupitajo", "chispa": "chispa"}.get(w.efecto, "fuego"))
	var g := CHORRO.new()
	g.tipo = w.efecto
	g.velocidad = Vector2.from_angle(angulo + (randf() - 0.5) * 0.14) * w.velocidad * randf_range(0.85, 1.15)
	g.dano = w.dano
	g.empuje = w.empuje
	g.quema = w.get("quema", 1.0)
	g.saltos = w.get("saltos", 0)
	g.epica = w.get("calidad", 0) >= Armas.EPICA
	g.vida_max = w.alcance / w.velocidad
	sala.add_child(g)
	g.global_position = salida
	if w.efecto == "chispa":
		Luz.destello(johnny, salida - Vector2(0, 50), 110.0, 0.06, 1.0, Color("#9fe8ff"))
	elif w.efecto != "acido":
		Luz.destello(johnny, salida - Vector2(0, 50), 120.0, 0.08)


# Lo que pasa cuando una gota o una chispa tocan a un zombi ("quema": cuánto más arde el que prende una gota de
# fuego; "epica": si lo mata, revienta, estallido)
static func golpe(zombi: Node2D, hacia: Vector2, dano: float, empuje: float, tipo: String, quema := 1.0,
		saltos := 0, epica := false) -> void:
	# al jefe de bomberos (bombero.gd) el fuego no le hace nada: ni el daño ni prenderle
	if tipo == "llama" and zombi.get("inmune_fuego"):
		zombi.prender()
		return
	var johnny := zombi.get_tree().get_first_node_in_group("jugador")
	var d: int = johnny.con_critico(dano) if johnny else roundi(dano)
	zombi.recibir_golpe(d, hacia.normalized() * EMPUJE * empuje)
	if not zombi.is_in_group("zombis"):
		if epica:
			estallido(zombi, tipo, d, quema)
		return
	if tipo == "llama":
		prender(zombi, quema)
	elif tipo == "chispa":
		descarga(zombi, d, EFECTOS.chispa, saltos)
	elif tipo == "acido":
		herir(zombi, "acido", d)


# El ácido en un zombi: va de hijo suyo y le quita vida a pellizcos. Lo tiñe de verde (a los zombis, zombi.gd, que lo
# junta con el fuego; a los jefes, aquí) y, mientras está, todo le quita más (con_acido). Al jefe de bomberos el ácido
# solo lo tiñe: su herir() es el del fuego de los charcos (la vida se la quita el chorro, llamarada.gd)
class Herida extends Node:
	var t := 0.0
	var dps := 0.0
	var color := Color.WHITE
	var tick := 0.0
	var acido := false
	var puesta := 0.0   # lo que lleva puesta (para que el verde lata)

	func _physics_process(delta: float) -> void:
		var zombi: Node2D = get_parent()
		if not zombi.is_in_group("zombis"):
			pintar(zombi, false)
			queue_free()
			return
		t -= delta
		tick += delta
		puesta += delta
		if acido:
			pintar(zombi, true)
		if tick >= ArmasCreadas.EFECTOS.tick:
			tick -= ArmasCreadas.EFECTOS.tick
			if not zombi.get("inmune_fuego"):
				zombi.herir(dps * ArmasCreadas.EFECTOS.tick, color)
		if t <= 0.0:
			pintar(zombi, false)
			queue_free()

	# El ácido en un jefe (que no es Zombi): con el shader de los zombis (el del destello), que se le pone la primera
	# vez, y su luz verde, que se quita al acabarse
	func pintar(jefe: Node2D, si: bool) -> void:
		if not acido or jefe is Zombi or not jefe.get("sprite") is CanvasItem:
			return
		var s: CanvasItem = jefe.get("sprite")
		if not s.material is ShaderMaterial:
			if not si:
				return
			s.material = ShaderMaterial.new()
			s.material.shader = Zombi.DESTELLO
			s.material.set_shader_parameter("semilla", randf() * 100.0)
		Zombi.quemaduras(s, 0.0, Zombi.cuanto_acido(puesta) if si else 0.0, puesta)
		if si:
			var alto: float = jefe.get("arriba") if jefe.get("arriba") != null else 120.0   # (Minijefe.arriba)
			Brillo.luz_acido(jefe, alto).fuerza = 0.55
		elif jefe.has_node("LuzAcido"):
			jefe.get_node("LuzAcido").queue_free()
