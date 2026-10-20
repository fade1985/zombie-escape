// La niebla de las habitaciones que aún no se han pisado (mapa.gd). Se pinta de una vez sobre todo el mapa,
// con una textura pequeña de una casilla por píxel:
//   - rojo: lo oscura que está la casilla (en los muros, la de la habitación de al lado), para difuminar
//   - verde: si en esa casilla se pinta niebla o no (1 sí, 0 no)
// Así los bordes junto a una puerta se difuminan, se intuye lo que hay debajo y un humo muy suave se mueve.
shader_type canvas_item;

uniform vec3 oscuro : source_color = vec3(0.07, 0.063, 0.11);
uniform float fondo = 0.72;      // lo que tapa a tope (1 = nada se ve)
uniform float humo = 0.14;       // cuánto cambia la niebla de un sitio a otro
uniform float velocidad = 0.04;  // lo rápido que se mueve el humo
uniform float casillas_humo = 5.0;  // lo grandes que son las manchas de humo, en casillas

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Ruido suave: números al azar en una rejilla, mezclados entre sí
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), f.x),
			mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 tam = vec2(textureSize(TEXTURE, 0));
	ivec2 casilla = ivec2(UV * tam);
	if (texelFetch(TEXTURE, casilla, 0).g < 0.5) {
		discard;
	}
	// difuminado: varias muestras alrededor (la textura se lee suavizada entre casillas)
	vec2 paso = 0.6 / tam;
	float n = texture(TEXTURE, UV).r * 2.0;
	n += texture(TEXTURE, UV + vec2(paso.x, 0.0)).r;
	n += texture(TEXTURE, UV - vec2(paso.x, 0.0)).r;
	n += texture(TEXTURE, UV + vec2(0.0, paso.y)).r;
	n += texture(TEXTURE, UV - vec2(0.0, paso.y)).r;
	n /= 6.0;
	// el humo: dos capas de ruido que se desplazan en sentidos distintos
	vec2 p = UV * tam / casillas_humo;
	float t = TIME * velocidad;
	float h = ruido(p + vec2(t, t * 0.6)) * 0.6 + ruido(p * 2.1 - vec2(t * 1.3, -t * 0.4)) * 0.4;
	float a = n * clamp(fondo + (h - 0.5) * 2.0 * humo, 0.0, 1.0);
	COLOR = vec4(oscuro * (0.85 + 0.3 * h), a);
}
