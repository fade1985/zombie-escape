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
#   - Sangre ácida: cada golpe o disparo que le das salpica ácido y Johnny pierde un 1 % de su vida (uno cada
#     segundo como mucho, para que las armas rápidas no sumen demasiado). Si le pegan los supervivientes que
#     acompañan a Johnny, le hacen daño igual pero el ácido no le cae a nadie.
#   - Una explosión (granada) le corta lo que esté haciendo (se tambalea): la manera de parar el aspirado.
# Enfadado (a media vida, «¡TENGO HAMBRE!»): el doble de lenguas, aspira con el doble de fuerza (al máximo arrastra
# desde 7 casillas, y de lejos Johnny va a 40) y el ácido quita un 2 %.
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
const ACIDO := [0.01, 0.02]            # lo que quita el salpicón de sangre ácida (parte de la vida máxima de Johnny)
const ACIDO_CADA := 1.0                # (hasta el 27 oct, 0,5: con cualquier arma, unos 50-80 de vida por combate)
const TAMBALEO := 0.6                  # lo que le corta una explosión
const PIE := 30.0                      # a qué altura dibuja los pies respecto a su centro
const BOCA := 0.5                      # a qué altura tiene la boca (parte de "arriba"): adonde va el aire que aspira
const VERDE := Color("#c7e04a")
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
const BOCAS := {
	"s": Vector2(0, -28), "se": Vector2(36, -16), "e": Vector2(58, -32), "ne": Vector2(54, -20),
	"n": Vector2(0, -86), "no": Vector2(-60, -38), "o": Vector2(-62, -36), "so": Vector2(-46, -14),
}

var espera_latigazo := 1.5
var espera_aspirar := 6.0
var acido_t := 0.0                     # para no salpicar ácido con cada perdigón
var elipse = null                      # la elipse limpia de su habitación, en unidades (la_elipse(); null, sin buscar)
var lenguas: Array[Lengua] = []        # las del latigazo (enfadado, todas; si no, las primeras)
var apuntadas := 0                     # cuántas lleva este latigazo


func _ready() -> void:
	super()
	for i in LENGUAS[1]:
		var lengua := Lengua.new(PALETA)
		lengua.grueso = 5.0
		lengua.fino = 2.0
		lengua.borde = 2.0
		lengua.culebrea = 7.0
		lengua.largo = LARGO_LENGUA
		lengua.ancho = ANCHO_LENGUA
		lengua.desfase = i * 0.37
		lenguas.append(lengua)


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
			contacto = 0   # el bocado ya lo da comer()
			aspirar(delta, johnny, hacia, d)
			if t >= DURA_ASPIRAR:
				andar(0.6)
		"tambaleo":
			frenar(delta, 5.0)
			if t >= TAMBALEO:
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
		gritar("¡HAMBRE!", VERDE)
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
		if lenguas[i].golpea(self, johnny):
			johnny.recibir_dano(DANO_LATIGAZO, self)
			johnny.empujar(Vector2.from_angle(lenguas[i].angulo) * 500.0)
			return


# ── Aspirar ──

# Tira de Johnny hacia la boca mientras esté en el cono, le vea y no esté esquivando. Si llega, se lo come
func aspirar(delta: float, johnny: Node2D, hacia: Vector2, d: float) -> void:
	var fuerza := fuerza_aspirado()
	# el aire que entra: motas que vuelan hacia la boca (más, más deprisa y más blancas cuanto más fuerte aspira)
	if randf() < delta * 60.0 * fuerza:
		var a := mirada.angle() + randf_range(-MEDIO_ASPIRAR, MEDIO_ASPIRAR)
		var largo := largo_aspirado(a, global_position)
		var desde := global_position + Vector2.from_angle(a) * randf_range(minf(100.0, largo), largo)
		var boca := global_position + Vector2(0, -arriba * BOCA)
		Particulas.soltar(self, desde, (boca - desde).normalized() * (200.0 + 350.0 * fuerza),
			Color(1, 1, 1, 0.25 + 0.35 * fuerza), 2, 0.4)
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
	gritar("¡ÑAM!", Color("#ffd23f"), 26)
	Particulas.salpicar(self, get_parent(), johnny.global_position, 20.0, hacia, Color("#7a1f1a"), 8)
	andar(1.0)


func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, "¡TENGO HAMBRE!")


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
	if de_lleno and estado != "grito":
		cambiar("tambaleo")   # una explosión le corta lo que esté haciendo
		marcha = Vector2.ZERO
	# un golpe o una bala de Johnny (no el fuego): salpica. Si le pega un superviviente, el ácido no le cae a nadie
	if fuerza != Vector2.ZERO and not de_aliado:
		salpicar_acido()


func salpicar_acido() -> void:
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny == null or not johnny.vivo or acido_t > 0.0:
		return
	acido_t = ACIDO_CADA
	var dano := maxi(1, roundi(johnny.stats.vida_max * ACIDO[fase - 1]))
	johnny.quitar_vida(dano)
	Sonido.tocar("chisporroteo")
	Zombi.texto_flotante(get_parent(), johnny.global_position + Vector2(-24, -72), "-%d ácido" % dano, VERDE, 16)
	# gotas verdes que saltan de él hacia Johnny, y el chisporroteo al caerle encima
	var hacia: Vector2 = (johnny.global_position - global_position).normalized()
	for i in 6:
		Particulas.soltar(self, global_position + Vector2(randf_range(-20, 20), -arriba * 0.6),
			hacia.rotated(randf_range(-0.5, 0.5)) * randf_range(150.0, 320.0), VERDE, 3, 0.4)
	for i in 4:
		Particulas.soltar(self, johnny.global_position + Vector2(randf_range(-10, 10), -30),
			Vector2(randf_range(-40, 40), -40), VERDE, 2, 0.35)


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
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
			# el cono por donde aspira (verde, hasta las paredes), que se llena en el aviso; aspirando, lleno y con
			# ondas que se le meten en la boca, más deprisa cuanto más fuerte aspira (aviso.gd)
			var k := minf(1.0, t / AVISO_ASPIRAR) if estado == "aviso_aspirar" else 1.0
			var puntas := []   # (cada rayo hasta donde llega, como poco 30 para que siempre se vea algo)
			for i in 21:
				var b: float = mirada.angle() - MEDIO_ASPIRAR + i / 20.0 * MEDIO_ASPIRAR * 2.0
				puntas.append(maxf(30.0, largo_aspirado(b, global_position + Vector2(0, 6))))
			var cono := Aviso.abanico(self, Vector2(0, 6), mirada.angle(), MEDIO_ASPIRAR, 0.0, k, tiempo)
			cono.rayos(puntas)
			cono.tinte = VERDE
			if estado == "aspirar":
				cono.ondas = 60.0 + 160.0 * fuerza_aspirado()
				cono.destella = false
	draw_set_transform(Vector2.ZERO)


# Las lenguas del latigazo, enteras por encima de él (en el nodo "Vapor"): salen disparadas de la boca, caen sobre el
# aviso culebreando y se recogen (lengua.gd)
func pintar_encima(lienzo: Node2D) -> void:
	if estado != "latigazo":
		return
	for i in apuntadas:
		var puntos := lenguas[i].lanzada(BOCAS[direccion()], Vector2(0, 6), t, DURA_LATIGAZO)
		lenguas[i].pintar(lienzo, puntos, 0, Tentaculo.PUNTOS)
