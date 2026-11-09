# La llamarada del lanzallamas de Johnny (Armas.DATOS.lanzallamas): mientras se ataca, un chorro de fuego fijo que
# sale de la boca del tubo, estrecho, y se abre en cono hasta su alcance (las paredes y los muebles lo cortan).
# Quema a todos los zombis que pilla dentro, uno detrás de otro: cada TICK les quita su parte del daño por segundo y
# los deja ardiendo, y uno de cada EMPUJA pellizcos (cada medio segundo) los empuja un poco. Solo a los zombis: ni a
# Johnny, ni a los que le acompañan, ni deja fuego en el suelo. Al jefe de bomberos no le hace nada (inmune_fuego).
#
# Va de hija de Johnny. Johnny la mantiene encendida llamando a mantener() en cada paso en que echa fuego (johnny.gd,
# echar_fuego); el paso en que no la llama, se apaga sola. Como la bala, la llama "de verdad" va por el suelo (desde
# debajo de la boca) y se dibuja más arriba: sale a la altura de la boca y va bajando hasta el cuerpo de los zombis.
# El dibujo lo hace su shader (escenas/armas/llamarada.gdshader): fuego en pixel art, con las bocanadas y los colores
# (sin humo). Aquí, además, las chispas que saltan, la luz que alumbra alrededor mientras sale (más en los sitios
# oscuros) y el apagado: al soltar, la llama se despega de la boca y se va (CRECE, APAGA). La del lanzallamas, además,
# se va más despacio (APAGA_LLAMA), enfriándose y subiendo; la boquilla escupe chispas y unas gotas ardiendo, de ella
# sale una bocanada de humo y el humo de la punta sigue subiendo un rato (apagar(), HUMO; el shader, "apagado").
#
# El lanza ácido (Armas.DATOS.desintegrador, efecto "acido") echa por aquí su chorro, igual de largo y con el mismo
# cono: lo que cambia es el dibujo (escenas/armas/chorro_acido.gdshader: una vara de ácido a presión, blanca en el centro y
# con borde verde oscuro, que engorda, se rompe en pegotes al final y es más estrecha que el cono que moja),
# el sonido (un siseo de agua a presión), que no alumbra, que en vez de chispas suelta gotitas que caen (y salpican
# contra la pared) y que, en vez de prenderlos, deja a los zombis la herida de ácido (ArmasCreadas.herir). Como no es
# fuego, al jefe de bomberos también le quita vida.
#
# El lanza rayos (Armas.DATOS.pistola_electrica, efecto "rayo") también echa por aquí un chorro continuo, pero de
# electricidad: un rayo celeste en zigzag, más estrecho (ABRE_RAYO), que se dibuja a código (trazar_rayo y dibujar_rayo: no
# usa shader y cambia de forma FORMAS veces por segundo; la "tormenta" de pixelfx, con hebras, nudos que corren, latigazos
# y un halo que suma luz), con su luz celeste y sus chispas. En cada pellizco quita su parte del daño
# por segundo a los zombis que toca y los aturde (ATURDE); y la descarga salta de cada uno al zombi más cercano que
# tenga a menos de "salto" (ArmasCreadas.EFECTOS.descarga), 1 + "saltos" veces (la calidad del arma), que se lleva medio
# daño y también se queda aturdido (los arcos se ven, entre zombi y zombi). Ni empuja ni deja nada en el suelo. Al jefe
# de bomberos también le quita vida (no es fuego).
class_name Llamarada
extends Node2D

