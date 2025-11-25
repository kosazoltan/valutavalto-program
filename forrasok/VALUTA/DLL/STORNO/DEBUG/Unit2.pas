unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, Grids, DBGrids, IBDatabase, IBCustomDataSet, IBQuery,
  ExtCtrls, StdCtrls, StrUtils, Buttons, IBTable;

type
  TSTORNOFORM = class(TForm)

    TempQuery       : TIBQuery;
    TempDbase       : TIBDatabase;
    TempTranz       : TIBTransaction;

    ValutaTabla     : TIBTable;
    ValutaQuery     : TIBQuery;
    ValutaDbase     : TIBDatabase;
    ValutaTranz     : TIBTransaction;

    StornoSource    : TDataSource;

    BizeloPanel     : TPanel;
    BizSzamPanel    : TPanel;
    ErtekPanel      : TPanel;
    Fuggony         : TPanel;
    LastKerdoPanel  : TPanel;
    Nyugtapanel     : TPanel;
    NyugtaTakaro    : TPanel;
    Panel1          : TPanel;
    SureBizszamPanel: TPanel;
    Surepanel       : TPanel;
    VegPanel        : TPanel;

    BizonylatRacs   : TDBGrid;

    VR              : TRadioButton;
    ER              : TRadioButton;
    UR              : TRadioButton;
    FR              : TRadioButton;

    Radiok          : TGroupBox;

    Kilepo          : TTimer;

    Bizvegedit      : TEdit;
    IndokEdit       : TEdit;

    Label1          : TLabel;
    Label2          : TLabel;
    Label3          : TLabel;
    Label4          : TLabel;
    Label5          : TLabel;
    Label6          : TLabel;
    Label7          : TLabel;
    Label8          : TLabel;
    Label9          : TLabel;
    Label10         : TLabel;
    Label11         : TLabel;
    Label12         : TLabel;

    IgenGomb        : TBitBtn;
    MegsemGomb      : TBitBtn;
    MayStornoGomb   : TBitBtn;
    Nosuccessgomb   : TBitBtn;
    NemGomb         : TBitBtn;
    StartGomb       : TBitBtn;
    StornoGomb      : TBitBtn;
    VisszaGomb      : TBitBtn;

    Shape1          : TShape;

    TempQueryBizonylatszam: TIBStringField;
    TempQueryFizetendo    : TIntegerField;
    KISUGYFELPANEL: TPanel;
    REMOTEQUERY: TIBQuery;
    REMOTEDBASE: TIBDatabase;
    REMOTETRANZ: TIBTransaction;

    procedure AlapAdatBeolvasas;
    procedure BankKartyaRendezes;
    procedure BizLista(_ST: string);
    procedure BizonylatRacsDblClick(Sender: TObject);
    procedure EllenTranzakcio;
    procedure ErClick(Sender: TObject);
    procedure Ervenytelenites;
    procedure FixFizetendo;
    procedure FormActivate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FrClick(Sender: TObject);
    procedure GongyoletVissza;
    procedure IgenGombClick(Sender: TObject);
    procedure IndokEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KilepoTimer(Sender: TObject);
    procedure KivalasztottBeolvasas;
    procedure KisUgyfelStorno;
    procedure MegsemGombClick(Sender: TObject);
    procedure NemGombClick(Sender: TObject);
    procedure RadiokClick(Sender: TObject);
    procedure StartGombClick(Sender: TObject);
    procedure StornoGombClick(Sender: TObject);
    procedure SureStorno;
    procedure UrClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
    procedure ValutaStorno;
    procedure VisszaGombClick(Sender: TObject);
    procedure VrClick(Sender: TObject);

    function FtForm(_ft: integer): string;
    function Getidos: string;
    function Nulele(_b: integer;_hh: byte): string;
    function OtpAruvisszavet: byte;
    function OtpKontrol: boolean;
    function OtpTermStorno: byte;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  STORNOFORM: TSTORNOFORM;

   _vnem,_ejel: array[1..27] of string;
  _arf,_elsz,_bjegy,_ftert: array[1..27] of integer;

  _aktdnem,_elojel,_recnums,_zcounts,_azonosito,_ugyftipus,_fdbTabla: string;
  _arfolyam,_elszarf,_bankjegy,_forintertek,_fizetoEszkoz,_ugyfelszam: integer;
  _soft,_tarspt,_oft,_fizetendo,_zcount,_recnum,_code,_kezdij,_blokk: integer;
  _recno,_spk,_absfiz,_sorszam,_mResult,_otpoke,_edosszeg,_ujosszeg: integer;
  _ftertek: integer;

  _utkeres,_tarsptar,_stornoindok,_pcs,_keres,_bizonylatszam,_kbetu: string;
  _akttipus,_stblokk,_megnyitottnap,_aktidos,_indok,_tts,_ugyfelnev: string;
  _ptkod,_bizelokod,_bizker,_origbizonylat,_tipus,_mezo,_nevtabla: string;
  _aktprosnev,_aktprosid,_stornobizonylat,_plombaszam,_gongy,_ss: string;
  _lastbizszam,_sss,_host: string;

  _sorveg: string = chr(13)+chr(10);

  _bill,_tetel,_maistornodarab,_maxnum,_napistorno,_nlen,_y,_antinumber: byte;
   _otp,_otpstoke,_wpl,_konverzio: byte;

  _top,_left,_width,_height,_ptszam: word;

  _ezstorno,_megvan,_kellgongystorno,_kellotp,_sikeres: boolean;

