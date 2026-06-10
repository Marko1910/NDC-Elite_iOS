# NDC Elite — Mapa de Navegación (SwiftUI)

Derivado de los diseños de Stitch "NDC Performance Hub" (25 pantallas originales + 9 generadas).
Complementa a `SCHEMA.md`. Cada pantalla indica su tabla(s) principal(es) de Supabase.

## Arquitectura de navegación

```
App
├── Sin sesión → LoginView
└── Con sesión (según profiles.role)
    ├── atleta  → TabView Atleta  (Inicio · WOD · Progreso · Comunidad · Perfil)
    └── coach   → TabView Coach   (Inicio · WODs · Atletas · Alertas · Progreso)
```

## 🔑 Autenticación
| Vista | Origen diseño | Datos | Navega a |
|---|---|---|---|
| `LoginView` | ✨ generada | Supabase Auth (email+password) | TabView según rol |
| — Registro | no hay registro abierto: **comunidad cerrada**, el alta es por invitación del coach | `auth.admin`/magic link | — |

## 👤 TAB ATLETA

### Tab 1 · Inicio
| Vista | Diseño | Tablas | Botones → destino |
|---|---|---|---|
| `AthleteDashboardView` | NDC HQ - Dashboard | wods, attendance, personal_records, athlete_goals, coach_tips | Ver WOD → `WodDetailView` · 🔔 → `AthleteNotificationsView` ✨ · Tip ▶ → `ExerciseDetailView` |

### Tab 2 · WOD
| Vista | Diseño | Tablas | Botones |
|---|---|---|---|
| `WodDetailView` | WOD del Día / WOD Detallado | wods, wod_blocks, wod_block_exercises | Ver técnica → `ExerciseDetailView` · Registrar mi Resultado → `LogWodResultSheet` |
| `LogWodResultSheet` | Registro de Resultados | wod_results (insert, status=pendiente) | Confirmar → dismiss |

### Tab 3 · Progreso (PR Lab)
| Vista | Diseño | Tablas | Botones |
|---|---|---|---|
| `PerformanceView` | Rendimiento y Ranking Unificado | personal_records, profiles.points | chevron → `PrDetailView` · Ver todo → `PrHistoryList` |
| `PrDetailView` | Detalle de Logro | personal_records (+ historial 6 meses) | Compartir → ShareLink nativo |
| `LogPrSheet` | Registrar Nueva Marca | personal_records (insert), exercises (picker) | Guardar → dismiss |
| `ExerciseLibraryView` | Biblioteca Técnica | exercises, exercise_technique_steps | Registrar PR Actual → `LogPrSheet` |

### Tab 4 · Comunidad
| Vista | Diseño | Tablas | Botones |
|---|---|---|---|
| `CommunityView` (segmentos Retos/Ranking) | Comunidad y Retos / Ranking de la Comunidad | challenges, challenge_participants, achievements, athlete_achievements, profiles.points, ranking_snapshots | Unirse al Reto / Continuar → `ChallengeDetailView` ✨ |
| `ChallengeDetailView` ✨ | generada | challenges, challenge_participants | Registrar mi Progreso (update progress_value) · Abandonar Reto (delete) |

### Tab 5 · Perfil
| Vista | Diseño | Tablas | Botones |
|---|---|---|---|
| `AthleteProfileView` | Perfil de Atleta - Con Registro de Lesiones | profiles, attendance (resumen), personal_records, injuries, coach_notes (visibility=compartida), athlete_goals | + Registrar Nueva Lesión → `LogInjurySheet` · ⚙️ → `SettingsView` ✨ |
| `LogInjurySheet` | Registrar Nueva Lesión | injuries (insert) | Guardar → dismiss |
| `SettingsView` ✨ | generada | profiles (update), Auth signOut | Mi Pase QR → `QrPassView` ✨ · Cerrar Sesión |
| `QrPassView` ✨ | generada | profiles.id → QR | Añadir a Apple Wallet (PassKit, fase 2) |
| `AthleteNotificationsView` ✨ | generada | notifications (user_id propio) | Marcar leídas (update is_read) |

## 🧑‍🏫 TAB COACH

### Tab 1 · Inicio
| Vista | Diseño | Tablas | Botones |
|---|---|---|---|
| `CoachDashboardView` | Dashboard del Coach | attendance (hoy), wod_results+personal_records (pendientes), wods (próximo) | Revisar → `ValidationView` · Ver detalles → `WodDetailView` · 💬 → **WhatsApp deep link** |

