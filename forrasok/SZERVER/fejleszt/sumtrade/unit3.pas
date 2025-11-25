unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, comobj, unit1,
  ExtCtrls;

type
  TMEXCEL = class(TForm)
    Button1: TButton;
    SMQUERY: TIBQuery;
    SMDBASE: TIBDatabase;
    SMTRANZ: TIBTransaction;
    MESSPANEL: TPanel;

    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure MakeExcel;
    procedure Adatbeolvasas;
    procedure adatfeliro;
    procedure MindosszesenFeliro;

    function Null3(_b: byte): string;
    function ScanEt(_b: byte): byte;
    function Getpenztarnev(_b: byte): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MEXCEL: TMEXCEL;
  _oxl,_owb: variant;

  _etarnevsor: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
           'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR','EXPRESSZ');

  _ptdb: array[1..9] of byte;
  _irodasor: array[1..9,1..30] of byte;

  _rangestr,_aktetarnev,_aktptarnev,_pcs,_status: string;
  _xx,_prisor,_aktptdb,_aktetar,_aktptar,_ptss,_etutprisor: integer;
  _szamzaro,_telenor,_vodafon,_paysafecard: integer;
  _aktet,_aktpt: byte;


implementation

{$R *.dfm}

procedure TMEXCEL.Button1Click(Sender: TObject);
begin
  _owb := Unassigned;
  _oxl.quit;
  _oxl := Unassigned;

  Modalresult := 1;
end;



procedure TMexcel.MakeExcel;

