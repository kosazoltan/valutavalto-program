unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, StrUtils, DateUtils,ShellAPI,
  IBDatabase, DB, IBCustomDataSet, IBTable, ComCtrls, Printers,
  IBQuery, Psock, Grids, Calendar, DBGrids;

type
  TNapiJelentes = class(TForm)
    KeszletPanel      : TPanel;
    Panel8            : TPanel;
    CimletPanel       : TPanel;
    Panel92           : TPanel;
    C1Panel           : TPanel;
    Panel94           : TPanel;
    Panel95           : TPanel;
    C8Panel           : TPanel;
    C2Panel           : TPanel;
    Panel98           : TPanel;
    Panel99           : TPanel;
    Panel100          : TPanel;
    Panel101          : TPanel;
    Panel102          : TPanel;
    Panel103          : TPanel;
    Panel104          : TPanel;
    Panel105          : TPanel;
    C3Panel           : TPanel;
    C9Panel           : TPanel;
    C10Panel          : TPanel;
    C4Panel           : TPanel;
    C5Panel           : TPanel;
    C11Panel          : TPanel;
    C6Panel           : TPanel;
    Panel113          : TPanel;
    C12Panel          : TPanel;
    C7Panel           : TPanel;
    Panel120          : TPanel;
    WUPANEL           : TPanel;
    Panel116          : TPanel;
    Panel118          : TPanel;
    Panel119          : TPanel;
    WUHUFPanel        : TPanel;
    WUUSDPanel        : TPanel;
    AFAPanel          : TPanel;
    Panel124          : TPanel;
    Panel125          : TPanel;
    InnovaPanel       : TPanel;
    EgyediPanel       : TPanel;
    Panel128          : TPanel;
    XVal1Panel        : TPanel;
    XSum1Panel        : TPanel;
    XArf1Panel        : TPanel;
    XBiz1Panel        : TPanel;
    Panel133          : TPanel;
    Panel134          : TPanel;
    Panel135          : TPanel;
    Panel136          : TPanel;
    XBiz2Panel        : TPanel;
    XVal2Panel        : TPanel;
    XSum2Panel        : TPanel;
    XArf2Panel        : TPanel;
    XVal3Panel        : TPanel;
    XSum3Panel        : TPanel;
    XArf3Panel        : TPanel;
    XBiz3Panel        : TPanel;
    XVal4Panel        : TPanel;
    XSum4Panel        : TPanel;
    XArf4Panel        : TPanel;
    XBiz4Panel        : TPanel;
    ZaroPanel         : TPanel;
    ZForintPanel      : TPanel;
    Panel151          : TPanel;
    Panel152          : TPanel;
    DatumPanel        : TPanel;
    UzletnevPanel     : TPanel;
    Panel155          : TPanel;
    ZValutaPanel      : TPanel;
    ZOsszesPanel      : TPanel;
    Panel158          : TPanel;
    ForgalomPanel     : TPanel;
    VSumPanel         : TPanel;
    ESumPanel         : TPanel;
    Panel162          : TPanel;
    Panel163          : TPanel;
    VDePanel          : TPanel;
    VDuPanel          : TPanel;
    EDePanel          : TPanel;
    EDuPanel          : TPanel;
    Panel168          : TPanel;
    MEMOKerek         : TMemo;
    MemoKuldok        : TMemo;
    ProsNevPanel      : TPanel;
    XSum5Panel        : TPanel;
    Panel171          : TPanel;
    Panel172          : TPanel;
    DeProsNevPanel    : TPanel;
    DuProsNevPanel    : TPanel;
    XSum6Panel        : TPanel;
    XSum7Panel        : TPanel;
    XSum8Panel        : TPanel;
    XSum9Panel        : TPanel;
    XSum10Panel       : TPanel;
    XArf5Panel        : TPanel;
    XArf6Panel        : TPanel;
    XArf7Panel        : TPanel;
    XArf8Panel        : TPanel;
    XArf9Panel        : TPanel;
    XArf10Panel       : TPanel;
    XBiz5Panel        : TPanel;
    XVal5Panel        : TPanel;
    XVal6Panel        : TPanel;
    XBiz6Panel        : TPanel;
    XBiz7Panel        : TPanel;
    XBiz8Panel        : TPanel;
    XVal7Panel        : TPanel;
    XVal8Panel        : TPanel;
    XVal9Panel        : TPanel;
    XVal10Panel       : TPanel;
    XBiz9Panel        : TPanel;
    XBiz10PANEL       : TPanel;
    Label1            : TLabel;
    Label2            : TLabel;
    Label3            : TLabel;
    Label4            : TLabel;
    Label5            : TLabel;
    Label6            : TLabel;
    NapiVetelLabel    : TLabel;
    NapiEladasLabel   : TLabel;
    DuVetLabel        : TLabel;
    DuEladasLabel     : TLabel;
    DeVETLabel        : TLabel;
    DeEladasLabel     : TLabel;
    InditoTimer       : TTimer;

    BFTabla           : TIBTable;
    BFDbase           : TIBDatabase;
    BFTranz           : TIBTransaction;

    BTTabla           : TIBTable;
    BTDbase           : TIBDatabase;
    BTTranz           : TIBTransaction;

    FejSource         : TDataSource;
    Panel1            : TPanel;
    Panel2            : TPanel;
    EE2Panel          : TPanel;
    Panel4            : TPanel;
    EE1Panel          : TPanel;
    KuldoPanel        : TPanel;
    Panel3            : TPanel;
    KezdijErtekPanel  : TPanel;
    Panel11           : TPanel;
    EkerErtekPanel    : TPanel;
    BekuldoGomb       : TBitBtn;
    CANCELGomb        : TBitBtn;
    ValutaQUERY       : TIBQuery;
    ValutaDBASE       : TIBDatabase;
    ValutaTranz       : TIBTransaction;
    ValDATAQuery      : TIBQuery;
    ValDATADbase      : TIBDatabase;
    ValDATATRANZ      : TIBTransaction;
    ValDATATABLA      : TIBTable;
    BFQUERY           : TIBQuery;
    BTQUERY           : TIBQuery;
    TRADEQUERY        : TIBQuery;
    TRADEDBASE        : TIBDatabase;
    TRADETRANZ        : TIBTransaction;
    PillRACS          : TDBGrid;
    PillQUERY         : TIBQuery;
    PillDBASE         : TIBDatabase;
    PillTRANZ         : TIBTransaction;
    PillSOURCE        : TDataSource;
    VQUERY            : TIBQuery;
    VDBASE            : TIBDatabase;
    VTRANZ            : TIBTransaction;
    KULDOKPANEL       : TPanel;
    Label10           : TLabel;
    KEREKPANEL        : TPanel;
    Label11           : TLabel;
    FUGGONY           : TPanel;
    Label7            : TLabel;
    PILLQUERYVALUTANEM: TIBStringField;
    PILLQUERYZARO     : TIntegerField;
    PILLQUERYVETEL    : TIntegerField;
    PILLQUERYELADAS   : TIntegerField;
    KILEPO: TTimer;

    procedure AdatlapKijelzes;
    procedure AdatlapTorles;
    procedure AlapAdatBeolvasas;
    procedure BekuldoGombClick(Sender: TObject);
    procedure ByteKoder(_b: byte);
    procedure CancelGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure InditoTimerTimer(Sender: TObject);
    procedure IntegerKoder(_i: integer);
    procedure JelentesIras;
    procedure MemoAnalizis;
    procedure MemoKerekEnter(Sender: TObject);
    procedure MemoKerekExit(Sender: TObject);
    procedure PillParancs(_ukaz: string);
    procedure Textkoder(_s: string);
    procedure TombBerakas;
    procedure ValutaParancs(_ukaz: string);
    procedure WordKoder(_w: word);

    function Adatmeghatarozas:boolean;
    function Arfform(_a: integer): string;
    function CimletBeolvasas(_tnev: string):boolean;
    function ForgalomBeolvasas(_tfarok: string):boolean;
    function Ftform(_ft: integer): string;
    function GetRegiSvajciFrank: integer;
    function GetJelentesPath(_datumstring: string): string;
    function Getjelszo: string;
    function KedvezmenyBeolvasas(_tnev:string):boolean;
    function ScanDnem(_d: string): byte;
    procedure KILEPOTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NAPIJELENTES: TNAPIJELENTES;

  _honapnev: array[1..12] of string = ('Január','Február','Március','Április',
                'Május','Junius','Július','Augusztus','Szeptember','Október',
                'November','December');

  _Dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                          'CZK','DKK','EUR','GBP','HRK','HUF','ILS',
                          'JPY','MXN','NOK','NZD','PLN','RON','RSD','RUB',
                          'SEK','THB','TRY','UAH','USD');

  _KedvDarab: byte;
  _xval,_xsum,_xarf,_xbiz: array[1..10] of TPanel;
  _kedvDnem,_kedvBiz : array[1..10] of string;
  _kedvArf,_kedvBjegy: array[1..10] of integer;

  _cimlet: array[1..12] of TPanel;
  _ftcimlet: array[1..12] of word;
  _bytetomb: array[1..4096] of byte;

  _keszDarab: byte;
  _keszkeszlet,_keszvetel,_keszEladas: array[1..27] of Integer;
  _keszDnem: array[1..27] of string;

  _elsz,_tZaro: array[1..27] of integer;
  _kersor,_kuldsor: array[1..10] of string;

  _iras: File of Byte;

  _aktPanel: TPanel;

  _z,_kellMatrica,_xx,_hufIndex,_coin,_kersordb,_kuldsordb,_ertektar,_asc: byte;
  _homePenztarszam,_hihi,_hilo,_hi,_lo: byte;

  _top,_left,_height,_width,_ee1,_ee2,_vettErme,_pp,_aktcimlet: word;

  _aktZaro,_aktVetel,_aktEladas,_control,_wuUsd,_wuHuf,_metro,_tesco,_afa: integer;
  _napiKezdij,_napiEkerForint,_zForint,_zValuta,_recno,_oFt,_aktelszarf: integer;
  _zOsszes,_deVet,_duVet,_deEladas,_duEladas,_aktErtek,_bankJegy: integer;
  _sumVet,_sumEladas,_aktKeszlet,_aktcim,_aktArf,_code,_mResult,_regifrank: integer;

  _farok,_zDatums,_aktDnem,_deProsnev,_duProsnev,_pcs,_tipus,_bizonylatszam: string;
  _aktProsNev,_elojel,_homePenztarnev,_aktBiz,_bejelszo,_aktbizonylat: string;
  _aktText,_jelentesPath: string;

  _sorveg: string = chr(13)+chr(10);

  _ketmuszak: boolean;


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

  _top  := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top  := _top;
  Left := _left;

  Height := 768;
  Width  := 1024;

  with Fuggony do
    begin
      Top     := 0;
      Left    := 0;
      Visible := True;
    end;

  TombBerakas;
  AlapadatBeolvasas;

  InditoTimer.Enabled := true;
