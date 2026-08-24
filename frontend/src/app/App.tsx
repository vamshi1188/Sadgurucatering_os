import { AppProviders } from "./providers";
import { AppRoutes } from "../routes/AppRoutes";

export function App() {
  return (
    <AppProviders>
      <AppRoutes />
    </AppProviders>
  );
}
