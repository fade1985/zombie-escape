# La partida de prueba ("-- --captura", ver CLAUDE.md): la partida de siempre (partida.gd) y, encima, las fotos
# y las comprobaciones que van saliendo en la terminal. La monta escenas/partida_prueba.tscn, que es la escena de
# la partida con este script en vez del suyo; con --captura, el menú abre esa en vez de la normal.
# Sin nada más, la prueba larga (_process, abajo): cuenta en la terminal qué planta ha salido, mete a Johnny en un
# apartamento, dispara para despertar a los zombis, guarda una foto en captura.png, sube a la planta siguiente,
# prueba al jefe, los menús, el ordenador, el inventario... y se cierra. Con algo más, solo una parte:
#   --fotos-tiendas, --fotos-luz, --fotos-ayudas   las fotos de las tiendas, de la luz o de las ayudas
#   --evento X     la prueba de ese evento sorpresa (eventos.gd)
#   --alerta N     las reglas de esa alerta (alerta.gd)
#   --jefe X       el minijefe de la 1ª planta (centro comercial: si no, el antidisturbios; Apartamentos: si no, la
#                  portera en la baja)
#   --skins        las skins de Johnny (skins.gd): el desbloqueo, la taquilla, la cara y lo que hace cada una
#   --baul         guardar a mano en el baúl lo de la mochila (ui/inventario.gd)
#   --lanza        la lanza con su dibujo propio: su icono en el baúl, su hoja, la estocada en las 8 direcciones y
#                  con una skin (Armas.CREADAS.lanza)
#   --aplastacabezas  lo mismo con el aplastacabezas: su icono, su hoja, el golpe (que aturde) en las 8 direcciones
#                  y con una skin (Armas.CREADAS.aplastacabezas)
#   --bate-fuego   lo mismo con el bate de fuego: su icono, su hoja, el golpe (que prende) en las 8 direcciones y
#                  con las 4 skins (Armas.CREADAS.bate_fuego)
#   --partecuerpos lo mismo con el partecuerpos: su icono, su hoja, el golpe (que hace sangrar) en las 8 direcciones
#                  y con las 4 skins (Armas.CREADAS.partecuerpos)
#   --inmovilizadora lo mismo con la inmovilizadora: su icono, su hoja, el golpe (que aturde y salta a otro zombi) en las
#                  8 direcciones y con las 4 skins (Armas.CREADAS.inmovilizadora)
#   --latigo       lo mismo con el látigo escorpión: su icono, su hoja, el golpe (a 110 de alcance, que envenena) en las
#                  8 direcciones y con las 4 skins (Armas.CREADAS.latigo)
#   --supermaza    lo mismo con la súper maza: su icono, su hoja, el golpe en círculo (pega a los zombis de todos los lados) en
#                  las 8 direcciones y con las 4 skins (Armas.CREADAS.supermaza)
#   --mangual      lo mismo con el mangual: su icono, su hoja, el giro con la cadena estirada (a 90 de alcance, pega a los
#                  de todos los lados, los echa lejos y los deja aturdidos) en las 8 direcciones y con las 4 skins
#                  (Armas.CREADAS.mangual)
#   --bate-helado  lo mismo con el bate helado: su icono, su hoja, el golpe (que congela al zombi) en las 8 direcciones
#                  y con las 4 skins (Armas.CREADAS.bate_helado)
#   --latigo-electrico lo mismo con el látigo eléctrico: su icono, su hoja, el golpe (a 110 de alcance, que aturde y salta a
#                  otro zombi cercano) en las 8 direcciones y con las 4 skins (Armas.CREADAS.latigo_electrico)
#   --lanzallamas  el lanzallamas (la primera creada a distancia con dibujo propio): su icono, su hoja con la llamarada en la
#                  boca del tubo, sin chispitas, que el chorro quita vida y prende al zombi que tiene delante y no llega al
#                  lejano, el disparo en las 8 direcciones y con las 4 skins (Armas.CREADAS.lanzallamas)
#   --supersoplete el supersoplete (la segunda creada a distancia con dibujo propio): su icono, su hoja con la llamarada en
#                  cono de la boca acampanada, sin chispitas, que el cono quita vida y prende al zombi que tiene cerca y no
#                  llega al lejano, una bala por disparo, el disparo en las 8 direcciones y con las 4 skins
#                  (Armas.CREADAS.supersoplete)
#   --desintegrador el desintegrador (la tercera creada a distancia con dibujo propio): su icono, su hoja con el chorrito de
#                  ácido de la boquilla, sin chispitas, que el chorro quita vida y deja ácido al zombi que tiene delante y
#                  no llega al lejano, una bala por disparo, el disparo en las 8 direcciones y con las 4 skins
#                  (Armas.CREADAS.desintegrador)
#   --bumeran      el bumerán segador (la cuarta creada con dibujo propio que dispara): su icono, su hoja con el gesto de lanzar, sin
#                  chispitas, que el bumerán atraviesa a los zombis que tiene delante, no llega al lejano, vuelve a la mano y no gasta
#                  bala, que andando no hay gesto, el lanzamiento en las 8 direcciones y con las 4 skins (Armas.CREADAS.bumeran)
#   --pistola-electrica la pistola eléctrica (la quinta creada a distancia con dibujo propio): su icono, su hoja con la descarga celeste de
#                  los electrodos, sin chispitas de adorno, que la chispa quita vida y aturde al zombi que tiene delante y salta al
#                  de al lado y no llega al lejano, una bala por disparo, disparar andando, el disparo en las 8 direcciones y con las
#                  4 skins (Armas.CREADAS.pistola_electrica)
#   --garfio       el garfio (la última creada con dibujo propio): su icono, su hoja con el gesto de lanzar, sin chispitas, que engancha al
#                  zombi que tiene delante y se lo trae aturdido, que no llega al lejano y vuelve solo, no gasta bala, que andando
#                  no hay gesto, el lanzamiento en las 8 direcciones y con las 4 skins (Armas.CREADAS.garfio)
#   --ascensorel ascensor arreglado: baja a la sala de mantenimiento y vuelve a la planta (partida.gd)
#   --viviendas    las viviendas de los rescatados, por la puerta de la derecha de la sala (mapa/viviendas.gd)
#   --sala         la sala de mantenimiento: sus tres estancias, sus muebles y una foto de cada una (planta.gd)
#   --armas        la sala de pruebas de armas (F11, sala_armas.gd): la diana que no se muere, la pistola desde 72
#                  ángulos (desde cuáles falla), la munición sin fin, el cambio de arma y la vuelta con las armas de antes
#   --gastro       el vómito de la mutación Gastroenteritis (mutaciones.gd) no cruza las paredes
#   --caza         el acompañante va a por los zombis que ve (aliado.gd, cazar)
#   --porqueria    (con --jefe gloton) la habitación del Glotón: sin muebles y llena de su porquería, que quema
#   --gimnasio     (con --jefe gymbro) el gimnasio del Gymbro: máquinas en las paredes y mancuernas que te tiran
#   --cubos        (con --jefe portera) el cuarto de la limpieza de la portera: cubos de basura, fregonas y cubos
#                  colgados y cubos por el suelo que te tiran
#   --llamas       (con --jefe bombero) la habitación del jefe de bomberos, en llamas por el borde, y su giro con el
#                  lanzallamas: el cono llega a la pared y solo se esquiva corriendo en su sentido
#   --ir-jefe      Mayús + 7, 8, 9 y P: derecho a la habitación de cada minijefe de los Apartamentos
#   --presentacion (con --jefe X, si se quiere) la presentación del jefe al aparecer (ui/presentacion.gd)
extends "res://scripts/partida.gd"

var tiempo := 0.0            # los segundos que lleva la prueba larga (_process)
var grito_visto := false     # fotos_tiendas: la foto del grito de la dependienta, solo una vez
var peligros_vistos := {}    # fotos_tiendas: los peligros que ya tienen sus fotos (fotos_peligros)


func _ready() -> void:
	captura = true
	super()


func preparar_prueba() -> void:
	Guardado.archivo = "user://guardado-prueba.json"   # la prueba no toca el guardado de verdad
	# con "--alerta 5", la prueba se juega con esa alerta (alerta.gd); sin él, sin alerta
	Alerta.nivel = int(Captura.dato("--alerta", "0"))
	# con "--evento apagon" (incendio, horda), la prueba de ese evento sorpresa (eventos.gd)
	eventos.forzado = Captura.dato("--evento")


# En la prueba, el jefe que se ve es el de la 1ª planta (la segunda): que sea el antidisturbios, u otro con
# "--jefe cocinero", "--jefe modista" o "--jefe mascota"
func ordenar_jefes_prueba() -> void:
	var probar := Captura.dato("--jefe", "antidisturbios")
	if probar not in orden_jefes and "portera" in orden_jefes:
		# los Apartamentos sin --jefe: la portera en la planta baja, como siempre
		orden_jefes.erase("portera")
		orden_jefes.insert(0, "portera")
	if probar in orden_jefes:
		orden_jefes.erase(probar)
		orden_jefes.insert(1, probar)
	if "--joyeria" in OS.get_cmdline_user_args():
		Planta.joyeria_planta = 1   # la joyería en la planta baja, para ir derecho a su cámara acorazada


# Ya en la sala de mantenimiento: la prueba que se haya pedido (si no, la larga, que sigue en _process)
func empezar_prueba() -> void:
	var args := OS.get_cmdline_user_args()
	if "--fotos-tiendas" in args:
		fotos_tiendas()
	elif "--fotos-luz" in args:
		fotos_luz()
	elif "--fotos-ayudas" in args:
		fotos_ayudas()
	elif "--fotos-supervivientes" in args:
		fotos_supervivientes()
	elif "--gastro" in args:
		set_process(false)   # sin la prueba larga
		probar_gastro()
	elif "--caza" in args:
		set_process(false)   # sin la prueba larga
		probar_caza()
	elif "--porqueria" in args:
		set_process(false)   # sin la prueba larga
		probar_porqueria()
	elif "--gimnasio" in args:
		set_process(false)   # sin la prueba larga
		probar_gimnasio()
	elif "--cubos" in args:
		set_process(false)   # sin la prueba larga
		probar_cubos()
	elif "--llamas" in args:
		set_process(false)   # sin la prueba larga
		probar_llamas()
	elif "--ir-jefe" in args:
		set_process(false)   # sin la prueba larga
		probar_ir_jefe()
	elif "--presentacion" in args:
		set_process(false)   # sin la prueba larga
		probar_presentacion()
	elif "--skins" in args:
		set_process(false)   # sin la prueba larga
		probar_skins()
	elif "--baul" in args:
		set_process(false)   # sin la prueba larga
		probar_baul()
	elif "--lanza" in args:
		set_process(false)   # sin la prueba larga
		probar_lanza()
	elif "--aplastacabezas" in args:
		set_process(false)   # sin la prueba larga
		probar_aplastacabezas()
	elif "--bate-fuego" in args:
		set_process(false)   # sin la prueba larga
		probar_bate_fuego()
	elif "--partecuerpos" in args:
		set_process(false)   # sin la prueba larga
		probar_partecuerpos()
	elif "--inmovilizadora" in args:
		set_process(false)   # sin la prueba larga
		probar_inmovilizadora()
	elif "--latigo" in args:
		set_process(false)   # sin la prueba larga
		probar_latigo()
	elif "--supermaza" in args:
		set_process(false)   # sin la prueba larga
		probar_supermaza()
	elif "--mangual" in args:
		set_process(false)   # sin la prueba larga
		probar_mangual()
	elif "--bate-helado" in args:
		set_process(false)   # sin la prueba larga
		probar_bate_helado()
	elif "--latigo-electrico" in args:
		set_process(false)   # sin la prueba larga
		probar_latigo_electrico()
	elif "--lanzallamas" in args:
		set_process(false)   # sin la prueba larga
		probar_lanzallamas()
	elif "--supersoplete" in args:
		set_process(false)   # sin la prueba larga
		probar_supersoplete()
	elif "--desintegrador" in args:
		set_process(false)   # sin la prueba larga
		probar_desintegrador()
	elif "--bumeran" in args:
		set_process(false)   # sin la prueba larga
		probar_bumeran()
	elif "--pistola-electrica" in args:
		set_process(false)   # sin la prueba larga
		probar_pistola_electrica()
	elif "--garfio" in args:
		set_process(false)   # sin la prueba larga
		probar_garfio()
	elif "--ascensor" in args:
		set_process(false)   # sin la prueba larga
		probar_ascensor()
	elif "--viviendas" in args:
		set_process(false)   # sin la prueba larga
		probar_viviendas()
	elif "--sala" in args:
		set_process(false)   # sin la prueba larga
		probar_sala()
	elif "--armas" in args:
		set_process(false)   # sin la prueba larga
		probar_armas()
	elif "--joyeria" in args:
		set_process(false)   # sin la prueba larga
		probar_joyeria()
	elif eventos.forzado != "":
		set_process(false)   # sin la prueba larga
		eventos.probar(eventos.forzado)
	elif Reto.activo:
		set_process(false)   # sin la prueba larga
		probar_reto()
	elif Alerta.nivel > 0:
		set_process(false)   # sin la prueba larga
		probar_alerta()
	else:
		contar_planta()


# Con "--captura --fotos-ayudas": prueba las ayudas de Opciones. Abre la pestaña Ayudas y las pone en Sí
# (captura-ayudas-opciones.png); luego le quita casi toda la vida a Johnny, lo cura y dispara la pistola, y
# cuenta en la terminal la vida, los tercios y las balas, sin ayudas y con ellas (captura-ayudas-hud.png).
# Para lanzar apuntando solo, con el ratón lejos, mete un zombi y cuenta adónde iría el lanzable: con la
# ayuda, al zombi (captura-ayudas-lanzar.png, con un molotov en el aire).
# Al acabar las deja en No y se cierra
func fotos_ayudas() -> void:
	set_process(false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var probar := func(nombre: String) -> void:
		johnny.tercios = 3
		johnny.vida = johnny.stats.vida_max
		johnny.quitar_vida(roundi(johnny.stats.vida_max * 0.8))
		johnny.curar(1000)
		johnny.coger("pistola")
		var antes: int = johnny.balas
		for i in 5:
			johnny.disparar(0.0)
		print("Ayudas %s: vida %d/%d tras curar · tercios %d · balas %d -> %d · recargando %s" % [nombre,
			johnny.vida, johnny.stats.vida_max, johnny.tercios_vivos(), antes, johnny.balas, johnny.recargando > 0.0])
	var zombi := meter_zombi("normal", johnny.global_position + Vector2(-150, 60))
	zombi.set_physics_process(false)   # quieto, para la prueba
	var probar_lanzar := func(nombre: String) -> void:
		johnny.con_raton = true
		var donde: Vector2 = lanzables.objetivo()
		print("Ayudas %s: el lanzable caería a %d del zombi" % [nombre, roundi(donde.distance_to(zombi.global_position))])
	probar.call("no")
	probar_lanzar.call("no")
	var o := Opciones.abrir(self, null, johnny)
	o.ver("ayudas")
	await get_tree().process_frame
	for b in o.contenido.get_children():
		if b is Button:
			b.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ayudas-opciones.png")
	o.cerrar()
	probar.call("sí")
	probar_lanzar.call("sí")
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-ayudas-hud.png")
	lanzables.lanzar(lanzables.objetivo())   # un molotov de verdad, en pleno vuelo hacia el zombi
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ayudas-lanzar.png")
	Guardado.cambiar(func(g):
		g.ajustes.vida_entera = false
		g.ajustes.pistola_sin_fin = false
		g.ajustes.lanzar_solo = false)
	get_tree().quit()


# Con "--captura --viviendas": las viviendas de los supervivientes rescatados (mapa/viviendas.gd), detrás de la puerta
# de la derecha de la sala de mantenimiento. Entrar, las puertas cerradas y abiertas, cada uno en su habitación,
# acompañar y volver, y desde la 1ª planta por el ascensor (supervivientes.gd: probar_viviendas); luego los seis a la
# vez, el guiño de la cafetera y las cámaras del técnico. Cada línea de la terminal dice lo esperado. Deja el guardado
# como estaba y se cierra
func probar_viviendas() -> void:
	await get_tree().create_timer(0.3).timeout
	await supervivientes.probar_viviendas()
	await supervivientes.probar_los_seis()
	await supervivientes.probar_cafetera()
	await supervivientes.averia.probar_mejora()
	get_tree().quit()


# Con "--captura --fotos-supervivientes": los tres supervivientes del edificio con su hoja de PixelLab (aliado.gd,
# HOJAS; con "--edificio centro", los del centro comercial). En las viviendas, de vecinos, cada uno en su habitación
# (captura-supervivientes-sala.png); luego se unen al equipo y, en un piso sin zombis, andan tras él
# (captura-supervivientes-andar.png), hacen lo suyo (captura-supervivientes-accion.png: el fogonazo de la pistola y
# del fusil y la jeringa, o el martillazo y la descarga; la farmacéutica no tiene gesto) y el último cae, con su vida
# encima como en la horda (captura-supervivientes-caido.png). Luego se cierra
func fotos_supervivientes() -> void:
	set_process(false)
	var ids := ["ferretero", "farmaceutica", "tecnico"] if edificio == "centro" else ["policia", "medico", "militar"]
	# en las viviendas, con sus puertas abiertas (sin los vecinos de siempre: se ponen los de la prueba)
	var rescatados_antes: Array = Guardado.cargar().rescatados.duplicate()
	Guardado.cambiar(func(g): g.rescatados = ids)
	await montar(planta.viviendas, 0, false)
	Guardado.cambiar(func(g): g.rescatados = rescatados_antes)
	for v in supervivientes.vecinos:
		v.queue_free()
	supervivientes.vecinos = []
	for id in ids:
		if supervivientes.equipo.any(func(a): return a.def.id == id):
			continue   # ya acompaña a Johnny (el guardado de la prueba trae al policía de acompañante)
		# (sin su rescate: al unirse, la farmacéutica y el técnico no empiezan la escolta ni la avería)
		var datos: Dictionary = Supervivientes.DATOS[id].duplicate()
		datos.erase("rescate")
		var v := supervivientes.crear(datos, "vecino")
		v.es_vecino = true
		v.casa = Viviendas.casa(id)
		v.position = v.casa
		mapa.cosas.add_child(v)
		supervivientes.vecinos.append(v)
	# en el pasillo, delante de la habitación del medio de su fila
	var medio := Viviendas.casa(ids[1])
	johnny.position = Vector2(medio.x, (Viviendas.PASILLO_F + (1 if medio.y < Viviendas.PASILLO_F * 32 else 4)) * 32)
	johnny.direccion = "n" if medio.y < Viviendas.PASILLO_F * 32 else "s"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.8).timeout
	Captura.foto("captura-supervivientes-sala.png")
	print("Foto supervivientes: en la sala, de vecinos")
	for v in supervivientes.vecinos.duplicate():
		supervivientes.unir(v)
	# a un apartamento (el de más habitaciones) sin zombis y con todo descubierto, como en fotos_luz
	var i := 1
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and planta.sitios[j].tipo != "viviendas" and (not planta.sitios[i].has("apt")
				or planta.sitios[j].apt.salas.size() > planta.sitios[i].apt.salas.size()):
			i = j
	montar(i, 0, false)
	for sala in planta.sitios[i].apt.salas:
		mapa.vistas[sala.id] = true
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().create_timer(0.5).timeout
	# andando tras Johnny: él se aparta y ellos van a su alrededor
	johnny.position += Vector2(150, 0)
	johnny.direccion = "e"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-supervivientes-andar.png")
	print("Foto supervivientes: andando")
	await get_tree().create_timer(1.2).timeout
	# lo suyo: el policía y el militar sacan el arma, la médica la jeringa, el ferretero alza el martillo y el técnico
	# saca el aparato (la foto, en el fotograma del fogonazo; el rayo de la descarga, a mano, que no hay zombis)
	var hacia := {"policia": Vector2.RIGHT, "medico": Vector2.DOWN, "militar": Vector2.LEFT,
		"ferretero": Vector2.RIGHT, "farmaceutica": Vector2.DOWN, "tecnico": Vector2.LEFT}
	for k in supervivientes.equipo.size():
		var a: Aliado = supervivientes.equipo[k]
		# en fila, que no se tapen, y quietos ahí mirando a su lado (como en la horda, delante de la cerradura)
		a.position = johnny.position + Vector2(-210 + k * 140, 90)
		a.velocity = Vector2.ZERO
		a.forzando = true
		a.sitio_forzar = a.position
		a.mira_forzar = hacia[a.def.id]
		a.animar("reposo", hacia[a.def.id])
		if a.sprite.sprite_frames.has_animation("ataque_s"):
			a.empezar_accion()
	await get_tree().create_timer(0.17).timeout
	for a in supervivientes.equipo:
		if a.def.id == "tecnico":
			a.rayo_t = 0.6
			a.rayo_a = a.global_position + Vector2(-180, -24)
	await get_tree().create_timer(0.05).timeout   # (que se llegue a dibujar el rayo)
	Captura.foto("captura-supervivientes-accion.png")
	print("Foto supervivientes: lo suyo de cada uno")
	await get_tree().create_timer(0.8).timeout
	for a in supervivientes.equipo:
		a.forzando = false
	# el último del edificio cae (como en la horda: forzando la cerradura, con su vida encima)
	var p: Aliado = supervivientes.equipo.filter(func(a): return a.def.id in ids).back()
	p.forzando = true
	p.sitio_forzar = p.position
	p.vida = 0
	p.caido = true
	await get_tree().create_timer(0.9).timeout
	Captura.foto("captura-supervivientes-caido.png")
	print("Foto supervivientes: cae %s" % p.def.nombre)
	get_tree().quit()


# Con "--captura --fotos-luz": para ver si la luz se cuela por las paredes. Entra en el apartamento con más
# habitaciones, todas descubiertas (las lámparas encendidas) y sin zombis, y saca una foto con Johnny en
# cada habitación, justo debajo de un tabique con otra habitación detrás y mirándolo (captura-luz-<n>.png):
# la linterna tiene que quedarse en la pared y no alumbrar el suelo de detrás. Luego se cierra
func fotos_luz() -> void:
	set_process(false)
	$Pantalla/HUD.hide()
	var i := 1   # el apartamento con más habitaciones
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and planta.sitios[j].tipo != "viviendas" and (not planta.sitios[i].has("apt")
				or planta.sitios[j].apt.salas.size() > planta.sitios[i].apt.salas.size()):
			i = j
	montar(i, 0, false)
	var s: Dictionary = planta.sitios[i]
	for sala in s.apt.salas:
		mapa.vistas[sala.id] = true
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	for sala in s.apt.salas:
		# justo debajo de un tabique que tenga otra habitación detrás (el del medio, si hay varios)
		var sitios := []
		for f in range(3, mapa.filas):
			for c in mapa.cols:
				var aqui_d: int = mapa.dueno[f * mapa.cols + c]
				var detras: int = mapa.dueno[(f - 2) * mapa.cols + c]
				if aqui_d == sala.id and mapa.dueno[(f - 1) * mapa.cols + c] == -1 and detras >= 0 and detras != sala.id:
					sitios.append(Vector2(c + 0.5, f + 0.7) * 32.0)
		if sitios.is_empty():
			continue
		johnny.position = sitios[sitios.size() / 2]
		johnny.direccion = "n"
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		Captura.foto("captura-luz-%d.png" % sala.id)
		print("Foto luz: ", s.nombre, " · ", sala.nombre)
	get_tree().quit()


# Con "--captura --presentacion" (y --jefe gloton, u otro): la presentación del jefe (ui/presentacion.gd). Entra en el
# piso del jefe de la 1ª planta y, cuando él aparece, mira al gritar (captura-presentacion-grito.png) que no sale
# ninguna frase escrita y que Johnny está callado; a mitad de la presentación (captura-presentacion.png), que la
# cámara está acercada y sobre el jefe, Johnny quieto y sin poder recibir daño, el jefe gritando, el nombre en
# pantalla y la barra de vida aún oculta; y al acabar, que la cámara ha vuelto, Johnny se mueve (y dice lo que se ha
# callado), el jefe anda y la barra ha salido. Con la Modista (--edificio centro --jefe modista), que entra
# escondida, ni zoom ni grito: solo franjas, nombre y rugido, y sigue escondida al acabar. Johnny lleva las mutaciones
# que actúan solas (mutaciones.gd), listas y con un zombi quieto al lado: ninguna actúa mientras dura, y cada una 1 s
# después de acabar (captura-presentacion-vomito.png, con el vómito en el aire); el acompañante que ataca (el policía
# del guardado de la prueba), igual: con lo suyo listo, no ataca hasta 1 s después (aliado.gd, calma). Cuenta todo en
# la terminal, con lo esperado, y se cierra
func probar_presentacion() -> void:
	set_process(false)
	presentar_en_prueba = true
	nueva_planta(2)   # la 1ª planta: con --jefe X, el suyo
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	# con las mutaciones que actúan solas, listas (como en la partida, esperando a quién): se apunta cuándo actúa cada
	# una (al actuar, su cuenta vuelve a "cada": se ve en el fotograma siguiente) y si la presentación seguía
	var ids := ["gastro", "tentacular", "locura", "flatulento"]
	for id in ids:
		mutaciones.tengo.append(id)
		mutaciones.espera[id] = 0.0
	# el reloj del juego (el de las mutaciones: en los parones de los golpes, Temblor.parar, casi no avanza)
	var reloj := get_tree().create_timer(1000.0)
	var ahora := func() -> float: return 1000.0 - reloj.time_left
	var actua: Array = []   # [mutación, cuándo (s del juego), si la presentación seguía]
	# y lo mismo con los acompañantes que atacan (al atacar, su cuenta vuelve a "cada", igual que las mutaciones)
	var ataques: Array = []   # [cuándo (s del juego), si la presentación seguía]
	get_tree().physics_frame.connect(func() -> void:
		for id in ids:
			if mutaciones.espera[id] == Mutaciones.MUT[id].cada:
				actua.append([id, ahora.call(), presentacion.activa])
		for a in get_tree().get_nodes_in_group("aliados"):
			if a.modo == "equipo" and a.ataca() and a.hab_t == a.def.habilidad.cada:
				ataques.append([ahora.call(), presentacion.activa]))
	montar(idx, 0, false)   # (sin await: la presentación va dentro, y hay que mirarla a medias)
	# Johnny, a 200 de donde saldrá el jefe (en medio de la sala): desde la puerta, el vómito (420) no le llegaría
	johnny.position = Vector2(planta.sitios[idx].ancho / 2.0, planta.sitios[idx].alto / 2.0 + 200.0)
	johnny.get_node("Camara").reset_smoothing()
	# y, nada más empezar la presentación (hasta ahí, sin nadie a quien hacérselo, esperan listas), un zombi quieto a su
	# lado, para que Tentacular, Locura y Flatulento tengan a quién (el vómito también va a él; con mucha vida, que no
	# lo maten)
	while not presentacion.activa:
		await get_tree().physics_frame
	var vecino := meter_zombi("normal", johnny.position + Vector2(40, 0))
	vecino.set_physics_process(false)
	vecino.vida = 100000
	# y los acompañantes que atacan, con lo suyo listo (como las mutaciones): atacan en cuanto se les acaba la calma
	var acompanan: Array = get_tree().get_nodes_in_group("aliados").filter(func(a): return a.modo == "equipo" and a.ataca())
	for a in acompanan:
		a.hab_t = 0.0
	# a 0,6 s, recién soltado el grito: ningún texto flotando en la sala (el jefe no dice ninguna frase escrita) y
	# Johnny callado (lo de la habitación lo dice al acabar)
	await get_tree().create_timer(0.6).timeout
	var flotando: Array = jefa.get_parent().get_children().filter(func(n): return n is Label).map(func(n): return n.text)
	print("Presentación, al gritar: textos flotando en la sala %d %s (esperado: 0: el grito es la pose y el rugido, sin frase escrita) · Johnny dice algo %s (esperado: false: se calla hasta el final)" % [
		flotando.size(), flotando, aviso.modulate.a > 0.0 and aviso.text != ""])
	Captura.foto("captura-presentacion-grito.png")
	await get_tree().create_timer(0.5).timeout   # a 1,1 s de empezar la presentación
	var camara: Camera2D = johnny.get_node("Camara")
	print("Presentación (jefe %s), a mitad: zoom %.2f (esperado: %.1f; 1 si entra escondido, como la Modista) · cámara desplazada %d hacia el jefe (esperado: más de 0; 0 si escondido) · a %d del jefe (esperado: menos de 60, que enfoca algo por encima; da igual si escondido) · Johnny quieto %s y sin daño %s (esperado: true, true) · el jefe gritando %s (esperado: true; false si escondido) · nombre «%s» a la vista %s (esperado: true) · barra oculta %s (esperado: true)" % [
		planta.jefe, camara.zoom.x, presentacion.ZOOM, roundi(camara.offset.length()),
		roundi(camara.get_screen_center_position().distance_to(jefa.global_position)), not johnny.is_physics_processing(),
		johnny.invulnerable > 0.0, jefa.estado == "grito", presentacion.nombre.text,
		presentacion.visible and presentacion.nombre.modulate.a > 0.9, not $Pantalla/Jefa.visible])
	# el foco que alumbra al jefe mientras grita (presentacion.gd): ninguno al Gymbro (se ve con la luz de su gimnasio)
	var focos: int = jefa.get_children().filter(func(n): return n is PointLight2D and n.texture_scale == Presentacion.LUZ_RADIO / 128.0).size()
	print("  (focos sobre el jefe %d (esperado: %s))" % [focos, "0, no lleva (SIN_FOCO)" if planta.jefe in Presentacion.SIN_FOCO else "1; 0 si entra escondido, como la Modista"])
	print("  (jefe en %s, a %d del medio de la sala (esperado: menos de 60) · centro de la cámara %s · offset %s · límites %d-%d x %d-%d · zoom %s)" % [jefa.global_position.round(),
		roundi(jefa.global_position.distance_to(Vector2(planta.sitios[idx].ancho / 2.0, planta.sitios[idx].alto / 2.0))),
		camara.get_screen_center_position().round(), camara.offset, camara.limit_left, camara.limit_right, camara.limit_top, camara.limit_bottom, camara.zoom])
	Captura.foto("captura-presentacion.png")
	while presentacion.activa:
		await get_tree().physics_frame
	var acabo: float = ahora.call()
	await get_tree().create_timer(0.5).timeout
	print("Presentación, al acabar: zoom %.2f (esperado: 1) · cámara desplazada %d (esperado: 0) · Johnny se mueve %s (esperado: true) · el jefe en «%s» (esperado: no «grito») · barra a la vista %s (esperado: true) · franjas y nombre ocultos %s (esperado: true) · Johnny dice «%s» (esperado: lo de la habitación, si tiene peligro: en la del bombero, «¡La habitación está en llamas!…»; si no, nada)" % [
		camara.zoom.x, roundi(camara.offset.length()), johnny.is_physics_processing(), jefa.estado, $Pantalla/Jefa.visible,
		not presentacion.visible, aviso.text if aviso.modulate.a > 0.0 else ""])
	# la primera vez de cada una después, y el primer ataque de los acompañantes (se espera hasta 2,5 s del juego); y
	# la foto, con el vómito ya en el aire
	var primera := {}
	var primer_ataque := ""
	while (primera.size() < ids.size() or (not acompanan.is_empty() and primer_ataque == "")) and ahora.call() - acabo < 2.5:
		await get_tree().physics_frame
		for a in actua:
			if a[1] >= acabo and not primera.has(a[0]):   # (las de antes de salir el jefe no cuentan)
				primera[a[0]] = "%.2f" % (a[1] - acabo)
		for a in ataques:
			if a[0] >= acabo and primer_ataque == "":
				primer_ataque = "%.2f" % (a[0] - acabo)
	print("Mutaciones: veces que actúan durante la presentación %d (esperado: 0) · la primera de cada una, en s después de acabar: %s (esperado: las 4, a 1, con un fotograma de margen: entre 0,95 y 1,1)" % [
		actua.filter(func(a): return a[2]).size(), primera])
	print("Acompañantes que atacan %s: ataques durante la presentación %d (esperado: 0) · el primero, en s después de acabar: %s (esperado: a 1, como las mutaciones: entre 0,95 y 1,1; sin acompañantes, «»)" % [
		acompanan.map(func(a): return a.def.id), ataques.filter(func(a): return a[1]).size(), primer_ataque])
	await get_tree().create_timer(0.15).timeout
	Captura.foto("captura-presentacion-vomito.png")
	get_tree().quit()


# Con "--captura --jefe gloton --porqueria": la habitación del Glotón (peligros/porqueria.gd): sin muebles y con la
# franja de porquería pegada a las paredes, que quema. Monta su piso (la 1ª planta) con todo descubierto y sin
# que salga él, y cuenta en la terminal: los muebles (ninguno, ni lámparas), cuántas casillas están sucias (parte del suelo), que donde
# aparece Johnny está limpio, que el centro está limpio y lo pegado a las paredes sucio (y cuánto mide la franja), que
# en medio queda una elipse limpia perfecta, como un ring, que sale igual con otra semilla, que la puerta está en el
# centro de la pared y de ella se llega al centro por un paso limpio, recto y holgado, lo que pierde Johnny en 1 s sobre una casilla sucia (unos 7) y que en una limpia,
# pasado el escozor, no pierde nada; las salpicaduras de la pared de arriba, los pegotes de los lomos de las otras y las luces del resplandor. Saca captura-porqueria.png
# (Johnny sobre la porquería) y captura-porqueria-medio.png (desde el medio: la elipse limpia y la franja alrededor)
# y se cierra
func probar_porqueria() -> void:
	set_process(false)
	nueva_planta(2)   # la 1ª planta: con --jefe gloton, la suya
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true   # que no aparezca el Glotón: aquí se prueba la habitación
	await montar(idx, 0, false)
	for sala in sitio.apt.salas:
		mapa.vistas[sala.id] = true   # todo descubierto
		mapa.niebla[sala.id] = 0.0
	mapa.actualizar_niebla(0.0)   # (y la niebla, repintada ya: si no, la foto sale tapada)
	var lista: Array = sitio.get("peligros", []).filter(func(q): return q.tipo == "porqueria")
	if lista.is_empty():
		print("Porquería: el piso del jefe (%s) no tiene porquería (¡mal!)" % planta.jefe)
		get_tree().quit()
		return
	var p: Dictionary = lista[0]
	var sala: Dictionary = sitio.apt.salas[0]
	var total: int = sala.ancho * sala.fondo
	var montones: int = p.casillas.values().count(2)
	print("Porquería (jefe %s): muebles %d (esperado: 0, ni lámparas) · casillas sucias %d de %d (%d %%, esperado: entre 35 y 55) · montones %d · donde aparece Johnny, limpio %s (esperado: true)" % [
		planta.jefe, sitio.muebles.size(), p.casillas.size(), total,
		roundi(100.0 * p.casillas.size() / total), montones, not p.casillas.has(Peligros.casilla(johnny.position))])
	# la franja junto a las paredes y la elipse limpia: el centro limpio, y las casillas pegadas a cada pared sucias (en la
	# de la puerta, a un lado de ella), con la franja de al menos 2 casillas de grosor en sus puntos medios
	var medio := Vector2i(sala.c0 + sala.ancho / 2, sala.f0 + sala.fondo / 2)
	var lado_puerta: int = sala.f0 if sitio.apt.entrada.lado == "arriba" else sala.f0 + sala.fondo - 1
	var puntos := [Vector2i(sala.c0, medio.y), Vector2i(sala.c0 + sala.ancho - 1, medio.y),
		Vector2i(medio.x, sala.f0), Vector2i(medio.x, sala.f0 + sala.fondo - 1)]
	for i in puntos.size():
		if puntos[i].y == lado_puerta:
			# a un lado del acceso limpio de la puerta: al otro lado del centro (el pasillo va de la puerta hacia él)
			puntos[i].x += -7 if sitio.apt.entrada.c + 1 > medio.x else 7
	var sucios := puntos.filter(func(q): return p.casillas.has(q)).size()
	var grosor := 99
	for q in puntos:
		var hacia: Vector2i = (medio - q).sign()
		var n := 0
		var k: Vector2i = q
		while p.casillas.has(k):
			n += 1
			k += hacia
		grosor = mini(grosor, n)
	print("Porquería: el centro limpio %s (esperado: true) · pegado a las paredes, sucio en %d de 4 puntos (esperado: 4) · la franja mide al menos %d casillas de grosor (esperado: 2 o más)" % [
		not p.casillas.has(medio), sucios, grosor])
	# siempre igual: con otra semilla, las mismas casillas sucias (los montones sí cambian)
	var otro: Dictionary = sitio.duplicate()
	otro.surtido = int(sitio.surtido) + 1
	print("Porquería: la elipse limpia del medio, de %.1f × %.1f casillas, es perfecta: casillas que no cuadran %d (esperado: 0) · con otra semilla sale igual %s (esperado: true)" % [
		p.ovalo.rx * 2.0, p.ovalo.ry * 2.0, descuadradas(sitio, p), Peligros.del_gloton(otro)[0].casillas.keys() == p.casillas.keys()])
	# el acceso: la puerta en el centro de la pared y de ella al centro de la sala, recto y sin pisar nada
	print("Porquería: %s · %s · de donde aparece Johnny al centro, sin pisar nada y holgado (3 casillas de ancho como poco) %s (esperado: true)" % [
		puerta_en_medio(sitio), paso_recto(sitio), paso_holgado(sala, p.casillas, Peligros.casilla(johnny.position))])
	# 1 s sobre una casilla sucia rodeada de sucias (que el borde no engañe)
	var sucia := Vector2i(-1, -1)
	for c in p.casillas:
		if sucia == Vector2i(-1, -1) and Peligros.LADOS.all(func(d): return p.casillas.has(c + d)):
			sucia = c
	johnny.vida = johnny.stats.vida_max
	johnny.position = Peligros.centro(sucia)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(1.0).timeout
	print("Porquería: 1 s sobre una casilla sucia, Johnny pierde %d (esperado: entre 5 y 9) · estado «porqueria» %s (esperado: true)" % [
		johnny.stats.vida_max - johnny.vida, johnny.estados.has("porqueria")])
	Captura.foto("captura-porqueria.png")
	# en una limpia (sin sucias alrededor), pasado el escozor de 1 s, ya no pierde nada
	var limpia := Vector2i(-1, -1)
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			var k := Vector2i(c, f)
			if limpia == Vector2i(-1, -1) and not p.casillas.has(k) and Peligros.LADOS.all(func(d): return not p.casillas.has(k + d)):
				limpia = k
	johnny.position = Peligros.centro(limpia)
	await get_tree().create_timer(1.3).timeout
	var antes: int = johnny.vida
	await get_tree().create_timer(1.0).timeout
	var salpicaduras: int = mapa.caras.get(sala.id, []).reduce(func(acc, cara): return acc + cara.adornos.size(), 0)
	print("Porquería: en una casilla limpia, pasado el escozor, pierde %d en 1 s (esperado: 0) · estado «porqueria» %s (esperado: false) · salpicaduras en la pared de arriba %d y pegotes en los lomos de las otras %d (esperado: más de 0 las dos) · luces del resplandor %d (esperado: entre 4 y 8)" % [
		antes - johnny.vida, johnny.estados.has("porqueria"), salpicaduras, p.get("paredes", {}).size(), mapa.get_node("Porqueria").luces.size()])
	print("Porquería: %s (se suma al resplandor)" % await luz_fija_de_jefe())
	# y desde el medio de la zona de pelea, con la cámara alejada: la elipse limpia y la franja sucia alrededor
	johnny.position = Peligros.centro(medio)
	johnny.direccion = "n"
	johnny.get_node("Camara").zoom = Vector2(0.66, 0.66)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-porqueria-medio.png")
	get_tree().quit()


