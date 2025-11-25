unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ComObj, ExtCtrls, ComCtrls, strUtils, TlHelp32;

type
  TForm2 = class(TForm)
    BOOKQUERY: TIBQuery;
    BOOKDBASE: TIBDatabase;
    BOOKTRANZ: TIBTransaction;

    RemoteQuery  : TIBQuery;
    RemoteDbase  : TIBDatabase;
    RemoteTranz  : TIBTransaction;

    AlapPanel    : TPanel;
    ProgressPanel: TPanel;
    Prog3Panel   : TPanel;
    Prog2Panel   : TPanel;

    Csik         : TProgressBar;
    Csik2        : TProgressBar;

    Label1       : TLabel;
    Label2       : TLabel;
    KILEPO: TTimer;

    procedure AdatLezaras;
    procedure AdatokBeirasa;
    procedure IrodaBeolvasas;
    procedure FormActivate(Sender: TObject);
    procedure KillExcel;
    procedure MunkaMenet;
    procedure KFTFejlec;
    procedure KilepoTimer(Sender: TObject);
    procedure EgyAdatSorBeirasa;
    procedure UjKorzetNyitas;
    procedure Ujpenztarnyitas;
    procedure VastagKeret(_rs: string; _sh: byte);
    procedure VekonyKeret(_rs: string; _sh: byte);

    function GetKorzetnev(_kn: byte): string;
    function Kiez(_tps: string): string;
    function Nulele(_b: byte): string;
    function ScanKorzet(_knum: byte): byte;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _host: string = '185.43.207.99';

  _kftNevek: array[1..2] of string = ('Best Change','Expressz Zálog');

  _honev: array[1..12] of string = ('JANUAR','FEBRUAR','MARCIUS','APRILIS','MAJUS',
                         'JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                         'NOVEMBER','DECEMBER');


  _korzetszamok: array[1..9] of byte = (20,40,50,63,75,10,120,145,180);
  _korzetnevek : array[1..9] of string = ('SZEGED','KECSKEMÉT','DEBRECEN',
              'NYÍREGYHÁZ','BÉKÉSCSABA','SZEKSZÁRD','PÉCS','KAPOSVÁR','ZÁLOG');

  _penztarnev: array[1..170] of string;

  _proc: PROCESSENTRY32;
  _handle: HWND;

  _LOOPER: boolean;

  _pcs,_qs,_korzetnev: string;
  _sorveg: string = chr(13)+chr(10);

  _kftindex,_aktkorzet,_aktpenztar,_utpenztar,_uzlet,_utkorzet: byte;
  _korzetIndex: byte;
  _y,_aktev,_aktho,_exs,_xx,_startsor,_endsor,_pp: word;
  _top,_left,_width,_height: word;
  _kftbetuk: array[1..2] of string = ('B','Z');
  _aktKftBetu,_aktkftnev,_focim,_rangestr,_aktdnem: string;
  _aktad,_aktkap: real;
  _tpz,_code,_recno: integer;
  _tarspenztar,_rpath,_apath,_aktnev,_aktevs,_farok: string;
  _advetexcelnev,_advetexcelpath,_pnev: string;

  _adatokLezarva,_vanexcel: boolean;

  _oxl,_owb,_range: OleVariant;


function advetexcelrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
             function advetexcelrutin: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.Showmodal;
  Form2.Free;
end;

// =============================================================================
               procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].width;

  _top    := 128 + round((_height-450)/2);
  _left   := 8 + round((_width-441)/2);

  Top     := _top-100;
  Left    := _left;
  Height  := 329;
  Width   := 441;

  Label1.Repaint;
  Label2.Repaint;

  BookDbase.close;
  BookDbase.DatabaseName := 'C:\BOOKING\DATABASE\BOOKING.FDB';
  BookDbase.Connected := True;

  with BookQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM EVHONAP');
      Open;
      _aktev := FieldByNAme('EV').asInteger;
      _aktho := FieldByName('HONAP').asInteger;
      Close;
    end;
  BookDbase.close;

  _aktevs := inttostr(_aktev);
  _farok := midstr(_aktevs,3,2)+nulele(_aktho);

  _advetexcelnev := 'ADVET' + _farok + '.XLS';
  _advetexcelPath := 'C:\BOOKING\EXCEL\' + _advetexcelnev;

  // --------------------------------------------

  _vanExcel := False;
  Irodabeolvasas;
  Munkamenet;

  if fileExists(_advetexcelPath) then Sysutils.DeleteFile(_advetexcelPath);
  _owb.Saveas(_advetexcelPath);

  Kilepo.Enabled := true;
