unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DBTables, DB, sTRuTILS, DBIProcs, Dbierrs, DBITypes,
  ExtCtrls, idGlobal, Buttons,DateUtils, jpeg, ComCtrls, IBDatabase,
  IBCustomDataSet, IBTable, IBQuery;

type
  TForm1 = class(TForm)

    StartIdozito: TTimer;

    Label1: TLabel;

    QuitGomb: TBitBtn;
    mnbcsikpanel: TPanel;
    mnbcsik: TProgressBar;

    DAYBOOKTABLA: TIBTable;
    DAYBOOKDBASE: TIBDatabase;
    DAYBOOKTRANZ: TIBTransaction;

    BLOKKFEJTABLA: TIBTable;
    BLOKKFEJDBASE: TIBDatabase;
    BLOKKFEJTRANZ: TIBTransaction;

    BLOKKTETELTABLA: TIBTable;
    BLOKKTETELDBASE: TIBDatabase;
    BLOKKTETELTRANZ: TIBTransaction;

    MNBTABLA: TIBTable;
    MNBDBASE: TIBDatabase;
    MNBTRANZ: TIBTransaction;

    IBDbase: TIBDatabase;
    IBTranz: TIBTransaction;
    IBQuery: TIBQuery;

    CIMTARTABLA: TIBTable;
    CIMTARDBASE: TIBDatabase;
    CIMTARTRANZ: TIBTransaction;

    NARFTABLA: TIBTable;
    NARFDBASE: TIBDatabase;
    NARFTRANZ: TIBTransaction;

    MNBTEMPTABLA: TIBTable;
    MNBTEMPDBASE: TIBDatabase;
    MNBTEMPTRANZ: TIBTransaction;
    IBTabla: TIBTable;
    Label3: TLabel;
    RECEPTORQUERY: TIBQuery;
    RECEPTORDBASE: TIBDatabase;
    RECEPTORTRANZ: TIBTransaction;
    DAYBOOKQUERY: TIBQuery;
    Shape2: TShape;
    Shape3: TShape;
    Image1: TImage;

    procedure AdatControl(_napstr: STRING);
    procedure DbkControl(_napstr: string);
    procedure FillDayBook(_tnev: string;_datums: string);
    procedure FormCreate(Sender: TObject);
    procedure IrodaBetolto;
    procedure ValutaBetolto;
    procedure KilepGombClick(Sender: TObject);
    procedure MakeDayBook(_dbknev: string);
    procedure MenuJob(Sender: TObject);
    procedure RendszerAdatBeolvasas;
    procedure TextKiiro;


    // -------------- functions -----------------------

    function BennvanMindenzaras(_napstr: string):boolean;
    function DNemScan(_vn: string):integer;
    function DayBookReader(_napstr: string): Boolean;
    function DecitoHexa(_deci: byte):string;
    function Elokieg(_num: integer): string;
    function ForintForm(_osszeg:integer):string;
    function HexaToDec(_hexa: string): integer;
    function Kieg(_mit:string;_hh:integer):string;
    function Nulele(_szam: integer): string;
    function PtarScan(_pt: integer):integer;
    function SetLongDstring(_dstring: string):string;
    function TegnapControl(_datums:string):boolean;
    function TablaExists(_fdbpath: string; _tnev: string): boolean;
    function Vanilyeniroda(_irszam: integer): boolean;
    function ValutaControl(_val: string):boolean;
    function ErtTarScan(_et: integer): integer;
    function BankScan(_tpt: string):integer;
    function RealToStr(_rr: real): string;

    function VesszobolPont(_vst: string): string;
    function FtForm(_ft:real):string;
    function GetCegbetuSorszam(_betu: string): integer;
   
    function HDateToStr(_hdat: TDateTime): string;
    function HstrToDate(_dst: string): TDateTime;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _valutaDarab : integer = 28;

  // ---------------------- Tomb deklaraciok --------------------------------

  _honapnev: array[1..12] of string = ('Január','Február','Március','Április',
               'Május','Junius','Július','Augusztus','Szeptember','Október',
               'November','December');

  _napnev: array[1..7] of string = ('HÉTFÕ','KEDD','SZERDA','CSÜTÖRTÖK','PÉNTEK',
               'SZOMBAT','VASÁRNAP');

  _ertekTarDarab: byte = 9;

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY','CZK',
         'DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK','NZD','PLN','RON',
         'RSD','RUB','SEK','THB','TRY','UAH','USD');

  _dnev: array[1..27] of string = ('Ausztral dollar','Bosnyak marka','Bolgar leva',
         'Brazil real','Kanadai dollar','Svajci frank','Kinai juan','Cseh korona',
         'Dan korona','Euro','Angol font','Horvat kuna','Magyar forint','Izraeli shakel',
         'Japan jen','Mexikoi peso','Norveg korona','Ujzelandi dollar',
         'Lengyel zloty','Roman lei','Szerb dinar','Orosz rubel','Sved korona',
         'Thai bath','Torok lira','Ukran hrivnya','Usa dollar');


  _kvett,_keladott,_kvettertek,_keladottertek: array[1..9,0..27] of integer;
  _kkvett,_kkeladott,_kkvettertek,_kkeladottertek: array[1..4,0..27] of integer;
  _kelszarf,_sumvett,_sumeladott,_sumvettertek,_sumeladottertek: array[0..27] of integer;

  _kockaszin: array[1..5] of TColor = (clBlack,clGray,clBlue,clYellow,clRed);
  _betuszin : array[1..5] of TColor = (clGray,clBlack,clWhite,clBlue,clYellow);
  _statuzen : array[1..5] of String = ('NINCS VÁLTÓ','ZÁRVA','KÉZI BEVITEL',
                                         'ADAT BEJÖTT','NEMJÖTT BE');
      _bankJel: array[1..9] of string;
  _missPenztar: array of integer;

  _korzetnev : array[1..9] of string = ('Szekszárd','Szeged','Kecskemét','Debrecen',
                         'Nyíregyháza','Békéscsaba','Pécs','Kaposvár','Expressz');

  _korzetszam: array[1..9] of integer = (10,20,40,50,63,75,120,145,180);
  _cegbetuk  : array[1..4] of string = ('B','P','E','Z');
  _azonosito : array[1..4] of string;
  _valtonev  : array[1..4] of string;
  _impid     : array[1..4] of string;

   _cimlet: array[1..14] of integer = (20000,10000,5000,2000,1000,500,200,
                                       100,50,20,10,5,2,1);

   _LFile,_olvas,_nyomtat: TextFile;

   _varf,_earf,_elszarf: array[0..27] of integer;
   _korzet: array[1..180] of byte;
   _boltnev,_irodanev,_city,_bankkod,_cegbetutomb: array[1..180] of string;
   _etarbetutomb,_nstatus,_vasarnap,_bezarva,_vTipus: array[1..180] of string;

    _subdir: array[1..4] of string = ('BEST','PANNON','EAST','ZALOG');
    _irodaszam: array of integer;
    _cim: array[1..14] of integer;
    _sorveg: string = chr(13)+chr(10);
    _prosnevsor: array[1..500] of string;
    _evtomb,_jmentes: array[1..500] of integer;

  // ------------------- STRING DEKLARACIOK ----------------------------

   _aktBfej,
   _aktBlokkNum,
   _aktBTet,
   _aktCegbetu,
   _aktCegnev,
   _aktDatums,
   _aktDir,
   _aktDnem,
   _aktDNev,
   _aktFej,
   _aktFdbPath,
   _aktKorzetnev,
   _aktPenztarnev,
   _aktStatus,
   _aktSunday,
   _aktTarsPenztar,
   _aktTet,
   _aktTipus,
   _bankForg,
   _bf,
   _bkTipus,
   _bt,
   _cegbetu,
   _closed,
   _datum,
   _datumigs,
   _datumtols,
   _fbkFile,
   _dbMezo,
   _displayfocim,
   _elofarok,
   _elojel,
   _farok,
   _fark,
   _hianyString,
   _holnaps,
   _ido,
   _idoszakLabel,
   _idoszakSzuro,
   _igs,
   _igString,
   _irodadnem,
   _jelszo,
   _kbJelzo,
   _keres,
   _mainSzuro,
   _mamas,
   _megnev,
   _mezo,
   _napmezo,
   _napstatus,
   _narfName,
   _narfPath,
   _pcs,
   _penztar,
   _prosnev,
   _sttipus,
   _sunday,
   _szuro,
   _tegnaps,
   _telefon,
   _tema,
   _tFarok,
   _tipus,
   _tolfarok,
   _tols,
   _tolString,
   _trbptars,
   _utstatus,
   _uzDnem,
   _valutanem,
   _valutanev: string;

   // ------------- Date deklarációk ------------------------------------

   _elsoDatum,
   _nDatum,
   _nyDatum,
   _tDatum,
   _uDatum: TDateTime;

  
  _bankiAtad,
  _bankiAtvet,
  _bankJegy,
  _bevetel,
  _eddig,
  _eladas,
  _eladasiArfolyam,
  _eladott,
  _eladottErtek,
  _elszamolasiArfolyam,
  _elszarfolyam,
  _elteres,
  _ertek,
  _hiany,
  _keszlet,
  _kiadas,
  _osszesen,
  _nyito,
  _ptarAtvesz,
  _ptarKiad,
  _sftErtek,
  _skeszlet,
  _szamZaro,
  _tobblet,
  _ujBankjegy,
  _vetel,
  _veteliArfolyam,
  _vett,
  _vettErtek,
  _visszaMinusz,
  _visszaPlusz: integer;

  // ------------------------- WORD DECLARATION ------------------------

   _aktev,
   _aktho,
   _aktnap,
   _hnap,
   _kertev,
   _kertho,
   _kellCtrl,
   _tegnapev,
   _tegnapho,
   _tegnapnap,
   _tolev,
   _tolho,
   _tolnap,
   _tnap,
   _trbPtar,
   _xEv,
   _xHonap,
   _xNap: word;

  // ---------------------- INTEGER DECLARATIONS -----------------------

   _aktCimlet,
   _aktErtek,
   _aktErtekTar,
   _aktKorzet,
   _aktMenuRud,
   _aktPenztar,
   _aktPenztarszam,
   _aktPt,
   _aktTarsPenztarSzam,
   _bJegy,
   _bq,
   _cbsors,
   _cc,
   _cegSs,
   _code,
   _darab,
   _displayTipus,
   _dnemDarab,
   _eladasDb,
   _eloEv,
   _eloHo,
   _ertektar,
   _fogado,
   _height,
   _hetnap,
   _houtnap,
   _iroda,
   _irodaDarab,
   _irszam,
   _kft,
   _kuldo,
   _left,
   _lastPenztar,
   _pausePerc,
   _penztardarab,
   _prisor,
   _qq,
   _stip,
   _storno,
   _top,
   _utsorszam,
   _vasarnapDb,
   _veteldb,
   _width,
   _xx: integer;
   _zaro,
   _zhiany: integer;

  // --------------------- DATUM DEKLARACIOK  --------------------------

   _aktDatum,
   _datumtol,
   _datumig,
   _ig,
   _mama,
   _tegnap,
   _tol,
   _zNap: TDateTime;

  // ------------------------- LOGIKAI DEKLARACIOK ----------------------

   _eof,
   _found,
   _hibas,
   _megvan,
   _oke,
   _sajat,
   _torolt,
   _voltadat,
   _ezTegnap,
   _ezegynap,
   _vancimtar,
   _kellExcel,
   _vanHiany: Boolean;

  // ------------------------- EGYEB DEKLARACIOK ------------------------

    _aktPanel: TPanel;
    _betu: char;
    _dataFile: File of Char;


