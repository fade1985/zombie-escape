// Exporta un efecto de pixelfx en tres hojas para Godot (8 columnas, a 20 fotogramas por segundo): lo que va detrás
// del personaje, lo de delante y su brillo (para sumar, con mezcla "añadir").
// Uso: node tools/pixelfx/exportar.mjs <carpeta de pixelfx> <efecto.js de esta carpeta> <carpeta de salida>
// (pixelfx: git clone https://github.com/patch-gg/pixelfx). Copia el efecto dentro de pixelfx, en src/fx/holy/.
import { writeFileSync, copyFileSync } from "node:fs";
import { basename, join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
const [PFX, EFECTO, SALIDA] = process.argv.slice(2).map((p) => resolve(p));
const nombre = basename(EFECTO, ".js"), destino = join(PFX, "src/fx/holy", nombre + ".js");
copyFileSync(EFECTO, destino);
const { createFrame, clearFrame, createFx, composite } = await import(pathToFileURL(join(PFX, "src/core/index.js")));
const { encodePNG } = await import(pathToFileURL(join(PFX, "tools/lib/png.mjs")));
const mod = await import(pathToFileURL(destino));
const [W, H] = mod.meta.size, [OX, OY] = mod.meta.origin, FPS = 20, COLS = 8;
const n = Math.round(mod.meta.duration * FPS), rows = Math.ceil(n / COLS);
const fx = createFx(mod, { x: OX, y: OY, actor: null });
const sheets = { detras: new Uint8ClampedArray(W * COLS * H * rows * 4), delante: new Uint8ClampedArray(W * COLS * H * rows * 4), brillo: new Uint8ClampedArray(W * COLS * H * rows * 4) };
const f = createFrame(W, H), tmp = new Uint8ClampedArray(W * H * 4), luz = new Uint32Array(W * H);
const pegar = (dst, src, i) => {
  const cx = (i % COLS) * W, cy = Math.floor(i / COLS) * H;
  for (let y = 0; y < H; y++) dst.set(src.subarray(y * W * 4, (y + 1) * W * 4), ((cy + y) * W * COLS + cx) * 4);
};
for (let i = 0; i < n; i++) {
  if (i > 0) fx.update(1 / FPS);
  luz.fill(0);
  for (const capa of ["back", "front"]) {
    clearFrame(f);
    fx.draw(f, capa);
    for (let k = 0; k < W * H; k++) {   // la luz de las dos capas, sumada
      const a = luz[k], b = f.light[k];
      luz[k] = Math.min(255, (a & 255) + (b & 255)) | (Math.min(255, ((a >> 8) & 255) + ((b >> 8) & 255)) << 8) | (Math.min(255, ((a >> 16) & 255) + ((b >> 16) & 255)) << 16);
    }
    f.light.fill(0);
    pegar(sheets[capa === "back" ? "detras" : "delante"], composite(f, tmp, null), i);
  }
  const out = new Uint8ClampedArray(W * H * 4);
  for (let k = 0; k < W * H; k++) {
    const l = luz[k] & 0xffffff;
    out[k * 4] = l & 255; out[k * 4 + 1] = (l >> 8) & 255; out[k * 4 + 2] = (l >> 16) & 255; out[k * 4 + 3] = l ? 255 : 0;
  }
  pegar(sheets.brillo, out, i);
}
for (const [capa, px] of Object.entries(sheets)) writeFileSync(join(SALIDA, `${nombre}-${capa}.png`), encodePNG(W * COLS, H * rows, px));
console.log(n, "fotogramas", W, H, "cols", COLS, "filas", rows);
