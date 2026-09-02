import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Link } from "react-router-dom";
import { getDashboardSummary, type DashboardEvent } from "../api/dashboard";
import { useHealthCheck } from "../hooks/useHealthCheck";

type Period = "today" | "yesterday" | "week" | "month" | "year" | "custom";

function dateString(date: Date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function rangeFor(period: Period, now = new Date()) {
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  if (period === "today")
    return { from: dateString(today), to: dateString(today) };
  if (period === "yesterday") {
    const day = new Date(today);
    day.setDate(day.getDate() - 1);
    return { from: dateString(day), to: dateString(day) };
  }
  if (period === "week") {
    const start = new Date(today);
    start.setDate(start.getDate() - start.getDay());
    return { from: dateString(start), to: dateString(today) };
  }
  if (period === "month")
    return {
      from: dateString(new Date(today.getFullYear(), today.getMonth(), 1)),
      to: dateString(today),
    };
  if (period === "year")
    return {
      from: dateString(new Date(today.getFullYear(), 0, 1)),
      to: dateString(today),
    };
  return { from: dateString(today), to: dateString(today) };
}

function formatCurrency(value: string) {
  const amount = Number(value);
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 2,
  }).format(Number.isFinite(amount) ? amount : 0);
}

function EventRow({ event }: { event: DashboardEvent }) {
  return (
    <Link className="event-row" to={`/events?event=${event.id}`}>
      <div className="event-main">
        <strong>{event.title}</strong>
        <span>
          {event.venue} · {event.guest_count.toLocaleString("en-IN")} guests
        </span>
      </div>
      <span className={`status-badge status-${event.status}`}>
        <span />
        {event.status}
      </span>
      <div className="event-finance">
        <strong>{formatCurrency(event.profit)}</strong>
        <span>profit</span>
      </div>
    </Link>
  );
}