function jutalekszorzo: integer; stdcall; external 'c:\receptor\jszorzo.dll' name 'jutalekszorzo';

function tranzakciojelentes: integer;stdcall;external 'c:\receptor\tranzdij.dll'
                                                      name 'tranzakciojelentes';    
function dolgozoinyilvantartas: integer;stdcall;external 'c:\receptor\ptarosok.dll'
                                                   name 'dolgozoinyilvantartas';

function makeimportrutin: integer; stdcall; external 'c:\receptor\makimprt.dll'
                                       name 'makeimportrutin';

implementation

uses Unit2, Unit3, Unit4, Unit7, Unit10, Unit11, Unit12,
  Unit14, Unit20, Unit6, Unit21, Unit16, Unit31, Unit33, Unit34, Unit37;

{$R *.dfm}


// =====================================================
      procedure TForm1.FormCreate(Sender: TObject);
// =====================================================

begin
  _height := Screen.Monitors[0].height;
  _width := screen.Monitors[0].width;

  if _width<768 then
    begin
      ShowMessage('ÁLLITS A KÉPERNYÖT 1024*768-RA');
      Application.Terminate;
      exit;
    end;
   _top := 0;
  _left := 0;

  if _height>768 then
    begin
       _top := trunc((_height-768)/2);
      _left := trunc((_width-1024)/2);
    end;

     top := _top+120;
    left := _left+140;
  Height := 530;
   width := 750;

  Label1.Visible := true;
  _tegnaps := leftstr(hdatetostr(now-1),10);
  _mamas := leftstr(hdatetostr(now),10);
  _holnaps := leftstr(hdatetostr(now+1),10);

  Form1.Repaint;

  RendszerAdatBeolvasas;  // Az alapadatok beolvasása
  ValutaBetolto;
  IrodaBetolto;           // Az irodák és értéktárak adatait tömbbe olvassa
  SetLength(_missPenztar,_IrodaDarab);
  DbkControl(_holnaps); // paraméterben adott napra ha van naplófile -> visszatér
                        //  - ha nincs -> létrehozza, feltölti pénztárakkal, vasár-
                        // és ünnepnapokat kiixeli, ha a váltó vasárnap zárva

  StartIdozito.Enabled := True;
