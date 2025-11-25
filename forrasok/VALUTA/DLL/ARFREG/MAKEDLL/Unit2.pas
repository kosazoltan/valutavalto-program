unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, IBTable,
  StrUtils, Buttons, Grids, ExtCtrls, dateUtils;

type
  TARFOLYAMTAROLO = class(TForm)
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    ARFOLYAMQUERY: TIBQuery;
    ARFOLYAMDBASE: TIBDatabase;
    ARFOLYAMTRANZ: TIBTransaction;
    ARFOLYAMTABLA: TIBTable;
    WRITEPANEL: TPanel;
    READPANEL: TPanel;
    RACS: TStringGrid;
    KOVETKEZOGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    TORTENETPANEL: TPanel;
    Label1: TLabel;
    EHAVIGOMB: TBitBtn;
    REGEBBIGOMB: TBitBtn;
    HOCOMBO: TComboBox;
    EVCOMBO: TComboBox;
    Bevel1: TBevel;
    megsegomb: TBitBtn;
    LIMITGOMB: TBitBtn;
    KEDVEZMENYPANEL: TPanel;
    Label2: TLabel;
    Panel3: TPanel;
    Panel4: TPanel;
    TOL1PANEL: TPanel;
    TOL2PANEL: TPanel;
    IG1PANEL: TPanel;
    IG2PANEL: TPanel;
    KEDVVISSZAGOMB: TBitBtn;
    Panel2: TPanel;
    Panel5: TPanel;
    Panel8: TPanel;
    KISPANEL: TPanel;
    USZOTIMER: TTimer;
    MASIKHONAPGOMB: TBitBtn;
    kilepo: TTimer;
    Shape1: TShape;
    ARFOLYAMCIMPANEL: TPanel;
    ELOZOGOMB: TBitBtn;
    DATUMRENDBENGOMB: TBitBtn;


    procedure FormActivate(Sender: TObject);
    procedure ArfolyamRogzites;
    procedure ArfolyamKijelzes;
    procedure MakeArfolyamTabla;
    procedure EgyracsDisplay;
    procedure EgyIdoBeolvasas;
    procedure RacsTakarito;

    function dnemDekoder: string;
    function Intdekodol(_bp: integer): real;
    function RealToStr(_rr: real): string;
    function Limitform(_int: integer):string;
    function GetcurrateFile: string;


//    procedure RACSDrawCell(Sender: TObject; ACol, ARow: Integer;
//      Rect: TRect; State: TGridDrawState);
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure REGEBBIGOMBClick(Sender: TObject);
    procedure datumrendbengombClick(Sender: TObject);
    procedure EHAVIGOMBClick(Sender: TObject);

    function Nulele(_int: integer): string;
    function RealFormat(_real: real): string;
    procedure LIMITGOMBClick(Sender: TObject);
    procedure USZOTIMERTimer(Sender: TObject);
    procedure KEDVVISSZAGOMBClick(Sender: TObject);
    procedure KOVETKEZOGOMBClick(Sender: TObject);
    procedure kilepoTimer(Sender: TObject);
    procedure MASIKHONAPGOMBClick(Sender: TObject);
 
    function KovetkezoIdo: boolean;
    function ElozoIdo: boolean;
    procedure ELOZOGOMBClick(Sender: TObject);
    function HunDatetostr(_caldat: TDateTime): string;
    procedure EVCOMBOChange(Sender: TObject);
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ARFOLYAMTAROLO: TARFOLYAMTAROLO;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                 'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER',
                 'OKTÓBER','NOVEMBER','DECEMBER');

   _dnem:array[1..28] of string = ('EUR','USD','GBP','CHF','AUD','CAD','DKK',
           'JPY','NOK','SEK','CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH',
           'RUB','EUA','TRY','CNY','BAM','THB','BRL','MXN','NZD','RCH');

  _sorveg : string = #13#10;
  _bytetomb: array[1..4096] of byte;
  _yDnem: array[1..28] of string;

  _yVet,
  _yelad,
  _y1vet,
  _y1elad,
  _y2vet,
  _y2elad,
  _yelszam: array[1..28] of real;

  _beladArf,
  _bVetarf,
  _eladArf,
  _elszamArf,
  _ueladArf,
  _uVetArf,
  _vetArf: array[1..28] of real;


  _aktdatum,
  _aktdnem,
  _aktevs,
  _aktidos,
  _aktnaps,
  _arfdatum,
  _arfidos,
  _arfolyampath,
  _curratefile,
  _farok,
  _foc,
  _homepenztarkod,
  _mamas,
  _OIDOs,
  _odatum,
  _oras,
  _pcs,
  _percs,
  _qfilenev,
  _qPath,
  _sss,
  _xDatum,
  _xIdos,
  _tablanev: string;

  _aktev,
  _akthonap,
  _aktnap,
  _aktperc,
  _aktora,
  _aktmasodperc,
  _aktvalutaDarab,
  _csopIndex,
  _fulszam,
  _height,
  _homepenztarszam,
  _kezdet,
  _kpt,
  _kpL,
  _kpH,
  _kpW,
  _L1,
  _L2,
  _L3,
  _left,
  _mResult,
  _qq,
  _recno,
  _tombSize,
  _top,
  _valutadarab,
  _width: integer;

  _srec: TsearchRec;
  _ido: Tdatetime;
  _ures: boolean;


  _olvas: File of byte;

  _wrflag:integer=1;



