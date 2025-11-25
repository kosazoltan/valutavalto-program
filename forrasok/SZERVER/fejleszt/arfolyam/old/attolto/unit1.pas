unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  wininet;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    ARFQUERY: TIBQuery;
    ARFDBASE: TIBDatabase;
    ARFTRANZ: TIBTransaction;
    Memo1: TMemo;

    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure Adatfeliras;
    procedure Arfparancs(_ukaz: string);

    function AdatLetoltes: boolean;
    function Getbyte: byte;
    function Getword: word;
    function Getstring: string;
    function Getszin: TColor;
    function VanInternet: boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _localpath: string = 'c:\_arfolyam\ARFDATA.DAT';
  _dnem: array[1..28] of string;

  _olvas: file of byte;
  _bytetomb: array[1..42000] of byte;

  _irodadarab,_urldarab,_darab,_oszlop,_adatverzio,_aktcsoportdarab: byte;
  _aktcsoport,_aktivcsoportdarab,_cc,_cs: byte;
  _ptarszam: array[1..180] of byte;
  _ptarnev: array[1..180] of string;

  _wertek,_wfuggveny: array[1..28,1..9] of string;
  _wbetuszin,_whatterszin: array[1..28,1..9] of TColor;
  _urlgombnevek,_urlnevek: array[1..30] of string;
  _urlgombszam: array[1..30] of byte;

  _ccontrol: array[1..54] of boolean;
  _csoportszamok: array[1..54] of byte;
  _csoportnevek: array[1..54] of string;

  _aktertekstring,_aktfuggvenystring,_pcs,_aktdnem,_csnev: string;
  _aktbetuszin,_akthatterszin: TColor;

  _pp,_qq: integer;
  _ss: byte;

  _hFtp,
  _hSearch,
  _hNet: Hinternet;

  _host: string = '185.43.207.99';
  _port: integer = 21100;
  _ftpPassword: string = 'klc+45%';
  _tab        : char = chr(9);
  _userid     : string = 'ebc-10%';


  _sikeres: boolean;

  _ptarcsop: array[1..180]of byte;
  _jErtek,_jfuggveny: array[1..54,1..28] of string;
  _jBetuszin,_jHatterszin: array[1..54,1..28] of TColor;

  _lErtek,_lfuggveny: array[1..54,1..28] of string;
  _lBetuszin,_lHatterszin: array[1..54,1..28] of TColor;

  _mErtek,_mfuggveny: array[1..54,1..28] of string;
  _mBetuszin,_mHatterszin: array[1..54,1..28] of TColor;

  _nErtek,_nfuggveny: array[1..54,1..28] of string;
  _nBetuszin,_nHatterszin: array[1..54,1..28] of TColor;

  _oErtek,_ofuggveny: array[1..54,1..28] of string;
  _oBetuszin,_oHatterszin: array[1..54,1..28] of TColor;

  _pErtek,_pfuggveny: array[1..54,1..28] of string;
  _pBetuszin,_pHatterszin: array[1..54,1..28] of TColor;

  _qErtek,_qfuggveny: array[1..54,1..28] of string;
  _qBetuszin,_qHatterszin: array[1..54,1..28] of TColor;

  _rErtek,_rfuggveny: array[1..54,1..28] of string;
  _rBetuszin,_rHatterszin: array[1..54,1..28] of TColor;

  _sErtek,_sfuggveny: array[1..54,1..28] of string;
  _sBetuszin,_sHatterszin: array[1..54,1..28] of TColor;
  _remoteFile : string = 'ARFDATA.DAT';

  _csoportdarab: byte = 54;
  _kLimit: array[1..54,1..3] of integer;
  _valss,_csoport,_uu: byte;
  _szorzo: word;
  _valutadarab: byte = 28;
  _sorveg: string = chr(13)+chr(10);

  _elsreal,_otpreal,_vetelreal,_eladasreal,_xeurreal,_xusdreal,_eladreal: real;
  _segedreal,_grandreal: real;
  _els,_otps,_segeds,_vetels,_eladass,_xeurs,_xusds,_grands: string;
  _segedfuggveny,_xeurfuggveny,_xusdfuggveny,_grandfuggveny: string;
  _elszamfuggveny,_vetelfuggveny,_eladasfuggveny: string;
  _elszambetu,_elszamhatter,_vetelhatter,_eladasbetu,_eladashatter: integer;
  _xusdhatter: integer;
  _otphatter,_segedhatter,_xeurhatter,xusdhatter,_grandhatter,_dnemhatter: integer;
  _otpbetu,_segedbetu,_dnembetu,_xeurbetu,_xusdbetu,_grandbetu: integer;
  _elszamolasiarfolyam,_otp,_seged,_vetel,_eladas,grand,_xeur,_xusd: integer;
  _code,_grand,_k1vetel,_k2vetel,_k1eladas,_k2eladas,_shkvetel,_shkeladas: integer;
  _vetelbetu: integer;

  implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  // A letöltött ARFDATA.DAT feldolgozása:
  if not AdatLetoltes then
    begin
      Showmessage('NEM SIKERÜLT LETÖLTENI AT ARFDATA.DAT-OT');
      EXIT;
    END;

  Assignfile(_olvas,_localPath);
  Reset(_olvas);

  // ---------------------------------------------------------------------------
  // Az iroda adatainak beolvasása:

  _adatverzio := Getbyte;       // Ez a verziószám   15 VAGY 16

  _IrodaDarab := Getbyte;       // Ennyi iroda van

  _qq := 1;
  while _qq<=_irodadarab do
    begin
      // Az iroda száma
      _ptarSzam[_qq] := GetByte;

      // Az iroda
      _ptarnev[_qq] := Getstring;

      // A pénztár csoportja:

      _ptarcsop[_qq]:= Getbyte;

      inc(_qq);
    end;


   // ----------------- INTERNET CIMEK ------------------------------

  _urlDarab := GetByte;    // internetcimek darabszáma

  _qq := 1;
  while _qq<=_urldarab do
    begin
      _pp := getbyte;
      _urlgombszam[_qq] := _pp;
      _urlGombNevek[_qq] := Getstring;
      _urlNevek[_qq] := GetString;
      inc(_qq);
    end;

  // ---------------- AZ ALAPTÁBLA ADATAI --------------------------------------

  _qq := 1;
  _darab := 28;
  IF _adatverzio=15 then _darab := 27;

  while _qq<=_Darab do
    begin
      _oszlop := 1;
      while _oszlop<=9 do
        begin
          _aktertekstring    := Getstring;
          _aktfuggvenystring := getstring;
          _aktbetuszin       := getszin;
          _akthatterszin     := Getszin;

          if (_aktfuggvenystring<>'') and (_aktbetuszin=clBlack) then _aktbetuszin :=clBlue;

          _wErtek[_qq,_oszlop]      := _aktertekstring;
          _wFuggveny[_qq,_oszlop]   := _aktfuggvenyString;
          _wBetuszin[_qq,_oszlop]   := _aktBetuszin;
          _wHatterszin[_qq,_oszlop] := _akthatterszin;


          inc(_oszlop);
          if _oszlop=4 then inc(_oszlop);
        end;
      inc(_qq);
    end;

  // --------- A csoportok ADATAI ----------------------------------------------

  // az aktiv csoportok darabszáma:


  _aktivcsoportDarab := getByte;

  _qq := 1;
  while _qq<=_aktivcsoportDarab do
    begin
      _aktCsoport := Getbyte;
      if _aktcsoport>100 then
        begin
          _aktcsoport := _aktcsoport-100;
          _ccontrol[_aktcsoport] := False;
        end else _ccontrol[_aktcsoport] := true;

      _csoportszamok[_qq] := _aktcsoport;
      _csoportNevek[_qq]:= GetString;

      _pp := 1;


      while _pp<=_darab do
        begin
          _jErtek[_aktcsoport,_pp]:= GetString;
          _aktfuggvenystring      := Getstring;
          _aktbetuszin            := Getszin;

          if (_aktfuggvenystring<>'') and (_aktbetuszin=clBlack) then _aktbetuszin :=clBlue;

          _jFuggveny[_aktcsoport,_pp]  := _aktfuggvenyString;
          _jBetuszin[_aktcsoport,_pp]  := _aktbetuszin;
          _jHatterSzin[_aktcsoport,_pp]:= GetSzin;

          // -------------------------------------------------------------------

          _lErtek[_aktcsoport,_pp] := GetString;
          _aktfuggvenystring       := Getstring;
          _aktbetuszin             := Getszin;

          if (_aktfuggvenystring<>'') and (_aktbetuszin=clBlack) then _aktbetuszin :=clBlue;

          _lFuggveny[_aktcsoport,_pp]  := _aktfuggvenystring;
          _lBetuszin[_aktcsoport,_pp]  := _aktbetuszin;
          _lHatterSzin[_aktcsoport,_pp]:= GetSzin;

          // -------------------------------------------------------------------

          _mErtek[_aktcsoport,_pp] := GetString;
          _aktfuggvenystring       := Getstring;
          _aktbetuszin             := Getszin;

          if (_aktfuggvenystring<>'') and (_aktbetuszin=clBlack) then _aktbetuszin :=clBlue;

          _mFuggveny[_aktcsoport,_pp]  := _aktfuggvenystring;
          _mBetuszin[_aktcsoport,_pp]  := _aktbetuszin;
          _mHatterSzin[_aktcsoport,_pp]:= GetSzin;

          // -------------------------------------------------------------------

          _nErtek[_aktcsoport,_pp] := GetString;
          _aktfuggvenystring       := Getstring;
          _aktbetuszin             := Getszin;

          if (_aktfuggvenystring<>'') and (_aktbetuszin=clBlack) then _aktbetuszin :=clBlue;

          _nFuggveny[_aktcsoport,_pp]  := _aktfuggvenystring;
          _nBetuszin[_aktcsoport,_pp]  := _aktbetuszin;
          _nHatterSzin[_aktcsoport,_pp]:= GetSzin;

          // -------------------------------------------------------------------

          _oErtek[_aktcsoport,_pp] := GetString;
          _aktfuggvenystring       := Getstring;
          _aktbetuszin             := Getszin;

          if (_aktfuggvenystring<>'') and (_aktbetuszin=clBlack) then _aktbetuszin :=clBlue;

          _oFuggveny[_aktcsoport,_pp]  := _aktfuggvenystring;
          _oBetuszin[_aktcsoport,_pp]  := _aktbetuszin;
          _oHatterSzin[_aktcsoport,_pp]:= GetSzin;

          // -------------------------------------------------------------------

          _pErtek[_aktcsoport,_pp] := GetString;
          _aktfuggvenystring       := Getstring;
          _aktbetuszin             := Getszin;

          if (_aktfuggvenystring<>'') and (_aktbetuszin=clBlack) then _aktbetuszin :=clBlue;

          _pFuggveny[_aktcsoport,_pp]  := _aktfuggvenystring;
          _pBetuszin[_aktcsoport,_pp]  := _aktbetuszin;
          _pHatterSzin[_aktcsoport,_pp]:= GetSzin;

          // -------------------------------------------------------------------

          _qErtek[_aktcsoport,_pp]:= GetString;
          _aktfuggvenystring      := Getstring;
          _aktbetuszin            := Getszin;

          if (_aktfuggvenystring<>'') and (_aktbetuszin=clBlack) then _aktbetuszin :=clBlue;

          _qFuggveny[_aktcsoport,_pp]  := _aktfuggvenystring;
          _qBetuszin[_aktcsoport,_pp]  := _aktbetuszin;
          _qHatterSzin[_aktcsoport,_pp]:= GetSzin;

           // -------------------------------------------------------------------


           _rErtek[_aktcsoport,_pp]:= GetString;
           _aktfuggvenystring      := Getstring;
           _aktbetuszin            := Getszin;

           if (_aktfuggvenystring<>'') and (_aktbetuszin=clBlack) then _aktbetuszin :=clBlue;

           _rFuggveny[_aktcsoport,_pp]  := _aktfuggvenystring;
           _rBetuszin[_aktcsoport,_pp]  := _aktbetuszin;
           _rHatterSzin[_aktcsoport,_pp]:= GetSzin;

          // -------------------------------------------------------------------

           _sErtek[_aktcsoport,_pp]:= GetString;
           _aktfuggvenystring      := Getstring;
           _aktbetuszin            := Getszin;

           if (_aktfuggvenystring<>'') and (_aktbetuszin=clBlack) then _aktbetuszin :=clBlue;

           _sFuggveny[_aktcsoport,_pp]  := _aktfuggvenystring;
           _sBetuszin[_aktcsoport,_pp]  := _aktbetuszin;
           _sHatterSzin[_aktcsoport,_pp]:= GetSzin;

          inc(_pp);
        end;

      _klimit[_aktcsoport,1] := GetWord;
      _klimit[_aktcsoport,2] := GetWord;
      _klimit[_aktcsoport,3] := GetWord;
      inc(_qq);

    end;

  BlockRead(_olvas,_bytetomb,3);
  closeFile(_olvas);

  ADATFELIRAS;
   // Adatok beirása az adatbázisokba:

  SHOWMESSAGE('Készen van');
