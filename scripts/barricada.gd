# El rescate propio del ferretero del centro comercial (docs/historial/CENTRO_COMERCIAL.md, «Supervivientes»). Se ha
# atrincherado en el almacén de la ferretería: la puerta tiene tablas clavadas (mapa/puerta_bano.gd: "tablas").
# Al limpiar la tienda no se abre: él se pone a quitar la barricada desde dentro y, mientras tanto, la horda de
# siempre, más corta (2 minutos): la entrada de la tienda se cierra de golpe y van entrando zombis, cada vez más.
# A él no le pueden tumbar (está dentro): lo que hay que defender es la barricada. Los zombis que pillan más cerca
# la puerta que a Johnny, o todos si Johnny se aleja, van a aporrearla; y mientras haya alguno pegado a ella, él
# no avanza (la barra se pone roja). Las tablas van cayendo según avanza y, a mitad, pasa por debajo de la puerta
# un molotov, una granada y dos cajas de munición. Al acabar se abren su puerta y la entrada, se une al arrimarse
# (como siempre) y ya no hay otra horda al salir con él.
#
# Lo monta supervivientes.gd: dibujar() en su capa de la pantalla. Empieza solo, al quedarse limpia la tienda con
# la puerta aún cerrada. Él no se ve (está dentro, a oscuras): lo que dice sale encima de la puerta, como sus
# gritos. Los números son provisionales.
class_name Barricada
extends Node

const DURA := 120.0        # segundos de trabajo para quitar la barricada (no cuentan mientras empujan la puerta)
const TABLAS := 4          # las que tiene clavadas la puerta
const PEGADO := 70.0       # un zombi a menos de esto de la puerta la está empujando: él no avanza
const ESPERA := 1.2        # desde que se limpia la tienda hasta que se cierra la entrada
const CADA := [6.0, 3.0]   # segundos entre grupo y grupo, al principio y al final
const GRUPO := [2, 5]      # zombis por grupo, igual
const TOPE := 30           # zombis a la vez, como mucho
const TIPOS := [["lento", "normal", "normal"], ["normal", "normal", "rapido", "rapido", "explosivo", "lento"]]
const COLOR := Color("#ffc58a")   # lo que dice, encima de la puerta
# Lo que va diciendo según lo que lleva (de 0 a 1); con 0.5 pasa las provisiones por debajo de la puerta. En español;
# sale con Idioma.t
# [traducir]
const FRASES := [
	[0.1, "¡Cuántos clavos le metí!"],
	[0.25, "¡Una tabla menos!"],
	[0.38, "Esta tabla no sale…"],
	[0.5, "¡Toma, te lo paso por debajo!"],
	[0.65, "¡Otra fuera!"],
	[0.8, "Ya casi está…"],
	[0.92, "¡La última tabla!"],
]
const EMPUJAN := ["¡Me están empujando la puerta!", "¡Quítamelos de la puerta!", "¡Así no puedo, Johnny!"]
# [/traducir]


# Lo que aporrean los zombis: un punto invisible delante de la puerta, por fuera. Para ellos es como el
# superviviente de la horda (zombi.gd: objetivo), pero no se cae: cada zarpazo solo hace temblar la puerta
class Diana extends Node2D:
	const RADIO := 20.0
	var vivo := true
	var barricada: Barricada

	# ("_quien", el zombi que pega: solo lo mira Johnny, para la skin del glotón)
	func recibir_dano(_cantidad: int, _quien = null) -> void:
		barricada.golpe()

	# ¿Va este zombi a por la puerta en vez de a por Johnny? Si la pilla más cerca, o si Johnny se ha alejado
	func presa_de(z: Node2D, jugador: Node2D, lejos: float) -> bool:
		var dp := z.global_position.distance_to(jugador.global_position)
		var da := z.global_position.distance_to(global_position)
		return da < dp * 0.8 or jugador.global_position.distance_to(global_position) > lejos


