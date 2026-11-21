# El Glotón: uno de los cuatro minijefes de los Apartamentos (docs/historial/JEFES_APARTAMENTOS.md, apartado 1). Un zombi
# grotesco que va a gatas, con la cabeza tan grande como el cuerpo y llena de ampollas de ácido, y una boca enorme
# con varias filas de dientes de la que salen lenguas como látigos. Lo común de los minijefes, en minijefe.gd.
#
#   - Lento: la cabeza le pesa más que el cuerpo.
#   - Latigazo: echa la cabeza atrás enroscando las lenguas, con el aviso de las cargas de los jefes por donde irán
#     (0,6 s), y las dispara en abanico: 16 de daño y un empujón si te alcanza una. Se paran en las paredes y los
#     muebles (el aviso acaba en estrella).
#   - Aspirar: abre la boca (0,8 s de aviso, con el cono marcado en el suelo) y durante 5 s tira de Johnny hacia
#     ella si está en el cono y le ve. El cono llega hasta el borde de la elipse limpia de su habitación (el ring),
#     esté donde esté él: lo que está en la porquería no lo aspira. Va de menos a más: empieza al 30 % y a los 3 s
#     tira con toda su fuerza; y cuanto más cerca, mucho más fuerte. Al máximo, a menos de 5 casillas arrastra a
#     Johnny aunque ande hacia atrás; más lejos, andando hacia atrás le gana, pero se nota mucho: a 8 casillas va a
#     unos 80 y de lejos a 105 (en vez de a 210; hasta el 28 oct, a 126 y a 140). También se libra esquivando (esquivando no tira), saliendo del cono (o metiéndose en la
#     porquería) o poniendo una pared en medio. Si Johnny llega a la boca, se lo come: 30 de daño y lo escupe lejos.
#   - Sangre ácida (9 nov): cada golpe o disparo que le das salpica un chorro de sangre verde que llega hasta donde
#     estaba Johnny (como la de los zombis, pero mucha más) y, al caer allí, deja un charco pequeño de ácido (dos si
#     está enfadado), que quema al pisarlo como el de la portera. Cuanto más lejos, más tarda en llegar (VUELO). Ya no quita vida directamente (hasta el 9 nov, un 1 %).
#     Como mucho uno cada 0,25 s (los perdigones de la escopeta cuentan como un golpe). Si le pegan los supervivientes
#     que acompañan a Johnny, le hacen daño igual pero no salpica. Con las armas especiales (el chorro y el rayo), también
#     salpica mientras le dan (17 nov: llamarada.gd, salpica).
#   - Una explosión (granada) le corta lo que esté haciendo (se tambalea): la manera de parar el aspirado.
# Enfadado (a media vida, «¡TENGO HAMBRE!»): el doble de lenguas, aspira con el doble de fuerza (al máximo arrastra
# desde 7 casillas, y de lejos Johnny va a 40) y cada golpe deja dos charcos de ácido.
extends Minijefe

