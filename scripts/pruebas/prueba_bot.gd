# Las pruebas del jugador automático (el bot, bot.gd; docs/BOT.md). Parte de la cadena de la partida de prueba (ver
# partida_prueba.gd).
#
# Con "--captura --bot-jefes" (y --edificio X, el de los Apartamentos si no se dice): Johnny, recién empezado (la pistola
# y la fregona, sin talentos ni mutaciones), pelea él solo con cada jefe del edificio (los cuatro minijefes, cada uno en
# la planta que le toca en el sorteo, y el jefe final en la azotea) varias veces y a tres niveles de jugador (novato,
# normal y bueno). Cada pelea va en una línea de capturas/bot/jefes-<edificio>-<semilla>.jsonl, para que
# tools/bot.py haga el resumen. Opciones:
#   --peleas N            cuántas peleas con cada jefe y nivel (5)
#   --niveles a,b         qué niveles (novato,normal,bueno)
#   --jefes a,b           qué jefes (todos los del edificio; el final se llama como su escena: cientifico_jefe...)
#   --semilla S           la semilla del azar (si no, una cualquiera; va en el nombre del archivo)
# Sin fotos: se puede lanzar con --headless --fixed-fps 60, que va a toda prisa (tools/bot.py lo hace así).
#
# La vida: Johnny pelea con muchísima vida (VIDA_BOT) para que no se caiga de verdad (el cartel de derrota pararía la
# prueba) y la vida que tendría se lleva aparte: cuando llega a 0, la pelea está perdida. Los tercios que pierde sí se le
# quitan (anda más despacio), como en el juego.
extends "res://scripts/pruebas/trailer.gd"

const BOT := preload("res://scripts/pruebas/bot.gd")
const VIDA_BOT := 1000000
const PELEA_MAX := 180.0   # (s de juego) una pelea que dura más se da por no acabada
const MUNICION_BOT := 300  # las balas de reserva de la pistola en cada pelea
var bot: Node = null
var con_bot := false       # mientras juega el bot: sin el recuadro de las mutaciones ni el final del edificio
var municion_inicial := {}


# Tras un jefe, el recuadro de las mutaciones pararía el juego (y la mutación cambiaría a Johnny para la siguiente
# pelea): con el bot de los jefes, no sale; con el de la partida, elige una al azar sin abrirlo
func abrir_mutacion() -> void:
	if con_bot or elegir_mutacion_bot():
		return
	await super()


# El final del edificio (el helicóptero, el laboratorio): con el bot de los jefes, la pelea acaba al caer el jefe y sigue
# la siguiente; con el de la partida, ha ganado
func fin_del_edificio() -> void:
	if con_bot:
		return
	if con_bot_partida:
		bot_gana = true
		return
	await super()


func probar_bot_jefes() -> void:
	con_bot = true
	# Con --fixed-fps 60, cada fotograma es 1/60 s de juego: cuantos más fotogramas por segundo, más deprisa va. Sin tope
	# ni esperar a la pantalla (con ventana va más rápido que con --headless, que se queja a cada paso)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Guardado.cambiar(func(g):
		g.ajustes.temblor = 0   # sin los parones de los golpes (Temblor cambia Engine.time_scale)
		g.ajustes.disparo_asistido = false
		g.acompanante = "")   # solo, sin el rescatado que acompaña (en el guardado de prueba suele haber uno)
	# Munición de sobra (MUNICION_BOT): se mide la pelea, no lo que se ha recogido antes por la planta (eso, la fase 2)
	municion_inicial = johnny.municion.duplicate()
	var tipo_pistola: String = johnny.base("pistola").municion
	municion_inicial[tipo_pistola] = maxi(int(municion_inicial.get(tipo_pistola, 0)), MUNICION_BOT)
	var semilla := int(Captura.dato("--semilla", str(randi() % 100000)))
	seed(semilla)
	bot = BOT.new()
	bot.partida = self
	bot.johnny = johnny
	add_child(bot)
	var peleas := int(Captura.dato("--peleas", "5"))
	var niveles := Captura.dato("--niveles", "novato,normal,bueno").split(",")
	var jefes: Array = ed.minijefes.duplicate()
	if ZOMBIS.has(ed.get("final", "")):
		jefes.append(ed.final)
	var pedidos := Captura.dato("--jefes")
	if pedidos != "":
		jefes = jefes.filter(func(j): return j in pedidos.split(","))
	DirAccess.make_dir_recursive_absolute(Captura.CARPETA + "bot")
	var ruta := Captura.CARPETA + "bot/jefes-%s-%d.jsonl" % [edificio, semilla]
	# (si ya existe, se añade al final: tools/bot.py --misma-planta lanza un jefe cada vez con la misma semilla)
	var archivo: FileAccess
	if FileAccess.file_exists(ruta):
		archivo = FileAccess.open(ruta, FileAccess.READ_WRITE)
		archivo.seek_end()
	else:
		archivo = FileAccess.open(ruta, FileAccess.WRITE)
	print("BOT: %s, jefes %s, niveles %s, %d peleas de cada, semilla %d → %s" % [edificio, jefes, niveles, peleas, semilla, ruta])
	await get_tree().create_timer(0.3).timeout
	for tipo in jefes:
		for nivel in niveles:
			for i in peleas:
				var r := await pelear(tipo, nivel)
				r.merge({"edificio": edificio, "jefe": tipo, "nivel": nivel, "semilla": semilla, "n": i})
				archivo.store_line(JSON.stringify(r))
				archivo.flush()
				print("BOT: %s %s #%d: %s en %d s, le quitan %d de %d%s" % [tipo, nivel, i + 1,
					"GANA" if r.get("gana") else ("NO ACABA" if r.get("no_acaba") else "PIERDE"), roundi(r.get("segundos", 0)),
					r.get("dano", 0), r.get("vida_max", 0), " (%s)" % r.error if r.has("error") else ""])
	archivo.close()
	bot.parar()
	print("BOT: TERMINADO")
	get_tree().quit()


