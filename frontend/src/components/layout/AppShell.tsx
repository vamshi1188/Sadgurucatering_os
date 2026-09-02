import type { ReactNode } from "react";
import { NavLink } from "react-router-dom";
import { useAuth } from "../../auth/useAuth";

interface AppShellProps {
  children: ReactNode;
}

const navItems = [
  { label: "Overview", path: "/" },
  { label: "Events", path: "/events" },
];

export function AppShell({ children }: AppShellProps) {
  const { logout } = useAuth();

  return (
    <div className="app-shell">
      <aside className="app-sidebar">
        <div className="brand">
          <div className="brand-mark">S</div>
          <div className="brand-copy">
            <strong>Sadguru</strong>
            <span>Catering OS</span>
          </div>
        </div>

        <nav className="sidebar-nav" aria-label="Main navigation">
          <div className="sidebar-section-label">Workspace</div>

          {navItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `sidebar-link ${isActive ? "active" : ""}`
              }
            >
              <span className="sidebar-icon">
                {item.label === "Overview" ? "⌂" : "◫"}
              </span>
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-bottom">
          <div className="sidebar-status">
            <span className="status-dot" />
            <span>
              <strong>System online</strong>
              <small>All services operational</small>
            </span>
          </div>

          <button
            className="sidebar-logout"
            onClick={() => {
              void logout();
            }}
          >
            <span>↪</span>
            Sign out
          </button>
        </div>
      </aside>

      <div className="app-main">
        <header className="topbar">
          <div>
            <span className="topbar-eyebrow">SADGURU CATERING</span>
            <h1>Operations workspace</h1>
          </div>

          <div className="topbar-actions">
            <button className="icon-button" aria-label="Notifications">
              ♢
            </button>

            <div className="user-profile">
              <div className="avatar">V</div>
              <div className="user-copy">
                <strong>Administrator</strong>
                <span>Owner</span>
              </div>
            </div>
          </div>
        </header>

        <main className="app-content">{children}</main>
      </div>
    </div>
  );
}
