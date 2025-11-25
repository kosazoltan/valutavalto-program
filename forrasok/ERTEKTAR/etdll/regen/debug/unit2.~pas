unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StrUtils, ExtCtrls, StdCtrls, ComCtrls, IBQuery, IBDatabase, DB,
  IBCustomDataSet, IBTable, DateUtils;

type
  TREGENERALO = class(TForm)
    IDOZITO: TTimer;
    Panel1: TPanel;
    CSIK: TProgressBar;
    FASTCSIK: TProgressBar;
    regeninfopanel: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Shape1: TShape;
    Shape2: TShape;
    VALUTATABLA: TIBTable;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALDATATABLA: TIBTable;
    VALDATAQUERY: TIBQuery;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;

  procedure FormActivate(Sender: TObject);
  procedure IdozitoTimer(Sender: TObject);
  procedure AdatNullazas;
  procedure NyitoBetoltes;

  procedure KeszletRegeneralo;
  procedure KeszletRogzites;
  procedure HaviForgalomBedolgozas;
  procedure NapiForgalomBedolgozas;

  procedure WuAfaRegeneralo;

  procedure HaviWuforgGyujto;
  procedure NapiWuforgGyujto;

  procedure WuAfaForgalom;
  procedure WuAfaRogzites;
  procedure Kezdijregeneralo;
  procedure KezdijRogzites;
  procedure EkerRegeneralo;
  procedure EkerRogzites;

  procedure ValutaParancs(_ukaz: string);
  procedure GetHardwareData;

  function Nulele(_int,_hh: integer): string;
  function Dnemscan(_egydnem:string): integer;
  
 
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  REGENERALO: TREGENERALO;

  _xx,_y: byte;
  _top,_left,_width,_height,_aktev,_aktho,_eloev,_eloho: word;

  _husdnyito,_hhufnyito,_hafanyito: integer;
  _husdbe,_hhufbe,_hafabe: integer;
  _husdki,_hhufki,_hafaki: integer;

  _nusdnyito,_nhufnyito,_nAfanyito: integer;
  _nusdbe,_nhufbe,_nafabe: integer;
  _nusdki,_nHufki,_nAfaki: integer;
  _nUsdZaro,_nHufZaro,_nAfaZaro: integer;

  _hekernyito,_hekerbe,_hekerki,_nekernyito,_nekerbe,_nekerki,_nekerZaro: integer;
  _hkezdijnyito,_hkezdijbe,_hkezdijki,_nkezdijNyito: integer;
  _nkezdijbe,_nkezdijki,_nkezdijZaro: integer;

  _megnyitottnap,_pcs,_farok,_elofarok,_aktdnem,_tipus,_bizonylat: string;
  _elojel,_biztipus,_ekernev: string;
  _sorveg: string = chr(13)+chr(10);

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                                   'CZK','DKK','EUR','GBP','HRK','HUF','ILS',
                                   'JPY','MXN','NOK','NZD','PLN','RON','RSD',
                                   'RUB','SEK','THB','TRY','UAH','USD');

  _hNyito,_hBevetel,_hKiadas: array[1..27] of integer;
  _nNyito,_nBevetel,_nKiadas,_nZaro: array[1..27] of integer;
  _hztablanev,_aktdatum,_wuni,_kezdijtablanev: string;
  _recno,_bankjegy: integer;
  
 function regeneralorutin: integer; stdcall;


implementation

{$R *.dfm}

// =============================================================================
       function regeneralorutin: integer; stdcall;
// =============================================================================


begin
  Regeneralo := TRegeneralo.Create(Nil);
  result := Regeneralo.ShowModal;
  Regeneralo.Free;
end;



// =========================================================================
        procedure TREGENERALO.FormActivate(Sender: TObject);
// =========================================================================


