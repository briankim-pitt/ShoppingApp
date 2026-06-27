import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { z } from "zod";

const requestSchema = z.object({
  order_id: z.string().uuid(),
  force: z.boolean().default(true),
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
  if (error instanceof Error) {
    return error.message;
  }

  return "Unexpected error";
}

function statusForDatabaseError(message: string) {
  if (message.includes("not found")) return 404;
  if (message.includes("already")) return 409;
  return 400;
}

type ShippingRpcClient = {
  rpc: (
    functionName: "advance_virtual_order_shipping",
    args: {
      p_user_id: string;
      p_order_id: string;
      p_force: boolean;
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

    const admin = ctx.supabaseAdmin as unknown as ShippingRpcClient;
    const { data, error } = await admin.rpc("advance_virtual_order_shipping", {
      p_user_id: userId,
      p_order_id: payload.order_id,
      p_force: payload.force,
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
