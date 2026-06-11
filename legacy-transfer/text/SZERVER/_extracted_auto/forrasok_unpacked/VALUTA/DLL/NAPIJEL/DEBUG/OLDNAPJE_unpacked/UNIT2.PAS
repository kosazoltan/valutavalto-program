unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, StrUtils, DateUtils,ShellAPI,
  IBDatabase, DB, IBCustomDataSet, IBTable, ComCtrls, Printers,
  IBQuery, Psock, Grids, Calendar, DBGrids;

type
  TNapiJelentes = class(TForm)

    BlokkQuery         : TIBQuery;
    BlokkDbase         : TIBDatabase;
    BlokkTranz         : TIBTransaction;

    PILLQuery          : TIBQuery;
    PillDbase          : TIBDatabase;
    PillTranz          : TIBTransaction;

    TradeQuery         : TIBQuery;
    TradeDbase         : TIBDatabase;
    TradeTranz         : TIBTransaction;

    ValutaQuery        : TIBQuery;
    ValutaDbase        : TIBDatabase;
    ValutaTranz        : TIBTransaction;

    VQuery             : TIBQuery;
    VDbase             : TIBDatabase;
    VTranz             : TIBTransaction;

    BekuldoGomb        : TBitBtn;
    CancelGomb         : TBitBtn;
    DatumOkeGomb       : TBitBtn;
    Minuszgomb         : TBitBtn;
    PluszGomb          : TBitBtn;
    VisszaGomb         : TBitBtn;

    DuEladasLabel      : TLabel;
    DeVetLabel         : TLabel;
    DuVetLabel         : TLabel;
    DeEladasLabel      : TLabel;
    IroFocim           : TLabel;
    Label1             : TLabel;
    Label2             : TLabel;
    Label3             : TLabel;
    Label4             : TLabel;
    Label5             : TLabel;
    Label6             : TLabel;
    Label7             : TLabel;
    Label8             : TLabel;
    Label9             : TLabel;
    NapiEladasLabel    : TLabel;
    NapiVetelLabel     : TLabel;

    AfaPanel           : TPanel;

    C1Panel            : TPanel;
    C2Panel            : TPanel;
    C3Panel            : TPanel;
    C4Panel            : TPanel;
    C5Panel            : TPanel;
    C6Panel            : TPanel;
    C7Panel            : TPanel;
    C8Panel            : TPanel;
    C9Panel            : TPanel;
    C10Panel           : TPanel;
    C11Panel           : TPanel;
    C12Panel           : TPanel;

    CimletPanel        : TPanel;
    DatumPanel         : TPanel;
    DeProsNevPanel     : TPanel;
    DuProsNevPanel     : TPanel;

    EDePanel           : TPanel;
    EDuPanel           : TPanel;
    Ee1Panel           : TPanel;
    Ee2Panel           : TPanel;
    EgyediPanel        : TPanel;
    EkerErtekPanel     : TPanel;
    ESumPanel          : TPanel;

    EvPanel            : TPanel;
    ForgalomPanel      : TPanel;
    Fuggony            : TPanel;

    HonapPanel         : TPanel;
    InnovaPanel        : TPanel;
    JelszoPanel        : TPanel;

    KeszletPanel       : TPanel;
    KezdijErtekPanel   : TPanel;
    KuldoPanel         : TPanel;

    NaptarPanel        : TPanel;

    Panel1             : TPanel;
    Panel2             : TPanel;
    Panel3             : TPanel;
    Panel4             : TPanel;
    Panel8             : TPanel;
    Panel11            : TPanel;
    Panel92            : TPanel;
    Panel94            : TPanel;
    Panel95            : TPanel;
    Panel98            : TPanel;
    Panel99            : TPanel;
    Panel100           : TPanel;
    Panel101           : TPanel;
    Panel102           : TPanel;
    Panel103           : TPanel;
    Panel104           : TPanel;
    Panel105           : TPanel;
    Panel113           : TPanel;
    Panel116           : TPanel;
    Panel118           : TPanel;
    Panel119           : TPanel;
    Panel120           : TPanel;
    Panel124           : TPanel;
    Panel125           : TPanel;
    Panel128           : TPanel;
    Panel133           : TPanel;
    Panel134           : TPanel;
    Panel135           : TPanel;
    Panel136           : TPanel;
    Panel151           : TPanel;
    Panel152           : TPanel;
    Panel155           : TPanel;
    Panel158           : TPanel;
    Panel162           : TPanel;
    Panel163           : TPanel;
    Panel168           : TPanel;
    Panel171           : TPanel;
    Panel172           : TPanel;
    ProsnevPanel       : TPanel;

    UzenoPanel         : TPanel;
    UzletnevPanel      : TPanel;

    VDePanel           : TPanel;
    VDuPanel           : TPanel;
    VSumPanel          : TPanel;

    WuPanel            : TPanel;
    WuHufPanel         : TPanel;
    WuUsdPanel         : TPanel;

    XArf1Panel         : TPanel;
    XArf2Panel         : TPanel;
    XArf3Panel         : TPanel;
    XArf4Panel         : TPanel;
    XArf5Panel         : TPanel;
    XArf6Panel         : TPanel;
    XArf7Panel         : TPanel;
    XArf8Panel         : TPanel;
    XArf9Panel         : TPanel;
    XArf10Panel        : TPanel;

    XBiz1Panel         : TPanel;
    XBiz2Panel         : TPanel;
    XBiz3Panel         : TPanel;
    XBiz4Panel         : TPanel;
    XBiz5Panel         : TPanel;
    XBiz6Panel         : TPanel;
    XBiz7Panel         : TPanel;
    XBiz8Panel         : TPanel;
    XBiz9Panel         : TPanel;
    XBiz10Panel        : TPanel;

    XSum1Panel         : TPanel;
    XSum2Panel         : TPanel;
    XSum3Panel         : TPanel;
    XSum4Panel         : TPanel;
    XSum5Panel         : TPanel;
    XSum6Panel         : TPanel;
    XSum7Panel         : TPanel;
    XSum8Panel         : TPanel;
    XSum9Panel         : TPanel;
    XSum10Panel        : TPanel;

    XVal1Panel         : TPanel;
    XVal2Panel         : TPanel;
    XVal3Panel         : TPanel;
    XVal4Panel         : TPanel;
    XVal5Panel         : TPanel;
    XVal6Panel         : TPanel;
    XVal7Panel         : TPanel;
    XVal8Panel         : TPanel;
    XVal9Panel         : TPanel;
    XVal10Panel        : TPanel;

    ZaroPanel          : TPanel;
    ZForintPanel       : TPanel;
    ZOsszesPanel       : TPanel;
    ZValutaPanel       : TPanel;

    MemoKerek          : TMemo;
    MemoKuldok         : TMemo;
    MemoTabla          : TMemo;

    IroTimer           : TTimer;
    KilepoTimer        : TTimer;

    JelszoEdit         : TEdit;
    ListBox1           : TListBox;
    Naptar             : TCalendar;
    PillRacs           : TDBGrid;
    PillSource         : TDataSource;

    PillQueryValutaNem          : TIBStringField;
    PillQueryValutaNev          : TIBStringField;
    PillQueryVETELIArfolyam     : TFloatField;
    PillQueryEladasiArfolyam    : TFloatField;
    PillQueryElszamolasiArfolyam: TFloatField;
    PillQueryPenztariAtadas     : TIntegerField;
    PillQueryNyito              : TIntegerField;
    PillQueryBevetel            : TIntegerField;
    PillQueryKiadas             : TIntegerField;
    PillQueryForgalmiEgyenleg   : TIntegerField;
    PillQueryZaro               : TIntegerField;
    PillQueryPenztariAtvetel    : TIntegerField;
    PillQueryVetel              : TIntegerField;
    PillQueryEladas             : TIntegerField;
    PillQueryVetelForint        : TIntegerField;
    PillQueryEladasForint       : TIntegerField;

    // ------------------------------------------

    procedure AlapAdatBeolvasas;
    procedure BekuldoGombClick(Sender: TObject);
    procedure ByteKoder(_b: byte);
    procedure CancelGombClick(Sender: TObject);
    procedure ClearPanels;
    procedure DataLapKIjelzes;
    procedure DatumOkeGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure GetEkerkeszlet;
    procedure IntegKoder(_int: integer);
    procedure IroTimerTimer(Sender: TObject);
    procedure JelentesIras;
    procedure JelszoEditKeyDown(Sender: TObject; var Key: Word;  Shift: TShiftState);
    procedure KerFoglalot;
    procedure KilepoTimerTimer(Sender: TObject);
    procedure MemoAnalizis;
    procedure MemoKerekEnter(Sender: TObject);
    procedure MemoKerekExit(Sender: TObject);
    procedure MinuszGombClick(Sender: TObject);
    procedure PillParancs(_ukaz: string);
    procedure PluszGombClick(Sender: TObject);
    procedure SetValutanem(_deviza: string);
    procedure TextKoder(_t: string);
    procedure TombbeToltes;
    procedure ValutaParancs(_ukaz: string);
    procedure VisszaGombClick(Sender: TObject);
    procedure WordKoder(_w: word);

   // -------------------------------------------

    function Adatmeghatarozas:boolean;
    function CimletBeolvasas(_tnev: string):boolean;
    function ForgalomBeolvasas(_tfarok: string):boolean;
    function KedvezmenyBeolvasas(_tnev:string):boolean;
    function Kerekito(_int: integer): integer;
    function Nulele(_bb:byte):string;
    function ScanNdnem(_valnem: string): byte;
    function SetjelentesPath(_datumstring: string): string;

    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Napijelentes: TNapijelentes;

  _aktPanel: TPanel;

  _honapnev: array[1..12] of string = ('Januar','Februar','Marcius','Aprilis',
                'Majus','Junius','Jukius','Augusztus','Szeptember','Oktober',
                'November','December');

  _nDnem: array[1..28] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                          'CZK','DKK','EUR','EUA','GBP','HRK','HUF','ILS',
                          'JPY','MXN','NOK','NZD','PLN','RON','RSD','RUB',
                          'SEK','THB','TRY','UAH','USD');

  _kerfoglaloPath: string = 'c:\valuta\foglalo\kerfog.txt';
  _sorveg: string = chr(13)+chr(10);

  _dZaro,_sVetel,_sEladas,_tZaro: array[1..28] of Integer;
  _dkeszlet,_dVetel,_dEladas    : array[1..28] of integer;

  _ddnem   : array[1..28] of string;

  _cimlet  : array[1..12] of TPanel;
  _ftcimlet: array[1..12] of integer;

  _xval,_xsum,_xarf,_xbiz: array[1..10] of TPanel;

  _xdnem,_xdbiz   : array[1..10] of string;
  _kersor,_kuldsor: array[1..10] of string;
  _xdsum,_xdkedv  : array[1..10] of integer;
  _byteTomb       : array[1..255] of Byte;

  _olvas,_iras: File of Byte;
  _ketmuszak: boolean;

  _xx,_coin,_hufindex,_kellMatrica,_ertektar,_valutaDarab,_xDarab: byte;
  _pwho,_eho,_r: byte;

  _yev,_yho,_ynap,_homepenztarszam,_top,_left,_height,_width: word;
  _ev,_ho,_nap,_cc,_ee1,_ee2,_vetterme,_ermekeszlet,_aktcimlet: word;

  _zforint,_zValuta,_zOsszes,_aktelszarf,_aktertek,_oFt,_recno,_tesco: integer;
  _ptSzam,_aktvetel,_akteladas,_code,_control,_deProlen,_duProlen,_afa: integer;
  _deVet,_duVet,_deEladas,_duEladas,_aktsum,_aktkedv,_aktbjegy,_metro: integer;
  _wuHuf,_wuUsd,_sumvet,_sumeladas,_aktzaro,_napikezdij,_bankjegy: integer;
  _kermemosor,_kuldmemoSor,_napiekerForint: integer;

  _deProsnev,_duProsnev,_fileNev,_filePath,_ctNev,_jjelszo,_bejelszo: string;
  _homepenztarnev,_aktdnem,_tipus,_bizonylatszam,_elojel,_jelentesPath: string;
  _fejtomb,_tettomb,_jelszokelte,_pcs,_mamas,_farok,_yDAtum: string;
  _yuzletnev,_aktbiz,_aktprosnev,_zDatums,_aktsor: string;


function napijelrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
                 function napijelrutin: integer; stdcall;
// =============================================================================

begin
   NapiJelentes := TNapijelentes.create(Nil);
   result := napijelentes.showmodal;
   napijelentes.Free;
end;

// =============================================================================
             procedure TNAPIJELENTES.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width  := Screen.Monitors[0].Width;
  _height := Screen.Monitors[0].height;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top  := _top;
  Left := _left;

  Height := 768;
  Width := 1024;

  with Fuggony do
    begin
      Top := 0;
      Left := 0;
      Visible := True;
      repaint;
    end;

  AlapadatBeolvasas;

  JelszoPanel.Visible   := False;
  Uzenopanel.Visible    := False;
  Visszagomb.Enabled    := True;

  MemoTabla.Clear;
  IroFocim.Visible := True;

  TombBetoltes;

  _yev := yearof(Date);
  _yHo := monthof(Date);
  _yNap:= dayof(Date);

  Naptar.Year  := _yev;
  Naptar.Month := _yho;
  Naptar.Day   := _ynap;

  evpanel.Caption     := inttostr(_yev);
  HonapPanel.Caption  := _honapnev[_yho];
  NaptarPanel.Visible := True;

  ActiveControl := DatumOkeGomb;
end;

// =============================================================================
          procedure TNapiJelentes.DatumOkeGombClick(Sender: TObject);
