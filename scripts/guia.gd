# El tutorial disimulado (docs/LANZAMIENTO.md, apartado 2): en la primera partida, la planta baja de los Apartamentos
# enseña a jugar sin parar el juego. En vez de las ventanas de los tutoriales (tutoriales.gd) salen:
#   - pistas: un letrero pequeño encima de Johnny con la tecla en amarillo («Esquiva con Espacio»), justo cuando hace
#     falta; se va solo en cuanto se hace (o a los DURA segundos, y entonces su ventana podrá salir otro día);
#   - el HUD que late: la casilla de lo que toca usar (hud.gd, "latido");
#   - una flecha en el suelo, delante de Johnny, hacia donde hay que ir: en la sala de mantenimiento, la puerta del
#     pasillo; en el pasillo, el apartamento sin limpiar más cercano (el fácil, primero), la sala del jefe con la llave
#     y las escaleras tras el jefe;
#   - una llavecita encima del zombi que lleva la llave del jefe.
# Y el primer apartamento al que lleva la flecha es fácil a propósito: pocos zombis, sin la llave y con unas vendas en el
# armarito del baño (preparar_planta).
#
# Las pistas, en orden (PISTAS): moverse y esquivar al empezar; al ver un zombi despierto, atacar; luego sacar la
# pistola, recargar con medio cargador, curarse con vendas al estar herido y lanzar con tres zombis cerca. Los tercios
# y el jefe se cuentan con la línea de avisos (partida.decir) o con una pista con tiempo.
# Lo que se enseña así se apunta como visto (Tutoriales.apuntar) y queda en el apartado Tutorial del menú. Las
# ventanas de CUBRE no salen mientras la guía está activa (partida.tutorial).
#
# Se enciende en partida.gd (_ready) si es la primera partida, en los Apartamentos y con los tutoriales encendidos
# (Opciones → Ayudas); se apaga al subir a la planta siguiente. Lo engancha partida.gd: nueva_planta(), al_montar(),
# marcar_llave() y jefe_presentado(). Se prueba con --captura --guiado (prueba_varias.gd).
class_name Guia
extends Node

const LLAVE := preload("res://assets/sprites/objeto-llave-puerta.png")
const DURA := 12.0          # lo más que se queda una pista sin hacerse
const MINIMO := 1.5         # lo menos que se ve una pista (para que dé tiempo a leerla)
const FACIL := 3            # los zombis del primer apartamento
const CERCA := 300.0        # a qué distancia cuentan los zombis para la pista de lanzar
const LEJOS_FLECHA := 150.0 # más cerca de la puerta que esto, la flecha se va

# Las ventanas que la guía enseña a su manera (no salen mientras está activa)
const CUBRE := ["jugar", "apartamentos", "lanzables", "municion", "curas", "tercios", "jefes"]

# Cada pista: su frase (con las teclas entre llaves, como en tutoriales.gd), la ventana que cuenta como vista al hacerla
# y la casilla del HUD que late mientras sale. "atacar" usa la frase del modo de atacar (Tutoriales.atacar_modo)
# [traducir]
const PISTAS := {
	"moverse": {"texto": "Muévete con {moverse}", "tutorial": "", "latido": ""},
	"esquivar": {"texto": "Esquiva con {esquivar}: no te hacen daño", "tutorial": "jugar", "latido": ""},
	"atacar": {"texto": "", "tutorial": "", "latido": ""},   # (su frase es la del modo de atacar)
	"pistola": {"texto": "Saca la pistola con {cambiar_arma}", "tutorial": "", "latido": "armas"},
	"recargar": {"texto": "Recarga con {recargar}", "tutorial": "municion", "latido": "balas"},
	"vendas": {"texto": "Cúrate con {usar_vendas}", "tutorial": "curas", "latido": "curas"},
	"lanzar": {"texto": "Mantén {lanzar} para apuntar y suelta para lanzar", "tutorial": "lanzables", "latido": "lanzar"},
	"jefe": {"texto": "¡Sal de la marca del suelo o esquiva con {esquivar}!", "tutorial": "jefes", "latido": ""},
}
# [/traducir]

