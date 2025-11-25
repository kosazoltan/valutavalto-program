unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,DB, Grids, DBGrids, StrUtils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery, jpeg, printers,
  dateUtils;

type
  TFORM2 = class(TForm)
    HrkSource            : TDataSource;
    HrkRacs              : TDBGrid;
    HRKQuery             : TibQuery;
    HrkDbase             : TibDatabase;
    HrkTranz             : TibTransaction;

    ErtektarQuery        : TibQuery;
    ErtektarDbase        : TibDatabase;
    ErtektarTranz        : TibTransaction;

    AtadasPanel          : TPanel;
    HrkMenuPanel         : TPanel;
    Panel2               : TPanel;
    AtvetelPanel         : TPanel;
    BeBizPanel           : TPanel;
    BizonylatPanel       : TPanel;
    KezBizonyFocimPanel  : TPanel;
    StornoPanel          : TPanel;
    PillKezdijPanel      : TPanel;
    KiBizPanel           : TPanel;
    SurePanel            : TPanel;
    StornoFedel          : TPanel;
    PillOsszegPanel      : TPanel;

    Shape9               : TShape;
    Shape1               : TShape;
    Shape2               : TShape;
    Shape3               : TShape;

    Label1               : TLabel;
    Label2               : TLabel;
    Label3               : TLabel;
    Label4               : TLabel;
    Label11              : TLabel;
    Label5               : TLabel;
    Label6               : TLabel;
    Label7               : TLabel;
    Label8               : TLabel;
    Label9               : TLabel;
    Label10              : TLabel;
    Label21              : TLabel;

    BePenztarEdit        : TEdit;
    BeKunaEdit           : TEdit;
    IndokPanel           : TEdit;
    KiPenztarEdit        : TEdit;
    KiKunaEdit           : TEdit;

    BeKonyveloGomb       : TBitBtn;
    BeMegsemGomb         : TBitBtn;
    HrkAtadoGomb         : TBitBtn;
    SureGomb             : TBitBtn;
    NoSureGomb           : TBitBtn;
    KikonyveloGomb       : TBitBtn;
    HrkAtvevoGomb        : TBitBtn;
    HrkPILLGomb          : TBitBtn;
    HrkBizonylatGomb     : TBitBtn;
    VisszaGomb           : TBitBtn;
    StornoGOGomb         : TBitBtn;
    StornoGomb           : TBitBtn;
    ListaVisszaGomb      : TBitBtn;
    PillKeszBackGomb     : TBitBtn;
    ReprintGomb          : TBitBtn;
    StornoNoGomb         : TBitBtn;
    KiMegsemGomb         : TBitBtn;


    procedure AlapAdatBeolvasas;
    procedure BizonylatChange;
    procedure BePenztarEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure GetHrkData;
    procedure HrkForgDisplay(Sender: TObject);
    procedure HrkParancs(_ukaz: string);
    procedure HrkAtvevoGombClick(Sender: TObject);
    procedure HrkBizonylatGombClick(Sender: TObject);
    procedure HrkPILLGombClick(Sender: TObject);
    procedure HrkRacsCellClick(Column: TColumn);
    procedure HrkRacsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HrkRacsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure HrkRacsDblClick(Sender: TObject);
    procedure HrkAtadoGombClick(Sender: TObject);
    procedure KiPenztarEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KiKunaEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KiKonyveloGombClick(Sender: TObject);
    procedure SureGombClick(Sender: TObject);
    procedure StornoGoGombClick(Sender: TObject);
    procedure NoSureGombClick(Sender: TObject);
    procedure IndokPanelKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KezdParancs(_ukaz: string);
    procedure BeMegsemGombClick(Sender: TObject);
    procedure KozepreIr(_szoveg: string);
    procedure BeKunaEditEnter(Sender: TObject);
    procedure BeKunaEditExit(Sender: TObject);
    procedure BeKunaEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BeKonyveloGombClick(Sender: TObject);
    procedure ListaVisszaGombClick(Sender: TObject);
    procedure BeNyomtatas;
    procedure KiNyomtatas;
    procedure PillKeszBackGombClick(Sender: TObject);
    procedure PlombaAdatBeolvasas;
    procedure ReprintGombClick(Sender: TObject);
    procedure StornoGombClick(Sender: TObject);
    procedure TextKiiro;
    procedure VisszaGombClick(Sender: TObject);
    procedure VonalHuzo;
    procedure Hrkregen;

    function ForintForm(_sm:integer):string;
    function Getidos: string;
    function Nulele(_b, _h: integer): string;






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
  _LPath : string = 'C:\ERTEKTAR\AKTLST.TXT';
  _sorveg: string = chr(13) + chr(10);

  _printer,_penztarszam,_storno,_ertektar,_BILL: byte;
  _height,_width,_top,_left,_maiev,_maiho,_mainap,_kertho,_kertev: word;

  _BESorszam,_aktHrkKeszlet,_BEkuna,_kikuna,_kisorszam: integer;
  _nyito,_bevetel,_kiadas,_zaro,_recno: integer;

   _kezbBizszam,_kezKBizszam,_aktkezdij,_kezdij,_code,_mozgas: integer;
  _kezSbizszam,_plombaOke,_ptaroke,_stornom_nyito,_be,_ki: integer;

  _pcs,_plombaszam,_mamas,_szallitonev,_megjegyzes,_farok: string;
  _bizonylatszam,_penztarnev,_penztarcim,_bizkelte,_elojel,_cegnev: string;
  _tema,_ej,_aktPenztarszam,_aktPenztarnev,_origbizonylat,_indok: string;
  _stornobizonylat,_tipus,_penztarkod,_idos,_utdatum,_bizido: string;


  _oBizonylat,_ujrekord: boolean;

