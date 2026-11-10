// «Contáctanos» (Opciones → General del juego): el jugador escribe un mensaje y el juego lo manda aquí. Esto es un
// programita de Vercel (va con la web: https://zombie-escape-two.vercel.app/api/contacto) que abre con el mensaje un aviso
// (issue) en el repositorio PRIVADO fade1985/zombie-escape-mensajes. Ahí os llega a los dos y Claude lo lee y lo analiza
// (docs/MENSAJES.md).
//
// El juego no puede escribir en GitHub por su cuenta: la llave iría dentro del .exe y de la web, y cualquiera podría sacarla.
// La llave está solo aquí, en Vercel (Settings → Environment Variables → GITHUB_TOKEN_MENSAJES), y solo sirve para abrir
// avisos en ese repositorio.
//
// No se guarda nada del jugador: ni su dirección (IP) ni ningún dato suyo. Solo el mensaje y, si deja marcada la casilla,
// los datos técnicos (versión, sistema y las últimas líneas del registro, ya limpias de rutas con su nombre: contacto.gd).
// Contra el abuso: el juego manda una cabecera suya (X-Juego), el mensaje tiene un largo máximo y cada instancia de
// Vercel acepta unos pocos mensajes por hora desde el mismo sitio (y unos cuantos en total). Si un día llega spam, se
// borra la llave en Vercel y esto deja de abrir avisos.

const REPO = "fade1985/zombie-escape-mensajes"
const MAX_MENSAJE = 1000      // lo mismo que deja escribir el juego (contacto.gd, MAX_LETRAS)
const MAX_REGISTRO = 20000
const MAX_DATO = 200
const POR_HORA_DESDE_UN_SITIO = 5
const POR_HORA_EN_TOTAL = 40
const HORA = 60 * 60 * 1000

// Cuándo llegó cada mensaje, por sitio: solo en la memoria de esta instancia, y se olvida a la hora
const llegados = new Map()
let en_total = []

function demasiados(sitio) {
  const ahora = Date.now()
  en_total = en_total.filter((t) => ahora - t < HORA)
  const suyos = (llegados.get(sitio) || []).filter((t) => ahora - t < HORA)
  if (suyos.length >= POR_HORA_DESDE_UN_SITIO || en_total.length >= POR_HORA_EN_TOTAL) return true
  suyos.push(ahora)
  llegados.set(sitio, suyos)
  en_total.push(ahora)
  for (const [k, v] of llegados) if (v.every((t) => ahora - t >= HORA)) llegados.delete(k)
  return false
}

// Un dato corto, en una línea y sin «|» (que rompería la tabla)
function corto(valor) {
  return String(valor ?? "").replace(/[\r\n|]+/g, " ").trim().slice(0, MAX_DATO) || "?"
}

// Un texto dentro de un bloque ~~~~: así GitHub no lo convierte en enlaces, menciones (@alguien) ni dibujos
function bloque(texto) {
  return "~~~~text\n" + String(texto).replace(/~{4,}/g, "~~~") + "\n~~~~"
}

module.exports = async (req, res) => {
  res.setHeader("Access-Control-Allow-Origin", "*")
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS")
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, X-Juego")
  if (req.method === "OPTIONS") return res.status(204).end()
  if (req.method !== "POST") return res.status(405).json({ error: "solo POST" })
  if (req.headers["x-juego"] !== "johnny-rush") return res.status(403).json({ error: "no viene del juego" })

  let datos = req.body
  if (typeof datos === "string") {
    try { datos = JSON.parse(datos) } catch { datos = null }
  }
  if (!datos || typeof datos !== "object") return res.status(400).json({ error: "sin datos" })
  const mensaje = String(datos.mensaje ?? "").replace(/\r\n/g, "\n").trim()
  if (mensaje.length < 3 || mensaje.length > MAX_MENSAJE) return res.status(400).json({ error: "mensaje vacío o largo" })

  const token = process.env.GITHUB_TOKEN_MENSAJES
  if (!token) return res.status(503).json({ error: "falta la llave en Vercel" })

  const sitio = String(req.headers["x-forwarded-for"] || "").split(",")[0].trim() || "?"
  if (demasiados(sitio)) return res.status(429).json({ error: "demasiados mensajes" })

  const titulo = "Mensaje: " + (mensaje.replace(/\s+/g, " ").length > 60
    ? mensaje.replace(/\s+/g, " ").slice(0, 60) + "…"
    : mensaje.replace(/\s+/g, " "))
  let cuerpo = bloque(mensaje) + "\n\n" +
    "| Versión | Sistema | Idioma | Dónde |\n|---|---|---|---|\n" +
    `| ${corto(datos.version)} | ${corto(datos.sistema)} | ${corto(datos.idioma)} | ${corto(datos.plataforma)} |\n`
  if (datos.registro) {
    cuerpo += "\n<details><summary>Registro (las últimas líneas)</summary>\n\n" +
      bloque(String(datos.registro).slice(-MAX_REGISTRO)) + "\n</details>\n"
  } else {
    cuerpo += "\n_Sin datos técnicos: el jugador desmarcó la casilla._\n"
  }

  try {
    const respuesta = await fetch(`https://api.github.com/repos/${REPO}/issues`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "johnny-rush-contacto",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ title: titulo, body: cuerpo }),
    })
    if (!respuesta.ok) {
      console.error("GitHub no ha abierto el aviso:", respuesta.status, (await respuesta.text()).slice(0, 300))
      return res.status(502).json({ error: "GitHub no lo ha aceptado" })
    }
    return res.status(201).json({ ok: true })
  } catch (e) {
    console.error("No se ha podido hablar con GitHub:", e)
    return res.status(502).json({ error: "sin conexión con GitHub" })
  }
}
