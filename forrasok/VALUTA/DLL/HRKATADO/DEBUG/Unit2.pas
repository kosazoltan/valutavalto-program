unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,DB, Grids, DBGrids, StrUtils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery, jpeg, printers,
  dateUtils;

type
  TFORM2 = class(TForm)
    HrkMenuPanel         : TPanel;
    Panel2               : TPanel;
    HrkAtadGomb          : TBitBtn;
    HrkPILLGomb          : TBitBtn;
    HrkBizonylatGomb     : TBitBtn;
    VisszaGomb           : TBitBtn;
    KezelesiFoPanel      : TPanel;
    Shape7               : TShape;
    Label11              : TLabel;
    KezBizPanel          : TPanel;
    KunaEdit             : TEdit;
    KonyveloGomb         : TBitBtn;
    KezKonyvMegsemGomb   : TBitBtn;
    BizonylatPanel       : TPanel;
    HrkRacs              : TDBGrid;
    HrkDbase             : TIBDatabase;
    HrkTranz             : TIBTransaction;
    HrkSource            : TDataSource;
    StornoGomb           : TBitBtn;
    ListaVisszaGomb      : TBitBtn;
    KezBizonyFocimPanel  : TPanel;
    StornoPanel          : TPanel;
    PillKezdijPanel      : TPanel;
    Label21              : TLabel;
    PillOsszegPanel      : TPanel;
    Shape9               : TShape;
    PillKeszBackGomb     : TBitBtn;
    ReprintGomb          : TBitBtn;
    Shape1               : TShape;
    HRKQuery             : TIBQuery;
    Shape2               : TShape;
    Label1               : TLabel;
    Label2               : TLabel;
    ValutaQuery          : TIBQuery;
    ValutaDbase          : TIBDatabase;
    ValutaTranz          : TIBTransaction;
    Label3               : TLabel;
    surepanel: TPanel;
    Label4: TLabel;
    SIGENGOMB: TBitBtn;
    SNEMGOMB: TBitBtn;
    SUREFEDEL: TPanel;
    Label5: TLabel;
    STORNOEDIT: TEdit;
    STORNOGOGOMB: TButton;
    STORNONOGOMB: TBitBtn;
    NAPLOQUERY: TIBQuery;
    NAPLODBASE: TIBDatabase;
    NAPLOTRANZ: TIBTransaction;

    procedure AlapAdatBeolvasas;
    procedure BizonylatChange;
    procedure FormActivate(Sender: TObject);
    procedure GetHRKData;
    procedure HrkForgDisplay(Sender: TObject);
    procedure HrkParancs(_ukaz: string);
    procedure HrkAtadGombClick(Sender: TObject);
    procedure HrkBizonylatGombClick(Sender: TObject);
    procedure HrkPILLGombClick(Sender: TObject);
    procedure HrkRacsCellClick(Column: TColumn);
    procedure HrkRacsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HrkRacsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure HrkRacsDblClick(Sender: TObject);
    procedure HrkRegen;
    procedure KezdParancs(_ukaz: string);
    procedure KezKonyvMegsemGombClick(Sender: TObject);
    procedure KozepreIr(_szoveg: string);
    procedure KunaEditEnter(Sender: TObject);
    procedure KunaEditExit(Sender: TObject);
    procedure KunaEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KonyveloGombClick(Sender: TObject);
    procedure ListaVisszaGombClick(Sender: TObject);
    procedure Naplobair;
    procedure NaploParancs(_ukaz: string);
    procedure Nyomtatas;
    procedure PillKeszBackGombClick(Sender: TObject);
    procedure PlombaAdatBeolvasas;
    procedure ReprintGombClick(Sender: TObject);
    procedure StornoGombClick(Sender: TObject);
    procedure TextKiiro;
    procedure VisszaGombClick(Sender: TObject);
    procedure VonalHuzo;

    function ForintForm(_sm:integer):string;
    function Getidos: string;
    function Nulele(_b, _h: integer): string;
    procedure SIGENGOMBClick(Sender: TObject);
    procedure STORNOEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure STORNOGOGOMBClick(Sender: TObject);

  private
    { Private declarations }

  public
    { Public declarations }
  end;

