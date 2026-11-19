# El HUD de Johnny. En el ordenador (19 nov), en su propia franja de abajo (FRANJA, 100 de alto, con fondo liso): la
# pantalla está partida en HUD y juego, y el juego solo se ve encima (la cámara se corre: partida.encuadrar). Todo en una
# fila y a su tamaño (ESCALA_FRANJA): la vida a la izquierda, las curas a su lado, el nombre del sitio con el minimapa
# en medio y las armas a la derecha. En el móvil no hay franja: va encima del juego y más grande (ESCALA).
# Así la barra de la portera y la de la horda, arriba, no se tapan.
# Va ordenado por importancia: lo que se usa al pelear, grande; lo que solo informa, pequeño y sin marco.
#   - La barra de vida en su marco (barra-vida.png), partida en tres tercios. Los tercios perdidos se tapan
#     con rayas oscuras, porque ya no se curan. Encima, la vida en números. Al recibir un golpe, la barra
#     tiembla y lo perdido se queda en claro un momento antes de bajar; con poca vida, la sangre late.
#   - Justo encima de la barra, la del mutágeno (19 nov; partida.llenar_mutageno): igual que la de vida, con un líquido
#     morado oscuro y el tanto por ciento que lleva; la llenan los zombis al caer y, al llegar al 100 %, da un mutágeno y
#     vuelve a empezar. Sube poco a poco con burbujas dentro y un brillo que la recorre; al completarse, destella en
#     blanco y baja a cero. Encima de ella, el escudo, si lo hay.
#   - Sobre la barra, las balas del cargador: una por cada bala que cabe (las gastadas, apagadas) y la
#     reserva (la munición de su tipo, compartida con las armas que la gastan). Al recargar, las gastadas parpadean.
#     Más apagadas si lleva en la mano el arma cuerpo a cuerpo.
#     Con el lanzallamas, en vez de las balas, el depósito: una barra de gasolina y las gasolinas de la mochila
#     (con el lanza ácido, la barra en verde y sus bidones de ácido).
#   - A la derecha de la barra de vida, en medio de la franja, las curas que lleva (las vendas y el botiquín; Objetos.USABLES), cada una en su
#     casilla con cuántas tiene y su tecla (1 y 2: partida.usar_cura). Solo salen las que lleva; mientras no sirven se
#     apagan (con la vida llena; el botiquín, que devuelve un tercio, si además no ha perdido ninguno). Al coger una o gastarla, la casilla da un saltito (y al gastarla, un destello).
#   - En la esquina de abajo a la derecha, las armas: la de la mano en la misma esquina, en la casilla más grande
#     y con el borde amarillo, y la otra a su lado, apagada (con la tecla de cambiar). Al cambiar dan un saltito
#     (sin el nombre encima: el arma se ve en su dibujo).
#   - A su izquierda, los lanzables que lleva a mano (los de repuesto no se ven), cada uno en su casilla con
#     cuántos le quedan: el que se lanza ahora, en una casilla grande como la del arma, encendido y con las esquinas
#     amarillas, que la F pasa al siguiente.
#   - En el medio de la franja, el nombre del sitio (partida.lugar, con la letra pequeña) y debajo el minimapa (minimapa.gd, a
#     2/3 de su tamaño: MAPA_FRANJA), que coloca este HUD.
#   - En el móvil (M114), abajo van los pulgares: la vida y las balas, arriba a la izquierda, con el minimapa debajo, y
#     las armas, los lanzables y las curas solo en los botones del móvil (tactil.gd), sin casillas (colocar_movil).
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
# La barra del mutágeno: como la de vida (su marco, barra-vida.png, y su tamaño), con el líquido morado oscuro
const ALTO_MUTAGENO := ALTO
# el relleno, su parte de arriba (más clara), su sombra de abajo y las burbujas
const MORADOS_MUTAGENO := [Color("#3e1a5c"), Color("#52267a"), Color("#2a0f40"), Color("#9a6cc8")]
const ABAJO := 8.0        # lo que queda entre el borde de abajo de la pantalla y la barra o las casillas
const ARRIBA_MOVIL := 8.0 # en el móvil, lo que queda entre el borde de arriba y las balas
const BOTONES_ARRIBA := 230.0   # en el móvil, lo que ocupan los botones de arriba a la derecha (a tamaño 1: tactil.gd)
# Las cifras de la vida: la letra del juego solo se ve bien a 16 o 32 (más pequeña se deforma), así que estas van dibujadas
# aquí, cada una de 4 × 6 píxeles (fila a fila), con píxeles de 2 de pantalla (1,33 × ESCALA)
const CIFRAS := {"0": "0110 1001 1001 1001 1001 0110", "1": "0010 0110 0010 0010 0010 0111", "2": "0110 1001 0001 0010 0100 1111",
	"3": "1110 0001 0110 0001 0001 1110", "4": "1001 1001 1001 1111 0001 0001", "5": "1111 1000 1110 0001 0001 1110",
	"6": "0110 1000 1110 1001 1001 0110", "7": "1111 0001 0010 0010 0100 0100", "8": "0110 1001 0110 1001 1001 0110",
	"9": "0110 1001 1001 0111 0001 0110", "/": "0001 0010 0010 0100 0100 1000",
	# (para la barra del mutágeno: el tanto por ciento y «MAX»)
	"%": "1101 1101 0010 0100 1011 1011", "M": "1001 1111 1111 1001 1001 1001", "A": "0110 1001 1001 1111 1001 1001",
	"X": "1001 1001 0110 0110 1001 1001"}