# Johnny como al empezar: con toda la vida, sin nada encima y con la munición del principio
func reponer_johnny() -> void:
	johnny.vida = johnny.stats.vida_max
	johnny.tercios = 3
	johnny.invulnerable = 0.0
	johnny.estados.clear()
	johnny.municion = municion_inicial.duplicate()
	johnny.sostener("fuego")
	johnny.balas = johnny.base("pistola").cargador
	johnny.recargando = 0.0
	johnny.esquiva_espera = 0.0
	# y dos molotovs y dos granadas a mano, como las demás pruebas (los tira bot.gd, lanzar)
	lanzables.mano.clear()
	for k in ["molotov", "granada"]:
		lanzables.cantidades[k] = 2
		lanzables.mano.append(k)
	lanzables.tipo = "molotov"


# Una pelea con "tipo" a ese nivel. Devuelve lo que ha pasado: si gana, lo que tarda, el daño que le hacen (y de quién)
func pelear(tipo: String, nivel: String) -> Dictionary:
	bot.parar()
	reponer_johnny()
	if tipo == ed.get("final", ""):
		await ir_a_la_azotea()
	else:
		ir_al_jefe(tipo)
		var espera := 0.0
		while not cambiando and espera < 1.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
		while (cambiando or not is_instance_valid(jefa)) and espera < 6.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
	if not is_instance_valid(jefa):
		return {"error": "no ha salido el jefe"}
	for a in supervivientes.equipo:   # (y sin nadie que le ayude)
		if is_instance_valid(a):
			a.queue_free()
	supervivientes.equipo.clear()
	reponer_johnny()
	var vida_max: int = johnny.stats.vida_max
	johnny.vida = VIDA_BOT
	# el daño que le hacen, apuntado por quién (johnny.golpe_de: el jefe, un charco, sus esbirros...)
	var cuenta := {"antes": VIDA_BOT, "de": {}}
	var al_cambiar := func(v: int, _m: int) -> void:
		var quitado: int = cuenta.antes - v
		cuenta.antes = v
		if quitado > 0:
			var quien: String = johnny.golpe_de if johnny.golpe_de != "" else "?"
			cuenta.de[quien] = cuenta.de.get(quien, 0) + quitado
	johnny.vida_cambiada.connect(al_cambiar)
	var el_jefe: Node2D = jefa
	var vida_jefe := float(el_jefe.get("vida_max") if el_jefe.get("vida_max") != null else el_jefe.vida)
	bot.empezar(nivel)
	var tiempo := 0.0
	var parado := 0.0
	var sin_jefe := 0.0
	var r := {}
	while true:
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		if get_tree().paused:
			parado += delta
			if parado > 5.0:
				r.error = "el juego se ha quedado en pausa (%s)" % menus.abierto
				break
			continue
		tiempo += delta
		# con --fotos-bot, una foto cada 3 s de la pelea, para ver cómo juega (capturas/bot-<jefe>-<nivel>-<s>.png)
		if "--fotos-bot" in OS.get_cmdline_user_args() and fmod(tiempo, 3.0) < delta:
			Captura.foto("bot-%s-%s-%02d.png" % [tipo, nivel, roundi(tiempo)])
		var dano: int = VIDA_BOT - johnny.vida
		var queda := vida_max - dano
		johnny.tercios = clampi(ceili(queda / (vida_max / 3.0) - 0.000001), 1, 3)
		if queda <= 0:
			r.gana = false
			break
		# ha caído el jefe (y no queda otro grande: la criatura del científico, por ejemplo)
		if planta.jefa_muerta or not bot.vale(jefa):
			sin_jefe += delta
			if planta.jefa_muerta or (sin_jefe > 1.5 and bot.jefes().is_empty()):
				r.gana = true
				break
		else:
			sin_jefe = 0.0
		if tiempo > PELEA_MAX:
			r.gana = false
			r.no_acaba = true
			break
	bot.parar()
	johnny.vida_cambiada.disconnect(al_cambiar)
	var dano_total: int = VIDA_BOT - johnny.vida
	r.merge({"segundos": snappedf(tiempo, 0.1), "dano": dano_total, "vida_max": vida_max, "de": cuenta.de,
		"esquivas": bot.esquivas, "lanzados": bot.lanzados, "planta": planta.num,
		"jefe_queda": 0.0 if r.get("gana") or not is_instance_valid(el_jefe) else snappedf(maxf(el_jefe.vida, 0) / vida_jefe, 0.01)})
	johnny.vida = johnny.stats.vida_max
	return r


