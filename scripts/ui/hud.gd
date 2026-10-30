# El HUD de Johnny, en la franja de abajo de la pantalla (la del muro de abajo, 64 de alto), como el del JS
# (src/ui.js, updateHud; #hud en style.css). Así la barra de la portera y la de la horda, arriba, no se tapan.
# Va ordenado por importancia: lo que se usa al pelear, grande; lo que solo informa, pequeño y sin marco.
#   - La barra de vida en su marco (barra-vida.png), partida en tres tercios. Los tercios perdidos se tapan
#     con rayas oscuras, porque ya no se curan. Encima, la vida en números. Al recibir un golpe, la barra
#     tiembla y lo perdido se queda en claro un momento antes de bajar; con poca vida, la sangre late.
#   - Sobre la barra, las balas del cargador: una por cada bala que cabe (las gastadas, apagadas) y la
#     reserva (la munición de su tipo, compartida con las armas que la gastan). Al recargar, las gastadas parpadean.
#     Más apagadas si lleva en la mano el arma cuerpo a cuerpo.
#     Con el lanzallamas, en vez de las balas, el depósito: una barra de gasolina y las gasolinas de la mochila
#     (con el lanza ácido, la barra en verde y sus bidones de ácido).
#   - A la derecha de la barra de vida, las curas que lleva (las vendas y el botiquín; Objetos.USABLES), cada una en su
#     casilla con cuántas tiene y su tecla (1 y 2: partida.usar_cura). Solo salen las que lleva; mientras no sirven se
#     apagan (con la vida llena; el botiquín, que devuelve un tercio, si además no ha perdido ninguno). Al coger una o gastarla, la casilla da un saltito (y al gastarla, un destello).
#   - En la esquina de abajo a la derecha, las armas: la de la mano en la misma esquina, en la casilla más grande
#     y con el borde amarillo, y la otra a su lado, apagada (con la tecla de cambiar). Al cambiar dan un saltito
#     (sin el nombre encima: el arma se ve en su dibujo).
#   - A su izquierda, los lanzables que lleva a mano (los de repuesto no se ven), cada uno en su casilla con
#     cuántos le quedan: el que se lanza ahora, en una casilla grande como la del arma, encendido y con las esquinas
#     amarillas, que la F pasa al siguiente.
#   - En el móvil, las armas y los lanzables van al lado de la barra: la esquina de la derecha es de los botones.
#   - Ni la llave de la portera, ni la mochila, ni los dólares están aquí: se ven en el inventario.
#   - En la primera partida, la guía (guia.gd) puede pedir que una parte lata ("latido": "balas", "curas", "lanzar" o
#     "armas"): un marco amarillo alrededor que se abre y se cierra, para que se vea qué hay que usar.
# Cada fotograma mira cómo está Johnny ("johnny") y lo que lleva la partida ("partida").
extends Control

const MARCO := preload("res://assets/ui/barra-vida.png")
const BALA := preload("res://assets/ui/iconos/bala.png")
const CARTUCHO := preload("res://assets/ui/iconos/cartucho.png")
const ANCHO := 236.0      # la barra a tamaño 1 (el dibujo mide 236×26)
const ALTO := 26.0
# El hueco de dentro del marco, por donde se ve la sangre (en partes de la barra, como en style.css)
const HUECO := Rect2(0.046 * ANCHO, 0.28 * ALTO, 0.908 * ANCHO, 0.44 * ALTO)
# La barra del escudo (M22): el marco de la de vida a media altura (barra-escudo.png, 236×13: sus filas de arriba, las
# del medio y las de abajo, sin deformar los remaches, y con el filo de dentro en azul), y su hueco
const MARCO_ESCUDO := preload("res://assets/ui/barra-escudo.png")
const ALTO_ESCUDO := 13.0
const HUECO_ESCUDO := Rect2(0.046 * ANCHO, 3.0, 0.908 * ANCHO, 7.0)
const ABAJO := 8.0        # lo que queda entre el borde de abajo de la pantalla y la barra o las casillas
# Todo el HUD, una vez y media más grande que sus medidas (cada píxel del dibujo, 3 de pantalla en vez de 2: se sigue
# viendo nítido). Más no cabe: al doble, la parte de la izquierda y la de la derecha se pisarían en una pantalla de 960
const ESCALA := 1.5
const GRANDE := 52.0      # la casilla del arma en la mano (casilla-grande.png, de 22 píxeles, con los lados estirados)
const MEDIANA := 36.0     # la de la otra arma y la de cada lanzable (casilla-mediana.png, de 18, al doble)
const MARCOS := {
	"grande": preload("res://assets/ui/casilla-grande.png"),
	"mediana": preload("res://assets/ui/casilla-mediana.png"),
}
# Por cada marco: lo que mide su esquina en el dibujo (se pinta al doble y no se estira) y su grueso en la
# pantalla (hasta el hueco de dentro)
const CORTE := {"grande": 4, "mediana": 4}
const GRUESO := {"grande": 8.0, "mediana": 7.0}
# La barra del depósito, del color de lo que lo llena: [el relleno, su brillo de arriba, su sombra de abajo]
const COLORES_DEPOSITO := {
	"gasolina": [Color("#ff9f1c"), Color("#ffd23f"), Color("#b8561c")],
	"bidon_acido": [Color("#c7e04a"), Color("#ecf896"), Color("#608028")],
	"bateria": [Color("#2cc8e8"), Color("#b8f4ff"), Color("#1b7f9c")],
}

