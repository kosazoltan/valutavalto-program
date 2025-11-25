unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, StrUtils, DateUtils,ShellAPI,
  IBDatabase, DB, IBCustomDataSet, IBTable, ComCtrls, Printers,
  IBQuery, Psock, Grids, Calendar, DBGrids;

type
  TNAPIJELENTES = class(TForm)

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
    Cim1Panel          : TPanel;
    Cim2Panel          : TPanel;
    Cim3Panel          : TPanel;
    Cim4Panel          : TPanel;
    Cim5Panel          : TPanel;
    Cim6Panel          : TPanel;
    Cim7Panel          : TPanel;
    Cim8Panel          : TPanel;
    Cim9Panel          : TPanel;
    Cim10Panel         : TPanel;
    Cim11Panel         : TPanel;
    Cim12Panel         : TPanel;
    CimletPanel        : TPanel;
    Coin1Panel         : TPanel;
    Coin2Panel         : TPanel;
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
    PDePanel           : TPanel;
    PDuPanel           : TPanel;
    ProsNevPanel       : TPanel;
    R1Panel            : TPanel;
    R2Panel            : TPanel;
    R3Panel            : TPanel;
    R4Panel            : TPanel;
    R5Panel            : TPanel;
    R6Panel            : TPanel;
    R7Panel            : TPanel;
    R8Panel            : TPanel;
    R9Panel            : TPanel;
    R10Panel           : TPanel;
    UzenoPanel         : TPanel;
    UzletNevPanel      : TPanel;
    VDePanel           : TPanel;
    VDuPanel           : TPanel;
    VSumPanel          : TPanel;
    WuHufPanel         : TPanel;
    WuPanel            : TPanel;
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
    XVal2Panel         : TPanel;
    XVal3Panel         : TPanel;
    XVal1Panel         : TPanel;
    XVal4Panel         : TPanel;
    XVal5Panel         : TPanel;
    XVal6Panel         : TPanel;
    XVal7Panel         : TPanel;
    XVal8Panel         : TPanel;
    XVal9Panel         : TPanel;
    XVal10Panel        : TPanel;
    Y1Panel            : TPanel;
    Y2Panel            : TPanel;
    Y3Panel            : TPanel;
    Y4Panel            : TPanel;
    Y5Panel            : TPanel;
    Y6Panel            : TPanel;
    Y7Panel            : TPanel;
    Y8Panel            : TPanel;
    Y9Panel            : TPanel;
    Y10Panel           : TPanel;
    Y11Panel           : TPanel;
    Y12Panel           : TPanel;
    ZaroPanel          : TPanel;
    ZForintPanel       : TPanel;
    ZOsszesPanel       : TPanel;
    ZValutaPanel       : TPanel;

    DeEladasLabel      : TLabel;
    DeVetLabel         : TLabel;
    DuEladasLabel      : TLabel;
    DuVetLabel         : TLabel;
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
    OlvasoFocim        : TLabel;
    MASIKIRODAGOMB: TBitBtn;
    NyomtatasGomb      : TBitBtn;
    DatumOkeGomb       : TBitBtn;
    MinuszGomb         : TBitBtn;
    PluszGomb          : TBitBtn;
    VisszaGomb         : TBitBtn;

    FejSource          : TDataSource;

    JelszoEdit         : TEdit;

    PrinterSetupDialog1: TPrinterSetupDialog;

    ListBox1           : TListBox;

    Naptar             : TCalendar;

    MemoKerek          : TMemo;
    MemoKuldok         : TMemo;
    MemoTabla          : TMemo;

    KilepoTimer        : TTimer;

    BfTabla            : TIBTable;
    BFQuery            : TIBQuery;
    BfDbase            : TIBDatabase;
    BfTranz            : TIBTransaction;

    BtTabla            : TIBTable;
    BTQuery            : TIBQuery;
    BtDbase            : TIBDatabase;
    BtTranz            : TIBTransaction;

    PillRacs           : TDBGrid;
    PillQuery          : TIBQuery;
    PillDbase          : TIBDatabase;
    PillTranz          : TIBTransaction;
    PillSource         : TDataSource;

    PillQueryVetel     : TIntegerField;
    PillQueryEladas    : TIntegerField;
    PillQueryZaro      : TIntegerField;
    PillQueryValutanem : TIBStringField;

    ValutaQuery        : TIBQuery;
    ValutaDbase        : TIBDatabase;
    ValutaTranz        : TIBTransaction;
    ValDataQuery       : TIBQuery;

    ValDataDbase       : TIBDatabase;
    ValDataTranz       : TIBTransaction;
    ValDataTabla       : TIBTable;

    VQuery             : TIBQuery;
    VDbase             : TIBDatabase;
    VTranz             : TIBTransaction;
    Shape1: TShape;
    CHFPANEL: TPanel;
    Label10: TLabel;
    CHFLABEL: TLabel;


    procedure FormActivate(Sender: TObject);

    procedure DataLapClear;
    procedure DataLapDisplay;
    procedure MemoKerekEnter(Sender: TObject);
    procedure MemoKerekExit(Sender: TObject);
    procedure AlapAdatBeolvasas;
    procedure EgyjelentesOlvasas;
    procedure Kivilagositas;
    procedure Kiszinezes;
    procedure EgyirodaJelentese;
    procedure PagesAppear;
    procedure ValutaParancs(_ukaz: string);
    procedure TombBeToltes;
    procedure KilepoTimerTimer(Sender: TObject);
    procedure CancelGombClick(Sender: TObject);
    procedure JelentesExit;
    procedure JelszoEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure NyomtatasGombClick(Sender: TObject);
    procedure VisszaGombClick(Sender: TObject);
    procedure MinuszGombClick(Sender: TObject);
    procedure PluszGombClick(Sender: TObject);
    procedure DatumOkeGombClick(Sender: TObject);
    procedure PillParancs(_ukaz: string);
    procedure SetValutanem(_deviza: string);
    procedure MasikIrodaGombClick(Sender: TObject);


    function ArfForm(_arf: integer): string;
    function DataKibonto(_napijelPath: string):boolean;
    function GetByte: byte;
    function GetDnem: string;
    function GetWord: word;
    function GetInteger: integer;
    function GetString: string;
    function FtForm(_i: integer): string;
    function SetjelentesPath(_datumstring: string): string;
    function Nulele(_b:byte):string;
    function Vbetuout(_s: string): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NAPIJELENTES: TNAPIJELENTES;

   _olvas   : File of Byte;
   _rendiras: textFile;

  _honapnev: array[1..12] of string = ('Január','Február','Március','Április',
                'Május','Junius','Július','Augusztus','Szeptember','Október',
                'November','December');

  _nDnem: array[1..28] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                          'CZK','DKK','EUR','EUA','GBP','HRK','HUF','ILS',
                          'JPY','MXN','NOK','NZD','PLN','RON','RSD','RUB',
                          'SEK','THB','TRY','UAH','USD');

  _yPanel,_cPanel: array[1..14]of TPanel;

  _kerfoglaloPath: string = 'c:\ERTEKTAR\foglalo\kerfog.txt';

  _aktPanel: TPanel;

  _aPanel: array[1..6] of Tpanel;
  _rPanel: array[1..10] of TPanel;
  _sorveg: string = chr(13)+chr(10);

  _byteTomb                 : array[1..4096] of Byte;

  _kedvDnem,_kedvBizonylat  : array[1..10] of string;
  _kedvBjegy,_kedvarf       : array[1..10] of integer;

  _ddnem                    : array[1..27] of string;
  _dKeszlet,_dVetel,_dEladas: array[1..27] of integer;

  _cimlet                   : array[1..12] of TPanel;
  _xval,_xsum,_xarf,_xbiz   : array[1..10] of TPanel;

  _ftcimlet                 : array[1..12] of integer;

  _kerSor,_kuldsor          : array[1..9] of string;

  _dZaro: array[1..28] of Integer;

  _b1,_b2,_b3,_z,_kedvDarab,_kersordarab,_kuldSorDarab,_y: byte;
  _XX,_coin,_hufindex,_kellMatrica,_ertektar: byte;

  _pp,_ctrl,_ee1,_ee2,_aktword,_aktev,_aktho,_aktnap: word;
  _yev,_yho,_ynap,_homepenztarszam,_ev,_ho,_nap,_cc: word;
  _top,_left,_height,_width: word;

  _aktinteger,_aktkeszlet,_regisvajcifrank,_rByte,_aktvarf: integer;
  _zforint,_zValuta,_zOsszes,_aktelszarf,_aktertek,_aktearf: integer;
  _deVet,_duVet,_deEladas,_duEladas,_aktsum,_aktkedv,_aktbjegy: integer;
  _wuHuf,_wuUsd,_afa,_sumvet,_sumeladas,_metro,_tesco,_aktvetel: integer;
  _valtoNevHossz,_valutaDarab,_fileDb,_ptszam,_lenkodtxt,_oFt: integer;
  _kermemosor,_kuldmemoSor,_deProlen,_duProlen,_code,_akteladas: integer;
  _xdarab,_aktcimlet,_bankjegy,_pwho,_eho,_aktZaro,_control: integer;
  _napikezdij,_napiekerForint,_recno,_vetterme,_ermekeszlet: integer;

  _deProsnev,_duProsnev,_fileNev,_filePath,_ctNev,_jjelszo,_bejelszo: string;
  _homepenztarnev,_aktdnem,_tipus,_bizonylatszam,_elojel: string;
  _yDatum,_yuzletnev,_idJel,_aktbiz,_aktprosnev,_farok,_aktdnev: string;
  _zDatums,_aktNifFileNev,_pcs,_jelszokelte,_jelentesPath: string;
  _megnyitottnap,_homepenztarkod,_aktstring,_rsfs: string;

  _ketmuszak: boolean;


