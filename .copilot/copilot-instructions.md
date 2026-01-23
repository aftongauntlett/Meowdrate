# water-app — Copilot Instructions

These guidelines are project standards for water-app. Follow them unless a ticket explicitly says otherwise.

## TypeScript and React Native

- Always write TypeScript (`.ts`/`.tsx`). No `any`.
- Prefer strict typing: model data with explicit types and narrow unions.
- Use functional components only. No class components.
- Keep components pure and predictable. Avoid hidden side effects.

## Architecture and boundaries

- `screens/` are for layout + wiring only (navigation, composing components).
- Never put business logic directly in `screens/`.
- Business logic belongs in `services/` (domain operations, API clients) or `hooks/` (stateful orchestration).
- UI building blocks belong in `components/` and should be reusable.
- Utilities go in `utils/` and should be small, deterministic, and well-typed.
- Persistence code belongs in `storage/`.

## File size and readability

- Prefer small, focused files.
- No file should exceed ~200 lines. Split by responsibility.
- Avoid deeply nested components and deeply nested conditionals.
- Use clear naming: `PetCard`, `usePets`, `petService`, `storageKeys`.

## React patterns

- Prefer composition over prop drilling.
- Prefer colocated presentational components when they’re only used once.
- Use memoization (`useMemo`, `useCallback`) intentionally — only when it prevents real re-renders.
- Follow React Hooks rules. Do not disable hook lint rules.

## Styling and UI

- Use shared tokens from `theme/` (colors, spacing, radius).
- Keep styling consistent across screens; prefer shared components over one-off styles.
- Use RN-friendly layout: flexbox, spacing tokens, and accessible touch targets.

## Accessibility and UX

- Provide accessible labels/roles for interactive elements.
- Ensure touch targets are at least 44x44.
- Maintain readable contrast and avoid relying on color alone.
- Support Dynamic Type where possible (avoid hard-coded tiny fonts).

## Testing and maintainability

- Write code that is easy to unit test: pure functions in `utils/`, side effects isolated in `services/`.
- Avoid tight coupling to navigation or global singletons.

## Tooling

- Keep `eslint` and `prettier` passing.
- Prefer `const`. Remove unused imports/vars.
- Don’t add new dependencies without clear justification.
