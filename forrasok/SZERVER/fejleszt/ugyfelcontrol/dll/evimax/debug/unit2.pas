unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Buttons, ExtCtrls, strutils, IBDatabase, DB,
  IBCustomDataSet, IBQuery, Comobj, Excel97, Activex;

type
  TForm2 = class(TForm)
    Munkapanel : TPanel;
    Label1     : TLabel;
    Label2     : TLabel;
    Label3     : TLabel;
    EVEDIT     : TEdit;
    ForintEdit : TEdit;
    Label4     : TLabel;
    STARTGOMB  : TBitBtn;
    VISSZAGOMB : TBitBtn;
    GYUJTOPanel: TPanel;
    CSIK       : TProgressBar;
    Label5     : TLabel;
    NEVPanel   : TPanel;
    BQUERY     : TIBQuery;
    BDBASE     : TIBDatabase;
    BTRANZ     : TIBTransaction;
    LQUERY     : TIBQuery;
    LDBASE     : TIBDatabase;
    LTRANZ     : TIBTransaction;
    ZAROPanel  : TPanel;
    ZAROGomb   : TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure EvEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure ForintEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure EvEditEnter(Sender: TObject);
    procedure EvEditExit(Sender: TObject);
    procedure StartGombClick(Sender: TObject);
    procedure ZapDbase;
    procedure Vastag(_rs: string;_sh: byte);
    procedure Vekony(_rs: string;_sh: byte);
    procedure VisszaGombClick(Sender: TObject);
    procedure ZaroGombClick(Sender: TObject);
    procedure NaturDataBeiras;
    procedure JogiDataBeiras;

    function Bovito(_szd: string): string;
    function MakeExcel: boolean;
    function Forintform(_ft: integer): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _asc: byte;
  _width,_height,_kertev,_ndatadb,_jdatadb,_prisor,_top,_left: word;
  _code,_forint,_recno,_sorszam,_evesforint: integer;

  _Kertevs,_evtizes,_ugytab,_aktfdb,_tabla,_pcs,_nev,_anyjaneve,_rangestr: string;
  _szulhely,_szulido,_allampolg,_lakcim,_nlastnums,_joginev,_telephely: string;
  _okirat,_fotev,_mbneve,_kepvisnev,_jLastnums: string;

  _sorveg: string = chr(13)+chr(10);

  _oxl,_owb,_range: OleVariant;


function evimaxtranzakciok: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
            function evimaxtranzakciok: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  form2.free;
end;

// =============================================================================
              procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width  := Screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;
  _top    :=round((_height-595)/2);
  _left := 8+round((_width-1017)/2);

  Top := _top-50;
  Left := _left;
  Height := 537;
  Width := 1001;

  with Munkapanel do
    begin
      top := 120;
      left := 200;
      visible := true;
    end;

  ForintEdit.clear;
  Evedit.clear;
  ActiveControl := evedit;
end;


// =============================================================================
        procedure TForm2.EVEDITKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _kertevs := trim(evedit.Text);
  val(_kertevs,_kertev,_code);
  if _code<>0 then _kertev := 0;
  if _kertev<2020 then
    begin
      ShowMessage('ÉRVÉNYTELEN ÉV');
      exit;
    end;
  Activecontrol := Forintedit;
end;


// =============================================================================
procedure TForm2.FORINTEDITKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
// =============================================================================

var _fts: string;

begin
  if ord(key)<>13 then exit;
  _fts := trim(Forintedit.Text);
  Val(_fts,_forint,_code);
  if _code<>0 then _forint := 0;
  if _forint=0 then exit;

  _fts := Forintform(_forint);
  ForintEdit.text := _fts;

  StartGomb.Enabled := true;
  Activecontrol := Startgomb;

end;

// =============================================================================
             function TForm2.Forintform(_ft: integer): string;
// =============================================================================

var _ftlen,_f1: byte;

begin
  result := inttostr(_ft);
  _ftlen := length(result);
  if _ftlen<4 then exit;
  if _ftlen>9 then  // 1 000 000 000
    begin
      result := leftstr(result,1)+' '+midstr(result,2,3)+' '+midstr(result,5,3)+' '+midstr(result,8,3);
      exit;
    end;

  if _ftlen>6 then
    begin
      _f1 := _ftlen-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;
  _f1 := _ftlen-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;

// =============================================================================
                procedure TForm2.EVEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clyellow;
