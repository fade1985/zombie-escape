// La munición del suelo a oscuras (billete.gd con "a_oscuras"): una copia del dibujo, encima y medio transparente, a
// la que no afecta la penumbra ("unshaded"). Así se ve un poco aunque la sala esté a oscuras
shader_type canvas_item;
render_mode unshaded;

uniform float base = 0.2;   // cuánto se ve el dibujo a oscuras (0, nada; 1, como con luz)

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(c.rgb, c.a * base);
}
