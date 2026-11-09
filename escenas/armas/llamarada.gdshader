// La llama del lanzallamas de Johnny (llamarada.gd). Se pinta sobre un rectángulo que la cubre entera: en cada
// píxel del dibujo (de 2 unidades, como los muñecos, alineados con el mundo aunque la llama vaya en diagonal) se
// calcula lo "caliente" que está y se pinta con una rampa de 9 colores de fuego, a bandas, sin degradados.
// El estilo sale del "flamethrower" de pixelfx (9 nov): un chorro a presión, no una nube.
//   - El chorro: sale fino de la boca, con el centro blanco y por fuera amarillo; por él corren golpes de presión
//     (bandas más calientes que van hacia fuera). Se va deshaciendo hacia la punta
//   - La llama de alrededor: casi nada en la boca y se abre en cono más lejos (como el que quema, llamarada.gd),
//     a bocanadas, naranja y con la piel roja oscura y deshilachada. De ella suben lenguas de fuego (hacia arriba en
//     la pantalla, vaya hacia donde vaya), más cuanto más lejos, y en la punta se enrosca hacia arriba
//   - En la boca, la llamita azul del piloto (solo mientras echa fuego)
//   - Encima de la punta, un poco de humo transparente que sube y se deshace (poco: el de antes parecía una nube
//     negra al final)
//   - Al apagarla ("apagado", los segundos desde que se soltó): la llama que se va se enfría y sube, de la boquilla
//     sale una bocanada de humo y el humo de la punta sigue subiendo un rato donde estaba ("largo_humo")
//   - Si la corta una pared, en la punta se aplasta y se abre; al apagarla, se despega de la boca ("cola")
// Los bordes entre un color y otro van en damero (dos colores a cuadros), como se hace a mano en pixel art.
shader_type canvas_item;
render_mode unshaded;

uniform float tiempo = 0.0;
uniform vec2 boca = vec2(0.0);       // la boca del tubo, en el mundo
uniform vec2 eje = vec2(1.0, 0.0);   // hacia dónde va la llama en la pantalla (de largo 1)
uniform float largo = 0.0;           // hasta dónde llega la punta (en la pantalla, desde la boca)
uniform float cola = 0.0;            // desde dónde empieza (al apagarla se despega de la boca)
uniform float alcance = 320.0;       // lo más lejos que llega (para lo que se enfría)
uniform float cortada = 0.0;         // 1 si la corta una pared antes de su alcance
uniform float apagado = -1.0;        // los segundos desde que se soltó (-1: echando fuego, o nada)
uniform float largo_humo = 0.0;      // lo larga que era al soltarla

// la rampa del fuego, de fría a caliente (la del flamethrower de pixelfx)
const vec3 F0 = vec3(0.290, 0.090, 0.071);   // #4a1712
const vec3 F1 = vec3(0.541, 0.122, 0.090);   // #8a1f17
const vec3 F2 = vec3(0.788, 0.157, 0.122);   // #c9281f
const vec3 F3 = vec3(0.949, 0.337, 0.114);   // #f2561d
const vec3 F4 = vec3(1.0, 0.541, 0.165);     // #ff8a2a
const vec3 F5 = vec3(1.0, 0.761, 0.239);     // #ffc23d
const vec3 F6 = vec3(1.0, 0.886, 0.420);     // #ffe26b
const vec3 F7 = vec3(1.0, 0.953, 0.651);     // #fff3a6
const vec3 F8 = vec3(1.0, 1.0, 1.0);
// el piloto, azul
const vec3 AZUL0 = vec3(0.106, 0.165, 0.541);  // #1b2a8a
const vec3 AZUL1 = vec3(0.227, 0.384, 0.878);  // #3a62e0
const vec3 AZUL2 = vec3(0.659, 0.831, 1.0);    // #a8d4ff
// el humo
const vec3 HUMO0 = vec3(0.180, 0.149, 0.188);  // #2e2630
const vec3 HUMO1 = vec3(0.388, 0.322, 0.337);  // #635256
const vec3 HUMO2 = vec3(0.549, 0.490, 0.502);  // #8c7d80 (lo de arriba de la bocanada de la boquilla)