var sup: Supervivientes
var diana: Diana = null    # mientras dura la barricada (null: no hay barricada)
var mapa: Node2D = null    # el de la ferretería, para saber si Johnny se ha ido (en las pruebas)
var espera := 0.0          # desde que se ha limpiado la tienda
var avisado := false       # ya ha dicho que va a quitar la barricada
var hecho := 0.0           # segundos de trabajo que lleva
var grupo_t := 0.0
var frase_i := 0
var empujan := false       # hay algún zombi pegado a la puerta
var queja_t := 0.0
var martillo_t := 0.0
var cuenta := false        # ya ha sonado el aviso de los últimos 10 segundos
var tiempo := 0.0
var dicho_t := -9.0        # cuándo ha dicho algo por última vez (para no pisarse las frases)


func activa() -> bool:
	return diana != null


func _physics_process(delta: float) -> void:
	var partida: Node = sup.partida if sup else null
	if partida == null or partida.mapa == null or partida.cambiando:
		return
	tiempo += delta
	if diana == null:
		esperar(delta)
		return
	if partida.mapa != mapa or not is_instance_valid(diana):
		cancelar()   # Johnny ya no está en la ferretería (solo pasa en las pruebas)
		return
	var puerta: Node2D = sup.puerta
	var k := hecho / DURA
	# ¿hay algún zombi pegado a la puerta? Entonces no avanza
	empujan = get_tree().get_nodes_in_group("zombis").any(func(z):
		return z.get("estado") != "muerto" and z.global_position.distance_to(diana.global_position) < PEGADO)
	queja_t -= delta
	if empujan:
		if queja_t <= 0.0 and tiempo - dicho_t > 2.6:
			queja_t = 5.0
			decir(Idioma.t(EMPUJAN.pick_random()))
	elif sup.johnny.vivo:
		hecho = minf(DURA, hecho + delta)
		# se le oye trabajar: un golpe de martillo o un tirón de vez en cuando
		martillo_t -= delta
		if martillo_t <= 0.0:
			martillo_t = randf_range(1.2, 2.2)
			Sonido.tocar("palanca")
			puerta.golpes = 0.12
	# las tablas caen según avanza
	var quedan := ceili((1.0 - hecho / DURA) * TABLAS - 0.001)
	if quedan < puerta.tablas:
		puerta.tablas = quedan
		Sonido.tocar("porrazo")
		puerta.golpes = 0.3
		for i in 10:
			Particulas.soltar(puerta, diana.global_position + Vector2(randf_range(-30, 30), -40),
				Vector2(randf_range(-90, 90), randf_range(-140, -40)), Color("#a0703f"), 4.0, 0.6)
	var frase := ""   # (si avanza de golpe, solo la última)
	while frase_i < FRASES.size() and k >= FRASES[frase_i][0]:
		frase = Idioma.t(FRASES[frase_i][1])
		if FRASES[frase_i][0] == 0.5:
			soltar_provisiones()
		frase_i += 1
	if frase != "":
		decir(frase)
	# los últimos 10 segundos: aviso
	if DURA - hecho <= 10.0 and not cuenta:
		cuenta = true
		Sonido.tocar("jefe")
	# los grupos de zombis
	grupo_t -= delta
	if grupo_t <= 0.0 and DURA - hecho > 3.0:
		grupo_t = lerpf(CADA[0], CADA[1], k)
		grupo(roundi(lerpf(GRUPO[0], GRUPO[1], k)), TIPOS[0] if hecho < 50.0 else TIPOS[1])
	if hecho >= DURA:
		acabar()


# Antes de empezar: la tienda se queda limpia con la puerta del almacén aún cerrada. Él avisa y, al poco, se
# cierra la entrada de golpe
func esperar(delta: float) -> void:
	var r: Dictionary = sup.rescate
	var partida: Node = sup.partida
	if r.is_empty() or r.def.get("rescate", "") != "barricada" or r.horda_hecha or not sup.encerrado() \
			or sup.puerta == null or partida.aqui != partida.planta.superviviente.sitio \
			or not partida.planta.sitios[partida.aqui].limpio or not sup.johnny.vivo:
		espera = 0.0
		avisado = false
		return
	espera += delta
	if not avisado and espera >= 0.3:
		avisado = true
		decir(Idioma.t("¡Espera, que quito la barricada!"))
	if espera >= ESPERA:
		empezar()