end;

// =============================================================================
              procedure TForm2.EVEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(Sender).Color := clWindow;
end;

// =============================================================================
          procedure TForm2.STARTGOMBClick(Sender: TObject);
// =============================================================================

begin
  with Gyujtopanel do
    begin
      top := 272;
      left := 200;
      Visible := True;
      repaint;
    end;

  if _kertev=0 then
    begin
      Activecontrol := evedit;
      exit;
    end;

  _evtizes := midstr(inttostr(_kertev),3,2);
  _ugytab := 'UGYFEL'+_EVTIZES + '.FDB';
  _aktfdb := '185.43.207.99:C:\RECEPTOR\DATABASE\' + _ugytab;

  Zapdbase;

  bdbase.close;
  bdbase.DatabaseName := _aktfdb;
  bdbase.Connected := True;

  Ldbase.connected := true;
  if Ltranz.InTransaction then LTranz.Commit;
  Ltranz.StartTransaction;

  _asc := 65;
  while _asc<=90 do
    begin
      Csik.Position := _asc-64;

      _tabla := chr(_asc)+'NEV';
      _pcs := 'SELECT * FROM ' + _tabla + _sorveg;
      _pcs := _pcs + 'WHERE FORINTOSSZEG>='+inttostr(_forint);
      with bquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := Recno;
        end;

      if _recno=0 then
        begin
          bquery.close;
          inc(_asc);
          Continue;
        end;
      while not bquery.Eof do
        begin
          with bquery do
            begin
              _nev := trim(FieldByNAme('NEV').AsString);
              _sorszam := FieldByNAme('SORSZAM').asInteger;
              _anyjaneve := trim(FieldByNAme('ANYJANEVE').AsString);
              _szulhely := trim(FieldByNAme('SZULETESIHELY').AsString);
              _szulido := trim(FieldByName('SZULETESIIDO').asString);
              _allampolg := trim(FieldByNAme('ALLAMPOLGAR').AsString);
              _lakcim := trim(FieldByNAme('LAKCIM').AsString);
              _evesforint := FieldByNAme('FORINTOSSZEG').asInteger;
            end;

          _szulido := Bovito(_szulido);

          Nevpanel.Caption := _nev;
          Nevpanel.Repaint;

          _pcs := 'INSERT INTO UGYFELEK (NEV,SORSZAM,ANYJANEVE,SZULETESIHELY,';
          _pcs := _pcs + 'SZULETESIIDO,ALLAMPOLGAR,LAKCIM,EVESFORINT)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39) + _nev + chr(39) + ',';
          _pcs := _pcs + inttostr(_sorszam) + ',';
          _pcs := _pcs + chr(39) + _anyjaneve + chr(39) + ',';
          _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
          _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
          _pcs := _pcs + chr(39) + _allampolg + chr(39) + ',';
          _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
          _pcs := _pcs + inttostr(_evesforint) + ')';

          with Lquery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Execsql;
            end;
          Bquery.next;
        end;
      Bquery.close;
      inc(_asc);
    end;

  // ------------------------ jogi személyek ---------------------------

  _pcs := 'SELECT * FROM JOGI' + _sorveg;
  _pcs := _pcs + 'WHERE FORINTOSSZEG>='+inttostr(_forint);

  with bquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := Recno;
      First;
    end;

  if _recno>0 then
    begin
      while not bquery.Eof do
        begin
          _joginev := trim(Bquery.fieldByName('JOGISZEMELYNEV').asString);
          _telephely := trim(BQuery.FieldByNAme('TELEPHELYCIM').asString);
          _okirat := trim(Bquery.FieldByNAme('OKIRATSZAM').AsString);
          _fotev := trim(Bquery.fieldByNAme('FOTEVEKENYSEG').AsString);
          _mbneve := trim(Bquery.FieldByname('MEGBIZOTTNEVE').asString);
          _kepvisnev := trim(Bquery.FieldByNAme('KEPVISELONEV').asString);
          _sorszam := Bquery.FieldByNAme('SORSZAM').asInteger;
          _evesforint := BQuery.FieldByNAme('FORINTOSSZEG').asInteger;

          Nevpanel.caption := _joginev;
          NevPanel.repaint;

          _pcs := 'INSERT INTO JOGISZEMELY (JOGISZEMELYNEV,TELEPHELYCIM,';
          _pcs := _pcs + 'OKIRATSZAM,FOTEVEKENYSEG,MEGBIZOTTNEVE,KEPVISELONEV,';
          _pcs := _pcs + 'EVESFORINT,SORSZAM)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + CHR(39) + _joginev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _telephely + chr(39) + ',';
          _pcs := _pcs + chr(39) + _okirat + chr(39) + ',';
          _pcs := _pcs + chr(39) + _fotev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _mbneve + chr(39) + ',';
          _pcs := _pcs + chr(39) + _kepvisnev + chr(39) + ',';
          _pcs := _pcs + inttostr(_evesforint) + ',';
          _pcs := _pcs + inttostr(_sorszam)+ ')';

          with Lquery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Execsql;
            end;
          Bquery.next;
        end;
    end;
  Bquery.close;
  Bdbase.close;

  Ltranz.commit;
  Ldbase.close;

  if not MakeExcel then
    begin
      ShowMessage('NINCSENEK ADATOK');
      Modalresult := -1;
      exit;
    end;

