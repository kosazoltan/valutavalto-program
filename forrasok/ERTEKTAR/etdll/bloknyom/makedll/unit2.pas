unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls,
  strutils, printers, dateutils;

type
  TBLOKKNYOM = class(TForm)
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    kilepotimer: TTimer;
    Shape1: TShape;
    Label1: TLabel;

    procedure FormActivate(Sender: TObject);


    // A nyomtatáshoz szükséges adatok beolvasásasa:

    procedure GetVtempBasic;
    procedure GetPenztarData;

    // Cimlet nyomtatas procedurai:

    function CimletBedolgozas: boolean;
    function Getword: word;
    function Getbyte: byte;
    procedure CimletNyomtatas;

    // Ötféle számla nyomtatása:

    procedure AtadBlokkNyomtatas;
    procedure AtveszBlokkNyomtatas;
    procedure StornoBlokknyomtatas;
    procedure WuAfaNyomtatas;
    procedure EkerNyomtatas;
    procedure KezdijNyomtatas;
    procedure WUKeszletNyomtatas;


    // storno

    procedure WuAfaStornoBlokk;


    // Bizonylat részlet nyomtatások:


    procedure BlokkFocimIro;
    procedure BlokkFejlecIro;
    procedure BlokkTetelIro;

    // Segéd programok

    procedure VonalHuzo;
    procedure KozepreIr(_szoveg: string);
    procedure TextKiiro;
    procedure KilepotimerTimer(Sender: TObject);
    procedure Soremeles;
    procedure startNyomtatas;
    function FtForm(_num: integer;_btip: string): string;

    // Segéd funkciók:

    function Elokieg(_s:string;_h: byte):string;
    function HunDateTostr(_caldat: TDateTime): string;
    function ForintForm(_osszeg:integer):string;
    function ArfolyamForm(_curr: real): string;
    function Nulele(_i: integer):string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BLOKKNYOM: TBLOKKNYOM;

  _cimDataPath   : string = 'c:\ertektar\aktcim.dat';
  _binOlvas      : File of byte;
  _bytetomb      : array[1..16] of byte;

  _nyomTipus     : byte;      // ha nagyobb 10-nél, akkor másolat
 
  _mondat        : string;
  _mamas         : string;
  _LFile         : textfile;
  _printer       : byte;
  _wideon        : string = #14;
  _wideoff       : string = #20;

  _Lf5           : string = #27#97#5;

  _pcs           : string;
  _sorveg: string = chr(13) + chr(10);

  _forintszamla  : boolean;
  _masolat       : boolean;

  // penztar adatai:

  _aktpenztarszam: byte;
  _aktPenztarkod : string;
  _aktpenztarnev : string;
  _aktpenztarcim : string;
  _akttelefon    : string;
  _aktadoszam    : string;
  _cardnums      : string;
  _cegnev        : string;
  _kftnev        : string;
  _trb           : string;

  _yValDarab     : integer;
  _yNev          : array[1..3] of string;
  _yCdb          : array[1..3] of byte;
  _yC,_yB        : array[1..3,1..14] of word;

  // Tulajdonosok adatai

  _vanCimlet      : boolean;
  _datum          : string;
  _ido            : string;
  _bizonylatszam  : string;
  _tipus          : string;
  _ftipus         : string;

  _tetel          : byte;
  _storno         : byte;
  _width          : word;
  _height         : word;
  _qq             : integer;
  _recno          : integer;
  _osszforint     : integer;
  _bankjegy       : integer;

  _netto          : integer;
  _kezelesidij    : integer;
  _penztarnev     : string;

  _code           : integer;
  _osszesforint   : integer;

  _aktdnem        : string;
  _aktarfolyam    : integer;
  _arfolyam       : integer;
  _arfolyamreal   : integer;
  _aktbankjegy    : integer;
  _aktertek       : integer;
  _elojel         : string;
  _totarfs        : string;

  _adoszam        : string;
  _megnyitottnap  : string;

  _penztarkod     : string;
  _szallitonev    : string;
  _plombaszam     : string;
  _forras         : string;
  _nyil           : string;

  _lmezo          : string;
  _tmezo          : string;
  _amezo          : string;

  _stornoBizonylat: string;
  _megjegyzes     : string;
  _reprintindok   : string;
  _stornoindok    : string;
  _tranznev       : string;
  _tranztipus     : string;
 

  _akttort        : string;

  _nyomtatvanyPath    : string = 'C:\ERTEKTAR\AKTLST.TXT';

