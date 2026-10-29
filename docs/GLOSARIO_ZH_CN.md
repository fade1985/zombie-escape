# Glosario del chino simplificado (zh_CN) · cómo se dice cada cosa

Para que el chino suene siempre igual. **Provisional: sin revisión de una persona nativa.** Si cambia un nombre, se cambia aquí
y en `locale/zh_CN.po` (buscar y reemplazar).

## Reglas

- **Caracteres:** solo GB2312 nivel 1 (los ~3.700 más usados), comprobado carácter a carácter con un script. Por eso faltan
  algunas onomatopeyas típicas, que son de nivel 2 (哐 哔 嘟 嗷 噜 咚 咔 嗒 嘣): se usan otras (当！ 嘘——！ 啊呜！ 叮！ 蹦！).
  Otros evitados por lo mismo: 霰 (escopeta = 散弹枪), 飙, 攥, 烊, 娅, 黏.
- **Puntuación de ancho completo** (，。！？：；（）、“”). Las comillas españolas «» pasan a “”. Los puntos suspensivos, «……».
  Los `%d`/`%s`, cifras, horas (23:10) y siglas (VD-7, MP5, DNA, S-1, LB, RT…) en ASCII; «???» de la taquilla, también.
- **Porcentajes** pegados a la cifra («+25%», «%d%%»), como se escribe en chino.
- **Decimales con punto** (3.99欧元, 0.8秒). Miles sin separador (10000盒, 1000个僵尸). Segundos: «4 s» → «4秒».
- **Sin espacios** entre palabras chinas; un espacio entre `%d` y el chino solo cuando ayuda a leer («%d 个僵尸»).
- **Trato al jugador:** 你 (informal). Imperativos directos: 按、点击、选择、拉下…
- **Gritos de jefes:** cortos (≤ 8 caracteres), con «！». Sin mayúsculas en chino: la fuerza va en la frase.
- **Plural:** el chino no tiene; un solo valor (sirve para 1 y para muchos: «%d 个僵尸»).
- **Frases con nombres que llegan por `%s`:** los supervivientes llegan sin artículo (警察、电工…), y en chino no hacen falta
  artículos. Donde el orden del español no vale para el chino (los `%s` no se pueden reordenar), la frase se rehace con dos puntos o
  paréntesis: «Caíste en la %s de %s» = 你倒在了%s（%s） → «你倒在了1楼（公寓楼）»; «Junto al cuerpo de %s» = 发现于尸体旁：%s.

## Nombres propios

| Español | Chino | Notas |
|---|---|---|
| Johnny | Johnny | letras latinas (la marca) |
| Velaria · Velaria Corp. · Torre Velaria | Velaria · Velaria公司 · Velaria大厦 | latinas |
| VD-7 | VD-7 | |
| Marta Ruiz · Elena Ruiz | Marta Ruiz · Elena Ruiz | **latinas**: `Historia.REPORTERA` es `# no-tr` y el juego escribe «Marta Ruiz» tal cual; para que la reportera y su hermana se reconozcan, las dos se quedan así |
| el doctor Salas · Héctor Salas | 萨拉斯博士 · 埃克托·萨拉斯 | «Dr./Dra.» = …博士 (detrás del nombre) |
| Arturo Salcedo (el gerente) | 阿图罗·萨尔塞多 | |
| Otros firmantes del dosier | 伊内斯·洛萨诺, 托马斯·比达尔, 安德烈斯·佩尼亚, 拉蒙·希尔, 胡利安·莫拉, 曼努埃尔·奥尔特加, 露西亚·贝内特 | transcripción estándar del español; «·» entre nombre y apellido |
| Canal 8 · CANAL8.TV | 8频道 · 8频道.TV | |
| el número 14 (el edificio) | 14号楼 | |
| «Velaria Noche» (somnífero) | Velaria安睡 | |
| Programa «Turno infinito» | “无限加班”计划 | «un turno infinito para todo el país» = 让全国都无限加班 |
| Dirección (de Velaria) · SOLO DIRECCIÓN | 总部 · 仅限高层 | |

## Personajes y jefes

| Español | Chino | Notas |
|---|---|---|
| Johnny, el conserje | 清洁工 Johnny | con desprecio, el Dr. Salas le llama 扫地的 |
| la portera | 楼管大妈 | la señora del edificio que lo controla todo; su traje, «El portero» = 楼管大爷 |
| el gerente · el gerente mutado | 经理 · 变异经理 | |
| el Glotón · el Gymbro · el jefe de bomberos | 大胃王 · 健身哥 · 消防队长 | |
| el antidisturbios · el cocinero · la modista · la mascota | 防暴警察 · 厨师 · 裁缝 · 吉祥物 | |
| la criatura | 怪物 | |
| jefe(s) | 首领 | |
| Supervivientes: Policía · Militar · Médica · Farmacéutica · Ferretero · Técnico | 警察 · 士兵 · 医生 · 药剂师 · 五金店老板 · 电工 | sin artículo, como en inglés |
| superviviente(s) | 幸存者 | |

