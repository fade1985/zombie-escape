// El agua con corriente de la electrónica (peligros/agua.gd; 27 nov, el dueño: la tienda inundada, Tienda.LABERINTOS). Es
// mucha agua para calcularla cuadradito a cuadradito como los charcos (charco.gd, liquido.gdshader): la textura tiene un
// texel por CASILLA (rojo: agua; con una casilla seca alrededor) y aquí se saca todo lo demás. Cada cuadradito (un píxel del
// dibujo, 16 por casilla) es agua si lo es su casilla, menos las esquinas de fuera, redondeadas (las que tienen seco a los dos
// lados: agua.gd, en_agua, mira lo mismo). Lo lejos que está del seco (mirando las 8 casillas de alrededor) da su color, como
// en los charcos: el contorno oscuro, bandas que se mecen, vetas de brillo que resbalan y, encima, los anillos de ondas.
// Todo en precisión alta (highp): hay móviles que, si no, calculan con pocos decimales y el balanceo iría a saltos.
shader_type canvas_item;

uniform highp float t = 0.0;              // el tiempo (lo que se mece)
uniform highp vec2 esquina = vec2(0.0);   // dónde empieza la textura, en el nodo (para las vetas y las ondas)
uniform vec4 borde : source_color;
uniform vec4 oscuro : source_color;
uniform vec4 medio : source_color;
uniform vec4 centro : source_color;
uniform vec4 brillo : source_color;
uniform vec4 luz : source_color;
uniform highp vec4 ondas[24];             // cada anillo: su centro (en el nodo), cada cuánto sale y su desfase
uniform int cuantas = 0;

const float LADO = 16.0;     // cuadraditos por casilla
const float REDONDEO = 4.0;  // el radio de las esquinas de fuera, en cuadraditos (agua.gd, REDONDEO)

varying vec4 tinte;   // el modulate del nodo (el destello de cada calambrazo)

void vertex() {
	tinte = COLOR;
}

float moja(sampler2D tex, ivec2 c) {
	return texelFetch(tex, c, 0).r;
}

void fragment() {
	highp vec2 q = UV * vec2(textureSize(TEXTURE, 0));   // en casillas
	ivec2 cas = ivec2(floor(q));
	if (moja(TEXTURE, cas) < 0.5) {
		discard;
	}
	highp vec2 l = floor(fract(q) * LADO) + 0.5;   // el centro de su cuadradito, dentro de la casilla (de 0 a 16)
	// lo lejos que está del seco, en cuadraditos: de las casillas secas de alrededor...
	float lejos = 99.0;
	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			if ((dx != 0 || dy != 0) && moja(TEXTURE, cas + ivec2(dx, dy)) < 0.5) {
				vec2 d = vec2(dx < 0 ? l.x : (dx > 0 ? LADO - l.x : 0.0), dy < 0 ? l.y : (dy > 0 ? LADO - l.y : 0.0));
				lejos = min(lejos, length(d));
			}
		}
	}
	// ...y de las esquinas redondeadas de la suya (seco a los dos lados: fuera del cuarto de círculo, no hay agua)
	for (int sy = -1; sy <= 1; sy += 2) {
		for (int sx = -1; sx <= 1; sx += 2) {
			if (moja(TEXTURE, cas + ivec2(sx, 0)) < 0.5 && moja(TEXTURE, cas + ivec2(0, sy)) < 0.5) {
				vec2 c = vec2(sx < 0 ? REDONDEO : LADO - REDONDEO, sy < 0 ? REDONDEO : LADO - REDONDEO);
				bool en_esquina = (sx < 0 ? l.x < REDONDEO : l.x > LADO - REDONDEO) && (sy < 0 ? l.y < REDONDEO : l.y > LADO - REDONDEO);
				if (en_esquina) {
					float r = length(l - c);
					if (r > REDONDEO) {
						discard;
					}
					lejos = min(lejos, REDONDEO - r);
				}
			}
		}
	}
	bool contorno = lejos < 1.0;
	float d = clamp(1.0 - (lejos + 0.5 - 1.0) / 10.0, 0.0, 1.0);   // 0 en lo hondo, 1 en el borde (como en los charcos)
	highp vec2 p = esquina + (vec2(cas) * LADO + l - 0.5) * 2.0;   // el cuadradito, en el nodo
	// su fase: un ruido suave, para que las bandas se mezan como olas
	highp float g = 3.0 * sin(p.x * 0.11 + 1.3 * sin(p.y * 0.07)) + 3.0 * sin(p.y * 0.13 + 1.1 * sin(p.x * 0.05));
	vec4 color;
	if (contorno) {
		color = borde;
	} else {
		highp float dd = d + 0.05 * sin(t * 2.2 + g);
		color = dd < 0.35 ? centro : dd < 0.62 ? medio : dd < 0.86 ? oscuro : borde;
		if (d < 0.75) {
			// el brillo en vetas: líneas casi horizontales que ondulan y se desplazan
			highp float v = sin(p.y * 0.35 + sin(p.x * 0.06 + t * 0.7) * 2.2 + g * 0.25) * sin(p.x * 0.045 - t * 0.5 + g * 0.1);
			if (v > 0.86) {
				color = brillo;
			} else if (v > 0.74 && dd >= 0.35) {
				color = centro;
			}
		}
		// los anillos de ondas: cada uno nace en su sitio, crece y se apaga; a trozos (como las crestas de "ripples")
		if (d <= 0.85) {
			for (int i = 0; i < cuantas; i++) {
				highp vec4 o = ondas[i];
				highp float k = mod(t + o.w, o.z) / o.z;
				if (k > 0.85) {
					continue;
				}
				highp float radio = 4.0 + k * (18.0 + 6.0 * fract(o.w * 3.7));
				highp vec2 v = p + 1.0 - o.xy;
				highp float e = length(vec2(v.x, v.y / 0.6));
				if (abs(e - radio) < 1.0) {
					int pasos = max(12, int(radio * 0.8));
					int trozo = int(floor(fract(atan(v.y / 0.6, v.x) / 6.2831853) * float(pasos)));
					if (trozo % 3 != 0) {
						color = mix(centro, luz, 1.0 - k);
					}
				}
			}
		}
	}
	COLOR = color * tinte;
}