function blokknyomtatas(_para: integer): integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
        function blokknyomtatas(_para: integer): integer; stdcall;
// =============================================================================

// Parameter ha nagyobb 1-nél akkor másolat

begin
  Blokknyom  := TBlokknyom.create(Nil);
  _nyomtipus := _Para;
  result     := Blokknyom.showmodal;
  Blokknyom.Free;
end;


// =============================================================================
               procedure TBLOKKNYOM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _masolat := False;
  if _nyomtipus>1 then _masolat := True;

   _width := Screen.Monitors[0].Width;
   _height:= Screen.Monitors[0].Height;

   top := trunc((_height-90)/2);
   Left := trunc((_width-280)/2);
   Visible := true;
   Repaint;


   // --------------------------------------------------------------------------
   // Beolvassa a pénztár nevét, cimet, adoszámát, pénztáros nevét
   // printer tipusát, kft nevét:

   GetPenztarData;

   // Beolvassa: datum,ido,tipus,netto,fizetendo, kezelesidij,bizonylatszam
   // konverzio,storno,tetel,elojel,penztarkod,stornobizonylat,szallitonev,
   // plombaszam,megjegyzes,reprintindok,stornoindok,tarspenztarnev,

   GetVTempBasic;
   _vanCimlet := False;

   if _storno=3 then
     begin
       StornoBlokknyomtatas;
       KilepoTimer.Enabled := True;
       exit;
     end;

   if FileExists(_cimDataPath) then _vancimlet := Cimletbedolgozas;

   if _tipus='F' then AtadBlokkNyomtatas;
   if _tipus='U' then AtveszBlokkNyomtatas;
   if _tipus='W' then WuAfaNyomtatas;
   if _tipus='E' then Ekernyomtatas;
   IF _tipus='K' then KezdijNyomtatas;
   if _tipus='Q' then WuKeszletNyomtatas;

   Kilepotimer.enabled := true;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//$$$$$$$$$$$$$$$$$$$$$$  ADATOK BEOLVASASA $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                   procedure TBlokknyom.GetVtempBasic;
// =============================================================================

begin
  Valutadbase.Connected := true;
  with valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
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

  with Valutaquery do
    begin

      _datum := trim(FieldByname('DATUM').AsString);
      _ido   := trim(FieldByName('IDO').AsString);
      _tipus := trim(FieldByName('TIPUS').AsString);
      _bizonylatszam  := FieldByNAme('BIZONYLATSZAM').asstring;
      _tranztipus := trim(FieldByName('TRANZTIPUS').AsString);
      _bankjegy   := FieldByName('BANKJEGY').asInteger;
      _aktdnem    := FieldByNAme('VALUTANEM').asString;

      _storno         := FieldByName('STORNO').asInteger;
      _tetel          := FieldByName('TETEL').asInteger;
      _elojel         := FieldByNAme('ELOJEL').asString;
      _penztarkod     := FieldByName('PENZTARKOD').asString;
      _trb            := trim(FieldByName('TRBPENZTAR').AsString);
      _stornobizonylat:= trim(FieldByName('STORNOBIZONYLAT').asString);
      _szallitonev    := trim(FieldByName('SZALLITONEV').asstring);
      _plombaszam     := TRIM(FieldByName('PLOMBASZAM').asstring);
      _megjegyzes     := trim(FieldByNAme('MEGJEGYZES').asString);
      _reprintindok   := trim(FieldByName('COPYINDOK').asString);
      _stornoindok    := trim(FieldByName('STORNOINDOK').asstring);
      _penztarnev     := trim(Fieldbyname('TARSPENZTARNEV').AsString);
      _osszforint     := FieldByNAme('OSSZESFORINTERTEK').asInteger;
     
      next;
    end;

  ValutaQuery.close;
  Valutadbase.close;
end;


// =============================================================================
                     procedure TBlokkNyom.GetPenztarData;
// =============================================================================

