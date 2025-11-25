unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBTable, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, strutils, DateUtils, Buttons, Grids, Calendar, printers, jpeg;

type
  TNAPIKEZD = class(TForm)

    BfTabla   : TIBTable;
    BfQuery   : TIBQuery;
    BfDbase   : TIBDatabase;
    BfTranz   : TIBTransaction;

    KilepoTimer     : TTimer;

    PrintDialog1    : TPrintDialog;
    HZQUERY: TIBQuery;
    HZDBASE: TIBDatabase;
    HZTRANZ: TIBTransaction;
    KEZDQUERY: TIBQuery;
    KEZDTABLA: TIBTable;
    KEZDDBASE: TIBDatabase;
    KEZDTRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    NAPTAR: TCalendar;
    NYOMTATOGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    ELOHOGOMB: TBitBtn;
    KOVHOGOMB: TBitBtn;
    EVPANEL: TPanel;
    HONAPPANEL: TPanel;
    DAYPANEL: TPanel;
    NAPNEVPANEL: TPanel;
    ERTEKTARPANEL: TPanel;
    TAKAROPANEL: TPanel;
    LOGOPANEL: TPanel;
    Label1: TLabel;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Label2: TLabel;
    KFTPANEL: TPanel;
    valutatranz: TIBTransaction;
    NAPLOQUERY: TIBQuery;
    NAPLODBASE: TIBDatabase;
    NAPLOTRANZ: TIBTransaction;
    Image1: TImage;


    procedure Egyadatsor;
    procedure ElohoGombClick(Sender: TObject);
    procedure EvhonapDisplay;
    procedure Fejlec(_psor: integer);
    procedure FormActivate(Sender: TObject);
    procedure Gethavinyito;
    procedure KilepoTimerTimer(Sender: TObject);
    procedure Kozepre(_psor:integer;_text: string);
    procedure KovHoGombClick(Sender: TObject);
    procedure Lablec(_psor: integer);
    procedure NaploNapiPrintBejegyzes;
    procedure KezdijNyomtatas;

    procedure NyomtatoGombClick(Sender: TObject);
    procedure Ujoldaltnyit;
    procedure VisszaGombClick(Sender: TObject);

    function EloKieg(_s: string;_hh: integer): string;
    function EtarScan(_et:integer): integer;
    function Form11(_int: integer): string;
    function FtFormalo(_ft: integer): string;
    function HunDateTostr(_caldat: TDatetime): string;
    function KovetkezoNap(_np: string): string;
    function Nulele(_n: byte): string;
    function NulKieg(_i,_hh: integer): string;
    function PtarKepzo(_pts: string): string;
    procedure NAPTARChange(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NAPIKEZD: TNAPIKEZD;

   _etarszam: array[1..8] of integer = (10,20,40,50,63,75,120,145);

   _etarnev: array[1..8] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT','DEBRECEN',
                                 'NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR');

  _honev: array[1..12] of string  = ('január','február','március','április','május',
                  'junius','július','augusztus','szeptember','október','november',
                  'december');

  _napnev: array[1..7] of string = ('hétfõ','kedd','szerda','csütörtök','péntek',
                   'szombat','vasárnap');

  _tranztext: array[1..2] of string = ('forint - átadás','forint - átvétel');

  _sorveg: string = chr(13)+chr(10);

  _keret : TRect;

  _kertDatum,
  _tegnap,
  _aktdatum: TDateTime;

  _etarss: byte;

  _aktev,
  _aktho,
  _akty,
  _aktm,
  _aktd,
  _ertektar,
  _height,
  _hoUtolsonap,
  _width: word;

  _aktoldal,
  _kezdosorszam,
  _utolsosorszam,
  _aktosszeg,
  _bebizdarab,
  _bedarab,
  _code,
  _eladas,
  _eloev,
  _eloho,
  _gepfunkcio,
  _hnap,
  _kertday,
  _kertdekad,
  _kertev,
  _kertho,
  _kezelesidij,
  _kibizdarab,
  _kidarab,
  _ksorszam,
  _lapszelesseg,
  _lastsorszam,
  _lastZaro,
  _mresult,
  _nyito,
  _osszbizonylat,
  _osszbevetel,
  _osszkiadas,
  _osszft,
  _osszesft,
  _osszbizdarab,
  _osszesen,
  _prisor,
  _racsbsor,
  _racsksor,
  _recno,
  _spk,
  _storno,
  _tranzss,
  _utsorszam,
  _vetel,
  _zaro: integer;


  _aktbizonylat,
  _aktnap,
  _aktptarszam,
  _betujel,
  _bfejnev,
  _btetnev,
  _bizonylatszam,
  _datumstring,
  _elofarok,
  _elojel,
  _farok,
  _hzFilenev,
  _istring,
  _kertnap,
  _kertCondNap,
  _kezdfilenev,
  _kezdonap,
  _kftnev,
  _kotojel,
  _lastnap,
  _lezartnap,
  _mamas,
  _megnyitottnap,
  _mondat,
  _pcs,
  _penztarkod,
  _penztarnev,
  _penztarcim,
  _tarspenztarkod,
  _tegnaps,
  _tipus,
  _utolsonap,
  _varosnev: string;

  _dOke,
  _voltvetel,
  _volteladas: boolean;

  _textiras,
  _nyomtat,
  _textolvas: textfile;

