unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, strutils, IBDatabase, DB, IBCustomDataSet,
  IBQuery, Buttons, Grids, DBGrids,dateutils;

type
  TForm2 = class(TForm)

    EvPanel        : TPanel;
    LetiltoGomb    : TPanel;
    KeresoPanel    : TPanel;
    KilepoGomb     : TPanel;
    KeresoGomb     : TPanel;
    MenuPanel      : TPanel;
    NaturPanel     : TPanel;
    Panel1         : TPanel;
    Panel2         : TPanel;
    Panel5         : TPanel;
    ScanAskPanel   : TPanel;
    Blokkpanel     : TPanel;
    TtPanel        : TPanel;
    PTPanel        : TPanel;
    ProsPanel      : TPanel;
    FizeszkozPanel : TPanel;
    JevPanel       : TPanel;
    NaturVisszaGomb: TPanel;
    Panel3         : TPanel;
    V1             : TPanel;
    V2             : TPanel;
    V3             : TPanel;
    V5             : TPanel;
    V6             : TPanel;
    V4             : TPanel;
    A1             : TPanel;
    A2             : TPanel;
    A4             : TPanel;
    A5             : TPanel;
    A6             : TPanel;
    A3             : TPanel;
    E1             : TPanel;
    E2             : TPanel;
    E3             : TPanel;
    E4             : TPanel;
    E5             : TPanel;
    E6             : TPanel;
    F2             : TPanel;
    F1             : TPanel;
    F3             : TPanel;
    F4             : TPanel;
    F5             : TPanel;
    F6             : TPanel;
    InformacioPanel: TPanel;
    NaturDataPanel : TPanel;
    BizPanel       : TPanel;
    QDatumPanel    : TPanel;
    LastTranzPanel : TPanel;
    TranzPanel     : TPanel;
    BackGomb       : TPanel;
    ScanGomb       : TPanel;
    TiltottPanel   : TPanel;
    JogiDataPanel  : TPanel;
    TdbPanel       : TPanel;
    JogiPanel      : TPanel;
    EviMaxPanel    : TPanel;
    EviSumPanel    : TPanel;
    Panel4         : TPanel;
    Panel6         : TPanel;
    Panel7         : TPanel;
    Panel8         : TPanel;
    Panel9         : TPanel;
    WBizPanel      : TPanel;
    WDatIdo        : TPanel;
    KezdijPanel    : TPanel;
    FizetendoPanel : TPanel;

    Label9         : TLabel;
    Label33        : TLabel;
    Label34        : TLabel;
    Label35        : TLabel;
    Label36        : TLabel;
    Label37        : TLabel;
    Label38        : TLabel;
    Label39        : TLabel;
    Label40        : TLabel;
    Label41        : TLabel;
    Label23        : TLabel;
    Label24        : TLabel;
    Label25        : TLabel;
    Label26        : TLabel;
    Label27        : TLabel;
    Label28        : TLabel;
    Label5         : TLabel;
    Label1         : TLabel;
    Label4         : TLabel;
    Label10        : TLabel;
    Label11        : TLabel;
    Label6         : TLabel;
    Label7         : TLabel;
    Label12        : TLabel;
    Label32        : TLabel;
    Label13        : TLabel;
    Label14        : TLabel;
    Label15        : TLabel;
    Label16        : TLabel;
    Label17        : TLabel;
    Label18        : TLabel;
    Label19        : TLabel;
    Label20        : TLabel;
    Label21        : TLabel;
    Label22        : TLabel;
    Label2         : TLabel;
    Label3         : TLabel;
    Label42        : TLabel;
    Label43        : TLabel;
    Label8         : TLabel;
    Label30        : TLabel;
    Label31        : TLabel;
    Label29        : TLabel;
    Label44        : TLabel;
    Label45        : TLabel;
    Label46        : TLabel;
    Label47        : TLabel;
    Label48        : TLabel;
    Label49        : TLabel;
    Label50        : TLabel;
    Label51        : TLabel;
    Label52        : TLabel;

    JogiNevEdit    : TEdit;
    TelephelyEdit  : TEdit;
    OkiratEDIT     : TEdit;
    FoTevekenyEdit : TEdit;
    MbNevEdit      : TEdit;
    MbBeoEdit      : TEdit;
    KepvisNevEdit  : TEdit;
    KepvisBeoEdit  : TEdit;
    JStatuszEdit   : TEdit;
    UgynevEdit     : TEdit;
    ElonevEdit     : TEdit;
    LeanyEdit      : TEdit;
    AnyjaEdit      : TEdit;
    SzulhelyEdit   : TEdit;
    SzulidoEdit    : TEdit;
    AllampolgarEdit: TEdit;
    LakcimEdit     : TEdit;
    OkmTipEdit     : TEdit;
    AzonositoEdit  : TEdit;
    TarthelyEdit   : TEdit;
    LCimCardEdit   : TEdit;
    StatuszEdit    : TEdit;
    JKerNevEdit    : TEdit;
    KerNevEdit     : TEdit;
    Nevedit        : TEdit;

    BizQuery       : TIBQuery;
    BizDBase       : TIBDatabase;
    BizTranz       : TIBTransaction;

    BizlatokQuery  : TibQuery;
    BizlatokDbase  : TibDatabase;
    BizlatokTranz  : TibTransaction;

    JQuery         : TIBQuery;
    JDbase         : TIBDatabase;
    JTranz         : TIBTransaction;

    NQuery         : TIBQuery;
    NDbase         : TIBDatabase;
    NTranz         : TIBTransaction;

    RemoteQuery    : TibQuery;
    RemoteDbase    : TibDatabase;
    RemoteTranz    : TibTransaction;

    BlokkVisszaGomb: TBitBtn;
    JOGIVISSZAGOMB: TBitBtn;
    BitBtn3        : TBitBtn;


    NRadio         : TRadioButton;
    JRadio         : TRadioButton;

    Shape1         : TShape;
    Shape2         : TShape;
    Shape3         : TShape;

    Evcombo        : TComboBox;

    BizRacs        : TDBGrid;
    JogiRacs       : TDBGrid;
    NaturRacs      : TDBGrid;

    BizSource      : TDataSource;
    NaturSource    : TDataSource;
    JogiSource     : TDataSource;

    procedure EvcomboTolto;
    procedure AllDisplay;
    procedure NaturRacsDblClick(Sender: TObject);
    procedure NaturRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AllAdatbeolvasas;
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Menube;
    procedure Nevkereses(Sender: TObject);
    procedure NevEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NevEditEnter(Sender: TObject);
    procedure NevEditExit(Sender: TObject);
    procedure NevetValasztott;
    procedure Setkertev;
    procedure Xdatabe;
    procedure ScanGombClick(Sender: TObject);
    procedure BizRacsCellClick(Column: TColumn);
    procedure evcomboChange(Sender: TObject);
    procedure JRadioClick(Sender: TObject);
    procedure BackGombClick(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BizRacsKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NaturVisszaGombClick(Sender: TObject);
    procedure BizonylatChanged;
    procedure BParancs(_ukaz: string);
    procedure BizRacsDblClick(Sender: TObject);
    procedure IrodaBeolvasas;
    procedure BlokkVisszaGombClick(Sender: TObject);
    procedure LetiltoGombClick(Sender: TObject);
    procedure JOGILETILTOGOMBClick(Sender: TObject);

    function Arfform(_af: integer): string;
    function Angolra(_huName: string): string;
    function HutoGb(_kod: byte): byte;
    function DoubleKill(_s: string): string;
    function FtForm(_n: integer): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _top,_left,_height,_width,_aktev: word;
  _recno,_evindex: integer;
  _kertnev,_ugyfeltipus,_nevtabla,_biztabla,_pcs,_kezdobetu,_kertevs: string;
  _kertevtizes,_fdbpath,_nevmezo,_kit: string;
  _sorveg: string = chr(13)+chr(10);
  _host: string = '185.43.207.99';
  _penztarnev: array[1..168] of string;

  _wdnem : array[1..6] of string;
  _wBjegy,_warf,_welsz,_wertek: array[1..6] of integer;

  _qTiltva,_aktpenztar: byte;

  _aktPanel: TPanel;
  _aktRacs : TDBGrid;
  _aktSource: TDataSource;

  _qKulfoldi: byte;
  _qNev,_qElozonev,_qLeanykori,_qAnyjaneve,_qSzuletesihely,_qSzuletesiido: string;
  _qAllampolgar,_qLakcim,_qOkmanytipus,_qAzonosito,_qTarthely,_tkernev: string;
  _qLakcimKartya,_qTelephelycim,_qOkiratszam,_qFotevekenyseg,_qMegbizottneve: string;
  _qMegbizottbeosztasa,_qKepviselonev,_qKepvisbeo,_qDatum,_kertdatums: string;
  _qDatasorszam,_xLakcim,_xLcimcard,_xokmtip,_xAzonosito,_xTarthely: string;
  _xAllampolg,_askfile,_sorstring,_wbiz,_wdat,_aktpts,_aktfarok,_bf,_bt: string;
  _aktpenztarnev,_wIdo,_wPros,_wTipus,_tts: string;
  _qtdb,_wFize,_wTetel,_storno,_wKonv,_t,_y: byte;
  _qSumft,_qHetiOssz,_qEvimax,_qSss,_code,_wOssz,_wKezdij: integer;


function letiltorutin: integer; stdcall; external 'c:\uctrl\bin\letilt.dll';
function tiltaskezelorutin: integer; stdcall; external 'c:\uctrl\bin\tiltasok.dll';
function okmanydisplayrutin: integer; stdcall; external 'c:\uctrl\bin\okmdisp.dll';
function keresotiltorutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
               function keresotiltorutin: integer; stdcall;
// =============================================================================

begin
  form2 := TForm2.Create(Nil);
  result := form2.ShowModal;
  form2.free;
end;

// =============================================================================
             procedure TForm2.Button1Click(Sender: TObject);
// =============================================================================

begin
  JogiPanel.Visible := False;
  Modalresult := 1;
end;

// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].width;

  _top := round((_height-595)/2);
  _left := 8+round((_width-1017)/2);

  top    := _top-50;
  left   := _left;
  width  := 1001;
  height := 537;
  color  := clred;

  IrodaBeolvasas;
  evcombotolto;

  Menube;
end;

// =============================================================================
                             procedure Tform2.Menube;
// =============================================================================

begin
  with MenuPanel do
    begin
      top     := 120;
      left    := 336;
      Visible := True;
      repaint;
    end;
  Activecontrol := Keresogomb;
end;

// =============================================================================
                   procedure TForm2.EvcomboTolto;
// =============================================================================

begin
  _aktev := yearof(date);
  Evcombo.Items.clear;
  Evcombo.Items.Add(inttostr(_aktev-2));
  Evcombo.Items.Add(inttostr(_aktev-1));
  Evcombo.Items.Add(inttostr(_aktev));
  Evcombo.ItemIndex := 2;
end;

// =============================================================================
               procedure TForm2.Nevkereses(Sender: TObject);
// =============================================================================

begin

  MenuPanel.Visible := False;
  Nevedit.clear;

  with KeresoPanel do
    begin
      Top := 80;
      Left := 192;
      Visible := True;
      repaint;
    end;

  Activecontrol := Nevedit;

end;

// =============================================================================
       procedure TForm2.NEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _kertnev := trim(nevedit.Text);
  if _kertnev='' then EXIT;

  Setkertev;

  KeresoPanel.Visible := False;

  _kertnev := angolra(_kertnev);

  if Nradio.Checked then
    begin
      _ugyfeltipus := 'N';
      _kezdoBetu   := leftstr(_kertnev,1);
      _nevtabla    := _kezdoBetu + 'NEV';
      _biztabla    := _kezdoBetu + 'BIZ';

      _aktsource   := NaturSource;
      _aktRacs     := Naturracs;
      _aktPanel    := NaturPanel;

      _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
      _pcs := _pcs + 'WHERE NEV LIKE ' + chr(39)+_kertnev+'%'+chr(39)+_SORVEG;
      _pcs := _pcs + 'ORDER BY NEV';

      NDBase.Connected := True;
      with Nquery do
        begin
          Close;
          Sql.clear;
          Sql.Add(_pcs);
          Open;
          _recno := Recno;
        end;

    end else
    begin
      _ugyfeltipus := 'J';
      _nevtabla    := 'JOGI';
      _biztabla    := 'JOGIBIZ';
      _nevmezo     := 'JOGISZEMELYNEV';
      _aktsource   := Jogisource;
      _aktracs     := Jogiracs;
      _aktPanel    := JogiPanel;

      _pcs := 'SELECT * FROM JOGI' + _sorveg;
      _pcs := _pcs+'WHERE JOGISZEMELYNEV LIKE '+chr(39)+_kertnev+'%'+chr(39)+_sorveg;
      _pcs := _pcs+'ORDER BY JOGISZEMELYNEV';

      JDBase.Connected := True;
      with JQuery do
        begin
          Close;
          Sql.clear;
          Sql.Add(_pcs);
          Open;
          _recno := Recno;
        end;
    end;

  if _recno=0 then
    begin
      Nquery.close;
      Ndbase.close;
      Jquery.Close;
      JDbase.close;

      ShowMessage('ILYEN NEVÜ ÜGYFELÜNK NINCS.ADJON MEG MÁSIK NEVET !');
      Nevkereses(nIL);
      exit;
    end;

  _aktsource.Enabled := True;

  if _ugyfeltipus='N' then
    begin
      Evpanel.Caption := _kertevs;
      Kernevedit.Text := _kertnev;
      Evpanel.Repaint;
      Kernevedit.Repaint;
    end else
    begin
      JEvpanel.Caption := _kertevs;
      JKernevedit.Text := _kertnev;
      JEvpanel.Repaint;
      JKernevedit.Repaint;
    end;

  with _Aktpanel do
    begin
      Top  := 52;
      left := 44;
      Visible := true;
      repaint;
    end;
  _aktracs.SetFocus;
end;

// =============================================================================
              procedure TForm2.NEVEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;

// =============================================================================
             procedure TForm2.NEVEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWindow;
end;

// =============================================================================
                           procedure TForm2.Setkertev;
// =============================================================================

begin
  _evindex := evcombo.itemindex;

  _kertevs := Evcombo.items[_evindex];
  _kertevtizes := midstr(_kertevs,3,2);
  _fdbPath := _host + ':C:\receptor\database\ugyfel'+midstr(_kertevs,3,2)+'.FDB';

  BizDbase.close;
  BizDbase.DatabaseName := _fdbPath;

  NDbase.close;
  NDbase.DatabaseName := _fdbPath;

  JDbase.close;
  JDbase.DatabaseName := _fdbPath;
end;

// =============================================================================
                 function TForm2.Angolra(_huName: string): string;
// =============================================================================

var _whn,_z,_asc: byte;

begin
  result  := '';

  _huname := uppercase(trim(_huname));
  _whn    := length(_huname);

  if _whn=0 then exit;

  _z := 1;
  while _z<=_whn do
    begin
      _asc := ord(_huname[_z]);
      _asc := HutoGb(_asc);

      result := result + chr(_asc);
      inc(_z);
    end;
  result := DoubleKill(result);
end;

// =============================================================================
                   function TForm2.DoubleKill(_s: string): string;
// =============================================================================

var _w,_asc,_utasc,_y: byte;

begin
  result := '';

  _s := trim(_s);
  _w := length(_s);

  // Ha üres string -> nincs mit tömöriteni
  if _w=0 then exit;

  _y     := 1;
  _utasc := 0;       // default

  while _y<=_w do
    begin
      _asc := ord(_s[_y]);
      if (_asc=32) and (_utasc=32) then
        begin
          inc(_y);
          continue;
        end;

      if _asc=32 then
        begin
          result := result + ' ';
          _utasc := 32;
          inc(_y);
          Continue;
        end;

      if (_asc<48) or (_asc>90) then
        begin
          inc(_y);
          Continue;
        end;

      if (_asc>57) and (_asc<65) then
        begin
          inc(_y);
          Continue;
        end;

      result := Result + chr(_asc);
      _utasc := _asc;
      inc(_y);
    end;
end;

// =============================================================================
                   function TForm2.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;

// =============================================================================
            procedure TForm2.NATURRACSDblClick(Sender: TObject);
// =============================================================================

begin
   NevetValasztott;
end;

// =============================================================================
      procedure TForm2.NATURRACSKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  NevetValasztott;
end;

// =============================================================================
                    procedure TForm2.NevetValasztott;
// =============================================================================

begin
  AllAdatbeolvasas;
  AllDisplay;
end;

// =============================================================================
                       procedure TForm2.AllDisplay;
// =============================================================================

begin
  if _qtiltva=1 then
    begin
      with TiltottPanel do
        begin
          top := 88;
          left := 120;
          visible := true;
          Bringtofront;
          repaint;
        end;
    end else Tiltottpanel.Visible := False;


  if _ugyfeltipus='N' then
    begin
      UgyNevEdit.text      := _qNev;
      ElonevEdit.text      := _qElozonev;
      LeanyEdit.text       := _qLeanykori;
      AnyjaEdit.text       := _qAnyjaneve;
      Szulhelyedit.text    := _qSzuletesihely;
      SzulidoEdit.text     := _qSzuletesiido;
      AllampolgarEdit.text := _qAllampolgar;
      LakcimEdit.text      := _qLakcim;
      OkmTipEdit.text      := _qOkmanytipus;
      AzonositoEdit.text   := _qAzonosito;
      TartHelyEdit.text    := _qTarthely;
      LcimcardEdit.text    := _qLakcimkartya;

      if _qKulfoldi=1 then Statuszedit.text := 'KÜLFÖLDI'
      else Statuszedit.text := 'BELFÖLDI';
      with NaturDataPanel do
        begin
          left := 22;
          top  := 16;
          Visible := True;
          repaint;
        end;

      JogiDataPanel.visible := False;
    end else
    begin
      Joginevedit.text    := _qNev;
      TelephelyEdit.text  := _qTelephelycim;
      Okiratedit.text     := _qOkiratszam;
      FotevekenyEdit.text := _qFotevekenyseg;
      MbNevedit.text      := _qMegbizottneve;
      MbBeoEdit.text      := _qMegbizottBeosztasa;
      Kepvisnevedit.text  := _qKepviselonev;
      Kepvisbeoedit.text  := _qKepvisbeo;

      if _qKulfoldi=1 then jStatuszedit.text := 'KÜLFÖLDI'
      else JStatuszedit.text := 'BELFÖLDI';

      with JogiDataPanel do
        begin
          top  := 8;
          left := 8;
          Visible := True;
          repaint;
        end;
    end;

  // ---------------------------------------------------------------------------

  TDBPanel.caption    := inttostr(_qTDB)+' darab';
  EvimaxPanel.caption := Ftform(_qEviMax)+' Ft';
  EvisumPanel.caption := FtForm(_qSumFT)+' Ft';

  qDatumPanel.caption    := _qDatum;
  LastTranzPanel.caption := ftform(_qHetiossz)+' Ft';

  // -----------------------------------------------------------------------

  _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_qsss) + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  Bizdbase.connected := tRUE;
  with BizQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  xDatabe;
  Bizsource.enabled := True;
  // -----------------------------------------------------------------------

  with InformacioPanel do
    begin
      Top     := 30;
      Left    := 8;
      Visible := True;
      repaint;
    end;

  Bizracs.setfocus;
