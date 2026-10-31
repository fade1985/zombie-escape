// Exporta los fogonazos (tools/pixelfx/fogonazo.js) para Godot: por cada arma, dos partes en dos hojas cada una
// (el color y el brillo, que se suma con mezcla "añadir"):
//  - <arma>-llama: la llama girada (con la opción "angle" de pixelfx, sin perder píxeles) en 9 ángulos, de -90° (hacia
//    arriba) a 90° (hacia abajo) de 22,5 en 22,5, a 30 fotogramas por segundo. Hacia la izquierda, el juego la da la vuelta.
//    La pistola tiene 2 formas y la MP5 3, para que la ráfaga no se repita: van una detrás de otra (forma 0 sus 9 ángulos,
//    forma 1...).
//  - <arma>-humo: el humo en 5 rumbos (-90°, -45°, 0°, 45° y 90°), a 15 fotogramas por segundo (va despacio), sin girar (sube siempre).
// Cada variante (forma y ángulo) ocupa sus filas de hasta 16 columnas; todas las hojas, recortadas a lo justo.
// Al final escribe las medidas que hay que copiar en scripts/fogonazo.gd (TIPOS).
// Uso: node tools/pixelfx/exportar_fogonazo.mjs <carpeta de pixelfx> <carpeta de salida>
// (pixelfx: git clone https://github.com/patch-gg/pixelfx). Copia el efecto dentro de pixelfx, en src/fx/projectiles/.
import { writeFileSync, copyFileSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { pathToFileURL, fileURLToPath } from "node:url";
const [PFX, SALIDA] = process.argv.slice(2).map((p) => resolve(p));
const AQUI = dirname(fileURLToPath(import.meta.url)), destino = join(PFX, "src/fx/projectiles/fogonazo.js");
copyFileSync(join(AQUI, "fogonazo.js"), destino);
const { createFrame, clearFrame, createFx, composite } = await import(pathToFileURL(join(PFX, "src/core/index.js")));
const { encodePNG } = await import(pathToFileURL(join(PFX, "tools/lib/png.mjs")));
const mod = await import(pathToFileURL(destino));
const [W, H] = mod.meta.size, [OX, OY] = mod.meta.origin, COLS = 16, RAD = Math.PI / 180;
const FORMAS = { pistola: [3, 11], mp5: [6, 17, 29], escopeta: [5] };
const resumen = [];

for (const arma of ["pistola", "mp5", "escopeta"]) {
  for (const parte of ["llama", "humo"]) {
    const fps = parte === "llama" ? 30 : 15, n = Math.round(mod.DURA[arma][parte] * fps);
    const variantes = parte === "llama"
      ? FORMAS[arma].flatMap((seed) => Array.from({ length: 9 }, (_, i) => ({ seed, angle: (-90 + 22.5 * i) * RAD, rumbo: 0 })))
      : Array.from({ length: 5 }, (_, i) => ({ seed: FORMAS[arma][0], angle: 0, rumbo: (-90 + 45 * i) * RAD }));
    // dibujar todos los fotogramas de todas las variantes (color y luz por separado)
    const cuadros = [], f = createFrame(W, H);
    let x0 = W, y0 = H, x1 = -1, y1 = -1;
    for (const v of variantes) {
      const fx = createFx(mod, { x: OX, y: OY, angle: v.angle, arma, parte, rumbo: v.rumbo, seed: v.seed });
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
    const cols = Math.min(COLS, n), w = x1 - x0 + 1, h = y1 - y0 + 1, filas = Math.ceil(n / cols), alto = filas * variantes.length;
    const hojas = { "": new Uint8ClampedArray(w * cols * h * alto * 4), "-brillo": new Uint8ClampedArray(w * cols * h * alto * 4) };
    cuadros.forEach((c, j) => {
      const v = Math.floor(j / n), i = j % n, cx = (i % cols) * w, cy = (v * filas + Math.floor(i / cols)) * h;
      for (const [sufijo, px] of [["", c.color], ["-brillo", c.luz]])
        for (let y = 0; y < h; y++) hojas[sufijo].set(px.subarray(((y0 + y) * W + x0) * 4, ((y0 + y) * W + x1 + 1) * 4), ((cy + y) * w * cols + cx) * 4);
    });
    for (const [sufijo, px] of Object.entries(hojas)) writeFileSync(join(SALIDA, `fogonazo-${arma}-${parte}${sufijo}.png`), encodePNG(w * cols, h * alto, px));
    resumen.push(`"${arma}-${parte}": {"origen": Vector2(${OX - x0}, ${OY - y0}), "fotogramas": ${n}, "columnas": ${cols}, "filas": ${filas}, "fps": ${fps}, "formas": ${parte === "llama" ? FORMAS[arma].length : 1}},   # ${w * cols}x${h * alto}`);
  }
}
console.log(resumen.join("\n"));