function regeneralorutin(_para: integer): integer; stdcall; external 'c:\valuta\bin\regen.dll' name 'regeneralorutin';
function blokknyomtatas(_para: integer):integer; stdcall; external 'c:\valuta\bin\bloknyom.dll' name 'blokknyomtatas';
function gongyvisszavonas: integer; stdcall; external 'c:\valuta\bin\gongback.dll' name 'gongyvisszavonas';
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';
function qrdisplayrutin: integer; stdcall; external 'c:\valuta\bin\qrgener.dll' name 'qrdisplayrutin';
function otpterminal: integer; stdcall; external 'c:\valuta\bin\otp.dll' name 'otpterminal';

function stornorutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
                   function stornorutin: integer; stdcall;
// =============================================================================

begin
  Stornoform := TstornoForm.Create(Nil);
  Result     := stornoform.showmodal;
  Stornoform.free;
end;


// =============================================================================
          procedure TSTORNOFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top    := round((_height-515)/2);
  _left   := round((_width-610)/2);

  Top     := _top;
  Left    := _left;
  Height  := 515;
  Width   := 610;
  _spk    := 0;

  _azonosito := '';

  SurePanel.Visible := False;
  Vegpanel.visible  := False;
  KisugyfelPanel.Visible := False;

  AlapadatBeolvasas;

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  if _napistorno>2 then
    begin
      _spk := supervisorjelszo(0);
      if _spk<>1 then
        begin
          Kilepo.Enabled := true;
          exit;
        end;
    end;

  _keres  := '';
  _zcount := 0;
  _recnum := 0;

  vRClick(Nil);

end;

// =============================================================================
         procedure TStornoForm.BizonylatRacsDblClick(Sender: TObject);
// =============================================================================

// Kiválasztotta a stornózni óhajtott tranzakciót

begin
  _bizker := trim(Tempquery.FieldbyName('BIZONYLATSZAM').AsString);
  _origbizonylat := _bizker;

  Surestorno;
end;

// =============================================================================
                        procedure TstornoForm.Surestorno;
// =============================================================================

//     Biztosan stornózza a V123456789 számú bizonylatot ?  Igen  Nem

begin
  Keypreview := False;
  KivalasztottBeolvasas;  // Beolvassa a kiválasztott bizonylat adatait fej/tet

  SureBizszamPanel.Caption := _bizker;  // stornózandó bizonylat száma
  SurebizszamPanel.repaint;
  with SurePanel do
    begin
      Top     := 110;
      Left    := 150;
      Visible := True;
      Repaint;
    end;
  ActiveControl := NemGomb;  // mégsem gombon a fókusz
end;

// =============================================================================
             procedure TStornoForm.IgenGombClick(Sender: TObject);
// =============================================================================

//   Igen ! Biztossan stornozom !

