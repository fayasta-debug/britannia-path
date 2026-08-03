import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, "Content-Type": "application/json" },
});

function envKey(name: string, dictionaryName: string): string {
  const direct = Deno.env.get(name);
  if (direct) return direct;
  try {
    const dictionary = JSON.parse(Deno.env.get(dictionaryName) || "{}");
    return String(dictionary.default || Object.values(dictionary)[0] || "");
  } catch { return ""; }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);
  try {
    const url = Deno.env.get("SUPABASE_URL") || "";
    const publishable = envKey("SUPABASE_ANON_KEY", "SUPABASE_PUBLISHABLE_KEYS");
    const secret = envKey("SUPABASE_SERVICE_ROLE_KEY", "SUPABASE_SECRET_KEYS");
    const authorization = req.headers.get("Authorization") || "";
    if (!url || !publishable || !secret) return json({ error: "Faltan variables internas de Supabase" }, 500);

    const callerClient = createClient(url, publishable, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: userData, error: userError } = await callerClient.auth.getUser();
    const caller = userData?.user;
    if (userError || !caller) return json({ error: "Sesión inválida" }, 401);

    const admin = createClient(url, secret, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: profile } = await admin.from("profiles").select("role,status").eq("id", caller.id).maybeSingle();
    if (!profile || profile.role !== "admin" || profile.status !== "active") return json({ error: "Solo un administrador puede realizar esta acción" }, 403);

    const body = await req.json();
    const action = String(body.action || "create");

    if (action === "create") {
      const email = String(body.email || "").trim().toLowerCase();
      const fullName = String(body.full_name || "").trim();
      const temporaryPassword = String(body.temporary_password || "");
      if (!/^\S+@\S+\.\S+$/.test(email)) return json({ error: "Correo inválido" }, 400);
      if (fullName.length < 2) return json({ error: "Escribe el nombre del estudiante" }, 400);
      if (temporaryPassword.length < 10) return json({ error: "La contraseña temporal debe tener al menos 10 caracteres" }, 400);

      const { data, error } = await admin.auth.admin.createUser({
        email,
        password: temporaryPassword,
        email_confirm: true,
        user_metadata: { display_name: fullName, must_change_password: true },
      });
      if (error) return json({ error: error.message }, 400);
      if (!data.user) return json({ error: "No se creó el usuario" }, 500);

      await admin.from("profiles").upsert({
        id: data.user.id,
        email,
        full_name: fullName,
        role: "student",
        status: "active",
        must_change_password: true,
      });
      await admin.from("cycle_access").upsert({
        student_id: data.user.id,
        cycle_id: "induction",
        is_unlocked: true,
        unlock_reason: "created by administrator",
        unlocked_by: caller.id,
      });
      return json({ ok: true, student: { id: data.user.id, email, full_name: fullName } });
    }

    if (action === "reset_password") {
      const studentId = String(body.student_id || "");
      const temporaryPassword = String(body.temporary_password || "");
      if (!studentId || temporaryPassword.length < 10) return json({ error: "Datos incompletos" }, 400);
      const { error } = await admin.auth.admin.updateUserById(studentId, { password: temporaryPassword });
      if (error) return json({ error: error.message }, 400);
      await admin.from("profiles").update({ must_change_password: true }).eq("id", studentId);
      return json({ ok: true });
    }

    return json({ error: "Acción desconocida" }, 400);
  } catch (error) {
    console.error(error);
    return json({ error: error instanceof Error ? error.message : "Error interno" }, 500);
  }
});
