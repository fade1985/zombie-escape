# Pruebas de las armas: la sala de pruebas (--armas), el lanzallamas, el lanza ácido y la pistola
# eléctrica (--lanzallamas, --desintegrador, --pistola-electrica) y el fuego y el ácido en los enemigos (--tintes,
# --fuego-acido) y los trucos de las Épicas (--epicas). Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_jefes.gd"


# Con "--captura --armas": la sala de pruebas (sala_armas.gd). Desde la sala de mantenimiento, F11 lleva a
# ella: cuenta en la terminal su tamaño, que la diana está en el centro, que hay luz y que se entra con la pistola. La
# pistola, en el modo asistido y a 200 de la diana, desde 72 ángulos (cada 5°; 0° = disparando hacia la derecha, 90° =
# hacia abajo): si la primera bala le da, pasa por el lado (y a cuánto) o choca, y los ángulos desde los que falla
# (desde el 24 oct la bala va de la boca al zombi: ninguno); y a quemarropa, a 40, desde 8 direcciones.
# Luego, que la diana no se ha muerto ni ha perdido vida (y cuántos zombis normales habría matado), que la reserva sigue llena y que ha recargado; que el punto pasa
# a la escopeta y la coma vuelve (con el recuento a cero) y llega a la última de la tienda (la pistola eléctrica), que el guion esconde y
# saca el panel; y que F11 vuelve a la sala
# de mantenimiento con las armas y las balas de antes. Fotos: captura-armas.png (la sala con las líneas de ayuda y el
# panel, tras un fallo por el lado), captura-armas-pistola-<e, se, n, o>.png (Johnny disparando con la Beretta hacia cada
# lado, con el fogonazo) y captura-armas-escopeta.png (los perdigones). Cada línea dice lo esperado
func probar_armas() -> void:
	johnny.coger("fregona")   # (entra con la de cuerpo a cuerpo en la mano, para ver que le pone la pistola)
	var antes := [johnny.huecos.duplicate(), johnny.mano, johnny.balas, johnny.reserva()]
	await pulsar_y_esperar(KEY_F11)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	var sitio: Dictionary = planta.sitios[aqui]
	var centro := Vector2(sitio.ancho, sitio.alto) / 2.0
	print("Sala de pruebas: en «%s» (esperado: armas) · %d × %d · la diana en el centro %s, la única %s (esperado: true, true) · oscuridad %s (esperado: 0) · en la mano: %s (esperado: Pistola)" % [
		sitio.tipo, sitio.ancho, sitio.alto, sala.diana.global_position.distance_to(centro) < 2.0,
		get_tree().get_nodes_in_group("zombis").size() == 1, luz.oscuridad(), johnny.arma().nombre])
	johnny.poner_modo("asistido")
	var recargo := false
	var vida_min: int = sala.diana.vida_max   # la vida más baja que se le ha visto a la diana
	var resultados := []   # [ángulo, fin, pasa, dirección]
	var foto := -1         # el primer ángulo que falla por el lado: su foto
	for grados in range(0, 360, 5):
		var a := deg_to_rad(grados)
		johnny.position = sala.diana.global_position - Vector2.from_angle(a) * 200.0
		johnny.velocity = Vector2.ZERO
		var antes_tiros := sala.tiros
		var espera := 0.0
		while sala.tiros == antes_tiros and espera < 3.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
			recargo = recargo or johnny.recargando > 0.0
			vida_min = mini(vida_min, sala.diana.vida)
		var b: Dictionary = sala.balas.back()
		while b.fin == "" and espera < 5.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
			vida_min = mini(vida_min, sala.diana.vida)
		resultados.append([grados, b.fin, b.pasa, johnny.direccion])
		if b.fin == "lado" and foto < 0:
			foto = grados
			await get_tree().create_timer(0.05).timeout
			Captura.foto("captura-armas.png")
	var lineas := []
	var fila := []
	for r in resultados:
		fila.append("%d° %s %s" % [r[0], r[3], "da" if r[1] == "acierto" else "%s a %d" % [r[1], roundi(r[2])]])
		if fila.size() == 6:
			lineas.append(" · ".join(fila))
			fila = []
	print("Pistola desde cada ángulo (dirección de Johnny, si da, o cómo falla y a cuánto pasa del centro; le da a menos de 23):
  " + "
  ".join(lineas))
	var falla := resultados.filter(func(r): return r[1] != "acierto")
	print("Da desde %d de %d ángulos; falla desde: %s" % [resultados.size() - falla.size(), resultados.size(),
		", ".join(falla.map(func(r): return "%d°" % r[0])) if not falla.is_empty() else "ninguno"])
	print("Diana: viva %s · la vida más baja que se le ha visto %d de %d (esperado: true, %d, siempre llena) · habría matado %d zombis normales (esperado: más de 0) · aciertos del recuento %d" % [
		sala.diana.estado != "muerto", vida_min, sala.diana.vida_max, sala.diana.vida_max, sala.abatidos, sala.aciertos])
	print("Munición: reserva %d (esperado: 99, sin fin) · ha recargado %s (esperado: true)" % [johnny.reserva(),
		recargo])
	# A quemarropa: a 40 del centro de la diana, la boca de la Beretta queda más allá del zombi (johnny.gd, tiro)
	var pegado := 0
	for grados in range(0, 360, 45):
		johnny.position = sala.diana.global_position - Vector2.from_angle(deg_to_rad(grados)) * 40.0
		johnny.velocity = Vector2.ZERO
		var tiros_antes := sala.tiros
		var espera := 0.0
		while sala.tiros == tiros_antes and espera < 3.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
		var b: Dictionary = sala.balas.back()
		while b.fin == "" and espera < 5.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
		pegado += 1 if b.fin == "acierto" else 0
	print("A quemarropa (a 40 de la diana): da desde %d de 8 direcciones (esperado: 8)" % pegado)
	# La Beretta disparando hacia la derecha, en diagonal hacia abajo, de espaldas y hacia la izquierda, justo al salir la bala
	for d in [["e", 0], ["se", 45], ["n", 270], ["o", 180]]:
		johnny.position = sala.diana.global_position - Vector2.from_angle(deg_to_rad(d[1])) * 140.0
		johnny.velocity = Vector2.ZERO
		var tiros_antes := sala.tiros
		var espera := 0.0
		while sala.tiros == tiros_antes and espera < 3.0:
			await get_tree().physics_frame
			espera += get_physics_process_delta_time()
		await get_tree().create_timer(0.03).timeout
		Captura.foto("captura-armas-pistola-%s.png" % d[0])
	await pulsar_y_esperar(KEY_PERIOD)
	for i in 2:
		await get_tree().physics_frame
	# (Johnny ya ha disparado con ella: lo que cuenta tienen que ser solo sus perdigones, cinco por disparo)
	print("Con el punto: %s (esperado: Escopeta) · recuento a cero: %d disparos y %d balas (esperado: cinco balas por disparo)" % [
		johnny.arma().nombre, johnny.disparos - sala.disparos_desde, sala.tiros])
	johnny.position = sala.diana.global_position - Vector2(150, 0)
	await get_tree().create_timer(1.3).timeout
	Captura.foto("captura-armas-escopeta.png")
	print("Escopeta a 150: balas %d · aciertos %d" % [sala.tiros, sala.aciertos])
	await pulsar_y_esperar(KEY_MINUS)
	await get_tree().physics_frame
	var escondido: bool = not sala.panel.visible
	await pulsar_y_esperar(KEY_MINUS)
	await get_tree().physics_frame
	print("Con el guion, el panel se esconde %s y vuelve %s (esperado: true, true)" % [escondido, sala.panel.visible])
	await pulsar_y_esperar(KEY_COMMA)
	await get_tree().physics_frame
	var vuelta: String = johnny.arma().nombre
	for i in 4:
		await pulsar_y_esperar(KEY_COMMA)
	print("Con la coma: %s (esperado: Pistola) · cuatro más atrás: %s (esperado: la última de la tienda, %s)" % [
		vuelta, johnny.arma().nombre, Armas.DATOS[sala.lista.back()].nombre])
	await pulsar_y_esperar(KEY_F11)
	await get_tree().create_timer(0.3).timeout
	print("De vuelta con F11: en «%s» (esperado: mantenimiento) · armas %s (esperado: true) · balas %d y %d (esperado: %d y %d)" % [
		planta.sitios[aqui].tipo, [johnny.huecos, johnny.mano] == [antes[0], antes[1]], johnny.balas, johnny.reserva(),
		antes[2], antes[3]])
	get_tree().quit()


# Pulsa y suelta una tecla y, si con ella se cambia de sitio, espera a que acabe el fundido
func pulsar_y_esperar(tecla: Key) -> void:
	for pulsada in [true, false]:
		var evento := InputEventKey.new()
		evento.keycode = tecla
		evento.pressed = pulsada
		Input.parse_input_event(evento)
	var espera := 0.0
	while not cambiando and espera < 0.2:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()
	while cambiando and espera < 3.0:
		await get_tree().physics_frame
		espera += get_physics_process_delta_time()


# Con "--captura --lanzallamas": el lanzallamas de la llamarada continua (Armas.DATOS.lanzallamas, llamarada.gd; la
# hoja de ahora, conserje-48-lanzallamas, en la postura de apuntar). Primero, en la sala de mantenimiento, Johnny lo
# compra en la tienda de armas del ordenador (captura-lanzallamas-tienda.png, con él marcado) y cuenta su hoja, su daño
# por segundo, su alcance (10 casillas), su depósito, su recarga, su empuje, sus pies, su boca hacia el este, que no le
# salen chispitas y que las cajas de munición no le valen. Luego, en la sala de pruebas (F11: cabe la llama
# entera), con el lanzallamas comprado y gastando gasolina de verdad:
#   - la llamarada: 1 s echando fuego hacia la derecha (a la izquierda está el panel de la sala) con tres zombis en la
#     misma línea, a 120 y a 250 (los dos dentro: pierden vida, arden y el primero se va hacia atrás) y a 430 (más allá de las 10 casillas: ni se entera).
#     Johnny no pierde vida, no queda fuego en el suelo y el depósito gasta 1 s; al soltar, se apaga
#     (captura-lanzallamas-llama.png, a media llama, con la barra de gasolina abajo)
#   - a oscuras (Luz.evento, como en el apagón), la llama alumbra alrededor (captura-lanzallamas-oscuro.png); y al
#     soltar, se despega de la boca y se va (captura-lanzallamas-apagando.png); y contra la pared, se corta en ella y se
#     aplasta abriéndose (captura-lanzallamas-pared.png)
#   - hacia zombis entre dos direcciones del dibujo (chorro_torcido): al un poco apartado de la línea, sale recto por
#     donde apunta el tubo y su cono de 45° le da; al del hueco entre la diagonal y abajo, se gira lo justo para que
#     entre por el borde; sin bailar entre dos direcciones (captura-lanzallamas-recto.png y captura-lanzallamas-hueco.png)
#   - el depósito: casi vacío y con una gasolina en la mochila, al vaciarse se llena solo y la gasta; sin gasolina,
#     «¡Sin gasolina!», saca la de cuerpo a cuerpo y la Q no deja volver (captura-lanzallamas-sin-gasolina.png); al coger
#     una gasolina del suelo vuelve a sacar el lanzallamas y lo llena
#   - la llama en las 8 direcciones (captura-lanzallamas-<dirección>.png); andando, anda lo mismo que sin echar fuego
#     (captura-lanzallamas-andando.png); y con las 4 skins, con su hoja
#     (captura-lanzallamas-<skin>.png), con Johnny quieto en la postura de apuntar
# Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_lanzallamas() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g2):
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	await comprar_en_tienda("lanzallamas", "captura-lanzallamas-tienda.png")

	# comprado: sus números, su boca y sin chispitas; las balas no le valen
	var id := "lanzallamas"
	var w := Armas.datos(id)
	johnny.modo = "quieto"   # que no eche fuego por su cuenta: aquí lo echa la prueba
	await get_tree().create_timer(0.3).timeout
	print("Lanzallamas en la mano: %s · hoja «%s» · daño %d/s · alcance %.0f (%.0f casillas) · depósito %.0f s (lleno: %.1f) · recarga %.1f s · empuje %.1f · pies %s · boca este %s · chispitas %s · icono «%s» · la caja es para «%s» (esperado: lanzallamas, conserje-48-lanzallamas.tres, 30, 320 (10), 8 (8.0), 1.5, 0.5, (48, 72), (28, -22), false, lanzallamas, pistola: la de repuesto)" % [
		johnny.huecos.fuego, johnny.sprite.sprite_frames.resource_path.get_file(), w.dano, w.alcance, w.alcance / Planta.CASILLA,
		w.deposito, johnny.deposito, w.recarga, w.empuje, w.pies, w.boca.e, w.has("detalle"), Objetos.icono(id), johnny.arma_de_caja()])

	# a la sala de pruebas (allí le ponen la pistola y la gasolina sin fin: se le vuelve a dar este, gastando)
	await pulsar_y_esperar(KEY_F11)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	johnny.coger(id)
	johnny.municion_sin_fin = false
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no le tape en las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	johnny.global_position = sala.diana.global_position + Vector2(0, 200)
	johnny.direccion = "e"
	johnny.get_node("Camara").reset_smoothing()
	var z := []
	for d in [Vector2(120, 0), Vector2(250, 0), Vector2(430, 0)]:
		var zombi: Node2D = meter_zombi("lento", johnny.position + d)
		zombi.vida = 500
		z.append(zombi)
	await get_tree().process_frame
	for zombi in z:
		zombi.aturdido = 30.0   # quietos (los empujones sí les mueven)
	var x0: float = z[0].position.x
	while "gasolina" in mochila:
		mochila.erase("gasolina")
	mochila.append_array(["gasolina", "gasolina"])   # (para que la barra de abajo enseñe dos)
	var deposito0: float = johnny.deposito
	var vida_johnny: int = johnny.vida
	var charcos: int = get_tree().get_nodes_in_group("charcos").size()
	await echar_fuego(0.0, 1.0, "captura-lanzallamas-llama.png")
	var encendida: bool = johnny.llamarada.encendida
	var gastado: float = deposito0 - johnny.deposito
	await get_tree().create_timer(0.3).timeout
	print("Llamarada 1 s hacia la derecha: a 120 pierde %d, arde %s, empujado %.0f · a 250 pierde %d, arde %s (esperado: más de 50 (con lo que arde y los críticos), true, más de 0, y lo mismo)" % [
		500 - z[0].vida, z[0].arder_t > 0.0, z[0].position.x - x0, 500 - z[1].vida, z[1].arder_t > 0.0])
	print("Zombi a 430 (más allá de las 10 casillas): pierde %d · arde %s (esperado: 0 y false)" % [500 - z[2].vida, z[2].arder_t > 0.0])
	print("Depósito gastado %.2f s (esperado: 1.00 más o menos) · Johnny -%d (esperado: 0) · fuego nuevo en el suelo %d (esperado: 0) · encendida mientras %s, al soltar %s (esperado: true, false)" % [
		gastado, vida_johnny - johnny.vida, get_tree().get_nodes_in_group("charcos").size() - charcos, encendida,
		johnny.llamarada.visible])
	for zombi in z:
		zombi.remove_from_group("zombis")
		zombi.queue_free()

	# a oscuras (como en el apagón): la llama alumbra alrededor; y al soltar, se despega de la boca y se va
	Luz.evento = 0.85
	await get_tree().create_timer(0.8).timeout
	await echar_fuego(0.0, 0.6, "captura-lanzallamas-oscuro.png")
	var alumbra: bool = johnny.llamarada.luz.enabled and johnny.llamarada.luz.energy > 0.5
	for i in 4:
		await get_tree().physics_frame
	Captura.foto("captura-lanzallamas-apagando.png")
	print("A oscuras: oscuridad %.2f · la llama alumbra %s · al soltar, despegada de la boca %.0f de %.0f (esperado: 0.85, true, más de 0)" % [
		Luz.nivel, alumbra, johnny.llamarada.cola, johnny.llamarada.largo])
	Luz.evento = 0.0
	await get_tree().create_timer(0.8).timeout
	# contra la pared: la llama se corta en ella y se aplasta abriéndose (captura-lanzallamas-pared.png)
	var puesto: Vector2 = johnny.global_position
	johnny.global_position = sala.diana.global_position + Vector2(380, 200)
	johnny.get_node("Camara").reset_smoothing()
	await echar_fuego(0.0, 0.5, "captura-lanzallamas-pared.png")
	print("Contra la pared: la llama llega a %.0f de %.0f (esperado: menos de 320)" % [johnny.llamarada.tope, johnny.llamarada.alcance])
	johnny.global_position = puesto
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.4).timeout
	# hacia zombis entre dos direcciones del dibujo: sale recto por el tubo y el cono le da al que no está justo en él
	# (al que queda fuera, se gira lo justo)
	johnny.global_position = sala.diana.global_position + Vector2(-150, -100)
	johnny.get_node("Camara").reset_smoothing()
	await chorro_torcido("lanzallamas")
	johnny.global_position = puesto
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.4).timeout

	# el depósito: casi vacío y con una gasolina, se llena solo al vaciarse y la gasta
	while "gasolina" in mochila:
		mochila.erase("gasolina")
	mochila.append("gasolina")
	johnny.deposito = 0.1
	await echar_fuego(PI, 0.3)
	var recarga: bool = johnny.recargando > 0.0
	await get_tree().create_timer(1.7).timeout
	print("Depósito vacío con una gasolina: recarga sola %s · depósito %.1f s · gasolinas que quedan %d (esperado: true, 8.0, 0)" % [
		recarga, johnny.deposito, mochila.count("gasolina")])
	# sin gasolina: se apaga, avisa y saca la de cuerpo a cuerpo, y la Q no deja volver
	johnny.deposito = 0.1
	await echar_fuego(PI, 0.3)
	Captura.foto("captura-lanzallamas-sin-gasolina.png")
	var mano: String = johnny.mano
	johnny.cambiar_mano()
	print("Sin gasolina: en la mano «%s» · después de la Q, «%s» · llama encendida %s (esperado: cuerpo, cuerpo, false)" % [
		mano, johnny.mano, johnny.llamarada.encendida])
	# coge una gasolina del suelo: vuelve a sacar el lanzallamas y lo llena
	soltar_objeto("gasolina", johnny.position + Vector2(30, 0))
	await get_tree().create_timer(2.2).timeout
	print("Coge una gasolina del suelo: en la mano «%s» · depósito %.1f s · gasolinas %d (esperado: fuego, 8.0, 0)" % [
		johnny.mano, johnny.deposito, mochila.count("gasolina")])

	# las 8 direcciones, quieto en la postura de apuntar (con la gasolina sin fin: aquí ya no se cuenta)
	johnny.municion_sin_fin = true
	var posturas := []
	for d in johnny.DIRS:
		johnny.deposito = w.deposito
		johnny.direccion = d
		await echar_fuego(johnny.DIRS.find(d) * PI / 4, 0.4, "captura-lanzallamas-%s.png" % d)
		posturas.append(johnny.sprite.animation)
		await get_tree().create_timer(0.2).timeout
	print("Postura echando fuego en cada dirección: %s (esperado: quieto_<dirección> en las 8)" % ", ".join(posturas))

	# andando: echando fuego anda lo mismo que sin echarlo (0,8 s hacia la derecha cada vez, desde parado), con la llama
	# saliendo del tubo mientras anda (captura-lanzallamas-andando.png)
	var andado := []
	for con_fuego in [false, true]:
		johnny.global_position = sala.diana.global_position + Vector2(-300, 200)
		johnny.velocity = Vector2.ZERO
		johnny.get_node("Camara").reset_smoothing()
		await get_tree().create_timer(0.2).timeout
		var desde: Vector2 = johnny.global_position
		Input.action_press("derecha")
		if con_fuego:
			await echar_fuego(0.0, 0.8, "captura-lanzallamas-andando.png")
		else:
			await get_tree().create_timer(0.8).timeout
		Input.action_release("derecha")
		andado.append(johnny.global_position.distance_to(desde))
		await get_tree().create_timer(0.3).timeout
	print("Andando 0,8 s: sin fuego %.0f · echando fuego %.0f (esperado: lo mismo, más o menos)" % andado)

	# con cada skin: su hoja del lanzallamas
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.deposito = w.deposito
		await echar_fuego(0.0, 0.3, "captura-lanzallamas-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-lanzallamas-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.2).timeout

	Guardado.cambiar(func(g2):
		g2.dolares = antes.dolares
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Compra un arma en la tienda de armas del ordenador (con dólares de sobra): antes, una foto de la tienda con ella
# marcada y lo que dice de ella. Lo usan probar_lanzallamas, probar_desintegrador y probar_pistola_electrica
func comprar_en_tienda(id: String, foto: String) -> void:
	Guardado.cambiar(func(g2): g2.dolares = maxi(g2.dolares, 200))
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("armas", "b_" + id)
	await get_tree().create_timer(0.3).timeout
	print("En la tienda: %s a la venta por $%d · dice «%s»" % [Armas.DATOS[id].nombre, Armas.PRECIOS[id], ordenador.info.text])
	Captura.foto(foto)
	ordenador.comprar_arma(id)
	await get_tree().process_frame
	print("Comprado: en la mano %s · dice «%s»" % [johnny.huecos.fuego, ordenador.info.text])
	ordenador.abrir("")
	ordenador.apagar()
	await get_tree().process_frame


# Johnny echa fuego con el lanzallamas (o el chorro del lanza ácido) hacia "angulo" durante "segundos" (en cada paso,
# como si se mantuviera el botón) y, si se pide, saca una foto a la mitad. Lo usan probar_lanzallamas,
# probar_desintegrador y probar_skin_bombero
func echar_fuego(angulo: float, segundos: float, foto := "") -> void:
	var t := 0.0
	var hecha := foto == ""
	while t < segundos:
		johnny.intentar_atacar(angulo)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		if not hecha and t >= segundos / 2.0:
			hecha = true
			Captura.foto(foto)


# El chorro del lanza ácido (o la llama del lanzallamas) hacia zombis que no caen en ninguna de las 8 direcciones del
# dibujo (abajo a la derecha, más hacia abajo que la diagonal, como en la foto del dueño del 25 oct). Johnny mira hacia
# abajo (el tubo de la diagonal va más tumbado y le quedaría más lejos), sin cambiar de dirección mientras. Al zombi un
# poco apartado de la línea del tubo ya le pilla su cono de 45°: el chorro sale recto por el tubo, sin girarse nada, y
# le da (captura-<arma>-recto.png). Al que cae justo en el hueco entre la diagonal y abajo (a unos 36° del tubo), el
# chorro se gira desde el tubo lo justo para que entre por el borde, con el margen (MARGEN_CHORRO: queda a 19,5° del
# chorro), y le da (captura-<arma>-hueco.png). Luego el zombi va de la diagonal a abajo mientras le echa el chorro:
# Johnny pasa de una a otra una sola vez (no baila entre las dos)
func chorro_torcido(arma: String) -> void:
	var w: Dictionary = johnny.arma()
	var borde := rad_to_deg(Llamarada.ABRE - johnny.MARGEN_CHORRO)
	for caso in [["recto", Vector2(25, 160)], ["hueco", Vector2(80, 150)]]:
		var zombi: Node2D = meter_zombi("lento", johnny.position + caso[1])
		zombi.vida = 500
		await get_tree().process_frame
		zombi.aturdido = 30.0   # quieto (los empujones sí le mueven)
		var hacia: Vector2 = zombi.global_position - johnny.global_position
		var cambios := 0
		var antes := ""
		var t := 0.0
		while t < 0.6:
			johnny.intentar_atacar(hacia.angle())
			if antes != "" and johnny.direccion != antes:
				cambios += 1
			antes = johnny.direccion
			await get_tree().physics_frame
			t += get_physics_process_delta_time()
			if t >= 0.3 and t - get_physics_process_delta_time() < 0.3:
				Captura.foto("captura-%s-%s.png" % [arma, caso[0]])
		var l: Llamarada = johnny.llamarada
		var boca: Vector2 = l.global_position - Vector2(0, Llamarada.ALTURA)
		var eje := (Vector2.from_angle(l.angulo) + Vector2(0, (Llamarada.ALTURA - Llamarada.ALTURA_CUERPO) / l.alcance)).normalized()
		var tubo := deg_to_rad(w.cano[johnny.direccion])
		var cuerpo: Vector2 = zombi.global_position - Vector2(0, Llamarada.ALTURA_CUERPO)   # (donde se le ve el cuerpo)
		var de_boca: Vector2 = johnny.global_position + Vector2(w.boca[johnny.direccion].x * 2.0, 16.0 + w.boca[johnny.direccion].y * 2.0)
		var del_tubo := rad_to_deg(absf(angle_difference((cuerpo - boca).angle(), tubo)))
		print("Chorro hacia un zombi %s: mira «%s» (postura «%s») · cambios de dirección %d · sale a %.1f de la boca del dibujo · el zombi, a %.1f° del tubo · entre el tubo y el chorro %.1f° · el zombi, a %.1f° del chorro · le quita %d (esperado: s (quieto_s), 0, 0.0, %s, %s, %s, más de 0)" % [
			"un poco apartado de la línea del tubo (ya dentro del cono)" if caso[0] == "recto" else "en el hueco entre la diagonal y abajo (fuera del cono)",
			johnny.direccion, johnny.sprite.animation, cambios, boca.distance_to(de_boca), del_tubo,
			rad_to_deg(absf(angle_difference(eje.angle(), tubo))), rad_to_deg(absf(angle_difference((cuerpo - boca).angle(), eje.angle()))),
			500 - zombi.vida,
			"menos de %.1f" % borde if caso[0] == "recto" else "más de 22,5",
			"0.0, sin girarse" if caso[0] == "recto" else "%.1f, girado solo lo que se pasa" % (del_tubo - borde),
			"igual que del tubo" if caso[0] == "recto" else "%.1f, al borde con el margen" % borde])
		zombi.remove_from_group("zombis")
		zombi.queue_free()
		await get_tree().create_timer(0.4).timeout
	# el zombi va de la diagonal (abajo a la derecha) a abajo en 1 s, con el chorro encima
	var zombi: Node2D = meter_zombi("lento", johnny.position + Vector2(150, 150))
	await get_tree().process_frame
	zombi.aturdido = 30.0
	var direcciones := []
	var t := 0.0
	while t < 1.0:
		zombi.global_position = johnny.global_position + Vector2(150, 150).lerp(Vector2(10, 170), t)
		johnny.intentar_atacar((zombi.global_position - johnny.global_position).angle())
		if direcciones.is_empty() or direcciones[-1] != johnny.direccion:
			direcciones.append(johnny.direccion)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	print("El zombi pasa de la diagonal a abajo: Johnny mira %s (esperado: [\"se\", \"s\"], una sola vez cada una)" % [direcciones])
	zombi.remove_from_group("zombis")
	zombi.queue_free()


# Con "--captura --desintegrador": el lanza ácido (Armas.DATOS.desintegrador: en el juego «Lanza ácido» y por dentro
# el desintegrador), un lanzallamas de ácido. Su hoja es la del lanzallamas con las bombonas verdes y sin la llamita
# (tools/hoja_lanza_acido.py; casilla de 96x96 con los pies en 48,72) y su chorro, el de la llamarada con "acido"
# (llamarada.gd y chorro_acido.gdshader). Como el lanzallamas, en la sala de mantenimiento, Johnny lo compra en la
# tienda de armas del ordenador (captura-desintegrador-tienda.png, con él marcado) y cuenta sus números, su boca y que
# las balas no le valen. Luego, en la sala de pruebas (F11), gastando bidones de ácido de verdad:
#   - quieto, sin echar el chorro, la gota de ácido de la boquilla (goteo.gd): se hincha, cuelga entera
#     (captura-desintegrador-gota.png) y se suelta y cae (captura-desintegrador-cae.png)
#   - el chorro: 1 s hacia la derecha con tres zombis en la misma línea, a 120 y a 250 (los dos dentro: pierden vida,
#     se quedan con la herida de ácido y el primero se va hacia atrás) y a 430 (más allá de las 10 casillas: ni se
#     entera). Johnny no pierde vida, no queda ningún charco y no alumbra; al soltar, se apaga
#     (captura-desintegrador-chorro.png, a medio chorro), y la gota que colgaba se ha soltado
#   - al soltar, se despega de la boquilla y se va (captura-desintegrador-soltando.png); y contra la pared se corta
#     en ella y salpica (captura-desintegrador-pared.png)
#   - hacia zombis entre dos direcciones del dibujo (chorro_torcido): al un poco apartado de la línea, sale recto por
#     donde apunta el tubo y su cono de 45° le da; al del hueco entre la diagonal y abajo, se gira lo justo para que
#     entre por el borde; sin bailar entre dos direcciones (captura-desintegrador-recto.png y
#     captura-desintegrador-hueco.png)
#   - el depósito: casi vacío y con un bidón de ácido en la mochila, al vaciarse se llena solo y lo gasta; sin bidones,
#     «¡Sin ácido!», saca la de cuerpo a cuerpo y la Q no deja volver (captura-desintegrador-sin-acido.png, con la barra
#     verde del depósito vacía; una gasolina no le vale); al coger un bidón del suelo (captura-desintegrador-bidon.png,
#     el bidón en el suelo) vuelve a sacar el lanza ácido y lo llena
#   - el chorro en las 8 direcciones (captura-desintegrador-<dirección>.png), con la gota colgando antes de echarlo
#     (captura-desintegrador-gota-<dirección>.png), y con las 4 skins, con su hoja (captura-desintegrador-<skin>.png),
#     con el depósito sin fin
#   - al jefe de bomberos, al que el fuego no le hace nada, el ácido sí le quita vida (al final: su barra de vida se queda)
#   - los bidones de ácido: de 4000 gordos, cerca de 1 de cada 4 suelta uno (y nada más); ni los otros zombis ni el
#     reparto al azar los dan nunca; y en las Colecciones salen en los dos edificios, con «lo suelta el gordo»
# Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_desintegrador() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g2):
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	await comprar_en_tienda("desintegrador", "captura-desintegrador-tienda.png")

	# comprado: sus números, su boca y sin chispitas; las balas no le valen
	var id := "desintegrador"
	var w := Armas.datos(id)
	johnny.modo = "quieto"   # que no eche el chorro por su cuenta: aquí lo echa la prueba
	await get_tree().create_timer(0.3).timeout
	print("Lanza ácido en la mano: nombre «%s» · hoja «%s» · efecto %s · alcance %.0f (%.0f casillas) · depósito %.0f s · recarga %.1f s · empuje %.1f · daño %.0f/s · pies %s · boca este %s · chispitas %s · icono «%s» · la caja es para «%s» (esperado: Lanza ácido, conserje-48-desintegrador.tres, acido, 320 (10), 8, 1.5, 0.5, 30, (48, 72), (26, -20), false, desintegrador, pistola: la de repuesto)" % [
		w.nombre, johnny.sprite.sprite_frames.resource_path.get_file(), w.efecto, w.alcance, w.alcance / Planta.CASILLA,
		w.deposito, w.recarga, w.empuje, w.dano, w.pies, w.boca.e, w.has("detalle"), Objetos.icono(id), johnny.arma_de_caja()])

	# a la sala de pruebas (allí le ponen la pistola y el depósito sin fin: se le vuelve a dar este)
	await pulsar_y_esperar(KEY_F11)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	johnny.coger(id)
	johnny.municion_sin_fin = false
	while "bidon_acido" in mochila:
		mochila.erase("bidon_acido")
	mochila.append_array(["bidon_acido", "bidon_acido"])   # (para que la barra de abajo enseñe dos)
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no le tape en las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	johnny.global_position = sala.diana.global_position + Vector2(0, 200)
	johnny.direccion = "e"
	johnny.get_node("Camara").reset_smoothing()

	# la gota de la boquilla: se hincha, cuelga entera (la foto) y se suelta y cae
	await get_tree().create_timer(0.3).timeout
	var hinchandose: bool = johnny.goteo.t > 0.0
	johnny.goteo.t = johnny.goteo.dura * 0.8
	await get_tree().physics_frame
	Captura.foto("captura-desintegrador-gota.png")
	johnny.goteo.t = johnny.goteo.dura + Goteo.CUELGA - 0.01
	await get_tree().physics_frame
	var cae: bool = johnny.goteo.cayendo.size() > 0
	await get_tree().create_timer(0.12).timeout
	Captura.foto("captura-desintegrador-cae.png")
	await get_tree().create_timer(0.5).timeout
	print("La gota de la boquilla: se hincha %s · se suelta y cae %s · ya en el suelo %s (esperado: true, true, true)" % [
		hinchandose, cae, johnny.goteo.cayendo.is_empty()])

	# el chorro: 1 s hacia la derecha con tres zombis en la misma línea
	var z := []
	for d in [Vector2(120, 0), Vector2(250, 0), Vector2(430, 0)]:
		var zombi: Node2D = meter_zombi("lento", johnny.position + d)
		zombi.vida = 500
		z.append(zombi)
	await get_tree().process_frame
	for zombi in z:
		zombi.aturdido = 30.0   # quietos (los empujones sí les mueven)
	var x0: float = z[0].position.x
	var vida_johnny: int = johnny.vida
	var charcos: int = get_tree().get_nodes_in_group("charcos").size()
	johnny.goteo.t = johnny.goteo.dura * 0.8   # (una gota colgando: al echar el chorro se suelta)
	await get_tree().physics_frame
	await echar_fuego(0.0, 1.0, "captura-desintegrador-chorro.png")
	var encendido: bool = johnny.llamarada.encendida
	var alumbra: bool = johnny.llamarada.luz.enabled
	var gota_suelta: bool = johnny.goteo.t == 0.0
	await get_tree().create_timer(0.3).timeout
	print("Chorro 1 s hacia la derecha: a 120 pierde %d, ácido %s, empujado %.0f · a 250 pierde %d, ácido %s (esperado: más de 30 (con los críticos), true, más de 0, y lo mismo)" % [
		500 - z[0].vida, z[0].get_node_or_null("herida_acido") != null, z[0].position.x - x0, 500 - z[1].vida,
		z[1].get_node_or_null("herida_acido") != null])
	print("Zombi a 430 (más allá de las 10 casillas): pierde %d · ácido %s (esperado: 0 y false)" % [500 - z[2].vida,
		z[2].get_node_or_null("herida_acido") != null])
	print("Johnny -%d (esperado: 0) · charcos nuevos %d (esperado: 0) · encendido mientras %s, al soltar %s · alumbra %s · la gota que colgaba, suelta %s (esperado: true, false, false, true)" % [
		vida_johnny - johnny.vida, get_tree().get_nodes_in_group("charcos").size() - charcos, encendido,
		johnny.llamarada.visible, alumbra, gota_suelta])
	for zombi in z:
		zombi.remove_from_group("zombis")
		zombi.queue_free()

	# al soltar, se despega de la boquilla y se va; y contra la pared, se corta en ella y salpica
	await echar_fuego(0.0, 0.6)
	for i in 4:
		await get_tree().physics_frame
	Captura.foto("captura-desintegrador-soltando.png")
	print("Al soltar: despegado de la boquilla %.0f de %.0f (esperado: más de 0)" % [johnny.llamarada.cola, johnny.llamarada.largo])
	await get_tree().create_timer(0.5).timeout
	var puesto: Vector2 = johnny.global_position
	johnny.global_position = sala.diana.global_position + Vector2(380, 200)
	johnny.get_node("Camara").reset_smoothing()
	await echar_fuego(0.0, 0.5, "captura-desintegrador-pared.png")
	print("Contra la pared: el chorro llega a %.0f de %.0f (esperado: menos de 320)" % [johnny.llamarada.tope, johnny.llamarada.alcance])
	johnny.global_position = puesto
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.4).timeout
	# hacia zombis entre dos direcciones del dibujo: sale recto por el tubo y el cono le da al que no está justo en él
	# (al que queda fuera, se gira lo justo)
	johnny.global_position = sala.diana.global_position + Vector2(-150, -100)
	johnny.get_node("Camara").reset_smoothing()
	await chorro_torcido("desintegrador")
	johnny.global_position = puesto
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.4).timeout

	# el depósito: casi vacío y con un bidón de ácido, se llena solo al vaciarse y lo gasta
	while "bidon_acido" in mochila:
		mochila.erase("bidon_acido")
	mochila.append("bidon_acido")
	johnny.deposito = 0.1
	await echar_fuego(PI, 0.3)
	var recarga: bool = johnny.recargando > 0.0
	await get_tree().create_timer(1.7).timeout
	print("Depósito vacío con un bidón: recarga sola %s · depósito %.1f s · bidones que quedan %d · el texto «%s» (esperado: true, 8.0, 0, Lanza ácido   8 s · bidón de ácido x0)" % [
		recarga, johnny.deposito, mochila.count("bidon_acido"), texto_del_arma()])
	# sin bidones (con una gasolina en la mochila, que no le vale): se apaga, avisa y saca la de cuerpo a cuerpo, y la Q
	# no deja volver
	mochila.append("gasolina")
	johnny.deposito = 0.1
	await echar_fuego(PI, 0.3)
	var aviso: Array = johnny.get_parent().get_children().filter(
		func(n): return n is Label and n.text.begins_with("¡Sin")).map(func(n): return n.text)
	Captura.foto("captura-desintegrador-sin-acido.png")
	var mano: String = johnny.mano
	johnny.cambiar_mano()
	print("Sin bidones (con una gasolina): aviso %s · en la mano «%s» · después de la Q, «%s» · chorro encendido %s · gasolinas %d (esperado: [\"¡Sin ácido!\"], cuerpo, cuerpo, false, 1)" % [
		aviso, mano, johnny.mano, johnny.llamarada.encendida, mochila.count("gasolina")])
	mochila.erase("gasolina")
	# coge un bidón del suelo (la foto, antes de que vuele hacia él): vuelve a sacar el lanza ácido y lo llena
	soltar_objeto("bidon_acido", johnny.position + Vector2(60, 0))
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-desintegrador-bidon.png")
	await get_tree().create_timer(2.2).timeout
	print("Coge un bidón del suelo: en la mano «%s» · depósito %.1f s · bidones %d · icono «%s» (esperado: fuego, 8.0, 0, obj-bidon_acido)" % [
		johnny.mano, johnny.deposito, mochila.count("bidon_acido"), Objetos.icono("bidon_acido")])

	# las 8 direcciones: la gota colgando antes y el chorro saliendo del tubo, en la postura de apuntar (con el
	# depósito sin fin: aquí ya no se cuenta)
	johnny.municion_sin_fin = true
	var posturas := []
	for d in johnny.DIRS:
		johnny.deposito = w.deposito
		johnny.direccion = d
		await get_tree().physics_frame
		johnny.goteo.t = johnny.goteo.dura * 0.8
		await get_tree().physics_frame
		Captura.foto("captura-desintegrador-gota-%s.png" % d)
		await echar_fuego(johnny.DIRS.find(d) * PI / 4, 0.4, "captura-desintegrador-%s.png" % d)
		posturas.append(johnny.sprite.animation)
		await get_tree().create_timer(0.4).timeout
	print("Postura echando el chorro en cada dirección: %s (esperado: quieto_<dirección> en las 8)" % ", ".join(posturas))

	# con cada skin: su hoja del lanza ácido
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.deposito = w.deposito
		await echar_fuego(0.0, 0.3, "captura-desintegrador-%s.png" % skin)
		print("Con %s: hoja «%s» · puntas de la gota %s (esperado: conserje-48-desintegrador-%s.tres, true)" % [skin,
			johnny.sprite.sprite_frames.resource_path.get_file(), johnny.sprite.sprite_frames.has_meta("puntas"), skin])
		await get_tree().create_timer(0.2).timeout

	# al jefe de bomberos el fuego no le hace nada; el ácido, sí (quieto: que no ataque)
	var jefe: Node2D = meter_zombi("bombero", johnny.position + Vector2(150, 0))
	await get_tree().process_frame
	jefe.process_mode = Node.PROCESS_MODE_DISABLED
	var vida_jefe: int = jefe.vida
	await echar_fuego(0.0, 1.0)
	print("Jefe de bomberos (inmune al fuego %s): pierde %d con 1 s de ácido (esperado: true, más de 30)" % [
		jefe.get("inmune_fuego"), vida_jefe - jefe.vida])
	jefe.remove_from_group("zombis")
	jefe.queue_free()

	# los bidones de ácido: solo los suelta el gordo, 1 de cada 4 (y entonces nada más), en los dos edificios
	var suelta := {}
	for ed in ["apartamentos", "centro"]:
		for i in 2000:
			var obj := Objetos.que_suelta("venenoso", ed, "ferreteria" if ed == "centro" else "")
			suelta[obj] = suelta.get(obj, 0) + 1
	var otros := 0   # bidones de los demás zombis o del reparto al azar
	for tipo in ["normal", "lento", "rapido", "explosivo", "tentaculos"]:
		for i in 400:
			if Objetos.que_suelta(tipo) == "bidon_acido" or Objetos.que_suelta(tipo, "centro", "restaurante") == "bidon_acido":
				otros += 1
	for i in 2000:
		if Objetos.al_azar() == "bidon_acido" or Objetos.al_azar("centro") == "bidon_acido":
			otros += 1
	print("De 4000 gordos: %s (esperado: cerca de 1000 bidon_acido y el resto \"\", nada más) · bidones de otros zombis o al azar %d (esperado: 0)" % [
		suelta, otros])
	print("Colecciones: en los Apartamentos %s, en el centro %s · «%s» y «%s» · nombre «%s» · al baúl %s (esperado: true, true, lo suelta el gordo dos veces, Bidón de ácido, true)" % [
		"bidon_acido" in Objetos.de_edificio("apartamentos"), "bidon_acido" in Objetos.de_edificio("centro"),
		Objetos.donde("bidon_acido", "apartamentos"), Objetos.donde("bidon_acido", "centro"), Objetos.nombre("bidon_acido"),
		Objetos.al_baul("bidon_acido")])

	Guardado.cambiar(func(g2):
		g2.dolares = antes.dolares
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# El texto del arma que lleva Johnny (el del cartel de la sala de mantenimiento: johnny.avisar_arma), su primera línea
func texto_del_arma() -> String:
	var texto := [""]   # (en una lista: la función de dentro no puede cambiar una variable de fuera)
	var f := func(t): texto[0] = t
	johnny.arma_cambiada.connect(f)
	johnny.avisar_arma()
	johnny.arma_cambiada.disconnect(f)
	return texto[0].get_slice("\n", 0)


# Con "--captura --tintes": el fuego y el ácido de los enemigos, pintados por su shader (zombi.gd, quemaduras;
# escenas/personajes/quemaduras.gdshaderinc; armas_creadas.gd, la herida): llamas que suben desde los pies, lenguas
# por encima y chispas; manchas de ácido con burbujas y gotas. En la sala de pruebas, cuatro zombis quietos
# (como la diana): uno sin nada, uno ardiendo, uno con el ácido del lanza ácido y uno con las dos cosas a la vez, y un
# jefe (el gymbro, quieto) con ácido. Fotos a la luz, otra un poco después (las llamas suben y las manchas han crecido)
# y a oscuras (lo que luce brilla: la copia de brillo.gd; el que arde lleva la luz naranja de sus llamas y el del
# ácido, una verde); luego el jefe con su ácido y su luz verde, que se van al acabarse, y uno que muere ardiendo
# (cae en llamas, se apagan y se vuelve carbón)
func probar_tintes() -> void:
	await pulsar_y_esperar(KEY_F11)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no le tape en las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	johnny.modo = "quieto"
	johnny.global_position = sala.diana.global_position + Vector2(0, 200)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	var z := []
	for i in 4:
		z.append(meter_zombi("normal", johnny.position + Vector2(-165 + i * 110, -90)))
	await get_tree().process_frame
	for zombi in z:
		zombi.diana = true   # quietos en su sitio y sin perder vida
		zombi.casa = zombi.position
	# lo que tiene puesto: "fuego/ácido", y si brilla a oscuras (la copia de brillo.gd, visible)
	var efecto := func(nodo: Node2D) -> String:
		var s: Node = nodo.get_node("Sprite") if nodo.has_node("Sprite") else nodo.get("sprite")
		var m: Material = s.material
		if not m is ShaderMaterial:
			return "0.00/0.00 sin brillo"
		var b: Node = s.get_node_or_null("Brillo")
		return "%.2f/%.2f %s" % [Brillo.valor(m, "fuego"), Brillo.valor(m, "acido"), "brilla" if b and b.visible else "sin brillo"]
	var luz_acido := func(nodo: Node2D) -> bool:
		return nodo.has_node("LuzAcido") and nodo.get_node("LuzAcido").visible and not nodo.get_node("LuzAcido").is_queued_for_deletion()
	# el fuego y el ácido se renuevan cada medio segundo, mientras se hacen las fotos
	var sigue := [true]
	var renovar := func() -> void:
		while sigue[0]:
			for i in [1, 3]:
				z[i].prender()
			for i in [2, 3]:
				ArmasCreadas.herir(z[i], "acido", 4)
			await get_tree().create_timer(0.5).timeout
	renovar.call()
	await get_tree().create_timer(0.7).timeout
	Captura.foto("captura-tintes-luz.png")
	print("Tintes (fuego/ácido): sin nada %s · ardiendo %s · ácido %s · las dos %s (esperado: 0.00/0.00 sin brillo, 1.00/0.00 brilla, 0.00/más de 0.5 brilla y 1.00/más de 0.5 brilla)" % [
		efecto.call(z[0]), efecto.call(z[1]), efecto.call(z[2]), efecto.call(z[3])])
	print("Tintes: luz del fuego %s · luz verde del ácido: sin nada %s, ardiendo %s, ácido %s, las dos %s (esperado: true; false, false, true y true)" % [
		z[1].llamas.luz.visible, luz_acido.call(z[0]), luz_acido.call(z[1]), luz_acido.call(z[2]), luz_acido.call(z[3])])
	await get_tree().create_timer(0.55).timeout
	Captura.foto("captura-tintes-luz-2.png")
	Luz.evento = 0.85
	await get_tree().create_timer(0.8).timeout
	Captura.foto("captura-tintes-oscuro.png")
	Luz.evento = 0.0
	sigue[0] = false
	for zombi in z:
		zombi.remove_from_group("zombis")
		zombi.queue_free()
	await get_tree().create_timer(0.8).timeout

	# un jefe con ácido: verde mientras le dura, y se le va al acabarse
	var jefe: Node2D = meter_zombi("gymbro", johnny.position + Vector2(0, -150))
	await get_tree().create_timer(0.2).timeout
	jefe.process_mode = Node.PROCESS_MODE_DISABLED   # quieto (la herida sigue: va aparte)
	ArmasCreadas.herir(jefe, "acido", 4)
	var herida: Node = jefe.get_node("herida_acido")
	herida.process_mode = Node.PROCESS_MODE_ALWAYS
	var vida0: int = jefe.vida
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-tintes-jefe.png")
	var con: String = efecto.call(jefe)
	var con_luz: bool = luz_acido.call(jefe)
	await get_tree().create_timer(3.0).timeout
	print("Tintes: el jefe con ácido %s y luz verde %s; al acabarse %s y luz verde %s (esperado: 0.00/más de 0.3 brilla, true, 0.00/0.00 sin brillo y false) · pierde %d (esperado: más de 0) · herida acabada %s (esperado: true)" % [
		con, con_luz, efecto.call(jefe), luz_acido.call(jefe), vida0 - jefe.vida, not is_instance_valid(herida)])
	jefe.remove_from_group("zombis")
	jefe.queue_free()
	await get_tree().create_timer(0.3).timeout

	# uno que muere ardiendo: cae teñido de fuego y se vuelve carbón
	var quemado: Node2D = meter_zombi("normal", johnny.position + Vector2(0, -110))
	await get_tree().process_frame
	quemado.aturdido = 30.0
	quemado.vida = 3
	quemado.prender(4.0)
	await get_tree().create_timer(0.55).timeout
	Captura.foto("captura-tintes-cae.png")
	await get_tree().create_timer(1.6).timeout
	Captura.foto("captura-tintes-carbon.png")
	print("Tintes: el quemado, muerto %s · fuego/ácido mientras ennegrece %s (esperado: true y el fuego entre 0 y 0.6: se va apagando)" % [
		quemado.estado == "muerto", efecto.call(quemado)])
	get_tree().quit()


# Con "--captura --charcos": los charcos que burbujean (charco.gd: veneno, ácido y vómito) junto a uno de fuego, para
# compararlos. En la sala de pruebas, en fila delante de Johnny: fotos al caer (se extienden), con sus
# burbujas, cuando empiezan a secarse a trozos y con la mancha que dejan. Cuenta si se pisan y se cierra
func probar_charcos() -> void:
	await pulsar_y_esperar(KEY_F11)
	await get_tree().create_timer(0.3).timeout
	for a in get_tree().get_nodes_in_group("aliados"):
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	johnny.modo = "quieto"
	johnny.direccion = "n"
	var charcos := {}
	for i in 4:
		var tipo: String = ["veneno", "acido", "vomito", "fuego"][i]
		var charco: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
		charco.tipo = tipo
		charco.position = johnny.position + Vector2(-100 + i * 140, -110)
		johnny.get_parent().add_child(charco)
		charcos[tipo] = charco
	var lejia: Node2D = load("res://escenas/armas/charco.tscn").instantiate()   # la lejía, en otra fila, más arriba
	lejia.tipo = "lejia"
	lejia.position = johnny.position + Vector2(-30, -250)
	johnny.get_parent().add_child(lejia)
	await get_tree().create_timer(0.1).timeout
	Captura.foto("captura-charcos-caen.png")
	await get_tree().create_timer(0.8).timeout
	Captura.foto("captura-charcos.png")
	await get_tree().create_timer(0.35).timeout
	Captura.foto("captura-charcos-2.png")
	var centro: bool = charcos.veneno.arde_en(charcos.veneno.global_position, 0.0)
	var fuera: bool = charcos.veneno.arde_en(charcos.veneno.global_position + Vector2(200, 0), 0.0)
	await get_tree().create_timer(2.25).timeout
	Captura.foto("captura-charcos-secan.png")
	var borde: bool = charcos.veneno.arde_en(charcos.veneno.global_position + Vector2(56, 0), 0.0)
	Luz.evento = 0.85
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-charcos-oscuro.png")
	Luz.evento = 0.0
	await get_tree().create_timer(3.0).timeout
	Captura.foto("captura-charcos-mancha.png")
	# los mocos en el aire (proyectil.gd): miran hacia donde van, hacia arriba al salir y de cabeza al caer. Tres a la
	# vez, a la derecha, a la izquierda y hacia arriba; fotos al salir, en lo alto y al caer
	# (y dos garrafas de lejía, que van dando vueltas)
	for hacia in [Vector2(260, -40), Vector2(-260, -40), Vector2(30, -260), Vector2(160, -200), Vector2(-160, -200)]:
		var moco: Node2D = load("res://escenas/armas/proyectil.tscn").instantiate()
		moco.tipo = "lejia" if absf(hacia.x) == 160.0 else "veneno"
		moco.desde = johnny.global_position + Vector2(0, -60)
		moco.alto_salida = 30.0
		moco.hasta = moco.desde + hacia
		johnny.get_parent().add_child(moco)
	for i in 3:
		await get_tree().create_timer(0.22).timeout
		Captura.foto("captura-charcos-moco-%d.png" % (i + 1))
	print("Charcos: el veneno se pisa en el centro %s, lejos %s, en el borde al secarse %s · quedan %d (esperado: true, false, false y 0)" % [
		centro, fuera, borde, get_tree().get_nodes_in_group("charcos").size()])
	get_tree().quit()


# Con "--captura --fuego-acido": lo que hacen el fuego y el ácido, además de quitar vida un rato. En la sala de pruebas
# de armas:
#   1) El fuego se contagia (zombi.gd, contagiar): cuatro zombis en fila, pegados, y uno apartado, quietos y sin perder
#      vida (como la diana). Se prende el primero y el fuego pasa de uno a otro cada medio segundo, con la fuerza del
#      primero, hasta el último; el apartado no se prende. Como al apagarse se quedan chamuscados, cada uno arde una vez
#      y el fuego se acaba (no va y vuelve entre dos pegados sin fin). Foto con el fuego a mitad de la fila
#      (captura-fuego-acido-contagio.png).
#   2) El ácido les come la armadura (ArmasCreadas.con_acido): a un zombi, el mismo golpe y el mismo daño sin golpe le
#      quitan un 50 % más con la herida de ácido que sin ella, y al acabarse la herida, lo de siempre; igual con el ácido
#      de un charco de vómito, y al salir de él, lo de siempre. A un jefe (el cocinero, quieto), igual, con una foto de
#      su número (captura-fuego-acido-jefe.png).
# Cada línea dice lo esperado. Se cierra sola
func probar_fuego_acido() -> void:
	await pulsar_y_esperar(KEY_F11)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no le tape en las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	johnny.modo = "quieto"
	johnny.global_position = sala.diana.global_position + Vector2(0, 200)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()

	# 1) el contagio: la fila, pegados (entre los bordes, 14: lo que se apartan solos en una horda apretada, y menos de lo
	# que hace falta para contagiarse), y el apartado
	var todos := []
	for i in 5:
		todos.append(meter_zombi("normal", johnny.position + Vector2(-150 + i * 60, -90)))
	await get_tree().process_frame
	var paso: float = todos[0].radio * 2.0 + 14.0
	for i in 5:
		var z: Node2D = todos[i]
		z.position = johnny.position + Vector2(-130 + (i * paso if i < 4 else 3 * paso + 150), -90)
		z.diana = true   # quietos en su sitio y sin perder vida
		z.casa = z.position
	await get_tree().process_frame
	var primera := [-1.0, -1.0, -1.0, -1.0, -1.0]   # cuándo se prende cada uno
	var veces := [0, 0, 0, 0, 0]                    # cuántas veces se prende
	var ardia := [false, false, false, false, false]
	todos[0].prender(2.0)
	var t := 0.0
	var foto := false
	while t < 6.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		for i in 5:
			var arde: bool = todos[i].arder_t > 0.0
			if arde and not ardia[i]:
				veces[i] += 1
				if primera[i] < 0.0:
					primera[i] = t
			ardia[i] = arde
		if not foto and t >= 1.25:
			foto = true
			Captura.foto("captura-fuego-acido-contagio.png")
	var cuando := []
	for s in primera:
		cuando.append("%.2f" % s)
	print("Fuego, contagio: se prenden a los %s s (esperado: 0, 0.5, 1, 1.5 más o menos y -1: el apartado, nunca) · veces %s (esperado: [1, 1, 1, 1, 0]) · el último arde con fuerza %.1f (esperado: 2.0) · a los 6 s arde alguno %s (esperado: false)" % [
		", ".join(cuando), veces, todos[3].arder_dano, todos.any(func(z): return z.arder_t > 0.0)])
	for z in todos:
		z.remove_from_group("zombis")
		z.queue_free()
	await get_tree().create_timer(0.3).timeout

	# 2) el ácido: lo que quitan un golpe de 10 y 10 sin golpe ("golpe/sin golpe"), según lo que lleve
	var zh: Node2D = meter_zombi("normal", johnny.position + Vector2(-90, -90))
	var c: Node2D = meter_zombi("normal", johnny.position + Vector2(90, -90))
	await get_tree().process_frame
	var ultimo := {}
	for zz in [zh, c]:
		zz.diana = true
		zz.casa = zz.position
		zz.herido.connect(func(n: int, _golpe: bool): ultimo[zz] = n)
	var quita := func(zz: Node2D) -> String:
		zz.recibir_golpe(10, Vector2.ZERO)
		var a: int = ultimo[zz]
		zz.herir(10.0)
		return "%d/%d" % [a, ultimo[zz]]
	var sin: String = quita.call(zh)
	ArmasCreadas.herir(zh, "acido", 4)
	var con: String = quita.call(zh)
	await get_tree().create_timer(3.4).timeout
	print("Ácido, herida: sin ácido %s · con la herida %s · al acabarse (herida %s) %s (esperado: 10/10, 15/15, false y 10/10)" % [
		sin, con, zh.has_node("herida_acido"), quita.call(zh)])
	var charco: Node2D = load("res://escenas/armas/charco.tscn").instantiate()
	charco.tipo = "vomito"
	charco.position = johnny.get_parent().to_local(c.global_position)
	johnny.get_parent().add_child(charco)
	await get_tree().create_timer(0.4).timeout
	var en_charco: String = quita.call(c)
	var pisa: bool = c.estados.has("acido")
	c.position += Vector2(110, 0)
	c.casa = c.position
	await get_tree().create_timer(0.3).timeout
	print("Ácido, charco de vómito: dentro (ácido %s) %s · fuera (ácido %s) %s (esperado: true, 15/15, false y 10/10)" % [
		pisa, en_charco, c.estados.has("acido"), quita.call(c)])
	charco.queue_free()
	for zz in [zh, c]:
		zz.remove_from_group("zombis")
		zz.queue_free()
	await get_tree().create_timer(0.3).timeout

	# a un jefe (el cocinero, quieto: la herida sigue, va aparte), lo que le quita un golpe de 20
	var jefe: Node2D = meter_zombi("cocinero", johnny.position + Vector2(0, -150))
	await get_tree().create_timer(0.2).timeout
	jefe.process_mode = Node.PROCESS_MODE_DISABLED
	jefe.invulnerable = false
	var v0: int = jefe.vida
	jefe.recibir_golpe(20, Vector2.ZERO)
	var jefe_sin: int = v0 - jefe.vida
	ArmasCreadas.herir(jefe, "acido", 4)
	jefe.get_node("herida_acido").process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().create_timer(0.6).timeout
	v0 = jefe.vida
	jefe.recibir_golpe(20, Vector2.ZERO)
	var jefe_con: int = v0 - jefe.vida
	await get_tree().create_timer(0.15).timeout
	Captura.foto("captura-fuego-acido-jefe.png")
	print("Ácido, jefe: un golpe de 20 le quita %d sin ácido y %d con él (esperado: 20 y 30)" % [jefe_sin, jefe_con])
	get_tree().quit()


# Con "--captura --pistola-electrica": la pistola eléctrica con su dibujo propio (Armas.DATOS.pistola_electrica,
# conserje-48-pistola-electrica: la hoja lleva el retroceso corto de pistola y una descarga celeste en zigzag que sale de los dos
# electrodos del táser azul marino; casilla de 180x168, con los pies en 90,88). Como el lanza ácido, en la sala de mantenimiento,
# Johnny la compra en la tienda de armas del ordenador (captura-pistola-electrica-tienda.png, con ella marcada) y cuenta su hoja, su
# ritmo, su alcance, sus pies, su boca hacia el este y que ya no le salen chispitas de adorno; dispara a un zombi a 120 a su
# izquierda (le quita vida y lo aturde), con otro cerca de él (la descarga salta y lo aturde también) y otro a 330 (más lejos de lo
# que llega la chispa: ni se entera), con una foto con las chispas saliendo (captura-pistola-electrica-chispa.png) y cuenta cuántas
# balas gasta (una por disparo). Las baterías: con el cargador vacío, una de la mochila lo llena entero; sin ellas, no recarga; y
# las cajas de munición no le valen. Luego
# dispara andando (sigue andando, con los efectos del disparo pintados encima y el retroceso) y en las 8 direcciones, con una foto de
# cada una a los 0,09 s, con la descarga ya saliendo (captura-pistola-electrica-<dirección>.png): lo dibujado y las chispas del
# juego tienen que salir del mismo sitio. Con cada skin (portero, glotón, gymbro y bombero), su hoja y una foto
# (captura-pistola-electrica-<skin>.png). Cada línea dice lo esperado. Deja el guardado como estaba y se cierra
func probar_pistola_electrica() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g2):
		g2.skins = ["portero", "gloton", "gymbro", "bombero"]
		g2.skin = "")
	johnny.vestir("")
	await comprar_en_tienda("pistola_electrica", "captura-pistola-electrica-tienda.png")

	# comprada: su hoja, su boca y sin chispitas de adorno
	var id := "pistola_electrica"
	var w := Armas.datos(id)
	johnny.position = Vector2(690, 300)   # (en el despacho)
	johnny.direccion = "e"
	johnny.espera = 1000.0                # que no dispare por su cuenta: aquí dispara la prueba
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.3).timeout
	print("Pistola eléctrica en la mano: hoja «%s» · ritmo %.0f · alcance %.0f · pies %s · boca este %s · chispitas de adorno %s · icono «%s» (esperado: conserje-48-pistola-electrica.tres, 5, 230, (90, 88), (22, -30), false, pistola_electrica)" % [
		johnny.sprite.sprite_frames.resource_path.get_file(), w.ritmo, w.alcance, w.pies, w.boca.e, w.has("detalle"), Objetos.icono(id)])

	# la chispa: sale de la boca hacia la izquierda, le quita vida al primero (a 120) y lo aturde, salta al que tiene cerca (a 100
	# de él: también pierde vida y se queda aturdido) y no llega al tercero, a 330 (230 desde la boca, que está a 44 de Johnny)
	johnny.direccion = "o"
	var z := zombis_de_prueba([Vector2(-120, 0), Vector2(-200, 60), Vector2(-330, 0)])
	await get_tree().process_frame
	var balas0: int = johnny.balas
	johnny.atacar(PI)
	await get_tree().create_timer(0.12).timeout
	Captura.foto("captura-pistola-electrica-chispa.png")
	await get_tree().create_timer(0.15).timeout
	print("Aturdidos a los 0,27 s: el de 120 %s · el que está a su lado %s · el de 330 %s (esperado: true, true, false)" % [
		z[0].aturdido > 0.0, z[1].aturdido > 0.0, z[2].aturdido > 0.0])
	await get_tree().create_timer(0.4).timeout
	print("Zombi a 120: vida %d · el de al lado: vida %d (esperado: menos de 500 los dos) · a 330: vida %d (esperado: 500)" % [z[0].vida, z[1].vida, z[2].vida])
	print("Balas gastadas: %d (esperado: 1)" % (balas0 - johnny.balas))
	zombis_de_prueba([])
	await get_tree().create_timer(0.3).timeout

	# las baterías: con el cargador vacío y una batería en la mochila, la recarga la gasta y lo llena entero; sin
	# baterías no recarga; y las cajas de munición no le valen
	while "bateria" in mochila:
		mochila.erase("bateria")
	mochila.append("bateria")
	johnny.balas = 0
	johnny.empezar_recarga()
	await get_tree().create_timer(w.recarga + 0.2).timeout
	print("Recarga con una batería: cargador %d de %d · baterías %d · gasta «%s» · la caja es para «%s» (esperado: 30 de 30, 0, Batería, pistola: la de repuesto, a la eléctrica no le vale)" % [
		johnny.balas, w.cargador, mochila.count("bateria"), Armas.MUNICION[Armas.municion(id)].nombre, johnny.arma_de_caja()])
	johnny.balas = 0
	johnny.empezar_recarga()
	print("Sin baterías: recargando %s · el aviso «%s» (esperado: false, ¡Sin batería!)" % [johnny.recargando > 0.0,
		Armas.MUNICION[Armas.municion(id)].sin])
	johnny.balas = w.cargador

	# disparar andando: sigue andando (sin el gesto entero), con los efectos del disparo pintados encima y el retroceso
	johnny.direccion = "e"
	johnny.velocity = Vector2(120, 0)
	johnny.atacar(0.0)
	await get_tree().create_timer(0.07).timeout
	Captura.foto("captura-pistola-electrica-andando.png")
	print("Disparado andando: ataque_t %.1f (esperado: -1.0) · efectos visibles %s (esperado: true) · retroceso %s (esperado: distinto de (0, 0))" % [
		johnny.ataque_t, johnny.efectos.visible, johnny.patada])
	johnny.velocity = Vector2.ZERO
	await get_tree().create_timer(0.5).timeout

	# las 8 direcciones, con una foto a los 0,09 s: la descarga dibujada y las chispas del juego saliendo
	for d in johnny.DIRS:
		johnny.direccion = d
		johnny.atacar(johnny.DIRS.find(d) * PI / 4)
		await get_tree().create_timer(0.09).timeout
		Captura.foto("captura-pistola-electrica-%s.png" % d)
		await get_tree().create_timer(0.6).timeout

	# con cada skin: su hoja de la pistola eléctrica
	for skin in ["portero", "gloton", "gymbro", "bombero"]:
		Skins.poner(skin)
		johnny.vestir(skin)
		johnny.direccion = "e"
		johnny.atacar(0.0)
		await get_tree().create_timer(0.09).timeout
		Captura.foto("captura-pistola-electrica-%s.png" % skin)
		print("Con %s: hoja «%s» (esperado: conserje-48-pistola-electrica-%s.tres)" % [skin, johnny.sprite.sprite_frames.resource_path.get_file(), skin])
		await get_tree().create_timer(0.6).timeout

	Guardado.cambiar(func(g2):
		g2.dolares = antes.dolares
		g2.skins = antes.skins
		g2.skin = antes.skin)
	get_tree().quit()


