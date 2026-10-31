// Exporta la chispa de las balas al dar a un zombi (tools/pixelfx/chispa.js) para Godot, en dos tallas: la de una bala
// (chispa-bala) y la de un perdigón (chispa-perdigon), cada una con su color y su brillo (que se suma con mezcla
// "añadir"). En cada hoja, una variante detrás de otra: los 5 colores (normal, crítica, poco común, rara y épica), y
// en cada color 5 direcciones (-90° hacia arriba, -45°, 0° a la derecha, 45° y 90° hacia abajo). Hacia la izquierda,
// el juego la da la vuelta. A 30 fotogramas por segundo, recortadas a lo justo.
// Al final escribe las medidas que hay que copiar en scripts/chispa.gd (TIPOS).
// Uso: node tools/pixelfx/exportar_chispa.mjs <carpeta de pixelfx> <carpeta de salida>
// (pixelfx: git clone https://github.com/patch-gg/pixelfx). Copia el efecto dentro de pixelfx, en src/fx/impacts/.
import { copyFileSync } from "node:fs";
import { join, resolve, dirname } from "node:path";
import { pathToFileURL, fileURLToPath } from "node:url";
import { exportarVariantes } from "./hojas.mjs";
const [PFX, SALIDA] = process.argv.slice(2).map((p) => resolve(p));
const AQUI = dirname(fileURLToPath(import.meta.url)), destino = join(PFX, "src/fx/impacts/chispa.js");
copyFileSync(join(AQUI, "chispa.js"), destino);
const mod = await import(pathToFileURL(destino));
const RAD = Math.PI / 180, FPS = 30, n = Math.round(mod.meta.duration * FPS);
const resumen = [];
for (const [talla, K] of [["bala", 0.7], ["perdigon", 0.45]]) {
  const variantes = Object.values(mod.COLORES).flatMap((palette) =>
    Array.from({ length: 5 }, (_, i) => ({ palette, aim: (-90 + 45 * i) * RAD, talla: K, seed: 4 + i })));
  const m = await exportarVariantes(PFX, mod, variantes, n, FPS, SALIDA, `chispa-${talla}`);
  resumen.push(`"${talla}": {"origen": Vector2(${m.origen}), "fotogramas": ${n}, "columnas": ${m.columnas}, "filas": ${m.filas}},   # ${m.w}x${m.h}`);
}
console.log("colores:", Object.keys(mod.COLORES).join(", "));
console.log(resumen.join("\n"));
