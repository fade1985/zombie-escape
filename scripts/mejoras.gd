# Los atributos de Johnny al empezar un edificio (baseStats de src/upgrades.js del JS).
# Johnny los lleva en "stats" y los lee al moverse, atacar y recibir golpes. Los de ataque multiplican los
# números del arma que lleve. Los talentos (talentos.gd), los objetos y las mutaciones los cambian.
class_name Mejoras


static func base() -> Dictionary:
	return {
		"vida_max": 100,
		"dano": 1.0,             # x daño del arma
		"ritmo": 1.0,            # x velocidad de ataque del arma
		"alcance": 1.0,          # x alcance del arma
		"alcance_cuerpo": 1.0,   # x alcance extra de las armas cuerpo a cuerpo
		"velocidad_bala": 1.0,   # x velocidad de las balas
		"critico": 0.05,         # probabilidad de que un golpe o una bala haga el doble de daño
		"dano_recibido": 1.0,    # x daño que recibes (menos es mejor)
		"velocidad": 210.0,      # unidades por segundo
		"iman": 120.0,           # radio en el que los billetes vienen hacia ti
		"esquiva_espera": 0.9,   # segundos que tarda en recargarse la esquiva
		# Del árbol de talentos
		"dano_cuerpo": 1.0,      # x daño cuerpo a cuerpo (Camorrista)
		"dano_fuego": 1.0,       # x daño con armas de fuego (Tirador)
		"dano_lanzar": 1.0,      # x daño del molotov y la granada (Puntería)
		"alcance_lanzar": 1.0,   # x lo lejos que se lanzan (Puntería)
		"lanzar_extra": 0,       # molotovs y granadas de más (Artificiero)
		"mirilla": false,        # cada 3 disparos, el siguiente es crítico (Mirilla)
		"fabricante": false,     # fuego y explosiones más grandes (Fabricante)
		"regenera": 0,           # vida que recuperas cada 5 s (Lobezno)
		"armadura": 0,           # daño que se le quita a cada golpe (Durito)
		"esquiva_sola": 0,       # cada cuántos segundos esquivas solo un golpe; 0 = nunca (Reflejos)
		"botiquin_extra": 0,     # vida de más que curan los botiquines (Sanitario)
		"escudo": 0,             # escudo al empezar cada planta (Acero)
		"ninja": false,          # golpe en área al acabar la esquiva (Ninja)
		"resucitar": false,      # resucitar una vez por edificio (Desfibrilador)
		"dano_quimico": 1.0,     # x daño de fuego, ácido, rayo y frío (Catalizador; se suma como los demás)
		"resiste_quimico": 0.0,  # parte que se quita al daño de los charcos y los estados (Guantes de goma)
		"arde_extra": 0.0,       # segundos de más que arden los zombis que prendes (Incendiario)
		"corroe_extra": 0.0,     # lo que el ácido les come de más la armadura (Desatascador)
		"congeladoras": 0,       # congeladoras de más al empezar y en la mochila (Criogenia)
		"congela_extra": 0.0,    # segundos de más que dejan quietos (Criogenia)
		"reaccion": false,       # los que mueren ardiendo revientan y prenden (Reacción en cadena)
		"residuo": false,        # los que mueren con ácido dejan un charco (Residuo tóxico)
		"pararrayos": false,     # rayo al que te golpea (Pararrayos)
		# De las mutaciones: solo duran la partida
		"canibal": 0.0,          # parte de la vida que cura cada zombi que matas (Caníbal)
		"ansiedad": false,       # golpes más rápidos cuantos más zombis a la vista (Ansiedad)
		"escudo_mut": 0,         # escudo de más en cada planta (Endurecimiento)
	}


# Un atributo de Johnny, para quien no lo lleva a mano (los zombis, el ácido): el de base si no hay Johnny
static func de_johnny(arbol: SceneTree, clave: String) -> Variant:
	var johnny := arbol.get_first_node_in_group("jugador")
	return johnny.stats[clave] if johnny and johnny.get("stats") else base()[clave]
