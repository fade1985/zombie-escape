# La gota de ácido que cuelga de la boquilla del lanza ácido (Armas.DATOS.desintegrador) mientras Johnny no echa el
# chorro: se va hinchando en el labio de abajo de la boquilla, cuelga un momento estirándose, se suelta y cae al suelo,
# donde salpica un poquito (sin charco) con un «plic». Luego empieza otra. Se pinta a píxeles del dibujo de Johnny (de
# 2 unidades, en su misma rejilla) y con los verdes del ácido, para que parezca parte del dibujo.
#
# Va de hija de Johnny, pero se pinta en el mundo (top_level): la que cae se queda donde se soltó aunque Johnny ande.
# Johnny le dice en cada paso dónde está el labio de la boquilla (gotear(), con la punta del dibujo de reposo de ahora,
# que trae su hoja en "puntas": tools/hoja_lanza_acido.py). El paso en que no se lo dice (anda, echa el chorro, lleva
# otra arma o se queda sin ácido), la gota que colgaba se suelta (o, si era un granito, se queda en la boquilla).
# La motosierra (6 nov) usa la misma gota, pero de sangre y más de tarde en tarde: cuelga de la punta de la espada
# (Armas.DATOS.motosierra, "punta") quieto y andando, y gotea también de espaldas.
class_name Goteo
extends Node2D

const HINCHA := Vector2(1.2, 2.4)   # lo que tarda en hincharse cada gota (al azar entre estos dos), en segundos
const CUELGA := 0.4                 # y lo que cuelga entera, estirándose, antes de soltarse
const PESO := 600.0                 # lo que acelera al caer (unidades por segundo, cada segundo)
# Lo que cae desde el labio hasta el suelo (en la pantalla) según hacia dónde mira Johnny: de frente, el tubo apunta al
# suelo; de lado y en diagonal, lo lleva a la altura de la cintura. De espaldas apunta hacia arriba: no gotea
const CAIDA := {"s": 4.0, "se": 30.0, "e": 40.0, "ne": 44.0, "no": 44.0, "o": 40.0, "so": 30.0}
const COLORES := {"c": Color("#f4ffd9"), "v": Color("#c7e04a"), "o": Color("#96b430")}   # (claros: que se vea en el suelo oscuro)
# La de sangre de la motosierra: los rojos de la sangre de los zombis (partida.gd, SANGRE), sin brillo blanco; tarda más
# en hincharse (de vez en cuando) y cae desde la punta de la espada: de frente y en las diagonales de frente la espada
# va casi a ras de suelo; de lado, a la altura de la rodilla, y de espaldas sube hacia el fondo
const COLORES_SANGRE := {"c": Color("#e0503e"), "v": Color("#b52d22"), "o": Color("#7a1f1a")}
const HINCHA_SANGRE := Vector2(2.5, 5.0)
const CAIDA_SANGRE := {"s": 4.0, "se": 6.0, "e": 16.0, "ne": 18.0, "n": 14.0, "no": 18.0, "o": 16.0, "so": 6.0}
# La gota que cuelga, de pequeña a entera y estirada (cada letra, un píxel del dibujo: "c" el brillo, "v" el verde del
# ácido y "o" la sombra; la columna del medio, debajo del labio): un granito, una bolita, la gota con su cuello (fina
# arriba y gorda abajo, como la del icono) y la gota estirada a punto de caer. La que cae es la entera (la tercera)
const FORMAS := [
	[".v."],
	[".v.", "cvo"],
	[".v.", "cvv", "vvo"],
	[".v.", ".v.", "cvv", "vvo"],
]

var labio := Vector2.ZERO   # el labio de la boquilla en el mundo (la esquina de arriba a la izquierda de su píxel)
var hacia := "s"            # hacia dónde mira Johnny
var pedido := false         # Johnny ha dicho en este paso dónde está el labio
var t := 0.0                # lo que lleva hinchándose la gota que cuelga (0 = no hay)
var dura := 0.0             # lo que tardará en hincharse
var cayendo: Array[Dictionary] = []   # las que caen: {"x", "y0" (donde se soltó), "y", "v", "suelo", "colores"}
var sangre := false         # la gota que cuelga es de sangre (la motosierra) y no de ácido


func _ready() -> void:
	top_level = true
	z_index = 4   # por encima de Johnny, como la llamarada
	dura = hinchado()


# Johnny lleva el lanza ácido sin echar el chorro: "donde", el labio de la boquilla en el mundo; "direccion", hacia
# dónde mira
func gotear(donde: Vector2, direccion: String, de_sangre := false) -> void:
	if de_sangre != sangre:
		# ha cambiado de arma: la gota que colgaba (de la otra) se quita y la nueva empieza de cero
		sangre = de_sangre
		t = 0.0
		dura = hinchado()
	pedido = caidas().has(direccion)
	labio = donde
	hacia = direccion


func caidas() -> Dictionary:
	return CAIDA_SANGRE if sangre else CAIDA


func colores() -> Dictionary:
	return COLORES_SANGRE if sangre else COLORES


# Lo que tardará en hincharse la próxima gota (al azar)
func hinchado() -> float:
	var h := HINCHA_SANGRE if sangre else HINCHA
	return randf_range(h.x, h.y)


func _physics_process(delta: float) -> void:
	if pedido:
		t += delta
		if t >= dura + CUELGA:
			soltar()
	elif t > 0.0:
		if t >= dura * 0.6:
			soltar()
		else:
			t = 0.0
	pedido = false
	# las que caen: aceleran y, al llegar al suelo, salpican
	var siguen: Array[Dictionary] = []
	for g in cayendo:
		g.v += PESO * delta
		g.y += g.v * delta
		if g.y + 6.0 >= g.suelo:
			salpicar(Vector2(g.x + 1.0, g.suelo), g.colores)
		else:
			siguen.append(g)
	cayendo = siguen
	queue_redraw()


# La gota se suelta del labio y empieza otra
func soltar() -> void:
	var y := labio.y + 2.0
	cayendo.append({"x": labio.x, "y0": y, "y": y, "v": 0.0, "suelo": y + caidas().get(hacia, 30.0), "colores": colores()})
	t = 0.0
	dura = hinchado()


# Al llegar al suelo: tres gotitas que saltan un poco a los lados y caen enseguida (sin charco), y un «plic»
func salpicar(pie: Vector2, cols: Dictionary) -> void:
	for i in 3:
		var v := Vector2(randf_range(25.0, 60.0) * (1.0 if i % 2 == 0 else -1.0), randf_range(-12.0, 12.0))
		Particulas.volar(self, pie, 2.0, v, randf_range(40.0, 80.0), cols["cv"[i % 2]], 2.0)
	Sonido.tocar("gota")


func _draw() -> void:
	if t > 0.0:
		var p := t / dura
		forma(FORMAS[0 if p < 0.3 else (1 if p < 0.6 else (2 if p < 1.0 else 3))], labio + Vector2(-2.0, 2.0), colores())
	for g in cayendo:
		# baja a saltos de un píxel del dibujo, como todo lo demás
		forma(FORMAS[2], Vector2(g.x - 2.0, g.y0 + roundf((g.y - g.y0) / 2.0) * 2.0), g.colores)


# Pinta una de las FORMAS con su esquina de arriba a la izquierda en "donde"
func forma(filas: Array, donde: Vector2, cols: Dictionary) -> void:
	for f in filas.size():
		var fila: String = filas[f]
		for c in fila.length():
			if cols.has(fila[c]):
				draw_rect(Rect2(donde + Vector2(c, f) * 2.0, Vector2(2.0, 2.0)), cols[fila[c]])
