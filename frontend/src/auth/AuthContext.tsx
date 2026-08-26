import {
  createContext,
  useContext,
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

interface AuthContextValue {
  authenticated: boolean;
  loading: boolean;
  login: (password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

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

export function useAuth() {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error("useAuth must be used within AuthProvider");
  }

  return context;
}
