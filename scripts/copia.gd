# El rescate propio del informático joven de Torre Velaria (docs/PLAN_TERCER_EDIFICIO.md, «Los supervivientes»; el
# que hacía las prácticas con el becario). Está encerrado en la sala de servidores de Informática. Al unirse no se
# quiere ir sin llevarse los archivos de Velaria: se pone delante de los armarios de servidores, de espaldas, a
# copiarlos (aliado.gd: "forzando", como el que fuerza la cerradura), la puerta del departamento se cierra y van
# entrando zombis por las habitaciones, cada vez más. Hay que protegerle DURA segundos. Y cada ALARMA segundos el
# programa de copia hace saltar una de las cámaras de seguridad de la sala grande (peligros/camaras.gd): se despiertan
# todos y, la primera vez que llama esa cámara, llegan escoltas por la puerta. Las cámaras rotas de un disparo ya no
# saltan: romperlas antes ahorra sustos. Si lo tumban, como en la horda (no avanza hasta que Johnny lo levanta).
#
# Lo monta supervivientes.gd: empezar() al unirse él al equipo y dibujar() en su capa de la pantalla. partida.gd
# pregunta no_cruzar() antes de cruzar una puerta. Los números son provisionales.
class_name Copia
extends Node

const DURA := 60.0          # segundos de copia (no cuentan caído ni yendo a su sitio)
const TOPE := 50            # zombis a la vez, como mucho
const CADA := [3.2, 1.6]    # segundos entre grupo y grupo, al principio y al final
const GRUPO := [3, 8]       # zombis por grupo, igual
const ALARMA := 15.0        # cada cuánto hace saltar una cámara
const TIPOS := [["lento", "normal", "normal", "oficinista"],
	["normal", "rapido", "oficinista", "oficinista", "explosivo"]]   # la primera mitad y la segunda
# Lo que dice (en español; sale con Idioma.t)
# [traducir]
const FRASES := [
	[0.02, "Me llevo los archivos de Velaria. ¡Cúbreme mientras se copian!"],
	[0.15, "Cuatro mil carpetas… ¿quién guarda tanto?"],
	[0.3, "¡Ay! El programa de copia ha hecho saltar las cámaras"],
	[0.5, "¡Toma, esto estaba en el armario de los cables!"],
	[0.65, "«Proyecto Sujeto 1»… esto no pinta bien"],
	[0.8, "Copiando lo último…"],
	[0.92, "¡Un poco más!"],
]
const LLAMADAS := ["¡Johnny, vuelve!", "¡No me dejes aquí!", "¡Que me comen!"]   # cuando le dan y Johnny anda lejos
# [/traducir]

var sup: Supervivientes
var el: Aliado = null       # el informático mientras dura su rescate (null: no hay)
var hecho := 0.0            # lo que lleva copiado (segundos)
var grupo_t := 0.0
var alarma_t := 0.0
var frase_i := 0
var levantando := 0.0
var cuenta := false         # ya ha sonado el aviso de los últimos 10 segundos
var chispa_t := 0.0
var tiempo := 0.0


func activa() -> bool:
	return el != null


# Se le ha unido en la sala de servidores: se pone a copiar ahí mismo, de cara a los armarios de la pared
func empezar(a: Aliado) -> void:
	var partida: Node = sup.partida
	el = a
	hecho = 0.0
	frase_i = 0
	levantando = 0.0
	cuenta = false
	grupo_t = 3.0
	alarma_t = ALARMA * 0.3
	a.sitio_forzar = partida.planta.superviviente.pos
	a.mira_forzar = Vector2.UP
	a.forzando = true
	a.vida = Aliado.VIDA
	a.caido = false
	a.add_to_group("presa")
	Sonido.musica("horda")   # la música de pelea, como en la horda
	partida.cerrada = true
	partida.actualizar_puertas()
	Sonido.tocar("portazo")
	partida.decir(Idioma.t("¡Se ha cerrado la puerta! Protege al %s mientras copia los archivos") % Idioma.t(a.def.nombre), 4.0)


