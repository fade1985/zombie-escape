// Johnny partido por la cintura (johnny.gd): al golpear andando, el dibujo del golpe pone el cuerpo y otro
// dibujo debajo, el de andar, pone las piernas. Así no se le quedan los pies quietos mientras avanza.
// "parte": 0 = entero (lo normal), 1 = de cintura para arriba, 2 = de cintura para abajo.
// De cintura para abajo, el dibujo del golpe deja también lo claro (el barrido blanco y el arma), que si no
// se cortaría en recto; los vaqueros y las botas son oscuros y se quedan fuera.
shader_type canvas_item;

uniform int parte = 0;
uniform float cintura = 17.0;   // píxeles del dibujo por encima de los pies

varying float alto;

void vertex() {
	// Los pies están en el 0 (el offset del dibujo los pone ahí): hacia arriba es negativo
	alto = -VERTEX.y;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float luz = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	bool claro = luz > 0.5 && c.b <= c.r + 0.02;
	if (parte == 1 && alto < cintura && !claro) {
		discard;
	}
	if (parte == 2 && alto >= cintura) {
		discard;
	}
	COLOR = c * COLOR;
}
