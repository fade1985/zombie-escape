# El tutorial disimulado (docs/LANZAMIENTO.md, apartado 2): en la primera partida, la planta baja de los Apartamentos
# enseña a jugar con las ventanas de los tutoriales (tutoriales.gd) justo cuando hace falta, y además:
#   - el HUD que late: tras cerrar la ventana, la casilla de lo que toca usar (hud.gd, "latido") late hasta que se hace
#     (o a los DURA segundos);
#   - una flecha en el suelo, delante de Johnny, hacia donde hay que ir: en la sala de mantenimiento, la puerta del
#     pasillo; en el pasillo, el apartamento sin limpiar más cercano (el fácil, primero), la sala del jefe con la llave
#     y las escaleras tras el jefe. Con la tele de las noticias encendida (al coger la página del dosier), antes que
#     nada su apartamento (15 nov, lo pidió el dueño: primero la tele y luego el jefe);
#   - una llavecita encima del zombi que lleva la llave del jefe.
# Y el primer apartamento al que lleva la flecha es fácil a propósito: pocos zombis, sin la llave y con unas vendas en el
# armarito del baño (preparar_planta).
#
# Las ventanas: al empezar, «Moverse y esquivar» (partida.tutorial_al_empezar, que apunta también «Cómo se juega» como
# visto: lo demás va saliendo luego). Las que pide la guía (PASOS), en orden: «Atacar» en la primera pelea (al despertarse
# el primer zombi o al cerrarse la puerta del primer apartamento: partida.gd; «Lanzables», desde el 15 nov, con el primero que se consigue); en una pelea con la
# fregona en la mano y la pistola guardada, la casilla de las armas late hasta cambiar (con la ventana «Cambiar de arma»
# delante si no salió ya; en la primera partida no sale al sacar la pistola del baúl: partida.mirar_tutoriales, M97), y «Munición y recarga» con la pistola en la
# mano y medio cargador, antes de quedarse sin balas. «Vendas», «Jefes» y las
# demás salen como en cualquier partida. Hasta el 15 nov (M109) esto eran letreros encima de la cabeza de Johnny.
# Las ventanas de CUBRE no salen mientras la guía está activa (partida.tutorial).
#
# Se enciende en partida.gd (_ready) si es la primera partida, en los Apartamentos y con los tutoriales encendidos
# (Opciones → Ayudas); se apaga al subir a la planta siguiente. Lo engancha partida.gd: nueva_planta(), al_montar() y
# marcar_llave(). Se prueba con --captura --guiado (prueba_varias.gd).
class_name Guia
extends Node

const LLAVE := preload("res://assets/sprites/objeto-llave-puerta.png")
const DURA := 12.0          # lo más que late una casilla del HUD sin hacerse lo que pide
const FACIL := 3            # los zombis del primer apartamento
const LEJOS_FLECHA := 150.0 # más cerca de la puerta que esto, la flecha se va

# Las ventanas que no salen mientras la guía está activa: «Cómo se juega» (la cuentan «Moverse y esquivar» y las de
# PASOS) y «Limpia los apartamentos» (lo dice la línea de abajo al salir al pasillo, al_montar)
const CUBRE := ["jugar", "apartamentos"]

# Cada paso: la ventana que sale y la casilla del HUD que late después, hasta que se hace (hecho())
const PASOS := {
	"atacar": {"tutorial": "atacar", "latido": ""},
	"pistola": {"tutorial": "cambiar_arma", "latido": "armas"},
	"recargar": {"tutorial": "municion", "latido": "balas"},
}

var partida: Node
var johnny: Node2D
var activa := false
var hechos: Array = []        # los pasos ya enseñados
var paso := ""                # el último enseñado, mientras late su casilla
var desde := 0.0              # cuánto lleva latiendo
var facil := -1               # el apartamento fácil (su número de sitio)
var dicho: Array = []         # los avisos de la línea de abajo ya dichos ("pasillo", "llave")
var flecha := Flecha.new()


func preparar(p: Node) -> void:
	partida = p
	johnny = p.johnny


