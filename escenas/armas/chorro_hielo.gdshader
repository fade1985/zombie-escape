// La nube de congelación del lanza hielo de Johnny (llamarada.gd, efecto "hielo"). No es un chorro a presión como el del
// lanzallamas (16 nov, lo pidió el dueño): es una nube. De la boquilla salen bocanadas de niebla helada, una detrás de
// otra y sin prisa, que se van hinchando según se alejan, se juntan unas con otras, bajan un poco (el aire frío pesa) y
// al final se deshacen. Dentro brillan cristalitos de escarcha. Si una pared la corta, las bocanadas se amontonan
// contra ella y se abren a los lados; al soltarla ("cola"), las que ya han salido siguen su camino y se van.
// Cada bocanada (BOCANADAS, en bucle) tiene su sitio a lo largo, su ladeo al azar (cambia en cada vuelta) y su tamaño;
// la nube es la suma de todas, con los bordes rotos por un ruido. Se pinta en píxeles del dibujo (de 2 unidades), con
// los azules de la rampa a bandas, translúcida por fuera y con luz de arriba a la izquierda; las bandas, en damero.
shader_type canvas_item;
render_mode unshaded;

uniform float tiempo = 0.0;
uniform vec2 boca = vec2(0.0);       // la boca del tubo, en el mundo
uniform vec2 eje = vec2(1.0, 0.0);   // hacia dónde va en la pantalla (de largo 1)
uniform float largo = 0.0;           // hasta dónde llega (en la pantalla, desde la boca): su alcance o la pared
uniform float cola = 0.0;            // desde dónde empieza (al soltarla se despega de la boca)
uniform float alcance = 288.0;       // lo más lejos que llega
uniform float cortada = 0.0;         // 1 si la corta una pared antes de su alcance

// la rampa del hielo (la de las bombonas de Johnny, tools/hoja_lanza_hielo.py), de la sombra al brillo
const vec3 H0 = vec3(0.133, 0.243, 0.439);   // #223e70
const vec3 H1 = vec3(0.227, 0.463, 0.714);   // #3a76b6
const vec3 H2 = vec3(0.400, 0.698, 0.894);   // #66b2e4
const vec3 H3 = vec3(0.620, 0.871, 0.973);   // #9edef8
const vec3 H4 = vec3(0.804, 0.937, 0.988);   // #cdeffc
const vec3 H5 = vec3(0.925, 0.980, 1.0);     // #ecfaff
const vec3 H6 = vec3(1.0, 1.0, 1.0);

const int BOCANADAS = 16;      // las que hay a la vez por el camino
const float VUELTA = 1.1;      // lo que tarda cada una en llegar al final (segundos)

varying vec2 mundo;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), f.x),
			mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), f.x), f.y);
}