end;

// =============================================================================
                    function TForm1.GetByte: byte;
// =============================================================================


begin
  Blockread(_olvas,_bytetomb,1);
  result := _Bytetomb[1];
end;

// =============================================================================
                  function TForm1.Getword: word;
// =============================================================================

var _lo,_hi: byte;

begin
  Blockread(_olvas,_bytetomb,2);
  _lo := _bytetomb[1];
  _hi := _bytetomb[2];
  result := _lo + trunc(256*_hi);
end;

// =============================================================================
               function TForm1.GetSzin: Tcolor;
// =============================================================================

var _tmp: real;
    _b1,_b2,_b3,_b4,_b5: byte;

begin
  Blockread(_olvas,_bytetomb,5);
  _b1 := _bytetomb[1];
  _b2 := _bytetomb[2];
  _b3 := _bytetomb[3];
  _b4 := _bytetomb[4];
  _b5 := _bytetomb[5];
  _tmp := _b5*sqr(65536);
  _tmp := _tmp + (256*(_b4*65536));
  _tmp := _tmp + (65536*_b3);
  _tmp := _tmp + (256*_b2);
  result := _b1 + trunc(_tmp);
end;


// =============================================================================
                 function TForm1.Getstring: string;
// =============================================================================

var _shossz,_y: integer;
    _kod: byte;

