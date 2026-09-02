import { useQuery } from "@tanstack/react-query";
import { getEvents } from "../api/events";
import { Badge } from "../components/ui/Badge";
import { Card } from "../components/ui/Card";
import { Link } from "react-router-dom";

export function DashboardPage() {
  const query = useQuery({
    queryKey: ["events"],
    queryFn: getEvents,
  });

  const events = query.data?.data ?? [];
  const running = events.filter((e) => e.status === "running");
  const upcoming = events.filter((e) => e.status === "upcoming");
  const completed = events.filter((e) => e.status === "completed");

  return (
    <div className="dashboard-page">
      <section className="page-heading">
        <div>
          <span className="section-kicker">OVERVIEW</span>
          <h1>Good morning</h1>
          <p>Your catering operations at a glance.</p>
        </div>
        <Link className="button-link" to="/events">
          Manage events →
        </Link>
      </section>

      <section className="stats-grid">
        <Card className="stat-card">
          <span>UPCOMING</span>
          <strong>{upcoming.length}</strong>
          <small>Scheduled events</small>
        </Card>
        <Card className="stat-card stat-running">
          <span>RUNNING</span>
          <strong>{running.length}</strong>
          <small>Currently active</small>
        </Card>
        <Card className="stat-card stat-completed">
          <span>COMPLETED</span>
          <strong>{completed.length}</strong>
          <small>Finished events</small>
        </Card>
      </section>

      <section className="dashboard-grid">
        <Card className="dashboard-events">
          <div className="card-heading">
            <div>
              <span className="section-kicker">OPERATIONS</span>
              <h2>Active events</h2>
            </div>
            <Link to="/events">View all</Link>
          </div>

          {query.isLoading && <p>Loading events...</p>}

          {!query.isLoading && running.length === 0 && (
            <div className="mini-empty">
              <span>●</span>
              <div>
                <strong>No events running</strong>
                <p>Your active operations will appear here.</p>
              </div>
            </div>
          )}

          {running.map((event) => (
            <div className="dashboard-event" key={event.id}>
              <div>
                <strong>{event.title}</strong>
                <span>{event.venue} · {event.guest_count} guests</span>
              </div>
              <Badge tone="running">Running</Badge>
            </div>
          ))}
        </Card>

        <Card className="system-card">
          <span className="section-kicker">SYSTEM</span>
          <h2>System status</h2>
          <div className="system-status">
            <span className="status-live" />
            <strong>Operational</strong>
          </div>
          <p>Sadguru OS services are ready for operations.</p>
        </Card>
      </section>
    </div>
  );
}

export function NotFoundPage() {
  return (
    <div className="state-panel">
      <div className="empty-icon">404</div>
      <strong>Page not found</strong>
      <p>The page you're looking for doesn't exist.</p>
      <Link className="button-link" to="/">
        Return to overview
      </Link>
    </div>
  );
}