var johnny: Node2D
var partida: Node

var fila := HBoxContainer.new()
var derecha := HBoxContainer.new()   # los lanzables y las armas, en la esquina de la derecha
var barra := Control.new()
var curas := Control.new()      # las vendas y el botiquín, al lado de la barra
var armas := Control.new()      # las dos casillas de las armas
var lanzar := Control.new()     # el lanzable de ahora y los demás
var encima := Control.new()     # el marco del latido, por encima de todo
var latido := ""                # la parte que late (la pide guia.gd; "" ninguna)
var texturas := {}              # los iconos ya cargados

# Las armas: cuál estaba en la mano y las animaciones al cambiar (de 0 a 1 el intercambio; las demás, de 1 a 0)
var en_mano := ""
var mano_antes := ""
var cambio := 1.0
var salto_arma := 0.0
var destello_arma := 0.0
# Los lanzables: el que se ve, el de antes (de donde vienen las esquinas al cambiar) y cuántos había
var tipo_visto := ""
var tipo_antes := ""
var cuenta_antes := -1
var giro := 1.0
var salto_cuenta := 0.0
var destello_lanzar := 0.0
# Las curas: cuántas llevaba cada una la última vez (para ver si ha cogido o gastado) y las animaciones de cada casilla
var cuentas_curas := {}
var salto_curas := {}
var destello_curas := {}

# La barra que se mueve: al perder vida, el trozo perdido se queda un momento en claro y luego baja
# poco a poco (como en los juegos de lucha); al curarse, sube poco a poco
const ESPERA := 0.45      # lo que tarda en empezar a bajar el trozo perdido
const BAJADA := 0.9       # cuánta barra baja por segundo (en partes de la barra)
var vista := -1.0         # la parte de la barra que se ve llena ahora (0 a 1)
var perdida := -1.0       # hasta dónde llega el trozo claro de lo perdido
var espera := 0.0
var temblor := 0.0        # el temblor de la barra al recibir un golpe (se apaga solo)
var tiempo := 0.0
# Lo mismo para la barra del escudo
var escudo_vista := -1.0
var escudo_perdida := -1.0
var escudo_espera := 0.0
var escudo_temblor := 0.0

# Las balas que salen volando del cargador al disparar (se pintan cayendo y apagándose) y las que entran al
# recargar (aparecen con un saltito)
var balas_antes := -1
var arma_antes := ""
var gastadas: Array = []  # [número de bala, tiempo desde que salió]
var nuevas := {}          # número de bala → tiempo desde que entró


func _ready() -> void:
	theme = Tema.crear()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fila.add_theme_constant_override("separation", 14)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.scale = Vector2(ESCALA, ESCALA)
	add_child(fila)
	barra.custom_minimum_size = Vector2(ANCHO, ALTO)
	barra.size_flags_vertical = Control.SIZE_SHRINK_END   # la barra y las curas, con el borde de abajo a la par
	barra.draw.connect(pintar_barra)
	fila.add_child(barra)
	curas.custom_minimum_size = Vector2(MEDIANA, MEDIANA + 4)
	curas.size_flags_vertical = Control.SIZE_SHRINK_END
	curas.draw.connect(pintar_curas)
	curas.visible = false
	fila.add_child(curas)
	derecha.add_theme_constant_override("separation", 14)
	derecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	derecha.scale = Vector2(ESCALA, ESCALA)
	add_child(derecha)
	lanzar.custom_minimum_size = Vector2(GRANDE, GRANDE + 4)
	lanzar.draw.connect(pintar_lanzar)
	derecha.add_child(lanzar)
	armas.custom_minimum_size = Vector2(MEDIANA + GRANDE + 12, GRANDE + 4)
	armas.draw.connect(pintar_armas)
	derecha.add_child(armas)
	encima.mouse_filter = Control.MOUSE_FILTER_IGNORE
	encima.draw.connect(pintar_latido)
	add_child(encima)


func _process(delta: float) -> void:
	tiempo += delta
	var pantalla := get_viewport_rect().size
	# en la franja de abajo, con la barra de vida pegada abajo (las balas se pintan por encima de ella); las medidas
	# de dentro, agrandadas (ESCALA)
	fila.position = Vector2(14, roundf(pantalla.y - ABAJO - fila.size.y * ESCALA))
	# las casillas, en la esquina de abajo a la derecha, con su borde de abajo a la altura del de la barra (sus
	# dibujos dejan 2 de aire debajo); en el móvil, al lado de la barra
	var x := fila.position.x + (fila.size.x + 14) * ESCALA if Tactil.activo else pantalla.x - 14 - derecha.size.x * ESCALA
	derecha.position = Vector2(roundf(x), roundf(pantalla.y - ABAJO - (derecha.size.y - 2) * ESCALA))
	if johnny == null:
		return
	mirar_armas(delta)
	mirar_lanzar(delta)
	mirar_curas(delta)
	mover_barra(delta)
	mover_escudo(delta)
	mirar_balas(delta)
	barra.queue_redraw()
	curas.queue_redraw()
	armas.queue_redraw()
	lanzar.queue_redraw()
	encima.queue_redraw()


