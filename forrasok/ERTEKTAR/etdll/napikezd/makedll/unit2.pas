unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBTable, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, strutils, DateUtils, Buttons, Grids, Calendar, printers, jpeg;

type
  TNAPIKEZD = class(TForm)

    KilepoTimer     : TTimer;

    PrintDialog1    : TPrintDialog;
    VALDATAQUERY: TIBQuery;
    VALDATATABLA: TIBTable;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
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
    Image1: TImage;


    procedure Egyadatsor;
    procedure ElohoGombClick(Sender: TObject);
    procedure EvhonapDisplay;
    procedure Fejlec(_psor: integer);
    procedure FormActivate(Sender: TObject);
   
    procedure KilepoTimerTimer(Sender: TObject);
    procedure Kozepre(_psor:integer;_text: string);
    procedure KovHoGombClick(Sender: TObject);
    procedure Lablec(_psor: integer);
//    procedure NaploNapiPrintBejegyzes;
    procedure KezdijNyomtatas;
    procedure ValutaParancs(_ukaz: string);
    procedure EgyNapiRekordInsert;

    procedure NyomtatoGombClick(Sender: TObject);
    procedure Ujoldaltnyit;
    procedure VisszaGombClick(Sender: TObject);
    procedure Szamtan;

    function EloKieg(_s: string;_hh: integer): string;
    function FormDatum: string;


    function Form11(_int: integer): string;
    function FtFormalo(_ft: integer): string;
    function HunDateTostr(_caldat: TDatetime): string;
    function KovetkezoNap(_np: string): string;
    function Nulele(_n: byte): string;
    function NulKieg(_i,_hh: integer): string;
    function PtarKepzo(_pts: string): string;
    procedure NAPTARChange(Sender: TObject);
    function GetElofarok: string;
    function Getnyito(_kdas: string): integer;
    function GetZaro(_kdas: string): integer;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NAPIKEZD: TNAPIKEZD;

  _etarszam: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _etarnev: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
                'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR',
                'EXPRESSZ');

  _honev: array[1..12] of string  = ('január','február','március','április','május',
                  'junius','július','augusztus','szeptember','október','november',
                  'december');

  _napnev: array[1..7] of string = ('hétfõ','kedd','szerda','csütörtök','péntek',
                   'szombat','vasárnap');

  _tranztext: array[1..2] of string = ('forint - átadás','forint - átvétel');

  _kotojel : string = '-';

  _penztarszam,_status,_storno,_tranzss,_aktoldal: byte;

  _kertDatum: TDateTime;

  _mResult,_code,_osszbevetel,_osszkiadas,_bedarab,_kidarab: integer;
  _nyito,_zaro,_osszesen,_recno,_kezdosorszam,_aktsorszam,_lastsorszam: integer;
  _aktosszeg,_szamitott,_aktbankjegy: integer;
  _height,_width,_etindex,_lapszelesseg,_prisor,_racsksor,_racsbsor: word;

  _pcs,_megnyitottnap,_kftnev,_penztarkod,_penztarcim,_maievs,_cegnev: string;
  _varosnev,_datumstring,_kertDatums,_lastevs,_farok,_elofarok,_kdat: string;
  _kezdnev,_aktbizonylat,_aktptarszam,_elojel: string;
  _sorveg: string = chr(13)+chr(10);

  _hiba: boolean;

function napikezdijrutin: integer; stdcall;
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\ertektar\bin\super.dll' name 'supervisorjelszo';

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
  _mResult := 2;

  TakaroPanel.visible := False;

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
  while _etindex<=9 do
    begin
      if _penztarszam=_etarszam[_etindex] then break;
      inc(_etindex);
    end;

  if _etindex>9 then
    begin
      ShowMessage('Hibás pénztárszám !');
      Kilepotimer.Enabled := true;
      exit;
    end;
  if _kftnev<>'EXPRESSZ' then _cegnev := 'EXCLUSIVE BEST CHANGE ZRT'
  else _cegnev := 'EXPRESSZ ÉKSZEHÁZ ÉS MINIBANK KFT';

  KftPanel.Caption := _cegnev;
  _varosnev := _etarnev[_etindex];
  if _varosnev='EXPRESSZ' then _varosnev := 'Pécs';

  Naptar.CalendarDate := Date;
  EvhonapDisplay;
end;