# Con "--captura --jefe gymbro --gimnasio": el gimnasio del Gymbro (catalogo.gd, "jefe-gymbro", muebles.gd, fijos,
# peligros/luz_jefe.gd y peligros/tropiezos.gd). Monta su piso (la 1ª planta) con todo descubierto y sin que salga
# él, y cuenta en la terminal: las máquinas (29) y cuántas de cada tipo hay en cada pared (la derecha, 8 cintas; la
# izquierda, 6 bancos de press y 2 pilas de discos; el fondo, 2 taquillas, 4 pilas de discos, 3 poleas y 4 estantes,
# nada en la de abajo), que ninguna se pisa ni toca un muro, que el fondo es simétrico con una polea justo enfrente de
# la puerta, ninguna lámpara, las luces fijas (5) encendidas, qué parte del suelo queda libre, la puerta en el centro
# de la pared, las mancuernas (12, separadas, lejos de la puerta y de los muebles); que al pasar andando por encima de
# una Johnny se cae, no se mueve ni ataca aunque se le pida, no pierde vida y se levanta a los 2 s, y la mancuerna sale
# rodando; y que rodando (la esquiva) se pasa por encima sin caer. Cada línea dice lo esperado. Saca
# captura-gimnasio.png (la sala entera, con la cámara alejada y sin penumbra), captura-gimnasio-luz.png (lo mismo, con
# la penumbra de siempre: lo que alumbran las luces) y captura-gimnasio-caido.png (Johnny en el suelo con las
# estrellitas) y se cierra
func probar_gimnasio() -> void:
	set_process(false)
	nueva_planta(2)   # la 1ª planta: con --jefe gymbro, la suya
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true   # que no aparezca el Gymbro: aquí se prueba la habitación
	await montar(idx, 0, false)
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true   # todo descubierto
		mapa.niebla[s.id] = 0.0
	var lista: Array = sitio.get("peligros", []).filter(func(q): return q.tipo == "tropiezos")
	if lista.is_empty():
		print("Gimnasio: el piso del jefe (%s) no tiene mancuernas (¡mal!)" % planta.jefe)
		get_tree().quit()
		return
	var datos: Dictionary = lista[0]
	var sala: Dictionary = sitio.apt.salas[0]
	var maquinas := ["treadmill", "benchpress", "cablemachine", "dumbbellrack", "weightplates", "lockers"]
	var de_gimnasio: Array = sitio.muebles.filter(func(m): return m.tipo in maquinas)
	var lamparas: int = sitio.muebles.filter(func(m): return m.tipo == "lamp").size()
	var paredes := {}   # pared -> {tipo -> cuántos}
	var ocupado := 0.0
	for m in sitio.muebles:
		paredes[m.lado] = paredes.get(m.lado, {})
		paredes[m.lado][m.tipo] = paredes[m.lado].get(m.tipo, 0) + 1
		ocupado += m.w * m.h
	var esperadas := {"derecha": {"treadmill": 8}, "izquierda": {"benchpress": 6, "weightplates": 2},
		"arriba": {"lockers": 2, "weightplates": 4, "cablemachine": 3, "dumbbellrack": 4}}
	var suelo: float = sala.ancho * sala.fondo * Peligros.CASILLA * Peligros.CASILLA
	print("Gimnasio (jefe %s): muebles %d (esperado: 29), de gimnasio %d (esperado: 29) · lámparas %d (esperado: 0) · por pared %s (esperado: %s) · suelo libre %d %% (esperado: menos de 92)" % [
		planta.jefe, sitio.muebles.size(), de_gimnasio.size(), lamparas, paredes, "igual" if paredes == esperadas else "OTRO: %s" % esperadas,
		roundi(100.0 * (1.0 - ocupado / suelo))])
	# ni se pisan ni tocan un muro, el fondo es simétrico (y la polea del medio, justo enfrente de la puerta)
	var geo := {"cols": sitio.apt.cols, "filas": sitio.apt.filas, "dueno": sitio.apt.dueno}
	var pisados := 0
	for i in sitio.muebles.size():
		for j in range(i + 1, sitio.muebles.size()):
			if Muebles.hueco(sitio.muebles[i]).intersects(Muebles.hueco(sitio.muebles[j])):
				pisados += 1
	var en_muro: int = sitio.muebles.filter(func(m): return not Muebles.en_suelo(geo, Muebles.hueco(m))).size()
	var fondo: Array = sitio.muebles.filter(func(m): return m.lado == "arriba")
	fondo.sort_custom(func(a, b): return a.x < b.x)
	var medio: float = (sitio.apt.entrada.c + 1) * Peligros.CASILLA
	var simetrico := not fondo.is_empty()
	for i in fondo.size():
		var otro: Dictionary = fondo[fondo.size() - 1 - i]
		simetrico = simetrico and fondo[i].tipo == otro.tipo and absf((fondo[i].x - medio) + (otro.x - medio)) <= 2.0
	print("Gimnasio: muebles que se pisan %d (esperado: 0) · metidos en un muro %d (esperado: 0) · el fondo, simétrico %s (esperado: true) · el del medio %s, en x = %d (esperado: cablemachine, en x = %d)" % [
		pisados, en_muro, simetrico, fondo[fondo.size() / 2].tipo if not fondo.is_empty() else "-",
		roundi(fondo[fondo.size() / 2].x) if not fondo.is_empty() else 0, roundi(medio)])
	print("Gimnasio: %s" % puerta_en_medio(sitio))
	var entrada: Rect2 = Muebles.delante_de({"cols": sitio.apt.cols, "filas": sitio.apt.filas}, sitio.apt.entrada.lado,
		(sitio.apt.entrada.c + 1) * Peligros.CASILLA)
	print("Gimnasio: la puerta, en la pared de %s (esperado: abajo) · muebles delante de la puerta %d (esperado: 0)" % [
		sitio.apt.entrada.lado, sitio.muebles.filter(func(m): return Muebles.hueco(m).intersects(entrada)).size()])
	# y en 40 plantas más, cada una con el piso del jefe detrás de una puerta (y una semilla) distinta: siempre abajo
	# y sin muebles delante
	var malos := 0
	var viejo := Planta.semilla
	for k in 40:
		Planta.semilla = 3000 + k
		var otra: Dictionary = Planta.generar(1 + k % 4, "apartamentos", "gymbro")
		for s in otra.sitios:
			if s.tipo != "jefe":
				continue
			var delante: Rect2 = Muebles.delante_de({"cols": s.apt.cols, "filas": s.apt.filas}, s.apt.entrada.lado,
				(s.apt.entrada.c + 1) * Peligros.CASILLA)
			if s.apt.entrada.lado != "abajo" or s.muebles.size() != 29 or s.muebles.any(func(m): return Muebles.hueco(m).intersects(delante)):
				malos += 1
	Planta.semilla = viejo
	print("Gimnasio: en 40 plantas más, con el piso del jefe en otra puerta, con la puerta en otro sitio o con muebles delante: %d (esperado: 0)" % malos)
	var cerca := 9999.0
	for a in datos.cosas:
		for b in datos.cosas:
			if a != b:
				cerca = minf(cerca, a.pos.distance_to(b.pos))
	print("Gimnasio: mancuernas %d (esperado: 12) · la más cercana a otra, a %d (esperado: 110 o más) · alguna junto a la puerta %s (esperado: false) · alguna junto a un mueble %s (esperado: false) · donde aparece Johnny, sin mancuerna %s (esperado: true)" % [
		datos.cosas.size(), roundi(cerca), datos.cosas.any(func(k): return entrada.grow(60.0).has_point(k.pos)),
		datos.cosas.any(func(k): return sitio.muebles.any(func(m): return Muebles.hueco(m).grow(20.0).has_point(k.pos))),
		datos.cosas.all(func(k): return k.pos.distance_to(johnny.position) > 60.0)])
	# la sala entera, desde el medio y con la cámara alejada
	var camara: Camera2D = johnny.get_node("Camara")
	johnny.position = sala.centro
	johnny.direccion = "s"
	camara.zoom = Vector2(0.66, 0.66)
	camara.reset_smoothing()
	luz.alternar()   # sin penumbra, para que se vea todo
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-gimnasio.png")
	luz.alternar()
	await get_tree().create_timer(0.6).timeout
	print("Gimnasio: %s" % await luz_fija_de_jefe())
	Captura.foto("captura-gimnasio-luz.png")   # con la penumbra de siempre: lo que alumbran las luces
	camara.zoom = Vector2.ONE
	await probar_tropezar("Gimnasio", "una mancuerna", "mancuernas", sitio, datos, "captura-gimnasio-caido.png")
	get_tree().quit()


# Con "--captura --jefe portera --cubos": el cuarto de la limpieza de la portera (catalogo.gd, "jefe-portera"; mapa.gd,
# colgados; peligros/tropiezos.gd). Monta su piso (la 1ª planta) con todo descubierto y sin que salga ella, y cuenta en
# la terminal: cómo se llama la sala, los muebles (contenedores, cubos de basura y carros de limpieza, y 3 lámparas) y en
# qué paredes están, la puerta en el centro de la pared, lo que cuelga de la pared de arriba (fregonas y cubos, nada
# delante de la puerta), los cubos del
# suelo (10, de pie, separados, lejos de la puerta y de los muebles) y el aviso de Johnny al entrar; luego lo mismo que
# en el gimnasio (probar_tropezar), y que el cubo con el que tropieza vuelca. Saca captura-cubos.png (la sala entera,
# con la cámara alejada), captura-cubos-pared.png (la pared de arriba de cerca) y captura-cubos-caido.png (Johnny en
# el suelo junto al cubo volcado) y se cierra
func probar_cubos() -> void:
	set_process(false)
	nueva_planta(2)   # la 1ª planta: con --jefe portera, la suya
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true   # que no aparezca la portera: aquí se prueba la habitación
	await montar(idx, 0, false)
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true   # todo descubierto
		mapa.niebla[s.id] = 0.0
	var lista: Array = sitio.get("peligros", []).filter(func(q): return q.tipo == "tropiezos")
	if lista.is_empty():
		print("Cubos: el piso del jefe (%s) no tiene cubos por el suelo (¡mal!)" % planta.jefe)
		get_tree().quit()
		return
	var datos: Dictionary = lista[0]
	var sala: Dictionary = sitio.apt.salas[0]
	var de_limpieza: Array = sitio.muebles.filter(func(m): return m.tipo in ["wheeliebin", "trashcan", "janitorcart"])
	var lamparas: int = sitio.muebles.filter(func(m): return m.tipo == "lamp").size()
	var tipos := {}
	for m in de_limpieza:
		tipos[m.tipo] = tipos.get(m.tipo, 0) + 1
	var paredes := {}
	for m in sitio.muebles:
		paredes[m.lado] = paredes.get(m.lado, 0) + 1
	print("Cubos (jefe %s): la sala se llama «%s» (esperado: Cuarto de la limpieza) · muebles %d, de limpieza %d %s (esperado: de 8 a 11, con 1 o 2 carros, janitorcart) · lámparas %d (esperado: 3) · otros %d (esperado: 0) · por pared %s (esperado: en 3 o 4)" % [
		planta.jefe, sala.nombre, sitio.muebles.size(), de_limpieza.size(), tipos, lamparas,
		sitio.muebles.size() - de_limpieza.size() - lamparas, paredes])
	# lo que cuelga de la pared de arriba (en unidades del mapa, para mirar la puerta)
	var colgados := []
	for cara in mapa.caras.get(sala.id, []):
		for a in cara.adornos:
			if a.dibujo.resource_path.contains("colgado-"):
				colgados.append({"x": cara.position.x + a.x * 2.0, "w": a.dibujo.get_width() * 2.0,
					"fregona": a.dibujo.resource_path.contains("fregona")})
	var puertas: Array = sitio.salidas.filter(func(s): return s.dir == "arriba").map(func(s): return s.en)
	var fregonas := colgados.filter(func(k): return k.fregona).size()
	print("Cubos: colgados en la pared de arriba %d (esperado: 10 o más): fregonas %d y cubos %d (esperado: más de 0 los dos) · alguno delante de la puerta %s (esperado: false; puertas arriba: %d)" % [
		colgados.size(), fregonas, colgados.size() - fregonas,
		colgados.any(func(k): return puertas.any(func(en): return k.x < en + 32.0 and k.x + k.w > en - 32.0)), puertas.size()])
	print("Cubos: %s" % puerta_en_medio(sitio))
	var entrada: Rect2 = Muebles.delante_de({"cols": sitio.apt.cols, "filas": sitio.apt.filas}, sitio.apt.entrada.lado,
		(sitio.apt.entrada.c + 1) * Peligros.CASILLA)
	var cerca := 9999.0
	for a in datos.cosas:
		for b in datos.cosas:
			if a != b:
				cerca = minf(cerca, a.pos.distance_to(b.pos))
	var colores := {}
	for k in datos.cosas:
		colores[k.color] = colores.get(k.color, 0) + 1
	print("Cubos: en el suelo %d (esperado: 10) · todos cubos y de pie %s (esperado: true) · de qué color %s (esperado: de 2 o 3) · el más cercano a otro, a %d (esperado: 110 o más) · alguno junto a la puerta %s (esperado: false) · alguno junto a un mueble %s (esperado: false) · donde aparece Johnny, sin cubo %s (esperado: true)" % [
		datos.cosas.size(), datos.cosas.all(func(k): return k.forma == "cubo" and k.volcado == 0), colores, roundi(cerca),
		datos.cosas.any(func(k): return entrada.grow(60.0).has_point(k.pos)),
		datos.cosas.any(func(k): return sitio.muebles.any(func(m): return Muebles.hueco(m).grow(20.0).has_point(k.pos))),
		datos.cosas.all(func(k): return k.pos.distance_to(johnny.position) > 60.0)])
	await get_tree().create_timer(0.3).timeout
	print("Cubos: al entrar, Johnny avisa %s (esperado: true) · «%s» (esperado: habla de cubos)" % [
		datos.avisado, mapa.get_node("Tropiezos").aviso])
	# la sala entera, desde el medio y con la cámara alejada
	var camara: Camera2D = johnny.get_node("Camara")
	johnny.position = sala.centro
	johnny.direccion = "s"
	camara.zoom = Vector2(0.66, 0.66)
	camara.reset_smoothing()
	luz.alternar()   # sin penumbra, para que se vea todo
	await get_tree().create_timer(0.6).timeout
	print("Cubos: %s (se suma a las lámparas)" % await luz_fija_de_jefe())
	Captura.foto("captura-cubos.png")
	# y la pared de arriba de cerca, con lo colgado (desde un sitio sin cubos cerca: si no, se caería ya aquí)
	camara.zoom = Vector2.ONE
	var junto_pared := Vector2(sala.centro.x, (sala.f0 + 4) * Peligros.CASILLA)
	for paso in range(0, 640, 32):
		var p := junto_pared + Vector2(paso if paso % 64 == 0 else -paso, 0)
		if datos.cosas.all(func(k): return k.pos.distance_to(p + Vector2(0, 14)) > 80.0) \
				and sitio.muebles.all(func(m): return not Muebles.hueco(m).grow(30.0).has_point(p)):
			junto_pared = p
			break
	johnny.position = junto_pared
	camara.reset_smoothing()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-cubos-pared.png")
	luz.alternar()
	await probar_tropezar("Cubos", "un cubo", "cubos", sitio, datos, "captura-cubos-caido.png")
	get_tree().quit()


# Lo que se prueba igual en el gimnasio y en el cuarto de la limpieza (probar_gimnasio, probar_cubos), con la cosa del
# suelo que toque ("uno": "una mancuerna" o "un cubo"; "varios", en plural): que al pasar andando por encima de una Johnny se cae, no se mueve ni
# ataca aunque se le pida, no pierde vida y se levanta a los 2 s, y la cosa sale rodando (el cubo, volcado); y que
# rodando (la esquiva) se pasa por encima de otra sin caer. Saca la foto "foto" (Johnny en el suelo con las estrellitas)
func probar_tropezar(titulo: String, uno: String, varios: String, sitio: Dictionary, datos: Dictionary, foto: String) -> void:
	var sala: Dictionary = sitio.apt.salas[0]
	var camara: Camera2D = johnny.get_node("Camara")
	# una cosa con sitio libre a los dos lados para pasar por encima (sin muebles ni otras cosas)
	var tropiezos: Node = mapa.get_node("Tropiezos")
	var hueco_para := func(k: Dictionary, dir: Vector2) -> bool:
		for paso in range(-100, 181, 8):
			var p: Vector2 = k.pos + dir * paso
			if absi(paso) > 30 and not Peligros.libre_para_cosas(sitio, sala.id, p, 22.0):
				return false
			for otra in datos.cosas:
				if otra != k and otra.pos.distance_to(p) < 40.0:
					return false
		return true
	# (las más cerca del medio, primero: que en la foto no quede Johnny pegado al borde)
	var orden: Array = datos.cosas.duplicate()
	orden.sort_custom(func(a, b): return a.pos.distance_to(sala.centro) < b.pos.distance_to(sala.centro))
	var buscar := func(menos: Dictionary) -> Array:
		for k in orden:
			if k == menos:
				continue
			for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
				if hueco_para.call(k, dir):
					return [k, dir]
		return []
	var accion := {Vector2.RIGHT: "derecha", Vector2.LEFT: "izquierda", Vector2.DOWN: "abajo", Vector2.UP: "arriba"}
	if johnny.caido_t > 0.0:
		print("%s: Johnny ya estaba en el suelo antes de empezar (¡mal! la prueba no valdría)" % titulo)
		return
	var elegida: Array = buscar.call({})
	if elegida.is_empty():
		print("%s: no hay %s con sitio para pasar por encima (¡mal!)" % [titulo, varios])
		return
	var cosa: Dictionary = elegida[0]
	var dir: Vector2 = elegida[1]
	var antes: Vector2 = cosa.pos
	# andando hacia ella: se cae
	johnny.vida = johnny.stats.vida_max
	johnny.velocity = Vector2.ZERO
	johnny.position = cosa.pos - dir * 90.0 - Vector2(0, tropiezos.PIES)
	camara.reset_smoothing()
	Input.action_press(accion[dir])
	var espera := 0.0
	while johnny.caido_t <= 0.0 and espera < 2.0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	var t0 := Time.get_ticks_msec()
	print("%s: andando hacia %s, se cae %s (esperado: true)" % [titulo, uno, johnny.caido_t > 0.0])
	await get_tree().create_timer(0.4).timeout
	var tumbado := absf(rad_to_deg(johnny.sprite.rotation))
	var quieto: Vector2 = johnny.position
	Input.action_press("atacar")
	camara.reset_smoothing()
	await get_tree().create_timer(0.4).timeout
	Captura.foto(foto)
	await get_tree().create_timer(0.6).timeout
	var volcado := " · volcado %s (esperado: true)" % (cosa.volcado != 0) if cosa.forma == "cubo" else ""
	print("%s: en el suelo, tumbado %d° (esperado: 90) · pidiéndole andar 1 s, se mueve %d (esperado: menos de 5) · atacando %s (esperado: false) · ha salido rodando %d (esperado: entre 30 y 120)%s" % [
		titulo, roundi(tumbado), roundi(johnny.position.distance_to(quieto)), johnny.ataque_t >= 0.0,
		roundi(cosa.pos.distance_to(antes)), volcado])
	Input.action_release("atacar")
	while johnny.caido_t > 0.0 and Time.get_ticks_msec() - t0 < 4000:
		await get_tree().physics_frame
	var dura := (Time.get_ticks_msec() - t0) / 1000.0
	var de_pie: Vector2 = johnny.position
	await get_tree().create_timer(0.4).timeout
	Input.action_release(accion[dir])
	print("%s: se levanta a los %.2f s (esperado: 2,0) · derecho %s (esperado: true) · luego anda %d en 0,4 s (esperado: más de 30) · vida perdida %d (esperado: 0)" % [
		titulo, dura, is_zero_approx(johnny.sprite.rotation), roundi(johnny.position.distance_to(de_pie)),
		johnny.stats.vida_max - johnny.vida])
	# rodando por encima de otra: no se cae
	await get_tree().create_timer(0.8).timeout
	var otra: Array = buscar.call(cosa)
	if otra.is_empty():
		print("%s: no hay más %s con sitio para rodar por encima (¡mal!)" % [titulo, varios])
		return
	johnny.velocity = Vector2.ZERO
	johnny.position = otra[0].pos - otra[1] * 60.0 - Vector2(0, tropiezos.PIES)
	await get_tree().physics_frame
	johnny.esquivar(otra[1])
	await get_tree().create_timer(0.6).timeout
	var pasada: float = (johnny.position + Vector2(0, tropiezos.PIES) - otra[0].pos).dot(otra[1])
	print("%s: rodando por encima de %s, se cae %s (esperado: false) · ha pasado al otro lado %s (esperado: true)" % [
		titulo, uno, johnny.caido_t > 0.0, pasada > 20.0])


# Con "--captura --jefe bombero --llamas": la habitación del jefe de bomberos (catalogo.gd, "jefe-bombero";
# peligros/cerco.gd) y su giro con el lanzallamas (bombero.gd). Monta su piso (la 1ª planta) con todo descubierto y sin
# que salga él, y cuenta en la terminal: cómo se llama la sala, que no tiene muebles, cómo arde (la parte del suelo,
# el centro sin fuego, todo lo pegado a la pared ardiendo menos el acceso de la puerta, en medio una elipse limpia
# perfecta, como un ring, que sale igual con otra semilla, la puerta en el centro de la pared y de ella al centro un
# paso sin fuego, recto y holgado, y sitio de sobra para el giro en el medio), el aviso de
# Johnny al entrar, las luces del fuego y lo que quema quedarse 1 s en el fuego.
# Luego mete al bombero en el medio y le hace girar (vuelta_de_giro), con Johnny moviéndose como con el mando: el
# sentido sale a cada lado; el cono se abre 40 grados; llega hasta la pared en todo su ancho; corriendo delante de él,
# en su sentido, Johnny no se quema; en contra, sí; rodando a través de él, también; su burbuja de fuego
# (burbuja_de_fuego): girando, nada le quita vida, y en el aviso y acabado el giro, sí; y enfadado, corriendo por el
# hueco entre los dos conos a su paso, no. Al final, sus bolas de fuego y sus molotovs, enfadado (bolas_y_molotovs).
# Cada línea dice lo esperado. Saca captura-llamas.png (la sala entera ardiendo, con la cámara alejada),
# captura-llamas-aviso.png (el cono rojo y las flechas del aviso), captura-llamas-giro.png (Johnny corriendo delante
# del cono), captura-llamas-burbuja.png (la burbuja de cerca, brillando donde le da una bala) y
# captura-llamas-enfadado.png (los dos conos) y captura-llamas-bolas.png (el abanico de bolas y los molotovs) y se
# cierra
func probar_llamas() -> void:
	set_process(false)
	nueva_planta(2)   # la 1ª planta: con --jefe bombero, la suya
	var idx := -1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "jefe":
			idx = i
	var sitio: Dictionary = planta.sitios[idx]
	sitio.limpio = true   # que no aparezca solo: se le mete a mano cuando toca
	await montar(idx, 0, false)
	for s in sitio.apt.salas:
		mapa.vistas[s.id] = true   # todo descubierto
		mapa.niebla[s.id] = 0.0
	mapa.actualizar_niebla(0.0)   # (y la niebla, repintada ya: si no, la foto sale tapada)
	var lista: Array = sitio.get("peligros", []).filter(func(q): return q.tipo == "cerco")
	if lista.is_empty():
		print("Llamas: el piso del jefe (%s) no tiene el borde en llamas (¡mal!)" % planta.jefe)
		get_tree().quit()
		return
	var cerco: Dictionary = lista[0]
	var apt: Dictionary = sitio.apt
	var sala: Dictionary = apt.salas[0]
	var total: int = sala.ancho * sala.fondo
	# la parte del suelo que arde, el centro sin fuego y, contadas aquí por su cuenta, las casillas pegadas a la pared
	# (menos el acceso limpio de la puerta, el de Peligros.franja_y_ovalo) y las de delante de la puerta (las de sus 2
	# casillas y una más a cada lado, en las 2 filas de esa pared)
	var limpio := Peligros.acceso(apt)
	var en: float = (apt.entrada.c + 1) * Peligros.CASILLA
	var pegadas := 0
	var pegadas_arden := 0
	var puerta := 0
	var puerta_arde := 0
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			var k := Vector2i(c, f)
			var en_hueco := limpio.has(k)
			var lejos: int = mini(mini(c - sala.c0, sala.c0 + sala.ancho - 1 - c), mini(f - sala.f0, sala.f0 + sala.fondo - 1 - f))
			var pared_puerta: int = sala.f0 + sala.fondo - 1 - f if apt.entrada.lado == "abajo" else f - sala.f0
			if pared_puerta < 2 and absf((c + 0.5) * Peligros.CASILLA - en) < 64.0:
				puerta += 1
				puerta_arde += 1 if cerco.casillas.has(k) else 0
			if lejos == 0 and not en_hueco:
				pegadas += 1
				pegadas_arden += 1 if cerco.casillas.has(k) else 0
	var medio := Vector2i(sala.c0 + sala.ancho / 2, sala.f0 + sala.fondo / 2)
	print("Llamas (jefe %s): la sala se llama «%s» (esperado: Apartamento en llamas) · muebles %d (esperado: 0) · arden %d de %d casillas (%d %%, esperado: entre 35 y 55, como la porquería) · el centro sin fuego %s (esperado: true) · pegadas a la pared arden %d de %d (esperado: todas) · delante de la puerta arden %d de %d (esperado: 0 de 8) · donde aparece Johnny, sin fuego %s (esperado: true)" % [
		planta.jefe, sala.nombre, sitio.muebles.size(), cerco.casillas.size(), total, roundi(100.0 * cerco.casillas.size() / total),
		not cerco.casillas.has(medio), pegadas_arden, pegadas, puerta_arde, puerta, not cerco.casillas.has(Peligros.casilla(johnny.position))])
	# siempre igual: con otra semilla, las mismas casillas
	var otro: Dictionary = sitio.duplicate()
	otro.surtido = int(sitio.surtido) + 1
	print("Llamas: la elipse limpia del medio, de %.1f × %.1f casillas, es perfecta: casillas que no cuadran %d (esperado: 0) · con otra semilla sale igual %s (esperado: true)" % [
		cerco.ovalo.rx * 2.0, cerco.ovalo.ry * 2.0, descuadradas(sitio, cerco), Peligros.del_bombero(otro)[0].casillas == cerco.casillas])
	# el acceso: la puerta en el centro de la pared y de ella al centro de la sala, recto y sin pisar el fuego
	print("Llamas: %s · %s · de donde aparece Johnny al centro, sin pisar el fuego y holgado (3 casillas de ancho como poco) %s (esperado: true)" % [
		puerta_en_medio(sitio), paso_recto(sitio), paso_holgado(sala, cerco.casillas, Peligros.casilla(johnny.position))])
	await get_tree().create_timer(0.3).timeout
	var nodo: Node = mapa.get_node("Cerco")
	print("Llamas: al entrar, Johnny avisa %s (esperado: true) · luces del fuego %d (esperado: entre 8 y 10)" % [
		cerco.avisado, nodo.luces.size()])
	print("Llamas: %s (se suma al fuego)" % await luz_fija_de_jefe())
	# lo más cerca que llega el fuego del medio de la sala (donde gira el bombero): Johnny corre a unas 6 casillas de él
	var centro: Vector2 = mapa.centro_libre()   # (ya con el mapa de navegación listo)
	var hueco_giro := INF
	for k in cerco.casillas:
		var caja := Rect2(Vector2(k) * Peligros.CASILLA, Vector2.ONE * Peligros.CASILLA)
		hueco_giro = minf(hueco_giro, centro.distance_to(centro.clamp(caja.position, caja.end)))
	print("Llamas: el fuego, a %d del medio de la sala como poco (esperado: más de 250, que deja sitio para correr el giro a 190-210)" % roundi(hueco_giro))
	# la sala entera, desde el medio y con la cámara alejada (con su luz de verdad: solo la del fuego)
	var camara: Camera2D = johnny.get_node("Camara")
	johnny.position = centro + Vector2(0, 120)
	johnny.direccion = "n"
	camara.zoom = Vector2(0.66, 0.66)
	camara.reset_smoothing()
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-llamas.png")
	# 1 s en el fuego, en el medio del borde de la izquierda; y luego en el medio, pasado el ardor, nada
	johnny.vida = johnny.stats.vida_max
	johnny.position = Peligros.centro(Vector2i(sala.c0, sala.f0 + sala.fondo / 2))
	await get_tree().create_timer(1.0).timeout
	print("Llamas: 1 s en el fuego del borde, Johnny pierde %d (esperado: entre 10 y 14) · ardiendo %s (esperado: true)" % [
		johnny.stats.vida_max - johnny.vida, johnny.estados.has("fuego")])
	johnny.position = centro + Vector2(0, 120)
	await get_tree().create_timer(2.3).timeout
	var antes: int = johnny.vida
	await get_tree().create_timer(1.0).timeout
	print("Llamas: en el medio, pasado el ardor, pierde %d en 1 s (esperado: 0) · ardiendo %s (esperado: false)" % [
		antes - johnny.vida, johnny.estados.has("fuego")])
	# el bombero, en el medio; que nadie le dispare (ni Johnny solo, ni los que le acompañan)
	johnny.modo = "mira"
	for a in get_tree().get_nodes_in_group("aliados"):
		a.process_mode = Node.PROCESS_MODE_DISABLED
	var jefe: Node2D = meter_zombi("bombero", centro)
	await get_tree().create_timer(0.3).timeout
	var lados := {1.0: 0, -1.0: 0}
	for i in 40:
		jefe.avisar_giro(johnny)
		lados[jefe.datos.sentido] += 1
	print("Llamas: el sentido del giro, en 40 avisos: %d como las agujas del reloj y %d al revés (esperado: más de 5 los dos)" % [
		lados[1.0], lados[-1.0]])
	# lo abierto que es el cono: 40 grados (20 a cada lado del medio), a 200 del jefe (la lengua de antes, solo unos 8)
	var cerca := func(grados: float) -> bool:
		return jefe.en_cono(jefe.global_position + Vector2.from_angle(deg_to_rad(grados)) * 200.0, 0.0, 0.0)
	print("Llamas: el cono se abre %d grados (esperado: 40): a 200 del jefe, pilla lo que está a 17 grados del medio %s (esperado: true) y no lo que está a 23 %s (esperado: true)" % [
		roundi(rad_to_deg(jefe.ABERTURA * 2.0)), cerca.call(17.0), not cerca.call(23.0)])
	jefe.andar(5.0)
	var con := await vuelta_de_giro(jefe, centro, "con", 1.0, PI / 2.0, 190.0, "captura-llamas-aviso.png", "captura-llamas-giro.png")
	print("Llamas: el cono llega a la pared en todo su ancho: por el medio, entre %d y %d de largo, y lo más que se queda un rayo de la pared, de borde a borde, %d (esperado: 2 o menos)" % [
		roundi(con.largo[0]), roundi(con.largo[1]), roundi(con.pared)])
	print("Llamas: corriendo delante del cono, en su sentido (a %d-%d del jefe), Johnny pierde %d (esperado: 0) · arde %s (esperado: false)" % [
		roundi(con.radio[0]), roundi(con.radio[1]), con.vida, con.arde])
	var contra := await vuelta_de_giro(jefe, centro, "contra", -1.0, PI / 2.0, 190.0)
	print("Llamas: corriendo en contra (a %d-%d del jefe), Johnny pierde %d (esperado: más de 0) · arde %s (esperado: true)" % [
		roundi(contra.radio[0]), roundi(contra.radio[1]), contra.vida, contra.arde])
	var rodar := await vuelta_de_giro(jefe, centro, "rodar", 1.0, 0.0, 190.0)
	print("Llamas: rodando a través del cono, Johnny rueda %s (esperado: true) · pierde %d (esperado: más de 0) · arde %s (esperado: true)" % [
		rodar.rodado, rodar.vida, rodar.arde])
	await burbuja_de_fuego(jefe, centro)
	# enfadado: dos conos opuestos (Johnny, lejos del empujón del grito y a un lado, donde la elipse limpia es más ancha)
	johnny.position = centro + Vector2(300, 0)
	jefe.fase = 2
	jefe.al_enfadarse(johnny)
	await get_tree().create_timer(0.5).timeout
	var entre := await vuelta_de_giro(jefe, centro, "entre", -1.0, PI / 2.0, 210.0, "", "captura-llamas-enfadado.png")
	print("Llamas: enfadado, corriendo por el hueco entre los dos conos, a su paso (a %d-%d del jefe), Johnny pierde %d (esperado: 0) · arde %s (esperado: false) · conos %d (esperado: 2)" % [
		roundi(entre.radio[0]), roundi(entre.radio[1]), entre.vida, entre.arde, entre.conos])
	await bolas_y_molotovs(jefe, centro)
	get_tree().quit()


# Las bolas de fuego y los molotovs del bombero ("jefe", ya enfadado, puesto en "centro"; bombero.gd), con Johnny
# quieto a un lado: 5 bolas en abanico (de 15 grados en 15) y 3 molotovs en fila, separados para no caer unos encima de
# otros. Saca captura-llamas-bolas.png (el abanico de bolas volando y los molotovs con sus marcas rojas)
func bolas_y_molotovs(jefe: Node2D, centro: Vector2) -> void:
	jefe.andar(5.0)
	jefe.position = centro
	jefe.marcha = Vector2.ZERO
	johnny.position = centro + Vector2(300, 0)
	johnny.velocity = Vector2.ZERO
	johnny.vida = johnny.stats.vida_max
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(0.8, 0.8)
	camara.reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	jefe.mirada = (johnny.position - jefe.position).normalized()
	jefe.lanzar_bolas(johnny)
	jefe.lanzar_molotovs(johnny)
	var bolas: Array = get_tree().get_nodes_in_group("balas_zombi").filter(func(n): return n is BolaFuego)
	var abanico := 0.0
	for b in bolas:
		abanico = maxf(abanico, absf(angle_difference(jefe.mirada.angle(), b.velocidad.angle())))
	var caen: Array = jefe.get_parent().get_children().filter(func(n): return n.get("tipo") == "molotov_jefe").map(
		func(n): return n.hasta)
	var separados := INF
	for i in caen.size():
		for j in range(i + 1, caen.size()):
			separados = minf(separados, caen[i].distance_to(caen[j]))
	print("Llamas: enfadado, bolas de fuego %d (esperado: 5) en abanico de %d grados de punta a punta (esperado: 60) · molotovs %d (esperado: 3), separados %d como poco (esperado: 100 o más)" % [
		bolas.size(), roundi(rad_to_deg(abanico * 2.0)), caen.size(), roundi(separados)])
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-llamas-bolas.png")


# Con "--captura --ir-jefe": desde la sala de mantenimiento, pulsa Mayús + la tecla de cada minijefe de los
# Apartamentos (SALAS_JEFE e ir_al_jefe, partida.gd; la última, el jefe de bomberos) y cuenta en la terminal, de cada
# uno: que está en la planta que le tocó en el sorteo, que Johnny está en la habitación del jefe, junto a la puerta, y
# que el jefe que ha salido es ese. Saca captura-ir-jefe.png (el jefe de bomberos en su habitación en llamas) y se
# cierra
func probar_ir_jefe() -> void:
	var teclas: Array = SALAS_JEFE.keys()
	teclas.erase(KEY_9)
	teclas.append(KEY_9)   # (el jefe de bomberos, el último: el de la foto)
	for tecla in teclas:
		var tipo: String = SALAS_JEFE[tecla]
		johnny.vida = johnny.stats.vida_max
		for pulsada in [true, false]:
			var evento := InputEventKey.new()
			evento.keycode = tecla
			evento.shift_pressed = true
			evento.pressed = pulsada
			Input.parse_input_event(evento)
		# hasta que empieza a cambiar de sitio (mientras se funde a negro, "jefa" aún es el de antes) y luego, hasta que
		# sale el jefe (en la prueba, sin presentación)
		var espera := 0.0
		while not cambiando and espera < 1.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
		while (cambiando or not is_instance_valid(jefa)) and espera < 6.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
		var sitio: Dictionary = planta.sitios[aqui]
		print("Ir al jefe (Mayús + %s): a la %s, la suya del sorteo %s (esperado: true) · en la habitación del jefe %s (esperado: true) · Johnny, a %d de la puerta (esperado: menos de 100) · ha salido %s (esperado: %s)" % [
			OS.get_keycode_string(tecla), planta.nombre, planta.num == orden_jefes.find(tipo) + 1, sitio.tipo == "jefe",
			roundi(johnny.position.distance_to(mapa.puertas[0].llegada())),
			jefa.scene_file_path.get_file().get_basename() if is_instance_valid(jefa) else "nadie", ZOMBIS[tipo].resource_path.get_file().get_basename()])
	await get_tree().create_timer(1.0).timeout
	Captura.foto("captura-ir-jefe.png")
	get_tree().quit()


# Las casillas de la habitación del jefe que no cuadran con una elipse perfecta, la de "datos.ovalo" (la porquería del
# Glotón y el cerco de fuego del bombero, de Peligros.franja_y_ovalo): fuera de ella tiene que estar todo cubierto,
# menos el acceso limpio de la puerta (Peligros.acceso: el hueco de delante y el pasillo hacia el centro), y dentro,
# nada (sin ondas ni manchas sueltas)
func descuadradas(sitio: Dictionary, datos: Dictionary) -> int:
	var apt: Dictionary = sitio.apt
	var sala: Dictionary = apt.salas[0]
	var limpio := Peligros.acceso(apt)
	var ov: Dictionary = datos.ovalo
	var n := 0
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			var k := Vector2i(c, f)
			var fuera: bool = Vector2((c + 0.5 - ov.centro.x) / ov.rx, (f + 0.5 - ov.centro.y) / ov.ry).length() > 1.0
			if datos.casillas.has(k) != (fuera and not limpio.has(k) and Peligros.dueno(apt, c, f) == sala.id):
				n += 1
	return n


