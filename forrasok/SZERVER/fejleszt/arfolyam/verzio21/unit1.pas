unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, Grids, DBGrids, StdCtrls, ExtCtrls, Buttons, OleCtrls,
  SHDocVw, strutils, wininet, jpeg;

type
  TForm1 = class(TForm)
    VeszKilepo   : TTimer;

    Label1       : TLabel;
    Label3       : TLabel;
    Image10: TImage;
    Label2: TLabel;
    Label4: TLabel;
    Image11: TImage;
    Label5: TLabel;
    Shape1: TShape;
    Panel1: TPanel;
    KILEPO: TTimer;

    procedure AdatlapAtszamolo;
    procedure ControlHiba;
    procedure CsoportLapAtszamolo(_Tcs: integer);
    procedure CsoportTagSzamito;
    procedure ErtekControl;
    procedure FormActivate(Sender: TObject);

    procedure MindentAtszamolo;
    procedure VeszkilepoTimer(Sender: TObject);

    function DnemScan(_yDnem: string): integer;
    function EgyFuggvenyKiszamitasa(_fv: string): string;
    function Exemuvelet(_t1: real;_m1: integer;_t2: real):real;
    function Forintform(_int: integer): string;
    function Fuggvenybontas(_fuggveny: string): integer;
    function FvenybolNum(_subfugg: string): real;
    function Getcsoportertek: string;
    function Nulele(_ii: integer): string;
    function ScanIroda(_ptsz: integer): integer;
    function ScanIrsors(_irszam: integer): integer;
    function SubFvbontas(_sfg: string): integer;
    function Summatagok: real;
    function SumSubTagok: real;
    function Vegcontrol: boolean;
    function VesszobolPont(_md: string):string;
    function ZarojelKiszamolo(_subfgg: string): string;
    procedure KILEPOTimer(Sender: TObject);
   
                              
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var

  Form1: TForm1;
  _top,_left,_height,_width: integer;

  // ----------- konstans -----------------------------------------------

  _dnemDarab: integer = 28;
  _dnem:array[1..28] of string = ('EUR','USD','GBP','CHF','AUD','CAD','DKK',
           'JPY','NOK','SEK','CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH',
           'RUB','EUA','TRY','CNY','BAM','THB','BRL','MXN','NZD','RCH');

  // ----------------------------------------------------------------------

  _findData   : WIN32_FIND_DATA;

  _Host       : string = '185.43.207.99';
  _Port       : integer = 21100;
  _userid     : string = 'ebc-10%';
  _ftpPassword: string = 'klc+45%';
  _tab        : char = chr(9);

  _aktTegla  : TPanel;

  _aktivcsoportdarab: byte;
  _irodaDarab       : byte;
  _urlDarab         : byte;
  _urlnevek         : array[1..30] of string;
  _urlgombNevek     : array[1..30] of string;
  _urlgombszam      : array[1..30] of byte;

  _ptarszam,_ptarcsop,_ptarstat: array[1..200] of byte;
  _ptarnev,_ptarcim : array[1..200] of string;

  _csoportNevek : array[1..54] of string;
  _csoportszamok: array[1..54] of byte;
  _ccontrol: array[1..54] of boolean;

  _jErtek,_jfuggveny,_kertek,_kfuggveny: array[1..54,1..28] of string;
  _lErtek,_lfuggveny,_mErtek,_mFuggveny: array[1..54,1..28] of string;
  _nErtek,_nfuggveny,_oErtek,_oFuggveny: array[1..54,1..28] of string;
  _pErtek,_pfuggveny,_qErtek,_qFuggveny: array[1..54,1..28] of string;
  _rErtek,_rfuggveny,_sErtek,_sFuggveny: array[1..54,1..28] of string;

  _jBetuszin,_jHatterSzin,_kBetuszin,_kHatterszin: array[1..54,1..28] of TColor;
  _lBetuszin,_lHatterSzin,_mBetuszin,_mHatterszin: array[1..54,1..28] of TColor;
  _nBetuszin,_nHatterSzin,_oBetuszin,_oHatterszin: array[1..54,1..28] of TColor;
  _pBetuszin,_pHatterSzin,_qBetuszin,_qHatterszin: array[1..54,1..28] of TColor;
  _rBetuszin,_rHatterSzin,_sBetuszin,_sHatterszin: array[1..54,1..28] of TColor;

  _wErtek,_wfuggveny: array[1..28,1..9] of string;
  _wBetuszin,_wHatterszin: array[1..28,1..9] of TColor;

  _klimit: array[1..54,1..3] of integer;

  // -----------------  arrays -------------------------------------------------

  _bytetomb           : array[1..42000] of byte;
  _csoportTagDarab    : array[1..54] of integer;
  _csoportTagok       : array[1..54,1..15] of integer;
  _ttag,_sttag        : array[1..3] of string;
  _tertek,_sTertek    : array[1..3] of real;
  _tMuvelet,_stmuvelet: array[1..2] of byte;
  _markLista          : array[1..54] of byte;
  _listSs             : array[0..19] of byte;
  _listText           : array[0..19] of string;

  _arfolyamdir: string = '\ARFOLYAM';
  _mentesdir: string = '\ARFOLYAM\MENTES';

