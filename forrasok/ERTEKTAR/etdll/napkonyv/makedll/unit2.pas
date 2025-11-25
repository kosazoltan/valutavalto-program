unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBTable, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, strutils, DateUtils, Buttons, Grids, Calendar, printers, jpeg;

type
  TNAPIKONYV = class(TForm)

    ValdatATabla: TIBTable;
    ValdatAQuery: TIBQuery;
    ValdatADbase: TIBDatabase;
    ValdatATranz: TIBTransaction;

    ValutaQuery : TIBQuery;
    ValutaDbase : TIBDatabase;
    ValutaTranz : TIBTransaction;
    EvPanel          : TPanel;
    DayPanel         : TPanel;
    HonapPanel       : TPanel;
    NapnevPanel      : TPanel;
    Label3           : TLabel;
    Label4           : TLabel;

    ElohoGomb        : TBitBtn;
    KovhoGomb        : TBitBtn;
    NyomtatoGomb     : TBitBtn;
    VisszaGomb       : TBitBtn;

    Shape1           : TShape;
    Shape3           : TShape;
    Shape4           : TShape;
    KilepoTimer      : TTimer;
    Naptar           : TCalendar;
    PrintDialog1     : TPrintDialog;
    CEGNEVPANEL: TPanel;

    procedure Egyadatsor;
    procedure EgynapiRekordInsert;
 
    procedure ElohoGombClick(Sender: TObject);
    procedure EvhonapDisplay;
    procedure Fejlec(_psor: integer);
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimerTimer(Sender: TObject);
    procedure KovHoGombClick(Sender: TObject);
    procedure Kozepre(_psor:integer;_text: string);
    procedure Lablec(_psor: integer);
    procedure NaploNapiPrintBejegyzes;
    procedure NapiKonyvNyomtatas;
    procedure NyomtatoGombClick(Sender: TObject);
    procedure Szamtan;
    procedure Ujoldaltnyit;
    procedure ValutaParancs(_ukaz: string);
    procedure VisszaGombClick(Sender: TObject);

    function EloKieg(_s: string;_hh: integer): string;
    function Form11(_int: integer): string;
    function FormDatum: string;
    function FtFormalo(_ft: integer): string;
    function GetElofarok: string;

    function GetNyito(_kdas: string): integer;
    function Getvarosnev(_et: byte):string;
    function GetZaro(_kdas: string): integer;
    function Hundatetostr(_caldat: TDatetime): string;
    function Nulele(_n: byte): string;
    function NulKieg(_i,_hh: integer): string;
  
    procedure NAPTARChange(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NAPIKONYV: TNAPIKONYV;

  _etarszam: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _etarnev: array[1..8] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
                'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR');

  _honev: array[1..12] of string  = ('január','február','március','április','május',
                  'junius','július','augusztus','szeptember','október','november',
                  'december');

  _napnev: array[1..7] of string = ('hétfõ','kedd','szerda','csütörtök','péntek',
                   'szombat','vasárnap');

  _tranztext: array[1..2] of string = ('forint - átadás','forint - átvétel');

  _penztarszam,_status,_storno,_tranzss,_aktoldal: byte;
  _kotojel: string = '-';

  _kertDatum: TDateTime;

  _mResult,_code,_osszbevetel,_osszkiadas,_bedarab,_kidarab: integer;
  _nyito,_zaro,_osszesen,_recno,_kezdosorszam,_aktsorszam,_lastsorszam: integer;
  _aktOsszeg,_szamitott: integer;

  _height,_width,_etindex,_lapszelesseg,_prisor,_racskSor,_racsBSor: word;

  _pcs,_megnyitottnap,_kftnev,_penztarkod,_penztarcim,_maievs,_cegnev: string;
  _varosnev,_datumstring,_kertDatums,_lastevs,_farok,_elofarok,_cimtnev: string;
  _bfejnev,_aktbizonylat,_aktptarszam,_betujel: string;
  _sorveg: string = chr(13)+chr(10);

  _hiba: boolean;

function napikonyvelorutin: integer; stdcall;
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\ertektar\bin\super.dll' name 'supervisorjelszo';


implementation

{$R *.dfm}


// =============================================================================
                function napikonyvelorutin: integer; stdcall;
// =============================================================================

