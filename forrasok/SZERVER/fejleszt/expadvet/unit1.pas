unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  DateUtils, strutils, IBTable, ExtCtrls, ComObj, TlHelp32;

type
  TForm1 = class(TForm)
    STARTGOMB: TBitBtn;
    KILEPGOMB: TBitBtn;
    VQUERY: TIBQuery;
    ADVETQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    ADVETDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    ADVETTRANZ: TIBTransaction;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    VTABLA: TIBTable;
    ADVETTABLA: TIBTable;
    VTETQUERY: TIBQuery;
    VTETDBASE: TIBDatabase;
    VTETTRANZ: TIBTransaction;
    WUNITABLA: TIBTable;
    WUNIQUERY: TIBQuery;
    WUNITRANZ: TIBTransaction;
    WUNIDBASE: TIBDatabase;
    Label1: TLabel;
    Label2: TLabel;
    Shape1: TShape;
    Label3: TLabel;
    Memo: TMemo;
    Shape2: TShape;
    Shape3: TShape;
    KILEPO: TTimer;
    ARTQUERY: TIBQuery;
    ARTDBASE: TIBDatabase;
    ARTTRANZ: TIBTransaction;
    INFOTABLA: TPanel;
    Label4: TLabel;
    EPATHPANEL: TPanel;
    Label5: TLabel;

    procedure AdvetBeolvasas;
    procedure AdatFeltoltes;
    procedure AdvetParancs(_ukaz: string);
    procedure BlokkTetelBeolvasas;
    procedure ExcelKill;
    procedure Fejlec;
    procedure FormActivate(Sender: TObject);
    procedure HoComboChange(Sender: TObject);
    procedure IrodakBeolvasasa;
    procedure KilepGombClick(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure Maketabla(_tnev: string);
    procedure MakeExcel;
    procedure PenztarStart;
    procedure StartGombClick(Sender: TObject);
    procedure Vekonykeret(_rs: string);
    procedure Vastagkeret(_rs: string);
    procedure WuniBeolvasas;

    function Getpenztarnev(_pnum: byte): string;
    function Nulele(_b: byte): string;
  
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _penztarnev: array[1..18] of string;
  _honev: array[1..12] of string = ('JANUAR','FEBRUAR','MARCIUS','APRILIS','MAJUS',
           'JUNIUS','JULIUS','AUGUSZTUS','SZEPTEMBER','OKTOBER','NOVEMBER',
           'DECEMBER');

  _y,_aktpenztar,_lastpenztar,_tetel,_foegyseg,_pt: byte;
  _top,_left,_width,_height,_aktev,_aktho,_kertev,_kertho,_prisor: word;
  _startsor,_endsor: word;
  _farok,_pcs,_tablanev,_wuninev,_bfejnev,_aktvPath,_datum,_tars,_tipus: string;
  _kuldo,_fogado,_ttip,_szallitonev,_plombaszam,_bizonylatszam,_ftjel: string;
  _btetnev,_ttipus,_exdir,_exfile,_expath,_rangestr,_sstr,_estr: string;
  _aktpenztarnev,_pstr,_aktdnem: string;
  _bankjegy: integer;

  _vanexcel,_looper: boolean;

  _proc     : PROCESSENTRY32;
  _handle   : HWND;

  _dnem: array[1..26] of string;
  _osszeg: array[1..26] of integer;

  _sorveg: string = chr(13)+chr(10);
  _host: string = '185.43.207.99';
  _oxl,_owb,_range: olevariant;


implementation

{$R *.dfm}

// =============================================================================
             procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _top := round((_height-523)/2);
  _left := round((_width-390)/2);

  Top := _top;
  Left:= _left;
  Repaint;

  Irodakbeolvasasa;

  _aktev := yearof(date);
  _aktho := monthof(date);

  evcombo.Clear;
  evcombo.Items.Clear;
  evcombo.Items.add(inttostr(_aktev-1));
  evcombo.Items.Add(inttostr(_aktev));
  evcombo.ItemIndex := 1;

  hocombo.Clear;
  hocombo.Items.Clear;
  _y := 1;
  while _y<=12 do
    begin
      hocombo.Items.Add(_honev[_y]);
      inc(_y);
    end;

  if _aktho=1 then
    begin
      evcombo.ItemIndex := 0;
      hocombo.itemindex := 11;
    end else hocombo.ItemIndex := _aktho-1;

  Activecontrol := startgomb;
end;

// =============================================================================
                procedure TForm1.KILEPGOMBClick(Sender: TObject);
// =============================================================================

begin
  Kilepo.enabled := true;
end;

// =============================================================================
                procedure TForm1.STARTGOMBClick(Sender: TObject);
// =============================================================================

begin
  StartGomb.Enabled := False;

  _kertev := _aktev + evcombo.itemindex - 1;
  _kertho := 1 + hocombo.ItemIndex;
  _farok  := midstr(inttostr(_kertev),3,2)+nulele(_kertho);
  _tablanev := 'HAVIADVET' + _farok;
  _wuninev  := 'WUNI' + _farok;
  _bfejnev  := 'BF' + _farok;
  _btetnev  := 'BT' + _farok;

  MakeTabla(_tablanev);

   _aktpenztar := 151;
   while _aktpenztar<=168 do
     begin
       Memo.Lines.add(inttostr(_aktpenztar)+'. pénztár vizsgálata');

       // _aktvPath := _host + ':c:\cartcash\database\v'+inttostr(_aktpenztar)+'.fdb';
       _aktvPath := _host +':c:\cartcash\database\v'+inttostr(_aktpenztar)+'.fdb';

       vdbase.close;
       vdbase.DatabaseName := _aktvpath;
       vdbase.Connected := true;
       vtabla.close;

       vtetdbase.close;
       vtetdbase.DatabaseName := _aktvpath;

       wunidbase.close;
       wunidbase.DatabaseName := _aktvpath;

       vtabla.TableName := _bfejnev;
       if vtabla.Exists then advetbeolvasas;

       vdbase.Connected := True;
       vtabla.TableName := _wuninev;
       if vtabla.Exists then wunibeolvasas;
       inc(_aktpenztar);
     end;
  MakeExcel;
  _oxl.visible := True;
  Infotabla.Visible := True;
end;

// =============================================================================
                          procedure TForm1.AdvetBeolvasas;
// =============================================================================

begin
  Advetdbase.connected := True;
  if advettranz.InTransaction then Advettranz.commit;
  advettranz.StartTransaction;

  _pcs := 'SELECT * FROM ' + _bfejnev + _sorveg;
  _pcs := _pcs + 'WHERE ((TIPUS='+chr(39)+'F'+chr(39)+') ';
  _pcs := _pcs + 'OR (TIPUS='+chr(39)+'U'+chr(39)+') ';
  _pcs := _pcs + 'AND (STORNO=1))'+_sorveg;

  with Vquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not vquery.eof do
    begin
      _datum := vquery.fieldByNAme('DATUM').asString;
      _tars := trim(Vquery.Fieldbyname('PENZTAR').asstring);
      _tipus := vquery.fieldByName('TIPUS').asString;
      if _tipus='F' then
        begin
          _kuldo := inttostr(_aktpenztar);
          _fogado := _tars;
          _ttip  := 'Átadás';
        end else
        begin
          _fogado := inttostr(_aktpenztar);
          _kuldo  := _tars;
          _ttip   := 'Átvétel';
        end;
      _szallitonev := trim(Vquery.FieldByNAme('SZALLITONEV').asString);
      _plombaszam := trim(Vquery.FieldByNAme('PLOMBASZAM').asString);
      _bizonylatszam := vquery.FieldByNAme('BIZONYLATSZAM').asstring;
      _ftjel := midstr(_bizonylatszam,2,1);
      if _ftjel='F' then
        begin
          _dnem[1] := 'HUF';
          _osszeg[1]  := vquery.fieldbyname('OSSZESEN').asInteger;
          _tetel := 1;
        end else BlokktetelBeolvasas;

      _y := 1;
      while _y<=_tetel do
        begin
          _pcs := 'INSERT INTO ' + _tablaNev + '(KULDO,FOGADO,DATUM,BIZONYLATSZAM,';
          _pcs := _pcs + 'TRANZTIPUS,OSSZEG,VALUTANEM,SZALLITONEV,';
          _pcs := _pcs + 'PLOMBASZAM,PENZTAR)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + chr(39) + _kuldo + chr(39) + ',';
          _pcs := _pcs + chr(39) + _fogado + chr(39) + ',';
          _pcs := _pcs + chr(39) + _datum + chr(39) + ',';
          _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
          _pcs := _pcs + chr(39) + _ttip + chr(39) + ',';
          _pcs := _pcs + inttostr(_osszeg[_y]) + ',';
          _pcs := _pcs + chr(39) + _dnem[_y] + chr(39) + ',';
          _pcs := _pcs + chr(39) + _szallitonev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _plombaszam + chr(39) + ',';
          _pcs := _pcs + inttostr(_aktpenztar)+')';

          with AdvetQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Execsql;
            end;
          inc(_y);
        end;
      Vquery.next;
    end;
  Vquery.close;
  vdbase.close;

  AdvetTranz.commit;
  Advetdbase.close;
end;

// =============================================================================
                       procedure TForm1.BlokktetelBeolvasas;
// =============================================================================

begin
  _tetel := 0;

  _pcs := 'SELECT * FROM ' + _btetnev + _sorveg;
  _pcs := _pcs + 'WHERE (BIZONYLATSZAM=' + chr(39)+_bizonylatszam+chr(39)+') ';
  _pcs := _pcs + 'AND (STORNO=1)' + _sorveg;

  VtetDbase.connected := true;
  with VTetQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not VTetQuery.eof do
    begin
      inc(_tetel);
      _dnem[_tetel] := vtetquery.FieldByNAme('VALUTANEM').asString;
      _osszeg[_tetel] := Vtetquery.FieldByNAme('BANKJEGY').asInteger;
      vTetQuery.next;
    end;

  VTetQuery.close;
  VTetDbase.close;
end;


// =============================================================================
                  procedure TForm1.Maketabla(_tnev: string);
// =============================================================================

begin
  AdvetDbase.connected := true;
  AdvetTabla.close;
  AdvetTabla.TableName := _tnev;
  if Advettabla.Exists then
    begin
      Advetdbase.close;
      AdvetParancs('DELETE FROM ' + _tnev);
      exit;
    end;
  Advetdbase.close;

  _pcs := 'CREATE TABLE '+_tnev+' (' + _sorveg;
  _pcs := _pcs + 'KULDO CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'FOGADO CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'TRANZTIPUS CHAR (10) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'OSSZEG INTEGER,'+_sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'SZALLITONEV CHAR (20) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'PLOMBASZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'PENZTAR INTEGER)';

  AdvetParancs(_pcs);
