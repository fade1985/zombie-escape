// La niebla helada del lanza hielo de Johnny (llamarada.gd, efecto "hielo"). Como la llama del lanzallamas
// (llamarada.gdshader), se pinta sobre un rectángulo que la cubre entera, en píxeles del dibujo (de 2 unidades) y con una
// rampa de colores a bandas, sin degradados. El estilo sale del "frost-breath" de pixelfx (15 nov):
//   - El chorro: sale fino de la boca, blanco en el centro y celeste por fuera, con golpes de presión que corren hacia
//     fuera; se va deshaciendo en niebla hacia la punta
//   - La niebla de alrededor: bocanadas que se hinchan según se alejan de la boca y, como el aire frío pesa, CAEN (al
//     revés que las lenguas del fuego, que suben). Por fuera, azul oscuro y a cuadros; la piel, transparente
//   - Rayas de viento: trazos finos y blancos que corren a lo largo del chorro, deprisa
//   - Cristalitos de hielo que viajan con la niebla y destellan (una crucecita blanca de vez en cuando)
//   - Si la corta una pared, en la punta se aplasta y se abre; al soltarla, se despega de la boca ("cola") y se deshace
// Los bordes entre un color y otro van en damero, como se hace a mano en pixel art.
shader_type canvas_item;
render_mode unshaded;

uniform float tiempo = 0.0;
uniform vec2 boca = vec2(0.0);       // la boca del tubo, en el mundo
uniform vec2 eje = vec2(1.0, 0.0);   // hacia dónde va en la pantalla (de largo 1)
uniform float largo = 0.0;           // hasta dónde llega la punta (en la pantalla, desde la boca)
uniform float cola = 0.0;            // desde dónde empieza (al soltarla se despega de la boca)
uniform float alcance = 288.0;       // lo más lejos que llega
uniform float cortada = 0.0;         // 1 si la corta una pared antes de su alcance

// la rampa del hielo, de la piel oscura al centro blanco (la de las bombonas de Johnny, tools/hoja_lanza_hielo.py)
const vec3 H0 = vec3(0.133, 0.243, 0.439);   // #223e70
const vec3 H1 = vec3(0.227, 0.463, 0.714);   // #3a76b6
const vec3 H2 = vec3(0.400, 0.698, 0.894);   // #66b2e4
const vec3 H3 = vec3(0.620, 0.871, 0.973);   // #9edef8
const vec3 H4 = vec3(0.804, 0.937, 0.988);   // #cdeffc
const vec3 H5 = vec3(0.925, 0.980, 1.0);     // #ecfaff
const vec3 H6 = vec3(1.0, 1.0, 1.0);

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

