import { useState } from "react";
import type { FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { ApiError } from "../api/client";
import { Button } from "../components/ui/Button";
import { Card } from "../components/ui/Card";
import { Input } from "../components/ui/Input";
import { useAuth } from "../auth/AuthContext";

export function LoginPage() {
  const navigate = useNavigate();
  const { login } = useAuth();

  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    setError("");
    setSubmitting(true);

    try {
      await login(password);
      navigate("/", { replace: true });
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        setError("Invalid password.");
      } else {
        setError("Unable to sign in. Please try again.");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="login-page">
      <Card>
        <div className="login-content">
          <h1>Sadguru Catering OS</h1>
          <p>Sign in to continue.</p>

          <form onSubmit={handleSubmit}>
            <label htmlFor="password">Password</label>

            <Input
              id="password"
              name="password"
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete="current-password"
              required
              disabled={submitting}
            />

            {error && (
              <p role="alert" className="login-error">
                {error}
              </p>
            )}

            <Button
              type="submit"
              disabled={submitting || password.length === 0}
            >
              {submitting ? "Signing in..." : "Sign in"}
            </Button>
          </form>
        </div>
      </Card>
    </main>
  );
}
