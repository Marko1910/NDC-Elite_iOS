# NDC Elite — Mapa de Navegación y Lógica entre Pantallas

Estado de la app construida en SwiftUI. Documenta las **barras de navegación**,
los **flujos entre pantallas** y los **puntos de conexión a datos** (marcados con
`TODO` en el código). Útil para continuar el trabajo (incluido sin Mac).

> Diseños de origen en `diseño/atleta/` y `diseño/coach/` (PNG + HTML de Stitch).
> Capa de datos: `Core/Supabase/AthleteRepository.swift` + stores por pantalla.
> Estados de carga: `DesignSystem/Skeleton.swift` (LoadState + shimmer).

---

## Raíz

`NDC_EliteApp` → `ContentView` (router por `SessionStore.state`):
- `.loading` → splash
- `.loggedOut` → `LoginView`
- `.loggedIn(profile)` → según `profile.role`:
  - `.atleta` → `AthleteTabView`
  - `.coach` / `.admin` → `CoachTabView`

---

## TAB BAR — ATLETA (`AthleteTabView`)

5 tabs: **Inicio · WOD · Progreso · Comunidad · Perfil**

| Tab | Vista raíz | Navega a |
|---|---|---|
| Inicio | `AthleteDashboardView` ✅cableado Supabase | WOD del día → `WodDetailView` · 🔔 → Notificaciones (pend.) |
| WOD | `WodDetailView` | "Ver técnica" 👁 → `ExerciseDetailView` · "Registrar mi Resultado" → `LogWodResultView` (push, mantiene navbar) · icono ⏱ historial → `WodHistoryView` |
| Progreso | `PerformanceView` | icono 📚 biblioteca → `ExerciseLibraryView` · "Último Logro"/"Marcas" → `PrDetailView` · FAB + → `LogPrSheet` (sheet) |
| Comunidad | `CommunityView` (segmentos Retos/Ranking; ranking animado) | "Unirse/Continuar" reto → `ChallengeDetailView` (PENDIENTE: Detalle de Reto Running Sunday) |
| Perfil | `AthleteProfileView` | icono QR (reemplaza campana) → `AttendanceScannerView` (fullScreenCover, cámara) · "Registrar Nueva Lesión" → `LogInjuryView` (push) |

Sub-vistas atleta:
- `ExerciseLibraryView` → `ExerciseDetailView` (video YouTube in-app + técnica + "Registrar PR" → `LogPrSheet`)
- `PrDetailView` → ShareLink con tarjeta deportiva renderizada (`ImageRenderer`)
- `AttendanceScannerView` — escanea el QR que genera el coach (cierra el ciclo)

Componentes compartidos: `NDCBrandBar` (`.ndcBrandToolbar`), `NDCAvatarView`,
`NDCBellButton`, `YouTubePlayerView`, `QRCameraView`.

---

## TAB BAR — COACH (`CoachTabView`)

5 tabs: **Inicio · WODs · Atletas · Alertas · Progreso**

| Tab | Vista raíz | Navega a |
|---|---|---|
| Inicio | `CoachDashboardView` | "Validaciones Pendientes" → `ValidationView` (push) · alertas de ausencia → WhatsApp (`WhatsAppHelper`) · próximo WOD → WodDetail (pend.) |
| WODs | `WodManagementView` | FAB menú → "Nuevo WOD" `WodEditorView` (push) / "Nueva Sesión de Running" `RunningEditorView` (sheet) · editar/eliminar (pend.) |
| Atletas | `AthleteManagementView` | "Tomar Asistencia" → `AttendanceControlView` (sheet) · "Ver Perfil" → `CoachAthleteProfileView` (push) · barra "Invitar" → `InviteAthleteView` (sheet) |
| Alertas | `CoachAlertsView` | Validar → `ValidationView` (entrada principal vía Dashboard) · Contactar → WhatsApp · Responder (pend.) |
| Progreso | `CommunityProgressView` | "Ver todo" listas (pend.) |

Sub-vistas coach:
- `ValidationView` → Validar (status validado) / Corregir → `CorrectResultSheet` (pend.) / Validar Todo
- `CoachAthleteProfileView` → "Añadir Nota" → `AddNoteView` (sheet)
- `AttendanceControlView` → FAB QR → `GenerateQRView` (sheet)
- `GenerateQRView` — genera el QR (CoreImage) que el atleta escanea con `AttendanceScannerView`
- `WodEditorView` → "Añadir Ejercicio" → `ExercisePickerSheet` (pend.)

---

## Conexión a datos (Supabase)

Patrón: cada pantalla tiene un `@Observable` store que expone
`LoadState<Data>`; la vista usa `LoadStateView` (skeleton → datos → error+retry).
Ejemplo cableado: `AthleteDashboardStore` + `AthleteRepository`.

Inserts pendientes (marcados `TODO(datos)` en cada vista):
- `LogWodResultView` → `wod_results` (status pendiente)
- `LogPrSheet` → `personal_records` (status pendiente)
- `LogInjuryView` → `injuries`
- `AttendanceScannerView` (atleta) / `AttendanceControlView` (coach) → `attendance`
- `GenerateQRView` payload = id de `class_sessions` actual
- `ValidationView` → update status validado · `AddNoteView` → `coach_notes`
- `WodEditorView`/`RunningEditorView` → `wods`+`wod_blocks`+`wod_block_exercises`
- `InviteAthleteView` → Auth invite + `profiles`

Lectura por pantalla: ver tablas en `SCHEMA.md` y `FLOWS.md`.

---

## Pendientes
- Atleta: Detalle de Reto (Running Sunday), Notificaciones, Ajustes, Pase QR.
- Coach: CorrectResultSheet, ExercisePickerSheet, Gestión de WODs (menú alt.),
  "Ver todo" de Progreso.
- Cablear todas las pantallas a Supabase (sólo Dashboard atleta hecho).
- Dark Mode del design system (NDCColor usa hex fijos).
