// La llama del lanzallamas de Johnny (llamarada.gd). Se pinta sobre un rectángulo que la cubre entera: en cada
// píxel del dibujo (de 2 unidades, como los muñecos, alineados con el mundo aunque la llama vaya en diagonal) se
// calcula lo "caliente" que está y se pinta con los colores del fuego del juego (Llamas.FUEGO), a bandas, sin
// degradados: así parece fuego de verdad pero en pixel art.
//   - Sale estrecha de la boca y se abre en cono, ondulando como una manguera; dentro, un ruido que corre hacia
//     fuera hace las bocanadas, y deshilacha los bordes y la punta
//   - Más caliente en el medio y junto a la boca (blanco y amarillo), naranja en el medio y rojo en los bordes, más
//     fría cuanto más lejos; al final, humo oscuro
//   - Si la corta una pared, en la punta se aplasta y se abre (aunque esté muy cerca); al apagarla, se despega de
//     la boca ("cola")
// Los bordes entre un color y otro van en damero (dos colores a cuadros), como se hace a mano en pixel art.
shader_type canvas_item;
render_mode unshaded;

uniform float tiempo = 0.0;
uniform vec2 boca = vec2(0.0);       // la boca del tubo, en el mundo
uniform vec2 eje = vec2(1.0, 0.0);   // hacia dónde va la llama en la pantalla (de largo 1)
uniform float largo = 0.0;           // hasta dónde llega la punta (en la pantalla, desde la boca)
uniform float cola = 0.0;            // desde dónde empieza (al apagarla se despega de la boca)
uniform float alcance = 320.0;       // lo más lejos que llega (para lo que se enfría)
uniform float cortada = 0.0;         // 1 si la corta una pared antes de su alcance

const vec3 BLANCO = vec3(1.0, 0.99, 0.92);
const vec3 FUEGO0 = vec3(1.0, 0.953, 0.69);    // #fff3b0
const vec3 FUEGO1 = vec3(1.0, 0.824, 0.247);   // #ffd23f
const vec3 FUEGO2 = vec3(1.0, 0.624, 0.11);    // #ff9f1c
const vec3 FUEGO3 = vec3(0.941, 0.329, 0.118); // #f0541e
const vec3 FUEGO4 = vec3(0.722, 0.149, 0.11);  // #b8261c
const vec3 HUMO_OSCURO = vec3(0.16, 0.13, 0.15);
const vec3 HUMO_CLARO = vec3(0.3, 0.26, 0.28);

varying vec2 mundo;

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

// Tres capas de ruido, cada una más fina: manchas grandes con detalle dentro
float capas(vec2 p) {
	return 0.55 * ruido(p) + 0.3 * ruido(p * 2.03 + 7.1) + 0.15 * ruido(p * 4.1 + 3.7);
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// el centro de su píxel del dibujo, y dónde cae: "x" a lo largo de la llama desde la boca, "y" de lado
	vec2 p = floor(mundo / 2.0) * 2.0 + 1.0;
	vec2 r = p - boca;
	float x = dot(r, eje);
	float y = dot(r, vec2(-eje.y, eje.x));
	float t = clamp(x / alcance, 0.0, 1.0);

	// ondula como una manguera, más cuanto más lejos, y la onda corre hacia fuera
	float onda = sin(x * 0.035 - tiempo * 10.0) * x * 0.045 + sin(x * 0.09 - tiempo * 17.0) * x * 0.012;
	float yy = y - onda;
	// las bocanadas: un ruido que corre hacia fuera (unas 260 unidades por segundo)
	float n = capas(vec2(x * 0.045 - tiempo * 11.7, yy * 0.07 + tiempo * 0.7));
	// lo ancha: estrecha en la boca y se abre (como el cono que quema, llamarada.gd), con las bocanadas; contra la
	// pared, en la punta, se aplasta y se abre
	float ancho0 = 5.0 + x * 0.21;
	ancho0 *= 1.0 + cortada * 0.6 * smoothstep(largo - 60.0, largo, x);
	ancho0 += cortada * 26.0 * smoothstep(largo - 36.0, largo, x);
	float ancho = ancho0 * (0.7 + 0.6 * n);
	float lado = abs(yy) / ancho;

	float calor = 1.0 - lado - t * 0.55 + (n - 0.5) * 0.35;
	calor += (1.0 - smoothstep(0.0, 70.0, x)) * 0.4 * (1.0 - lado);   // el chorro de junto a la boca, blanco
	// la punta, deshilachada (contra la pared, cortada casi en seco); la cola (al apagarla); y nada por detrás de la boca
	float punta = largo - mix(22.0, 8.0, cortada) * capas(vec2(yy * 0.09, tiempo * 3.0));
	calor *= 1.0 - smoothstep(punta - mix(30.0, 10.0, cortada), punta, x);
	calor *= smoothstep(cola - 24.0, cola, x);
	calor *= step(-1.0, x);

	// el humo: al final y un poco más allá de la punta, algo más ancho que el fuego, y sube (se mira un poco más abajo
	// en el mundo, más cuanto más lejos)
	vec2 rs = r + vec2(0.0, 6.0 + max(0.0, x - largo * 0.5) * 0.3);
	float xs = dot(rs, eje);
	float ys = dot(rs, vec2(-eje.y, eje.x)) - onda;
	float s = capas(vec2(xs * 0.05 - tiempo * 4.0, ys * 0.08 - tiempo * 1.1));
	float hacia_final = smoothstep(largo * 0.6, largo * 0.95, xs) * (1.0 - smoothstep(largo, largo + 28.0, xs));
	float humo = (1.0 - abs(ys) / ((5.0 + xs * 0.21) * 1.2)) * hacia_final + (s - 0.5) * 0.9;
	humo *= smoothstep(cola - 24.0, cola, x) * step(0.0, x);

	// el damero de los bordes: medio píxel sí y medio no, un poco más o menos caliente
	float damero = mod(floor(p.x / 2.0) + floor(p.y / 2.0), 2.0) - 0.5;
	calor += damero * 0.06;
	humo += damero * 0.05;

	vec4 color = vec4(0.0);
	if (calor > 0.88) {
		color = vec4(BLANCO, 1.0);
	} else if (calor > 0.72) {
		color = vec4(FUEGO0, 1.0);
	} else if (calor > 0.55) {
		color = vec4(FUEGO1, 1.0);
	} else if (calor > 0.38) {
		color = vec4(FUEGO2, 1.0);
	} else if (calor > 0.2) {
		color = vec4(FUEGO3, 1.0);
	} else if (calor > 0.07) {
		color = vec4(FUEGO4, 1.0);
	} else if (humo > 0.45) {
		color = vec4(HUMO_OSCURO, 0.8);
	} else if (humo > 0.3) {
		color = vec4(HUMO_CLARO, 0.5);
	}
	COLOR = color;
}