function nifvalasztorutin: integer; stdcall; external 'c:\ERTEKTAR\bin\nifval.dll';
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
             procedure TNapiJelentes.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width  := Screen.Monitors[0].Width;
  _height := Screen.Monitors[0].height;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top  := _top;
  Left := _left;

  Height := 760;
  Width := 1020;
  chfpanel.Visible := False;

  _bejelszo := '';

  MemoTabla.Clear;
  with Fuggony do
    begin
      Top     := 0;
      Left    := 0;
      Visible := True;
    end;

  _aktev  := yearof(date);
  _aktho  := monthof(date);
  _aktnap := dayof(date);

  Naptar.Year  := _aktEv;
  Naptar.Month := _aktHo;
  Naptar.Day   := _aktNap;

  AlapadatBeolvasas;

  JelszoPanel.Visible := False;
  Uzenopanel.Visible  := False;
  Visszagomb.Enabled  := True;

  TombBeToltes;

  Evpanel.Caption     := inttostr(_aktev);
  HonapPanel.Caption  := _honapnev[_aktho];
  NaptarPanel.Visible := True;

  ActiveControl := DatumOkeGomb;
end;

// ======================================================================
        procedure TNapiJelentes.DatumOkeGombClick(Sender: TObject);
// ======================================================================

begin
  _yev     := Naptar.year;
  _yho     := Naptar.Month;
  _ynap    := Naptar.Day;
  _zDatums := inttostr(_yev) + '.' + nulele(_yho) + '.' + nulele(_ynap);

  NaptarPanel.Visible := False;
  EgyIrodaJelentese;

