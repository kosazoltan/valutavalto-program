unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls,
  Buttons, StrUtils, IBTable, DateUtils, ComCtrls, wininet, shellapi, jpeg,
  printers;

type
  TForm1 = class(TForm)

    Shape1         : TShape;
    Shape2         : TShape;
    Shape3         : TShape;
    Shape4         : TShape;

    Label3         : TLabel;
    Label4         : TLabel;
    Label2         : TLabel;

    KilepesGomb    : TBitBtn;
    ListaGomb      : TBitbtn;
    MatricaGomb    : TBitbtn;
    TelefonGomb    : TBitBtn;
    TanusitvanyGomb: TBitBtn;
    LOGOLVASOGOMB  : TBitBtn;

    TradeQuery     : TIBQuery;
    TradeDbase     : TIBDatabase;
    TradeTranz     : TIBTransaction;
    TradeTabla     : TIBTable;

    ValutaQuery    : TIBQuery;
    ValutaDbase    : TIBDatabase;
    ValutaTranz    : TIBTransaction;

    KilepoTimer    : TTimer;
    Indito         : TTimer;

    Fuggony        : TPanel;
    KftNevPanel    : TPanel;

    Csik           : TProgressBar;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    REMOTEQUERY: TIBQuery;
    REMOTEDBASE: TIBDatabase;
    REMOTETRANZ: TIBTransaction;
    ARHIVPANEL: TPanel;

    procedure AfasSzamla;
    procedure AlapadatBeolvasas;
    procedure Archivalo;
    procedure BlokkFocimIro;
    procedure BlokkNyitas;
    procedure CikktorzsBeolvasas;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure HardKozepreir(_ms: string);
    procedure HaviTradeControl;
    procedure InditoTimer(Sender: TObject);
    procedure KilepesGombClick(Sender: TObject);
    procedure KilepoTimerTimer(Sender: TObject);
    procedure Konyveles(_tp: string);
    procedure Kozepreir(_ms: string);
    procedure ListaGombClick(sender: TObject);
    procedure Logbair(_mondat: string);
    procedure LogOlvasoGombClick(Sender: TObject);
    procedure MakeTradeTabla;
    procedure MatricaSellerCopy;
    procedure MatricaCustomerCopy;
    procedure MatricaGombClick(Sender: TObject);
    procedure SetLogFile;
    procedure StartNyomtatas;
    procedure TelefonBlokk;
    procedure TelefonGombClick(Sender: TObject);
    procedure TelefonGombEnter(Sender: TObject);
    procedure TelefonGombExit(Sender: TObject);
    procedure TelefonGombMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TextKiiro;
    procedure TelAfasSzamla;
    procedure TelenorBizonylat;
    procedure TRadeParancs(_ukaz: string);
    procedure TanusitvanyGombClick(Sender: TObject);
    procedure TMobilBizonylat;
    procedure TComBizonylat;
    procedure ValutaParancs(_ukaz: string);
    procedure VodaBizonylat;
    procedure WideKozepreir(_ms: string);

    function CsomagKuldes: boolean;
    function FtForm(_ar: integer):string;
    function Getidos:string;
    function Getmezo(_mezonev: string): string;
    function GetUtBizonylat: integer;
    function HatNulele(_nn: integer):string;
    function Hundatetostr(_caldat: TDateTime): string;
    function Kodxor(_s: string): string;
    function Nulele(_nn: integer): string;
    function Vaninternet: boolean;
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1            : TForm1;

  _host            : string = '185.43.207.99';
  _ftpPort         : integer = 21100;
  _userid          : string = 'ebc-10%';
  _ftpPassword     : string = 'klc+45%';

  _requestPath     : string = 'c:\valuta\temp\request.xml';
  _replyPath       : string = 'c:\valuta\temp\REPLY.XML';
  _javaprog        : string = 'c:\valuta\bin\Coupon.exe';
  _tradeLogDir     : string = 'C:\VALUTA\TRADELOG';
  _ipcim           : string ='193.68.57.146';    // új ip-cim
  _url             : string = 'https://193.68.57.146/kupon/as.php';
  _sorveg          : string = chr(13) + chr(10);

  _cikkar          : array[1..999] of integer;     // a cikkek árai
  _cikknev         : array[1..999] of string;      // a cikkek nevei
  _tFirm           : array[1..6] of string = ('T-Mobile','Telenor','Vodafone','T-Com',
                                        'NeoPhone','Tesco');

  _reqrow,_reprow  : array[1..255] of string;
  _bytetomb        : array[1..1024] of byte;
  _hmFt,_hTft,_hFFt: array[1..200] of integer;

  _hevh            : array[1..200] of string;
  _printer         : byte;

  _mobilcikk : array[1..7,1..6] of integer;

  _FB        : array[1..7] of TBitbtn;
  _foreNumber: array[0..7] of Integer = (0,3,2,7,0,0,0,3);
  _ft        : array[1..6] of TPanel;
  _logos     : array[1..7] of TImage;
  _logoshapes: array[1..7] of TShape;

  _phNumPanel: array[1..14] of TPanel;
  _qhNumPanel: array[1..20] of Tpanel;
  _phNumShape: array[1..14] of TShape;
  _qhNumshape: array[1..20] of Tshape;
  _sh        : array[1..7]  of tshape;
  _csh       : array[1..6]  of TShape;

  _ctAzonosito,_ctEgysegar: array[1..1024] of integer;
  _ctCikknev,_ctOperator: array[1..1024] of string;
  _ctDarab: word;

  _megyenev:array[0..18] of string =('BÁCS-KISKUN',           // 1
                                  'BARANYA',                  // 2
                                  'BÉKÉS',                    // 3
                                  'BORSOD-ABAÚJ-ZEMPLÉN',     // 4
                                  'CSONGRÁD',                 // 5
                                  'FEJÉR',                    // 6
                                  'GYÖR-MOSON-SOPRON',        // 7
                                  'HAJDÚ-BIHAR',              // 8
                                  'HEVES',                    // 9

                                  'JÁSZ-NAGYKUN-SZOLNOK',     // 10

                                  'KOMÁROM-ESZTERGOM',        // 11
                                  'NOGRÁD',                   // 12
                                  'PEST',                     // 13
                                  'SOMOGY',                   // 14
                                  'SZABOLCS-SZATMÁR-BEREG',   // 15

                                  'TOLNA',                    // 16
                                  'VAS',                      // 17
                                  'VESZPRÉM',                 // 18
                                  'ZALA');                    // 19


  // --------------------------------------------------------------------------

  _honev: array[1..12] of string = ('JANUAR','FEBRUAR','MARCIUS','APRILIS','MAJUS',
         'JUNIUS','JULIUS','AUGUSZTUS','SZEPTEMBER','OKTOBER','NOVEMBER','DECEMBER');

  _napnev: array[1..7] of string = ('HETFO','KEDD','SZERDA','CSUTORTOK','PENTEK',
                                                'SZOMBAT','VASARNAP');
  _asc,_wm,_p,_TComTip,_counter             : Byte;
  _reppieces,_reqPieces,_rowss,_z           : word;
  _filehossz                                : integer;

  _aktreprow,_aktreqrow                     : string;
  _sOke,_sikeres,_ezMegye,_megvan,_kellafas : boolean;
  _vegjel,_ezPaysafeCard,_kapcsolva         : boolean;

  _LFile,_logiro,_iras,_olvas,_textIras     : TextFile;
  _binOlvas                                 : File of byte;

  _tipus          : string;                // M= matrica, T= telefon

  _kemeny : string = chr(27)+chr(71);
  _puha   : string = chr(27)+chr(72);

  _sendOke: cardinal;
  _pacs: pchar;
  _top,_left,_height,_width,_proskod,_code,_prosOke,_recno,_frt: integer;
  _cikkszam,_mResult,_meret,_fizetendo,_megyess,_forint,_sumFel: integer;
  tranzakcioOke,_countryCode,_psOsszeg,_utbizonylat,_tanOke    : integer;
  _lastMatrica,_lastTelefon,_lastUgyfel,_ugyfelszam,_kftlen    : integer;
  _sumHo,_snEv,_snHo,_snsumHo,_sumTel,_sumMat,_sumVod,_sumNor  : integer;
  _tranzakcioOke,_decfogyar,_elesitve,_egysar,_ujegysar: integer;

  _kapcsolatmod,_kapcsolatnev,_felhasznalonev,_ijelszo,_modosido: string;
  _hibaUzenet,_VFD,_pcs,_prosnev,_prosjelszo,_httpTipus        : string;
  _homePenztarszam,_homePenztarnev,_status,_bizonylatszam      : string;
  _Tranzakcio,_replyFile,_rendszam,_rrendszam,_kategoriastr    : string;
  _rcikkszams,_rFizetendos,_rOrszagnev,_aktdatumido,_aktmondat : string;
  _startDatIDo,_endDatIdo,_countryName,_referenceid,_akcio     : string;
  _telefonszam,_szolgaltato,_szolgaltatas,_mamas,_idos         : string;
  _sors,_elesitesideje,_xrdurHun,_xrdureng,_aktcikknev         : string;
  _akthonap,_uthonap: string;

  // ----- Topup reply értékek ------------------------

  _xrStatusId,_xrStatusDescription,_xrMessageType,_adoszam     : string;
  _xrAmount,_xrPhoneNumber,_xrTransactionId,_datum,_sDatum     : string;
  _xrTransactionDate,_xrOutletAddress,_xrProductId             : string;
  _xrOutletTaxNo,_xrProductName,_xrOperatorId,_username        : string;
  _xrOutletName,_xrReceiptNumber,_xrCategory,_farok            : string;
  _xrDurationHUN,_xrDurationEng                                : string;
  _xrRegistrationNumber,_xrVFD,_xrVTD,_tablanev,_startperc     : string;
  _xrCountryName,_xrReferenceId,_penztarosnev,_cegnev          : string;
  _homePenztarcim,_startdatums,_endDatums,_aktmegyenev,_tsz    : string;
  _ugyfelnev,_ugyfelcim,_aktmatricanev,_password,_elesEvtizeds : string;
  _terminalid,_lastday,_felirat,_logfile,_logPath ,_ugyfadoszam: string;

  _startev,_startho,_startnap,_starthnap,_penztarszam,_endcszam: word;
  _endev,_endho,_endNap,_endhnap,_decsorszam,_startcsz         : word;
  _aktcsz,_ocszam,_aktev,_aktho,_aktnap                        : word;

  _startDatum,_endDatum: TDateTime;

  // --------------------------------------------------------------------------

