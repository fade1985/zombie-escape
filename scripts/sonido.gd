# Los efectos de sonido (como src/sfx.js del JS): no hay archivos de audio, cada efecto son unas notas
# sintetizadas (onda cuadrada, triangular, senoidal o de sierra que baja o sube de tono y se apaga).
# La primera vez que suena un efecto se "graba" en memoria y luego se reutiliza.
#
# Es un nodo que siempre está (autoload en project.godot), así que desde cualquier script:
#     Sonido.tocar("compra")
#
# Los buses de audio están en default_bus_layout.tres: Master (con un compresor para que muchos efectos a
# la vez no saturen), Efectos y Musica.
# Con --captura (la prueba sin jugar) arranca sin sonido, como el modo ?pruebas del JS.
#
# La música de fondo: en el JS (src/musica.js) se inventaba sobre la marcha. Aquí son tramos grabados de
# ella (tools/grabar_musica.mjs → assets/musica/, ya con su volumen) que se encadenan al azar con fundidos:
#     Sonido.musica("explorar")   # "menu", "explorar", "jefe" o "" (se apaga despacio)
#     Sonido.jingle(true)         # la melodía corta de victoria (false: la de derrota)
extends Node

const MEZCLA := 22050        # muestras por segundo: de sobra para estos pitidos y gasta la mitad
const VOCES := 16            # cuántos efectos pueden sonar a la vez

