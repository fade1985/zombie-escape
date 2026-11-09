// Borrador A, "contraste": toda la zona se ve desde el principio sobre una base oscura con borde, se va llenando de rojo
// del jefe hacia fuera con un frente claro, el borde late cada vez más deprisa y, justo antes de pegar, un fogonazo blanco.
// No se exporta: el juego lo pinta a código en escenas/personajes/aviso.gdshader (relleno()), para que se corte en las
// paredes y tenga el tamaño y la duración de cada ataque. Se renderiza con pixelfx (src/fx/avisos/) para probar ideas.
import { META, D, TW, ROJO, OSC, MED, BRI, WHITE, cada, fase, tajo, SEC, CIR } from "./_aviso.js";

export const meta = { ...META, name: "Aviso A contraste", desc: "borrador de aviso de jefe: base oscura, relleno rojo, borde que late", tags: ["ui", "telegraph"], options: { seed: 1 } };

export function draw(p, t) {
  const [k, a] = fase(t);
  // el borde late: cada vez más deprisa (la fase es la integral de la frecuencia, 2 a 12 por segundo)
  const ph = (2 * k + (10 * k * k * k) / 3) * TW, late = Math.sin(ph * Math.PI * 2) > 0 && k > 0.35;
  const fogonazo = t > TW - 0.07 && t < TW;
  if (a < 0) {
    cada((x, y, g, cual) => {
      const R = cual ? CIR.r : SEC.r, frente = k * R;
      if (fogonazo) return g.borde < 1.5 ? p.px(x, y, WHITE) : p.blend(x, y, WHITE, 0.75);
      if (g.borde < 1) return p.px(x, y, OSC);
      if (g.borde < 2) return p.px(x, y, late ? BRI : MED);
      if (g.r < frente - 1.5) return p.blend(x, y, ROJO, 0.55 + 0.15 * k);
      if (g.r < frente + 0.5) return p.px(x, y, BRI);
      p.blend(x, y, OSC, 0.42);
    });
    if (fogonazo) { p.glow(SEC.x + 30, SEC.y, 40, BRI, 0.4); p.glow(CIR.x, CIR.y, 44, BRI, 0.4); }
  } else {
    // la zona se apaga deprisa
    const q = 1 - a / 0.15;
    if (q > 0) cada((x, y, g) => p.blend(x, y, g.borde < 2 ? ROJO : OSC, 0.4 * q));
  }
  tajo(p, a);
}
