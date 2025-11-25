unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls,Comobj, StdCtrls;

type
  TEXCELFORM = class(TForm)
    KILEPO: TTimer;
    Label1: TLabel;
    Label2: TLabel;
    
    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure BestAdatok;
    procedure EastAdatok;
    procedure PannAdatok;
    procedure Zalogadatok;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EXCELFORM: TEXCELFORM;

  _oxl,_owb: olevariant;
  _rangestr,_FORMULA: string;
  _prisor,_lastrow,_pp,_bestsumrow,_eastsumrow,_pannsumrow: integer;
  _zalogsumrow,_lowest: integer;
  _aktpt: byte;



implementation

uses unit1;

{$R *.dfm}

procedure TEXCELFORM.FormActivate(Sender: TObject);
begin
  _oxl := CreateOleObject('EXCEL.APPLICATION');
  _owb := _oxl.workbooks.add[1];

  _oxl.range['B3:M3'].mergecells := true;
  _oxl.range['B3:M3'].font.size := 14;
  _oxl.range['B3:M3'].font.bold := True;
  _oxl.range['B3:M3'].Font.italic := true;
  _oxl.range['B3:M3'].interior.color := clyellow;
  _oxl.range['B3:M3'].HorizontalAlignment := -4108;
  _oxl.cells[3,2] := _focim;

  _oxl.range['A1:A1'].columnwidth := 2;
  _oxl.range['B1:B1'].columnwidth := 8;
  _oxl.range['C1:C1'].columnwidth := 31;
  _oxl.range['D1:D1'].columnwidth := 12;
  _oxl.range['E1:E1'].columnwidth := 12;
  _oxl.range['F1:F1'].columnwidth := 12;
  _oxl.range['G1:G1'].columnwidth := 12;
  _oxl.range['H1:H1'].columnwidth := 12;
  _oxl.range['I1:I1'].columnwidth := 12;
  _oxl.range['J1:J1'].columnwidth := 12;
  _oxl.range['K1:K1'].columnwidth := 12;
  _oxl.range['L1:L1'].columnwidth := 12;
  _oxl.range['M1:M1'].columnwidth := 15;

  _oxl.range['B5:C5'].MergeCells := True;
  _oxl.range['D5:F5'].MergeCells := True;
  _oxl.range['G5:I5'].MergeCells := True;
  _oxl.range['J5:L5'].MergeCells := True;
  _oxl.range['M5:M6'].MergeCells := True;
  _oxl.range['M5:M6'].Wraptext   := True;

  _oxl.cells[5,2] := 'PÉNZTÁR';
  _oxl.cells[5,4] := 'VALUTA VÁSÁRLÁS';
  _oxl.cells[5,7] := 'VALUTA ELADÁS';
  _oxl.cells[5,10]:= 'ÖSSZESEN';
  _oxl.cells[5,13]:= 'HAVI  FORGALOM';
  _oxl.cells[6,2] := 'SZÁMA';
  _oxl.cells[6,3] := 'MEGNEVEZÉSE';
  _oxl.cells[6,4] := 'VÁSÁRLÁS';
  _oxl.cells[6,5] := 'KEZ-I DÍJ';
  _oxl.cells[6,6] := 'ÖSSZES';
  _oxl.cells[6,7] := 'ELADÁS';
  _oxl.cells[6,8] := 'KEZ-I DÍJ';
  _oxl.cells[6,9] := 'ÖSSZES';
  _oxl.cells[6,10]:= 'FORGALOM';
  _oxl.cells[6,11]:= 'KEZ-I DÍJ';
  _oxl.cells[6,12]:= 'ÖSSZES';

  _oxl.range['B5:C5'].BorderAround(1,2);

  _oxl.range['D5:F5'].BorderAround(1,2);
  _oxl.range['G5:I5'].BorderAround(1,2);
  _oxl.range['J5:L5'].BorderAround(1,2);
  _oxl.range['C6:C6'].BorderAround(1,2);
  _oxl.range['E6:E6'].BorderAround(1,2);
  _oxl.range['G6:G6'].BorderAround(1,2);
  _oxl.range['I6:I6'].BorderAround(1,2);
  _oxl.range['L6:L6'].BorderAround(1,2);
  _oxl.range['B5:M6'].BorderAround(1,4);

  _oxl.range['B5:M6'].HorizontalAlignment := -4108;

  BestAdatok;
  EastAdatok;
  PannAdatok;
  ZalogAdatok;

  _lowest := _lastrow + 3;

  // =--------------------------------------------------------------------------

  _formula := '=(D' + inttostr(_bestsumrow) + '+D' + inttostr(_eastsumrow);
  _formula := _formula + '+D'+inttostr(_pannsumrow);
  if _zdb>0 then _formula := _formula + '+D'+inttostr(_zalogsumrow);
  _formula := _formula + ')';

  _rangestr := 'D'+inttostr(_lowest)+':D'+inttostr(_lowest);
  _oxl.range[_rangestr].formula := _formula;

  // ---------------------------------------------------------------------------

  _formula := '=(E' + inttostr(_bestsumrow) + '+E' + inttostr(_eastsumrow)+' +E';
  _formula := _formula + inttostr(_pannsumrow)+'+E'+inttostr(_zalogsumrow)+')';

  _rangestr := 'E'+inttostr(_lowest)+':E'+inttostr(_lowest);
  _oxl.range[_rangestr].formula := _formula;

  // ---------------------------------------------------------------------------
  _formula := '=(F' + inttostr(_bestsumrow) + '+F' + inttostr(_eastsumrow)+' +F';
  _formula := _formula + inttostr(_pannsumrow)+'+F'+inttostr(_zalogsumrow)+')';

  _rangestr := 'F'+inttostr(_lowest)+':F'+inttostr(_lowest);
  _oxl.range[_rangestr].formula := _formula;

  // ---------------------------------------------------------------------------
  _formula := '=(G' + inttostr(_bestsumrow) + '+G' + inttostr(_eastsumrow)+' +G';
  _formula := _formula + inttostr(_pannsumrow)+'+G'+inttostr(_zalogsumrow)+')';

  _rangestr := 'G'+inttostr(_lowest)+':G'+inttostr(_lowest);
  _oxl.range[_rangestr].formula := _formula;

  // ---------------------------------------------------------------------------
  _formula := '=(H' + inttostr(_bestsumrow) + '+H' + inttostr(_eastsumrow)+' +H';
  _formula := _formula + inttostr(_pannsumrow)+'+H'+inttostr(_zalogsumrow)+')';

  _rangestr := 'H'+inttostr(_lowest)+':H'+inttostr(_lowest);
  _oxl.range[_rangestr].formula := _formula;

  // ---------------------------------------------------------------------------
  _formula := '=(I' + inttostr(_bestsumrow) + '+I' + inttostr(_eastsumrow)+' +I';
  _formula := _formula + inttostr(_pannsumrow)+'+I'+inttostr(_zalogsumrow)+')';

  _rangestr := 'I'+inttostr(_lowest)+':I'+inttostr(_lowest);
  _oxl.range[_rangestr].formula := _formula;

  // ---------------------------------------------------------------------------
  _formula := '=(J' + inttostr(_bestsumrow) + '+J' + inttostr(_eastsumrow)+' +J';
  _formula := _formula + inttostr(_pannsumrow)+'+J'+inttostr(_zalogsumrow)+')';

  _rangestr := 'J'+inttostr(_lowest)+':J'+inttostr(_lowest);
  _oxl.range[_rangestr].formula := _formula;

  // ---------------------------------------------------------------------------
  _formula := '=(K' + inttostr(_bestsumrow) + '+K' + inttostr(_eastsumrow)+' +K';
  _formula := _formula + inttostr(_pannsumrow)+'+K'+inttostr(_zalogsumrow)+')';

  _rangestr := 'K'+inttostr(_lowest)+':K'+inttostr(_lowest);
  _oxl.range[_rangestr].formula := _formula;

  // ---------------------------------------------------------------------------
  _formula := '=(L' + inttostr(_bestsumrow) + '+L' + inttostr(_eastsumrow)+' +L';
  _formula := _formula + inttostr(_pannsumrow)+'+L'+inttostr(_zalogsumrow)+')';

  _rangestr := 'L'+inttostr(_lowest)+':L'+inttostr(_lowest);
  _oxl.range[_rangestr].formula := _formula;

  // ---------------------------------------------------------------------------

  _formula := '=(M' + inttostr(_bestsumrow) + '+M' + inttostr(_eastsumrow)+' +M';
  _formula := _formula + inttostr(_pannsumrow)+'+M'+inttostr(_zalogsumrow)+')';

  _rangestr := 'M'+inttostr(_lowest)+':M'+inttostr(_lowest);
  _oxl.range[_rangestr].formula := _formula;

  // ---------------------------------------------------------------------------


  _rangestr := 'B'+inttostr(_lowest)+':C'+inttostr(_lowest);
  _oxl.range[_rangestr].Mergecells := true;

  _oxl.cells[_lowest,2] := 'MINDÖSSZESEN';

  _rangestr := 'B' +inttostr(_lowest)+':M' + inttostr(_lowest);
  _oxl.range[_rangestr].font.color := clRed;
  _oxl.range[_rangestr].font.size := 12;
  _oxl.range[_rangestr].font.Bold := true;

  _Rangestr := 'A7:A7';
  _oxl.range[_rangestr].select;
  _oxl.activewindow.FreezePanes := true;

  if fileExists(_expath) then sysutils.DeleteFile(_expath);
  _owb.saveas(_expath);
  _oxl.quit;
  _oxl := unassigned;

  Kilepo.Enabled := true;