//  _arfolyamdir: string = '\TEMPARF';
//  _mentesdir: string = '\TEMPARF\MENTES';


  _lastVersionNumber: integer;
  _lastVersionDate  : string;
  _mamas            : string;
  _kellPecs         : boolean;

  // --------------------- colors ----------------------------------------------

  _aktBetuszin,
  _aktHatterszin: TColor;

  // --------------- integer ------------------------------------------------

  _ptop,_pleft,_kptop,_kpleft,_sByte: integer;

  _aktCsoport,
  _aktcsoportdarab,
  _aktiroda,
  _aktirodaszam,
  _aktweblapszam,
  _code,
  _csoportszam,
  _eMarkOszlop,
  _eMarksor,
  _getfx,_getfy,
  _kod,
  _kp,
  _lenfuggveny,
  _lensfg,
  _lenstence,
  _listdb,
  _markcsoport,
  _markdb,
  _mlen1,
  _muvss,
  _oszlop,
  _pp,
  _pp1,
  _qq,
  _skp,
  _sMarkOszlop,
  _sMarksor,
  _smuvss,
  _sor,
  _spp,
  _stagdarab,
  _stagss,
  _svp,
  _tagDarab,
  _tagss,
  _tallon,
  _tcs,
  _tcsoport,
  _toszlop,
  _tsor,
  _utolsoTag,
  _valasztottirodaszam,
  _vp,
  _xx,
  _zMenusor,
  _zMenuOszlop: integer;

  // --------------------- strings ---------------------------------------------

  _aktErtekString,
  _aktFuggvenyString,
  _aktIrodaCim,
  _aktIrodaNev,
  _akturl,
  _arftipus,
  _arfPath,
  _csoportNev,
  _eleje,
  _ertekstr,
  _muvjel,
  _nums,
  _valasztottirodanev,
  _valutanem,
  _vege,
  _workdir: string;

  // ------------------- boolean -----------------------------------------------

  _arfdatavaltozott,
  _double,
  _ezujprogram,
  _ismarker,
  _manual,
  _nyitottweblap,
  _signing,
  _zold: boolean;

  _ertek,
  _verem: real;

  _jLeft,_jTop,_jHeight,_jWidth: integer;
  _startsor,_startOszlop,_endsor,_endOszlop: integer;
  _aktsor,_aktoszlop: integer;
  _teglanev,_utteglanev,_aktfuggveny: string;

  _verzioszam : byte = 16;
  _adatverzio : byte;

implementation

uses Unit3, Unit4, Unit7, Unit9, Unit8, Unit12, Unit5, Unit6;