varying vec2 mundo;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Ruido suave: números al azar en una rejilla, mezclados entre sí
float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(azar(i), azar(i + vec2(1.0, 0.0)), f.x),
			mix(azar(i + vec2(0.0, 1.0)), azar(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Tres capas de ruido, cada una más fina: manchas grandes con detalle dentro
float capas(vec2 p) {
	return 0.55 * ruido(p) + 0.3 * ruido(p * 2.03 + 7.1) + 0.15 * ruido(p * 4.1 + 3.7);
}

vec3 rampa(int i) {
	if (i <= 0) return F0;
	if (i == 1) return F1;
	if (i == 2) return F2;
	if (i == 3) return F3;
	if (i == 4) return F4;
	if (i == 5) return F5;
	if (i == 6) return F6;
	if (i == 7) return F7;
	return F8;
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float T = tiempo;
	// el centro de su píxel del dibujo, y dónde cae: "x" a lo largo de la llama desde la boca, "y" de lado
	vec2 p = floor(mundo / 2.0) * 2.0 + 1.0;
	// al apagarla, la llama que se va sube y se enfría (k, de 0 a 1 en lo que tarda en irse)
	float k = apagado >= 0.0 ? clamp(apagado / 0.4, 0.0, 1.0) : 0.0;
	vec2 r = p - boca + vec2(0.0, k * k * 26.0);
	vec2 lado_eje = vec2(-eje.y, eje.x);
	float x = dot(r, eje);
	float y = dot(r, lado_eje);
	float t = clamp(x / alcance, 0.0, 1.0);
	float damero = mod(floor(p.x / 2.0) + floor(p.y / 2.0), 2.0) - 0.5;

	// la punta (deshilachada; contra la pared, cortada casi en seco), la cola (al apagarla) y nada detrás de la boca
	float punta = largo - mix(18.0, 6.0, cortada) * capas(vec2(y * 0.09, T * 3.0));
	float vive = 1.0 - smoothstep(punta - mix(26.0, 8.0, cortada), punta, x);
	// la cola de la llama que se va, redondeada y deshilachada (no cortada en recto)
	float colar = cola > 0.0 ? cola + abs(y) * 0.5 + 18.0 * capas(vec2(y * 0.08, T * 4.0)) - 9.0 : cola;
	vive *= smoothstep(colar - 20.0, colar, x) * step(-1.0, x);

	// ── El chorro a presión: fino, recto, ondula un poco lejos de la boca ──
	float onda = sin(x * 0.03 - T * 9.0) * x * 0.022 + sin(x * 0.08 - T * 15.0) * x * 0.007;
	float yy = y - onda;
	// se deshace hacia la punta (contra la pared llega entero)
	float entero = 1.0 - smoothstep(largo * mix(0.5, 0.8, cortada), largo * mix(0.85, 1.0, cortada), x);
	float wc = (2.6 + x * 0.04) * (1.0 + 0.18 * sin(x * 0.35 - T * 38.0)) * entero * (1.0 - smoothstep(0.0, 0.5, k));
	float lc = abs(yy) / max(wc, 0.001);
	// los golpes de presión: bandas que corren hacia fuera, un color más calientes
	float golpe = step(fract(x * 0.026 - T * 7.5), 0.14);
	int chorro = -1;
	if (wc > 0.5) {
		if (lc < 0.38) chorro = 8;
		else if (lc < 0.68) chorro = 7;
		else if (lc < 0.92 + damero * 0.1) chorro = 6;
		else if (lc < 1.2 + damero * 0.2) chorro = 5;
		if (chorro >= 0) {
			if (t > 0.4 && chorro > 6) chorro -= 1;   // lejos de la boca ya no es blanco
			chorro = min(8, chorro + int(golpe));
		}
	}

	// ── La llama de alrededor ──
	// las lenguas: cada píxel mira el fuego que tiene un poco más abajo en la pantalla, según un ruido que sube; así
	// el fuego trepa hacia arriba. Más cuanto más lejos de la boca, y en la punta se enrosca
	float abre = smoothstep(8.0, 150.0, x);
	float sube = capas(vec2(p.x * 0.045, p.y * 0.05 + T * 4.5));
	float lengua = max(0.0, sube - 0.4) * 75.0 * abre;
	lengua += max(0.0, sube - 0.3) * 40.0 * smoothstep(largo - 90.0, largo, x) * (1.0 - cortada);
	// (solo de lado: a lo largo no se mueve, para que el cono no se acorte cuando la llama va hacia arriba o abajo)
	float xe = x;
	float ye = dot(r + vec2(0.0, lengua), lado_eje) - onda;
	float n = capas(vec2(xe * 0.05 - T * 12.0, ye * 0.08 + T * 0.6));
	// (más ancha cuanto más de lado vaya hacia arriba o abajo: ahí no tiene lenguas que la ensanchen)
	float we = 3.0 + max(xe, 0.0) * mix(0.42, 0.34, abs(eje.x));
	we *= 1.0 + cortada * 0.6 * smoothstep(largo - 60.0, largo, xe);
	we += cortada * 26.0 * smoothstep(largo - 36.0, largo, xe);
	we *= 0.55 + 0.8 * n;
	float le = abs(ye) / we;
	float calor = (1.0 - le) * (0.35 + 0.75 * smoothstep(0.0, 120.0, xe)) - t * 0.4 + (n - 0.5) * 0.35;
	calor += golpe * 0.1 * (1.0 - le);
	// con luz de arriba: la mitad de arriba (en la pantalla), algo más caliente, y la de abajo más oscura
	calor += clamp(ye * -eje.x / we, -1.0, 1.0) * 0.08;
	// dentro, las bocanadas más calientes: manchas grandes que van hacia fuera
	calor += smoothstep(0.55, 0.75, capas(vec2(xe * 0.03 - T * 8.0, ye * 0.05 - T * 0.4))) * 0.14 * (1.0 - le);
	calor *= 1.0 - smoothstep(punta - mix(26.0, 8.0, cortada), punta + 10.0, xe);
	float colae = cola > 0.0 ? cola + abs(ye) * 0.5 + 18.0 * capas(vec2(ye * 0.08, T * 4.0)) - 9.0 : cola;
	calor *= smoothstep(colae - 24.0, colae, xe);
	calor -= k * 0.42;                 // al irse se enfría
	calor += (n - 0.5) * 0.4 * k;      // y se rompe en bocanadas
	calor += damero * 0.03;
	int llama = -1;
	if (calor > 0.8) llama = 6;
	else if (calor > 0.64) llama = 5;
	else if (calor > 0.48) llama = 4;
	else if (calor > 0.33) llama = 3;
	else if (calor > 0.2) llama = 2;
	else if (calor > 0.1) llama = 1;
	else if (calor > 0.06 && damero > 0.0) llama = 0;   // la piel, roja muy oscura y a cuadros

	int nivel = max(vive > 0.5 ? chorro : -1, llama);
	vec4 color = vec4(0.0);
	if (nivel >= 0) {
		color = vec4(rampa(nivel), 1.0);
	}

	// ── El piloto: una llamita azul en la boca, alrededor del chorro (solo mientras echa fuego) ──
	if (nivel < 5 && cola <= 0.0 && apagado < 0.0 && largo > 0.0 && x > -3.0 && x < 10.0) {
		float lp = abs(y) - wc;
		float hasta = 4.0 - x * 0.35 + damero * 0.6;
		if (lp > -0.5 && lp < hasta) {
			color = vec4(lp < hasta * 0.45 ? (x < 3.0 ? AZUL2 : AZUL1) : AZUL0, 1.0);
		}
	}

	// ── El humo: encima de la punta, transparente, sube y se deshace ──
	float lh = apagado >= 0.0 ? largo_humo : largo;
	if (nivel < 0 && lh > 40.0) {
		vec2 d = p - (boca + eje * (lh - 6.0));
		d.y += max(apagado, 0.0) * 35.0;   // al apagarla, sigue subiendo
		float alto = -d.y;   // lo que ha subido
		float sigue = sin(alto * 0.05 - T * 2.0) * 6.0 + alto * 0.15 * sign(eje.x);
		float ancho = 8.0 + alto * 0.45;
		float h = capas(vec2(d.x * 0.07, d.y * 0.06 + T * 2.4));
		float densa = (1.0 - abs(d.x - sigue) / ancho) * smoothstep(-6.0, 12.0, alto) * (1.0 - smoothstep(30.0, 85.0, alto));
		densa *= smoothstep(40.0, 120.0, lh);
		if (apagado >= 0.0) densa *= 1.0 - apagado / 0.9;
		densa = densa * (0.6 + h) - 0.42 + damero * 0.08;
		if (densa > 0.0) {
			color = vec4(densa > 0.22 && h > 0.5 ? HUMO1 : HUMO0, 0.55);
		}
	}
	// ── Al apagarla: una bocanada de humo que sale de la boquilla y sube ──
	if (color.a == 0.0 && apagado >= 0.0 && apagado < 0.7) {
		float a = apagado;
		vec2 c = boca + eje * (6.0 + a * 16.0) + vec2(0.0, -a * 50.0);
		float radio = 6.0 + a * 20.0;
		vec2 dc = p - c;
		float h = capas(dc * 0.12 + vec2(0.0, T * 1.5));
		float densa = 1.0 - length(dc) / radio + (h - 0.5) * 0.6 + damero * 0.08;
		if (densa > 0.0) {
			vec3 tono = dc.y < -radio * 0.35 ? HUMO2 : (dc.y < radio * 0.1 ? HUMO1 : HUMO0);   // con luz de arriba
			color = vec4(tono, 0.75 * (1.0 - smoothstep(0.3, 0.7, a)));
		}
	}
	COLOR = color;
}
