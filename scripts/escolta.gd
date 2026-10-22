# El rescate propio de la farmacéutica del centro comercial (docs/CENTRO_COMERCIAL.md, «Supervivientes»). Está
# herida en la rebotica de la farmacia y, en vez de la horda de siempre, hay que llevarla hasta la puerta de las
# escaleras de su planta. Va detrás de Johnny, cojeando (aliado.gd: "herida"), y mientras tanto van saliendo
# zombis: un grupo entra en la farmacia al poco de unirse ella y, en el pasillo, salen por las puertas de las
# tiendas que quedan lejos de Johnny, cada vez más. Si Johnny se aleja de ella, van a por ella; si la tumban, hay
# que quedarse a su lado para levantarla (como en la horda). Johnny no puede cruzar una puerta dejándola atrás.
# Al llegar con ella a las escaleras (aunque sigan cerradas) se venda la pierna y sigue en el equipo, como los demás.
#
# Lo monta supervivientes.gd: empezar() al unirse ella al equipo y dibujar() en su capa de la pantalla. partida.gd
# pregunta no_cruzar() antes de cruzar una puerta. Los números son provisionales.
class_name Escolta
extends Node

const VELOCIDAD := 90.0    # lo que anda herida (Johnny anda a 210)
const LLEGA := 160.0       # a qué distancia de la puerta de las escaleras ya está a salvo
const LEJOS := 140.0       # si está más lejos de Johnny que esto, no le deja cruzar una puerta
const PRIMERO := 3         # los zombis que entran en la farmacia al poco de unirse ella
const CADA := [6.0, 3.0]   # segundos entre grupo y grupo en el pasillo: al principio y al cabo de un minuto
const GRUPO := [1, 3]      # zombis por grupo, igual
const TOPE := 14           # zombis a la vez, como mucho
const TIPOS := [["lento", "normal", "normal"], ["normal", "normal", "rapido", "venenoso"]]
const QUEJAS := ["Me duele mucho la pierna…", "¡No vayas tan deprisa!", "¡No me dejes atrás!", "¿Falta mucho?",
	"Tengo que vendarme esto…"]

var sup: Supervivientes
var ella: Aliado = null    # la farmacéutica mientras dura la escolta (null: no hay escolta)
var t := 0.0               # lo que lleva de escolta
var grupo_t := 0.0         # lo que falta para el siguiente grupo del pasillo
var primero := false       # ya ha entrado el grupo de la farmacia
var levantando := 0.0
var queja_t := 0.0
var planta_num := 0


func activa() -> bool:
	return ella != null


# Se le ha unido en la rebotica: empieza la escolta
func empezar(a: Aliado) -> void:
	ella = a
	t = 0.0
	grupo_t = CADA[0]
	primero = false
	levantando = 0.0
	queja_t = 8.0
	planta_num = sup.partida.planta.num
	a.herida = true
	a.vida = Aliado.VIDA
	a.caido = false
	a.add_to_group("presa")
	a.decir("Vámonos. Despacio, por favor")
	Sonido.musica("jefe")   # la música más tensa, como en la horda
	sup.partida.decir("Lleva a la %s hasta las escaleras: va herida" % a.def.nombre, 4.0)


