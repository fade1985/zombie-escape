# Pruebas del inventario y del baúl (--inventario, --arrastrar, --baul, --repuesto, --tienda, --municion,
# --municion-suelo), de los objetos de curar (--curas), de las piezas de mejora (--piezas), de las calidades (--calidades) y del
# banco que las sube (--banco-mejorar). Parte de la cadena de la partida de prueba (ver partida_prueba.gd).
extends "res://scripts/pruebas/prueba_skins.gd"

var en_el_aire := {}         # arrastrar: lo que se veía justo antes de soltar


# Le da a Johnny tres atraedoras o congeladoras (lanzables.gd): a mano si hay sitio y si no, de repuesto
func dar_lanzable(k: String) -> void:
	lanzables.cantidades[k] = 3
	lanzables.colocar(k)


# Con "--captura --baul": la pantalla del baúl (ui/inventario.gd). En la sala de
# mantenimiento, con dos piezas especiales en el baúl y en la mochila gasolina, una pieza especial, vendas, una pieza
# cuerpo a cuerpo y tres a distancia, Johnny
# se arrima al baúl y cuenta en la terminal: que se abre con la marca en lo primero que se puede guardar, que guardar
# una casilla mete todos los de esa casilla (y la marca se queda en la siguiente), que las vendas también se guardan
# (y se vuelven a poner), que la gasolina se guarda desde la munición y se saca de una en una (la marca se queda en
# «Sacar uno»), que las balas y los cartuchos también se guardan (el hueco entero, y también arrastrando) y salen
# hasta un hueco de una vez, o lo que quepa (captura-baul-municion.png), y que «Guardar todo» lo mete todo, la
# munición también. Que «Destruir» pide confirmación (la primera pulsación lo deja a medias, elegir otra casilla o esperar
# 3 s lo cancela) y la segunda quita para siempre la casilla entera: un objeto, un hueco de munición, un arma y un
# paquete de arrojables del baúl, y un objeto de la mochila; las armas que lleva no tienen botón
# (captura-baul-destruir.png). Que al sacar un arma que ya lleva (la fregona Épica, con la Normal de repuesto, y la
# pistola Rara, con la Normal en la mano) se cambian y la suya entra en el baúl, sin dejar nada en el suelo. Y el baúl
# lleno: con 31 armas y una pieza (cada arma, en su casilla) no deja guardar otra arma, y con más de 32 (al completar el
# edificio entra todo) las casillas se hacen más pequeñas. Cada línea dice lo esperado. Saca captura-baul-guardar.png
# (la gasolina elegida, para guardarla), captura-baul-cambio.png (tras sacar la pistola Rara) y captura-baul-lleno.png,
# deja el baúl como estaba y se cierra
func probar_baul() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g2):
		g2.baul = {"pieza_especial": 2}
		g2.baul_equipo = [])
	mochila.clear()
	mochila.append_array(["gasolina", "gasolina", "pieza_especial", "vendas", "pieza_cuerpo", "pieza_distancia", "pieza_distancia", "pieza_distancia"])
	var marca := func() -> String:   # el botón o la casilla marcada (la del mando y las flechas)
		var f := get_viewport().gui_get_focus_owner()
		return String(f.name) if f else "-"
	var dice := func() -> String:    # el texto de la ficha
		var t: Label = inventario.fondo.find_child("nota", true, false)
		return t.text if t else "-"
	var boton := func(nombre: String) -> String:
		var b: Button = inventario.fondo.find_child(nombre, true, false)
		return "no está" if b == null else ("apagado" if b.disabled else "activo")
	var en_baul := func(id: String) -> String:   # la casilla de un objeto en el baúl ("b1")
		return "b%d" % inventario.objetos_baul(Guardado.cargar()).map(func(o): return o[0]).find(id)
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	var abierto: bool = inventario.abierto == "baul"
	print("Baúl: abierto al arrimarse %s · juego en pausa %s (esperado: true, true)" % [abierto, get_tree().paused])
	if not abierto:
		get_tree().quit()
		return
	# las casillas de la mochila: m0 pieza especial, m1 vendas, m2 pieza cuerpo a cuerpo, m3 pieza a distancia × 3 (la gasolina va con la munición)
	print("Al abrir: la marca en «%s» (esperado: m0, la pieza especial: lo primero que se puede guardar) · «Guardar todo» %s (esperado: activo) · dice «%s»" % [
		marca.call(), boton.call("guardar_todo"), dice.call()])
	inventario.tocar("m0")
	await get_tree().process_frame
	print("Elegida la pieza especial: «Guardar en el baúl» %s, la marca en «%s» (esperado: activo, guardar) · dice «%s»" % [
		boton.call("guardar"), marca.call(), dice.call()])
	inventario.guardar()
	await get_tree().process_frame
	var g := Guardado.cargar()
	print("Guardada la pieza especial: en el baúl %d, en la mochila %d (esperado: 3, 0) · la marca en «%s», en la casilla de %s (esperado: m0, Vendas: la siguiente)" % [
		g.baul.get("pieza_especial", 0), mochila.count("pieza_especial"), marca.call(), Objetos.nombre(Objetos.casillas(mochila)[0][0])])
	# ahora: m0 vendas, m1 pieza cuerpo a cuerpo, m2 pieza a distancia × 3
	inventario.tocar("m0")
	await get_tree().process_frame
	print("Elegidas las vendas: «Guardar en el baúl» %s (esperado: activo) · dice «%s»" % [boton.call("guardar"), dice.call()])
	inventario.guardar()
	await get_tree().process_frame
	print("Guardadas las vendas: en la mochila %d, en el baúl %d (esperado: 0, 1)" % [mochila.count("vendas"),
		Guardado.cargar().baul.get("vendas", 0)])
	# se vuelven a poner donde estaban (m0), para seguir con lo de siempre
	mochila.insert(0, "vendas")
	Guardado.cambiar(func(g2): g2.baul.erase("vendas"))
	inventario.pintar()
	# la gasolina, desde su hueco de munición, y luego sacarla otra vez, de una en una
	inventario.tocar("u%d" % johnny.huecos_municion().map(func(h): return h[0]).find("gasolina"))
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-guardar.png")
	print("Elegida la gasolina de la munición: «Guardar en el baúl» %s, la marca en «%s» (esperado: activo, guardar) · dice «%s»" % [
		boton.call("guardar"), marca.call(), dice.call()])
	inventario.guardar()
	await get_tree().process_frame
	print("Guardada la gasolina: en el baúl %d, en la mochila %d (esperado: 2, 0)" % [Guardado.cargar().baul.get("gasolina", 0),
		mochila.count("gasolina")])
	inventario.tocar(en_baul.call("gasolina"))
	await get_tree().process_frame
	print("Elegida la gasolina del baúl: «Sacar uno» %s, la marca en «%s» (esperado: activo, sacar) · dice «%s»" % [
		boton.call("sacar"), marca.call(), dice.call()])
	inventario.sacar()
	await get_tree().process_frame
	print("Sacada una: en el baúl %d, en la mochila %d · la marca en «%s» (esperado: 1, 1, sacar: se puede sacar otra)" % [
		Guardado.cargar().baul.get("gasolina", 0), mochila.count("gasolina"), marca.call()])
	inventario.sacar()
	await get_tree().process_frame
	print("Sacada otra: en el baúl %d, en la mochila %d · la marca en «%s» (esperado: 0, 2, %s: ya no queda, la casilla pasa a la pieza especial)" % [
		Guardado.cargar().baul.get("gasolina", 0), mochila.count("gasolina"), marca.call(), en_baul.call("pieza_especial")])
	# las balas y los cartuchos: desde su hueco de munición se guarda el hueco entero (también arrastrándolo) y salen de una
	# tanda (un hueco: 24 balas, 12 cartuchos), o lo que quepa. 60 balas son tres huecos (24, 24 y 12)
	var texto_boton := func(nombre: String) -> String:
		var b: Button = inventario.fondo.find_child(nombre, true, false)
		return "no está" if b == null else b.text
	johnny.municion = {"balas": 60, "cartuchos": 7}
	inventario.pintar()
	inventario.tocar("u0")
	await get_tree().process_frame
	print("Elegido el 1.er hueco de balas: «Guardar en el baúl» %s · arrastrándolo, destinos %s · dice «%s» (esperado: activo · {baul: guardar} · es para la pistola y la MP5, se guardan los 24)" % [
		boton.call("guardar"), inventario.destinos("u0"), dice.call()])
	inventario.guardar()
	await get_tree().process_frame
	print("Guardado el hueco: en el baúl %d balas, Johnny lleva %d (esperado: 24, 36) · la marca en «%s» (esperado: u0, el hueco siguiente)" % [
		Guardado.cargar().baul.get("balas", 0), johnny.cuanta("balas"), marca.call()])
	inventario.tocar(en_baul.call("balas"))
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-municion.png")
	print("Elegidas las balas del baúl: botón «%s», %s · dice «%s» (esperado: Sacar 24, activo · es para la pistola, salen hasta 24 de una vez)" % [
		texto_boton.call("sacar"), boton.call("sacar"), dice.call()])
	inventario.sacar()
	await get_tree().process_frame
	print("Sacadas: en el baúl %d balas, Johnny lleva %d (esperado: 0, 60: se acaba la casilla)" % [
		Guardado.cargar().baul.get("balas", 0), johnny.cuanta("balas")])
	# con poco sitio salen solo las que quepan: 40 balas (2 huecos), 60 cartuchos (5) y la gasolina (1) dejan sitio a 8 más
	johnny.municion = {"balas": 40, "cartuchos": 60}
	Guardado.cambiar(func(g2): g2.baul["balas"] = 100)
	inventario.pintar()
	inventario.tocar(en_baul.call("balas"))
	await get_tree().process_frame
	inventario.sacar()
	await get_tree().process_frame
	print("Con sitio para 8: en el baúl %d balas, Johnny lleva %d (esperado: 92, 48)" % [Guardado.cargar().baul.get("balas", 0), johnny.cuanta("balas")])
	print("Sin sitio: «Sacar» %s, dice «%s» (esperado: apagado · no te cabe: llenos los huecos de munición)" % [boton.call("sacar"), dice.call()])
	inventario.sacar()
	await get_tree().process_frame
	print("Sacar sin sitio: en el baúl %d balas, Johnny lleva %d (esperado: 92, 48: no cambia nada)" % [Guardado.cargar().baul.get("balas", 0), johnny.cuanta("balas")])
	# los cartuchos, también
	johnny.municion = {"balas": 0, "cartuchos": 30}
	Guardado.cambiar(func(g2): g2.baul = {"pieza_especial": 3, "cartuchos": 5})
	inventario.pintar()
	inventario.tocar(en_baul.call("cartuchos"))
	await get_tree().process_frame
	print("Cartuchos del baúl: botón «%s» (esperado: Sacar 5: solo hay 5)" % texto_boton.call("sacar"))
	inventario.sacar()
	await get_tree().process_frame
	print("Sacados: en el baúl %d, Johnny lleva %d (esperado: 0, 35)" % [Guardado.cargar().baul.get("cartuchos", 0), johnny.cuanta("cartuchos")])
	# «Destruir» en el baúl: la primera pulsación pide confirmación, otra casilla o 3 s la cancelan, la segunda destruye
	Guardado.cambiar(func(g2):
		g2.baul = {"pieza_especial": 3, "cartuchos": 40}
		g2.baul_equipo = [{"id": "bate", "calidad": 2}, {"id": "molotov", "calidad": 1, "n": 4}])
	inventario.pintar()
	inventario.tocar(en_baul.call("pieza_especial"))
	await get_tree().process_frame
	print("Elegida la pieza especial del baúl: «Destruir» %s, texto «%s» (esperado: activo, Destruir)" % [
		boton.call("destruir"), texto_boton.call("destruir")])
	inventario.destruir()
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-baul-destruir.png")
	print("1.ª pulsación: texto «%s» · en el baúl %d · dice «%s» (esperado: ¿Seguro? Pulsa otra vez · 3 · ¿Destruir Pieza especial ×3?...)" % [
		texto_boton.call("destruir"), Guardado.cargar().baul.get("pieza_especial", 0), dice.call()])
	inventario.tocar(en_baul.call("cartuchos"))
	inventario.tocar(en_baul.call("pieza_especial"))
	await get_tree().process_frame
	print("Elegir otra casilla y volver: texto «%s» · en el baúl %d (esperado: Destruir, 3: se cancela)" % [
		texto_boton.call("destruir"), Guardado.cargar().baul.get("pieza_especial", 0)])
	inventario.destruir()
	await get_tree().create_timer(3.3).timeout
	print("Tras 3 s sin pulsar: texto «%s» · en el baúl %d (esperado: Destruir, 3: se cancela solo)" % [
		texto_boton.call("destruir"), Guardado.cargar().baul.get("pieza_especial", 0)])
	inventario.destruir()
	inventario.destruir()
	await get_tree().process_frame
	print("Destruida la pieza especial: en el baúl %d · dice «%s» · la marca en «%s» (esperado: 0 · Destruido: Pieza especial ×3. · una casilla, no el botón)" % [
		Guardado.cargar().baul.get("pieza_especial", 0), dice.call(), marca.call()])
	inventario.tocar(en_baul.call("cartuchos"))
	await get_tree().process_frame
	inventario.destruir()
	inventario.destruir()
	await get_tree().process_frame
	print("Destruidos los cartuchos del baúl: quedan %d (esperado: 0 de 40)" % Guardado.cargar().baul.get("cartuchos", 0))
	for id in ["bate", "molotov"]:   # un arma y un paquete de arrojables
		inventario.tocar("b%d" % inventario.cosas_baul(Guardado.cargar()).map(func(o): return o.id if o.equipo >= 0 else "").find(id))
		await get_tree().process_frame
		inventario.destruir()
		await get_tree().process_frame
		var pide: String = dice.call()
		inventario.destruir()
		await get_tree().process_frame
		print("Destruido «%s» del baúl: pedía «%s» · queda %s (esperado: %s)" % [id, pide, Guardado.cargar().baul_equipo.map(func(e): return e.id),
			"¿Destruir Bate (Rara)? ... · [molotov]" if id == "bate" else "¿Destruir Molotov (Poco común) ×4? ... · []"])
	# lo de la mochila (dos piezas de arrojable que se ponen y se quitan) y un hueco de munición
	mochila.append_array(["pieza_arrojable", "pieza_arrojable"])
	var en_mochila := mochila.size()
	inventario.pintar()
	inventario.tocar("m%d" % Objetos.casillas(mochila).map(func(c): return c[0]).find("pieza_arrojable"))
	await get_tree().process_frame
	inventario.destruir()
	inventario.destruir()
	await get_tree().process_frame
	print("Destruidas las piezas de arrojable de la mochila: quedan %d, el resto de la mochila %d de %d (esperado: 0, %d de %d)" % [
		mochila.count("pieza_arrojable"), mochila.size(), en_mochila, en_mochila - 2, en_mochila])
	johnny.municion = {"balas": 60}
	inventario.pintar()
	inventario.tocar("u0")
	await get_tree().process_frame
	inventario.destruir()
	inventario.destruir()
	await get_tree().process_frame
	print("Destruido el 1.er hueco de balas: Johnny lleva %d (esperado: 36: el hueco de 24)" % johnny.cuanta("balas"))
	inventario.tocar("u%d" % johnny.huecos_municion().map(func(h): return h[0]).find("gasolina"))
	await get_tree().process_frame
	inventario.destruir()
	inventario.destruir()
	await get_tree().process_frame
	print("Destruida la gasolina de la munición: quedan %d en la mochila (esperado: 0)" % mochila.count("gasolina"))
	mochila.append_array(["gasolina", "gasolina"])   # (otra vez, para lo que sigue)
	# las armas que lleva no se destruyen
	inventario.pintar()
	inventario.tocar("p0")
	await get_tree().process_frame
	print("Elegida el arma de la mano: botón «Destruir» %s (esperado: no está)" % boton.call("destruir"))
	# «Guardar todo», con la gasolina sacada otra vez en la munición y 30 balas encima
	johnny.municion = {"balas": 30}
	Guardado.cambiar(func(g2): g2.baul = {"pieza_especial": 3, "gasolina": 3})
	inventario.pintar()
	inventario.guardar_todo()
	await get_tree().process_frame
	g = Guardado.cargar()
	print("«Guardar todo» con sitio: mochila %s, balas que lleva %d (esperado: [], 0) · baúl %s (esperado: pieza_especial 3, gasolina 5: las 3 y las 2 sacadas, vendas 1, pieza_cuerpo 1, pieza_distancia 3, balas 30) · «Guardar todo» %s, la marca en «%s» (esperado: apagado, b0: ya no hay nada que guardar)" % [
		mochila, johnny.cuanta("balas"), g.baul, boton.call("guardar_todo"), marca.call()])
	# sacar un arma que ya lleva: se cambian y la suya entra en el baúl en su lugar, aunque sea la fregona o la pistola
	# Normales (nada al suelo). Con el bate a la mano, para que la fregona quede de repuesto
	Guardado.cambiar(func(g2):
		g2.baul_equipo = [{"id": "fregona", "calidad": 3}, {"id": "pistola", "calidad": 2}])
	llevar_arma("bate", 1)
	inventario.pintar()
	await get_tree().process_frame
	var en_suelo: int = mapa.cosas.get_child_count()
	var arma_baul := func(id: String) -> String:   # la casilla de un arma en el baúl ("b4")
		return "b%d" % inventario.cosas_baul(Guardado.cargar()).map(func(o): return o.id if o.equipo >= 0 else "").find(id)
	inventario.tocar(arma_baul.call("fregona"))
	await get_tree().process_frame
	print("La fregona Épica del baúl (con la Normal de repuesto): «Sacar» %s (esperado: activo) · dice «%s»" % [
		boton.call("sacar"), dice.call()])
	inventario.sacar()
	inventario.tocar(arma_baul.call("pistola"))
	inventario.sacar()
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-cambio.png")
	print("Sacadas la fregona Épica y la pistola Rara: en la mano %s, de repuesto %s, calidades %s · baúl %s · cosas nuevas en el suelo %d (esperado: bate y pistola · fregona · bate 1, fregona 3, pistola 2 · fregona 0 y pistola 0, cada una en su casilla · 0)" % [
		johnny.huecos, armas_guardadas, johnny.calidades,
		Guardado.cargar().baul_equipo.map(func(e): return "%s %d" % [e.id, e.calidad]),
		mapa.cosas.get_child_count() - en_suelo])
	# los montones de 99: 250 balas ocupan tres casillas (99, 99 y 52); al guardar el hueco de 24 de las 30 que lleva, 274
	# (99, 99 y 76); «Destruir» quita solo la casilla elegida (la última: quedan 198); y con el baúl casi lleno solo entra lo
	# que cabe en la última casilla
	Guardado.cambiar(func(g2):
		g2.baul = {"balas": 250, "pieza_especial": 1}
		g2.baul_equipo = [])
	mochila.clear()
	johnny.municion = {"balas": 30}
	inventario.pintar()
	var montones := func() -> String:
		return str(inventario.objetos_baul(Guardado.cargar()).map(func(o): return "%s %d" % [o[0], o[1]]))
	inventario.tocar("b%d" % (inventario.objetos_baul(Guardado.cargar()).size() - 1))
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-montones.png")
	print("Montones de 99: %s (esperado: pieza_especial 1, balas 99, balas 99, balas 52) · ocupa %d de %d (esperado: 4) · la última dice «%s» (esperado: Hay 52 en esta casilla · 250 en el baúl)" % [
		montones.call(), Objetos.casillas_baul(Guardado.cargar()), Objetos.BAUL, inventario.ficha_baul().cuanto])
	inventario.tocar("u0")
	inventario.guardar()
	await get_tree().process_frame
	print("Guardado el hueco de 24 balas: %s (esperado: pieza_especial 1, balas 99, balas 99, balas 76) · le quedan %d (esperado: 6)" % [
		montones.call(), johnny.cuanta("balas")])
	inventario.tocar("b%d" % (inventario.objetos_baul(Guardado.cargar()).size() - 1))
	inventario.destruir()
	inventario.destruir()
	await get_tree().process_frame
	print("Destruida la última casilla de balas: %s (esperado: pieza_especial 1, balas 99, balas 99)" % montones.call())
	Guardado.cambiar(func(g2):
		g2.baul = {"balas": 60}
		g2.baul_equipo = []
		for i in Objetos.BAUL - 1:
			g2.baul_equipo.append({"id": "bate", "calidad": 1}))
	johnny.municion = {"balas": 60}
	inventario.pintar()
	print("Baúl con 31 armas y 60 balas: caben %d balas más (esperado: 39: hasta 99 en su casilla)" % Objetos.caben_baul(Guardado.cargar(), "balas"))
	inventario.guardar_todo()
	await get_tree().process_frame
	print("«Guardar todo»: en el baúl %d balas, contigo %d (esperado: 99, 21) · dice «%s» (esperado: el baúl está lleno: contigo se quedan balas)" % [
		Guardado.cargar().baul.get("balas", 0), johnny.cuanta("balas"), dice.call()])
	print("Con la casilla de balas ya en 99 y el baúl lleno: caben %d (esperado: 0) · «Guardar todo» %s (esperado: apagado)" % [
		Objetos.caben_baul(Guardado.cargar(), "balas"), boton.call("guardar_todo")])
	johnny.municion.clear()
	# el baúl lleno: una pieza y 31 armas, cada una en su casilla (de las cuatro calidades)
	Guardado.cambiar(func(g2):
		g2.baul = {"pieza_especial": 1}
		g2.baul_equipo = []
		for i in Objetos.BAUL - 1:
			g2.baul_equipo.append({"id": ["bate", "cuchillo", "escopeta", "mp5"][i % 4], "calidad": i % 4}))
	llevar_arma("bate", 2)
	inventario.pintar()
	inventario.tocar("p0")
	await get_tree().process_frame
	print("Baúl lleno: %d / %d casillas · «Guardar en el baúl» del bate Raro de la mano %s (esperado: 32 / 32, apagado) · dice «%s»" % [
		Objetos.casillas_baul(Guardado.cargar()), Objetos.BAUL, boton.call("guardar"), dice.call()])
	# con más de 32 (al completar el edificio entra lo que lleva aunque no quepa): casillas más pequeñas
	Guardado.cambiar(func(g2):
		for i in 9:
			g2.baul_equipo.append({"id": "cuchillo", "calidad": 3}))
	inventario.pintar()
	inventario.tocar("b%d" % (inventario.cosas_baul(Guardado.cargar()).size() - 1))
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-baul-lleno.png")
	print("Baúl con más de 32: %d casillas, se ven %d (esperado: 41, 41: todas, más pequeñas) · la última: «%s»" % [
		Objetos.casillas_baul(Guardado.cargar()), inventario.fondo.find_children("b*", "", true, false).size(), dice.call()])
	inventario.cerrar()
	await get_tree().process_frame
	print("Baúl cerrado: juego en pausa %s (esperado: false)" % get_tree().paused)
	Guardado.cambiar(func(g2):
		g2.baul = antes.baul
		g2.baul_equipo = antes.baul_equipo)
	get_tree().quit()


