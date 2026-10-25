# La llamarada del lanzallamas de Johnny (Armas.CREADAS.lanzallamas): mientras se ataca, un chorro de fuego fijo que
# sale de la boca del tubo, estrecho, y se abre en cono hasta su alcance (las paredes y los muebles lo cortan).
# Quema a todos los zombis que pilla dentro, uno detrás de otro: cada TICK les quita su parte del daño por segundo y
# los deja ardiendo, y uno de cada EMPUJA pellizcos (cada medio segundo) los empuja un poco. Solo a los zombis: ni a
# Johnny, ni a los que le acompañan, ni deja fuego en el suelo. Al jefe de bomberos no le hace nada (inmune_fuego).
#
# Va de hija de Johnny. Johnny la mantiene encendida llamando a mantener() en cada paso en que echa fuego (johnny.gd,
# echar_fuego); el paso en que no la llama, se apaga sola. Como la bala, la llama "de verdad" va por el suelo (desde
# debajo de la boca) y se dibuja más arriba: sale a la altura de la boca y va bajando hasta el cuerpo de los zombis.
# El dibujo lo hace su shader (escenas/armas/llamarada.gdshader): fuego en pixel art, con las bocanadas y los colores
# (sin humo). Aquí, además, las chispas que saltan, la luz que alumbra alrededor mientras sale (más en los sitios
# oscuros) y el apagado: al soltar, la llama se despega de la boca y se va (CRECE, APAGA).
#
# El lanza ácido (Armas.CREADAS.desintegrador, efecto "acido") echa por aquí su chorro, igual de largo y con el mismo
# cono: lo que cambia es el dibujo (escenas/armas/chorro_acido.gdshader: un chorro de manguera de bomberos, verde),
# el sonido (un siseo de agua a presión), que no alumbra, que en vez de chispas suelta gotitas que caen (y salpican
# contra la pared) y que, en vez de prenderlos, deja a los zombis la herida de ácido (ArmasCreadas.herir). Como no es
# fuego, al jefe de bomberos también le quita vida.
class_name Llamarada
extends Node2D

const TICK := 0.25          # cada cuánto quita vida a los que están dentro
const EMPUJA := 2           # empuja uno de cada tantos pellizcos (cada medio segundo)
const ABRE := 0.2           # cuánto se abre el cono a cada lado (radianes, unos 11°): a 10 casillas, 70 de ancho a cada lado
const ABRE_ACIDO := 0.13    # el chorro del lanza ácido, más estrecho (unos 7°: a 10 casillas, 48 a cada lado), como se ve
const BOCA := 6.0           # medio ancho de la llama en la boca
const ALTURA := 50.0        # a qué altura sale de la boca (como la bala)
const ALTURA_CUERPO := 26.0 # y a cuál llega al final
const CRECE := 0.12         # lo que tarda en estirarse hasta su alcance al encenderla
const APAGA := 0.22         # y lo que tarda en irse al apagarla (se despega de la boca y se aleja)
const EMPUJE := 170.0       # empuje base, como el de las balas
const SOMBREADO := preload("res://escenas/armas/llamarada.gdshader")
const SOMBREADO_ACIDO := preload("res://escenas/armas/chorro_acido.gdshader")
const CHISPAS := 22.0       # chispas que saltan por segundo
const GOTITAS := 26.0       # el ácido: gotitas que se escapan del final del chorro por segundo (contra la pared, el doble)
const VERDES := [Color("#ecf896"), Color("#c7e04a"), Color("#96b430")]   # las del chorro (chorro_acido.gdshader)
const LUZ := Color(1.0, 0.6, 0.28)
const ATRAS := 2.0          # el dibujo empieza un poquito por detrás de la boca: así sale pegada al tubo
const DOBLEZ := 32.0        # en cuánto se dobla desde la dirección del tubo hacia el zombi (en la pantalla)
const GIRO_MAX := PI / 3.0  # lo más que se dobla (60°)