# Cada efecto: sus notas [frecuencia, duración, onda, volumen, deslizar (Hz al final), retraso] y,
# si no debe repetirse muy seguido, "hueco" (milisegundos mínimos entre dos). Los números, los del JS.
const EFECTOS := {
	"disparo": {"hueco": 60, "notas": [[620, 0.05, "cuadrada", 0.012, -250]]},        # shoot
	"golpe": {"hueco": 40, "notas": [[240, 0.06, "cuadrada", 0.025, -120]]},          # hit (zombi herido)
	"muerte": {"hueco": 50, "notas": [[300, 0.12, "triangulo", 0.07, 400]]},          # kill
	"moneda": {"hueco": 45, "notas": [[988, 0.05, "cuadrada", 0.025], [1319, 0.08, "cuadrada", 0.025, 0, 0.05]]},
	"gema": {"notas": [[1200, 0.08, "seno", 0.06], [1800, 0.15, "seno", 0.05, 0, 0.07]]},
	"dano": {"notas": [[180, 0.25, "sierra", 0.06, -90]]},                             # hurt
	"esquiva": {"notas": [[260, 0.12, "seno", 0.05, 420]]},                            # dash
	"puerta": {"notas": [[400, 0.1, "triangulo", 0.06, 200], [600, 0.15, "triangulo", 0.05, 300, 0.08]]},
	"limpio": {"notas": [[523, 0.14, "cuadrada", 0.035, 0, 0.0], [659, 0.14, "cuadrada", 0.035, 0, 0.09],
		[784, 0.14, "cuadrada", 0.035, 0, 0.18], [1047, 0.14, "cuadrada", 0.035, 0, 0.27]]},   # clear
	"compra": {"notas": [[880, 0.07, "cuadrada", 0.03], [1175, 0.1, "cuadrada", 0.03, 0, 0.07]]},   # buy
	"no": {"notas": [[150, 0.15, "cuadrada", 0.04, -40]]},                             # nope
	"barrido": {"hueco": 40, "notas": [[520, 0.1, "triangulo", 0.035, -380]]},        # swing (cuerpo a cuerpo)
	"porrazo": {"hueco": 40, "notas": [[150, 0.09, "cuadrada", 0.05, -70], [90, 0.12, "triangulo", 0.06, -30]]},
	"pistola": {"hueco": 50, "notas": [[950, 0.05, "cuadrada", 0.03, -750], [170, 0.08, "triangulo", 0.05, -90]]},
	"escopeta": {"notas": [[120, 0.2, "sierra", 0.07, -60], [700, 0.1, "cuadrada", 0.035, -600]]},
	"pitido": {"notas": [[1200, 0.06, "cuadrada", 0.03]]},                             # beep (mecha)
	"explosion": {"notas": [[90, 0.45, "sierra", 0.09, -60], [50, 0.5, "triangulo", 0.1, -20, 0.02],
		[400, 0.15, "cuadrada", 0.04, -350]]},
	"latigazo": {"notas": [[300, 0.12, "sierra", 0.05, 500]]},                         # whip
	"escupitajo": {"notas": [[260, 0.12, "seno", 0.06, -180]]},                        # spit
	"chof": {"hueco": 60, "notas": [[140, 0.12, "triangulo", 0.06, -80], [500, 0.06, "seno", 0.03, -300]]},
	"lanzar": {"notas": [[300, 0.16, "seno", 0.05, 260]]},                             # toss
	"fuego": {"notas": [[120, 0.5, "sierra", 0.05, -60], [700, 0.3, "sierra", 0.015, -500, 0.05]]},
	"chisporroteo": {"hueco": 450, "notas": [[1800, 0.12, "sierra", 0.012, -900]]},    # sizzle (quemarse)
	"curar": {"notas": [[660, 0.1, "seno", 0.05, 200], [990, 0.16, "seno", 0.045, 300, 0.08]]},
	"disparo_aliado": {"hueco": 70, "notas": [[760, 0.05, "cuadrada", 0.018, -550]]},
	# el superviviente encerrado: tres golpes en la puerta y un grito (de cerca y, desde el pasillo, flojito)
	"socorro": {"notas": [[170, 0.07, "cuadrada", 0.06, -60, 0.0], [170, 0.07, "cuadrada", 0.06, -60, 0.15],
		[170, 0.07, "cuadrada", 0.06, -60, 0.3], [760, 0.4, "seno", 0.025, -260, 0.45]]},
	"socorro_lejos": {"notas": [[150, 0.06, "cuadrada", 0.02, -50, 0.0], [150, 0.06, "cuadrada", 0.02, -50, 0.15],
		[150, 0.06, "cuadrada", 0.02, -50, 0.3], [700, 0.35, "seno", 0.01, -240, 0.45]]},
	"portazo": {"notas": [[110, 0.16, "cuadrada", 0.07, -50], [70, 0.22, "triangulo", 0.08, -20, 0.03]]},
	"silbato": {"notas": [[2700, 0.1, "seno", 0.045, 150], [2900, 0.4, "seno", 0.05, -200, 0.13]]},   # el guardia
	"jefe": {"notas": [[110, 0.6, "sierra", 0.06, -40], [82, 0.8, "sierra", 0.05, -20, 0.2]]},
	"rugido": {"notas": [[160, 0.5, "sierra", 0.07, -90], [120, 0.6, "cuadrada", 0.04, -60, 0.05]]},
	"escobazo": {"hueco": 90, "notas": [[900, 0.12, "sierra", 0.018, -700]]},          # broom (la portera)
	"cristal": {"hueco": 60, "notas": [[2200, 0.08, "cuadrada", 0.025, -800], [1500, 0.12, "triangulo", 0.03, 600, 0.03]]},
	"latido": {"notas": [[70, 0.12, "seno", 0.18, -20], [60, 0.14, "seno", 0.14, -15, 0.16]]},   # heartbeat
	"disparo_zombi": {"hueco": 80, "notas": [[330, 0.08, "seno", 0.025, -150]]},       # enemyShot
	# armas de fuego: sin balas, sacar el cargador, meterlo, meter un cartucho y cambiar de arma
	"click": {"hueco": 200, "notas": [[1600, 0.03, "cuadrada", 0.025]]},
	"voz": {"hueco": 70, "notas": [[480, 0.035, "triangulo", 0.012, -60]]},              # la reportera de las noticias
	"recargar": {"notas": [[520, 0.05, "cuadrada", 0.025, -200], [260, 0.06, "triangulo", 0.04, -80, 0.06]]},
	"recargado": {"notas": [[300, 0.05, "cuadrada", 0.035, 200], [1400, 0.04, "cuadrada", 0.025, 0, 0.07]]},
	"cartucho": {"notas": [[700, 0.04, "cuadrada", 0.025, -300], [1200, 0.03, "cuadrada", 0.02, 0, 0.05]]},
	"cambiar": {"notas": [[420, 0.07, "triangulo", 0.035, 260]]},                      # swap
}

