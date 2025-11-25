unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, StrUtils, IBDatabase, DB,DateUtils,
  IBCustomDataSet, IBQuery, Grids, DBGrids, IBTable, DBCtrls,mapi, jpeg,
  Printers;

type
  TFOGLALO = class(TForm)

  FoglaloTabla                : TIBTable;
  FoglaloQuery                : TIBQuery;
  FoglaloDbase                : TIBDatabase;
  FoglaloTranz                : TIBTransaction;

  FuggoQuery                  : TIBQuery;
  FuggoDbase                  : TIBDatabase;
  FuggoTranz                  : TIBTransaction;

  RendQuery                   : TIBQuery;
  RendDbase                   : TIBDatabase;
  RendTranz                   : TIBTransaction;

  ValutaTabla                 : TIBTable;
  ValutaQuery                 : TIBQuery;
  ValutaDbase                 : TIBDatabase;
  ValutaTranz                 : TIBTransaction;

  BizSelectSource             : TDataSource;
  FoglaloSource               : TDataSource;
  FuggoSource                 : TDataSource;
  RendSource                  : TDataSource;
  UgyfelSource                : TDataSource;

  BizRacs                     : TDBGrid;
  FuggoRacs                   : TDBGrid;
  RendRacs                    : TDBGrid;
  UgyfelRacs                  : TDBGrid;

  FoglaloQueryDatum           : TIBStringField;
  FoglaloQueryUgyfelszam      : TIntegerField;
  FoglaloQueryUgyfelnev       : TIBStringField;
  FoglaloQueryUgyfeltipus     : TIBStringField;
  FoglaloQueryBizonylatszam   : TIBStringField;
  FoglaloQueryHatarido        : TIBStringField;
  FoglaloQueryRendeltOsszeg   : TFloatField;
  FoglaloQueryRendeltErtek    : TFloatField;
  FoglaloQueryRendeltValutanem: TIBStringField;
  FoglaloQueryFoglalo         : TFloatField;
  FoglaloQueryFoglaloValutanem: TIBStringField;
  FoglaloQueryMozgas          : TSmallintField;
  FoglaloQueryHivatkozas      : TIBStringField;
  FoglaloQUERYMegjegyzes      : TIBStringField;
  FoglaloQueryStatus          : TSmallintField;
  FoglaloQueryStorno          : TSmallintField;
  FoglaloQueryOsszeg          : TFloatField;
  FoglaloQueryOsszegValutanem : TIBStringField;

  FuggoQueryFoglalo           : TFloatField;
  FuggoQueryDatum             : TIBStringField;
  FuggoQueryUgyfelszam        : TIntegerField;
  FuggoQueryUgyfelnev         : TIBStringField;
  FuggoQueryUgyfeltipus       : TIBStringField;
  FuggoQueryBizonylatszam     : TIBStringField;
  FuggoQueryHatarido          : TIBStringField;
  FuggoQueryRendeltOsszeg     : TFloatField;
  FuggoQueryRendeltErtek      : TFloatField;
  FuggoQueryRendeltValutanem  : TIBStringField;
  FuggoQueryFoglaloValutanem  : TIBStringField;
  FuggoQueryMozgas            : TSmallintField;
  FuggoQueryHivatkozas        : TIBStringField;
  FuggoQueryMegjegyzes        : TIBStringField;
  FuggoQueryStatus            : TSmallintField;
  FuggoQueryStorno            : TSmallintField;
  FuggoQueryOsszeg            : TFloatField;
  FuggoQueryOsszegValutanem   : TIBStringField;
  PrgFocim                    : TLabel;
  Label1                      : TLabel;
  Label9                      : TLabel;
  Label2                      : TLabel;
  Label3                      : TLabel;
  Label5                      : TLabel;
  Label6                      : TLabel;
  Label7                      : TLabel;
  Label8                      : TLabel;
  Label4                      : TLabel;
  Label10                     : TLabel;
  Label11                     : TLabel;
  Label12                     : TLabel;
  Label13                     : TLabel;
  FocimArnyek                 : TLabel;
  Label32                     : TLabel;
  Label33                     : TLabel;
  Label34                     : TLabel;
  Label35                     : TLabel;
  Label36                     : TLabel;
  Label37                     : TLabel;
  Label38                     : TLabel;
  Label39                     : TLabel;
  Label30                     : TLabel;
  Atlabel                     : TLabel;
  Label48                     : TLabel;
  Label49                     : TLabel;
  Label50                     : TLabel;
  Label53                     : TLabel;
  Label54                     : TLabel;
  Label51                     : TLabel;
  Label52                     : TLabel;
  Label55                     : TLabel;
  Label56                     : TLabel;
  Label57                     : TLabel;
  Label40                     : TLabel;

  AtvetelGomb                 : TBitBtn;
  FoglKeszlVisszaGomb         : TBitBtn;
  KifizetesGomb               : TBitBtn;
  ListaGomb                   : TBitBtn;
  KeszletGomb                 : TBitBtn;
  Newtimegomb                 : TBitBtn;
  QuitGomb                    : TBitBtn;
  RegUgyfelGomb               : TBitBtn;
  UjUgyfelGomb                : TBitBtn;
  IgenGomb                    : TBitBtn;
  NemGomb                     : TBitBtn;
  MegsemGomb                  : TBitBtn;
  MegisMostGomb               : TBitBtn;
  NameFinishGomb              : TBitBtn;
  UgyletOkeGomb               : TBitBtn;
  UgyletFaultByClient         : TBitBtn;
  UgyletFaultByEBC            : TBitBtn;
  ValutaRendbenGomb           : TBitBtn;
  ValutaMegsemGomb            : TBitBtn;
  VisszaCancelGomb            : TBitBtn;
  UgyfelValasztoGomb          : TBitBtn;
  ValaszMegsemGomb            : TBitBtn;

  UjnevOke                    : TButton;
  UjnevQuit                   : TButton;

  AdatBekeroPanel             : TPanel;
  BizSelectPanel              : TPanel;
  ConfirmPanel                : TPanel;
  FoglKeszlPanel              : TPanel;
  FomenuPanel                 : TPanel;
  FuggoPanel                  : TPanel;
  Fuggony                     : TPanel;
  GetUgyfelPanel              : TPanel;
  KifizetesPanel              : TPanel;
  ListVisszaGomb              : TPanel;
  MasHatidoPanel              : TPanel;
  MenuFuggony                 : TPanel;
  NincsFuggoPanel             : TPanel;
  NincsRendezettFoglaloPanel  : TPanel;
  OkozatTakaro                : TPanel;
  P0                          : TPanel;
  P1                          : TPanel;
  P3                          : TPanel;
  P2                          : TPanel;
  P4                          : TPanel;
  Panel2                      : TPanel;
  RacsTakaro                  : TPanel;
  RendezettPanel              : TPanel;
  UgyfelValasztoPanel         : TPanel;
  ValutaPanel                 : TPanel;
  VFnevPanel                  : TPanel;
  VFHatidoPanel               : TPanel;
  VFRendeltValutaPanel        : TPanel;
  VFBizszamPanel              : TPanel;
  VFFoglaloPanel              : TPanel;
  AnyjaEdit                   : TEdit;
  AnyjaDisp                   : TEdit;
  ArfDisp                     : TEdit;
  AzonositoEdit               : TEdit;
  AllamPolgEdit               : TEdit;
  FTDisp                      : TEdit;
  FogDisp                     : TEdit;
  IndokEdit                   : TEdit;
  KeresoEdit                  : TEdit;
  NevDisp                     : TEdit;
  NevEdit                     : TEdit;
  OkmTipEdit                  : TEdit;
  SzulDisp                    : TEdit;
  SzulhelyEdit                : TEdit;
  SzulidoEdit                 : TEdit;
  ValDisp                     : TEdit;


  HidoDisp                    : TEdit;

  Shape1                      : TShape;
  Shape9                      : TShape;
  Shape10                     : TShape;
  Shape11                     : TShape;
  Shape13                     : TShape;
  Shape15                     : TShape;
  Shape18                     : TShape;
  Shape19                     : TShape;

  Image1                      : TImage;
  ValutaLista                 : TListBox;
    KESZLETPANEL: TPanel;
    Label14: TLabel;
    KP0: TPanel;
    KP1: TPanel;
    KP2: TPanel;
    KP3: TPanel;
    KP4: TPanel;
    KV0: TPanel;
    KV1: TPanel;
    KV2: TPanel;
    KV3: TPanel;
    KV4: TPanel;
    KESZLETVISSZAGOMB: TBitBtn;
    Shape2: TShape;

  // ===========================================================================

  procedure FormActivate(Sender: TObject);
  procedure PenztarBeolvasas;
  procedure ValutanemBetoltes;
  procedure Fomenure;
  // -------------------------- foglaló rendelés -------------------------------
  procedure EmailekKuldese;
  procedure BebIzIro;
  // -------------------- ugyfélrutinok ----------------------------------------
  procedure IgenGombClick(Sender: TObject);
  procedure NevEditEnter(Sender: TObject);
  procedure NevEditExit(Sender: TObject);
  procedure NevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure RegUgyfelClick(Sender: TObject);
  procedure UgyfelRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure UgyfelValasztoGombClick(Sender: TObject);
  procedure UgyfeletValasztott;
  procedure UjugyfelGombClick(Sender: TObject);
  procedure UjNevOkeClick(Sender: TObject);
  procedure UjnevquitClick(Sender: TObject);
  procedure UgyfelRacsDblClick(Sender: TObject);
  procedure ValaszMegsemGombClick(Sender: TObject);
  procedure VisszaFizetoProcedura;
  // ---------------------------------------------------------------------------
  procedure Alairasiro;
  procedure ArfolyamEditExit(Sender: TObject);
  procedure ArfolyamEditEnter(Sender: TObject);
  procedure AtvetelGombClick(Sender: TObject);
  procedure AtvetelGombEnter(Sender: TObject);
  procedure AtvetelGombExit(Sender: TObject);
  procedure AtvetelGombMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
  procedure BizonylateditEnter(Sender: TObject);
  procedure BizonylateditExit(Sender: TObject);
  procedure BizonylatFejiro(_fejlec: string);
  procedure BizonylatotValasztott;
  procedure BizracsDblClick(Sender: TObject);
  procedure BizracsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure FoglaloKifizetes;
  procedure FoglaloRekordIras;
  procedure GetUgyfelData;
  procedure IndOkEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  procedure KeszletVisszaGombClick(Sender: TObject);
  procedure KeszletGombClick(Sender: TObject);
  procedure Kibiziro;
  procedure KifizetesGombClick(Sender: TObject);
  procedure KozepreIr(_szoveg: string);
  procedure ListaGombClick(Sender: TObject);
  procedure ListaVisszaGombClick(Sender: TObject);
  procedure ListVisszaGombClick(Sender: TObject);
  procedure Masidopont;
  procedure MegisMostGombClick(Sender: TObject);
  procedure MegsemGombClick(Sender: TObject);
  procedure NameFinishGombClick(Sender: TObject);
  procedure NemGombClick(Sender: TObject);
  procedure NewtimegombClick(Sender: TObject);
  procedure NormalVisszaFizetes;
  procedure OsszegEditEnter(Sender: TObject);
  procedure OsszegEditExit(Sender: TObject);
  procedure QuitGombClick(Sender: TObject);
  procedure RegiBizTorlese;
  procedure StartNyomtatas;
  procedure UgyletOkeGombClick(Sender: TObject);
  procedure ValutaParancs(_ukaz: string);
  procedure VisszaCancelGombClick(Sender: TObject);
  procedure VisszaRekordIras;
  procedure VonalHuzo;
  procedure FoglaloBevetelezes;
  procedure FoglaloKivezetes;
  // -------------------- FÜGGVÉNYEK -------------------------------------
  function ArfForm(_aw: word): string;
  function BebizonylatLepteto: string;
  function BizonylatSeek: boolean;
  function Elokieg(_targy: integer;_len: byte): string;
  function Ftform(_ft: integer): string;
  function Getarfolyam(_vn: string): integer;
  function GetHibaBizonylat: string;
  function Getidos: string;
  function Hundatetostr(_caldat: TDatetime): string;
  function Hunstrtodate(_calstr: string): TdateTime;
  function Kerekito(_int: integer): integer;
  function Nulele(_b: byte):string;
  function Null5(_b: integer): string;
  function Space(_hh: integer):string;
  function Ugyfeldataread(_usz: integer): boolean;
  function KiBizonylatLepteto: string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Foglalo: TFoglalo;

  _uedit      : array[1..7] of TEdit;
  _dNem       : array[0..26] of string;

  _munkadir   : string = 'C:\VALUTA';
  _sorveg     : string = chr(13)+chr(10);

  _inic       : string = #27#64;
  _lf5        : string = #27#97#5;
  _widon      : string = #14;
  _widoff     : string = #20;

  _ugyfeltipus: string = 'N';
  _hido       : TDatetime;
  _hatidate   : TdateTime;
  _aktpanel   : TPanel;
  _hanynapra  : extended;

  _zzaro,_znyito,_zbe,_zki: array[0..4] of integer;
  _zvalnem                : array[0..4] of string;

  _textiras,_LFile,_piras: TextFile;
  _goodtime,_stornoblokk,_stornozottblokk,_van: boolean;

  _kertdnem,_foglalodnem,_hatarido,_bjs,_akthidos,_fs          : string;
  _captions,_bebizonylat,_kibizonylat,_foglaloValutanem        : string;
  _hivatkozas,_kMezo,_numbers,_osszegValutanem                 : string;
  _mess,_bizonylatszam,_megjegyzes,_pcs,_tranztip              : string;
  _rendeltValutanem,_rendeltValutaNev,_vMezo,_zMezo,_datum     : string;
  _arany,_maildir,_body,_mailstring,_remoteFile,_localpath     : string;
  _v0,_v1,_v2,_v3,_v4,_fbizonylat,_aktidkod,_aktprosnev,_tipus : string;
  _vvari,_kvari,_yV,_hibamess                                  : string;
  _rendeles,_rendelesPath,_mamas,_ugyfelnev,_aktmamas,_aktidos : string;
  _aktpenztarszam,_aktpenztarnev,_szallitonev,_plombaszam      : string;
  _elojel,_anyjaneve,_szulhely,_szulido,_okmanytipus,_azonosito: string;
  _allampolgar,_valutanem,_aktdnem,_exclusive,_cegnev,_fdnem   : string;
  _kftnev,_homepenztarkod,_homepenztarnev,_homepenztarcim      : string;
  _homepenztartelefon,_etaremail,_foglalos,_keres,_ujkeres     : string;

  _arfolyam,_bankjegy,_ftertek,_foglalo,_aktertek,_ujKeszlet   : integer;
  _bjegy,_arf,_dnemindex,_sendOke,_alkuarf,_yK                 : integer;
  _kibiz,_mozgas,_nHossz,_status,_fvaldarab,_aktft,_spk        : integer;
  _stbiz,_spvOke,_stornojel,_visszaTipus,_xx,_findex           : integer;
  _ertek,_aktbankjegy,_aktarfolyam,_aktzaro,_aktEarf           : integer;
  _k0,_k1,_k2,_k3,_k4,_foglaloertek,_farf,_fertek              : integer;
  _osszeg,_code,_ugyfelszam,_recno,_aktkeszlet                 : integer;
  _rendeltosszeg,_rendeltErtek,_vFizetett,_rendback            : integer;
  _atadFlag,_bebiz,_fizetendo                                  : integer;

  _be,_ki,_h_ev,_h_ho,_h_nap,_width,_height,_top,_left         : word;

  _valdb,_bill,_dnemdarab,_para,_ptarnum,_valdarab             : byte;
  _storno,_printer,_homePenztarSzam,_editss,_y,_db             : byte;