end;


// =============================================================================
                procedure TNAPIJELENTES.Egyirodajelentese;
// =============================================================================

begin
  Pillquery.close;
  Pilldbase.close;

  with Fuggony do
    begin
      Top     := 0;
      Left    := 0;
      Visible := True;
      repaint;
    end;

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (DATUM) VALUES ('+chr(39)+_zDatums+chr(39)+')';
  ValutaParancs(_pcs);
  EgyjelentesOlvasas;
end;

// =============================================================================
                procedure TNapiJelentes.EgyjelentesOlvasas;
// =============================================================================

var _oke: integer;
    _foc: string;

begin

  _oke := nifvalasztorutin;
  if _oke <>1 then
    begin
      JelentesExit;
      Exit;
    end;

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM MEDIA');
      Open;
      _aktNifFileNev := trim(FieldByNAme('STTFILE').AsString);
      Close;
    end;
  Valutadbase.close;

  _filePath := 'C:\ERTEKTAR\JELENTES\' + _AktNifFileNev;

  _foc := leftstr(_aktNifFilenev,2)+'. számu váltó 20';
  _foc := _foc + midstr(_aktNifFileNev,3,2)+'.'+midstr(_aktNifFilenev,5,2)+'.'+midstr(_aktnifFilenev,7,2);

  NapiJelentes.Caption := _foc+'-i napi jelentése';
  if not DataKibonto(_filePath) then
    begin
      ShowMessage('AZ INFORMÁCIÓS FILE HIBÁS ! NEM LEHET ÉRTELMEZNI !');
      EgyJelentesOlvasas;
      Exit;
    end;

  // itt kell bekérni a passwordot

  if _bejelszo='' then
   begin
      JelszoEdit.Clear;
      Jelszopanel.Visible := True;
      ActiveControl := JelszoEdit;
    end else
   begin
     PagesAppear;
      DataLapDisplay;
   end;

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
  _bejelszo := vbetuout(_bejelszo);

  if _jjelszo<>_bejelszo then
    begin
      ShowMessage('A MEGADOTT JELSZÓ NEM MEGFELELÕ !');
      ModalResult := 2;
      Exit;
    end;

  PagesAppear;
  DataLapDisplay;
end;



// ========================================================================
          procedure TNAPIJELENTES.CANCELGOMBClick(Sender: TObject);
// ========================================================================

begin
  KilepoTimer.Enabled := true;
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
  dec(_aktho);
  if _aktho=0 then
    begin
      dec(_aktev);
      _aktho := 12
    end;

  Naptar.Year := _aktev;
  Naptar.Month := _aktho;
  Evpanel.Caption := inttostr(_aktev);
  HonapPanel.Caption := _honapnev[_aktho];
  ActiveControl := DatumOkeGomb;
end;

// =============================================================================
           procedure TNAPIJELENTES.PLUSZGOMBClick(Sender: TObject);
// =============================================================================