begin
  SurePanel.Visible := False;

  Bizszampanel.Caption := _origbizonylat;
  ErtekPanel.Caption   := ftForm(_fizetendo)+' Ft';

  val(_recnums,_recnum,_code);
  if (_tipus='V') OR (_tipus='E') then
    begin

      // A végpanelre felirja a NAV két számát:

      NyugtaPanel.Caption  := _zCounts + '/' + _recnums;
      NyugtaTakaro.Visible := False;
    end else
    begin

      // Eltakarja a vegpanelen a nyugta sorát:

      NyugtaTakaro.top     := 150;
      NyugtaTakaro.Left    := 40;
      NyugtaTakaro.Visible := True;
    end;

  IndokEdit.Clear;
  StartGomb.Enabled := False;

  // Kirakja a vegpanelt: és kéri a stornózást indokát:

  with VegPanel do
    begin
      Top     := 88;
      Left    := 88;
      Visible := true;
    end;

  ActiveControl := Indokedit;

end;

// =============================================================================
     procedure TSTORNOFORM.INDOKEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

// ha megvan a stornózás indoka, akkor mehet a menet a startgombról:

begin
  if ord(key)=13 then
    begin
      _stornoIndok := trim(indokedit.Text);
      if _stornoindok='' then exit;

      StartGomb.Enabled := true;
      ActiveControl := StartGomb;
    end;
end;


// =============================================================================
            procedure TStornoForm.StartGombClick(Sender: TObject);
// =============================================================================

// Innen indulhat a stornózás menete:

begin
  Tempquery.close;
  Tempdbase.close;

  VegPanel.Visible := False;

  with Fuggony do
    begin
      top     := 16;
      left    := 16;
      Visible := true;
      Repaint;
    end;

  // Itt fut végig az érvénytelenítés menete:

  ERVENYTELENITES;

  // A stornózás után regenerálja az adatbázis:

  regeneralorutin(0);
  _mResult := 1;
  Kilepo.Enabled := True;
end;


// =============================================================================
                 procedure TStornoForm.AlapadatBeolvasas;
// =============================================================================

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT* FROM PENZTAR');
      Open;

      _ptKod := trim(FieldByName('PENZTARKOD').asString);

      close;
      Sql.clear;
      Sql.add('SELECT* FROM HARDWARE');
      Open;

      _aktprosid     := FieldByNAme('IDKOD').asstring;
      _host          := trim(FieldByName('HOST').AsString);
      _aktprosnev    := trim(FieldByNAme('PENZTAROSNEV').AsString);
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').AsString);
      _napiStorno    := FieldByName('NAPISTORNO').asInteger;
      _otp           := FieldByNAme('POSTTERM').asInteger;

      Close;
    end;
  Valutadbase.close;

  while length(_ptkod)<3 do _ptkod := '0'+_ptkod;
  val(_ptkod,_ptszam,_code);
end;


// =============================================================================
           procedure TStornoForm.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  ValutaQuery.Close;
  ValutaDbase.Close;
  _mResult := 2;
  Kilepo.Enabled := true;
end;

// =============================================================================
     procedure TStornoForm.FormKeyPress(Sender: TObject; var Key: Char);
// =============================================================================

var _bill,_wk: byte;
    _ujkeres: string;

begin
  _bill := ord(key);

  IF (_BILL>95) AND (_bill<106) then _bill := _bill-48;

  if (_bill>47) AND (_bill<58) then
    begin
      _wk := length(_keres);
      if _wk=_maxnum then exit;
      _ujkeres := _keres + chr(_bill);

      _bizker := _bizelokod + _ujkeres;
      _megvan := Tempquery.Locate('BIZONYLATSZAM',_BIZKER,[loPartialKey]);
      if _megvan then
        begin
          _keres := _ujkeres;
          BizvegEdit.Text := _keres;

        end;
      exit;
    end;

  if _bill=8 then
    begin
      _wk := length(_keres);

      if _wk=0 then exit;
      if _wk=1 then
        begin
          _keres := '';
          Bizvegedit.Text := '';
          exit;
        end;
      dec(_wk);
      _keres := leftstr(_keres,_wk);
      BizVegedit.Text := _keres;
      exit;
    end;

  if _bill=13 then
    begin
      if length(_keres)<_maxnum then
        begin
          _bizker := trim(Tempquery.FieldbyName('BIZONYLATSZAM').AsString);
           _origbizonylat := _bizker;
          Surestorno;
          exit;
        end;
    end;
end;


// =============================================================================
            procedure TStornoForm.NemGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 2;
  Kilepo.Enabled := true;
