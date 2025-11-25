unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBQuery, IBCustomDataSet,
  IBTable, dateutils, strutils, ExtCtrls,excel97,comobj,TlHelp32, jpeg;

type
  TForm1 = class(TForm)
    HOOKEGOMB: TBitBtn;
    POSTTABLA: TIBTable;
    POSTQUERY: TIBQuery;
    POSTDBASE: TIBDatabase;
    posttranz: TIBTransaction;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    VTABLA: TIBTable;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    Panel1: TPanel;
    takaro: TPanel;
    Label1: TLabel;
    Image1: TImage;
    Label2: TLabel;
    EXCELPANEL: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    EXPQUERY: TIBQuery;
    EXPDBASE: TIBDatabase;
    EXPTRANZ: TIBTransaction;

    procedure ExitGombClick(Sender: TObject);
    procedure MakePostTabla(_tnev: string);
    procedure PostParancs(_ukaz: string);
    procedure FormActivate(Sender: TObject);
    procedure HOOKEGOMBClick(Sender: TObject);
    procedure BankKodBeolvasas;
    procedure MakeExcel;
    procedure Keret(_rs: string; _wide: byte);
    procedure Keret2(_rs: string; _wide: byte);
  
    function Nulele(_b: byte): string;
    function VanPostTabla: boolean;
    function Ezertektar(_p: byte): boolean;
    procedure EvComboChange(Sender: TObject);
    procedure ExcelKill;
    function ScanBankKod(_bk: integer): byte;
    procedure NAPCOMBOChange(Sender: TObject);
    procedure AdatGyujtes;
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pcs,_evitem,_tablanev,_farok,_banks,_bf,_aktfdbpath,_datums,_naps: string;
  _pcsv,_nnev,_knev,_datealap,_rangestr,_aktdates,_formula: string;
  _savePath,_cBetu,_kertdatums,_aktsavefile,_aktdatums,_aktkft: string;
  _utbiz,_bizonylat: string;

  _cegnev,_cegkod,_cegjel,_saveFile: array[1..4] of string;
  _spnetto,_spkk: array[1..4] of integer;
  _voltadat: array[1..4] of boolean;
  _aktcegkod,_aktcegbetu,_das: string;

  _sorveg: string = chr(13)+chr(10);
  _evindex,_hoindex,_code,_netto,_kezdij,_xnetto,_xkk,_aktbankKod,_recno: integer;
  _aktspkk,_aktspnetto,_kerekites,_add: integer;

  _bankkod: array[1..170] of integer;
  _cegbetu: array[1..170] of string;
  _sNetto,_sKezdij: array[1..170,1..31] of integer;
  _napnetto,_napkk: array[1..31] of integer;

  _HONEV: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
           'MÁJUS','JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
           'NOVEMBER','DECEMBER');

  _kertev,_kertho,_aktev,_aktho,_uzlet,_pt,_snap,_adatsor,_lower,_cc,_pp: word;
  _aktnap,_kertnap,_utnap,_bankkoddarab: word;
  _xx,_ceg,_index: byte;

  _oxl,_owb: olevariant;

   proc   : PROCESSENTRY32;
  _handle : HWND;
  _Looper : BOOL;

implementation

{$R *.dfm}


// =============================================================================
                 procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var _y,_x: integer;

begin
  Takaro.Visible := false;
  ExcelPanel.Visible := False;

  for _y:= 1 to 170 do
    begin
      _cegbetu[_y] := 'X';
      for _x := 1 to 31 do
        begin
          _sNetto[_y,_x] := 0;
          _sKezdij[_y,_x]:= 0;
        end;
    end;

  for _x := 1 to 31 do
    begin
      _napnetto[_x] := 0;
      _napkk[_x] := 0;
    end;

  for _x := 1 to 4 do
    begin
      _voltadat[_x] := false;
      _spnetto[_x] := 0;
      _spkk[_x] := 0;
    end;

  Bankkodbeolvasas;

  _cegjel[1] := 'B';
  _cegnev[1] := 'BEST';
  _cegkod[1] := '107746';

  _cegjel[2] := 'E';
  _cegnev[2] := 'EAST';
  _cegkod[2] := 'A05RKS';

  _cegjel[3] := 'P';
  _cegnev[3] := 'PANNON';
  _cegkod[3] := 'A05SQX';

  _cegjel[4] := 'Z';
  _cegnev[4] := 'EXPRESSZ';
  _cegkod[4] := 'A0AYTS';

  evcombo.Items.clear;
  hocombo.items.clear;

  _aktev  := yearof(date);
  _aktho  := monthof(date);
  _aktnap := dayof(date);
  _kertnap:= _aktnap-1;
  _aktdatums := inttostr(_aktev)+'.'+nulele(_aktho)+'.'+nulele(_kertnap);

  _y := -2;
  while _y<1 do
    begin
      evcombo.Items.add(inttostr(_y+_aktev));
      inc(_y);
    end;
  evcombo.ItemIndex := 2;

  _y := 1;
  while _y<=12 do
    begin
      hocombo.items.add(_honev[_y]);
      inc(_y);
    end;
  Hocombo.itemindex := _aktho-1;
