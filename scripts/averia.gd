# El rescate propio del técnico del centro comercial (docs/CENTRO_COMERCIAL.md, «Supervivientes»). Está encerrado
# en el almacén de la tienda de electrónica, la del agua con corriente (peligros/agua.gd). Al unirse no se quiere
# ir sin arreglar el cable pelado, pero con corriente no lo puede tocar: Johnny tiene que bajar la palanca del
# cuadro eléctrico (peligros/cuadro.gd) y la tienda se queda a oscuras. Entonces se pone a arreglarlo, de espaldas,
# donde el cable sale de la pared (aliado.gd: "forzando", como el que fuerza la cerradura), la puerta de la tienda
# se cierra y van entrando zombis por las habitaciones, cada vez más: hay que aguantar a oscuras (solo con la
# linterna) mientras trabaja. Si Johnny vuelve a subir la palanca, vuelve la luz y el agua da calambres a los
# zombis que la pisen, pero él deja de trabajar hasta que se baje otra vez. Si lo tumban, como en la horda.
# Al acabar, el cable queda arreglado: el agua de esa tienda ya no da calambres nunca más.
#
# Lo monta supervivientes.gd: empezar() al unirse él al equipo y dibujar() en su capa de la pantalla. partida.gd
# pregunta no_cruzar() antes de cruzar una puerta. Si su tienda no tuviera agua, no empieza y sale la horda de
# siempre. Los números son provisionales.
class_name Averia
extends Node

const DURA := 90.0          # segundos de trabajo (no cuentan con corriente, ni caído, ni yendo a su sitio)
const TOPE := 24            # zombis a la vez, como mucho (la tienda es pequeña y está a oscuras)
const CADA := [6.0, 3.5]    # segundos entre grupo y grupo, al principio y al final
const GRUPO := [2, 5]       # zombis por grupo, igual
const TIPOS := [["lento", "normal", "normal", "dependienta"],
	["normal", "rapido", "rapido", "vigilante", "dependienta", "explosivo"]]   # el primer minuto y luego
const FRASES := [
	[0.02, "¡Bien, sin corriente! Cúbreme mientras lo arreglo"],
	[0.15, "Este empalme está hecho polvo…"],
	[0.32, "No veo nada… ¡no dejes que se me acerquen!"],
	[0.5, "¡Toma, esto estaba en el almacén!"],
	[0.65, "Pelo el cable, lo uno… vale"],
	[0.8, "Ya solo falta la cinta aislante…"],
	[0.92, "¡Un poco más!"],
]
const QUEJAS := ["¡Eh, que hay corriente! ¡Baja la palanca!", "¡Así no puedo! ¡Quita la corriente!",
	"¡Que me electrocuto! ¡La palanca!"]

var sup: Supervivientes
var el: Aliado = null       # el técnico mientras dura su rescate (null: no hay)
var fase := ""              # "palanca" (esperando a que Johnny baje la palanca) o "arreglando"
var datos: Dictionary       # el agua con corriente de su tienda (peligros.gd): "corriente" y "arreglado"
var hecho := 0.0            # lo que lleva de trabajo
var grupo_t := 0.0
var frase_i := 0
var levantando := 0.0
var queja_t := 0.0
var cuenta := false         # ya ha sonado el aviso de los últimos 10 segundos
var lampara: PointLight2D   # la lucecita con la que trabaja a oscuras
var chispa_t := 0.0
var tiempo := 0.0


func activa() -> bool:
	return el != null


# Se le ha unido en el almacén: si su tienda tiene el agua con corriente, empieza lo suyo (si no, la horda de siempre)
func empezar(a: Aliado) -> bool:
	var partida: Node = sup.partida
	datos = {}
	for d in partida.planta.sitios[partida.aqui].get("peligros", []):
		if d.tipo == "agua" and not d.get("arreglado", false):
			datos = d
	if datos.is_empty():
		return false
	el = a
	fase = "palanca"
	hecho = 0.0
	frase_i = 0
	levantando = 0.0
	queja_t = 0.0
	cuenta = false
	if datos.corriente:
		a.decir("Con corriente no puedo tocarlo. ¡Baja la palanca del cuadro!")
		partida.decir("Baja la palanca del cuadro eléctrico para que el %s arregle el cable" % a.def.nombre, 4.0)
	return true


