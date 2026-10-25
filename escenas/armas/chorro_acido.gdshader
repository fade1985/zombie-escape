// El chorro del lanza ácido de Johnny (llamarada.gd, con "acido"). Como la llama del lanzallamas, se pinta sobre un
// rectángulo que lo cubre entero: en cada píxel del dibujo (de 2 unidades, como los muñecos, alineados con el mundo
// aunque el chorro vaya en diagonal) se calcula lo "espeso" que está y se pinta con los verdes del ácido del juego (el
// del medio, #c7e04a, el de EFECTOS.acido y las bombonas), a bandas, sin degradados. Como el de una manguera de bomberos:
//   - Sale fino y recto de la boquilla (va a presión: no ondula como la llama) y se va abriendo poco a poco
//   - Es más claro y espeso en el centro (casi blanco junto a la boquilla) y lleva vetas a lo largo que corren
//     hacia fuera muy deprisa
//   - Alrededor, un rocío de gotitas sueltas; y, cuanto más lejos, más se rompe el chorro, hasta acabar en rocío
//   - Si lo corta una pared, en la punta se aplasta y salpica a los lados; al soltarlo, se despega de la boquilla ("cola")
// Los bordes entre un color y otro van en damero (dos colores a cuadros), como se hace a mano en pixel art.
shader_type canvas_item;
render_mode unshaded;

uniform float tiempo = 0.0;
uniform vec2 boca = vec2(0.0);       // la boquilla, en el mundo
uniform vec2 eje = vec2(1.0, 0.0);   // hacia dónde va el chorro en la pantalla (de largo 1)
uniform float largo = 0.0;           // hasta dónde llega la punta (en la pantalla, desde la boquilla)
uniform float cola = 0.0;            // desde dónde empieza (al soltarlo se despega de la boquilla)
uniform float alcance = 320.0;       // lo más lejos que llega (para lo que se rompe)
uniform float cortada = 0.0;         // 1 si lo corta una pared antes de su alcance
uniform float tuerce = 0.0;          // lo que se tuerce al salir hacia donde apunta el tubo (llamarada.gd, "giro")
uniform float doblez = 32.0;         // y en cuánto se endereza

const vec3 BLANCO = vec3(0.957, 1.0, 0.851);   // #f4ffd9
const vec3 CLARO = vec3(0.925, 0.973, 0.588);  // #ecf896
const vec3 MEDIO = vec3(0.780, 0.878, 0.290);  // #c7e04a
const vec3 OSCURO = vec3(0.588, 0.706, 0.188); // #96b430
const vec3 SOMBRA = vec3(0.376, 0.502, 0.157); // #608028

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
	// el centro de su píxel del dibujo, y dónde cae: "x" a lo largo del chorro desde la boquilla, "y" de lado
	vec2 p = floor(mundo / 2.0) * 2.0 + 1.0;
	vec2 r = p - boca;
	float x = dot(r, eje);
	float y = dot(r, vec2(-eje.y, eje.x));
	// sale de la boquilla hacia donde apunta el tubo y se dobla enseguida hacia el eje (el del zombi), como una manguera
	float xd = max(x, 0.0);
	y -= tuerce * xd * exp(-xd / doblez);
	float t = clamp(x / alcance, 0.0, 1.0);
	float damero = mod(floor(p.x / 2.0) + floor(p.y / 2.0), 2.0) - 0.5;

	// contra la pared, en la punta, se aplasta: se ensancha y salpica a los lados
	float pared = cortada * smoothstep(largo - 40.0, largo, x);
	// lo ancho: el chorro, fino en la boquilla y que se abre poco a poco, y el rocío de alrededor, hasta el cono que
	// moja (llamarada.gd: BOCA + x * tan(ABRE_ACIDO))
	float nucleo = 2.5 + x * 0.085 + pared * 14.0;
	float rocio = 4.0 + x * 0.14 + pared * 44.0;
	// las vetas: un ruido estirado a lo largo, que corre hacia fuera muy deprisa
	float vetas = capas(vec2(x * 0.025 - tiempo * 13.0, y * 0.45));
	// lejos de la boquilla el chorro se va llenando de huecos y acaba en rocío (contra la pared, se deshace antes)
	float rompe = smoothstep(0.35, 1.0, t) + pared * 0.6;
	// la punta, deshilachada; la cola (al soltarlo); y nada por detrás de la boquilla
	float punta = largo - mix(18.0, 6.0, cortada) * capas(vec2(y * 0.12, tiempo * 5.0));
	float fin = 1.0 - smoothstep(punta - mix(40.0, 12.0, cortada), punta, x);
	float empieza = smoothstep(cola, cola + 24.0, x) * step(-1.0, x);

	// lo espeso: 1 en el centro del chorro y 0 en su borde, con las vetas, y menos cuanto más se rompe
	float espeso = 1.0 - abs(y) / nucleo + (vetas - 0.5) * 0.55 - rompe * 0.95;
	espeso = espeso * fin * empieza - (1.0 - fin * empieza) * 0.4;

	vec4 color = vec4(0.0);
	if (espeso > 0.0) {
		// más claro en el centro y junto a la boquilla (sale casi blanco)
		float luz = espeso + (1.0 - smoothstep(0.0, 70.0, x)) * 0.45 + damero * 0.08;
		if (luz > 0.8) {
			color = vec4(BLANCO, 1.0);
		} else if (luz > 0.52) {
			color = vec4(CLARO, 1.0);
		} else if (luz > 0.22) {
			color = vec4(MEDIO, 1.0);
		} else {
			color = vec4(OSCURO, 1.0);
		}
	} else if (abs(y) < rocio && x < largo) {
		// el rocío: gotitas sueltas que corren hacia fuera con el chorro, más juntas cerca de él y donde se rompe
		float cerca = 1.0 - abs(y) / rocio;
		float juntas = (0.1 * smoothstep(10.0, 90.0, x) + 0.28 * rompe) * cerca * (0.35 + 0.65 * fin) * empieza;
		vec2 celda = vec2(floor((x - tiempo * 280.0) / 2.0), floor(y / 2.0));
		if (azar(celda) < juntas) {
			float tono = azar(celda + 17.3);
			color = vec4(tono < 0.45 ? CLARO : (tono < 0.85 ? MEDIO : SOMBRA), 1.0);
		}
	}
	COLOR = color;
}