end;

// =============================================================================
          procedure TNAPIJELENTES.INDITOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  InditoTimer.Enabled := False;

  if not AdatMeghatarozas then
    begin
      _Mresult := 2;
      Kilepo.Enabled := true;
      exit;
    end;

   Adatlaptorles;
   AdatlapKijelzes;

   Fuggony.Visible := False;
end;


// =============================================================================
                 function TNapiJelentes.Adatmeghatarozas:boolean;
// =============================================================================

var _arfenev,_ctnev: string;

begin
   // _zDatums = A napi jelentés dátuma
   Result := False;

  _farok := midstr(_zDatums,3,2)+midstr(_zDatums,6,2);
  _ctnev := 'CIMT'+ _farok;

  // Ha nincs jelentésnapi cimletezés, akkor nincs jelentés se
  if not CimletBeolvasas(_ctNev) then
    begin
      ShowMessage('NEM TALÁLOM A ' + _zDatums + '-I CIMLETEZÉST !');
      exit;
    end;

  _arfenev := 'ARFE'+_FAROK;
  KedvezmenyBeolvasas(_arfenev);

  // ---------------------------------------------------------------------------

  if not ForgalomBeolvasas(_farok) then Showmessage('Nem volt forgalom ?');

  // Tömbökbe irja a készlet,vétel, és eladás adatait:

  _keszDarab := 0;
  _z := 1;
  while _z<=27 do
    begin
      _aktdnem   := _Dnem[_z];
      _aktzaro   := _tzaro[_z];
      _aktvetel  := _keszVetel[_z];
      _akteladas := _keszEladas[_z];

      _control := _aktzaro+_aktvetel+_akteladas;

      if _control>0 then
        begin
          inc(_keszDarab);
          _KeszDnem[_keszdarab]    := _aktdnem;
          _KeszKeszlet[_keszdarab] := _aktzaro;
          _KeszVetel[_keszdarab]   := _aktVetel;
          _KeszEladas[_keszdarab]  := _aktEladas;
        end;
       inc(_z);
    end;

  // ---------------------------------------------------------------------------

  if not _ketMuszak then _deprosnev := '';

  // ---------------------------------------------------------------------------

  Valdatadbase.Connected := true;

  _pcs := 'SELECT * FROM WZAR' + _farok + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _zDatums + chr(39);

  with ValdataQuery do
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
  ValdataDbase.close;

  _afa := _metro + _tesco;

  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------

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

  Result := true;
