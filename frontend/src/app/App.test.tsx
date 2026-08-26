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
        name: "Sadguru Catering OS",
      }),
    ).toBeInTheDocument();

    expect(
      screen.getByText("Backend Health"),
    ).toBeInTheDocument();

    expect(
      screen.getByText("Backend status: ok"),
    ).toBeInTheDocument();
  });
});