var
  FORM2: TFORM2;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                 'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                                             'NOVEMNER','DECEMBER');

  _Lfile : textfile;
  _LPath : string = 'C:\VALUTA\AKTLST.TXT';
  _sorveg: string = chr(13) + chr(10);

  _printer,_penztarszam,_storno,_ertektar: byte;
  _height,_width,_top,_left,_maiev,_maiho,_kertho,_kertev: word;

  _kiSorszam,_aktHrkKeszlet,_kikuna,_be,_ki: integer;
  _nyito,_bevetel,_kiadas,_zaro,_recno: integer;

   _kezbBizszam,_kezKBizszam,_aktkezdij,_kezdij,_code,_mozgas: integer;
  _kezSbizszam,_plombaOke,_ptaroke,_sumbe,_sumki,_hnyito,_hzaro: integer;

  _pcs,_plombaszam,_mamas,_szallitonev,_megjegyzes,_farok,_indok: string;
  _bizonylatszam,_penztarnev,_penztarcim,_bizkelte,_elojel,_cegnev: string;
  _tema,_ej,_aktPenztarszam,_aktPenztarnev,_origbizonylat,_aktdatum: string;
  _stornobizonylat,_tipus,_penztarkod,_idos,_utdatum,_bizido,_datum: string;


  _oBizonylat,_ujrekord: boolean;

function penztarrutin: integer; stdcall; external 'c:\valuta\bin\getptar.dll' name 'penztarrutin';
function getplombarutin: integer; stdcall; external 'c:\valuta\bin\getplomb.dll' name 'getplombarutin';

function hrkbekuldorutin: integer; stdcall;

implementation


{$R *.dfm}


// =============================================================================
              function hrkbekuldorutin: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.ShowModal;
  form2.free;
end;


// =============================================================================
              procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top := trunc((_height-400)/2);
  _left := trunc((_width-640)/2);

  Top  := _top;
  Left := _left;

  Height  := 400;
  Width   := 640;

  with HrkMenupanel do
    begin
      Top  := 0;
      Left := 0;
      visible := true;
      repaint;
    end;

  _maiev := yearof(date);
  _maiho := monthof(date);

  Visible := true;
  Hrkregen;
  AlapadatBeolvasas;
  _idos := Getidos;
  ActiveControl := HrkAtadGomb;
end;

// =============================================================================
                    function TForm2.Getidos: string;
// =============================================================================

begin
  result := timetostr(Time);
  if midstr(result,2,1)=':' then result := '0' + result;
  result := leftstr(result,5);
end;

// =============================================================================
            procedure TFORM2.HrkAtadGombClick(Sender: TObject);
// =============================================================================

begin

  Konyvelogomb.Enabled := False;

  GetHrkData;
  inc(_kiSorszam);

  _bizonylatszam := 'K-' + nulele(_kiSorszam,5);
  KezbizPanel.Caption := _bizonylatszam;
  with KezelesiFopanel do
    begin
      top     := 110;
      Left    := 30;
      Visible := True;
    end;

  KunaEdit.clear;
  ActiveControl := KunaEdit;
end;

// =============================================================================
             procedure TFORM2.KunaEditEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).Color := $B0FFFF;
end;

// =============================================================================
            procedure TFORM2.KunaEditExit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clWindow;
end;

// =============================================================================
   procedure TFORM2.KUNAEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _bill: byte;

begin
  _bill := ord(key);
  if _bill<>13 then exit;

  KonyveloGomb.Enabled := True;
  ActiveControl := KonyveloGOmb;
end;

// =============================================================================
         procedure TFORM2.KEZKONYVMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  KezelesiFopanel.Visible := False;
  ActiveControl := HrkAtadGomb;
end;


// =============================================================================
           procedure TFORM2.KONYVELOGOMBClick(Sender: TObject);
// =============================================================================

