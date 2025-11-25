unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls,DB, Grids, DBGrids, StrUtils,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery, jpeg, printers,
  dateUtils;

type
  TKdAdvet = class(TForm)

    AdottVettPanel         : TPanel;
    AtadottKezbizPanel     : TPanel;
    AtvettKezBizPanel      : TPanel;
    AtvevoPenztarPanel     : TPanel;
    KezdijAtadPanel        : TPanel;
    KezBizonyFocimPanel    : TPanel;
    KezBizonylatPanel      : TPanel;
    KezdijAtvetPanel       : TPanel;
    KezdijPanel            : TPanel;
    KezfocimPanel          : TPanel;
    KuldoPenztarPanel      : TPanel;
    HovalasztoPanel        : TPanel;
    Panel2                 : TPanel;
    PillkezdIJPanel        : TPanel;
    PillOsszegPanel        : TPanel;
    StornoPanel            : TPanel;

    HoMegsemGomb           : TButton;
    HoOkeGomb              : TButton;

    AtadottKdKonyveloGomb  : TBitBtn;
    AtadottKdMegsemGomb    : TBitBtn;
    AtvettKdKonyvEloGomb   : TBitBtn;
    AtvettKdKonyvMegsemGomb: TBitBtn;
    KezBizStornoGomb       : TBitBtn;
    KezBizvegeGomb         : TBitBtn;
    KezdAtvetGomb          : TBitBtn;
    KezdBizonylatGomb      : TBitBtn;
    KezdKiadGomb           : TBitBtn;
    KezdPillGomb           : TBitBtn;
    KezdVisszaGomb         : TBitBtn;
    MaiKezdijGomb          : TBitBtn;
    OldKezdijGomb          : TBitBtn;
    PillKeszBackGomb       : TBitBtn;
    ReprintGomb            : TBitBtn;

    KezdijTabla            : TIBTable;
    KezdijQuery            : TIBQuery;
    KezdijDbase            : TIBDatabase;
    KezdijTranz            : TIBTransaction;

    ValutaQuery            : TIBQuery;
    ValutaDbase            : TIBDatabase;
    ValutaTranz            : TIBTransaction;

    ValdataQuery           : TIBQuery;
    ValdataDbase           : TIBDatabase;
    ValdataTranz           : TIBTransaction;

    Shape1                 : TShape;
    Shape2                 : TShape;
    Shape6                 : TShape;
    Shape7                 : TShape;
    Shape8                 : TShape;
    Shape9                 : TShape;

    Label1                 : TLabel;
    Label2                 : TLabel;
    Label3                 : TLabel;
    Label4                 : TLabel;
    Label9                 : TLabel;
    Label11                : TLabel;
    Label13                : TLabel;
    Label21                : TLabel;

    AtvettKezdijEdit       : TEdit;
    KiadottKezdijEdit      : TEdit;

    KezBizRacs             : TDBGrid;

    KezdijSource           : TDataSource;

    EvCombo                : TComboBox;
    HoCombo                : TComboBox;

    KezdijTablaBankjegy    : TIntegerField;
    KezdijTablaBizonylat   : TIBStringField;
    KezdijTablaDatum       : TIBStringField;
    KezdijTablaElojel      : TIBStringField;
    KezdijTablaPenztar     : TIBStringField;
    KezdijTablaStorno      : TSmallintField;

    procedure AlapAdatBeolvasas;
    procedure AtadottKdKonyveloGombClick(Sender: TObject);
    procedure AtvettKezdijEditEnter(Sender: TObject);
    procedure AtvettKezdijEditExit(Sender: TObject);
    procedure AtvettKezdijEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AtvettKdKonyvEloGombClick(Sender: TObject);
    procedure AtvettKdKonyvMegsemGombClick(Sender: TObject);
    procedure BizonylatChange;
    procedure EvcomboChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure GetKezBizSzam;
    procedure HoMegsemGombClick(Sender: TObject);
    procedure HoOkeGombClick(Sender: TObject);
    procedure KezbizracsCellClick(Column: TColumn);
    procedure KezbizracsDblClick(Sender: TObject);
    procedure KezbizracsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KezbizracsMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure KezbizvegegombClick(Sender: TObject);
    procedure KezdAtvetGombClick(Sender: TObject);
    procedure KezdBizonylatGombClick(Sender: TObject);
    procedure KezbizStornoGombClick(Sender: TObject);
    procedure KezdijNyomtatas;
    procedure KezdKiadGombClick(Sender: TObject);
    procedure KezdParancs(_ukaz: string);
    procedure KezdPILLGombClick(Sender: TObject);
    procedure KezdVISSZAGombClick(Sender: TObject);
    procedure KiadottKezdijEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NapiKezdijDisplay(Sender: TObject);
    procedure OldKezdijGombClick(Sender: TObject);
    procedure PillKeszBackGombClick(Sender: TObject);
    procedure PlombaAdatBeolvasas;
    procedure Ptarbeolvasas;
    procedure Rekordiras;
    procedure ReprintGombClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);

    function ForintForm(_sm:integer):string;
    function Nulele(_b, _h: integer): string;
    procedure ATADOTTKDMEGSEMGOMBClick(Sender: TObject);


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
  _LPath : string = 'C:\ERTEKTAR\AKTLST.TXT';
  _sorveg: string = chr(13) + chr(10);

  _printer: byte;
  _height,_width,_top,_left,_maiev,_maiho,_kertho,_kertev,_bill: word;

  _kezbBizszam,_kezKBizszam,_aktkezdij,_kezdij,_code,_mozgas: integer;
  _kezSbizszam,_plombaOke,_ptaroke,_storno,_aktkezdijsorszam: integer;

  _pcs,_plombaszam,_megnyitottnap,_szallitonev,_megjegyzes,_farok: string;
  _bizonylat,_penztarnev,_penztarcim,_bizkelte,_elojel: string;
  _aktPenztarszam,_aktPenztarnev,_origbizonylat: string;
  _stornobizonylat,_tipus: string;

  _oBizonylat: boolean;


