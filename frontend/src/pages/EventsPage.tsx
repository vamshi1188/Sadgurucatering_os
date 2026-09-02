import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  createEvent,
  getEvents,
  updateEventStatus,
  type CateringEvent,
  type EventStatus,
} from "../api/events";
import { Badge } from "../components/ui/Badge";
import { Button } from "../components/ui/Button";
import { Card } from "../components/ui/Card";
import { Input } from "../components/ui/Input";

type Filter = "all" | EventStatus;

function formatDate(value: string) {
  const date = new Date(value);
  return {
    month: date.toLocaleDateString("en-IN", { month: "short" }).toUpperCase(),
    day: date.toLocaleDateString("en-IN", { day: "2-digit" }),
  };
}

function EventCard({
  event,
  onStatusChange,
  pending,
}: {
  event: CateringEvent;
  onStatusChange: (event: CateringEvent) => void;
  pending: boolean;
}) {
  const date = formatDate(event.event_date);

  return (
    <Card className="event-card">
      <div className="event-date">
        <span>{date.month}</span>
        <strong>{date.day}</strong>
      </div>

      <div className="event-main">
        <div className="event-heading">
          <div>
            <h3>{event.title}</h3>
            <p>{event.venue}</p>
          </div>
          <Badge tone={event.status}>
            {event.status}
          </Badge>
        </div>

        <div className="event-footer">
          <span className="guest-count">
            <strong>{event.guest_count.toLocaleString("en-IN")}</strong>{" "}
            guests
          </span>

          {event.status !== "completed" && (
            <Button
              variant={event.status === "running" ? "secondary" : "primary"}
              disabled={pending}
              onClick={() => onStatusChange(event)}
            >
              {pending
                ? "Updating..."
                : event.status === "upcoming"
                  ? "Start event"
                  : "Complete event"}
              <span>→</span>
            </Button>
          )}
        </div>
      </div>
    </Card>
  );
}