var partida: Node
var johnny: Node2D
var activa := false
var hechas: Array = []        # las pistas ya enseñadas
var pista := ""               # la que se ve ahora
var desde := 0.0              # cuánto lleva a la vista
var cumplida := false         # si ya se ha hecho lo que pide (se queda en cuanto pasa una vez)
var inicio := Vector2.ZERO    # dónde estaba Johnny al salir "moverse"
var lanzables_antes := 0      # los lanzables a mano al salir "lanzar" (al bajar, ha lanzado)
var vendas_antes := 0
var facil := -1               # el apartamento fácil (su número de sitio)
var dicho: Array = []         # los avisos de la línea de abajo ya dichos ("pasillo", "llave", "tercio")
var letrero := RichTextLabel.new()
var flecha := Flecha.new()


func preparar(p: Node) -> void:
	partida = p
	johnny = p.johnny
	letrero.bbcode_enabled = true
	letrero.fit_content = true
	letrero.autowrap_mode = TextServer.AUTOWRAP_OFF
	letrero.scroll_active = false
	letrero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letrero.theme = Tema.crear()
	letrero.add_theme_font_size_override("normal_font_size", 16)
	letrero.add_theme_constant_override("outline_size", 6)
	letrero.add_theme_color_override("font_outline_color", Tema.LINEA)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(Tema.LINEA, 0.75)
	fondo.border_color = Color(Tema.AMARILLO, 0.6)
	fondo.set_border_width_all(2)
	fondo.set_content_margin_all(6)
	letrero.add_theme_stylebox_override("normal", fondo)
	letrero.visible = false
	p.get_node("Pantalla").add_child(letrero)


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
	pista = ""
	letrero.visible = false
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
		partida.decir(Idioma.t("Limpia los apartamentos: al entrar, la puerta se cierra hasta que no quede ni un zombi"), 5.0)


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
	var tween := marca.create_tween().set_loops()
	tween.tween_property(marca, "position:y", -108.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(marca, "position:y", -100.0, 0.5).set_trans(Tween.TRANS_SINE)


# Tras la presentación del jefe: cómo se esquivan sus ataques (una pista que se va sola)
func jefe_presentado() -> void:
	if activa and not "jefe" in hechas:
		poner("jefe")


func _process(delta: float) -> void:
	if not activa or partida.mapa == null or partida.cambiando or partida.terminada or not johnny.vivo:
		letrero.visible = false
		poner_latido("")
		return
	mover_flecha()
	mirar_avisos()
	if pista == "":
		pista = siguiente()
		if pista != "":
			poner(pista)
	if pista != "":
		desde += delta
		cumplida = cumplida or hecha(pista)   # (lo hecho cuenta aunque pase enseguida, como la esquiva)
		if (cumplida and desde >= MINIMO) or desde >= DURA:
			if cumplida:
				var t: String = PISTAS[pista].tutorial
				if t != "":
					Tutoriales.apuntar(t)
			pista = ""
			letrero.visible = false
			poner_latido("")
		else:
			colocar_letrero()


# La pista que toca ahora (la primera de la lista que aún no se ha enseñado y viene a cuento), o ""
func siguiente() -> String:
	var despiertos := zombis_despiertos()
	if not "moverse" in hechas:
		return "moverse"
	if not "esquivar" in hechas:
		return "esquivar"
	if despiertos.is_empty():
		return ""
	if not "atacar" in hechas:
		return "atacar"
	if not "pistola" in hechas and johnny.mano == "cuerpo":
		return "pistola"
	var arma: Dictionary = johnny.base(johnny.huecos.fuego)
	if not "recargar" in hechas and johnny.mano == "fuego" and not arma.has("deposito") \
			and johnny.balas <= arma.cargador / 2 and johnny.recargando <= 0.0:
		return "recargar"
	if not "vendas" in hechas and "vendas" in partida.mochila and partida.puede_curar("vendas"):
		return "vendas"
	var cerca := despiertos.filter(func(z): return z.global_position.distance_to(johnny.global_position) < CERCA)
	if not "lanzar" in hechas and cerca.size() >= 3 and lanzables_a_mano() > 0:
		return "lanzar"
	return ""


func poner(id: String) -> void:
	pista = id
	desde = 0.0
	cumplida = false
	if not id in hechas:
		hechas.append(id)
	inicio = johnny.global_position
	lanzables_antes = lanzables_a_mano()
	vendas_antes = partida.mochila.count("vendas")
	letrero.text = Tutoriales.con_teclas(Tutoriales.atacar_modo() if id == "atacar" else Idioma.t(PISTAS[id].texto))
	letrero.visible = true
	letrero.reset_size()
	poner_latido(PISTAS[id].latido)
	colocar_letrero()


# Si ya se ha hecho lo que pide la pista
func hecha(id: String) -> bool:
	match id:
		"moverse":
			return johnny.global_position.distance_to(inicio) > 80.0
		"esquivar":
			return johnny.esquiva_t > 0.0
		"atacar":
			return johnny.ataque_t >= 0.0 or (Guardado.ajuste("modo") != "libre" and desde > 4.0)
		"pistola":
			return johnny.mano == "fuego"
		"recargar":
			return johnny.recargando > 0.0
		"vendas":
			return partida.mochila.count("vendas") < vendas_antes
		"lanzar":
			return lanzables_a_mano() < lanzables_antes
	return false   # (la del jefe se va sola, a los DURA segundos)


# Encima de la cabeza de Johnny, centrado, subiendo y bajando un poco
func colocar_letrero() -> void:
	var en: Vector2 = johnny.get_global_transform_with_canvas().origin
	var sube := sin(desde * 4.0) * 2.0
	letrero.visible = true   # (vuelve a salir tras un cambio de sitio o una ventana)
	poner_latido(PISTAS[pista].latido)
	letrero.reset_size()
	letrero.position = (en + Vector2(-letrero.size.x / 2.0, -118.0 + sube)).round()
	letrero.modulate.a = clampf(desde / 0.25, 0.0, 1.0)


# Los avisos de la línea de abajo, una vez cada uno: el zombi de la llave al despertar y el primer tercio perdido
func mirar_avisos() -> void:
	if not "llave" in dicho:
		for z in zombis_despiertos():
			if z.has_meta("llave"):
				dicho.append("llave")
				partida.decir(Idioma.t("¡Ese zombi lleva la llave del %s!") % partida.nombre_jefa(), 3.5)
	if not "tercio" in dicho and johnny.tercios_vivos() < 3:
		dicho.append("tercio")
		Tutoriales.apuntar("tercios")
		partida.decir(Idioma.t("Has perdido un tercio de vida: ese ya no se cura con vendas, solo con un botiquín"), 5.0)


func zombis_despiertos() -> Array:
	return get_tree().get_nodes_in_group("zombis").filter(func(z):
		return is_instance_valid(z) and not z.get("dormido") and z.get("estado") != "muerto")


func lanzables_a_mano() -> int:
	var n := 0
	for k in partida.lanzables.cantidades:
		n += partida.lanzables.cantidades[k]
	return n


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


# La puerta a la que lleva la flecha: en la sala de mantenimiento, la del pasillo (si no hay zombis); en el pasillo,
# las escaleras con el jefe caído, la sala del jefe con la llave, o el apartamento sin limpiar más cercano (el fácil,
# antes que ninguno)
func destino() -> Node2D:
	var planta: Dictionary = partida.planta
	var sitio: Dictionary = planta.sitios[partida.aqui]
	var puertas: Array = partida.mapa.puertas
	if sitio.tipo == "mantenimiento":
		for i in sitio.salidas.size():
			if sitio.salidas[i].get("a", -1) == 0 and i < puertas.size():
				return puertas[i]
		return null
	if sitio.tipo != "pasillo":
		return null
	var mejor: Node2D = null
	var nota := INF
	for i in mini(sitio.salidas.size(), puertas.size()):
		var s: Dictionary = sitio.salidas[i]
		var vale := false
		if planta.jefa_muerta:
			vale = s.tipo == "escaleras"
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


# La flecha amarilla del suelo, con su borde oscuro, que respira
class Flecha extends Node2D:
	var t := 0.0

	func _ready() -> void:
		z_index = -1   # en el suelo, como los charcos

	func _process(delta: float) -> void:
		t += delta
		modulate.a = 0.65 + 0.35 * sin(t * 5.0)
		queue_redraw()

	func _draw() -> void:
		var avance := sin(t * 5.0) * 5.0
		var punta := PackedVector2Array([Vector2(24 + avance, 0), Vector2(-12 + avance, -20), Vector2(-3 + avance, 0),
			Vector2(-12 + avance, 20)])
		draw_colored_polygon(punta, Tema.AMARILLO)
		var borde := punta.duplicate()
		borde.append(punta[0])
		draw_polyline(borde, Tema.LINEA, 2.0)