export function DashboardPage() {
  const [period, setPeriod] = useState<Period>("today");
  const [customFrom, setCustomFrom] = useState("");
  const [customTo, setCustomTo] = useState("");
  const [healthOpen, setHealthOpen] = useState(false);

  const {
    data: health,
    isLoading: healthLoading,
    isError: healthError,
  } = useHealthCheck();

  const range =
    period === "custom" && customFrom && customTo
      ? { from: customFrom, to: customTo }
      : rangeFor(period);

  const todayRange = rangeFor("today");

  const todayQuery = useQuery({
    queryKey: ["dashboard-summary", todayRange],
    queryFn: () => getDashboardSummary(todayRange),
  });

  const query = useQuery({
    queryKey: ["dashboard-summary", range],
    queryFn: () => getDashboardSummary(range),
    enabled: period !== "custom" || Boolean(customFrom && customTo),
  });

  const summary = query.data?.data;
  const todaySummary = todayQuery.data?.data;

  const label =
    period === "today"
      ? "Today"
      : period === "yesterday"
        ? "Yesterday"
        : period === "week"
          ? "This week"
          : period === "month"
            ? "This month"
            : period === "year"
              ? "This year"
              : "Custom range";

  const operationalCards = [
    [
      "Today's Events",
      todaySummary?.event_count ?? 0,
      "Scheduled for today",
      "",
    ],
    [
      "Events in Progress",
      todaySummary?.running_count ?? 0,
      "Currently running",
      "stat-running",
    ],
    [
      "Completed Today",
      todaySummary?.completed_count ?? 0,
      "Finished today",
      "stat-completed",
    ],
  ] as const;

  const financialCards = [
    [
      "Today's Bookings",
      formatCurrency(todaySummary?.total_income ?? "0"),
      "Total revenue",
      "stat-featured",
    ],
    [
      "Today's Expenses",
      formatCurrency(todaySummary?.total_expenses ?? "0"),
      "Total expenses",
      "",
    ],
    [
      "Today's Profit",
      formatCurrency(todaySummary?.profit ?? "0"),
      "Revenue minus expenses",
      "stat-profit",
    ],
  ] as const;

  return (
    <div className="dashboard-page">
      <section className="page-heading">
        <div>
          <span className="section-kicker">OPERATIONS DASHBOARD</span>
          <h1>Good morning</h1>
          <p>Here is what is happening across your catering operations.</p>
        </div>

        <div className="dashboard-actions">
          <button
            className="ui-button ui-button-secondary"
            type="button"
            onClick={() => setHealthOpen(true)}
          >
            System Status
          </button>

          <Link className="button-link" to="/events">
            New event <span>+</span>
          </Link>
        </div>
      </section>

      <section aria-label="Today's operations">
        <div className="dashboard-section-heading">
          <div>
            <span className="section-kicker">TODAY'S OPERATIONS</span>
            <h3>Event activity at a glance</h3>
          </div>
        </div>

        <div className="stats-grid stats-grid-three">
          {operationalCards.map(([name, value, foot, className]) => (
            <article className={`stat-card ${className}`} key={name}>
              <span>{name}</span>
              <strong>{value}</strong>
              <small>{foot}</small>
            </article>
          ))}
        </div>
      </section>

      <section
        className="dashboard-financial-snapshot"
        aria-label="Today's financial snapshot"
      >
        <div className="dashboard-section-heading">
          <div>
            <span className="section-kicker">TODAY'S FINANCIAL SNAPSHOT</span>
            <h3>Money in, money out, profit</h3>
          </div>
        </div>

        <div className="stats-grid stats-grid-three">
          {financialCards.map(([name, value, foot, className]) => (
            <article className={`stat-card ${className}`} key={name}>
              <span>{name}</span>
              <strong>{value}</strong>
              <small>{foot}</small>
            </article>
          ))}
        </div>
      </section>

      <section className="panel dashboard-finance">
        <div className="panel-heading">
          <div>
            <span className="section-kicker">
              {label.toUpperCase()} FINANCE
            </span>
            <h3>Financial performance</h3>
          </div>

          <div className="period-tabs" role="tablist">
            {(
              [
                "today",
                "yesterday",
                "week",
                "month",
                "year",
                "custom",
              ] as Period[]
            ).map((item) => (
              <button
                key={item}
                type="button"
                className={period === item ? "filter-active" : ""}
                onClick={() => setPeriod(item)}
              >
                {item === "today"
                  ? "Today"
                  : item === "yesterday"
                    ? "Yesterday"
                    : item === "week"
                      ? "Week"
                      : item === "month"
                        ? "Month"
                        : item === "year"
                          ? "Year"
                          : "Custom"}
              </button>
            ))}
          </div>
        </div>

        {period === "custom" && (
          <div className="custom-range">
            <input
              type="date"
              value={customFrom}
              onChange={(event) => setCustomFrom(event.target.value)}
            />
            <span>to</span>
            <input
              type="date"
              value={customTo}
              onChange={(event) => setCustomTo(event.target.value)}
            />
          </div>
        )}

        {query.isLoading && <p>Loading financials...</p>}

        {query.isError && (
          <p className="form-error">
            Unable to load dashboard summary. Check that the backend is running
            and try again.
          </p>
        )}

        {summary && (
          <div className="finance-summary">
            <div className="finance-summary-card">
              <span>Revenue</span>
              <strong>{formatCurrency(summary.total_income)}</strong>
            </div>

            <div className="finance-summary-card">
              <span>Expenses</span>
              <strong>{formatCurrency(summary.total_expenses)}</strong>
            </div>

            <div className="finance-summary-card finance-profit">
              <span>Profit</span>
              <strong>{formatCurrency(summary.profit)}</strong>
            </div>
          </div>
        )}
      </section>

      <section className="panel events-panel dashboard-events-panel">
        <div className="panel-heading">
          <div>
            <span className="section-kicker">{label.toUpperCase()} EVENTS</span>
            <h3>Event activity</h3>
          </div>

          <Link to="/events">View all →</Link>
        </div>

        {summary?.events.length === 0 && (
          <div className="mini-empty">
            <strong>No events in this period</strong>
            <p>Your event activity will appear here.</p>
          </div>
        )}

        {summary?.events.map((event) => (
          <EventRow event={event} key={event.id} />
        ))}
      </section>

      {healthOpen && (
        <div
          className="health-modal-backdrop"
          role="presentation"
          onClick={() => setHealthOpen(false)}
        >
          <section
            className="health-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="system-status-title"
            onClick={(event) => event.stopPropagation()}
          >
            <div className="panel-heading">
              <div>
                <span className="section-kicker">SYSTEM</span>
                <h3 id="system-status-title">System status</h3>
              </div>

              <button
                className="icon-button"
                type="button"
                aria-label="Close system status"
                onClick={() => setHealthOpen(false)}
              >
                ×
              </button>
            </div>

            <div className="health-status-content">
              <div className="health-item">
                <span className="health-check">{healthError ? "!" : "✓"}</span>

                <div>
                  <strong>Backend API</strong>
                  <span>
                    {healthLoading
                      ? "Checking..."
                      : healthError
                        ? "Unavailable"
                        : `Operational · ${health?.status ?? "ok"}`}
                  </span>
                </div>
              </div>

              <div className="health-status-note">
                System status is checked from the live backend health endpoint.
              </div>
            </div>
          </section>
        </div>
      )}
    </div>
  );
}

export function NotFoundPage() {
  return (
    <div className="empty-page">
      <span className="section-kicker">404</span>
      <h2>Page not found</h2>
      <p>The page you're looking for doesn't exist.</p>
      <Link className="button-link" to="/">
        Return to overview
      </Link>
    </div>
  );
}