begin
  _pcs := 'SELECT * FROM PENZTAR';
  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Open;
      _aktPenztarkod  := trim(FieldByNAme('PENZTARKOD').asstring);
      _aktPenztarNev  := trim(FieldByName('PENZTARNEV').asString);
      _aktpenztarCim  := trim(FieldByName('PENZTARCIM').asstring);
      _aktTelefon     := trim(FieldByName('TELEFONSZAM').AsString);
      Close;
    end;

  val(_aktpenztarkod,_aktpenztarszam,_code);

  // ---------------------------------------------------------------

  _pcs := 'SELECT * FROM HARDWARE';
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Open;
      _mamas   := fieldByName('MEGNYITOTTNAP').asString;
      _KFTNev  := trim(FieldByName('KFTNEV').asString);
      _printer := FieldByNAme('PRINTER').asInteger;
      Close;
    end;
  ValutaDbase.close;

  if _kftnev='BEST' then _aktadoszam := '32313332-2-02';
  _cegnev      := 'EXCLUSIVE BEST CHANGE ZRT.';
end;



// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$ CIMLET PROCEDURÁK  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                function TBlokkNyom.CimletBedolgozas: boolean;
// =============================================================================

var _vnev : string;
    _cc,_z,_p,_vcdb: byte;
    _zz   : word;

begin
  Result := false;
  Assignfile(_binolvas,_cimDataPath);
  Reset(_binolvas);
  Blockread(_binolvas,_bytetomb,1);

  _yValDarab := _byteTomb[1];

  _cc := 1;
  while _cc<=_yValdarab do
    begin
      Blockread(_binolvas,_bytetomb,3);

      _vnev := chr(255-_bytetomb[1])+chr(255-_bytetomb[2])+chr(255-_bytetomb[3]);
      _yNev[_cc] := _vNev;

      Blockread(_binolvas,_bytetomb,1);
      _vcdb := _bytetomb[1];
      _yCdb[_cc] := _vcdb;

      _p := 1;
      while _p<=_vcdb do
        begin
          _yC[_cc,_p] := getword;
          _yB[_cc,_p] := getword;
          inc(_p);
        end;
      _z := getbyte;
      if _z<255 then
        begin
          CloseFile(_binolvas);
          exit;
        end;
      inc(_cc);
    end;
  _z := getbyte;
  _zz := _z + Getbyte;
  CloseFile(_binolvas);
  if _zz<>510 then exit;
  result := true;
end;

// =============================================================================
                      function TBlokknyom.Getword: word;
// =============================================================================

begin

  Blockread(_binolvas,_bytetomb,2);
  result := _bytetomb[1]+trunc(256*_bytetomb[2]);
end;


// =============================================================================
                    function TBlokknyom.GetByte: byte;
// =============================================================================

begin
  Blockread(_binolvas,_bytetomb,1);
  result := _bytetomb[1];
end;


// =============================================================================
                   procedure TBlokkNyom.CimletNyomtatas;
// =============================================================================


var _sor,_vNev: string;
    _p,_cc,_vcdb,_sdb: byte;
    _cim,_bjy: word;

begin
  Cimletbedolgozas;
  WriteLn(_LFile,'        Cimletezes - denominations:'+_sorveg);
  _cc := 1;
  while _cc<=_yValDarab do
    begin
      _vNev:= _yNev[_cc];
      write(_LFile,_vNev + ': ');
      _sor := '';
      _vcdb := _yCdb[_cc];
      _p := 1;
      _sdb := 0;
      while _p<=_vcdb do
        begin
          _cim := _yC[_cc,_p];
          _bJy := _yB[_cc,_p];
          _sor := _sor + inttostr(_cim)+'='+inttostr(_bjy)+',';
          inc(_sdb);
          if _sdb=4 then
            begin
              writeLn(_LFile,_sor);
              _sdb := 0;
              _sor := '';
            end;
          inc(_p);
        end;
      if _sor<>'' then writeln(_LFile,'    '+_sor);
      inc(_cc);
    end;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$ BLOKKNYOMTATAS $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// =============================================================================
               procedure TBLOKKNYOM.AtadBlokkNyomtatas;
// =============================================================================

