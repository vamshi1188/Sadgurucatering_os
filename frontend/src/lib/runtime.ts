import { config } from "./config";

export function validateRuntimeConfiguration(): void {
  if (!config.apiBaseUrl.startsWith("/api/")) {
    throw new Error("Invalid API base URL: expected a same-origin /api/ path.");
  }
}
