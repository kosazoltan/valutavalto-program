unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, Buttons,
  ExtCtrls,wininet, strutils, dateutils;

type
  TGetArfolyam = class(TForm)

    IBQuery: TIBQuery;
    IBDbase: TIBDatabase;
    IBTranz: TIBTransaction;

    MemoTabla: TMemo;
    Label1: TLabel;
    Shape2: TShape;
    NoChangePanel: TPanel;
    Shape1: TShape;
    Label2: TLabel;
    Label3: TLabel;
    NochangeGomb: TBitBtn;
    ChangePanel: TPanel;
    changebox: TListBox;
    Shape3: TShape;
    Label4: TLabel;
    ChangeGomb: TBitBtn;
    InditoTimer: TTimer;
    KILEPO: TTimer;

    procedure FormActivate(Sender: TObject);
    procedure GetGepParameters;
    procedure InditoTimerTimer(Sender: TObject);


    procedure Aktarfolyambetoltes;
    procedure DataToKijelzo;

    function WCurateBeolvasas: boolean;
    function GetCurrate: string;
    procedure CrsTorlese;

    procedure FTPszerverbeBelep;
    procedure Changedisplay;
    procedure Nochangedisplay;
    procedure ArfolyamAdatrogzites;
    procedure ibParancs(_ukaz: string);
    procedure Listbeiras(_mondat: string);
    procedure MNBFrissites;
    function DnemDekod(_dkod:string):string;

    function Scandnem(_dn: String): byte;
    function IntegDek(_5betu:string): real;
    function dnemDekoder(_dns: string): string;



    function wCurateFeldolgozas: boolean;
    function Intdekodol(_bs: integer): real;

    function CtrlSummaControl: boolean;

    function Vaninternet: boolean;
    function ArfolyamValtozott: boolean;
    function RealToStr(_rr: real): string;
    function Kitkod(_kdatum: string):string;
    function Formaz(_r1,_r2: real): string;
    function HunDatetostr(_caldat: TDateTime): string;
    function Nulele(_b: byte): string;

    procedure NochangeGombClick(Sender: TObject);
    procedure CHANGEGOMBClick(Sender: TObject);
    function GetIdos: string;
    procedure KILEPOTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Getarfolyam: TGetarfolyam;

  _penztarszam,_arfid,_dnemdb: byte;
  _szorzo: word;

  _olddnem: array[1..28] of string;
  _oldDnemDarab: integer;
  _oldvetArf,_oldEladArf,_oldelszArf: array[1..28] of real;
  _ujVetArf,_ujEladArf,_ujElszarf   : array[1..28] of real;

  _chnglist  : string = 'c:\valuta\ratechng.txt';
  _currate   : string;
  _lastCr    : string;

// _arfolyamdir: string = '\TEMPARF';

  _arfolyamdir: string = '\ARFOLYAM';

  _valnemDarab: integer = 28;
  _valnem:array[1..28] of string = ('EUR','USD','GBP','CHF','AUD','CAD','DKK',
           'JPY','NOK','SEK','CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH',
           'RUB','EUA','TRY','CNY','BAM','THB','BRL','MXN','NZD','RCH');

   _hNet,_hFTP,_hSearch: HINTERNET;
   _findData: WIN32_FIND_DATA;

   _biniras: File of byte;


   _width,_height,_arfdnemdarab,_ptarszam: word;
   _gepfunkcio,_qq,_valutadarab,_sajcsoport: byte;
   _code: integer;

   _L1,_L2,_L3: INTEGER;
   _voltValtozas,_csakmnbletoltes,_sikeres,_openlist: boolean;


   _aktdnem,_pcs,_mnbPath,_kodstr,_kiterjesztes,_mamas,_mondat,_lognev: string;
   _mnbfile,_homepenztarszam,_changePath,_ujwpath,_logpath,_aktidos: string;

   _sorveg: string = chr(13)+chr(10);

   _ftpPassword : String  = 'klc+45%';
   _ftpPort     : Integer = 21100;
   _ftpPort2    : Integer = 21;

   _host        : String;  

   _userId      : String  = 'ebc-10%';

   _uvetarf,_bvetarf,_ueladarf,_beladarf: array[1..28] of real;
   _shkvetarf,_shkeladarf: array[1..28] of real;

   _bytetomb: array[1..4096] of byte;

   _Olvas: file of byte;
