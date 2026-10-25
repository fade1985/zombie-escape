// El aviso de las cargas en el suelo (aviso.gd), de pixel art: cada cuadradito de 2 de la cuadrícula del suelo mira
// dónde cae en el camino (a lo largo y a lo ancho) y de qué color va. Unas flechas grandes (>), del ancho del jefe,
// que se encienden una tras otra hacia donde va (cuando se enciende la última, embiste); a los lados, dos raíles de
// puntos que marcan el ancho; y al final, donde acaba: una estrella de choque si se va a estrellar contra la pared
// (y quedarse atontado) o una X si no. Justo antes de pegar, un destello suave
shader_type canvas_item;

uniform vec2 origen;            // de dónde sale, en el mundo
uniform vec2 hacia = vec2(1.0, 0.0);
uniform float largo = 100.0;
uniform float medio = 32.0;     // el ancho, a cada lado
uniform float k = 0.0;          // lo que lleva (0 a 1)
uniform float tiempo = 0.0;
uniform bool choca = false;     // acaba en una pared

const float CELDA = 2.0;
const float PRIMERA = 18.0;     // dónde empieza la primera flecha
const float PASO = 40.0;        // de una flecha a la siguiente
const float GROSOR = 10.0;
const float ABRE = 0.7;         // lo abiertas que están (los lados van por detrás de la punta)
const float FINAL = 26.0;       // el sitio que se deja al final para la marca
const vec3 ROJO = vec3(1.0, 0.24, 0.35);
const vec4 OSCURO = vec4(0.227, 0.039, 0.078, 0.75);   // el contorno, para que se vea en cualquier suelo
const vec3 BRILLO = vec3(1.0, 0.82, 0.85);             // la flecha recién encendida
const vec3 AMARILLO = vec3(1.0, 0.824, 0.247);         // la estrella del choque (como el «¡PUMBA!»)

varying vec2 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// La marca del final en "q" (respecto a su centro): 1 dentro, 0.5 en el contorno, 0 fuera
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

void fragment() {
	vec2 celda = floor(mundo / CELDA);
	vec2 p = celda * CELDA + CELDA * 0.5 - origen;
	vec2 lado = vec2(-hacia.y, hacia.x);
	float u = dot(p, hacia);   // a lo largo
	float a = abs(dot(p, lado));   // a lo ancho
	float destello = clamp((k - 0.94) / 0.06, 0.0, 1.0) * 0.5;
	vec4 color = vec4(0.0);

	// las flechas
	float n = max(1.0, floor((largo - FINAL - PRIMERA - GROSOR) / PASO) + 1.0);
	float encendidas = k * n * 1.08;
	float d = u + a * ABRE - PRIMERA;
	float i = floor(d / PASO);
	float dentro = d - i * PASO;   // dónde cae en su flecha
	if (i >= 0.0 && i < n && a <= medio - CELDA) {
		bool encendida = i < encendidas;
		if (dentro < GROSOR && a <= medio - CELDA * 2.0) {
			if (!encendida) {
				color = vec4(ROJO, 0.3);
			} else if (i >= floor(encendidas)) {
				color = vec4(BRILLO, 0.95);   // la última que se ha encendido
			} else {
				color = vec4(ROJO, 0.82 + 0.12 * sin(tiempo * 5.0 - i * 0.8));
			}
		} else if (dentro < GROSOR + CELDA || dentro > PASO - CELDA || a > medio - CELDA * 2.0) {
			bool detras = dentro > PASO - CELDA;   // el contorno de atrás es de la flecha siguiente
			if (dentro < GROSOR + CELDA || (detras && i + 1.0 < n)) {
				color = (detras ? i + 1.0 < encendidas : encendida) ? OSCURO : vec4(OSCURO.rgb, 0.3);
			}
		}
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

	if (color.a <= 0.0) {
		discard;
	}
	COLOR = mix(color, vec4(1.0, 1.0, 1.0, max(color.a, 0.6)), destello * step(0.3, color.a));
}