# Con "--captura --calidades": las calidades de las armas y de los paquetes de arrojables (Armas.CALIDADES; parte 4 de la
# tienda y las piezas). Cada línea dice lo esperado. Cuenta: lo que da cada calidad (el bate Raro, la pistola Épica, el
# lanzallamas Raro, el lanza rayos Poco común y los molotovs Raros); que Johnny lleva una de cada arma (al coger
# otro bate, se cambian y el viejo se queda en el suelo); que en el baúl (con lo de «Piezas al baúl» del panel de pruebas) se guardan el bate y los
# molotovs Raros, pero no la fregona ni los molotovs Normales, y que al sacar un arma la que sobra entra en su lugar; las
# casillas con el color de su calidad (captura-calidades-baul.png y captura-calidades-inventario.png); que si cae no
# guarda nada y que al completar el edificio pasan al baúl sus armas (menos la fregona y la pistola Normales) y los
# paquetes mejorados. Deja el guardado como estaba y se cierra
func probar_calidades() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g2):
		g2.baul = {}
		g2.baul_equipo = [])
	var dice := func() -> String:    # el texto de la ficha
		var t: Label = inventario.fondo.find_child("nota", true, false)
		return t.text if t else "-"
	var boton := func(nombre: String) -> String:
		var b: Button = inventario.fondo.find_child(nombre, true, false)
		return "no está" if b == null else ("apagado" if b.disabled else "activo")
	var en_baul := func(id: String, calidad: int) -> String:   # la casilla de un arma o un paquete en el baúl ("b5")
		var cosas: Array = inventario.cosas_baul(Guardado.cargar())
		for i in cosas.size():
			if cosas[i].equipo >= 0 and cosas[i].id == id and cosas[i].calidad == calidad:
				return "b%d" % i
		return "-"
	var equipo := func() -> Array:   # el equipo del baúl, corto: ["bate 1", "molotov 2 ×4"...]
		return Guardado.cargar().baul_equipo.map(func(e): return "%s %d%s" % [e.id, e.calidad, " ×%d" % e.n if e.has("n") else ""])
	# lo que da cada calidad
	var w := Armas.con_calidad("bate", 2)
	print("Bate Raro: daño %.1f, alcance %.1f, abanico %.1f (esperado: 23.2, 79.2, 132.0: +45 %%, +20 %%, +20 %%)" % [w.dano, w.alcance, w.arco])
	w = Armas.con_calidad("pistola", 3)
	print("Pistola Épica: daño %.1f, cargador %d, recarga %.3f (esperado: 17.5, 21, 0.605: +75 %%, +75 %%, un 45 %% más rápida)" % [
		w.dano, w.cargador, w.recarga])
	w = Armas.con_calidad("lanzallamas", 2)
	print("Lanzallamas Raro: daño %.1f, depósito %.1f s (esperado: 43.5, 12.0) · lanza rayos Poco común: saltos %d, depósito %.1f s (esperado: 1, 10.0)" % [
		w.dano, w.deposito, Armas.con_calidad("pistola_electrica", 1).saltos, Armas.con_calidad("pistola_electrica", 1).deposito])
	print("Lo que dice la ficha: «%s» · «%s»" % [Armas.que_da("bate", 2), Armas.que_da("molotov", 3)])
	# una de cada arma: el bate Raro a la mano (la fregona al repuesto) y luego otro bate, Poco común: se cambian
	llevar_arma("bate", 2)
	var dano_raro: float = johnny.arma().dano
	print("Bate Raro a la mano: calidad %d, de repuesto «%s» (esperado: 2, fregona)" % [johnny.calidad("bate"), repuesto("cuerpo")])
	var suelta := llevar_arma("bate", 1)
	print("Otro bate, Poco común: sobra %s, en la mano el bate %d, daño Raro / Poco común %.3f (esperado: {id: bate, calidad: 2}, 1, 1.208)" % [
		suelta, johnny.calidad("bate"), dano_raro / johnny.arma().dano])
	# la pistola Épica, cambiada por la Normal: viene llena, con su cargador más grande
	suelta = llevar_arma("pistola", 3)
	print("Pistola Épica: sobra %s, balas %d de %d (esperado: {id: pistola, calidad: 0}, 21 de 21)" % [suelta, johnny.balas,
		johnny.base("pistola").cargador])
	# los molotovs Raros: un paquete aparte, con su hueco, su máximo y su radio
	var entran := lanzables.meter("molotov:2", 4)
	var tipo_antes: String = lanzables.tipo
	lanzables.tipo = "molotov:2"
	var radio_raro := lanzables.radio_zona()
	lanzables.tipo = "molotov"
	print("Molotovs Raros: entran %d, a mano %s, caben %d (esperado: 4, [molotov, granada, molotov:2], %d) · radio Raro / Normal %.2f (esperado: 1.20)" % [
		entran, lanzables.mano, lanzables.maximo("molotov:2"), lanzables.maximo("molotov") + 2, radio_raro / lanzables.radio_zona()])
	lanzables.tipo = tipo_antes
	# el baúl, con lo de «Piezas al baúl» (piezas, y armas y arrojables de cada calidad)
	dar_objetos()
	johnny.position = Vector2(mapa.BAUL_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	if inventario.abierto != "baul":
		print("Baúl: no se ha abierto (esperado: abierto)")
		Guardado.escribir(antes)
		get_tree().quit()
		return
	print("Baúl con «Piezas al baúl»: %d casillas, equipo %s (esperado: 10: 4 piezas y 6 de equipo)" % [
		Objetos.casillas_baul(Guardado.cargar()), equipo.call()])
	inventario.tocar("p0")
	await get_tree().process_frame
	print("El bate Poco común de la mano: «Guardar en el baúl» %s (esperado: activo) · dice «%s»" % [boton.call("guardar"), dice.call()])
	inventario.guardar()
	await get_tree().process_frame
	print("Guardado: equipo %s · en la mano «%s», de repuesto «%s» (esperado: termina en bate 1 · fregona, nada)" % [
		equipo.call(), johnny.huecos.cuerpo, repuesto("cuerpo")])
	inventario.tocar("p0")
	await get_tree().process_frame
	print("La fregona Normal: «Guardar en el baúl» %s (esperado: no está) · dice «%s»" % [boton.call("guardar"), dice.call()])
	inventario.tocar("l2")
	await get_tree().process_frame
	inventario.guardar()
	await get_tree().process_frame
	print("Los molotovs Raros, guardados: equipo %s · a mano %s (esperado: termina en molotov 2 ×4 · [molotov, granada])" % [
		equipo.call(), lanzables.mano])
	inventario.tocar("l0")
	await get_tree().process_frame
	print("Los molotovs Normales: «Guardar en el baúl» %s (esperado: no está) · dice «%s»" % [boton.call("guardar"), dice.call()])
	# sacar: el bate a la mano (la fregona, al repuesto); la escopeta Rara a la mano (la pistola Épica al repuesto) y
	# la pistola Rara, que se cambia por la Épica de repuesto (la Épica entra en el baúl en su lugar)
	inventario.tocar(en_baul.call("bate", 1))
	await get_tree().process_frame
	print("El bate del baúl: «Sacar» %s (esperado: activo) · dice «%s»" % [boton.call("sacar"), dice.call()])
	inventario.sacar()
	inventario.tocar(en_baul.call("escopeta", 2))
	inventario.sacar()
	inventario.tocar(en_baul.call("pistola", 2))
	inventario.sacar()
	await get_tree().process_frame
	print("Sacados el bate, la escopeta y la pistola Rara: manos %s, repuesto %s, calidades %s · equipo %s (esperado: bate y escopeta · fregona y pistola · bate 1, escopeta 2, pistola 2 · la pistola 3 donde estaba la 2) · dice «%s»" % [
		johnny.huecos, armas_guardadas, johnny.calidades, equipo.call(), dice.call()])
	inventario.tocar(en_baul.call("molotov", 2))
	inventario.sacar()
	await get_tree().process_frame
	print("Sacados los molotovs Raros: a mano %s, quedan %d (esperado: [molotov, granada, molotov:2], 4)" % [lanzables.mano,
		lanzables.cuantas("molotov:2")])
	inventario.tocar(en_baul.call("lanzallamas", 3))
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-calidades-baul.png")
	print("El lanzallamas Épico del baúl: dice «%s»" % dice.call())
	inventario.cerrar()
	await get_tree().process_frame
	# el inventario, con los bordes de colores
	abrir_cosas("inventario")
	await get_tree().create_timer(0.3).timeout
	inventario.tocar("p1")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-calidades-inventario.png")
	print("La escopeta Rara en el inventario: dice «%s»" % dice.call())
	inventario.cerrar()
	await get_tree().process_frame
	# si cae, nada; al completar el edificio, lo que lleva (menos la fregona y la pistola Normales) y los paquetes mejorados
	var encima := equipo_encima()
	var cuantos: int = Guardado.cargar().baul_equipo.size()
	terminar(false)
	await get_tree().create_timer(0.3).timeout
	print("Cae: el baúl tiene %d de equipo (esperado: %d, lo mismo)" % [Guardado.cargar().baul_equipo.size(), cuantos])
	terminada = false
	get_tree().paused = false
	terminar(true)
	await get_tree().create_timer(0.3).timeout
	print("Completa el edificio: lo que lleva %s · el baúl tiene %d de equipo (esperado: bate 1, escopeta 2, pistola 2 y molotov 2 ×4, sin la fregona · %d)" % [
		encima.map(func(e): return "%s %d%s" % [e.id, e.calidad, " ×%d" % e.n if e.has("n") else ""]),
		Guardado.cargar().baul_equipo.size(), cuantos + encima.size()])
	Guardado.escribir(antes)
	get_tree().quit()


# Con "--captura --banco-mejorar": el banco de trabajo (parte 5 de la tienda y las piezas). Cada línea dice lo
# esperado. Con 2 piezas cuerpo a cuerpo en la mochila y 2 en el baúl, 3 arrojables y 20 a distancia en el baúl, en el
# baúl una escopeta Rara, un lanzallamas Épico y 3 molotovs Poco comunes, y 5 molotovs Poco comunes a mano: Johnny se
# arrima al banco y se abre (captura-banco.png); sube la fregona a Poco común (gasta primero las 2 de la mochila y 1 del
# baúl) y se cumple el logro Manitas; para Rara le faltan; la granada sube en su mismo hueco; los molotovs Normales no
# caben con los Poco comunes y, con uno solo, se juntan (los arrojables cuestan menos: 1, 2 y 4); la escopeta del baúl sube a Épica y el lanzallamas Épico ya no
# sube (captura-banco-mejorado.png); los molotovs del baúl, sin piezas bastantes. Deja el guardado como estaba y se cierra
func probar_banco_mejorar() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g2):
		g2.baul = {"pieza_cuerpo": 2, "pieza_arrojable": 3, "pieza_distancia": 20}
		g2.baul_equipo = [{"id": "escopeta", "calidad": 2}, {"id": "lanzallamas", "calidad": 3},
			{"id": "molotov", "calidad": 1, "n": 3}]
		g2.logros.erase("manitas"))
	mochila = ["pieza_cuerpo", "gasolina", "pieza_cuerpo"]
	lanzables.meter("molotov:1", 5)
	var dice := func(nombre: String) -> String:   # un texto de la ficha: lo que gana ("nota") o lo que cuesta ("coste")
		var t: Label = inventario.fondo.find_child(nombre, true, false)
		return t.text if t else "-"
	var boton := func() -> String:   # el botón de mejorar
		var b: Button = inventario.fondo.find_child("mejorar", true, false)
		return "no está" if b == null else "%s «%s»" % ["apagado" if b.disabled else "activo", b.text]
	var piezas := func(p: String) -> String:   # las de esa familia: en la mochila y en el baúl
		return "%d y %d" % [mochila.count(p), Guardado.cargar().baul.get(p, 0)]
	# se arrima al banco
	johnny.position = Vector2(mapa.BANCO_X, mapa.MURO + 36.0 + 22.0)
	johnny.direccion = "n"
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.5).timeout
	if inventario.abierto != "banco":
		print("Banco: no se ha abierto (esperado: abierto)")
		Guardado.escribir(antes)
		get_tree().quit()
		return
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-banco.png")
	# la fregona de la mano: a Poco común
	print("La fregona: elegida %s · botón %s · «%s» · «%s» (esperado: p0 · activo «Mejorar a Poco común» · Sube a Poco común: daño +20 %%... · Cuesta 3 piezas cuerpo a cuerpo (tienes 4).)" % [
		inventario.sel, boton.call(), dice.call("nota"), dice.call("coste")])
	inventario.mejorar()
	await get_tree().process_frame
	print("Mejorada: calidad %d · piezas cuerpo a cuerpo %s · logro Manitas «%s» · dice «%s» (esperado: 1 · 0 y 1 · conseguido · ¡Mejorado! Ahora es Fregona (Poco común).)" % [
		johnny.calidad("fregona"), piezas.call("pieza_cuerpo"), Logros.estado(Guardado.cargar(), "manitas"), dice.call("nota")])
	print("Otra vez: botón %s · «%s» (esperado: apagado «Mejorar a Rara» · Cuesta 6 piezas cuerpo a cuerpo y tienes 1: te faltan 5.)" % [
		boton.call(), dice.call("coste")])
	inventario.mejorar()
	print("Sin piezas: calidad %d (esperado: 1)" % johnny.calidad("fregona"))
	# los arrojables a mano: la granada sube en su hueco; los molotovs Normales, con los Poco comunes
	inventario.tocar("l1")
	inventario.mejorar()
	await get_tree().process_frame
	print("La granada: a mano %s, quedan %d · elegida %s · piezas arrojables %s (esperado: [molotov, granada:1, molotov:1], 2 · l1 · 0 y 2)" % [
		lanzables.mano, lanzables.cuantas("granada:1"), inventario.sel, piezas.call("pieza_arrojable")])
	inventario.tocar("l0")
	await get_tree().process_frame
	print("Los 2 molotovs Normales, con 5 Poco comunes: botón %s · «%s» (esperado: apagado · Ya llevas otro paquete Poco común y juntos no caben (como mucho, 6)...)" % [
		boton.call(), dice.call("coste")])
	lanzables.cantidades["molotov"] = 1
	inventario.repintar()
	inventario.mejorar()
	await get_tree().process_frame
	print("Con 1 Normal, se juntan: a mano %s, Poco comunes %d · elegida %s · piezas arrojables %s (esperado: [granada:1, molotov:1], 6 · l1 · 0 y 1)" % [
		lanzables.mano, lanzables.cuantas("molotov:1"), inventario.sel, piezas.call("pieza_arrojable")])
	# lo del baúl: la escopeta Rara a Épica; el lanzallamas Épico, ya no; los molotovs, sin piezas bastantes
	inventario.tocar("q0")
	inventario.mejorar()
	await get_tree().process_frame
	print("La escopeta del baúl: calidad %d · piezas a distancia %s · botón %s (esperado: 3 · 0 y 10 · apagado «Ya es Épica»)" % [
		Guardado.cargar().baul_equipo[0].calidad, piezas.call("pieza_distancia"), boton.call()])
	inventario.tocar("q1")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-banco-mejorado.png")
	print("El lanzallamas Épico: botón %s · «%s» · «%s» (esperado: apagado «Ya es Épica» · Épica: daño +75 %%, depósito un 75 %% más grande. Truco: los zombis que mata revientan y pasan su efecto a los de al lado. · Ya es Épica: no se puede mejorar más.)" % [
		boton.call(), dice.call("nota"), dice.call("coste")])
	inventario.tocar("q2")
	await get_tree().process_frame
	print("Los 3 molotovs Poco comunes del baúl: botón %s · «%s» (esperado: apagado «Mejorar a Rara» · Cuesta 2 piezas arrojables y tienes 1: te faltan 1.)" % [
		boton.call(), dice.call("coste")])
	inventario.cerrar()
	Guardado.escribir(antes)
	get_tree().quit()


