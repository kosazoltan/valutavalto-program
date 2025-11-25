unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, wininet, idGlobal, StdCtrls, ComCtrls, StrUtils, jpeg,
  Comobj, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery, TlHelp32;

type
  TForm2 = class(TForm)

    Kilepo       : TTimer;

    ArtQuery     : TIBQuery;
    ArtDbase     : TIBDatabase;
    ArtTranz     : TIBTransaction;

    BookQuery    : TIBQuery;
    BookDbase    : TIBDatabase;
    BookTranz    : TIBTransaction;

    RemoteQuery  : TIBQuery;
    RemoteDbase  : TIBDatabase;
    RemoteTranz  : TIBTransaction;

    Label1       : TLabel;
    Label2       : TLabel;

    Csik2        : TProgressBar;
    Csik         : TProgressBar;

    ProcessPanel : TPanel;
    Prog2Panel   : TPanel;
    Prog3Panel   : TPanel;

    procedure AdatLezaras;
    procedure EgyKftExcelKeszitese;
    procedure FejlecekKeszitese;
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure KillExcel;
    procedure KftFejlec;
    procedure KftOsszesitese;
    procedure KftSummazas;
    procedure MakeForgExcel;
    procedure PenztarBeolvasas;
    procedure PenztarExcelTombRendezes;
    procedure SumNullazas;
    procedure VastagKeret(_rs: string; _sh: byte);
    procedure VekonyKeret(_rs: string; _sh: byte);
    procedure UjKorzetNyitas;
    procedure UjPenztarNyitas;

    function Nulele(_b: byte): string;
    function ScanPenztar(_ptn: byte): byte;
    function ScanKorzet(_kz: byte): byte;
    function ScanValuta(_vn: string): byte;
    function GetKorzetnev(_k: byte): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var

  Form2: TForm2;

  _oxl,_owb,_range: OleVariant;
  _BOOKPath : string = 'c:\booking\database\booking.fdb';

  _host: string = '185.43.207.99';

  _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
            'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN','NOK','NZD',
            'PLN','RON','RSD','RUB','SEK','THB','TRY','UAH','USD');

  _kftnevek : array[1..4] of string = ('Best Change','East Change','Pannon Change',
                                       'Expressz Zalog');

  _kftBetuk: array[1..4] of string = ('B','E','P','Z');
  _honev: array[1..12] of string = ('JANUAR','FEBRUAR','MARCIUS','APRILIS','MAJUS',
                         'JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                         'NOVEMBER','DECEMBER');

  _korzetnevek   : array[1..9] of string = ('SZEGED','KECSKEMÉT','DEBRECEN',
              'NYÍREGYHÁZA','BÉKÉSCSABA','SZEKSZÁRD','PÉCS','KAPOSVÁR','ZÁLOG');

  _korzetszam : array[1..9] of byte = (20,40,50,63,75,10,120,145,180);

  _korzet,_penztar: array[1..170] of byte;
  _kft,_penztarnev: array[1..170] of string;

  _ptnem         : array[1..27] of string;
  _ptAd,_ptKap,_ptVbj,_ptVft,_ptEbj,_ptEKp,_pteBk: array[1..27] of real;
  _ptValNev      : array[1..150,1..27] of string;
  _pValDb        : array[1..150] of byte;

  _ContPtarSor   : array[1..150] of byte;
  _ContPtarNev   : array[1..150] of string;
  _ContKorzetPtDB: array[1..9] of byte;
  _korzPtdb      : array[1..4,1..9] of byte;
  _korzetPtSor   : array[1..9,1..18] of byte;

  _ContKorzetSor : array[1..9] of byte = (20,40,50,63,75,10,120,145,180);
  _korzetDb      : array[1..4] of byte = (2,3,3,1);
  _kftKorzetSor  : array[1..4,1..3] of byte;

  _sumad,_sumkap,_sumvbj,_sumvFt,_sumebj,_sumekp,_sumeBk: array[1..27] of real;

  _aktPanel : TPanel;
  _proc     : PROCESSENTRY32;
  _handle   : HWND;

  _aktkft   : string;
  _aktkorzet,_aktpenztar,_penztardarab,_utpenztar: byte;
  _aktkorzetdb,_korzetss,_aktptdarab: byte;
  _penztarIndex,_korzetIndex,_contPtss,_xpt,_vDarab,_vp,_kftindex: byte;
  _aktkftKorzetdb,_aktkftKorzetszam,_aktkorzetszam,_aktkorzetPtdb: byte;
  _aktpenztarszam,_Contptardb,_spp,_ContkorzetIndex,_tag,_utkorzet: byte;

  _y,_aktev,_aktho,_xx,_ptpp,_startsor,_endsor,_exs,_contindex: word;
  _top,_left,_height,_width: word;

  _atadas,_atvetel,_vettbjegy,_eladottbjegy,_eladottkp,_eladottbk: real;

  _recno,_pp: integer;

  _ptsumvet,_ptsumeladkp,_ptsumeladbk,_vettertek: real;

  _aktkftnev,_rangestr,_focim,_forgTabla,_pcs,_aktkorzetnev,_aktdnem: string;
  _aktpenztarnev,_qs,_aktnev,_vFormula,_eFormula,_forgexcelPath,_evs,_farok: string;
  _gFormula,_fformula,_dformula,_mess: string;

  _sorveg: string = chr(13)+chr(10);

  _looper,_adatoklezarva,_vanexcel: boolean;


// =============================================================================
              function forgalomexcelrutin: integer; stdcall;
// =============================================================================

implementation

{$R *.dfm}

// =============================================================================
             function forgalomexcelrutin: integer; stdcall;
// =============================================================================

begin
  Form2  := TForm2.Create(Nil);
  result := Form2.ShowModal;
  Form2.free;
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

  Label1.repaint;
  Label2.repaint;

  // Beolvassa a kivánt éve és hónapot:

  bookDbase.close;
  bookDbase.DatabaseName := _bookPath;
  bookDbase.Connected := True;

  with bookQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM EVHONAP');
      Open;
      _aktev := FieldByNAme('EV').asInteger;
      _aktho := FieldByNAme('HONAP').asInteger;
      Close;
    end;
  bookDbase.close;

  _evs := inttostr(_aktev);
  _farok := midstr(_evs,3,3)+nulele(_aktho);
  _forgexcelPath := 'c:\booking\excel\FORG' +_farok + '.xls';

  Csik2.max := 5;
  CSik2.Position := 0;

  processPanel.Caption := 'Adatok elõkészítése';
  processPanel.Repaint;

  _vanexcel := False;

  Makeforgexcel;  // A forgalmakat exceltáblába tölti

  if fileExists(_forgexcelPath) then SysUtils.DeleteFile(_forgexcelPath);

  _owb.SaveAs(_forgexcelPath);

  Csik2.Position := 5;
  Sleep(1500);

  Kilepo.Enabled := True;
end;

// =============================================================================
                         procedure TForm2.MakeForgExcel;
// =============================================================================

begin
  Prog2Panel.Caption := 'Pénztárak beolvasása ..';
  Prog2Panel.repaint;

  PenztarBeolvasas;
  Csik2.Position := 1;

  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add(1);
  _oxl.workbookS[1].sheets.add(,,4);

  _vanexcel := True;

  FejlecekKeszitese;

  _kftindex := 1;
  while _kftindex<=4 do
    begin
      CSik2.Position := 1 + _kftIndex;
      EgyKftExcelKeszitese;
      inc(_kftindex);
    end;
end;


// =============================================================================
                    procedure TForm2.FejlecekKeszitese;
// =============================================================================

begin
  processPanel.Caption := 'Fejlécek elkészítése';
  processPanel.repaint;

  Csik.max  := 4;
  _kftindex := 1;
  while _kftindex<=4 do
    begin
      _aktkftnev := _kftnevek[_kftindex];
      Csik.Position := _kftindex;

      prog2panel.Caption := _aktkftnev;
      prog2Panel.Repaint;

      _oxl.workbooks[1].worksheets[_kftindex].name := _aktkftnev;

      Kftfejlec;
      inc(_kftindex);
    end;
end;

// =============================================================================
                procedure TForm2.KftFejlec;
// =============================================================================

begin
  if _korzetIndex<4 then _Focim := 'EXCLUSIVE '+uppercase(_aktkftnev)+' KFT '
  else _focim := 'EXPRESSZ ÉKSZERHÁZ ';
  _focim := _focim + inttostr(_aktev)+' '+_honev[_aktho]+' HAVI FORGALMA';


  // AZ OSZLOP SZÉLESSÉGÉT ÁLLITJA MEG:

  _oxl.worksheets[_kftindex].range['A1:A1'].columnWidth  := 14;
  _oxl.worksheets[_kftindex].range['B1:B1'].columnWidth  := 17;
  _oxl.worksheets[_kftindex].range['C1:C1'].columnWidth  := 18;
  _oxl.worksheets[_kftindex].range['D1:D1'].columnWidth  := 18;
  _oxl.worksheets[_kftindex].range['E1:E1'].columnWidth  := 18;
  _oxl.worksheets[_kftindex].range['F1:F1'].columnWidth  := 18;
  _oxl.worksheets[_kftindex].range['G1:G1'].columnWidth  := 18;
  _oxl.worksheets[_kftindex].range['H1:H1'].columnWidth  := 18;
  _oxl.worksheets[_kftindex].range['I1:I1'].columnWidth  := 18;

  // KFT FÕCIM KIIRÁSA

  _rangestr := 'B2:I2';
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
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[4,2] := 'VALUTA NEME';

  // Fejléc : VALUTA VÉTEL

  _rangestr := 'C4:D4';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[4,3] := 'VALUTA VÉTEL';

  // Fejléc : VALUTA ELADÁS

  _rangestr := 'E4:G4';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[4,5] := 'VALUTA ELADÁS';

  // Fejléc : VALUTA ÁTADÁS

  _rangestr := 'H4:H5';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Verticalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[4,8] := 'VALUTA ÁTADÁS';

  // Fejléc : VALUTA ÁTVÉTEL

  _rangestr := 'I4:I5';
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Verticalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[4,9] := 'VALUTA ÁTVÉTEL';

  // Fejléc : VALUTA VÉTEL ÖSSZEGE

  _rangestr := 'C5:C5';
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[5,3] := 'ÖSSZEGE';

  // Fejléc : VALUTA VÉTEL FT ÉRTÉKE

  _rangestr := 'D5:D5';
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[5,4] := 'FT ÉRTÉKE';

  // Fejléc : VALUTA ELADÁS ÖSSZEGE

  _rangestr := 'E5:E5';
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[5,5] := 'ÖSSZEGE';

  // Fejléc : VALUTA ELADÁS KÉSZPÉNZZEL

  _rangestr := 'F5:F5';
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[5,6] := 'KÉSZPÉNZES';

  // Fejléc : VALUTA ELADÁS BANKKÁRTYÁVAL

  _rangestr := 'F5:F5';
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Italic := True;
  _oxl.worksheets[_kftindex].Cells[5,7] := 'BANKKÁRTYÁS';

  // Fejléc keretezése:

  VekonyKeret('C5:C5',_kftindex);
  VekonyKeret('D5:D5',_kftindex);
  VekonyKeret('E5:E5',_kftindex);
  VekonyKeret('F5:F5',_kftindex);
  VekonyKeret('G5:G5',_kftindex);

  VastagKeret('B4:B5',_kftindex);
  VastagKeret('E4:G5',_kftindex);
  VastagKeret('H4:H5',_kftindex);
  VastagKeret('B4:I5',_kftindex);

  // A fejléc alatti sor befagyasztása

  _oxl.workbooks[1].worksheets[_kftindex].select;

  _rangestr := 'A6:A6';
  _range    := _oxl.range[_rangestr];

  _range.select;
  _oxl.ActiveWindow.FreezePanes := True;
end;

// =============================================================================
                   procedure TForm2.EgyKftExcelKeszitese;
// =============================================================================

begin
  _aktkft        := _kftBetuk[_kftindex];
  _aktkftnev     := _kftNevek[_kftindex];
  _exs           := 6;
  _utkorzet      := 0;
  _utpenztar     := 0;
  _adatoklezarva := True;

  ProcessPanel.Caption := _aktkftnev+ ' forgalma';
  ProcessPanel.Repaint;

  SumNullazas;

  _pcs := 'SELECT * FROM TRANZAKCIOK' + _sorveg;
  _pcs := _pcs + 'WHERE KFT='+chr(39)+_aktkft+chr(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY KORZET,PENZTAR,VALUTANEM';

  Bookdbase.Connected := true;
  with Bookquery do
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
  while not Bookquery.Eof do
    begin
      inc(_pp);
      Csik.Position := _pp;

      with BookQuery do
        begin
          _aktKorzet    := FieldByName('KORZET').asInteger;
          _aktPenztar   := FieldByNAme('PENZTAR').asInteger;
          _aktDnem      := FieldByName('VALUTANEM').asString;
          _vettBjegy    := FieldByName('VETTBANKJEGY').asFloat;
          _vettErtek    := FieldByName('VETTERTEK').asFloat;
          _eladottBjegy := FieldByNAme('ELADOTTBANKJEGY').asFloat;
          _eladottKp    := FieldByName('ELADOTTKESZPENZ').asFloat;
          _eladottBk    := FieldByName('ELADOTTKARTYAS').asFloat;
          _atAdas       := FieldByName('ATADAS').asFloat;
          _atVetel      := FieldByNAme('ATVETEL').asFloat;
        end;

      KftSummazas;

      if _aktpenztar<>_utpenztar then
        begin
          if not _adatokLezarva then AdatLezaras;
          if _utkorzet<>_aktkorzet then UjkorzetNyitas;
          UjpenztarNyitas;
        end;

      _utpenztar := _aktPenztar;
      _utKorzet  := _aktkorzet;

      _oxl.worksheets[_kftindex].Cells[_exs,2] := _aktdnem;
      _oxl.worksheets[_kftindex].Cells[_exs,3] := _vettbjegy;
      _oxl.worksheets[_kftindex].Cells[_exs,4] := _vettertek;
      _oxl.worksheets[_kftindex].Cells[_exs,5] := _eladottbjegy;
      _oxl.worksheets[_kftindex].Cells[_exs,6] := _eladottkp;
      _oxl.worksheets[_kftindex].Cells[_exs,7] := _eladottbk;
      _oxl.worksheets[_kftindex].Cells[_exs,8] := _atadas;
      _oxl.worksheets[_kftindex].Cells[_exs,9] := _atvetel;
      _adatokLezarva := False;

      inc(_exs);
      BookQuery.next;
    end;
  Bookquery.close;
  Bookdbase.close;
  AdatLezaras;

  KftOsszesitese;
end;
// =============================================================================
                         procedure Tform2.UjKorzetNyitas;
// =============================================================================

begin
  _aktkorzetnev := GetKorzetNev(_aktkorzet);

  prog2Panel.caption := _aktkorzetnev;
  prog2Panel.Repaint;

  _qs := inttostr(_exs);
  _rangestr := 'B'+_qs+':I'+_qs;
  _oxl.worksheets[_kftindex].range[_rangestr].MergeCells     := True;
  _oxl.worksheets[_kftindex].range[_rangestr].interior.color := $E8DDB6;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Name      := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].font.Size      := 14;
  _oxl.worksheets[_kftindex].range[_rangestr].font.Bold      := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Italic    := True;
  _oxl.worksheets[_kftindex].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_kftindex].Cells[_exs,2] := uppercase(_aktkorzetnev);
  inc(_exs);