# Al generar cada planta: fuera de la planta baja se apaga. En la planta baja, sin evento sorpresa y con su apartamento
# fácil: el más cercano a la puerta de la sala de mantenimiento se queda con FACIL zombis (si llevaba la llave, la
# pasa a uno de otro apartamento) y su armarito, con vendas
func nueva_planta() -> void:
	var planta: Dictionary = partida.planta
	if planta.num != 1:
		apagar()
		return
	if not activa:
		return
	partida.eventos.evento = ""
	var pasillo: Dictionary = planta.sitios[0]
	var desde_x := 0.0
	for s in pasillo.salidas:
		if s.get("a", -1) == planta.mantenimiento:
			desde_x = s.en
	var mejor := INF
	for s in pasillo.salidas:
		if s.tipo == "puerta" and planta.sitios[s.a].tipo == "apartamento" and absf(s.en - desde_x) < mejor:
			mejor = absf(s.en - desde_x)
			facil = s.a
	if facil < 0:
		return
	var sitio: Dictionary = planta.sitios[facil]
	var llevaba: bool = sitio.zombis.any(func(z): return z.get("llave", false))
	var quedan: Array = sitio.zombis.filter(func(z): return not z.get("llave", false))
	sitio.zombis = quedan.slice(0, FACIL)
	for z in sitio.zombis:
		z.tipo = "lento" if z.tipo == "lento" else "normal"
	if llevaba:
		for i in planta.sitios.size():
			var otro: Dictionary = planta.sitios[i]
			if i != facil and otro.tipo == "apartamento" and not otro.zombis.is_empty():
				otro.zombis[0].llave = true
				break
	if not sitio.get("armaritos", []).is_empty():
		sitio.armaritos[0].dentro = "vendas"


func apagar() -> void:
	activa = false
	paso = ""
	flecha.visible = false
	poner_latido("")


# Antes de quitar el mapa viejo: la flecha sale de él (si no, se iría con él)
func recoger() -> void:
	if flecha.get_parent():
		flecha.get_parent().remove_child(flecha)


# Al montar cada sitio: la flecha, al suelo del mapa nuevo
func al_montar() -> void:
	recoger()
	if not activa:
		return
	partida.mapa.cosas.add_child(flecha)
	if partida.planta.sitios[partida.aqui].tipo == "pasillo" and not "pasillo" in dicho:
		dicho.append("pasillo")
		Tutoriales.apuntar("apartamentos")
		partida.decir(Idioma.t("Limpia los apartamentos: al entrar, la puerta se cierra hasta que no quede ni un durmiente"), 5.0)