function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll';
function copyfiletoftprutin: integer; stdcall; external 'c:\valuta\bin\copy2ftp.dll';
function foglalorendeles: integer; stdcall; external  'c:\valuta\bin\foglrend.dll';
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll';

function foglalorutinok: integer; stdcall;


implementation


{$R *.dfm}

{
   MOZGAS = 1-> Foglaló bevételezése, 2-> Normál visszafizetés
            3-> Ügyfél hibája miatt marad a foglaló a pénztárban
            4-> Az Exclusive Change hibája miatt kétszeres foglalót kell kifizetni

   STATUS = 1-> Ügylet függõben,
            2-> Ügylet idõben rendezve
            3-> Ügylet más idõpontban rendezve



}

// =============================================================================
                function foglalorutinok: integer; stdcall;
// =============================================================================

begin
  Foglalo := TFoglalo.Create(NIL);
  Result  := Foglalo.Showmodal;
  Foglalo.Free;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////     ITT INDUL A PROGRAM  //////////////////////////////////
// =============================================================================
              procedure TFOGLALO.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width    := Screen.Monitors[0].Width;
  _height   := Screen.Monitors[0].Height;

  _left     := trunc((_width-1024)/2);
  _top      := trunc((_height-768)/2);

  Top       := _top;
  Left      := _left;

  width     := 1024;
  Height    := 768;

  _mamas    := Hundatetostr(date);

  _uedit[1] := Nevedit;
  _uedit[2] := Anyjaedit;
  _uedit[3] := Szulhelyedit;
  _uedit[4] := Szulidoedit;
  _uedit[5] := OkmTipedit;
  _uedit[6] := Azonositoedit;
  _uedit[7] := Allampolgedit;

  RegiBiztorlese;
  PenztarBeolvasas;
  ValutanemBetoltes;

  logirorutin(pchar('A foglaló menüpontot választottas'));
  Fomenure;
end;

////////////////////////////////////////////////////////////////////////////////
/////////////////   A RÉGI BENNRAGADT TÉTELEK KITÖRLÉSE  ///////////////////////
// =============================================================================
                 procedure TFoglalo.RegiBizTorlese;
// =============================================================================

var _lastnaps: string;
    _xev,_xho,_xnap: word;

begin
  _xev := yearof(date);
  _xho := monthof(date);
  _xnap:= dayof(date);
  _xho := _xho-2;
  if _xho<1 then
    begin
      _xho := 11;
      dec(_xev);
    end;
    
  _lastnaps := inttostr(_xev)+'.'+nulele(_xho)+'.'+nulele(_xnap);

  _pcs := 'DELETE FROM FOGLALOK WHERE (DATUM<' + chr(39)+_lastNaps + chr(39)+')';
  _pcs := _pcs + ' AND (MOZGAS>1) AND (STATUS>1)';
  ValutaParancs(_pcs);
end;

////////////////////////////////////////////////////////////////////////////////
//////////////////////  PÉNZTÁR ALAPADATOK BEOLVASÁSA   ////////////////////////
// =============================================================================
                   PROCEDURE TFoglalo.PenztarBeolvasas;
// =============================================================================

