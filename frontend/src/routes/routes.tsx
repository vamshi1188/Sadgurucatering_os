import type { RouteObject } from "react-router-dom";
import { Outlet } from "react-router-dom";
import { DashboardPage, NotFoundPage } from "./pages";
import { LoginPage } from "../pages/LoginPage";
import { EventsPage } from "../pages/EventsPage";
import { ProtectedRoute } from "./ProtectedRoute";
import { AppShell } from "../components/layout/AppShell";

function ShellRoute() {
  return (
    <AppShell>
      <Outlet />
    </AppShell>
  );
}

export const routes: RouteObject[] = [
  {
    path: "/login",
    element: <LoginPage />,
  },
  {
    element: <ProtectedRoute />,
    children: [
      {
        element: <ShellRoute />,
        children: [
          {
            path: "/",
            element: <DashboardPage />,
          },
          {
            path: "/events",
            element: <EventsPage />,
          },
        ],
      },
    ],
  },
  {
    path: "*",
    element: <NotFoundPage />,
  },
];