# Para probar_pistola_electrica: quita los zombis y los charcos que haya, cura a Johnny y saca zombis lentos de 500 de
# vida en esos sitios (respecto a Johnny)
func zombis_de_prueba(donde: Array) -> Array:
	for o in get_tree().get_nodes_in_group("zombis") + get_tree().get_nodes_in_group("charcos"):
		o.remove_from_group("zombis")
		o.queue_free()
	johnny.vida = johnny.stats.vida_max
	var lista := []
	for d in donde:
		var zombi := meter_zombi("lento", johnny.position + d)
		zombi.vida = 500
		lista.append(zombi)
	return lista


# Con "--captura --epicas": el truco de la Épica de cada familia (Armas.TRUCO; parte 6 de la tienda y las piezas), en la
# sala de pruebas, con zombis lentos de 500 de vida. Cada línea dice lo esperado. Cuenta: lo que dice la ficha
# de cada Épica; el golpe de gracia (el bate Épico: el 4.º golpe que da hace el doble; captura-epica-gracia.png); las
# balas que atraviesan (la pistola Épica da a los dos zombis en fila, la Normal solo al primero;
# captura-epica-balas.png, con la estela morada); el estallido (el zombi que mata un golpe Épico de fuego, ácido o
# chispa pasa su efecto a uno de al lado y no a uno lejos; sin ser Épico, a nadie; captura-epica-estallido.png) y el
# racimo (lanzados a 180 por encima de Johnny, la granada Épica suelta 2 granaditas y el molotov Épico 2 charcos más
# pequeños; captura-epica-racimo.png y
# captura-epica-molotov.png). Se cierra
func probar_epicas() -> void:
	await pulsar_y_esperar(KEY_F11)
	var sala: SalaArmas = null
	for n in mapa.get_children():
		if n is SalaArmas:
			sala = n
	await get_tree().create_timer(0.3).timeout
	for a in get_tree().get_nodes_in_group("aliados"):   # (que el que le acompaña no le tape en las fotos)
		a.process_mode = Node.PROCESS_MODE_DISABLED
		a.visible = false
	johnny.modo = "quieto"
	johnny.global_position = sala.diana.global_position + Vector2(0, 200)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	johnny.stats.critico = 0.0   # (sin críticos al azar: solo los del truco)
	sala.diana.visible = false
	sala.diana.remove_from_group("zombis")
	print("Fichas de la Épica: «%s» · «%s» · «%s» · «%s»" % [Armas.que_da("bate", 3), Armas.que_da("pistola", 3),
		Armas.que_da("pistola_electrica", 3), Armas.que_da("molotov", 3)])
	print("Precios: un arma %s, un arrojable %s (esperado: [0, 3, 6, 10], [0, 1, 2, 4])" % [
		range(4).map(func(c): return Armas.coste("bate", c)), range(4).map(func(c): return Armas.coste("granada", c))])

	# 1) el golpe de gracia: 4 golpes con el bate Épico al mismo zombi
	llevar_arma("bate", 3)
	johnny.gracia = 0
	var z: Array = zombis_de_prueba([Vector2(0, -50)])
	var quita := []
	for i in 4:
		z[0].position = johnny.position + Vector2(0, -50)
		await get_tree().create_timer(0.25).timeout
		var antes: int = z[0].vida
		johnny.golpear(-PI / 2)
		quita.append(antes - z[0].vida)
		if i == 3:
			await get_tree().create_timer(0.1).timeout
			Captura.foto("captura-epica-gracia.png")
	print("Golpe de gracia: quita %s (esperado: tres iguales y el 4.º el doble: %d, %d, %d, %d)" % [quita,
		roundi(johnny.arma().dano), roundi(johnny.arma().dano), roundi(johnny.arma().dano), roundi(johnny.arma().dano) * 2])

	# 2) las balas que atraviesan: dos zombis quietos en fila, el segundo justo detrás del primero según va la bala (que
	# sale de la boca, a un lado de Johnny); la pistola Épica y luego la Normal. Lo que les quita, por su señal "herido"
	var vidas := []
	for calidad in [3, 0]:
		llevar_arma("pistola", calidad)
		z = zombis_de_prueba([Vector2(0, -110), Vector2(0, -110)])
		var salida: Vector2 = johnny.tiro(-PI / 2, johnny.arma(), johnny.direccion)[0]
		z[1].position = z[0].position + (z[0].position - salida).normalized() * 80.0
		var quitado := [0, 0]
		for i in 2:
			z[i].diana = true   # (quietos en su sitio)
			z[i].casa = z[i].position
			z[i].herido.connect(func(cantidad, _golpe): quitado[i] += cantidad)
		await get_tree().create_timer(0.1).timeout
		johnny.disparar(-PI / 2)
		if calidad == 3:
			await get_tree().create_timer(0.09).timeout
			Captura.foto("captura-epica-balas.png")
		await get_tree().create_timer(0.5).timeout
		vidas.append(quitado)
	print("Balas: la Épica quita %s, la Normal %s (esperado: a los dos · solo al primero, el segundo 0)" % [vidas[0], vidas[1]])

	# 3) el estallido: el de en medio muere de un golpe Épico; el de al lado lo pilla, el lejano no
	for tipo in ["llama", "acido", "chispa", "sin"]:
		z = zombis_de_prueba([Vector2(0, -120), Vector2(55, -120), Vector2(-260, -120)])
		z[0].vida = 1
		await get_tree().create_timer(0.1).timeout
		ArmasCreadas.golpe(z[0], Vector2(0, -1), 10.0, 0.5, "llama" if tipo == "sin" else tipo, 1.0, 0, tipo != "sin")
		var pilla := func(o: Node2D) -> bool:
			return o.arder_t > 0.0 or o.has_node("herida_acido") or o.aturdido > 0.0
		print("Estallido de %s: muere %s · el de al lado %s · el lejano %s (esperado: true · %s · false)" % [
			tipo, z[0].estado == "muerto", pilla.call(z[1]), pilla.call(z[2]), tipo != "sin"])
		if tipo == "llama":
			await get_tree().create_timer(0.12).timeout
			Captura.foto("captura-epica-estallido.png")
	llevar_arma("lanzallamas", 3)
	johnny.llamarada.mantener(johnny.global_position, -PI / 2, johnny.arma())
	print("La llamarada del lanzallamas Épico: Épica %s (esperado: true)" % johnny.llamarada.epica)

	# 4) el racimo: la granada Épica y el molotov Épico, lanzados a 180 por encima de Johnny
	zombis_de_prueba([])
	var cuantas := func(hijas: bool) -> int:
		return johnny.get_parent().get_children().filter(func(n):
			return n.get_script() == Lanzables.BOMBA and n.hija == hijas).size()
	lanzables.meter("granada:3", 2)
	lanzables.tipo = "granada:3"
	lanzables.lanzar(johnny.position + Vector2(0, -180))
	await get_tree().create_timer(Lanzables.GRANADA.mecha + 0.15).timeout
	print("Racimo de la granada: granaditas %d, la grande %d (esperado: %d, 0)" % [cuantas.call(true), cuantas.call(false),
		Armas.TRUCO.racimo])
	await get_tree().create_timer(0.75).timeout
	Captura.foto("captura-epica-racimo.png")
	await get_tree().create_timer(0.4).timeout
	print("Las granaditas, ya: %d (esperado: 0)" % cuantas.call(true))
	for c in get_tree().get_nodes_in_group("charcos"):
		c.queue_free()
	await get_tree().process_frame
	lanzables.meter("molotov:3", 2)
	lanzables.tipo = "molotov:3"
	lanzables.lanzar(johnny.position + Vector2(0, -180))
	await get_tree().create_timer(1.4).timeout
	var charcos: Array = get_tree().get_nodes_in_group("charcos").map(func(c): return snappedf(c.escala, 0.01))
	print("Racimo del molotov: charcos de tamaño %s (esperado: uno de %.2f y %d de %.2f)" % [charcos,
		Armas.CALIDADES[3].radio, Armas.TRUCO.racimo, Armas.CALIDADES[3].radio * Armas.TRUCO.racimo_tamano])
	Captura.foto("captura-epica-molotov.png")
	get_tree().quit()


