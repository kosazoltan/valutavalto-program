/**
 * Penztar suite-updater — UAC elevation launch decisions (pure leaf module).
 *
 * WHY: on a standard-user machine the silent installer spawn fails with EACCES
 * (the NSIS setup requires administrator). The recovery path is a PowerShell
 * `Start-Process -Verb RunAs` relaunch. Every decision on that path is a pure
 * function here so it is testable WITHOUT spawning anything:
 *   - classifySpawnFailure: is the spawn error an elevation problem?
 *   - resolvePowerShellPath: absolute system path, never PATH-resolved
 *     (PATH hijack would let an attacker own the elevation prompt).
 *   - buildElevatedLaunchArgv: the hidden powershell command line.
 *   - classifyElevatedExit: the helper's exit code is the ONLY consent signal.
 *
 * No `electron` import: side effects (spawn, app.quit, IPC) stay in
 * suite-update.ts; this file only decides.
 */

export type SpawnFailureKind = 'ELEVATION_REQUIRED' | 'LAUNCH_FAILED';
export type ElevatedLaunchOutcome = 'STARTED' | 'ELEVATION_REFUSED' | 'LAUNCH_FAILED';

/** EACCES / EPERM on the installer exe means the caller lacks admin rights. */
export function classifySpawnFailure(err: NodeJS.ErrnoException): SpawnFailureKind {
  if (err.code === 'EACCES' || err.code === 'EPERM' || err.errno === -4092) {
    return 'ELEVATION_REQUIRED';
  }
  return 'LAUNCH_FAILED';
}

/**
 * Absolute PowerShell path from %SystemRoot% (fallback C:\Windows). Never rely
 * on PATH: a writable PATH entry named powershell.exe would run elevated here.
 */
export function resolvePowerShellPath(env: NodeJS.ProcessEnv): string {
  const systemRoot = env.SystemRoot && env.SystemRoot.length > 0 ? env.SystemRoot : 'C:\\Windows';
  return `${systemRoot}\\System32\\WindowsPowerShell\\v1.0\\powershell.exe`;
}

/**
 * Double every single quote for interpolation into a single-quoted PowerShell
 * string literal ('...' — the only PowerShell string form with no expansion).
 */
function quoteForPowerShell(value: string): string {
  return `'${value.replaceAll("'", "''")}'`;
}

/**
 * Build the argv for the elevation helper: hidden, non-interactive PowerShell
 * that starts the installer elevated. The script maps a refused consent
 * (Win32 error 1223) to exit code 3; success to 0.
 *
 * The helper is NOT detached and IS awaited: its exit code is the only consent
 * signal, and quitting the app before it returns would kill the UAC prompt.
 */
export function buildElevatedLaunchArgv(exePath: string, args: string[]): string[] {
  const argumentList = args.map((a) => quoteForPowerShell(a)).join(',');
  const script =
    `try { Start-Process -FilePath ${quoteForPowerShell(exePath)}` +
    ` -ArgumentList ${argumentList} -Verb RunAs -ErrorAction Stop; exit 0 }` +
    ` catch { exit 3 }`;
  return ['-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden', '-Command', script];
}

/** Map the helper exit code: 0 = installer started, 3 = user refused UAC. */
export function classifyElevatedExit(code: number | null): ElevatedLaunchOutcome {
  if (code === 0) return 'STARTED';
  if (code === 3) return 'ELEVATION_REFUSED';
  return 'LAUNCH_FAILED';
}
