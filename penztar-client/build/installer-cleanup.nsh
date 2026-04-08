; === Regi Valutavalto telepitesek tisztitasa ===
; Ez a script a telepites ELOTT fut — eltavolitja a korabbi verziok maradekait

!macro customInit
  ; 1. Regi "valuta-penztar" konyvtar torlese (C:\Program Files)
  RMDir /r "$PROGRAMFILES\valuta-penztar"
  RMDir /r "$PROGRAMFILES64\valuta-penztar"
  
  ; 2. Regi "Valutavalto Penztar" konyvtar torlese (C:\Program Files)
  RMDir /r "$PROGRAMFILES\Valutavalto Penztar"
  RMDir /r "$PROGRAMFILES64\Valutavalto Penztar"
  
  ; 3. Regi per-user telepites torlese (AppData\Local\Programs)
  RMDir /r "$LOCALAPPDATA\Programs\valuta-penztar"
  
  ; 4. Regi uninstall registry bejegyzesek torlese
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\valuta-penztar"
  DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\valuta-penztar"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\{com.bestchange.penztar}"
  
  ; 5. Regi Start menu linkek torlese
  RMDir /r "$SMPROGRAMS\valuta-penztar"
  RMDir /r "$SMPROGRAMS\Valutavalto Penztar"
  
  ; 6. Regi Desktop linkek torlese
  Delete "$DESKTOP\valuta-penztar.lnk"
  Delete "$DESKTOP\Valutavalto Penztar.lnk"
!macroend