end;

// =============================================================================
                   procedure TForm1.BankKodBeolvasas;
// =============================================================================

var i: byte;
    _bkod: integer;

begin
  for i := 1 to 170 do _bankkod[i] := 0;

  recdbase.connected := true;
  _pcs := 'SELECT * FROM IRODAK' + _SORVEG;
  _pcs := _pcs + 'WHERE CLOSED='+chr(39)+'N'+chr(39)+_sorveg;
  _PCS := _PCS + 'ORDER BY UZLET';

  with Recquery do
    begin
      CLose;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _bankkodDarab := 0;
  while not Recquery.eof do
    begin
      _uzlet := RecQuery.fieldByNAme('UZLET').asInteger;
      _banks := trim(Recquery.FieldByNAme('BANKKOD').AsString);
      _cBetu := RecQuery.FieldByNAme('CEGBETU').asString;
      val(_banks,_bkod,_code);
      if _code<>0 then _bkod := 0;

      if _bkod>0 then
        begin
          _bankkod[_uzlet] := _bkod;
          _cegbetu[_uzlet] := _cBetu;
          inc(_bankkoddarab);
        end;
      Recquery.next;
    end;
  Recquery.close;
  recdbase.close;

  // ---------------------------------------------------------------

  EXPdbase.connected := true;
  _pcs := 'SELECT * FROM IRODAK' + _SORVEG;
  _pcs := _pcs + 'WHERE CLOSED='+chr(39)+'N'+chr(39)+_sorveg;
  _PCS := _PCS + 'ORDER BY UZLET';

  with EXPquery do
    begin
      CLose;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not EXPquery.eof do
    begin
      _uzlet := EXPQuery.fieldByNAme('UZLET').asInteger;
      _banks := trim(EXPquery.FieldByNAme('BANKKOD').AsString);
      _cBetu := 'Z';
      val(_banks,_bkod,_code);
      if _code<>0 then _bkod := 0;

      if _bkod>0 then
        begin
          _bankkod[_uzlet] := _bkod;
          _cegbetu[_uzlet] := _cBetu;
          inc(_bankkoddarab);
        end;
      EXPquery.next;
    end;
  EXPquery.close;
  EXPdbase.close;


end;


// =============================================================================
                   procedure TForm1.HOOKEGOMBClick(Sender: TObject);
// =============================================================================

var _volt: byte;