begin
  inc(_aktho);
  if _aktho>12 then
    begin
      inc(_aktev);
      _aktho := 1;
    end;

  Naptar.Year := _aktev;
  Naptar.Month := _aktho;
  Evpanel.Caption := inttostr(_aktev);
  HonapPanel.Caption := _honapnev[_aktho];
  ActiveControl := DatumOkeGomb;
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
  Result := 'C:\ERTEKTAR\JELENTES\'+_jFile;
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
      _aktDnev    := trim(FieldByNAme('VALUTANEV').asString);
      _aktVarf    := FieldByNAme('VETELIARFOLYAM').asInteger;
      _aktEarf    := FieldByNAme('ELADASIARFOLYAM').asInteger;
      _aktelszarf := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
      Close;
    end;
  Vdbase.close;

end;

// =============================================================================
                  procedure TNapijelentes.Kivilagositas;
// =============================================================================

var _aktPanel: TPanel;

begin
  _y := 1;
  while _y<=14 do
    begin
      _aktpanel := _yPanel[_y];
      _aktPanel.color := clWhite;
      _aktPanel.Repaint;

      _aktpanel := _cPanel[_y];
      _aktPanel.color := clWhite;
      _aktPanel.Repaint;

      inc(_y);
    end;

  _y := 1;
  while _y<=6 do
    begin
      _aktpanel := _aPanel[_y];
      _aktpanel.color := clWhite;
      _aktPanel.repaint;
      inc(_y);
    end;

  _y := 1;
  while _y<=10 do
    begin
      _aktPanel := _rPanel[_y];
      _aktpanel.color := clWhite;
      _aktpanel.Font.color := clBlack;
      _aktpanel.Repaint;
      inc(_y);
    end;

  KuldoPanel.Color := clWhite;
  KuldoPanel.repaint;
  MasikIrodagomb.visible := false;
  Nyomtatasgomb.visible := False;
  MasikIrodaGomb.repaint;
  NyomtatasGomb.Repaint;
end;





// =============================================================================
                       function Tnapijelentes.getword: word;
// =============================================================================

begin
  _b1 := getbyte;
  _b2 := getbyte;
  result := _b1+trunc(256*_b2);
end;

// =============================================================================
                        FUNCTIOn Tnapijelentes.getbyte: byte;
// =============================================================================

begin
  result := _bytetomb[_pp];
  inc(_pp);
end;



// =============================================================================
                       function Tnapijelentes.getstring: string;
// =============================================================================

var _bdb: word;

begin
  result := '';
  _bdb := getbyte;
  if _bdb=0 then exit;
  _cc := 1;
  while _cc<=_bdb do
    begin
      _b1 := 255-getbyte;
      result := result + chr(_b1);
      inc(_cc);
    end;
end;

// =============================================================================
                    function Tnapijelentes.Getinteger: integer;
// =============================================================================

var _b1,_b2,_b3,_b4: byte;
    _res: real;

begin
  _b1 := getbyte;
  _b2 := getbyte;
  _b3 := getbyte;
  _b4 := getbyte;
  _res := (16777216*_b4)+(65536*_b3)+(256*_b2)+_b1;
  result := trunc(_res);
end;




// =============================================================================
                  procedure Tnapijelentes.DataLapClear;
// =============================================================================

begin
  DatumPanel.Caption      := '';
  UzletnevPanel.Caption   := '';
  zForintPanel.Caption    := '';
  zValutaPanel.Caption    := '';
  zOsszesPanel.Caption    := '';

  DeVetLabel.Caption      := '';
  DeEladasLabel.Caption   := '';
  DuVetLabel.Caption      := '';
  DuEladasLabel.Caption   := '';

  NapiVetelLabel.Caption  := '';
  NapiEladasLabel.Caption := '';

  _z := 1;
  while _z<=12 do
    begin
      _cimlet[_z].Caption := '';
      inc(_z);
    end;

  ee1Panel.Caption := '';
  ee2Panel.Caption := '';

  _z := 1;
  while _z<=10 do
    begin
      _xVal[_z].Caption := '';
      _xSum[_z].Caption := '';
      _xArf[_z].Caption := '';
      _xBiz[_z].Caption := '';
      inc(_z);
    end;

  MemoKuldok.Lines.Clear;
  MemoKuldok.Clear;
  MemoKuldok.Lines.Add('KÜLDÖK:');

  MemoKerek.Lines.Clear;
  MemoKerek.Clear;
  MemoKerek.Lines.Add('KÉREK:');

  WuHufPanel.Caption  := '';
  WuUsdPanel.Caption  := '';
  InnovaPanel.Caption := '';

  KezdijErtekPanel.Caption := '';
  EkerErtekPanel.Caption   := '';

  DeprosnevPanel.caption := '';
  DuProsnevPanel.Caption := '';

  _pcs := 'DELETE FROM NAPIZAR';
  PillParancs(_pcs);
  Fuggony.Visible := False;