end;

// =============================================================================
                     procedure TForm2.AllAdatbeolvasas;
// =============================================================================

begin

  if _ugyfeltipus='N' then
    begin
      with NQuery do
        begin
          _qSSS           := FieldByNAme('SORSZAM').asINteger;
          _qNev           := trim(FieldByNAme('NEV').asString);
          _qElozonev      := trim(FieldByNAme('ELOZONEV').asString);
          _qAnyjaneve     := trim(FieldByNAme('ANYJANEVE').asString);
          _qLeanykori     := trim(FieldByNAme('LEANYKORI').asString);
          _qSzuletesihely := trim(FieldByNAme('SZULETESIHELY').asString);
          _qSzuletesiido  := fieldbyname('SZULETESIIDO').asString;
          _qAllamPolgar   := trim(FieldByNAme('ALLAMPOLGAR').asString);
          _qLakcim        := trim(FieldByNAme('LAKCIM').asString);
          _qOkmanytipus   := trim(FieldByNAme('OKMANYTIP').asString);
          _qAzonosito     := trim(FieldByNAme('AZONOSITO').asString);
          _qtarthely      := trim(FieldByNAme('TARTOZKODASIHELY').asString);
          _qLakcimkartya  := trim(FieldByNAme('LAKCIMKARTYA').asString);
          _qKulfoldi      := fieldbyname('KULFOLDI').asInteger;
          _qSumft         := FieldByNAme('FORINTOSSZEG').asInteger;
          _qTDB           := FieldByName('TRANZAKCIODB').asInteger;
          _qDatum         := FieldByName('DATUM').asString;
          _qEvimax        := FieldByName('EVIMAX').asInteger;
          _qhetiossz      := FieldByName('HETIOSSZ').asInteger;
          _qTiltva        := FieldByNAme('TILTVA').asInteger;
        end;
    end else
    begin
      with Jquery do
        begin
          _qSSS                := FieldByNAme('SORSZAM').asINteger;
          _qNev                := trim(FieldByName('JOGISZEMELYNEV').asString);
          _qTelephelycim       := trim(FieldByNAme('TELEPHELYCIM').asString);
          _qOkiratszam         := trim(FieldByName('OKIRATSZAM').asString);
          _qFotevekenyseg      := trim(FieldByNAme('FOTEVEKENYSEG').asString);
          _qMegbizottneve      := trim(FieldByNAme('MEGBIZOTTNEVE').asString);
          _qKepviselonev       := trim(FieldByNAme('KEPVISELONEV').asString);
          _qMegbizottbeosztasa := trim(FieldByNAme('MEGBIZOTTBEOSZTASA').asString);
          _qKepvisbeo          := trim(FieldByNAme('KEPVISBEO').asString);
          _qDatasorszam        := trim(FieldByNAme('MBDATASORSZAM').AsString);
          _qSumft              := FieldByNAme('FORINTOSSZEG').asInteger;
          _qTDB                := FieldByName('TRANZAKCIODB').asInteger;
          _qDatum              := FieldByName('DATUM').asString;
          _qEvimax             := FieldByName('EVIMAX').asInteger;
          _qhetiossz           := FieldByName('HETIOSSZ').asInteger;
          _qTiltva             := FieldByNAme('TILTVA').asInteger;
        end;
    end;