# El marco amarillo del latido, alrededor de la parte que pide la guía (las balas, encima de la barra de vida)
func pintar_latido() -> void:
	var cual: Control = {"curas": curas, "lanzar": lanzar, "armas": armas, "balas": barra}.get(latido)
	if cual == null or not cual.visible:
		return
	var r := Rect2(cual.global_position - encima.global_position, cual.size * ESCALA)
	if latido == "balas":
		r = Rect2(r.position + Vector2(HUECO.position.x, -28) * ESCALA, Vector2(ANCHO * 0.55, 24) * ESCALA)
	var k := 0.5 + 0.5 * sin(tiempo * 7.0)
	encima.draw_rect(r.grow(4.0 + 4.0 * k), Color(Tema.AMARILLO, 0.5 + 0.5 * k), false, 3.0)


func icono(nombre: String) -> Texture2D:
	if not texturas.has(nombre):
		texturas[nombre] = load("res://assets/ui/iconos/%s.png" % nombre)
	return texturas[nombre]


func icono_lanzable(k: String) -> String:
	if k == "":
		return ""   # no lleva nada a mano para lanzar
	return Lanzables.tipo_de(k)   # (assets/ui/iconos/<tipo>.png; "k" es la clave del paquete)


# Una casilla: el marco de metal (casilla-*.png) y el icono dentro. "luz" apaga la que no está en uso. El icono
# puede ir corrido ("corrido", para la animación del tambor) y se recorta al hueco de dentro. Lo que no es Normal
# ("calidad": la del arma o el paquete; Armas.CALIDADES) lleva una raya de su color por dentro del marco
func casilla(c: Control, r: Rect2, nombre: String, luz := 1.0, corrido := Vector2.ZERO, calidad := 0) -> void:
	var m := 0.55 + 0.45 * luz
	marco(c, r, Color(m, m, m))
	c.draw_rect(hueco_de(r), Color("#5a4e63", 0.55 * luz))   # el hueco, algo encendido si está en uso
	if calidad > 0:
		c.draw_rect(hueco_de(r).grow(-1), Color(Armas.color(calidad), 0.5 + 0.5 * luz), false, 2.0)
	if nombre != "":
		icono_dentro(c, nombre, r, corrido, Color(luz, luz, luz, 0.4 + 0.6 * luz))


func tipo_marco(r: Rect2) -> String:
	return "grande" if r.size.x > 44 else "mediana"


# El marco de metal, en nueve trozos: las esquinas al doble, como todo el dibujo, y los lados estirados hasta lo
# que mida la casilla (así la del arma en la mano puede ser más grande sin que las esquinas se deformen)
func marco(c: Control, r: Rect2, color: Color) -> void:
	var tipo := tipo_marco(r)
	var tex: Texture2D = MARCOS[tipo]
	var e: float = CORTE[tipo]
	var t := float(tex.get_width())
	var corte := [0.0, e, t - e, t]   # dónde se corta el dibujo y dónde va cada trozo en la pantalla
	var xs := [r.position.x, r.position.x + e * 2, r.end.x - e * 2, r.end.x]
	var ys := [r.position.y, r.position.y + e * 2, r.end.y - e * 2, r.end.y]
	for i in 3:
		for j in 3:
			c.draw_texture_rect_region(tex, Rect2(xs[i], ys[j], xs[i + 1] - xs[i], ys[j + 1] - ys[j]),
				Rect2(corte[i], corte[j], corte[i + 1] - corte[i], corte[j + 1] - corte[j]), color)


# El hueco de dentro de una casilla
func hueco_de(r: Rect2) -> Rect2:
	return r.grow(-GRUESO[tipo_marco(r)])


# El icono, centrado en el hueco (corrido si hace falta) y recortado a él para que no se salga
func icono_dentro(c: Control, nombre: String, r: Rect2, corrido: Vector2, color: Color) -> void:
	var tex := icono(nombre)
	var lado := roundf(r.size.x * 32.0 / 44.0)
	var donde := Rect2(r.get_center() - Vector2(lado, lado) / 2.0 + corrido, Vector2(lado, lado))
	var visto := donde.intersection(hueco_de(r))
	if visto.size.x <= 0.0 or visto.size.y <= 0.0:
		return
	var escala := tex.get_size() / donde.size
	c.draw_texture_rect_region(tex, visto, Rect2((visto.position - donde.position) * escala, visto.size * escala), color)


