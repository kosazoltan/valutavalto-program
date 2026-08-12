; NSIS IfSilent relativ-ugras szemantika EMPIRIKUS meres.
;
; MIERT: az `installer/Penztar-Setup.nsi` ket mintat hasznal egymas mellett —
; `IfSilent +2 0` (68., 448. sor) es `IfSilent +1` (563., 636., 660., 672.,
; 783., 825., 1153. sor). A 9. sor kommentje szerint egy review tudatosan
; irta at a +2-t +1-re ("E6-01 IfSilent +2->+1"). Csak az egyik lehet helyes.
;
; MERESI ELV: ha a MessageBox silent (/S) modban is megjelenik, a folyamat
; BLOKKOL (nincs, aki OK-t nyomjon) -> a telepito nem lep ki. Ha atugorja, a
; folyamat lefut es kiir egy marker fajlt. A blokkolas/kilepes tehat gepileg
; mérhető, nem velemeny kerdese.
;
; Hasznalat:
;   makensis /DVARIANT=1 ifsilent-probe.nsi   -> IfSilent +1 valtozat
;   makensis /DVARIANT=2 ifsilent-probe.nsi   -> IfSilent +2 valtozat
;   ifsilent-probe-<N>.exe /S                 -> lefut-e, vagy blokkol?

!ifndef VARIANT
  !define VARIANT 1
!endif

Name "IfSilent probe v${VARIANT}"
OutFile "ifsilent-probe-${VARIANT}.exe"
RequestExecutionLevel user
SilentInstall normal
ShowInstDetails nevershow

Section "probe"
  ; A marker konyvtarat a hivo adja at, hogy ne szemeteljunk.
  StrCpy $0 "$EXEDIR\probe-result-${VARIANT}.txt"

  ; ---- A vizsgalt idioma ----
  ; A valos kodban ez egy hibaag: MessageBox tajekoztat, majd Abort.
  ; Silent modban a MessageBox-nak KI KELL MARADNIA, az Abort-nak le kell futnia.
!if ${VARIANT} == 1
  IfSilent +1
  MessageBox MB_OK "Ez a MessageBox silent modban NEM jelenhetne meg."
  Goto after_box
!else
  IfSilent +2 0
  MessageBox MB_OK "Ez a MessageBox silent modban NEM jelenhetne meg."
  Goto after_box
!endif

after_box:
  ; Ide csak akkor jutunk el, ha a MessageBox nem blokkolt.
  FileOpen $1 $0 w
  FileWrite $1 "REACHED_AFTER_MESSAGEBOX variant=${VARIANT}$\r$\n"
  FileClose $1
SectionEnd
