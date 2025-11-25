unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DB, Grids, DBGrids, StrUtils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery, printers;

type
  TMatPenztar = class(TForm)

    BeBankSzamPanel          : TPanel;
    BeBizPanel               : TPanel;
    BevetelPanel             : Tpanel;
    BizonylatPanel           : TPanel;
    KeszletDisplayPanel      : TPanel;
    KiadasPanel              : TPanel;
    KibankSzamPanel          : TPanel;
    KibizPanel               : TPanel;
    MatricasPanel            : TPanel;
    PillKeszPanel            : TPanel;

    Label1                   : TLabel;
    Label2                   : TLabel;
    Label3                   : TLabel;
    Label4                   : TLabel;
    Label5                   : TLabel;
    Label6                   : TLabel;
    Label7                   : TLabel;
    Label8                   : TLabel;
    Label13                  : TLabel;
    Label16                  : TLabel;
    Label21                  : TLabel;
    Label22                  : TLabel;
    Label23                  : TLabel;
    Label24                  : TLabel;

    BeMegsemGomb             : TBitBtn;
    BeOkeGomb                : TBitBtn;
    BeVetGomb                : TBitBtn;
    BizonyLatGomb            : TBitBtn;
    BizVisszaGomb            : TBitBtn;
    KeszletGomb              : TBitBtn;
    KiMegsemGomb             : TBitBtn;
    KiOkeGomb                : TBitBtn;
    KiadGomb                 : TBitBtn;
    PillVisszaGomb           : TBitBtn;
    ReprintGomb              : TBitBtn;
    ReturnGomb               : TBitBtn;

    Shape1                   : TShape;
    Shape3                   : TShape;

    TradeSource              : TDataSource;

    BeosszegEdit             : TEdit;
    KiOsszegEdit             : TEdit;

    Bizracs                  : TDBGrid;

    ValutaDbase              : TIBDatabase;
    ValutaQuery              : TIBQuery;
    ValutaTranz              : TIBTransaction;
    ValutaTabla              : TIBTable;

    ValutaTablaBizonylatszam : TIBStringField;
    ValutaTablaBizonylatTipus: TIBStringField;
    ValutaTablaDatum         : TIBStringField;
    ValutaTablaOsszeg        : TIntegerField;
    ValutaTablaPenztaros     : TIBStringField;
    ValutaTablaPenztarSzam   : TSmallintField;
    ValutaTablaStorno        : TSmallintField;
    ValutaTablaTarspenztar   : TIBStringField;

    procedure AlapAdatBeolvasas;
    procedure BeBizonylatPrint;
    procedure BeKonyveles;
    procedure BeMegsemGombClick(Sender: TObject);
    procedure BeOkeGombClick(Sender: TObject);
    procedure BeOsszegEditEnter(Sender: TObject);
    procedure BeOsszegEditExit(Sender: TObject);
    procedure BeOsszegEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure BevetGombClick(Sender: TObject);
    procedure BizonylatGombClick(Sender: TObject);
    procedure BizVisszaGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KeszletGombClick(Sender: TObject);
    procedure KiadGombClick(Sender: TObject);
    procedure KiBizonylatPrint;
    procedure KiKonyveles;
    procedure KiMegsemGombClick(Sender: TObject);
    procedure KiOkeGombClick(Sender: TObject);
    procedure KiOsszegEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure KozepreIr(_szoveg: string);
    procedure MatDataBeolvas;
    procedure MatricaGombClick(Sender: TObject);
    procedure PillVisszaGombClick(Sender: TObject);
    procedure PlombaAdatBeolvasas;
    procedure Ptarbeolvasas;
    procedure RePrintGombClick(Sender: TObject);
    procedure ReturnGombClick(Sender: TObject);
    procedure TextKiiro;
    procedure ValutaParancs(_ukaz: string);
    procedure VonalHuzo;

    function ForintForm(_sm: integer):string;
    function Nul6(_i: integer): string;
    function Nulele(_b: byte): string;

  private
    { Private declarations }

  public
    { Public declarations }
  end;

