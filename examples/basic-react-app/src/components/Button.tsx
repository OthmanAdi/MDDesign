import React from "react";
import { tokens } from "../theme";

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary";
};

// All values resolve to declared tokens in DESIGN.md.
// Inline hex would fail /mddesign:critique drift pass (P1).
export function Button({ variant = "primary", children, ...rest }: ButtonProps) {
  const bg = variant === "primary" ? tokens.colors.primary : tokens.colors.secondary;

  return (
    <button
      style={{
        backgroundColor: bg,
        color: tokens.colors["text-on-primary"],
        fontFamily: tokens.typography.button.fontFamily,
        fontSize: tokens.typography.button.fontSize,
        fontWeight: tokens.typography.button.fontWeight,
        lineHeight: tokens.typography.button.lineHeight,
        borderRadius: tokens.rounded.md,
        padding: `${tokens.spacing.sm} ${tokens.spacing.md}`,
        border: "none",
        cursor: "pointer",
      }}
      {...rest}
    >
      {children}
    </button>
  );
}
