# El aspecto de los menús y del HUD, como el style.css del JS: la fuente pixel art, los botones de chapa con
# remaches, los paneles de metal oxidado y las pastillas del HUD. Todos los menús usan Tema.crear().
#
# Variantes (se ponen con theme_type_variation):
#   "BotonGrande"  el botón principal (JUGAR, Continuar...)
#   "BotonRojo"    la misma chapa, rojiza (Abandonar partida)
#   "Celda"        las casillas de la tabla de controles (Opciones)
#   "Pastilla"     las cajitas del HUD (arma, dinero, llave); "PastillaOn", la que está en la mano
#   "Titulo"       el título grande de un panel · "Sub" el texto gris de debajo
class_name Tema

const TINTA := Color("#d9d1bd")    # el color del texto: hueso sucio
const LINEA := Color("#0f0d17")    # contornos
const GRIS := Color("#9b93a0")
const METAL := Color("#2b2732")
const OXIDO := Color("#7a4a33")
const AMARILLO := Color("#ffd23f")
const VERDE := Color("#80ed99")
const ROJO := Color("#ff5d73")

const FUENTE := preload("res://assets/fuentes/zombie-scape-ui.ttf")
# La letra de los nombres de los jefes (su barra de vida y su presentación): Jersey 25, de Google Fonts, con licencia
# OFL (jersey-25-OFL.txt, que va con ella). Es pixel art a 25 (un píxel de su dibujo, uno de pantalla) y a 50
const FUENTE_JEFE := preload("res://assets/fuentes/jersey-25.ttf")
# Las letras que esas dos no traen salen de otra (poner_fuentes): el cirílico del ruso, de Ark Pixel de 16 px (la misma
# medida que la letra del juego; OFL, ark-pixel-OFL.txt), y el chino, de Fusion Pixel de 12 px (OFL, fusion-pixel-OFL.txt y
# fusion-pixel-licencias/). Las dos, sin suavizado (en su .import)
const FUENTE_CIRILICO := preload("res://assets/fuentes/ark-pixel-16.woff2")
const FUENTE_CHINO := preload("res://assets/fuentes/fusion-pixel-12-zh.woff2")
const BOTON := preload("res://assets/ui/boton-oscuro.png")
const PANEL := preload("res://assets/ui/panel-oscuro.png")

static var _tema: Theme


# Las letras de reserva para lo que la letra del juego no tiene: la cadena es letra del juego → Jersey 25 (los signos y las vocales
# con tilde que faltan) → la del idioma que se juega (en ruso, el cirílico; en chino, el chino). Los demás idiomas solo llevan la
# Jersey 25. La cadena va PLANA, las tres detrás de la letra del juego: si una letra de reserva cuelga de la Jersey 25 (que
# también lleva reservas), solo se alcanza a la Jersey 25 y las demás no salen. En el ordenador parecía que sí (Windows pone una
# letra del sistema para lo que falta), pero en la web, que no trae letras del sistema, salían cuadros (29 oct 2026).
# Las de reserva miden más de alto que la del juego (a 16: 22 contra 17): con un ajuste negativo por arriba y por abajo, la línea
# queda igual de alta. Se llama al montar el tema y cada vez que cambia el idioma (idioma.gd)
static var _jersey_de_respaldo: FontVariation


static func poner_fuentes() -> void:
	if _jersey_de_respaldo == null:
		# A la fuente le faltan · × < > … — y otros signos: los dibujaba con una letra del sistema, que mide más y hacía la
		# línea 5 px más alta y su texto más bajo. Ahora los saca de Jersey 25, con un píxel menos de bajada para que la
		# línea mida lo mismo que sin ellos (y que en la web, que no trae letras del sistema, también se vean)
		_jersey_de_respaldo = FontVariation.new()
		_jersey_de_respaldo.base_font = FUENTE_JEFE
		_jersey_de_respaldo.spacing_bottom = -1
	var cadena: Array[Font] = [_jersey_de_respaldo]
	var de_los_jefes: Array[Font] = []   # (los nombres de los jefes se escriben con la Jersey 25 sola: necesita su reserva)
	var propia := fuente_del_idioma(Idioma.actual)
	if propia != null:
		cadena.append(propia)
		de_los_jefes.append(fuente_del_idioma(Idioma.actual))
	var jefe: FontFile = FUENTE_JEFE   # (con la constante directamente no deja asignar)
	jefe.fallbacks = de_los_jefes
	var juego: FontFile = FUENTE
	juego.fallbacks = cadena


# La letra de un idioma que no escribe la del juego (null si la del juego basta): el cirílico, de Ark Pixel, y el chino, de Fusion Pixel,
# con el ajuste de altura (sube/baja, en píxeles) que las deja de la misma altura de línea que la del juego. También es la letra
# con la que el selector de Opciones escribe «Русский» y «简体中文», en cualquier idioma
static func fuente_del_idioma(codigo: String) -> Font:
	match codigo:
		"ru":
			return _con_altura(FUENTE_CIRILICO, -4, -1)
		"zh_CN":
			return _con_altura(FUENTE_CHINO, -5, 0)
	return null


