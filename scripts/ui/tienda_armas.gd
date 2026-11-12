# La tienda de armas del ordenador (ARMAS.EXE, en ordenador.gd): la misma chapa oscura que el árbol de talentos
# (chapa.gd), con lo ahorrado arriba a la izquierda y todo a la vez, sin desplazarse.
#
# A la izquierda, una fila por grupo (Cuerpo a cuerpo, A distancia, Especiales y Arrojables) y en cada una sus casillas:
# el icono (el precio sale en la ficha). Lo que llevas, con el borde verde (sin letrero), los arrojables que ya no te
# caben, «LLENO», y lo que no puedes pagar sale apagado.
#
# A la derecha, una ficha fija con lo elegido: su nombre y su grupo, el dibujo en grande, unos medidores de 10
# cuadraditos (cada uno comparado con el arma que más tiene de eso), qué hace y el botón «Comprar» con el precio. Sin nada
# elegido (al abrir con el ratón), la ficha dice que se pase por un arma (cómo va la tienda lo cuenta su tutorial, la
# primera vez: Tutoriales "tienda"); con el regalo de bienvenida sin coger, «¡COMPRA UN ARMA!» en grande.
#
# El regalo de bienvenida (Guardado "regalo_cogido"; desde el 10 nov Johnny ya no empieza con la pistola: Armas.SIEMPRE):
# la primera pistola es gratis, una sola vez en todo el juego. Hasta cogerla, su casilla lleva un «!» y su botón dice
# «Regalo de bienvenida» en vez del precio; después cuesta lo de siempre (Armas.PRECIOS).
#
# Lo elegido es, con el ratón, la última casilla por la que ha pasado (y se queda al ir hacia «Comprar»); con el teclado,
# el mando o el dedo, la marcada. Con el ratón, el teclado o el mando se compra al pulsar la casilla; con el dedo, el
# primer toque solo la enseña y el segundo compra (o «Comprar», que compra a la primera). Todo se dibuja con código
# (_draw); encima de cada casilla hay un botón transparente, "b_<id>", que es el que se marca y se pulsa
extends Control

const PLACA := preload("res://scripts/ui/chapa.gd")
const INVENTARIO := preload("res://scripts/ui/inventario.gd")   # lo que hace cada cosa (QUE_HACE)
const VERDE := Color("#7fa86a")      # lo que llevas y lo lleno
const VERDE_BORDE := Color("#5f8a4f")
const ANCHO_FICHA := 250
const CASILLA := 62                  # lo más grande que es una casilla (si no cabe, menos)
const HUECO := 6                     # entre casilla y casilla
const TITULO := 24                   # lo alto del título de cada grupo, con su raya
const MEDIDOR := 18                  # lo alto de cada medidor de la ficha
const TAM_LISA := 15                 # la letra lisa (Rubik) de debajo del dibujo: los medidores y qué hace (12 nov)
const ALTO_BOTON := 40
# Los grupos, en orden: [familia (Armas.familia; "arrojable" para los de Lanzables), título]
# [traducir]
const GRUPOS := [
	["cuerpo", "Cuerpo a cuerpo"],
	["distancia", "A distancia"],
	["especial", "Especiales"],
	["arrojable", "Arrojables"],
]
# [/traducir]

# Cómo se está moviendo el jugador por la pantalla: "raton" o "foco" (el teclado o el mando). Se queda al volver a montar
# la ventana después de comprar
static var modo := "raton"

var ordenador: Node
var s: Dictionary                    # el guardado
var filas := []                      # una por grupo: [familia, título, [ids]]
var botones := {}                    # id → su botón (la casilla)
var casillas := {}                   # id → su recuadro
var titulos := []                    # [y, título] de cada grupo
var comprar: Button                  # el botón «Comprar» de la ficha
var ficha := Rect2()
var ficha_id := ""                   # lo que enseña la ficha ("" = cómo va la tienda)
var ficha_desde := 0.0               # desde cuándo (en s): un toque del dedo justo al elegirlo no compra
var listo := {}                      # id → si al pulsarlo ya enseñaba su ficha (con el dedo, el segundo toque)
var maximos := {}                    # "tipo/medida" → lo más que tiene de eso un arma de la tienda (los medidores)


