import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { createClient } from "npm:@supabase/supabase-js@2.108.2";
import { z } from "npm:zod@4.4.3";

const requestSchema = z.object({
  product_id: z.string().uuid(),
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

function authenticatedUserID(ctx: unknown) {
  const userClaims = typeof ctx === "object" && ctx !== null && "userClaims" in ctx
    ? Reflect.get(ctx, "userClaims")
    : null;
  const rawUserId = typeof userClaims === "object" && userClaims !== null && "id" in userClaims
    ? Reflect.get(userClaims, "id")
    : null;

  return typeof rawUserId === "string" && rawUserId.length > 0 ? rawUserId : null;
}

export default {
  fetch: withSupabase({ auth: "user" }, async (
    request: Request,
    ctx: unknown,
  ) => {
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const userId = authenticatedUserID(ctx);
    if (!userId) {
      return json({ error: "Missing authenticated user" }, 401);
    }

    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (!serviceRoleKey || !supabaseUrl) {
      return json({ error: "Missing Supabase environment variables" }, 500);
    }

    let payload: z.infer<typeof requestSchema>;
    try {
      payload = requestSchema.parse(await request.json());
    } catch (error) {
      return json({ error: errorMessage(error) }, 400);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    try {
      const { data: imports, error: importLookupError } = await admin
        .from("product_imports")
        .select("id")
        .eq("user_id", userId)
        .eq("product_id", payload.product_id);

      if (importLookupError) {
        throw importLookupError;
      }

      if (!imports?.length) {
        return json({ error: "No matching import was found." }, 404);
      }

      const { error: deleteImportError } = await admin
        .from("product_imports")
        .delete()
        .eq("user_id", userId)
        .eq("product_id", payload.product_id);

      if (deleteImportError) {
        throw deleteImportError;
      }

      const { data: remainingImports, error: remainingLookupError } = await admin
        .from("product_imports")
        .select("id")
        .eq("product_id", payload.product_id)
        .limit(1);

      if (remainingLookupError) {
        throw remainingLookupError;
      }

      let deletedProduct = false;
      if (!remainingImports?.length) {
        const { error: deleteProductError } = await admin
          .from("products")
          .delete()
          .eq("id", payload.product_id);

        if (deleteProductError) {
          throw deleteProductError;
        }

        deletedProduct = true;
      }

      return json({
        deleted_import: true,
        deleted_product: deletedProduct,
      });
    } catch (error) {
      return json({ error: errorMessage(error) }, 400);
    }
  }),
};
