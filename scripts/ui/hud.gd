# El HUD de Johnny, en la franja de abajo de la pantalla (la del muro de abajo, 64 de alto), como el del JS
# (src/ui.js, updateHud; #hud en style.css). Así la barra de la portera y la de la horda, arriba, no se tapan.
# Va ordenado por importancia: lo que se usa al pelear, grande; lo que solo informa, pequeño y sin marco.
#   - La barra de vida en su marco (barra-vida.png), partida en tres tercios. Los tercios perdidos se tapan
#     con rayas oscuras, porque ya no se curan. Encima, la vida en números. Al recibir un golpe, la barra
#     tiembla y lo perdido se queda en claro un momento antes de bajar; con poca vida, la sangre late.
#   - Sobre la barra, las balas del cargador: una por cada bala que cabe (las gastadas, apagadas) y la
#     reserva. Al recargar, las gastadas parpadean. Más apagadas si lleva en la mano el arma cuerpo a cuerpo.
#     Con el lanzallamas, en vez de las balas, el depósito: una barra de gasolina y las gasolinas de la mochila.
#   - Al lado, las armas: la de la mano en una casilla grande con el borde amarillo y la otra, pequeña y
#     apagada (con la tecla de cambiar). Al cambiar dan un saltito y el nombre sale encima un momento.
#   - Luego, los lanzables: el que se lanza ahora en su casilla, con cuántos quedan en la esquina, y los demás
#     en pequeño al lado (en gris si no queda ninguno).
#   - A la derecha, sin marco: la llave de la portera (si la lleva, entra con un brillo), la mochila (una
#     cajita por casilla, las llenas encendidas) y los dólares, que suben contando con un "+5" que flota.
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
const GRANDE := 44.0      # la casilla del arma en la mano (casilla-grande.png, de 22 píxeles)
const PEQUENA := 28.0     # la de la otra arma
const MEDIANA := 36.0     # la del lanzable de ahora
const MARCOS := {
	"grande": preload("res://assets/ui/casilla-grande.png"),
	"mediana": preload("res://assets/ui/casilla-mediana.png"),
	"pequena": preload("res://assets/ui/casilla-pequena.png"),
}
const NOMBRE := 1.6       # lo que se ve el nombre del arma al cambiar (segundos)

var johnny: Node2D
var partida: Node

var fila := HBoxContainer.new()
var barra := Control.new()
var armas := Control.new()      # las dos casillas de las armas
var lanzar := Control.new()     # el lanzable de ahora y los demás
var recursos := Control.new()   # la llave, la mochila y el dinero, pegados a la derecha
var texturas := {}              # los iconos ya cargados

# Las armas: cuál estaba en la mano y las animaciones al cambiar (de 0 a 1 el intercambio; las demás, de 1 a 0)
var en_mano := ""
var mano_antes := ""
var cambio := 1.0
var salto_arma := 0.0
var destello_arma := 0.0
var nombre_arma := 0.0            # el rato que le queda al nombre
# Los lanzables: el que se ve, el de antes (sale del tambor) y cuántos había
var tipo_visto := ""
var tipo_antes := ""
var cuenta_antes := -1
var giro := 1.0
var salto_cuenta := 0.0
var destello_lanzar := 0.0
# El dinero que se ve (sube contando hasta el de verdad) y los "+5" que flotan: [cantidad, tiempo]
var dinero_visto := -1.0
var dinero_real := -1
var ganado: Array = []
var llave_t := -1.0             # desde cuándo lleva la llave (para el brillo al cogerla)

# La barra que se mueve: al perder vida, el trozo perdido se queda un momento en claro y luego baja
# poco a poco (como en los juegos de lucha); al curarse, sube poco a poco
const ESPERA := 0.45      # lo que tarda en empezar a bajar el trozo perdido
const BAJADA := 0.9       # cuánta barra baja por segundo (en partes de la barra)
var vista := -1.0         # la parte de la barra que se ve llena ahora (0 a 1)
var perdida := -1.0       # hasta dónde llega el trozo claro de lo perdido
var espera := 0.0
var temblor := 0.0        # el temblor de la barra al recibir un golpe (se apaga solo)
var tiempo := 0.0

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
	add_child(fila)
	barra.custom_minimum_size = Vector2(ANCHO, ALTO)
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	barra.draw.connect(pintar_barra)
	fila.add_child(barra)
	armas.custom_minimum_size = Vector2(GRANDE + PEQUENA + 8, GRANDE + 4)
	armas.draw.connect(pintar_armas)
	fila.add_child(armas)
	lanzar.custom_minimum_size = Vector2(MEDIANA, GRANDE + 4)
	lanzar.draw.connect(pintar_lanzar)
	fila.add_child(lanzar)
	recursos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	recursos.draw.connect(pintar_recursos)
	add_child(recursos)


