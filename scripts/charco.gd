# Un charco en el suelo: el moco verde del venenoso, la lejía de la portera, el vómito de Johnny (mutación
# Gastroenteritis), el fuego del molotov, el aceite de la probeta del científico jefe, que resbala y al secarse arde:
# se convierte en un fuego como el del molotov, un poco más grande, o el aceite hirviendo del cocinero.
# Cada uno pone sus estados (estados.gd) a quien lo pisa: el veneno te sigue envenenando al salir, la lejía resbala,
# el ácido solo daña a los zombis... Al rato se seca.
# Como HAZARDS en src/game-ataques.js.
#
# El fuego (makeFire y burnFire de src/molotov.js) es especial: se dibuja con código, a cuadraditos de pixel
# art. Se extiende desde el centro, arde con llamas y ascuas, se apaga por trozos al final y deja una mancha
# de ceniza. Prende a los zombis que lo pisan (siguen ardiendo al salir: zombi.gd) y lleva su luz de fuego.
#
# El aceite hirviendo del cocinero ("hirviendo") quema como el fuego (a Johnny y a los zombis, pero no a él: es su
# "dueno"); se dibuja también con código, una mancha dorada con burbujas que revientan y algo de vapor. El que rebosa
# de los fogones y las freidoras de su cocina (M82, cocinero.gd) es el mismo, más grande y con "crece": en vez de
# extenderse de golpe, se va extendiendo despacio por el suelo (y solo quema hasta donde ha llegado).
#
# El veneno, el ácido, el vómito, la lejía y el agua ("burbujas" en TIPOS; el agua, sin burbujas ni vapor) se dibujan como el fuego, a cuadraditos y con el borde
# ondulado: se extienden desde el centro, sus colores tiemblan, en vez de llamas tienen burbujitas que crecen y
# revientan, echan algo de vapor y al secarse desaparecen a trozos, antes por los bordes, dejando una mancha.
class_name Charco
extends Node2D

const LUZ_FUEGO := preload("res://escenas/luces/fuego.tscn")