{$R *.dfm}

// =============================================================================
                  procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var _oke,i,j: integer;

begin
  _top  := 0;
  _left := 0;

  Top  := _top;
  Left := _left;

  Height := 729;
  Width  := 1366;

  // ---------------------------------------------------------------------------

  _mamas := leftstr(datetostr(date),10);

  _workDir := GetCurrentDir;
  for i := 1 to 54 do
    begin
      _csoportTagDarab[i] := 0;
      _csoportNevek[i] := 'NINCS IRODA';
      for j := 1 to 15 do _csoportTagok[i,j] := 0;
    end;

  _oke := Adatbetoltes.showmodal;
  if _oke<>1 then
    begin
      VeszKilepo.enabled := True;
      exit;
    end;

  _arfDataValtozott := false;
  MindentAtSzamolo;

  CsoportTagSzamito;

  _signing       := False;
  _manual        := False;
  _double        := False;
  _zold          := False;
  _isMarker      := False;
  _aktweblapszam := 255;

  Alaplap.showmodal;
  Kilepo.Enabled := true;
end;

// =============================================================================
               procedure TForm1.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.enabled := False;
  ArfdataIras.showmodal;
  Application.Terminate;
end;



// =============================================================================
           function Tform1.VesszobolPont(_md: string):string;
// =============================================================================

var _pos: integer;

begin
  result := _md;
  while True do
    begin
      _pos := pos(',',result);
      if _pos=0 then break;
      result[_pos] := '.';
    end;
end;


// =============================================================================
            procedure TForm1.VESZKILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Veszkilepo.Enabled := False;
  Application.Terminate;
end;


// =============================================================================
                     procedure TForm1.MindentAtszamolo;
// =============================================================================

var _csopdb: integer;

begin
  AdatlapAtszamolo;
  _tcsoport := 1;
  while _tcsoport<=54 do
    begin
      _csopdb := _csoportTagDarab[_tcsoport];
      if _csopdb>0 then CsoportLapAtszamolo(_tcsoport);
      inc(_tcsoport);
    end;
end;

// =============================================================================
                     procedure TForm1.AdatlapAtszamolo;
// =============================================================================

var _aktfveny: string;

begin

  _Tcsoport := 0; // ez jelzi, hogy az alaptáblát számolom ki

  // Elöször valutanemenként 1 oszloptól a 9-ik oszlopig kiszámitja az értéket
  _Tsor := 1;
  while _Tsor<=_dnemdarab do
    begin
      _Toszlop := 2;
      while _Toszlop<=9 do
        begin
          _aktfveny := trim(_wFuggveny[_Tsor,_Toszlop]);
           // Ha van az oszlopban függvény, akkor kiszámitja az értéket:
          if _aktfveny<>'' then _wErtek[_Tsor,_Toszlop] := Egyfuggvenykiszamitasa(_aktfveny);

          inc(_Toszlop);
          if _Toszlop=4 then inc(_Toszlop);
        end;

      _Toszlop := 1;
      _aktfveny := trim(_wFuggveny[_Tsor,_Toszlop]);
      if _aktfveny<>'' then _wErtek[_Tsor,_Toszlop] := Egyfuggvenykiszamitasa(_aktfveny);

      inc(_Tsor)
    end;
end;


// =============================================================================
          procedure TForm1.CsoportLapAtszamolo(_Tcs: integer);
// =============================================================================

var
    _aktfveny: string;