const VELOCIDAD := 55.0
const GIRO := 2.0                      # lo deprisa que se gira mientras aspira (radianes por segundo)
const LENGUAS := [3, 6]                # cuántas lenguas en el latigazo (normal y enfadado)
const ABRE_LENGUAS := [0.4, 0.27]      # separación entre lenguas (enfadado, más juntas: son el doble)
const LARGO_LENGUA := 300.0            # lo largas que son (unas 9,4 casillas); el latigazo lo da a menos de este largo + 30
const ANCHO_LENGUA := 12.0             # medio ancho de cada lengua
const AVISO_LATIGAZO := 0.6
const DURA_LATIGAZO := 0.45
const DANO_LATIGAZO := 16
const GOLPE_LATIGAZO := 5              # fotograma del latigazo en el que las lenguas salen disparadas (en su animación de PixelLab)
const AVISO_ASPIRAR := 0.8
const DURA_ASPIRAR := 5.0
const CRECE_ASPIRAR := 3.0             # lo que tarda en tirar con toda su fuerza (hasta el 28 oct, 3,5 s)
const FUERZA_INICIAL := 0.3            # lo que tira nada más abrir la boca, de su fuerza (hasta el 28 oct, 0,2)
# A cuánto tira de Johnny con toda su fuerza y pegado a la boca (unidades por segundo que le suma hacia ella; normal
# y enfadado). Se apaga deprisa con la distancia (tiron_aspirado(), con APAGA_TIRON): Johnny anda a 210, así que al
# máximo le arrastra a menos de unas 5 casillas (7 enfadado) y más lejos le gana andando hacia atrás. Pero de lejos
# no se apaga del todo, que era lo que no se notaba (el dueño, 28 oct): a media distancia (TIRON_MEDIO) cae en línea
# recta hasta ALCANCE_MEDIO (de 8 casillas, 132 normal: Johnny anda hacia atrás a 78) y de unas 12 casillas para allá y
# hasta el borde del cono tira siempre TIRON_LEJOS (hasta el 28 oct, 70 y 140): andando hacia atrás, Johnny va a 105
# (a 40 enfadado), y quieto se le acerca poco a poco
const TIRON := [550.0, 1100.0]
const TIRON_MEDIO := [260.0, 400.0]
const TIRON_LEJOS := [105.0, 170.0]
const APAGA_TIRON := 420.0             # a qué distancia se apagaría del todo el tirón de cerca
const ALCANCE_MEDIO := 520.0           # y a cuál el de media distancia
const ALCANCE_ASPIRAR := 420.0         # hasta dónde aspira donde no hay elipse (la exposición, la tecla 7 en otro sitio)
const MEDIO_ASPIRAR := 0.85            # medio ángulo del cono por donde aspira
const DANO_COMER := 30
const CHARCOS := [1, 2]                # charcos de ácido que deja cada golpe (normal y enfadado)
const ACIDO_CADA := 0.25               # lo menos entre dos salpicones (los perdigones de un tiro, uno solo)
const VUELO := [0.3, 1.0, 600.0]       # lo que tarda el chorro en caer: de 0,3 s (pegado) a 1 s (a 600 o más)
const CHARCO := preload("res://escenas/armas/charco.tscn")
const TAMBALEO := 0.6                  # lo que le corta una explosión
const PIE := 30.0                      # a qué altura dibuja los pies respecto a su centro
const BOCA := 0.5                      # a qué altura tiene la boca (parte de "arriba"): adonde va el aire que aspira
const VERDE := Color("#c7e04a")
# El aire que aspira (pintar_aire)
const AIRE_RAYAS := 40                 # las corrientes de viento, con toda su fuerza (al empezar, el 40 %)
const AIRE_POLVO := 60                 # el polvo del suelo que arrastra
const AIRE_ARCOS := 4                  # los arcos de la succión, en el suelo
const AIRE_SUBE := 0.3                 # en qué último trozo del camino sube del suelo a la boca
const AIRE_GIRO := 1.4                 # lo que se retuerce el aire al entrarle en la boca (radianes)
const POLVO := [Color("#f2e6c9"), Color("#4a3a2c"), Color("#d8cdb4"), Color("#6b5a48"), Color("#ffffff")]
# Las lenguas del latigazo, pintadas con código (lengua.gd), iguales que las de su dibujo (colores sacados píxel a
# píxel de su hoja): contorno casi negro y capas de granate a rojo, cada una más clara, más estrecha y más arrimada al
# lado de la luz, con un brillo rosado cerca del borde. Las capas, de la más oscura (todo el ancho) a la más clara:
# color y lo que ocupa (en partes del ancho, contando desde el borde de la luz)
const PALETA := {
	"contorno": Color("#25100e"),
	"capas": [
		[Color("#64211e"), 1.0],
		[Color("#7f2b26"), 0.8],
		[Color("#a03830"), 0.6],
		[Color("#b7463a"), 0.4],
		[Color("#d36352"), 0.24],
		[Color("#b7463a"), 0.1],
	],
}
# De dónde salen: su boca en cada dirección, medida en el fotograma del golpe de su latigazo (de espaldas, por
# donde asoman las de su dibujo: por encima de la cabeza o por un lado). Van enteras por delante de su dibujo
# Una por fotograma del golpe (del 5 al 8), porque la cabeza se mueve y la lengua la sigue (21 nov: antes era una
# sola por dirección y en varias salían por debajo de la boca, casi de la rodilla mirando al suroeste)
const BOCAS := {
	"s": [Vector2(0, -28), Vector2(0, -28), Vector2(0, -28), Vector2(0, -28)],
	"se": [Vector2(31, -43), Vector2(34, -36), Vector2(28, -46), Vector2(24, -52)],
	"e": [Vector2(55, -39), Vector2(51, -33), Vector2(48, -53), Vector2(48, -60)],
	"ne": [Vector2(54, -56), Vector2(54, -56), Vector2(48, -56), Vector2(48, -63)],
	"n": [Vector2(0, -86), Vector2(0, -86), Vector2(0, -86), Vector2(0, -86)],
	"no": [Vector2(-62, -56), Vector2(-59, -56), Vector2(-52, -66), Vector2(-48, -70)],
	"o": [Vector2(-62, -40), Vector2(-59, -39), Vector2(-59, -59), Vector2(-56, -63)],
	"so": [Vector2(-49, -36), Vector2(-49, -49), Vector2(-42, -56), Vector2(-39, -63)],
}