end;

// ====================================
       procedure TForm1.MenuJob;
// ====================================

var _aktmenuPont,_vanUser: integer;
    _zarasOke: boolean;

begin

  StartIdozito.Enabled := False;     // Az idözitö kikapcsolása
  _vanUser := UserForm.Showmodal;    // Belép a felhasználó

  if _vanUser<>1 then                // Nem tudja a jelszavat
    begin
      Application.Terminate;         // Kilépés
      Exit;
    end;

// -----------------------------------------------------------

  _aktmenuRud := 3;
  _kellctrl := 0;

  // Ha bejött minden zárás, vizsgálja az adatok helyességét:

  _zarasOke := TegnapControl(_tegnaps);

  if _zarasOke then
    begin
      _kellCtrl := KellTegnap.ShowModal;
      if _kellCtrl=1 then  AdatControl(_tegnaps);
    end else HianyzoZarasokForm.ShowModal;

  // Itt jöhet a fömenü ciklusfeje:
  _kellCtrl := 0;

  while True do
    begin
      _aktmenupont := Fomenuform.ShowModal;  // Bekéri a menupontot
      if _aktmenuPont=-1 then                // Befejezi a munkát
        begin
          Application.Terminate;
          Exit;
        end;

      // A kert menupontnak megfelelo program hivasa:

      case _aktmenupont of
        1: Rendszeradatok.ShowModal;
        2: ArfolyamTmk.ShowModal;
        3: GetDataDisp.showModal;
        4: IRODATMK.Showmodal;
        5: makeimportrutin;
        6: Attekintes.ShowModal;
        7: MnBListak.ShowModal;
        8: Atlagarfolyam.Showmodal;
        9: Jutszam.ShowModal;
       10: ArfolyamElterites.ShowModal;
       11: WuniWafaControl.ShowModal;
       12: dolgozoinyilvantartas;
       13: tranzakciojelentes;
       14: jutalekszorzo;
      end;
    end;