begin
  _kertho  := 1+ hocombo.itemindex;
  _evindex := evcombo.itemindex;
  _evitem  := evcombo.items[_evindex];

  val(_evitem,_kertev,_code);

  if _code<>0 then _kertev := 0;
  if _kertev=0 then
    begin
      ShowMessage('HIBÁS ÉV');
      exit;
    end;

  if (_kertev=_aktev) and (_kertho=_aktho) then
    begin
      _kertdatums := _aktdatums;
    end else
    begin
      _kertnap := daysinamonth(_kertev,_kertho);
      _kertdatums := inttostr(_kertev)+nulele(_kertho)+nulele(_kertnap);
    end;

  _das := leftstr(_kertdatums,4)+midstr(_kertdatums,6,2)+midstr(_kertdatums,9,2);

  // ---------------------------------------------------------------------------

  _ceg := 1;
  while _ceg<=4 do
    begin
      _aktcegkod := _cegkod[_ceg];
      _savefile[_ceg] := _aktcegkod + _das +'.XLS';
      {
      _savePath := 'c:\receptor\mail\posta\posterm\' + _saveFile;
      if fileExists(_savepath) then Sysutils.DeleteFile(_savePath);
      }
      inc(_ceg);
    end;

  _tablanev := 'P_'+inttostr(_kertev-2000)+'_'+nulele(_kertho);
  _farok    := inttostr(_kertev-2000)+nulele(_kertho);
  _bf := 'BF' + _farok;

  if VanPostTabla then
    begin
      _pcs := 'DELETE FROM ' + _TABLANEV;
      PostParancs(_pcs);
    end;

  Adatgyujtes;

  // ---------------------------------------------------------------------------

  _adatsor := 0;
  _pt := 1;
  while _pt<=170 do
    begin
      _aktCegBetu := _cegBetu[_pt];
      _aktBankKod := _bankkod[_pt];
      if _aktcegbetu='X' then
        begin
          inc(_pt);
          continue;
        end;

      _pcs := 'INSERT INTO '+_tablanev + ' (BANKKOD,CEGBETU';
      _pcsv := 'Values ('+ inttostr(_aktbankkod)+','+chr(39)+_aktCegbetu + chr(39);

      _snap := 1;
      _volt := 0;

      while _snap<=31 do
        begin
          _xnetto := _SNetto[_pt,_snap];
          _xkk := _sKezdij[_pt,_sNap];
          if _xNetto>0 then
            begin
              _volt := 1;

              _nnev := 'POSNETTO'+inttostr(_snap);
              _knev := 'POSKK' + inttostr(_snap);
              _pcs := _pcs + ',' + _nnev + ',' +_knev;
              _pcsv := _pcsv + ','+inttostr(_xNetto)+','+inttostr(_xkk);
            end;
          inc(_snap);
        end;

      if _volt>0 then
        begin
          MakePostTabla(_tablanev);
          _pcs := _pcs + ')'+_sorveg+_pcsv+')';
          inc(_adatsor);
          postparancs(_pcs);
        end;
      inc(_pt);
    end;

  _ceg := 1;
  while _ceg<=4 do
    begin
      _aktkft := _cegnev[_ceg];
      _aktSaveFile := _saveFile[_ceg];
      _aktcegbetu  := _cegjel[_ceg];
      _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
      _pcs := _pcs + 'WHERE CEGBETU=' + chr(39)+_aktcegbetu+chr(39);
      _aktspnetto := _spnetto[_ceg];
      _aktspkk := _spkk[_ceg];

      Postdbase.Connected := True;
      with PostQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          Last;
          _recno := recno;
          First;
        end;

      if _recno>0 then
        begin
          _lower := _recno+7;
          MakeExcel;
        end;

      Postquery.close;
      Postdbase.close;
      inc(_ceg);
    end;

  ExcelKill;
  Takaro.Visible := True;
  Takaro.repaint;
  sleep(3500);
  Application.Terminate;
end;



// =============================================================================
                function TForm1.Ezertektar(_p: byte): boolean;
// =============================================================================

begin
  result := False;
  if (_p=10) or (_p=20) or (_p=40) or (_p=50) or (_p=63) then
    begin
      result := True;
      exit;
    end;

  if (_p=85) or (_p=120) or (_p=145) then
    begin
      result := True;
      exit;
    end;
end;


// =============================================================================
                        procedure TForm1.MakeExcel;
// =============================================================================


var _lows,_nMezo,_kMezo,_lastds,_betu,_foc,_rangestring: string;
    _bKod,_pnetto,_pkk,_oszlop,_sn,_sk: integer;
  
