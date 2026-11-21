# El antidisturbios: uno de los cuatro minijefes del centro comercial (su tienda, la Oficina de seguridad). Un
# policía zombi enorme con casco, porra y un escudo transparente. Lo común de los minijefes, en minijefe.gd.
# Rehecho el 21 nov con el plan de docs/JEFES_CENTRO.md («El muro»): el escudo es el reto, hay que romperlo.
#
# FASE 1, con escudo. Es lento y gira despacio, y el escudo le tapa por delante:
#   - De frente, las balas y los golpes rebotan en el escudo («¡CLONC!» y chispas). De lado le haces el daño
#     normal, y por la espalda, el doble. Las explosiones (granadas) y el fuego (molotov) le dan por todos lados.
#     Con el escudo entero no baja de media vida («¡EL ESCUDO AGUANTA!»): hay que rompérselo.
#   - Carga: marca una franja roja y corre en línea recta con el escudo por delante. Si pilla a Johnny le quita
#     20 y le tira; si se estrella, se queda atontado (5 s, ¡a por su espalda!). Contra las taquillas metálicas de
#     su oficina (catalogo.gd, "jefe-antidisturbios"), además, se le agrieta el escudo: a la 3ª, revienta. (Donde
#     no hay taquillas, la sala de pruebas, vale cualquier pared o mueble.)
#   - Pelotas de goma: levanta el escudo y dispara 3 en abanico (pelota_goma.gd). Rebotan por la sala sin pararse
#     y se van sumando (como mucho, MAX_PELOTAS); se rompen de un disparo.
#   - Gas lacrimógeno: tira un bote (proyectil.gd, "gas") que deja una nube que pica un rato (nube_gas.gd).
#   - Porrazo: si Johnny está cerca y delante, marca en rojo un trozo de suelo (medio segundo) y golpea: 18 y empuja.
#   - Silbato: llegan 2 refuerzos.
# Al reventar el escudo (romper_escudo): revientan todas las pelotas de goma a la vez, grita y empieza la
# FASE 2, sin escudo (es el «enfado» de los demás minijefes: aquí no llega a media vida, sino al romperlo). Ya se le
# pega igual por todos lados, pero va más deprisa y gira antes. Ya no tiene pelotas, ni silbato, ni porrazo suelto:
#   - Barrido eléctrico: golpea el suelo con la porra y salen 3 olas de chispas, una tras otra, que cruzan la sala
#     de pared a pared, cada una con su hueco en otro sitio (barrido_electrico.gd). Se pasan por el hueco o esquivando.
#   - Combo de porrazos: 3 golpes seguidos, avanzando hacia Johnny, cada uno con su aviso. El último se le queda
#     clavado en el suelo (CLAVADO s): la ventana para pegarle (le entra un 50 % más).
#   - Carga, más rápida; al estrellarse se atonta la mitad.
#   - Gas: dos botes de cada vez.
extends Minijefe

const PELOTA := preload("res://scripts/pelota_goma.gd")
const BARRIDO := preload("res://scripts/barrido_electrico.gd")
const PROYECTIL := preload("res://escenas/armas/proyectil.tscn")