end;

// =============================================================================
           procedure TEXCELFORM.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  Modalresult := 1;
end;

// =============================================================================
                     procedure TExcelForm.BestAdatok;
// =============================================================================

var _bestbase: integer;
    _bs,_ls,_es,_ss: string;

begin

  IF _BDB=0 THEN EXIT;

  _bestBase := 9;
  _ss := inttostr(_BESTBASE-1);

  _lastrow := _bestbase + _bdb;

  _rangestr := 'B'+_ss+':C'+_ss;
  _oxl.range[_rangestr].mergecells := True;
  _oxl.range[_rangestr].Font.size := 14;
  _oxl.range[_rangestr].Interior.color := clYellow;
  _oxl.range[_rangestr].Font.Italic := true;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _Oxl.cells[(_bestbase-1),2] := 'EXCLUSIVE BEST CHANGE';

  inc(_bestbase);
  _prisor := _bestBase;

   _bs := inttostr(_bestbase);

  _rangestr := 'B'+_bs+':B'+inttostr(_lastrow);
  _oxl.range[_rangestr].HorizontalALignment := -4108;

  _pp := 1;
  while _pp<=_bdb do
    begin
      _aktpt := _bsor[_pp];
      _oxl.cells[_prisor,2] := inttostr(_aktpt);
      _oxl.cells[_prisor,3] := _ptnev[_aktpt];
      _oxl.cells[_prisor,4] := inttostr(_pvtot[_aktpt]);
      _oxl.cells[_prisor,5] := inttostr(_pvkdij[_aktpt]);

      _oxl.cells[_prisor,7] := inttostr(_petot[_aktpt]);
      _oxl.cells[_prisor,8] := inttostr(_pekdij[_aktpt]);

      _oxl.cells[_prisor,13] := inttostr(_Havisum[_aktpt]);
      inc(_pp);
      inc(_prisor);
    end;

  _formula := '=(D'+_bs+'-E'+_bs+')';
  _rangestr := 'F'+_bs+':F'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(G'+_bs+'+H'+_bs+')';
  _rangestr  := 'I'+_bs+':I'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(D'+_bs+'+G'+_bs+')';
  _rangestr  := 'J'+_bs+':J'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(E'+_bs+'+H'+_bs+')';
  _rangestr  := 'K'+_bs+':K'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(F'+_bs+'+I'+_bs+')';
  _rangestr  := 'L'+_bs+':L'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(F'+_bs+'+I'+_bs+')';
  _rangestr  := 'L'+_bs+':L'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  // -----------------------------------------------

  _bestsumrow := _lastrow+1;
  _ls := inttostr(_lastrow);
  _es := inttostr(_bestsumrow);

  _formula := '=SUM(D'+_bs+':D'+_ls+')';
  _rangestr := 'D'+_es+':D'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(E'+_bs+':E'+_ls+')';
  _rangestr := 'E'+_es+':E'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(F'+_bs+':F'+_ls+')';
  _rangestr := 'F'+_es+':F'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(G'+_bs+':G'+_ls+')';
  _rangestr := 'G'+_es+':G'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(H'+_bs+':H'+_ls+')';
  _rangestr := 'H'+_es+':H'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(I'+_bs+':I'+_ls+')';
  _rangestr := 'I'+_es+':I'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(J'+_bs+':J'+_ls+')';
  _rangestr := 'J'+_es+':J'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(K'+_bs+':K'+_ls+')';
  _rangestr := 'K'+_es+':K'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(M'+_bs+':M'+_ls+')';
  _rangestr := 'M'+_es+':M'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(L'+_bs+':L'+_ls+')';
  _rangestr := 'L'+_es+':L'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _rangestr := 'B10:M'+inttostr(_lastrow+1);
  _oxl.range[_rangestr].Numberformat := '### ### ###';

  _rangestr := 'B' + _es  + ':C'+_es;
  _oxl.range[_rangestr].Mergecells := true;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.cells[_bestsumrow,2] := 'BEST CHANGE ÖSSZESEN';

  _rangestr := 'B' + _es  + ':M'+_es;
  _oxl.range[_rangestr].font.color := clBlue;
  _oxl.range[_rangestr].font.Bold := true;