# Cada tipo: su dibujo, su tamaño (radio), cuánto dura y los estados que pone. "solo_zombis": a Johnny no le
# hace nada. El del molotov tiene sus números en MOLOTOV (lanzables.gd)
const TIPOS := {
	"veneno": {"burbujas": "veneno", "radio": 64.0, "vida": 4.0, "estados": {"veneno": {}}},
	# el que deja el gordo al reventar (M38, zombi_venenoso.gd): el mismo veneno que escupe, pero grande, más largo y con
	# burbujas gordas (las de "toxic-puddle" de pixelfx, ver pintar_burbujas_gordas)
	"reventon": {"burbujas": "veneno", "radio": 96.0, "vida": 6.0, "estados": {"veneno": {}}, "gordas": 6},
	"lejia": {"burbujas": "lejia", "radio": 54.0, "vida": 5.0, "estados": {"resbaladizo": {}, "toxico": {"dps": 3.0}}},
	# el ácido que salpica la portera con la fregona: quema al pisarlo y deja veneno al salir (ACIDO en el JS)
	"acido": {"burbujas": "acido", "radio": 58.0, "vida": 6.0, "estados": {"acido": {}, "veneno": {}}},
	"sangre_gloton": {"burbujas": "acido", "radio": 30.0, "vida": 5.0, "estados": {"acido": {}, "veneno": {}}},   # los pequeños que salpica el Glotón
	"vomito": {"burbujas": "vomito", "radio": 55.0, "vida": 4.0, "estados": {"acido": {"dps": 8.0}, "vomito": {}}, "solo_zombis": true},
	# el que deja un zombi que muere con ácido si Johnny tiene el talento Residuo tóxico (zombi.gd, quimica_al_morir):
	# como el de la portera pero más pequeño, y solo a los zombis
	"residuo": {"burbujas": "acido", "radio": 40.0, "vida": 4.0, "estados": {"acido": {"dps": 8.0}}, "solo_zombis": true},
	"fuego": {"radio": 64.0, "vida": 4.0, "estados": {"fuego": {"dps": 12.0}}},
	"aceite": {"burbujas": "aceite", "radio": 54.0, "vida": 2.0, "estados": {"resbaladizo": {}}},
	"hirviendo": {"radio": 60.0, "vida": 6.0, "estados": {"fuego": {"dps": 12.0}}, "prende": true},   # el del cocinero
	# el agua de los aspersores (la alarma de incendios, eventos.gd): solo resbala, y no se seca mientras dure
	# el café de los vasos del becario (becario.gd): solo resbala
	"cafe": {"burbujas": "cafe", "radio": 50.0, "vida": 6.0, "estados": {"resbaladizo": {}}},
	# el agua de los cubos del Sujeto 1 (sujeto_1.gd): solo resbala, 6 s
	"agua_cubo": {"burbujas": "agua", "radio": 56.0, "vida": 6.0, "estados": {"resbaladizo": {}}},
	"agua": {"burbujas": "agua", "radio": 54.0, "vida": 99999.0, "estados": {"resbaladizo": {}}},
}
# Los colores de los charcos que burbujean: del borde al centro, los brillos, la burbuja (y su brillo), el vapor y
# la mancha que dejan al secarse
const BURBUJEO := {
	"veneno": {"borde": Color("#1d4a1a"), "oscuro": Color("#2f7a22"), "medio": Color("#4fae2c"), "centro": Color("#7ad63a"),
		"brillo": Color("#c8f77a"), "burbuja": Color("#8fe04a"), "luz": Color("#e6ffb0"), "vapor": Color(0.6, 1.0, 0.4, 0.35),
		"mancha": Color("#1a2e14", 0.55)},
	"acido": {"borde": Color("#4a4a12"), "oscuro": Color("#7d8a1c"), "medio": Color("#b4c62a"), "centro": Color("#dceb44"),
		"brillo": Color("#f8ff9c"), "burbuja": Color("#e4f25a"), "luz": Color("#ffffd0"), "vapor": Color(0.95, 1.0, 0.5, 0.35),
		"mancha": Color("#2e2c12", 0.55)},
	"vomito": {"borde": Color("#5a4214"), "oscuro": Color("#8a6e22"), "medio": Color("#b89a34"), "centro": Color("#d6bc4c"),
		"brillo": Color("#f2e08c"), "burbuja": Color("#d8c25a"), "luz": Color("#fff2bc"), "vapor": Color(0.9, 0.85, 0.5, 0.3),
		"mancha": Color("#2e2410", 0.5)},
	# la lejía: blanquecina, con un punto azulado gris (que no parezca agua), y sus burbujas son espuma blanca
	"lejia": {"borde": Color("#76888e"), "oscuro": Color("#a8b8bc"), "medio": Color("#cfdcdd"), "centro": Color("#e9f0ee"),
		"brillo": Color("#ffffff"), "burbuja": Color("#fbfdfc"), "luz": Color("#ffffff"), "vapor": Color(0.95, 0.97, 0.97, 0.3),
		"mancha": Color("#3a4246", 0.4)},
	# el agua (los aspersores y los cubos; también el charco con corriente de Electrónica, agua.gd): azul, con brillos
	# pero sin burbujas ni vapor, y al secarse no deja mancha
	"agua": {"borde": Color("#1d3f6a"), "oscuro": Color("#2e609d"), "medio": Color("#4f8fd0"), "centro": Color("#7dbbf3"),
		"brillo": Color("#d8f0ff"), "luz": Color("#ffffff"), "sin_burbujas": true, "ondas": true},
	# el aceite de la probeta del científico jefe: dorado, con el brillo grasiento; no se seca (al acabar arde, arder)
	"aceite": {"borde": Color("#5a3a0c"), "oscuro": Color("#8a5a14"), "medio": Color("#c08a22"), "centro": Color("#e6b84a"),
		"brillo": Color("#fff0b0"), "sin_burbujas": true, "no_seca": true},
	# el café de los vasos del becario: marrón, y al secarse deja su mancha
	"cafe": {"borde": Color("#2a160a"), "oscuro": Color("#4a2a14"), "medio": Color("#6e4222"), "centro": Color("#8a5a30"),
		"brillo": Color("#d8b48a"), "sin_burbujas": true, "mancha": Color("#2a1a10", 0.4)},
}
# Cuánto tarda en extenderse al caer y cuánto antes de acabar empieza a secarse
const DERRAMA := 0.25
const SECA := 1.2
const ACEITE_ARDE := 1.25   # el fuego del aceite, así de grande respecto al del molotov
# El fuego por fuera: cuánto tarda en extenderse, cuánto antes de acabar empieza a apagarse, lo que brilla en
# blanco el frente y lo que dura la brasa de un trozo recién apagado
const EXTIENDE := 0.35
const APAGA := 1.4
const FRENTE := 0.07
const BRASA := 0.3
const CELDA := 4.0   # 2 píxeles del dibujo
const GOTA := 2.0    # los cuadraditos de los charcos que burbujean y del agua: un píxel del dibujo (como Johnny)

var tipo := "veneno"
var fregado := false       # la limpiadora de noche lo ha fregado: se seca enseguida (fregar)
var dueno: Node2D = null   # quien lo ha tirado: a él no le hace nada (el cocinero y su aceite hirviendo)
var escala := 1.0          # el Fabricante hace el fuego más grande...
var duracion := 1.0        # ...y más largo
var extra := 0.0           # segundos de más que dura (Napalm: el fuego del molotov de Johnny)
var dano_lanzar := 1.0     # Puntería: el fuego quema más a los zombis
var crece := 0.0           # M82: el aceite hirviendo que rebosa de la cocina, lo que tarda en llegar a su tamaño (0: de golpe)
var vida := 0.0
var vida_max := 0.0
var t := 0.0
var tick := 0.0
var celdas: Array = []     # el fuego: [posición, distancia al centro (0-1), cuándo prende, cuándo se apaga, ruido]
var llamas: Array = []     # [x, y, ancho, alto, semilla, prende, apaga]
var ascuas: Array = []
var burbujas: Array = []   # el aceite hirviendo: [sitio, cuándo empieza, cada cuánto revienta, lo lejos del centro]; el veneno, ver hacer_burbujeo
var ondas_agua: Array = []    # el agua: los anillos que crecen y se apagan (hacer_ondas)
var celdas_por_sitio := {}    # los charcos que burbujean: cada cuadradito, por su sitio (preparar_liquido)
var gordas: Array = []     # las burbujas gordas del reventón: [su celda, desfase, cada cuánto revienta, lo grande que se hace]