func _physics_process(delta: float) -> void:
	tiempo += delta
	var partida: Node = sup.partida if sup else null
	if el == null or partida == null or partida.mapa == null or partida.cambiando:
		return
	if not is_instance_valid(el) or not el in sup.equipo:
		el = null
		return
	if fase == "palanca":
		if not datos.corriente:
			empezar_arreglo()
		return
	var johnny: Node2D = sup.johnny
	var a := el
	if a.caido:
		# caído: Johnny lo levanta quedándose a su lado
		if johnny.vivo and johnny.position.distance_to(a.position) < 60.0:
			levantando += delta
		else:
			levantando = maxf(0.0, levantando - delta * 2.0)
		a.levantar = levantando / Supervivientes.HORDA.levantar
		if levantando >= Supervivientes.HORDA.levantar:
			levantando = 0.0
			a.levantarse()
			a.decir("¡Gracias! Sigo con el cable")
			Particulas.anillo(a, a.global_position, 50.0, Tema.VERDE, 0.4)
	elif datos.corriente:
		# han vuelto a subir la palanca: así no puede trabajar
		queja_t -= delta
		if queja_t <= 0.0:
			queja_t = 6.0
			a.decir(QUEJAS.pick_random())
	elif a.en_su_sitio():
		hecho = minf(DURA, hecho + delta)
		queja_t = 0.0
		# trabajando: chispitas en el empalme de vez en cuando
		chispa_t -= delta
		if chispa_t <= 0.0:
			chispa_t = randf_range(0.3, 0.9)
			for i in 3:
				Particulas.soltar(a, a.global_position + Vector2(randf_range(-6, 6), -40), Vector2(randf_range(-60, 60),
					randf_range(-70, 10)), Color.WHITE if i % 2 else Color("#ffd27a"), 2, 0.2)
	lampara.enabled = not a.caido
	var k := hecho / DURA
	while frase_i < FRASES.size() and k >= FRASES[frase_i][0]:
		var frase: Array = FRASES[frase_i]
		frase_i += 1
		a.decir(frase[1])
		if frase[0] == 0.5:
			sup.soltar_provisiones(a)
	if not a.caido and DURA - hecho <= 10.0 and not cuenta:
		cuenta = true
		Sonido.tocar("jefe")
	# los grupos de zombis, por las habitaciones de la tienda
	grupo_t -= delta
	if grupo_t <= 0.0 and DURA - hecho > 3.0:
		grupo_t = lerpf(CADA[0], CADA[1], k)
		var n := mini(roundi(lerpf(GRUPO[0], GRUPO[1], k)), TOPE - get_tree().get_nodes_in_group("zombis").size())
		if n > 0:
			sup.grupo(n, TIPOS[0 if hecho < 60.0 else 1])
	if hecho >= DURA:
		acabar()


# Ya no hay corriente: se va a donde el cable sale de la pared y se pone a arreglarlo. Se cierra la puerta
func empezar_arreglo() -> void:
	var partida: Node = sup.partida
	var a := el
	fase = "arreglando"
	grupo_t = 3.0
	a.sitio_forzar = datos.cable_desde + Vector2(0, 22)
	a.mira_forzar = Vector2.UP
	a.forzando = true
	a.vida = Aliado.VIDA
	a.caido = false
	a.add_to_group("presa")
	# su lucecita de trabajo, para que se le vea a oscuras
	lampara = PointLight2D.new()
	lampara.name = "Lampara"
	lampara.texture = preload("res://escenas/luces/luz_suave.tres")
	lampara.texture_scale = 120.0 / 128.0
	lampara.color = Color("#ffe2a8")
	lampara.energy = 0.9
	lampara.position = Vector2(0, -30)
	lampara.range_item_cull_mask = Luz.CAPA_SUELO | Luz.CAPA_COSAS | Luz.capa_sala(0)
	a.add_child(lampara)
	Sonido.musica("jefe")   # la música más tensa, como en la horda
	partida.cerrada = true
	partida.actualizar_puertas()
	Sonido.tocar("portazo")
	partida.decir("¡Se ha cerrado la puerta! Aguanta a oscuras mientras el %s arregla el cable" % a.def.nombre, 4.0)