// =============================================================================

begin
  _yev     := Naptar.year;
  _yho     := Naptar.Month;
  _ynap    := Naptar.Day;

  _zDatums := inttostr(_yev) + '.' + nulele(_yho) + '.' + nulele(_ynap);

  NaptarPanel.Visible := False;
  IroTimer.Enabled := True;
end;

// =============================================================================
    procedure TNAPIJELENTES.JELSZOEDITKeyDown(Sender: TObject; var Key: Word;
                                                    Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _bejelszo := JelszoEdit.Text;
  if _bejelszo='' then
    begin
      JelszoPanel.Visible := False;
      ModalResult := 2;
      Exit;
    end;

  JelszoPanel.Visible := False;
  _bejelszo := trim(_bejelszo);

  if _eho>_pwho then
    begin
      _pcs := 'UPDATE HARDWARE SET JELSZO='+chr(39)+_bejelszo+chr(39);
      _pcs := _pcs + ',JELSZOKELTE='+chr(39)+_mamas+chr(39);
      ValutaParancs(_pcs);
    end;

  if not AdatMeghatarozas then
    begin
      ModalResult := 2;
      Exit;
    end;

  BekuldoGomb.Visible := true;
  CancelGomb.Visible := true;

  DatalapKijelzes;
end;

// =============================================================================
                  procedure TNAPIJELENTES.DataLapKijelzes;
// =============================================================================

var _q,i: integer;
    _aktdnem,_mondat,_aktdbiz: string;

begin

  for i:= 1 to 10 do
    begin
      _xval[i].Caption := '';
      _xsum[i].Caption := '';
      _xarf[i].Caption := '';
      _xbiz[i].Caption := '';
    end;

  Ee1Panel.Caption := '';
  Ee2Panel.caption := '';

  DatumPanel.Caption    := _yDatum;
  UzletnevPanel.Caption := _yUzletNev;
  zForintPanel.Caption  := Formatfloat('###,###,####',_zForint)+' Ft';
  zValutaPanel.Caption  := FormatFloat('###,###,###',_zValuta)+' Ft';
  zOsszesPanel.Caption  := Formatfloat('###,###,###',_zOsszes)+' Ft';

  // ---------------------------------------------------------------------------

  PillSource.Enabled := false;

  _pcs := 'SELECT * FROM NAPIZAR' + _sorveg;
  _pcs := _pcs + 'WHERE ZARO>0' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  PillDbase.Connected := True;
  with Pillquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  PillSource.Enabled := true;

  Pillparancs('DELETE FROM NAPIZAR');

  _q := 1;
  while _q<=_valutaDarab do
    begin
      _aktdnem := _ddnem[_q];
      _pcs := 'INSERT INTO NAPIZAR (VALUTANEM,VETEL,ELADAS,ZARO)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39)+',';
      _pcs := _pcs + floattostr(_dvetel[_q]) + ',';
      _pcs := _pcs + floattostr( _deladas[_q]) + ',';
      _pcs := _pcs + floattostr(_dKeszlet[_q]) + ')';
      PillParancs(_pcs);
      inc(_q);
    end;

  Pillsource.Enabled := False;
  Pilldbase.Connected := true;
  with Pillquery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM NAPIZAR');
      Open;
      First;
    end;
  Pillsource.Enabled := true;

  // ---------------------------------------------------------------------------

  _ermekeszlet := (2*_ee2)+_ee1;
  EE2Panel.Caption := FormatFloat('###,###,###',_ee2);
  EE1Panel.Caption := FormatFloat('###,###,###',_ee1);
//  K10Panel.Caption := FormatFloat('###,###,###',_ermekeszlet);
//  V10Panel.caption := FormatFloat('###,###,###',_vettErme);

  if _devet>0 then
    DevetLabel.Caption := Formatfloat('###,###,####',_devet)+ ' Ft';

  if _deeladas>0 then
    DeeladasLabel.Caption := Formatfloat('###,###,####',_deeladas)+' Ft';

  if _duvet>0 then
    DuvetLabel.Caption := Formatfloat('###,###,####',_duvet)+ ' Ft';

  if _dueladas>0 then
    DueladasLabel.Caption := Formatfloat('###,###,####',_dueladas)+' Ft';

  _sumvet := _devet+_duvet;
  if _sumvet>0 then
    NapivetelLabel.caption := Formatfloat('###,###,####',_sumvet)+' Ft';

  _sumeladas := _deeladas+_dueladas;
  if _sumeladas>0 then
    NapieladasLabel.Caption := Formatfloat('###,###,####',_sumeladas)+' Ft';

  for i := 1 to 12 do
    begin
      _aktPanel := _cimlet[i];
      _aktPanel.Caption := Formatfloat('###,###,####',_ftCimlet[i]);
    end;

  if _kerMemoSor>0 then
    begin
      for _q := 1 to _kerMemoSor do
        begin
          _mondat := _kersor[_q];
          Memokerek.Lines.Add(_mondat);
        end;
    end;

  if _kuldMemoSor>0 then
    begin
      for _q := 1 to _kuldMemoSor do Memokuldok.Lines.Add(_kuldsor[_q]);
    end;

  WuHufPanel.Caption := FormatFLoat('###,###,####',_wuHuf)+' Ft';
  WuUsdPanel.Caption := '$ ' + FormatFloat('###,###,####',_wuUsd);
  InnovaPanel.Caption := FormatFloat('###,###,####',_afa)+' Ft';

  if _xdarab>0 then
    begin
      if _xdarab>10 then _xdarab := 10;
      _q := 1;
      while _q<=_xdarab do
        begin
          _aktPanel := _xVal[_q];
          _aktpanel.Caption := _xDnem[_q];

          _aktpanel := _xsum[_q];
          _aktpanel.Caption := FormatFloat('###,###,####',_xDsum[_q]);

          _aktpanel := _xarf[_q];
          _aktpanel.Caption := FormatFloat('###,###,####.##',_xDkedv[_q]);

          _aktDbiz := _xdbiz[_q];
          _xbiz[_q].caption := _aktDbiz;;

          inc(_q);
        end;
    end;

  KezdijErtekPanel.Caption := formatfloat('### ### ###',(1*_napikezdij))+' Ft';
  EkerertekPanel.Caption   := FormatFloat('### ### ###',(1*_napiekerforint))+ 'Ft';

  DeprosnevPanel.Caption := _deProsNev;
  DuProsNevPanel.Caption := _duProsnev;
  Fuggony.Visible := False;
end;

// #######################################################################
// =============================================================================
           procedure TNAPIJELENTES.IROTIMERTimer(Sender: TObject);
// =============================================================================
// ======================= EZT HASZNÁLJÁK AZ PÉNZTÁRAK ===================

var _pwHos: string;

begin

  Irotimer.Enabled := False;
  ClearPanels;

  (*
    INFOFILENEV:  SSYYMMDD.NIF
      SS =  A Váltó száma 2 jegyen, ha váltó 3 jegyu, akkor az
            elsö számjegy betü: pl 85 = 85, A4 = 104, B7 = 117, F0 = 150;

      YYMMDD = A NAPI DÁTUM PL. 081130 = 2008 NOVEMBER 30
      kiterjesztés = értéktárszám

     // -----------------------------------------

        NapiInfofile strukturája:

     2 byte: 'NQ' - napiinfo
     3 byte: évtized+64, honap+64, nap+64
     1 byte: Váltónév hossza   (x)
     x byte: 255-valtonev betüi

     5 byte: Záróforint
     5 byte: Záróvaluta
     1 byte: ennyi valutának van zárókészlete: (vx)
     18 * vx darab :
          3 byte: dnem 3 betüje-65;
          5 byte: dnem készlete
          5 byte: dnem vétele
          5 byte: dnem eladása
     5 byte: délelötti vételforgalom
     5 byte: délelötti eladásforgalom
     5 byte: délutáni vételforgalom
     5 byte: délutáni eladásforgalom

     5 byte: vett EURO érme
     5 btye: 1 euros érme darab
     5 byte: 2 Eurós érme darab

     12*2 byte (lo-hi) Ft cimletek
     5 byte: wu-USD készlet
     5 byte: wu-HUF készlet
     5 byte: AFA ft készlet
     1 byte: 0-9 ennyi arfolyam engedmény volt (e) max 10
     20* e byte:
          3 byte: dnem 3 betüje-65
          5 byte: dnem összege
          5 byte: kedv-es árfolyama * 100
          7 byte: bizonylatszam betüi - 48

     Byte: kérek memo sorai:
           (shift= 255-asc)
           1. byte = sorhossz

     Byte: Küldök memo betüszáma:
           (shift= 255-asc)
           1. byte = sorhossz

     5 byte: napi kezelési dij záró
     5 byte: napi elektronikus kereskedés záróösszege

     1 byte: délelötti ptáros nevének betüszáma
            255-A délelötti pénztárosnév betüi
     1 byte: délutáni pénztáros nevének betüszáma
            255-a délutáni pénztáros betüi
     3 byte: 255-255-255 = vége Jel

  *)

  // Meg kell határozni a következő adatokat:
  // _zforint,_zvaluta: a napi zárókészletek

  // _ValutaDarab: ahány valutából van zárókészlet vagy volt forfalom
  //   ahány valuta, annyi készlet, összvétel és összeladás
  //   _ddnem[1..], _dkeszlet[1..], _dvetel[1..], _deladas[1..]

  // _devet,deeladas,duvet,dueladas: a délelötti és délutáni
  // valutavétel és valutaeladás összege: (ha van két pénztáros)
  // ( ha nincs két pénztáros: devet,deeladas = 0)

  // Forintkészlet cimletértékei : _ftCimlet[1..12]

  // _wuUsd, _wuHuf, _afa : western union és afa zárókészletei

  // Arfolyamkedvezmények darabszáma: _xDarab
  //    _xdnem[1..] az engedményes tranzakciók valutaneme (max. 10)
  //    _xdsum[1..] a kiadott bankjegy
  //    _xdkedv[1..] a kedvezményes árfolyamok;
  //    _xdbiz[1..] a kedvezményes bizonylatszámok

  // _kermemosor : ahány sora van a kérelem memonak
  //    _kersor[1..] az aktuális kérés sorainak tartalma

  // _kuldmemosor: ahony sora van a küldés memonak
  //    _kuldsor[1..] az aktuális küédés sorainak tartalma
  // _deProsnev,_duProsnev : a délelötti és délutáni pénztárosok nevei
  // egy müszak esetén _deprosnev= ''

  // ===================================================================

  ValutaDbase.Connected := true;
  _pcs := 'SELECT * FROM HARDWARE';

  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _beJelszo := FieldbyName('JELSZO').asstring;
      _jelszokelte := trim(FieldByName('JELSZOKELTE').asString);
      Close;
    end;
  Valutadbase.close;

  // Ha nincs még jelszó ......
  if _jelszokelte<>'' then
    begin
      if _jelszokelte= '' then _jelszokelte := _mamas;

      _pwhos := midstr(_jelszokelte,6,2);
      val(_pwhos,_pwho,_code);

      _eho := monthof(Date);

      // Ha a jelszó még jó
      if _pwho=_eho then
        begin
          if not AdatMeghatarozas then
             begin
               ModalResult := 2;
               Exit;
             end;
          BekuldoGomb.Visible := true;
          CancelGomb.Visible := true;
          DatalapKijelzes;
          exit;
        end;
    end;

  _pwho:=_eho-1;

  Jelszoedit.clear;
  JelszoPanel.Visible := true;
  ActiveControl := Jelszoedit;

end;


// =============================================================================
                    procedure TNapiJelentes.JelentesIras;
// =============================================================================

var
    i: integer;
    _aktevs,_akthos,_aktnaps: string;
    _aktho,_aktev,_aktnap: word;

begin
  _jelentesPath := SetJelentesPath(_zDatums);

  AssignFile(_iras,_jelentespath);
  Rewrite(_iras);

  ByteKoder(68);
  ByteKoder(65);  // DA = NAPI JELENTÉS ID-KÓDJA

  _aktevs := leftstr(_zDatums,4);
  _akthos := midstr(_zDatums,6,2);
  _aktnaps:= midstr(_zDatums,9,2);

  val(_aktevs,_aktev,_code);
  val(_akthos,_aktho,_code);
  val(_aktnaps,_aktnap,_code);

  ByteKoder(_aktev-2000);
  ByteKoder(_aktho);
  ByteKoder(_aktnap);

  TextKoder(_bejelszo);
  Textkoder(_homepenztarnev);

  IntegKoder(_zForint);
  Integkoder(_zValuta);

  ByteKoder(_valutadarab);

  _r := 1;
  while _r<= _valutaDarab do
    begin
      _aktdnem := _ddnem[_r];
      TextKoder(_aktdnem);

      _aktbjegy := _dkeszlet[_r];
      Integkoder(_aktbjegy);

      _aktvetel := _dVetel[_r];
       Integkoder(_aktvetel);

      _akteladas := _dEladas[_r];
       Integkoder(_akteladas);

       inc(_r);
    end;

  IntegKoder(_devet);
  IntegKoder(_deeladas);

  IntegKoder(_duvet);
  IntegKoder(_dueladas);

  WordKoder(_vettErme);
  wordKoder(_ee1);
  WordKoder(_ee2);

  _r := 1;
  while _r<=12 do
    begin
      _aktcimlet := _ftcimlet[_r];
      wordKoder(_aktCimlet);
      inc(_r);
    end;

  IntegKoder(_wuUsd);
  IntegKoder(_wuHuf);
  IntegKoder(_AFA);

  ByteKoder(_xdarab);
  if _xDarab>0 then
    begin
      _r := 1;
      while _r<=_xDarab do
        begin
          _aktdnem := _xDnem[_r];
          TextKoder(_aktdnem);

          _aktSum := _xdsum[_r];
          IntegKoder(_aktsum);

          _aktKedv := _xdkedv[_r];
          IntegKoder(_aktkedv);

          _aktBiz := _xdbiz[_r];
          TextKoder(_aktbiz);

          inc(_r);
        end;
    end;

// A kér - küld memok analizise

  MemoAnalizis;

  ByteKoder(_kerMemoSor);
  if _kerMemoSor>0 then
    begin
      _r := 1;
      while _r<=_kerMemosor do
        begin
          _aktsor := _kersor[_r];
          textkoder(_aktsor);
          inc(_r);
        end;
    end;

  ByteKoder(_kuldMemoSor);
  if _kuldMemoSor>0 then
    begin
      _r := 1;
      while _r<=_kuldmemosor do
        begin
          _aktsor := _kuldsor[_r];
          textkoder(_aktsor);
          inc(_r);
        end;
    end;

  IntegKoder(_napikezdij);
  IntegKoder(_napiekerforint);

  TextKoder(_deprosnev);
  Textkoder(_duprosnev);

  for i := 1 to 3 do _byteTomb[i] := 255;

  Blockwrite(_iras,_byteTomb,3);
  CloseFile(_iras);
end;


// =============================================================================
          function TNapiJelentes.CimletBeolvasas(_tnev: string):boolean;
// =============================================================================

var i,z: integer;
    _mezonev: string;

begin

  _ee1 := 0;
  _ee2 := 0;

  for i := 1 to 28 do _tzaro[i] := 0;

  _zForint := 0;
  _zValuta := 0;
  for i := 1 to 12 do _ftcimlet[i] := 0;

  Result := False;

  _pcs := 'SELECT * FROM '+ _tNev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+ _zDatums + chr(39);

  Blokkdbase.Connected := true;
  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      BlokkQuery.close;
      BlokkDbase.close;
      Exit;
    end;

  while not BlokkQuery.Eof do
    begin
      _aktdnem := BlokkQuery.FieldByName('VALUTANEM').asString;
      _oFt     := BlokkQuery.FieldByName('OSSZESFORINTERTEK').asInteger;

      if _aktDnem='EUR' then
        begin
          _ee2 := BlokkQuery.FieldByName('CIMLET13').AsInteger;
          _ee1 := BlokkQuery.FieldByName('CIMLET14').AsInteger;
        end;

      if _aktdnem='HUF' then
        begin
          _zforint := _oFt;
          for z := 1 to 12 do
            begin
              _mezonev := 'CIMLET'+inttostr(z);
              _ftCimlet[z] := BlokkQuery.FieldByName(_mezonev).asInteger;
            end;
        end else
        Begin
          SetValutaNem(_aktdnem);
         _zValuta := _zValuta + TRUNC(_aktelszarf/100*_oFt);
        end;

      _xx := scanNdnem(_aktdnem);
      _Tzaro[_xx] := _oft;

      BlokkQuery.Next;
    end;
  BlokkQuery.close;
  Blokkdbase.close;

  _zOsszes := _zValuta + _zForint;
  Result := True;
end;


// =============================================================================
      function TNapiJelentes.ForgalomBeolvasas(_tfarok: string):boolean;
// =============================================================================

var i: integer;

begin
  Result := False;
  _vetterme := 0;

  for i := 1 to 28 do
    begin
      _sVetel[i] := 0;
      _sEladas[i] := 0;
    end;

  _fejTomb := 'BF' + _tFarok;
  _tetTomb := 'BT' + _tFarok;

  _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
  _pcs := _pcs +'FROM '+_fejTomb+' FEJ JOIN '+_tetTomb+' TET'+_sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;

  _pcs := _pcs + 'WHERE (FEJ.DATUM=' + chr(39)+_zDatums+chr(39)+') AND (TET.STORNO=1)';
  _pcs := _pcs + ' AND ((TIPUS=' + chr(39)+'V' + chr(39)+') OR (TIPUS=';
  _pcs := _pcs + chr(39)+'E'+CHR(39)+'))';

  blokkDbase.Connected := True;
  with BlokkQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      Blokkquery.close;
      Blokkdbase.close;
      exit;
    end;

  _deprosnev := Blokkquery.FieldByName('PENZTAROSNEV').asString;

  BlokkQuery.Last;
  _duprosnev := BlokkQuery.FieldByName('PENZTAROSNEV').asString;

  _deprosnev := trim(_deprosnev);
  _duProsnev := trim(_duprosnev);

  _deVet    := 0;
  _duVet    := 0;
  _deEladas := 0;
  _duEladas := 0;

  BlokkQuery.First;
  _ketmuszak := True;

  if _deProsnev=_duProsnev then
    begin
      _deProsnev := '';
      _ketmuszak := False;
    end;

  _hufindex := ScanNDnem('HUF');

  Blokkquery.First;

  while not BlokkQuery.eof do
    begin
      with BlokkQuery do
        begin
          _tipus      := FieldByName('TIPUS').asString;
          _aktdnem    := FieldByName('VALUTANEM').AsString;
          _aktertek   := FieldByNAme('FORINTERTEK').asInteger;
          _bankjegy   := FieldByName('BANKJEGY').asInteger;
          _elojel     := FieldByName('ELOJEL').asstring;
          _coin       := FieldByName('COIN').asInteger;
          _aktprosnev := trim(FieldByName('PENZTAROSNEV').asString);
        end;

       if _aktdnem='HUF' then
         begin
           BlokkQuery.Next;
           Continue;
         end;

       _aktertek := Kerekito(_aktertek);

       if _coin=1 then _vettErme := _vettErme + _bankjegy;

       _xx := ScanNDnem(_aktdnem);
       if (_ketmuszak) and (_aktprosnev<>_duprosnev) then
         begin
           if _elojel='+' then
             begin
               _devet := _devet+_aktertek;
               _sVetel[_xx] := _sVetel[_xx] + _bankjegy;
               _sVetel[_hufindex] := _sVetel[_hufindex] + _aktertek;
             end else
             begin
               _deEladas := _deEladas + _aktertek;
               _sEladas[_xx] := _sEladas[_xx] + _bankjegy;
               _sEladas[_hufindex] := _SEladas[_hufindex] + _aktertek;
             end;
         end else
         begin
           if _elojel='+' then
             begin
               _duvet := _duvet+_aktertek;
               _sVetel[_xx] := _sVetel[_xx] + _bankjegy;
               _sVetel[_hufindex] := _sVetel[_hufindex] + _aktertek;
             end else
             begin
               _duEladas := _duEladas + _aktertek;
               _sEladas[_xx] := _sEladas[_xx] + _bankjegy;
               _sEladas[_hufindex] := _Seladas[_hufindex] + _aktertek;
             end;
         end;
       BlokkQuery.Next;
    end;
  Blokkquery.close;
  Blokkdbase.close;
  Result := True;
end;

// =============================================================================
       function TNapiJelentes.KedvezmenyBeolvasas(_tnev:string):boolean;
// =============================================================================

var _engtipus: integer;
    _lobyte: word;

begin
  Result := False;
  _xDarab := 0;

  BlokkDbase.connected := true;
  _pcs := 'SELECT * FROM ' + _tNev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_ZDatums + chr(39);

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _Recno = 0 then
    begin
      BlokkQuery.Close;
      BlokkDbase.close;
      Exit;
    end;

  while not BlokkQuery.Eof do
    begin
      _EngTipus := BlokkQuery.FieldByNAme('ENGEDMENYTIPUSSZAM').asInteger;
      _lobyte := (_Engtipus AND 255);

      if (_LOBYTE<16) then
        begin
          BlokkQuery.Next;
          Continue;
        end;

      inc(_xDarab);

      with BlokkQuery do
        begin
          _xDnem[_xDarab]  := FieldByName('VALUTANEM').asstring;
          _xdkedv[_xDarab] := FieldByName('UJARFOLYAM').asInteger;
          _xdsum[_xDarab]  := FieldByName('BANKJEGY').asInteger;
          _xdbiz[_xDarab]  := FieldByName('BIZONYLATSZAM').asString;
        end;

      if _xdarab>9 then break;
      BlokkQuery.next;
    end;

  BlokkQuery.Close;
  Blokkdbase.close;

  Result := True;
end;


// =============================================================================
                function TNapiJelentes.Adatmeghatarozas:boolean;
// =============================================================================

var _arfenev: string;
      i: integer;

begin
   // ZaroDString = A napi jelentés dátuma
   Result := False;

  _farok := midstr(_zDatums,3,2)+midstr(_zDatums,6,2);
  _ctnev := 'CIMT'+ _farok;

  // Ha nincs jelentésnapi cimletezés, akkor nincs jelentés se
  if not CimletBeolvasas(_ctNev) then
    begin
      ShowMessage('NEM TALÁLOM A ' + _zDatums + '-I CIMLETEZÉST !');
      exit;
    end;

  // Ha nincs jelentésnapi forgalom, akkor nincs jelentés sem
  if not ForgalomBeolvasas(_farok) then
    begin
      ShowMessage('NEM TALÁLOM A ' + _zDatums + '-I FORGALMAT !');
      exit;
    end;

  _arfenev := 'ARFE'+_FAROK;
  KedvezmenyBeolvasas(_arfenev);

  // Megszámolja, hogy hány valutából volt forgalom:

  _valutaDarab := 0;
  for i:= 1 to 28 do
    begin
      _aktzaro   := _tzaro[i];
      _aktvetel  := _sVetel[i];
      _akteladas := _seladas[i];

      _control := _aktzaro+_aktvetel+_akteladas;
      if _control>0 then inc(_valutaDarab);
    end;

  // Tömbökbe irja a készlet,vétel, és eladás adatait:

  _cc := 0;
  for i:= 1 to 28 do
    begin
      _aktdnem := _nDnem[i];
      _aktzaro := _tzaro[i];
      _aktvetel := _sVetel[i];
      _akteladas := _seladas[i];

      _control := _aktzaro+_aktvetel+_akteladas;

      if _control>0 then
        begin
          inc(_cc);
          _ddnem[_cc] := _aktdnem;
          _dkeszlet[_cc] := _aktzaro;
          _dVetel[_cc] := _aktVetel;
          _dEladas[_cc] := _aktEladas;
        end;
    end;

  if not _ketMuszak then _deprosnev := '';

  _yDatum    := _zDatums;
  _yUzletNev := _homePenztarnev;

  Blokkdbase.Connected := true;

  _pcs := 'SELECT * FROM WZAR' + _farok + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _zDatums + chr(39);

  with BlokkQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _wuUsd := FieldByName('USDZARO').asInteger;
      _wuHuf := FieldByName('HUFZARO').asInteger;
      _metro := FieldByName('METROZARO').asInteger;
      _tesco := FieldByNAme('TESCOZARO').asInteger;
      Close;
    end;
  BlokkDbase.close;

  _afa := _metro + _tesco;

  _pcs := 'SELECT * FROM NAPIKEZELESIDIJ' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _zDatums + chr(39);

  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _napikezdij := FieldByName('ZARO').asInteger;
      Close;
    end;
  Valutadbase.close;

  Getekerkeszlet;

  Result := true;
end;

// =============================================================================
          procedure TNAPIJELENTES.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  Uzenopanel.Visible := false;
  KilepoTimer.Enabled := false;
  ModalResult := 1;
end;

// =============================================================================
              procedure TNAPIJELENTES.CANCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := true;
end;

// =============================================================================
            procedure TNAPIJELENTES.BEKULDOGOMBClick(Sender: TObject);
// =============================================================================

begin
  JelentesIras;
  ShowMessage('A NAPI JELENTÉS KÜLDÉSRE ELÖKÉSZITVE !');
  ModalResult := 1;
end;

// =============================================================================
         procedure TNAPIJELENTES.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Visszagomb.Enabled := false;
  KilepoTimer.Enabled := True;
end;

// =============================================================================
           procedure TNAPIJELENTES.minuszgombClick(Sender: TObject);
// =============================================================================

begin
  dec(_yho);
  if _yho=0 then
    begin
      dec(_yev);
      _yho := 12
    end;

  Naptar.Year := _yev;
  Naptar.Month := _yho;
  Evpanel.Caption := inttostr(_yev);
  HonapPanel.Caption := _honapnev[_yho];
  ActiveControl := DatumOkeGomb;
end;

// =============================================================================
           procedure TNAPIJELENTES.PLUSZGOMBClick(Sender: TObject);
// =============================================================================

begin
  inc(_yho);
  if _yho>12 then
    begin
      inc(_yev);
      _yho := 1;
    end;

  Naptar.Year := _yev;
  Naptar.Month := _yho;
  Evpanel.Caption := inttostr(_yev);
  HonapPanel.Caption := _honapnev[_yho];
  ActiveControl := DatumOkeGomb;
end;

// =============================================================================
                     procedure TNAPIJELENTES.ClearPanels;
// =============================================================================

var i: integer;

begin

  EE1Panel.Caption := '';
  EE2Panel.Caption := '';

  for i := 1 to 12 do
    begin
      _aktPanel := _cimlet[i];
      _aktpanel.Caption := '-';
    end;

   for i := 1 to 10 do
     begin
       _aktpanel := _xval[i];
       _aktpanel.Caption := '-';

       _aktpanel := _xsum[i];
       _aktpanel.Caption := '-';

       _aktpanel := _xbiz[i];
       _aktpanel.Caption := '-';

       _aktpanel := _xarf[i];
       _aktPanel.Caption := '-';
     end;

   DatumPanel.Caption := '-';
   UzletnevPanel.Caption := '-';

   ZForintPanel.Caption := '-';
   ZValutaPanel.Caption := '-';
   zOsszesPanel.Caption := '-';

   deVetLabel.caption := '-';
   duVetLabel.Caption := '-';

   deEladasLabel.Caption := '-';
   duEladasLabel.Caption := '-';

   NapiVetelLabel.Caption := '-';
   NapiEladasLabel.Caption := '-';
   MemoKerek.Clear;
   if FileExists(_kerfoglaloPath) then Kerfoglalot;
   MemoKuldok.clear;

   WuHufPanel.Caption := '-';
   WuUsdPanel.Caption := '-';
   InnovaPanel.Caption := '-';
   DeprosnevPanel.caption := '-';
   DuProsnevPanel.Caption := '-';

   MemoKuldok.Clear;

   if MemoKerek.Lines.Count=0 then Memokerek.Lines.Add('KÉREK:');
   Memokuldok.Lines.Add('KÜLDÖK:');
end;

procedure TnapiJelentes.Kerfoglalot;

var _textOlvas: textFile;
    _mondat : string;

begin
  if not fileExists(_kerfoglaloPath) then exit;
  AssignFile(_textolvas,_kerfoglaloPath);
  Reset(_textolvas);
  readln(_textolvas,_mondat);
  CloseFile(_textOlvas);
  Memokerek.Lines.Add('KÉREK:');
  Memokerek.Lines.Add(' ');
  Memokerek.Lines.add(_mondat);
  Deletefile(_kerfoglaloPath);
end;

// =============================================================================
             procedure TNAPIJELENTES.MEMOKEREKEnter(Sender: TObject);
// ==================================================================(==========

begin
 Tmemo(sender).Color := clYellow;
end;

// =============================================================================
            procedure TNAPIJELENTES.MEMOKEREKExit(Sender: TObject);
// =============================================================================

begin
  Tmemo(sender).Color := clWindow;
end;

// =============================================================================
         function TNAPIJELENTES.ScanNdnem(_valnem: string): byte;
// =============================================================================

var k: byte;

begin
  result := 0;
  for k := 1 to 28 do
    begin
      if _Ndnem[k]= _valnem then
        begin
          result := k;
          break;
        end;
    end;
end;

// =============================================================================
               function TNAPIJELENTES.Nulele(_bb:byte):string;
// =============================================================================

begin
  result := inttostr(_bb);
  if _bb<10 then result := '0' + result;
end;

// =============================================================================
             procedure TNapijelentes.PillParancs(_ukaz: string);
// =============================================================================

begin
  Pilldbase.Connected := true;
  if pilltranz.InTransaction then Pilltranz.Commit;
  Pilltranz.StartTransaction;
  with Pillquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Pilltranz.commit;
  Pilldbase.close;
end;

// =============================================================================
                        procedure TNapiJelentes.GetEkerkeszlet;
// =============================================================================

begin

  _napiekerforint := 0;
  if (_kellMatrica=1) then
    begin
      tradedbase.close;
      tradeDbase.DatabaseName := 'c:\valuta\database\trade.fdb';
      tradeDbase.Connected := True;
      with TradeQuery do
        begin
          Close;
          sql.Clear;
          Sql.Add('SELECT * FROM PARAMETERS');
          Open;
          _napiekerforint := FieldByName('PILLALLAS').asInteger;
          Close;
        end;
      Tradedbase.close;
    end;
end;

// =============================================================================
                    procedure Tnapijelentes.AlapadatBeolvasas;
// =============================================================================

var _yevs,_yhos,_ynaps,_ptarnums: string;

begin
  valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _mamas:= trim(FieldByNAme('MEGNYITOTTNAP').AsString);
      _kellmatrica := FieldByName('KELLMATRICA').asInteger;
      _ertektar := FieldByNAme('ERTEKTAR').asInteger;
      Close;

      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _zDatums := trim(FieldByNAme('DATUM').AsString);
      Close;

      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _ptarnums := trim(FieldbyName('PENZTARKOD').AsString);
      _homepenztarnev := trim(FieldByName('PENZTARNEV').AsString);
      Close;
    end;

  Valutadbase.close;

  val(_ptarnums,_homePenztarszam,_code);

  _yevs  := leftstr(_zDatums,4);
  _yHos  := midstr(_zDatums,6,2);
  _yNaps := midstr(_zDatums,9,2);

  val(_yevs,_yev,_code);
  val(_yhos,_yho,_code);
  val(_ynaps,_ynap,_code);
end;


// =============================================================================
             procedure TNapijelentes.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.connected := true;
  if valutatranz.InTransaction then valutatranz.commit;
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
           function TNapiJelentes.Kerekito(_int: integer): integer;
// =============================================================================

var _nums: string;
    _utdig,_wnums: Byte;

begin
  result := _int;
  _nums  := intToStr(_int);
  _wNums := length(_nums);
  _utDig := ord(_nums[_wNums])-48;

  if (_utDig<>0) and (_utDig<>5) then
    begin
      if (_utDig=1) or (_utDig=2) then result := _int-_utDig;
      if (_utDig=6) or (_utDig=7) then result := _int-(_utDig-5);
      if (_utDig=3) or (_utDig=4) then result := _int+(5-_utDig);
      if (_utDig=8) or (_utDig=9) then result := _int+10-_utDig;
    end;
end;



// =============================================================================
        function TNapijelentes.SetjelentesPath(_datumstring: string): string;
// =============================================================================


var _tizes,_egyes,_ptszam: integer;
    _dats,_ptsz,_jfile: string;


begin
  _ptSzam := _homePenztarszam;
  _tizes := trunc(_ptszam/10);
  _egyes := _ptszam - trunc(10*_tizes);
  if _tizes>9 then  _tizes := _tizes + 7;

  _ptsz := chr(_tizes+48)+chr(_egyes+48);
  _dats := midstr(_datumstring,3,2)+midstr(_datumstring,6,2)+midstr(_datumstring,9,2);

  _jfile := _ptsz + _dats + '.'+inttostr(_ertektar);
  Result := 'C:\VALUTA\JELENTES\'+_jFile;
end;

// =============================================================================
          procedure TNapijelentes.SetValutanem(_deviza: string);
// =============================================================================

begin

  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39)+_deviza+chr(39);

  Vdbase.connected :=true;
  with vquery do
    begin
      close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _aktelszarf := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
      Close;
    end;
  Vdbase.close;