end;

// ===================================================
    procedure TForm1.KilepGombClick(Sender: TObject);
// ===================================================

begin
  Application.Terminate;
end;


// ===========================================================
       function TForm1.HexaToDec(_hexa: string): integer;
// ===========================================================

var _tizes,_egyes: byte;
begin
  _tizes := ord(_hexa[1]);
  _egyes := ord(_hexa[2]);
  _tizes := _tizes - 48;
  _egyes := _egyes - 48;
  if _tizes>9 then _tizes := _tizes-7;
  if _egyes>9 then _egyes := _egyes - 7;
  result := trunc((16*_tizes)+_egyes);
end;


// ========================================================================
         function TForm1.SetLongDstring(_dstring: string):string;
// ========================================================================

var _ddatum: TdateTime;
    _dho,_dnap,_hnap: word;
begin
  result := leftstr(_dstring,4);
  _ddatum := hstrtodate(_dstring);
  _dho := strtoint(midstr(_dstring,6,2));
  _dnap := strtoint(midstr(_dstring,9,2));
  _hnap := dayoftheweek(_ddatum);
  result := result + ' '+ _honapnev[_dho]+' '+inttostr(_dnap)+' '+_napnev[_hnap];
end;


// ================================================================
         function TForm1.Elokieg(_num: integer): string;
// ================================================================

begin
  Result := inttostr(_num);
  while length(Result)<3 do Result := chr(32)+Result;
end;


// ==========================================================
       function Tform1.ForintForm(_osszeg:integer):string;
// ==========================================================

var _slen,_pp: integer;
    _ejel : string;

begin
  result := '-';

  if _osszeg=0 then exit;

  _ejel := '';

  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;

  result := inttostr(_osszeg);

  if _osszeg<1000 then
    begin
      result := _ejel + result;
      exit;
    end;

  _slen := length(result);
  if _osszeg>999999 then
    begin
      _pp := _slen-5;
      result := _ejel + midstr(result,1,_pp-1)+' '+midstr(result,_pp,3)+' '+midstr(result,_pp+3,3);
      exit;
    end;
  _pp := _slen-2;
  result := _ejel + midstr(result,1,_pp-1)+' '+midstr(result,_pp,3);

end;

// ==========================================================
         function TForm1.PtarScan(_pt: integer):integer;
// ==========================================================

var j: integer;
begin
   result := -1;
   for j:= 0 to (_IrodaDarab-1) do
     begin
       if _irodaszam[j] = _pt then
         begin
           result := j;
           exit;
         end;
     end;
end;



// =*==***=**==**==**==**==**==**==**==**==**==**==**==**==**===**==**=
// ================================================
      procedure TForm1.RendszeradatBeolvasas;
// ================================================

var i: integer;
    _bj: string;
begin
   ReceptorDbase.Connected := true;
   with ReceptorQuery do
     begin
       Close;
       Sql.clear;
       sql.Add('SELECT * FROM RENDSZER');
       Open;
       _azonosito[1]:= FieldByName('AZONOSITO').asString;
       _valtonev[1] := FieldByName('VALTONEV').asstring;
       _azonosito[2]:= FieldByName('AZONOSITO1').asString;
       _valtonev[2] := FieldByName('VALTONEV1').asstring;
       _azonosito[3]:= FieldByName('AZONOSITO2').asString;
       _valtonev[3] := FieldByName('VALTONEV2').asstring;
  //     _azonosito[4]:= FieldByName('AZONOSITO3').asString;
  //     _valtonev[4] := FieldByName('VALTONEV3').asstring;
       _pausePerc   := FieldByName('PAUSEPERC').asInteger;
       _imPid[1]    := FieldByname('BETUJEL').asString;
       _imPid[2]    := FieldByname('BETUJEL1').asString;
       _imPid[3]    := FieldByname('BETUJEL2').asString;
  //     _impId[4]    := FieldByName('BETUJEL3').asString; 
     end;

   for i := 1 to 9 do
     begin
       _mezo := 'BANKFK' + inttostr(i);
       _bj := ReceptorQuery.FieldByName(_mezo).asString;
       _bankjel[i] := trim(_bj);
     end;

   _jelszo := ReceptorQuery.FieldbyName('JELSZO').asstring;
   ReceptorQuery.Close;
   ReceptorDbase.Close;
end;

// =============================================
       procedure Tform1.Valutabetolto;
// =============================================

var _vetelarf,_eladarf,_eszarf: integer;

