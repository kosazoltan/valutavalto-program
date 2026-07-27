/**
 * Wrapper az electron-builder signtoolOptions.sign hookhoz.
 *
 * Az electron-builder >= 26.15.0 nem enged a workspace rooton
 * (arfolyam-keszito-client/) kivulre mutato hook-modult a konfigban, ezert a
 * kozos alairo script nem hivatkozhato tobbe kozvetlenul
 * ("../penztar-client/scripts/..."). Ez a wrapper a rooton belul el, es a
 * tenyleges implementaciot valtozatlanul a penztar-client scriptje adja
 * (single source of truth, nincs duplikacio).
 */
exports.default = require('../../penztar-client/scripts/sign-with-azure-keyvault.js').default