function kezdijatadorutin: integer; stdcall;
function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\ertektar\bin\bloknyom.dll' name 'blokknyomtatas';
function penztarrutin: integer; stdcall; external 'c:\ertektar\bin\getptar.dll' name 'penztarrutin';
function getplombarutin: integer; stdcall; external 'c:\ertektar\bin\getplomb.dll' name 'getplombarutin';
function regeneralorutin: integer; stdcall; external 'c:\ertektar\bin\regen.dll' name 'regeneralorutin';

implementation

{$R *.dfm}

// =============================================================================
              function kezdijatadorutin: integer; stdcall;
// =============================================================================

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
  _PtarOke := penztarrutin;
  if _ptaroke<>1 then exit;

  PtarBeolvasas;
  GetKezBizSzam;

  _storno := 1;
  inc(_aktkezdijsorszam);
  _Bizonylat := 'B-' + nulele(_aktkezdijsorszam,6);

  AtvettKezbizPanel.Caption := _bizonylat;
  with Kezdijatvetpanel do
    begin
      top     := 110;
      Left    := 30;
      Visible := True;
    end;

    _elojel := '+';
  KuldoPenztarPanel.Caption := _aktpenztarszam;
  AtvettKezdijEdit.clear;
  ActiveControl := AtvettKezdijEdit;
end;


// =============================================================================
            procedure TKDadvet.KezdKiadGombClick(Sender: TObject);
// =============================================================================

begin
  _PtarOke := penztarrutin;
  if _ptaroke<>1 then exit;

  PtarBeolvasas;
  GetKezBizSzam;

  _storno := 1;
  inc(_aktkezdijsorszam);
  _Bizonylat := 'K-' + nulele(_aktkezdijsorszam,6);

  AtadottKezbizPanel.Caption := _bizonylat;
  with Kezdijatadpanel do
    begin
      top     := 110;
      Left    := 30;
      Visible := True;
    end;

  _elojel := '-';
  AtvevoPenztarPanel.Caption := _aktpenztarszam;
  KiadottKezdijEdit.clear;
  ActiveControl := KiadottKezdijEdit;
end;


