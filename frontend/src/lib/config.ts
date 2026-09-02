interface AppConfig {
  apiBaseUrl: string;
}

const appConfig: AppConfig = {
  apiBaseUrl: "/api/v1",
};

export const config = Object.freeze(appConfig);
