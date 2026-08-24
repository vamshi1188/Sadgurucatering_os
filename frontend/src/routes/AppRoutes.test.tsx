import { render, screen } from "@testing-library/react";
import {
  createMemoryRouter,
  RouterProvider,
} from "react-router-dom";
import { describe, expect, it } from "vitest";
import { routes } from "./AppRoutes";

function renderRoute(initialEntry: string) {
  const router = createMemoryRouter(routes, {
    initialEntries: [initialEntry],
  });

  return render(<RouterProvider router={router} />);
}

describe("AppRoutes", () => {
  it("renders the home route", () => {
    renderRoute("/");

    expect(
      screen.getByText("Sadguru Catering OS — Home"),
    ).toBeInTheDocument();
  });

  it("renders the not-found route", () => {
    renderRoute("/does-not-exist");

    expect(
      screen.getByText("Sadguru Catering OS — Page Not Found"),
    ).toBeInTheDocument();
  });
});
