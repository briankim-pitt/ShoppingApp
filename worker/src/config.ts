import { z } from "zod";

const configSchema = z.object({
  SUPABASE_URL: z.url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
});

export function readConfig(env: Record<string, string | undefined> = process.env) {
  return configSchema.parse(env);
}
