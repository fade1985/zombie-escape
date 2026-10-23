# La presentación de un jefe: al aparecer, la pelea se para un momento, la cámara hace un zoom que lo enfoca solo a
# él mientras suelta su grito (la pose y el rugido, sin ninguna frase escrita: con el zoom no se leería), entran dos
# franjas negras de cine y sale su nombre en grande; luego la cámara vuelve y empieza la pelea. La monta partida.gd
# al sacar al jefe (presentar); en la partida de prueba se salta, salvo en su prueba (--captura --presentacion).
# Mientras dura: Johnny, los acompañantes y los demás zombis se quedan quietos (y Johnny no puede recibir daño); el
# HUD, el minimapa y la barra del jefe se esconden; Johnny se calla (lo que estuviera diciendo, como el aviso de la
# habitación al entrar, y lo que fuera a decir: partida.decir lo deja en "pendiente") y lo dice al acabar; el jefe se
# pone en su pose de gritar (su estado "grito", el mismo de cuando se enfada, que también lo deja sin recibir daño) y
# un foco lo alumbra (menos al Gymbro: SIN_FOCO, se ve con la luz de su gimnasio); al acabar echa a andar como siempre.
# Los jefes que entran a su manera (la Modista, escondida
# entre los maniquíes: no empiezan en "andar") se presentan sin tocarlos ni enfocarlos: solo las franjas, el nombre y
# el rugido. partida.gd no deja pausar ni abrir el inventario mientras tanto ("activa"), ni las mutaciones actúan
# (mutaciones.gd); al acabar, ellas y los acompañantes (aliado.gd: calma) tardan 1 s más en atacar. El desplazamiento
# de la cámara va por Temblor.desplazamiento (si se tocara el offset de la cámara, el temblor lo borraría).
class_name Presentacion
extends Control

const ZOOM := 2.0            # lo que acerca la cámara (2: cada píxel del dibujo ocupa el doble, sin emborronarse)
const ACERCAR := 0.45        # lo que tarda la cámara en acercarse (y en volver)
const GRITO := 0.45          # a los cuántos segundos grita el jefe (cuando la cámara ya está encima)
const QUIETO := 1.75         # cuándo empieza a volver la cámara
const DURA := 2.2            # cuándo acaba todo y sigue la pelea
const FRANJA := 56.0         # el alto de las franjas negras, en píxeles de pantalla
const CUERPO := 24.0         # la cámara enfoca un poco por encima del pie del jefe, para encuadrar su cuerpo
const NOMBRE_ENTRA := 0.25   # lo que tarda el nombre en aparecer
const LUZ_RADIO := 240.0     # el foco que alumbra al jefe mientras tanto (en la penumbra o a oscuras no se le vería)
const LUZ_TEXTURA := preload("res://escenas/luces/luz_suave.tres")
const SIN_FOCO := ["gymbro"]   # los jefes a los que no se les pone el foco: se ven con la luz de su sala (el gimnasio tiene luces propias)

var arriba: ColorRect        # las franjas negras
var abajo: ColorRect
var nombre: Label            # el nombre del jefe, en grande
var activa := false          # mientras dura
var pendiente: Array = []    # lo que Johnny se calla mientras tanto ([texto] o [texto, segundos]): lo dice al acabar


func preparar(partida: Node) -> void:
	name = "Presentacion"
	theme = Tema.crear()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	arriba = franja()
	abajo = franja()
	nombre = Label.new()
	nombre.theme_type_variation = "Titulo"
	nombre.add_theme_font_override("font", Tema.FUENTE_JEFE)   # la letra de los jefes, como en su barra (al doble)
	nombre.add_theme_font_size_override("font_size", 50)
	nombre.add_theme_color_override("font_color", Tema.AMARILLO)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nombre.modulate.a = 0.0
	add_child(nombre)
	hide()
	var capa: Node = partida.get_node("Pantalla")
	capa.add_child(self)
	capa.move_child(self, partida.negro.get_index())   # por debajo del fundido a negro