end;


// =============================================================================
        function TNapiJelentes.CimletBeolvasas(_tnev: string):boolean;
// =============================================================================

var i,z: integer;
    _mezonev: string;

begin

  // NULLÁZÁS:

  _ee1 := 0;
  _ee2 := 0;

  for i := 1 to 27 do _tzaro[i] := 0;

  _zForint := 0;
  _zValuta := 0;

  for i := 1 to 12 do _ftcimlet[i] := 0;

  Result := False;

  //---------------------------------------------------------

  ValdataTabla.Close;
  ValdataDbase.Connected := True;

  ValdataTabla.TableName := _tNev;
  if not ValdataTabla.Exists then exit;

  _pcs := 'SELECT * FROM '+ _tNev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+ _zDatums + chr(39);

  with ValdataQuery do
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
      ValdataQuery.close;
      ValdataDbase.close;
      Exit;
    end;

  while not ValdataQuery.Eof do
    begin
      _aktdnem := ValdataQuery.FieldByName('VALUTANEM').asString;
      _oFt     := ValdataQuery.FieldByName('OSSZESFORINTERTEK').asInteger;
      _xx      := scandnem(_aktdnem);
      if _xx = 0 then
        begin
          ValdataQuery.next;
          continue;
        end;

      if _aktDnem='EUR' then
        begin
          _ee2 := ValdataQuery.FieldByName('CIMLET13').AsInteger;
          _ee1 := ValdataQuery.FieldByName('CIMLET14').AsInteger;
        end;

      if _aktdnem='HUF' then
        begin
          _zforint := _oFt;
          for z := 1 to 12 do
            begin
              _mezonev := 'CIMLET'+inttostr(z);
              _ftCimlet[z] := ValdataQuery.FieldByName(_mezonev).asInteger;
            end;
        end else
        Begin
          _aktelszarf := _elsz[_xx];
          _zValuta := _zValuta + trunc((_oFt*_aktelszarf)/100);
        end;

      _Tzaro[_xx] := _oft;
      ValdataQuery.Next;
    end;
  ValdataQuery.close;
  Valdatadbase.close;

  _zOsszes := _zValuta + _zForint;
  Result := True;
