// Los avisos de los jefes en el suelo (aviso.gd), de pixel art: cada cuadradito de 2 de la cuadrícula del suelo mira
// dónde cae en el aviso y de qué color va. Lo que se enciende poco a poco dice cuánto falta (con lo último, pega) y,
// justo antes de pegar, un destello suave. Dos formas:
//   - la franja de una carga: flechas grandes (>), del ancho del jefe, que se encienden una tras otra hacia donde va;
//     a los lados, raíles de puntos que marcan el ancho; y al final, una estrella de choque si se va a estrellar contra
//     la pared (y quedarse atontado) o una X si no.
//   - el abanico de un golpe: arcos que se encienden del jefe hacia fuera, el borde hasta donde llega y los lados de
//     puntos.
shader_type canvas_item;

uniform int forma = 0;          // 0: franja; 1: abanico
uniform vec2 origen;            // de dónde sale, en el mundo
uniform vec2 hacia = vec2(1.0, 0.0);
uniform float largo = 100.0;    // lo largo de la franja, o hasta dónde llega el abanico
uniform float medio = 32.0;     // la franja: el ancho a cada lado; el abanico: el medio ángulo
uniform float aplasta = 1.0;    // el abanico: lo aplastado que se ve en el suelo
uniform float k = 0.0;          // lo que lleva (0 a 1)
uniform float tiempo = 0.0;
uniform bool choca = false;     // la franja acaba en una pared

const float CELDA = 2.0;
// las flechas de la franja
const float PRIMERA = 18.0;     // dónde empieza la primera
const float PASO = 40.0;        // de una a la siguiente
const float GROSOR = 10.0;
const float ABRE = 0.7;         // lo abiertas que están (los lados van por detrás de la punta)
const float FINAL = 26.0;       // el sitio que se deja al final para la marca
// los arcos del abanico
const float INICIO_ARCOS = 14.0;
const float PASO_ARCOS = 22.0;
const float GROSOR_ARCOS = 8.0;

const vec3 ROJO = vec3(1.0, 0.24, 0.35);
const vec4 OSCURO = vec4(0.227, 0.039, 0.078, 0.75);   // el contorno, para que se vea en cualquier suelo
const vec3 BRILLO = vec3(1.0, 0.82, 0.85);             // lo último que se ha encendido
const vec3 AMARILLO = vec3(1.0, 0.824, 0.247);         // la estrella del choque (como el «¡PUMBA!»)

varying vec2 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// Una tira de cosas que se encienden una tras otra (las flechas o los arcos): "d", lo que se ha avanzado desde la
// primera; "n", cuántas hay; "a_lado", si está pegado al lado (ahí, contorno). Devuelve su color (transparente si no
// cae en ninguna)
vec4 tira(float d, float n, float paso, float grosor, bool a_lado) {
	float encendidas = k * n * 1.08;
	float i = floor(d / paso);
	float dentro = d - i * paso;   // dónde cae en la suya
	if (i < 0.0 || i >= n) {
		return vec4(0.0);
	}
	bool encendida = i < encendidas;
	if (dentro < grosor && !a_lado) {
		if (!encendida) {
			return vec4(ROJO, 0.3);
		} else if (i >= floor(encendidas)) {
			return vec4(BRILLO, 0.95);   // la última que se ha encendido
		}
		return vec4(ROJO, 0.82 + 0.12 * sin(tiempo * 5.0 - i * 0.8));
	}
	bool detras = dentro > paso - CELDA;   // el contorno de atrás es de la siguiente
	if (dentro < grosor + CELDA || (detras && i + 1.0 < n)) {
		return (detras ? i + 1.0 < encendidas : encendida) ? OSCURO : vec4(OSCURO.rgb, 0.3);
	}
	return vec4(0.0);
}

