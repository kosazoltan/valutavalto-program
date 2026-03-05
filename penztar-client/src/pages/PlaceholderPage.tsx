import { useNavigate, } from 'react-router-dom';
import { useEffect } from 'react';
import { useAuthStore } from '@/stores/authStore';

interface PlaceholderPageProps {
  title: string;
}

export default function PlaceholderPage({ title }: PlaceholderPageProps) {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        navigate('/menu');
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">{title}</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>
      <main className="flex flex-1 items-center justify-center">
        <div className="text-center">
          <p className="text-6xl">🚧</p>
          <h2 className="mt-4 text-2xl font-bold text-gray-700">{title}</h2>
          <p className="mt-2 text-gray-500">
            Ez a funkció fejlesztés alatt áll.
          </p>
          <p className="mt-1 text-sm text-gray-400">
            Nyomjon ESC-et a főmenühöz való visszatéréshez.
          </p>
        </div>
      </main>
    </div>
  );
}