# La luz fija de la habitación del jefe de los Apartamentos (peligros/luz_jefe.gd): cuántas luces tiene y cuántas están
# encendidas, con lo esperado (espera un momento a que se enciendan)
func luz_fija_de_jefe() -> String:
	await get_tree().create_timer(0.1).timeout
	var nodos: Array = mapa.peligros.filter(func(p): return p.datos.tipo == "luz_jefe")
	if nodos.is_empty():
		return "luz fija: ninguna (esperado: %d luces blancas, ¡mal!)" % Peligros.LUZ_JEFE.luces.size()
	var luces: Array = nodos[0].luces
	return "luz fija: %d luces (esperado: %d), encendidas %d (esperado: todas)" % [luces.size(), Peligros.LUZ_JEFE.luces.size(),
		luces.filter(func(l): return l.energy > 0.0).size()]


# La puerta de entrada de la habitación del jefe, en el centro de su pared (Apartamento.probar). Devuelve el trozo de
# línea que lo cuenta, con lo esperado
func puerta_en_medio(sitio: Dictionary) -> String:
	var apt: Dictionary = sitio.apt
	var en: int = (apt.entrada.c + 1) * Peligros.CASILLA
	var medio: int = apt.cols * Peligros.CASILLA / 2
	return "la puerta, en x %d, en el centro de la pared (x %d) %s (esperado: true)" % [en, medio, en == medio]


# El acceso limpio de la habitación del jefe (Peligros.acceso, el de la porquería del Glotón y el del cerco de fuego del
# bombero), recto: de la puerta al centro de la sala por las mismas columnas a un lado y a otro de la puerta (torcido,
# sobraría por un lado). Devuelve el trozo de línea que lo cuenta, con lo esperado
func paso_recto(sitio: Dictionary) -> String:
	var apt: Dictionary = sitio.apt
	var columnas := {}
	for k in Peligros.acceso(apt):
		columnas[k.x] = true
	var de: int = columnas.keys().min()
	var a: int = columnas.keys().max()
	var en: int = (apt.entrada.c + 1) * Peligros.CASILLA
	return "el paso limpio va recto, de la columna %d a la %d, lo mismo a cada lado de la puerta %s (esperado: true)" % [
		de, a, (de + a + 1) * Peligros.CASILLA == 2 * en]


# ¿Se va de "desde" al centro de la habitación del jefe ("sala") sin pisar "casillas", y holgado? Por casillas de la
# sala con las 8 de alrededor también limpias (los muros no cuentan): un paso de 3 casillas de ancho como poco, no un
# hueco por el que apenas se cuela
func paso_holgado(sala: Dictionary, casillas: Dictionary, desde: Vector2i) -> bool:
	var pasa := {}
	for f in range(sala.f0, sala.f0 + sala.fondo):
		for c in range(sala.c0, sala.c0 + sala.ancho):
			var k := Vector2i(c, f)
			var libre := true
			for df in range(-1, 2):
				for dc in range(-1, 2):
					if casillas.has(k + Vector2i(dc, df)):
						libre = false
			if libre:
				pasa[k] = true
	return not Peligros.camino(pasa, desde, Vector2i(sala.c0 + sala.ancho / 2, sala.f0 + sala.fondo / 2)).is_empty()


# Una vuelta del giro del bombero ("jefe", puesto en "centro"), con Johnny a "radio" de él, hacia "desde" (ángulo), y
# girando hacia "sentido" (1, como las agujas del reloj). "como" dice qué hace Johnny, moviéndose como con el mando:
# "con" (corre delante del cono, en su sentido), "contra" (corre en contra), "rodar" (quieto, con el medio del cono
# empezando 1,2 rad por detrás de él, y cuando le va a llegar el borde rueda a través de él) o "entre" (enfadado: en el
# aviso corre en el sentido del giro y luego va por el hueco entre los dos conos, a su paso: si se le acerca el de
# detrás, se arrima al jefe, que así da la vuelta antes; si se le acerca el de delante, se aleja). Saca "foto_aviso" en
# el aviso y "foto_giro" a los 2,5 s de girar. Devuelve {vida (la que pierde), arde (si ha llegado a arder), radio
# ([mín, máx] de lo lejos que ha ido del jefe), largo ([mín, máx] del primer cono, por el medio), pared (lo más que se
# ha quedado de la pared un cono, por el medio o cualquiera de sus rayos), conos, rodado}. Si le quema, acaba un poco
# después
func vuelta_de_giro(jefe: Node2D, centro: Vector2, como: String, sentido: float, desde: float, radio: float,
		foto_aviso := "", foto_giro := "") -> Dictionary:
	var sala: Dictionary = mapa.sitio.apt.salas[0]
	var cas := float(Peligros.CASILLA)
	var caja := Rect2(sala.c0 * cas, sala.f0 * cas, sala.ancho * cas, sala.fondo * cas)   # las paredes de la sala
	var hasta_caja := func(p: Vector2, dir: Vector2) -> float:
		var tx := INF if absf(dir.x) < 0.0001 else ((caja.end.x if dir.x > 0.0 else caja.position.x) - p.x) / dir.x
		var ty := INF if absf(dir.y) < 0.0001 else ((caja.end.y if dir.y > 0.0 else caja.position.y) - p.y) / dir.y
		return minf(tx, ty)
	jefe.position = centro
	jefe.marcha = Vector2.ZERO
	johnny.position = centro + Vector2.from_angle(desde) * radio
	johnny.velocity = Vector2.ZERO
	johnny.tercios = 3
	johnny.vida = johnny.stats.vida_max
	johnny.estados.clear()
	johnny.pisando.clear()
	johnny.invulnerable = 0.0
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(0.66, 0.66)
	camara.reset_smoothing()
	await get_tree().physics_frame
	jefe.avisar_giro(johnny, sentido)
	if como == "rodar":
		jefe.datos.angulo = desde - sentido * 1.2
	var r := {"vida": 0, "arde": false, "radio": [INF, 0.0], "largo": [INF, 0.0], "pared": 0.0, "conos": 0, "rodado": false}
	var vida0: int = johnny.vida
	var fotos := {"aviso": foto_aviso == "", "giro": foto_giro == ""}   # (las que ya están o no hacen falta)
	var quemado := -1.0
	var espera := 0.0
	while jefe.estado in ["aviso_giro", "giro"] and espera < 10.0:
		var d: Vector2 = johnny.global_position - jefe.global_position
		var lejos := d.length()
		var fuera := d / lejos
		var hacia := Vector2.from_angle(d.angle() + PI / 2.0 * sentido)   # por donde va el cono
		var pedido := Vector2.ZERO
		match como:
			"con":
				pedido = hacia + fuera * clampf((radio - lejos) / 40.0, -1.0, 1.0)
			"contra":
				pedido = -hacia + fuera * clampf((radio - lejos) / 40.0, -1.0, 1.0)
			"entre":
				var meta := radio
				if jefe.estado == "giro":
					# lo que le lleva al medio del cono de detrás (de 0 a PI): lo mejor, PI / 2, en medio de los dos
					var va := fposmod((d.angle() - jefe.datos.angulo) * sentido, PI)
					meta = clampf(radio + (va - PI / 2.0) * 120.0, 110.0, 300.0)
				pedido = hacia + fuera * clampf((meta - lejos) / 40.0, -1.0, 1.0)
			"rodar":
				var falta := fposmod((d.angle() - jefe.datos.angulo) * sentido, TAU)   # lo que le falta al medio del cono para llegarle
				if jefe.estado == "giro" and not r.rodado and falta < jefe.ABERTURA + 0.12:   # (ya le llega el borde)
					r.rodado = true
					johnny.esquiva_espera = 0.0
					johnny.esquivar(-hacia)
		pedir_andar(pedido.normalized() if pedido != Vector2.ZERO else Vector2.ZERO)
		if jefe.estado == "giro":
			r.radio = [minf(r.radio[0], lejos), maxf(r.radio[1], lejos)]
			r.conos = jefe.datos.largos.size()
			var pies: Vector2 = jefe.global_position + Vector2(0, jefe.PIE - 6)
			for i in jefe.datos.largos.size():
				var a: float = jefe.datos.angulo + i * TAU / jefe.datos.largos.size()
				var largo: float = jefe.datos.largos[i]
				r.pared = maxf(r.pared, absf(largo - hasta_caja.call(jefe.global_position, Vector2.from_angle(a))))
				if i == 0:
					r.largo = [minf(r.largo[0], largo), maxf(r.largo[1], largo)]
				# y cada rayo del cono, de borde a borde (desde sus pies, hasta donde se dibuja)
				for j in jefe.RAYOS + 1:
					var dir := Vector2.from_angle(jefe.angulo_rayo(a, j))
					r.pared = maxf(r.pared, absf(float(jefe.datos.puntas[i][j]) - hasta_caja.call(pies, dir)))
		r.arde = r.arde or johnny.estados.has("fuego")
		if quemado < 0.0 and johnny.vida < vida0:
			quemado = espera
		if not fotos.aviso and jefe.estado == "aviso_giro" and jefe.t >= 0.7:
			fotos.aviso = true
			Captura.foto(foto_aviso)
		if not fotos.giro and jefe.estado == "giro" and jefe.t >= 2.5:
			fotos.giro = true
			Captura.foto(foto_giro)
		if quemado >= 0.0 and espera > quemado + 0.4:
			break   # ya le ha quemado
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	pedir_andar(Vector2.ZERO)
	r.vida = vida0 - johnny.vida
	jefe.andar(5.0)   # que pare de girar (y no ataque hasta la siguiente)
	return r


# La burbuja de fuego del bombero ("jefe", puesto en "centro"; bombero.gd), con Johnny cerca y el cono empezando
# lejos de él. En el aviso del giro aún no la tiene: un golpe de 10 le quita 10. Girando, la tiene: ni un golpe de 10,
# ni una explosión de 40 (que tampoco le corta el giro), ni una bala de 10 le quitan vida, y la burbuja brilla donde
# le da la bala (captura-llamas-burbuja.png, de cerca). Acabado el giro, un golpe de 10 vuelve a quitarle 10 y la
# burbuja baja
func burbuja_de_fuego(jefe: Node2D, centro: Vector2) -> void:
	await get_tree().create_timer(0.5).timeout   # (que acabe de bajar la burbuja de la vuelta de antes)
	jefe.position = centro
	jefe.marcha = Vector2.ZERO
	johnny.position = centro + Vector2(-130, 70)
	johnny.velocity = Vector2.ZERO
	johnny.vida = johnny.stats.vida_max
	var camara: Camera2D = johnny.get_node("Camara")
	camara.zoom = Vector2(1.25, 1.25)
	camara.reset_smoothing()
	await get_tree().physics_frame
	jefe.avisar_giro(johnny, 1.0)
	jefe.datos.angulo += PI   # (el cono, al otro lado: tarda unos 2,7 s en llegarle a Johnny)
	await get_tree().create_timer(0.3).timeout
	var antes: int = jefe.vida
	jefe.recibir_golpe(10, Vector2.RIGHT * 300.0)
	var aviso := [jefe.burbuja == 0.0, antes - jefe.vida]
	var espera := 0.0
	while jefe.estado == "aviso_giro" and espera < 3.0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	await get_tree().create_timer(0.5).timeout   # (ya subida)
	var girando: bool = jefe.estado == "giro"
	var subida: bool = jefe.burbuja >= 1.0
	antes = jefe.vida
	jefe.recibir_golpe(10, Vector2.RIGHT * 300.0)
	var explosion: Node2D = load("res://escenas/armas/explosion.tscn").instantiate()
	explosion.dano = 40
	explosion.position = jefe.position + Vector2(50, 0)
	jefe.get_parent().add_child(explosion)
	await get_tree().create_timer(0.2).timeout
	var sigue: bool = jefe.estado == "giro"
	espera = 0.0
	while is_instance_valid(explosion) and espera < 1.5:   # (que no tape la burbuja en la foto)
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	Temblor.desplazamiento = jefe.position + Vector2(0, -50) - johnny.position   # la foto, con el jefe en medio
	var bala: Node2D = load("res://escenas/armas/bala.tscn").instantiate()
	bala.velocidad = johnny.position.direction_to(jefe.position) * 900.0
	bala.dano = 10
	bala.vida = 1.0
	jefe.get_parent().add_child(bala)
	bala.global_position = johnny.position
	espera = 0.0
	while is_instance_valid(bala) and espera < 1.0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	var brilla: bool = jefe.destello > 0.0
	await get_tree().process_frame
	await get_tree().process_frame
	Captura.foto("captura-llamas-burbuja.png")
	Temblor.desplazamiento = Vector2.ZERO
	var girando_quita: int = antes - jefe.vida
	jefe.andar(5.0)   # se acaba el giro
	await get_tree().physics_frame
	await get_tree().physics_frame
	antes = jefe.vida
	jefe.recibir_golpe(10, Vector2.RIGHT * 300.0)
	var fuera_quita: int = antes - jefe.vida
	await get_tree().create_timer(0.5).timeout
	print("Llamas: la burbuja de fuego, en el aviso aún no está %s (esperado: true) y un golpe de 10 le quita %d (esperado: 10) · girando está %s (esperado: true) y un golpe de 10, una explosión de 40 y una bala de 10 le quitan %d (esperado: 0) · la explosión no le corta el giro %s (esperado: true) · brilla donde le da la bala %s (esperado: true) · acabado el giro, un golpe de 10 le quita %d (esperado: 10) y la burbuja baja %s (esperado: true)" % [
		aviso[0], aviso[1], girando and subida, girando_quita, sigue, brilla, fuera_quita, jefe.burbuja == 0.0])


# Pide andar hacia "dir" como con el stick del mando (cada tecla con su fuerza); Vector2.ZERO, nada
func pedir_andar(dir: Vector2) -> void:
	for par in [["derecha", dir.x], ["izquierda", -dir.x], ["abajo", dir.y], ["arriba", -dir.y]]:
		if par[1] > 0.01:
			Input.action_press(par[0], par[1])
		else:
			Input.action_release(par[0])


# Con "--captura --caza": el acompañante va a por los zombis que ve (aliado.gd, cazar). En un apartamento con todo
# descubierto, solo el ferretero (martillo, alcance 80) acompaña a Johnny, quieto en lo más despejado de la habitación
# más grande. Un zombi en otra habitación, con pared en medio: el ferretero se queda en la fila. Otro despierto y
# quieto a unos 250, a la vista: deja la fila y va a por él (captura-caza-va.png), le da martillazos hasta matarlo y
# vuelve a su puesto junto a Johnny (captura-caza-vuelve.png). Cuenta en la terminal distancias y vida, con lo esperado
func probar_caza() -> void:
	set_process(false)
	var i := 1   # el apartamento con más habitaciones
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and planta.sitios[j].tipo != "viviendas" and (not planta.sitios[i].has("apt")
				or planta.sitios[j].apt.salas.size() > planta.sitios[i].apt.salas.size()):
			i = j
	await montar(i, 0, false)
	var sitio: Dictionary = planta.sitios[i]
	var apt: Dictionary = sitio.apt
	for sala in apt.salas:
		mapa.vistas[sala.id] = true   # todo descubierto: nada a oscuras
		mapa.niebla[sala.id] = 0.0
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	# solo el ferretero en el equipo (el guardado de la prueba trae al policía, que mataría al zombi a tiros desde la fila)
	for a in supervivientes.equipo:
		a.queue_free()
	supervivientes.equipo.clear()
	var datos: Dictionary = Supervivientes.DATOS.ferretero.duplicate()
	datos.erase("rescate")
	var ferre: Aliado = supervivientes.crear(datos, "equipo")
	ferre.idx = 0
	supervivientes.equipo.append(ferre)
	mapa.cosas.add_child(ferre)
	# Johnny, quieto en lo más despejado de la habitación más grande; el ferretero, a su lado
	var grande: Dictionary = apt.salas[0]
	for s in apt.salas:
		if s.casillas > grande.casillas:
			grande = s
	johnny.position = grande.centro
	johnny.direccion = "e"
	johnny.get_node("Camara").reset_smoothing()
	ferre.position = johnny.position + Vector2(-40, 20)
	Aliado.borrar_huellas()
	await get_tree().create_timer(0.8).timeout
	var d_fila: float = ferre.position.distance_to(johnny.position)
	# 1) un zombi en otra habitación, con pared en medio: no lo ve, así que se queda en la fila
	var otra: Dictionary = {}
	for s in apt.salas:
		if s.id != grande.id and not mapa.muro_entre(ferre.position, s.centro).is_empty() and otra.is_empty():
			otra = s
	if otra.is_empty():
		print("Caza: ninguna habitación con pared en medio (no se prueba lo de no verlo)")
	else:
		var tras := meter_zombi("normal", otra.centro)
		tras.dormido = false
		tras.set_physics_process(false)
		await get_tree().create_timer(1.5).timeout
		print("Caza, zombi en otra habitación (a %d, con pared): el ferretero sigue en la fila, a %d de Johnny (esperado: menos de 80) · de caza %s (esperado: false)" % [
			roundi(ferre.position.distance_to(tras.position)), roundi(ferre.position.distance_to(johnny.position)), ferre.cazando])
		tras.queue_free()
		await get_tree().process_frame
	# 2) un zombi despierto y quieto a unos 250, a la vista, en la misma habitación
	var donde := Vector2.INF
	for lejos in [250.0, 200.0, 160.0]:
		for k in 64:
			var pos: Vector2 = johnny.position + Vector2.from_angle(k * TAU / 64.0) * lejos
			if donde == Vector2.INF and Planta.despejado(apt, pos, 20.0, grande.id) and Planta.lejos_de_muebles(sitio, pos, 34.0) \
					and mapa.muro_entre(ferre.position, pos).is_empty():
				donde = pos
		if donde != Vector2.INF:
			break
	if donde == Vector2.INF:
		print("Caza: no hay sitio para el zombi a la vista (¡mal!)")
		get_tree().quit()
		return
	var z := meter_zombi("normal", donde)
	z.dormido = false
	z.set_physics_process(false)   # quieto: ni anda ni ataca, para medir
	var d0: float = ferre.position.distance_to(z.position)
	await get_tree().create_timer(0.7).timeout
	print("Caza, zombi a la vista a %d de Johnny: el ferretero va a por él, de %d a %d (esperado: baja) · a %d de Johnny (esperado: más de %d) · de caza %s (esperado: true)" % [
		roundi(johnny.position.distance_to(z.position)), roundi(d0), roundi(ferre.position.distance_to(z.position)),
		roundi(ferre.position.distance_to(johnny.position)), roundi(d_fila), ferre.cazando])
	Captura.foto("captura-caza-va.png")
	var t := 0.0
	while is_instance_valid(z) and z.estado != "muerto" and t < 8.0:
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	var como: String = "muerto" if not is_instance_valid(z) or z.estado == "muerto" else "vivo con %d" % z.vida
	print("Caza: a los %.1f s el zombi está %s (esperado: muerto) · el ferretero a %d de donde estaba el zombi (esperado: menos de 100)" % [
		t, como, roundi(ferre.position.distance_to(donde))])
	await get_tree().create_timer(2.5).timeout
	print("Caza: sin zombis a la vista, vuelve a la fila: a %d de Johnny (esperado: menos de 80) · de caza %s (esperado: false)" % [
		roundi(ferre.position.distance_to(johnny.position)), ferre.cazando])
	Captura.foto("captura-caza-vuelve.png")
	get_tree().quit()


# Con "--captura --gastro": el vómito de Gastroenteritis (mutaciones.gd) no cruza las paredes. En un apartamento,
# Johnny pegado a un tabique con un zombi justo detrás: el vómito no sale (no lo ve). El charco del vómito junto al
# tabique no quema a ese zombi, pero sí a otro de este lado. Y con otro zombi más lejos pero a la vista, el vómito
# sale a ese (captura-gastro-vuelo.png, captura-gastro-charco.png). Cuenta todo en la terminal y se cierra
func probar_gastro() -> void:
	set_process(false)
	var i := 1   # el apartamento con más habitaciones
	for j in range(1, planta.sitios.size()):
		if planta.sitios[j].has("apt") and planta.sitios[j].tipo != "viviendas" and (not planta.sitios[i].has("apt")
				or planta.sitios[j].apt.salas.size() > planta.sitios[i].apt.salas.size()):
			i = j
	await montar(i, 0, false)
	var sitio: Dictionary = planta.sitios[i]
	for sala in sitio.apt.salas:
		mapa.vistas[sala.id] = true   # todo descubierto: nada a oscuras
		mapa.niebla[sala.id] = 0.0
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().process_frame
	# un tabique de una casilla con una habitación a cada lado, a la altura de una fila (Johnny a un lado, el zombi al otro)
	var johnny_en := Vector2.INF
	var tras_en := Vector2.INF
	var dc := 1
	for f in range(3, mapa.filas - 3):
		for c in range(3, mapa.cols - 3):
			for d in [1, -1]:
				var a: int = mapa.dueno[f * mapa.cols + c]
				var b: int = mapa.dueno[f * mapa.cols + c + 2 * d]
				if a >= 0 and b >= 0 and a != b and mapa.dueno[f * mapa.cols + c + d] == -1 and johnny_en == Vector2.INF \
						and mapa.dueno[f * mapa.cols + c - d] == a and mapa.dueno[f * mapa.cols + c + 3 * d] == b:
					dc = d
					johnny_en = Vector2(c + 0.5, f + 0.5) * 32.0
					tras_en = johnny_en + Vector2(52.0 * d, 0)   # 4 de la pared hacia dentro: dentro del charco
	if johnny_en == Vector2.INF:
		print("Gastro: no he encontrado ningún tabique (¡mal!)")
		get_tree().quit()
		return
	johnny.position = johnny_en
	johnny.get_node("Camara").reset_smoothing()
	var tras := meter_zombi("normal", tras_en)
	tras.set_physics_process(false)   # quietos, para la prueba
	var vomitos := func() -> Array:
		return johnny.get_parent().get_children().filter(func(n): return n.get("tipo") == "vomito" and not n.is_in_group("charcos"))
	# 1) solo hay un zombi, y está tras la pared (a unos 52 de Johnny, muy a tiro): no debe lanzar
	var lanzo: bool = mutaciones.actuar("gastro")
	print("Gastro, un zombi tras la pared (a %d): ¿lanza? %s (esperado: false) · vómitos en el aire %d (esperado: 0)" % [
		roundi(johnny.position.distance_to(tras.position)), lanzo, vomitos.call().size()])
	# 2) un charco de vómito en los pies de Johnny, pegado al tabique: no quema al de detrás pero sí a uno de este lado
	var cerca := meter_zombi("normal", johnny_en - Vector2(28.0 * dc, 0))
	cerca.set_physics_process(false)
	var charco: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
	charco.tipo = "vomito"
	charco.position = johnny_en
	johnny.get_parent().add_child(charco)
	await get_tree().create_timer(0.4).timeout
	print("Gastro, charco pegado al tabique: el de este lado lo pisa %s (esperado: true) · el de detrás lo pisa %s (esperado: false)" % [
		cerca.pisando.has("acido"), tras.pisando.has("acido")])
	Captura.foto("captura-gastro-charco.png")
	charco.queue_free()
	# 3) otro zombi, más lejos que el de detrás pero a la vista: el vómito sale a ese y cae en él, no en la pared
	var lejos_en := Vector2.INF
	for f in range(2, mapa.filas - 2):
		for c in range(2, mapa.cols - 2):
			var pos := Vector2(c + 0.5, f + 0.5) * 32.0
			var dist := pos.distance_to(johnny_en)
			if dist > 110.0 and dist < 260.0 and mapa.dueno[f * mapa.cols + c] == mapa.dueno[int(johnny_en.y / 32.0) * mapa.cols + int(johnny_en.x / 32.0)] \
					and mapa.muro_entre(johnny_en, pos).is_empty() and Planta.lejos_de_muebles(sitio, pos, 34.0) and lejos_en == Vector2.INF:
				lejos_en = pos
	if lejos_en == Vector2.INF:
		print("Gastro: no he encontrado sitio para el zombi lejano (¡mal!)")
		get_tree().quit()
		return
	var lejos := meter_zombi("normal", lejos_en)
	lejos.set_physics_process(false)
	cerca.queue_free()
	await get_tree().process_frame   # que ya no esté en el grupo: si no, el vómito iría a él (el más cercano)
	lanzo = mutaciones.actuar("gastro")
	var aire: Array = vomitos.call()
	var cae := Vector2.INF
	if not aire.is_empty():
		cae = aire[0].hasta
	print("Gastro, con otro zombi a %d a la vista: ¿lanza? %s (esperado: true) · cae a %d de ese zombi y a %d del de detrás de la pared" % [
		roundi(johnny.position.distance_to(lejos.position)), lanzo, roundi(cae.distance_to(lejos.position)), roundi(cae.distance_to(tras.position))])
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-gastro-vuelo.png")
	await get_tree().create_timer(0.6).timeout
	print("Gastro: el charco cae sobre el zombi a la vista, que lo pisa %s (esperado: true) · el de detrás de la pared %s (esperado: false)" % [
		lejos.pisando.has("acido"), tras.pisando.has("acido")])
	get_tree().quit()


# Con "-- --captura --edificio centro --fotos-tiendas": sin penumbra y con todo descubierto, una foto de la sala de
# venta de cada tienda de las dos primeras plantas (captura-tienda-<tipo>.png) y otra de la galería, y se cierra.
# Además, la primera vez que sale cada peligro, sus fotos (fotos_peligros)
func fotos_tiendas() -> void:
	set_process(false)
	luz.alternar()
	Planta.joyeria_planta = 2   # la joyería, en la 1ª planta: así sale en las fotos
	for num in [1, 2]:
		if num > 1:
			nueva_planta(num)
		for i in range(1, planta.sitios.size()):
			var s: Dictionary = planta.sitios[i]
			if s.get("tienda", "") == "":
				continue
			montar(i, 0, false)
			for sala in s.apt.salas:
				mapa.vistas[sala.id] = true
			for z in get_tree().get_nodes_in_group("zombis"):
				z.queue_free()
			var venta: Dictionary = s.apt.salas[0]
			johnny.position = Vector2(venta.c0 + venta.ancho / 2.0, venta.f0 + venta.fondo / 2.0) * 32.0
			johnny.get_node("Camara").reset_smoothing()
			await get_tree().create_timer(0.8).timeout
			var nombre: String = "jefe" if s.tipo == "jefe" else s.tienda
			Captura.foto("captura-tienda-%s.png" % nombre)
			var cuenta := {}
			for z in s.zombis:
				cuenta[z.tipo] = cuenta.get(z.tipo, 0) + 1
			print("Foto: ", s.nombre, " (", nombre, ") | zombis: ", cuenta)
			if not grito_visto and s.tipo != "jefe":
				grito_visto = true
				await foto_grito()
			await fotos_peligros(s)
		montar(0, 0, false)
		johnny.position = Vector2(planta.sitios[0].ancho / 2.0, planta.sitios[0].alto / 2.0)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.8).timeout
		Captura.foto("captura-galeria-%d.png" % num)
	# los peligros que no hayan salido en esas dos plantas (las tiendas cambian en cada partida), en las siguientes
	for num in range(3, 9):
		if peligros_vistos.size() >= 3:
			break
		nueva_planta(num)
		for i in range(1, planta.sitios.size()):
			var s: Dictionary = planta.sitios[i]
			if not s.get("peligros", []).any(func(d): return not peligros_vistos.has(d.tipo)):
				continue
			montar(i, 0, false)
			for sala in s.apt.salas:
				mapa.vistas[sala.id] = true
			for z in get_tree().get_nodes_in_group("zombis"):
				z.queue_free()
			await fotos_peligros(s)
	get_tree().quit()


# La dependienta (zombi_dependienta.gd): dormida delante de Johnny, se despierta, grita «¡OFERTAS!», despierta a los
# vigilantes dormidos de al lado y les mete prisa (captura-grito.png); luego, los nuevos de cerca (captura-nuevos.png)
func foto_grito() -> void:
	var dep := meter_zombi("dependienta", johnny.position + Vector2(120, 0))
	dep.dormido = true
	var otros := []
	for i in 3:
		var v := meter_zombi("vigilante", johnny.position + Vector2(-140 + i * 90, 110))
		v.dormido = true
		otros.append(v)
	# se despierta sola al ver a Johnny (en la misma sala) y grita enseguida
	await get_tree().create_timer(0.25).timeout
	Captura.foto("captura-grito.png")
	print("Grito: estado %s | despiertos %d/3 | prisa %s | velocidad máxima %s" % [dep.estado,
		otros.filter(func(o): return not o.dormido).size(), otros.map(func(o): return snappedf(o.prisa, 0.1)),
		otros.map(func(o): return o.agente.max_speed)])
	await get_tree().create_timer(2.0).timeout
	print("Dependienta a %d de Johnny (se aparta) | estado %s" % [dep.global_position.distance_to(johnny.global_position), dep.estado])
	Captura.foto("captura-nuevos.png")
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().process_frame


# Las fotos de los peligros (peligros.gd), con la penumbra puesta y unos zombis despiertos dentro:
#   captura-peligro-frio.png     Johnny dentro de la cámara (escarcha en la pantalla) y los zombis, congelándose
#   captura-peligro-fuego.png    desde la puerta de la cocina, con zombis ardiendo
#   captura-peligro-agua.png     en pleno calambrazo, con zombis en el agua
#   captura-peligro-sin-luz.png  después de bajar la palanca (la tienda a oscuras)
#   captura-peligro-cuadro.png   delante del cuadro eléctrico (que la vuelve a subir)
func fotos_peligros(s: Dictionary) -> void:
	for nodo in mapa.peligros:
		var d: Dictionary = nodo.datos
		if peligros_vistos.has(d.tipo):
			continue
		peligros_vistos[d.tipo] = true
		luz.alternar()
		luz.poner_sitio(s.tipo)
		var sala: Dictionary = s.apt.salas[d.sala]
		var donde: Vector2 = sala.centro
		var zombis := []
		match d.tipo:
			"frio":
				var dentro := Rect2(sala.c0 * 32.0, sala.f0 * 32.0, sala.ancho * 32.0, sala.fondo * 32.0).grow(-24.0)
				for k in [Vector2(-70, -30), Vector2(70, -20), Vector2(0, 50)]:
					zombis.append((sala.centro + k).clamp(dentro.position, dentro.end))
			"fuego":
				var puerta: Dictionary = s.apt.puertas.filter(func(p): return (p.a == d.sala or p.b == d.sala) and (p.a == 0 or p.b == 0))[0]
				donde = Peligros.centro(Peligros.al_lado_de(s.apt, puerta, d.sala)) + Vector2(16, 0)
				for c in d.arde.keys().filter(func(c): return not c in d.focos).slice(0, 3):
					zombis.append(Peligros.centro(c))
			"agua":
				for c in d.casillas:
					for v in Peligros.LADOS:
						if not c + v in d.casillas and Peligros.dueno(s.apt, c.x + v.x, c.y + v.y) == 0 and not Peligros.bajo_mueble(s, c + v):
							donde = Peligros.centro(c + v)
				var lista: Array = d.casillas.duplicate()
				lista.shuffle()
				for c in lista.slice(0, 3):
					zombis.append(Peligros.centro(c))
		johnny.position = donde
		johnny.get_node("Camara").reset_smoothing()
		for p in zombis:
			var zombi := meter_zombi("normal", p)
			zombi.vida = 300   # para que aguanten hasta la foto
		await get_tree().create_timer(4.6 if d.tipo == "frio" else 1.5).timeout
		if d.tipo == "agua":
			# la foto, en pleno calambrazo
			for i in 60:
				if nodo.destello > 0.12:
					break
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
		Captura.foto("captura-peligro-%s.png" % d.tipo)
		var vivos: Array = get_tree().get_nodes_in_group("zombis").filter(func(z): return z.estado != "muerto")
		print("Peligro %s en %s: Johnny %d de vida | zombis vivos %d (vida %s) | congelados %d | ardiendo %d" % [d.tipo, s.nombre,
			johnny.vida, vivos.size(), vivos.map(func(z): return z.vida), vivos.filter(func(z): return z.congelado > 0.0).size(),
			vivos.filter(func(z): return z.arder_t > 0.0).size()])
		if d.tipo == "fuego":
			print("  arden %d casillas de %d (tope %d), quemadas %d" % [d.arde.size(), d.casillas.size(), d.tope, d.quemadas.size()])
		if d.tipo == "agua":
			nodo.cambiar_corriente()
			await get_tree().create_timer(1.2).timeout
			Captura.foto("captura-peligro-sin-luz.png")
			print("  sin corriente: oscuridad %.2f | corriente %s" % [Luz.nivel, d.corriente])
			johnny.position = Vector2(d.cuadro.x, d.cuadro.y + 40.0)
			johnny.get_node("Camara").reset_smoothing()
			await get_tree().create_timer(1.2).timeout
			Captura.foto("captura-peligro-cuadro.png")
			print("  delante del cuadro: corriente %s | oscuridad %.2f" % [d.corriente, Luz.nivel])
		for z in get_tree().get_nodes_in_group("zombis"):
			z.queue_free()
		johnny.vida = johnny.stats.vida_max
		johnny.tercios = 3
		johnny.estados.clear()
		luz.alternar()
		luz.poner_sitio(s.tipo)


# Con "--captura --alerta N" (en vez de la prueba larga): comprueba las reglas de esa alerta (alerta.gd) con sus
# números en la terminal y saca captura-alerta.png (el aviso del principio), captura-alerta-llave.png (en los
# Apartamentos, el vecino que lleva la llave, que solo sale con la Alerta 5; en el centro comercial, el guardia) y
# captura-alerta-fin.png (el cartel del final con los dólares de más y la alerta que se abre). Luego se cierra
func probar_alerta() -> void:
	var n := Alerta.nivel
	print("Prueba de la %s en %s: %s" % [Alerta.nombre(), ed.el_nombre, Alerta.REGLAS[n]])
	decir("%s: %s
%s: %s" % [planta.nombre, ed.objetivo, Alerta.nombre(), Alerta.REGLAS[n]], 4.0)
	await get_tree().create_timer(0.5, false).timeout
	Captura.foto("captura-alerta.png")
	# A1: los zombis de cinco plantas, sin alerta y con ella (las mismas: con las mismas semillas)
	var contar := func() -> String:
		var total := 0
		var coste := 0.0   # lo que "cuestan" (planta.gd, COSTE): los caros son los duros
		for i in 5:
			Planta.semilla = 1000 + i
			for s in Planta.generar(2, edificio, jefe_de(2)).sitios:
				for z in s.get("zombis", []).filter(func(z): return not z.get("llave", false)):
					total += 1
					coste += Planta.COSTE[z.tipo]
		Planta.semilla = 0
		return "%d (coste %.0f)" % [total, coste]
	Alerta.nivel = 0
	var sin: String = contar.call()
	Alerta.nivel = n
	print("A1 · zombis en cinco plantas: %s sin alerta, %s con ella (x%.2f)" % [sin, contar.call(), Alerta.mas_zombis()])
	# A2 y A3: un zombi normal y el jefe de la planta, recién sacados
	var normal := meter_zombi("normal", Vector2(200, 200))
	var jefe := meter_zombi("portera", Vector2(300, 200))
	print("A2 · velocidad del zombi normal: %.0f (sin alerta, %.0f)" % [normal.velocidad, ZOMBIS.normal.instantiate().velocidad])
	print("A3 · vida de la portera en la planta baja: %d · se enfada a %d %% de la vida" % [jefe.vida_max, roundi(jefe.enfado * 100)])
	normal.queue_free()
	jefe.queue_free()
	$Pantalla/Jefa.hide()
	# A4 y A5
	print("A4 · un botiquín cura %d (sin alerta, %d)" % [cura_botiquin(), BOTIQUIN + johnny.stats.botiquin_extra])
	print("A5 · los disparos se oyen a %.0f (sin alerta, %.0f)" % [Zombi.OIDO * Alerta.oido(), Zombi.OIDO])
	# las rarezas del banco, en 2000 armas
	var rarezas := {"verde": 0, "azul": 0, "morada": 0}
	for i in 2000:
		rarezas[Recetas.rareza_al_azar()] += 1
	print("Banco · de 2000 armas: %d verdes, %d azules, %d moradas" % [rarezas.verde, rarezas.azul, rarezas.morada])
	# el guardia (centro) o el vecino de la llave (Apartamentos), en su sitio y sin penumbra para que se vea bien
	if ed.cerrojo == "tarjeta":
		await montar(0, 0, false)
		print("A5 · el guardia: vida %d" % guardia.vida_max)
		johnny.position = guardia.position + Vector2(-160, 40)   # (que no se quede en la puerta, que la cruzaría)
	else:
		var vecino := -1
		for i in planta.sitios.size():
			if planta.sitios[i].get("zombis", []).any(func(z): return z.get("llave", false)):
				vecino = i
		print("A5 · llave en el suelo: %s | vecino de la llave en %s" % [planta.llave.sitio >= 0,
			planta.sitios[vecino].nombre if vecino >= 0 else "ningún sitio"])
		if vecino >= 0:
			await montar(vecino, 0, false)
			for z in get_tree().get_nodes_in_group("zombis"):
				if z.has_meta("llave"):
					print("A5 · el vecino: vida %d" % z.vida_max)
					johnny.position = z.position + Vector2(0, 90)
					for k in 16:   # Johnny, cerca de él y en su misma habitación
						var p: Vector2 = z.position + Vector2.from_angle(k * TAU / 16.0) * 90.0
						if mapa.zona_en(p) == z.zona:
							johnny.position = p
							break
					luz.alternar()
					johnny.get_node("Camara").reset_smoothing()
					await get_tree().create_timer(0.4, false).timeout
					Captura.foto("captura-alerta-llave.png")
					luz.alternar()
					z.recibir_golpe(9999, Vector2.ZERO)
					await get_tree().create_timer(0.5, false).timeout
					print("A5 · al caer: llave en %s, en el suelo: %s" % [planta.sitios[planta.llave.sitio].nombre
						if planta.llave.sitio >= 0 else "ningún sitio", mapa.cosas.has_node("Llave")])
	if ed.cerrojo == "tarjeta":
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.4, false).timeout
		Captura.foto("captura-alerta-llave.png")
	# el final: con 50 dólares recogidos, y la alerta de la partida como la más alta abierta
	Guardado.cambiar(func(g): Guardado.edificio(g, edificio).alerta_max = n)
	dolares = 50
	planta.num = Planta.PLANTAS
	terminar(true)
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-alerta-fin.png")
	var e: Dictionary = Guardado.cargar().edificios[edificio]
	print("Final · dólares: 50 + %d · alerta más alta abierta: %d" % [Alerta.dolares_extra(50), e.alerta_max])
	get_tree().quit()


