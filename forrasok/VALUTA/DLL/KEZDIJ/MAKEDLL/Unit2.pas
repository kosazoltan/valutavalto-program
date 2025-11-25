unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,DB, Grids, DBGrids, StrUtils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery, jpeg, printers,
  dateUtils;

type
  TKDADVET = class(TForm)
    valutaDBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    KEZDIJPANEL: TPanel;
    Panel2: TPanel;
    KEZDATVETGOMB: TBitBtn;
    KEZDATADGOMB: TBitBtn;
    KEZDPILLGOMB: TBitBtn;
    KEZDBIZONYLATGOMB: TBitBtn;
    KEZDVISSZAGOMB: TBitBtn;
    Shape6: TShape;
    KEZELESIFOPANEL: TPanel;
    KEZFOCIMPANEL: TPanel;
    Shape7: TShape;
    Label9: TLabel;
    Label11: TLabel;
    KEZBIZPANEL: TPanel;
    TARSPENZTARPANEL: TPanel;
    ADOTTVETTPANEL: TPanel;
    KEZDIJEDIT: TEdit;
    KEZKONYVELOGOMB: TBitBtn;
    KEZKONYVMEGSEMGOMB: TBitBtn;
    KEZBIZONYLATPANEL: TPanel;
    KEZBIZRACS: TDBGrid;
    KEZDIJTABLA: TIBTable;
    KEZDIJDBASE: TIBDatabase;
    KEZDIJTRANZ: TIBTransaction;
    kezdijsource: TDataSource;
    MAIKEZDIJGOMB: TBitBtn;
    OLDKEZDIJGOMB: TBitBtn;
    KEZBIZSTORNOGOMB: TBitBtn;
    Kezbizvegegomb: TBitBtn;
    KEZBIZONYFOCIMPANEL: TPanel;
    hovalasztopanel: TPanel;
    Shape8: TShape;
    evcombo: TComboBox;
    hocombo: TComboBox;
    Label13: TLabel;
    hookegomb: TButton;
    homegsemgomb: TButton;
    STORNOPANEL: TPanel;
    PILLKEZDIJPANEL: TPanel;
    Label21: TLabel;
    PILLOSSZEGPANEL: TPanel;
    Shape9: TShape;
    PillKeszBackGomb: TBitBtn;
    REPRINTGOMB: TBitBtn;
    Shape1: TShape;
    kezdijquery: TIBQuery;
    KEZDIJTABLADATUM: TIBStringField;
    KEZDIJTABLAELOJEL: TIBStringField;
    KEZDIJTABLAKEZELESIDIJ: TIntegerField;
    KEZDIJTABLAPENZTAR: TIBStringField;
    KEZDIJTABLASTORNO: TSmallintField;
    KEZDIJTABLAMOZGAS: TSmallintField;
    KEZDIJTABLABIZONYLAT: TIBStringField;
    KEZDIJTABLAORIGBIZONYLAT: TIBStringField;
    KEZDIJTABLASZALLITONEV: TIBStringField;
    KEZDIJTABLAPLOMBASZAM: TIBStringField;

    procedure FormActivate(Sender: TObject);
    function ForintForm(_sm:integer):string;
    procedure KozepreIr(_szoveg: string);
    procedure TextKiiro;
    procedure VonalHuzo;
    procedure GetKezBizSzamok;
    procedure KozosKezdijRutin;
    procedure PlombaAdatBeolvasas;
    function Nulele(_b, _h: integer): string;
    procedure NapiKezdijDisplay(Sender: TObject);
    procedure Ptarbeolvasas;
    procedure AlapAdatBeolvasas;
    procedure KezdijNyomtatas(_t: string);
    procedure ValutaParancs(_ukaz: string);
    procedure BizonylatChange;
    procedure KEZBIZRACSCellClick(Column: TColumn);
    procedure KEZBIZRACSKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KEZBIZRACSMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure KEZBIZRACSDblClick(Sender: TObject);
    procedure KezdParancs(_ukaz: string);
  
    procedure KEZDATVETGOMBClick(Sender: TObject);
    procedure KEZDIJEDITEnter(Sender: TObject);
    procedure KEZDIJEDITExit(Sender: TObject);
    procedure KEZDIJEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KEZKONYVELOGOMBClick(Sender: TObject);
    procedure KEZKONYVMEGSEMGOMBClick(Sender: TObject);
    procedure KEZDATADGOMBClick(Sender: TObject);
    procedure KEZDBIZONYLATGOMBClick(Sender: TObject);
    procedure KEZDPILLGOMBClick(Sender: TObject);
    procedure KEZDVISSZAGOMBClick(Sender: TObject);
    procedure PillKeszBackGombClick(Sender: TObject);
    procedure KezbizvegegombClick(Sender: TObject);
    procedure OLDKEZDIJGOMBClick(Sender: TObject);
    procedure homegsemgombClick(Sender: TObject);
    procedure evcomboChange(Sender: TObject);
    procedure hookegombClick(Sender: TObject);
    procedure KEZBIZSTORNOGOMBClick(Sender: TObject);
    procedure REPRINTGOMBClick(Sender: TObject);


  private
    { Private declarations }

  public
    { Public declarations }
  end;

