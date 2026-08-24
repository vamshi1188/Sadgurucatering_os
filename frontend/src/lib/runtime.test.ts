import { describe, expect, it } from "vitest";
import { validateRuntimeConfiguration } from "./runtime";

describe("runtime configuration", () => {
  it("accepts the configured API base URL", () => {
    expect(() => validateRuntimeConfiguration()).not.toThrow();
  });
});
