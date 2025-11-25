unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBTable, IBCustomDataSet, IBQuery, ComCtrls,
  StdCtrls, Buttons, DAteUtils,strutils, ComObj, ExtCtrls;

type
  TForm1 = class(TForm)
    EVCOMBO: TComboBox;
    STARTGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    LCSIK: TProgressBar;
    IBQUERY: TIBQuery;
    IBTABLA: TIBTable;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    HCSIK: TProgressBar;
    Shape1: TShape;
    honappanel: TPanel;
    penztarpanel: TPanel;
    focimpanel: TPanel;

    procedure STARTGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    function Nulele(_int: byte): string;
    function Ezertektar(_ptn: byte): boolean;
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure Excelkeszites;
    procedure KeretHuzas;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _honev: array[1..12] of string = ('január','február','március','április',
                    'május','junius','július','augusztus','szeptember',
                    'október','november','december');

  _maiev,_maiho,_kertev,_kertho: word;
  _farok,_wuninev,_narfnev,_aktfdbpath,_pcs,_datum,_valutanem: string;
  _sorveg: string = chr(13) + chr(10);
  _udbe,_udki,_ftbe,_ftki: array[1..150] of real;
  _qq,_nap,_ptardb,_utolsohonap,_akthonap: byte;
  _elsz,_bankjegy,_RC,_CC,_sor: integer;
  _usdelsz: array[1..31] of integer;
  _ptarnev: array[1..150] of string;

  _exceltabla,_sajatexcel: olevariant;
  _rangestr,_ttipus: string;
  _vanexcel: boolean;


implementation

{$R *.dfm}

procedure TForm1.FormActivate(Sender: TObject);

var i,_uzlet: integer;
    _nev: string;

begin
  _vanexcel := false;
  ibdbase.close;
  ibdbase.DatabaseName := 'c:\receptor\database\receptor.fdb';
  ibdbase.Connected := true;

  _pcs := 'SELECT * FROM IRODAK';
  WITH IBQUERY do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ibquery.Eof do
    begin
      _uzlet := Ibquery.fieldbyName('UZLET').asInteger;
      _nev := trim(Ibquery.FieldByName('KESZLETNEV').asstring);
      _ptarnev[_uzlet] := _nev;
      ibquery.next;
    end;
  ibquery.close;
  ibdbase.close;

  // -------------------------------------------------------------------

  _maiev := yearof(date);
  _maiho := monthof(date);

  evcombo.Items.clear;

  for i := 0 to 4 do
      evcombo.Items.Add(inttostr(_maiev-i));

  evcombo.itemindex := 0;

  Activecontrol := Startgomb;

end;




procedure TForm1.STARTGOMBClick(Sender: TObject);

var i,_evindex: integer;

begin

  StartGomb.Visible := false;
  Evcombo.Visible := false;

  _evindex := evcombo.itemindex;
  _kertev := _maiev-_evindex;
  _utolsohonap := 12;
  if _evindex=0 then _utolsohonap := _maiho;
  Lcsik.Max := _utolsohonap;


  for i := 1 to 150 do
    begin
      _ftbe[i] := 0;
      _ftki[i] := 0;
      _udbe[i] := 0;
      _udki[i] := 0;
    end;

  _qq := 1;
  while _qq<=150 do
    begin
      Hcsik.Position := _QQ;
      if ezertektar(_qq) then
        begin
          inc(_qq);
          Continue;
        end;

      _aktfdbpath := 'c:\receptor\database\v' + inttostr(_qq)+'.fdb';

      if not fileExists(_aktfdbPath) then
        begin
          inc(_qq);
          Continue;
        end;

        PenztarPanel.caption := _ptarnev[_qq];
        PenztarPanel.Repaint;
      _akthonap := 1;

      while _akthonap<=_utolsohonap do
        begin
          Lcsik.Position := _akthonap;

          _farok := inttostr(_kertev-2000)+nulele(_akthonap);
          _wuninev := 'WUNI' + _farok;

          ibdbase.close;
          ibtabla.close;

          ibtabla.TableName := _wuninev;
          ibdbase.DatabaseName := _aktfdbPath;
          ibdbase.Connected := true;

          if not ibtabla.Exists then
            begin
              ibdbase.close;
              inc(_akthonap);
              continue;
            end;

          HonapPanel.Caption := _honev[_akthonap];
          FocimPanel.repaint;
          PenztarPanel.Repaint;
          HonapPanel.Repaint;

          _pcs := 'SELECT * FROM ' + _wuninev + _sorveg;
          _pcs := _pcs + 'WHERE (STORNO=1) AND (UGYFELTIPUS='+chr(39)+'U'+chr(39) + ')';

          with Ibquery do
            begin
              Close;
              Sql.clear;
              Sql.add(_pcs);
              Open;
              First;
            end;

          while not ibquery.eof do
            begin
              _bankjegy := Ibquery.FieldByName('BANKJEGY').asInteger;
              _valutanem := ibQuery.FieldByName('VALUTANEM').asString;
              _ttipus := IbQuery.Fieldbyname('TRANZAKCIOTIPUS').asString;

              if _valutanem='USD' THEN
                begin
                  if _ttipus='+B' then _udbe[_qq] := _udbe[_qq] + _bankjegy
                  else _udki[_qq] := _udki[_qq] + _bankjegy;
                end else
                begin
                  if _ttipus='+B' then _ftbe[_qq] := _ftbe[_qq] + _bankjegy
                  else _ftki[_qq] := _ftki[_qq] + _bankjegy;
                end;
              ibquery.next;
            end;
          ibquery.close;
          ibdbase.close;

          inc(_akthonap);
        end;

      inc(_qq);
    end;