end;

//******************************************************************************
//                                                                            **
//                         KÓDEREK                                            **
//                                                                            **
//******************************************************************************
// =============================================================================
              procedure TnapiJelentes.IntegKoder(_int: integer);
// =============================================================================

var _a1,_a2,_a3,_a4: byte;
    _remain : integer;

begin
  _a4 := trunc(_int/16777216);

  _remain := _int-trunc(_a4*16777216);
  _a3 := trunc(_remain/65536);

  _remain := _remain-trunc(_a3*65536);
  _a2 := trunc(_remain/256);

  _remain := _remain-trunc(_a2*256);
  _a1 := trunc(_remain);

  _bytetomb[1] := _a1;
  _bytetomb[2] := _a2;
  _bytetomb[3] := _a3;
  _bytetomb[4] := _a4;

  Blockwrite(_iras,_bytetomb,4);
end;

// =============================================================================
               procedure TNapiJelentes.TextKoder(_t: string);
// =============================================================================

var _tlen,_asc,k: byte;

begin
  _t := trim(_t);
  _tlen := length(_t);

  ByteKoder(_tlen);
  if _tlen=0 then exit;

  k := 1;
  while k<=_tLen do
    begin
      _asc := ord(_t[k]);
      _bytetomb[k] := 255-_asc;
      inc(k);
    end;

  BlockWrite(_iras,_bytetomb,_tLen);