begin

  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add[1];

  {
  _oxl.Range['A3:O35'].HorizontalAlignment := -4108;

  _rangestr := 'B5:O35';
  _oxl.range[_RANGESTR].NumberFormat := '### ### ###';
  }

  _rangestr := 'B3:N3';
  _oxl.Range[_rangestr].MergeCells := True;
  _oxl.Range[_rangestr].HorizontalAligNment := -4108;
  _oxl.Range[_rangestr].Font.Size := 14;
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Font.Italic := True;

  _oxl.Cells[3,2] := 'ELEKTROMOS KERESKEDÉS '+ _kezdonaps+ ' ÉS '+_vegsonaps+' KÖZÖTT';

  _rangestr := 'B5:N5';
  _oxl.Range[_rangestr].HorizontalAligNment := -4108;
  _oxl.Range[_rangestr].Font.Size := 11;
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Font.Italic := True;


  _oxl.Cells[5,2] := 'ÉRTÉKTÁR';
  _oxl.Cells[5,3] := 'PÉNZTÁR';
  _oxl.Cells[5,4] := 'NYITÓ';
  _oxl.Cells[5,5] := 'TELEFON';
  _oxl.Cells[5,6] := 'TELENOR';
  _oxl.Cells[5,7] := 'VODA';
  _oxl.Cells[5,8] := 'PAYSAFE';
  _oxl.Cells[5,9] := 'MATRICA';
  _oxl.Cells[5,10] := 'ÁTADÁS';
  _oxl.Cells[5,11] := 'ÁTVÉTEL';
  _oxl.Cells[5,12] := 'ZÁRÓ';
  _oxl.Cells[5,13] := 'SZÁM.';
  _oxl.Cells[5,14] := 'STÁT.';

  _oxl.Range['A1:A1'].columnWidth := 3;
  _oxl.Range['B1:B1'].columnWidth := 15;
  _oxl.Range['C1:C1'].columnWidth := 29;
  _oxl.Range['D1:D1'].columnWidth := 11;
  _oxl.Range['E1:E1'].columnWidth := 11;
  _oxl.Range['F1:F1'].columnWidth := 11;
  _oxl.Range['G1:G1'].columnWidth := 11;
  _oxl.Range['H1:H1'].columnWidth := 11;
  _oxl.Range['I1:I1'].columnWidth := 11;
  _oxl.Range['J1:J1'].columnWidth := 11;
  _oxl.Range['K1:K1'].columnWidth := 11;
  _oxl.Range['L1:L1'].columnWidth := 11;
  _oxl.Range['M1:M1'].columnWidth := 11;
  _oxl.Range['N1:N1'].columnWidth := 7;

   // ---------------------------------------

   _prisor := 5;
   _xx := 1;
   while _xx<=9 do
     begin
       _aktptdb := _ptdb[_xx];
       IF _aktptdb=0 then
         begin
           inc(_xx);
           Continue;
         end;

       _aktetar    := _etarszamok[_xx];
       _aktetarnev := _etarnevsor[_xx];
       _etutprisor := 1+_prisor +_ptdb[_xx];
       _rangeStr   := 'B'+inttostr(_prisor+1)+':B'+inttostr(_etutprisor);

       _oxl.Range[_rangestr].Mergecells := true;
       _oxl.Range[_rangestr].VerticalAlignment := -4108;
       _oxl.Range[_rangestr].HorizontalAlignment := -4108;
       _oxl.Range[_rangestr].WrapText := true;
       _oxl.cells[_prisor+1,2] := _aktetarnev+ ' KÖRZET';

       _rangestr := 'C'+inttostr(_prisor+1)+':N'+inttostr(_etutprisor);
       _oxl.Range[_rangestr].Font.size := 10;
       _oxl.Range[_rangestr].Font.Bold := False;
       _oxl.Range[_rangestr].Font.Italic := False;
     
       _rangestr := 'D'+inttostr(_prisor+1)+':M'+inttostr(_etutprisor);
       _oxl.Range[_rangestr].NumberFormat := '### ### ###';

       _rangestr := 'N'+inttostr(_prisor+1)+':N'+inttostr(_etutprisor);
       _oxl.Range[_rangestr].HorizontalAlignment := -4108;
       _oxl.Range[_rangestr].Font.Bold := true;

       _ptss := 1;
       while _ptss<=_aktptdb do
         begin
           _aktptar := _irodasor[_xx,_ptss];
           _aktptarnev := getpenztarnev(_aktptar);

           _pcs := 'SELECT * FROM SUMTRADE' + _sorveg;
           _pcs := _pcs + 'WHERE (ERTEKTAR='+inttostr(_aktetar)+') AND ';
           _pcs := _pcs + '(IRODASZAM='+inttostr(_aktptar)+')';

           AdatBeolvasas;
           inc(_prisor);

           _oxl.cells[_prisor,3] := null3(_aktptar)+' '+ _aktptarnev;
           AdatFeliro;

           inc(_ptss);
         end;

       _pcs := 'SELECT * FROM SUMTRADE' + _sorveg;
       _pcs := _pcs + 'WHERE (ERTEKTAR='+inttostr(_aktetar)+') AND ';
       _pcs := _pcs + '(IRODASZAM=0)';

       Adatbeolvasas;
       inc(_prisor);

       _rangestr := 'C'+inttostr(_prisor)+':M'+inttostr(_prisor);
       _oxl.Range[_rangestr].Font.Bold := True;

       _oxl.cells[_prisor,3] := _aktetarnev+' ÖSSZESEN';
       Adatfeliro;

       inc(_xx);
     end;

  MindosszesenFeliro;
  _rangestr := 'A6:A6';
  _oxl.range[_rangestr].select;
  _oxl.Activewindow.Freezepanes := true;
  Messpanel.Visible := false;

  _oxl.visible := true;
end;

procedure TMexcel.MindosszesenFeliro;

begin
  _pcs := 'SELECT * FROM SUMTRADE' + _sorveg;
  _pcs := _pcs + 'WHERE (ERTEKTAR=0) AND (IRODASZAM=0)';
  AdatBeolvasas;
  inc(_prisor);

  _rangestr := 'B' + inttostr(_prisor)+':C'+ inttostr(_prisor);
  _oxl.Range[_rangestr].MergeCells := True;
  _oxl.Range[_rangestr].HorizontalAligNment := -4108;
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Font.Italic := True;
  _oxl.Range[_rangestr].Font.Color := clRed;

  _rangestr := 'D' + inttostr(_prisor)+':M'+ inttostr(_prisor);
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Numberformat := '### ### ###';
  _oxl.Range[_rangestr].Font.Color := clRed;


  _rangestr := 'N' + inttostr(_prisor)+':N'+ inttostr(_prisor);
  _oxl.Range[_rangestr].HorizontalAligNment := -4108;
  _oxl.Range[_rangestr].Font.Bold := True;
  _oxl.Range[_rangestr].Numberformat := '### ### ###';

  _oxl.Cells[_prisor,2] := 'M I N D Ö S S Z E S E N :';
  AdatFeliro;