end;

// =============================================================================
                function TForm2.Bovito(_szd: string): string;
// =============================================================================

begin
  result := trim(_szd);
  if length(_szd)<>8 then exit;
  result := leftstr(result,4)+'.'+midstr(result,5,2)+'.'+midstr(result,7,2);
end;


// =============================================================================
                         procedure TForm2.Zapdbase;
// =============================================================================

begin
  Ldbase.connected := true;
  if Ltranz.InTransaction then LTranz.Commit;
  Ltranz.StartTransaction;

  _pcs := 'DELETE FROM UGYFELEK';
  with LQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;

  _pcs := 'DELETE FROM JOGISZEMELY';
  with LQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;

  LTranz.commit;
  ldbase.close;
end;

// =============================================================================
                function tForm2.MakeExcel: boolean;
// =============================================================================

begin
  result := False;

  Ldbase.Connected := True;
  _pcs := 'SELECT * FROM UGYFELEK ORDER BY EVESFORINT DESC';
  with Lquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      last;
      _NDataDb := recno;
      First;
    end;

  _pcs := 'SELECT * FROM JOGISZEMELY ORDER BY EVESFORINT DESC';
  with Lquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      last;
      _jDataDb := recno;
      First;
    end;

   if (_JdataDb=0) AND (_NDataDb=0) then
     begin
       LQuery.close;
       Ldbase.close;
       exit;
     end;

  _oxl := CreateOleobject('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.add(1);
  _oxl.workbooks[1].sheets.add(,,2);

  _oxl.workbooks[1].worksheets[1].name := 'TERM.SZEMÉLY';
  _oxl.workbooks[1].worksheets[2].name := 'JOGI SZEMÉLY';

  // ------------- természetes személy oszlopszélesség beállitása --------------

  _oxl.worksheets[1].Range['A1:A1'].Columnwidth := 24;  // üres
  _oxl.worksheets[1].Range['B1:B1'].Columnwidth := 24;  // nev
  _oxl.worksheets[1].Range['C1:C1'].Columnwidth := 10;  // évi váltás
  _oxl.worksheets[1].Range['D1:D1'].Columnwidth := 21;  // anyja neve
  _oxl.worksheets[1].Range['E1:E1'].Columnwidth := 18;  // szülhelye
  _oxl.worksheets[1].Range['F1:F1'].Columnwidth := 9;   // szül ideje
  _oxl.worksheets[1].Range['G1:G1'].Columnwidth := 15;  // állampolgár
  _oxl.worksheets[1].Range['H1:H1'].Columnwidth := 35;  // lakcim
  _oxl.worksheets[1].Range['I1:I1'].Columnwidth := 6;   // sorszám

  // ------------- jogi személy oszlopszélesség beállitása ---------------------

  _oxl.worksheets[2].Range['A1:A1'].Columnwidth := 35;  // üres
  _oxl.worksheets[2].Range['B1:B1'].Columnwidth := 30;  // nev
  _oxl.worksheets[2].Range['C1:C1'].Columnwidth := 12;  // évi váltás
  _oxl.worksheets[2].Range['D1:D1'].Columnwidth := 34;  // telephely
  _oxl.worksheets[2].Range['E1:E1'].Columnwidth := 14;  // okirat szám
  _oxl.worksheets[2].Range['F1:F1'].Columnwidth := 28;  // fö tevékenység
  _oxl.worksheets[2].Range['G1:G1'].Columnwidth := 25;  // megbizott neve
  _oxl.worksheets[2].Range['H1:H1'].Columnwidth := 25;  // képviselö neve
  _oxl.worksheets[2].Range['I1:I1'].Columnwidth := 9;   // sorszáma

  // ----------------  természetes személy fõcim -------------------------------

  _rangestr := 'B3:I3';
  _oxl.worksheets[1].Range[_rangestr].mergecells := True;
  _oxl.worksheets[1].Range[_rangestr].Font.Name := 'Calibri';
  _oxl.worksheets[1].Range[_rangestr].Font.size := 12;
  _oxl.worksheets[1].Range[_rangestr].Font.Bold := True;
  _oxl.worksheets[1].Range[_rangestr].Font.Italic := False;

  // ----------------  jogi személy fõcim --------------------------------------

  _rangestr := 'B3:I3';
  _oxl.worksheets[2].Range[_rangestr].mergecells := True;
  _oxl.worksheets[2].Range[_rangestr].Font.Name := 'Calibri';
  _oxl.worksheets[2].Range[_rangestr].Font.size := 12;
  _oxl.worksheets[2].Range[_rangestr].Font.Bold := True;
  _oxl.worksheets[2].Range[_rangestr].Font.Italic := False;

  // -------------- természetes személy fejléce --------------------------------

  _rangestr := 'B5:I6';
  _oxl.worksheets[1].Range[_rangestr].font.name   := 'Calibri';
  _oxl.worksheets[1].Range[_rangestr].font.size   := 9;
  _oxl.worksheets[1].Range[_rangestr].font.bold   := true;
  _oxl.worksheets[1].Range[_rangestr].font.italic := False;
  _oxl.worksheets[1].Range[_rangestr].WrapText    := True;

  _oxl.worksheets[1].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[1].Range[_rangestr].VerticalAlignment   := -4108;


  // --------------- jogi személy fejléce --------------------------------------

  _rangestr := 'B6:I6';
  _oxl.worksheets[2].Range[_rangestr].font.name   := 'Calibri';
  _oxl.worksheets[2].Range[_rangestr].font.size   := 10;
  _oxl.worksheets[2].Range[_rangestr].font.bold   := true;
  _oxl.worksheets[2].Range[_rangestr].font.italic := False;

  _oxl.worksheets[2].Range[_rangestr].HorizontalAlignment := -4108;

  // --------------- természetes személy adatmezõje  ---------------------------

  _Nlastnums := inttostr(_Ndatadb+6);

  _rangestr := 'B7:I'+_Nlastnums;
  _oxl.worksheets[1].Range[_rangestr].font.name   := 'Calibri';
  _oxl.worksheets[1].Range[_rangestr].font.size   := 8;
  _oxl.worksheets[1].Range[_rangestr].font.bold   := False;
  _oxl.worksheets[1].Range[_rangestr].font.italic := False;

  // ------------ jogi személy adatmezõi ---------------------------------------

  _jlastnums := inttostr(_jdatadb+6);

  _rangestr := 'B7:I'+_jlastnums;
  _oxl.worksheets[2].Range[_rangestr].font.name   := 'Calibri';
  _oxl.worksheets[2].Range[_rangestr].font.size   := 8;
  _oxl.worksheets[2].Range[_rangestr].font.bold   := False;
  _oxl.worksheets[2].Range[_rangestr].font.italic := False;

  // ----------- term. személy adat oszopai ------------------------------------

  _rangestr := 'C7:C'+_nLastnums;
  _oxl.worksheets[1].Range[_rangestr].Numberformat := '### ### ###';

  _rangestr := 'F7:F'+_nLastnums;
  _oxl.worksheets[1].Range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'I7:I'+_nLastnums;
  _oxl.worksheets[1].Range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'G7:G'+_nLastnums;
  _oxl.Range[_rangestr].HorizontalAlignment := -4108;

  // -------------------  jogiszemély adat-oszlopai ----------------------------

  _rangestr := 'C7:C'+_nLastnums;
  _oxl.worksheets[2].Range[_rangestr].Numberformat := '### ### ###';

  _rangestr := 'E7:E' + _jLastNums;
  _oxl.worksheets[2].Range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'I7:I' + _jLastNums;
  _oxl.worksheets[2].Range[_rangestr].HorizontalAlignment := -4108;

  // ----------- term. személy  fejléc cellái ----------------------------------

  _oxl.worksheets[1].Range['B5:B6'].Mergecells := True;
  _oxl.worksheets[1].Range['C5:C6'].Mergecells := True;
  _oxl.worksheets[1].Range['D5:D6'].Mergecells := True;
  _oxl.worksheets[1].Range['E5:E6'].Mergecells := True;
  _oxl.worksheets[1].Range['F5:F6'].Mergecells := True;
  _oxl.worksheets[1].Range['G5:G6'].Mergecells := True;
  _oxl.worksheets[1].Range['H5:H6'].Mergecells := True;
  _oxl.worksheets[1].Range['I5:I6'].Mergecells := True;

  _oxl.worksheets[1].Cells[5,2] := 'AZ ÜGYFÉL NEVE';
  _oxl.worksheets[1].Cells[5,3] := 'ÉVI VÁLTÁS';
  _oxl.worksheets[1].Cells[5,4] := 'ANYJA NEVE';
  _oxl.worksheets[1].Cells[5,5] := 'SZÜLETÉSI HELYE';
  _oxl.worksheets[1].Cells[5,6] := 'SZÜLETÉSI IDEJE';
  _oxl.worksheets[1].Cells[5,7] := 'ÁLLAMPOLGÁR';
  _oxl.worksheets[1].Cells[5,8] := 'LAKCIM';
  _oxl.worksheets[1].Cells[5,9] := 'SOR SZÁMA';

  // ------------- jogi azemély fejléc cellái ----------------------------------

  _oxl.worksheets[2].Cells[6,2] := 'JOGI SZEMÉLY NEVE';
  _oxl.worksheets[2].Cells[6,3] := 'ÉVI VÁLTÁS';
  _oxl.worksheets[2].Cells[6,4] := 'TELEPHELY CÍME';
  _oxl.worksheets[2].Cells[6,5] := 'OKIRAT SZÁMA';
  _oxl.worksheets[2].Cells[6,6] := 'FÕ TEVÉKENYSÉGE';
  _oxl.worksheets[2].Cells[6,7] := 'MEGBIZOTT NEVE';
  _oxl.worksheets[2].Cells[6,8] := 'KÉPVISELÕ NEVE';
  _oxl.worksheets[2].Cells[6,9] := 'SOR SZÁMA';

  // -------------  TERM. SZEMÉLY CELLA FAGYASZTÁS -----------------------------

  _rangestr := 'A7:A7';
  _oxl.worksheets[1].range[_rangestr].select;
  _oxl.activewindow.freezePanes := true;

  // --------------  JOGI SZEMÉLY CELLA FAGYASZTÁS -----------------------------

  _oxl.workbooks[1].worksheets[2].select;
  _range := _oxl.range[_rangestr];
  _range.select;
  _oxl.activewindow.freezePanes := true;

  // --------------- TERMÉSZETES SZEMÉLY ADATAI --------------------------------

  if _nDataDb>0 then NaturDataBeiras;
  if _jDataDb>0 then JogiDataBeiras;

  Ldbase.close;

  with ZaroPanel do
    begin
      top := 280;
      left := 320;
      Visible := true;
    end;

  _oxl.visible := true;
  result := True;
end;

// =============================================================================
                procedure TForm2.Vastag(_rs: string;_sh: byte);
// =============================================================================

begin
  _oxl.worksheets[_sh].range[_rs].BorderAround(1,4);
end;

// =============================================================================
                  procedure TForm2.Vekony(_rs: string;_sh: byte);
// =============================================================================

begin
  _oxl.worksheets[_sh].range[_rs].BorderAround(1,2);
end;

// =============================================================================
               procedure TForm2.ZAROGOMBClick(Sender: TObject);
// =============================================================================

begin
  _oxl.quit;
  _oxl := unassigned;
  Modalresult := 1;
end;

// =============================================================================
           procedure TForm2.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

// =============================================================================
                  procedure TForm2.NaturDataBeiras;
// =============================================================================

begin
  Ldbase.Connected := True;
  _pcs := 'SELECT * FROM UGYFELEK ORDER BY EVESFORINT DESC';
  with Lquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _prisor := 6;
  while not Lquery.Eof do
    begin
      with LQuery do
        begin
          _nev := trim(FieldByNAme('NEV').AsString);
          _sorszam := FieldByNAme('SORSZAM').asInteger;
          _anyjaneve := trim(FieldByNAme('ANYJANEVE').AsString);
          _szulhely := trim(FieldByNAme('SZULETESIHELY').AsString);
          _szulido := trim(FieldByName('SZULETESIIDO').asString);
          _allampolg := trim(FieldByNAme('ALLAMPOLGAR').AsString);
          _lakcim := trim(FieldByNAme('LAKCIM').AsString);
          _evesforint := FieldByNAme('EVESFORINT').asInteger;
        end;

      inc(_prisor);

      _oxl.worksheets[1].cells[_prisor,2] := _nev;
      _oxl.worksheets[1].cells[_prisor,3] := _evesforint;
      _oxl.worksheets[1].cells[_prisor,4] := _anyjaneve;
      _oxl.worksheets[1].cells[_prisor,5] := _szulhely;
      _oxl.worksheets[1].cells[_prisor,6] := _szulido;
      _oxl.worksheets[1].cells[_prisor,7] := _allampolg;
      _oxl.worksheets[1].cells[_prisor,8] := _lakcim;
      _oxl.worksheets[1].cells[_prisor,9] := _sorszam;

      Lquery.next;
    end;
  Lquery.close;

  Vekony('C5:C'+_nlastnums,1);
  Vekony('E5:E'+_nlastnums,1);
  Vekony('G5:G'+_nlastnums,1);
  Vekony('H5:H'+_nlastnums,1);

  Vastag('B5:I6',1);
  Vastag('B5:I'+_nLastnums,1);

  _oxl.worksheets[1].range['B3:I3'].HorizontalAlignment := -4108;
  _oxl.worksheets[1].cells[3,2] := inttostr(_kertev)+' ÉVBEN ' + forintform(_forint) + ' FT FELETTI TERMÉSZETES SZEMÉLYEK VÁLTÁSAI';

  _oxl.worksheets[2].range['B3:I3'].HorizontalAlignment := -4108;
  _oxl.worksheets[2].cells[3,2] := inttostr(_kertev)+' ÉVBEN ' + forintform(_forint) + ' FT FELETTI JOGI SZEMÉLYEK VÁLTÁSAI';


end;

// =============================================================================
                  procedure TForm2.JogiDataBeiras;
// =============================================================================

begin
  _pcs := 'SELECT * FROM JOGISZEMELY ORDER BY EVESFORINT DESC';
  with Lquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _prisor := 6;
  while not Lquery.Eof do
    begin
      _joginev := trim(Lquery.fieldByName('JOGISZEMELYNEV').asString);
      _telephely := trim(LQuery.FieldByNAme('TELEPHELYCIM').asString);
      _okirat := trim(Lquery.FieldByNAme('OKIRATSZAM').AsString);
      _fotev := trim(Lquery.fieldByNAme('FOTEVEKENYSEG').AsString);
      _mbneve := trim(Lquery.FieldByname('MEGBIZOTTNEVE').asString);
      _kepvisnev := trim(Lquery.FieldByNAme('KEPVISELONEV').asString);
      _sorszam := Lquery.FieldByNAme('SORSZAM').asInteger;
      _evesforint := LQuery.FieldByNAme('EVESFORINT').asInteger;

      inc(_prisor);

      _oxl.worksheets[2].cells[_prisor,2] := _joginev;
      _oxl.worksheets[2].cells[_prisor,3] := _evesforint;
      _oxl.worksheets[2].cells[_prisor,4] := _telephely;
      _oxl.worksheets[2].cells[_prisor,5] := _okirat;
      _oxl.worksheets[2].cells[_prisor,6] := _fotev;
      _oxl.worksheets[2].cells[_prisor,7] := _mbneve;
      _oxl.worksheets[2].cells[_prisor,8] := _kepvisnev;
      _oxl.worksheets[2].cells[_prisor,9] := _sorszam;

      Lquery.next;
    end;
  Lquery.close;

  Vekony('C5:C'+_jlastnums,2);
  Vekony('E5:E'+_jlastnums,2);
  Vekony('G5:G'+_jlastnums,2);
  Vekony('H5:H'+_jlastnums,2);

  Vastag('B5:I6',2);
  Vastag('B5:I'+_jlastnums,2);

  _oxl.worksheets[1].range['B3:I3'].HorizontalAlignment := -4108;
  _oxl.worksheets[1].cells[3,2] := inttostr(_kertev)+' ÉVBEN ' + forintform(_forint) + ' FT FELETTI VÁLTÁSOK';
end;



end.