const PIXEL_CIFRA := 4.0 / 3.0
# En el móvil, todo el HUD una vez y media más grande que sus medidas (cada píxel del dibujo, 3 de pantalla en vez de 2:
# se sigue viendo nítido). En el ordenador va en la franja de abajo (FRANJA) a su tamaño (ESCALA_FRANJA): más grande no
# cabe en una sola fila en una pantalla de 960 (la vida, las curas, el minimapa y las armas se pisarían)
const ESCALA := 1.5
const ESCALA_FRANJA := 1.0
# La franja del HUD en el ordenador (19 nov): abajo, de lado a lado y de este alto, con su fondo; el juego se ve solo
# encima (la cámara de Johnny se corre para que él quede en medio de lo que se ve: partida.encuadrar). En el móvil no la
# hay: el HUD va encima del juego, como antes, porque abajo están los pulgares
const FRANJA := 100.0
const FONDO_FRANJA := Color("#1b1822")
const RAYA_FRANJA := Color("#463840")      # la raya de arriba de la franja (del tono del marco de las barras)
const LUZ_FRANJA := Color("#6e585e")       # su filo de luz, justo debajo
const ABAJO_FRANJA := 5.0   # en la franja, lo que queda entre su borde de abajo y la barra de vida
const MAPA_FRANJA := 2.0 / 3.0   # el minimapa en la franja, a esta parte de su tamaño (como el resto del HUD)
var escala := ESCALA_FRANJA     # la de ahora (ESCALA en el móvil)
var fondo := Control.new()      # el fondo de la franja
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
	"nitrogeno": [Color("#9edef8"), Color("#ecfaff"), Color("#3a76b6")],
}

var johnny: Node2D
var partida: Node

var fila := HBoxContainer.new()
var derecha := HBoxContainer.new()   # los lanzables y las armas, en la esquina de la derecha
var barra := Control.new()
var curas := Control.new()      # las vendas y el botiquín, encima de las balas
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
var antes_i := -1   # el montón de los lanzables que se lanzaba antes de cambiar con la F (su sitio en la fila)
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
# La del mutágeno: lo que se ve lleno (de 0 a 1), el mutágeno que había (para ver cuándo se gana uno), las vueltas que le
# quedan por llenar hasta arriba antes de bajar a cero, y las animaciones: el destello al completarse y el pulso al subir
var mut_vista := -1.0
var mut_cuenta := -1
var mut_barra_antes := -1
var mut_vueltas := 0
var mut_destello := 0.0
var mut_pulso := 0.0

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
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.draw.connect(pintar_fondo)
	add_child(fondo)
	fila.add_theme_constant_override("separation", 14)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fila.scale = Vector2(escala, escala)
	add_child(fila)
	barra.custom_minimum_size = Vector2(ANCHO, ALTO)
	barra.draw.connect(pintar_barra)
	fila.add_child(barra)
	curas.size = Vector2(MEDIANA, MEDIANA + 4)
	curas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curas.scale = Vector2(escala, escala)
	curas.draw.connect(pintar_curas)
	curas.visible = false
	add_child(curas)
	derecha.add_theme_constant_override("separation", 14)
	derecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	derecha.scale = Vector2(escala, escala)
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
	# en el móvil, más grande y encima del juego; en el ordenador, a su tamaño y en la franja de abajo
	escala = ESCALA if Tactil.activo else ESCALA_FRANJA
	for c in [fila, curas, derecha]:
		c.scale = Vector2(escala, escala)
	var franja := 0.0 if Tactil.activo else FRANJA
	if franja != Pantalla.franja_hud:   # (se ha cambiado al móvil o al ordenador: la cámara, a su sitio)
		Pantalla.franja_hud = franja
		if partida and partida.has_method("reencuadrar"):
			partida.reencuadrar()
	fondo.visible = franja > 0.0
	if Tactil.activo:
		colocar_movil(pantalla)
	else:
		colocar(pantalla)
	if johnny == null:
		return
	mirar_armas(delta)
	mirar_lanzar(delta)
	mirar_curas(delta)
	mover_barra(delta)
	mover_escudo(delta)
	mover_mutageno(delta)
	mirar_balas(delta)
	barra.queue_redraw()
	curas.queue_redraw()
	armas.queue_redraw()
	lanzar.queue_redraw()
	encima.queue_redraw()