const REFUERZO := "vigilante"
const REFUERZOS := 2               # cuántos llegan al silbato (solo con escudo)
const VELOCIDAD := [70.0, 95.0]    # (con escudo y sin él)
const GIRO := [1.4, 3.0]           # lo deprisa que se gira, en radianes por segundo
# El escudo: medio ángulo de lo que tapa por delante; por detrás, lo mismo es la espalda (el doble de daño)
const FRENTE := PI / 3.0
const ESPALDA := PI / 3.0
const GRIETAS := 3                 # los choques contra las taquillas que aguanta el escudo
const AVISO_PORRAZO := 0.5
const ALCANCE_PORRAZO := 115.0
const MEDIO_PORRAZO := 0.85        # medio ángulo del trozo que barre
const DANO_PORRAZO := 18
const DISTANCIA_PORRAZO := 150.0   # si Johnny está más cerca que esto (y delante), prefiere el porrazo (o el combo)
const AVISO_CARGA := 0.8
const VELOCIDAD_CARGA := [400.0, 480.0]
const TIEMPO_CARGA := 1.3          # lo que corre como mucho
const DANO_CARGA := 20
const ATONTADO := 2.0              # lo que se queda atontado al estrellarse en la azotea (en las tiendas, 5 s: minijefe.gd)
const PIE := 30.0                  # a qué altura dibuja los pies respecto a su centro
const GOLPE_PORRAZO := 4           # fotograma del porrazo en el que la porra baja
# Las pelotas de goma
const AVISO_PELOTAS := 0.6
const PELOTAS := 3                 # las de cada tanda, en abanico
const ABRE_PELOTAS := 0.35         # lo que se separan entre sí, en radianes
const VELOCIDAD_PELOTA := 300.0   # (21 nov: 240 iba algo lenta)
const MAX_PELOTAS := 9             # con estas por la sala, no dispara más
const ESPERA_PELOTAS := 4.5
# El gas
const AVISO_GAS := 0.45
const BOTES := [1, 2]
const ESPERA_GAS := [7.0, 5.5]
# El barrido eléctrico (fase 2)
const AVISO_BARRIDO := 0.7
const OLAS := 5
const ENTRE_OLAS := 1.4            # lo que tarda en salir cada ola tras la anterior
const ESPERA_BARRIDO := 7.0
# El combo de porrazos (fase 2)
const AVISO_COMBO := [0.5, 0.32, 0.32]   # el aviso de cada golpe
const DANO_COMBO := 16
const ESTOCADA := 260.0            # lo que avanza entre golpe y golpe
const CLAVADO := 1.8               # lo que se le queda clavada la porra tras el tercero
const CLAVADO_DANO := 1.5          # lo que le entra de más mientras tanto
const ESPERA_COMBO := 2.5

var espera_porrazo := 1.0
var espera_carga := 2.5
var espera_silbato := 5.0
var espera_pelotas := 2.0
var espera_gas := 4.0
var espera_barrido := 1.0
var espera_combo := 0.0
var clonc_t := 0.0                 # para no llenar la pantalla de «¡CLONC!» con los perdigones de la escopeta
var aguanta_t := 0.0               # para no repetir mucho «¡EL ESCUDO AGUANTA!»
var escudo := true
var grietas := 0


func _ready() -> void:
	super()
	enfado = -1.0   # (no se enfada a media vida: «se enfada» al romperle el escudo, romper_escudo)