var espera_latigazo := 1.5
var espera_aspirar := 6.0
var puntas := []                       # hasta dónde llega cada rayo del cono (puntas_aspirado())
var puntas_f := -1                     # (el fotograma en que se midió)
var acido_t := 0.0                     # para no salpicar ácido con cada perdigón
var elipse = null                      # la elipse limpia de su habitación, en unidades (la_elipse(); null, sin buscar)
var lenguas: Array[Lengua] = []        # las del latigazo (enfadado, todas; si no, las primeras)
var apuntadas := 0                     # cuántas lleva este latigazo
var lienzo_lenguas: LienzoPixelado     # donde se pintan las lenguas del latigazo...
var lienzo_sombra: LienzoPixelado      # ...y su sombra


func _ready() -> void:
	aguanta_acido = true   # (no se quema en los charcos de ácido: minijefe.gd, pisar)
	super()
	EfectoSuelo.precalentar(get_parent(), "latigazo")   # (que el primer chasquido no pare el juego)
	for i in LENGUAS[1]:
		var lengua := Lengua.new(PALETA)
		lengua.grueso = 7.0   # (eran 5 y 2: se veían como rayas planas)
		lengua.fino = 2.5
		lengua.borde = 2.0
		lengua.culebrea = 7.0
		lengua.largo = LARGO_LENGUA
		lengua.ancho = ANCHO_LENGUA
		lengua.desfase = i * 0.37
		lenguas.append(lengua)
	# Las lenguas y su sombra, a la medida de los píxeles de su dibujo (lienzo_pixelado.gd): las lenguas por encima de
	# todo (en "Vapor") y la sombra detrás de su dibujo. Llegan hasta su largo, más la boca y lo que culebrean
	var medio := int(LARGO_LENGUA) + 130
	lienzo_lenguas = LienzoPixelado.new(medio, pintar_lenguas)
	$Vapor.add_child(lienzo_lenguas)
	lienzo_sombra = LienzoPixelado.new(medio, pintar_sombra_lenguas)
	add_child(lienzo_sombra)
	move_child(lienzo_sombra, 0)


# Al empezar el latigazo, cada lengua apunta a su franja y mide hasta dónde llega (por si hay una pared o un mueble
# por medio)
func cambiar(nuevo: String, nuevos_datos := {}) -> void:
	super(nuevo, nuevos_datos)
	if nuevo == "aviso_latigazo":
		var angulos := angulos_lenguas()
		apuntadas = angulos.size()
		for i in apuntadas:
			lenguas[i].apuntar(self, angulos[i])


func pensar(delta: float, johnny: Node2D) -> void:
	espera_latigazo -= delta
	espera_aspirar -= delta
	acido_t -= delta
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"andar":
			perseguir(delta, johnny, VELOCIDAD)
			if marcha.length() > 10.0:
				mirada = marcha.normalized()
			if t >= dur:
				elegir(johnny, d)
		"aviso_latigazo":
			# echa la cabeza atrás; el aviso marca por dónde irán las lenguas (ya no cambia de idea)
			frenar(delta)
			if t >= AVISO_LATIGAZO:
				cambiar("latigazo", {"angulo": datos.angulo, "dado": false})
				Sonido.tocar("latigazo")
		"latigazo":
			frenar(delta)
			if not datos.dado and t >= 0.08:   # cuando las lenguas llegan al final
				datos.dado = true
				latigazos(johnny)
			if t >= DURA_LATIGAZO:
				andar(0.5 if enfadado() else 0.8)
		"aviso_aspirar":
			frenar(delta)
			girar_hacia(delta, hacia.normalized())
			if t >= AVISO_ASPIRAR:
				cambiar("aspirar")
				Sonido.tocar("rugido")
		"aspirar":
			frenar(delta)
			girar_hacia(delta, hacia.normalized())
			aspirar(delta, johnny, hacia, d)
			if t >= DURA_ASPIRAR:
				andar(0.6)
		"tambaleo":
			frenar(delta, 5.0)
			if t >= TAMBALEO:
				andar(0.4)
		"atontado":
			# le ha dado un bidón (M16, peligros/bidones.gd): ATONTA s sin moverse, con estrellitas (minijefe.gd)
			frenar(delta, 5.0)
			if t >= datos.get("dura", 5.0):
				andar(0.4)


func girar_hacia(delta: float, hacia: Vector2) -> void:
	if hacia == Vector2.ZERO:
		return
	var paso := GIRO * delta
	mirada = mirada.rotated(clampf(angle_difference(mirada.angle(), hacia.angle()), -paso, paso))


