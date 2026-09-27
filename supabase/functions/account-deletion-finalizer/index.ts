import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const jsonHeaders = { "Content-Type": "application/json" };

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return new Response(JSON.stringify({ error: "method_not_allowed" }), {
      status: 405,
      headers: jsonHeaders,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authorization = request.headers.get("Authorization");

  if (!supabaseUrl || !serviceRoleKey) {
    return new Response(JSON.stringify({ error: "server_configuration_error" }), {
      status: 500,
      headers: jsonHeaders,
    });
  }

  if (authorization !== `Bearer ${serviceRoleKey}`) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: jsonHeaders,
    });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: requests, error: listError } = await admin
    .from("account_deletion_requests")
    .select("subject_user_id,user_id")
    .eq("status", "pending")
    .lte("scheduled_for", new Date().toISOString())
    .not("user_id", "is", null);

  if (listError) {
    return new Response(JSON.stringify({ error: "request_lookup_failed" }), {
      status: 500,
      headers: jsonHeaders,
    });
  }

  let finalized = 0;
  const failures: string[] = [];

  for (const item of requests ?? []) {
    const userId = item.user_id as string | null;
    const subjectUserId = item.subject_user_id as string;
    if (!userId || userId !== subjectUserId) {
      failures.push(subjectUserId);
      continue;
    }

    const { error: prepareError } = await admin.rpc(
      "prepare_account_deletion_finalization",
      { p_user_id: userId },
    );
    if (prepareError) {
      failures.push(subjectUserId);
      continue;
    }

    const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
    if (deleteError) {
      failures.push(subjectUserId);
      continue;
    }

    const { error: completeError } = await admin.rpc(
      "complete_account_deletion_finalization",
      { p_subject_user_id: subjectUserId },
    );
    if (completeError) {
      failures.push(subjectUserId);
      continue;
    }

    finalized += 1;
  }

  return new Response(JSON.stringify({ finalized, failures }), {
    status: failures.length === 0 ? 200 : 207,
    headers: jsonHeaders,
  });
});