begin
  Napikonyv := TNapiKonyv.Create(Nil);
  result := Napikonyv.ShowModal;
  Napikonyv.Free;
end;



// =============================================================================
                procedure TNapiKonyv.FormActivate(Sender: TObject);
// =============================================================================

BEGIN
  _mResult := 2;

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  top     := trunc((_height-590)/2);
  Left    := trunc((_width-817)/2);

  // Hardware adatok beolvasása:

  _pcs := 'SELECT * FROM HARDWARE';
  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
      _kftnev        := trim(FieldByName('KFTNEV').asstring);
      close;

      Sql.clear;
      Sql.Add('SELECT * FROM PENZTAR');
      Open;
      _penztarkod := trim(FieldByNAme('PENZTARKOD').AsString);
      _penztarcim := trim(FieldByNAme('PENZTARCIM').AsString);
      Close;
    end;
  Valutaquery.close;
  Valutadbase.close;

  // ----------------------------------------------

  _maievs := leftstr(_megnyitottnap,4);

  Val(_penztarkod,_penztarszam,_code);
  if _code<>0 then _penztarszam := 0;
  if _penztarszam=0 then
    begin
      ShowMessage('Hibas pénztárszám !');
      Kilepotimer.Enabled := true;
      exit;
    end;

  _etindex := 1;
  while _etindex<=8 do
    begin
      if _penztarszam=_etarszam[_etindex] then break;
      inc(_etindex);
    end;

  if _etindex>8 then
    begin
      ShowMessage('Hibas pénztárszám !');
      Kilepotimer.Enabled := true;
      exit;
    end;
  _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';

  CegnevPanel.Caption := _cegnev;
  _varosnev := _etarnev[_etindex];

  Naptar.CalendarDate := Date;
  EvhonapDisplay;
end;

// =============================================================================
                     procedure TNapiKonyv.EvhonapDisplay;
// =============================================================================

VAR _aktev,_aktho,_kertday,_hNap: word;
    _aktdatum : TDateTime;

begin

  _aktEv    := Naptar.Year;
  _aktHo    := Naptar.Month;
  _kertDay  := Naptar.day;
  _aktDatum := Naptar.CalendarDate;
  _hNap     := dayOfTheWeek(_aktDatum);

  EvPanel.Caption     := inttostr(_aktEv);
  HonapPanel.Caption  := _honev[_aktHo];
  DayPanel.Caption    := inttostr(_kertDay);
  NapnevPanel.Caption := _napnev[_hNap];

  EvPanel.repaint;
  HonapPanel.repaint;
  DayPanel.Repaint;
  NapnevPanel.Repaint;

  ActiveControl := NyomtatoGomb;
end;


// =============================================================================
          procedure TNapiKonyv.NyomtatoGombClick(Sender: TObject);
// =============================================================================

// Amikor a naptár rendben van ide kattont:

var _spk : integer;

begin

  _osszbevetel := 0;
  _osszkiadas  := 0;
  _bedarab     := 0;
  _kidarab     := 0;
  _nyito       := 0;
  _zaro        := 0;
  _osszesen    := 0;
  _hiba        := False;

  // Meghatározza  a napot, melyet nyomtatni kell:

  _kertDatum   := Naptar.CalendarDate;
  _datumstring := Formdatum;
  _kertdatums  := Hundatetostr(_kertdatum);

  if _kertdatums>_megnyitottnap then
    begin
      Showmessage('A KÉRT NAP A JÖVÕ !');
      Modalresult := 2;
      exit;
    end;

  if _kertdatums<_megnyitottnap then
    begin
      _spk := supervisorjelszo(0);
      if _spk<>1 then
        begin
          modalresult := 2;
          exit;
        end;
    end;

  _pcs := 'SELECT * FROM NAPIKONYV' + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM<' + chr(39) + _kertdatums + chr(39)+ ')'+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  _lastsorszam := 0;

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno :=  recno;
    end;

  if _recno>0 then
    begin
      _lastsorszam := ValutaQuery.FieldByName('VEGSORSZAM').asInteger;
      _lastevs := leftstr(ValutaQuery.FieldByNAme('DATUM').AsString,4);
    end;

  ValutaQuery.close;
  Valutadbase.close;

  if _maievs>_lastevs then _lastsorszam := 0;

  _kezdosorszam := 1 + _lastsorszam;

  _farok := midstr(_kertdatums,3,2)+midstr(_kertdatums,6,2);
  _elofarok := Getelofarok;

  _nyito := Getnyito(_kertdatums);
  _zaro  := Getzaro(_kertdatums);

  Szamtan;

  if _hiba then
    begin
      Modalresult := 2;
      exit;
    end;

  printer.Copies := 2;
  if not Printdialog1.execute then
    begin
      Modalresult := 2;
      exit;
    end;

  NapiKonyvNyomtatas;

  if not _hiba then
    begin
      EgyNapiRekordInsert;
      NaploNapiPrintBejegyzes;
    end;
  Modalresult := 1;
