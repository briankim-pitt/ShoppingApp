import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { z } from "zod";

const requestSchema = z.object({
  currency_code: z.string().trim().length(3).toUpperCase(),
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

type HomeCurrencyRpcClient = {
  rpc: (
    functionName: "set_home_currency",
    args: {
      p_user_id: string;
      p_currency_code: string;
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

    const admin = ctx.supabaseAdmin as unknown as HomeCurrencyRpcClient;
    const { data, error } = await admin.rpc("set_home_currency", {
      p_user_id: userId,
      p_currency_code: payload.currency_code,
    });

    if (error) {
      const status = error.message.includes("not found")
        ? 404
        : error.message.includes("cannot be changed")
        ? 409
        : 422;
      return json({ error: error.message }, status);
    }

    return json(data);
  }),
};