begin

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM PENZTAR');
      Open;
      _HomePenztarNev     := trim(FieldByname('PENZTARNEV').asString);
      _HomePenztarKod     := trim(FieldByname('PENZTARKOD').asString);
      _HomePenztarcim     := trim(FieldByName('PENZTARCIM').asString);
      _HomePenztarTelefon := trim(FieldByName('TELEFONSZAM').AsString);
      Close;

      val(_HomePenztarKod,_ptarnum,_code);
      if _code<>0 then _ptarnum := 0;

      Sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _kftnev     := Trim(FieldByName('KFTNEV').AsString);
      _printer    := FieldByNAme('PRINTER').asInteger;
       _etaremail := trim(FieldByName('ERTEKTAREMAILCIM').AsString);
       _aktidkod  := trim(FieldByNAme('IDKOD').asString);
       _aktprosnev := trim(FieldByName('PENZTAROSNEV').asString);
      Close;
    end;
  Valutadbase.close;

  val(_homePenztarKod,_homePenztarSzam,_code);
  if _homePenztarszam<151 then
    begin
      _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';
    end else
    begin
      _cegnev := 'EXPRESSZ ÉKSZERHAZ ES MINIBANK KFT';
    end;
end;


////////////////////////////////////////////////////////////////////////////////
/////////////////  BETÖLTI A VALUTANEMEKET SZ ARFOLYAM TÁBLÁBÓL  ///////////////
// =============================================================================
                       procedure TFoglalo.ValutanemBetoltes;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE (VALUTANEM<>'+chr(39)+'EUA'+chr(39);
  _pcs := _pcs + ') AND (VALUTANEM<>'+chr(39)+'RCH'+CHR(39)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _y := 0;
  while not ValutaQuery.eof do
    begin
      _aktdnem := ValutaQuery.FieldByName('VALUTANEM').asString;
      _dnem[_y] := _aktdnem;
      ValutaQuery.next;
      inc(_y);
    end;

  ValutaQuery.close;
  Valutadbase.close;

  _dnemdarab := _y;
end;


////////////////////////////////////////////////////////////////////////////////
////////////////        A FÖMENÜT HOZZA A KLPERNYÕRE    ////////////////////////
// =============================================================================
                          procedure TFoglalo.Fomenure;
// =============================================================================

begin
  with FomenuPanel do
    begin
      Left    := 280;
      top     := 440;
      visible := true;
      repaint;
    end;
  ActiveControl := Atvetelgomb;
end;


////////////////////////////////////////////////////////////////////////////////
//////////////////      FOGLALÓ BEVÉTELEZÉSE   /////////////////////////////////
// =============================================================================
             procedure TFOGLALO.AtvetelGombClick(Sender: TObject);
// =============================================================================

begin
  FomenuPanel.Visible := False;
  _rendBack := foglalorendeles;
  if _rendback=-1 then
    begin
      Fomenure;
      exit;
    end;

  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;

      _tipus       := FieldbyName('TIPUS').asstring;
      _kertdnem    := FieldByName('VALUTANEM').asString;
      _foglalodnem := trim(FieldByName('MEGJEGYZES').AsString);
      _bankjegy    := FieldByNAme('BANKJEGY').asInteger;
      _arfolyam    := FieldByName('ARFOLYAM').asInteger;
      _ftErtek     := FieldByNAme('FORINTERTEK').asInteger;
      _foglalo     := FieldByNAme('FIZETENDO').asInteger;
      _hatarido    := FieldByName('DATUM').asString;

      Close;
    end;
  Valutadbase.close;
  if _tipus='V' then _tipus := 'VETEL' else _tipus := 'ELADAS';

  logirorutin(pchar('Ügyfél-választó panelröl választ'));

  with GetugyfelPanel do
    begin
      Top     := 200;
      Left    := 190;
      Visible := True;
      repaint;
    end;
  Activecontrol := RegUgyfelGomb;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////   ÚJ ÜGYFÉL FELVÉTELE   ///////////////////////////////////
// =============================================================================
             procedure TFoglalo.ujugyfelgombClick(Sender: TObject);
// =============================================================================

var i: integer;

begin
  for i := 1 to 7 do _uedit[I].text := '';

  with adatbekeroPanel do
    begin
      Top := 60;
      Left := 72;
      Visible := True;
    end;
  Activecontrol := Nevedit;
end;




////////////////////////////////////////////////////////////////////////////////
////////////////    AZ ÚJ ÜGYFÉL ADATAINAK BEKÉRÉSE    /////////////////////////
// =============================================================================
      procedure TFoglalo.NeveditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

var _eText: string;

begin
  _editss := TEdit(Sender).Tag;
  if ord(key)<>13 then exit;
  _eText := trim(_uedit[_editss].Text);
  if _etext='' then exit;

  if _editss=7 then activecontrol := Ujnevoke
  else activecontrol := _uedit[_editss+1];

end;

////////////////////////////////////////////////////////////////////////////////
/////////////   AZ ÚJ ÜGYFÉL ADATAINAK RÖGZITÉSE ÉS VÁLASZTÁSA    //////////////
// =============================================================================
            procedure TFoglalo.UjNevOkeClick(Sender: TObject);
// =============================================================================

begin
  _ugyfelnev   := trim(nevedit.Text);
  _anyjaneve   := trim(anyjaEdit.Text);
  _szulhely    := trim(szulhelyedit.Text);
  _szulido     := szulidoedit.Text;
  _okmanytipus := trim(okmtipedit.text);
  _azonosito   := trim(azonositoedit.text);
  _allampolgar := trim(allampolgedit.Text);

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM UTOLSOBLOKKOK');
      Open;
      _ugyfelszam := FieldByName('UTOLSOUGYFELSZAM').asInteger;
      close;
    end;
  Valutadbase.close;

  inc(_ugyfelszam);

  _pcs := 'INSERT INTO UGYFEL (UGYFELSZAM,NEV,ANYJANEVE,SZULETESIHELY,SZULETESIIDO,';
  _pcs := _pcs + 'ALLAMPOLGAR,OKMANYTIPUS,AZONOSITO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_ugyfelszam)+',';
  _pcs := _pcs + chr(39)+_ugyfelnev+chr(39)+',';
  _pcs := _pcs + chr(39)+_anyjaneve+chr(39)+',';
  _pcs := _pcs + chr(39)+_szulhely+chr(39)+',';
  _pcs := _pcs + chr(39)+_szulido+chr(39)+',';
  _pcs := _pcs + chr(39)+_allampolgar+chr(39)+',';
  _pcs := _pcs + chr(39)+_okmanytipus+chr(39)+',';
  _pcs := _pcs + chr(39)+_azonosito+chr(39)+')';

  ValutaParancs(_pcs);

  _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOUGYFELSZAM='+inttostr(_ugyfelszam);
  ValutaParancs(_pcs);

  Ugyfeletvalasztott;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////      REGISZTRÁLT ÜGYFELET AKAR VÁLASZTANI   ///////////////////
// =============================================================================
              procedure TFoglalo.RegUgyfelClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('Régi ügyfélre klikkelt'));

  _pcs := 'SELECT * FROM UGYFEL' + _sorveg;
  _pcs := _pcs + 'ORDER BY NEV';

  Valutadbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  Ugyfelsource.Enabled := true;

  with UgyfelValasztoPanel do
    begin
      top     := 55;
      Left    := 80;
      Visible := true;
    end;
  _keres := '';
  UgyfelRacs.SetFocus;
end;


////////////////////////////////////////////////////////////////////////////////
//////////////////    KERESI A RÉGI ÜGYFELET A LISTÁBAN   //////////////////////
// =============================================================================
    procedure TFoglalo.UgyfelRacsKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _kw:byte;

begin
  _bill := ord(key);
  if (_bill>64) and (_bill<91) then
    begin
      _ujkeres := _keres + chr(_bill);
      _van := ValutaQuery.Locate('NEV',_UJKERES,[loPartialkey]);
      if _van then
        begin
          _keres := _ujkeres;
          Keresoedit.text := _keres;
        end;
       exit;
    end;

   if (_bill=8) then
     begin
       _kw :=length(_keres);
       if _kw=0 then exit;

       dec(_kw);
       if _kw=0 then _keres := ''
       else _keres := leftstr(_keres,_kw);
       Keresoedit.Text := _keres;
     end;

  if _bill = 13  then
    begin
      _ugyfelszam := ValutaQuery.FieldByName('UGYFELSZAM').asInteger;
      ValutaQuery.close;
      Valutadbase.close;
      UgyfeletValasztott;
    end;
end;

////////////////////////////////////////////////////////////////////////////////
/////////////////////    ÜGYFÉLVÁLASZTÓ GOMBOT NYOMTA    ///////////////////////
// =============================================================================
         procedure TFoglalo.UgyfelValasztoGombClick(Sender: TObject);
// =============================================================================

begin
  _ugyfelszam := ValutaQuery.FieldByName('UGYFELSZAM').asInteger;

  ValutaQuery.close;
  Valutadbase.close;

  UgyfeletValasztott;
end;

////////////////////////////////////////////////////////////////////////////////
///////////   ÜGXFELET VÁLASZTOTT (régit vagy újat) ÜGYFFÉLSZÁMMAL   ///////////
// =============================================================================
                 procedure TFoglalo.UgyfeletValasztott;
// =============================================================================

begin
  UgyfelValasztoPanel.Visible := false;
  GetugyfelPanel.Visible := False;

  // Beolvassa az ügyfélszámhoz tartozó adatokat:
  Ugyfeldataread(_ugyfelszam);

  Nevdisp.Text   := _ugyfelnev;
  AnyjaDIsp.Text := _anyjaneve;
  Szuldisp.Text  := _szulido+' ' + _szulhely;
  Valdisp.Text   := ftform(_bankjegy) + ' ' + _kertdnem;
  Arfdisp.Text   := ArfForm(_arfolyam) + ' ' + _kertdnem + '/HUF';
  FtDisp.Text    := FtForm(_FtErtek)+' Ft';
  HidoDisp.Text  := _hatarido;
  Fogdisp.text   := ftform(_foglalo)+' '+_foglalodnem;

  with ConfirmPanel do
    begin
      top     := 220;
      left    := 150;
      Visible := true;
      repaint;
    end;
  Activecontrol := Igengomb;