# El zombi de la llave lleva una llavecita encima, que sube y baja
func marcar_llave(zombi: Node2D) -> void:
	if not activa:
		return
	var marca := Sprite2D.new()
	marca.texture = LLAVE
	marca.position = Vector2(0, -100)   # (por encima de su barra de vida)
	marca.z_index = 5
	marca.name = "MarcaLlave"
	zombi.add_child(marca)
	zombi.murio.connect(marca.queue_free)   # (el cuerpo se queda en el suelo: la llavecita, no)
	var tween := marca.create_tween().set_loops()
	tween.tween_property(marca, "position:y", -108.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(marca, "position:y", -100.0, 0.5).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	if not activa or partida.mapa == null or partida.cambiando or partida.terminada or not johnny.vivo:
		poner_latido("")
		return
	mover_flecha()
	mirar_avisos()
	var toca := siguiente()
	if toca != "":
		mostrar(toca)
	# la casilla del HUD del último paso late hasta que se hace (con su ventana abierta, el juego está parado y no corre)
	if paso != "":
		desde += delta
		if hecho(paso) or desde >= DURA:
			paso = ""
		poner_latido(PASOS[paso].latido if paso != "" else "")


# El paso que toca ahora (el primero de la lista que aún no se ha enseñado y viene a cuento), o "". Todos, en una pelea
func siguiente() -> String:
	if zombis_despiertos().is_empty():
		return ""
	if not "atacar" in hechos:
		return "atacar"
	if not "pistola" in hechos and johnny.mano == "cuerpo" and johnny.huecos.fuego != "":
		return "pistola"
	var arma: Dictionary = johnny.base(johnny.huecos.fuego)
	if not "recargar" in hechos and johnny.mano == "fuego" and not arma.has("deposito") \
			and johnny.balas <= arma.cargador / 2 and johnny.recargando <= 0.0:
		return "recargar"
	return ""


# Saca la ventana de un paso (partida.tutorial: si ya se vio, no sale) y, tras ella, que lata su casilla. También la
# llama partida.gd con "atacar" al cerrarse la puerta de la primera pelea
func mostrar(id: String) -> void:
	if not activa or id in hechos:
		return
	hechos.append(id)
	partida.tutorial(PASOS[id].tutorial)
	paso = id
	desde = 0.0


# Si ya se ha hecho lo que pide el paso
func hecho(id: String) -> bool:
	match id:
		"pistola":
			return johnny.mano == "fuego"
		"recargar":
			return johnny.recargando > 0.0
	return true   # (atacar no hace latir nada)


# Los avisos de la línea de abajo, una vez cada uno: el zombi de la llave al despertar (el primer tercio perdido ya no:
# sale su ventana, M35)
func mirar_avisos() -> void:
	if not "llave" in dicho:
		for z in zombis_despiertos():
			if z.has_meta("llave"):
				dicho.append("llave")
				partida.decir(Idioma.t("¡Ese durmiente lleva la llave del %s!") % partida.nombre_jefa(), 3.5)


func zombis_despiertos() -> Array:
	return get_tree().get_nodes_in_group("zombis").filter(func(z):
		return is_instance_valid(z) and not z.get("dormido") and z.get("estado") != "muerto")


func poner_latido(cual: String) -> void:
	var hud := partida.get_node_or_null("Pantalla/HUD")
	if hud:
		hud.latido = cual


# La flecha: delante de Johnny, hacia la puerta que toca (destino); sin destino o ya cerca, no se ve
func mover_flecha() -> void:
	var puerta := destino()
	if puerta == null or puerta.global_position.distance_to(johnny.global_position) < LEJOS_FLECHA:
		flecha.visible = false
		return
	var dir: Vector2 = (puerta.global_position - johnny.global_position).normalized()
	flecha.visible = true
	flecha.position = johnny.position + Vector2(0, 14) + dir * 76.0
	flecha.rotation = dir.angle()


# La puerta a la que lleva la flecha: en la sala de mantenimiento, la del pasillo (si no hay zombis y ya no queda ningún «!»); en el pasillo,
# las escaleras con el jefe caído, el apartamento con la tele encendida sin ver (tele_por_ver), la sala del jefe con la
# llave, o el apartamento sin limpiar más cercano (el fácil, antes que ninguno)
func destino() -> Node2D:
	var planta: Dictionary = partida.planta
	var sitio: Dictionary = planta.sitios[partida.aqui]
	var puertas: Array = partida.mapa.puertas
	if sitio.tipo == "mantenimiento":
		if partida.falta_sala():
			return null   # (mientras quede algún «!» en la sala, no se sale: partida.falta_sala)
		for i in sitio.salidas.size():
			if sitio.salidas[i].get("a", -1) == 0 and i < puertas.size():
				return puertas[i]
		return null
	if sitio.tipo != "pasillo":
		return null
	var mejor: Node2D = null
	var nota := INF
	var tele := tele_por_ver()
	for i in mini(sitio.salidas.size(), puertas.size()):
		var s: Dictionary = sitio.salidas[i]
		var vale := false
		if planta.jefa_muerta:
			vale = s.tipo == "escaleras"
		elif tele >= 0:
			vale = s.get("a", -1) == tele
		elif planta.tiene_llave:
			vale = s.get("cerrojo", "") == "llave"
		elif s.tipo == "puerta" and s.get("cerrojo", "") == "":
			var otro: Dictionary = planta.sitios[s.a]
			vale = otro.tipo == "apartamento" and not otro.limpio
		if not vale:
			continue
		var d: float = puertas[i].global_position.distance_to(johnny.global_position) - (100000.0 if s.get("a", -1) == facil else 0.0)
		if d < nota:
			nota = d
			mejor = puertas[i]
	return mejor


# El apartamento de esta planta con la tele de las noticias encendida y aún sin ver (mapa/tele_salon.gd: se enciende al
# coger la página del dosier), o -1
func tele_por_ver() -> int:
	var sitios: Array = partida.planta.sitios
	for k in sitios.size():
		if sitios[k].get("tele", {}).get("estado", "") == "encendida":
			return k
	return -1


# La flecha amarilla del suelo, con su borde oscuro, que respira
class Flecha extends Node2D:
	var t := 0.0

	var dibujo := Sprite2D.new()

	func _ready() -> void:
		z_index = -1   # en el suelo, como los charcos
		# la flecha de GPT, pintada en el suelo y mirando a la derecha (M7; tools/muebles_gpt.py): el nodo la gira
		dibujo.texture = load("res://assets/sprites/flecha-guia.png")
		dibujo.scale = Vector2(2, 2)
		add_child(dibujo)

	func _process(delta: float) -> void:
		t += delta
		modulate.a = 0.65 + 0.35 * sin(t * 5.0)
		dibujo.position.x = 6.0 + sin(t * 5.0) * 5.0   # va y viene hacia donde apunta