# Si la partida se cierra o se reinicia a medias, que la cámara de la siguiente no nazca desplazada
func _exit_tree() -> void:
	Temblor.desplazamiento = Vector2.ZERO


# Una franja negra de cine (su sitio y su tamaño se ponen al empezar, con la pantalla de verdad)
func franja() -> ColorRect:
	var f := ColorRect.new()
	f.color = Color.BLACK
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(f)
	return f


# La presentación entera: se llama al sacar al jefe y se espera a que acabe (await). "texto_nombre" es lo que pone en
# su barra de vida
func presentar(partida: Node, jefa: Node2D, texto_nombre: String) -> void:
	if activa or not is_instance_valid(jefa) or not partida.johnny.vivo or partida.terminada:
		return
	activa = true
	var johnny: Node2D = partida.johnny
	var camara: Camera2D = johnny.get_node("Camara")
	var barra: Control = partida.get_node("Pantalla/Jefa")
	var hud: Array = [partida.get_node_or_null("Pantalla/HUD"), partida.get_node_or_null("Pantalla/Minimapa"), partida.lugar]
	# todo quieto: Johnny (sin poder recibir daño; su cuenta atrás se para con él, así que al acabar se le devuelve la
	# que tenía), los acompañantes y los demás zombis; el jefe sigue (va a gritar)
	var quietos: Array = []
	for n in [johnny] + partida.get_tree().get_nodes_in_group("aliados") + partida.get_tree().get_nodes_in_group("zombis"):
		if n != jefa and is_instance_valid(n) and n.is_physics_processing():
			n.set_physics_process(false)
			quietos.append(n)
	var inv_antes: float = johnny.invulnerable
	johnny.invulnerable = DURA + 1.0
	if johnny.has_method("quedarse_quieto"):
		johnny.quedarse_quieto()
	# un fotograma: que corra lo que el jefe deja para después de nacer (la Modista se muda a su maniquí y se esconde;
	# la barra de vida se enseña), y así se sabe dónde está y cómo entra
	await get_tree().process_frame
	if not is_instance_valid(jefa) or jefa.get("estado") == "muerto" or not johnny.vivo or partida.terminada:
		soltar(partida, quietos, johnny, inv_antes)
		return
	barra.hide()
	for h in hud:
		if h:
			h.hide()
	# lo que esté diciendo Johnny (lo de la habitación, nada más entrar: «¡La habitación está en llamas!…») se calla y
	# lo dice al acabar
	var aviso: Label = partida.aviso
	if aviso.modulate.a > 0.0 and aviso.text != "":
		pendiente = [aviso.text]
		if partida.aviso_tween:
			partida.aviso_tween.kill()
		aviso.modulate.a = 0.0
	# los que empiezan andando se ponen a gritar desde ya (sin recibir daño ni hacerlo) y se les enfoca; los que entran
	# a su manera (la Modista, escondida), ni se tocan ni se enfocan
	var normal: bool = jefa.get("estado") == "andar"
	var foco: PointLight2D = null
	if normal:
		if jefa.has_method("cambiar"):
			jefa.cambiar("grito")
		if not partida.planta.jefe in SIN_FOCO:
			foco = PointLight2D.new()
			foco.texture = LUZ_TEXTURA
			foco.texture_scale = LUZ_RADIO / 128.0
			foco.color = Color(1.0, 0.95, 0.85)
			foco.energy = 0.9
			foco.range_item_cull_mask = Luz.TODAS
			foco.position = Vector2(0, -40)
			jefa.add_child(foco)
	# las franjas y el nombre, al tamaño de la pantalla de verdad (la ventana puede ser más ancha que la base)
	var pantalla := get_viewport_rect().size
	arriba.size = Vector2(pantalla.x, FRANJA)
	abajo.size = Vector2(pantalla.x, FRANJA)
	nombre.position = Vector2(0, pantalla.y - FRANJA - 150)   # (por encima del aviso de abajo)
	nombre.size = Vector2(pantalla.x, 64)
	nombre.text = texto_nombre
	nombre.modulate.a = 0.0
	arriba.position.y = -FRANJA
	abajo.position.y = pantalla.y
	show()
	# la cámara: de donde descansará ya acercada (Johnny, recortado a los límites del mapa; no de donde está ahora,
	# que puede venir deslizándose desde la puerta) hasta el jefe, recortado igual
	var medio := camara.get_viewport_rect().size / (2.0 * ZOOM)   # (lo que ve la cámara ya acercada, a cada lado)
	var meta := Vector2(clampf(jefa.global_position.x, camara.limit_left + medio.x, camara.limit_right - medio.x),
		clampf(jefa.global_position.y - CUERPO, camara.limit_top + medio.y, camara.limit_bottom - medio.y))
	var desde := Vector2(clampf(johnny.global_position.x, camara.limit_left + medio.x, camara.limit_right - medio.x),
		clampf(johnny.global_position.y, camara.limit_top + medio.y, camara.limit_bottom - medio.y))
	var ida := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if normal:
		ida.tween_property(camara, "zoom", Vector2(ZOOM, ZOOM), ACERCAR)
		ida.tween_property(Temblor, "desplazamiento", meta - desde, ACERCAR)
	ida.tween_property(arriba, "position:y", 0.0, ACERCAR)
	ida.tween_property(abajo, "position:y", pantalla.y - FRANJA, ACERCAR)
	await get_tree().create_timer(GRITO, false).timeout
	# el grito: el rugido, sin frase escrita (la pose ya la tiene, y le dura desde aquí 1,4 s más, hasta casi el
	# final); y el nombre
	if normal and is_instance_valid(jefa):
		jefa.set("t", 0.0)
	Sonido.tocar("rugido")
	create_tween().tween_property(nombre, "modulate:a", 1.0, NOMBRE_ENTRA)
	await get_tree().create_timer(QUIETO - GRITO, false).timeout
	# la vuelta: la cámara a su sitio, las franjas fuera y el nombre se va
	var vuelta := create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if normal:
		vuelta.tween_property(camara, "zoom", Vector2.ONE, ACERCAR)
		vuelta.tween_property(Temblor, "desplazamiento", Vector2.ZERO, ACERCAR)
	vuelta.tween_property(arriba, "position:y", -FRANJA, ACERCAR)
	vuelta.tween_property(abajo, "position:y", pantalla.y, ACERCAR)
	vuelta.tween_property(nombre, "modulate:a", 0.0, ACERCAR)
	await get_tree().create_timer(DURA - QUIETO, false).timeout
	camara.zoom = Vector2.ONE
	Temblor.desplazamiento = Vector2.ZERO
	hide()
	if is_instance_valid(foco):
		foco.queue_free()
	for h in hud:
		if h:
			h.show()
	soltar(partida, quietos, johnny, inv_antes)
	if is_instance_valid(jefa) and jefa.get("estado") != "muerto":
		barra.show()


# Se acaba: todos vuelven a moverse (los acompañantes, sin atacar hasta pasado el mismo respiro que las mutaciones),
# Johnny recupera su cuenta de invulnerabilidad (al menos un respiro) y dice lo que se ha callado
func soltar(partida: Node, quietos: Array, johnny: Node2D, inv_antes: float) -> void:
	for n in quietos:
		if is_instance_valid(n):
			n.set_physics_process(true)
			if n is Aliado:
				n.calma = Mutaciones.TRAS_PRESENTACION
	if is_instance_valid(johnny):
		johnny.invulnerable = maxf(inv_antes, 0.3)
	activa = false
	if not pendiente.is_empty() and is_instance_valid(johnny) and johnny.vivo and not partida.terminada:
		partida.callv("decir", pendiente)   # (con sus segundos, si los dijo)
	pendiente = []
