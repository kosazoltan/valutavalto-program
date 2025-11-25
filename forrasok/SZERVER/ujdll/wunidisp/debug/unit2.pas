unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBTable, unit1, strutils, IBQuery;

type
  TWuniDisplay = class(TForm)

    ReceptQuery   : TIBQuery;
    ReceptTabla   : TIBTable;
    ReceptDbase   : TIBDatabase;
    ReceptTranz   : TIBTransaction;

    AFA           : TPanel;
    AfaPBePanel   : TPanel;
    AfaNyitoPanel : TPanel;
    AfaGBePanel   : TPanel;
    AfaGKiPanel   : TPanel;
    AfaUKiPanel   : TPanel;
    AfaPKiPanel   : TPanel;
    AfaZaroPanel  : TPanel;
    EgysegPanel   : TPanel;
    HufPBEPanel   : TPanel;
    HufPKiPanel   : TPanel;
    HufUBePanel   : TPanel;
    HufGBePanel   : TPanel;
    HufUKIPanel   : TPanel;
    HufNyitoPanel : TPanel;
    HufGKiPanel   : TPanel;
    HufZAROPanel  : TPanel;
    IdoszakPanel  : TPanel;
    Panel10       : TPanel;
    Panel11       : TPanel;
    Panel13       : TPanel;
    Panel14       : TPanel;
    Panel17       : TPanel;
    Panel2        : TPanel;
    Panel3        : TPanel;
    Panel4        : TPanel;
    Panel5        : TPanel;
    Panel6        : TPanel;
    Panel7        : TPanel;
    Panel8        : TPanel;
    Panel15       : TPanel;
    Panel16       : TPanel;
    UsdNyitoPanel : TPanel;
    UsdGBePanel   : TPanel;
    UsdGKiPanel   : TPanel;
    UsdZaroPanel  : TPanel;
    UsdPBePanel   : TPanel;
    UsdUKiPanel   : TPanel;
    UsdPKiPanel   : TPanel;
    UsdUBePanel   : TPanel;

    Shape1        : TShape;
    Label1        : TLabel;

    MasAdatokGomb : TBitBtn;
    MasEgysegGomb : TBitBtn;
    MasIdoszakGomb: TBitBtn;
    QuitGomb      : TBitBtn;
    KILEPO: TTimer;
    ZALOGPLUSBOX: TCheckBox;

    procedure QUITGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure ParameterBeolvasas;

    function ForintForm(_ft: integer):string;
    function ScanBetu(_b: string): byte;
    function ScanKorzet(_k: integer): byte;

    procedure MasAdatokGombClick(Sender: TObject);
    procedure MasEgysegGombClick(Sender: TObject);
    procedure MasIdoszakGombClick(Sender: TObject);
    procedure TablaDisplay;
    procedure KilepoTimer(Sender: TObject);
    procedure ZALOGPLUSBOXClick(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WUNIDISPLAY: TWUNIDISPLAY;

  _korzetszam: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _korzetnev: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
           'DEBRECEN','NYIREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR','ZÁLOG');

  _honev: array[1..12] of string = ('január','február','március','április',
                 'május','junius','július','augusztus','szeptember',
                          'október','november','december');

  _betusor: array[1..4] of string = ('B','P','E','Z');

  _cegnevsor: array[1..4] of string =('BEST CHANGE','PANNON CHANGE','EAST CHANGE',
                                           'EXPRESSZ ZÁLOG');

  _usdNyito,_hufnyito,_afanyito,_usdZaro,_hufzaro,_afaZaro,_afabe,_afaki: integer;
  _usdgbe,_hufgbe,_afagbe,_usdgki,_hufgki,_afagki: integer;
  _usdube,_hufube,_usduki,_hufuki,_afauki: integer;
  _usdpbe,_hufpbe,_afapbe,_usdpki,_hufpki,_afapki,_mResult: integer;
  _pcs,_filter,_aktcegbetu,_evs,_hos,_tolnaps,_ignaps,_tolstring,_igstring: string;

  _idsz,_cegnev,_aktegyseg: string;
  _sorveg: string = chr(13)+chr(10);
  _egysegtipus,_aktkorzet,_aktpenztar,_bss,_korzss,_code: integer;
  _aktho,_tolnap,_ignap,_y: word;


