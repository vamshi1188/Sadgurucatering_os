import { describe, expect, it } from "vitest";

import { config } from "./config";

describe("config", () => {
  it("uses the same-origin API base URL", () => {
    expect(config.apiBaseUrl).toBe("/api/v1");
  });
});