end;


// =============================================================================
                     procedure TExcelForm.EastAdatok;
// =============================================================================

var _eastbase: integer;
    _bs,_ls,_es,_ss: string;

begin
  if _edb=0 then exit;

  _eastBase := _bestsumrow+3;
  _ss := inttostr(_eastbase-1);

  _lastrow := _eastbase + _edb;

  _rangestr := 'B'+_ss+':C'+_ss;
  _oxl.range[_rangestr].mergecells := True;
  _oxl.range[_rangestr].Font.size := 14;
  _oxl.range[_rangestr].Font.Italic := true;
  _oxl.range[_rangestr].Interior.color := clYellow;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _Oxl.cells[(_eastbase-1),2] := 'EXCLUSIVE EAST CHANGE';

  inc(_eastbase);
  _prisor := _eastBase;

   _bs := inttostr(_eastbase);

  _rangestr := 'B'+_bs+':B'+inttostr(_lastrow);
  _oxl.range[_rangestr].HorizontalALignment := -4108;

  _pp := 1;
  while _pp<=_edb do
    begin
      _aktpt := _esor[_pp];
      _oxl.cells[_prisor,2] := inttostr(_aktpt);
      _oxl.cells[_prisor,3] := _ptnev[_aktpt];
      _oxl.cells[_prisor,4] := inttostr(_pvtot[_aktpt]);
      _oxl.cells[_prisor,5] := inttostr(_pvkdij[_aktpt]);

      _oxl.cells[_prisor,7] := inttostr(_petot[_aktpt]);
      _oxl.cells[_prisor,8] := inttostr(_pekdij[_aktpt]);

      _oxl.cells[_prisor,13] := inttostr(_Havisum[_aktpt]);
      inc(_pp);
      inc(_prisor);
    end;

  _formula := '=(D'+_bs+'-E'+_bs+')';
  _rangestr := 'F'+_bs+':F'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(G'+_bs+'+H'+_bs+')';
  _rangestr  := 'I'+_bs+':I'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(D'+_bs+'+G'+_bs+')';
  _rangestr  := 'J'+_bs+':J'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(E'+_bs+'+H'+_bs+')';
  _rangestr  := 'K'+_bs+':K'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(F'+_bs+'+I'+_bs+')';
  _rangestr  := 'L'+_bs+':L'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(F'+_bs+'+I'+_bs+')';
  _rangestr  := 'L'+_bs+':L'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  // -----------------------------------------------

  _eastsumrow := _lastrow+1;
  _ls := inttostr(_lastrow);
  _es := inttostr(_eastsumrow);

  _formula := '=SUM(D'+_bs+':D'+_ls+')';
  _rangestr := 'D'+_es+':D'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(E'+_bs+':E'+_ls+')';
  _rangestr := 'E'+_es+':E'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(F'+_bs+':F'+_ls+')';
  _rangestr := 'F'+_es+':F'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(G'+_bs+':G'+_ls+')';
  _rangestr := 'G'+_es+':G'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(H'+_bs+':H'+_ls+')';
  _rangestr := 'H'+_es+':H'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(I'+_bs+':I'+_ls+')';
  _rangestr := 'I'+_es+':I'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(J'+_bs+':J'+_ls+')';
  _rangestr := 'J'+_es+':J'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(K'+_bs+':K'+_ls+')';
  _rangestr := 'K'+_es+':K'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(L'+_bs+':L'+_ls+')';
  _rangestr := 'L'+_es+':L'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(M'+_bs+':M'+_ls+')';
  _rangestr := 'M'+_es+':M'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _rangestr := 'B10:M'+inttostr(_lastrow+1);
  _oxl.range[_rangestr].Numberformat := '### ### ###';

  _rangestr := 'B' + _es  + ':C'+_es;
  _oxl.range[_rangestr].Mergecells := true;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.cells[_eastsumrow,2] := 'EAST CHANGE ÖSSZESEN';

  _rangestr := 'B' + _es  + ':M'+_es;
  _oxl.range[_rangestr].font.color := clBlue;
  _oxl.range[_rangestr].font.Bold := true;
