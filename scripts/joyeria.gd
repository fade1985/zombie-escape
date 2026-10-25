# La cámara acorazada de la joyería (parte 10 del centro comercial, trozo 2; docs/CENTRO_COMERCIAL.md, «Decidido
# con el dueño (22 oct 2026, para la parte 10)»). La joyería sale una vez por partida (planta.gd, joyeria_planta) y
# su cámara, al fondo, tiene la puerta blindada cerrada (mapa/puerta_bano.gd con "acero") y un lector de tarjetas:
# arrimarse a la puerta por el lado de la tienda. Se abre de dos maneras:
#   - con la tarjeta dorada: la lleva el guardia de la planta junto a la suya y la suelta al caer (partida.gd,
#     _al_caer_guardia → soltar_dorada); con ella, al arrimarse la puerta se abre sin ruido;
#   - sin ella, la apertura de emergencia: al arrimarse dos veces (la primera solo avisa), salta la alarma: sirena,
#     una cuenta atrás de CUENTA segundos y zombis entrando por la entrada de la tienda y por las habitaciones, en
#     grupos cada vez mayores. Hay que aguantar dentro de la joyería: si Johnny sale, la cuenta se para hasta que
#     vuelve. Al acabar, la puerta se abre con un clac.
# Dentro, el premio (trozo 3): una vitrina con un arma creada de rareza morada (la mejor) de una receta que ya se
# sepa (si solo se sabe el molotov, un cóctel morado con todas sus botellas), que al pisarla va a la mano como al
# sacarla del baúl, y un fajo de billetes (FAJO, más FAJO_POR_PLANTA por planta). Y el logro «Caja fuerte» al abrir
# la cámara la primera vez (logros.gd). El estado va en planta.joyeria (lo crea planta.gd):
#   sitio, sala (la de la cámara), puerta (su hueco, de apt.puertas), abierta, dorada ("guardia", "suelo", "tengo" o
#   "usada"), suelo ({sitio, pos} mientras está en el suelo), alarma (-1 sin empezar; si no, los segundos que
#   quedan) y, con la cámara abierta, premio ({arma, fajo, pos, cogido}).
# Lo engancha partida.gd: preparar(), al_montar(), recoger(), soltar_dorada() y coger_dorada(). Los números son
# provisionales.
class_name Joyeria
extends Node

const PUERTA := preload("res://scripts/mapa/puerta_bano.gd")
const BILLETE := preload("res://scripts/billete.gd")
const FAJO := 15              # el fajo de billetes de la cámara...
const FAJO_POR_PLANTA := 5    # ...y lo que suma por planta
const RAREZA := "morada"      # la rareza del arma de la vitrina (recetas.gd, RAREZAS)
const CUENTA := 40.0          # segundos de la apertura de emergencia
const CADA := [5.0, 3.0]      # segundos entre grupo y grupo, al principio y al final
const GRUPO := [2, 4]         # zombis por grupo, al principio y al final (y uno más por cada dos plantas)
const TOPE := 24              # zombis a la vez, como mucho
const TIPOS := [["normal", "normal", "lento", "dependienta", "rapido"],
	["normal", "rapido", "rapido", "vigilante", "explosivo"]]
const SIRENA := 6.0           # cada cuánto suena la sirena
const DELANTE := 64.0         # a qué distancia de la puerta se usa el lector
const ROJO := Color("#ff4f5e")

var partida: Node
var puerta: Node2D = null     # la puerta blindada montada (null si no estamos en la joyería o ya está abierta)
var capa: Control             # la cuenta atrás, en la pantalla
var listo := true             # hay que apartarse de la puerta antes de volver a usar el lector
var avisado := false          # ya ha avisado de que sin tarjeta solo queda la apertura de emergencia
var grupo_t := 0.0
var sirena_t := 0.0
var tiempo := 0.0
var cuenta := false           # ya ha sonado el aviso de los últimos 10 segundos


func preparar(p: Node) -> void:
	partida = p
	capa = Control.new()
	capa.name = "Joyeria"
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.draw.connect(dibujar)
	var pantalla: Node = p.get_node("Pantalla")
	pantalla.add_child(capa)
	pantalla.move_child(capa, p.negro.get_index())   # por debajo del fundido a negro


# Los datos de la joyería de esta planta ({} si no la tiene)
func datos() -> Dictionary:
	return partida.planta.get("joyeria", {})