end;

////////////////////////////////////////////////////////////////////////////////
//////////////   AZ ÜGYFÉLVÁLASZTÁS UTAN  NEM GOMBOT NYOMTA   //////////////////
// =============================================================================
              procedure TFOGLALO.NEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  ConfirmPanel.visible := False;
  Fomenure;
end;


////////////////////////////////////////////////////////////////////////////////
/////////////   A KIVÁLASZTOTT ÜGYFÉLRE IGEN GOMBOT NYOMOTT     ////////////////
// =============================================================================
              procedure TFoglalo.IgenGombClick(Sender: TObject);
// =============================================================================

begin
   // Itt minden rendben, lehet könyvelni !

   Confirmpanel.Visible := False;
   logirorutin(pchar('Minden rendben - lehet könyvelni'));

  _bizonylatszam := BebizonylatLepteto;  // 'B' + null5(_bebiz);
  _stornojel     := 1;
  _megjegyzes    := '';
  _status        := 1;
  _mozgas        := 1;

  logirorutin(pchar('Foglaló felvétel rögzitése'));
  FoglaloBevetelezes;

  // A foglalót bevételezi a FOGLALOKESZ táblába
  FoglaloRekordIras;

  // A foglalás befizetés bizonylatának nyomtatása:

  BebizIro;
  logirorutin(pchar('E-mail küldése Helgának és Értéktárnak és Durucznak'));

  EmailekKuldese;     // TESZT !!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ConfirmPanel.Visible := False;

  logirorutin(pchar('Foglaló felvétel befejezve'));
  logirorutin(pchar('--------------------------------'));
  Fomenure;
end;

////////////////////////////////////////////////////////////////////////////////
//////////   A BEVETELEZETT FOGLALÓ BEIRÁSA A FOGLALOK ADATBÁZISBA  ////////////
// =============================================================================
                        procedure TFoglalo.FoglaloRekordIras;
// =============================================================================

//  A foglalás regisztrálása:

begin
  if _foglalo=0 then exit;

  // Bizonylat rekordját felirjuk:

  _pcs := 'INSERT INTO FOGLALOK (DATUM,BIZONYLATSZAM,UGYFELSZAM,UGYFELTIPUS,';
  _pcs := _pcs + 'UGYFELNEV,RENDELTVALUTANEM,RENDELTOSSZEG,RENDELTERTEK,';
  _pcs := _pcs + 'HATARIDO,FOGLALO,FOGLALOVALUTANEM,MOZGAS,STATUS,STORNO,';
  _pcs := _pcs + 'MEGJEGYZES,OSSZEG,OSSZEGVALUTANEM)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + inttostr(_ugyfelszam) + ',';
  _pcs := _pcs + chr(39) + 'N' + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ugyfelnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _kertdnem + chr(39) + ',';

  _pcs := _pcs + inttostr(trunc(_bankjegy)) + ',';
  _pcs := _pcs + inttostr(trunc(_ftErtek)) + ',';
  _pcs := _pcs + chr(39) + _hatarido + chr(39) + ',';

  _pcs := _pcs + inttostr(_foglalo) + ',';
  _pcs := _pcs + chr(39) + _foglaloDnem + chr(39) + ',';
  _pcs := _pcs + inttostr(_mozgas) + ',';
  _pcs := _pcs + inttostr(_status) + ',';
  _pcs := _pcs + inttostr(_stornojel)+',';
  _pcs := _pcs + chr(39) + _megjegyzes + chr(39) + ',';
  _pcs := _pcs + inttostr(_foglalo) + ',';
  _pcs := _pcs + chr(39) + _foglaloDnem + chr(39) + ')';
  ValutaParancs(_pcs);
end;

////////////////////////////////////////////////////////////////////////////////
////////////    E-MAIL-EK KÜLDÉSE A FELÜGYELÕKNEK  /////////////////////////////
// =============================================================================
                    procedure TFoglalo.EmailekKuldese;
// =============================================================================