begin

  _LOWS := inttostr(_lower);
  _lastds := inttostr(_lower-1);

  _datealap := inttostr(_kertev)+'.'+nulele(_kertho)+'.';
  _utnap :=daysinamonth(_kertev,_kertho);

  ExcelPanel.Visible := True;
  ExcelPanel.repaint;

   _oxl := CreateOleObject('Excel.Application');
   _owb := _oxl.workbooks.add[1];

   // ---  A 2 fül létrehozása és elnevezése -----------------------------------

   _oxl.workbooks[1].sheets.add(,,2);
   _oxl.workbooks[1].worksheets[2].name := 'ÜZLETENKÉNT';
   _oxl.workbooks[1].worksheets[1].name := 'ÖSSZESEN';


   // ------------------ 1. FEJLEC ---------------------------------------------

   _rangestr := 'C5:BP'+inttostr(_lower);
   _oxl.worksheets[2].range[_rangestr].Columnwidth := 12;
   Keret(_rangestr,4);

   _rangestr := 'C5:BP6';
   Keret(_rangestr,4);

   _rangestr := 'C'+inttostr(_lower)+':BP'+inttostr(_lower);
   Keret(_rangestr,4);

   _rangestr := 'C5:C' + _lows;
   Keret(_rangestr,4);

   // --------------------------------------------------------------------------

   _cc := 0;
   while _cc<21 do
     begin
       _rangestr := chr(69+_cc)+'5:'+chr(70+_cc)+'5';
       _oxl.worksheets[2].range[_rangestr].mergecells := True;
       _cc := _cc+2;
     end;

   _cc := 0;
   while _cc<26 do
     begin
       _rangestr := 'A'+chr(65+_CC)+'5:A'+chr(66+_CC)+'5';
       _oxl.worksheets[2].range[_rangestr].mergecells := True;
       _cc := _cc+2;
     end;

   _cc := 0;
   while _cc<15 do
     begin
       _rangestr := 'B'+chr(65+_CC)+'5:B'+chr(66+_CC)+'5';
       _oxl.worksheets[2].range[_rangestr].mergecells := True;
       _cc := _cc+2;
     end;

   // --------------------------------------------------------------------------

   _cc := 5;
   _aktnap := 1;
   while _cc<=67 do
     begin
       if _aktnap<=_utnap THEN
         begin
           _aktdates := _dateAlap + nulele(_aktnap);
           _oxl.worksheets[2].Cells[5,_cc] := _aktdates;
           _oxl.worksheets[2].Cells[6,_cc] := 'POS NETTÓ';
           _oxl.worksheets[2].Cells[6,_cc+1] := 'POS KK';
         end;
       inc(_aktnap);
       _cc := _cc + 2;
     end;

   // --------------------------------------------------------------------------

   _rangestr := 'C5:BP'+inttostr(_lower);
   _oxl.worksheets[2].Range[_rangestr].HorizontalAlignment := -4108;

   _rangestr := 'C5:BP5';
   _oxl.worksheets[2].Range[_rangestr].Font.size := 11;
   _oxl.worksheets[2].Range[_rangestr].Font.Bold := True;
   _oxl.worksheets[2].Range[_rangestr].Font.Italic := True;

   _rangestr := 'C6:BP'+inttostr(_lower-1);
   _oxl.worksheets[2].Range[_rangestr].NumberFormat := '### ### ###';
   _oxl.worksheets[2].Range[_rangestr].Font.size := 10;
   _oxl.worksheets[2].Range[_rangestr].Font.Bold := False;
   _oxl.worksheets[2].Range[_rangestr].Font.Italic := False;

   _rangestr := 'C5:D6';
   _oxl.worksheets[2].Range[_rangestr].Mergecells := true;
   _oxl.worksheets[2].Range[_rangestr].Font.size := 11;
   _oxl.worksheets[2].Range[_rangestr].vERTICALaLIGNMENT := -4108;
   _oxl.worksheets[2].Range[_rangestr].Font.bold := True;
   _oxl.worksheets[2].Range[_rangestr].Font.Italic := True;
   _oxl.worksheets[2].Range[_rangestr].wrapText := True;

   _oxl.worksheets[2].Range['C7:D'+_LOWS].Font.bold := true;
   _oxl.worksheets[2].Cells[5,3] := 'PTÁR SZÁM + BANKKÓD';

   _oxl.worksheets[2].cells[5,67] := 'ÖSSZESEN';
   _oxl.worksheets[2].cells[6,67] := 'POS NETTÓ';
   _oxl.worksheets[2].cells[6,68] := 'POS KK';

   Keret('E5:F'+_LOWS,4);
   Keret('G5:H'+_LOWS,4);
   Keret('K5:L'+_LOWS,4);
   Keret('O5:P'+_LOWS,4);
   Keret('S5:T'+_LOWS,4);
   Keret('W5:X'+_LOWS,4);
   Keret('AA5:AB'+_LOWS,4);
   Keret('AE5:AF'+_LOWS,4);
   Keret('AI5:AJ'+_LOWS,4);
   Keret('AM5:AN'+_LOWS,4);
   Keret('AQ5:AR'+_LOWS,4);
   Keret('AU5:AV'+_LOWS,4);
   Keret('AY5:AZ'+_LOWS,4);
   Keret('BC5:BD'+_LOWS,4);
   Keret('BG5:BH'+_LOWS,4);
   Keret('BK5:BL'+_LOWS,4);
   Keret('BM5:BN'+_LOWS,4);

   // ------------------------- ADATFELTÖLTÉS ----------------------------------
   {
   _pcs := 'SELECT * FROM '+ _tablanev + _sorveg;
   _pcs := _pcs + 'ORDER BY BANKKOD';

   Postdbase.Connected := true;
   with PostQuery do
     begin
       Close;
       sql.clear;
       sql.Add(_pcs);
       Open;
       First;
     end;
   }


   _adatsor := 7;
   while not Postquery.eof do
     begin
       _sn := 0;
       _sk := 0;
       _aktnap := 1;
       _bkod := Postquery.FieldByName('BANKKOD').asInteger;
       _xx := scanBankkod(_bkod);
       _oxl.worksheets[2].Cells[_adatsor,3] := inttostr(_xx);
       _oxl.worksheets[2].Cells[_adatsor,4] := _bkod;
       while _aktnap<=_utnap do
         begin
           _nMezo := 'POSNETTO'+inttostr(_aktnap);
           _kMezo := 'POSKK' + inttostr(_aktnap);
           _pnetto := PostQuery.FieldByname(_nmezo).asInteger;
           _pkk := PostQuery.FieldByname(_kmezo).asInteger;
           if _pnetto>0 then
             begin
               _sn := _sn + _pnetto;
               _sk := _sk + _pkk;
               _oszlop := 3+trunc(2*_aktnap);
               _oxl.worksheets[2].cells[_adatsor,_oszlop] := _pNetto;
               _oxl.worksheets[2].cells[_adatsor,_oszlop+1] := _pkk;
             end;
           inc(_aktnap);
         end;
     
       _oxl.worksheets[2].cells[_adatsor,67] := _sn;
       _oxl.worksheets[2].cells[_adatsor,68] := _sk;

       inc(_adatsor);
       Postquery.next;
     end;
   PostQuery.close;
   Postdbase.close;

   // --------------------------------------------------------------------------

   _oxl.worksheets[2].range['C3:K3'].MergeCells := True;
   _oxl.worksheets[2].range['C3:K3'].Font.size := 12;
   _oxl.worksheets[2].range['C3:K3'].Font.Bold := True;
   _oxl.worksheets[2].range['C3:K3'].Font.Italic := True;

   _foc := inttostr(_kertev)+' '+_honev[_kertho]+' HAVI POS-TERMINAL TRANZAKCIÓK (EXCLUSIVE '+_AKTKFT + ' CHANGE KFT)';
   if _aktkft='EXPRESSZ' then
      _foc := inttostr(_kertev)+' '+_honev[_kertho]+' HAVI POS-TERMINAL TRANZAKCIÓK (EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT)';
  
   _oxl.worksheets[2].Cells[3,3] := _FOC;

   _oxl.worksheets[2].range['C'+_lows+':BP'+_lows].font.bold := True;
   _oxl.worksheets[2].range['C'+_lows+':D'+_lows].mergecells := true;
   _oxl.worksheets[2].cells[_lower,3] := 'ÖSSZESEN';

   _cc := 0;
   while _cc<22 do  //E - Z
     begin
       _betu := chr(69+_cc);     // E
       _formula := '=SUM('+_betu+'7:'+_betu+_lastds+')';
       _oxl.worksheets[2].cells[_lower,_cc+5].Formula := _formula;
       inc(_cc)
     end;

   _cc := 0;
   while _cc<=25 do  // AA - AZ
     begin
       _betu := chr(_cc+65);
       _formula := '=SUM(A'+_betu+'7:A'+_betu+_lastds+')';
       _oxl.worksheets[2].cells[_lower,_cc+27].Formula := _formula;
       inc(_cc)
     end;

   _cc := 0;
   while _cc<16 do  // BA -
     begin
       _betu := chr(_cc+65);
       _formula := '=SUM(B'+_betu+'7:B'+_betu+_lastds+')';
       _oxl.worksheets[2].cells[_lower,_cc+53].Formula := _formula;
       inc(_cc)
     end;

  // ----------------- ÖSSZESEN FÜL --------------------------------------------

   _rangestring := 'A1:C1';
   _oxl.worksheets[1].range[_rangestring].MergeCells  := True;
   _oxl.worksheets[1].range[_rangestring].Font.size   := 12;
   _oxl.worksheets[1].range[_rangestring].Font.Bold   := True;
   _oxl.worksheets[1].range[_rangestring].Font.Italic := True;
   _oxl.worksheets[1].range[_rangestring].columnwidth := 25;

   _foc := inttostr(_kertev)+' '+_honev[_kertho]+' '+INTTOSTR(_kertnap)+'-I POS-TERMINAL TRANZAKCIÓK';
   _oxl.worksheets[1].Cells[1,1] := _FOC;

   _rangestring := 'A3:B4';
   _oxl.worksheets[1].range[_rangestring].font.size   := 12;
   _oxl.worksheets[1].range[_rangestring].font.Bold   := True;
   _oxl.worksheets[1].range[_rangestring].font.Italic := True;
   _oxl.worksheets[1].range[_rangestring].HorizontalAlignment := -4108;

   _rangestring := 'B3:B4';
   _oxl.worksheets[1].range[_rangestring].Numberformat := '### ### ###';

   _oxl.worksheets[1].cells[3,1] := 'POS NETTÓ';
   _oxl.worksheets[1].cells[4,1] := 'POS KK';

   _oxl.worksheets[1].cells[3,2] := _aktspnetto;
   _oxl.worksheets[1].cells[4,2] := _aktspkk;

   _rangestring := 'A3:A4';
   Keret2(_rangestring,2);

   _rangestring := 'A3:B4';
   Keret2(_rangestring,4);

 //  _aktnetto := _napnetto[_kertnap];
 //  _aktkk  := _napkk[_kertnap];

   _savePath := 'c:\receptor\mail\posta\posterm\' + _aktsaveFile;
   if fileExists(_savepath) then Sysutils.DeleteFile(_savePath);

   _owb.saveas(_savePath);
   _oxl.Quit;
   _oxl := Unassigned;
   _owb := Unassigned;
