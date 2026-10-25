// El aviso de las cargas en el suelo (aviso.gd), de pixel art: cada cuadradito de 2 de la cuadrícula del suelo mira
// dónde cae en la franja (a lo largo y a lo ancho) y de qué color va. Lo que falta, a cuadros; lo lleno, rojo con el
// frente más claro; por dentro, unas flechas (>) que corren hacia donde va; al final el borde se aclara y, justo
// antes de pegar, un destello suave
shader_type canvas_item;

uniform vec2 origen;            // de dónde sale, en el mundo
uniform vec2 hacia = vec2(1.0, 0.0);
uniform float largo = 100.0;
uniform float medio = 32.0;     // el ancho, a cada lado
uniform float k = 0.0;          // lo lleno (0 a 1)
uniform float tiempo = 0.0;

const float CELDA = 2.0;
const vec3 ROJO = vec3(1.0, 0.24, 0.35);
const vec4 OSCURO = vec4(0.227, 0.039, 0.078, 0.8);   // el borde de fuera, para que se vea en cualquier suelo
const vec3 BRILLO = vec3(1.0, 0.702, 0.741);          // las flechas y el frente del llenado

varying vec2 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 celda = floor(mundo / CELDA);
	vec2 p = celda * CELDA + CELDA * 0.5 - origen;
	float u = dot(p, hacia);                          // a lo largo
	float a = abs(dot(p, vec2(-hacia.y, hacia.x)));   // a lo ancho
	if (u < -CELDA || u > largo + CELDA || a > medio + CELDA) {
		discard;
	}
	float lleno = largo * k;
	float aclara = clamp((k - 0.7) / 0.3, 0.0, 1.0);
	float destello = clamp((k - 0.94) / 0.06, 0.0, 1.0) * 0.55;
	float corre = tiempo * (50.0 + 90.0 * k);   // las flechas, algo más deprisa al final
	bool fuera = u < 0.0 || u > largo || a > medio;
	bool borde = !fuera && (u < CELDA || u > largo - CELDA || a > medio - CELDA);
	bool flecha = !fuera && !borde && a < medio * 0.62 && mod(u + a * 0.9 - corre, 44.0) < 4.0;
	vec4 color;
	if (fuera) {
		color = OSCURO;
	} else if (borde) {
		color = mix(vec4(ROJO, u <= lleno ? 0.95 : 0.45), vec4(BRILLO, 1.0), aclara * 0.7);
	} else if (u <= lleno) {
		color = lleno - u < 6.0 ? vec4(BRILLO, 0.75) : vec4(ROJO, 0.32 + 0.18 * k);
	} else {
		if (!flecha && mod(celda.x + celda.y, 2.0) < 0.5) {
			discard;   // lo que falta: a cuadros
		}
		color = vec4(ROJO, 0.12 + 0.12 * k);
	}
	if (flecha) {
		color = vec4(BRILLO, u <= lleno ? 0.75 : 0.4);
	}
	COLOR = mix(color, vec4(1.0, 1.0, 1.0, max(color.a, 0.6)), destello);
}