var grabados := {}       # nombre → AudioStreamWAV ya sintetizado
var ultimo := {}         # nombre → cuándo sonó (ms), para el "hueco"
var voces: Array[AudioStreamPlayer] = []
var siguiente := 0

const TRAMOS := {"menu": 2, "explorar": 5, "jefe": 3}   # cuántos tramos hay grabados de cada momento
const FUNDIDO := 3.0     # segundos que tarda en pasar de un tramo a otro
var momento := ""        # lo que suena ahora
var sonando: AudioStreamPlayer = null   # de los dos reproductores de música, el que está sonando
var otro: AudioStreamPlayer = null
var ultimo_tramo := ""   # para no repetir el mismo tramo dos veces seguidas
var queda := 0.0         # segundos que le quedan al tramo que suena


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS    # los clics de los menús suenan también en pausa
	for i in VOCES:
		var v := AudioStreamPlayer.new()
		v.bus = &"Efectos"
		add_child(v)
		voces.append(v)
	sonando = reproductor_musica()
	otro = reproductor_musica()
	if "--captura" in OS.get_cmdline_user_args():
		silenciar(true)
	musica_si(Guardado.cargar().ajustes.musica)


# Suena un efecto (si no sonó hace nada y lleva "hueco")
func tocar(nombre: String) -> void:
	var e: Dictionary = EFECTOS.get(nombre, {})
	if e.is_empty():
		push_error("Sonido: no existe el efecto " + nombre)
		return
	var ahora := Time.get_ticks_msec()
	if e.has("hueco") and ultimo.has(nombre) and ahora - int(ultimo[nombre]) < int(e.hueco):
		return
	ultimo[nombre] = ahora
	if not grabados.has(nombre):
		grabados[nombre] = sintetizar(e.notas)
	var v := voces[siguiente]
	siguiente = (siguiente + 1) % VOCES
	v.stream = grabados[nombre]
	v.play()


# ── Música ──

func reproductor_musica() -> AudioStreamPlayer:
	var r := AudioStreamPlayer.new()
	r.bus = &"Musica"
	add_child(r)
	return r


# Cambia de momento: el tramo nuevo entra mientras el viejo se apaga
func musica(nuevo: String) -> void:
	if nuevo == momento:
		return
	momento = nuevo
	if nuevo == "":
		fundir(sonando, 0.0, 1.5)
		return
	otro_tramo()


func _process(delta: float) -> void:
	if momento == "":
		return
	queda -= delta
	if queda <= FUNDIDO:
		otro_tramo()   # se acaba: el siguiente, al azar


# Elige un tramo del momento (no el mismo que acaba de sonar), empezando por cualquier sitio de su primera
# mitad para que tampoco empiece siempre igual, y lo funde con el que sonaba
func otro_tramo() -> void:
	var nombre := ultimo_tramo
	while nombre == ultimo_tramo:
		nombre = "%s-%d" % [momento, randi_range(1, TRAMOS[momento])]
		if TRAMOS[momento] == 1:
			break
	ultimo_tramo = nombre
	var tramo: AudioStream = load("res://assets/musica/%s.ogg" % nombre)
	var desde := randf_range(0.0, tramo.get_length() * 0.5)
	queda = tramo.get_length() - desde
	fundir(sonando, 0.0, FUNDIDO)
	var r := otro
	otro = sonando
	sonando = r
	r.stream = tramo
	r.volume_db = -60.0
	r.play(desde)
	fundir(r, 1.0, FUNDIDO)


