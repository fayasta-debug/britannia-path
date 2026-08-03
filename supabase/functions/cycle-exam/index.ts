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
    const callerClient = createClient(url, publishable, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: userData, error: userError } = await callerClient.auth.getUser();
    const user = userData?.user;
    if (userError || !user) return json({ error: "Inicia sesión para rendir el examen" }, 401);

    const admin = createClient(url, secret, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: profile } = await admin.from("profiles").select("role,status").eq("id", user.id).maybeSingle();
    if (!profile || profile.status !== "active") return json({ error: "La cuenta no está activa" }, 403);

    const body = await req.json();
    const action = String(body.action || "start");
    const cycleId = String(body.cycle_id || "");
    if (!cycleId) return json({ error: "Falta el ciclo" }, 400);

    if (action === "start") {
      const { data: existing } = await admin.from("cycle_progress").select("status").eq("student_id", user.id).eq("cycle_id", cycleId).maybeSingle();
      if (existing?.status === "completed" && profile.role !== "admin") return json({ error: "Este ciclo ya fue aprobado" }, 409);

      if (profile.role !== "admin") {
        const { data: access } = await admin.from("cycle_access").select("is_unlocked").eq("student_id", user.id).eq("cycle_id", cycleId).maybeSingle();
        if (!access?.is_unlocked) return json({ error: "El ciclo está bloqueado" }, 403);
        const { count } = await admin.from("lesson_progress").select("lesson_key", { count: "exact", head: true }).eq("student_id", user.id).eq("cycle_id", cycleId).eq("completed", true);
        if ((count || 0) < 21) return json({ error: `Completa al menos 21 de 24 lecciones antes del examen. Actualmente: ${count || 0}.`, code: "not_ready", completed_lessons: count || 0 }, 409);
      }

      const { data: questions, error } = await admin.from("exam_questions")
        .select("id,position,section,prompt,options")
        .eq("cycle_id", cycleId).eq("active", true).order("position");
      if (error) throw error;
      if (!questions || questions.length < 5) return json({ error: "El banco de preguntas de este ciclo no está instalado" }, 500);
      const questionIds = questions.map((item) => item.id);
      const { data: session, error: sessionError } = await admin.from("exam_sessions")
        .insert({ student_id: user.id, cycle_id: cycleId, question_ids: questionIds }).select("id,expires_at").single();
      if (sessionError) throw sessionError;
      return json({ ok: true, session_id: session.id, expires_at: session.expires_at, questions });
    }

    if (action === "submit") {
      const sessionId = String(body.session_id || "");
      const answers = body.answers && typeof body.answers === "object" ? body.answers : {};
      const { data: session, error: sessionError } = await admin.from("exam_sessions")
        .select("id,student_id,cycle_id,question_ids,started_at,expires_at,submitted_at")
        .eq("id", sessionId).eq("student_id", user.id).eq("cycle_id", cycleId).maybeSingle();
      if (sessionError || !session) return json({ error: "Sesión de examen no encontrada" }, 404);
      if (session.submitted_at) return json({ error: "Este intento ya fue enviado" }, 409);
      if (new Date(session.expires_at).getTime() < Date.now()) return json({ error: "El examen venció. Inicia un nuevo intento." }, 409);

      const ids = Array.isArray(session.question_ids) ? session.question_ids : [];
      const { data: questions, error } = await admin.from("exam_questions")
        .select("id,prompt,options,correct_index,explanation")
        .in("id", ids);
      if (error) throw error;
      const byId = new Map((questions || []).map((item) => [item.id, item]));
      let correct = 0;
      const feedback = ids.map((id: string) => {
        const item: any = byId.get(id);
        const selected = Number(answers[id]);
        const isCorrect = item && selected === Number(item.correct_index);
        if (isCorrect) correct += 1;
        return {
          question_id: id,
          prompt: item?.prompt || "",
          selected_index: Number.isFinite(selected) ? selected : null,
          correct_index: item?.correct_index,
          correct_option: item?.options?.[item?.correct_index] || "",
          correct: isCorrect,
          explanation: item?.explanation || "",
        };
      });
      const total = ids.length || 1;
      const score = Math.round((correct / total) * 10000) / 100;
      const passed = score >= 70;
      const { count } = await admin.from("exam_attempts").select("id", { count: "exact", head: true }).eq("student_id", user.id).eq("cycle_id", cycleId);
      const attemptNumber = (count || 0) + 1;
      const { error: attemptError } = await admin.from("exam_attempts").insert({
        student_id: user.id, cycle_id: cycleId, session_id: session.id,
        attempt_number: attemptNumber, answers, score, passed, started_at: session.started_at,
      });
      if (attemptError) throw attemptError;
      await admin.from("exam_sessions").update({ submitted_at: new Date().toISOString() }).eq("id", session.id);
      await admin.from("cycle_progress").upsert({
        student_id: user.id, cycle_id: cycleId,
        status: passed ? "completed" : "needs_review",
        final_exam_score: score, attempt_count: attemptNumber,
        completed_at: passed ? new Date().toISOString() : null,
      }, { onConflict: "student_id,cycle_id" });

      let nextCycle: any = null;
      if (passed) {
        const { data: currentCycle } = await admin.from("course_cycles").select("sequence").eq("id", cycleId).single();
        if (currentCycle) {
          const { data: next } = await admin.from("course_cycles").select("id,code,title").eq("sequence", currentCycle.sequence + 1).maybeSingle();
          if (next) {
            nextCycle = next;
            await admin.from("cycle_access").upsert({
              student_id: user.id, cycle_id: next.id, is_unlocked: true,
              unlock_reason: `passed ${cycleId}`, unlocked_by: null,
            }, { onConflict: "student_id,cycle_id" });
            await admin.from("cycle_progress").upsert({ student_id: user.id, cycle_id: next.id, status: "in_progress" }, { onConflict: "student_id,cycle_id", ignoreDuplicates: true });
          }
        }
      }
      return json({ ok: true, score, passed, correct, total, attempt_number: attemptNumber, next_cycle: nextCycle, feedback });
    }
    return json({ error: "Acción desconocida" }, 400);
  } catch (error) {
    console.error(error);
    return json({ error: error instanceof Error ? error.message : "Error interno" }, 500);
  }
});