func _physics_process(delta: float) -> void:
	var partida: Node = sup.partida if sup else null
	if ella == null or partida == null or partida.mapa == null or partida.cambiando:
		return
	if not is_instance_valid(ella) or not ella in sup.equipo:
		ella = null
		return
	if partida.planta.num != planta_num:
		acabar(false)   # ha subido con ella: también vale
		return
	t += delta
	var johnny: Node2D = sup.johnny
	if ella.caido:
		# caída: Johnny la levanta quedándose a su lado
		if johnny.vivo and johnny.position.distance_to(ella.position) < 60.0:
			levantando += delta
		else:
			levantando = maxf(0.0, levantando - delta * 2.0)
		ella.levantar = levantando / Supervivientes.HORDA.levantar
		if levantando >= Supervivientes.HORDA.levantar:
			levantando = 0.0
			ella.levantarse()
			ella.decir("Gracias… sigamos")
			Particulas.anillo(ella, ella.global_position, 50.0, Tema.VERDE, 0.4)
	# de vez en cuando se queja
	queja_t -= delta
	if queja_t <= 0.0:
		queja_t = randf_range(8.0, 12.0)
		if not ella.caido and ella.dicho_t > 3.0:
			ella.decir(QUEJAS.pick_random())
	# el primer grupo entra por la puerta de la farmacia
	if not primero and t >= 2.0:
		primero = true
		if partida.aqui == sup.rescate.get("sitio", -1):
			salir_zombis([partida.mapa.puertas[0]], PRIMERO, TIPOS[0])
	if partida.aqui != 0:
		return
	# en el pasillo: los grupos salen por las puertas de las tiendas, y al llegar a las escaleras se acaba
	var k := minf(1.0, t / 60.0)
	grupo_t -= delta
	if grupo_t <= 0.0:
		grupo_t = lerpf(CADA[0], CADA[1], k)
		var puertas := []   # las de las tiendas, lejos de los dos
		for p in partida.mapa.puertas:
			if p.salida.tipo == "puerta" and p.position.distance_to(johnny.position) > 380.0 \
					and p.position.distance_to(ella.position) > 260.0:
				puertas.append(p)
		salir_zombis(puertas, roundi(lerpf(GRUPO[0], GRUPO[1], k)), TIPOS[1] if k > 0.4 else TIPOS[0])
	var escaleras: Node2D = partida.mapa.puertas[partida.puerta_de_tipo("escaleras")]
	if not ella.caido and ella.position.distance_to(escaleras.position) < LLEGA:
		acabar(true)


# "n" zombis salen por una de esas puertas (al azar), delante de ella, sin pasar del tope
func salir_zombis(puertas: Array, n: int, tipos: Array) -> void:
	n = mini(n, TOPE - get_tree().get_nodes_in_group("zombis").size())
	if n <= 0 or puertas.is_empty():
		return
	var puerta: Node2D = puertas.pick_random()
	for i in n:
		sup.partida.meter_zombi(tipos.pick_random(), puerta.llegada() + Vector2(randf_range(-24, 24), randf_range(-24, 24)))


# Le han dado: si se ha caído, lo dice; si Johnny anda lejos, se queja (como mucho cada 6 s)
func al_herir(cae: bool) -> void:
	if cae:
		levantando = 0.0
		ella.decir("¡Ayúdame, no puedo levantarme!")
	elif sup.johnny.position.distance_to(ella.position) > Supervivientes.HORDA.lejos and queja_t > 6.0:
		queja_t = 6.0
		ella.decir(["¡Johnny, vuelve!", "¡No me dejes aquí!", "¡Que me comen!"].pick_random())


# Antes de cruzar una puerta: lo que dice si no se puede (en el suelo o lejos), o "" si sí
func no_cruzar() -> String:
	if ella == null:
		return ""
	if ella.caido:
		return "¡La %s está en el suelo! Quédate a su lado para levantarla" % ella.def.nombre
	if sup.johnny.position.distance_to(ella.position) > LEJOS:
		return "Espera a la %s: va herida" % ella.def.nombre
	return ""


# A salvo en las escaleras: se venda la pierna y sigue en el equipo como los demás
func acabar(llego: bool) -> void:
	var a := ella
	ella = null
	a.herida = false
	a.caido = false
	a.levantar = 0.0
	a.vida = Aliado.VIDA
	a.remove_from_group("presa")
	if not sup.rescate.is_empty():
		sup.rescate.horda_hecha = true   # ya no hay horda para ella
	sup.partida.logros.cumplir("buen_vecino")
	Sonido.musica("explorar")
	if not llego:
		return
	a.decir("Aquí ya estamos a salvo. Me vendo la pierna y sigo contigo")
	sup.partida.decir("¡La %s está a salvo!" % a.def.nombre, 3.0)
	Sonido.tocar("limpio")
	Particulas.anillo(a, a.global_position, 50.0, a.def.color, 0.5)


# En la pantalla: arriba, a quién hay que llevar adónde (o que ha caído) y, en el borde, la flecha hacia las
# escaleras (en el pasillo) o hacia la salida (dentro de una tienda)
func dibujar(capa: Control) -> void:
	if ella == null:
		return
	var partida: Node = sup.partida
	var letra := Tema.FUENTE
	var tam := capa.size
	var texto := ("¡La %s ha caído! Quédate a su lado" if ella.caido else "Lleva a la %s a las escaleras") % ella.def.nombre
	var ancho := letra.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 40.0
	var caja := Rect2((tam.x - ancho) / 2.0, 12, ancho, 30)
	capa.draw_rect(caja.grow(2), Tema.LINEA)
	capa.draw_rect(caja, Color(0.11, 0.1, 0.17, 0.9))
	capa.draw_string_outline(letra, Vector2(0, 33), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, 4, Tema.LINEA)
	capa.draw_string(letra, Vector2(0, 33), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16,
		Color("#ff8a8a") if ella.caido else Color("#f2e6c0"))
	var hacia: Vector2 = partida.mapa.puertas[partida.puerta_de_tipo("escaleras")].position if partida.aqui == 0 \
		else partida.mapa.puertas[0].position
	sup.flecha(hacia, ella.def.color, false)


