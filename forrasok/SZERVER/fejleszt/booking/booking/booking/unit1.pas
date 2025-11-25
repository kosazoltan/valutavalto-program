unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  IBTable,StrUtils, ExtCtrls, DateUtils, ComCtrls, ComObj, TlHelp32;

type
  TForm1 = class(TForm)

    ArtQuery     : TIBQuery;
    ArtDBase     : TIBDatabase;
    ArtTranz     : TIBTransaction;

    BookTabla    : TIBTable;
    BookQuery    : TIBQuery;
    BookDbase    : TIBDatabase;
    BookTranz    : TIBTransaction;

    IbQuery      : TIBQuery;
    IbDbase      : TIBDatabase;
    IbTranz      : TIBTransaction;
    IbTabla      : TIBTable;

    RemoteTabla  : TIBTable;
    RemoteQuery  : TIBQuery;
    RemoteDbase  : TIBDatabase;
    RemoteTranz  : TIBTransaction;

    AktDatumPanel: TPanel;
    AlapPanel    : TPanel;
    E1           : TPanel;
    E2           : TPanel;
    E3           : TPanel;
    DatumPanel   : TPanel;
    ExistPanel   : TPanel;
    FejPanel     : TPanel;
    FinishPanel  : TPanel;
    H1           : TPanel;
    H2           : TPanel;
    H3           : TPanel;
    H4           : TPanel;
    H5           : TPanel;
    H6           : TPanel;
    H7           : TPanel;
    H8           : TPanel;
    H9           : TPanel;
    H10          : TPanel;
    H11          : TPanel;
    H12          : TPanel;
    HibaPanel    : TPanel;
    OpenPanel    : TPanel;
    Prog2Panel   : TPanel;
    Prog3Panel   : TPanel;
    ProgressPanel: TPanel;
    Takaro       : TPanel;
    Xls1Panel    : TPanel;
    Xls2Panel    : TPanel;
    Xls3Panel    : TPanel;

    Label1       : TLabel;
    Label2       : TLabel;
    Label3       : TLabel;
    Label4       : TLabel;
    Label5       : TLabel;
    Label6       : TLabel;
    Label7       : TLabel;
    Label8       : TLabel;
    Label9       : TLabel;
    Label10      : TLabel;
    Label11      : TLabel;
    Label12      : TLabel;
    Label13      : TLabel;

    BitBtn1      : TBitBtn;
    ExitGomb     : TBitBtn;
    HonapOkeGomb : TBitBtn;
    RemakeGomb   : TBitBtn;
    ForgTablaGomb: TBitBtn;
    AtadTablaGomb: TBitBtn;
    EgyiketseGomb: TBitBtn;
    FinishGomb   : TBitBtn;
    NyitoGomb    : TBitBtn;
    OpenGomb     : TBitBtn;
    VegeGomb     : TBitBtn;
    VisszaGomb   : TBitBtn;

    Shape1       : TShape;
    Shape2       : TShape;

    Kilepo       : TTimer;

    Csik         : TProgressBar;
    Csik2        : TProgressBar;

    HibaLista    : TListBox;

    procedure AdatlegyujtoProgram;
    procedure AdatNullazas;
    procedure AtadTablaGombClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BookingControl;
    procedure BookParancs(_ukaz: string);
    procedure CtrlNullazas;
    procedure E1Click(Sender: TObject);
    procedure E1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure EgyiketseGombClick(Sender: TObject);
    procedure ExitGombClick(Sender: TObject);
    procedure EvPanelsClear;
    procedure Excelopen(_excelNev: string);
    procedure ExcelKill;
    procedure Feldolgozas;
    procedure GetCtrlData;
    procedure ProgramFinish;
    procedure FinishGombClick(Sender: TObject);
    procedure ForgTablaGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure H1Click(Sender: TObject);
    procedure H1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure HonapOkeGombClick(Sender: TObject);
    procedure HoPanelsClear;
    procedure PenztarBeolvasas;
    procedure KilepoTimer(Sender: TObject);
    procedure Konyveles;
    procedure MakeAdvetTabla;
    procedure MakeFdb;
    procedure MakeTranzTabla;
    procedure MakeEvhoTabla;
    procedure NyitoGombClick(Sender: TObject);
    procedure NyitoZaroBeolvasas;
    procedure NyitoZaroNullazas;
    procedure NyitoZaroRegisztralas;
    procedure OpenGombClick(Sender: TObject);
    procedure RemakeGombClick(Sender: TObject);
    procedure TombbeOlvasas;
    procedure VisszaGombClick(Sender: TObject);

    function FinishControl: boolean;
    function Kerekito(_int: real): real;
    function Nulele(_b: byte): string;
    function Null3(_apt: byte): string;
    function Scanpenztar(_pz: byte): byte;
    function ScanNyitopenztar(_pz: byte): byte;
    function Scandnem(_ad: string): byte;
    function ScanPtDnemTpts(_apdTp: string): word;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _host     : string = '185.43.207.99';

  _aktPanel,_aktevpanel,_akthopanel : TPanel;

  _handle   :HWND;

  _iras: TextFile;

  _bookdir  : string = 'C:\BOOKING';
  _datadir  : string = 'c:\BOOKING\DATABASE';
  _exceldir : string = 'c:\BOOKING\EXCEL';
  _logdir   : string = 'c:\BOOKING\LOG';
  _bookPath : string = 'c:\booking\database\booking.fdb';
  _vSorveg  : string = ','+chr(13)+chr(10);

  _ptDnemTpts: array[1..4096] of string;
  _vbj,_vft,_ebj,_eft,_eBk: array[1..170,1..27] of real;

  _adbj,_kapbj: array[1..170,1..27] of real;
  _adptBj,_kapPtbj: array[1..4096] of real;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
             'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK',
             'NZD','PLN','RON','RSD','RUB','SEK','THB','TRY','UAH','USD');

  _hufindex: byte = 13;
  _evPanel: array[1..3] of TPanel;
  _hoPanel: array[1..12] of TPanel;

  _sorveg: string = chr(13)+chr(10);

  _proc: PROCESSENTRY32;

  _penztar,_korzet,_nyitottPenztar: array[1..170] of byte;
  _penztarnev: array[1..170] of string;

  _nyito,_zaro: array[1..170,1..27] of real;
  _hibastr: string;

  _aktpt,_aktet,_penztarDarab,_aktpenztar,_aktkorzet,_tag,_zz,_nyitottIndex: byte;
  _nyitottPenztardarab,_dnemindex,_lastpenztar,_fizetoeszkoz: byte;
  _penztarIndex: byte;

  _top,_left,_height,_width,_aktev,_akthonap,_eloev,_eloho: word;
  _ptdnemDarab,_ptdnemTptsDarab,_pp,_y,_xx,_yy,_ptss,_hiba: word;

  _aPath,_rPath,_vPath,_elofarok,_elocimtar,_aktcimtar,_utdatum: string;

  _pcs,_aktkft,_aktnev,_hknev,_hksnev,_aktdnem,_mess,_utbizszam: string;
  _FEJ,_TET,_farok,_tipus,_tarspenztar,_valutanem,_pts,_aktptdnem: string;
  _aktptdnemTpts,_akthonev,_datumstr,_aktevnev,_selectedevs,_cst: string;
  _forgexcelPath,_forgExcelnev,_advetExcelnev,_advetExcelPath: string;
  _selectedHos,_selectedHonev,_aktdatum,_aktpenztarnev,_bizonylatszam: string;
  _keszletexcelnev,_keszletexcelPath: string;

  _recno,_code,_kerekites: integer;
  _bankjegy,_forintertek,_osszesen,_aktnyito,_aktzaro,_hufzaro,_szamhufzaro: real;
  _zvbj,_zebj,_zvft,_zeft,_zeBk,_zAd,_zKap,_aktad,_aktkap,_sumvett,_sumeladott: real;
  _aktvbjegy,_aktebjegy,_aktvertek,_akteertek,_szamzaro,_szamhufzaro1: real;
  _aktkeszpenz,_aktkartyas,_hufnyito,_hufkap,_hufad,_sumkonvertft: real;

  _evfix,_hofix,_looper: boolean;
  _oxl,_owb: OleVariant;

  _nyPenztarIndex: byte;