begin
  if _storno=3 then
     begin
       StornoBlokknyomtatas;
       KilepoTimer.Enabled := True;
       exit;
     end;

  BlokkFocimiro;

  writeLn(_LFile,_wideon + '  Penztari atadas' + _wideoff + _sorveg);
  writeLn(_LFile,'Atvevo: ' +  _penztarkod + ' - ' + _PenztarNev);

  if _trb<>'' then Kozepreir('(TRB penztar: '+ _trb+')');

  if _masolat then
    begin
      writeLn(_LFile,' ');
      Kozepreir('M Á S O L A T I   P É L D Á N Y');
      writeLn(_LFile,' ');
    end;

  BlokkFejlecIro;
  BlokkTetelIro;

  writeLn(_LFile,'SZALLITO NEVE: ' + _szallitoNev);
  writeLn(_LFile,'PLOMBA SZAMA : ' + _plombaSzam);

  if _megjegyzes<>'' then writeLN(_LFile,'Megjegyzes: '+_megjegyzes);
  writeLN(_LFile,_sorveg);

  writeLn(_LFile,dupestring('.',18)+'     '+ dupestring('.',18));
  writeLn(_Lfile,'       atado'+dupestring(' ',15) + 'atvevo');

  StartNyomtatas;
end;

// =============================================================================
             procedure TBLOKKNYOM.AtveszBlokkNyomtatas;
// =============================================================================

begin
  if _storno=3 then
     begin
       StornoBlokknyomtatas;
       KilepoTimer.Enabled := True;
       exit;
     end;

  BlokkFocimiro;

  writeLn(_LFile,_wideon+'  Penztari atvetel' + _wideoff + _sorveg);
  writeLn(_LFile,'Atado: '+ _PenztarKod+ ' - ' +_PenztarNev);

  if _trb<>'' then Kozepreir('(TRB penztar: '+ _trb+')');

  if _masolat then
    begin
      writeLn(_LFile,' ');
      Kozepreir('M Á S O L A T I   P É L D Á N Y');
      writeLn(_LFile,' ');
    end;

  BlokkFejlecIro;
  BlokkTetelIro;

  writeLn(_LFile,'SZALLITO NEVE: ' + _szallitoNev);
  writeLn(_LFile,'PLOMBA SZAMA : ' + _plombaSzam);

  if _megjegyzes<>'' then writeLN(_LFile,'Megjegyzes: '+_megjegyzes);
  writeLN(_LFile,_sorveg);

  // 123456789012345678901234567890123456789
  // Büntetö felelösségem tudatában kijelen-
  // tem, hogy a fentiekben felsorolt pénz-
  // készletet a szállitóktól átvettem, azt
  //         tételesen átszámoltam.

  writeLn(_LFIle,'Büntetö felelösségem tudatában kijelen-');
  writeLn(_LFIle,'tem,  hogy a fentiekben felsorolt pénz-');
  writeLn(_LFIle,'készletet a szállitóktól átvettem,  azt');
  writeLn(_LFIle,'        tételesen átszámoltam.');


  writeLN(_LFile,_sorveg);
  writeLn(_LFile,dupeString('.',18)+'     '+ dupeString('.',18));
  writeLn(_Lfile,'       atado'+dupestring(' ',15) + 'atvevo');

  StartNyomtatas;
 

end;

// =============================================================================
               procedure TBlokknyom.StornoBlokknyomtatas;
// =============================================================================

begin
  if _tipus='W' then
    begin
      WuAfaStornoBlokk;
      exit;
    end;

  if _tipus='F' then _tranztipus := 'deviza atadas';
  if _tipus='U' then _tranztipus := 'deviza atvetel';

  Sysutils.DeleteFile(_nyomtatvanyPath);
  AssignFile(_LFile,_nyomtatvanyPath);
  Rewrite(_LFile);

  writeLN(_LFile,_wideon+'STORNO BIZONYLAT'+_wideOff);
  writeLn(_Lfile,' ');

  if _masolat then
    begin
      writeLn(_LFile,' ');
      Kozepreir('M Á S O L A T I   P É L D Á N Y');
      writeLn(_LFile,' ');
    end;

  Kozepreir(_cegnev);
  Kozepreir(_aktpenztarkod + ' ' + _aktpenztarnev);
  KozepreIr('Telefon: ' + _aktTelefon);
  Kozepreir('Adoszam: ' + _aktadoszam);
  writelN(_Lfile,dupestring('-',40));

  writeLn(_LFile,'       Bizonylatszam: ' + _bizonylatszam);
  writeLn(_LFile,'               Datum: ' + _datum);
  writeLn(_Lfile,'                 Ido: ' + _ido);
  writelN(_Lfile,dupestring('-',40));

  writeLN(_LFile,'       A stornozott bizonylat adatai:');
  writeLn(_LFile,'       ------------------------------');

  Kozepreir('Eredeti bizonylatszam: '+_stornobizonylat);
  Kozepreir('Tranzakcio tipusa: '+ _tranztipus);
  Kozepreir('Bizonylat forinterteke: ' + trim(forintForm(_osszforint)));
  Kozepreir('Stornozas indoka: ' + _stornoIndok);
  Kozepreir('Stornozast vegezte:');
  vonalhuzo;
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  writeLn(_LFile,dupestring('.',40));
 
  StartNyomtatas;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$  RÉSZADAT NYOMTATÁSOK $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