// =============================================================================
   procedure TKDADVET.kiadottkezdijeditKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  _bill := ord(key);
  if _bill<>13 then exit;

  AtadottKdkonyveloGomb.Enabled := true;
  ActiveControl := AtadottKdKonyveloGOmb;
end;


// =============================================================================
             procedure TKDADVET.ATVETTKEZDIJEDITEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).Color := $B0FFFF;
end;

// =============================================================================
            procedure TKDADVET.ATVETTKEZDIJEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clWindow;
end;

// =============================================================================
   procedure TKDADVET.ATVETTKEZDIJEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _bill: byte;

begin
  _bill := ord(key);
  if _bill<>13 then exit;

  AtvettKdkonyveloGomb.Enabled := true;
  ActiveControl := AtvettKdKonyveloGOmb;
end;

// =============================================================================
         procedure TKDADVET.ATVETTKDKONYVMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  KezdijAtvetpanel.Visible := False;
  ActiveControl := KezdAtvetGomb;
end;


// =============================================================================
           procedure TKDADVET.ATVETTKDKONYVELOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Kezdijatvetpanel.Visible := False;
  (* Kezelesidij táblába beir:  DATUM,BIZONYLAT,ELOJEL,KEZELESIDIJ,
                                PENZTAR,STORNO,MOZGAS
     Kezelesidata táblába beir: UTBEVET (a bizonylat sorszámát)
                        aktulizálni AKTKEZELESIDIJ - at

  *)

  val(AtvettKezdijedit.text,_kezdij,_code);
  if _code<>0 then _kezdij := 0;
  if _kezdij= 0 then exit;

  _plombaOke := getplombarutin;
  if _plombaOke=2 then exit;

  PlombaAdatBeolvasas;
  RekordIras;
end;

// =============================================================================
         procedure TKDADVET.KEZDVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
          procedure TKDADVET.KEZDPILLGOMBClick(Sender: TObject);
// =============================================================================

begin
  GetKezBizSzam;
  Pillosszegpanel.Caption := ForintForm(_aktkezdij)+' Ft';
  with PillKezdijpanel do
    begin
      Top := 136;
      Left := 52;
      Visible := True;
    end;
  PillkezdijPanel.Repaint;
end;


// =============================================================================
         procedure TKDadvet.PillKeszBackGombClick(Sender: TObject);
// =============================================================================

begin
  Pillkezdijpanel.Visible := false;
  ActiveControl := KezdAtvetGomb;
end;

// =============================================================================
       procedure TKDadvet.KezdBizonylatGombClick(Sender: TObject);
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
                procedure TKDadvet.NapiKezdijDisplay(Sender: TObject);
// =============================================================================

begin

  MaiKezdijgomb.Enabled := False;
  KezdijSource.Enabled := False;
  KezbizStornoGomb.Enabled := False;

  with KezdijDbase do
    begin
      Close;
      DatabaseName := 'c:\ertektar\database\valuta.fdb';
      Connected := true;
    end;

  if KezdijTranz.InTransaction then KezdijTranz.commit;
  Kezdijtranz.StartTransaction;

  with KezdijTabla do
    begin
      close;
      TableName := 'KEZDIJ';
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
      _kezdij := FieldByName('BANKJEGY').asInteger;
      _aktpenztarszam := FieldByName('PENZTAR').asString;
      _Bizonylat := FieldByName('BIZONYLAT').asString;
      _storno := FieldByName('STORNO').asInteger;
    end;
  if _storno>1 then stornopanel.visible := true else stornopanel.visible := false;
  KezbizStornoGomb.Enabled := True;
  IF (_storno>1) then KezbizStornoGomb.Enabled := False;

end;

// =============================================================================
         procedure TKDAdvet.KezbizRacsDblClick(Sender: TObject);
// =============================================================================

begin
  BizonylatChange;
end;

// =============================================================================
         procedure TKDAdvet.KezbizracsCellClick(Column: TColumn);
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
                    procedure TKDADVET.AlapAdatBeolvasas;
// =============================================================================