# Un "rayo" hasta Johnny: si choca con una pared o un mueble (capa 1), no le ve (como se_ve() del zombi)
func se_ve(johnny: Node2D) -> bool:
	var rayo := PhysicsRayQueryParameters2D.create(global_position, johnny.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


func elegir(johnny: Node2D, d: float) -> void:
	var ve := se_ve(johnny)
	var angulo := (johnny.global_position - global_position).angle()
	if ve and d < LARGO_LENGUA + 30.0 and espera_latigazo <= 0.0:
		espera_latigazo = 1.6 if enfadado() else 2.4
		mirada = Vector2.from_angle(angulo)
		cambiar("aviso_latigazo", {"angulo": angulo})
		return
	if ve and d > 90.0 and d < largo_aspirado(angulo, global_position) and espera_aspirar <= 0.0:
		espera_aspirar = 7.0 if enfadado() else 10.0
		mirada = Vector2.from_angle(angulo)
		cambiar("aviso_aspirar")
		gritar(Idioma.t("¡HAMBRE!"), VERDE)
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	andar(0.4)


# ── El latigazo ──

# Los ángulos de las lenguas, en abanico alrededor de donde apuntó
func angulos_lenguas() -> Array:
	var n: int = LENGUAS[fase - 1]
	var lista := []
	for i in n:
		lista.append(datos.angulo + (i - (n - 1) / 2.0) * ABRE_LENGUAS[fase - 1])
	return lista


# ¿Está Johnny dentro de alguna lengua, hasta donde llega? (como los latigazos del gerente mutado)
func latigazos(johnny: Node2D) -> void:
	Temblor.temblar(4.0)
	for i in apuntadas:
		lenguas[i].chasquido(self, Vector2(0, 6))
	for i in apuntadas:
		if lenguas[i].golpea(self, johnny):
			johnny.recibir_dano(DANO_LATIGAZO, self)
			johnny.empujar(Vector2.from_angle(lenguas[i].angulo) * 500.0)
			return


# ── Aspirar ──

# Tira de Johnny hacia la boca mientras esté en el cono, le vea y no esté esquivando. Si llega, se lo come
func aspirar(delta: float, johnny: Node2D, hacia: Vector2, d: float) -> void:
	# (el aire que entra lo pinta pintar_aire)
	if d > largo_aspirado(hacia.angle(), global_position) or absf(angle_difference(mirada.angle(), hacia.angle())) > MEDIO_ASPIRAR:
		return
	if not se_ve(johnny) or johnny.esquiva_t > 0.0:
		return
	# se suma a la velocidad de Johnny, que su frenada va parando: este empujón es justo el que, con esa frenada,
	# le deja el tirón sumado (anda a 210 hacia atrás y se queda en 210 - tirón)
	johnny.empujar(-hacia.normalized() * tiron_aspirado(d) * (exp(delta * johnny.ARRANQUE) - 1.0))
	if d < radio + johnny.RADIO + 6.0:
		comer(johnny, hacia)


# Lo fuerte que aspira: del 30 % al abrir la boca al 100 % a los CRECE_ASPIRAR s, y así hasta que la cierra
func fuerza_aspirado() -> float:
	return lerpf(FUERZA_INICIAL, 1.0, minf(1.0, t / CRECE_ASPIRAR))


# A cuánto tira de Johnny a esa distancia: cada vez más fuerte, y mucho más cuanto más cerca (va con el cuadrado de
# lo cerca que está: a 210, la cuarta parte que pegado a la boca); a media distancia, una recta que baja hasta
# ALCANCE_MEDIO; y de lejos, como poco TIRON_LEJOS. Gana el que más tire de los tres
func tiron_aspirado(d: float) -> float:
	var cerca := maxf(0.0, 1.0 - d / APAGA_TIRON)
	var medio: float = TIRON_MEDIO[fase - 1] * maxf(0.0, 1.0 - d / ALCANCE_MEDIO)
	return maxf(maxf(TIRON[fase - 1] * cerca * cerca, medio), TIRON_LEJOS[fase - 1]) * fuerza_aspirado()


# Hasta dónde llega el aspirado desde "desde" hacia "angulo": hasta el borde de la elipse limpia de su habitación (el
# ring), esté donde esté él; así lo que está en la porquería no lo aspira. Sin elipse, ALCANCE_ASPIRAR
func largo_aspirado(angulo: float, desde: Vector2) -> float:
	var ov := la_elipse()
	if ov.is_empty():
		return ALCANCE_ASPIRAR
	# encogido por los radios de la elipse, la elipse es un círculo de radio 1: dónde sale de él la raya que va de
	# "desde" hacia "angulo" (la segunda vez que cruza el borde; si no lo cruza, no llega a nada)
	var radios := Vector2(ov.rx, ov.ry)
	var o: Vector2 = (desde - ov.centro) / radios
	var u := Vector2.from_angle(angulo) / radios
	var a := u.dot(u)
	var b := o.dot(u)
	var disc := b * b - a * (o.dot(o) - 1.0)
	if disc <= 0.0:
		return 0.0
	return maxf(0.0, (-b + sqrt(disc)) / a)


# Hasta dónde llega cada rayo del cono (21, de un borde al otro): hasta el borde de la elipse (largo_aspirado) y, si
# antes hay una pared o un mueble, hasta él; como poco 30, para que siempre se vea algo. Una vez por fotograma
func puntas_aspirado() -> Array:
	if puntas_f == Engine.get_process_frames() and not puntas.is_empty():
		return puntas
	puntas_f = Engine.get_process_frames()
	puntas = []
	var origen := global_position + Vector2(0, 6)
	var espacio := get_world_2d().direct_space_state
	for i in 21:
		var b: float = mirada.angle() - MEDIO_ASPIRAR + i / 20.0 * MEDIO_ASPIRAR * 2.0
		var largo := largo_aspirado(b, origen)
		var rayo := PhysicsRayQueryParameters2D.create(origen, origen + Vector2.from_angle(b) * largo, 1)
		rayo.exclude = [get_rid()]
		var choque := espacio.intersect_ray(rayo)
		if not choque.is_empty():
			largo = origen.distance_to(choque.position)
		puntas.append(maxf(30.0, largo))
	return puntas


# ── El aire que aspira ──
# Todo pintado con código, en cuadraditos de 2 (los píxeles de los dibujos) y dentro del cono de verdad (puntas_aspirado:
# hasta el borde de la elipse o la pared), así que nunca se sale ni pisa una pared. Cada cosa da vueltas sin fin: tiene
# su sitio fijo en el cono (un número al azar que no cambia) y avanza hacia la boca con el tiempo; al llegar vuelve a
# salir del borde. Va de menos a más con fuerza_aspirado(): más rayas, más deprisa, más largas y más blancas.
#   - En el suelo (por debajo): polvo, piedrecitas y papelillos que se arrastran hacia él dando saltitos.
#   - En el aire (por encima, salvo si mira hacia arriba: entonces la boca queda detrás): corrientes de viento, rayas que
#     salen del borde del cono, se juntan y se curvan en remolino al entrarle en la boca; y el remolino de la boca.

# Un número al azar fijo, de 0 a 1, para la cosa "i" ("k": cuál de sus números)
static func azar(i: int, k: int) -> float:
	var x := sin(i * 12.9898 + k * 78.233) * 43758.5453
	return x - floorf(x)


# Hasta dónde llega el cono en "u" (de -1, un borde, a 1, el otro), entre los rayos de puntas_aspirado()
func largo_en(u: float) -> float:
	var p := puntas_aspirado()
	var x := (u + 1.0) * 0.5 * (p.size() - 1)
	var i := clampi(floori(x), 0, p.size() - 2)
	return lerpf(p[i], p[i + 1], x - i)


# Adónde va el aire: su boca (más o menos, la del dibujo de la boca abierta), en su sitio
func boca_aire() -> Vector2:
	return Vector2(0, -arriba * BOCA) + mirada * radio * 0.5


# Un cuadradito de 2 en la cuadrícula del suelo (como los píxeles de los dibujos), en el sitio "p" del lienzo
func pixel(lienzo: Node2D, p: Vector2, color: Color, lado := 2.0) -> void:
	var g := ((global_position + p) / 2.0).floor() * 2.0
	lienzo.draw_rect(Rect2(g - global_position, Vector2(lado, lado)), color)


# Una raya de 2 (o de "lado") de ancho de "a" a "b", con las puntas en la cuadrícula de los píxeles. Una sola línea, no
# un cuadradito por píxel: con cientos de rayas por fotograma, en la web se notaría
func raya_pixeles(lienzo: Node2D, a: Vector2, b: Vector2, color: Color, lado := 2.0) -> void:
	var medio := Vector2(lado, lado) * 0.5
	var ga := ((global_position + a) / 2.0).floor() * 2.0 + medio - global_position
	var gb := ((global_position + b) / 2.0).floor() * 2.0 + medio - global_position
	if ga.is_equal_approx(gb):
		lienzo.draw_rect(Rect2(ga - medio, medio * 2.0), color)
	else:
		lienzo.draw_line(ga, gb, color, lado)


# El punto del camino del aire: "u" de un borde del cono al otro, "s" de 1 (el borde de fuera) a 0 (la boca). Va por el
# suelo hacia él y, en el último trozo, sube a la boca girando en remolino
func camino_aire(u: float, s: float) -> Vector2:
	var a := mirada.angle() + u * MEDIO_ASPIRAR
	var largo := largo_en(u)
	var suelo := Vector2(0, 6) + Vector2.from_angle(a) * lerpf(radio * 0.6, largo, s)
	var w := clampf(1.0 - s / AIRE_SUBE, 0.0, 1.0)
	var boca := boca_aire()
	var p := suelo.lerp(boca, w * w)
	return boca + (p - boca).rotated(-AIRE_GIRO * w * w * w)


func pintar_aire(lienzo: Node2D, arriba_: bool) -> void:
	var fuerza := fuerza_aspirado()
	var vel := 0.3 + 0.7 * fuerza   # (vueltas por segundo: de fuera a la boca)
	if not arriba_:
		# los arcos de la succión: rayas de puntos de lado a lado del cono que se cierran hacia él, como ondas al revés
		for k in AIRE_ARCOS:
			var s := fposmod(k / float(AIRE_ARCOS) - tiempo * vel * 0.8, 1.0)
			var luz := minf(1.0, (1.0 - s) * 4.0) * minf(1.0, s * 6.0) * (0.35 + 0.35 * fuerza)
			var antes := Vector2.ZERO
			for j in 25:
				var u := j / 12.0 - 1.0
				var a := mirada.angle() + u * MEDIO_ASPIRAR
				var p := Vector2(0, 6) + Vector2.from_angle(a) * lerpf(radio * 0.8, largo_en(u), s)
				if j % 3 != 0:   # (a trozos: dos de cada tres)
					raya_pixeles(lienzo, antes, p, Color(1, 1, 1, luz))
				antes = p
		# el polvo del suelo: va dando saltitos de lado y desaparece al llegarle debajo
		for i in AIRE_POLVO:
			var u := azar(i, 1) * 2.0 - 1.0
			var q := fposmod(azar(i, 2) - tiempo * vel * (0.6 + 0.5 * azar(i, 3)), 1.0)
			var s := pow(q, 0.75)
			var a := mirada.angle() + u * MEDIO_ASPIRAR
			var r := lerpf(radio * 0.7, largo_en(u), s)
			var lado := Vector2.from_angle(a).orthogonal() * sin(tiempo * 23.0 + i * 1.7) * 2.0 * fuerza
			var p := Vector2(0, 6) + Vector2.from_angle(a) * r + lado
			var c: Color = POLVO[i % POLVO.size()]
			c.a = minf(1.0, (1.0 - s) * 6.0) * minf(1.0, s * 5.0) * (0.6 + 0.4 * fuerza)
			if i % 5 == 0:   # una piedrecita o un papelillo (4×4)
				pixel(lienzo, p, c, 4.0)
			else:
				pixel(lienzo, p, c)
				c.a *= 0.5   # y su rastro
				pixel(lienzo, p + Vector2.from_angle(a) * (2.0 + 4.0 * fuerza), c)
		return
	# las corrientes de viento: más cuanto más fuerte. Cada una va del borde a la boca a la misma marcha, así que
	# siempre hay tantas cerca de la boca como lejos (y allí se juntan y se ven más)
	var n := roundi(lerpf(AIRE_RAYAS * 0.4, AIRE_RAYAS, fuerza))
	var tramo := 0.1 + 0.12 * fuerza   # lo larga que es cada raya (en "s")
	for i in n:
		var u := (azar(i, 4) * 2.0 - 1.0) * 0.95
		var s := fposmod(azar(i, 5) - tiempo * vel * (0.8 + 0.4 * azar(i, 6)), 1.0)
		var luz := minf(1.0, (1.0 - s) * 4.0) * minf(1.0, s * 15.0) * (0.6 + 0.4 * fuerza)
		var gruesa := azar(i, 7) < 0.3 + 0.4 * fuerza
		var antes := camino_aire(u, s)
		for j in range(1, 5):   # de la cabeza (blanca y gruesa) a la cola (verdosa, se apaga)
			var ahora := camino_aire(u, minf(1.0, s + tramo * j / 4.0))
			var c := Color(1, 1, 1, luz * (1.0 - j / 5.0)) if j < 3 else Color(0.78, 0.88, 0.7, luz * (1.0 - j / 5.0))
			raya_pixeles(lienzo, antes, ahora, c, 4.0 if gruesa and j == 1 else 2.0)
			antes = ahora
	# el remolino de la boca: cuatro arcos que giran, aplastados, más deprisa cuanto más fuerte
	var boca := boca_aire()
	for k in 4:
		var radio_k := 8.0 + k * 7.0 + sin(tiempo * 9.0 + k) * 2.0
		var giro := tiempo * (6.0 + 10.0 * fuerza) * (1.0 - k * 0.12) + k * 1.7
		for j in 9:
			var b := giro + j * 0.22
			var c := Color(1, 1, 1, (0.4 + 0.5 * fuerza) * (1.0 - j / 9.0) * (1.0 - k * 0.15))
			pixel(lienzo, boca + Vector2(cos(b) * radio_k, sin(b) * radio_k * 0.55), c, 4.0 if j < 3 else 2.0)


# La elipse limpia de su habitación ({centro, rx, ry} en unidades; la guarda su porquería, de Peligros.franja_y_ovalo);
# fuera de su habitación no hay, vacía. Se busca una vez
func la_elipse() -> Dictionary:
	if elipse == null:
		var mapa := get_tree().get_first_node_in_group("mapa")
		if mapa == null:
			return {}
		elipse = {}
		for p in mapa.sitio.get("peligros", []):
			if p.tipo == "porqueria":
				elipse = {"centro": p.ovalo.centro * Planta.CASILLA, "rx": p.ovalo.rx * Planta.CASILLA,
					"ry": p.ovalo.ry * Planta.CASILLA}
	return elipse


func comer(johnny: Node2D, hacia: Vector2) -> void:
	johnny.recibir_dano(DANO_COMER, self)
	johnny.empujar(hacia.normalized() * 1100.0)   # y lo escupe
	johnny.pisar({"tirado": {}})
	Sonido.tocar("chof")
	Temblor.temblar(10.0)
	gritar(Idioma.t("¡ÑAM!"), Color("#ffd23f"), 26)
	Particulas.salpicar(self, get_parent(), johnny.global_position, 20.0, hacia, Color("#7a1f1a"), 8)
	andar(1.0)


func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, Idioma.t("¡TENGO HAMBRE!"))


