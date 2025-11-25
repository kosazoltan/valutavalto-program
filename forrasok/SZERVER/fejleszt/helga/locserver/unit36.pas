unit Unit36;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, IBCustomDataSet, IBDatabase, IBTable, Grids, DBGrids,
  StdCtrls, Buttons, ExtCtrls, unit1, IBQuery, comObj,ActiveX, ShlObj,
  OleServer, Excel97;

type
  TATLAGDISPLAY = class(TForm)
    IDOSZAKPANEL: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    BitBtn1: TBitBtn;
    VALUTAPANEL: TPanel;
    MARGERACS: TDBGrid;
    ATLAGDBASE: TIBDatabase;
    ATLAGTRANZ: TIBTransaction;
    MARGESOURCE: TDataSource;
    VALUTALISTA: TListBox;
    Panel5: TPanel;
    ATLAGQUERY: TIBQuery;
    ATLAGQUERYIRODA: TSmallintField;
    ATLAGQUERYERTEKTAR: TSmallintField;
    ATLAGQUERYMEGNEVEZES: TIBStringField;
    ATLAGQUERYVALUTANEM: TIBStringField;
    ATLAGQUERYVETELBANKJEGY: TFloatField;
    ATLAGQUERYVETELERTEK: TFloatField;
    ATLAGQUERYELADBANKJEGY: TFloatField;
    ATLAGQUERYELADERTEK: TFloatField;
    ATLAGQUERYVETELATLAG: TFloatField;
    ATLAGQUERYELADATLAG: TFloatField;
    ATLAGQUERYVALUTANEV: TIBStringField;
    ATLAGQUERYMARGE: TFloatField;
    EXCELGOMB: TBitBtn;
    KILEPOTIMER: TTimer;
    ARFOLYAMQUERY: TIBQuery;
    ARFOLYAMDBASE: TIBDatabase;
    ARFOLYAMTRANZ: TIBTransaction;
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure VALUTALISTAEnter(Sender: TObject);
    procedure VALUTALISTAExit(Sender: TObject);
    procedure MARGERACSEnter(Sender: TObject);
    procedure MARGERACSExit(Sender: TObject);
    procedure EgyValAtlagDisplay(_ix: integer);
    procedure IkonKirako;
    function DnemScan(_vn: string):integer;

    procedure MARGERACSMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure VALUTALISTAMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure VALUTALISTAKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure VALUTALISTADblClick(Sender: TObject);
    procedure VALUTALISTAClick(Sender: TObject);
   
    procedure EXCELGOMBClick(Sender: TObject);
    procedure KILEPOTIMERTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ATLAGDISPLAY: TATLAGDISPLAY;
  _alapszuro,_szuro,_aktdnem,_aktdnev: string;
  _aktIndex,_vadarab: integer;
  _path,_mondat: string;
  _iras: textFile;

  _vanem: array of string;
  _vatlag, _vBankjegy, _eAtlag, _eBankjegy: array of array of real;
  _excelTabla,_sajatexcel,_range: variant;

implementation

{$R *.dfm}

procedure TATLAGDISPLAY.FormActivate(Sender: TObject);

var i: integer;
    _aktvalnev : string;

begin

  Top := _top + 200;
  Left := _left + 145;

  ValutaLista.Clear;
  for i := 0 to _valutaDarab-1 do
    begin
      _aktvalnev := '     ' + _dnev[i] + '      ';
      Valutalista.Items.Add(_aktValNev);
    end;
  ValutaLista.ItemIndex := 0;
  IdoszakPanel.Caption := _tolstring+' - '+_igstring;
  EgyvalAtlagDisplay(0);
end;

procedure TATLAGDISPLAY.BitBtn1Click(Sender: TObject);
begin
  KilepoTimer.Enabled := True;
end;

procedure TATLAGDISPLAY.VALUTALISTAEnter(Sender: TObject);
begin
  ValutaLista.Color := $b0ffff;
end;

procedure TATLAGDISPLAY.VALUTALISTAExit(Sender: TObject);
begin
  ValutaLista.Color := clWindow;
end;

procedure TATLAGDISPLAY.MARGERACSEnter(Sender: TObject);
begin
  MargeRacs.Color := $B0FFFF;
end;

procedure TATLAGDISPLAY.MARGERACSExit(Sender: TObject);
begin
  Margeracs.Color := clWindow;
end;

procedure TATLAGDISPLAY.MARGERACSMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := MargeRacs;
end;

procedure TATLAGDISPLAY.VALUTALISTAMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := ValutaLista;
end;