end;


// =============================================================================
                 function Tnapijelentes.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
            function Tnapijelentes.FtForm(_i: integer): string;
// =============================================================================

var _f1,_fw: byte;

begin
  result := '-';
  if _i<1 then exit;

  result := inttostr(_i);
  if _i<1000 then exit;

  _fw := length(result);
  if _fw>6 then
    begin
      _f1:= _fw-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+3,3);
      exit;
    end;

  _f1 := _fw-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;

// =============================================================================
            function Tnapijelentes.ArfForm(_arf: integer): string;
// =============================================================================

var _fw: byte;
    _arfs: string;

begin
  result := '';
  if _arf=0 then exit;

  _arfs := inttostr(_arf);  // '123'  - '12345'
  _fw := length(_arfs);     //   3    -    5
  _fw := _fw-2;
  result := leftstr(_arfs,_fw)+midstr(_arfs,_fw+1,2);
end;

procedure TNAPIJELENTES.JelentesExit;
begin
  Pillquery.close;
  Pilldbase.close;
  Modalresult := 1;
end;


// =============================================================================
                procedure TNapiJelentes.TombBetoltes;
// =============================================================================

begin
 _yPanel[1] := y1Panel;
  _yPanel[2] := y2Panel;
  _yPanel[3] := y3Panel;
  _yPanel[4] := y4Panel;
  _yPanel[5] := y5Panel;
  _yPanel[6] := y6Panel;
  _yPanel[7] := y7Panel;
  _yPanel[8] := y8Panel;
  _yPanel[9] := y9Panel;
  _yPanel[10]:= y10Panel;
  _yPanel[11]:= y11Panel;
  _yPanel[12]:= y12Panel;
  _yPanel[13]:= DatumPanel;
  _yPanel[14]:= UzletnevPanel;

  _aPanel[1] := vdePanel;
  _aPanel[2] := vduPanel;
  _aPanel[3] := edePanel;
  _aPanel[4] := eduPanel;
  _aPanel[5] := pdePanel;
  _aPanel[6] := pduPanel;

  _rPanel[1] := R1Panel;
  _rPanel[2] := R2Panel;
  _rPanel[3] := R3Panel;
  _rPanel[4] := R4Panel;
  _rPanel[5] := R5Panel;
  _rPanel[6] := R6Panel;
  _rPanel[7] := R7Panel;
  _rPanel[8] := R8Panel;
  _rPanel[9] := R9Panel;
  _rPanel[10]:= R10Panel;

  _cPanel[1] := Cim1Panel;
  _cPanel[2] := Cim2Panel;
  _cPanel[3] := Cim3Panel;
  _cPanel[4] := Cim4Panel;
  _cPanel[5] := Cim5Panel;
  _cPanel[6] := Cim6Panel;
  _cPanel[7] := Cim7Panel;
  _cPanel[8] := Cim8Panel;
  _cPanel[9] := Cim9Panel;
  _cPanel[10]:= Cim10Panel;
  _cPanel[11]:= Cim11Panel;
  _cPanel[12]:= Cim12Panel;
  _cPanel[13]:= Coin1Panel;
  _cPanel[14]:= Coin2Panel;

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



// =============================================================================
                    function Tnapijelentes.GetDnem: string;
// =============================================================================

var _b1,_b2,_b3: byte;

begin
  _b1 := getbyte+64;
  _b2 := getbyte+64;
  _b3 := getbyte+64;
  result := chr(_b1)+chr(_b2)+chr(_b3);
end;


// =============================================================================
                        procedure TNapiJelentes.PagesAppear;
// =============================================================================

begin
  ZaroPanel.Visible := true;
  KeszletPanel.Visible := true;
  ForgalomPanel.Visible := true;
  CimletPanel.Visible := true;
  WuPanel.Visible := true;
  AfaPanel.Visible := true;
  EgyediPanel.Visible := true;
  KuldoPanel.Visible := true;
  ProsnevPanel.Visible := true;
  MemoKuldok.Visible := true;
  MemoKerek.Visible := true;
end;


// =============================================================================
            procedure TNAPIJELENTES.MASIKIRODAGOMBClick(Sender: TObject);
// =============================================================================

begin
  ChfLabel.Visible := False;
  _regisvajcifrank := 0;
  EgyirodaJelentese;
end;

// =============================================================================
                function TNapijelentes.Vbetuout(_s: string): string;
// =============================================================================

var _y,_w,_asc: byte;

begin
  result := '';
  _s:= uppercase(trim(_s));
  _w := length(_s);
  if _w=0 then exit;

  _y:= 1;
  while _y<=_w do
    begin
      _asc := ord(_s[_y]);
      if _asc<90 then result := result + chr(_asc);
      inc(_y);
    end;
