import { describe, expect, it } from "vitest";
import { groupEventsByDate } from "./EventsPage";

const event = (id: number, event_date: string) => ({ id, event_date, title: `Event ${id}` } as never);

describe("groupEventsByDate", () => {
  it("keeps same-day events individually identifiable and isolates dates", () => {
    const groups = groupEventsByDate([event(1, "2026-09-05"), event(2, "2026-09-05"), event(3, "2026-09-06")]);
    expect(groups["2026-09-05"].map((item) => item.id)).toEqual([1, 2]);
    expect(groups["2026-09-06"].map((item) => item.id)).toEqual([3]);
  });
});