# En el ordenador: todo en la franja de abajo (FRANJA), con su fondo, en una fila: a la izquierda la vida con las balas, el
# mutágeno y el escudo encima; a su lado, las curas; en medio, el nombre del sitio con el minimapa debajo, y a la derecha
# los lanzables y las armas
func colocar(pantalla: Vector2) -> void:
	derecha.visible = true
	var arriba := pantalla.y - FRANJA   # donde empieza la franja
	var dentro := FRANJA - 4.0          # lo que queda debajo de su raya de arriba
	fondo.position = Vector2(0, arriba)
	fondo.size = Vector2(pantalla.x, FRANJA)
	fondo.queue_redraw()
	# la barra de vida, abajo (las balas, el mutágeno y el escudo se pintan por encima de ella)
	fila.position = Vector2(14, roundf(pantalla.y - ABAJO_FRANJA - fila.size.y * escala))
	# las curas, a su derecha y en medio de la franja (con el borde de la primera casilla a 16 de la barra)
	var x_curas := fila.position.x + ANCHO * escala + 16.0
	curas.position = Vector2(roundf(x_curas - sitio_cura(0).position.x * escala),
		roundf(arriba + 4.0 + (dentro - curas.size.y * escala) / 2.0))
	# las casillas de la derecha, en la esquina y en medio de la franja (sus dibujos dejan 2 de aire debajo)
	var x := pantalla.x - 14 - derecha.size.x * escala
	derecha.position = Vector2(roundf(x), roundf(arriba + 4.0 + (dentro - (derecha.size.y - 2) * escala) / 2.0))
	# en medio, entre las curas (con su sitio guardado aunque no haya, para que no se mueva) y las armas: el nombre del
	# sitio y debajo el minimapa (minimapa.gd, más pequeño), en el centro de la pantalla si cabe
	var desde := x_curas + (2 * (MEDIANA + 10) - 4) * escala + 16.0
	var hasta := x - 16.0
	var mapa: Control = partida.get_node_or_null("Pantalla/Minimapa") if partida else null
	var ancho_mapa: float = mapa.size.x * MAPA_FRANJA if mapa else 0.0
	var alto_mapa: float = mapa.size.y * MAPA_FRANJA if mapa else 0.0
	var centro := clampf(pantalla.x / 2.0, desde + ancho_mapa / 2.0, maxf(desde + ancho_mapa / 2.0, hasta - ancho_mapa / 2.0))
	var alto_nombre := 20.0
	var y_nombre := arriba + 4.0 + roundf((dentro - alto_nombre - 4.0 - alto_mapa) / 2.0)
	if mapa:
		mapa.scale = Vector2(MAPA_FRANJA, MAPA_FRANJA)
		mapa.position = Vector2(roundf(centro - ancho_mapa / 2.0), y_nombre + alto_nombre + 4.0)
	var medio := minf(centro - desde, hasta - centro)
	poner_arriba(Vector2(roundf(centro - medio), roundf(medio * 2.0)), (pantalla.x - BarraJefe.ANCHO) / 2.0, 44.0, y_nombre - 2.0)


# El fondo de la franja: liso, con una raya arriba y su filo de luz
func pintar_fondo() -> void:
	fondo.draw_rect(Rect2(Vector2.ZERO, fondo.size), FONDO_FRANJA)
	fondo.draw_rect(Rect2(0, 0, fondo.size.x, 3), RAYA_FRANJA)
	fondo.draw_rect(Rect2(0, 3, fondo.size.x, 1), LUZ_FRANJA)


func _exit_tree() -> void:
	Pantalla.franja_hud = 0.0   # (fuera de la partida no hay franja)


# En el móvil (M114), abajo están los pulgares: el joystick a la izquierda y los botones a la derecha. Allí solo quedan
# los botones (tactil.gd), que ya llevan las armas, los lanzables y las curas: las casillas de la derecha y las de las
# curas no salen (estaban repetidas, y debajo del pulgar). La vida, con sus balas encima, va arriba a la izquierda, y el
# minimapa justo debajo; el nombre del sitio, en el hueco de arriba entre la vida y los botones de arriba a la derecha
# (las curas, el inventario y la pausa), y la barra del jefe también, o, si no cabe, debajo de la vida, en el medio
func colocar_movil(pantalla: Vector2) -> void:
	derecha.visible = false
	# (el sitio de las balas encima de la barra, con el del escudo aunque no lo haya: así la barra no se mueve al tenerlo)
	fila.position = Vector2(14, roundf(ARRIBA_MOVIL + (24.0 + ALTO_ESCUDO + ALTO_MUTAGENO + 6.0) * escala))
	var bajo_vida := fila.position.y + fila.size.y * escala + 10.0
	var mapa: Control = partida.get_node_or_null("Pantalla/Minimapa") if partida else null
	if mapa:
		mapa.scale = Vector2.ONE
		mapa.position = Vector2(fila.position.x, roundf(bajo_vida))
	var desde := fila.position.x + ANCHO * escala + 14.0
	var hasta := pantalla.x - BOTONES_ARRIBA * Tactil.escala - 14.0
	var jefe_x := (desde + hasta - BarraJefe.ANCHO) / 2.0
	var jefe_y := 44.0
	if hasta - desde < BarraJefe.ANCHO:
		jefe_x = maxf((pantalla.x - BarraJefe.ANCHO) / 2.0, (mapa.position.x + mapa.size.x + 14.0) if mapa else 0.0)
		jefe_y = bajo_vida + 32.0   # (con su nombre encima, que mide 30)
	poner_arriba(Vector2(desde, hasta - desde), jefe_x, jefe_y)