func empezar() -> void:
	var partida: Node = sup.partida
	mapa = partida.mapa
	hecho = 0.0
	grupo_t = 3.0
	frase_i = 0
	queja_t = 0.0
	martillo_t = 1.0
	cuenta = false
	empujan = false
	diana = Diana.new()
	diana.barricada = self
	diana.position = delante()
	diana.add_to_group("presa")
	partida.mapa.cosas.add_child(diana)
	sup.puerta.tablas = TABLAS
	Sonido.musica("jefe")   # la música más tensa, como en la horda
	Sonido.tocar("portazo")
	partida.cerrada = true
	partida.actualizar_puertas()
	partida.decir(Idioma.t("¡La entrada se ha cerrado! Defiende la puerta mientras el %s quita la barricada") %
		Idioma.t(sup.rescate.def.nombre), 4.0)


# Por fuera de la puerta del almacén, a un paso: donde aporrean los zombis y donde caen las provisiones
func delante() -> Vector2:
	var puerta: Node2D = sup.puerta
	var centro: Vector2 = puerta.caja.get_center()
	var dentro: Vector2 = sup.partida.planta.superviviente.pos
	var fuera := Vector2(0, signf(centro.y - dentro.y)) if puerta.de_frente else Vector2(signf(centro.x - dentro.x), 0)
	var medio: float = (puerta.caja.size.y if puerta.de_frente else puerta.caja.size.x) / 2.0
	return centro + fuera * (medio + 20.0)


# Un zarpazo a la puerta: tiembla
func golpe() -> void:
	if sup.puerta:
		sup.puerta.golpes = 0.25
	Sonido.tocar("golpe")


# Lo que dice desde dentro, encima de la puerta (como sus gritos)
func decir(texto: String) -> void:
	var puerta: Node2D = sup.puerta
	if puerta == null or sup.partida.aqui != sup.partida.planta.superviviente.sitio:
		return
	dicho_t = tiempo
	sup.texto_flotante(puerta.position + Vector2(0, -110), texto, COLOR, 18, 2.6)


# A mitad: un molotov, una granada y dos cajas de munición, por debajo de la puerta
func soltar_provisiones() -> void:
	var donde := delante()
	sup.partida.soltar_lanzable("molotov", donde + Vector2(-34, 10))
	sup.partida.soltar_lanzable("granada", donde + Vector2(34, 10))
	sup.partida.soltar_municion(donde + Vector2(-12, 24))
	sup.partida.soltar_municion(donde + Vector2(12, 24))


# Un grupo de zombis entra por una habitación de la tienda donde no está Johnny (nunca el almacén, donde está
# él) o por la entrada, y él avisa de por dónde
func grupo(n: int, tipos: Array) -> void:
	var partida: Node = sup.partida
	n = mini(n, TOPE - get_tree().get_nodes_in_group("zombis").size())
	if n <= 0:
		return
	var sitio: Dictionary = partida.planta.sitios[partida.aqui]
	var apt: Dictionary = sitio.apt
	var aqui: int = partida.mapa.zona_en(sup.johnny.position)
	var suya: int = partida.planta.superviviente.sala
	var salas: Array = apt.salas.filter(func(s): return s.id != suya and s.id != aqui and s.uso != "bano")
	var entrada: Node2D = partida.mapa.puertas[0]
	var por_la_entrada: bool = sup.johnny.position.distance_to(entrada.llegada()) > 220.0 \
		and (salas.is_empty() or randf() < 0.4)
	var puestos := 0
	var por := ""
	if por_la_entrada:
		for i in n:
			partida.meter_zombi(tipos.pick_random(), entrada.llegada() + Vector2(randf_range(-24, 24), randf_range(-24, 24)))
		puestos = n
		por = Idioma.t("la entrada")
	elif not salas.is_empty():
		var sala: Dictionary = salas.pick_random()
		for i in 120:
			if puestos >= n:
				break
			var pos := Vector2((sala.c0 + randf() * sala.ancho) * Planta.CASILLA, (sala.f0 + randf() * sala.fondo) * Planta.CASILLA)
			if not Planta.despejado(apt, pos, 24.0, sala.id) or pos.distance_to(sup.johnny.position) < 180.0:
				continue
			if not Planta.lejos_de_muebles(sitio, pos, 30.0):
				continue
			partida.meter_zombi(tipos.pick_random(), pos)
			puestos += 1
		por = Idioma.t(Supervivientes.POR.get(sala.uso, ""))
	if puestos > 0 and por != "" and randf() < 0.4 and tiempo - dicho_t > 2.6:
		decir(Idioma.t("¡Vienen por %s!") % por)