const TICK := 0.25          # cada cuánto quita vida a los que están dentro
const EMPUJA := 2           # empuja uno de cada tantos pellizcos (cada medio segundo)
# cuánto se abre el cono a cada lado (22,5°: 45° entre los dos bordes; a 10 casillas, 133 de ancho a cada lado), en
# los dos (el lanza ácido, igual), como se ve. Sale recto por donde apunta el tubo del dibujo, y Johnny solo tiene 8:
# al zombi que queda fuera del cono, el chorro se le gira lo justo para que entre (johnny.gd, echar_fuego)
const ABRE := 0.3927
const BOCA := 6.0           # medio ancho de la llama en la boca
const ALTURA := 50.0        # a qué altura sale de la boca (como la bala)
const ALTURA_CUERPO := 26.0 # y a cuál llega al final
const CRECE := 0.12         # lo que tarda en estirarse hasta su alcance al encenderla
const APAGA := 0.22         # y lo que tarda en irse al apagarla (se despega de la boca y se aleja)
const APAGA_LLAMA := 0.4    # la del lanzallamas, más despacio (se enfría y sube mientras se va)
const APAGA_ACIDO := 0.32   # el ácido, algo más despacio que el rayo: se ve cómo se va deshaciendo (chorro_acido.gdshader)
const HUMO := 0.9           # lo que dura el humo del apagado del lanzallamas (el de la boquilla y el de la punta)
const EMPUJE := 170.0       # empuje base, como el de las balas
const SOMBREADO := preload("res://escenas/armas/llamarada.gdshader")
const SOMBREADO_ACIDO := preload("res://escenas/armas/chorro_acido.gdshader")
const CHISPAS := 22.0       # chispas que saltan por segundo
const GOTAS_FUEGO := 9.0    # el lanzallamas: gotas de gasolina ardiendo que se caen del chorro por segundo
const GOTITAS := 26.0       # el ácido: gotitas que se escapan del final del chorro por segundo (contra la pared, el doble)
const SALPICAN := 40.0      # y gotas que saltan de sus lados por segundo (salpicar)
const VERDES := [Color("#ecf896"), Color("#c7e04a"), Color("#96b430")]   # las del chorro (chorro_acido.gdshader)
const LUZ := Color(1.0, 0.6, 0.28)
# El rayo del lanza rayos
const ABRE_RAYO := 0.1571   # su cono es más estrecho (9° a cada lado)
const ATURDE := 0.5         # lo que aturde cada pellizco (y lo que sigue aturdido el zombi al soltar)
const FORMAS := 18.0        # veces por segundo que cambia el zigzag
const QUIEBRO_RAYO := 0.09  # lo que se aparta del eje (por cada unidad de largo; Relampago.trazar): largo, poco
const RAMAS_RAYO := 0.45    # las ramitas que le salen
# El rayo es la "tormenta" del borrador A hecho con pixelfx (9 nov): además del tronco, dos hebras finas entrelazadas que
# cambian de forma a otro ritmo, nudos de luz que corren por el tronco hacia los zombis, latigazos que saltan a los lados
# y se apagan, y un nudo que chisporrotea en la boca y en cada zombi que toca
const HEBRAS := [[12.0, 0.6], [24.0, 0.45]]   # cada hebra: cuántas formas por segundo, y su fuerza (0..1)
const QUIEBRO_HEBRA := 0.13
const RAMAS_HEBRA := 0.15
const HEROE := 7            # una de cada tantas formas, el tronco da un fogonazo blanco
const NUDOS := 3            # los nudos de luz que corren por el tronco
const NUDOS_VEL := 4.0      # las veces por segundo que lo recorre cada uno
const LATIGAZOS := 5.0      # latigazos por segundo
const VIDA_LATIGAZO := 0.1
const GORDO_HEBRA := [1.0, 0.0, -1.0]   # lo gordo de cada capa (Relampago.pintar_con): las hebras, finas
const GORDO_TRONCO := [1.6, 1.0, 0.0]
const BLANCO := Color(1, 1, 1)
const CELESTES := [Color("#9fe8ff"), Color("#2cf2f0"), Color("#ecffff")]   # las chispas
const LUZ_RAYO := Color(0.45, 0.9, 1.0)
const ATRAS := 2.0          # el dibujo empieza un poquito por detrás de la boca: así sale pegada al tubo

var pedida := false         # se ha pedido fuego en este paso (mantener)
var variante := "llama"     # "llama" (el lanzallamas), "acido" (el lanza ácido) o "rayo" (el lanza rayos): lo dice el arma
var encendida := false
var angulo := 0.0
var alcance := 320.0
var dps := 0.0
var empuje := 0.0
var quema := 1.0
var epica := false          # es de un arma Épica: el zombi que mata revienta (ArmasCreadas.estallido)
var tope := 0.0             # hasta dónde llega, por el suelo: su alcance o la pared
var largo := 0.0            # hasta dónde llega la punta que se ve (crece al encenderla)
var cola := 0.0             # desde dónde se ve (al apagarla se despega de la boca y va hacia la punta)
var luz: PointLight2D
var tick_t := TICK          # (empieza lleno: el primer pellizco, en cuanto sale)
var ticks := 0
var tiempo := 0.0
var apagado := -1.0         # el lanzallamas: cuánto hace que se soltó (para el humo y el enfriado); -1, nada
var largo_humo := 0.0       # y lo larga que era al soltarla (el humo de la punta se queda ahí)
var saltos := 0             # el rayo: a cuántos zombis más salta la descarga, además del primero (la calidad)
var abertura := ABRE        # lo que se abre el cono a cada lado (el del rayo, más estrecho)
var blancos: Array = []     # el rayo: los zombis que toca
var arcos: Array = []       # el rayo: lo que salta de uno a otro, [desde, hasta] (los zombis)
var forma := 0              # el rayo: cuál de sus zigzags (cambia FORMAS veces por segundo)
var latigazos: Array = []   # el rayo: los que están saliendo, {"u" (por dónde del tronco), "a", "l", "t", "semilla"}
var capas: Array = []       # el rayo, ya trazado (trazar_rayo): [caminos, gordo del tronco, de las ramas, colores]
var discos: Array = []      # [centro, radio en píxeles del dibujo, color]
var brillos: Array = []     # la luz que se suma (halo): [centro, radio, color]
var halo: Node2D            # donde se pinta esa luz, sumando
var propio: ShaderMaterial  # el del fuego o el del ácido (el rayo se dibuja sin shader)