func _physics_process(delta: float) -> void:
	tiempo += delta
	var partida: Node = sup.partida if sup else null
	if el == null or partida == null or partida.mapa == null or partida.cambiando:
		return
	if not is_instance_valid(el) or not el in sup.equipo:
		el = null
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
			a.decir(Idioma.t("¡Gracias! Sigo copiando"))
			Particulas.anillo(a, a.global_position, 50.0, Tema.VERDE, 0.4)
	elif a.en_su_sitio():
		hecho = minf(DURA, hecho + delta)
		# copiando: lucecitas moradas que suben del portátil de vez en cuando
		chispa_t -= delta
		if chispa_t <= 0.0:
			chispa_t = randf_range(0.25, 0.6)
			Particulas.soltar(a, a.global_position + Vector2(randf_range(-10, 10), -30), Vector2(randf_range(-20, 20),
				randf_range(-70, -40)), a.def.color if randi() % 2 else Color("#bff4ff"), 2, 0.35)
	var k := hecho / DURA
	while frase_i < FRASES.size() and k >= FRASES[frase_i][0]:
		var frase: Array = FRASES[frase_i]
		frase_i += 1
		a.decir(Idioma.t(frase[1]))
		if frase[0] == 0.5:
			sup.soltar_provisiones(a)
	if not a.caido and DURA - hecho <= 10.0 and not cuenta:
		cuenta = true
		Sonido.tocar("jefe")
	# las cámaras: cada ALARMA segundos salta una de las que sigan enteras
	alarma_t -= delta
	if alarma_t <= 0.0 and DURA - hecho > 5.0:
		alarma_t = ALARMA
		saltar_camara()
	# los grupos de zombis, por las habitaciones del departamento
	grupo_t -= delta
	if grupo_t <= 0.0 and DURA - hecho > 3.0:
		grupo_t = lerpf(CADA[0], CADA[1], k)
		var n := mini(roundi(lerpf(GRUPO[0], GRUPO[1], k)), TOPE - get_tree().get_nodes_in_group("zombis").size())
		if n > 0:
			sup.grupo(n, TIPOS[0 if hecho < DURA / 2.0 else 1], TOPE)
	if hecho >= DURA:
		acabar()


# Las cámaras del departamento (su nodo), o null si no hay
func camaras() -> Node2D:
	for p in sup.partida.mapa.peligros:
		if p.datos.tipo == "camaras":
			return p
	return null


# Salta una de las cámaras enteras (si no queda ninguna, nada)
func saltar_camara() -> void:
	var c := camaras()
	if c == null or c.alarma > 0.0:
		return
	var enteras: Array = range(c.datos.camaras.size()).filter(func(i): return not c.datos.camaras[i].rota)
	if enteras.is_empty():
		return
	c.saltar(enteras.pick_random())


# Copiado: se abre la puerta y él sigue en el equipo como los demás
func acabar() -> void:
	var partida: Node = sup.partida
	var a := el
	el = null
	a.forzando = false
	a.levantar = 0.0
	a.remove_from_group("presa")
	if not sup.rescate.is_empty():
		sup.rescate.horda_hecha = true   # ya no hay horda para él
	partida.logros.cumplir("buen_vecino")
	partida.cerrada = false
	partida.actualizar_puertas()
	Sonido.musica("menu")
	a.decir(Idioma.t("¡Copiado! Vámonos de aquí"))
	partida.decir(Idioma.t("¡El %s ha copiado los archivos de Velaria!") % Idioma.t(a.def.nombre), 3.5)
	Sonido.tocar("limpio")
	get_tree().create_timer(0.25, false).timeout.connect(Sonido.tocar.bind("puerta"))
	Particulas.anillo(a, a.global_position, 50.0, a.def.color, 0.5)


