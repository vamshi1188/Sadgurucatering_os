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

describe("App", () => {
  it("renders the application dashboard", () => {
    render(<App />);

    expect(
      screen.getByRole("heading", {
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