end;

// =============================================================================
                        procedure TForm1.WuniBeolvasas;
// =============================================================================

begin
  wunidbase.connected := True;
  wuniTabla.close;
  wunitabla.TableName := _wuninev;
  if not wunitabla.Exists then
    begin
      wunidbase.close;
      exit;
    end;

  Advetdbase.connected := True;
  if advettranz.InTransaction then Advettranz.commit;
  advettranz.StartTransaction;

  _pcs := 'SELECT * FROM ' + _wuninev + _sorveg;
  _pcs := _pcs + 'WHERE ((SORSZAM LIKE ' + chr(39) + 'WB%' + chr(39)+') ';
  _pcs := _pcs + 'OR (SORSZAM LIKE ' + chr(39) + 'WK%' + chr(39) + ') ';
  _pcs := _pcs + 'AND (STORNO=1))'+_sorveg;

  with wuniquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not wuniquery.eof do
    begin
      _datum := wuniquery.fieldByNAme('DATUM').asString;
      _bizonylatszam := trim(wuniquery.FieldByNAme('SORSZAM').AsString);
      _ttipus := trim(wuniquery.FieldByNAme('TRANZAKCIOTIPUS').AsString);
      _foegyseg := Wuniquery.fieldbyname('FOEGYSEG').asInteger;
      _dnem[1] := Wuniquery.FieldByNAme('VALUTANEM').asString;
      _osszeg[1] := WuniQuery.fieldByName('BANKJEGY').asInteger;

      if _foegyseg=1 then _tars := 'EXCL. CASH';
      If _foegyseg=2 then _tars := 'W. UNION';

      if _ttipus='-K' Then
        begin
          _kuldo := inttostr(_aktpenztar);
          _fogado := _tars;
          _ttip := 'WU-kiadás';
        end else
        begin
          _fogado := inttostr(_aktpenztar);
          _kuldo := _tars;
          _ttip := 'WU-átvétel';
        end;

      _pcs := 'INSERT INTO ' + _tablaNev + '(KULDO,FOGADO,DATUM,BIZONYLATSZAM,';
      _pcs := _pcs + 'TRANZTIPUS,OSSZEG,VALUTANEM,SZALLITONEV,';
      _pcs := _pcs + 'PLOMBASZAM,PENZTAR)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _kuldo + chr(39) + ',';
      _pcs := _pcs + chr(39) + _fogado + chr(39) + ',';
      _pcs := _pcs + chr(39) + _datum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _ttip + chr(39) + ',';
      _pcs := _pcs + inttostr(_osszeg[1]) + ',';
      _pcs := _pcs + chr(39) + _dnem[1] + chr(39) + ',';
      _pcs := _pcs + chr(39) + chr(39) + ',';
      _pcs := _pcs + chr(39) + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktpenztar) + ')';

      with AdvetQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;
      wuniquery.next;
    end;
  wuniquery.close;
  wunidbase.close;

  Advettranz.commit;
  Advetdbase.close;