# El nombre del sitio (de "desde.x", "desde.y" de ancho: si no le cabe, partida.poner_lugar le pone la letra pequeña) y
# la barra del jefe (en el lugar del nombre, que se esconde mientras está)
func poner_arriba(lugar: Vector2, jefe_x: float, jefe_y: float, lugar_y := 4.0) -> void:
	if partida == null:
		return
	var etiqueta: Control = partida.get_node_or_null("Pantalla/Lugar")
	if etiqueta and (etiqueta.position.x != lugar.x or etiqueta.size.x != lugar.y or etiqueta.position.y != lugar_y):   # (solo si cambia)
		etiqueta.position = Vector2(lugar.x, lugar_y)
		etiqueta.size.x = lugar.y
	partida.set("lugar_grande", Tactil.activo)   # (en la franja del ordenador, siempre con la letra pequeña)
	var jefe: Control = partida.get_node_or_null("Pantalla/Jefa")
	if jefe:
		jefe.position = Vector2(roundf(jefe_x), jefe_y)


# El marco amarillo del latido, alrededor de la parte que pide la guía (las balas, encima de la barra de vida)
func pintar_latido() -> void:
	var cual: Control = {"curas": curas, "lanzar": lanzar, "armas": armas, "balas": barra}.get(latido)
	if cual == null or not cual.visible:
		return
	var r := Rect2(cual.global_position - encima.global_position, cual.size * escala)
	if latido == "balas":
		r = Rect2(r.position + Vector2(HUECO.position.x, -28) * escala, Vector2(ANCHO * 0.55, 24) * escala)
	var k := 0.5 + 0.5 * sin(tiempo * 7.0)
	encima.draw_rect(r.grow(4.0 + 4.0 * k), Color(Tema.AMARILLO, 0.5 + 0.5 * k), false, 3.0)


func icono(nombre: String) -> Texture2D:
	if not texturas.has(nombre):
		texturas[nombre] = Objetos.textura(nombre)   # (las armas, con el dibujo de la tienda)
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
	if Objetos.de_tienda(tex):
		lado = hueco_de(r).size.x   # el de la tienda (las armas) llena su cuadro en diagonal: justo el hueco, sin cortarle las puntas
	var donde := Rect2(r.get_center() - Vector2(lado, lado) / 2.0 + corrido, Vector2(lado, lado))
	var visto := donde.intersection(hueco_de(r))
	if visto.size.x <= 0.0 or visto.size.y <= 0.0:
		return
	var prop := tex.get_size() / donde.size
	c.draw_texture_rect_region(tex, visto, Rect2((visto.position - donde.position) * prop, visto.size * prop), color)


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


# Lo que se pulsa para una acción, pequeño y pegado a una casilla (cambiar de arma, cambiar de lanzable, las curas): la
# tecla que tenga puesta o, jugando con el mando (Controles.con_mando), el dibujo de su botón (boton_mando). "donde" es la
# esquina de arriba a la izquierda de la tecla (12 × 12); el botón del mando va centrado en el mismo sitio
func tecla(c: Control, donde: Vector2, accion: String) -> void:
	var boton := Controles.boton_de(accion) if Controles.con_mando else null
	if boton:
		boton_mando(c, donde + Vector2(6, 6), boton)
		return
	var r := Rect2(donde, Vector2(12, 12))
	c.draw_rect(r.grow(1), Tema.LINEA)
	c.draw_rect(r, Tema.GRIS)
	c.draw_string(Tema.FUENTE, donde + Vector2(3, 10), Controles.tecla_de(accion).left(1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Tema.LINEA)


# Los colores de los botones de la cara del mando (los de un mando de Xbox) y el gris de los demás
const COLOR_BOTON := {JOY_BUTTON_A: Color("#5fb84a"), JOY_BUTTON_B: Color("#d9483b"), JOY_BUTTON_X: Color("#3f7fd9"),
	JOY_BUTTON_Y: Color("#e6b91e")}
const LETRA_BOTON := {JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",   # no-tr (nombres de botones)
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_LEFT_STICK: "L", JOY_BUTTON_RIGHT_STICK: "R",   # no-tr
	JOY_BUTTON_START: "≡", JOY_BUTTON_BACK: "▪"}   # no-tr
const GRIS_MANDO := Color("#a49cb0")
const CRUCETA := Color("#5e566c")   # (más oscura que GRIS_MANDO: clara parecería la cruz de una cura)


# El dibujo de un botón del mando, centrado en "centro": los de la cara (A, B, X, Y), redondos y de su color; LB y RB,
# alargados; LT y RT, gatillos (con la punta redonda); la cruceta, una cruz con el brazo que toca en amarillo; el resto
# (pulsar los sticks, Start, Select, empujar un stick), un redondo gris con su letra
func boton_mando(c: Control, centro: Vector2, ev: InputEvent) -> void:
	if ev is InputEventJoypadMotion:
		if ev.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
			var r := Rect2(centro - Vector2(9, 3), Vector2(18, 10))
			c.draw_circle(Vector2(centro.x, r.position.y), 10.0, Tema.LINEA, true, -1.0, false)
			c.draw_rect(r.grow(1), Tema.LINEA)
			c.draw_circle(Vector2(centro.x, r.position.y), 9.0, GRIS_MANDO, true, -1.0, false)
			c.draw_rect(r, GRIS_MANDO)
			letra_boton(c, centro + Vector2(0, 1), "LT" if ev.axis == JOY_AXIS_TRIGGER_LEFT else "RT", Tema.LINEA)   # no-tr
		else:
			redondo(c, centro, GRIS_MANDO)
			letra_boton(c, centro, "L" if ev.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y] else "R", Tema.LINEA)   # no-tr (el stick)
		return
	var b: int = ev.button_index
	match b:
		JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y:
			redondo(c, centro, COLOR_BOTON[b])
			letra_boton(c, centro, LETRA_BOTON[b], Color.WHITE)
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			var r := Rect2(centro - Vector2(10, 6), Vector2(20, 12))
			c.draw_rect(r.grow(1), Tema.LINEA)
			c.draw_rect(r, GRIS_MANDO)
			letra_boton(c, centro, LETRA_BOTON[b], Tema.LINEA)
		JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
			var brazo: Vector2 = {JOY_BUTTON_DPAD_UP: Vector2(0, -1), JOY_BUTTON_DPAD_DOWN: Vector2(0, 1),
				JOY_BUTTON_DPAD_LEFT: Vector2(-1, 0), JOY_BUTTON_DPAD_RIGHT: Vector2(1, 0)}[b]
			var largo := Rect2(centro - Vector2(8, 3), Vector2(16, 6))
			var alto := Rect2(centro - Vector2(3, 8), Vector2(6, 16))
			c.draw_rect(largo.grow(1), Tema.LINEA)
			c.draw_rect(alto.grow(1), Tema.LINEA)
			c.draw_rect(largo, CRUCETA)
			c.draw_rect(alto, CRUCETA)
			c.draw_rect(Rect2(centro + brazo * 5.0 - Vector2(3, 3), Vector2(6, 6)), Tema.AMARILLO)
		_:
			redondo(c, centro, GRIS_MANDO)
			letra_boton(c, centro, LETRA_BOTON.get(b, "·"), Tema.LINEA)   # no-tr