# "elegido": lo que enseña la ficha al abrir ("" = cómo va la tienda; después de comprar, lo comprado)
func montar(o: Node, guardado: Dictionary, elegido := "") -> void:
	ordenador = o
	s = guardado
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 400)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var armas := Armas.PRECIOS.keys()
	armas.sort_custom(func(a, b): return Armas.PRECIOS[a] < Armas.PRECIOS[b])
	for g in GRUPOS:
		var ids: Array = Lanzables.PRECIOS.keys() if g[0] == "arrojable" else armas.filter(func(id): return Armas.familia(id) == g[0])
		filas.append([g[0], Idioma.t(g[1]), ids])
		for id in ids:
			var b := boton_transparente("b_" + id, Vector2(CASILLA, CASILLA))
			b.button_down.connect(func(): listo[id] = ficha_id == id and ahora() - ficha_desde > 0.25)
			botones[id] = b
	comprar = boton_transparente("b_comprar", Vector2(ANCHO_FICHA - 16, ALTO_BOTON))
	comprar.focus_mode = Control.FOCUS_NONE   # (la marca se queda en la casilla: es lo que se compra)
	comprar.pressed.connect(func():
		if ficha_id != "":
			comprar_esto(ficha_id))
	for b in [comprar]:
		b.mouse_entered.connect(queue_redraw)
		b.mouse_exited.connect(queue_redraw)
		b.button_down.connect(queue_redraw)
		b.button_up.connect(queue_redraw)
	calcular_maximos()
	ficha_id = elegido if botones.has(elegido) else ""
	ficha_desde = ahora()
	resized.connect(colocar)


func boton_transparente(nombre: String, tam: Vector2) -> Button:
	var b := Button.new()
	b.name = nombre
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.size = tam
	for e in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(e, StyleBoxEmpty.new())
	b.focus_entered.connect(actualizar_ficha)
	b.focus_exited.connect(actualizar_ficha)
	add_child(b)
	return b


func ahora() -> float:
	return Time.get_ticks_msec() / 1000.0


# ── Los medidores ──

# Lo que mide cada uno, según lo que sea: [nombre, medida]. Las armas cuerpo a cuerpo, su daño, su rapidez, lo lejos que
# llegan y lo ancho del golpe; las de fuego, su daño, su rapidez, su cargador (o su depósito) y lo lejos que llegan; los
# arrojables, su daño y lo grande que es lo que dejan
# (los nombres se traducen al dibujarlos)
# [traducir]
func medidas(id: String) -> Array:
	if Lanzables.PRECIOS.has(id):
		return [["Daño", "dano"], ["Área", "radio"]]
	var w: Dictionary = Armas.DATOS[id]
	if w.tipo == "cuerpo":
		return [["Daño", "dano"], ["Rapidez", "ritmo"], ["Alcance", "alcance"], ["Abanico", "arco"]]
	return [["Daño", "dano"], ["Rapidez", "ritmo"], ["Depósito", "deposito"] if w.has("deposito") else ["Cargador", "cargador"],
		["Alcance", "alcance"]]
# [/traducir]


# Cuánto tiene de esa medida. El daño de un arma es el de cada disparo o golpe (la escopeta, con todos sus perdigones;
# las de depósito, el de cada trago de su chorro); el del molotov, su golpe y todo lo que quema su fuego
func valor(id: String, medida: String) -> float:
	if Lanzables.PRECIOS.has(id):
		var l: Dictionary = Lanzables.DATOS[id]
		if medida == "dano" and l.has("quema"):
			return l.golpe + l.quema * l.vida
		return float(l.get(medida, 0))
	var w: Dictionary = Armas.DATOS[id]
	if medida == "dano":
		return w.dano / w.ritmo if w.has("deposito") else float(w.dano * w.get("perdigones", 1))
	return float(w.get(medida, 0))


func tipo_de(id: String) -> String:
	return "arrojable" if Lanzables.PRECIOS.has(id) else Armas.DATOS[id].tipo


