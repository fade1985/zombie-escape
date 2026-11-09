// El chorro del lanza ácido de Johnny (llamarada.gd, con "acido"). Como la llama del lanzallamas, se pinta sobre un
// rectángulo que lo cubre entero: en cada píxel del dibujo (de 2 unidades, como los muñecos, alineados con el mundo
// aunque el chorro vaya en diagonal) se calcula dónde cae dentro del chorro y se pinta con los verdes del ácido del
// juego, a bandas, sin degradados. Sale del borrador "A" hecho con pixelfx (líquido a presión, 9 nov), hecho más
// líquido y menos "láser":
//   - Una manguera de ácido que ondula (su centro se mueve de lado a lado) y se hincha a borbotones que corren hacia
//     fuera; los bordes, grumosos, y cada vez más cuanto más lejos
//   - Verdes por bandas hacia fuera, pero las bandas van a manchas (no rayas rectas); el blanco, solo en brillos
//     sueltos (más cerca de la boquilla) y, más oscuro, el lado de abajo de la pantalla; un borde verde oscuro de un
//     píxel para que se lea sobre el suelo gris
//   - Pegado a los bordes, un rocío de gotitas que se van hacia fuera (las gotas gordas que saltan a los lados y caen
//     al suelo las suelta llamarada.gd: salpicar)
//   - De la mitad en adelante se va rompiendo en huecos, y de la punta salen pegotes
//   - Un fogonazo pequeño en la boquilla
//   - Si lo corta una pared, en la punta se aplasta y salpica a los lados
//   - Al soltarlo, se despega de la boquilla ("cola"): el trozo de atrás se adelgaza y se rompe en pegotes, y el
//     chorro se va así, deshaciéndose, en vez de cortarse en seco
// Es más estrecho que el cono que moja (llamarada.gd, ABRE): a propósito, el daño sigue igual de fácil de acertar.
shader_type canvas_item;
render_mode unshaded;

uniform float tiempo = 0.0;
uniform vec2 boca = vec2(0.0);       // la boquilla, en el mundo
uniform vec2 eje = vec2(1.0, 0.0);   // hacia dónde va el chorro en la pantalla (de largo 1)
uniform float largo = 0.0;           // hasta dónde llega la punta (en la pantalla, desde la boquilla)
uniform float cola = 0.0;            // desde dónde empieza (al soltarlo se despega de la boquilla)
uniform float alcance = 320.0;       // lo más lejos que llega (para lo que se rompe)
uniform float cortada = 0.0;         // 1 si lo corta una pared antes de su alcance

// los verdes del ácido, de oscuro a blanco (MEDIO es el de EFECTOS.acido y las bombonas)
const vec3 BORDE = vec3(0.165, 0.369, 0.071);  // #2a5e12
const vec3 SOMBRA = vec3(0.310, 0.561, 0.086); // #4f8f16
const vec3 OSCURO = vec3(0.588, 0.706, 0.188); // #96b430
const vec3 MEDIO = vec3(0.780, 0.878, 0.290);  // #c7e04a
const vec3 CLARO = vec3(0.925, 0.973, 0.588);  // #ecf896
const vec3 BLANCO = vec3(1.0, 1.0, 1.0);

const float CORRE = 160.0;  // lo deprisa que corren los borbotones y los pegotes (píxeles del dibujo por segundo)
const float DESHACE = 26.0; // al soltarlo, lo largo del trozo de atrás que se adelgaza y se rompe (píxeles)

varying vec2 mundo;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Ruido suave: números al azar en una rejilla, mezclados entre sí (de -1 a 1)
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n = mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), f.x),
			mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), f.x), f.y);
	return n * 2.0 - 1.0;
}