var
  MATPENZTAR: TMATPENZTAR;
  _top,_left,_width,_height,_utbiznum: word;
  _printer: byte;

  _LFile: textfile;
  _LPath: string = 'c:\valuta\aktlst.txt';

  _sorveg: string = chr(13)+chr(10);

  _gepfunkcio: byte;

  _pcs,_mattipus,_bizonylatszam,_aktpenztarszam,_aktpenztarnev: string;
  _aktBizonylat,_aktdatum,_prosnev,_szallitonev,_plombaszam: string;
  _megjegyzes,_cegnev,_penztarnev,_penztarcim,_kftnev: string;
  _megnyitottnap,_aktprosnev,_penztarkod: string;

  _utmatsorszam,_matkeszlet,_penztaroke,_osszeg,_code,_plombaOke: integer;
  _penztarszam: byte;

function penztarrutin: integer; stdcall; external 'c:\valuta\bin\getptar.dll' name 'penztarrutin';
function getplombarutin: integer; stdcall; external 'c:\valuta\bin\getplomb.dll' name 'getplombarutin';

function matpenztarrutin: integer; stdcall;



implementation

{$R *.dfm}


function matpenztarrutin: integer; stdcall;
begin
  MatPenztar := TMatPenztar.Create(Nil);
  result := Matpenztar.showmodal;
  MatPenztar.free;
end;



// =============================================================================
              procedure TMATPENZTAR.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top := trunc((_height-330)/2);
  _left := trunc((_width-600)/2);

  Top := _top;
  Left := _left;
  Height := 330;
  Width := 600;

  BevetelPanel.visible := false;
  KiadasPanel.visible := False;
  BizonylatPanel.visible := False;
  Pillkeszpanel.visible := false;

  Bevetgomb.Enabled    := True;
  KiadGomb.Enabled     := True;
  Keszletgomb.Enabled  := True;

  AlapadatBeolvasas;

  Visible := true;
  Repaint;
end;

// =============================================================================
          procedure TMATPENZTAR.MATRICAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Bevetgomb.Enabled    := True;
  KiadGomb.Enabled     := True;
  Keszletgomb.Enabled  := True;

  with Matricaspanel do
    begin
      Top     := 265;
      Left    := 240;
      Visible := True;
    end;
end;

// =============================================================================
                   procedure TMATPENZTAR.Matdatabeolvas;
// =============================================================================

begin
  ValutaDbase.Connected := true;
  if ValutaTranz.InTransaction then Valutatranz.Commit;
  _pcs := 'SELECT * FROM MATDATA';
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _utmatsorszam := FieldByName('UTMATSORSZAM').asInteger;
      _matkeszlet := FieldByName('AKTKESZLET').asInteger;
      Close;
    end;
  ValutaDbase.Close;
end;

// =============================================================================
             procedure TMATPENZTAR.BEVETGOMBClick(Sender: TObject);
// =============================================================================

begin
  _penztarOke := penztarrutin;
  if _penztarOke<>1 then exit;

  PtarBeolvasas;
  MatdataBeolvas;
  inc(_utmatsorszam);

  BebankszamPanel.caption := _aktpenztarszam;
  _bizonylatszam := 'B-'+nul6(_utmatsorszam);
  Bebizpanel.Caption := _bizonylatszam;
  Beosszegedit.clear;

  with BevetelPanel do
    begin
      top := 96;
      Left := 30;
      Visible := true;
      Repaint;
    end;
  Activecontrol := Beosszegedit;
end;

// =============================================================================
                function TMatPenztar.Nul6(_i: integer): string;
// =============================================================================

begin
  result := inttostr(_i);
  while length(result)<6 do result := '0' + result;
end;

// =============================================================================
            procedure TMatPenztar.KiadGombClick(Sender: TObject);
// =============================================================================

begin
  _penztarOke := penztarrutin;
  if _penztarOke<>1 then exit;
  PtarBeolvasas;

  MatdataBeolvas;
  inc(_utmatsorszam);

  KibankszamPanel.caption := _aktpenztarszam;
  _bizonylatszam := 'K-'+nul6(_utmatsorszam);
  Kibizpanel.Caption := _bizonylatszam;
  Kiosszegedit.clear;

  with KiadasPanel do
    begin
      top := 96;
      Left := 30;
      Visible := true;
      Repaint;
    end;
  Activecontrol := Kiosszegedit;
end;

// =============================================================================
                       procedure TMatPenztar.Ptarbeolvasas;
// =============================================================================

begin
  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _aktpenztarSzam := trim(FieldbyName('PENZTARKOD').AsString);
      _aktpenztarnev := trim(FieldByNAme('TARSPENZTARNEV').AsString);
      Close;
    end;
  Valutadbase.close;
