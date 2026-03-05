import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

/**
 * Splash Screen - Megjelenik az alkalmazás indításakor
 * - Cég logó középen
 * - "Pénztár Rendszer" felirat
 * - Betöltés animáció
 * - Verzió szám
 * - 2 mp után automatikus redirect LoginPage-re
 */
export default function SplashScreen() {
  const navigate = useNavigate();

  useEffect(() => {
    // Backend health check (opcionális)
    const checkBackend = async () => {
      try {
        const response = await fetch('http://localhost:3000/health', {
          method: 'GET',
          signal: AbortSignal.timeout(1500), // 1.5s timeout
        });
        if (response.ok) {
          console.log('✅ Backend elérhető');
        }
      } catch (error) {
        console.warn('⚠️ Backend nem elérhető még:', error);
      }
    };

    checkBackend();

    // 2 másodperc után redirect LoginPage-re
    const timer = setTimeout(() => {
      navigate('/login');
    }, 2000);

    return () => clearTimeout(timer);
  }, [navigate]);

  // Cég típus detektálás (környezeti változóból vagy config-ból)
  const companyType = import.meta.env.VITE_COMPANY_TYPE || 'bestchange'; // 'bestchange' | 'expressz'
  const isBestChange = companyType === 'bestchange';

  // Cég specifikus színek
  const brandColor = isBestChange ? '#DC2626' : '#EA580C'; // red-600 | orange-600
  const brandName = isBestChange ? 'Best Change' : 'Expressz';

  return (
    <div
      className="min-h-screen flex flex-col items-center justify-center relative overflow-hidden"
      style={{
        background: `linear-gradient(135deg, ${brandColor}dd 0%, ${brandColor} 100%)`,
      }}
    >
      {/* Animated background circles */}
      <div
        className="absolute top-1/4 left-1/4 w-96 h-96 rounded-full blur-3xl opacity-30 animate-pulse"
        style={{ background: 'white' }}
      />
      <div
        className="absolute bottom-1/4 right-1/4 w-80 h-80 rounded-full blur-3xl opacity-20 animate-pulse"
        style={{ background: 'white', animationDelay: '1s' }}
      />

      {/* Logó + Tartalom */}
      <div className="z-10 flex flex-col items-center space-y-8">
        {/* Cég Logó (SVG inline vagy img) */}
        <div
          className="w-32 h-32 rounded-3xl flex items-center justify-center text-white text-6xl font-black shadow-2xl"
          style={{ backgroundColor: brandColor }}
        >
          {isBestChange ? 'BC' : 'EX'}
        </div>

        {/* Alkalmazás Címe */}
        <div className="text-center space-y-2">
          <h1 className="text-5xl font-black text-white tracking-tight">
            {brandName}
          </h1>
          <p className="text-xl font-semibold text-white/90">Pénztár Rendszer</p>
        </div>

        {/* Betöltés Animáció */}
        <div className="flex items-center space-x-2">
          <div
            className="w-3 h-3 rounded-full bg-white animate-bounce"
            style={{ animationDelay: '0s' }}
          />
          <div
            className="w-3 h-3 rounded-full bg-white animate-bounce"
            style={{ animationDelay: '0.2s' }}
          />
          <div
            className="w-3 h-3 rounded-full bg-white animate-bounce"
            style={{ animationDelay: '0.4s' }}
          />
        </div>

        <p className="text-sm font-medium text-white/80 animate-pulse">
          Betöltés...
        </p>

        {/* Verzió szám */}
        <div className="absolute bottom-8 text-sm font-medium text-white/60">
          v{import.meta.env.VITE_APP_VERSION || '1.0.0'}
        </div>
      </div>
    </div>
  );
}
