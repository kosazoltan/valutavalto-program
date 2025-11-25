unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, unit1;

type
  TEXPRESSEXCEL = class(TForm)
    Panel1: TPanel;
    kilepo: TTimer;

    procedure FormActivate(Sender: TObject);
    procedure kilepoTimer(Sender: TObject);
    procedure excelfejlec;
    procedure adatfeltoltes;
    procedure KorzetOsszesenExcel;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EXPRESSEXCEL: TEXPRESSEXCEL;
  _kptdarab,_skeszletft,_sptvft,_spteft,_ptv,_pte,_ptvFt,_pteFT: integer;

implementation

{$R *.dfm}

procedure TEXPRESSEXCEL.FormActivate(Sender: TObject);
begin
  Visible := False;

  Top     := _top + 370;
  Left    := _left +230;

  ExpressExcel.Repaint;
  Visible := true;

  _korzetIndex := 10;

  ExcelFejlec;
  Adatfeltoltes;
  Kilepo.enabled := true;
end;




procedure TEXPRESSEXCEL.kilepoTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  Modalresult := 1;
end;

procedure TEXPRESSEXCEL.Excelfejlec;

begin
    // Hány oszlop kell az express táblájában:

  _aktKorzetDarab := _acPkFileDarab;

  _oszlopDarab := 4+trunc(2*_aktKorzetdarab); // 2 valutanem + 2*irodak + 2*összesen
  _lastLetter := Form1.GetOszlopBetu(_oszlopDarab); // ez az utolsó oszlop betüjele

  _oxl.workSheets[_korzetIndex].Range['A1:A1'].columnWidth := 5;
  _oxl.worksheets[_korzetIndex].Range['B1:B1'].columnWidth := 18;
  _rangestr := 'C1:' + _lastletter +'1';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].columnWidth := 15;


  // A fejléc összes betüje Times New Roman, bold, Italic, 12-es közepre;

  _rangestr := 'A2:' + _lastletter + '7';
  Form1.RangeFontKeszlet(_rangestr,'Times New Roman',12,True,True);
  Form1.RangeKozepre(_rangestr);

  // A legfelsõ magyarázó fõcimsor beállitása:

  _rangestr := 'A2:H2';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Font.Size   := 16;

  _text := 'AZ EXPRESSZ MINIBANK KÉSZLETEI ÉS FORGALMA';
  _oxl.worksheets[_korzetIndex].cells[2,1] := _text;

  //----------------------------------------------------------------------------

  // Valutanemek box:

  _rangestr := 'A4:B5';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].range[_rangestr].VerticalAlignment := -4108;
  _oxl.worksheets[_korzetIndex].Cells[4,1] := 'VALUTANEMEK';

  // Dátumbox

  _rangestr := 'A6:B6';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Cells[6,1] := 'DÁTUM';

  // Idõbox:

  _rangestr := 'A7:B7';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Cells[7,1] := 'IDÕ';

  // ---------------------------------------------------------------------------

  // Az egységek ossulopainak kialakitása: körzetenként

  Form1.Fastcsik.Max := _aktkorzetdarab;

  _ptsorindex := 1;
  while _ptsorindex<=_aktkorzetDarab do
    begin
      // Az elsõ a 3-ik oszlop: (majd 5,7 stb)

      Form1.Fastcsik.Position := _ptsorIndex;
      _aktoszlop := 1 + trunc(2*_ptsorindex);

      // A következö pénztárszám:  ELSÕ RANGE= 'C4:B4'

      // Az összenyitott két cellába az egység neve kerül: (pl: Nyiregyháza TESCO)

      _ptarIndex := _AcPkSor[_ptsorindex]-150;
      _rangestr := Form1.getoszlopbetu(_aktoszlop) + '4:' + Form1.getoszlopbetu(_aktoszlop+1) + '4';
      _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;

      _text := _acirodanev[_ptarindex];

      // ------------------Egység neve, és a 2 oszlop neve ---------------------

      _oxl.worksheets[_korzetIndex].Cells[4,_aktoszlop]   := _text;
      _oxl.worksheets[_korzetIndex].Cells[5,_aktoszlop]   := 'KÉSZLET';
      _oxl.worksheets[_korzetIndex].Cells[5,_aktoszlop+1] := 'ÉRTÉK (Ft)';

      // ------------- Elsö range = 'C6:D6' Beirja az aktuális dûtumot ---------

      _rangestr := Form1.getoszlopbetu(_aktoszlop) + '6:' + Form1.getoszlopbetu(_aktoszlop+1) + '6';
      _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
      _oxl.worksheets[_korzetIndex].Cells[6,_aktoszlop] := _ptDatum[_ptarIndex];

      // ----------- Elsö range = 'C7:D7' -- Beirja az aktuális idöt -----------

      _rangestr := Form1.getoszlopbetu(_aktoszlop) + '7:' + Form1.getoszlopbetu(_aktoszlop+1) + '7';
      _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
      _oxl.worksheets[_korzetIndex].Cells[7,_aktoszlop] := _ptIdo[_ptarIndex];

      //  Jöhet a következö egység oszlopa -------------------------------------

      inc(_ptsorIndex);
    end;

  // ---------------------------------------------------------------------------

  // Az összesen oszlop kialakitása:

  _rangestr := Form1.getoszlopbetu(_oszlopDarab-1)+'4:' + Form1.getoszlopBetu(_oszlopdarab)+'7';
  _oxl.worksheets[_korzetindex].range[_rangestr].VerticalAlignment := -4108;

  // Az ÖSSZESEN felirat 4 összenyitott cellába kerül:

  _rangestr := Form1.getoszlopbetu(_oszlopDarab-1)+'4:'+Form1.getoszlopbetu(_oszlopdarab)+'5';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Cells[4,_oszlopDarab-1] := 'ÖSSZESEN';

  // Két-két cella összenyitva a KÉSZLET és ÉRTÉK (Ft) beirásának:

  _rangestr := Form1.getoszlopbetu(_oszlopDarab-1)+'6:'+Form1.getoszlopbetu(_oszlopdarab-1)+'7';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Cells[6,_oszlopDarab-1] := 'KÉSZLET';

  _rangestr := Form1.getoszlopbetu(_oszlopDarab)+'6:'+Form1.getoszlopbetu(_oszlopdarab)+'7';
  _oxl.worksheets[_korzetIndex].Range[_rangestr].Mergecells := True;
  _oxl.worksheets[_korzetIndex].Cells[6,_oszlopDarab] := 'ÉRTÉK (Ft)';

  // ------------------- OLDAL FEJLÉC (Valutanemek) ----------------------------

  //  A valutanemek és valutanevek beirása az 1 és 2-ik oszopba
  // a 8-tól a 34-ig sorig:

  _valutaIndex := 1;
  while _valutaIndex<=27 do
    begin
      _oxl.worksheets[_korzetIndex].Cells[7+_valutaindex,1] := _valutanemek[_valutaIndex];
      _oxl.worksheets[_korzetIndex].Cells[7+_valutaIndex,2] := _valutaNevek[_valutaIndex];
      inc(_valutaIndex);
    end;

  // A valutanemek oszlop-betüjének beállitása:

  _rangestr := 'A8:A34';
  Form1.RangeFontKeszlet(_rangestr,'Arial',10,True,False);
  Form1.RangeKozepre(_rangestr);

  // A valutanevek oszlop-betüjének beállitása

  _rangestr := 'B8:B34';
  Form1.RangeFontKeszlet(_rangestr,'Arial',10,False,False);

  // Az ÖSSZESEN felirat részére 2 cella összenyitva:

  _oxl.worksheets[_korzetIndex].range['A35:B35'].mergeCells := True;
  _oxl.worksheets[_korzetIndex].Cells[35,1] := 'ÖSSZESEN';

  //  Az ÖSSZESEN sor bankjegy-érték cellák összenyitása, mert csk érték van itt

  _xoszlop := 3;
  while _xoszlop<_oszlopDarab do
    begin
      _rangestr := Form1.getOszlopBetu(_xoszlop)+'35:'+Form1.getoszlopBetu(_xoszlop+1)+'35';
      _oxl.worksheets[_korzetIndex].range[_rangestr].MergeCells := true;
      _xoszlop := _xoszlop + 2;
    end;

  // --------- Az egyéb (WU,afa,kezdij,eker,foglalo) készletei -----------------

  _xsor := 38;
  while _xsor<44 do
    begin
      // a két cella összenyitása: és cim beirása (wu (usd)... stb)

      _rangestr := 'A'+inttostr(_xsor)+':B'+inttostr(_xsor);
      _oxl.worksheets[_korzetIndex].range[_rangestr].Mergecells := true;
      Form1.RangeFontKeszlet(_rangestr,'Times New Roman',11,False,True);
      _cc := _xsor-38;
      _oxl.worksheets[_korzetIndex].Cells[_xsor,1] := _wNev[_cc];

      //  Minden péntárnak, 2-2 celláját összenyitjuk az értékeknek:

      _xoszlop := 3;
      while _xOszlop<_oszlopdarab do
        begin
          _rangestr := Form1.getoszlopBetu(_xoszlop)+inttostr(_xsor)+':'+Form1.getoszlopbetu(_xOszlop+1)+inttostr(_xsor);
          _oxl.workSheets[_korzetIndex].range[_rangestr].Mergecells := True;
          _xoszlop := _xoszlop + 2;
        end;
      inc(_xsor);
    end;

  // Az egyéb készletek betütipusának beállitása:

  _rangestr := 'C38:' + Form1.getOszlopbetu(_oszlopDarab)+'43';
  Form1.RangeFontkeszlet(_rangestr,'Times New Roman',11,False,True);

  // ---------------------------------------------------------------------------

  // A NAPI FORGALOM sorának beállitása

  _Rangestr := 'A47:'+ Form1.getoszlopbetu(_oszlopdarab)+'47';
  Form1.RangeFontkeszlet(_rangestr,'Times New Roman',12,True,True);
  Form1.RangeKozepre(_rangestr);
  _oxl.worksheets[_korzetIndex].range['A47:B47'].mergecells := True;
  _oxl.worksheets[_korzetIndex].cells[47,1] := 'NAPI FORGALOM';

  // A forgalom sor fejlécének fejlécneveinek beirása:

  _xOszlop := 3;
  while _xOszlop<_oszlopdarab do
    begin
      _oxl.worksheets[_korzetIndex].cells[47,_xoszlop] := 'VÉTEL';
      _oxl.worksheets[_korzetIndex].cells[47,_xoszlop+1] := 'ELADÁS';
      _xOszlop := _xOszlop + 2;
    end;

  // --------- A forgalom  valutanemenként ------------------------------

  _xsor := 49;
  _valutaindex := 1;
  Form1.FAstcsik.Max := 27;

  while _valutaIndex<=27 do
    begin

      // Beirja a valutanemeket és valutaneveket:

      Form1.Fastcsik.Position := _valutaIndex;
      _oxl.worksheets[_korzetIndex].cells[_xsor,1] := _valutanemek[_valutaIndex];
      _oxl.worksheets[_korzetIndex].cells[_xsor,2] := _valutanevek[_valutaIndex];

      // Két-két cellát egymás alatt összenyit a valuta-nemeknek és neveknek:

      _rangestr := 'A'+inttostr(_xsor)+':A'+inttostr(_xsor+1);
      _oxl.worksheets[_korzetIndex].range[_rangestr].mergecells := true;

      _rangestr := 'B'+inttostr(_xsor)+':B'+inttostr(_xsor+1);
      _oxl.worksheets[_korzetIndex].range[_rangestr].mergecells := true;

      _xsor := _xsor + 2;
      inc(_valutaIndex);
    end;

  // A valutanemek betütipusai és elrendezése:

  _rangestr := 'A49:A102';
  Form1.RangeFontkeszlet(_rangestr,'Arial',10,True,False);
  Form1.RangeKozepre(_rangestr);

  _oxl.worksheets[_korzetIndex].range[_rangestr].VerticalAlignment := -4108;

  // A valutanevek betütipusai és elrendezése:

  _rangestr := 'B49:B102';
  Form1.RangeFontkeszlet(_rangestr,'Arial',10,False,False);
  _oxl.worksheets[_korzetIndex].range[_rangestr].VerticalAlignment := -4108;

  // A legalsó ÖSSZSESEN sor beállitása:

  _rangestr := 'A103:' + Form1.getoszlopbetu(_oszlopDarab)+'103';
  Form1.RangeFontkeszlet(_rangestr,'Arial',12,True,False);
  Form1.RangeKozepre(_rangestr);

  _oxl.worksheets[_korzetIndex].range[_rangestr].NumberFormat := '### ### ###';
  _oxl.worksheets[_korzetIndex].range['A103:B103'].Mergecells := true;
  _oxl.worksheets[_korzetIndex].range['A103:B103'].HorizontalAlignment := -4108;
  _oxl.worksheets[_korzetIndex].Cells[103,1] := 'ÖSSZESEN';

  // A teljes forgalmi számok beállitása:

  _rangestr := 'C49:' + Form1.getoszlopBetu(_oszlopDarab)+'102';
  _oxl.worksheets[_korzetIndex].range[_rangestr].NumberFormat := '### ### ###';
  Form1.RangeKozepre(_rangestr);