procedure TATLAGDISPLAY.VALUTALISTAKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  _aktindex := ValutaLista.ItemIndex;
  EgyValAtlagDisplay(_aktindex);
end;

procedure TAtlagDisplay.EgyValAtlagDisplay(_ix: integer);

begin

  _aktdnev := _dnev[_ix];
  _aktdnem := _dnem[_ix];
  ValutaPanel.Caption := _aktdnev;
  _szuro := 'VALUTANEM=' + chr(39) + _aktdnem + chr(39)+' AND (VETELATLAG>0 OR ELADATLAG>0)';

  Atlagdbase.Close;
  AtlagDbase.Connected := True;
  if Atlagtranz.InTransaction then atlagtranz.Commit;

  _pcs := 'SELECT * FROM ATLAGARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE '+_szuro + _sorveg;
  _pcs := _pcs + 'ORDER BY ERTEKTAR,IRODA';

  with AtlagQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;
  Margeracs.Repaint;
  activeControl := ValutaLista;
end;

procedure TATLAGDISPLAY.VALUTALISTADblClick(Sender: TObject);
begin
  _aktindex := ValutaLista.ItemIndex;
  EgyValAtlagDisplay(_aktindex);
end;


procedure TATLAGDISPLAY.VALUTALISTAClick(Sender: TObject);
begin
  _aktindex := ValutaLista.ItemIndex;
  EgyValAtlagDisplay(_aktindex);
end;

// ====================================================================
        procedure TATLAGDISPLAY.EXCELGOMBClick(Sender: TObject);
// ====================================================================


var i,j,_aktetss,_valss,_oszlop,_sor: integer;
    _aktvAtlag,_akteatlag: real;
