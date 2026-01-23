import * as React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useFocusEffect, useNavigation, useRoute } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';

import { Button } from '../components/Button';
import { theme } from '../theme';
import { useDrinksToday } from '../hooks/useDrinksToday';
import type { RootStackParamList } from '../navigation/types';

type Nav = NativeStackNavigationProp<RootStackParamList>;

export function HomeScreen() {
  const navigation = useNavigation<Nav>();
  const route = useRoute();
  const { count, totalAmountMl, recent, isLoading, refresh } = useDrinksToday();
  const [showSuccess, setShowSuccess] = React.useState(false);

  const timeFormatter = React.useMemo(
    () =>
      new Intl.DateTimeFormat(undefined, {
        hour: 'numeric',
        minute: '2-digit',
      }),
    [],
  );

  useFocusEffect(
    React.useCallback(() => {
      void refresh();

      const didLogDrink = Boolean(
        (route.params as { didLogDrink?: boolean } | undefined)?.didLogDrink,
      );
      if (!didLogDrink) {
        return;
      }

      setShowSuccess(true);
      navigation.setParams({ didLogDrink: undefined });

      const timeout = setTimeout(() => {
        setShowSuccess(false);
      }, 2000);

      return () => {
        clearTimeout(timeout);
      };
    }, [navigation, refresh, route.params]),
  );

  const handleTestDrinkMomentPress = React.useCallback(() => {
    navigation.navigate('DrinkMoment');
  }, [navigation]);

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.container}>
        <View style={styles.header}>
          <Text accessibilityRole="header" style={styles.title}>
            Home
          </Text>
          <Text style={styles.subtitle}>{`Drinks today: ${isLoading ? '…' : String(count)}`}</Text>
          <Text
            style={styles.subtitle}
          >{`Total today: ${isLoading ? '…' : String(totalAmountMl)} ml`}</Text>
          {showSuccess && <Text style={styles.success}>Nice — drink logged.</Text>}
        </View>

        <View style={styles.history}>
          <Text style={styles.historyTitle}>Recent (dev)</Text>
          {isLoading ? (
            <Text style={styles.historyRow}>Loading…</Text>
          ) : recent.length === 0 ? (
            <Text style={styles.historyRow}>No drinks yet.</Text>
          ) : (
            recent.map((entry) => (
              <Text key={entry.timestamp} style={styles.historyRow}>
                {`${timeFormatter.format(new Date(entry.timestamp))} • ${entry.amountMl} ml`}
              </Text>
            ))
          )}
        </View>

        <View style={styles.actions}>
          <Button label="Test drink moment" onPress={handleTestDrinkMomentPress} />
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
  header: {
    gap: theme.spacing.xs,
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
  success: {
    color: theme.colors.primary,
    fontSize: 14,
    lineHeight: 18,
    paddingTop: theme.spacing.sm,
    fontWeight: '600',
  },
  actions: {
    gap: theme.spacing.sm,
    paddingTop: theme.spacing.md,
  },
  history: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    padding: theme.spacing.lg,
    gap: theme.spacing.xs,
  },
  historyTitle: {
    color: theme.colors.text,
    fontSize: 14,
    fontWeight: '700',
  },
  historyRow: {
    color: theme.colors.textMuted,
    fontSize: 14,
    lineHeight: 18,
  },
});
