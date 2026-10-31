// Lo común de los exportadores de efectos con variantes (exportar_fogonazo.mjs y exportar_chispa.mjs): dibuja todos los
// fotogramas de todas las variantes de un efecto de pixelfx, recorta a lo justo (lo mismo para todas, con el origen en
// el mismo sitio) y guarda dos hojas: <nombre>.png, el color, y <nombre>-brillo.png, la luz (para sumarla con mezcla
// "añadir"). Cada variante ocupa sus filas de hasta 16 columnas, una detrás de otra.
// Devuelve las medidas para el script de Godot: { origen: [x, y], fotogramas, columnas, filas, w, h, alto }.
import { writeFileSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

export async function exportarVariantes(PFX, mod, variantes, n, fps, salida, nombre) {
  const { createFrame, clearFrame, createFx, composite } = await import(pathToFileURL(join(PFX, "src/core/index.js")));
  const { encodePNG } = await import(pathToFileURL(join(PFX, "tools/lib/png.mjs")));
  const [W, H] = mod.meta.size, [OX, OY] = mod.meta.origin;
  const cuadros = [], f = createFrame(W, H);
  let x0 = W, y0 = H, x1 = -1, y1 = -1;
  for (const v of variantes) {
    const fx = createFx(mod, { x: OX, y: OY, ...v });
    for (let i = 0; i < n; i++) {
      if (i > 0) fx.update(1 / fps);
      clearFrame(f);
      fx.draw(f, "front");
      const luz = new Uint8ClampedArray(W * H * 4);
      for (let k = 0; k < W * H; k++) {
        const l = f.light[k] & 0xffffff;
        luz[k * 4] = l & 255; luz[k * 4 + 1] = (l >> 8) & 255; luz[k * 4 + 2] = (l >> 16) & 255; luz[k * 4 + 3] = l ? 255 : 0;
      }
      f.light.fill(0);
      const color = new Uint8ClampedArray(W * H * 4);
      composite(f, color, null);
      for (let k = 0; k < W * H; k++) {
        if (!color[k * 4 + 3] && !(luz[k * 4] | luz[k * 4 + 1] | luz[k * 4 + 2])) continue;
        const x = k % W, y = Math.floor(k / W);
        x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y);
      }
      cuadros.push({ color, luz });
    }
  }
  // recortar a lo justo y pegar en las hojas
  const cols = Math.min(16, n), w = x1 - x0 + 1, h = y1 - y0 + 1, filas = Math.ceil(n / cols), alto = filas * variantes.length;
  const hojas = { "": new Uint8ClampedArray(w * cols * h * alto * 4), "-brillo": new Uint8ClampedArray(w * cols * h * alto * 4) };
  cuadros.forEach((c, j) => {
    const v = Math.floor(j / n), i = j % n, cx = (i % cols) * w, cy = (v * filas + Math.floor(i / cols)) * h;
    for (const [sufijo, px] of [["", c.color], ["-brillo", c.luz]])
      for (let y = 0; y < h; y++) hojas[sufijo].set(px.subarray(((y0 + y) * W + x0) * 4, ((y0 + y) * W + x1 + 1) * 4), ((cy + y) * w * cols + cx) * 4);
  });
  for (const [sufijo, px] of Object.entries(hojas)) writeFileSync(join(salida, `${nombre}${sufijo}.png`), encodePNG(w * cols, h * alto, px));
  return { origen: [OX - x0, OY - y0], fotogramas: n, columnas: cols, filas, w: w * cols, h: h * alto };
}
