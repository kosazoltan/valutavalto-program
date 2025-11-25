unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBQuery, IBCustomDataSet,
  IBTable, DateUtils, ExtCtrls, Grids, DBGrids, StrUtils, jpeg, wininet;

type
  TForm1 = class(TForm)
    NTABLA: TIBTable;
    NQUERY: TIBQuery;
    NDBASE: TIBDatabase;
    NTRANZ: TIBTransaction;
    NATURSOURCE: TDataSource;
    NATURPANEL: TPanel;
    NATURRACS: TDBGrid;
    Label2: TLabel;
    JOGIPANEL: TPanel;
    JOGISOURCE: TDataSource;
    jogiracs: TDBGrid;
    Shape1: TShape;
    Panel1: TPanel;
    Panel2: TPanel;
    MENUPANEL: TPanel;
    KERESOGOMB: TPanel;
    KILEPOGOMB: TPanel;
    Label3: TLabel;
    Shape2: TShape;
    KERESOPANEL: TPanel;
    Label4: TLabel;
    Label5: TLabel;
    EVCOMBO: TComboBox;
    Label6: TLabel;
    NEVEDIT: TEdit;
    Shape3: TShape;
    Panel3: TPanel;
    Image1: TImage;
    Image2: TImage;
    Label7: TLabel;
    NRADIO: TRadioButton;
    JRADIO: TRadioButton;
    EVPANEL: TPanel;
    TIPUSPANEL: TPanel;
    Panel6: TPanel;
    Label1: TLabel;
    KERNEVEDIT: TEdit;
    MENUBEGOMB: TBitBtn;
    INFORMACIOPANEL: TPanel;
    NATURDATAPANEL: TPanel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    TARTHELYEDIT: TEdit;
    UGYNEVEDIT: TEdit;
    ELONEVEDIT: TEdit;
    LEANYEDIT: TEdit;
    ANYJAEDIT: TEdit;
    SZULHELYEDIT: TEdit;
    SZULIDOEDIT: TEdit;
    ALLAMPOLGAREDIT: TEdit;
    LAKCIMEDIT: TEdit;
    OKMTIPEDIT: TEdit;
    AZONOSITOEDIT: TEdit;
    LCIMCARDEDIT: TEdit;
    STATUSZEDIT: TEdit;
    TRANZPANEL: TPanel;
    Shape4: TShape;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    LASTTRANZPANEL: TPanel;
    TDBPANEL: TPanel;
    EVIMAXPANEL: TPanel;
    EVISUMPANEL: TPanel;
    Label27: TLabel;
    Shape5: TShape;
    BIZPANEL: TPanel;
    BIZRACS: TDBGrid;
    bizsource: TDataSource;
    BIZQUERY: TIBQuery;
    BIZDBASE: TIBDatabase;
    BIZTRANZ: TIBTransaction;
    BIZQUERYSORSZAM: TIntegerField;
    BIZQUERYBIZONYLATSZAM: TIBStringField;
    BIZQUERYFIZETENDO: TIntegerField;
    BIZQUERYDATUM: TIBStringField;
    Label28: TLabel;
    Shape6: TShape;
    qdatumpanel: TPanel;
    Panel4: TPanel;
    Label29: TLabel;
    JOGIDATAPANEL: TPanel;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    Label36: TLabel;
    Label37: TLabel;
    Label38: TLabel;
    JOGINEVEDIT: TEdit;
    TELEPHELYEDIT: TEdit;
    OKIRATEDIT: TEdit;
    FOTEVEKENYEDIT: TEdit;
    MBNEVEDIT: TEdit;
    MBBEOEDIT: TEdit;
    KEPVISNEVEDIT: TEdit;
    KEPVISBEOEDIT: TEdit;
    Panel5: TPanel;
    Label39: TLabel;
    JSTATUSZEDIT: TEdit;
    JEVPANEL: TPanel;
    Panel7: TPanel;
    JKERNEVEDIT: TEdit;
    Panel8: TPanel;
    JMENUBEGOMB: TBitBtn;
    JTABLA: TIBTable;
    JQUERY: TIBQuery;
    JDBASE: TIBDatabase;
    JTRANZ: TIBTransaction;
    BLOKKPANEL: TPanel;
    Label26: TLabel;
    WBIZPANEL: TPanel;
    Label40: TLabel;
    WDATIDO: TPanel;
    TPANEL: TPanel;
    ptpanel: TPanel;
    Label41: TLabel;
    kezdijpanel: TPanel;
    PROSPANEL: TPanel;
    Label42: TLabel;
    FIZETENDOPANEL: TPanel;
    Panel17: TPanel;
    V1: TPanel;
    V2: TPanel;
    V3: TPanel;
    V4: TPanel;
    V5: TPanel;
    V6: TPanel;
    A1: TPanel;
    E1: TPanel;
    F1: TPanel;
    Label43: TLabel;
    Label44: TLabel;
    Label45: TLabel;
    Label46: TLabel;
    Panel27: TPanel;
    Panel28: TPanel;
    Panel29: TPanel;
    A2: TPanel;
    A3: TPanel;
    A4: TPanel;
    A6: TPanel;
    A5: TPanel;
    E2: TPanel;
    E3: TPanel;
    E4: TPanel;
    E5: TPanel;
    E6: TPanel;
    F2: TPanel;
    F3: TPanel;
    F4: TPanel;
    F5: TPanel;
    F6: TPanel;
    Shape7: TShape;
    BLOKKQUERY: TIBQuery;
    BLOKKDBASE: TIBDatabase;
    BLOKKTRANZ: TIBTransaction;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    ARTQUERY: TIBQuery;
    ARTDBASE: TIBDatabase;
    ARTTRANZ: TIBTransaction;
    BLOKKVISSZAGOMB: TBitBtn;
    Label47: TLabel;
    fizeszkozpanel: TPanel;
    Label48: TLabel;
    TILTOTTPANEL: TPanel;
    Label49: TLabel;
    Label50: TLabel;
    LETILTOPANEL: TPanel;
    Label51: TLabel;
    Label52: TLabel;
    TNEVEDIT: TEdit;
    TILTORACS: TDBGrid;
    Label54: TLabel;
    KEZIGOMB: TBitBtn;
    TBACKGOMB: TBitBtn;
    Label53: TLabel;
    TYEARCOMBO: TComboBox;
    KEZIADATPANEL: TPanel;
    Label55: TLabel;
    Label56: TLabel;
    Label57: TLabel;
    Label58: TLabel;
    Label59: TLabel;
    Label60: TLabel;
    TILTNEVEDIT: TEdit;
    TSZULIDOEDIT: TEdit;
    TANYJAEDIT: TEdit;
    TSZULHELYEDIT: TEdit;
    TGOMB: TBitBtn;
    TMEGEMGOMB: TBitBtn;
    TILTOSOURCE: TDataSource;
    TTPANEL: TPanel;
    Label61: TLabel;
    Label63: TLabel;
    Label64: TLabel;
    Label65: TLabel;
    Label66: TLabel;
    Label67: TLabel;
    tnedit: TEdit;
    taedit: TEdit;
    TIEDIT: TEdit;
    THEDIT: TEdit;
    TLEDIT: TEdit;
    UTILTOGOMB: TBitBtn;
    TVISSZAGOMB: TBitBtn;
    FIGYELEMPANEL: TPanel;
    Label62: TLabel;
    Label68: TLabel;
    Label69: TLabel;
    Label70: TLabel;
    IGENGOMB: TBitBtn;
    nemgomb: TBitBtn;
    FOMENUPANEL: TPanel;
    Label71: TLabel;
    IDOSZAKKERESOGOMB: TBitBtn;
    UGYFELKERESOGOMB: TBitBtn;
    EXITGOMB: TBitBtn;
    Shape8: TShape;
    kertdatumpanel: TPanel;
    Label75: TLabel;
    KERTDATUMSPANEL: TPanel;
    RADIOPANEL: TPanel;
    KFTRADIO: TRadioButton;
    KORZETRADIO: TRadioButton;
    PENZTARRADIO: TRadioButton;
    Shape10: TShape;
    PENZTARCOMBO: TComboBox;
    ptmegsemgomb: TBitBtn;
    PTOKEGOMB: TBitBtn;
    RACSPANEL: TPanel;
    FEJRACS: TDBGrid;
    TETELRACS: TDBGrid;
    FEJSOURCE: TDataSource;
    TETELSOURCE: TDataSource;
    FEJQUERY: TIBQuery;
    FEJDBASE: TIBDatabase;
    FEJTRANZ: TIBTransaction;
    TETELQUERY: TIBQuery;
    TETELDBASE: TIBDatabase;
    TETELTRANZ: TIBTransaction;
    FEJQUERYBIZONYLAT: TIBStringField;
    FEJQUERYDATUM: TIBStringField;
    FEJQUERYIDO: TIBStringField;
    FEJQUERYTETEL: TSmallintField;
    FEJQUERYFIZETENDO: TIntegerField;
    FEJQUERYKEZELESIDIJ: TIntegerField;
    FEJQUERYSORSZAM: TIntegerField;
    FEJQUERYPENZTAR: TSmallintField;
    FEJQUERYPROSID: TIBStringField;
    FEJQUERYNEVTABLA: TIBStringField;
    TETELQUERYBIZONYLAT: TIBStringField;
    TETELQUERYVALUTANEM: TIBStringField;
    TETELQUERYBANKJEGY: TIntegerField;
    TETELQUERYARFOLYAM: TIntegerField;
    TETELQUERYELSZAM: TIntegerField;
    TETELQUERYERTEK: TIntegerField;
    Panel10: TPanel;
    NATUGYFELPANEL: TPanel;
    ptarpanel: TPanel;
    Label72: TLabel;
    NATNEVPANEL: TPanel;
    NATANYJAPANEL: TPanel;
    SZULPANEL: TPanel;
    Label73: TLabel;
    Label74: TLabel;
    Label76: TLabel;
    PENZPANEL: TPanel;
    EVIOSSZPANEL: TPanel;
    MAXPANEL: TPanel;
    LASTDATEPANEL: TPanel;
    Label77: TLabel;
    Label78: TLabel;
    Label79: TLabel;
    TRDBPANEL: TPanel;
    AKTPTPANEL: TPanel;
    AKTPROSPANEL: TPanel;
    Label80: TLabel;
    Label81: TLabel;
    PROSQUERY: TIBQuery;
    PROSDBASE: TIBDatabase;
    PROSTRANZ: TIBTransaction;
    NEVQUERY: TIBQuery;
    NEVDBASE: TIBDatabase;
    NEVTRANZ: TIBTransaction;
    JOGIUGYFELPANEL: TPanel;
    JOGNEVPANEL: TPanel;
    JOGHELYPANEL: TPanel;
    OKIRPANEL: TPanel;
    Label82: TLabel;
    Label83: TLabel;
    Label84: TLabel;
    Label85: TLabel;
    tobbgomb: TPanel;
    FOTEVPANEL: TPanel;
    MBNEVPANEL: TPanel;
    MBBEOPANEL: TPanel;
    KVBEOPANEL: TPanel;
    KEPVISPANEL: TPanel;
    FELGOMB: TPanel;
    Label86: TLabel;
    Label87: TLabel;
    Label88: TLabel;
    Label89: TLabel;
    Label90: TLabel;
    KFTPANEL: TPanel;
    RBEST: TRadioButton;
    REAST: TRadioButton;
    RPANNON: TRadioButton;
    REXPRESSZ: TRadioButton;
    RALL: TRadioButton;
    Shape11: TShape;
    KFTOKEGOMB: TBitBtn;
    AKTKFTPANEL: TPanel;
    Shape12: TShape;
    CNEVPANEL: TPanel;
    KORZETCOMBO: TComboBox;
    KORZETOKEGOMB: TBitBtn;
    FOCIMPANEL: TPanel;
    DATUMLIMITPANEL: TPanel;
    AKTPTNEVPANEL: TPanel;
    Panel14: TPanel;
    LIMPANEL: TPanel;
    HIDEDIT: TEdit;
    Label91: TLabel;
    CSAKJOGI: TCheckBox;
    FOMENUREGOMB: TPanel;
    BACKGOMB: TPanel;
    SCANASKPANEL: TPanel;
    Label92: TLabel;
    scannevpanel: TPanel;
    Label93: TLabel;
    SCANUZENOPANEL: TPanel;
    IMPORTGOMB: TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure IdBeolvasas;
    procedure Menube;
    procedure SetKertev;
    procedure TiltotValasztott;

    function Nul3(_b: byte): string;
    function Angolra(_huName: string): string;
    procedure TetelDisplay;
    function HutoGb(_kod: byte): byte;
    function DoubleKill(_s: string): string;
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure KERESOGOMBClick(Sender: TObject);
    procedure NEVEDITEnter(Sender: TObject);
    procedure NEVEDITExit(Sender: TObject);
    procedure IrodaBeolvasas;
    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MENUBEGOMBClick(Sender: TObject);
    procedure NATURRACSDblClick(Sender: TObject);
    procedure NATURRACSKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NevetValasztott;
    procedure AllAdatBeolvasas;
    procedure Alldisplay;
    function FtForm(_n: integer): string;
    procedure BACKGOMBClick(Sender: TObject);
    procedure NRADIOClick(Sender: TObject);
    procedure JMENUBEGOMBClick(Sender: TObject);
    procedure Nevkereses;
    procedure BIZRACSDblClick(Sender: TObject);
    procedure FoMenube;
    procedure RacsDisplay;
    procedure AskFileDelete;

    function Arfform(_af: integer): string;
    procedure TombbeTolt;
    procedure BLOKKVISSZAGOMBClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
    procedure LETILTOGOMBClick(Sender: TObject);
    procedure NaturParancs(_ukaz: string);
    procedure Fejkiolvasas;
    procedure BizonylatValtas;
    procedure TILTNEVEDITEnter(Sender: TObject);
    procedure TILTNEVEDITExit(Sender: TObject);
    procedure TILTNEVEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KEZIGOMBClick(Sender: TObject);
    procedure TGOMBClick(Sender: TObject);
    function Tomorito(_ts: string): string;
    procedure TBACKGOMBClick(Sender: TObject);
    procedure TYEARCOMBOClick(Sender: TObject);
    procedure TNEVEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TILTORACSDblClick(Sender: TObject);
    procedure TILTORACSKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure nemgombClick(Sender: TObject);
    procedure TTMBClick(Sender: TObject);
    procedure IGENGOMBClick(Sender: TObject);
    procedure TMEGEMGOMBClick(Sender: TObject);
    function Scanid(_id: string): string;

    procedure EXITGOMBClick(Sender: TObject);
    procedure UGYFELKERESOGOMBClick(Sender: TObject);
    procedure IDOSZAKKERESOGOMBClick(Sender: TObject);
    procedure FocimDisplay;

    procedure PENZTARRADIOClick(Sender: TObject);
    procedure PENZTARCOMBOChange(Sender: TObject);
    procedure ptmegsemgombClick(Sender: TObject);
    procedure PMBClick(Sender: TObject);
    procedure FEJRACSKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FEJRACSCellClick(Column: TColumn);
    procedure FEJRACSDblClick(Sender: TObject);
    procedure FOMENUREGOMBClick(Sender: TObject);

    procedure FELGOMBClick(Sender: TObject);
    procedure tobbgombClick(Sender: TObject);
    procedure KFTRADIOClick(Sender: TObject);
    procedure KFTOKEGOMBClick(Sender: TObject);
    procedure KORZETRADIOClick(Sender: TObject);
    procedure KORZETCOMBOChange(Sender: TObject);
    procedure KORZETOKEGOMBClick(Sender: TObject);
    procedure LIMPANELClick(Sender: TObject);
    procedure HIDEDITKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RBESTClick(Sender: TObject);
    procedure CSAKJOGIClick(Sender: TObject);
    procedure EXCELGOMBClick(Sender: TObject);
    procedure ScanGombClick(Sender: TObject);

    function FtpOpen(_remdir: string): boolean;
    function Beolvasas: boolean;
    function Kikuldes(_lpath,_rFile: string): boolean;
    procedure IMPORTGOMBClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _v,_a,_e,_f: array[1..6] of TPanel;
  _wdnem: array[1..6] of string;

  _honev      : array[1..12] of string = ('január','február','március',
                             'április','május','junius',
         'július','augusztus','szeptember','október','november','december');

  _kftnev: array[1..4] of string = ('Exclusive Best Change Kft','Exclusive East Change Kft',
                     'Exclusive Pannon Change Kft','Expressz Ékszerház Kft');

  _korzet: array[1..180] of byte;
  _cegbetu: array[1..180] of string;

  _korzetek: array[0..7] of byte = (10,20,40,50,63,75,120,145);
  _korzetnevek: array[0..7] of string = ('Szekszárd','Szeged','Kecskemét',
         'Debrecen','Nyíregyháza','Békéscsaba','Pécs','Kaposvár');

  _kftnum: array[1..180] of byte;
  _ptarcim: array[1..180] of string;

  _wBjegy,_wArf,_welsz,_wErtek: array[1..6] of integer;
  _TEdit: array[1..4] of TEdit;

  _prosid,_prsnev: array[1..800] of string;

  _vanLimit,_alatt,_felett: boolean;

  _qTiltva,_aktpenztar,_wtetel,_wKonv,_storno,_wFize,_t,_wtet,_tiltva,_k: byte;
  _aktev,_y,_curryear,_aktho,_havinapok,_kertev,_kertho,_tolnap,_ignap,_trdb: word;
  _idDarab: word;

  _aktkorzet,_ertektar: byte;

  _evindex,_hoIndex,_tolindex,_igIndex,_recno,_code,_sss,_ttsss: integer;
  _forintosszeg,_evimax,_limit,_cc: integer;

  _fdbPath,_kertevs,_kertnev,_kezdobetu,_nevtabla,_nevmezo,_pcs,_ignaps: string;
  _ugyfeltipus,_biztabla,_wido,_wpros,_wTipus,_tts,_aktpenztarnev,_last: string;
  _tiltnev,_tiltanyja,_tiltszulido,_tiltszulhely,_lastvari,_aktevs: string;
  _aktjoginev,_aktTelephely,_aktOkirat,_aktTevekeny,_aktMbNeve,_uzcim: string;
  _aktmbBeo,_aktkepvisnev,_aktkepvisbeo,_aktceg,_aktkorzetnev,_limits: string;

  _qNev,_qElozonev,_qLeanykori,_qAnyjaneve,_qSzuletesihely,_qSzuletesiido: string;
  _qAllampolgar,_qLakcim,_qOkmanytipus,_qAzonosito,_qTarthely,_tkernev: string;
  _qLakcimKartya,_qTelephelycim,_qOkiratszam,_qFotevekenyseg,_qMegbizottneve: string;
  _qMegbizottbeosztasa,_qKepviselonev,_qKepvisbeo,_qDatum,_kertdatums: string;
  _wBiz,_wdat,_aktpts,_aktfarok,_bf,_bt,_blokkfdb,_pttipus,_akttabla: string;
  _toldatums,_igdatums,_aktcegbetu,_cb,_aktbizonylat,_aktProsid,_aktprosnev: string;
  _aktptnev,_aktnev,_aktanyja,_szulido,_szulhely,_csoptipus: string;

  _qTDB,_qKulfoldi,_qSumFt,_qHetiossz,_qsss,_qEvimax,_wossz,_wKezdij,_ok: integer;
  _aktsorszam: integer;

  _penztarnev: array[1..180] of string;

  _sorveg: string = chr(13)+chr(10);

  _aktsource : TDataSource;
  _aktPanel  : TPanel;
  _aktRacs   : TDBGrid;
  _toltes    : boolean;

    _hNet,_hFTP,_hSearch: HINTERNET;
  _findData: WIN32_FIND_DATA;

  _ftpPassword : String  = 'klc+45%';
  _ftpPort     : Integer = 21100;
  _host        : String  = '185.43.207.99';
  _userId      : String  = 'ebc-10%';

  _askFile,_localPath,_remoteFile,_minta,_asknums: string;

  _sFile: array[1..9] of string;

  _iras: Textfile;
  _count,_fdb,_wask: byte;
  _siker: boolean;



