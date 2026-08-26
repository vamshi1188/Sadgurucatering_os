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
    </QueryClientProvider>,
  );
}

describe("AppRoutes", () => {
  it("renders the dashboard route", async () => {
    renderRoute("/");

    expect(
      await screen.findByRole("heading", {
        name: "Sadguru Catering OS",
      }),
    ).toBeInTheDocument();

    expect(
      screen.getByText("Backend status: ok"),
    ).toBeInTheDocument();
  });

  it("renders the not-found route", () => {
    renderRoute("/does-not-exist");

    expect(
      screen.getByText("Sadguru Catering OS — Page Not Found"),
    ).toBeInTheDocument();
  });
});
