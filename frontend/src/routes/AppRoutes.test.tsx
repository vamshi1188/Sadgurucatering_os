import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render, screen } from "@testing-library/react";
import {
  createMemoryRouter,
  RouterProvider,
} from "react-router-dom";
import { describe, expect, it, vi } from "vitest";
import { routes } from "./AppRoutes";

vi.mock("../hooks/useHealthCheck", () => ({
  useHealthCheck: () => ({
    data: { status: "ok" },
    isLoading: false,
    isError: false,
  }),
}));

function renderRoute(initialEntry: string) {
  const router = createMemoryRouter(routes, {
    initialEntries: [initialEntry],
  });

  const queryClient = new QueryClient();

  return render(
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>,
  );
}

describe("AppRoutes", () => {
  it("renders the dashboard route", () => {
    renderRoute("/");

    expect(
      screen.getByRole("heading", {
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
