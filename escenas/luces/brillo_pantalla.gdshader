// El brillo de Opciones (pantalla.gd, poner_brillo): coge lo que ya está pintado en la pantalla y lo vuelve a pintar
// más claro o más oscuro. Con "gamma" por debajo de 1 se aclara sobre todo lo oscuro (lo blanco casi no cambia: así no se
// ve todo lavado), y por encima de 1 se oscurece; "ganancia" baja además todo un poco en los brillos más oscuros
shader_type canvas_item;

uniform sampler2D pantalla : hint_screen_texture, filter_nearest;
uniform float gamma = 1.0;
uniform float ganancia = 1.0;

void fragment() {
	vec3 c = texture(pantalla, SCREEN_UV).rgb;
	COLOR = vec4(pow(c, vec3(gamma)) * ganancia, 1.0);
}
