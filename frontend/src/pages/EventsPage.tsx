import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useSearchParams } from "react-router-dom";
import {
  createEvent,
  getEvents,
  updateEventStatus,
  type CateringEvent,
  type EventStatus,
} from "../api/events";
import {
  addEventExpense,
  addEventIncome,
  getEventFinancials,
  type EventFinancials,
} from "../api/finance";
import { Badge } from "../components/ui/Badge";
import { Button } from "../components/ui/Button";
import { Card } from "../components/ui/Card";
import { Input } from "../components/ui/Input";

type Filter = "all" | EventStatus;
type FinanceEntryType = "income" | "expense";

export function groupEventsByDate(events: CateringEvent[]) {
  return events.reduce<Record<string, CateringEvent[]>>((groups, event) => {
    groups[event.event_date] ??= [];
    groups[event.event_date].push(event);
    return groups;
  }, {});
}

function localDateKey(date = new Date()) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function formatDate(value: string) {
  const date = new Date(value);
  return {
    month: date.toLocaleDateString("en-IN", { month: "short" }).toUpperCase(),
    day: date.toLocaleDateString("en-IN", { day: "2-digit" }),
  };
}

function formatCurrency(value: string) {
  const amount = Number(value);

  if (!Number.isFinite(amount)) {
    return "₹0.00";
  }

  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 2,
  }).format(amount);
}