func pensar(delta: float, johnny: Node2D) -> void:
	for e in ["espera_porrazo", "espera_carga", "espera_silbato", "espera_pelotas", "espera_gas", "espera_barrido",
			"espera_combo", "clonc_t", "aguanta_t"]:
		set(e, get(e) - delta)
	var hacia: Vector2 = johnny.global_position - global_position
	var d := hacia.length()
	match estado:
		"andar":
			# solo anda hacia delante: para ir hacia Johnny tiene que girarse (y se gira despacio)
			var quiere := camino_a(johnny)
			girar_hacia(delta, quiere)
			var alineado := maxf(0.0, mirada.dot(quiere))
			var v: float = VELOCIDAD[fase - 1]
			marcha += (mirada * v * (0.25 + 0.75 * alineado) - marcha) * (1.0 - exp(-delta * 6.0))
			if t >= dur:
				elegir(johnny, d, absf(angle_difference(mirada.angle(), hacia.angle())))
		"aviso_porrazo":
			frenar(delta)
			if t >= AVISO_PORRAZO:
				cambiar("porrazo", {"angulo": datos.angulo})
				porrazo(johnny, datos.angulo, DANO_PORRAZO, 650.0)
		"porrazo":
			frenar(delta)
			if t >= 0.4:
				andar(0.9)
		"aviso_carga":
			# se agacha detrás del escudo y se va girando hacia Johnny (la franja roja marca por dónde irá)
			frenar(delta, 6.0)
			girar_hacia(delta, hacia.normalized())
			if t >= AVISO_CARGA:
				cambiar("carga", {"desde": global_position})
				Sonido.tocar("rugido")
		"carga":
			cargar(delta, johnny)
		"atontado":
			frenar(delta, 4.0)
			var dura := tiempo_atontado(ATONTADO) * (1.0 if escudo else 0.5)
			if t >= datos.get("dura", dura):
				andar(0.4)
		"recuperar":
			frenar(delta, 5.0)
			if t >= datos.dur:
				andar(0.9 if escudo else 0.5)
		"silbato":
			frenar(delta)
			if t >= 0.5 and not datos.get("hecho", false):
				datos.hecho = true
				llamar(REFUERZO, REFUERZOS, 120.0)
			if t >= 1.0:
				andar(0.5)
		"aviso_pelotas":
			frenar(delta)
			girar_hacia(delta, hacia.normalized())
			if t >= AVISO_PELOTAS:
				disparar_pelotas()
				cambiar("recuperar", {"dur": 0.4})
		"aviso_gas":
			frenar(delta)
			if t >= AVISO_GAS:
				tirar_gas(johnny)
				cambiar("recuperar", {"dur": 0.35})
		"aviso_barrido":
			frenar(delta)
			girar_hacia(delta, hacia.normalized())
			if t >= AVISO_BARRIDO:
				barrer(johnny)
				cambiar("recuperar", {"dur": 0.6})
		"aviso_combo":
			# entre golpe y golpe se gira hacia Johnny, deprisa
			frenar(delta, 8.0)
			girar_hacia(delta * 2.0, hacia.normalized())
			if t >= AVISO_COMBO[datos.golpe]:
				cambiar("combo", {"golpe": datos.golpe, "angulo": mirada.angle()})
				marcha = mirada * ESTOCADA   # (da un paso adelante con cada porrazo)
				porrazo(johnny, mirada.angle(), DANO_COMBO, 450.0)
		"combo":
			frenar(delta, 7.0)
			if t >= 0.22:
				if datos.golpe < AVISO_COMBO.size() - 1:
					cambiar("aviso_combo", {"golpe": datos.golpe + 1})
				else:
					clavar_porra()
		"clavado":
			frenar(delta, 10.0)
			if randf() < delta * 14.0:
				Particulas.soltar(self, global_position + mirada * 70.0 + Vector2(0, PIE), Vector2(randf_range(-60, 60), -60),
					Color("#5fd3ff"), 3, 0.3)
			if t >= CLAVADO:
				andar(0.4)


func girar_hacia(delta: float, hacia: Vector2) -> void:
	if hacia == Vector2.ZERO:
		return
	var paso: float = GIRO[fase - 1] * delta
	mirada = mirada.rotated(clampf(angle_difference(mirada.angle(), hacia.angle()), -paso, paso))


func elegir(johnny: Node2D, d: float, desvio: float) -> void:
	if escudo:
		elegir_con_escudo(johnny, d, desvio)
	else:
		elegir_sin_escudo(johnny, d, desvio)


