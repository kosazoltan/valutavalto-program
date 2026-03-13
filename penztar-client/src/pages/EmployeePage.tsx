import { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  getEmployees,
  getEmployee,
  deleteEmployee,
  importEmployees,
  getFeorCodes,
} from '@/api/employees';
import type { EmployeeListItem, EmployeeDetail, FeorCodeItem } from '@/api/employees';

type TabView = 'list' | 'detail' | 'import';

/** Cím típus → magyar név */
const ADDRESS_TYPE_LABELS: Record<string, string> = {
  PERMANENT: 'Állandó lakcím',
  MAILING: 'Levelezési cím',
  TEMPORARY: 'Ideiglenes cím',
};

/** Bankszámla típus → magyar név */
const ACCOUNT_TYPE_LABELS: Record<string, string> = {
  SALARY: 'Bérszámla',
  SZEP_CARD: 'SZÉP kártya',
};

/** Szervezeti egységek (a 9 terület) */
const ORG_UNITS = [
  'Békéscsaba', 'Debrecen', 'Iroda', 'Kaposvár', 'Kecskemét',
  'Nyíregyháza', 'Pécs', 'Szeged', 'Szekszárd',
];

/** Részletes nézet tab típusok */
type DetailTab = 'personal' | 'addresses' | 'bank' | 'employment' | 'benefits';

