# El aviso de fotosensibilidad (11 nov, a petición del dueño): una pantalla negra con el aviso de que el juego tiene
# destellos y luces que parpadean. Sale encima del menú principal (menu_principal.gd) cada vez que se abre el juego, una
# sola vez (no al volver al menú desde una partida ni al cambiar de idioma: «visto»). Cualquier tecla, clic, toque o botón
# del mando la quita, como el relato (relato.gd), salvo las primeras décimas (ESPERA), para que nadie se la salte sin
# querer. Va por _input, antes que nadie: lo que se pulsa no llega al menú de detrás.
# En las pruebas (--captura) no sale, salvo en la suya (--aviso, pruebas/prueba_aviso.gd).
class_name AvisoLuces
extends CanvasLayer

signal cerrado

const ANCHO := 760.0      # lo más anchos que son los textos (se parten solos si no caben)...
const MARGEN := 30.0      # ...y, en una pantalla estrecha, lo que dejan a cada lado
const ESPERA := 0.8       # segundos que no hace caso al salir
const FUNDIDO := 0.4      # lo que tarda en irse
const NO_CUENTAN := [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_F11]   # (como en relato.gd)

static var visto := false   # ya ha salido desde que se abrió el juego

var fondo: ColorRect
var abierta := 0.0


# Lo pone encima del menú si aún no ha salido. Devuelve el aviso, o null si no toca
static func poner(dueno: Node) -> AvisoLuces:
	if visto:
		return null
	visto = true
	var a := AvisoLuces.new()
	dueno.add_child(a)
	return a


func _ready() -> void:
	layer = 14   # encima de todo lo del menú
	process_mode = Node.PROCESS_MODE_ALWAYS
	fondo = ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.theme = Tema.crear()
	add_child(fondo)
	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.add_child(centro)
	var columna := VBoxContainer.new()
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.custom_minimum_size.x = minf(ANCHO, get_viewport().get_visible_rect().size.x - 2.0 * MARGEN)
	columna.add_theme_constant_override("separation", 20)
	centro.add_child(columna)
	var titulo := Label.new()
	titulo.text = Idioma.t("Aviso de fotosensibilidad")
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.add_theme_color_override("font_color", Tema.AMARILLO)
	columna.add_child(titulo)
	for texto in [
		Idioma.t("Este juego tiene destellos, luces que parpadean y explosiones que pueden provocar ataques epilépticos a personas con epilepsia fotosensible."),
		Idioma.t("Si tú o alguien de tu familia ha tenido alguna vez un ataque epiléptico, consulta a un médico antes de jugar."),
		Idioma.t("Deja de jugar enseguida si notas mareo, visión borrosa, tics en los ojos o en la cara, movimientos que no controlas o desorientación."),
	]:
		var l := Label.new()
		l.text = texto
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		columna.add_child(l)
	var pie := Label.new()
	pie.theme_type_variation = "Sub"
	pie.text = como_seguir()
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pie.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pie.position.y = -40.0
	fondo.add_child(pie)


# Lo que se pulsa para seguir, según con qué se juegue (como en relato.gd)
func como_seguir() -> String:
	if Tactil.activo:
		return Idioma.t("Toca la pantalla para continuar")
	if Controles.con_mando:
		return Idioma.t("Pulsa cualquier botón para continuar")
	return Idioma.t("Pulsa cualquier tecla para continuar")


func _process(delta: float) -> void:
	abierta += delta


# Una tecla, un clic (no la rueda), un toque o un botón del mando recién pulsados
func es_pulsacion(evento: InputEvent) -> bool:
	if evento is InputEventKey:
		return evento.pressed and not evento.echo and not evento.alt_pressed and not evento.keycode in NO_CUENTAN
	if evento is InputEventMouseButton:
		return evento.pressed and evento.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	return (evento is InputEventScreenTouch or evento is InputEventJoypadButton) and evento.pressed


func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion or evento is InputEventScreenDrag:
		get_viewport().set_input_as_handled()   # (que los botones de detrás no den su saltito)
		return
	if not es_pulsacion(evento):
		return
	get_viewport().set_input_as_handled()
	if abierta >= ESPERA:
		cerrar()


func cerrar() -> void:
	set_process(false)
	set_process_input(false)
	cerrado.emit()
	var tween := fondo.create_tween()
	tween.tween_property(fondo, "modulate:a", 0.0, FUNDIDO)
	tween.tween_callback(queue_free)
