# Seguridad — Britannia Path Admin V5

- Cada fila de práctica incluye `student_id` y una clave de respuesta.
- Las políticas RLS permiten al estudiante leer y modificar únicamente sus propias respuestas.
- El administrador puede leerlas para fines académicos.
- La `publishableKey` puede estar en `config.js`.
- Nunca publiques claves `secret`, `service_role`, contraseñas de base de datos ni tokens personales.
- La Edge Function valida la sesión y comprueba que el perfil tenga `role = admin` antes de mostrar respuestas o modificar cuentas.
- La clave de servicio se utiliza únicamente dentro de la Edge Function.