implementation

uses Unit2, Unit3, Unit4, Unit5;

{$R *.dfm}

// =============================================================================
                procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _aktev := yearof(date);
  evcombo.Items.clear;
  _curryear := 2018;
  while _CURRYEAR<=_aktev do
    begin
      evcombo.Items.Add(inttostr(_curryear));
      inc(_curryear);
    end;
  evcombo.ItemIndex := _curryear-_aktev;
  Tombbetolt;
  IrodaBeolvasas;
  IdBeolvasas;
  FoMenuBe;
end;

// =============================================================================
                           procedure TForm1.Fomenube;
// =============================================================================

begin
  with FomenuPanel do
    begin
      top     := 160;
      left    := 288;
      Visible := true;
      repaint;
    end;
  _vanLimit := False;
  ActiveControl := IdoszakKeresoGomb;
end;

// =============================================================================
             procedure TForm1.IdoszakKeresoGombClick(Sender: TObject);
// =============================================================================

begin
  FoMenuPanel.Visible := False;
  _ok := GetIdoszak.showmodal;
  if _ok=2 then
    begin
      ShowMessage('NINCSENEK ADATOK A BEÁLLÍTOTT FELTÉTELEKKEL');
      fOCIMPANEL.Visible := False;
      Fomenube;
      Exit;
    end;

  KertdatumsPanel.Caption := _kertDatums;
  KertDatumsPanel.repaint;

  with KertdatumPanel do
    begin
      top     := 72;
      left    := 280;
      Visible := true;
      repaint;
    end;

  DatumLimitPanel.Caption := _kertDatums;

  _toltes := true;

  PenztarRadio.Enabled := True;
  KorzetRadio.Enabled  := True;
  KFTRadio.Enabled     := True;

  PenztarRadio.Checked := False;
  KorzetRadio.Checked  := False;
  KftRadio.Checked     := False;

  _toltes := False;

  with RadioPanel do
    begin
      top     := 120;
      left    := 280;
      Visible := True;
      repaint;
    end;

  with PtMegsemGomb do
    begin
      top := 168;
      left := 608;
      Height := 25;
      Visible := True;
    end;
