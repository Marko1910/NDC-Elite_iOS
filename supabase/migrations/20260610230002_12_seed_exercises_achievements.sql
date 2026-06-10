-- ===== Datos semilla: biblioteca de ejercicios + catálogo de logros =====
-- Migración de datos idempotente (on conflict do nothing): segura de
-- re-ejecutar y de promover de staging a producción.

-- ---------- Ejercicios ----------
insert into public.exercises (name, name_es, category, difficulty, description, default_score_type) values
  -- Fuerza
  ('Back Squat',        'Sentadilla trasera',       'fuerza',    'basico',     'Sentadilla con barra apoyada sobre los trapecios.', 'peso'),
  ('Front Squat',       'Sentadilla frontal',       'fuerza',    'intermedio', 'Sentadilla con barra en rack frontal.', 'peso'),
  ('Deadlift',          'Peso muerto',              'fuerza',    'basico',     'Levantamiento de barra desde el suelo hasta la cadera.', 'peso'),
  ('Shoulder Press',    'Press de hombros',         'fuerza',    'basico',     'Press estricto de barra sobre la cabeza.', 'peso'),
  ('Push Press',        'Push press',               'fuerza',    'intermedio', 'Press con impulso de piernas.', 'peso'),
  ('Bench Press',       'Press de banca',           'fuerza',    'basico',     'Press de barra acostado en banca.', 'peso'),
  -- Olímpico
  ('Snatch',            'Arrancada',                'olimpico',  'avanzado',   'Levantamiento olímpico: barra del suelo a overhead en un movimiento.', 'peso'),
  ('Clean & Jerk',      'Cargada y envión',         'olimpico',  'avanzado',   'Levantamiento olímpico en dos tiempos.', 'peso'),
  ('Clean',             'Cargada',                  'olimpico',  'intermedio', 'Barra del suelo a los hombros.', 'peso'),
  ('Power Clean',       'Cargada de potencia',      'olimpico',  'intermedio', 'Cargada recibida sobre paralelo.', 'peso'),
  ('Power Snatch',      'Arrancada de potencia',    'olimpico',  'avanzado',   'Arrancada recibida sobre paralelo.', 'peso'),
  -- Gimnasia
  ('Pull-up',           'Dominada',                 'gimnasia',  'basico',     'Dominada estricta en barra.', 'reps'),
  ('Chest to Bar Pull-up', 'Dominada al pecho',     'gimnasia',  'intermedio', 'Dominada con contacto del pecho a la barra.', 'reps'),
  ('Ring Muscle Up',    'Muscle up en anillas',     'gimnasia',  'avanzado',   'Transición de dominada a fondo en anillas.', 'reps'),
  ('Bar Muscle Up',     'Muscle up en barra',       'gimnasia',  'avanzado',   'Transición de dominada a fondo sobre la barra.', 'reps'),
  ('Handstand Push-up', 'Flexión de pino',          'gimnasia',  'avanzado',   'Flexión invertida contra la pared.', 'reps'),
  ('Handstand Walk',    'Caminata de manos',        'gimnasia',  'avanzado',   'Desplazamiento en posición de pino.', 'distancia'),
  ('Toes to Bar',       'Pies a la barra',          'gimnasia',  'intermedio', 'Llevar los pies a tocar la barra colgado.', 'reps'),
  ('Air Squat',         'Sentadilla al aire',       'gimnasia',  'basico',     'Sentadilla con peso corporal.', 'reps'),
  ('Push-up',           'Flexión de brazos',        'gimnasia',  'basico',     'Flexión de pecho en el suelo.', 'reps'),
  ('Burpee',            'Burpee',                   'gimnasia',  'basico',     'Flexión + salto con palmada sobre la cabeza.', 'reps'),
  ('Box Jump',          'Salto al cajón',           'gimnasia',  'basico',     'Salto a dos pies sobre el cajón.', 'reps'),
  ('Wall Ball',         'Lanzamiento de balón',     'gimnasia',  'basico',     'Sentadilla + lanzamiento de balón medicinal al objetivo.', 'reps'),
  ('Double Under',      'Salto doble de comba',     'gimnasia',  'intermedio', 'Dos pasadas de cuerda por salto.', 'reps'),
  -- Endurance
  ('Run',               'Carrera',                  'endurance', 'basico',     'Carrera a pie.', 'distancia'),
  ('Row',               'Remo',                     'endurance', 'basico',     'Remo en máquina (ergómetro).', 'distancia'),
  ('Bike Erg',          'Bicicleta',                'endurance', 'basico',     'Bicicleta estática de aire o ergómetro.', 'calorias'),
  ('Ski Erg',           'Esquí',                    'endurance', 'intermedio', 'Máquina de esquí.', 'calorias'),
  -- Movilidad
  ('Scapular Pull-up',  'Dominada escapular',       'movilidad', 'basico',     'Activación escapular colgado de la barra.', 'reps'),
  ('Hip Mobility Flow', 'Movilidad de cadera',      'movilidad', 'basico',     'Secuencia de movilidad articular de cadera.', 'tiempo')
on conflict (name) do nothing;

-- ---------- Pasos de técnica: Back Squat (como en el diseño de Stitch) ----------
insert into public.exercise_technique_steps (exercise_id, step_number, title, description)
select e.id, s.step_number, s.title, s.description
from public.exercises e
join (values
  (1, 'Setup',       'Pies a la anchura de los hombros, barra apoyada firmemente sobre los trapecios.'),
  (2, 'Descenso',    'Iniciamos rompiendo la cadera, manteniendo el pecho erguido y las rodillas alineadas con los pies.'),
  (3, 'Profundidad', 'El pliegue de la cadera debe bajar más que el tope de la rodilla.')
) as s(step_number, title, description) on true
where e.name = 'Back Squat'
on conflict (exercise_id, step_number) do nothing;

-- ---------- Catálogo de logros (badges del diseño "Mis Logros") ----------
insert into public.achievements (code, title, description, icon) values
  ('early_bird',  'Early Bird',  'Asiste a 10 clases de la primera hora de la mañana.',        'wb_sunny'),
  ('pr_crusher',  'PR Crusher',  'Consigue 5 récords personales validados.',                   'bolt'),
  ('consistent',  'Consistent',  'Cumple tu meta de asistencia mensual 3 meses seguidos.',     'calendar_month'),
  ('iron_lungs',  'Iron Lungs',  'Completa 10 WODs de tipo endurance o running.',              'rowing'),
  ('wall_baller', 'Wall Baller', 'Acumula 1,000 wall balls en WODs registrados.',              'sports_handball'),
  ('elite_pro',   'Elite Pro',   'Alcanza el nivel Avanzado con 85% de adherencia RX.',        'workspace_premium')
on conflict (code) do nothing;
