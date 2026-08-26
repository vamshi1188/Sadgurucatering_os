import { config } from "../lib/config";

export class ApiError extends Error {
  readonly status: number;

  constructor(status: number, message: string) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

async function request<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const response = await fetch(`${config.apiBaseUrl}${path}`, {
    ...options,
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
  });

  if (!response.ok) {
    throw new ApiError(
      response.status,
      `API request failed with status ${response.status}`,
    );
  }

  return (await response.json()) as T;
}

export const apiClient = {
  get<T>(path: string) {
    return request<T>(path);
  },

  post<T>(path: string, body: unknown) {
    return request<T>(path, {
      method: "POST",
      body: JSON.stringify(body),
    });
  },
};