begin
  val(KunaEdit.text,_kikuna,_code);

  if _code<>0 then _kikuna := 0;
  if _kikuna=0 then
    begin
      ModalResult := 2;
      exit;
    end;

  if _kikuna>_aktHrkKeszlet then
    begin
      ShowMessage('Ennyi HRK nincs a házipénztárban !');
      Modalresult := 2;
      exit;
    end;

  _plombaOke := getplombarutin;
  if _plombaOke=2 then
    begin
      ModalResult := 2;
      exit;
    end;

  PlombaAdatBeolvasas;

  // ----------------- itt könyvelem a kuna kiadás -----------------------------
  // hrk-napló:

  _nyito    := 0;
  _bevetel  := 0;
  _kiadas   := _kikuna;
  _ujrekord := True;

  _pcs := 'SELECT * FROM HRKNAPLO ORDER BY DATUM';
  HrkDbase.Connected := true;
  with HrkQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := Recno;
    end;

  if _recno>0 then
    begin
     _utDatum := HrkQuery.FieldByName('DATUM').asString;
     if _utdatum<_mamas then
       begin
         _nyito := HrkQuery.FieldByName('ZARO').asInteger
       end else
       Begin
         _nyito := Hrkquery.FieldByNAme('NYITO').asInteger;
         _bevetel := HrkQuery.FieldByNAme('BEVETEL').asInteger;
         _kiadas := HrkQuery.FieldByNAme('KIADAS').asInteger;
         _kiadas := _kiadas + _kikuna;
         _ujrekord := false;
       end;
    end;

  HrkQuery.close;
  HrkDbase.close;

  _zaro := _nyito + _bevetel - _kiadas;
  if _ujrekord then
    begin
      _pcs := 'INSERT INTO HRKNAPLO (DATUM,IDO,NYITO,BEVETEL,KIADAS,ZARO)'+_SORVEG;
      _pcs := _pcs + 'VALUES (' + chr(39) + _MAMAS + chr(39) + ',';
      _pcs := _pcs + chr(39) + _idos + chr(39) + ',';
      _pcs := _pcs + inttostr(_nyito) + ',';
      _pcs := _pcs + inttostr(_bevetel) + ',';
      _pcs := _pcs + inttostr(_kiadas) + ',';
      _pcs := _pcs + inttostr(_zaro)+')';
    end else
    begin
      _pcs := 'UPDATE HRKNAPLO SET KIADAS='+inttostr(_kiadas)+',ZARO='+inttostr(_zaro)+_sorveg;
      _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _mamas +chr(39);
    end;
  HrkParancs(_pcs);

  // ---------------------------------------------------------------------------

  // hrk-data

  _pcs := 'SELECT * FROM HRKDATA';

  HrkDbase.Connected := True;
  with HrkQuery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      _kiSorszam := FieldByNAme('KISORSZAM').asInteger;
      Close;
    end;
  Hrkdbase.close;

  inc(_kiSorszam);

  _pcs := 'UPDATE HRKDATA SET KISORSZAM='+inttostr(_kisorszam);
  _pcs := _pcs + ',AKTKESZLET=' + inttostr(_zaro);
  HrkParancs(_pcs);

  // ---------------------------------------------------------------------------
  // hrk-szamlak

  _bizonylatszam := 'K-'+nulele(_kiSorszam,5);

  _pcs := 'INSERT INTO HRKSZAMLAK (DATUM,IDO,BIZONYLATSZAM,KIADAS,';
  _pcs := _pcs + 'PENZTAR,STORNO,PLOMBASZAM,SZALLITONEV)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _idos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_kikuna) + ',';
  _pcs := _pcs + chr(39) + inttostr(_ertektar) + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + trim(_plombaszam) + chr(39) + ',';
  _pcs := _pcs + chr(39) + trim(_szallitonev) + chr(39) + ')';
  HrkParancs(_pcs);

  Nyomtatas;
  KezelesiFoPanel.Visible := False;
end;


// =============================================================================
             procedure TFORM2.Nyomtatas;
// =============================================================================

var _tema,_cim: string;

