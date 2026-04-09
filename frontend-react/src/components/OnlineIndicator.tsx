import { useOnlineStatus } from '../hooks/useOnlineStatus';

/**
 * Kis online/offline állapot jelző — fejléc vagy státuszsor számára.
 * Böngészőben csak hálózat alapú, Electronban backend health check is fut.
 */
export default function OnlineIndicator() {
  const { isOnline, isNetworkOnline, isBackendReachable, lastCheckedAt } =
    useOnlineStatus();

  const dotColor = isOnline ? 'bg-green-500' : 'bg-red-500';
  const textColor = isOnline ? 'text-green-600' : 'text-red-600';

  const label = isOnline
    ? 'Online'
    : !isNetworkOnline
      ? 'Offline (hálózat)'
      : isBackendReachable ? 'Offline' : 'Offline (szerver)';

  return (
    <span
      className="inline-flex items-center gap-1.5"
      title={
        lastCheckedAt
          ? `Utolsó ellenőrzés: ${lastCheckedAt.toLocaleTimeString('hu-HU')}`
          : undefined
      }
    >
      <span className={`inline-block h-2.5 w-2.5 rounded-full ${dotColor}`} />
      <span className={textColor}>{label}</span>
    </span>
  );
}