end;


// =============================================================================
                function TNAPIKONYV.GetElofarok: string;
// =============================================================================

var _evs: string;
    _ev,_ho: word;

begin
  _ev := Naptar.year;
  _ho := Naptar.month;

  dec(_ho);
  if _ho<1 then
    begin
      _ho := 12;
      dec(_ev);
    end;
  _evs :=inttostr(_ev-2000);
  result := _evs + nulele(_ho);
end;


// =============================================================================
             function TNAPIKONYV.Form11(_int: integer): string;
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
           procedure TNAPIKONYV.Kozepre(_psor:integer;_text: string);
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
           procedure TNAPIKONYV.KilepoTimerTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := false;
  ModalResult := _mResult;
end;

// =============================================================================
              function TNAPIKONYV.NulKieg(_i,_hh: integer): string;
// =============================================================================

var _s: string;

begin
  _s := inttostr(_i);
  _s := trim(_s);

  while length(_s)<_hh do _s := '0' + _s;
  result := _s;
end;

// =============================================================================
             function TNAPIKONYV.EloKieg(_s: string;_hh: integer): string;
// =============================================================================

begin
  _s := trim(_s);
  while length(_s)<_hh do _s := ' ' + _s;
  result := _s;
end;

// =============================================================================
            procedure TNAPIKONYV.elohogombClick(Sender: TObject);
// =============================================================================

begin
  Naptar.PrevMonth;
  EvhonapDisplay;
end;


// =============================================================================
            procedure TNAPIKONYV.kovhogombClick(Sender: TObject);
// =============================================================================

begin
  Naptar.NextMonth;
  EvHonapDisplay;
end;

///$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                 procedure TNAPIKONYV.NaploNapiPrintBejegyzes;
// =============================================================================

begin
  _pcs := 'DELETE FROM NAPLO WHERE DATUM='+chr(39)+_kertdatums+chr(39);
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO NAPLO (DATUM,STATUS)' + _sorveg;
  _pcs := _pcs + 'VALUES (' +chr(39) + _kertdatums + chr(39)+',1)';
  ValutaParancs(_pcs);
end;




// =============================================================================
           procedure TNAPIKONYV.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

// =============================================================================
        function TNAPIKONYV.HunDateTostr(_caldat: TDatetime): string;
// =============================================================================

var _h_ev,_h_ho,_h_nap: word;

begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;

// =============================================================================
                  function TNAPIKONYV.Nulele(_n: byte): string;
// =============================================================================

begin
  result := inttostr(_n);
  if _n<10 then result := '0' + result;
end;

// =============================================================================
           function TNAPIKONYV.Getnyito(_kdas: string): integer;
// =============================================================================

begin
  result := 0;
  _cimtnev := 'CIMT' + _farok;
  _pcs := 'SELECT * FROM ' + _cimtnev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM<' + chr(39) + _kdas + chr(39);
  _pcs := _pcs + ' AND (VALUTANEM=' + chr(39)+'HUF'+chr(39)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  ValdataDbase.connected := true;
  ValDataTabla.close;
  ValdataTabla.tablename := _cimtnev;
  if not ValdataTabla.exists then
    begin
      ValdataDbase.close;
      exit;
    end;

  with ValdataQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := Recno;
    end;

  if _recno=0 then
    begin

      _pcs := 'SELECT * FROM ' + 'HZ' + _elofarok + _sorveg;
      _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39)+'HUF'+chr(39);

      with ValdataQuery do
        begin
          Close;
          sql.clear;
          Sql.add(_pcs);
          Open;
          result := FieldByNAme('ZARO').asInteger;
          Close;
        end;
      Valdatadbase.close;
      exit;
    end;
  result := ValdataQuery.FieldByNAme('BANKJEGY').asInteger;
  ValdataQuery.close;
  Valdatadbase.close;