// _dllPara: integer =1;

  _dllPara: integer;

   _textiras,_txtolvas: textfile;


function arfolyamletoltes(_para: integer): integer; stdcall;
function arfolyamregiszter(_para: integer): integer; stdcall; external 'c:\valuta\bin\arfreg.dll' name 'arfolyamregiszter';
function fenyujsagfrissito: integer; stdcall; external 'c:\valuta\bin\fnyujsag.dll' name 'fenyujsagfrissito';
Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';


implementation

{$R *.dfm}

// =============================================================================
        function arfolyamletoltes(_para: integer): integer; stdcall;
// =============================================================================

begin
  Getarfolyam := TGetarfolyam.Create(Nil);
  _dllPara := _para;
  result := Getarfolyam.ShowModal;
  Getarfolyam.free;
end;

// =============================================================================
             procedure TGETARFOLYAM.FormActivate(Sender: TObject);
// =============================================================================

begin

  Kilepo.Enabled := false;
  logirorutin(pchar('Arfolyam lekérés indul'));

  // Eredmény-jelzõk ektüntetése:

  ChangePanel.Visible   := False;
  NochangePanel.Visible := False;

  // Kiteszi az ablakot a képernyõre:

  _width := screen.Monitors[0].Width;
  _height:= screen.Monitors[0].Height;

  Top := trunc((_height-313)/2);
  Left:= trunc((_width-401)/2);

  // A változás-listát és a z_curate.dat-ot elöször is kitörli:

  if FileExists(_chngList) then DeleteFile(_chngList);

  _mamas := Hundatetostr(date);
  GetGepParameters;  // gépfunkció és pénztárszám meghatározása

   // Kiolvassa a gépen levõ NR*.dat-t vagy NR0000000.dat nevét

  _currate := GetCurrate;
  _currate := uppercase(trim(_currate));

  // Ha kettõ a paraméter - akkor MNB letöltés

  _csakMnbLetoltes := False;
  if (_dllpara=2) then
    begin
      _csakmnbletoltes := True;
      _currate := 'NR000000.DAT';
    end;

  // A mai nap meghatározása:

  Inditotimer.Enabled := true;
end;



// =============================================================================
                   procedure TGetarfolyam.GetGepParameters;
// =============================================================================

//  A Gépfunkció és a pénztárszám beolvasása:

var _ptkods: string;

begin
  ibdbase.connected := true;
  with ibquery do
    begin
      Close;
      Sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _gepfunkcio := FieldByName('GEPFUNKCIO').asInteger;
      _host := trim(FieldByNAme('HOST').asString);
      Close;
      sql.clear;
      Sql.add('SELECT * FROM PENZTAR');
      Open;
      _ptkods := trim(FieldByName('PENZTARKOD').asstring);
      Close;
    end;
  ibdbase.close;
  val(_ptkods,_penztarszam,_code);
end;

// =============================================================================
                  function Tgetarfolyam.GetCurrate: string;
// =============================================================================

var _srec: Tsearchrec;
    _minta : string;

begin
  result := 'NR000000.DAT';
  exit;
  _minta := 'c:\valuta\arfolyam\NR*.dat';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then result := _srec.name;
  FindClose(_srec);
end;


// =============================================================================
           procedure TGetArfolyam.InditoTimerTimer(Sender: TObject);
// =============================================================================

begin

  // Itt indul a program:

  InditoTimer.Enabled := False;

   // Beolvassa a jelenlegi árfolyamokat a tömbökbe:
  // _olddnemdarab,_olddnem[],_oldvetarf[],_oldeladarf[],_oldelszArf[]

  if not Vaninternet then
    begin
      Showmessage('NINCS INTERNET - NEM TUDOK ÁRFOLYAMOT TÖLTENI !');
      logirorutin(pchar('--- Kilépek a getarf-ból.Nincs internet (2) ------'));
      Modalresult := 2;
      exit;
    end;

  Aktarfolyambetoltes;

  // Elsõ feladat: az internet ellenõrzése, illetve bekapcsolása:

  Memotabla.Lines.Add('Internet ellenõrzése ...');

   if not WCurateBeolvasas then
    begin
      Nochangedisplay;
      exit;
    end;

  if _csakMnbLetoltes then
    begin
      MnbFrissites;
      MemoTabla.lines.add('Az MNB árfolyamok sikeresen letöltve');
      Sleep(3500);
      logirorutin(pchar('--- Kilépek a getarf-ból.Sikeres MNB (1) ------'));
      ModalResult := 1;
      exit;
    end;

