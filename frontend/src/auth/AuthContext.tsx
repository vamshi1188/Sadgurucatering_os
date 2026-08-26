import {
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  getSession,
  login as loginRequest,
  logout as logoutRequest,
} from "../api/auth";
import { AuthContext, type AuthContextValue } from "./auth-context";

export function AuthProvider({ children }: { children: ReactNode }) {
  const [authenticated, setAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;

    getSession()
      .then((result) => {
        if (mounted) {
          setAuthenticated(result.authenticated);
        }
      })
      .catch(() => {
        if (mounted) {
          setAuthenticated(false);
        }
      })
      .finally(() => {
        if (mounted) {
          setLoading(false);
        }
      });

    return () => {
      mounted = false;
    };
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      authenticated,
      loading,

      async login(password: string) {
        await loginRequest(password);
        setAuthenticated(true);
      },

      async logout() {
        await logoutRequest();
        setAuthenticated(false);
      },
    }),
    [authenticated, loading],
  );

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}
