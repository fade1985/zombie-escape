// Los avisos de los jefes en el suelo (aviso.gd), de pixel art: cada cuadradito de 2 de la cuadrícula del suelo mira
// dónde cae en el aviso y de qué color va. Lo que se enciende poco a poco dice cuánto falta (con lo último, pega) y,
// justo antes de pegar, un destello suave. Cuatro formas:
//   - la franja de una carga: flechas grandes (>), del ancho del jefe, que se encienden una tras otra hacia donde va;
//     a los lados, raíles de puntos que marcan el ancho; y al final, una estrella de choque si se va a estrellar contra
//     la pared (y quedarse atontado) o una X si no.
//   - el abanico de un golpe: se va llenando del jefe hacia fuera, como una barra de carga, sin bordes; lo que falta,
//     a cuadros flojitos. Con medio ángulo PI, un círculo entero (los de la portera, donde cae un salto); en un salto,
//     además, la sombra de quien cae en el medio. Puede llegar hasta las paredes (cada rayo, hasta donde choca: el
//     giro del bombero, el aspirado del glotón), ser de otro color y llevar ondas que van hacia el jefe (aspirando).
//   - la barra: una franja recta que se llena hacia fuera como el abanico (las lenguas, los latigazos, los alfileres
//     y las rayas por donde irán los disparos). Si es fina, lo que falta va liso en vez de a cuadros.
//   - las flechas del giro del bombero: dos anillos de flechas alrededor de él que corren hacia el lado al que girará.
shader_type canvas_item;

uniform int forma = 0;          // 0: franja; 1: abanico; 2: barra; 3: flechas del giro
uniform vec2 origen;            // de dónde sale, en el mundo
uniform vec2 hacia = vec2(1.0, 0.0);
uniform float largo = 100.0;    // lo largo de la franja o de la barra, o hasta dónde llega el abanico
uniform float inicio = 0.0;     // la barra: dónde empieza
uniform float medio = 32.0;     // la franja y la barra: el ancho a cada lado; el abanico: el medio ángulo
uniform float aplasta = 1.0;    // el abanico: lo aplastado que se ve en el suelo
uniform float k = 0.0;          // lo que lleva (0 a 1)
uniform float tiempo = 0.0;
uniform bool choca = false;     // la franja acaba en una pared
uniform float sombra = 0.0;     // el abanico de un salto: la sombra de quien cae, en el medio (lo que ocupa, 0 a 1)
uniform vec3 tinte = vec3(1.0, 0.24, 0.35);   // el abanico y la barra: su color (rojo; el aspirado, verde)
uniform float ondas = 0.0;      // el abanico: lo deprisa que van las ondas hacia el jefe (0, sin ondas)
uniform float rayos[21];        // el abanico: hasta dónde llega cada rayo, de un borde al otro (si n_rayos > 1)
uniform int n_rayos = 0;
uniform bool destella = true;   // el destello del final (no, en lo que ya está pasando: aspirando, girando)
uniform float sentido = 1.0;    // las flechas del giro: 1, como las agujas del reloj; -1, al revés

const float CELDA = 2.0;
// las flechas de la franja
const float PRIMERA = 18.0;     // dónde empieza la primera
const float PASO = 40.0;        // de una a la siguiente
const float GROSOR = 10.0;
const float ABRE = 0.7;         // lo abiertas que están (los lados van por detrás de la punta)
const float FINAL = 26.0;       // el sitio que se deja al final para la marca

const vec3 ROJO = vec3(1.0, 0.24, 0.35);
const vec4 OSCURO = vec4(0.227, 0.039, 0.078, 0.75);   // el contorno, para que se vea en cualquier suelo
const vec3 BRILLO = vec3(1.0, 0.82, 0.85);             // lo último que se ha encendido
const vec3 AMARILLO = vec3(1.0, 0.824, 0.247);         // la estrella del choque (como el «¡PUMBA!»)

varying vec2 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// Una tira de cosas que se encienden una tras otra (las flechas): "d", lo que se ha avanzado desde la
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