begin

  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';
  ReceptorDbase.Connected := true;
  with ReceptorQuery do
    begin
      Close;
      sql.Clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _cc := 0;
  while not ReceptorQuery.Eof do
    begin
      with ReceptorQuery do
        begin
          _valutanem := FieldByName('VALUTANEM').asString;
          _valutanev := FieldByName('VALUTANEV').asstring;
          _vetelarf  := FieldByName('VETELIARFOLYAM').asInteger;
          _eladarf   := FieldByName('ELADASIARFOLYAM').asInteger;
          _eszarf    := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
        end;

      INC(_CC);

      _dnem[_cc]     := _valutanem;
      _dnev[_cc]     := _valutanev;
      _varf[_cc]     := _vetelarf;
      _earf[_cc]     := _eladarf;
      _elszarf[_cc]  := _eszarf;

      ReceptorQuery.Next;
    end;
  ReceptorQuery.Close;
  ReceptorDbase.close;
end;


function TForm1.ValutaControl(_val: string):boolean;

var z: integer;

begin
  Result := False;
  for z := 0 to 27 do
    begin
      if _val = _dnem[z] then
        begin
          result := true;
          Break;
        end;
    end;
end;

// =============================================================================
                      procedure TForm1.IrodaBetolto;
// =============================================================================

var _xStatus,_xvaros,_xboltnev,_xbankkod,_xvasarnap,_xcegbetu,_xbezarva: string;
    _xertektarszam,z: integer;
begin

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';
  ReceptorDbase.Connected := true;
  with ReceptorQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_PCS);
      Open;
      First;
    end;

  _IrodaDarab := 0;
  while not ReceptorQuery.Eof do
    begin
      inc(_irodaDarab);
      _xstatus := ReceptorQuery.FieldByName('STATUS').asString;
      Receptorquery.Next;
    end;

  SetLength(_irodaszam,_irodaDarab+1);
  for z := 1 to 180 do
    begin
      _vasarnap[z] := '';
      _bezarva[z]  := '';
      _boltnev[z]  := '';
      _irodanev[z] := '';
      _city[z]     := '';
    end;

  _cc := 0;
  ReceptorQuery.First;
  while not ReceptorQuery.Eof do
    begin
      with ReceptorQuery do
        begin
          _uzlet         := FieldByname('UZLET').asInteger;
          _xcegbetu      := FieldByname('CEGBETU').asstring;
          _xvaros        := FieldByName('VAROS').asString;
          _xboltnev      := FieldByName('BOLTNEV').asString;
          _xstatus       := FieldByName('STATUS').asString;
          _xbankkod      := FieldByName('BANKKOD').asString;
          _xertektarszam := FieldByName('ERTEKTAR').asInteger;
          _xvasarnap     := FieldByName('SUNDAYCLOSE').asstring;
          _xbezarva      := FieldByName('CLOSED').asString;
        end;

      _city[_cc]           := trim(_xVaros);
      _irodaszam[_cc]      := _uzlet;
      _vasarnap[_uzlet]    := _xvasarnap;
      _bezarva[_uzlet]     := _xbezarva;
     
      _bankkod[_uzlet]     := trim(_xBankKod);
      _cegbetutomb[_uzlet] := _xcegbetu;
      _boltnev[_uzlet]     := trim(_xBoltnev);
      _vtipus[_uzlet]      := _xStatus;
      _korzet[_uzlet]      := _xErtektarszam;
      _etarbetutomb[_xErtektarszam] := _xCegbetu;
      _irodaNev[_uzlet]    := trim(_xVaros)+' '+trim(_xBoltNev);
      ReceptorQuery.Next;
      inc(_cc);
    end;
  ReceptorQuery.Close;
  ReceptorDbase.Close;
end;

// ====================================================
       procedure TForm1.DbkControl(_napstr: string);
// ====================================================

begin

  _farok := midStr(_Napstr,3,2)+midStr(_Napstr,6,2);
  _fbkFile := 'DAYB'+_Farok;
  _aktfdbPath := 'C:\RECEPTOR\DATABASE\DAYBOOK.FDB';
  if TablaExists(_aktfdbPath,_fbkFile) then exit;

  MakeDayBook(_fbkFile);
  FillDayBook(_fbkFile,_napstr);
end;


// ============================================================
     procedure TForm1.MakeDayBook(_dbkNev: string);
// ===========================================================

var
    z: integer;
begin
  IbDbase.Connected := True;
  if ibTranz.inTransaction then ibTranz.Commit;
  ibTranz.StartTransaction;
  _pcs := 'CREATE TABLE '+_dbkNev+' ('+_sorveg;
  _pcs := _pcs + 'PENZTAR INTEGER,'+_sorveg;

  for z := 1 to 30 do
      _pcs := _pcs + 'N' + inttostr(z)+' CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;

  _pcs := _pcs + 'N31 CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250)';

  with ibQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;

  _pcs := 'CREATE INDEX IDX_' +_dbkNev + ' ON ' + _dbkNev + ' (PENZTAR)';
  with ibQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;


  ibTranz.Commit;
  ibQuery.Close;
end;


// ==================================================================
      procedure TForm1.FillDayBook(_tnev: string;_datums: string);
// ==================================================================

var _xev,_xho,_utnap,z: integer;
    _datelo: string;
    _unnep: array[1..2] of integer;
    _unnepnap,_qq: integer;
    _napDatum: TDateTime;