begin
  ArfolyamDbase.Connected := true;
  _pcs := 'SELECT * FROM ARFOLYAM WHERE VALUTANEM<>'+CHR(39)+'EUA'+CHR(39)+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';
  with ArfolyamQuery do
    begin
      close;
      Sql.Clear;
      sql.Add(_PCS);
      Open;
      Last;
      _vaDarab := recno;
      First;
    end;

  Setlength(_vanem,_vadarab);
  Setlength(_vAtlag,_vadarab,_ertektardarab+2);
  Setlength(_vBankjegy,_vadarab,_ertektardarab+2);

  Setlength(_eAtlag,_vadarab,_ertektardarab+2);
  Setlength(_eBankjegy,_vadarab,_ertektardarab+2);
  i := 0;
  while not ArfolyamQuery.Eof do
    begin
      _vanem[i] := ArfolyamQuery.FieldByName('VALUTANEM').asstring;
      inc(i);
      ArfolyamQuery.Next;

    end;

  ArfolyamQuery.Close;
  ArfolyamDbase.Close;

  for i := 0 to _vadarab-1 do
    begin
      for j := 0 to _ertektardarab+1 do
        begin
          _vAtlag[i,j] := 0;
          _eatlag[i,j] := 0;
          _vbankjegy[i,j] := 0;
          _eBankjegy[i,j] := 0;
        end;
    end;

  _pcs := 'SELECT * FROM ATLAGARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE IRODA=0 AND ERTEKTAR>0';

  with AtlagQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _VALSS := 1;
  while not AtlagQuery.Eof do
    begin
      _aktertektar := AtlagQuery.FieldByName('ERTEKTAR').asInteger;
      _valutanem := AtlagQuery.FieldByName('VALUTANEM').asString;
 //     _aktetss := Form1.ErtTarScan(_aktertektar);
 //     _valss := DnemScan(_valutanem);
      if _valss<0 then
        begin
          Atlagquery.next;
          Continue;
        end;
      _aktvAtlag := AtlagQuery.FieldByNAme('VETELATLAG').asFloat;
      _akteAtlag := AtlagQuery.FieldByName('ELADATLAG').asFloat;
      _vAtlag[_valSs,_aktetss] := _aktVAtlag/100;
      _eatlag[_valSs,_aktetss] := _akteAtlag/100;
      _vBankjegy[_valSs,_aktEtss] := AtlagQuery.FieldByName('VETELBANKJEGY').asInteger;
      _eBankjegy[_valSs,_aktEtss] := AtlagQuery.FieldByName('ELADBANKJEGY').asInteger;
      AtlagQuery.next;
    end;

  _pcs := 'SELECT * FROM ATLAGARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE IRODA=0 AND ERTEKTAR=0';

  with AtlagQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not AtlagQuery.Eof do
    begin
      _valutanem := AtlagQuery.FieldByName('VALUTANEM').asString;
      _valss := DnemScan(_valutanem);
      if _valss<0 then
        begin
           AtlagQuery.Next;
           Continue;
         end;  
      _aktvAtlag := AtlagQuery.FieldByNAme('VETELATLAG').asFloat;
      _vAtlag[_valSs,_ertekTarDarab] := _aktVAtlag/100;
      _aktEAtlag := AtlagQuery.FieldByNAme('ELADATLAG').asFloat;
      _eAtlag[_valSs,_ertekTarDarab] := _akteAtlag/100;
      _vBankjegy[_valss,_ertektardarab] := AtlagQuery.FieldByName('VETELBANKJEGY').asInteger;
      _eAtlag[_valSs,_ertekTarDarab] := _aktEAtlag/100;
      _eBankjegy[_valss,_ertektardarab] := AtlagQuery.FieldByName('ELADBANKJEGY').asInteger;
      AtlagQuery.next;
    end;

  _pcs := 'SELECT * FROM ATLAGARFOLYAM';
  with AtlagQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _path := 'c:\receptor\mail\posta\Atlagarfolyam.xls';
  DeleteFile(_path);

  _excelTabla := cREATEOLEOBJECT('EXCEL.APPLICATION');
  _sajatexcel := _exceltabla.workbooks.add[1];
  _sajatexcel.Activate;

  // ---------------------------------------------------

  _excelTabla.Range['A1:AK1'].MergeCells := True;
  _excelTabla.Cells[1,1].Interior.color := $D080FF;
  _excelTabla.Cells[1,1].Font.color := clBlue;
  _excelTabla.Cells[1,1].Font.Size := 16;
  _exceltabla.Cells[1,1].Font.Bold := true;
  _excelTabla.Cells[1,1].HorizontalAlignment := -4108;
  _excelTabla.Cells[1,1] := 'ÁTLAGÁRFOLYAMOK '+_tolstring+' ÉS '+_igstring+' KÖZÖTT';

  _range := _excelTabla.Range['A5:A31'];
  _range.Select;
  _range.Interior.Color := $D080FF;
  _range.Font.Color := clBlue;
  _range.Font.Size := 12;
  _range.Font.Bold := True;
  _range.Columnwidth := 12;
  _range.HorizontalAlignment := -4108;

  // -----------------------------------------------------

  _range := _excelTabla.Range['B2:AK3'];
  _range.Select;
  _range.Font.Size := 14;
  _range.Font.Bold := true;
  _range.Font.Color := clBlue;
  _range.HorizontalAlignment := -4108;

   //- ----------------------------------------------

  _excelTabla.Range['A2:A4'].MergeCells := True;
  _exceltabla.Cells[2,1].Interior.Color := $D080FF;
  _excelTabla.Cells[2,1].Font.Color := clBlue;
  _excelTabla.Cells[2,1].Font.Size := 12;
  _exceltabla.Cells[2,1].Font.Bold := True;
  _excelTabla.Cells[2,1] := 'VALUTÁK';
  _exceltabla.Cells[2,1].VerticalAlignment := xlvAlignCenter;

  // -------------------------------------------------------

  _range := _excelTabla.Range['A32:AK32'];
  _range.Select;
  _range.MergeCells := True;
  _range.Interior.Color := $D080FF;
  _range.Font.Bold := True;
  _range.Font.Size := 16;

 // ---------------------------------------------------------

   _range := _excelTabla.Range['AL1:AL32'];
   _range.Select;
   _range.Interior.Color := $D080FF;

 // ---------------------------------------------------------

   _range := _excelTabla.Range['B3:AK31'];
   _range.Select;
   _range.Font.color := clBlue;
   _range.Font.Bold := True;
   _range.Font.Size := 12;

 // ---------------------------------------------------------

   _range := _exceltabla.Range['B2:E2'];
   _range.Select;
   _range.MergeCells := True;
   _range.Interior.Color := $B0FFFF;
   _excelTabla.Cells[2,2] := 'Szekszárd körzet';

 // ---------------------------------------------------------

   _range := _exceltabla.Range['J2:M2'];
   _range.Select;
   _range.MergeCells := True;
   _range.Interior.Color := $B0FFFF;
   _excelTabla.Cells[2,10] := 'Kecskemét körzet';

 // ---------------------------------------------------------

   _range := _exceltabla.Range['R2:U2'];
   _range.Select;
   _range.MergeCells := True;
   _range.Interior.Color := $B0FFFF;
   _excelTabla.Cells[2,18] := 'Nyíregyháza körzet';

// ---------------------------------------------------------

   _range := _exceltabla.Range['Z2:AC2'];
   _range.Select;
   _range.MergeCells := True;
   _range.Interior.Color := $B0FFFF;
   _excelTabla.Cells[2,26] := 'Pécs körzet';