end;

// =============================================================================
                  procedure TForm2.Ujpenztarnyitas;
// =============================================================================

begin
  _qs := inttostr(_exs);
  _rangestr := 'B'+_qs+':D'+_qs;

   _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
   _oxl.worksheets[_kftindex].range[_rangestr].HorizontalAlignment := -4108;

   _oxl.worksheets[_kftindex].range[_rangestr].Font.name      := 'Arial';
   _oxl.worksheets[_kftindex].range[_rangestr].Font.size      := 12;
   _oxl.worksheets[_kftindex].range[_rangestr].Font.Bold      := True;
   _oxl.worksheets[_kftindex].range[_rangestr].Font.Italic    := true;
   _oxl.worksheets[_kftindex].range[_rangestr].Interior.color := clYellow;

   ScanPenztar(_aktpenztar);
   _mess := inttostr(_aktpenztar)+'. '+_aktpenztarnev;
   _oxl.worksheets[_kftindex].Cells[_exs,2] := _mess;

   prog3Panel.Caption := _mess;
   prog3Panel.Repaint;

  inc(_exs);
  _startsor := _exs;
end;

// =============================================================================
                   procedure TForm2.AdatLezaras;
// =============================================================================

begin
  _endsor := _exs-1;
  PenztarExceltombRendezes;

  _rangestr := 'D' + inttostr(_startsor)+':D'+inttostr(_endsor);
  _dformula := '=SUM(' + _rangestr + ')';

  _rangestr := 'F' + inttostr(_startsor)+':F'+inttostr(_endsor);
  _fformula := '=SUM(' + _rangestr + ')';

  _rangestr := 'G' + inttostr(_startsor)+':G'+inttostr(_endsor);
  _gformula := '=SUM(' + _rangestr + ')';

  _oxl.worksheets[_kftindex].Cells[_exs,4].Formula := _dFormula;
  _oxl.worksheets[_kftindex].Cells[_exs,6].Formula := _fFormula;
  _oxl.worksheets[_kftindex].Cells[_exs,7].Formula := _gFormula;


  _qs := inttostr(_exs);
  _rangestr :='B'+_qs+':C'+_qs;
  _oxl.worksheets[_kftindex].range[_rangestr].Mergecells := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.color := clTeal;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Italic := True;
   _oxl.worksheets[_kftindex].range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_kftindex].Cells[_exs,2] := 'ÖSSZESEN:';

  _rangestr := 'E'+_qs+':E'+_qs;
  _oxl.worksheets[_kftindex].range[_rangestr].Interior.color := clSilver;

  _rangestr := 'H'+_qs+':I'+_qs;
  _oxl.worksheets[_kftindex].range[_rangestr].Interior.color := clSilver;

  _rangestr := 'D'+_qs+':G'+_qs;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.color := clTeal;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size := 12;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Italic := True;
  _oxl.worksheets[_kftindex].range[_rangestr].NumberFormat := '### ### ###';
  _oxl.worksheets[_kftindex].range[_rangestr].HorizontalAlignment := -4108;
  _exs := _exs + 2;
  _adatokLezarva := True;
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
                procedure TForm2.PenztarBeolvasas;
