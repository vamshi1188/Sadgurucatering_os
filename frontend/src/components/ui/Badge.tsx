import type { ReactNode } from "react";

interface BadgeProps {
  children: ReactNode;
  tone?: "upcoming" | "running" | "completed" | "neutral";
}

export function Badge({
  children,
  tone = "neutral",
}: BadgeProps) {
  return (
    <span className={`ui-badge ui-badge-${tone}`}>
      <span className="ui-badge-dot" />
      {children}
    </span>
  );
}
