import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { z } from "zod";

const requestSchema = z.object({
  request_id: z.string().uuid(),
  action: z.enum(["accepted", "rejected"]),
});

function json(body: unknown, status = 200) {
  return Response.json(body, {
    status,
    headers: {
      "cache-control": "no-store",
    },
  });
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Unexpected error";
}

function statusForDatabaseError(message: string) {
  if (message.includes("not found")) return 404;
  if (message.includes("already")) return 409;
  return 422;
}

type FriendResponseRpcClient = {
  rpc: (
    functionName: "respond_to_friend_request",
    args: {
      p_user_id: string;
      p_request_id: string;
      p_action: "accepted" | "rejected";
    },
  ) => Promise<{
    data: unknown;
    error: { message: string } | null;
  }>;
};

export default {
  fetch: withSupabase({ auth: "user" }, async (request, ctx) => {
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const userId = ctx.userClaims?.id;
    if (!userId) {
      return json({ error: "Missing authenticated user" }, 401);
    }

    let payload: z.infer<typeof requestSchema>;
    try {
      payload = requestSchema.parse(await request.json());
    } catch (error) {
      return json({ error: errorMessage(error) }, 400);
    }

    const admin = ctx.supabaseAdmin as unknown as FriendResponseRpcClient;
    const { data, error } = await admin.rpc("respond_to_friend_request", {
      p_user_id: userId,
      p_request_id: payload.request_id,
      p_action: payload.action,
    });

    if (error) {
      return json(
        { error: error.message },
        statusForDatabaseError(error.message),
      );
    }

    return json(data);
  }),
};