function FinancePanel({
  event,
  financials,
  loading,
  error,
  entryType,
  onEntryTypeChange,
  onSubmit,
  pending,
  mutationError,
}: {
  event: CateringEvent;
  financials?: EventFinancials;
  loading: boolean;
  error: boolean;
  entryType: FinanceEntryType | null;
  onEntryTypeChange: (type: FinanceEntryType | null) => void;
  onSubmit: (
    type: FinanceEntryType,
    description: string,
    amount: string,
  ) => void;
  pending: boolean;
  mutationError: unknown;
}) {
  const [description, setDescription] = useState("");
  const [amount, setAmount] = useState("");

  function submitEntry(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();

    if (!entryType) {
      return;
    }

    onSubmit(entryType, description.trim(), amount);
    setDescription("");
    setAmount("");
  }

  return (
    <div className="finance-panel">
      <div className="finance-header">
        <div>
          <span className="section-kicker">EVENT FINANCE</span>
          <h4>{event.title}</h4>
        </div>
      </div>

      {loading && (
        <div className="finance-state">
          <span className="loading-pulse" />
          <span>Loading financials...</span>
        </div>
      )}

      {error && (
        <div className="finance-state finance-error">
          <strong>Unable to load financials.</strong>
          <span>Check that the backend is running and try again.</span>
        </div>
      )}

      {!loading && !error && financials && (
        <>
          <div className="finance-summary">
            <div className="finance-summary-card">
              <span>Total income</span>
              <strong>{formatCurrency(financials.total_income)}</strong>
            </div>

            <div className="finance-summary-card">
              <span>Total expenses</span>
              <strong>{formatCurrency(financials.total_expenses)}</strong>
            </div>

            <div className="finance-summary-card finance-profit">
              <span>Profit</span>
              <strong>{formatCurrency(financials.profit)}</strong>
            </div>
          </div>

          <div className="finance-columns">
            <div className="finance-entry-section">
              <div className="finance-section-heading">
                <h5>Income</h5>
                <button
                  className="finance-add-link"
                  type="button"
                  onClick={() => onEntryTypeChange("income")}
                >
                  + Add income
                </button>
              </div>

              {financials.income.length === 0 ? (
                <p className="finance-empty">No income entries yet.</p>
              ) : (
                <div className="finance-entry-list">
                  {financials.income.map((entry) => (
                    <div className="finance-entry" key={entry.id}>
                      <span>{entry.description}</span>
                      <strong>{formatCurrency(entry.amount)}</strong>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="finance-entry-section">
              <div className="finance-section-heading">
                <h5>Expenses</h5>
                <button
                  className="finance-add-link"
                  type="button"
                  onClick={() => onEntryTypeChange("expense")}
                >
                  + Add expense
                </button>
              </div>

              {financials.expenses.length === 0 ? (
                <p className="finance-empty">No expense entries yet.</p>
              ) : (
                <div className="finance-entry-list">
                  {financials.expenses.map((entry) => (
                    <div className="finance-entry" key={entry.id}>
                      <span>{entry.description}</span>
                      <strong>{formatCurrency(entry.amount)}</strong>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {entryType && (
            <form className="finance-form" onSubmit={submitEntry}>
              <div className="finance-form-heading">
                <strong>
                  Add {entryType === "income" ? "income" : "expense"}
                </strong>
                <button
                  type="button"
                  className="finance-form-close"
                  onClick={() => onEntryTypeChange(null)}
                  aria-label="Close finance form"
                >
                  ×
                </button>
              </div>

              <label>
                Description
                <Input
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder={
                    entryType === "income"
                      ? "Catering advance"
                      : "Food supplies"
                  }
                  required
                />
              </label>

              <label>
                Amount
                <Input
                  type="number"
                  min="0.01"
                  step="0.01"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="50000.00"
                  required
                />
              </label>

              {mutationError !== null && mutationError !== undefined && (
                <p className="form-error">
                  {mutationError instanceof Error
                    ? mutationError.message
                    : "Unable to save financial entry"}
                </p>
              )}

              <div className="finance-form-actions">
                <Button
                  variant="secondary"
                  type="button"
                  onClick={() => onEntryTypeChange(null)}
                >
                  Cancel
                </Button>
                <Button disabled={pending}>
                  {pending ? "Saving..." : "Save entry"}
                </Button>
              </div>
            </form>
          )}
        </>
      )}
    </div>
  );
}

function EventCard({
  event,
  onStatusChange,
  pending,
  expanded,
  onToggleFinance,
}: {
  event: CateringEvent;
  onStatusChange: (event: CateringEvent) => void;
  pending: boolean;
  expanded: boolean;
  onToggleFinance: (event: CateringEvent) => void;
}) {
  const date = formatDate(event.event_date);

  const financialsQuery = useQuery({
    queryKey: ["event-financials", event.id],
    queryFn: () => getEventFinancials(event.id),
    enabled: expanded,
  });

  const queryClient = useQueryClient();
  const [entryType, setEntryType] = useState<FinanceEntryType | null>(null);

  const incomeMutation = useMutation({
    mutationFn: ({
      description,
      amount,
    }: {
      description: string;
      amount: string;
    }) => addEventIncome(event.id, { description, amount }),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: ["event-financials", event.id],
      });
      void queryClient.invalidateQueries({
        queryKey: ["dashboard-summary"],
      });
      setEntryType(null);
    },
  });

  const expenseMutation = useMutation({
    mutationFn: ({
      description,
      amount,
    }: {
      description: string;
      amount: string;
    }) => addEventExpense(event.id, { description, amount }),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: ["event-financials", event.id],
      });
      void queryClient.invalidateQueries({
        queryKey: ["dashboard-summary"],
      });
      setEntryType(null);
    },
  });

  function submitFinanceEntry(
    type: FinanceEntryType,
    description: string,
    amount: string,
  ) {
    if (type === "income") {
      incomeMutation.mutate({ description, amount });
    } else {
      expenseMutation.mutate({ description, amount });
    }
  }

  const financePending =
    incomeMutation.isPending || expenseMutation.isPending;

  const financeError = incomeMutation.error ?? expenseMutation.error;

  return (
    <Card className="event-card">
      <div className="event-card-date">
        <span>{date.month}</span>
        <strong>{date.day}</strong>
      </div>

      <div className="event-card-body">
        <div className="event-card-heading">
          <div>
            <h3>{event.title}</h3>
            <p>{event.venue}</p>
          </div>
          <Badge tone={event.status}>{event.status}</Badge>
        </div>

        <div className="event-card-footer">
          <span className="guest-count">
            <strong>{event.guest_count.toLocaleString("en-IN")}</strong>{" "}
            guests
          </span>

          <div className="event-actions">
            <Button
              variant="secondary"
              onClick={() => onToggleFinance(event)}
              aria-expanded={expanded}
            >
              {expanded ? "Hide finances" : "View finances"}
            </Button>

            {event.status !== "completed" && (
              <Button
                variant={
                  event.status === "running" ? "secondary" : "primary"
                }
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

        {expanded && (
          <FinancePanel
            event={event}
            financials={financialsQuery.data?.data}
            loading={financialsQuery.isLoading}
            error={financialsQuery.isError}
            entryType={entryType}
            onEntryTypeChange={setEntryType}
            onSubmit={submitFinanceEntry}
            pending={financePending}
            mutationError={financeError}
          />
        )}
      </div>
    </Card>
  );
}

export function EventsPage() {
  const [searchParams] = useSearchParams();
  const queryClient = useQueryClient();
  const [filter, setFilter] = useState<Filter>("all");
  const [showCreate, setShowCreate] = useState(false);
  const [expandedEventId, setExpandedEventId] = useState<number | null>(() => {
    const eventId = Number(searchParams.get("event"));
    return Number.isInteger(eventId) && eventId > 0 ? eventId : null;
  });
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
      void queryClient.invalidateQueries({
        queryKey: ["dashboard-summary"],
      });
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
      void queryClient.invalidateQueries({
        queryKey: ["dashboard-summary"],
      });
    },
  });

  const events = useMemo(() => eventsQuery.data?.data ?? [], [eventsQuery.data]);

  const counts = useMemo(
    () => ({
      upcoming: events.filter((e) => e.status === "upcoming").length,
      running: events.filter((e) => e.status === "running").length,
      completed: events.filter((e) => e.status === "completed").length,
    }),
    [events],
  );

  const filtered = useMemo(
    () =>
      filter === "all"
        ? events
        : events.filter((event) => event.status === filter),
    [filter, events],
  );

  const groupedEvents = useMemo(() => groupEventsByDate(filtered), [filtered]);
  const today = localDateKey();
  const todayEvents = filtered.filter((event) => event.event_date === today);
  const futureDates = Object.keys(groupedEvents).filter((date) => date > today).sort();

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

  function toggleFinance(event: CateringEvent) {
    setExpandedEventId((current) =>
      current === event.id ? null : event.id,
    );
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

      <div className="event-day-groups">
        {todayEvents.length > 0 && (
          <section className="event-day-group">
            <div className="event-day-heading"><span className="section-kicker">TODAY</span><strong>{todayEvents.length} events</strong></div>
            {(["upcoming", "running", "completed"] as EventStatus[]).map((status) => {
              const events = todayEvents.filter((event) => event.status === status);
              return events.length > 0 ? <div className="event-status-group" key={status}><h3>{status}</h3>{events.map((event) => <EventCard key={event.id} event={event} pending={statusMutation.isPending && statusMutation.variables?.id === event.id} onStatusChange={changeStatus} expanded={expandedEventId === event.id} onToggleFinance={toggleFinance} />)}</div> : null;
            })}
          </section>
        )}
        {futureDates.length > 0 && <section className="event-day-group"><div className="event-day-heading"><span className="section-kicker">UPCOMING</span><strong>Future events</strong></div>{futureDates.map((date) => <div className="event-status-group" key={date}><h3>{formatDate(date).month} {formatDate(date).day}</h3>{groupedEvents[date].map((event) => <EventCard key={event.id} event={event} pending={statusMutation.isPending && statusMutation.variables?.id === event.id} onStatusChange={changeStatus} expanded={expandedEventId === event.id} onToggleFinance={toggleFinance} />)}</div>)}</section>}
        {filtered.length > 0 && todayEvents.length === 0 && futureDates.length === 0 && <section className="event-day-group"><div className="event-day-heading"><span className="section-kicker">COMPLETED HISTORY</span><strong>Past events</strong></div>{filtered.map((event) => <EventCard key={event.id} event={event} pending={statusMutation.isPending && statusMutation.variables?.id === event.id} onStatusChange={changeStatus} expanded={expandedEventId === event.id} onToggleFinance={toggleFinance} />)}</section>}
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