func _ready() -> void:
	vida_max = TIPOS[tipo].vida * duracion + extra
	vida = vida_max
	z_index = -1   # en el suelo: por debajo de todos
	material = Recorte.material("aire" if tipo == "fuego" else "suelo")   # (ni encima de las paredes ni al otro lado; las llamas suben)
	add_to_group("charcos")
	if tipo == "hirviendo":
		hacer_hirviendo()
	if burbujea():
		hacer_burbujeo()
	if tipo == "fuego":
		hacer_fuego()
		var luz := LUZ_FUEGO.instantiate()
		luz.radio = radio() * 3.0
		luz.vida = vida_max
		add_child(luz)


# La limpiadora de noche (aliado.gd, fregar) se lleva estos: el veneno, el ácido, la lejía y el aceite (los que resbalan)
const FREGABLES := ["veneno", "reventon", "acido", "sangre_gloton", "lejia", "aceite"]


# Fregado: se seca de golpe, a trozos como siempre (el aceite, sin arder: se quita sin más)
func fregar() -> void:
	fregado = true
	if tipo == "aceite":
		queue_free()
		return
	vida = minf(vida, 0.45)


func radio() -> float:
	return TIPOS[tipo].radio * escala


# El aceite hirviendo, lo que se ha extendido ya (0-1): el de la sartén, en un momento; el que rebosa de la cocina
# (M82), despacio, más deprisa al principio (como un líquido que se derrama)
func extendido() -> float:
	if crece <= 0.0:
		return minf(1.0, t / 0.25)
	var k := minf(1.0, t / crece)
	return 0.25 + 0.75 * (1.0 - (1.0 - k) * (1.0 - k))


func burbujea() -> bool:
	return TIPOS[tipo].has("burbujas")


func _physics_process(delta: float) -> void:
	vida -= delta
	t += delta
	if vida <= 0.0:
		if tipo == "aceite":
			arder()
		elif tipo == "fuego" or burbujea():
			dejar_ceniza()
		queue_free()
		return
	if tipo == "fuego":
		quemar(delta)
	elif tipo == "aceite":
		modulate.a = 1.0   # el aceite no se seca: arde
	elif burbujea():
		echar_vapor()   # se seca a trozos (en _draw), no transparentándose entero
	else:
		if TIPOS[tipo].get("prende", false):
			prender_zombis(delta)
		if tipo == "hirviendo":
			hervir(delta)
		# Al final se va secando (más transparente)
		modulate.a = clampf(vida / 0.6, 0.0, 1.0)
	if not burbujea() or Engine.get_physics_frames() % 2 == 0:   # los líquidos, a 30 fotogramas: tienen muchos cuadraditos
		queue_redraw()
	var datos: Dictionary = TIPOS[tipo]
	var johnny := get_tree().get_first_node_in_group("jugador")
	# ningún charco cruza las paredes: al otro lado de un tabique ni Johnny ni los zombis lo pisan (hasta el 10 nov, solo
	# el vómito de Gastroenteritis y el residuo; el fuego del molotov, roto contra la pared, quemaba al de detrás)
	if not datos.get("solo_zombis", false) and johnny and johnny.vivo and arde_en(johnny.global_position, johnny.RADIO * 0.3) \
			and not ArmasCreadas.tapado(self, global_position, johnny.global_position):
		johnny.pisar(datos.estados)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi != dueno and zombi.has_method("pisar") and arde_en(zombi.global_position, zombi.radio * 0.3):
			if ArmasCreadas.tapado(self, global_position, zombi.global_position):
				continue
			zombi.pisar(datos.estados)


# El charco es una elipse (más ancha que alta, porque el suelo se ve un poco desde arriba)
func dentro(punto: Vector2, margen: float) -> bool:
	var d := punto - global_position
	var r := radio() * (extendido() if tipo == "hirviendo" else 1.0) + margen
	return (d.x / r) ** 2 + (d.y / (r * 0.6)) ** 2 <= 1.0


# Si ahí se ve el charco: el fuego, solo donde ya ha llegado y aún no se ha apagado
func arde_en(punto: Vector2, margen: float) -> bool:
	if not dentro(punto, margen):
		return false
	if tipo != "fuego" and not burbujea():
		return true
	var d := punto - global_position
	var k := Vector2(d.x, d.y / 0.6).length() / radio()
	var e := vida_max - vida
	if burbujea():
		return e >= k * DERRAMA and vida > SECA * k * 0.5
	return e >= k * EXTIENDE and vida > APAGA * k * 0.5


