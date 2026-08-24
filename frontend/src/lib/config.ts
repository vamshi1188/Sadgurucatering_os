interface AppConfig {
  apiBaseUrl: string;
}

function readConfig(): AppConfig {
  const apiBaseUrl = import.meta.env.VITE_API_BASE_URL;

  if (!apiBaseUrl) {
    throw new Error(
      "Missing required environment variable: VITE_API_BASE_URL",
    );
  }

  return Object.freeze({ apiBaseUrl });
}

export const config = readConfig();
