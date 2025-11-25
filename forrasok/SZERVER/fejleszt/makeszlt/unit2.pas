unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, unit1, StdCtrls, ExtCtrls, strutils;

type
  TACEXCELTABLA = class(TForm)
    Label1: TLabel;
    KILEPO: TTimer;
    procedure FormActivate(Sender: TObject);
  //  procedure AcExcelFejlec;
 //   procedure KILEPOTimer(Sender: TObject);
  //  procedure adatfeltoltes;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ACEXCELTABLA: TACEXCELTABLA;
  _lastletter,_formula,_obetu,_b: string;
  _oszlopdarab,_valindex: byte;



implementation

{$R *.dfm}


procedure TACEXCELTABLA.FormActivate(Sender: TObject);
begin
  Visible := false;
  Top := _top + 370;
  Left := _left +230;
  AcExceltabla.Repaint;
  Visible := true;

 // AcExcelFejlec;
//  Adatfeltoltes;
  Kilepo.enabled := true;
end;


{
// =============================================================================
                      procedure TAcExcelTabla.AcExcelFejlec;
// =============================================================================


begin
   // Hány oszlop kell a körzet táblájában:

  _oszlopDarab := 4+trunc(2*_acPkFileDarab); // 2 valutanem + 2*irodak + 2*összesen
  _lastLetter := Form1.GetOszlopBetu(_oszlopDarab); // ez az utolsó oszlop betüjele

  _oxl.workSheets[10].Range['A1:A1'].columnWidth := 5;
  _oxl.worksheets[10].Range['B1:B1'].columnWidth := 18;
  _rangestr := 'C1:' + _lastletter +'1';
  _oxl.worksheets[10].Range[_rangestr].columnWidth := 15;


  // A fejléc összes betüje Times New Roman, bold, Italic, 12-es közepre;

  _rangestr := 'A2:' + _lastletter + '7';
  Form1.rangefontKeszlet(_rangestr,'Times New Roman',12,True,True);
  Form1.RangeKozepre(_rangestr);

  // A legfelsõ magyarázó fõcimsor beállitása:

  _rangestr := 'A2:' + _lastletter + '2';
  _oxl.worksheets[10].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[10].Range[_rangestr].Font.Size   := 16;

  _text := 'ART-CASH KFT KÉSZLETEI ÉS FORGALMA';
  _oxl.worksheets[10].cells[2,1] := _text;

  //----------------------------------------------------------------------------

  // Valutanemek box:

  _rangestr := 'A4:B5';
  _oxl.worksheets[10].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[10].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[10].Cells[4,1] := 'VALUTANEMEK';

  // Dátumbox

  _rangestr := 'A6:B6';
  _oxl.worksheets[10].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[10].Cells[6,1] := 'DÁTUM';

  // Idõbox:

  _rangestr := 'A7:B7';
  _oxl.worksheets[10].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[10].Cells[7,1] := 'IDÕ';

  // ---------------------------------------------------------------------------

  // Az egységek ossulopainak kialakitása: körzetenként

  Form1.Fastcsik.Max := _ACPkFileDarab;

  _pkindex := 1;
  while _pkindex<=_acPkFileDarab do
    begin
      // Az elsõ a 3-ik oszlop: (majd 5,7 stb)

      Form1.Fastcsik.Position := _pkIndex;
      _aktoszlop := 1 + trunc(2*_pkindex);

      // A következö pénztárszám:  ELSÕ RANGE= 'C4:B4'

      // Az összenyitott két cellába az egység neve kerül: (pl: Nyiregyháza TESCO)

      _rangestr := Form1.getoszlopbetu(_aktoszlop) + '4:' + Form1.getoszlopbetu(_aktoszlop+1) + '4';
      _oxl.worksheets[10].Range[_rangestr].Mergecells := True;

      _irodanum := _Acirodasor[_pkindex];
      _acirodaindex := Form1.Scaniroda(_irodanum);
      _text := _acirodanev[_acirodaindex];

      // ------------------Egység neve, és a 2 oszlop neve ---------------------

      _oxl.worksheets[10].Cells[4,_aktoszlop]   := _text;
      _oxl.worksheets[10].Cells[5,_aktoszlop]   := 'KÉSZLET';
      _oxl.worksheets[10].Cells[5,_aktoszlop+1] := 'ÉRTÉK (Ft)';

      // ------------- Elsö range = 'C6:D6' Beirja az aktuális dûtumot ---------

      _rangestr := Form1.getoszlopbetu(_aktoszlop) + '6:' + Form1.getoszlopbetu(_aktoszlop+1) + '6';
      _oxl.worksheets[10].Range[_rangestr].Mergecells := True;
      _oxl.worksheets[10].Cells[6,_aktoszlop] := _acDatum[_pkIndex];

      // ----------- Elsö range = 'C7:D7' -- Beirja az aktuális idöt -----------

      _rangestr := Form1.getoszlopbetu(_aktoszlop) + '7:' + Form1.getoszlopbetu(_aktoszlop+1) + '7';
      _oxl.worksheets[10].Range[_rangestr].Mergecells := True;
      _oxl.worksheets[10].Cells[7,_aktoszlop] := _acIdo[_pkIndex];

      //  Jöhet a következö egység oszlopa -------------------------------------

      inc(_pkIndex);
    end;

  // ---------------------------------------------------------------------------

  // Az összesen oszlop kialakitása:

  _rangestr := Form1.getoszlopbetu(_oszlopDarab-1)+'4:' + Form1.getoszlopBetu(_oszlopdarab)+'7';
  _oxl.worksheets[10].range[_rangestr].VerticalAlignment := -4108;

  // Az ÖSSZESEN felirat 4 összenyitott cellába kerül:

  _rangestr := Form1.getoszlopbetu(_oszlopDarab-1)+'4:'+Form1.getoszlopbetu(_oszlopdarab)+'5';
  _oxl.worksheets[10].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[10].Cells[4,_oszlopDarab-1] := 'ÖSSZESEN';

  // Két-két cella összenyitva a KÉSZLET és ÉRTÉK (Ft) beirásának:

  _rangestr := Form1.getoszlopbetu(_oszlopDarab-1)+'6:'+Form1.getoszlopbetu(_oszlopdarab-1)+'7';
  _oxl.worksheets[10].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[10].Cells[6,_oszlopDarab-1] := 'KÉSZLET';

  _rangestr := Form1.getoszlopbetu(_oszlopDarab)+'6:'+Form1.getoszlopbetu(_oszlopdarab)+'7';
  _oxl.worksheets[10].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[10].Cells[6,_oszlopDarab] := 'ÉRTÉK (Ft)';

  // ------------------- OLDAL FEJLÉC (Valutanemek) ----------------------------

  //  A valutanemek és valutanevek beirása az 1 és 2-ik oszopba
  // a 8-tól a 30-ig sorig:

  _valutaIndex := 1;
  while _valutaIndex<=2 do
    begin
      _oxl.worksheets[10].Cells[7+_valutaindex,1] := _valutanemek[_valutaIndex];
      _oxl.worksheets[10].Cells[7+_valutaIndex,2] := _acvalutaNevek[_valutaIndex];
      inc(_valutaIndex);
    end;

  // A valutanemek oszlop-betüjének beállitása:

  _rangestr := 'A8:A16';
  Form1.RangeFontKeszlet(_rangestr,'Arial',10,True,False);
  Form1.RangeKozepre(_rangestr);

  // A valutanevek oszlop-betüjének beállitása

  _rangestr := 'B8:B13';
  Form1.RangeFontKeszlet(_rangestr,'Arial',10,False,False);

  // Az ÖSSZESEN felirat részére 2 cella összenyitva:

  _oxl.worksheets[10].range['A14:B14'].mergeCells := True;
  _oxl.worksheets[10].range['A14:B14'].HorizontalAlignment := -4108;
  _oxl.worksheets[10].Cells[14,1] := 'ÖSSZESEN';

  _rangestr := 'C8:' + _lastletter + '19';
  _oxl.worksheets[10].range[_rangestr].NumberFormat := '### ### ###';


  //  Az ÖSSZESEN sor bankjegy-érték cellák összenyitása, mert csk érték van itt

  _xoszlop := 3;
  while _xoszlop<_oszlopDarab do
    begin
      _rangestr := Form1.getOszlopBetu(_xoszlop)+'17:'+Form1.getoszlopBetu(_xoszlop+1)+'14';
      _oxl.worksheets[10].range[_rangestr].MergeCells := true;
      _oxl.worksheets[10].range[_rangestr].HorizontalAlignment := -4108;
      _oxl.worksheets[10].range[_rangestr].Font.Bold := True;
      _oxl.worksheets[10].range[_rangestr].Font.Italic := True;
      _oxl.worksheets[10].range[_rangestr].Font.Size := 12;

      _oBetu := Form1.getoszlopbetu(_xoszlop+1);
      _formula := '=SUM('+ _obetu+'8:'+_obetu+'16)';
      _oxl.worksheets[10].Cells[17,_xoszlop].formula := _formula;

      _xoszlop := _xoszlop + 2;
    end;




  // --------- Az egyéb (WU,afa,kezdij,eker,foglalo) készletei -----------------

  _rangestr := 'A20:B23';
  Form1.RangeFontKeszlet(_rangestr,'Times New Roman',11,False,True);
  _oxl.worksheets[10].range[_rangestr].HorizontalAlignment := -4108;

  _xsor := 20;
  while _xsor<=23 do
    begin
      _xoszlop := 1;
      while _xOszlop<_oszlopdarab do
        begin
          _rangestr := Form1.getoszlopBetu(_xoszlop)+inttostr(_xsor)+':'+Form1.getoszlopbetu(_xOszlop+1)+inttostr(_xsor);
          _oxl.workSheets[10].range[_rangestr].Mergecells := True;
          _oxl.worksheets[10].range[_rangestr].HorizontalAlignment := -4108;
          _oxl.worksheets[10].range[_rangestr].Numberformat := '### ### ###';
          _xoszlop := _xoszlop + 2;
        end;
      inc(_xsor);
    end;

  // Az egyéb készletek betütipusának beállitása:

  _rangestr := 'C20:' + Form1.getOszlopbetu(_oszlopdarab)+'23';
  Form1.RangeFontkeszlet(_rangestr,'Times New Roman',11,False,True);

  _oxl.worksheets[10].Cells[20,1] := 'WESTERN UNION (USD)';
  _oxl.worksheets[10].Cells[21,1] := 'WESTERN UNION (HUF)';
  _oxl.worksheets[10].Cells[22,1] := 'KEZELÉSI DÍJ';
  _oxl.worksheets[10].Cells[23,1] := 'FOGLALÓK';

  // ---------------------------------------------------------------------------

  // A NAPI FORGALOM sorának beállitása

  _Rangestr := 'A27:'+ Form1.getoszlopbetu(_oszlopdarab)+'27';
  Form1.RangeFontkeszlet(_rangestr,'Times New Roman',12,True,True);
  Form1.RangeKozepre(_rangestr);
  _oxl.worksheets[10].range['A27:B27'].mergecells := True;
  _oxl.worksheets[10].cells[27,1] := 'NAPI FORGALOM';

  // A forgalom sor fejlécének fejlécneveinek beirása:

  _xOszlop := 3;
  while _xOszlop<_oszlopdarab do
    begin
      _oxl.worksheets[10].cells[27,_xoszlop] := 'VÉTEL';
      _oxl.worksheets[10].cells[27,_xoszlop+1] := 'ELADÁS';
      _xOszlop := _xOszlop + 2;
    end;

  // --------- A forgalom  valutanemenként ------------------------------

  _xsor := 29;
  _valutaindex := 1;
  Form1.FAstcsik.Max := 9;

  while _valutaIndex<=9 do
    begin

      // Beirja a valutanemeket és valutaneveket:

      Form1.Fastcsik.Position := _valutaIndex;
      _oxl.worksheets[10].cells[_xsor,1] := _acvalutanemek[_valutaIndex];
      _oxl.worksheets[10].cells[_xsor,2] := _acvalutanevek[_valutaIndex];

      // Két-két cellát egymás alatt összenyit a valuta-nemeknek és neveknek:

      _rangestr := 'A'+inttostr(_xsor)+':A'+inttostr(_xsor+1);
      _oxl.worksheets[10].range[_rangestr].mergecells := true;

      _rangestr := 'B'+inttostr(_xsor)+':B'+inttostr(_xsor+1);
      _oxl.worksheets[10].range[_rangestr].mergecells := true;

      _xsor := _xsor + 2;
      inc(_valutaIndex);
    end;

  // A valutanemek betütipusai és elrendezése:
  _rangestr := 'A29:A45';
  Form1.RangeFontkeszlet(_rangestr,'Arial',10,True,False);
  Form1.RangeKozepre(_rangestr);
  _oxl.worksheets[10].range[_rangestr].VerticalAlignment := -4108;

  // A valutanevek betütipusai és elrendezése:

  _rangestr := 'B29:B45';
  Form1.RangeFontkeszlet(_rangestr,'Arial',10,False,False);
  _oxl.worksheets[10].range[_rangestr].VerticalAlignment := -4108;

  // A legalsó ÖSSZSESEN sor beállitása:

  _rangestr := 'A48:' + Form1.getoszlopbetu(_oszlopDarab)+'48';
  Form1.RangeFontkeszlet(_rangestr,'Arial',12,True,False);
  Form1.RangeKozepre(_rangestr);

  _rangestr := 'C48:' + Form1.getoszlopbetu(_oszlopDarab)+'48';
  _oxl.worksheets[10].range[_rangestr].NumberFormat := '### ### ###';

  _oxl.worksheets[10].range['A48:B48'].Mergecells := true;
  _oxl.worksheets[10].Cells[48,1] := 'ÖSSZESEN';

  _xsor := 29;
  while _xsor<=45 do
    begin
      _rangestr := 'C'+INTTOSTR(_Xsor)+':'+_lastletter+inttostr(_xsor);
      _oxl.worksheets[10].range[_rangestr].Font.color := clGray;
      _xsor := _xsor + 2;
    end;

  // A teljes forgalmi számok beállitása:

  _rangestr := 'C29:' + Form1.getoszlopBetu(_oszlopDarab)+'45';
  _oxl.worksheets[10].range[_rangestr].NumberFormat := '### ### ###';
  Form1.RangeKozepre(_rangestr);

  // --------------------------------------------------------------------

  _xOszlop := 3;
  while _xOszlop<=_oszlopDarab do
    begin
      _b := Form1.GetoszlopBetu(_xOszlop);
      _formula := '=SUM(' + _b + '29+' + _b + '31+' + _b + '33 +' + _b + '35+'
                 + _b + '37+' + _b + '39+' + _b + '41+' + _b + '43+' + _b+'45)';
      _oxl.worksheets[10].Cells[37,_xOszlop].Formula := _formula;
      inc(_xOszlop);
    end;
end;

procedure TACEXCELTABLA.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := false;
  Modalresult := 1;
end;


procedure TacExcelTabla.Adatfeltoltes;

begin
  _pkindex := 1;
  while _pkindex<=_acPkFileDarab do
    begin
      _xoszlop := 1 + trunc(2*_pkindex);
      _valindex := 1;
      while _valindex<=9 do
        begin
          _xsor := _valindex + 7;
          _oxl.worksheets[10].Cells[_xsor,_xoszlop] := _acKeszlet[_pkindex,_valindex];
          _oxl.worksheets[10].Cells[_xsor,_xoszlop+1] := _acKeszletFt[_pkindex,_valindex];

          _xsor := 27 + trunc(2*_valindex);
          _oxl.worksheets[10].Cells[_xsor,_xoszlop] := _acVetel[_pkindex,_valindex];
          _oxl.worksheets[10].Cells[_xsor+1,_xoszlop] := _acVetelFt[_pkindex,_valindex];

          _oxl.worksheets[10].Cells[_xsor,_xoszlop+1] := _acEladas[_pkindex,_valindex];
          _oxl.worksheets[10].Cells[_xsor+1,_xoszlop+1] := _acEladasFt[_pkindex,_valindex];

          inc(_valindex);
        end;

      _oxl.worksheets[10].Cells[20,_xoszlop] := _acWusd[_pkindex];
      _oxl.worksheets[10].Cells[21,_xoszlop] := _acWhuf[_pkindex];
      _oxl.worksheets[10].Cells[22,_xoszlop] := _acWKezdij[_pkindex];
   //   _oxl.worksheets[10].Cells[23,_xoszlop] := _acWusd[_pkindex];

      inc(_pkindex);
    end;

  // ---------------------------------------------------------------------------


  _xoszlop  := 1 + trunc(2*_pkindex);
  _valindex := 1;
  while _valindex<=9 do
    begin
      _xsor := _valindex + 7;
      _oxl.worksheets[10].Cells[_xsor,_xoszlop] := _acKeszlet[0,_valindex];
      _oxl.worksheets[10].Cells[_xsor,_xoszlop+1] := _acKeszletFt[0,_valindex];

      _xsor := 27 + trunc(2*_valindex);
      _oxl.worksheets[10].Cells[_xsor,_xoszlop] := _acVetel[0,_valindex];
      _oxl.worksheets[10].Cells[_xsor+1,_xoszlop] := _acVetelFt[0,_valindex];

      _oxl.worksheets[10].Cells[_xsor,_xoszlop+1] := _acEladas[0,_valindex];
      _oxl.worksheets[10].Cells[_xsor+1,_xoszlop+1] := _acEladasFt[0,_valindex];

       inc(_valindex);

    end;

  _oxl.worksheets[10].Cells[20,_xoszlop] := _acWusd[0];
  _oxl.worksheets[10].Cells[21,_xoszlop] := _acWhuf[0];
  _oxl.worksheets[10].Cells[22,_xoszlop] := _acWKezdij[0];
  _oxl.worksheets[10].Cells[23,_xoszlop] := _acWusd[0];
end;
}

end.