## Zombis

| Español | Chino |
|---|---|
| el vecino · el arrastrado · el crío · el dinamitero | 邻居 · 爬行者 · 熊孩子 · 自爆客 |
| el de los tentáculos · el gordo | 触手怪 · 胖子 |
| la dependienta · el vigilante · el guardia (de la tarjeta) · el maniquí | 店员 · 巡逻保安 · 持卡保安 · 假人模特 |
| durmiente · sonámbulo | 沉睡者 · 梦游者 |
| sujeto(s) · Sujeto 0 | 受试者 · 0号受试者 (el Dr. Salas, en sus gritos: 实验品) |
| horda | 尸潮 (y «一大波僵尸», guiño a Plants vs. Zombies) |

## Lugares

| Español | Chino |
|---|---|
| los Apartamentos · el Centro comercial | 公寓楼 · 购物中心 (en la charla, 商场) |
| Oficina de seguridad · Cocina central · Taller de costura · Juguetería | 保安室 · 中央厨房 · 裁缝铺 · 玩具店 |
| Planta baja · 1ª/2ª/3ª planta · %dª planta · Azotea | 底层 · 1楼/2楼/3楼 · %d楼 · 天台 (como el cartel: 0, 1, 2, 3) |
| «planta %d» como cuenta del juego (récord, reto, logro «Llega a la planta 3») | 第%d层 |
| Puertas: Bajo C · 1ºD | 底层C · 1D |
| Salón · Cocina · Baño · Dormitorio · Pasillo | 客厅 · 厨房 · 浴室 · 卧室 · 走廊 |
| Dormitorio de matrimonio · Baño principal · Dormitorio individual | 主卧 · 主卫 · 次卧 |
| Vestuario · Despacho · Taller · Gimnasio · Cuarto de la limpieza | 更衣室 · 办公室 · 工作间 · 健身房 · 保洁间 |
| sala de Mantenimiento · Viviendas · TRASTEROS | 维修间 · 生活区 · 储藏室 |
| Tiendas: Supermercado · Ferretería · Electrónica · Restaurante · Tienda de ropa · Farmacia · Joyería | 超市 · 五金店 · 电器店 · 餐厅 · 服装店 · 药店 · 珠宝店 |
| Neones: SUPER · FERRETERIA · ELECTRO · BURGER · MODA · FARMACIA · JOYAS | 超市 · 五金 · 电器 · 汉堡 · 时装 · 大药房 · 珠宝 |
| Almacén · Cámara frigorífica · Taquillas · Probadores · Rebotica · Aseo · Trastienda · Cámara acorazada | 仓库 · 冷库 · 储物间 · 试衣间 · 配药间 · 厕所 · 库房 · 金库 |
| cuadro eléctrico · palanca · barricada · valla | 配电箱 · 电闸 («Baja la palanca» = 拉下电闸) · 路障 · 围栏 |
| tarjeta de acceso · tarjeta dorada · apertura de emergencia | 门禁卡 · 金卡 · 紧急开启 |

## Armas, munición, objetos

| Español | Chino |
|---|---|
| Fregona · Bate · Cuchillo · Pistola · Escopeta · MP5 | 拖把 · 球棒 · 小刀 · 手枪 · 散弹枪 · MP5 |
| Lanzallamas · Lanza ácido · Lanza rayos | 火焰喷射器 · 酸液枪 · 闪电枪 |
| Balas de pistola · Cartuchos · Gasolina · Bidón de ácido · Batería | 手枪子弹 · 散弹 · 汽油 · 酸液桶 · 电池 |
| Molotov · Granada · Atraedora · Congeladora · arrojables | 燃烧瓶 · 手雷 · 诱饵弹 · 冰冻弹 · 投掷物 |
| Cuerpo a cuerpo · A distancia · Especial | 近战 · 远程 · 特殊 |
| Normal · Poco común · Rara · Épica | 普通 · 优秀 · 稀有 · 史诗 |
| Truco (de la Épica) | 绝活 |
| Vendas · Botiquín · Desfibrilador | 绷带 · 急救包 · 除颤器 |
| piezas (de mejora) | 零件 (升级零件) |
| cargador · depósito · reserva · recargar | 弹匣 · 储罐 · 备弹 · 换弹 |

## Interfaz