func elegir_con_escudo(_johnny: Node2D, d: float, desvio: float) -> void:
	if d < DISTANCIA_PORRAZO and desvio < 0.9 and espera_porrazo <= 0.0:
		espera_porrazo = 1.5
		cambiar("aviso_porrazo", {"angulo": mirada.angle()})
		return
	# el silbato (si no quedan ya muchos zombis por ahí)
	if espera_silbato <= 0.0 and secuaces() <= REFUERZOS:
		espera_silbato = 13.0
		cambiar("silbato")
		Sonido.tocar("silbato")
		gritar(Idioma.t("¡PRIIIII!"), Color("#bfe9ff"))
		return
	if d > 170.0 and desvio < 0.7 and espera_carga <= 0.0 and carga_libre(_johnny):
		espera_carga = 3.5
		cambiar("aviso_carga")
		gritar(Idioma.t("¡ATRÁS!"), Color("#ff5d73"))
		return
	if espera_pelotas <= 0.0 and desvio < 1.2 and pelotas().size() + PELOTAS <= MAX_PELOTAS:
		espera_pelotas = ESPERA_PELOTAS
		cambiar("aviso_pelotas")
		return
	if espera_gas <= 0.0 and d > 120.0:
		espera_gas = ESPERA_GAS[0]
		cambiar("aviso_gas")
		return
	# nada a mano: sigue andando un poco y vuelve a mirar
	andar(0.3)


func elegir_sin_escudo(_johnny: Node2D, d: float, desvio: float) -> void:
	if d < DISTANCIA_PORRAZO + 20.0 and espera_combo <= 0.0:
		espera_combo = ESPERA_COMBO
		cambiar("aviso_combo", {"golpe": 0})
		return
	if espera_barrido <= 0.0:
		espera_barrido = ESPERA_BARRIDO
		cambiar("aviso_barrido")
		gritar(Idioma.t("¡ATRÁS!"), Color("#5fd3ff"))
		return
	if d > 170.0 and desvio < 0.7 and espera_carga <= 0.0 and carga_libre(_johnny):
		espera_carga = 2.5
		cambiar("aviso_carga")
		Sonido.tocar("rugido")
		return
	if espera_gas <= 0.0 and d > 120.0:
		espera_gas = ESPERA_GAS[1]
		cambiar("aviso_gas")
		return
	andar(0.25)


# Un porrazo: daña y empuja a Johnny si está dentro del trozo marcado (y no hay una pared o un mueble en medio)
func porrazo(johnny: Node2D, angulo: float, dano: int, empuje: float) -> void:
	Sonido.tocar("porrazo")
	var hacia: Vector2 = johnny.global_position - global_position
	var desvio := absf(angle_difference(hacia.angle(), angulo))
	if hacia.length() - johnny.RADIO <= ALCANCE_PORRAZO and desvio <= MEDIO_PORRAZO + 0.15 \
			and not Aviso.tapado(self, johnny.global_position):
		johnny.recibir_dano(dano, self)
		johnny.empujar(hacia.normalized() * empuje)


# La carga: corre en línea recta con el escudo por delante (lo común, en minijefe.gd). Si pilla a Johnny, le
# tira; si se estrella, se atonta (y, contra una taquilla, se le agrieta el escudo)
func cargar(delta: float, johnny: Node2D) -> void:
	if not datos.has("desde"):
		datos.desde = global_position   # (de dónde sale, para saber cuánto lleva corrido)
	var como := embestir(delta, johnny, VELOCIDAD_CARGA[fase - 1], DANO_CARGA, TIEMPO_CARGA, PIE)
	# una taquilla, aunque sea rozándola de lado, también le para (como los muros): si no, resbalaba por su lado
	if como == "" and t > 0.05 and toca_taquilla():
		como = "pared"
	# hasta haber corrido la mitad, no se estrella (21 nov, el dueño: se golpeaba nada más empezar): si roza algo, sigue;
	# si se ha comido algo de frente y no puede seguir, frena sin más (ni atontado ni grieta)
	if como == "pared" and global_position.distance_to(datos.get("desde", global_position)) < media_carga():
		como = "fin" if get_real_velocity().length() < VELOCIDAD_CARGA[fase - 1] * 0.4 else ""
	match como:
		"pillado":
			cambiar("recuperar", {"dur": 0.6})
		"pared":
			var taquilla := contra_taquilla()
			estrellarse()
			if escudo and taquilla:
				agrietar()
		"fin":
			marcha *= 0.3
			cambiar("recuperar", {"dur": 0.5})


