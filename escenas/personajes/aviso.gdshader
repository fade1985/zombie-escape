// Los avisos de los jefes en el suelo (aviso.gd), de pixel art: cada cuadradito de 2 de la cuadrícula del suelo mira
// dónde cae en el aviso y de qué color va. Lo que se enciende poco a poco dice cuánto falta (con lo último, pega) y,
// justo antes de pegar, un fogonazo blanco. Tres formas:
//   - la franja de una carga: flechas grandes (>), del ancho del jefe, que se encienden una tras otra hacia donde va;
//     a los lados, raíles de puntos que marcan el ancho; y al final, una estrella de choque si se va a estrellar contra
//     la pared (y quedarse atontado) o una X si no.
//   - el abanico de un golpe: toda la zona oscura con dos bordes (el de dentro late cada vez más deprisa), y se va
//     llenando del jefe hacia fuera, como una barra de carga (el estilo, en relleno()). Con medio ángulo PI, un
//     círculo entero (los de la portera, donde cae un salto); en un salto, además, la sombra de quien cae en el
//     medio. Puede llegar hasta las paredes (cada rayo, hasta donde choca: el giro del bombero, el aspirado del
//     glotón), ser de otro color y llevar ondas que van hacia el jefe (aspirando).
//   - la barra: una franja recta que se llena hacia fuera como el abanico (las lenguas, los latigazos, los alfileres
//     y las rayas por donde irán los disparos), con el mismo estilo. Si es fina, de color con un contorno oscuro
//     (hilo()). Si el disparo se para en una pared (choca), acaba en la estrella de las cargas.
//     El cono del giro del bombero lleva además dos flechas curvas hacia donde girará (flecha_curva()) y, como las
//     marcas de lo que se lanza (molotovs, sartenes, probetas...), el estilo flojo (sutil, relleno_sutil()).
shader_type canvas_item;

uniform int forma = 0;          // 0: franja; 1: abanico; 2: barra
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
uniform float rayos[37];        // el abanico: hasta dónde llega cada rayo, de un borde al otro (si n_rayos > 1)
uniform int n_rayos = 0;
uniform bool destella = true;   // el destello del final (no, en lo que ya está pasando: aspirando, girando)
uniform float flechas = 0.0;    // el abanico: las flechas curvas del giro (1, como las agujas del reloj; -1, al revés; 0, sin)
uniform bool sutil = false;     // el estilo flojo (el cono del giro del bombero, las marcas de lo que se lanza)

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

// "color", con la marca del final encima (en "q", respecto a su centro, de "tam" cuando ya se ve entera; "aparece", de
// 0 a 1, lo que se ve)
vec4 con_marca(vec4 color, vec2 q, float tam, float aparece) {
	float m = marca(q, tam * (0.5 + 0.5 * aparece));
	if (m == 1.0) {
		color = choca ? vec4(mix(AMARILLO, vec3(1.0), length(q) < 5.0 ? 0.8 : 0.0), 0.95) : vec4(ROJO, 0.9);
		color.a *= aparece;
	} else if (m == 0.5) {
		color = vec4(OSCURO.rgb, OSCURO.a * aparece);
	}
	return color;
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
		color = con_marca(color, p - hacia * (largo - (choca ? 10.0 : FINAL * 0.5)), choca ? 16.0 : 12.0, aparece);
	}
	return color;
}

// El estilo del abanico y de la barra (el borrador A de tools/pixelfx/aviso-a.js): toda la zona se ve desde el
// principio, oscura y translúcida, con dos bordes (oscuro por fuera; del color por dentro, que late cada vez más deprisa
// según se acerca el golpe), y se va llenando del color hacia fuera con un frente claro. Así se ve en cualquier suelo.
// "d", lo lejos que está del principio; "hasta", donde acaba (ahí, en "k", pega); "borde", lo que le queda hasta el borde
bool late() {
	float vueltas = 3.0 * k + 6.0 * k * k * k;   // cada vez más deprisa: 9 latidos en todo el aviso
	return k > 0.35 && fract(vueltas) < 0.5;
}

// El estilo flojo, para lo que es grande o se repite mucho (el cono del giro del bombero, las marcas de los molotovs,
// sartenes, probetas, cafés y cubos): lo mismo, pero el suelo apenas se oscurece, los bordes no laten y el relleno es
// más suave (el borrador de tools/pixelfx/_giro.js)
vec4 relleno_sutil(float d, float hasta, float borde, vec3 oscuro, vec3 claro) {
	if (borde < CELDA) {
		return vec4(oscuro, 0.6);
	}
	if (borde < CELDA * 2.0) {
		return vec4(tinte, 0.75);
	}
	float lleno = hasta * k;
	if (d < lleno - CELDA * 1.5) {
		return vec4(tinte, 0.28 + 0.12 * k);
	}
	if (d < lleno + CELDA * 0.5) {
		return vec4(claro, 0.7);
	}
	return vec4(oscuro, 0.18);
}

vec4 relleno(float d, float hasta, float borde) {
	vec3 oscuro = tinte * 0.22;
	vec3 claro = mix(tinte, vec3(1.0), 0.75);
	if (sutil) {
		return relleno_sutil(d, hasta, borde, oscuro, claro);
	}
	if (borde < CELDA) {
		return vec4(oscuro, 0.9);
	}
	if (borde < CELDA * 2.0) {
		return late() ? vec4(claro, 0.95) : vec4(tinte * 0.7, 0.9);
	}
	float lleno = hasta * k;
	if (d < lleno - CELDA * 1.5) {
		return vec4(tinte, 0.55 + 0.15 * k);
	}
	if (d < lleno + CELDA * 0.5) {
		return vec4(claro, 0.95);   // el frente, que avanza hacia fuera
	}
	return vec4(oscuro, 0.42);
}

