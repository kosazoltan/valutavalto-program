; === Regi Valutavalto kliensek tisztitasa az osszevont Kozponti Munkaallomas elott ===
; A fajl a customInit mellett a customCheckAppRunning hookot is definialja (#1428).
; Ez a script a telepites ELOTT fut (customInit) — eltavolitja a ket korabbi klienst
; (Kozponti Iranyitokozpont + Arfolyamkeszito), amelyeket az osszevont "Kozponti
; Munkaallomas" kivalt. Igy nincs duplikalt vagy beagyazott telepites az upgrade-nel.
;
; A GUID-ek determinisztikusak (uuid5(appId)), igy minden gepen azonosak:
;   - com.bestchange.kozponti        -> 8d6cb25c-88c3-528b-8d57-4255e2a10dff (regi Iranyitokozpont)
;   - com.bestchange.arfolyamkeszito -> 20a800ca-9d77-5e25-82c1-18c49595c2ad (regi Arfolyamkeszito)

; === #1428 R2: System.dll crash-fix friss telepitesnel (preInit) ===
; A WER-fingerprint (System.dll 0xc0000005, offset 0x1581 = System!Store+0x4a0)
; az electron-builder multiUser.nsh setInstallModePerUser agaban keletkezik:
; ha NINCS korabbi InstallLocation a registryben, a boilerplate a
; System::Store S + SHGetKnownFolderPath + System::Call utat futtatja, ami
; intermittensen access-violationnel osszeomlik (upstream: electron-builder
; issue #7921; a System::Store call eltavolitasa megszunteti).
; Mitigacio: a preInit (ami az initMultiUser ELOTT fut) beirja az
; InstallLocation-t a default per-user utvonalra, igy a crash-elo ag
; SOHA nem fut le. A /D= kapcsolo tovabbra is felulirja az utvonalat
; (a GetDParameter az InstallLocation-olvasas UTAN ertekelodik ki).
!macro preInit
  SetShellVarContext current
  ReadRegStr $0 HKCU "${INSTALL_REGISTRY_KEY}" InstallLocation
  StrCmp $0 "" 0 +2
  WriteRegStr HKCU "${INSTALL_REGISTRY_KEY}" InstallLocation "$LocalAppData\Programs\${APP_FILENAME}"
!macroend

!macro customInit
  ; 1. Regi per-user telepitesi konyvtarak torlese (AppData\Local\Programs)
  ;    (a beagyazott "...\Iranyitokozpont\Munkaallomas" allapotot is ez tisztitja)
  RMDir /r "$LOCALAPPDATA\Programs\Valutavalto Kozponti Iranyitokozpont"
  RMDir /r "$LOCALAPPDATA\Programs\Valutavalto Arfolyamkeszito"

  ; 2. Regi uninstall registry bejegyzesek torlese (Add/Remove Programs)
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\8d6cb25c-88c3-528b-8d57-4255e2a10dff"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\20a800ca-9d77-5e25-82c1-18c49595c2ad"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\{com.bestchange.kozponti}"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\{com.bestchange.arfolyamkeszito}"

  ; 3. Regi per-user install-location markerek torlese (ezt olvassa az electron-builder
  ;    az "elozo telepites" detektalasahoz — enelkul beagyazna az uj telepitest)
  DeleteRegKey HKCU "Software\8d6cb25c-88c3-528b-8d57-4255e2a10dff"
  DeleteRegKey HKCU "Software\20a800ca-9d77-5e25-82c1-18c49595c2ad"

  ; 4. Regi Start menu mappak/linkek torlese
  Delete "$SMPROGRAMS\Valutavalto Kozponti Iranyitokozpont.lnk"
  Delete "$SMPROGRAMS\Valutavalto Arfolyamkeszito.lnk"
  RMDir /r "$SMPROGRAMS\Valutavalto Kozponti Iranyitokozpont"
  RMDir /r "$SMPROGRAMS\Valutavalto Arfolyamkeszito"

  ; 5. Regi Desktop linkek torlese
  Delete "$DESKTOP\Valutavalto Kozponti Iranyitokozpont.lnk"
  Delete "$DESKTOP\Valutavalto Arfolyamkeszito.lnk"
!macroend

; === Silent (/S) telepites: System.dll process-enum kihagyasa (#1428) ===
; Az electron-builder boilerplate (_CHECK_APP_RUNNING) minden telepiteskor
; lefuttatja a ${GetProcessInfo}-t (nyers System::Call/System::Alloc
; process-enum, getProcessInfo.nsh) — silent modban ez intermittens
; System.dll 0xC0000005 crash-t okoz (load-fuggo, AV-interferencia gyanus).
; A customCheckAppRunning definialasa a boilerplate dokumentalt hookja:
; teljesen kivaltja a default _CHECK_APP_RUNNING-ot
; (allowOnlyOneInstallerInstance.nsh:39-44).
;   - UI mod: az EREDETI _CHECK_APP_RUNNING fut (bajtra azonos viselkedes).
;   - Silent mod: ugyanaz a find/kill logika, DE a ${GetProcessInfo}
;     System.dll-enum NELKUL (a find/kill nsExec-uton fut: tasklist/taskkill
;     ill. PowerShell Get-CimInstance — System.dll-mentes).
; A boilerplate a custom makro miatt NEM include-olja a getProcessInfo.nsh-t
; es NEM deklaralja a $pid-et (allowOnlyOneInstallerInstance.nsh:5-8) —
; mindkettot itt potoljuk (a getProcessInfo.nsh include-guardos, es
; BUILD_UNINSTALLER alatt automatikusan un._GetProcessInfo-t definial).
!include "getProcessInfo.nsh"
Var pid

!macro customCheckAppRunning
  !insertmacro IS_POWERSHELL_AVAILABLE
  ${If} ${Silent}
    ; --- SILENT AG (#1428): _CHECK_APP_RUNNING masolata GetProcessInfo nelkul.
    ; Elteresek az eredetihez kepest (allowOnlyOneInstallerInstance.nsh:105-164):
    ;   1. Nincs ${GetProcessInfo} hivas -> $pid-et fixen 0-ra allitjuk, hogy a
    ;      KILL_PROCESS taskkill-filtere ("PID ne $pid") valid maradjon; a
    ;      setup.exe image-neve ugysem egyezik az app exe-jevel.
    ;   2. Nincs az "installer == app exe" onvedelmi kulso if (ebben a
    ;      termekben a setup exe neve soha nem az app exe neve).
    ;   3. Label-ok atnevezve (silent* prefix), mert a UI-agban beszurt eredeti
    ;      _CHECK_APP_RUNNING ugyanebben a function-scope-ban definialja a
    ;      loop/doStopProcess/not_running label-oket.
    StrCpy $pid 0
    ${if} ${isUpdated}
      # allow app to exit without explicit kill
      Sleep 300
    ${endIf}
    !insertmacro FIND_PROCESS "${APP_EXECUTABLE_FILENAME}" $R0
    ${if} $R0 == 0
      ${if} ${isUpdated}
        # allow app to exit without explicit kill
        Sleep 1000
        Goto silentDoStopProcess
      ${endIf}
      MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION "$(appRunning)" /SD IDOK IDOK silentDoStopProcess
      Quit

      silentDoStopProcess:

      DetailPrint "$(appClosing)"

      !insertmacro KILL_PROCESS "${APP_EXECUTABLE_FILENAME}" 0
      # to ensure that files are not "in-use"
      Sleep 300

      # Retry counter
      StrCpy $R1 0

      silentKillLoop:
        IntOp $R1 $R1 + 1

        !insertmacro FIND_PROCESS "${APP_EXECUTABLE_FILENAME}" $R0
        ${if} $R0 == 0
          # wait to give a chance to exit gracefully
          Sleep 1000
          !insertmacro KILL_PROCESS "${APP_EXECUTABLE_FILENAME}" 1 # 1 = force kill
          !insertmacro FIND_PROCESS "${APP_EXECUTABLE_FILENAME}" $R0
          ${if} $R0 == 0
            DetailPrint `Waiting for "${PRODUCT_NAME}" to close.`
            Sleep 2000
          ${else}
            Goto silentNotRunning
          ${endIf}
        ${else}
          Goto silentNotRunning
        ${endIf}

        # App likely running with elevated permissions.
        # Ask user to close it manually
        ${if} $R1 > 1
          MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION "$(appCannotBeClosed)" /SD IDCANCEL IDRETRY silentKillLoop
          Quit
        ${else}
          Goto silentKillLoop
        ${endIf}
      silentNotRunning:
    ${endIf}
  ${Else}
    ; --- UI AG: az eredeti boilerplate-makro valtozatlanul (bajtra azonos
    ; viselkedes: GetProcessInfo onvedelem + futo-app dialogus + kill-loop).
    !insertmacro _CHECK_APP_RUNNING
  ${EndIf}
!macroend