end;

// =============================================================================
            function TNAPIKONYV.GetZaro(_kdas: string): integer;
// =============================================================================

begin
  result := 0;
  _cimtnev := 'CIMT' + _farok;
  _pcs := 'SELECT * FROM ' + _cimtnev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _kdas + chr(39);
  _pcs := _pcs + ' AND (VALUTANEM=' + chr(39)+'HUF'+chr(39)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  ValdataDbase.connected := true;
  ValDataTabla.close;
  ValdataTabla.tablename := _cimtnev;
  if not ValdataTabla.exists then
    begin
      ValdataDbase.close;
      exit;
    end;

  with ValdataQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := Recno;
    end;

  if _recno>0 then
          result := ValdataQuery.FieldByNAme('BANKJEGY').asInteger;

  ValdataQuery.close;
  Valdatadbase.close;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
              procedure TNAPIKONYV.NapiKonyvNyomtatas;
// =============================================================================

begin

  _AKTSORSZAM := _kezdosorszam;

  Printer.Begindoc;
  _lapSzelesseg := Printer.PageWidth;

  with Printer.Canvas do
    begin
      Pen.Width := 10;
      roundRect(50,50,_lapszelesseg-50,900,250,250);
      Font.Name  := 'Times New Roman';
      Font.Size  := 24;
      Font.Style := [fsbold,fsItalic];

      Kozepre(120,_cegnev);

      Font.Size  := 36;
      Font.Style := [fsItalic];
      Kozepre(450,'NAPI PÉNZTÁR JELENTÉS');

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

  _pcs := 'SELECT * FROM '+_bfejNev + _sorVeg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _KERTDATUMS + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY IDO';

  ValdataDbase.Connected := True;

  with ValdataQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _aktSorszam := _kezdoSorszam;

  while not ValdataQuery.eof do
    begin
      if (_prisor>=4680)  then UjoldaltNyit;

      with ValdataQuery do
        begin
          _storno       := FieldByName('STORNO').asInteger;
          _aktBizonylat := FieldByName('BIZONYLATSZAM').asString;
          _aktPtarSzam  := FieldByName('TARSPENZTARKOD').asString;
          _aktOsszeg    := FieldByName('FORINTERTEK').asInteger;
        end;

      _betuJel := leftstr(_aktBizonylat,2);

      if (_betuJel='FF') OR (_betuJel='UF') then
        begin
          if _storno<>1 then _aktOsszeg := 0;

          if _betuJel='FF' then _tranzss := 1;
          if _betujel='UF' then _tranzss := 2;

          EgyAdatSor;

        end;

      ValdataQuery.next;
    end;
  ValdataDbase.close;
  
  _prisor := _prisor + 150;
  LabLec(_prisor);

  Printer.EndDoc;
end;

// =============================================================================
              procedure TNAPIKONYV.Lablec(_psor: integer);
// =============================================================================

begin
  dec(_aktsorszam);
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

      textout(1910,_pSor+30,'FORGALOM');
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
      textout(100,_pSor,_varosNev+' '+ hundatetostr(date));
      textout(2500,_pSor,dupestring('.',40));
      textout(3000,_psor+100,'pénztáros');
    end;
end;

// =============================================================================
                       procedure TNAPIKONYV.Egyadatsor;
// =============================================================================

var _sors: string;

begin
  _sors := Nulkieg(_AKTsorszam,6);
  with Printer.Canvas do
    begin
      textout(60,_prisor,_sors);
      textout(500,_prisor,_aktBizonylat);
      textout(1180,_prisor,_tranztext[_tranzSs]);
      textout(2170,_prisor,elokieg(_aktptarSzam,3));
    end;

  if _aktOsszeg=0 then
    begin
      Printer.Canvas.TextOut(2800,_prisor,'storno bizonylat');
      _prisor := _prisor + 120;
      inc(_aktSorszam);
      exit;
    end;

  if _tranzSs=2 then Printer.Canvas.Textout(2500,_prisor,ftFormalo(_aktOsszeg));
  if _tranzss=1 then Printer.Canvas.TextOut(3600,_prisor,ftFormalo(_aktOsszeg));

  _prisor := _prisor + 120;
  inc(_aktSorszam);