# Con "--captura --piezas": las piezas de mejora de las armas (Objetos.PIEZAS) y la limpieza de objetos del 25 oct. Cada
# línea dice lo esperado. Cuenta: que hay 4 piezas con su nombre y su icono, y que ya no están los 5 objetos quitados
# (explosivos, despertador, extintor, trapo y alcohol: ni en NOMBRES, ni su icono, ni en 3000 sorteos de lo que cae al
# azar); las tasas (zombi 6 %, jefe 4; con la Alerta 5, 12 % y 8); «Piezas al baúl» del panel de pruebas (10 de cada pieza al baúl) y la ficha de
# una pieza en el baúl; un zombi normal que suelta una pieza de verdad al caer (se mata uno tras otro hasta que sale) y
# la portera, que suelta cuatro; Johnny las recoge, la mochila las apila y su ficha dice para qué armas son
# (captura-piezas-mochila.png; la del baúl, captura-piezas-baul.png); y al completar el edificio (terminar(true)) pasan
# al baúl. Deja el guardado como estaba y se cierra
func probar_piezas() -> void:
	var antes := Guardado.cargar()
	await get_tree().create_timer(0.5).timeout
	var quitados := ["explosivos", "despertador", "extintor", "trapo", "alcohol"]
	print("Piezas: %s · nombres %s (esperado: 4 · Pieza cuerpo a cuerpo, Pieza a distancia, Pieza especial, Pieza arrojable)" % [
		Objetos.PIEZAS.size(), Objetos.PIEZAS.keys().map(Objetos.nombre)])
	print("Familias: %s (esperado: cuerpo, distancia, especial, arrojable) · iconos que faltan: %s (esperado: [])" % [
		Objetos.PIEZAS.values(), Objetos.PIEZAS.keys().filter(
			func(id): return not FileAccess.file_exists("res://assets/ui/iconos/%s.png" % Objetos.icono(id)))])
	print("Los 5 quitados: en NOMBRES %s · con icono %s (esperado: [] · [])" % [
		quitados.filter(func(id): return Objetos.NOMBRES.has(id)),
		quitados.filter(func(id): return FileAccess.file_exists("res://assets/ui/iconos/obj-%s.png" % id))])
	print("Siguen los dos copiados aparte: atraedora %s · congeladora %s (esperado: true, true)" % [
		FileAccess.file_exists("res://assets/ui/iconos/atraedora.png"), FileAccess.file_exists("res://assets/ui/iconos/congeladora.png")])
	# lo que cae al azar (y lo que suelta un zombi concreto): ni piezas ni los quitados
	var raros := []
	var distintos := {}
	for ed_id in ["apartamentos", "centro"]:
		for tienda in [""] + (Objetos.TIENDAS.keys() + ["ropa"] if ed_id == "centro" else []):
			for i in 400:
				var id := Objetos.al_azar(ed_id, tienda)
				distintos[id] = true
				if id in Objetos.PIEZAS or id in quitados:
					raros.append(id)
	for tipo in ["normal", "explosivo", "venenoso"]:
		for i in 3000:
			var id := Objetos.que_suelta(tipo)
			if id != "":
				distintos[id] = true
				if id in Objetos.PIEZAS or id in quitados:
					raros.append(id)
	print("Sorteos: salen %s · piezas o quitados entre ellos %d (esperado: gasolina, bateria, vendas, bidon_acido · 0)" % [
		distintos.keys(), raros.size()])
	print("Colecciones: Apartamentos %d objetos, centro %d (esperado: 7, 8) · dónde sale la pieza: «%s»" % [
		Objetos.de_edificio("apartamentos").size(), Objetos.de_edificio("centro").size(), Objetos.donde("pieza_cuerpo", "apartamentos")])
	print("Probabilidad de que un zombi suelte un objeto: %.2f (esperado: 0.04)" % Objetos.SUELTA)
	# las tasas, sin y con alerta
	var tasa := func(nivel: int) -> String:
		var nivel_antes := Alerta.nivel
		Alerta.nivel = nivel
		var salen := 0
		for i in 20000:
			if Objetos.pieza_de_zombi() != "":
				salen += 1
		var del_jefe := Objetos.piezas_de_jefe().size()
		Alerta.nivel = nivel_antes
		return "alerta %d: zombi %.1f %% · jefe %d" % [nivel, salen / 200.0, del_jefe]
	print("Tasas: %s | %s | %s (esperado: zombi 6,0 y jefe 4 | zombi 9,0 y jefe 6 | zombi 12,0 y jefe 8, con unas décimas de más o de menos)" % [
		tasa.call(0), tasa.call(3), tasa.call(5)])
	print("Resumen de la Alerta 5: «%s»" % Alerta.resumen(5).replace("\n", " · "))
	# «Piezas al baúl» (el botón del panel de pruebas) mete 10 de cada pieza en el baúl
	Guardado.cambiar(func(g): g.baul = {"gasolina": 1})
	dar_objetos()
	print("Piezas al baúl: baúl %s (esperado: gasolina 1 y 10 de cada pieza)" % [Guardado.cargar().baul])
	abrir_cosas("baul")
	await get_tree().create_timer(0.4).timeout
	var nota := func() -> String: return inventario.fondo.find_child("nota", true, false).text
	inventario.tocar("b%d" % inventario.objetos_baul(Guardado.cargar()).map(func(o): return o[0]).find("pieza_distancia"))
	await get_tree().create_timer(0.2).timeout
	print("Ficha de la pieza a distancia en el baúl: «%s» (esperado: Sirve para mejorar las armas a distancia...)" % nota.call())
	Captura.foto("captura-piezas-baul.png")
	inventario.cerrar()
	await get_tree().process_frame
	Guardado.cambiar(func(g): g.baul = {"gasolina": 1})
	# un zombi normal suelta una pieza de verdad (seis de cada cien): se matan de veinte en veinte hasta que sale una
	var piezas_en_suelo := func() -> Array:
		return mapa.cosas.get_children().filter(func(c): return c.get_script() == BILLETE and c.icono != null and "obj-pieza_" in c.icono.resource_path)
	var matados := 0
	while piezas_en_suelo.call().is_empty() and matados < 600:
		for i in 20:
			var z: Node2D = meter_zombi("normal", johnny.position + Vector2(260, 0))
			z.recibir_golpe(9999, Vector2.ZERO)
		matados += 20
		await get_tree().process_frame
		await get_tree().process_frame
	print("Zombis normales matados hasta que suelta una pieza: %d (esperado: salió alguna, unos 17 de media; piezas en el suelo: %d)" % [
		matados, piezas_en_suelo.call().size()])
	# la portera suelta cuatro
	var antes_jefe: int = piezas_en_suelo.call().size()
	var portera: Node2D = meter_zombi("portera", johnny.position + Vector2(-260, 0))
	portera.recibir_golpe(99999, Vector2.ZERO)
	await get_tree().process_frame
	await get_tree().process_frame
	var del_jefe: int = piezas_en_suelo.call().size() - antes_jefe
	print("La portera al caer suelta %d piezas (esperado: 4)" % del_jefe)
	var total_suelo: int = piezas_en_suelo.call().size()
	# Johnny las recoge: de una en una, yendo a cada sitio donde quedan
	var cogidas := 0
	for vuelta in 4:
		var sitios := []
		for c in piezas_en_suelo.call():
			if not c.position in sitios:
				sitios.append(c.position)
		if sitios.is_empty():
			break
		for sitio in sitios:
			johnny.position = sitio
			await get_tree().create_timer(0.5).timeout
	var en_mochila := mochila.filter(func(id): return id in Objetos.PIEZAS)
	print("Johnny las recoge: en el suelo quedan %d · en la mochila %d piezas, casillas %s (esperado: 0 · %d, y se apilan por familia)" % [
		piezas_en_suelo.call().size(), en_mochila.size(), Objetos.casillas(mochila).filter(func(c): return c[0] in Objetos.PIEZAS),
		total_suelo])
	# (la portera trae las mutaciones 2 s después de caer: se elige una y se sigue)
	for i in 30:
		if menus.abierto == "mutacion":
			break
		await get_tree().create_timer(0.1).timeout
	if menus.abierto == "mutacion":
		menus.elegir("insensible")
	get_tree().paused = false
	await get_tree().process_frame
	# su ficha en la mochila
	abrir_cosas("inventario")
	await get_tree().create_timer(0.4).timeout
	var primera: String = Objetos.casillas(mochila).map(func(c): return c[0]).filter(func(id): return id in Objetos.PIEZAS)[0]
	inventario.tocar("m%d" % Objetos.casillas(mochila).map(func(c): return c[0]).find(primera))
	await get_tree().create_timer(0.2).timeout
	print("Ficha de «%s» en la mochila: «%s» (esperado: Sirve para mejorar las armas ... en el banco de trabajo del taller. Si caes, se pierde...)" % [
		Objetos.nombre(primera), nota.call()])
	Captura.foto("captura-piezas-mochila.png")
	inventario.cerrar()
	await get_tree().process_frame
	# al completar el edificio, pasan al baúl
	var contadas := {}
	for id in en_mochila:
		contadas[id] = contadas.get(id, 0) + 1
	terminar(true)
	await get_tree().create_timer(0.3).timeout
	var baul: Dictionary = Guardado.cargar().baul
	var pasaron := true
	for id in contadas:
		if baul.get(id, 0) != contadas[id]:
			pasaron = false
	print("Al completar el edificio: piezas llevadas %s · baúl %s · pasaron todas %s (esperado: lo mismo en las dos, true)" % [
		contadas, baul, pasaron])
	Guardado.escribir(antes)
	get_tree().quit()