begin
  _top    := 0;
  _left   := 0;
  _width  := Screen.Monitors[0].width;
  _height := Screen.Monitors[0].Height;

  if _width>1024 then _left := trunc((_width-1024)/2);
  if _height>768 then _top  := trunc((_height-768)/2);

   // _NAPNYITAS STRING NAPJÁT KELL REGENERÁLNI

  Top    := _top + 290;
  Left   := _left + 270;

  Width  := 540;
  Height := 333;

  GetHardwareData;

  _aktev := strtoint(leftstr(_megnyitottnap,4));
  _aktho := strtoint(midstr(_megnyitottnap,6,2));

  _eloEv := _aktev;
  _eloHo := _akthO-1;

  if _eloHo<1 then
    begin
      _eloHo := 12;
      dec(_eloev);
    end;

  _farok      := midstr(_megnyitottnap,3,2)+midstr(_megnyitottnap,6,2);
  _eloFarok   := inttostr(_eloev-2000)+Nulele(_eloho,2);
  _hztablanev := 'HZ' + _elofarok;

  Idozito.Enabled := True;

end;

// ===================================================================
         procedure TRegeneralo.IdozitoTimer(Sender: TObject);
// ===================================================================

begin
  // Itt indul a regenerálás ténylegesen:
  Idozito.Enabled := False;     // Idözitö kikapcsolva
  Csik.Max := 9;

  AdatNullazas;
  NyitoBetoltes;

  Csik.Position := 1;

  KeszletRegeneralo; // Pillanatnyi allás regenerálása
  Csik.Position := 2;

  Keszletrogzites;
  Csik.Position := 3;

  WuafaRegeneralo; // Western és Afa regenerálás
  Csik.Position := 4;

  Wuafarogzites;
  Csik.Position := 5;

  Kezdijregeneralo;
  Csik.Position := 6;

  KezdijRogzites;
  Csik.Position := 7;

  EkerRegeneralo;
  Csik.Position := 8;

  EkerRogzites;
  Csik.Position := 9;

  ModalResult := 1;

end;

// =============================================================================
                  procedure TRegeneralo.KeszletRegeneralo;
// =============================================================================

begin
  Fastcsik.Max := 5;
  FastCsik.Visible  := True;
  FastCsik.Position := 1;

  // A havi adatok bedolgozása  bevétel, kiadás mezökbe:

  HaviForgalomBedolgozas;
  Fastcsik.Position := 2;

  _y := 1;
  while _y<=27 do
    begin
      _nNyito[_y] := _hNyito[_y] + _hBevetel[_y] - _hKiadas[_y];
      inc(_y);
    end;

   Fastcsik.Position := 3;

  // A mai napi forgalmak bedolgozása a bevétel, kiadás mezõibe

  NapiForgalomBedolgozas;
  FastCsik.Position := 4;

  // A pillanatnyi zárókészletek kiszámitása:

  _y := 1;
  while _y<=27 do
    begin
      _nZaro[_y] := _nNyito[_y] + _nBevetel[_y] - _nKiadas[_y];
      inc(_y);
    end;

  FastCsik.Position := 5;

end;


// =============================================================================
           procedure TRegeneralo.HaviForgalomBedolgozas;
// =============================================================================

var _tNev: string;

begin
  RegenInfoPanel.Caption := 'HAVI FORGALOM BEDOLGOZÁSA ..';
  RegenInfoPanel.Repaint;

  _tNev := 'BT' + _farok;
  ValdataDbase.connected := true;

  _pcs := 'SELECT * FROM '+ _tNev + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1';

  with ValdataQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno = 0 then
    begin
      ValdataQuery.Close;
      Valdatadbase.close;
      Exit;
    end;

  ValdataQuery.First;
  while not ValdataQuery.Eof do
    begin
      with ValdataQuery do
        begin
          _aktdatum   := FieldByName('DATUM').asstring;
          _bizonylat  := FieldByName('BIZONYLATSZAM').asString;
          _aktDnem    := Fieldbyname('VALUTANEM').asString;
          _BankJegy   := FieldByname('BANKJEGY').AsInteger;
        end;

      _xx := Dnemscan(_aktdnem);

      // ha ilyen valuta nincs is, akkor ezt ignorálni

      if _xx=0 then
        begin
          ValdataQuery.Next;
          Continue;
        end;

      _tipus := leftstr(_bizonylat,1);

      if _aktdatum=_megnyitottnap then
         begin
           if _tipus='F' then _nKiadas[_xx] := _nKiadas[_xx] + _bankjegy;
           if _tipus='U' then _nBevetel[_xx] := _nBevetel[_xx] + _bankjegy;
         end else
         begin
           if _tipus='F' then _hKiadas[_xx] := _hKiadas[_xx] + _bankjegy;
           if _tipus='U' then _hBevetel[_xx] := _hBevetel[_xx] + _bankjegy;
         end;
      ValdataQuery.Next;
    end;

  ValdataQuery.Close;
  ValdataDbase.close;