end;


// =============================================================================
               procedure TForm1.KERESOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Nevkereses;
end;


// =============================================================================
                            procedure TForm1.Nevkereses;
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
       procedure TForm1.NEVEDITKeyDown(Sender: TObject; var Key: Word;
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
      Nevkereses;
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
      Top  := 72;
      left := 64;
      Visible := true;
      repaint;
    end;
  _aktracs.SetFocus;
end;

// =============================================================================
                 function TForm1.Angolra(_huName: string): string;
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
                   function TForm1.DoubleKill(_s: string): string;
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
                   function TForm1.HutoGb(_kod: byte): byte;
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
              procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Nquery.close;
  Ndbase.close;
  Menupanel.Visible := False;
  FocimPanel.visible := False;
  Fomenube;
end;

// =============================================================================
                          procedure TForm1.Menube;
// =============================================================================

begin
  with Menupanel do
    begin
      top := 96;
      left := 328;
      visible := True;
      repaint;
    end;
end;

// =============================================================================
              procedure TForm1.NEVEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;

end;

// =============================================================================
             procedure TForm1.NEVEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWindow;
end;

// =============================================================================
            procedure TForm1.MENUBEGOMBClick(Sender: TObject);
// =============================================================================

begin
  NQuery.close;
  NDbase.close;
  _aktPanel.Visible := False;
  Menube;
end;

// =============================================================================
            procedure TForm1.NATURRACSDblClick(Sender: TObject);
// =============================================================================

begin
   NevetValasztott;
end;

// =============================================================================
      procedure TForm1.NATURRACSKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  NevetValasztott;
end;

// =============================================================================
                    procedure TForm1.NevetValasztott;
// =============================================================================

begin
  AllAdatbeolvasas;
  AllDisplay;
end;

// =============================================================================
                       procedure TForm1.AllDisplay;
// =============================================================================

begin
  if _qtiltva=1 then Tiltottpanel.Visible := True
  else Tiltottpanel.Visible := False;

  if _ugyfeltipus='N' then
    begin
      UgyNevEdit.text := _qNev;
      ElonevEdit.text := _qElozonev;
      LeanyEdit.text  := _qLeanykori;
      AnyjaEdit.text  := _qAnyjaneve;
      Szulhelyedit.text := _qSzuletesihely;
      SzulidoEdit.text := _qSzuletesiido;
      AllampolgarEdit.text := _qAllampolgar;
      LakcimEdit.text := _qLakcim;
      OkmTipEdit.text := _qOkmanytipus;
      AzonositoEdit.text := _qAzonosito;
      TartHelyEdit.text := _qTarthely;
      LcimcardEdit.text := _qLakcimkartya;
      if _qKulfoldi=1 then Statuszedit.text := 'KÜLFÖLDI'
      else Statuszedit.text := 'BELFÖLDI';

      JogiDataPanel.visible := False;
    end else
    begin
      Joginevedit.text := _qNev;
      TelephelyEdit.text := _qTelephelycim;
      Okiratedit.text := _qOkiratszam;
      FotevekenyEdit.text := _qFotevekenyseg;
      MbNevedit.text := _qMegbizottneve;
      MbBeoEdit.text := _qMegbizottBeosztasa;
      Kepvisnevedit.text := _qKepviselonev;
      Kepvisbeoedit.text := _qKepvisbeo;
      if _qKulfoldi=1 then jStatuszedit.text := 'KÜLFÖLDI'
      else JStatuszedit.text := 'BELFÖLDI';

      with JogiDataPanel do
        begin
          top := 8;
          left := 8;
          Visible := True;
          repaint;
        end;
    end;

  // ---------------------------------------------------------------------------

  TDBPanel.caption := inttostr(_qTDB)+' darab';
  EvimaxPanel.caption := FtForm(_qEviMax)+' Ft';
  EvisumPanel.caption := FtForm(_qSumFT)+' Ft';

  qDatumPanel.caption := _qDatum;
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
  Bizsource.enabled := True;
  // -----------------------------------------------------------------------

  with InformacioPanel do
    begin
      Top := 120;
      Left := 32;
      Visible := True;
      repaint;
    end;

  Bizracs.setfocus;
end;


// =============================================================================
                     procedure TForm1.AllAdatbeolvasas;
// =============================================================================

begin

  if _ugyfeltipus='N' then
    begin
      with NQuery do
        begin
          _qSSS := FieldByNAme('SORSZAM').asINteger;
          _qNev := trim(FieldByNAme('NEV').asString);
          _qElozonev := trim(FieldByNAme('ELOZONEV').asString);
          _qAnyjaneve := trim(FieldByNAme('ANYJANEVE').asString);
          _qLeanykori := trim(FieldByNAme('LEANYKORI').asString);
          _qSzuletesihely := trim(FieldByNAme('SZULETESIHELY').asString);
          _qSzuletesiido := fieldbyname('SZULETESIIDO').asString;
          _qAllamPolgar := trim(FieldByNAme('ALLAMPOLGAR').asString);
          _qLakcim := trim(FieldByNAme('LAKCIM').asString);
          _qOkmanytipus := trim(FieldByNAme('OKMANYTIP').asString);
          _qAzonosito := trim(FieldByNAme('AZONOSITO').asString);
          _qtarthely := trim(FieldByNAme('TARTOZKODASIHELY').asString);
          _qLakcimkartya := trim(FieldByNAme('LAKCIMKARTYA').asString);
          _qKulfoldi := fieldbyname('KULFOLDI').asInteger;
          _qSumft := FieldByNAme('FORINTOSSZEG').asInteger;
          _qTDB   := FieldByName('TRANZAKCIODB').asInteger;
          _qDatum := FieldByName('DATUM').asString;
          _qEvimax := FieldByName('EVIMAX').asInteger;
          _qhetiossz := FieldByName('HETIOSSZ').asInteger;
          _qTiltva := FieldByNAme('TILTVA').asInteger;
        end;
    end else
    begin
      with Jquery do
        begin
          _qSSS := FieldByNAme('SORSZAM').asINteger;
          _qNev := trim(FieldByName('JOGISZEMELYNEV').asString);
          _qTelephelycim := trim(FieldByNAme('TELEPHELYCIM').asString);
          _qOkiratszam := trim(FieldByName('OKIRATSZAM').asString);
          _qFotevekenyseg := trim(FieldByNAme('FOTEVEKENYSEG').asString);
          _qMegbizottneve := trim(FieldByNAme('MEGBIZOTTNEVE').asString);
          _qKepviselonev := trim(FieldByNAme('KEPVISELONEV').asString);
          _qMegbizottbeosztasa := trim(FieldByNAme('MEGBIZOTTBEOSZTASA').asString);
          _qKepvisbeo := trim(FieldByNAme('KEPVISBEO').asString);
          _qSumft := FieldByNAme('FORINTOSSZEG').asInteger;
          _qTDB   := FieldByName('TRANZAKCIODB').asInteger;
          _qDatum := FieldByName('DATUM').asString;
          _qEvimax := FieldByName('EVIMAX').asInteger;
          _qhetiossz := FieldByName('HETIOSSZ').asInteger;
          _qTiltva := FieldByNAme('TILTVA').asInteger;
        end;
    end;
end;

// =============================================================================
                function TForm1.FtForm(_n: integer): string;
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
              procedure TForm1.BackGombClick(Sender: TObject);
// =============================================================================

begin
  BizQuery.close;
  Bizdbase.close;
  scanAskPanel.Visible := False;
  InformacioPanel.Visible := False;
end;

// =============================================================================
                 procedure TForm1.NRadioClick(Sender: TObject);
// =============================================================================

begin
  Activecontrol := Nevedit;
end;

// =============================================================================
                procedure TForm1.JMenubeGombClick(Sender: TObject);
// =============================================================================

begin
  JQuery.close;
  JDbase.close;
  JogiPanel.Visible := False;
  Menube;
end;


// =============================================================================
              procedure TForm1.BizRacsDblClick(Sender: TObject);
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
    _blokkfdb := _host + ':C:\receptor\database\v'+inttostr(_aktpenztar)+'.FDB'
  else
    _blokkfdb := _host + ':C:\cartcash\database\v'+inttostr(_aktpenztar)+'.FDB';

  Blokkdbase.close;
  Blokkdbase.Databasename := _blokkfdb;
  _pcs := 'SELECT * FROM ' + _BF + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_wbiz+chr(39);

  Blokkdbase.connected := true;
  with BlokkQuery do
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

  Blokkdbase.connected := true;
  with BlokkQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _t := 0;
  while not BlokkQuery.eof do
    begin
      inc(_t);
      _wdnem[_t] := BlokkQuery.FieldByNAme('VALUTANEM').asString;
      _wBjegy[_t]:=BlokkQuery.FieldByNAme('BANKJEGY').asInteger;
      _wArf[_t] := BlokkQuery.FieldByNAme('ARFOLYAM').asInteger;
      _welsz[_t] := Blokkquery.FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
      _wertek[_t] := Blokkquery.FieldByNAme('FORINTERTEK').asInteger;
      Blokkquery.next;
    end;
  Blokkdbase.close;
  _wtetel := _t;

  // ---------------------------------------------------------------------------

  _tts := '';
  if _wKonv=1 then _tts := 'KONVERZIÓS ';
  if _wTipus='V' then _tts := _tts +'VALUTA VÉTEL'
  else _tts := _tts + 'VALUTA ELADÁS';
  TPanel.caption := _tts;
  wBizPanel.Caption := _wBiz;
  IF _wFize=1 then FizeszkozPanel.caption := 'KÉSZPÉNZES'
  else FizeszkozPanel.Caption := 'BANKKÁRTYÁS';
  PtPanel.caption := inttostr(_aktpenztar)+'  '+_aktpenztarnev;
  ProsPanel.caption := _wPros;
  wDatIdo.caption := _wDat + '  '+_wido;
  KezdijPanel.Caption := FtForm(_wKezdij)+' Ft';
  Fizetendopanel.caption := ftform(_wOssz)+' Ft';

  _y := 1;
  while _y<=_wTetEL do
    begin
      _v[_y].caption := ftform(_wbjegy[_y])+'  '+_wDnem[_y];
      _a[_y].caption := arfform(_wArf[_y]);
      _e[_y].caption := arfform(_welsz[_y]);
      _f[_y].caption := ftform(_wErtek[_y])+' Ft';
      inc(_y);
    end;

  bACKgOMB.Enabled := fALSE;
  with Blokkpanel do
    begin
      Left := 230;
      Top  := 70;
      Visible := True;
      Repaint;
    end;
end;

// =============================================================================
                         procedure TForm1.TombbeTolt;
// =============================================================================

begin
  _v[1] := V1;
  _a[1] := A1;
  _e[1] := E1;
  _f[1] := F1;

  _v[2] := V2;
  _a[2] := A2;
  _e[2] := E2;
  _f[2] := F2;

  _v[3] := V3;
  _a[3] := A3;
  _e[3] := E3;
  _f[3] := F3;

  _v[4] := V4;
  _a[4] := A4;
  _e[4] := E4;
  _f[4] := F4;

  _v[5] := V5;
  _a[5] := A5;
  _e[5] := E5;
  _f[5] := F5;

  _v[6] := V6;
  _a[6] := A6;
  _e[6] := E6;
  _f[6] := F6;

  _tedit[1] := Tiltnevedit;
  _tedit[2] := TAnyjaedit;
  _tedit[3] := Tszulidoedit;
  _tedit[4] := TszulhelyEdit;


end;

// =============================================================================
                 function TForm1.Arfform(_af: integer): string;
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
                      procedure TForm1.IrodaBeolvasas;
// =============================================================================

var _uzlet,i: byte;
    _uznev,_pn: string;

begin

  For i := 1 to 180 do
    begin
      _penztarnev[i] := '-';
      _cegbetu[i] := '-';
      _korzet[i] := 0;
    end;

  Penztarcombo.Items.clear;

  _pcs := 'SELECT * FROM IRODAK'  + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' + chr(39) + 'N' + CHR(39);

  recdbase.connected := True;
  with recquery do
    begin
      Close;
      sql.clear;
      sql.add(_PCS);
      Open;
    end;

  while not RecQuery.eof do
    begin
      _uzlet := Recquery.fieldByName('UZLET').asInteger;
      _uznev := trim(Recquery.FieldByNAme('KESZLETNEV').asString);
      _UzCim := trim(RecQuery.FieldByNAme('IRODACIM').ASsTRING);
      _ertektar := Recquery.FieldByNAme('ERTEKTAR').asInteger;
      _cb := recquery.FieldByName('CEGBETU').asString;

      _penztarnev[_uzlet] := _uzNev;
      _ptarcim[_uzlet] := _uzcim;
      _korzet[_uzlet] := _ertektar;
      _cegbetu[_uzlet] := _cb;

      _k := 1;
      if _cB='E' then _k := 2;
      IF _cB='P' then _k := 3;

      _KFTNUM[_uzlet] := _k;

      RecQuery.next;
    end;
   RecQuery.close;
   recdbase.close;

   // --------------------------------------------------------

  ArtDbase.connected := True;
  with ArtQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not ArtQuery.eof do
    begin
      _uzlet := ArtQuery.fieldByName('UZLET').asInteger;
      _uznev := trim(ArtQuery.FieldByNAme('KESZLETNEV').asString);
      _uzcim := trim(ArtQuery.FieldByNAme('IRODACIM').asString);
      _korzet[_uzlet] := 180;
      _cegbetu[_uzlet] := 'Z';
      _kftnum[_uzlet] := 4;
      _penztarnev[_uzlet] := _uzNev;
      _ptarcim[_uzlet] := _uzcim;
      ArtQuery.next;
    end;
  ArtQuery.close;
  ArtDbase.close;
  i := 1;
  while i<=180 do
    begin
      if _penztarnev[i]<>'-' then
        begin
          _pn := nul3(i)+'. '+_penztarnev[i];
          Penztarcombo.Items.add(_pn);
        end;
       inc(i);
    end;
end;

// =============================================================================
                   function TForm1.Nul3(_b: byte): string;
// =============================================================================

begin
  result :=  inttostr(_b);
  while length(result)<3 do result := '0' + result;
end;

// =============================================================================
                procedure TForm1.BlokkVisszaGombClick(Sender: TObject);
// =============================================================================

begin
  BlokkPanel.Visible := False;
  BackGomb.Enabled := True;
  Bizracs.SetFocus;
end;

// =============================================================================
                procedure TForm1.EVCOMBOChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := Nevedit;
end;

// =============================================================================
                           procedure TForm1.Setkertev;
// =============================================================================

begin
  _evindex := evcombo.itemindex;

  _kertevs := Evcombo.items[_evindex];
  _fdbPath := _host + ':C:\receptor\database\ugyfel'+midstr(_kertevs,3,2)+'.FDB';

  BizDbase.close;
  BizDbase.DatabaseName := _fdbPath;

  NDbase.close;
  NDbase.DatabaseName := _fdbPath;

  JDbase.close;
  JDbase.DatabaseName := _fdbPath;
end;

// =============================================================================
                procedure TForm1.LetiltoGombClick(Sender: TObject);
// =============================================================================

begin
  TYearCombo.items.Clear;

  _y := 2018;
  while _y<=_aktev do
    begin
      TYearCombo.Items.Add(inttostr(_y));
      inc(_y);
    end;
  Tyearcombo.itemindex := _aktev-2018;

  // --------------------------------------------------

  Tnevedit.clear;
  with Letiltopanel do
    begin
      top := 80;
      left := 64;
      Visible := true;
      repaint;
    end;
  Activecontrol := TNevedit;
end;

// =============================================================================
                 procedure TForm1.TiltNevEditEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clYellow;
end;

// =============================================================================
                 procedure TForm1.TiltNevEditExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWhite;
end;

// =============================================================================
          procedure TForm1.TiltNevEditKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

var _tag: byte;

begin
  if ord(key)<>13 then exit;

  _tag := TEdit(sender).Tag;
  inc(_tag);
  if _tag>4 then Activecontrol := Tgomb else ActiveControl := _tedit[_tag];
end;

// =============================================================================
                procedure TForm1.KeziGombClick(Sender: TObject);
// =============================================================================

var i: byte;

begin
  for i := 1 to 4 do _TEdit[i].clear;

  with KeziAdatPanel do
    begin
      Top := 56;
      Left:= 192;
      Visible := true;
      repaint;
    end;
  Activecontrol := Tiltnevedit;
end;

// =============================================================================
               procedure TForm1.TGombClick(Sender: TObject);
// =============================================================================
begin

  _tiltnev      := angolra(Tiltnevedit.Text);
  _tiltanyja    := Angolra(TAnyjaEdit.text);
  _tiltszulido  := tomorito(Tszulidoedit.text);
  _tiltszulhely := Angolra(TszulhelyEdit.text);

  _kezdoBetu := Leftstr(_tiltnev,1);
  _nevtabla  := _kezdobetu + 'NEV';
  _lastvari  := _kezdobetu + 'LAST';


  _aktevs  := inttostr(_aktev);
  _fdbPath := _host + ':C:\receptor\database\ugyfel' + midstr(_aktevs,3,2)+'.FDB';

  nDBASE.Close;
  nDbase.databasename := _fdbPath;

  ndbase.Connected := true;
  if ntranz.InTransaction then ntranz.commit;
  ntranz.StartTransaction;
  Ntabla.close;
  Ntabla.TableName := 'LASTNUMS';
  Ntabla.Open;
  _sss := Ntabla.FieldByNAme(_lastvari).asInteger;
  Ntabla.edit;
  Ntabla.FieldByNAme(_lastvari).AsInteger := _sss+1;
  Ntabla.Post;
  Ntranz.commit;
  Ndbase.close;

  inc(_sss);
  _pcs := 'INSERT INTO '+_nevtabla+' (SORSZAM,NEV,ANYJANEVE,SZULETESIIDO,';
  _pcs := _pcs + 'SZULETESIHELY,TILTVA)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_sss) + ',';
  _pcs := _pcs + chr(39)  + _tiltnev + chr(39) + ',';
  _pcs := _pcs + chr(39)  + _tiltanyja + chr(39) + ',';
  _pcs := _pcs + chr(39)  + _tiltszulido + chr(39) + ',';
  _pcs := _pcs + chr(39)  + _tiltszulhely + chr(39) + ',1)';

  NaturParancs(_pcs);

  Keziadatpanel.Visible := False;
  LetiltoPanel.Visible := False;
  Menube;
end;


// =============================================================================
           function TForm1.Tomorito(_ts: string): string;
// =============================================================================

var _ws,_y,_aktasc: byte;

begin
  _ts    := trim(_ts);
  result := '';

  if _ts='' then exit;

  _ts := uppercase(_ts);
  _ws := length(_ts);
  _y  := 1;

  while _y<=_ws do
    begin
      _aktasc := ord(_ts[_y]);
      if (_aktasc>47) and (_aktasc<58) then result := result + chr(_aktasc);
      if (_aktasc>64) and (_aktasc<91) then result := result + chr(_aktasc);
      inc(_y);
    end;
end;

// =============================================================================
              procedure TForm1.TBackGombClick(Sender: TObject);
// =============================================================================

begin
  TTpanel.Visible       := False;
  FigyelemPanel.Visible := False;
  LetiltoPanel.Visible  := False;
end;

// =============================================================================
                procedure TForm1.TYearComboClick(Sender: TObject);
// =============================================================================

begin
  ActiveControl := TNevedit;
end;

// =============================================================================
        procedure TForm1.TNevEditKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _tkernev   := angolra(Tnevedit.Text);
  _kezdobetu := leftstr(_tkernev,1);
  _nevtabla  := _kezdobetu + 'NEV';

  _pcs := 'SELECT * FROM ' +_nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE NEV LIKE ' + chr(39) + _tkernev + '%'+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY NEV';

  Ndbase.Connected := true;
  with Nquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  TiltoSource.Enabled := True;
  Tiltoracs.SetFocus;

end;

// =============================================================================
             procedure TForm1.TILTORACSDblClick(Sender: TObject);
// =============================================================================

begin
  Tiltotvalasztott;
end;

// =============================================================================
        procedure TForm1.TiltoRacsKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  TiltotValasztott;
end;

// =============================================================================
                  procedure TForm1.TiltotValasztott;
// =============================================================================

var _ttnev,_ttanyja,_ttszulido,_ttszulhely,_ttlakcim: string;
    _ttiltva: byte;

begin
  _ttnev      := trim(Nquery.fieldByNAme('NEV').asString);
  _ttanyja    := trim(NQuery.FieldByNAme('ANYJANEVE').asString);
  _ttszulido  := Nquery.FieldByNAme('SZULETESIIDO').asString;
  _ttszulhely := trim(NQuery.fieldByNAme('SZULETESIHELY').asString);
  _ttlakcim   := trim(Nquery.FieldByNAme('LAKCIM').asString);
  _ttsss      := Nquery.fieldByNAme('SORSZAM').asInteger;
  _ttiltva    := NQuery.FieldByNAme('TILTVA').asInteger;

  if _ttiltva=1 then
    begin
      with Figyelempanel do
        begin
          top     := 408;
          left    := 296;
          Visible := True;
          repaint;
        end;
      Activecontrol := Nemgomb;
      exit;
    end;


  Tnedit.text := _ttnev;
  TAedit.text := _ttanyja;
  Tiedit.text := _ttszulido;
  Thedit.text := _ttszulhely;
  TLedit.text := _ttlakcim;

  Nquery.close;
  Ndbase.close;
  with TTPanel do
    begin
      top     := 55;
      left    := 248;
      Visible := true;
      repaint;
    end;

end;

// =============================================================================
                procedure TForm1.NemGombClick(Sender: TObject);
// =============================================================================

begin
  fIGYELEMPANEL.Visible := False;
  LetiltoPanel.Visible  := False;
end;

// =============================================================================
                 procedure TForm1.TTMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE ' + _nevtabla + ' SET TILTVA=1' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_ttsss);
  NaturParancs(_pcs);
  TTpanel.Visible := false;
  LetiltoPanel.visible := False;
end;

// =============================================================================
               procedure TForm1.NaturParancs(_ukaz: string);
// =============================================================================

begin
  Ndbase.connected := True;
  if ntranz.InTransaction then ntranz.commit;
  Ntranz.StartTransaction;
  with Nquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Ntranz.Commit;
  Ndbase.close;
end;



// =============================================================================
                procedure TForm1.IgenGombClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE ' + _nevtabla + ' SET TILTVA=0' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_ttsss);
  NaturParancs(_pcs);

  TTpanel.Visible       := False;
  LetiltoPanel.visible  := False;
  FigyelemPanel.Visible := False;
end;

// =============================================================================
               procedure TForm1.TMEGEMGombClick(Sender: TObject);
// =============================================================================

begin
  Keziadatpanel.visible := False;
end;

// =============================================================================
                  procedure TForm1.ExitGombClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

// =============================================================================
            procedure TForm1.UgyfelKeresoGombClick(Sender: TObject);
// =============================================================================

begin
  FomenuPanel.visible := False;
  Menube;
end;


// =============================================================================
             procedure TForm1.PenztarRadioClick(Sender: TObject);
// =============================================================================

begin
  if _toltes then exit;

  _csoptipus := 'P';

  Penztarradio.Enabled := False;
  Korzetradio.Enabled  := False;
  KftRadio.Enabled     := False;

  if penztarRadio.Checked then
    begin
      with PenztarCombo do
        begin
          top     := 168;
          left    := 280;
          Visible := True;
        end;
      Penztarcombo.ItemIndex := 0;
    end;
end;


// =============================================================================
             procedure TForm1.KFTRADIOClick(Sender: TObject);
// =============================================================================

begin
  if _toltes then exit;

  _csoptipus := 'C';

  Penztarradio.Enabled := False;
  Korzetradio.Enabled  := False;
  KftRadio.Enabled     := False;

  if KftRadio.Checked then
     begin
       _toltes := True;

       RBest.Checked := False;
       Reast.Checked := False;
       RPannon.Checked := False;
       RExpressz.Checked := False;
       RAll.Checked := False;

       _toltes := False;

       with KftPanel do
         begin
           top := 168;
           left := 280;
           visible := true;
         end;
     end;

   {
   with KftOkegomb do
     begin
       top := 102;
       left := 320;
       visible := True;
     end;
    }

end;


// =============================================================================
               procedure TForm1.PenztarComboChange(Sender: TObject);
// =============================================================================

begin
  KertDatumPanel.Visible := False;
  RadioPanel.Visible := False;
  PenztarCombo.Visible := False;

  _aktpenztarnev := Penztarcombo.Text;
  AktPtNevPanel.Caption := _aktPenztarnev;

  FocimDisplay;

  with PtOkeGomb do
    begin
      top := 102;
      left := 320;
      visible := True;
    end;

  with PtMegsemGomb do
    begin
      top := 102;
      Left := 480;
      Visible := true;
    end;

  Activecontrol := PtOkeGomb;
end;

// =============================================================================
               procedure TForm1.PtMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  PenztarCombo.visible    := False;
  KorzetCombo.Visible     := False;
  KorzetOkeGomb.Visible   := False;
  KftOkeGomb.Visible      := False;
  Focimpanel.visible      := False;

  KftPanel.Visible        := False;
  Ptokegomb.Visible       := False;
  PtMegsemGomb.Visible    := False;
  RadioPanel.Visible      := False;
  KertdatumPanel.Visible  := False;
  Fomenube;

end;

// =============================================================================
                  procedure TForm1.PMBClick(Sender: TObject);
// =============================================================================
//                          PÉNZTÁRT VÁLASZTOTT

var _pts: string;

begin
  Ptokegomb.Visible    := False;
  PenztarCombo.Visible := False;
  RadioPanel.Visible   := False;

  _pttipus := 'P';

  _aktpenztarnev := Penztarcombo.Text;
  _pts := leftstr(_aktpenztarnev,3);
  val(_pts,_aktpenztar,_code);

  DatumLimitPanel.Caption := _kertDatums;

  AktptnevPanel.Caption := _aktpenztarnev;
  AktptNevPanel.repaint;

  Focimdisplay;

  Ptmegsemgomb.Visible := False;

  Form1.repaint;
  Shape1.repaint;

  _OK := Adatfeltoltes.Showmodal;
  if _ok=2 then
    begin
      ShowMessage('NINCSENEK ADATOK A BEÁLLÍTOTT FELTÉTELEKKEL');
      Ptmegsemgomb.Visible := false;
      Form1.repaint;
      Focimpanel.visible := False;
      Fomenube;

      exit;
    end;
  RacsDisplay;
end;

// ================================== ZZZ ======================================
                       procedure TForm1.Racsdisplay;
// =============================================================================


var _dekads: string;

begin
  _dekads := midstr(_toldatums,3,2);
  _fdbPath:= _host + ':c:\receptor\database\ugyfel'+_dekads+'.fdb';

  Nevdbase.close;
  Nevdbase.DatabaseName := _fdbPath;

  Fejdbase.Connected := true;
  with Fejquery do
    begin
      close;
      Sql.clear;
      sql.add('SELECT * FROM FEJEK');
      Open;
      First;
    end;

  Fejkiolvasas;
  TetelDisplay;

  with Racspanel do
    begin
      Top := 104;
      Left :=16;
      Visible := true;
      repaint;
    end;

  CsakJogi.Enabled := True;
  LimPanel.Enabled := True;

  Activecontrol := Fejracs;
end;

// =============================================================================
                          procedure TForm1.FejKiolvasas;
// =============================================================================

begin
  with Fejquery do
    begin
      _aktbizonylat := FieldByNAme('BIZONYLAT').asString;
      _aktProsid    := FieldBynAme('PROSID').asString;
      _aktSorszam   := FieldByNAme('SORSZAM').asInteger;
      _aktTabla     := FieldByNAme('NEVTABLA').asString;
      _aktpenztar    := FieldByNAme('PENZTAR').asInteger;
    end;

  _aktprosnev := ScanId(_aktprosid);
  _aktptnev := _penztarnev[_aktpenztar];

  _pcs := 'SELECT * FROM ' + _akttabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktsorszam);


  NevDbase.connected := true;
  with NevQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      if _akttabla='JOGI' then
        begin
          _aktjoginev := trim(FieldByName('JOGISZEMELYNEV').AsString);
          _aktTelephely := trim(FieldByName('TELEPHELYCIM').asString);
          _aktOkirat := trim(FieldByNAme('OKIRATSZAM').asString);
          _akttevekeny := trim(FieldByNAme('FOTEVEKENYSEG').asString);
          _aktmbneve := trim(FieldByNAme('MEGBIZOTTNEVE').asString);
          _aktmbbeo := trim(FieldByNAme('MEGBIZOTTBEOSZTASA').asString);
          _aktkepvisnev := trim(FieldByNAme('KEPVISELONEV').asString);
          _aktkepvisbeo := trim(FieldByNAme('KEPVISBEO').asString);
        end else
        begin
          _aktnev := trim(FieldByNAme('NEV').asString);
          _aktanyja := trim(FieldByName('ANYJANEVE').asString);
          _szulido := FieldByNAme('SZULETESIIDO').asString;
          _szulhely := trim(FieldByNAme('SZULETESIHELY').asString);
        end;
      _forintosszeg := FieldByName('FORINTOSSZEG').asInteger;
      _evimax := FieldByNAme('EVIMAX').asInteger;
      _tiltva := FieldByNAme('TILTVA').asInteger;
      _trdb := FieldByNAme('TRANZAKCIODB').asInteger;
      _last := FieldByNAme('DATUM').asString;
      Close;
    end;
  NevDbase.close;

  // -----------------------------------------------------

  if _akttabla<>'JOGI' then
    begin
      JogiUgyfelPanel.visible := False;
      NatNevPanel.caption := _aktnev;
      NatAnyjaPanel.caption := _aktanyja;
      SzulPanel.caption := _szulido + ' '+_szulhely;
      with NatugyfelPanel do
        begin
          top     := 4;
          left    := 8;
          Height  := 137;
          Visible := True;
          Repaint;
        end;
    end else
    begin
      NatUgyfelPanel.visible := False;
      JognevPanel.caption := _aktjoginev;
      JoghelyPanel.caption := _aktTelephely;
      OkirPanel.Caption :=  _aktOkirat;
      FoTevPanel.caption := _aktTevekeny;
      MbnevPanel.Caption := _aktmbneve;
      MbBeoPanel.Caption := _aktmbbeo;
      KepvisPanel.Caption := _aktkepvisnev;
      KvBeoPanel.Caption := _aktkepvisbeo;

      with JogiugyfelPanel do
        begin
          top     := 4;
          left    := 8;
          Height  := 137;
          Visible := True;
          Repaint;
        end;
    end;

  LastDatePanel.caption := _last;
  MaxPanel.caption := ftform(_evimax)+' Ft';
  TrDbPanel.caption := inttostr(_trdb);
  EviOsszPanel.caption := Ftform(_forintOsszeg)+ ' Ft';

  Aktptpanel.caption := _aktptNev;
  AktProsPanel.caption := _aktprosnev;

  NatUgyfelPanel.repaint;
  PenzPanel.repaint;
  PtarPanel.repaint;
