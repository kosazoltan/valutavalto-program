import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Vault, Lock, Unlock, Plus, Minus, AlertTriangle, CheckCircle, Clock, FileCheck } from 'lucide-react'
import { NumberInput } from '../../components/NumberInput'

const mockCashDeskStatus = {
  isOpen: true,
  openedAt: '2024-05-20 08:15:00',
  openedBy: 'Kiss Péter',
  balances: [
    { currency: 'HUF', balance: 2500000, minBalance: 500000, maxBalance: 5000000 },
    { currency: 'EUR', balance: 5200, minBalance: 500, maxBalance: 10000 },
    { currency: 'USD', balance: 3800, minBalance: 500, maxBalance: 8000 },
    { currency: 'GBP', balance: 1200, minBalance: 200, maxBalance: 3000 },
    { currency: 'CHF', balance: 800, minBalance: 200, maxBalance: 2000 },
  ],
  todayStats: {
    transactions: 23,
    buyTotal: 1250000,
    sellTotal: 980000,
    profit: 45000
  }
}

export default function CashDeskPage() {
  const navigate = useNavigate()
  const [status] = useState(mockCashDeskStatus)
  const [showMovementDialog, setShowMovementDialog] = useState(false)
  const [movementType, setMovementType] = useState<'in' | 'out'>('in')
  const [movementCurrency, setMovementCurrency] = useState('HUF')
  const [movementAmount, setMovementAmount] = useState('')

  const getBalanceStatus = (balance: number, min: number, max: number) => {
    if (balance < min) return 'low'
    if (balance > max) return 'high'
    return 'ok'
  }

  const handleMovement = () => {
    // API call would go here
    setShowMovementDialog(false)
    setMovementAmount('')
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Vault />
          Pénztár
        </h1>
        <div className="flex gap-2">
          <button
            onClick={() => navigate('/closing/wizard')}
            className="form-button-primary flex items-center gap-1"
          >
            <FileCheck size={16} />
            Zárás
          </button>
          {status.isOpen ? (
            <button className="form-button flex items-center gap-1 text-red-600">
              <Lock size={16} />
              Pénztár zárás
            </button>
          ) : (
            <button className="form-button-primary flex items-center gap-1">
              <Unlock size={16} />
              Pénztár nyitás
            </button>
          )}
        </div>
      </div>

      {/* Status Banner */}
      <div className={`form-panel flex items-center justify-between ${
        status.isOpen ? 'bg-green-50 border-green-200' : 'bg-red-50 border-red-200'
      }`}>
        <div className="flex items-center gap-2">
          {status.isOpen ? (
            <>
              <CheckCircle className="text-green-600" size={20} />
              <span className="text-green-800 font-semibold">Pénztár nyitva</span>
            </>
          ) : (
            <>
              <Lock className="text-red-600" size={20} />
              <span className="text-red-800 font-semibold">Pénztár zárva</span>
            </>
          )}
        </div>
        <div className="text-sm text-gray-600 flex items-center gap-4">
          <span className="flex items-center gap-1">
            <Clock size={14} />
            Nyitva: {status.openedAt}
          </span>
          <span>Kezelő: {status.openedBy}</span>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3">
        {/* Cash Balances */}
        <div className="col-span-2 form-panel">
          <div className="flex justify-between items-center mb-3">
            <h2 className="section-title">Pénzkészlet</h2>
            <div className="flex gap-2">
              <button 
                onClick={() => { setMovementType('in'); setShowMovementDialog(true); }}
                className="form-button flex items-center gap-1"
              >
                <Plus size={16} />
                Bevét
              </button>
              <button 
                onClick={() => { setMovementType('out'); setShowMovementDialog(true); }}
                className="form-button flex items-center gap-1"
              >
                <Minus size={16} />
                Kivét
              </button>
            </div>
          </div>
          
          <div className="space-y-2">
            {status.balances.map((item) => {
              const balanceStatus = getBalanceStatus(item.balance, item.minBalance, item.maxBalance)
              return (
                <div 
                  key={item.currency}
                  className={`flex items-center justify-between p-3 rounded border ${
                    balanceStatus === 'low' ? 'bg-orange-50 border-orange-200' :
                    balanceStatus === 'high' ? 'bg-yellow-50 border-yellow-200' :
                    'bg-gray-50 border-gray-200'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span className="font-mono font-bold text-lg w-12">{item.currency}</span>
                    {balanceStatus === 'low' && (
                      <span className="flex items-center gap-1 text-orange-600 text-sm">
                        <AlertTriangle size={14} />
                        Alacsony készlet
                      </span>
                    )}
                    {balanceStatus === 'high' && (
                      <span className="flex items-center gap-1 text-yellow-600 text-sm">
                        <AlertTriangle size={14} />
                        Magas készlet
                      </span>
                    )}
                  </div>
                  <div className="text-right">
                    <div className="text-xl font-bold font-mono">
                      {item.balance.toLocaleString('hu-HU')}
                    </div>
                    <div className="text-xs text-gray-500">
                      Min: {item.minBalance.toLocaleString('hu-HU')} | Max: {item.maxBalance.toLocaleString('hu-HU')}
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        </div>

        {/* Today's Stats */}
        <div className="form-panel">
          <h2 className="section-title">Mai statisztika</h2>
          <div className="space-y-3">
            <div className="bg-blue-50 p-3 rounded">
              <div className="text-sm text-blue-600">Tranzakciók</div>
              <div className="text-2xl font-bold text-blue-800">{status.todayStats.transactions}</div>
            </div>
            <div className="bg-green-50 p-3 rounded">
              <div className="text-sm text-green-600">Vétel összesen</div>
              <div className="text-xl font-bold text-green-800">
                {status.todayStats.buyTotal.toLocaleString('hu-HU')} Ft
              </div>
            </div>
            <div className="bg-red-50 p-3 rounded">
              <div className="text-sm text-red-600">Eladás összesen</div>
              <div className="text-xl font-bold text-red-800">
                {status.todayStats.sellTotal.toLocaleString('hu-HU')} Ft
              </div>
            </div>
            <div className="bg-purple-50 p-3 rounded">
              <div className="text-sm text-purple-600">Napi eredmény</div>
              <div className="text-xl font-bold text-purple-800">
                {status.todayStats.profit.toLocaleString('hu-HU')} Ft
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Denomination Panel */}
      <div className="form-panel">
        <h2 className="section-title">Címletek (HUF)</h2>
        <div className="grid grid-cols-8 gap-2">
          {[20000, 10000, 5000, 2000, 1000, 500, 200, 100].map((denom) => (
            <div key={denom} className="text-center p-2 bg-gray-50 rounded border">
              <div className="text-sm font-semibold font-mono">{denom.toLocaleString('hu-HU')}</div>
              <NumberInput 
                value="0,00"
                onChange={() => {}}
                className="form-input w-full text-center text-sm mt-1" 
                allowDecimals={true}
                allowNegative={false}
                min={0}
                step="0.01"
              />
            </div>
          ))}
        </div>
      </div>

      {/* Movement Dialog */}
      {showMovementDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg shadow-xl p-6 w-96">
            <h3 className="text-lg font-bold mb-4">
              {movementType === 'in' ? 'Pénz bevét' : 'Pénz kivét'}
            </h3>
            <div className="space-y-3">
              <div>
                <label className="form-label">Valuta</label>
                <select 
                  value={movementCurrency}
                  onChange={(e) => setMovementCurrency(e.target.value)}
                  className="form-input"
                >
                  <option value="HUF">HUF - Magyar Forint</option>
                  <option value="EUR">EUR - Euró</option>
                  <option value="USD">USD - USA Dollár</option>
                  <option value="GBP">GBP - Angol Font</option>
                  <option value="CHF">CHF - Svájci Frank</option>
                </select>
              </div>
              <div>
                <label className="form-label">Összeg</label>
                <NumberInput
                  value={movementAmount}
                  onChange={(val) => setMovementAmount(val)}
                  className="form-input"
                  placeholder="0,00"
                  allowDecimals={true}
                  allowNegative={false}
                  min={0}
                  step="0.01"
                />
              </div>
              <div>
                <label className="form-label">Megjegyzés</label>
                <textarea className="form-input" rows={2} placeholder="Opcionális..." />
              </div>
            </div>
            <div className="flex justify-end gap-2 mt-4">
              <button 
                onClick={() => setShowMovementDialog(false)}
                className="form-button"
              >
                Mégse
              </button>
              <button 
                onClick={handleMovement}
                className="form-button-primary"
              >
                {movementType === 'in' ? 'Bevételezés' : 'Kivételezés'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
