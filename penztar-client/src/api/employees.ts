import apiClient from './client';

/**
 * Dolgozói HR törzsadat API kliens.
 */

/** Lista DTO — kevés mező a táblázathoz */
export interface EmployeeListItem {
  id: number;
  lastName: string;
  firstName: string;
  organizationUnit: string;
  jobTitle: string;
  feorCode: string;
  employmentStartDate: string;
  active: boolean;
}

/** Cím DTO */
export interface EmployeeAddress {
  id?: number;
  addressType: 'PERMANENT' | 'MAILING' | 'TEMPORARY';
  postalCode: string;
  city: string;
  streetName: string;
  streetType: string;
  houseNumber: string;
  building: string;
  staircase: string;
  floor: string;
  door: string;
}

/** Bankszámla DTO */
export interface EmployeeBankAccount {
  id?: number;
  accountType: 'SALARY' | 'SZEP_CARD';
  bankCode: string;
  accountNumber: string;
}

/** Teljes dolgozó DTO */
export interface EmployeeDetail {
  id: number;
  companyId: string;
  workerId: number | null;
  organizationUnit: string;
  serialNumber: number;

  lastName: string;
  firstName: string;
  birthLastName: string;
  birthFirstName: string;
  taxId: string;
  socialSecurityNumber: string;
  mothersName: string;
  birthDate: string;
  birthCountry: string;
  birthPlace: string;
  citizenship: string;

  idCardNumber: string;
  idCardExpiry: string;

  email: string;
  phone: string;

  pensionStartDate: string;
  pensionType: string;
  reducedWorkCapacity: boolean;
  reducedWorkCapacityType: string;

  employmentStartDate: string;
  employmentType: string;
  employmentEndDate: string;
  feorCode: string;
  jobTitle: string;
  workHoursPerDay: number;
  hasSecondaryEducation: boolean;

  salaryType: 'HB' | 'OB' | null;
  salaryAmount: number;
  paymentMethod: 'B' | 'K' | null;

  vocationalSchoolName: string;
  vocationalQualification: string;
  certificateDate: string;

  personalTaxCredit: string;
  familyTaxCredit: string;
  twoChildrenCredit: string;
  fourPlusChildrenCredit: string;
  threeChildrenCredit: string;
  firstMarriageCredit: string;
  marriageDate: string;
  creditValidityLastMonth: string;
  under25YouthCreditAmount: string;
  under25YouthCreditExpiry: string;
  under30MotherCreditAmount: string;

  active: boolean;
  addresses: EmployeeAddress[];
  bankAccounts: EmployeeBankAccount[];
}

/** FEOR kód referencia */
export interface FeorCodeItem {
  id: number;
  code: string;
  title: string;
}

/** Lista szűrő paraméterek */
interface EmployeeListParams {
  organizationUnit?: string;
  jobTitle?: string;
  active?: boolean;
  name?: string;
}

/** Dolgozók listázása szűréssel */
export async function getEmployees(params?: EmployeeListParams): Promise<EmployeeListItem[]> {
  const { data } = await apiClient.get<EmployeeListItem[]>('/employees', { params });
  return data;
}

/** Dolgozó részletes lekérdezés */
export async function getEmployee(id: number): Promise<EmployeeDetail> {
  const { data } = await apiClient.get<EmployeeDetail>(`/employees/${id}`);
  return data;
}

/** Dolgozó létrehozás */
export async function createEmployee(dto: Partial<EmployeeDetail>): Promise<EmployeeDetail> {
  const { data } = await apiClient.post<EmployeeDetail>('/employees', dto);
  return data;
}

/** Dolgozó módosítás */
export async function updateEmployee(id: number, dto: Partial<EmployeeDetail>): Promise<EmployeeDetail> {
  const { data } = await apiClient.put<EmployeeDetail>(`/employees/${id}`, dto);
  return data;
}

/** Dolgozó soft delete */
export async function deleteEmployee(id: number): Promise<void> {
  await apiClient.delete(`/employees/${id}`);
}

/** JSON import */
export async function importEmployees(jsonContent: string): Promise<{ success: boolean; imported: number; message: string }> {
  const { data } = await apiClient.post<{ success: boolean; imported: number; message: string }>(
    '/employees/import',
    jsonContent,
    { headers: { 'Content-Type': 'application/json' } }
  );
  return data;
}

/** FEOR kód lista */
export async function getFeorCodes(): Promise<FeorCodeItem[]> {
  const { data } = await apiClient.get<FeorCodeItem[]>('/employees/feor-codes');
  return data;
}