function advetexcelrutin: integer; stdcall; external 'c:\booking\advetex.dll';
function forgalomexcelrutin: integer; stdcall; external 'c:\booking\forgex.dll';
function keszletexcelrutin: integer; stdcall; external 'c:\booking\keszex.dll';
implementation

{$R *.dfm}

// =============================================================================
           procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top    := round((_height-450)/2);
  _left   := round((_width-457)/2);

  Top  := _top-100;
  Left := _left+8;

  Tombbeolvasas;

  _hofix := False;
  _evfix := False;

  _aktev := yearof(date);
  _akthonap := monthof(date);

  dec(_akthonap);
  if _akthonap=0 then
    begin
      _akthonap := 12;
      dec(_aktev);
    end;

  E3.Caption := inttostr(_aktev);
  E2.Caption := inttostr(_aktev-1);
  E1.Caption := inttostr(_aktev-2);

  _akthopanel := _hopanel[_akthonap];
  _akthopanel.Color := clMoneyGreen;
  _akthoPanel.Font.Color := clBlack;

  _aktevnev := inttostr(_aktev);
  _akthonev := _akthoPanel.caption;
  _datumstr := _aktevnev + ' ' + _akthonev;

  DatumPanel.Caption := _datumstr;
end;

// =============================================================================
           procedure TForm1.HonapOkeGombClick(Sender: TObject);
// =============================================================================

begin
  _selectedEvs   := _aktevnev;
  _selectedHos   := nulele(_akthonap);
  _selectedhonev := _hopanel[_akthonap].caption;
  _aktdatum      := _selectedEvs + ' ' + _selectedHonev;
  val(_selectedevs,_aktev,_code);

  AktdatumPanel.Caption := _aktdatum;

  ProgressPanel.Caption := '';
  Prog2Panel.caption :='';
  Prog3Panel.Caption := '';

  Csik.Position  := 0;
  Csik2.Position := 0;

  _farok          := midstr(_selectedEvs,3,2)+_selectedHos;
  _forgExcelNev   := 'FORG' + _farok + '.xls';
  _advetExcelNev  := 'ADVET' + _farok + '.xls';
  _keszletExcelNev:= 'KESZ' + _farok + '.xls';
  _forgExcelPath  := 'C:\BOOKING\EXCEL\' + _forgexcelnev;
  _advetExcelPath := 'C:\BOOKING\EXCEL\' + _advetexcelnev;
  _keszletExcelPath := 'C:\BOOKING\EXCEL\' + _keszletexcelnev;


  if fileExists(_forgexcelpath) then
    begin
      with existPanel do
        begin
          top := 112;
          left:= 24;
          Visible := True;
          repaint;
        end;
      exit;
    end;
  Feldolgozas;
end;

// =============================================================================
                     procedure TForm1.Feldolgozas;
// =============================================================================

begin
  with Takaro do
    begin
      top  := 8;
      left := 8;
      Visible := True;
      repaint;
    end;

  // ---------------------------------------------------------

  ProgressPanel.Caption := 'Adatbázis ellenörzése ..';
  ProgressPanel.repaint;

  BookingCOntrol;         // directoryk - adatbázisok ellenörzése, kreálása
  PenztarBeolvasas; // receptorból: penztar,penztarnev,korzet,kft tomb 1..penztardatab]

  AdatLegyujtoProgram;    //
  NyitoZaroBeolvasas;
  Konyveles;
  NyitoZaroRegisztralas;

  progressPanel.Caption := 'Az adatok leellenõrzése';
  progressPanel.repaint;

  if not finishControl then
    begin
      with hibapanel do
        begin
          top := 8;
          left := 8;
          visible := true;
          repaint;
        end;
      Activecontrol := Visszagomb;
      exit;
    end else
    begin
      progressPanel.Caption := 'AZ ADATOK HIBÁTLANOK !';
      Sleep(3000);
    end;

  forgalomexcelrutin;
  advetexcelrutin;
  keszletexcelrutin;
  programFinish;
end;

// =============================================================================
              procedure TForm1.AdatleGyujtoProgram;
// =============================================================================