end;

// =============================================================================
           function TNAPIKONYV.FtFormalo(_ft: integer): string;
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
                    procedure TNAPIKONYV.Ujoldaltnyit;
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

// =============================================================================
                  procedure TNAPIKONYV.Fejlec(_psor: integer);
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

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                procedure TNAPIKONYV.EgynapiRekordInsert;
// =============================================================================

begin
  _pcs := 'DELETE FROM NAPIKONYV WHERE DATUM='+CHR(39)+_kertdatums+chr(39);
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO NAPIKONYV (DATUM,KEZDOSORSZAM,VEGSORSZAM,BEDARAB,KIDARAB,';
  _pcs := _pcs + 'NYITO,OSSZBEVETEL,OSSZKIADAS,OSSZESEN,ZARO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _kertdatums + chr(39) + ',';
  _pcs := _pcs + inttostr(_kezdosorszam) + ',';
  _pcs := _pcs + inttostr(_aktsorszam) + ',';
  _pcs := _pcs + inttostr(_bedarab) + ',';
  _pcs := _pcs + inttostr(_kidarab) + ',';
  _pcs := _pcs + inttostr(_nyito) + ',';
  _pcs := _pcs + inttostr(_osszbevetel) + ',';
  _pcs := _pcs + inttostr(_osszkiadas) + ',';
  _pcs := _pcs + inttostr(_osszesen) + ',';
  _pcs := _pcs + inttostr(_zaro) + ')';

  ValutaParancs(_pcs);
end;

// =============================================================================
             procedure TNAPIKONYV.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.Connected := True;
  if ValutaTranz.intransaction then ValutaTranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ValutaTranz.Commit;
  ValutaDbase.close;
end;


// =============================================================================
            function TNAPIKONYV.Getvarosnev(_et: byte):string;
// =============================================================================

var _y: byte;

begin
  result := '';
  _y := 1;
  while _y<=8 do
    begin
      if _et=_etarszam[_y] then
        begin
          result := _etarnev[_y];
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                     function TNAPIKONYV.FormDatum: string;
// =============================================================================

var _ev,_ho,_nap,_hnap: word;

begin
  _ev := yearof(_kertdatum);
  _ho := monthof(_kertdatum);
  _nap:= dayof(_kertdatum);
  _hnap := dayoftheweek(_kertdatum);

  result := inttostr(_ev)+' '+_honev[_ho]+' '+inttostr(_nap)+' '+_napnev[_hnap];
end;

// =============================================================================
           procedure TNAPIKONYV.NAPTARChange(Sender: TObject);
// =============================================================================

begin
  EvHonapDisplay;
end;

// =============================================================================
                             procedure TNAPIKONYV.Szamtan;
// =============================================================================

begin
  _osszbevetel := 0;
  _osszkiadas  := 0;
  _bedarab     := 0;
  _kidarab     := 0;
  _hiba        := False;
  _szamitott   := 0;

  _bfejnev := 'BF' + _farok;


  _pcs := 'SELECT * FROM '+_bfejNev + _sorVeg;
  _pcs := _pcs + 'WHERE (DATUM=' + chr(39) + _kertDatums + chr(39)+')';
  _pcs := _pcs + ' AND (STORNO=1)';

  ValdataDbase.connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ValdataQuery.eof do
    begin
      with ValdataQuery do
        begin
          _aktBizonylat := FieldByName('BIZONYLATSZAM').asString;
          _aktOsszeg    := FieldByName('FORINTERTEK').asInteger;
        end;

      _betuJel := leftstr(_aktBizonylat,2);

      if (_betuJel='FF') OR (_betuJel='UF') then
        begin
          if _betuJel='FF' then
            begin
              _osszkiadas := _osszkiadas + _aktosszeg;
              inc(_kidarab);
            end else
            begin
              _osszbevetel := _osszbevetel + _aktosszeg;
              inc(_bedarab);
            end;
        end;
      ValdataQuery.next;
    end;
  Valdataquery.close;
  Valdatadbase.close;

  _szamitott := _nyito + _osszbevetel - _osszkiadas;

  if _szamitott<>_zaro then
    begin
      Showmessage('NEM EGYEZIK A ZÁRÓÖSSZEG');
      _HIBA := True;
    end;
end;




end.
