# El ambiente de la pantalla, por encima del mundo y por debajo del HUD y los avisos:
#   - Viñeteado: los bordes un poco más oscuros, para que la vista se vaya al centro (donde está Johnny)
#   - Pantalla roja: un rojo en los bordes que late como un corazón cuando a Johnny le queda poca vida (menos
#     de un tercio), y un fogonazo rojo corto cada vez que le pegan
# Es un rectángulo del tamaño de la pantalla con un shader (un programita que pinta cada píxel).
extends ColorRect

const POCA_VIDA := 0.34      # por debajo de esta parte de la vida, empieza a latir
const VINETA := 0.38         # lo oscuros que se quedan las esquinas (0 nada, 1 negro)

const SHADER := """
shader_type canvas_item;
uniform float vineta = 0.38;
uniform float rojo = 0.0;      // el latido de poca vida (0 a 1)
uniform float golpe = 0.0;     // el fogonazo al recibir un golpe (0 a 1)
uniform vec2 tam = vec2(960.0, 640.0);

void fragment() {
	// distancia al centro, corregida para que la pantalla ancha no deje el óvalo aplastado
	vec2 p = (UV - 0.5) * vec2(tam.x / tam.y, 1.0);
	float d = length(p) / length(vec2(tam.x / tam.y, 1.0) * 0.5);
	float borde = smoothstep(0.45, 1.0, d);
	float oscuro = borde * vineta;
	float r = clamp(rojo * smoothstep(0.35, 1.0, d) + golpe * (0.35 + 0.65 * borde), 0.0, 1.0);
	// por dentro, transparente; por fuera, negro, y encima el rojo
	vec3 color = mix(vec3(0.0), vec3(0.55, 0.02, 0.04), r / max(r + oscuro, 0.001));
	COLOR = vec4(color, clamp(oscuro + r * 0.6, 0.0, 0.85));
}
"""

var johnny: Node2D
var golpe := 0.0
var latido := 0.0
var vida_antes := -1.0


func _ready() -> void:
	name = "Ambiente"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := Shader.new()
	s.code = SHADER
	material = ShaderMaterial.new()
	material.shader = s
	material.set_shader_parameter("vineta", VINETA)
	if johnny:
		vida_antes = johnny.vida
		johnny.vida_cambiada.connect(_vida_cambiada)


func _vida_cambiada(vida: int, _maxima: int) -> void:
	if vida_antes >= 0.0 and vida < vida_antes:
		golpe = 1.0
	vida_antes = vida


func _process(delta: float) -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	material.set_shader_parameter("tam", size)
	golpe = move_toward(golpe, 0.0, delta * 3.5)
	var rojo := 0.0
	if johnny and johnny.vivo:
		var parte: float = johnny.vida / float(johnny.stats.vida_max)
		if parte < POCA_VIDA:
			# late más deprisa y más fuerte cuanta menos vida le queda
			var apuro := 1.0 - parte / POCA_VIDA
			latido += delta * (1.4 + 1.4 * apuro)
			var pulso := pow(absf(sin(latido * PI)), 6.0)   # un golpe seco por latido
			rojo = (0.3 + 0.35 * apuro) * (0.55 + 0.45 * pulso)
	material.set_shader_parameter("rojo", rojo)
	material.set_shader_parameter("golpe", golpe * 0.55)