begin
  Adatnullazas;    // tömbök - adatbázisok nullázása

  ProgressPanel.caption := 'Havi tranzakciók legyüjtése ...';
  ProgressPanel.Repaint;

  // A kért hónap összes nemstornozott rekordját nyitja meg a _pcs

  _FEJ := 'BF' + _farok;
  _TET := 'BT' + _farok;
  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM ' + _FEJ + ' FEJ JOIN '+ _TET + ' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.STORNO=1)';

  Csik.max := _penztarDarab;
  Csik2.Max := 4;
  Csik2.Position := 1;

  _nyitottIndex := 0;    // a müködõ pénztárak indexe nullázva

  _penztarIndex := 1;
  while _penztarindex<=_penztarDarab do  // az összes (bezártak is) pénztárt vizsgálja
    begin
      Csik.Position := _penztarIndex;

      _aktpenztar := _penztar[_penztarIndex]; // a teljes pénztársor eleme (lehet zárt is)
      _aktpenztarnev := _penztarnev[_penztarIndex];
      _sumkonvertFt := 0;

      Prog2Panel.Caption := _aktpenztarnev;
      Prog2panel.repaint;

      _Vpath := _host + ':C:\receptor\database\V'+inttostr(_aktpenztar)+'.FDB';
      _pts := null3(_aktpenztar);    // pl: '009','033','143' etc.

      // A szerver megfelelõ adatbázisát nyitja meg:

      RemoteDbase.close;
      remoteDbase.Databasename := _VPath;
      RemoteDbase.Connected := True;

      // Megnnézi, hogy az adatbézisban létezik e az adott havi tábla

      RemoteTabla.close;
      remoteTabla.TableName := _fej;

      if not Remotetabla.Exists then // ha nem kétezik, tehát zárva van átlépi
        begin
          Remotedbase.close;
          inc(_penztarIndex);
          Continue;
        end;

      // Létezik a havi gyüjtõtábla - ezért neg is nyitja:

      with RemoteQuery do
        begin
          close;
          sql.clear;
          sql.Add(_pcs);
          Open;
          _recno := recno;
        end;


      // Ha a havi forgalomtábla üres -> átlépi ezt a pénztárt

      if _recno=0 then
        begin
          RemoteQuery.close;
          remotedbase.close;
          inc(_penztarIndex);
          Continue;
        end;

      // =============================

      // Ennek a pénztárnak vannal a kért hónapra adatai

      inc(_nyitottIndex);     // A penztar számát felvesszük a nyitottpénztársorba
      _nyitottPenztar[_nyitottIndex] := _aktpenztar;

      _utbizszam := '0';
      while not RemoteQuery.Eof do
        begin

          // Beolvasunk egy rekordot a blokkfej-blokktétel adatbázisból:

          with RemoteQuery do
            begin
              _bizonylatszam := FieldbyName('BIZONYLATSZAM').asString;
              _tipus         := FieldbyName('TIPUS').asstring;
              _tarspenztar   := trim(FieldByName('PENZTAR').asString);
              _aktdnem       := FieldByNAme('VALUTANEM').asString;
              _bankjegy      := FieldByName('BANKJEGY').asInteger;
              _forintertek   := FieldByNAme('FORINTERTEK').asInteger;
              _kerekites     := FieldByname('KEREKITES').asInteger;
              _fizetoeszkoz  := FieldByNAme('FIZETOESZKOZ').asInteger;
            end;

          // Ha ez új bizonylatszám -> fizetendot kerekitessel kell módositani
          if _utbizszam<>_bizonylatszam then
            begin
              _utbizszam := _bizonylatszam;
              _forintertek := _forintertek + _kerekites;
            end;


          // A konverziós forint gyüjtése
          if (_tipus='E') AND (_aktdnem='HUF') then
            begin
               _sumkonvertft := _sumkonvertft + _bankjegy;
               remoteQuery.next;
               Continue;
            end;


          _mess := floattostr(_bankjegy) + ' ' + _aktDnem;

          if _tipus='V' then _mess := _mess + ' vásárlása';
          if _tipus='E' then _mess := _mess + ' eladása';
          if _tipus='U' then _mess := _mess + ' átvétele';
          if _tipus='F' then _mess := _mess + ' átadása';

          Prog3Panel.Caption := _mess;
          Prog3Panel.repaint;

          // Az átadás-átvétel társpénztár szerinti gyüjtése
          _aktptdnemTpts := _pts + _aktDnem + _tarspenztar;

          _xx := Scandnem(_aktDnem);   // _xx = valutaindex
          _yy := ScanPtDnemTpts(_aktPtDnemTpts); // kombi-index
          _zz := _nyitottIndex;

          if ((_tipus='V') OR (_tipus='E')) then
            begin
              if _tipus='V' then
                begin

                  _vbj[_zz,_xx] := _vbj[_zz,_xx] + _bankjegy;
                  _vFt[_zz,_xx] := _vFt[_zz,_xx] + _forintertek;
                end else
                begin
                  _ebj[_zz,_xx] := _ebj[_zz,_xx] + _bankjegy;
                  if _fizetoeszkoz=2 then
                        _eBk[_zz,_xx] := _eBk[_zz,_xx] + _forintertek;
                  if _fizetoeszkoz=1 then
                        _eFt[_zz,_xx] := _eFt[_zz,_xx] + _forintertek;
                end;
            end;

          if (_tipus='U') OR (_tipus='F') then
            begin
              if _tipus='F' then
                begin
                  _adbj[_zz,_xx] := _adbj[_zz,_xx] + _bankjegy;
                  _adPtbj[_yy] := _adptbj[_yy] + _bankjegy;
                end else
                begin
                  _kapbj[_zz,_xx] := _kapbj[_zz,_xx] + _bankjegy;
                  _kapPtBj[_yy] := _kapPtBj[_yy] + _bankjegy;
                end;
             end;

          remotequery.next;
        end;
      _eFt[_zz,_hufindex] := _eFt[_zz,_hufindex] + _sumkonvertft;
      _vFt[_zz,_hufindex] := _vFt[_zz,_hufindex] + _sumkonvertft;

      remoteQuery.close;
      Remotedbase.close;
      inc(_penztarIndex);
    end;

  _nyitottPenztarDarab := _nyitottIndex;
  Csik2.Position := 2;

  ProgressPanel.Caption := '';
  Prog2Panel.Caption := '';

  ProgressPanel.repaint;
  Prog2Panel.Repaint;

  Csik.Position := 0;

end;

// =============================================================================
                     procedure TForm1.Konyveles;
// =============================================================================

var _zlen: byte;
    _aktpenztars: string;

