unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, COMOBJ, unit1, StrUtils, StdCtrls, ComCtrls, Buttons;

type
  TMAKEEXCELTABLA = class(TForm)
    CSIK: TProgressBar;
    Label1: TLabel;
    KILEPOGOMB: TBitBtn;

    procedure FormActivate(Sender: TObject);
    function FTForm(_num: integer; _dim: string): string;
    procedure Tablafejlec;
    procedure MunkalapFejlec;
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure ExceladatFeltoltes;
    function ScanIrodasorszam(_ptsz: integer): byte;
    procedure OsszesenTablaRajzolas;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MAKEEXCELTABLA: TMAKEEXCELTABLA;

  _oxl,_owb,_range: OleVariant;
  _qq,_oszlopDarab,_lapszelesseg,_VV,_ii: integer;
  _lastletter,_rangeStr,_aktvaltonev: string;
  _aktirodaszam,_xx,_AKTOSZLOP,_munkaoszlop,_koszlop: byte;
  _aktIrodaNev: string;



implementation

{$R *.dfm}

procedure TMAKEEXCELTABLA.FormActivate(Sender: TObject);

VAR I,j: integer;
    _kNev: string;

begin
   tOP := _TOP+70;
   Left := _left+10;
   KILEPOGOMB.VISIBLE := False;
   MakeexcelTabla.Repaint;

   // --------------------------------------------------------------------------

   for i := 1 to 8 do
     begin
       for j := 1 to 20 do
         begin
           _korzetKeszlet[i,j] := 0;
           _korzetErtek[i,j] := 0;
         end;
     end;

   for j := 1 to 20 do
     begin
       _ebckeszlet[j] := 0;
       _ebcErtek[j] := 0;
     end;

   // --------------------------------------------------------------------------

   Csik.Position := 0;
   Csik.Repaint;

   _oxl := CreateOleObject('Excel.Application');
   _owb := _oxl.workbooks.add;

   _oxl.workbooks[1].sheets.add(,,9);
   for i := 1 TO 8 do
     begin
       _kNev := _korzetnevek[i]+'I KÖRZET';
       _oxl.workbooks[1].worksheets[i].name := _kNev;
     end;
   _oxl.workbooks[1].worksheets[9].name := 'EXCLUSIVE CHANGE';

   _korzet := 1;
   while _korzet<9 do
     begin
       _aktKorzetDarab := _korzetValtoDarab[_korzet];
       Tablafejlec;
       ExcelAdatFeltoltes;
       INC(_korzet);
     end;

  OsszesenTablaRajzolas;
  exceladatFeltoltes;

  Csik.Position := 100;
  Csik.Repaint;
  _OXL.VISIBLE := TRUE;
  Kilepogomb.Visible := true;
end;


// =============================================================================
                 procedure TmakeExcelTabla.TablaFejlec;
// =============================================================================


var _text: string;