// =============================================================================

var _pp: byte;
    _Path: string;

begin
  ProCessPanel.Caption := 'IRODÁK BEOLVASÁSA ...';
  ProCessPanel.repaint;

  _path := _host + ':C:\RECEPTOR\DATABASE\RECEPTOR.FDB';
  _pp := 0;

  with RemoteDbase do
    begin
      close;
      databasename := _Path;
      Connected := True;
    end;

  _pcs := 'SELECT * FROM IRODAK ORDER BY CEGBETU,ERTEKTAR,UZLET';
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  Csik.Max := _recno;
  while not RemoteQuery.eof do
    begin
      with remoteQuery do
        begin
          _aktPenztar    := Fieldbyname('UZLET').asInteger;
          _aktkft        := FieldByName('CEGBETU').asString;
          _aktKorzet     := FieldByNAme('ERTEKTAR').asInteger;
          _aktPenztarNev := trim(FieldByName('KESZLETNEV').asstring);
        end;

      Prog2Panel.Caption := _aktPenztarNev;
      Prog2Panel.repaint;

      inc(_pp);
      Csik.Position := _pp;

      _penztar[_pp] := _aktpenztar;
      _korzet[_pp]  := _aktkorzet;
      _kft[_pp]     := _aktkft;
      _penztarnev[_pp] := _aktPenztarnev;

      RemoteQuery.next;
    end;
  RemoteQuery.close;
  RemoteDbase.close;

  // -----------------------------------------

  _path := _host + ':C:\CARTCASH\DATABASE\ARTCASH.FDB';

  with remoteDbase do
    begin
      close;
      databasename := _Path;
      Connected := True;
    end;

  _pcs := 'SELECT * FROM IRODAK ORDER BY UZLET';
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not RemoteQuery.eof do
    begin
      with RemoteQuery do
        begin
          _aktPenztar    := Fieldbyname('UZLET').asInteger;
          _aktPenztarnev := trim(FieldByName('KESZLETNEV').asstring);
        end;

      Prog2Panel.Caption := _aktPenztarNev;
      Prog2Panel.repaint;

      inc(_pp);
      Csik.Position := _pp;

      _penztar[_pp]    := _aktPenztar;
      _korzet[_pp]     := 180;
      _kft[_pp]        := 'Z';
      _penztarnev[_pp] := _aktPenztarnev;

      RemoteQuery.next;
    end;
  RemoteQuery.close;
  RemoteDbase.close;

  _penztarDarab := _pp;

  ProcessPanel.Caption := '';
  Prog2Panel.Caption    := '';

  ProcessPanel.repaint;
  Prog2Panel.Repaint;