# La mitad de lo que corre en una carga: antes de eso no se estrella, y no empieza una carga con algo más cerca
func media_carga() -> float:
	return VELOCIDAD_CARGA[fase - 1] * TIEMPO_CARGA / 2.0


# Si puede cargar hacia Johnny: sin nada en medio (pared o mueble) en la primera mitad de la carga
func carga_libre(johnny: Node2D) -> bool:
	var hacia := global_position.direction_to(johnny.global_position)
	return not test_move(global_transform, hacia * media_carga())


# ¿Se ha estrellado contra una taquilla? Donde no hay ninguna (la sala de pruebas), vale cualquier choque
func contra_taquilla() -> bool:
	var hay := get_tree().get_nodes_in_group("muebles").any(func(m): return m.datos.get("tipo", "") == "lockers")
	return toca_taquilla() if hay else true


# Si en este paso ha tocado una taquilla
func toca_taquilla() -> bool:
	for i in get_slide_collision_count():
		var otro := get_slide_collision(i).get_collider()
		if otro is Node and (otro as Node).is_in_group("muebles") and otro.datos.get("tipo", "") == "lockers":
			return true
	return false


# El escudo se agrieta; a la última grieta, revienta
func agrietar() -> void:
	grietas += 1
	Sonido.tocar("cristal")
	var donde := global_position + mirada * (radio + 6.0) + Vector2(0, -arriba * 0.45)
	for i in 8:
		Particulas.soltar(self, donde, Vector2.from_angle(randf() * TAU) * randf_range(60, 160), Color("#bfe9ff"), 3, 0.4)
	if grietas >= GRIETAS:
		romper_escudo()
	else:
		Zombi.texto_flotante(get_parent(), donde + Vector2(-30, -40), Idioma.t("¡CRAC!"), Color("#bfe9ff"), 22)


# ¡Se acabó el escudo! Revientan las pelotas de goma, grita y empieza la fase 2 (el «enfado» de minijefe.gd)
func romper_escudo() -> void:
	escudo = false
	Temblor.temblar(12.0)
	var donde := global_position + mirada * (radio + 6.0) + Vector2(0, -arriba * 0.45)
	for i in 22:
		Particulas.soltar(self, donde, Vector2.from_angle(randf() * TAU) * randf_range(90, 260),
			Color("#ffffff") if i % 3 == 0 else Color("#bfe9ff"), 4, 0.6)
	for p in pelotas():
		p.reventar()
	Sonido.tocar("explosion")
	fase = 2
	cambiar("grito")
	var johnny := get_tree().get_first_node_in_group("jugador")
	if johnny:
		al_enfadarse(johnny)
	if vapor:
		rabia.chorro()
	espera_barrido = 1.5
	espera_combo = 0.0


func pelotas() -> Array:
	return get_tree().get_nodes_in_group("pelotas_goma")


# Las pelotas de goma: 3 en abanico hacia donde mira, desde el escudo
func disparar_pelotas() -> void:
	Sonido.tocar("disparo_zombi")
	for i in PELOTAS:
		var a := mirada.angle() + (i - (PELOTAS - 1) / 2.0) * ABRE_PELOTAS
		var p := PELOTA.new()
		p.velocidad = Vector2.from_angle(a) * VELOCIDAD_PELOTA
		p.dueno = self
		p.position = position + mirada * (radio + 12.0)
		get_parent().add_child(p)


# El gas: uno o dos botes hacia Johnny (el segundo, a un lado de él)
func tirar_gas(johnny: Node2D) -> void:
	Sonido.tocar("lanzar")
	for i in BOTES[fase - 1]:
		var p := PROYECTIL.instantiate()
		p.tipo = "gas"
		p.desde = global_position + mirada * 30.0
		p.alto_salida = arriba * 0.6
		var lado := Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * 140.0
		p.hasta = NavigationServer2D.map_get_closest_point(agente.get_navigation_map(),
			johnny.global_position + johnny.velocity * 0.4 + lado)
		p.dueno = self
		get_parent().add_child(p)