end;

// =============================================================================
            procedure TStornoForm.StornoGombClick(Sender: TObject);
// =============================================================================

begin
  _bizker := trim(Tempquery.FieldbyName('BIZONYLATSZAM').AsString);
  _origbizonylat := _bizker;
  SureStorno;
end;

// =============================================================================
           procedure TStornoForm.RadiokClick(Sender: TObject);
// =============================================================================

begin
  Keypreview := true;
end;

// =============================================================================
            function Tstornoform.FtForm(_ft: integer): string;
// =============================================================================

var _wr,_f1: byte;

begin
  result := inttostr(_ft);
  if _ft<1000 then exit;

  _wr := length(result);
  if _wr>6 then
    begin
      _f1 := _wr-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;
  _f1 := _wr-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;

// =============================================================================
           procedure TStornoForm.MegsemGombClick(Sender: TObject);
// =============================================================================

begin
  TempQuery.close;
  Tempdbase.close;
  _Mresult := 2;
  Kilepo.Enabled := True;
end;

// =============================================================================
                   procedure TstornoForm.KivalasztottBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM BLOKKFEJ' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_origbizonylat+chr(39);

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _tipus     := FieldByNAme('TIPUS').asString;
      _konverzio := FieldByNAme('KONVERZIO').asInteger;
      _oft       := FieldByNAme('OSSZESFORINTERTEK').asInteger;
      _kezdij    := FieldByName('KEZELESIDIJ').asInteger;
      _tarsptar  := FieldByNAme('TARSPENZTARKOD').asString;
      _fizetendo := FieldByNAme('FIZETENDO').asInteger;
      _fizetoeszkoz := FieldByName('FIZETOESZKOZ').asInteger;
      _recnums   := FieldByNAme('RECNUMS').asString;
      _zcounts   := FieldByName('ZCOUNTS').asString;
      _ugyftipus := FieldByName('UGYFELTIPUS').asstring;
      _ugyfelszam:= FieldByName('UGYFELSZAM').asInteger;
      _plombaszam:= Trim(FieldByNAme('PLOMBASZAM').AsString);
      Close;
    end;
  Valutadbase.close;

  if (_konverzio=1) and (_tipus='E') then fixfizetendo;

  _wpl := length(_plombaszam);
  if _wpl>4 then
    begin
      _nevtabla := leftstr(_plombaszam,4);
      _sss := midstr(_plombaszam,5,_wpl-4);
      val(_sss,_sorszam,_code);
    end;

  _azonosito := '';
  if (_ugyfelszam>0) and ((_tipus='V') or (_tipus='E')) then
    begin
      if _ugyftipus='N' then _pcs := 'SELECT * FROM UGYFEL '
      else _pcs := 'SELECT * FROM JOGISZEMELY ';
      _pcs := _pcs + 'WHERE UGYFELSZAM='+inttostr(_ugyfelszam);

      Valutadbase.Connected := true;
      with ValutaQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;
      if _recno>0 then
         begin
           if _ugyftipus='N' then
             begin
               _azonosito := trim(Valutaquery.fieldbyname('AZONOSITO').asString);
               _ugyfelnev := trim(ValutaQuery.FieldByNAme('NEV').asString);
             end else
             begin
               _azonosito := trim(ValutaQuery.FieldbyName('OKIRATSZAM').AsString);
               _ugyfelnev := trim(ValutaQuery.FieldByNAme('JOGISZEMELYNEV').AsString);
             end;
         end;
      ValutaQuery.close;
      Valutadbase.close;
    end;


 // _ftipus := leftstr(_origBizonylat,2);

  _pcs := 'SELECT * FROM BLOKKTETEL' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_origbizonylat+chr(39);
   Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _tetel := 0;
  while not ValutaQuery.Eof do
    begin
      _aktdnem     := ValutaQuery.FieldbyNAme('VALUTANEM').asString;
      _arfolyam    := ValutaQuery.FieldByNAme('ARFOLYAM').asInteger;
      _elszarf     := ValutaQuery.fieldbyname('ELSZAMOLASIARFOLYAM').asInteger;
      _bankjegy    := ValutaQuery.FieldByNAme('BANKJEGY').asInteger;
      _forintertek := ValutaQuery.FieldByNAme('FORINTERTEK').asInteger;
      _elojel      := ValutaQuery.FieldByNAme('ELOJEL').asString;
      inc(_tetel);

      _vnem[_tetel]  := _aktdnem;
      _arf[_tetel]   := _arfolyam;
      _elsz[_tetel]  := _elszarf;
      _bjegy[_tetel] := _bankjegy;
      _ftert[_tetel] := _forintertek;
      _ejel[_tetel]  := _elojel;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  ValutaDbase.close;
