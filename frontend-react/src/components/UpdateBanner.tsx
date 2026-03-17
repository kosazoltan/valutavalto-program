import { getElectronAPI } from '../utils/electron';

type UpdateBannerProps = {
  updateAvailable: boolean;
  hardRequired: boolean;
};

/**
 * Frissítési értesítő banner — csak Electron-ban jelenik meg (useUpdateNotifier guard).
 * Soft állapot: sárga sáv alul. Hard állapot (5 perc után): modális overlay.
 */
export default function UpdateBanner({ updateAvailable, hardRequired }: UpdateBannerProps) {
  if (!updateAvailable) return null;

  const handleRestart = () => {
    const electronAPI = getElectronAPI();
    if (electronAPI?.restartApp) {
      void electronAPI.restartApp();
    }
  };

  if (hardRequired) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div className="w-full max-w-lg rounded-lg bg-white p-6 shadow-xl">
          <h2 className="mb-3 text-lg font-semibold text-gray-900">Frissítés szükséges</h2>
          <p className="mb-6 text-gray-700">
            Az összes nyitott műveletet mentsd el, majd kattints az újraindításra.
          </p>
          <button
            type="button"
            onClick={handleRestart}
            className="w-full rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          >
            Újraindítás
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed bottom-0 left-0 right-0 z-40 bg-yellow-300 px-4 py-3 text-center text-sm font-medium text-gray-900 shadow-lg">
      🔄 Új verzió érkezett! Mentsd a munkád, majd indítsd újra a programot.
    </div>
  );
}