# Con "--captura --reto" (y "--reto oscuras", "--reto cuerpo"..., con esa regla en vez de la de hoy): la prueba
# del reto del día (reto.gd). Saca el aviso del principio (captura-reto.png); comprueba que la 1ª planta sale
# igual dos veces con la semilla de hoy y distinta con la de otro día; dice en la terminal lo que cambia cada
# regla y, con la que se juega, cómo queda el primer piso (armaritos, balas, lanzables, lo oscuro que está:
# captura-reto-piso.png); y acaba dos veces, cayendo en la 3ª planta (captura-reto-derrota.png) y completando
# el edificio (captura-reto-fin.png, con la marca mejorada). Al final mira el guardado: la marca de hoy, y que
# el edificio sigue sin contar como completado y sin abrir alertas
func probar_reto() -> void:
	print("Reto del día (%s) en %s: %s · %s · semilla %d" % [Reto.fecha, ed.el_nombre, Reto.nombre(), Reto.desc(), Planta.semilla])
	decir("%s: %s
%s" % [planta.nombre, ed.objetivo, Reto.aviso()], 4.0)
	await get_tree().create_timer(0.5, false).timeout
	Captura.foto("captura-reto.png")
	# la 1ª planta, dos veces con la semilla de hoy y una con la de otro día
	var una := var_to_str(Planta.generar(2, edificio, jefe_de(2)).sitios)
	var otra := var_to_str(Planta.generar(2, edificio, jefe_de(2)).sitios)
	var semilla := Planta.semilla
	Planta.semilla = Reto.semilla_de("2000-01-01", edificio)
	var de_otro_dia := var_to_str(Planta.generar(2, edificio, jefe_de(2)).sitios)
	Planta.semilla = semilla
	print("Semilla · la 1ª planta sale igual dos veces: %s · con la de otro día, distinta: %s" % [una == otra, una != de_otro_dia])
	# lo que cambia cada regla (la vida de Johnny y la velocidad de un zombi normal, recién puestos)
	var regla := Reto.regla
	var talentos: Dictionary = Guardado.cargar().talentos
	for r in Reto.REGLAS:
		Reto.regla = r
		aplicar_talentos(talentos)
		var z := meter_zombi("normal", Vector2(200, 200))
		print("%s · munición: %s · oscuras: %s · curas: %s · velocidad %.0f · vida %d · zombis x%.1f · oído %.0f" % [
			Reto.nombre(), not Reto.sin_municion(), Reto.oscuras(), not Reto.sin_curas(),
			z.velocidad, johnny.stats.vida_max, Reto.mas_zombis(), Zombi.OIDO * Reto.oido()])
		z.queue_free()
	Reto.regla = regla
	aplicar_talentos(talentos)
	# con la regla que se juega, el primer piso: los armaritos, las balas y los lanzables, y lo oscuro que está
	var piso := 1
	for i in planta.sitios.size():
		if planta.sitios[i].tipo == "apartamento":
			piso = i
			break
	await montar(piso, 0, false)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.4, false).timeout
	var lamparas := mapa.find_children("*", "", true, false).filter(func(n): return n.scene_file_path == Eventos.LAMPARA)
	print("Con «%s», en %s · armaritos vacíos: %d de %d · balas %d (+%d) · molotovs %d, granadas %d · oscuridad %.2f (Luz.evento %.2f) · lámparas apagadas: %d de %d · arriba: «%s»" % [
		Reto.nombre(), planta.sitios[piso].nombre, mapa.armaritos.filter(func(a): return a.datos.cogido).size(), mapa.armaritos.size(),
		johnny.balas, johnny.reserva, lanzables.cantidades.molotov, lanzables.cantidades.granada, Luz.nivel, Luz.evento,
		lamparas.filter(func(n): return n.fuerza == 0.0).size(), lamparas.size(), lugar.text])
	Captura.foto("captura-reto-piso.png")
	# el final, dos veces: cayendo en la 3ª planta y luego completando el edificio (las dos mejoran la marca de hoy)
	var antes: Dictionary = Guardado.cargar().edificios[edificio].duplicate()
	planta.num = 3
	planta.nombre = Planta.nombre_planta(3)
	terminar(false)
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-reto-derrota.png")
	var f: Dictionary = Guardado.cargar().retos[edificio]
	print("Caída en la %s · marca de hoy: %s · intentos: %d" % [planta.nombre.to_lower(), Reto.marca(f), f.intentos])
	terminada = false
	planta.num = Planta.PLANTAS
	planta.nombre = Planta.nombre_planta(Planta.PLANTAS)
	dolares = 50
	terminar(true)
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-reto-fin.png")
	var s := Guardado.cargar()
	f = s.retos[edificio]
	var e: Dictionary = s.edificios[edificio]
	print("Completado · marca de hoy: %s (regla %s, intentos %d) · dólares ahorrados: %d" % [Reto.marca(f), f.regla, f.intentos, s.dolares])
	print("El edificio sigue igual (completado %s, victorias %d, alerta más alta %d, mejor planta %d, mejor tiempo %.0f): %s" % [
		e.completado, e.victorias, e.alerta_max, e.mejor_planta, e.mejor_tiempo,
		e.completado == antes.completado and e.victorias == antes.victorias and e.alerta_max == antes.alerta_max
		and e.mejor_planta == antes.mejor_planta and e.mejor_tiempo == antes.mejor_tiempo])
	get_tree().quit()


# Con "--captura --sala": la sala de mantenimiento y sus tres estancias (planta.gd). Cuenta en la terminal las
# estancias, sus puertas y en cuál ha quedado cada mueble, y si desde donde se empieza se llega a todo (por donde andan
# los zombis): a la puerta del pasillo, a la de las viviendas y delante de cada mueble que se usa. Fotos: la sala entera
# (captura-sala.png) y, recortada de la pantalla, cada estancia con Johnny dentro y lo que pone arriba
# (captura-sala-vestuario.png, captura-sala-despacho.png y captura-sala-taller.png). Luego cruza la puerta de las
# viviendas, vuelve y sale al pasillo, y cuenta adónde ha llegado cada vez. Luego se cierra
func probar_sala() -> void:
	var sitio: Dictionary = planta.sitios[aqui]
	var apt: Dictionary = sitio.apt
	print("Sala: %d × %d casillas (%d × %d) · estancias: %s · puertas de dentro: %s" % [apt.cols, apt.filas, sitio.ancho,
		sitio.alto, ", ".join(apt.salas.map(func(s): return "%s %d×%d" % [s.nombre, s.ancho, s.fondo])),
		", ".join(apt.puertas.map(func(d): return "%s-%s" % [apt.salas[d.a].nombre, apt.salas[d.b].nombre]))])
	# los que se usan: [nodo, cómo se dice "delante de él"]
	var usables := {"Ordenador": [mapa.ordenador, "del ordenador"], "Banco": [mapa.banco, "del banco"],
		"Baúl": [mapa.baul, "del baúl"], "Taquilla": [mapa.taquilla, "de la taquilla"]}
	var donde := []
	for n in usables:
		donde.append("%s en %s" % [n, mapa.nombre_zona(mapa.zona_en(usables[n][0].position - Vector2(0, 4)))])
	# ninguno lleva ya su nombre escrito debajo
	var con_nombre := usables.keys().filter(func(n): return not usables[n][0].find_children("*", "Label").is_empty())
	print("Muebles de la sala con su nombre escrito: %s (esperado: ninguno)" % ("ninguno" if con_nombre.is_empty() else ", ".join(con_nombre)))
	for m in mapa.muebles:
		donde.append("%s en %s" % [m.datos.tipo, mapa.nombre_zona(m.zona)])
	var corcho: Node2D = mapa.cosas.get_node_or_null("Corcho")
	donde.append("corcho en %s" % (mapa.nombre_zona(mapa.zona_en(corcho.position)) if corcho else "ningún sitio"))
	print("Muebles: " + " · ".join(donde))
	await get_tree().create_timer(0.2).timeout
	var red: RID = mapa.get_node("Navegacion").get_navigation_map()
	var inicio: Vector2 = johnny.position
	var metas := {"la puerta del pasillo": mapa.puertas[0].llegada(), "la de las viviendas": mapa.puertas[1].llegada()}
	for n in usables:
		metas["delante " + usables[n][1]] = usables[n][0].position + Vector2(0, 22)
	var llega := []
	for n in metas:
		var camino := NavigationServer2D.map_get_path(red, inicio, metas[n], true)
		llega.append("%s %s" % [n, not camino.is_empty() and camino[-1].distance_to(metas[n]) < 24.0])
	print("Desde %s (en el %s) se llega a: %s" % [inicio, mapa.nombre_zona(mapa.zona_en(inicio)).to_lower(), " · ".join(llega)])
	johnny.direccion = "s"
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-sala.png")
	# cada estancia, de cerca: Johnny en medio y, de la pantalla, el trozo de la estancia con sus paredes (sin lo de
	# encima de la pantalla: el minimapa y el letrero tapan la esquina del taller)
	$Pantalla.hide()
	for s in apt.salas:
		johnny.position = s.centro + Vector2(0, 40)
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.3).timeout
		print("En el %s, arriba pone «%s»" % [s.nombre.to_lower(), lugar.text])
		var pantalla := get_viewport().get_texture().get_image()
		var escala := Vector2(pantalla.get_size()) / get_viewport().get_visible_rect().size
		var a := get_viewport().get_canvas_transform() * Vector2((s.c0 - 1) * Planta.CASILLA, -48.0) * escala
		var b := get_viewport().get_canvas_transform() * Vector2((s.c0 + s.ancho + 1) * Planta.CASILLA, sitio.alto) * escala
		var trozo := Rect2i(Vector2i(a), Vector2i(b - a)).intersection(Rect2i(Vector2i.ZERO, pantalla.get_size()))
		pantalla.get_region(trozo).save_png("res://captura-sala-%s.png" % s.uso)
	$Pantalla.show()
	# las dos puertas de fuera: a las viviendas (y vuelta, por la misma) y al pasillo
	await cruzar(1)
	print("Por la puerta de la derecha: en «%s» (esperado: viviendas)" % planta.sitios[aqui].tipo)
	await cruzar(0)
	print("De vuelta: en «%s», en el %s (esperado: mantenimiento, taller)" % [planta.sitios[aqui].tipo,
		mapa.nombre_zona(mapa.zona_en(johnny.position)).to_lower()])
	await cruzar(0)
	print("Por la puerta de abajo: en «%s» (esperado: pasillo)" % planta.sitios[aqui].tipo)
	get_tree().quit()


# Con "--captura --armas": la sala de pruebas de armas (sala_armas.gd). Desde la sala de mantenimiento, F11 lleva a
# ella: cuenta en la terminal su tamaño, que la diana está en el centro, que hay luz y que se entra con la pistola. La
# pistola, en el modo asistido y a 200 de la diana, desde 72 ángulos (cada 5°; 0° = disparando hacia la derecha, 90° =
# hacia abajo): si la primera bala le da, pasa por el lado (y a cuánto) o choca, y los ángulos desde los que falla.
# Luego, que la diana no se ha muerto ni ha perdido vida (y cuántos zombis normales habría matado), que la reserva sigue llena y que ha recargado; que el punto pasa
# a la escopeta y la coma vuelve (con el recuento a cero) y llega a las del banco de trabajo, que el guion esconde y
# saca el panel; y que F11 vuelve a la sala
# de mantenimiento con las armas y las balas de antes. Fotos: captura-armas.png (la sala con las líneas de ayuda y el
# panel, tras un fallo por el lado) y captura-armas-escopeta.png (los perdigones). Cada línea dice lo esperado
func probar_armas() -> void:
	johnny.coger("fregona")   # (entra con la de cuerpo a cuerpo en la mano, para ver que le pone la pistola)
	var antes := [johnny.huecos.duplicate(), johnny.mano, johnny.balas, johnny.reserva]
	await pulsar_y_esperar(KEY_F11)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	var sitio: Dictionary = planta.sitios[aqui]
	var centro := Vector2(sitio.ancho, sitio.alto) / 2.0
	print("Sala de pruebas de armas: en «%s» (esperado: armas) · %d × %d · la diana en el centro %s, la única %s (esperado: true, true) · oscuridad %s (esperado: 0) · en la mano: %s (esperado: Pistola)" % [
		sitio.tipo, sitio.ancho, sitio.alto, sala.diana.global_position.distance_to(centro) < 2.0,
		get_tree().get_nodes_in_group("zombis").size() == 1, luz.oscuridad(), johnny.arma().nombre])
	johnny.poner_modo("asistido")
	var recargo := false
	var vida_min: int = sala.diana.vida_max   # la vida más baja que se le ha visto a la diana
	var resultados := []   # [ángulo, fin, pasa, dirección]
	var foto := -1         # el primer ángulo que falla por el lado: su foto
	for grados in range(0, 360, 5):
		var a := deg_to_rad(grados)
		johnny.position = sala.diana.global_position - Vector2.from_angle(a) * 200.0
		johnny.velocity = Vector2.ZERO
		var antes_tiros := sala.tiros
		var espera := 0.0
		while sala.tiros == antes_tiros and espera < 3.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
			recargo = recargo or johnny.recargando > 0.0
			vida_min = mini(vida_min, sala.diana.vida)
		var b: Dictionary = sala.balas.back()
		while b.fin == "" and espera < 5.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
			vida_min = mini(vida_min, sala.diana.vida)
		resultados.append([grados, b.fin, b.pasa, johnny.direccion])
		if b.fin == "lado" and foto < 0:
			foto = grados
			await get_tree().create_timer(0.05).timeout
			Captura.foto("captura-armas.png")
	var lineas := []
	var fila := []
	for r in resultados:
		fila.append("%d° %s %s" % [r[0], r[3], "da" if r[1] == "acierto" else "%s a %d" % [r[1], roundi(r[2])]])
		if fila.size() == 6:
			lineas.append(" · ".join(fila))
			fila = []
	print("Pistola desde cada ángulo (dirección de Johnny, si da, o cómo falla y a cuánto pasa del centro; le da a menos de 23):
  " + "
  ".join(lineas))
	var falla := resultados.filter(func(r): return r[1] != "acierto")
	print("Da desde %d de %d ángulos; falla desde: %s" % [resultados.size() - falla.size(), resultados.size(),
		", ".join(falla.map(func(r): return "%d°" % r[0])) if not falla.is_empty() else "ninguno"])
	print("Diana: viva %s · la vida más baja que se le ha visto %d de %d (esperado: true, %d, siempre llena) · habría matado %d zombis normales (esperado: más de 0) · aciertos del recuento %d" % [
		sala.diana.estado != "muerto", vida_min, sala.diana.vida_max, sala.diana.vida_max, sala.abatidos, sala.aciertos])
	print("Munición: reserva %d (esperado: %d, siempre llena) · ha recargado %s (esperado: true)" % [johnny.reserva,
		Armas.datos("pistola").cargador * johnny.RESERVA_MAX, recargo])
	await pulsar_y_esperar(KEY_PERIOD)
	for i in 2:
		await get_tree().physics_frame
	# (Johnny ya ha disparado con ella: lo que cuenta tienen que ser solo sus perdigones, cinco por disparo)
	print("Con el punto: %s (esperado: Escopeta) · recuento a cero: %d disparos y %d balas (esperado: cinco balas por disparo)" % [
		johnny.arma().nombre, johnny.disparos - sala.disparos_desde, sala.tiros])
	johnny.position = sala.diana.global_position - Vector2(150, 0)
	await get_tree().create_timer(1.3).timeout
	Captura.foto("captura-armas-escopeta.png")
	print("Escopeta a 150: balas %d · aciertos %d" % [sala.tiros, sala.aciertos])
	await pulsar_y_esperar(KEY_MINUS)
	await get_tree().physics_frame
	var escondido: bool = not sala.panel.visible
	await pulsar_y_esperar(KEY_MINUS)
	await get_tree().physics_frame
	print("Con el guion, el panel se esconde %s y vuelve %s (esperado: true, true)" % [escondido, sala.panel.visible])
	await pulsar_y_esperar(KEY_COMMA)
	await get_tree().physics_frame
	var vuelta: String = johnny.arma().nombre
	for i in 4:
		await pulsar_y_esperar(KEY_COMMA)
	print("Con la coma: %s (esperado: Pistola) · cuatro más atrás: %s (esperado: el último del banco de trabajo, %s)" % [
		vuelta, johnny.arma().nombre, Recetas.LISTA[sala.lista.back()].nombre])
	await pulsar_y_esperar(KEY_F11)
	await get_tree().create_timer(0.3).timeout
	print("De vuelta con F11: en «%s» (esperado: mantenimiento) · armas %s (esperado: true) · balas %d y %d (esperado: %d y %d)" % [
		planta.sitios[aqui].tipo, [johnny.huecos, johnny.mano] == [antes[0], antes[1]], johnny.balas, johnny.reserva,
		antes[2], antes[3]])
	get_tree().quit()


# Pulsa y suelta una tecla y, si con ella se cambia de sitio, espera a que acabe el fundido
func pulsar_y_esperar(tecla: Key) -> void:
	for pulsada in [true, false]:
		var evento := InputEventKey.new()
		evento.keycode = tecla
		evento.pressed = pulsada
		Input.parse_input_event(evento)
	var espera := 0.0
	while not cambiando and espera < 0.2:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	while cambiando and espera < 3.0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()


# Con "--captura --skins": las skins de Johnny (skins.gd). En la sala de mantenimiento, sin ninguna skin:
#   - sin desbloquear, la taquilla no deja ponérsela (y dice cómo se consigue; captura-skins-taquilla-sin.png)
#   - la portera cae y desbloquea el portero (se guarda; no se pone sola), con su aviso (captura-skins-desbloqueo.png);
#     una segunda vez ya no es nueva. Y el Glotón, el glotón (captura-skins-desbloqueo-gloton.png), el Gymbro, el
#     gymbro (captura-skins-desbloqueo-gymbro.png), y el jefe de bomberos, el bombero (captura-skins-desbloqueo-bombero.png)
#   - la taquilla: se abre al arrimarse, enseña el portero y se elige (captura-skins-taquilla.png); Johnny cambia de
#     hoja en el acto y se guarda; uno que no existe no se puede; lo mismo con el glotón, el gymbro y el bombero
#     (captura-skins-taquilla-<id>.png); la tecla Z da la vuelta sin guardar
#   - la cara en las 8 direcciones (con la fregona) y con las otras cinco armas, mirando al sur, al lado del
#     conserje de siempre (captura-skins-caras.png, el portero; captura-skins-caras-<id>.png, las demás); y Johnny
#     andando con la skin, que sigue con su paso
#   - el daño de la fregona: × 4 con el portero (con el bate, igual), contado y con un golpe de verdad
#   - el daño cuerpo a cuerpo: × 3 con el gymbro con todas (también una creada en el banco, la lanza) y las de
#     fuego, igual; contado y con un golpe de verdad (con el bate y con la lanza)
#   - el daño de las armas que queman: × 3 con el bombero (el bate de fuego, el lanzallamas, el súpersoplete, el
#     molotov y la bomba de aceite) y las demás, igual; contado y de verdad, con el golpe o el disparo y lo que sigue
#     ardiendo el zombi (y un molotov de verdad); con la pistola y el bate, igual
#   - el bombero, inmune al fuego: el fuego del suelo, un charco de molotov, los molotovs, el cono y las bolas del jefe
#     de bomberos, de verdad: sin la skin Johnny pierde vida y sigue ardiendo; con ella, nada; el hachazo, sí le quita
#   - el poder del glotón: un zombi normal que le da un zarpazo de verdad muere; el Gymbro (con su armadura) pierde
#     un 10 % de su vida con un golpe suyo y con una pesa suya, y la armadura no se lo para; sin la skin, nada; y nada
#     si Johnny es invulnerable o si el daño no es de nadie
# Cada línea dice lo esperado. Deja el guardado de la prueba sin skins y se cierra
func probar_skins() -> void:
	set_process(false)
	Guardado.cambiar(func(g): g.skins = []; g.skin = "")
	johnny.vestir("")
	johnny.coger("fregona")
	print("Al empezar: skins %s · puesta «%s» · Johnny lleva «%s» (esperado: [], «», «»)" % [Skins.tenidas(),
		Skins.puesta(), johnny.skin])
	# sin desbloquear: la taquilla no deja
	johnny.position = Vector2(mapa.TAQUILLA_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	if taquilla.abierta():
		var puesto: bool = taquilla.elegir("portero")
		# (la foto con todas en «???»: que su pista quepa en la carta, también la larga del jefe de bomberos)
		await get_tree().create_timer(0.2).timeout
		Captura.foto("captura-skins-taquilla-sin.png")
		print("Sin desbloquear: ¿puesto? %s (esperado: false) · Johnny lleva «%s» · dice «%s»" % [
			puesto, johnny.skin, taquilla.info.text])
		taquilla.cerrar()
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout

	# ── El desbloqueo: cae la portera ──
	var portera: Node2D = meter_zombi("portera", johnny.position + Vector2(220, 0))
	await get_tree().create_timer(0.2).timeout
	for i in 20:
		if portera.estado == "muerto":
			break
		portera.recibir_golpe(99999, Vector2.ZERO)
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-skins-desbloqueo.png")
	print("Cae la portera (muerta: %s): skins %s · puesta «%s» (esperado: [\"portero\"], «»: no se pone sola)" % [
		portera.estado == "muerto", Skins.tenidas(), Skins.puesta()])
	print("Otra vez: ¿nueva? %s (esperado: false) · skins %s" % [Skins.desbloquear("portero"), Skins.tenidas()])
	# las mutaciones que salen al caer la portera: se elige una y sigue
	await get_tree().create_timer(2.0).timeout
	if menus.abierto == "mutacion":
		menus.elegir("insensible")
	get_tree().paused = false
	$Pantalla/Jefa.hide()
	# y el Glotón (le pega un aliado: que su ácido no salpique a Johnny)
	var gloton: Node2D = meter_zombi("gloton", johnny.position + Vector2(220, 0))
	await get_tree().create_timer(0.2).timeout
	for i in 20:
		if gloton.estado == "muerto":
			break
		gloton.recibir_golpe(99999, Vector2.ZERO, false, true)
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-skins-desbloqueo-gloton.png")
	print("Cae el Glotón (muerto: %s): skins %s · puesta «%s» (esperado: [\"portero\", \"gloton\"], «»)" % [
		gloton.estado == "muerto", Skins.tenidas(), Skins.puesta()])
	print("Otra vez: ¿nueva? %s (esperado: false) · un jefe sin skin (el cocinero): «%s» (esperado: «»)" % [
		Skins.desbloquear("gloton"), Skins.de_jefe("cocinero")])
	await get_tree().create_timer(2.0).timeout
	if menus.abierto == "mutacion":
		menus.elegir("canibal")
	get_tree().paused = false
	$Pantalla/Jefa.hide()
	# y el Gymbro
	var jefe_gymbro: Node2D = meter_zombi("gymbro", johnny.position + Vector2(220, 0))
	await get_tree().create_timer(0.2).timeout
	for i in 60:
		if jefe_gymbro.estado == "muerto":
			break
		jefe_gymbro.recibir_golpe(99999, Vector2.ZERO, false, true)
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-skins-desbloqueo-gymbro.png")
	print("Cae el Gymbro (muerto: %s): skins %s · puesta «%s» (esperado: [\"portero\", \"gloton\", \"gymbro\"], «»)" % [
		jefe_gymbro.estado == "muerto", Skins.tenidas(), Skins.puesta()])
	print("Otra vez: ¿nueva? %s (esperado: false)" % Skins.desbloquear("gymbro"))
	await get_tree().create_timer(2.0).timeout
	if menus.abierto == "mutacion":
		menus.elegir("insensible")
	get_tree().paused = false
	$Pantalla/Jefa.hide()
	# y el jefe de bomberos (le pega un aliado, como al Glotón)
	var jefe_bombero: Node2D = meter_zombi("bombero", johnny.position + Vector2(220, 0))
	await get_tree().create_timer(0.2).timeout
	for i in 60:
		if jefe_bombero.estado == "muerto":
			break
		jefe_bombero.recibir_golpe(99999, Vector2.ZERO, false, true)
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-skins-desbloqueo-bombero.png")
	print("Cae el jefe de bomberos (muerto: %s): skins %s · puesta «%s» (esperado: [\"portero\", \"gloton\", \"gymbro\", \"bombero\"], «»)" % [
		jefe_bombero.estado == "muerto", Skins.tenidas(), Skins.puesta()])
	print("Otra vez: ¿nueva? %s (esperado: false)" % Skins.desbloquear("bombero"))
	await get_tree().create_timer(2.0).timeout
	if menus.abierto == "mutacion":
		menus.elegir("canibal")
	get_tree().paused = false
	$Pantalla/Jefa.hide()
	# (lo que haya dejado ardiendo al caer: fuera)
	for c in get_tree().get_nodes_in_group("charcos"):
		c.queue_free()

	# ── La taquilla ──
	johnny.position = Vector2(mapa.TAQUILLA_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Taquilla: abierta al arrimarse %s · juego en pausa %s (esperado: true, true)" % [taquilla.abierta(), get_tree().paused])
	if taquilla.abierta():
		taquilla.marcar("portero")
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-skins-taquilla.png")
		taquilla.elegir("portero")
		print("Elegido el portero: Johnny lleva «%s» · guardado «%s» · su hoja %s · dice «%s»" % [johnny.skin,
			Guardado.cargar().skin, johnny.sprite.sprite_frames.resource_path.get_file(), taquilla.info.text])
		print("Uno que no existe: ¿puesto? %s (esperado: false) · Johnny sigue con «%s»" % [taquilla.elegir("astronauta"),
			johnny.skin])
		# (las fotos del glotón, del gymbro y del bombero, ya puestas: que su efecto quepa también con «Puesta»)
		taquilla.marcar("gloton")
		taquilla.elegir("gloton")
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-skins-taquilla-gloton.png")
		print("Elegido el glotón: Johnny lleva «%s» · guardado «%s» · su hoja %s · dice «%s»" % [johnny.skin,
			Guardado.cargar().skin, johnny.sprite.sprite_frames.resource_path.get_file(), taquilla.info.text])
		taquilla.marcar("gymbro")
		taquilla.elegir("gymbro")
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-skins-taquilla-gymbro.png")
		print("Elegido el gymbro: Johnny lleva «%s» · guardado «%s» · su hoja %s · dice «%s»" % [johnny.skin,
			Guardado.cargar().skin, johnny.sprite.sprite_frames.resource_path.get_file(), taquilla.info.text])
		taquilla.marcar("bombero")
		taquilla.elegir("bombero")
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-skins-taquilla-bombero.png")
		print("Elegido el bombero: Johnny lleva «%s» · guardado «%s» · su hoja %s · dice «%s»" % [johnny.skin,
			Guardado.cargar().skin, johnny.sprite.sprite_frames.resource_path.get_file(), taquilla.info.text])
		taquilla.cerrar()
	print("Taquilla cerrada: juego en pausa %s (esperado: false)" % get_tree().paused)
	var vuelta := []
	var s := ""
	for i in Skins.LISTA.size() + 1:
		s = Skins.siguiente(s)
		vuelta.append(Skins.nombre(s))
	print("Tecla Z: %s (esperado: El portero > El glotón > El gymbro > El bombero > Conserje)" % " > ".join(vuelta))

	# ── La cara: las 8 direcciones con la fregona, y las otras armas mirando al sur (una foto por skin) ──
	johnny.position = Vector2(690, 330)
	johnny.get_node("Camara").reset_smoothing()
	johnny.hide()
	var dirs := ["s", "se", "e", "ne", "n", "no", "o", "so"]
	var armas := ["fregona", "bate", "cuchillo", "pistola", "escopeta", "mp5"]
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		var copias := []
		var hojas_bien := 0
		for i in dirs.size() + armas.size() + 1:
			var arma: String = "fregona" if i < dirs.size() else ("fregona" if i == dirs.size() else armas[i - dirs.size() - 1])
			var w: Dictionary = Armas.datos(arma)
			var copia := Node2D.new()   # los pies, como el dibujo de Johnny (sprite.position)
			if i < dirs.size():
				copia.position = johnny.position + Vector2(-350 + 100 * i, -40)
			else:
				copia.position = johnny.position + Vector2(-350 + 100 * (i - dirs.size()), 110)
			var dibujo := AnimatedSprite2D.new()
			# el último de la segunda fila, el conserje de siempre, para comparar
			dibujo.sprite_frames = Skins.hoja(w.hoja, "" if i == dirs.size() else skin)
			if dibujo.sprite_frames.resource_path.ends_with("-%s.tres" % skin):
				hojas_bien += 1
			dibujo.centered = false
			dibujo.offset = -w.pies
			dibujo.scale = Vector2(2, 2)
			dibujo.material = johnny.sprite.material.duplicate()
			copia.add_child(dibujo)
			dibujo.play("reposo_" + (dirs[i] if i < dirs.size() else "s"))
			mapa.cosas.add_child(copia)
			copias.append(copia)
		await get_tree().create_timer(0.6).timeout
		Captura.foto("captura-skins-caras.png" if skin == "portero" else "captura-skins-caras-%s.png" % skin)
		print("Foto caras: arriba %s en %s; abajo el conserje y %s con %s · sus hojas %d de %d (esperado: 14 de 14)" % [
			Skins.nombre(skin), ", ".join(dirs), Skins.nombre(skin), ", ".join(armas), hojas_bien, dirs.size() + armas.size()])
		for c in copias:
			c.queue_free()
	johnny.show()
	# andando: ponerse la skin no le corta el paso (sigue con la misma animación, en el mismo dibujo)
	johnny.vestir("")
	johnny.sprite.play("andar_e")
	johnny.sprite.set_frame_and_progress(3, 0.5)
	johnny.vestir("portero")
	print("Andando: después de ponérsela «%s», dibujo %d, en marcha %s (esperado: andar_e, 3, true) · hoja %s" % [
		johnny.sprite.animation, johnny.sprite.frame, johnny.sprite.is_playing(),
		johnny.sprite.sprite_frames.resource_path.get_file()])

	# ── El daño de la fregona ──
	johnny.coger("fregona")
	johnny.vestir("")
	var de_siempre: float = johnny.arma().dano
	johnny.vestir("portero")
	var con_portero: float = johnny.arma().dano
	johnny.coger("bate")
	var bate_portero: float = johnny.arma().dano
	johnny.vestir("")
	var bate_siempre: float = johnny.arma().dano
	print("Daño de la fregona: conserje %.1f · portero %.1f (× %.1f; esperado: × 4) · bate: conserje %.1f, portero %.1f (esperado: igual)" % [
		de_siempre, con_portero, con_portero / de_siempre, bate_siempre, bate_portero])
	# un golpe de verdad, sin críticos, a un zombi delante
	johnny.coger("fregona")
	var critico: float = johnny.stats.critico
	johnny.stats.critico = 0.0
	var quitado := {}
	for skin in ["", "portero"]:
		johnny.vestir(skin)
		var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(40, 0))
		zombi.vida = 500
		await get_tree().process_frame
		var vida_antes: float = zombi.vida
		johnny.golpear(0.0)
		quitado[skin] = vida_antes - zombi.vida
		zombi.queue_free()
		await get_tree().process_frame
	johnny.stats.critico = critico
	print("Un golpe de fregona a un zombi: conserje le quita %d · portero %d (esperado: el cuádruple)" % [
		quitado[""], quitado["portero"]])

	# ── El daño cuerpo a cuerpo del gymbro: × 3 con todas, también las creadas en el banco; las de fuego, igual ──
	var lanza := Armas.apuntar(Recetas.crear("lanza", "verde"))
	var cuentas := []
	for arma in ["fregona", "bate", "cuchillo", lanza, "pistola", "escopeta", "mp5"]:
		johnny.coger(arma)
		johnny.vestir("")
		var siempre: float = johnny.arma().dano
		johnny.vestir("gymbro")
		cuentas.append("%s × %.1f" % [Objetos.nombre(arma), johnny.arma().dano / siempre])
	print("Daño con el gymbro: %s (esperado: × 3 las cuatro primeras, × 1 las de fuego)" % " · ".join(cuentas))
	# golpes de verdad, sin críticos, con el bate y con la lanza
	johnny.stats.critico = 0.0
	var golpes := []
	for arma in ["bate", lanza]:
		johnny.coger(arma)
		var quita := {}
		for skin in ["", "gymbro"]:
			johnny.vestir(skin)
			var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(40, 0))
			zombi.vida = 500
			await get_tree().process_frame
			var vida_antes: float = zombi.vida
			johnny.golpear(0.0)
			quita[skin] = vida_antes - zombi.vida
			zombi.queue_free()
			await get_tree().process_frame
		golpes.append("%s: conserje %d, gymbro %d" % [Objetos.nombre(arma), quita[""], quita["gymbro"]])
	johnny.stats.critico = critico
	print("Un golpe a un zombi: %s (esperado: el triple)" % " · ".join(golpes))
	johnny.coger("fregona")
	johnny.coger("pistola")
	johnny.vestir("")

	await probar_skin_bombero()

	# ── El poder del glotón: quien le hace daño lo paga ──
	var modo: String = johnny.modo
	johnny.modo = "mira"   # que Johnny no pegue solo
	var a_punto := func() -> void:   # con toda la vida y sin el parpadeo de invulnerable, para que el golpe entre
		johnny.vida = johnny.stats.vida_max
		johnny.invulnerable = 0.0
	for skin in ["", "gloton"]:
		johnny.vestir(skin)
		# un zombi normal, al lado: le da un zarpazo de verdad
		# (se sabe que le ha dado porque se queda un rato invulnerable: Caníbal le cura al morir el zombi)
		var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(46, 0))
		a_punto.call()
		for i in 300:
			if johnny.invulnerable > 0.0:
				break
			await get_tree().physics_frame
		await get_tree().process_frame
		var pego: bool = johnny.invulnerable > 0.0
		var muerto: bool = not is_instance_valid(zombi) or zombi.estado == "muerto"
		if is_instance_valid(zombi):
			zombi.queue_free()   # (que no le siga pegando)
		# el Gymbro, quieto y con su armadura: un golpe suyo y una pesa suya que le cae encima
		var gymbro: Node2D = meter_zombi("gymbro", johnny.position + Vector2(200, 0))
		await get_tree().process_frame
		gymbro.process_mode = Node.PROCESS_MODE_DISABLED
		gymbro.armadura_max = int(gymbro.vida_max * gymbro.ARMADURA)
		gymbro.armadura = gymbro.armadura_max
		var v0: int = gymbro.vida
		a_punto.call()
		johnny.recibir_dano(20, gymbro)
		var v1: int = gymbro.vida
		a_punto.call()
		var pesa := Pesa.new()
		pesa.dueno = gymbro
		pesa.desde = johnny.global_position + Vector2(80, 0)
		pesa.hasta = johnny.global_position
		pesa.vuelo = 0.2
		gymbro.get_parent().add_child(pesa)
		await get_tree().create_timer(0.5).timeout
		var v2: int = gymbro.vida
		var diez := ceili(gymbro.vida_max * 0.1)
		print("Poder del glotón, con «%s»: el zombi le pega %s y muere %s · el Gymbro (vida %d) pierde %d con su golpe y %d con su pesa, armadura %d de %d (esperado: %s)" % [
			skin, pego, muerto, gymbro.vida_max, v0 - v1, v1 - v2, gymbro.armadura, gymbro.armadura_max,
			"true, true · %d y %d, armadura entera" % [diez, diez] if skin == "gloton" else "true, false · 0 y 0, armadura entera"])
		gymbro.queue_free()
		await get_tree().process_frame
	# con el glotón, invulnerable o sin dueño: nada
	var otro: Node2D = meter_zombi("normal", johnny.position + Vector2(300, 0))
	await get_tree().process_frame
	johnny.invulnerable = 1.0
	johnny.recibir_dano(10, otro)
	var tras_invulnerable: bool = otro.estado != "muerto"
	a_punto.call()
	johnny.recibir_dano(10)
	print("Poder del glotón, invulnerable: el zombi sigue vivo %s · sin dueño (una explosión): Johnny pierde %d y nada más (esperado: true, 10 o menos)" % [
		tras_invulnerable, johnny.stats.vida_max - johnny.vida])
	otro.queue_free()
	johnny.modo = modo
	Guardado.cambiar(func(g): g.skins = []; g.skin = "")
	get_tree().quit()


