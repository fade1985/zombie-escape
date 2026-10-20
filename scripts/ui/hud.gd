# El HUD de Johnny, en la franja de abajo de la pantalla (la del muro de abajo, 64 de alto), como el del JS
# (src/ui.js, updateHud; #hud en style.css). Así la barra de la portera y la de la horda, arriba, no se tapan:
#   - La barra de vida en su marco (barra-vida.png), partida en tres tercios. Los tercios perdidos se tapan
#     con rayas oscuras, porque ya no se curan. Encima, la vida en números.
#   - Sobre la barra, las balas del cargador: una por cada bala que cabe (las gastadas, apagadas) y la
#     reserva. Al recargar, las gastadas parpadean. Más apagadas si lleva en la mano el arma cuerpo a cuerpo.
#   - Al lado, las dos armas (la que está en la mano, con el borde amarillo), los molotovs y las granadas que
#     le quedan (el que se lanza ahora, con el borde amarillo), la mochila (casillas llenas), los dólares y la
#     llave de la portera, si la lleva.
# Cada fotograma mira cómo está Johnny ("johnny") y lo que lleva la partida ("partida").
extends Control

const MARCO := preload("res://assets/ui/barra-vida.png")
const BALA := preload("res://assets/ui/iconos/bala.png")
const CARTUCHO := preload("res://assets/ui/iconos/cartucho.png")
const ANCHO := 236.0      # la barra a tamaño 1 (el dibujo mide 236×26)
const ALTO := 26.0
# El hueco de dentro del marco, por donde se ve la sangre (en partes de la barra, como en style.css)
const HUECO := Rect2(0.046 * ANCHO, 0.28 * ALTO, 0.908 * ANCHO, 0.44 * ALTO)
const FRANJA := 64.0      # el alto de la franja de abajo (el grosor del muro de abajo)
const ICONOS := {"mp5": "pistola"}   # las armas sin icono propio usan el de otra

var johnny: Node2D
var partida: Node

var fila := HBoxContainer.new()
var barra := Control.new()
var cuerpo: PanelContainer
var fuego: PanelContainer
var dinero: PanelContainer
var mochila: PanelContainer
var molotov: PanelContainer
var granada: PanelContainer
var creada: PanelContainer   # la arrojadiza creada elegida (o la primera que quede), si tiene alguna
var llave: PanelContainer
var antes := {}           # lo que se pintó la última vez (para no rehacer las pastillas en cada fotograma)


func _ready() -> void:
	theme = Tema.crear()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.add_theme_constant_override("separation", 8)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fila)
	barra.custom_minimum_size = Vector2(ANCHO, ALTO)
	barra.draw.connect(pintar_barra)
	fila.add_child(barra)
	cuerpo = pastilla(fila)
	fuego = pastilla(fila)
	molotov = pastilla(fila)
	granada = pastilla(fila)
	creada = pastilla(fila)
	mochila = pastilla(fila)
	dinero = pastilla(fila)
	llave = pastilla(fila)


func pastilla(fila: HBoxContainer) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = "Pastilla"
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(p)
	return p


# Cambia lo que hay dentro de una pastilla (solo si ha cambiado)
func poner(p: PanelContainer, icono: String, texto: String, on := false) -> void:
	var clave := "%s|%s|%s" % [icono, texto, on]
	if antes.get(p) == clave:
		return
	antes[p] = clave
	for hijo in p.get_children():
		hijo.queue_free()
	p.add_child(Tema.icono_y_texto(icono, texto, 22))
	p.theme_type_variation = "PastillaOn" if on else "Pastilla"


func _process(_delta: float) -> void:
	# en la franja de abajo (las balas se pintan por encima de la barra de vida; debajo queda la línea de ayuda)
	fila.position = Vector2(14, roundf(get_viewport_rect().size.y - FRANJA / 2.0 - fila.size.y / 2.0) - 5.0)
	if johnny == null:
		return
	var h: Dictionary = johnny.huecos
	var c: Dictionary = Armas.datos(h.cuerpo)
	var f: Dictionary = Armas.datos(h.fuego)
	poner(cuerpo, Objetos.icono(h.cuerpo), c.nombre, johnny.mano == "cuerpo")
	poner(fuego, Objetos.icono(h.fuego), f.nombre, johnny.mano == "fuego")
	var lz: Lanzables = partida.lanzables
	poner(molotov, "molotov", str(lz.cantidades.molotov), lz.tipo == "molotov")
	poner(granada, "granada", str(lz.cantidades.granada), lz.tipo == "granada")
	var otras: Array = lz.tipos().slice(2)
	creada.visible = not otras.is_empty()
	if creada.visible:
		var k: String = lz.tipo if lz.tipo in otras else otras[0]
		poner(creada, Objetos.icono(Recetas.LISTA[k].icono), str(lz.cuantas(k)), lz.tipo == k)
	poner(mochila, "mochila", "%d/%d" % [Objetos.casillas(partida.mochila).size(), Objetos.MOCHILA])
	poner(dinero, "billete", "$%d" % partida.cartera())
	llave.visible = partida.planta.tiene_llave
	if llave.visible:
		poner(llave, "llave", partida.nombre_jefa())
	barra.queue_redraw()


