# Britannia Path — GitHub Pages + cuentas en la nube

Plataforma-libro interactiva en español para estudiar **British English desde Pre-A1 hasta C2**, con Idioms, Phrasal Verbs y una especialización completa de Legal English.

## Qué contiene este repositorio

- `index.html`: plataforma completa.
- `404.html`: respaldo para GitHub Pages.
- `config.js`: configuración pública de Supabase.
- `supabase-schema.sql`: tabla y políticas de seguridad para el progreso.
- `.github/workflows/pages.yml`: publicación automática en GitHub Pages.
- `.nojekyll`: evita que GitHub procese el sitio con Jekyll.

La plataforma funciona de inmediato en **modo local**. Sin Supabase, cada navegador conserva su propio progreso. Al configurar Supabase, se habilitan registro, inicio de sesión y sincronización entre dispositivos.

## 1. Publicar la web en GitHub Pages

1. Crea un repositorio nuevo en GitHub, por ejemplo `britannia-path`.
2. Sube **todos** los archivos y carpetas de este proyecto a la raíz del repositorio.
3. Usa la rama `main`.
4. Abre `Settings` → `Pages`.
5. En `Build and deployment`, selecciona **GitHub Actions**.
6. Abre la pestaña `Actions` y espera a que termine `Deploy Britannia Path to GitHub Pages`.
7. El enlace público tendrá una forma similar a:

   `https://TU-USUARIO.github.io/britannia-path/`

Cada cambio enviado a `main` volverá a publicar la web automáticamente.

## 2. Crear el backend de cuentas en Supabase

### 2.1 Crear proyecto

1. Crea un proyecto en Supabase.
2. En `SQL Editor`, crea una consulta nueva.
3. Copia y ejecuta todo el archivo `supabase-schema.sql`.

### 2.2 Configurar las URL de autenticación

En Supabase, abre `Authentication` → `URL Configuration`:

- `Site URL`: tu URL final de GitHub Pages.
- `Redirect URLs`: agrega la misma URL y, para pruebas locales, `http://localhost:8000/**`.

Ejemplo:

`https://TU-USUARIO.github.io/britannia-path/`

### 2.3 Copiar las credenciales públicas

En Supabase, abre la configuración/API del proyecto y copia:

- Project URL.
- Publishable key o anon public key.

Edita `config.js`:

```js
window.BRITANNIA_CONFIG = {
  supabase: {
    url: "https://TU-PROYECTO.supabase.co",
    publishableKey: "TU_CLAVE_PUBLICA"
  }
};
```

No coloques una `secret key` ni una clave `service_role` en GitHub. Solo debe utilizarse la clave pública. La seguridad del progreso depende de las políticas RLS incluidas en `supabase-schema.sql`.

## 3. Probar antes de publicar

Desde la carpeta del proyecto:

```bash
python3 -m http.server 8000
```

Abre:

`http://localhost:8000`

No pruebes abriendo `index.html` directamente con `file://`, porque la autenticación y algunas APIs del navegador requieren un origen HTTP/HTTPS.

## 4. Funcionamiento del progreso

- Sin cuenta: se guarda en el navegador.
- Al crear cuenta: se conserva la copia local y se sincroniza con la cuenta.
- Al iniciar sesión en otro dispositivo: se descarga el progreso de esa cuenta.
- Si no hay conexión: se continúa guardando localmente y se intenta sincronizar al volver Internet.
- Cuando se combinan dos dispositivos, se conservan lecciones completadas y las puntuaciones más altas; las notas locales no vacías tienen prioridad.

## 5. Correo de confirmación

Supabase puede exigir que el estudiante confirme su correo. Para pruebas rápidas puedes revisar esa opción en la configuración de Auth. Para un sitio público, se recomienda mantener la confirmación de correo activada.

## 6. Dominio propio (opcional)

GitHub Pages permite utilizar el dominio `github.io` o un dominio propio. Configúralo desde `Settings` → `Pages` y luego actualiza `Site URL` y `Redirect URLs` en Supabase.

## Seguridad

- Las contraseñas son gestionadas por Supabase Auth; la plataforma no las almacena dentro del JSON de progreso.
- La tabla tiene Row Level Security.
- Cada operación se limita a `auth.uid() = user_id`.
- La clave pública se puede incluir en una web estática; las claves secretas no.
- No desactives las políticas RLS para “solucionar” errores de acceso.

## Limitaciones

GitHub Pages sirve únicamente archivos estáticos. No puede ejecutar `app.py`, Flask ni SQLite. Por eso las cuentas utilizan Supabase. Si no deseas un servicio externo, la web puede publicarse igualmente, pero el progreso quedará limitado al navegador de cada persona.
