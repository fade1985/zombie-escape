# La partida a medias (docs/LANZAMIENTO.md, «Robustez»): al empezar cada planta se apunta en el guardado una foto de
# lo que lleva la partida (lo de Johnny, la mochila, las mutaciones, lo sorteado al empezar...). Si el juego se cierra,
# el menú principal enseña «Continuar partida» y se vuelve al principio de esa planta, con lo que se llevaba al llegar
# a ella. Lo hecho dentro de la planta se pierde, como en Isaac. La planta sale igual (la semilla de la partida va en la
# foto: Planta.semilla), para que cerrar el juego no sirva para cambiar una planta que no gusta.
# Al acabar la partida (ganes, caigas o abandones) la foto se borra.
#
# La foto va en "en_curso" del guardado como texto de Godot (var_to_str): así los números enteros siguen siendo
# enteros al leerla (en JSON todos salen con decimales).
class_name PartidaGuardada

const VERSION := 1   # si cambia lo que lleva la foto, las de antes no se leen (se empieza de cero)

static var continuar := {}   # la foto con la que tiene que empezar la próxima partida (la pone el menú); {} = una nueva


# La partida guardada, o {} si no hay (o es de una versión vieja o de un edificio que ya no existe)
static func guardada(s := {}) -> Dictionary:
	if s.is_empty():
		s = Guardado.cargar()
	var texto: String = str(s.get("en_curso", ""))
	if texto == "":
		return {}
	var foto = str_to_var(texto)
	if not foto is Dictionary or foto.get("version", 0) != VERSION or not Edificios.LISTA.has(foto.get("edificio", "")):
		return {}
	return foto


# El menú, al pulsar «Continuar partida»: pone el edificio y la alerta de la foto y abre la partida
static func seguir(foto: Dictionary) -> void:
	if cargando:
		return   # (otra pulsación mientras sale la pantalla de carga)
	cargando = true
	continuar = foto
	Edificios.elegido = foto.edificio
	Alerta.nivel = foto.alerta
	Garaje.quitar()   # (el garaje del reto del día no se apunta a medias: siempre es una partida normal)
	await pantalla_de_carga()
	cargando = false
	Captura.ir_a_la_partida()


static var cargando := false   # mientras sale la pantalla de carga (no se sigue dos veces)


# Encima del menú, la pantalla se va a negro con «Cargando…»: generar la planta tarda un poco y, sin esto, el menú se
# quedaba quieto con el botón pulsado y parecía que el juego se había colgado. La partida empieza también en negro
# (partida.gd, continuar_partida) y se aclara al estar lista
static func pantalla_de_carga() -> void:
	var arbol := Engine.get_main_loop() as SceneTree
	var capa := CanvasLayer.new()
	capa.layer = 100
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.theme = Tema.crear()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)   # (y tapa el ratón: ya no se pulsa nada del menú)
	fondo.modulate.a = 0.0
	var texto := Label.new()
	texto.text = Idioma.t("Cargando…")
	texto.add_theme_font_size_override("font_size", 32)   # (la letra pixel art, nítida a 16 o a 32)
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fondo.add_child(texto)
	capa.add_child(fondo)
	arbol.current_scene.add_child(capa)
	await fondo.create_tween().tween_property(fondo, "modulate:a", 1.0, 0.2).finished
	if Captura.activa():   # (la prueba --continuar)
		await arbol.process_frame
		Captura.foto("captura-cargando.png")
	# dos fotogramas, para que el negro y el texto lleguen a la pantalla antes del parón de cargar
	await arbol.process_frame
	await arbol.process_frame


static func borrar() -> void:
	if str(Guardado.cargar().get("en_curso", "")) != "":
		Guardado.cambiar(func(g): g.en_curso = "")