// ---------------------------------------------------------

   _range := _exceltabla.Range['F2:I2'];
   _range.Select;
   _range.MergeCells := True;
   _range.Interior.Color := $FFFFA0;
   _excelTabla.Cells[2,6] := 'Szeged körzet';

// ---------------------------------------------------------

   _range := _exceltabla.Range['N2:Q2'];
   _range.Select;
   _range.MergeCells := True;
   _range.Interior.Color := $FFFFA0;
   _excelTabla.Cells[2,14] := 'Debrecen körzet';

// ---------------------------------------------------------

   _range := _exceltabla.Range['V2:Y2'];
   _range.Select;
   _range.MergeCells := True;
   _range.Interior.Color := $FFFFA0;
   _excelTabla.Cells[2,22] := 'Békéscsaba körzet';

// ---------------------------------------------------------

   _range := _exceltabla.Range['AD2:AG2'];
   _range.Select;
   _range.MergeCells := True;
   _range.Interior.Color := $FFFFA0;
   _excelTabla.Cells[2,30] := 'Kaposvár körzet';

// ---------------------------------------------------------

   _range := _exceltabla.Range['AH2:AK2'];
   _range.Select;
   _range.MergeCells := True;
   _range.Interior.Color := $D080FF;
   _excelTabla.Cells[2,34] := 'EXCLUSIVE CHANGE';