begin
   _maildir := 'c:\valuta\mail';
   if not Directoryexists(_maildir) then createdir(_maildir);

  _body := 'FOGLALOT VETT FEL EGY PENZTAR'+_sorveg;
  _body := _body + 'Penztar       : ' + _HomePenztarKod + _sorveg;
  _body := _body + 'Rendeles napja: ' + _hatarido + _sorveg;
  _body := _body + 'Rendelt osszeg: ' + ftform(_bankjegy)+' '+_kertDnem+_sorveg;
  _body := _body + 'Arfolyam      : ' + inttostr(_arfolyam) +' (100 '+_kertDnem+'/ Ft)'+_sorveg;
  _body := _body + 'Tranz. tipusa : ' + _tipus;

  _mailstring := '<mail>' + _sorveg;
  _mailstring := _mailstring + '  <addresses>' + _sorveg;
  _mailstring := _mailstring + '    <address>' + _sorveg;
  _mailstring := _mailstring + '      kasza.helga.ebc@gmail.com' + _sorveg;
  _mailstring := _mailstring + '    </address>' + _sorveg;

  _mailstring := _mailstring + '    <address>' + _sorveg;
  _mailstring := _mailstring + '       durucz.tamas.eec@gmail.com' + _sorveg;
  _mailstring := _mailstring + '    </address>' + _sorveg;

  _mailstring := _mailstring + '    <address>' + _sorveg;
  _mailstring := _mailstring + '       fabulyazsuzsa.eec@gmail.com' + _sorveg;
  _mailstring := _mailstring + '    </address>' + _sorveg;

  _mailstring := _mailstring + '    <address>' + _sorveg;
  _mailstring := _mailstring + '       kornel.kiss.epc@gmail.com' + _sorveg;
  _mailstring := _mailstring + '    </address>' + _sorveg;


  if _etaremail<>'' then
    begin
      _mailstring := _mailstring + '    <address>' + _sorveg;
      _mailstring := _mailstring + '      ' + _etaremail + _sorveg;
      _mailstring := _mailstring + '    </address>' + _sorveg;
    end;

  _mailstring := _mailstring + '  </addresses>' + _sorveg;
  _mailstring := _mailstring + '  <subject>' + _sorveg;
  _mailstring := _mailstring + '     foglalo felvetele'+_sorveg;
  _mailstring := _mailstring + '  </subject>'+_sorveg;
  _mailstring := _mailstring + '  <message>'+ _sorveg;
  _mailstring := _mailstring + '    ' +_body + _sorveg;
  _mailstring := _mailstring + '  </message>' + _sorveg;
  _mailstring := _mailstring + '</mail>';

  _remoteFile := 'E' + _homepenztarkod + '.xml';
  _localPath := 'mail\'+_remotefile;
  AssignFile(_pIras,'c:\valuta\' +_localpath);
  rewrite(_pIras);
  write(_piras,_mailstring);
  closefile(_piras);

 _PCS := 'DELETE FROM MEDIA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO MEDIA (REMOTEDIR,REMOTEFILE,LOCALPATH)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + 'SENDMAIL' + chr(39) + ',';
  _pcs := _pcs + chr(39) + _remotefile + chr(39) + ',';
  _pcs := _pcs + chr(39) + _localpath + chr(39) + ')';
  ValutaParancs(_pcs);
  _sendoke := 0;

  _sendoke := copyfiletoftprutin;

  if _sendoke=1 then
    begin
      ShowMessage('AZ E-MAILEKET SIKERESEN ELKÜLDTEM');

      Sysutils.DeleteFile(_localPath);
    end else
    begin
      Showmessage('SIKERTELEN E-MAIL KÜLDÉS');
    end;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
////////////////////  ITT VÉGE VAN A RENDELÉS FELVÉTELÉVEL /////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================




////////////////////////////////////////////////////////////////////////////////
////////////////    FOGLALO VISSZAFIZETÉS MENÜPONT    //////////////////////////
// =============================================================================
            procedure TFOGLALO.KIFIZETESGOMBClick(Sender: TObject);
// =============================================================================

begin
  QuitGomb.Cancel     := False;
  logirorutin(pchar('A kifizetes menüpontot választotta'));
  FoglaloKifizetes;
end;


////////////////////////////////////////////////////////////////////////////////
///////////////////////  FOGLALÓ VISSZAFIZETÉSE    /////////////////////////////
// =============================================================================
                     procedure TFoglalo.FoglaloKifizetes;
// =============================================================================

begin
  if not bizonylatseek then
    begin
      Showmessage('Nincs függõben lévõ foglaló');
      exit;
    end;

  FomenuPanel.Visible := False;

  // -----------------------------------------------------

  RacsTakaro.Visible  := False;
  with MenuFuggony do
    begin
      top := 120;
      left := 16;
      Visible := True;
      repaint;
    end;

  with KifizetesPanel do
    begin
      top     := 200;
      left    := 200;
      Visible := True;
      repaint;
    end;

  with BizSelectPanel do
    begin
      top     := 96;
      left    := 16;
      Visible := True;
      repaint;
    end;

  with Fuggony do
    begin
      top := 105;
      left := 32;
      Visible := True;
      repaint;
    end;

  Activecontrol := Bizracs;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////   MEGNÉZI HOGY VAN-E FÜGGÖBEN LÉVÕ FOGLALÓ ////////////////////
// =============================================================================
                    function Tfoglalo.BizonylatSeek: boolean;
// =============================================================================

begin
   result := False;

   _pcs := 'SELECT * FROM FOGLALOK' + _sorveg;
   _pcs := _pcs + 'WHERE (MOZGAS=1) AND (STORNO=1) AND (STATUS=1)';

   FoglaloDbase.connected := true;
   with FoglaloQuery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Open;
       _recno := recno;
     end;

   if _recno=0 then
     begin
       FoglaloDbase.close;
       FoglaloQuery.close;
       exit;
     end;
  result := true;
end;


////////////////////////////////////////////////////////////////////////////////
/////////////    DUPLA-KLIKK -> BIZONYLATOT VÁLASZTOTT    //////////////////////
// =============================================================================
            procedure TFOGLALO.BIZRACSDblClick(Sender: TObject);
// =============================================================================

begin
  BizonylatotValasztott;
end;

////////////////////////////////////////////////////////////////////////////////
//////////////////   ENTERREL VÁLASZTOTT BIZONYLATOT   /////////////////////////
// =============================================================================
       procedure TFOGLALO.BIZRACSKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  BizonylatotValasztott;
end;


////////////////////////////////////////////////////////////////////////////////
//////////   KIVÁLASZTOTT EGY RENDEZETLEN FOGLALÓ-BIZONYLATOT    ///////////////
// =============================================================================
                procedure TFoglalo.BizonylatotValasztott;
// =============================================================================

begin
  BizselectPanel.visible := false;

  with FoglaloQuery do
    begin
      _ugyfelnev        := trim(FieldByName('UGYFELNEV').AsString);
      _ugyfelszam       := Fieldbyname('UGYFELSZAM').asInteger;
      _hatarido         := fieldByName('HATARIDO').asString;
      _bebizonylat      := FieldByNAme('BIZONYLATSZAM').asString;
      _rendeltOsszeg    := FieldByNAme('RENDELTOSSZEG').asInteger;
      _rendeltValutanem := FieldByNAme('RENDELTVALUTANEM').asString;
      _rendeltertek     := FieldByName('RENDELTERTEK').asInteger;
      _foglalo          := FieldByNAme('FOGLALO').asInteger;
      _foglalodnem      := FieldByNAme('FOGLALOVALUTANEM').asString;
      Close;
    end;
  Foglalodbase.close;

  vfNevPanel.Caption           := _ugyfelnev;
  vfHatidoPanel.Caption        := _hatarido;
  vfBizszamPanel.Caption       := _bebizonylat;
  vfRendeltValutaPanel.Caption := ftform(_rendeltOsszeg)+' '+_rendeltvalutanem;
  vfFoglaloPanel.Caption       := ftform(_foglalo)+' '+_foglaloValutaNem;

  with RacsTakaro do
    begin
      left    := 8;
      top     := 56;
      Visible := true;
      repaint;
    end;

  MenuFuggony.Visible := False;
end;

////////////////////////////////////////////////////////////////////////////////
//////////////     A BIZONYLAT VISSZA-FIZETES RUTIN INDULHAT    ////////////////
// =============================================================================
           procedure TFOGLALO.UGYLETOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _visszaTipus := TBitbtn(Sender).Tag;
  KifizetesPanel.Visible := False;

  _goodtime := true;
  if (_visszatipus=1) and (_hatarido<>_mamas) then _goodtime := False;

  if not _goodtime then
    begin
      MasidoPont;
      exit;
    end;

  _mozgas := 2;  // Normál visszafizetés
  _status := 2;  // A ügylet lerendezve idõben

  VisszaFizetoProcedura;
end;

////////////////////////////////////////////////////////////////////////////////
//////////////  A HATÁRIDÕ ELTÉR A MEGÁLLAPODÁSTÓL      ////////////////////////
// =============================================================================
                           procedure TFoglalo.MasidoPont;
// =============================================================================

begin
  logirorutin(pchar('A határidõ eltér az eredetitõl'));

  NewTimeGomb.enabled   := False;
  MegisMostGomb.Enabled := True;

  with OkozatTakaro do
    begin
      top := 128;
      left := 72;
      Visible := True;
      repaint;
    end;

  with MasHatidoPanel do
    begin
      Top     := 265;
      Left    := 238;
      Visible := true;
    end;
end;


////////////////////////////////////////////////////////////////////////////////
///////////  HATÁRIDÕ NEM STIMMEL - BEFEJEZEM A TRANZAKCIÓT  ///////////////////
// =============================================================================
              procedure TFoglalo.NameFinishGombClick(Sender: TObject);
// =============================================================================

begin
  MasHatidoPanel.Visible := False;
  Fomenure;
end;

////////////////////////////////////////////////////////////////////////////////
////////////  HATÁRIDÕ NEM STIMMEL - DE MÉGIS MEHET A TRANZAKCIÓ  //////////////
// =============================================================================
                 procedure TFoglalo.MegisMostGombClick(Sender: TObject);
// =============================================================================

begin
  // NINCS MÉG HATÁRIDÕ - MÉGIS MOST FIZETEK:

  logirorutin(pchar('Mégis most fizessük ki !'));

  MegisMostGomb.Enabled := False;

 _spvOke := supervisorjelszo(0);
 if _spvOke<>1 then
   begin
     logirorutin(pchar('Nem tudta a supervisor jelszavat'));
     MasHatidoPanel.Visible := False;
     exit;
   end;

  Indokedit.Text := '';
  Okozattakaro.visible := False;

  Indokedit.visible := True;
  ActiveControl := Indokedit;
end;


////////////////////////////////////////////////////////////////////////////////
///////////   MEG KELL INDOKOLNI A HATÁRIDÕCSUSZÁST    /////////////////////////
// =============================================================================
       procedure TFOGLALO.INDOKEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _megjegyzes := trim(Indokedit.Text);
  if _megjegyzes = '' then  exit;

  Newtimegomb.Enabled := true;
  ActiveControl := Newtimegomb;
end;


////////////////////////////////////////////////////////////////////////////////
/////////////            MEHET A TRANZAKCIÓ       //////////////////////////////
// =============================================================================
                procedure TFOGLALO.NewTimeGombClick(Sender: TObject);
// =============================================================================

begin
  // Mehet a tranzakció:

  MasHatidoPanel.Visible := false;
  _mozgas := 2;  // Normál kifizetés
  _status := 3;  // Más határidõbeli visstafizetés
  VisszaFizetoProcedura;
end;


////////////////////////////////////////////////////////////////////////////////
///////////   A FOGLALÓ VÉGLEGES LEZÁRÁSE   ////////////////////////////////////
// =============================================================================
            procedure TFoglalo.VisszaFizetoProcedura;
// =============================================================================


// _visszatipus = 1 -> ugylet oké
// _visszatipus = 2 -> ugylet fault by client
// _visszatipus = 3 -> ugylet fault by EBC


begin
  // A FOGLALOKESZLET-bõl kiveszi a foglaló értékét

  FoglaloKivezetes;

  case _visszatipus of
    1: begin
         _mess := 'ÜGYLET RENDBEN';
         _fizetendo := _foglalo;
         NormalVisszaFizetes;
         Fomenure;
         exit;
       end;

    2: begin     // ügyfél miatt stornó

         _fizetendo := 0;
         _elojel    := '+';
         _mozgas    := 3;
         _status    := 3;

         _mess := 'ÜGYFÉL MIATT SEMMIS';
         _hibamess := 'ÜGYFÉL HIBÁJA MIATT A FOGLALÓ ITT MARAD';
       end;

    3: begin     // EXCLUSIVE MIATT STORNÓ:

         _fizetendo := round(2*_foglalo);
         _elojel := '-';
         _mozgas := 4;
         _status := 4;
         _mess := 'EBC MIATT SEMMIS';
         _hibamess := 'AZ EXCLUSIVE CHANGE HIBÁJA MIATT DUPLÁN VISSZAFIZETJÜK A FOGLALÓT';
       end;
  end;

  _fBizonylat   := GetHibaBizonylat;
  _aktarfolyam  := GetArfolyam(_foglalovalutanem);
  _foglaloErtek := round(_foglalo*_aktarfolyam/100);
  _foglaloertek := kerekito(_foglaloertek);

  if _visszatipus=3 then _foglaloertek := round(2*_foglaloertek);

  // bejegyezi az adatbazisba a visszafizetés tényét:

  VisszaRekordiras;

  // Kinyomtatja a visszafizetési bizonylatot:

  KiBiziro;

  ShowMessage(_hibamess);
  Fomenure;
end;


////////////////////////////////////////////////////////////////////////////////
/////////////////  NORMÁL VISSZAFIZETÉS    /////////////////////////////////////
// =============================================================================
                   procedure TFoglalo.NormalvisszaFizetes;
// =============================================================================

begin

  // bejegyzi az adatbázisba a visszafizetés adatait:
  VisszaRekordIras;

  // kinyomtatja a visszafizetési bizonylatott:

  Kibiziro;
  Showmessage('A VISSZAFIZETÉS RENDBEN LEZAJLOTT');
end;


////////////////////////////////////////////////////////////////////////////////
//////////    A visszafizetés adatait beirja az adatbázisba   ///////////////////
// =============================================================================
                    procedure Tfoglalo.VisszaRekordIras;
// =============================================================================

begin
  _kibizonylat := KibizonylatLepteto;

  _pcs := 'UPDATE FOGLALOK SET STATUS='+inttostr(_status);
  _pcs := _pcs + ',MOZGAS=2' + _sorveg;

  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_bebizonylat+chr(39);
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO FOGLALOK (DATUM,UGYFELSZAM,UGYFELNEV,UGYFELTIPUS,BIZONYLATSZAM,';
  _pcs := _pcs + 'HATARIDO,RENDELTOSSZEG,RENDELTERTEK,RENDELTVALUTANEM,FOGLALO,';
  _pcs := _pcs + 'FOGLALOVALUTANEM,MOZGAS,HIVATKOZAS,STATUS,STORNO,OSSZEG,OSSZEGVALUTANEM,';
  _pcs := _pcs + 'MEGJEGYZES)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + chr(39) + _mamas + chr(39) + ','; // mai nap

  _pcs := _pcs + inttostr(_ugyfelszam)+',';                     // ügyfél adatai
  _pcs := _pcs + chr(39) + _ugyfelnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ugyfeltipus + chr(39) + ',';

  _pcs := _pcs + chr(39) + _kibizonylat + chr(39) + ',';         // kiadási bizonylat száma

  _pcs := _pcs + chr(39) + _hatarido + chr(39) + ',';   // eredeti határidõ
  _pcs := _pcs + inttostr(_rendeltOsszeg) + ',';              // rendelt valuta adatai
  _pcs := _pcs + inttostr(_rendeltErtek) + ',';
  _pcs := _pcs + chr(39) + _rendeltvalutanem + chr(39) + ',';

  _pcs := _pcs + inttostr(_foglalo) + ',';                      // foglaló mennyisége
  _pcs := _pcs + chr(39) + _foglaloValutanem + chr(39) + ',';

  _pcs := _pcs + inttostr(_mozgas) + ',';                      // Mozgas =3
  _pcs := _pcs + chr(39) + _bebizonylat + chr(39) + ',';  // hivatkozás a befizetés bizonylata
  _pcs := _pcs + inttostr(_status) + ',';                  // status = 3

  _pcs := _pcs + '1,';       // storno nincs

  _pcs := _pcs + inttostr(_fizetendo)+',';           // 0 = nincs mit kifizetni
  _pcs := _pcs + chr(39) + _foglaloValutanem + chr(39) + ',';   // ebbõl a pénznembõl
  _pcs := _pcs + chr(39) + _mess + chr(39) + ')';     //
  ValutaParancs(_pcs);
end;


///                     A BIZONYLATOK KILISTÁZÁSA


// /////////////////////////////////////////////////////////////////////////////
// ////////////////////       BIZONYLATOK       ////////////////////////////////
// /////////////////////////////////////////////////////////////////////////////
// =============================================================================
            procedure TFOGLALO.LISTAGOMBClick(Sender: TObject);
// =============================================================================

begin

  FomenuPanel.Visible := False;

  FuggoDbase.Connected := True;
  FuggoQuery.Open;
  FuggoQuery.First;
  _recno := FuggoQuery.recno;
  if _recno=0 then
    begin
      FuggoDbase.close;
      FuggoQuery.close;
      NincsFuggoPanel.visible := True;
      NincsFuggoPanel.repaint;
    end;

  // -------------------------

  RendDbase.Connected := true;
  RendQuery.Open;
  RendQuery.First;
  _recno := rendquery.recno;
  if _recno=0 then
    begin
      rendDbase.close;
      rendQuery.close;
      NincsRendezettFoglaloPanel.visible := True;
      NincsRendezettFoglaloPanel.repaint;
    end;

  with FuggoPanel do
    begin
      top := 336;
      left := 40;
      Visible := True;
      repaint;
    end;

  with RendezettPanel do
    begin
      top := 336;
      left := 520;
      Visible := True;
      repaint;
    end;

  with ListVisszaGomb do
    begin
      top := 696;
      left := 424;
      Visible := True;
      repaint;
    end;
  Fuggoracs.SetFocus;
end;


// =============================================================================
          procedure TFOGLALO.LISTAVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  FoglaloTabla.Close;
  FoglaloDbase.Close;
  Fomenure;
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////    kilépés a programból   /////////////////////////////
// =============================================================================
                 procedure TFOGLALO.QUITGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;

// =============================================================================
           procedure TFOGLALO.bizonylateditEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).color := clYellow;
end;

// =============================================================================
            procedure TFOGLALO.bizonylateditExit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clWindow;
end;

// =============================================================================
          procedure TFOGLALO.ATVETELGOMBEnter(Sender: TObject);
// =============================================================================

begin
  QuitGomb.Cancel := true;
  with TBitbtn(sender).Font do
    begin
      Color := clMaroon;
      Size := 12;
      Style := [fsBold,fsItalic];
    end;
end;

// =============================================================================
                procedure TFOGLALO.ATVETELGOMBExit(Sender: TObject);
// =============================================================================

begin
   with TBitBtn(sender).Font do
    begin
      Color := clBlack;
      Size := 11;
      Style := [fsItalic];
    end;
end;

// =============================================================================
        procedure TFOGLALO.ATVETELGOMBMouseMove(Sender: TObject;
                                         Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  activeControl := TBitBtn(sender);
end;

// =============================================================================
            procedure TFOGLALO.OSSZEGEDITEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).color := clYellow;
end;

// =============================================================================
            procedure TFOGLALO.OSSZEGEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).Color := clWindow;
