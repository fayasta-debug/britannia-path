# Paso a paso de Supabase — Britannia Path Admin V5

## Si ya instalaste Admin V4

No vuelvas a ejecutar todo desde cero. Sigue únicamente estos pasos:

1. En Supabase abre **SQL Editor → New query**.
2. Copia y ejecuta `supabase/03-private-responses-and-admin-review.sql`.
3. Abre **Edge Functions → admin-students**.
4. Reemplaza su código por `supabase/functions/admin-students/index.ts`.
5. Pulsa **Deploy**.
6. Mantén **Verify JWT desactivado**.
7. Sube a GitHub los archivos nuevos del proyecto y espera el check verde de Actions.
8. Recarga la página con `Command + Shift + R`.

La guía detallada está en `ACTUALIZACION-V5-PASO-A-PASO.md`.

## Si instalas todo desde cero

1. Ejecuta `supabase/01-database-and-exams.sql` en SQL Editor.
2. Convierte tu cuenta en administrador con `supabase/02-make-first-admin.sql`.
3. Despliega las funciones `admin-students` y `cycle-exam`.
4. Configura `config.js` con Project URL y Publishable Key.
5. Publica la carpeta en GitHub Pages.