end;

// =============================================================================
                 procedure TForm2.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;

  if _vanexcel then
    begin
      _OWB := unassigned;
      _oxl.quit;
      _oxl := unassigned;
    end;

  KillExcel;
  Modalresult := 1;
end;


// =============================================================================
                       procedure TForm2.Munkamenet;
// =============================================================================

begin
  ProgressPanel.Caption := 'Tranzakciók bedolgozása';
  ProgressPanel.repaint;

  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add(1);
  _oxl.workbookS[1].sheets.add(,,2);

  _vanexcel := True;

  Csik2.Max := 8;
  _kftindex := 1;
  while _kftindex<=2 do
    begin
      Csik2.Position := _kftindex;
      _aktkftnev := _kftnevek[_kftindex];

      Prog2Panel.Caption := _aktkftnev;
      Prog2Panel.repaint;

      _oxl.workbooks[1].worksheets[_kftindex].name := _aktkftnev;

      Kftfejlec;

      inc(_kftindex);
    end;

  _kftindex := 1;
  while _kftindex<=2 do
    begin
      Csik2.Position := _kftindex+2;

      AdatokBeirasa;

      inc(_kftindex);
      Csik2.Position := 8;
    end;
end;

// =============================================================================
                procedure TForm2.KFTFejlec;
// =============================================================================

begin

  if _kftindex=1 then _Focim := 'EXCLUSIVE BEST CHANGE KFT '
  else _focim := 'EXPRESSZ ÉKSZERHÁZ ';
  _focim := _focim + inttostr(_aktev)+' '+_honev[_aktho]+' HAVI ÁTADÁS-ÁTVÉTELEI';


  // AZ OSZLOP SZÉLESSÉGÉT ÁLLITJA MEG:

  _oxl.worksheets[_kftindex].range['A1:A1'].columnWidth  := 16;
  _oxl.worksheets[_kftindex].range['B1:B1'].columnWidth  := 12;
  _oxl.worksheets[_kftindex].range['C1:C1'].columnWidth  := 18;
  _oxl.worksheets[_kftindex].range['D1:D1'].columnWidth  := 45;
  _oxl.worksheets[_kftindex].range['E1:E1'].columnWidth  := 18;
  _oxl.worksheets[_kftindex].range['F1:F1'].columnWidth  := 45;

  // KFT FÕCIM KIIRÁSA

  _rangestr := 'B2:F2';
  _oxl.worksheets[_kftindex].range[_rangestr].MergeCells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name  := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Bold  := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Italic:= True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size  := 16;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.color := clTeal;
  _oxl.worksheets[_kftindex].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Interior.color := $f8e4c0;
  _oxl.worksheets[_kftindex].Cells[2,2] := _focim;

  // -------------------------------------------------------------------

  // Fejléc : A VALUTA NEME

  _rangestr := 'B4:B5';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Verticalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size   := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold   := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].WrapText    := True;
  _oxl.worksheets[_kftindex].Cells[4,2] := 'VALUTA NEME';


  // Fejléc: Átadott bankjegy

  _rangestr := 'C4:C5';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Verticalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].WrapText := true;
  _oxl.worksheets[_kftindex].Cells[4,3] := 'ÁTADOTT BANKJEGY';

  // Fejléc: Hova lett átutalva

  _rangestr := 'D4:D5';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Verticalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[4,4] := 'HOVA LETT ÁTUTALVA';

  // Fejléc: Átvett bankjegy

  _rangestr := 'E4:E5';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Verticalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].WrapText := true;
  _oxl.worksheets[_kftindex].Cells[4,5] := 'ÁTVETT BANKJEGY';

  // Fejléc: Honnan lett átutalva

  _rangestr := 'F4:F5';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Verticalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[4,6] := 'HONNAN LETT ÁTUTALVA';

  // Keretezés:

  _rangestr:='D4:D5';
  Vekonykeret(_rangestr,_kftindex);

  _rangestr:='F4:F5';
  Vekonykeret(_rangestr,_kftindex);

  _rangestr:='B4:B5';
  VastagKeret(_rangestr,_kftindex);

  _rangestr:='B4:D5';
  VastagKeret(_rangestr,_kftindex);

  _rangestr:='B4:F5';
  VastagKeret(_rangestr,_kftindex);

  // Fagyasztások:

  _oxl.workbooks[1].worksheets[_kftindex].select;
  _rangestr := 'A7:A7';
  _range := _oxl.range[_rangestr];
  _range.Select;
  _oxl.ActiveWindow.FreezePanes := True;

  _exs := 7;