var pedida := false         # se ha pedido fuego en este paso (mantener)
var acido := false          # es el chorro del lanza ácido (lo dice el arma, en mantener)
var encendida := false
var angulo := 0.0
var alcance := 320.0
var dps := 0.0
var empuje := 0.0
var quema := 1.0
var tope := 0.0             # hasta dónde llega, por el suelo: su alcance o la pared
var largo := 0.0            # hasta dónde llega la punta que se ve (crece al encenderla)
var cola := 0.0             # desde dónde se ve (al apagarla se despega de la boca y va hacia la punta)
var luz: PointLight2D
var tick_t := TICK          # (empieza lleno: el primer pellizco, en cuanto sale)
var ticks := 0
var tiempo := 0.0
var giro := 0.0             # lo que se tuerce al salir: del eje del chorro a la dirección del tubo (radianes)
var doblez := DOBLEZ


func _ready() -> void:
	z_index = 4   # por encima de Johnny y de los zombis, como el bumerán
	var propio := ShaderMaterial.new()
	propio.shader = SOMBREADO   # (unshaded: el fuego luce por sí mismo)
	material = propio
	luz = PointLight2D.new()
	luz.texture = Luz.TEXTURA
	luz.color = LUZ
	luz.range_item_cull_mask = Luz.TODAS
	add_child(luz)
	visible = false


# Johnny echa fuego en este paso: "desde", el suelo debajo de la boca; "a", hacia dónde; "w", su arma (arma()); "cano",
# hacia dónde apunta el tubo en el dibujo (solo hay 8 direcciones); "blanco", el zombi al que apunta (su sitio en el
# suelo; Vector2.INF si no hay ninguno).
# Con un zombi, el chorro va de la boca a su cuerpo (no paralelo a la línea que sale del centro de Johnny, que con la
# boca a un lado pasaría junto a él): en la pantalla, de la boca al cuerpo, que se dibuja ALTURA_CUERPO por encima de
# su sitio. Como el tubo solo apunta a 8 sitios y el zombi puede estar en cualquiera, el chorro sale hacia donde apunta
# el tubo y se dobla enseguida hacia el zombi ("giro"; lo dibuja el shader), como el agua de una manguera al moverla
func mantener(desde: Vector2, a: float, w: Dictionary, cano := a, blanco := Vector2.INF) -> void:
	pedida = true
	global_position = desde
	alcance = w.alcance
	var u := Vector2.from_angle(a)
	var baja := Vector2(0, (ALTURA - ALTURA_CUERPO) / alcance)   # lo que baja en la pantalla por cada unidad de suelo
	var eje := (u + baja).normalized()   # hacia dónde va en la pantalla
	doblez = DOBLEZ
	if blanco != Vector2.INF:
		var hasta := blanco - Vector2(0, ALTURA_CUERPO) - (desde - Vector2(0, ALTURA))   # de la boca al cuerpo
		eje = hasta.normalized()
		doblez = clampf(hasta.length() / 3.0, 4.0, DOBLEZ)   # (con el zombi cerca, se dobla antes)
		# la dirección por el suelo que, con lo que baja, se ve así: u + baja tiene que ir por el eje, con u de largo 1
		var e := eje.dot(baja)
		u = (e + sqrt(e * e + 1.0 - baja.length_squared())) * eje - baja
	angulo = u.angle()
	giro = clampf(angle_difference(eje.angle(), cano), -GIRO_MAX, GIRO_MAX)
	dps = w.dano
	empuje = w.empuje
	quema = w.get("quema", 1.0)
	if acido != (w.get("efecto", "") == "acido"):
		acido = not acido
		(material as ShaderMaterial).shader = SOMBREADO_ACIDO if acido else SOMBREADO


func _physics_process(delta: float) -> void:
	encendida = pedida
	pedida = false
	tiempo += delta
	if encendida:
		tope = medir()
		cola = 0.0
		largo = minf(largo + alcance / CRECE * delta, tope)
		Sonido.tocar("chorro_acido" if acido else "llamarada")
		# el reloj de los pellizcos solo corre con la llama encendida (soltar y volver a pulsar no quema más deprisa)
		tick_t += delta
		if tick_t >= TICK:
			tick_t -= TICK
			quemar()
		if acido:
			gotitas(delta)
		else:
			chispas(delta)
	elif largo > 0.0:
		cola += alcance / APAGA * delta
		if cola >= largo:
			largo = 0.0
			cola = 0.0
	visible = largo > 0.0
	pintar()