# Lo que se abre el cono de un arma a cada lado (Johnny lo usa para girar el chorro hacia el zombi)
static func abre_de(w: Dictionary) -> float:
	return ABRE_RAYO if w.get("efecto", "") == "rayo" else ABRE


func _ready() -> void:
	z_index = 4   # por encima de Johnny y de los zombis
	propio = ShaderMaterial.new()
	propio.shader = SOMBREADO   # (unshaded: el fuego luce por sí mismo)
	material = propio
	luz = PointLight2D.new()
	luz.texture = Luz.TEXTURA
	luz.color = LUZ
	luz.range_item_cull_mask = Luz.TODAS
	add_child(luz)
	# el halo del rayo: luz que se suma a lo que hay debajo y luce por sí misma
	halo = Node2D.new()
	var suma := CanvasItemMaterial.new()
	suma.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	suma.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	halo.material = suma
	halo.draw.connect(dibujar_halo)
	add_child(halo)
	visible = false


# Johnny echa fuego en este paso: "desde", el suelo debajo de la boca; "a", hacia dónde va en la pantalla (por donde
# apunta el tubo del dibujo, o girada lo justo hacia el zombi: sale recta, sin doblarse); "w", su arma (arma())
func mantener(desde: Vector2, a: float, w: Dictionary) -> void:
	pedida = true
	global_position = desde
	alcance = w.alcance
	# por el suelo, la dirección que, con lo que baja de la altura de la boca a la del cuerpo, se ve así: u + baja
	# tiene que ir hacia "a", con u de largo 1
	var eje := Vector2.from_angle(a)
	var baja := Vector2(0, (ALTURA - ALTURA_CUERPO) / alcance)   # lo que baja en la pantalla por cada unidad de suelo
	var e := eje.dot(baja)
	angulo = ((e + sqrt(e * e + 1.0 - baja.length_squared())) * eje - baja).angle()
	dps = w.dano
	empuje = w.empuje
	quema = w.get("quema", 1.0)
	epica = w.get("calidad", 0) >= Armas.EPICA
	saltos = w.get("saltos", 0)
	abertura = abre_de(w)
	var efecto: String = w.get("efecto", "llama")
	if efecto != variante:
		variante = efecto
		# el fuego y el ácido, con su shader; el rayo se dibuja a código, y alumbra de celeste
		material = null if variante == "rayo" else propio
		propio.shader = SOMBREADO_ACIDO if variante == "acido" else SOMBREADO
		luz.color = LUZ_RAYO if variante == "rayo" else LUZ
	# (los efectos de pixelfx de cada uno, preparados para que el primero no pare el juego; solo la primera vez)
	var sala: Node = get_parent().get_parent()
	if variante == "rayo":
		EfectoSuelo.precalentar(sala, "chispazo")
	else:
		var cual := "acido" if variante == "acido" else "fuego"
		EfectoSuelo.precalentar(sala, "chorro-" + cual)
		EfectoSuelo.precalentar(sala, "pared-" + cual)


func _physics_process(delta: float) -> void:
	var antes := encendida
	encendida = pedida
	pedida = false
	tiempo += delta
	forma = floori(tiempo * FORMAS)
	if encendida:
		apagado = -1.0
		tope = medir()
		cola = 0.0
		largo = minf(largo + alcance / CRECE * delta, tope)
		Sonido.tocar({"acido": "chorro_acido", "rayo": "rayo"}.get(variante, "llamarada"))
		if variante == "rayo":
			buscar_blancos()
			if randf() < LATIGAZOS * delta:
				latigazos.append({"u": randf_range(0.15, 0.85), "a": (1.0 if randf() < 0.5 else -1.0) * randf_range(0.6, 1.3),
					"l": randf_range(28.0, 60.0), "t": 0.0, "semilla": randi()})
		# el reloj de los pellizcos solo corre con la llama encendida (soltar y volver a pulsar no quema más deprisa)
		tick_t += delta
		if tick_t >= TICK:
			tick_t -= TICK
			quemar()
		if variante == "acido":
			gotitas(delta)
			salpicar(delta)
		else:
			chispas(delta)
		if variante == "llama":
			gotas_fuego(delta)
	else:
		if antes and variante == "llama" and largo > 20.0:
			apagar()
		if antes and variante == "acido" and largo > 20.0:
			soltar_acido()
		if apagado >= 0.0:
			apagado += delta
			if apagado > HUMO:
				apagado = -1.0
		if largo > 0.0:
			cola += alcance / {"llama": APAGA_LLAMA, "acido": APAGA_ACIDO}.get(variante, APAGA) * delta
			if cola >= largo:
				largo = 0.0
				cola = 0.0
	if not encendida:
		blancos.clear()
		arcos.clear()
	for l in latigazos:
		l.t += delta
	latigazos = latigazos.filter(func(l): return l.t < VIDA_LATIGAZO)
	visible = largo > 0.0 or apagado >= 0.0
	pintar()


