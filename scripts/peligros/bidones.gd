# Los bidones contra los jefes (M16): tres en la habitación del Glotón, de fuego, y tres en la del jefe de bomberos, de
# ácido (Peligros.bidones; los reparte planta.gd con los demás peligros de su habitación). Están de pie, en el borde
# de la elipse limpia del medio. Se usan como los muebles de la sala de mantenimiento (mapa/zona_usar.gd, con su
# contorno amarillo): con Johnny delante, el clic encima, J, B en el mando o el botón «Empujar» del móvil. Entonces se
# tumba y sale rodando en línea recta hacia donde está el jefe en ese momento; si el jefe se aparta, sigue hasta la
# pared y revienta ahí, gastado. A los zombis que pilla por el camino los aparta de un golpe.
# Si le da al jefe, lo deja atontado ATONTA s (Minijefe.atontar, con las estrellitas) y revienta en un charco de lo que
# lleva: fuego (al Glotón le quema) o ácido (al bombero, que no se quema, el ácido sí le hace daño). El charco también
# le hace daño a Johnny si lo pisa. Si el jefe no se puede tocar (el bombero dando vueltas con su burbuja de fuego, o
# gritando al enfadarse), revienta igual pero no lo atonta.
# Cada bidón es de un solo uso: "usado" se apunta en el sitio, y al volver a la habitación ya no está.
# Los dibujos: assets/sprites/bidon-<fuego|acido>[-tumbado].png (tools/bidones.py: de GPT, reducidos como los muebles)
extends Node2D

const ZONA_USAR := preload("res://scripts/mapa/zona_usar.gd")
const CHARCO := preload("res://escenas/armas/charco.tscn")

const ATONTA := 3.0          # lo que deja atontado al jefe (antes 5: el dueño lo bajó a 3)
const RAPIDEZ := 380.0       # lo deprisa que rueda
const DURA_MAX := 4.0        # lo más que rueda (si no choca con nada antes)
const RADIO := 18.0          # lo que ocupa rodando (para chocar)
const CHARCO_ESCALA := 1.3   # el charco que deja, algo más grande que el de un molotov
const ZOMBI_DANO := 10       # el golpe a los zombis que pilla rodando
const ZOMBI_EMPUJE := 420.0
# Los colores de lo que salta al reventar (y los del charco los pone charco.gd)
const SALPICA := {"fuego": [Color("#ffd23f"), Color("#ff8a1f"), Color("#e8401c")],
	"acido": [Color("#b8f25a"), Color("#78e046"), Color("#3fa83a")]}

var datos: Dictionary
var mapa: Node
var bidones: Array[Node2D] = []


func montar(d: Dictionary, m: Node) -> void:
	datos = d
	mapa = m
	name = "Bidones"   # no-tr (nombre de nodo)


# Los bidones van en "cosas" (ordenados por su "y" con los personajes: están de pie)
func _ready() -> void:
	for i in datos.cosas.size():
		if datos.cosas[i].usado:
			continue
		var b := Bidon.new()
		b.montar(self, i)
		mapa.cosas.add_child(b)
		bidones.append(b)


# El jefe de la habitación, si está vivo (si no, los bidones ya no se pueden usar)
func jefe() -> Node2D:
	for z in get_tree().get_nodes_in_group("zombis"):
		if z is Minijefe and z.estado != "muerto" and mapa.zona_en(z.global_position) == datos.sala:
			return z
	return null