function napikezdijrutin: integer; stdcall;
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';

implementation

{$R *.dfm}


// =============================================================================
                   function napikezdijrutin: integer; stdcall;
// =============================================================================

begin
  Napikezd := TNapikezd.Create(Nil);
  result := Napikezd.Showmodal;
  Napikezd.Free;
end;

// =============================================================================
                procedure TNAPIKEZD.FormActivate(Sender: TObject);
// =============================================================================

BEGIN

  TakaroPanel.visible := False;

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  top     := trunc((_height-590)/2);
  Left    := trunc((_width-817)/2);

  _mamas  := Hundatetostr(date);

  // Hardware adatok beolvasása:

  _pcs := 'SELECT * FROM HARDWARE';
  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _gepfunkcio    := FieldByName('GEPFUNKCIO').asInteger;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
      _lezartnap     := trim(FieldByName('LEZARTNAP').AsString);
      _kftnev        := trim(FieldByNAme('KFTNEV').AsString);
      close;
    end;

  KftPanel.Caption := 'Exclusive Best Change Zrt';
  KftPanel.Repaint;

  // Pénztár adatok beolvasása:

  _pcs := 'SELECT * FROM PENZTAR';
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _penztarKod := trim(FieldByName('PENZTARKOD').asString);
      _penztarNev := trim(FieldByNAme('PENZTARNEV').asstring);
      _penztarCim := trim(FieldByName('PENZTARCIM').asString);
      close;
    end;

  ValutaQuery.close;
  ValutaDbase.close;

  // Ha ez nem értéktár, akkor rossz helyen vagyunk

  if _gepFunkcio<>2 then
     begin
       _Mresult := 2;
       KilepoTimer.Enabled := True;
       exit;
     end;

  EvhonapDisplay;
end;

// =============================================================================
                     procedure TNAPIKEZD.EvhonapDisplay;
// =============================================================================

begin

  _aktEv    := Naptar.Year;
  _aktHo    := Naptar.Month;
  _kertDay  := Naptar.day;
  _aktDatum := Naptar.CalendarDate;
  _hNap     := dayOfTheWeek(_aktDatum);

  EvPanel.Caption    := inttostr(_aktEv);
  HonapPanel.Caption := _honev[_aktHo];
  DayPanel.Caption   := inttostr(_kertDay);
  NapnevPanel.Caption:= _napnev[_hNap];

  EvPanel.repaint;
  HonapPanel.repaint;
  DayPanel.Repaint;
  NapnevPanel.Repaint;

  ActiveControl := NyomtatoGomb;
end;


// =============================================================================
          procedure TNAPIKEZD.NyomtatoGombClick(Sender: TObject);
// =============================================================================

// Amikor a naptár rendben van ide kattont:

