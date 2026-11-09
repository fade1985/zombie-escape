// Borrador del giro A, "flecha curva": junto al borde de delante de cada cono, dos flechas curvas que dan la vuelta
// alrededor del jefe hacia donde girará; se van llenando con el aviso.
// No se exporta: el juego lo pinta a código en escenas/personajes/aviso.gdshader (relleno_sutil() y flecha_curva()).
import { META, D, TW, L, AB, CONOS, SENTIDO, ROJO, OSC, BRI, WHITE, fase, zonas } from "./_giro.js";

export const meta = { ...META, name: "Giro A flecha curva", desc: "borrador del aviso del giro: flechas curvas", tags: ["ui", "telegraph"], options: { seed: 1 } };
const dang = (a, b) => Math.atan2(Math.sin(a - b), Math.cos(a - b));

// cuánto cae (x, y) en la flecha de radio R0 que sale del cono c: 2 dentro, 1 contorno, 0 fuera; y por dónde va (0 a 1)
function flecha(r, a, c, R0) {
  const u = dang(a, c + SENTIDO * (AB + 0.08)) * SENTIDO;
  const along = u * R0, across = r - R0, LB = R0 * 0.55, CAB = 10;
  if (along < -2 || along > LB + CAB + 2) return [0, 0];
  const ancho = along <= LB ? 2.5 : 6.5 * (1 - (along - LB) / CAB);
  const q = along / (LB + CAB);
  if (along >= 0 && along <= LB + CAB && Math.abs(across) <= ancho) return [2, q];
  if (Math.abs(across) <= Math.max(ancho, 1) + 1.5) return [1, q];
  return [0, 0];
}

export function draw(p, t) {
  zonas(p, t);
  const [k, a0] = fase(t);
  if (a0 > 0) return;
  const ve = Math.min(1, k * 4);
  for (let y = -95; y < 95; y++)
    for (let x = -150; x < 150; x++) {
      const px = x + 0.5, py = y + 0.5, r = Math.hypot(px, py), a = Math.atan2(py, px);
      for (const c of CONOS)
        for (const R0 of [L * 0.45, L * 0.8]) {
          const [m, q] = flecha(r, a, c, R0);
          if (m === 1) p.blend(px, py, OSC, 0.7 * ve);
          else if (m === 2) p.blend(px, py, q < k ? (k > 0.85 ? WHITE : BRI) : ROJO, (q < k ? 0.95 : 0.6) * ve);
        }
    }
}
