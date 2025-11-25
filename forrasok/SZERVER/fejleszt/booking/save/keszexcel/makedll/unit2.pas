unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable,
  Strutils, comobj, ComCtrls, ExtCtrls, TlHelp32;

type
  TForm2 = class(TForm)

    BookTABLA    : TIBTable;
    BookQUERY    : TIBQuery;
    BookDBASE    : TIBDatabase;
    BookTRANZ    : TIBTransaction;

    RemoteQuery  : TIBQuery;
    RemoteDbase  : TIBDatabase;
    RemoteTranz  : TIBTransaction;

    Csik         : TProgressBar;
    Csik2        : TProgressBar;

    Kilepo       : TTimer;

    ProgressPanel: TPanel;
    Prog2Panel   : TPanel;

    Label1       : TLabel;
    Label2       : TLabel;

    procedure AdatLezaras;
    procedure EgyKftExcelKeszitese;
    procedure Kftfejlec;
    procedure FormActivate(Sender: TObject);
    procedure IrodaBeolvasas;
    procedure Munkamenet;
    procedure KftSummazas;
    procedure KillExcel;
    procedure KilepoTimer(Sender: TObject);
    procedure KftSumKiirasa;
    procedure Sumnullazas;
    procedure UjkorzetNyitas;
    procedure UjPenztarNyitas;
    procedure VastagKeret(_rs: string; _sh: byte);
    procedure VekonyKeret(_rs: string; _sh: byte);

    function Nulele(_b: byte): string;
    function ScanPenztar(_pt: byte): byte;
    function Getpenztarnev(_pt: byte): string;
    function GetKorzetnev(_kz: byte): string;
    function Scankorzet(_k: byte): byte;
    function ScanDnem(_sd: string): byte;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _proc: PROCESSENTRY32;
  _looper: boolean;
  _handle: HWND;

  _host: string = '185.43.207.99';

  _kftbetuk: array[1..4] of string = ('B','E','P','Z');
  _kftNevek: array[1..4] of string = ('Best Change','East Change','Pannon Change',
                                                      'Expressz Zálog');

  _honev: array[1..12] of string = ('JANUAR','FEBRUAR','MARCIUS','APRILIS','MAJUS',
                         'JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                         'NOVEMBER','DECEMBER');

  _korzetnevek   : array[1..9] of string = ('SZEGED','KECSKEMÉT','DEBRECEN',
              'NYÍREGYHÁZA','BÉKÉSCSABA','SZEKSZÁRD','PÉCS','KAPOSVÁR','ZÁLOG');

  _korzetszamok: array[1..9] of byte = (20,40,50,63,75,10,120,145,180);

  _dnem: ARRAY[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
             'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK',
             'NZD','PLN','RON','RSD','RUB','SEK','THB','TRY','UAH','USD');

  _cegbetu,_penztarnev    : array[1..170] of string;
  _korzetszam,_penztarszam: array[1..170] of byte;

  _sumNyito,_sumZaro,_sumAd,_sumKap,_sumvett,_sumeladott: array[1..27] of real;


  _owb,_oxl,_range: OleVariant;

  _penztardarab,_dnemIndex: byte;

  _kftindex,_aktpenztar,_aktkorzet,_utPenztar,_utkorzet,_xx: byte;
  _aktev,_aktho,_top,_left,_width,_height,_uzlet,_exs,_pp,_startsor,_endsor: word;
  _recno: integer;

  _aktad,_aktkap,_vettertek,_eladottertek,_nyito,_zaro,_forgdiff,_trdiff: real;
  _vettbjegy,_eladottbjegy: real;
  _focim,_aktevs,_farok,_keszExcelNev,_keszExcelPath,_rPath,_aktnev,_pcs: string;
  _aktKftNev,_aktkftBetu,_aktPenztarnev,_rangestr,_aktCegBetu,_aktdnem: string;
  _qs,_aktkorzetnev: string;

  _sorveg: string = chr(13)+chr(10);

  _adatokLezarva: boolean;

function keszletexcelrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
            function keszletexcelrutin: integer; stdcall;
// =============================================================================

begin
  Form2 := Tform2.Create(Nil);
  result := form2.ShowModal;
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

  Repaint;

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
  _farok  := midstr(_aktevs,3,2)+nulele(_aktho);

  _keszexcelnev  := 'KESZ' + _farok + '.XLS';
  _keszexcelPath := 'C:\BOOKING\EXCEL\' + _keszexcelnev;

  Csik2.Max := 5;
  // --------------------------------------------

  Irodabeolvasas;
  Csik2.Position := 1;

  Munkamenet;

  if fileExists(_keszExcelPath) then Sysutils.DeleteFile(_keszExcelPath);
  _owb.Saveas(_keszExcelPath);

  Kilepo.Enabled := true;
end;

// =============================================================================
                       procedure TForm2.Munkamenet;
// =============================================================================

begin

  ProgressPanel.Caption := 'Készletek feldolgozása';
  ProgressPanel.repaint;

  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add(1);
  _oxl.workbookS[1].sheets.add(,,4);

  Csik2.Max := 4;
  _kftindex := 1;

  while _kftindex<=4 do
    begin
      Csik2.Position := _kftindex;

      _aktkftnev := _kftnevek[_kftindex];
      Prog2Panel.Caption := _aktkftnev;
      Prog2Panel.repaint;

      _oxl.workbooks[1].worksheets[_kftindex].name := _aktkftnev;

      Kftfejlec;
      EgyKftExcelKeszitese;

      inc(_kftindex);
    end;
end;

// =============================================================================
                  procedure TForm2.Kftfejlec;
// =============================================================================

begin
  if _kftindex<4 then _Focim := 'EXCLUSIVE '+uppercase(_aktkftnev)+' KFT '
  else _focim := 'EXPRESSZ ÉKSZERHÁZ ';
  _focim := _focim + inttostr(_aktev)+' '+_honev[_aktho]+' HAVI KÉSZLETEI';


  // AZ OSZLOP SZÉLESSÉGÉT ÁLLITJA MEG:

  _oxl.worksheets[_kftindex].range['A1:A1'].columnWidth  := 18;
  _oxl.worksheets[_kftindex].range['B1:B1'].columnWidth  := 30;
  _oxl.worksheets[_kftindex].range['C1:C1'].columnWidth  := 25;
  _oxl.worksheets[_kftindex].range['D1:D1'].columnWidth  := 25;
  _oxl.worksheets[_kftindex].range['E1:E1'].columnWidth  := 25;
  _oxl.worksheets[_kftindex].range['F1:F1'].columnWidth  := 25;

  // KFT FÕCIM KIIRÁSA

  _rangestr := 'B2:F2';

  _oxl.worksheets[_kftindex].range[_rangestr].MergeCells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name  := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Bold  := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Italic:= True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size  := 16;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.color := clTeal;
  _oxl.worksheets[_kftindex].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Interior.color := $FFB0FF;
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


  // Fejléc: Nyitó készlet

  _rangestr := 'C4:C5';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Verticalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].WrapText := true;
  _oxl.worksheets[_kftindex].Cells[4,3] := 'NYITÓ KÉSZLET';

  // Fejléc: Egyenleg

  _rangestr := 'D4:E4';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Verticalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].WrapText := true;
  _oxl.worksheets[_kftindex].Cells[4,4] := 'EGYENLEG';

  // Fejléc: Zárókészlet

  _rangestr := 'F4:F5';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Verticalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].WrapText := true;
  _oxl.worksheets[_kftindex].Cells[4,6] := 'ZÁRÓ KÉSZLET';

  // Fejléc: Adás-vétel

  _rangestr := 'D5:E5';
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].WrapText := true;
  _oxl.worksheets[_kftindex].Cells[5,4] := 'ADÁS-VÉTEL';
  _oxl.worksheets[_kftindex].Cells[5,5] := 'ÁTADÁS-ÁTVÉTEL';

  _rangestr := 'D5:D5';
   Vekonykeret(_rangestr,_kftindex);

  _rangestr := 'B4:B5';
   VastagKeret(_rangestr,_kftindex);

  _rangestr := 'C4:C5';
   VastagKeret(_rangestr,_kftindex);

  _rangestr := 'D4:E4';
   VastagKeret(_rangestr,_kftindex);

  _rangestr := 'F4:F5';
   VastagKeret(_rangestr,_kftindex);

  _rangestr := 'D5:E5';
  VastagKeret(_rangestr,_kftindex);

  // Fagyasztások:

  _oxl.workbooks[1].worksheets[_kftindex].select;
  _rangestr := 'A6:A6';
  _range := _oxl.range[_rangestr];
  _range.Select;
  _oxl.ActiveWindow.FreezePanes := True;

  _exs := 7;