// ------------------------  Arfolyamok Frissitese ----------------------------

  if not wCurateFeldolgozas then   //  _elszamarf,_vetarf
    begin
      Memotabla.Lines.add('A letöltött árfolyamtábla érvénytelen !');
      Sleep(3500);
      logirorutin(pchar('--- Kilépek a getarf-ból.Érvénytelen tábla (2) ------'));
      ModalResult := 2;
      exit;
    end;

  // A régi és új árfolyamok összehasonlitása: EQU=true -> nincs változás

  _voltvaltozas := ArfolyamValtozott;

  // Rögzitjük az új(?) árfolyamokat:

  ArfolyamAdatrogzites;

  Datatokijelzo;
  if _voltvaltozas then
    begin
      arfolyamregiszter(2);
      fenyujsagfrissito;
      ChangeDisplay;
    end else NochangeDisplay;
end;


// =============================================================================
               procedure TGetarfolyam.Aktarfolyambetoltes;
// =============================================================================

var _cc: integer;
    _elszarf,_varf,_earf: REAL;

begin

  _pcs := 'SELECT * FROM ARFOLYAM'+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  ibdbase.Connected := True;
  with ibquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _cc := 0;
  while not Ibquery.eof do
    begin
      with Ibquery do
        begin
          _aktdnem := FieldByName('VALUTANEM').asString;
          _elszarf := FieldByName('ELSZAMOLASIARFOLYAM').asFloat;
          _vArf := Fieldbyname('VETELIARFOLYAM').asFloat;
          _eArf := FieldbyName('ELADASIARFOLYAM').asFloat;
        end;

      if _aktdnem='HUF' then
        begin
          IbQuery.next;
          Continue;
        end;

      inc(_cc);

      _oldDnem[_cc]    := _aktdnem;
      _oldVetArf[_cc]  := _vArf;
      _oldEladArf[_cc] := _eArf;
      _oldElszarf[_cc] := _elszarf;

      ibQuery.next;
    end;
  ibquery.close;
  ibdbase.close;

  _oldDnemDarab := _cc;
 
end;


// =============================================================================
                  procedure TGetarfolyam.ArfolyamAdatrogzites;
// =============================================================================

var _aktelszarf,_aktvetelarf,_akteladarf: real;
    _aktuvarf,_aktuearf,_aktbvarf,_aktbearf: real;
    _aktshkvarf,_aktshkearf: real;

begin
   _qq := 1;
   while _qq<=_dnemdb do
     begin
       _aktdnem     := _valnem[_qq];
       {
       if _aktdnem='HRK' then
         begin
           inc(_qq);
           continue;
         end;
       }
       _aktelszarf  := _ujelszarf[_qq];
       _aktvetelarf := _ujvetarf[_qq];
       _akteladarf  := _ujeladarf[_qq];
       _aktuvarf    := _uvetarf[_qq];
       _aktuearf    := _ueladarf[_qq];
       _aktbvarf    := _bvetarf[_qq];
       _aktbearf    := _beladarf[_qq];
       _aktshkvarf  := _shkvetarf[_qq];
       _aktshkearf  := _shkeladarf[_qq];

       if _gepfunkcio=1 then
         begin
           _pcs := 'UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM='+RealToStr(_aktelszarf)+',';
           _pcs := _pcs + 'VETELIARFOLYAM='+realtostr(_aktvetelarf)+',';
           _pcs := _pcs + 'ELADASIARFOLYAM='+ realtostr(_akteladarf)+',';
           _pcs := _pcs + 'K1VETEL='+RealToStr(_AKTUVARF)+',';
           _pcs := _pcs + 'K1ELADAS='+RealToStr(_aktuearf)+',';
           _pcs := _pcs + 'K2VETEL='+RealToStr(_aktbvarf)+',';
           _pcs := _pcs + 'K2ELADAS='+RealToStr(_aktbearf) + ',';
           _pcs := _pcs + 'SHKVETARFOLYAM='+RealToStr(_aktshkvarf)+',';
           _pcs := _pcs + 'SHKELADARFOLYAM='+RealToStr(_aktshkearf) + _sorveg;
         end else
         begin
           _pcs := 'UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM='+ realtostr(_aktelszarf)+_sorveg;
         end;

       _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+_aktdnem+chr(39);
       ibParancs(_pcs);

       inc(_qq);
     end;

  _pcs := 'UPDATE HARDWARE SET LIMIT1='+inttostr(_L1)+',';
  _pcs := _pcs + 'LIMIT2='+inttostr(_L2)+',';
  _pcs := _pcs + 'LIMIT3='+inttostr(_L3);

  ibParancs(_pcs);

 
  (*
  _sLimit[1] := _L1;
  _sLimit[2] := _L2;
  _sLimit[3] := _L3;

  dnemTolto;
  *)
