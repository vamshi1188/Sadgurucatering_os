import {
  createBrowserRouter,
  RouterProvider,
  type RouteObject,
} from "react-router-dom";
import { useHealthCheck } from "../hooks/useHealthCheck";

function DashboardPage() {
  const { data, isLoading, isError } = useHealthCheck();

  return (
    <main>
      <h1>Sadguru Catering OS</h1>

      <section aria-label="Backend health">
        <h2>Backend Health</h2>

        {isLoading && <p>Checking backend...</p>}

        {isError && <p>Backend unavailable</p>}

        {data && <p>Backend status: {data.status}</p>}
      </section>
    </main>
  );
}

function NotFoundPage() {
  return <div>Sadguru Catering OS — Page Not Found</div>;
}

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

const router = createBrowserRouter(routes);

export function AppRoutes() {
  return <RouterProvider router={router} />;
}
