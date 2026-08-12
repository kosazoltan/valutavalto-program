; NSIS exit-code meres: `Abort` egy Section-ben, /S modban.
;
; MIERT: a tervezett suite-updater a telepito EXIT KODJARA tamaszkodik ("nem-nulla
; exit hibanal"). Ha az NSIS nema modban 0-t adna vissza egy megszakadt telepites
; utan, az updater sikeresnek hinne a bukott upgrade-et — ezert ezt meg kell merni,
; nem feltetelezni. Ez a probe NEM nyit MessageBox-ot (nincs GUI-zavar).
;
;   makensis /DFAILMODE=1 abort-exit-probe.nsi  -> Abort a Section-ben
;   makensis /DFAILMODE=0 abort-exit-probe.nsi  -> sikeres lefutas
;   abort-exit-probe-<N>.exe /S ; echo $?

!ifndef FAILMODE
  !define FAILMODE 1
!endif

Name "Abort exit probe ${FAILMODE}"
OutFile "abort-exit-probe-${FAILMODE}.exe"
RequestExecutionLevel user
SilentInstall normal
ShowInstDetails nevershow

Section "probe"
  DetailPrint "probe start"
!if ${FAILMODE} == 1
  ; Ugyanaz az idioma, mint a Penztar-Setup.nsi hibaagaiban: silent modban a
  ; MessageBox kimarad, az Abort lefut.
  IfSilent +2 0
  MessageBox MB_OK "nem jelenhet meg /S alatt"
  Abort "probe: szandekos hiba"
!endif
  DetailPrint "probe vege (siker)"
SectionEnd