end;


// =============================================================================
           procedure TRegeneralo.NapiForgalomBedolgozas;
// =============================================================================


begin
  RegenInfoPanel.Caption := 'NAPI FORGALOM BEDOLGOZÁSA ..';
  RegenInfoPanel.Repaint;
  ValutaDbase.connected := true;

  _pcs := 'SELECT * FROM BLOKKTETEL' + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1';

  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno = 0 then
    begin
      ValutaQuery.Close;
      Valutadbase.close;
      Exit;
    end;

  ValutaQuery.First;
  while not ValutaQuery.Eof do
    begin
      with ValutaQuery do
        begin
          _bizonylat  := FieldByName('BIZONYLATSZAM').asString;
          _aktDnem    := Fieldbyname('VALUTANEM').asString;
          _BankJegy   := FieldByname('BANKJEGY').AsInteger;
        end;

      _xx := Dnemscan(_aktdnem);

      // ha ilyen valuta nincs is, akkor ezt ignorálni

      if _xx=0 then
        begin
          ValutaQuery.Next;
          Continue;
        end;

      _tipus := leftstr(_bizonylat,1);
      if _tipus='F' then _nKiadas[_xx] := _nKiadas[_xx] + _bankjegy;
      if _tipus='U' then _nBevetel[_xx] := _nBevetel[_xx] + _bankjegy;

      ValutaQuery.Next;
    end;

  ValutaQuery.Close;
  ValutaDbase.close;
end;

// =============================================================================
                  procedure TRegeneralo.Keszletrogzites;
// =============================================================================

begin
  RegenInfoPanel.Caption := 'PILLANATNYI ÁLLÁS RÖGZITÉSE ..';
  RegenInfoPanel.Repaint;

  _y := 1;
  while _y<=27 do
    begin
      _aktdnem := _dnem[_y];

      _pcs := 'UPDATE ARFOLYAM ';
      _pcs := _pcs + 'SET NYITO=' + inttostr(_Nnyito[_y]) + ',';
      _pcs := _pcs + 'BEVETEL='   + inttostr(_nbevetel[_y]) + ',';
      _pcs := _pcs + 'KIADAS='    + inttostr(_nkiadas[_y]) + ',';
      _pcs := _pcs + 'ZARO='      + inttostr(_nzaro[_y]) + _sorveg;
      _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);
      ValutaParancs(_pcs);
      inc(_y);
    end;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$ WUAFA $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
              procedure TRegeneralo.WuAfaRegeneralo;
// =============================================================================

begin
   Fastcsik.Max := 2;
   RegenInfoPanel.Caption := 'WU-AFA ADATOK FELDOLGOZÁSA ..';
   RegenInfoPanel.Repaint;

   fastcsik.Position := 1;
   WuafaForgalom;

   fastcsik.Position := 2;
end;

// =============================================================================
                procedure TRegeneralo.WuAfaForgalom;
// =============================================================================

begin
  FastCsik.Max := 3;
  Fastcsik.Position := 1;
  HaviwuforgGyujto;
  Fastcsik.Position := 2;
  NapiWuforgGyujto;
  Fastcsik.Position := 3;
end;

// =============================================================================
                     procedure TRegeneralo.haviWuforgGyujto;
// =============================================================================