static func _con_altura(base: Font, sube: int, baja: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = base
	v.spacing_top = sube
	v.spacing_bottom = baja
	return v


# ¿Tiene alguna de las fuentes del juego esa letra? (la prueba --letras comprueba así todas las traducciones)
static func tiene_letra(codigo: int) -> bool:
	var a: FontFile = FUENTE
	var b: FontFile = FUENTE_JEFE
	var c: FontFile = FUENTE_CIRILICO
	var d: FontFile = FUENTE_CHINO
	return a.has_char(codigo) or b.has_char(codigo) or c.has_char(codigo) or d.has_char(codigo)


static func crear() -> Theme:
	if _tema:
		return _tema
	var t := Theme.new()
	# La fuente es pixel art (un píxel = 1/16 de su tamaño): sin suavizado y a 16 o 32, para que se vea nítida (la de
	# los jefes, igual: sin suavizado)
	var fuente: FontFile = FUENTE
	for f: FontFile in [FUENTE, FUENTE_JEFE]:
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	poner_fuentes()   # (las letras de reserva: los signos y las de cada idioma)
	t.default_font = fuente
	t.default_font_size = 16

	t.set_color("font_color", "Label", TINTA)
	t.set_color("font_outline_color", "Label", LINEA)
	t.set_constant("outline_size", "Label", 4)

	# Títulos grandes y texto de explicación
	t.set_type_variation("Titulo", "Label")
	t.set_font_size("font_size", "Titulo", 32)
	t.set_constant("outline_size", "Titulo", 10)
	t.set_color("font_color", "Titulo", Color("#e6dec8"))
	t.set_type_variation("Sub", "Label")
	t.set_color("font_color", "Sub", GRIS)

	# Botones: la chapa estirada por el centro sin deformar los remaches de las esquinas
	var normal := _chapa(Color.WHITE)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", _chapa(Color(1.3, 1.25, 1.1)))
	t.set_stylebox("pressed", "Button", _chapa(Color(0.75, 0.75, 0.75)))
	t.set_stylebox("disabled", "Button", _chapa(Color(0.5, 0.5, 0.5, 0.75)))
	# El botón elegido (con el mando o el teclado): la chapa iluminada, igual que con el ratón encima
	t.set_stylebox("focus", "Button", _chapa(Color(1.3, 1.25, 1.1)))
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", Color("#e6dec8"))
	t.set_color("font_disabled_color", "Button", GRIS)
	t.set_color("font_outline_color", "Button", LINEA)
	t.set_constant("outline_size", "Button", 4)
	t.set_font_size("font_size", "Button", 16)
	t.set_constant("h_separation", "Button", 8)

	# Las casillas de la tabla de controles (Opciones): solo el texto; al pasar por encima o elegirlas,
	# una cajita de metal con el borde amarillo
	t.set_type_variation("Celda", "Button")
	var celda := _pastilla(AMARILLO)
	t.set_stylebox("normal", "Celda", StyleBoxEmpty.new())
	t.set_stylebox("hover", "Celda", celda)
	t.set_stylebox("focus", "Celda", celda)
	t.set_stylebox("pressed", "Celda", celda)
	t.set_color("font_color", "Celda", GRIS)

	t.set_type_variation("BotonGrande", "Button")
	t.set_font_size("font_size", "BotonGrande", 32)
	t.set_type_variation("BotonRojo", "Button")
	t.set_stylebox("normal", "BotonRojo", _chapa(Color(1.25, 0.7, 0.6)))
	t.set_stylebox("hover", "BotonRojo", _chapa(Color(1.6, 0.9, 0.75)))

	# Paneles de metal oxidado
	var panel := StyleBoxTexture.new()
	panel.texture = PANEL
	panel.set_texture_margin_all(46)
	panel.content_margin_left = 40
	panel.content_margin_right = 40
	panel.content_margin_top = 34
	panel.content_margin_bottom = 36
	t.set_stylebox("panel", "PanelContainer", panel)

	# Pastillas del HUD: cajita de metal con el borde oxidado
	t.set_type_variation("Pastilla", "PanelContainer")
	t.set_stylebox("panel", "Pastilla", _pastilla(OXIDO))
	t.set_type_variation("PastillaOn", "PanelContainer")
	t.set_stylebox("panel", "PastillaOn", _pastilla(AMARILLO))
	_tema = t
	return t


static func _chapa(color: Color) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = BOTON
	s.set_texture_margin_all(16)
	s.modulate_color = color
	s.content_margin_left = 26
	s.content_margin_right = 26
	s.content_margin_top = 10
	s.content_margin_bottom = 12
	return s


static func _pastilla(borde: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = METAL
	s.set_border_width_all(2)
	s.border_color = borde
	s.shadow_color = LINEA
	s.shadow_size = 2
	s.content_margin_left = 8
	s.content_margin_right = 10
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s


# Una fila "icono + texto" (para el HUD, las estadísticas y las listas)
static func icono_y_texto(icono: String, texto: String, tamano := 24) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	if icono != "":
		var imagen := TextureRect.new()
		imagen.texture = load("res://assets/ui/iconos/%s.png" % icono)
		imagen.custom_minimum_size = Vector2(tamano, tamano)
		imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		fila.add_child(imagen)
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(etiqueta)
	return fila
