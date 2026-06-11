unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls,
  Buttons, StrUtils, IBTable, DateUtils, ComCtrls, wininet;

type
  TForm1 = class(TForm)

    Shape1     : TShape;
    KilepesGomb: TBitBtn;
    ListaGomb  : TBitbtn;
    MatricaGomb: TBitbtn;
    TelefonGomb: TBitBtn;

    ValutaQuery: TIBQuery;
    ValutaDbase: TIBDatabase;
    ValutaTranz: TIBTransaction;

    KilepoTimer: TTimer;
    Label3     : TLabel;
    Label4     : TLabel;
    TRADEQUERY: TIBQuery;
    TRADEDBASE: TIBDatabase;
    TRADETRANZ: TIBTransaction;
    TRADETABLA: TIBTable;
    Shape2: TShape;
    Shape3: TShape;
    KFTNEVPANEL: TPanel;
    INDITO: TTimer;
    CSIK: TProgressBar;
    Shape4: TShape;
    TANUSITVANYGOMB: TBitBtn;
    BitBtn1: TBitBtn;
    FUGGONY: TPanel;
    Shape5: TShape;
    Label2: TLabel;

    procedure BlokkFocimIro(_kellnyitni: boolean);
    procedure EgysegarBetoltes;
    procedure FormActivate(Sender: TObject);
    procedure ParameterBeolvaso;

    procedure KilepesGombClick(Sender: TObject);
    procedure KilepoTimerTimer(Sender: TObject);
    procedure Konyveles(_tp: string);
    procedure ListaGombClick(sender: TObject);
    procedure MakeTradeTabla;
    procedure Matrica1Blokk;
    procedure Matrica2Blokk;
    procedure AfasSzamla;
    procedure MatricaGombClick(Sender: TObject);
    procedure PenztarBetoltes;
    procedure StartNyomtatas;
    procedure TelefonBlokk;
    procedure TelefonGombClick(Sender: TObject);
    procedure TelefonGombEnter(Sender: TObject);
    procedure TelefonGombExit(Sender: TObject);
    procedure TelefonGombMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TextKiiro;
    procedure BlokkNyitas;
    procedure Kozepreir(_ms: string);
    procedure HaviTradeControl;
    procedure TelAfasSzamla;

    procedure VodaBizonylat;
    
//    procedure DataCellToltes;

    procedure Logbair(_mondat: string);
    procedure TMobilBizonylat;
    procedure TComBizonylat;


    function FtForm(_ar: integer):string;
    function Getidos:string;
    function Getmezo(_mezonev: string): string;
    function HatNulele(_nn: integer):string;
    function Nulele(_nn: integer): string;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);

    function GetUtBizonylat: integer;
    function Kodxor(_s: string): string;

    procedure INDITOTimer(Sender: TObject);
    procedure TelenorBizonylat;

    procedure TRadeParancs(_ukaz: string);
    function Vaninternet: boolean;
    procedure TANUSITVANYGOMBClick(Sender: TObject);
    function Hundatetostr(_caldat: TDateTime): string;
    procedure BitBtn1Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1    : TForm1;


  _LFile   : TextFile;              // A nyomtató file
  _tipus   : string;                // M= matrica, T= telefon
  _elesitve: integer;
  _aktmondat: string;
  _wm      : byte;

  _letter  : TStrings;                   // A csomagküldés tárolója
  _tfs     : TFileStream;                // A válasz stream-je
  _chartomb: array[1..2048] of char;     // A valasz pufferje
  _cmd     : pchar = 'OPEN';             // Parameterek a Rasdial.exe-hez
  _dir     : pchar = 'C:';
  _fil     : pchar = 'rasdial.exe';
  _par     : pchar;

  _qq      : array[1..123] of string;

  _ipcim   : string = '91.213.9.44';   // éles ip-cim