# Con "--captura --sala-pruebas": la sala de pruebas con su panel (sala_armas.gd y ui/panel_pruebas.gd). Desde la sala
# de mantenimiento, F11 lleva a ella: cuenta en la terminal que hay baúl y que el baúl que se ve es el de pruebas (todas
# las armas y los arrojables en cada calidad). La P abre el panel; con sus botones, Johnny invencible y, con «Quieto», el
# antidisturbios: que ha salido y que, tras 3 s, sigue en su sitio. Luego apaga los avisos de los jefes y el alcance
# del arma, y los vuelve a encender; y con los atajos (2 y Mayús + 7), un zombi lento y el Glotón
# (captura-sala-pruebas-atajos.png). Al final, F11 vuelve al mismo sitio de la sala de mantenimiento, con el baúl de
# verdad sin tocar. Fotos: captura-sala-pruebas-panel.png (el panel, en Jefes), captura-sala-pruebas-jefe.png (el
# antidisturbios quieto, con sus avisos) y captura-sala-pruebas-sin-ayudas.png (lo mismo, sin avisos ni alcance)
func probar_sala_pruebas() -> void:
	var real: int = Guardado.cargar().baul_equipo.size()
	johnny.position += Vector2(60, -40)
	var desde: Vector2 = johnny.position
	var de: int = aqui
	await pulsar_y_esperar(KEY_F11)
	await get_tree().create_timer(0.3).timeout
	var esperado := (Armas.DATOS.size() + Lanzables.DATOS.size()) * Armas.CALIDADES.size()
	print("Sala de pruebas: en «%s» (esperado: armas) · baúl %s (esperado: true) · en el baúl %d cosas (esperado: %d)" % [
		planta.sitios[aqui].tipo, mapa.baul != null, Guardado.cargar().baul_equipo.size(), esperado])
	await pulsar_y_esperar(KEY_P)
	await get_tree().create_timer(0.3).timeout
	print("Panel de pruebas: abierto %s, juego parado %s (esperado: true, true)" % [panel_pruebas.abierto(), get_tree().paused])
	Captura.foto("captura-sala-pruebas-panel.png")
	panel_pruebas.elegir("Johnny")
	pulsar_en_panel("Invencible")
	panel_pruebas.elegir("Jefes")
	if not PANEL_PRUEBAS.quieto:
		pulsar_en_panel("Quieto")
	pulsar_en_panel("Antidisturbios")
	await get_tree().create_timer(0.2).timeout
	var jefe: Node2D = null
	for z in get_tree().get_nodes_in_group("zombis"):
		if z.scene_file_path.get_file() == "antidisturbios.tscn":
			jefe = z
	var sitio_jefe: Vector2 = jefe.global_position if jefe else Vector2.ZERO
	await get_tree().create_timer(3.0).timeout
	print("Jefe del panel: ha salido %s, el panel se ha cerrado %s · quieto: se ha movido %d (esperado: true, true, 0) · Johnny invencible, vida %d de %d" % [
		jefe != null, not panel_pruebas.abierto(), roundi(jefe.global_position.distance_to(sitio_jefe)) if jefe else -1,
		johnny.vida, johnny.stats.vida_max])
	Captura.foto("captura-sala-pruebas-jefe.png")
	abrir_panel_pruebas()
	panel_pruebas.elegir("Ayudas")
	pulsar_en_panel("Avisos de los jefes")
	pulsar_en_panel("Alcance del arma")
	print("Ayudas apagadas: avisos %s, alcance %s (esperado: true, false)" % [Aviso.apagados, SalaArmas.ayudas.alcance])
	panel_pruebas.cerrar()
	await get_tree().create_timer(1.0).timeout
	Captura.foto("captura-sala-pruebas-sin-ayudas.png")
	abrir_panel_pruebas()
	panel_pruebas.elegir("Ayudas")
	pulsar_en_panel("Avisos de los jefes")
	pulsar_en_panel("Alcance del arma")
	print("Ayudas encendidas: avisos %s, alcance %s (esperado: false, true)" % [Aviso.apagados, SalaArmas.ayudas.alcance])
	panel_pruebas.cerrar()
	# los atajos, con el panel cerrado: el 2, un zombi lento; Mayús + 7, el Glotón
	var antes := get_tree().get_nodes_in_group("zombis").size()
	for tecla in [[KEY_2, false], [KEY_7, true]]:
		var evento := InputEventKey.new()
		evento.keycode = tecla[0]
		evento.shift_pressed = tecla[1]
		evento.pressed = true
		Input.parse_input_event(evento)
		await get_tree().physics_frame
		evento = evento.duplicate()
		evento.pressed = false
		Input.parse_input_event(evento)
		await get_tree().create_timer(0.2).timeout
	var nuevos := get_tree().get_nodes_in_group("zombis").map(func(z): return z.scene_file_path.get_file().get_basename())
	print("Atajos (2 y Mayús + 7): %d nuevos, lento %s, Glotón %s (esperado: %d, true, true)" % [nuevos.size() - antes,
		"zombi_lento" in nuevos, "gloton" in nuevos, 1 + PANEL_PRUEBAS.cuantos])
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-sala-pruebas-atajos.png")
	await pulsar_y_esperar(KEY_F11)
	await get_tree().create_timer(0.3).timeout
	print("De vuelta: al mismo sitio %s, al mismo punto %s · el baúl de verdad, %d cosas (esperado: true, true, %d)" % [
		aqui == de, johnny.position.distance_to(desde) < 2.0, Guardado.cargar().baul_equipo.size(), real])
	get_tree().quit()


# Pulsa el botón del panel de pruebas que empieza por "texto"
func pulsar_en_panel(texto: String) -> void:
	for b in panel_pruebas.hoja.get_children():
		if b.text.begins_with(texto) or b.text.ends_with("· " + texto):
			b.pressed.emit()
			return
	print("ERROR: en el panel no está el botón «%s»" % texto)
