import * as React from 'react';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import { HomeScreen } from '../screens/HomeScreen';
import { DrinkMomentScreen } from '../screens/DrinkMomentScreen';
import type { RootStackParamList } from './types';
import { theme } from '../theme';

const Stack = createNativeStackNavigator<RootStackParamList>();

export function AppNavigator() {
  return (
    <Stack.Navigator
      initialRouteName="Home"
      screenOptions={{
        headerStyle: { backgroundColor: theme.colors.background },
        headerTintColor: theme.colors.text,
        contentStyle: { backgroundColor: theme.colors.background },
      }}
    >
      <Stack.Screen name="Home" component={HomeScreen} options={{ title: 'water-app' }} />
      <Stack.Screen
        name="DrinkMoment"
        component={DrinkMomentScreen}
        options={{ title: 'Drink moment' }}
      />
    </Stack.Navigator>
  );
}
