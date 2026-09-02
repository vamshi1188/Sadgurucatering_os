import { apiClient } from "./client";

export interface HealthResponse {
  status: string;
}

interface HealthApiResponse {
  data: HealthResponse;
}

export async function getHealth(): Promise<HealthResponse> {
  const response = await apiClient.get<HealthApiResponse>(
    "/health",
  );

  return response.data;
}
