import { apiClient } from "./client";

export interface AuthResponse {
  authenticated: boolean;
}

export function login(password: string) {
  return apiClient.post<AuthResponse>("/api/v1/auth/login", { password });
}

export function getSession() {
  return apiClient.get<AuthResponse>("/api/v1/auth/session");
}

export function logout() {
  return apiClient.post<AuthResponse>("/api/v1/auth/logout", {});
}
