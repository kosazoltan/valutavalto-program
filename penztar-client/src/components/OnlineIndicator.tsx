import { useOnlineStatus } from '@/hooks/useOnlineStatus';

export default function OnlineIndicator() {
  const { isOnline, isNetworkOnline, isBackendReachable } = useOnlineStatus();

  const dotColor = isOnline ? 'bg-green-500' : 'bg-red-500';
  const label = isOnline
    ? 'Online'
    : !isNetworkOnline
      ? 'Offline (hálózat)'
      : !isBackendReachable
        ? 'Offline (szerver)'
        : 'Offline';

  return (
    <span className="inline-flex items-center gap-1.5">
      <span className={`inline-block h-2.5 w-2.5 rounded-full ${dotColor}`} />
      <span className={isOnline ? 'text-green-600' : 'text-red-600'}>
        {label}
      </span>
    </span>
  );
}
