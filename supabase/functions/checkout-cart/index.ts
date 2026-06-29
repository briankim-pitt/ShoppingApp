import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { z } from "zod";

const cartItemSchema = z.object({
  product_id: z.string().uuid(),
  quantity: z.number().int().min(1).max(99),
  manual_price_amount: z.number().positive().max(9999999999.99).optional(),
  manual_currency_code: z.string().trim().length(3).toUpperCase().optional(),
});

const requestSchema = z.object({
  items: z.array(cartItemSchema).min(1).max(50),
  idempotency_key: z.string().uuid(),
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
  if (message.includes("Insufficient virtual balance")) return 409;
  if (
    message.includes("price") ||
    message.includes("currency") ||
    message.includes("quantity") ||
    message.includes("Quantity") ||
    message.includes("Cart") ||
    message.includes("cart") ||
    message.includes("idempotency") ||
    message.includes("product")
  ) {
    return 422;
  }

  return 400;
}

type CheckoutRpcClient = {
  rpc: (
    functionName: "place_virtual_cart_order",
    args: {
      p_user_id: string;
      p_items: z.infer<typeof cartItemSchema>[];
      p_idempotency_key: string;
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

    const admin = ctx.supabaseAdmin as unknown as CheckoutRpcClient;
    const { data, error } = await admin.rpc("place_virtual_cart_order", {
      p_user_id: userId,
      p_items: payload.items,
      p_idempotency_key: payload.idempotency_key,
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