// =============================================================================
                  procedure TBLOKKNYOM.BlokkFocimIro;
// =============================================================================

begin
  Sysutils.DeleteFile(_nyomtatvanyPath);
  AssignFile(_LFile,_nyomtatvanyPath);
  Rewrite(_LFile);

  VonalHuzo;
  KozepreIr(_cegnev);
  Kozepreir(_aktpenztarkod+'. '+_aktpenztarnev);
  Kozepreir(_aktpenztarcim);
  Kozepreir('Adoszam: ' + _AKTADOSZAM);
  if _akttelefon<>'' then KozepreIr('Tel: '+ _aktTelefon);
end;

// =============================================================================
                       procedure TBLOKKNYOM.BlokkFejlecIro;
// =============================================================================

begin
  Vonalhuzo;

  writeLn(_LFile,'Sorszam   (INVOICE NR)    :   ' + _bizonylatSzam);
  writeLN(_LFile,'Datum     (DATE)          :   ' +  _datum);
  writeLn(_Lfile,'Ido       (TIME)          :     ' + _ido);

  vonalhuzo;

  if _storno=2 then
    begin
      writeLn(_LFile,'      S T O R N O Z O T T   B L O K K');
      if _stornoindok<>'' then KozepreIr('Storno indoka: '+trim(_stornoIndok)+')');
    end;

  writeLn(_LFile,'Adomentes               Szj - 67.13.10.0');

  VonalHuzo;
  writeLn(_LFile,'V.nem    Arf.       B.jegy       Forint');
  writeLn(_LFile,'CURR.    RATE        CASH        VALUE');
  VonalHuzo;
end;

// =============================================================================
                          procedure TBLOKKNYOM.BlokkTetelIro;
// =============================================================================

var _akttort: string;


begin

  Valutadbase.Connected := true;

  _pcs := 'SELECT * FROM VTEMP' + _sorveg;
  _pcs := _pcs + 'WHERE (BANKJEGY>0)';
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.Eof do
    begin
      _aktDnem := ValutaQuery.FieldByName('VALUTANEM').asString;
      if _aktDnem='' then
        begin
          ValutaQuery.Next;
          Continue;
        end;

      with ValutaQuery do
        begin
          _aktArfolyam := FieldByName('ARFOLYAM').asInteger;
          _aktBankjegy := FieldByNAme('BANKJEGY').asInteger;
          _aktertek    := FieldByNAme('FORINTERTEK').asInteger;
          _akttort     := trim(FieldByName('TORTRESZ').asstring);
        end;

      while length(_akttort)<4 do _akttort := _akttort + '0';
      _totarfs := inttostr(_aktarfolyam)+'.'+_akttort;

      while length(_totarfs)<10 do _totarfs := ' ' + _totarfs;

      write(_LFile,_aktDnem + '  ');
      write(_LFile,_totarfs+' ');
      write(_LFile,eloKieg(forintForm(_aktBankjegy),11)+'  ');
      writeLN(_LFile,eloKieg(forintForm(_aktertek),11));

      ValutaQuery.Next;
    end;

  ValutaQuery.close;
  ValutaDbase.close;

  // ---------------------------------------------------------------------------

  VonalHuzo;
  write(_LFile,'Kifizetve:(PAID): ');
  WriteLN(_LFile,_wideon+elokieg(forintForm(_osszforint),11)+_wideoff);

  VonalHuzo;
end;


// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$ SEGÉD  - PROGRAMOK $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                          procedure TBLOKKNYOM.VonalHuzo;
// =============================================================================

begin
  writeLn(_Lfile,dupeString('-',40));
end;