func calcular_maximos() -> void:
	for id in botones:
		for m in medidas(id):
			var clave: String = tipo_de(id) + "/" + m[1]
			maximos[clave] = maxf(maximos.get(clave, 0.0), valor(id, m[1]))


# De 1 a 10 cuadraditos (el que más tiene, los 10)
func cuadraditos(id: String, medida: String) -> int:
	var tope: float = maximos.get(tipo_de(id) + "/" + medida, 0.0)
	return 0 if tope <= 0.0 else clampi(ceili(valor(id, medida) / tope * 10.0 - 0.001), 1, 10)


# ── Cómo está cada cosa ──

func precio(id: String) -> int:
	if es_regalo(s, id):
		return 0
	return Supervivientes.precio(Lanzables.PRECIOS[id] if Lanzables.PRECIOS.has(id) else Armas.PRECIOS[id])


# Si esto es el regalo de bienvenida aún sin coger (la pistola gratis; ver arriba). Lo usa también ordenador.comprar_arma
static func es_regalo(guardado: Dictionary, id: String) -> bool:
	return id == "pistola" and not guardado.regalo_cogido


# "lleva" (un arma en la mano o de repuesto), "lleno" (un arrojable que ya no cabe), "reto" (el reto sin munición no deja
# llevar arrojables), "caro" (no te llega) o "" (se puede comprar)
func estado(id: String) -> String:
	var partida: Node = ordenador.partida
	if Lanzables.PRECIOS.has(id):
		if not partida.lanzables.cabe(id):
			return "lleno"
		if Reto.sin_municion():
			return "reto"
	else:
		var tipo: String = Armas.DATOS[id].tipo
		if partida.johnny.huecos[tipo] == id or partida.repuesto(tipo) == id:
			return "lleva"
	return "caro" if s.dolares < precio(id) else ""


func nombre(id: String) -> String:
	return Lanzables.uno(id) if Lanzables.PRECIOS.has(id) else Armas.nombre(id)


func grupo(id: String) -> String:
	for f in filas:
		if id in f[2]:
			return f[1]
	return ""


# ── Dónde va cada cosa (al cambiar de tamaño) ──

func colocar() -> void:
	if size.x < ANCHO_FICHA * 2 or size.y < 200:
		return   # (aún sin su tamaño de verdad)
	var margen := 10.0
	var arriba := PLACA.ARRIBA + 4.0
	ficha = Rect2(size.x - margen - ANCHO_FICHA, arriba, ANCHO_FICHA, size.y - arriba - margen)
	var ancho_izquierda := ficha.position.x - margen * 2 - 6
	var mas_ancha := 0
	for f in filas:
		mas_ancha = maxi(mas_ancha, f[2].size())
	var lado := floorf(minf(CASILLA, minf((ancho_izquierda + HUECO) / mas_ancha - HUECO,
		(size.y - arriba - margen) / filas.size() - TITULO - HUECO)))
	var y := arriba
	titulos.clear()
	for f in filas:
		titulos.append([y, f[1]])
		for i in f[2].size():
			var r := Rect2(margen + 4 + i * (lado + HUECO), y + TITULO, lado, lado)
			casillas[f[2][i]] = r
			botones[f[2][i]].position = r.position
			botones[f[2][i]].size = r.size
		y += TITULO + lado + HUECO
	comprar.size = Vector2(ANCHO_FICHA - 16, ALTO_BOTON)
	comprar.position = Vector2(ficha.position.x + 8, ficha.end.y - 8 - ALTO_BOTON)
	comprar.visible = ficha_id != ""
	poner_vecinos()
	actualizar_ficha()
	queue_redraw()