function arfolyamregiszter(_para: integer): integer;stdcall;

implementation

{$R *.dfm}

// =============================================================================
        function arfolyamregiszter(_para: integer): integer;stdcall;
// =============================================================================

begin
  ArfolyamTarolo := Tarfolyamtarolo.Create(Nil);
  _wrflag := _para;
  result := ArfolyamTarolo.ShowModal;
  ArfolyamTarolo.Free;
end;



{  Parameter: 1 = olvasás,  2 = irás

   Source = 'c:\valuta\arfolyam\q_*.*'
   Source structura :
        Source_name: 'Q_yymmdd.ss  (ss= napi sorszám)

        1. byte = valutenemek darabszáma   (default= 20) innen = VDB
        2. - (2*VDB) = a valutanemek 2 byte-on kódolva  (default = 40 byte)
        n. - n + 150 = az egyes váltók fülszáma (150 byte) (fülszám = 3 .. 40)

        3.. 40 árfolyamtömb (38 db) - (árfolyamtömb = 35*VDB byte)
                                       árfolyamtömb struktura:
                                         5 byte = elszamolási arfolyam
                                         5 byte = vételi árfolyam
                                         5 byte = eladási árfolyam
                                         5 byte = kedv1-es vételi árfolyam
                                         5 byte = kedv1-es eladási árfolyam
                                         5 byte = kedv2-es vételi árfolyam
                                         5 byte = kedv2-es eladási árfolyam

        3..40 (38*6 byte) Limitword(lo-hi)(limit1-limit2-limit3)*1000 Ft(6 byte)
        (File default méret: 1 + 40 + 150 + 26600 + 228 = 27019 byte)

     Interbase adatok:
         Adatbázis: 'c:\valuta\database\arfolyam-Fdb'
         Havi táblák: 'SARFyymm'
         Havi tábla struktura: DATUM,IDO,SORSZAM
                               VALUTANEM
                               LIMIT1,LIMIT2,LIMIT3
                               ALAPVETEL,ALAPELADAS
                               LIM1VETEL,LIM1ELADAS
                               LIM2VETEL,LIM2ELADAS
                               ELSZAMOLASIARFOLYAM.

      DEKODEREK: DNEMDKODER(dns: string)
                 b1 = ord(dns[1]), b2 = ord(dns[2]
                 r1 = B1/4, r2 = b1*64
                 r2 = (r2/8) + (b2/32)
                 r3 = b2*8
                 r3 = r3/8
                 result = #r1+64#r2+64#r3+64

                 INTEGERDEKODER(dns: string)
                 b1=ord(dns[1]),b2=ord(dns[2]),b3=ord(dns[3]),b4=ord(dns[4]),b5=ord(dns[5])
                 res = b5*65536*65536
                 res = res + b4*256*65536
                 res = res + b3*65536
                 res = res + b2*256
                 res = res + b1
}


// =============================================================================
            procedure TARFOLYAMTAROLO.FormActivate(Sender: TObject);
// =============================================================================

begin
 //// _wrflag := 1;     /// teszt

  Readpanel.Visible := false;
  WritePanel.Visible := False;
  Tortenetpanel.visible := false;

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  height := 768;
  Width  := 1024;
  _mamas := Hundatetostr(date);

  // ---------------------------------------------------

  if _wrflag=2 then ArfolyamRogzites
  else ArfolyamKijelzes;
end;


// =============================================================================
                    procedure TArfolyamTarolo.ArfolyamRogzites;
// =============================================================================

begin
  // ------------- PÉNZTÁRSZÁM BEOLVASÁSA --------------------------------------

  Tortenetpanel.visible := False;
  ReadPanel.Visible := False;
  with WritePanel do
    begin
      Top     := 5;
      Left    := 5;
      Height  := 610;
      Width   := 850;
      Visible := True;
    end;

  Writepanel.Repaint;
  sleep(200);
  _pcs := 'SELECT * FROM PENZTAR';

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;

      _homePenztarkod := trim(fieldbyname('PENZTARKOD').asstring);
      Close;
    end;

  Valutadbase.close;
  _homePenztarszam := strtoint(_homepenztarkod);

  // ---------------- ÁRFOLYAM ASC FELDOLGOZÁSA --------------------------------

  _curratefile := GetCurrateFile;
  if _currateFile='' then
    begin
      _mResult := 2;
      Kilepo.Enabled := true;
      exit;
    end;

  _arfolyamPath := 'c:\valuta\arfolyam\'+_curratefile;
  if not fileExists(_arfolyamPath) then
    begin
      _Mresult := 2;
      Kilepo.Enabled := true;
      Exit;
    end;

  _arfidos := midstr(_curratefile,5,2)+':'+midstr(_curratefile,7,2)+':00';


  assignfile(_olvas,_arfolyamPath);
  reset(_olvas);
  Blockread(_olvas,_bytetomb,1);   // VERZIO = 15
  Blockread(_olvas,_bytetomb,200);  // CSOPORT-KÓDOK
  closeFile(_olvas);

  // ------------------- ÁRFOLYAM TÁBLA INICIALIZÁLÁSA -------------------------

  _aktev := yearof(date);
  _akthonap := monthof(date);

  _farok :=  nulele(_aktev-2000)+nulele(_akthonap);
  _tablanev := 'SARF' + _farok;

  Arfolyamdbase.close;
  Arfolyamtabla.Close;
  ArfolyamTabla.TableName := _tablanev;
  ArfolyamDbase.Connected := true;
  _ures := False;
  if not ArfolyamTabla.Exists then
    begin
      Arfolyamdbase.close;
      MakeArfolyamTabla;
      _ures := true;
    end;

  // ------------- HA NEM ÜRES, AKKOR TÖRÖLNI KELL AZ AZONOS REKORDOKAT --------

  if not _ures then
    begin
      _pcs := 'DELETE FROM '+_tablanev + _sorveg;
      _pcs := _pcs + 'WHERE (DATUM='+chr(39)+_mamas+chr(39)+') AND (IDO='+chr(39)+_arfidos+chr(39)+')';

      ArfolyamDbase.Connected := true;
      IF arfolyamTranz.InTransaction then ArfolyamTranz.Commit;
      ArfolyamTranz.StartTransaction;
      with ArfolyamQuery do
        begin
          Close;
          Sql.Clear;
          sql.Add(_pcs);
          ExecSql;
        end;
      ArfolyamTranz.Commit;
      ArfolyamDbase.close;
    end;

  // ----------------------------------------------------------------

  Assignfile(_olvas,_arfolyampath);
  Reset(_olvas);
  Blockread(_olvas,_bytetomb,1);  // VERZIO =15
  blockread(_olvas,_bytetomb,200);   // Munkacsoportok
  _valutadarab := 28;

  // -----------------------------------------------------------------

  _csopindex := _bytetomb[_homepenztarszam];

  if _csopindex>0 then
    begin
      _kezdet := 201+trunc((_csopindex-1)*1266);
      reset(_olvas);
      seek(_olvas,_kezdet);
    end;

   _qq := 1;
   while _qq<=28 do
     begin
       Blockread(_olvas,_bytetomb,45);

       _elszamarf[_qq] := intdekodol(1);
       _vetarf[_qq] := intdekodol(6);
       _eladarf[_qq] := intdekodol(11);
       _uvetarf[_qq] := intdekodol(16);
       _ueladarf[_qq] := intdekodol(21);
       _bvetarf[_qq] := intdekodol(26);
       _beladarf[_qq] := intdekodol(31);
   //    _shkvetar[_qq] := intdekodol[36];
   //    _shkeladar[_qq] := intdekodol[41];
       inc(_qq);
     end;

   Blockread(_Olvas,_bytetomb,6);
   closeFile(_olvas);

   _L1 := _bytetomb[1] + trunc(256*_bytetomb[2]);
   _L2 := _bytetomb[3] + trunc(256*_bytetomb[4]);
   _L3 := _bytetomb[5] + trunc(256*_bytetomb[6]);

   _L1 := trunc(1000*_L1);
   _L2 := trunc(1000*_L2);
   _L3 := trunc(1000*_L3);

   // -------------------------------------------------------------

   Arfolyamdbase.Connected := true;
   if arfolyamtranz.InTransaction then arfolyamtranz.Commit;
   ArfolyamTranz.StartTransaction;

   _qq := 1;
   while _qq<=_valutaDarab do
     begin
       _pcs := 'INSERT INTO ' + _tablanev+ ' (DATUM,IDO,VALUTANEM,';
       _pcs := _pcs + 'LIMIT1,LIMIT2,LIMIT3,ALAPVETEL,ALAPELADAS,LIM1VETEL,';
       _pcs := _pcs + 'LIM1ELADAS,LIM2VETEL,LIM2ELADAS,ELSZAMOLASIARFOLYAM)'+_sorveg;

       _pcs := _pcs + 'VALUES ('+ chr(39) + _mamas +chr(39) + ',';
       _pcs := _pcs + chr(39) + _arfidos + chr(39) + ',';
       _pcs := _pcs + chr(39) + _dnem[_qq] + chr(39) + ',';
       _pcs := _pcs + inttostr(_L1) + ',';
       _pcs := _pcs + inttostr(_L2) + ',';
       _pcs := _pcs + inttostr(_L3) + ',';
       _pcs := _pcs + realtostr(_vetarf[_qq]) + ',';
       _pcs := _pcs + realtostr(_eladarf[_qq]) + ',';
       _pcs := _pcs + realtostr(_uvetarf[_qq]) + ',';
       _pcs := _pcs + realtostr(_ueladarf[_qq]) + ',';
       _pcs := _pcs + realtostr(_bVetarf[_qq]) + ',';
       _pcs := _pcs + realtostr(_bEladarf[_qq]) + ',';
       _pcs := _pcs + realtostr(_elszamarf[_qq])+')';

       with ArfolyamQuery do
         begin
           Close;
           Sql.Clear;
           sql.Add(_pcs);
           ExecSql;
         end;

       inc(_qq);
     end;
   ArfolyamTranz.Commit;
   ArfolyamDbase.Close;
   WritePanel.visible := False;
   _MResult := 1;
   Kilepo.Enabled := true;
end;


function TArfolyamTarolo.GetcurrateFile: string;

var _minta: string;
    _srec: TSearchrec;

begin
  result := '';
  _minta := 'c:\valuta\arfolyam\NR*.dat';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then result := _srec.name;
  FindClose(_srec);
end;


// =============================================================================
                function TarfolyamTarolo.dnemDekoder: string;
// =============================================================================


var _b1,_b2,_r1,_r2,_r3: byte;

begin
  _b1 := _bytetomb[1];
  _b2 := _bytetomb[2];
  _r1 := trunc(_b1/4);
  _r2 := trunc(_b1*64);
  _r2 := trunc(_r2/8)+trunc(_b2/32);
  _r3 := trunc(_b2*8);
  _r3 := trunc(_r3/8);
  result := chr(_r1+64)+chr(_r2+64)+chr(_r3+64);
end;

// =============================================================================
             function TArfolyamTarolo.Intdekodol(_bp: integer): real;
// =============================================================================

var _b1,_b2,_b3,_b4,_b5: byte;

begin
   _b1 := _bytetomb[_bp];
   _b2 := _bytetomb[_bp+1];
   _b3 := _bytetomb[_bp+2];
   _b4 := _bytetomb[_bp+3];
   _b5 := _bytetomb[_bp+4];

   result := _b5*65536*65536;
   result := result + (_b4*65536*256);
   result := result + (65536*_b3);
   result := result + (256*_b2);
   result := result + _b1;
end;

// =============================================================================
                  function TArfolyamTarolo.RealToStr(_rr: real): string;
// =============================================================================

var _pos: integer;

begin
  Result := '0';
  if _rr=0 then exit;

  Result := Floattostr(_rr);
  _pos := pos(chr(44),result);
  if _pos>0 then result[_pos] := chr(46);
end;

// =============================================================================
                  procedure TArfolyamTarolo.MakeArfolyamTabla;
// =============================================================================


begin
  _pcs := 'CREATE TABLE ' + _tablanev + ' (' + _sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'IDO CHAR (8) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'LIMIT1 INTEGER,' + _sorveg;
  _pcs := _pcs + 'LIMIT2 INTEGER,' + _sorveg;
  _pcs := _pcs + 'LIMIT3 INTEGER,' + _sorveg;
  _pcs := _pcs + 'ALAPVETEL DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'ALAPELADAS DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'LIM1VETEL DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'LIM1ELADAS DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'LIM2VETEL DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'LIM2ELADAS DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'ELSZAMOLASIARFOLYAM DOUBLE PRECISION)';

  ArfolyamDbase.Connected := true;
  if arfolyamTranz.InTransaction then ArfolyamTranz.Commit;
  ArfolyamTranz.StartTransaction;
  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      execSql;
    end;

  _pcs := 'CREATE INDEX IDX_' + _tablanev + _sorveg;
  _pcs := _pcs + 'ON '+_tablanev+' (DATUM,IDO)';

  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      execSql;
    end;

  ArfolyamTranz.Commit;
  ArfolyamDbase.close;
end;

// =============================================================================
                  procedure TarfolyamTarolo.ArfolyamKijelzes;
// =============================================================================

var i,_y: integer;

begin
  _aktev := yearof(date);

  writePanel.Visible    := False;
  Readpanel.visible     := False;
  Tortenetpanel.Visible := False;

  Evcombo.Visible := False;
  Hocombo.Visible := False;
  Datumrendbengomb.Visible := False;

  Hocombo.Items.Clear;
  EvCombo.Items.Clear;

  _y := 5;
  while _y>=0 do
    begin
      Evcombo.Items.add(inttostr(_aktev-_y));
      dec(_y);
    end;
   evcombo.ItemIndex := 6;


  for i := 1 to 12 do Hocombo.Items.add(_honev[i]);

  _akthonap := monthof(date);
  hocombo.ItemIndex := _akthonap-1;

  TortenetPanel.Visible := True;
  ActiveControl := Ehavigomb;
end;


{
// =============================================================================
        procedure TARFOLYAMTAROLO.RACSDrawCell(Sender: TObject; ACol,
                           ARow: Integer; Rect: TRect; State: TGridDrawState);
// =============================================================================

var s: string;

begin
  if Arow=0 then
    begin
      Racs.canvas.Brush.Color := $5050ff;
      Racs.canvas.Font.Color := clYellow;
      Racs.Canvas.font.Style := [fsBold];
       Racs.Canvas.FillRect(rect);
      S := racs.cells[acol,arow];
      racs.Canvas.TextOut(rect.Left+2,rect.Top+2,S);
      exit;
    end;
  if Arow=racs.Row then
    begin
      Racs.Canvas.Font.Style := [fsBold];
      Racs.Canvas.Font.Size := 12;
      Racs.Canvas.FillRect(rect);
      S := racs.cells[acol,arow];
      racs.Canvas.TextOut(rect.Left+2,rect.Top+2,S);
    end;

  if (acol<3) or (acol=7) then exit;

  if (acol<5) then
    begin
      Racs.Canvas.Font.Color := clNavy;
      Racs.Canvas.Brush.Color := $B0FFFF;
      Racs.Canvas.FillRect(rect);
      S := racs.cells[acol,arow];
      racs.Canvas.TextOut(rect.Left+2,rect.Top+2,S);
      exit;
    end;

  if (acol>4) then
    begin
      Racs.Canvas.Font.Color := clRed;
      Racs.Canvas.Brush.Color := $FFB0FF;
      Racs.Canvas.FillRect(rect);
      S := racs.cells[acol,arow];
      racs.Canvas.TextOut(rect.Left+2,rect.Top+2,S);
    end;
end;
}


// =============================================================================
            procedure TARFOLYAMTAROLO.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  if arfolyamQuery.Active then
    begin
      ArfolyamQuery.close;
      ArfolyamDbase.close;
    end;

  _mResult := 1;
  Kilepo.Enabled := true;
end;

// =============================================================================
           procedure TArfolyamTarolo.RegebbiGombClick(Sender: TObject);
// =============================================================================


var _evindex,_hoindex,_aktev,_aktho: integer;

begin
 
  _aktho   := monthof(date);
  _evindex := 5;
  _hoIndex := _aktho-1;

  evcombo.ItemIndex := _evIndex;
  hocombo.ItemIndex := _hoIndex;

  evcombo.Visible := true;
  hocombo.Visible := true;
  datumrendbenGomb.visible := True;

  ActiveControl := DatumrendbenGomb;
end;


// =============================================================================
         procedure TARFOLYAMTAROLO.datumrendbengombClick(Sender: TObject);
// =============================================================================

var _evindex,_code: integer;
    _evs: string;

begin
  _evindex := evcombo.ItemIndex;
  _evs := evcombo.Items[_evindex];
  val(_evs,_aktev,_code);

  _akthonap := 1 + Hocombo.itemindex;
  _farok := nulele(_aktev-2000)+nulele(_akthonap);
  _tablanev := 'SARF' + _farok;

  ArfolyamDbase.Close;
  ArfolyamTabla.close;
  ArfolyamTabla.TableName := _tablanev;
  ArfolyamDbase.Connected := true;

  if not ArfolyamTabla.Exists then
    begin
      ShowMessage('A KÉRT HÓNAPRÓL NINCSENEK ADATAIM !');
      Arfolyamdbase.close;
      _MResult := 2;
      Kilepo.Enabled := True;
      Exit;
    end;
  EHavigombclick(Nil);
end;

// =============================================================================
            procedure TARFOLYAMTAROLO.EHAVIGOMBClick(Sender: TObject);
// =============================================================================

begin
  TortenetPanel.visible := false;
  with ReadPanel do
    begin
      Top := 60;
      Left := 5;
      Visible := true;
    end;

  _farok := Nulele(_aktev-2000) + Nulele(_akthoNAP);
  _tablanev := 'SARF' + _farok;

  arfolyamdbase.close;
  arfolyamtabla.close;

  ArfolyamTabla.TableName := _Tablanev;
  ArfolyamDbase.Connected := True;

  if not ArfolyamTabla.Exists then
    begin
      SHowMessage('A KÉRT HÓNAPRÓL NINCSENEK ADATAIM !');
      ArfolyamDbase.close;
      _MResult := 2;
      Kilepo.Enabled := true;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM,IDO';

  ArfolyamDbase.Connected := true;
  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ArfolyamQuery.close;
      Arfolyamdbase.close;
      ShowMessage('ÜRES AZ ADATBÁZIS');
      VisszaGombClick(Nil);
      exit;
    end;

  _aktDatum := ArfolyamQuery.FieldByName('DATUM').asstring;
  _aktIdos := ArfolyamQuery.FieldByname('IDO').asString;

  EgyRacsDisplay;
end;

// =============================================================================
            function TArfolyamTarolo.Nulele(_int: integer): string;
// =============================================================================


begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

// =============================================================================
                   procedure TarfolyamTarolo.EgyracsDisplay;
// =============================================================================

begin
  KedvezmenyPanel.Visible := False;
  KisPanel.Visible        := False;

  EgyIdoBeolvasas;

  _aktevs  := leftstr(_aktdatum,4);
  _akthonap:= strtoint(midstr(_aktdatum,6,2));
  _aktnaps := midstr(_aktdatum,9,2);

  _foc := _aktevs + ' '+ _honev[_akthonap] + ' '+ _AKTNAPS +'-N ('+ _aktidos + '-KOR) ';
  _foc := _foc + ' KIADOTT ÁRFOLYAMTÁBLA';

  ArfolyamCimPanel.Caption := _foc;
  ArfolyamCimPanel.Repaint;

  RacsTakarito;

  Racs.Cells[0,0] := '   VALUTANEM';
  Racs.cells[1,0] := '  Vételi árfolyam';
  Racs.Cells[2,0] := '  Eladási árfolyam';
  Racs.Cells[3,0] := '  1. Kedvm. vétel';
  Racs.Cells[4,0] := '  1. Kedvm.eladás';
  Racs.Cells[5,0] := '  2. Kedvm. vétel';
  Racs.Cells[6,0] := '  2. Kedvm.eladás';
  Racs.Cells[7,0] := '  Elszámolási árf';

  _qq := 1;
  while _qq<=_aktValutaDarab do
    begin
      _aktdnem := _yDnem[_qq];
      Racs.cells[0,_qq] := '         ' + _aktdnem;
      Racs.cells[1,_qq] := realformat(_yvet[_qq]);
      Racs.cells[2,_qq] := realformat(_yelad[_qq]);
      Racs.cells[3,_qq] := RealFormat(_y1vet[_qq]);
      Racs.cells[4,_qq] := RealFormat(_y1elad[_qq]);
      Racs.Cells[5,_qq] := RealFormat(_y2vet[_qq]);
      Racs.Cells[6,_qq] := RealFormat(_y2elad[_qq]);
      Racs.cells[7,_qq] := realformat(_yelszam[_qq]);
      inc(_qq);
    end;
  with Racs do
    begin
      left := 8;
      Visible := true;
    end;    
  ActiveControl     := Racs;
end;

// =============================================================================
               procedure TarfolyamTarolo.RacsTakarito;
// =============================================================================
begin
  _qq := 1;
  while _qq<=24 do
    begin
      racs.cells[0,_qq]:= ' ';
      racs.cells[1,_qq]:= ' ';
      racs.cells[2,_qq]:= ' ';
      racs.cells[3,_qq]:= ' ';
      racs.cells[4,_qq]:= ' ';
      racs.cells[5,_qq]:= ' ';
      racs.cells[6,_qq]:= ' ';
      racs.cells[7,_qq]:= ' ';
      inc(_qq);
    end;
end;

// =============================================================================
          function TarfolyamTarolo.RealFormat(_real: real): string;
// =============================================================================

begin
  if _aktdnem='JPY' then _real := _real/10;
  result := '            '+ Formatfloat('### ###.#',_real);
end;

// =============================================================================
                procedure TarfolyamTarolo.EgyIdoBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM=' + chr(39)+ _aktDatum + chr(39);
  _pcs := _pcs + ') AND (IDO='+chr(39)+_aktidos+chr(39)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  ArfolyamDbase.Connected := true;
  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
      _L1 := FieldByName('LIMIT1').asInteger;
      _L2 := FieldByName('LIMIT2').asInteger;
      _L3 := FieldByName('LIMIT3').asInteger;
    end;

  _qq := 1;
  while not ArfolyamQuery.eof do
    begin
      with ArfolyamQuery do
        begin
          _yDnem[_qq]  := FieldByName('VALUTANEM').asString;
          _yvet[_qq]   := FieldByName('ALAPVETEL').asFloat;
          _yelad[_qq]  := FieldByName('ALAPELADAS').asFloat;
          _y1vet[_qq]  := FieldByName('LIM1VETEL').asFloat;
          _y1elad[_qq] := FieldByName('LIM1ELADAS').asFloat;
          _y2vet[_qq]  := FieldByName('LIM2VETEL').asFloat;
          _y2elad[_qq] := FieldByName('LIM2ELADAS').asFloat;
          _yelszam[_qq]:= FieldByName('ELSZAMOLASIARFOLYAM').asFloat;
        end;
      _aktvalutaDarab := _qq;
      inc(_qq);
      ArfolyamQuery.Next;
    end;
  Arfolyamquery.close;
  ArfolyamDbase.close;
end;

// =============================================================================
            procedure TARFOLYAMTAROLO.LIMITGOMBClick(Sender: TObject);
// =============================================================================

begin

  TOL1PANEL.Caption := Limitform(_L1+1);
  Tol2Panel.Caption := Limitform(_L2+1);
  Ig1Panel.Caption  := LimitForm(_L2);
  Ig2Panel.Caption  := LimitForm(_L3);

  _kpt := 530;
  _kpL := 60;
  _kpw := 80;
  _kpH := 40;
  with Kispanel do
    begin
      Top     := _kpt;
      Left    := _kpL;
      width   := _kpW;
      Height  := _kpH;
      Visible := True;
    end;
  UszoTimer.enabled := true;
end;

// =============================================================================
          procedure TARFOLYAMTAROLO.USZOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  UszoTimer.Enabled := false;
  if _kpt>160 then _kpt := _kpt-5;
  if _kpL<160 then _kpL := _kpL + 5;
  if _kpw<440 then _kpw := _kpw + 5;
  if _kpH<220 then _kph := _kph + 5;
  if (_kpt=160) and (_kpl=160) and (_kpw=440) and (_kph=220) then
    begin
      Kispanel.Visible := false;
      Visszagomb.Cancel := false;
      with Kedvezmenypanel do
        begin
          Top     := 160;
          Left    := 160;
          Height  := 220;
          Width   := 440;
          Visible := true;
        end;
    end else
    begin
      with Kispanel do
        begin
          Top    := _kpt;
          Left   := _kpL;
          width  := _kpW;
          Height := _kpH;
        end;
      Uszotimer.Enabled := True;
    end;
end;

// =============================================================================
        procedure TARFOLYAMTAROLO.KEDVVISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  KedvezmenyPanel.Visible := False;
  VisszaGomb.Cancel := true;
  ActiveControl := Racs;
end;


// =============================================================================
           function TArfolyamtarolo.Limitform(_int: integer):string;
// =============================================================================


var _pp: integer;
begin
  result := inttostr(_int);
  if _int<1000 then exit;
  if _int>=1000000 then
    begin
      _pp := length(result)-6;
      result := leftstr(result,_pp)+'.'+midstr(result,_pp+1,3)+'.'+midstr(result,_pp+4,3);
      exit;
    end;
  _pp := length(result)-3;
  result := leftstr(result,_pp)+'.'+midstr(result,_pp+1,3);
end;


// =============================================================================
         procedure TArfolyamTarolo.KovetkezoGombClick(Sender: TObject);
// =============================================================================

begin
  If kovetkezoIdo then
    begin
      EgyRacsDisplay;
      exit;
    end;
  ShowMessage('NEM VOLT A HÓNAPBAN TÖBB ÁRFOLYAMVÁLTOZÁS');
end;

// =============================================================================
          procedure TARFOLYAMTAROLO.kilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  ModalResult := _mResult;
end;

// =============================================================================
        procedure TARFOLYAMTAROLO.MASIKHONAPGOMBClick(Sender: TObject);
// =============================================================================

begin
  if ArfolyamQuery.Active then
    begin
      ArfolyamQuery.close;
      arfolyamDbase.close;
    end;
  ArfolyamKijelzes;
end;



// =============================================================================
               function TarfolyamTarolo.KovetkezoIdo: boolean;
// =============================================================================


begin
  result := false;
  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM,IDO';
  Arfolyamdbase.connected := True;
  with ArfolyamQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      Locate('DATUM',_aktdatum,[loPartialKey]);
    end;
  while not ArfolyamQuery.eof do
    begin
      _xDatum := ArfolyamQuery.FieldByName('DATUM').asString;
      _xIdos := arfolyamQuery.FieldByName('IDO').asSTRING;
      if (_xdatum>_aktdatum) or (_xIdos>_aktIdos) then
        begin
          _aktdatum := ArfolyamQuery.fieldbyname('DATUM').asstring;
          _aktIdos := ArfolyamQuery.FieldByName('IDO').assTRING;
          result := true;
          break;
        end;
      ArfolyamQuery.Next;
    end;
  ArfolyamQuery.close;
  ArfolyamDbase.close;
end;

// =============================================================================
               function TarfolyamTarolo.ElozoIdo: boolean;
// =============================================================================

begin
  result := false;
  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM,IDO';
  Arfolyamdbase.connected := True;
  with ArfolyamQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      Locate('DATUM',_aktdatum,[loPartialKey]);
      _xIDOS := FieldByName('IDO').asstring;
    end;

  if _xIdos=_aktidos then
    begin
      ArfolyamQuery.Prior;
      if ArfolyamQuery.bof then
        begin
          ArfolyamQuery.close;
          ArfolyamDbase.close;
          Exit;
        end;

      _aktdatum := ArfolyamQuery.fieldbyname('DATUM').asstring;
      _aktidos := ArfolyamQuery.FieldByName('IDO').asString;
      result := true;
      exit;
    end;

  while not ArfolyamQuery.Eof do
    begin
      _xIdos := ArfolyamQuery.FieldByName('IDO').asstring;
      if _xIdos=_aktIdos then
        begin
          ArfolyamQuery.prior;
          _AktIdos := Arfolyamquery.FieldByName('IDO').assTRING;
          result := true;
          break;
        end;
      arfolyamQuery.Next;
    end;

  ArfolyamQuery.close;
  ArfolyamDbase.close;
end;

procedure TARFOLYAMTAROLO.ELOZOGOMBClick(Sender: TObject);
begin
  if ElozoIdo then
    begin
      EgyRacsDisplay;
      exit;
    end;
  ShowMessage('Nem volt a hónapban ez elött másik árfolyam');
end;


function TarfolyamTarolo.HunDatetostr(_caldat: TDateTime): string;
var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;










procedure TARFOLYAMTAROLO.EVCOMBOChange(Sender: TObject);
begin
  Activecontrol := Datumrendbengomb;
end;

end.