end;


// =============================================================================
         procedure TMatPenztar.KeszletGombClick(Sender: TObject);
// =============================================================================

begin

  Matdatabeolvas;
  with PillKeszPanel do
    begin
      Top     := 96;
      Left    := 30;
      Visible := True;
    end;

  KeszletDisplayPanel.Caption := ForintForm(_matkeszlet)+ ' Ft';
  PillvisszaGomb.Enabled := True;
  ActiveControl := PillvisszaGomb;
end;

// =============================================================================
              procedure TMatPenztar.BizonylatGombClick(Sender: TObject);
// =============================================================================

begin
  Valutadbase.Connected := true;
  ValutaTabla.Open;
  ValutaTabla.first;

  with BizonylatPanel do
    begin
      Top := 96;
      Left := 30;
      Visible := True;
    end;
  ActiveControl := Bizracs;
end;

// =============================================================================
                 function TMatPenztar.Nulele(_b: byte): string;
// ============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
            procedure TMatPenztar.ReturnGombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;

// =============================================================================
            procedure TMATPENZTAR.BEOSSZEGEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clwhite;
end;

// =============================================================================
             procedure TMatPenztar.BeosszegEditExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;

// =============================================================================
     procedure TMATPENZTAR.BEOSSZEGEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(Key)<>13 then exit;
  Activecontrol := BeokeGomb;
end;

// =============================================================================
             procedure TMATPENZTAR.BEMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  BevetelPanel.visible := False;
end;

// =============================================================================
             procedure TMATPENZTAR.BEOKEGOMBClick(Sender: TObject);
// =============================================================================

var _fts: string;

begin
  _Fts := trim(BeosszegEdit.Text);
  val(_fts,_osszeg,_code);
  if _code<>0 then _osszeg := 0;

  // ------------------------------

  if _osszeg=0 then
    begin
      Activecontrol := BeosszegEdit;
      exit;
    end;

  _plombaOke := getplombarutin;
  if _plombaOke<>1 then
    begin
      Modalresult := 2;
      exit;
    end;

  PlombaAdatBeolvasas;
  _aktDatum := _megnyitottnap;
  _aktprosnev := _prosnev;
  Bekonyveles;
  BebizonylatPrint;
  BevetelPanel.Visible := false;

end;

// =============================================================================
                         procedure TMatpenztar.BeKonyveles;
// =============================================================================

begin
  _pcs := 'INSERT INTO MATBIZONYLAT (DATUM,BIZONYLATSZAM,OSSZEG,TARSPENZTAR,';
  _pcs := _pcs + 'BIZONYLATTIPUS,STORNO,PENZTAROS)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _aktdatum + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_osszeg) + ',';
  _pcs := _pcs + chr(39) + _aktpenztarszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'B' + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _prosnev + chr(39) + ')';
 

  ValutaParancs(_pcs);

  _matkeszlet := _matkeszlet + _osszeg;
  _pcs := 'UPDATE MATDATA SET AKTKESZLET=' + inttostr(_matkeszlet);
  _pcs := _pcs + ',UTMATSORSZAM=' + inttostr(_utmatsorszam);
  ValutaParancs(_pcs);

  BevetelPanel.visible := False;
end;


// =============================================================================
                   procedure TMatpenztar.PlombaAdatBeolvasas;
// =============================================================================

begin
  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _szallitonev := trim(FieldbyNAme('SZALLITONEV').asString);
      _plombaszam := trim(FieldByNAme('PLOMBASZAM').asString);
      _megjegyzes := trim(FieldbyNAme('MEGJEGYZES').asString);
      Close;
    end;
  ValutaDbase.close;
end;

// =============================================================================
             procedure TMatpenztar.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.connected := true;
  if ValutaTranz.InTransaction then Valutatranz.Commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;


// =============================================================================
                    procedure TMatPenztar.BebizonylatPrint;
// =============================================================================

