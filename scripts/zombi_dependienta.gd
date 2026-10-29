# La dependienta del centro comercial (parte 4 del plan, docs/historial/CENTRO_COMERCIAL.md): flojita (vida 20) pero
# rápida, y lo peor es su grito:
#   - Al despertar grita «¡OFERTAS!»: despierta a toda la tienda y durante 5 s todos los zombis van un 30 % más
#     rápido (zombi.gd, meter_prisa).
#   - Luego no se acerca: se aparta de Johnny, guardando las distancias, y vuelve a gritar cada 8 s.
#   - Si la acorralas, te chilla en la cara (un golpe flojo, 6).
# El grito usa la animación de ataque (el chillido con las manos en la boca); no tiene zarpazo.
extends Zombi

const GRITO_CADA := 8.0     # cada cuánto vuelve a gritar
const PRISA_GRITO := 5.0    # lo que dura la prisa de los demás
const CERCA := 200.0        # más cerca que esto, se aparta de Johnny
const LEJOS := 300.0        # más lejos que esto, se acerca (para que no se pierda de vista)

var grito_t := 0.0          # lo que le falta para el siguiente grito (empieza gritando)


# Al despertar no se queda pasmada como los demás: grita enseguida (en andar, que ya le toca)
func despertar() -> void:
	var estaba := dormido
	super()
	if estaba:
		espabilando = 0.0


func andar(delta: float, johnny: Node2D) -> void:
	grito_t -= delta
	if grito_t <= 0.0:
		gritar(johnny)
		return
	var hacia: Vector2 = global_position.direction_to(johnny.global_position)
	var distancia := distancia_a(johnny)
	var ve := se_ve(johnny)
	# acorralada: le chilla en la cara
	if distancia < radio + johnny.RADIO + alcance and ve:
		empezar_zarpazo(johnny)
		return
	if not ve or distancia > LEJOS:
		ir_hacia(delta, camino_hacia(johnny.global_position), velocidad)
	elif distancia < CERCA:
		# se aparta usando el mapa de navegación: con una pared detrás, se escapa por un lado
		ir_hacia(delta, camino_hacia(global_position - hacia * 140.0), velocidad)
	else:
		pedir_velocidad(Vector2.ZERO)
		poner_animacion("reposo")
	mirar_hacia(hacia)


# «¡OFERTAS!»: despierta a todos los de la tienda y les mete prisa (a ella también)
func gritar(johnny: Node2D) -> void:
	estado = "grito"
	grito_t = GRITO_CADA
	mirar_hacia(johnny.global_position - global_position)
	poner_animacion("ataque", true)
	Sonido.tocar("chillido")
	Zombi.texto_flotante(get_parent(), global_position + Vector2(-44, -altura), Idioma.t("¡OFERTAS!"), Color("#ff5a4f"), 22)
	for otro in get_tree().get_nodes_in_group("zombis"):
		if otro.get("dormido"):
			otro.despertar()
		if otro.has_method("meter_prisa"):
			otro.meter_prisa(PRISA_GRITO)


# Mientras grita se queda plantada (si se moviera sin mover las piernas, parecería que flota)
func estado_propio(_delta: float, _johnny: Node2D) -> void:
	if estado != "grito":
		return
	pedir_velocidad(Vector2.ZERO)
	if not sprite.is_playing():
		estado = "andar"
