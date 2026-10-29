# El tentáculo largo que pega, pintado con código: el del zombi de tentáculos y los tres del gerente mutado. Mientras
# avisa le sale de la espalda, se levanta por encima de la cabeza, se enrosca y tiembla, apuntando hacia donde va a
# pegar; en el suelo, el mismo aviso que en las cargas de los jefes (Aviso.franja). Con el golpe se estira como un
# látigo hasta donde llega (si da con una pared o un mueble, hasta ella), cae sobre el aviso y se recoge.
# Se pinta como los de su dibujo: el contorno y encima capas, cada una más clara, más estrecha y arrimada al lado de
# la luz, y las ventosas por el lado de la sombra. Cada uno trae sus colores y sus medidas.
# Quien lo usa elige de dónde sale (la raíz, que se mueve con su dibujo) y qué parte va por detrás del dibujo y qué
# parte por delante (pintar, de un trozo a otro).
class_name Tentaculo
extends RefCounted

const PUNTOS := 20                 # en cuántos trozos se pinta, de la base a la punta
const LUZ := Vector2(-0.4, -0.9)   # de dónde le da la luz (arriba a la izquierda), como a los dibujos

# Sus colores: el contorno; las capas, de la más oscura (todo el ancho) a la más clara, con lo que ocupa cada una
# (en partes del ancho, contando desde el borde de la luz); y las ventosas: aros (con "aro", "sombra", "hueco" y
# "brillo") o puntitos ("punto")
var contorno: Color
var capas := []
var ventosas := {}
# Sus medidas
var grueso := 7.5          # medio grueso en la base...
var fino := 2.0            # ...y en la punta
var enroscado := 110.0     # lo largo que es levantado durante el aviso
var alto := 1.0            # lo alto que pasa al estirarse (y lo que culebrea): 1, el del zombi
var largo := 220.0         # hasta dónde llega el latigazo (si no da antes con una pared)
var ancho := 16.0          # medio ancho de la línea del golpe (y de su aviso)
var desfase := 0.0         # para que, si son varios, no tiemblen todos a la vez
# Este latigazo
var angulo := 0.0          # hacia dónde va (se fija al empezar el aviso, apuntar)
var llega := 220.0         # hasta dónde llega
var choca := false         # si se para en una pared o un mueble (el aviso acaba en estrella)
var gordo := 1.0           # lo que se le ve de grueso: lo dejan levantado() y latigo() para pintar()


# "paleta": {"contorno", "capas", "ventosas"}, con los colores de su hoja. "oscurecer": si su dibujo pasa por el
# shader de los zombis (destello.gdshader), que multiplica el dibujo por sí mismo y lo deja más oscuro, el canal por
# sí mismo: al tentáculo se le hace lo mismo para que quede igual que los de su espalda
func _init(paleta: Dictionary, oscurecer := false) -> void:
	contorno = _color(paleta.contorno, oscurecer)
	for capa in paleta.capas:
		capas.append([_color(capa[0], oscurecer), capa[1]])
	for k in paleta.ventosas:
		ventosas[k] = _color(paleta.ventosas[k], oscurecer)


static func _color(c: Color, oscurecer: bool) -> Color:
	return Color(c.r * c.r, c.g * c.g, c.b * c.b, c.a) if oscurecer else c


# Hacia dónde va este latigazo y hasta dónde llega antes de dar con una pared o un mueble, como las cargas de los
# jefes (Aviso.franja): por dónde pasaría un círculo del ancho del golpe. Si choca, llega hasta tocar la pared
func apuntar(cuerpo: Node2D, angulo_: float) -> void:
	angulo = angulo_
	var circulo := CircleShape2D.new()
	circulo.radius = ancho
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = circulo
	consulta.transform = Transform2D(0.0, cuerpo.global_position)
	consulta.motion = Vector2.from_angle(angulo) * largo
	consulta.collision_mask = 1   # paredes y muebles
	var hasta := cuerpo.get_world_2d().direct_space_state.cast_motion(consulta)
	choca = hasta[1] < 1.0 and largo * hasta[0] + ancho < largo
	llega = largo * hasta[0] + ancho if choca else largo


# ¿Está Johnny dentro de la franja? Se mira lo lejos que queda de la línea del latigazo, hasta donde llega
func golpea(cuerpo: Node2D, johnny: Node2D) -> bool:
	var linea := Vector2.from_angle(angulo)
	var hacia: Vector2 = johnny.global_position - cuerpo.global_position
	var a_lo_largo := clampf(hacia.dot(linea), 0.0, llega)
	return hacia.distance_to(linea * a_lo_largo) <= ancho + johnny.RADIO