begin
  _oszlopDarab := 4+trunc(2*_aktKorzetdarab); // 2 valutanem + 2*irodak + 2*összesen
  _lastLetter := chr(64+_oszlopdarab);

  _oxl.workSheets[_korzet].Range['A6:A25'].columnWidth := 5;
  _oxl.workSheets[_korzet].Range['A6:A25'].Font.Name := 'Arial';
  _oxl.workSheets[_korzet].Range['A6:A25'].Font.Size := 10;
  _oxl.workSheets[_korzet].Range['A6:A25'].Font.Bold := False;
  _oxl.workSheets[_korzet].Range['A6:A25'].Font.Italic := False;
  _oxl.workSheets[_korzet].Range['A6:A25'].HorizontalAlignment := -4108;

  // ---------------------------------------------------------------------------

  _oxl.worksheets[_korzet].Range['B6:B25'].columnWidth := 18;

  // ---------------------------------------------------------------------------

  _rangestr := 'C6:'+_lastletter+'25';
  _oxl.workSheets[_korzet].Range[_rangestr].columnWidth := 15;

  // ---------------------------------------------------------------------------

  _rangeStr := 'A2:'+chr(64+_oszlopdarab)+'5';
  _oxl.worksheets[_korzet].Range[_rangestr].Font.Name := 'Times New Roman';
  _oxl.worksheets[_korzet].Range[_rangestr].Font.Bold := True;
  _oxl.worksheets[_korzet].Range[_rangestr].Font.Italic := True;
  _oxl.worksheets[_korzet].Range[_rangestr].Font.Size := 12;

  // ---------------------------------------------------------------------------

  _rangestr := 'A2:'+chr(64+_oszlopDarab)+'2';
  _oxl.worksheets[_korzet].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzet].Range[_rangestr].font.Bold := True;
  _oxl.worksheets[_korzet].Range[_rangestr].Font.Italic := True;
  _oxl.worksheets[_korzet].Range[_rangestr].Font.size := 16;
  _oxl.worksheets[_korzet].Range[_rangestr].HorizontalAlignment := -4108;
  _text := _korzetNevek[_korzet]+' ';
  if _korzet<9 then _text := _text + 'KÖRZET ';
  _text := _text + _mamas + '-I KÉSZLETEI';
  _oxl.worksheets[_korzet].Cells[2,1]  := _TEXT;

  // ---------------------------------------------------------------------------

  _oxl.worksheets[_korzet].range['A4:B5'].MergeCells := true;
  _oxl.worksheets[_korzet].range['A4:B5'].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzet].range['A4:B5'].VerticalAlignment := -4108;
  _oxl.worksheets[_korzet].cells[4,1] := 'VALUTANEMEK';

  // ------------- EDDIG JÓ ----------------------------------------------------

  _rangestr := 'C5:'+ chr(64+_oszlopdarab)+'5';
  _oxl.worksheets[_korzet].range[_rangestr].HorizontalAlignment := -4108;

  _ii := 1;
  while _ii<=_aktKorzetDarab do
    begin
      _kOszlop := 1+trunc(2*_ii);  // 3,5,7
      _rangestr := chr(64+_koszlop)+'4:'+chr(65+_koszlop)+'4';
      _oxl.worksheets[_korzet].Range[_rangestr].mergecells := true;
      _oxl.worksheets[_korzet].Range[_rangestr].HorizontalAlignment := -4108;

      if _korzet>8 then
        begin
          _text := _korzetnevek[_ii]+' KÖRZET';
        end else
        begin
          _aktIrodaSzam := _valtosor[_korzet,_ii];
          _aktIrodaNev  := _irodanevek[_aktIrodaSzam];
          _text := inttostr(_aktIrodaszam)+'. '+ _aktirodaNev;
        end;
        
      _oxl.worksheets[_korzet].cells[4,_koszlop] := _text;

      _oxl.worksheets[_korzet].cells[5,_koszlop] := 'KÉSZLET';
      _oxl.worksheets[_korzet].cells[5,_koszlop+1] := 'ÉRTÉK';

      _rangeStr := chr(64+_koszlop)+'26:'+chr(65+_koszlop)+'26';
      _oxl.worksheets[_korzet].Range[_rangestr].Mergecells := true;
      _oxl.worksheets[_korzet].range[_rangestr].font.Size := 12;
      _oxl.worksheets[_korzet].range[_rangestr].font.Bold := True;
      _oxl.worksheets[_korzet].range[_rangestr].font.Italic := True;
      _oxl.worksheets[_korzet].Range[_rangestr].HorizontalAlignment := -4108;

      inc(_ii);
    end;

  _kOszlop := 1+trunc(2*_ii);
  _rangestr := chr(64+_koszlop)+'4:'+chr(65+_koszlop)+'4';
  
  _oxl.worksheets[_korzet].Range[_rangestr].mergecells := true;
  _oxl.worksheets[_korzet].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzet].cells[4,_koszlop] := 'ÖSSZESEN';
  _oxl.worksheets[_korzet].cells[5,_koszlop] := 'KÉSZLET';
  _oxl.worksheets[_korzet].cells[5,_koszlop+1] := 'ÉRTÉK';

  _rangestr := chr(64+_koszlop)+'26:'+chr(65+_koszlop)+'26';
  _oxl.worksheets[_korzet].Range[_rangestr].mergecells := true;
  _oxl.worksheets[_korzet].Range[_rangestr].HorizontalAlignment := -4108;

  // ---------------------------------------------------------------------------

  _ii := 1;
  while _ii<=20 do
    begin
      _oxl.worksheets[_korzet].cells[_ii+5,1] := _valutanemek[_ii];
      _oxl.worksheets[_korzet].cells[_ii+5,2] := _valutanevek[_ii];
      inc(_ii);
    end;

  _oxl.worksheets[_korzet].range['A26:B26'].Mergecells := true;
  _oxl.worksheets[_korzet].range['A26:B26'].font.Size := 12;
  _oxl.worksheets[_korzet].range['A26:B26'].Font.Bold := True;
  _oxl.worksheets[_korzet].range['A26:B26'].Font.Italic := true;
  _oxl.worksheets[_korzet].range['A26:B26'].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzet].cells[26,1] := 'ÖSSZESEN';

end;


// =============================================================================
                  procedure TMakeExcelTabla.MunkalapFejlec;
// =============================================================================



begin


  exit;
end;

procedure TMakeExcelTabla.ExcelAdatFeltoltes;

var _aktkeszlet,_aktertek,_sErtek: integer;