end;

// =============================================================================
               procedure TForm2.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;

  _OWB := unassigned;
  _oxl.quit;
  _oxl := unassigned;

  KillExcel;
  Modalresult := 1;
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
                     function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
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
      _cegbetu[_pp]    := '';
      _korzetszam[_pp] := 0;
      _penztarszam[_pp]:= 0;
      _penztarnev[_pp] := '';
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
      Sql.clear;
      Sql.add(_pcs);
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
          _aktPenztar    := fieldbyname('UZLET').asInteger;
          _aktKorzet     := FieldByNAme('ERTEKTAR').asInteger;
          _aktcegBetu    := FieldByNAme('CEGBETU').asString;
          _aktPenztarNev := trim(FieldByName('KESZLETNEV').asstring);
        end;

      _penztarszam[_pp] := _aktPenztar;
      _penztarNev[_pp]  := _aktPenztarNev;
      _korzetszam[_pp]  := _aktkorzet;
      _cegBetu[_pp]     := _aktcegbetu;
      RemoteQuery.next;
    end;
  RemoteQuery.close;
  RemoteDbase.close;

  // -----------------------------------------

  _rPath := _host + ':C:\CARTCASH\DATABASE\ARTCASH.FDB';
  with RemoteDbase do
    begin
      Close;
      Databasename := _rPath;
      Connected := True;
    end;

  with remoteQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  while not RemoteQuery.eof do
    begin
      inc(_pp);
      Csik.Position := _pp;

      with remoteQuery do
        begin
          _aktpenztar    := Fieldbyname('UZLET').asInteger;
          _aktPenztarNev := trim(FieldByName('KESZLETNEV').asstring);
        end;

      _penztarszam[_pp] := _aktPenztar;
      _penztarnev[_pp]  := _aktPenztarNev;
      _korzetszam[_pp]  := 180;
      _cegbetu[_pp]     := 'Z';

      RemoteQuery.next;
    end;
  RemoteQuery.close;
  RemoteDbase.close;

  _penztarDarab := _pp;
  Csik.Position := 170;

  sleep(1800);
  Csik.Position := 0;

  ProgressPanel.Caption := '';
  ProgressPanel.repaint;