# Barricada fuera: se abren su puerta y la entrada. Él se une al arrimarse, como siempre (supervivientes.gd)
func acabar() -> void:
	var partida: Node = sup.partida
	quitar_diana()
	sup.rescate.horda_hecha = true   # al salir con él ya no hay otra horda
	partida.logros.cumplir("buen_vecino")
	Sonido.musica("menu")
	partida.cerrada = false
	partida.actualizar_puertas()
	partida.decir(Idioma.t("¡Barricada fuera! La entrada se ha abierto"), 3.0)
	Sonido.tocar("limpio")
	sup.abrir_escondite(partida.aqui)


func cancelar() -> void:
	quitar_diana()
	espera = 0.0
	avisado = false


func quitar_diana() -> void:
	if is_instance_valid(diana):
		diana.queue_free()
	diana = null


# En la pantalla: arriba, la barra de la barricada y la cuenta atrás (roja mientras empujan la puerta)
func dibujar(capa: Control) -> void:
	if diana == null:
		return
	var letra := Tema.FUENTE
	var tam := capa.size
	var ancho := minf(360.0, tam.x - 260.0)
	var x := (tam.x - ancho) / 2.0
	var y := 18.0
	var falta := ceili(DURA - hecho)
	capa.draw_rect(Rect2(x - 8, y - 8, ancho + 16, 44), Tema.LINEA)
	capa.draw_rect(Rect2(x - 6, y - 6, ancho + 12, 40), Color(0.11, 0.1, 0.17, 0.9))
	capa.draw_rect(Rect2(x, y + 16, ancho, 10), Color("#3a2f22"))
	var relleno := (Color("#ff2d4b") if int(tiempo * 6.0) % 2 else Color("#7a2030")) if empujan else Color("#e0b030")
	capa.draw_rect(Rect2(x, y + 16, ancho * hecho / DURA, 10), relleno)
	capa.draw_rect(Rect2(x, y + 16, ancho, 10), Tema.LINEA, false, 2.0)
	var nombre: String = sup.rescate.def.nombre
	var texto := Idioma.t("¡Están empujando la puerta! Quítaselos") if empujan \
		else Idioma.t("%s quita la barricada · %d:%02d") % [Idioma.t(nombre), falta / 60, falta % 60]
	capa.draw_string_outline(letra, Vector2(0, y + 9), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, 4, Tema.LINEA)
	capa.draw_string(letra, Vector2(0, y + 9), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16,
		Color("#ff8a8a") if empujan else Color("#f2e6c0"))
	# los últimos diez segundos, en grande y latiendo
	if falta <= 10 and not empujan:
		var grande := 64 if fmod(hecho, 1.0) < 0.5 else 72
		capa.draw_string_outline(letra, Vector2(0, 150), str(falta), HORIZONTAL_ALIGNMENT_CENTER, tam.x, grande, 10, Tema.LINEA)
		capa.draw_string(letra, Vector2(0, 150), str(falta), HORIZONTAL_ALIGNMENT_CENTER, tam.x, grande, Tema.AMARILLO)