function supervisorjelszo(_para: integer): integer; stdcall; external 'c:\valuta\bin\Super.dll' name 'supervisorjelszo';
function matricaregeneralo: integer; stdcall; external 'c:\valuta\bin\Matregen.dll' name 'matricaregeneralo';


implementation

uses Unit2, Unit3, Unit5,  Unit10, Unit11, Unit9, Unit8, Unit13;

{$R *.dfm}

// =============================================================================
                      procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin

  // Alap beállítások és nullázások:

  _username   := '';
  _terminalid := '';
  _password   := '';

  _top    := 0;
  _left   := 0;

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  if _height>768 then _top := trunc((_height-768)/2);
  if _width>1024 then _left := trunc((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  height := 768;
  Width  := 1024;

  _aktev := yearof(date);
  _aktho := monthof(date);
  _aktnap := dayof(date);

  with Fuggony do
    begin
      left    := 8;
      top     := 8;
      Visible := True;
      repaint;
    end;

//  SetWindowPos(Form1.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);

  _kellafas := False;

  _mamas := HunDateTostr(date);
  Indito.Enabled := True;
end;

// =============================================================================
                procedure TForm1.InditoTimer(Sender: TObject);
// =============================================================================

begin

  // Itt indul a program
  // Beolvassa: Kftnév, Pénztárnév, pénztárszám,utolsó ügyfél számát
  // az utolsó telefon és matrica bizonylatszámokat,
  // a terminalid, username és password értékét
  // Kiszámítja: az adószámot és cégnevet
  // Betölti a Cikktorzs adatait = cikkszam[], cikknev[] tömböket

  Indito.Enabled := False;
  Archivalo;

// Ha nincs internet, akkor nem lehet dolgozni:

  if not Vaninternet then
    begin
      ShowMessage('NINCS INTERNET !');
      Application.Terminate;
      exit;
    end;

  AlapadatBeolvasas;

  // Ellenörzi, hogy van-e havi TRADEyymm tábla - ha nincs csinál
  HaviTradeControl;

  // Elõkésziti a log-file-t használatra
  SetLogFile;

  // ---------------------------------------------------------------------------

  // Külsõ dll regenerálja a mai összesítõ táblákat

  matricaregeneralo;

  // ---------------------------------------------------------------------------
  // Ha a terminalid nem 4 betübõl áll, akkor nincs kitöltve a tanusitvány:

  if length(_terminalid)<>4 then
    begin
       Logbair('Nincsenek kitöltve a tanusitvány adatai');

       _tanOke := GetTanusitvany.showmodal;
       if _tanOke<>1 then
         begin
           Logbair('Nem töltötte ki a tanusitványt - kilépek a programból');
           Application.Terminate;
           Exit;
         end;
       Logbair('Rendben kitöltötte a tanusitványt');
    end;

  // ----------------------------------------------------------------------

  KftnevPanel.Caption := _cegnev;
  KftnevPanel.repaint;

  // -----------Pénztáros belépése, jelszóval ----------------------------------

  Logbair('Most belép a pénztáros');

  _prosoke := GetPenztaros.ShowModal;
  // _proskod,_prosnev beolvasása, jelszó ellenõrzése:

  if _prosoke<>1 then
    begin
      // Nem tudta a jelszavát:

      Kilepotimer.enabled := true;
      Exit;
    end;

  CikktorzsBeolvasas;
  Fuggony.Visible := False;
end;

// ============================================================================
               procedure TForm1.TelefonGombEnter(Sender: TObject);
// ============================================================================

begin
  TBitbtn(sender).Font.Style := [fsBold,fsItalic];
end;

// ============================================================================
              procedure TForm1.TelefonGombExit(Sender: TObject);
// ============================================================================

begin
  TBitbtn(sender).Font.Style := [fsItalic];
end;

// =============================================================================
     procedure TForm1.TELEFONGOMBMouseMove(Sender: TObject; Shift: TShiftState;
                                                          X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitbtn(sender);
end;

// =============================================================================
                   function TForm1.FtForm(_ar: integer):string;
// =============================================================================

var _lenars: integer;

begin

  result  := inttostr(_ar);
  _lenars := length(result);

  case _lenars of
    4: result := leftstr(result,1)+'.'+midstr(result,2,3);
    5: result := leftstr(result,2)+'.'+midstr(result,3,3);
    6: result := leftstr(result,3)+'.'+midstr(result,4,3);
    7: result := leftstr(result,1)+'.'+midstr(result,2,3)+'.'+midstr(result,5,3);
  end;

  result := result + ' Ft';
end;

// =============================================================================
                    procedure TForm1.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := False;
  Application.terminate;
end;

// =============================================================================
                function TForm1.Getmezo(_mezonev: string): string;
// =============================================================================

// Chartömb pufferbõl visszaadja a parameter nevü mezö értékét:

var _wHossz: integer;
    _aktmezo: string;

begin
  result := '';
  _whossz := length(_mezonev);
  _z := 1;

  while _z<=_reppieces do
    begin
      _aktreprow := _reprow[_z];
      _aktMezo := midstr(_aktreprow,2,_whossz);
      if _aktmezo=_mezonev then
        begin
          _p := 3+_whossz;
          while _p<200 do
            begin
              _asc := ord(_aktreprow[_p]);
              if _asc=60 then exit;
              result := result + chr(_asc);
              inc(_p);
            end;
          exit;
        end;
      inc(_z);
    end;
end;


// =============================================================================
                      procedure TForm1.KilepesGombClick(Sender: TObject);
// =============================================================================

begin
  Logbair('Kilépés menüpontra klikkelt');
  matricaregeneralo;
  Kilepotimer.enabled := true;
end;

// ============================================================================
                  procedure TForm1.BlokkFocimIro ;
// ============================================================================

// Blokknyomtatás fejléce

begin
  writeLn(_LFile,' Kupon Portfolio es Kereskedelmi Kft.');
  writeLN(_LFile,'      2161 Csomad, Liget utca 40.');
  writeLn(_LFile,'             12896127-2-44');
  writeln(_LFile,' ');

  if _penztarszam<151 then
    begin
      wideKozepreir('EXCLUSIVE BEST');
      wideKozepreir('CHANGE ZRT.');
    end else
    begin
      wideKozepreir('EXPRESSZ EKSZERHAZ');
      wideKozepreir('ES MINIBANK KFT');
    End;

  writeln(_LFile,' ');

  kozepreir(_homePenztarNev);
  Kozepreir(_homePenztarCim);

  writeLn(_LFile,' ');
  writeLn(_lFile,'     Adoszam       : ' + _adoszam);
  WriteLn(_LFile,'     Terminál ID   : '+_terminalId);
  writeLn(_LFile,'     Bizonylatszam : '+ _bizonylatszam);
  writeln(_LFile,' ');

  Kozepreir('NUSZ call center: +36 1-587-500');
  writeln(_LFile,' ');
end;

// =============================================================================
                        procedure TForm1.Blokknyitas;
// =============================================================================

var _filenev: string;

begin
  _filenev := 'aktlst.txt';
  assignFile(_LFile,'C:\valuta\'+_filenev);
  Rewrite(_LFile);
  write(_LFile,#27#64);
end;

// ============================================================================
                       procedure TForm1.StartNyomtatas;
// ============================================================================

begin
  Writeln(_LFile,#27#97#5);
  WriteLn(_LFile,chr(26));
  CloseFile(_LFile);

 ////////////EXIT;  ///// TESZT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  TextKiiro;
end;

// ============================================================================
                        procedure TForm1.TextKiiro;
// ============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin
 ///// exit;  //////teszt !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  IF _PRINTER<>1 THEN
    AssignFile(_nyomtat,'LPT1')
  else
    AssignPrn(_nyomtat);

  Rewrite(_nyomtat);
  AssignFile(_olvas,'c:\valuta\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;

// =============================================================================
                        procedure TForm1.TelefonBlokk;
// =============================================================================

begin

  {
   ==============================================
   SZOLGÁLTATÓ            TIPUS  LOSS   _TCOMTIP
   =============================================
   T-mobile ...........    'T'    1         -
   Telenor  ...........    'N'    2         -
   Vodafone ...........    'V'    3         -
   T-Com control ......    'T'    4         1
   T-com barangolo ....    'T'    4         2
   Neophone ...........    'T'    6         -
   Tesco ..............    'T'    7         -
  }

  Blokknyitas;
  BlokkFocimiro;
  _tsz :=_telefonszam;

  if _tipus='T' then
    begin
      case _loss of
        1: begin
             Kozepreir('T-MOBIL TELEFON FELTOLTES');
             tmOBILBIZONYLAT;
           end;

        4: TcomBizonylat;
        6: begin
             Kozepreir('NEOPHON TELEFON FELTOLTES');
             TmobilBizonylat;
           end;

        7: begin
             Kozepreir('TESCO TELEFON FELTOLTES');
             Tmobilbizonylat;
           end;
      end;
    end;

  if _tipus='V' then Vodabizonylat;
  if _tipus='N' then TelenorBizonylat;

  StartNyomtatas;
end;

// =============================================================================
                         procedure TForm1.Tcombizonylat;
// =============================================================================

begin
  if _tcomTip=1 then
    begin
      Kozepreir('T-COM KONTROLL FELTOLTES');
      TmobilBizonylat;
      exit;
    end;

  if _tcomtip=2 then
    begin
      Kozepreir('T-COM BARANGOLO FELTOLTES');
      TmobilBizonylat;
      exit;
    end;
end;

// =============================================================================
                         procedure TForm1.TMobilbizonylat;
// =============================================================================

begin

  writeLn(_LFile,'Szolgaltato: Magyar Telekom Nyrt');
  writeLn(_Lfile,'Feltoltes datuma      : '+_mamas);
  writeLn(_LFile,'Feltoltott telefonszam: '+_tsz);
  writeLn(_LFile,'Feltoltott osszeg     : '+ #14 + ftform(_fizetendo)+#20);
  writeLn(_LFile,dupestring('-',39));

  writeLn(_LFile,'Terminal azonosito: '+ _terminalId);
  writeLn(_LFile,'Szolg-i integrator: Kupon Portfolio Kft');
  writeLn(_LFile,'Tranzakcio szama  : '+ _tranzakcio);
  writeLn(_LFile,dupestring('-',39));

  writeLn(_LFile,'Egyszeri brutto feltoltesre jogosit, es');
  writeLn(_LFile,'igazolja a feltoltes ellenertekenek at-');
  writeLn(_LFile,'vetelet. Orizze meg bizonylatat !');
  Kozepreir('Nem adougyi bizonylat !');

  writeLn(_LFile,' ');

  writeLn(_LFile,'Ugyfelszolgalat:');
  writeLn(_LFile,'       ugyfelszolgalat@telekom.hu');
  writeLn(_LFile,'  AFA-s szamla igenyevel kapcsolatban');
  writeLn(_LFile,'  hivja a 1777-et, vagy irjon a fenti');
  Kozepreir('e-mail cimre');
  writeLn(_LFile,'Aktualis egyenleget a *102# beutesevel');
  Kozepreir('tudja ellenorizni');
  writeLn(_LFile,' ');
  kozepreir('Koszonjuk a vasarlasat !');
end;

// =============================================================================
                          procedure TForm1.vodabizonylat;
// =============================================================================

begin
  Kozepreir('VODAFON TELEFONFELTOTES');

  WriteLn(_LFile,'Szolgaltato: Vodafone Magyarorszag Zrt.');
  writeLn(_LFile,'             1096 Budapest');
  writeLn(_Lfile,'             Lechner Odon fasor 6.'+_sorveg);

  writeLn(_LFile,'Feltoltes datuma    : ' + _mamas + ' '+_idos);
  writeLn(_Lfile,'Telefonszam         : '+ _telefonszam);
  writeLn(_LFile,'Feltoltesi osszeg   : '+ ftform(_fizetendo));
  writelN(_Lfile,'Tranzakcio azonosito: ' + _tranzakcio+_sorveg);

  writeLn(_LFile,'Afas szamlat csak az egyenleg felhasz-');
  writeLN(_LFile,'nalasarol tudunk kiallitani. Afas szam-');
  writeLn(_Lfile,'la igenyet a www.vodafone.hu oldalon,');
  writeLn(_LFile,'illetve a 1270-es telefonszamon elerheto');
  writeLn(_LFile,'Vodafon ugyfszolg-on keresztul jelezheti'+_sorveg);
  writeLn(_Lfile,'Problema eseten forduljon ugyfelszolga-');
  writeLn(_LFile,'latunkhoz a +36-1-766-45-19 tel.számon');
  writeLn(_Lfile,'Kerjuk, orizze meg a bizonylatot !'+_sorveg);
  writeLn(_LFile,'Bizonylat sorszam: '+ _bizonylatszam);

end;


// =============================================================================
                          procedure TForm1.TelenorBizonylat;
// =============================================================================

begin

  Kozepreir('TELENOR TELEFONFELTOLTES BIZONYLAT');

  WriteLn(_LFile,'Szolgaltato: Telenor Magyarorszag Zrt');
  writeLn(_LFile,'             2045 Törökbálint');
  writeLn(_Lfile,'             Pannon út 1.'+_sorveg);

  writeLn(_LFile,'Feltoltes datuma    : ' + _mamas + ' '+_idos);
  writeLn(_Lfile,'Telefonszam         : '+ _telefonszam);
  writeLn(_LFile,'Feltoltesi osszeg   : '+ ftform(_fizetendo));
  writelN(_Lfile,'Tranzakcio azonosito: ' + _tranzakcio+_sorveg);

  writeLn(_LFile,'Az egyenleg felhasznalasarol AFAs szam-');
  writeLN(_LFile,'la igenyet a - www.telenor.hu - oldalon');
  writeLn(_Lfile,'illetve a 1220-as telefonszamon elerhe-');
  writeLn(_LFile,'to  Telenor ugyfelszolgalaton keresztul');
  writeLn(_LFile,'               jelezheti'+_sorveg);

  writeLn(_Lfile,'Problema eseten forduljon ugyfelszolga-');
  writeLn(_LFile,'latunkhoz a +36-1-766-45-19 tel.számon');
  writeLn(_Lfile,'Kerjuk, orizze meg a bizonylatot !'+_sorveg);
  writeLn(_LFile,'Bizonylat sorszam: '+ _bizonylatszam);

end;

// =============================================================================
                  procedure TForm1.Konyveles(_tp: string);
// =============================================================================

// Egy tranzakció lekönyvelése:

begin

  _idos  := getidos;
  _farok := midstr(_mamas,3,2)+midstr(_mamas,6,2);
  _tablanev := 'TRAD' + _farok;
  _kategoriastr := _cikknev[_cikkszam];

  if _tp = 'M' then
    begin
      Logbair('Autómatrica könyvelése: Biz: '+ _bizonylatszam);
      Logbair(' - fizetendö: '+inttostr(_fizetendo));
      _pcs := 'INSERT INTO ' + _tablanev + ' (TIPUS,BIZONYLATSZAM,KATEGORIA,';
      _pcs := _pcs + 'STARTDATUM,ENDDATUM,RENDSZAM,COUNTRYNAME,REFERENCEID,TRANZAKCIO,FIZETENDO,';
      _pcs := _pcs + 'PENZTAROSNEV,DATUM,IDO,UGYFELSZAM,UGYFELNEV,UGYFELCIM,ELKULDVE)'+_sorveg;
      _pcs := _pcs + 'VALUES ('+ chr(39)+_tipus + chr(39) + ',';
      _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _kategoriastr + chr(39) + ',';
      _pcs := _pcs + chr(39) + _startdatums + chr(39) + ',';
      _pcs := _pcs + chr(39) + _endDatums + chr(39) + ',';
      _pcs := _pcs + chr(39) + _rendszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _countryName + chr(39) + ',';
      _pcs := _pcs + chr(39) + _referenceid + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tranzakcio + chr(39) + ',';
      _pcs := _pcs + inttostr(_fizetendo) + ',';
      _pcs := _pcs + chr(39) + trim(_prosnev) + chr(39) + ',';
      _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
      _pcs := _pcs + chr(39) + _idos + chr(39)+ ',';
      _pcs := _pcs + inttostr(_ugyfelszam) + ',';
      _pcs := _pcs + chr(39) + _ugyfelnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _ugyfelcim + chr(39) + ',';
      _pcs := _pcs + inttostr(_cikkszam)+')';
    end;

  if (_tp='T') or (_tp='N') or (_tp='V')  then
    begin
      Logbair('Telefonfeltöltés könyvelése: Biz: '+_bizonylatszam);
      Logbair(' - fizetendö: '+inttostr(_fizetendo));
      _pcs := 'INSERT INTO ' + _tablanev + ' (TIPUS,BIZONYLATSZAM,TRANZAKCIO,TELEFONSZAM,';
      _pcs := _pcs + 'FIZETENDO,PENZTAROSNEV,DATUM,IDO,SZOLGALTATO,SZOLGALTATAS,ELKULDVE)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + CHR(39) + _Tp +chr(39)+',';
      _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tranzakcio + chr(39) + ',';
      _pcs := _pcs + chr(39) + _telefonszam + chr(39) + ',';
      _pcs := _pcs + inttostr(_fizetendo) + ',';
      _pcs := _pcs + chr(39) + trim(_prosnev) + chr(39) + ',';
      _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
      _pcs := _pcs + chr(39) + _idos + chr(39)+ ',';
      _pcs := _pcs + chr(39) + _szolgaltato +chr(39) +',';
      _pcs := _pcs + chr(39) + _szolgaltatas + chr(39)+',';
      _pcs := _pcs + inttostr(_cikkszam)+')';
    end;

  TradeParancs(_pcs);

  if _tp='M' then _pcs := 'UPDATE PARAMETERS SET LASTMATRICA='+inttostr(_lastmatrica)
  else _pcs := 'UPDATE PARAMETERS SET LASTTELEFON='+inttostr(_lasttelefon);
  TradeParancs(_pcs);

  Logbair('Sorszam leptetese:');
  Logbair(_PCS);
end;

// =============================================================================
               function TForm1.HatNulele(_nn: integer):string;
// =============================================================================

var _lenres: integer;

begin
  result := '000000'+inttostr(_nn);
  _lenres := length(result);
  result := midstr(result,_lenres-5,6);
end;

// =============================================================================
                  procedure TForm1.LISTAGOMBClick(Sender: TObject);
// =============================================================================

// A fõmenü listázó menüpontja

begin
  Logbair(dupestring('-',80));
  Logbair('Feladás és listák menüpontra klikkelt');
  Zaras.ShowModal;
end;



// =============================================================================
                           procedure TForm1.AfasSzamla;
// =============================================================================

begin

  Blokknyitas;

  writeln(_LFile,chr(13)+chr(10));
  KozepreIr('EGYSZERUSITETT SZAMLA');
  WriteLn(_LFile,' elektromos autopalya matrica vetelerol');
  writeln(_LFile,' ');
  write(_LFile,'Szamlaszam: AM-' + midstr(_bizonylatszam,3,6));
  writeLn(_LFile,' Keszult: 2 pld-ban');
  writeLn(_LFile,dupestring(' ',30)+'1. peldany');
  writeln(_LFile,' ');

  BlokkFocimiro;
  writeln(_LFile,' ');

  writeln(_LFile,'    Vevo: '+leftstr(_ugyfelnev,30));
  writeLn(_LFile,'    Cime: '+leftstr(_ugyfelcim,30));
  writeLn(_LFile,' Adoszam: '+ _ugyfadoszam);
  writeln(_LFile,' ');

  writeln(_LFile,'Cikk megnevezese: '+ _xrCategory);
  writeLn(_LFile,'       Egysegara: '+ ftform(_fizetendo));
  writeLn(_LFile,'      Mennyisege: 1 db');
  writeLn(_LFile,'       Fizetendo: ' + ftform(_fizetendo));
  writeLn(_LFile,' ');
  writeLn(_LFile,'A számla vegosszege 21,26 % AFA-t tartalmaz');
  writeLn(_LFile,' ');
  Kozepreir('Lejarat utan kerjuk a bizonylatot ket');
  Kozepreir('evig megorizni / Please keep it for');
  Kozepreir('two years after its expiration');
  WriteLn(_Lfile,' ');
  KozepreIr('Szamla kelte: ' + _mamas);
  writeLn(_LFile,' ');
  writeLn(_LFile,' ');
  writeln(_LFile,dupestring('.',38));
  KozepreIr('Alairas');
  writeLn(_LFile,' ');

  Startnyomtatas;
end;


// =============================================================================
                           procedure TForm1.TelAfasSzamla;
// =============================================================================

begin

  Blokknyitas;
  BlokkFocimiro;
  writeln(_LFile,chr(13)+chr(10));
  KozepreIr('EGYSZERUSITETT SZAMLA');
  KozepreIr('Mobil telefon feltoltesrol');

  writeln(_LFile,' ');
  write(_LFile,'Szamlaszam: TE-' + midstr(_bizonylatszam,3,6));
  writeLn(_LFile,' Keszult: 2 pld-ban');
  writeLn(_LFile,dupestring(' ',30)+'1. peldany');
  writeln(_LFile,' ');
  If _penztarszam<151 then
        WriteLn(_LFile,'Szallito: Exclusive Best Change Zrt.')
  else WriteLn(_LFile,'Szallito: Expressz Ekszerhaz es Minibank Kft.');
  writeln(_LFile,'     Nev: '+leftstr(_homepenztarnev,30));
  writeLn(_LFile,'     Cim: '+leftstr(_homePenztarcim,30));
  writeLn(_LFile,' Adoszam: '+_adoszam);
  writeln(_LFile,' ');
  writeln(_LFile,'    Vevo: '+leftstr(_ugyfelnev,30));
  writeLn(_LFile,'    Cime: '+leftstr(_ugyfelcim,30));
  writeln(_LFile,' ');
  writeln(_LFile,'Szolg. megnev.: '+ leftstr(_szolgaltatas,24));
  writeLn(_LFile,'     Egysegara: '+ ftform(_fizetendo));
  writeLn(_LFile,'    Mennyisege: 1 db');
  writeLn(_LFile,'     Fizetendo: ' + ftform(_fizetendo));
  writeLn(_LFile,' ');
  writeLn(_LFile,'A szamla vegosszege 21,26 % AFA-t tartalmaz');
  writeLn(_LFile,' ');
  KozepreIr('Szamla kelte: ' + _mamas);
  writeLn(_LFile,' ');
  writeLn(_LFile,' ');
  writeln(_LFile,dupestring('.',38));
  KozepreIr('Alairas');
  writeLn(_LFile,' ');
  Startnyomtatas;
end;

// =============================================================================
                   procedure TForm1.Kozepreir(_ms: string);
// =============================================================================

var _mslen,_oo: integer;

begin
  _ms := trim(_ms);
  _mslen := length(_ms);

  if _msLen=0 then
    begin
      writeLn(_LFile,' ');
      exit;
    end;

  if _mslen>39 then
    begin
      _ms := leftstr(_ms,39);
      _msLen := 39;
    end;

   _oo := trunc((40-_mslen)/2);
   if _oo>0 then Write(_LFile,dupestring(' ',_oo));
   WriteLn(_LFile,_ms);
end;


// =============================================================================
                   procedure TForm1.WideKozepreir(_ms: string);
// =============================================================================

var _mslen,_oo: integer;

begin
  _ms := trim(_ms);
  _mslen := length(_ms);

  if _msLen=0 then
    begin
      writeLn(_LFile,' ');
      exit;
    end;

  if _mslen>19 then
    begin
      _ms := leftstr(_ms,19);
      _msLen := 19;
    end;


   write(_LFile,chr(14));
   _oo := trunc((20-_mslen)/2);
   if _oo>0 then Write(_LFile,dupestring(' ',_oo));
   WriteLn(_LFile,_ms+chr(20));
end;

// =============================================================================
                   procedure TForm1.HardKozepreir(_ms: string);
// =============================================================================

var _mslen,_oo: integer;

begin
  _ms := trim(_ms);
  _mslen := length(_ms);

  if _msLen=0 then
    begin
      writeLn(_LFile,' ');
      exit;
    end;

  if _mslen>19 then
    begin
      _ms := leftstr(_ms,19);
      _msLen := 19;
    end;


   write(_LFile,_kemeny);
   _oo := trunc((20-_mslen)/2);
   if _oo>0 then Write(_LFile,dupestring(' ',_oo));
   WriteLn(_LFile,_ms+_puha);
end;






// =============================================================================
               function TForm1.Nulele(_nn: integer): string;
// =============================================================================

begin
  result := inttostr(_nn);
  if _nn<10 then result := '0' + result;
end;

// =============================================================================
                   function TForm1.GetUtBizonylat: integer;
// =============================================================================

begin
   // Beolvassa az utolsó bizonylatot:

  TradeDbase.connected := True;
  with TradeQuery do
    begin
      close;
      Sql.Clear;
      sql.Add('SELECT * FROM PARAMETERS');
      Open;

      //_utBizonylat := Fieldbyname('UTBIZONYLAT').asInteger;

      result := Fieldbyname('UTBIZONYLAT').asInteger;
      close;
    end;
  TradeDbase.close;
end;

// =============================================================================
                  procedure TForm1.Logbair(_mondat: string);
// =============================================================================

var _times: string;

begin
  _times := GetIdos;
  _mondat := trim(_mondat);
  Assignfile(_logiro,_logpath);
  append(_logiro);
  writeLn(_logiro,kodxor(_times+': '+_mondat));
  closefile(_logiro);
end;

// =============================================================================
               function TForm1.Kodxor(_s: string): string;
// =============================================================================

var _y,_sw: byte;

begin
  result := '';
  _sw := length(_s);
  if _sw=0 then exit;

  _y := 1;
  while _y<=_sw do
    begin
      _asc := 255 - ord(_s[_y]);
      result := result + chr(_asc);
      inc(_y);
    end;
end;

// =============================================================================
                 function TForm1.Vaninternet: boolean;
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
                      procedure TForm1.HaviTradeControl;
// =============================================================================

begin
  _farok := midstr(_mamas,3,2)+midstr(_mamas,6,2);
  _tablanev := 'TRAD' + _farok;

  TradeTabla.close;
  Tradedbase.Connected := true;
  TradeTabla.TableName := _tablanev;
  if not TradeTabla.Exists then MakeTradeTabla;
  Tradedbase.close;
end;

// =============================================================================
                      procedure TForm1.MakeTradeTabla;
// =============================================================================


begin
  _pcs := 'CREATE TABLE '+_tablanev +' (' + _sorveg;
  _pcs := _pcs + 'TIPUS CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR (8) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'KATEGORIA CHAR (33) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'STARTDATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'ENDDATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'TELEFONSZAM CHAR (12) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'RENDSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'COUNTRYNAME CHAR (30) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'REFERENCEID CHAR (25) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'TRANZAKCIO CHAR (12) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'FIZETENDO INTEGER,' + _sorveg;
  _pcs := _pcs + 'PENZTAROSNEV CHAR (25) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'IDO CHAR (8) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'SZOLGALTATO CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'SZOLGALTATAS CHAR (30) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+ _sorveg;
  _pcs := _pcs + 'UGYFELSZAM INTEGER,' + _sorveg;
  _pcs := _pcs + 'UGYFELNEV CHAR(25) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'UGYFELCIM CHAR(40) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'TARSPENZTAR CHAR(4) CHARACTER SET WIN1250 COLLATE WIN1250,'+ _sorveg;
  _pcs := _pcs + 'STORNO SMALLINT,' + _sorveg;
   _pcs := _pcs + 'ELKULDVE SMALLINT)';

  TradeParancs(_pcs);
end;

// =============================================================================
                         function TForm1.Getidos:string;
// =============================================================================

begin
  Result := TimeTostr(Now);
  if midstr(Result,2,1) = ':' then Result := '0' + Result;
end;

// =============================================================================
                     procedure TForm1.TelefonGombClick(Sender: TObject);
// =============================================================================

// Fömenü mobilfeltöltés menüpontja

begin
  Logbair(dupestring('-',80));
  Logbair('Telefonfeltöltésre klikkelt');
  _ezPaySafeCard := False;
  Telefonform.showmodal;
end;

// =============================================================================
                   procedure TForm1.MatricaGombClick(Sender: TObject);
// =============================================================================

// Fõmenü autópályamatrica menüeleme:

begin
  Logbair(dupestring('-',80));
  Logbair('Autopálya-matrica menüpontra klikkelt');
  _ezPaySafeCard := False;
  Autopalyaform.showmodal;
end;

// =============================================================================
      procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
// =============================================================================

begin

  matricaregeneralo;
end;

// =============================================================================
           procedure TForm1.TANUSITVANYGOMBClick(Sender: TObject);
// =============================================================================

var  _spk: integer;

begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;
  gettanusitvany.showmodal;
end;

// =============================================================================
           function TForm1.Hundatetostr(_caldat: TDateTime): string;
// =============================================================================

var _h_ev,_h_ho,_h_nap: word;

begin
   _h_ev := yearof(_caldat);
   _h_ho := monthof(_caldat);
   _h_nap:= dayof(_caldat);

   result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;


// =============================================================================
            procedure TForm1.LOGOLVASOGOMBClick(Sender: TObject);
// =============================================================================

var _spk: integer;

begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;
  LogOlvasas.showmodal;
end;

// =============================================================================
                    function TForm1.CsomagKuldes: boolean;
// =============================================================================

begin
 // ----------------------------------------------------------------
  //  TESZT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


  AssignFile(_textiras,_requestPath);
  rewrite(_textiras);

  _z := 1;
  while _z<=_reqpieces do
    begin
      _aktreqrow := _reqrow[_z];
      writeLn(_textiras,_aktreqrow);
      inc(_z);
    end;
  CLoseFile(_textiras);

  _reppieces := 0;

  If fileExists(_replyPath) then sysutils.DeleteFile(_replypath);

  _pacs := Pchar('c:\valuta\bin\Coupon.exe');
  WinexecAndWait32(_pacs,sw_hide);

  if not _ezPaySafeCard then Logolvasas.Valaszfeldolgozas;
  result := true;

end;


// =============================================================================
       function TForm1.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
// =============================================================================

var Msg: TMsg;
    lpExitCode: cardinal;
    StartupInfo: TStartupInfo;
    ProcessInfo: TProcessInformation;

begin
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
    begin
      cb := SizeOf(TStartupInfo);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
      wShowWindow := visibility; {you could pass sw_show or sw_hide as parameter}
    end;

  if CreateProcess(nil, path, nil, nil, False, NORMAL_PRIORITY_CLASS,
                                      nil, nil, StartupInfo,ProcessInfo) then
    begin
      repeat
        while PeekMessage(Msg, 0, 0, 0, pm_Remove) do
          begin
            if Msg.Message = wm_Quit then Halt(Msg.WParam);
            TranslateMessage(Msg);
            DispatchMessage(Msg);
          end;

        GetExitCodeProcess(ProcessInfo.hProcess,lpExitCode);
      until lpExitCode <> Still_Active;

    with ProcessInfo do {not sure this is necessary but seen in in some code elsewhere}
      begin
        CloseHandle(hThread);
        CloseHandle(hProcess);
      end;

    Result := 0;
  end else Result := GetLastError;
end;

// =============================================================================
                     procedure TForm1.AlapadatBeolvasas;
// =============================================================================

begin

  // a HARDWARE táblából beolvassa a KFT nevet, Pénztár adatait:
  // utolsó ugyfél számát

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      sql.Add('SELECT * FROM PENZTAR');
      Open;
      _homePenztarnev := trim(FieldByName('PENZTARNEV').asString);
      _homePenztarCim := trim(FieldByName('PENZTARCIM').asstring);
      _homePenztarSzam := trim(FieldByName('PENZTARKOD').asstring);
      Close;

      sql.clear;
      sql.Add('SELECT * FROM HARDWARE');
      open;
      _printer :=FieldbyName('PRINTER').ASiNTEGER;
      CLOSE;

      Sql.Clear;
      Sql.add('SELECT * FROM UTOLSOBLOKKOK');
      Open;
      _LastUgyfel := FieldByName('UTOLSOUGYFELSZAM').asInteger;
      Close;
    end;
  ValutaDbase.close;

  val(_homePenztarSzam,_penztarszam,_code);
  if _code<>0 then _penztarszam := 0;

  // A penztarszam alapján meghatározza az adószámot
  //  és a Cég feliratot:

  if _penztarszam<151 then
    begin
      _adoszam := '32313332-2-02';
      _cegnev := 'Exclusive Best Change Zrt';
    end else
    begin
      _cegnev  := 'EXPRESSZ EKSZERHAZ';
      _adoszam := '14040535-2-02';
    end;

  // ---------------- A telefon és autópály alapadatok -------------------------

  _pcs := 'SELECT * FROM PARAMETERS';

  TradeDbase.Connected := true;
  with TradeQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  with Tradequery do
    begin

      _elesitve := fieldByName('ELESITVE').asInteger;
      _elesitesIdeje := trim(FieldByName('ELESITESIDEJE').AsString);
      _lastMatrica := FieldByName('LASTMATRICA').asInteger;
      _lastTelefon := FieldByName('LASTTELEFON').asInteger;

      _terminalid := trim(FieldByName('TERMINALID').AsString);
      _username := trim(FieldByName('USERNAME').AsString);
      _password := trim(FieldByName('JELSZO').AsString);
      close;
    end;
  Tradedbase.close;
end;

// =============================================================================
                    procedure TForm1.CikktorzsBeolvasas;
// =============================================================================

begin
  TradeDbase.Connected := True;
  with TradeQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('SELECT * FROM CIKKTORZS WHERE AZONOSITO<1000');
      Open;
    end;

  while not TradeQuery.Eof do
    begin
      with TradeQuery do
        begin
          _ss := FieldByName('AZONOSITO').asInteger;
          _cikkar[_ss] := FieldByName('EGYSEGAR').asInteger;
          _cikknev[_ss] := trim(FieldByName('CIKKNEV').asString);
          Next;
        end;
    end;

  Tradequery.close;
  Tradedbase.close;

end;

// =============================================================================
                          procedure TForm1.SetLogFile;
// =============================================================================

begin

  // Ha nincs log-directory - csinál egyet:

  if not DirectoryExists(_tradeLogDir) then CreateDir(_tradeLogDir);
  _logfile := 'XL'+midstr(_mamas,3,2)+midstr(_mamas,6,2)+midstr(_mamas,9,2)+'.LOG';

  _logpath := _tradeLogDir + '\' + _logfile;
  if not fileExists(_logpath) then
    begin
      assignFile(_logiro,_logpath);
      rewrite(_logiro);
      CLoseFile(_logiro);
    end;

  // ------------ A log-tábla elõkészitve irásra ------------------------

  Logbair(dupestring('=',80));
  Logbair('Az e-ker program elindul');
  Logbair('Az adatok regenerálása');
end;

// =============================================================================
              procedure TForm1.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.connected := true;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;

  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;

  ValutaTranz.commit;
  ValutaDbase.close;
end;


// =============================================================================
              procedure TForm1.TradeParancs(_ukaz: string);
// =============================================================================

begin
  TradeDbase.connected := true;
  if tradetranz.InTransaction then tradetranz.Commit;
  TradeTranz.StartTransaction;
  with TradeQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  TradeTranz.commit;
  Tradedbase.close;
end;

// =============================================================================
                               procedure Tform1.MatricaSellerCopy;
// =============================================================================

begin

  BlokkNyitas;

  Kozepreir('e-matrica ellenorzo szelveny/');
  Kozepreir('e-vignette control slip');

  Kozepreir('Eladoi peldany/Seller'#39's copy');
  Kozepreir('Nem adougyi bizonylat !');
  Kozepreir('/No taxation document !');
  WriteLn(_Lfile,' ');

  BlokkFocimiro;

  Kozepreir('Vasarlas idopontja/Date of purchase:');
  WideKozepreIr(_mamas+' '+_idos);
  WriteLn(_Lfile,' ');

  HardKozepreir('Rendszam/License plate number:');
  WideKozepreir(_xrRegistrationNumber);
  WriteLn(_Lfile,' ');

  Kozepreir('Felsegjelzes/Country code:');
  KozepreIr(_xrCountryName);
  writeLn(_LFile,' ');

  Kozepreir('Kategoria/Category: ' + _xrCategory);
  writeLn(_LFile,' ');

  KozepreIr('Tipus/Type:');
  kozepreir(_xrDurHUN);
  kozepreir(_xrDurENG);

  writeLn(_LFile,' ');

  writeLN(_LFile,_kemeny+'Ervenyesseg kezdete/Start of validity:'+_puha);

  _sors := leftstr(_xrvfd,4)+'.'+midstr(_xrVFD,5,2)+'.'+midstr(_xrVFD,7,2);
  _sors := _sors + ' ' + midstr(_xrVFD,9,2)+':'+midstr(_xrVFD,11,2)+':'+midstr(_xrVFD,13,2);
  wideKozepreIr(_sors);
  WriteLn(_LFile,' ');

  writeLn(_LFile,_kemeny+'Ervenyesseg vege/End of validity:'+_puha);

  _sors := leftstr(_xrVTD,4)+'.'+midstr(_xrVTD,5,2)+'.'+midstr(_xrVTD,7,2);
  _sors := _sors + ' ' + midstr(_xrVTD,9,2)+':'+midstr(_xrVTD,11,2)+':'+midstr(_xrVFD,13,2);
  wideKozepreIr(_sors);
  WriteLn(_LFile,' ');

  Kozepreir('Termek/Product: ' + _xrCategory);
  Kozepreir(_xrDurHun);
  Kozepreir(_xrDurEng);
  WriteLn(_LFile,' ');

  Kozepreir('TR.azonosito/tr. ID:');
  Kozepreir(_xrTransActionID);
  WriteLn(_LFile,' ');

  HArdKozepreir('Ar/Price:');
  wideKozepreir(ftform(_fizetendo)+' HUF');
  WriteLn(_LFile,#13#10);

  writeLn(_LFile,dupestring('-',39));
  kozepreIr('Ugyfel alairasa / Customer'#39's signature');
  writeLn(_LFile,' ');

  kozepreir('Alairasommal elismerem a fenti adatok');
  Kozepreir('helyesseget/I acknowledge the');
  KozepreIr('correctness of the above data with');
  Kozepreir('my signature');
  WriteLn(_LFile,'  '+chr(13)+chr(10));

  KozepreIr('Eladoi peldany, az e-matrica megvasarlast');
  Kozepreir('nem igazolja,uthasznalatra nem jogosit');
  writeLn(_LFile,' ');
  KozepreIr('/Seller'#39's copy doesn'#39't certify the');
  kozepreir('purchase of the e-vignette, doesn'#39't');
  KozepreIr('authorise for road use');
  WriteLn(_LFile,' ');

  StartNyomtatas;
end;


// =============================================================================
                               procedure Tform1.MatricaCustomerCopy;
// =============================================================================

begin
  Blokknyitas;

  Kozepreir('e-matrica ellenorzo szelveny');
  Kozepreir('/ e-vignette control slip');
  Kozepreir('Vevoi peldany / Costumer'+chr(39)+'s copy');
  Kozepreir('Nem adougyi nyilatkozat');
  Kozepreir('/ no taxation document');
  writeLn(_Lfile,' ');

  BlokkFocimiro;

  HardKozepreIr('Vasarlas idopontja/Date of purchase:');
  WideKozepreIr(_mamas+' '+_idos);
  WriteLn(_LFile,' ');

  HardKozepreir('Rendszam/License plate number');
  wideKozepreir(_rendszam);
  WriteLn(_Lfile,' ');

  Kozepreir('Felsegjelzes/Country code:');
  KozepreIr(_xrcountryName);
  writeLn(_LFile,' ');

  Kozepreir('Kategoria/Category: ' + _xrCategory);
  writeLn(_LFile,' ');

  KozepreIr('Tipus/Type:');
  Kozepreir(_xrDurHUN);
  Kozepreir(_xrDurEng);
  writeLn(_LFile,' ');

  writeLN(_LFile,_kemeny+'Ervenyesseg kezdete/Start of validity:'+_puha);

  _sors := leftstr(_xrvfd,4)+'.'+midstr(_xrVFD,5,2)+'.'+midstr(_xrVFD,7,2);
  _sors := _sors + ' ' + midstr(_xrVFD,9,2)+':'+midstr(_xrVFD,11,2)+':'+midstr(_xrVFD,13,2);

  wideKozepreIr(_sors);
  WriteLn(_LFile,' ');

  writeLn(_LFile,_kemeny+'Ervenyesseg vege/End of validity:'+_puha);

  _sors := leftstr(_xrVTD,4)+'.'+midstr(_xrVTD,5,2)+'.'+midstr(_xrVTD,7,2);
  _sors := _sors + ' ' + midstr(_xrVTD,9,2)+':'+midstr(_xrVTD,11,2)+':'+midstr(_xrVFD,13,2);

  wideKozepreIr(_sors);
  WriteLn(_LFile,' ');

  Kozepreir('Matricaazonosito/Vignette unique ID:');
  Kozepreir(_xrReferenceId);

  Kozepreir('Termek/Product: ' + _xrCategory);
  Kozepreir(_xrDurHun);
  Kozepreir(_xrDurENG);
  writeLn(_LFile,' ');

  Kozepreir('Termek azonosito/Pr. ID:');
  Kozepreir(_xrTransActionID);
  WriteLn(_Lfile,' ');

  HardKozepreir('Ar/Price:');
  wideKozepreir(ftform(_fizetendo)+' HUF');
  WriteLn(_LFile,#13#10);

  writeLn(_LFile,dupestring('-',39));
  kozepreIr('Eladohely alairasa+PH/Seller'+chr(39)+'s signature');
  WriteLn(_Lfile,' ');

  writeLn(_LFile,'Az adatok helyszinen torteno modo-');
  writeLn(_LFile,'sitasat a vasarlastol szamitott 30');
  writeLn(_LFile,'percen belul lehet kezdemenyezni/');
  writeLn(_LFile,'Modification of the data on site');
  writeLn(_LFile,'can initiate within 30 minutes');
  writeLn(_LFile,'after the time of the purchase');

  writeLn(_LFile,'Kerjuk a bizonylatot a lejarat utan');
  Kozepreir('2 evig megorizni !');

  writeLn(_LFile,'Please keep it for two years after');
  kozepreir('its expiration !');

  StartNyomtatas;
end;

// =============================================================================
                            procedure TForm1.Archivalo;
// =============================================================================

var _ev,_ho,_evtized: word;
    _fnev,_fark: string;

begin
  Arhivpanel.Visible := true;
  ArhivPanel.repaint;

  _ev := yearof(date);
  dec(_ev);

  _evtized := _ev-2000;

  _ho := 12;
  while True do
    begin
      _fark := inttostr(_evtized) + nulele(_ho);
      _fnev := 'TRAD' + _fark;

      Tradedbase.Connected := True;
      Tradetabla.Close;
      TradeTabla.TableName := _fnev;
      if not TradeTabla.Exists then Break;

      TradeDbase.close;
      _pcs := 'DROP TABLE ' + _FNEV;
      TradeParancs(_pcs);

      dec(_ho);
      if _ho=0 then
        begin
          _ho := 12;
          dec(_evtized);
        end;
    end;
  Tradedbase.close;

  Arhivpanel.Visible := False;
end;




end.