# Cable arreglado: el agua ya no da calambres, se abre la puerta y él sigue en el equipo como los demás
func acabar() -> void:
	var partida: Node = sup.partida
	var a := el
	el = null
	fase = ""
	datos.arreglado = true
	for p in partida.mapa.peligros:
		if p.datos.tipo == "agua":
			p.arreglar()
	a.forzando = false
	a.levantar = 0.0
	a.remove_from_group("presa")
	if is_instance_valid(lampara):
		lampara.queue_free()
	if not sup.rescate.is_empty():
		sup.rescate.horda_hecha = true   # ya no hay horda para él
	partida.logros.cumplir("buen_vecino")
	partida.cerrada = false
	partida.actualizar_puertas()
	Sonido.musica("menu")
	a.decir("¡Arreglado! Ya puedes dar la luz")
	partida.decir("¡El %s ha arreglado el cable! El agua ya no da calambres" % a.def.nombre, 3.5)
	Sonido.tocar("limpio")
	get_tree().create_timer(0.25, false).timeout.connect(Sonido.tocar.bind("puerta"))
	Particulas.anillo(a, a.global_position, 50.0, a.def.color, 0.5)


# Le han dado: si se ha caído, lo dice; si Johnny anda lejos, se queja (como mucho cada 6 s)
func al_herir(cae: bool) -> void:
	if fase != "arreglando":
		return
	if cae:
		levantando = 0.0
		el.decir("¡Ayúdame, no puedo levantarme!")
	elif sup.johnny.position.distance_to(el.position) > Supervivientes.HORDA.lejos and el.dicho_t > 6.0:
		el.decir(["¡Johnny, vuelve!", "¡No me dejes aquí!", "¡Que me comen!"].pick_random())


# Antes de cruzar una puerta: lo que dice si no se puede, o "" si sí
func no_cruzar() -> String:
	if el == null:
		return ""
	if fase == "palanca":
		return "El %s no se va sin arreglar el cable: baja la palanca del cuadro" % el.def.nombre
	return "Aguanta: el %s está arreglando el cable" % el.def.nombre


# El cuadro eléctrico de la tienda (su nodo), o null
func cuadro() -> Node2D:
	for p in sup.partida.mapa.peligros:
		if p.datos.tipo == "agua":
			return p.cuadro
	return null


# En la pantalla: antes, el letrero de la palanca; arreglando, la barra con la cuenta atrás (como la horda). Y,
# mientras haya corriente, la flecha en el borde hacia el cuadro
func dibujar(capa: Control) -> void:
	if el == null:
		return
	var a := el
	var letra := Tema.FUENTE
	var tam := capa.size
	var y := 18.0
	var texto := ""
	var color := Color("#f2e6c0")
	if fase == "palanca":
		texto = "Baja la palanca del cuadro eléctrico"
		var ancho := letra.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 40.0
		var caja := Rect2((tam.x - ancho) / 2.0, 12, ancho, 30)
		capa.draw_rect(caja.grow(2), Tema.LINEA)
		capa.draw_rect(caja, Color(0.11, 0.1, 0.17, 0.9))
		capa.draw_string_outline(letra, Vector2(0, 33), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, 4, Tema.LINEA)
		capa.draw_string(letra, Vector2(0, 33), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, color)
	else:
		var falta := ceili(DURA - hecho)
		var ancho := minf(360.0, tam.x - 260.0)
		var x := (tam.x - ancho) / 2.0
		capa.draw_rect(Rect2(x - 8, y - 8, ancho + 16, 44), Tema.LINEA)
		capa.draw_rect(Rect2(x - 6, y - 6, ancho + 12, 40), Color(0.11, 0.1, 0.17, 0.9))
		capa.draw_rect(Rect2(x, y + 16, ancho, 10), Color("#22303a"))
		var parpadeo := int(tiempo * 6.0) % 2 == 0
		var relleno := Color("#4fe3ff")
		if a.caido:
			relleno = Color("#ff2d4b") if parpadeo else Color("#7a2030")
			texto = "¡El %s ha caído!" % a.def.nombre
			color = Color("#ff8a8a")
		elif datos.corriente:
			relleno = Color("#ffd23f") if parpadeo else Color("#7a6420")
			texto = "¡Hay corriente! Baja la palanca"
			color = Color("#ffd23f")
		else:
			texto = "El %s arregla el cable · %d:%02d" % [a.def.nombre, falta / 60, falta % 60]
		capa.draw_rect(Rect2(x, y + 16, ancho * hecho / DURA, 10), relleno)
		capa.draw_rect(Rect2(x, y + 16, ancho, 10), Tema.LINEA, false, 2.0)
		capa.draw_string_outline(letra, Vector2(0, y + 9), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, 4, Tema.LINEA)
		capa.draw_string(letra, Vector2(0, y + 9), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, color)
		# los últimos diez segundos, en grande y latiendo
		if falta <= 10 and not a.caido and not datos.corriente:
			var grande := 64 if fmod(hecho, 1.0) < 0.5 else 72
			capa.draw_string_outline(letra, Vector2(0, 150), str(falta), HORIZONTAL_ALIGNMENT_CENTER, tam.x, grande, 10, Tema.LINEA)
			capa.draw_string(letra, Vector2(0, 150), str(falta), HORIZONTAL_ALIGNMENT_CENTER, tam.x, grande, Tema.AMARILLO)
	var c := cuadro()
	if c and datos.corriente:
		sup.flecha(c.global_position + Vector2(0, -50), a.def.color, false)