begin
  result := '';
  Blockread(_olvas,_bytetomb,1);
  _sHossz := _bytetomb[1];
  if _shossz=0 then exit;

  Blockread(_olvas,_bytetomb,_sHossz);
  _y := 1;
  while _y<=_sHossz do
    begin
      _kod := 255-_bytetomb[_y];
      result := result + chr(_kod);
      inc(_y);
    end;
end;

PROCEDURE TForm1.adatfeliras;

begin
  _pcs := 'SELECT * FROM VALUTANEMEK';
  arfdbase.connected := true;
  with arfQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
    end;
  while not arfQuery.Eof do
    begin
      _aktdnem := Arfquery.fieldByName('VALUTANEM').asstring;
      _ss := arfquery.FieldByName('SORSZAM').asInteger;
      _dnem[_ss] := _aktdnem;
      arfquery.next;
    end;
  ArfQuery.close;
  Arfdbase.close;

  // ----------------------------------------------------

  _pcs := 'DELETE FROM URLEK';
  aRFpARANCS(_PCS);

  _uu := 1;
  while _uu<=_urldarab do
    begin
      _pcs := 'INSERT INTO URLEK (URLSORSZAM,URLNEV,GOMBFELIRAT)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_urlgombszam[_uu]) + ',';
      _pcs := _pcs + chr(39) + _urlnevek[_uu] + CHR(39) + ',';
      _pcs := _pcs + chr(39) + _urlgombnevek[_uu] + chr(39) + ')';

      ArfParancs(_pcs);
      inc(_uu);
    end;  



  // ----------------------------------------------------


  _pcs := 'DELETE FROM CSOPORTOK';
  ArfParancs(_pcs);

  _csoport := 1;
  while _csoport<=_csoportdarab do
    begin
      _pcs := 'INSERT INTO CSOPORTOK (CSOPORT,CSOPORTNEV,STATUSZ,LIMIT1,LIMIT2,';
      _pcs := _pcs + 'LIMIT3)' + _sorveg;

      _cs := _csoportszamok[_csoport];
      _cc := 0;
      if _ccontrol[_csoport] then _cc := 1;

      _csnev := _csoportnevek[_csoport];

      _pcs := _pcs + 'VALUES (' + inttostr(_cs) + ',';
      _pcs := _pcs + chr(39) + _csnev + chr(39) + ',';
      _pcs := _pcs + inttostr(_cc) + ',';





  // -----------------------------------------------------

  _pcs := 'DELETE FROM ALAPTABLA';
  ArfParancs(_pcs);

  _valss := 1;
  while _valss<=_valutadarab do
    begin
      _pcs := 'INSERT INTO ALAPTABLA (VALUTANEM,ELSZAMOLASIARFOLYAM,';
      _pcs := _pcs + 'OTP,SEGED,VETEL,ELADAS,XEUR,XUSD,GRAND,ELSZAMFUGGVENY,';
      _pcs := _pcs + 'SEGEDFUGGVENY,VETELFUGGVENY,ELADASFUGGVENY,XEURFUGGVENY,';
      _pcs := _pcs + 'XUSDFUGGVENY,GRANDFUGGVENY,ELSZAMBETU,OTPBETU,VALUTANEMBETU,';
      _pcs := _pcs + 'SEGEDBETU,VETELBETU,ELADASBETU,XEURBETU,XUSDBETU,GRANDBETU,';
      _pcs := _pcs + 'ELSZAMHATTER,OTPHATTER,VALUTANEMHATTER,VETELHATTER,ELADASHATTER,';
      _pcs := _pcs + 'XEURHATTER,XUSDHATTER,GRANDHATTER)' + _sorveg;

      _aktdnem := _dnem[_valss];
      _szorzo := 100;
      if _aktdnem='JPY' then _szorzo := 1000;

      _els := _wertek[_valss,1];
      val(_els,_elsreal,_code);
      if _code<>0 then _elsreal := 0;
      _elszamolasiarfolyam := trunc(_szorzo*_elsreal);

      _otps := _wertek[_valss,2];
      val(_otps,_otpreal,_code);
      if _code<>0 then _otpreal := 0;
      _otp := trunc(_szorzo*_otpreal);

      _segeds := _wertek[_valss,3];
      val(_segeds,_segedreal,_code);
      if _code<>0 then _segedreal := 0;
      _seged := trunc(_szorzo*_segedreal);

      _vetels := _wertek[_valss,5];
      val(_vetels,_vetelreal,_code);
      if _code<>0 then _vetelreal := 0;
      _vetel := trunc(_szorzo*_vetelreal);

      _eladass := _wertek[_valss,6];
      val(_eladass,_eladasreal,_code);
      if _code<>0 then _eladasreal := 0;
      _eladas := trunc(_szorzo*_eladasreal);

      _xeurs := _wertek[_valss,7];
      val(_xeurs,_xeurreal,_code);
      if _code<>0 then _xeurreal := 0;
      _xeur := trunc(_szorzo*_xeurreal);

      _xusds := _wertek[_valss,8];
      val(_xUsds,_xusdreal,_code);
      if _code<>0 then _xUsdreal := 0;
      _xUsd := trunc(_szorzo*_xUsdreal);

      _Grands := _wertek[_valss,9];
      val(_grands,_grandreal,_code);
      if _code<>0 then _grandreal := 0;
      _grand := trunc(_szorzo*_grandreal);

      // -------------------------------------------

      _elszamfuggveny := _wfuggveny[_valss,1];
      _segedfuggveny  := _wfuggveny[_valss,3];
      _vetelfuggveny  := _wfuggveny[_valss,5];
      _eladasfuggveny := _wfuggveny[_valss,6];
      _xeurfuggveny   := _wfuggveny[_valss,7];
      _xUsdfuggveny   := _wfuggveny[_valss,8];
      _Grandfuggveny  := _wfuggveny[_valss,9];


      _pcs := _pcs + 'VALUES (' + CHR(39) + _aktdnem +chr(39) + ',';
      _pcs := _pcs + inttostr(_elszamolasiarfolyam)+',';
      _pcs := _pcs + inttostr(_otp) + ',';
      _pcs := _pcs + inttostr(_seged) + ',';
      _pcs := _pcs + inttostr(_vetel) + ',';
      _pcs := _pcs + inttostr(_eladas) + ',';
      _pcs := _pcs + inttostr(_xeur) + ',';
      _pcs := _pcs + inttostr(_xusd) + ',';
      _pcs := _pcs + inttostr(_grand) + ',';

      // ----------------------------------------

      _pcs := _pcs + chr(39) + _elszamfuggveny + chr(39) + ',';
      _pcs := _pcs + chr(39) + _segedfuggveny + chr(39) + ',';
      _pcs := _pcs + chr(39) + _vetelfuggveny + chr(39) + ',';
      _pcs := _pcs + chr(39) + _eladasfuggveny + chr(39) + ',';
      _pcs := _pcs + chr(39) + _xeurfuggveny + chr(39) + ',';
      _pcs := _pcs + chr(39) + _xusdfuggveny + chr(39) + ',';
      _pcs := _pcs + chr(39) + _grandfuggveny + chr(39) + ',';

      // -------------------------------------------------------

      _elszambetu := _wBetuszin[_valss,1];
      _otpbetu    := _wBetuszin[_valss,2];
      _segedbetu  := _wBetuszin[_valss,3];
      _dnembetu   := _wbetuszin[_valss,4];
      _vetelbetu  := _wBetuszin[_valss,5];
      _eladasbetu := _wBetuszin[_valss,6];
      _xeurbetu   := _wBetuszin[_valss,7];
      _xusdbetu   := _wBetuszin[_valss,8];
      _grandbetu  := _wBetuszin[_valss,9];




      _pcs := _pcs + inttostr(_elszambetu) + ',';
      _pcs := _pcs + inttostr(_otpbetu) + ',';
      _pcs := _pcs + inttostr(_dnembetu) + ',';
      _pcs := _pcs + inttostr(_segedbetu) + ',';
      _pcs := _pcs + inttostr(_vetelbetu) + ',';
      _pcs := _pcs + inttostr(_eladasbetu) + ',';
      _pcs := _pcs + inttostr(_xeurbetu) + ',';
      _pcs := _pcs + inttostr(_xusdbetu) + ',';
      _pcs := _pcs + inttostr(_grandbetu) + ',';

      _elszamhatter := _wHatterszin[_valss,1];
      _otphatter    := _wHatterszin[_valss,2];
      _segedhatter  := _wHatterszin[_valss,3];
      _dnemHatter   := _wHatterszin[_valss,4];
      _vetelHatter  := _wHatterszin[_valss,5];
      _eladasHatter := _wHatterszin[_valss,6];
      _xeurHatter   := _wHatterszin[_valss,7];
      _xusdHatter   := _wHatterszin[_valss,8];
      _grandHatter  := _wHatterszin[_valss,9];



      _pcs := _pcs + inttostr(_elszamhatter) + ',';
      _pcs := _pcs + inttostr(_otphatter) + ',';
      _pcs := _pcs + inttostr(_dnemhatter) + ',';
      _pcs := _pcs + inttostr(_segedhatter) + ',';
      _pcs := _pcs + inttostr(_vetelhatter) + ',';
      _pcs := _pcs + inttostr(_eladashatter) + ',';
      _pcs := _pcs + inttostr(_xeurhatter) + ',';
      _pcs := _pcs + inttostr(_xusdhatter) + ',';
      _pcs := _pcs + inttostr(_grandhatter) + ')';

      Arfparancs(_pcs);
      inc(_valss);
    end;

  // ----------------------------------------------------

  _pcs := 'DELETE FROM ARFOLYAMOK';
  ArfParancs(_pcs);
  _csoport := 1;
  while _csoport<=_csoportdarab do
    begin
      mEMO1.Lines.add('Csoport: '+ INTTOSTR(_CSOPORT));
      _valss := 1;
      while _valss<=28 do
        begin

          _pcs := 'INSERT INTO ARFOLYAMOK (CSOPORT,VALUTANEM,ELSZAMOLASIARFOLYAM,';
          _pcs := _pcs + 'ELSZAMOLASFUGGVENY,ELSZAMOLASBETU,ELSZAMOLASHATTER,';
          _pcs := _pcs + 'VETELIARFOLYAM,VETELFUGGVENY,VETELBETU,VETELHATTER,';
          _pcs := _pcs + 'ELADASIARFOLYAM,ELADASFUGGVENY,ELADASBETU,ELADASHATTER,';
          _pcs := _pcs + 'K1VETELIARFOLYAM,K1VETELFUGGVENY,K1VETELBETU,K1VETELHATTER,';
          _pcs := _pcs + 'K1ELADASIARFOLYAM,K1ELADASFUGGVENY,K1ELADASBETU,K1ELADASHATTER,';
          _pcs := _pcs + 'K2VETELIARFOLYAM,K2VETELFUGGVENY,K2VETELBETU,K2VETELHATTER,';
          _pcs := _pcs + 'K2ELADASIARFOLYAM,K2ELADASFUGGVENY,K2ELADASBETU,K2ELADASHATTER,';
          _pcs := _pcs + 'SHKVETELIARFOLYAM,SHKVETELFUGGVENY,SHKVETELBETU,SHKVETELHATTER,';
          _pcs := _pcs + 'SHKELADASIARFOLYAM,SHKELADASFUGGVENY,SHKELADASBETU,SHKELADASHATTER)'+_SORVEG;

          _pcs := _pcs + 'VALUES (' + inttostr(_csoport) + ',';

          _aktdnem := _dnem[_valss];
          _pcs := _pcs + chr(39) + _dnem[_valss] + chr(39) + ',';

          Memo1.Lines.add(_aktdnem);

      // ----------------------------------------------------------------------

          _els := _jertek[_csoport,_valss];
          val(_els,_elsreal,_code);
          if _code<>0 then _elsreal := 0;

          _szorzo := 100;
          if _aktdnem='JPY' then _szorzo := 1000;

          _elszamolasiarfolyam := trunc(_szorzo*_elsreal);
          _pcs := _pcs + inttostr(_elszamolasiarfolyam) + ',';

      // ----------------------------------------------------------------------

          _elszamfuggveny := _jFuggveny[_csoport,_valss];
          _elszambetu     := _jbetuszin[_csoport,_valss];
          _elszamhatter   := _jHatterszin[_csoport,_valss];

          _pcs := _pcs + chr(39) + _elszamfuggveny + chr(39) + ',';
          _pcs := _pcs + inttostr(_elszambetu) + ',';
          _pcs := _pcs + inttostr(_elszamhatter) + ',';

      // ----------------------------------------------------------------------

          _vetels := _lertek[_csoport,_valss];
          val(_vetels,_vetelreal,_code);
          if _code<>0 then _vetelreal := 0;
          _vetel := trunc(_szorzo*_vetelreal);

          _eladass := _mertek[_csoport,_valss];
          val(_eladass,_eladreal,_code);
          if _code<>0 then _eladreal := 0;
          _eladas := trunc(_szorzo*_eladreal);

          _vetels := _nertek[_csoport,_valss];
          val(_vetels,_vetelreal,_code);
          if _code<>0 then _vetelreal := 0;
          _k1vetel := trunc(_szorzo*_vetelreal);

          _eladass := _oertek[_csoport,_valss];
          val(_eladass,_eladreal,_code);
          if _code<>0 then _eladreal := 0;
          _k1eladas := trunc(_szorzo*_eladreal);

          _vetels := _Pertek[_csoport,_valss];
          val(_vetels,_vetelreal,_code);
          if _code<>0 then _vetelreal := 0;
          _k2vetel := trunc(_szorzo*_vetelreal);

          _eladass := _Qertek[_csoport,_valss];
          val(_eladass,_eladreal,_code);
          if _code<>0 then _eladreal := 0;
          _k2eladas := trunc(_szorzo*_eladreal);

          _vetels := _Rertek[_csoport,_valss];
          val(_vetels,_vetelreal,_code);
          if _code<>0 then _vetelreal := 0;
          _SHKvetel := trunc(_szorzo*_vetelreal);

          _eladass := _sertek[_csoport,_valss];
          val(_eladass,_eladreal,_code);
          if _code<>0 then _eladreal := 0;
          _shkeladas := trunc(_szorzo*_eladreal);

          // ------------------------------------------------

          _vetelfuggveny := _lFuggveny[_csoport,_valss];
          _vetelbetu     := _lbetuszin[_csoport,_valss];
          _vetelhatter   := _lHatterszin[_csoport,_valss];

          _pcs := _pcs + inttostr(_vetel) + ',';
          _pcs := _pcs + chr(39) + _vetelfuggveny + chr(39) + ',';
          _pcs := _pcs + inttostr(_vetelbetu) + ',';
          _pcs := _pcs + inttostr(_vetelhatter) + ',';

          // --------------------------------------------------

          _eladasfuggveny := _mFuggveny[_csoport,_valss];
          _eladasbetu     := _mbetuszin[_csoport,_valss];
          _eladashatter   := _mHatterszin[_csoport,_valss];

          _pcs := _pcs + inttostr(_eladas) + ',';
          _pcs := _pcs + chr(39) + _eladasfuggveny + chr(39) + ',';
          _pcs := _pcs + inttostr(_eladasbetu) + ',';
          _pcs := _pcs + inttostr(_eladashatter) + ',';

          // --------------------------------------------------

          _vetelfuggveny := _nFuggveny[_csoport,_valss];
          _vetelbetu     := _nbetuszin[_csoport,_valss];
          _vetelhatter   := _nHatterszin[_csoport,_valss];

          _pcs := _pcs + inttostr(_k1vetel) + ',';
          _pcs := _pcs + chr(39) + _vetelfuggveny + chr(39) + ',';
          _pcs := _pcs + inttostr(_vetelbetu) + ',';
          _pcs := _pcs + inttostr(_vetelhatter) + ',';

          // --------------------------------------------------

          _eladasfuggveny := _oFuggveny[_csoport,_valss];
          _eladasbetu     := _obetuszin[_csoport,_valss];
          _eladashatter   := _oHatterszin[_csoport,_valss];

          _pcs := _pcs + inttostr(_k1eladas) + ',';
          _pcs := _pcs + chr(39) + _eladasfuggveny + chr(39) + ',';
          _pcs := _pcs + inttostr(_eladasbetu) + ',';
          _pcs := _pcs + inttostr(_eladashatter) + ',';

          // --------------------------------------------------

          _vetelfuggveny := _pFuggveny[_csoport,_valss];
          _vetelbetu     := _pbetuszin[_csoport,_valss];
          _vetelhatter   := _pHatterszin[_csoport,_valss];

          _pcs := _pcs + inttostr(_k2vetel) + ',';
          _pcs := _pcs + chr(39) + _vetelfuggveny + chr(39) + ',';
          _pcs := _pcs + inttostr(_vetelbetu) + ',';
          _pcs := _pcs + inttostr(_vetelhatter) + ',';

          // --------------------------------------------------

          _eladasfuggveny := _qFuggveny[_csoport,_valss];
          _eladasbetu     := _qbetuszin[_csoport,_valss];
          _eladashatter   := _qHatterszin[_csoport,_valss];

          _pcs := _pcs + inttostr(_k2eladas) + ',';
          _pcs := _pcs + chr(39) + _eladasfuggveny + chr(39) + ',';
          _pcs := _pcs + inttostr(_eladasbetu) + ',';
          _pcs := _pcs + inttostr(_eladashatter) + ',';

          // --------------------------------------------------

          _vetelfuggveny := _rFuggveny[_csoport,_valss];
          _vetelbetu     := _rbetuszin[_csoport,_valss];
          _vetelhatter   := _rHatterszin[_csoport,_valss];

          _pcs := _pcs + inttostr(_shkvetel) + ',';
          _pcs := _pcs + chr(39) + _vetelfuggveny + chr(39) + ',';
          _pcs := _pcs + inttostr(_vetelbetu) + ',';
          _pcs := _pcs + inttostr(_vetelhatter) + ',';

          // --------------------------------------------------

          _eladasfuggveny := _sFuggveny[_csoport,_valss];
          _eladasbetu     := _sbetuszin[_csoport,_valss];
          _eladashatter   := _sHatterszin[_csoport,_valss];

          _pcs := _pcs + inttostr(_shkeladas) + ',';
          _pcs := _pcs + chr(39) + _eladasfuggveny + chr(39) + ',';
          _pcs := _pcs + inttostr(_eladasbetu) + ',';
          _pcs := _pcs + inttostr(_eladashatter) + ')';

          // --------------------------------------------------

          Arfparancs(_PCS);
          inc(_valss);
        end;
      inc(_csoport);
    end;