// =============================================================================
                      function wudisplayrutin: integer; stdcall;
// =============================================================================

implementation

{$R *.dfm}

// =============================================================================
                 function wudisplayrutin: integer; stdcall;
// =============================================================================

begin
  wunidisplay := TWunidisplay.Create(Nil);
  result := Wunidisplay.showmodal;
  wunidisplay.free;
end;


// ======================================================================
         procedure TWUNIDISPLAY.FormActivate(Sender: TObject);
// ======================================================================

begin
  Top  := 230;
  Left := 208;

  ZalogPlusBox.Visible := False;
  ZalogplusBox.Checked := false;
  ParameterBeolvasas;
  
  if _egysegtipus=4 then ZalogplusBox.visible := True;
  Tabladisplay;
end;


// =============================================================================
                   procedure TWunidisplay.TablaDisplay;
// =============================================================================

begin
  _pcs := 'SELECT * FROM WUNIGYUJTO' + _sorveg;
  _pcs := _pcs + 'WHERE ' + _filter;

  ReceptDbase.Connected := true;
  with ReceptQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  with ReceptQuery do
    begin
      _usdNyito := FieldByNAme('USDNYITO').asInteger;
      _hufNyito := FieldByNAme('HUFNYITO').asInteger;
      _afaNyito := FieldByNAme('AFANYITO').asInteger;

      _usdZaro := FieldByNAme('USDZARO').asInteger;
      _hufZaro := FieldByNAme('HUFZARO').asInteger;
      _afaZaro := FieldByNAme('AFAZARO').asInteger;

      _afaBe := FieldByname('AFABE').asInteger;
      _afaki := FieldByName('AFAKI').asInteger;

      _usdGbE := FieldByNAme('USDGBE').asInteger;
      _hufGbe := FieldByNAme('HUFGBE').asInteger;
      _afaGbe := FieldByNAme('AFAGBE').asInteger;

      _usdGKi := FieldByNAme('USDGKI').asInteger;
      _hufGKi := FieldByNAme('HUFGKI').asInteger;
      _afaGKi := FieldByNAme('AFAGKI').asInteger;

      _usdUbE := FieldByNAme('USDUBE').asInteger;
      _hufUbe := FieldByNAme('HUFUBE').asInteger;

      _usdUKi := FieldByNAme('USDUKI').asInteger;
      _hufUKi := FieldByNAme('HUFUKI').asInteger;
      _afaUKi := FieldByNAme('AFAUKI').asInteger;

      _usdPbE := FieldByNAme('USDPBE').asInteger;
      _hufPbe := FieldByNAme('HUFPBE').asInteger;
      _afaPbe := FieldByNAme('AFAPBE').asInteger;

      _usdPKi := FieldByNAme('USDPKI').asInteger;
      _hufPKi := FieldByNAme('HUFPKI').asInteger;
      _afaPKi := FieldByNAme('AFAPKI').asInteger;
    end;

  ReceptQuery.Close;
  ReceptDbase.Close;

  UsdnyitoPanel.Caption := Forintform(_usdNyito);
  HufnyitoPanel.Caption := Forintform(_hufNyito);
  aFANyitoPanel.Caption := Forintform(_afaNyito);

  UsdGBePanel.Caption := Forintform(_usdGBe);
  HufGBePanel.Caption := Forintform(_hufGBe);
  AfaGBePanel.Caption := Forintform(_AfaGBe);

  UsdGKiPanel.Caption := Forintform(_usdGKi);
  HufGKIPanel.Caption := Forintform(_hufGKi);
  AfaGKiPanel.Caption := Forintform(_AfaGKi);

  UsdUBePanel.Caption := Forintform(_usdUBe);
  HufUBePanel.Caption := Forintform(_hufUBe);

  UsdUKiPanel.Caption := Forintform(_usdUKi);
  HufUKIPanel.Caption := Forintform(_hufUKi);
  AfaUKiPanel.Caption := Forintform(_AfaUKi);

  UsdPBePanel.Caption := Forintform(_usdPBe);
  HufPBePanel.Caption := Forintform(_hufPBe);
  AfaPBePanel.Caption := ForintForm(_afabe);

  UsdPKiPanel.Caption := Forintform(_usdPKi);
  HufPKIPanel.Caption := Forintform(_hufPKi);
  AfaPKiPanel.Caption := Forintform(_AfaPKi);


  UsdZaroPanel.Caption := Forintform(_usdZaro);
  HufzaroPanel.Caption := Forintform(_hufZaro);
  aFAZaroPanel.Caption := Forintform(_afaZaro);

