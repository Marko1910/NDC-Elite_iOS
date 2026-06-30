# Diseños NDC HQ (exportados de Stitch)

Origen: proyecto Stitch **"Remix of NDC Performance Hub"** (ID `13676274385961218082`).
Cada pantalla tiene su **`.png`** (referencia visual) y su **`.html`** (markup Tailwind
generado por Stitch, útil para portar colores/espaciados exactos al design system).

Separado por rol: `atleta/` y `coach/`. **La UI que se construye ahora es la de atleta.**

Para descargar/actualizar más pantallas se usa el MCP de Stitch (`get_screen`),
ya registrado en este proyecto (`claude mcp list` → `stitch`).

## Atleta (`diseño/atleta/`)

| Archivo | Pantalla Stitch | Vista en FLOWS.md | Tab |
|---|---|---|---|
| `01-dashboard` | NDC HQ - Dashboard | `AthleteDashboardView` | 1 · Inicio |
| `02-wod-detallado-tecnica` | WOD Detallado (técnica por ejercicio) | `WodDetailView` | 2 · WOD |
| `03-registro-resultados-wod` | Registro de Resultados - WOD Optimizado | `LogWodResultSheet` | 2 · WOD |
| `04-rendimiento-ranking-unificado` | Rendimiento y Ranking Unificado | `PerformanceView` | 3 · Progreso |
| `05-detalle-logro-sentadilla-trasera` | Detalle de Logro: Sentadilla Trasera | `PrDetailView` | 3 · Progreso |
| `06-registrar-nueva-marca` | Registrar Nueva Marca (modal) | `LogPrSheet` | 3 · Progreso |
| `07-biblioteca-tecnica-ejercicios` | Biblioteca Técnica de Ejercicios | `ExerciseLibraryView` | 3 · Progreso |
| `08-comunidad-y-retos` | Comunidad y Retos NDC HQ | `CommunityView` (seg. Retos) | 4 · Comunidad |
| `09-ranking-comunidad` | Ranking de la Comunidad | `CommunityView` (seg. Ranking) | 4 · Comunidad |
| `10-perfil-atleta-lesiones` | Perfil de Atleta (con lesiones) | `AthleteProfileView` | 5 · Perfil |
| `11-registrar-nueva-lesion` | Registrar Nueva Lesión (modal) | `LogInjurySheet` | 5 · Perfil |

## Notas de diseño observadas (para mantener consistencia)

- **Marca**: header "NDC HQ" + campana de notificaciones arriba en cada tab raíz.
- **Color primario** Celeste Oscuro en cards destacadas (WOD del día, Estado de
  Rendimiento, header de perfil) con texto blanco.
- **Amarillo de acento** (`NDCColor.accent`) en CTAs clave: "Ver WOD", "Guardar
  Marca", "Unirse al Reto", FAB de "+". El primario oscuro en CTAs serios
  ("Registrar mi Resultado", "Confirmar Resultado", "Guardar Registro").
- **Tarjetas** sobre fondo `surface` gris claro, esquinas redondeadas grandes.
- **Stats grandes** (PR 145kg, tiempo 12:45) con tipografía heavy → `NDCFont.statsXL`.
- **Selectores tipo segmented** para nivel de intensidad / RX vs Escalado.
- **Grid de zonas del cuerpo** con iconos en "Registrar Nueva Lesión".
- **Gráfico de evolución histórica** (línea) en detalle de logro y perfil.
- Los `.html` traen los valores Tailwind exactos (hex, padding) si se necesita
  afinar algún token de `NDCColors`/`NDCTypography`.
