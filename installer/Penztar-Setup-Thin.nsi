; =============================================================================
; Valutavalto Penztar -- Thin Client Telepito v1.0
; NSIS 3.x Script
; =============================================================================
; Thin client: CSAK Electron frontend app, NEM tartalmaz:
;   - PostgreSQL
;   - Java JRE / Spring Boot backend
;   - NSSM service manager
; A backend a Hetzner VPS-en fut (https://excvaluta.com/api/v1)
; Becsult installer meret: ~80-120 MB
; =============================================================================

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "x64.nsh"

; --- Parameterek ---
!ifndef VERSION
  !define VERSION "2.1.5"
!endif
!ifndef BUILD_DATE
  !define BUILD_DATE "dev"
!endif
!ifndef THIN_STAGE_DIR
  !define THIN_STAGE_DIR "build\\thin-stage"
!endif
!ifndef OUTPUT_DIR
  !define OUTPUT_DIR "build"
!endif

; --- Windows EXE Version Info ---
VIProductVersion "${VERSION}.0"
VIFileVersion "${VERSION}.0"
VIAddVersionKey /LANG=1038 "ProductName" "Valutavalto Penztar"
VIAddVersionKey /LANG=1038 "CompanyName" "Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "LegalCopyright" "(c) 2026 Exclusive Best Change Zrt."
VIAddVersionKey /LANG=1038 "FileDescription" "Valutavalto Penztar Thin Client Telepito"
VIAddVersionKey /LANG=1038 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1038 "ProductVersion" "${VERSION} (${BUILD_DATE})"
VIAddVersionKey /LANG=1038 "OriginalFilename" "Penztar-Thin-${VERSION}.exe"
VIAddVersionKey /LANG=1038 "InternalName" "PenztarThinSetup"

; --- Alapbeallitasok ---
Name "Valutavalto Penztar ${VERSION} (Thin Client)"
OutFile "${OUTPUT_DIR}\\Penztar-Thin-${VERSION}-${BUILD_DATE}.exe"
InstallDir "$PROGRAMFILES64\\Valutavalto Penztar"
InstallDirRegKey HKLM "Software\\BestChange\\ValutavaltoPenztar" "InstallDir"
RequestExecutionLevel admin
Unicode true
SetCompressor /SOLID lzma
SetCompressorDictSize 64

; --- Branding ---
!define MUI_ICON "..\\penztar-client\\build\\icons\\app-icon-bestchange.ico"
!define MUI_UNICON "..\\penztar-client\\build\\icons\\app-icon-bestchange.ico"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Valutavalto Penztar ${VERSION}"
!define MUI_WELCOMEPAGE_TEXT "Ez a varazslo telepiti a Valutavalto Penztar alkalmazast.$\r$\nEz a thin client verzio csak a Penztar alkalmazast telepiti.$\r$\nA backend szerver a Hetzner szerveren fut (excvaluta.com).$\r$\nTelepites elott zarjon be minden futo Penztar alkalmazast."
!define MUI_FINISHPAGE_RUN "$INSTDIR\\Penztar.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Penztar alkalmazas inditasa"

; --- Oldalak ---
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; --- Uninstaller oldalak ---
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; --- Nyelv ---
!insertmacro MUI_LANGUAGE "Hungarian"

; =============================================================================
; Telepites
; =============================================================================
Section "Telepites" SecInstall
    SetOutPath $INSTDIR

    DetailPrint "Korabbi Penztar leallitasa (ha fut)..."
    nsExec::ExecToLog 'taskkill /F /IM Penztar.exe'
    Sleep 1500

    DetailPrint "Alkalmazas masolasa..."
    File /r "${THIN_STAGE_DIR}\\app\\*.*"

    WriteRegStr HKLM "Software\\BestChange\\ValutavaltoPenztar" "InstallDir" "$INSTDIR"
    WriteRegStr HKLM "Software\\BestChange\\ValutavaltoPenztar" "Version" "${VERSION}"
    WriteRegStr HKLM "Software\\BestChange\\ValutavaltoPenztar" "Type" "thin-client"

    CreateDirectory "$SMPROGRAMS\\Valutavalto Penztar"
    CreateShortcut "$SMPROGRAMS\\Valutavalto Penztar\\Penztar.lnk" "$INSTDIR\\Penztar.exe"
    CreateShortcut "$SMPROGRAMS\\Valutavalto Penztar\\Eltavolitas.lnk" "$INSTDIR\\Uninstall.exe"
    CreateShortcut "$DESKTOP\\Valutavalto Penztar.lnk" "$INSTDIR\\Penztar.exe"

    WriteUninstaller "$INSTDIR\\Uninstall.exe"

    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ValutavaltoPenztar" \
        "DisplayName" "Valutavalto Penztar ${VERSION}"
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ValutavaltoPenztar" \
        "UninstallString" '"$INSTDIR\\Uninstall.exe"'
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ValutavaltoPenztar" \
        "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ValutavaltoPenztar" \
        "Publisher" "Exclusive Best Change Zrt."
    WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ValutavaltoPenztar" \
        "DisplayVersion" "${VERSION}"
    WriteRegDWORD HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ValutavaltoPenztar" \
        "NoModify" 1
    WriteRegDWORD HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ValutavaltoPenztar" \
        "NoRepair" 1

    DetailPrint "Telepites befejezve."
SectionEnd

; =============================================================================
; Eltavolitas
; =============================================================================
Section "Uninstall"
    DetailPrint "Penztar leallitasa..."
    nsExec::ExecToLog 'taskkill /F /IM Penztar.exe'
    Sleep 1500

    Delete "$DESKTOP\\Valutavalto Penztar.lnk"
    Delete "$SMPROGRAMS\\Valutavalto Penztar\\Penztar.lnk"
    Delete "$SMPROGRAMS\\Valutavalto Penztar\\Eltavolitas.lnk"
    RMDir "$SMPROGRAMS\\Valutavalto Penztar"

    DeleteRegKey HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\ValutavaltoPenztar"
    DeleteRegKey HKLM "Software\\BestChange\\ValutavaltoPenztar"

    RMDir /r "$INSTDIR"

    DetailPrint "Eltavolitas befejezve."
SectionEnd
