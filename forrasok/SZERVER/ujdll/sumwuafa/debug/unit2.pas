unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable,
  ExtCtrls;

type
  TForm2 = class(TForm)
    WTABLA: TIBTable;
    WQUERY: TIBQuery;
    WDBASE: TIBDatabase;
    WTRANZ: TIBTransaction;
    KILEPO: TTimer;
    messpanel: TPanel;

    procedure FormActivate(Sender: TObject);
    procedure Wparancs(_ukaz: string);
    procedure SumAdatNullazo;
    procedure WuniDataBeolvasas;
    procedure WuniDataOsszeadas;
    procedure Sumkibe;
    procedure AdatFeliro;
    procedure KorzetSum;
    procedure KFTsum;
    procedure Cegsum;
    procedure KILEPOTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _etnums: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _cbetuk: array[1..4] of string = ('B','E','P','Z');
  _et,_ceg,_aktpenztar: byte;
  _aktkorzet: integer;

  _pcs,_cegbetu,_aktceg,_aktcegbetu: string;
  _sorveg: string = chr(13)+chr(10);

  _usdnyito,_usdzaro,_usdgbe,_usdgki,_usdpbe,_usdpki,_usdube,_usduki: integer;
  _hufnyito,_hufzaro,_hufgbe,_hufgki,_hufpbe,_hufpki,_hufube,_hufuki: integer;
  _afanyito,_afazaro,_afagbe,_afagki,_afapbe,_afapki,_afauki: integer;

  _susdnyito,_susdzaro,_susdgbe,_susdgki,_susdpbe,_susdpki,_susdube,_susduki: integer;
  _shufnyito,_shufzaro,_shufgbe,_shufgki,_shufpbe,_shufpki,_shufube,_shufuki: integer;
  _safanyito,_safazaro,_safagbe,_safagki,_safapbe,_safapki,_safauki: integer;
  _sUsdBe,_sHufbe,_sAfabe,_sUsdki,_sHufki,_sAfaki: integer;

  _top,_left,_height,_width: word;


function summawuniafa: integer;stdcall;

implementation

{$R *.dfm}


function summawuniafa: integer; stdcall;
begin
  Form2 := Tform2.Create(Nil);
  result := form2.showmodal;
  Form2.free;
end;


// =============================================================================
              procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top    := round((_height-43)/2);
  _left   := round((_width-332)/2);

  Top     := _top;
  Left    := _left;
  Height  := 43;
  Width   := 332;

  KorzetSum;
  Kftsum;
  Cegsum;
  Kilepo.Enabled := true;
end;

// =============================================================================
                         procedure TForm2.KorzetSum;
// =============================================================================

begin
  MessPanel.Caption := 'KÖRZETEK ÖSSZESÍTÕJE';
  MessPanel.repainT;

  _et := 1;
  while _et<=9 do
    begin
      SumAdatNullazo;

      _aktkorzet := _etNums[_et];

      _pcs := 'SELECT * FROM WUNIGYUJTO' + _sorveg;
      _pcs := _pcs + 'WHERE ERTEKTAR=' + inttostr(_aktkorzet);

      wdbase.Connected := true;
      with wquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _aktcegbetu := FieldByNAme('CEGBETU').asString;
        end;

      while not wquery.Eof do
        begin
          wuniDataBeolvasas;
          wuniDataOsszeAdas;
          wquery.next;
        end;

      wquery.close;
      wDbase.close;

      SumKibe;

      _aktPenztar := 0;
      AdatFeliro;
      inc(_et);
    end;
end;

// =============================================================================
                          procedure TForm2.Kftsum;
// =============================================================================


begin
  MessPanel.Caption := 'KFT-K ÖSSZESÍTÕJE';
  MessPanel.repaint;

  _ceg := 1;
  while _ceg<=4 do
    begin
      SumAdatNullazo;

      _aktcegbetu := _cBetuk[_ceg];

      _pcs := 'SELECT * FROM WUNIGYUJTO' + _sorveg;
      _pcs := _pcs + 'WHERE (IRODASZAM=0) AND (CEGBETU='+chr(39)+_aktcegbetu+chr(39)+')';

      wdbase.Connected := true;
      with wquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      while not wquery.Eof do
        begin
          WuniDataBeolvasas;
          WuniDataOsszeAdas;
          wquery.next;
        end;

      wquery.close;
      wDbase.close;

      SumKibe;

      _aktpenztar := 0;
      _aktkorzet  := 0;
      
      AdatFeliro;
      inc(_ceg);
    end;
end;

// =============================================================================
                          procedure TForm2.Cegsum;
// =============================================================================

