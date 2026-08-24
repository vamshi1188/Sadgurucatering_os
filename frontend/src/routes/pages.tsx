import { useHealthCheck } from "../hooks/useHealthCheck";

export function DashboardPage() {
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

export function NotFoundPage() {
  return <div>Sadguru Catering OS — Page Not Found</div>;
}
