# La voz de la reportera de las noticias (M93): mientras salen los subtítulos (tele.gd) «habla» con pitidos de 8 bits,
# sin palabras, como el balbuceo de los videojuegos antiguos. Cada sílaba es un pitido corto de onda cuadrada (de las de
# antes: el volumen en 16 escalones) con su nota y su largo un poco al azar; la nota va subiendo y bajando poco a poco, como
# una voz, baja al acabar una frase y sube en las preguntas. En los espacios y los signos se calla: así se oye a trozos,
# palabra a palabra.
# Va por el bus de Efectos (el volumen de efectos de Opciones) y por su propio altavoz, para poder callarla de golpe: al
# saltar la frase, en la pausa del reproductor o al cerrar la noticia (al cerrarse, la tele se borra y la voz con ella).
# Se usa desde tele.gd:  voz.letra(c, la_siguiente)  por cada letra que sale  ·  voz.avanzar(delta)  ·  voz.callar()
class_name VozReportera
extends AudioStreamPlayer

const MEZCLA := 22050
const BASE := 370.0   # la nota de en medio: voz de mujer, aguda pero sin chillar
# las notas que puede coger cada sílaba, en semitonos desde BASE: de una escala de cinco notas, así no desafinan nunca
const NOTAS := [-5, -3, 0, 2, 4, 7, 9]
const LARGOS := [0.05, 0.065, 0.08]   # lo que dura cada sílaba (segundos)
const HUECO := Vector2(0.085, 0.13)   # de una sílaba a la siguiente, como poco (al azar entre los dos)
const FUERZA := 0.045   # lo fuerte que suena: por debajo de la música (la onda cuadrada se oye mucho, aunque vaya floja)
# los que no se dicen: espacios y signos (también los chinos), y ahí se calla
const CALLA := " \n,.;:!?¡¿«»\"'-—…()，。！？、：；“”"
static var grabadas := {}   # "nota/largo/pulso" → su sonido ya hecho (se hacen la primera vez que hacen falta)

var reloj := 0.0     # lo que lleva hablando (solo corre mientras habla)
var proxima := 0.0   # cuándo puede empezar la sílaba siguiente
var nota := 2        # la nota de la última sílaba (el número de NOTAS)


func _init() -> void:
	bus = &"Efectos"


# Corre el reloj de la voz (tele.gd, mientras la reportera habla)
func avanzar(delta: float) -> void:
	reloj += delta


# Sale una letra del subtítulo: si toca, empieza una sílaba. Devuelve la que suena ("" si no suena ninguna), para la prueba
func letra(c: String, siguiente := "") -> String:
	if c == "" or c in CALLA or reloj < proxima:
		return ""
	# la nota: casi siempre una vecina de la anterior (sube o baja un poco, como una voz); al final de una frase, de las
	# graves, y en las preguntas, de las agudas
	if siguiente in [".", "!", "…", "。", "！"]:
		nota = randi_range(0, 1)
	elif siguiente in ["?", "？"]:
		nota = randi_range(NOTAS.size() - 2, NOTAS.size() - 1)
	else:
		nota = clampi(nota + [-2, -1, -1, 0, 1, 1, 2].pick_random(), 0, NOTAS.size() - 1)
	var largo := randi_range(0, LARGOS.size() - 1)
	var pulso := randi_range(0, 1)   # (la cuadrada estrecha suena más nasal: de una sílaba a otra cambia la «vocal»)
	var clave := "%d/%d/%d" % [nota, largo, pulso]
	proxima = reloj + randf_range(HUECO.x, HUECO.y)
	if is_inside_tree():
		stream = silaba(clave)
		play()
	return clave


# Se calla de golpe (al saltar la frase, en la pausa, al poner otra noticia...)
func callar() -> void:
	if playing:
		stop()


# El sonido de una sílaba (y se guarda para la próxima vez)
static func silaba(clave: String) -> AudioStreamWAV:
	if not grabadas.has(clave):
		var muestras := muestras_de(clave)
		var datos := PackedByteArray()
		datos.resize(muestras.size() * 2)
		for i in muestras.size():
			datos.encode_s16(i * 2, int(clampf(muestras[i], -1.0, 1.0) * 32767.0))
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = MEZCLA
		wav.data = datos
		grabadas[clave] = wav
	return grabadas[clave]


# Las muestras de una sílaba: una onda cuadrada que baja un poquito de tono al final (como al soltar la sílaba), con una
# entrada muy rápida y una salida suave para que no chasquee, y el volumen en 16 escalones, como las consolas de antes
static func muestras_de(clave: String) -> PackedFloat32Array:
	var partes := clave.split("/")
	var hz := BASE * pow(2.0, NOTAS[int(partes[0])] / 12.0)
	var dur: float = LARGOS[int(partes[1])]
	var ancho := 0.5 if partes[2] == "0" else 0.25
	var cuantas := int(dur * MEZCLA)
	var muestras := PackedFloat32Array()
	muestras.resize(cuantas)
	var fase := 0.0
	for i in cuantas:
		var t := float(i) / cuantas
		fase = fmod(fase + hz * (1.0 - 0.06 * t * t) / MEZCLA, 1.0)
		var envolvente := minf(1.0, i / (0.004 * MEZCLA)) * (1.0 if t < 0.55 else 1.0 - (t - 0.55) / 0.45)
		envolvente = roundf(envolvente * 15.0) / 15.0
		# (menos su media: con la estrecha, la onda no queda centrada y daría un golpe sordo al empezar y al acabar)
		muestras[i] = ((1.0 if fase < ancho else -1.0) - (2.0 * ancho - 1.0)) * FUERZA * envolvente
	return muestras
