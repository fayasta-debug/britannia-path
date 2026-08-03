# Britannia Path Admin V4

Sitio completo para GitHub Pages + Supabase con dos roles:

- **student**: se asigna automáticamente a toda cuenta registrada.
- **admin**: puede crear estudiantes, ver su progreso y desbloquear ciclos.

La ruta contiene 37 ciclos y el banco servidor contiene 444 preguntas finales (12 por ciclo).

## Regla de progresión

1. El estudiante solo abre ciclos desbloqueados.
2. Debe completar al menos **21 de 24 lecciones** del ciclo (85%).
3. Rinde el examen final de 12 preguntas.
4. Aprueba con **70%**.
5. Supabase marca el ciclo como `completed` y desbloquea automáticamente el siguiente.
6. Si no aprueba, el ciclo queda `needs_review` y el siguiente continúa bloqueado.
7. El administrador puede desbloquear manualmente un ciclo.

## Instalación muy simple

Lee primero **PASO-A-PASO-SUPABASE.md**. No necesitas instalar programas ni usar terminal.

## Archivos principales

- `index.html`: plataforma completa.
- `config.js`: Project URL y publishable key públicas.
- `supabase/01-database-and-exams.sql`: tablas, roles, seguridad y preguntas.
- `supabase/02-make-first-admin.sql`: convierte tu cuenta en administradora.
- `supabase/functions/admin-students/index.ts`: crea estudiantes y restablece contraseñas.
- `supabase/functions/cycle-exam/index.ts`: entrega, corrige y registra exámenes.

## Seguridad

Nunca subas a GitHub una clave `sb_secret_`, `service_role`, contraseña de base de datos ni token personal. Las Edge Functions utilizan las credenciales secretas internas que Supabase proporciona en el servidor.