# Con --captura --edificio centro (lo llama supervivientes.gd): la farmacéutica en su rebotica; al unirse, el grupo
# que entra en la farmacia; que no deja salir sin ella; en el pasillo, la foto con zombis saliendo
# (captura-escolta.png); tumbarla y levantarla; y llegar con ella a las escaleras. Luego, el equipo como estaba
func probar() -> void:
	var partida: Node = sup.partida
	if partida.edificio != "centro":
		return
	var johnny: Node2D = sup.johnny
	var antes: Array = sup.equipo
	for a in antes:
		if a.get_parent():
			a.get_parent().remove_child(a)
	sup.equipo = []
	sup.rescate = {}
	await sup.probar_aqui(false, "farmaceutica")
	await get_tree().create_timer(0.8, false).timeout   # se limpia la farmacia y se abre la rebotica
	var npc: Aliado = sup.npc
	if npc:
		johnny.position = npc.position + Vector2(0, 30)
		await get_tree().create_timer(0.3, false).timeout
	if ella == null:
		print("Escolta: no ha empezado (%s)" % [sup.rescate.get("def", {}).get("nombre", "nadie")])
		dejar(antes)
		return
	var a := ella
	print("Escolta: %s en el equipo %s | herida %s | dice '%s'" % [a.def.nombre, a in sup.equipo, a.herida, a.dicho])
	await get_tree().create_timer(2.0, false).timeout
	print("Escolta: zombis en la farmacia %d" % get_tree().get_nodes_in_group("zombis").size())
	matar_zombis()
	# sin ella al lado, la puerta no deja salir
	johnny.position = partida.mapa.puertas[0].llegada()
	a.position = johnny.position + Vector2(0, -200)
	partida.cruzar(0)
	print("Escolta: salir sin ella: '%s'" % partida.aviso.text)
	a.position = johnny.position + Vector2(24, 0)
	partida.cruzar(0)
	await get_tree().create_timer(1.0, false).timeout
	print("Escolta: en el pasillo %s | a %d de Johnny" % [partida.aqui == 0, a.position.distance_to(johnny.position)])
	grupo_t = 0.0
	await get_tree().create_timer(0.1, false).timeout
	grupo_t = 0.0
	a.position = johnny.position + Vector2(-70, 10)   # a su lado, que se vea en la foto
	await get_tree().create_timer(1.4, false).timeout
	print("Escolta: zombis en el pasillo %d | van a por ella %d" % [get_tree().get_nodes_in_group("zombis").size(),
		get_tree().get_nodes_in_group("zombis").filter(func(z): return z.objetivo() == a).size()])
	Captura.foto("captura-escolta.png")
	# tumbada: no deja cruzar, y Johnny la levanta
	matar_zombis()
	a.inv_t = 0.0
	a.recibir_dano(500)
	print("Escolta: caída %s | al cruzar: '%s'" % [a.caido, no_cruzar()])
	johnny.position = a.position + Vector2(30, 0)
	await get_tree().create_timer(2.3, false).timeout
	print("Escolta: levantada %s | vida %d" % [not a.caido, a.vida])
	# a las escaleras
	var escaleras: Node2D = partida.mapa.puertas[partida.puerta_de_tipo("escaleras")]
	johnny.position = escaleras.llegada()
	a.position = escaleras.llegada() + Vector2(-40, 0)
	await get_tree().create_timer(0.3, false).timeout
	print("Escolta: a salvo %s | herida %s | sigue en el equipo %s | dice '%s'" % [not activa(), a.herida,
		a in sup.equipo, a.dicho])
	matar_zombis()
	sup.equipo.erase(a)
	a.queue_free()
	dejar(antes)


func matar_zombis() -> void:
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()


func dejar(antes: Array) -> void:
	ella = null
	sup.equipo = antes
	for a in antes:
		sup.partida.mapa.cosas.add_child(a)
		a.position = sup.johnny.position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
