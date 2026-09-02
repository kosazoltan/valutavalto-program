/**
 * Penztar suite-updater — UAC elevation launch decisions (pure leaf module).
 *
 * WHY: on a standard-user machine the silent installer spawn fails with EACCES;
 * the recovery path is a PowerShell `Start-Process -Verb RunAs` relaunch. These
 * decisions (failure classification, PowerShell path resolution, argv building,
 * exit-code mapping) must be testable WITHOUT spawning anything: getting them
 * wrong either bricks the update path or quits the app behind a pending UAC
 * prompt.
 */
import { describe, expect, it } from 'vitest';
import {
  buildElevatedLaunchArgv,
  classifyElevatedExit,
  classifySpawnFailure,
  resolvePowerShellPath,
} from '../install-launcher';

const INSTALLER_PATH =
  'C:\\zk\\Downloads\\valutavalto-v2.28.96\\Penztar-Setup-2.28.96-20260902.exe';

describe('classifySpawnFailure — EACCES/EPERM means elevation is required', () => {
  it('EACCES (errno -4092) -> ELEVATION_REQUIRED', () => {
    const err = { code: 'EACCES', errno: -4092 } as NodeJS.ErrnoException;
    expect(classifySpawnFailure(err)).toBe('ELEVATION_REQUIRED');
  });

  it('EPERM -> ELEVATION_REQUIRED', () => {
    const err = { code: 'EPERM' } as NodeJS.ErrnoException;
    expect(classifySpawnFailure(err)).toBe('ELEVATION_REQUIRED');
  });

  it('ENOENT -> LAUNCH_FAILED (not an elevation problem)', () => {
    const err = { code: 'ENOENT' } as NodeJS.ErrnoException;
    expect(classifySpawnFailure(err)).toBe('LAUNCH_FAILED');
  });
});

describe('resolvePowerShellPath — absolute system path, never PATH-resolved', () => {
  it('uses %SystemRoot% when present', () => {
    const p = resolvePowerShellPath({ SystemRoot: 'C:\\Windows' });
    expect(p.endsWith('System32\\WindowsPowerShell\\v1.0\\powershell.exe')).toBe(true);
    expect(p.startsWith('C:\\Windows')).toBe(true);
  });

  it('empty env falls back to C:\\Windows', () => {
    const p = resolvePowerShellPath({});
    expect(p).toBe('C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe');
  });
});

describe('buildElevatedLaunchArgv — hidden PowerShell running Start-Process -Verb RunAs', () => {
  it('contains -NoProfile, the runas markers, the exe path, the silent args and exit 3', () => {
    const argv = buildElevatedLaunchArgv(INSTALLER_PATH, ['/S']);
    const script = argv.join(' ');
    expect(argv).toContain('-NoProfile');
    expect(script).toContain('-Verb RunAs');
    expect(script).toContain(INSTALLER_PATH);
    expect(script).toContain('/S');
    expect(script).toContain('exit 3');
  });

  it('the path appears verbatim inside the script (no backslash mangling)', () => {
    const argv = buildElevatedLaunchArgv(INSTALLER_PATH, ['/S']);
    const script = argv[argv.length - 1];
    expect(script).toContain(INSTALLER_PATH);
  });

  it("single quotes are doubled: o'brien -> o''brien (no unescaped quote survives)", () => {
    const quoted = "C:\\zk\\Downloads\\o'brien\\Penztar-Setup-2.28.96-20260902.exe";
    const argv = buildElevatedLaunchArgv(quoted, ['/S']);
    const script = argv[argv.length - 1];
    expect(script).toContain("o''brien");
    expect(script.includes("o'brien")).toBe(false);
    // After collapsing every doubled quote, only the literal delimiters remain:
    // '...' around the exe path and '...' around the argument list = exactly 4.
    const remaining = script.replaceAll("''", '').match(/'/g) ?? [];
    expect(remaining.length).toBe(4);
  });
});

describe('classifyElevatedExit — the helper exit code is the only consent signal', () => {
  it('0 -> STARTED', () => {
    expect(classifyElevatedExit(0)).toBe('STARTED');
  });

  it('3 -> ELEVATION_REFUSED', () => {
    expect(classifyElevatedExit(3)).toBe('ELEVATION_REFUSED');
  });

  it('1 -> LAUNCH_FAILED', () => {
    expect(classifyElevatedExit(1)).toBe('LAUNCH_FAILED');
  });

  it('null -> LAUNCH_FAILED', () => {
    expect(classifyElevatedExit(null)).toBe('LAUNCH_FAILED');
  });
});