# El aviso en el suelo, el de las cargas de los jefes: flechas que se encienden una tras otra hacia donde va, los
# puntos que marcan el ancho y, al final, una X (o una estrella si se para en una pared). Va por detrás de todo el
# cuerpo. "cual": si tiene varios a la vez, cuál
func avisar(cuerpo: Node2D, desde: Vector2, k: float, tiempo: float, cual := 0) -> void:
	var aviso := Aviso.pedir(cuerpo, 0, desde, angulo, k, tiempo, cual)
	aviso.largo = llega
	aviso.medio = ancho
	aviso.choca = choca


# Levantado por encima de la cabeza, como un gancho: sube recto de la raíz, echado un poco hacia atrás, arriba se
# curva hasta apuntar hacia donde va y la punta se enrosca. "k" va de 0 a 1 durante el aviso: primero sale y sube, y
# luego se enrosca cada vez más y tiembla (con "tiembla" a 0, quieto). "lado": hacia qué lado se enrosca si apunta
# justo abajo o justo arriba (el de su raíz, por fuera del cuerpo); "t", el tiempo que lleva, para el temblor
func levantado(raiz: Vector2, k: float, t: float, lado: float, tiembla := 1.0) -> PackedVector2Array:
	var hacia := Vector2.from_angle(angulo)
	var tramo := enroscado / PUNTOS * ease(minf(1.0, k / 0.35), 0.5)
	var sube := -PI / 2 - 0.3 * hacia.x
	# Lo que gira para apuntar, por el lado más corto. Si va justo al revés (abajo), gira por el lado de la raíz, por
	# fuera del cuerpo; y si va justo arriba, también se enrosca hacia ese lado
	var giro := wrapf(hacia.angle() - sube, -PI, PI)
	if absf(giro) > PI * 0.9:
		giro = fposmod(hacia.angle() - sube, TAU) if lado > 0.0 else -fposmod(sube - hacia.angle(), TAU)
	var enrosca := (signf(giro) if absf(giro) > 0.2 else lado) * (0.6 + 1.8 * k)
	var puntos := PackedVector2Array([raiz])
	for i in PUNTOS:
		var s := (i + 0.5) / PUNTOS
		var hacia_donde := sube + giro * smoothstep(0.3, 0.85, s) + enrosca * pow(s, 2.5)
		hacia_donde += sin((t + desfase) * 47.0 + i * 1.3) * 0.08 * k * tiembla
		puntos.append(puntos[i] + Vector2.from_angle(hacia_donde) * tramo)
	gordo = minf(1.0, 0.3 + 2.0 * k)   # sale fino y engorda enseguida
	return puntos


# Estirado como un látigo hasta el final del aviso (donde llega: si hay pared, hasta ella): sale de la raíz hacia
# arriba y baja hasta la punta, primero en arco por lo alto y luego ("cae" de 0 a 1) tendido sobre el aviso, que
# empieza en "suelo". Una onda lo recorre de la base a la punta. El codo cae sobre el aviso siempre más allá de la
# raíz: si va hacia arriba y la raíz está muy alta (el gerente), si no, el tentáculo bajaría y volvería a subir
func estirado(raiz: Vector2, suelo: Vector2, cae: float, t: float) -> PackedVector2Array:
	var hacia := Vector2.from_angle(angulo)
	var punta := suelo + Vector2(0, -6) + hacia * llega
	var arriba := raiz + Vector2(0, -36) * alto
	var en_alto := raiz + Vector2(0, -70) * alto + hacia * llega * 0.4
	var hasta_codo := minf(maxf(llega * 0.32, (raiz - suelo).dot(hacia) + 40.0), llega * 0.8)
	var codo := en_alto.lerp(suelo + Vector2(0, -10) + hacia * hasta_codo, cae)
	var lado := (punta - raiz).orthogonal().normalized()
	var puntos := PackedVector2Array()
	for i in PUNTOS + 1:
		var s := float(i) / PUNTOS
		var u := 1.0 - s
		var p := raiz * u * u * u + arriba * 3.0 * u * u * s + codo * 3.0 * u * s * s + punta * s * s * s
		puntos.append(p + lado * sin(s * 2.0 * TAU - t * 90.0) * 8.0 * alto * sin(s * PI))
	return puntos