# Con "--captura --repuesto": Johnny lleva como mucho dos armas de cada tipo, la de la mano y la de repuesto
# (partida.llevar_arma). Compra en la tienda del ordenador un lanza ácido y un lanza rayos (con el segundo ya
# llevaba dos de fuego: el lanza ácido se queda en el suelo), el bate y el cuchillo (el cuchillo deja el bate en el
# suelo) y no le deja comprar la pistola que lleva de repuesto, tira la fregona de repuesto desde el
# inventario y vuelve a coger el bate del suelo (va al repuesto, sin cambiarle la de la mano). Saca
# captura-repuesto.png (el inventario con las dos de repuesto). Cada línea dice lo esperado. Deja los dólares y las
# armas compradas como estaban
func probar_repuesto() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g):
		g.dolares = 200
		g.armas = [])
	ahorrados = 200
	johnny.coger("fregona")
	johnny.coger("pistola")
	armas_guardadas.clear()
	var armas := func() -> String:
		return "mano %s y %s · repuesto %s" % [Objetos.nombre(johnny.huecos.cuerpo), Objetos.nombre(johnny.huecos.fuego),
			armas_guardadas.map(Objetos.nombre)]
	var es_arma := func(c: Node) -> bool:   # una de las armas de la prueba tirada en el suelo (por su icono)
		return "icono" in c and c.icono != null and c.icono.resource_path.get_file().get_basename() in [
			"desintegrador", "pistola_electrica", "pistola", "fregona", "bate", "cuchillo"]
	var suelo := func() -> Array:
		return mapa.cosas.get_children().filter(es_arma).map(func(c): return c.icono.resource_path.get_file().get_basename())
	await get_tree().create_timer(0.5).timeout
	print("Al empezar: %s (esperado: mano Fregona y Pistola · repuesto [])" % armas.call())
	# la tienda del ordenador
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("armas")
	ordenador.comprar_arma("desintegrador")
	await get_tree().process_frame
	print("Compra el lanza ácido: %s (esperado: mano Fregona y Lanza ácido · repuesto [\"Pistola\"])" % armas.call())
	ordenador.comprar_arma("pistola_electrica")
	await get_tree().process_frame
	print("Compra el lanza rayos: %s · en el suelo %s (esperado: mano Fregona y Lanza rayos · repuesto [\"Pistola\"] · [\"desintegrador\"]) · dice «%s»" % [
		armas.call(), suelo.call(), ordenador.info.text])
	ordenador.comprar_arma("bate")
	await get_tree().process_frame
	print("Compra el bate: %s · dice «%s» (esperado: mano Bate y Lanza rayos · repuesto [\"Pistola\", \"Fregona\"] · la fregona pasa al repuesto)" % [
		armas.call(), ordenador.info.text])
	ordenador.comprar_arma("cuchillo")
	await get_tree().process_frame
	print("Compra el cuchillo: %s · en el suelo %s · dice «%s» (esperado: mano Cuchillo y Lanza rayos · repuesto [\"Pistola\", \"Fregona\"] · [\"desintegrador\", \"bate\"] · el bate se queda en el suelo)" % [
		armas.call(), suelo.call(), ordenador.info.text])
	var dolares_antes: int = Guardado.cargar().dolares
	ordenador.comprar_arma("pistola")
	await get_tree().process_frame
	print("Compra la pistola de repuesto: %s · $%d → $%d · dice «%s» (esperado: igual, sin pagar, ya la llevas de repuesto)" % [
		armas.call(), dolares_antes, Guardado.cargar().dolares, ordenador.info.text])
	ordenador.abrir("")
	ordenador.apagar()
	await get_tree().process_frame
	# tira la fregona de repuesto y vuelve a coger el bate del suelo, lejos de lo demás
	abrir_cosas("inventario")
	inventario.tocar("g%d" % armas_guardadas.find("fregona"))
	inventario.tirar()
	inventario.cerrar()
	await get_tree().process_frame
	print("Tira la fregona: %s · en el suelo %s (esperado: mano Cuchillo y Lanza rayos · repuesto [\"Pistola\"] · [\"desintegrador\", \"bate\", \"fregona\"])" % [
		armas.call(), suelo.call()])
	var bate: Node2D = mapa.cosas.get_children().filter(func(c): return es_arma.call(c) and c.icono.resource_path.ends_with("/bate.png"))[0]
	bate.position = johnny.position + Vector2(300, 0)
	await get_tree().create_timer(0.3).timeout
	johnny.position = bate.position
	await get_tree().create_timer(0.8).timeout
	print("Coge el bate del suelo: %s · en el suelo %s (esperado: mano Cuchillo y Lanza rayos · repuesto [\"Pistola\", \"Bate\"] · [\"desintegrador\", \"fregona\"])" % [
		armas.call(), suelo.call()])
	abrir_cosas("inventario")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-repuesto.png")
	inventario.cerrar()
	Guardado.cambiar(func(g):
		g.dolares = antes.dolares
		g.armas = antes.armas)
	get_tree().quit()