end;

// =============================================================================
       function TNapiJelentes.KedvezmenyBeolvasas(_tnev:string):boolean;
// =============================================================================

var _engtipus: integer;
    _lobyte: word;

begin
  Result := False;
  _KedvDarab := 0;

  ValdataTabla.close;
  ValdataDbase.connected := true;
  ValdataTabla.TableName := _tnev;

  if not ValdataTabla.Exists then
    begin
      ValdataDbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _tNev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_ZDatums + chr(39);

  with ValdataQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _Recno = 0 then
    begin
      ValdataQuery.Close;
      ValdataDbase.close;
      Exit;
    end;

  while not ValdataQuery.Eof do
    begin
      _EngTipus := ValdataQuery.FieldByNAme('ENGEDMENYTIPUSSZAM').asInteger;
      _lobyte := (_Engtipus AND 255);

      if (_LOBYTE<16) then
        begin
          ValdataQuery.Next;
          Continue;
        end;

      inc(_KedvDarab);
      with ValdataQuery do
        begin
          _kedvDnem[_KedvDarab] := FieldByName('VALUTANEM').asstring;
          _kedvArf[_kedvDarab]  := FieldByName('UJARFOLYAM').asInteger;
          _kedvBjegy[_kedvDarab]:= FieldByName('BANKJEGY').asInteger;
          _kedvBiz[_KedvDarab]  := FieldByName('BIZONYLATSZAM').asString;
        end;

      if _KedvDarab>9 then break;
      ValdataQuery.next;
    end;

  ValdataQuery.Close;
  Valdatadbase.close;

  Result := True;
end;


// =============================================================================
      function TNapiJelentes.ForgalomBeolvasas(_tfarok: string):boolean;
// =============================================================================

var i: integer;

begin
  Result := False;
  _vetterme := 0;

  for i := 1 to 27 do
    begin
      _keszVetel[i] := 0;
      _keszEladas[i] := 0;
    end;

  _pcs := 'SELECT * FROM BF' + _tfarok + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM=' + chr(39)+_zDatums+chr(39)+') AND (STORNO=1)';

  BfTabla.close;
  BfDbase.Connected := True;
  BfTabla.TableName := 'BF' + _tfarok;
  if not Bftabla.exists then
    begin
      bfdbase.close;
      exit;
    end;

  with Bfquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      Bfquery.close;
      Bfdbase.close;
      exit;
    end;

// --------------------- pénztárosok neghatározása -----------------------------

  _deprosnev := Bfquery.FieldByName('PENZTAROSNEV').asString;

  BfQuery.Last;
  _duprosnev := BfQuery.FieldByName('PENZTAROSNEV').asString;

  _deprosnev := trim(_deprosnev);
  _duProsnev := trim(_duprosnev);

  _deVet    := 0;
  _duVet    := 0;
  _deEladas := 0;
  _duEladas := 0;

  BfQuery.First;
  _ketmuszak := True;

  if _deProsnev=_duProsnev then
    begin
      _deProsnev := '';
      _ketmuszak := False;
    end;