end;

// =============================================================================
             procedure TStornoForm.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.connected := true;
  if valutatranz.InTransaction then valutatranz.Commit;
  Valutatranz.StartTransaction;
  with valutaquery do
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
               procedure TStornoForm.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  ModalResult    := _mResult;
end;


// =============================================================================
                function TStornoForm.OtpKontrol: boolean;
// =============================================================================

begin
  Result := False;

  _pcs := 'SELECT * FROM BLOKKFEJ' + _sorveg;
  _pcs := _pcs + 'WHERE (FIZETOESZKOZ=2) AND (STORNO=1)' + _sorveg;
  _pcs := _pcs + 'ORDER BY IDO';

  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno>0 then
    begin
      _lastbizszam := ValutaQuery.FieldByName('BIZONYLATSZAM').asString;
    end;

  ValutaQuery.Close;
  ValutaDbase.Close;

  if _lastBizSzam = _origBizonylat then Result := True;
end;


// =============================================================================
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                   procedure TStornoForm.Ervenytelenites;
// =============================================================================

begin

  // Ha átadás-átvétel bizonylatot stornózzuk:

  if (_tipus='F') or (_tipus='U') then
    begin
       EllenTranzakcio;  // NaV-os tranzakció futtatását
       ValutaStorno;     // Normál valuta-stornó
       Exit;
     end;

  //  Innen csak vétel vagy eladás bizonylat stornózása:

  // Ha OTP átutalással fizetett az ügyfél:

  if _fizetoEszkoz=2 then
    begin
      // Az otpkontrol vizsgálja, hogy utolsó bizonylat volt-e a választott
      // Ha igen sima otp-storno, ha nem otp-aruvisszavét

      if OtpKontrol then _otpOke := OTPTermStorno
      else _otpOke := OtpAruvisszavet;

      // Ha sikertelen OTP-müvelet volt - akkor nincs tovább;
      if _otpoke<>1 then
        begin
          ShowMessage('SIKERTELEN OTP-STORNÓ ! Stornó nem kehetséges');
          exit;
        end;
    end;

  if _ugyftipus='K' then KisUgyfelstorno;

  // Amennyiben van plombaszám (tehát nagyügyfél) Serveren vissza kell göngyölioteni
  if (_ugyftipus<>'K') and (_nevtabla<>'') then GongyoletVissza;

  // Végül normál Valuta-stornó müveletet hajt végre:
  Valutastorno;
end;

// =============================================================================
                 procedure Tstornoform.EllentranzAkcio;
// =============================================================================

var _aktbjegy: integer;

begin
  _pcs := 'DELETE FROM QRPARAMS';
  ValutaParancs(_pcs);

  _y :=1;
  while _y<=_tetel do
    begin
      _aktdnem  := _vnem[_y];
      _aktbjegy := _bjegy[_y];

      _pcs := 'INSERT INTO QRPARAMS (VALUTANEM,BANKJEGY)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39)+_aktdnem+chr(39)+',';
      _pcs := _pcs + inttostr(_aktbjegy)+')';
      ValutaParancs(_pcs);

      inc(_y);
    end;

  if _tipus='F' then _antinumber :=5 else _antinumber:=6;

  _pcs := 'UPDATE QRPARAMS SET NUMBER='+inttostr(_antinumber);
  ValutaParancs(_pcs);

  qrdisplayrutin;
end;


// =============================================================================
                  function TStornoForm.OtpTermStorno: byte;
// =============================================================================

begin

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (BIZONYLATSZAM,FIZETENDO,OTPFUNCTYPE)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_origbizonylat+chr(39)+',';
  _pcs := _pcs + inttostr(_fizetendo) + ',';
  _pcs := _pcs + '100)';
  ValutaParancs(_pcs);

  result := otpterminal;

end;

// =============================================================================
                   function TStornoForm.OtpAruVisszavet: byte;
// =============================================================================

