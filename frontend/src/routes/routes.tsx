import type { RouteObject } from "react-router-dom";
import { DashboardPage, NotFoundPage } from "./pages";

export const routes: RouteObject[] = [
  {
    path: "/",
    element: <DashboardPage />,
  },
  {
    path: "*",
    element: <NotFoundPage />,
  },
];