begin
  _pcs := '';

  ProgressPanel.Caption := 'Tranzakciók könyvelése ...';
  ProgressPanel.repaint;

  _nyitottIndex := 1;
  Csik.Max := _nyitottPenztarDarab;
  while _nyitottIndex<=_nyitottPenztarDarab do
    begin
      _aktpenztar   := _nyitottPenztar[_nyitottIndex];
      _penztarIndex := ScanPenztar(_aktpenztar);
      _aktkorzet    := _korzet[_penztarIndex];
      _aktkft       := 'B';
      if _aktpenztar>150 then
        begin
          _aktkft := 'Z';
          _aktkorzet := 180;
        end;

      Csik.Position := _nyitottIndex;
      _pts := null3(_aktpenztar);

      Prog2Panel.Caption := _pts+'. pénztár könyvelése';
      prog2Panel.repaint;

      _zz := _nyitottindex;

      _dnemIndex := 1;
      while _dnemindex<=27 do
        begin
          _aktdnem   := _dnem[_dnemindex];
          _aktptdnem := _pts + _aktdnem;

          prog3Panel.Caption := _aktdnem;
          Prog3Panel.repaint;

          _xx := _dnemIndex;

          _zvbj := _vbj[_zz,_xx];
          _zvFt := _vFt[_zz,_xx];
          _zebj := _ebj[_zz,_xx];
          _zeFt := _eFt[_zz,_xx];
          _zeBk := _eBk[_zz,_xx];
          _zad  := _adbj[_zz,_xx];
          _zkap := _kapbj[_zz,_xx];

          if (_zvBj>0) or (_zebj>0) or (_zad>0) or (_zKap>0) then
            begin
              _pcs := 'INSERT INTO TRANZAKCIOK (KFT,KORZET,PENZTAR,';
              _pcs := _pcs + 'VALUTANEM,VETTBANKJEGY,VETTERTEK,ELADOTTBANKJEGY,';
              _pcs := _pcs + 'ELADOTTKESZPENZ,ELADOTTKARTYAS,ATADAS,ATVETEL)' + _sorveg;

              _pcs := _pcs + 'VALUES (' +chr(39)+_aktkft+chr(39)+',';
              _pcs := _pcs + inttostr(_aktkorzet) + ',';
              _pcs := _pcs + inttostr(_aktpenztar) + ',';
              _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';

              _pcs := _pcs + floattostr(_zvBj) + ',';
              _pcs := _pcs + floattostr(_zvFt) + ',';
              _pcs := _pcs + floattostr(_zeBj) + ',';
              _pcs := _pcs + floattostr(_zeFt) + ',';
              _pcs := _pcs + floattostr(_zeBk) + ',';
              _pcs := _pcs + floattostr(_zaD) + ',';
              _pcs := _pcs + floattostr(_zKap) + ')';
              BookParancs(_pcs);

            end;
          inc(_dnemIndex);
        end;
      inc(_nyitottIndex);
    end;

  Prog2Panel.Caption := '';
  Prog2Panel.repaint;

  Prog3Panel.Caption := '';
  Prog3Panel.repaint;

  Csik2.Position := 3;

  // ------------------------------------------------------

  ProgressPanel.Caption := 'Valutamozgások könyvelése ...';
  ProgressPanel.repaint;

  Csik.Max := _ptdnemTptsDarab;

  _ptss := 1;
  while _ptss<=_ptdnemTptsDarab do
    begin
      Csik.Position := _ptss;
      _aktPtdnemTpts := _ptdnemTpts[_ptss];
      _aktAd  := _adPtBj[_ptss];
      _aktKap := _kapPtBj[_ptss];

      if (_aktad>0) or (_aktkap>0) then
        begin
          _zLen        := length(_aktPtDnemTpts);
          _aktpenztars := leftstr(_aktPtdnemTpts,3);
          _aktDnem     := midstr(_aktPtdnemTpts,4,3);
          _tarspenztar := midstr(_aktPtDnemTpts,7,_zLen-6);

          _mess := _aktdnem + ' átadása-átvétele';
          Prog3Panel.Caption := _mess;
          Prog3Panel.repaint;

          val(_aktpenztars,_aktpenztar,_code);

          _xx := scanPenztar(_aktpenztar);
          _aktkorzet := _korzet[_xx];
          _aktkft := 'B';

          if _aktPenztar>150 then
            begin
              _aktKft := 'Z';
              _aktkorzet := 180;
            end;

          _pcs := 'INSERT INTO ATADATVET (KFT,KORZET,PENZTAR,';
          _pcs := _pcs + 'VALUTANEM,ATADAS,ATVETEL,TARSPENZTAR)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39) + _aktkft + chr(39) + ',';
          _pcs := _pcs + inttostr(_aktkorzet) + ',';
          _pcs := _pcs + inttostr(_aktpenztar) + ',';
          _pcs := _pcs + chr(39) + _aktDnem + chr(39) + ',';
          _pcs := _pcs + floattostr(_aktad) + ',';
          _pcs := _pcs + floattostr(_aktkap) + ',';
          _pcs := _pcs + chr(39) + _tarspenztar + chr(39) + ')';
          BookParancs(_pcs);
        end;
      inc(_ptss);
    end;

  _pcs := 'INSERT INTO EVHONAP (EV,HONAP)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_aktev) + ',';
  _pcs := _pcs + inttostr(_akthonap) + ')';
  BookParancs(_pcs);
end;

// =============================================================================
                    procedure TForm1.ProgramFinish;
// =============================================================================

begin
  Csik2.Position := 4;

  progressPanel.Caption := 'Adatgyüjtést befejeztem';
  ProgressPanel.repaint;

  prog2panel.Caption := '';
  Prog3Panel.Caption := '';

  prog2panel.Repaint;
  Prog3Panel.repaint;

  Csik.Position  := 0;
  Csik2.Position := 0;

  xls1Panel.Caption := _forgexcelnev;
  xls2Panel.caption := _advetexcelnev;
  xls3Panel.caption := _keszletexcelnev;

  with FinishPanel do
    begin
      top := 192;
      left := 16;
      Visible := true;
      repaint;
    end;
  Activecontrol := finishgomb;
end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//////////////  BILLENTYÜ- ÉS EGÉR ESEMÉNYEK  //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
     procedure TForm1.H1MouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                   Y: Integer);
// =============================================================================

begin
  if _hofix then exit;

  _akthonap := TPanel(Sender).tag;
  HoPanelsClear;
  _aktpanel := _hopanel[_akthonap];
  _aktpanel.color := clMoneyGreen;
  _aktpanel.Font.Color := clBlack;
  _akthonev := _aktPanel.Caption;
  _datumstr := _aktevnev + ' ' + _akthonev;
  Datumpanel.caption := _datumstr;
  DatumPanel.repaint;
end;