# Justo antes de generar la planta "num" (al empezar la partida y al subir por las escaleras): la foto de la partida
static func apuntar(p: Node, num: int) -> void:
	var j: Node2D = p.johnny
	var sup: Supervivientes = p.supervivientes
	var lz: Lanzables = p.lanzables
	var rescate := {}
	if not sup.rescate.is_empty():
		rescate = {"id": Supervivientes.DATOS.find_key(sup.rescate.def), "planta": sup.rescate.planta,
			"rescatado": sup.rescate.rescatado, "horda_hecha": sup.rescate.horda_hecha}
	var equipo := []
	for a in sup.equipo:
		if a.vivo:
			equipo.append({"id": Supervivientes.DATOS.find_key(a.def), "vida": a.vida, "vecino": a.es_vecino,
				"rescatado": a == sup.rescate.get("amigo")})
	var foto := {
		"version": VERSION,
		"edificio": p.edificio, "alerta": Alerta.nivel,
		"semilla": Planta.semilla, "planta": num,
		# lo sorteado de la sala de mantenimiento y de las viviendas de la planta baja: al continuar más arriba se hacen
		# solo ellas con esto, sin generar otra vez la planta baja entera (tardaba casi medio segundo: partida.gd)
		"baja": [int(p.sala_mantenimiento.get("surtido", -1)), int(p.sala_viviendas.get("surtido", -1))],
		"orden_jefes": p.orden_jefes, "joyeria": Planta.joyeria_planta,
		"rescate": rescate, "equipo": equipo,
		"mutaciones": p.mutaciones.tengo, "eventos": p.eventos.usados,
		"logros": {"con_ayudas": p.logros.con_ayudas, "fregonazos": p.logros.fregonazos, "curado": p.logros.curado,
			"racha": p.logros.racha, "mejor_racha": p.logros.mejor_racha},
		"mochila": p.mochila, "orden_casillas": p.orden_casillas, "armas_guardadas": p.armas_guardadas,
		"dolares": p.dolares, "mutageno": p.mutageno, "mutageno_barra": p.mutageno_barra, "muertos": p.muertos, "matados": p.matados, "duracion": p.duracion, "al_empezar": p.al_empezar,
		"johnny": {"vida": j.vida, "tercios": j.tercios, "resucitado": j.resucitado, "copia_usada": j.copia_usada, "huecos": j.huecos,
			"calidades": j.calidades, "quedan": j.quedan, "mano": j.mano, "balas": j.balas, "municion": j.municion,
			"cargadores": j.cargadores, "deposito": j.deposito, "escudo_mut": j.escudo_mut},
		"lanzables": {"mano": lz.mano, "en_mano": lz.en_mano, "elegido": lz.elegido, "repuesto": lz.repuesto,
			"en_repuesto": lz.en_repuesto, "tipo": lz.tipo, "quedan": lz.quedan},
	}
	var texto := var_to_str(foto)
	Guardado.cambiar(func(g): g.en_curso = texto)


# Al gastar mutágeno en un talento (talentos.gd, subir): se le quita también a la foto que haya en el guardado "s" (sin
# bajar de 0), para que cerrar el juego no lo devuelva. No escribe el guardado: lo hace el que llama
# Lo mismo con los dólares de la partida gastados en la tienda de armas (ordenador.gd, pagar)
static func gastar_dolares(s: Dictionary, cuanto: int) -> void:
	var foto := guardada(s)
	if foto.is_empty():
		return
	foto.dolares = maxi(int(foto.get("dolares", 0)) - cuanto, 0)
	s.en_curso = var_to_str(foto)


static func gastar_mutageno(s: Dictionary, cuanto: int) -> void:
	var foto := guardada(s)
	if foto.is_empty():
		return
	foto.mutageno = maxi(int(foto.get("mutageno", 0)) - cuanto, 0)
	s.en_curso = var_to_str(foto)


