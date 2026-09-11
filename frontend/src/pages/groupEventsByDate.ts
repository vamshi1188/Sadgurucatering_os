import type { CateringEvent } from "../api/events";

export function groupEventsByDate(events: CateringEvent[]) {
  return events.reduce<Record<string, CateringEvent[]>>((groups, event) => {
    groups[event.event_date] ??= [];
    groups[event.event_date].push(event);
    return groups;
  }, {});
}
