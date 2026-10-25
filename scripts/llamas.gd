# Llamas de pixel art (drawFlame de src/molotov.js). Dos usos:
#   - Llamas.llama(...): pinta una llama en cualquier dibujo (el charco de fuego del molotov la usa).
#   - Como nodo: las llamas de alguien que arde (Johnny con el estado "fuego"). Se pone de hijo, encima del
#     cuerpo, con su lucecita naranja (escenas/luces/fuego.tscn), y se apaga con "fuerza". A un zombi prendido
#     solo le pone la luz ("cuerpo" a false): a él arder lo tiñe (zombi.gd, tinte_fuerte).
class_name Llamas
extends Node2D

# Colores del fuego: del centro (blanco amarillento) al borde (rojo)
const FUEGO := [Color("#fff3b0"), Color("#ffd23f"), Color("#ff9f1c"), Color("#f0541e"), Color("#b8261c")]
const LUZ := preload("res://escenas/luces/fuego.tscn")
const U := 2.0   # un píxel del dibujo, en unidades

var alto := 60.0     # lo que mide el cuerpo que arde (las llamas suben hasta ahí)
var ancho := 16.0    # medio ancho del cuerpo
var fuerza := 1.0    # 0 = apagadas; entre medias, más pequeñas
var cuerpo := true   # si se dibujan las llamas por el cuerpo (si no, solo la luz)
var t := 0.0
var luz: PointLight2D


func _ready() -> void:
	z_index = 1
	luz = LUZ.instantiate()
	luz.radio = 90.0
	luz.fuerza = 0.75
	luz.position = Vector2(0, -alto * 0.4)
	add_child(luz)


func _process(delta: float) -> void:
	t += delta
	luz.visible = fuerza > 0.0
	luz.fuerza = 0.75 * fuerza
	if cuerpo:
		queue_redraw()


func _draw() -> void:
	if fuerza <= 0.0 or not cuerpo:
		return
	# tres llamas por el cuerpo: una alta en medio y dos más bajas a los lados
	llama(self, -ancho * 0.55, -alto * 0.15, 5, 11, t, 1.3, fuerza)
	llama(self, ancho * 0.5, -alto * 0.25, 5, 10, t, 4.1, fuerza)
	llama(self, 0.0, -alto * 0.35, 6, 15, t, 2.7, fuerza)


# Una llama. (x, y) es la base; "w" y "h", el ancho y el alto en píxeles del dibujo. Por fuera es roja, por
# dentro naranja y en el corazón amarilla; se estrecha hacia arriba, se mece de lado (más cuanto más arriba)
# y su altura tiembla con dos ondas a distinto ritmo. De vez en cuando la punta suelta una chispa.
# "semilla" cambia el ritmo de cada llama; "k" (0-1) la encoge.
static func llama(item: CanvasItem, x: float, y: float, w: float, h: float, t: float, semilla: float, k := 1.0) -> void:
	var hh := roundi(h * k * (0.72 + 0.18 * sin(t * 11.0 + semilla * 3.1) + 0.1 * sin(t * 17.3 + semilla)))
	if hh < 2:
		return
	var bx := roundi(x / U)
	var by := roundi(y / U)
	var medio := w * maxf(0.5, k) / 2.0
	var vaiven := 0
	for j in hh:
		var f := float(j) / hh   # 0 en la base, 1 en la punta
		vaiven = roundi(sin(t * 7.0 + semilla * 2.0 - j * 0.5) * f * f * 2.5)
		var hw := roundi(medio * pow(1.0 - f, 0.8))
		var fila := (by - j - 1) * U
		var izq := bx + vaiven
		item.draw_rect(Rect2((izq - hw) * U, fila, (2 * hw + 1) * U, U), FUEGO[4] if f > 0.7 else FUEGO[3])
		if hw >= 1 and f < 0.75:
			item.draw_rect(Rect2((izq - hw + 1) * U, fila, (2 * hw - 1) * U, U), FUEGO[2])
		if hw >= 2 and f < 0.5:
			item.draw_rect(Rect2((izq - hw + 2) * U, fila, (2 * hw - 3) * U, U), FUEGO[0] if f < 0.25 else FUEGO[1])
	# chispa que se suelta de la punta y sube
	var chispa := fmod(t * 1.7 + semilla * 0.37, 1.0)
	if chispa < 0.45:
		item.draw_rect(Rect2((bx + vaiven) * U, (by - hh - 2 - floori(chispa * 8.0)) * U, U, U), FUEGO[1] if chispa < 0.2 else FUEGO[3])