end;


// =============================================================================
           function TGetarfolyam.Intdekodol(_bs: integer): real;
// =============================================================================

var _b1,_b2,_b3,_b4,_b5: byte;

begin
   _b1 := _bytetomb[_bs];
   _b2 := _bytetomb[_bs+1];
   _b3 := _bytetomb[_bs+2];
   _b4 := _bytetomb[_bs+3];
   _b5 := _bytetomb[_bs+4];

   result := _b5*65536*65536;
   result := result + (_b4*65536*256);
   result := result + (65536*_b3);
   result := result + (256*_b2);
   result := result + _b1;
end;

// =============================================================================
           function TGetarfolyam.dnemDekoder(_dns: string): string;
// =============================================================================


var _b1,_b2,_r1,_r2,_r3: byte;

begin
  _b1 := ord(_dns[1]);
  _b2 := ord(_dns[2]);
  _r1 := trunc(_b1/4);
  _r2 := trunc(_b1*64);
  _r2 := trunc(_r2/8)+trunc(_b2/32);
  _r3 := trunc(_b2*8);
  _r3 := trunc(_r3/8);
  result := chr(_r1+64)+chr(_r2+64)+chr(_r3+64);
end;

// =============================================================================
                  procedure Tgetarfolyam.MnbFrissites;
// =============================================================================

var
    _kodstr: string;
    i: integer;
    _elszamarfolyam: real;

begin
  if not fileexists(_mnbPath) then
    begin
      ShowMessage('NINCS A SZERVEREN MAI NAPI MNB ÁRFOLYAM RÖGZITVE');
      exit;
    end;

  AssignFile(_olvas,_mnbPath);  // arf100.ddd bedolgozása
  Reset(_olvas);
  BlockRead(_olvas,_byteTomb,1);
  _valutaDarab := _bytetomb[1];

  if _valutaDarab=0 then
    begin
      CloseFile(_olvas);
      DeleteFile(_mnbPath);
      ShowMessage('NINCSENEK ÁRFOLYAMOK AZ ADATOKBAN');
      Exit;
    end;

  ibDbase.Close;
  ibDbase.Connected := true;

  if ibTranz.InTransaction then ibTranz.Commit;
  ibTranz.StartTransaction;

  while true do
    begin
      BlockRead(_olvas,_byteTomb,2);
      if (_byteTomb[1]=255) and (_byteTomb[2]=255) then break;

      _kodstr := chr(_byteTomb[1])+chr(_byteTomb[2]);
      _aktdnem := dnemdekod(_kodstr);

      BlockRead(_olvas,_byteTomb,5);
      _kodstr := chr(_byTeTomb[1]);

      for i := 2 to 5 do  _kodStr := _kodstr + chr(_byteTomb[i]);
      _elszamarfolyam := integDek(_kodstr)/10000;

      _pcs := 'UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM='+RealToStr(_elszamarfolyam);
      _pcs := _pcs + ' WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);

      with ibQuery do
        begin
          Close;
          Sql.Clear;
          Sql.Add(_pcs);
          ExecSql;
        end;
    end;

  CloseFile(_olvas);

  ibTranz.Commit;
  ibDbase.Close;
end;





// =============================================================================
              function TGetarfolyam.wCurateBeolvasas: boolean;
// =============================================================================

// var _hiba: integer;