begin
  _wuni   := 'WUNI' + _farok;

  _pcs := 'SELECT * FROM ' + _wuni + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1';

  ValdataDbase.Connected := True;
   with ValdataQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       First;
       _recno := recno;
     end;

   if _Recno=0 then
     begin
       ValdataQuery.Close;
       ValdataDbase.close;
       Exit;
     end;

   while not ValdataQuery.Eof do
     begin
       with ValdataQuery do
         begin
           _aktdatum  := FieldByName('DATUM').asstring;
           _elojel    := FieldByName('ELOJEL').asstring;
           _bankjegy  := FieldByname('BANKJEGY').asInteger;
           _biztipus  := trim(FieldByName('BIZTIPUS').asString);
           _aktdnem   := FieldByName('VALUTANEM').asString;
         end;

       if _aktdatum=_megnyitottnap then
         begin
           if _biztipus='WU' then
             begin
               if _aktDnem='USD' then
                 begin
                   if _elojel='+' then _nusdbe := _nusdbe + _bankjegy
                   else _nusdki := _nusdki + _bankjegy;
                 end;

               if _aktDnem='HUF' then
                 begin
                   if _elojel='+' then _nhufbe := _nhufbe + _bankjegy
                   else _nhufki := _nhufki + _bankjegy;
                 end;
             end else
             begin
               if _elojel='+' then _nafabe := _nafabe + _bankjegy
               else _nafaki := _nafaki + _bankjegy;
             end;
         end;

       if _aktdatum<_megnyitottnap then
         begin
           if _biztipus='WU' then
             begin
               if _aktDnem='USD' then
                 begin
                   if _elojel='+' then _husdbe := _husdbe + _bankjegy
                   else _husdki := _husdki + _bankjegy;
                 end;

               if _aktDnem='HUF' then
                 begin
                   if _elojel='+' then _hhufbe := _hhufbe + _bankjegy
                   else _hhufki := _hhufki + _bankjegy;
                 end;
             end else
             begin
               if _elojel='+' then _hafabe := _hafabe + _bankjegy
               else _hafaki := _hafaki + _bankjegy;
             end;
         end;

       Valdataquery.next;
     end;
   Valdataquery.close;
   Valdatadbase.close;
end;

// =============================================================================
               procedure TRegeneralo.NapiWuforgGyujto;
// =============================================================================

begin
  _pcs := 'SELECT * FROM WUAFAFORG WHERE STORNO=1';

  ValutaDbase.Connected := true;
   with ValutaQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       First;
       _recno := recno;
     end;

   if _Recno=0 then
     begin
       ValutaQuery.Close;
       ValutaDbase.close;
       Exit;
     end;

   while not ValutaQuery.Eof do
     begin
       with ValutaQuery do
         begin
           _elojel    := FieldByName('ELOJEL').asstring;
           _bankjegy  := FieldByname('BANKJEGY').asInteger;
           _biztipus  := trim(FieldByName('BIZTIPUS').asString);
           _aktdnem   := FieldByName('VALUTANEM').asString;
         end;

       if _biztipus='WU' then
         begin
           if _aktDnem='USD' then
             begin
               if _elojel='+' then _nusdbe := _nusdbe + _bankjegy
               else _nusdki := _nusdki + _bankjegy;
             end;

           if _aktDnem='HUF' then
             begin
               if _elojel='+' then _nhufbe := _nhufbe + _bankjegy
               else _nhufki := _nhufki + _bankjegy;
             end;
         end else
         begin
           if _elojel='+' then _nafabe := _nafabe + _bankjegy
           else _nafaki := _nafaki + _bankjegy;
         end;
       Valutaquery.next;
     end;
   Valutaquery.close;
   Valutadbase.close;
end;


// =============================================================================
              procedure TRegeneralo.WuAfaRogzites;
// =============================================================================