# Le han dado: si se ha caído, lo dice; si Johnny anda lejos, se queja (como mucho cada 6 s)
func al_herir(cae: bool) -> void:
	if el == null:
		return
	if cae:
		levantando = 0.0
		el.decir(Idioma.t("¡Ayúdame, no puedo levantarme!"))
	elif sup.johnny.position.distance_to(el.position) > Supervivientes.HORDA.lejos and el.dicho_t > 6.0:
		el.decir(Idioma.t(LLAMADAS.pick_random()))


# Antes de cruzar una puerta: lo que dice si no se puede, o "" si sí
func no_cruzar() -> String:
	if el == null:
		return ""
	return Idioma.t("Aguanta: el %s está copiando los archivos") % Idioma.t(el.def.nombre)


# En la pantalla, la barra con la cuenta atrás (como la horda)
func dibujar(capa: Control) -> void:
	if el == null:
		return
	var a := el
	var falta := ceili(DURA - hecho)
	var parpadeo := int(tiempo * 6.0) % 2 == 0
	var relleno: Color = a.def.color
	var texto := Idioma.t("El %s copia los archivos · %d:%02d") % [Idioma.t(a.def.nombre), falta / 60, falta % 60]
	var color := Tema.TINTA
	if a.caido:
		relleno = Color("#ff2d4b") if parpadeo else Color("#7a2030")
		texto = Idioma.t("¡El %s ha caído!") % Idioma.t(a.def.nombre)
		color = Color("#ff8a8a")
	CuentaAtras.dibujar(capa, texto, color, hecho / DURA, relleno, falta, fmod(hecho, 1.0), not a.caido)


# ═════════════ Para probar ═════════════

# Con --captura --edificio torre --programador (prueba_supervivientes.gd): el informático en su sala de servidores; al
# unirse, la copia con su barra (captura-programador-copia.png) y que no deja salir; una cámara que salta
# (captura-programador-alarma.png); tumbarlo y levantarlo; acabar (captura-programador-fin.png). Luego lo suyo: la
# tienda del ordenador un 15 % más barata, que con él cerca las cámaras no ven a Johnny y que abre el teclado del jefe
# sin el código; y su habitación en las viviendas (captura-programador-sala.png). Se deja el equipo y el guardado
# como estaban
func probar() -> void:
	var partida: Node = sup.partida
	var johnny: Node2D = sup.johnny
	var antes: Array = sup.equipo
	for a in antes:
		if a.get_parent():
			a.get_parent().remove_child(a)
	sup.equipo = []
	sup.rescate = {}
	await sup.probar_aqui(false, "programador")
	print("Informático: sale en «%s» · %s" % [Planta.nombre_de_sitio(partida.planta.sitios[partida.aqui]),
		partida.planta.superviviente.get("sala", -1)])
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()   # (la sala, limpia de golpe)
	await get_tree().create_timer(0.8, false).timeout   # se limpia y se abre la sala de servidores
	var npc: Aliado = sup.npc
	if npc:
		johnny.position = npc.position + Vector2(0, 30)
		await get_tree().create_timer(0.4, false).timeout
	if el == null:
		print("Informático: no ha empezado (%s)" % [sup.rescate.get("def", {}).get("nombre", "nadie")])
		dejar(antes)
		return
	var a := el
	await get_tree().create_timer(2.0, false).timeout
	print("Informático: en el equipo %s · copiando %s · puerta cerrada %s · no deja salir: '%s'" % [a in sup.equipo,
		a.forzando, partida.cerrada, no_cruzar()])
	johnny.position = a.position + Vector2(-60, 60)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-programador-copia.png")
	# una cámara salta (adelantando su cuenta)
	alarma_t = 0.0
	await get_tree().create_timer(0.3, false).timeout
	var c := camaras()
	print("Informático: cámaras %s · alarma %s" % [c != null, c.alarma > 0.0 if c else false])
	if c:
		johnny.position = c.ojo(0) + Vector2(80, 200)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.3, false).timeout
		Captura.foto("captura-programador-alarma.png")
	# tumbarlo y levantarlo
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	a.vida = 1
	a.recibir_dano(5)
	var parado := hecho
	await get_tree().create_timer(0.5, false).timeout
	print("Informático: caído %s · no avanza %s" % [a.caido, is_equal_approx(parado, hecho)])
	johnny.position = a.position + Vector2(30, 0)
	await get_tree().create_timer(Supervivientes.HORDA.levantar + 0.6, false).timeout
	print("Informático: levantado %s" % [not a.caido])
	# acabar (adelantado)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	hecho = DURA - 0.2
	frase_i = FRASES.size()
	await get_tree().create_timer(0.6, false).timeout
	print("Informático: acabado %s · puerta abierta %s · sigue en el equipo %s · dice '%s'" % [el == null,
		not partida.cerrada, a in sup.equipo, a.dicho])
	johnny.position = a.position + Vector2(-60, 60)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	Captura.foto("captura-programador-fin.png")
	await probar_mejora(a)
	dejar(antes)