# A la azotea, con el jefe final: Johnny sube al ring para que deje de esperar (como en --cupula)
func ir_a_la_azotea() -> void:
	nueva_planta(Planta.PLANTAS)
	await montar(0, puerta_de_llegada(), false)
	await get_tree().create_timer(1.0).timeout
	var s: Dictionary = planta.sitios[0]
	if s.has("helipuerto"):
		johnny.position = Vector2(Planta.plataforma(s).end.x - 60.0, s.helipuerto.y)
	var espera := 0.0
	while espera < 5.0 and (not is_instance_valid(jefa) or jefa.get("esperando")):
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()


# ── Fase 2: una partida entera ──
#
# Con "--captura --bot-partida" (y --edificio X; --nivel novato/normal/bueno, normal si no se dice; --semilla S): el bot
# juega una partida de verdad desde la sala de mantenimiento, como una persona: sale al pasillo, limpia los apartamentos
# (o las tiendas), coge la llave, mata al jefe (y elige una mutación al azar), sube por las escaleras... hasta que muere,
# acaba el edificio o se atasca. Johnny recién empezado (la pistola y la fregona, 2 molotovs y 2 granadas), con su
# munición de verdad y su vida de verdad (se cura con las vendas y el botiquín que encuentre). Lo apunta, con cada planta
# (lo que tarda, la vida con la que llega al jefe, quién le quita vida), en capturas/bot/partida-<edificio>-<nivel>-<semilla>.jsonl.
# Si se queda atascado (20 s sin moverse ni pelear), saca una foto (capturas/bot/atasco-...png) y lo apunta: así
# salen las puertas que no se abren, los zombis trabados y lo que el bot aún no sabe hacer.
# Lo que no hace aún: leer los terminales del código (Torre Velaria), usar muebles, la tienda o el ordenador.

const PARTIDA_MAX := 2400.0   # (s de juego) una partida que dura más se da por atascada
var con_bot_partida := false
var bot_gana := false
var cruzar_t := 0.0

# ── Fase 3: la carrera (tools/bot.py --carrera) ──
# Partidas seguidas con el mismo guardado, como alguien que juega hasta pasarse el edificio. En la sala de
# mantenimiento, al empezar, compra en el ordenador (las mutaciones del árbol con el mutágeno; en la tienda, molotovs,
# granadas y el mejor arma cuerpo a cuerpo que le llegue) y saca del baúl lo comprado. El mutágeno que se coge en una
# partida se pierde al caer, así que el listo vuelve al ordenador a gastarlo: en la planta 1, antes del jefe (andando),
# y en las demás, en cuanto cae el jefe (en el ascensor). El despistado solo compra al empezar.
# Las mutaciones, por este orden: de cada una, primero el 1.er punto de todas, luego el 2.º... (lo barato primero)
const PRIORIDAD := ["durito", "corpulento", "ataque", "tirador", "reflejos", "camorrista", "acero", "mirilla", "lobezno",
	"sanitario", "larguirucho", "blindaje", "gatillo", "frenesi", "desfibrilador", "aliento", "ninja", "veterano",
	"adrenalina", "artificiero", "punteria", "fabricante", "sombra", "racimo"]