# El barrido eléctrico: las olas salen de donde está, hacia Johnny (a lo ancho o a lo alto de la sala)
func barrer(johnny: Node2D) -> void:
	Sonido.tocar("porrazo")
	Temblor.temblar(6.0)
	var b := BARRIDO.new()
	b.dir = global_position.direction_to(johnny.global_position)
	b.dueno = self
	for i in OLAS:
		b.olas.append({"sale": i * ENTRE_OLAS})
	b.position = position
	get_parent().add_child(b)


# El tercer porrazo del combo se le queda clavado en el suelo: la ventana para pegarle
func clavar_porra() -> void:
	cambiar("clavado")
	Temblor.temblar(5.0)
	Sonido.tocar("chisporroteo")


func al_enfadarse(johnny: Node2D, _grito := "") -> void:
	super(johnny, Idioma.t("¡QUEDAS DETENIDO!"))


# En la foto de la prueba (--captura): preparando la carga
func foto(_johnny: Node2D) -> void:
	cambiar("aviso_carga")


# ── El escudo ──

# Con escudo: por delante no le pasa nada (salvo las explosiones y el fuego, que llegan sin dirección o "de lleno");
# por la espalda, el doble. Sin escudo, lo normal (y, con la porra clavada, más)
func danar(cantidad: int, fuerza: Vector2, de_lleno: bool) -> int:
	if not escudo:
		return roundi(cantidad * CLAVADO_DANO) if estado == "clavado" else cantidad
	if de_lleno or fuerza == Vector2.ZERO:
		return cantidad
	var dif := absf(angle_difference(mirada.angle(), (-fuerza).angle()))
	if dif < FRENTE:
		clonc(fuerza)
		return 0
	if dif > PI - ESPALDA:
		return cantidad * 2
	return cantidad


# Con el escudo entero no baja de media vida: hay que rompérselo
func quitar_vida(cantidad: int, fuerza: Vector2) -> void:
	if not escudo:
		super(cantidad, fuerza)
		return
	var limite := ceili(vida_max * 0.5)
	cantidad = mini(cantidad, vida - limite)
	if cantidad <= 0:
		if aguanta_t <= 0.0:
			aguanta_t = 3.0
			gritar(Idioma.t("¡EL ESCUDO AGUANTA!"), Color("#bfe9ff"), 20)
		return
	super(cantidad, fuerza)
	if vida < limite:   # (un crítico puede pasarse: se queda en la mitad)
		vida = limite
		vida_cambiada.emit(vida, vida_max)


func clonc(fuerza: Vector2) -> void:
	var donde := global_position + mirada * (radio + 6.0) + Vector2(0, -arriba * 0.45)
	for i in 6:
		var v := (-fuerza.normalized()).rotated(randf_range(-1.0, 1.0)) * randf_range(90.0, 200.0)
		Particulas.soltar(self, donde, v, Color("#fff3a8") if i % 2 else Color("#ffffff"), 3, 0.25)
	if clonc_t <= 0.0:
		clonc_t = 0.25
		Zombi.texto_flotante(get_parent(), donde + Vector2(-34, -30), Idioma.t("¡CLONC!"), Color("#bfe9ff"), 18)
		Sonido.tocar("clonc")


# ── Dibujo ──

