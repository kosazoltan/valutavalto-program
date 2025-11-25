unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DB, Grids, DBGrids, DBTables,
  DateUtils, StrUtils, ComCtrls, IBDatabase, IBCustomDataSet, IBTable,
  IBQuery, printers, jpeg;

type
  TVALUTAOSSZESITOFORM = class(TForm)
    Label4: TLabel;
    INTERVALLUMPANEL: TPanel;
    Label5: TLabel;
    TOLPANEL: TPanel;
    Label6: TLabel;
    IGPANEL: TPanel;
    Label7: TLabel;
    TELJFORGLABEL: TLabel;
    Shape3: TShape;
    VALUTAQUERY: TIBQuery;
    VALUTATRANZ: TIBTransaction;
    VALUTADBASE: TIBDatabase;
    KILEPO: TTimer;
    VALDATAQUERY: TIBQuery;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
    valdatatabla: TIBTable;
    CSIKPANEL: TPanel;
    CSIK: TProgressBar;
    Image1: TImage;

    procedure ForgalomOsszesito;

  

    procedure Nullazas;
    procedure TextKiiro;
    procedure KozepreIr(_szoveg: string);

    procedure FormActivate(Sender: TObject);


    procedure AlapadatBeolvasas;

    function Ftform(_n: integer): string;

    procedure GetKertdatumAdatok;
    procedure KILEPOTimer(Sender: TObject);

    function Scandnem(_adn: string): byte;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  VALUTAOSSZESITOFORM: TVALUTAOSSZESITOFORM;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                                   'CZK','DKK','EUR','GBP','HRK','HUF','ILS',
                                   'JPY','MXN','NOK','NZD','PLN','RON','RSD',
                                   'RUB','SEK','THB','TRY','UAH','USD');

  _vetel,_eladas,_atadott,_atvett: array[1..27] of integer;
  _vetelFt,_eladasFt: array[1..27] of integer;

  _rekdarab,_aktRek,_sumvetel,_sumeladas,_mResult: integer;
  _vker,_eker,_kerekites: integer;
  _fejtombnev,_tettombnev,_vkers,_ekers: string;

  _aktbankjegy,_aktertek,_aktvetel,_akteladas,_code: integer;
  _aktatvett,_aktatadott,_aktvetelFt,_akteladasFt: integer;

  _megnyitottnap,_farok,_tipus,_penztar,_aktdnem: string;
  _bizonylatszam,_kftnev,_utbiz,_homepenztarkod: string;

  _top,_height,_width,_left: word;
  _idOke,_xx,_printer,_homepenztarszam: byte;

  _kertev,_kertho,_tolnap,_ignap: word;
  _tolstring,_igstring,_szuro,_pcs: string;
  _homepenztarnev,_homepenztarcim,_cegnev,_idsz: string;
  _sorveg: string = chr(13)+chr(10);

  _LFile: textfile;


function idoszakrutin: integer; stdcall; external 'c:\valuta\bin\idoszak.dll' name 'idoszakrutin';

function forgosszrutin: integer; stdcall;

implementation
{$R *.dfm}

function forgosszrutin: integer; stdcall;
begin
  ValutaOsszesitoForm := TValutaOsszesitoForm.create(Nil);
  result := ValutaOsszesitoForm.ShowModal;
  ValutaOsszesitoForm.Free;
end;


// =============================================================================
           procedure TVALUTAOSSZESITOFORM.FormActivate(Sender: TObject);
// =============================================================================


begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _top    := round((_height-768)/2);
  _left   := round((_width-1024)/2);

  Top     := _top;
  Left    := _left;

  CsikPanel.Visible        := False;
  TeljforgLabel.Visible    := False;
 
  InterVallumPanel.Visible := False;

  Alapadatbeolvasas;
  _mResult := 2;
  _idoke :=idoszakrutin;
  if _idoke=2 then
    begin
      Kilepo.enabled := true;
      exit;
    end;

  GetKertdatumAdatok;

  TolPanel.Caption := _tolstring;
  IgPanel.Caption  := _igstring;
  with IntervallumPanel do
    begin
      top := 80;
      left := 240;
      Visible := true;
    end;
  FORGALOMOSSZESITO;