### Tab 2 · WODs
| Vista | Diseño | Tablas | Botones |
|---|---|---|---|
| `WodManagementView` | Gestión de WODs (+ menú opciones) | wods por semana | Crear WOD → `WodEditorView` · Programar Running → `RunningEditorSheet` · edit/delete |
| `WodEditorView` | Editor de WOD | wods, wod_blocks, wod_block_exercises | Añadir Ejercicio → `ExercisePickerSheet` ✨ · Publicar (status=publicado) · Guardar Borrador |
| `ExercisePickerSheet` ✨ | generada | exercises (búsqueda + filtro por categoría) | + añade a bloque · Añadir seleccionados → dismiss |
| `RunningEditorSheet` | Nuevo Registro de Running | wods (wod_type=running, distance_km, pace_target, route_url) | Publicar Sesión |

### Tab 3 · Atletas
| Vista | Diseño | Tablas | Botones |
|---|---|---|---|
| `AthleteManagementView` | Gestión de Atletas | profiles (filtros nivel/lesión), injuries | Tomar Asistencia → `AttendanceView` · Ver Perfil → `CoachAthleteProfileView` · + → `InviteAthleteSheet` ✨ |
| `InviteAthleteSheet` ✨ | generada | invitación (Auth invite por email) + profiles.phone | Enviar Invitación |
| `CoachAthleteProfileView` | Perfil de Atleta - Vista Coach / Edición | profiles, wod_results, personal_records, injuries, coach_notes | edit resultado → `CorrectResultSheet` ✨ · nota → `AddNoteSheet` |
| `AddNoteSheet` | Añadir Nota del Coach | coach_notes (insert) | Guardar Nota |
| `AttendanceView` | Control de Asistencia | class_sessions, attendance | 📷 QR → `QrScannerView` ✨ · toggle presente/ausente |
| `QrScannerView` ✨ | generada | attendance (insert check_in_method='qr') | Registrar manualmente → vuelve a lista |

### Tab 4 · Alertas
| Vista | Diseño | Tablas | Botones |
|---|---|---|---|
| `CoachAlertsView` | Alertas y Notificaciones - Coach | notifications (user_id=coach) | Validar → `ValidationView` · Contactar Atleta → **WhatsApp deep link** |
| `ValidationView` | Validación de Marcas | wod_results + personal_records (status=pendiente) | Validar (status=validado) · Corregir → `CorrectResultSheet` ✨ · Validar Todo |
| `CorrectResultSheet` ✨ | generada | wod_results/personal_records (update + status=corregido) | Guardar Corrección |

### Tab 5 · Progreso
| Vista | Diseño | Tablas | Botones |
|---|---|---|---|
| `CommunityProgressView` | Rendimiento de Atletas - Coach | wod_results, personal_records, attendance (agregados) | Ver todo → listas completas |

## 📲 Comportamientos especiales (sin pantalla)

### Botón "Contactar Atleta" → WhatsApp
No abre chat interno. Abre WhatsApp con mensaje pre-armado de inasistencia:
```swift
let phone = athlete.phone          // profiles.phone, formato +51987654321
let days = athlete.absentDays      // calculado de attendance
let msg = "Hola \(athlete.firstName) 👋 Te extrañamos en NDC HQ. " +
          "Llevas \(days) días sin entrenar. ¿Todo bien? ¡Tu próxima clase te espera! 💪"
let url = URL(string: "https://wa.me/\(phone.filter(\.isNumber))?text=" +
          msg.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
UIApplication.shared.open(url)     // fallback: sms: si no tiene WhatsApp
```

### Compartir Logro → `ShareLink` nativo (sin pantalla)
### Validar / Validar Todo → updates inline con confirmación (sin pantalla)

## ✨ Pantallas generadas en Stitch (10-jun-2026) — confirmadas

| Pantalla | Screen ID (proyecto 13676274385961218082) |
|---|---|
| Inicio de Sesión - NDC HQ | `3eaa9583c01445bb8af4033cad7e70c5` |
| Seleccionar Ejercicio - Biblioteca | `08b6e38be36740b79e363c52e0a4c121` |
| Corregir Marca - Modal Coach | `ec06304e3a9645fdaad8f27bdd4e36a7` |
| Detalle de Reto: Running Sunday | `b293736844244f7dac7c3f45bb4fe89a` |
| Check-in con QR - Coach | `919e0b7afb374828baad3ad328ab404e` |
| Mi Pase NDC - Atleta | `0189ede91e424e58ad690a09d3a10745` |
| Notificaciones - Atleta | `4b66778f6e1e4981a63d6a4b82bc709c` |
| Invitar Atleta - Modal Coach | `67ca939101da4e0fbe5b8298fa5a56ff` |
| Ajustes - Perfil de Atleta | `929f67fa1e0d4e1190c48eeaa1d33635` |
