import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render, screen } from "@testing-library/react";
import {
  createMemoryRouter,
  RouterProvider,
} from "react-router-dom";
import { describe, expect, it, vi } from "vitest";
import { AuthProvider } from "../auth/AuthContext";
import { routes } from "./routes";

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

function renderRoute(initialEntry: string) {
  const router = createMemoryRouter(routes, {
    initialEntries: [initialEntry],
  });

  const queryClient = new QueryClient();

  return render(
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <RouterProvider router={router} />
      </AuthProvider>
    </QueryClientProvider>
  );
}

describe("AppRoutes", () => {
  it("renders the dashboard route", async () => {
    renderRoute("/");

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
  });

  it("renders the not-found route", () => {
    renderRoute("/does-not-exist");

    expect(
      screen.getByRole("heading", {
        name: "Page not found",
      }),
    ).toBeInTheDocument();

    expect(
      screen.getByText("The page you're looking for doesn't exist."),
    ).toBeInTheDocument();
  });
});
