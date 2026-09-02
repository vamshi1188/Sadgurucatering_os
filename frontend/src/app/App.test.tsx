import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { App } from "./App";

vi.mock("../hooks/useHealthCheck", () => ({
  useHealthCheck: () => ({
    data: { status: "ok" },
    isLoading: false,
    isError: false,
  }),
}));

vi.mock("../api/auth", () => ({
  getSession: vi.fn().mockResolvedValue({
    authenticated: true,
  }),
  login: vi.fn(),
  logout: vi.fn(),
}));

describe("App", () => {
  it("renders the application dashboard", async () => {
    render(<App />);

    expect(
      await screen.findByRole("heading", {
        name: "Operations workspace",
      }),
    ).toBeInTheDocument();

    expect(
      screen.getByRole("heading", {
        name: "Welcome back, Vamshi.",
      }),
    ).toBeInTheDocument();

    expect(
      screen.getByText("Recent events"),
    ).toBeInTheDocument();

    expect(
      screen.getByText("System health"),
    ).toBeInTheDocument();
  });
});
