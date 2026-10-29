# La partida a medias (docs/LANZAMIENTO.md, «Robustez»): al empezar cada planta se apunta en el guardado una foto de
# lo que lleva la partida (lo de Johnny, la mochila, las mutaciones, lo sorteado al empezar...). Si el juego se cierra,
# el menú principal enseña «Continuar partida» y se vuelve al principio de esa planta, con lo que se llevaba al llegar
# a ella. Lo hecho dentro de la planta se pierde, como en Isaac. La planta sale igual (la semilla de la partida va en la
# foto: Planta.semilla), para que cerrar el juego no sirva para cambiar una planta que no gusta.
# Al acabar la partida (ganes, caigas o abandones) la foto se borra. En el reto del día, con sus mismas reglas.
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


# El menú, al pulsar «Continuar partida»: pone el edificio, la alerta y el reto de la foto y abre la partida
static func seguir(foto: Dictionary) -> void:
	continuar = foto
	Edificios.elegido = foto.edificio
	Alerta.nivel = foto.alerta
	if foto.reto.activo:
		Reto.empezar(foto.edificio, foto.reto.fecha)
		Reto.regla = foto.reto.regla
	else:
		Reto.quitar()
	Captura.ir_a_la_partida()


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
		"reto": {"activo": Reto.activo, "fecha": Reto.fecha, "regla": Reto.regla},
		"semilla": Planta.semilla, "planta": num,
		"orden_jefes": p.orden_jefes, "joyeria": Planta.joyeria_planta,
		"rescate": rescate, "equipo": equipo,
		"mutaciones": p.mutaciones.tengo, "eventos": p.eventos.usados,
		"logros": {"con_ayudas": p.logros.con_ayudas, "fregonazos": p.logros.fregonazos, "curado": p.logros.curado,
			"racha": p.logros.racha, "mejor_racha": p.logros.mejor_racha},
		"mochila": p.mochila, "armas_guardadas": p.armas_guardadas,
		"dolares": p.dolares, "muertos": p.muertos, "duracion": p.duracion, "al_empezar": p.al_empezar,
		"johnny": {"vida": j.vida, "tercios": j.tercios, "resucitado": j.resucitado, "huecos": j.huecos,
			"calidades": j.calidades, "mano": j.mano, "balas": j.balas, "municion": j.municion,
			"cargadores": j.cargadores, "deposito": j.deposito},
		"lanzables": {"cantidades": lz.cantidades, "mano": lz.mano, "repuesto": lz.repuesto,
			"en_repuesto": lz.en_repuesto, "tipo": lz.tipo},
	}
	var texto := var_to_str(foto)
	Guardado.cambiar(func(g): g.en_curso = texto)


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
	p.armas_guardadas = foto.armas_guardadas.duplicate()
	p.dolares = foto.dolares
	p.muertos = foto.muertos
	p.duracion = foto.duracion
	p.al_empezar = foto.al_empezar.duplicate(true)
	# Johnny: sus atributos (talentos y mutaciones), su vida y sus armas
	p.aplicar_talentos(s.talentos)
	var j: Node2D = p.johnny
	var fj: Dictionary = foto.johnny
	j.tercios = fj.tercios
	j.resucitado = fj.resucitado
	j.huecos = fj.huecos.duplicate()
	j.calidades = fj.calidades.duplicate()
	j.municion = fj.municion.duplicate()
	j.cargadores = fj.cargadores.duplicate()
	j.sostener(fj.mano)
	j.balas = fj.balas
	j.deposito = fj.deposito
	j.vida = mini(fj.vida, j.vida_tope())
	j.vida_cambiada.emit(j.vida, j.stats.vida_max)
	j.avisar_arma()
	var lz: Lanzables = p.lanzables
	lz.cantidades = foto.lanzables.cantidades.duplicate()
	lz.mano = foto.lanzables.mano.duplicate()
	lz.repuesto = foto.lanzables.repuesto.duplicate()
	lz.en_repuesto = foto.lanzables.en_repuesto.duplicate()
	lz.tipo = foto.lanzables.tipo
	# el superviviente de la partida y el equipo (el acompañante y el rescatado, si ya lo estaba)
	var sup: Supervivientes = p.supervivientes
	Planta.tienda_fija = {}
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
