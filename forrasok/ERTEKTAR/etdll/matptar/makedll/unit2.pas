unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DB, Grids, DBGrids, StrUtils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery;

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
    EKERPANEL: TPanel;
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

    KIADGOMB                 : TBitBtn;
    EKERTABLA                : TIBTable;
    EKERDBASE                : TIBDatabase;
    EKERTRANZ                : TIBTransaction;

    EKERTABLADATUM           : TIBStringField;
    EKERTABLABIZONYLAT       : TIBStringField;
    EKERTABLAELOJEL          : TIBStringField;
    EKERTABLABANKJEGY        : TIntegerField;
    EKERTABLAPENZTAR         : TIBStringField;

    procedure AlapAdatBeolvasas;
    procedure BizonylatPrint;
    procedure Konyveles;
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
    procedure KiMegsemGombClick(Sender: TObject);
    procedure KiOkeGombClick(Sender: TObject);
    procedure KiOsszegEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);

    procedure EkerDataBeolvas;
    procedure MatricaGombClick(Sender: TObject);
    procedure PillVisszaGombClick(Sender: TObject);
    procedure PlombaAdatBeolvasas;
    procedure Ptarbeolvasas;
    procedure RePrintGombClick(Sender: TObject);
    procedure ReturnGombClick(Sender: TObject);

    procedure ValutaParancs(_ukaz: string);

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

  _LFile: textfile;
  _LPath: string = 'c:\ertektar\aktlst.txt';

  _sorveg: string = chr(13)+chr(10);

  _gepfunkcio: byte;

  _pcs,_mattipus,_bizonylat,_aktpenztarszam,_aktpenztarnev: string;
  _aktBizonylat,_aktdatum,_prosnev,_szallitonev,_plombaszam: string;
  _megjegyzes,_penztarnev,_penztarcim,_kftnev: string;
  _megnyitottnap,_aktprosnev,_elojel: string;

  _ekersorszam,_ekerkeszlet,_penztaroke,_code,_plombaOke: integer;
  _bankjegy,_recno: integer;

function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\ertektar\bin\bloknyom.dll' name 'blokknyomtatas';
function regeneralorutin: integer; stdcall; external 'c:\ertektar\bin\regen.dll' name 'regeneralorutin';
function penztarrutin: integer; stdcall; external 'c:\ertektar\bin\getptar.dll' name 'penztarrutin';
function getplombarutin: integer; stdcall; external 'c:\ertektar\bin\getplomb.dll' name 'getplombarutin';
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

  Top    := _top;
  Left   := _left;
  Height := 330;
  Width  := 600;

  BevetelPanel.visible   := False;
  KiadasPanel.visible    := False;
  BizonylatPanel.visible := False;
  Pillkeszpanel.visible  := false;

  Bevetgomb.Enabled    := True;
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
  Keszletgomb.Enabled  := True;

  with EkerPanel do
    begin
      Top     := 265;
      Left    := 240;
      Visible := True;
    end;
end;

// =============================================================================
                   procedure TMATPENZTAR.Ekerdatabeolvas;
// =============================================================================

begin
  ValutaDbase.Connected := true;
  if ValutaTranz.InTransaction then Valutatranz.Commit;
  _pcs := 'SELECT * FROM EKERDATA';
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _ekerkeszlet := FieldByName('ZARO').asInteger;
      Close;

      Sql.clear;
      Sql.Add('SELECT * FROM UTOLSOBLOKKOK');
      Open;
      _ekersorszam := FieldByName('LASTEKER').asInteger;
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
  EkerdataBeolvas;
  inc(_ekersorszam);

  BebankszamPanel.caption := _aktpenztarszam;
  _bizonylat := 'BE-'+nul6(_ekersorszam);
  _ELOJEL := '+';

  Bebizpanel.Caption := _bizonylat;
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

  EkerdataBeolvas;
  inc(_ekersorszam);

  KibankszamPanel.caption := _aktpenztarszam;
  _bizonylat := 'KE-'+nul6(_ekersorszam);
  _ELOJEL := '-';

  Kibizpanel.Caption := _bizonylat;
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

  Ekerdatabeolvas;
  with PillKeszPanel do
    begin
      Top     := 96;
      Left    := 30;
      Visible := True;
    end;

  KeszletDisplayPanel.Caption := ForintForm(_ekerkeszlet)+ ' Ft';
  PillvisszaGomb.Enabled := True;
  ActiveControl := PillvisszaGomb;
