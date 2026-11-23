# Un saco (o una caja) de ingredientes del cocinero (minijefe del centro comercial; docs/JEFES_CENTRO.md). Cada vez
# que el cocinero va a cocinar, caen tres por su cocina (cocinero.gd, reponer): son lo que echa en la olla. Si Johnny
# los rompe todos antes de que termine de remover, el guiso sale malo y el cocinero se pone enfermo (¡a pegarle!);
# si no, se cura un poco por cada uno que quede. Dibujos de PixelLab (saco de patatas, caja de tomates, saco de harina).
# Está en el grupo "zombis" (con radio, vida y recibir_golpe, como los maniquíes vivos de la modista): las balas, los
# golpes y las explosiones le dan. No se mueve. Al morir el cocinero se rompen todos (que no se quede la puerta cerrada).
# Se crea con SacoIngredientes.new(); se le pone "tipo" (0, 1 o 2) antes de meterlo en la escena.
class_name SacoIngredientes
extends CharacterBody2D

const DIBUJOS := [preload("res://assets/sprites/saco-patatas.png"), preload("res://assets/sprites/caja-tomates.png"),
	preload("res://assets/sprites/saco-harina.png")]
# los trocitos que saltan al darle y al romperse: patatas, tomates, harina
const COLORES := [[Color("#c8a060"), Color("#8a6a3a")], [Color("#d8402a"), Color("#e8c060")], [Color("#f4f0e4"), Color("#d8d0c0")]]
const CAE := 0.45          # lo que tarda en caer desde arriba al aparecer
const VIDA := 40

var tipo := 0
var radio := 20.0
var vida := VIDA
var vida_max := VIDA
var t := 0.0
var sacude := 0.0          # al darle, tiembla un momento
var roto := false
var sprite: Sprite2D


func _ready() -> void:
	add_to_group("zombis")
	add_to_group("sacos_ingredientes")
	collision_layer = 4    # como los zombis: choca con Johnny y no tapa la vista
	collision_mask = 0     # (no se mueve)
	var choque := CollisionShape2D.new()
	choque.name = "Choque"
	var circulo := CircleShape2D.new()
	circulo.radius = radio
	choque.shape = circulo
	add_child(choque)
	sprite = Sprite2D.new()
	sprite.texture = DIBUJOS[tipo]
	sprite.scale = Vector2(2, 2)
	sprite.offset = Vector2(0, -sprite.texture.get_height() / 2.0 + 4.0)   # sus pies, en su sitio
	add_child(sprite)
	sprite.position.y = -500.0


func _physics_process(delta: float) -> void:
	t += delta
	sacude = maxf(0.0, sacude - delta)
	if t < CAE:
		var k := t / CAE
		sprite.position.y = -500.0 * (1.0 - k * k)
		return
	if sprite.position.y != 0.0:
		# acaba de caer: un golpe seco y una nubecita
		sprite.position.y = 0.0
		Sonido.tocar("chof")
		for i in 6:
			Particulas.soltar(get_parent(), global_position + Vector2(randf_range(-16, 16), 4),
				Vector2(randf_range(-80, 80), randf_range(-30, 10)), Color("#d8d0c0", 0.7), randf_range(3, 5), 0.4)
	sprite.position.x = sin(t * 60.0) * 2.0 * sacude / 0.2 if sacude > 0.0 else 0.0


func recibir_golpe(cantidad: int, fuerza: Vector2, _de_lleno := false, _de_aliado := false) -> void:
	if roto or t < CAE:
		return
	vida = maxi(vida - cantidad, 0)
	sacude = 0.2
	Zombi.numero_golpe(get_parent(), global_position + Vector2(randf_range(-16, 0), -60), cantidad)
	Sonido.tocar("golpe")
	for i in 3:
		var v := (fuerza.normalized() if fuerza != Vector2.ZERO else Vector2.UP) * 90.0
		Particulas.soltar(get_parent(), global_position + Vector2(randf_range(-10, 10), -randf_range(10, 40)),
			v.rotated(randf_range(-0.8, 0.8)), COLORES[tipo][i % 2], 3, 0.4)
	if vida <= 0:
		romper()


# Daño sin golpe (el fuego)
func herir(cantidad: float, _color := Color.WHITE) -> void:
	recibir_golpe(maxi(1, roundi(cantidad)), Vector2.ZERO)


# Revienta: salta todo lo de dentro y desaparece
func romper() -> void:
	if roto:
		return
	roto = true
	remove_from_group("zombis")
	remove_from_group("sacos_ingredientes")
	Sonido.tocar("portazo")
	for i in 14:
		Particulas.soltar(get_parent(), global_position + Vector2(0, -20),
			Vector2.from_angle(randf() * TAU) * randf_range(60, 180), COLORES[tipo][i % 2], randf_range(3, 6), 0.6)
	queue_free()
