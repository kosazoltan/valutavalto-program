import type { VoiceMode } from '../hooks/useVoiceMode'
import installPromptRaw from './systemPrompt.install.md?raw'
import testPromptRaw from './systemPrompt.test.md?raw'
import supportPromptRaw from './systemPrompt.support.md?raw'

/**
 * EBC Hangsegéd system prompt loader.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §4.1-4.3
 *
 * <p>A három üzemmódhoz a `*.md?raw` Vite plugin-import segítségével olvassuk
 * be a markdown szöveget. Build-time **inline** a JS bundle-be — runtime
 * fetch nincs, a .md fajlok NEM kerulnek kulon assetkent a dist/-be.
 * Electron csomagban a prompt-szoveg a renderer JS-ben el.
 *
 * <p>Megjegyzes: a promptok ekezet-mentes magyar nyelven irodtak — ez
 * SZANDEKOS, a forras-direktiva tukrozesee (encoding-biztos), es az LLM
 * a kollegai audio outputban automatikusan ekezetekkel beszel magyarul.
 */

type ActiveMode = Exclude<VoiceMode, 'idle'>

const PROMPTS: Record<ActiveMode, string> = {
  install: installPromptRaw,
  test: testPromptRaw,
  support: supportPromptRaw,
}

/**
 * Kerdezi le a megfelelő system promptot.
 *
 * @param mode aktiv hangsegéd-mod
 * @param moduleKnowledge opcionalis high-level overview (Phase 1 PR #654)
 * @returns összefűzött system prompt
 */
export function getSystemPrompt(
  mode: ActiveMode,
  moduleKnowledge?: string
): string {
  const base: string = PROMPTS[mode] ?? ''
  if (!moduleKnowledge || !moduleKnowledge.trim()) {
    return base
  }
  return `${base}\n\n# MODULISMERETI HIGH-LEVEL OVERVIEW (mindig releváns)\n\n${moduleKnowledge.trim()}\n`
}

export function getAvailablePromptModes(): ActiveMode[] {
  return Object.keys(PROMPTS) as ActiveMode[]
}