end;



procedure TEXPRESSEXCEL.Adatfeltoltes;
begin
   //  A készletek celláinak szám kijelzés tipusa

  _rangestr := 'C8:' + _lastLetter + '35';
  _oxl.worksheets[_korzetIndex].range[_rangestr].Numberformat := '### ### ###';
  Form1.Rangefontkeszlet(_rangestr,'Arial',10,False,False);

  //  Az ÖSSZESEN sor beállitása

   _rangeStr := 'A35:' + Form1.getOszlopBetu(_oszlopDarab)+'35';
  Form1.RangeFontKeszlet(_rangestr,'Arial',12,True,True);
  Form1.RangeKozepre(_rangestr);


  _kptDarab := _acPkFileDarab;
  _ptsorIndex := 1;

  _skeszletft := 0;

  Form1.Fastcsik.Max := _kptDarab;
  while _ptsorIndex<=_kptDarab do
    begin
      Form1.FastCsik.Position := _ptsorIndex;
      _valutaIndex := 1;

      _xoszlop     := 1 + trunc(2*_ptsorindex);

      _sptvft   := 0;
      _spteft   := 0;
      _skeszletft := 0;

      while _valutaIndex<=27 do
        begin

          // Az aktuális valuta sora: Xsor
          // Beirja a Valuta készletét és forint értékét:

          _xsor := _valutaIndex + 7;
          _aktKeszletFt := _acKeszletFt[_ptsorIndex,_valutaIndex];

          _oxl.worksheets[10].Cells[_xSor,_xOszlop]  := _acKeszlet[_ptsorindex,_valutaIndex];
          _oxl.worksheets[10].Cells[_xSor,_xOszlop+1]:= _aktkeszletFt;
          _sKeszletFt := _sKeszletFt + _aktKeszletFt;

          //  Most az aktuális valuta Vétele és Eladása kerül beirásra:
          // Az AUD kezdõsora: 49

          _xsor := 47 + trunc(_valutaIndex*2);

          _ptv := _acVetel[_ptsorIndex,_valutaIndex];
          _pte := _acEladas[_ptsorIndex,_valutaIndex];

          // Vétel és mellé az eladás beirása:

          if _ptv>0 then _oxl.worksheets[10].cells[_xSor,_xoszlop]  := _ptv;
          if _pte>0 then _oxl.worksheets[10].cells[_xSor,_xOszlop+1]:= _ptE;

          // A fenti tranzakciók forint értéke:

          _ptvFt := _acVetelFt[_ptsorIndex,_valutaIndex];
          _pteFt := _acEladasFt[_ptsorIndex,_valutaIndex];

          if _ptvFt>0 then
            begin
              _oxl.worksheets[10].cells[_xSor+1,_xoszlop].font.color := clGray;
              _oxl.worksheets[10].cells[_xSor+1,_xoszlop] := _ptvft;
              _sptvft := _sptvft + _ptvft;
            end;

          if _pteFt>0 then
            begin
              _oxl.worksheets[10].cells[_xSor+1,_xoszlop+1].font.color := clGray;
              _oxl.worksheets[10].cells[_xSor+1,_xoszlop+1] := _pteft;
              _spteft := _spteft + _pteft;
            end;

          inc(_valutaIndex);   // Jöhet a következõ valutanem
        end;

      // ----------- a valuták Vételi és eladási adatok felvannak irva ---------

      _x := 0;
      _fogs := '';

      while _x<5 do
        begin
          _aktf := _acfoglalo[_ptsorindex,_x];
          if _aktf>0 then _fogs := _fogs + inttostr(_aktf)+' '+ _foglalodnem[_x]+' ';
          inc(_x);
        end;

      // Az összes valuta készlet forint értéke a 35 sorba irva ------------

      _oxl.worksheets[10].Cells[35,_xoszlop] := _sKeszletFt;

      // A 103-ik sorba beirjuk az összes tranzakciók forint értékét
      // külön a vétel- és eladás rovatba:

      _oxl.worksheets[10].Cells[103,_xoszlop] := _sptvFt;
      _oxl.worksheets[10].Cells[103,_xoszlop+1] := _spteFt;

      // A WU- ÁFÁ KEZDIJ EKER FOGLALOK cellák elõkészitése:

      _rangeStr := 'A38:'+ Form1.getoszlopbetu(_oszlopdarab)+'43';
      _oxl.worksheets[10].range[_rangestr].HorizontalAlignment := -4108;
      _oxl.worksheets[10].range[_rangestr].NumberFormat := '### ### ###';

      // A WU (etc) adatok beirása:

      _oxl.worksheets[10].cells[38,_xoszlop] := _acWusd[_ptsorIndex];
      _oxl.worksheets[10].cells[39,_xoszlop] := _acWHuf[_ptsorIndex];

      _oxl.worksheets[10].cells[41,_xoszlop] := _acWKezdij[_ptsorIndex];

      _oxl.worksheets[10].cells[43,_xoszlop] := _fogs;

      inc(_ptsorIndex); // Jöhet a következõ pénztár a sorban
    end;

  KorzetOsszesenExcel;