end;

// =============================================================================
                           procedure TFoglalo.GetUgyfelData;
// =============================================================================

var _uOke: boolean;

begin
  _uoke := UgyfeldataRead(_ugyfelszam);

  if not _uOke then
    begin
      logirorutin(pchar('Nem talált ügyfelet. Adatokat nullázza'));
      _ugyfelnev   := '';
      _anyjaNeve   := '';
      _szulido     := '';
      _szulhely    := '';
      _okmanytipus := '';
      _azonosito   := '';
      _allampolgar := '';
    end;
end;

// =============================================================================
                  function TFoglalo.Space(_hh: integer):string;
// =============================================================================

begin
  Result := dupeString(' ',_hh);
end;

// =============================================================================
            procedure TFoglalo.ujnevquitClick(Sender: TObject);
// =============================================================================

begin
  AdatBekeroPanel.visible := false;
end;

// =============================================================================
         procedure TFoglalo.VALASZMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Valutaquery.close;
  Valutadbase.close;
  UgyfelValasztoPanel.Visible := false;
end;

// =============================================================================
          procedure TFoglalo.UGYFELRACSDblClick(Sender: TObject);
// =============================================================================

begin
  _ugyfelszam := ValutaQuery.FieldByName('UGYFELSZAM').asInteger;
   ValutaQuery.close;
  Valutadbase.close;
  UgyfeletValasztott;
end;

// =============================================================================
             function TFoglalo.Ftform(_ft: integer): string;
// =============================================================================

var _fts: string;
    _wfts,_f1: byte;

begin
  result := '-';
  _fts := inttostr(_ft);
  if _ft=0 then exit;

  result := _fts;
  _wfts := length(_fts);

  if _wfts<4 then exit;


  if _wfts>6 then
    begin
      _f1 := _wfts - 6;
      result := leftstr(_fts,_f1)+'.' +midstr(_fts,_f1+1,3)+'.'+midstr(_fts,_f1+4,3);
      exit;
    end;

  _f1 := _wfts - 3;
  result := leftstr(_fts,_f1)+'.' +midstr(_fts,_f1+1,3);
end;

// =============================================================================
              function TFoglalo.ArfForm(_aw: word): string;
// =============================================================================

var _w,_f1: byte;
    _ast: string;

begin
  _ast := inttostr(_aw);
  _w  := length(_ast);
  if _w<3 then
    begin
      result := _ast;
      exit;
    end;

  _f1 := _w-2;
  result := leftstr(_ast,_f1)+','+midstr(_ast,_f1+1,2);
end;

// =============================================================================
                function TFoglalo.Nulele(_b: byte):string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;





// =============================================================================
                procedure TFoglalo.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.connected := true;
  if Valutatranz.InTransaction then valutatranz.Commit;
  Valutatranz.StartTransaction;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Valutatranz.Commit;
  Valutadbase.close;
end;

// =============================================================================
          procedure TFOGLALO.ARFOLYAMEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).color := clwhite;
end;

// =============================================================================
                function TFoglalo.Kerekito(_int:integer): integer;
// =============================================================================

var _str: string;
    _ww,_utbetu: integer;
begin
  result := 0;
  if _int=0 then exit;

  result  := _int;
  _str    := inttostr(result);
  _ww     := length(_str);
  _utbetu := ord(_str[_ww])-48;
  if (_utbetu=0) or (_utbetu=5) then exit;

  if _utbetu<5 then result := result - _utbetu
  else result := result + (10-_utbetu);

end;

procedure TFOGLALO.VISSZACANCELGOMBClick(Sender: TObject);
begin
  MasHatidoPanel.visible := False;
  KifizetesPanel.visible := False;
  Fomenure;
end;


////////////////////////////////////////////////////////////////////////////////
//////////     ÜGYFELEKKEL FOGLALKOZÓ RUTINOK  /////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
           function TFoglalo.Ugyfeldataread(_usz: integer): boolean;
// =============================================================================

begin
  logirorutin(pchar('Ugyféladatok beolvasása. Ügyfélszám: '+inttostr(_usz)));
  result := false;
  _pcs := 'SELECT * FROM UGYFEL' + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_usz);
  valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      logirorutin(pchar('Nem találta meg az ügyfelet  !'));
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

  with ValutaQuery do
    begin
      _ugyfelnev := trim(FieldByName('NEV').asString);
      _anyjaneve := trim(FieldByName('ANYJANEVE').asString);
      _szulhely  := trim(FieldByName('SZULETESIHELY').asString);
      _szulido   := trim(FieldByName('SZULETESIIDO').asString);
      _okmanytipus := trim(FieldByName('OKMANYTIPUS').asString);
      _azonosito := trim(FieldByName('AZONOSITO').asString);
      _allampolgar := trim(FieldByName('ALLAMPOLGAR').asstring);
      close;
    end;
  Valutadbase.close;

  logirorutin(pchar('Megtalálta az ügyfelet: '+_ugyfelnev+','+_anyjaneve));
  result := true;
