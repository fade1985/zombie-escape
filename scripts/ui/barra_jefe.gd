# La barra de vida de los jefes, arriba en el centro: la misma que la de Johnny (ui/hud.gd), pero más larga. Vale
# para todos (la portera, los minijefes y los jefes finales de las azoteas).
#   - El marco de metal oxidado (barra-vida.png), alargado repitiendo su trozo de en medio, para que las puntas
#     con sus remaches no se deformen. Dentro, la sangre con su brillo.
#   - Al recibir un golpe, la barra tiembla y lo perdido se queda en claro un momento antes de bajar.
#   - Encima, la vida en números, con la letra del juego.
#   - Cuando el jefe se enfada (a media vida, su "fase" 2), la sangre da un fogonazo, se vuelve rojo fuego y late.
# Sus hijos: "Nombre", el nombre del jefe con su letra (Jersey 25, Tema.FUENTE_JEFE), y "Armadura", la barra fina
# de la armadura del Gymbro (la hace partida.gd, armadura_jefe). partida.gd le pone "jefe", "max_value" y "value".
class_name BarraJefe
extends Control

const MARCO := preload("res://assets/ui/barra-vida.png")
const ANCHO := 400.0      # la barra (el dibujo del marco mide 236×26: se alarga por el medio)
const ALTO := 26.0
const PUNTA := 24.0       # lo que mide cada punta del marco, con sus remaches (esas no se alargan)
# El hueco de dentro del marco, por donde se ve la sangre (de alto, como el de Johnny; de largo, hasta las puntas)
const HUECO := Rect2(11, 0.28 * ALTO, ANCHO - 22, 0.44 * ALTO)
# Como la de Johnny: lo que tarda en bajar el trozo perdido y lo rápido que baja
const ESPERA := 0.45
const BAJADA := 0.9

# El jefe de ahora (para saber si se ha enfadado). Con uno nuevo, la barra empieza ya en su sitio, sin animaciones
# (si no, subiría poco a poco desde donde dejó la del anterior)
var jefe: Node2D:
	set(nuevo):
		jefe = nuevo
		vista = -1.0
var max_value := 100.0
var value := 100.0

var vista := -1.0         # la parte de la barra que se ve llena ahora (0 a 1)
var perdida := -1.0       # hasta dónde llega el trozo claro de lo perdido
var espera := 0.0
var temblor := 0.0        # el temblor al recibir un golpe (se apaga solo)
var fogonazo := 0.0       # el destello al enfadarse (se apaga solo)
var enfadado := false
var tiempo := 0.0


func _ready() -> void:
	theme = Tema.crear()
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # que no se coma los clics de disparar
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var nombre: Label = $Nombre
	nombre.add_theme_font_override("font", Tema.FUENTE_JEFE)