class Bidon extends Node2D:
	var dueno: Node2D             # el nodo Bidones
	var i := 0                    # cuál es (en datos.cosas)
	var dibujo: Sprite2D
	var cuerpo: StaticBody2D
	var zona: Area2D
	var dir := Vector2.ZERO       # rodando: hacia dónde (si no, está de pie)
	var t := 0.0
	var pillados := []            # los zombis que ya ha apartado


	func montar(d: Node2D, cual: int) -> void:
		dueno = d
		i = cual
		name = "Bidon%d" % cual   # no-tr
		position = d.datos.cosas[cual].pos
		dibujo = Sprite2D.new()
		dibujo.texture = load("res://assets/sprites/bidon-%s.png" % d.datos.contenido)
		dibujo.scale = Vector2(2, 2)
		dibujo.position = Vector2(0, -dibujo.texture.get_height())   # apoyado en el suelo por su pie
		add_child(dibujo)
		# no se le atraviesa: un cuerpo bajito en su pie, como el de los muebles
		cuerpo = StaticBody2D.new()
		cuerpo.collision_layer = 1
		cuerpo.collision_mask = 0
		var hueco := CollisionShape2D.new()
		var forma := RectangleShape2D.new()
		forma.size = Vector2(40, 16)
		hueco.shape = forma
		hueco.position = Vector2(0, -6)
		cuerpo.add_child(hueco)
		add_child(cuerpo)
		# la zona de alrededor donde se pone Johnny para empujarlo
		zona = ZONA_USAR.new()
		zona.montar_rect(Rect2(-54, -44, 108, 88))
		zona.al_pie = true
		zona.boton = Idioma.t("Empujar")
		zona.puede = func() -> bool: return dir == Vector2.ZERO and dueno.jefe() != null
		add_child(zona)
		zona.usar.connect(empujar)


	# Sale rodando hacia donde está el jefe ahora (en línea recta: si se aparta, falla)
	func empujar() -> void:
		var j: Node2D = dueno.jefe()
		if j == null or dir != Vector2.ZERO:
			return
		dir = global_position.direction_to(j.global_position)
		if dir == Vector2.ZERO:
			dir = Vector2.DOWN
		dueno.datos.cosas[i].usado = true   # (de un solo uso: al volver, ya no está)
		cuerpo.queue_free()
		if zona.contorno:
			zona.contorno.queue_free()   # (va aparte, en el bidón: si no, se quedaría encendido)
		zona.queue_free()
		# tumbado, con las tapas a los lados de hacia donde rueda (girado de 45 en 45 grados, para que el pixel art no se
		# deforme mucho)
		dibujo.texture = load("res://assets/sprites/bidon-%s-tumbado.png" % dueno.datos.contenido)
		dibujo.position = Vector2(0, -dibujo.texture.get_height())
		dibujo.rotation = snappedf(dir.angle() + PI / 2.0, PI / 4.0)
		Sonido.tocar("portazo")


	func _physics_process(delta: float) -> void:
		if dir == Vector2.ZERO:
			return
		t += delta
		position += dir * RAPIDEZ * delta
		# un pequeño bote al rodar
		dibujo.position.y = -dibujo.texture.get_height() - absf(sin(t * 22.0)) * 2.0
		var j: Node2D = dueno.jefe()
		if j:
			# el bombero con su burbuja de fuego: revienta contra ella (brilla donde le da) y no le hace nada
			if j.has_method("escudo_toca") and j.escudo_toca(global_position + Vector2(0, -20)):
				j.rebote(dir * 300.0, false)
				j.onda_en(j.centro_burbuja() - dir * j.radio_burbuja())
				j.decir_inmune()
				reventar(false)
				return
			if global_position.distance_to(j.global_position) < j.radio + RADIO:
				reventar(j.atontar(ATONTA))
				return
		# a los zombis que pilla, los aparta de un golpe (una vez cada uno)
		for z in get_tree().get_nodes_in_group("zombis"):
			if z is Minijefe or z in pillados or not z.has_method("recibir_golpe"):
				continue
			if global_position.distance_to(z.global_position) < z.radio + RADIO:
				pillados.append(z)
				var lado := dir.orthogonal() * signf(dir.orthogonal().dot(z.global_position - global_position) + 0.01)
				z.recibir_golpe(ZOMBI_DANO, (lado + dir * 0.5).normalized() * ZOMBI_EMPUJE)
				Sonido.tocar("golpe")
		# contra la pared (o rodando demasiado), revienta gastado
		var delante := global_position + dir * RADIO
		if dueno.mapa.es_muro(floori(delante.x / Peligros.CASILLA), floori(delante.y / Peligros.CASILLA)) or t >= DURA_MAX:
			reventar(false)


	# Revienta: el charco de lo que lleva (en píxel entero del dibujo), lo que salta y el golpe. "atonto": si le ha
	# dado al jefe y lo ha atontado
	func reventar(atonto: bool) -> void:
		var contenido: String = dueno.datos.contenido
		var charco: Node2D = CHARCO.instantiate()
		charco.tipo = contenido
		charco.escala = CHARCO_ESCALA
		charco.position = (position / 2.0).round() * 2.0
		get_parent().add_child(charco)
		var colores: Array = SALPICA[contenido]
		for k in 26:
			var v := Vector2.from_angle(randf() * TAU) * randf_range(60.0, 220.0) + Vector2(0, -randf_range(40.0, 160.0))
			Particulas.soltar(get_parent(), global_position + Vector2(0, -14), v, colores[k % colores.size()],
				randf_range(2.0, 4.0), randf_range(0.3, 0.6))
		Sonido.tocar("portazo")
		Sonido.tocar("fuego" if contenido == "fuego" else "chisporroteo")
		Temblor.temblar(9.0 if atonto else 5.0)
		dueno.bidones.erase(self)
		queue_free()