begin
  // Meghatározza  a napot, melyet nyomtatni kell:

  _kertDatum := Naptar.CalendarDate;
  _kertev    := Naptar.year;
  _kertho    := Naptar.Month;
  _kertday   := Naptar.Day;

  _kertnap   := Hundatetostr(_kertdatum);

  // Meghatározza a farok és elöfarok értéket:

  _farok     := midstr(_kertnap,3,2) + midstr(_kertnap,6,2);
  _eloev     := _kertev;
  _eloho     := _kertho;

  dec(_eloho);

  if _eloho<1 then
    begin
      _eloho := 12;
      dec(_eloev);
    end;
  _elofarok := inttostr(_eloev-2000)+nulele(_eloho);

  // A HZ és KEZD file meghatározza:

  _hzfilenev   := 'HZ' + _eloFarok;
  _kezdfilenev := 'KEZD' + _farok;

  // Ha a kért nap a jövöben van, akkor nincs nyomtatás:

  if _kertnap>_megnyitottnap then
    begin
      ShowMessage('Érvénytelen nap kérése');
      Modalresult := 2;
      exit;
    end;

  // Ha a kért nap a mai nap - és még nincs lezárva - le kell zárni

  if _kertnap=_megnyitottnap then
    begin
      if _lezartnap='' then
        begin
          ShowMessage('Kérem elöbb lezárni a mai napot !');
          Modalresult := 2;
          exit;
        end;
    end;

  // Megnézi, hogy van-e KEZD tábla - ha nincs akkor nincs nyomtatás:

  KezdTabla.close;
  KezdTabla.TableName := _kezdfilenev;
  Kezddbase.Connected := true;

  if not KezdTabla.Exists then
    begin
      KezdDbase.close;
      ShowMessage('Nincs a megjelölt napról semmi adat');
      Modalresult := 2;
      exit;
    end;

  // Beolvassa az aktuális sorszámot: _utsorszam, ée a nyitó összeget: _nyito

  GetHavinyito;

  // Megnyitja az e-havi KEZD file a kért napnál régebbi rekordjait:

  _pcs := 'SELECT * FROM ' + _kezdfileNev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM<' + chr(39) + _kertnap + chr(39)+ _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with KezdQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  // A hónap eleji nyitót elöjel szerint módositja a kért napig:

  while not KezdQuery.eof do
    begin
      with Kezdquery do
        begin
          _elojel      := FieldByName('ELOJEL').asstring;
          _kezelesidij := FieldByName('KEZELESIDIJ').asInteger;
          _storno      := FieldByName('STORNO').asInteger;
        end;

      inc(_utsorszam);
      if _elojel= '+' then _nyito := _nyito + _kezelesidij
      else _nyito := _nyito - _kezelesidij;

      KezdQuery.next;
    end;

  KezdQuery.close;

  // ---------------------------------------------------------------------------

  // Most megnyitja a kért napi adatokat

  _pcs := 'SELECT * FROM ' + _kezdfilenev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _kertnap + chr(39);

  with Kezdquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  Kezdquery.close;
  KezdDbase.close;

  // ---------------------------------------------------------------------------

   if (_recno=0) and (_nyito=0) then
     begin
       ShowMessage('NINCSEN KÉSZLET A VÁLASZTOTT NAPON !');
       ModalResult := 2;
       exit;
     end;

  // ---------------------------------------------------------------------------
  //  Nyomtatás fejléc adatok


  val(_penztarKod,_ertektar,_code);
  if _code<>0 then _ertektar := 0;

  if _ertektar=0 then
    begin
      ShowMessage('HIBÁS ÉRTÉKTÁRSZÁM !');
      ModalResult := 2;
      exit;
    end;

  // Megnézi, hogy ez az értéktár létezik-e

  _etarss := etarScan(_ertektar);
  if _etarss=0 then
    begin
      ShowMessage('HIBÁS ÉRTÉKTÁRSZÁM !');
      ModalResult := 2;
      Exit;
    end;

  _varosNev := _etarNev[_etarss];
  Ertektarpanel.Caption := _varosNev + ' ÉRTÉKTÁR';

  _datumString := inttostr(_kertEv)+' ' + _hoNev[_kertHo] + ' '+inttostr(_kertDay);
  _datumString := _datumString +' - '+_napNev[_hNap];

  if _kertnap>'2017.01.06' then
     begin

  if _kertnap<_megnyitottnap then
    begin
      _spk := supervisorjelszo(0);
      if _spk<>1 then
        begin
          ModalResult := 2;
          exit;
        end;
    end;
    
      end;


  Printer.Copies := 2;
  if not PrintDialog1.Execute then
    begin
      Modalresult := 2;
      Exit;
    end;

  // ==================== NYOMTATÁS INNEN INDUL ================================

  WITH TakaroPanel DO
    begin
      Top := 176;
      Left := 40;
      Visible := true;
      Repaint;
    end;

  // -------------------------------------------------------

  inc(_utsorszam);
  KezdijNyomtatas;
  NaploNapiPrintBejegyzes;

  Modalresult := 1;