# Sube o baja el volumen de un reproductor poco a poco (a 0: además se para)
func fundir(r: AudioStreamPlayer, hasta: float, segundos: float) -> void:
	if not r.playing:
		return
	var t := r.create_tween()
	t.tween_method(func(v: float): r.volume_db = linear_to_db(v), db_to_linear(r.volume_db), hasta, segundos)
	if hasta == 0.0:
		t.tween_callback(r.stop)


# La melodía corta del final (como music.jingle del JS): sube si se gana, baja si se pierde. La música se apaga
func jingle(gana: bool) -> void:
	musica("")
	var notas := [0, 4, 7, 12, 7, 12, 16] if gana else [7, 6, 5, 4, 3, 2, 0]
	var raiz := 392.0 if gana else 196.0
	var dur := 0.12 if gana else 0.2
	var lista := []
	for i in notas.size():
		var largo := dur * (4.0 if i == notas.size() - 1 else 1.4)
		# el volumen del JS (0,05) por el de su música (0,55): los tramos grabados ya lo llevan dentro
		lista.append([raiz * pow(2.0, notas[i] / 12.0), largo, "cuadrada", 0.05 * 0.55, 0, 0.05 + i * dur])
	var r := otro if not otro.playing else reproductor_musica()
	r.stream = sintetizar(lista)
	r.volume_db = 0.0
	r.play()


# Quita o pone todo el sonido (efectos y música)
func silenciar(si: bool) -> void:
	AudioServer.set_bus_mute(0, si)


func silenciado() -> bool:
	return AudioServer.is_bus_mute(0)


# La música encendida o apagada (el ajuste del menú de pausa)
func musica_si(si: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Musica"), not si)


# Mezcla las notas de un efecto en un sonido de 16 bits, como hacía el navegador con sus osciladores:
# el tono va de la frecuencia a frecuencia + deslizar, y el volumen cae hasta casi nada, los dos en curva
func sintetizar(notas: Array) -> AudioStreamWAV:
	var largo := 0.0
	for n in notas:
		largo = maxf(largo, nota(n, 5, 0.0) + n[1] + 0.02)
	var muestras := PackedFloat32Array()
	muestras.resize(int(largo * MEZCLA) + 1)
	for n in notas:
		var f0: float = n[0]
		var dur: float = n[1]
		var onda: String = n[2]
		var vol: float = n[3]
		var f1 := maxf(30.0, f0 + nota(n, 4, 0.0))
		var empieza := int(nota(n, 5, 0.0) * MEZCLA)
		var cuantas := int(dur * MEZCLA)
		var fase := 0.0
		for i in cuantas:
			var t := float(i) / cuantas
			fase = fmod(fase + f0 * pow(f1 / f0, t) / MEZCLA, 1.0)
			muestras[empieza + i] += forma(onda, fase) * vol * pow(0.0001 / vol, t)
	var datos := PackedByteArray()
	datos.resize(muestras.size() * 2)
	for i in muestras.size():
		datos.encode_s16(i * 2, int(clampf(muestras[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MEZCLA
	wav.data = datos
	return wav


func nota(n: Array, i: int, si_no: float) -> float:
	return float(n[i]) if n.size() > i else si_no


# Una vuelta de cada onda (fase de 0 a 1), entre -1 y 1
func forma(onda: String, fase: float) -> float:
	match onda:
		"cuadrada": return 1.0 if fase < 0.5 else -1.0
		"triangulo": return 4.0 * fase - 1.0 if fase < 0.5 else 3.0 - 4.0 * fase
		"sierra": return 2.0 * fase - 1.0
	return sin(fase * TAU)