# La skin del bombero (skins.gd), dentro de probar_skins(). Johnny en el despacho, sin pegar ni disparar solo y sin
# críticos:
#   - el daño contado: × 3 las armas que queman (el bate de fuego, el lanzallamas, el súpersoplete, y lo que queman el
#     molotov y la bomba de aceite) y × 1 las seis de siempre
#   - de verdad, a un zombi quieto delante: el golpe o el disparo y lo que sigue ardiendo después, sin la skin y con
#     ella (con el bate y la pistola, igual y sin arder); y un molotov de verdad
#   - inmune al fuego, de verdad, sin la skin y con ella: el fuego del suelo (lo que hace cada paso al pisarlo) y lo
#     que sigue ardiendo al salir, un charco de molotov a sus pies (con la skin, captura-skins-bombero-fuego.png), los
#     molotovs, el cono y las bolas de fuego del jefe de bomberos; y su hachazo, que sí le quita
func probar_skin_bombero() -> void:
	var modo: String = johnny.modo
	johnny.modo = "mira"   # que Johnny no pegue ni dispare solo
	var critico: float = johnny.stats.critico
	johnny.stats.critico = 0.0
	johnny.direccion = "e"
	var queman := {}
	for r in ["bate_fuego", "lanzallamas", "supersoplete"]:
		queman[r] = Armas.apuntar(Recetas.crear(r, "verde"))
	# ── contado ──
	var cuentas := []
	for arma in ["fregona", "bate", "cuchillo", "pistola", "escopeta", "mp5", queman.bate_fuego, queman.lanzallamas,
			queman.supersoplete]:
		johnny.coger(arma)
		johnny.vestir("")
		var siempre: float = johnny.arma().dano
		johnny.vestir("bombero")
		cuentas.append("%s × %.1f" % [Objetos.nombre(arma), johnny.arma().dano / siempre])
	print("Daño con el bombero: %s (esperado: × 1 las seis de siempre, × 3 las tres que queman)" % " · ".join(cuentas))
	var lanzados := []
	for tipo in ["molotov", "bomba_aceite"]:
		var cuanto := {}
		for skin in ["", "bombero"]:
			johnny.vestir(skin)
			if tipo == "molotov":
				lanzables.cantidades.molotov = maxi(lanzables.cantidades.molotov, 1)
			else:
				lanzables.sacar(Recetas.crear("bomba_aceite", "verde"))
			lanzables.tipo = tipo
			lanzables.lanzar(johnny.global_position + Vector2(-200, 100))
			var p: Node = johnny.get_parent().get_children().filter(func(n): return n.get("hasta") != null and n.get("dano_lanzar") != null).back()
			cuanto[skin] = p.dano_lanzar
			p.queue_free()   # (que no caiga: solo se mira lo que quemará)
		lanzados.append("%s × %.1f" % [lanzables.nombre(tipo), cuanto.bombero / cuanto[""]])
	lanzables.tipo = "molotov"
	print("Lo que quema lo que se lanza, con el bombero: %s (esperado: × 3 los dos)" % " · ".join(lanzados))

	# ── de verdad: el golpe o el disparo, y lo que sigue ardiendo el zombi ──
	var de_verdad := []
	for arma in [queman.bate_fuego, queman.lanzallamas, queman.supersoplete, "bate", "pistola"]:
		johnny.coger(arma)
		var cuerpo: bool = Armas.datos(arma).tipo == "cuerpo"
		var quita := {}
		for skin in ["", "bombero"]:
			johnny.vestir(skin)
			johnny.balas = 50
			# (a distancia, justo delante de la boca: que le den las nueve gotas del súpersoplete)
			var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(50 if cuerpo else 80, 0))
			zombi.vida = 2000
			await get_tree().process_frame
			zombi.aturdido = 5.0   # quieto, delante
			var vida_antes: int = zombi.vida
			johnny.direccion = "e"
			if cuerpo:
				johnny.golpear(0.0)
			else:
				johnny.disparar(0.0)
				await get_tree().create_timer(0.3).timeout   # (lo que tarda en llegar)
			var golpe: int = vida_antes - zombi.vida
			zombi.position = johnny.position + Vector2(220, 0)   # lejos mientras arde (pegado a Johnny, algo le pellizca)
			await get_tree().create_timer(2.6).timeout
			quita[skin] = [golpe, vida_antes - zombi.vida - golpe]
			zombi.queue_free()
			await get_tree().process_frame
		de_verdad.append("%s: golpe %d → %d, ardiendo %d → %d" % [Objetos.nombre(arma), quita[""][0], quita.bombero[0],
			quita[""][1], quita.bombero[1]])
	print("De verdad a un zombi, sin la skin → con el bombero: %s (esperado: el triple las tres que queman, redondeando cada gota; el bate y la pistola, igual y sin arder)" % " · ".join(de_verdad))
	var molotov := {}
	for skin in ["", "bombero"]:
		johnny.vestir(skin)
		var zombi: Node2D = meter_zombi("normal", johnny.position + Vector2(170, 0))
		zombi.vida = 2000
		await get_tree().process_frame
		zombi.aturdido = 6.0
		lanzables.cantidades.molotov = maxi(lanzables.cantidades.molotov, 1)
		lanzables.tipo = "molotov"
		var vida_antes: int = zombi.vida
		lanzables.lanzar(zombi.global_position)
		await get_tree().create_timer(3.0).timeout
		molotov[skin] = vida_antes - zombi.vida
		zombi.queue_free()
		for c in get_tree().get_nodes_in_group("charcos"):
			c.queue_free()
		await get_tree().process_frame
	print("Un molotov de verdad a un zombi quieto: en 3 s le quita %d sin la skin y %d con el bombero (× %.1f; esperado: × 3, más o menos)" % [
		molotov[""], molotov.bombero, molotov.bombero / maxf(1.0, molotov[""])])

	# ── inmune al fuego (que los que le acompañan no le disparen al jefe) ──
	var aliados: Array = get_tree().get_nodes_in_group("aliados")
	for a in aliados:
		a.process_mode = Node.PROCESS_MODE_DISABLED
	var puesto: Vector2 = johnny.position
	var jefe: Node2D = meter_zombi("bombero", puesto + Vector2(-160, 0))   # (en el despacho: a la derecha está la pared)
	await get_tree().create_timer(0.2).timeout
	jefe.process_mode = Node.PROCESS_MODE_DISABLED   # quieto: lo que hace, se le manda
	$Pantalla/Jefa.hide()
	var a_punto := func() -> void:   # en su sitio, con toda la vida, sin parpadeo y sin arder
		johnny.position = puesto
		johnny.velocity = Vector2.ZERO
		johnny.vida = johnny.stats.vida_max
		johnny.invulnerable = 0.0
		johnny.estados.clear()
		johnny.estado_dano = 0.0
	var pierde := func() -> int:
		return johnny.stats.vida_max - johnny.vida
	for skin in ["", "bombero"]:
		johnny.vestir(skin)
		var r := {}
		# el fuego del suelo (la cocina, el cerco de la sala del jefe): lo que le hace a cada paso mientras lo pisa
		a_punto.call()
		for i in 60:
			johnny.pisar({"fuego": {"dps": Peligros.FUEGO.dps}})
			await get_tree().physics_frame
		r.suelo = pierde.call()
		r.ardiendo = johnny.estados.has("fuego")
		await get_tree().create_timer(1.0).timeout
		r.sigue = pierde.call() - r.suelo
		# un charco de fuego de molotov a sus pies
		a_punto.call()
		var charco: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
		charco.tipo = "fuego"
		charco.position = johnny.position
		johnny.get_parent().add_child(charco)
		await get_tree().create_timer(1.5).timeout
		if skin == "bombero":
			Captura.foto("captura-skins-bombero-fuego.png")
		r.charco = pierde.call()
		charco.queue_free()
		# los molotovs del jefe, encima (la botella y su fuego)
		a_punto.call()
		jefe.lanzar_molotovs(johnny)
		await get_tree().create_timer(1.8).timeout
		r.molotov = pierde.call()
		for c in get_tree().get_nodes_in_group("charcos"):
			c.queue_free()
		# su cono, 1 s apuntándole
		a_punto.call()
		var a: float = (johnny.global_position - jefe.global_position).angle()
		var puntas := []
		puntas.resize(jefe.RAYOS + 1)
		puntas.fill(150.0)
		for i in 60:
			jefe.quemar_cono(a, johnny, puntas)
			await get_tree().physics_frame
		r.cono = pierde.call()
		# sus bolas de fuego
		a_punto.call()
		jefe.mirada = (johnny.global_position - jefe.global_position).normalized()
		jefe.lanzar_bolas(johnny)
		await get_tree().create_timer(1.2).timeout
		r.bolas = pierde.call()
		# y su hachazo, de cerca
		a_punto.call()
		jefe.position = puesto + Vector2(-50, 0)
		jefe.mirada = Vector2.RIGHT
		jefe.dar_hachazo(johnny)
		r.hacha = pierde.call()
		jefe.position = puesto + Vector2(-160, 0)
		print("Inmune al fuego, con «%s»: pisando fuego 1 s pierde %d · ardiendo %s, y al salir %d más en 1 s · un charco de molotov 1,5 s, %d · los molotovs del jefe, %d · su cono 1 s, %d · sus bolas, %d · su hachazo, %d (esperado: %s)" % [
			skin, r.suelo, r.ardiendo, r.sigue, r.charco, r.molotov, r.cono, r.bolas, r.hacha,
			"0 · false, 0 · 0 · 0 · 0 · 0 · más de 0" if skin == "bombero" else "más de 0 en todo y ardiendo true"])
	a_punto.call()
	jefe.queue_free()
	for a in aliados:
		if is_instance_valid(a):
			a.process_mode = Node.PROCESS_MODE_INHERIT
	johnny.stats.critico = critico
	johnny.modo = modo
	johnny.coger("fregona")
	johnny.coger("pistola")
	johnny.vestir("")
	await get_tree().process_frame


# Con "--captura --lanza": la lanza con su dibujo propio (Armas.CREADAS.lanza, conserje-48-lanza; recetas.gd, su icono).
# En la sala de mantenimiento, con dos lanzas en el baúl (una guardada antes de que tuviera icono propio, con el de la
# fregona), Johnny se arrima al baúl y cuenta el icono de cada una (captura-lanza-baul.png). Saca una y cuenta su hoja,
# su momento del golpe y que ya no le salen chispitas; le da una estocada a un zombi a 80 de distancia (con la fregona
# no llegaría) y luego ataca en las 8 direcciones, con una foto de cada una justo en el golpe
# (captura-lanza-<dirección>.png). Con la skin del bombero puesta, su hoja de la lanza y una foto
# (captura-lanza-bombero.png). Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_lanza() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("lanza", "azul")
	vieja.icono = "fregona"   # como las que se crearon antes de que la lanza tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("lanza", "morada")]
		g2.skins = ["bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos de las lanzas %s (esperado: true, [\"lanza\", \"lanza\"]) · en el banco «%s» (esperado: lanza)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("lanza")])
	Captura.foto("captura-lanza-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacada del baúl: su hoja, sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no ataque por su cuenta: aquí ataca la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Lanza en la mano: hoja «%s» · momento %.3f · chispitas %s · icono «%s» (esperado: conserje-48-lanza.tres, 0.222, false, lanza)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.momento, w.has("detalle"), Objetos.icono(id)])

	# la estocada llega lejos: un zombi a 80 (el alcance de la lanza es 96; el de la fregona, 62)
	var z := zombis_de_prueba([Vector2(80, 0)])
	await get_tree().process_frame
	johnny.atacar(0.0)
	await get_tree().create_timer(0.6).timeout
	print("Estocada a 80: vida del zombi %d (esperado: menos de 500)" % z[0].vida)
	zombis_de_prueba([])

	# las 8 direcciones, con una foto en el golpe (llega a los 0,111 s: 0,5 × 0,222)
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.13).timeout
		Captura.foto("captura-lanza-%s.png" % d)
		await get_tree().create_timer(0.5).timeout

	# con la skin del bombero: su hoja de la lanza
	Skins.poner("bombero")
	johnny.vestir("bombero")
	johnny.direccion = "e"
	johnny.atacar(0.0)
	await get_tree().create_timer(0.13).timeout
	Captura.foto("captura-lanza-bombero.png")
	print("Con el bombero: hoja «%s» (esperado: conserje-48-lanza-bombero.tres)" % johnny.sprite.sprite_frames.resource_path.get_file())
	await get_tree().create_timer(0.5).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --aplastacabezas": el aplastacabezas con su dibujo propio (Armas.CREADAS.aplastacabezas,
# conserje-48-aplastacabezas; recetas.gd, su icono). Como la de la lanza: en la sala de mantenimiento, con dos en el
# baúl (una guardada antes de que tuviera icono propio, con el del bate), Johnny se arrima al baúl y cuenta el icono de
# cada una (captura-aplastacabezas-baul.png). Saca una y cuenta su hoja, su momento del golpe y que ya no le salen
# chispitas; le da a un zombi a 50 a su izquierda (lo aturde y lo echa atrás) y luego ataca en las 8 direcciones, con una
# foto de cada una justo en el golpe (captura-aplastacabezas-<dirección>.png). Con la skin del portero, su hoja y una
# foto (captura-aplastacabezas-portero.png). Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_aplastacabezas() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("aplastacabezas", "azul")
	vieja.icono = "bate"   # como las que se crearon antes de que el aplastacabezas tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("aplastacabezas", "morada")]
		g2.skins = ["portero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"aplastacabezas\", \"aplastacabezas\"]) · en el banco «%s» (esperado: aplastacabezas)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("aplastacabezas")])
	Captura.foto("captura-aplastacabezas-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no ataque por su cuenta: aquí ataca la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Aplastacabezas en la mano: hoja «%s» · momento %.3f · chispitas %s · icono «%s» (esperado: conserje-48-aplastacabezas.tres, 0.222, false, aplastacabezas)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.momento, w.has("detalle"), Objetos.icono(id)])

	# el golpe llega en su fotograma (a los 0,111 s: 0,5 × 0,222), aturde y echa atrás (el zombi, a la izquierda:
	# a la derecha hay una pared muy cerca y no le deja salir despedido)
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-50, 0)])
	await get_tree().process_frame
	johnny.atacar(PI)
	await get_tree().create_timer(0.2).timeout
	print("Golpe a 50: vida del zombi %d (esperado: menos de 500) · aturdido %s (esperado: true) · a %.0f de Johnny (esperado: más de 50)" % [
		z[0].vida, z[0].aturdido > 0.0, z[0].position.distance_to(johnny.position)])
	await get_tree().create_timer(0.4).timeout
	zombis_de_prueba([])

	# las 8 direcciones, con una foto en el golpe
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.13).timeout
		Captura.foto("captura-aplastacabezas-%s.png" % d)
		await get_tree().create_timer(0.5).timeout

	# con la skin del portero: su hoja del aplastacabezas
	Skins.poner("portero")
	johnny.vestir("portero")
	johnny.direccion = "e"
	johnny.atacar(0.0)
	await get_tree().create_timer(0.13).timeout
	Captura.foto("captura-aplastacabezas-portero.png")
	print("Con el portero: hoja «%s» (esperado: conserje-48-aplastacabezas-portero.tres)" % johnny.sprite.sprite_frames.resource_path.get_file())
	await get_tree().create_timer(0.5).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --bate-fuego": el bate de fuego con su dibujo propio (Armas.CREADAS.bate_fuego,
