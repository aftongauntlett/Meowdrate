import * as React from 'react';
import {
  Pressable,
  StyleSheet,
  Text,
  type PressableProps,
  type StyleProp,
  type ViewStyle,
} from 'react-native';

import { theme } from '../theme';

type ButtonVariant = 'primary' | 'ghost';

type Props = {
  label: string;
  variant?: ButtonVariant;
  containerStyle?: StyleProp<ViewStyle>;
} & Omit<PressableProps, 'children'>;

export function Button({ label, variant = 'primary', containerStyle, disabled, ...rest }: Props) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: Boolean(disabled) }}
      disabled={disabled}
      style={({ pressed }) => [
        styles.base,
        variant === 'primary' ? styles.primary : styles.ghost,
        pressed &&
          !disabled &&
          (variant === 'primary' ? styles.primaryPressed : styles.ghostPressed),
        disabled && styles.disabled,
        containerStyle,
      ]}
      {...rest}
    >
      <Text style={[styles.label, variant === 'ghost' && styles.labelGhost]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 48,
    paddingHorizontal: theme.spacing.lg,
    borderRadius: theme.radius.md,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
  },
  primary: {
    backgroundColor: theme.colors.primary,
  },
  primaryPressed: {
    backgroundColor: theme.colors.primaryPressed,
  },
  ghost: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: theme.colors.border,
  },
  ghostPressed: {
    backgroundColor: 'rgba(245, 247, 255, 0.06)',
  },
  disabled: {
    opacity: 0.6,
  },
  label: {
    color: '#041018',
    fontSize: 16,
    fontWeight: '700',
  },
  labelGhost: {
    color: theme.colors.text,
  },
});