end;



procedure TMexcel.AdatBeolvasas;

begin
  smdbase.connected := true;
  with Smquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;

      _nyito := FieldByName('NYITO').asInteger;
      _telefon := FieldByName('TELEFON').asInteger;
      _vodafon := FieldByName('VODAFON').asInteger;
      _telenor := FieldByName('TELENOR').asInteger;
      _paysafecard := FieldByName('PAYSAFECARD').asInteger;
      _matrica := FieldByName('MATRICA').asInteger;
      _atvetel := FieldByName('ATVETEL').asInteger;
      _atadas := FieldByNAme('ATADAS').asInteger;
      _zaro := FieldByNAme('ZARO').asInteger;
      _szamzaro := FieldByName('SZAMZARO').asInteger;
      _status := trim(FieldByName('STATUS').asstring);
      Close;
    end;
  Smdbase.close;
end;


procedure TMexcel.Adatfeliro;

begin
  _oxl.cells[_prisor,4] := inttostr(_nyito);
  _oxl.cells[_prisor,5] := inttostr(_telefon);
  _oxl.cells[_prisor,6] := inttostr(_telenor);
  _oxl.cells[_prisor,7] := inttostr(_vodafon);
  _oxl.cells[_prisor,8] := inttostr(_paysafecard);
  _oxl.cells[_prisor,9] := inttostr(_matrica);
  _oxl.cells[_prisor,10]:= inttostr(_atadas);
  _oxl.cells[_prisor,11]:= inttostr(_atvetel);
  _oxl.cells[_prisor,12]:= inttostr(_zaro);
  _oxl.cells[_prisor,13]:= inttostr(_szamzaro);
  _oxl.cells[_prisor,14]:= _status;
end;

function TMexcel.ScanEt(_b: byte): byte;

var _y: byte;

begin
  _y := 1;
  result := 0;
  while _y<=9 do
    begin
      if _etarszamok[_y]=_b then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

function TMexcel.Getpenztarnev(_b: byte): string;

var _y: byte;

begin
  result := '??';
  _y := 0;
  while _y<_irodadarab do
    begin
      if _ptarnum[_y]=_b then
        begin
          result := _ptarnev[_y];
          exit;
        end;
      inc(_y);
    end;
end;


procedure TMEXCEL.FormActivate(Sender: TObject);

var i,_pp: byte;

begin
  Messpanel.Visible := true;
  mESSPANEL.Repaint;
  for i := 1 to 9 do _ptdb[i] :=0;

  _pcs := 'SELECT * FROM SUMTRADE' + _sorveg;
  _pcs := _pcs + 'ORDER BY ERTEKTAR,IRODASZAM';

  SMdbase.Connected := true;
  with Smquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;
  while not Smquery.Eof do
    begin
      _aktet := SmQuery.FieldByName('ERTEKTAR').asInteger;
      _aktpt := Smquery.FieldByName('IRODASZAM').asInteger;

      if _aktpt=0 then
        begin
          Smquery.next;
          Continue;
        end;
      _xx := ScanEt(_aktet);
      _pp := 1 + _ptdb[_xx];
      _ptdb[_xx] := _pp;
      _irodasor[_xx,_pp] := _aktPt;
      Smquery.Next;
    end;

  Makeexcel;
  
end;


function TMexcel.Null3(_b: byte): string;

begin
  result := inttostr(_b);
  while length(result)<3 do result := '0' + result;
end;


end.
