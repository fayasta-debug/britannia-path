# Seguridad

- `config.js` solo contiene la URL y la **publishable key**.
- Nunca publiques `sb_secret_`, `service_role`, la contraseña de la base de datos o un token personal.
- Las respuestas de examen están en `exam_questions`, sin acceso para `anon` ni `authenticated`.
- La corrección se realiza en la Edge Function `cycle-exam`.
- La creación de usuarios se realiza en `admin-students`, donde la credencial secreta permanece en el servidor.
- Las políticas RLS separan los datos de cada estudiante.
- El rol `admin` se comprueba tanto en la interfaz como en la base de datos o función servidor.