end;



function Tfoglalo.Getarfolyam(_vn: string): integer;

begin
  if _vn='HUF' then
    begin
      result := 100;
      exit;
    end;

  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM='+chr(39)+_vn+chr(39);
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      result := Fieldbyname('ELSZAMOLASIARFOLYAM').asInteger;
      Close;
    end;
  Valutadbase.close;
end;






// =============================================================================
             procedure TFOGLALO.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  GetugyfelPanel.Visible := False;
  Fomenure;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
/////////////////////   SEGÉDPEOGRAMOK LS FUNKCIÓK /////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
        function TFoglalo.Hundatetostr(_caldat: TDatetime): string;
// =============================================================================

begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;

// =============================================================================
        function TFoglalo.Hunstrtodate(_calstr: string): TdateTime;
// =============================================================================

begin
  _h_ev  := strtoint(leftstr(_calstr,4));
  _h_ho  := strtoint(midstr(_calstr,6,2));
  _h_nap := strtoint(midstr(_calstr,9,2));

  result := encodedate(_h_ev,_h_ho,_h_nap);
end;

// =============================================================================
                function TFoglalo.GetHibaBizonylat: string;
// =============================================================================

var _uf: integer;
    _fb: string;

begin

  result := '';
  if _visszaTipus=1 then exit;

  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM UTOLSOBLOKKOK');
      Open;
    end;

  if _visszaTipus=2 then    // ÜGYFÉL HIBÁJA MIATT BEVÉTELEZÉS
    begin
      _TIPUS := 'U';
      if _foglalovalutanem='HUF' then
        begin
          _uf := ValutaQuery.FieldbyName('UTOLSOFORINTATVETELBLOKK').asInteger;
          _fB := 'UF'+ eloKieg(_ptarnum,3)+elokieg(_uf,5);
          inc(_uf);
          _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOFORINTATVETELBLOKK='+inttostr(_uf);
          ValutaParancs(_pcs);
        end else
        begin
          _uf := ValutaQuery.FieldbyName('UTOLSOATVETELBLOKK').asInteger;
          _fB := 'U'+ eloKieg(_ptarnum,3)+elokieg(_uf,6);
          inc(_uf);
          _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOATVETELBLOKK='+inttostr(_uf);
        end;
    end;

  if _visszaTipus=3 then    // exclusive HIBÁJA MIATT BEVÉTELEZÉS
    begin
      _tipus := 'F';
      if _foglalovalutanem='HUF' then
        begin
          _uf := ValutaQuery.FieldbyName('UTOLSOFORINTATADASBLOKK').asInteger;
          _fB := 'FF'+ eloKieg(_ptarnum,3)+elokieg(_uf,5);
          inc(_uf);
          _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOFORINTATADASBLOKK='+inttostr(_uf);
          ValutaParancs(_pcs);
        end else
        begin
          _uf := ValutaQuery.FieldbyName('UTOLSOATADASBLOKK').asInteger;
          _fB := 'F'+ eloKieg(_ptarnum,3)+elokieg(_uf,6);
          inc(_uf);
          _pcs := 'UPDATE UTOLSOBLOKKOK SET UTOLSOATADASBLOKK='+inttostr(_uf);
        end;
    end;
  ValutaParancs(_pcs);
  result := _fb;
end;

// =============================================================================
              function TFoglalo.getidos: string;
// =============================================================================

var _idos: string;

begin
  _idos := timetostr(Time);
  if midstr(_idos,2,1)=':' then _idos := '0' + _idos;
  result := leftstr(_idos,5);
end;


// =============================================================================
            procedure TFOGLALO.ARFOLYAMEDITEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).Color := clYellow;
end;

// =============================================================================
          function Tfoglalo.Elokieg(_targy:integer;_len: byte): string;
// =============================================================================

begin
  result := inttostr(_targy);
  while length(result)<_len do result := '0' + result;
end;


// =============================================================================
         procedure TFOGLALO.LISTVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  fuggoQuery.close;
  RendQuery.close;
  FuggoDbase.close;
  RendDbase.close;
  FuggoPanel.Visible := False;
  RendezettPanel.visible  := False;
  ListVisszaGomb.Visible := False;
  Fomenure;
end;



////////////////////////////////////////////////////////////////////////////////
///////////////////////  FOGLALO BEVÉTELEZÉSE   ////////////////////////////////
// =============================================================================
                   procedure TFoglalo.FoglaloBevetelezes;
// =============================================================================

begin

  Valutadbase.Connected := True;
  if ValutaTranz.InTransaction then Valutatranz.Commit;

  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM FOGLALOKESZLET');
      Open;
      _valdarab := FieldByNAme('VALDARAB').asInteger;
    end;

  _y := 0;
  while _y<_valdarab do
    begin
      _vmezo := 'V' + inttostr(_y);
      _aktdnem := ValutaQuery.fieldByNAme(_vmezo).asString;

      if _aktdnem=_foglalodnem then
        begin
          _kmezo      := 'K' + inttostr(_y);
          _aktkeszlet := ValutaQuery.fieldByName(_kmezo).asInteger;
          _ujkeszlet  := _aktkeszlet + _foglalo;

          _pcs := 'UPDATE FOGLALOKESZLET SET ' + _kmezo+'='+inttostr(_ujkeszlet);

          with ValutaQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Execsql;
            end;

          ValutaTranz.commit;
          Valutadbase.close;
          exit;
        end;

      inc(_y);
    end;

  _kmezo := 'K' + inttostr(_y);
  _vmezo := 'V' + inttostr(_y);
  inc(_valdarab);

  _pcs := 'UPDATE FOGLALOKESZLET SET '+_kmezo+'='+inttostr(_foglalo);
  _pcs := _pcs + ',' + _vMezo + '=' + chr(39) + _foglalodnem + chr(39);
  _pcs := _pcs + ',VALDARAB=' + inttostr(_valdarab);

  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;

  ValutaTranz.commit;
  Valutadbase.close;
end;

////////////////////////////////////////////////////////////////////////////////
///////////////       A FOGLALÓ KIVEZETÉSE     /////////////////////////////////
// =============================================================================
                  procedure TFoglalo.FoglaloKivezetes;
// =============================================================================

var _dn: string;
    _aktkesz,_ujkesz: integer;

begin
  _ujkesz := 0;
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM FOGLALOKESZLET');
      Open;
      _valdarab := FieldByName('VALDARAB').asInteger;
    end;
  _y := 0;
  while _y<=4 do
    begin
      _vmezo := 'V' + chr(48+_y);
      _kMezo := 'K' + chr(48+_y);
      _dn := ValutaQuery.FieldByName(_vmezo).asString;
      if _dn=_foglalodnem then
         begin
           _aktkesz := ValutaQuery.Fieldbyname(_kmezo).asInteger;
           _ujkesz  := _aktkesz-_foglalo;
           if _ujkesz<0 then _ujkesz := 0;
           break;
         end;
      inc(_y);
    end;
  valutaquery.close;
  Valutadbase.close;
  if _y>4 then exit;
  _pcs := 'UPDATE FOGLALOKESZLET SET '+_kmezo+'='+inttostr(_ujkesz);
  ValutaParancs(_pcs);
end;

////////////////////////////////////////////////////////////////////////////////
///////////////////   LÉPTETI A BEVÉTEL BIZONYLATSZÁMÁT   //////////////////////
// =============================================================================
              function TFoglalo.BebizonylatLepteto: string;
// =============================================================================

var _utbe: integer;

begin
  Valutadbase.connected := true;
  if ValutaTranz.InTransaction then valutatranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM FOGLALOKESZLET');
      Open;
      _utbe := FieldByNAme('UTBEBIZSZAM').asInteger;
    end;

  inc(_utbe);

  _pcs := 'UPDATE FOGLALOKESZLET SET UTBEBIZSZAM='+inttostr(_utbe);
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Execsql;
    end;
  valutatranz.commit;
  Valutadbase.close;

  result := 'B'+ null5(_utbe);
end;


////////////////////////////////////////////////////////////////////////////////
//////////////////  VISSZAFIZETES BIZONYLATSZAM LÉPTETÉSE   ////////////////////
// =============================================================================
              function TFoglalo.KiBizonylatLepteto: string;
// =============================================================================

var _utki: integer;

begin
  Valutadbase.connected := true;
  if ValutaTranz.InTransaction then valutatranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM FOGLALOKESZLET');
      Open;
      _utki := FieldByNAme('UTKIBIZSZAM').asInteger;
    end;

  inc(_utKI);

  _pcs := 'UPDATE FOGLALOKESZLET SET UTKIBIZSZAM='+inttostr(_utki);
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Execsql;
    end;
  valutatranz.commit;
  Valutadbase.close;

  result := 'K'+ null5(_utki);
end;

// =============================================================================
                function TFoglalo.Null5(_b: integer): string;
// =============================================================================

begin
  result := inttostr(_b);
  while length(result)<5 do result := '0' + result;
end;




// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//////////////////////   NYOMTATVÁNYOK /////////////////////////////////////////
// =============================================================================
                      procedure TFoglalo.Bebiziro;
// =============================================================================