begin
   RegenInfoPanel.Caption := 'WU - AFA RÖGZITÉSE ..';
   RegenInfoPanel.Repaint;

   _nUsdNyito := _hUsdNyito + _hUsdbe - _hUsdKi;
   _nHufNyito := _hHufNyito + _hHufbe - _hHufKi;
   _nAfaNyito := _hAfaNyito + _hAfabe - _hAfaKi;

   _nusdzaro := _nusdnyito + _nusdbe - _nusdki;
   _nhufzaro := _nhufnyito + _nhufbe - _nhufki;
   _nafazaro := _nafanyito + _nafabe - _nafaki;

   _pcs := 'UPDATE WUAFAADATOK SET USDKESZLET='+inttostr(_nusdzaro);
   _pcs := _pcs + ',HUFKESZLET=' + inttostr(_nhufzaro);
   _pcs := _pcs + ',AFAKESZLET=' + inttostr(_nafazaro);

   ValutaParancs(_pcs);

   _pcs := 'DELETE FROM WZARO';
   ValutaParancs(_pcs);

   _pcs := 'INSERT INTO WZARO (DATUM,USDNYITO,HUFNYITO,AFANYITO,USDBEVETEL,';
   _pcs := _pcs + 'HUFBEVETEL,AFABEVETEL,USDKIADAS,HUFKIADAS,AFAKIADAS,';
   _pcs := _pcs + 'USDZARO,HUFZARO,AFAZARO)' + _sorveg;
   _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';

   _pcs := _pcs + inttostr(_nusdnyito) + ',';
   _pcs := _pcs + inttostr(_nhufnyito) + ',';
   _pcs := _pcs + inttostr(_nafanyito) + ',';

   _pcs := _pcs + inttostr(_nusdbe) + ',';
   _pcs := _pcs + inttostr(_nhufbe) + ',';
   _pcs := _pcs + inttostr(_nafabe) + ',';

   _pcs := _pcs + inttostr(_nusdki) + ',';
   _pcs := _pcs + inttostr(_nhufki) + ',';
   _pcs := _pcs + inttostr(_nafaki) + ',';

   _pcs := _pcs + inttostr(_nusdzaro) + ',';
   _pcs := _pcs + inttostr(_nhufzaro) + ',';
   _pcs := _pcs + inttostr(_nafazaro) + ')';

   ValutaParancs(_pcs);
end;


//$$$$$$$$$$$$$$$$$$$$$$$$$$$ KEZELÉSI DIJ $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                  procedure Tregeneralo.Kezdijregeneralo;
// =============================================================================

begin
  Fastcsik.Max := 4;

  Fastcsik.Position := 1;
  RegenInfoPanel.Caption := 'KEZELÉSI DÍJAK BEDOLGOZÁSA ..';
  RegenInfoPanel.Repaint;

  // -------------------

  _kezdijtablaNev := 'KEZD' + _farok;

  _pcs := 'SELECT * FROM '+ _KezdijTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1';

  Valdatadbase.Connected := true;
  with Valdataquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

 fastcsik.Position := 2;

  while not ValdataQuery.Eof do
    begin
      _aktdatum := ValdataQuery.FieldByNAme('DATUM').asString;
      _elojel   := ValdataQuery.FieldByNAme('ELOJEL').asString;
      _bankjegy := Valdataquery.FieldByNAme('BANKJEGY').asInteger;

      if _aktdatum=_megnyitottnap then
        begin
          if _elojel='+' then _nkezdijbe := _nkezdijbe + _bankjegy
          else _nkezdijki := _nkezdijki + _bankjegy;
        end;

      if _aktdatum<_megnyitottnap then
        begin
          if _elojel='+' then _hkezdijbe := _hkezdijbe + _bankjegy
          else _hkezdijki := _hkezdijki + _bankjegy;
        end;
      Valdataquery.Next;
    end;
  Valdataquery.close;
  Valdatadbase.close;

  /// ------------------------------------------

  _pcs := 'SELECT * FROM KEZDIJ' + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1';

  Valutadbase.Connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

 fastcsik.Position := 3;

  while not ValutaQuery.Eof do
    begin
      _elojel   := ValutaQuery.FieldByNAme('ELOJEL').asString;
      _bankjegy := Valutaquery.FieldByNAme('BANKJEGY').asInteger;

      if _elojel='+' then _nkezdijbe := _nkezdijbe + _bankjegy
      else _nkezdijki := _nkezdijki + _bankjegy;

      Valutaquery.Next;
    end;

  Valutaquery.close;
  Valutadbase.close;

  // --------------------------------------------

  _nKezdijNyito := _hKezdijNyito + _hKezdijbe - _hKezdijki;
  _nKezdijZaro  := _nKezdijNyito + _nKezdijbe - _nKezdijki;

  fastcsik.Position := 4;

