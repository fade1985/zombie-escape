// El cuerpo de un zombi muerto no se pinta encima de las paredes ni al otro lado (20 nov; lo pidió el dueño): el mismo
// recorte que los charcos y las explosiones (escenas/armas/recorte.gdshaderinc, recorte.gd), metido en el shader de los
// zombis (destello.gdshader) y en su copia que brilla (brillo.gdshader). Va apagado ("recortar" a 0) y lo enciende
// zombi.gd al morir, en el modo "aire" (por los lados y por abajo se corta en la pared; por encima de la pared de
// arriba se sigue viendo, como un personaje delante de ella). Se incluye antes de quemaduras.gdshaderinc, que tiene
// los huecos VERTICE (en su vertex) y RECORTE (al empezar su fragment). Se prueba con --captura --muerto-pared
#include "res://escenas/armas/recorte.gdshaderinc"

uniform float recortar = 0.0;

#define VERTICE mundo = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; pie = MODEL_MATRIX[3].xy;
#define RECORTE if (recortar > 0.5 && visible() < 0.5) { discard; }