func en_joyeria() -> bool:
	var d := datos()
	return not d.is_empty() and partida.aqui == d.sitio


# La alarma está sonando: la cuenta atrás, empezada y sin acabar
func alarma() -> bool:
	var d := datos()
	return not d.is_empty() and d.alarma >= 0.0 and not d.abierta


# Al montar un sitio: en la joyería, la puerta blindada (si sigue cerrada) y, si la tarjeta dorada se quedó en el
# suelo de este sitio, la tarjeta
func al_montar(idx: int, _sitio: Dictionary) -> void:
	var d := datos()
	if d.is_empty():
		return
	listo = false   # (por si se monta con Johnny ya delante de la puerta)
	if idx == d.sitio and not d.abierta:
		puerta = PUERTA.new()
		puerta.acero = true
		puerta.montar(d.puerta)
		partida.mapa.cosas.add_child(puerta)
		partida.mapa.rehornear()   # que los zombis no cuenten con pasar por ahí
	if idx == d.sitio and d.abierta and d.has("premio") and not d.premio.cogido:
		poner_premio()   # la vitrina sigue dentro hasta que se coja
	if d.dorada == "suelo" and d.suelo.sitio == idx:
		partida.mapa.poner_llave(d.suelo.pos, true, true)


# Antes de cambiar de sitio: la puerta se va con el mapa (la cuenta atrás, si sigue, espera a que Johnny vuelva)
func recoger() -> void:
	puerta = null


# El guardia ha caído en este sitio: suelta la tarjeta dorada al lado de la suya. Devuelve si la ha soltado
func soltar_dorada(pos: Vector2) -> bool:
	var d := datos()
	if d.is_empty() or d.dorada != "guardia":
		return false
	d.dorada = "suelo"
	d.suelo = {"sitio": partida.aqui, "pos": pos}
	partida.mapa.call_deferred("poner_llave", pos, true, true)
	return true


func coger_dorada() -> void:
	var d := datos()
	d.dorada = "tengo"
	d.suelo = {}
	Sonido.tocar("compra")
	partida.decir("Has cogido la tarjeta dorada: abre la cámara acorazada de la Joyería", 3.0)


func _physics_process(delta: float) -> void:
	if partida == null or partida.mapa == null or partida.cambiando or partida.terminada or not partida.johnny.vivo:
		return
	if not en_joyeria():
		return
	var d := datos()
	tiempo += delta
	if not d.abierta and puerta:
		mirar_lector()
	if not alarma():
		return
	capa.queue_redraw()
	d.alarma -= delta
	sirena_t -= delta
	if sirena_t <= 0.0:
		sirena_t = SIRENA
		Sonido.tocar("alarma")
	if d.alarma <= 10.0 and not cuenta:   # los últimos 10 segundos: aviso
		cuenta = true
		Sonido.tocar("jefe")
	grupo_t -= delta
	if grupo_t <= 0.0 and d.alarma > 3.0:
		var k: float = 1.0 - d.alarma / CUENTA
		grupo_t = lerpf(CADA[0], CADA[1], k)
		var extra: int = (partida.planta.num - 1) / 2
		grupo(roundi(lerpf(GRUPO[0], GRUPO[1], k)) + extra, TIPOS[0] if k < 0.5 else TIPOS[1])
	if d.alarma <= 0.0:
		abrir("¡Clac! Se acabó la cuenta: la cámara acorazada se ha abierto")


# El lector de tarjetas: arrimarse a la puerta blindada por el lado de la tienda. Con la tarjeta dorada, abre; sin
# ella, la primera vez avisa y la segunda (tras apartarse) dispara la apertura de emergencia
func mirar_lector() -> void:
	var d := datos()
	var p: Vector2 = partida.johnny.global_position
	var delante: bool = p.distance_to(puerta.caja.get_center()) < DELANTE and partida.mapa.zona_en(p) != d.sala
	if not delante:
		listo = true
		return
	if not listo:
		return
	listo = false
	if d.dorada == "tengo":
		d.dorada = "usada"
		Sonido.tocar("compra")
		abrir("Abres la cámara acorazada con la tarjeta dorada")
	elif alarma():
		partida.decir("Aguanta: la cámara se abre en %d segundos" % ceili(d.alarma))
	elif not avisado:
		avisado = true
		Sonido.tocar("no")
		partida.decir("Lector de tarjetas. Sin la tarjeta dorada del guardia solo queda la apertura de emergencia: vuelve a arrimarte para disparar la alarma", 4.5)
	else:
		empezar_alarma()