export default function EmployeePage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [tab, setTab] = useState<TabView>('list');
  const [employees, setEmployees] = useState<EmployeeListItem[]>([]);
  const [selectedEmployee, setSelectedEmployee] = useState<EmployeeDetail | null>(null);
  const [feorCodes, setFeorCodes] = useState<FeorCodeItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Szűrők
  const [filterOrgUnit, setFilterOrgUnit] = useState('');
  const [filterJobTitle, setFilterJobTitle] = useState('');
  const [filterActive, setFilterActive] = useState<string>('true');
  const [filterName, setFilterName] = useState('');

  // Részletes nézet tab
  const [detailTab, setDetailTab] = useState<DetailTab>('personal');

  // Import
  const fileInputRef = useRef<HTMLInputElement>(null);

  // ===== Adatok betöltése =====

  const loadEmployees = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const params: Record<string, string | boolean | undefined> = {};
      if (filterOrgUnit) params.organizationUnit = filterOrgUnit;
      if (filterJobTitle) params.jobTitle = filterJobTitle;
      if (filterActive !== '') params.active = filterActive === 'true';
      if (filterName) params.name = filterName;

      const data = await getEmployees(params as any);
      setEmployees(data);
    } catch {
      console.error('[Employee] Betöltés hiba:', err);
      setError('Dolgozók betöltése sikertelen.');
    } finally {
      setIsLoading(false);
    }
  }, [filterOrgUnit, filterJobTitle, filterActive, filterName]);

  const loadFeorCodes = useCallback(async () => {
    try {
      const data = await getFeorCodes();
      setFeorCodes(data);
    } catch {
      // Nem kritikus — a lista nélkül is működik
    }
  }, []);

  useEffect(() => {
    void loadEmployees();
    void loadFeorCodes();
  }, [loadEmployees, loadFeorCodes]);

  // ===== Részletes nézet =====

  const handleShowDetail = useCallback(async (id: number) => {
    setIsLoading(true);
    setError('');
    try {
      const detail = await getEmployee(id);
      setSelectedEmployee(detail);
      setDetailTab('personal');
      setTab('detail');
    } catch {
      setError('Dolgozó adatainak betöltése sikertelen.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  // ===== Soft delete =====

  const handleDelete = useCallback(async (id: number, name: string) => {
    if (!confirm(`Biztosan inaktiválod: ${name}?`)) return;
    try {
      await deleteEmployee(id);
      setSuccess('✅ Dolgozó inaktiválva!');
      void loadEmployees();
    } catch {
      setError('❌ Inaktiválás sikertelen.');
    }
  }, [loadEmployees]);

  // ===== Import =====

  const handleImport = useCallback(async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsLoading(true);
    setError('');
    setSuccess('');

    try {
      const content = await file.text();
      const result = await importEmployees(content);
      setSuccess(`✅ ${result.message}`);
      setTab('list');
      void loadEmployees();
    } catch {
      setError('❌ Import sikertelen. Ellenőrizd a JSON formátumot!');
    } finally {
      setIsLoading(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  }, [loadEmployees]);

  // ===== FEOR kód keresés =====

  const getFeorTitle = (code: string): string => {
    const found = feorCodes.find(f => f.code === code);
    return found ? found.title : code;
  };

  // ===== ESC → vissza =====

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (tab !== 'list') {
          setTab('list');
          setError('');
          setSuccess('');
        } else {
          navigate('/menu');
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate, tab]);

  // ===== Render =====

  return (
    <div className="flex h-screen flex-col">
      {/* Header */}
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">👤 Dolgozói Törzsadatok</h1>
          <div className="flex gap-2">
            {tab !== 'list' && (
              <button
                onClick={() => { setTab('list'); setError(''); setSuccess(''); }}
                className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
              >
                ← Lista
              </button>
            )}
            <button
              onClick={() => navigate('/menu')}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
            >
              ← Vissza (ESC)
            </button>
          </div>
        </div>
      </header>

      {/* Állapot üzenetek */}
      {error && (
        <div className="bg-red-100 border-l-4 border-red-500 p-3 text-red-700">
          {error}
        </div>
      )}
      {success && (
        <div className="bg-green-100 border-l-4 border-green-500 p-3 text-green-700">
          {success}
        </div>
      )}

      {/* Tartalom */}
      <main className="flex-1 overflow-auto p-6">
        {/* ===== LISTA NÉZET ===== */}
        {tab === 'list' && (
          <>
            {/* Szűrők */}
            <div className="mb-4 grid grid-cols-1 gap-3 md:grid-cols-5">
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Szervezeti egység</label>
                <select
                  value={filterOrgUnit}
                  onChange={(e) => setFilterOrgUnit(e.target.value)}
                  className="w-full rounded border border-gray-300 px-3 py-2 text-sm"
                >
                  <option value="">Mind</option>
                  {ORG_UNITS.map(u => (
                    <option key={u} value={u}>{u}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Munkakör</label>
                <input
                  type="text"
                  value={filterJobTitle}
                  onChange={(e) => setFilterJobTitle(e.target.value)}
                  placeholder="pl. Valutapénztáros"
                  className="w-full rounded border border-gray-300 px-3 py-2 text-sm"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Státusz</label>
                <select
                  value={filterActive}
                  onChange={(e) => setFilterActive(e.target.value)}
                  className="w-full rounded border border-gray-300 px-3 py-2 text-sm"
                >
                  <option value="true">Aktív</option>
                  <option value="false">Inaktív</option>
                  <option value="">Mind</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1">Keresés névre</label>
                <input
                  type="text"
                  value={filterName}
                  onChange={(e) => setFilterName(e.target.value)}
                  placeholder="Vezetéknév vagy keresztnév"
                  className="w-full rounded border border-gray-300 px-3 py-2 text-sm"
                />
              </div>
              <div className="flex items-end gap-2">
                <button
                  onClick={() => void loadEmployees()}
                  className="rounded bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700"
                >
                  🔍 Szűrés
                </button>
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="rounded bg-green-600 px-4 py-2 text-sm text-white hover:bg-green-700"
                >
                  📥 Import
                </button>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".json"
                  onChange={handleImport}
                  className="hidden"
                />
              </div>
            </div>

            {/* Táblázat */}
            {isLoading ? (
              <p className="text-center text-gray-500 py-8">⏳ Betöltés...</p>
            ) : employees.length === 0 ? (
              <p className="text-center text-gray-400 py-8">Nincs találat.</p>
            ) : (
              <div className="overflow-x-auto rounded-lg border">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Név</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Szerv. egység</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Munkakör</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">FEOR</th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Jogv. kezdete</th>
                      <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Aktív</th>
                      <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Műveletek</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200 bg-white">
                    {employees.map((emp) => (
                      <tr key={emp.id} className="hover:bg-gray-50 cursor-pointer"
                          onClick={() => void handleShowDetail(emp.id)}>
                        <td className="px-4 py-3 text-sm font-medium">
                          {emp.lastName} {emp.firstName}
                        </td>
                        <td className="px-4 py-3 text-sm text-gray-600">{emp.organizationUnit}</td>
                        <td className="px-4 py-3 text-sm text-gray-600">{emp.jobTitle}</td>
                        <td className="px-4 py-3 text-sm text-gray-600">{emp.feorCode}</td>
                        <td className="px-4 py-3 text-sm text-gray-600">{emp.employmentStartDate}</td>
                        <td className="px-4 py-3 text-center">
                          <span className={`inline-block rounded-full px-2 py-1 text-xs font-bold ${
                            emp.active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                          }`}>
                            {emp.active ? 'Aktív' : 'Inaktív'}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-center">
                          <button
                            onClick={(e) => { e.stopPropagation(); void handleDelete(emp.id, `${emp.lastName} ${emp.firstName}`); }}
                            className="text-red-600 hover:text-red-800 text-sm"
                            title="Inaktiválás"
                          >
                            🗑️
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <div className="bg-gray-50 px-4 py-2 text-sm text-gray-500">
                  Összesen: {employees.length} dolgozó
                </div>
              </div>
            )}
          </>
        )}

        {/* ===== RÉSZLETES NÉZET ===== */}
        {tab === 'detail' && selectedEmployee && (
          <div>
            <h2 className="text-lg font-bold mb-4">
              {selectedEmployee.lastName} {selectedEmployee.firstName}
              <span className="ml-2 text-sm font-normal text-gray-500">
                #{selectedEmployee.serialNumber} — {selectedEmployee.organizationUnit}
              </span>
            </h2>

            {/* Tab gombok */}
            <div className="flex gap-1 border-b mb-4">
              {([
                ['personal', '👤 Személyi'],
                ['addresses', '🏠 Címek'],
                ['bank', '🏦 Bankszámlák'],
                ['employment', '💼 Jogviszony / Bér'],
                ['benefits', '🎁 Kedvezmények'],
              ] as [DetailTab, string][]).map(([key, label]) => (
                <button
                  key={key}
                  onClick={() => setDetailTab(key)}
                  className={`px-4 py-2 text-sm font-medium border-b-2 ${
                    detailTab === key
                      ? 'border-blue-600 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>

            {/* Tab tartalom */}
            <div className="bg-white rounded-lg border p-6">
              {/* Személyi adatok tab */}
              {detailTab === 'personal' && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <Field label="Vezetéknév" value={selectedEmployee.lastName} />
                  <Field label="Keresztnév" value={selectedEmployee.firstName} />
                  <Field label="Születési vezetéknév" value={selectedEmployee.birthLastName} />
                  <Field label="Születési keresztnév" value={selectedEmployee.birthFirstName} />
                  <Field label="Adóazonosító" value={selectedEmployee.taxId} />
                  <Field label="TAJ-szám" value={selectedEmployee.socialSecurityNumber} />
                  <Field label="Anyja születési neve" value={selectedEmployee.mothersName} />
                  <Field label="Születési dátum" value={selectedEmployee.birthDate} />
                  <Field label="Születési ország" value={selectedEmployee.birthCountry} />
                  <Field label="Születési hely" value={selectedEmployee.birthPlace} />
                  <Field label="Állampolgárság" value={selectedEmployee.citizenship} />
                  <Field label="Személyi ig. száma" value={selectedEmployee.idCardNumber} />
                  <Field label="Személyi ig. lejárta" value={selectedEmployee.idCardExpiry} />
                  <Field label="E-mail" value={selectedEmployee.email} />
                  <Field label="Telefon" value={selectedEmployee.phone} />
                  <Field label="Nyugdíj kezdete" value={selectedEmployee.pensionStartDate} />
                  <Field label="Nyugdíj típusa" value={selectedEmployee.pensionType} />
                  <Field label="Megv. munkaképesség" value={selectedEmployee.reducedWorkCapacity ? 'Igen' : 'Nem'} />
                  {selectedEmployee.reducedWorkCapacityType && (
                    <Field label="Megv. munkakép. típusa" value={selectedEmployee.reducedWorkCapacityType} />
                  )}
                </div>
              )}

              {/* Címek tab */}
              {detailTab === 'addresses' && (
                <div className="space-y-4">
                  {selectedEmployee.addresses.length === 0 ? (
                    <p className="text-gray-400">Nincs rögzített cím.</p>
                  ) : (
                    selectedEmployee.addresses.map((addr, idx) => (
                      <div key={idx} className="border rounded-lg p-4">
                        <h3 className="font-medium text-sm text-gray-700 mb-2">
                          {ADDRESS_TYPE_LABELS[addr.addressType] || addr.addressType}
                        </h3>
                        <p className="text-sm">
                          {addr.postalCode} {addr.city}, {addr.streetName} {addr.streetType} {addr.houseNumber}
                          {addr.building && ` ${addr.building}`}
                          {addr.staircase && ` ${addr.staircase} lph.`}
                          {addr.floor && ` ${addr.floor} em.`}
                          {addr.door && ` ${addr.door} ajtó`}
                        </p>
                      </div>
                    ))
                  )}
                </div>
              )}

              {/* Bankszámlák tab */}
              {detailTab === 'bank' && (
                <div className="space-y-4">
                  {selectedEmployee.bankAccounts.length === 0 ? (
                    <p className="text-gray-400">Nincs rögzített bankszámla.</p>
                  ) : (
                    selectedEmployee.bankAccounts.map((acc, idx) => (
                      <div key={idx} className="border rounded-lg p-4">
                        <h3 className="font-medium text-sm text-gray-700 mb-2">
                          {ACCOUNT_TYPE_LABELS[acc.accountType] || acc.accountType}
                        </h3>
                        <div className="grid grid-cols-2 gap-2 text-sm">
                          <Field label="Bank kód" value={acc.bankCode} />
                          <Field label="Számlaszám" value={acc.accountNumber} />
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}

              {/* Jogviszony / Bér tab */}
              {detailTab === 'employment' && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <Field label="Jogviszony kezdete" value={selectedEmployee.employmentStartDate} />
                  <Field label="Jogviszony megnevezése" value={selectedEmployee.employmentType} />
                  <Field label="Jogviszony vége" value={selectedEmployee.employmentEndDate} />
                  <Field label="FEOR kód" value={selectedEmployee.feorCode ? `${selectedEmployee.feorCode} — ${getFeorTitle(selectedEmployee.feorCode)}` : ''} />
                  <Field label="Munkakör" value={selectedEmployee.jobTitle} />
                  <Field label="Napi munkaóra" value={selectedEmployee.workHoursPerDay?.toString()} />
                  <Field label="Középfokú végzettség" value={selectedEmployee.hasSecondaryEducation ? 'Igen' : 'Nem'} />
                  <Field label="Bér típusa" value={selectedEmployee.salaryType === 'HB' ? 'Havibér' : selectedEmployee.salaryType === 'OB' ? 'Órabér' : selectedEmployee.salaryType} />
                  <Field label="Bér összege" value={selectedEmployee.salaryAmount ? `${selectedEmployee.salaryAmount.toLocaleString('hu-HU')} Ft` : ''} />
                  <Field label="Kifizetés módja" value={selectedEmployee.paymentMethod === 'B' ? 'Banki átutalás' : selectedEmployee.paymentMethod === 'K' ? 'Készpénz' : selectedEmployee.paymentMethod} />
                  <Field label="Szakképző iskola" value={selectedEmployee.vocationalSchoolName} />
                  <Field label="Szakképesítés" value={selectedEmployee.vocationalQualification} />
                  <Field label="Bizonyítvány dátuma" value={selectedEmployee.certificateDate} />
                </div>
              )}

              {/* Kedvezmények tab */}
              {detailTab === 'benefits' && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <Field label="Személyi adókedvezmény" value={selectedEmployee.personalTaxCredit} />
                  <Field label="Családi adóalapkedvezmény" value={selectedEmployee.familyTaxCredit} />
                  <Field label="2 gyermekes anyák kedv." value={selectedEmployee.twoChildrenCredit} />
                  <Field label="3 gyermekes anyák kedv." value={selectedEmployee.threeChildrenCredit} />
                  <Field label="4+ gyermekes anyák kedv." value={selectedEmployee.fourPlusChildrenCredit} />
                  <Field label="Első házasok kedvezmény" value={selectedEmployee.firstMarriageCredit} />
                  <Field label="Házasságkötés időpontja" value={selectedEmployee.marriageDate} />
                  <Field label="Érvényesség utolsó hónapja" value={selectedEmployee.creditValidityLastMonth} />
                  <Field label="25 év alatti fiatalok kedv." value={selectedEmployee.under25YouthCreditAmount} />
                  <Field label="25 év alatti kedv. lejárata" value={selectedEmployee.under25YouthCreditExpiry} />
                  <Field label="30 év alatti anyák kedv." value={selectedEmployee.under30MotherCreditAmount} />
                </div>
              )}
            </div>
          </div>
        )}
      </main>
    </div>
  );
}

/** Egyszerű mező megjelenítő komponens */
function Field({ label, value }: { label: string; value?: string | null }) {
  return (
    <div>
      <span className="text-xs text-gray-500">{label}</span>
      <p className="text-sm font-medium">{value || '—'}</p>
    </div>
  );
}