end;

// =============================================================================
                  procedure TNapijelentes.WordKoder(_w: word);
// =============================================================================

var _hi,_lo: byte;

begin
  _hi := trunc(_w/256);
  _lo := _w-trunc(256*_hi);

  _bytetomb[1] := _lo;
  _bytetomb[2] := _hi;

  BlockWrite(_iras,_bytetomb,2);
end;

// =============================================================================
                 procedure Tnapijelentes.ByteKoder(_b: byte);
// =============================================================================

begin
  _bytetomb[1] := _b;
  Blockwrite(_iras,_bytetomb,1);
end;

// =============================================================================
                    procedure TnapiJelentes.MemoAnalizis;
// =============================================================================

begin
  _kermemosor := MemoKerek.Lines.Count;
  if _kermemosor>0 then
    begin
      _r := 1;
      _cc := 0;
      while _r<=_kermemosor do
        begin
          _aktsor := trim(MemoKerek.Lines[_r]);
          if _aktsor<>'' then
            begin
              inc(_cc);
              _kersor[_cc] := _aktsor;
            end;
          inc(_r);
        end;
      _kermemosor := _cc;
    end;

  MemoKuldok.Refresh;

  _kuldmemosor := MemoKuldok.Lines.Count;
  if _kuldmemosor>0 then
    begin
      _r := 1;
      _cc := 0;
      while _r<=_kuldMemosor do
        begin
          _aktsor := trim(MemoKuldok.Lines[_r]);
          if _aktsor<>'' then
            begin
              inc(_cc);
              _kuldsor[_cc] := _aktsor;
            end;
          inc(_r);
        end;
      _kuldmemosor := _cc;
    end;