# Al soltar el lanzallamas: la boquilla escupe unas chispas y unas gotas de gasolina ardiendo que caen cerca (el humo
# de la boca y el de la punta los pinta el shader mientras corre "apagado")
func apagar() -> void:
	apagado = 0.0
	largo_humo = largo
	var u := Vector2.from_angle(angulo)
	var boca := global_position - Vector2(0, ALTURA)
	for i in 6:
		var hacia := u * randf_range(40.0, 130.0) + Vector2(randf_range(-40.0, 40.0), -randf_range(20.0, 90.0))
		Particulas.soltar(self, boca, hacia, Llamas.FUEGO[randi() % 3], 2.0, randf_range(0.2, 0.45))
	for i in 4:
		var hacia := u * randf_range(15.0, 70.0) + u.orthogonal() * randf_range(-20.0, 20.0)
		Particulas.volar(self, global_position + u * randf_range(0.0, 10.0), ALTURA, hacia, randf_range(0.0, 25.0),
			Llamas.FUEGO[randi() % 3], randf_range(2.0, 3.0))


# Hasta dónde llega la llama por el suelo: su alcance o, si antes hay una pared o un mueble, hasta ahí. Si la boca
# queda al otro lado de una pared (Johnny pegado a ella), nada
func medir() -> float:
	var espacio := get_world_2d().direct_space_state
	var johnny: Node2D = get_parent()
	if not espacio.intersect_ray(PhysicsRayQueryParameters2D.create(johnny.global_position, global_position, 1)).is_empty():
		return 0.0
	var fin := global_position + Vector2.from_angle(angulo) * alcance
	var choque := espacio.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, fin, 1))
	return alcance if choque.is_empty() else global_position.distance_to(choque.position)


# Un pellizco a todos los zombis que están dentro de la llama (y, uno de cada EMPUJA, con empujón). El ácido, en vez
# de prenderlos, les deja la herida de ácido; y al jefe de bomberos sí le hace daño, pero por el golpe (su herir() es
# el de las llamas de los charcos, que no le quita vida), y la herida solo lo tiñe de verde (ArmasCreadas.Herida)
func quemar() -> void:
	ticks += 1
	var johnny: Node2D = get_parent()
	var u := Vector2.from_angle(angulo)
	var empuja := ticks % EMPUJA == 1
	johnny.oir_disparo()   # el fuego se oye: despierta a los que duermen cerca
	if variante == "rayo":
		electrocutar(johnny)
		return
	var sala: Node = johnny.get_parent()
	var cual := "acido" if variante == "acido" else "fuego"
	# contra la pared, donde se corta el chorro (M60): el fuego se aplasta y se abre, el ácido salpica y chorrea
	if tope < alcance - 1.0 and largo >= tope - 1.0:
		EfectoSuelo.soltar(sala, "pared-" + cual, global_position + u * tope)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if not dentro(zombi, johnny, u):
			continue
		# lo que hace el chorro al darle (M59), en el suelo debajo de él (el golpe, a la altura del cuerpo)
		EfectoSuelo.soltar(sala, "chorro-" + cual, zombi.global_position)
		if variante == "acido":
			var da: int = johnny.con_critico(dps * TICK)
			if empuja or zombi.get("inmune_fuego"):
				zombi.recibir_golpe(da, u * EMPUJE * empuje if empuja else Vector2.ZERO)
			else:
				zombi.herir(da, ArmasCreadas.EFECTOS.acido.color)
			ArmasCreadas.herir(zombi, "acido", da)
			if epica and not zombi.is_in_group("zombis"):
				ArmasCreadas.estallido(zombi, "acido", da)
			continue
		if zombi.get("inmune_fuego"):
			zombi.prender()   # al jefe de bomberos el fuego no le hace nada
			continue
		var d: int = johnny.con_critico(dps * TICK)
		if empuja:
			zombi.recibir_golpe(d, u * EMPUJE * empuje)
		else:
			zombi.herir(d, Llamas.FUEGO[2])   # sin empujón ni encogerse, con el número del color del fuego
		ArmasCreadas.prender(zombi, quema)
		if epica and not zombi.is_in_group("zombis"):
			ArmasCreadas.estallido(zombi, "llama", d, quema)


