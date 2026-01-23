import * as React from 'react';

import { hydrationService } from '../services/hydrationService';

interface State {
  count: number;
  totalAmountMl: number;
  recent: { timestamp: number; amountMl: number }[];
  isLoading: boolean;
  refresh: () => Promise<void>;
}

export function useDrinksToday(): State {
  const [count, setCount] = React.useState(0);
  const [totalAmountMl, setTotalAmountMl] = React.useState(0);
  const [recent, setRecent] = React.useState<{ timestamp: number; amountMl: number }[]>([]);
  const [isLoading, setIsLoading] = React.useState(true);

  const refresh = React.useCallback(async () => {
    setIsLoading(true);
    try {
      const summary = await hydrationService.getDrinksTodaySummary();
      setCount(summary.count);
      setTotalAmountMl(summary.totalAmountMl);
      setRecent(summary.recent);
    } finally {
      setIsLoading(false);
    }
  }, []);

  React.useEffect(() => {
    void refresh();
  }, [refresh]);

  return { count, totalAmountMl, recent, isLoading, refresh };
}