end;

// =============================================================================
            function TForm2.ScanPenztar(_pt: byte): byte;
// =============================================================================

var _k: byte;

begin
  result := 0;
  _k := 1;
  while _k<=_penztardarab do
    begin
      if _penztarszam[_k]=_pt then
        begin
          _aktkftbetu := _cegbetu[_k];
          _aktkorzet  := _korzetszam[_k];
          _aktpenztarnev := _penztarnev[_k];
          result := _k;
          exit;
        end;
      inc(_k);
    end;
end;

// =============================================================================
                  procedure TForm2.EgyKftExcelKeszitese;
// =============================================================================

begin
  _aktKftBetu    := _kftbetuk[_kftindex];
  _utkorzet      := 0;
  _utPenztar     := 0;
  _adatokLezarva := True;
  _exs           := 7;

  Sumnullazas;

  _pcs := 'SELECT *FROM TRANZAKCIOK' + _sorveg;
  _pcs := _pcs + 'WHERE KFT=' + chr(39) + _aktkftbetu + chr(39) + _sorveg;
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

  _pp := 0;
  while not BookQuery.eof do
    begin
      inc(_pp);
      Csik.position := _pp;
      with BookQuery do
        begin
          _aktkorzet    := FieldByname('KORZET').asInteger;
          _aktPenztar   := FieldByName('PENZTAR').asInteger;
          _aktdnem      := FieldByNAme('VALUTANEM').asString;
          _aktad        := FieldByNAme('ATADAS').asInteger;
          _aktkap       := FieldByNAme('ATVETEL').asInteger;
          _vettbjegy    := FieldByNAme('VETTBANKJEGY').asInteger;
          _eladottbjegy := FieldByNAme('ELADOTTBANKJEGY').asInteger;
          _nyito        := FieldByNAme('NYITO').AsInteger;
          _zaro         := FieldByNAme('ZARO').AsInteger;
        end;

      _trDiff       := _aktkap-_aktad;
      _forgDiff     := _vettbjegy-_eladottbjegy;

      KftSummazas;

      if _aktPenztar<>_utPenztar then
        begin
          if not _adatokLezarva then AdatLezaras;
          if _utkorzet<>_aktkorzet then UjkorzetNyitas;
          UjPenztarnyitas;
        end;
      _utpenztar := _aktpenztar;
      _utKorzet  := _aktkorzet;

      if _aktdnem='HUF' then _forgdiff := _zaro-_nyito-_trDiff;

      _oxl.worksheets[_kftindex].Cells[_exs,2] := _aktdnem;
      _oxl.worksheets[_kftindex].Cells[_exs,3] := _nyito;
      _oxl.worksheets[_kftindex].Cells[_exs,4] := _forgdiff;
      _oxl.worksheets[_kftindex].Cells[_exs,5] := _trdiff;
      _oxl.worksheets[_kftindex].Cells[_exs,6] := _zaro;
      _adatokLezarva := False;

      inc(_exs);
      BookQuery.next;
    end;
  Bookquery.close;
  Bookdbase.close;
  AdatLezaras;

  KftSumKiirasa;