begin
  {

123456789012345678901234567890123456789
---------------------------------------
       EXCLUSIVE BEST  CHANGE
        NYIREGYHÁZA ÉRTÉKTÁR
    NYIREGYHAZA, KISFALUDY TER 55

 E-KERESKEDELEM PÉNZÁTVÉTEL BIZONYLAT
---------------------------------------
      BIZONYLATSZAM: B-123456
              DATUM: 2016.12.12
      ATADÓ PÉNZTÁR: 143
      ÁTVETT ÖSSZEG: 123.456.500 Ft
-------------1--------1---------2-----6
SZALLITONEV: EOIUROIUZROIUROUROUTROUTRO
 PLOMBASZAM: EPOUERPOUROTURTOIUTOIUTOIT
 MEGJEGYZES: RPOURPU TTROTUOUTOU TOIUTO


..................  ...................
       átadó              átvevó
   }

  Assignfile(_LFile,_LPath);
  Rewrite(_LFile);

  Kozepreir(_cegnev);
  Kozepreir(_penztarnev);
  Kozepreir(_Penztarcim);
  writeln(_LFile,' ');

  writeLn(_LFile,' E-KERESKEDELEM PÉNZÁTVÉTEL BIZONYLAT');
  VonalHuzo;

  writeLn(_Lfile,'      BIZONYLATSZAM: ' + _bizonylatszam);
  writeLn(_LFile,'              DATUM: ' + _aktdatum);
  writeLn(_LFile,'      ÁTADÓ PÉNZTÁR: ' + _aktPenztarszam);
  writeLn(_LFile,'      ÁTVETT ÖSSZEG: ' + forintform(_osszeg));
  Vonalhuzo;

  writeLn(_LFile,'SZALLITÓNÉV: '+_szallitonev);
  writeLn(_LFile,' PLOMBASZÁM: '+_plombaszam);
  writeLn(_LFile,' MEGJEGYZÉS: '+_megjegyzes);
  writeLn(_Lfile,_sorveg);

  writeLn(_Lfile,'..................  ...................');
  writeLn(_LFile,'       átadó              átvevó');
  writeLn(_LFile,_sorveg+_sorveg);
  Closefile(_LFile);
  TextKiiro;
end;

// =============================================================================
                          procedure TMatpenztar.Vonalhuzo;
// =============================================================================

begin
  writeLn(_LFile,dupestring('-',39));
end;

// =============================================================================
                         procedure TMatPenztar.TextKiiro;
// =============================================================================

var _nyomtat,_olvas: Textfile;
    _mondat: string;

begin
  if _printer<>1 then AssignFile(_nyomtat,'LPT1:')
  else AssignPrn(_nyomtat);
  Rewrite(_nyomtat);

  AssignFile(_olvas,_Lpath);
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
                     procedure TMatpenztar.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;


// =============================================================================
             function TMatPenztar.ForintForm(_sm:integer):string;
// =============================================================================

var _slen,_pp: integer;
    _ejel : string;

begin
  Result := '-';

  if _sm=0 then exit;

  _ejel := '';

  if _sm<0 then
    begin
      _ejel := '-';
      _sm := abs(_sm);
    end;

  Result := intTostr(_sm);

  if _sm<1000 then
    begin
      Result := _ejel + Result;
      Exit;
    end;

  _sLen := length(Result);
  if _sm>999999 then
    begin
      _pp := _sLen-5;
      Result := _ejel + midStr(Result,1,_pp-1)+','+midStr(Result,_pp,3)+','+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := _ejel + midStr(result,1,_pp-1)+','+midStr(result,_pp,3);
end;

// =============================================================================
                 procedure TMatPenztar.AlapAdatBeolvasas;
// =============================================================================

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := FieldByName('MEGNYITOTTNAP').asstring;
      _prosnev := trim(FieldByName('PENZTAROSNEV').AsString);
      _kftnev := trim(FieldByName('KFTNEV').AsString);
      _printer := FieldByNAme('PRINTER').asInteger;
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _penztarkod := trim(FieldByName('PENZTARKOD').AsString);
      _penztarnev := trim(FieldByNAme('PENZTARNEV').AsString);
      _penztarcim := trim(FieldByNAme('PENZTARCIM').AsString);
      CLOSE;
    end;
  Valutadbase.close;

  val(_penztarkod,_penztarszam,_code);
  if _penztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
    end else
    begin
      _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
    end;
end;

// =============================================================================
     procedure TMATPENZTAR.KIOSSZEGEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(Key)<>13 then exit;
  Activecontrol := KiokeGomb;
end;

// =============================================================================
             procedure TMATPENZTAR.KIMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  KiadasPanel.Visible := False;
end;

