import { beforeEach, describe, expect, it, vi } from "vitest";

describe("config", () => {
  beforeEach(() => {
    vi.resetModules();
  });

  it("reads the API base URL", async () => {
    vi.stubEnv("VITE_API_BASE_URL", "http://localhost:8080/api/v1");

    const { config } = await import("./config");

    expect(config.apiBaseUrl).toBe("http://localhost:8080/api/v1");
  });

  it("throws when the API base URL is missing", async () => {
    vi.stubEnv("VITE_API_BASE_URL", "");

    await expect(import("./config")).rejects.toThrow(
      "Missing required environment variable: VITE_API_BASE_URL",
    );
  });
});