// =============================================================================
      procedure TForm1.E1MouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                  Y: Integer);
// =============================================================================

begin
  if _evfix then exit;

   _tag := TPanel(Sender).tag;
   EvPanelsClear;
  _aktpanel := _evpanel[_tag];
  _aktpanel.color := clMoneyGreen;
  _aktpanel.Font.Color := clBlack;
  _aktevnev := _aktPanel.Caption;
  _datumstr := _aktevnev + ' ' + _akthonev;
  Datumpanel.caption := _datumstr;
  DatumPanel.repaint;
end;

// =============================================================================
                procedure TForm1.H1Click(Sender: TObject);
// =============================================================================

begin
  Tpanel(Sender).Color := clFuchsia;
  _hofix := True;
end;

// =============================================================================
               procedure TForm1.E1Click(Sender: TObject);
// =============================================================================

begin
  Tpanel(Sender).Color := clFuchsia;
  _evfix := True;
end;

// =============================================================================
              procedure TForm1.EXITGOMBClick(Sender: TObject);
// =============================================================================

begin
  Kilepo.enabled := True;
end;

// =============================================================================
////////////////////////////////////////////////////////////////////////////////
//////////////  SEGÉD-PROGRAMOK ÉS FUNKCIÓK   //////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// =============================================================================
                procedure TForm1.PenztarBeolvasas;
// =============================================================================

var _pp: byte;

begin
  ProgressPanel.Caption := 'IRODÁK BEOLVASÁSA ...';
  ProgressPanel.repaint;

  _Rpath := _host + ':C:\RECEPTOR\DATABASE\RECEPTOR.FDB';
  _pp := 0;

  with RemoteDbase do
    begin
      close;
      databasename := _RPath;
      Connected := True;
    end;

  _pcs := 'SELECT * FROM IRODAK ORDER BY CEGBETU,ERTEKTAR,UZLET';
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Max := _recno;
  while not RemoteQuery.eof do
    begin
      with remoteQuery do
        begin
          _aktPenztar    := Fieldbyname('UZLET').asInteger;
          _aktKorzet     := FieldByNAme('ERTEKTAR').asInteger;
          _aktPenztarNev := trim(FieldByName('KESZLETNEV').asstring);
        end;

      Prog2Panel.Caption := _aktPenztarNev;
      Prog2Panel.repaint;

      inc(_pp);
      Csik.Position := _pp;

      _penztar[_pp] := _aktpenztar;
      _korzet[_pp]  := _aktkorzet;
      _penztarnev[_pp] := _aktPenztarnev;

      RemoteQuery.next;
    end;
  RemoteQuery.close;
  RemoteDbase.close;

  _penztarDarab := _pp;

  ProgressPanel.Caption := '';
  Prog2Panel.Caption    := '';

  ProgressPanel.repaint;
  Prog2Panel.Repaint;
end;


// =============================================================================
                          procedure TForm1.MakeFdb;
// =============================================================================

var _vdbase: TIbDatabase;

begin
  _vDbase := TIbDatabase.create(Nil);
  with _vdbase do
    begin
      connected := False;
      DatabaseName:= _bookPath;
      Params.Add('USER ''SYSDBA''PASSWORD ''dek@nySo''');
      Params.add('DEFAULT CHARACTER SET WIN1250');
      SqlDialect := 3;
      LoginPrompt := False;
      CreateDatabase;
    end;
end;

// =============================================================================
                  procedure TForm1.MakeTranzTabla;
// =============================================================================

begin
  _pcs := 'CREATE TABLE TRANZAKCIOK (';
  _pcs := _pcs + 'KFT CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,';
  _pcs := _pcs + 'KORZET INTEGER,';
  _pcs := _pcs + 'PENZTAR INTEGER,';
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,';
  _pcs := _pcs + 'NYITO DOUBLE PRECISION,';
  _pcs := _pcs + 'ZARO DOUBLE PRECISION,';
  _pcs := _pcs + 'ATADAS DOUBLE PRECISION,';
  _pcs := _pcs + 'ATVETEL DOUBLE PRECISION,';
  _pcs := _pcs + 'VETTBANKJEGY DOUBLE PRECISION,';
  _pcs := _pcs + 'VETTERTEK DOUBLE PRECISION,';
  _pcs := _pcs + 'ELADOTTBANKJEGY DOUBLE PRECISION,';
  _pcs := _pcs + 'ELADOTTKESZPENZ DOUBLE PRECISION,';
  _pcs := _pcs + 'ELADOTTKARTYAS DOUBLE PRECISION,';
  _pcs := _pcs + 'CSAKKESZLET SMALLINT)';
  BookParancs(_pcs);
end;

// =============================================================================
                procedure TForm1.MakeAdvetTabla;
// =============================================================================

begin
  _pcs := 'CREATE TABLE ATADATVET (';
  _pcs := _pcs + 'KFT CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,';
  _pcs := _pcs + 'KORZET INTEGER,';
  _pcs := _pcs + 'PENZTAR INTEGER,';
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,';
  _pcs := _pcs + 'ATADAS DOUBLE PRECISION,';
  _pcs := _pcs + 'ATVETEL DOUBLE PRECISION,';
  _pcs := _pcs + 'TARSPENZTAR CHAR (4) CHARACTER SET WIN1250 COLLATE WIN1250)';
  BookParancs(_pcs);
end;

// =============================================================================
                procedure TForm1.MakeEvhoTabla;
// =============================================================================

begin
  _pcs := 'CREATE TABLE EVHONAP (';
  _pcs := _pcs + 'EV INTEGER,';
  _pcs := _pcs + 'HONAP INTEGER)';

  BookParancs(_pcs);
end;

// =============================================================================
                  procedure TForm1.BookingControl;
// =============================================================================

begin
  if not DirectoryExists(_bookdir) then CreateDir(_bookdir);
  if not DirectoryExists(_datadir) then CreateDir(_datadir);
  if not DirectoryExists(_exceldir) then CreateDir(_exceldir);
  if not DirectoryExists(_logdir) then CreateDir(_logdir);

  if not FileExists(_bookpath) then
    begin
      MakeFdb;
      MakeTranzTabla;
      MakeAdvetTabla;
      MakeEvhoTabla;
    end;

end;

// =============================================================================
                  procedure TForm1.AdatNullazas;
// =============================================================================

var _x,_y: word;