var
  KDAdVet: TKDAdVet;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                 'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                                             'NOVEMNER','DECEMBER');

  _Lfile : textfile;
  _LPath : string = 'C:\VALUTA\AKTLST.TXT';
  _sorveg: string = chr(13) + chr(10);

  _gepfunkcio,_printer,_penztarszam: byte;
  _height,_width,_top,_left,_maiev,_maiho,_kertho,_kertev: word;

   _kezbBizszam,_kezKBizszam,_aktkezdij,_kezdij,_code,_mozgas: integer;
  _kezSbizszam,_plombaOke,_ptaroke,_storno: integer;

  _pcs,_plombaszam,_megnyitottnap,_szallitonev,_megjegyzes,_farok: string;
  _bizonylat,_penztarnev,_penztarcim,_bizkelte,_elojel,_cegnev: string;
  _tema,_ej,_aktPenztarszam,_aktPenztarnev,_origbizonylat: string;
  _stornobizonylat,_tipus,_penztarkod: string;


  _oBizonylat: boolean;

function kezdijatadorutin: integer; stdcall;
function penztarrutin: integer; stdcall; external 'c:\valuta\bin\getptar.dll' name 'penztarrutin';
function getplombarutin: integer; stdcall; external 'c:\valuta\bin\getplomb.dll' name 'getplombarutin';


implementation


{$R *.dfm}

function kezdijatadorutin: integer; stdcall;
begin
  KdAdvet := TKdAdvet.create(NIL);
  result := Kdadvet.showmodal;
  kdadvet.free;
end;


// =============================================================================
              procedure TKDADVET.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top := trunc((_height-400)/2);
  _left := trunc((_width-640)/2);

  Top  := _top;
  Left := _left;

  Height := 400;
  Width := 640;

  with Kezdijpanel do
    begin
      Top := 0;
      Left := 0;
    end;

  _maiev := yearof(date);
  _maiho := monthof(date);

  Visible := true;

  AlapadatBeolvasas;
  ActiveControl := KezdAtvetGomb;
end;

// =============================================================================
           procedure TKDADVET.KEZDATVETGOMBClick(Sender: TObject);
// =============================================================================

begin
  _tema := 'B';
  KozosKezdijRutin;
end;

// =============================================================================
            procedure TKDADVET.KEZDATADGOMBClick(Sender: TObject);
// =============================================================================

begin
   _tema := 'K';
  KozosKezdijRutin;
end;

// =============================================================================
               procedure TKDADVET.KozosKezdijrutin;
// =============================================================================

