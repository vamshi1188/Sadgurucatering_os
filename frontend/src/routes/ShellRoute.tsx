import { Outlet } from "react-router-dom";
import { AppShell } from "../components/layout/AppShell";

export function ShellRoute() {
  return (
    <AppShell>
      <Outlet />
    </AppShell>
  );
}