begin
  _tCsoport := _Tcs;
  _tsor := 1;
  while _tsor<=_dnemDarab do
    begin
      _aktfveny := trim(_jfuggveny[_Tcs,_tsor]);
      if _aktfveny<>'' then _jertek[_Tcs,_tsor] := EgyfuggvenyKiszamitasa(_aktfveny);

      _aktfveny := trim(_lFuggveny[_Tcs,_tsor]);
      if _aktfveny<>'' then _lErtek[_tcs,_tsor] := Egyfuggvenykiszamitasa(_aktfveny);

      _aktfveny := trim(_mFuggveny[_Tcs,_tsor]);
      if _aktfveny<>'' then _mErtek[_TCs,_tsor] := Egyfuggvenykiszamitasa(_aktfveny);

      _aktfveny := trim(_nFuggveny[_TCs,_tsor]);
      if _aktfveny<>'' then _nErtek[_TCs,_tsor] := Egyfuggvenykiszamitasa(_aktfveny);

      _aktfveny := trim(_oFuggveny[_TCs,_tsor]);
      if _aktfveny<>'' then _oErtek[_TCs,_tsor] := EgyfuggvenyKiszamitasa(_aktfveny);

      _aktfveny := trim(_pFuggveny[_TCs,_tsor]);
      if _aktfveny<>'' then _pErtek[_TCs,_tsor] := EgyfuggvenyKiszamitasa(_aktfveny);

      _aktfveny := trim(_qFuggveny[_TCs,_tsor]);
      if _aktfveny<>'' then _qErtek[_TCs,_tsor] := EgyfuggvenyKiszamitasa(_aktfveny);

      _aktfveny := trim(_rFuggveny[_TCs,_tsor]);
      if _aktfveny<>'' then _rErtek[_TCs,_tsor] := EgyfuggvenyKiszamitasa(_aktfveny);

      _aktfveny := trim(_sFuggveny[_TCs,_tsor]);
      if _aktfveny<>'' then _sErtek[_TCs,_tsor] := EgyfuggvenyKiszamitasa(_aktfveny);

      inc(_tsor);
    end;
end;

// =============================================================================
           function TForm1.EgyFuggvenyKiszamitasa(_fv: string): string;
// =============================================================================

var _td: integer;
    _aktErtek,_vegertek,_szorzo,_real: real;
    _talcsop,_taloszlop,_talsor,_egesz: integer;

begin
   _talcsop := _tcsoport;
   _talOszlop := _toszlop;
   _talsor := _tsor;

   result := '0';
   if _fv='' then exit;

   _tagdarab := FuggvenyBontas(_fv);
   _td := 1;
   while _td<=_tagdarab do
     begin
       _aktfuggveny := _ttag[_td];
       _aktertek := fvenybolNum(_aktfuggveny);
       _tErtek[_td] := _aktertek;
       inc(_td);
     end;
   _vegertek := SummaTagok;

   _tcsoport := _talcsop;
   _toszlop := _talOszlop;
   _tsor := _talsor;

   _szorzo := 100;
   if _tsor=8 then _szorzo := 1000;
   _real := _szorzo*_vegertek;
   _egesz := round(_real);
   result := floattostr(_egesz/_szorzo);
   result := vesszobolpont(result);
end;

// =============================================================================
          function Tform1.Fuggvenybontas(_fuggveny: string): integer;
// =============================================================================

begin
  _tagss := 0;
  _muvss := 0;
  _fuggveny := trim(_fuggveny);
  _lenfuggveny := length(_fuggveny);
  _pp := 1;
  _kp := 1;
  while _pp<=_lenfuggveny do
    begin
      _kod := ord(_fuggveny[_pp]);
      if _kod=40 then  // zárójel indul
        begin
          while _pp<=_lenfuggveny do
            begin
              _kod := ord(_fuggveny[_pp]);
              if _kod=41 then
                begin
                  inc(_pp);
                  if _pp<=_lenfuggveny then _kod := ord(_fuggveny[_pp]);
                  break;
                end;
              inc(_pp)
            end;
        end;

      if (_kod=42) or (_kod=45) or (_kod=47) or (_kod=43) then
         begin
           _vp := _pp-1;
           inc(_tagss);
           _ttag[_tagss] := midstr(_fuggveny,_kp,_pp-_kp);

           inc(_muvss);
           _tmuvelet[_muvss] := _kod;

           _kp := _pp+1;
         end;
      inc(_pp);
    end;

  inc(_tagss);
  _ttag[_tagss] := midstr(_fuggveny,_kp,_pp-_kp);
  result := _tagss;