# ¿Está el zombi dentro de la llama? Por el suelo: en el cono que sale de la boca (estrecho en ella, y se abre hasta
# donde llega) o, si está más cerca que la boca (a quemarropa), en la franja entre Johnny y la boca. Y sin una pared
# en medio
func dentro(zombi: Node2D, johnny: Node2D, u: Vector2) -> bool:
	var r: float = zombi.radio
	var p := zombi.global_position - global_position
	var delante := p.dot(u)
	var desde := global_position
	if delante < 0.0:
		var q := zombi.global_position - johnny.global_position
		if q.dot(u) < -r or absf(q.cross(u)) > BOCA * 2.0 + r:
			return false
		desde = johnny.global_position
	elif delante > tope + r or absf(p.cross(u)) > BOCA + delante * abre() + r:
		return false
	var rayo := PhysicsRayQueryParameters2D.create(desde, zombi.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# Lo que se abre el cono a cada lado por cada unidad de largo
func abre() -> float:
	return tan(abertura)


# Chispas que saltan de la llama hacia delante y hacia arriba (Particulas), en sitios al azar de lo largo
func chispas(delta: float) -> void:
	if largo < 20.0 or randf() > CHISPAS * delta:
		return
	var u := Vector2.from_angle(angulo)
	var d := randf_range(0.15, 0.9) * largo
	var donde := global_position + u * d - Vector2(0, lerpf(ALTURA, ALTURA_CUERPO, d / alcance))
	donde += u.orthogonal() * randf_range(-0.6, 0.6) * (BOCA + d * abre())
	var hacia := u * randf_range(60.0, 140.0) + Vector2(randf_range(-20.0, 20.0), -randf_range(40.0, 90.0))
	var colores: Array = CELESTES if variante == "rayo" else Llamas.FUEGO
	Particulas.soltar(self, donde, hacia, colores[randi() % 3], 2.0, randf_range(0.3, 0.6))


# El lanzallamas: gotas de gasolina ardiendo que se caen del chorro (como en el "flamethrower" de pixelfx), de por
# la mitad: siguen un poco hacia delante y caen al suelo, donde se apagan (Particulas.volar, sin marca)
func gotas_fuego(delta: float) -> void:
	if largo < 60.0 or randf() > GOTAS_FUEGO * delta:
		return
	var u := Vector2.from_angle(angulo)
	var d := randf_range(0.2, 0.7) * largo
	var pie := global_position + u * d + u.orthogonal() * randf_range(-0.3, 0.3) * (BOCA + d * abre())
	var hacia := u * randf_range(60.0, 150.0) + u.orthogonal() * randf_range(-25.0, 25.0)
	Particulas.volar(self, pie, lerpf(ALTURA, ALTURA_CUERPO, d / alcance), hacia, randf_range(-10.0, 30.0),
		Llamas.FUEGO[randi() % 3], randf_range(2.0, 3.0))


# El ácido: gotitas que se escapan del final del chorro hacia delante y caen al suelo; contra la pared, el doble, y
# salpican hacia atrás y a los lados (Particulas.volar: caen por su peso y se acaban al llegar al suelo, sin charco)
func gotitas(delta: float) -> void:
	var cortada := tope < alcance - 1.0
	if largo < 20.0 or randf() > GOTITAS * delta * (2.0 if cortada else 1.0):
		return
	var u := Vector2.from_angle(angulo)
	var d := randf_range(0.75, 1.0) * largo
	var pie := global_position + u * d + u.orthogonal() * randf_range(-1.0, 1.0) * ancho_acido(d)
	var hacia := u * (randf_range(-110.0, -30.0) if cortada else randf_range(30.0, 110.0))
	hacia += u.orthogonal() * randf_range(-60.0, 60.0) * (1.6 if cortada else 1.0)
	Particulas.volar(self, pie, lerpf(ALTURA, ALTURA_CUERPO, d / alcance), hacia, randf_range(10.0, 70.0),
		VERDES[randi() % VERDES.size()], 2.0)


# Lo que mide de lado el chorro de ácido que se dibuja a "d" de la boca (chorro_acido.gdshader: 2,6 + 9 píxeles del
# dibujo al final, sin los borbotones ni los grumos), en unidades
func ancho_acido(d: float) -> float:
	return 2.0 * (2.6 + 9.0 * pow(clampf(d / alcance, 0.0, 1.0), 0.9))


# El ácido: gotas que saltan de los lados del chorro, a lo largo de todo él, hacia fuera y hacia delante, y caen al
# suelo (así no se ve quieto); una de cada cuatro, gorda
func salpicar(delta: float) -> void:
	if largo < 30.0 or randf() > SALPICAN * delta:
		return
	var u := Vector2.from_angle(angulo)
	var d := randf_range(0.12, 0.95) * largo
	var lado := 1.0 if randf() < 0.5 else -1.0
	var pie := global_position + u * d + u.orthogonal() * lado * ancho_acido(d)
	var hacia := u * randf_range(40.0, 150.0) + u.orthogonal() * lado * randf_range(50.0, 150.0)
	Particulas.volar(self, pie, lerpf(ALTURA, ALTURA_CUERPO, d / alcance), hacia, randf_range(20.0, 90.0),
		VERDES[randi() % VERDES.size()], 3.0 if randf() < 0.25 else 2.0)


# Al soltar el lanza ácido: la boquilla escupe un último chorrito que cae justo delante (sin la presión, se
# desparrama), y el chorro, al romperse, suelta gotas a lo largo de él que siguen volando hacia delante
func soltar_acido() -> void:
	var u := Vector2.from_angle(angulo)
	for i in 7:
		var hacia := u * randf_range(15.0, 75.0) + u.orthogonal() * randf_range(-25.0, 25.0)
		Particulas.volar(self, global_position + u * randf_range(0.0, 12.0), ALTURA, hacia, randf_range(0.0, 30.0),
			VERDES[randi() % VERDES.size()], 3.0 if i < 2 else 2.0)
	for i in 10:
		var d := randf_range(0.1, 1.0) * largo
		var hacia := u * randf_range(60.0, 160.0) + u.orthogonal() * randf_range(-70.0, 70.0)
		var pie := global_position + u * d + u.orthogonal() * randf_range(-1.0, 1.0) * ancho_acido(d)
		Particulas.volar(self, pie, lerpf(ALTURA, ALTURA_CUERPO, d / alcance), hacia, randf_range(10.0, 60.0),
			VERDES[randi() % VERDES.size()], 2.0)


# Le pasa al shader dónde está la llama y cómo va (en la pantalla: el eje baja un poco, porque la llama baja de la
# altura de la boca a la del cuerpo), pone la luz en medio de la llama y la redibuja (el rayo no usa shader: se dibuja
# a código en _draw)
func pintar() -> void:
	luz.enabled = visible and variante != "acido" and largo > 0.0   # (el ácido no alumbra; el humo tampoco)
	if not visible:
		return
	var u := Vector2.from_angle(angulo)
	var en_pantalla := u + Vector2(0, (ALTURA - ALTURA_CUERPO) / alcance)
	var f := en_pantalla.length()   # lo que mide en la pantalla cada unidad de llama por el suelo
	var eje := en_pantalla / f
	var cortada := tope < alcance - 1.0
	if variante != "rayo":
		var m: ShaderMaterial = material
		m.set_shader_parameter("tiempo", tiempo)
		m.set_shader_parameter("boca", global_position + Vector2(0, -ALTURA) - eje * ATRAS)
		m.set_shader_parameter("eje", eje)
		m.set_shader_parameter("largo", largo * f + ATRAS + (8.0 if cortada else 0.0))   # (que toque la cara de la pared)
		m.set_shader_parameter("cola", cola * f + ATRAS if cola > 0.0 else 0.0)
		m.set_shader_parameter("alcance", alcance * f + ATRAS)
		m.set_shader_parameter("cortada", 1.0 if cortada else 0.0)
		if variante == "llama":
			m.set_shader_parameter("apagado", apagado)
			m.set_shader_parameter("largo_humo", largo_humo * f + ATRAS)
	# la luz: en medio de lo que se ve, tan grande como la llama, y temblando
	var medio := (cola + largo) / 2.0
	luz.position = Vector2(0, -ALTURA) + eje * medio * f
	luz.texture_scale = ((largo - cola) * 0.6 + 80.0) / 128.0
	if variante == "rayo":
		luz.energy = 1.1 * Luz.fuerza() * randf_range(0.65, 1.0)   # el rayo parpadea
		trazar_rayo(eje, f)
		halo.queue_redraw()
	else:
		luz.energy = 1.4 * Luz.fuerza() * (0.85 + 0.15 * sin(tiempo * 23.0) * sin(tiempo * 7.0))
		if not brillos.is_empty():   # (venía del lanza rayos)
			brillos.clear()
			halo.queue_redraw()
	queue_redraw()


# Un rectángulo que cubre la llama entera (con sitio para que ondule y se abra): lo demás lo pinta el shader. El rayo
# se dibuja a código (dibujar_rayo)
func _draw() -> void:
	if not visible:
		return
	var u := Vector2.from_angle(angulo)
	var en_pantalla := u + Vector2(0, (ALTURA - ALTURA_CUERPO) / alcance)
	var eje := en_pantalla.normalized()
	if variante == "rayo":
		dibujar_rayo()
		return
	var lado := eje.orthogonal() * 240.0
	var boca := Vector2(0, -ALTURA)
	var desde := boca - eje * (ATRAS + 60.0)   # (el humo de la boquilla sube, aunque la llama vaya hacia abajo)
	var hasta := boca + eje * (maxf(largo, largo_humo if apagado >= 0.0 else 0.0) * 1.1 + 90.0)   # (y el de la punta)
	Formas.poligono(self, PackedVector2Array([desde + lado, hasta + lado, hasta - lado, desde - lado]), Color.WHITE)


# ── El rayo del lanza rayos ──

# Los zombis que toca el rayo (en su cono estrecho, sin paredes en medio) y a los que salta la descarga: de cada uno,
# al más cercano que tenga a menos de "salto" y aún no esté pillado, y de ese al siguiente, 1 + "saltos" veces. Se mira
# en cada paso (para dibujar los arcos); el daño va a pellizcos (electrocutar)
func buscar_blancos() -> void:
	blancos.clear()
	arcos.clear()
	var johnny: Node2D = get_parent()
	var u := Vector2.from_angle(angulo)
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if dentro(zombi, johnny, u):
			blancos.append(zombi)
	var pillados: Array = blancos.duplicate()
	for zombi in blancos:
		var desde: Node2D = zombi
		for vez in 1 + saltos:
			var otro := mas_cercano(desde, pillados)
			if otro == null:
				break
			arcos.append([desde, otro])
			pillados.append(otro)
			desde = otro


# El zombi más cercano a "desde" (a menos de lo que salta la descarga, y sin una pared en medio) que no esté en "menos"
func mas_cercano(desde: Node2D, menos: Array) -> Node2D:
	var otro: Node2D = null
	var mejor: float = ArmasCreadas.EFECTOS.descarga.salto
	var espacio := get_world_2d().direct_space_state
	for o in get_tree().get_nodes_in_group("zombis"):
		var d: float = o.global_position.distance_to(desde.global_position)
		if o in menos or d >= mejor:
			continue
		if not espacio.intersect_ray(PhysicsRayQueryParameters2D.create(desde.global_position, o.global_position, 1)).is_empty():
			continue
		mejor = d
		otro = o
	return otro


# Un pellizco de electricidad: su parte del daño por segundo a los zombis que toca, y medio daño a los que salta la
# descarga, y a todos los deja aturdidos. Sin empujón
func electrocutar(johnny: Node2D) -> void:
	for zombi in blancos:
		golpe_de_rayo(zombi, johnny, 1.0)
	for arco in arcos:
		golpe_de_rayo(arco[1], johnny, ArmasCreadas.EFECTOS.descarga.dano)


func golpe_de_rayo(zombi: Node2D, johnny: Node2D, parte: float) -> void:
	if not is_instance_valid(zombi) or not zombi.is_inside_tree():
		return
	var d: int = johnny.con_critico(dps * TICK * parte)
	if zombi.get("inmune_fuego"):
		zombi.recibir_golpe(d, Vector2.ZERO)   # (el herir() del jefe de bomberos es el del fuego: no le quita vida)
	else:
		zombi.herir(d, CELESTES[0])
	ArmasCreadas.aturdir(zombi, ATURDE)
	# el chispazo de pixelfx (M50; EfectoSuelo): en el suelo, con el golpe a la altura del cuerpo
	var pie: Vector2 = zombi.global_position + Vector2(0, ArmasCreadas.ALTURA_CHISPAZO - ALTURA_CUERPO)
	EfectoSuelo.soltar(zombi.get_parent(), "chispazo", pie)
	if epica and not zombi.is_in_group("zombis"):
		ArmasCreadas.estallido(zombi, "chispa", d)


# El rayo, trazado en cada paso (pintar) para que _draw y el halo pinten lo mismo: del labio de la boca (si se acaba,
# se despega y se va: cola) hasta donde llega, unos rayitos donde choca con la pared y los arcos que saltan de un zombi
# a otro. Se traza y se entinta como los relámpagos (Relampago.trazar y pintar_con: zigzag partido por la mitad con
# ramas, borde, cuerpo y centro de un píxel), con el mismo "rng" mientras dura cada forma (que no tiemble a cada
# fotograma). Encima, lo del borrador A de pixelfx: las hebras, el fogonazo blanco del tronco una de cada HEROE formas,
# los nudos que corren por él, los latigazos y el nudo que chisporrotea en la boca y en cada zombi
func trazar_rayo(eje: Vector2, f: float) -> void:
	capas.clear()
	discos.clear()
	brillos.clear()
	var boca := Vector2(0, -ALTURA)
	var cortada := tope < alcance - 1.0
	var desde := boca + eje * (cola * f)
	var hasta := boca + eje * (largo * f + (8.0 if cortada else 0.0))
	var fuerte := cola <= 0.0
	var colores := [Relampago.BORDE, Relampago.CUERPO, Relampago.CENTRO]
	# las hebras, por detrás, cada una a su ritmo y con su fuerza (más flojas, más transparentes)
	for i in HEBRAS.size():
		var rng := RandomNumberGenerator.new()
		rng.seed = floori(tiempo * HEBRAS[i][0]) * 7919 + 17 * (i + 1)
		var hebra := []
		Relampago.trazar(hebra, rng, desde, hasta, QUIEBRO_HEBRA, RAMAS_HEBRA)
		var k: float = HEBRAS[i][1] + 0.25 * rng.randf()
		capas.append([hebra, GORDO_HEBRA if fuerte else [0.0, -1.0, -1.0], [0.0, -1.0, -1.0] if fuerte else [],
			colores.map(func(c): return Color(c, k))])
	# el tronco (con un fogonazo blanco de vez en cuando)
	var rng := RandomNumberGenerator.new()
	rng.seed = forma * 7919 + 1
	var tronco := []
	Relampago.trazar(tronco, rng, desde, hasta, QUIEBRO_RAYO, RAMAS_RAYO)
	if cortada and largo > 0.0 and fuerte:
		for i in 4:
			Relampago.trazar(tronco, rng, hasta, hasta + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10.0, 22.0), 0.3, 0.0, 0.55, 2)
	var heroe := forma % HEROE == 0
	capas.append([tronco, Relampago.GORDO.fuerte if fuerte else Relampago.GORDO.flojo, Relampago.GORDO.rama if fuerte else [],
		[Relampago.CUERPO, Relampago.CENTRO, BLANCO] if heroe else colores])
	var puntos: Array = tronco[0][0]
	for i in range(0, puntos.size(), 3):
		brillos.append([puntos[i], 18.0, Relampago.CUERPO * Color(1, 1, 1, 0.1)])
	if not fuerte:
		return
	# los nudos de luz que corren por el tronco
	for j in NUDOS:
		var u := fposmod(tiempo * NUDOS_VEL + float(j) / NUDOS, 1.0)
		var p: Vector2 = puntos[floori(u * (puntos.size() - 1))]
		discos.append([p, 2.4, Relampago.CENTRO])
		discos.append([p, 1.2, BLANCO])
		brillos.append([p, 16.0, Relampago.CUERPO * Color(1, 1, 1, 0.35)])
	# los latigazos: una rama que sale del tronco, vive unos fotogramas y se va
	var lado := eje.angle()
	for l in latigazos:
		var p: Vector2 = puntos[floori(l.u * (puntos.size() - 1))]
		var rl := RandomNumberGenerator.new()
		rl.seed = l.semilla
		var latigo := []
		Relampago.trazar(latigo, rl, p, p + Vector2.from_angle(lado + l.a) * l.l, 0.3, 0.6)
		var k: float = 1.0 - l.t / VIDA_LATIGAZO
		capas.append([latigo, GORDO_HEBRA if k > 0.5 else [0.0, -1.0, -1.0], [0.0, -1.0, -1.0] if k > 0.5 else [], colores])
	# la boca, los zombis que toca y los arcos que saltan de uno a otro (con un nudo más pequeño en el que recibe)
	nudo(boca, 4.0, 3, 1)
	brillos.append([boca, 24.0, Relampago.CUERPO * Color(1, 1, 1, 0.3)])
	for zombi in blancos:
		if is_instance_valid(zombi):
			nudo(to_local(zombi.global_position) - Vector2(0, ALTURA_CUERPO), 8.0, 6, zombi.get_instance_id())
	for arco in arcos:
		if not is_instance_valid(arco[0]) or not is_instance_valid(arco[1]):
			continue
		var a: Vector2 = to_local(arco[0].global_position) - Vector2(0, ALTURA_CUERPO)
		var b: Vector2 = to_local(arco[1].global_position) - Vector2(0, ALTURA_CUERPO)
		var salto := []
		Relampago.trazar(salto, rng, a, b)
		capas.append([salto, GORDO_TRONCO, Relampago.GORDO.rama, colores])
		nudo(b, 5.0, 4, arco[1].get_instance_id())


