// Exporta la explosión (tools/pixelfx/explosion.js) para Godot: dos hojas (el color y el brillo, que se suma con mezcla
// "añadir"), con sus dos capas (la de atrás lleva el humo y la marca del suelo), recortadas a lo justo, de los primeros DURA segundos a FPS (lo que sigue es humo casi invisible y la marca
// del suelo; la granada ya deja su mancha chamuscada). Al final escribe las medidas que hay que copiar en
// scripts/explosion.gd (HOJA).
// Uso: node tools/pixelfx/exportar_explosion.mjs <carpeta de pixelfx> <carpeta de salida>
// (pixelfx: git clone https://github.com/patch-gg/pixelfx). Copia el efecto dentro de pixelfx, en src/fx/explosions/.
import { copyFileSync } from "node:fs";
import { exportarVariantes } from "./hojas.mjs";
import { join, resolve, dirname } from "node:path";
import { pathToFileURL, fileURLToPath } from "node:url";
const [PFX, SALIDA] = process.argv.slice(2).map((p) => resolve(p));
const AQUI = dirname(fileURLToPath(import.meta.url)), destino = join(PFX, "src/fx/explosions/explosion-juego.js");
copyFileSync(join(AQUI, "explosion.js"), destino);
const mod = await import(pathToFileURL(destino));
const FPS = 30, DURA = 2.5;
const m = await exportarVariantes(PFX, mod, [{ ...mod.meta.options }], Math.round(DURA * FPS), FPS, SALIDA, "explosion", ["back", "front"]);
console.log(`"explosion": origen ${JSON.stringify(m.origen)}, fotogramas ${m.fotogramas}, columnas ${m.columnas}, filas ${m.filas}, fps ${FPS}  (${m.w}x${m.h} cada uno)`);