end;

// =============================================================================
                     procedure Tregeneralo.Kezdijrogzites;
// =============================================================================

begin
  Fastcsik.Max := 2;
  Fastcsik.Position := 1;
  RegenInfoPanel.Caption := 'KEZELÉSI DÍJAK RÖGZITÉSE ..';
  RegenInfoPanel.Repaint;

  _pcs := 'DELETE FROM KEZDIJDATA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO KEZDIJDATA (DATUM,NYITO,BEVETEL,KIADAS,ZARO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + inttostr(_nkezdijnyito) + ',';
  _pcs := _pcs + inttostr(_nkezdijbe) + ',';
  _pcs := _pcs + inttostr(_nkezdijki) + ',';
  _pcs := _pcs + inttostr(_nkezdijzaro) + ')';

  ValutaParancs(_pcs);
  Fastcsik.position := 2;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$ E-KERESKEDELEM $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                  procedure Tregeneralo.EkerRegeneralo;
// =============================================================================

begin
  Fastcsik.Max := 4;

  RegenInfoPanel.Caption := 'E-KERESKEDELEM FELDOLGOZÁSA ..';
  RegenInfoPanel.Repaint;

  fastcsik.Position := 1;

  _ekernev := 'EKER' + _farok;
  _pcs := 'SELECT * FROM ' + _ekernev + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1';

  ValdataDbase.connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not ValdataQuery.Eof do
    begin
      _aktdatum := ValdataQuery.FieldByNAme('DATUM').asString;
      _elojel   := ValdataQuery.FieldByNAme('ELOJEL').asString;
      _bankjegy := Valdataquery.FieldByNAme('BANKJEGY').asInteger;

      if _aktdatum=_megnyitottnap then
        begin
          if _elojel='+' then _nEkerbe := _nEkerbe + _bankjegy
          else _nEkerki := _nEkerki + _bankjegy;
        end;

      if _aktdatum<_megnyitottnap then
        begin
          if _elojel='+' then _hEkerbe := _hEkerbe + _bankjegy
          else _hEkerki := _hEkerki + _bankjegy;
        end;
      Valdataquery.Next;
    end;
  Valdataquery.close;
  Valdatadbase.close;

  Fastcsik.Position := 2;

   /// ------------------------------------------

  _pcs := 'SELECT * FROM EKERESKEDELEM' + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1';

  Valutadbase.Connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

 fastcsik.Position := 3;

  while not ValutaQuery.Eof do
    begin
      _elojel   := ValutaQuery.FieldByNAme('ELOJEL').asString;
      _bankjegy := Valutaquery.FieldByNAme('BANKJEGY').asInteger;

      if _elojel='+' then _nEkerbe := _nEkerbe + _bankjegy
      else _nEkerki := _nEkerki + _bankjegy;

      Valutaquery.Next;
    end;

  Valutaquery.close;
  Valutadbase.close;

  _nEkerNyito := _hEkerNyito + _hEkerbe - _hEkerki;
  _nEkerZaro  := _nEkerNyito + _nEkerbe - _nEkerki;

  fastcsik.Position := 4;

end;


// =============================================================================
                     procedure Tregeneralo.EkerRogzites;
// =============================================================================

begin
  Fastcsik.Max := 2;
  Fastcsik.Position := 1;
  RegenInfoPanel.Caption := 'E-KERESKEDELEM RÖGZITÉSE ..';
  RegenInfoPanel.Repaint;

  _pcs := 'DELETE FROM EKERDATA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO EKERDATA (DATUM,NYITO,BEVETEL,KIADAS,ZARO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + inttostr(_nekernyito) + ',';
  _pcs := _pcs + inttostr(_nekerbe) + ',';
  _pcs := _pcs + inttostr(_nekerki) + ',';
  _pcs := _pcs + inttostr(_nekerzaro) + ')';
  ValutaParancs(_pcs);

  fastcsik.Position := 2;