# Con "--captura --tienda": la tienda de armas del ordenador con sus cuatro secciones (Cuerpo a cuerpo, A distancia,
# Especiales y Arrojables) y los arrojables, que se compran de uno en uno (Lanzables.PRECIOS; ordenador.gd,
# comprar_lanzable). Con $40: la atraedora va a la mano y la congeladora, con la mano llena, al repuesto; tres molotovs
# llegan al máximo y el cuarto no se cobra; sin hueco (la mano y el repuesto llenos a la fuerza) no se compra; y sin
# dinero tampoco. Cada línea dice lo esperado. Fotos: captura-tienda.png (arriba: las armas) y
# captura-tienda-arrojables.png (abajo: los arrojables, con el molotov «AL MÁXIMO»). Deja los dólares como estaban
func probar_tienda() -> void:
	var antes := Guardado.cargar()
	Guardado.cambiar(func(g): g.dolares = 40)
	ahorrados = 40
	var lz: Lanzables = lanzables
	var cuenta := func() -> String:
		return "%s · mano %s · repuesto %s · $%d" % [lz.cantidades, lz.mano, lz.repuesto, Guardado.cargar().dolares]
	await get_tree().create_timer(0.5).timeout
	abrir_ordenador()
	await get_tree().create_timer(0.4).timeout
	ordenador.abrir("armas", "b_cuchillo")
	await get_tree().create_timer(0.3).timeout
	ordenador.ventana.find_children("*", "ScrollContainer", true, false)[0].scroll_vertical = 0   # la foto, desde arriba
	await get_tree().process_frame
	var titulos := ordenador.ventana.find_children("*", "Label", true, false).map(func(l): return l.text).filter(
		func(t): return not "Daño" in t and (t.begins_with("Cuerpo a cuerpo") or t.begins_with("A distancia") or
			t.begins_with("Especiales") or t.begins_with("Arrojables")))   # (las tarjetas dicen «Daño»)
	print("Secciones: %s (esperado: Cuerpo a cuerpo, A distancia..., Especiales..., Arrojables...)" % [titulos])
	print("Familias: escopeta %s, lanzallamas %s, bate %s (esperado: distancia, especial, cuerpo)" % [
		Armas.familia("escopeta"), Armas.familia("lanzallamas"), Armas.familia("bate")])
	Captura.foto("captura-tienda.png")
	print("Al empezar: %s (esperado: molotov 2, granada 2, atraedora 0, congeladora 0 · mano [molotov, granada] · $40)" % cuenta.call())
	ordenador.comprar_lanzable("atraedora")
	await get_tree().process_frame
	print("Compra una atraedora: %s · dice «%s» (esperado: atraedora 1, a la mano · $32)" % [cuenta.call(), ordenador.info.text])
	# sin hueco: la mano y el repuesto llenos a la fuerza (con solo cuatro tipos no pasa jugando), y se deja como estaba
	var mano: Array = lz.mano.duplicate()
	var repuesto: Array = lz.repuesto.duplicate()
	lz.repuesto.assign(["molotov", "molotov", "molotov", "molotov", "molotov", "molotov", "molotov", "molotov"])
	ordenador.comprar_lanzable("congeladora")
	print("Sin hueco, una congeladora: congeladora %d · $%d · dice «%s» (esperado: 0 · $32 · no te queda hueco)" % [
		lz.cuantas("congeladora"), Guardado.cargar().dolares, ordenador.info.text])
	lz.mano.assign(mano)
	lz.repuesto.assign(repuesto)
	ordenador.comprar_lanzable("congeladora")
	await get_tree().process_frame
	print("Compra una congeladora: %s (esperado: congeladora 1, de repuesto · $24)" % cuenta.call())
	for i in 3:
		ordenador.comprar_lanzable("molotov")
		await get_tree().process_frame
	print("Compra tres molotovs: %s · dice «%s» (esperado: molotov 5 · $9 · ya llevas 5/5)" % [cuenta.call(), ordenador.info.text])
	ordenador.comprar_lanzable("molotov")
	await get_tree().process_frame
	print("Otro molotov: %s · dice «%s» (esperado: igual, sin pagar: ya llevas el máximo)" % [cuenta.call(), ordenador.info.text])
	ordenador.comprar_lanzable("granada")
	await get_tree().process_frame
	ordenador.comprar_lanzable("granada")
	await get_tree().process_frame
	print("Dos granadas con $9: %s · dice «%s» (esperado: granada 3 · $4 · la segunda no: te faltan $1)" % [cuenta.call(), ordenador.info.text])
	ordenador.abrir("armas", "b_atraedora")
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-tienda-arrojables.png")
	ordenador.abrir("")
	ordenador.apagar()
	Guardado.cambiar(func(g): g.dolares = antes.dolares)
	get_tree().quit()


# Con "--captura --municion": la munición por tipos (Armas.MUNICION, johnny.gd) y los arrojables 3 + 8 (lanzables.gd), en
# la sala de mantenimiento. La munición: al empezar, las balas de la pistola en un hueco; la MP5 nueva trae dos cargadores
# de las mismas balas y recarga de ellas (la pistola ve las que quedan); la escopeta trae cartuchos; la gasolina y el bidón
# de ácido ocupan huecos de munición y no casillas de la mochila (en el baúl sí se guardan); con el lanzallamas en la mano,
# la caja es para la de repuesto; con su hueco lleno, la caja ya no va; las balas tiradas desde el inventario quedan en
# una caja que las devuelve; y el lanzallamas se llena con una gasolina de la munición. Los arrojables: al empezar, el molotov y la granada a mano; la atraedora y
# la congeladora van a la mano y, con la mano llena, al repuesto; al acabarse uno, su hueco lo ocupa el primero de repuesto; F cambia entre los de la mano;
# «A la mano» y «Al repuesto»; con el máximo, el molotov del suelo no se coge. Cada línea dice lo esperado. Fotos:
# captura-municion.png (el inventario con un hueco de balas elegido), captura-municion-arrojables.png (con un arrojable de
# repuesto elegido) y captura-municion-hud.png (el HUD con la MP5 y las balas que comparte con la pistola)
func probar_municion() -> void:
	var lz: Lanzables = lanzables
	mochila.clear()
	armas_guardadas.clear()
	johnny.coger("fregona")
	johnny.coger("pistola")
	await get_tree().create_timer(0.5).timeout
	var huecos := func() -> String:
		return ", ".join(johnny.huecos_municion().map(func(h): return "%s %d" % [h[0], h[1]]))
	print("Al empezar: %s · cargador %d (esperado: balas 24 · 12)" % [huecos.call(), johnny.balas])
	johnny.coger("mp5")
	print("Coge la MP5: %s · cargador %d (esperado: balas 24, balas 24, balas 24, balas 12 · 30: trae 60 de las mismas balas)" % [
		huecos.call(), johnny.balas])
	johnny.balas = 0
	johnny.terminar_recarga()
	print("Vacía y recarga la MP5: cargador %d · reserva %d (esperado: 30 · 54)" % [johnny.balas, johnny.reserva()])
	johnny.coger("pistola")
	print("Vuelve a la pistola: cargador %d · reserva %d (esperado: 12 · 54: son las mismas balas)" % [johnny.balas, johnny.reserva()])
	johnny.coger("escopeta")
	print("Coge la escopeta: %s · sin munición diría «%s» (esperado: balas 24, balas 24, balas 6, cartuchos 12 · ¡Sin cartuchos!)" % [
		huecos.call(), Armas.MUNICION[Armas.municion(johnny.huecos.fuego)].sin])
	mochila.append_array(["gasolina", "gasolina", "gasolina", "gasolina", "bidon_acido", "pieza_cuerpo"])
	print("Con 4 gasolinas, un bidón de ácido y una pieza cuerpo a cuerpo: %s · mochila %s (esperado: balas 24, balas 24, balas 6, cartuchos 12, gasolina 3, gasolina 1, bidon_acido 1 · [[\"pieza_cuerpo\", 1]])" % [
		huecos.call(), Objetos.casillas(mochila)])
	# con el lanzallamas en la mano (no gasta balas), la caja es para la de repuesto
	llevar_arma("lanzallamas")
	print("Coge el lanzallamas: mano %s · repuesto %s · la caja es para la %s (esperado: Lanzallamas · [\"escopeta\"] · escopeta)" % [
		Objetos.nombre(johnny.huecos.fuego), armas_guardadas, johnny.arma_de_caja()])
	johnny.sumar_municion()
	print("Coge una caja: cartuchos %d · huecos %d / 8 (esperado: 18 · 8)" % [johnny.cuanta("cartuchos"), johnny.huecos_municion().size()])
	johnny.sumar_municion()
	print("Otra caja: cartuchos %d · ¿va otra caja? %s · caben aún %d balas y %d gasolinas (esperado: 24 · false · 18 y 2: lo que falta para llenar sus huecos)" % [
		johnny.cuanta("cartuchos"), johnny.quiere_municion(), johnny.sitio("balas"), johnny.sitio("gasolina")])
	# se pone la escopeta de repuesto (con su cargador de antes) y tira un hueco de balas: queda en una caja
	abrir_cosas("inventario")
	inventario.tocar("g0")
	inventario.poner_guardada()
	print("Se pone la escopeta: mano %s · cargador %d · repuesto %s (esperado: Escopeta · 6 · el lanzallamas)" % [
		Objetos.nombre(johnny.huecos.fuego), johnny.balas, armas_guardadas.map(Objetos.nombre)])
	inventario.tocar("u0")
	inventario.tirar()
	inventario.cerrar()
	await get_tree().create_timer(0.1).timeout
	var cajas: Array = mapa.cosas.get_children().filter(func(c): return c.is_in_group("cajas_municion"))
	print("Tira un hueco de balas: balas %d · cajas en el suelo %d (esperado: 30 · 1)" % [johnny.cuanta("balas"), cajas.size()])
	if not cajas.is_empty():
		cajas[0].position = johnny.position + Vector2(300, 0)
		await get_tree().create_timer(0.3).timeout
		johnny.position = cajas[0].position
		await get_tree().create_timer(0.8).timeout
	print("Vuelve a cogerla: balas %d (esperado: 54)" % johnny.cuanta("balas"))
	# los arrojables
	var arrojables := func() -> String:
		return "a mano %s (lanza %s) · repuesto %s" % [lz.mano, lz.tipo, lz.repuesto]
	print("Arrojables al empezar: %s (esperado: a mano [\"molotov\", \"granada\"] (lanza molotov) · repuesto [])" % arrojables.call())
	for k in ["atraedora", "congeladora"]:
		dar_lanzable(k)
	print("Coge atraedoras y congeladoras: %s (esperado: a mano [molotov, granada, atraedora] · repuesto [congeladora])" % arrojables.call())
	lz.tipo = "granada"
	johnny.invulnerable = 2.6   # (por si alguna rebota hacia él)
	while lz.cuantas("granada") > 0:
		lz.lanzar(johnny.global_position + Vector2(-280, 60))
	print("Lanza todas las granadas: %s (esperado: a mano [molotov, congeladora, atraedora] (lanza congeladora) · repuesto []: la congeladora ocupa su hueco)" % arrojables.call())
	await get_tree().create_timer(2.8).timeout   # (que exploten antes de las fotos)
	var vistos := [lz.tipo]
	for _i in 3:
		lz.cambiar()
		vistos.append(lz.tipo)
	print("F tres veces: %s (esperado: congeladora → atraedora → molotov → congeladora)" % " → ".join(vistos))
	lz.al_repuesto("atraedora")
	print("Guarda la atraedora: %s (esperado: a mano [molotov, congeladora] (lanza congeladora) · repuesto [atraedora])" % arrojables.call())
	lz.cantidades.molotov = lz.maximo("molotov")
	print("Un molotov del suelo con %d de %d: ¿lo coge? %s (esperado: false, ya tiene el máximo)" % [lz.cuantas("molotov"),
		lz.maximo("molotov"), lz.cabe("molotov")])
	await get_tree().create_timer(0.3).timeout
	abrir_cosas("inventario")
	inventario.tocar("u0")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-municion.png")
	inventario.tocar("e0")
	await get_tree().create_timer(0.2).timeout
	Captura.foto("captura-municion-arrojables.png")
	inventario.mover_lanzable()
	print("«A la mano» con la atraedora: %s (esperado: a mano [molotov, congeladora, atraedora] (lanza atraedora) · repuesto [])" % arrojables.call())
	inventario.cerrar()
	await get_tree().process_frame
	abrir_cosas("baul")
	print("En el baúl, para guardar: %s (esperado: gasolina, bidón de ácido y pieza_cuerpo)" % [inventario.guardables()])
	inventario.cerrar()
	await get_tree().process_frame
	# el lanzallamas vacío se llena con una de las gasolinas de la munición
	johnny.coger(armas_guardadas[0])
	johnny.deposito = 0.0
	johnny.terminar_recarga()
	print("Llena el lanzallamas: depósito %.1f s · gasolinas %d (esperado: 8.0 · 3)" % [johnny.deposito, johnny.cuanta("gasolina")])
	johnny.coger("mp5")
	await get_tree().create_timer(0.5).timeout
	print("Con la MP5 en la mano: cargador %d · reserva %d (esperado: 30 · 54)" % [johnny.balas, johnny.reserva()])
	Captura.foto("captura-municion-hud.png")
	get_tree().quit()