function penztarrutin: integer; stdcall; external 'c:\ertektar\bin\getptar.dll' name 'penztarrutin';
function getplombarutin: integer; stdcall; external 'c:\ertektar\bin\getplomb.dll' name 'getplombarutin';

function hrkatvevorutin: integer; stdcall;

implementation


{$R *.dfm}


// =============================================================================
              function hrkatvevorutin: integer; stdcall;
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
  _mainap:= dayof(date);
  _mamas := inttostr(_maiev)+'.'+nulele(_maiho,2)+'.'+nulele(_mainap,2);

  Visible := true;

  HrkRegen;
  AlapadatBeolvasas;
  
  _idos := Getidos;
  ActiveControl := HrkAtvevoGomb;
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
            procedure TFORM2.HRKATVEVOGOMBClick(Sender: TObject);
// =============================================================================

begin
  BeKonyvelogomb.Enabled := False;

  GetHrkData;
  inc(_BESorszam);

  _bizonylatszam := 'B-' + nulele(_beSorszam,5);
  BeBizPanel.Caption := _bizonylatszam;

  BePenztarEdit.Text := '';
  BeKunaedit.Text    := '';

  with AtvetelPanel do
    begin
      top     := 110;
      Left    := 30;
      Visible := True;
    end;

  BePenztarEdit.clear;
  ActiveControl := BePenztarEdit;
end;

// =============================================================================
             procedure TFORM2.BEKUNAEDITEnter(Sender: TObject);
// =============================================================================

begin

  TEdit(sender).Color := $B0FFFF;
end;

// =============================================================================
            procedure TFORM2.BEKUNAEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clWindow;
end;

procedure TFORM2.BEPENZTAREDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  _bill := ord(key);
  if _bill<>13 then exit;

  BeKunaEdit.clear;
  ActiveControl := BeKunaEdit;
end;



// =============================================================================
   procedure TFORM2.BEKUNAEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _bill: byte;

begin
  _bill := ord(key);
  if _bill<>13 then exit;

  BeKonyveloGomb.Enabled := True;
  ActiveControl := BeKonyveloGOmb;
end;

// =============================================================================
         procedure TFORM2.BEMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  AtvetelPanel.Visible := False;
  ActiveControl := HrkATVEVOGomb;
end;


