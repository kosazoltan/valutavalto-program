import { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import apiClient from '@/api/client';

/**
 * SzĂĽnet mĂłd â€” teljes kĂ©pernyĹ‘s overlay.
 *
 * Legacy: PAUSDISP â€” a Delphi rendszerben a szĂĽnet mĂłd
 * letiltotta a pĂ©nztĂˇri mĹ±veleteket, visszaszĂˇmlĂˇlĂłt mutatott,
 * Ă©s supervisor PIN-nel lehetett feloldani.
 *
 * FunkciĂłk:
 * - VisszaszĂˇmlĂˇlĂł (max szĂĽnet idĹ‘ system_parameter-bĹ‘l)
 * - "VisszatĂ©rĂ©s" gomb PIN-nel
 * - Supervisor override (korlĂˇtlan szĂĽnet)
 * - CashDeskBreak entitĂˇs rĂ¶gzĂ­tĂ©se backend-en
 */
export default function BreakPage() {
  const navigate = useNavigate();
  const { user, companyType } = useAuthStore();

  const [maxBreakMinutes, setMaxBreakMinutes] = useState(15);
  const [elapsed, setElapsed] = useState(0); // mĂˇsodpercben
  const [breakId, setBreakId] = useState<number | null>(null);
  const [pin, setPin] = useState('');
  const [pinError, setPinError] = useState('');
  const [showPinDialog, setShowPinDialog] = useState(false);
  const [supervisorOverride, setSupervisorOverride] = useState(false);
  const startTimeRef = useRef<Date>(new Date());

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const remaining = Math.max(0, maxBreakMinutes * 60 - elapsed);
  const isOvertime = remaining === 0 && !supervisorOverride;

  // SzĂĽnet indĂ­tĂˇsa
  useEffect(() => {
    const initBreak = async () => {
      try {
        // Max szĂĽnet idĹ‘ lekĂ©rĂ©se
        const configRes = await apiClient.get('/api/system-parameters/by-key/MAX_BREAK_MINUTES');
        const maxMin = parseInt(configRes.data?.parameterValue ?? '15', 10);
        setMaxBreakMinutes(maxMin);

        // CashDeskBreak rĂ¶gzĂ­tĂ©se
        const res = await apiClient.post('/api/daily-sessions/break/start', {
          workerId: user?.id,
          reason: 'MANUAL',
        });
        setBreakId(res.data?.id ?? null);
        startTimeRef.current = new Date();
      } catch {
        // Ha nincs system parameter â†’ default 15 perc
        setMaxBreakMinutes(15);
      }
    };
    void initBreak();
  }, [user]);

  // VisszaszĂˇmlĂˇlĂł
  useEffect(() => {
    const timer = setInterval(() => {
      const now = new Date();
      const diff = Math.floor((now.getTime() - startTimeRef.current.getTime()) / 1000);
      setElapsed(diff);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // IdĹ‘ formĂˇzĂˇs MM:SS
  const formatTime = (seconds: number) => {
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  // VisszatĂ©rĂ©s kezelĂ©se
  const handleReturn = useCallback(async () => {
    if (!pin) {
      setPinError('Adja meg a PIN kĂłdjĂˇt!');
      return;
    }
    setPinError('');
    try {
      // PIN validĂˇciĂł + szĂĽnet lezĂˇrĂˇsa
      await apiClient.post('/api/daily-sessions/break/end', {
        breakId,
        pin,
        workerId: user?.id,
      });
      navigate('/');
    } catch {
      setPinError('Ă‰rvĂ©nytelen PIN kĂłd!');
    }
  }, [pin, breakId, user, navigate]);

  // Supervisor override
  const handleSupervisorOverride = useCallback(async () => {
    try {
      await apiClient.post('/api/daily-sessions/break/supervisor-override', {
        breakId,
        pin,
        workerId: user?.id,
      });
      setSupervisorOverride(true);
      setShowPinDialog(false);
      setPin('');
    } catch {
      setPinError('Ă‰rvĂ©nytelen supervisor PIN!');
    }
  }, [pin, breakId, user]);

  return (
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-gray-900">
      {/* Header sĂˇv */}
      <div className={`absolute top-0 left-0 right-0 h-2 ${headerColor}`} />

      {/* KĂ¶zponti tartalom */}
      <div className="text-center">
        {/* Ikon */}
        <div className="text-8xl mb-6">â•</div>

        {/* CĂ­m */}
        <h1 className="text-4xl font-bold text-white mb-2">
          SzĂĽnet
        </h1>
        <p className="text-gray-400 text-lg mb-8">
          {user?.fullName ?? 'PĂ©nztĂˇros'} â€” {user?.branchCode ?? ''}
        </p>

        {/* VisszaszĂˇmlĂˇlĂł */}
        <div className={`text-7xl font-mono font-bold mb-4 ${
          isOvertime ? 'text-red-500 animate-pulse' : 'text-white'
        }`}>
          {isOvertime ? `+${formatTime(elapsed - maxBreakMinutes * 60)}` : formatTime(remaining)}
        </div>

        {isOvertime && !supervisorOverride && (
          <p className="text-red-400 text-lg mb-4 animate-pulse">
            âš ď¸Ź TĂşllĂ©pte a megengedett szĂĽnet idĹ‘t! KĂ©rem tĂ©rjen vissza.
          </p>
        )}

        {supervisorOverride && (
          <p className="text-green-400 text-lg mb-4">
            âś… Supervisor jĂłvĂˇhagyĂˇs â€” korlĂˇtlan szĂĽnet
          </p>
        )}

        <p className="text-gray-500 mb-8">
          Eltelt: {formatTime(elapsed)} / Max: {maxBreakMinutes} perc
        </p>

        {/* VisszatĂ©rĂ©s gomb */}
        {!showPinDialog ? (
          <div className="space-y-4">
            <button
              onClick={() => setShowPinDialog(true)}
              className={`px-8 py-4 text-xl font-bold text-white rounded-lg shadow-lg 
                transition-all duration-200 hover:scale-105 active:scale-95
                ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'}`}
            >
              đź”“ VisszatĂ©rĂ©s a pĂ©nztĂˇrhoz
            </button>

            {isOvertime && (
              <div>
                <button
                  onClick={() => setShowPinDialog(true)}
                  className="px-6 py-3 text-sm text-gray-400 hover:text-white 
                    border border-gray-700 rounded-lg hover:border-gray-500 transition-colors"
                >
                  đź”‘ Supervisor feloldĂˇs
                </button>
              </div>
            )}
          </div>
        ) : (
          /* PIN bevitel */
          <div className="bg-gray-800 rounded-xl p-6 w-80 mx-auto">
            <h3 className="text-white text-lg font-semibold mb-4">
              {isOvertime ? 'đź”‘ Supervisor PIN' : 'đź”“ PIN kĂłd'}
            </h3>
            <input
              type="password"
              value={pin}
              onChange={(e) => { setPin(e.target.value); setPinError(''); }}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  if (isOvertime) {
                    void handleSupervisorOverride();
                  } else {
                    void handleReturn();
                  }
                }
              }}
              placeholder="PIN kĂłd"
              className="w-full px-4 py-3 text-center text-2xl tracking-widest bg-gray-700 
                text-white rounded-lg border border-gray-600 focus:border-blue-500 
                focus:outline-none focus:ring-2 focus:ring-blue-500/50"
              autoFocus
            />
            {pinError && (
              <p className="text-red-400 text-sm mt-2">{pinError}</p>
            )}
            <div className="flex gap-3 mt-4">
              <button
                onClick={() => { setShowPinDialog(false); setPin(''); setPinError(''); }}
                className="flex-1 px-4 py-2 text-gray-400 border border-gray-600 
                  rounded-lg hover:bg-gray-700 transition-colors"
              >
                MĂ©gse
              </button>
              <button
                onClick={isOvertime ? handleSupervisorOverride : handleReturn}
                className={`flex-1 px-4 py-2 text-white rounded-lg transition-colors
                  ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'}`}
              >
                OK
              </button>
            </div>
          </div>
        )}
      </div>

      {/* IdĹ‘ Ă©s dĂˇtum */}
      <div className="absolute bottom-6 text-gray-600 text-sm">
        {new Date().toLocaleDateString('hu-HU', { year: 'numeric', month: 'long', day: 'numeric' })}
        {' â€˘ '}
        SzĂĽnet indĂ­tva: {startTimeRef.current.toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit' })}
      </div>
    </div>
  );
}