end;

// =============================================================================
              function Tform1.FvenybolNum(_subfugg: string): real;
// =============================================================================

var _mDnem,_csopstr: string;

begin
  // a zárójeles függvényt késöbb

  _kod := ord(_subfugg[1]);
  case _kod of

    33: begin   // felkiáltójel
          _kod := ord(_subfugg[2]);
          _tOszlop := _kod-64;
          _mDnem := midstr(_subfugg,3,3);
          _tallon := _tsor;
          _tSor := Dnemscan(_mdnem);
          if _toszlop<10 then _nums := _wErtek[_tsor,_tOszlop]
          else _nums := getcsoportErtek;
          _tsor := _tallon;
        end;

    35: begin   // kettöskereszt
          _csopstr := midstr(_subFugg,2,2);
          _tallon := _tcsoport;
          _tcsoport := strtoint(_csopstr);
          _kod := ord(_subfugg[4]);
          _toszlop := _kod-64;
          _nums := GetcsoportErtek;
          _tcsoport := _tallon;
        end;

    65..90: begin   // betü
              _tOszlop := _kod - 64;
              if _toszlop<10 then _nums := _wErtek[_tsor,_tOszlop]
              else
              _nums := Getcsoportertek;
            end;

    48..57: begin   // számok
              _nums := vesszobolpont(_subFugg);
            end;

     40: begin   // zárójel
           _nums := ZarojelKiszamolo(_subfugg);
         end;
  end;
  _nums := vesszobolpont(_nums);
  val(_nums,result,_code);
  if _code<>0 then result := 0;
end;

// =============================================================================
                    function TForm1.Getcsoportertek: string;
// =============================================================================

begin
  if _toszlop>8 then _toszlop := _toszlop-9;
  case _toszlop of
    1: result := _jErtek[_tcsoport,_tsor];
    3: result := _lErtek[_tcsoport,_tsor];
    4: result := _mErtek[_tcsoport,_tsor];
    5: result := _nErtek[_tcsoport,_tsor];
    6: result := _oErtek[_tcsoport,_tsor];
    7: result := _pErtek[_tcsoport,_tsor];
    8: result := _qErtek[_tcsoport,_tsor];
    9: result := _rErtek[_tcsoport,_tsor];
   10: result := _sErtek[_tcsoport,_tsor];
  end;
end;


// =============================================================================
               function TForm1.DnemScan(_yDnem: string): integer;
// =============================================================================


var _y: integer;

begin
  result := 0;
  _y := 1;
  while _y<=_dnemdarab do
    begin
      if _dnem[_y] = _yDnem then
        begin
          result := _y;
          Break;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                       function TForm1.Summatagok: real;
// =============================================================================

var _mj1,_mj2: byte;

begin
  result := 0;
  case _tagdarab of
    1: result := _tErtek[1];
    2: result := ExeMuvelet(_tertek[1],_tmuvelet[1],_tertek[2]);
    3: begin
         _mj1 := _tMuvelet[1];
         _mj2 := _tMuvelet[2];
         if _mj1 = 42 then _mj1 := 46;
         if _mj2 = 42 then _mj2 := 46;
         if _mj1<_mj2 then
           begin
             result := exeMuvelet(_tertek[2],_tmuvelet[2],_tertek[3]);
             result := exemuvelet(_tertek[1],_tmuvelet[1],result);
           end else
           begin
             result := exeMuvelet(_tertek[1],_tmuvelet[1],_tertek[2]);
             result := exemuvelet(result,_tmuvelet[2],_tertek[3]);
           end;
       end;
  end;
end;

// =============================================================================
       function TForm1.Exemuvelet(_t1: real;_m1: integer;_t2: real):real;