// =============================================================================
                     procedure TNAPIKEZD.EvhonapDisplay;
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
          procedure TNAPIKEZD.NyomtatoGombClick(Sender: TObject);
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

  _pcs := 'SELECT * FROM NAPIKEZD' + _sorveg;
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

  {
  with PrintTakaroPanel do
    begin
      top := 104;
      left := 144;
      Visible := true;
      repaint;
    end;
  }


  Kezdijnyomtatas;

  if not _hiba then
    begin
      EgyNapiRekordInsert;
//      NaploNapiPrintBejegyzes;
    end;
  Modalresult := 1;
end;

// =============================================================================
                        function Tnapikezd.GetElofarok: string;
// =============================================================================

var _ev,_ho: word;


begin
  _ev := NAptar.year;
  _ho := Naptar.month;

  dec(_ho);
  if _ho<1 then
    begin
      _ho := 12;
      dec(_ev);
    end;
  result := inttostr(_ev-2000)+nulele(_ho);
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
           procedure TNAPIKEZD.KilepoTimerTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := false;
  ModalResult := _mResult;
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
          function TNapiKezd.Hundatetostr(_caldat: TDateTime): string;
// =============================================================================

var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;



// =============================================================================
                  function TNAPIKEZD.Nulele(_n: byte): string;
// =============================================================================

begin
  result := inttostr(_n);
  if _n<10 then result := '0' + result;
end;


// =============================================================================
            function Tnapikezd.Getnyito(_kdas: string): integer;
// =============================================================================

begin

  _kdat := 'KDAT' + _farok;
  _pcs := 'SELECT * FROM ' + _kdat +  _sorveg;
  _pcs := _pcs + 'WHERE DATUM<' + chr(39) + _kertdatums + chr(39) + _sorveg;
  _PCS := _pcs + 'ORDER BY DATUM';

  Valutadbase.Connected := true;
   with ValdataQuery do
     begin
       close;
       sql.clear;
       sql.add(_pcs);
       Open;
       last;
       _recno := recno;
     end;

   if _recno=0 then
     begin
       _pcs := 'SELECT * FROM HZ' + _elofarok;
       with ValdataQuery do
         begin
           CLose;
           sql.clear;
           sql.add(_pcs);
           Open;
           result := FieldByNAme('KEZDIJZARO').asInteger;
           Close;
         end;
       ValdataQuery.close;
       exit;
     end;

   result := ValdataQuery.FieldByName('ZARO').asInteger;
   ValdataQuery.close;
   ValdataDbase.close;
end;



// =============================================================================
            function Tnapikezd.GetZaro(_kdas: string): integer;
// =============================================================================

begin

  _kdat := 'KDAT' + _farok;
  _pcs := 'SELECT * FROM ' + _kdat +  _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _kertdatums + chr(39);

  ValdataDbase.connected := true;
  with valdataQuery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      result := FieldByNAme('ZARO').asInteger;
      Close;
    end;

  Valdatadbase.close;
end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
// =============================================================================
                   procedure Tnapikezd.KezdijNyomtatas;
// =============================================================================

begin

  _aktsorszam := _kezdosorszam;

  Printer.Begindoc;
  _lapSzelesseg := Printer.PageWidth;

  with Printer.Canvas do
    begin
      Pen.Width := 10;
      roundRect(50,50,_lapszelesseg-50,900,250,250);
      Font.Name  := 'Times New Roman';
      Font.Size  := 24;
      Font.Style := [fsbold,fsItalic];

      Kozepre(180,_cegnev);

      Font.Size  := 28;
      Font.Style := [fsItalic];
      Kozepre(500,'KEZELÉSI KÖLTSÉG JELENTÉS');

      Pen.Width := 6;
      Roundrect(1350,1000,3300,1500,200,200);

      Font.Size := 18;
      Kozepre(1020,_varosnev+' értéktár');

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

  _kezdnev := 'KEZD' + _farok;

  _pcs := 'SELECT * FROM ' + _kezdnev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39)+_kertdatums+chr(39);

  ValdataDbase.Connected := True;
  with ValdataQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValdataQuery.Eof do
    begin
      if (_prisor>=4680)  then UjoldaltNyit;
      with ValdataQuery do
        begin
          _storno       := FieldByName('STORNO').asInteger;
          _aktBizonylat := FieldByName('BIZONYLAT').asString;
          _aktPtarSzam  := FieldByName('PENZTAR').asString;
          _aktOsszeg    := FieldByName('BANKJEGY').asInteger;
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

      ValdataQuery.next;
    end;

  ValdataQuery.close;
  ValdataDbase.close;

  _zaro := _nyito + _osszbevetel - _osszkiadas;

  _prisor := _prisor + 150;
  LabLec(_prisor);

  _lastsorszam := _aktsorszam-1;
  Printer.EndDoc;