end;


procedure  TVALUTAOSSZESITOFORM.AlapadatBeolvasas;

begin
  Valutadbase.connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := FieldByNAme('MEGNYITOTTNAP').asString;
      _printer := FieldByNAme('PRINTER').asInteger;
      _kftnev := trim(FieldByName('KFTNEV').asString);
      Close;

      Sql.clear;
      sql.Add('SELECT * FROM PENZTAR');
      Open;
      _homepenztarkod := trim(FieldByNAme('PENZTARKOD').asString);
      _homepenztarnev := trim(FieldbyName('PENZTARNEV').AsString);
      _homepenztarCim := trim(FieldByName('PENZTARCIM').AsString);
      Close;

    end;
  Valutadbase.close;
  val(_homepenztarkod,_homepenztarszam,_code);

  if _homepenztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT.';
    end else
    begin
      _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
    end;

end;


// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//                                TELJES FORGALOM ÖSSZESITÖ
// =============================================================================
       procedure TVALUTAOSSZESITOFORM.FORGALOMOSSZESITO;
// =============================================================================


begin
  Nullazas;

  Csik.Position := 0;
  with CsikPanel do
    begin
      top := 672;
      Left := 120;
      Visible := true;
    end;

  // A gyüjtö adatbázisok nevének meghatározása:

  _farok := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);
  _fejtombnev := 'BF' + _farok;
  _tetTombNev := 'BT' + _farok;

  valdataDbase.Connected := true;
  ValdataTabla.close;
  ValdataTabla.tableName := _fejtombnev;
  if not Valdatatabla.exists then
    begin
      Valdatadbase.close;
      ShowMessage('NINCS ADAT A KÉRT HÓNAPRÓL');
      Kilepo.Enabled := true;
      exit;
    end;

  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM '+ _fejTombNev+' FEJ JOIN ' + _tetTombNev+' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.DATUM>=' +chr(39) + _tolstring + chr(39) +') ';
  _pcs := _pcs + ' AND (FEJ.DATUM<=' + chr(39)+_igstring+chr(39)+')';
  _pcs := _pcs + ' AND (FEJ.STORNO=1)';

  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _rekdarab := recno;
    end;

  if _rekdarab=0 then
    begin
      ValdataQuery.close;
      Valdatadbase.close;
      ShowMessage('NINCS ADAT A KÉRT IDÕSZAKRÓL');
      Kilepo.Enabled := true;
      Exit;
    end;

// ======================= fejciklus =================================

  // Innen kezdjük a havi gyüjtök adatait feldolgozni:

  ValDataQuery.First;
  Csik.Max := _rekdarab;

  TeljforgLabel.Top     := 672;
  TeljforgLabel.Visible := true;
  TeljForgLabel.Repaint;

  _utbiz := 'XXXX';
  _vKer := 0;
  _eKer := 0;
  _aktrek := 0;
  while not ValdataQuery.eof do
    begin
      inc(_aktrek);
      Csik.Position := _aktrek;

    // Fejböl a 3 fontos adat kiolvasása:

      with ValdataQuery do
        begin
          _bizonylatszam := FieldByName('BIZONYLATSZAM').asString;
          _kerekites     := FieldbyName('KEREKITES').asInteger;
          _tipus         := FieldByName('TIPUS').AsString;
          _penztar       := FieldByName('TARSPENZTARKOD').AsString;
          _aktdnem       := FieldByNAme('VALUTANEM').asString;
          _aktBankjegy   := FieldbyNAme('BANKJEGY').AsInteger;
          _aktertek      := FieldByName('FORINTERTEK').asInteger;
        end;

      _xx := scandnem(_aktdnem);
      if (_aktdNem<>'HUF') then
        begin
          if _tipus='V' then
            begin
              _vetel[_xx] := _vetel[_xx] + _aktbankjegy;
              _vetelFt[_xx]:= _vetelFt[_xx] + _aktertek;
              if _utbiz<>_bizonylatszam then _Vker := _vKer + _kerekites;
            end;

          if _tipus='E' then
            begin
              _eladas[_xx] := _eladas[_xx] + _aktbankjegy;
              _eladasFt[_xx] := _eladasFt[_xx] + _aktertek;
              if _utbiz<>_bizonylatszam then _eker := _eKer + _kerekites;
            end;
        end;

      if _tipus='U' then _atvett[_xx] := _atvett[_xx] + _aktbankjegy;
      if _tipus='F' then _atadott[_xx] := _atadott[_xx] + _aktbankjegy;

      _utbiz := _bizonylatszam;

      ValdataQuery.next;
    end;

  ValdataQuery.close;
  ValdataDbase.close;

  Assignfile(_LFile,'c:\valuta\aktlst.txt');
  Rewrite(_LFile);

  Kozepreir(_cegnev);
  KozepreIr(_homePenztarnev);
  Kozepreir(_homepenztarcim);
  writeLn(_LFile,dupestring('-',40));

  _idsz := _tolstring+' es '+ _igstring+' kozotti';
  KozepreIr(_idsz);
  Kozepreir('Valuta forgalom');
  writeLn(_LFile,' ');

  writeLn(_LFile,dupestring('-',40));
  writeLn(_LFile,'Valutanem    Vasarolva    Forintertek');
  writeLn(_LFile,dupestring('-',40));