begin
  Kezkonyvelogomb.Enabled := False;

  _PtarOke := penztarrutin;
  PtarBeolvasas;
  if _ptaroke<>1 then exit;

  PtarBeolvasas;
  GetKezBizSzamok;

  _storno := 1;

  if _tema='B' then
  begin
    inc(_kezBBizSzam);
    _Bizonylat := 'B-' + nulele(_kezbbizszam,6);
    KezfocimPanel.Caption := 'KEZELÉSI KÖLTSÉGEK ÁTVÉTELE';
    Adottvettpanel.caption := 'Átvett összeg:';
    if _gepfunkcio=2 then _mozgas := 4 else _mozgas := 2;
  end else
  begin
    inc(_kezKBizSzam);
    _bizonylat := 'K-' + nulele(_kezKbizszam,6);
    KezfocimPanel.Caption := 'KEZELÉSI KÖLTSÉGEK ÁTADÁSA';
    AdottvettPanel.caption := 'Átadott összeg:';
    if _gepfunkcio=2 then _mozgas := 5 else _mozgas := 3;
  end;

  KezbizPanel.Caption := _bizonylat;
  with KezelesiFopanel do
    begin
      top     := 110;
      Left    := 30;
      Visible := True;
    end;

  TarsPenztarPanel.Caption := _aktpenztarszam;
  KezdijEdit.clear;
  ActiveControl := KezdijEdit;
end;

// =============================================================================
             procedure TKDADVET.KEZDIJEDITEnter(Sender: TObject);
// =============================================================================

begin
  KezdijEdit.Color := $B0FFFF;
end;

// =============================================================================
            procedure TKDADVET.KEZDIJEDITExit(Sender: TObject);
// =============================================================================

begin
  KezdijEdit.Color := clWindow;
end;

// =============================================================================
   procedure TKDADVET.KEZDIJEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _bill: byte;

begin
  _bill := ord(key);
  if _bill<>13 then exit;
  KezkonyveloGomb.Enabled := true;
  ActiveControl := KezKonyveloGOmb;
end;

// =============================================================================
         procedure TKDADVET.KEZKONYVMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  KezelesiFopanel.Visible := False;
  ActiveControl := KezdAtvetGomb;
end;


// =============================================================================
           procedure TKDADVET.KEZKONYVELOGOMBClick(Sender: TObject);
// =============================================================================

begin
  KezelesiFopanel.Visible := False;
  (* Kezelesidij táblába beir:  DATUM,BIZONYLAT,ELOJEL,KEZELESIDIJ,
                                PENZTAR,STORNO,MOZGAS
     Kezelesidata táblába beir: UTBEVET (a bizonylat sorszámát)
                        aktulizálni AKTKEZELESIDIJ - at

  *)

  val(Kezdijedit.text,_kezdij,_code);
  if _code<>0 then _kezdij := 0;
  if _kezdij= 0 then
    begin
      ModalResult := 2;
      exit;
    end;

  if _tema='K' then
    begin
      if _kezdij>_aktkezdij then
        begin
          ShowMessage('Ennyi kezelési díj nincs !');
          Modalresult := 2;
          exit;
        end;
     end;
        
  _plombaOke := getplombarutin;
  if _plombaOke=2 then
    begin
      ModalResult := 2;
      exit;
    end;

  PlombaAdatBeolvasas;

  _ej := '+';
  if _tema='K' then _ej := '-';

  _pcs := 'INSERT INTO KEZELESIDIJ (DATUM,BIZONYLAT,ELOJEL,KEZELESIDIJ,';
  _pcs := _pcs + 'PENZTAR,STORNO,MOZGAS,PLOMBASZAM,SZALLITONEV)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ej + chr(39) + ',';
  _pcs := _pcs + inttostr(_kezdij) + ',';
  _pcs := _pcs + chr(39) + trim(_aktpenztarszam) + chr(39) + ',';
  _pcs := _pcs + '1,' + inttostr(_mozgas)+',';
  _pcs := _pcs + chr(39) + trim(_plombaszam) + chr(39) + ',';
  _pcs := _pcs + chr(39) + trim(_szallitonev) + chr(39) + ')';
  ValutaParancs(_pcs);

  if _tema='B' then
    begin
      _aktkezdij := _aktkezdij + _kezdij;
      _pcs := 'UPDATE KEZELESIDATA SET UTBEVET='+inttostr(_kezBBizszam)+',';
     _pcs := _pcs + 'AKTKEZELESIDIJ='+inttostr(_aktkezdij);
    end else
    begin
      _aktkezdij := _aktkezdij - _kezdij;
      _pcs := 'UPDATE KEZELESIDATA SET UTKIADAS='+inttostr(_kezKBizszam)+',';
      _pcs := _pcs + 'AKTKEZELESIDIJ='+inttostr(_aktkezdij);
    end;

  ValutaParancs(_pcs);

  kezdijNyomtatas(_tema);
  TextKiiro;  // 2-ik példány
  KezelesiFoPanel.Visible := False;