end;


// =============================================================================
              procedure TForm2.PenztarExcelTombRendezes;
// =============================================================================

begin
  _rangestr := 'B'+inttostr(_startsor)+':I'+inttostr(_endsor);

  _oxl.worksheets[_kftindex].range[_rangestr].Font.Name   := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Font.size   := 11;
  _oxl.worksheets[_kftindex].range[_rangestr].Font.Italic := True;

  _oxl.worksheets[_kftindex].range[_rangestr].HorizontalAlignment := -4108;

  // A 6 adatcella elõkészítése

  _rangestr := 'C'+inttostr(_startsor)+':I'+inttostr(_endsor);
  _oxl.worksheets[_kftindex].range[_rangestr].NumberFormat := '### ### ###';
end;

// =============================================================================
                      procedure TForm2.KftSummazas;
// =============================================================================

begin
  _xx := scanValuta(_aktdnem);

  _sumad[_xx]  := _sumad[_xx] + _atadas;
  _sumkap[_xx] := _sumkap[_xx] + _atvetel;

  _sumvbj[_xx] := _sumvbj[_xx] + _vettbjegy;
  _sumvFt[_xx] := _sumvFt[_xx] + _vettErtek;

  _sumebj[_xx] := _sumebj[_xx] + _eladottbjegy;
  _sumeKp[_xx] := _sumEKp[_xx] + _eladottKp;
  _sumeBk[_xx] := _sumEBk[_xx] + _eladottBk;