// =============================================================================
                     procedure TBlokknyom.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;


// =============================================================================
                            procedure TBlokknyom.TextKiiro;
// =============================================================================

var
    _nyomtat,_olvas: textFile;

begin
  if _printer<>1 then AssignFile(_nyomtat,'LPT1:')
  else AssignPrn(_nyomtat);
  Rewrite(_nyomtat);
  AssignFile(_olvas,_nyomtatvanypath);
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;


// =============================================================================
             procedure TBLOKKNYOM.kilepotimerTimer(Sender: TObject);
// =============================================================================

begin
  Kilepotimer.Enabled := false;
  Modalresult := 1;
end;

// =============================================================================
                      procedure TBlokknyom.soremeles;
// =============================================================================

begin
  writeLn(_LFile,' ');
end;


// =============================================================================
                      procedure TBLOKKNYOM.StartNyomtatas;
// =============================================================================

begin
  Writeln(_LFile,_sorveg);
  writeLn(_Lfile,' ');
  writeLn(_Lfile,' ');
  writeLn(_Lfile,' ');
  writeLn(_Lfile,' ');
  writeLn(_Lfile,' ');
  writeLn(_Lfile,' ');
  writeLn(_Lfile,' ');
  writeLn(_LFile,'...');
  WriteLn(_LFile,chr(26));
  CloseFile(_LFile);
  TextKiiro;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$ SEGÉD FUNKCIÓK $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
            function TBlokknyom.Elokieg(_s:string;_h: byte):string;
// =============================================================================

begin

  result := _s;
  while length(result)<_h do  result := ' '+result;
end;

// =============================================================================
         function TBlokkNyom.Hundatetostr(_caldat: TdateTime): string;
// =============================================================================

var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;


// =============================================================================
             function TBlokknyom.ForintForm(_osszeg:integer):string;
// =============================================================================

var _slen,_pp: integer;
    _ejel : string;

begin
  Result := '-';

  if _osszeg=0 then exit;

  _ejel := '';

  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;

  Result := intTostr(_osszeg);

  if _osszeg<1000 then
    begin
      Result := _ejel + Result;
      Exit;
    end;

  _sLen := length(Result);
  if _osszeg>999999 then
    begin
      _pp := _sLen-5;
      Result := _ejel + midStr(Result,1,_pp-1)+','+midStr(Result,_pp,3)+','+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := _ejel + midStr(result,1,_pp-1)+','+midStr(result,_pp,3);

end;


// =============================================================================
               function TBlokknyom.ArfolyamForm(_curr: real): string;
// =============================================================================

var
    _rs: string;
    _w1,_pos,_tdb,_need0: byte;

begin
  // _curr : 123.05
  _rs := floattostr(_curr);
  _w1 := length(_rs);
  _pos := Pos(',',_rs);

  if _pos=0 then
    begin
      _rs := _rs + '.0000';
      while length(_rs)<10 do _rs := ' ' + _rs;
      result := _rs;
      exit;
    end;
   _TDB := _w1-_pos;
   _need0 := 4-_tdb;
   if _need0>0 then _rs := _rs + dupestring('0',_need0);
   while length(_rs)<10 do _rs := ' '+_rs;
   result := _rs;
end;

// =============================================================================
               function TBlokkNyom.Nulele(_i: integer):string;
// =============================================================================

begin
  result := inttostr(_i);
  if _i<10 then result := '0' + result;
end;


procedure TBlokknyom.WuKeszletNyomtatas;

var _wusd,_whuf,_afa: integer;

begin
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM WUAFAADATOK');
      Open;
      _wusd := FieldByName('USDKESZLET').asInteger;
      _whuf := FieldByName('HUFKESZLET').asInteger;
      _afa  := FieldByName('AFAKESZLET').asInteger;
      Close;
    end;
  Valutadbase.close;

  BlokkFocimiro;
  VonalHuzo;

  Kozepreir('WESTERN UNION KÉSZLETEK:');
  writeLn(_LFile,' ');

  write(_LFile,dupestring(' ',11));
  writelN(_LFile,ftform(_wusd,'USD'));

  write(_LFile,dupestring(' ',11));
  writeLn(_Lfile,ftform(_whuf,'HUF'));
  writeLn(_Lfile,' ');
  kozepreir('AFA KÉSZLETEK:');
  writeLn(_Lfile,' ');

  write(_LFile,dupestring(' ',11));
  writeLn(_LFile,ftform(_afa,'HUF'));
  VonalHuzo;
  writeLn(_LFile,_mamas);
  writeln(_LFile,' ');

  StartNyomtatas;
