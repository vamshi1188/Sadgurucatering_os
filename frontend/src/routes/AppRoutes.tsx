import {
  createBrowserRouter,
  RouterProvider,
  type RouteObject,
} from "react-router-dom";

function HomePlaceholder() {
  return <div>Sadguru Catering OS — Home</div>;
}

function NotFoundPlaceholder() {
  return <div>Sadguru Catering OS — Page Not Found</div>;
}

export const routes: RouteObject[] = [
  {
    path: "/",
    element: <HomePlaceholder />,
  },
  {
    path: "*",
    element: <NotFoundPlaceholder />,
  },
];

const router = createBrowserRouter(routes);

export function AppRoutes() {
  return <RouterProvider router={router} />;
}