end;

// =============================================================================
                      procedure TForm2.SumNullazas;
// =============================================================================

begin
  _y := 1;
  while _y<=27 do
    begin
      _sumad[_y] := 0;
      _sumkap[_y]:= 0;
      _sumvbj[_y] := 0;
      _sumvft[_y] := 0;
      _sumebj[_y] := 0;
      _sumekp[_y] := 0;
      _sumebk[_y] := 0;
      inc(_y);
    end;
end;

// =============================================================================
                  procedure TForm2.KftOsszesitese;
// =============================================================================

var _ctrlsum: real;

begin

  inc(_exs);
  _focim := _kftnevek[_kftindex]+' Kft Összesítése:';

  _rangestr := 'B'+inttostr(_exs)+':I'+inttostr(_exs);
  _oxl.worksheets[_kftIndex].range[_rangestr].Mergecells     := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftIndex].range[_rangestr].Font.size      := 14;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Italic    := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Bold      := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Color     := clRed;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Name      := 'Arial';
  _oxl.worksheets[_kftIndex].range[_rangestr].Interior.color := $B0FFFF;
  _oxl.worksheets[_kftIndex].cells[_exs,2]                   := _focim;

  _startsor := _exs+1;
  _endsor   := _exs+27;

  _rangestr := 'B' + inttostr(_startsor)+':B'+inttostr(_endsor);
  _oxl.worksheets[_kftIndex].range[_rangestr].Font.size      := 12;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Italic    := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Name      := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;

  _rangestr := 'B' + inttostr(_startsor)+':I'+inttostr(_endsor);
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Name := 'Arial';
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftindex].range[_rangestr].NumberFormat := '### ### ###';

  _y := 1;
  inc(_exs);
  _startsor := _exs;

  while _y<=27 do
    begin
      _atadas       := _sumad[_y];
      _atvetel      := _sumkap[_y];
      _vettbjegy    := _sumvbj[_y];
      _vettertek    := _sumvft[_y];
      _eladottbjegy := _sumebj[_y];
      _eladottKp    := _sumeKp[_y];
      _eladottBk    := _sumeBk[_y];

      _ctrlSum := _atadas+_atvetel+_vettbjegy+_eladottbjegy;
      if _ctrlSum>0 then
        begin
          _oxl.worksheets[_kftindex].Cells[_exs,2] := _dnem[_y];
          _oxl.worksheets[_kftindex].Cells[_exs,3] := floattostr(_sumvbj[_y]);
          _oxl.worksheets[_kftindex].Cells[_exs,4] := floattostr(_sumvFt[_y]);
          _oxl.worksheets[_kftindex].Cells[_exs,5] := floattostr(_sumebj[_y]);
          _oxl.worksheets[_kftindex].Cells[_exs,6] := floattostr(_sumekp[_y]);
          _oxl.worksheets[_kftindex].Cells[_exs,7] := floattostr(_sumebk[_y]);
          _oxl.worksheets[_kftindex].Cells[_exs,8] := floattostr(_sumad[_y]);
          _oxl.worksheets[_kftindex].Cells[_exs,9] := floattostr(_sumkap[_y]);
          inc(_exs);
        end;
      inc(_y);
    end;

  _endsor := _exs-1;

  _rangestr := 'D' + inttostr(_startsor)+':D'+inttostr(_endsor);
  _vformula := '=SUM(' + _rangestr + ')';

  _rangestr := 'F' + inttostr(_startsor)+':F'+inttostr(_endsor);
  _eformula := '=SUM(' + _rangestr + ')';

  _rangestr := 'G' + inttostr(_startsor)+':G'+inttostr(_endsor);
  _gformula := '=SUM(' + _rangestr + ')';

  _rangeStr := 'D'+inttostr(_exs)+':D'+inttostr(_exs);
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftIndex].range[_rangestr].Font.size      := 12;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Italic    := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Bold      := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Color     := clRed;

  _oxl.worksheets[_kftindex].range[_rangestr].Formula := _vFormula;

  _rangeStr := 'F'+inttostr(_exs)+':F'+inttostr(_exs);
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftIndex].range[_rangestr].Font.size      := 12;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Italic    := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Bold      := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Color     := clRed;

  _oxl.worksheets[_kftindex].range[_rangestr].Formula := _eFormula;

  _rangeStr := 'G'+inttostr(_exs)+':G'+inttostr(_exs);
  _oxl.worksheets[_kftindex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftIndex].range[_rangestr].Font.size      := 12;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Italic    := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Bold      := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Color     := clRed;

  _oxl.worksheets[_kftindex].range[_rangestr].Formula := _gFormula;

  _rangestr := 'B'+inttostr(_exs)+':C'+inttostr(_exs);
  _oxl.worksheets[_kftIndex].range[_rangestr].Mergecells     := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].Horizontalalignment := -4108;
  _oxl.worksheets[_kftIndex].range[_rangestr].Font.size      := 12;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Italic    := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Bold      := True;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Color     := clRed;
  _oxl.worksheets[_kftIndex].range[_rangestr].font.Name      := 'Arial';
  _oxl.worksheets[_kftIndex].range[_rangestr].Interior.color := $B0FFFF;
  _oxl.worksheets[_kftIndex].cells[_exs,2] := 'Ö S S Z E S E N :';

  _rangestr := 'E'+inttostr(_exs)+':E'+inttostr(_exs);
  _oxl.worksheets[_kftIndex].range[_rangestr].interior.color := clSilver;
  _rangestr := 'H'+inttostr(_exs)+':I'+inttostr(_exs);
  _oxl.worksheets[_kftIndex].range[_rangestr].interior.color := clSilver;