end;

procedure TForm1.Arfparancs(_ukaz: string);

begin
  arfdbase.Connected := true;
  if arftranz.InTransaction then arftranz.commit;
  Arftranz.StartTransaction;
  with aRFQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Arftranz.commit;
  Arfdbase.close;
end;


// =============================================================================
                  function TForm1.AdatLetoltes: boolean;
// =============================================================================


begin
  Result := False;

  if not VanInternet then
    begin
      ShowMessage('NINCS INTERNET !');
      exit;
    end;

  _hnet := InternetOpen(pchar('LoadFormServer'),INTERNET_OPEN_TYPE_DIRECT,nil,nil,0);

  if _hNet = nil then
    begin
      Showmessage('Nem tudtam fellépni az internetre ...');
      exit;
    end;

  // -------------------  connect to the server  -------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_Host),_Port,Pchar(_userId),
                           PChar(_ftpPassword),INTERNET_SERVICE_FTP,
                           INTERNET_FLAG_PASSIVE,
                           0);

  // ---------------------------------------------------------------------------

   IF _hFTP = nil then
    begin
      Showmessage('Itt sem sikerült csatlakozni a szerverhez !');
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // ----------------------- Change directory ---*****************--------------

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('\arfolyam'));

  if not _sikeres then
    begin
      Showmessage('Nem sikerült belépni az árfolyamkönyvtárba !');
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // --------ENDNEWPRG ---------------------------------------------------------

  _remoteFile := 'ARFDATA.DAT';
 
  if Fileexists(_localpath) then DeleteFile(_localpath);

  Result := FtpGetfile(_hFTP,pchar(_remoteFile),pchar(_localPath),
                                           False,0,FTP_TRANSFER_TYPE_BINARY,0);

  if not Result then showmessage('Hiba történt a letöltés közben');

  // --------------------------------------------------------------------------

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

end;

// =============================================================================
                 function TForm1.VanInternet: boolean;
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


end.