begin

  _xev := strtoint(leftstr(_datums,4));
  _xho := strtoint(midstr(_datums,6,2));
  _unnepnap := 0;

  if _xho=1 then
    begin
      _unnep[1] := 1;
      _unnepnap := 1;
    end;

  if _xho=12 then
    begin
      _unnep[1] := 25;
      _unnep[2] := 26;
      _unnepnap := 2;
    end;

  if _xho=5 then
    begin
      _unnep[1] := 1;
      _unnepnap := 1;
    end;

  if _xho=8 then
    begin
      _unnep[1] := 20;
      _unnepnap := 1;
    end;

  if _xho=10 then
    begin
      _unnep[1] := 23;
      _unnepnap := 1;
    end;

  _utnap := DaysinAMonth(_xev,_xho);

  dayBookDbase.Connected := true;
  if dayBooktranz.InTransaction then DayBooktranz.Commit;
  Daybooktranz.StartTransaction;
  with DayBookQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('DELETE FROM ' + _tNev);
      ExecSql;
    end;
  DayBookTranz.Commit;
  DayBookDbase.close;

  // ---------------------------------------------------------------------------

  DayBookTabla.close;
  DayBooktabla.TableName := _tNev;
  DaybookDbase.Connected := True;
  DayBookTabla.Open;

  _qq := 0;
  while _qq<_irodaDarab do
    begin
      _iroda := _irodaszam[_qq];
      _sunday := _vasarnap[_qq];
      _closed := _bezarva[_iroda];

      with DayBookTabla do
        begin
          Append;
          Edit;
          FieldbyName('PENZTAR').asInteger := _iroda;
        end;

      for z := 1 to _utnap do
        begin
          _mezo := 'N' + inttostr(z);
          DayBookTabla.FieldByName(_mezo).asstring := ' ';
        end;

   //   if (_utnap<31) then
   //     begin
   //       for z := (_utnap+1) to 31 do
   //         begin
   //           _mezo := 'N' + inttostr(z);
   //           DayBookTabla.FieldByName(_mezo).asstring := 'X';
   //         end;
   //     end;

      if _unnepNap>0 then
        begin
          for z := 1 to _unnepnap do
            begin
              _mezo := 'N' + inttostr(_unnep[z]);
              DayBookTabla.FieldByName(_mezo).asstring := 'X';
            end;
        end;

      if _sunday='X' then
        begin
          _datelo := inttostr(_xev)+'.'+nulele(_xho)+'.';
          for z := 1 to _utnap do
            begin
              _napdatum := hstrtodate(_datelo+nulele(z));
              _hnap := dayoftheweek(_napdatum);
              if _hnap=7 then
                begin
                  _mezo := 'N'+INTTOSTR(Z);
                  DayBooktabla.FieldByNAme(_mezo).asString := 'X';
                end;
            end;
        end;

      if _closed='X' then
        begin
          for z := 1 to _utnap do
            begin
              _mezo := 'N' + inttostr(z);
              DayBookTabla.FieldByName(_mezo).asString := 'X';
            end;
        end;
      DayBookTabla.Post;
      inc(_qq);
    end;

  DayBookTranz.Commit;
  dayBookTabla.Close;
  DayBookDbase.Close;
end;

// ===========================================================================
        function TForm1.TegnapControl(_datums:string):boolean;
// ==========================================================================

// Vizsgálja, hogy bejött-e minden tegnapi adat

var
     i: integer;
     _dayBookName,_napstatus: string;
begin

  // Defaultadatok beállitása:

  Result := True;

  _vanHiany := False;
  _zHiany := 0;

  // Tegnapi napot vizsgálja:

  _farok := midstr(_datums,3,2)+midstr(_datums,6,2);
  _aktnap := strtoint(midstr(_datums,9,2));
  _aktfdbPath := 'c:\receptor\database\daybook.fdb';
 // A naplófile es a mezö meghatározása:

  _daybookname := 'DAYB'+ _farok;
  _napmezo := 'N' + inttostr(_aktnap);

  // A napló-adatbázis megnyitása:

  DayBookDbase.Connected := False;
  DayBookDbase.DataBaseName := _aktfdbPath;
  DayBookDbase.Connected := True;

  with DayBookTabla do
    begin
      Close;
      TableName := _dayBookName;
      IndexFieldNames := 'PENZTAR';
      Open;
      Refresh;
      First;
    end;

  _vanHiany := False;
  _zHiany := 0;

  // Végigmegyünk az összes pénztáron:
  while not DayBookTabla.eof do
    begin
      _aktPenztar := DayBookTabla.FieldByname('PENZTAR').asInteger;
      _napstatus  := DayBookTabla.FieldByname(_napMezo).asString;
      _nstatus[_aktpenztar] := _napstatus;
      if _napstatus='' then
        begin
          _vanHiany := True;
          _missPenztar[_zHiany] := _aktPenztar;
          inc(_zHiany);
          if _zhiany>20 then break;
        end;
      DayBooktabla.Next;
    end;

  // Naplóadatbázis bezárva

  DayBookTabla.Close;
  DayBookDbase.Connected := False;


  if not _vanHiany then exit;

  // A hiánystring összeállitása - ha van:

  _hianyString := '';
  if _vanHiany then
    begin
      for i := 0 to _zhiany-1 do
          _hianyString := _hianyString + inttostr(_missPenztar[i])+',';

      // Jelzi, hogy volt hiányzó zárás:
      Result := False;
    end;