end;


procedure TBlokknyom.WuafaNyomtatas;

var _fcim: string;

begin
  BlokkFocimiro;

   if _tranztipus='WU'  then
    begin
      if _elojel='+' then _fcim := 'ATVETEL WESTERN UNION PENZTARTOL'
      else _fcim := 'ATADAS WESTERN UNION PENZTARNAK';
    end else
    begin
      if _elojel='+' then _fcim := 'ATVETEL EGY AFA PENZTARTOL'
      else _fcim := 'ATADAS EGY AFA PENZTARNAK';
    end;

  writeLn(_LFile,' ');
  Kozepreir(_fcim);
  writeLn(_LFile,' ');

  writeLn(_LFile,'Partner: '+ _penztarkod+' '+_penztarnev);
  Vonalhuzo;

  if _masolat then
    begin
      writeLn(_LFile,' ');
      Kozepreir('M Á S O L A T I   P É L D Á N Y');
      writeLn(_LFile,' ');
    end;

  writeLn(_LFile,'  Bizonylatszam : ' + _bizonylatszam);
  if _elojel='+' then
    begin
      writeLn(_LFile,'  Atvetel kelte : '+_datum);
      writeLn(_LFile,'  Atvett osszeg : '+ftform(_bankjegy,_aktdnem));
    end else
    begin
      writeLn(_LFile,'   Atadas kelte : '+_datum);
      writeLn(_LFile,' Atadott osszeg : '+ftform(_bankjegy,_aktdnem));
    end;
  writeLn(_LFile,'  Szallito neve : ' + _szallitonev);
  writeLn(_LFile,'  Zsakplombaszam: ' + _plombaszam);
  writeLn(_lfile,'      Megjegyzes: ' + _megjegyzes);
  Vonalhuzo;
  writeLn(_LFile,_sorveg,_sorveg);
  writeLn(_Lfile,'.................   .................');
  writeLn(_Lfile,'       atado              atvevo');
  writeLn(_Lfile,_sorveg,_sorveg);
  Startnyomtatas; 
end;

function TBlokknyom.FtForm(_num: integer;_btip: string): string;

var _nums: string;
    _f1,_w1: byte;

begin
  result := '-';
  if _num=0 then exit;
  _nums := inttostr(_num);
  _w1 := length(_nums);
  if _w1<4 then
    begin
      result := _nums+' '+_aktdnem;
      exit;
    end;
  if _w1>6 then
    begin
      _f1 := _w1-6;
      result := leftstr(_nums,_f1)+' '+midstr(_nums,_f1+1,3)+' '+midstr(_nums,_f1+4,3);
      result := result + ' '+_btip;
      exit;
    end;
  _f1 := _w1-3;
  result := leftstr(_nums,_f1)+ ' '+midstr(_nums,_f1+1,3)+' '+_btip;
end;

procedure TBlokknyom.EkerNyomtatas;
begin
  Blokkfocimiro;

  if _elojel='+' then writeLn(_LFile,' E-KERESKEDELEM PENZATVETEL BIZONYLAT')
  else writeLn(_LFile,' E-KERESKEDELEM PENZATADASI BIZONYLAT');
  VonalHuzo;

  if _masolat then
    begin
      writeLn(_LFile,' ');
      Kozepreir('M Á S O L A T I   P É L D Á N Y');
      writeLn(_LFile,' ');
    end;

  writeLn(_Lfile,'      BIZONYLATSZAM: ' + _bizonylatszam);
  writeLn(_LFile,'              DATUM: ' + _datum);
  if _elojel='+' then
    begin
      writeLn(_LFile,'      ATADO PENZTAR: ' + _Penztarkod);
      writeLn(_LFile,'      ATVETT OSSZEG: ' + forintform(_bankjegy));
    end else
    begin
      writeLn(_LFile,'     ATVEVO PENZTAR: ' + _penztarkod);
      writeLn(_LFile,'     ATADOTT OSSZEG: ' + forintform(_bankjegy));
    end;

  Vonalhuzo;

  writeLn(_LFile,'SZALLITONEV: '+_szallitonev);
  writeLn(_LFile,' PLOMBASZAM: '+_plombaszam);
  writeLn(_LFile,' MEGJEGYZES: '+_megjegyzes);
  writeLn(_Lfile,_sorveg);

  writeLn(_Lfile,'..................  ...................');
  writeLn(_LFile,'       atado              atvevo');
  writeLn(_LFile,_sorveg+_sorveg);
  StartNyomtatas;