// =============================================================================

begin
   result := 0;
   case _m1 of
     42: result := _t1*_t2;
     43: result := _t1+_t2;
     45: result := _t1-_t2;
     47: begin
           result := 0;
           if _t2<>0 then result := _t1/_t2;
         end;
   end;
end;

// =============================================================================
          function Tform1.ZarojelKiszamolo(_subfgg: string): string;
// =============================================================================

var _std: integer;
    _aktsfg: string;
    _subErtek,_aktertek: real;

begin
  _subfgg := trim(_subfgg);
  _subfgg := midstr(_subfgg,2,length(_subfgg)-2);
  _sTagdarab := SubFvBontas(_subfgg);
  _std := 1;
  while _std<=_sTagDarab do
    begin
      _aktsfg := _sttag[_std];
      _aktertek := fvenybolNum(_aktsfg);
      _stErtek[_std] := _aktertek;
       inc(_std);
     end;

  _subertek := SumSubTagok;
  result := FloatTostr(_subertek);
end;


// =============================================================================
          function Tform1.SubFvbontas(_sfg: string): integer;
// =============================================================================

begin
 // _tsor := 1;
  _stagss := 0;
  _smuvss := 0;
  _sfg := trim(_sfg);
  _lensfg := length(_sfg);
  _spp := 1;
  _skp := 1;
  while _spp<=_lensfg do
    begin
      _kod := ord(_sfg[_spp]);
      if (_kod=42) or (_kod=45) or (_kod=47) or (_kod=43) then
         begin
           _svp := _spp-1;
           inc(_stagss);
           _sttag[_stagss] := midstr(_sfg,_skp,_spp-_skp);

           inc(_smuvss);
           _stmuvelet[_smuvss] := _kod;

           _skp := _spp+1;
         end;
      inc(_spp);
    end;

  inc(_stagss);
  _sttag[_stagss] := midstr(_sfg,_skp,_spp-_skp);
  result := _stagss;
end;

// =============================================================================
                      function Tform1.SumSubTagok: real;
// =============================================================================

var _mj1,_mj2: byte;

begin
  result := 0;
  case _stagdarab of
    1: result := _stErtek[1];
    2: result := ExeMuvelet(_stertek[1],_stmuvelet[1],_stertek[2]);
    3: begin
         _mj1 := _stMuvelet[1];
         _mj2 := _stMuvelet[2];
         if _mj1 = 42 then _mj1 := 46;
         if _mj2 = 42 then _mj2 := 46;
         if _mj1<_mj2 then
           begin
             result := exeMuvelet(_stertek[2],_stmuvelet[2],_stertek[3]);
             result := exemuvelet(_stertek[1],_stmuvelet[1],result);
           end else
           begin
             result := exeMuvelet(_stertek[1],_stmuvelet[1],_stertek[2]);
             result := exemuvelet(result,_stmuvelet[2],_stertek[3]);
           end;
       end;
  end;
end;

// =============================================================================
             function TForm1.ScanIrsors(_irszam: integer): integer;
// =============================================================================

var _y: integer;

begin
   result := 0;
  _y := 1;
  while _y<=_irodaDarab do
    begin
      if _ptarszam[_y]=_irszam then
        begin
          result := _y;
          Break;
        end;
      inc(_y);
    end;
end;


// =============================================================================
           function TForm1.ScanIroda(_ptsz: integer): integer;
// =============================================================================

var _zz: integer;

begin
  _zz := 1;
  Result := 0;
  while _zz<=_irodadarab do
    begin
      if _ptsz=_ptarszam[_zz] then
        begin
          Result := _zz;
          Exit;
        end;
      inc(_zz);
    end;
end;

// =============================================================================
            function TForm1.Forintform(_int: integer): string;
// =============================================================================

var _ftlen,_pp: integer;