end;


// =============================================================================
                        procedure Tnapikezd.Gethavinyito;
// =============================================================================

begin
  // A HZ file HUF rekordból kiolvassa a KEZDIJZARO és UTKEZDIJSORSZAM
  // kiolvasásra kerül:

  _pcs := 'SELECT * FROM '+ _hzFileNev + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + 'HUF' + chr(39);

  Hzdbase.Connected := true;
  with HzQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      _nyito      := FieldbyName('KEZDIJZARO').asInteger;
      _utsorszam := FieldByName('UTKEZDIJSORSZAM').asInteger;
      close;
    end;
  HzDbase.close;

  // Ha január van, akkor elölröl kezdjük a sorszámot:

  if _kertho=1 then _utsorszam := 0;

end;


// =============================================================================
         function TNAPIKEZD.KovetkezoNap(_np: string): string;
// =============================================================================

var _napDatum : TDateTime;
    _ev,_ho,_nap: word;
    _evs,_hos,_naps: string;

begin
  _evs := leftstr(_np,4);
  _hos := midstr(_np,6,2);
  _naps:= midstr(_np,9,2);

  val(_evs,_ev,_code);
  if _code<>0 then _ev := 0;

  val(_hos,_ho,_code);
  if _code<>0 then _ho := 0;

    val(_naps,_nap,_code);
  if _code<>0 then _nap := 0;

  _napDatum := encodedate(_ev,_ho,_nap);
  _napdatum := _napdatum+1;
  result    := Hundatetostr(_napDatum);
end;


// =============================================================================
                  function TNAPIKEZD.Nulele(_n: byte): string;
// =============================================================================

begin
  result := inttostr(_n);
  if _n<10 then result := '0' + result;
end;

// =============================================================================
              function TNAPIKEZD.NulKieg(_i,_hh: integer): string;
// =============================================================================

var _s: string;

begin
  _s := inttostr(_i);
  _s := trim(_s);

  while length(_s)<_hh do _s := '0' + _s;
  result := _s;
end;

// =============================================================================
             function TNAPIKEZD.EloKieg(_s: string;_hh: integer): string;
// =============================================================================

begin
  _s := trim(_s);
  while length(_s)<_hh do _s := ' ' + _s;
  result := _s;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


// =============================================================================
          function TNAPIKEZD.PtarKepzo(_pts: string): string;
// =============================================================================

begin
  result := '   ('+trim(_pts)+')';
  while length(result)<11 do result := result + ' ';
end;

// =============================================================================
             function TNAPIKEZD.Form11(_int: integer): string;
// =============================================================================

var _res: string;
    _wRes,_p1: integer;

begin
  result := _kotoJel;
  if _int=0 then exit;

  _res  := inttostr(_int);
  _wRes := length(_res);

  if _wRes>6 then
    begin
      _p1  := _wRes-6;
      _res := leftstr(_res,_p1)+'.'+midstr(_res,_p1+1,3)+'.'+midstr(_res,_p1+4,3);
    end else

    begin
      if _wRes>3 then
        begin
          _p1  := _wRes-3;
          _res := leftstr(_res,_p1)+'.'+midstr(_res,_p1+1,3);
        end;
    end;

  while length(_res)<11 do _res := ' ' + _res;

  Result := _res;
end;


// =============================================================================
           procedure TNAPIKEZD.Kozepre(_psor:integer;_text: string);
// =============================================================================

var _texthossz,_poszlop: integer;

begin
  with Printer.Canvas do
    begin
      _textHossz := TextWidth(_text);
      _pOszlop   := trunc((_lapSzelesseg-_textHossz)/2);
      textout(_pOszlop,_pSor,_text);
    end;