// =============================================================================
           procedure TFORM2.BEKONYVELOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _aktpenztarszam := trim(BePenztaredit.Text);
  val(BeKunaEdit.text,_bekuna,_code);

  if _code<>0 then _bekuna := 0;
  if _bekuna=0 then
    begin
      ModalResult := 2;
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
  _bevetel  := _bekuna;
  _kiadas   := 0;
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
         _bevetel := _bevetel + _bekuna;
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
      _pcs := _pcs + inttostr(_zaro)+ ')';
    end else
    begin
      _pcs := 'UPDATE HRKNAPLO SET BEVETEL='+inttostr(_bevetel)+',ZARO='+inttostr(_zaro)+_sorveg;
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
      _beSorszam := FieldByNAme('BESORSZAM').asInteger;
      Close;
    end;
  Hrkdbase.close;

  inc(_beSorszam);

  _pcs := 'UPDATE HRKDATA SET BESORSZAM='+inttostr(_besorszam);
  _pcs := _pcs + ',AKTKESZLET=' + inttostr(_zaro);
  HrkParancs(_pcs);

  // ---------------------------------------------------------------------------
  // hrk-szamlak

  _bizonylatszam := 'B-'+nulele(_beSorszam,5);

  _pcs := 'INSERT INTO HRKSZAMLAK (DATUM,IDO,BIZONYLATSZAM,BEVETEL,';
  _pcs := _pcs + 'PENZTAR,STORNO,PLOMBASZAM,SZALLITONEV)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _idos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_bekuna) + ',';
  _pcs := _pcs + chr(39) + _aktpenztarszam + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + trim(_plombaszam) + chr(39) + ',';
  _pcs := _pcs + chr(39) + trim(_szallitonev) + chr(39) + ')';
  HrkParancs(_pcs);

  BeNyomtatas;
  AtvetelPanel.Visible := False;
end;


// =============================================================================
             procedure TFORM2.BeNyomtatas;
// =============================================================================

var _cim: string;

begin
  {

  123456789012345678901234567890123456789
         EXCLUSIVE BEST CHANGE ZRT
            KECSKEMÉT, INTERSPAR
      KECSKEMET, CSOKONAI MIHÁLY U.44
  -----------------------------------------
      HORVÁT KUNA ATVÉTELI BIZONYLATA
  -----------------------------------------
        Bizonylatszam : B-000123
      Bizonylat kelte : 2016.12.12
        Atadó pénztár : 143
        Átavett összeg: 123 456 000 HRK
  ------------------------------------------
   }

  AssignFile(_LFile,_Lpath);
  rewrite(_LFile);

  Kozepreir(_cegnev);
  Kozepreir(_penztarnev);
  Kozepreir(_penztarcim);
  VonalHuzo;
  if _storno>1 then
    begin
      Kozepreir('(ez a bizonylat stornozott)');
      if _indok<>'' then Kozepreir('(Indok: ' + _indok + ')');
    end;

  _cim := '     HORVÁT KUNA BEVÉTELI BIZONYLATA';
  WriteLn(_LFile,_cim);

  VonalHuzo;
  writeLn(_LFile,'      Bizonylatszam: ' + _bizonylatszam);
  writeLn(_LFile,'    Bizonylat kelte: ' + _mamas);

  writelN(_LFile,'      Átadó pénztár: '+_aktpenztarszam);

  write(_LFile,'Bevételezett összeg: ');
  writeLn(_LFile,forintform(_bekuna)+' HRK');
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
             procedure TFORM2.KiNyomtatas;
// =============================================================================

var _cim: string;