begin

  result := False;
  FTPSzerverbeBelep;
  if _hFTP=Nil then exit;

  // --------- Change directory -----------------

  MemoTabla.Lines.add('Belépek az árfolyam könyvtárban ...');
  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar(_arfolyamdir));
  if not _sikeres then
    begin
      Memotabla.Lines.add('Nem tudtam bellépni az árfolyam könyvtárba !');
      logirorutin(pchar('Nem tudok belepni az ARFOLYAM konyvtarba'));

      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  if _csakmnbLetoltes then
    begin
      _kiterjesztes := Kitkod(_mamas);
      _mnbFile := 'af100.' + _kiterjesztes;
      _mnbPath := 'c:\valuta\in\' + _mnbFile;
      if Fileexists(_mnbPath) then DeleteFile(_mnbPath);
      result := ftpgetfile(_hftp,pchar(_mnbFile),pchar(_mnbPath),False,
                                                0, FTP_TRANSFER_TYPE_BINARY, 0);
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;

  _hSearch := FTPFindFirstFile(_hFTP,'NR*.DAT',_findData,0,0);

  if _hsearch=NIL then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      logirorutin(pchar('Nem talaltam a szerveren arolyam file-t !'));
      exit;
    end;
  _Lastcr := _finddata.cFileName;
  InternetCloseHandle(_hsearch);

  _lastCr := uppercase(trim(_lastcr));
  logirorutin(pchar('A szerveren ' + _lastcr + ' nevu arfolyamfile-t talaltam'));

  if _lastcr=_currate then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;

  Crstorlese;

  _ujwPath := 'C:\VALUTA\ARFOLYAM\' + _lastCr;
      // Jöhet a download:

  _sikeres := ftpgetfile(_hftp,pchar(_lastCr),pchar(_ujwPath),False,0,FTP_TRANSFER_TYPE_BINARY,0);
  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  {
  if _sikeres then
    begin
      if not CtrlSummaControl then
         begin
           if FileExists(_ujWpath) then DeleteFile(_ujwPath);
           exit;
         end;
    end else
   }

   if not _sikeres then
     begin
      logirorutin(pchar('Nem sikerult letoltenem az arfolyamfile-t a szerverrol'));
  //    _hiba := GetLastError();
      exit;
    end;

  Result := true;
end;

// =============================================================================
                      procedure TGetarfolyam.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := Nil;

  MemoTabla.Lines.Add('Fellépek az internetre ...');
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then
    begin
      MemoTabla.Lines.Add('Nem tudok fellépni az internetre !');
      Exit;
    end;

   MemoTabla.Lines.add('Belépek a központi szerverre ...');

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------


  if _hFTP=nil then
    begin
      ShowMessage('A központi szerver nem érhetõ el !');
      InternetCloseHandle(_hNet);
    end;
end;

// =============================================================================
                 function TGetArfolyam.CtrlSummaControl: boolean;
// =============================================================================

var _sByte,_fhossz: integer;

begin
  Result := False;
  if not FileExists(_ujwPath) then exit;

  AssignFile(_olvas,_ujwPath);
  Reset(_olvas);

  _fHossz := FileSize(_olvas);
  logirorutin(pchar('Filehossza: '+ inttostr(_fHossz)));

  {
  if _fhossz<>66138 then
    begin
      CloseFile(_olvas);
      exit;
    end;
  }

  logirorutin(pchar('Pozició az utolsó 3 bytera'));
  Seek(_olvas,(_fhossz-3));

  logirorutin(pchar('Kiolvasom a ctrl byte-okat'));
  BlockRead(_olvas,_bytetomb,3);
  CloseFile(_olvas);

  _sByte := _bytetomb[1]+_bytetomb[2]+_bytetomb[3];
  if _sByte=765 then Result := true;
end;

// =============================================================================
               function TGetArfolyam.wCurateFeldolgozas: boolean;
// =============================================================================

var _kezdet,_fhossz: integer;