# conserje-48-bate-fuego; recetas.gd, su icono). Como la del aplastacabezas: en la sala de mantenimiento, con dos en el
# baúl (una guardada antes de que tuviera icono propio, con el del bate), Johnny se arrima al baúl y cuenta el icono de
# cada una (captura-bate-fuego-baul.png). Saca una y cuenta su hoja, su momento del golpe y que ya no le salen
# chispitas; le da a un zombi a 50 a su izquierda (le quita vida y lo prende) y luego ataca en las 8 direcciones, con
# una foto de cada una justo en el golpe (captura-bate-fuego-<dirección>.png). Con cada skin (portero, glotón, gymbro y
# bombero), su hoja y una foto (captura-bate-fuego-<skin>.png). Cada línea dice lo esperado. Deja el guardado como
# estaba y se cierra
func probar_bate_fuego() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("bate_fuego", "azul")
	vieja.icono = "bate"   # como las que se crearon antes de que el bate de fuego tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("bate_fuego", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"bate_fuego\", \"bate_fuego\"]) · en el banco «%s» (esperado: bate_fuego)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("bate_fuego")])
	Captura.foto("captura-bate-fuego-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no ataque por su cuenta: aquí ataca la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Bate de fuego en la mano: hoja «%s» · momento %.3f · chispitas %s · icono «%s» (esperado: conserje-48-bate-fuego.tres, 0.222, false, bate_fuego)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.momento, w.has("detalle"), Objetos.icono(id)])

	# el golpe llega en su fotograma (a los 0,111 s: 0,5 × 0,222), le quita vida y lo prende
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-50, 0)])
	await get_tree().process_frame
	johnny.atacar(PI)
	await get_tree().create_timer(0.2).timeout
	print("Golpe a 50: vida del zombi %d (esperado: menos de 500) · ardiendo %s (esperado: true)" % [z[0].vida, z[0].arder_t > 0.0])
	await get_tree().create_timer(0.4).timeout
	zombis_de_prueba([])

	# las 8 direcciones, con una foto en el golpe
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.13).timeout
		Captura.foto("captura-bate-fuego-%s.png" % d)
		await get_tree().create_timer(0.5).timeout

	# con cada skin: su hoja del bate de fuego
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.13).timeout
		Captura.foto("captura-bate-fuego-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-bate-fuego-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.5).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --partecuerpos": el partecuerpos con su dibujo propio (Armas.CREADAS.partecuerpos,
# conserje-48-partecuerpos; recetas.gd, su icono). Como la del bate de fuego: en la sala de mantenimiento, con dos en el
# baúl (una guardada antes de que tuviera icono propio, con el del bate), Johnny se arrima al baúl y cuenta el icono de
# cada una (captura-partecuerpos-baul.png). Saca una y cuenta su hoja, su momento del golpe y que ya no le salen
# chispitas; le da a un zombi a 50 a su izquierda (le quita vida y lo deja sangrando: la herida de armas_creadas.gd) y
# luego ataca en las 8 direcciones, con una foto de cada una justo en el golpe (captura-partecuerpos-<dirección>.png).
# Con cada skin (portero, glotón, gymbro y bombero), su hoja y una foto (captura-partecuerpos-<skin>.png). Cada línea
# dice lo esperado. Deja el guardado como estaba y se cierra
func probar_partecuerpos() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("partecuerpos", "azul")
	vieja.icono = "bate"   # como las que se crearon antes de que el partecuerpos tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("partecuerpos", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"partecuerpos\", \"partecuerpos\"]) · en el banco «%s» (esperado: partecuerpos)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("partecuerpos")])
	Captura.foto("captura-partecuerpos-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no ataque por su cuenta: aquí ataca la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Partecuerpos en la mano: hoja «%s» · momento %.3f · arco %.0f · chispitas %s · icono «%s» (esperado: conserje-48-partecuerpos.tres, 0.222, 170, false, partecuerpos)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.momento, w.arco, w.has("detalle"), Objetos.icono(id)])

	# el golpe llega en su fotograma (a los 0,111 s: 0,5 × 0,222), le quita vida y lo deja sangrando
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-50, 0)])
	await get_tree().process_frame
	johnny.atacar(PI)
	await get_tree().create_timer(0.2).timeout
	var vida_golpe: int = z[0].vida
	print("Golpe a 50: vida del zombi %d (esperado: menos de 500) · sangrando %s (esperado: true)" % [
		vida_golpe, z[0].get_node_or_null("herida_sangra") != null])
	await get_tree().create_timer(1.0).timeout
	print("Un segundo después: vida del zombi %d (esperado: menos de %d, por la herida)" % [z[0].vida, vida_golpe])
	zombis_de_prueba([])

	# las 8 direcciones, con una foto en el golpe
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.13).timeout
		Captura.foto("captura-partecuerpos-%s.png" % d)
		await get_tree().create_timer(0.5).timeout

	# con cada skin: su hoja del partecuerpos
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.13).timeout
		Captura.foto("captura-partecuerpos-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-partecuerpos-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.5).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --inmovilizadora": la inmovilizadora con su dibujo propio (Armas.CREADAS.inmovilizadora,
# conserje-48-inmovilizadora; recetas.gd, su icono). Como la del partecuerpos: en la sala de mantenimiento, con dos en el
# baúl (una guardada antes de que tuviera icono propio, con el del táser), Johnny se arrima al baúl y cuenta el icono de
# cada una (captura-inmovilizadora-baul.png). Saca una y cuenta su hoja, su momento del golpe y que ya no le salen
# chispitas; le da a un zombi a 50 a su izquierda (le quita vida y lo aturde) con otro a 140 detrás, a donde salta la
# descarga (también pierde vida y se queda aturdido, sin que el golpe lo alcance) y luego ataca en las 8 direcciones,
# con una foto de cada una justo en el golpe (captura-inmovilizadora-<dirección>.png). Con cada skin (portero, glotón,
# gymbro y bombero), su hoja y una foto (captura-inmovilizadora-<skin>.png). Cada línea dice lo esperado. Deja el
# guardado como estaba y se cierra
func probar_inmovilizadora() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("inmovilizadora", "azul")
	vieja.icono = "taser"   # como las que se crearon antes de que la inmovilizadora tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("inmovilizadora", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"inmovilizadora\", \"inmovilizadora\"]) · en el banco «%s» (esperado: inmovilizadora)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("inmovilizadora")])
	Captura.foto("captura-inmovilizadora-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no ataque por su cuenta: aquí ataca la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Inmovilizadora en la mano: hoja «%s» · momento %.3f · chispitas %s · icono «%s» (esperado: conserje-48-inmovilizadora.tres, 0.222, false, inmovilizadora)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.momento, w.has("detalle"), Objetos.icono(id)])

	# el golpe llega en su fotograma (a los 0,111 s: 0,5 × 0,222), le quita vida y lo aturde; la descarga salta al
	# otro, que está fuera del alcance del bate (66) pero a menos de 130 del primero
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-50, 0), Vector2(-140, 0)])
	await get_tree().process_frame
	johnny.atacar(PI)
	await get_tree().create_timer(0.2).timeout
	print("Golpe a 50: vida del zombi %d (esperado: menos de 500) · aturdido %s (esperado: true)" % [
		z[0].vida, z[0].aturdido > 0.0])
	print("Salto a 140: vida del otro %d (esperado: menos de 500) · aturdido %s (esperado: true)" % [
		z[1].vida, z[1].aturdido > 0.0])
	await get_tree().create_timer(0.4).timeout
	zombis_de_prueba([])

	# las 8 direcciones, con una foto en el golpe
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.13).timeout
		Captura.foto("captura-inmovilizadora-%s.png" % d)
		await get_tree().create_timer(0.5).timeout

	# con cada skin: su hoja de la inmovilizadora
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.13).timeout
		Captura.foto("captura-inmovilizadora-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-inmovilizadora-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.5).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --latigo": el látigo escorpión con su dibujo propio (Armas.CREADAS.latigo, conserje-48-latigo, de casilla
# más grande: pies en 72,88; recetas.gd, su icono). Como la de la inmovilizadora: en la sala de mantenimiento, con dos en
# el baúl (una guardada antes de que tuviera icono propio, con el de la cuerda), Johnny se arrima al baúl y cuenta el
# icono de cada una (captura-latigo-baul.png). Saca una y cuenta su hoja, su momento del golpe, sus pies y que ya no le
# salen chispitas; le da a un zombi a 100 a su izquierda (más lejos de lo que llega el cuchillo, que son 46: le quita
# vida y lo deja envenenado: la herida de armas_creadas.gd) y luego ataca en las 8 direcciones, con una foto de cada
# una justo en el golpe (captura-latigo-<dirección>.png). Con cada skin (portero, glotón, gymbro y bombero), su hoja y
# una foto (captura-latigo-<skin>.png). Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_latigo() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("latigo", "azul")
	vieja.icono = "cuerda"   # como las que se crearon antes de que el látigo tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("latigo", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"latigo\", \"latigo\"]) · en el banco «%s» (esperado: latigo)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("latigo")])
	Captura.foto("captura-latigo-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no ataque por su cuenta: aquí ataca la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Látigo en la mano: hoja «%s» · momento %.3f · alcance %.0f · pies %s · chispitas %s · icono «%s» (esperado: conserje-48-latigo.tres, 0.333, 110, (72, 88), false, latigo)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.momento, w.alcance, w.pies, w.has("detalle"), Objetos.icono(id)])

	# el golpe llega en su fotograma (a los 0,08 s: 0,2375 × 0,333), le quita vida a 100 (más que el cuchillo) y lo envenena
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-100, 0)])
	await get_tree().process_frame
	johnny.atacar(PI)
	await get_tree().create_timer(0.2).timeout
	var vida_golpe: int = z[0].vida
	print("Golpe a 100: vida del zombi %d (esperado: menos de 500) · envenenado %s (esperado: true)" % [
		vida_golpe, z[0].get_node_or_null("herida_veneno") != null])
	await get_tree().create_timer(1.0).timeout
	print("Un segundo después: vida del zombi %d (esperado: menos de %d, por el veneno)" % [z[0].vida, vida_golpe])
	zombis_de_prueba([])

	# las 8 direcciones, con una foto en el golpe
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.1).timeout
		Captura.foto("captura-latigo-%s.png" % d)
		await get_tree().create_timer(0.5).timeout

	# con cada skin: su hoja del látigo
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.1).timeout
		Captura.foto("captura-latigo-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-latigo-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.5).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --supermaza": la súper maza con su dibujo propio (Armas.CREADAS.supermaza, conserje-48-supermaza, de
# casilla más grande: pies en 64,79; recetas.gd, su icono). Como la del látigo: en la sala de mantenimiento, con dos en
# el baúl (una guardada antes de que tuviera icono propio, con el de las mancuernas), Johnny se arrima al baúl y cuenta
# el icono de cada una (captura-supermaza-baul.png). Saca una y cuenta su hoja, su momento del golpe, sus pies y que ya
# no le salen chispitas; pone un zombi a cada lado (izquierda, derecha, arriba y abajo, a 45) y otro lejos (a 160),
# ataca hacia la izquierda y cuenta que el golpe en círculo (arco 360) le quita vida a los cuatro de alrededor y al
# lejano no (con una foto justo en el golpe, captura-supermaza-circulo.png); luego ataca en las 8 direcciones, con una
# foto de cada una justo en el golpe (captura-supermaza-<dirección>.png). Con cada skin (portero, glotón, gymbro y
# bombero), su hoja y una foto (captura-supermaza-<skin>.png). Cada línea dice lo esperado. Deja el guardado como
# estaba y se cierra
func probar_supermaza() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("supermaza", "azul")
	vieja.icono = "mancuernas"   # como las que se crearon antes de que la súper maza tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("supermaza", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"supermaza\", \"supermaza\"]) · en el banco «%s» (esperado: supermaza)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("supermaza")])
	Captura.foto("captura-supermaza-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacada del baúl: su hoja, sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no ataque por su cuenta: aquí ataca la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Súper maza en la mano: hoja «%s» · momento %.3f · alcance %.0f · arco %.0f · pies %s · chispitas %s · icono «%s» (esperado: conserje-48-supermaza.tres, 0.300, 62, 360, (64, 79), false, supermaza)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.momento, w.alcance, w.arco, w.pies, w.has("detalle"), Objetos.icono(id)])

	# el golpe en círculo: llega en su fotograma (a los 0,15 s: 0,5 × 0,3) y pega a los de todos los lados, no al lejano
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-45, 0), Vector2(45, 0), Vector2(0, -45), Vector2(0, 45), Vector2(160, 0)])
	await get_tree().process_frame
	johnny.atacar(PI)
	await get_tree().create_timer(0.17).timeout
	Captura.foto("captura-supermaza-circulo.png")
	await get_tree().create_timer(0.2).timeout
	var vidas := z.map(func(o): return o.vida)
	print("Golpe en círculo: vidas de los zombis (izquierda, derecha, arriba, abajo, lejos) %s (esperado: los cuatro primeros menos de 500 y el último, 500)" % [vidas])
	zombis_de_prueba([])

	# las 8 direcciones, con una foto en el golpe
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.17).timeout
		Captura.foto("captura-supermaza-%s.png" % d)
		await get_tree().create_timer(0.5).timeout

	# con cada skin: su hoja de la súper maza
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.17).timeout
		Captura.foto("captura-supermaza-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-supermaza-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.5).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --mangual": el mangual con su dibujo propio (Armas.CREADAS.mangual, conserje-48-mangual, de casilla
# grande: pies en 72,88; recetas.gd, su icono). Como la súper maza: en la sala de mantenimiento, con dos en el baúl (una
# guardada antes de que tuviera icono propio, con el de la cadena), Johnny se arrima al baúl y cuenta el icono de cada una
# (captura-mangual-baul.png). Saca una y cuenta su hoja, su momento del golpe, sus pies, su alcance y que ya no le salen
# chispitas; pone un zombi a cada lado (izquierda, derecha, arriba y abajo, a 80) y otro lejos (a 200), ataca hacia la
# izquierda y cuenta que el giro (arco 360) le quita vida a los cuatro de alrededor, los deja aturdidos y los echa lejos,
# y al lejano ni lo toca (con una foto justo en el golpe, captura-mangual-circulo.png); luego ataca en las 8 direcciones,
# con una foto de cada una justo en el golpe (captura-mangual-<dirección>.png). Con cada skin (portero, glotón, gymbro
# y bombero), su hoja y una foto (captura-mangual-<skin>.png). Cada línea dice lo esperado. Deja el guardado como estaba
# y se cierra
func probar_mangual() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("mangual", "azul")
	vieja.icono = "cadena"   # como las que se crearon antes de que el mangual tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("mangual", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"mangual\", \"mangual\"]) · en el banco «%s» (esperado: mangual)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("mangual")])
	Captura.foto("captura-mangual-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no ataque por su cuenta: aquí ataca la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Mangual en la mano: hoja «%s» · momento %.3f · alcance %.0f · arco %.0f · pies %s · chispitas %s · icono «%s» (esperado: conserje-48-mangual.tres, 0.300, 90, 360, (72, 88), false, mangual)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.momento, w.alcance, w.arco, w.pies, w.has("detalle"), Objetos.icono(id)])

	# el giro: llega en su fotograma (a los 0,15 s: 0,5 × 0,3), pega a los de todos los lados, los aturde y los echa lejos;
	# el lejano ni lo toca
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-80, 0), Vector2(80, 0), Vector2(0, -80), Vector2(0, 80), Vector2(200, 0)])
	await get_tree().process_frame
	johnny.atacar(PI)
	await get_tree().create_timer(0.17).timeout
	Captura.foto("captura-mangual-circulo.png")
	await get_tree().create_timer(0.2).timeout
	print("Giro del mangual: vidas (izquierda, derecha, arriba, abajo, lejos) %s (esperado: los cuatro primeros menos de 500 y el último, 500)" % [z.map(func(o): return o.vida)])
	print("  aturdidos %s (esperado: cuatro true y false) · distancias a Johnny %s (esperado: izquierda, derecha y arriba, echados a más de 150; abajo, contra la pared, a menos; el último, 200)" % [
		z.map(func(o): return o.aturdido > 0.0), z.map(func(o): return roundi(o.distancia_a(johnny)))])
	zombis_de_prueba([])

	# las 8 direcciones, con una foto en el golpe
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.17).timeout
		Captura.foto("captura-mangual-%s.png" % d)
		await get_tree().create_timer(0.5).timeout

	# con cada skin: su hoja del mangual
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.17).timeout
		Captura.foto("captura-mangual-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-mangual-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.5).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --bate-helado": el bate helado con su dibujo propio (Armas.CREADAS.bate_helado, conserje-48-bate-helado;
# recetas.gd, su icono). Como la de la inmovilizadora: en la sala de mantenimiento, con dos en el baúl (una guardada antes
# de que tuviera icono propio, con el del hielo seco), Johnny se arrima al baúl y cuenta el icono de cada una
# (captura-bate-helado-baul.png). Saca una y cuenta su hoja, su momento del golpe y que ya no le salen chispitas; le da a
# un zombi a 50 a su izquierda (le quita vida y lo congela) con otro a 140 detrás, fuera de su alcance (ni lo toca ni lo
# congela; con una foto justo en el golpe, captura-bate-helado-congela.png) y luego ataca en las 8 direcciones, con una
# foto de cada una justo en el golpe (captura-bate-helado-<dirección>.png). Con cada skin (portero, glotón, gymbro y
# bombero), su hoja y una foto (captura-bate-helado-<skin>.png). Cada línea dice lo esperado. Deja el guardado como
# estaba y se cierra
func probar_bate_helado() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("bate_helado", "azul")
	vieja.icono = "hielo_seco"   # como las que se crearon antes de que el bate helado tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("bate_helado", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"bate_helado\", \"bate_helado\"]) · en el banco «%s» (esperado: bate_helado)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("bate_helado")])
	Captura.foto("captura-bate-helado-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no ataque por su cuenta: aquí ataca la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Bate helado en la mano: hoja «%s» · momento %.3f · chispitas %s · icono «%s» (esperado: conserje-48-bate-helado.tres, 0.222, false, bate_helado)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.momento, w.has("detalle"), Objetos.icono(id)])

	# el golpe llega en su fotograma (a los 0,111 s: 0,5 × 0,222), le quita vida y lo congela; el otro, a 140, queda fuera
	# del alcance del bate (66) y ni lo toca ni lo congela
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-50, 0), Vector2(-140, 0)])
	await get_tree().process_frame
	johnny.atacar(PI)
	await get_tree().create_timer(0.17).timeout
	Captura.foto("captura-bate-helado-congela.png")
	print("Golpe a 50: vida del zombi %d (esperado: menos de 500) · congelado %.2f (esperado: más de 0)" % [
		z[0].vida, z[0].congelado])
	print("Zombi a 140: vida %d · congelado %.2f (esperado: 500 y 0)" % [z[1].vida, z[1].congelado])
	await get_tree().create_timer(0.4).timeout
	zombis_de_prueba([])

	# las 8 direcciones, con una foto en el golpe
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.13).timeout
		Captura.foto("captura-bate-helado-%s.png" % d)
		await get_tree().create_timer(0.5).timeout

	# con cada skin: su hoja del bate helado
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.13).timeout
		Captura.foto("captura-bate-helado-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-bate-helado-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.5).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --latigo-electrico": el látigo eléctrico con su dibujo propio (Armas.CREADAS.latigo_electrico,
# conserje-48-latigo-electrico, de casilla más grande: pies en 72,88; recetas.gd, su icono). Como la del látigo escorpión:
# en la sala de mantenimiento, con dos en el baúl (una guardada antes de que tuviera icono propio, con el del cable),
# Johnny se arrima al baúl y cuenta el icono de cada una (captura-latigo-electrico-baul.png). Saca una y cuenta su hoja,
# su momento del golpe, su alcance, sus pies y que ya no le salen chispitas; le da a un zombi a 100 a su izquierda (más
# lejos de lo que llega el cuchillo, que son 46: le quita vida y lo aturde) con otro a 134 de Johnny pero fuera del
# abanico del látigo (a 90 del primero: la descarga salta hasta él, que pierde vida y se queda aturdido sin que el golpe
# lo alcance) y un tercero lejos de los dos (no le pasa nada); con una foto justo en el golpe
# (captura-latigo-electrico-descarga.png). Luego ataca en las 8 direcciones, con una foto de cada una justo en el golpe
# (captura-latigo-electrico-<dirección>.png). Con cada skin (portero, glotón, gymbro y bombero), su hoja y una foto
# (captura-latigo-electrico-<skin>.png). Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_latigo_electrico() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("latigo_electrico", "azul")
	vieja.icono = "cable"   # como las que se crearon antes de que el látigo eléctrico tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("latigo_electrico", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"latigo_electrico\", \"latigo_electrico\"]) · en el banco «%s» (esperado: latigo_electrico)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("latigo_electrico")])
	Captura.foto("captura-latigo-electrico-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no ataque por su cuenta: aquí ataca la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Látigo eléctrico en la mano: hoja «%s» · momento %.3f · alcance %.0f · pies %s · chispitas %s · icono «%s» (esperado: conserje-48-latigo-electrico.tres, 0.286, 110, (72, 88), false, latigo_electrico)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.momento, w.alcance, w.pies, w.has("detalle"), Objetos.icono(id)])

	# el golpe llega en su fotograma (a los 0,07 s: 0,2375 × 0,286), le quita vida al primero a 100 (más que el cuchillo) y lo
	# aturde; la descarga salta al segundo (a 90 del primero, fuera del abanico del látigo), que se lleva medio daño y también
	# se queda aturdido; el tercero, a más de 130 de los dos, ni se entera
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-100, 0), Vector2(-100, 90), Vector2(-100, 230)])
	await get_tree().process_frame
	johnny.atacar(PI)
	await get_tree().create_timer(0.09).timeout
	Captura.foto("captura-latigo-electrico-descarga.png")
	await get_tree().create_timer(0.1).timeout
	print("Golpe a 100: vida del zombi %d (esperado: menos de 500) · aturdido %s (esperado: true)" % [
		z[0].vida, z[0].aturdido > 0.0])
	print("Salto a 90 del primero: vida del otro %d (esperado: menos de 500) · aturdido %s (esperado: true)" % [
		z[1].vida, z[1].aturdido > 0.0])
	print("Zombi lejos: vida %d · aturdido %s (esperado: 500 y false)" % [z[2].vida, z[2].aturdido > 0.0])
	await get_tree().create_timer(0.4).timeout
	zombis_de_prueba([])

	# las 8 direcciones, con una foto en el golpe
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.09).timeout
		Captura.foto("captura-latigo-electrico-%s.png" % d)
		await get_tree().create_timer(0.5).timeout

	# con cada skin: su hoja del látigo eléctrico
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.09).timeout
		Captura.foto("captura-latigo-electrico-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-latigo-electrico-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.5).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --lanzallamas": el lanzallamas con su dibujo propio (Armas.CREADAS.lanzallamas, conserje-48-lanzallamas: la
# hoja lleva el retroceso y la llamarada de la boca del tubo; casilla de 96x104; recetas.gd, su icono). Es la primera creada
# a distancia con hoja propia, así que además del icono y la hoja se comprueba la boca: en la sala de mantenimiento, con dos
# en el baúl (una guardada antes de que tuviera icono propio, con el de la pistola de agua), Johnny se arrima al baúl y cuenta
# el icono de cada una (captura-lanzallamas-baul.png). Saca una y cuenta su hoja, su ritmo, su alcance, sus pies, su boca hacia
# el este y que ya no le salen chispitas; dispara a un zombi a 120 a su izquierda (le quita vida y lo prende) con otro a 330
# en la misma línea (más lejos de lo que llega el chorro: ni se entera), con una foto justo con la llamarada y las gotas
# saliendo (captura-lanzallamas-chorro.png) y cuenta cuántas balas gasta. Luego dispara en las 8 direcciones, con una foto de
# cada una en el fotograma de la llamarada (captura-lanzallamas-<dirección>.png): la llama del dibujo y las gotas tienen que
# salir del mismo sitio. Con cada skin (portero, glotón, gymbro y bombero), su hoja y una foto
# (captura-lanzallamas-<skin>.png). Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_lanzallamas() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("lanzallamas", "azul")
	vieja.icono = "pistola_agua"   # como las que se crearon antes de que el lanzallamas tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("lanzallamas", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"lanzallamas\", \"lanzallamas\"]) · en el banco «%s» (esperado: lanzallamas)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("lanzallamas")])
	Captura.foto("captura-lanzallamas-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, su boca y sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no dispare por su cuenta: aquí dispara la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Lanzallamas en la mano: hoja «%s» · ritmo %.0f · alcance %.0f · pies %s · boca este %s · chispitas %s · icono «%s» (esperado: conserje-48-lanzallamas.tres, 10, 170, (48, 72), (34, -26), false, lanzallamas)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.ritmo, w.alcance, w.pies, w.boca.e, w.has("detalle"), Objetos.icono(id)])

	# el chorro: sale de la boca hacia la izquierda, le quita vida al primero (a 120) y lo prende; el segundo, a 330, queda
	# fuera de su alcance (170 desde la boca, que está a 68 de Johnny)
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-120, 0), Vector2(-330, 0)])
	await get_tree().process_frame
	var balas0: int = johnny.balas
	johnny.atacar(PI)
	await get_tree().create_timer(0.1).timeout
	Captura.foto("captura-lanzallamas-chorro.png")
	await get_tree().create_timer(0.5).timeout
	print("Chorro a 120: vida del zombi %d (esperado: menos de 500) · ardiendo %s (esperado: true)" % [z[0].vida, z[0].arder_t > 0.0])
	print("Zombi a 330: vida %d · ardiendo %s (esperado: 500 y false)" % [z[1].vida, z[1].arder_t > 0.0])
	print("Balas gastadas: %d (esperado: 1)" % (balas0 - johnny.balas))
	zombis_de_prueba([])
	await get_tree().create_timer(0.3).timeout

	# las 8 direcciones, con una foto en la llamarada (el disparo dura 0,095 s: el 2º de sus 3 fotogramas, a los 0,04 s)
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.04).timeout
		Captura.foto("captura-lanzallamas-%s.png" % d)
		await get_tree().create_timer(0.6).timeout

	# con cada skin: su hoja del lanzallamas
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.04).timeout
		Captura.foto("captura-lanzallamas-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-lanzallamas-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.6).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --supersoplete": el supersoplete con su dibujo propio (Armas.CREADAS.supersoplete, conserje-48-supersoplete: la
# hoja lleva el retroceso de escopeta y la llamarada en cono de la boca acampanada del soplete; casilla de 144x152, con los pies
# en 72,72; recetas.gd, su icono). Como el lanzallamas, en la sala de mantenimiento, con dos en el baúl (una guardada antes de
# que tuviera icono propio, con el del spray), Johnny se arrima al baúl y cuenta el icono de cada una
# (captura-supersoplete-baul.png). Saca una y cuenta su hoja, su ritmo, su alcance, sus pies, su boca hacia el este y que ya
# no le salen chispitas; dispara a un zombi a 60 a su izquierda (le quita vida y lo prende) con otro a 260 en la misma línea
# (más lejos de lo que llega el cono: ni se entera), con una foto justo con la llamarada y las gotas saliendo
# (captura-supersoplete-chorro.png) y cuenta cuántas balas gasta (una por disparo). Luego dispara en las 8 direcciones, con
# una foto de cada una en el fotograma de la llamarada grande (captura-supersoplete-<dirección>.png): la llama del dibujo y las
# gotas tienen que salir del mismo sitio. Con cada skin (portero, glotón, gymbro y bombero), su hoja y una foto
# (captura-supersoplete-<skin>.png). Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_supersoplete() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("supersoplete", "azul")
	vieja.icono = "spray"   # como las que se crearon antes de que el supersoplete tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("supersoplete", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"supersoplete\", \"supersoplete\"]) · en el banco «%s» (esperado: supersoplete)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("supersoplete")])
	Captura.foto("captura-supersoplete-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, su boca y sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no dispare por su cuenta: aquí dispara la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Supersoplete en la mano: hoja «%s» · ritmo %.0f · alcance %.0f · pies %s · boca este %s · chispitas %s · icono «%s» (esperado: conserje-48-supersoplete.tres, 2, 100, (72, 72), (26, -31), false, supersoplete)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.ritmo, w.alcance, w.pies, w.boca.e, w.has("detalle"), Objetos.icono(id)])

	# el cono: sale de la boca hacia la izquierda, le quita vida al primero (a 60) y lo prende; el segundo, a 260, queda
	# fuera de su alcance (100 desde la boca, que está a 54 de Johnny)
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-60, 0), Vector2(-260, 0)])
	await get_tree().process_frame
	var balas0: int = johnny.balas
	johnny.atacar(PI)
	await get_tree().create_timer(0.19).timeout
	Captura.foto("captura-supersoplete-chorro.png")
	await get_tree().create_timer(0.5).timeout
	print("Cono a 60: vida del zombi %d (esperado: menos de 500) · ardiendo %s (esperado: true)" % [z[0].vida, z[0].arder_t > 0.0])
	print("Zombi a 260: vida %d · ardiendo %s (esperado: 500 y false)" % [z[1].vida, z[1].arder_t > 0.0])
	print("Balas gastadas: %d (esperado: 1)" % (balas0 - johnny.balas))
	zombis_de_prueba([])
	await get_tree().create_timer(0.3).timeout

	# las 8 direcciones, con una foto en la llamarada grande (el disparo dura 0,46 s, 6 fotogramas: el 3º, a los 0,19 s)
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.19).timeout
		Captura.foto("captura-supersoplete-%s.png" % d)
		await get_tree().create_timer(0.7).timeout

	# con cada skin: su hoja del supersoplete
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.19).timeout
		Captura.foto("captura-supersoplete-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-supersoplete-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.7).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --desintegrador": el desintegrador con su dibujo propio (Armas.CREADAS.desintegrador, conserje-48-desintegrador: la
# hoja lleva el retroceso corto de pistola de agua y un chorrito fino de ácido verde pálido de la boquilla blanca; casilla de
# 152x136, con los pies en 66,90; recetas.gd, su icono). Como el lanzallamas, en la sala de mantenimiento, con dos en el baúl
# (una guardada antes de que tuviera icono propio, con el de la lejía), Johnny se arrima al baúl y cuenta el icono de cada una
# (captura-desintegrador-baul.png). Saca una y cuenta su hoja, su ritmo, su alcance, sus pies, su boca hacia el este y que ya no
# le salen chispitas; dispara a un zombi a 120 a su izquierda (le quita vida y le deja la herida de ácido) con otro a 330 en la
# misma línea (más lejos de lo que llega el chorro: ni se entera), con una foto con las gotas saliendo
# (captura-desintegrador-chorro.png) y cuenta cuántas balas gasta (una por disparo). Luego dispara en las 8 direcciones, con una
# foto de cada una en el segundo fotograma del disparo, el del chorro largo (captura-desintegrador-<dirección>.png): el chorro
# del dibujo y las gotas tienen que salir del mismo sitio. Con cada skin (portero, glotón, gymbro y bombero), su hoja y una foto
# (captura-desintegrador-<skin>.png). Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_desintegrador() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("desintegrador", "azul")
	vieja.icono = "lejia"   # como las que se crearon antes de que el desintegrador tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("desintegrador", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"desintegrador\", \"desintegrador\"]) · en el banco «%s» (esperado: desintegrador)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("desintegrador")])
	Captura.foto("captura-desintegrador-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, su boca y sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no dispare por su cuenta: aquí dispara la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Desintegrador en la mano: hoja «%s» · ritmo %.0f · alcance %.0f · pies %s · boca este %s · chispitas %s · icono «%s» (esperado: conserje-48-desintegrador.tres, 12, 220, (66, 90), (24, -26), false, desintegrador)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.ritmo, w.alcance, w.pies, w.boca.e, w.has("detalle"), Objetos.icono(id)])

	# el chorro: sale de la boca hacia la izquierda, le quita vida al primero (a 120) y le deja ácido; el segundo, a 330, queda
	# fuera de su alcance (220 desde la boca, que está a 46 de Johnny)
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-120, 0), Vector2(-330, 0)])
	await get_tree().process_frame
	var balas0: int = johnny.balas
	johnny.atacar(PI)
	await get_tree().create_timer(0.1).timeout
	Captura.foto("captura-desintegrador-chorro.png")
	await get_tree().create_timer(0.5).timeout
	print("Chorro a 120: vida del zombi %d (esperado: menos de 500) · con ácido %s (esperado: true)" % [z[0].vida, z[0].get_node_or_null("herida_acido") != null])
	print("Zombi a 330: vida %d · con ácido %s (esperado: 500 y false)" % [z[1].vida, z[1].get_node_or_null("herida_acido") != null])
	print("Balas gastadas: %d (esperado: 1)" % (balas0 - johnny.balas))
	zombis_de_prueba([])
	await get_tree().create_timer(0.3).timeout

	# las 8 direcciones, con una foto en el chorro largo (el disparo dura 0,08 s, 2 fotogramas: el 2º, a los 0,045 s)
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.045).timeout
		Captura.foto("captura-desintegrador-%s.png" % d)
		await get_tree().create_timer(0.6).timeout

	# con cada skin: su hoja del desintegrador
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.045).timeout
		Captura.foto("captura-desintegrador-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-desintegrador-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.6).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --bumeran": el bumerán segador con su dibujo propio (Armas.CREADAS.bumeran, conserje-48-bumeran: la hoja lleva solo el
# gesto de lanzar el bumerán de acero con el mango rojo; el que sale volando y vuelve a la mano lo dibuja el juego, bumeran.gd; casilla de
# 94x92, con los pies en 45,76; recetas.gd, su icono). Como el desintegrador, en la sala de mantenimiento, con dos en el baúl (una guardada
# antes de que tuviera icono propio, con el del hacha), Johnny se arrima al baúl y cuenta el icono de cada una (captura-bumeran-baul.png).
# Saca una y cuenta su hoja, su ritmo, su alcance, sus pies, su boca hacia el este y que ya no le salen chispitas; lanza el bumerán a un
# zombi a 120 a su izquierda con otro detrás, a 200 (los dos pierden vida: atraviesa), con otro a 420 en la misma línea (más lejos de lo que
# llega: ni se entera), y cuenta que el bumerán vuelve a la mano (se acaba solo) y que no gasta munición (captura-bumeran-lanzar.png). Lanza
# andando y cuenta que Johnny sigue andando, sin gesto y sin efectos (la hoja no los tiene). Luego lanza en las 8 direcciones, con una foto
# de cada una a los 0,05 s, con el brazo ya estirado y el bumerán de verdad saliendo de la mano (captura-bumeran-<dirección>.png). Con cada
# skin (portero, glotón, gymbro y bombero), su hoja y una foto (captura-bumeran-<skin>.png). Cada línea dice lo esperado. Deja el guardado
# como estaba y se cierra
func probar_bumeran() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("bumeran", "azul")
	vieja.icono = "hacha"   # como las que se crearon antes de que el bumerán tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("bumeran", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"bumeran\", \"bumeran\"]) · en el banco «%s» (esperado: bumeran)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("bumeran")])
	Captura.foto("captura-bumeran-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, su boca y sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no dispare por su cuenta: aquí dispara la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Bumerán en la mano: hoja «%s» · ritmo %.0f · alcance %.0f · pies %s · boca este %s · chispitas %s · icono «%s» (esperado: conserje-48-bumeran.tres, 1, 300, (45, 76), (-1, -37), false, bumeran)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.ritmo, w.alcance, w.pies, w.boca.e, w.has("detalle"), Objetos.icono(id)])

	# el lanzamiento: atraviesa al primero (a 120) y al segundo (a 200); el tercero, a 420, queda fuera de su alcance (300 desde la mano)
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-120, 0), Vector2(-200, 0), Vector2(-420, 0)])
	await get_tree().process_frame
	var balas0: int = johnny.balas
	johnny.atacar(PI)
	await get_tree().create_timer(0.35).timeout
	Captura.foto("captura-bumeran-lanzar.png")
	var volando := bumeranes_volando()
	await get_tree().create_timer(1.6).timeout
	print("Bumerán en el aire a los 0,35 s: %d (esperado: 1) · tras 1,95 s: %d (esperado: 0: volvió a la mano)" % [volando, bumeranes_volando()])
	print("Zombi a 120: vida %d · a 200: vida %d (esperado: menos de 500 los dos) · a 420: vida %d (esperado: 500)" % [z[0].vida, z[1].vida, z[2].vida])
	print("Balas gastadas: %d (esperado: 0: no gasta munición)" % (balas0 - johnny.balas))
	zombis_de_prueba([])
	await get_tree().create_timer(0.3).timeout

	# lanzar andando: sigue andando, sin gesto (sin efectos: la hoja no los tiene) ni retroceso
	johnny.direccion = "e"
	johnny.velocity = Vector2(120, 0)
	johnny.atacar(0.0)
	await get_tree().create_timer(0.1).timeout
	print("Lanzado andando: ataque_t %.1f (esperado: -1.0) · efectos visibles %s (esperado: false) · retroceso %s (esperado: (0, 0))" % [
		johnny.ataque_t, johnny.efectos.visible, johnny.patada])
	johnny.velocity = Vector2.ZERO
	quitar_bumeranes()
	await get_tree().create_timer(0.3).timeout

	# las 8 direcciones, con una foto a los 0,05 s: el brazo estirado y el bumerán saliendo de la mano
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.05).timeout
		Captura.foto("captura-bumeran-%s.png" % d)
		await get_tree().create_timer(0.5).timeout
		quitar_bumeranes()
		await get_tree().create_timer(0.2).timeout

	# con cada skin: su hoja del bumerán
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.05).timeout
		Captura.foto("captura-bumeran-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-bumeran-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.5).timeout
		quitar_bumeranes()
		await get_tree().create_timer(0.2).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Para probar_bumeran: los bumeranes que van por el aire (los que lanzó Johnny y aún no han vuelto a su mano)
func bumeranes_volando() -> int:
	return johnny.get_parent().get_children().filter(func(n): return n.get_script() == ArmasCreadas.BUMERAN).size()


func quitar_bumeranes() -> void:
	for n in johnny.get_parent().get_children():
		if n.get_script() == ArmasCreadas.BUMERAN:
			n.queue_free()


# Con "--captura --pistola-electrica": la pistola eléctrica con su dibujo propio (Armas.CREADAS.pistola_electrica,
# conserje-48-pistola-electrica: la hoja lleva el retroceso corto de pistola y una descarga celeste en zigzag que sale de los dos
# electrodos del táser azul marino; casilla de 180x168, con los pies en 90,88; recetas.gd, su icono). Como el desintegrador, en la sala
# de mantenimiento, con dos en el baúl (una guardada antes de que tuviera icono propio, con el de la batería), Johnny se arrima al
# baúl y cuenta el icono de cada una (captura-pistola-electrica-baul.png). Saca una y cuenta su hoja, su ritmo, su alcance, sus pies,
# su boca hacia el este y que ya no le salen chispitas de adorno; dispara a un zombi a 120 a su izquierda (le quita vida y lo aturde),
# con otro cerca de él (la descarga salta y lo aturde también) y otro a 330 (más lejos de lo que llega la chispa: ni se entera), con
# una foto con las chispas saliendo (captura-pistola-electrica-chispa.png) y cuenta cuántas balas gasta (una por disparo). Luego
# dispara andando (sigue andando, con los efectos del disparo pintados encima y el retroceso) y en las 8 direcciones, con una foto de
# cada una a los 0,09 s, con la descarga ya saliendo (captura-pistola-electrica-<dirección>.png): lo dibujado y las chispas del
# juego tienen que salir del mismo sitio. Con cada skin (portero, glotón, gymbro y bombero), su hoja y una foto
# (captura-pistola-electrica-<skin>.png). Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_pistola_electrica() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("pistola_electrica", "azul")
	vieja.icono = "bateria"   # como las que se crearon antes de que la pistola eléctrica tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("pistola_electrica", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"pistola_electrica\", \"pistola_electrica\"]) · en el banco «%s» (esperado: pistola_electrica)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("pistola_electrica")])
	Captura.foto("captura-pistola-electrica-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacada del baúl: su hoja, su boca y sin chispitas de adorno
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no dispare por su cuenta: aquí dispara la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Pistola eléctrica en la mano: hoja «%s» · ritmo %.0f · alcance %.0f · pies %s · boca este %s · chispitas de adorno %s · icono «%s» (esperado: conserje-48-pistola-electrica.tres, 5, 230, (90, 88), (22, -30), false, pistola_electrica)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.ritmo, w.alcance, w.pies, w.boca.e, w.has("detalle"), Objetos.icono(id)])

	# la chispa: sale de la boca hacia la izquierda, le quita vida al primero (a 120) y lo aturde, salta al que tiene cerca (a 100
	# de él: también pierde vida y se queda aturdido) y no llega al tercero, a 330 (230 desde la boca, que está a 44 de Johnny)
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-120, 0), Vector2(-200, 60), Vector2(-330, 0)])
	await get_tree().process_frame
	var balas0: int = johnny.balas
	johnny.atacar(PI)
	await get_tree().create_timer(0.12).timeout
	Captura.foto("captura-pistola-electrica-chispa.png")
	await get_tree().create_timer(0.15).timeout
	print("Aturdidos a los 0,27 s: el de 120 %s · el que está a su lado %s · el de 330 %s (esperado: true, true, false)" % [
		z[0].aturdido > 0.0, z[1].aturdido > 0.0, z[2].aturdido > 0.0])
	await get_tree().create_timer(0.4).timeout
	print("Zombi a 120: vida %d · el de al lado: vida %d (esperado: menos de 500 los dos) · a 330: vida %d (esperado: 500)" % [z[0].vida, z[1].vida, z[2].vida])
	print("Balas gastadas: %d (esperado: 1)" % (balas0 - johnny.balas))
	zombis_de_prueba([])
	await get_tree().create_timer(0.3).timeout

	# disparar andando: sigue andando (sin el gesto entero), con los efectos del disparo pintados encima y el retroceso
	johnny.direccion = "e"
	johnny.velocity = Vector2(120, 0)
	johnny.atacar(0.0)
	await get_tree().create_timer(0.07).timeout
	Captura.foto("captura-pistola-electrica-andando.png")
	print("Disparado andando: ataque_t %.1f (esperado: -1.0) · efectos visibles %s (esperado: true) · retroceso %s (esperado: distinto de (0, 0))" % [
		johnny.ataque_t, johnny.efectos.visible, johnny.patada])
	johnny.velocity = Vector2.ZERO
	await get_tree().create_timer(0.5).timeout

	# las 8 direcciones, con una foto a los 0,09 s: la descarga dibujada y las chispas del juego saliendo
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.09).timeout
		Captura.foto("captura-pistola-electrica-%s.png" % d)
		await get_tree().create_timer(0.6).timeout

	# con cada skin: su hoja de la pistola eléctrica
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.09).timeout
		Captura.foto("captura-pistola-electrica-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-pistola-electrica-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.6).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Con "--captura --garfio": el garfio con su dibujo propio (Armas.CREADAS.garfio, conserje-48-garfio: la hoja lleva solo el gesto de
# lanzar el gancho de perchas, con el rollo de cuerda en la otra mano; el gancho que sale volando, la cuerda y el zombi arrastrado los
# dibuja el juego, garfio.gd; casilla de 90x88, con los pies en 45,72; recetas.gd, su icono). Como el bumerán, en la sala de mantenimiento,
# con dos en el baúl (una guardada antes de que tuviera icono propio, con el de las perchas), Johnny se arrima al baúl y cuenta el icono de
# cada una (captura-garfio-baul.png). Saca una y cuenta su hoja, su ritmo, su alcance, sus pies, su boca hacia el este y que ya no le salen
# chispitas; lanza el garfio a un zombi a 120 a su izquierda: lo engancha, le pega y se lo trae hasta delante de Johnny, aturdido (a los
# 0,2 s, con la cuerda tensa, captura-garfio-lanzar.png; a los 0,6 s, ya soltado delante de Johnny, captura-garfio-traido.png). Luego lo
# lanza hacia otro a 400 (más lejos de lo que llega: ni se entera y el garfio vuelve solo), cuenta que no gasta munición y lanza andando
# (Johnny sigue andando, sin gesto y sin efectos). Luego lanza en las 8 direcciones, con una foto de cada una a los 0,05 s, con el brazo ya
# estirado y el gancho saliendo de la mano (captura-garfio-<dirección>.png). Con cada skin (portero, glotón, gymbro y bombero), su hoja y una
# foto (captura-garfio-<skin>.png). Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_garfio() -> void:
	var antes := Guardado.cargar()
	var vieja := Recetas.crear("garfio", "azul")
	vieja.icono = "perchas"   # como las que se crearon antes de que el garfio tuviera icono propio
	Guardado.cambiar(func(g2):
		g2.baul_armas = [vieja, Recetas.crear("garfio", "morada")]
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	print("Baúl: abierto %s · iconos %s (esperado: true, [\"garfio\", \"garfio\"]) · en el banco «%s» (esperado: garfio)" % [
		inventario.abierto == "baul", Guardado.cargar().baul_armas.map(func(a): return Recetas.icono_de(a.receta)),
		Recetas.icono_de("garfio")])
	Captura.foto("captura-garfio-baul.png")
	inventario.cerrar()
	await get_tree().process_frame

	# sacado del baúl: su hoja, su boca y sin chispitas
	var id := Armas.apuntar(Guardado.cargar().baul_armas[0])
	johnny.coger(id)
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no dispare por su cuenta: aquí dispara la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Garfio en la mano: hoja «%s» · ritmo %.1f · alcance %.0f · pies %s · boca este %s · chispitas %s · icono «%s» (esperado: conserje-48-garfio.tres, 0.9, 320, (45, 72), (-6, -33), false, garfio)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.ritmo, w.alcance, w.pies, w.boca.e, w.has("detalle"), Objetos.icono(id)])

	# el lanzamiento hacia un zombi a 120: lo engancha, le pega y se lo trae hasta delante de Johnny, aturdido
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-120, 0)])
	await get_tree().process_frame
	var pies: Vector2 = johnny.global_position + Vector2(0, 16)
	var lejos0: float = z[0].global_position.distance_to(pies)
	var balas0: int = johnny.balas
	johnny.atacar(PI)
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-garfio-lanzar.png")
	var volando := garfios_volando()
	var z_index_garfio := 0
	for n in johnny.get_parent().get_children():
		if n.get_script() == ArmasCreadas.GARFIO:
			z_index_garfio = n.z_index
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-garfio-traido.png")
	print("Garfio en el aire a los 0,2 s: %d (esperado: 1) con z_index %d (esperado: 4) · tras 0,6 s: %d (esperado: 0: ya soltó al zombi)" % [
		volando, z_index_garfio, garfios_volando()])
	print("Zombi a 120: vida %d (esperado: menos de 500) · distancia a Johnny: de %.0f a %.0f (esperado: de 120 a unos 56) · aturdido %.2f s (esperado: más de 0)" % [
		z[0].vida, lejos0, z[0].global_position.distance_to(pies), z[0].aturdido])
	await get_tree().create_timer(0.8).timeout

	# el lanzamiento hacia un zombi a 400: queda fuera de su alcance (320 desde la mano), el garfio vuelve solo
	z = zombis_de_prueba([Vector2(-400, 0)])
	await get_tree().process_frame
	johnny.atacar(PI)
	await get_tree().create_timer(0.35).timeout
	Captura.foto("captura-garfio-lejos.png")
	var volando2 := garfios_volando()
	await get_tree().create_timer(1.6).timeout
	print("Garfio en el aire a los 0,35 s: %d (esperado: 1) · tras 1,95 s: %d (esperado: 0: volvió solo)" % [volando2, garfios_volando()])
	print("Zombi a 400: vida %d (esperado: 500) · aturdido %.2f (esperado: 0)" % [z[0].vida, z[0].aturdido])
	print("Balas gastadas: %d (esperado: 0: no gasta munición)" % (balas0 - johnny.balas))
	zombis_de_prueba([])
	await get_tree().create_timer(0.3).timeout

	# lanzar andando: sigue andando, sin gesto (sin efectos: la hoja no los tiene) ni retroceso
	johnny.direccion = "e"
	johnny.velocity = Vector2(120, 0)
	johnny.atacar(0.0)
	await get_tree().create_timer(0.1).timeout
	print("Lanzado andando: ataque_t %.1f (esperado: -1.0) · efectos visibles %s (esperado: false) · retroceso %s (esperado: (0, 0))" % [
		johnny.ataque_t, johnny.efectos.visible, johnny.patada])
	johnny.velocity = Vector2.ZERO
	quitar_garfios()
	await get_tree().create_timer(0.3).timeout

	# las 8 direcciones, con una foto a los 0,05 s: el brazo estirado y el gancho saliendo de la mano
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.05).timeout
		Captura.foto("captura-garfio-%s.png" % d)
		await get_tree().create_timer(0.5).timeout
		quitar_garfios()
		await get_tree().create_timer(0.2).timeout

	# con cada skin: su hoja del garfio
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.05).timeout
		Captura.foto("captura-garfio-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-garfio-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.5).timeout
		quitar_garfios()
		await get_tree().create_timer(0.2).timeout

	Guardado.cambiar(func(g2):
		g2.baul_armas = antes.baul_armas
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Para probar_garfio: los garfios que van por el aire (los que lanzó Johnny y aún no han vuelto a su mano)
func garfios_volando() -> int:
	return johnny.get_parent().get_children().filter(func(n): return n.get_script() == ArmasCreadas.GARFIO).size()


func quitar_garfios() -> void:
	for n in johnny.get_parent().get_children():
		if n.get_script() == ArmasCreadas.GARFIO:
			n.queue_free()


# Con "--captura --baul": guardar a mano en el baúl lo de la mochila (ui/inventario.gd, «Guardar de la mochila»).
# En la sala de mantenimiento, con dos clavos en el baúl y en la mochila gasolina, clavos, vendas, cuchillas y
# táser, Johnny se arrima al baúl y cuenta en la terminal: que se abre, que se ve la mochila, que guardar una casilla
# mete todos los de esa casilla (y salen de la mochila), que las vendas no se guardan, que con el baúl lleno solo
# caben más de lo que ya tiene (y lo que dice «Guardar todo» de lo que no cabe), y que con sitio «Guardar todo» lo
# mete todo menos lo de curar. Cada línea dice lo esperado. Saca captura-baul-mochila.png (la mochila en la ventana
# del baúl, con la gasolina elegida) y captura-baul-guardado.png (el baúl con lo guardado), deja el baúl como estaba
# y se cierra
func probar_baul() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g2):
		g2.baul = {"clavos": 2}
		g2.baul_armas = [])
	mochila.clear()
	mochila.append_array(["gasolina", "gasolina", "clavos", "vendas", "cuchillas", "taser", "taser", "taser"])
	var marca := func() -> String:   # el botón o la casilla marcada (la del mando y las flechas)
		var f := get_viewport().gui_get_focus_owner()
		return String(f.name) if f else "-"
	var dice := func() -> String:    # el texto de abajo de la ventana
		var t: Label = inventario.fondo.find_child("nota", true, false)
		return t.text if t else "-"
	var boton := func(nombre: String) -> String:
		var b: Button = inventario.fondo.find_child(nombre, true, false)
		return "no está" if b == null else ("apagado" if b.disabled else "activo")
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	var abierto: bool = inventario.abierto == "baul"
	print("Baúl: abierto al arrimarse %s · juego en pausa %s (esperado: true, true)" % [abierto, get_tree().paused])
	if not abierto:
		get_tree().quit()
		return
	print("Baúl sin armas y con cosas en la mochila: «Guardar de la mochila» %s, la marca en «%s» (esperado: activo, ver_mochila) · dice «%s»" % [
		boton.call("ver_mochila"), marca.call(), dice.call()])
	inventario.ver_mochila(true)
	await get_tree().process_frame
	print("La mochila en el baúl: %d casillas, la marca en «%s» (esperado: 5, m0) · «Guardar todo» %s (esperado: activo) · dice «%s»" % [
		Objetos.casillas(mochila).size(), marca.call(), boton.call("guardar_todo"), dice.call()])
	# las casillas: m0 gasolina × 2, m1 clavos, m2 vendas, m3 cuchillas, m4 táser × 3
	inventario.tocar("m0")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-mochila.png")
	print("Elegida la gasolina: «Guardar» %s, la marca en «%s» (esperado: activo, guardar) · dice «%s»" % [
		boton.call("guardar"), marca.call(), dice.call()])
	inventario.guardar()
	await get_tree().process_frame
	var g := Guardado.cargar()
	print("Guardada la gasolina: en el baúl %d, en la mochila %d (esperado: 2, 0) · los clavos del baúl %d (esperado: 2, no se tocan) · la marca en «%s» (esperado: m0, ahora los clavos)" % [
		g.baul.get("gasolina", 0), mochila.count("gasolina"), g.baul.get("clavos", 0), marca.call()])
	# ahora: m0 clavos, m1 vendas, m2 cuchillas, m3 táser × 3
	inventario.tocar("m1")
	await get_tree().process_frame
	print("Elegidas las vendas: «Guardar» %s (esperado: no está) · dice «%s»" % [boton.call("guardar"), dice.call()])
	inventario.guardar()
	print("Guardar las vendas igualmente: en la mochila %d, en el baúl %d (esperado: 1, 0)" % [mochila.count("vendas"),
		Guardado.cargar().baul.get("vendas", 0)])
	# el baúl lleno: los objetos que faltan (menos las cuchillas y el táser) y 8 armas, 32 casillas
	Guardado.cambiar(func(g2):
		for id in Objetos.NOMBRES:
			if Objetos.al_baul(id) and not id in ["cuchillas", "taser"] and not id in g2.baul:
				g2.baul[id] = 1
		for i in 8:
			g2.baul_armas.append(Recetas.crear("molotov")))
	inventario.tocar("m2")
	await get_tree().process_frame
	print("Baúl lleno (%d / %d, esperado: 32 / 32) · elegidas las cuchillas: «Guardar» %s, la marca en «%s» (esperado: apagado, m2) · dice «%s»" % [
		Objetos.casillas_baul(Guardado.cargar()), Objetos.BAUL, boton.call("guardar"), marca.call(), dice.call()])
	inventario.guardar_todo()
	await get_tree().process_frame
	g = Guardado.cargar()
	print("«Guardar todo» con el baúl lleno: clavos en el baúl %d, en la mochila %d (esperado: 3, 0: ya los tenía) · se quedan cuchillas %d y táser %d (esperado: 1, 3) · baúl %d / %d · dice «%s»" % [
		g.baul.get("clavos", 0), mochila.count("clavos"), mochila.count("cuchillas"), mochila.count("taser"),
		Objetos.casillas_baul(g), Objetos.BAUL, dice.call()])
	# con sitio: fuera las armas y los objetos de relleno
	Guardado.cambiar(func(g2):
		g2.baul = {"clavos": 3, "gasolina": 2}
		g2.baul_armas = [Recetas.crear("aplastacabezas", "azul")])
	inventario.pintar()
	inventario.guardar_todo()
	await get_tree().process_frame
	g = Guardado.cargar()
	print("«Guardar todo» con sitio: mochila %s (esperado: [\"vendas\"]) · baúl %s (esperado: clavos 3, gasolina 2, cuchillas 1, taser 3) · «Guardar todo» %s, la marca en «%s» (esperado: apagado, ver_baul)" % [
		mochila, g.baul, boton.call("guardar_todo"), marca.call()])
	inventario.ver_mochila(false)
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-guardado.png")
	print("Vuelta al baúl: %d / %d casillas (esperado: 5 / 32) · «Guardar de la mochila» %s, la marca en «%s» (esperado: apagado —solo quedan las vendas—, a0) · dice «%s»" % [
		Objetos.casillas_baul(Guardado.cargar()), Objetos.BAUL, boton.call("ver_mochila"), marca.call(), dice.call()])
	inventario.cerrar()
	await get_tree().process_frame
	print("Baúl cerrado: juego en pausa %s (esperado: false)" % get_tree().paused)
	Guardado.cambiar(func(g2):
		g2.baul = antes.baul
		g2.baul_armas = antes.baul_armas)
	get_tree().quit()


# Con "--captura --ascensor": el ascensor (partida.gd, arreglar_ascensor). En la planta baja no se arregla (la sala
# está ahí mismo); en la 1ª planta está averiado hasta que cae el jefe (se hace como si cayera: Johnny entra en su
# sala y el jefe no llega a salir), y al salir al pasillo Johnny dice que lo ha arreglado. Con cosas en la mochila,
# baja en él a la sala de mantenimiento, las guarda en el baúl y vuelve a la 1ª planta, delante del ascensor. En la
# 2ª planta vuelve a estar averiado, y en la azotea no hay. Cada línea de la terminal dice lo esperado. Saca
# captura-placas.png (antes de nada, el pasillo de la planta baja con las placas de las puertas y el cartel de la
# planta junto al ascensor), captura-ascensor-arreglado.png (el ascensor ya arreglado, con el aviso de Johnny), captura-ascensor-sala.png (la
# sala, ya abajo) y captura-ascensor-baul.png (lo de la mochila, ya en el baúl). Deja el baúl como estaba y se cierra
func probar_ascensor() -> void:
	var antes := Guardado.cargar()
	# en el pasillo de la planta baja, delante de la sala de mantenimiento (la puerta A): su placa, con la llave
	# inglesa, y junto al ascensor el cartel de la planta, con el 0 (captura-placas.png)
	await montar(0, 0, false)
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-placas.png")
	var sala_de_siempre: int = planta.mantenimiento
	arreglar_ascensor()
	var asc := puerta_de_tipo("ascensor")
	print("Planta baja, como si cayera el jefe: la sala %d (esperado: %d, la de siempre) · el ascensor «%s» (esperado: nunca)" % [
		planta.mantenimiento, sala_de_siempre, planta.sitios[0].salidas[asc].cerrojo])
	# a la 1ª planta, al pasillo (por la llegada, como al subir)
	nueva_planta(2)
	await montar(0, puerta_de_tipo("llegada"), false)
	asc = puerta_de_tipo("ascensor")
	cruzar(asc)
	await get_tree().process_frame
	print("1ª planta, antes del jefe: ascensor abierto %s · al empujarlo, sigue en el sitio %d y dice «%s» (esperado: false, 0, El ascensor está averiado)" % [
		mapa.puertas[asc].abierta, aqui, aviso.text])
	# en la sala del jefe, como si ya hubiera caído: sin zombis y sin que llegue a salir
	var del_jefe := -1
	for k in planta.sitios.size():
		if planta.sitios[k].tipo == "jefe":
			del_jefe = k
	montar(del_jefe, 0, false)
	jefa_salio = true
	await get_tree().create_timer(0.3).timeout
	var salida: Dictionary = planta.sitios[0].salidas[asc]
	# (la sala es el penúltimo sitio: detrás van sus viviendas)
	print("Cae el jefe: escaleras abiertas %s · el ascensor «%s» lleva al sitio %d, «%s» (esperado: true, «», %d, mantenimiento)" % [
		planta.jefa_muerta, salida.cerrojo, salida.a, planta.sitios[salida.a].tipo, planta.sitios.size() - 2])
	await cruzar(0)
	print("Al salir al pasillo: Johnny dice «%s» (esperado: que ha arreglado el ascensor) · ascensor abierto %s (esperado: true)" % [
		aviso.text, mapa.puertas[asc].abierta])
	johnny.position = mapa.puertas[asc].llegada() + Vector2(0, 40)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ascensor-arreglado.png")
	# con cosas en la mochila, abajo
	mochila.clear()
	mochila.append_array(["gasolina", "gasolina", "clavos"])
	Guardado.cambiar(func(g2):
		g2.baul = {}
		g2.baul_armas = [])
	await cruzar(asc)
	var minimapa = $Pantalla/Minimapa
	print("Abajo: en «%s» (esperado: mantenimiento) · arriba pone «%s» (esperado: Planta baja · Mantenimiento) · el minimapa, «%s» (esperado: Planta baja) · la planta sigue siendo la %d (esperado: 2)" % [
		planta.sitios[aqui].tipo, lugar.text, Planta.nombre_planta(1) if minimapa.abajo() else planta.nombre, planta.num])
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ascensor-sala.png")
	# al baúl: se guarda todo lo de la mochila
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	var abierto: bool = inventario.abierto == "baul"
	if abierto:
		inventario.ver_mochila(true)
		await get_tree().process_frame
		inventario.guardar_todo()
		await get_tree().process_frame
		inventario.ver_mochila(false)
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-ascensor-baul.png")
	var g := Guardado.cargar()
	print("Baúl: abierto %s · guardado gasolina %d, clavos %d · en la mochila %d (esperado: true, 2, 1, 0)" % [
		abierto, g.baul.get("gasolina", 0), g.baul.get("clavos", 0), mochila.size()])
	inventario.cerrar()
	await get_tree().process_frame
	# y de vuelta: la puerta de la sala lleva al ascensor de la 1ª planta
	await cruzar(0)
	print("De vuelta: planta %d, en el sitio %d, a %d del ascensor · dice «%s» (esperado: 2, 0, 0, 1ª planta)" % [
		planta.num, aqui, roundi(johnny.position.distance_to(mapa.puertas[asc].llegada())), aviso.text])
	# en la 2ª planta, averiado otra vez (y la sala de la planta baja, como siempre)
	await subir()
	asc = puerta_de_tipo("ascensor")
	print("2ª planta: el ascensor «%s», abierto %s · la puerta de la sala de siempre, «%s» (esperado: nunca, false, puerta)" % [
		planta.sitios[0].salidas[asc].cerrojo, mapa.puertas[asc].abierta, sala_mantenimiento.salidas[0].tipo])
	# en la azotea no hay ascensor: no se arregla nada (ni falla)
	await ir_a_azotea()
	arreglar_ascensor()
	print("Azotea: sala de mantenimiento %d (esperado: -1)" % planta.mantenimiento)
	Guardado.cambiar(func(g2):
		g2.baul = antes.baul
		g2.baul_armas = antes.baul_armas)
	get_tree().quit()