func empezar_alarma() -> void:
	var d := datos()
	d.alarma = CUENTA
	grupo_t = 3.0
	sirena_t = 0.0
	cuenta = false
	Sonido.musica("jefe")
	partida.eventos.mostrar_cartel("¡ALARMA!", "Apertura de emergencia: la cámara se abre en %d segundos. ¡Aguanta!" % roundi(CUENTA), ROJO)
	partida.decir("¡Has disparado la alarma! Vienen a por ti: aguanta %d segundos sin salir de la joyería" % roundi(CUENTA), 4.0)


# La puerta blindada se abre (con la tarjeta o al acabar la cuenta): deja de chocar, los zombis ya pueden pasar,
# dentro aparece el premio y cae el logro «Caja fuerte»
func abrir(texto: String) -> void:
	var d := datos()
	d.abierta = true
	d.alarma = -1.0
	if is_instance_valid(puerta):
		puerta.abrir()
		partida.mapa.rehornear()
	Sonido.tocar("limpio")
	Sonido.musica("menu")
	partida.decir(texto, 3.5)
	capa.queue_redraw()
	if not d.has("premio"):
		preparar_premio()
	poner_premio()
	partida.logros.cumplir("caja_fuerte")


# ── El premio ──

# Qué hay en la vitrina: un arma creada morada de una receta que ya se sepa (sin contar el molotov; si no se sabe
# otra, el cóctel molotov morado) y el fajo de billetes de esta planta
func preparar_premio() -> void:
	var d := datos()
	var sabidas: Array = Recetas.sabidas(Guardado.cargar()).filter(func(r): return r != "molotov")
	var receta: String = sabidas.pick_random() if not sabidas.is_empty() else "molotov"
	d.premio = {"arma": Recetas.crear(receta, RAREZA), "fajo": FAJO + FAJO_POR_PLANTA * (partida.planta.num - 1),
		"pos": Vector2.INF, "cogido": false}


# La vitrina, en un sitio libre de la cámara (siempre el mismo): el icono del arma en grande, con un brillo
# morado, y se coge pisándola como las demás cosas del suelo
func poner_premio() -> void:
	var d := datos()
	var sitio: Dictionary = partida.planta.sitios[d.sitio]
	var sala: Dictionary = sitio.apt.salas[d.sala]
	if d.premio.pos == Vector2.INF:
		var pos: Vector2 = Planta.sitio_libre(sitio, sala, Vector2.INF, [], 40.0)
		d.premio.pos = sala.centro if pos == Vector2.INF else pos
	var a: Dictionary = d.premio.arma
	var cosa := BILLETE.new()
	cosa.name = "Vitrina"
	cosa.johnny = partida.johnny
	cosa.icono = load("res://assets/ui/iconos/%s.png" % Recetas.icono_de(a.receta))
	cosa.tamano = 2.0
	cosa.tirado = true   # (quieta: no sale despedida)
	cosa.position = d.premio.pos
	var brillo := PointLight2D.new()
	brillo.texture = load("res://escenas/luces/luz_suave.tres")
	brillo.texture_scale = 0.35
	brillo.color = Recetas.RAREZAS[RAREZA].color
	brillo.position = Vector2(0, -10)
	cosa.add_child(brillo)
	cosa.cogido.connect(coger_premio)
	partida.mapa.cosas.add_child.call_deferred(cosa)


# Al pisar la vitrina: el arma, como al sacarla del baúl (la de cuerpo a cuerpo o de fuego, a la mano; el cóctel
# suma sus botellas a los molotovs; las demás arrojadizas, al botón de lanzar), cuenta en Colecciones como creada, y
# el fajo a los dólares de la partida
func coger_premio() -> void:
	var d := datos()
	d.premio.cogido = true
	var a: Dictionary = d.premio.arma
	var johnny: Node2D = partida.johnny
	var como := ""
	if a.hueco == "arrojadiza":
		partida.lanzables.sacar(a)
		como = "Sus botellas se suman a tus molotovs" if a.receta == "molotov" else "Lista para lanzar (F para elegirla)"
	else:
		partida.armas_guardadas.append(johnny.huecos[a.hueco])
		johnny.coger(Armas.apuntar(a))
		como = "Ya la llevas en la mano"
	Guardado.cambiar(func(g):
		if not a.receta in g.creadas:   # (Colecciones: cuenta como creada alguna vez)
			g.creadas.append(a.receta)
			g.colecciones_nuevo = true)
	partida.dolares += d.premio.fajo
	Sonido.tocar("compra")
	partida.numero(johnny.position + Vector2(0, -60), "+$%d" % d.premio.fajo, Tema.VERDE)
	partida.decir("¡%s %s! %s. Y un fajo de billetes: +$%d" % [a.nombre, Recetas.RAREZAS[RAREZA].nombre.to_lower(), como, d.premio.fajo], 4.5)