end;

procedure TForm2.KftSumKiirasa;

var _kftnev: string;

begin

  _qs := inttostr(_exs);
  _rangestr := 'B' + _qs + ':F' + _qs;
  _startsor := _exs+1;

  _oxl.worksheets[_kftindex].range[_rangestr].MergeCells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name  := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size  := 14;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Color := clyellow;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;

  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold      := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic    := True;
  _oxl.worksheets[_kftindex].range[_rangestr].interior.color := clred;

  _kftnev := _kftnevek[_kftindex];
  _oxl.worksheets[_kftindex].Cells[_exs,2] := _kftnev+' ÖSSZESEN';
  inc(_exs);

  _dnemIndex := 1;
  while _dnemIndex<=27 do
    begin
      _trDiff       := _sumkap[_dnemindex]-_sumad[_dnemindex];
      _forgDiff     := _sumvett[_dnemindex]-_sumeladott[_dnemindex];

      _oxl.worksheets[_kftindex].Cells[_exs,2] := _dnem[_dnemindex];
      _oxl.worksheets[_kftindex].Cells[_exs,3] := _sumnyito[_dnemindex];
      _oxl.worksheets[_kftindex].Cells[_exs,4] := _forgdiff;
      _oxl.worksheets[_kftindex].Cells[_exs,5] := _trdiff;
      _oxl.worksheets[_kftindex].Cells[_exs,6] := _sumzaro[_dnemindex];
      inc(_exs);
      inc(_dnemIndex);
    end;
   AdatLezaras;
