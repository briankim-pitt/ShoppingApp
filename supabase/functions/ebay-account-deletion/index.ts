import "@supabase/functions-js/edge-runtime.d.ts";

// eBay Marketplace Account Deletion endpoint.
//
// eBay validates the endpoint with a GET challenge: the response must be the
// SHA-256 hex digest of challengeCode + verificationToken + endpointUrl.
// Deletion notifications arrive as POSTs and only need a 2xx acknowledgement.
// https://developer.ebay.com/marketplace-account-deletion

function json(body: unknown, status = 200) {
  return Response.json(body, {
    status,
    headers: {
      "cache-control": "no-store",
    },
  });
}

function verificationToken() {
  const token = Deno.env.get("EBAY_VERIFICATION_TOKEN");
  if (!token) {
    throw new Error(
      "eBay account deletion is not configured. Set EBAY_VERIFICATION_TOKEN.",
    );
  }

  return token;
}

function endpointUrl(request: Request) {
  const configured = Deno.env.get("EBAY_DELETION_ENDPOINT_URL");
  if (configured) {
    return configured;
  }

  const url = new URL(request.url);
  url.search = "";
  url.hash = "";
  return url.toString();
}

async function sha256Hex(value: string) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

export default {
  fetch: async (request: Request) => {
    if (request.method === "GET") {
      const challengeCode = new URL(request.url).searchParams.get(
        "challenge_code",
      );
      if (!challengeCode) {
        return json({ error: "Missing challenge_code" }, 400);
      }

      try {
        const challengeResponse = await sha256Hex(
          challengeCode + verificationToken() + endpointUrl(request),
        );
        return json({ challengeResponse });
      } catch (error) {
        const message = error instanceof Error
          ? error.message
          : "Unexpected error";
        return json({ error: message }, 503);
      }
    }

    if (request.method === "POST") {
      // Acknowledge immediately; the catalog only caches public listing
      // snapshots, so there is no per-user eBay data to erase.
      return new Response(null, { status: 204 });
    }

    return json({ error: "Method not allowed" }, 405);
  },
};