end;


procedure TBlokknyom.KezdijNyomtatas;
begin
  BlokkFocimiro;

  if _storno= 1 then
    begin
      if _elojel='+' then
         WriteLn(_LFile,' KEZELESI KOLTSEG ATVETELI BIZONYLATA')
      else WriteLn(_LFile,' KEZELESI KOLTSEG ATADASI BIZONYLATA');
    end else
    begin
      if _storno=2 then writeLn(_LFile,'    SZTORNOZOTT BIZONYLAT')
      else WriteLn(_LFile,' KEZELESI KOLTSEG SZTORNO BIZONYLATA');
    end;

  if _masolat then
    begin
      writeLn(_LFile,' ');
      Kozepreir('M Á S O L A T I   P É L D Á N Y');
      writeLn(_LFile,' ');
    end;

  if _storno=3 then _bankjegy := trunc((-1)*_bankjegy);

  VonalHuzo;
  writeLn(_LFile,'      Bizonylatszam: ' + _bizonylatszam);
  writeLn(_LFile,'    Bizonylat kelte: ' + _datum);

  IF _elojel='+' then
    write(_LFile,'      Atado penztar: ')
  else write(_LFile,'      Atvevo penztar: ');
  writeLn(_LFile,_penztarkod);

  if _elojel='+' then
     write(_LFile,'      Atvett osszeg: ')
  else write(_LFile,'     Atadott osszeg: ');

  writeLn(_LFile,forintform(_bankjegy)+' Ft');
  VonalHuzo;

  if _storno=1 then
    begin
      writeLn(_LFile,'Szallitonev: '+_szallitonev);
      writeLn(_LFile,'Plomba-szam: '+_plombaszam);
      writeLn(_LFile,' Megjegyzes: '+_megjegyzes);
      writeLn(_lFile,_sorveg+_sorveg);
      writeLN(_Lfile,'..................  ...................');
      writeLn(_LFile,'      atado                 atvevo     ');
      writeLn(_LFile,_sorveg);
    end else
    begin
      writeLN(_Lfile,'Stornozast vegezte:'+_sorveg+_sorveg);
      writeLn(_LFile,'.......................');
    end;

   StartNyomtatas; 
end;

// =============================================================================
                  procedure TBlokknyom.WuafaStornoBlokk;
// =============================================================================

var _fcim: string;

begin
  BlokkFocimiro;

   if _tranztipus='WU'  then
    begin
      if _elojel='-' then _fcim := 'WU. ATVETEL BIZONYLAT STORNÓJA'
      else _fcim := 'WU ATADAS BIZONYLAT STORNÓJA';
    end else
    begin
      if _elojel='-' then _fcim := 'AFA ATVETEL BIZONYLAT STORNOJA'
      else _fcim := 'AFA ATADAS BIZONYLAT STORNÓJA';
    end;

  writeLn(_LFile,' ');
  Kozepreir(_fcim);
  writeLn(_LFile,' ');

  writeLn(_LFile,'Partner: '+ _penztarkod+' '+_penztarnev);
  Vonalhuzo;
  Kozepreir('EREDETI BIZONYLAT:');
  writeLn(_LFile,'    Bizonylat száma: ' + _stornobizonylat);
  WriteLn(_LFile,'  Stornózott összeg: ' + ftform(_bankjegy,_aktdnem));

  writeLn(_Lfile,' ');
  KozepreIr('STORNÓ BIZONYLAT:');
  writeln(_LFile,' ');

  writeLn(_LFile,'      Bizonylatszám: ' + _bizonylatszam);
  writeLn(_LFile,'    Stornózás kelte: '+_datum);
  Vonalhuzo;
  writeLn(_LFile,' ');
  writeLn(_LFile,' ');
  writeLn(_LFile,dupestring('.',25));
  writeLn(_LFile,'   Stornózást végezte');

 startnyomtatas;
end;


end.