func animar() -> void:
	var dir := direccion()
	sprite.position = Vector2(0, PIE)
	match estado:
		"aviso_porrazo", "aviso_gas", "aviso_barrido":
			var dura: float = {"aviso_porrazo": AVISO_PORRAZO, "aviso_gas": AVISO_GAS, "aviso_barrido": AVISO_BARRIDO}[estado]
			fijar("porrazo", dir, mini(GOLPE_PORRAZO - 1, int(t / dura * GOLPE_PORRAZO)))
			if estado == "aviso_barrido":
				sprite.position.x = sin(tiempo * 40.0) * 1.5   # (la porra echa chispas: tiembla)
		"aviso_combo":
			fijar("porrazo", dir, mini(GOLPE_PORRAZO - 1, int(t / AVISO_COMBO[datos.golpe] * GOLPE_PORRAZO)))
		"porrazo", "combo":
			var resto := sprite.sprite_frames.get_frame_count("porrazo_" + dir) - GOLPE_PORRAZO
			fijar("porrazo", dir, GOLPE_PORRAZO + clampi(int(t / 0.4 * resto), 0, maxi(0, resto - 1)))
		"clavado":
			fijar("porrazo", dir, sprite.sprite_frames.get_frame_count("porrazo_" + dir) - 1)
			sprite.position.x = sin(tiempo * 30.0) * 1.0
		"aviso_carga", "aviso_pelotas":
			var dura := AVISO_CARGA if estado == "aviso_carga" else AVISO_PELOTAS
			fijar("carga", dir, avance("carga_" + dir, t / dura))
		"carga":
			# corriendo: su animación de andar, muy deprisa, con zancadas (un pequeño bote). La de "carga" es solo
			# agacharse tras el escudo (el aviso): quieta en su último fotograma parecía que iba flotando (21 nov)
			poner("andar_" + dir, 3.0)
			sprite.position.y = PIE - absf(sin(tiempo * 16.0)) * 3.0
		"atontado":
			fijar("golpe", dir, avance("golpe_" + dir, t / 0.5))
			sprite.position.x = sin(tiempo * 9.0) * 2.0
		"silbato":
			fijar("silbato", "s", avance("silbato_s", t / 1.0))
		"grito":
			fijar("quieto", "s", 0)
			sprite.position.x = sin(tiempo * 50.0) * 2.0
		_:
			if marcha.length() > 8.0:
				poner("andar_" + dir, clampf(marcha.length() / VELOCIDAD[fase - 1], 0.4, 1.5))
			else:
				poner("reposo_" + dir)


func morir() -> void:
	for p in pelotas():
		p.romper()
	super()
	# mientras no tenga su animación de muerte (solo la vista quieta), cae de lado
	if sprite.sprite_frames.get_frame_count(sprite.animation) == 1:
		create_tween().tween_property(sprite, "rotation", PI / 2.0 * signf(mirada.x + 0.01), 0.4)


# Los avisos, en el suelo (por debajo de él)
func _draw() -> void:
	if estado == "muerto":
		return
	var a := mirada.angle()
	# (hasta el 21 nov, un arco azulado a sus pies marcaba lo que tapa el escudo, y unas rayas blancas encima, sus
	# grietas: el dueño no los quería. Las grietas se ven en el «¡CRAC!» y las chispas al chocar)
	match estado:
		"aviso_porrazo":
			Aviso.golpe(self, Vector2(0, 6), datos.angulo, MEDIO_PORRAZO, ALCANCE_PORRAZO,
				minf(1.0, t / AVISO_PORRAZO), tiempo)
		"aviso_combo":
			Aviso.golpe(self, Vector2(0, 6), a, MEDIO_PORRAZO, ALCANCE_PORRAZO,
				minf(1.0, t / AVISO_COMBO[datos.golpe]), tiempo)
		"aviso_carga":
			franja(VELOCIDAD_CARGA[fase - 1] * TIEMPO_CARGA, minf(1.0, t / AVISO_CARGA))
		"aviso_pelotas":
			for i in PELOTAS:
				var ai := a + (i - (PELOTAS - 1) / 2.0) * ABRE_PELOTAS
				Aviso.disparo(self, Vector2(0, 6), ai, 260.0, 8.0, minf(1.0, t / AVISO_PELOTAS), tiempo, i)
		"aviso_barrido":
			# un corro de chispas a sus pies que crece: de ahí salen las olas
			Aviso.golpe(self, Vector2(0, 6), a, PI, 90.0, minf(1.0, t / AVISO_BARRIDO), tiempo)