end;

// =============================================================================
                     function TForm1.VanPostTabla: boolean;
// =============================================================================

begin
  PostDbase.connected := true;
  postTabla.close;
  PostTabla.Tablename := _tablanev;
  result :=  PostTABLA.Exists;

  PostDbase.close;

end;

// =============================================================================
             procedure TForm1.Keret(_rs: string; _wide: byte);
// =============================================================================

begin
  _oxl.worksheets[2].range[_rs].Borderaround(1,_wide);
end;

// =============================================================================
            procedure TForm1.Keret2(_rs: string; _wide: byte);
// =============================================================================

begin
  _oxl.worksheets[1].range[_rs].Borderaround(1,_wide);
end;


// =============================================================================
             procedure TForm1.EVCOMBOChange(Sender: TObject);
// =============================================================================

begin
  _kertev := (_aktev-2)+evcombo.ItemIndex;
  _kertho := 1 + hocombo.itemindex;

  aCTIVECONTROL := HoOkegomb;
end;

// =============================================================================
                  procedure TForm1.ExcelKill;
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

// =============================================================================
               function TForm1.ScanBankKod(_bk: integer): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=150 do
    begin
      if _bankkod[_y]= _bk then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
            procedure TForm1.NAPCOMBOChange(Sender: TObject);