// =========================================================
    _range := _excelTabla.Range['B3:C3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $70C0FF;
    _excelTabla.Cells[3,2] := 'Vétel';
// ..................................................

    _range := _excelTabla.Range['D3:E3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $D080FF;
    _excelTabla.Cells[3,4] := 'Eladás';

//  --------------------------------------------------

    _range := _excelTabla.Range['F3:G3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $70C0FF;
    _excelTabla.Cells[3,6] := 'Vétel';
// ..................................................

    _range := _excelTabla.Range['H3:I3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $D080FF;
    _excelTabla.Cells[3,8] := 'Eladás';

//  --------------------------------------------------


    _range := _excelTabla.Range['J3:K3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $70C0FF;
    _excelTabla.Cells[3,10] := 'Vétel';
// ..................................................

    _range := _excelTabla.Range['L3:M3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $D080FF;
    _excelTabla.Cells[3,12] := 'Eladás';

//  --------------------------------------------------

   _range := _excelTabla.Range['N3:O3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $70C0FF;
    _excelTabla.Cells[3,14] := 'Vétel';
// ..................................................

    _range := _excelTabla.Range['P3:Q3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $D080FF;
    _excelTabla.Cells[3,16] := 'Eladás';

//  --------------------------------------------------
  _range := _excelTabla.Range['R3:S3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $70C0FF;
    _excelTabla.Cells[3,18] := 'Vétel';
// ..................................................

    _range := _excelTabla.Range['T3:U3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $D080FF;
    _excelTabla.Cells[3,20] := 'Eladás';

//  --------------------------------------------------

 _range := _excelTabla.Range['V3:W3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $70C0FF;
    _excelTabla.Cells[3,22] := 'Vétel';
// ..................................................

    _range := _excelTabla.Range['X3:Y3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $D080FF;
    _excelTabla.Cells[3,24] := 'Eladás';

//  --------------------------------------------------

 _range := _excelTabla.Range['Z3:AA3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $70C0FF;
    _excelTabla.Cells[3,27] := 'Vétel';
// ..................................................

    _range := _excelTabla.Range['AB3:AC3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $D080FF;
    _excelTabla.Cells[3,28] := 'Eladás';

//  --------------------------------------------------
 _range := _excelTabla.Range['AD3:AE3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $70C0FF;
    _excelTabla.Cells[3,30] := 'Vétel';
// ..................................................

    _range := _excelTabla.Range['AF3:AG3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $D080FF;
    _excelTabla.Cells[3,32] := 'Eladás';

//  --------------------------------------------------

_range := _excelTabla.Range['AH3:AI3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $70C0FF;
    _excelTabla.Cells[3,34] := 'Vétel';
// ..................................................

    _range := _excelTabla.Range['AJ3:AK3'];
    _range.Select;
    _range.MergeCells := True;
    _range.Interior.Color := $D080FF;
    _excelTabla.Cells[3,36] := 'Eladás';

//  --------------------------------------------------

   for i := 0 to _vadarab-1 do
     begin
       _excelTabla.Cells[i+5,1] := _vanem[i];
     end;

   _qq := 2;
   while _qq<37 do
     begin
       _excelTabla.Cells[4,_qq] := 'Árfolyam';
       _excelTabla.Cells[4,_qq+1] := 'Összeg';
       _qq := _qq + 2;
     end;

// ****************************************************

    _range := _excelTabla.Range['B5:B32'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['C5:C31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
  _range := _excelTabla.Range['D5:D32'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['E5:E31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
   _range := _excelTabla.Range['F5:F31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['G5:G31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------

  _range := _excelTabla.Range['H5:H31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['I5:I31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
  _range := _excelTabla.Range['J5:J31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['K5:K31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
  _range := _excelTabla.Range['L5:L31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['M5:M31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
  _range := _excelTabla.Range['N5:N31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['O5:O31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
  _range := _excelTabla.Range['P5:P31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['Q5:Q31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
// -----------------------------------------------------
  _range := _excelTabla.Range['R5:R31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['S5:S31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------//
  _range := _excelTabla.Range['T5:T31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['U5:U31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------//
  _range := _excelTabla.Range['V5:V31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['W5:W31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
// -----------------------------------------------------
  _range := _excelTabla.Range['X5:X31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['Y5:Y31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
// -----------------------------------------------------
  _range := _excelTabla.Range['Z5:Z31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['AA5:AA31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
// -----------------------------------------------------
  _range := _excelTabla.Range['AB5:AB31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['AC5:AC31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// -----------------------------------------------------
  _range := _excelTabla.Range['AD5:AD31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['AE5:AE31'];
    _range.select;
    _range.NumberFormat := '### ### ###';
    // -----------------------------------------------------
  _range := _excelTabla.Range['AF5:AF31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['AG5:AG31'];
    _range.select;
    _range.NumberFormat := '### ### ###';
    // -----------------------------------------------------
  _range := _excelTabla.Range['AH5:AH31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['AI5:AI31'];
    _range.select;
    _range.NumberFormat := '### ### ###';
    // -----------------------------------------------------
  _range := _excelTabla.Range['AJ5:AJ31'];
    _range.select;
    _range.NumberFormat := '# ###,##';

    _range := _excelTabla.Range['AK5:AK31'];
    _range.select;
    _range.NumberFormat := '### ### ###';

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    _range := _excelTabla.Range['B4:AK31'];
    _range.select;
    _range.HorizontalAlignment := -4108;
    _range.columnwidth := 12;



// =============================================================================

    for i := 0 to _vaDarab-1 do
      begin

        for j := 0 to 8 do
          begin
            _oszlop := 2+trunc(4*j);
            _sor := i+5;
            _excelTabla.Cells[_sor,_oszlop] := _vAtlag[i,j];
            _excelTabla.Cells[_sor,_oszlop+1] := _vBankjegy[i,j];
            _excelTabla.Cells[_sor,_oszlop+2] := _eAtlag[i,j];
            _excelTabla.Cells[_sor,_oszlop+3] := _eBankjegy[i,j];
          end;
      end;


// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


  _sajatexcel.saveas(_path);

  _excelTabla.ActiveWorkBook.close;
  _excelTabla.quit;
  IkonKirako;

  KilepoTimer.Enabled := True;

end;

procedure TATLAGDISPLAY.KILEPOTIMERTimer(Sender: TObject);
begin
  KilepoTimer.Enabled := False;
  AtlagQuery.close;
  ModalResult := 1;
end;

// ========================================
        procedure TAtlagdisplay.IkonKirako;
// ========================================

var IObject: IUnKnown;
    isLink : IShellLink;
    ipFile : iPersistFile;
    PIDL   : pItemidList;
   inFolder: array[0..MAX_PATH] of char;
 TargetName: string;
   LinkName: widestring;

begin
  TargetName := 'C:\RECEPTOR\MAIL\POSTA\ATLAGARFOLYAM.XLS';

  IoBJECT := CreateComObject(CLSID_ShellLink);
  isLink := iObject as iShellLink;
  ipFile := iObject as iPersistFile;

  with Islink do
    begin
      SetPath(pchar(targetName));
      SetWorkingDirectory(pchar(extractFilePath(TargetName)));
    end;
  ShGetSpecialFolderLocation(0,CSIDL_DESKTOPDIRECTORY,PIDL);
  ShGetPathFromIdList(PIDL,InFolder);
  LinkName := infolder + '\Atlagarfolyam.lnk';
  ipFile.Save(pwChar(Linkname),False);
end;

function TAtlagdisplay.DnemScan(_vn: string):integer;
var _y: integer;
begin
  Result := -1;
  for _y := 0 to _vadarab-1 do
    begin
      if _vn = _vanem[_y] then
        begin
          Result := _y;
          Break;
        end;
    end;
end;

end.