end;


// ===============================================
    procedure TForm1.AdatControl(_napstr:string);
// ===============================================

// Nem hiányzik egy zárás sem - tehát vizsgáljuk az adatokat:

var _megjegyzes,_uzletnev: string;
    _uzlet: integer;

begin

  _datumtols := _napstr;
  _datumigs := _napstr;
  _tolstring := _napstr;
  _igstring := _napstr;
  _eztegnap := True;

  MNBLegyujto.Showmodal; //;;;;;;;;;;;;;;;;;;;;;;;;;;;

  _hibas := False;   // Default ertek

  // A hibakat leiro tabla elokeszitese:

  ReceptorDbase.Connected := true;
  if ReceptorTranz.InTransaction then ReceptorTranz.Commit;
  ReceptorTranz.StartTransaction;
  with ReceptorQuery do
    begin
      close;
      sql.Clear;
      sql.Add('DELETE FROM HIBAK');
      Execsql;
    end;
  Receptortranz.Commit;
  ReceptorDbase.close;

  // MnbTabla megnyitasa es vegigolvasasa:

  MnbDbase.CLose;
  MNBDbase.Connected := true;

  MnbTabla.Open;
  MnbTabla.First;
  while not MNBtabla.eof do
    begin
      _megjegyzes := MnbTabla.FieldByName('MEGJEGYZES').asString;
      _uzlet := MNBtabla.FieldByName('IRODASZAM').asInteger;

      if (_megjegyzes<>'OK') AND (_uzlet>0) then
        begin
          _aktstatus  := _nStatus[_uzlet];
          if _aktstatus = 'X' then
            begin
              MNBTabla.Next;
              Continue;
            end;

          _hibas := True;
          _aktdnem := MNBtabla.FieldByName('VALUTANEM').asString;
          _uzletnev := _irodanev[_uzlet];
          _zaro := MNBTabla.FieldByName('ZARO').asInteger;
          _szamzaro := MNBtabla.FieldByName('SZAMITOTTZARO').asInteger;
          _elteres := _zaro - _szamzaro;

          receptorDbase.Connected := true;
          if receptorTranz.InTransaction then ReceptorTranz.Commit;
          ReceptorTranz.StartTransaction;
          _pcs := 'INSERT INTO HIBAK (IRODA,IRODANEV,VALUTANEM,ELTERES)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(_uzlet) + ',';
          _pcs := _pcs + chr(39) + _uzletnev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
          _pcs := _pcs + inttostr(_elteres) + ')';

          with Receptorquery do
            begin
              Close;
              sql.Clear;
              sql.Add(_pcs);
              Execsql;
            end;
          ReceptorTranz.Commit;
          ReceptorDbase.Close;
        end;

      MNBTabla.Next;
    end;

  MnbTabla.Close;

  if not _hibas then
    begin
      ShowMessage('A BEÉRKEZETT ADATOK HIBÁTLANOK !');
      exit;
    end;

  // A hibák kijelzése:

  HibakDisplay.ShowModal;
end;

// ========================================================================
       function TForm1.BennvanMindenzaras(_napstr: string):boolean;
// ========================================================================

var _vanTabla: Boolean;
    _qnap: integer;

begin
  Result := False;
  _farok := midstr(_napstr,3,2)+midstr(_napstr,6,2);
  _fbkFile := 'DAYB'+_farok;
  _vanTabla := TablaExists('C:\receptor\database\Daybook.fdb',_fbkFile);

  // Ha egy üres új táblát kellett csinálni,akkor nincs mit nézni -> FALSE

  if not _vanTabla then exit;

  _farok := midstr(_napstr,3,2)+midstr(_napstr,6,2);
  _fbkFile := 'DAYB' + _farok;
  _qnap := strtoint(midstr(_napstr,9,2));
  _napMezo := 'N' + inttostr(_qNap);

  DayBookDbase.Close;
  DayBookDbase.Connected := True;
  with DayBookTabla do
    begin
      TableName := _fbkFile;
      Open;
      Refresh;
      First;
    end;

  while not DayBookTabla.Eof do
    begin
      _aktstatus := DayBookTabla.FieldByName(_napMezo).asString;
      if _aktstatus = '' then
        begin
          DaybookTabla.Close;
          Exit;
        end;
      DayBookTabla.Next;
    end;
  DayBookTabla.Close;
  Result := true;
end;



// ================================================================
       function TForm1.DayBookReader(_napstr: string):boolean;
// ================================================================

var _dbkFarok: string;
    _dbknap,z: integer;
begin

   Result := False;

  _dbkFarok := midstr(_napstr,3,2)+midstr(_napstr,6,2);
  _fbkFile := 'DAYB' + _dbkFarok;
  _dbknap := strtoint(midstr(_napstr,9,2));
  _napMezo := 'N' + inttostr(_dbkNap);

  DayBookDbase.Close;
  DayBookDbase.Connected := True;
  DayBookTabla.TableName := _fbkFile;

  if not DayBookTabla.Exists then exit;

  for z := 1 to 180 do _nstatus[z] := 'E';

  with DayBookTabla do
    begin
      Open;
      Refresh;
      First;
    end;

  while not DaybookTabla.Eof do
    begin
      _iroda := DayBookTabla.FieldByName('PENZTAR').asInteger;
      _napstatus := DayBookTabla.FieldByName(_napmezo).asString;
      _nStatus[_iroda] := _napStatus;
      DayBookTabla.Next;
    end;

  Result := True;
  DayBookTabla.close;