begin
  valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;

      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
      _printer := FieldByName('PRINTER').asInteger;
      Close;

      Sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;

      _penztarnev := trim(FieldByNAme('PENZTARNEV').asString);
      _penztarcim := trim(FieldByNAme('PENZTARCIM').AsString);
      Close;
    end;
  Valutadbase.close;

end;

// =============================================================================
                  procedure TKDADVET.GetKezBizSzam;
// =============================================================================

begin
  Valutadbase.Connected := True;
  with Valutaquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM UTOLSOBLOKKOK');
      Open;
      _aktkezdijsorszam   := Fieldbyname('LASTKEZDIJ').asInteger;
      Close;
      Sql.clear;
      sql.add('SELECT * FROM KEZDIJDATA');
      Open;
      _aktkezdij := FieldbyNAme('ZARO').asInteger;
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
      _aktpenztarnev  := trim(FieldByNAme('TARSPENZTARNEV').AsString);
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
          procedure TKDADVET.KezdijNyomtatas;
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (TIPUS,BIZONYLATSZAM,DATUM,ELOJEL,PENZTARKOD,';
  _pcs := _pcs + 'STORNO,SZALLITONEV,PLOMBASZAM,BANKJEGY,MEGJEGYZES)'+_sorveg;
  _Pcs := _pcs + 'VALUES (' + chr(39)+'K'+chr(39)+',';
  _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + chr(39) + _aktpenztarszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_storno) + ',';
  _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_kezdij) + ',';
  _pcs := _pcs + chr(39) + _megjegyzes + chr(39) + ')';
  ValutaParancs(_pcs);
  blokknyomtatas(1);
  blokknyomtatas(1);

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


// =============================================================================
             procedure TKDadvet.OldKezdijGombClick(Sender: TObject);
// =============================================================================

var _y: byte;

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

// =============================================================================
          procedure TKDadvet.HoMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  HovalasztoPanel.Visible := False;
  MaiKezdijgomb.Enabled := True;
  OldKezdijGomb.Enabled := True;
  KezbizStornoGomb.Enabled := False;
end;

// =============================================================================
            procedure TKDadvet.evcomboChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := HoOkeGomb;
end;

// =============================================================================
              procedure TKDAdvet.HoOkeGombClick(Sender: TObject);
// =============================================================================

var _kFocim: string;

begin
  _kertho := 1 + Hocombo.itemindex;
  _kertev := _maiev-1+evcomBo.itemindex;

  _FAROK := inttostr(_kertev-2000)+nulele(_kertho,2);
  HovalasztoPanel.Visible := false;

  Kezdijtabla.close;
  if kezdijtranz.InTransaction then Kezdijtranz.commit;
  Kezdijdbase.close;

  Kezdijdbase.DatabaseName := 'c:\ertektar\database\valdata.fdb';
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

// =============================================================================
          procedure TKDADVET.KEZBIZSTORNOGOMBClick(Sender: TObject);
// =============================================================================

var _contraElojel: STRING;

begin
  _storno := KezdijTabla.FieldByNAme('STORNO').asInteger;
  if _storno>1 then exit;

  _bizkelte := trim(Kezdijtabla.fieldbyname('DATUM').asString);
  if _bizkelte<>_megnyitottnap then exit;

  _kezdij := KezdijTabla.fieldByName('BANKJEGY').asInteger;
  _aktpenztarszam := trim(Kezdijtabla.FieldByNAme('PENZTAR').AsString);
  _elojel := KezdijTabla.FieldByNAme('ELOJEL').asString;
  _origbizonylat := KezdijTabla.FieldByNAme('BIZONYLAT').asString;

  KezdijTabla.edit;
  Kezdijtabla.FieldByName('STORNO').asInteger := 2;
  Kezdijtabla.Post;
  Kezdijtranz.commit;
  Kezdijdbase.close;
  Kezdijtabla.close;

  GetKezBizSzam;
  inc(_AKTKEZDIJSORSZAM);

  _stornobizonylat := 'S-' + nulele(_aktkezdijsorszam,6);

  _contraElojel := '+';
  if _elojel='+' then _contraElojel := '-'
  else _contraelojel := '+';

  /// -----------------------------------
  _storno    := 3;

  _pcs := 'INSERT INTO KEZDIJ (DATUM,BIZONYLAT,BANKJEGY,';
  _pcs := _pcs + 'STORNO,PENZTAR,ELOJEL)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _stornobizonylat + chr(39) + ',';
  _pcs := _pcs + inttostr(_kezdij) +',';
  _pcs := _pcs + inttostr(_storno) + ',';
  _pcs := _pcs + chr(39) + _aktpenztarszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _contraElojel + chr(39) + ')';

  KezdParancs(_pcs);

  _pcs := 'UPDATE UTOLSOBLOKKOK SET LASTKEZDIJ='+inttostr(_aktkezdijsorszam);
  ValutaParancs(_pcs);

  _bizonylat := _stornobizonylat;
  _bizkelte  := _megnyitottnap;

  KezdijNyomtatas;

  KezBizonylatPanel.visible := False;
  ActiveControl := KezdAtvetGomb;