func _process(delta: float) -> void:
	tiempo += delta
	var parte := clampf(value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0
	var ahora: bool = is_instance_valid(jefe) and jefe.get("fase") == 2
	if not is_visible_in_tree() or vista < 0.0:
		# escondida (entre plantas, o mientras se presenta el jefe): sin animaciones, ya en su sitio
		vista = parte
		perdida = parte
		espera = 0.0
		temblor = 0.0
		fogonazo = 0.0
		enfadado = ahora
		return
	if parte < vista:
		# le acaban de pegar: la barra baja de golpe, lo perdido se queda en claro y la barra tiembla
		perdida = maxf(perdida, vista)
		vista = parte
		espera = ESPERA
		temblor = 1.0
	elif parte > vista:
		vista = move_toward(vista, parte, delta * BAJADA * 0.6)   # si se cura, sube poco a poco
	espera -= delta
	if espera <= 0.0:
		perdida = move_toward(perdida, vista, delta * BAJADA * 0.5)
	perdida = maxf(perdida, vista)
	temblor = move_toward(temblor, 0.0, delta * 3.0)
	if ahora and not enfadado:
		fogonazo = 1.0
	enfadado = ahora
	fogonazo = move_toward(fogonazo, 0.0, delta * 2.5)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(roundf(sin(tiempo * 70.0) * 3.0 * temblor), roundf(cos(tiempo * 55.0) * 2.0 * temblor)))
	# El fondo del hueco y lo que acaba de perder, en claro, que se va bajando detrás de la sangre
	draw_rect(HUECO, Color("#1a1620"))
	var claro := HUECO
	claro.size.x *= perdida
	draw_rect(claro, Color("#f0d8b0") if espera > ESPERA - 0.08 else Color("#d98a5a"))
	# La sangre: roja como la de Johnny; enfadado, rojo fuego y latiendo (más clara en cada latido)
	var lleno := HUECO
	lleno.size.x *= vista
	var oscuro := Color("#8a1f1a")
	var brillo := Color("#c24a38")
	var sombra := Color("#6a1512")
	if enfadado:
		var luz := 0.45 * pow(absf(sin(tiempo * PI * 1.6)), 4.0)
		oscuro = Color("#c2321c").lerp(Color("#ff6a3a"), luz)
		brillo = Color("#ff7a3a").lerp(Color("#ffc07a"), luz)
		sombra = Color("#7a1a10")
	draw_rect(lleno, oscuro)
	draw_rect(Rect2(lleno.position, Vector2(lleno.size.x, lleno.size.y * 0.45)), brillo)
	draw_rect(Rect2(lleno.position + Vector2(0, lleno.size.y * 0.8), Vector2(lleno.size.x, lleno.size.y * 0.2)), sombra)
	if fogonazo > 0.0:
		draw_rect(HUECO, Color(1.0, 0.9, 0.7, 0.8 * fogonazo))
	# El marco por encima: las dos puntas tal cual y, entre ellas, su trozo de en medio repetido
	var medio := MARCO.get_width() - 2.0 * PUNTA
	draw_texture_rect_region(MARCO, Rect2(0, 0, PUNTA, ALTO), Rect2(0, 0, PUNTA, ALTO))
	var x := PUNTA
	while x < ANCHO - PUNTA:
		var trozo := minf(medio, ANCHO - PUNTA - x)
		draw_texture_rect_region(MARCO, Rect2(x, 0, trozo, ALTO), Rect2(PUNTA, 0, trozo, ALTO))
		x += trozo
	draw_texture_rect_region(MARCO, Rect2(ANCHO - PUNTA, 0, PUNTA, ALTO), Rect2(MARCO.get_width() - PUNTA, 0, PUNTA, ALTO))
	# La vida en números, como en la de Johnny
	var fuente := Tema.FUENTE
	var texto := "%d / %d" % [ceili(value), roundi(max_value)]
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	var donde := Vector2(roundf((ANCHO - ancho) / 2.0), ALTO / 2.0 + 5)
	draw_string_outline(fuente, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Tema.LINEA)
	draw_string(fuente, donde, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#f0e8d4"))


# La barra fina de la armadura (la del Gymbro, "Armadura": la hace partida.gd), con el mismo estilo que la de vida:
# su hueco oscuro con borde y, dentro, el acero con su brillo arriba
func pintar_armadura(barra: ProgressBar) -> void:
	var r := Rect2(Vector2.ZERO, barra.size)
	barra.draw_rect(r, Tema.LINEA)
	var hueco := r.grow(-2.0)
	barra.draw_rect(hueco, Color("#1a1620"))
	var lleno := hueco
	lleno.size.x = roundf(lleno.size.x * clampf(barra.value / barra.max_value, 0.0, 1.0)) if barra.max_value > 0.0 else 0.0
	barra.draw_rect(lleno, Color("#7f9fc2"))
	barra.draw_rect(Rect2(lleno.position, Vector2(lleno.size.x, 2)), Color("#d8ecff"))