begin
  ProgressPanel.Caption := 'Adatok nullázása ...';
  ProgressPanel.repaint;

  BookParancs('DELETE FROM TRANZAKCIOK');
  BookParancs('DELETE FROM ATADATVET');
  BookParancs('DELETE FROM EVHONAP');

  _y := 1;
  while _y<=4096 do
    begin
      _adPtBj[_y]     := 0;
      _kapPtBj[_y]    := 0;
      _ptDnemTpts[_y] := '';
      inc(_y);
    end;

  _y := 1;
  while _y<=170 do
    begin
      _x := 1;
      while _x<=27 do
        begin
          _vbj[_y,_x]   := 0;    // vettbankjegy[_penztarss,_dnemss]
          _vFt[_y,_x]   := 0;    // vett ertek[""]
          _ebj[_y,_x]   := 0;    // eladott bankjegy [""]
          _eFt[_y,_x]   := 0;    // eladott értéke valuta készpénzzel fizetve [""]
          _eBk[_y,_x]   := 0;    // eladott értéke valuta bankkártyával fizetve[""]
          _adbj[_y,_x]  := 0;    // átadott valuta benkjegyek[""]
          _kapbj[_y,_x] := 0;    // átvett valuta bankjegyek[""]

          inc(_x);     // következõ valutanem indexe
        end;

      inc(_y);        // következõ pénztár indexe
    end;

  _ptDnemTptsDarab := 0;
  ProgressPanel.Caption := '';
  progressPanel.repaint;
end;


// =============================================================================
              function TForm1.Null3(_apt: byte): string;
// =============================================================================

begin
  result := inttostr(_apt);
  while length(result)<3 do result := '0' + result;
end;


// =============================================================================
                function TForm1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
                     procedure TForm1.EvPanelsClear;
// =============================================================================

var _k: byte;

begin
  _k := 1;
  while _k<=3 do
    begin
      _aktpanel := _evpanel[_k];
      _aktPanel.color := clWhite;
      _aktpanel.Font.color := clSilver;
      inc(_k);
    end;
end;

// =============================================================================
                      procedure TForm1.HopanelsClear;
// =============================================================================

var _k: byte;

begin
  _k := 1;
  while _k<=12 do
    begin
      _aktpanel := _hopanel[_k];
      _aktPanel.color := clWhite;
      _aktpanel.Font.color := clSilver;
      inc(_k);
    end;
end;

// =============================================================================
                     procedure TForm1.TombbeOlvasas;
// =============================================================================

begin
  _evPanel[1]  := E1;
  _evPanel[2]  := E2;
  _evPanel[3]  := E3;

  _hopanel[1]  := H1;
  _hopanel[2]  := H2;
  _hopanel[3]  := H3;
  _hopanel[4]  := H4;
  _hopanel[5]  := H5;
  _hopanel[6]  := H6;
  _hopanel[7]  := H7;
  _hopanel[8]  := H8;
  _hopanel[9]  := H9;
  _hopanel[10] := H10;
  _hopanel[11] := H11;
  _hopanel[12] := H12;
end;

// =============================================================================
               procedure TForm1.BookParancs(_ukaz: string);
// =============================================================================

begin
  Bookdbase.close;
  Bookdbase.DatabaseName := _bookPath;
  Bookdbase.connected := True;
  if Booktranz.InTransaction then booktranz.Commit;
  Booktranz.StartTransaction;
  with BookQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Booktranz.commit;
  bookdbase.close;
end;

// =============================================================================
               function TForm1.Scanpenztar(_pz: byte): byte;
// =============================================================================

var _z: byte;

begin
  result := 0;
  _z := 1;
  while _z<=_penztarDarab do
    begin
      if _penztar[_z]=_pz then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;

// =============================================================================
           function TForm1.ScanPtDnemTpts(_apdTp: string): word;
// =============================================================================

var _k: word;

begin
  if _ptDnemTptsDarab=0 then
    begin
      _ptdnemTptsDarab := 1;
      _ptdnemTpts[1] := _apdTp;
      result := 1;
      exit;
    end;

  _k := 1;
  while _k<=_ptdnemTptsDarab do
    begin
      if _ptdnemTpts[_k]=_apdTp then
        begin
          result := _k;
          exit;
        end;
      inc(_k);
    end;
  inc(_ptdnemTptsdarab);
  _ptdnemTpts[_k] := _apdTp;
  result := _k;
end;

// =============================================================================
               procedure TForm1.excelopen(_excelNev: string);
// =============================================================================

begin
  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.open(_excelnev);
  _oxl.visible := True;
end;

// =============================================================================
                  procedure TForm1.ExcelKill;
// =============================================================================

var
  _fileName,_filePath: String;

begin

  _Proc.dwSize := SizeOf(_Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,_proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := _Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),_proc.th32ProcessID),0);
          break;
        end;

      _Looper := Process32Next(_handle,_proc);
    end;
  CloseHandle(_handle);
end;

// =============================================================================
               procedure TForm1.REMAKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  ExistPanel.Visible := False;
  Feldolgozas;;
end;

// =============================================================================
              procedure TForm1.OPENGOMBClick(Sender: TObject);
// =============================================================================

begin
  with OpenPanel do
    begin
      top := 24;
      left := 16;
      Visible := true;
      repaint;
    end;
  Activecontrol := ForgtablaGomb;
end;

