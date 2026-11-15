# El frío del lanza hielo en los jefes (15 nov, lo pidió el dueño): lo llevan Minijefe y la portera (cada uno tiene uno,
# "hielo"). A diferencia de los zombis (que congelados mueren de un golpe), a los jefes:
#   - les cuesta el doble enfriarse (HELOR: el chorro les enfría a la mitad) y se quedan congelados solo CONGELA
#     segundos, quietos, azules y en su bloque de hielo (el de los zombis, más grande), sin pensar, atacar ni hacer daño
#     al tocarles;
#   - mientras están congelados, todo golpe o bala les hace crítico (el de Johnny: stats.critico_x, con su número
#     amarillo), pero no los mata de una vez;
#   - al deshelarse, el hielo revienta y siguen con lo suyo; durante SIN_FRIO segundos el frío no les hace nada (para
#     que no se les pueda tener congelados todo el combate).
# El jefe tiene que tener "sprite", "estado", "invulnerable", frenar(delta) y mover()
class_name HieloJefe
extends RefCounted

const HELOR := 0.5
const CONGELA := 2.0
const SIN_FRIO := 3.0

var jefe: Node2D
var arriba := 120.0      # la altura de su cabeza (lo alto que es el bloque)
var helor := 0.0         # lo enfriado (0..1): azul; a 1, se congela
var espera := 0.0        # lo que hace que no le da el chorro
var congelado := 0.0
var sin_frio := 0.0
var bloque: EfectoSuelo = null


func _init(quien: Node2D, alto: float) -> void:
	jefe = quien
	arriba = alto


# El chorro le da (llamarada.gd): gritando, invulnerable o recién deshelado, nada
func enfriar(cuanto: float) -> void:
	if congelado > 0.0 or sin_frio > 0.0 or jefe.estado in ["muerto", "grito"] or jefe.invulnerable \
			or jefe.get("esperando"):
		return
	espera = 0.0
	helor += cuanto * HELOR
	if helor >= 1.0:
		congelar()
	else:
		tintar(0.12 + 0.36 * helor)


# Cada paso del jefe, antes de pensar: si está congelado, solo frena lo que le empujen y devuelve true (ese paso no
# hace nada más); si no, se le va pasando el frío si hace rato que no le da el chorro
func paso(delta: float) -> bool:
	if congelado > 0.0:
		congelado -= delta
		jefe.frenar(delta)
		jefe.mover()
		if congelado <= 0.0:
			deshelar()
		return true
	sin_frio -= delta
	if helor > 0.0:
		espera += delta
		if espera > Zombi.HELOR_ESPERA:
			helor = maxf(helor - Zombi.HELOR_PASA * delta, 0.0)
			tintar(0.12 + 0.36 * helor if helor > 0.0 else 0.0)
	return false


func congelar() -> void:
	helor = 0.0
	congelado = CONGELA
	jefe.sprite.pause()
	tintar(0.6)
	Sonido.tocar("cristal")
	EfectoSuelo.soltar(jefe.get_parent(), "escarcha-zombi", jefe.global_position, 1.5)
	if bloque == null:
		bloque = EfectoSuelo.new()
		bloque.tipo = "bloque-hielo"
		bloque.escala = clampf((arriba + 20.0) / 104.0, 1.2, 2.2)   # (el bloque mide 104 a escala 1: hasta la cabeza)
		bloque.position = Vector2(0, 20)
		jefe.add_child(bloque)


# Se le acaba (o muere congelado): el hielo revienta (el "deshielo", más grande)
func deshelar() -> void:
	if congelado <= 0.0 and bloque == null:
		return
	congelado = 0.0
	sin_frio = SIN_FRIO
	tintar(0.0)
	jefe.sprite.play()
	if bloque:
		bloque.queue_free()
		bloque = null
	Sonido.tocar("deshielo")
	EfectoSuelo.soltar(jefe.get_parent(), "deshielo", jefe.global_position, 1.5)


# Lo que le quita un golpe de "cantidad" (con "fuerza": un golpe, una bala o una explosión; sin ella, el fuego o el
# ácido): congelado, crítico. Deja Zombi.critico encendido para que su número salga amarillo: quien llama lo vuelve a
# poner como estaba después de sacar el número
func golpe(cantidad: int, fuerza: Vector2) -> int:
	if congelado <= 0.0 or fuerza == Vector2.ZERO:
		return cantidad
	Sonido.tocar("cristal")
	if Zombi.critico:
		return cantidad   # (ya era crítico: no se dobla otra vez)
	Zombi.critico = true
	var johnny := jefe.get_tree().get_first_node_in_group("jugador")
	return roundi(cantidad * (johnny.stats.critico_x if johnny else 2.0))


# Lo azul que se ve: con el shader de los zombis (el Gymbro), su "hielo"; si no, tiñe el dibujo
func tintar(k: float) -> void:
	var m := jefe.sprite.material as ShaderMaterial
	if m and m.shader == Zombi.DESTELLO:
		m.set_shader_parameter("hielo", k)
	else:
		jefe.sprite.self_modulate = Color.WHITE.lerp(Color(0.55, 0.8, 1.0), clampf(k / 0.6, 0.0, 1.0))
