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
        name: "Welcome back, Vamshi.",
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