begin

  result := False;
  if not FileExists(_UJwPath) then exit;

  Assignfile(_olvas,_ujwPath);
  Reset(_olvas);

  Blockread(_olvas,_bytetomb,1);  // verzió száma  = 15
  _arfid :=  _bytetomb[1];
  if _arfid=15 then
    begin
      _dnemdb := 27;
      _szorzo := 1221;
    end;

  if _arfid=16 then
    begin
      _dnemdb := 28;
      _szorzo := 1266;
    end;

  Blockread(_olvas,_bytetomb,200);
  if _penztarszam=0 then
     begin
       Closefile(_olvas);
       Showmessage('Hibás pénztárszam !');
       Exit;
     end;

   if _gepfunkcio=1 then _sajcsoport := _bytetomb[_penztarszam]
   else _sajcsoport := 3;

   if (_sajcsoport<1) or (_sajcsoport>54) then
     begin
       CloseFile(_olvas);
       ShowMessage('Hibás csoportkód az árfolyamtáblában !');
       Exit;
     end;

   _kezdet := 201+trunc((_sajcsoport-1)*_szorzo);
   reset(_olvas);

   _fhossz := Filesize(_olvas);
   if _kezdet>_fhossz then
     begin
       CloseFile(_olvas);
       ShowMessage('Hibás a letöltött árfolyam táblázat !');
       exit;
     end;

   seek(_olvas,_kezdet);
   _qq := 1;

   while _qq<=_dnemdb do
     begin
       Blockread(_olvas,_bytetomb,45);

       _ujelszarf[_qq]   := intdekodol(1);
       _ujvetarf[_qq]    := intdekodol(6);
       _ujeladarf[_qq]   := intdekodol(11);
       _uvetarf[_qq]     := intdekodol(16);
       _ueladarf[_qq]    := intdekodol(21);
       _bvetarf[_qq]     := intdekodol(26);
       _beladarf[_qq]    := intdekodol(31);
       _shkvetarf[_qq]   := intdekodol(36);
       _shkeladarf[_qq]  := intdekodol(41);

       {
       if _valnem[_qq]='JPY' then
         begin
           _ujelszarf[_qq]  := _ujelszarf[_qq]/10;
           _ujvetarf[_qq]   := _ujvetarf[_qq]/10;
           _ujeladarf[_qq]  := _ujeladarf[_qq]/10;
           _uvetarf[_qq]    := _uvetarf[_qq]/10;
           _ueladarf[_qq]   := _ueladarf[_qq]/10;
           _bvetarf[_qq]    := _bvetarf[_qq]/10;
           _beladarf[_qq]   := _beladarf[_qq]/10;
           _shkvetarf[_qq]  := _shkvetarf[_qq]/10;
           _shkeladarf[_qq] := _shkeladarf[_qq]/10;
         end;
       }

       inc(_qq);
     end;

   Blockread(_olvas,_bytetomb,6);
   closeFile(_olvas);

   _L1 := _bytetomb[1] + trunc(256*_bytetomb[2]);
   _L2 := _bytetomb[3] + trunc(256*_bytetomb[4]);
   _L3 := _bytetomb[5] + trunc(256*_bytetomb[6]);

   _L1 := trunc(1000*_L1);
   _L2 := trunc(1000*_L2);
   _L3 := trunc(1000*_L3);

   result := true;
end;

// =============================================================================
                 function Tgetarfolyam.ArfolyamValtozott: boolean;
// =============================================================================

var _ujss: byte;
     _sor: string;
     _ovarf,_oearf,_ujVarf,_ujEarf: real;

begin
  result := False;
  _aktidos := GetIdos;

  {
  assignfile(_logiro,_logpath);
  Append(_logiro);
  writeln(_logiro,'Arfolyamok összehasonlitasa:');
  }

  _openlist := False;
  _qq := 1;

  while _qq<= _OldDnemDarab do
    begin
      _aktdnem := _oldDnem[_qq];
      _ujss := Scandnem(_aktdnem);
      if _ujss>0 then
        begin
          _ovarf := _oldvetArf[_qq];
          _oearf := _oldEladArf[_qq];

          _ujVarf := _ujvetarf[_ujss];
          _ujEarf := _ujeladarf[_ujss];

          _mondat := ' - '+_aktdnem +': ' + floattostr(_ovarf)+' -> '+floattostr(_ujvarf)+chr(9)+' es ';
          _mondat := _mondat + floattostr(_oearf)+' -> '+floattostr(_ujearf);

          if (_ovarf<>_ujvarf) or (_oearf<>_ujearf) then
            begin
              result := True;
              _sor := _aktdnem+' új árfolyama = ' + formaz(_ujvarf,_ujearf);
              Listbeiras(_sor);
            end;

        end;
      inc(_qq);
    end;
  if _openList then Closefile(_textIras);