# ═════════════ Para probar ═════════════

# Con --captura --edificio centro (lo llama supervivientes.gd): el técnico en su almacén; al unirse, el letrero de
# la palanca (captura-tecnico-palanca.png) y que no deja salir; bajar la palanca y la horda a oscuras
# (captura-tecnico-horda.png); subirla (se para); tumbarlo y levantarlo; acabar, y que el agua ya no da calambres
# (captura-tecnico-fin.png). Luego su mejora: el minimapa con los zombis (captura-tecnico-minimapa.png) y las
# pantallas en su habitación de las viviendas (captura-tecnico-sala.png). Se deja el equipo y el guardado como estaban
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
	await sup.probar_aqui(false, "tecnico")
	await get_tree().create_timer(0.8, false).timeout   # se limpia la tienda y se abre el almacén
	var npc: Aliado = sup.npc
	if npc:
		johnny.position = npc.position + Vector2(0, 30)
		await get_tree().create_timer(0.3, false).timeout
	if el == null:
		print("Técnico: no ha empezado (%s)" % [sup.rescate.get("def", {}).get("nombre", "nadie")])
		dejar(antes)
		return
	var a := el
	var c := cuadro()
	print("Técnico: %s en el equipo %s | fase %s | corriente %s | dice '%s'" % [a.def.nombre, a in sup.equipo, fase,
		datos.corriente, a.dicho])
	# lejos del cuadro, para que se vea la flecha
	johnny.position = datos.cable_desde + Vector2(0, 90)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.6, false).timeout
	Captura.foto("captura-tecnico-palanca.png")
	# sin bajar la palanca, la puerta no deja salir
	partida.cruzar(0)
	print("Técnico: salir sin bajar la palanca: '%s'" % partida.aviso.text)
	# bajar la palanca: plantarse delante del cuadro
	johnny.position = Vector2(c.datos.x, c.datos.y + 30)
	await get_tree().create_timer(0.3, false).timeout
	print("Técnico: palanca bajada | corriente %s | fase %s | puerta %s" % [datos.corriente, fase,
		"cerrada" if partida.cerrada else "abierta"])
	partida.cruzar(0)
	print("Técnico: salir arreglando: '%s'" % partida.aviso.text)
	a.position = a.sitio_forzar
	johnny.position = a.sitio_forzar + Vector2(60, 50)
	johnny.get_node("Camara").reset_smoothing()
	grupo_t = 0.0
	await get_tree().create_timer(0.1, false).timeout
	grupo_t = 0.0
	await get_tree().create_timer(2.0, false).timeout
	print("Técnico: arreglando %.1f s | en su sitio %s | zombis %d | dice '%s'" % [hecho, a.en_su_sitio(),
		get_tree().get_nodes_in_group("zombis").size(), a.dicho])
	Captura.foto("captura-tecnico-horda.png")
	# subir la palanca: vuelve la luz y se para
	johnny.position = Vector2(c.datos.x, c.datos.y + 200)
	await get_tree().create_timer(0.1, false).timeout
	johnny.position = Vector2(c.datos.x, c.datos.y + 30)
	await get_tree().create_timer(0.1, false).timeout
	var parado := hecho
	await get_tree().create_timer(1.0, false).timeout
	print("Técnico: palanca subida | corriente %s | trabajo parado %s | dice '%s'" % [datos.corriente,
		is_equal_approx(parado, hecho), a.dicho])
	johnny.position = Vector2(c.datos.x, c.datos.y + 200)
	await get_tree().create_timer(0.1, false).timeout
	johnny.position = Vector2(c.datos.x, c.datos.y + 30)
	await get_tree().create_timer(0.1, false).timeout
	# tumbado: Johnny lo levanta
	sup.escolta.matar_zombis()
	a.inv_t = 0.0
	a.recibir_dano(500)
	print("Técnico: caído %s | corriente %s" % [a.caido, datos.corriente])
	johnny.position = a.position + Vector2(30, 0)
	await get_tree().create_timer(2.3, false).timeout
	print("Técnico: levantado %s | vida %d" % [not a.caido, a.vida])
	# a mitad suelta lo suyo, y al final se acaba
	hecho = DURA * 0.49
	await get_tree().create_timer(0.3, false).timeout
	hecho = DURA - 0.2
	await get_tree().create_timer(0.5, false).timeout
	print("Técnico: acabado %s | arreglado %s | puerta %s | sigue en el equipo %s | dice '%s'" % [not activa(),
		datos.get("arreglado", false), "cerrada" if partida.cerrada else "abierta", a in sup.equipo, a.dicho])
	sup.escolta.matar_zombis()
	# dar la luz: el agua ya no da calambres (su cuenta hasta el siguiente no avanza)
	johnny.position = Vector2(c.datos.x, c.datos.y + 200)
	await get_tree().create_timer(0.1, false).timeout
	johnny.position = Vector2(c.datos.x, c.datos.y + 30)
	await get_tree().create_timer(0.1, false).timeout
	johnny.position = Peligros.centro(datos.casillas[0]) + Vector2(0, 120)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(2.6, false).timeout
	print("Técnico: con luz otra vez %s | calambrazos del agua: %s" % [datos.corriente,
		"no" if c.agua.pulso == 0.0 else "sí"])
	Captura.foto("captura-tecnico-fin.png")
	sup.escolta.matar_zombis()
	sup.equipo.erase(a)
	a.queue_free()
	await probar_mejora()
	dejar(antes)