# Lo suyo, ya rescatado: el precio de empleado; con él en el equipo, las cámaras no ven a Johnny y el teclado de la
# sala del jefe se abre sin código; y su habitación en las viviendas
func probar_mejora(a: Aliado) -> void:
	var partida: Node = sup.partida
	var johnny: Node2D = sup.johnny
	var g := Guardado.cargar()
	var guardado := [g.rescatados.duplicate(), g.acompanante]
	Guardado.cambiar(func(x): x.rescatados = [])
	var sin: int = Supervivientes.precio(1000)
	Guardado.cambiar(func(x): x.rescatados = ["programador"])
	print("Informático: precio de empleado, $1000 → $%d sin él y $%d con él (esperado: 1000, 850)" % [sin,
		Supervivientes.precio(1000)])
	var c := camaras()
	if c:
		# un sitio donde la cámara ve a Johnny (con el informático lejos), y luego con él al lado
		a.position = Vector2(-5000, -5000)
		var visto := -1
		c.alarma = 0.0
		for i in c.datos.camaras.size():
			for d in range(60, 400, 20):
				johnny.position = c.ojo(i) + Vector2.from_angle(c.angulo(i)) * d
				if c.ve(i, johnny.global_position, johnny):
					visto = i
					break
			if visto >= 0:
				break
		print("Informático: rotas %s · una cámara ve a Johnny sin él: la %d (esperado: una)" % [
			c.datos.camaras.map(func(x): return x.rota), visto])
		if visto >= 0:
			a.position = johnny.position + Vector2(30, 0)
			print("Informático: y con él al lado %s (esperado: false)" % [c.ve(visto, johnny.global_position, johnny)])
	print("Informático: abre el código del jefe %s (esperado: true)" % [sup.abre_codigo()])
	# su habitación en las viviendas, con él dentro
	for x in sup.equipo:
		x.queue_free()   # (si fuera en el equipo, no esperaría en su habitación)
	sup.equipo = []
	partida.nueva_planta(1)
	await partida.montar(partida.planta.mantenimiento, 0, false)
	johnny.position = partida.mapa.puertas[1].position + Vector2(-16, 0)
	await get_tree().create_timer(1.0, false).timeout
	johnny.position = Viviendas.casa("programador") + Vector2(-70, 50)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3, false).timeout
	print("Informático: en las viviendas, vecinos %s" % [sup.vecinos.map(func(v): return v.def.id)])
	Captura.foto("captura-programador-sala.png")
	Guardado.cambiar(func(x):
		x.rescatados = guardado[0]
		x.acompanante = guardado[1])


func dejar(antes: Array) -> void:
	el = null
	sup.partida.cerrada = false
	for a in sup.equipo:
		if is_instance_valid(a):
			a.queue_free()
	sup.equipo = antes
	sup.rescate = {}
