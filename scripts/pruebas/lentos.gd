# El detector de fotogramas lentos (-- --captura <prueba> --lentos): cuenta lo que tarda cada fotograma de verdad (en el
# ordenador y, sobre todo, en la web, donde un efecto con muchos dibujos puede tardar más de un segundo: docs/WEB.md) y
# avisa de cada uno que pasa de AVISA milisegundos, con cuántos dibujos llevaba y qué hacía la partida; al acabar, el
# resumen. Vale con cualquier prueba (también las de los jefes y los efectos); en la web se pone en "args" del index.html.
class_name Lentos
extends Node

const AVISA := 60.0          # milisegundos: a 60 fps, un fotograma dura 16
const CARGA := 4.0           # segundos del principio, que no cuentan (el juego aún está cargando)

var partida: Node
var antes := 0
var empezo := 0
var fotogramas := 0
var lentos := 0
var peor := 0.0
var suma_lentos := 0.0


# En la web, si la página está a la vista ("visible") o escondida ("hidden"): una página escondida va a un fotograma por
# segundo y sus medidas no valen (el panel del navegador de la app de Claude, escondido, daba falsos atascos de 1 s)
static func visibilidad() -> String:
	return str(JavaScriptBridge.eval("document.visibilityState")) if OS.has_feature("web") else "-"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	empezo = Time.get_ticks_msec()
	antes = Time.get_ticks_usec()


func _process(_delta: float) -> void:
	var ahora := Time.get_ticks_usec()
	var ms := (ahora - antes) / 1000.0
	antes = ahora
	if Time.get_ticks_msec() - empezo < CARGA * 1000.0:
		return
	fotogramas += 1
	if fotogramas % 120 == 0:   # (una muestra cada dos segundos más o menos: cuánto dibuja la partida en un fotograma normal)
		print("Lento · muestra · %d llamadas · %d triángulos · %.0f ms · página %s" % [
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), ms, visibilidad()])
	if ms < AVISA:
		return
	lentos += 1
	suma_lentos += ms
	peor = maxf(peor, ms)
	var dibujos := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var triangulos := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var que := ""
	if partida != null and partida.get("mapa") != null:
		var tipos := {}
		for n in get_tree().get_nodes_in_group("zombis"):
			var t: String = n.get_meta("tipo", n.name)
			tipos[t] = tipos.get(t, 0) + 1
		que = " · en «%s» · zombis %s · velocidad %.2f" % [partida.planta.sitios[partida.aqui].tipo, tipos, Engine.time_scale]
	print("Lento · fotograma de %.0f ms · %d llamadas · %d triángulos · a los %.1f s · página %s%s" % [ms, dibujos, triangulos,
		(Time.get_ticks_msec() - empezo) / 1000.0, visibilidad(), que])


func _exit_tree() -> void:
	print("Lento · resumen: %d fotogramas lentos (>%d ms) de %d · el peor %.0f ms · en total %.1f s parados" % [
		lentos, int(AVISA), fotogramas, peor, suma_lentos / 1000.0])
