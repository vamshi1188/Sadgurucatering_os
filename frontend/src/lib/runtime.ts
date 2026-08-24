import { config } from "./config";

export function validateRuntimeConfiguration(): void {
  if (!config.apiBaseUrl.startsWith("http")) {
    throw new Error(
      "Invalid VITE_API_BASE_URL: expected an HTTP(S) URL.",
    );
  }
}