func pintar_barra() -> void:
	var vida: float = johnny.vida
	var maxima: float = johnny.stats.vida_max
	# El fondo del hueco y la sangre
	barra.draw_rect(HUECO, Color("#1a1620"))
	var lleno := HUECO
	lleno.size.x *= clampf(vida / maxima, 0.0, 1.0)
	barra.draw_rect(lleno, Color("#8a1f1a"))
	barra.draw_rect(Rect2(lleno.position, Vector2(lleno.size.x, lleno.size.y * 0.45)), Color("#c24a38"))
	barra.draw_rect(Rect2(lleno.position + Vector2(0, lleno.size.y * 0.8), Vector2(lleno.size.x, lleno.size.y * 0.2)), Color("#6a1512"))
	# Las dos rayas que separan los tercios
	for i in [1, 2]:
		barra.draw_rect(Rect2(HUECO.position.x + HUECO.size.x * i / 3.0 - 1, HUECO.position.y, 2, HUECO.size.y), Color("#1a1620"))
	# Los tercios perdidos, tapados con rayas oscuras en diagonal
	var perdido: float = HUECO.size.x * (3 - johnny.tercios) / 3.0
	if perdido > 0.0:
		var x0 := HUECO.end.x - perdido
		var y0 := HUECO.position.y
		var y1 := HUECO.end.y
		barra.draw_rect(Rect2(x0, y0, perdido, y1 - y0), Color("#2a2230"))
		var alto := y1 - y0
		var x := x0 - alto
		while x < HUECO.end.x:
			# una raya de abajo a la izquierda a arriba a la derecha, recortada al trozo tapado
			var a := Vector2(x, y1)
			var b := Vector2(x + alto, y0)
			if a.x < x0:
				a = Vector2(x0, y1 - (x0 - x))
			if b.x > HUECO.end.x:
				b = Vector2(HUECO.end.x, y0 + (b.x - HUECO.end.x))
			if b.x > a.x:
				barra.draw_line(a, b, Color("#121016"), 2.0)
			x += 6.0
	# El marco por encima, y la vida en números
	barra.draw_texture_rect(MARCO, Rect2(0, 0, ANCHO, ALTO), false)
	var fuente := Tema.FUENTE
	var texto := "%d / %d" % [ceili(vida), roundi(maxima)]
	if johnny.escudo > 0.0:
		texto += "  escudo %d" % ceili(johnny.escudo)   # Acero
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var donde := Vector2((ANCHO - ancho) / 2.0, ALTO / 2.0 + 5)
	barra.draw_string_outline(fuente, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Tema.LINEA)
	barra.draw_string(fuente, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f0e8d4"))
	pintar_balas()


# Las balas del cargador, en fila encima de la barra
func pintar_balas() -> void:
	var w: Dictionary = Armas.datos(johnny.huecos.fuego)
	var lejos: bool = johnny.mano != "fuego"
	var parpadeo: bool = johnny.recargando > 0.0 and int(Time.get_ticks_msec() / 200) % 2 == 0
	var tam := Vector2(5, 10) if w.cargador > 16 else Vector2(10, 20)   # las del MP5, más pequeñas para que quepan
	var hueco := 2.0
	var x := HUECO.position.x
	var abajo := -4.0
	for i in w.cargador:
		var color := Color.WHITE
		if i >= johnny.balas:
			color = Color(0.5, 0.5, 0.5, 0.6 if parpadeo else 0.22)   # gastada
		if lejos:
			color.a *= 0.5
		barra.draw_texture_rect(CARTUCHO if w.cartucho else BALA, Rect2(x, abajo - tam.y, tam.x, tam.y), false, color)
		x += tam.x + hueco
	# La reserva: las balas de repuesto que lleva (en naranja si ya no le queda ninguna)
	var donde := Vector2(x + 4, abajo - 2)
	var texto := "+∞" if w.get("sin_municion", false) else "+%d" % johnny.reserva
	var color_texto := Color("#f0e8d4") if johnny.reserva > 0 or texto == "+∞" else Color("#ff9f1c")
	color_texto.a = 0.5 if lejos else 1.0
	barra.draw_string_outline(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(Tema.LINEA, color_texto.a))
	barra.draw_string(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color_texto)
