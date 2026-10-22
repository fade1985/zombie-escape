# Jefes de los Apartamentos (decidido con el dueño, 22 oct 2026)

Hoy en los Apartamentos la portera es la jefa de todas las plantas. Pasan a tener, como el centro comercial
(`docs/CENTRO_COMERCIAL.md`, trozos 2 y 6), **cuatro minijefes al azar** y **un jefe final en la azotea**.

## Lo decidido

- **Minijefes:** portera, Glotón, Gymbro y jefe de bomberos. **Uno por planta, en orden al azar en cada partida y
  sin repetir** (como `minijefes` del centro en `edificios.gd`). Tamaño de zombi grande (lienzo de 72), como los del
  centro. Lo común ya está en `scripts/minijefe.gd` (aparece al entrar, barra grande, +25 % de vida por planta, se
  enfada a media vida, botín y mutación al caer).
- **Jefe final, siempre en la azotea:** el científico jefe. **Más grande de lo normal, como el gerente** (lienzo de 128,
  unos 117 px) y con **dos fases: en la segunda se transforma** (como el gerente con la jeringa).
- Mientras un jefe no esté hecho, en su sitio sale la portera (como en el centro).
- **Una sesión por jefe.** En PixelLab, decir el coste antes de generar. Los números son provisionales: se ajustan
  jugando. Si hay que cambiar algo del diseño, se cambia después.
- Las marcas, fuera: nada de logos, rayas ni nombres de marcas reales en la ropa.

## 1. El Glotón (minijefe; diseño del dueño)

**Aspecto:** grotesco y lento, va **a gatas**. Calzoncillos sucios, camiseta interior sin mangas sucia y calcetines
sucios. La **cabeza tan grande o más que el cuerpo**, llena de **ampollas de ácido** a punto de reventar. **Boca
gigante con varias filas de dientes** y **lenguas como látigos** que le salen de ella.

**Fase 1**
- Lento: la cabeza le pesa más que el cuerpo.
- Latigazos con las lenguas: hacen daño si te alcanzan.
- Durante **5 s** intenta aspirarte para comerte; si te alcanza, mucho daño.
- Cada golpe o disparo que le das salpica sangre ácida: **1 % de daño** a Johnny.

**Fase 2**
- El doble de lenguas.
- El doble de fuerza al aspirar.
- La sangre ácida, **2 %** por golpe.

*Nota de Claude:* con armas rápidas (MP5) el salpicón suma mucho; quizá uno cada medio segundo como mucho.

## 2. El Gymbro (minijefe; diseño del dueño)

**Aspecto:** muy musculoso, con **cuádriceps y manos gigantes** comparados con el resto del cuerpo; **arrastra las
manos** por el suelo de lo grandes que son. Calvo y con barba, **la piel se le cae a cachos**. Torso desnudo,
pantalón de chándal y zapatillas deportivas de estilo clásico, **sin marca ni rayas**.

**Fase 1**
- Embiste con los brazos abiertos, formando un torbellino a su paso.
- Salta e intenta caer encima de Johnny.
- Lanza pesas como proyectiles.

**Fase 2**
- Se toma unos suplementos: **barra de armadura** (encima de la de vida); mientras dure, solo le entra el **50 %**
  del daño.
- Hasta **2 torbellinos seguidos**.
- El salto dura la mitad.
- El doble de pesas.

## 3. El jefe de bomberos (minijefe; aspecto de Claude, con visto bueno)

**Aspecto:** grande y ancho, con el **traje ignífugo chamuscado y abierto por el pecho**, que deja ver brasas por
dentro, como si ardiera por dentro. **Casco con la visera rota que echa humo**, la botella de oxígeno de la espalda
hecha **depósito de gasolina** y una **manguera que escupe fuego** en vez de agua. Por las grietas de la piel asoma
la lumbre.

**Fase 1**
- El traje lo protege: **el fuego no le hace nada** (molotov, lanzallamas, bate de fuego...), así que obliga a
  cambiar de arma.
- Bolas de fuego: daño al dar y daño con el tiempo.
- Se pone en el centro de la sala y **gira con el lanzallamas**: daño al dar y con el tiempo.
- Molotovs que dejan charcos de fuego: daño al entrar y con el tiempo.
- **Hachazo de bombero** si Johnny se le pega (para que pegarle de cerca no salga gratis).

**Fase 2**
- El doble de bolas de fuego, de lenguas de fuego en el giro y de charcos.
- **Se le rompe el traje y entra en llamas:** deja un rastro de fuego al andar.

## 4. El científico jefe (jefe final de la azotea; de Claude, con visto bueno)

Grande como el gerente (lienzo de 128). Encaja con la historia de Velaria (`docs/CENTRO_COMERCIAL.md`): es quien
estaba detrás de lo que pasa en el edificio.

**Fase 1: el científico.** Bata blanca manchada, gafas de laboratorio y una jeringa enorme. Rápido, no pega de cerca:
- Lanza **probetas** que dejan charcos de colores: ácido, veneno y uno que resbala (los estados ya existen).
- **Inyecta suero a los zombis** de la azotea y los hace más fuertes.
- Se esconde tras una **cúpula de cristal** que hay que romper.

**Transformación** (a media vida): se pincha a sí mismo; se le revienta la bata y crece (como la mutación del
gerente: fogonazo, temblor y rugido).

**Fase 2: la criatura.** Una masa enorme hecha con trozos de los otros jefes (**la boca del Glotón, los brazos del
Gymbro y el fuego del bombero**), como si fuera él quien los hubiera creado. Ataques que los recuerdan:
lenguas-látigo, puñetazos al suelo con onda expansiva y escupitajos de fuego.

## Orden de trabajo (una sesión cada uno)

1. **Glotón**, y de paso el sorteo de minijefes en los Apartamentos (`minijefes` en su ficha de `edificios.gd`;
   donde toque uno sin hacer, la portera).
2. **Gymbro.**
3. **Jefe de bomberos.**
4. **Científico jefe**, y de paso la azotea en los Apartamentos (`azotea` y `final` en su ficha, como el centro).

Cada uno: modelo en PixelLab (coste antes) → visto bueno del aspecto → animaciones → su script (hereda de
`minijefe.gd`) → ficha del bestiario → prueba → visto bueno del dueño → commit y push solo de sus archivos.
