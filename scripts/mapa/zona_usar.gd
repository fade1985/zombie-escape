# La zona invisible de delante de un mueble de la sala de mantenimiento (la mesa del ordenador, ordenador.gd; el
# baúl, el banco de trabajo y la taquilla, arrimable.gd). Antes el mueble se abría solo al arrimarse; ahora, mientras
# Johnny está en la zona, se abre al pulsar la acción de atacar: el clic izquierdo o J (las que tenga puestas en
# Opciones), RT en el mando y, en el móvil, el botón «Abrir» que sale entonces (tactil.gd). Con el ratón, el clic tiene
# que caer encima del mueble: si cae en otra parte, no se abre y Johnny ataca como siempre (clic_fuera). Con J o RT no hay
# puntero, así que lo abren estén donde estén y no disparan (johnny.gd, "ante_mueble"). Sin letrero encima (lo pidió el dueño).
extends Area2D

signal usar

var johnny: Node2D = null   # Johnny, mientras está en la zona
var clic_fuera := false     # si lo último con lo que se ha atacado es un clic lejos del mueble: ni se abre ni para el ataque


# "ancho": lo que ocupa el mueble en el suelo
func montar(ancho: float) -> void:
	name = "Zona"   # no-tr
	collision_layer = 0
	collision_mask = 2   # solo Johnny
	var hueco := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(ancho + 20, 40)
	hueco.shape = r
	hueco.position = Vector2(0, 18)
	add_child(hueco)
	body_entered.connect(func(cuerpo):
		johnny = cuerpo
		clic_fuera = false
		cuerpo.set("ante_mueble", self))
	body_exited.connect(func(cuerpo):
		if cuerpo.get("ante_mueble") == self:
			cuerpo.set("ante_mueble", null)
		johnny = null)


# Cada vez que se pulsa "atacar", apunta si ha sido un clic fuera del mueble (llega antes que _physics_process)
func _input(evento: InputEvent) -> void:
	if johnny == null or not evento.is_action_pressed("atacar"):
		return
	clic_fuera = evento is InputEventMouseButton and not encima(evento)


func _physics_process(_delta: float) -> void:
	if johnny and Input.is_action_just_pressed("atacar") and not clic_fuera:
		abrir()


# Si un clic cae sobre el dibujo del mueble (con un poco de margen, para no tener que afinar)
func encima(evento: InputEventMouseButton) -> bool:
	for hijo in get_parent().get_children():
		if hijo is Sprite2D:
			return hijo.get_rect().grow(4).has_point(hijo.make_input_local(evento).position)
	return false


# Al irse la sala (otra planta, F9, el ascensor) con Johnny dentro: que no se quede creyendo que sigue delante
func _exit_tree() -> void:
	if is_instance_valid(johnny) and johnny.get("ante_mueble") == self:
		johnny.set("ante_mueble", null)
	johnny = null


func abrir() -> void:
	usar.emit()
