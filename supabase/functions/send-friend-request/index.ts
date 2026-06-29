import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { z } from "zod";

const requestSchema = z.object({
  recipient_user_id: z.string().uuid(),
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
  if (
    message.includes("already friends") ||
    message.includes("already sent")
  ) {
    return 409;
  }

  return 422;
}

type FriendRequestRpcClient = {
  rpc: (
    functionName: "send_friend_request",
    args: {
      p_requester_user_id: string;
      p_recipient_user_id: string;
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

    const admin = ctx.supabaseAdmin as unknown as FriendRequestRpcClient;
    const { data, error } = await admin.rpc("send_friend_request", {
      p_requester_user_id: userId,
      p_recipient_user_id: payload.recipient_user_id,
    });

    if (error) {
      return json(
        { error: error.message },
        statusForDatabaseError(error.message),
      );
    }

    const responseData = typeof data === "object" && data !== null
      ? data as Record<string, unknown>
      : {};
    const idempotentReplay = responseData.idempotent_replay === true;

    return json(responseData, idempotentReplay ? 200 : 201);
  }),
};
