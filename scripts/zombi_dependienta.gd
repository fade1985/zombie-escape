# La dependienta del centro comercial (parte 4 del plan, docs/historial/CENTRO_COMERCIAL.md): flojita (vida 20) pero
# rápida, y lo peor es su grito (18 nov, lo pidió el dueño; antes, M80, ponía a los demás una barrera y huía):
#   - Al despertar grita «¡¡¡AAAHHH!!!», una sola vez: despierta a toda la tienda y enfurece a todos los demás zombis
#     que hay en ese momento (zombi.gd, enfurecer; a ella no, 18 nov): un 25 % más rápidos andando y atacando y un 25 % más de vida,
#     ardiendo en rojo. Los jefes no (el jefe de seguridad tampoco).
#   - La furia les dura hasta que ella muere: o la matas primero, o te los cargas a todos furiosos.
#   - Después pelea como un durmiente más: va a por Johnny y le da zarpazos.
# Fuera del jefe (el gerente llama a dos), nunca hay más de una en la misma sala; con dos, la furia no se suma.
# Su dibujo (18 nov) es el de 112 px de PixelLab, reducido desde el 19 nov (lo pidió el dueño) a la altura de Johnny y con
# su borde negro, a escala 2 como los zombis de 48 (tools/hoja_112.py, con "reducir" en su ficha
# assets/sources/dependienta-96-gpt/hoja.json; receta en docs/ZOMBIS_112.md). El
# grito tiene su animación propia («grito», siempre de cara: la misma en las 8 direcciones) y la de ataque queda para
# los zarpazos.
extends Zombi

var gritado := false        # ya ha gritado (solo grita una vez)


# (18 nov, lo pidió el dueño: la furia de su grito es para los demás; a ella no le afecta, ni la de otra dependienta)
func _ready() -> void:
	super()
	se_enfurece = false


# Al despertar no se queda pasmada como los demás ni suelta el "!": grita enseguida (en andar, que ya le toca)
func despertar() -> void:
	exclamacion = false
	var estaba := dormido
	super()
	if estaba:
		espabilando = 0.0


func andar(delta: float, johnny: Node2D) -> void:
	if not gritado:
		gritar(johnny)
		return
	super(delta, johnny)


# «¡¡¡AAAHHH!!!» (M79; antes, «¡OFERTAS!»): despierta a todos y enfurece a los demás (a ella no)
func gritar(johnny: Node2D) -> void:
	gritado = true
	estado = "grito"
	mirar_hacia(johnny.global_position - global_position)
	poner_animacion("grito", true)
	Sonido.tocar("chillido")
	# grande, rojo como su furia y encima de ella, como el «¡¡¡GRRR!!!» del jefe de seguridad (zombi_guardia.gd)
	var grito := Zombi.texto_flotante(get_parent(), global_position + Vector2(0, -110), Idioma.t("¡¡¡AAAHHH!!!"), Tema.ROJO,
		32, true, 1.4)
	var sin_luz := CanvasItemMaterial.new()   # (como los gritos de Johnny: que no lo apague la penumbra)
	sin_luz.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	grito.material = sin_luz
	# la primera vez que se la oye, su tutorial (tutoriales.gd), cuando ya se ve a los demás arder en rojo
	var partida := get_tree().current_scene
	if partida.has_method("tutorial"):
		get_tree().create_timer(0.6, false).timeout.connect(partida.tutorial.bind("dependienta"))
	for otro in get_tree().get_nodes_in_group("zombis"):
		if otro.has_method("enfurecer"):
			otro.enfurecer(self)
		if otro.get("dormido"):
			otro.despertar()


# Mientras grita se queda plantada (si se moviera sin mover las piernas, parecería que flota)
func estado_propio(_delta: float, _johnny: Node2D) -> void:
	if estado != "grito":
		return
	pedir_velocidad(Vector2.ZERO)
	if not sprite.is_playing():
		estado = "andar"