// Lo mismo en una barra fina (las rayas de los disparos): sin hueco para dos bordes, va del color, más flojo lo que
// falta, con un contorno oscuro por fuera ("a", lo que se aparta del medio)
vec4 hilo(float d, float hasta, float a) {
	if (a > medio) {
		return vec4(tinte * 0.22, 0.85);
	}
	float lleno = hasta * k;
	if (d < lleno - CELDA * 1.5) {
		return vec4(tinte, 0.9);
	}
	if (d < lleno + CELDA * 0.5) {
		return vec4(mix(tinte, vec3(1.0), 0.75), 0.95);
	}
	return vec4(late() ? mix(tinte, vec3(1.0), 0.5) : tinte, 0.45 + 0.1 * k);
}

// Las flechas curvas del giro del bombero: junto al borde de delante del cono, dos flechas que rodean al jefe hacia
// donde girará ("flechas"), a media distancia y casi al final, y que se van llenando de claro con el aviso. Con su
// contorno oscuro. "r" y "ang": dónde cae el cuadradito, desde el jefe
vec4 flecha_curva(float r, float ang) {
	float h = atan(hacia.y, hacia.x);
	// hasta dónde llega el cono por su borde de delante (los rayos van de -medio a +medio)
	float lejos = n_rayos > 1 ? (flechas > 0.0 ? rayos[n_rayos - 1] : rayos[0]) : largo;
	float d = ang - (h + flechas * (medio + 0.08));
	float u = atan(sin(d), cos(d)) * flechas;   // lo que se ha adelantado, en radianes
	float ve = min(1.0, k * 4.0);
	for (int i = 0; i < 2; i++) {
		float r0 = lejos * (i == 0 ? 0.45 : 0.8);
		float a_lo_largo = u * r0;
		float a_lo_ancho = abs(r - r0);
		float cuerpo = r0 * 0.55;
		float cabeza = 20.0;
		if (a_lo_largo < -4.0 || a_lo_largo > cuerpo + cabeza + 4.0) {
			continue;
		}
		float ancho = a_lo_largo <= cuerpo ? 5.0 : 13.0 * (1.0 - (a_lo_largo - cuerpo) / cabeza);
		float va = a_lo_largo / (cuerpo + cabeza);
		if (a_lo_largo >= 0.0 && a_lo_largo <= cuerpo + cabeza && a_lo_ancho <= ancho) {
			bool lleno = va < k;
			return vec4(lleno ? (k > 0.85 ? vec3(1.0) : BRILLO) : ROJO, (lleno ? 0.95 : 0.6) * ve);
		}
		if (a_lo_ancho <= max(ancho, 2.0) + 3.0) {
			return vec4(OSCURO.rgb, 0.7 * ve);
		}
	}
	return vec4(0.0);
}

vec4 abanico(vec2 p) {
	vec2 q = vec2(p.x, p.y / aplasta);
	float r = length(q);
	float giro = acos(clamp(dot(q, hacia) / max(r, 0.001), -1.0, 1.0));   // lo que se aparta del medio
	if (flechas != 0.0) {
		vec4 f = flecha_curva(r, atan(q.y, q.x));
		if (f.a > 0.0) {
			return f;
		}
	}
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
	// lo que le queda hasta el borde, en el suelo: si está aplastado, arriba y abajo está más cerca
	float borde = (hasta - r) * mix(1.0, aplasta, r > 0.0 ? (q.y * q.y) / (r * r) : 0.0);
	if (medio < 3.1) {
		borde = min(borde, (medio - giro) * r);   // los lados (un círculo entero no tiene)
	}
	vec4 color = relleno(r, hasta, borde);
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
	vec4 color = vec4(0.0);
	bool fina = medio < 6.0;
	if (u >= inicio && u <= largo && a <= medio + (fina ? CELDA : 0.0)) {
		if (fina) {
			color = hilo(u - inicio, largo - inicio, a);
		} else {
			color = relleno(u - inicio, largo - inicio, min(medio - a, min(largo - u, u - inicio)));
		}
	}
	// si el disparo se para en una pared (choca), la estrella de las cargas al final, que sale a partir de la mitad
	float aparece = clamp((k - 0.25) / 0.35, 0.0, 1.0);
	if (choca && aparece > 0.0) {
		color = con_marca(color, p - hacia * (largo - 8.0), 12.0, aparece);
	}
	return color;
}

void fragment() {
	vec2 p = floor(mundo / CELDA) * CELDA + CELDA * 0.5 - origen;
	vec4 color;
	if (forma == 0) {
		color = franja(p);
	} else if (forma == 1) {
		color = abanico(p);
	} else {
		color = barra(p);
	}
	if (color.a <= 0.0) {
		discard;
	}
	// el fogonazo blanco justo antes de pegar (el último 6 %)
	float destello = destella ? clamp((k - 0.94) / 0.02, 0.0, 1.0) * (sutil ? 0.5 : 0.8) : 0.0;
	COLOR = mix(color, vec4(1.0, 1.0, 1.0, max(color.a, 0.6)), destello * step(0.3, color.a));
}