# Con "--captura --inventario": la pantalla del inventario «todo a la vista» (ui/inventario.gd, parte 3 del inventario
# nuevo), en la sala de mantenimiento y con un poco de todo: el bate y la pistola en la mano, la fregona y la escopeta de
# repuesto, piezas cuerpo a cuerpo, una pieza a distancia, un botiquín y gasolina en la mochila, balas y cartuchos, la atraedora a mano
# y una congeladora de repuesto, y la skin del bombero. Al abrir, la ficha enseña el arma de la mano; la flecha abajo
# lleva la marca a la escopeta y la ficha la sigue; Intro salta a «Ponérmela» e Y del mando se la pone; Supr tira un
# pieza cuerpo a cuerpo; tirar el arma de la mano pone en su sitio la de repuesto; F cambia el arrojable que se lanza; «A la mano» con la
# mano llena cambia por el que se lanzaba; Esc cierra. Luego, la ficha del lanza rayos (nombre largo, depósito) y
# la de un lanzallamas (depósito), y las otras pruebas que usan el inventario: las vendas (probar_curas)
# y el botiquín de la farmacéutica (supervivientes.gd). Cada línea dice lo esperado.
# Fotos: captura-inventario-nuevo.png (al abrir), captura-inventario-escopeta.png (la marca en la escopeta de
# repuesto), captura-inventario-objeto.png (la pieza a distancia, con su ficha), captura-inventario-destruir.png (con «Destruir»
# a medias; la 2.ª pulsación la destruye), captura-inventario-municion.png,
# captura-inventario-arrojable.png, captura-inventario-pistola_electrica.png y captura-inventario-lanzallamas.png
func probar_inventario() -> void:
	var lz: Lanzables = lanzables
	var inv = inventario
	var skin_antes: String = johnny.skin
	johnny.skin = "bombero"
	mochila.clear()
	armas_guardadas.clear()
	johnny.municion.clear()
	johnny.coger("fregona")
	johnny.coger("escopeta")   # (trae sus cartuchos)
	llevar_arma("bate")        # el bate a la mano y la fregona al repuesto
	llevar_arma("pistola")     # la pistola a la mano y la escopeta al repuesto
	johnny.balas = 8
	johnny.meter_municion("balas", 30)
	mochila.append_array(["pieza_cuerpo", "pieza_cuerpo", "pieza_distancia", "botiquin", "gasolina", "gasolina"])
	lz.mano = ["molotov", "granada"]
	lz.repuesto = []
	lz.tipo = "molotov"
	dar_lanzable("atraedora")
	dar_lanzable("congeladora")
	await get_tree().create_timer(0.5).timeout
	var nota := func() -> String: return inv.fondo.find_child("nota", true, false).text
	var marca := func() -> String:
		var b := get_viewport().gui_get_focus_owner()
		return String(b.name) if b else "-"
	var hoja := func() -> String: return inv.fondo.find_child("johnny", true, false).sprite_frames.resource_path.get_file()
	abrir_cosas("inventario")
	await get_tree().create_timer(0.4).timeout
	print("Al abrir: elegida %s · marca %s · Johnny %s · dice «%s» (esperado: p1 · p1 · conserje-48-pistola-bombero.tres · Dispara de una en una...)" % [
		inv.sel, marca.call(), hoja.call(), nota.call()])
	Captura.foto("captura-inventario-nuevo.png")
	await pulsar_evento(accion("ui_down"))
	print("Flecha abajo: elegida %s · marca %s · dice «%s» (esperado: g1 · g1 · Cinco perdigones...)" % [inv.sel, marca.call(), nota.call()])
	Captura.foto("captura-inventario-escopeta.png")
	await pulsar_evento(accion("ui_accept"))
	print("Intro: marca %s (esperado: poner)" % marca.call())
	var y := InputEventJoypadButton.new()
	y.button_index = JOY_BUTTON_Y
	await pulsar_evento(y)
	await get_tree().create_timer(0.2).timeout
	print("Y del mando: mano %s · repuesto %s · elegida %s · Johnny %s (esperado: Escopeta · [\"fregona\", \"pistola\"] · p1 · conserje-48-escopeta-bombero.tres)" % [
		Objetos.nombre(johnny.huecos.fuego), armas_guardadas, inv.sel, hoja.call()])
	inv.tocar("m0")
	var supr := InputEventKey.new()
	supr.keycode = KEY_DELETE
	await pulsar_evento(supr)
	print("Supr con las piezas cuerpo a cuerpo: mochila %s (esperado: [[\"pieza_cuerpo\", 1], [\"pieza_distancia\", 1], [\"botiquin\", 1]])" % [Objetos.casillas(mochila)])
	inv.tocar("m1")
	await get_tree().create_timer(0.2).timeout
	print("La pieza a distancia: dice «%s» (esperado: Sirve para mejorar las armas a distancia (la pistola, la MP5 y la escopeta) en el banco de trabajo del taller. Si caes, se pierde (en el baúl queda a salvo).)" % nota.call())
	Captura.foto("captura-inventario-objeto.png")
	# «Destruir» la pieza a distancia: la 1.ª pulsación pide confirmación (captura-inventario-destruir.png) y la 2.ª la
	# destruye; X (Tirar al suelo) y Y no lo hacen (sin atajo). Luego se vuelve a poner donde estaba
	var boton_destruir: Button = inv.fondo.find_child("destruir", true, false)
	print("La pieza a distancia: botón «%s» (esperado: Destruir)" % boton_destruir.text)
	inv.destruir()
	await get_tree().create_timer(0.2).timeout
	boton_destruir = inv.fondo.find_child("destruir", true, false)
	print("1.ª pulsación de «Destruir»: botón «%s» · la pieza sigue (%d) · dice «%s» (esperado: ¿Seguro? Pulsa otra vez · 1 · ¿Destruir Pieza a distancia?...)" % [
		boton_destruir.text, mochila.count("pieza_distancia"), nota.call()])
	Captura.foto("captura-inventario-destruir.png")
	inv.destruir()
	await get_tree().process_frame
	print("2.ª pulsación: piezas a distancia %d · dice «%s» (esperado: 0 · Destruido: Pieza a distancia.)" % [mochila.count("pieza_distancia"), nota.call()])
	mochila.insert(mochila.find("pieza_cuerpo") + 1, "pieza_distancia")   # (otra vez, para lo que sigue)
	inv.pintar()
	inv.tocar("m2")
	await get_tree().process_frame
	print("Toca el botiquín: marca %s (esperado: usar)" % marca.call())
	inv.tocar("p0")
	inv.tirar()
	await get_tree().process_frame
	print("Tira el bate de la mano: mano %s y %s (sacada la de %s) · repuesto %s (esperado: Fregona y Escopeta (sacada la de fuego) · [\"pistola\"])" % [
		Objetos.nombre(johnny.huecos.cuerpo), Objetos.nombre(johnny.huecos.fuego), johnny.mano, armas_guardadas])
	inv.tocar("p0")
	print("Sin repuesto, «Tirar al suelo» apagado: %s (esperado: true)" % inv.fondo.find_child("tirar", true, false).disabled)
	await pulsar_evento(accion("cambiar_lanzable"))
	print("F: lanza %s (esperado: granada)" % lz.tipo)
	inv.tocar("e0")
	inv.mover_lanzable()
	print("«A la mano» con la congeladora: a mano %s (lanza %s) · repuesto %s · elegida %s (esperado: [molotov, congeladora, atraedora] (congeladora) · [granada] · l1)" % [
		lz.mano, lz.tipo, lz.repuesto, inv.sel])
	inv.tocar("u0")
	await get_tree().create_timer(0.2).timeout
	print("Las balas: dice «%s»" % nota.call())
	Captura.foto("captura-inventario-municion.png")
	inv.tocar("l2")
	await get_tree().create_timer(0.2).timeout
	print("La atraedora: dice «%s»" % nota.call())
	Captura.foto("captura-inventario-arrojable.png")
	await pulsar_evento(accion("ui_cancel"))
	print("Esc: abierto «%s» · juego en pausa %s (esperado: «» · false)" % [inv.abierto, get_tree().paused])
	# la ficha de nombre largo: el lanza rayos (depósito, con su barra celeste); y la de otro de depósito
	for arma in ["pistola_electrica", "lanzallamas"]:
		llevar_arma(arma)
		abrir_cosas("inventario")
		await get_tree().create_timer(0.3).timeout
		print("%s en la mano: elegida %s · dice «%s» (esperado: p1)" % [Objetos.nombre(johnny.huecos.fuego), inv.sel, nota.call()])
		Captura.foto("captura-inventario-%s.png" % arma)
		inv.cerrar()
		await get_tree().process_frame
	johnny.skin = skin_antes
	# y las otras pruebas que usan el inventario (sin la prueba larga): las vendas y el botiquín
	await probar_curas()
	await supervivientes.probar_botiquin()
	get_tree().quit()


