// Las bocanadas del chorro de fuego del jefe de bomberos (L25 y L34): las de fuego y las de humo del efecto
// "fire-breath" de pixelfx (firePuff y smokePuff de src/fx/fire/_lib.js; licencia MIT, © Patch, y la receta de las
// bocanadas, de Hugo Duprez), cada una en 10 tamaños y 10 edades, en una hoja para Godot (chorro_fuego.gd).
// Filas 0-9: fuego, de pequeña a grande (TAMANOS); filas 10-19: humo (TAMANOS × HUMO). Columnas: de recién salida a
// casi apagada. Cada casilla, de CASILLA px con la bocanada en el centro.
// Uso: node tools/pixelfx/bocanadas.mjs <carpeta de pixelfx> <carpeta de salida>
import { writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
const [PFX, SALIDA] = process.argv.slice(2).map((p) => resolve(p));
const cargar = (ruta) => import(pathToFileURL(join(PFX, ruta)));
const { createFrame, clearFrame, composite, painterFor, fit } = await cargar("src/core/index.js");
const { encodePNG } = await cargar("tools/lib/png.mjs");
const { firePuff, smokePuff, hotFirst } = await cargar("src/fx/fire/_lib.js");
const fb = await cargar("src/fx/fire/fire-breath.js");

const TAMANOS = [3, 4, 5, 6.5, 8, 10, 12.5, 15, 18, 22], HUMO = 0.75, EDADES = 10, CASILLA = 56;
const H = hotFirst(fit(fb.meta.options.palette, 9));
const W = CASILLA * EDADES, ALTO = CASILLA * TAMANOS.length * 2;
const hoja = new Uint8ClampedArray(W * ALTO * 4);
const f = createFrame(CASILLA, CASILLA), tmp = new Uint8ClampedArray(CASILLA * CASILLA * 4);
for (let fila = 0; fila < TAMANOS.length * 2; fila++) {
  for (let col = 0; col < EDADES; col++) {
    clearFrame(f);
    const p = painterFor(f).place(CASILLA / 2, CASILLA / 2), k = 1 - (col + 0.5) / EDADES;
    if (fila < TAMANOS.length) firePuff(p, 0, 0, k, TAMANOS[fila], 0.5, H, 0, 0, -0.9);
    else smokePuff(p, 0, 0, k, TAMANOS[fila - TAMANOS.length] * HUMO, 0, true, 1.2);
    f.light.fill(0);   // sin brillo: la luz del cono ya la pone el juego (luz_giro)
    composite(f, tmp, null);
    for (let y = 0; y < CASILLA; y++)
      hoja.set(tmp.subarray(y * CASILLA * 4, (y + 1) * CASILLA * 4), ((fila * CASILLA + y) * W + col * CASILLA) * 4);
  }
}
writeFileSync(join(SALIDA, "bocanadas-fuego.png"), encodePNG(W, ALTO, hoja));
console.log("bocanadas-fuego.png", W, "×", ALTO);
