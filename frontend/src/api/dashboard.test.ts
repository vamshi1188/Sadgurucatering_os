import { afterEach, describe, expect, it, vi } from "vitest";
import { getDashboardSummary } from "./dashboard";

describe("dashboard API", () => {
  afterEach(() => vi.restoreAllMocks());

  it("requests an inclusive date range and preserves the API response", async () => {
    const response = {
      data: {
        from: "2026-09-01",
        to: "2026-09-02",
        event_count: 2,
        total_income: "70000.00",
      },
    };
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response(JSON.stringify(response), { status: 200 }),
    );
    await expect(
      getDashboardSummary({ from: "2026-09-01", to: "2026-09-02" }),
    ).resolves.toEqual(response);
    expect(fetch).toHaveBeenCalledWith(
      "/api/v1/dashboard/summary?from=2026-09-01&to=2026-09-02",
      expect.anything(),
    );
  });
});