// =============================================================================

begin
  aCTIVEcONTROL := HoOkeGomb;
end;


// =============================================================================
                       procedure TForm1.Adatgyujtes;
// =============================================================================




begin
  _pt := 3;
  while _pt<=150 do
    begin
      if Ezertektar(_pt) then
        begin
          inc(_pt);
          continue;
        end;

      _aktfdbPath := 'c:\receptor\database\v' + inttostr(_pt)+'.fdb';
      if not FileExists(_aktfdbpath) then
        begin
          inc(_pt);
          continue;
        end;

      vDbase.close;
      vdbase.DatabaseName := _aktfdbpath;
      vdbase.connected := true;

      vtabla.close;
      vTabla.TableName := _bf;

      if not vtabla.Exists then
        begin
          vdbase.close;
          INC(_PT);
          Continue;
        end;

      // ----------- ITT ÉRVÉNYES PÉNZTÁR VAN ----------------------------------

      Panel1.Caption := inttostr(_pt);
      Panel1.Repaint;

      _pcs := 'SELECT * FROM '+ _bf + _sorveg;
      _pcs := _pcs + 'WHERE (FIZETOESZKOZ=2) AND (STORNO=1)';

      with Vquery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Open;
          First;
        end;

      _utbiz := 'xxxx';
      while not VQuery.Eof do
        begin
          _netto := Vquery.FieldByName('OSSZESEN').asInteger;
          _kezdij:= Vquery.FieldByNAme('KEZELESIDIJ').asInteger;
          _datums:= Vquery.FieldByNAme('DATUM').asString;
          _kerekites := Vquery.FieldByName('KEREKITES').asInteger;
          _bizonylat := trim(Vquery.FieldbyNAme('BIZONYLATSZAM').AsString);

          _naps := midstr(_datums,9,2);
          Val(_naps,_snap,_code);
          if _code<>0 then _snap := 0;

          if _snap>0 then
            begin
              _add := _netto;
              if _utbiz<>_bizonylat then _add := _add + _kerekites;
              _snetto[_pt,_sNap]  := _snetto[_pt,_sNap] + _add;
              _skezdij[_pt,_sNap] := _sKezdij[_pt,_sNap] + abs(_kezdij);
              _AKTCEGBETU := _cegbetu[_pt];

              if _aktcegbetu='B' then _index := 1;
              if _aktcegbetu='E' then _index := 2;
              if _aktcegbetu='P' then _index := 3;

              if _snap=_kertnap then
                begin
                  _spnetto[_index] := _spnetto[_index] + _add;
                  _spkk[_index] := _spkk[_index] + abs(_kezdij);
                end;

              _napnetto[_sNap]    := _napnetto[_sNap] + _add;
              _napkk[_sNap]       := _napkk[_snap] + abs(_kezdij);
            end;

          _utbiz := _bizonylat;
          vQuery.next;
        end;
      Vquery.Close;
      Vdbase.close;

      inc(_pt);
    end;


  // -----------------------------------------------------------------

  while _pt<=170 do
    begin

      _aktfdbPath := 'c:\cartcash\database\v' + inttostr(_pt)+'.fdb';
      if not FileExists(_aktfdbpath) then
        begin
          inc(_pt);
          continue;
        end;

      vDbase.close;
      vdbase.DatabaseName := _aktfdbpath;
      vdbase.connected := true;

      vtabla.close;
      vTabla.TableName := _bf;

      if not vtabla.Exists then
        begin
          vdbase.close;
          INC(_PT);
          Continue;
        end;

      // ----------- ITT ÉRVÉNYES PÉNZTÁR VAN ----------------------------------

      Panel1.Caption := inttostr(_pt);
      Panel1.Repaint;

      _pcs := 'SELECT * FROM '+ _bf + _sorveg;
      _pcs := _pcs + 'WHERE (FIZETOESZKOZ=2) AND (STORNO=1)';

      with Vquery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Open;
          First;
        end;

      _utbiz := 'xxxx';
      while not VQuery.Eof do
        begin
          _netto := Vquery.FieldByName('OSSZESEN').asInteger;
          _kezdij:= Vquery.FieldByNAme('KEZELESIDIJ').asInteger;
          _datums:= Vquery.FieldByNAme('DATUM').asString;
          _kerekites := Vquery.FieldByName('KEREKITES').asInteger;
          _bizonylat := trim(Vquery.FieldbyNAme('BIZONYLATSZAM').AsString);

          _naps := midstr(_datums,9,2);
          Val(_naps,_snap,_code);
          if _code<>0 then _snap := 0;

          if _snap>0 then
            begin
              _add := _netto;
              if _utbiz<>_bizonylat then _add := _add + _kerekites;
              _snetto[_pt,_sNap]  := _snetto[_pt,_sNap] + _add;
              _skezdij[_pt,_sNap] := _sKezdij[_pt,_sNap] + abs(_kezdij);
              _AKTCEGBETU := _cegbetu[_pt];

              if _aktcegbetu='B' then _index := 1;
              if _aktcegbetu='E' then _index := 2;
              if _aktcegbetu='P' then _index := 3;
              If _aktcegbetu='Z' then _index := 4;

              if _snap=_kertnap then
                begin
                  _spnetto[_index] := _spnetto[_index] + _add;
                  _spkk[_index] := _spkk[_index] + abs(_kezdij);
                end;

              _napnetto[_sNap]    := _napnetto[_sNap] + _add;
              _napkk[_sNap]       := _napkk[_snap] + abs(_kezdij);
            end;

          _utbiz := _bizonylat;
          vQuery.next;
        end;
      Vquery.Close;
      Vdbase.close;

      inc(_pt);
    end;
