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

vi.mock("../api/dashboard", () => ({
  getDashboardSummary: vi.fn().mockResolvedValue({
    data: {
      event_count: 0,
      upcoming_count: 0,
      running_count: 0,
      completed_count: 0,
      total_income: "0.00",
      total_expenses: "0.00",
      profit: "0.00",
      events: [],
    },
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
        name: "Good morning",
      }),
    ).toBeInTheDocument();

    expect(screen.getByText("Event activity")).toBeInTheDocument();

    expect(
      screen.getByRole("button", { name: "System Status" }),
    ).toBeInTheDocument();

    expect(screen.queryByText("System health")).not.toBeInTheDocument();
  });
});