end;

// =============================================================================
                function TForm2.FtForm(_n: integer): string;
// =============================================================================

var _wn,_f1: byte;

begin
  result := '';
  if  _n=0 then exit;

  result := inttostr(_n);
  if _n<1000 then exit;

  _wn := length(result);
  if _wn>6 then
    begin
      _f1 := _wn-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;

  _f1 := _wn-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;

// =============================================================================
                   procedure Tform2.xdatabe;
// =============================================================================

begin
  with Bizquery do
    begin
      _xLakcim := trim(FieldByNAme('LAKCIM').asString);
      _xLcimcard := trim(FieldByName('LAKCIMKARTYA').asString);
      _xokmtip := trim(FieldByName('OKMANYTIP').asString);
      _xAzonosito := trim(FieldByNAme('AZONOSITO').asString);
      _xTartHely := trim(FieldByNAme('TARTOZKODASIHELY').asString);
      _xAllampolg := trim(FieldByName('ALLAMPOLGAR').asString);
    end;
end;

// =============================================================================
             procedure TForm2.evcomboChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := Nevedit;
end;

// =============================================================================
              procedure TForm2.JRADIOClick(Sender: TObject);
// =============================================================================

begin
  Activecontrol := Nevedit;
end;

// =============================================================================
             procedure TForm2.BACKGOMBClick(Sender: TObject);