end;


// =============================================================================
                       procedure TNAPIKEZD.Egyadatsor;
// =============================================================================

var _sors: string;

begin
  
  _sors := Nulkieg(_aktSorszam,6);

  _tranzSs := 1;


  if _elojel = '+' then _tranzss := 2;
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
      inc(_aktSorszam);
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
  inc(_aktSorszam);
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
      textout(100,_pSor,_varosnev+' '+ Hundatetostr(date));
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
               procedure TNAPIKEZD.NAPTARChange(Sender: TObject);
// =============================================================================

begin
  EvhonapDisplay;
end;


function TNapikezd.FormDatum: string;


var _ev,_ho,_nap,_hnap: word;

begin
  _ev   := yearof(_kertdatum);
  _ho   := monthof(_kertdatum);
  _nap  := dayof(_kertdatum);
  _hnap := dayoftheweek(_kertdatum);

  result := inttostr(_ev)+' '+_honev[_ho]+' '+inttostr(_nap)+' '+_napnev[_hNap];

end;

procedure TNapiKezd.Szamtan;

begin
  _osszbevetel := 0;
  _osszkiadas := 0;
  _bedarab    := 0;
  _kidarab    := 0;
  _hiba       := False;
  _szamitott  := 0;

  _kezdNev := 'KEZD' + _farok;

  _pcs := 'SELECT * FROM ' + _kezdnev  + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM=' + chr(39) + _kertdatums + chr(39) + ')';
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

  while not valdataQuery.eof do
    begin
      _aktbankjegy := ValdataQuery.FieldByNAme('BANKJEGY').asInteger;
      _elojel := ValdataQuery.Fieldbyname('ELOJEL').asString;

      if _elojel='+' then
        begin
          inc(_bedarab);
          _osszbevetel := _osszbevetel + _aktbankjegy;
        end else
        begin
          inc(_kidarab);
          _osszkiadas := _osszkiadas + _aktbankjegy;
        end;
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  Valdatadbase.close;

  _zaro := _nyito + _osszbevetel - _osszkiadas;
end;



procedure TNapikezd.ValutaParancs(_ukaz: string);

begin
  Valutadbase.connected := true;
  if valutatranz.InTransaction then ValutaTranz.Commit;
  Valutatranz.StartTransaction;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  Valutatranz.commit;
  ValutaDbase.close;
end;

{
// =============================================================================
                 procedure TNAPIKezd.NaploNapiPrintBejegyzes;
// =============================================================================

begin
  _pcs := 'SELECT * FROM NAPLO' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39)+_kertdatums + chr(39);

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _recno := recno;
    end;


  _status := 0;
  if _recno>0 then _status := ValutaQuery.FieldByNAme('STATUS').asInteger;

  _status := _status or 2;
  ValutaQuery.close;
  Valutadbase.close;


  // ------------------------------

  if _recno=0 then
    begin
      _pcs := 'INSERT INTO NAPLO (DATUM,STATUS)' + _sorveg;
      _pcs := _pcs + 'VALUES (' +chr(39) + _kertdatums + chr(39)+','+inttostr(_status)+')';
    end else
    begin
      _pcs := 'UPDATE NAPLO SET STATUS=' + inttostr(_status)+_sorveg;
      _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _kertdatums + chr(39);
    end;
  ValutaParancs(_pcs);
end;
}


// =============================================================================
                procedure TNapiKezd.EgynapiRekordInsert;
// =============================================================================

begin
  _pcs := 'DELETE FROM NAPIKEZD WHERE DATUM='+CHR(39)+_kertdatums+chr(39);
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO NAPIKEZD (DATUM,KEZDOSORSZAM,VEGSORSZAM,BEDARAB,KIDARAB,';
  _pcs := _pcs + 'NYITO,OSSZBEVETEL,OSSZKIADAS,OSSZESEN,ZARO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _kertdatums + chr(39) + ',';
  _pcs := _pcs + inttostr(_kezdosorszam) + ',';
  _pcs := _pcs + inttostr(_lastsorszam) + ',';
  _pcs := _pcs + inttostr(_bedarab) + ',';
  _pcs := _pcs + inttostr(_kidarab) + ',';
  _pcs := _pcs + inttostr(_nyito) + ',';
  _pcs := _pcs + inttostr(_osszbevetel) + ',';
  _pcs := _pcs + inttostr(_osszkiadas) + ',';
  _pcs := _pcs + inttostr(_osszesen) + ',';
  _pcs := _pcs + inttostr(_zaro) + ')';

  ValutaParancs(_pcs);
end;





end.