end;


// =============================================================================
            procedure TGetarfolyam.Listbeiras(_mondat: string);
// =============================================================================


begin
  if not _openList then
    begin
      AssignFile(_textiras,_chnglist);
      Rewrite(_textiras);
      _openList := True;
    end;
  writeLn(_textiras,_mondat);
end;

// =============================================================================
          function TGetarfolyam.Formaz(_r1,_r2: real): string;
// =============================================================================


begin
  result := floattostr(_r1)+'/'+floattostr(_r2);
end;

// =============================================================================
          function TGetarfolyam.Scandnem(_dn: String): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=_dnemdb do
    begin
      if _valnem[_y]=_dn then
        begin
          result := _y;
          break;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                  function TGetarfolyam.RealToStr(_rr: real): string;
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
                   procedure Tgetarfolyam.Nochangedisplay;
// =============================================================================

begin
  with NoChangePanel do
    begin
      Top := 64;
      Left := 16;
      Visible := True;
      Repaint;
    end;
  logirorutin(pchar('Nem volt arfolyamvaltozas'));
  Kilepo.Enabled := true;
  Activecontrol := NochangeGomb;
end;

// =============================================================================
                    procedure Tgetarfolyam.Changedisplay;
// =============================================================================

begin
  ChangeBox.Items.Clear;
  Changebox.Items.add('      AZ ÚJ ÁRFOLYAMOK:');
  ChangeBox.Items.Add('  ');

  Assignfile(_txtolvas,_chnglist);
  Reset(_txtolvas);
  while not eof(_txtolvas) do
    begin
      readln(_txtolvas,_mondat);
      ChangeBox.Items.add(_mondat);
    end;
  Closefile(_txtOlvas);
  Changebox.Repaint;

  with ChangePanel do
    begin
      Top := 16;
      Left := 16;
      Visible := true;
      Repaint;
    end;
  logirorutin(pchar('Az arfolyamok megvaltoztak !'));

  _pcs := 'UPDATE HARDWARE SET KEZIARFOLYAM=0';
  iBPARANCS(_PCS);

  ActiveControl := ChangeGomb;
end;

