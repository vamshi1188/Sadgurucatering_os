import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { cleanup, render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { DashboardPage, rangeFor } from "./pages";
import { getDashboardSummary } from "../api/dashboard";

vi.mock("../api/dashboard", () => ({
  getDashboardSummary: vi.fn(),
}));

vi.mock("../hooks/useHealthCheck", () => ({
  useHealthCheck: () => ({
    data: { status: "ok" },
    isLoading: false,
    isError: false,
  }),
}));

const mockedGetDashboardSummary = vi.mocked(getDashboardSummary);

afterEach(() => {
  cleanup();
});

function renderDashboard() {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <DashboardPage />
      </MemoryRouter>
    </QueryClientProvider>,
  );
}

const summary = {
  from: "2026-09-02",
  to: "2026-09-02",
  event_count: 2,
  upcoming_count: 1,
  running_count: 1,
  completed_count: 0,
  total_income: "70000.00",
  total_expenses: "25000.00",
  profit: "45000.00",
  events: [
    {
      id: 1,
      title: "Wedding A",
      event_date: "2026-09-02",
      venue: "Hall A",
      guest_count: 500,
      status: "running" as const,
      total_income: "50000.00",
      total_expenses: "18000.00",
      profit: "32000.00",
    },
    {
      id: 2,
      title: "Wedding B",
      event_date: "2026-09-02",
      venue: "Hall B",
      guest_count: 150,
      status: "upcoming" as const,
      total_income: "20000.00",
      total_expenses: "7000.00",
      profit: "13000.00",
    },
  ],
};

describe("rangeFor", () => {
  const now = new Date(2026, 8, 2, 23, 30, 0);

  it("returns today", () => {
    expect(rangeFor("today", now)).toEqual({
      from: "2026-09-02",
      to: "2026-09-02",
    });
  });

  it("returns yesterday", () => {
    expect(rangeFor("yesterday", now)).toEqual({
      from: "2026-09-01",
      to: "2026-09-01",
    });
  });

  it("returns the current week starting Sunday", () => {
    expect(rangeFor("week", now)).toEqual({
      from: "2026-08-30",
      to: "2026-09-02",
    });
  });

  it("returns the current month", () => {
    expect(rangeFor("month", now)).toEqual({
      from: "2026-09-01",
      to: "2026-09-02",
    });
  });

  it("returns the current year", () => {
    expect(rangeFor("year", now)).toEqual({
      from: "2026-01-01",
      to: "2026-09-02",
    });
  });

  it("uses today as the fallback for custom period", () => {
    expect(rangeFor("custom", now)).toEqual({
      from: "2026-09-02",
      to: "2026-09-02",
    });
  });
});

describe("DashboardPage", () => {
  beforeEach(() => {
    vi.clearAllMocks();

    mockedGetDashboardSummary.mockResolvedValue({
      data: summary,
    });
  });

  it("renders operational and financial dashboard data", async () => {
    renderDashboard();

    expect(await screen.findAllByText("₹70,000.00")).toHaveLength(2);

    expect(screen.getByText("Wedding A")).toBeInTheDocument();
    expect(screen.getByText("Wedding B")).toBeInTheDocument();
    expect(screen.getByText("Revenue")).toBeInTheDocument();
    expect(screen.getByText("Expenses")).toBeInTheDocument();
    expect(screen.getByText("Profit")).toBeInTheDocument();

    expect(screen.getAllByText("₹70,000.00")).toHaveLength(2);
    expect(screen.getAllByText("₹25,000.00")).toHaveLength(2);
    expect(screen.getAllByText("₹45,000.00")).toHaveLength(2);
  });

  it("requests the today dashboard summary on initial render", async () => {
    renderDashboard();

    await waitFor(() => {
      expect(mockedGetDashboardSummary).toHaveBeenCalled();
    });

    expect(mockedGetDashboardSummary).toHaveBeenCalledWith(
      expect.objectContaining({
        from: expect.any(String),
        to: expect.any(String),
      }),
    );
  });

  it("changes the dashboard period", async () => {
    const user = await import("@testing-library/user-event");
    const userEvent = user.default.setup();

    renderDashboard();

    await screen.findAllByText("₹70,000.00");

    await userEvent.click(screen.getByRole("button", { name: "Month" }));

    await waitFor(() => {
      expect(mockedGetDashboardSummary).toHaveBeenCalledWith(
        expect.objectContaining({
          from: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/),
          to: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/),
        }),
      );
    });
  });

  it("shows an empty state when the selected period has no events", async () => {
    mockedGetDashboardSummary.mockResolvedValue({
      data: {
        ...summary,
        event_count: 0,
        upcoming_count: 0,
        running_count: 0,
        completed_count: 0,
        total_income: "0.00",
        total_expenses: "0.00",
        profit: "0.00",
        events: [],
      },
    });

    renderDashboard();

    expect(
      await screen.findByText("No events in this period"),
    ).toBeInTheDocument();
  });

  it("links dashboard events to their event finance details", async () => {
    renderDashboard();

    const eventLinks = await screen.findAllByRole("link", {
      name: /Wedding A/i,
    });

    expect(eventLinks).toHaveLength(1);
    expect(eventLinks[0]).toHaveAttribute("href", "/events?event=1");
  });
});