# Hasta dónde llega la llama por el suelo: su alcance o, si antes hay una pared o un mueble, hasta ahí. Si la boca
# queda al otro lado de una pared (Johnny pegado a ella), nada
func medir() -> float:
	var espacio := get_world_2d().direct_space_state
	var johnny: Node2D = get_parent()
	if not espacio.intersect_ray(PhysicsRayQueryParameters2D.create(johnny.global_position, global_position, 1)).is_empty():
		return 0.0
	var fin := global_position + Vector2.from_angle(angulo) * alcance
	var choque := espacio.intersect_ray(PhysicsRayQueryParameters2D.create(global_position, fin, 1))
	return alcance if choque.is_empty() else global_position.distance_to(choque.position)


# Un pellizco a todos los zombis que están dentro de la llama (y, uno de cada EMPUJA, con empujón). El ácido, en vez
# de prenderlos, les deja la herida de ácido; y al jefe de bomberos sí le hace daño, pero por el golpe (su herir() es
# el de las llamas de los charcos, que no le quita vida), y sin la herida (que también le llegaría por herir())
func quemar() -> void:
	ticks += 1
	var johnny: Node2D = get_parent()
	var u := Vector2.from_angle(angulo)
	var empuja := ticks % EMPUJA == 1
	johnny.oir_disparo()   # el fuego se oye: despierta a los que duermen cerca
	for zombi in get_tree().get_nodes_in_group("zombis"):
		if not dentro(zombi, johnny, u):
			continue
		if acido:
			var da: int = johnny.con_critico(dps * TICK)
			if empuja or zombi.get("inmune_fuego"):
				zombi.recibir_golpe(da, u * EMPUJE * empuje if empuja else Vector2.ZERO)
			else:
				zombi.herir(da, ArmasCreadas.EFECTOS.acido.color)
			if not zombi.get("inmune_fuego"):
				ArmasCreadas.herir(zombi, "acido", da)
			continue
		if zombi.get("inmune_fuego"):
			zombi.prender()   # al jefe de bomberos el fuego no le hace nada
			continue
		var d: int = johnny.con_critico(dps * TICK)
		if empuja:
			zombi.recibir_golpe(d, u * EMPUJE * empuje)
		else:
			zombi.herir(d, Llamas.FUEGO[2])   # sin empujón ni encogerse, con el número del color del fuego
		ArmasCreadas.prender(zombi, quema)


# ¿Está el zombi dentro de la llama? Por el suelo: en el cono que sale de la boca (estrecho en ella, y se abre hasta
# donde llega) o, si está más cerca que la boca (a quemarropa), en la franja entre Johnny y la boca. Y sin una pared
# en medio
func dentro(zombi: Node2D, johnny: Node2D, u: Vector2) -> bool:
	var r: float = zombi.radio
	var p := zombi.global_position - global_position
	var delante := p.dot(u)
	var desde := global_position
	if delante < 0.0:
		var q := zombi.global_position - johnny.global_position
		if q.dot(u) < -r or absf(q.cross(u)) > BOCA * 2.0 + r:
			return false
		desde = johnny.global_position
	elif delante > tope + r or absf(p.cross(u)) > BOCA + delante * abre() + r:
		return false
	var rayo := PhysicsRayQueryParameters2D.create(desde, zombi.global_position, 1)
	return get_world_2d().direct_space_state.intersect_ray(rayo).is_empty()


# Lo que se abre el cono a cada lado por cada unidad de largo (el del ácido, más estrecho)
func abre() -> float:
	return tan(ABRE_ACIDO if acido else ABRE)


# Chispas que saltan de la llama hacia delante y hacia arriba (Particulas), en sitios al azar de lo largo
func chispas(delta: float) -> void:
	if largo < 20.0 or randf() > CHISPAS * delta:
		return
	var u := Vector2.from_angle(angulo)
	var d := randf_range(0.15, 0.9) * largo
	var donde := global_position + u * d - Vector2(0, lerpf(ALTURA, ALTURA_CUERPO, d / alcance))
	donde += u.orthogonal() * randf_range(-0.6, 0.6) * (BOCA + d * tan(ABRE))
	var hacia := u * randf_range(60.0, 140.0) + Vector2(randf_range(-20.0, 20.0), -randf_range(40.0, 90.0))
	Particulas.soltar(self, donde, hacia, Llamas.FUEGO[randi() % 3], 2.0, randf_range(0.3, 0.6))