const CUERPO_MEJORES := ["motosierra", "katana", "bate", "cuchillo"]   # de mejor a peor (la fregona, la peor)
const LANZABLES_BOT := 2   # los molotovs y las granadas que quiere llevar de cada
var carrera := ""          # el nombre de la carrera (--bot-carrera X); vacío, una partida suelta
var listo := true
var en_sala := ""          # lo que hace en la sala de mantenimiento: "ordenador", "baul" o "" (ya ha acabado o no está)
var visita := ""           # el momento (bot_momento()) en el que ha ido a la sala por última vez
var compras := []          # lo que ha comprado en esta partida, para el informe
var recoger_t := 0.0       # (s) lo que lleva yendo a por lo que hay en el suelo de este sitio: con 15, lo deja
# Lo que no consigue alcanzar (un zombi o una cosa del suelo detrás de un mueble o de una puerta): tras 10 s atascado
# yendo hacia ello, lo olvida hasta que cambia de sitio. Antes, a los 6 s, pulsa «usar», como haría una persona
var olvidadas := []
var sitio_antes := -1
var meta_cosa := false     # la meta es un zombi o una cosa del suelo (no una puerta ni un mueble)


# La partida del bot, con su propio guardado (una copia del de prueba): así se puede jugar a la vez que otra prueba y lo
# que gane o pierda no toca el guardado de prueba de las demás
func preparar_prueba() -> void:
	super()
	var args := OS.get_cmdline_user_args()
	if "--bot-carrera" in args:
		# la carrera (fase 3): su propio guardado, que pasa de una partida a la siguiente. La primera («--nueva»)
		# empieza de cero, como alguien que acaba de instalar el juego, con el regalo de bienvenida de la tienda ya
		# cogido: la pistola (en la mano: la de prueba_comun) y un lanzable de cada, al baúl (sin él no sale de la sala)
		carrera = Captura.dato("--bot-carrera", "bot")
		listo = not "--despistado" in args
		Guardado.usar("user://carrera-" + carrera)
		if "--nueva" in args:
			var g: Dictionary = Guardado.NUEVO.duplicate(true)
			for k in preload("res://scripts/ui/tienda_armas.gd").REGALO_LANZABLES:
				Objetos.arrojables_al_baul(g, k, 0, 1)
			g.regalos_lanzables = preload("res://scripts/ui/tienda_armas.gd").REGALO_LANZABLES.duplicate()
			Guardado.escribir(g)
		Guardado.cambiar(func(g):
			g.ajustes.tutoriales = false
			g.regalo_cogido = true)
	elif "--bot-partida" in args:
		var g := Guardado.cargar()
		Guardado.usar("user://guardado-bot-%s" % Captura.dato("--semilla", "0"))
		Guardado.escribir(g)


# Johnny elige una de las dos mutaciones al azar, sin abrir el recuadro (que pararía el juego)
func elegir_mutacion_bot() -> bool:
	if not con_bot_partida:
		return false
	if mutaciones.tengo.size() < Mutaciones.MAXIMO:
		var opciones := mutaciones.sortear()
		if not opciones.is_empty():
			elegir_mutacion(opciones.pick_random().id)
	return true


