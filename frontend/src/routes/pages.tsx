import { useAuth } from "../auth/useAuth";
import { useHealthCheck } from "../hooks/useHealthCheck";
import { Button } from "../components/ui/Button";

export function DashboardPage() {
  const { data, isLoading, isError } = useHealthCheck();
  const { logout } = useAuth();

  return (
    <main>
      <header>
        <h1>Sadguru Catering OS</h1>

        <Button
          variant="secondary"
          onClick={() => {
            void logout();
          }}
        >
          Logout
        </Button>
      </header>

      <section aria-label="Backend health">
        <h2>Backend Health</h2>

        {isLoading && <p>Checking backend...</p>}

        {isError && <p>Backend unavailable</p>}

        {data && <p>Backend status: {data.status}</p>}
      </section>
    </main>
  );
}

export function NotFoundPage() {
  return <div>Sadguru Catering OS — Page Not Found</div>;
}