end;

//============================================================
     function TWunidisplay.ForintForm(_ft: integer):string;
// ===========================================================

var _lebego: real;

begin
  _lebego := 1.00*_ft;
  result := formatfloat('###,###,###',_lebego);
end;


// =============================================================================
                procedure TWuniDisplay.ParameterBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ADATATADO';

  ReceptDbase.Connected := True;
  with ReceptQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;

      _filter      := trim(FieldByNAme('SZURO').AsString);
      _egysegtipus := FieldByNAme('TIPUS').asInteger;
      _aktcegbetu  := FieldByName('CEGBETU').asString;
      _aktkorzet   := FieldByName('KORZET').asInteger;
      _aktpenztar  := FieldByName('IRODA').asInteger;
      Close;

      Sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;

      _tolstring := FieldByName('STARTDATE').asString;
      _igstring := FieldByName('ENDDATE').asString;
      Close;
    end;
  Receptdbase.close;

  if _egysegtipus=3 then _filter:=_filter+chr(39)+_aktcegbetu+chr(39)+')';

  _evs     := leftstr(_tolstring,4);
  _hos     := midstr(_tolstring,6,2);
  _tolnaps := midstr(_tolstring,9,2);
  _ignaps  := midstr(_igstring,9,2);

  val(_hos,_aktho,_code);
  val(_tolnaps,_tolnap,_code);
  val(_ignaps,_ignap,_code);

  _idsz := _evs + ' '+_honev[_aktho] + ' ' + inttostr(_tolnap)+' - '+inttostr(_ignap);
  IdoszakPanel.Caption := _idsz;
  IdoszakPanel.repaint;

  _bss    := ScanBetu(_AKTCEGBETU);
  _cegnev := '';

  if _bss>0 then _cegnev := _cegnevsor[_bss]+' KFT';

  _korzss := Scankorzet(_aktkorzet);

  case _egysegtipus of
    1: _aktegyseg := inttostr(_aktpenztar)+'. PÉNZTÁR ADATAI';
    2: _aktegyseg := _korzetnev[_korzss]+'I KÖRZET ADATAI';
    3: _aktegyseg := _cegnev +' ADATAI';
    4: _aktegyseg := 'PÉNZTÁRAK ÖSSZESITETT ADATAI';
  end;

  EgysegPanel.Caption := _aktegyseg;
  Egysegpanel.repaint;
end;

// =============================================================================
           function TWuniDisplay.ScanKorzet(_k: integer): byte;
// =============================================================================

begin
  result := 0;
  _y := 1;
  while _y<=9 do
    begin
      if _korzetszam[_y]=_k then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
              function TWuniDisplay.ScanBetu(_b: string): byte;
// =============================================================================

var _y: byte;

begin
  result := 0;
  _y :=1;
  while _y<=4 do
    begin
      if _betusor[_y]=_b THEN
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
          procedure TWuniDisplay.MASADATOKGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  Kilepo.enabled := True;
end;

// =============================================================================
           procedure TWuniDisplay.MASEGYSEGGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 2;
  Kilepo.enabled := True;
end;

// =============================================================================
          procedure TWuniDisplay.MASIDOSZAKGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 3;
  Kilepo.enabled := True;
end;

// =============================================================================
            procedure TWuniDisplay.QUITGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := -1;
  Kilepo.enabled := True;
end;

// =============================================================================
            procedure TWuniDisplay.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

procedure TWuniDisplay.ZALOGPLUSBOXClick(Sender: TObject);
begin
  if ZalogplusBox.Checked then _filter := '(ERTEKTAR=-2)'
  else _filter := '(ERTEKTAR=-1)';
  TablaDisplay;
end;





end.