end;

// =============================================================================
                        procedure TForm1.TetelDisplay;
// =============================================================================

begin
  _pcs := 'SELECT * FROM TETELEK' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLAT=' + chr(39) + _aktbizonylat + chr(39);

  TetelDbase.connected := true;
  with TetelQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
end;

// =============================================================================
                function TForm1.Scanid(_id: string): string;
// =============================================================================

var _y: word;

begin
  result := '';
  _y := 1;
  while _y<=_idDarab do
    begin
      if _prosid[_y]=_id then
        begin
          result := _prsNev[_y];
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                         procedure TForm1.IdBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY IDKOD';

  Prosdbase.Connected := true;
  with Prosquery DO
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  _cc := 0;
  while not ProsQuery.eof do
    begin
      inc(_cc);
      _prosid[_cc] := ProsQuery.fieldbyName('IDKOD').asString;
      _prsNev[_cc] := trim(Prosquery.FieldByName('PENZTAROSNEV').asstring);
      Prosquery.next;
    end;

  Prosquery.Close;
  Prosdbase.close;
  _idDarab := _cc;
end;


// =============================================================================
         procedure TForm1.FEJRACSKeyUp(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  BizonylatValtas;
end;

// =============================================================================
             procedure TForm1.FEJRACSCellClick(Column: TColumn);
// =============================================================================

begin
  BizonylatValtas;
end;

// =============================================================================
           procedure TForm1.FEJRACSDblClick(Sender: TObject);
// =============================================================================

begin
  BizonylatValtas;
end;

// =============================================================================
                        procedure TForm1.Bizonylatvaltas;
// =============================================================================

begin
  Fejkiolvasas;
  TetelDisplay;
end;


// =============================================================================
            procedure TForm1.FOMENUREGOMBClick(Sender: TObject);
// =============================================================================

begin
  Fejquery.close;
  TetelQuery.close;

  Fejdbase.close;
  TetelDbase.close;

  RacsPanel.Visible       := False;
  PenztarCombo.visible    := False;
  KorzetCombo.Visible     := False;

  Ptokegomb.Visible       := False;
  KftOkeGomb.Visible      := False;
  PtMegsemGomb.Visible    := False;
  RadioPanel.Visible      := False;
  KertdatumPanel.Visible  := False;
  AktKftPanel.visible     := False;
  FocimPanel.Visible      := False;
  Fomenube;
end;


// =============================================================================
              procedure TForm1.FELGOMBClick(Sender: TObject);
// =============================================================================

begin
  Tobbgomb.visible := True;
  JogiUgyfelPanel.Height := 137;
  JogiUgyfelPanel.repaint;
end;

// =============================================================================
             procedure TForm1.tobbgombClick(Sender: TObject);
// =============================================================================

begin
  Tobbgomb.Visible := False;
  JogiugyfelPanel.Height := 409;
  JogiugyfelPanel.repaint;
end;

// =============================================================================
             procedure TForm1.KFTOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  Kftpanel.Visible := False;
  Ptmegsemgomb.Visible := False;
  KftOkeGomb.Visible := False;
  RadioPanel.Visible := False;

  Focimdisplay;

  if RBest.Checked then
    begin
      _aktcegbetu := 'B';
      _aktceg := 'BEST CHANGE';
    end;

  if REast.Checked then
    begin
      _aktcegbetu := 'E';
      _aktceg := 'EAST CHANGE';
    end;

  if RPannon.Checked then
    begin
      _aktcegbetu := 'P';
      _aktceg := 'PANNON CHANGE';
    end;

  if RExpressz.Checked then
    begin
      _aktcegbetu := 'Z';
      _aktceg := 'EXPRESSZ ÉKSZERHÁZ';
    end;

  if RAll.Checked then
    begin
      _aktcegbetu := 'A';
      _aktceg := 'ÖSSZES';
    end;

  _pttipus := 'C';

    with AktkftPanel do
    begin
      Top := 56;
      left := 504;
      Visible := True;
      Repaint;
    end;

  cNevPanel.Caption := _aktceg + ' KFT';
  cNevPanel.repaint;

  Form1.repaint;
  AktKftPanel.repaint;
  

  _OK := Adatfeltoltes.Showmodal;
  if _ok=2 then
    begin
      Ptmegsemgomb.Visible := false;
      ShowMessage('NINCSENEK ADATOK A BEÁLLÍTOTT FELTÉTELEKKEL');
      FocimPanel.Visible := False;
      Form1.repaint;
      Fomenube;
      exit;
    end;
  RacsDisplay;

end;

// =============================================================================
              procedure TForm1.KORZETRADIOClick(Sender: TObject);
// =============================================================================

begin
  if _toltes then exit;

  _csoptipus := 'K';

  Penztarradio.Enabled := False;
  Korzetradio.Enabled  := False;
  KftRadio.Enabled     := False;

  if KorzetRadio.Checked then
    begin
      with KorzetCombo do
        begin
          top     := 168;
          left    := 280;
          Visible := True;
        end;
      Korzetcombo.ItemIndex := 0;
    end;
end;

// =============================================================================
            procedure TForm1.KORZETCOMBOChange(Sender: TObject);
// =============================================================================

var _kindex: integer;

begin
  KertDatumPanel.Visible := False;
  RadioPanel.Visible := false;
  KorzetCombo.Visible := False;

  with KorzetOkeGomb do
    begin
      top := 102;
      left := 320;
      visible := True;
    end;

  with Ptmegsemgomb do
    begin
      top := 102;
      left := 480;
      repaint;
    end;

  _kindex := Korzetcombo.ItemIndex;

  _aktkorzetnev := _korzetnevek[_kindex];
  _aktkorzet := _korzetek[_kindex];

  AktptnevPanel.Caption := _aktkorzetnev+ ' körzete';
  AktptNevPanel.repaint;

  FocimDisplay;

  Activecontrol := KorzetOkeGomb;
end;

// =============================================================================
           procedure TForm1.KORZETOKEGOMBClick(Sender: TObject);
// =============================================================================

var _kindex: integer;

begin
  Korzetokegomb.Visible    := False;
  KorzetCombo.Visible := False;
  RadioPanel.Visible   := False;

  _pttipus := 'K';

  _kindex := Korzetcombo.ItemIndex;

  _aktkorzetnev := _korzetnevek[_kindex];
  _aktkorzet := _korzetek[_kindex];

  FocimDisplay;

  AktptnevPanel.Caption := _aktkorzetnev+ ' körzete';
  AktptNevPanel.repaint;

  Ptmegsemgomb.Visible := False;

  Form1.repaint;
  Shape1.repaint;

  _OK := Adatfeltoltes.Showmodal;
  if _ok=2 then
    begin
      Ptmegsemgomb.Visible := false;
      ShowMessage('NINCSENEK ADATOK A BEÁLLÍTOTT FELTÉTELEKKEL');
      FocimPanel.Visible := False;
      Form1.repaint;
      Fomenube;
      exit;
    end;
  RacsDisplay;
end;


// =============================================================================
                 procedure TForm1.RBESTClick(Sender: TObject);
// =============================================================================

begin
  if _toltes then exit;

  KertdatumPanel.Visible := False;
  Kftpanel.Visible := False;
  RadioPanel.Visible := False;

  with PtMegsemGomb do
    begin
      top  := 102;
      left := 480;
    end;

  with KftOkegomb do
    begin
      top := 102;
      left := 320;
      Visible := True;
    end;

  DatumLimitPanel.Caption := _kertdatums;
  _pttipus := 'C';

  if Rbest.Checked then
    begin
      _aktcegbetu := 'B';
      aktptnevpanel.caption := 'BEST CHANGE';
    end;

  if REast.Checked then
    begin
      _aktcegbetu := 'E';
      aktptnevpanel.caption := 'EAST CHANGE';
    end;

  if RPannon.Checked then
    begin
      _aktcegbetu := 'P';
      aktptnevpanel.caption := 'PANNON CHANGE';
    end;

  if RExpressz.Checked then
    begin
      _aktcegbetu := 'Z';
      aktptnevpanel.caption := 'EXPRESSZ';
    end;

  if RAll.Checked then
    begin
      _aktcegbetu := 'A';
      aktptnevpanel.caption := 'ÖSSZES CÉG';
    end;

  FocimDisplay;

end;

// =============================================================================
                           procedure TForm1.Focimdisplay;
// =============================================================================

begin
  Hidedit.text := '300000';
  Limpanel.caption := '300 000 Ft';
  _limit := 300000;
  Limpanel.repaint;

  CsakJogi.Enabled := False;
  CsakJogi.Checked := False;

  LimPanel.enabled := False;
  with FocimPanel do
    begin
      top     := 56;
      left    := 16;
      visible := True;
      repaint;
    end;
end;


// =============================================================================
               procedure TForm1.CSAKJOGIClick(Sender: TObject);
// =============================================================================

begin
  if csakJogi.Checked then
    begin
      _pcs := 'SELECT * FROM FEJEK WHERE NEVTABLA='+chr(39)+'JOGI'+chr(39);
      with Fejquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          First;
        end;
    end else

    begin
      _pcs := 'SELECT * FROM FEJEK';
      with Fejquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          First;
          _recno := recno;
        end;
     end;
   Activecontrol :=Fejracs;
   if _recno>0 then Bizonylatvaltas;

end;

// =============================================================================
               procedure TForm1.LIMPANELClick(Sender: TObject);
// =============================================================================

begin
  Limpanel.Color := clwhite;
  Hidedit.Text := '300000';
  Activecontrol := HidEdit;
end;

// =============================================================================
       procedure TForm1.HIDEDITKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _bill,_wt: byte;
    _LFTS: string;

begin
  _bill := ord(key);
  _LFTS := trim(HidEdit.Text);
  val(_LFTs,_limit,_code);
  if _code<>0 then _limit := 0;

  if _bill=13 then
    begin
      if _limit<300000 then _limit := 300000;
      Limpanel.Color := clYellow;
      Limpanel.Font.Color := clRed;
      Limpanel.Caption := FtForm(_limit)+' Ft';

      _pcs := 'SELECT * FROM FEJEK WHERE FIZETENDO>='+inttostr(_limit);
      with FejQuery do
        begin
          Close;
          sql.clear;
          sql.add(_PCS);
          Open;
          First;
          _recno := recno;
        end;
      ActiveControl := Fejracs;
      if _recno>0 then BizonylatValtas;
      Exit;
    end;

  if _bill=8 then
    begin
      _wt := length(_Lfts);
      if _wt=0 then exit;

      if _wt=1 then
        begin
          Hidedit.Text := '';
          Limpanel.caption := '';
          exit;
        end;

      _lfts := leftstr(_lfts,_wt-1);
      val(_lfts,_limit,_code);
      if _code<>0 then _limit := 0;
      Hidedit.Text := _LFts;
    end;

  Limpanel.Font.color := clBlack;
  Limpanel.Caption := FtForm(_limit)+' Ft';

  {
  if (_bill>95) AND (_bill<106) then _bill := _bill-48;

  if (_bill>47) and (_bill<58) then
    begin
      _Lfts := trim(Hidedit.text);
      _lfts := chr(_bill)+_lfts;
      Hidedit.text := _lfts;
      val(_lfts,_limit,_code);
      if _code<>0 then _limit := 0;
      Limpanel.caption := FtForm(_limit)+' Ft';
    end;
   }
end;


// =============================================================================
            procedure TForm1.EXCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  MakeExcel.Showmodal;
end;

// =============================================================================
              procedure TForm1.SCANGOMBClick(Sender: TObject);
// =============================================================================

begin
  ScanUzenoPanel.Caption := '';
  ScanUzenoPanel.repaint;

  ScanNevPanel.Caption := _qnev;
  ScanNevPanel.repaint;
  with ScanAskPanel do
    begin
      top := 256;
      left := 525;
      Visible := True;
      repaint;
    end;

// --------------------------------------------------

  _askfile := _nevtabla+inttostr(_qsss);
  _wask := length(_askFile);
  _asknums := midstr(_askFile,5,_wask-4);

  AssignFile(_iras,'c:\UCTRL\DATA\'+_askFile);
  rewrite(_iras);
  Closefile(_iras);

  _localPath := 'c:\UCTRL\DATA\' +_askfile;
  _remotefile := _askFile;
  if not kikuldes(_localPath,_remoteFile) then
    begin
      ShowMessage('NEM SIKERÜLT A KÉRÉST KIKÜLDENI');
      exit;
    end;

  ScanUzenoPanel.caption := 'A kérést kiküldtem a receptornak - Várok';
  ScanUzenoPanel.repaint;

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  // -------------------------------------------------------------------

  _count := 3;
  _siker := False;
  _fdb   := 0;

  while _count>0 do
    begin
      if Beolvasas then
        begin
          _siker := True;
          break;
        end;
      sleep(2500);
      dec(_count);
    end;

  AskFileDelete;

  if not _siker then
    begin

      ScanUzenoPanel.Caption := 'Nem küldte a receptor a kért okmányokat';
      ScanUzenopanel.repaint;



      Sleep(2500);
      ScanAskPanel.Visible := False;
      exit;
    end;
  ShowMessage('A kért okmányokat a C:\UCTRL\DATA könyvtárba másoltam');
end;


// =============================================================================
               function Tform1.FtpOpen(_remdir: string): boolean;
// =============================================================================

begin
  result := False;
  _hnet := InternetOpen('Server',INTERNET_OPEN_TYPE_PRECONFIG,Nil,Nil,0);
  if _hnet=NIL then exit;

  _hFTP := InternetConnect(_hNet,pchar(_host),_ftpPort,pchar(_userId),
             pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  If _hFTP=Nil then
    begin
      InternetCloseHandle(_hNet);
      exit;
    end;

  result := FtpSetCurrentDirectory(_hFTP,pchar(_remdir));
  If not result then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;
end;

// =============================================================================
            function Tform1.Kikuldes(_lpath,_rFile: string): boolean;
// =============================================================================

begin
  result := False;
  if not FtpOpen('\SCANS\ASK') then exit;
  result := FtpPutFile(_hFtp,pchar(_lPath),pchar(_rFile),FTP_TRANSFER_TYPE_BINARY,0);
  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;


// =============================================================================
                     function TForm1.Beolvasas: boolean;
// =============================================================================


var _q: byte;

begin
  result := False;
  _minta := inttostr(_qsss) + '*.JPG';
  if not FtpOpen('\SCANS\OUT') then exit;
  _hSearch := FtpFindFirstFile(_hFTP,pchar(_minta),_findData,0,0);
  if _hSearch=Nil then
     begin
       InternetCloseHandle(_hFTP);
       InternetCloseHandle(_hNet);
       exit;
     end;
  repeat
    inc(_fdb);
    _sFile[_fdb] := _findData.cFilename;
  until not InternetFindNextFile(_hSearch,@_findData);

  InternetCloseHandle(_hsearch);
  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  if _fdb=0 then exit;

  // -------------------------------------------------------------

  if not FtpOpen('\SCANS\OUT') then exit;

  _Q := 1;
  while _q<=_fdb do
    begin
      _localpath := 'c:\UCTRL\DATA\'+_sFile[_q];
      _remoteFile := _sFile[_q];
      result := ftpgetFile(_hFtp,pchar(_remoteFile),pchar(_localPath),
                                           False,0,FTP_TRANSFER_TYPE_BINARY,0);
      IF RESULT then FtpDeleteFile(_hFtp,pchar(_remoteFile));
      inc(_q);
    end;

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;

procedure TForm1.AskfileDelete;

begin
  if not FtpOpen('\SCANS\ASK') then exit;
  ftpdeleteFile(_hftp,pchar(_askfile));

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  sysutils.deletefile('c:\UCTRL\DATA\'+_askfile);
end;


procedure TForm1.IMPORTGOMBClick(Sender: TObject);
begin
  ImportForm.showmodal;
end;

end.