# Las cuatro esquinas amarillas de la casilla en uso, como un punto de mira. "abre" las separa (al llegar,
# vienen de lejos y se cierran) y respiran un poco
func esquinas(c: Control, r: Rect2, abre := 0.0) -> void:
	var f := r.grow(3.0 + roundf(abre + sin(tiempo * 5.0) * 0.5 + 0.5))
	var largo := 8.0
	for i in 2:   # primero el contorno oscuro (más gordo) y encima el amarillo
		var g := 1.0 if i == 0 else 0.0
		var color := Tema.LINEA if i == 0 else Tema.AMARILLO
		for derecha in [false, true]:
			for abajo in [false, true]:
				var x: float = f.end.x - 2 if derecha else f.position.x
				var y: float = f.end.y - 2 if abajo else f.position.y
				c.draw_rect(Rect2(f.end.x - largo if derecha else f.position.x, y, largo, 2).grow(g), color)
				c.draw_rect(Rect2(x, f.end.y - largo if abajo else f.position.y, 2, largo).grow(g), color)


# Un destello blanco en el hueco que se apaga (al cambiar algo)
func destello(c: Control, r: Rect2, k: float) -> void:
	if k > 0.0:
		c.draw_rect(hueco_de(r), Color(1, 1, 0.9, 0.55 * k))


# Un texto con su contorno; "x" es el centro si "centrado"
func texto(c: Control, donde: Vector2, s: String, tamano: int, color: Color, centrado := false) -> void:
	if centrado:
		donde.x -= roundf(Tema.FUENTE.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x / 2.0)
	c.draw_string_outline(Tema.FUENTE, donde, s, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, 4, Color(Tema.LINEA, color.a))
	c.draw_string(Tema.FUENTE, donde, s, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano, color)


func ancho_texto(s: String, tamano: int) -> float:
	return Tema.FUENTE.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x


# Una tecla pequeña pegada a una casilla (Q para cambiar de arma, F para cambiar de lanzable)
func tecla(c: Control, donde: Vector2, letra: String) -> void:
	var r := Rect2(donde, Vector2(12, 12))
	c.draw_rect(r.grow(1), Tema.LINEA)
	c.draw_rect(r, Tema.GRIS)
	c.draw_string(Tema.FUENTE, donde + Vector2(3, 10), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tema.LINEA)


# Dibuja con un saltito: más grande al empezar ("k" de 1 a 0), alrededor del centro de "r"
func con_salto(c: Control, r: Rect2, k: float) -> void:
	var s := 1.0 + 0.22 * sin(k * PI) * k
	c.draw_set_transform(r.get_center() * (1.0 - s), 0.0, Vector2(s, s))


# De 0 a 1 pasándose un poco al final y volviendo (como un muelle)
func muelle(x: float) -> float:
	var c1 := 1.70158
	return 1.0 + (c1 + 1.0) * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


func mezclar(a: Rect2, b: Rect2, k: float) -> Rect2:
	return Rect2(a.position.lerp(b.position, k), a.size.lerp(b.size, k))


# ── Las armas ──

func mirar_armas(delta: float) -> void:
	var ahora: String = johnny.huecos[johnny.mano]
	if ahora != en_mano:
		if en_mano != "":
			if johnny.mano != mano_antes:
				cambio = 0.0       # ha cambiado de mano: las casillas se intercambian
			else:
				salto_arma = 1.0   # ha cogido otra arma en la misma mano: saltito
			destello_arma = 1.0
		en_mano = ahora
		mano_antes = johnny.mano
	cambio = move_toward(cambio, 1.0, delta / 0.24)
	salto_arma = move_toward(salto_arma, 0.0, delta * 5.0)
	destello_arma = move_toward(destello_arma, 0.0, delta * 4.0)


# Al cambiar de arma, la nueva salta de la casilla pequeña a la grande (haciendo un arco por arriba) y la
# vieja baja a la pequeña; luego las esquinas amarillas se cierran sobre la nueva. La grande va a la derecha,
# en la esquina de la pantalla
func pintar_armas() -> void:
	var h: Dictionary = johnny.huecos
	var otra: String = h.fuego if johnny.mano == "cuerpo" else h.cuerpo
	var grande := Rect2(MEDIANA + 10, 2, GRANDE, GRANDE)
	var pequena := Rect2(2, 2 + GRANDE - MEDIANA, MEDIANA, MEDIANA)
	var k := muelle(cambio)
	var arco := Vector2(0, -sin(cambio * PI) * 12.0)
	var vieja := mezclar(grande, pequena, k)
	vieja.position -= arco * 0.4
	casilla(armas, vieja, Objetos.icono(otra), lerpf(1.0, 0.6, cambio), Vector2.ZERO, johnny.calidad(otra))
	if cambio >= 1.0:
		tecla(armas, pequena.position + Vector2(MEDIANA - 8, -8), "Q")
	var nueva := mezclar(pequena, grande, k)
	nueva.position += arco
	con_salto(armas, nueva, salto_arma)
	casilla(armas, nueva, Objetos.icono(en_mano), lerpf(0.6, 1.0, cambio), Vector2.ZERO, johnny.calidad(en_mano))
	destello(armas, nueva, destello_arma)
	if cambio > 0.6:
		esquinas(armas, nueva, (1.0 - cambio) * 25.0)
	armas.draw_set_transform(Vector2.ZERO)


# ── Los lanzables ──