begin
  {

  123456789012345678901234567890123456789
         EXCLUSIVE BEST CHANGE ZRT
            KECSKEMÉT, INTERSPAR
      KECSKEMET, CSOKONAI MIHÁLY U.44
  -----------------------------------------
      HORVÁT KUNA ATADÁSI BIZONYLATA
  -----------------------------------------
        Bizonylatszam : B-000123
      Bizonylat kelte : 2016.12.12
        Atadó pénztár : 143
        Átadott összeg: 123 456 000 HRK
  ------------------------------------------
   }


  _tema := leftstr(_bizonylatszam,1);

  AssignFile(_LFile,_Lpath);
  rewrite(_LFile);

  Kozepreir(_cegnev);
  Kozepreir(_penztarnev);
  Kozepreir(_penztarcim);
  VonalHuzo;
  if _storno>1 then
    begin
      Kozepreir('(ez a bizonylat stornozott)');
      if _indok<>'' then Kozepreir('Indoka: '+_indok);
    end;

  _cim := '     HORVÁT KUNA ';
  if _tema='K' then _cim := _cim + 'ÁTADÁSI '
  else _cim := _cim + 'BEVÉTELI ';
  _cim := _cim + 'BIZONYLATA';

  WriteLn(_LFile,_cim);

  VonalHuzo;
  writeLn(_LFile,'      Bizonylatszam: ' + _bizonylatszam);
  writeLn(_LFile,'    Bizomylat kelte: ' + _mamas);
  if _tema='K' then write(_LFile,'      Átadó pénztár: ')
  else write(_LFile,'     Átvevõ pénztár: ');
  writeLn(_LFile,_aktpenztarszam);

  if _tema='K' then
    begin
      write(_LFile,'     Átadott összeg: ');
      writeLn(_LFile,forintform(_kiadas)+' HRK');
    end else
    begin
      write(_LFile,'Bevételezett összeg: ');
      writeLn(_LFile,forintform(_bevetel)+' HRK');
    end;
  VonalHuzo;

  writeLn(_LFile,'Szállitónév: '+_szallitonev);
  writeLn(_LFile,'Plomba-szám: '+_plombaszam);
  writeLn(_LFile,' Megjegyzés: '+_megjegyzes);
  writeLn(_lFile,_sorveg+_sorveg);

  writeLN(_Lfile,'..................  ...................');
  writeLn(_LFile,'      atado                 atvevo     ');
  writeLn(_LFile,_sorveg);

  CloseFile(_Lfile);
  TextKiiro;
end;

// =============================================================================
         procedure TFORM2.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  hrkRegen;
  Modalresult := 1;
end;

// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
          procedure TFORM2.HRKPILLGOMBClick(Sender: TObject);
// =============================================================================

begin
  GetHRKData;
  Pillosszegpanel.Caption := ForintForm(_aktHrkKeszlet)+' HRK';
  with PillKezdijpanel do
    begin
      Top := 136;
      Left := 52;
      Visible := True;
    end;
  PillkezdijPanel.Repaint;
end;

procedure TFORM2.PillKeszBackGombClick(Sender: TObject);
begin
  Pillkezdijpanel.Visible := false;
  ActiveControl := HrkAtadGomb;
end;



// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
       procedure TFORM2.HRKBIZONYLATGOMBClick(Sender: TObject);
// =============================================================================

begin
  Stornopanel.Visible := false;
  with BizonylatPanel do
     begin
       Top := 0;
       Left := 0;
       Visible := true;
     end;
   HrkForgDisplay(Nil);
end;


// =============================================================================
                procedure TFORM2.HrkForgDisplay(Sender: TObject);
// =============================================================================

begin
  HRKSource.Enabled  := False;
  StornoGomb.Enabled := False;

  HrkDbase.Connected := true;
  with HrkQuery do
    begin
      close;
      sql.clear;
      Sql.Add('SELECT * FROM HRKSZAMLAK');
      Open;
      First;
    end;

  BizonylatChange;
  HRKSource.Enabled := True;

  _oBizonylat := False;

  HrkRacs.SelectedIndex := 0;
  HrkRacs.setfocus;