func probar_bot_partida() -> void:
	con_bot_partida = true
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Guardado.cambiar(func(g):
		g.ajustes.temblor = 0
		g.ajustes.disparo_asistido = false
		g.acompanante = "")
	var nivel := Captura.dato("--nivel", "normal")
	var semilla := int(Captura.dato("--semilla", str(randi() % 100000)))
	seed(semilla)
	bot = BOT.new()
	bot.partida = self
	bot.johnny = johnny
	add_child(bot)
	for a in supervivientes.equipo:
		if is_instance_valid(a):
			a.queue_free()
	supervivientes.equipo.clear()
	await get_tree().create_timer(0.5).timeout
	bot.empezar(nivel)
	var r := {"edificio": edificio, "nivel": nivel, "semilla": semilla, "plantas": [], "atascos": [], "pausas": {}}
	var al_empezar_s := Guardado.cargar()
	if carrera != "":
		r.carrera = carrera
		r.listo = listo
		r.partida = int(al_empezar_s.partidas)
		r.ahorro_al_empezar = {"dolares": int(al_empezar_s.dolares), "mutageno": int(al_empezar_s.mutageno)}
	var cogido := {"mutageno": 0, "antes": mutageno}   # el mutágeno que coge en la partida (lo gaste o no)
	var cuenta := {"antes": johnny.vida}
	var al_cambiar := func(v: int, _m: int) -> void:
		var quitado: int = cuenta.antes - v
		cuenta.antes = v
		if quitado > 0 and not r.plantas.is_empty():
			var quien: String = johnny.golpe_de if johnny.golpe_de != "" else "?"
			var de: Dictionary = r.plantas[-1].de
			de[quien] = de.get(quien, 0) + quitado
	johnny.vida_cambiada.connect(al_cambiar)
	var tiempo := 0.0
	var pensar := 0.0
	var quieto_t := 0.0
	var parado := 0.0
	var donde: Vector2 = johnny.global_position
	var planta_num := -1
	while true:
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		if not johnny.vivo:
			r.final = "muere"
			r.muere = {"planta": planta.num, "sitio": planta.sitios[aqui].tipo, "de": johnny.golpe_de}
			break
		if bot_gana:
			r.final = "gana"
			break
		if get_tree().paused:
			if menus.abierto == "mutacion":
				continue
			# (el ordenador al arrimarse a su mesa, una página, la tele, un tutorial: al medio segundo se cierra, como lo
			# haría una persona, y se apunta qué era)
			parado += delta
			if parado > 0.5:
				parado = 0.0
				var que: String = menus.abierto
				if ordenador.fondo != null:
					que = "ordenador"
					ordenador.apagar()
				if inventario.abierto != "":
					que = inventario.abierto
					inventario.cerrar()
				r.pausas[que if que != "" else "?"] = r.pausas.get(que if que != "" else "?", 0) + 1
				menus.cerrar()
				get_tree().paused = false
			continue
		parado = 0.0
		tiempo += delta
		if mutageno > cogido.antes:
			cogido.mutageno += mutageno - cogido.antes
		cogido.antes = mutageno
		if tiempo > PARTIDA_MAX:
			r.final = "no acaba"
			break
		if planta.num != planta_num:
			planta_num = planta.num
			r.plantas.append({"planta": planta.num, "entra": snappedf(tiempo, 0.1), "de": {}, "dolares": cartera()})
		var esta: Dictionary = r.plantas[-1]
		if planta.sitios[aqui].tipo == "jefe" and not esta.has("vida_al_jefe"):
			esta.vida_al_jefe = johnny.vida
			esta.llega_jefe = snappedf(tiempo, 0.1)
			esta.balas_al_jefe = johnny.balas + int(johnny.municion.get(johnny.base("pistola").municion, 0))
			esta.cuerpo_a_cuerpo = 0.0
		# (cuánto rato pelea con el jefe solo con la fregona: se ha quedado sin balas)
		if esta.has("cuerpo_a_cuerpo") and not planta.jefa_muerta and johnny.arma().tipo == "cuerpo":
			esta.cuerpo_a_cuerpo += delta
		if planta.jefa_muerta and not esta.has("jefe_muerto"):
			esta.jefe_muerto = snappedf(tiempo, 0.1)
		pensar -= delta
		cruzar_t -= delta
		if pensar <= 0.0:
			pensar = 0.25
			decidir_bot()
		# atascos: 20 s sin moverse (40 px) ni pelear
		if johnny.global_position.distance_to(donde) > 40.0 or bot.en_pelea() or cambiando:
			donde = johnny.global_position
			quieto_t = 0.0
		else:
			quieto_t += delta
		if Input.is_action_pressed("usar"):
			Input.action_release("usar")
		if quieto_t > 6.0 and quieto_t - delta <= 6.0:
			Input.action_press("usar")
		if quieto_t > 10.0 and meta_cosa and bot.meta != Vector2.INF:
			olvidadas.append(bot.meta)
			r.olvidadas = r.get("olvidadas", 0) + 1
			meta_cosa = false
			quieto_t = 0.0
		if quieto_t > 20.0:
			quieto_t = 0.0
			var foto := "bot/atasco-%s-%d-%d.png" % [edificio, semilla, r.atascos.size() + 1]
			Captura.foto(foto)
			r.atascos.append({"planta": planta.num, "sitio": planta.sitios[aqui].tipo, "pos": [roundi(donde.x), roundi(donde.y)],
				"meta": str(bot.meta), "llave": planta.tiene_llave, "jefe_muerto": planta.jefa_muerta,
				"zombis": get_tree().get_nodes_in_group("zombis").size(), "foto": foto})
			print("BOT: ATASCO en la planta %d (%s): %s" % [planta.num, planta.sitios[aqui].tipo, r.atascos[-1]])
			if r.atascos.size() >= 3:
				r.final = "atasco"
				break
	bot.parar()
	r.segundos = snappedf(tiempo, 0.1)
	r.dolares = cartera()
	r.planta_max = planta.num
	var ruta := Captura.CARPETA + "bot/partida-%s-%s-%d.jsonl" % [edificio, nivel, semilla]
	if carrera != "":
		# la partida se cierra como en el juego (lo que se guarda al caer o al ganar: partida.terminar), y se apunta en
		# la carrera lo que se ha cogido, comprado y guardado
		if not terminada:
			terminar(false)
		var espera := 0.0
		while not terminada and espera < 5.0:
			await get_tree().create_timer(0.1, true).timeout
			espera += 0.1
		var s := Guardado.cargar()
		r.mutageno_cogido = cogido.mutageno
		r.compras = compras
		r.talentos = s.talentos.duplicate()
		r.puntos = Talentos.puestos(s)
		r.mutaciones = mutaciones.tengo.duplicate()
		r.ahorro_al_acabar = {"dolares": int(s.dolares), "mutageno": int(s.mutageno)}
		ruta = Captura.CARPETA + "bot/carrera-%s.jsonl" % carrera
	DirAccess.make_dir_recursive_absolute(Captura.CARPETA + "bot")
	var archivo: FileAccess
	if carrera != "" and FileAccess.file_exists(ruta) and not "--nueva" in OS.get_cmdline_user_args():
		archivo = FileAccess.open(ruta, FileAccess.READ_WRITE)
		archivo.seek_end()
	else:
		archivo = FileAccess.open(ruta, FileAccess.WRITE)
	archivo.store_line(JSON.stringify(r))
	archivo.close()
	print("BOT: PARTIDA %s %s: %s en la planta %d tras %d s%s" % [edificio, nivel, r.final.to_upper(), planta.num,
		roundi(tiempo), " (%s)" % r.muere if r.has("muere") else ""])
	print("BOT: TERMINADO")
	get_tree().quit()


