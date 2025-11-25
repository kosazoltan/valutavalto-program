

// =============================================================================
                    procedure TEstizar.MatricaKodolas;
// =============================================================================

begin
   if (_gepfunkcio=1) AND (_kellMatrica=0) then exit;
   if (_gepfunkcio=3) then exit;

    Matricadbase.close;
   if _gepFunkcio=2 then
     begin
       EtarMatcsomag;
       exit;
     end;

   MatricaDbase.DatabaseName := 'c:\valuta\database\trade.gdb';
   MatricaDbase.Connected := true;

   _pcs := 'SELECT * FROM NAPIOSSZESITO' + _sorveg;
   _pcs := _pcs + 'WHERE DATUM='+chr(39) + _zaroDString + chr(39);

   with MatricaQuery do
     begin
       close;
       sql.clear;
       Sql.Add(_pcs);
       Open;
       First;
       _recno := recno;
     end;

   // Ha a napiosszesito tábla üres ezen a napon, akkor semmi sincs;
   if _recno=0 then
     begin
       MatricaQuery.close;
       Matricadbase.close;
       exit;
     end;

   // A zárónapi rekord mezõit beolvassa és zárja a napiosszesito táblát:
   with MatricaQuery do
     begin
       _nyito   := FieldByName('NYITO').asInteger;
       _matrica := FieldByName('MATRICA').asInteger;
       _telefon := FieldByName('TELEFON').asInteger;
       _atadas  := FieldByNAme('ATADAS').AsInteger;
       _atvetel := FieldByName('ATVETEL').asInteger;
       _zaro    := FieldByName('ZARO').AsInteger;
       _zarokeszlet := FieldByName('ZAROKESZLET').asInteger;
     end;
   MatricaQuery.close;
   Matricadbase.close;

   // -------------------- Innentõl indul az új csomag -------------------------

   _rekordDarab := 1;
   _tradetabla := 'TRAD'+midstr(_zarodstring,3,2)+midstr(_zarodstring,6,2);

   _pcs := 'SELECT * FROM '+ _tradetabla + _sorveg;
   _pcs := _pcs + 'WHERE (DATUM='+chr(39) + _zaroDString + chr(39);
   _pcs := _pcs + ') AND (TIPUS=' + chr(39) + 'F' + chr(39) + ')';

   Matricadbase.Connected := True;
   with MatricaQuery do
     begin
       close;
       sql.Clear;
       Sql.Add(_pcs);
       Open;
       first;
       _recno := recno;
     end;

   if _recno>0 then
     begin
       _reKorddarab := 0;
       while not MatricaQuery.Eof do
         begin
           inc(_rekordDarab);
           _ft := MatricaQuery.fieldByNAme('FIZETENDO').asInteger;
           _tp := MatricaQuery.FieldByName('TARSPENZTAR').asString;

           _irany := 45;  // minusz
           if _ft<0 then  // forditott elõjelek !!!!!
             begin
               _irany := 43;  // plusz +
               _ft := abs(_ft);
             end;

           _forint[_rekordDarab] := _ft;
           _addjel[_rekordDarab] := _irany;
           _tarspt[_rekordDarab] := _tp;
           MatricaQuery.Next;
         end;
     end;

   MatricaQuery.close;
   MatricaDbase.close;

   // --------------------------------------------------------------------------
   // A matrica csomagot elkésziti:

   MatPackiro;
end;

// =============================================================================
                       procedure TEstizar.MatPackIro;
// =============================================================================

var _zz,_zOsszeg: integer;
    _zIrany: byte;

begin

 (* Beirja az address számot és a rekordok számát *)

  _tablaSorszam := 10;  // az a matricás tábla sorszáma
  // _rekordDarab := 1;

  Beiras(1,_tablasorszam);
  Beiras(2,_rekordDarab);

  Beiras(1,_targyev-2000);
  Beiras(1,_targyho);
  Beiras(1,_targynap);
  Beiras(12,_nyito);
  Beiras(12,_matrica);
  Beiras(12,_telefon);
  Beiras(12,_atadas);
  Beiras(12,_atvetel);
  Beiras(12,_zaro);
  Beiras(12,_zarokeszlet);

  _zz := 1;
  while _zz<=_rekordDarab do
    begin
      _zPenztar := trim(_tarspt[_zz]);
      _zIrany   := _addjel[_zz];
      _zOsszeg  := _forint[_zz];
      Beiras(4,_zPenztar);
      Beiras(1,_zIrany);
      Beiras(12,_zOsszeg);
      inc(_zz);
    end;
  Beiras(1,255);
end;

// =============================================================================
                      procedure TEstizar.Etarmatcsomag;
// =============================================================================

var _typ: string;

begin

   ValutaDbase.Connected := true;

   _pcs := 'SELECT * FROM NAPIMAT' + _sorveg;
   _pcs := _pcs + 'WHERE DATUM='+chr(39) + _zaroDString + chr(39);

   with ValutaQuery do
     begin
       close;
       sql.clear;
       Sql.Add(_pcs);
       Open;
       First;
       _recno := recno;
     end;

   if _recno=0 then
     begin
       ValutaQuery.close;
       Valutadbase.close;
       exit;
     end;

   WITH vALUTAQUERY DO
     begin
       _atvetel := FieldByName('ATADAS').AsInteger;
       _atadas  := FieldByname('ATVETEL').asInteger;
       _nyito   := FieldByName('NYITO').asInteger;
       _zaro    := FieldByName('ZARO').asInteger;
     end;

   _zarokeszlet := _zaro;
   _matrica     := 0;
   _telefon     := 0;

   ValutaQuery.close;
   Valutadbase.close;

   // ------------------- INNEN A MÓDOSITÁS ------------------------------------

   _rekordDarab := 1;

   _pcs := 'SELECT * FROM MATBIZONYLAT' + _sorveg;
   _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_zarodstring+chr(39)+') AND (STORNO=1)';

   Valutadbase.Connected := true;
   with ValutaQuery do
     begin
       Close;
       sql.Clear;
       Sql.Add(_pcs);
       Open;
       _recno := recno;
     end;

   if _recno>0 then
     begin
       _rekordDarab := 0;
       while not ValutaQuery.Eof do
         begin
           inc(_rekordDarab);
           _ft := ValutaQuery.FieldByNAme('OSSZEG').asInteger;
           _tp := ValutaQuery.FieldByName('TARSPENZTAR').asString;
           _typ:= ValutaQuery.FieldByName('BIZONYLATTIPUS').asstring;

           _tp := trim(_tp);
           _ft := abs(_ft);

           _irany := 45;  // '-' minusz kódja
           if _typ='B' then _irany := 43;  // + plusz-kódja
           _forint[_rekordDarab] := _ft;
           _addjel[_rekorddarab] := _irany;
           _tarspt[_rekorddarab] := _tp;
           ValutaQuery.Next;
         end;
     end;

   ValutaQuery.close;
   Valutadbase.close;

   MatPackiro;
end;