end;

// =============================================================================
              procedure TMatPenztar.BizonylatGombClick(Sender: TObject);
// =============================================================================

begin
  Ekerdbase.Connected := true;
  EkerTabla.Open;
  EkerTabla.first;

  with BizonylatPanel do
    begin
      Top := 96;
      Left := 56;
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
  val(_fts,_bankjegy,_code);
  if _code<>0 then _bankjegy := 0;

  // ------------------------------

  if _bankjegy=0 then
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

  konyveles;

  bizonylatPrint;
  BevetelPanel.Visible := false;
  regeneralorutin;


end;

// =============================================================================
                         procedure TMatpenztar.Konyveles;
// =============================================================================

begin
  _pcs := 'INSERT INTO EKERESKEDELEM (DATUM,BIZONYLAT,ELOJEL,BANKJEGY,';
  _pcs := _pcs + 'PENZTAR,STORNO)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _aktdatum + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ELOJEL + chr(39) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + chr(39) + _aktpenztarszam + chr(39) + ',1)';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE UTOLSOBLOKKOK SET LASTEKER=' + inttostr(_ekersorszam);
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO WPENZSZALLITAS (DATUM,BIZONYLATSZAM,PLOMBASZAM,';
  _pcs := _pcs + 'SZALLITONEV,MEGJEGYZES,WTIPUS)'+_SORVEG;

  _pcs := _pcs + 'VALUES (' + chr(39) + _aktdatum+chr(39)+',';
  _pcs := _pcs + chr(39)+_bizonylat+chr(39)+',';
  _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megjegyzes + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'EK' + chr(39) + ')';
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
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;

      _penztarnev := trim(FieldByNAme('PENZTARNEV').AsString);
      _penztarcim := trim(FieldByNAme('PENZTARCIM').AsString);
      CLOSE;

    end;
  Valutadbase.close;
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
  val(_fts,_bankjegy,_code);
  if _code<>0 then _bankjegy := 0;

  // ------------------------------

  if _bankjegy=0 then
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
  konyveles;
  bizonylatPrint;
  KiadasPanel.Visible := false;
  regeneralorutin;
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
  EkerTabla.close;
  EkerDbase.close;

  Pillkeszpanel.visible := False;
end;

// =============================================================================
             procedure TMATPENZTAR.REPRINTGOMBClick(Sender: TObject);
// =============================================================================

begin
  _aktdatum := EkerTabla.FieldByNAme('DATUM').AsString;
  _bankjegy := EkerTabla.fieldByName('BANKJEGY').asInteger;
  _bizonylat := EkerTabla.fieldByName('BIZONYLAT').asString;
  _elojel := EkerTabla.FieldByName('ELOJEL').asString;
  _aktpenztarszam := trim(EkerTabla.Fieldbyname('PENZTAR').AsString);

  _szallitonev := '';
  _plombaszam  := '';
  _megjegyzes  := '';

  _pcs := 'SELECT * FROM WPENZSZALLITAS WHERE BIZONYLATSZAM='+chr(39)+_bizonylat+chr(39);
  Valutadbase.Connected := true;
  with valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;
  if _recno>0 then
    begin
      _szallitonev := trim(ValutaQuery.fieldByNAme('SZALLITONEV').AsString);
      _plombaszam := trim(ValutaQuery.FieldByNAme('PLOMBASZAM').AsString);
      _megjegyzes := trim(Valutaquery.FieldByNAme('MEGJEGYZES').asString);
    end;
  Valutaquery.close;
  Valutadbase.close;


  bizonylatPrint;
end;

// =============================================================================
                    procedure TMatPenztar.bizonylatPrint;
// =============================================================================

begin

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (TIPUS,DATUM,BIZONYLATSZAM,ELOJEL,PENZTARKOD,';
  _pcs := _pcs + 'BANKJEGY,SZALLITONEV,PLOMBASZAM,MEGJEGYZES,STORNO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + 'E' +chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktdatum + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktpenztarszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_bankjegy) + ',';
  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megjegyzes + chr(39) + ',';
  _pcs := _pcs + '1)';
  ValutaParancs(_pcs);
  blokknyomtatas(1);
end;

end.