# El ácido: gotitas que se escapan del final del chorro hacia delante y caen al suelo; contra la pared, el doble, y
# salpican hacia atrás y a los lados (Particulas.volar: caen por su peso y se acaban al llegar al suelo, sin charco)
func gotitas(delta: float) -> void:
	var cortada := tope < alcance - 1.0
	if largo < 20.0 or randf() > GOTITAS * delta * (2.0 if cortada else 1.0):
		return
	var u := Vector2.from_angle(angulo)
	var d := randf_range(0.75, 1.0) * largo
	var pie := global_position + u * d + u.orthogonal() * randf_range(-0.5, 0.5) * (BOCA + d * abre())
	var hacia := u * (randf_range(-110.0, -30.0) if cortada else randf_range(30.0, 110.0))
	hacia += u.orthogonal() * randf_range(-60.0, 60.0) * (1.6 if cortada else 1.0)
	Particulas.volar(self, pie, lerpf(ALTURA, ALTURA_CUERPO, d / alcance), hacia, randf_range(10.0, 70.0),
		VERDES[randi() % VERDES.size()], 2.0)


# Le pasa al shader dónde está la llama y cómo va (en la pantalla: el eje baja un poco, porque la llama baja de la
# altura de la boca a la del cuerpo, y lo que se tuerce al salir del tubo), pone la luz en medio de la llama y la redibuja
func pintar() -> void:
	luz.enabled = visible and not acido   # (el ácido no alumbra)
	if not visible:
		return
	var u := Vector2.from_angle(angulo)
	var en_pantalla := u + Vector2(0, (ALTURA - ALTURA_CUERPO) / alcance)
	var f := en_pantalla.length()   # lo que mide en la pantalla cada unidad de llama por el suelo
	var eje := en_pantalla / f
	var m: ShaderMaterial = material
	m.set_shader_parameter("tiempo", tiempo)
	m.set_shader_parameter("boca", global_position + Vector2(0, -ALTURA) - eje * ATRAS)
	m.set_shader_parameter("eje", eje)
	var cortada := tope < alcance - 1.0
	m.set_shader_parameter("largo", largo * f + ATRAS + (8.0 if cortada else 0.0))   # (que toque la cara de la pared)
	m.set_shader_parameter("cola", cola * f + ATRAS if cola > 0.0 else 0.0)
	m.set_shader_parameter("alcance", alcance * f + ATRAS)
	m.set_shader_parameter("cortada", 1.0 if cortada else 0.0)
	m.set_shader_parameter("tuerce", tan(giro))
	m.set_shader_parameter("doblez", doblez)
	# la luz: en medio de lo que se ve, tan grande como la llama, y temblando
	var medio := (cola + largo) / 2.0
	luz.position = Vector2(0, -ALTURA) + eje * medio * f
	luz.texture_scale = ((largo - cola) * 0.6 + 80.0) / 128.0
	luz.energy = 1.4 * Luz.fuerza() * (0.85 + 0.15 * sin(tiempo * 23.0) * sin(tiempo * 7.0))
	queue_redraw()


# Un rectángulo que cubre la llama entera (con sitio para que ondule y se abra): lo demás lo pinta el shader
func _draw() -> void:
	if not visible:
		return
	var u := Vector2.from_angle(angulo)
	var eje := (u + Vector2(0, (ALTURA - ALTURA_CUERPO) / alcance)).normalized()
	var lado := eje.orthogonal() * 170.0
	var boca := Vector2(0, -ALTURA)
	var desde := boca - eje * (ATRAS + 10.0)
	var hasta := boca + eje * (largo * 1.1 + 12.0)
	draw_colored_polygon(PackedVector2Array([desde + lado, hasta + lado, hasta - lado, desde - lado]), Color.WHITE)
