unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, comobj,Excel97;

type
  TEXCELKESZITES = class(TForm)
    kilepo: TTimer;
    Label1: TLabel;
   
    procedure FormActivate(Sender: TObject);
    procedure kilepoTimer(Sender: TObject);
    procedure MakeExcelTabla;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EXCELKESZITES: TEXCELKESZITES;
  _excelPath,_text,_aktirodaNev: string;
  _oxl,_owb: variant;
  _ii,_aktirodaszam,_akthaszon: integer;

implementation

uses Unit1, Unit2;

{$R *.dfm}



procedure TEXCELKESZITES.FormActivate(Sender: TObject);
begin
  Top := _top;
  Left := _left;
  width := 1024;
  Height := 768;
  MakeexcelTabla;
  Kilepo.Enabled := true;
end;

procedure TEXCELKESZITES.kilepoTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  Modalresult := 1;
end;


// =============================================================================
                   procedure TexcelKeszites.MakeExceltabla;
// =============================================================================

var i,_korzet,_aktkorzetirodaDarab: integer;
    _knev,_rangestr: string;
begin

   _excelPath := 'C:\RECEPTOR\MAIL\POSTA\HASZON.XLS';
   if FileExists(_excelPath) then DeleteFile(_excelPath);

   _oxl := CreateOleObject('Excel.Application');
   _owb := _oxl.workbooks.add[1];

   // --------------  A 8 fül létrehozása és elnevezése ------------------------

   _oxl.workbooks[1].sheets.add(,,9);
   for i := 1 to 8 do
     begin
       _kNev := _korzetnev[i]+'I KÖRZET';
       _oxl.workbooks[1].worksheets[i].name := _kNev;
       _oxl.workbooks[1].worksheets[I].select;
     end;


  _korzet := 1;
  while _korzet<=8 do
    begin

      _aktkorzetirodadarab := _korzetIrodaDarab[_korzet];
      _rangestr := 'A4:C4';   // a teljes fejléc

      _oxl.worksheets[_korzet].Range[_rangestr].Font.Name   := 'Arial Rounded MT Bold';
      _oxl.worksheets[_korzet].Range[_rangestr].Font.Size   := 14;
      _oxl.worksheets[_korzet].cells[4,1] := 'Pénztár száma';
      _oxl.worksheets[_korzet].cells[4,2] := 'Pénztár megnevezése';
      _oxl.worksheets[_korzet].cells[4,3] := 'Havi haszon';
      _oxl.worksheets[_korzet].Range[_rangeStr].columnwidth := 40;
      _oxl.worksheets[_korzet].Range[_rangestr].HorizontalAlignment := -4108;


      _rangestr := 'A5:C'+ inttostr(_aktkorzetIrodaDarab);
      _oxl.worksheets[_korzet].Range[_rangestr].Font.Name   := 'Arial';
      _oxl.worksheets[_korzet].Range[_rangestr].Font.Size   := 14;
      _oxl.worksheets[_korzet].Range[_rangestr].HorizontalAlignment := -4108;


      _rangestr := 'A2:C2';
      _oxl.worksheets[_korzet].range[_rangestr].Mergecells := True;
      _oxl.worksheets[_korzet].range[_rangestr].Font.size := 16;
      _oxl.worksheets[_korzet].range[_rangestr].HorizontalAlignment := -4108;
      _text := _korzetNev[_korzet]+'I KÖRZET HAVI HASZONÉRTÉKE';
      _oxl.worksheets[_korzet].range[_rangestr] := _text;

      _rangestr := 'A5:C'+INTTOSTR(5+_aktkorzetirodadarab);
      _oxl.worksheets[_korzet].range[_rangestr].font.Name := 'Arial';
      _oxl.worksheets[_korzet].Range[_rangestr].Font.Italic := True;
      _oxl.worksheets[_korzet].Range[_rangestr].Font.Size   := 14;
      _oxl.worksheets[_korzet].Range[_rangestr].HorizontalAlignment := -4108;

      _ii := 1;
      while _ii<=_aktKorzetIrodaDarab do
        begin
          _aktirodaszam := _korzetIrodak[_korzet,_ii];
          _aktirodanev  := _irodaNev[_aktirodaszam];
          _akthaszon    := _wProfit[_aktirodaszam];

          _oxl.worksheets[_korzet].cells[_ii+4,1] := inttostr(_aktirodaszam);
          _oxl.worksheets[_korzet].cells[_ii+4,2] := _aktirodanev;
          _oxl.worksheets[_korzet].cells[_ii+4,3].numberFormat := '### ### ###';
          _oxl.worksheets[_korzet].cells[_ii+4,3] := inttostr(_akthaszon);

          inc(_ii);
        end;
      inc(_korzet);
    end;
  _owb.saveas(_excelpath);
  _oxl.quit;
  _oxl := unassigned;
  _owb := Unassigned;
  Kijelzes.ExcelKill;
end;

end.