end;

// =============================================================================
                         procedure TForm2.Adatokbeirasa;
// =============================================================================
//                      Egy kft teljes adatainak beirása

begin
  _aktKftBetu    := _kftbetuk[_kftindex];
  _utKorzet      := 0;
  _utpenztar     := 0;
  _adatokLezarva := True;
  _exs           := 7;

  _pcs := 'SELECT *FROM ATADATVET' + _sorveg;
  _pcs := _pcs + 'WHERE KFT=' + chr(39)+_aktkftbetu +chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY KORZET,PENZTAR,VALUTANEM';

  BookDbase.close;
  Bookdbase.DatabaseName := 'c:\booking\database\booking.fdb';
  BookDbase.Connected := True;

  with BookQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Max := _recno;
  Csik.Position := 0;

  _pp       := 0;
  _startsor := _exs;
  while not BookQuery.Eof do
    begin
      inc(_pp);
      Csik.Position := _pp;

      _aktkorzet   := BookQuery.FieldByname('KORZET').asInteger;
      _aktPenztar  := BookQuery.FieldByName('PENZTAR').asInteger;
      _aktdnem     := BookQuery.FieldByNAme('VALUTANEM').asString;
      _aktad       := BookQuery.FieldByNAme('ATADAS').asInteger;
      _aktkap      := BookQuery.FieldByNAme('ATVETEL').asInteger;
      _tarspenztar := trim(BookQuery.FieldByNAme('TARSPENZTAR').AsString);

      if _aktpenztar<>_utpenztar then
         begin
           if not _adatokLezarva then AdatLezaras;
           if _utkorzet<>_aktkorzet then UjkorzetNyitas;
           UjPenztarNyitas;
         end;

      _utpenztar := _aktPenztar;
      _utKorzet  := _aktKorzet;

      EgyAdatsorBeirasa;
      _adatokLezarva := False;

      inc(_exs);
      BookQuery.next;
    end;

  Adatlezaras;
  BookQuery.close;
  BookDbase.close;
end;

// =============================================================================
                    procedure TForm2.EgyadatsorBeirasa;
// =============================================================================

begin
  _oxl.worksheets[_kftindex].Cells[_exs,2] := _aktdnem;
  if _aktad>0 then
    begin
      _oxl.worksheets[_kftindex].Cells[_exs,3] := _aktad;
      _oxl.worksheets[_kftindex].Cells[_exs,4] := kiez(_tarspenztar);
    end;

  if _aktkap>0 then
    begin
      _oxl.worksheets[_kftindex].Cells[_exs,5] := _aktkap;
      _oxl.worksheets[_kftindex].Cells[_exs,6] := kiez(_tarspenztar);
    end;
end;

// =============================================================================
                        procedure TForm2.Ujkorzetnyitas;
// =============================================================================

begin
  _korzetnev := Getkorzetnev(_aktkorzet) + 'I KÖRZET';
  Prog2Panel.Caption := _korzetNev;
  Prog2Panel.Repaint;

  _qs := inttostr(_exs);
  _rangestr := 'B'+_qs + ':F' + _qs;
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 14;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Color := clPurple;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].interior.color := $BACADF;
  _oxl.worksheets[_kftindex].Cells[_exs,2] := _korzetnev;
  inc(_exs);
end;

// =============================================================================
             function TForm2.GetKorzetnev(_kn: byte): string;
// =============================================================================

begin
  _korzetindex := ScanKorzet(_kn);
  result := _korzetnevek[_korzetindex];
end;

// =============================================================================
               function TForm2.ScanKorzet(_knum: byte): byte;
// =============================================================================

var _k: byte;

begin
  result := 0;
  _k := 1;
  while _k<=9 do
    begin
      if _korzetszamok[_k]=_knum then
        begin
          result := _k;
          exit;
        end;
      inc(_k);
    end;
end;

// =============================================================================
                    procedure TForm2.AdatLezaras;
// =============================================================================