# Adónde va ahora: la llave si está en el suelo; en un sitio con zombis, a por el más cercano; limpio, de vuelta al
# pasillo; y en el pasillo, a la puerta que toca (las escaleras con el jefe muerto, la del jefe con la llave, si no, el
# sitio más cercano sin limpiar). Al llegar a la puerta, la cruza. Y se cura si le queda poca vida
func decidir_bot() -> void:
	bot.meta = Vector2.INF
	if cambiando or mapa == null:
		return
	if johnny.vida < johnny.stats.vida_max * 0.4:
		for id in ["botiquin", "vendas"]:
			if id in mochila:
				usar_cura(id)
				break
	var sitio: Dictionary = planta.sitios[aqui]
	meta_cosa = false
	if aqui != sitio_antes:
		sitio_antes = aqui
		olvidadas.clear()
	if carrera != "" and decidir_carrera(sitio):
		return
	if not planta.tiene_llave and not planta.get("llave_usada", false) and planta.llave.get("sitio", -1) == aqui:
		bot.meta = mapa.to_global(planta.llave.pos)
		return
	var puerta: Node2D = null
	if sitio.tipo != "pasillo":
		if not sitio.get("limpio", false) and not sitio.tipo in ["mantenimiento", "viviendas"]:
			# (el más cercano al que se puede llegar: el camino acaba junto a él; uno detrás de una puerta con llave, no)
			var cerca := INF
			var mapa_nav: RID = johnny.get_world_2d().navigation_map
			for z in get_tree().get_nodes_in_group("zombis"):
				var d: float = johnny.global_position.distance_to(z.global_position)
				if bot.vale(z) and d < cerca and not olvidada(z.global_position):
					var camino := NavigationServer2D.map_get_path(mapa_nav, johnny.global_position, z.global_position, true)
					if not camino.is_empty() and camino[-1].distance_to(z.global_position) < 48.0:
						cerca = d
						bot.meta = z.global_position
						meta_cosa = true
			if bot.meta == Vector2.INF and sitio.tipo == "jefe" and not jefa_salio:
				bot.meta = mapa.to_global(Vector2(sitio.get("ancho", 600), sitio.get("alto", 400)) / 2.0)   # (que salga el jefe)
			if bot.meta != Vector2.INF:
				return
		if bot_recoger():
			return
		for p in mapa.puertas:
			var a: int = p.salida.get("a", -1)
			if p.salida.tipo == "puerta" and a >= 0 and planta.sitios[a].tipo == "pasillo":
				puerta = p
	else:
		if bot_recoger():
			return
		puerta = puerta_del_pasillo()
	bot_a_la_puerta(puerta)