end;

// =============================================================================
         procedure TKDADVET.KEZDVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
          procedure TKDADVET.KEZDPILLGOMBClick(Sender: TObject);
// =============================================================================

begin
  GetKezBizSzamok;
  Pillosszegpanel.Caption := ForintForm(_aktkezdij)+' Ft';
  with PillKezdijpanel do
    begin
      Top := 136;
      Left := 52;
      Visible := True;
    end;
  PillkezdijPanel.Repaint;
end;

procedure TKDADVET.PillKeszBackGombClick(Sender: TObject);
begin
  Pillkezdijpanel.Visible := false;
  ActiveControl := KezdAtvetGomb;
end;

// =============================================================================
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
       procedure TKDADVET.KEZDBIZONYLATGOMBClick(Sender: TObject);
// =============================================================================

begin
  Stornopanel.Visible := false;
  Maikezdijgomb.Enabled := true;
  OldKezdijGomb.Enabled := True;
  with KezBizonylatPanel do
     begin
       Top := 0;
       Left := 0;
       Visible := true;
     end;
   NapiKezdijDisplay(Nil);
end;

// =============================================================================
                procedure TKDADVET.NapiKezdijDisplay(Sender: TObject);
// =============================================================================

begin

  MaiKezdijgomb.Enabled := False;
  KezdijSource.Enabled := False;
  KezbizStornoGomb.Enabled := False;

  with KezdijDbase do
    begin
      Close;
      DatabaseName := 'c:\valuta\database\valuta.fdb';
      Connected := true;
    end;

  if KezdijTranz.InTransaction then KezdijTranz.commit;
  Kezdijtranz.StartTransaction;

  with KezdijTabla do
    begin
      close;
      TableName := 'KEZELESIDIJ';
      Open;
      First;
    end;

  BizonylatChange;
  KezdijSource.Enabled := True;

  _oBizonylat := False;

  Kezbizracs.SelectedIndex := 0;
  KezBizRacs.setfocus;
end;


// =============================================================================
                    procedure TKdAdvet.Bizonylatchange;
// =============================================================================

begin
  with KezdijTabla do
    begin
      _bizkelte := FieldbyName('DATUM').asstring;
      _elojel := FieldByName('ELOJEL').asString;
      _kezdij := FieldByName('KEZELESIDIJ').asInteger;
      _mozgas := FieldByName('MOZGAS').asInteger;
      _aktpenztarszam := FieldByName('PENZTAR').asString;
      _Bizonylat := FieldByName('BIZONYLAT').asString;
      _origbizonylat := FieldByName('ORIGBIZONYLAT').asString;
      _storno := FieldByName('STORNO').asInteger;
    end;
  if _storno>1 then stornopanel.visible := true else stornopanel.visible := false;
  KezbizStornoGomb.Enabled := True;
  IF (_storno>1) or (_obizonylat) then KezbizStornoGomb.Enabled := False;
  if _mozgas=1 then KezbizstornoGomb.Enabled := false;

end;



// =============================================================================
         procedure TKdAdVET.KEZBIZRACSDblClick(Sender: TObject);
// =============================================================================

begin
  BizonylatChange;
end;

// =============================================================================
         procedure TKdAdVET.KEZBIZRACSCellClick(Column: TColumn);
// =============================================================================

begin
  BizonylatChange;
end;

// =============================================================================
     procedure TKdAdVET.KEZBIZRACSKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  BizonylatChange;
end;