begin
  _endsor := _exs-1;

 //  valutanemek:

  _rangestr := 'B'+inttostr(_startsor)+':B'+inttostr(_endsor);
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.italic := true;

  // átadott bankjegy:

  _rangestr := 'C'+inttostr(_startsor)+':C'+inttostr(_endsor);
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].NumberFormat := '### ### ###';

  // átvett bankjegy:

  _rangestr := 'E'+inttostr(_startsor)+':E'+inttostr(_endsor);
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].NumberFormat := '### ### ###';
  _exs := _exs + 1;
  _adatokLezarva := True;
end;

// =============================================================================
                       procedure TForm2.Ujpenztarnyitas;
// =============================================================================

var _ps: string;

begin
  _rangestr := 'B'+inttostr(_exs)+':F'+ inttostr(_exs);

  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].interior.color := clYellow;
  _ps := inttostr(_aktpenztar);

  _pnev := Kiez(_ps);
  _oxl.worksheets[_kftindex].Cells[_exs,2] := _pNev;

  prog3Panel.Caption := _pNev;
  Prog3Panel.repaint;

  _exs       := _exs + 2;
  _startsor  := _exs;
end;

// =============================================================================
                function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
           procedure TForm2.Vastagkeret(_rs: string; _sh: byte);
// =============================================================================

begin
  _oxl.worksheets[_sh].range[_rs].borderAround(1,4);
end;

// =============================================================================
          procedure TForm2.Vekonykeret(_rs: string; _sh: byte);
// =============================================================================

begin
  _oxl.worksheets[_sh].range[_rs].borderAround(1,2);
end;

// =============================================================================
                  procedure TForm2.KillExcel;
// =============================================================================

var
  _fileName,_filePath: String;

begin

  _Proc.dwSize := SizeOf(_Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,_proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := _Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),_proc.th32ProcessID),0);
          break;
        end;

      _Looper := Process32Next(_handle,_proc);
    end;
  CloseHandle(_handle);
end;

// =============================================================================
                procedure TForm2.IrodaBeolvasas;
// =============================================================================

var _pp: byte;

begin
  _pp := 1;
  while _pp<=170 do
    begin
      _penztarnev[_pp] := 'ismeretlen';
      inc(_pp);
    end;

  ProgressPanel.Caption := 'IRODÁK BEOLVASÁSA ...';
  ProgressPanel.repaint;

  _Rpath := _host + ':C:\RECEPTOR\DATABASE\RECEPTOR.FDB';

  with RemoteDbase do
    begin
      close;
      databasename := _RPath;
      Connected := True;
    end;

  _pcs := 'SELECT * FROM IRODAK';
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _pp := 0;
  while not RemoteQuery.eof do
    begin
      inc(_pp);
      Csik.Position := _pp;

      with remoteQuery do
        begin
          _uzlet  := fieldbyname('UZLET').asInteger;
          _aktnev := trim(FieldByName('KESZLETNEV').asstring);
        end;

      _penztarnev[_uzlet] := _aktnev;
      RemoteQuery.next;
    end;
  RemoteQuery.close;
  RemoteDbase.close;

  // -----------------------------------------

  _Apath := _host + ':C:\CARTCASH\DATABASE\ARTCASH.FDB';
  with RemoteDbase do
    begin
      close;
      databasename := _APath;
      Connected := True;
    end;

  with remoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not RemoteQuery.eof do
    begin
      inc(_pp);
      Csik.Position := _pp;
      with remoteQuery do
        begin
          _uzlet  := fieldbyname('UZLET').asInteger;
          _aktnev := trim(FieldByName('KESZLETNEV').asstring);
        end;
      _penztarnev[_uzlet] := _aktnev;
      RemoteQuery.next;
    end;
  RemoteQuery.close;
  RemoteDbase.close;

  Csik.Position := 170;

  sleep(1800);
  Csik.Position := 0;
  ProgressPanel.Caption := '';
  ProgressPanel.repaint;
end;

// =============================================================================
              function TForm2.Kiez(_tps: string): string;
// =============================================================================

begin
  val(_tps,_tpz,_code);
  if _code<>0 then _tpz := 0;
  if _tpz=0 then
    begin
      if _tps='TH' then
        begin
          result := 'többlet-hiány pénztár';
          exit;
        end;
      result := _tps + ' BANK';
      exit;
    end;
  if _tpz=1 then
    begin
      result := ' 1. Fõpénztár';
      exit;
    end;
  result := _tps+'. '+_penztarnev[_tpz];
end;
end.