end;

// =============================================================================
           function TNAPIKEZD.FtFormalo(_ft: integer): string;
// =============================================================================

var _wfts,_p1: integer;
    _fts: string;

begin
  result := '       -        ';
  if _ft=0 then exit;

  _fts  := inttostr(_ft);
  _wFts := length(_fts);

  if _wFts>6 then
    begin
      _p1 := _wFts-6;
      _fts := leftstr(_fts,_p1)+'.'+midstr(_fts,_p1+1,3)+'.'+midstr(_fts,_p1+4,3);
    end else

    begin
      if _wFts>3 then
        begin
          _p1 := _wFts-3;
          _fts := leftstr(_fts,_p1)+'.'+midstr(_fts,_p1+1,3);
        end;
    end;

  while length(_fts)<11 do _fts := ' ' + _fts;
  result := _fts + '.- Ft';
end;

// =============================================================================
           procedure TNAPIKEZD.KilepoTimerTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := false;
  ModalResult := _mResult;
end;

// =============================================================================
              function TNAPIKEZD.EtarScan(_et:integer): integer;
// =============================================================================

var _y: integer;

begin
  result := 0;
  _y     := 0;

  while _y<=8 do
    begin
      if _etarszam[_y]=_et then
        begin
          result := _y;
          break;
        end;
      inc(_y);
    end;
end;

// =============================================================================
            procedure TNapiKezd.elohogombClick(Sender: TObject);
// =============================================================================

begin
  Naptar.PrevMonth;
end;

// =============================================================================
            procedure TNapiKezd.kovhogombClick(Sender: TObject);
// =============================================================================

begin
  Naptar.NextMonth;
end;

// =============================================================================
           procedure TNAPIKEZD.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;


// =============================================================================
                 procedure TNapiKezd.NaploNapiPrintBejegyzes;
// =============================================================================

begin
     // $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
   //  Itt kell registrálni a nyomtatást a naplóban !!!
   // kertev, kertho, kertdekad

   _kertCondNap := leftstr(_kertnap,4)+midstr(_kertnap,6,2)+midstr(_kertnap,9,2);
   _pcs := 'SELECT * FROM PRINTCONTROL' + _sorveg;
   _pcs := _pcs + 'WHERE DATUMDEKAD=' + chr(39) + _kertCondNap + chr(39);

   Naplodbase.connected := true;
   with NaploQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       _recno := recno;
       Close;
     end;
   Naplodbase.close;

   if _recno=0 then
     begin
       _pcs := 'INSERT INTO PRINTCONTROL (KEZDIJPRINT,DEKADPRINT,DATUMDEKAD)' + _sorveg;
       _pcs := _pcs + 'VALUES (1,0,' + chr(39) + _kertCondNap + chr(39)+ ')';
     end else
     begin
       _pcs := 'UPDATE PRINTCONTROL SET KEZDIJPRINT=1'+_sorveg;
       _pcs := _pcs + 'WHERE DATUMDEKAD='+chr(39)+_kertCondNap+chr(39);
     end;

   Naplodbase.Connected := true;
   if NaploTranz.InTransaction then Naplotranz.Commit;
   Naplotranz.StartTransaction;
   with NaploQuery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Execsql;
     end;
   Naplotranz.Commit;
   Naplodbase.close;
end;

// =============================================================================
               procedure TNAPIKEZD.NAPTARChange(Sender: TObject);
// =============================================================================

begin
  EvhonapDisplay;
end;

// =============================================================================
          function TNapiKezd.Hundatetostr(_caldat: TDateTime): string;
// =============================================================================

var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
// =============================================================================
                   procedure Tnapikezd.KezdijNyomtatas;
// =============================================================================

