export type SetupAppMode = 'penztar' | 'ertektar' | 'full' | 'rate-maker';

export interface RoleSelectionSource {
  roles?: string[];
  availableRoles?: Array<{ roleCode?: string; code?: string }>;
}

const LEGACY_BOOTSTRAP_ROLE_CODE = 'CASHIER';

const APP_MODE_ROLE_PREFERENCES: Record<SetupAppMode, string[]> = {
  penztar: ['penztar', 'CASHIER'],
  ertektar: ['ertektar', 'VAULT_KEEPER', 'CHIEF_VAULT', 'foertektar'],
  'rate-maker': ['foertektar', 'ugyvezeto', 'ADMIN'],
  full: [
    'ugyvezeto',
    'foertektar',
    'irodavezeto',
    'belso_ellenor',
    'berszamfejto',
    'penzugyi_vezeto',
    'irodai_dolgozo',
    'csoportvezeto',
    'arfolyam_nezo',
    'ADMIN',
    'MANAGER',
  ],
};

export function normalizeSetupAppMode(appMode: string | null | undefined): SetupAppMode | null {
  const normalized = appMode?.trim().toLowerCase();
  return normalized === 'penztar' ||
    normalized === 'ertektar' ||
    normalized === 'full'
    ? normalized
    : null;
}

export function preferredRoleCodesForAppMode(appMode: string | null | undefined): string[] {
  const normalized = normalizeSetupAppMode(appMode);
  return normalized ? APP_MODE_ROLE_PREFERENCES[normalized] : [];
}

export function resolveBootstrapRoleCodeForAppMode(appMode: string | null | undefined): string {
  return preferredRoleCodesForAppMode(appMode)[0] ?? LEGACY_BOOTSTRAP_ROLE_CODE;
}

export function collectRoleCodes(login: RoleSelectionSource): Set<string> {
  const values = [
    ...(login.roles ?? []),
    ...(login.availableRoles ?? []).flatMap((role) => [role.roleCode, role.code]),
  ];
  return new Set(
    values.filter(
      (roleCode): roleCode is string => typeof roleCode === 'string' && roleCode.trim().length > 0,
    ),
  );
}
