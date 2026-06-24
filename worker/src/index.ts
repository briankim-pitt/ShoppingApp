import { createClient } from "@supabase/supabase-js";
import { readConfig } from "./config.js";

function main() {
  const config = readConfig();
  const client = createClient(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  console.log(JSON.stringify({
    ok: true,
    supabaseUrlHost: new URL(config.SUPABASE_URL).host,
    clientReady: Boolean(client),
  }, null, 2));
}

main();
