import { apiClient } from "./client";

export interface DashboardEvent {
  id: number;
  title: string;
  event_date: string;
  venue: string;
  guest_count: number;
  status: "upcoming" | "running" | "completed";
  total_income: string;
  total_expenses: string;
  profit: string;
}

export interface DashboardSummary {
  from: string;
  to: string;
  event_count: number;
  upcoming_count: number;
  running_count: number;
  completed_count: number;
  total_income: string;
  total_expenses: string;
  profit: string;
  events: DashboardEvent[];
}

interface ApiResponse<T> {
  data: T;
}

export interface DashboardDateRange {
  from: string;
  to: string;
}

export function getDashboardSummary({ from, to }: DashboardDateRange) {
  const params = new URLSearchParams({ from, to });
  return apiClient.get<ApiResponse<DashboardSummary>>(
    `/dashboard/summary?${params.toString()}`,
  );
}
