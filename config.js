/*
  CONFIGURACIÓN PÚBLICA PARA GITHUB PAGES
  1. Crea un proyecto en Supabase.
  2. Copia Project URL y la publishable/anon key.
  3. Reemplaza los valores siguientes.

  Es normal que esta clave aparezca en el navegador: debe ser la clave pública
  (publishable o anon), NUNCA una secret key ni service_role.
*/
window.BRITANNIA_CONFIG = {
  supabase: {
    url: "YOUR_SUPABASE_URL",
    publishableKey: "YOUR_SUPABASE_PUBLISHABLE_KEY"
  }
};
