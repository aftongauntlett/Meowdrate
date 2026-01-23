import * as React from 'react';

interface UseCountdownOptions {
  seconds: number;
  autoStart?: boolean;
  intervalMs?: number;
}

export interface CountdownState {
  remainingSeconds: number;
  isComplete: boolean;
  reset: () => void;
}

export function useCountdown({
  seconds,
  autoStart = true,
  intervalMs = 1000,
}: UseCountdownOptions) {
  const [remainingSeconds, setRemainingSeconds] = React.useState(seconds);

  const reset = React.useCallback(() => {
    setRemainingSeconds(seconds);
  }, [seconds]);

  React.useEffect(() => {
    if (!autoStart) {
      return;
    }

    setRemainingSeconds(seconds);

    const interval = setInterval(() => {
      setRemainingSeconds((current) => Math.max(0, current - 1));
    }, intervalMs);

    return () => {
      clearInterval(interval);
    };
  }, [autoStart, intervalMs, seconds]);

  return {
    remainingSeconds,
    isComplete: remainingSeconds === 0,
    reset,
  } satisfies CountdownState;
}