begin
  MessPanel.Caption := 'CÉG ÖSSZESÍTÕJE';
  MessPanel.repaint;

  SumAdatNullazo;

  _pcs := 'SELECT * FROM WUNIGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE (IRODASZAM=0) AND (ERTEKTAR=0)';

  wdbase.Connected := true;
  with wquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not wquery.Eof do
    begin
      WuniDataBeolvasas;
      _cegbetu := Wquery.FieldByName('CEGBETU').asString;
      if _cegbetu<>'Z' then WuniDataOsszeadas;
      Wquery.next;
    end;

  wquery.close;
  wDbase.close;

  SumKibe;
  _aktPenztar := 0;
  _aktKorzet  := -1;
  _aktcegbetu := '';

  Adatfeliro;

  // -----------------------------------

  _pcs := 'SELECT * FROM WUNIGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE (IRODASZAM=0) AND (ERTEKTAR=0) AND (CEGBETU='+chr(39)+'Z'+chr(39)+')';

  wdbase.Connected := true;
  with wquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  WuniDataBeolvasas;
  WuniDataOsszeAdas;
  _aktPenztar := 0;
  _aktKorzet  := -2;
  _aktcegbetu := '';
  AdatFeliro;
end;

// =============================================================================
                    procedure TForm2.SumadatNullazo;
// =============================================================================

begin
  _sUsdNyito := 0;
  _sUsdZaro  := 0;
  _sUsdGbe   := 0;
  _sUsdGki   := 0;
  _sUsdPbe   := 0;
  _sUsdPki   := 0;
  _sUsdUbe   := 0;
  _sUsdUki   := 0;

  _sHufNyito := 0;
  _sHufZaro  := 0;
  _sHufGbe   := 0;
  _sHufGki   := 0;
  _sHufPbe   := 0;
  _sHufPki   := 0;
  _sHufUbe   := 0;
  _sHufUki   := 0;

  _sAfaNyito := 0;
  _sAfaZaro  := 0;
  _sAfaGbe   := 0;
  _sAfaGki   := 0;
  _sAfaPbe   := 0;
  _sAfaPki   := 0;
  _sAfaUki   := 0;
end;

// =============================================================================
                   procedure TForm2.WunidataBeolvasas;
// =============================================================================

begin
  with wquery do
    begin

      _usdgbe := FieldbyName('USDGBE').asInteger;
      _usdgki := FieldbyName('USDGKI').asInteger;
      _usdpbe := FieldbyName('USDPBE').asInteger;
      _usdpki := FieldbyName('USDPKI').asInteger;
      _usdube := FieldbyName('USDUBE').asInteger;
      _usduki := FieldbyName('USDUKI').asInteger;

      _hufgbe := FieldbyName('HUFGBE').asInteger;
      _hufgki := FieldbyName('HUFGKI').asInteger;
      _hufpbe := FieldbyName('HUFPBE').asInteger;
      _hufpki := FieldbyName('HUFPKI').asInteger;
      _hufube := FieldbyName('HUFUBE').asInteger;
      _hufuki := FieldbyName('HUFUKI').asInteger;

      _afagbe := FieldbyName('AFAGBE').asInteger;
      _afagki := FieldbyName('AFAGKI').asInteger;
      _afapbe := FieldbyName('AFAPBE').asInteger;
      _afapki := FieldbyName('AFAPKI').asInteger;
      _afauki := FieldbyName('AFAUKI').asInteger;

      _usdNyito := FieldByName('USDNYITO').asInteger;
      _hufNyito := FieldByName('HUFNYITO').asInteger;
      _afaNyito := FieldByName('AFANYITO').asInteger;

      _usdZaro := FieldByName('USDZARO').asInteger;
      _hufZaro := FieldByName('HUFZARO').asInteger;
      _afaZaro := FieldByName('AFAZARO').asInteger;

    end;
end;

// =============================================================================
                    procedure TForm2.WuniDataOsszeadas;
// =============================================================================


begin
  _sUsdGbe := _sUsdGbe + _usdGbe;
  _sUsdGki := _sUsdGki + _usdGki;
  _sUsdPbe := _sUsdPbe + _usdPbe;
  _sUsdPki := _sUsdPki + _usdPki;
  _sUsdUbe := _sUsdUbe + _usdUbe;
  _sUsdUki := _sUsdUki + _usdUki;

  _sHufGbe := _sHufGbe + _hufGbe;
  _sHufGki := _sHufGki + _hufGki;
  _sHufPbe := _sHufPbe + _hufPbe;
  _sHufPki := _sHufPki + _hufPki;
  _sHufUbe := _sHufUbe + _hufUbe;
  _sHufUki := _sHufUki + _hufUki;

  _sAfaGbe := _sAfaGbe + _afaGbe;
  _sAfaGki := _sAfaGki + _afaGki;
  _sAfaPbe := _sAfaPbe + _afaPbe;
  _sAfaPki := _sAfaPki + _afaPki;
  _sAfaUki := _sAfaUki + _afaUki;

  _sUsdNyito := _sUsdNyito + _usdNyito;
  _sHufNyito := _sUsdNyito + _hufNyito;
  _sAfaNyito := _sUsdNyito + _afaNyito;
  _sUsdZaro := _sUsdZaro + _usdZaro;
  _sHufZaro := _sHufZaro + _hufZaro;
  _sAfaZaro := _sAfaZaro + _afaZaro;
