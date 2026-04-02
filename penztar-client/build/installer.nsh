; Windows 11 Insider (26200+) Chromium sandbox compatibility fix
; The Chromium sandbox initialization fails on recent Windows Insider builds,
; causing the Electron process to exit with code 0 before main.js runs.
; Fix: launch the EXE with --no-sandbox --disable-gpu-sandbox flags.

!macro customInstall
  ; Overwrite default shortcuts with sandbox-disabled versions
  ${ifNot} ${isUpdated}
    CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\${APP_EXECUTABLE_FILENAME}" "--no-sandbox --disable-gpu-sandbox"
  ${endIf}
  CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}.lnk" "$INSTDIR\${APP_EXECUTABLE_FILENAME}" "--no-sandbox --disable-gpu-sandbox"
!macroend