| Español | Chino |
|---|---|
| JUGAR · Tutorial · Opciones · Pantalla completa · Salir · Volver | 开始 · 教程 · 选项 · 全屏 · 退出 · 返回 |
| Opciones: General · Controles · Ayudas · Móvil · Mando · Teclado y ratón | 常规 · 操作 · 辅助 · 手机 · 手柄 · 键盘和鼠标 |
| Sí / No (interruptores) | 开 / 关 |
| Modo de atacar: Asistido / Apuntar libre | 攻击模式：辅助瞄准 / 自由瞄准 |
| Ayudas: Vida entera · Pistola sin fin · Lanzar apuntando solo | 完整生命 · 无限手枪 · 自动瞄准投掷 |
| Teclas: Espacio · Mayús · Intro · Borrar · Flecha izq. · Clic izq./dcho. · Clic rueda · Rueda | 空格 · Shift · 回车 · 退格 · 左方向键 · 鼠标左键/右键 · 鼠标中键 · 滚轮 |
| Mando: Stick izq./dcho. · Cruceta arriba · Guía · Select/Start/LB/RT | 左摇杆/右摇杆 · 十字键上 · 指南 · igual |
| Inventario · mochila · baúl · Banco de trabajo · Taquilla (de Johnny) | 物品栏 · 背包 · 储物箱 · 工作台 · 储物柜 |
| En la mano · De repuesto · A la mano · Al repuesto | 手上 · 备用 · 放到手上 · 放入备用 |
| Ponérmela · Tirar al suelo · Destruir · Usar · Sacar · Guardar | 装备 · 丢在地上 · 销毁 · 使用 · 取出 · 存入 |
| Seguir (inventario) · Continuar (pausa) · Seguir (dosier) | 继续 |
| Pausa · Abandonar partida · Jugar otra vez · Menú principal | 暂停 · 放弃本局 · 再玩一局 · 主菜单 |
| Vida · Velocidad · Daño recibido · Crítico | 生命 · 移动速度 · 受到伤害 · 暴击率 |
| partida | 一局 / 本局 («Búscalo en una partida» = 开一局去找吧) |
| Alerta %d · Sin alerta · Reto del día | 警戒 %d · 无警戒 · 每日挑战 |
| dólares · puntos de talento · logros · premio | 美元 ($%d) · 天赋点 · 成就 · 奖励 |
| Dosier · Noticias · Colecciones · Bestiario · Emisión %d | 档案 · 新闻 · 收藏品 · 图鉴 · 第 %d 期 |
| ConserjeOS · CONSERJE OS 95 · C:\MANTENIMIENTO\ | 保洁OS · 保洁 OS 95 · C:\维修间\ |
| PUNTOS.EXE · ARMAS.EXE · LOGROS.EXE · DOSIER.TXT · COLECCION.EXE | 天赋点.EXE · 武器.EXE · 成就.EXE · 档案.TXT · 收藏.EXE |
| ¡NOTICIAS NUEVAS! · EN DIRECTO · ÚLTIMA HORA | 突发新闻！ · 直播 · 最新消息 |
| ¡Piso limpio! | 清理完毕！ |
| skin | 皮肤 |
| Apagón · Alarma de incendios · Horda | 停电 · 火警 · 尸潮 |

## Talentos (adaptaciones)

| Español | Chino |
|---|---|
| Ramas: Militar · Superviviente · Químico | 军人 · 幸存者 · 化学家 |
| Ataque · Puntería · Camorrista · Tirador · Artificiero · Larguirucho · Mirilla · Fabricante | 攻击 · 准头 · 打架王 · 神枪手 · 爆破专家 · 长臂猿 · 瞄准镜 · 炸弹匠 |
| Frenesí · Gatillo fácil · Racimo · Veterano | 狂暴 · 扳机狂 · 集束 · 老兵 |
| Corpulento · Lobezno · Durito · Reflejos · Sanitario · Acero · Ninja · Desfibrilador | 壮汉 · 金刚狼 · 硬骨头 · 反射神经 · 医护兵 · 钢铁 · 忍者 · 除颤器 |
| Blindaje · Sombra · Segundo aliento · Adrenalina | 装甲板 · 暗影 · 绝处逢生 (también el grito «¡Segundo aliento!») · 肾上腺素 |
| Catalizador · Guantes de goma · Incendiario · Desatascador · Criogenia | 催化剂 · 橡胶手套 · 火上浇油 · 疏通剂 · 极寒 |
| Reacción en cadena · Residuo tóxico · Pararrayos · Napalm · Pegajoso · Alto voltaje · Mezcla explosiva | 连锁反应 · 有毒废料 · 避雷针 · 凝固汽油 · 粘糊糊 · 高压电 · 爆炸配方 |

## Logros (adaptaciones)

