export type Period = "today" | "yesterday" | "week" | "month" | "year" | "custom";

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
