# Seguridad

## Claves permitidas en el repositorio

Solo puede incluirse la clave pública de Supabase (`publishable` o `anon`).

Nunca publiques:

- `service_role`
- `secret key`
- contraseñas de base de datos
- tokens personales de GitHub

## Datos de progreso

La tabla `user_progress` usa Row Level Security. Las políticas exigen que el usuario autenticado sea propietario de la fila.

## Reportar un problema

No incluyas correos, tokens, contraseñas ni datos personales al abrir un issue público.
