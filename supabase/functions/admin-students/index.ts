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
  } catch {
    return "";
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

  try {
    const url = Deno.env.get("SUPABASE_URL") || "";
    const publishable = envKey("SUPABASE_ANON_KEY", "SUPABASE_PUBLISHABLE_KEYS");
    const secret = envKey("SUPABASE_SERVICE_ROLE_KEY", "SUPABASE_SECRET_KEYS");
    const authorization = req.headers.get("Authorization") || "";

    if (!url || !publishable || !secret) {
      return json({ error: "Faltan variables internas de Supabase" }, 500);
    }

    const callerClient = createClient(url, publishable, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: userData, error: userError } = await callerClient.auth.getUser();
    const caller = userData?.user;
    if (userError || !caller) return json({ error: "Sesión inválida" }, 401);

    const admin = createClient(url, secret, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: profile } = await admin
      .from("profiles")
      .select("role,status")
      .eq("id", caller.id)
      .maybeSingle();

    if (!profile || profile.role !== "admin" || profile.status !== "active") {
      return json({ error: "Solo un administrador puede realizar esta acción" }, 403);
    }

    const body = await req.json();
    const action = String(body.action || "create");

    if (action === "create") {
      const email = String(body.email || "").trim().toLowerCase();
      const fullName = String(body.full_name || "").trim();
      const temporaryPassword = String(body.temporary_password || "");

      if (!/^\S+@\S+\.\S+$/.test(email)) return json({ error: "Correo inválido" }, 400);
      if (fullName.length < 2) return json({ error: "Escribe el nombre del estudiante" }, 400);
      if (temporaryPassword.length < 10) {
        return json({ error: "La contraseña temporal debe tener al menos 10 caracteres" }, 400);
      }

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
      await admin.from("cycle_progress").upsert({
        student_id: data.user.id,
        cycle_id: "induction",
        status: "in_progress",
      });

      return json({ ok: true, student: { id: data.user.id, email, full_name: fullName } });
    }

    if (action === "reset_password") {
      const studentId = String(body.student_id || "");
      const temporaryPassword = String(body.temporary_password || "");
      if (!studentId || temporaryPassword.length < 10) {
        return json({ error: "Datos incompletos" }, 400);
      }
      const { error } = await admin.auth.admin.updateUserById(studentId, {
        password: temporaryPassword,
      });
      if (error) return json({ error: error.message }, 400);
      await admin.from("profiles").update({ must_change_password: true }).eq("id", studentId);
      return json({ ok: true });
    }

    if (action === "detail") {
      const studentId = String(body.student_id || "");
      if (!studentId) return json({ error: "Falta el estudiante" }, 400);

      const [
        profileResult,
        lessonResult,
        cycleResult,
        accessResult,
        assignmentResult,
        responseResult,
        attemptResult,
      ] = await Promise.all([
        admin.from("profiles").select("id,email,full_name,status,created_at").eq("id", studentId).eq("role", "student").maybeSingle(),
        admin.from("lesson_progress").select("lesson_key,cycle_id,unit_no,lesson_no,completed,score,completed_at").eq("student_id", studentId).order("completed_at", { ascending: false }),
        admin.from("cycle_progress").select("cycle_id,status,final_exam_score,attempt_count,completed_at,updated_at").eq("student_id", studentId),
        admin.from("cycle_access").select("cycle_id,is_unlocked,unlock_reason,unlocked_at").eq("student_id", studentId),
        admin.from("assignment_submissions").select("id,cycle_id,assignment_type,content,status,teacher_score,teacher_feedback,submitted_at,reviewed_at").eq("student_id", studentId).order("submitted_at", { ascending: false }),
        admin.from("activity_responses").select("response_key,cycle_id,unit_no,lesson_no,prompt,selected_answer,correct_answer,is_correct,answered_at,updated_at").eq("student_id", studentId).order("answered_at", { ascending: false }),
        admin.from("exam_attempts").select("id,cycle_id,session_id,attempt_number,answers,score,passed,started_at,submitted_at").eq("student_id", studentId).order("submitted_at", { ascending: false }),
      ]);

      const firstError = [profileResult, lessonResult, cycleResult, accessResult, assignmentResult, responseResult, attemptResult]
        .map((item) => item.error)
        .find(Boolean);
      if (firstError) throw firstError;
      if (!profileResult.data) return json({ error: "Estudiante no encontrado" }, 404);

      const attempts = attemptResult.data || [];
      const questionIds = [...new Set(attempts.flatMap((attempt: any) => Object.keys(attempt.answers || {})))];
      let questionMap = new Map<string, any>();
      if (questionIds.length) {
        const { data: questions, error } = await admin
          .from("exam_questions")
          .select("id,prompt,options,correct_index,explanation")
          .in("id", questionIds);
        if (error) throw error;
        questionMap = new Map((questions || []).map((question: any) => [question.id, question]));
      }

      const enrichedAttempts = attempts.map((attempt: any) => {
        const answers = attempt.answers || {};
        const details = Object.entries(answers).map(([questionId, selectedValue]) => {
          const question = questionMap.get(questionId);
          const selectedIndex = Number(selectedValue);
          const correctIndex = Number(question?.correct_index);
          return {
            question_id: questionId,
            prompt: question?.prompt || "Pregunta no disponible",
            selected_index: Number.isFinite(selectedIndex) ? selectedIndex : null,
            selected_option: Number.isFinite(selectedIndex) ? question?.options?.[selectedIndex] ?? "" : "",
            correct_index: Number.isFinite(correctIndex) ? correctIndex : null,
            correct_option: Number.isFinite(correctIndex) ? question?.options?.[correctIndex] ?? "" : "",
            correct: Number.isFinite(selectedIndex) && selectedIndex === correctIndex,
            explanation: question?.explanation || "",
          };
        });
        return { ...attempt, details };
      });

      return json({
        ok: true,
        detail: {
          profile: profileResult.data,
          lessons: lessonResult.data || [],
          cycles: cycleResult.data || [],
          access: accessResult.data || [],
          assignments: assignmentResult.data || [],
          responses: responseResult.data || [],
          attempts: enrichedAttempts,
        },
      });
    }

    if (action === "review_assignment") {
      const assignmentId = String(body.assignment_id || "");
      const score = body.teacher_score === null || body.teacher_score === ""
        ? null
        : Number(body.teacher_score);
      const feedback = String(body.teacher_feedback || "").slice(0, 10000);

      if (!assignmentId) return json({ error: "Falta la entrega" }, 400);
      if (score !== null && (!Number.isFinite(score) || score < 0 || score > 100)) {
        return json({ error: "La nota debe estar entre 0 y 100" }, 400);
      }

      const { data, error } = await admin
        .from("assignment_submissions")
        .update({
          teacher_score: score,
          teacher_feedback: feedback,
          status: "reviewed",
          reviewed_at: new Date().toISOString(),
        })
        .eq("id", assignmentId)
        .select("id,status,teacher_score,teacher_feedback,reviewed_at")
        .single();
      if (error) throw error;
      return json({ ok: true, assignment: data });
    }

    if (action === "reset_progress") {
      const studentId = String(body.student_id || "");
      if (!studentId) return json({ error: "Falta el estudiante" }, 400);

      const { data: target } = await admin
        .from("profiles")
        .select("id,role")
        .eq("id", studentId)
        .maybeSingle();
      if (!target || target.role !== "student") return json({ error: "Estudiante no encontrado" }, 404);

      for (const table of [
        "activity_responses",
        "assignment_submissions",
        "exam_attempts",
        "exam_sessions",
        "lesson_progress",
        "cycle_progress",
        "cycle_access",
      ]) {
        const column = table === "exam_sessions" ? "student_id" : "student_id";
        const { error } = await admin.from(table).delete().eq(column, studentId);
        if (error) throw error;
      }
      await admin.from("user_progress").delete().eq("user_id", studentId);
      await admin.from("cycle_access").insert({
        student_id: studentId,
        cycle_id: "induction",
        is_unlocked: true,
        unlock_reason: "progress reset by administrator",
        unlocked_by: caller.id,
      });
      await admin.from("cycle_progress").insert({
        student_id: studentId,
        cycle_id: "induction",
        status: "in_progress",
      });

      return json({ ok: true });
    }

    return json({ error: "Acción desconocida" }, 400);
  } catch (error) {
    console.error(error);
    return json({ error: error instanceof Error ? error.message : "Error interno" }, 500);
  }
});