# En la foto de la prueba (--captura): soltando el latigazo
func foto(johnny: Node2D) -> void:
	var angulo := (johnny.global_position - global_position).angle()
	mirada = Vector2.from_angle(angulo)
	cambiar("aviso_latigazo", {"angulo": angulo})
	t = AVISO_LATIGAZO - 0.05


# ── La sangre ácida ──

func recibir_golpe(cantidad: int, fuerza: Vector2, de_lleno := false, de_aliado := false) -> void:
	var antes := vida
	super(cantidad, fuerza, de_lleno, de_aliado)
	if estado == "muerto" or vida == antes:
		return
	if de_lleno and estado != "grito" and estado != "atontado":
		cambiar("tambaleo")   # una explosión le corta lo que esté haciendo
		marcha = Vector2.ZERO
	# un golpe o una bala de Johnny (no el fuego): salpica. Si le pega un superviviente, el ácido no le cae a nadie
	if fuerza != Vector2.ZERO and not de_aliado:
		salpicar_acido()


func salpicar_acido() -> void:
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny == null or acido_t > 0.0:
		return
	acido_t = ACIDO_CADA
	Sonido.tocar("chisporroteo")
	# un chorro de sangre verde que llega hasta donde está Johnny, como el de los zombis pero mucho más (ellos, 24 por golpe)
	var hasta: Vector2 = johnny.global_position
	var vuelo := vuelo_acido(global_position.distance_to(hasta))
	Particulas.salpicar_hasta(self, get_parent(), global_position + Vector2(0, 6), arriba * 0.5, hasta, VERDE, 60, vuelo)
	# y, cuando cae, el charco pequeño de ácido allí (enfadado, dos, uno a cada lado)
	var sitio := get_parent()
	var n: int = CHARCOS[fase - 1]
	await get_tree().create_timer(vuelo, false).timeout
	if not is_instance_valid(sitio) or not sitio.is_inside_tree():
		return
	var lado := Vector2.from_angle(randf() * TAU) * Vector2(26.0, 16.0)
	for i in n:
		var charco: Node2D = CHARCO.instantiate()
		charco.tipo = "sangre_gloton"
		charco.dueno = self if is_instance_valid(self) else null   # a él no le quema
		var p: Vector2 = hasta + (lado * (1.0 if i == 0 else -1.0) if n > 1 else Vector2.ZERO)
		charco.position = ((p - sitio.global_position) / 2.0).round() * 2.0   # (en píxel entero del dibujo)
		sitio.add_child(charco)