begin
  {

  123456789012345678901234567890123456789
         EXCLUSIVE BEST CHANGE KFT
            KECSKEMÉT, INTERSPAR
      KECSKEMET, CSOKONAI MIHÁLY U.44
  -----------------------------------------
      HORVÁT KUNA ATADÁSI BIZONYLATA
  -----------------------------------------
        Bizonylatszam : B-000123
      Bizonylat kelte : 2016.12.12
       Fogadó pénztár : 143
        Átadott összeg: 123 456 000 HRK
  ------------------------------------------
   }

  AssignFile(_LFile,_Lpath);
  rewrite(_LFile);

  Kozepreir(_cegnev);
  Kozepreir(_penztarnev);
  Kozepreir(_penztarcim);
  VonalHuzo;
  if _storno>1 then Kozepreir('(ez a bizonylat stornozott)');

  _cim := '     HORVÁT KUNA ÁTADÁSI BIZONYLATA';
  WriteLn(_LFile,_cim);

  VonalHuzo;
  writeLn(_LFile,'      Bizonylatszam: ' + _bizonylatszam);
  writeLn(_LFile,'    Bizonylat kelte: ' + _mamas);
  writeLn(_LFile,'     Fogadó pénztár: ' + _aktpenztarszam);

  write(_LFile,'     Átadott összeg: ');
  writeLn(_LFile,forintform(_kikuna)+' HRK');
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

// =============================================================================
             procedure TFORM2.PillKeszBackGombClick(Sender: TObject);
// =============================================================================

begin
  Pillkezdijpanel.Visible := false;
  ActiveControl := HrkAtvevoGomb;
end;

// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
       procedure TFORM2.HRKBIZONYLATGOMBClick(Sender: TObject);
// =============================================================================

begin
  Stornopanel.Visible := False;
  with BizonylatPanel do
     begin
       Top     := 0;
       Left    := 0;
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

   If _bizkelte<_mamas then StornoGomb.Enabled := False;

end;

// =============================================================================
                procedure TFORM2.STORNOGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _bizkelte<_mamas then
    begin
      Showmessage('CSAK MAI NAPI BIZONYLAT STORNÓZHATÓ');
      HrkForgDisplay(Nil);
      exit;
    end;

   _indok := ''; 
   IndokPanel.clear;
   stornoFedel.Visible := False;
   with SurePanel do
     begin
       Top := 160;
       Left := 184;
       Visible := True;
     end;
   Activecontrol := SureGomb;
end;

// =============================================================================
            procedure TFORM2.SUREGOMBClick(Sender: TObject);
// =============================================================================

begin
  StornoFedel.Visible := True;
  ActiveControl := IndokPanel;
end;

// =============================================================================
          procedure TFORM2.NOSUREGOMBClick(Sender: TObject);
// =============================================================================

begin
  SurePanel.Visible := False;
  HrkRacs.setfocus;
end;

// =============================================================================
           procedure TFORM2.STORNOGOGOMBClick(Sender: TObject);
// =============================================================================

begin
  SurePanel.Visible := False;
  HrkQuery.close;
  HrkDbase.close;
  _storno:= 2;

  _pcs := 'UPDATE HRKSZAMLAK SET STORNO=2 WHERE BIZONYLATSZAM='+CHR(39)+_bizonylatszam+chr(39);
  HrkParancs(_pcs);

  if leftstr(_bizonylatszam,1)='B' then
    begin
      _bekuna := trunc((-1)*_bevetel);
      Benyomtatas
    end else
    begin
      _kikuna := trunc((-1)*_kiadas);
      kinyomtatas;
    end;

  _indok := '';

  HrkRegen;
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
  ErtektarDbase.connected := True;
  with ErtektarQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _printer := FieldByName('PRINTER').asInteger;
      Close;

      Sql.clear;
      Sql.add('SELECT * FROM PENZTAR');
      Open;
      _penztarkod := trim(FieldByNAme('PENZTARKOD').AsString);
      _penztarnev := trim(FieldByNAme('PENZTARNEV').asString);
      _penztarcim := trim(FieldByNAme('PENZTARCIM').AsString);
      Close;
    end;
  ErtektarDbase.close;

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
      _beSorszam:= FieldByName('BESORSZAM').asInteger;
      _kisorszam := FieldByName('KISORSZAM').asInteger;
      Close;
    end;

  HrkDbase.close;
end;

// =============================================================================
                   procedure TForm2.PlombaAdatBeolvasas;
// =============================================================================

begin
  ErtektarDbase.Connected := true;
  with ErtektarQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM VTEMP');
      Open;

      _szallitonev := trim(FieldbyNAme('SZALLITONEV').asString);
      _plombaszam := trim(FieldByNAme('PLOMBASZAM').asString);

      _megjegyzes := trim(FieldbyNAme('MEGJEGYZES').asString);
      Close;
    end;
  ErtektarDbase.Close;
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
  ActiveControl           := HrkAtvevoGomb;