# El latigazo: sale disparado desde lo alto, cae sobre el aviso y se recoge hacia la raíz. "t", lo que lleva desde
# el golpe; "dura", cuándo acaba de recogerse
func latigo(raiz: Vector2, suelo: Vector2, t: float, dura: float, lado: float) -> PackedVector2Array:
	var sale := smoothstep(0.0, 0.05, t)
	var recoge := smoothstep(0.13, dura, t)
	var antes := levantado(raiz, 1.0, t, lado, 0.0)
	var tendido := estirado(raiz, suelo, smoothstep(0.03, 0.1, t), t)
	var puntos := PackedVector2Array()
	for i in PUNTOS + 1:
		puntos.append(raiz + (antes[i].lerp(tendido[i], sale) - raiz) * (1.0 - recoge))
	gordo = 1.0 - 0.7 * recoge   # al recogerse, más fino
	return puntos


# Pinta los trozos del tentáculo de "desde" a "hasta" (por sus puntos), igual que los de su dibujo: el contorno y
# encima las capas, cada una más clara y más pequeña y arrimada al lado de la luz; y las ventosas, por el lado de la
# sombra. Grueso en la base y fino en la punta
func pintar(lienzo: CanvasItem, puntos: PackedVector2Array, desde: int, hasta: int) -> void:
	var r := PackedFloat32Array()
	var luz := PackedVector2Array()     # hacia dónde se arriman las capas claras (de lado al tentáculo)
	var sombra := PackedVector2Array()  # el lado contrario, el de las ventosas
	for i in PUNTOS + 1:
		r.append((fino + (grueso - fino) * pow(1.0 - float(i) / PUNTOS, 0.8)) * gordo)
		var n := (puntos[mini(i + 1, PUNTOS)] - puntos[maxi(i - 1, 0)]).orthogonal().normalized()
		# Del todo al borde de la luz, salvo cuando el tentáculo va justo hacia la luz: ahí pasa poco a poco por el
		# medio, para que el brillo no salte de un borde al otro
		var cuanto := clampf(n.dot(LUZ.normalized()) * 2.5, -1.0, 1.0)
		luz.append(n * cuanto)
		sombra.append(-n if cuanto >= 0.0 else n)
	# La parte de delante empieza cortada en recto, sin redondel: así no se nota la juntura con la de detrás
	var primero := desde + 1 if desde > 0 else 0
	for i in range(primero, hasta + 1):
		lienzo.draw_circle(puntos[i], r[i] + 1.0, contorno)
	for i in range(desde, hasta):
		lienzo.draw_line(puntos[i], puntos[i + 1], contorno, r[i] + r[i + 1] + 2.0)
	for capa in capas:
		var arrima: float = 1.0 - capa[1]
		for i in range(primero, hasta + 1):
			lienzo.draw_circle(puntos[i] + luz[i] * r[i] * arrima, maxf(0.5, r[i] * capa[1]), capa[0])
		for i in range(desde, hasta):
			lienzo.draw_line(puntos[i] + luz[i] * r[i] * arrima, puntos[i + 1] + luz[i + 1] * r[i + 1] * arrima,
				capa[0], maxf(1.0, (r[i] + r[i + 1]) * capa[1]))
	# Las ventosas, en fila por el lado de la sombra (hasta cerca de la punta)
	for i in range(maxi(desde, 2), hasta):
		if r[i] < 2.5:
			continue
		if ventosas.has("punto"):
			# puntitos claros por el medio de la cara de abajo, dos en cada trozo
			for p in [puntos[i], (puntos[i] + puntos[i + 1]) / 2.0]:
				var punto: Vector2 = p + sombra[i] * r[i] * 0.55
				lienzo.draw_rect(Rect2(punto.floor() - Vector2.ONE, Vector2(2, 2)), ventosas.punto)
			continue
		# aros: el aro con su sombra hacia fuera, el hueco oscuro y un punto de brillo hacia la luz
		var v := puntos[i] + sombra[i] * r[i] * 0.4
		var tam := maxf(1.5, r[i] * 0.38)
		lienzo.draw_circle(v, tam + 0.5, contorno)
		lienzo.draw_circle(v + sombra[i] * 0.5, tam, ventosas.sombra)
		lienzo.draw_circle(v - sombra[i] * 0.3, tam - 0.5, ventosas.aro)
		lienzo.draw_circle(v, maxf(0.5, tam * 0.45), ventosas.hueco)
		lienzo.draw_rect(Rect2((v - sombra[i] * tam * 0.7).floor(), Vector2.ONE), ventosas.brillo)