end;

// =============================================================================
                    procedure TNapiJelentes.TombbeToltes;
// =============================================================================

begin
  _cimlet[1]  := C1Panel;
  _cimlet[2]  := C2Panel;
  _cimlet[3]  := C3Panel;
  _cimlet[4]  := C4Panel;
  _cimlet[5]  := C5Panel;
  _cimlet[6]  := C6Panel;
  _cimlet[7]  := C7Panel;
  _cimlet[8]  := C8Panel;
  _cimlet[9]  := C9Panel;
  _cimlet[10] := C10Panel;
  _cimlet[11] := C11Panel;
  _cimlet[12] := C12Panel;

  _xval[1]  := xval1Panel;
  _xval[2]  := xval2Panel;
  _xval[3]  := xval3Panel;
  _xval[4]  := xval4Panel;
  _xval[5]  := xval5Panel;
  _xval[6]  := xval6Panel;
  _xval[7]  := xval7Panel;
  _xval[8]  := xval8Panel;
  _xval[9]  := xval9Panel;
  _xval[10] := xval10Panel;

  _xsum[1]  := xsum1Panel;
  _xsum[2]  := xsum2Panel;
  _xsum[3]  := xsum3Panel;
  _xsum[4]  := xsum4Panel;
  _xsum[5]  := xsum5Panel;
  _xsum[6]  := xsum6Panel;
  _xsum[7]  := xsum7Panel;
  _xsum[8]  := xsum8Panel;
  _xsum[9]  := xsum9Panel;
  _xsum[10] := xsum10Panel;

  _xarf[1]  := xarf1Panel;
  _xarf[2]  := xarf2Panel;
  _xarf[3]  := xarf3Panel;
  _xarf[4]  := xarf4Panel;
  _xarf[5]  := xarf5Panel;
  _xarf[6]  := xarf6Panel;
  _xarf[7]  := xarf7Panel;
  _xarf[8]  := xarf8Panel;
  _xarf[9]  := xarf9Panel;
  _xarf[10] := xarf10Panel;

  _xbiz[1]  := xbiz1Panel;
  _xbiz[2]  := xbiz2Panel;
  _xbiz[3]  := xbiz3Panel;
  _xbiz[4]  := xbiz4Panel;
  _xbiz[5]  := xbiz5Panel;
  _xbiz[6]  := xbiz6Panel;
  _xbiz[7]  := xbiz7Panel;
  _xbiz[8]  := xbiz8Panel;
  _xbiz[9]  := xbiz9Panel;
  _xbiz[10] := xbiz10Panel;
end;

end.
