import { colors, radius, spacing } from './tokens';

export const theme = {
  colors,
  spacing,
  radius,
} as const;

export type Theme = typeof theme;
