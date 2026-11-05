# El escolta de Velaria (parte 4 del plan, docs/PLAN_TERCER_EDIFICIO.md, «Los zombis nuevos»): traje negro, chaleco y
# pinganillo. El vigilante de la torre: llega cuando una cámara te ve (peligros/camaras.gd) y hace guardia en Seguridad
# corporativa.
#   - El chaleco: las balas que le llegan de frente le hacen la mitad (chispas y un «¡TOC!»). De lado, por la espalda,
#     los golpes, el fuego y las explosiones, lo de siempre.
#   - El táser: su ataque quita poco ("dano" de su escena) pero deja a Johnny tieso medio segundo (el "calambre" de
#     estados.gd, el mismo del agua con corriente).
# Números provisionales: se ajustan jugando.
extends Zombi

const FRENTE := 1.05     # medio ángulo de lo que tapa el chaleco por delante (unos 60 grados a cada lado)
const CHALECO := 0.5     # lo que le llega de una bala de frente
const TIESO := 0.5       # segundos que deja a Johnny sin moverse

var toc_t := 0.0         # para que el «¡TOC!» no salga a cada perdigón


func _ready() -> void:
	super()
	momento_zarpazo = 0.286   # en su hoja, el táser ya está estirado en el fotograma 3 de 7


func _physics_process(delta: float) -> void:
	toc_t -= delta
	super(delta)


func recibir_golpe(cantidad: int, fuerza: Vector2) -> void:
	if Zombi.de_bala and estado != "muerto" and not dormido and fuerza != Vector2.ZERO:
		var mirada := Vector2.from_angle(DIRS.find(direccion) * PI / 4.0)
		if absf(angle_difference(mirada.angle(), (-fuerza).angle())) < FRENTE:
			cantidad = maxi(1, roundi(cantidad * CHALECO))
			chispas(fuerza)
	super(cantidad, fuerza)


func chispas(fuerza: Vector2) -> void:
	var donde := global_position + Vector2(0, -altura * 0.5) - fuerza.normalized() * 8.0
	for i in 5:
		var v := (-fuerza.normalized()).rotated(randf_range(-1.0, 1.0)) * randf_range(80.0, 180.0)
		Particulas.soltar(self, donde, v, Color("#fff3a8") if i % 2 else Color("#ffffff"), 3, 0.22)
	if toc_t <= 0.0:
		toc_t = 0.4
		Zombi.texto_flotante(get_parent(), donde + Vector2(-26, -30), Idioma.t("¡TOC!"), Color("#bfe9ff"), 16)


# El táser: si le da de verdad (no estaba Johnny esquivando ni recién golpeado), lo deja tieso, con su chispazo
func dar_zarpazo(johnny: Node2D) -> void:
	var antes: int = johnny.vida
	var podia: bool = johnny.invulnerable <= 0.0
	super(johnny)
	if not podia or not johnny.vivo or johnny.vida >= antes:
		return
	johnny.pisar({"calambre": {"despues": TIESO}})
	Sonido.tocar("calambre")
	var donde: Vector2 = johnny.global_position + Vector2(0, -40)
	for i in 8:
		Particulas.soltar(get_parent(), donde, Vector2.from_angle(randf() * TAU) * randf_range(60.0, 160.0),
			Color("#bff4ff") if i % 2 else Color("#ffffff"), 3, 0.25)