# Lo que tarda el chorro en llegar a "lejos" (más lejos, más tarda)
static func vuelo_acido(lejos: float) -> float:
	return lerpf(VUELO[0], VUELO[1], clampf(lejos / VUELO[2], 0.0, 1.0))


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	lienzo_lenguas.refrescar(estado == "latigazo")
	lienzo_sombra.refrescar(estado == "latigazo")
	match estado:
		"aviso_latigazo":
			fijar("latigazo", dir, mini(GOLPE_LATIGAZO - 1, int(t / AVISO_LATIGAZO * GOLPE_LATIGAZO)))
		"latigazo":
			var resto := sprite.sprite_frames.get_frame_count("latigazo_" + dir) - GOLPE_LATIGAZO
			fijar("latigazo", dir, GOLPE_LATIGAZO + clampi(int(t / DURA_LATIGAZO * resto), 0, maxi(0, resto - 1)))
		"aviso_aspirar":
			fijar("aspirar", dir, avance("aspirar_" + dir, t / AVISO_ASPIRAR))
		"aspirar":
			# con la boca abierta del todo, temblando del esfuerzo (más cuanto más fuerte aspira)
			fijar("aspirar", dir, sprite.sprite_frames.get_frame_count("aspirar_" + dir) - 1)
			sprite.position.x = sin(tiempo * 40.0) * 3.0 * fuerza_aspirado()
		"tambaleo":
			fijar("golpe", dir, avance("golpe_" + dir, t / TAMBALEO))
		"atontado":
			fijar("golpe", dir, avance("golpe_" + dir, t / 0.5))
			sprite.position.x = sin(tiempo * 9.0) * 2.0
		"grito":
			fijar("quieto", "s", 0)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD, 0.4, 1.5))
			else:
				poner("reposo_" + dir)