end;













// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// -----------------------------------------------------------------------------
//------------------------------------------------------------------------------
////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                A BEÉRKEZETT ADATOK DEKÓDOLÁSA                          ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// ===========================================================================
         function TNAPIJELENTES.DataKibonto(_napijelPath: string):boolean;
// ===========================================================================

var _fileMeret: word;
    _aktId: string;

begin
  (* Az infofile neve: 99081231.NIF= 99 VÁLTÓ 2008.12.31
                       A6080901.NIF=106 VÁLTÓ 2008.09.01
                       B3081105.NIF=111 VÁLTÓ 2008.11.05
                       E6081205.NIF=146 VÁLTÓ 2008.12.05

      NapiInfofile strukturája:

     2 byte: 'DA' - FILE identitás kód
     3 byte: évtized, honap, nap  -> 3 BYTE

     Jelszó     -> TEXT
     Pénztárnév -> TEXT

     Záróforint -> INTEGER
     Záróvaluta -> INTEGER

     Ennyi valutának van zárókészlete: (VZ)  -> BYTE

     VZ darab valuta:
          dnem          -> TEXT
          dnem készlete -> INTEGER
          dnem vétele   -> INTEGER
          dnem eladása  -> INTEGER

     Délelötti vételforgalom   -> INTEGER
     Délelötti eladásforgalom  -> INTEGER
     Délutáni vételforgalom    -> INTEGER
     Délutáni eladásforgalom   -> INTEGER

     Vett Euro érme   -> WORD

     1 EUROS darab    -> WORD
     2 EUROS darab    -> WORD

     12 WORD  Ft cimletek  -> 12 * WORD

     Wu-USD készlet  -> INTEGER
     Wu-HUF készlet  -> INTEGER
     AFA ft készlet  -> INTEGER

     Árfolyam-engedmények száma az adott napon (engDB) (max 10)
        1 to engDb:

          dnem               -> TEXT
          Bankjegy           -> INTEGER
          kedv-es árfolyama  -> INTEGER
          bizonylatszam      -> TEXT

     Byte: kérek memo sorai:  (KERSORDB)

          1 TO KERSORDARAB : SORTEXT -> TEXT

     Byte: küldök memo sorai:  (KULDSORDB)

          1 TO KULDSORDARAB : SORTEXT -> TEXT

     Napi kezelési díj          -> INTEGER
     E-kereskedelem záróforint  -> INTEGER

     délelötti ptáros neve: -> TEXT
     délutáni  ptáros neve: -> TEXT

     Régi svájci frank összege  -> INTEGER

     3 byte: 255-255-255 = File-contol száma
     *)

  Result := False;

  // Beolvassa a bytetombbe a _filemeret darab byte-ot:

  AssignFile(_olvas,_napijelPath);
  Reset(_olvas);
  _fileMeret := Filesize(_olvas);
  Blockread(_olvas,_byteTomb,_fileMeret);
  Closefile(_olvas);

  // A pp mutatót alapra állitja

  _pp := 1;

  //  Az aktuális ID dekodolása

  _b1 := getByte;
  _b2 := getByte;

  _aktid := chr(_b1)+chr(_b2);
  if (_aktid<>'DA') and (_aktid<>'NW') then exit;


  // Itt az ID rendben. Dekodolja a dátumot,jelszót és az üzlet nevét:

  _ev  := 2000 + getbyte;
  _ho  := getbyte;
  _nap := getbyte;

  _ydatum := inttostr(_ev) + '.' + nulele(_ho) + '.'+nulele(_nap);
  _jjelszo   := vbetuout(GetString);
  _yUzletnev := Getstring;

  // A forint és valutakészletek beolvasása:

  _zForint   := Getinteger;
  _zValuta   := GetInteger;

  _zOsszes := _zForint + _zValuta;


  // A valutanemek szerinti készletek, vásárlások és eladások dekódolása:

  _valutaDarab := getByte;
  _z := 1;
  while _z<=_valutadarab do
    begin
      _ddnem[_z]    := Getstring;
      _dKeszlet[_z] := GetInteger;
      _dVetel[_z]   := GetInteger;
      _dEladas[_z]  := GetInteger;
      inc(_z);
    end;


  // A délelötti és délutáni forgalmak beolvasása

  _devet    := GetInteger;
  _deeladas := GetInteger;
  _duvet    := GetInteger;
  _dueladas := GetInteger;

  // Az euró érmék dekódolása:

  _vetterme := getWord;
  _ee1      := Getword;
  _ee2      := Getword;


  // A forint-készlet cimleteinek dekódolása:

  _z := 1;
  while _z<=12 do
    begin
      _ftcimlet[_z] := getword;
      inc(_z);
    end;

  // Western Union és AFA készletek dekódolása:

  _wuUsd := GetInteger;
  _wuHUF := GetInteger;
  _AFA   := GetInteger;


  // A kiadott kedvezmények dekódolása:

  _KedvDarab := getbyte;

  if _KedvDarab>0 then
    begin
      _z := 1;
      while _z<=_kedvDarab do
        begin
          _kedvDnem[_z]      := Getstring;
          _kedvBjegy[_z]     := GetInteger;
          _kedvArf [_z]      := GetInteger;
          _kedvbizonylat[_z] := Getstring;
          inc(_z);
        end;
    end;


  // Kérek memo adatainak dekódolása

  _kerSorDarab := GetByte;
  if _kerSorDarab>0 then
    begin
      _z := 1;
      while _z<=_kersorDarab do
        begin
          _kersor[_z] := Getstring;
          inc(_z);
        end;
    end;

  // Küldök memo adatainak dekódolása

  _kuldSorDarab := GetByte;
  if _kuldSorDarab>0 then
    begin
      _z := 1;
      while _z<=_kuldsorDarab do
        begin
          _kuldsor[_z] := Getstring;
          inc(_z);
        end;
    end;

  // A napi kezelési díj és elektromos kereskedés készletének dekódolása

  _napikezdij     := getInteger;
  _napiekerforint := getinteger;

  // A délelötti és délutáni pénztárosok nevének dekódolása:

  _deprosnev := Getstring;
  _duprosnev := Getstring;

  // A régi svájci frank vételének dekódolása

  _regisvajcifrank := 0;
  if _aktid='NW' then _regisvajcifrank := GetInteger;

  // A napi jelentés kontrolsummája, ha rendben van -> vissza = TRUE

  _ctrl := _bytetomb[_pp]+_bytetomb[_pp+1]+_bytetomb[_pp+2];
  if _ctrl=765 then result := True else result := False;