// =============================================================================
             procedure TGETARFOLYAM.NochangeGombClick(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  Modalresult := 3;
end;

// =============================================================================
             procedure TGETARFOLYAM.CHANGEGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;




// =============================================================================
                 function TGetarfolyam.Vaninternet: boolean;
// =============================================================================

var
    _dwConnType: integer;

begin
   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := true;
   except
   end;
end;

// =============================================================================
                   procedure Tgetarfolyam.ibParancs(_ukaz: string);
// =============================================================================

begin
  ibdbase.connected := true;
  if ibtranz.InTransaction then ibtranz.commit;
  ibtranz.StartTransaction;
  with ibquery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      ExecSql;
    end;

  ibtranz.commit;
  ibdbase.close;
end;

// =============================================================================
                function TGetarfolyam.Kitkod(_kdatum: string):string;
// =============================================================================

var _hos,_naps,_evs: string;
    _ev,_honap,_nap: word;

begin
   result := '000';
   if _kdatum='' then exit;

   _evs := leftstr(_kdatum,4);
   _hos := midstr(_kdatum,6,2);
   _naps:= midstr(_kdatum,9,2);

   val(_evs,_ev,_code);
   if _code<>0 then _ev := 0;

   val(_hos,_honap,_code);
   if _code<>0 then _honap := 0;

   val(_naps,_nap,_code);
   if _code<>0 then _ev := 0;

   if (_ev<2000) or (_ev>2036) then exit;

   _ev := _ev - 2000;
   _hos := chr(64+trunc(2*_honap));

   if _nap<10 then _naps := chr(48+_nap)
   else _naps := chr(55+_nap);

   _evs := chr(64+_ev);
   result := _naps + _evs + _hos;
end;


// =============================================================================
           function TGetarfolyam.IntegDek(_5betu:string): real;
// =============================================================================

var _a1,_a2,_a3,_a4,_a5,_negativ: integer;
    _r0,_r1,_r2,_r3,_r4,_big: real;

begin
  result := 0;

  if _5betu='' then exit;
  _a1 := ord(_5betu[1]);
  _a2 := ord(_5betu[2]);
  _a3 := ord(_5betu[3]);
  _a4 := ord(_5betu[4]);
  _a5 := ord(_5betu[5]);
  _negativ := 0;

  if _a1>127 then
    begin
      _a1 := _a1 - 128;
      _negativ := 1;
    end;
  _big := sqr(65536);
  _r0 := (1.00*_a5);
  _r1 := 256*_a4;
  _r2 := 65536*_a3;
  _r3 := 256*65536*_a2;
  _r4 := _big*_a1;

  result := _r0+_r1+_r2+_r3+_r4;

  if _negativ>0 then result := result*(-1);
end;


// =============================================================================
           function TGetarfolyam.DnemDekod(_dkod:string):string;
// =============================================================================

var _a1,_a2,_x1,_x2,_x3: integer;

begin
  result := '';
  if _dkod='' then exit;
  _a1 := ord(_dkod[1]);    //  2
  _a2 := ord(_dkod[2]);    //  131

  _x1 := trunc(_a1/4);
  _x2 := trunc((_a1 and 3) * 8) + trunc(_a2/32);
  _x3 := (_a2 and 31);

  result := chr(_x1+65)+chr(_x2+65)+chr(_x3+65);
end;


// =============================================================================
                     procedure TGetarfolyam.DataToKijelzo;
// =============================================================================

var _targetpath,_foglalt,_changePath: string;
    _aktvetelarf,_akteladarf: real;
    _vlo,_vhi,_ehi,_elo: byte;

begin
  _targetpath := 'c:\valuta\DISPDATA.DAT';
  _changePath := 'c:\valuta\CHANGE.SIG';

  _foglalt := 'c:\valuta\FOGL.ALT';
  _bytetomb[1] := 255;

  assignfile(_biniras,_foglalt);
  rewrite(_BINIRAS);
  blockwrite(_biniras,_bytetomb,1);
  Closefile(_biniras);

  if fileexists(_targetPath) then sysutils.DeleteFile(_targetpath);

  Assignfile(_biniras,_targetPath);
  rewrite(_biniras);

  _qq := 1;
  while _qq<=_dnemdb do
    begin
      _aktdnem     := _valnem[_qq];
      _aktvetelarf := _ujvetarf[_qq];
      _akteladarf  := _ujeladarf[_qq];

      {
      if _aktdnem='JPY' then
        begin
          _aktvetelarf := 10*_aktvetelarf;
          _akteladarf  := 10*_akteladarf;
        end;

       }
      _bytetomb[1] := ord(_aktdnem[1]);
      _bytetomb[2] := ord(_aktdnem[2]);
      _bytetomb[3] := ord(_aktdnem[3]);

      _vhi := trunc(_aktvetelarf/256);
      _vlo := trunc(_aktvetelarf - (256*_vhi));

      _ehi := trunc(_akteladarf/256);
      _elo := trunc(_akteladarf - (256*_ehi));

      _bytetomb[4] := _vlo;
      _bytetomb[5] := _vhi;

      _bytetomb[6] := _elo;
      _bytetomb[7] := _ehi;

      Blockwrite(_biniras,_bytetomb,7);
      inc(_qq);
    end;

  _bytetomb[1] := 255;

  Blockwrite(_biniras,_bytetomb,1);
  closefile(_biniras);

  Assignfile(_biniras,_changepath);
  rewrite(_biniras);

  Blockwrite(_biniras,_bytetomb,1);
  CloseFile(_biniras);

  Sysutils.DeleteFile(_foglalt);
end;




procedure TGetarfolyam.crsTorlese;

var _minta,_delFile,_delPath: string;
    _srec: TSearchRec;

begin
  _minta := 'C:\VALUTA\ARFOLYAM\NR*.DAT';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        _delFile := _srec.Name;
        _delPath := 'c:\valuta\arfolyam\'+_delfile;
        deleteFile(_delPath);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
end;

function TGetarfolyam.HunDatetostr(_caldat: TDatetime): string;

var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;


function TGetarfolyam.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


function Tgetarfolyam.GetIdos: string;

begin
  result := timetostr(TIme)+': ';
  if midstr(result,2,1)=':' then result := '0'+result;
end;


procedure TGetArfolyam.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  Modalresult := 3;
end;

end.
