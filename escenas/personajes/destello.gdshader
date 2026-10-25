// El destello blanco de los zombis al recibir un golpe (zombi.gd): mezcla el dibujo con blanco.
// "hielo": congelado en la cámara frigorífica, lo mezcla con azul hielo.
// "tinte": el color de arder o del ácido (Zombi.tinte_fuerte); en "a", cuánto se mezcla (0 = nada). Guarda lo claro
// y lo oscuro del dibujo, para que se le sigan viendo la ropa y la cara
shader_type canvas_item;

uniform float destello = 0.0;
uniform float hielo = 0.0;
uniform vec4 tinte = vec4(0.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	vec3 r = mix(c.rgb, vec3(0.72, 0.9, 1.0), hielo);
	float claro = dot(r, vec3(0.3, 0.59, 0.11));
	r = mix(r, tinte.rgb * (0.35 + 1.1 * claro), tinte.a);
	COLOR = vec4(mix(r, vec3(1.0), destello), c.a);
}
