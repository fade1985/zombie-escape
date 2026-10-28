# Una bala (o un perdigón de la escopeta): vuela en línea recta y se acaba al chocar con una pared o un
# mueble, al dar a un zombi o al llegar a su alcance. La de un arma Épica a distancia atraviesa zombis ("atraviesa",
# Armas.TRUCO) y deja la estela morada. Como en el juego (src/game-combate.js), la bala "de
# verdad" va a la altura de los pies, y el dibujo sale a la altura del cañón y baja enseguida a la del cuerpo.
extends Node2D

const ALTURA_CUERPO := 22.0   # a qué altura sobre los pies se dibuja la bala cuando ya va lanzada
const BAJADA := 14.0          # lo rápido que baja el dibujo desde el cañón
const EMPUJE := 170.0         # empuje base de un zombi normal (el del arma lo multiplica)
# Los colores de la trazadora (TRACER del JS), de la punta a la cola; las críticas, más rojizas
const TRAZA := [Color("#fffbe0"), Color("#ffe066"), Color("#ffb020"), Color("#f0701a"), Color("#b8400e")]
const TRAZA_CRITICA := [Color("#ffffff"), Color("#ffe9a8"), Color("#ff9a3c"), Color("#ff4d2e"), Color("#b3122a")]
const LINEA := Color("#1d1b2c")

var velocidad := Vector2.ZERO
var dano := 0
var empuje := 1.0
var radio := 4.0
var critico := false        # las críticas se ven más rojizas (y saltan más chispas)
var calidad := 0            # la calidad del arma de Johnny que la dispara (Armas.CALIDADES): su trazadora, del color de la calidad
var atraviesa := 0          # a cuántos zombis más puede dar (la Épica a distancia): al darle a uno, sigue
var tocados: Array = []     # los que ya ha atravesado (no les vuelve a dar)
var vida := 1.0             # segundos que le quedan (alcance ÷ velocidad)
var altura := 50.0          # a qué altura sobre la bala de verdad se dibuja
var de_aliado := false      # la ha disparado un superviviente, no Johnny (se lo dice a los jefes: el Glotón no salpica)


func _physics_process(delta: float) -> void:
	vida -= delta
	if vida <= 0.0:
		queue_free()
		return
	altura += (ALTURA_CUERPO - altura) * (1.0 - exp(-delta * BAJADA))

	var antes := global_position
	var despues := antes + velocidad * delta
	# ¿Hay una pared o un mueble entre donde estaba y donde va a estar? (capa de choque 1)
	var rayo := PhysicsRayQueryParameters2D.create(antes, despues, 1)
	var pared := get_world_2d().direct_space_state.intersect_ray(rayo)
	if pared:
		global_position = pared.position
		chocar(true)
		return
	global_position = despues

	# ¿Ha dado a algún zombi?
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if zombi in tocados:
			continue
		if global_position.distance_to(zombi.global_position) < zombi.radio + radio + 3.0:
			var fuerza := velocidad.normalized() * EMPUJE * empuje
			Zombi.critico = critico   # (su número sale en amarillo)
			if de_aliado and zombi is Minijefe:
				zombi.recibir_golpe(dano, fuerza, false, true)
			else:
				zombi.recibir_golpe(dano, fuerza)
			Zombi.critico = false
			if atraviesa > 0:   # (la Épica: lo atraviesa y sigue)
				atraviesa -= 1
				tocados.append(zombi)
				chocar(false, true)
				continue
			chocar()
			return
	queue_redraw()


# Al chocar (bulletImpact del JS): un destello cuadrado y unas chispas del color de la bala que rebotan hacia
# atrás; contra un muro salta además algo de polvo. Salen a la altura a la que se ve la bala. Si lo atraviesa
# ("sigue"), las chispas salen pero la bala no se acaba
func chocar(pared := false, sigue := false) -> void:
	var donde := global_position + Vector2(0, -altura)
	var atras := (-velocidad).angle()
	var colores := estela()
	Particulas.soltar(self, donde, Vector2.ZERO, colores[0], 10.0 if critico else 8.0, 0.07)
	var n := (7 if critico else 5) - (2 if radio < 4.0 else 0)   # los perdigones sueltan menos chispas
	for i in n:
		var v := Vector2.from_angle(atras + randf_range(-1.1, 1.1)) * randf_range(110.0, 300.0)
		Particulas.soltar(self, donde, v, colores[1 + i % 3], 4.0 if i < 2 else 2.0, randf_range(0.14, 0.28))
	if pared:
		for i in 3:
			var v := Vector2.from_angle(atras + randf_range(-0.8, 0.8)) * randf_range(30.0, 90.0) + Vector2(0, -20)
			Particulas.soltar(self, donde, v, Color("#b9bec9") if i else Color("#e3e6ec"), 4.0, randf_range(0.25, 0.4))
	if not sigue:
		queue_free()


# Los colores de la trazadora y de sus chispas: la de la Épica, morada; la crítica, rojiza; las de un arma mejorada,
# del color de su calidad (Armas.traza)
func estela() -> Array:
	if atraviesa > 0 or not tocados.is_empty():
		return Armas.traza(Armas.EPICA)
	if critico:
		return TRAZA_CRITICA
	return Armas.traza(calidad) if calidad > 0 else TRAZA


# La trazadora (drawTracer del JS): cuadraditos de pixel art en fila hacia atrás, encajados en la cuadrícula
# del dibujo: la punta casi blanca y una estela corta que pasa de amarillo a naranja, con borde oscuro en la
# parte gorda. Así vale para cualquier ángulo sin verse borrosa. Los perdigones, más finos
func _draw() -> void:
	var u := velocidad.normalized()
	var gordo := 2 if radio >= 4.0 else 1          # lado de la punta, en píxeles del dibujo
	var colores := estela()
	var paso := gordo * 2.0                         # los trozos van pegados uno detrás de otro
	var punta := Vector2(0, -altura)
	for k in range(2, -1, -1):
		cuadradito(punta - u * k * paso, gordo + 2, LINEA)
	for k in range(colores.size() - 1, -1, -1):
		var c: Color = colores[k]
		c.a = 0.5 if k == 4 else (0.8 if k == 3 else 1.0)
		cuadradito(punta - u * k * paso, gordo if k < 3 else maxi(1, gordo - 1), c)


# Un cuadradito de "lado" píxeles del dibujo, con el centro en "centro", encajado en la cuadrícula del mundo
func cuadradito(centro: Vector2, lado: int, color: Color) -> void:
	var s := lado * 2.0
	var esquina := ((global_position + centro - Vector2(s, s) / 2.0) / 2.0).round() * 2.0 - global_position
	draw_rect(Rect2(esquina, Vector2(s, s)), color)
