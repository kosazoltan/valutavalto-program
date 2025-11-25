unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,Comobj, Comctrls, ExtCtrls,unit1, StdCtrls,TlHelp32, Buttons;

type
  TMAKEEXCEL = class(TForm)
    Label1: TLabel;
    backgomb: TBitBtn;
    Shape1: TShape;
    procedure FormActivate(Sender: TObject);
    PROCEDURE Keretezo(_rstr: string);
    procedure backgombClick(Sender: TObject);
    procedure ExcelKill;
    procedure Setformula(_start,_end: integer);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MAKEEXCEL: TMAKEEXCEL;
  _oxl,_owb,_range: olevariant;
  _rangestr,_focim: string;
  _sumsor,_prisor,_sugyf: integer;
  _irodadarab,_pt: byte;
  _sft: real;
    proc : PROCESSENTRY32;
  _handle : HWND;
  _Looper : BOOL;

implementation

{$R *.dfm}

procedure TMAKEEXCEL.FormActivate(Sender: TObject);

var i,_elso: integer;

begin

  Top  := _top +30;
  Left := _left +190;

  BackGomb.Visible := false;
  MakeEXCEL.Repaint;


  _SUMSOR := 0;
  for i := 1 to 8 do _sumsor := _sumsor + _korzetirodadb[i];
  _sumsor := _sumsor + 24;

  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add[1];

  _range := _oxl.range['B3:X3'];
  _range.select;
  _range.mergecells  := true;
  _range.horizontalalignment := -4108;

  _range.Font.Name   := 'Arial';
  _range.Font.Size   := 14;
  _range.Font.Italic := true;
  _range.Font.Bold   := TRUE;
  _FOCIM := 'ÖSSZESÍTETT FORGALOM '+_tols + ' ÉS '+_igs+' KÖZÖTT';

  // ---------------------------------------

  _oxl.cells[1,2].columnwidth  := 10;
  _oxl.cells[1,3].columnwidth  := 28;
  _oxl.cells[1,4].columnwidth  := 10;
  _oxl.cells[1,5].columnwidth  := 14;
  _oxl.cells[1,6].columnwidth  := 10;
  _oxl.cells[1,7].columnwidth  := 14;
  _oxl.cells[1,8].columnwidth  := 10;
  _oxl.cells[1,9].columnwidth  := 14;
  _oxl.cells[1,10].columnwidth := 10;
  _oxl.cells[1,11].columnwidth := 14;
  _oxl.cells[1,12].columnwidth := 14;
  _oxl.cells[1,13].columnwidth := 10;
  _oxl.cells[1,14].columnwidth := 14;
  _oxl.cells[1,15].columnwidth := 14;
  _oxl.cells[1,16].columnwidth := 10;
  _oxl.cells[1,17].columnwidth := 14;
  _oxl.cells[1,18].columnwidth := 14;
  _oxl.cells[1,19].columnwidth := 14;
  _oxl.cells[1,20].columnwidth := 14;
  _oxl.cells[1,21].columnwidth := 10;
  _oxl.cells[1,22].columnwidth := 14;
  _oxl.cells[1,23].columnwidth := 14;
  _oxl.cells[1,24].columnwidth := 14;


   // --------------------------------------------

  _rangestr := 'B6:B8';
  _range := _oxl.range[_rangestr];
  _range.select;
  _range.mergecells  := true;

  _range.VerticalAlignment   := -4108;
  _range.HorizontalAlignment := -4117;

  _range.font.italic := True;
  _range.font.Bold := True;
  Keretezo(_rangestr);

   // --------------------------------------------

  _rangestr := 'C6:C8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment  := -4117;
  _range.VerticalAlignment    := -4108;

  _range.font.italic := True;
  _range.font.Bold := True;
  Keretezo(_rangestr);


   // --------------------------------------------

  _rangestr := 'D6:I6';
  _range := _oxl.range[_rangestr];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment := -4108;
  _range.font.italic := True;
  _range.font.Bold := True;
  Keretezo(_rangestr);

   // --------------------------------------------

  _range := _oxl.range['D7:E7'];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment := -4108;
  _range.font.italic := True;

   // --------------------------------------------

  _range := _oxl.range['F7:G7'];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment := -4108;
  _range.font.italic := True;

   // --------------------------------------------

  _range := _oxl.range['H7:I7'];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment := -4108;
  _range.font.italic := True;

   // --------------------------------------------

  _rangestr := 'J6:L6';
  _range := _oxl.range[_rangestr];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment := -4108;
  _range.font.italic := True;
  _range.font.Bold := True;
  Keretezo(_rangestr);


  // --------------------------------------------

  _rangestr := 'J7:J8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment:= -4108;
  _range.VerticalAlignment  := -4108;

  _range.font.italic := True;

  Keretezo('J7:L8');

  // --------------------------------------------

  _rangestr := 'K7:K8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;

  _range.HorizontalAlignment  := -4108;
  _range.VerticalAlignment    := -4108;

  _range.font.italic := True;


  // --------------------------------------------

  _rangestr := 'L7:L8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment  := -4108;
  _range.VerticalAlignment    := -4108;

  _range.font.italic := True;

  // --------------------------------------------

  _rangestr := 'M7:M8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment  := -4108;
  _range.VerticalAlignment    := -4108;
  _range.font.italic := True;

  Keretezo('M7:O8');

  // --------------------------------------------

  _rangestr := 'N7:N8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment  := -4108;
  _range.VerticalAlignment    := -4108;
  _range.font.italic := True;

  // --------------------------------------------

  _rangestr := 'O6:O8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment  := -4108;
  _range.VerticalAlignment    := -4108;
  _range.font.italic := True;
  _range.font.Bold := True;
  Keretezo(_rangestr);


  // --------------------------------------------

  _rangestr := 'P7:P8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment  := -4108;
  _range.VerticalAlignment    := -4108;

  _range.font.italic := True;

  Keretezo('P7:T8');

  // --------------------------------------------

  _rangestr := 'Q7:Q8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;

  _range.HorizontalAlignment  := -4117;
  _range.VerticalAlignment    := -4108;

  _range.font.italic := True;

  // --------------------------------------------

  _rangestr := 'R7:R8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;

  _range.HorizontalAlignment  := -4108;
  _range.HorizontalAlignment  := -4117;
  _range.VerticalAlignment    := -4108;

  _range.font.italic := True;
  
  // --------------------------------------------

  _rangestr := 'S7:S8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;
 
  _range.HorizontalAlignment  := -4117;
  _range.VerticalAlignment    := -4108;
  _range.font.italic := True;


  // --------------------------------------------

  _rangestr := 'T7:T8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment  := -4108;
  _range.VerticalAlignment    := -4108;

  _range.font.italic := True;


   // --------------------------------------------

  _rangestr := 'M6:N6';
  _range := _oxl.range[_rangestr];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment := -4108;
  _range.font.italic := True;
  _range.font.Bold := True;
  Keretezo(_rangestr);

   // --------------------------------------------

  _rangestr := 'P6:T6';
  _range := _oxl.range[_rangestr];
  _range.select;
  _range.mergecells  := true;
  _range.HorizontalAlignment := -4108;
  _range.font.italic := True;
  _range.font.Bold := True;
  Keretezo(_rangestr);

   // --------------------------------------------

  _rangestr := 'U6:V6';
  _range := _oxl.range[_rangestr];
  _range.select;
  _range.mergecells  := true;
  _range.font.italic := True;
  _range.font.Bold := True;
   _range.HorizontalAlignment:= -4108;
  Keretezo(_rangestr);

   // --------------------------------------------

  _rangestr := 'U7:U8';
  _range := _oxl.range[_rangestr];
  _range.select;
  _range.mergecells  := true;
  _range.font.italic := True;
  _range.HorizontalAlignment  := -4108;
  _range.VerticalAlignment    := -4108;

  Keretezo('U7:V8');

   // --------------------------------------------

  _rangestr := 'V7:V8';
  _range := _oxl.range[_RANGESTR];
  _range.select;
  _range.mergecells  := true;
  _range.font.italic := True;
   _range.HorizontalAlignment  := -4108;
  _range.VerticalAlignment    := -4108;

   // --------------------------------------------

  _rangestr := 'W6:W8';
  _range := _oxl.range[_rangestr];
  _range.select;
  _range.mergecells  := true;
  _range.font.italic := True;
  _range.font.Bold := True;
  _range.HorizontalAlignment  := -4117;
  _range.VerticalAlignment    := -4108;

  Keretezo(_rangestr);

   // --------------------------------------------

   _rangestr := 'X6:X8';
  _range := _oxl.range[_rangestr];
  _range.select;
  _range.mergecells  := true;
  _range.font.italic := True;
  _range.font.Bold := True;
  _range.HorizontalAlignment  := -4117;
  _range.VerticalAlignment    := -4108;

  Keretezo(_rangestr);

  _rangestr := 'D7:E8';
  Keretezo(_rangestr);


  _rangestr := 'F7:G8';
  Keretezo(_rangestr);

  _rangestr := 'H7:I8';
  Keretezo(_rangestr);

  _rangestr := 'D8:I8';
  _oxl.range[_rangestr].HorizontalAlignment := -4108;



  _oxl.cells[6,2] := 'PÉNZTÁR SZÁMA';
  _oxl.cells[6,3] := 'PÉNZTÁR MEGNEVEZÉSE';
  _oxl.cells[6,4] := 'VALUTAVÁLTÁS';
  _oxl.cells[6,15]:= 'HASZON';
  _oxl.cells[7,4] := 'VÉTEL';
  _oxl.cells[7,6] := 'ELADÁS';
  _oxl.cells[7,8] := 'ÖSSZESEN';
  _oxl.cells[8,4] := 'ÜGYFÉL';
  _oxl.cells[8,5] := 'FORINT';
  _oxl.cells[8,6] := 'ÜGYFÉL';
  _oxl.cells[8,7] := 'FORINT';
  _oxl.cells[8,8] := 'ÜGYFÉL';
  _oxl.cells[8,9] := 'FORINT';

  _oxl.cells[6,10]:= 'WESTERN UNION';
  _oxl.cells[7,10]:= 'ÜGYFÉL';
  _oxl.cells[7,11]:= 'HUF';
  _oxl.cells[7,12]:= 'USD';
  _oxl.cells[7,13]:= 'ÜGYFÉL';
  _oxl.cells[7,14]:= 'FORINT';

  _oxl.cells[7,16]:= 'ÜGYFÉL';
  _oxl.cells[7,17]:= 'TELEFON FELTÖLTÉS';
  _oxl.cells[7,18]:= 'AUTÓPÁLYA MATRICA';
  _oxl.cells[7,19]:= 'PAYSAFE- CARD';
  _oxl.cells[7,20]:= 'ÖSSZESEN';
  _oxl.cells[7,21]:= 'ÜGYFÉL';
  _oxl.cells[7,22]:= 'FORINT';

  _oxl.cells[6,13]:= 'ÁFA VISSZATÉRÍTÉS';
  _oxl.cells[6,16]:= 'ELEKTRONIKUS KERESKEDÉS';
  _oxl.cells[6,21]:= 'AXA BIZTOSÍTÁS';
  _oxl.cells[6,23]:= 'KEZELÉSI DÍJ';
  _oxl.cells[6,24]:= 'TRANZAKCIÓ ADÓ';

  // -------------- itt a fejléc készen van ------------------------------------

   _rangestr := 'D9:X'+inttostr(_sumsor+9);
   _oxl.range[_rangestr].Numberformat := '### ### ### ###';
   _oxl.range[_rangestr].HorizontalAlignment:= -4108;

   _oxl.cells[3,2] := _focim;

   _korzet := 1;
   _prisor := 8;
   _utkorzet := 0;
   _elso := 10;
   while _korzet<=8 do
     begin
       if _korzet>_utkorzet then
         begin
           inc(_prisor);
           _rangestr := 'B'+inttostr(_prisor)+':C'+inttostr(_prisor);
           _oxl.range[_rangestr].mergecells := True;
           _oxl.range[_rangestr].Font.Bold := True;
           _oxl.range[_rangestr].Font.Italic := True;
           _oxl.range[_rangestr].Font.size := 12;
           _oxl.cells[_prisor,2] := _korzetnev[_korzet];
           _utkorzet := _korzet;

           _rangestr := 'B'+inttostr(_prisor)+':X'+inttostr(_prisor);
           _oxl.range[_rangestr].interior.color := $B0FFFF;

           inc(_prisor);
         end;


       _irodadarab := _korzetirodadb[_korzet];
       _pt := 1;
       while _pt<=_irodadarab do
         begin
           _aktpt := _korzetIrodaszam[_korzet,_pt];

           _sugyf := _vevok[_aktpt] + _eladok[_aktpt];
           _sFt   := _vetel[_aktpt] + _eladas[_aktpt];

           _oxl.cells[_prisor,2] := inttostr(_aktpt);
           _oxl.cells[_prisor,3] := _penztarnevek[_aktpt];

           _oxl.cells[_prisor,4] := inttostr(_eladok[_aktpt]);
           _oxl.cells[_prisor,5] := floattostr(_vetel[_aktpt]);

           _oxl.cells[_prisor,6] := inttostr(_vevok[_aktpt]);
           _oxl.cells[_prisor,7] := floattostr(_eladas[_aktpt]);

           _oxl.cells[_prisor,8]:= inttostr(_sugyf);
           _oxl.cells[_prisor,9]:= floattostr(_sft);

           _oxl.cells[_prisor,10]:= inttostr(_wuugyfel[_aktpt]);
           _oxl.cells[_prisor,11]:= floattostr(_wuhuf[_aktpt]);
           _oxl.cells[_prisor,12]:= floattostr(_wuusd[_aktpt]);

           _oxl.cells[_prisor,13]:= inttostr(_afaugyfel[_aktpt]);
           _oxl.cells[_prisor,14]:= floattostr(_afaforgalom[_aktpt]);
           _oxl.cells[_prisor,15]:= floattostr(_profit[_aktpt]);

           _sft := _telefon[_aktpt]+_automatrica[_aktpt]+_paysafecard[_aktpt];

           _oxl.cells[_prisor,16]:= inttostr(_ekerugyfel[_aktpt]);
           _oxl.cells[_prisor,17]:= floattostr(_telefon[_aktpt]);
           _oxl.cells[_prisor,18]:= floattostr(_automatrica[_aktpt]);
           _oxl.cells[_prisor,19]:= floattostr(_paysafecard[_aktpt]);
           _oxl.cells[_prisor,20]:= floattostr(_sft);

           _oxl.cells[_prisor,21]:= inttostr(_axaugyfel[_aktpt]);
           _oxl.cells[_prisor,22]:= floattostr(_axaforgalom[_aktpt]);

           _oxl.cells[_prisor,23]:= floattostr(_kezelesidij[_aktpt]);
           _oxl.cells[_prisor,24]:= floattostr(_tranzado[_aktpt]);
           inc(_pt);
           inc(_prisor);
         end;

       _oxl.cells[_prisor,3] := 'ÖSSZESEN';
       _rangestr := 'C'+inttostr(_prisor)+':X'+inttostr(_prisor);
       _range := _oxl.range[_rangestr];
       _range.select;
       _range.font.italic := True;
       _range.font.Bold := True;
       _range.font.color := clRed;

       Setformula(_elso,_prisor-1);
       _elso := _prisor +3;
       inc(_prisor);

       inc(_korzet);
     end;

  _range := _oxl.range['D9:D9'];
  _range.select;
  _oxl.Activewindow.FreezePanes := True;
  _oxl.visible := true;
  BackGomb.Visible := true;
end;

procedure TMakeExcel.Setformula(_start,_end: integer);

var _asc,_oo: byte;
    _oBetu,_formula: string;

begin
  _asc := 68;
  while _asc<=88 do
    begin
      _obetu := chr(_asc);
      _oo := _asc-64;
      _formula := '=SUM('+_OBETU+inttostr(_start)+':'+_OBETU+inttostr(_end)+')';
      _oxl.cells[_end+1,_oo].formula := _formula;
      inc(_asc);
    end;
end;


PROCEDURE TMakeExcel.Keretezo(_rstr: string);

begin
   _oxl.Range[_rstr].BorderAround(1,-4138,-4105);
end;

procedure TMAKEEXCEL.backgombClick(Sender: TObject);
begin
  _owb := unassigned;
  _oxl.quit;
  _oxl := unassigned;

  ExcelKill;
  mODALRESULT := 1;
end;


// =============================================================================
                  procedure TMakeExcel.ExcelKill;
// =============================================================================


var
  _fileName,_filePath: String;

begin

  Proc.dwSize := SizeOf(Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),proc.th32ProcessID),0);
          break;
        end;

      _Looper := Process32Next(_handle,proc);
    end;
  CloseHandle(_handle);
end;




end.