func morir() -> void:
	super()
	lienzo_lenguas.refrescar(false)   # (si muere a mitad del latigazo)
	lienzo_sombra.refrescar(false)
	# mientras no tenga su animación de muerte (solo la vista quieta), cae de lado
	if sprite.sprite_frames.get_frame_count(sprite.animation) == 1:
		create_tween().tween_property(sprite, "rotation", PI / 2.0 * signf(mirada.x + 0.01), 0.4)


# Los avisos, en el suelo (por debajo de él)
func _draw() -> void:
	if estado == "muerto":
		return
	match estado:
		"aviso_latigazo":
			# las lenguas avisan como las cargas de los jefes: flechas que se encienden hacia fuera y, al final, una X
			# (o una estrella, si se paran en una pared o un mueble)
			for i in apuntadas:
				lenguas[i].avisar(self, Vector2(0, 6), minf(1.0, t / AVISO_LATIGAZO), tiempo, i)
		"aviso_aspirar", "aspirar":
			# el aviso de la zona que aspira, rojo como el de los demás ataques de los jefes (aviso.gd): se llena hacia
			# fuera y destella. Al aspirar se oculta (lo que se ve entonces es el aire, pintar_aire), pero sigue pedido
			# para que el bot (docs/BOT.md) sepa por dónde aspira
			var cono := Aviso.abanico(self, Vector2(0, 6), mirada.angle(), MEDIO_ASPIRAR, 0.0,
				minf(1.0, t / AVISO_ASPIRAR), tiempo)
			cono.rayos(puntas_aspirado())
			cono.oculto = estado == "aspirar"
			# aspirando: el polvo del suelo, arrastrado hacia él; y, mirando hacia arriba (con la boca al otro lado),
			# también las corrientes de aire, que se le meten por detrás
			if estado == "aspirar":
				pintar_aire(self, false)
				if direccion().begins_with("n"):
					pintar_aire(self, true)
	draw_set_transform(Vector2.ZERO)


