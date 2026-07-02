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

5 tabs: **Inicio · WODs · Atletas · Progreso · Perfil**

| Tab | Vista raíz | Navega a |
|---|---|---|
| Inicio | `CoachDashboardView` | "Validaciones Pendientes" → `ValidationView` (push) · campanita (toolbar) → `CoachAlertsView` (push) · alertas de ausencia → WhatsApp (`WhatsAppHelper`) · próximo WOD → WodDetail (pend.) |
| WODs | `WodManagementView` | FAB menú → "Nuevo WOD" `WodEditorView` (push) / "Nueva Sesión de Running" `RunningEditorView` (sheet) · toolbar → `ExerciseLibraryManagementView` (push) · editar/eliminar (pend.) |
| Atletas | `AthleteManagementView` | "Tomar Asistencia" → `AttendanceControlView` (sheet) · "Ver Perfil" → `CoachAthleteProfileView` (push, PRs reales por ejercicio) · 📅 → `ClassScheduleView` (push) · invitar → `GenerateInviteCodeView` (sheet) |
| Progreso | `CommunityProgressView` | 🏆 toolbar y "Ver todo" de PRs Recientes → `CoachPrsView` (push) |
| Perfil | `CoachProfileView` | Cerrar Sesión → `SessionStore.signOut()` |

`CoachAlertsView` ya no es tab: se accede desde la campanita del Dashboard. Validar → `ValidationView` · Contactar → WhatsApp · Responder (pend.)

Sub-vistas coach:
- `ValidationView` → Validar / Corregir → `CorrectResultSheet` (interno) / Validar Todo — todo real
- `CoachAthleteProfileView` → PRs reales (última marca por ejercicio) · "Añadir Nota" → `AddNoteView` (sheet)
- `ClassScheduleView` — horario de clases: crea/elimina `class_sessions` (hoy + 13 días, hora/título/capacidad)
- `AttendanceControlView` → elige entre las clases programadas de hoy (o crea la de la hora actual) · FAB QR → `GenerateQRView(presetSession:)` (misma sesión)
- `GenerateQRView` — genera el QR (CoreImage) que el atleta escanea con `AttendanceScannerView`
- `CoachPrsView` — todas las marcas del box (búsqueda atleta/ejercicio + filtro por estado)
- `WodEditorView` → "Añadir Ejercicio" → `ExercisePickerSheet` (interno, real)
- `ExerciseEditorView` — incluye "Se mide en" (`default_score_type`): define la unidad de los PRs de ese ejercicio

---

## Conexión a datos (Supabase)

Patrón: cada pantalla tiene un `@Observable` store que expone
`LoadState<Data>`; la vista usa `LoadStateView` (skeleton → datos → error+retry).
Ejemplo cableado: `AthleteDashboardStore` + `AthleteRepository`.

Inserts ya cableados (jul-2026):
- ✅ `LogWodResultView` → `wod_results` (upsert por wod+atleta, status pendiente; carga el WOD del día real + selector RX/Escalado)
- ✅ `LogPrSheet` → `personal_records` (picker de `exercises` real, `previous_value` automático, unidad según `default_score_type`)
- ✅ `LogInjuryView` → `injuries` (reported_by = atleta)
- ✅ `AddNoteView` → `coach_notes` (coach_id = sesión; recibe `Profile` real)
- ✅ `RunningEditorView` → `wods` (wod_type=running, distance_km, hora de salida en `focus`)
- ✅ Ciclo QR completo: `GenerateQRView` crea/reusa la `class_sessions` de hoy (payload `ndc-attendance://session/<id>`) y `AttendanceScannerView` valida el prefijo e inserta en `attendance` (check_in_method='qr'; duplicado = "ya registrada")
- ✅ `AthleteManagementView` → lista real de `profiles` + lesiones activas (filtro "Con Lesión"); pasa `Profile` a `CoachAthleteProfileView`

- ✅ `ValidationView` → cola real (`wod_results` + `personal_records` pendientes,
  con nombres/WODs/ejercicios reales). Validar y Validar Todo actualizan
  **solo los ids listados** con guarda `status=pendiente` (no pisa carreras).
  Corregir → `CorrectResultSheet` (vive dentro de ValidationView.swift, como
  ExercisePickerSheet en WodEditorView): edita la métrica registrada →
  status=corregido + validated_by/at.
- ✅ `AttendanceControlView` → roster real + toggle persistido en `attendance`
  (upsert por sesión+atleta, check_in_method='manual', optimista con revert).
  Opera sobre la clase de HOY a la hora elegida y **comparte la misma
  `class_sessions` con el QR** (`GenerateQRView(presetSession:)`), para que
  check-in manual y escaneado sumen juntos. Al marcar ausente se anula
  `checked_in_at` explícitamente.

Pendiente:
- `InviteAthleteView` → obsoleta (la reemplazó `GenerateInviteCodeView`, ya funcional); candidata a borrarse

Lectura por pantalla: ver tablas en `SCHEMA.md` y `FLOWS.md`.

---

## Lecturas cableadas (jul-2026)
- ✅ `AthleteDashboardView` — datos reales (wods/attendance/PRs/goals/tips/notifs);
  "Ver WOD" cambia al tab WOD (`AthleteTabView` con selección programática).
- ✅ `WodDetailView` — WOD publicado real + bloques + ejercicios; el 👁 abre la
  técnica del ejercicio en la Biblioteca; búsqueda → `ExerciseLibraryView`.
- ✅ `PerformanceView` — hero/último logro/marcas clave desde `personal_records`.
- ✅ `CoachDashboardView` — asistencia hoy (+capacidad de `class_sessions`),
  contador real de pendientes, próximo WOD real, alertas de ausencia calculadas
  (últimos 30 días, umbral 4 días, top 3, WhatsApp real con `profiles.phone`).

## Terminología del grupo
Niveles **Principiante / Intermedio / Avanzado** (sin RX/Escalado en la UI).
`AthleteLevel.basico.displayName == "Principiante"` (raw value intacto en BD).
El resultado del WOD guarda el nivel en `wod_results.intensity`; `rx_level`
queda en su default de BD. El RPE viaja al inicio de `athlete_notes`.

## Pendientes
- Atleta: Detalle de Reto (Running Sunday), Notificaciones, Ajustes;
  Community y WodHistory aún con datos de muestra.
- Coach: CoachAlertsView (sample), CoachAthleteProfile (WOD de hoy/historial sample).
- Dark Mode del design system (NDCColor usa hex fijos).