# Con "--captura --arrastrar": arrastrar con el ratón en el inventario y en el baúl (ui/inventario.gd, la parte 5 del
# inventario nuevo). Con el bate y la pistola en la mano, la fregona y la escopeta de repuesto, dos piezas cuerpo a cuerpo, un botiquín
# y dos gasolinas, y de arrojables el molotov, la granada y la atraedora a mano y la congeladora de repuesto, cuenta en
# la terminal (cada línea con lo esperado). Tres arrastres son de verdad, moviendo el ratón (arrastrar: el cursor se
# mueve un momento y luego vuelve a su sitio): la escopeta a la mano (lo que se enciende y lo que crece bajo el ratón),
# las dos piezas cuerpo a cuerpo a la zona roja y, en el baúl, la pieza a distancia al baúl. Los demás sueltan directamente donde caerían
# (inventario.soltar_en): la pistola en Johnny, el botiquín en Johnny (cura y el inventario sigue abierto), la granada
# al repuesto, la congeladora encima del molotov (se cambian), el bate en Johnny (no se puede: vuelve), el bate en su
# repuesto (se cambia por la fregona), las gasolinas en la zona roja y un molotov soltado en el título (vuelve sin
# más); en el baúl, las vendas (sí van), una pieza especial sacada y la fregona (no va). Fotos: captura-arrastrar-escopeta.png
# (a medio arrastrar, sobre la mano), captura-arrastrar-salto.png (la escopeta y Johnny dando su saltito),
# captura-arrastrar-tirar.png (la zona roja con las piezas) y captura-arrastrar-baul.png (la pieza a distancia sobre el baúl).
# Deja el baúl como estaba y se cierra
func probar_arrastrar() -> void:
	var lz: Lanzables = lanzables
	var inv = inventario
	var antes := Guardado.cargar()
	mochila.clear()
	armas_guardadas.clear()
	johnny.municion.clear()
	johnny.coger("fregona")
	johnny.coger("escopeta")
	llevar_arma("bate")        # el bate a la mano y la fregona al repuesto
	llevar_arma("pistola")     # la pistola a la mano y la escopeta al repuesto
	johnny.meter_municion("balas", 30)
	mochila.append_array(["pieza_cuerpo", "pieza_cuerpo", "botiquin", "gasolina", "gasolina"])
	lz.mano = ["molotov", "granada"]
	lz.repuesto = []
	lz.tipo = "molotov"
	dar_lanzable("atraedora")     # a la mano (la tercera)
	dar_lanzable("congeladora")   # al repuesto
	johnny.vida = johnny.vida_tope() - 60
	await get_tree().create_timer(0.5).timeout
	abrir_cosas("inventario")
	await get_tree().create_timer(0.4).timeout
	var nota := func() -> String: return inv.fondo.find_child("nota", true, false).text
	var guardada := func(id: String) -> String: return "g%d" % armas_guardadas.find(id)
	var soltar := func(clave: String, a_donde: String) -> void:   # suelta donde caería, sin mover el ratón
		inv.soltar_en(clave, a_donde)
		await get_tree().process_frame
	# la escopeta (de repuesto) a la mano, de verdad: se encienden la mano, Johnny y la zona roja, y la mano crece
	await arrastrar(guardada.call("escopeta"), Vector2(346, 160), "captura-arrastrar-escopeta.png")
	print("Arrastrando la escopeta: el ratón empezó en su casilla %s · se arrastraba %s · encendidos %s · bajo el ratón «%s» (esperado: true · true · [\"luz_johnny\", \"luz_p1\", \"luz_tirar\"] · p1)" % [
		en_el_aire.casilla, en_el_aire.arrastrando, en_el_aire.luces, en_el_aire.encima])
	await get_tree().create_timer(0.06).timeout
	Captura.foto("captura-arrastrar-salto.png")
	print("Soltada en la mano: mano %s · repuesto %s · elegida %s · todo apagado %s (esperado: Escopeta · [\"fregona\", \"pistola\"] · p1 · true)" % [
		Objetos.nombre(johnny.huecos.fuego), armas_guardadas, inv.sel, inv.arrastre.is_empty() and inv.capa == null])
	# la pistola (ahora de repuesto), encima de Johnny: se la pone
	await soltar.call(guardada.call("pistola"), "johnny")
	print("La pistola en Johnny: mano %s · repuesto %s (esperado: Pistola · [\"fregona\", \"escopeta\"])" % [
		Objetos.nombre(johnny.huecos.fuego), armas_guardadas])
	# las dos piezas cuerpo a cuerpo (m0) a la zona roja, de verdad: se tira la casilla entera
	await arrastrar("m0", Vector2(773, 338), "captura-arrastrar-tirar.png")
	print("Las piezas cuerpo a cuerpo a la zona roja: encendidos %s · bajo el ratón «%s» · mochila %s (esperado: [\"luz_tirar\"] · tirar · [[\"botiquin\", 1]])" % [
		en_el_aire.luces, en_el_aire.encima, Objetos.casillas(mochila)])
	# el botiquín (ahora m0) en Johnny: se cura y el inventario sigue abierto
	var vida_antes = johnny.vida
	await soltar.call("m0", "johnny")
	print("El botiquín en Johnny: vida %s → %s · abierto «%s» · dice «%s» (esperado: sube · inventario · Te has curado...)" % [
		vida_antes, johnny.vida, inv.abierto, nota.call()])
	# la granada (l1) a una casilla vacía del repuesto (e1): pasa al repuesto
	await soltar.call("l1", "e1")
	print("La granada al repuesto: a mano %s · repuesto %s (esperado: [\"molotov\", \"atraedora\"] · [\"congeladora\", \"granada\"])" % [
		lz.mano, lz.repuesto])
	# la congeladora (e0) encima del molotov (l0): se cambian
	await soltar.call("e0", "l0")
	print("La congeladora encima del molotov: a mano %s (lanza %s) · repuesto %s (esperado: [\"congeladora\", \"atraedora\"] (congeladora) · [\"molotov\", \"granada\"])" % [
		lz.mano, lz.tipo, lz.repuesto])
	# el bate (p0) en Johnny: no se puede (ya lo lleva en la mano), vuelve a su casilla
	print("El bate se puede soltar en %s (esperado: [\"r0\", \"tirar\"])" % [inv.destinos("p0").keys()])
	await soltar.call("p0", "johnny")
	print("El bate en Johnny: mano %s (esperado: Bate)" % Objetos.nombre(johnny.huecos.cuerpo))
	# el bate en su repuesto (la fregona): se cambian
	await soltar.call("p0", "r0")
	print("El bate al repuesto: mano %s · repuesto %s (esperado: Fregona · [\"bate\", \"escopeta\"])" % [
		Objetos.nombre(johnny.huecos.cuerpo), armas_guardadas])
	# el hueco de las gasolinas a la zona roja: el hueco entero
	var u: int = johnny.huecos_municion().map(func(h): return h[0]).find("gasolina")
	await soltar.call("u%d" % u, "tirar")
	print("Las gasolinas a la zona roja: en la mochila %d (esperado: 0)" % mochila.count("gasolina"))
	# el molotov (e0) soltado en el título: vuelve sin más
	await soltar.call("e0", "")
	print("El molotov en el título: repuesto %s · a mano %s (esperado: [\"molotov\", \"granada\"] · [\"congeladora\", \"atraedora\"])" % [
		lz.repuesto, lz.mano])
	inv.cerrar()
	await get_tree().process_frame
	# el baúl: m0 la pieza a distancia (×2) y m1 las vendas; en el baúl, dos piezas especiales
	Guardado.cambiar(func(g1):
		g1.baul = {"pieza_especial": 2}
		g1.baul_equipo = [])
	mochila.append_array(["pieza_distancia", "pieza_distancia", "vendas"])
	abrir_cosas("baul")
	await get_tree().create_timer(0.4).timeout
	await arrastrar("m0", Vector2(680, 240), "captura-arrastrar-baul.png")
	print("La pieza a distancia al baúl, de verdad: encendidos %s · en el baúl %d · en la mochila %d (esperado: [\"luz_baul\"] · 2 · 0)" % [
		en_el_aire.luces, Guardado.cargar().baul.get("pieza_distancia", 0), mochila.count("pieza_distancia")])
	print("Las vendas se pueden soltar en %s (esperado: [\"baul\"])" % [inv.destinos("m0").keys()])
	await soltar.call("m0", "baul")
	print("Las vendas al baúl: en la mochila %d, en el baúl %d (esperado: 0, 1)" % [mochila.count("vendas"),
		Guardado.cargar().baul.get("vendas", 0)])
	await soltar.call("b%d" % inv.objetos_baul(Guardado.cargar()).map(func(o): return o[0]).find("pieza_especial"), "llevas")
	print("Una pieza especial fuera del baúl: en el baúl %d · en la mochila %d (esperado: 1 · 1)" % [
		Guardado.cargar().baul.get("pieza_especial", 0), mochila.count("pieza_especial")])
	await soltar.call("p0", "baul")
	print("La fregona al baúl: se puede soltar en %s · mano %s (esperado: [] · Fregona)" % [inv.destinos("p0").keys(),
		Objetos.nombre(johnny.huecos.cuerpo)])
	inv.cerrar()
	Guardado.cambiar(func(g2):
		g2.baul = antes.baul
		g2.baul_equipo = antes.baul_equipo)
	get_tree().quit()


# Arrastra con el ratón, de verdad, lo de la casilla "desde" del inventario o del baúl hasta "a" (un punto de la
# pantalla de 960×640, como en la maqueta): aprieta en la casilla, mueve el ratón en 10 pasos y suelta. En Windows, Godot
# mira dónde está el cursor de verdad al soltar, así que también se mueve el cursor (y al acabar vuelve a donde
# estaba). Justo antes de soltar apunta en en_el_aire lo que se ve (si el ratón empezó en la casilla, si se arrastra, lo
# encendido y lo que hay bajo el ratón) y, con "foto", la saca
func arrastrar(desde: String, a: Vector2, foto := "") -> void:
	var inv = inventario
	var b: Control = inv.lienzo.get_node(desde)
	var ida: Vector2 = b.get_global_rect().get_center()
	var llegada: Vector2 = inv.lienzo.get_global_transform() * (a - inv.ORIGEN)
	var ventana := get_viewport().get_screen_transform()
	var estaba := get_viewport().get_mouse_position()
	var raton := func(e: InputEventMouse, p: Vector2) -> void:
		e.position = ventana * p
		e.global_position = e.position
		Input.warp_mouse(e.position)
		Input.parse_input_event(e)
	var apretar := InputEventMouseButton.new()
	apretar.button_index = MOUSE_BUTTON_LEFT
	apretar.button_mask = MOUSE_BUTTON_MASK_LEFT
	apretar.pressed = true
	raton.call(apretar, ida)
	await get_tree().process_frame
	en_el_aire = {"casilla": get_viewport().get_mouse_position().distance_to(ida) < 2.0}
	var antes := ida
	for k in range(1, 11):
		var p := ida.lerp(llegada, k / 10.0)
		var paso := InputEventMouseMotion.new()
		paso.button_mask = MOUSE_BUTTON_MASK_LEFT
		paso.relative = ventana.basis_xform(p - antes)
		raton.call(paso, p)
		antes = p
		await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout   # (a que crezca lo de debajo)
	en_el_aire.arrastrando = get_viewport().gui_is_dragging()
	en_el_aire.luces = inv.capa.get_children().map(func(n): return String(n.name)) if is_instance_valid(inv.capa) else []
	en_el_aire.encima = inv.encima
	if foto != "":
		Captura.foto(foto)
	var dejar := InputEventMouseButton.new()
	dejar.button_index = MOUSE_BUTTON_LEFT
	dejar.pressed = false
	raton.call(dejar, llegada)
	await get_tree().process_frame
	await get_tree().process_frame
	Input.warp_mouse(ventana * estaba)


# Una acción pulsada (para pulsar_evento)
func accion(nombre: String) -> InputEventAction:
	var a := InputEventAction.new()
	a.action = nombre
	return a


# Pulsa y suelta un botón, una tecla o una acción, como si lo hiciera el jugador, y espera a que llegue
func pulsar_evento(evento: InputEvent) -> void:
	for pulsada in [true, false]:
		var e = evento.duplicate()
		e.pressed = pulsada
		Input.parse_input_event(e)
		await get_tree().process_frame
	await get_tree().process_frame


# Con "--captura --municion-suelo": los dibujos de la munición (PixelLab, 25 oct) en el suelo y en el inventario. En
# fila a la derecha de Johnny: una caja de balas y otra de cartuchos tiradas, la caja que suelta un zombi con la MP5 en
# la mano (la caja verde; cambia a la de cartuchos al sacar la escopeta), una gasolina y un bidón de ácido; debajo, un
# molotov y una granada del suelo. Fotos: captura-municion-suelo.png (con luz), captura-municion-suelo-oscuras.png (a
# oscuras se ven un poco), captura-municion-suelo-vuelo.png (un molotov lanzado, a mitad de vuelo),
# captura-municion-suelo-inventario.png y captura-municion-suelo-hud.png (el lanzallamas, con la gasolina junto a su
# barra)
func probar_municion_suelo() -> void:
	mochila.clear()
	armas_guardadas.clear()
	johnny.coger("pistola")
	johnny.coger("mp5")
	johnny.direccion = "o"   # (que la linterna no alumbre la fila)
	await get_tree().create_timer(0.5).timeout
	var donde := func(i: int) -> Vector2: return johnny.position + Vector2(130 + i * 48, 0)
	soltar_municion(donde.call(0), "balas", 12)
	soltar_municion(donde.call(1), "cartuchos", 6)
	soltar_municion(donde.call(2))
	soltar_objeto("gasolina", donde.call(3), true)
	soltar_objeto("bidon_acido", donde.call(4), true)
	soltar_lanzable("molotov", donde.call(0) + Vector2(0, 70))   # (más abajo: más lejos que el imán de Johnny)
	soltar_lanzable("granada", donde.call(1) + Vector2(0, 70))
	await get_tree().process_frame
	await get_tree().process_frame
	var cajas: Array = get_tree().get_nodes_in_group("cajas_municion")
	var del_zombi: Node2D = cajas.filter(func(c): return c.que_icono.is_valid())[0]
	del_zombi.velocidad = Vector2.ZERO   # (sale despedida: quieta en su sitio)
	del_zombi.position = donde.call(2)
	print("Cajas en el suelo: %s (esperado: municion-pistola, municion-escopeta, municion-mp5)" % [
		cajas.map(func(c): return c.icono.resource_path.get_file().get_basename())])
	await get_tree().create_timer(0.6).timeout
	Captura.foto("captura-municion-suelo.png")
	johnny.coger("escopeta")
	await get_tree().create_timer(0.1).timeout
	print("Saca la escopeta: la del zombi es ahora %s (esperado: municion-escopeta)" % del_zombi.icono.resource_path.get_file().get_basename())
	johnny.coger("mp5")
	luz.objetivo = 0.92
	await get_tree().create_timer(1.5).timeout
	Captura.foto("captura-municion-suelo-oscuras.png")
	luz.objetivo = 0.0
	await get_tree().create_timer(1.5).timeout   # (que vuelva la luz)
	lanzables.meter("molotov", 1)   # un molotov en el aire, a mitad de vuelo
	lanzables.tipo = "molotov"
	var antes: int = lanzables.cuantas("molotov")
	lanzables.lanzar(johnny.position + Vector2(220, 20))   # (hacia un lado: hacia arriba lo tapa la pared)
	await get_tree().create_timer(0.27).timeout
	var en_vuelo: Array = johnny.get_parent().get_children().filter(func(n): return "tipo" in n and n.get("tipo") == "molotov")
	print("Molotov lanzado: tenía %d y ahora %d; en vuelo: %d (esperado: uno menos y 1 en vuelo)" % [antes,
		lanzables.cuantas("molotov"), en_vuelo.size()])
	Captura.foto("captura-municion-suelo-vuelo.png")
	johnny.meter_municion("cartuchos", 12)
	mochila.append_array(["gasolina", "gasolina", "bidon_acido"])
	abrir_cosas("inventario")
	await get_tree().create_timer(0.4).timeout
	Captura.foto("captura-municion-suelo-inventario.png")
	inventario.cerrar()
	llevar_arma("lanzallamas")
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-municion-suelo-hud.png")
	get_tree().quit()