end;


////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
////                  A DEKODOLT ADATOK KIJELZÉSE                           ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
                     procedure TnapiJelentes.DataLapDisplay;
// =============================================================================

begin
  DataLapClear;

  // Dátum és üzletnév kijelzése:

  DatumPanel.Caption      := _yDatum;
  UzletnevPanel.Caption   := _yUzletnev;

  // Forint és valuta készlet kijelzése

  _zOsszes := _zForint + _zValuta;
  zForintPanel.Caption    := FtForm(_zForint)+' Ft';
  zValutaPanel.Caption    := FtForm(_zValuta)+' Ft';
  zOsszesPanel.caption    := FtForm(_zOsszes);

  // A délelötti és délutáni forgalmak kijelzése:

  DeVetLabel.Caption      := ftForm(_deVet)+' Ft';;
  DeEladasLabel.Caption   := ftForm(_deEladas)+ ' Ft';
  DuVetLabel.Caption      := ftForm(_duVet) + ' Ft';
  DuEladasLabel.Caption   := ftForm(_duEladas)+ ' Ft';

  NapiVetelLabel.Caption  := ftForm(_devet+_duVet)+' Ft';
  NapiEladasLabel.Caption := ftForm(_deEladas+_duEladas)+' Ft';

  // A 12 forint cimlet kijelzése:

  _z := 1;
  while _z<=12 do
    begin
      _aktPanel := _cimlet[_z];
      _aktword  :=  _ftCimlet[_z];
      _aktPanel.Caption := ftForm(_aktword);
      inc(_z);
    end;

  // Euró érmék kijelzése:

  ee1Panel.Caption := ftForm(_ee1);
  ee2Panel.Caption := ftForm(_ee2);


  if _kedvDarab>0 then
    begin
      if _kedvDarab>10 then _kedvDarab := 10;

      // A max 10 kedvezmény (valnem,bankjegy,arfolyam,bizonylatszam)

      _z := 1;
      while _z<=_kedvDarab do
        begin
          _aktPanel := _xVal[_z];
          _aktstring  := _kedvdnem[_z];
          _aktPanel.Caption := _aktstring;

          _aktPanel := _xSum[_z];
          _aktinteger  := _kedvbjegy[_z];
          _aktPanel.Caption := ftform(_aktinteger);

          _aktPanel := _xArf[_z];
          _aktinteger  := _kedvArf[_z];
          _aktPanel.Caption := arfForm(_aktInteger);

          _aktPanel := _xBiz[_z];
          _aktstring  := _kedvbizonylat[_z];
          _aktPanel.Caption := _aktstring;

          inc(_z);
        end;
    end;


  // Western Union Huf és Usd, és AFA készlet kijelzése:

  if _wuHuf>0 then wuhufPanel.Caption := ftform(_wuhuf)+' Ft';
  if _wuUsd>0 then wuUsdPanel.Caption := ftform(_wuUsd)+' Ft';
  if _afa>0 then InnovaPanel.Caption  := ftform(_afa)+' Ft';

  // A kezelési díj és e-kereskedelmi készlet kijelzése:

  if _napikezdij>0 then KezdijErtekPanel.Caption := ftform(_napikezdij)+' Ft';
  if _napiEkerForint>0 then EkerErtekPanel.Caption := ftform(_napiEkerForint)+' Ft';

  // A délelötti/délutáni pénztárosok nevének kijelzése:

  if _deprosnev<>'' then DeProsnevPanel.Caption := _deprosnev;
  if _duprosnev<>'' then DuProsnevPanel.Caption := _duprosnev;

  // A készletek, vételek és eladások berögzitése a Napizar táblába:

  _z := 1;
  while _z<=_valutadarab do
    begin
      _aktdnem    := _ddnem[_z];
      _aktvetel   := _dVetel[_z];
      _aktEladas  := _dEladas[_z];
      _aktKeszlet := _dKeszlet[_z];

      _pcs := 'INSERT INTO NAPIZAR (VALUTANEM,VETEL,ELADAS,ZARO)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktvetel) + ',';
      _pcs := _pcs + inttostr(_akteladas) + ',';
      _pcs := _pcs + inttostr(_aktkeszlet)+')';

      PillParancs(_pcs);
      inc(_z);
    end;

  // Amennyiben van kérés -> kérések kijelzése

  if _kersordarab>0 then
    begin
      _z := 1;
      while _z<=_kersordarab do
        begin
          MemoKerek.Lines.add(_kersor[_z]);
          inc(_z);
        end;
    end;


  // Amennyiben van küldés -> küldések kijelzése

  if _kuldsordarab>0 then
    begin
      _z := 1;
      while _z<=_kuldsordarab do
        begin
          MemoKuldok.Lines.add(_kuldsor[_z]);
          inc(_z);
        end;
    end;

  //  A készletek és forgalmak adatbázison keresztüli kijelzése

  _pcs := 'SELECT * FROM NAPIZAR' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  Pilldbase.Connected := true;
  with PillQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
    end;


  //  Kijelzés indul !

  Pillsource.Enabled := true;

 // Ha volt régi svájci frank, akkor azt kijelzi

  if _regisvajcifrank>0 then
    begin
      _rsfs := FtForm(_regisvajcifrank)+' CHF';
      CHFLabel.Caption := _RSFS;
      ChfLabel.visible := True;
      ChfPanel.Visible := True;
      ChfPanel.Repaint;
    end;
  Napijelentes.repaint;  


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
                procedure Tnapijelentes.AlapadatBeolvasas;