# Un botón redondo del mando, con su borde oscuro (draw_circle: Formas.disco, a este tamaño, sale octogonal)
func redondo(c: Control, centro: Vector2, color: Color) -> void:
	c.draw_circle(centro, 8.0, Tema.LINEA, true, -1.0, false)
	c.draw_circle(centro, 7.0, color, true, -1.0, false)


# Las letras de un botón del mando, centradas en "centro"
func letra_boton(c: Control, centro: Vector2, texto: String, color: Color) -> void:
	var ancho := ancho_texto(texto, 11)
	c.draw_string(Tema.FUENTE, Vector2(roundf(centro.x - ancho / 2.0), centro.y + 4), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)


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
	if cambio >= 1.0 and otra != "":   # (sin arma a distancia no hay a qué cambiar)
		tecla(armas, pequena.position + Vector2(MEDIANA - 8, -8), "cambiar_arma")
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
	# (el montón que se lanza, por su sitio y su clave: desde el 16 nov puede llevar dos de la misma)
	var visto := "%d %s" % [lz.elegido, lz.tipo] if lz.tipo != "" else ""
	if visto != tipo_visto:
		if tipo_visto != "":
			giro = 0.0             # otro lanzable: gira el tambor
			antes_i = tipo_visto.get_slice(" ", 0).to_int()
			destello_lanzar = 1.0
		tipo_visto = visto
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
	var ahora := clampi(partida.lanzables.elegido, 0, lista.size() - 1)
	var antes := antes_i if giro < 1.0 and antes_i < lista.size() else -1
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
		var n := lz.cuantos_en("l%d" % i)
		var activo := t != "" and i == lz.elegido
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
	# las esquinas, sobre el de ahora (viniendo del de antes al cambiar)
	var ahora := clampi(lz.elegido, 0, lista.size() - 1)
	var cursor: Rect2 = sitios[ahora]
	var antes := antes_i if antes_i < lista.size() else -1
	if giro < 1.0 and antes >= 0:
		cursor = mezclar(sitios[antes], cursor, k)
	if lz.cuantas(lz.tipo) > 0:
		esquinas(lanzar, cursor)
	# la F, sobre el que saldrá al pulsarla (el siguiente, como la Q en las armas), cuando ya ha terminado de cambiar, y
	# en su esquina de arriba más cerca del de ahora: la izquierda si está a su derecha y la derecha si vuelve al primero
	if lista.size() > 1 and giro >= 1.0:
		var i_sig := (ahora + 1) % lista.size()
		var siguiente: Rect2 = sitios[i_sig]
		var x := -4.0 if i_sig > ahora else siguiente.size.x - 8
		tecla(lanzar, siguiente.position + Vector2(x, -8), "cambiar_lanzable")


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
	curas.visible = llevadas > 0 and not Tactil.activo   # (en el móvil, en los botones de arriba a la derecha)
	curas.size.x = maxi(1, llevadas) * (MEDIANA + 10) - 4


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
		tecla(curas, r.position + Vector2(MEDIANA - 6, -10), Objetos.USABLES[id].accion)


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
	barra.position.y = fila.size.y - ALTO + roundf(cos(tiempo * 55.0) * 2.0 * temblor)   # (abajo en la fila)


