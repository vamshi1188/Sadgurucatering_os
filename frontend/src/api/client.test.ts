import { afterEach, describe, expect, it, vi } from "vitest";
import { ApiError, apiClient } from "./client";

describe("apiClient", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("performs a GET request against the configured API base URL", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(JSON.stringify({ status: "ok" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    );

    const result = await apiClient.get<{ status: string }>("/health");

    expect(result).toEqual({ status: "ok" });
    expect(fetch).toHaveBeenCalledWith(
      "/api/v1/health",
      expect.objectContaining({
        headers: {
          "Content-Type": "application/json",
        },
      }),
    );
  });

  it("throws ApiError for failed responses", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(JSON.stringify({ message: "Unauthorized" }), {
        status: 401,
      }),
    );

    await expect(apiClient.get("/protected")).rejects.toEqual(
      new ApiError(401, "API request failed with status 401"),
    );
  });
});