//  _ipcim   : string = '91.213.9.27';   // test ip-cim

  _url     : string = 'https://91.213.9.44/kupon/as.php';
  _olvas   : file of char;

  _sorveg  : string = chr(13) + chr(10);
  _sikeres : Boolean;
  _megvan  : Boolean;
  _ezmegye : Boolean;

 
  _cikkar  : array[1..699] of integer;     // a cikkek árai
  _cikknev : array[1..699] of string;      // a cikkek nevei
  _tFirm   : array[1..6] of string = ('T-Mobile','Telenor','Vodafone','T-Com',
                                        'NeoPhone','Tesco');

  _cikkszam,_proskod,_internetProcNum,_code,_prosOke   : integer;
  _top,_left,_height,_width,_mResult,_meret,_fizetendo : integer;
  _tranzakcioOke,_counter,_countryCode,_psOsszeg       : integer;
  _lastMatrica,_lastTelefon,_lastUgyfel,_ugyfelszam    : integer;
  _megyess                                             : integer;

  _kapcsolatmod,_kapcsolatnev,_felhasznalonev,_ijelszo     : string;
  _hibaUzenet,_VFD,_pcs,_prosnev,_prosjelszo,_httpTipus    : string;
  _homePenztarszam,_homePenztarnev,_status,_bizonylatszam  : string;
  _Tranzakcio,_replyFile,_rendszam,_rrendszam,_kategoriastr: string;
  _rcikkszams,_rFizetendos,_rOrszagnev,_aktdatumido        : string;
  _startDatIDo,_endDatIdo,_countryName,_referenceid        : string;
  _telefonszam,_szolgaltato,_szolgaltatas,_mamas,_idos     : string;

  // ----- Topup reply értékek ------------------------

  _xrStatusId,_xrStatusDescription,_xrMessageType : string;
  _xrAmount,_xrPhoneNumber,_xrTransactionId       : string;
  _xrTransactionDate,_xrOutletAddress,_xrProductId: string;
  _xrOutletTaxNo,_xrProductName,_xrOperatorId     : string;
  _xrOutletName,_xrReceiptNumber,_xrPrintReceipt  : string;
  _xrRegistrationNumber,_xrVFD,_xrVTD,_tablanev   : string;
  _xrCountryName,_xrReferenceId,_penztarosnev     : string;
  _homePenztarcim,_startdatums,_endDatums,_farok  : string;
  _ugyfelnev,_ugyfelcim,_startPerc,_kftnev,_tsz   : string;
  _aktmegyenev,_aktmatricanev                     : string;

  _startev,_startho,_startnap,_starthnap: word;
  _endev,_endho,_endNap,_endhnap        : word;
  _kellafas: boolean;

  _USERNAME,_PASSWORD,_TERMINALID,_lastday,_sDatum,_datum,_adoszam: string;
  _sumho,_snev,_snho,_snsumho,_utbizonylat: integer;
  _sumtel,_sumMat,_sumVod,_sumNor,_sumFel,_forint,_kftlen,_recno,_tanoke: integer;
  _felirat: string;
  _p,_TCOMTIP: byte;

  _tradeLogDir: string = 'C:\VALUTA\TRADELOG';
  _logfile,_logPath: string;
  _LOGiro: Textfile;

  _startDatum,_endDatum: TDateTime;
  _bytetomb: array[1..1024] of byte;

  _hmFt,_hTft,_hFFt: array[1..200] of integer;

  _hevh: array[1..200] of string;

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
  _sh        : array[1..7] of tshape;
  _csh       : array[1..6] of TShape;


  _megyenev:array[0..18] of string =('BACS-KISKUN',           // 0
                                  'BARANYA',                  // 1
                                  'BÉKÉS',                    // 2
                                  'BORSOD-ABAÚJ-ZEMPLÉN',     // 3
                                  'CSONGRÁD',                 // 4
                                  'FEJÉR',                    // 5
                                  'GYÖR-MOSON-SOPRON',        // 6
                                  'HAJDÚ-BIHAR',              // 7
                                  'HEVES',                    // 8

                                  'JÁSZ-NAGYKUN-SZOLNOK',     // 9

                                  'KOMÁROM-ESZTERGOM',        // 10
                                  'NÓGRÁD',                   // 11
                                  'PEST',                     // 12
                                  'SOMOGY',                   // 13
                                  'SZABOLCS-SZATMÁR-BEREG',   // 14

                                  'TOLNA',                    // 15
                                  'VAS',                      // 16
                                  'VESZPRÉM',                 // 17
                                  'ZALA');                    // 18




  // --------------------------------------------------------------------------

  _honev: array[1..12] of string = ('JANUAR','FEBRUAR','MARCIUS','APRILIS','MAJUS',
         'JUNIUS','JULIUS','AUGUSZTUS','SZEPTEMBER','OKTOBER','NOVEMBER','DECEMBER');

  _napnev: array[1..7] of string = ('HETFO','KEDD','SZERDA','CSUTORTOK','PENTEK',
                                                'SZOMBAT','VASARNAP');

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
  _username := '';
  _terminalid := '';
  _password := '';

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

  with Fuggony do
    begin
      left:= 40;
      top := 80;
      Visible := True;
      repaint;
    end;

  _kellafas := false;

  _mamas := HunDateTostr(date);
  Indito.Enabled := True;
end;


// =============================================================================
                procedure TForm1.InditoTimer(Sender: TObject);
// =============================================================================

begin

  Indito.Enabled := False;

  // Ellenörzi, hogy van-e TRADEyymm tábla - ha nincs csinál
  HaviTradeControl;

  // ---------------------------------------------------------------------------

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

  Logbair(dupestring('=',80));
  Logbair('Az e-ker program elindul');
  Logbair('Az adatok regenerálása');
  matricaregeneralo;

  // ---------------------------------------------------------------------------

  // Beolvassa az utolsó telefon és matrica bizonylatszámokat,
  // valamint beolvassa a terminalid, username és password értékeket:

  ParameterBeolvaso;

  // ---------------------------------------------------------------------------

  // Ha a terminalid nem 4 betüből áll, akkor nincs kitültve a tanusitvány:

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

  // a HARDWARE táblából beolvassa a KFT nevet:

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;
      _kftnev := FieldByName('KFTNEV').asString;
      Close;
    end;
  ValutaDbase.close;


  _kftnev := trim(lowercase(_kftnev));

  // A kft név alapján meghatározza a kft adószámát:

  Logbair('A gép beolvassa az adószámot');
  if _kftnev='best' then _adoszam := '11788670-2-41';
  if _kftnev='east' then _adoszam := '23008975-2-41';
  if _kftnev='pannon' then _adoszam := '23009017-1-41';

  _kftlen := length(_kftnev);
  _kftnev := uppercase(leftstr(_kftnev,1))+midstr(_kftnev,2,_kftlen-1);
  _felirat := 'Exclusive ' + _KFTNEV + ' Change';

  KftnevPanel.Caption := _felirat;
  KftnevPanel.repaint;

  // -----------Pénztáros belépése, jelszóval ----------------------------------

  Logbair('Most belép a pénztáros');

  _prosoke := GetPenztaros.ShowModal;
  // _proskod,_prosnev beolvasása, jelszó ellenőrzése:

  if _prosoke<>1 then
    begin
      // Nem tudta a jelszavát:

      Kilepotimer.enabled := true;
      Exit;
    end;

  // Pénztár- és internet adatok betöltése a valuta adatbázisból

  // Betölti: _homepenztar-szam, -nev, -cim és utolsougyfelszam adatokat:

  PenztarBetoltes;

  // Ha nincs internet, akkor nem lehet dolgozni:

  if not Vaninternet then
    begin
      ShowMessage('NINCS INTERNET !');
      Application.terminate;
      exit;
    end;

  // Egységárak betöltése a TRADE cikktorza adatbázisból
  // _cikkar[_cikkszam] és _cikknev[_cikkszam]
  EgysegarBetoltes;
  Fuggony.Visible := False;