// =============================================================================

begin
  valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := trim(FieldByNAme('MEGNYITOTTNAP').AsString);

      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;

      _homepenztarkod := trim(FieldbyName('PENZTARKOD').AsString);
      _homepenztarnev := trim(FieldByName('PENZTARNEV').AsString);
      Close;
    end;
  Valutadbase.close;
  val(_homepenztarkod,_homePenztarszam,_code);
end;

// =============================================================================
         procedure TNAPIJELENTES.NYOMTATASGOMBClick(Sender: TObject);
// =============================================================================

begin
  MasikIrodaGomb.Visible := False;
  if PrintersetupDialog1.Execute then
    begin
      Kivilagositas;
      Sleep(50);
      Print;
      sleep(50);
      Kiszinezes;
    end;
  MasikIrodaGomb.Visible := True;
end;





// =============================================================================
                     procedure TNapijelentes.Kiszinezes;
// =============================================================================

var _aktpanel: TPanel;

begin
  _y := 1;
  while _y<=14 do
    begin
      _aktpanel := _yPanel[_y];
      _aktpanel.color := clyellow;
      _aktpanel.repaint;

      _aktpanel := _cPanel[_y];
      _aktpanel.color := $F8E4D8;
      _aktpanel.repaint;

      inc(_y);
    end;

  _y := 1;
  while _y<=6 do
    begin
      _aktPanel := _aPanel[_y];
      _aktPanel.color := clAqua;
      _aktpanel.repaint;
      inc(_y);
    end;

  _y := 1;
  while _y<=10 do
    begin
      _aktPanel := _rPanel[_y];
      _aktpanel.color := clRed;
      _aktpanel.Font.color := clWhite;
      _aktpanel.Repaint;
      inc(_y);
    end;
  KuldoPanel.Color := $F8E4D8;
  KuldoPanel.repaint;

  Masikirodagomb.visible := True;
  Nyomtatasgomb.visible := True;
  Masikirodagomb.Repaint;
  Nyomtatasgomb.Repaint;
end;

// =========================================================================
       procedure TNAPIJELENTES.KILEPOTIMERTimer(Sender: TObject);
// =========================================================================

begin
  Uzenopanel.Visible := false;
  KilepoTimer.Enabled := false;
  ModalResult := 1;
end;



end.