//------------------------------------------------------------------------------

  _hufindex := ScanDnem('HUF');
  _vettErme := 0;

  Bfquery.First;
  while not BfQuery.eof do
    begin
       _tipus         := BFQuery.FieldByName('TIPUS').asString;
       _bizonylatszam := BfQuery.FieldByName('BIZONYLATSZAM').asstring;
       _aktprosnev    := trim(BfQuery.FieldByName('PENZTAROSNEV').asString);

       if (_tipus='F') or (_tipus='U') then
         begin
           BfQuery.next;
           Continue;
         end;

       _pcs := 'SELECT * FROM BT'+ _tfarok + _sorveg;
       _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_bizonylatszam+chr(39);

       Btdbase.Connected := true;
       with BTQuery do
         begin
           Close;
           Sql.clear;
           Sql.Add(_pcs);
           Open;
           First;
         end;

       while not Btquery.Eof do
         begin
           with BTQuery do
             begin
               _aktdnem  := FieldByName('VALUTANEM').AsString;
               _aktertek := FieldByNAme('FORINTERTEK').asInteger;
               _bankjegy := FieldByName('BANKJEGY').asInteger;
               _elojel   := FieldByName('ELOJEL').asstring;
               _coin     := FieldByName('COIN').asInteger;
             end;

           if _aktdnem='HUF' then
             begin
               BTQuery.Next;
               Continue;
             end;

           if _coin=1 then _vettErme := _vettErme + _bankjegy;

           _xx := ScanDnem(_aktdnem);
           if _xx=0 then
             begin
               BTquery.Next;
               Continue;
             end;

           if (_aktprosnev=_duProsnev) OR (NOT _ketMuszak) then
             begin
               if _elojel='+' then
                 begin
                   _duvet := _duvet+_aktertek;
                   _keszVetel[_xx] := _keszVetel[_xx] + _bankjegy;
                   _keszVetel[_hufindex] := _keszVetel[_hufindex] + _aktertek;
                 end else
                 begin
                   _duEladas := _duEladas + _aktertek;
                   _keszEladas[_xx] := _keszEladas[_xx] + _bankjegy;
                   _keszEladas[_hufindex] := _keszEladas[_hufindex] + _aktertek;
                 end;
             end else
             begin
               if _elojel='+' then
                 begin
                   _devet := _devet+_aktertek;
                   _keszVetel[_xx] := _keszVetel[_xx] + _bankjegy;
                   _keszVetel[_hufindex] := _keszVetel[_hufindex] + _aktertek;
                 end else
                 begin
                   _deEladas := _deEladas + _aktertek;
                   _keszEladas[_xx] := _keszEladas[_xx] + _bankjegy;
                   _keszEladas[_hufindex] := _keszEladas[_hufindex] + _aktertek;
                 end;
             end;
           BtQuery.Next;
         end;
       Btquery.close;
       Btdbase.close;

       BfQuery.Next;
     end;
   BfQuery.Close;
   Bfdbase.Close;

   _sumvet := _deVet+_duVet;
   _sumEladas := _deEladas + _duEladas;

   Result := True;
end;

// =============================================================================
                     procedure Tnapijelentes.adatLapTorles;
// =============================================================================

var i: byte;

begin
  DatumPanel.caption      := '';
  UzletnevPanel.caption   := '';
  ZForintPanel.caption    := '';
  ZValutaPanel.Caption    := '';
  zOsszesPanel.caption    := '';
  DevetLabel.caption      := '';
  DuvetLabel.caption      := '';
  DeEladasLabel.caption   := '';
  DuEladasLabel.caption   := '';
  NapivetelLabel.caption  := '';
  NapiEladasLabel.caption := '';

  for i := 1 to 12 do _cimlet[i].caption := '';

  ee2Panel.caption := '';
  ee1Panel.caption := '';
  MemoKuldok.Lines.Clear;
  MemoKuldok.Clear;

  for i := 1 to 10 do
    begin
      _xVal[i].Caption := '';
      _xarf[i].Caption := '';
      _xSum[i].Caption := '';
      _xBiz[i].Caption := '';
    end;

  MemoKerek.Lines.Clear;
  MemoKerek.Clear;

  WuhufPanel.Caption       := '';
  WuusdPanel.Caption       := '';
  InnovaPanel.Caption      := '';
  KezdijErtekPanel.Caption := '';
  EkerErtekPanel.Caption   := '';
  DeprosnevPanel.Caption   := '';
  DUProsnevPanel.Caption   := '';

  PillSource.Enabled := False;
  _pcs := 'DELETE FROM NAPIZAR';
  PillParancs(_pcs);
end;

// =============================================================================
                  procedure TnapiJelentes.AdatlapKijelzes;
// =============================================================================