end;



// =============================================================================
/// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// ============================================================================
               procedure TForm1.TELEFONGOMBEnter(Sender: TObject);
// ============================================================================


begin
  TBitbtn(sender).Font.Style := [fsBold,fsItalic];
end;

// ============================================================================
              procedure TForm1.TELEFONGOMBExit(Sender: TObject);
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
/// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                procedure TForm1.EgysegarBetoltes;
// =============================================================================

// Cikktörzsböl betölti a cikkneveket és egységárakat  tömbökbe

begin
  Tradedbase.connected := True;
  with TradeQuery do
    begin
      CLose;
      Sql.Clear;
      sql.Add('SELECT * FROM CIKKTORZS');
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
                   function TForm1.FtForm(_ar: integer):string;
// =============================================================================

var _lenars: integer;

begin

  result := inttostr(_ar);
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
  Logbair('Kilépés a programból - PROGRAM VÉGE');
  Application.terminate;
end;

// =============================================================================
                function TForm1.Getmezo(_mezonev: string): string;
// =============================================================================

// Chartömb pufferből visszaadja a parameter nevü mezö értékét:

var _xx: integer;

begin
  result := '';
  _xx := Ansipos(_mezonev,_chartomb);

  if _xx = 0 then exit;

  while ord(_chartomb[_xx])<>62 do inc(_xx);
  inc(_xx);

  while ord(_chartomb[_xx])<>60 do
    begin
      result := result + _chartomb[_xx];
      inc(_xx);
    end;

  result := trim(result);
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
             procedure TForm1.BlokkFocimIro(_kellnyitni: boolean) ;
// ============================================================================

// Blokknyomtatás fejléce

var _cimnev: string;