end;

// **--**--**--**--**--**--**--**--**--**--**--**--**--**--**--**--


// =============================================================
      function TForm1.Kieg(_mit:string;_hh:integer):string;
// =============================================================

begin
  while length(_mit)<_hh do _mit := _mit + chr(32);
  result := _mit;
end;

// ========================================================
      function TForm1.DecitoHexa(_deci: byte):string;
// ========================================================

var _dhi,_dlo: byte;

begin
  _dhi := trunc(_deci/16);
  _dlo := _deci-trunc(16*_dhi);
  if _dlo>9 then _dlo := _dlo + 7;
  if _dhi>9 then _dhi := _dhi + 7;
  result := chr(_dhi+48)+chr(_dlo+48);
end;

// ==========================================================
         function TForm1.Nulele(_szam: integer): string;
// ==========================================================

begin
  if _szam<10 then result := '0' + chr(48+_szam)
  else result := inttostr(_szam);
end;



// ==========================================================================
     function TForm1.TablaExists(_fdbpath: string; _tnev: string): boolean;
// ==========================================================================

begin
  Result := False;
  Ibdbase.Connected := False;
  IbDbase.DatabaseName := _fdbPath;
  IbDbase.Connected := True;
  IbTabla.Close;
  IbTabla.TableName := _tnev;
  if IBTabla.Exists then Result := True;
end;


function TForm1.Vanilyeniroda(_irszam: integer): boolean;

var j: integer;

begin
  result := false;
  for j := 0 to _irodaDarab-1 do
    begin
      if _irszam=_irodaszam[j] then
        begin
          result := true;
          Exit;
        end;
    end;
end;

function TForm1.DnemScan(_vn: string):integer;
var _y: integer;
begin
  Result := -1;
  for _y := 0 to 27 do
    begin
      if _vn = _dnem[_y] then
        begin
          Result := _y;
          Break;
        end;
    end;
end;

//=============================================================
      function TfORM1.ErtTarScan(_et: integer): integer;
// ============================================================

(* Visszaadja a paraméterben adott értéktár tömbbeli sorszámát *)

var j: integer;

begin
  result := -1;

  for j := 0 to 8 do
    begin
      if _korzetSzam[j] = _et then
        begin
          result := j;
          break;
        end;
    end;
end;

// ======================================================
     function TForm1.BankScan(_tpt: string):integer;
// ======================================================

var j: integer;
   _bj: string;
begin
  result := 0;
  for j := 1 to 9 do
    begin
      _bj := _bankjel[j];
      if _bj=_tpt then
        begin
          result := j;
          exit;
        end;
    end;
end;


function Tform1.VesszobolPont(_vst: string): string;

var y,_kod: integer;

begin
  result := '';
  if _vst='' then exit;
  for y := 1 to length(_vst) do
    begin
      _kod := ord(_vst[y]);
      if _kod=44 then _kod := 46;
      result := Result + chr(_kod);
    end;
end;

function TForm1.FtForm(_ft:real):string;

begin
  result := FormatFloat('### ### ###',_ft);
  while length(result)<11 do result := ' '+result;
end;


procedure TForm1.TextKiiro;

begin
  assignFile(_nyomtat,'LPT1');
  REWRITE(_nyomtat);
  assignFile(_olvas,'c:\receptor\text.txt');
  reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeLn(_nyomtat,_mondat);
    end;
  system.closeFile(_nyomtat);
  System.closeFile(_olvas);
end;

// =============================================================================
           function TForm1.GetCegbetuSorszam(_betu: string): integer;
// =============================================================================


begin
  result := 0;
  _betu := uppercase(_betu);
  if _betu='B' then exit;
  inc(result);
 
end;


// =============================================================================
                  function TFORM1.RealToStr(_rr: real): string;
// =============================================================================

var _pos: integer;

begin
  Result := '0';
  if _rr=0 then exit;

  Result := Floattostr(_rr);
  _pos := pos(chr(44),result);
  if _pos>0 then result[_pos] := chr(46);
end;

function TForm1.HDateToStr(_hdat: TDateTime): string;

var _hev,_hho,_hnp: word;

begin
  _hev := yearof(_hdat);
  _hho := monthof(_hdat);
  _hnp := dayof(_hdat);

  result := inttostr(_hev)+'.'+nulele(_hho)+'.'+nulele(_hnp);
end;

function TForm1.HstrToDate(_dst: string): TDateTime;

var _hevs,_hhos,_hnps: string;
    _hev,_hho,_hnp: word;

begin
  _hevs := leftstr(_dst,4);
  _hhos := midstr(_dst,6,2);
  _hnps := midstr(_dst,9,2);

  val(_hevs,_hev,_code);
  val(_hhos,_hho,_code);
  val(_hnps,_hnp,_code);

  result := encodedate(_hev,_hho,_hnp);
end;




end.