begin
  result := 2;

  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (BIZONYLATSZAM,FIZETENDO,OTPFUNCTYPE)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_origbizonylat+chr(39)+',';
  _pcs := _pcs + inttostr(_fizetendo) + ',';
  _pcs := _pcs + '4)';
  ValutaParancs(_pcs);

  Result := otpterminal;

end;

// =============================================================================
                procedure Tstornoform.GongyoletVissza;
// =============================================================================

begin
  _gongy := midstr(_plombaszam,2,3);
  if (_gongy<>'NEV') AND (_gongy<>'OGI') then exit;

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);

  _absfiz := abs(_fizetendo);

  _pcs := 'INSERT INTO VTEMP (BIZONYLATSZAM,FIZETENDO,SORSZAM,NEVTABLA)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _origbizonylat + chr(39) + ',';
  _pcs := _pcs + inttostr(_absfiz) + ',';
  _pcs := _pcs + inttostr(_sorszam) + ',';
  _pcs := _pcs + chr(39) + _nevtabla + chr(39) + ')';
  ValutaParancs(_pcs);

  gongyvisszavonas;
end;

// =============================================================================
                 procedure TStornoform.ValutaStorno;
// =============================================================================

begin
  if (_tipus='V') or (_tipus='E') THEN
    begin
      if _recnum>0 then
        begin
          _pcs := 'DELETE FROM QRPARAMS';
          ValutaParancs(_pcs);

          _pcs := 'INSERT INTO QRPARAMS (NUMBER,RECNUM)'+_sorveg;
          _pcs := _pcs + 'VALUES (9,'+_recnums+')';

          ValutaParancs(_pcs);
          qrdisplayrutin;
        end;
     end;

  _aktIdos := Getidos;

  // -----------------------------------------------------

  if (_tipus='F') or (_tipus='U') then
    begin
      if midstr(_origbizonylat,2,1)='F' then _tipus:=leftstr(_origbizonylat,2)
    end;

  if _tipus='V' then _mezo  := 'UTOLSOVETELBLOKK';
  if _tipus='E' then _mezo  := 'UTOLSOELADASBLOKK';
  if _tipus='U' then _mezo  := 'UTOLSOATVETELBLOKK';
  if _tipus='F' then _mezo  := 'UTOLSOATADASBLOKK';
  if _tipus='UF' then _mezo := 'UTOLSOFORINTATVETELBLOKK';
  if _tipus='FF' then _mezo := 'UTOLSOFORINTATADASBLOKK';

  // --------------------------------------------------------

  // Elöször a stornózandó blokkfejet és tételeket kell storno=2-re állitani

  _pcs := 'UPDATE BLOKKFEJ SET STORNO=2' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_origbizonylat+chr(39);
  ValutaParancs(_pcs);

  _pcs := 'UPDATE BLOKKTETEL SET STORNO=2' + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_origbizonylat+chr(39);
  ValutaParancs(_pcs);

  // -----------------------------------------------------------

  // Léptetni kell az utolsóblokkszamot: _blokk

  ValutaDbase.Connected := True;
  if ValutaTranz.InTransaction then ValutaTranz.commit;
  Valutatranz.StartTransaction;

  with ValutaTabla do
    begin
      Close;
      TableName := 'UTOLSOBLOKKOK';
      Open;
      _blokk := FieldByNAme(_mezo).asInteger;
    end;

  // Léptetjük az utolsó blokkot:

  inc(_blokk);

  // A léptetett utolsó sorszámot rögziti:

  with ValutaTabla do
    begin
      Edit;
      FieldByNAme(_mezo).asInteger := _blokk;
      Post;
    end;
  ValutaTranz.commit;
  Valutadbase.close;

  // ----------------------------------------------------------

  //  Létre hozza a Storno-bizonylatot:

  _nlen := 6;
  if length(_tipus)=2 then _nLen := 5;

  _stornoBizonylat := _tipus + _bizelokod + nulele(_blokk,_nLen);
  _oft             := trunc(_oft*(-1));
  _fizetendo       := trunc(_fizetendo*(-1));
  _kezdij          := trunc(_kezdij*(-1));
  _tipus           := leftstr(_tipus,1);

  _pcs := 'INSERT INTO BLOKKFEJ (BIZONYLATSZAM,TIPUS,DATUM,IDO,OSSZESFORINTERTEK,';
  _pcs := _pcs + 'TETEL,PENZTAROSNEV,IDKOD,STORNO,FIZETENDO,KEZELESIDIJ)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+_stornoBizonylat+chr(39)+',';
  _pcs := _pcs + chr(39)+_tipus+chr(39)+',';
  _pcs := _pcs + chr(39) + _megnyitottnap + chr(39)+',';
  _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
  _pcs := _pcs + inttostr(_oft) + ',';
  _pcs := _pcs + inttostr(_tetel) + ',';
  _pcs := _pcs + chr(39) + _aktprosnev + chr(39) + ',';
  _pcs := _pcs + chr(39)+_aktprosid+chr(39) + ',3,';
  _pcs := _pcs + inttostr(_fizetendo) + ',';
  _pcs := _pcs + inttostr(_kezdij)+')';
  ValutaParancs(_pcs);

  // A Vtemp-et kiüriti

  _pcs := 'DELETE FROM VTEMP';
  ValutaParancs(_pcs);


  // A storno bizonylat tételeit és felirja:

  _y := 1;
  while _y<=_tetel do
    begin
      _aktdnem     := _vnem[_y];
      _arfolyam    := _arf[_y];
      _elszarf     := _elsz[_y];
      _bankjegy    := _bjegy[_y];
      _forintertek := _ftert[_y];
      _elojel      := _ejel[_y];

      _bankjegy    := trunc(_bankjegy*(-1));
      _forintertek := trunc(_forintertek*(-1));

      _pcs := 'INSERT INTO BLOKKTETEL (BIZONYLATSZAM,VALUTANEM,ARFOLYAM,';
      _pcs := _pcs + 'ELSZAMOLASIARFOLYAM,BANKJEGY,FORINTERTEK,';
      _Pcs := _pcs + 'STORNO,DATUM)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + CHR(39) + _STORNOBIZONYLAT +chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_arfolyam) + ',';
      _pcs := _pcs + inttostr(_elszarf) + ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + inttostr(_forintertek) + ',';

      _pcs := _pcs + '3,';
      _pcs := _pcs + chr(39) + _megnyitottnap + chr(39) + ')';
      ValutaParancs(_pcs);

      // A vtemp-be is beirja a tételeket:

      _pcs := 'INSERT INTO VTEMP (VALUTANEM,ARFOLYAM,BANKJEGY,FORINTERTEK)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_arfolyam)+ ',';
      _pcs := _pcs + inttostr(_bankjegy) + ',';
      _pcs := _pcs + inttostr(_forintertek) + ')';
      ValutaParancs(_pcs);

      inc(_y);
    end;

  _pcs := 'UPDATE VTEMP SET BIZONYLATSZAM='+chr(39)+_stornoBizonylat+chr(39)+',';
  _pcs := _pcs + 'STORNOBIZONYLAT='+chr(39)+_origBizonylat+chr(39)+',';
  _pcs := _pcs + 'STORNO=3,TIPUS='+CHR(39)+_tipus+chr(39)+',';
  _pcs := _pcs + 'FIZETENDO='+inttostr(_fizetendo);
  _pcs := _pcs + ',PENZTAROSNEV=' + chr(39)+_aktprosnev+chr(39);
  _pcs := _pcs + ',DATUM=' + chr(39) + _megnyitottnap + chr(39);
  _pcs := _pcs + ',IDO=' + chr(39) + _aktidos + chr(39);
  _pcs := _pcs + ',STORNOINDOK=' + chr(39)+ _stornoindok + chr(39);
  ValutaParancs(_pcs);

  inc(_napistorno);
  _pcs := 'UPDATE HARDWARE SET NAPISTORNO='+inttostr(_napistorno);
  ValutaParancs(_pcs);

  blokknyomtatas(1);
  _tts := midstr(_origbizonylat,2,1);
  if (_tts='F') or (_ptszam>150) then
    begin
      blokknyomtatas(11);
    end;

  if (_fizetoeszkoz=2) AND (_tipus='E') then BankKartyaRendezes;