begin
  Printer.Begindoc;
  _lapSzelesseg := Printer.PageWidth;

  with Printer.Canvas do
    begin
      Pen.Width := 10;
      roundRect(50,50,_lapszelesseg-50,900,250,250);
      Font.Name  := 'Times New Roman';
      Font.Size  := 36;
      Font.Style := [fsbold,fsItalic];

      Kozepre(100,'EXCLUSIVE BEST CHANGE ZRT');

      Font.Size  := 24;
      Font.Style := [fsItalic];
      Textout(250,550,'KEZELÉSI KÖLTSÉG');
      textout(3600,550,'JELENTÉS');         //3000 550

      _Keret := rect(2400,400,3400,800);    // 1800-400-2800-800 L-T-R-B

      StretchDraw(_keret,image1.Picture.Bitmap);

      Pen.Width := 6;
      Roundrect(1350,1000,3300,1500,200,200);

      Font.Size := 18;
      Kozepre(1020,_varosNev + ' ÉRTÉKTÁR');

      Font.Size := 14;
      Kozepre(1180,_penztarCim);

      Font.Size := 16;
      Kozepre(1300,_datumString);

      Fejlec(1600);

      Font.Name  := 'Courier New';
      Font.style := [];
    end;

  _prisor := 1800;

  // ---------------------------------------------------------------------------

  _beDarab := 0;
  _kiDarab := 0;
  _osszbevetel := 0;
  _osszkiadas  := 0;

  KezdDbase.Connected := True;
  with KezdQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not KezdQuery.Eof do
    begin
      if (_prisor>=4680)  then UjoldaltNyit;
      with KezdQuery do
        begin
          _storno       := FieldByName('STORNO').asInteger;
          _aktBizonylat := FieldByName('BIZONYLAT').asString;
          _aktPtarSzam  := FieldByName('PENZTAR').asString;
          _aktOsszeg    := FieldByName('KEZELESIDIJ').asInteger;
          _elojel       := FieldByNAme('ELOJEL').asString;
        end;

      EgyAdatSor;

      if _elojel='+' then
        begin
          _osszbevetel := _osszbevetel + _aktosszeg;
          if _storno=1 then inc(_bedarab);
        end;

       if _elojel='-' then
        begin
          _osszkiadas := _osszkiadas + _aktosszeg;
          if _storno=1 then inc(_kidarab);
        end;

      KezdQuery.next;
    end;

  KezdQuery.close;
  KezdDbase.close;

  _zaro := _nyito + _osszbevetel - _osszkiadas;

  _prisor := _prisor + 150;
  LabLec(_prisor);

  Printer.EndDoc;
end;


// =============================================================================
                       procedure TNAPIKEZD.Egyadatsor;
// =============================================================================

var _sors: string;

begin

  _sors := Nulkieg(_utSorszam,6);

  _tranzSs := 1;


  if leftstr(_aktBizonylat,1)='B' then _tranzss := 2;
  if _storno<>1 then _aktosszeg := 0;

  with Printer.Canvas do
    begin
      textout(60,_prisor,_sors);
      textout(560,_prisor,_aktBizonylat);
      textout(1100,_prisor,_tranztext[_tranzSs]);
      textout(2170,_prisor,elokieg(_aktptarSzam,3));
    end;

  if _aktOsszeg=0 then
    begin
      Printer.Canvas.TextOut(2800,_prisor,'storno bizonylat');
      _prisor := _prisor + 120;
      inc(_utSorszam);
      exit;
    end;

  if _tranzSs=2 then
    begin
      Printer.Canvas.Textout(2500,_prisor,ftFormalo(_aktOsszeg));
    end else
    begin
       Printer.Canvas.TextOut(3600,_prisor,ftFormalo(_aktOsszeg));
    end;

  _prisor := _prisor + 120;
  inc(_utSorszam);
end;

// =============================================================================
              procedure TNAPIKEZD.Lablec(_psor: integer);
// =============================================================================

