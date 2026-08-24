import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { Button, Card, Input } from "./index";

describe("shared UI primitives", () => {
  it("renders Button", () => {
    render(<Button>Save</Button>);

    expect(screen.getByRole("button", { name: "Save" })).toBeInTheDocument();
  });

  it("renders Card", () => {
    render(<Card>Content</Card>);

    expect(screen.getByText("Content")).toBeInTheDocument();
  });

  it("renders Input", () => {
    render(<Input aria-label="Name" />);

    expect(screen.getByRole("textbox", { name: "Name" })).toBeInTheDocument();
  });
});