end;


// =============================================================================
                  function TStornoForm.GetIdos: string;
// =============================================================================

begin
  result := timetostr(Time);
  if midstr(result,2,1)=':' then result := '0'+ result;
  result := leftstr(result,5);
end;


// =============================================================================
             procedure TSTORNOFORM.VRClick(Sender: TObject);
// =============================================================================

begin
  BizLista('V');
end;

// =============================================================================
              procedure TSTORNOFORM.ERClick(Sender: TObject);
// =============================================================================

begin
  BizLista('E');
end;

// =============================================================================
              procedure TSTORNOFORM.URClick(Sender: TObject);
// =============================================================================

begin
  BizLista('U');
end;

// =============================================================================
              procedure TSTORNOFORM.FRClick(Sender: TObject);
// =============================================================================

begin
  BizLista('F');
end;


// =============================================================================
                procedure TstornoForm.BizLista(_ST: string);
// =============================================================================

begin

  Radiok.Enabled := False;
  _bizelokod := _ptKod;

  if length(_st)=2 then
    begin
      _maxnum := 5;
      BizeloPanel.Caption := _bizelokod;
    end else
    begin
      _maxnum := 6;
      BizeloPanel.caption := '   '+_bizelokod;
    end;

  Bizvegedit.MaxLength := _maxnum;
  Bizvegedit.Clear;
  Bizelopanel.repaint;

  _keres := '';
  KeyPreview := True;

  _pcs := 'SELECT * FROM BLOKKFEJ' + _sorveg;
  _pcs := _pcs + 'WHERE (BIZONYLATSZAM LIKE ' +chr(39)+_st+'%'+chr(39);
  _pcs := _pcs + ') AND (STORNO=1)';

  TempDbase.connected := true;
  with TempQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;
  Bizonylatracs.SetFocus;