// La marca del final de la franja en "q" (respecto a su centro): 1 dentro, 0.5 en el contorno, 0 fuera
float marca(vec2 q, float tam) {
	float r = length(q);
	if (choca) {
		// una estrella de 8 puntas
		float puntas = pow(abs(cos(atan(q.y, q.x) * 4.0)), 4.0);
		float hasta = tam * mix(0.35, 1.0, puntas);
		return r <= hasta ? 1.0 : (r <= hasta + CELDA * 1.5 ? 0.5 : 0.0);
	}
	// una X
	float brazo = abs(abs(q.x) - abs(q.y));
	float lejos = max(abs(q.x), abs(q.y));
	if (lejos > tam * 0.7 + CELDA) {
		return 0.0;
	}
	return brazo < 3.0 && lejos <= tam * 0.7 ? 1.0 : (brazo < 3.0 + CELDA * 1.5 ? 0.5 : 0.0);
}

vec4 franja(vec2 p) {
	vec2 lado = vec2(-hacia.y, hacia.x);
	float u = dot(p, hacia);       // a lo largo
	float a = abs(dot(p, lado));   // a lo ancho
	vec4 color = vec4(0.0);
	// las flechas
	if (a <= medio - CELDA) {
		float n = max(1.0, floor((largo - FINAL - PRIMERA - GROSOR) / PASO) + 1.0);
		color = tira(u + a * ABRE - PRIMERA, n, PASO, GROSOR, a > medio - CELDA * 2.0);
	}
	// los raíles de los lados: puntos que marcan el ancho
	if (color.a == 0.0 && u >= 0.0 && u <= largo && a > medio - CELDA && a <= medio && mod(u, 8.0) < 4.0) {
		color = vec4(ROJO, 0.3 + 0.35 * k);
	}
	// la marca del final: aparece a partir de la mitad y va creciendo
	float aparece = clamp((k - 0.25) / 0.35, 0.0, 1.0);
	if (aparece > 0.0) {
		vec2 centro = hacia * (largo - (choca ? 10.0 : FINAL * 0.5));
		float m = marca(p - centro, (choca ? 16.0 : 12.0) * (0.5 + 0.5 * aparece));
		if (m == 1.0) {
			color = choca ? vec4(mix(AMARILLO, vec3(1.0), length(p - centro) < 5.0 ? 0.8 : 0.0), 0.95) : vec4(ROJO, 0.9);
			color.a *= aparece;
		} else if (m == 0.5) {
			color = vec4(OSCURO.rgb, OSCURO.a * aparece);
		}
	}
	return color;
}

vec4 abanico(vec2 p) {
	vec2 q = vec2(p.x, p.y / aplasta);
	float r = length(q);
	float giro = acos(clamp(dot(q, hacia) / max(r, 0.001), -1.0, 1.0));   // lo que se aparta del medio
	float al_lado = (medio - giro) * r;   // lo lejos que está del lado (más o menos, en unidades)
	if (r > largo + CELDA * 1.5 || al_lado < -CELDA * 1.5) {
		return vec4(0.0);
	}
	if (r > largo || al_lado < 0.0) {
		return OSCURO;   // el contorno de fuera
	}
	// el borde hasta donde llega
	if (r > largo - CELDA * 1.5) {
		return vec4(ROJO, 0.5 + 0.45 * k);
	}
	// los arcos
	float n = max(1.0, floor((largo - CELDA * 2.0 - INICIO_ARCOS - GROSOR_ARCOS) / PASO_ARCOS) + 1.0);
	vec4 color = tira(r - INICIO_ARCOS, n, PASO_ARCOS, GROSOR_ARCOS, al_lado < CELDA);
	// los lados: puntos
	if (color.a == 0.0 && al_lado < CELDA * 1.5 && mod(r, 8.0) < 4.0) {
		color = vec4(ROJO, 0.3 + 0.35 * k);
	}
	return color;
}

void fragment() {
	vec2 p = floor(mundo / CELDA) * CELDA + CELDA * 0.5 - origen;
	vec4 color = forma == 0 ? franja(p) : abanico(p);
	if (color.a <= 0.0) {
		discard;
	}
	float destello = clamp((k - 0.94) / 0.06, 0.0, 1.0) * 0.5;
	COLOR = mix(color, vec4(1.0, 1.0, 1.0, max(color.a, 0.6)), destello * step(0.3, color.a));
}
