# PASO A PASO DE SUPABASE — PARA PRINCIPIANTES

Tu dirección pública es:

`https://fayasta-debug.github.io/britannia-path/`

No necesitas instalar programas. Todo se hace desde el navegador.

---

## PARTE 1 — Haz una copia de seguridad

1. Entra a tu repositorio `fayasta-debug/britannia-path`.
2. Pulsa **Code**.
3. Pulsa **Download ZIP**.
4. Guarda ese ZIP por si deseas volver a la versión anterior.

---

## PARTE 2 — Sube el proyecto nuevo a GitHub

1. Descomprime `britannia-path-admin-v4.zip`.
2. En GitHub abre tu repositorio `britannia-path`.
3. Pulsa **Add file → Upload files**.
4. Arrastra todo el contenido de la carpeta descomprimida.
5. Deben quedar en la raíz: `index.html`, `config.js`, `README.md`, `supabase` y `.github`.
6. Pulsa **Commit changes**.
7. En **Actions**, espera el check verde.

Tu `config.js` ya contiene tu Project URL y tu publishable key. No coloques ninguna secret key.

---

## PARTE 3 — Crea las tablas y los exámenes en Supabase

1. Entra a Supabase y abre tu proyecto **Britannia Path**.
2. En el menú izquierdo pulsa **SQL Editor**.
3. Pulsa **New query**.
4. En tu computadora abre el archivo:
   `supabase/01-database-and-exams.sql`
5. Selecciona todo el contenido y cópialo.
6. Pégalo dentro del SQL Editor.
7. Pulsa **Run**.
8. Espera hasta que aparezca un resultado parecido a:
   - `ciclos = 37`
   - `preguntas = 444`

Si ves “Success” o una tabla con esos números, terminó correctamente.

### Comprobación visual

1. Pulsa **Table Editor**.
2. Deben aparecer tablas como:
   - `profiles`
   - `lesson_progress`
   - `cycle_access`
   - `cycle_progress`
   - `exam_attempts`
   - `exam_questions`

---

## PARTE 4 — Convierte tu cuenta en administrador

Primero debes haber creado una cuenta en la propia página con tu correo.

1. En Supabase vuelve a **SQL Editor**.
2. Pulsa **New query**.
3. Copia este código:

```sql
update public.profiles
set role='admin', status='active', updated_at=now()
where lower(email)=lower('TU_CORREO_REAL');

select email,full_name,role,status
from public.profiles
where lower(email)=lower('TU_CORREO_REAL');
```

4. Cambia `TU_CORREO_REAL` por el correo que usas para iniciar sesión.
5. Pulsa **Run**.
6. En el resultado debe aparecer `role = admin`.
7. Cierra sesión en Britannia Path y vuelve a iniciarla.
8. En el menú aparecerá **Panel administrador**.

No existe un botón público para convertirse en administrador.

---

## PARTE 5 — Crea la función “admin-students”

Esta función permite que el administrador cree estudiantes sin exponer claves secretas.

1. En Supabase pulsa **Edge Functions**.
2. Pulsa **Deploy a new function**.
3. Elige **Via Editor**.
4. Nombre de la función: `admin-students`
5. Abre en tu computadora:
   `supabase/functions/admin-students/index.ts`
6. Copia todo y reemplaza el código del editor.
7. Pulsa **Deploy function** o **Deploy updates**.
8. Si aparece una opción **Verify JWT**, déjala activada.

No debes crear ni copiar una service-role key. Supabase entrega esa clave únicamente dentro de la función.

---

## PARTE 6 — Crea la función “cycle-exam”

1. Sigue en **Edge Functions**.
2. Pulsa **Deploy a new function → Via Editor**.
3. Nombre: `cycle-exam`
4. Abre:
   `supabase/functions/cycle-exam/index.ts`
5. Copia todo el código y pégalo.
6. Pulsa **Deploy function**.
7. Deja **Verify JWT** activado.

Esta función guarda las respuestas correctas en el servidor. El estudiante no puede verlas abriendo `index.html`.

---

## PARTE 7 — Configura las direcciones de correo

1. En Supabase entra a **Authentication → URL Configuration**.
2. En **Site URL** escribe exactamente:

`https://fayasta-debug.github.io/britannia-path/`

3. En **Redirect URLs** agrega:

`https://fayasta-debug.github.io/britannia-path/`

4. Agrega también:

`https://fayasta-debug.github.io/britannia-path/**`

5. Guarda.

---

## PARTE 8 — Prueba como administrador

1. Abre la página y recarga sin caché (`Command + Shift + R`).
2. Inicia sesión con la cuenta convertida en admin.
3. Abre **Panel administrador**.
4. Escribe nombre, correo y contraseña temporal.
5. Pulsa **Crear cuenta**.
6. Entrega el correo y la contraseña al estudiante de forma privada.
7. El estudiante deberá cambiar la contraseña al iniciar sesión.

---

## PARTE 9 — Prueba como estudiante

1. Abre una ventana privada del navegador.
2. Inicia sesión con la cuenta de estudiante.
3. Debe poder entrar únicamente a **Inducción**.
4. Marca al menos 21 lecciones como completadas.
5. Abre el ciclo y pulsa **Rendir examen final**.
6. Con menos de 70%, el siguiente ciclo queda bloqueado.
7. Con 70% o más, el siguiente ciclo se desbloquea automáticamente.

---

## ERRORES COMUNES

### “Function not found”
La Edge Function no se desplegó o su nombre no coincide exactamente. Debe llamarse `admin-students` o `cycle-exam`.

### “Solo un administrador…”
Tu cuenta sigue como `student`. Repite la Parte 4 y vuelve a iniciar sesión.

### “El banco de preguntas no está instalado”
Vuelve a ejecutar `01-database-and-exams.sql` completo.

### El panel no aparece
Haz una recarga completa y comprueba que el usuario tenga `role = admin` en `Table Editor → profiles`.

### El estudiante no puede rendir
Debe tener al menos 21 lecciones del ciclo guardadas en `lesson_progress`.

### GitHub muestra una versión antigua
Espera el check verde en **Actions** y recarga con `Command + Shift + R`.
