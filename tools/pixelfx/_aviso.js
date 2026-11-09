// Común a los borradores de los avisos de los jefes (Johnny Rush), vistos desde arriba: a la izquierda, el trozo
// que barre un golpe cuerpo a cuerpo (el jefe en SEC, mirando a la derecha); a la derecha, el círculo donde cae un
// salto. El aviso dura TW y luego pega (el golpe del abanico aquí; el pisotón del salto, el del juego, se pone encima
// al montar el GIF).
import { hex, WHITE, clamp, ease } from "../../core/index.js";

export const D = 1.6, TW = 1.1;
export const SEC = { x: 22, y: 0, r: 46, half: 0.75 };
export const CIR = { x: 150, y: 0, r: 38 };
export const META = { size: [250, 170], origin: [8, 85], duration: D, loop: true, fps: 30, bg: "dark" };
export const ROJO = hex("#ff3d59"), OSC = hex("#3a0a14"), MED = hex("#b0182f"), BRI = hex("#ffd1d9"), AMA = hex("#ffd23f");
export { WHITE };

/** Dónde cae un píxel en el abanico: d (0 jefe, 1 borde), s (-1 a 1, de un lado al otro), borde (px al borde). */
export function enSector(x, y) {
  const dx = x - SEC.x, dy = y - SEC.y, r = Math.hypot(dx, dy), a = Math.atan2(dy, dx);
  if (r > SEC.r || Math.abs(a) > SEC.half || r < 4) return null;
  return { d: r / SEC.r, s: a / SEC.half, borde: Math.min(SEC.r - r, (SEC.half - Math.abs(a)) * r, r - 4), r, a };
}
export function enCirculo(x, y) {
  const dx = x - CIR.x, dy = y - CIR.y, r = Math.hypot(dx, dy);
  if (r > CIR.r) return null;
  return { d: r / CIR.r, s: Math.atan2(dy, dx) / Math.PI, borde: CIR.r - r, r, a: Math.atan2(dy, dx) };
}
/** Recorre los píxeles de las dos formas: f(x, y, g, cual) (cual 0 abanico, 1 círculo). */
export function cada(f) {
  for (let y = -85; y < 85; y++)
    for (let x = -8; x < 236; x++) {
      const px = x + 0.5, py = y + 0.5;
      let g = enSector(px, py);
      if (g) f(px, py, g, 0);
      g = enCirculo(px, py);
      if (g) f(px, py, g, 1);
    }
}
/** Lo que lleva el aviso (0 a 1) y el tiempo desde el golpe (negativo antes). */
export const fase = (t) => [clamp(t / TW), t - TW];

/** El golpe del abanico: una media luna blanca que barre de un lado al otro y se apaga. */
export function tajo(p, a) {
  if (a < 0 || a > 0.3) return;
  const barre = ease.outCubic(clamp(a / 0.1)), apaga = 1 - clamp((a - 0.08) / 0.22);
  for (let y = -85; y < 85; y++)
    for (let x = -8; x < 90; x++) {
      const g = enSector(x + 0.5, y + 0.5);
      if (!g || g.d < 0.45) continue;
      const frente = -1.2 + 2.4 * barre, detras = frente - g.s;
      if (detras < 0 || detras > 1.6) continue;
      const k = (1 - detras / 1.6) * apaga, ancho = 0.35 + 0.6 * (1 - detras / 1.6);
      if (g.d < 1 - ancho) continue;
      if (detras < 0.12 && apaga > 0.5) p.px(x + 0.5, y + 0.5, WHITE);
      else if (k > 0.55) p.px(x + 0.5, y + 0.5, g.d > 0.85 ? WHITE : BRI);
      else if (k > 0.3) p.px(x + 0.5, y + 0.5, ROJO);
      else if (k > 0.05) p.blend(x + 0.5, y + 0.5, ROJO, 0.5);
    }
  if (a < 0.15) p.glow(SEC.x + 34, SEC.y, 36, BRI, 0.6 * (1 - a / 0.15));
}