export function EventsPage() {
  const queryClient = useQueryClient();
  const [filter, setFilter] = useState<Filter>("all");
  const [showCreate, setShowCreate] = useState(false);
  const [title, setTitle] = useState("");
  const [eventDate, setEventDate] = useState("");
  const [venue, setVenue] = useState("");
  const [guestCount, setGuestCount] = useState("");

  const eventsQuery = useQuery({
    queryKey: ["events"],
    queryFn: getEvents,
  });

  const createMutation = useMutation({
    mutationFn: createEvent,
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["events"] });
      setShowCreate(false);
      setTitle("");
      setEventDate("");
      setVenue("");
      setGuestCount("");
    },
  });

  const statusMutation = useMutation({
    mutationFn: ({
      id,
      status,
    }: {
      id: number;
      status: EventStatus;
    }) => updateEventStatus(id, status),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ["events"] });
    },
  });

  const events = eventsQuery.data?.data ?? [];

  const counts = useMemo(
    () => ({
      upcoming: events.filter((e) => e.status === "upcoming").length,
      running: events.filter((e) => e.status === "running").length,
      completed: events.filter((e) => e.status === "completed").length,
    }),
    [events],
  );

  const filtered =
    filter === "all"
      ? events
      : events.filter((event) => event.status === filter);

  function changeStatus(event: CateringEvent) {
    const nextStatus =
      event.status === "upcoming" ? "running" : "completed";

    statusMutation.mutate({
      id: event.id,
      status: nextStatus,
    });
  }

  function submitCreate(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    createMutation.mutate({
      title: title.trim(),
      event_date: eventDate,
      venue: venue.trim(),
      guest_count: Number(guestCount),
    });
  }

  return (
    <div className="events-page">
      <section className="page-heading">
        <div>
          <span className="section-kicker">EVENT MANAGEMENT</span>
          <h1>Events</h1>
          <p>Plan, track and complete your catering operations.</p>
        </div>

        <Button onClick={() => setShowCreate(true)}>
          <span className="button-plus">+</span>
          New event
        </Button>
      </section>

      <section className="stats-grid" aria-label="Event statistics">
        <Card className="stat-card">
          <span>UPCOMING</span>
          <strong>{counts.upcoming}</strong>
          <small>Scheduled events</small>
        </Card>
        <Card className="stat-card stat-running">
          <span>RUNNING</span>
          <strong>{counts.running}</strong>
          <small>Currently active</small>
        </Card>
        <Card className="stat-card stat-completed">
          <span>COMPLETED</span>
          <strong>{counts.completed}</strong>
          <small>Finished events</small>
        </Card>
      </section>

      <section className="events-toolbar">
        <div className="filter-tabs" role="tablist" aria-label="Event filters">
          {(["all", "upcoming", "running", "completed"] as Filter[]).map(
            (item) => (
              <button
                key={item}
                className={filter === item ? "filter-active" : ""}
                onClick={() => setFilter(item)}
              >
                {item === "all" ? "All events" : item}
              </button>
            ),
          )}
        </div>
        <span className="event-total">{filtered.length} events</span>
      </section>

      {eventsQuery.isLoading && (
        <div className="state-panel">
          <div className="loading-pulse" />
          <p>Loading events...</p>
        </div>
      )}

      {eventsQuery.isError && (
        <div className="state-panel state-error">
          <strong>Unable to load events</strong>
          <p>Check that the backend is running and try again.</p>
          <Button
            variant="secondary"
            onClick={() => void eventsQuery.refetch()}
          >
            Try again
          </Button>
        </div>
      )}

      {!eventsQuery.isLoading &&
        !eventsQuery.isError &&
        filtered.length === 0 && (
          <div className="state-panel">
            <div className="empty-icon">◫</div>
            <strong>No {filter === "all" ? "" : filter} events</strong>
            <p>Create an event to start managing your operations.</p>
            <Button onClick={() => setShowCreate(true)}>
              Create event
            </Button>
          </div>
        )}

      <div className="event-list">
        {filtered.map((event) => (
          <EventCard
            key={event.id}
            event={event}
            pending={
              statusMutation.isPending &&
              statusMutation.variables?.id === event.id
            }
            onStatusChange={changeStatus}
          />
        ))}
      </div>

      {showCreate && (
        <div
          className="modal-backdrop"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) {
              setShowCreate(false);
            }
          }}
        >
          <section
            className="modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="create-event-title"
          >
            <div className="modal-header">
              <div>
                <span className="section-kicker">NEW OPERATION</span>
                <h2 id="create-event-title">Create event</h2>
              </div>
              <button
                className="modal-close"
                onClick={() => setShowCreate(false)}
                aria-label="Close"
              >
                ×
              </button>
            </div>

            <form onSubmit={submitCreate}>
              <label>
                Event name
                <Input
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Wedding Reception"
                  required
                />
              </label>

              <label>
                Event date
                <Input
                  type="date"
                  value={eventDate}
                  onChange={(e) => setEventDate(e.target.value)}
                  required
                />
              </label>

              <label>
                Venue
                <Input
                  value={venue}
                  onChange={(e) => setVenue(e.target.value)}
                  placeholder="Sadguru Function Hall"
                  required
                />
              </label>

              <label>
                Guest count
                <Input
                  type="number"
                  min="0"
                  value={guestCount}
                  onChange={(e) => setGuestCount(e.target.value)}
                  placeholder="500"
                  required
                />
              </label>

              {createMutation.isError && (
                <p className="form-error">
                  {createMutation.error instanceof Error
                    ? createMutation.error.message
                    : "Unable to create event"}
                </p>
              )}

              <div className="modal-actions">
                <Button
                  variant="secondary"
                  type="button"
                  onClick={() => setShowCreate(false)}
                >
                  Cancel
                </Button>
                <Button disabled={createMutation.isPending}>
                  {createMutation.isPending
                    ? "Creating..."
                    : "Create event"}
                </Button>
              </div>
            </form>
          </section>
        </div>
      )}
    </div>
  );
}