end;


// =============================================================================
                     procedure TExcelForm.PannAdatok;
// =============================================================================

var _pannbase: integer;
    _bs,_ls,_es,_ss: string;

begin
  if _pdb=0 then exit;
  _pannBase := _eastsumrow+3;
  _ss := inttostr(_pannbase-1);

  _lastrow := _pannbase + _Pdb;

  _rangestr := 'B'+_ss+':C'+_ss;
  _oxl.range[_rangestr].mergecells := True;
  _oxl.range[_rangestr].Font.size := 14;
  _oxl.range[_rangestr].Interior.color := clYellow;
  _oxl.range[_rangestr].Font.Italic := true;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _Oxl.cells[(_pannbase-1),2] := 'EXCLUSIVE PANNON CHANGE';

  inc(_pannbase);
  _prisor := _pannBase;

   _bs := inttostr(_pannbase);

  _rangestr := 'B'+_bs+':B'+inttostr(_lastrow);
  _oxl.range[_rangestr].HorizontalALignment := -4108;

  _pp := 1;
  while _pp<=_pdb do
    begin
      _aktpt := _psor[_pp];
      _oxl.cells[_prisor,2] := inttostr(_aktpt);
      _oxl.cells[_prisor,3] := _ptnev[_aktpt];
      _oxl.cells[_prisor,4] := inttostr(_pvtot[_aktpt]);
      _oxl.cells[_prisor,5] := inttostr(_pvkdij[_aktpt]);

      _oxl.cells[_prisor,7] := inttostr(_petot[_aktpt]);
      _oxl.cells[_prisor,8] := inttostr(_pekdij[_aktpt]);

      _oxl.cells[_prisor,13] := inttostr(_Havisum[_aktpt]);
      inc(_pp);
      inc(_prisor);
    end;

  _formula := '=(D'+_bs+'-E'+_bs+')';
  _rangestr := 'F'+_bs+':F'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(G'+_bs+'+H'+_bs+')';
  _rangestr  := 'I'+_bs+':I'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(D'+_bs+'+G'+_bs+')';
  _rangestr  := 'J'+_bs+':J'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(E'+_bs+'+H'+_bs+')';
  _rangestr  := 'K'+_bs+':K'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(F'+_bs+'+I'+_bs+')';
  _rangestr  := 'L'+_bs+':L'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(F'+_bs+'+I'+_bs+')';
  _rangestr  := 'L'+_bs+':L'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  // -----------------------------------------------

  _pannsumrow := _lastrow+1;
  _ls := inttostr(_lastrow);
  _es := inttostr(_pannsumrow);

  _formula := '=SUM(D'+_bs+':D'+_ls+')';
  _rangestr := 'D'+_es+':D'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(E'+_bs+':E'+_ls+')';
  _rangestr := 'E'+_es+':E'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(F'+_bs+':F'+_ls+')';
  _rangestr := 'F'+_es+':F'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(G'+_bs+':G'+_ls+')';
  _rangestr := 'G'+_es+':G'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(H'+_bs+':H'+_ls+')';
  _rangestr := 'H'+_es+':H'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(I'+_bs+':I'+_ls+')';
  _rangestr := 'I'+_es+':I'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(J'+_bs+':J'+_ls+')';
  _rangestr := 'J'+_es+':J'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(K'+_bs+':K'+_ls+')';
  _rangestr := 'K'+_es+':K'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(L'+_bs+':L'+_ls+')';
  _rangestr := 'L'+_es+':L'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(M'+_bs+':M'+_ls+')';
  _rangestr := 'M'+_es+':M'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _rangestr := 'B10:M'+inttostr(_lastrow+1);
  _oxl.range[_rangestr].Numberformat := '### ### ###';

  _rangestr := 'B' + _es  + ':C'+_es;
  _oxl.range[_rangestr].Mergecells := true;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.cells[_pannsumrow,2] := 'PANNON CHANGE ÖSSZESEN';

  _rangestr := 'B' + _es  + ':M'+_es;
  _oxl.range[_rangestr].font.color := clBlue;
  _oxl.range[_rangestr].font.Bold := true;