// =============================================================================

begin
  BizQuery.close;
  Bizdbase.close;
  scanAskPanel.Visible := False;
  InformacioPanel.Visible := False;
end;

// =============================================================================
              procedure TForm2.SCANGOMBClick(Sender: TObject);
// =============================================================================

var _ww: byte;

begin
  IF _ugyfeltipus='N' then _askfile := _nevtabla+inttostr(_qsss)
  else
  begin
    _askFile := _qDatasorszam;
    _ww := length(_qDataSorszam);
    _sorstring := midstr(_qDatasorszam,5,_ww-4);
    val(_sorstring,_qsss,_code);
    if _code<>0 then _qsss := 0;
  end;

  _KIT := '.A' + midstr(_qDatum,3,2);
  _askfile := _askfile + _kit;

  _pcs := 'UPDATE VTEMP SET NEV='+chr(39)+_qNev+chr(39);
  _pcs := _pcs + ',CIM=' + chr(39) + _qLakcim + chr(39);
  _pcs := _pcs + ',DATUM=' + chr(39) + _qDatum + chr(39);
  _pcs := _pcs + ',ASKFILE=' + chr(39) + _askfile + chr(39);

  Bizlatokdbase.Connected := true;
  if bizlatoktranz.InTransaction then Bizlatoktranz.commit;
  Bizlatoktranz.StartTransaction;
  with BizlatokQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  Bizlatoktranz.Commit;
  Bizlatokdbase.close;

  okmanydisplayrutin;
  ShowMessage('A kért okmányokat a C:\UCTRL\DATA könyvtárba másoltam');