| Español | Chino |
|---|---|
| Primer turno · Sube, conserje · Fin de la jornada · Liquidación total | 首次上岗 · 步步高升 · 下班时间 · 清仓大甩卖 |
| Alerta naranja · Alerta máxima · Jornada exprés · Empleado del mes | 橙色警戒 · 红色警戒 · 光速下班 · 本月最佳员工 |
| Desahucio · Sin un rasguño · Por los pelos · Visto y no visto · Cazajefes | 扫地出门 · 毫发无伤 · 千钧一发 · 速战速决 · 首领猎人 |
| Fregona de oro · Exterminador · Limpieza general · Pirómano · Racha imparable · Intocable | 金拖把 · 除害专家 · 大扫除 · 纵火狂 · 势不可挡 · 无懈可击 |
| Sin tiritas · Manitas · Joya de la corona · Arsenal completo · Especialista · Conserje total | 不用创可贴 · 能工巧匠 · 镇店之宝 · 全副武装 · 专家 · 全能清洁工 |
| Buen vecino · Comunidad de vecinos · Plantilla completa · Buena compañía · Caja fuerte | 好邻居 · 业主委员会 · 全员到齐 · 结伴同行 · 金库大盗 |
| Se fue la luz · Simulacro · Contra la marea · Reto aceptado · Ninguna regla me para | 黑灯瞎火 · 消防演习 · 逆流而上 · 接受挑战 · 规则拦不住我 |
| Cambio de look · Vestuario completo · Naturalista · Investigador · Chatarrero | 改头换面 · 衣柜齐全 · 博物学家 · 调查员 · 破烂王 |
| Temas: Edificios · Jefes · Combate · Armas y talentos · Supervivientes · Sorpresas y retos · Colecciones | 大楼 · 首领 · 战斗 · 武器与天赋 · 幸存者 · 意外与挑战 · 收藏品 |

## Mutaciones, trajes y reglas del reto

| Español | Chino |
|---|---|
| Tentacular · Gastroenteritis · Insensible · Caníbal | 触手缠身 · 肠胃炎 · 麻木 · 食人魔 |
| Ansiedad · Endurecimiento · Locura · Flatulento | 焦虑 · 皮糙肉厚 · 疯狂 · 屁王 |
| Trajes: Conserje · El portero · El glotón · El gymbro · El bombero | 清洁工 · 楼管大爷 · 大胃王 · 健身哥 · 消防员 |
| Reto: Solo cuerpo a cuerpo · Todo a oscuras · Sin curas · Zombis rápidos | 只许近战 · 一片漆黑 · 不许治疗 · 快速僵尸 |
| Reto: De cristal · Casa llena · Oído fino | 玻璃人 · 人满为患 · 顺风耳 |

## Gritos (adaptados)

| Español | Chino |
|---|---|
| Portera: ¡QUE ACABO DE FREGAR! · ¡VECINOS! · ¡LEJÍA! · ¡ÁCIDO! · ¡A BARRER! | 我刚拖的地！ · 街坊们！ · 消毒液！ · 酸液！ · 统统扫走！ |
| Gerente: ¡A TRABAJAR! · ¡AQUÍ NO PARA NADIE! | 都给我干活！ · 谁也不准下班！ |
| Gymbro: ¡HORA DE LOS SUPLEMENTOS! · ¡SIN SUPLEMENTOS! · ¡NO PAIN, NO GAIN! | 该吃补剂了！ · 补剂没了！ · NO PAIN, NO GAIN! |
| Glotón: ¡HAMBRE! · ¡ÑAM! · ¡TENGO HAMBRE! | 好饿！ · 啊呜！ · 饿死我了！ |
| Bombero: ¡A ARDER! · ¡INMUNE! · ¡TODO ARDE! | 消防演习！ · 免疫！ · 一片火海！ |
| Dr. Salas: ¡MÁS SUJETOS! · ¡DOSIS DOBLE! · ¡SUERO! · ¡NO ME TOCARÁS! · ¡MI CÚPULA! · ¡AÚN NO HE TERMINADO! | 再来点实验品！ · 双倍剂量！ · 血清！ · 扫地的，别碰我！ · 我的玻璃罩！ · 我还没完呢！ |
| Cocinero · Modista · Mascota | 趁热吃！ / 下锅！ · 嘶——！ / 给你量尺寸！ · 免费抱抱！ / 蹦！ / 游戏时间！ |
| Antidisturbios: ¡PRIIIII! · ¡ATRÁS! · ¡QUEDAS DETENIDO! · ¡CLONC! | 嘘——！ · 退后！ · 你被捕了！ · 当！ |
| Dependienta: ¡OFERTAS! · Guardia: ¡PRIIII! / uf | 大促销！ · 嘘——！ / 呼 |
