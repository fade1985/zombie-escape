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
import { copyFileSync } from "node:fs";
import { exportarVariantes } from "./hojas.mjs";
import { join, resolve, dirname } from "node:path";
import { pathToFileURL, fileURLToPath } from "node:url";
const [PFX, SALIDA] = process.argv.slice(2).map((p) => resolve(p));
const AQUI = dirname(fileURLToPath(import.meta.url)), destino = join(PFX, "src/fx/projectiles/fogonazo.js");
copyFileSync(join(AQUI, "fogonazo.js"), destino);
const mod = await import(pathToFileURL(destino));
const RAD = Math.PI / 180;
const FORMAS = { pistola: [3, 11], mp5: [6, 17, 29], escopeta: [5] };
const resumen = [];

for (const arma of ["pistola", "mp5", "escopeta"]) {
  for (const parte of ["llama", "humo"]) {
    const fps = parte === "llama" ? 30 : 15, n = Math.round(mod.DURA[arma][parte] * fps);
    const variantes = parte === "llama"
      ? FORMAS[arma].flatMap((seed) => Array.from({ length: 9 }, (_, i) => ({ seed, angle: (-90 + 22.5 * i) * RAD, rumbo: 0, arma, parte })))
      : Array.from({ length: 5 }, (_, i) => ({ seed: FORMAS[arma][0], angle: 0, rumbo: (-90 + 45 * i) * RAD, arma, parte }));
    const m = await exportarVariantes(PFX, mod, variantes, n, fps, SALIDA, `fogonazo-${arma}-${parte}`);
    resumen.push(`"${arma}-${parte}": {"origen": Vector2(${m.origen}), "fotogramas": ${n}, "columnas": ${m.columnas}, "filas": ${m.filas}, "fps": ${fps}, "formas": ${parte === "llama" ? FORMAS[arma].length : 1}},   # ${m.w}x${m.h}`);
  }
}
console.log(resumen.join("\n"));