end;

// =============================================================================
           procedure TKDADVET.REPRINTGOMBClick(Sender: TObject);
// =============================================================================

begin
  with KezdijTabla do
    begin
      _bizonylat := FieldByName('BIZONYLAT').asString;
      _bizkelte  := FieldByNAme('DATUM').asString;
      _kezdij    := FieldByNAme('BANKJEGY').asInteger;
      _aktpenztarszam := trim(FieldByNAme('PENZTAR').asString);
      _storno := FieldByNAme('STORNO').asInteger;
    end;

  _pcs := 'SELECT * FROM WPENZSZALLITAS' + _sorveg;
  _pcs := _pcs + 'WHERE (WTIPUS='+chr(39)+'KD'+chr(39)+') ';
  _pcs := _pcs + 'AND (BIZONYLATSZAM='+chr(39)+_bizonylat+chr(39)+')';

  valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      _szallitonev:= trim(FieldByName('SZALLITONEV').AsString);
      _plombaszam := trim(FieldByNAme('PLOMBASZAM').AsString);
      close;
    end;
  Valutadbase.close;
  KezdijNyomtatas;
end;

// =============================================================================
         procedure TKDADVET.ATADOTTKDKONYVELOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Kezdijatadpanel.Visible := False;

  val(KiadottKezdijedit.text,_kezdij,_code);
  if _code<>0 then _kezdij := 0;
  if _kezdij= 0 then exit;

  _plombaOke := getplombarutin;
  if _plombaOke=2 then exit;

  PlombaAdatBeolvasas;
  RekordIras;

end;

// =============================================================================
                       procedure TKdAdVet.Rekordiras;
// =============================================================================

begin
  _pcs := 'INSERT INTO KEZDIJ (DATUM,BIZONYLAT,ELOJEL,BANKJEGY,PENZTAR,STORNO)'+_sorveg;;

  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
  _pcs := _pcs + chr(39) + _elojel + chr(39) + ',';
  _pcs := _pcs + inttostr(_kezdij) + ',';
  _pcs := _pcs + chr(39) + trim(_aktpenztarszam) + chr(39) + ',1)';
  ValutaParancs(_pcs);

  _pcs := 'UPDATE UTOLSOBLOKKOK SET LASTKEZDIJ='+inttostr(_aktkezdijsorszam);
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO WPENZSZALLITAS (DATUM,BIZONYLATSZAM,PLOMBASZAM,';
  _pcs := _pcs + 'SZALLITONEV,WTIPUS)' + _sorveg;

  _pcs := _pcs + 'VALUES (';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
  _pcs := _pcs + chr(39) + trim(_plombaszam) + chr(39) + ',';
  _pcs := _pcs + chr(39) + trim(_szallitonev) + chr(39) + ',';
  _pcs := _pcs + chr(39) + 'KD' + chr(39) + ')';
  ValutaParancs(_pcs);

  kezdijNyomtatas;
  regeneralorutin;
end;
procedure TKdAdvet.ATADOTTKDMEGSEMGOMBClick(Sender: TObject);
begin
  KezdijAtadpanel.Visible := False;
  ActiveControl := KezdKiadGomb;
end;

end.
