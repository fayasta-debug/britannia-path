# Britannia Path Admin V5

Plataforma de British English Pre-A1–C2 con Legal English, cuentas de estudiante, administrador, progreso, evaluaciones y revisión individual.

## Correcciones de V5

- Almacenamiento local privado por usuario.
- Eliminación de la mezcla de respuestas entre cuentas que usan el mismo navegador.
- Nueva tabla `activity_responses` con Row Level Security.
- Vista administrativa de respuestas de prácticas.
- Vista administrativa de producciones escritas.
- Vista pregunta por pregunta de cada examen final.
- Calificación y retroalimentación de entregas.
- Restablecimiento seguro del progreso contaminado sin eliminar la cuenta.

## Actualización desde V4

Lee primero:

`ACTUALIZACION-V5-PASO-A-PASO.md`

La actualización mínima requiere:

1. Reemplazar los archivos de GitHub.
2. Ejecutar `supabase/03-private-responses-and-admin-review.sql`.
3. Volver a desplegar `admin-students` con el nuevo `index.ts`.

## Instalación nueva

Para una instalación desde cero puedes ejecutar `supabase/01-database-and-exams.sql`, que ya incluye la tabla y las políticas de V5.