vec3 rampa(int i) {
	if (i <= 0) return H0;
	if (i == 1) return H1;
	if (i == 2) return H2;
	if (i == 3) return H3;
	if (i == 4) return H4;
	if (i == 5) return H5;
	return H6;
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float T = tiempo;
	vec2 p = floor(mundo / 2.0) * 2.0 + 1.0;
	vec2 r = p - boca;
	vec2 lado_eje = vec2(-eje.y, eje.x);
	float x = dot(r, eje);
	float y = dot(r, lado_eje);
	float t = clamp(x / alcance, 0.0, 1.0);
	float damero = mod(floor(p.x / 2.0) + floor(p.y / 2.0), 2.0) - 0.5;

	// la punta (deshilachada; contra la pared, cortada casi en seco), la cola (al soltarla) y nada detrás de la boca
	float punta = largo - mix(22.0, 6.0, cortada) * capas(vec2(y * 0.08, T * 2.5));
	float colar = cola > 0.0 ? cola + abs(y) * 0.6 + 22.0 * capas(vec2(y * 0.07, T * 3.0)) - 10.0 : cola;

	// ── El chorro a presión: fino y recto, ondula un poco lejos de la boca ──
	float onda = sin(x * 0.028 - T * 8.0) * x * 0.02 + sin(x * 0.07 - T * 13.0) * x * 0.006;
	float yy = y - onda;
	float entero = 1.0 - smoothstep(largo * mix(0.4, 0.75, cortada), largo * mix(0.8, 1.0, cortada), x);
	float wc = (2.2 + x * 0.035) * (1.0 + 0.15 * sin(x * 0.3 - T * 34.0)) * entero;
	float lc = abs(yy) / max(wc, 0.001);
	float golpe = step(fract(x * 0.024 - T * 7.0), 0.13);
	int chorro = -1;
	if (wc > 0.5 && x > -1.0 && x < punta && x > colar) {
		if (lc < 0.4) chorro = 6;
		else if (lc < 0.72) chorro = 5;
		else if (lc < 1.0 + damero * 0.12) chorro = 4;
		else if (lc < 1.25 + damero * 0.2) chorro = 3;
		if (chorro >= 0) {
			if (t > 0.35 && chorro > 5) chorro -= 1;   // lejos de la boca ya no es blanco
			chorro = min(6, chorro + int(golpe));
		}
	}

	// ── La niebla de alrededor: bocanadas que se hinchan hacia fuera y caen ──
	float abre = smoothstep(6.0, 140.0, x);
	// cada píxel mira la niebla que tiene un poco más ARRIBA en la pantalla, según un ruido que baja: así cae
	float baja = capas(vec2(p.x * 0.04, p.y * 0.045 - T * 2.2));
	float caida = max(0.0, baja - 0.38) * 46.0 * abre;
	caida += max(0.0, baja - 0.3) * 22.0 * smoothstep(largo - 80.0, largo, x) * (1.0 - cortada);
	float ye = dot(r - vec2(0.0, caida), lado_eje) - onda;
	float xe = x;
	// las bocanadas: manchas grandes que viajan hacia fuera y se hinchan
	float n = capas(vec2(xe * 0.042 - T * 9.0, ye * 0.07 + T * 0.4));
	float bocanada = capas(vec2(xe * 0.022 - T * 5.5, ye * 0.045));
	float we = 3.0 + max(xe, 0.0) * mix(0.4, 0.32, abs(eje.x));
	we *= 1.0 + cortada * 0.7 * smoothstep(largo - 60.0, largo, xe);
	we += cortada * 30.0 * smoothstep(largo - 36.0, largo, xe);
	we *= 0.5 + 0.75 * n + 0.35 * bocanada;
	float fin = (1.0 - cortada) * smoothstep(punta - 140.0, punta - 4.0, xe);
	we = max(we * (0.08 + 0.92 * sqrt(max(1.0 - fin * fin, 0.0))), 0.001);
	float le = abs(ye) / we;
	float frio = (1.0 - le) * (0.4 + 0.6 * smoothstep(0.0, 110.0, xe)) - t * 0.32 + (n - 0.5) * 0.4;
	frio += golpe * 0.08 * (1.0 - le);
	// con luz de arriba: la mitad de arriba (en la pantalla), más clara
	frio += clamp(ye * -eje.x / we, -1.0, 1.0) * 0.07 - clamp(ye / we, -1.0, 1.0) * 0.06;
	frio += smoothstep(0.55, 0.78, bocanada) * 0.16 * (1.0 - le);
	frio *= 1.0 - smoothstep(punta - mix(30.0, 8.0, cortada), punta + 12.0, xe);
	float colae = cola > 0.0 ? cola + abs(ye) * 0.6 + 22.0 * capas(vec2(ye * 0.07, T * 3.0)) - 10.0 : cola;
	frio *= smoothstep(colae - 26.0, colae, xe);
	frio += damero * 0.035;
	int niebla = -1;
	float opaca = 1.0;
	if (frio > 0.82) niebla = 5;
	else if (frio > 0.66) niebla = 4;
	else if (frio > 0.5) niebla = 3;
	else if (frio > 0.36) niebla = 2;
	else if (frio > 0.22) { niebla = 1; opaca = 0.8; }
	else if (frio > 0.12) { niebla = 1; opaca = 0.5; }
	else if (frio > 0.07 && damero > 0.0) { niebla = 0; opaca = 0.45; }   // la piel, oscura, a cuadros y transparente

	int nivel = max(chorro, niebla);
	vec4 color = vec4(0.0);
	if (nivel >= 0) {
		color = vec4(rampa(nivel), chorro >= niebla ? 1.0 : opaca);
	}

	// ── Rayas de viento: trazos blancos y finos que corren a lo largo, dentro de la niebla ──
	if (niebla >= 1 && x > 16.0) {
		float fila = floor(ye / 4.0);
		float sale = azar(vec2(fila, 3.1));
		float raya = fract(x * 0.012 - T * (5.0 + sale * 3.0) + sale * 7.0);
		if (sale > 0.45 && raya < 0.09 && mod(ye, 4.0) < 2.0) {
			color = vec4(niebla >= 3 ? H6 : H4, 1.0);
		}
	}

	// ── Cristalitos que viajan con la niebla y destellan ──
	if (niebla >= 1 && x > 10.0) {
		vec2 viaja = vec2(x - T * 150.0, ye);
		vec2 celda = floor(viaja / 10.0);
		float h = azar(celda + 0.37);
		if (h > 0.9) {
			vec2 c = celda * 10.0 + 2.0 + floor(vec2(azar(celda + 1.3), azar(celda + 2.7)) * 3.0) * 2.0;
			vec2 d = abs(viaja - c);
			float destella = step(0.6, fract(T * 3.0 + h * 11.0));
			if ((d.x < 1.5 && d.y < 1.5) || (destella > 0.0 && ((d.x < 1.5 && d.y < 3.5) || (d.y < 1.5 && d.x < 3.5)))) {
				color = vec4(H6, 1.0);
			}
		}
	}

	COLOR = color;
}