// El relleno del abanico y de la barra: "d", lo lejos que está del principio; "hasta", donde acaba (ahí, en "k",
// pega). Lo lleno, algo más fuerte hacia fuera, con el frente claro; lo que falta, a cuadros flojitos (o liso)
vec4 relleno(vec2 p, float d, float hasta, bool liso) {
	vec3 claro = mix(tinte, vec3(1.0), 0.65);
	float lleno = hasta * k;
	if (d > lleno) {
		vec2 celda = floor((p + origen) / CELDA);
		if (!liso && mod(celda.x + celda.y, 2.0) < 0.5) {
			return vec4(0.0);
		}
		return vec4(tinte, (liso ? 0.28 : 0.22) + 0.1 * k);
	}
	if (lleno - d < 6.0) {
		return vec4(claro, 0.8);   // el frente, que avanza hacia fuera
	}
	return vec4(tinte, (liso ? 0.5 : 0.3) + 0.25 * k * (d / hasta));   // (las finas, más fuertes: que se vean)
}

vec4 abanico(vec2 p) {
	vec2 q = vec2(p.x, p.y / aplasta);
	float r = length(q);
	float giro = acos(clamp(dot(q, hacia) / max(r, 0.001), -1.0, 1.0));   // lo que se aparta del medio
	if (giro > medio) {
		return vec4(0.0);
	}
	// hasta dónde llega por aquí: todo igual o, con rayos, el de este lado (entre los dos más cercanos)
	float hasta = largo;
	if (n_rayos > 1) {
		float lado = sign(hacia.x * q.y - hacia.y * q.x);
		float f = clamp((giro * lado + medio) / (2.0 * medio), 0.0, 1.0) * float(n_rayos - 1);
		int i = min(int(floor(f)), n_rayos - 2);
		hasta = mix(rayos[i], rayos[i + 1], f - float(i));
	}
	if (r > hasta) {
		return vec4(0.0);
	}
	vec4 color = relleno(p, r, hasta, false);
	// las ondas: arcos claros que van hacia el jefe (cuanto más deprisa, más vivos)
	if (ondas > 0.0 && mod(r + tiempo * ondas, 28.0) < 6.0) {
		color = vec4(mix(tinte, vec3(1.0), 0.5), 0.35 + 0.002 * ondas);
	}
	// la sombra de quien cae, que crece según baja
	if (r < largo * sombra) {
		color = vec4(mix(color.rgb, vec3(0.06, 0.02, 0.04), 0.8), max(color.a, 0.3 + 0.3 * k));
	}
	return color;
}

vec4 barra(vec2 p) {
	float u = dot(p, hacia);
	float a = abs(dot(p, vec2(-hacia.y, hacia.x)));
	if (u < inicio || u > largo || a > medio) {
		return vec4(0.0);
	}
	return relleno(p, u - inicio, largo - inicio, medio < 6.0);
}

// Las flechas del giro: dos anillos (de 110 y de 200, con 6 y 10 flechas) que corren hacia el lado al que girará.
// Rojas y con el contorno oscuro, para que se vean en cualquier suelo
vec4 flechas_giro(vec2 p) {
	float r = length(p);
	float ang = atan(p.y, p.x);
	for (int anillo = 0; anillo < 2; anillo++) {
		float radio = anillo == 0 ? 110.0 : 200.0;
		float n = anillo == 0 ? 6.0 : 10.0;
		float hueco = 6.2831853 / n;
		float b = mod(ang - tiempo * 1.2 * sentido, hueco) - hueco * 0.5;   // lo que se aparta de su flecha
		float t = b * radio * sentido;   // a lo largo del anillo, hacia donde gira
		float e = r - radio;             // hacia fuera
		if (abs(e) > 16.0 || abs(t) > 16.0) {
			continue;
		}
		// una flecha (>) que apunta hacia donde gira: la punta delante y los lados por detrás
		float d = t + abs(e) * 0.8;
		if (d > -5.0 && d < 5.0 && abs(e) < 13.0) {
			return vec4(ROJO, 0.95 * k);
		}
		if (d > -7.0 && d < 7.0 && abs(e) < 15.0) {
			return vec4(OSCURO.rgb, OSCURO.a * k);
		}
	}
	return vec4(0.0);
}

void fragment() {
	vec2 p = floor(mundo / CELDA) * CELDA + CELDA * 0.5 - origen;
	vec4 color;
	if (forma == 0) {
		color = franja(p);
	} else if (forma == 1) {
		color = abanico(p);
	} else if (forma == 2) {
		color = barra(p);
	} else {
		color = flechas_giro(p);
	}
	if (color.a <= 0.0) {
		discard;
	}
	float destello = destella ? clamp((k - 0.94) / 0.06, 0.0, 1.0) * 0.5 : 0.0;
	COLOR = mix(color, vec4(1.0, 1.0, 1.0, max(color.a, 0.6)), destello * step(0.3, color.a));
}