begin
  if _kellnyitni then BlokkNyitas;

  writeLn(_LFile,dupestring('=',39));
  writeLn(_Lfile,#14'      EXCLUSIVE'#20);
  if _kftnev = 'PANNON' then _cimnev := ' PANNON '
  else _cimnev := '   ' + _kftnev;

  writeLn(_LFile,#14+_CIMNEV+ 'CHANGE KFT.'#20);
  write(_LFile,_homePenztarNev);
  writeLN(_LFile,_homePenztarszam);
  writeLn(_LFile,_homePenztarCim);
  writeLn(_lFile,'Adoszam       : ' + _adoszam);
  WriteLn(_LFile,'Terminal ID   : '+_terminalId);
  writeLn(_LFile,'Bizonylatszam : '+ _bizonylatszam);

  writeLn(_LFile,dupestring('=',39));
end;


// =============================================================================
                        procedure TForm1.Blokknyitas;
// =============================================================================


begin
  assignFile(_LFile,'C:\valuta\aktlst.txt');
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
  TextKiiro;

end;

// ============================================================================
                        procedure TForm1.TextKiiro;
// ============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin
  AssignFile(_nyomtat,'LPT1');
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

  BlokkFocimiro(True);
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
  writeLn(_LFile,'latunkhoz a 06-40-630-360 tel.számon');
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
  writeLn(_LFile,'latunkhoz a 06-40-630-360 tel.számon');
  writeLn(_Lfile,'Kerjuk, orizze meg a bizonylatot !'+_sorveg);
  writeLn(_LFile,'Bizonylat sorszam: '+ _bizonylatszam);

end;




// =============================================================================
                  procedure TForm1.Konyveles(_tp: string);
// =============================================================================

// Egy tranzakció lekönyvelése:

begin

  _idos := getidos;
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

  if (_tp='P') then   // Paysafecard
    begin
      Logbair('Paysafecard könyvelése: Biz: '+_bizonylatszam);
      Logbair('- fizetendö: '+ inttostr(_psOsszeg));

      _pcs := 'INSERT INTO ' + _tablanev + ' (TIPUS,BIZONYLATSZAM,TRANZAKCIO,';
      _pcs := _pcs + 'FIZETENDO,PENZTAROSNEV,DATUM,IDO,SZOLGALTATO,SZOLGALTATAS,ELKULDVE)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + CHR(39) + _Tp +chr(39)+',';
      _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _tranzakcio + chr(39) + ',';

      _pcs := _pcs + inttostr(_psOsszeg) + ',';
      _pcs := _pcs + chr(39) + trim(_prosnev) + chr(39) + ',';
      _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
      _pcs := _pcs + chr(39) + _idos + chr(39)+ ',';
      _pcs := _pcs + chr(39) + 'PREPAID' +chr(39) +',';
      _pcs := _pcs + chr(39) + 'PaySafeCard' + chr(39)+',';
      _pcs := _pcs + inttostr(_cikkszam)+')';
    end;

  TradeParancs(_pcs);

  if _tipus = 'M' then  _pcs := 'UPDATE PARAMETERS SET LASTMATRICA='+inttostr(_lastmatrica)
  else _pcs := 'UPDATE PARAMETERS SET LASTTELEFON='+inttostr(_lasttelefon);
  TradeParancs(_pcs);
end;

// =============================================================================
                        procedure TForm1.PenztarBetoltes;
// =============================================================================


// Penztárnév és kód betöltése a valuta.fdb-ből

begin
  Logbair('A pénztár adatainak beolvasása');

  Valutadbase.Connected := True;
  _pcs := 'SELECT * FROM PENZTAR';
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;

      _homePenztarnev := trim(FieldByName('PENZTARNEV').asString);
      _homePenztarCim := trim(FieldByName('PENZTARCIM').asstring);
      _homePenztarSzam := trim(FieldByName('PENZTARKOD').asstring);
      close;
    end;

  _pcs := 'SELECT * FROM UTOLSOBLOKKOK';
  with Valutaquery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      _LastUgyfel := FieldByName('UTOLSOUGYFELSZAM').asInteger;
      Close;
    end;
  ValutaDbase.close;

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

// A főmenü listázó menüpontja

begin
  Logbair(dupestring('-',80));
  Logbair('Feladás és listák menüpontra klikkelt');
  Zaras.ShowModal;
end;



(*
//34567890123456789012345678901234567890
***** E-MATRICA ELLENORZO SZELVENY *****
     (HIGHWAY TOLL CONTROL COUPON)

BIZONYLATSZAM/S.NO: AM-1234567

KATEGORIA/CATEGORY:
          D1- MOTOROS NÉGYNAPI ELOSZEZON
ERV.KEZD/VALID FROM: 2010.02.22 00:00:00
ERV.VEGE/VALID TILL: 2010.02.22 00:00:00
RENDSZAM/REGISTRATION NUMBER: ABC123
ORSZAG/COUNTRY : MAGYARORSZAG - H
REFERENCIA SZAM: 12345678901234567890123
TRANZAKCIÓ SZÁM: 1234567890

OSSZEG/TOTAL: 12.500 HUF

........................................
PENZTAROS: KOVACS ELEONORA
KELT/DATE: 2010.11.22  12:32:33
-----------------------------------------



//34567890123456789012345678901234567890
*** MOBILFELTOLTEST IGAZOLO SZELVENY ***

BIZONYLATSZAM/S.NO.: AM-1234567

        SZOLGALTATO: VODAFONE
        TELEFONSZAM: 70-123-44-55
  FELTOLTOTT OSSZEG: 14.000 Ft

........................................
PENZTAROS: KOVACS ELEONORA
KELT/DATE: 2010.11.22  12:32:33
*)

// =============================================================================
                               procedure Tform1.matrica1Blokk;
// =============================================================================


begin

 // BlokkNyitas;
  BlokkFocimiro(True);
  Kozepreir('E-matrica  / E-vignette');
  Kozepreir('Ellenorzo szelveny/Counterfoil');
  Kozepreir('Elado peldanya / Seller'#39's copy');
  WriteLn(_Lfile,' ');
  KozepreIr('Eladohely / Terminal id : '+_terminalid);
  WriteLn(_Lfile,' ');
  Kozepreir('Rendszam/Registration number: '+_rendszam);
  Kozepreir('Orszag/Country: '+_countryname);
  Kozepreir('Tipus/Type: '+_aktmatricanev);
  WriteLn(_LFile,' ');
  writeLn(_LFile,'      Ar/Price: '+ #14 + ftform(_fizetendo)+ #20#13#10);

  Kozepreir('Ervenyes/Valid:');
  if _ezmegye then Kozepreir(_aktmegyenev+' MEGYE/COUNTY')
  else Kozepreir('Az egesz orszagban/All of Hungary');


  Kozepreir('Ervenyesseg kezdete/Valid from:');
  Kozepreir(_startdatums);
  KozepreIr('Vasarlas idopontja/Purchase time:');
  KozepreIr(_mamas+'  '+_idos);
  KozepreIr('Tranzakcio azonosito/Transaction ID:');
  Kozepreir(_tranzakcio);
  writeLn(_LFile,' ');
  WriteLn(_LFile,'Alairasommal elismerem a fenti adatok');
  WriteLn(_LFile,'helyesseget/I acknowledge the correct-');
  KozepreIr('ness of the above data with');
  Kozepreir('my signature');
  WriteLn(_LFile,'  '+chr(13)+chr(10));
  writeLn(_LFile,dupestring('.',39));
  KozepreIr('Alairas/Signature');
  writeLn(_Lfile,' '+chr(13)+chr(10));
  writeLn(_LFile,' Nem adougyi bizonylat/');
  writeLn(_LFile,'                Not a taxation voucher'#13#10);
  KozepreIr('Ez az eladoi peldany uthasznalatra nem');
  KozepreIr('jogosit/This seller'#39's copy doesn'#39't');
  KozepreIr('entitle you to use roads');
  WriteLn(_LFile,' ');
  StartNyomtatas;
end;


// =============================================================================
                               procedure Tform1.matrica2Blokk;
// =============================================================================


begin
  // BlokkNyitas;
  BlokkFocimiro(True);
  Kozepreir('E-matrica  / E-vignette');
  writeLn(_Lfile,' ');
  Kozepreir('Ellenorzo szelveny /Counter foil');
  KozepreIr('Vevo peldanya /  Costumer'#39's copy');

  WriteLn(_Lfile,' ');
  kozepreir('Exclusive '+_kftnev+' Change Kft.');
  kozepreir(trim(_homePenztarnev));
  KozepreIr(trim(_homePenztarcim));
  writeLn(_Lfile,' ');
  Kozepreir('Rendszam/Registration number:');
  writeLn(_LFile,'             '+#14+_rendszam+#20#13#10);
  KozepreIr('Orszag/Country:');
  Kozepreir(_countryname);
  Kozepreir('Tipus / Type:');
  Kozepreir(_aktmatricanev);
  WriteLn(_LFile,'      Ar/Price: '+#14+ftform(_fizetendo)+#20#13#10);

  Kozepreir('Ervenyes/Valid:');
  if _ezmegye then Kozepreir(_aktmegyenev+' MEGYE/COUNTY')
  else Kozepreir('Az egesz orszagban/All of Hungary');

  KozepreIr('Ervenyesseg kezdete/Start of validity:');
  Kozepreir(_startdatums+'  ' +  _startPerc);
  Kozepreir('Ervenyesseg vege/End of validity:');
  Kozepreir(_enddatums+'  23:59:59');
  WriteLn(_Lfile,' ');
  Kozepreir('Vasarlas idopontja/Purchasing time:');
  Kozepreir(_mamas+'  '+ _idos);
  KozepreIr('Tranzakcio azonosito/Transaction ID:');
  Kozepreir(_tranzakcio);
  Kozepreir('Sorszam / Serial number:');
  Kozepreir(_referenceid);
  WriteLn(_Lfile,' ');
  Kozepreir('Lejarat utan kerjuk a bizonylatot egy');
  Kozepreir('evig megorizni / Please keep it for');
  Kozepreir('one year after its expiration');
  WriteLn(_Lfile,' ');
  writeLn(_Lfile,' Nem adougyi bizonylat/');
  writeLn(_LFile,'                Not a taxation voucher');
  writeLn(_lfile,#13#10#13#10);
  Kozepreir('Eladohely p.h/Seller'#39's stamp');
  startNyomtatas;
end;

// =============================================================================
                           procedure TForm1.AfasSzamla;
// =============================================================================

begin
  _kategoriastr := leftstr(_cikknev[_cikkszam],21);
  // Blokknyitas;
  BlokkFocimiro(True);
  writeln(_LFile,chr(13)+chr(10));
  KozepreIr('EGYSZERUSITETT SZAMLA');
  WriteLn(_LFile,' elektromos autopalya matrica vetelerol');
  writeln(_LFile,' ');
  write(_LFile,'Szamlaszam: AM-' + midstr(_bizonylatszam,3,6));
  writeLn(_LFile,' Keszult: 2 pld-ban');
  writeLn(_LFile,dupestring(' ',30)+'1. peldany');
  writeln(_LFile,' ');
  WriteLn(_LFile,'Szallito: Exclusive '+_kftnev+' Change Kft.');
  writeln(_LFile,'     Nev: '+leftstr(_homepenztarnev,30));
  writeLn(_LFile,'     Cim: '+leftstr(_homePenztarcim,30));
  writeLn(_LFile,' Adoszam: '+_adoszam);
  writeln(_LFile,' ');
  writeln(_LFile,'    Vevo: '+leftstr(_ugyfelnev,30));
  writeLn(_LFile,'    Cime: '+leftstr(_ugyfelcim,30));
  writeln(_LFile,' ');
  writeln(_LFile,'Cikk megnevezese: '+ _kategoriastr);
  writeLn(_LFile,'       Egysegara: '+ ftform(_fizetendo));
  writeLn(_LFile,'      Mennyisege: 1 db');
  writeLn(_LFile,'       Fizetendo: ' + ftform(_fizetendo));
  writeLn(_LFile,' ');
  writeLn(_LFile,'A szamla vegosszege 21 % AFA-t tartalmaz');
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
                           procedure TForm1.TelAfasSzamla;
// =============================================================================

begin

  // Blokknyitas;
  BlokkFocimiro(True);
  writeln(_LFile,chr(13)+chr(10));
  KozepreIr('EGYSZERUSITETT SZAMLA');
  KozepreIr('Mobil telefon feltoltesrol');

  writeln(_LFile,' ');
  write(_LFile,'Szamlaszam: TE-' + midstr(_bizonylatszam,3,6));
  writeLn(_LFile,' Keszult: 2 pld-ban');
  writeLn(_LFile,dupestring(' ',30)+'1. peldany');
  writeln(_LFile,' ');
  WriteLn(_LFile,'Szallito: Exclusive ' + _kftnev+ ' Change Kft.');
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
  writeLn(_LFile,'A szamla vegosszege 21 % AFA-t tartalmaz');
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
               function TForm1.Nulele(_nn: integer): string;
// =============================================================================

begin
  result := inttostr(_nn);
  if _nn<10 then result := '0' + result;
end;



(*
1234567890123456789012345678901234567890
         E-matrica / E-vignette                        1
     Ellenorzo szelveny/Counterfoil                    2
     Elado peldanya / Seller's copy                    3
                                                       4
     Eladohely / Terminal id : 16xx                    5

  Rendszam/Registration number: ABC123                 6                                                       7
   Orszag/Country: H - Magyarorszag                    8
Tipus/Type: D1 motoros 4 napos                         9
                                                      10
      Ar/price: 11117733 HHUUFF                            11
   Ervenyesseg kezdete/Valid from:                    12
            2010.04.30                                13
  Vasarlas idopontja/Purchase time:                   14
        2010.03.09 11:20:20                           15
 Tranzakcio azonosito/Transaction ID:                 16
             13039188                                 17
                                                      18
 Alairasommal elismerem a fenti adatok                19
 helyesseget/I acknowledge the correct-               20
   ness of the above data with                        21
           my signature                               22
                                                      23
                                                      24
........................................              25
           Alairas/Signature                          26
                                                      27
                                                      28
 Nem adougyi bizonylat/                               29
                Not a taxation voucher                30
 Ez az eladoi peldany uthasznalatra nem               31
   jogosit/This seller's copy doesn't                 32
        entitled to use roads                         33

----------------------------------------

1234567890123456789012345678901234567890

       E-matrica  / E-vignette                         1
                                                       2
     Ellenorzo szelveny /Counter foil                  3
     Vevo peldanya /  Costumer's copy                  4
                                                       5
Szentirmay Tihamer                                     6
1087 Budapest, Kobanyai ut 123.                        7
                                                       8
      Rendszam/Registration number:                    9
             AABBBCC112233                               10
             Orszag/Country:                          11
             H - Magyarorszag                         12
               Tipus/Type:                            13
            D1 motoros 4 napos                        14
     Ar / Price: 11.223344 hhuuff                      15
 Ervenyesseg kezdete/Start of validity:               16
           2010.03.09 00:00:00                        17
    Ervenyesseg vege/End of validity               18
           2010.03.04 23:59:59                        19
   Vasarlas idopontja/Purchasing time:                20
           2010.03.04 11:20:33                        21
 Tranzakcio azonosito/Transaction ID:                 22
                 13039188                             23
         Sorszam / Serial number:                     24
           501003091120171490572                      25
                                                      26
  Lejarat utan kerjuk a bizonylatot egy                 27
  evig megorizni / Please keep it for                 28
      one year after its expiration                     29
                                                      30
 Nem adougyi bizonylat/                               31
                Not a taxation voucher                32
                                                      33
                                                      34
                                                      35
     Eladohely p.h/Seller's stamp                     36


----------------------------------------

1234567890123456789012345678901234567890


         EGYSZERUSITETT SZAMLA
 elektromos autopalya matrica vetelerol

Szamlaszam: M-123456 Keszult: 2 pld-ban
                             1. peldany

Szallito: Exclusive Best Change Kft.
     Nev: 123456789012345678901234567890     // Város
     Cim: 123456789012345678901234567890     // Cim
 Adoszam:

    Vevo: 123456789012345678901234567890     // Vevo neve
    Cime: 123456789012345678901234567890     // Vevo cime

Cikk megnevezese: 4 napos matrica
       Egységára: 1.170 Ft
      Mennyisege: 1 db
       Fizetendo: 1.170 Ft

A szamla vegosszege 21 % AFA-t tartalmaz

        Szamla kelte: 2010.11.11

........................................
                 Alairas

                                                       8
      Rendszam/Registration number:                    9
             AABBBCC112233                               10
             Orszag/Country:                          11
             H - Magyarorszag                         12
               Tipus/Type:                            13
            D1 motoros 4 napos                        14
     Ar / Price: 11.223344 hhuuff                      15
 Ervenyesseg kezdete/Start of validity:               16
           2010.03.09 00:00:00                        17
    Ervenyesseg vege/End of validity               18
           2010.03.04 23:59:59                        19
   Vasarlas idopontja/Purchasing time:                20
           2010.03.04 11:20:33                        21
 Tranzakcio azonosito/Transaction ID:                 22
                 13039188                             23
         Sorszam / Serial number:                     24
           501003091120171490572                      25
                                                      26
  Lejarat utan kerjuk a bizonylatot egy                 27
  evig megorizni / Please keep it for                 28
      one year after its expiration                     29
                                                      30
 Nem adougyi bizonylat/                               31
                Not a taxation voucher                32
                                                      33
                                                      34
                                                      35
     Eladohely p.h/Seller's stamp                     36

----------------------------------------
1234567890123456789012345678901234567890


         EGYSZERUSITETT SZAMLA
       Mobil telefon feltoltesrol

Szamlaszam: T-123456 Keszult: 2 pld-ban
                             1. peldany

Szallito: Exclusive Best Change Kft.
     Nev: 123456789012345678901234567890     // Város
     Cim: 123456789012345678901234567890     // Cim

    Vevo: 123456789012345678901234567890     // Vevo neve
    Cime: 123456789012345678901234567890     // Vevo cime

Szolg. megnev.: vodafon mobil-feltoltes
     Egységára: 1.170 Ft
    Mennyisege: 1 db
     Fizetendo: 1.170 Ft

     A szamla 21 % AFA-t tartalmaz

       Szamla kelte: 2010.11.11

........................................
                 Alairas


*)




function TForm1.GetUtBizonylat: integer;

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

{
procedure TForm1.DataCellToltes;

begin

_qq[1] := '6,T-MOBILE MOBIL-FELTOLTES,T-MOBILE,3000,1';
_qq[2] := '7,T-MOBILE MOBIL-FELTOLTES,T-MOBILE,3500,1';
_qq[3] := '8,T-MOBILE MOBIL-FELTOLTES,T-MOBILE,5000,1';
_qq[4] := '9,T-MOBILE MOBIL-FELTOLTES,T-MOBILE,10000,1';
_qq[5] := '10,VODAFONE MOBIL-FELTOLTES,VODAFONE,3000,1';
_qq[6] := '11,VODAFONE MOBIL-FELTOLTES,VODAFONE,7000,1';
_qq[7] := '12,VODAFONE MOBIL-FELTOLTES,VODAFONE,12000,1';
_qq[8] := '13,VODAFONE MOBIL-FELTOLTES,VODAFONE,1500,1';
_qq[9] := '14,VODAFONE MOBIL-FELTOLTES,VODAFONE,5000,1';
_qq[10]:= '18,TELENOR MOBIL-FELTOLTES,TELENOR,10000,1';

_qq[11]:= '19,TELENOR MOBIL-FELTOLTES,TELENOR,15000,1';
_qq[12]:= '24,D1 - HETI MATRICA,AAK,2975,1';
_qq[13]:= '25,D1 - HAVI MATRICA,AAK,4780,1';
_qq[14]:= '26,D1 - EVES MATRICA,AAK,42980,1';
_qq[15]:= '34,D1 - MOTOROS HETI,AAK,1470,1';
_qq[16]:= '57,B2 HETI BUSZ MATRICA,AAK,13385,1';
_qq[17]:= '58,B2 HAVI BUSZ MATRICA,AAK,21975,1';
_qq[18]:= '59,B2 EVES BUSZ MATRICA,AAK,199975,1';
_qq[19]:= '67,T-MOBILE MOBIL-FELTOLTES,T-MOBILE,15000,1';
_qq[20]:= '70,30 NAPOS KONTROL-KARTYA,T-COM,2500,1';

_qq[21]:= '71,60 NAPOS KONTROL-KARTYA,T-COM,7400,1';
_qq[22]:= '72,90 NAPOS KONTROL-KARTYA,T-COM,10500,1';
_qq[23]:= '73,120 NAPOS KONTROL-KARTYA,T-COM,19500,1';
_qq[24]:= '74,T-COM BARANGOLO-KARTYA,T-COM,1000,1';
_qq[25]:= '75,T-COM BARANGOLO-KARTYA,T-COM,2000,1';
_qq[26]:= '76,T-COM BARANGOLO-KARTYA,T-COM,5000,1';
_qq[27]:= '78,VODAFONE MOBILFELTOLTES,VODAFONE,2000,1';
_qq[28]:= '80,NEOPHONE - 1.000,NEOPHONE,1000,1';
_qq[29]:= '81,NEOPHONE - 2.000,NEOPHONE,2000,1';
_qq[30]:= '82,NEOPHONE - 5.000,NEOPHONE,5000,1';

_qq[31]:= '83,NEOPHONE - 10.000,NEOPHONE,10000,1';
_qq[32]:= '84,T-MOBILE MOBILFELTOLTES,T-MOBILE,1500,1';
_qq[33]:= '86,TELENOR FELTOLTES,TELENOR,1700,1';
_qq[34]:= '87,TELENOR FELTOLTES,TELENOR,3300,1';
_qq[35]:= '88,TELENOR FELTOLTES,TELENOR,5500,1';
_qq[36]:= '89,TESCO-MOBILE FELTOLTES,TESCO,2000,1';
_qq[37]:= '91,TESCO-MOBILE FELTOLTES,TESCO,5000,1';
_qq[38]:= '92,TESCO-MOBILE FELTOLTES,TESCO,7000,1';
_qq[39]:= '93,TESCO-MOBILE FELTOLTES,TESCO,12000,1';
_qq[40]:= '267,TELENOR FELTOLTES,TELENOR,1200,1';

_qq[41]:= '268,TESCO-MOBILE FELTOLTES,TESCO,3500,1';
_qq[42]:= '501,U Bacs-Kiskun megye,AAK,5000,1';
_qq[43]:= '502,U Baranya megye,AAK,5000,1';
_qq[44]:= '503,U Bekes megye,AAK,5000,1';
_qq[45]:= '504,U Borsod-Abauj-Zemplen megye,AAK,5000,1';
_qq[46]:= '505,U Csongrad megye,AAK,5000,1';
_qq[47]:= '506,U Fejer megye,AAK,5000,1';
_qq[48]:= '507,U Gyor-Moson-Sopron megye,AAK,5000,1';
_qq[49]:= '508,U Hajdu-Bihar megye,AAK,5000,1';
_qq[50]:= '509,U Heves megye,AAK,5000,1';

_qq[51]:= '510,U Jasz-Nagykun-Szolnok megye,AAK,5000,1';
_qq[52]:= '511,U Komarom-Esztergom megye,AAK,5000,1';
_qq[53]:= '512,U Nograd megye,AAK,5000,1';
_qq[54]:= '513,U Pest megye,AAK,5000,1';
_qq[55]:= '514,U Somogy megye,AAK,5000,1';
_qq[56]:= '515,U Szabolcs-Szatmar-Bereg megye,AAK,5000,1';
_qq[57]:= '516,U Tolna megye,AAK,5000,1';
_qq[58]:= '517,U Vas megye,AAK,5000,1';
_qq[59]:= '518,U Veszprem megye,AAK,5000,1';
_qq[60]:= '519,U Zala megye,AAK,5000,1';

_qq[61]:= '521,D1 Bacs-Kiskun megye,AAK,5000,1';
_qq[62]:= '522,D1 Baranya megye,AAK,5000,1';
_qq[63]:= '523,D1 Bekes megye,AAK,5000,1';
_qq[64]:= '524,D1 Borsod-Abauj-Zemplen megye,AAK,5000,1';
_qq[65]:= '525,D1 Csongrad megye,AAK,5000,1';
_qq[66]:= '526,D1 Fejer megye,AAK,5000,1';
_qq[67]:= '527,D1 Gyor-Moson-Sopron megye,AAK,5000,1';
_qq[68]:= '528,D1 Hajdu-Bihar megye,AAK,5000,1';
_qq[69]:= '529,D1 Heves megye,AAK,5000,1';
_qq[70]:= '530,D1 Jasz-Nagykun-Szolnok megye,AAK,5000,1';

_qq[71]:= '531,D1 Komarom-Esztergom megye,AAK,5000,1';
_qq[72]:= '532,D1 Nograd megye,AAK,5000,1';
_qq[73]:= '533,D1 Pest megye,AAK,5000,1';
_qq[74]:= '534,D1 Somogy megye,AAK,5000,1';
_qq[75]:= '535,D1 Szabolcs-Szatmar-Bereg megye,AAK,5000,1';
_qq[76]:= '536,D1 Tolna megye,AAK,5000,1';
_qq[77]:= '537,D1 Vas megye,AAK,5000,1';
_qq[78]:= '538,D1 Veszprem megye,AAK,5000,1';
_qq[79]:= '539,D1 Zala megye,AAK,5000,1';
_qq[80]:= '541,D2 Bacs-Kiskun megye,AAK,10000,1';

_qq[81]:= '542,D2 Baranya megye,AAK,10000,1';
_qq[82]:= '543,D2 Bekes megye,AAK,10000,1';
_qq[83]:= '544,D2 Borsod-Abauj-Zemplen megye,AAK,10000,1';
_qq[84]:= '545,D2 Csongrad megye,AAK,10000,1';
_qq[85]:= '546,D2 Fejer megye,AAK,10000,1';
_qq[86]:= '547,D2 Gyor-Moson-Sopron megye,AAK,10000,1';
_qq[87]:= '548,D2 Hajdu-Bihar megye,AAK,10000,1';
_qq[88]:= '549,D2 Heves megye,AAK,10000,1';
_qq[89]:= '550,D2 Jasz-Nagykun-Szolnok megye,AAK,10000,1';
_qq[90]:= '551,D2 Komarom-Esztergom megye,AAK,10000,1';

_qq[91]:= '552,D2 Nograd megye,AAK,10000,1';
_qq[92]:= '553,D2 Pest megye,AAK,10000,1';
_qq[93]:= '554,D2 Somogy megye,AAK,10000,1';
_qq[94]:= '555,D2 Szabolcs-Szatmar-Bereg megye,AAK,10000,1';
_qq[95]:= '556,D2 Tolna megye,AAK,10000,1';
_qq[96]:= '557,D2 Vas megye,AAK,10000,1';
_qq[97]:= '558,D2 Veszprem megye,AAK,10000,1';
_qq[98]:= '559,D2 Zala megye,AAK,10000,1';
_qq[99]:= '561,B Bacs-Kiskun megye,AAK,20000,1';
_qq[100]:= '562,B Baranya megye,AAK,20000,1';

_qq[101]:= '563,B Bekes megye,AAK,20000,1';
_qq[102]:= '564,B Borsod-Abauj-Zemplen megye,AAK,20000,1';
_qq[103]:='565,B Csongrad megye,AAK,20000,1';
_qq[104]:= '566,B Fejer megye,AAK,20000,1';
_qq[105]:= '567,B Gyor-Moson-Sopron megye,AAK,20000,1';
_qq[106]:= '568,B Hajdu-Bihar megye,AAK,20000,1';
_qq[107]:= '569,B Heves megye,AAK,20000,1';
_qq[108]:= '570,B Jasz-Nagykun-Szolnok megye,AAK,20000,1';
_qq[109]:= '571,B Komarom-Esztergom megye,AAK,20000,1';
_qq[110]:= '572,B Nograd megye,AAK,20000,1';

_qq[111]:= '573,B Pest megye,AAK,20000,1';
_qq[112]:= '574,B Somogy megye,AAK,20000,1';
_qq[113]:= '575,B Szabolcs-Szatmar-Bereg megye,AAK,20000,1';
_qq[114]:= '576,B Tolna megye,AAK,20000,1';
_qq[115]:= '577,B Vas megye,AAK,20000,1';
_qq[116]:= '578,B Veszprem megye,AAK,20000,1';
_qq[117]:= '579,B Zala megye,AAK,20000,1';
_qq[118]:= '604,U heti e-matrica,AAK,2975,1';
_qq[119]:= '605,U havi e-matrica,AAK,4780,1';
_qq[120]:= '606,U eves e-matrica,AAK,42980,1';

_qq[121]:= '644,D2 heti e-matrica,AAK,5950,1';
_qq[122]:= '645,D2 havi e-matrica,AAK,9560,1';
_qq[123]:= '646,D2 eves e-matrica,AAK,42980,1';

end;
}


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


function TForm1.Kodxor(_s: string): string;

var _y,_sw,_asc: byte;

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
                    procedure TForm1.ParameterBeolvaso;
// =============================================================================

begin
  TradeDbase.Connected := true;

  _pcs := 'SELECT * FROM PARAMETERS';

  with TradeQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;


  //  A program paramétereinek beolvasása:
  Logbair('A gép beolvassa a tárolt adatokat');
  with Tradequery do
    begin
      _elesitve    := FieldByName('ELESITVE').asInteger;
      _lastMatrica := FieldByName('LASTMATRICA').asInteger;
      _lastTelefon := FieldByName('LASTTELEFON').asInteger;

      _terminalid := trim(FieldByName('TERMINALID').AsString);
      _username := trim(FieldByName('USERNAME').AsString);
      _password := trim(FieldByName('JELSZO').AsString);
      close;
    end;
  Tradedbase.close;
  
  if _elesitve=11 then TanusitvanyGomb.Font.Color := clTeal
  else TanusitvanyGomb.Font.Color := clred;
  
end;

// =============================================================================
                         function TForm1.Getidos:string;
// =============================================================================


begin
  Result := TimeTostr(Now);
  if midstr(Result,2,1) = ':' then Result := '0' + Result;
end;



// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                     procedure TForm1.TelefonGombClick(Sender: TObject);
// =============================================================================

// Fömenü mobilfeltöltés menüpontja

begin
  Logbair(dupestring('-',80));
  Logbair('Telefonfeltöltésre klikkelt');
  Telefonform.showmodal;
end;

// =============================================================================
                   procedure TForm1.MatricaGombClick(Sender: TObject);
// =============================================================================

// Főmenü autópályamatrica menüeleme:

begin
  Logbair(dupestring('-',80));
  Logbair('Autopálya-matrica menüpontra klikkelt');
  Autopalyaform.showmodal;
end;

// =============================================================================
      procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
// =============================================================================

begin
  matricaregeneralo;
end;


procedure TForm1.TANUSITVANYGOMBClick(Sender: TObject);

var  _spk,_siker: integer;

begin
  if _elesitve<>11 then
    begin
      _siker := Ujtanusitvany.Showmodal;
      if  _siker>1 then
        begin
          Showmessage('SIKERTELEN TANUSITVÁNY AKTUALIZÁLÁS');
          exit;
        END;
      _elesitve := 11;
      _pcs := 'UPDATE PARAMETERS SET ELESITVE='+inttostr(_elesitve);
      TradeParancs(_pcs);
      ShowMessage('SIKERESEN MÓDOSITOTTAM A TANUSITVÁNYT');
      TanusitvanyGomb.Font.Color := clTeal;
      exit;
    end;
  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;
  gettanusitvany.showmodal;

  end;


function TForm1.Hundatetostr(_caldat: TDateTime): string;

var _h_ev,_h_ho,_h_nap: word;

begin
   _h_ev := yearof(_caldat);
   _h_ho := monthof(_caldat);
   _h_nap:= dayof(_caldat);

   result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;


procedure TForm1.BitBtn1Click(Sender: TObject);

var _spk: integer;

begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then exit;
  LogOlvasas.showmodal;
end;


end.

