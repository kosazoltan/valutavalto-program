
SELECT 1
Use pannon
zap
index on penztar to ptx

select 2
Use pannall
do while .not. eof()
   _penztar = penztar
   _elado = vasarlo
   _vasarlo = elado
   _konvert = konvertalo
   ? _penztar

   select 1
   seek _penztar
   if .not. found()
      append blank
      replace ev with 2011
      replace penztar with _penztar
      replace elado with _elado
      replace vasarlo with _vasarlo
      replace konvertalo with _konvert
   else
      _ede = elado
      _edv = vasarlo
      _edk = konvertalo
      replace elado with (_ede+_elado)
      replace vasarlo with (_edv+_vasarlo)
      replace konvertalo with (_edk+_konvert)
   endif
   select 2
   skip
enddo
close databases
return