# Su mejora: con el técnico rescatado, el minimapa enseña los zombis (en el pasillo, unos cuantos de prueba, y en
# las tiendas sin visitar) y en su habitación de las viviendas están sus pantallas. Se deja el guardado como estaba
func probar_mejora() -> void:
	var partida: Node = sup.partida
	var johnny: Node2D = sup.johnny
	var minimapa: Node = partida.get_node("Pantalla/Minimapa")
	var g := Guardado.cargar()
	var antes := [g.rescatados.duplicate(), g.acompanante]
	Guardado.cambiar(func(x):
		x.rescatados = ["tecnico"]
		x.acompanante = "")
	minimapa.camaras = true
	partida.nueva_planta(2)
	await partida.montar(0, 0, false)
	for i in 5:
		partida.meter_zombi("lento", johnny.position + Vector2(160 + i * 90, 70 * (i % 2)))
	await get_tree().create_timer(0.4, false).timeout
	print("Cámaras: zombis en el minimapa %s" % [minimapa.zombis_por_sala()])
	Captura.foto("captura-tecnico-minimapa.png")
	sup.escolta.matar_zombis()
	partida.nueva_planta(1)   # las viviendas están en la planta baja
	await partida.montar(partida.planta.viviendas, 0, false)
	# en el pasillo, lejos del técnico, que no diga «¿Te acompaño?» encima de las pantallas
	johnny.position = Vector2(Viviendas.casa("tecnico").x, (Viviendas.PASILLO_F + 2) * Planta.CASILLA)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.4, false).timeout
	var camaras: Node2D = partida.mapa.cosas.get_node_or_null("Camaras")
	print("Cámaras: pantallas en su habitación %s, en «%s» (esperado: true, Técnico)" % [camaras != null,
		partida.mapa.nombre_zona(partida.mapa.zona_en(camaras.position)) if camaras else "-"])
	Captura.foto("captura-tecnico-sala.png")
	minimapa.camaras = "tecnico" in antes[0]
	Guardado.cambiar(func(x):
		x.rescatados = antes[0]
		x.acompanante = antes[1])


func dejar(antes: Array) -> void:
	el = null
	fase = ""
	sup.equipo = antes
	for a in antes:
		sup.partida.mapa.cosas.add_child(a)
		a.position = sup.johnny.position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