# La partida, al empezar con una foto (partida.gd, _ready): todo lo de la partida como estaba al llegar a su planta.
# Lo que se genera (la planta) lo hace después partida.gd, como al subir
static func poner(p: Node, foto: Dictionary) -> void:
	var s := Guardado.cargar()
	Planta.semilla = foto.semilla
	Planta.joyeria_planta = foto.joyeria
	p.orden_jefes = foto.orden_jefes.duplicate()
	p.mutaciones.tengo = foto.mutaciones.duplicate()
	p.eventos.usados = foto.eventos.duplicate()
	for clave in foto.logros:
		p.logros.set(clave, foto.logros[clave])
	p.mochila = foto.mochila.duplicate()
	p.orden_casillas = foto.get("orden_casillas", {}).duplicate(true)   # (una foto de antes del 16 nov no lo trae)
	p.armas_guardadas = foto.armas_guardadas.duplicate()
	p.dolares = foto.dolares
	p.mutageno = foto.get("mutageno", 0)   # (una foto de antes del 15 nov no lo trae)
	p.mutageno_barra = int(foto.get("mutageno_barra", 0))   # (ni una de antes del 19 nov, la barra)
	p.muertos = foto.muertos
	p.matados = foto.get("matados", {}).duplicate()   # (una foto de antes del 8 nov no los trae)
	p.duracion = foto.duracion
	p.al_empezar = foto.al_empezar.duplicate(true)
	# Johnny: sus atributos (talentos y mutaciones), su vida y sus armas
	p.aplicar_talentos(s.talentos)
	var j: Node2D = p.johnny
	var fj: Dictionary = foto.johnny
	j.tercios = fj.tercios
	j.resucitado = fj.resucitado
	j.copia_usada = fj.get("copia_usada", false)   # (la skin del becario; las guardadas antes, sin)
	j.huecos = fj.huecos.duplicate()
	j.calidades = fj.calidades.duplicate()
	j.quedan = fj.get("quedan", {}).duplicate()   # (la durabilidad; las fotos de antes del 9 nov no la traen: nuevas)
	j.municion = fj.municion.duplicate()
	j.cargadores = fj.cargadores.duplicate()
	# lo que quedaba del escudo de Endurecimiento (las fotos de antes del 16 nov no lo traen: entero, si la tenía)
	j.escudo_mut = fj.get("escudo_mut", float(j.stats.escudo_mut))
	j.sostener(fj.mano)
	j.balas = fj.balas
	j.deposito = fj.deposito
	j.vida = mini(fj.vida, j.vida_tope())
	j.vida_cambiada.emit(j.vida, j.stats.vida_max)
	j.avisar_arma()
	var lz: Lanzables = p.lanzables
	lz.mano = foto.lanzables.mano.duplicate()
	# cuántos hay en cada montón de la mano (las fotos de antes del 16 nov, con un montón por clave, los traen en
	# "cantidades": {clave: cuántos})
	var cuantos: Array = foto.lanzables.en_mano if foto.lanzables.has("en_mano") \
		else lz.mano.map(func(k): return foto.lanzables.get("cantidades", {}).get(k, 0))
	lz.en_mano = cuantos.map(func(n): return int(n))
	lz.repuesto = foto.lanzables.repuesto.duplicate()
	lz.en_repuesto = foto.lanzables.en_repuesto.map(func(n): return int(n))
	lz.elegido = int(foto.lanzables.get("elegido", maxi(lz.mano.find(foto.lanzables.get("tipo", "")), 0)))
	lz.quedan = foto.lanzables.get("quedan", {}).duplicate()
	sobrantes_al_baul(lz, foto)
	# el superviviente de la partida y el equipo (el acompañante y el rescatado, si ya lo estaba)
	var sup: Supervivientes = p.supervivientes
	Planta.tienda_fija = {}
	Planta.rescate_planta = 0
	if not foto.rescate.is_empty() and Supervivientes.DATOS.has(foto.rescate.id):
		sup.poner_rescate(Supervivientes.DATOS[foto.rescate.id], foto.rescate.planta)
		sup.rescate.rescatado = foto.rescate.rescatado
		sup.rescate.horda_hecha = foto.rescate.horda_hecha
	for e in foto.equipo:
		if not Supervivientes.DATOS.has(e.id):
			continue
		var a := sup.crear(Supervivientes.DATOS[e.id], "equipo")
		a.vida = e.vida
		a.idx = sup.equipo.size()
		if e.vecino:
			a.es_vecino = true
			a.casa = Viviendas.casa(e.id)
		if e.rescatado and not sup.rescate.is_empty():
			sup.rescate.amigo = a
		sup.equipo.append(a)


# Las fotos de antes del 13 nov llevan montones de repuesto (hasta 8 antes del M67, luego 4) y ahora caben
# Lanzables.REPUESTO (ninguno): los que sobran
# van al baúl, para que no se pierdan, y la foto se queda sin ellos (si el juego se cierra otra vez, no se meten dos veces)
static func sobrantes_al_baul(lz: Lanzables, foto: Dictionary) -> void:
	if lz.repuesto.size() <= Lanzables.REPUESTO:
		return
	var claves: Array = lz.repuesto.slice(Lanzables.REPUESTO)
	var cuantos: Array = lz.en_repuesto.slice(Lanzables.REPUESTO)
	lz.repuesto = lz.repuesto.slice(0, Lanzables.REPUESTO)
	lz.en_repuesto = lz.en_repuesto.slice(0, Lanzables.REPUESTO)
	foto.lanzables.repuesto = lz.repuesto.duplicate()
	foto.lanzables.en_repuesto = lz.en_repuesto.duplicate()
	var texto := var_to_str(foto)
	Guardado.cambiar(func(g):
		for i in claves.size():
			Objetos.arrojables_al_baul(g, Lanzables.tipo_de(claves[i]), Lanzables.calidad_de(claves[i]), cuantos[i])
		g.en_curso = texto)