begin

  _rangestr := 'C6:'+_lastletter+'25';
  _oxl.worksheets[_korzet].Range[_rangestr].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzet].Range[_rangestr].Font.Italic := True;

  _sErtek := 0;
  _vv := 1;
  while _vv<=_aktKorzetdarab do
    begin
      _kOszlop := 1 + trunc(2*_vv);
      if _korzet<9 then
        begin
          _aktIrodaSzam := _valtosor[_korzet,_vv];
          _xx := ScanIrodasorszam(_aktirodaszam);  // Hányadik az élõk között
        end else _xx := 0;

      _ii := 1;
      _sertek := 0;
      while _ii<=20 do
        begin
          if _xx>0 then
            begin
              _aktkeszlet := _valutaKeszlet[_xx,_ii];
              _korzetkeszlet[_korzet,_ii] := _korzetKeszlet[_korzet,_ii] + _aktkeszlet;
              _ebcKeszlet[_ii] := _ebcKeszlet[_ii] + _aktkeszlet;
            end else _aktkeszlet := _korzetkeszlet[_vv,_ii];

          _oxl.worksheets[_korzet].cells[_ii+5,_koszlop] := Ftform(_aktkeszlet,'');
          if _xx>0 then
            begin
              _aktertek := trunc(_aktkeszlet*_elszarfolyamok[_ii]/100);
              _korzetErtek[_korzet,_ii] := _korzetertek[_korzet,_ii] + _aktertek;
              _ebcertek[_ii] := _ebcertek[_ii]+_aktertek;
            end else _aktertek := _korzetErtek[_vv,_ii];

          _sErtek := _sErtek + _aktErtek;
          _oxl.worksheets[_korzet].cells[_ii+5,_koszlop+1] := FtForm(_aktertek,'Ft');
          inc(_ii);
        end;
      _oxl.workSheets[_korzet].cells[26,_koszlop] := FtForm(_sertek,'Ft');
      inc(_vv);
    end;

  // ---------------------------------------------------------------------------

  _koszlop := 1 + trunc(2*_vv);
  _sertek := 0;
  _ii := 1;
  while _ii<=20 do
    begin
      if _korzet<9 then _aktkeszlet := _korzetKeszlet[_korzet,_ii]
      else _aktkeszlet := _ebcKeszlet[_ii];

      _oxl.worksheets[_korzet].cells[_ii+5,_koszlop] := FtForm(_aktkeszlet,'');

      if _korzet<9 then _aktertek :=  _korzetErtek[_korzet,_ii]
      else _aktertek := _ebcertek[_ii];

      _sertek := _sErtek + _aktErtek;
      _oxl.worksheets[_korzet].cells[_ii+5,_koszlop+1] := FtForm(_aktertek,'Ft');
      inc(_ii);
    end;
  _oxl.worksheets[_korzet].cells[26,_koszlop].font.color := clRed;
  _oxl.worksheets[_korzet].cells[26,_koszlop].font.Bold := true;
  _oxl.worksheets[_korzet].cells[26,_koszlop].font.Italic := true;
  _oxl.worksheets[_korzet].cells[26,_koszlop].font.Size := 12;
  _oxl.workSheets[_korzet].cells[26,_koszlop] := FtForm(_sertek,'Ft');
end;


function TMakeexceltabla.ScanIrodasorszam(_ptsz: integer): byte;

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<= _eloirodadarab do
    begin
      if _ptsz=_eloIrodasor[_y] then
        begin
          result := _y;
          break;
        end;
      inc(_y);
    end;
end;



function TMakeExcelTabla.FTForm(_num: integer; _dim: string): string;

var _nums: string;
    _p1,_numlen: integer;

begin
  _nums := inttostr(_num);
  _numlen := length(_nums);
  if _num = 0 then
    begin
      result := '-';
      exit;
    end;

  if _Numlen<4 then
    begin
      result := _nums;
      if _dim<>'' then result := result + ' '+_dim;
      exit;
    end;


  if _num>999999 then
    begin
      _p1 := _numlen-6;
      result := leftstr(_nums,_p1)+' '+midstr(_nums,_p1+1,3)+' '+midstr(_nums,_p1+4,3);
      if _dim<>'' then result := result + ' '+_dim;
      exit;
    end;

  _p1 := _numlen-3;
  result := leftstr(_nums,_p1)+' '+midstr(_nums,_p1+1,3);
  if _dim<>'' then result := result + ' '+_dim;
end;

procedure TMAKEEXCELTABLA.KILEPOGOMBClick(Sender: TObject);
begin
  _oxl.Quit;
  _oxl := UnAssigned;
  Application.Terminate;
end;

procedure TMAKEEXCELTABLA.OsszesenTablaRajzolas;

begin
  _aktKorzetDarab := 8;
  TablaFejlec;
end;

end.