end;


// =============================================================================
                procedure TForm2.BitBtn3Click(Sender: TObject);
// =============================================================================

begin
  KeresoPanel.Visible := False;
  Menube;
end;


// =============================================================================
               procedure TForm2.NATURVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Naturpanel.Visible := False;
  Menube;
end;


// =============================================================================
          procedure TForm2.BIZRACSCellClick(Column: TColumn);
// =============================================================================

begin
  Bizonylatchanged;
end;

// =============================================================================
        procedure TForm2.BIZRACSKeyUp(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

begin
  BizonylatChanged;
end;

// =============================================================================
                   procedure TForm2.BizonylatChanged;
// =============================================================================

begin
  Xdatabe;
  if _xLakcim<>'' then LakcimEdit.Text := _xLakcim;
  if _xLcimCard<>'' then LcimCardEdit.text := _xLcimCard;
  if _xOkmTip<>'' then OkmtipEdit.text := _xOkmTip;
  if _xAzonosito<>'' then Azonositoedit.Text := _xAzonosito;
  if _xTarthely<>'' then TarthelyEdit.Text := _xTartHely;
  if _xAllampolg<>'' then Allampolgaredit.Text := _xAllampolg;
  Naturdatapanel.repaint;
end;

// =============================================================================
              procedure TForm2.BizRacsDblClick(Sender: TObject);
// =============================================================================

begin
  /// 'itt kell a bizonylatot kijelezni'
  with BizQuery do
    begin
      _wbiz := FieldByNAme('BIZONYLATSZAM').asString;
      _wdat := FieldByNAme('DATUM').asString;
    end;

  _aktpts := midstr(_wbiz,2,3);
  _aktfarok := midstr(_wdat,3,2)+midstr(_wdat,6,2);

  _bf := 'BF' + _aktfarok;
  _bt := 'BT' + _aktfarok;

  val(_aktpts,_aktpenztar,_code);
  _aktpenztarnev := _penztarnev[_aktPenztar];
  if _aktpenztar<151 then
    _fdbpath := _host + ':C:\receptor\database\v'+inttostr(_aktpenztar)+'.FDB'
  else
    _fdbpath := _host + ':C:\cartcash\database\v'+inttostr(_aktpenztar)+'.FDB';

  RemoteDbase.close;
  RemoteDbase.Databasename := _fdbpath;

  _pcs := 'SELECT * FROM ' + _BF + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_wbiz+chr(39);

  RemoteDbase.connected := true;
  with RemoteQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _WDAT := FieldByNAme('DATUM').asString;
      _wIdo := fieldByNAme('IDO').asString;
      _wOssz:= FieldByNAme('OSSZESEN').asinteger;
      _wFize:= FieldByNAme('FIZETOESZKOZ').asInteger;
      _wTetel:= FieldByName('TETEL').asInteger;
      _wPros := trim(FieldByNAme('PENZTAROSNEV').asString);
      _wKezdij:= FieldByNAme('KEZELESIDIJ').asInteger;
      _wKonv := FieldByNAme('KONVERZIO').asInteger;
      _storno := FieldByNAme('STORNO').asInteger;
      CLose;
    end;

  _wTipus := leftstr(_wbiz,1);

  _pcs := 'SELECT * FROM ' + _BT + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_wbiz+chr(39);

  with RemoteQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _t := 0;
  while not RemoteQuery.eof do
    begin
      inc(_t);
      with RemoteQuery do
        begin
          _wdnem[_t]  := FieldByNAme('VALUTANEM').asString;
          _wBjegy[_t] := FieldByNAme('BANKJEGY').asInteger;
          _wArf[_t]   := FieldByNAme('ARFOLYAM').asInteger;
          _welsz[_t]  := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
          _wertek[_t] := FieldByNAme('FORINTERTEK').asInteger;
          Next;
        end;
    end;
  RemoteDbase.close;

  _wtetel := _t;

  // ---------------------------------------------------------------------------

  _tts := '';
  if _wKonv=1 then _tts := 'KONVERZIÓS ';
  if _wTipus='V' then _tts := _tts +'VALUTA VÉTEL'
  else _tts := _tts + 'VALUTA ELADÁS';

  TTPanel.caption    := _tts;
  wBizPanel.Caption := _wBiz;

  IF _wFize=1 then FizeszkozPanel.caption := 'KÉSZPÉNZES'
  else FizeszkozPanel.Caption := 'BANKKÁRTYÁS';

  PtPanel.caption        := inttostr(_aktpenztar)+'  '+_aktpenztarnev;
  ProsPanel.caption      := _wPros;
  wDatIdo.caption        := _wDat + '  '+_wido;
  KezdijPanel.Caption    := FtForm(_wKezdij)+' Ft';
  Fizetendopanel.caption := ftform(_wOssz)+' Ft';

  _y := 1;
  while _y<=_wTetel do
    begin
      if _y=1 then
        begin
          v1.caption := ftform(_wbjegy[_y])+'  '+_wDnem[_y];
          a1.caption := arfform(_wArf[_y]);
          e1.caption := arfform(_welsz[_y]);
          f1.caption := ftform(_wErtek[_y])+' Ft';
        end;

      if _y=2 then
        begin
          v2.caption := ftform(_wbjegy[_y])+'  '+_wDnem[_y];
          a2.caption := arfform(_wArf[_y]);
          e2.caption := arfform(_welsz[_y]);
          f2.caption := ftform(_wErtek[_y])+' Ft';
        end;

      if _y=3 then
        begin
          v3.caption := ftform(_wbjegy[_y])+'  '+_wDnem[_y];
          a3.caption := arfform(_wArf[_y]);
          e3.caption := arfform(_welsz[_y]);
          f3.caption := ftform(_wErtek[_y])+' Ft';
        end;

      if _y=4 then
        begin
          v4.caption := ftform(_wbjegy[_y])+'  '+_wDnem[_y];
          a4.caption := arfform(_wArf[_y]);
          e4.caption := arfform(_welsz[_y]);
          f4.caption := ftform(_wErtek[_y])+' Ft';
        end;

      if _y=5 then
        begin
          v5.caption := ftform(_wbjegy[_y])+'  '+_wDnem[_y];
          a5.caption := arfform(_wArf[_y]);
          e5.caption := arfform(_welsz[_y]);
          f5.caption := ftform(_wErtek[_y])+' Ft';
        end;

      if _y=6 then
        begin
          v6.caption := ftform(_wbjegy[_y])+'  '+_wDnem[_y];
          a6.caption := arfform(_wArf[_y]);
          e6.caption := arfform(_welsz[_y]);
          f6.caption := ftform(_wErtek[_y])+' Ft';
        end;
      inc(_y);
    end;

  BackGomb.Enabled := False;
  with Blokkpanel do
    begin
      Left    := 230;
      Top     := 30;
      Visible := True;
      Repaint;
    end;

end;

// =============================================================================
                   procedure TForm2.Irodabeolvasas;
// =============================================================================

var _uzlet: byte;
    _pn: string;

begin
  _fdbPath := _host + ':c:\receptor\database\receptor.fdb';

  RemoteDbase.close;
  RemoteDbase.databasename := _fdbpath;
  RemoteDbase.connected := true;

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IRODAK');
      Open;
    end;

  while not RemoteQuery.eof do
    begin
      _uzlet := RemoteQuery.fieldByNAme('UZLET').asInteger;
      _pn    := trim(RemoteQuery.fieldByNAme('KESZLETNEV').asString);
      _penztarnev[_uzlet] := _pn;
      RemoteQuery.next;
    end;
  remoteQuery.close;
  remoteDbase.close;

  // -------------------------------------

  _fdbPath := _host + ':c:\cartcash\database\artcash.fdb';

  RemoteDbase.close;
  RemoteDbase.databasename := _fdbpath;
  RemoteDbase.connected := true;

  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM IRODAK');
      Open;
    end;

  while not RemoteQuery.eof do
    begin
      _uzlet := RemoteQuery.fieldByNAme('UZLET').asInteger;
      _pn    := trim(RemoteQuery.fieldByNAme('KESZLETNEV').asString);
      _penztarnev[_uzlet] := _pn;
      RemoteQuery.next;
    end;
  remoteQuery.close;
  remoteDbase.close;
end;


// =============================================================================
                 function TForm2.Arfform(_af: integer): string;
// =============================================================================

var _afs: string;
    _f1: byte;

begin
  result := '';
  if _af=0 then exit;

  _afs := inttostr(_af);
  _f1 := length(_afs)-2;
  result := leftstr(_afs,_f1)+','+midstr(_afs,_f1+1,2);
end;

// =============================================================================
           procedure TForm2.BLOKKVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  BackGomb.Enabled := true;
  BlokkPanel.Visible := False;
end;



// =============================================================================
                procedure TForm2.LetiltoGombClick(Sender: TObject);
// =============================================================================


begin
  tiltaskezelorutin;

  {
  _pcs := 'DELETE FROM VTEMP';
  Bparancs(_pcs);
  _pcs := 'INSERT INTO VTEMP (PTTIPUS)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + 'N' + chr(39)+')';
  Bparancs(_pcs);
  letiltorutin;
  }

  Menube;
end;


// =============================================================================
          procedure TForm2.JOGILETILTOGOMBClick(Sender: TObject);
// =============================================================================


begin
  _pcs := 'DELETE FROM VTEMP';
  Bparancs(_pcs);
  _pcs := 'INSERT INTO VTEMP (PTTIPUS)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + 'J' + chr(39)+ ')';
  Bparancs(_pcs);
  letiltorutin;
  Menube;
end;

procedure TForm2.BParancs(_ukaz: string);
begin
  bizlatokdbase.connected := true;
  if bizlatokTranz.InTransaction then Bizlatoktranz.commit;
  Bizlatoktranz.StartTransaction;
  with Bizlatokquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  BizlatokTranz.commit;
  Bizlatokdbase.close;
end;
end.