end;

// =============================================================================
procedure TFORM2.REPRINTGOMBClick(Sender: TObject);
// =============================================================================

begin
  if leftstr(_bizonylatszam,1)='B' then
    begin
      _bekuna := _bevetel;
      if _storno>1 then _bekuna := trunc((-1)*_bevetel);
      Benyomtatas
    end else
    begin
      _kikuna := _kiadas;
      if _storno>1 then _kikuna := trunc((-1)*_kiadas);
      kinyomtatas;
    end;
end;

// =============================================================================
                        procedure TForm2.Hrkregen;
// =============================================================================

begin
  _nyito := 0;
  _be := 0;
  _ki := 0;
  _pcs := 'SELECT * FROM HRKSZAMLAK WHERE STORNO=1';
  hRKDBASE.CONNECTED := TRUE;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not hrkquery.eof do
    begin
      _bevetel := HrkQuery.fieldByNAme('BEVETEL').asInteger;
      _kiadas  := HrkQuery.FieldByName('KIADAS').asInteger;
      _be := _be + _bevetel;
      _ki := _ki + _kiadas;
      Hrkquery.next;
    end;

  Hrkquery.close;
  Hrkdbase.close;

  _zaro := _nyito + _be - _ki;

  _pcs := 'UPDATE HRKDATA SET AKTKESZLET='+inttostr(_zaro);
  HrkParancs(_pcs);
end;

// =============================================================================
          procedure TFORM2.HRKATADOGOMBClick(Sender: TObject);
// =============================================================================

begin
  KiKonyvelogomb.Enabled := False;

  GetHrkData;
  inc(_KISorszam);

  _bizonylatszam := 'K-' + nulele(_kiSorszam,5);
  KiBizPanel.Caption := _bizonylatszam;

  KiPenztarEdit.Text := '';
  KiKunaedit.Text    := '';

  with AtadasPanel do
    begin
      top     := 110;
      Left    := 30;
      Visible := True;
    end;

  KiPenztarEdit.clear;
  ActiveControl := KiPenztarEdit;
end;

// =============================================================================
     procedure TFORM2.KIPENZTAREDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  _bill := ord(key);
  if _bill<>13 then exit;

  KiKunaEdit.clear;
  ActiveControl := KiKunaEdit;
end;

// =============================================================================
       procedure TFORM2.KIKUNAEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
 _bill := ord(key);
  if _bill<>13 then exit;

  KiKonyveloGomb.Enabled := True;
  ActiveControl := KiKonyveloGOmb;
end;

// =============================================================================
           procedure TFORM2.kikonyveloGombClick(Sender: TObject);
// =============================================================================

begin
 _aktpenztarszam := trim(kiPenztaredit.Text);
  val(KiKunaEdit.text,_kikuna,_code);

  if _code<>0 then _kikuna := 0;
  if _kikuna=0 then
    begin
      ModalResult := 2;
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
         _nyito    := Hrkquery.FieldByNAme('NYITO').asInteger;
         _bevetel  := HrkQuery.FieldByNAme('BEVETEL').asInteger;
         _kiadas   := HrkQuery.FieldByNAme('KIADAS').asInteger;
         _kiadas  := _kiadas + _kikuna;
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
      _pcs := _pcs + inttostr(_zaro)+ ')';
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
  _pcs := _pcs + chr(39) + _aktpenztarszam + chr(39) + ',';
  _pcs := _pcs + '1,';
  _pcs := _pcs + chr(39) + trim(_plombaszam) + chr(39) + ',';
  _pcs := _pcs + chr(39) + trim(_szallitonev) + chr(39) + ')';
  HrkParancs(_pcs);

  KiNyomtatas;
  AtadasPanel.Visible := False;
end;

procedure TFORM2.INDOKPANELKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(kEY)<>13 THEN exit;
  _indok := trim(indokpanel.Text);
  ActiveControl := Stornogogomb;
end;


end.