end;


// =============================================================================
               procedure TForm1.AdvetParancs(_ukaz: string);
// =============================================================================

begin
  Advetdbase.connected := true;
  if advetTranz.InTransaction then advettranz.commit;
  advettranz.StartTransaction;
  with AdvetQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  AdvetTranz.commit;
  Advetdbase.close;
end;

// =============================================================================
                  function tform1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
             procedure TForm1.HOCOMBOChange(Sender: TObject);
// =============================================================================

begin
  Activecontrol := Startgomb;
end;

// ============================================================================
                       procedure TForm1.MakeExcel;
// ============================================================================

begin
  Form1.Memo.Lines.add('  ');
  Form1.Memo.lines.add('EXCELTÁBLA KÉSZÍTÉSE');

  _exfile := 'TRANZ'+_farok+'.xls';
  _exdir := 'c:\EXPRESSZ';
  if not directoryExists(_exdir) then Createdir(_exdir);
  _expath := _exdir + '\' + _exfile;

  if fileExists(_expath) then Sysutils.DeleteFile(_expath);
  ePathPanel.Caption := _expath;

  // ---------------------------------------------------------

  _oxl := CreateOLEOBJECT('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.add[1];
  _owb.Activate;

  Fejlec;
  Adatfeltoltes;

  _vanexcel := True;

  Advetdbase.close;
  AdvetQuery.close;

  _oxl.visible := true;
end;

// =============================================================================
                procedure TForm1.Fejlec;
// =============================================================================

begin
  _oxl.range['A1:A1'].Columnwidth := 8;
  _oxl.range['B1:B1'].Columnwidth := 18;
  _oxl.range['C1:C1'].Columnwidth := 18;
  _oxl.range['D1:D1'].Columnwidth := 14;
  _oxl.range['E1:E1'].Columnwidth := 18;
  _oxl.range['F1:F1'].Columnwidth := 14;
  _oxl.range['G1:G1'].Columnwidth := 12;
  _oxl.range['H1:H1'].Columnwidth := 13;
  _oxl.range['I1:I1'].Columnwidth := 20;
  _oxl.range['J1:J1'].Columnwidth := 13;

  _rangestr := 'B2:J2';
  _oxl.range[_rangestr].MergeCells := True;
  _oxl.range[_rangestr].Font.Name  := 'Arial';
  _oxl.range[_rangestr].Font.Bold  := True;
  _oxl.range[_rangestr].Font.Italic:= True;
  _oxl.range[_rangestr].Font.size  := 12;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Cells[2,2] := 'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK WESTERN UNION PÉNZSZÁLLÍTÁSAI';

  _rangestr := 'B4:C4';
  _oxl.range[_rangestr].MergeCells := True;

  _rangestr := 'D4:D5';
  _oxl.range[_rangestr].MergeCells := True;
  _oxl.range[_rangestr].VerticalAlignment := -4108;

  _rangestr := 'E4:E5';
  _oxl.range[_rangestr].MergeCells := True;
  _oxl.range[_rangestr].VerticalAlignment := -4108;

  _rangestr := 'F4:F5';
  _oxl.range[_rangestr].MergeCells := True;
  _oxl.range[_rangestr].Wraptext   := True;


  _rangestr := 'G4:H4';
  _oxl.range[_rangestr].MergeCells := True;

  _rangestr := 'I4:I5';
  _oxl.range[_rangestr].MergeCells := True;
  _oxl.range[_rangestr].Wraptext   := True;

  _rangestr := 'J4:J5';
  _oxl.range[_rangestr].MergeCells := True;
  _oxl.range[_rangestr].Wraptext   := True;


  _rangestr := 'B4:J5';

  _oxl.range[_rangestr].font.size   := 10;
  _oxl.range[_rangestr].Font.Name   := 'Arial';
  _oxl.range[_rangestr].Font.Bold   := True;
  _oxl.range[_rangestr].Font.Italic := True;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;


  _oxl.Cells[4,2] := 'PÉNZTÁRAK';
  _oxl.Cells[5,2] := 'KÜLDÕ';
  _oxl.Cells[5,3] := 'FOGADÓ';
  _oxl.Cells[4,4] := 'DÁTUM';
  _oxl.Cells[4,5] := 'BIZONYLATSZÁM';
  _oxl.Cells[4,6] := 'TRANZAKCIÓ TIPUSA';
  _oxl.Cells[4,7] := 'SZÁLLÍTOTT PÉNZ';
  _oxl.Cells[5,7] := 'ÖSSZEG';
  _oxl.Cells[5,8] := 'VALUTANEM';
  _oxl.Cells[4,9] := 'SZÁLLÍTÓ MEGNEVEZÉSE';
  _oxl.Cells[4,10] := 'PLOMBA SZÁMA';

  Vekonykeret('B5:B5');
  Vekonykeret('C5:C5');
  Vekonykeret('D4:D5');
  Vekonykeret('F4:F5');
  Vekonykeret('G4:H4');
  Vekonykeret('H5:H5');
  Vekonykeret('J4:J5');

  Vastagkeret('B4:J5');

  _range := _oxl.range['A6:A6'];
  _range.select;
  _oxl.activeWindow.freezePanes := true;
end;

// =============================================================================
                  procedure TForm1.ExcelKill;
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
    //      break;
        end;

      _Looper := Process32Next(_handle,_proc);
    end;
  CloseHandle(_handle);
end;

procedure TForm1.KilepoTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  if _vanExcel then
    begin
      _owb := unassigned;
      _oxl.quit;
      _oxl := unassigned;
    end;

  ExcelKill;
  Application.Terminate;
end;

// =============================================================================
           procedure TForm1.Vastagkeret(_rs: string);
// =============================================================================

begin
  _oxl.range[_rs].borderAround(1,4);
end;

// =============================================================================
          procedure TForm1.Vekonykeret(_rs: string);
// =============================================================================

begin
  _oxl.range[_rs].borderAround(1,2);
end;

// =============================================================================
          procedure TForm1.AdatFeltoltes;
// =============================================================================

begin
  AdvetDbase.connected := true;
  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAR,DATUM';

  with AdvetQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _lastPenztar := 0;
  _prisor := 6;
  while not Advetquery.eof do
    begin
      _aktpenztar := Advetquery.FieldByName('PENZTAR').asInteger;
      _bizonylatszam := trim(AdvetQuery.FieldByNAme('BIZONYLATSZAM').asString);
      if _aktpenztar>_lastpenztar then PenztarStart;

      _kuldo       := trim(AdvetQuery.FieldbyName('KULDO').asString);
      _fogado      := trim(AdvetQuery.FieldbyName('FOGADO').asString);
      _datum       := AdvetQuery.FieldbyName('DATUM').asString;
      _ttipus      := trim(AdvetQuery.FieldbyName('TRANZTIPUS').asString);
      _bankjegy    := AdvetQuery.FieldbyName('OSSZEG').asInteger;
      _aktdnem     := AdvetQuery.FieldbyName('VALUTANEM').asString;
      _szallitonev := trim(AdvetQuery.FieldbyName('SZALLITONEV').asString);
      _plombaszam  := trim(AdvetQuery.FieldbyName('KULDO').asString);

      _oxl.cells[_prisor,2] := _kuldo;
      _oxl.cells[_prisor,3] := _fogado;
      _oxl.cells[_prisor,4] := _datum;
      _oxl.cells[_prisor,5] := _bizonylatszam;
      _oxl.cells[_prisor,6] := _ttipus;
      _oxl.cells[_prisor,7] := _bankjegy;
      _oxl.cells[_prisor,8] := _aktdnem;
      _oxl.cells[_prisor,9] := _szallitonev;
      _oxl.cells[_prisor,10]:= _plombaszam;

      inc(_prisor);
      advetquery.next;
    end;
  Advetquery.close;
  Advetdbase.close;
  _owb.saveas(_exPath);

end;

// =============================================================================
                      procedure TForm1.PenztarStart;
// =============================================================================

begin
  inc(_prisor);
  _aktpenztarnev := Getpenztarnev(_aktpenztar);
  _lastpenztar := _aktpenztar;
  Advetquery.next;
  _tetel := 1;

  while not advetQuery.eof do
    begin
      _pt := AdvetQuery.FieldByNAme('PENZTAR').asInteger;
      if _pt>_lastpenztar then break;
      inc(_tetel);
      Advetquery.next;
    end;

  _pstr := inttostr(_prisor);

  _startsor := _prisor + 1;
  _endsor   := _prisor + _tetel;

  _rangestr := 'B'+_pstr+':J' + _pstr;

  _oxl.range[_rangestr].MergeCells := True;
  _oxl.range[_rangestr].Font.Name  := 'Arial';
  _oxl.range[_rangestr].Font.Bold  := True;
  _oxl.range[_rangestr].Font.Italic:= True;
  _oxl.range[_rangestr].Font.size  := 11;
  _oxl.range[_rangestr].Interior.color := $B0FFFF;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.Cells[_prisor,2] := _aktpenztarnev;

  Memo.Lines.add(_aktpenztarnev);

  _sstr := inttostr(_startsor);
  _estr := inttostr(_endsor);

  _rangestr := 'B' + _sstr + ':J' + _estr;
  _oxl.range[_rangestr].Font.Name  := 'Arial';
  _oxl.range[_rangestr].Font.Bold  := False;
  _oxl.range[_rangestr].Font.Italic:= False;
  _oxl.range[_rangestr].Font.size  := 10;

  _rangestr := 'B' + _sstr + ':F' + _estr;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'J' + _sstr + ':J' + _estr;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;

  _rangestr := 'G' + _sstr + ':G' + _estr;
  _oxl.range[_rangestr].NumberFormat := '### ### ###';

  AdvetQuery.first;
  Advetquery.locate('BIZONYLATSZAM',_BIZONYLATSZAM,[loPartialKey]);
  _prisor := _startsor;
end;

// =============================================================================
            function TForm1.Getpenztarnev(_pnum: byte): string;
// =============================================================================

var _pp: byte;

begin
  _PP := _pnum-150;
  result := inttostr(_pnum)+'. pénztár '+_penztarnev[_pp];
end;

procedure TForm1.Irodakbeolvasasa;

var _artfdbpath,_nev: string;

begin
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  _artfdbpath := _host + ':c:\CARTCASH\database\artcash.fdb';
  Artdbase.close;
  artdbase.DatabaseName := _artfdbPath;
  artdbase.Connected := True;

  with ArtQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not Artquery.Eof do
    begin
      _pt := ArtQuery.fieldByName('UZLET').asInteger;
      _nev:= trim(ArtQuery.FieldByNAme('KESZLETNEV').asString);
      _pt := _pt-150;
      _penztarnev[_pt] := _nev;
      Artquery.next;
    end;
  ArtQuery.close;
  Artdbase.close;

end;








end.

