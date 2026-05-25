; === Regi Valutavalto kliensek tisztitasa az osszevont Kozponti Munkaallomas elott ===
; Ez a script a telepites ELOTT fut (customInit) — eltavolitja a ket korabbi klienst
; (Kozponti Iranyitokozpont + Arfolyamkeszito), amelyeket az osszevont "Kozponti
; Munkaallomas" kivalt. Igy nincs duplikalt vagy beagyazott telepites az upgrade-nel.
;
; A GUID-ek determinisztikusak (uuid5(appId)), igy minden gepen azonosak:
;   - com.bestchange.kozponti        -> 8d6cb25c-88c3-528b-8d57-4255e2a10dff (regi Iranyitokozpont)
;   - com.bestchange.arfolyamkeszito -> 20a800ca-9d77-5e25-82c1-18c49595c2ad (regi Arfolyamkeszito)

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
