import * as React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import type { NativeStackNavigationProp } from '@react-navigation/native-stack';

import { Button } from '../components/Button';
import { TextButton } from '../components/TextButton';
import { useCountdown } from '../hooks/useCountdown';
import { hydrationService } from '../services/hydrationService';
import type { RootStackParamList } from '../navigation/types';
import { theme } from '../theme';
import { formatSeconds } from '../utils/formatSeconds';

const DRINK_MOMENT_SECONDS = 15;
const DEFAULT_AMOUNT_ML = 250;

type Nav = NativeStackNavigationProp<RootStackParamList>;

export function DrinkMomentScreen() {
  const navigation = useNavigation<Nav>();
  const { remainingSeconds, isComplete } = useCountdown({ seconds: DRINK_MOMENT_SECONDS });

  const handleSkip = React.useCallback(() => {
    navigation.goBack();
  }, [navigation]);

  const handleDrank = React.useCallback(() => {
    if (!isComplete) {
      return;
    }

    void (async () => {
      await hydrationService.logDrink(DEFAULT_AMOUNT_ML);
      navigation.navigate('Home', { didLogDrink: true });
    })();
  }, [isComplete, navigation]);

  return (
    <SafeAreaView style={styles.safeArea} edges={['bottom']}>
      <View style={styles.container}>
        <View style={styles.header}>
          <Text accessibilityRole="header" style={styles.title}>
            Your pet found water
          </Text>
          <Text style={styles.subtitle}>Take a few sips and come back when you’re done.</Text>
        </View>

        <View style={styles.timerCard}>
          <Text accessibilityLabel="Countdown timer" style={styles.timer}>
            {formatSeconds(remainingSeconds)}
          </Text>
          <Text style={styles.timerHint}>
            {isComplete ? 'Your pet is waiting…' : 'Hold on until the timer ends.'}
          </Text>
        </View>

        <View style={styles.actions}>
          <Button label="I drank" onPress={handleDrank} disabled={!isComplete} />
          <TextButton label="Skip" onPress={handleSkip} />
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
    paddingTop: theme.spacing['2xl'],
    paddingBottom: theme.spacing.xl,
    justifyContent: 'space-between',
  },
  header: {
    gap: theme.spacing.sm,
  },
  title: {
    color: theme.colors.text,
    fontSize: 28,
    fontWeight: '800',
    letterSpacing: -0.3,
  },
  subtitle: {
    color: theme.colors.textMuted,
    fontSize: 16,
    lineHeight: 22,
  },
  timerCard: {
    backgroundColor: theme.colors.surface,
    borderRadius: theme.radius.lg,
    borderWidth: 1,
    borderColor: theme.colors.border,
    paddingHorizontal: theme.spacing.xl,
    paddingVertical: theme.spacing['2xl'],
    alignItems: 'center',
    gap: theme.spacing.sm,
  },
  timer: {
    color: theme.colors.text,
    fontSize: 64,
    fontWeight: '900',
    letterSpacing: -1.0,
    fontVariant: ['tabular-nums'],
  },
  timerHint: {
    color: theme.colors.textMuted,
    fontSize: 14,
    lineHeight: 18,
  },
  actions: {
    gap: theme.spacing.sm,
  },
});