# Como mover_barra, con el escudo: lo lleno es lo que tenía al empezar la planta (Acero y Blindaje, nuevo en cada una, y
# lo que quede de Endurecimiento, que no vuelve). Un golpe al escudo hace temblar solo su barra, porque la vida no se toca
func mover_escudo(delta: float) -> void:
	var tope: float = maxf(johnny.escudo_tope, johnny.escudo)
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


# Lo que ocupan, encima de la barra de vida, la del mutágeno y la del escudo (las balas van encima de las dos)
func alto_encima() -> float:
	return alto_mutageno() + (ALTO_ESCUDO if con_escudo() else 0.0)


# La barra del mutágeno no sale en el garaje (allí los zombis no lo dan: garaje.gd)
func con_mutageno() -> bool:
	return partida != null and not Garaje.activo


func alto_mutageno() -> float:
	return ALTO_MUTAGENO if con_mutageno() else 0.0


# La barra del mutágeno sigue a la de la partida (partida.mutageno_barra, de 0 a 99) poco a poco. Si entretanto se ha
# ganado un mutágeno (partida.mutageno ha subido), primero se llena hasta arriba, destella y baja a cero, y luego sigue
# hasta lo que sobró. Gastarlo en el ordenador no se anima
func mover_mutageno(delta: float) -> void:
	if not con_mutageno():
		return
	var meta: float = clampf(partida.mutageno_barra / float(partida.MUTAGENO_BARRA), 0.0, 1.0)
	if mut_cuenta < 0:
		mut_cuenta = partida.mutageno
		mut_barra_antes = partida.mutageno_barra
		mut_vista = meta
	if partida.mutageno > mut_cuenta:
		mut_vueltas += partida.mutageno - mut_cuenta
	mut_cuenta = partida.mutageno
	if partida.mutageno_barra != mut_barra_antes:
		mut_pulso = 1.0   # le han dado puntos: el borde de lo lleno se enciende
		mut_barra_antes = partida.mutageno_barra
	var hacia := 1.0 if mut_vueltas > 0 else meta
	if hacia < mut_vista and mut_vueltas == 0:
		mut_vista = hacia   # (ha bajado sin ganar uno: al cargar una partida o en el tope)
	# sube deprisa al principio y frena al llegar (y nunca más despacio que 0,25 de barra por segundo)
	mut_vista = move_toward(mut_vista, hacia, delta * maxf(absf(hacia - mut_vista) * 5.0, 0.25))
	if mut_vueltas > 0 and mut_vista >= 1.0:
		mut_vueltas -= 1
		mut_vista = 0.0
		mut_destello = 1.0
	mut_destello = move_toward(mut_destello, 0.0, delta * 1.4)
	mut_pulso = move_toward(mut_pulso, 0.0, delta * 3.0)


# La barra del mutágeno, justo encima de la de vida y como ella (su marco, su tamaño y sus cifras dibujadas a
# cuadraditos, pintar_cifras): dentro, el líquido morado oscuro con sus burbujas y su brillo, y el tanto por ciento. Al
# completarse (mut_destello), todo destella en blanco. En el tope (partida.TOPE), «MAX»
func pintar_mutageno() -> void:
	barra.draw_set_transform(Vector2(0, -ALTO_MUTAGENO))
	var hueco := HUECO
	barra.draw_rect(hueco, Color("#1a1620"))
	var lleno := hueco
	lleno.size.x = roundf(hueco.size.x * clampf(mut_vista, 0.0, 1.0))
	var blanco := mut_destello * mut_destello
	if lleno.size.x > 0.0:
		barra.draw_rect(lleno, MORADOS_MUTAGENO[0].lerp(Color.WHITE, blanco))
		barra.draw_rect(Rect2(lleno.position, Vector2(lleno.size.x, lleno.size.y * 0.45)), MORADOS_MUTAGENO[1].lerp(Color.WHITE, blanco))
		barra.draw_rect(Rect2(lleno.position + Vector2(0, lleno.size.y * 0.8), Vector2(lleno.size.x, lleno.size.y * 0.2)), MORADOS_MUTAGENO[2].lerp(Color.WHITE, blanco))
		# las burbujas: puntitos claros que avanzan por dentro, cada uno a su paso y a su altura
		for i in 9:
			var x := fmod(i * 41.0 + tiempo * (14.0 + (i % 3) * 7.0), hueco.size.x)
			if x < lleno.size.x - 2.0:
				var y := roundf(1.0 + (i % 4) * (lleno.size.y - 4.0) / 3.0)
				barra.draw_rect(Rect2(roundf(lleno.position.x + x), lleno.position.y + y, 2, 2), Color(MORADOS_MUTAGENO[3], 0.75))
		# el brillo que la recorre de izquierda a derecha cada 2,5 segundos
		var bx := fmod(tiempo, 2.5) / 2.5 * (hueco.size.x + 40.0) - 20.0
		var brillo := Rect2(roundf(lleno.position.x + bx), lleno.position.y, 6, lleno.size.y).intersection(lleno)
		if brillo.size.x > 0.0:
			barra.draw_rect(brillo, Color(1, 1, 1, 0.18))
		# el borde de lo lleno, encendido un momento al recibir puntos
		barra.draw_rect(Rect2(lleno.end.x - 2, lleno.position.y, 2, lleno.size.y), Color(MORADOS_MUTAGENO[3], 0.35 + 0.65 * mut_pulso))
	barra.draw_texture_rect(MARCO, Rect2(0, 0, ANCHO, ALTO_MUTAGENO), false, Color.WHITE.lerp(Color(1.6, 1.6, 1.6), blanco))
	var cifra := "%d%%" % roundi(clampf(mut_vista, 0.0, 1.0) * 100.0)
	if partida.mutageno_total() >= partida.TOPE:
		cifra = "MAX"   # no-tr (como en el inventario)
	pintar_cifras(cifra)
	barra.draw_set_transform(Vector2.ZERO)