func _process(delta: float) -> void:
	tiempo += delta
	# en la franja de abajo (las balas se pintan por encima de la barra de vida; debajo queda la línea de ayuda)
	fila.position = Vector2(14, roundf(get_viewport_rect().size.y - FRANJA / 2.0 - fila.size.y / 2.0) - 7.0)
	recursos.position = fila.position
	if johnny == null:
		return
	mirar_armas(delta)
	mirar_lanzar(delta)
	mirar_recursos(delta)
	mover_barra(delta)
	mirar_balas(delta)
	barra.queue_redraw()
	armas.queue_redraw()
	lanzar.queue_redraw()
	recursos.queue_redraw()


func icono(nombre: String) -> Texture2D:
	if not texturas.has(nombre):
		texturas[nombre] = load("res://assets/ui/iconos/%s.png" % nombre)
	return texturas[nombre]


func icono_lanzable(k: String) -> String:
	return k if k in ["molotov", "granada"] else Objetos.icono(Recetas.LISTA[k].icono)


# Una casilla: el marco de metal (casilla-*.png) y el icono dentro. "luz" apaga la que no está en uso. El icono
# puede ir corrido ("corrido", para la animación del tambor) y se recorta al hueco de dentro.
func casilla(c: Control, r: Rect2, nombre: String, luz := 1.0, corrido := Vector2.ZERO) -> void:
	var marco: Texture2D = MARCOS.grande if r.size.x > 38 else (MARCOS.mediana if r.size.x > 31 else MARCOS.pequena)
	var m := 0.55 + 0.45 * luz
	c.draw_texture_rect(marco, r, false, Color(m, m, m))
	c.draw_rect(hueco_de(r), Color("#5a4e63", 0.55 * luz))   # el hueco, algo encendido si está en uso
	if nombre != "":
		icono_dentro(c, nombre, r, corrido, Color(luz, luz, luz, 0.4 + 0.6 * luz))


# El hueco de dentro de una casilla (el marco tiene 4 píxeles del dibujo de grueso contando el filo, de 22)
func hueco_de(r: Rect2) -> Rect2:
	return r.grow(-roundf(r.size.x * 4.0 / 22.0))


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
			nombre_arma = NOMBRE
		en_mano = ahora
		mano_antes = johnny.mano
	cambio = move_toward(cambio, 1.0, delta / 0.24)
	salto_arma = move_toward(salto_arma, 0.0, delta * 5.0)
	destello_arma = move_toward(destello_arma, 0.0, delta * 4.0)
	nombre_arma = maxf(nombre_arma - delta, 0.0)


# Al cambiar de arma, la nueva salta de la casilla pequeña a la grande (haciendo un arco por arriba) y la
# vieja baja a la pequeña; luego las esquinas amarillas se cierran sobre la nueva
func pintar_armas() -> void:
	var h: Dictionary = johnny.huecos
	var otra: String = h.fuego if johnny.mano == "cuerpo" else h.cuerpo
	var grande := Rect2(2, 2, GRANDE, GRANDE)
	var pequena := Rect2(GRANDE + 8, 2 + GRANDE - PEQUENA, PEQUENA, PEQUENA)
	var k := muelle(cambio)
	var arco := Vector2(0, -sin(cambio * PI) * 12.0)
	var vieja := mezclar(grande, pequena, k)
	vieja.position -= arco * 0.4
	casilla(armas, vieja, Objetos.icono(otra), lerpf(1.0, 0.6, cambio))
	if cambio >= 1.0:
		tecla(armas, pequena.position + Vector2(PEQUENA - 8, -8), "Q")
	var nueva := mezclar(pequena, grande, k)
	nueva.position += arco
	con_salto(armas, nueva, salto_arma)
	casilla(armas, nueva, Objetos.icono(en_mano), lerpf(0.6, 1.0, cambio))
	destello(armas, nueva, destello_arma)
	if cambio > 0.6:
		esquinas(armas, nueva, (1.0 - cambio) * 25.0)
	armas.draw_set_transform(Vector2.ZERO)
	# el nombre, encima un momento al cambiar (y se apaga al final)
	if nombre_arma > 0.0:
		var a := clampf(nombre_arma / 0.4, 0.0, 1.0)
		texto(armas, Vector2(2, -30), Armas.datos(en_mano).nombre, 16, Color(Tema.AMARILLO, a))


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
	# el ancho depende de cuántos otros haya al lado
	lanzar.custom_minimum_size.x = MEDIANA + 8 + 26 * (lz.tipos().size() - 1)


