import * as React from 'react';
import { SafeAreaView, StyleSheet, Text, View } from 'react-native';

import { Button } from '../components/Button';
import { theme } from '../theme';

export function HomeScreen() {
  const handlePrimaryPress = React.useCallback(() => {
    // Navigation + feature wiring will live here later.
  }, []);

  const handleLearnMorePress = React.useCallback(() => {
    void 0;
  }, []);

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.container}>
        <Text accessibilityRole="header" style={styles.title}>
          water-app
        </Text>
        <Text style={styles.subtitle}>
          Product-grade foundations: clean structure, navigation, and shared UI components.
        </Text>

        <View style={styles.actions}>
          <Button label="Get Started" onPress={handlePrimaryPress} />
          <Button label="Learn More" variant="ghost" onPress={handleLearnMorePress} />
        </View>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  container: {
    flex: 1,
    paddingHorizontal: theme.spacing.xl,
    paddingTop: theme.spacing.xl,
    gap: theme.spacing.lg,
  },
  title: {
    color: theme.colors.text,
    fontSize: 32,
    fontWeight: '800',
    letterSpacing: -0.3,
  },
  subtitle: {
    color: theme.colors.textMuted,
    fontSize: 16,
    lineHeight: 22,
  },
  actions: {
    gap: theme.spacing.sm,
    paddingTop: theme.spacing.md,
  },
});