# Con el teclado o el mando, a qué casilla se pasa con cada flecha: la más cercana en esa dirección. Arriba del todo, a la
# «i»; abajo del todo y a la derecha del todo, no se mueve (si no, Godot buscaría solo y se iría a los iconos del
# escritorio). A la izquierda de la primera columna sí se sale a ellos, como en los demás programas
func poner_vecinos() -> void:
	var sitios := {}   # botón → su centro
	for id in botones:
		sitios[botones[id]] = casillas[id].get_center()
	for b: Button in sitios:
		for lado in [[Vector2.UP, "focus_neighbor_top"], [Vector2.DOWN, "focus_neighbor_bottom"],
				[Vector2.LEFT, "focus_neighbor_left"], [Vector2.RIGHT, "focus_neighbor_right"]]:
			var mejor: Button = null
			var menor := INF
			for o: Button in sitios:
				var d: Vector2 = sitios[o] - sitios[b]
				var hacia := d.dot(lado[0])
				var de_lado := absf(d.dot(Vector2(lado[0].y, lado[0].x)))
				if hacia > 4.0 and de_lado < hacia * (3.0 if lado[0].y != 0 else 0.5) and hacia + de_lado * 2.0 < menor:
					menor = hacia + de_lado * 2.0
					mejor = o
			if mejor:
				b.set(lado[1], b.get_path_to(mejor))
			elif lado[0] != Vector2.LEFT:
				b.set(lado[1], b.get_path_to(b))


# ── El dibujo ──

func _draw() -> void:
	var fuente := get_theme_default_font()
	PLACA.dibujar(self, size)
	PLACA.dibujar_ahorrado(self, fuente, s.dolares)
	if casillas.is_empty():
		return
	var ancho_titulos := ficha.position.x - 24
	for t in titulos:
		draw_string(fuente, Vector2(14, t[0] + 16), t[1].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, ancho_titulos, 16, PLACA.TEXTO)
		draw_rect(Rect2(14, t[0] + 20, ancho_titulos - 4, 2), PLACA.APAGADO)
	for id in casillas:
		dibujar_casilla(id, fuente)
	dibujar_marca_regalo()
	dibujar_ficha(fuente)


# Una casilla: oscura con borde gris y el icono (el precio sale en la ficha, al pasar por encima). Lo que llevas, con el
# borde verde; lo que ya no cabe, también con «LLENO»; lo que no se puede comprar, apagado. La elegida, con el borde claro
func dibujar_casilla(id: String, fuente: Font) -> void:
	var r: Rect2 = casillas[id]
	var e := estado(id)
	var borde := PLACA.REMACHE
	var relleno := Color("#1c1f24")
	var apagada := e in ["caro", "reto"]
	var texto := ""
	if e in ["lleva", "lleno"]:
		borde = VERDE_BORDE
		texto = "" if e == "lleva" else Idioma.t("LLENO")
	elif apagada:
		borde = PLACA.APAGADO
		relleno = PLACA.NEGRO
	if id == ficha_id:
		borde = PLACA.TEXTO
	draw_rect(r, borde)
	draw_rect(r.grow(-2), relleno)
	var color := Color(0.55, 0.55, 0.55, 0.75) if apagada else Color.WHITE
	var dibujo := dibujo_tienda(id)
	if dibujo:
		# el de la tienda (48), a su tamaño y en el centro; «LLENO» va encima, en una franja oscura
		var lado48 := Vector2(dibujo.get_size())
		draw_texture_rect(dibujo, Rect2((r.get_center() - lado48 / 2.0).floor(), lado48), false, color)
		if texto != "":
			draw_rect(Rect2(r.position.x + 2, r.end.y - 20, r.size.x - 4, 18), Color(relleno, 0.85))
	else:
		var lado := minf(32.0, r.size.y - 26) if texto != "" else minf(32.0, r.size.y - 12)
		var arriba := r.position.y + 6 if texto != "" else r.get_center().y - lado / 2.0
		draw_texture_rect(icono(id), Rect2(r.get_center().x - lado / 2.0, arriba, lado, lado), false, color)
	if texto == "":
		return
	var tam := 16
	while tam > 10 and fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > r.size.x - 6:
		tam -= 2   # (que «LLENO» quepa en todos los idiomas)
	draw_string(fuente, Vector2(r.position.x, r.end.y - 7), texto, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, tam, VERDE)