# Va a esa puerta y, al llegar, la cruza
func bot_a_la_puerta(puerta: Node2D) -> void:
	if puerta == null:
		return
	bot.meta = puerta.global_position
	if johnny.global_position.distance_to(puerta.global_position) < 56.0 and cruzar_t <= 0.0:
		cruzar_t = 1.5
		recoger_t = 0.0
		cruzar(puerta.indice)


func olvidada(p: Vector2) -> bool:
	return olvidadas.any(func(o): return o.distance_to(p) < 60.0)


# Lo que han soltado los zombis (billetes, mutágeno, munición, objetos): sin nadie con quien pelear, va a por lo más
# cercano que le quepa, como haría una persona. Lo que no puede alcanzar o tras 15 s en el mismo sitio, lo deja
func bot_recoger() -> bool:
	if bot.en_pelea() or recoger_t > 15.0 or mapa.get("cosas") == null:
		return false
	var cerca := INF
	var mapa_nav: RID = johnny.get_world_2d().navigation_map
	for c in mapa.cosas.get_children():
		if c.get_script() != BILLETE or c.tirado or not c.puede.call():
			continue
		var d: float = johnny.global_position.distance_to(c.global_position)
		if d < cerca and d > 8.0 and not olvidada(c.global_position):
			var camino := NavigationServer2D.map_get_path(mapa_nav, johnny.global_position, c.global_position, true)
			if not camino.is_empty() and camino[-1].distance_to(c.global_position) < johnny.stats.iman * 0.8:
				cerca = d
				bot.meta = c.global_position
				meta_cosa = true
	if bot.meta == Vector2.INF:
		return false
	recoger_t += 0.25
	return true


# La carrera: en la sala de mantenimiento, al ordenador y al baúl; y el listo, de vuelta a la sala a gastar el mutágeno
# (en la planta 1, con la llave y antes del jefe; en las demás, con el jefe muerto y el ascensor arreglado)
func decidir_carrera(sitio: Dictionary) -> bool:
	var sala: int = planta.get("mantenimiento", -1)
	if aqui == sala and sala >= 0:
		if visita != bot_momento():
			visita = bot_momento()
			en_sala = "ordenador"
		if en_sala != "":
			var mueble: Node2D = mapa.ordenador if en_sala == "ordenador" else mapa.baul
			if mueble == null:
				en_sala = ""
				return false
			var mapa_nav: RID = johnny.get_world_2d().navigation_map
			var junto := NavigationServer2D.map_get_closest_point(mapa_nav, mueble.global_position)
			bot.meta = junto
			if johnny.global_position.distance_to(junto) < 56.0:
				if en_sala == "ordenador":
					compras.append_array(bot_mutaciones())
					compras.append_array(bot_tienda())
					en_sala = "baul"
				else:
					compras.append_array(bot_baul())
					en_sala = ""
			return true
		# hecho: sale por su puerta de siempre (al pasillo o, en las plantas de arriba, al ascensor)
		for p in mapa.puertas:
			if p.indice == 0:
				bot_a_la_puerta(p)
				return true
		return false
	if not listo or visita == bot_momento() or sala < 0 or mutageno <= 0 or sitio.tipo != "pasillo":
		return false
	if not bot_momento().ends_with("jefe"):
		return false
	for p in mapa.puertas:
		if p.salida.get("a", -1) == sala and p.salida.get("cerrojo", "") == "":
			bot_a_la_puerta(p)
			return true
	return false


# En qué momento de la partida está, para ir a la sala una sola vez en cada uno: "1" al empezar; "1-jefe" en la
# planta 1 con la llave y el jefe vivo (antes de entrar a por él); "N-jefe" en las demás, con el jefe muerto
func bot_momento() -> String:
	if planta.num == 1:
		return "1-jefe" if planta.tiene_llave and not planta.jefa_muerta else "1"
	return "%d-jefe" % planta.num if planta.jefa_muerta else str(planta.num)