end;

// =============================================================================
                function TForm2.ScanPenztar(_ptn: byte): byte;
// =============================================================================

var _k: byte;

begin
  result := 0;
  _aktkorzet := 0;
  _aktkft := '';

  _k := 1;
  while _k<=_penztardarab do
    begin
      if _ptn= _penztar[_k] then
        begin
          _aktkft := _kft[_k];
          _aktkorzet := _korzet[_k];
          _aktPenztarnev := _penztarnev[_k];
          result := _k;
          exit;
        end;
      inc(_k);
    end;
end;

// =============================================================================
            function TForm2.GetKorzetNev(_k: byte): string;
// =============================================================================

begin
  _korzetindex := ScanKorzet(_k);
  result := _korzetnevek[_korzetindex]+'I KÖRZET';
end;

// =============================================================================
              function TForm2.ScanKorzet(_kz: byte): byte;
// =============================================================================

var _k: byte;

begin
  result := 0;
  _k := 1;
  while _K<=9 do
    begin
      if _Korzetszam[_k]=_kz then
        begin
          result := _k;
          exit;
        end;
      inc(_k);
    end;
end;

// =============================================================================
            procedure TForm2.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;

  if _vanexcel then
    begin
      _owb := unassigned;
      _oxl.quit;
      _oxl := unassigned;
    end;

  KillExcel;
  Modalresult := 1;
end;

// =============================================================================
                function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10then result := '0' + result;
end;

// =============================================================================
              function TForm2.ScanValuta(_vn: string): byte;
// =============================================================================

var _k: byte;

begin
  result := 0;
  _k := 1;
  while _k<=27 do
    begin
      if _dnem[_k]=_vn then
        begin
          result := _k;
          exit;
        end;
      inc(_k);
    end;
end;
end.