// =============================================================================
       procedure TKdAdVET.KEZBIZRACSMouseUp(Sender: TObject;
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
                    procedure TKDADVET.AlapAdatBeolvasas;
// =============================================================================

var _kftnev: string;

begin
  valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _gepfunkcio := FieldByName('GEPFUNKCIO').asInteger;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
      _printer := FieldByName('PRINTER').asInteger;
      _kftnev := trim(FieldbyNAme('KFTNEV').AsString);
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
  if _penztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
    end else
    begin
      _cegnev := 'EXPRESSZ EKSZERHAZ ES MINIBANK KFT';
    end;

end;


// =============================================================================
                  procedure TKDADVET.GetKezBizSzamok;
// =============================================================================


begin
  Valutadbase.Connected := True;
  with Valutaquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM KEZELESIDATA');
      Open;
      _aktkezdij   := Fieldbyname('AKTKEZELESIDIJ').asInteger;
      _kezBBizszam := FieldByName('UTBEVET').asInteger;
      _kezKBizszam := FieldByName('UTKIADAS').asInteger;
      _kezSBizszam := FieldbyName('UTSTORNO').asInteger;
      Close;
    end;
  Valutadbase.close;
end;



// =============================================================================
                       procedure TKDADVET.Ptarbeolvasas;
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
                   procedure TKDADVET.PlombaAdatBeolvasas;
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
          procedure TKDADVET.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.connected := true;
  if ValutaTranz.InTransaction then valutatranz.commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.commit;
  ValutaDbase.close;
end;


// =============================================================================
          procedure TKDADVET.KezdParancs(_ukaz: string);
// =============================================================================

begin
  Kezdijdbase.connected := true;
  if KezdijTranz.InTransaction then Kezdijtranz.commit;
  Kezdijtranz.StartTransaction;
  with KezdijQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  KezdijTranz.commit;
  KezdijDbase.close;
end;



// =============================================================================
          procedure TKDADVET.KezdijNyomtatas(_t: string);
// =============================================================================



begin
  {

  123456789012345678901234567890123456789
           EXCLUSIVE BEST  CHANGE
            KECSKEMÉT, INTERSPAR
      KECSKEMET, CSOKONAI MIHÁLY U.44
  -----------------------------------------
    KEZELESI KOLTSEG ATVETELI BIZONYLATA
  -----------------------------------------
        Bizonylatszam: B-000123
      Bizonylat kelte: 2016.12.12
        Atadó pénztár: 143
        Átvett összeg: 123 456 000 Ft
  ------------------------------------------
   }

  AssignFile(_LFile,_Lpath);
  rewrite(_LFile);

  Kozepreir(_cegnev);
  Kozepreir(_penztarnev);
  Kozepreir(_penztarcim);
  VonalHuzo;

  if _storno= 1 then
    begin
      if _T = 'B' then WriteLn(_LFile,' KEZELESI KOLTSEG ATVETELI BIZONYLATA')
      else WriteLn(_LFile,' KEZELESI KOLTSEG ATADASI BIZONYLATA');
    end else
    begin
      if _storno=2 then writeLn(_LFile,'    SZTORNOZOTT BIZONYLAT')
      else WriteLn(_LFile,' KEZELESI KOLTSEG SZTORNO BIZONYLATA');
    end;

  if _storno=3 then _kezdij := trunc((-1)*_kezdij);  

  VonalHuzo;
  writeLn(_LFile,'      Bizonylatszam: ' + _bizonylat);
  writeLn(_LFile,'    Bizomylat kelte: ' + _megnyitottnap);

  if _t='B' then write(_LFile,'      Átadó pénztár: ') else write(_LFile,'     Átvevö pénztár: ');
  writeLn(_LFile,_aktpenztarszam);

  if _t='B' then write(_LFile,'      Átvett összeg: ') else write(_LFile,'     Átadott összeg: ');
  writeLn(_LFile,forintform(_kezdij)+' Ft');
  VonalHuzo;

  if _storno=1 then
    begin
      writeLn(_LFile,'Szállitónév: '+_szallitonev);
      writeLn(_LFile,'Plomba-szám: '+_plombaszam);
      writeLn(_LFile,' Megjegyzés: '+_megjegyzes);
      writeLn(_lFile,_sorveg+_sorveg);
      writeLN(_Lfile,'..................  ...................');
      writeLn(_LFile,'      atado                 atvevo     ');
      writeLn(_LFile,_sorveg);
    end else
    begin
      writeLN(_Lfile,'Stornozást végezte:'+_sorveg+_sorveg);
      writeLn(_LFile,'.......................');
    end;

  CloseFile(_Lfile);
  TextKiiro;
end;

// =============================================================================
                         procedure TKdAdVET.TextKiiro;
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
             function TKDADVET.ForintForm(_sm:integer):string;
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
                          procedure TKdAdVET.Vonalhuzo;
// =============================================================================

begin
  writeLn(_LFile,dupestring('-',39));
end;


// =============================================================================
                     procedure TKdAdVET.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;

// =============================================================================
         function TKDADVET.Nulele(_b,_h: integer): string;
// =============================================================================

begin
  result := inttostr(_b);
  while length(result)<_h do result := '0' + result;
end;

// =============================================================================
           procedure TKDADVET.KezbizvegegombClick(Sender: TObject);
// =============================================================================

begin

  KezdijTabla.close;
  if Kezdijtranz.InTransaction then KezdijTranz.Commit;
  KezdijDbase.close;

  HovalasztoPanel.Visible := False;
  KezBizonylatPanel.Visible := False;
  ActiveControl := KezdAtvetGomb;
end;

procedure TKDADVET.OLDKEZDIJGOMBClick(Sender: TObject);

VAR _Y: BYTE;

begin
  KezbizStornogomb.Enabled := False;
  KezdijTabla.close;
  if Kezdijtranz.InTransaction then KezdijTranz.Commit;
  Kezdijdbase.close;

  Oldkezdijgomb.Enabled := false;
  evcombo.Items.clear;
  evcombo.Items.Add(inttostr(_maiev-1));
  evcombo.Items.Add(inttostr(_maiev));
  evcombo.ItemIndex := 1;

  hocombo.Items.clear;
  _y := 1;
  while _y<=12 do
    begin
      hocombo.Items.Add(_honev[_y]);
      inc(_y);
    end;
  Hocombo.itemindex := _maiho-1;

  with HovalasztoPanel do
    begin
      Top  := 152;
      left := 176;
      Visible := true;
    end;
  Activecontrol := HoOkeGomb;
end;

procedure TKDADVET.homegsemgombClick(Sender: TObject);
begin
  HovalasztoPanel.Visible := False;
  MaiKezdijgomb.Enabled := True;
  OldKezdijGomb.Enabled := True;
  KezbizStornoGomb.Enabled := False;
end;

procedure TKDADVET.evcomboChange(Sender: TObject);
begin
  ActiveControl := HoOkeGomb;
end;

procedure TKDADVET.hookegombClick(Sender: TObject);

VAR _KFOCIM: STRING;

begin
  _kertho := 1 + Hocombo.itemindex;
  _kertev := _maiev-1+evcomBo.itemindex;

  _FAROK := inttostr(_kertev-2000)+nulele(_kertho,2);
  HovalasztoPanel.Visible := false;

  Kezdijtabla.close;
  if kezdijtranz.InTransaction then Kezdijtranz.commit;
  Kezdijdbase.close;

  Kezdijdbase.DatabaseName := 'c:\valuta\database\valdata.fdb';
  Kezdijdbase.Connected := True;
  KezdijTabla.TableName := 'KEZD' + _farok;
  if not Kezdijtabla.Exists then
    begin
      if Kezdijtranz.InTransaction then KezdijTranz.Commit;
      Kezdijdbase.close;
      Oldkezdijgomb.Enabled := true;
      exit;
    end;

  _kfocim := inttostr(_kertev)+' '+_honev[_kertho]+ ' HÓNAP BIZONYLATAI';
  KezbizonyFocimPanel.Caption := _kfocim;
  KezbizonyFocimpanel.repaint;

  Kezdijtabla.Open;
  KezdijTabla.first;
  _obizonylat := true;

  Maikezdijgomb.Enabled := true;

  BizonylatChange;
  KezdijSource.Enabled := True;

  Kezbizracs.SelectedIndex := 0;
  KezBizRacs.setfocus;
end;

procedure TKDADVET.KEZBIZSTORNOGOMBClick(Sender: TObject);

VAR _SURE,_contraElojel: STRING;
   
begin
  _storno := KezdijTabla.FieldByNAme('STORNO').asInteger;
  if _storno>1 then exit;

  _BIZKELTE := trim(Kezdijtabla.fieldbyname('DATUM').asString);
  if _bizkelte<>_megnyitottnap then exit;

  _sure := InputBox('TÖRLÉS MEGERÕSITÉSE', 'Biztosan stornózzam ?', 'Igen/Nem');
  _sure := uppercase(LEFTSTR(_sure,1));

  if _sure = 'N' then EXIT;

  _kezdij := KezdijTabla.fieldByName('KEZELESIDIJ').asInteger;
  _aktpenztarszam := trim(Kezdijtabla.FieldByNAme('PENZTAR').AsString);
  _elojel := KezdijTabla.FieldByNAme('ELOJEL').asString;
  _mozgas := KezdijTabla.FieldByNAme('MOZGAS').asInteger;
  _origbizonylat := KezdijTabla.FieldByNAme('BIZONYLAT').asString;
  _tipus := leftstr(_origbizonylat,1);

  KezdijTabla.edit;
  Kezdijtabla.FieldByName('STORNO').asInteger := 2;
  Kezdijtabla.Post;
  Kezdijtranz.commit;
  Kezdijdbase.close;
  Kezdijtabla.close;

  GetKezBizSzamok;
  inc(_kezSBizszam);

  _stornobizonylat := 'S-' + nulele(_kezSbizszam,6);

  _contraElojel := '+';
  if _elojel='+' then
    begin
      _contraElojel := '-';
      _aktkezdij := _aktkezdij-_kezdij;
    end else
    begin
      _contraElojel := '+';
      _aktkezdij := _aktkezdij + _kezdij;
    end;

  /// -----------------------------------
  _storno    := 3;

  _pcs := 'INSERT INTO KEZELESIDIJ (DATUM,BIZONYLAT,MOZGAS,KEZELESIDIJ,';
  _pcs := _pcs + 'STORNO,PENZTAR,ELOJEL,ORIGBIZONYLAT)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _stornobizonylat + chr(39) + ',';
  _pcs := _pcs + inttostr(_mozgas) + ',';
  _pcs := _pcs + inttostr(_kezdij) +',';
  _pcs := _pcs + inttostr(_storno) + ',';
  _pcs := _pcs + chr(39) + _aktpenztarszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _contraElojel + chr(39) + ',';
  _pcs := _pcs + chr(39) + _origbizonylat + chr(39) + ')';
  KezdParancs(_pcs);


  _pcs := 'UPDATE KEZELESIDATA SET AKTKEZELESIDIJ=' + inttostr(_aktkezdij);
  _pcs := _pcs + ',UTSTORNO=' + inttostr(_kezSbizszam);
  ValutaParancs(_pcs);

  _bizonylat := _stornobizonylat;
  _bizkelte  := _megnyitottnap;
 
  KezdijNyomtatas(_tipus);

  KezBizonylatPanel.visible := False;
  ActiveControl := KezdAtvetGomb;
end;


procedure TKDADVET.REPRINTGOMBClick(Sender: TObject);
begin
  _bizonylat := KezdijTabla.FieldByName('BIZONYLAT').asString;
  _bizkelte  := KezdijTabla.FieldByNAme('DATUM').asString;
  _kezdij    := KezdijTabla.FieldByNAme('KEZELESIDIJ').asInteger;
  _tipus := leftstr(_bizonylat,1);
  _aktpenztarszam := trim(KezdijTabla.FieldByNAme('PENZTAR').asString);
  _storno := KezdijTabla.FieldByNAme('STORNO').asInteger;
  _szallitonev := trim(Kezdijtabla.FieldByName('SZALLITONEV').AsString);
  _plombaszam := trim(KezdijTabla.FieldByNAme('PLOMBASZAM').AsString);
  KezdijNyomtatas(_tipus);
end;


end.
