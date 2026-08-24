import { useQuery } from "@tanstack/react-query";
import { getHealth } from "../api/health";

export function useHealthCheck() {
  return useQuery({
    queryKey: ["health"],
    queryFn: getHealth,
  });
}