// =============================================================================
           procedure TForm1.FINISHGOMBClick(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := true;
end;

// =============================================================================
              procedure TForm1.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;

  Bookdbase.close;
  Bookquery.close;

  ExcelKill;
  Application.Terminate;
end;

// =============================================================================
          procedure TForm1.ForgTablaGombClick(Sender: TObject);
// =============================================================================

begin
  excelopen(_forgexcelPath);
end;

// =============================================================================
             procedure TForm1.AtadTablaGombClick(Sender: TObject);
// =============================================================================

begin
  excelOpen(_advetexcelPath);
end;

// =============================================================================
            procedure TForm1.NyitoGombClick(Sender: TObject);
// =============================================================================

begin
  excelopen(_keszletexcelpath);
end;



// =============================================================================
            procedure TForm1.EgyiketseGombClick(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := True;
end;

// =============================================================================
               function TForm1.ScanDnem(_ad: string): byte;
// =============================================================================

var _z: byte;

begin
  result := 0;
  _z := 1;
  while _z<=27 do
    begin
      if _dnem[_z]=_ad then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;

// =============================================================================
           function TForm1.kerekito(_int: real): real;
// =============================================================================

var _nums: string;
    _utdig,_wnums: Byte;

begin
  result := _int;
  _nums := floattostr(_int);
  _wnums := length(_nums);
  _utdig := ord(_nums[_wnums])-48;
  if (_utdig<>0) and (_utdig<>5) then
    begin
      if (_utdig=1) or (_utdig=2) then result := _int-_utdig;
      if (_utdig=6) or (_utdig=7) then result := _int-(_utdig-5);
      if (_utdig=3) or (_utdig=4) then result := _int+(5-_utdig);
      if (_utdig=8) or (_utdig=9) then result := _int+10-_utdig;
    end;
end;

// =============================================================================
                       procedure TForm1.NyitoZaroBeolvasas;
// =============================================================================

var _eloevs: string;

begin
  progressPanel.Caption := 'Nyitó-záró készletek beolvasása ..';
  ProgressPanel.Repaint;

  NyitoZaroNullazas;  // nyitó-záró tömbök nullázása

  _eloev := _aktev;
  _eloho := _akthonap;

  dec(_eloho);
  if _eloho=0 then
    begin
      dec(_eloev);
      _eloho := 12;
    end;

  _eloevs    := inttostr(_eloev);
  _elofarok  := midstr(_eloevs,3,2)+nulele(_eloho);
  _elocimtar := 'CIMT' + _elofarok;
  _aktcimtar := 'CIMT' + _farok;

  Csik.Max := _nyitottPenztardarab;
  _nyitottIndex := 1;

  while _nyitottIndex<=_nyitottPenztardarab do
    begin
      prog2Panel.Caption := 'Nyitó készlet beolvasása ...';
      prog2Panel.repaint;

      Csik.Position := _nyitottIndex;

      _aktPenztar   := _nyitottPenztar[_nyitottIndex];

      prog3panel.caption := inttostr(_aktpenztar)+'. PÉNZTÁR';
      prog3Panel.repaint;

      _Vpath := _host + ':C:\receptor\database\V'+inttostr(_aktpenztar)+'.FDB';

      // A szerveren az aktpénztár adatbázisát nyitja:

      ibDbase.close;
      ibDbase.Databasename := _VPath;
      ibDbase.Connected := True;


      // Amennyiben van elõhavi cimtárban - akkor megnyitja

      ibtabla.close;
      ibtabla.TableName := _elocimtar;

      if ibtabla.Exists then
        begin
          // Megállapítja az elözõ hónap utolsó napját:

          _pcs := 'SELECT * FROM ' + _elocimtar + _sorveg;
          _pcs := _pcs + 'ORDER BY DATUM';
          with IbQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              Last;
              _utdatum := FieldByNAme('DATUM').asString;
              close;
            end;

          // Megnyitja a múlt hónap utolsó napját:

          _pcs := 'SELECT * FROM ' + _elocimtar + _sorveg;
          _pcs := _pcs + 'WHERE DATUM=' + chr(39)+ _utdatum +chr(39);

          with IbQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
            end;


          // Beolvassa az összes nyitó értéket:

          while not IbQuery.Eof do
            begin
              _aktdnem  := ibQuery.FieldByNAme('VALUTANEM').asString;
              _osszesen := ibquery.FieldByName('OSSZESEN').asFloat;

              _xx := Scandnem(_aktdnem);
              _nyito[_nyitottIndex,_xx] := _osszesen;
              ibquery.next;
            end;
          ibquery.close;

          // -----------------------------------------------------

          prog2Panel.Caption := 'Záró készlet beolvasása ...';
          prog2Panel.repaint;

          // Beolvassa az összes záró értéket:

          _pcs := 'SELECT * FROM ' + _aktcimtar + _sorveg;
          _pcs := _pcs + 'ORDER BY DATUM';
          with IbQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              Last;
              _utdatum := FieldByNAme('DATUM').asString;
              close;
            end;

          _pcs := 'SELECT * FROM ' + _aktcimtar + _sorveg;
          _pcs := _pcs + 'WHERE DATUM=' + chr(39)+ _utdatum +chr(39);
          with IbQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
            end;

          while not IbQuery.Eof do
            begin
              _aktdnem := ibQuery.fieldByNAme('VALUTANEM').asString;
              _osszesen := ibquery.fieldByName('OSSZESEN').asFloat;
              _xx := Scandnem(_aktdnem);
              _zaro[_nyitottIndex,_xx] := _osszesen;
              ibquery.next;
            end;
          ibquery.close;
          ibDbase.close;
        end;
      inc(_nyitottIndex);
    end;
  ibdbase.close;
end;

// =============================================================================
                   procedure  TForm1.NyitoZaroNullazas;
// =============================================================================

begin
  Csik.Max := _nyitottPenztardarab;
  _nyitottIndex := 1;

  Prog2Panel.Caption := 'Nyitó-záró készletek nullázása';
  Prog2Panel.repaint;

  while _nyitottIndex<=_nyitottPenztardarab do
    begin
      Csik.Position := _nyitottIndex;

      _dnemindex := 1;
      while _dnemIndex<=27 do
        begin
          prog3Panel.Caption := _dnem[_dnemindex];
          prog3panel.repaint;

          _nyito[_nyitottIndex,_dnemindex] := 0;
          _zaro[_nyitottIndex,_dnemindex]  := 0;
          inc(_dnemIndex);
        end;
      inc(_nyitottIndex);
    end;
end;


// =============================================================================
                procedure TForm1.NyitoZaroRegisztralas;
// =============================================================================

begin
  progressPanel.caption := 'Nyitó-záró adatok rögzitése adabázisban';
  progresspanel.repaint;

  Bookdbase.close;
  bookdbase.DatabaseName := 'c:\booking\database\booking.fdb';
  bookdbase.Connected := True;

  if booktranz.InTransaction then booktranz.commit;
  Booktranz.StartTransaction;

  with BookTabla do
    begin
      close;
      TableName := 'TRANZAKCIOK';
      Open;
      Last;
      _recno := recno;
      First;
    end;

  csik.Max := _recno;

  _pp := 0;
  while not booktabla.Eof do
    begin
      inc(_pp);
      Csik.Position := _pp;

      _aktpenztar := Booktabla.Fieldbyname('PENZTAR').asInteger;
      _aktdnem    := Booktabla.FieldByNAme('VALUTANEM').asString;

      _yy := ScanNyitoPenztar(_aktpenztar);
      _xx := Scandnem(_aktdnem);

      _aktnyito := _nyito[_yy,_xx];
      _aktzaro := _zaro[_yy,_xx];

      prog2Panel.Caption := inttostr(_aktpenztar)+'. pénztár';
      prog3Panel.Caption := 'valutanem = ' + _aktdnem;
      prog2Panel.repaint;
      prog3Panel.repaint;

      Booktabla.edit;
      booktabla.FieldByName('NYITO').AsFloat := _aktnyito;
      booktabla.FieldByName('ZARO').AsFloat  := _aktZaro;
      Booktabla.post;
      Booktabla.next;
    end;
  Booktranz.commit;
  Bookdbase.close;
  Booktabla.close;
end;

// =============================================================================
               function TForm1.ScanNyitopenztar(_pz: byte): byte;
// =============================================================================

var _z: byte;

begin
  result := 0;
  _z := 1;
  while _z<=_nyitottPenztarDarab do
    begin
      if _nyitottPenztar[_z]=_pz then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;

// =============================================================================
                   function TForm1.FinishControl: boolean;
// =============================================================================

var _logfile,_logPath: string;

begin
  result := true;
  //-------------------------------------------------

  _logfile := 'LOG' + _farok;
  _logPath := 'c:\booking\log\' + _logfile;

  Assignfile(_iras,_logPath);
  rewrite(_iras);


  Hibalista.Clear;
  Hibalista.Items.clear;

  Bookdbase.close;
  bookdbase.DatabaseName := 'c:\booking\database\booking.fdb';
  bookdbase.Connected := True;

  _nyitottIndex := 1;
  while _nyitottIndex<=_nyitottPenztarDarab do
    begin
      _aktpenztar := _nyitottPenztar[_nyitottIndex];

      prog2Panel.caption := inttostr(_aktpenztar)+'. pénztár';
      prog2panel.repaint;

      _pcs := 'SELECT * FROM TRANZAKCIOK' + _sorveg;
      _pcs := _pcs + 'WHERE PENZTAR=' + inttostr(_aktpenztar) + _sorveg;
      _pcs := _pcs + 'ORDER BY VALUTANEM';

      with BookQuery do
        begin
          Close;
          sql.clear;
          Sql.add(_pcs);
          Open;
          Last;
          _recno := recno;
          First;
        end;

      CtrlNullazas;

      csik.Max := _recno;
      _pp := 0;

      while not BookQuery.eof do
        begin
          inc(_pp);
          Csik.Position := _pp;
          GetCtrlData;  // beolvas egy rekordot
          if _aktdnem<>'HUF' then
            begin
              _szamzaro   := _aktnyito+_aktkap-_aktad+_aktvbjegy-_aktebjegy;
              _sumvett    := _sumvett + _aktkeszpenz;
              _sumeladott := _sumeladott + _aktvertek;

              _cst := inttostr(_aktpenztar)+'-'+_aktdnem+'-'+floattostr(_szamzaro)+'=';

              _cst := _cst+floattostr(_aktnyito)+'+'+floattostr(_aktkap)+'-'+floattostr(_aktad);
              _cst := _cst+'+'+floattostr(_aktvbjegy)+'-'+floattostr(_aktebjegy)+'==';
              _cst := _cst+floattostr(_aktzaro);

              writeLn(_iras,_cst);

              if _szamzaro<>_aktzaro then
                begin
                  _hibastr := inttostr(_aktpenztar)+'. pénztár '+_aktdnem;
                  _hibastr := _hibastr + ' -> ' + floattostr(_szamzaro)+'<>';
                  _hibastr := _hibastr + floattostr(_aktzaro);
                  Hibalista.Items.add(_hibastr);
                  result := False;
                end;
            end else   // forint HUF
            begin
              _hufnyito := _aktnyito;
              _hufkap   := _aktkap;
              _hufad    := _aktad;
              _szamhufzaro1 := _hufnyito+_hufkap-_hufad;
              _hufzaro := _aktzaro;
            end;
          Bookquery.next;
        end;
      BookQuery.close;

      _szamhufzaro := _szamhufzaro1 + _sumvett - _sumeladott;
      _cst := inttostr(_aktpenztar) + '-HUF-' + floattostr(_szamhufzaro) + '=';
      _cst := _cst + floattostr(_hufnyito)+'+'+floattostr(_hufkap)+'-'+floattostr(_hufad);
      _cst := _cst + '+' + floattostr(_sumvett) + '-' + floattostr(_sumeladott) + '==';
      _cst := _cst + floattostr(_hufzaro);
      writeLn(_iras,_cst);

      if _szamhufzaro<>_hufzaro then
        begin
          _hibastr := inttostr(_aktpenztar)+'. pénztár HUF ';
          _hibastr := _hibastr + '-> '+floattostr(_szamhufzaro);
          _hibastr := _hibastr + '<>'+floattostr(_hufzaro);
          HibaLista.Items.Add(_hibastr);
          result := false;
        end;
      inc(_nyitottIndex);
    end;
  closefile(_iras);
end;

// =============================================================================
                      procedure TForm1.CtrlNullazas;
// =============================================================================

begin
  _sumvett     := 0;
  _sumeladott  := 0;
  _hufzaro     := 0;
  _szamhufzaro := 0;
end;

// =============================================================================
                      procedure TForm1.GetCtrlData;
// =============================================================================

begin
  with BookQuery do
    begin
      _aktpenztar := FieldByNAme('PENZTAR').asInteger;
      _aktdnem    := FieldByNAme('VALUTANEM').asString;
      _aktnyito   := FieldByNAme('NYITO').asfloat;
      _aktzaro    := FieldByName('ZARO').asFloat;
      _aktad      := FieldByNAme('ATADAS').asFloat;
      _aktkap     := FieldByNAme('ATVETEL').asfloat;
      _aktvbjegy  := FieldByNAme('VETTBANKJEGY').asFloat;
      _aktebjegy  := FieldByNAme('ELADOTTBANKJEGY').asFloat;
      _aktvertek  := FieldByName('VETTERTEK').asFloat;
      _aktkeszpenz:= FieldByNAme('ELADOTTKESZPENZ').asFloat;
      _aktkartyas := Fieldbyname('ELADOTTKARTYAS').asFloat;
    end;
  _akteertek := _aktkeszpenz+_aktkartyas;
end;


// =============================================================================
              procedure TForm1.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  forgalomexcelrutin;
  advetexcelrutin;
  keszletexcelrutin;
  programFinish;
end;

// =============================================================================
                 procedure TForm1.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := true;
end;
end.



