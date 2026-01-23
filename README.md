# water-app

This is a React Native mobile app that helps users build and maintain focus habits with a calm, friendly experience.

## What it is

A product-grade mobile application foundation with a clean architecture, shared UI components, navigation, and strict TypeScript.

## Tech stack

- Expo (latest SDK)
- React Native
- TypeScript (strict)
- React Navigation
- ESLint + Prettier

## How to run

### Prerequisites

- Node.js + npm
- Expo Go app (for device testing) or Xcode/Android Studio for simulators

### Install

```bash
npm install
```

### Start

```bash
npx expo start
```

Useful scripts:

```bash
npm run typecheck
npm run lint
npm run format:check
```

## Folder structure

The project uses an `app/` source directory for maintainability.

```
app/
  components/    Reusable UI building blocks
  screens/       Screen layout + navigation wiring (no business logic)
  hooks/         Stateful orchestration and reusable app hooks
  services/      Domain logic, API clients, side effects
  storage/       Persistence (AsyncStorage/secure storage wrappers)
  navigation/    Navigators and navigation types
  theme/         Design tokens (colors, spacing, radius)
  utils/         Small pure helpers
  App.tsx        App root (providers, navigation container)

App.tsx          Thin Expo entrypoint that delegates to app/App.tsx
index.ts         Expo root registration
assets/          Static assets
```

## Design principles

- Clear boundaries: UI vs orchestration vs domain logic
- Small, focused modules (avoid “god files”)
- Predictable data flow and testable code paths
- Consistent styling via theme tokens

## Accessibility goals

- Interactive elements have roles/labels and adequate touch targets
- High-contrast, readable typography and spacing
- Support system settings where practical (font scaling, safe areas)
- Avoid color-only signals; always include text or structure