begin
  result := inttostr(_int);
  _ftlen := length(result);
  if _ftlen<4 then exit;
  if _ftlen>6 then
    begin
      _pp := _ftlen-6;
      result := leftstr(result,_pp)+','+midstr(result,_pp+1,3)+','+midstr(result,_pp+4,3);
      exit;
    end;
  _pp := _ftlen-3;
  result := leftstr(result,_pp)+','+midstr(result,_pp+1,3);
end;

// =============================================================================
               function TForm1.Nulele(_ii: integer): string;
// =============================================================================


begin
  result := inttostr(_ii);
  if _ii<10 then result := '0' + result;
end;

// =============================================================================
                    procedure TForm1.Csoporttagszamito;
// =============================================================================

var _aktcsoportNum,_aktirodaSzam,_csdb,i: integer;

begin
   for i := 1 to 54 do _csoportTagdarab[i] := 0;
   _qq := 1;

  while _qq<=_irodaDarab do
    begin
      _aktcsoportNum := _ptarcsop[_qq];
      _aktirodaszam :=  _ptarszam[_qq];

      if _aktcsoportnum>0 then
        begin
          _csdb := _csoportTagdarab[_aktcsoportNum];
          inc(_csdb);
          _csoportTagDarab[_aktcsoportNum] := _csdb;
          _csoportTagok[_aktcsoportnum,_csdb] := _aktIrodaSzam;
        end;

      inc(_qq);
    end;
end;

// =============================================================================
                    function TForm1.Vegcontrol: boolean;
// =============================================================================


var _jerts,_lerts,_merts,_nerts,_oerts,_perts,_qerts,_rerts,_serts: string;
    _jert,_lert,_mert,_nert,_oert,_pert,_qert,_rert,_sert,_cvetel,_celadas: real;
    _elszstr,_vetstr,_eladstr: string;
    _elszam:real;

begin
  Result := false;
  _tcs :=1;
  while _tcs<=54 do
    begin
      _aktcsoportDarab := _csoportTagDarab[_tcs];
      if _aktcsoportDarab=0 then
        begin
          inc(_tcs);
          continue;
        end;

      if not _ccontrol[_tcs] then
        begin
          inc(_tcs);
          continue;
        end;

      _tsor := 1;
      while _tsor<=_dnemdarab-1 do
        begin
          if (_tsor=18) OR (_tsor=7) OR (_tsor=9) OR (_tSor=10) OR (_tsor=12) then
            begin
              inc(_tsor);
              continue;
            end;
          _arftipus := 'elszámoló árfolyam';
          _jerts := _jErtek[_tcs,_tsor];
          val(_jerts,_jert,_code);

          if (_code<>0) or (_jert=0) then
            begin
              ControlHiba;
              Exit;
            end;

          _arftipus := 'vételi árfolyam';
          _lerts := _lertek[_tcs,_tsor];
          val(_lerts,_lert,_code);

          if (_code<>0) or (_lert=0) or (_lert>_jert) then
            begin
              ControlHiba;
              exit;
            end;

          _nerts := _nertek[_tcs,_tsor];
          val(_nerts,_nert,_code);

          if (_code<>0) or (_nert=0) or (_nert>_jert) then
            begin
              ControlHiba;
              exit;
            end;

           _perts := _pertek[_tcs,_tsor];
          val(_perts,_pert,_code);

          if (_code<>0) or (_pert=0) or (_pert>_jert) then
            begin
              ControlHiba;
              exit;
            end;

         // --------------------------------------------------------------

          _arftipus := 'eladási árfolyam';
          _merts := _mertek[_tcs,_tsor];
          val(_merts,_mert,_code);

          if (_code<>0) or (_mert=0) or (_mert<_jert) then
            begin
              ControlHiba;
              exit;
            end;

          _oerts := _oertek[_tcs,_tsor];
          val(_oerts,_oert,_code);

          if (_code<>0) or (_oert=0) or (_oert<_jert) then
            begin
              ControlHiba;
              exit;
            end;

           _qerts := _qertek[_tcs,_tsor];
          val(_qerts,_qert,_code);

          if (_code<>0) or (_qert=0) or (_qert<_jert) then
            begin
              ControlHiba;
              exit;
            end;

          // -------------------------------------------------------------------

          _arftipus := 'sajáthatáskörü vételi árfolyam';
          _rerts := _rertek[_tcs,_tsor];
          val(_rerts,_rert,_code);

          if (_code<>0) or (_rert=0) or (_rert>_jert) then
            begin
              ControlHiba;
              exit;
            end;

          _arftipus := 'sajáthatáskörü eladási árfolyam';

          _serts := _sertek[_tcs,_tsor];
          val(_serts,_sert,_code);

          if (_code<>0) or (_sert=0) or (_sert<_jert) then
            begin
              ControlHiba;
              exit;
            end;
        inc(_tsor);
      end;
      inc(_tcs);
    end;

   _tcs  := 0;
   _tsor := 1;

   while _tsor<=_dnemdarab-1 do
     begin
       if (_tsor=18) OR (_tsor=7) OR (_tsor=9) OR (_tSor=10) OR (_tsor=12) then
         begin
           inc(_tsor);
           continue;
         end;

       _arftipus := 'elszamoló árfolyam';
       _elszstr := _wertek[_tsor,1];
       _vetstr  := _wertek[_tsor,5];
       _eladstr := _wertek[_tsor,6];
       val(_elszstr,_elszam,_code);

       if _code<>0 then
         begin
           ControlHiba;
           Exit;
         end;

       _arftipus := 'vételi árfolyam';
       val(_vetstr,_cvetel,_code);
       if (_code<>0) or (_cvetel>_elszam) then
         begin
           ControlHiba;
           Exit;
         end;

       _arftipus := 'eladási árfolyam';
       val(_eladstr,_celadas,_code);
       if (_code<>0) or (_celadas<_elszam) then
         begin
           ControlHiba;
           Exit;
         end;
       inc(_tsor);
     end;
   Result := True;