end;

// =============================================================================
                       procedure TForm2.Sumnullazas;
// =============================================================================

begin
  _dnemindex := 1;
  while _dnemindex<=27 do
    begin
      _sumNyito[_dnemIndex]   := 0;
      _sumZaro[_dnemIndex]    := 0;
      _sumAd[_dnemIndex]      := 0;
      _sumKap[_dnemIndex]     := 0;
      _sumvett[_dnemIndex]    := 0;
      _sumeladott[_dnemIndex] := 0;
      inc(_dnemIndex);
    end;
end;

// =============================================================================
                        procedure TForm2.KftSummazas;
// =============================================================================

begin
  _xx := scandnem(_aktdnem);
  _sumnyito[_xx] := _sumnyito[_xx] + _nyito;
  _sumZaro[_xx] := _sumZaro[_xx] + _zaro;
  _sumad[_xx] := _sumad[_xx] +_aktad;
  _sumkap[_xx] := _sumkap[_xx] +_aktkap;
  _sumvett[_xx] := _sumvett[_xx] + _vettbjegy;
  _sumeladott[_xx] := _sumeladott[_xx] + _eladottbjegy;
end;

// =============================================================================
                procedure TForm2.AdatLezaras;
// =============================================================================

begin
  _endsor := _exs-1;
  _rangestr := 'B'+inttostr(_startsor)+':B'+inttostr(_endsor);

  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.italic := true;

  _rangestr := 'C'+inttostr(_startsor)+':F'+inttostr(_endsor);
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].NumberFormat := '### ### ###';
  _adatokLezarva := True;
  inc(_exs);
end;

// =============================================================================
                    procedure Tform2.UjkorzetNyitas;
// =============================================================================

begin
  _aktkorzetnev := GetKorzetnev(_aktkorzet);
  _qs := inttostr(_exs);
  _rangestr := 'B'+_qs + ':F'+_qs;

  _oxl.worksheets[_kftindex].range[_rangestr].MergeCells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name  := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size  := 14;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Color := clteal;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;

  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].interior.color := $D8DDB6;
  _oxl.worksheets[_kftindex].Cells[_exs,2] := _aktkorzetnev;
  inc(_exs);
end;

// =============================================================================
                   procedure TForm2.UjPenztarNyitas;
// =============================================================================

begin
  _aktpenztarnev := getPenztarnev(_aktpenztar);

  _qs := inttostr(_exs);
  _rangestr := 'B'+_qs + ':C'+_qs;


  _oxl.worksheets[_kftindex].range[_rangestr].MergeCells  := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name   := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size   := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold   := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].interior.color := clYellow;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].Cells[_exs,2] := _aktpenztarnev;
  inc(_EXS);

  _startsor := _exs;
end;

// =============================================================================
            function TForm2.Getpenztarnev(_pt: byte): string;
// =============================================================================

begin
  _xx := Scanpenztar(_pt);
  result := inttostr(_pt)+'. '+_penztarnev[_xx];
end;

// =============================================================================
           function TForm2.GetKorzetnev(_kz: byte): string;
// =============================================================================

begin
  _xx := ScanKorzet(_kz);
  result := _korzetnevek[_xx]+'I KÖRZET';
end;

// =============================================================================
            function TForm2.Scankorzet(_k: byte): byte;
// =============================================================================

var _q: byte;

begin
  result := 0;
  _q := 1;
  while _q<=9 do
    begin
      if _korzetszamok[_q]=_k then
        begin
          result := _q;
          exit;
        end;
      inc(_q);
    end;
end;

// =============================================================================
                function TForm2.ScanDnem(_sd: string): byte;
// =============================================================================

var _q: byte;

begin
  _q := 1;
  result := 0;
  while _q<=27 do
    begin
      if _dnem[_q] = _sd then
        begin
          result := _q;
          exit;
        end;
      inc(_q);
    end;
end;
end.
