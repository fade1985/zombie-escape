# Los avisos de los ataques de los jefes, en el suelo y de pixel art (cuadraditos de 4, en la cuadrícula del suelo,
# como las manchas): se van llenando hacia donde va el golpe y, cuando están llenos, pega. Al final parpadean y
# destellan en blanco (el «¡ahora!»). De momento, la franja de las cargas y embestidas (minijefe.franja).
class_name Aviso
extends RefCounted

const CELDA := 4.0
const ROJO := Color(1, 0.24, 0.35)
const OSCURO := Color("#3a0a14", 0.8)   # el borde de fuera, para que se vea en cualquier suelo
const BRILLO := Color("#ffb3bd")         # las flechas y el frente del llenado

# Las casillas de cada franja ya calculadas, por largo, ancho y dirección (64): así no se recalculan
static var franjas := {}


# La franja de una carga: desde "desde" (en el lienzo), hacia "angulo", de "largo" y "medio" de ancho a cada lado.
# Se llena en "k" (0 a 1); por dentro corren unas flechas hacia donde va, cada vez más deprisa. "tiempo", para que se
# muevan
static func franja(lienzo: CanvasItem, desde: Vector2, angulo: float, largo: float, medio: float, k: float,
		tiempo: float) -> void:
	var dir := posmod(roundi(angulo / TAU * 64.0), 64)
	var clave := "%d_%d_%d" % [roundi(largo), roundi(medio), dir]
	if not franjas.has(clave):
		franjas[clave] = casillas(largo, medio, dir * TAU / 64.0)
	# las casillas van en la cuadrícula del suelo, no en la del jefe
	var global := lienzo.get_global_transform().origin + desde
	var origen := (global / CELDA).round() * CELDA - lienzo.get_global_transform().origin
	var lleno := largo * k
	var destello := k > 0.92
	var parpadea := k > 0.7 and fmod(tiempo * (10.0 + 14.0 * k), 1.0) < 0.5
	var corre := tiempo * (60.0 + 260.0 * k)   # las flechas, cada vez más deprisa
	for c in franjas[clave]:
		var u: float = c[1]   # a lo largo
		var v: float = c[2]   # a lo ancho (0 en el medio, 1 en el borde)
		# las flechas (>): en forma de punta, avanzando hacia donde va
		var flecha: bool = c[3] == 0 and v < 0.62 and fposmod(u + v * medio * 0.9 - corre, 40.0) < CELDA * 2.0
		var color: Color
		if c[3] == 2:
			color = OSCURO
		elif c[3] == 1:
			color = Color(ROJO, 0.95 if u <= lleno else 0.45)
			if parpadea:
				color = BRILLO
		elif u <= lleno:
			color = Color(ROJO, 0.32 + 0.18 * k)
			if lleno - u < CELDA * 3.0:
				color = Color(BRILLO, 0.75)   # el frente del llenado
		else:
			# lo que falta: una trama a cuadros, que se marca más según se va llenando
			if not flecha and (int(c[0].x / CELDA) + int(c[0].y / CELDA)) % 2 == 0:
				continue
			color = Color(ROJO, 0.12 + 0.12 * k)
		if flecha:
			color = Color(BRILLO, 0.85 if u <= lleno else 0.5)
		if destello:
			color = Color(1, 1, 1, maxf(color.a, 0.7))
		lienzo.draw_rect(Rect2(origen + c[0], Vector2(CELDA, CELDA)), color)


# Las casillas de la cuadrícula que caen en la franja: [sitio, a lo largo, a lo ancho (0 a 1), tipo (0: dentro, 1:
# borde, 2: borde de fuera)]
static func casillas(largo: float, medio: float, angulo: float) -> Array:
	var hacia := Vector2.from_angle(angulo)
	var lado := hacia.orthogonal()
	var fuera := medio + CELDA
	var esquinas := [-lado * fuera - hacia * CELDA, lado * fuera - hacia * CELDA,
		hacia * (largo + CELDA) - lado * fuera, hacia * (largo + CELDA) + lado * fuera]
	var caja := Rect2(esquinas[0], Vector2.ZERO)
	for e in esquinas:
		caja = caja.expand(e)
	var lista := []
	for y in range(floori(caja.position.y / CELDA), ceili(caja.end.y / CELDA) + 1):
		for x in range(floori(caja.position.x / CELDA), ceili(caja.end.x / CELDA) + 1):
			var p := Vector2(x, y) * CELDA
			var centro := p + Vector2(CELDA, CELDA) / 2.0
			var u := centro.dot(hacia)
			var v := absf(centro.dot(lado))
			if u < -CELDA or u > largo + CELDA or v > fuera:
				continue
			var tipo := 0
			if u < 0.0 or u > largo or v > medio:
				tipo = 2
			elif u < CELDA or u > largo - CELDA or v > medio - CELDA:
				tipo = 1
			lista.append([p, u, v / medio, tipo])
	return lista
