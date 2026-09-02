import { useHealthCheck } from "../hooks/useHealthCheck";
import { AppShell } from "../components/layout/AppShell";

const events = [
  {
    title: "Wedding Reception",
    venue: "Sadguru Function Hall",
    date: "30 Aug 2026",
    guests: 500,
    status: "completed",
  },
  {
    title: "Birthday Celebration",
    venue: "Sri Convention Center",
    date: "30 Aug 2026",
    guests: 150,
    status: "upcoming",
  },
];

function StatusBadge({ status }: { status: string }) {
  return (
    <span className={`status-badge status-${status}`}>
      <span />
      {status}
    </span>
  );
}

export function DashboardPage() {
  const { data, isLoading, isError } = useHealthCheck();

  return (
    <>
      <section className="page-heading">
        <div>
          <span className="section-kicker">GOOD EVENING</span>
          <h2>Welcome back, Vamshi.</h2>
          <p>Here is what is happening across your catering operations.</p>
        </div>

        <button className="primary-action">
          <span>+</span>
          New event
        </button>
      </section>

      <section className="stats-grid" aria-label="Business overview">
        <article className="stat-card stat-featured">
          <div className="stat-top">
            <span className="stat-label">TOTAL EVENTS</span>
            <span className="stat-icon">◫</span>
          </div>
          <strong className="stat-value">24</strong>
          <span className="stat-foot positive">↑ 12% <em>vs last month</em></span>
        </article>

        <article className="stat-card">
          <div className="stat-top">
            <span className="stat-label">UPCOMING</span>
            <span className="stat-icon soft-gold">◷</span>
          </div>
          <strong className="stat-value">8</strong>
          <span className="stat-foot">Next 30 days</span>
        </article>

        <article className="stat-card">
          <div className="stat-top">
            <span className="stat-label">RUNNING TODAY</span>
            <span className="stat-icon soft-green">●</span>
          </div>
          <strong className="stat-value">2</strong>
          <span className="stat-foot positive">Currently active</span>
        </article>

        <article className="stat-card">
          <div className="stat-top">
            <span className="stat-label">GUESTS SERVED</span>
            <span className="stat-icon soft-blue">♧</span>
          </div>
          <strong className="stat-value">4,850</strong>
          <span className="stat-foot positive">↑ 8.4% <em>this month</em></span>
        </article>
      </section>

      <section className="dashboard-grid">
        <div className="panel events-panel">
          <div className="panel-heading">
            <div>
              <span className="section-kicker">EVENT OPERATIONS</span>
              <h3>Recent events</h3>
            </div>

            <button className="text-action">View all →</button>
          </div>

          <div className="event-list">
            {events.map((event) => (
              <article className="event-row" key={event.title}>
                <div className="event-date">
                  <strong>{event.date.split(" ")[0]}</strong>
                  <span>{event.date.split(" ")[1]}</span>
                </div>

                <div className="event-main">
                  <strong>{event.title}</strong>
                  <span>{event.venue}</span>
                </div>

                <div className="event-guests">
                  <strong>{event.guests}</strong>
                  <span>guests</span>
                </div>

                <StatusBadge status={event.status} />

                <button className="row-menu" aria-label="Event options">
                  ⋮
                </button>
              </article>
            ))}
          </div>
        </div>

        <div className="panel health-panel">
          <div className="panel-heading">
            <div>
              <span className="section-kicker">SYSTEM</span>
              <h3>System health</h3>
            </div>
            <span className="health-live">LIVE</span>
          </div>

          <div className="health-visual">
            <div className="health-ring">
              <strong>100%</strong>
              <span>healthy</span>
            </div>
          </div>

          <div className="health-item">
            <span className="health-check">✓</span>
            <div>
              <strong>Backend API</strong>
              <span>
                {isLoading
                  ? "Checking..."
                  : isError
                    ? "Unavailable"
                    : `Operational · ${data?.status ?? "ok"}`}
              </span>
            </div>
          </div>

          <div className="health-item">
            <span className="health-check">✓</span>
            <div>
              <strong>Database</strong>
              <span>PostgreSQL operational</span>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}

export function NotFoundPage() {
  return (
    <AppShell>
      <div className="empty-page">
        <span className="section-kicker">404</span>
        <h2>Page not found</h2>
        <p>The page you're looking for doesn't exist.</p>
      </div>
    </AppShell>
  );
}