// Lo ancho del chorro a "x" píxeles de la boquilla (sin los grumos): fino en la boquilla y cada vez más gordo, con los
// borbotones que lo hinchan al pasar (dos trenes, uno cada 70 píxeles y otro cada 110)
float ancho_en(float x, float t) {
	float o1 = mod(x - tiempo * CORRE, 70.0) - 35.0;
	float o2 = mod(x - tiempo * CORRE * 1.15 + 40.0, 110.0) - 55.0;
	return 2.6 + 9.0 * pow(t, 0.9) + (exp(-(o1 * o1) / 60.0) * 2.0 + exp(-(o2 * o2) / 90.0) * 1.6) * (0.4 + t);
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// el centro de su píxel del dibujo, y dónde cae: "x" a lo largo del chorro desde la boquilla, "y" de lado; todo
	// en píxeles del dibujo (2 unidades)
	vec2 p = floor(mundo / 2.0) * 2.0 + 1.0;
	vec2 r = p - boca;
	float x = dot(r, eje) / 2.0;
	float y0 = dot(r, vec2(-eje.y, eje.x)) / 2.0;
	float L = alcance / 2.0;
	float t = clamp(x / L, 0.0, 1.0);
	float punta_x = largo / 2.0;
	float cola_x = cola / 2.0;
	// el centro ondula: una onda lenta y ancha y un temblor rápido, nada en la boquilla y más cuanto más lejos
	float y = y0 - ruido(vec2(x * 0.035 - tiempo * 5.0, 1.3)) * 4.0 * smoothstep(0.03, 0.6, t)
			- ruido(vec2(x * 0.13 - tiempo * 19.0, 4.7)) * 1.1 * t;
	// el lado de abajo de la pantalla es el de la sombra (si va de lado; si va recto arriba o abajo, ninguno)
	float abajo = y * sign(eje.x);

	// contra la pared, en la punta, se aplasta: se ensancha y se rompe antes
	float pared = cortada * smoothstep(punta_x - 20.0, punta_x, x);
	// al soltarlo: el trozo de atrás (DESHACE píxeles desde la cola) se adelgaza y se rompe
	float suelta = cola_x > 0.0 ? 1.0 - smoothstep(cola_x, cola_x + DESHACE, x) : 0.0;
	// la punta, deshilachada; y nada por detrás de la cola ni de la boquilla
	float punta = punta_x - mix(9.0, 3.0, cortada) * (ruido(vec2(y * 0.24, tiempo * 5.0)) * 0.5 + 0.5);
	bool dentro = x > cola_x && x >= -1.0 && x < punta;

	vec4 color = vec4(0.0);
	float m = 0.0;   // lo ancho aquí, por el lado de este píxel
	if (dentro) {
		// los grumos de los bordes (cada lado los suyos), desde muy cerca de la boquilla y más cuanto más lejos
		float grumos = 0.6 + 2.4 * smoothstep(0.08, 1.0, t) + pared * 2.0;
		float lado = abajo > 0.0 ? 3.0 : 9.0;
		float bulto = ruido(vec2(x * 0.22 - tiempo * 34.0, lado)) * 0.7 + ruido(vec2(x * 0.5 - tiempo * 70.0, lado + 20.0)) * 0.3;
		m = (ancho_en(x, t) + bulto * grumos + pared * 7.0) * (1.0 - suelta * 0.75);
		m = max(0.8, m);
		float q = abs(y) / m;
		// los huecos: de la mitad en adelante se rompe, cada vez más (contra la pared, antes; al soltarlo, la cola)
		float rompe = smoothstep(0.45, 1.0, t) + pared * 0.7 + suelta * 1.2;
		bool hueco = rompe > 0.0 && ruido(vec2(x * 0.11 - tiempo * 22.0, y * 0.28)) * 1.4 < -0.95 + 1.7 * rompe;
		if (!hueco) {
			if (q <= 1.0) {
				// por bandas, a manchas: "qm" es lo lejos del centro con un poco de ruido, para que las bandas no
				// sean rayas rectas; el blanco solo en brillos (las vetas más claras) y el lado de abajo, más oscuro
				float manchas = ruido(vec2(x * 0.16 - tiempo * 26.0, y * 0.55 + 3.0));
				float qm = q + manchas * 0.22;
				float vetas = ruido(vec2(x * 0.07 - tiempo * 38.0, floor(y + 20.0) * 1.3));
				int banda = qm < 0.3 ? 1 : (qm < 0.62 ? 2 : (qm < 0.85 ? 3 : 4));
				if (vetas > 0.25 && qm < 0.7) {
					banda -= 1;
				}
				if (banda == 0 && vetas < 0.45 + 0.4 * t) {
					banda = 1;   // blanco solo en las vetas más fuertes, y menos cuanto más lejos
				}
				if (abajo > 0.0 && qm > 0.4) {
					banda = min(4, banda + 1);
				}
				vec3 c = banda <= 0 ? BLANCO : (banda == 1 ? CLARO : (banda == 2 ? MEDIO : (banda == 3 ? OSCURO : SOMBRA)));
				color = vec4(c, 1.0);
			} else if (abs(y) <= m + 1.0) {
				color = vec4(BORDE, 1.0);   // el borde, de un píxel
			}
		}
	}

	// el rocío: gotitas sueltas pegadas a los bordes que corren con el chorro y se apartan de él hacia fuera
	if (color.a == 0.0 && x > max(cola_x, 6.0) && x < punta_x + 4.0) {
		float borde = max(m, ancho_en(x, t)) + 1.0;
		float fuera = abs(y) - borde;
		if (fuera > 0.0 && fuera < 9.0) {
			vec2 celda = vec2(floor((x - tiempo * CORRE * 0.85) / 2.0), floor((fuera - tiempo * 30.0) / 2.0) + sign(y) * 50.0);
			float juntas = (0.06 + 0.1 * t + 0.25 * suelta) * (1.0 - fuera / 9.0);
			if (azar(celda) < juntas) {
				color = vec4(azar(celda + 5.1) < 0.5 ? CLARO : MEDIO, 1.0);
			}
		}
	}

	// los pegotes: del último cuarto en adelante, uno en cada tramo de 13 píxeles, corriendo con el chorro y
	// pasándose un poco de la punta; cada uno, su sitio de lado
	if (color.a == 0.0 && x > max(L * 0.75, cola_x) && x < punta_x + 14.0 && x < L + 14.0) {
		float tramo = floor((x - tiempo * CORRE) / 13.0);
		float sitio = tramo * 13.0 + tiempo * CORRE + 6.5;
		float lado = (azar(vec2(tramo, 3.1)) - 0.5) * 2.0 * (2.6 + 9.0 * pow(min(sitio / L, 1.0), 0.9));
		float radio = azar(vec2(tramo, 7.7)) < 0.35 ? 1.75 : 1.2;
		vec2 d = vec2(x - sitio, y - lado);
		if (azar(vec2(tramo, 5.3)) < 0.8 && length(d) <= radio + 0.6) {
			color = vec4(length(d) > radio ? BORDE : (d.x + d.y < -0.5 ? BLANCO : (d.y < 0.5 ? CLARO : MEDIO)), 1.0);
		}
	}

	// el fogonazo de la boquilla: un circulito blanco y verde que late
	if (cola <= 0.0) {
		float fl = 0.85 + 0.15 * sin(tiempo * 37.7);
		float b = length(vec2(x - 1.0, y0));
		if (b <= 1.4 * fl) {
			color = vec4(BLANCO, 1.0);
		} else if (b <= 2.6 * fl) {
			color = vec4(CLARO, 1.0);
		} else if (b <= 3.6 * fl) {
			color = vec4(OSCURO, 1.0);
		}
	}
	COLOR = color;
}
