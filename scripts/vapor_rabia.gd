# El vapor de la rabia: lo que les sale de la cabeza a la portera y a los minijefes cuando se enfadan. Nubecitas de
# pixel art (los dibujos, de BalaZombi.dibujar_polvo) que salen a bocanadas de las orejas y de la coronilla: más
# seguidas mientras atacan, alguna más gorda de vez en cuando, rosadas al salir y blancas al subir; se balancean, se
# hinchan y al final se deshacen a trozos. Al enfadarse, un chorro de golpe (chorro()).
# Cada jefe tiene uno: lo mueve con actualizar() en cada paso y lo pinta con pintar() en su nodo "Vapor".
class_name VaporRabia
extends RefCounted

const ROSA := {"borde": Color("#8a5a62", 0.55), "oscuro": Color("#d89aa0", 0.7), "medio": Color("#f0c0c0", 0.75),
	"claro": Color("#fff0ee", 0.85), "brillo": Color("#fff0ee", 0.85)}
const BLANCO := {"borde": Color("#8c8a90", 0.45), "oscuro": Color("#c8c6cc", 0.6), "medio": Color("#e6e4e8", 0.65),
	"claro": Color("#ffffff", 0.75), "brillo": Color("#ffffff", 0.75)}

var salidas: Array            # las orejas y la coronilla, respecto al centro del jefe
var bocanadas := []           # [sitio, velocidad, edad, lo que dura, tamaño, balanceo, vuelta]
var siguiente := 0.0


# "cabeza": a qué altura tiene la coronilla; "orejas": lo separadas que están del medio y cuánto más abajo
func _init(cabeza: float, orejas := 18.0, bajan := 16.0) -> void:
	salidas = [Vector2(-orejas, -cabeza + bajan), Vector2(orejas, -cabeza + bajan), Vector2(0, -cabeza)]


# "echa": si está enfadado (si no, solo terminan de subir las que ya había); "ataca": echa más seguidas
func actualizar(delta: float, echa: bool, ataca: bool) -> void:
	for b in bocanadas:
		b[2] += delta
		b[0] += b[1] * delta
		b[1] *= 1.0 - delta * 1.5   # se frena al subir
	bocanadas = bocanadas.filter(func(b): return b[2] < b[3])
	if not echa:
		return
	siguiente -= delta
	if siguiente <= 0.0:
		siguiente = randf_range(0.2, 0.3) if ataca else randf_range(0.35, 0.55)
		var grande := randf() < 0.2   # de vez en cuando, una más gorda
		bocanada(salidas.pick_random(), 1.4 if grande else 1.0)
		if grande or ataca:
			bocanada(salidas.pick_random(), 0.8)


# Al enfadarse: un chorro de vapor de golpe
func chorro() -> void:
	for i in 8:
		bocanada(salidas[i % 3], randf_range(1.3, 1.6), 1.5)


# Una nubecita en "donde": sube (y, si sale de una oreja, se abre hacia ese lado)
func bocanada(donde: Vector2, tamano: float, fuerza := 1.0) -> void:
	var hacia := Vector2(signf(donde.x) * randf_range(20.0, 40.0) + randf_range(-10.0, 10.0), -randf_range(60.0, 90.0))
	bocanadas.append([donde + Vector2(randf_range(-3, 3), 0), hacia * fuerza, 0.0, randf_range(1.1, 1.4), 9.0 * tamano,
		randf() * TAU, randi() % 4])


func pintar(lienzo: CanvasItem) -> void:
	for b in bocanadas:
		var k: float = b[2] / b[3]
		var tam := roundi(b[4] * (0.7 + 0.7 * k))
		var rosa := k < 0.35
		var clave := "vapor_%d_%d_%d" % [int(rosa), tam, b[6]]
		if not BalaZombi.dibujos.has(clave):
			BalaZombi.dibujos[clave] = BalaZombi.dibujar_polvo(tam, b[6] * TAU / 12.0, ROSA if rosa else BLANCO)
		var centro: Vector2 = b[0] + Vector2(sin(b[2] * 6.0 + b[5]) * 4.0, 0.0)
		centro = (centro / 2.0).round() * 2.0   # en la cuadrícula de los píxeles del dibujo
		var deshace := (k - 0.65) / 0.35   # pasados dos tercios, cada vez le faltan más trozos
		var pixeles: Array = BalaZombi.dibujos[clave]
		for i in pixeles.size():
			if deshace > 0.0 and fmod(i * 0.618 + b[5], 1.0) < deshace:
				continue
			lienzo.draw_rect(Rect2(centro + pixeles[i][0], Vector2(2, 2)), pixeles[i][1])
