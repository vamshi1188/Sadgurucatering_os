import { apiClient } from "./client";

export type EventStatus = "upcoming" | "running" | "completed";

export interface CateringEvent {
  id: number;
  title: string;
  event_date: string;
  venue: string;
  guest_count: number;
  status: EventStatus;
  created_at: string;
  updated_at: string;
}

export interface CreateEventInput {
  title: string;
  event_date: string;
  venue: string;
  guest_count: number;
}

interface ApiResponse<T> {
  data: T;
  meta?: Record<string, unknown>;
}

export function getEvents() {
  return apiClient.get<ApiResponse<CateringEvent[]>>(
    "/api/v1/events",
  );
}

export function createEvent(input: CreateEventInput) {
  return apiClient.post<ApiResponse<CateringEvent>>(
    "/api/v1/events",
    input,
  );
}

export function updateEventStatus(
  id: number,
  status: EventStatus,
) {
  return apiClient.patch<ApiResponse<CateringEvent>>(
    `/api/v1/events/${id}/status`,
    { status },
  );
}