end;

// =============================================================================
                     procedure TExcelForm.ZalogAdatok;
// =============================================================================

var _zalogbase: integer;
    _bs,_ls,_es,_ss: string;

begin
  if _zdb=0 then exit;
  _zalogBase := _pannsumrow+3;
  _ss := inttostr(_zalogbase-1);

  _lastrow := _zalogbase + _Zdb;

  _rangestr := 'B'+_ss+':C'+_ss;
  _oxl.range[_rangestr].mergecells := True;
  _oxl.range[_rangestr].Font.size := 14;
  _oxl.range[_rangestr].Font.Italic := true;
  _oxl.range[_rangestr].Interior.color := clYellow;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _Oxl.cells[(_ZALOGbase-1),2] := 'EXPRESSZ ÉKSZERHÁZ';

  inc(_zalogbase);
  _prisor := _ZALOGBase;

   _bs := inttostr(_ZALOGbase);

  _rangestr := 'B'+_bs+':B'+inttostr(_lastrow);
  _oxl.range[_rangestr].HorizontalALignment := -4108;

  _pp := 1;
  while _pp<=_Zdb do
    begin
      _aktpt := _Zsor[_pp];
      _oxl.cells[_prisor,2] := inttostr(_aktpt);
      _oxl.cells[_prisor,3] := _ptnev[_aktpt];
      _oxl.cells[_prisor,4] := inttostr(_pvtot[_aktpt]);
      _oxl.cells[_prisor,5] := inttostr(_pvkdij[_aktpt]);

      _oxl.cells[_prisor,7] := inttostr(_petot[_aktpt]);
      _oxl.cells[_prisor,8] := inttostr(_pekdij[_aktpt]);

      _oxl.cells[_prisor,13] := inttostr(_Havisum[_aktpt]);
      inc(_pp);
      inc(_prisor);
    end;

  _formula := '=(D'+_bs+'-E'+_bs+')';
  _rangestr := 'F'+_bs+':F'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(G'+_bs+'+H'+_bs+')';
  _rangestr  := 'I'+_bs+':I'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(D'+_bs+'+G'+_bs+')';
  _rangestr  := 'J'+_bs+':J'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(E'+_bs+'+H'+_bs+')';
  _rangestr  := 'K'+_bs+':K'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(F'+_bs+'+I'+_bs+')';
  _rangestr  := 'L'+_bs+':L'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=(F'+_bs+'+I'+_bs+')';
  _rangestr  := 'L'+_bs+':L'+inttostr(_lastrow);
  _oxl.range[_rangestr].Formula := _formula;

  // -----------------------------------------------

  _zalogsumrow := _lastrow+1;
  _ls := inttostr(_lastrow);
  _es := inttostr(_zalogsumrow);

  _formula := '=SUM(D'+_bs+':D'+_ls+')';
  _rangestr := 'D'+_es+':D'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(E'+_bs+':E'+_ls+')';
  _rangestr := 'E'+_es+':E'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(F'+_bs+':F'+_ls+')';
  _rangestr := 'F'+_es+':F'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(G'+_bs+':G'+_ls+')';
  _rangestr := 'G'+_es+':G'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(H'+_bs+':H'+_ls+')';
  _rangestr := 'H'+_es+':H'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(I'+_bs+':I'+_ls+')';
  _rangestr := 'I'+_es+':I'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(J'+_bs+':J'+_ls+')';
  _rangestr := 'J'+_es+':J'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(K'+_bs+':K'+_ls+')';
  _rangestr := 'K'+_es+':K'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(L'+_bs+':L'+_ls+')';
  _rangestr := 'L'+_es+':L'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _formula := '=SUM(M'+_bs+':M'+_ls+')';
  _rangestr := 'M'+_es+':M'+_es;
  _oxl.range[_rangestr].Formula := _formula;

  _rangestr := 'B10:M'+inttostr(_lastrow+1);
  _oxl.range[_rangestr].Numberformat := '### ### ###';

  _rangestr := 'B' + _es  + ':C'+_es;
  _oxl.range[_rangestr].Mergecells := true;
  _oxl.range[_rangestr].HorizontalAlignment := -4108;
  _oxl.cells[_zalogsumrow,2] := 'EXPRESSZ ÖSSZESEN';

  _rangestr := 'B' + _es  + ':M'+_es;
  _oxl.range[_rangestr].font.color := clBlue;
  _oxl.range[_rangestr].font.Bold := true;
end;



end.