end;


// =============================================================================
                   procedure Tregeneralo.GetHardwareData;
// =============================================================================


begin
  ValutaDbase.Connected := true;

  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
      Close;
    end;
  ValutaDbase.close;
end;


// =============================================================================
              function TRegeneralo.Nulele(_int,_hh: integer): string;
//==============================================================================

begin
  result := inttostr(_int);
  while length(result)<_hh do result := '0' + result;
end;


// =============================================================================
     function TRegeneralo.Dnemscan(_egydnem:string): integer;
// =============================================================================

var y: integer;

begin
  Result := 0;
  y := 1;

  while y<=27 do
    begin
      if _egyDnem=_dnem[y] then
        begin
          Result := y;
          Exit;
        end;
      inc(y);
     end;
end;


// =============================================================================
                procedure TRegeneralo.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.connected := true;
  if ValutaTranz.InTransaction then Valutatranz.Commit;
  Valutatranz.StartTransaction;
  with Valutaquery do
    begin
      Close;
      sql.Clear;
      Sql.add(_ukaz);
      ExecSql;
    end;
  Valutatranz.commit;
  Valutadbase.close;
end;


// =============================================================================
                 procedure TRegeneralo.AdatNullazas;
// =============================================================================


begin
  _y := 1;
  while _y<=27 do
    begin
      _hNyito[_y]   := 0;
      _hBevetel[_y] := 0;
      _hKiadas[_y]  := 0;
      _nNyito[_y]   := 0;
      _nBevetel[_y] := 0;
      _nKiadas[_y]  := 0;
      _nZaro[_y]    := 0;
      inc(_y);
    end;

  _husdnyito := 0;
  _hhufnyito := 0;
  _hafanyito := 0;

  _husdbe := 0;
  _hhufbe := 0;
  _hafabe := 0;

  _husdki := 0;
  _hhufki := 0;
  _hafaki := 0;

  _nusdnyito := 0;
  _nhufnyito := 0;
  _nafanyito := 0;

  _nusdbe := 0;
  _nhufbe := 0;
  _nafabe := 0;

  _nusdki := 0;
  _nhufki := 0;
  _nafaki := 0;

  _nusdzaro := 0;
  _nhufzaro := 0;
  _nafazaro := 0;

  _hkezdijnyito := 0;
  _hKezdijBe := 0;
  _hKezdijKi := 0;
  _nKezdijNyito := 0;
  _nKezdijbe := 0;
  _nKezdijki := 0;
  _nKezdijZAro := 0;

  _hekerNyito := 0;
  _hekerbe := 0;
  _hekerki := 0;
  _nekernyito := 0;
  _nekerbe := 0;
  _nekerki := 0;
  _nekerzaro := 0;
end;

// =============================================================================
          procedure TRegeneralo.NyitoBetoltes;
// =============================================================================

var _nyito: integer;

begin
  RegenInfoPanel.Caption := 'A HÓ ELEJI NYITÓKÉSZLETEK BEOLVASÁSA ..';
  RegenInfoPanel.Repaint;

  ValdataDbase.Connected := true;

  _pcs := 'SELECT * FROM '+ _hztablanev;
  with ValdataQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
      _hkezdijnyito := FieldByNAme('KEZDIJZARO').asInteger;
      _hekernyito   := FieldByNAme('EKERZARO').asInteger;
      _husdnyito    := FieldByNAme('USDZARO').asInteger;
      _hhufnyito    := FieldByNAme('HUFZARO').asInteger;
      _hafanyito    := FieldByNAme('AFAZARO').asInteger;
    end;

  while not ValdataQuery.Eof do
    begin
      with ValdataQuery do
        begin
          _aktdnem := FieldByName('VALUTANEM').asString;
          _nyito   := FieldByName('ZARO').asInteger;
        end;

      _xx := DnemScan(_aktdnem);
      _hNyito[_xx] := _nyito;

      ValdataQuery.next;
    end;

  ValdataQuery.Close;
  valdatadbase.close;
end;



end.
