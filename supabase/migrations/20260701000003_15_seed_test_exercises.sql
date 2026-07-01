-- Ejercicios de prueba para poder probar la Biblioteca Técnica y el selector
-- de ejercicios del editor de WOD sin tener que cargarlos a mano primero.
-- `created_by` queda null (no depende de que exista un coach todavía).
insert into public.exercises (name, name_es, category, difficulty, description, video_url, default_score_type)
values
  ('Back Squat', 'Sentadilla por detrás', 'fuerza', 'basico',
   'Ejercicio base de fuerza de tren inferior. Trabaja cuádriceps, glúteos y core con la barra apoyada sobre los trapecios.',
   'https://www.youtube.com/watch?v=nEsZViY3EJ4', 'peso'),
  ('Snatch', 'Arranque olímpico', 'olimpico', 'avanzado',
   'Levantamiento olímpico que lleva la barra del suelo a por encima de la cabeza en un solo movimiento. Exige potencia y movilidad.',
   'https://youtu.be/9xQp2sldyts', 'peso'),
  ('Muscle Up', 'Transición en anillas/barra', 'gimnasia', 'avanzado',
   'Combina una dominada explosiva con un fondo. Requiere fuerza de tirón y empuje y una transición técnica.',
   'https://www.youtube.com/watch?v=astSQRcAU2g', 'reps'),
  ('Peso Muerto', 'Deadlift', 'fuerza', 'intermedio',
   'Patrón de bisagra de cadera que desarrolla la cadena posterior. Clave para la fuerza total y la prevención de lesiones lumbares.',
   'https://youtu.be/op9kVnSso6Q', 'peso'),
  ('Double Unders', 'Dobles a la comba', 'endurance', 'intermedio',
   'La cuerda pasa dos veces por salto. Mejora la coordinación, la resistencia y la economía de movimiento en metcons.',
   'https://www.youtube.com/watch?v=82jNjDS19lg', 'reps')
on conflict (name) do nothing;

-- Pasos de técnica para Back Squat (a modo de ejemplo del formato esperado).
insert into public.exercise_technique_steps (exercise_id, step_number, title, description)
select e.id, s.step_number, s.title, s.description
from public.exercises e
join (
  values
    (1, 'Setup', 'Pies a la anchura de los hombros, barra apoyada firmemente sobre los trapecios.'),
    (2, 'Descenso', 'Inicia rompiendo la cadera, manteniendo el pecho erguido y las rodillas alineadas con los pies.'),
    (3, 'Profundidad', 'El pliegue de la cadera debe bajar más que el tope de la rodilla.')
) as s(step_number, title, description) on true
where e.name = 'Back Squat'
on conflict (exercise_id, step_number) do nothing;