float capas(vec2 p) {
	return 0.55 * ruido(p) + 0.3 * ruido(p * 2.03 + 7.1) + 0.15 * ruido(p * 4.1 + 3.7);
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float T = tiempo;
	vec2 p = floor(mundo / 2.0) * 2.0 + 1.0;
	vec2 lado = vec2(-eje.y, eje.x);
	float damero = mod(floor(p.x / 2.0) + floor(p.y / 2.0), 2.0) - 0.5;
	// el ruido que rompe los bordes (se mueve despacio, como la niebla)
	float n = capas(p * 0.055 + vec2(T * 0.35, -T * 0.25));
	float n2 = capas(p * 0.12 - vec2(T * 0.6, T * 0.15));

	float densa = 0.0;   // cuánta niebla hay aquí
	float luz = 0.0;     // y su luz (de arriba a la izquierda), pesada por la niebla de cada bocanada
	for (int i = 0; i < BOCANADAS; i++) {
		float fi = float(i);
		float f = T / VUELTA + fi / float(BOCANADAS);
		float fase = fract(f);
		float cual = floor(f) * float(BOCANADAS) + fi;   // la bocanada de esta vuelta (cambia su azar)
		float d = fase * alcance;                        // por dónde va, a lo largo
		// las que ya han pasado la pared se amontonan contra ella y se abren a los lados
		float pasa = max(d - largo, 0.0);
		d = min(d, largo);
		// las de antes de la cola (al soltarla) ya no salen
		if (d < cola || largo <= 0.0) continue;
		float r = 5.0 + d * 0.2 + pasa * 0.12;           // se hinchan según se alejan
		r *= 0.8 + 0.4 * azar(vec2(cual, 1.7));
		float ladeo = (azar(vec2(cual, 4.3)) - 0.5) * d * 0.45 + sign(azar(vec2(cual, 9.1)) - 0.5) * pasa * 0.8;
		vec2 c = boca + eje * d + lado * ladeo + vec2(0.0, d * 0.06 + fase * fase * 14.0);   // y bajan un poco
		// al nacer crecen deprisa y al final se deshacen
		float vive = smoothstep(0.0, 0.06, fase) * (1.0 - smoothstep(0.72, 1.0, fase));
		vive *= 1.0 - smoothstep(0.0, 1.0, pasa / (alcance * 0.35));
		vec2 dc = p - c;
		float l = length(dc) / r + (n - 0.5) * 0.55 + (n2 - 0.5) * 0.2;
		float k = max(0.0, 1.0 - l) * vive;
		densa += k * 1.25;
		luz += k * dot(dc / max(length(dc), 0.001), vec2(-0.7, -0.7)) * min(1.0, length(dc) / r);
	}
	// en la boquilla, mientras sale, un fogonazo blanco de gas
	if (cola <= 0.0 && largo > 0.0) {
		float lb = length(p - boca - eje * 4.0) / (5.0 + 1.5 * sin(T * 31.0));
		densa += max(0.0, 1.0 - lb) * 1.2;
	}
	// lo espesa que se ve (sin pasarse de 1 donde se juntan muchas) y, encima, su luz: más clara arriba a la izquierda
	// de cada bocanada y más azul abajo a la derecha, para que tenga bulto
	float espesa = 1.0 - exp(-densa * 1.3);
	float nivel = espesa * 0.85 + clamp(luz / max(densa, 0.05), -1.0, 1.0) * 0.3 * min(densa * 2.5, 1.0)
		+ (n2 - 0.5) * 0.12 + damero * 0.04;

	vec4 color = vec4(0.0);
	if (espesa > 0.12) {
		if (nivel > 0.92) color = vec4(H6, 1.0);
		else if (nivel > 0.8) color = vec4(H5, 1.0);
		else if (nivel > 0.66) color = vec4(H4, 0.95);
		else if (nivel > 0.52) color = vec4(H3, 0.9);
		else if (nivel > 0.38) color = vec4(H2, 0.8);
		else if (nivel > 0.24) color = vec4(H1, 0.65);
		else color = vec4(H0, 0.5);
		color.a *= smoothstep(0.12, 0.3, espesa);   // los bordes, más transparentes
	} else if (espesa > 0.07 && damero > 0.0) {
		color = vec4(H1, 0.35);   // la piel, a cuadros y transparente
	}

	// cristalitos de escarcha que flotan dentro y destellan (una crucecita blanca de vez en cuando)
	if (densa > 0.3) {
		vec2 flota = p + vec2(T * 6.0, T * 9.0);
		vec2 celda = floor(flota / 12.0);
		float h = azar(celda + 0.37);
		if (h > 0.82) {
			vec2 c = celda * 12.0 + 3.0 + floor(vec2(azar(celda + 1.3), azar(celda + 2.7)) * 3.0) * 2.0;
			vec2 d = abs(flota - c);
			float destella = step(0.55, fract(T * 2.2 + h * 11.0));
			if ((d.x < 1.5 && d.y < 1.5) || (destella > 0.0 && ((d.x < 1.5 && d.y < 3.5) || (d.y < 1.5 && d.x < 3.5)))) {
				color = vec4(H6, 1.0);
			}
		}
	}

	COLOR = color;
}