begin
  DatumPanel.Caption := _zDatums;
  UzletnevPanel.Caption := _homePenztarnev;

  zForintPanel.Caption := FtForm(_zForint);
  zValutaPanel.Caption := FtForm(_zVAluta);
  zOsszesPanel.Caption := FtForm(_zOsszes);

  DevetLabel.Caption := FtForm(_devet)+' Ft';
  DuVetLabel.Caption := FtForm(_duVet)+' Ft';

  DeEladasLabel.Caption := FtForm(_deEladas)+' Ft';
  DuEladasLabel.Caption := FtForm(_duEladas)+' Ft';

  NapiVetelLabel.Caption  := FtForm(_sumvet)+' Ft';
  NapiEladasLabel.Caption := FtForm(_sumEladas) + ' Ft';

  _z := 1;
  while _z<=_keszDarab do
    begin
      _aktdnem    := _keszdnem[_z];
      _aktkeszlet := _keszKeszlet[_z];
      _aktvetel   := _keszVetel[_z];
      _akteladas  := _keszEladas[_z];

      _pcs := 'INSERT INTO NAPIZAR (VALUTANEM,VETEL,ELADAS,ZARO)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktvetel) + ',';
      _pcs := _pcs + inttostr(_akteladas) + ',';
      _pcs := _pcs + inttostr(_aktkeszlet) + ')';
      PillParancs(_pcs);
      inc(_z);
    end;

  _z := 1;
  while _z<=12 do
    begin
      _aktpanel := _cimlet[_z];
      _aktcim   := _ftCimlet[_z];
      _aktPanel.Caption := ftForm(_aktcim);
      inc(_z);
    end;

  ee2Panel.Caption := inttostr(_ee2);
  ee1Panel.Caption := inttostr(_ee1);

  if _wuHuf>0 then wuhufPanel.Caption := FtForm(_wuhuf)+' Ft'
  else wuhufpanel.Caption := '-';

  if _wuUsd>0 then wuUsdPanel.Caption := '$ ' + ftform(_wuUsd)
  else wuusdPanel.Caption := '-';

  if _afa>0 then InnovaPanel.Caption := FtForm(_afa)+ ' Ft'
  else InnovaPanel.Caption := '-';

  _z := 1;
  while _z<=_KedvDarab do
    begin
      _aktdnem := _KedvDnem[_z];
      _aktkeszlet := _KedvBjegy[_z];
      _aktarf := _KedvArf[_z];
      _aktbiz := _Kedvbiz[_z];

      _aktPanel := _xVal[_z];
      _aktpanel.Caption := _aktdnem;

      _aktPanel := _xSum[_z];
      _aktpanel.Caption := ftForm(_aktkeszlet);

       _aktPanel := _xArf[_z];
      _aktpanel.Caption := arfForm(_aktarf);

      _aktPanel := _xBiz[_z];
      _aktpanel.Caption := _aktBiz;

      inc(_z);
    end;

  if _NapiKezdij>0 then KezdijErtekPanel.Caption := FtForm(_napikezdij)+' Ft'
  else KezdijertekPanel.Caption := '-';

  if _napiEkerForint>0 then EkerErtekPanel.Caption := FtForm(_napiEkerForint)+' Ft'
  else EkerErtekPanel.Caption := '-';

  if _deprosnev<>'' then DeProsnevPanel.Caption := _deprosnev;
  if _duprosnev<>'' then DuProsnevPanel.Caption := _duprosnev;

  PillSource.Enabled := False;

  Pilldbase.Connected := True;
  with Pillquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM NAPIZAR');
      Open;
    end;
  PillSource.Enabled := True;

end;


// =============================================================================
                    function TNapiJelentes.Getjelszo: string;
// =============================================================================

var _password,_jelszokelte,_pwhos,_zdhos: string;

begin

  ValutaDbase.Connected := true;
  _pcs := 'SELECT * FROM HARDWARE';

  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _password := FieldbyName('JELSZO').asstring;
      _jelszokelte := trim(FieldByName('JELSZOKELTE').asString);
      Close;
    end;
  Valutadbase.close;

  if _jelszokelte='' then
    begin
      _jelszoKelte := _zDatums;
      _pcs := 'UPDATE HARDWARE SET JELSZOKELTE='+chr(39)+_zDatums+chr(39);
      ValutaParancs(_pcs);
    end;

  _pwhos := midstr(_jelszokelte,6,2);
  _zdhos := midstr(_zDatums,6,2);

  if (_pwHos<>_zdHos) or (_password='') then
    begin
      _password := inputbox('JELSZÓ BEKÉRÉSE','Kérem az új jelszavat: ',_password);
      _password := Uppercase(trim(_password));
      _pcs := 'UPDATE HARDWARE SET JELSZOKELTE='+chr(39)+_zDatums+chr(39)+',';
      _pcs := _pcs + 'JELSZO=' + chr(39)+_password+chr(39);
      ValutaParancs(_pcs);
    end;
  Result := _password;
end;


// =============================================================================
                      procedure TNapiJelentes.JelentesIras;
// =============================================================================

var _aktevs,_akthos,_aktnaps: string;
    _aktev,_aktho,_aktnap,_jelentesHossz: word;
    _qq: byte;