// 1234567890123456789012345678901234567890
//
//        Valutavetel az ugyfelektol
// -----------------------------------------
// Valutanem    Vasarolva    Forintertek
// -----------------------------------------
//    USD      123 456 678   123 456 789
//    EUR      123 456 789   123 456 789
// -----------------------------------------
//   Valuta vetel osszesen:  123 456 784 Ft
// -----------------------------------------
//        Valuta eladas az ugyfeleknek
// -----------------------------------------
// Valutanem     Eladva      Forintertek
// -----------------------------------------
//    USD      123 456 678   123 456 789
//    EUR      123 456 789   123 456 789
// -----------------------------------------
//  Valuta eladas osszesen:  123 456 784 Ft
// -----------------------------------------
//      Penztárak kozotti penzforgalom
// -----------------------------------------
// Valutanem      Atadva        Atveve
//    USD      123 456 678   123 456 789
//    EUR           -        123 456 789
//    AUD      123 456 789        -
// -----------------------------------------

   _sumvetel := 0;
   _xx := 1;
   while _xx<=27 do
     begin
       _aktdnem := _dnem[_xx];
       if _aktdnem='HUF' then
         begin
           inc(_xx);
           Continue;
         end;

       _aktvetel := _vetel[_xx];
       _aktvetelFt := _vetelft[_xx];
       _sumvetel := _sumvetel + _aktvetelFt;
       if _aktvetel>0 then
          writeLn(_LFile,'   '+_aktdnem+'      '+ftform(_aktvetel)+'   '+ftform(_aktvetelft));
       inc(_xx);
     end;
   if _vker>=0 then _vkers := '+'+inttostr(_vker) else _vKers := inttostr(_vker);
   writeLN(_LFile,'Forint kerekites                   '+_vkers);

   writeLn(_LFile,dupestring('-',40));
   writeLn(_LFile,'  Valuta vetel osszesen:  '+ftform(_sumvetel+_vker)+' Ft');
   writeLn(_LFile,dupestring('-',40));

   // ---------------------------------------------------------------

   writeLn(_LFile,'       Valuta eladas az ugyfeleknek');
   writeLn(_LFile,dupestring('-',40));
   writeLn(_LFile,'Valutanem     Eladva      Forintertek');
   writeLn(_LFile,dupestring('-',40));

   _sumeladas := 0;
   _xx := 1;
   while _xx<=27 do
     begin
       _aktdnem := _dnem[_xx];
       if _aktdnem='HUF' then
         begin
           inc(_xx);
           Continue;
         end;

       _akteladas := _eladas[_xx];
       _akteladasFt := _eladasft[_xx];
       _sumeladas := _sumeladas + _akteladasFt;
       if _akteladas>0 then
          writeLn(_LFile,'   '+_aktdnem+'      '+ftform(_akteladas)+'   '+ftform(_akteladasft));
       inc(_xx);
     end;

   if _eker>=0 then _ekers := '+'+inttostr(_eker) else _eKers := inttostr(_eker);
   writeLN(_LFile,'Forint kerekites                   '+_ekers);

   writeLn(_LFile,dupestring('-',40));
   writeLn(_LFile,' Valuta eladas osszesen:  '+ftform(_sumEladas+_eker)+' Ft');
   writeLn(_LFile,dupestring('-',40));

   writeLn(_LFile,'     Penztárak kozotti penzforgalom');
   writeLn(_LFile,dupestring('-',40));
   writeLn(_LFIle,'Valutanem      Atadva        Atveve');
   writeLn(_LFile,dupestring('-',40));

   _xx := 1;
   while _xx<=27 do
     begin
       _aktatadott := _atadott[_xx];
       _aktatvett  := _atvett[_xx];

       if (_aktatadott>0) or (_aktatvett>0) then
         begin
           _aktdnem := _dnem[_xx];
           write(_LFile,'   ' + _aktdnem + '      ');
           write(_Lfile,ftform(_aktatadott) + '   ');
           writeLn(_LFile,ftform(_aktatvett));
         end;
       inc(_xx);
     end;

  writeln(_LFile,dupestring('-',39));
  writeLn(_Lfile,_sorveg+_sorveg+_sorveg);
  CloseFile(_LFile);

  Csikpanel.Visible := False;

  Textkiiro;
  _mResult := 1;
  Kilepo.Enabled := true;