end;

// =============================================================================
                 procedure TForm1.PostParancs(_ukaz: string);
// =============================================================================

begin
  postdbase.connected := true;
  if PostTranz.InTransaction then PostTranz.commit;
  PostTranz.StartTransaction;
  with PostQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  PostTranz.commit;
  Postdbase.close;
end;

// =============================================================================
                procedure TForm1.MakePostTabla(_tnev: string);
// =============================================================================

var _acs: string;

begin
  if VanPostTabla then exit;

  _acs := 'CREATE TABLE ' + _tnev + ' (';
  _acs := _acs + 'BANKKOD INTEGER,';
  _acs := _acs + 'POSNETTO1 INTEGER,';
  _acs := _acs + 'POSKK1 INTEGER,';
  _acs := _acs + 'POSNETTO2 INTEGER,';
  _acs := _acs + 'POSKK2 INTEGER,';
  _acs := _acs + 'POSNETTO3 INTEGER,';
  _acs := _acs + 'POSKK3 INTEGER,';
  _acs := _acs + 'POSNETTO4 INTEGER,';
  _acs := _acs + 'POSKK4 INTEGER,';
  _acs := _acs + 'POSNETTO5 INTEGER,';
  _acs := _acs + 'POSKK5 INTEGER,';
  _acs := _acs + 'POSNETTO6 INTEGER,';
  _acs := _acs + 'POSKK6 INTEGER,';
  _acs := _acs + 'POSNETTO7 INTEGER,';
  _acs := _acs + 'POSKK7 INTEGER,';
  _acs := _acs + 'POSNETTO8 INTEGER,';
  _acs := _acs + 'POSKK8 INTEGER,';
  _acs := _acs + 'POSNETTO9 INTEGER,';
  _acs := _acs + 'POSKK9 INTEGER,';
  _acs := _acs + 'POSNETTO10 INTEGER,';
  _acs := _acs + 'POSKK10 INTEGER,';
  _acs := _acs + 'POSNETTO11 INTEGER,';
  _acs := _acs + 'POSKK11 INTEGER,';
  _acs := _acs + 'POSNETTO12 INTEGER,';
  _acs := _acs + 'POSKK12 INTEGER,';
  _acs := _acs + 'POSNETTO13 INTEGER,';
  _acs := _acs + 'POSKK13 INTEGER,';
  _acs := _acs + 'POSNETTO14 INTEGER,';
  _acs := _acs + 'POSKK14 INTEGER,';
  _acs := _acs + 'POSNETTO15 INTEGER,';
  _acs := _acs + 'POSKK15 INTEGER,';
  _acs := _acs + 'POSNETTO16 INTEGER,';
  _acs := _acs + 'POSKK16 INTEGER,';
  _acs := _acs + 'POSNETTO17 INTEGER,';
  _acs := _acs + 'POSKK17 INTEGER,';
  _acs := _acs + 'POSNETTO18 INTEGER,';
  _acs := _acs + 'POSKK18 INTEGER,';
  _acs := _acs + 'POSNETTO19 INTEGER,';
  _acs := _acs + 'POSKK19 INTEGER,';
  _acs := _acs + 'POSNETTO20 INTEGER,';
  _acs := _acs + 'POSKK20 INTEGER,';
  _acs := _acs + 'POSNETTO21 INTEGER,';
  _acs := _acs + 'POSKK21 INTEGER,';
  _acs := _acs + 'POSNETTO22 INTEGER,';
  _acs := _acs + 'POSKK22 INTEGER,';
  _acs := _acs + 'POSNETTO23 INTEGER,';
  _acs := _acs + 'POSKK23 INTEGER,';
  _acs := _acs + 'POSNETTO24 INTEGER,';
  _acs := _acs + 'POSKK24 INTEGER,';
  _acs := _acs + 'POSNETTO25 INTEGER,';
  _acs := _acs + 'POSKK25 INTEGER,';
  _acs := _acs + 'POSNETTO26 INTEGER,';
  _acs := _acs + 'POSKK26 INTEGER,';
  _acs := _acs + 'POSNETTO27 INTEGER,';
  _acs := _acs + 'POSKK27 INTEGER,';
  _acs := _acs + 'POSNETTO28 INTEGER,';
  _acs := _acs + 'POSKK28 INTEGER,';
  _acs := _acs + 'POSNETTO29 INTEGER,';
  _acs := _acs + 'POSKK29 INTEGER,';
  _acs := _acs + 'POSNETTO30 INTEGER,';
  _acs := _acs + 'POSKK30 INTEGER,';
  _acs := _acs + 'POSNETTO31 INTEGER,';
  _acs := _acs + 'POSKK31 INTEGER,';
  _acs := _acs + 'BETUJEL CHAR (1))';
  Postparancs(_acs);
end;

// =============================================================================
                  function TForm1.Nulele(_b: byte):string;
// =============================================================================


begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
            procedure TForm1.EXITGOMBClick(Sender: TObject);
// =============================================================================

begin
  ExcelKill;
  Application.Terminate;
end;


end.