func pintar_encima(lienzo: Node2D) -> void:
	if estado == "aspirar" and not direccion().begins_with("n"):
		pintar_aire(lienzo, true)


# De dónde salen ahora las lenguas: su boca en este fotograma del golpe (BOCAS)
func boca() -> Vector2:
	var bocas: Array = BOCAS[direccion()]
	return bocas[clampi(sprite.frame - GOLPE_LATIGAZO, 0, bocas.size() - 1)]


# Las lenguas del latigazo, enteras por encima de él (en su lienzo pixelado, hijo del nodo "Vapor"): salen disparadas
# de la boca, caen sobre el aviso culebreando y se recogen (lengua.gd)
func pintar_lenguas(lienzo: Node2D) -> void:
	for i in apuntadas:
		lenguas[i].estela(lienzo, boca(), Vector2(0, 6), t, DURA_LATIGAZO)
	for i in apuntadas:
		lenguas[i].pintar(lienzo, lenguas[i].lanzada(boca(), Vector2(0, 6), t, DURA_LATIGAZO), 0, Tentaculo.PUNTOS)


# Su sombra en el suelo, por debajo de él (en su lienzo pixelado, detrás de su dibujo; lengua.gd)
func pintar_sombra_lenguas(lienzo: Node2D) -> void:
	for i in apuntadas:
		lenguas[i].sombra(lienzo, lenguas[i].lanzada(boca(), Vector2(0, 6), t, DURA_LATIGAZO), Vector2(0, 6))