begin

  _beJelszo := Getjelszo;

  _bytetomb[1] := 78;  // N     = RÉGI SVÁJCI FRANKOS ID = 'NW'
  _bytetomb[2] := 87;  // W

  _aktevs := leftstr(_zDatums,4);
  _akthos := midstr(_zDatums,6,2);
  _aktnaps:= midstr(_zDatums,9,2);

  val(_aktevs,_aktev,_code);
  val(_akthos,_aktho,_code);
  val(_aktnaps,_aktnap,_code);

  _byteTomb[3] := _aktev-2000;
  _byteTomb[4] := _aktho;
  _byteTomb[5] := _aktnap;

  _pp := 6;
  Textkoder(_bejelszo);
  TextKoder(_homepenztarnev);

  integerKoder(_zForint);
  integerKoder(_zValuta);

  ByteKoder(_keszDarab);

  _qq := 1;
  while _qq<=_keszDarab do
    begin
      _aktdnem    := _keszdnem[_qq];
      _aktkeszlet := _keszkeszlet[_qq];
      _aktVetel   := _keszVetel[_qq];
      _aktEladas  := _keszEladas[_qq];

      Textkoder(_aktdnem);
      integerKoder(_aktkeszlet);
      integerKoder(_aktvetel);
      integerKoder(_akteladas);
      inc(_qq);
    end;

  IntegerKoder(_devet);
  IntegerKoder(_deeladas);

  IntegerKoder(_duvet);
  IntegerKoder(_dueladas);

  wordKoder(_vettErme);
  wordKoder(_ee1);
  wordKoder(_ee2);

  _qq := 1;
  while _qq<=12 do
    begin
      _aktcimlet := _ftcimlet[_qq];
      wordKoder(_aktcimlet);
      inc(_qq);
    end;

  IntegerKoder(_wuUsd);
  IntegerKoder(_wuHuf);
  IntegerKoder(_AFA);

  ByteKoder(_KedvDarab);

  _qq := 1;
  while _qq<=_KedvDarab do
    begin
      _aktdnem := _KedvDnem[_qq];
      _aktkeszlet := _KedvBjegy[_qq];
      _aktarf := _KedvArf[_qq];
      _aktBizonylat := _KedvBiz[_qq];

      Textkoder(_aktdnem);
      IntegerKoder(_aktkeszlet);
      IntegerKoder(_aktarf);
      TextKoder(_aktBizonylat);
      inc(_qq);
    end;

  MemoAnalizis;

  Bytekoder(_kerSordb);
  if _kersordb>0 then
    begin
      _qq := 1;
      while _qq<=_kerSordb do
        begin
          _aktText := _kersor[_qq];
          TextKoder(_akttext);
          inc(_qq);
        end;
    end;

  ByteKoder(_kuldSordb);
  if _kuldsordb>0 then
    begin
      _qq := 1;
      while _qq<=_kuldSordb do
        begin
          _aktText := _kuldsor[_qq];
          TextKoder(_akttext);
          inc(_qq);
        end;
    end;

  integerkoder(_napikezdij);
  integerkoder(_napiEkerForint);

  textKoder(_deprosnev);
  TextKoder(_duProsnev);

  integerKoder(_regifrank);

  byteKoder(255);
  byteKoder(255);
  bytekoder(255);

  _JelentesHossz := _pp-1;

  _jelentesPath := GetJelentesPath(_zDatums);

  AssignFile(_iras,_jelentesPath);
  rewrite(_iras);
  Blockwrite(_iras,_bytetomb,_jelentesHossz);
  CLoseFile(_iras);
end;


// =============================================================================
          procedure TNAPIJELENTES.CANCELGOMBClick(Sender: TObject);
// =============================================================================

begin
  _Mresult := 2;
  Kilepo.Enabled := True;
end;

// =============================================================================
          procedure TNAPIJELENTES.BEKULDOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _regiFrank := GetregiSvajciFrank;
  JelentesIras;
  ShowMessage('A NAPI JELENTÉS KÜLDÉSRE ELÖKÉSZITVE !');
  _MResult := 1;
  Kilepo.Enabled := true;
end;


// =============================================================================
                       procedure TnapiJelentes.MemoAnalizis;
// =============================================================================

begin

  MemoKerek.Refresh;

  _kersordb := MemoKerek.Lines.Count;
  if _kersordb>0 then
     begin
       _z := 1;
       while _z<=_kersordb do
         begin
           _kersor[_z] := Memokerek.Lines[_z-1];
           inc(_z);
         end;
     end;

  MemoKuldok.Refresh;

  _kuldsordb := MemoKuldok.Lines.Count;
  if _kuldSordb>0 then
    begin
      _z := 1;
      while _z<=_kuldsordb do
        begin
          _kuldsor[_z] := MemoKuldok.Lines[_z-1];
          inc(_z);
        end;
    end;
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
                   procedure Tnapijelentes.AlapadatBeolvasas;
// =============================================================================

var _ptarnums: string;
    _elszarf: integer;

begin
  valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;

      _kellmatrica := FieldByName('KELLMATRICA').asInteger;
      _ertektar := FieldByNAme('ERTEKTAR').asInteger;
      _zDATUMS := FieldbyName('MEGNYITOTTNAP').asString;
      Close;

      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _ptarnums := trim(FieldbyName('PENZTARKOD').AsString);
      _homepenztarnev := trim(FieldByName('PENZTARNEV').AsString);
      Close;

      Sql.clear;
      Sql.add('SELECT * FROM ARFOLYAM');
      Open;
    end;

  while not ValutaQuery.eof do
    begin
      _aktdnem := ValutaQuery.FieldByNAme('VALUTANEM').asstring;
      _elszarf := ValutaQuery.FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;

      _xx := ScanDnem(_aktdnem);
      if _xx>0 then _elsz[_xx] := _elszarf;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  val(_ptarnums,_homePenztarszam,_code);

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
        function TNapijelentes.GetjelentesPath(_datumstring: string): string;
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
                       procedure TNapiJelentes.TombBerakas;
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

// =============================================================================
            function TnapiJelentes.Ftform(_ft: integer): string;
// =============================================================================

var _w,_f1: byte;

begin
  result := '-';
  if _ft=0 then exit;

  result := inttostr(_ft);
  if _ft<1000 then exit;

  _w := length(result);
  if _w<7 then
    begin
      _f1 := _w-3;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
      exit;
    end;
  _f1 := _w-6;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