# Al cambiar de lanzable, como el tambor de un revólver: el viejo sale por la izquierda y el nuevo entra por
# la derecha, dentro del hueco
func pintar_lanzar() -> void:
	var lz: Lanzables = partida.lanzables
	var n := lz.cuantas(lz.tipo)
	var r := Rect2(2, 2 + GRANDE - MEDIANA, MEDIANA, MEDIANA)
	var k := muelle(giro)
	casilla(lanzar, r, icono_lanzable(lz.tipo), 1.0 if n > 0 else 0.35, Vector2((1.0 - k) * MEDIANA, 0))
	if giro < 1.0:
		var m := 1.0 if lz.cuantas(tipo_antes) > 0 else 0.35
		icono_dentro(lanzar, icono_lanzable(tipo_antes), r, Vector2(-k * MEDIANA, 0), Color(m, m, m, 1.0 - giro))
	destello(lanzar, r, destello_lanzar)
	if n > 0:
		esquinas(lanzar, r, (1.0 - k) * 10.0)
	# cuántos quedan, en la esquina de abajo a la derecha (en rojo si ninguno), con saltito si cambia
	var s := "x%d" % n
	var donde := Vector2(r.end.x - ancho_texto(s, 16) + 4, r.end.y - 1)
	con_salto(lanzar, Rect2(donde - Vector2(0, 12), Vector2(ancho_texto(s, 16), 12)), salto_cuenta)
	texto(lanzar, donde, s, 16, Tema.TINTA if n > 0 else Tema.ROJO)
	lanzar.draw_set_transform(Vector2.ZERO)
	var otros: Array = lz.tipos().filter(func(t): return t != lz.tipo)
	if otros.is_empty():
		return
	tecla(lanzar, r.position + Vector2(MEDIANA - 6, -10), "F")
	# los demás, en pequeño y apagados, con su número debajo
	var x := r.end.x + 12
	for t in otros:
		var m := lz.cuantas(t)
		var l := 0.85 if m > 0 else 0.3
		lanzar.draw_texture_rect(icono(icono_lanzable(t)), Rect2(x, r.position.y, 20, 20), false, Color(l, l, l, 0.5 + 0.5 * l))
		texto(lanzar, Vector2(x + 10, r.end.y), str(m), 12, Color(Tema.GRIS, 0.5 + 0.5 * l), true)
		x += 26


# ── La llave, la mochila y el dinero ──

func mirar_recursos(delta: float) -> void:
	var dinero: int = partida.cartera()
	if dinero_real < 0 or dinero < dinero_real:
		dinero_visto = dinero   # al empezar, o si gasta: de golpe
	elif dinero > dinero_real:
		# lo que acaba de coger, en un "+N" (si coge varios seguidos, se suman en el mismo)
		if ganado.is_empty() or ganado[-1][1] > 0.3:
			ganado.append([0, 0.0])
		ganado[-1][0] += dinero - dinero_real
	dinero_real = dinero
	# el contador sube contando (más deprisa cuanto más falta)
	dinero_visto = move_toward(dinero_visto, dinero, delta * maxf(12.0, (dinero - dinero_visto) * 4.0))
	for g in ganado:
		g[1] += delta
	ganado = ganado.filter(func(g): return g[1] < 1.1)
	if partida.planta.tiene_llave:
		llave_t = 0.0 if llave_t < 0.0 else llave_t + delta
	else:
		llave_t = -1.0


# De derecha a izquierda: el dinero pegado al borde, la mochila y la llave
func pintar_recursos() -> void:
	var y := roundf(fila.size.y / 2.0)
	var x := get_viewport_rect().size.x - 28.0
	# el dinero (en amarillo mientras sube) y los "+N" que suben y se apagan
	var contando: bool = roundi(dinero_visto) < dinero_real
	var s := "$%d" % roundi(dinero_visto)
	x -= ancho_texto(s, 16)
	texto(recursos, Vector2(x, y + 6), s, 16, Tema.AMARILLO if contando else Tema.TINTA)
	for g in ganado:
		var t: float = g[1]
		texto(recursos, Vector2(x + 4, y - 14 - t * 18.0), "+%d" % g[0], 14, Color(Tema.VERDE, clampf((1.1 - t) / 0.4, 0.0, 1.0)))
	x -= 28
	recursos.draw_texture_rect(icono("billete"), Rect2(x, y - 12, 24, 24), false)
	# la mochila: una cajita por casilla, en dos filas; las llenas encendidas (si está llena, parpadea)
	var llenas := Objetos.casillas(partida.mochila).size()
	var columnas := ceili(Objetos.MOCHILA / 2.0)
	var llena := llenas >= Objetos.MOCHILA and int(tiempo * 3.0) % 2 == 0
	x -= 18 + columnas * 7
	for i in Objetos.MOCHILA:
		var r := Rect2(x + (i % columnas) * 7, y - 7 + (i / columnas) * 7, 5, 5)
		recursos.draw_rect(r.grow(1), Tema.LINEA)
		recursos.draw_rect(r, (Tema.AMARILLO if llena else Tema.TINTA) if i < llenas else Tema.METAL)
	x -= 28
	recursos.draw_texture_rect(icono("mochila"), Rect2(x, y - 12, 24, 24), false)
	# la llave: al cogerla, entra grande con un brillo amarillo que se apaga
	if llave_t < 0.0:
		return
	var nombre: String = partida.nombre_jefa()
	x -= 40 + ancho_texto(nombre, 14)
	texto(recursos, Vector2(x + 28, y + 5), nombre, 14, Tema.AMARILLO)
	var r := Rect2(x, y - 12, 24, 24)
	var k := clampf(1.0 - llave_t / 1.2, 0.0, 1.0)
	if k > 0.0:
		recursos.draw_circle(r.get_center(), 14.0 + 10.0 * k, Color(Tema.AMARILLO, 0.45 * k))
	con_salto(recursos, r, k)
	recursos.draw_texture_rect(icono("llave"), r, false)
	recursos.draw_set_transform(Vector2.ZERO)


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
	barra.position.y = roundf(cos(tiempo * 55.0) * 2.0 * temblor)


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