# Con --captura --edificio centro (lo llama supervivientes.gd): el ferretero en su almacén con la barricada; al
# limpiar la tienda, que se cierra la entrada; a mitad, las provisiones y la foto con los zombis
# (captura-ferretero-barricada.png); un zombi pegado a la puerta para el trabajo; y, al acabar, la puerta abierta,
# que se une y que al salir ya no hay horda. Luego, el equipo como estaba
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
	await sup.probar_aqui(false, "ferretero")
	await get_tree().create_timer(0.1, false).timeout
	print("Barricada: %s en la tienda | tablas %d | puerta cerrada %s" % [sup.rescate.def.nombre,
		sup.puerta.tablas if sup.puerta else -1, sup.encerrado()])
	await get_tree().create_timer(ESPERA + 0.4, false).timeout
	print("Barricada: empieza %s | entrada %s" % [activa(), "cerrada" if partida.cerrada else "abierta"])
	if not activa():
		dejar(antes)
		return
	# a mitad: las provisiones, las tablas que quedan y un grupo de zombis (Johnny, por fuera, delante de la puerta)
	var fuera: Vector2 = (diana.position - sup.puerta.caja.get_center()).normalized()
	johnny.position = diana.position + fuera * 125.0 + Vector2(50, 0)
	johnny.get_node("Camara").reset_smoothing()
	hecho = DURA * 0.5 - 0.2
	grupo_t = 0.4
	await get_tree().create_timer(1.2, false).timeout
	print("Barricada a %d s: tablas %d | zombis %d | provisiones en el suelo %d (esperado: de 1 a 4, el molotov, la granada y 2 cajas de munición menos las que ya haya cogido Johnny)" % [int(hecho), sup.puerta.tablas,
		get_tree().get_nodes_in_group("zombis").size(), partida.mapa.cosas.get_children().filter(
		func(n): return n.get("icono") in sup.iconos_lanzables() or n.is_in_group("cajas_municion")).size()])
	Captura.foto("captura-ferretero-barricada.png")
	# un zombi pegado a la puerta: no avanza
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().process_frame
	var pegados := [partida.meter_zombi("lento", diana.position + fuera * 20.0 + Vector2(30, 0)),
		partida.meter_zombi("normal", diana.position + fuera * 30.0 + Vector2(-40, 0))]
	johnny.position = diana.position + fuera * 200.0
	var parado := hecho
	await get_tree().create_timer(0.8, false).timeout
	print("Barricada: con zombis en la puerta, empujan %s | avanza %.1f s | van a por la puerta %d" % [empujan,
		hecho - parado, pegados.filter(func(z): return is_instance_valid(z) and z.objetivo() == diana).size()])
	Captura.foto("captura-ferretero-empujan.png")
	for z in pegados:
		if is_instance_valid(z):
			z.queue_free()
	await get_tree().process_frame
	# al acabar
	grupo_t = 99.0
	hecho = DURA - 0.3
	await get_tree().create_timer(1.2, false).timeout
	print("Barricada: fin %s | tablas %d | entrada %s | almacén cerrado %s" % [not activa(), sup.puerta.tablas,
		"cerrada" if partida.cerrada else "abierta", sup.encerrado()])
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var npc: Aliado = sup.npc
	if npc:
		johnny.position = npc.position + Vector2(0, 30)
		await get_tree().create_timer(0.3, false).timeout
	var a: Aliado = sup.rescate.get("amigo")
	print("Barricada: en el equipo %s | dice '%s'" % [a != null and a in sup.equipo, a.dicho if a else ""])
	# al ir a salir con él, ya no hay horda
	johnny.position = partida.mapa.puertas[0].llegada()
	await get_tree().create_timer(0.3, false).timeout
	print("Barricada: al salir, horda %s | entrada %s" % [sup.en_horda(), "cerrada" if partida.cerrada else "abierta"])
	if a:
		sup.equipo.erase(a)
		a.queue_free()
	dejar(antes)


func dejar(antes: Array) -> void:
	cancelar()
	sup.equipo = antes
	for a in antes:
		sup.partida.mapa.cosas.add_child(a)
		a.position = sup.johnny.position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
