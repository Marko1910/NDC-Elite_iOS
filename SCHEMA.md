# NDC Elite — Esquema de Base de Datos (Supabase)

Esquema derivado del diseño de Stitch **"NDC Performance Hub"** (25 pantallas analizadas).
Proyecto Supabase: `rdbibgwnmrifscisicgv`. Todas las tablas tienen **RLS activado**.

## Roles y acceso
- `public.is_coach()` → helper usado por las políticas RLS.
- **Atleta**: ve/edita lo suyo; ve contenido publicado y validado.
- **Coach/Admin**: gestiona todo (WODs, validaciones, lesiones, notas, clases, retos).

## Enums
| Enum | Valores |
|---|---|
| `user_role` | atleta, coach, admin |
| `athlete_level` | basico, intermedio, avanzado |
| `rx_level` | rx, escalado |
| `score_type` | peso, tiempo, reps, rondas, distancia, calorias |
| `result_status` | pendiente, validado, corregido |
| `exercise_category` | fuerza, gimnasia, endurance, movilidad, olimpico |
| `wod_type` | amrap, emom, for_time, tabata, fuerza, running, hiit |
| `wod_status` | borrador, publicado, archivado |
| `block_type` | calentamiento, fuerza, metcon, skill, accesorio |
| `body_zone` | cabeza, hombros, espalda, codos, munecas, lumbar, cadera, rodillas, tobillos |
| `injury_severity` | leve, moderada, severa |
| `injury_status` | activa, en_seguimiento, resuelta |
| `note_category` | general, performance, lesion, nutricion |
| `note_visibility` | solo_coach, compartida |
| `attendance_status` | presente, ausente, tarde |
| `challenge_type` | comunidad, individual |
| `notification_type` | validacion, lesion, asistencia, mensaje, logro, general |

## Tablas (20)

### Identidad
- **profiles** — 1:1 con `auth.users` (trigger `handle_new_user` lo crea al registrarse).
  `full_name, avatar_url, role, level, weight_kg, member_since, monthly_attendance_goal, streak_days, points, is_active`

### Biblioteca de ejercicios
- **exercises** — `name, name_es, category, difficulty, video_url, image_url, default_score_type`
- **exercise_technique_steps** — pasos numerados (Setup/Descenso/…) por ejercicio.

### Entrenamientos
- **wods** — `title, scheduled_date, wod_type, status, focus, time_cap_minutes` + running: `distance_km, pace_target, route_url, is_outdoor`
- **wod_blocks** — bloques (calentamiento/fuerza/metcon), `duration_minutes, rounds, score_type, time_cap_minutes, position`
- **wod_block_exercises** — `prescription` ("5 Sets de 3 Reps al 75% RM"), `rx_load` ("135/95 lbs"), `scaled_load`, `coach_cue`

### Resultados y marcas
- **wod_results** — único por (wod, atleta). `rx_level, time_seconds, reps, rounds, weight_used_kg, intensity, athlete_notes, status, validated_by, is_pr`
- **personal_records** — `exercise_id, value, score_type, rx_level, record_date, previous_value, status, validated_by`
  - Flujo: el atleta registra → estado `pendiente` → el coach `valida` o `corrige`.

### Salud
- **injuries** — `body_zone, severity, description, incident_date, status, reported_by`
- **coach_notes** — `category, content, visibility, note_date` (solo_coach por defecto)

### Clases y asistencia
- **class_sessions** — única por (fecha, hora). `capacity (50), coach_id, wod_id`
- **attendance** — única por (sesión, atleta). `status, checked_in_at, check_in_method (qr/manual), recorded_by`

### Comunidad
- **challenges** — `challenge_type, goal_value, unit, current_value, starts_on, ends_on`
- **challenge_participants** — único por (reto, atleta). `progress_value, joined_at, completed_at`
- **achievements** — catálogo de badges (`code, title, icon`)
- **athlete_achievements** — badges desbloqueados por atleta
- **athlete_goals** — `title, target_value, current_value, unit, is_primary`
- **ranking_snapshots** — `points, rank, snapshot_date` (para mostrar Δ posiciones)

### Otros
- **notifications** — `user_id (destinatario), type, title, body, related_athlete_id, metadata jsonb, is_read`
- **coach_tips** — `title, content, video_url, exercise_id`

## Convenciones para la app iOS
- Tiempos de WOD/PR tipo "3:45" se guardan en **segundos** (`time_seconds` / `value` con `score_type = 'tiempo'`).
- Pesos en **kg** (`numeric`).
- El ranking se calcula con `profiles.points`; los deltas (+3/−1) comparando contra `ranking_snapshots`.
- "RX 85% Compliance" y "% asistencia" se calculan en consultas (no se almacenan).

## Migraciones aplicadas (10/06/2026)
1. `01_base_enums_profiles` · 2. `02_exercises_library` · 3. `03_wods_blocks_exercises` · 4. `04_results_personal_records` · 5. `05_injuries_coach_notes` · 6. `06_classes_attendance` · 7. `07_challenges_achievements_goals` · 8. `08_notifications_tips_ranking` · 9. `09_security_hardening_functions`