# Compara las balas con las del fotograma anterior: las que faltan salen volando, las que sobran entran
func mirar_balas(delta: float) -> void:
	for g in gastadas:
		g[1] += delta
	gastadas = gastadas.filter(func(g): return g[1] < 0.35)
	for i in nuevas.keys():
		nuevas[i] += delta
		if nuevas[i] > johnny.METER_DURA:
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
			# entran una detrás de otra, como si las metiera a mano (Johnny no dispara hasta que entran todas: johnny.meter)
			nuevas[i] = -johnny.paso_meter(b - balas_antes) * (i - balas_antes)
	balas_antes = b


# En qué tercio cae esa vida para su color (1 rojo, 2 amarillo, 3 verde): solo pasa al de arriba si tiene más que el
# tope del de abajo (johnny.vida_tope, redondeado igual)
static func tercio_de_color(vida: float, maxima: float) -> int:
	if vida > roundi(maxima * 2.0 / 3.0):
		return 3
	if vida > roundi(maxima / 3.0):
		return 2
	return 1


# Los colores de la vida, uno por tercio (con uno, con dos y con los tres): el de la barra y el que late con poca vida,
# el brillo de arriba y el que late, y la sombra de abajo
const TONOS_VIDA := [
	[Color("#8a1f1a"), Color("#e0503a"), Color("#c24a38"), Color("#ff8a6a"), Color("#6a1512")],   # rojo
	[Color("#a8801a"), Color("#e0b030"), Color("#d4aa36"), Color("#ffd870"), Color("#6e520e")],   # amarillo
	[Color("#3d7a26"), Color("#62b03a"), Color("#5ea23e"), Color("#9ad870"), Color("#28521a")],   # verde
]


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
	# el color va por tercios de la vida que tiene: con los tres, verde; con dos, amarillo; con uno, rojo (16 nov). Justo
	# en el borde de un tercio, el de abajo (17 nov: con 77 de 115, el tope de dos tercios redondeado, salía verde)
	var tonos: Array = TONOS_VIDA[tercio_de_color(vida, maxima) - 1]
	barra.draw_rect(lleno, tonos[0].lerp(tonos[1], luz))
	barra.draw_rect(Rect2(lleno.position, Vector2(lleno.size.x, lleno.size.y * 0.45)), tonos[2].lerp(tonos[3], luz))
	barra.draw_rect(Rect2(lleno.position + Vector2(0, lleno.size.y * 0.8), Vector2(lleno.size.x, lleno.size.y * 0.2)), tonos[4])
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
	# El marco por encima, y la vida en números, pequeños para que quepan entre las dos rayas
	barra.draw_texture_rect(MARCO, Rect2(0, 0, ANCHO, ALTO), false)
	pintar_cifras("%d/%d" % [ceili(vida), roundi(maxima)])
	if con_mutageno():
		pintar_mutageno()
	if con_escudo():
		pintar_escudo()
	pintar_balas()


# Lo que mide cada píxel de las cifras dentro de la barra: siempre 2 de pantalla (con ESCALA, 1,33; a tamaño 1, 2)
func pixel_cifra() -> float:
	return 2.0 / escala


# La vida, en el centro de la barra, píxel a píxel (CIFRAS): primero el borde oscuro y encima las cifras
func pintar_cifras(texto: String) -> void:
	var inicio := Vector2(ANCHO / 2.0 - (texto.length() * 5 - 1) * pixel_cifra() / 2.0, ALTO / 2.0 - 3 * pixel_cifra()).round()
	for borde in [true, false]:
		for i in texto.length():
			var filas: PackedStringArray = CIFRAS[texto[i]].split(" ")
			for y in filas.size():
				for x in filas[y].length():
					if filas[y][x] == "0":
						continue
					var punto := inicio + Vector2(i * 5 + x, y) * pixel_cifra()
					if borde:
						barra.draw_rect(Rect2(punto - Vector2.ONE * pixel_cifra(), Vector2.ONE * pixel_cifra() * 3), Tema.LINEA)
					else:
						barra.draw_rect(Rect2(punto, Vector2.ONE * pixel_cifra()), Color("#f0e8d4"))