# Gasta todo el mutágeno que puede en las mutaciones del árbol (PRIORIDAD): primero el 1.er punto de las que pueda,
# luego el 2.º... Devuelve las compradas
func bot_mutaciones() -> Array:
	var compradas := []
	for nivel in range(1, 6):
		var otra := true
		while otra:
			otra = false
			for id in PRIORIDAD:
				var s := Guardado.cargar()
				if Talentos.nivel_de(s, id) < nivel and Talentos.motivo(s, id, mutageno_total()) == "":
					if not Talentos.subir(id, self).is_empty():
						compradas.append(id)
						otra = true
	if not compradas.is_empty():
		aplicar_talentos(Guardado.cargar().talentos)
	return compradas


# En la tienda: hasta LANZABLES_BOT molotovs y granadas, y el mejor arma cuerpo a cuerpo que le llegue si es mejor que
# la que lleva (todo va al baúl, como en el juego). Se paga como en ordenador.pagar: primero lo de esta partida
func bot_tienda() -> Array:
	var compradas := []
	for k in ["molotov", "granada"]:
		var tiene: int = lanzables.cuantas(k)
		for e in Guardado.cargar().baul_equipo:
			if e.id == k:
				tiene += int(e.get("n", 0))
		for i in maxi(LANZABLES_BOT - tiene, 0):
			var s := Guardado.cargar()
			var precio: int = Supervivientes.precio(Lanzables.PRECIOS[k])
			if cartera() < precio or Objetos.caben_arrojables(s, k, 0) <= 0:
				break
			bot_pagar(s, precio)
			Objetos.arrojables_al_baul(s, k, 0, 1)
			Guardado.escribir(s)
			compradas.append(k)
	var lleva: int = CUERPO_MEJORES.find(johnny.huecos.get("cuerpo", "fregona"))
	for i in CUERPO_MEJORES.size():
		var id: String = CUERPO_MEJORES[i]
		if lleva >= 0 and i >= lleva:
			break
		var s := Guardado.cargar()
		var precio: int = Supervivientes.precio(Armas.PRECIOS[id])
		if cartera() >= precio and Objetos.hueco_baul(s):
			bot_pagar(s, precio)
			if not id in s.armas:
				s.armas.append(id)
			s.baul_equipo.append({"id": id, "calidad": 0, "quedan": Armas.nuevas(0) + 1})
			Guardado.escribir(s)
			compradas.append(id)
			break
	return compradas


func bot_pagar(s: Dictionary, precio: int) -> void:
	var de_partida := mini(precio, dolares)
	dolares -= de_partida
	s.dolares = maxi(s.dolares - (precio - de_partida), 0)
	ahorrados = s.dolares


# Del baúl: los lanzables, las curas y el arma cuerpo a cuerpo si es mejor que la que lleva (como con el inventario)
func bot_baul() -> Array:
	var sacadas := []
	inventario.abrir("baul", self)   # (abre el baúl como una persona: así el inventario sabe de qué partida es)
	var cosas: Array = inventario.cosas_baul(Guardado.cargar())
	for i in range(cosas.size() - 1, -1, -1):   # (de atrás adelante: al sacar, una casilla puede desaparecer)
		var o: Dictionary = cosas[i]
		if o.equipo < 0:
			if o.id in ["vendas", "botiquin"] and inventario.se_saca(o):
				inventario.sacar_objeto(o.id)
				sacadas.append("baul:" + o.id)
			continue
		if Armas.DATOS.has(o.id):
			var lleva: int = CUERPO_MEJORES.find(johnny.huecos.get("cuerpo", "fregona"))
			var esta: int = CUERPO_MEJORES.find(o.id)
			if esta < 0 or (lleva >= 0 and esta >= lleva):
				continue
		elif not o.id in ["molotov", "granada"]:
			continue
		if inventario.se_saca(o):
			inventario.sacar_equipo(o)
			sacadas.append("baul:" + o.id)
	inventario.cerrar()
	get_tree().paused = false
	return sacadas


func puerta_del_pasillo() -> Node2D:
	var mejor: Node2D = null
	var cerca := INF
	for p in mapa.puertas:
		var s: Dictionary = p.salida
		var a: int = s.get("a", -1)
		var sirve := false
		if planta.jefa_muerta:
			sirve = s.tipo == "escaleras"
		elif planta.tiene_llave and s.cerrojo == "llave":
			sirve = true
		elif s.tipo == "puerta" and s.cerrojo == "" and a >= 0:
			var destino: Dictionary = planta.sitios[a]
			sirve = not destino.get("limpio", false) and not destino.tipo in ["mantenimiento", "viviendas", "pasillo"]
		if sirve:
			var d: float = johnny.global_position.distance_to(p.global_position)
			if d < cerca:
				cerca = d
				mejor = p
	return mejor