end;


function TValutaOsszesitoForm.Scandnem(_adn: string): byte;

var _y: byte;

begin
  result :=0 ;
  _y := 1;
  while _y<=27 do
    begin
      if _dnem[_y]=_adn then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;



// =============================================================================
         procedure TVALUTAOSSZESITOFORM.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;





function TValutaOsszesitoForm.Ftform(_n: integer): string;

var _ns: string;
    _ws,_f1: byte;

begin
  if _n=0 then
    begin
      result := '     -     ';
      exit;
    end;
  _ns := inttostr(_n);
  _ws := length(_ns);
  if _ws>6 then
    begin
      _f1 := _ws-6;
      _ns := leftstr(_ns,_f1)+' '+midstr(_ns,_f1+1,3)+' '+midstr(_ns,_f1+4,3);
      while length(_ns)<11 do _ns := ' '+_ns;
      result := _ns;
      exit;
    end;
  if _ws>3 then
    begin
      _f1 := _ws-3;
      _ns := leftstr(_ns,_f1)+' '+midstr(_ns,_f1+1,3);
    end;
  while length(_ns)<11 do _ns := ' '+_ns;
  result := _ns;
end;



procedure TValutaOsszesitoForm.GetKertdatumAdatok;

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add('SELECT * FROM IDOSZAK');
      Open;
      _kertev := FieldbyName('KERTEV').asInteger;
      _kertho := FieldbyName('KERTHO').asInteger;
      _tolnap := FieldbyName('TOLNAP').asInteger;
      _ignap  := FieldbyName('IGNAP').asInteger;
      _tolstring := FieldbyName('TOLSTRING').asString;
      _igstring := FieldByName('IGSTRING').asString;
      Close;
    end;
  Valutadbase.close;
end;



procedure TVALUTAOSSZESITOFORM.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := false;
  Modalresult := _mResult;
end;


procedure TVALUTAOSSZESITOFORM.Nullazas;

begin
  _xx := 1;
  while _xx<=27 do
    begin
      _vetel[_xx]  := 0;
      _eladas[_xx] := 0;
        _vetelft[_xx]  := 0;
      _eladasft[_xx] := 0;
      _atadott[_xx] := 0;
      _atvett[_xx] := 0;
      inc(_xx);
    end;
end;


// =============================================================================
               procedure TVALUTAOSSZESITOFORM.TextKiiro;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else AssignPrn(_nyomtat);
  Rewrite(_nyomtat);
  AssignFile(_olvas,'c:\valuta\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;

end.