end;


// =============================================================================
                  procedure TExpressExcel.KorzetOsszesenExcel;
// =============================================================================


var _skeszletFt,_sptvFt,_sPteFt,_ptv,_pte,_ptvft,_pteft: integer;

begin

  _xOszlop := _oszlopDarab-1;

  _sKeszletFt := 0;
  _sptVFt     := 0;
  _spteFt     := 0;

  _valutaIndex := 1;
  Form1.FastCsik.Max := 27;
  while _valutaIndex<=27 do
    begin
      Form1.FAstcsik.Position := _valutaIndex;

      _xsor := _valutaIndex + 7;
      _aktKeszletFt := _ACKeszletFt[0,_valutaIndex];

      // Az aktuális valuta készlete és forint értéke: beirni:

      _oxl.worksheets[10].Cells[_xSor,_xOszlop]  := _ACKeszlet[0,_valutaIndex];
      _oxl.worksheets[10].Cells[_xSor,_xOszlop+1]:= _aktkeszletFt;

      // Forintérték summázása:

      _sKeszletFt := _sKeszletFt + _aktKeszletFt;


      // eXPRESS összes vétele és eladása:

      _xsor := 47 + trunc(_valutaIndex*2);

      _ptv := _acVetel[0,_valutaIndex];
      _pte := _acEladas[0,_valutaIndex];

      // Az express akt valutájának összes vétele és eladása:

      if _ptv>0 then _oxl.worksheets[10].cells[_xSor,_xoszlop]  := _ptv;
      if _pte>0 then _oxl.worksheets[10].cells[_xSor,_xOszlop+1]:= _ptE;

      _ptvFt := _acVetelFt[0,_valutaIndex];
      _pteFt := _acEladasFt[0,_valutaIndex];

      if _ptvFt>0 then
        begin
          _oxl.worksheets[10].cells[_xSor+1,_xoszlop].font.color := clGray;
          _oxl.worksheets[10].cells[_xSor+1,_xoszlop] := _ptvft;
          _sptvft := _sptvft + _ptvft;
        end;

      if _pteFt>0 then
        begin
          _oxl.worksheets[10].cells[_xSor+1,_xoszlop+1].font.color := clGray;
          _oxl.worksheets[10].cells[_xSor+1,_xoszlop+1] := _pteft;
          _spteft := _spteft + _pteft;
        end;

      inc(_valutaIndex); // jöhet a következõ valuta:
    end;

  //  Az összes forint készlet feladása (minden valutájé)

  _oxl.worksheets[10].Cells[35,_xoszlop]   := _sKeszletFt;

  //  Az aktuális valuta összes vásárlása és eladása:

  _oxl.worksheets[10].Cells[103,_xoszlop]   := _sptvFt;
  _oxl.worksheets[10].Cells[103,_xoszlop+1] := _spteFt;

  // Az összes western-union stb felirása:

  _oxl.worksheets[10].cells[38,_xoszlop] := _acWusd[0];
  _oxl.worksheets[10].cells[39,_xoszlop] := _acWHuf[0];
  _oxl.worksheets[10].cells[41,_xoszlop] := _acWKezdij[0];

  // ------------------ foglalók felirása --------------------------------------

  {

  _fogs := '';
  _x := 0;
  while _x<5 do
    begin
      _aktf := _ktfoglalo[_korzetindex,_x];
      if _aktf>0 then _fogs := _fogs +inttostr(_aktf)+' '+ _foglalodnem[_x]+' ';
      inc(_x);
    end;
   _oxl.worksheets[_korzetindex].cells[43,_xoszlop] := _fogs;
   }


end;




end.