# Las balas del cargador, en fila encima de la barra (el lanzallamas, su depósito)
func pintar_balas() -> void:
	var w: Dictionary = Armas.datos(johnny.huecos.fuego)
	var lejos: bool = johnny.mano != "fuego"
	if w.has("deposito"):
		pintar_deposito(w, lejos)
		return
	var parpadeo: bool = johnny.recargando > 0.0 and int(Time.get_ticks_msec() / 200) % 2 == 0
	var tam := Vector2(5, 10) if w.cargador > 16 else Vector2(10, 20)   # las del MP5, más pequeñas para que quepan
	var hueco := 2.0
	var x := HUECO.position.x
	var abajo := -4.0
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
	# La reserva: las balas de repuesto que lleva (en naranja si ya no le queda ninguna)
	var donde := Vector2(x + 4, abajo - 2)
	var texto := "+∞" if w.get("sin_municion", false) or johnny.pistola_sin_fin() else "+%d" % johnny.reserva
	var color_texto := Color("#f0e8d4") if johnny.reserva > 0 or texto == "+∞" else Color("#ff9f1c")
	color_texto.a = 0.5 if lejos else 1.0
	barra.draw_string_outline(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(Tema.LINEA, color_texto.a))
	barra.draw_string(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color_texto)


# El depósito del lanzallamas, encima de la barra de vida: una barra de gasolina que se vacía mientras echa fuego,
# con una rayita por cada segundo (con poco, late en rojo), y al lado las gasolinas de la mochila (en naranja si no
# queda ninguna). Al recargar se va llenando. Más apagado si lleva en la mano el arma cuerpo a cuerpo
func pintar_deposito(w: Dictionary, lejos: bool) -> void:
	var a := 0.5 if lejos else 1.0
	var r := Rect2(HUECO.position.x, -18.0, 120.0, 14.0)
	var parte: float = johnny.deposito / w.deposito
	if johnny.recargando > 0.0:
		parte = 1.0 - johnny.recargando / w.recarga
	barra.draw_rect(r.grow(2.0), Color(Tema.LINEA, a))
	barra.draw_rect(r, Color(Color("#1a1620"), a))
	var luz := 0.0
	if parte < 0.25 and johnny.recargando <= 0.0:
		luz = 0.6 * absf(sin(tiempo * PI * 2.5))
	var lleno := Rect2(r.position, Vector2(roundf(r.size.x * clampf(parte, 0.0, 1.0) / 2.0) * 2.0, r.size.y))
	barra.draw_rect(lleno, Color(Color("#ff9f1c").lerp(Color("#e0503a"), luz), a))
	barra.draw_rect(Rect2(lleno.position, Vector2(lleno.size.x, 4)), Color(Color("#ffd23f").lerp(Color("#ff8a6a"), luz), a))
	barra.draw_rect(Rect2(lleno.position + Vector2(0, lleno.size.y - 4), Vector2(lleno.size.x, 4)), Color(Color("#b8561c"), a))
	for i in range(1, ceili(w.deposito)):
		var x := r.position.x + roundf(r.size.x * i / w.deposito)
		barra.draw_rect(Rect2(x - 1, r.position.y, 2, r.size.y), Color(Color("#1a1620"), a * 0.8))
	var g: int = johnny.gasolinas()
	barra.draw_texture_rect(icono("obj-gasolina"), Rect2(r.end.x + 8, r.position.y - 1, 16, 16), false, Color(1, 1, 1, a))
	var texto := "x%d" % g
	var color := Color("#f0e8d4") if g > 0 else Color("#ff9f1c")
	color.a = a
	var donde := Vector2(r.end.x + 26, r.end.y)
	barra.draw_string_outline(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(Tema.LINEA, a))
	barra.draw_string(Tema.FUENTE, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