# Un grupo de zombis entra por la entrada de la tienda o por una habitación donde no esté Johnny (nunca la cámara)
func grupo(n: int, tipos: Array) -> void:
	n = mini(n, TOPE - get_tree().get_nodes_in_group("zombis").size())
	if n <= 0:
		return
	var d := datos()
	var johnny: Node2D = partida.johnny
	var sitio: Dictionary = partida.planta.sitios[partida.aqui]
	var apt: Dictionary = sitio.apt
	var aqui: int = partida.mapa.zona_en(johnny.position)
	var salas: Array = apt.salas.filter(func(s): return s.id != d.sala and s.id != aqui)
	var entrada: Node2D = partida.mapa.puertas[0]
	var por_la_entrada: bool = johnny.position.distance_to(entrada.llegada()) > 220.0 and (salas.is_empty() or randf() < 0.5)
	if por_la_entrada:
		for i in n:
			partida.meter_zombi(tipos.pick_random(), entrada.llegada() + Vector2(randf_range(-24, 24), randf_range(-24, 24)))
	elif not salas.is_empty():
		var sala: Dictionary = salas.pick_random()
		var puestos := 0
		for i in 120:
			if puestos >= n:
				break
			var pos := Vector2((sala.c0 + randf() * sala.ancho) * Planta.CASILLA, (sala.f0 + randf() * sala.fondo) * Planta.CASILLA)
			if not Planta.despejado(apt, pos, 24.0, sala.id) or pos.distance_to(johnny.position) < 180.0:
				continue
			if not Planta.lejos_de_muebles(sitio, pos, 30.0):
				continue
			partida.meter_zombi(tipos.pick_random(), pos)
			puestos += 1


# En la pantalla, arriba: la barra de la cuenta atrás (como la de la barricada del ferretero) y, los últimos diez
# segundos, el número en grande
func dibujar() -> void:
	if not alarma() or not en_joyeria():
		return
	var d := datos()
	var letra := Tema.FUENTE
	var tam := capa.size
	var ancho := minf(360.0, tam.x - 260.0)
	var x := (tam.x - ancho) / 2.0
	var y := 18.0
	var falta := ceili(d.alarma)
	capa.draw_rect(Rect2(x - 8, y - 8, ancho + 16, 44), Tema.LINEA)
	capa.draw_rect(Rect2(x - 6, y - 6, ancho + 12, 40), Color(0.11, 0.1, 0.17, 0.9))
	capa.draw_rect(Rect2(x, y + 16, ancho, 10), Color("#3a2f22"))
	var relleno := Color("#ff2d4b") if int(tiempo * 4.0) % 2 else Color("#c0203a")
	capa.draw_rect(Rect2(x, y + 16, ancho * (1.0 - d.alarma / CUENTA), 10), relleno)
	capa.draw_rect(Rect2(x, y + 16, ancho, 10), Tema.LINEA, false, 2.0)
	var texto := "Apertura de emergencia · %d:%02d" % [falta / 60, falta % 60]
	capa.draw_string_outline(letra, Vector2(0, y + 9), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, 4, Tema.LINEA)
	capa.draw_string(letra, Vector2(0, y + 9), texto, HORIZONTAL_ALIGNMENT_CENTER, tam.x, 16, Color("#ffb3b3"))
	if falta <= 10:
		var grande := 64 if fmod(d.alarma, 1.0) < 0.5 else 72
		capa.draw_string_outline(letra, Vector2(0, 150), str(falta), HORIZONTAL_ALIGNMENT_CENTER, tam.x, grande, 10, Tema.LINEA)
		capa.draw_string(letra, Vector2(0, 150), str(falta), HORIZONTAL_ALIGNMENT_CENTER, tam.x, grande, Tema.AMARILLO)