end;

// =============================================================================
                    procedure TFORM2.Bizonylatchange;
// =============================================================================

begin
  with HrkQuery do
    begin
      _bizkelte       := FieldbyName('DATUM').asstring;
      _bizido         := FieldByName('IDO').asString;
      _bevetel        := FieldByName('BEVETEL').asInteger;
      _kiadas         := FieldbynAme('KIADAS').asInteger;
      _aktpenztarszam := FieldByName('PENZTAR').asString;
      _Bizonylatszam  := FieldByName('BIZONYLATSZAM').asString;
      _storno         := FieldByName('STORNO').asInteger;
    end;

  if _storno>1 then
    begin
      stornopanel.visible := True;
      StornoGomb.Enabled  := false;
    end else
    begin
      stornopanel.visible := false;
      Stornogomb.Enabled := True;
    end;
  if _bizkelte<_mamas then Stornogomb.Enabled := False;

end;

// =============================================================================
                procedure TFORM2.STORNOGOMBClick(Sender: TObject);
// =============================================================================

begin
  HrkQuery.close;
  Hrkdbase.close;

  _pcs := 'UPDATE HRKSZAMLAK SET STORNO=2 WHERE BIZONYLATSZAM='+CHR(39)+_bizonylatszam+chr(39);
  HrkParancs(_pcs);
  HrkForgDisplay(Nil);
end;

// =============================================================================
         procedure TFORM2.HrkRacsDblClick(Sender: TObject);
// =============================================================================

begin
  BizonylatChange;
end;

// =============================================================================
         procedure TFORM2.HrkRacsCellClick(Column: TColumn);
// =============================================================================

begin
  BizonylatChange;
end;

// =============================================================================
     procedure TFORM2.HrkRacsKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  BizonylatChange;
end;