//  showmessage('EXCEL KESZITES');

  _ptardb := 0;
  for i := 1 to 150 do
    begin
      if (_udbe[i]>0) or (_udki[i]>0) or (_ftbe[i]>0) or (_ftki[i]>0) then inc(_ptardb);
    end;

  ExcelKeszites;




end;


function TForm1.ezertektar(_ptn: byte): boolean;

begin
  result := false;
  if (_ptn=10) or (_ptn=20) or (_ptn=40) or (_ptn=50) then result := true;
  if (_ptn=63) or (_ptn=75) or (_ptn=120) or (_ptn=145) then result := true;
end;



function TForm1.Nulele(_int: byte): string;

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + RESULT;
end;



procedure TForm1.excelkeszites;

var 
    _aktptarnev: string;
    _ube,_uki,_fbe,_fki: real;

begin
  _excelTabla := CreateOLEOBJECT('EXCEL.APPLICATION');
  _sajatexcel := _exceltabla.workbooks.add[1];
  _sajatexcel.Activate;

  _exceltabla.range['B1:B1'].Columnwidth := 15;
  _exceltabla.range['C1:C1'].Columnwidth := 30;
  _exceltabla.range['D1:D1'].Columnwidth := 18;
  _exceltabla.range['E1:E1'].Columnwidth := 18;
  _exceltabla.range['F1:F1'].Columnwidth := 18;
  _exceltabla.range['G1:G1'].Columnwidth := 18;


  _exceltabla.range['B5:G5'].MergeCells := true;
  _exceltabla.range['B5:G5'].HorizontalAlignment := -4108;
  _exceltabla.range['B5:G5'].Font.Size := 14;
  _exceltabla.range['B5:G5'].Font.Name := 'Times New Roman';
  _exceltabla.range['B5:G5'].Font.Italic := True;
  _exceltabla.range['B5:G5'].Font.Bold := True;
  _exceltabla.cells[5,2] := 'A '+inttostr(_kertev)+' ÉVI WESTERN UNION FORGALOM';

  _exceltabla.range['B7:B8'].MergeCells := true;
  _exceltabla.range['C7:C8'].Mergecells := true;
  _exceltabla.range['B7:C8'].HorizontalAlignment := -4108;
  _exceltabla.range['B7:C8'].VerticalAlignment := -4108;
  _exceltabla.range['B7:C8'].Font.bold := true;
  _exceltabla.range['B7:C8'].Font.Italic := true;

   _exceltabla.cells[7,2] := 'Pénztárszám';
   _exceltabla.cells[7,3] := 'Pénztár megnevezése';

   _exceltabla.range['D7:E7'].MergeCells := true;
   _exceltabla.range['F7:G7'].MergeCells := tRUE;
   _exceltabla.range['D7:G7'].HorizontalAlignment := -4108;
   _exceltabla.range['D7:G7'].Font.Bold := True;

   _exceltabla.cells[7,4] := 'AMERIKAI DOLLÁR';
   _exceltabla.cells[7,6] := 'MAGYAR FORINT';

   _exceltabla.range['D8:G8'].HorizontalAlignment := -4108;
   _exceltabla.range['D8:G8'].Font.Name := 'Times New Roman';
   _exceltabla.range['D8:G8'].Font.Italic := True;

   _exceltabla.cells[8,4] := 'BEFIZETÉS';
   _exceltabla.cells[8,5] := 'KIFIZETÉS';

   _exceltabla.cells[8,6] := 'BEFIZETÉS';
   _exceltabla.cells[8,7] := 'KIFIZETÉS';

  _rangestr := 'B7:G8';
  KeretHuzas;

  _rangestr := 'B7:D'+inttostr(_ptardb+8);
  KeretHuzas;

  _rangestr := 'D7:E'+inttostr(_ptardb+8);
  KeretHuzas;

  _rangestr := 'F7:G'+inttostr(_ptardb+8);
  KeretHuzas;


  _exceltabla.range['B7:B'+inttostr(8+_ptardb)].HorizontalAlignment := -4108;
  _exceltabla.range['D9:G'+INTTOSTR(8+_ptardb)].NumberFormat := '### ### ###';


  _qq := 1;
  _sor := 8;
  while _qq<=150 do
    begin
      _UBE := _udbe[_qq];
      _UKI := _udki[_qq];
      _FBE := _ftbe[_qq];
      _FKI := _ftki[_qq];
      if (_ube=0) and (_uki=0) and (_fbe=0) and (_fki=0) then
        begin
          inc(_qq);
          Continue;
        end;
      inc(_sor);

      _aktptarnev := _ptarnev[_qq];

      _exceltabla.cells[_sor,2] := inttostr(_qq);
      _exceltabla.cells[_sor,3] := _aktptarnev;
      _exceltabla.cells[_sor,4] := floattostr(_UBE);
      _exceltabla.cells[_sor,5] := floattostr(_UKI);
      _exceltabla.cells[_sor,6] := floattostr(_FBE);
      _exceltabla.cells[_sor,7] := floattostr(_FKI);

      inc(_qq);
    end;

  _vanexcel := true;
  _exceltabla.visible := true;
end;

procedure TForm1.KeretHuzas;

begin
  _exceltabla.Range[_rangestr].BorderAround(1,-4138,-4105);
end;


procedure TForm1.KILEPOGOMBClick(Sender: TObject);
begin
  if _vanexcel  then
    begin
      _exceltabla.quit;
      _excelTabla := unassigned;
    end;
  Application.Terminate;
end;

end.