func mirar_lanzar(delta: float) -> void:
	var lz: Lanzables = partida.lanzables
	var n := lz.cuantas(lz.tipo)
	if lz.tipo != tipo_visto:
		if tipo_visto != "":
			giro = 0.0             # otro lanzable: gira el tambor
			tipo_antes = tipo_visto
			destello_lanzar = 1.0
		tipo_visto = lz.tipo
	elif n != cuenta_antes and cuenta_antes >= 0:
		salto_cuenta = 1.0         # uno más o uno menos: el número da un saltito
	cuenta_antes = n
	giro = move_toward(giro, 1.0, delta / 0.22)
	salto_cuenta = move_toward(salto_cuenta, 0.0, delta * 5.0)
	destello_lanzar = move_toward(destello_lanzar, 0.0, delta * 4.0)
	# el ancho depende de cuántos lleve a mano (sin ninguno, una casilla vacía): una grande y las demás medianas
	lanzar.custom_minimum_size.x = (maxi(1, lz.tipos().size()) - 1) * (MEDIANA + 10) + GRANDE + 6


# Las casillas de los lanzables (en el orden de la F), en fila y con el borde de abajo como el de las armas: la del de
# ahora, grande como la del arma en la mano, y las demás medianas. Al cambiar con la F, la del de antes encoge mientras
# la del nuevo crece (con el muelle), así que la fila mide siempre lo mismo
func sitios_lanzables(lista: Array) -> Array:
	var ahora := maxi(lista.find(partida.lanzables.tipo), 0)
	var antes := lista.find(tipo_antes) if giro < 1.0 else -1
	var k := muelle(giro) if antes >= 0 else 1.0
	var sitios := []
	var x := 2.0
	for i in lista.size():
		var grande := (k if i == ahora else 0.0) + (1.0 - k if i == antes else 0.0)
		var lado := roundf(lerpf(MEDIANA, GRANDE, grande))
		sitios.append(Rect2(x, 2 + GRANDE - lado, lado, lado))
		x += lado + 10
	return sitios


# Cada lanzable en su casilla, con cuántos quedan en la esquina (en rojo si ninguno); el de ahora, en la casilla
# grande, encendido y con las esquinas amarillas. Al cambiar con la F, las esquinas saltan de una casilla a la otra,
# las casillas cambian de tamaño y la nueva da un saltito
func pintar_lanzar() -> void:
	var lz: Lanzables = partida.lanzables
	var lista: Array = lz.tipos()
	if lista.is_empty():
		lista = [""]   # no lleva nada a mano
	var k := muelle(giro)
	var sitios := sitios_lanzables(lista)
	for i in lista.size():
		var t: String = lista[i]
		var n := lz.cuantas(t)
		var activo := t == lz.tipo
		var r: Rect2 = sitios[i]
		if activo:
			con_salto(lanzar, r, 1.0 - giro)
		casilla(lanzar, r, icono_lanzable(t), (1.0 if activo else 0.6) if n > 0 else 0.35, Vector2.ZERO,
			Lanzables.calidad_de(t))
		if activo:
			destello(lanzar, r, destello_lanzar)
		lanzar.draw_set_transform(Vector2.ZERO)
		var s := "x%d" % n
		var donde := Vector2(r.end.x - ancho_texto(s, 16) + 4, r.end.y - 1)
		if activo:   # si cambia, el número da un saltito
			con_salto(lanzar, Rect2(donde - Vector2(0, 12), Vector2(ancho_texto(s, 16), 12)), salto_cuenta)
		texto(lanzar, donde, s, 16, Color(Tema.TINTA if n > 0 else Tema.ROJO, 1.0 if activo else 0.7))
		lanzar.draw_set_transform(Vector2.ZERO)
	# las esquinas, sobre el de ahora (viniendo del de antes al cambiar), y la F encima si hay otros
	var cursor: Rect2 = sitios[maxi(lista.find(lz.tipo), 0)]
	var antes := lista.find(tipo_antes)
	if giro < 1.0 and antes >= 0:
		cursor = mezclar(sitios[antes], cursor, k)
	if lz.cuantas(lz.tipo) > 0:
		esquinas(lanzar, cursor)
	if lista.size() > 1:
		tecla(lanzar, cursor.position + Vector2(cursor.size.x - 6, -10), "F")


# ── Las curas ──

# Lo que lleva de cada cura, en el orden de sus casillas: [[id, cuántas], ...]
func curas_llevadas() -> Array:
	var lista := []
	for id in Objetos.USABLES:
		var n: int = partida.mochila.count(id)
		if n > 0:
			lista.append([id, n])
	return lista


# La casilla de la cura "i" (todas en fila, con el hueco de arriba para la tecla y el borde de abajo como el de la barra
# y el de las casillas de la derecha)
func sitio_cura(i: int) -> Rect2:
	return Rect2(2 + i * (MEDIANA + 10), 4, MEDIANA, MEDIANA)


