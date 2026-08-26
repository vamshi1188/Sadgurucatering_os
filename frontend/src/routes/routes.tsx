import type { RouteObject } from "react-router-dom";
import { DashboardPage, NotFoundPage } from "./pages";
import { LoginPage } from "../pages/LoginPage";
import { ProtectedRoute } from "./ProtectedRoute";

export const routes: RouteObject[] = [
  {
    path: "/login",
    element: <LoginPage />,
  },
  {
    element: <ProtectedRoute />,
    children: [
      {
        path: "/",
        element: <DashboardPage />,
      },
    ],
  },
  {
    path: "*",
    element: <NotFoundPage />,
  },
];