// =============================================================================
               procedure TMATPENZTAR.KIOKEGOMBClick(Sender: TObject);
// =============================================================================

var _fts: string;

begin
  _Fts := trim(KiosszegEdit.Text);
  val(_fts,_osszeg,_code);
  if _code<>0 then _osszeg := 0;

  // ------------------------------

  if _osszeg=0 then
    begin
      Activecontrol := KiosszegEdit;
      exit;
    end;

  _plombaOke := getplombarutin;
  if _plombaOke<>1 then
    begin
      Modalresult := 2;
      exit;
    end;

  PlombaAdatBeolvasas;
  _aktDatum := _megnyitottnap;
  _aktprosnev := _prosnev;
  Kikonyveles;
  KibizonylatPrint;
  KiadasPanel.Visible := false;
end;


// =============================================================================
                          procedure TMatPenztar.KiKonyveles;
// =============================================================================

begin
  _pcs := 'INSERT INTO MATBIZONYLAT (DATUM,BIZONYLATSZAM,OSSZEG,TARSPENZTAR,';
  _pcs := _pcs + 'BIZONYLATTIPUS,STORNO,PENZTAROS)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _aktdatum + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_osszeg) + ',';
  _pcs := _pcs + chr(39) + _aktpenztarszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'K' + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + _aktprosnev + chr(39) + ')';

  ValutaParancs(_pcs);

  _matkeszlet := _matkeszlet - _osszeg;
  _pcs := 'UPDATE MATDATA SET AKTKESZLET=' + inttostr(_matkeszlet);
  _pcs := _pcs + ',UTMATSORSZAM=' + inttostr(_utmatsorszam);
  ValutaParancs(_pcs);

  KiadasPanel.visible := False;
end;

// =============================================================================
                      procedure TMatPenztar.KibizonylatPrint;
// =============================================================================

begin
  Assignfile(_LFile,_LPath);
  Rewrite(_LFile);

  Kozepreir(_cegnev);
  Kozepreir(_penztarnev);
  Kozepreir(_Penztarcim);
  writeln(_LFile,' ');

  writeLn(_LFile,'  E-KERESKEDELEM PÉNZÁZADÁS BIZONYLAT');
  VonalHuzo;

  writeLn(_Lfile,'      BIZONYLATSZAM: ' + _bizonylatszam);
  writeLn(_LFile,'              DATUM: ' + _aktdatum);
  writeLn(_LFile,'     ÁTVEVÕ PÉNZTÁR: ' + _aktPenztarszam);
  writeLn(_LFile,'     ÁTADOTT ÖSSZEG: ' + forintform(_osszeg));
  Vonalhuzo;

  writeLn(_LFile,'SZALLITÓNÉV: '+_szallitonev);
  writeLn(_LFile,' PLOMBASZÁM: '+_plombaszam);
  writeLn(_LFile,' MEGJEGYZÉS: '+_megjegyzes);
  writeLn(_Lfile,_sorveg);

  writeLn(_Lfile,'..................  ...................');
  writeLn(_LFile,'       átadó              átvevó');
  writeLn(_LFile,_sorveg+_sorveg);
  Closefile(_LFile);
  TextKiiro;
end;

// =============================================================================
           procedure TMATPENZTAR.PILLVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  PillkeszPanel.Visible := false;
end;

// =============================================================================
             procedure TMATPENZTAR.BIZVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Bizonylatpanel.Visible := False;
  ValutaTabla.close;
  ValutaDbase.close;

  Pillkeszpanel.visible := False;
end;

// =============================================================================
             procedure TMATPENZTAR.REPRINTGOMBClick(Sender: TObject);
// =============================================================================

var _btipus: string;

begin
  _osszeg := ValutaTabla.fieldByName('OSSZEG').asInteger;
  _aktdatum := ValutaTabla.FieldByNAme('DATUM').AsString;
  _bizonylatszam := ValutaTabla.fieldByName('BIZONYLATSZAM').asString;
  _aktprosnev := trim(ValutaTabla.FieldbyName('PENZTAROS').asString);
  _aktpenztarszam := trim(ValutaTabla.Fieldbyname('TARSPENZTAR').AsString);
  _btipus := ValutaTabla.FieldbyNAme('BIZONYLATTIPUS').asString;
 
  if _btipus='B' then BebizonylatPrint else KibizonylatPrint;
end;

end.