func mirar_curas(delta: float) -> void:
	for id in Objetos.USABLES:
		var n: int = partida.mochila.count(id)
		var antes: int = cuentas_curas.get(id, n)
		if n != antes:
			salto_curas[id] = 1.0                # una más o una menos: la casilla da un saltito
			if n < antes:
				destello_curas[id] = 1.0         # gastada
		cuentas_curas[id] = n
		salto_curas[id] = move_toward(salto_curas.get(id, 0.0), 0.0, delta * 5.0)
		destello_curas[id] = move_toward(destello_curas.get(id, 0.0), 0.0, delta * 4.0)
	var llevadas := curas_llevadas().size()
	curas.visible = llevadas > 0
	curas.custom_minimum_size.x = maxi(1, llevadas) * (MEDIANA + 10) - 4


# Cada cura en su casilla, con cuántas lleva en la esquina y su tecla encima; apagadas mientras no sirven (con la vida
# llena; el botiquín, con la vida llena y los tres tercios)
func pintar_curas() -> void:
	var lista := curas_llevadas()
	for i in lista.size():
		var id: String = lista[i][0]
		var r := sitio_cura(i)
		con_salto(curas, r, salto_curas.get(id, 0.0))
		casilla(curas, r, Objetos.icono(id), 1.0 if partida.puede_curar(id) else 0.6)
		destello(curas, r, destello_curas.get(id, 0.0))
		curas.draw_set_transform(Vector2.ZERO)
		var s := "x%d" % lista[i][1]
		texto(curas, Vector2(r.end.x - ancho_texto(s, 16) + 4, r.end.y - 1), s, 16, Tema.TINTA)
		if not Tactil.activo:   # (en el móvil, los botones de debajo del minimapa)
			tecla(curas, r.position + Vector2(MEDIANA - 6, -10), Controles.tecla_de(Objetos.USABLES[id].accion).left(1))


func mover_barra(delta: float) -> void:
	var parte := clampf(float(johnny.vida) / johnny.stats.vida_max, 0.0, 1.0)
	if vista < 0.0:
		vista = parte
		perdida = parte
	if parte < vista:
		# le acaban de pegar: la barra baja de golpe, lo perdido se queda en claro y la barra tiembla
		perdida = maxf(perdida, vista)
		vista = parte
		espera = ESPERA
		temblor = 1.0
	elif parte > vista:
		vista = move_toward(vista, parte, delta * BAJADA * 0.6)   # curarse: sube poco a poco
	espera -= delta
	if espera <= 0.0:
		perdida = move_toward(perdida, vista, delta * BAJADA * 0.5)
	perdida = maxf(perdida, vista)
	temblor = move_toward(temblor, 0.0, delta * 3.0)
	barra.position.x = roundf(sin(tiempo * 70.0) * 3.0 * temblor)
	barra.position.y = fila.size.y - ALTO + roundf(cos(tiempo * 55.0) * 2.0 * temblor)   # (abajo en la fila, como las curas)


# Como mover_barra, con el escudo: lo lleno es lo que le queda de lo que le dan en cada planta (Acero, Blindaje y
# Endurecimiento). Un golpe al escudo hace temblar solo su barra, porque la vida no se toca
func mover_escudo(delta: float) -> void:
	var tope: float = maxf(johnny.stats.escudo + johnny.stats.escudo_mut, johnny.escudo)
	var parte := clampf(johnny.escudo / tope, 0.0, 1.0) if tope > 0.0 else 0.0
	if escudo_vista < 0.0:
		escudo_vista = parte
		escudo_perdida = parte
	if parte < escudo_vista:
		escudo_perdida = maxf(escudo_perdida, escudo_vista)
		escudo_vista = parte
		escudo_espera = ESPERA
		escudo_temblor = 1.0
	elif parte > escudo_vista:
		escudo_vista = move_toward(escudo_vista, parte, delta * BAJADA * 0.6)   # el escudo nuevo de cada planta: sube poco a poco
	escudo_espera -= delta
	if escudo_espera <= 0.0:
		escudo_perdida = move_toward(escudo_perdida, escudo_vista, delta * BAJADA * 0.5)
	escudo_perdida = maxf(escudo_perdida, escudo_vista)
	escudo_temblor = move_toward(escudo_temblor, 0.0, delta * 3.0)


# Si se ve la barra del escudo: mientras le quede y, al romperse, hasta que acaba de bajar el trozo perdido
func con_escudo() -> bool:
	return johnny.escudo > 0.0 or escudo_perdida > 0.0


# Compara las balas con las del fotograma anterior: las que faltan salen volando, las que sobran entran
func mirar_balas(delta: float) -> void:
	for g in gastadas:
		g[1] += delta
	gastadas = gastadas.filter(func(g): return g[1] < 0.35)
	for i in nuevas.keys():
		nuevas[i] += delta
		if nuevas[i] > 0.2:
			nuevas.erase(i)
	var b: int = johnny.balas
	if johnny.huecos.fuego != arma_antes:
		arma_antes = johnny.huecos.fuego   # otra arma: no es que se hayan gastado
		balas_antes = b
		return
	if b < balas_antes:
		for i in range(b, balas_antes):
			gastadas.append([i, 0.0])
	elif b > balas_antes and balas_antes >= 0:
		for i in range(balas_antes, b):
			# entran una detrás de otra, como si las metiera a mano
			nuevas[i] = -0.03 * (i - balas_antes)
	balas_antes = b