begin

  logirorutin(pchar('Foglalo átvétel bizonylat nyomtatás'));

  BizonylatFejiro('           FOGLALO ATVETELE');

  writeLN(_LFile,'   Bizonylat szama: ' + _bizonylatszam);
  writeLn(_LFile,'    Rendelt osszeg: ' + trim(FTform(_bankjegy)+' '+_kertdnem));
  writeLN(_LFile,'  ennek ft. erteke: ' + trim(FTForm(_ftertek)+ ' HUF'));
  writeLn(_LFile,' Ugylet hatarideje: ' + _hatarido);
  writeLn(_LFile,'   Foglalo osszege: ' + trim(FTForm(_foglalo)+' '+ _foglalodnem));
  writeLn(_LFile,' Foglalo befizetve: ' + _mamas);

  VonalHuzo;
  writeLN(_LFile,'A fent megjelolt ugyfel ( tovabbiakban:');
  writeLN(_LFile,'Ugyfel) a  jelen  bizonylat alairasaval');
  writeLN(_LFile,'egyidejuleg   megfizeti  az   Exclusive');
  writeLN(_LFile,'Change (tovabbiakban:Megbizott) reszere');
  writeLN(_LFile,'a  fent megjelolt ellenertek osszegenek');
  writeLN(_LFile,'ot szazalekanak (5 %)  megfelelo ossze-');
  writeLN(_LFile,'get  foglalokent, mely osszeg atvetelet');
  writeLN(_LFile,'a Megbizott a jelen bizonylat alairasa-');
  writeLN(_LFile,'val nyugtaz es elismer.' + _sorveg);

  writeLN(_LFile,'Ugyfel es  Megbizott kijelentik, hogy a');
  writeLN(_LFile,'foglalo  jogi  termeszetevel  tisztaban');
  writeLN(_LFile,'vannak,  azt magukra  nezve kotelezonek');
  writeLN(_LFile,'ismerik el. Tudomassal birnak  azon ko-');
  writeLN(_LFile,'rulmenyrol,hogy amennyiben a penzvalta-');
  writeLN(_LFile,'si  megbizasi szerzodes  teljesulese  a');
  writeLN(_LFile,'szerzodes megkotese  utan Megbizott fe-');
  writeLN(_LFile,'lelossegebe tartozo okbol hiusulna meg,');
  writeLN(_LFile,'a foglalo ketszeres  osszege Ugyfel re-');
  writeLN(_LFile,'szere visszajar. Abban az esetben, ha a');
  writeLN(_LFile,'szerzodes teljesulese a szerzodes megko-');
  writeLN(_LFile,'tese utan az Ugyfel felelossegeben fel-');
  writeLN(_LFile,'merult okbol hiusulna meg, akkor az al-');
  writeLN(_LFile,'tala atadott osszeget  vegleg  elveszti.');
  writeLN(_LFile,'Az atadott foglalo az Ugyfel  altal fi-');
  writeLN(_LFile,'zetendo  osszegbe  beszamitasra  kerul.');

  writeLN(_LFile,'Tajekoztatjuk ugyfeleinket, hogy a fel-');
  writeLN(_LFile,'tuntetett arfolyam tajekoztato jellegu.');
  writeLN(_LFile,'Az aktualis arfolyam a kifizetes napjan');
  writeLN(_LFile,'        kerul meghatarozasra.'+_sorveg);

  AlairasIro;
  StartNyomtatas;
end;

// =============================================================================
                     procedure TFoglalo.KiBiziro;
// =============================================================================

///           FOGLALÓ VISSZAFIZETÉSE vagy NEM

begin

  if _visszatipus=1 then BizonylatFejiro('       FOGLALO VISSZAFIZETESE');
  if _visszatipus=2 then bizonylatFejiro(' ÜGYFÉL HIBÁJA MIATT MEGHIUSULT ÜGYLET');
  if _visszatipus=3 then Bizonylatfejiro('EXCLUSIVE HIBÁJA MIATT MEGHIUSULT ÜGYLET');

  writeLN(_LFile,'  Kifizetes bizonylata: '+ _kibizonylat);
  writeLn(_LFile,'Foglalo atvetel napja : '+ _hatarido);
  writeLN(_LFile,'Foglalo bizonylatszama: '+ _bebizonylat);
  writeLn(_LFile,'Atvett foglalo osszege: '+ trim(FtForm(_foglalo)+' '+_foglaloValutanem));
  writeLN(_LFile,'Foglalo rendezés napja: '+ _mamas + _sorveg);

  if not _goodTime then
    begin
      writeLn(_LFile,'(Hataridotol eltérés indoka: ');
      writeLn(_LFile,'  '+_megjegyzes+_sorveg);
    end;

  if _visszatipus=1 then
    begin
      writeLn(_LFile,'A mai napon a fenti ügyfél által a fenti');
      writeLn(_LFile,'napon befizetett foglaló összege a  mai');
      writeLn(_LFile,'napon végrehajtott ügylet ellenértékébe');
      writeLn(_LFile,'        beszámitásra került.');
      AlairasIro;
    end;

  if _visszatipus=2 then
    begin
      writeLN(_LFile,'A mai napon a fenti ügyfél által a fenti');
      writeLN(_LFile,'napon befizetett foglaló osszeget bevé-');
      writeLN(_LFile,'telként elkönyveltem az ügyfél hibájából');
      writeLN(_LFile,'       meghiusult ügylet miatt:');
      writeLn(_LFile,'   Elkönyvelt összeg: ' + Ftform(_foglalo)+' '+ _foglaloValutanem);
      writeLN(_LFile,_sorveg);
      writeLn(_Lfile,'        .......................');
      writeLN(_LFile,'                pénztáros');
    end;

  if _visszatipus=3 then
    begin
      writeLN(_LFile,'A mai napon a fenti ügyfél által a fenti');
      writeLN(_LFile,'napon befizetett foglaló kétszeres össze-');
      writeLN(_LFile,'ge az ügylet meghiusulása miatt kifize-');
      writeLN(_LFile,'             tésre került:');
      writeLn(_LFile,'   Kifizetett összeg: '+FtForm(_fizetendo)+' '+_foglaloValutanem);
      AlairasIro;
    end;
  StartNyomtatas;
end;

// =============================================================================
                       procedure TFoglalo.Alairasiro;
// =============================================================================

begin
  writeLn(_LFile,_sorveg);
  writeLN(_LFile,'..................    .................');
  writeLN(_LFile,'    penztaros              ugyfel');
end;

// =============================================================================
                          procedure TFoglalo.VonalHuzo;
// =============================================================================

begin
  writeLn(_Lfile,dupeString('-',40));
end;


// =============================================================================
                     procedure TFoglalo.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,Space(_oo)+_szoveg);
end;

// =============================================================================
              procedure TFoglalo.BizonylatFejiro(_fejlec: string);
// =============================================================================

var _uoke : boolean;

begin
  _uoke := UgyfeldataRead(_ugyfelszam);
  if not _uoke then
    begin
      ShowMessage('AZ ÜGYFÉL ADATAI ÉRVÉNYTELENEK');
      ModalResult := 2;
      exit;;
    end;

  assignFile(_LFile,'c:\valuta\aktlst.txt');
  Rewrite(_LFile);
  VonalHuzo;
  writeln(_LFile,_fejlec);
  VonalHuzo;


  writeLn(_LFile,'Ugyfel neve: ' + _ugyfelnev);
  writeLN(_LFile,' Anyja neve: ' + _anyjaneve);
  writeLn(_LFile,'Szul-i hely: ' + _szulhely);
  writeLn(_LFile,'Szul-i ido : ' + _szulido);
  writeLn(_Lfile,'Okmanytipus: ' + _okmanytipus);
  writeLn(_LFile,'Okmany szam: ' + _azonosito);
  writeLn(_LFile,'Allampolgar: ' + _allampolgar);
  VonalHuzo;
end;

// =============================================================================
                      procedure TFoglalo.StartNyomtatas;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin
  Writeln(_LFile,_LF5);
  WriteLn(_LFile,chr(26));
  CloseFile(_LFile);

  //  EXIT;   //////////////// TESZTELÉS !!!!!!!!!!!!!!!!!!!!!!!

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else assignprn(_nyomtat);
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

// =============================================================================
             procedure TFoglalo.NevEditEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(SENDER).Color := clYellow;
end;

// =============================================================================
           procedure TFoglalo.NevEditExit(Sender: TObject);
// =============================================================================

begin
  Tedit(Sender).Color := clWhite;
end;


// =============================================================================
          procedure TFOGLALO.KESZLETVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  KeszletPanel.visible := False;
  Fomenure;
end;

// =============================================================================
            procedure TFOGLALO.KESZLETGOMBClick(Sender: TObject);
// =============================================================================

var _v0,_v1,_v2,_v3,_v4: string;
    _k0,_k1,_k2,_k3,_k4: integer;

begin
  FomenuPanel.Visible := False;

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM FOGLALOKESZLET');
      Open;
      _v0 := trim(FieldByNAme('V0').asstring);
      _k0 := FieldByNAme('K0').asInteger;
      _v1 := trim(FieldByNAme('V1').asstring);
      _k1 := FieldByNAme('K1').asInteger;
      _v2 := trim(FieldByNAme('V2').asstring);
      _k2 := FieldByNAme('K2').asInteger;
      _v3 := trim(FieldByNAme('V3').asstring);
      _k3 := FieldByNAme('K3').asInteger;
      _v4 := trim(FieldByNAme('V4').asstring);
      _k4 := FieldByNAme('K4').asInteger;
      close;
    end;
  Valutadbase.close;

  Kp0.Caption := FtForm(_k0);
  Kv0.Caption := _v0;
  Kp1.Caption := FtForm(_k1);
  Kv1.Caption := _v1;
  Kp2.Caption := FtForm(_k2);
  Kv2.Caption := _v2;
  Kp3.Caption := FtForm(_k3);
  Kv3.Caption := _v3;
  Kp4.Caption := FtForm(_k4);
  Kv4.Caption := _v4;


  with Keszletpanel do
    begin
      top := 440;
      left := 390;
      Visible := true;
      repaint;
    end;
  Activecontrol := KeszletVisszaGomb;
end;
end.

