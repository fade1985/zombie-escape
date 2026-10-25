// Lo que comparten el shader de los zombis (destello.gdshader) y la copia que brilla a oscuras (brillo.gdshader):
//   - "destello": el blanco al recibir un golpe (0 = nada, 1 = blanco del todo)
//   - "hielo": congelado en la cámara frigorífica, mezcla el dibujo con azul hielo
//   - "fuego" (0-1): arde. Por dentro de la silueta le suben llamas desde los pies (amarillo, naranja y rojo, con
//     un borde a cuadritos), por encima de la cabeza y los hombros le salen lenguas cortas, le saltan chispas
//     sueltas y el resto del cuerpo se tiñe un poco de naranja. Con menos de 1, las llamas se encogen (quemado.gd)
//   - "acido" (0-1): le roe el ácido. Manchas verdes que crecen con "acido", con un borde verde oscuro, el centro
//     oscuro de lo que ya se ha comido, burbujas que se hinchan y revientan, y gotas que resbalan por el cuerpo
//   - "t": el reloj de las llamas y las burbujas; "semilla", para que cada uno arda distinto; "alto", lo que mide
//     el cuerpo en píxeles del dibujo, de los pies (y = 0 en el dibujo) a la cabeza
// Todo va por píxeles del dibujo (como el pixel art): "lugar" es el sitio del píxel en el dibujo, el mismo en todos
// los fotogramas (las manchas no saltan al andar)

uniform float destello = 0.0;
uniform float hielo = 0.0;
uniform float fuego = 0.0;
uniform float acido = 0.0;
uniform float t = 0.0;
uniform float semilla = 0.0;
uniform float alto = 46.0;

const vec3 FUEGO0 = vec3(1.0, 0.953, 0.69);     // #fff3b0, el corazón de la llama (como Llamas.FUEGO)
const vec3 FUEGO1 = vec3(1.0, 0.824, 0.247);    // #ffd23f
const vec3 FUEGO2 = vec3(1.0, 0.624, 0.11);     // #ff9f1c
const vec3 FUEGO3 = vec3(0.941, 0.329, 0.118);  // #f0541e
const vec3 FUEGO4 = vec3(0.722, 0.149, 0.11);   // #b8261c, el borde
const vec3 VERDE = vec3(0.49, 0.863, 0.227);          // #7ddc3a, el ácido
const vec3 VERDE_CLARO = vec3(0.659, 0.937, 0.29);    // #a8ef4a, burbujas y gotas
const vec3 VERDE_PALIDO = vec3(0.847, 1.0, 0.604);    // #d8ff9a, la burbuja a punto de reventar
const vec3 VERDE_OSCURO = vec3(0.184, 0.431, 0.11);   // #2f6e1c, el borde de la mancha
const vec3 ROIDO = vec3(0.133, 0.188, 0.102);         // #22301a, lo que ya se ha comido
const float BRILLO_ACIDO = 0.55;   // lo que luce el ácido a oscuras (el fuego, del todo)

varying vec2 lugar;

void vertex() {
	lugar = VERTEX;
}

// Un número al azar (0-1) para cada sitio
float azar(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * 0.1031);
	q += dot(q, q.yzx + 33.33);
	return fract((q.x + q.y) * q.z);
}

