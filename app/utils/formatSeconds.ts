export function formatSeconds(seconds: number): string {
  const clamped = Math.max(0, Math.floor(seconds));
  const minutes = Math.floor(clamped / 60);
  const remainder = clamped % 60;

  return `${String(minutes).padStart(1, '0')}:${String(remainder).padStart(2, '0')}`;
}