end;

// =============================================================================
                         procedure TForm2.SumKibe;
// =============================================================================

begin
  _sUSDbe := _sUsdGbe+_sUsdPbe+_sUsdUbe;
  _sUSDki := _sUsdGki+_sUsdPki+_sUsdUki;

  _sHUFbe := _sHufGbe+_sHufPbe+_sHufUbe;
  _sHUFki := _sHufGki+_sHufPki+_sHufUki;

  _sAfaBe := _sAfaGbe+_sAfaPbe;
  _sAfaki := _sAfaGki+_sAfaPki+_sAfaUki;
end;

// =============================================================================
                         procedure TForm2.Adatfeliro;
// =============================================================================

begin
  _pcs := 'INSERT INTO WUNIGYUJTO (IRODASZAM,ERTEKTAR,CEGBETU,';
  _pcs := _pcs + 'USDNYITO,HUFNYITO,AFANYITO,USDZARO,HUFZARO,AFAZARO,';
  _pcs := _pcs + 'USDGBE,HUFGBE,AFAGBE,USDGKI,HUFGKI,AFAGKI,';
  _pcs := _pcs + 'USDPBE,HUFPBE,AFAPBE,USDPKI,HUFPKI,AFAPKI,';
  _pcs := _pcs + 'USDUBE,HUFUBE,USDUKI,HUFUKI,AFAUKI,';
  _pcs := _Pcs + 'USDBE,HUFBE,AFABE,USDKI,HUFKI,AFAKI)'+_sorveg;

  _pcs := _pcs + 'VALUES ('+inttostr(_aktpenztar)+','+inttostr(_aktkorzet)+',';
  _pcs := _pcs + chr(39) + _aktcegbetu + chr(39) + ',';
  _pcs := _pcs + inttostr(_sUsdnyito) + ',';
  _pcs := _pcs + inttostr(_sHufnyito) + ',';
  _pcs := _pcs + inttostr(_sAfanyito) + ',';

  _pcs := _pcs + inttostr(_sUsdzaro) + ',';
  _pcs := _pcs + inttostr(_sHufZaro) + ',';
  _pcs := _pcs + inttostr(_sAfaZaro) + ',';

  _pcs := _pcs + inttostr(_sUsdGbe) + ',';
  _pcs := _pcs + inttostr(_sHufGbe) + ',';
  _pcs := _pcs + inttostr(_sAfaGbe) + ',';

  _pcs := _pcs + inttostr(_sUsdGki) + ',';
  _pcs := _pcs + inttostr(_sHufGki) + ',';
  _pcs := _pcs + inttostr(_sAfaGki) + ',';

  _pcs := _pcs + inttostr(_sUsdPbe) + ',';
  _pcs := _pcs + inttostr(_sHufPbe) + ',';
  _pcs := _pcs + inttostr(_sAfaPbe) + ',';

  _pcs := _pcs + inttostr(_sUsdPki) + ',';
  _pcs := _pcs + inttostr(_sHufPki) + ',';
  _pcs := _pcs + inttostr(_sAfaPki) + ',';

  _pcs := _pcs + inttostr(_sUsdUbe) + ',';
  _pcs := _pcs + inttostr(_sHufUbe) + ',';

  _pcs := _pcs + inttostr(_sUsdUki) + ',';
  _pcs := _pcs + inttostr(_sHufUki) + ',';
  _pcs := _pcs + inttostr(_sAfaUki) + ',';

  _pcs := _pcs + inttostr(_sUsdBe) + ',';
  _pcs := _pcs + inttostr(_sHufBe) + ',';
  _pcs := _pcs + inttostr(_sAfaBe) + ',';

  _pcs := _pcs + inttostr(_sUsdKi) + ',';
  _pcs := _pcs + inttostr(_sHufKi) + ',';
  _pcs := _pcs + inttostr(_sAfaKi) + ')';

  wParancs(_pcs);
end;

// =============================================================================
                procedure TForm2.Wparancs(_ukaz: string);
// =============================================================================

begin
  wdbase.connected := true;
  if wtranz.InTransaction then wtranz.commit;
  wtranz.StartTransaction;
  with wquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  wTranz.commit;
  wdbase.close;
end;

// =============================================================================
              procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := 1;
end;


end.