// Ruido suave: números al azar en una cuadrícula, mezclados entre sí (0-1)
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), f.x), mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Lo metido que está un píxel en una mancha de ácido (menos de 0: fuera). Crecen con "acido" y respiran un poco
float mancha(vec2 p) {
	float umbral = 0.7 - 0.14 * acido - 0.02 * sin(t * 2.0);
	return 0.7 * ruido(p * 0.22 + vec2(3.1, 7.7) + semilla) + 0.3 * ruido(p * 0.6 + semilla * 1.7) - umbral;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec3 r = mix(c.rgb, vec3(0.72, 0.9, 1.0), hielo);
	float claro = dot(r, vec3(0.3, 0.59, 0.11));
	float a = c.a;
	float brilla = 0.0;   // cuánto luce a oscuras (solo lo pinta la copia que brilla)
	vec2 p = floor(lugar);
	vec2 px = TEXTURE_PIXEL_SIZE;
	if (acido > 0.0 && a > 0.5) {
		float d = mancha(p);
		if (d < 0.0) {
			// fuera de las manchas, el dibujo como es
		} else if (d < 0.035) {
			r = mix(r, VERDE_OSCURO, 0.85);
		} else if (d > 0.13) {
			r = mix(r, ROIDO, 0.85);
		} else {
			r = VERDE * (0.55 + 0.8 * claro);
			brilla = BRILLO_ACIDO;
		}
		// burbujas: se hinchan, se aclaran y revientan en blanco
		if (d > 0.035 && azar(p + semilla * 3.0) < 0.11) {
			float f = fract(t * 0.9 + azar(p + 9.1));
			if (f < 0.8) {
				r = f < 0.45 ? VERDE_CLARO : (f < 0.7 ? VERDE_PALIDO : vec3(1.0));
				brilla = BRILLO_ACIDO;
			}
		}
		// gotas: en algunas columnas, una gota baja desde el borde de abajo de una mancha y vuelve a salir
		if (azar(vec2(p.x, 11.0) + semilla) > 0.6) {
			float o = floor(fract(t * 0.7 + azar(vec2(p.x, 12.0) + semilla)) * 9.0) + 1.0;
			vec2 q = p - vec2(0.0, o);
			bool sale = texture(TEXTURE, UV - vec2(0.0, o * px.y)).a > 0.5 && mancha(q) > 0.035;
			bool debajo = texture(TEXTURE, UV - vec2(0.0, (o - 1.0) * px.y)).a > 0.5 && mancha(q + vec2(0.0, 1.0)) > 0.035;
			if (sale && !debajo) {
				r = VERDE_CLARO;
				brilla = BRILLO_ACIDO;
			}
		}
	}
	if (fuego > 0.0) {
		float alt = -p.y / alto;            // 0 en los pies, 1 en lo alto de la cabeza
		float baja = (1.0 - fuego) * 0.9;   // con menos fuego, las llamas se encogen
		if (a > 0.5) {
			// llamas que suben: un ruido que corre hacia arriba, más fuerte cuanto más cerca de los pies
			float n = 0.7 * ruido(vec2(p.x * 0.8, (p.y + t * 30.0) * 0.22) + semilla)
				+ 0.3 * ruido(vec2(p.x * 1.6, (p.y + t * 45.0) * 0.5) + semilla * 2.0);
			float v = n + 0.62 - alt - baja;
			float l = 0.8 + 0.4 * claro;
			if (azar(p + floor(t * 5.0) * 7.31 + semilla) > 0.985 + baja) {
				r = FUEGO0;   // una chispa suelta
				brilla = 1.0;
			} else if (v > 1.02) {
				r = FUEGO1 * l;
				brilla = 1.0;
			} else if (v > 0.9) {
				r = FUEGO2 * l;
				brilla = 1.0;
			} else if (v > 0.76) {
				r = FUEGO3 * l;
				brilla = 1.0;
			} else if (v > 0.64 && mod(p.x + p.y, 2.0) < 0.5) {
				r = mix(r, FUEGO4, 0.75);   // el borde de la llama, a cuadritos
			} else {
				r = mix(r, FUEGO3 * (0.35 + 1.1 * claro), 0.3 * fuego);   // el resto, algo anaranjado
			}
		} else if (alt > 0.35) {
			// lenguas cortas (1 a 3 píxeles) por encima de lo que mira hacia arriba: cabeza, hombros, brazos
			float largo = floor(ruido(vec2(p.x * 0.7, t * 7.0) + semilla) * 5.0) - 1.0 - floor(baja * 4.0);
			for (int k = 1; k <= 3; k++) {
				float fk = float(k);
				if (texture(TEXTURE, UV + vec2(0.0, fk * px.y)).a > 0.5) {
					if (fk <= largo) {
						r = azar(vec2(p.x, floor(t * 12.0))) <= 0.2 ? FUEGO1 : (k == 1 ? FUEGO2 : (k == 2 ? FUEGO3 : FUEGO4));
						a = COLOR.a;
						brilla = 1.0;
					}
					break;
				}
			}
		}
	}
	r = mix(r, vec3(1.0), destello);
#ifdef SOLO_BRILLO
	COLOR = vec4(r, a * brilla);
#else
	COLOR = vec4(r, a);
#endif
}