end;

// =============================================================================
            function TNapiJelentes.arfform(_a: integer): string;
// =============================================================================

var _f1: byte;

begin
  result := inttostr(_a);
 _f1 := length(result)-2;
 result := leftstr(result,_f1)+','+midstr(result,_f1+1,2);
end;

// =============================================================================
               procedure TNapiJelentes.TextKoder(_s: string);
// =============================================================================

var _w: byte;

begin
  _s := trim(_s);
  _w := length(_s);
  _bytetomb[_pp] := _w;
  inc(_pp);

  if _w=0 then exit;
  _z := 1;
  while _z<=_w do
    begin
      _asc := 255-ord(_s[_z]);
      _bytetomb[_pp] := _asc;
      inc(_pp);
      inc(_z);
    end;
end;

// =============================================================================
              procedure TNapiJelentes.IntegerKoder(_i: integer);
// =============================================================================

var _maradt: integer;

begin
  _hihi := trunc(_i/16777216);
  _maradt := _i-trunc(16777216*_hihi);
  _hilo := trunc(_maradt/65536);
  _maradt := _maradt-trunc(_hilo*65536);
  _hi := trunc(_maradt/256);
  _lo := _maradt-trunc(256*_hi);

  _bytetomb[_pp] := _lo;
  _bytetomb[_pp+1] := _hi;
  _bytetomb[_pp+2] := _hilo;
  _bytetomb[_pp+3] := _hihi;

  _pp := _pp + 4;
end;

// =============================================================================
                 procedure TNapiJelentes.wordKoder(_w: word);
// =============================================================================

begin
  _hi := trunc(_w/256);
  _lo := _w - trunc(256*_hi);
  _bytetomb[_pp] := _lo;
  _bytetomb[_pp+1] := _hi;
  _pp := _pp + 2;
end;

// =============================================================================
               procedure TNapiJelentes.ByteKoder(_b: byte);
// =============================================================================

begin
  _bytetomb[_pp] := _b;
  inc(_pp);
end;

// =============================================================================
             function Tnapijelentes.ScanDnem(_d: string): byte;
// =============================================================================

begin
  result := 0;
  _z := 1;
  while _z<=27 do
    begin
      if (_d=_dnem[_z]) then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;

(* Az infofile neve: 99081231.NIF= 99 VÁLTÓ 2008.12.31
                       A6080901.NIF=106 VÁLTÓ 2008.09.01
                       B3081105.NIF=111 VÁLTÓ 2008.11.05
                       E6081205.NIF=146 VÁLTÓ 2008.12.05

      NapiInfofile strukturája:

     2 byte: 'DA' - napiinfo ID
     3 byte: évtized, honap, nap = dátum

     Jelszó  (text)
     Pénztárnév (text)

     4 byte: Záróforint
     4 byte: Záróvaluta

     1 byte: ennyi valutának van zárókészlete: (készdarab)
     1-tõl keszdarabig :
          dnem (text)
          keszlet (integer)
          vetel (integer)
          eladas (integer)

     délelötti vételforgalom
     délelötti eladásforgalom
     délutáni vételforgalom
     délutáni eladásforgalom

     vett Euro érme (word)
     1-es Euro érme darab (word)
     2-es Euro érme darab (word)

     Forint cimletek : 1-tõl 12-ig (12 db word)

     wu-USD készlet   (integer)
     wu-HUF készlet   (integer)
     AFA ft készlet   (integer)

     engedmény darab  (byte)  Max: 10

     1-töl engedmeny darabig:
           Valutanem (text)
           Bankjegy  (integer)
           Kedv-es árfolyam (integer)
           Bizonylatszam (10 character)

     kérek memo sorai:   (byte)  (kersor)
            1-tõl kersorig keressora (text)

     küldökk memo sorai:   (byte)  (küldsor)
            1-tõl küldsorig kuldsora (text)

     Napi kezelési díj  (integer)
     E-kereskedelem záróforint  (integer)

     délelötti pénztáros neve  (text)
     délutáni pénztáros neve  (text)

     3 byte: 255-255-255 = File-control trió
     *)

procedure TNapiJelentes.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := false;
  Pillquery.close;
  Pilldbase.close;
  Modalresult := _mResult;
end;

function TNapijelentes.GetRegiSvajciFrank: integer;

var _bj: integer;

begin
  _pcs := 'SELECT * FROM BT'+_farok + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_zDatums+chr(39)+') AND (COIN=2)';
  _pcs := _pcs + ' AND (STORNO=1)';
  Valdatadbase.Connected := true;

  result := 0;
  with valdataquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ValdataQuery.close;
      ValdataDbase.close;
      exit;
    end;


  while NOT valdataquery.eof do
    begin
      _bj := ValdataQuery.FieldByName('BANKJEGY').asInteger;
      result := result + _bj;
      Valdataquery.next;
    end;
  ValdataQuery.close;
  ValdataDbase.close;
end;




end.