# ── El fuego ──

func hacer_fuego() -> void:
	var r := radio()
	var ondas := []
	for k in [3, 5, 7]:
		ondas.append([k, randf() * TAU, randf_range(0.05, 0.12)])
	var ruido_liso := FastNoiseLite.new()   # como en los líquidos: trozos, no puntitos sueltos
	ruido_liso.seed = randi()
	ruido_liso.frequency = 0.09
	var n := ceili(r / GOTA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * GOTA
			var a := atan2(p.y / 0.6, p.x)
			var borde := 1.0
			for o in ondas:
				borde += sin(a * o[0] + o[1]) * o[2]
			var d := Vector2(p.x, p.y / 0.6).length() / r / borde
			var ruido := ruido_liso.get_noise_2dv(p) * 0.5 + 0.5   # (0-1, suave)
			if d > 1.0 or (d > 0.85 and ruido < 0.4):
				continue
			# prende del centro hacia fuera; se apaga a trozos, antes por los bordes
			var prende := d * EXTIENDE + ruido * 0.05
			var apaga := vida_max - APAGA * (1.0 - d * 0.6) * (0.5 + ruido * 0.5)
			celdas.append([p, d, prende, apaga, ruido])
	# las llamas, en sitios al azar (de atrás adelante, para que las de delante tapen a las de detrás)
	for i in 14:
		var c: Array = celdas.pick_random()
		if c[1] > 0.8:
			continue
		var grande: float = 1.0 - c[1]
		llamas.append([c[0].x + 1.0, c[0].y + 1.0, roundf(4 + grande * 5 + i % 2), roundf(6 + grande * 13 + (i % 3) * 2), randf() * 10.0, c[2], c[3]])
	llamas.sort_custom(func(a, b): return a[1] < b[1])
	for i in 24:
		ascuas.append(celdas.pick_random())


# Cada poco, prende a los zombis que estén dentro; y suelta chispas de donde aún arde
func quemar(delta: float) -> void:
	prender_zombis(delta)
	if randf() < 30.0 * delta:
		var a := randf() * TAU
		var r := sqrt(randf()) * radio() * 0.85
		var p := global_position + Vector2(cos(a) * r, sin(a) * r * 0.6)
		if arde_en(p, 0.0):
			Particulas.soltar(self, p, Vector2(randf_range(-10, 10), randf_range(-140, -70)), Llamas.FUEGO[randi() % 4], randf_range(1, 3), 0.45)


func prender_zombis(delta: float) -> void:
	tick += delta
	if tick >= Lanzables.MOLOTOV.tick:
		tick -= Lanzables.MOLOTOV.tick
		for zombi in get_tree().get_nodes_in_group("zombis"):
			if zombi == dueno or not arde_en(zombi.global_position, zombi.radio * 0.5):
				continue
			# el zombi se prende y la quemadura la lleva él: dentro se le renueva sin parar, y al salir sigue
			# ardiendo unos segundos. La portera no sabe arder: a ella se la quema solo dentro del fuego
			if zombi.has_method("prender"):
				zombi.prender(dano_lanzar)
			else:
				zombi.herir(Lanzables.MOLOTOV.quema * Lanzables.MOLOTOV.tick * dano_lanzar * Lanzables.a_jefe(zombi), Llamas.FUEGO[2])


# El aceite, al acabar, arde: en su sitio, un fuego como el del molotov (con su llamarada)
func arder() -> void:
	var fuego: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
	fuego.tipo = "fuego"
	fuego.escala = escala * ACEITE_ARDE
	fuego.duracion = duracion
	fuego.dano_lanzar = dano_lanzar
	fuego.dueno = dueno   # (a quien tiró el aceite, el científico jefe, tampoco le quema su fuego)
	fuego.position = position
	get_parent().add_child(fuego)
	Sonido.tocar("fuego")
	Luz.destello(get_parent(), global_position, radio() * 3.0, 0.3, 0.8)
	for i in 16:
		var a := randf() * TAU
		Particulas.soltar(self, global_position + Vector2(0, -6), Vector2(cos(a) * 160.0, sin(a) * 90.0 - 40.0), Llamas.FUEGO[i % 4],
			randf_range(2, 4), 0.5)


# Al apagarse del todo, la ceniza se queda en el suelo como una mancha más (el veneno, el ácido y el vómito dejan
# la suya, más clarita y solo por el centro)
func dejar_ceniza() -> void:
	if burbujea() and not BURBUJEO[TIPOS[tipo].burbujas].has("mancha"):
		return
	var m := Mancha.new()
	m.position = position
	m.material = Recorte.material("suelo")   # (como el charco: sin pasar a las paredes)
	for c in celdas:
		if burbujea():
			if c[1] < 0.75 and c[6] < 2.0:   # (por manchas: c[6] es un ruido suave)
				m.celdas.append([c[0], BURBUJEO[TIPOS[tipo].burbujas].mancha, Vector2(GOTA, GOTA)])
		else:
			m.celdas.append([c[0], Color("#1c120e", 0.7) if c[4] < 0.5 else Color("#2a1a14", 0.6), Vector2(GOTA, GOTA)])
	get_parent().add_child(m)


# ── El veneno, el ácido y el vómito ──

# Su forma, como la del fuego: cuadraditos con el borde ondulado, que aparecen del centro hacia fuera y se secan a
# trozos, antes por los bordes. Y las burbujas, en sitios al azar
func hacer_burbujeo() -> void:
	var r := radio()
	var ondas := []
	for k in [3, 5, 7]:
		ondas.append([k, randf() * TAU, randf_range(0.05, 0.11)])
	var ruido_liso := FastNoiseLite.new()   # un ruido suave: el borde ondula sin dejar puntitos sueltos
	ruido_liso.seed = randi()
	ruido_liso.frequency = 0.06
	var n := ceili(r / GOTA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * GOTA
			var a := atan2(p.y / 0.6, p.x)
			var borde := 1.0
			for o in ondas:
				borde += sin(a * o[0] + o[1]) * o[2]
			var liso := ruido_liso.get_noise_2dv(p) * 0.5 + 0.5
			borde *= 1.0 - 0.1 * liso
			var d := Vector2(p.x, p.y / 0.6).length() / r / borde
			if d > 1.0:
				continue
			var ruido := randf()
			var aparece := d * DERRAMA + ruido * 0.04
			var seca := vida_max - SECA * (1.0 - d * 0.6) * (0.6 + liso * 0.4)   # se seca por manchas, no a puntitos
			if BURBUJEO[TIPOS[tipo].burbujas].get("no_seca", false):
				seca = vida_max + 1.0
			celdas.append([p, d, aparece, seca, ruido])
	celdas_por_sitio = Charco.preparar_liquido(celdas, r, ruido_liso)
	if BURBUJEO[TIPOS[tipo].burbujas].get("ondas", false):
		ondas_agua = Charco.hacer_ondas(celdas, 2, r)
	if BURBUJEO[TIPOS[tipo].burbujas].get("sin_burbujas", false):
		return
	# cada burbuja: [su celda, cuándo empieza, cada cuánto revienta, lo grande que se hace (en píxeles del dibujo)]
	for i in 30:
		var c: Array = celdas.pick_random()
		if c[1] < 0.8:
			burbujas.append([c, randf() * 2.0, randf_range(0.9, 1.8), 2 + i % 2])
		if burbujas.size() >= 11:
			break
	for i in 40:
		var c: Array = celdas.pick_random()
		if gordas.size() >= TIPOS[tipo].get("gordas", 0):
			break
		if c[1] < 0.7:
			gordas.append([c, randf() * 3.0, randf_range(1.8, 2.6), randf_range(4.0, 6.5)])


# Algo de vapor que sube de donde aún hay charco
func echar_vapor() -> void:
	if not BURBUJEO[TIPOS[tipo].burbujas].has("vapor"):
		return
	if randf() < 6.0 * get_physics_process_delta_time():
		var a := randf() * TAU
		var r := sqrt(randf()) * radio() * 0.8
		var p := global_position + Vector2(cos(a) * r, sin(a) * r * 0.6)
		if arde_en(p, 0.0):
			Particulas.soltar(self, p, Vector2(randf_range(-6, 6), randf_range(-45, -25)), BURBUJEO[TIPOS[tipo].burbujas].vapor,
				randf_range(2, 4), 0.8)


func pintar_burbujeo() -> void:
	var col: Dictionary = BURBUJEO[TIPOS[tipo].burbujas]
	var e := vida_max - vida
	Charco.pintar_liquido(self, celdas, col, t, e)
	if col.get("ondas", false):
		Charco.pintar_ondas(self, ondas_agua, celdas_por_sitio, col, t)
	# las burbujas: crecen a saltos de píxel y revientan en gotitas, cada una a su ritmo (no si su trozo ya se seca)
	for b in burbujas:
		var c: Array = b[0]
		if e < c[2] + 0.15 or e >= c[3] - 0.3:
			continue
		var k: float = fmod(t + b[1], b[2]) / b[2]
		var p: Vector2 = c[0]
		var grande: int = b[3]
		if k < 0.75:
			var r := 1 + int(k / 0.75 * grande)
			burbuja(p + Vector2(0, 2), r, col.borde, col.borde)   # su sombra, un píxel más abajo
			burbuja(p, r, col.burbuja, col.luz)
		elif k < 0.9:
			var lejos := 4.0 + grande * 2.0
			for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(-0.7, -0.7), Vector2(0.7, -0.7)]:
				draw_rect(Rect2((p + o * lejos - Vector2(1, 1)).snapped(Vector2(2, 2)), Vector2(2, 2)), col.luz)
	pintar_burbujas_gordas(col, e)


# ── El dibujo de los líquidos (los charcos que burbujean y el agua; también el agua con corriente, agua.gd) ──
# Cada cuadradito es un píxel del dibujo (GOTA) y lleva, desde la posición 5: su color de base (lo cerca del borde, más
# oscuro abajo a la derecha porque la luz viene de arriba a la izquierda), su fase (un ruido suave: las bandas de color
# se mecen como olas, no parpadea cada uno por su cuenta) y si es del contorno (siempre del color más oscuro).
# Encima, un brillo en vetas que resbala despacio (como el de "toxic-puddle" de pixelfx) y, en el agua, anillos de
# ondas (como los de "ripples"). Las celdas: [posición, d (0 centro, 1 borde), aparece, se seca, ruido, ...]

# Completa cada celda y devuelve un diccionario sitio -> celda (para el contorno y las ondas). "r", el tamaño del
# charco (para la luz); las posiciones, desde su centro
static func preparar_liquido(lista: Array, r: float, ruido_liso: FastNoiseLite) -> Dictionary:
	var sitios := {}
	for c in lista:
		sitios[Vector2i((c[0] / GOTA).round())] = c
	for c in lista:
		var p: Vector2 = c[0]
		var s := Vector2i((p / GOTA).round())
		var contorno := false
		for v in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not sitios.has(s + v):
				contorno = true
		var luz := (p.x / r + p.y / (0.6 * r)) * 0.09
		c.append(c[1] + luz)                                             # 5: su color de base
		c.append(ruido_liso.get_noise_2d(p.x * 0.6, p.y * 0.6) * 6.0)   # 6: su fase
		c.append(contorno)                                               # 7: del contorno
	return sitios


# Pinta los cuadraditos: los de una fila seguidos y del mismo color, de un solo rectángulo. "e", lo que lleva hecho
# el charco (los que aún no han llegado o ya se han secado no se pintan; el recién secado, un momento más oscuro)
static func pintar_liquido(n: CanvasItem, lista: Array, col: Dictionary, t: float, e: float) -> void:
	var fila := -99999.0
	var desde := Vector2.ZERO
	var hasta := 0.0
	var color_tira := Color.TRANSPARENT
	for c in lista:
		if e < c[2] or e >= c[3] + 0.2:
			continue
		var p: Vector2 = c[0]
		var color: Color
		if e >= c[3]:
			color = Color(col.borde, 0.6)
		elif c[7]:
			color = col.borde
		else:
			var d: float = c[5] + 0.05 * sin(t * 2.2 + c[6])
			color = col.centro if d < 0.35 else col.medio if d < 0.62 else col.oscuro if d < 0.86 else col.borde
			if c[1] < 0.75:
				# el brillo en vetas: líneas casi horizontales que ondulan y se desplazan
				var v := sin(p.y * 0.35 + sin(p.x * 0.06 + t * 0.7) * 2.2 + c[6] * 0.25) * sin(p.x * 0.045 - t * 0.5 + c[6] * 0.1)
				if v > 0.86:
					color = col.brillo
				elif v > 0.74 and color != col.centro:
					color = col.centro
		if p.y == fila and p.x == hasta and color == color_tira:
			hasta += GOTA
			continue
		if color_tira.a > 0.0:
			n.draw_rect(Rect2(desde, Vector2(hasta - desde.x, GOTA)), color_tira)
		fila = p.y
		desde = p
		hasta = p.x + GOTA
		color_tira = color
	if color_tira.a > 0.0:
		n.draw_rect(Rect2(desde, Vector2(hasta - desde.x, GOTA)), color_tira)


# Los anillos del agua: cada uno nace cerca del centro, crece y se apaga, a su ritmo. [centro, cada cuánto, desfase, tamaño]
static func hacer_ondas(lista: Array, cuantas: int, r: float) -> Array:
	var ondas := []
	for i in 30:
		var c: Array = lista.pick_random()
		if c[1] < 0.45:
			ondas.append([c[0], randf_range(1.8, 2.6), randf() * 3.0, r * randf_range(0.35, 0.5)])
		if ondas.size() >= cuantas:
			break
	return ondas


static func pintar_ondas(n: CanvasItem, ondas: Array, sitios: Dictionary, col: Dictionary, t: float) -> void:
	for o in ondas:
		var q: float = fmod(t + o[2], o[1]) / o[1]
		if q > 0.85:
			continue
		var radio_onda: float = 4.0 + q * o[3]
		var color: Color = col.centro.lerp(col.luz, 1.0 - q)
		var pasos := maxi(12, int(radio_onda * 0.8))
		for i in pasos:
			if i % 3 == 0:
				continue   # el anillo, a trozos (como las crestas de "ripples")
			var a := TAU * i / pasos
			var p: Vector2 = o[0] + Vector2(cos(a) * radio_onda, sin(a) * radio_onda * 0.6)
			var s := Vector2i((p / GOTA).round())
			var c: Array = sitios.get(s, [])
			if c.is_empty() or c[7] or c[1] > 0.85:
				continue
			n.draw_rect(Rect2(Vector2(s) * GOTA, Vector2(GOTA, GOTA)), color)


# Las burbujas gordas del reventón, como las de "toxic-puddle" de pixelfx: se hinchan en una cúpula con la piel oscura
# y la luz del veneno por dentro, se estiran hacia arriba y, al reventar, sueltan un anillo que corre por el charco,
# un fogonazo y unas gotitas que saltan. Las medidas, en píxeles del dibujo (cada uno, 2 × 2)
func pintar_burbujas_gordas(col: Dictionary, e: float) -> void:
	for b in gordas:
		var c: Array = b[0]
		if e < c[2] + 0.3 or e >= c[3] - 0.4:
			continue
		var ciclo: float = b[2]
		var edad := fmod(t + b[1], ciclo)
		var hincha := ciclo * 0.6
		var x0: Vector2 = (c[0] / 2.0).floor()   # (su sitio, en píxeles del dibujo)
		var grande: float = b[3]
		if edad < hincha:
			var k := edad / hincha
			var estira := smoothstep(0.65, 1.0, k)
			var crece := 1.0 - pow(1.0 - minf(1.0, k * 1.3), 3.0)
			var rx := grande * crece * (1.0 - 0.18 * estira)
			var ry := grande * crece * (1.0 + 0.5 * estira)
			var dentro_k := 0.35 + 0.65 * k
			for i in range(-int(rx), int(rx) + 1):   # su sombra en el charco, una fila por debajo
				punto(x0 + Vector2(i, 1), col.borde)
			for j in range(-ceili(ry) - 1, 1):
				for i in range(-ceili(rx) - 1, ceili(rx) + 2):
					var dd := Vector2(i / maxf(0.6, rx), j / maxf(0.6, ry)).length()
					if dd > 1.1:
						continue
					var color: Color
					if dd > 0.9:
						color = col.borde
					elif dd < 0.55 * dentro_k and j > -ry * 0.75:
						color = col.brillo if dd < 0.3 * dentro_k else col.centro
					elif dd < 0.8 * dentro_k:
						color = col.medio
					else:
						color = col.oscuro
					punto(x0 + Vector2(i, j), color)
			# el brillo: una curva clara arriba a la izquierda y un punto blanco
			if rx > 1.8:
				var a := 3.5
				while a < 4.7:
					punto(x0 + (Vector2(cos(a) * rx, sin(a) * ry) * 0.68).round(), col.luz if a < 4.3 else col.brillo)
					a += 0.16
			if rx > 1.2:
				punto(x0 + Vector2(-roundf(rx * 0.35), -roundf(ry * 0.62)), Color.WHITE)
			continue
		var pasa := edad - hincha
		# al reventar: un anillo que se abre por el charco (aplastado, como el suelo) y se apaga
		if pasa < 0.3:
			var k := pasa / 0.3
			var r := 2.0 + 14.0 * (1.0 - pow(1.0 - k, 3.0))
			var color: Color = Color.WHITE if k < 0.4 else col.luz if k < 0.7 else col.brillo
			var a := 0.0
			while a < TAU:
				punto(x0 + Vector2(cos(a) * r, sin(a) * r * 0.6).round(), Color(color, clampf((1.0 - k) * 1.4, 0.0, 1.0)))
				a += 0.5 / r
		# y unas gotitas que saltan y caen
		if pasa < 0.6:
			for j in 7:
				var azar := fmod(sin(j * 12.9898 + b[1] * 78.233) * 43758.5453, 1.0)
				var vx := (absf(azar) - 0.5) * 80.0
				var vy := -45.0 - absf(fmod(azar * 7.31, 1.0)) * 70.0
				var dy := vy * pasa + 0.5 * 420.0 * pasa * pasa
				if dy < 0.0:
					punto(x0 + Vector2(vx * pasa, dy - 2.0).round(), col.borde)
					punto(x0 + Vector2(vx * pasa, dy - 3.0).round(), col.luz if j % 2 else col.brillo)


# Un píxel del dibujo, en "p" (en píxeles del dibujo, desde el centro del charco)
func punto(p: Vector2, color: Color) -> void:
	draw_rect(Rect2(p * 2.0, Vector2(2, 2)), color)


# Una burbuja de pixel art: un cuadrado con las esquinas recortadas, de "r" píxeles del dibujo de radio, y su brillo
func burbuja(p: Vector2, r: int, color: Color, luz: Color) -> void:
	var u := 2.0   # un píxel del dibujo
	var lado := r * 2 * u
	var esquina := p - Vector2(r, r) * u
	if r == 1:
		draw_rect(Rect2(esquina, Vector2(lado, lado)), color)
		draw_rect(Rect2(esquina, Vector2(u, u)), luz)
		return
	draw_rect(Rect2(esquina + Vector2(u, 0), Vector2(lado - 2 * u, lado)), color)
	draw_rect(Rect2(esquina + Vector2(0, u), Vector2(lado, lado - 2 * u)), color)
	draw_rect(Rect2(esquina + Vector2(u, u), Vector2(u, u)), luz)


# ── El aceite hirviendo del cocinero ──

# Su forma, en cuadraditos como el fuego (con el borde ondulado), y dónde salen las burbujas
func hacer_hirviendo() -> void:
	var r := radio()
	var ondas := []
	for k in [3, 5]:
		ondas.append([k, randf() * TAU, randf_range(0.06, 0.12)])
	var n := ceili(r / CELDA)
	for y in range(-n, n + 1):
		for x in range(-n, n + 1):
			var p := Vector2(x, y) * CELDA
			var a := atan2(p.y / 0.6, p.x)
			var borde := 1.0
			for o in ondas:
				borde += sin(a * o[0] + o[1]) * o[2]
			var d := Vector2(p.x, p.y / 0.6).length() / r / borde
			if d <= 1.0:
				celdas.append([p, d, 0.0, 0.0, randf()])
	# (el grande de la cocina, M82, con más burbujas: las mismas por trozo de suelo)
	for i in roundi(9 * escala * escala):
		var c: Array = celdas.pick_random()
		if c[1] < 0.8:
			burbujas.append([c[0], randf() * 2.0, randf_range(0.7, 1.4), c[1]])


# Hierve: algo de vapor que sube
func hervir(delta: float) -> void:
	if randf() < 5.0 * delta:
		var a := randf() * TAU
		var r := sqrt(randf()) * radio() * extendido() * 0.7
		Particulas.soltar(self, global_position + Vector2(cos(a) * r, sin(a) * r * 0.6), Vector2(randf_range(-8, 8), randf_range(-50, -30)),
			Color(1, 0.95, 0.85, 0.4), randf_range(3, 5), 0.7)


func pintar_hirviendo() -> void:
	var hasta := extendido()   # al caer, se extiende en un momento (el de la cocina, M82, despacio)
	for c in celdas:
		if c[1] > hasta:
			continue
		var color := Color("#5e3510") if c[1] > 0.88 else Color("#9a5a16") if c[1] > 0.6 or c[4] < 0.25 else Color("#c07a22")
		if c[4] > 0.93:
			color = Color("#e8b04a")   # brillos
		draw_rect(Rect2(c[0], Vector2(CELDA, CELDA)), color)
	# las burbujas: crecen y revientan (un anillo claro), cada una a su ritmo
	for b in burbujas:
		if b[3] > hasta:
			continue   # (aún no ha llegado ahí el aceite)
		var k: float = fmod(t + b[1], b[2]) / b[2]
		var p: Vector2 = b[0] + Vector2(2, 2)
		if k < 0.8:
			Formas.disco(self, p, 1.0 + k * 4.0, Color("#f0c060"))
			Formas.disco(self, p + Vector2(-1, -1), 1.0, Color("#fff1c4"))
		else:
			Formas.arco(self, p, 6.0, 0.0, TAU, 10, Color("#fff1c4", 0.8), 1.5)


func _draw() -> void:
	if tipo == "hirviendo":
		pintar_hirviendo()
		return
	if burbujea():
		pintar_burbujeo()
		return
	var e := vida_max - vida
	var tira := [Vector2.ZERO, 0.0, Color.TRANSPARENT]   # [desde, hasta, color]
	for c in celdas:
		if e < c[2]:
			continue
		var color: Color
		if e >= c[3]:
			# ya apagado: brasa un momento y luego ceniza
			color = Color("#6e1d12") if e - c[3] < BRASA else (Color("#1c120e", 0.7) if c[4] < 0.5 else Color("#2a1a14", 0.6))
		elif e - c[2] < FRENTE:
			color = Llamas.FUEGO[0]   # el frente del fuego, recién prendido
		else:
			var d: float = c[1] + 0.12 * sin(t * 9.0 + c[4] * 7.0)   # el color tiembla un poco, por trozos
			color = Llamas.FUEGO[1] if d < 0.3 else Llamas.FUEGO[2] if d < 0.55 else Llamas.FUEGO[3] if d < 0.8 else Llamas.FUEGO[4]
			color.a = 0.9
		var p: Vector2 = c[0]
		if p.y == tira[0].y and p.x == tira[1] and color == tira[2]:
			tira[1] += GOTA
			continue
		if tira[2].a > 0.0:
			draw_rect(Rect2(tira[0], Vector2(tira[1] - tira[0].x, GOTA)), tira[2])
		tira = [p, p.x + GOTA, color]
	if tira[2].a > 0.0:
		draw_rect(Rect2(tira[0], Vector2(tira[1] - tira[0].x, GOTA)), tira[2])
	# ascuas: píxeles sueltos que se encienden y se apagan (solo donde arde)
	for i in ascuas.size():
		var c: Array = ascuas[i]
		if e < c[2] or e >= c[3]:
			continue
		var brillo := sin(t * (6 + i % 5) + i * 2.3)
		if brillo > 0.2:
			draw_rect(Rect2(c[0], Vector2(2, 2)), Llamas.FUEGO[0] if brillo > 0.7 else Llamas.FUEGO[1])
	# las llamas: cada una crece cuando le llega el fuego y se encoge antes de que se apague su trozo
	for m in llamas:
		var k: float = minf(1.0, minf((e - m[5]) / 0.25, (m[6] - e) / 0.5))
		if k > 0.0:
			Llamas.llama(self, m[0], m[1], m[2], m[3], t, m[4], k)