# Un nudo que chisporrotea en "c" (de radio "r", en píxeles del dibujo): "n" zigzags cortitos a todos lados, que
# cambian el doble de deprisa que el tronco, y una bola que late, blanca por dentro, con su luz
func nudo(c: Vector2, r: float, n: int, sal: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = floori(tiempo * FORMAS * 2.0) * 7919 + sal
	var chispazos := []
	for i in n:
		Relampago.trazar(chispazos, rng, c, c + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(r, r * 2.8), 0.4, 0.0)
	capas.append([chispazos, GORDO_HEBRA, [], [Relampago.BORDE, Relampago.CUERPO, Relampago.CENTRO]])
	var late := 0.75 + 0.25 * rng.randf()
	discos.append([c, (r * 0.45 + 1.0) * late, Relampago.CUERPO])
	discos.append([c, (r * 0.3 + 0.8) * late, Relampago.CENTRO])
	discos.append([c, r * 0.15 + 0.6, BLANCO])
	brillos.append([c, (r * 2.0 + 4.0) * 2.0, Relampago.CUERPO * Color(1, 1, 1, 0.35 * late)])
	brillos.append([c, (r + 2.0) * 2.0, BLANCO * Color(1, 1, 1, 0.25)])


func dibujar_rayo() -> void:
	for c in capas:
		Relampago.pintar_con(self, c[0], c[1], c[2], c[3], global_position)
	for d in discos:
		Relampago.disco(self, d[0], d[1], d[2], global_position)


# El halo del rayo (sumando luz): una mancha suave en cada sitio de "brillos"
func dibujar_halo() -> void:
	for b in brillos:
		var r: float = b[1]
		halo.draw_texture_rect(Luz.TEXTURA, Rect2(b[0] - Vector2(r, r), Vector2(r, r) * 2.0), false, b[2])