begin

  with Printer.canvas do
    begin
      RoundRect(10,_psor-60,1600,_psor+720,50,50);
      RoundRect(1620,_psor-60,4670,_psor+720,50,50);

      Font.Style := [fsItalic ];

      // -----------------------------------------------------------------------

      RoundRect(90,_pSor,1530,_pSor+320,40,40);
      RoundRect(90,_pSor+340,1530,_pSor+660,40,40);

      Font.Size := 14;

      textout(100,_pSor+30,'BEVÉTELI BIZONYLATOK');
      textout(160,_pSor+370,'KIADÁSI BIZONYLATOK');

      Font.Size := 12;

      textout(100,_pSor+190,elokieg(inttostr(_beDarab),8)+' darab');
      textout(100,_pSor+530,elokieg(inttostr(_kiDarab),8)+' darab');

      // -----------------------------------------------------------------------

      RoundRect(1700,_pSor,2500,_psor+150,40,40);
      RoundRect(2550,_pSor,3550,_psor+150,40,40);
      RoundRect(3600,_pSor,4600,_psor+150,40,40);

      textout(1740,_pSor+30,'KEZELÉSI DÍJ');
      textout(2560,_pSor+30,ftFormalo(_osszBevetel));
      textout(3610,_pSor+30,ftFormalo(_osszKiadas));

      // -----------------------------------------------------------------------

      _pSor := _pSor + 170;

      RoundRect(1700,_pSor,2500,_pSor+150,40,40);
      RoundRect(2550,_pSor,3550,_pSor+150,40,40);
      RoundRect(3600,_pSor,4600,_pSor+150,40,40);

      _racskSor := _pSor;

      textout(1920,_pSor+30,'NYITÓ');
      textout(2560,_pSor+30,ftFormalo(_nyito));

      // -----------------------------------------------------------------------

      _pSor := _pSor + 170;

      RoundRect(1700,_pSor,2500,_pSor+150,40,40);
      RoundRect(2550,_pSor,3550,_pSor+150,40,40);
      RoundRect(3600,_pSor,4600,_pSor+150,40,40);

      _racsBsor := _pSor;
      textout(1935,_psor+30,'ZÁRÓ');
      textout(3610,_psor+30,ftFormalo(_zaro));

      // -----------------------------------------------------------------------

      _pSor := _pSor + 170;

      RoundRect(1700,_pSor,2500,_pSor+150,40,40);
      RoundRect(2550,_pSor,3550,_pSor+150,40,40);
      RoundRect(3600,_pSor,4600,_pSor+150,40,40);

      _osszesen := _nyito + _osszBevetel;

      textout(1900,_pSor+30,'ÖSSZESEN');
      textout(2560,_pSor+30,ftFormalo(_osszesen));
      textout(3610,_pSor+30,ftFormalo(_osszesen));

      Pen.Width := 1;
      Brush.Style := bsBDiagonal;
      FillRect(rect(3600,_racsksor,4600,_racsksor+150));
      FillRect(rect(2550,_racsbsor,3550,_racsbsor+150));

      // -----------------------------------------------------------------------

      _pSor := _pSor + 650;
      textout(100,_pSor,_varosNev+' '+ Hundatetostr(date));
      textout(2500,_pSor,dupestring('.',40));
      textout(3000,_psor+100,'pénztáros');
    end;
end;

// =============================================================================
                  procedure TNAPIKEZD.Fejlec(_psor: integer);
// =============================================================================

var _text: string;

begin
  _aktoldal := 0;
  with Printer.Canvas do
    begin
      Font.Size := 12;
      Font.Style := [fsBold];

      RoundRect(10,_psor,_lapszelesseg-10,_psor+150,30,30);

  //    Moveto(30,_psor);
  //    Lineto(_lapszelesseg-20,_psor);

      _text := 'Sorszám  Bizonylatszám         Tranzakció            ';
      _text := _text + 'Bank/ptár           Bevétel                                Kiadás';
      Textout(50,_psor+20,_text);

   //   Moveto(30,_psor+150);
   //   Lineto(_lapszelesseg-20,_psor+150);
    end;
end;

// =============================================================================
                    procedure TNAPIKEZD.Ujoldaltnyit;
// =============================================================================

var _text: string;

begin
  inc(_aktoldal);

  Printer.Canvas.Font.Name := 'Times New Roman';
  Printer.Canvas.Font.Size := 18;
  Printer.Canvas.Font.Style := [fsItalic];
  Kozepre(5800,'- folytatás a ' + inttostr(_aktoldal) + '. oldalon -');
  Printer.NewPage;

  with Printer.Canvas do
    begin
      _text := '- ' +inttostr(_aktoldal)+'. oldal -';
      Kozepre(200,_text);

      Font.size  := 16;
      Font.Style := [fsItalic];
    end;

  FejLec(400);
  Printer.Canvas.Font.Style := [];
  Printer.Canvas.Font.Name := 'Courier New';
  _prisor := 600;
end;

end.
