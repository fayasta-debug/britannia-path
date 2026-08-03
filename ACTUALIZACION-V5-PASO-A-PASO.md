# Britannia Path Admin V5 — actualización sencilla

Esta actualización corrige dos problemas:

1. Cada estudiante tendrá sus propias respuestas y notas, incluso si varias cuentas usan el mismo navegador.
2. El administrador podrá abrir la ficha de un estudiante y revisar:
   - respuestas de prácticas;
   - producciones escritas;
   - nota y retroalimentación;
   - cada intento del examen final;
   - respuesta elegida y respuesta correcta de cada pregunta.

## Parte 1 — Actualizar GitHub

1. Descarga y descomprime `britannia-path-admin-v5.zip`.
2. Entra a tu repositorio de GitHub `britannia-path`.
3. Pulsa **Add file → Upload files**.
4. Sube todos los archivos de la carpeta descomprimida.
5. Confirma con **Commit changes**.
6. Entra a **Actions** y espera que `build` y `deploy` aparezcan en verde.

No cambies tu `config.js` si ya contiene tu URL y tu `publishableKey` de Supabase.

## Parte 2 — Crear la tabla de respuestas privadas

1. Entra a tu proyecto de Supabase.
2. Pulsa **SQL Editor**.
3. Pulsa **New query**.
4. Abre el archivo:

   `supabase/03-private-responses-and-admin-review.sql`

5. Copia todo su contenido.
6. Pégalo en Supabase.
7. Pulsa **Run**.
8. Debe aparecer un resultado parecido a:

   `activity_responses instalada | true`

Esta tabla usa el identificador del estudiante como parte de su clave. Por eso una respuesta de una cuenta no puede sobrescribir la respuesta de otra.

## Parte 3 — Actualizar la función admin-students

1. En Supabase pulsa **Edge Functions**.
2. Abre la función `admin-students`.
3. Pulsa **Edit** o abre su editor.
4. Borra el código anterior.
5. Abre este archivo del proyecto:

   `supabase/functions/admin-students/index.ts`

6. Copia todo y pégalo en la función.
7. Pulsa **Deploy**.
8. Mantén **Verify JWT desactivado**, porque el código valida internamente la sesión y el rol administrador.

No tienes que cambiar la función `cycle-exam` para esta corrección.

## Parte 4 — Probar que cada cuenta esté separada

1. Abre Britannia Path en una ventana normal.
2. Inicia sesión con el estudiante A y responde una práctica.
3. Cierra sesión.
4. Inicia sesión con el estudiante B.
5. La respuesta del estudiante A ya no debe aparecer.
6. Responde otra práctica con el estudiante B.
7. Inicia sesión como administrador.
8. Abre **Panel administrador → Ver progreso**.
9. Usa las pestañas:
   - **Progreso**
   - **Trabajos**
   - **Prácticas**
   - **Exámenes**

## Parte 5 — Corregir datos que ya se mezclaron antes

Los datos antiguos que ya fueron copiados entre cuentas no pueden separarse automáticamente con seguridad.

Para borrar solo el progreso contaminado de un estudiante:

1. Entra como administrador.
2. Abre **Panel administrador**.
3. Pulsa **Ver progreso** en el estudiante afectado.
4. Pulsa **Restablecer progreso**.
5. Confirma escribiendo `RESTABLECER`.

Esto borra las lecciones, respuestas, entregas y exámenes de ese estudiante y vuelve a desbloquear únicamente Inducción. No elimina su cuenta.

## Qué cambió técnicamente

- El navegador ahora usa una clave local diferente para cada `user.id`.
- Al cerrar sesión se carga un espacio de invitado separado.
- Al iniciar sesión solo se combina la nube con el almacenamiento local de ese mismo usuario.
- Las prácticas se guardan en `activity_responses` con clave compuesta `student_id + response_key`.
- La función `admin-students` devuelve al administrador respuestas, trabajos y exámenes enriquecidos.
- El administrador puede calificar entregas y escribir retroalimentación.