func pintar_barra() -> void:
	var vida: float = johnny.vida
	var maxima: float = johnny.stats.vida_max
	# El fondo del hueco y la sangre
	barra.draw_rect(HUECO, Color("#1a1620"))
	# lo que acaba de perder, en claro, que se va bajando detrás de la sangre
	var claro := HUECO
	claro.size.x *= perdida
	barra.draw_rect(claro, Color("#f0d8b0") if espera > ESPERA - 0.08 else Color("#d98a5a"))
	var lleno := HUECO
	lleno.size.x *= vista
	# con poca vida, la sangre late (más clara en cada latido)
	var luz := 0.0
	if vida / maxima < 0.34 and johnny.vivo:
		luz = 0.35 * pow(absf(sin(tiempo * PI * 1.6)), 4.0)
	barra.draw_rect(lleno, Color("#8a1f1a").lerp(Color("#e0503a"), luz))
	barra.draw_rect(Rect2(lleno.position, Vector2(lleno.size.x, lleno.size.y * 0.45)), Color("#c24a38").lerp(Color("#ff8a6a"), luz))
	barra.draw_rect(Rect2(lleno.position + Vector2(0, lleno.size.y * 0.8), Vector2(lleno.size.x, lleno.size.y * 0.2)), Color("#6a1512"))
	# Las dos rayas que separan los tercios (con la ayuda "Vida entera" la vida no va en tercios: sin rayas)
	var en_tercios: bool = not Guardado.ajuste("vida_entera")
	for i in ([1, 2] if en_tercios else []):
		barra.draw_rect(Rect2(HUECO.position.x + HUECO.size.x * i / 3.0 - 1, HUECO.position.y, 2, HUECO.size.y), Color("#1a1620"))
	# Los tercios perdidos, tapados con rayas oscuras en diagonal
	var perdido: float = HUECO.size.x * (3 - johnny.tercios_vivos()) / 3.0
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
	# El marco por encima, y la vida que le queda (solo esa, para que quepa entre las dos rayas; la máxima, en la pausa)
	barra.draw_texture_rect(MARCO, Rect2(0, 0, ANCHO, ALTO), false)
	var fuente := Tema.FUENTE
	var texto := str(ceili(vida))
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var donde := Vector2(roundf((ANCHO - ancho) / 2.0), ALTO / 2.0 + 5)
	barra.draw_string_outline(fuente, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Tema.LINEA)
	barra.draw_string(fuente, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f0e8d4"))
	if con_escudo():
		pintar_escudo()
	pintar_balas()


# La barra del escudo, pegada encima de la de vida, borde con borde (y las balas, encima de ella): dentro, el acero
# azul con su brillo, como la armadura del Gymbro (barra_jefe.gd), y lo perdido en claro, como en la de vida; encima,
# lo que le queda en números
func pintar_escudo() -> void:
	var temblor_escudo := Vector2(sin(tiempo * 70.0) * 3.0, cos(tiempo * 55.0) * 2.0) * escudo_temblor
	barra.draw_set_transform(Vector2(0, -ALTO_ESCUDO) + temblor_escudo.round())
	barra.draw_rect(HUECO_ESCUDO, Color("#1a1620"))
	var claro := HUECO_ESCUDO
	claro.size.x *= escudo_perdida
	barra.draw_rect(claro, Color("#f4faff") if escudo_espera > ESPERA - 0.08 else Color("#b8cde4"))
	var lleno := HUECO_ESCUDO
	lleno.size.x *= escudo_vista
	barra.draw_rect(lleno, Color("#7f9fc2"))
	barra.draw_rect(Rect2(lleno.position, Vector2(lleno.size.x, 2)), Color("#d8ecff"))
	barra.draw_rect(Rect2(lleno.position + Vector2(0, lleno.size.y - 2), Vector2(lleno.size.x, 2)), Color("#55708f"))
	barra.draw_texture_rect(MARCO_ESCUDO, Rect2(0, 0, ANCHO, ALTO_ESCUDO), false)
	var fuente := Tema.FUENTE
	var texto := Idioma.t("escudo %d") % ceili(johnny.escudo)
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var donde := Vector2(roundf((ANCHO - ancho) / 2.0), ALTO_ESCUDO / 2.0 + 5)
	barra.draw_string_outline(fuente, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Tema.LINEA)
	barra.draw_string(fuente, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f0e8d4"))
	barra.draw_set_transform(Vector2.ZERO)


# Las balas del cargador, en fila encima de la barra (el lanzallamas y el lanza ácido, su depósito)
func pintar_balas() -> void:
	var w: Dictionary = johnny.base(johnny.huecos.fuego)
	var lejos: bool = johnny.mano != "fuego"
	if w.has("deposito"):
		pintar_deposito(w, lejos)
		return
	var parpadeo: bool = johnny.recargando > 0.0 and int(Time.get_ticks_msec() / 200) % 2 == 0
	var tam := Vector2(5, 10) if w.cargador > 16 else Vector2(10, 20)   # las del MP5, más pequeñas para que quepan
	var hueco := 2.0
	if w.cargador > 32:   # (la MP5 mejorada, aún más pequeñas)
		tam = Vector2(3, 8)
		hueco = 1.0
	var x := HUECO.position.x
	var abajo := -4.0 - (ALTO_ESCUDO if con_escudo() else 0.0)   # (con escudo, encima de su barra)
	var dibujo: Texture2D = CARTUCHO if w.cartucho else BALA
	var sitios := []   # dónde va cada bala, para las que salen volando
	for i in w.cargador:
		sitios.append(x)
		var color := Color.WHITE
		if i >= johnny.balas:
			color = Color(0.5, 0.5, 0.5, 0.6 if parpadeo else 0.22)   # gastada
		if lejos:
			color.a *= 0.5
		var r := Rect2(x, abajo - tam.y, tam.x, tam.y)
		if nuevas.has(i):
			# recién metida: aparece desde arriba y más grande, y se asienta
			var k := clampf(nuevas[i] / 0.2, 0.0, 1.0)
			if k <= 0.0:
				color.a = 0.22
			r = r.grow(roundf((1.0 - k) * 2.0))
			r.position.y -= roundf((1.0 - k) * 6.0)
		barra.draw_texture_rect(dibujo, r, false, color)
		x += tam.x + hueco
	# las que se acaban de disparar: saltan hacia arriba, caen girando un poco y se apagan
	for g in gastadas:
		var i: int = g[0]
		if i >= sitios.size():
			continue
		var t: float = g[1]
		var salto := Vector2(t * 40.0, -60.0 * t + 260.0 * t * t)
		var c := Color(1, 0.9, 0.6, 1.0 - t / 0.35)
		barra.draw_set_transform(Vector2(sitios[i], abajo - tam.y) + tam / 2.0 + salto, t * 9.0)
		barra.draw_texture_rect(dibujo, Rect2(-tam / 2.0, tam), false, c)
		barra.draw_set_transform(Vector2.ZERO)
	# La reserva: la munición de su tipo que lleva, la que comparte con las otras armas que la gastan (en naranja si ya
	# no le queda ninguna)
	var donde := Vector2(x + 4, abajo - 2)
	var texto := "+∞" if johnny.pistola_sin_fin() else "+%d" % johnny.reserva()
	var color_texto := Color("#f0e8d4") if johnny.reserva() > 0 or texto == "+∞" else Color("#ff9f1c")
	color_texto.a = 0.5 if lejos else 1.0
	barra.draw_string_outline(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(Tema.LINEA, color_texto.a))
	barra.draw_string(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color_texto)


# El depósito del lanzallamas, del lanza ácido o del lanza rayos, encima de la barra de vida: una barra (naranja de
# gasolina, verde de ácido o celeste de batería, COLORES_DEPOSITO) que se vacía mientras echa el chorro, con una rayita por cada segundo (con poco, late en
# rojo), y al lado el icono de lo que lo llena con cuántos lleva en la mochila (en naranja si no queda ninguno). Al
# recargar se va llenando. Más apagado si lleva en la mano el arma cuerpo a cuerpo
func pintar_deposito(w: Dictionary, lejos: bool) -> void:
	var colores: Array = COLORES_DEPOSITO[w.relleno]
	var a := 0.5 if lejos else 1.0
	var r := Rect2(HUECO.position.x, -18.0 - (ALTO_ESCUDO if con_escudo() else 0.0), 120.0, 14.0)
	var parte: float = johnny.deposito / w.deposito
	if johnny.recargando > 0.0:
		parte = 1.0 - johnny.recargando / w.recarga
	barra.draw_rect(r.grow(2.0), Color(Tema.LINEA, a))
	barra.draw_rect(r, Color(Color("#1a1620"), a))
	var luz := 0.0
	if parte < 0.25 and johnny.recargando <= 0.0:
		luz = 0.6 * absf(sin(tiempo * PI * 2.5))
	var lleno := Rect2(r.position, Vector2(roundf(r.size.x * clampf(parte, 0.0, 1.0) / 2.0) * 2.0, r.size.y))
	barra.draw_rect(lleno, Color(colores[0].lerp(Color("#e0503a"), luz), a))
	barra.draw_rect(Rect2(lleno.position, Vector2(lleno.size.x, 4)), Color(colores[1].lerp(Color("#ff8a6a"), luz), a))
	barra.draw_rect(Rect2(lleno.position + Vector2(0, lleno.size.y - 4), Vector2(lleno.size.x, 4)), Color(colores[2], a))
	for i in range(1, ceili(w.deposito)):
		var x := r.position.x + roundf(r.size.x * i / w.deposito)
		barra.draw_rect(Rect2(x - 1, r.position.y, 2, r.size.y), Color(Color("#1a1620"), a * 0.8))
	var g: int = johnny.reserva()
	barra.draw_texture_rect(icono(Objetos.icono(w.relleno)), Rect2(r.end.x + 8, r.position.y - 1, 16, 16), false, Color(1, 1, 1, a))
	var texto := "x%d" % g
	var color := Color("#f0e8d4") if g > 0 else Color("#ff9f1c")
	color.a = a
	var donde := Vector2(r.end.x + 26, r.end.y)
	barra.draw_string_outline(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(Tema.LINEA, a))
	barra.draw_string(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