# El «!» que bota dentro de la esquina de arriba a la derecha de la casilla del regalo de bienvenida (el de los iconos del
# escritorio: ordenador.marca_nuevo). Se vuelve a dibujar en cada fotograma mientras está (_process)
const EXCLAMACION := preload("res://assets/ui/exclamacion-pequena.png")
func dibujar_marca_regalo() -> void:
	if not con_marca():
		return
	var r: Rect2 = casillas["pistola"]
	var bote := roundf(sin(ahora() * 10.5) * 3.0)
	draw_texture(EXCLAMACION, (Vector2(r.end.x - EXCLAMACION.get_width() - 3, r.position.y + 6 + bote)).floor())


func con_marca() -> bool:
	return casillas.has("pistola") and es_regalo(s, "pistola") and estado("pistola") == ""


func _process(_delta: float) -> void:
	if con_marca():
		queue_redraw()


# La ficha de la derecha: lo elegido o, sin nada elegido, que se pase por un arma (o, con el regalo sin coger,
# «¡COMPRA UN ARMA!» en grande, con la letra y el color del «¡¡¡LA LLAVE!!!» de encima de Johnny: partida.gran_aviso)
func dibujar_ficha(fuente: Font) -> void:
	var f := ficha
	draw_rect(f, PLACA.REMACHE)
	draw_rect(f.grow(-2), Color("#101215"))
	draw_rect(Rect2(f.position + Vector2(2, 2), Vector2(f.size.x - 4, 26)), Color("#2a2e35"))
	var ancho := f.size.x - 20
	var x := f.position.x + 10
	if ficha_id == "":
		draw_string(fuente, Vector2(x, f.position.y + 21), Idioma.t("Tienda de armas").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, ancho, 16, PLACA.TEXTO)
		var y := f.position.y + 50
		if es_regalo(s, "pistola"):
			var lineas := partir(fuente, Idioma.t("¡COMPRA UN ARMA!"), ancho, 32)
			var alto := fuente.get_height(32)
			y = f.get_center().y - alto * lineas.size() / 2.0 + fuente.get_ascent(32)
			for linea in lineas:
				draw_string_outline(fuente, Vector2(x, y), linea, HORIZONTAL_ALIGNMENT_CENTER, ancho, 32, 8, Color(0.11, 0.1, 0.17))
				draw_string(fuente, Vector2(x, y), linea, HORIZONTAL_ALIGNMENT_CENTER, ancho, 32, Tema.AMARILLO)
				y += alto
			return
		for parrafo in nota():
			y = escribir(fuente, parrafo[0], Vector2(x, y), ancho, 14, parrafo[1], f.end.y - 8) + 8
		return
	var id := ficha_id
	draw_string(fuente, Vector2(x, f.position.y + 21), nombre(id).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, ancho, 16, PLACA.TEXTO)
	var g := grupo(id)
	var ancho_grupo := fuente.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	if fuente.get_string_size(nombre(id).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + ancho_grupo + 12 < ancho:
		draw_string(fuente, Vector2(x, f.position.y + 20), g, HORIZONTAL_ALIGNMENT_RIGHT, ancho, 14, PLACA.TEXTO_SUAVE)
	# el dibujo, a ×3, en su recuadro
	var cuadro := Rect2(x - 2, f.position.y + 34, ancho + 4, 100)
	draw_rect(cuadro, PLACA.APAGADO)
	draw_rect(cuadro.grow(-2), Color("#0d1012"))
	# el dibujo grande de la tienda (en horizontal, como en un escaparate) a ×2; si no tiene, el de la casilla a ×2 o el
	# icono de siempre a ×3
	var grande := dibujo_tienda(id, "-grande")
	var dibujo := grande if grande else dibujo_tienda(id)
	var zoom := 2.0 if dibujo else 3.0
	if dibujo == null:
		dibujo = icono(id)
	var tam_dibujo := Vector2(dibujo.get_size()) * zoom
	draw_texture_rect(dibujo, Rect2((cuadro.get_center() - tam_dibujo / 2.0).floor(), tam_dibujo), false)
	# debajo del dibujo, con la letra lisa (se lee mejor; el nombre de arriba y el botón, con la pixelada): los medidores
	var lisa := Tema.lisa(Tema.PESO_LISA)
	var y := cuadro.end.y + 6
	for m in medidas(id):
		draw_string(lisa, Vector2(x, y + 13), Idioma.t(m[0]), HORIZONTAL_ALIGNMENT_LEFT, 112, TAM_LISA, PLACA.TEXTO)
		var llenos := cuadraditos(id, m[1])
		for i in 10:
			draw_rect(Rect2(x + ancho - 10 * 11 + 3 + i * 11, y + 3, 8, 8), PLACA.TEXTO if i < llenos else PLACA.APAGADO)
		y += MEDIDOR
	# qué hace (sus números y cuántos llevas ya no salen: 11 nov, lo dicen los medidores)
	var tope := comprar.position.y - 6
	escribir(lisa, Idioma.t(INVENTARIO.QUE_HACE.get(id, "")), Vector2(x, y + 4), ancho, TAM_LISA, PLACA.TEXTO, tope)
	dibujar_comprar(fuente)


# Un texto partido en líneas (por palabras) que no pasan de "ancho", sin bajar de "tope"; devuelve dónde acaba (y)
func escribir(fuente: Font, texto: String, sitio: Vector2, ancho: float, tam: int, color: Color, tope: float) -> float:
	var alto_linea := fuente.get_height(tam)
	var y := sitio.y
	for linea in partir(fuente, texto, ancho, tam):
		if y + alto_linea > tope:
			break
		draw_string(fuente, Vector2(sitio.x, y + fuente.get_ascent(tam)), linea, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)
		y += alto_linea
	return y


func partir(fuente: Font, texto: String, ancho: float, tam: int) -> PackedStringArray:
	var lineas := PackedStringArray()
	var linea := ""
	# las palabras; una más ancha que la línea (el chino va sin espacios), letra a letra
	var trozos := []
	for palabra in texto.split(" ", false):
		if fuente.get_string_size(palabra, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x <= ancho:
			trozos.append([palabra, " "])
		else:
			for i in palabra.length():
				trozos.append([palabra[i], " " if i == 0 else ""])
	for trozo in trozos:
		var palabra: String = trozo[0]
		var con: String = palabra if linea == "" else linea + trozo[1] + palabra
		if linea != "" and fuente.get_string_size(con, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > ancho:
			lineas.append(linea)
			linea = palabra
		else:
			linea = con
	if linea != "":
		lineas.append(linea)
	return lineas


# El botón «Comprar · $X», con el texto en amarillo; si no se puede, en gris y diciendo por qué; lo que ya llevas,
# «Comprada» en grande, en verde y con el borde verde (como su casilla). Si no te llega el dinero, el precio en un
# marcador como el de lo ahorrado de arriba, en amarillo y sin el billete (10 nov)
func dibujar_comprar(fuente: Font) -> void:
	var r := Rect2(comprar.position, comprar.size)
	var texto := texto_comprar(ficha_id)
	var se_puede := estado(ficha_id) == ""
	var comprada := estado(ficha_id) == "lleva"
	var encima := se_puede and comprar.is_hovered()
	var pulsado := se_puede and comprar.button_pressed
	draw_rect(r, PLACA.TEXTO if se_puede else (VERDE_BORDE if comprada else PLACA.APAGADO))
	draw_rect(r.grow(-2), Color("#3a3f47") if encima and not pulsado else (Color("#2f333a") if se_puede else PLACA.NEGRO))
	if estado(ficha_id) == "caro":
		var p := precio(ficha_id)
		var medida := PLACA.medida_marcador(fuente, p)
		PLACA.dibujar_marcador(self, fuente, Rect2((r.get_center() - medida / 2.0).floor(), medida), p, PLACA.AMARILLO)
		return
	var tam := 24 if se_puede or comprada else 16
	while tam > 12 and fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > r.size.x - 12:
		tam -= 2
	var base := r.position.y + r.size.y / 2.0 + fuente.get_ascent(tam) / 2.0 - 2 + (2 if pulsado else 0)
	draw_string(fuente, Vector2(r.position.x, base), texto, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, tam,
		PLACA.AMARILLO if se_puede else (VERDE if comprada else PLACA.TEXTO_SUAVE))


# Lo que dice el botón «Comprar»: cómo se compra y cuánto cuesta (o por qué no se puede). Lo usan también las pruebas
func texto_comprar(id: String) -> String:
	var p := precio(id)
	match estado(id):
		"lleva": return Idioma.t("Comprada")   # (y se da por hecho que la llevas)
		"lleno": return Idioma.t("No te caben más")
		"reto": return Idioma.t("No en este reto")
		"caro": return "$%d" % p   # (dibujado en rojo, como un marcador: dibujar_comprar)
	if es_regalo(s, id):
		return Idioma.t("Regalo de bienvenida")
	if not (Tactil.activo and Tactil.con_dedo):
		if Controles.con_mando:
			return Idioma.t("A: comprar · $%d") % p
		if modo == "foco":
			return Idioma.t("Intro: comprar · $%d") % p
	return Idioma.t("Comprar · $%d") % p


# Lo que dice la ficha sin nada elegido, párrafo a párrafo: [texto, color] (cómo va la tienda, en su tutorial)
func nota() -> Array:
	var parrafos := [[Idioma.t("Pasa por un arma para ver qué hace."), PLACA.TEXTO]]
	if ordenador.partida.dolares > 0:
		parrafos.append([Idioma.t("Los $%d de esta partida se guardan al acabarla: todos si completas el edificio, la mitad si caes.") % ordenador.partida.dolares, PLACA.AMARILLO])
	return parrafos


# Los dibujos de la tienda, más grandes y nítidos que los iconos (assets/ui/tienda: <id>.png, de 48, para la casilla, y
# <id>-grande.png, en horizontal, para la ficha); null si esa cosa aún no tiene
var dibujos := {}
func dibujo_tienda(id: String, cual := "") -> Texture2D:
	var ruta := "res://assets/ui/tienda/%s%s.png" % [id, cual]
	if not dibujos.has(ruta):
		dibujos[ruta] = load(ruta) if ResourceLoader.exists(ruta) else null
	return dibujos[ruta]


# Los iconos se cargan una vez (assets/ui/iconos)
var iconos := {}
func icono(id: String) -> Texture2D:
	if not iconos.has(id):
		iconos[id] = load("res://assets/ui/iconos/%s.png" % id)
	return iconos[id]


# ── Lo elegido ──

func _input(evento: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var antes := modo
	if evento is InputEventKey or evento is InputEventJoypadButton or (evento is InputEventJoypadMotion and absf(evento.axis_value) > 0.5):
		modo = "foco"
	elif evento is InputEventMouseMotion or evento is InputEventMouseButton or evento is InputEventScreenTouch:
		modo = "raton"
	if evento is InputEventMouseMotion or modo != antes:
		actualizar_ficha()
		if modo != antes:
			queue_redraw()   # (el botón «Comprar» dice cómo se compra)


# Lo que tiene que enseñar la ficha: con el ratón, la casilla de debajo (o la «i»: cómo va la tienda); si no hay
# ninguna, lo que ya enseñaba. Con el teclado, el mando o el dedo, la marcada (el toque marca el botón, pero no mueve el
# ratón de Godot: se quedaría en el sitio de antes)
func quien() -> String:
	var con_dedo := Tactil.activo and Tactil.con_dedo
	if modo == "raton" and not con_dedo:
		if ordenador.colocando:
			return ficha_id
		var raton := get_local_mouse_position()
		for id in casillas:
			if casillas[id].has_point(raton):
				return id
		return ficha_id
	var foco := get_viewport().gui_get_focus_owner()
	for id in botones:
		if botones[id] == foco:
			return id
	return ficha_id


func actualizar_ficha() -> void:
	var id := quien()
	if id == ficha_id:
		return
	ficha_id = id
	ficha_desde = ahora()
	comprar.visible = id != ""
	queue_redraw()


# Al pulsar una casilla: con el dedo, si su ficha no estaba ya a la vista, el toque solo la enseña
func al_pulsar(id: String) -> void:
	if Tactil.activo and Tactil.con_dedo and not listo.get(id, false):
		return
	comprar_esto(id)


func comprar_esto(id: String) -> void:
	if Lanzables.PRECIOS.has(id):
		ordenador.comprar_lanzable(id)
	else:
		ordenador.comprar_arma(id)
