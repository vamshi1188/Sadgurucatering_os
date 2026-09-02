import { apiClient } from "./client";

export interface FinanceEntry {
  id: number;
  event_id: number;
  description: string;
  amount: string;
  created_at: string;
}

export interface EventFinancials {
  event_id: number;
  total_income: string;
  total_expenses: string;
  profit: string;
  income: FinanceEntry[];
  expenses: FinanceEntry[];
}

interface ApiResponse<T> {
  data: T;
  meta?: Record<string, unknown>;
}

export interface FinanceEntryInput {
  description: string;
  amount: string;
}

export function getEventFinancials(eventId: number) {
  return apiClient.get<ApiResponse<EventFinancials>>(
    `/events/${eventId}/financials`,
  );
}

export function addEventIncome(
  eventId: number,
  input: FinanceEntryInput,
) {
  return apiClient.post<ApiResponse<FinanceEntry>>(
    `/events/${eventId}/income`,
    input,
  );
}

export function addEventExpense(
  eventId: number,
  input: FinanceEntryInput,
) {
  return apiClient.post<ApiResponse<FinanceEntry>>(
    `/events/${eventId}/expenses`,
    input,
  );
}