# La barra del escudo, pegada encima de la de vida, borde con borde (y las balas, encima de ella): dentro, el acero
# azul con su brillo, como la armadura del Gymbro (barra_jefe.gd), y lo perdido en claro, como en la de vida; encima,
# lo que le queda en números
func pintar_escudo() -> void:
	var temblor_escudo := Vector2(sin(tiempo * 70.0) * 3.0, cos(tiempo * 55.0) * 2.0) * escudo_temblor
	barra.draw_set_transform(Vector2(0, -ALTO_ESCUDO - alto_mutageno()) + temblor_escudo.round())
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
	if johnny.huecos.fuego == "":
		return   # (sin arma a distancia: ni balas ni reserva)
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
	var abajo := -4.0 - alto_encima()   # (encima de la barra del mutágeno y, con escudo, de la suya)
	# Si en una fila no caben (la gatling, con su cinta de 100 o más), van en dos filas en zigzag: una abajo y otra
	# encima, alternando, de borde a borde del marco de la vida (la primera, en su borde izquierdo y la última, en el
	# derecho; L42, 16 nov). Antes, en una sola fila, se salían muy lejos por la derecha
	var en_zigzag: bool = w.cargador * (tam.x + hueco) - hueco > ANCHO
	var paso := 0.0   # (en zigzag, lo que va de una bala a la siguiente, que está en la otra fila)
	if en_zigzag:
		x = 0.0
		paso = (ANCHO - tam.x) / maxf(w.cargador - 1, 1)
	var dibujo: Texture2D = CARTUCHO if w.cartucho else BALA
	var sitios := []   # dónde va cada bala (la esquina de abajo a la izquierda), para las que salen volando
	for i in w.cargador:
		var sitio := Vector2(x, abajo)
		if en_zigzag:
			sitio = Vector2(roundf(i * paso), abajo - (tam.y + 1.0 if i % 2 == 1 else 0.0))
		sitios.append(sitio)
		var color := Color.WHITE
		if i >= johnny.balas:
			color = Color(0.5, 0.5, 0.5, 0.6 if parpadeo else 0.22)   # gastada
		if lejos:
			color.a *= 0.5
		var r := Rect2(sitio.x, sitio.y - tam.y, tam.x, tam.y)
		if nuevas.has(i):
			# recién metida: aparece desde arriba y más grande, y se asienta
			var k := clampf(nuevas[i] / johnny.METER_DURA, 0.0, 1.0)
			if k <= 0.0:
				color.a = 0.22
			r = r.grow(roundf((1.0 - k) * 2.0))
			r.position.y -= roundf((1.0 - k) * 6.0)
		barra.draw_texture_rect(dibujo, r, false, color)
		x += tam.x + hueco
	if en_zigzag:
		x = ANCHO + hueco   # (la reserva, a la derecha del marco)
	# las que se acaban de disparar: saltan hacia arriba, caen girando un poco y se apagan
	for g in gastadas:
		var i: int = g[0]
		if i >= sitios.size():
			continue
		var t: float = g[1]
		var salto := Vector2(t * 40.0, -60.0 * t + 260.0 * t * t)
		var c := Color(1, 0.9, 0.6, 1.0 - t / 0.35)
		barra.draw_set_transform(sitios[i] - Vector2(0, tam.y) + tam / 2.0 + salto, t * 9.0)
		barra.draw_texture_rect(dibujo, Rect2(-tam / 2.0, tam), false, c)
		barra.draw_set_transform(Vector2.ZERO)
	# La reserva: la munición de su tipo que lleva, la que comparte con las otras armas que la gastan (en naranja si ya
	# no le queda ninguna)
	var donde := Vector2(x + 4, abajo - 2)
	var sin_fin: bool = johnny.pistola_sin_fin()
	var texto := "+" if sin_fin else "+%d" % johnny.reserva()
	var color_texto := Color("#f0e8d4") if johnny.reserva() > 0 or sin_fin else Color("#ff9f1c")
	color_texto.a = 0.5 if lejos else 1.0
	barra.draw_string_outline(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(Tema.LINEA, color_texto.a))
	barra.draw_string(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color_texto)
	if sin_fin:
		# El «∞» no está en ninguna letra del juego (en el móvil y la web salía un cuadro): se dibuja a mano, píxel a píxel
		var ancho := Tema.FUENTE.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var origen := Vector2(roundf(donde.x + ancho + 2.0), donde.y - 10.0)
		var filas := [".##.##.", "#..#..#", "#..#..#", ".##.##."]
		for pasada in 2:
			for fila in filas.size():
				for col in 7:
					if filas[fila][col] != "#":
						continue
					var p := origen + Vector2(col, fila) * 2.0
					if pasada == 0:
						barra.draw_rect(Rect2(p, Vector2(2, 2)).grow(2.0), Color(Tema.LINEA, color_texto.a))
					else:
						barra.draw_rect(Rect2(p, Vector2(2, 2)), color_texto)


# El depósito del lanzallamas, del lanza ácido o del lanza rayos, encima de la barra de vida: una barra (naranja de
# gasolina, verde de ácido o celeste de batería, COLORES_DEPOSITO) que se vacía mientras echa el chorro, con una rayita por cada segundo (con poco, late en
# rojo), y al lado el icono de lo que lo llena con cuántos lleva en la mochila (en naranja si no queda ninguno). Al
# recargar se va llenando. Más apagado si lleva en la mano el arma cuerpo a cuerpo
func pintar_deposito(w: Dictionary, lejos: bool) -> void:
	var colores: Array = COLORES_DEPOSITO[w.relleno]
	var a := 0.5 if lejos else 1.0
	var r := Rect2(HUECO.position.x, -18.0 - alto_encima(), 120.0, 14.0)
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