# Con "--captura --edificio centro --joyeria": la prueba de la cámara acorazada (joyeria.gd), con la joyería en la
# planta baja. Johnny delante de la puerta blindada cerrada (captura-joyeria-camara.png); arrimarse al lector sin
# tarjeta: el aviso y, a la segunda, la alarma con el cartel y los primeros zombis (captura-joyeria-alarma.png); la
# cuenta adelantada hasta el final: la puerta se abre (captura-joyeria-abierta.png). Luego la otra manera: en el
# pasillo cae el guardia y suelta las dos tarjetas (captura-joyeria-dorada.png), Johnny coge la dorada y, con la
# cámara otra vez cerrada, el lector la abre sin alarma. Lo cuenta todo en la terminal
func probar_joyeria() -> void:
	var d: Dictionary = planta.get("joyeria", {})
	print("Joyería en la planta baja: %s · cámara: sala %d, puerta en (%d, %d) · dorada: %s" % [not d.is_empty(),
		d.get("sala", -1), d.get("puerta", {}).get("c", -1), d.get("puerta", {}).get("f", -1), d.get("dorada", "-")])
	if d.is_empty():
		get_tree().quit()
		return
	luz.alternar()
	await montar(d.sitio, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var sitio: Dictionary = planta.sitios[d.sitio]
	for sala in sitio.apt.salas:
		mapa.vistas[sala.id] = true
	# Johnny delante de la puerta blindada, por el lado de la sala de venta
	var centro: Vector2 = joyeria.puerta.caja.get_center()
	var dentro: Vector2 = sitio.apt.salas[d.sala].centro
	var fuera := Vector2(0, signf(centro.y - dentro.y)) if joyeria.puerta.de_frente else Vector2(signf(centro.x - dentro.x), 0)
	johnny.position = centro + fuera * 52.0
	johnny.get_node("Camara").reset_smoothing()
	print("Puerta blindada: montada %s · choca %s · abierta %s · zombis dentro de la cámara: %d" % [joyeria.puerta != null,
		joyeria.puerta.is_in_group("obstaculos"), d.abierta, sitio.zombis.filter(func(z): return mapa.zona_en(z.pos) == d.sala).size()])
	await get_tree().create_timer(0.5, false).timeout
	Captura.foto("captura-joyeria-camara.png")
	# el lector sin tarjeta: la primera vez avisa, la segunda dispara la alarma
	joyeria.listo = true
	joyeria.mirar_lector()
	print("Lector, 1ª vez: alarma %s · dice «%s»" % [joyeria.alarma(), aviso.text])
	joyeria.listo = true
	joyeria.mirar_lector()
	print("Lector, 2ª vez: alarma %s (quedan %.0f s)" % [joyeria.alarma(), d.alarma])
	joyeria.grupo_t = 0.5
	await get_tree().create_timer(1.6, false).timeout
	print("Alarma: zombis en la tienda %d · quedan %.0f s" % [get_tree().get_nodes_in_group("zombis").size(), d.alarma])
	Captura.foto("captura-joyeria-alarma.png")
	# la cuenta, adelantada hasta el final: se abre
	d.alarma = 1.0
	await get_tree().create_timer(1.6, false).timeout
	print("Al acabar la cuenta: abierta %s · la puerta choca %s · dice «%s»" % [d.abierta,
		joyeria.puerta.is_in_group("obstaculos") if is_instance_valid(joyeria.puerta) else false, aviso.text])
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().create_timer(0.8, false).timeout
	Captura.foto("captura-joyeria-abierta.png")
	# el premio: la vitrina dentro de la cámara y el logro; al pisarla, el arma a la mano y el fajo
	var a: Dictionary = d.premio.arma
	print("Premio: %s (%s, %s) · fajo $%d · vitrina en %s · logro Caja fuerte: %s" % [a.nombre, a.rareza, Recetas.detalle(a),
		d.premio.fajo, d.premio.pos, Logros.estado(Guardado.cargar(), "caja_fuerte")])
	var manos_antes: Dictionary = johnny.huecos.duplicate()
	var dolares_antes := dolares
	var molotovs_antes: int = lanzables.cantidades.molotov
	johnny.position = d.premio.pos + Vector2(0, 170)   # (más lejos que el imán de las cosas del suelo: que no vuele aún)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.6, false).timeout
	Captura.foto("captura-joyeria-premio.png")
	johnny.position = d.premio.pos
	await get_tree().create_timer(0.6, false).timeout
	print("Cogido: %s · manos %s → %s · guardadas %s · dólares %d → %d · molotovs %d → %d · dice «%s»" % [d.premio.cogido,
		manos_antes, johnny.huecos, armas_guardadas, dolares_antes, dolares, molotovs_antes, lanzables.cantidades.molotov, aviso.text])
	# si solo se sabe el molotov, el premio es un cóctel morado (la segunda apertura, más abajo, lo enseña)
	var recetas_antes: Array = Guardado.cargar().recetas.duplicate()
	Guardado.cambiar(func(g): g.recetas = ["molotov"])
	d.erase("premio")
	# la otra manera: el guardia cae en el pasillo y suelta la tarjeta dorada junto a la suya
	await montar(0, 0, false)
	print("Guardia en el pasillo: %s · dorada: %s" % [guardia != null, d.dorada])
	johnny.position = guardia.position + Vector2(-120, 30)
	guardia.recibir_golpe(9999, Vector2.ZERO)
	await get_tree().create_timer(0.6, false).timeout
	johnny.get_node("Camara").reset_smoothing()
	print("Al caer: dorada %s en %s · en el suelo: tarjeta %s, dorada %s" % [d.dorada, d.suelo, mapa.cosas.has_node("Llave"), mapa.cosas.has_node("Dorada")])
	Captura.foto("captura-joyeria-dorada.png")
	johnny.position = d.suelo.pos
	await get_tree().create_timer(0.4, false).timeout
	print("Cogida: dorada %s · dice «%s»" % [d.dorada, aviso.text])
	# con la cámara otra vez cerrada, el lector la abre con la tarjeta y sin alarma
	d.abierta = false
	d.alarma = -1.0
	await montar(d.sitio, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	johnny.position = centro + fuera * 52.0
	joyeria.listo = true
	joyeria.mirar_lector()
	print("Con la tarjeta dorada: abierta %s · alarma %s · dorada %s · dice «%s»" % [d.abierta, joyeria.alarma(), d.dorada, aviso.text])
	a = d.premio.arma
	print("Premio sabiendo solo el molotov: %s (%s, %s) · fajo $%d" % [a.nombre, a.rareza, Recetas.detalle(a), d.premio.fajo])
	Guardado.cambiar(func(g): g.recetas = recetas_antes)
	get_tree().quit()


func contar_planta() -> void:
	print("Planta: ", planta.nombre)
	for i in range(1, planta.sitios.size()):
		var s: Dictionary = planta.sitios[i]
		if not s.has("apt"):
			print("  %s [%s]: %d muebles" % [s.nombre, s.tipo, s.muebles.size()])
			continue
		var salas := []
		for sala in s.apt.salas:
			salas.append("%s(%d)" % [sala.nombre, sala.casillas])
		var tipos := {}
		for z in s.zombis:
			tipos[z.tipo] = tipos.get(z.tipo, 0) + 1
		print("  %s [%s] %dx%d casillas: %s | %d muebles | zombis: %s" % [s.nombre, s.tipo, s.apt.cols, s.apt.filas,
			" ".join(salas), s.muebles.size(), tipos])
	print("  pasillo: %d muebles | llave en %s" % [planta.sitios[0].muebles.size(),
		planta.sitios[planta.llave.sitio].nombre if planta.llave.sitio >= 0
		else "el guardia del pasillo" if ed.cerrojo == "tarjeta" else "un vecino (Alerta 5)"])


func _process(delta: float) -> void:
	tiempo += delta
	var antes := tiempo - delta
	# primero, fotos de la sala de mantenimiento (donde empieza) y de la exposición
	if antes < 0.3 and tiempo >= 0.3:
		Captura.foto("captura-mantenimiento.png")
		montar(planta.expo, 0, false)
		johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, 420)
		johnny.get_node("Camara").reset_smoothing()
	if antes < 0.7 and tiempo >= 0.7:
		Captura.foto("captura-expo.png")
		# y las últimas filas de zombis (los del centro comercial, la portera y los minijefes): captura-expo-zombis.png
		var filas := []
		for s in mapa.expo_sprites:
			if s.position.y not in filas:
				filas.append(s.position.y)
		filas.sort()
		johnny.position = Vector2(560, filas[-1] - 140.0)
		johnny.get_node("Camara").reset_smoothing()
	if antes < 0.9 and tiempo >= 0.9:
		Captura.foto("captura-expo-zombis.png")
	# al segundo, a un apartamento normal (el que tiene más zombis)
	if antes < 1.0 and tiempo >= 1.0:
		var mejor := 1
		for i in range(1, planta.sitios.size()):
			if planta.sitios[i].zombis.size() > planta.sitios[mejor].zombis.size():
				mejor = i
		print("Entra en ", planta.sitios[mejor].nombre)
		montar(mejor, 0, false)
	# el botiquín del baño: herido, delante del armarito
	if antes < 1.1 and tiempo >= 1.1 and not mapa.armaritos.is_empty():
		var a: Node2D = mapa.armaritos[0]
		johnny.vida = 40
		johnny.position = a.position + Vector2(0, 40)
		johnny.get_node("Camara").reset_smoothing()
		$Pantalla/HUD.hide()   # para que se vea la pared de arriba en la foto
	if antes < 1.4 and tiempo >= 1.4:
		var a: Node2D = mapa.armaritos[0] if not mapa.armaritos.is_empty() else null
		print("Armaritos en el piso: %d | vida tras el botiquín: %d | cogido: %s" % [mapa.armaritos.size(), johnny.vida,
			a.datos.cogido if a else "-"])
		Captura.foto("captura-botiquin.png")
		$Pantalla/HUD.show()
	# poca vida: la pantalla roja y la barra con lo perdido en claro (luego se le devuelve la vida)
	if antes < 1.45 and tiempo >= 1.45:
		johnny.quitar_vida(johnny.vida - 18)
	if antes < 1.6 and tiempo >= 1.6:
		Captura.foto("captura-poca-vida.png")
		johnny.vida = johnny.stats.vida_max
		johnny.tercios = 3
	# una granada a un lado (explota antes de la foto)
	if antes < 2.0 and tiempo >= 2.0:
		lanzables.cambiar()
		lanzables.lanzar(johnny.global_position + Vector2(-180, 90))
		lanzables.cambiar()
	# un tiro de pistola para despertar a los de cerca
	if antes < 2.5 and tiempo >= 2.5:
		Input.action_press("arma_4")
	if antes < 2.6 and tiempo >= 2.6:
		Input.action_release("arma_4")
		Input.action_press("atacar")
	# las trazadoras (normal, perdigón y crítica), quietas al lado de Johnny para la foto
	if antes < 2.65 and tiempo >= 2.65:
		for i in 3:
			var bala := preload("res://escenas/armas/bala.tscn").instantiate()
			bala.velocidad = Vector2.from_angle(-0.4 + i * 0.4) * 600.0
			bala.radio = 3.0 if i == 1 else 4.0
			bala.critico = i == 2
			bala.altura = 22.0
			bala.set_physics_process(false)
			bala.name = "BalaFoto%d" % i
			johnny.get_parent().add_child(bala)
			bala.global_position = johnny.global_position + Vector2(-70 + i * 50, 30)
	if antes < 2.7 and tiempo >= 2.7:
		Captura.foto("captura-balas.png")
		for n in johnny.get_parent().get_children():
			if n.name.begins_with("BalaFoto"):
				n.queue_free()
	if antes < 3.2 and tiempo >= 3.2:
		Input.action_release("atacar")
		# un molotov al zombi más cercano (o por delante)
		var prueba := meter_zombi("lento", mapa.punto_libre(johnny.position, 120.0))
		var donde: Vector2 = prueba.global_position
		lanzables.lanzar(donde)
		print("Molotov hacia ", donde, " | quedan ", lanzables.cantidades)
		# un zombi que cae al lado de Johnny: revienta y deja su mancha
		var muerto := meter_zombi("normal", johnny.position + Vector2(-60, 40))
		muerto.recibir_golpe(999, Vector2.ZERO)
		# y dos que mueren ardiendo: uno se queda en brasas y al otro se le adelanta el reloj hasta los huesos
		for i in 2:
			var quemado := meter_zombi("normal", johnny.position + Vector2(-90 + i * 130, 10))
			quemado.name = "QuemadoFoto%d" % i
			quemado.prender()
			quemado.recibir_golpe(999, Vector2.ZERO)
	if antes < 4.3 and tiempo >= 4.3:
		for i in 2:
			var cuerpo: Node = mapa.cosas.get_node_or_null("QuemadoFoto%d" % i)
			if cuerpo:
				var q: Quemado = cuerpo.get_children().filter(func(n): return n is Quemado)[0]
				q.t = q.caida + 3.0 if i == 0 else 99.0   # uno en brasas y humo; el otro, ya en huesos
	if antes < 4.4 and tiempo >= 4.4:
		Captura.foto("captura-quemado.png")
	if antes < 3.35 and tiempo >= 3.35:
		Captura.foto("captura-sangre.png")
		# las balas: sin ninguna, a la de cuerpo a cuerpo; una caja de munición devuelve la de fuego y recarga
		var antes_balas := "%s %d +%d" % [johnny.huecos.fuego, johnny.balas, johnny.reserva]
		johnny.balas = 0
		johnny.reserva = 0
		johnny.sostener("fuego")
		johnny.lista_para_disparar()
		var sin: String = johnny.mano
		johnny.sumar_municion()
		print("Balas: %s | sin balas pasa a %s | con una caja: %s %d +%d recargando %s" % [antes_balas, sin,
			johnny.mano, johnny.balas, johnny.reserva, johnny.recargando > 0.0])
	if antes < 4.2 and tiempo >= 4.2:
		var ardiendo := 0
		for z in get_tree().get_nodes_in_group("zombis"):
			if z.get("arder_t") != null and z.arder_t > 0.0:
				ardiendo += 1
		print("Charcos: %d | zombis ardiendo: %d | manchas: %d" % [get_tree().get_nodes_in_group("charcos").size(), ardiendo,
			get_tree().get_nodes_in_group("manchas").size()])
	if int(tiempo * 2.0) != int(antes * 2.0) and tiempo > 1.2:
		var dormidos := 0
		var despiertos := 0
		for z in get_tree().get_nodes_in_group("zombis"):
			if z.get("dormido"):
				dormidos += 1
			else:
				despiertos += 1
		print("t=%.1f vida=%d puerta %s | dormidos %d, despiertos %d | %s" % [tiempo, johnny.vida,
			"cerrada" if cerrada else "abierta", dormidos, despiertos, lugar.text.replace("\n", " / ")])
	if antes < 4.5 and tiempo >= 4.5:
		Captura.foto("captura.png")
		print("Foto guardada. Prueba de las escaleras:")
		planta.jefa_muerta = true
		cerrada = false
		montar(0, puerta_de_tipo("escaleras"), false)
	if antes < 4.7 and tiempo >= 4.7:
		cruzar(puerta_de_tipo("escaleras"))
	# en el centro comercial, el guardia: Johnny se le acerca (silbato y refuerzos), foto, y cae con su tarjeta
	if antes < 5.35 and tiempo >= 5.35 and guardia:
		johnny.position = mapa.punto_libre(guardia.position, 0.0)
		for i in 60:
			var p: Vector2 = guardia.position + Vector2.from_angle(randf() * TAU) * 220.0
			if mapa.zona_en(p) >= 0:
				johnny.position = p
				break
		johnny.get_node("Camara").reset_smoothing()
	if antes < 5.5 and tiempo >= 5.5 and guardia:
		print("Guardia: vida %d/%d | alerta %s | silbidos %d | zombis en el pasillo %d" % [guardia.vida, guardia.vida_max,
			guardia.alerta, guardia.silbidos, get_tree().get_nodes_in_group("zombis").size()])
		Captura.foto("captura-guardia.png")
		guardia.recibir_golpe(99999, Vector2.ZERO)
	if antes < 5.6 and tiempo >= 5.6:
		if planta.has("guardia"):
			print("Tarjeta: en el sitio %d, en %s | guardia vivo: %s" % [planta.llave.sitio, planta.llave.pos, planta.guardia.vivo])
		print("Ahora en: ", planta.nombre, " (", planta.sitios.size() - 1, " puertas)")
		Captura.foto("captura-pasillo.png")
		# Johnny pisa la puerta A del pasillo, como si fuera andando
		johnny.position = mapa.puertas[0].position + Vector2(0, 20)
	if antes < 6.6 and tiempo >= 6.6:
		print("Tras pisar la puerta A: en %s (aviso: '%s')" % [planta.sitios[aqui].nombre, aviso.text])
		# Prueba de la jefa: con la llave, a su apartamento
		planta.tiene_llave = true
		for i in planta.sitios.size():
			if planta.sitios[i].tipo == "jefe":
				montar(i, 0, false)
	if antes < 7.3 and tiempo >= 7.3 and jefa and planta.jefe == "gloton":   # (aparece a los 7,2)
		probar_gloton()   # la sangre ácida y el aspirado (lo escribe en la terminal)
	if antes < 7.3 and tiempo >= 7.3 and jefa and planta.jefe == "gymbro":
		probar_gymbro()   # los suplementos (la armadura) y las pesas (lo escribe en la terminal)
	if antes < 7.3 and tiempo >= 7.3 and jefa and planta.jefe == "bombero":
		probar_bombero()   # inmune al fuego, las bolas y los molotovs (lo escribe en la terminal)
	if antes < 7.7 and tiempo >= 7.7 and jefa:
		if jefa.has_method("cambiarse"):
			probar_modista(jefa)   # antes de poner a Johnny delante: se cambia de sitio
		# Johnny, delante del jefe (para que salga en la foto)
		for i in 60:
			var p: Vector2 = jefa.position + Vector2.from_angle(jefa.mirada.angle() + randf_range(-0.7, 0.7)) * 230.0
			if mapa.zona_en(p) >= 0:
				johnny.position = p
				break
		johnny.get_node("Camara").reset_smoothing()
		if jefa is Minijefe:
			jefa.mirada = (johnny.position - jefa.position).normalized()
		if jefa.has_method("lluvia"):
			probar_cocinero()
		if planta.jefe == "antidisturbios":
			# el antidisturbios. El escudo: un golpe de 10 por delante, de lado, por la espalda y de una explosión
			# (la fuerza va hacia donde empuja el golpe: el de delante empuja hacia atrás)
			var m: Vector2 = jefa.mirada
			var quita := []
			for golpe in [[-m, false], [m.orthogonal(), false], [m, false], [m, true]]:
				var antes_vida: int = jefa.vida
				jefa.recibir_golpe(10, golpe[0] * 300.0, golpe[1])
				quita.append(antes_vida - jefa.vida)
			print("Escudo (golpes de 10): de frente -%d, de lado -%d, por la espalda -%d, explosión -%d" % quita)
		if jefa.has_method("foto"):   # que salga en la foto haciendo lo suyo (el antidisturbios, preparando la carga; la mascota, saltando)
			jefa.foto(johnny)
		if jefa.has_method("cambiarse"):   # la modista: que salga en la foto tirando alfileres
			jefa.apuntar_alfileres(johnny.position - jefa.position)
			jefa.datos.aviso = 0.15
	if antes < 8.0 and tiempo >= 8.0 and jefa:
		Captura.foto("captura-jefe.png")
	if antes < 8.05 and tiempo >= 8.05:
		print("El jefe (%s) ha salido en '%s': %s | vida %d | puerta %s" % [planta.jefe, planta.sitios[aqui].nombre,
			jefa != null, jefa.vida_max if jefa else 0, "cerrada" if cerrada else "abierta"])
		if jefa:
			jefa.invulnerable = false   # (la mascota de la foto está en el aire, donde no se le puede dar)
			jefa.recibir_golpe(99999, Vector2.ZERO)
	if antes < 9.5 and tiempo >= 9.5:
		print("Jefa muerta: ", planta.jefa_muerta, " | ", aviso.text)
		probar_menus()


# La modista, en la prueba: cuántos maniquíes hay en su tienda, que se cambie de sitio con uno y que cobren vida
# tres (al caer ella, se caen)
func probar_modista(jefa: Node2D) -> void:
	var antes: Vector2 = jefa.position
	print("Modista: %d maniquíes en %s | al entrar, escondida: %s" % [jefa.maniquies().size(), planta.sitios[aqui].nombre,
		jefa.estado == "escondida"])
	jefa.cambiarse(johnny)
	print("Modista: se cambia de sitio con un maniquí (a %d unidades) | ahora: %s" % [antes.distance_to(jefa.position), jefa.estado])
	jefa.despertar_maniquies(johnny)
	print("Modista: cobran vida %d maniquíes | quedan %d de mueble" % [jefa.vivos.size(), jefa.maniquies().size()])
	jefa.murio.connect(func(): (func():
		print("Modista: al caer ella, maniquíes vivos: %d" % jefa.vivos.filter(func(v): return v.estado != "muerto").size())
		).call_deferred())


# El Glotón: la sangre ácida (primero, la bala de un superviviente: le hace daño a él y a Johnny no le salpica; luego
# dos golpes de Johnny seguidos: solo el primero salpica, un 1 % de su vida) y el aspirado (hasta dónde llega: al
# borde de la elipse limpia de su habitación, mire a donde mire; y Johnny puesto a 220 de él: 0,15 s al abrir la boca
# y otros 0,15 s con toda su fuerza; antes de la foto de los 7,7)
func probar_gloton() -> void:
	# la bala de verdad, encima de él, con un paso suyo hecho a mano (para que no tarde nada)
	var antes_vida: int = johnny.vida
	var antes_jefe: int = jefa.vida
	var bala := preload("res://escenas/armas/bala.tscn").instantiate()
	bala.velocidad = Vector2.RIGHT * 620.0
	bala.dano = 10
	bala.de_aliado = true
	bala.set_physics_process(false)
	jefa.get_parent().add_child(bala)
	bala.global_position = jefa.global_position
	bala._physics_process(1.0 / 60.0)
	print("Sangre ácida (bala de 10 de un superviviente): Glotón -%d, Johnny -%d (esperado: 10 y 0)" % [
		antes_jefe - jefa.vida, antes_vida - johnny.vida])
	antes_vida = johnny.vida
	jefa.recibir_golpe(10, Vector2.RIGHT * 300.0)
	jefa.recibir_golpe(10, Vector2.RIGHT * 300.0)
	print("Sangre ácida (dos golpes seguidos de 10): Johnny -%d" % (antes_vida - johnny.vida))
	for i in 60:
		var p: Vector2 = jefa.position + Vector2.from_angle(randf() * TAU) * 220.0
		if mapa.zona_en(p) >= 0:
			johnny.position = p
			break
	# hasta dónde llega: a la derecha, abajo, a la izquierda y arriba, y que las puntas caen en el borde de la elipse
	var ov: Dictionary = jefa.la_elipse()
	if ov.is_empty():
		print("Aspirar: no encuentra la elipse limpia de su habitación (¡mal!)")
	else:
		var largos := PackedStringArray()
		var en_borde := true
		for a in [0.0, PI / 2.0, PI, -PI / 2.0]:
			var largo: float = jefa.largo_aspirado(a, jefa.global_position)
			largos.append("%.1f" % (largo / 32.0))
			var punta: Vector2 = jefa.global_position + Vector2.from_angle(a) * largo
			en_borde = en_borde and absf(((punta - ov.centro) / Vector2(ov.rx, ov.ry)).length() - 1.0) < 0.001
		print("Aspirar: llega al borde de la elipse (de %.1f × %.1f casillas) mire a donde mire: a la derecha, abajo, a la izquierda y arriba %s casillas · las puntas, en el borde %s (esperado: true)" % [
			ov.rx * 2.0 / 32.0, ov.ry * 2.0 / 32.0, " / ".join(largos), en_borde])
	jefa.mirada = (johnny.position - jefa.position).normalized()
	jefa.cambiar("aspirar")
	# va de menos a más: lo que tira a 3, 5, 8 y 12 casillas al abrir la boca, y lo que acerca a Johnny (quieto) en
	# 0,15 s; luego lo mismo ya con toda su fuerza (Johnny anda a 210: de cerca le arrastra, de lejos no, pero le frena)
	var sitio: Vector2 = johnny.position
	var flojo := [3, 5, 8, 12].map(func(c): return roundi(jefa.tiron_aspirado(c * 32.0)))
	var d0: float = johnny.position.distance_to(jefa.position)
	await get_tree().create_timer(0.15, false).timeout
	var d1: float = johnny.position.distance_to(jefa.position)
	johnny.position = sitio
	johnny.velocity = Vector2.ZERO
	jefa.t = jefa.CRECE_ASPIRAR
	var fuerte := [3, 5, 8, 12].map(func(c): return roundi(jefa.tiron_aspirado(c * 32.0)))
	await get_tree().create_timer(0.15, false).timeout
	print("Aspirar (0,15 s, Johnny quieto): al empezar de %d a %d; con toda su fuerza de %d a %d (le ve: %s)" % [
		d0, d1, d0, johnny.position.distance_to(jefa.position), jefa.se_ve(johnny)])
	print("Aspirar, tirón a 3/5/8/12 casillas (Johnny anda a 210): al empezar %s; con toda su fuerza %s (esperado: [327, 211, 84, 70])" % [flojo, fuerte])
	# y la foto del cono, aspirando con toda su fuerza: hasta el borde de la elipse
	print("Aspirar: foto en captura-gloton-aspira.png (aspirando: %s)" % (jefa.estado == "aspirar"))
	Captura.foto("captura-gloton-aspira.png")


# El Gymbro: se enfada ya (los suplementos): un golpe de 20 le quita 10 de vida y 10 de armadura, y sale la barra
# de armadura. El salto: qué cae dentro de la zona (a un lado y arriba, justo dentro y justo fuera del borde) y uno de
# verdad, en el sitio, con Johnny de pie justo fuera del borde: la foto con él en el aire y, al caer, no le da (0,35 s;
# antes de la foto de los 7,7). Y lanza sus pesas (enfadado, 4) para que salgan en la foto de los 8,0
func probar_gymbro() -> void:
	jefa.fase = 2
	jefa.al_enfadarse(johnny)
	var vida_antes: int = jefa.vida
	var armadura_antes: int = jefa.armadura
	jefa.recibir_golpe(20, Vector2.RIGHT * 300.0)
	var barra: Node = $Pantalla/Jefa.get_node_or_null("Armadura")
	print("Gymbro con suplementos (golpe de 20): vida -%d, armadura -%d de %d | barra de armadura: %s" % [
		vida_antes - jefa.vida, armadura_antes - jefa.armadura, jefa.armadura_max, barra != null and barra.visible])
	# la zona del salto, en el suelo a sus pies (con el margen de Johnny, como al caer)
	var r: float = jefa.RADIO_SALTO
	var suelo: Vector2 = jefa.global_position + Vector2(0, jefa.PIE - 6)
	var margen: float = johnny.RADIO * 0.6
	var dentro := [Vector2(r - 10.0, 0), Vector2(r + 30.0, 0), Vector2(0, -(r * 0.6 - 10.0)), Vector2(0, -(r * 0.6 + 30.0))].map(
		func(d): return jefa.en_la_zona(suelo + d, margen))
	print("Gymbro, zona del salto (%d de ancho y %d de alto): a un lado, justo dentro %s y justo fuera %s; arriba, justo dentro %s y justo fuera %s (esperado: true, false, true, false)" % [
		r * 2.0, r * 1.2, dentro[0], dentro[1], dentro[2], dentro[3]])
	for lado in [1.0, -1.0]:
		var p: Vector2 = jefa.position + Vector2(0, jefa.PIE - 6) + Vector2(lado * (r + 30.0), -16.0)
		if mapa.zona_en(p) >= 0:
			johnny.position = p
			break
	johnny.get_node("Camara").reset_smoothing()
	jefa.mirada = (johnny.position - jefa.position).normalized()
	jefa.cambiar("salto", {"desde": jefa.global_position, "hasta": jefa.global_position, "vuelo": jefa.VUELO[0]})
	jefa.t = jefa.VUELO[0] * 0.75
	var antes_johnny: int = johnny.vida
	await get_tree().create_timer(0.1, false).timeout
	print("Gymbro: foto del salto en captura-gymbro-salto.png (en el aire: %s; Johnny, a %d del centro de la zona)" % [
		jefa.estado == "salto", (johnny.global_position + Vector2(0, 16) - suelo).length()])
	Captura.foto("captura-gymbro-salto.png")
	await get_tree().create_timer(0.25, false).timeout
	print("Gymbro: cae del salto (%s) con Johnny justo fuera del borde: Johnny -%d (esperado: 0)" % [
		jefa.estado == "aterrizar", antes_johnny - johnny.vida])
	jefa.lanzar_pesas(johnny)
	print("Gymbro: pesas en el aire: %d" % get_tree().get_nodes_in_group("balas_zombi").size())


# El jefe de bomberos: el fuego no le hace nada (una gota del lanzallamas, el fogonazo de un molotov y un charco
# de fuego debajo de él no le quitan vida, y grita «¡INMUNE!»), pero un golpe sí (antes de que se ponga a girar para
# la foto: girando, su burbuja de fuego no deja); y lanza sus bolas de fuego y un molotov (para que salgan en la foto
# de los 8,0, con el giro)
func probar_bombero() -> void:
	var vida_antes: int = jefa.vida
	ArmasCreadas.golpe(jefa, Vector2.RIGHT, 20.0, 1.0, "llama")
	var sin_lanzallamas: int = vida_antes - jefa.vida
	var molotov: Node2D = load("res://escenas/armas/proyectil.tscn").instantiate()
	molotov.tipo = "molotov"
	molotov.desde = jefa.position
	molotov.hasta = jefa.position
	add_child(molotov)
	molotov.llamarada(60.0)
	molotov.queue_free()
	var sin_molotov: int = vida_antes - jefa.vida
	# el golpe, ya (a los 7,7 se pone a girar para la foto, y girando la burbuja no deja que nada le quite vida)
	var antes_golpe: int = jefa.vida
	jefa.recibir_golpe(10, Vector2.RIGHT * 300.0)
	var golpe: int = antes_golpe - jefa.vida
	vida_antes = jefa.vida
	var fuego: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
	fuego.tipo = "fuego"
	fuego.position = jefa.position
	add_child(fuego)
	# (0,6 s: el charco prende a los zombis cada medio segundo; y hay que acabar antes de la foto de los 8,0 y de
	# que la prueba mate al jefe a los 8,05)
	await get_tree().create_timer(0.6, false).timeout
	var sin_fuego: int = vida_antes - jefa.vida
	print("Bombero inmune al fuego: lanzallamas -%d, molotov -%d, charco de fuego (0,6 s) -%d | un golpe de 10: -%d" % [
		sin_lanzallamas, sin_molotov, sin_fuego, golpe])
	jefa.mirada = (johnny.position - jefa.position).normalized()
	jefa.lanzar_bolas(johnny)
	jefa.lanzar_molotovs(johnny)
	var molotovs := 0
	for n in jefa.get_parent().get_children():
		if n.get("tipo") == "molotov_jefe":
			molotovs += 1
	print("Bombero: bolas de fuego en el aire: %d | molotovs: %d" % [get_tree().get_nodes_in_group("balas_zombi").size(), molotovs])


# El cocinero, para la foto del jefe: un charco de aceite debajo de él (no le quema) y otro debajo de Johnny,
# unos cuchillos ya clavados, la lluvia marcando el suelo y el abanico recién lanzado
func probar_cocinero() -> void:
	var antes_johnny: int = johnny.vida
	# que nadie le dispare mientras tanto (ni Johnny solo, ni el superviviente que le acompaña): así se ve lo que
	# le quita su aceite
	var modo: String = johnny.modo
	johnny.modo = "mira"
	for a in get_tree().get_nodes_in_group("aliados"):
		a.process_mode = Node.PROCESS_MODE_DISABLED
	for donde in [jefa.position, johnny.position]:
		var charco: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
		charco.tipo = "hirviendo"
		charco.dueno = jefa
		charco.position = donde
		mapa.cosas.add_child(charco)
	for i in 3:
		var c := Cuchillo.new()
		c.modo = "cae"
		c.aviso = 0.05
		c.position = jefa.position.lerp(johnny.position, 0.5) + Vector2((i - 1) * 50.0, 50.0)
		mapa.cosas.add_child(c)
	jefa.lluvia(johnny)
	jefa.empezar("aviso_abanico", (johnny.position - jefa.position).angle())
	jefa.t = 0.3   # el aviso ya casi acabado: en la foto acaba de lanzar el abanico
	await get_tree().create_timer(0.1, false).timeout   # (las balas que ya volaban, que lleguen antes de contar)
	var antes_jefe: int = jefa.vida
	await get_tree().create_timer(0.19, false).timeout
	print("Cocinero: su aceite le quita %d (tiene que ser 0); a Johnny, %d | cuchillos: %d" % [antes_jefe - jefa.vida,
		antes_johnny - johnny.vida, get_tree().get_nodes_in_group("balas_zombi").size()])
	# tras la foto, se recoge todo y Johnny vuelve como estaba (si no, las pruebas de después le pillan herido)
	await get_tree().create_timer(0.1, false).timeout
	johnny.modo = modo
	for a in get_tree().get_nodes_in_group("aliados"):
		a.process_mode = Node.PROCESS_MODE_INHERIT
	for cosa in get_tree().get_nodes_in_group("balas_zombi") + get_tree().get_nodes_in_group("charcos"):
		cosa.queue_free()
	johnny.estados.clear()
	johnny.pisando.clear()
	johnny.vida = antes_johnny


# El ordenador: con $60 en el guardado de prueba compra puntos, sube Ataque, compra la escopeta y hace fotos
func probar_ordenador() -> void:
	Guardado.cambiar(func(g):
		g.dolares = 60
		g.puntos = 0
		g.talentos = {}
		g.armas = [])
	ahorrados = 60
	aplicar_talentos({})
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("puntos")
	ordenador.comprar(3)
	ordenador.subir("ataque")
	ordenador.subir("punteria")
	ordenador.subir("tirador")   # bloqueado: no tiene Ataque al máximo
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-ordenador.png")
	ordenador.abrir("armas")
	ordenador.comprar_arma("escopeta")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-tienda.png")
	# los logros: uno cobrado, uno por cobrar y algo de progreso en los demás
	Guardado.cambiar(func(g): g.logros = {"primer_turno": "cobrado", "desahucio": "conseguido"})
	logros.fregonazos = 4
	ordenador.abrir("logros", "b_desahucio")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-logros.png")
	ordenador.cobrar_logro("desahucio")
	print("Logros: %s | $%d ahorrados tras cobrar" % [Guardado.cargar().logros, Guardado.cargar().dolares])
	var g := Guardado.cargar()
	print("Ordenador: $%d ahorrados, %d puntos, talentos %s, armas %s | daño x%.2f | lleva %s" % [g.dolares, g.puntos,
		g.talentos, g.armas, johnny.stats.dano, johnny.huecos])
	ordenador.abrir("")
	ordenador.apagar()


# La historia: el científico muerto de la planta (con su página sin encontrar), la página al cogerla y el Dosier
# del ordenador con dos páginas
# La sangre, en la sala de mantenimiento (con luz, para que se vea): el destello de un golpe, un zombi muerto a
# golpes que deja su charco, el lento arrastrándose con su rastro y los casquillos de unos disparos
func probar_sangre() -> void:
	# si sigue abierta la mutación de la portera, se elige una que no deja charcos (para que no salgan en la foto)
	if menus.abierto == "mutacion":
		menus.elegir("insensible")
	await montar(planta.mantenimiento, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var centro := Vector2(planta.sitios[aqui].ancho / 2.0, 330)
	johnny.position = centro
	johnny.get_node("Camara").reset_smoothing()
	johnny.invulnerable = 99.0
	johnny.coger("pistola")   # con la pistola (si lleva el desintegrador, el ácido tapa la sangre)
	# los acompañantes, quietos (si no, matan al lento antes de que se arrastre)
	for a in get_tree().get_nodes_in_group("presa"):
		if a != johnny:
			a.process_mode = Node.PROCESS_MODE_DISABLED
	var golpeado := meter_zombi("normal", centro + Vector2(110, -10))
	var lento := meter_zombi("lento", centro + Vector2(-300, 60))
	lento.despertar()
	var muerto := meter_zombi("normal", centro + Vector2(-60, 150))
	await get_tree().create_timer(0.3).timeout
	muerto.recibir_golpe(999, Vector2(-120, 60))
	golpeado.recibir_golpe(1, Vector2(150, 0))
	await get_tree().process_frame
	await get_tree().process_frame
	Captura.foto("captura-destello.png")
	await get_tree().create_timer(0.3).timeout
	golpeado.recibir_golpe(999, Vector2(170, 0))
	johnny.coger("pistola")
	johnny.balas = 8
	for i in 5:
		johnny.disparar(-0.3 + i * 0.15)
		await get_tree().create_timer(0.12).timeout
	await get_tree().create_timer(2.5).timeout
	var rastro: Node = lento.get_parent().get_node_or_null("Rastro")
	print("Sangre: rastro %d | gotas %d | casquillos %d | charco %s" % [rastro.celdas.size() if rastro else 0,
		lento.get_parent().get_node("Gotas").celdas.size() if lento.get_parent().has_node("Gotas") else 0,
		lento.get_parent().get_node("Casquillos").celdas.size() if lento.get_parent().has_node("Casquillos") else 0,
		golpeado.a_golpes])
	Captura.foto("captura-sangre2.png")
	johnny.invulnerable = 0.0
	for a in get_tree().get_nodes_in_group("presa"):
		a.process_mode = Node.PROCESS_MODE_INHERIT


func probar_historia() -> void:
	Guardado.cambiar(func(g): g.paginas = [])
	var c: Dictionary = planta.cientifico
	await montar(c.sitio, 0, false)
	johnny.position = c.pos + Vector2(-70, 0)
	johnny.get_node("Camara").reset_smoothing()
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	await get_tree().create_timer(1.2).timeout
	Captura.foto("captura-cientifico.png")
	print("Científico en pantalla: ", get_viewport().get_canvas_transform() * c.pos)
	johnny.position = c.pos + Vector2(28, 30)
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-pagina.png")
	print("Página cogida: %s | en el guardado: %s" % [c.get("pagina", {}).get("id", "-"), Guardado.cargar().paginas])
	menus.leida()
	# los muertos que no llevan bata (en el centro comercial: el jefe de seguridad y la secretaria), en fila sobre
	# un fondo liso, por encima de todo (sin penumbra ni paredes): captura-cuerpos.png
	var con_ropa: Array = Historia.dosier(edificio).paginas.filter(func(p): return p.look.has("ropa"))
	if not con_ropa.is_empty():
		var capa := CanvasLayer.new()
		capa.layer = 50
		add_child(capa)
		var fondo := ColorRect.new()
		fondo.color = Color("#5a5d66")
		fondo.position = Vector2(240, 230)
		fondo.size = Vector2(480, 180)
		capa.add_child(fondo)
		for i in con_ropa.size():
			var cuerpo := CIENTIFICO.new()
			cuerpo.montar(con_ropa[i], Vector2(370 + i * 220, 320))
			cuerpo.z_index = 0
			capa.add_child(cuerpo)
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-cuerpos.png")
		capa.queue_free()
	# en el ordenador, la primera y la tercera página del dosier de este edificio (en los Apartamentos, el correo)
	# y la primera de cada uno de los otros edificios: el Dosier las enseña todas, sea cual sea el edificio
	var ids: Array = Historia.dosier(edificio).paginas.map(func(p): return p.id)
	var de_otros: Array = Historia.DOSIERES.keys().filter(func(e): return e != edificio).map(
		func(e): return Historia.DOSIERES[e].paginas[0].id)
	Guardado.cambiar(func(g): g.paginas = [ids[0], ids[2]] + de_otros)
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	ordenador.abrir("dosier", "b_" + ids[2])
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-dosier.png")
	# la del jefe, si este edificio la tiene (el centro comercial): sin encontrar en el ordenador y luego soltada
	var del_jefe := Historia.del_jefe(Guardado.cargar(), edificio)
	if not del_jefe.is_empty():
		ordenador.abrir("dosier", "b_" + del_jefe.id)
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-dosier-falta.png")
	ordenador.abrir("")
	ordenador.apagar()
	if not del_jefe.is_empty():
		pagina_del_jefe()
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-pagina-jefe.png")
		print("Página del jefe: %s | en el guardado: %s" % [del_jefe.id, Guardado.cargar().paginas])
		menus.leida()
	await montar(planta.mantenimiento, 0, false)
	await probar_noticias()


# Colecciones (bestiario.gd y el programa del ordenador): deja en el guardado parte de lo que hay (8 objetos y los
# explosivos, tres o cuatro armas, cuatro o siete enemigos) y hace las fotos: el escritorio con el aviso de "¡NUEVO!"
# (captura-escritorio-nuevo.png), los objetos de este edificio (captura-colecciones.png), la ficha del vecino
# (captura-bestiario.png) y la del gerente, sin ver (captura-bestiario-falta.png). Luego cuenta en la terminal lo
# encontrado, creado y visto de cada edificio, y comprueba los totales
func probar_colecciones() -> void:
	# lo que la prueba ha ido apuntando sola (meter_zombi avisa al bestiario con cada enemigo que nace)
	print("Bestiario apuntado por la prueba hasta aquí: %s" % [Guardado.cargar().get("bestiario", [])])
	var encontrados: Array = Objetos.de_edificio(edificio).slice(0, 8)
	if not "explosivos" in encontrados:
		encontrados.append("explosivos")
	var creadas: Array = ["molotov", "lanza", "supermaza"]
	var vistos: Array = ["normal", "lento", "rapido", "portera"]
	if edificio == "centro":
		creadas.append("bate_helado")
		vistos += ["dependienta", "guardia", "antidisturbios"]
	Guardado.cambiar(func(g):
		g.encontrados = encontrados
		g.creadas = creadas
		g.bestiario = vistos
		g.colecciones_nuevo = true)
	abrir_ordenador()
	await get_tree().create_timer(0.5).timeout   # el encendido del monitor dura 0,35 s
	Captura.foto("captura-escritorio-nuevo.png")   # el icono avisa de que hay algo nuevo
	ordenador.abrir("colecciones", "c_%s_objetos" % edificio)
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-colecciones.png")
	ordenador.abrir("colecciones", "z_normal")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-bestiario.png")
	ordenador.abrir("colecciones", "z_gerente")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-bestiario-falta.png")
	# los recuentos que enseña el programa, edificio por edificio
	var g := Guardado.cargar()
	for e in Edificios.LISTA:
		var objetos: Array = Objetos.de_edificio(e)
		var armas: Array = Recetas.de_edificio(e)
		var bichos: Array = Bestiario.de_edificio(e)
		print("Colecciones de %s: objetos %d/%d | armas %d/%d | bestiario %d/%d" % [e,
			objetos.filter(func(id): return id in g.encontrados).size(), objetos.size(),
			armas.filter(func(id): return id in g.creadas).size(), armas.size(),
			bichos.filter(func(id): return id in g.bestiario).size(), bichos.size()])
	if Objetos.de_edificio("apartamentos").size() != 17 or Objetos.de_edificio("centro").size() != 23:
		push_error("Colecciones: los objetos por edificio no son 17 y 23")
	if Recetas.de_edificio("apartamentos").size() != 15 or Recetas.de_edificio("centro").size() != 9:
		push_error("Colecciones: las recetas por edificio no son 15 y 9")
	if Bestiario.LISTA.size() != 22:
		push_error("Colecciones: el bestiario no tiene 22 fichas")
	if Bestiario.retrato("gerente_mutado") == null:
		push_error("Colecciones: el retrato del gerente mutado es null")
	if g.colecciones_nuevo:
		push_error("Colecciones: el aviso de nuevo sigue puesto después de abrir el programa")
	ordenador.abrir("")
	ordenador.apagar()


# Las noticias: en los Apartamentos, con la página del correo encontrada salen tres emisiones (dos sin ver); en el
# centro comercial, con los Apartamentos completados y sus dos primeras páginas, salen cinco (dos sin ver). Abre el
# programa, deja hablar a la reportera un poco y hace la foto
func probar_noticias() -> void:
	var ids: Array = Historia.dosier(edificio).paginas.map(func(p): return p.id)
	var centro := edificio == "centro"
	Guardado.cambiar(func(g):
		g.paginas = [ids[0], ids[1]] if centro else ["vd7_protocolo", "vd7_correo"]
		g.noticias_vistas = ["n_cierre", "n_buscado", "n_reformas"] if centro else ["n_cierre"]
		# los edificios completados, siempre igual (el final de la prueba vuelve a completar el de la partida): en el
		# centro, los Apartamentos sí y el centro no (la del helicóptero, aún sin emitir)
		Guardado.edificio(g, "apartamentos").completado = centro
		Guardado.edificio(g, "centro").completado = false)
	print("Noticias emitidas: %s | nuevas: %s" % [Historia.noticias_emitidas(Guardado.cargar()).map(func(n): return n.id),
		Historia.noticias_nuevas(Guardado.cargar()).map(func(n): return n.id)])
	avisar_noticias()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-aviso-noticias.png")
	abrir_ordenador()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-escritorio.png")
	ordenador.abrir("noticias")
	await get_tree().create_timer(3.0).timeout
	Captura.foto("captura-noticias.png")
	print("Noticias vistas tras abrir: ", Guardado.cargar().noticias_vistas)
	ordenador.abrir("")
	ordenador.apagar()


# La mochila, el banco y el baúl: unos objetos en la mochila y en el baúl, compra el bate (la fregona va al
# inventario), crea un arma con una receta sabida, prueba una sin saber, y hace fotos. Luego, las recetas que
# sueltan los jefes (probar_soltar_recetas)
func probar_cosas() -> void:
	Guardado.cambiar(func(g):
		g.dolares = 20
		g.baul = {"clavos": 1, "lejia": 2}
		g.baul_armas = []
		g.recetas = ["molotov", "aplastacabezas", "partecuerpos", "lanza"])
	ahorrados = 20
	mochila = ["gasolina", "gasolina", "cuchillas", "taser", "cuerda"]
	soltar_objeto("mechero", johnny.position + Vector2(30, 0))
	await get_tree().create_timer(0.6).timeout
	abrir_ordenador()
	ordenador.abrir("armas")
	ordenador.comprar_arma("bate")
	ordenador.abrir("")
	ordenador.apagar()
	abrir_cosas("inventario")
	inventario.tocar("m0")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-inventario.png")
	inventario.cerrar()
	abrir_cosas("banco")
	inventario.tocar("r_aplastacabezas")   # el bate de la mano y los clavos del baúl
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-banco.png")
	inventario.crear_arma()
	inventario.tocar("r_bate_fuego")   # tiene la gasolina, pero no la receta (ni ya el bate): no hace nada
	inventario.crear_arma()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-banco2.png")
	print("Banco: creadas %s (solo el aplastacabezas)" % Guardado.cargar().baul_armas.map(func(a): return a.receta))
	inventario.cerrar()
	abrir_cosas("baul")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-baul.png")
	inventario.cerrar()
	var g := Guardado.cargar()
	print("Cosas: mochila %s | guardadas %s | mano %s | baúl %s | armas del baúl %s" % [mochila, armas_guardadas,
		johnny.huecos.cuerpo, g.baul, g.baul_armas.map(func(a): return "%s %s %d" % [a.nombre, a.rareza, a.dano])])


# Las armas creadas (fase 7b2): saca cinco del baúl, golpea con la inmovilizadora, lanza el bumerán, se pone
# el desintegrador desde el inventario y dispara, y lanza la congeladora. Cuenta lo que pasa y hace una foto
func probar_creadas() -> void:
	Guardado.cambiar(func(g): g.baul_armas = [Recetas.crear("inmovilizadora", "morada"), Recetas.crear("desintegrador"),
		Recetas.crear("bumeran"), Recetas.crear("congeladora"), Recetas.crear("molotov")])
	var molotovs: int = lanzables.cantidades.molotov
	abrir_cosas("baul")
	for i in 5:
		inventario.tocar("a0")
		inventario.sacar()
	inventario.cerrar()
	print("Creadas sacadas: mano %s | guardadas %s | molotovs %d -> %d | lanzables %s | baúl %d" % [
		[Objetos.nombre(johnny.huecos.cuerpo), Objetos.nombre(johnny.huecos.fuego)], armas_guardadas.map(Objetos.nombre),
		molotovs, lanzables.cantidades.molotov, lanzables.tipos(), Guardado.cargar().baul_armas.size()])
	johnny.direccion = "e"
	johnny.sostener("cuerpo")
	var z1 := meter_zombi("lento", johnny.position + Vector2(40, 0))
	var z2 := meter_zombi("lento", johnny.position + Vector2(100, 10))
	z1.vida = 500   # que no muera ninguno (saldría el recuadro de las mutaciones y pararía el juego)
	z2.vida = 500
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	print("Inmovilizadora: zombi 1 aturdido %.1f vida %d | zombi 2 aturdido %.1f vida %d" % [z1.aturdido, z1.vida, z2.aturdido, z2.vida])
	johnny.sostener("fuego")
	johnny.disparar(0.0)
	await get_tree().create_timer(0.3).timeout
	print("Bumerán: balas %d (no gasta) | zombi 1 vida %d | zombi 2 vida %d" % [johnny.balas, z1.vida, z2.vida])
	abrir_cosas("inventario")
	inventario.tocar("g%d" % armas_guardadas.find(armas_guardadas.filter(func(id): return Objetos.nombre(id) == "Desintegrador")[0]))
	inventario.poner_guardada()
	inventario.cerrar()
	for i in 6:
		johnny.disparar(0.0)
		await get_tree().create_timer(0.08).timeout
	await get_tree().create_timer(0.2).timeout
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().process_frame
	Captura.foto("captura-creadas.png")
	menus.visible = true
	print("Desintegrador: mano %s balas %d | zombi 2 vida %d heridas %s | charcos %d" % [Objetos.nombre(johnny.huecos.fuego),
		johnny.balas, z2.vida, z2.get_children().filter(func(n): return n.name.begins_with("herida")).map(func(n): return n.name),
		get_tree().get_nodes_in_group("charcos").size()])
	var z3 := meter_zombi("lento", johnny.position + Vector2(-120, 30))
	z3.vida = 500
	lanzables.tipo = "congeladora"
	lanzables.lanzar(z3.global_position)
	await get_tree().create_timer(2.3).timeout
	print("Congeladora: zombi 3 aturdido %.1f vida %d | vida de Johnny %d | quedan %s" % [z3.aturdido, z3.vida, johnny.vida, lanzables.tipos()])


# El reparto de objetos (parte 6 del centro comercial): cuenta qué sale en cada sitio de los dos edificios y
# comprueba que las cosas de casa no salen en el centro ni las del centro en los Apartamentos. Luego deja en el
# suelo los nueve nuevos, mete uno de cada objeto en el baúl (lo de la tecla U) y hace fotos del banco y del baúl
func probar_objetos() -> void:
	var fallos := []
	for ed_id in ["apartamentos", "centro"]:
		for tienda in [""] + (Objetos.TIENDAS.keys() if ed_id == "centro" else []):
			var salen := {}
			for i in 2000:
				var id := Objetos.al_azar(ed_id, tienda)
				salen[id] = salen.get(id, 0) + 1
				if id == "explosivos" or (ed_id == "centro" and id in Objetos.SOLO_CASA) \
						or (ed_id == "apartamentos" and id in Objetos.SOLO_CENTRO):
					fallos.append("%s %s: %s" % [ed_id, tienda, id])
			print("Objetos en %s %s: %d distintos %s" % [ed_id, tienda if tienda != "" else "(pasillo)", salen.size(), salen.keys()])
	print("Reparto de objetos: ", "bien" if fallos.is_empty() else "MAL %s" % str(fallos.slice(0, 5)))
	for i in Objetos.SOLO_CENTRO.size():
		soltar_objeto(Objetos.SOLO_CENTRO[i], johnny.position + Vector2(-176 + i * 44, -100), true)
	await get_tree().create_timer(0.5).timeout
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().process_frame
	Captura.foto("captura-objetos-nuevos.png")
	menus.visible = true
	for cosa in mapa.cosas.get_children():
		if cosa.get_script() == BILLETE:
			cosa.queue_free()
	var baul_antes: Dictionary = Guardado.cargar().baul
	dar_objetos()
	abrir_cosas("banco")
	inventario.tocar("r_pistola_electrica")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-banco-todo.png")
	inventario.cerrar()
	abrir_cosas("baul")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-todo.png")
	inventario.cerrar()
	print("Baúl con uno de cada: %d casillas de %d" % [Objetos.casillas_baul(Guardado.cargar()), Objetos.BAUL])
	Guardado.cambiar(func(g): g.baul = baul_antes)
	await probar_soltar_recetas()


# Las recetas que sueltan los jefes: sabiendo todas menos dos, suelta tres (la tercera ya no sale: las dos que
# quedan están en el suelo), foto del papel en el suelo, lo coge y foto del aviso
# Los objetos de curar de las tiendas (parte 9: las vendas y el bocadillo, Objetos.USABLES): con la vida baja y los
# dos en la mochila, saca el inventario con las vendas elegidas (captura-vendas.png) y usa cada uno, contando la
# vida antes y después; luego dice dónde salen, que no entran en recetas y cuántos objetos cuenta Colecciones
func probar_curas() -> void:
	var antes := [mochila.duplicate(), johnny.vida]
	mochila = ["vendas", "bocadillo", "clavos"]
	johnny.vida = roundi(johnny.vida_tope() * 0.4)
	abrir_cosas("inventario")
	inventario.tocar("m0")
	await get_tree().create_timer(0.4).timeout   # (sigue contando con el juego en pausa)
	Captura.foto("captura-vendas.png")
	for id in ["vendas", "bocadillo"]:
		var v: int = johnny.vida
		if inventario.abierto == "":
			abrir_cosas("inventario")
		if inventario.elegido() != id:   # (tocar la casilla ya elegida la deselecciona)
			inventario.tocar("m0")   # el primero de la mochila: primero las vendas y, gastadas, el bocadillo
		inventario.usar()
		print("%s: vida %d -> %d (cura %d) | mochila %s | cerrado %s" % [Objetos.nombre(id), v, johnny.vida, cura_de(id),
			mochila, inventario.abierto == ""])
	print("Curas · en alguna receta: %s · dónde salen: vendas en %s, bocadillo en %s · Colecciones del centro: %d objetos" % [
		Recetas.LISTA.values().any(func(r): return "vendas" in r.con or "bocadillo" in r.con),
		Objetos.donde("vendas", "centro"), Objetos.donde("bocadillo", "centro"), Objetos.de_edificio("centro").size()])
	if inventario.abierto != "":
		inventario.cerrar()   # por si alguno no se ha podido usar: que no se quede el juego en pausa
	mochila = antes[0]
	johnny.vida = antes[1]


func probar_soltar_recetas() -> void:
	var faltan := ["garfio", "mangual"]
	Guardado.cambiar(func(g): g.recetas = Recetas.LISTA.keys().filter(func(r): return not r in faltan))
	var donde: Vector2 = johnny.position + Vector2(220, 0)
	var soltadas := [soltar_receta(donde), soltar_receta(donde), soltar_receta(donde)]
	print("Recetas soltadas: %s (dos distintas de %s y la tercera vacía)" % [soltadas, faltan])
	menus.visible = false   # por si ha salido el recuadro de una mutación
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-receta-suelo.png")
	for cosa in mapa.cosas.get_children():
		if cosa.get_script() == BILLETE and cosa.icono == ICONO_RECETA:
			cosa.cogido.emit()
			cosa.queue_free()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-receta-cogida.png")
	print("Aviso al coger la receta: '%s' (se ve: %s)" % [aviso.text, aviso.modulate.a > 0.5 and aviso.is_visible_in_tree()])
	menus.visible = true
	print("Recetas sabidas: %d de %d | en el suelo: %s | otra al morir un jefe: '%s'" % [
		Recetas.sabidas(Guardado.cargar()).size(), Recetas.LISTA.size(), recetas_en_suelo, soltar_receta(donde)])


# Las armas de las recetas nuevas (parte 6 del centro comercial): comprueba que las nueve recetas salen en el banco
# y prueba cada arma contra zombis lentos de 500 de vida (que no muera ninguno), contando en la terminal lo que pasa
# y con una foto de cada una: captura-arma-<receta>.png
func probar_recetas() -> void:
	var nuevas := ["bate_helado", "mangual", "latigo_electrico", "pistola_electrica", "garfio", "bomba_aceite",
		"mina_despertador", "nube_somnifera", "bomba_clavos"]
	print("Recetas nuevas en el banco: ", nuevas.all(func(r): return Recetas.buscar(Recetas.LISTA[r].con[1], Recetas.LISTA[r].con[0]) == r))
	# en medio del cuarto, mirando a la derecha, y sin atacar por su cuenta (aquí ataca la prueba)
	johnny.position = Vector2(planta.sitios[aqui].ancho / 2.0, planta.sitios[aqui].alto / 2.0)
	johnny.get_node("Camara").reset_smoothing()
	johnny.direccion = "e"
	johnny.espera = 1000.0
	# cuerpo a cuerpo: el bate helado congela, el mangual echa a todos lejos y el látigo eléctrico salta a otro
	var z := zombis_de_prueba([Vector2(40, 0)])
	johnny.coger(Armas.apuntar(Recetas.crear("bate_helado")))
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	await foto_arma("bate_helado")
	print("Bate helado: congelado %.1f vida %d" % [z[0].congelado, z[0].vida])
	z = zombis_de_prueba([Vector2(45, 0), Vector2(-45, 10), Vector2(0, 45)])
	johnny.coger(Armas.apuntar(Recetas.crear("mangual")))
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	await get_tree().create_timer(0.25).timeout
	await foto_arma("mangual")
	print("Mangual: distancias %s | aturdidos %s" % [z.map(func(o): return roundi(o.distancia_a(johnny))), z.map(func(o): return o.aturdido > 0.0)])
	z = zombis_de_prueba([Vector2(90, 0), Vector2(150, 30)])
	johnny.coger(Armas.apuntar(Recetas.crear("latigo_electrico")))
	await get_tree().create_timer(0.1).timeout
	johnny.golpear(0.0)
	await foto_arma("latigo_electrico")
	print("Látigo eléctrico: aturdidos %s | vidas %s" % [z.map(func(o): return snappedf(o.aturdido, 0.1)), z.map(func(o): return o.vida)])
	# a distancia: las chispas de la pistola eléctrica y el garfio
	z = zombis_de_prueba([Vector2(160, 0), Vector2(220, 40)])
	johnny.coger(Armas.apuntar(Recetas.crear("pistola_electrica")))
	await get_tree().create_timer(0.1).timeout
	for i in 4:
		johnny.disparar(0.0)
		await get_tree().create_timer(0.08).timeout
	await foto_arma("pistola_electrica")
	await get_tree().create_timer(0.3).timeout
	print("Pistola eléctrica: balas %d | aturdidos %s | vidas %s" % [johnny.balas, z.map(func(o): return snappedf(o.aturdido, 0.1)),
		z.map(func(o): return o.vida)])
	z = zombis_de_prueba([Vector2(260, 0)])
	johnny.coger(Armas.apuntar(Recetas.crear("garfio")))
	await get_tree().create_timer(0.1).timeout
	var lejos := roundi(z[0].distancia_a(johnny))
	johnny.disparar(0.0)
	await get_tree().create_timer(0.4).timeout
	await foto_arma("garfio")
	await get_tree().create_timer(0.75).timeout
	print("Garfio: distancia %d -> %d | balas %d (no gasta) | vida %d" % [lejos, roundi(z[0].distancia_a(johnny)), johnny.balas, z[0].vida])
	# arrojadizas: el aceite resbala y luego arde, la mina espera a que pase un zombi, la nube duerme y los clavos
	z = zombis_de_prueba([Vector2(170, 0), Vector2(190, 30)])
	for r in ["bomba_aceite", "mina_despertador", "nube_somnifera", "bomba_clavos"]:
		lanzables.sacar(Recetas.crear(r))
	for o in z:
		o.aturdido = 4.0   # que se queden en el charco
	lanzables.tipo = "bomba_aceite"
	lanzables.lanzar(johnny.global_position + Vector2(180, 10))
	await get_tree().create_timer(1.0).timeout
	var aceite := get_tree().get_nodes_in_group("charcos").filter(func(c): return c.tipo == "aceite").size()
	await foto_arma("bomba_aceite")
	await get_tree().create_timer(2.0).timeout
	print("Bomba de aceite: charcos de aceite %d | luego fuegos %d | zombis ardiendo %s" % [aceite,
		get_tree().get_nodes_in_group("charcos").filter(func(c): return c.tipo == "fuego").size(), z.map(func(o): return o.arder_t > 0.0)])
	await foto_arma("bomba_aceite_arde")
	z = zombis_de_prueba([])
	lanzables.tipo = "mina_despertador"
	lanzables.lanzar(johnny.global_position + Vector2(-170, 0))
	await get_tree().create_timer(1.3).timeout
	await foto_arma("mina_despertador")
	var mina: Node2D = johnny.get_parent().get_children().filter(func(n): return n.get_script() == Lanzables.BOMBA)[-1]
	var donde: Vector2 = mina.global_position - johnny.global_position
	z = zombis_de_prueba([Vector2(-330, 0)])   # viene hacia Johnny y pasa por encima
	for i in 40:
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(mina):
			break
	await get_tree().create_timer(0.1).timeout
	print("Mina despertador: en %s | ha explotado %s | el zombi que pasa, vida %d (de 500) | vida de Johnny %d" % [
		donde.round(), not is_instance_valid(mina), z[0].vida, johnny.vida])
	z = zombis_de_prueba([Vector2(180, 0), Vector2(200, 40), Vector2(150, -30)])
	lanzables.tipo = "nube_somnifera"
	lanzables.lanzar(johnny.global_position + Vector2(180, 10))
	await get_tree().create_timer(1.9).timeout
	await foto_arma("nube_somnifera")
	print("Nube somnífera: dormidos %s" % [z.map(func(o): return snappedf(o.aturdido, 0.1))])
	z = zombis_de_prueba([Vector2(120, 0), Vector2(200, 50), Vector2(80, -60)])
	lanzables.tipo = "bomba_clavos"
	lanzables.lanzar(johnny.global_position + Vector2(150, 0))
	await get_tree().create_timer(2.15).timeout
	await foto_arma("bomba_clavos")
	await get_tree().create_timer(0.35).timeout
	print("Bomba de clavos: vidas %s | sangran %s | quedan %s" % [z.map(func(o): return o.vida),
		z.map(func(o): return o.has_node("herida_sangra")), lanzables.tipos()])
	zombis_de_prueba([])
	johnny.vida = johnny.stats.vida_max
	johnny.espera = 0.0


# Para probar_recetas: quita los zombis y los charcos que haya, cura a Johnny y saca zombis lentos de 500 de vida
# en esos sitios (respecto a Johnny)
func zombis_de_prueba(donde: Array) -> Array:
	for o in get_tree().get_nodes_in_group("zombis") + get_tree().get_nodes_in_group("charcos"):
		o.remove_from_group("zombis")
		o.queue_free()
	johnny.vida = johnny.stats.vida_max
	var lista := []
	for d in donde:
		var zombi := meter_zombi("lento", johnny.position + d)
		zombi.vida = 500
		lista.append(zombi)
	return lista


# Para probar_recetas: la foto de un arma nueva (sin el recuadro de las mutaciones, si ha salido)
func foto_arma(nombre: String) -> void:
	menus.visible = false
	await get_tree().process_frame
	Captura.foto("captura-arma-%s.png" % nombre)
	menus.visible = true


# El recuadro de las mutaciones: foto, elige la primera y comprueba que cambia los atributos
func probar_mutaciones() -> void:
	abrir_mutacion()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-mutacion.png")
	var primera: String = menus.cartas[0].id
	menus.elegir(primera)
	elegir_mutacion("insensible")
	print("Mutaciones: %s | daño recibido x%.2f | pausa %s" % [mutaciones.tengo, johnny.stats.dano_recibido, get_tree().paused])


# La azotea del centro comercial: Johnny llega por la escalera y sale el jefe (captura-azotea.png); la azotea entera,
# sin penumbra y desde lejos (captura-azotea-entera.png); y, quitado el jefe, la escalera de incendios abierta
# (captura-azotea-incendios.png)
func probar_azotea() -> void:
	nueva_planta(Planta.PLANTAS)
	await montar(0, puerta_de_tipo("llegada"), false)
	var s: Dictionary = planta.sitios[0]
	var tipos := {}
	for m in s.muebles:
		tipos[m.tipo] = tipos.get(m.tipo, 0) + 1
	print("Azotea: %d x %d | aparatos %s | manchas %d | restos %d | jefe: %s (%s)" % [s.ancho, s.alto, tipos,
		s.manchas.size(), mapa.restos.size(), planta.jefe, planta.el_jefe])
	johnny.position = mapa.puertas[0].llegada() + Vector2(200, 0)   # se aleja de la escalera: se cierra detrás
	await get_tree().create_timer(1.4).timeout
	Captura.foto("captura-azotea.png")
	print("  ha salido el jefe: %s | escalera de llegada %s | incendios %s | aviso: '%s'" % [jefa != null,
		"cerrada" if cerrada else "abierta", "abierta" if mapa.puertas[1].abierta else "cerrada", aviso.text])
	var camara: Camera2D = johnny.get_node("Camara")
	# el gerente, con Johnny delante, lanzándole los contratos (captura-gerente.png)
	if jefa and jefa.has_method("lanzar_contratos"):
		for i in 60:
			johnny.position = jefa.position + Vector2.from_angle(PI + randf_range(-0.8, 0.8)) * 300.0
			if mapa.zona_en(johnny.position) >= 0 and jefa.a_la_vista(johnny):   # sin aparatos en medio
				break
		camara.reset_smoothing()
		jefa.foto(johnny)
		await get_tree().create_timer(0.45).timeout
		Captura.foto("captura-gerente.png")
		print("  el gerente: vida %d/%d | barra: '%s' | contratos volando: %d" % [jefa.vida, jefa.vida_max,
			$Pantalla/Jefa/Nombre.text, get_tree().get_nodes_in_group("balas_zombi").size()])
		# el maletinazo, con Johnny pegado (captura-gerente-maletinazo.png)
		for i in 60:
			johnny.position = jefa.position + Vector2.from_angle(PI + randf_range(-0.5, 0.5)) * 115.0
			if mapa.zona_en(johnny.position) >= 0:
				break
		camara.reset_smoothing()
		for papel in get_tree().get_nodes_in_group("balas_zombi"):
			papel.queue_free()   # (que no le dé antes un contrato: luego Johnny es invulnerable un momento)
		johnny.invulnerable = 0.0
		var vida_johnny: int = johnny.vida
		jefa.empezar("aviso_maletinazo", (johnny.position - jefa.position).angle())
		await get_tree().create_timer(0.3).timeout
		Captura.foto("captura-gerente-maletinazo.png")
		await get_tree().create_timer(0.4).timeout
		# y «¡A TRABAJAR!»: llegan dos dependientas y un vigilante (captura-gerente-trabajar.png)
		print("  maletinazo: a Johnny le ha quitado %d (con su escudo y sus mutaciones de la prueba)" % (vida_johnny - johnny.vida))
		var antes_zombis: int = jefa.secuaces()
		jefa.cambiar("a_trabajar")
		jefa.gritar("¡A TRABAJAR!", Color("#ffd23f"), 26)
		await get_tree().create_timer(0.9).timeout
		Captura.foto("captura-gerente-trabajar.png")
		print("  ¡A TRABAJAR!: han llegado %d" % (jefa.secuaces() - antes_zombis))
		await probar_mutado(camara)
	elif jefa and jefa.has_method("lanzar_probetas"):
		await probar_cientifico_jefe(camara)
	luz.alternar()
	johnny.position = Vector2(s.ancho / 2.0, s.alto / 2.0)
	camara.zoom = Vector2(0.66, 0.66)
	camara.reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-azotea-entera.png")
	camara.zoom = Vector2.ONE
	luz.alternar()
	# sin el jefe se abre la escalera de incendios. El gerente cae de verdad (el jefe final no saca mutaciones); la
	# portera (si aún no estuviera el gerente), quitada sin que caiga: así no salen las mutaciones
	var es_final := jefa != null and not final_de(planta.jefe).is_empty()
	if es_final:
		# que su página del dosier salga al caer (probar_historia ya la ha apuntado)
		Guardado.cambiar(func(g):
			g.paginas.erase("cc_recogida")
			g.paginas.erase("vd7_sujeto_cero"))
	if jefa:
		for z in get_tree().get_nodes_in_group("zombis"):
			if z != jefa:
				z.queue_free()   # (los empleados del gerente)
		if es_final:
			jefa.invulnerable = false
			jefa.recibir_golpe(99999, Vector2.ZERO)
		else:
			jefa.queue_free()
			$Pantalla/Jefa.hide()
	johnny.position = mapa.puertas[1].llegada() + Vector2(-90, 0)
	camara.reset_smoothing()
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-azotea-incendios.png")
	print("  sin el jefe: jefe muerto %s | incendios %s | aviso: '%s'" % [planta.jefa_muerta,
		"abierta" if mapa.puertas[1].abierta else "cerrada", aviso.text])
	if es_final:
		# al rato, su página del dosier (con el juego parado); al cerrarla, el helicóptero (captura-helicoptero.png)
		await get_tree().create_timer(1.3).timeout
		print("  al caer el gerente: página del dosier abierta %s | juego parado %s" % [menus.abierto == "pagina",
			get_tree().paused])
		menus.leida()
		var helipuerto: Vector2 = s.get("helipuerto", johnny.position)
		johnny.position = helipuerto + Vector2(-170, 150)
		camara.zoom = Vector2(0.8, 0.8)
		camara.reset_smoothing()
		await get_tree().create_timer(0.8 + Helicoptero.LLEGADA + 0.5).timeout
		Captura.foto("captura-helicoptero.png")
		var helis: Array = mapa.cosas.get_children().filter(func(n): return n is Helicoptero)
		print("  helicóptero de Velaria: %d | sobre el helipuerto %s | aviso: '%s'" % [helis.size(),
			not helis.is_empty() and helis[0].llegado and helis[0].position.distance_to(helipuerto) < 1.0, aviso.text])
		camara.zoom = Vector2.ONE
		print("  al caer el gerente, mutación: %s" % ("sí (¡no debería!)" if menus.abierto == "mutacion" else "no"))


# El científico jefe (el jefe final de los Apartamentos): las probetas (captura-cientifico.png), la cúpula a
# golpes hasta rompérsela (captura-cientifico-cupula.png), el suero a dos vecinos (captura-cientifico-suero.png), la
# jeringa a media vida (captura-cientifico-jeringa.png) y el cambio (captura-cientifico-muta.png); la criatura con
# las lenguas (captura-criatura.png), el puñetazo (captura-criatura-punetazo.png) y escupiendo fuego
# (captura-criatura-fuego.png). Lo que comprueba lo escribe en la terminal
func probar_cientifico_jefe(camara: Camera2D) -> void:
	var cerca := func(lejos: float, hacia := PI / 2.0) -> void:   # Johnny cerca de él, donde se pueda estar y a la vista
		for i in 60:
			johnny.position = jefa.position + Vector2.from_angle(hacia + randf_range(-0.6, 0.6)) * lejos
			if mapa.zona_en(johnny.position) >= 0 and jefa.a_la_vista(johnny):
				break
		camara.reset_smoothing()
	# las probetas, recién tiradas
	cerca.call(300.0, PI)
	jefa.foto(johnny)
	await get_tree().create_timer(0.35).timeout
	Captura.foto("captura-cientifico.png")
	var en_el_aire := jefa.get_parent().get_children().filter(func(n): return str(n.get("tipo")).begins_with("probeta")).size()
	print("  el científico: vida %d/%d | barra: '%s' | probetas en el aire: %d | estado %s" % [jefa.vida, jefa.vida_max,
		$Pantalla/Jefa/Nombre.text, en_el_aire, jefa.estado])
	await get_tree().create_timer(1.3).timeout
	var charcos: Array = jefa.get_parent().get_children().filter(func(n): return n.get("tipo") in ["acido", "veneno", "aceite"])
	print("  al caer: charcos %s" % [charcos.map(func(c): return c.tipo)])
	# la cúpula: se mete y Johnny le da hasta rompérsela (los golpes se los lleva ella, con su barra azul)
	jefa.subir_cupula()
	await get_tree().create_timer(0.6).timeout
	var vida_antes: int = jefa.vida
	jefa.recibir_golpe(60, Vector2.RIGHT * 300.0)
	await get_tree().create_timer(0.1).timeout
	Captura.foto("captura-cientifico-cupula.png")
	print("  cúpula: %d/%d tras un golpe de 60 | a él le ha quitado %d | barra azul visible %s" % [jefa.cupula,
		jefa.CUPULA_VIDA, vida_antes - jefa.vida, armadura_jefe().visible])
	jefa.recibir_golpe(200, Vector2.RIGHT * 300.0)
	print("  otro de 200: cúpula %d | estado %s | vida %d" % [jefa.cupula, jefa.estado, jefa.vida])
	# el suero: dos vecinos al lado, inyectados
	var vecinos := []
	for i in 2:
		vecinos.append(meter_zombi("normal", jefa.position + Vector2(130.0 * (i * 2 - 1), 70.0)))
	await get_tree().physics_frame
	# (inyecta a los tres más cercanos: puede que a alguno de los sujetos que ya ha llamado él, en vez de a estos)
	var antes := vecinos.map(func(z): return [z.vida_max, int(z.velocidad), z.dano])
	jefa.cambiar("suero", {"hecho": true})
	jefa.inyectar()
	await get_tree().create_timer(0.15).timeout
	Captura.foto("captura-cientifico-suero.png")
	var con_suero: Array = get_tree().get_nodes_in_group("zombis").filter(func(z): return z.has_meta("suero"))
	print("  suero: un vecino normal (vida máx, velocidad, daño) %s | inyectados %d: %s" % [antes[0], con_suero.size(),
		con_suero.map(func(z): return [z.vida_max, int(z.velocidad), z.dano])])
	await get_tree().create_timer(1.1).timeout
	# a media vida: la jeringa y el cambio
	jefa.andar(5.0)
	cerca.call(190.0, PI)
	jefa.recibir_golpe(int(jefa.vida - jefa.vida_max * 0.5), Vector2.ZERO)
	await get_tree().create_timer(1.6).timeout
	Captura.foto("captura-cientifico-jeringa.png")
	print("  a media vida: %s (fotograma %d) | vida %d/%d | invulnerable %s" % [jefa.estado, jefa.sprite.frame,
		jefa.vida, jefa.vida_max, jefa.invulnerable])
	for i in 300:
		if jefa.mutado:
			break
		await get_tree().physics_frame
	await get_tree().create_timer(0.12).timeout
	Captura.foto("captura-cientifico-muta.png")
	while jefa.estado == "mutar":
		await get_tree().physics_frame
	print("  la criatura: %s | dibujo %s | radio %d | vida %d/%d | barra: '%s'" % [jefa.estado,
		jefa.sprite.sprite_frames.resource_path.get_file(), jefa.radio, jefa.vida, jefa.vida_max, $Pantalla/Jefa/Nombre.text])
	# las lenguas, recién soltadas
	cerca.call(200.0, 0.0)
	johnny.invulnerable = 0.0
	var vida_johnny: int = johnny.vida
	jefa.foto(johnny)
	await get_tree().create_timer(0.14).timeout
	Captura.foto("captura-criatura.png")
	print("  lenguas: %s | a Johnny le han quitado %d" % [jefa.estado, vida_johnny - johnny.vida])
	# el puñetazo: el círculo rojo y la onda
	await get_tree().create_timer(0.5).timeout
	cerca.call(150.0, 0.0)
	johnny.invulnerable = 0.0
	vida_johnny = johnny.vida
	jefa.empezar("aviso_punetazo", (johnny.position - jefa.position).angle())
	jefa.t = jefa.AVISO_PUNETAZO - 0.3
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-criatura-punetazo.png")
	await get_tree().create_timer(0.5).timeout
	print("  puñetazo: %s | a Johnny le ha quitado %d" % [jefa.estado, vida_johnny - johnny.vida])
	# y escupe fuego
	await get_tree().create_timer(0.5).timeout
	cerca.call(380.0, 0.0)
	jefa.empezar("aviso_fuego", (johnny.position - jefa.position).angle())
	jefa.t = jefa.AVISO_FUEGO - 0.05
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-criatura-fuego.png")
	print("  fuego: %s | bolas en el aire %d" % [jefa.estado, get_tree().get_nodes_in_group("balas_zombi").size()])
	for z in vecinos:
		if is_instance_valid(z):
			z.queue_free()


# El gerente, a media vida, se pincha VD-7 (captura-gerente-jeringa.png) y muta con un fogonazo
# (captura-gerente-muta.png); el mutado, con los latigazos (captura-mutado.png) y avisando la embestida
# (captura-mutado-embestida.png)
func probar_mutado(camara: Camera2D) -> void:
	for z in get_tree().get_nodes_in_group("zombis"):
		if z != jefa:
			z.queue_free()   # (los empleados del gerente)
	for papel in get_tree().get_nodes_in_group("balas_zombi"):
		papel.queue_free()
	var cerca := func(lejos: float, hacia := PI / 2.0) -> void:   # Johnny cerca de él, donde se pueda estar y a la vista
		for i in 60:
			johnny.position = jefa.position + Vector2.from_angle(hacia + randf_range(-0.6, 0.6)) * lejos
			if mapa.zona_en(johnny.position) >= 0 and jefa.a_la_vista(johnny):
				break
		camara.reset_smoothing()
	cerca.call(170.0, PI)   # (a un lado: así se le ve entero, con la jeringa)
	jefa.andar(5.0)
	jefa.recibir_golpe(int(jefa.vida - jefa.vida_max * 0.5), Vector2.ZERO)
	await get_tree().create_timer(1.5).timeout
	Captura.foto("captura-gerente-jeringa.png")
	print("  a media vida: %s (fotograma %d) | vida %d/%d | invulnerable %s" % [jefa.estado, jefa.sprite.frame,
		jefa.vida, jefa.vida_max, jefa.invulnerable])
	for i in 300:
		if jefa.mutado:
			break
		await get_tree().physics_frame
	await get_tree().create_timer(0.12).timeout
	Captura.foto("captura-gerente-muta.png")
	while jefa.estado == "mutar":
		await get_tree().physics_frame
	print("  mutado: %s | dibujo %s | radio %d | vida %d/%d | barra: '%s'" % [jefa.estado,
		jefa.sprite.sprite_frames.resource_path.get_file(), jefa.radio, jefa.vida, jefa.vida_max, $Pantalla/Jefa/Nombre.text])
	# los latigazos, recién soltados
	cerca.call(200.0, 0.0)
	johnny.invulnerable = 0.0
	var vida_johnny: int = johnny.vida
	jefa.foto(johnny)
	await get_tree().create_timer(0.14).timeout
	Captura.foto("captura-mutado.png")
	print("  latigazos: %s | a Johnny le han quitado %d" % [jefa.estado, vida_johnny - johnny.vida])
	# y la embestida: la franja roja, y luego sale corriendo
	await get_tree().create_timer(0.5).timeout
	cerca.call(400.0, 0.0)
	jefa.empezar("aviso_embestida", (johnny.position - jefa.position).angle())
	await get_tree().create_timer(0.55).timeout
	Captura.foto("captura-mutado-embestida.png")
	var estados := []
	for i in 30:
		await get_tree().create_timer(0.05).timeout
		if estados.is_empty() or estados[-1] != jefa.estado:
			estados.append(jefa.estado)
	print("  embestida: %s" % " → ".join(estados))


# Fotos de la pausa y del cartel de victoria (con el juego parado solo cuentan los temporizadores)
func probar_menus() -> void:
	set_process(false)
	# Johnny, como nuevo y sin charcos alrededor: el bombero deja el suelo ardiendo y le seguía quemando hasta
	# dejarle en un tercio; con la vida tan baja el bocadillo no se podía usar (se quedaba el inventario abierto y
	# el juego en pausa, y la prueba no se cerraba nunca) y en la azotea moría
	for c in get_tree().get_nodes_in_group("charcos"):
		c.remove_from_group("charcos")
		c.queue_free()
	johnny.estados.clear()
	johnny.tercios = 3
	johnny.vida = johnny.stats.vida_max
	soltar_billetes(3, johnny.position + Vector2(60, 0))
	await get_tree().create_timer(1.2).timeout
	print("Dólares de la partida: %d | muertos: %d" % [dolares, muertos])
	await probar_ordenador()
	await probar_cosas()
	await probar_creadas()
	await probar_objetos()
	await probar_curas()
	await probar_recetas()
	await supervivientes.probar()
	await probar_sangre()
	await probar_mutaciones()
	await probar_historia()
	await probar_colecciones()
	if ed.get("azotea", false):
		await probar_azotea()
	pausar()
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-pausa.png")
	seguir()
	terminar(true)
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-fin.png")
	print("Guardado de prueba: ", Guardado.cargar())
	get_tree().quit()