end;

// =============================================================================
           function TstornoForm.Nulele(_b: integer;_hh: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  while length(result)<_hh do result := '0' + result;
end;

// =============================================================================
                  procedure TStornoForm.BankKartyaRendezes;
// =============================================================================

var _randnum: integer;
    _randbizszam: string;

begin
  randomize;
  _randnum := random(9999);
  _randBizszam := 'FRND'+inttostr(_randnum);

  _pcs := 'DELETE FROM QRPARAMS';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO QRPARAMS (NUMBER,VALUTANEM,BANKJEGY,BIZONYLATSZAM)'+_sorveg;
  _pcs := _pcs + 'VALUES (5,'+chr(39)+'HUF'+CHR(39)+',' + inttostr(_fizetendo)+',';
  _pcs := _pcs + chr(39) + _randbizszam + chr(39) + ')';
  ValutaParancs(_pcs);

  // ------------------QRDISPLAY-(SELLING) -------------------------------------

  qrdisplayrutin;
end;

// =============================================================================
                     procedure TStornoform.Kisugyfelstorno;
// =============================================================================

begin
  with Kisugyfelpanel do
    begin
      top := 280;
      left:= 200;
      Visible := True;
      repaint;
    end;

  if (_nevtabla='') OR (_SORSZAM=0)  then exit;

  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);

  remoteDbase.close;
  remotedbase.DatabaseName := _host+':c:\receptor\database\kisugyfel.fdb';
  Remotedbase.connected := True;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _edosszeg := FieldByNAme('OSSZEG').asInteger;
      Close;
    end;
  Remotedbase.close;

  _ujosszeg := _edosszeg-_fizetendo;
  if _ujosszeg<0 then _ujOsszeg := 0;

  _pcs := 'UPDATE ' + _nevtabla + ' SET OSSZEG=' + inttostr(_ujOsszeg)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);

  Remotedbase.connected := true;
  if remoteTranz.InTransaction then remoteTranz.Commit;
  remotetranz.StartTransaction;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  RemoteTranz.commit;
  remotedbase.close;

  kISUGYFELpANEL.Visible := False;
end;

// =============================================================================
                        procedure TStornoForm.FixFizetendo;
// =============================================================================

begin
  _pcs := 'SELECT * FROM BLOKKTETEL' + _sorveg;
  _pcs := _pcs + 'WHERE (BIZONYLATSZAM=' + chr(39)+_origbizonylat+chr(39)+')';
  _pcs := _pcs + ' AND (VALUTANEM<>' + CHR(39)+'HUF'+chr(39)+')';
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      _fizetendo := FieldByNAme('FORINTERTEK').asInteger;
      Close;
    end;
  Valutadbase.close;
  
end;      

end.