// =============================================================================
       procedure TFORM2.HrkRacsMouseUp(Sender: TObject;
                       Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  Bizonylatchange;
end;

// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                    procedure TForm2.AlapAdatBeolvasas;
// =============================================================================

begin
  valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _ertekTar := FieldByNAme('ERTEKTAR').asInteger;
      _mamas := trim(FieldByName('MEGNYITOTTNAP').asString);
      _printer := FieldByName('PRINTER').asInteger;
      Close;

      Sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _penztarkod := trim(FieldByNAme('PENZTARKOD').AsString);
      _penztarnev := trim(FieldByNAme('PENZTARNEV').asString);
      _penztarcim := trim(FieldByNAme('PENZTARCIM').AsString);
      Close;
    end;
  Valutadbase.close;

  val(_penztarkod,_penztarszam,_code);
  _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
end;


// =============================================================================
                  procedure TForm2.GetHRKData;
// =============================================================================

begin
  HrkDbase.Connected := True;
  with HrkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM HRKDATA');
      Open;
      _aktHrkKeszlet   := Fieldbyname('AKTKESZLET').asInteger;
      _kiSorszam:= FieldByName('KISORSZAM').asInteger;
      Close;
    end;

  HrkDbase.close;
end;


// =============================================================================
                   procedure TForm2.PlombaAdatBeolvasas;
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
          procedure TFORM2.HRKParancs(_ukaz: string);
// =============================================================================

begin
  HRKdbase.connected := true;
  if HRKTranz.InTransaction then HRKtranz.commit;
  HRKtranz.StartTransaction;
  with HRKQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  HRKTranz.commit;
  HRKDbase.close;
end;

// =============================================================================
          procedure TForm2.KezdParancs(_ukaz: string);
// =============================================================================

begin
  Hrkdbase.connected := true;
  if HrkTranz.InTransaction then Hrktranz.commit;
  Hrktranz.StartTransaction;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  HrkTranz.commit;
  HrkDbase.close;
end;

// =============================================================================
                         procedure TForm2.TextKiiro;
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
             function TForm2.ForintForm(_sm:integer):string;
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
                          procedure TForm2.Vonalhuzo;
// =============================================================================

begin
  writeLn(_LFile,dupestring('-',39));
end;


// =============================================================================
                     procedure TForm2.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;

// =============================================================================
         function TForm2.Nulele(_b,_h: integer): string;
// =============================================================================

begin
  result := inttostr(_b);
  while length(result)<_h do result := '0' + result;
end;

// =============================================================================
           procedure TForm2.ListaVisszaGombClick(Sender: TObject);
// =============================================================================

begin

  HrkQuery.close;
  if Hrktranz.InTransaction then HrkTranz.Commit;
  HrkDbase.close;

  BizonylatPanel.Visible  := False;
  ActiveControl           := HrkAtadGomb;
end;

// =============================================================================
procedure TFORM2.REPRINTGOMBClick(Sender: TObject);
// =============================================================================

begin
  Nyomtatas;
end;




procedure TFORM2.SIGENGOMBClick(Sender: TObject);
begin
  Stornoedit.text := '';
  with Surefedel do
    begin
      top := 40;
      left := 16;
      visible := true;
    end;
  Activecontrol := stornoedit;
end;

procedure TFORM2.STORNOEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  _indok := trim(Stornoedit.Text);
  if _indok = '' then exit;
  Activecontrol := Stornogogomb;
end;



procedure TFORM2.STORNOGOGOMBClick(Sender: TObject);
begin
  Surefedel.Visible := False;
  SurePanel.visible := False;
  HrkQuery.close;
  Hrkdbase.close;
  _pcs := 'UPDATE HRKSZAMLAK SET STORNO=3 WHERE BIZONYLATSZAM='+chr(39)+_BIZONYLATSZAM+chr(39);
  HrkParancs(_pcs);
  Nyomtatas;
  Hrkregen;
  Modalresult := 1;
end;


// =============================================================================
                     procedure TForm2.Hrkregen;
// =============================================================================

begin
  _pcs := 'DELETE FROM HRKNAPLO';
  HrkParancs(_pcs);

  _pcs := 'SELECT * FROM HRKSZAMLAK' + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  HrkDbase.connected := true;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _aktdatum := FieldByNAme('DATUM').asString;
    end;

  _sumBe := 0;
  _sumKi := 0;
  _hnyito := 0;
  _hzaro  := 0;

  while not HrkQuery.eof do
    begin
      _datum := HrkQuery.FieldByNAme('DATUM').asString;
      _be := HrkQuery.fieldByNAme('BEVETEL').asInteger;
      _ki := HrkQuery.FieldByNAme('KIADAS').asInteger;

      if _aktdatum=_datum then
        begin
          _sumbe := _sumbe + _be;
          _sumki := _sumki + _ki;
          Hrkquery.next;
          Continue;
        end;

      Naplobair;

      _hnyito := _hzaro;
      _sumbe := _be;
      _sumki := _ki;
      _aktdatum := _datum;

      HrkQuery.next;
    end;

  Naplobair;

  _pcs := 'UPDATE HRKDATA SET AKTKESZLET=' + inttostr(_hzaro);
  HrkParancs(_pcs);
end;

// =============================================================================
                 procedure TForm2.Naplobair;
// =============================================================================

begin
  _hzaro := _hnyito+_sumbe-_sumki;
  _pcs := 'INSERT INTO HRKNAPLO (DATUM,NYITO,BEVETEL,KIADAS,ZARO)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _aktdatum + chr(39) + ',';
  _pcs := _pcs + inttostr(_hnyito) + ',';
  _pcs := _pcs + inttostr(_sumbe) + ',';
  _pcs := _pcs + inttostr(_sumki) + ',';
  _pcs := _pcs + inttostr(_hzaro) + ')';

  NaploParancs(_pcs);
end;


procedure TForm2.NaploParancs(_ukaz: string);

begin
  Naplodbase.Connected := True;
  if Naplotranz.InTransaction then Naplotranz.commit;
  NaploTranz.StartTransaction;
  with NaploQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  NaploTranz.commit;
  Naplodbase.close;
end;

end.