# Con "--captura --atraedora": los dibujos nuevos de la atraedora (PixelLab, 26 oct: el haz de dinamita con el
# despertador) y de la congeladora (el extintor con el temporizador de números rojos). Johnny lleva tres de cada una
# (la congeladora entra de repuesto y pasa a la mano al cambiarla por la atraedora). De cada una: una lanzada, a mitad
# de vuelo (captura-<tipo>-vuelo.png), el HUD con ella a mano (captura-<tipo>-hud.png) y el inventario con ella
# elegida (captura-<tipo>-inventario.png)
func probar_atraedora() -> void:
	johnny.direccion = "o"   # (que la linterna no alumbre la fila)
	lanzables.meter("atraedora", 3)
	lanzables.meter("congeladora", 3)
	await get_tree().create_timer(0.3).timeout
	for t in ["atraedora", "congeladora"]:
		lanzables.a_la_mano(t)   # (la congeladora, del repuesto: sin efecto si ya está a mano)
		lanzables.tipo = t
		lanzables.lanzar(johnny.position + Vector2(220, 20))   # (hacia un lado: hacia arriba lo tapa la pared)
		await get_tree().create_timer(0.27).timeout
		var en_vuelo: Array = johnny.get_parent().get_children().filter(func(n): return "tipo" in n and n.get("tipo") == t)
		print("%s lanzada: le quedan %d, en vuelo: %d (esperado: 2 y 1)" % [t, lanzables.cuantas(t), en_vuelo.size()])
		Captura.foto("captura-%s-vuelo.png" % t)
		await get_tree().create_timer(1.0).timeout
		Captura.foto("captura-%s-hud.png" % t)
		abrir_cosas("inventario")
		inventario.tocar("l%d" % lanzables.mano.find(t))
		await get_tree().create_timer(0.4).timeout
		Captura.foto("captura-%s-inventario.png" % t)
		inventario.cerrar()
		await get_tree().create_timer(1.5).timeout   # (que explote la lanzada antes de la siguiente)
	get_tree().quit()


# Los objetos de curar de las tiendas (parte 9: las vendas, Objetos.USABLES; el bocadillo se quitó del juego el 25
# oct): con la vida baja y las vendas en la mochila, saca el inventario con ellas elegidas (captura-vendas.png) y las
# usa, contando la vida antes y después; luego dice dónde salen y cuántos objetos cuenta Colecciones
func probar_curas() -> void:
	var antes := [mochila.duplicate(), johnny.vida]
	mochila = ["vendas", "pieza_cuerpo"]
	johnny.vida = roundi(johnny.vida_tope() * 0.4)
	abrir_cosas("inventario")
	inventario.tocar("m0")
	await get_tree().create_timer(0.4).timeout   # (sigue contando con el juego en pausa)
	Captura.foto("captura-vendas.png")
	for id in ["vendas"]:
		var v: int = johnny.vida
		if inventario.abierto == "":
			abrir_cosas("inventario")
		if inventario.elegido() != id:
			inventario.tocar("m0")   # el primero de la mochila: las vendas
		inventario.usar()
		print("%s: vida %d -> %d (cura %d) | mochila %s | cerrado %s" % [Objetos.nombre(id), v, johnny.vida, cura_de(id),
			mochila, inventario.abierto == ""])
	print("Curas · dónde salen las vendas: %s · Colecciones del centro: %d objetos (esperado: Supermercado y farmacia, 8)" % [
		Objetos.donde("vendas", "centro"), Objetos.de_edificio("centro").size()])
	if inventario.abierto != "":
		inventario.cerrar()   # por si alguno no se ha podido usar: que no se quede el juego en pausa
	mochila = antes[0]
	johnny.vida = antes[1]


# Con "--captura --curas": las vendas y el botiquín como objetos que se usan con su tecla (partida.usar_cura; sus
# casillas junto a la barra de vida, ui/hud.gd). Sin ninguno, las casillas no salen; con dos vendas y un botiquín y la
# vida a medias salen (captura-curas-hud.png). La tecla 1 (teclado de verdad) usa las vendas y cura 25, la 2 el
# botiquín y cura 50; con la vida llena no se gasta nada. Cómo queda en el móvil (captura-curas-movil.png). Con un solo
# tercio y lleno, las vendas no sirven y el botiquín sí: devuelve un tercio y cura (captura-curas-tercio.png); y lo que
# anda Johnny con 3, 2 y 1 tercios. En el baúl se guardan y se sacan como los demás objetos (captura-curas-baul.png). En
# un baño, el armarito se abre y suelta un botiquín (captura-curas-armarito.png) que Johnny recoge, y no cura al
# acercarse. Y al caer, la mitad de los dólares a la cartera (captura-curas-caer.png). Cada línea dice lo esperado. Se cierra
func probar_curas_rapidas() -> void:
	set_process(false)
	var antes := Guardado.cargar()
	var hud: Control = $Pantalla/HUD
	var pulsar := func(k: Key) -> void:
		for abajo in [true, false]:
			var e := InputEventKey.new()
			e.keycode = k
			e.physical_keycode = k
			e.pressed = abajo
			Input.parse_input_event(e)
		await get_tree().create_timer(0.1).timeout
	mochila.clear()
	johnny.vida = johnny.vida_tope()
	await get_tree().create_timer(0.3).timeout
	print("Curas · sin ninguna: casillas visibles %s (esperado: false)" % hud.curas.visible)
	mochila.append_array(["vendas", "vendas", "botiquin"])
	johnny.vida = roundi(johnny.vida_tope() * 0.3)
	await get_tree().create_timer(0.5).timeout
	print("Curas · con 2 vendas y un botiquín: casillas visibles %s · lo que enseña %s · teclas %s y %s (esperado: true · [[\"vendas\", 2], [\"botiquin\", 1]] · 1 y 2)" % [
		hud.curas.visible, hud.curas_llevadas(), Controles.tecla_de("usar_vendas"), Controles.tecla_de("usar_botiquin")])
	Captura.foto("captura-curas-hud.png")
	var v: int = johnny.vida
	await pulsar.call(KEY_1)
	print("Curas · la tecla 1: vida %d -> %d (esperado: +%d) · vendas %d (esperado: 1)" % [v, johnny.vida, cura_de("vendas"),
		mochila.count("vendas")])
	v = johnny.vida
	await pulsar.call(KEY_2)
	print("Curas · la tecla 2: vida %d -> %d (esperado: +%d o hasta el tope %d) · botiquín %d (esperado: 0)" % [v, johnny.vida,
		cura_de("botiquin"), johnny.vida_tope(), mochila.count("botiquin")])
	johnny.vida = johnny.vida_tope()
	await pulsar.call(KEY_1)
	print("Curas · con la vida llena la tecla 1: vendas %d (esperado: 1: no se gasta)" % mochila.count("vendas"))
	mochila.append("botiquin")
	johnny.vida = roundi(johnny.vida_tope() * 0.5)
	Tactil.activo = true   # (solo el HUD: los botones del móvil no se montan a mitad de partida)
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-curas-movil.png")
	Tactil.activo = false
	# los tercios: con uno solo y su tercio lleno, las vendas no sirven (casilla apagada) y el botiquín sí: devuelve un
	# tercio y cura
	mochila.clear()
	mochila.append_array(["vendas", "botiquin"])
	johnny.tercios = 1
	johnny.vida = johnny.vida_tope()
	await get_tree().create_timer(0.3).timeout
	print("Curas · con un tercio y lleno: sirven las vendas %s, el botiquín %s (esperado: false, true)" % [
		puede_curar("vendas"), puede_curar("botiquin")])
	Captura.foto("captura-curas-tercio.png")
	v = johnny.vida
	await pulsar.call(KEY_2)
	print("Curas · el botiquín con un tercio: tercios %d · vida %d -> %d (esperado: 2 · %d -> %d, el tope de dos tercios)" % [
		johnny.tercios, v, johnny.vida, v, mini(v + cura_de("botiquin"), johnny.vida_tope())])
	# la velocidad andando con 3, 2 y 1 tercios (LENTO_TERCIO: un 15 % menos por cada tercio perdido)
	var rapidez := []
	Input.action_press("derecha")
	for n in [3, 2, 1]:
		johnny.tercios = n
		await get_tree().create_timer(0.4).timeout
		rapidez.append(roundi(johnny.velocity.length()))
	Input.action_release("derecha")
	johnny.tercios = 3
	print("Velocidad con 3, 2 y 1 tercios: %s (esperado: %s; el zombi rápido anda a 165)" % [rapidez,
		[3, 2, 1].map(func(n): return roundi(johnny.stats.velocidad * (1.0 - johnny.LENTO_TERCIO * (3 - n))))])
	# el baúl
	mochila.clear()
	mochila.append_array(["vendas", "botiquin", "botiquin"])
	Guardado.cambiar(func(g):
		g.baul = {}
		g.baul_equipo = [])
	abrir_cosas("baul")
	await get_tree().create_timer(0.4).timeout
	var guardado_botiquin: bool = inventario.meter_en_baul("botiquin")
	var guardado_vendas: bool = inventario.meter_en_baul("vendas")
	var s := Guardado.cargar()
	print("Curas · al baúl: botiquín %s, vendas %s · en el baúl %s · en la mochila %s (esperado: true, true · botiquin 2, vendas 1 · [])" % [
		guardado_botiquin, guardado_vendas, s.baul, mochila])
	inventario.pintar()
	inventario.tocar("b%d" % inventario.objetos_baul(s).map(func(o): return o[0]).find("botiquin"))
	await get_tree().create_timer(0.3).timeout
	Captura.foto("captura-curas-baul.png")
	inventario.sacar()
	await get_tree().process_frame
	print("Curas · sacado un botiquín: en el baúl %d, en la mochila %d (esperado: 1, 1)" % [
		Guardado.cargar().baul.get("botiquin", 0), mochila.count("botiquin")])
	inventario.cerrar()
	await get_tree().process_frame
	Guardado.cambiar(func(g):
		g.baul = antes.baul
		g.baul_equipo = antes.baul_equipo)
	# el armarito de un baño: no cura, suelta un botiquín
	var bano := -1
	for j in planta.sitios.size():
		if not planta.sitios[j].get("armaritos", []).is_empty():
			bano = j
			break
	if bano < 0:
		print("Curas · no hay ningún baño en esta planta")
		get_tree().quit()
		return
	await montar(bano, 0, false)
	for z in get_tree().get_nodes_in_group("zombis"):
		z.queue_free()
	var a: Node2D = mapa.armaritos[0]
	mochila.clear()
	johnny.vida = roundi(johnny.vida_tope() * 0.4)
	v = johnny.vida
	luz.alternar()   # (sin penumbra, para que se vea el botiquín saliendo)
	await get_tree().create_timer(0.5, false).timeout
	johnny.position = a.position + Vector2(42, 50)   # (a un lado, para que no tape el botiquín al salir)
	johnny.get_node("Camara").reset_smoothing()
	await get_tree().create_timer(0.14, false).timeout
	Captura.foto("captura-curas-armarito.png")
	await get_tree().create_timer(1.0, false).timeout
	print("Curas · el armarito: abierto %s · vida %d -> %d (esperado: true · sin cambio) · botiquines en la mochila %d (esperado: 1)" % [
		a.datos.cogido, v, johnny.vida, mochila.count("botiquin")])
	# al caer, la mitad de los dólares recogidos pasa a la cartera (DOLARES_AL_CAER), con su cartel; luego se deja como estaba
	var cartera: int = Guardado.cargar().dolares
	dolares = 7
	terminar(false)
	await get_tree().create_timer(0.5).timeout
	Captura.foto("captura-curas-caer.png")
	print("Al caer con $7: la cartera %d -> %d (esperado: +4)" % [cartera, Guardado.cargar().dolares])
	Guardado.cambiar(func(g): g.dolares = cartera)
	get_tree().quit()