end;

// =============================================================================
                          procedure TForm1.ControlHiba;
// =============================================================================

var _mess: string;

begin
  _mess := 'Hiba a '+ inttostr(_tcs)+'. csoport '+_dnem[_tsor]+' '+_arftipus+'-nál';
  ShowMessage(_mess);
end;

// =============================================================================
                           procedure TForm1.ErtekControl;
// =============================================================================


var _aktert,_diff,_szazalek,_elsnum: real;
     _elstring,_mess: string;

begin
  val(_aktertekstring,_aktert,_code);
  if _code<>0 then _aktert := 0;
  if _aktert=0 then exit;

  if _aktcsoport=0 then
    begin
      if (_startoszlop<>5) and (_startoszlop<>6) and (_startoszlop<>2) then exit;
      _elstring := _wertek[_startsor,_startoszlop];
      val(_elstring,_elsnum,_code);
      if _code<>0 then exit;
      if _elsnum=0 then exit;

      _diff := abs(_elsnum-_aktert);
      _szazalek := 100*(_diff/_elsnum);
      if _szazalek>=10 then
        begin
          _mess := 'A BEIRT ÉRTÉK MEGHAJADJA A 10 %-OT !';
          Messagedlg(_mess,mtWarning,[mbOk],0);
        end;
      exit;
    end;

  if _startOszlop<3 then exit;
  _elstring := _jertek[_aktcsoport,_startsor];
  val(_elstring,_elsnum,_code);
  if _code<>0 then exit;
  if _elsnum=0 then exit;

  _diff := abs(_elsnum-_aktert);
  _szazalek := 100*(_diff/_elsnum);
  if _szazalek>=10 then
    begin
      _mess := 'A BEIRT ÉRTÉK MEGHALADJA A 10 %-OT !';
      Messagedlg(_mess,mtWarning,[mbOk],0);
    end;
end;





end.

