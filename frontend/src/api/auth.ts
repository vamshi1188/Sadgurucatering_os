import { apiClient } from "./client";

export interface AuthResponse {
  authenticated: boolean;
}

export function login(password: string) {
  return apiClient.post<AuthResponse>("/auth/login", { password });
}

export function getSession() {
  return apiClient.get<AuthResponse>("/auth/session");
}

export function logout() {
  return apiClient.post<AuthResponse>("/auth/logout", {});
}
