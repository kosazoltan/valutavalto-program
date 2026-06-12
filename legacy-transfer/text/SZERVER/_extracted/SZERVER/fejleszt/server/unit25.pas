unit Unit25;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBTable, unit1, strutils;

type
  TWUNIDISPLAY = class(TForm)
    EGYSEGPANEL: TPanel;
    Label1: TLabel;
    IDOSZAKPANEL: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    USDNYITOPANEL: TPanel;
    HUFGBEPANEL: TPanel;
    HUFNYITOPANEL: TPanel;
    HUFGKIPANEL: TPanel;
    USDGBEPANEL: TPanel;
    AFANYITOPANEL: TPanel;
    AFAGBEPANEL: TPanel;
    USDGKIPANEL: TPanel;
    USDZAROPANEL: TPanel;
    AFAPBEPANEL: TPanel;
    HUFZAROPANEL: TPanel;
    AFAZAROPANEL: TPanel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    WUNITABLA: TIBTable;
    WUNIDBASE: TIBDatabase;
    WUNITRANZ: TIBTransaction;
    Panel2: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    USDUBEPANEL: TPanel;
    HUFUBEPANEL: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel17: TPanel;
    USDPBEPANEL: TPanel;
    USDUKIPANEL: TPanel;
    HUFUKIPANEL: TPanel;
    USDPKIPANEL: TPanel;
    AFA: TPanel;
    HUFPBEPANEL: TPanel;
    HUFPKIPANEL: TPanel;
    AFAGKIPANEL: TPanel;
    AFAUKIPANEL: TPanel;
    AFAPKIPANEL: TPanel;
    procedure BitBtn2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);

    function ForintForm(_ft: integer):string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WUNIDISPLAY: TWUNIDISPLAY;
  _usdNyito,_hufnyito,_afanyito,_usdZaro,_hufzaro,_afaZaro,_afabe,_afaki: integer;
  _usdgbe,_hufgbe,_afagbe,_usdgki,_hufgki,_afagki: integer;
  _usdube,_hufube,_usduki,_hufuki,_afauki: integer;
  _usdpbe,_hufpbe,_afapbe,_usdpki,_hufpki,_afapki: integer;

implementation

{$R *.dfm}

procedure TWUNIDISPLAY.BitBtn2Click(Sender: TObject);
begin
  WuniTabla.close;
  ModalResult := 1;
end;

// ======================================================================
         procedure TWUNIDISPLAY.FormActivate(Sender: TObject);
// ======================================================================

begin
  Top := _top + 195;
  Left := _left +170;
  IdoszakPanel.Caption := _IdoszakLabel;
  EgysegPanel.Caption := _displayFocim;

   case _displaytipus of
    1: _szuro := '(IRODASZAM=0) AND (ERTEKTAR=0)';
    2: _szuro := '(IRODASZAM=0) AND (ERTEKTAR='+chr(39)+inttostr(_aktkorzet)+chr(39)+')';
    3: _szuro := 'IRODASZAM='+chr(39)+inttostr(_aktpenztar)+chr(39);
    4: _szuro := '(IRODASZAM=-1) AND (ERTEKTAR='+inttostr(_cbsors)+')';
  end;

  wunidbase.close;
  wuniDbase.Connected := true;

  if wunitranz.InTransaction then wunitranz.Commit;

  with WuniTabla do
    begin
      Open;
      Refresh;
      Filtered := False;
      Filter := _szuro;
      Filtered := true;
      First;
    end;

  with Wunitabla do
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

  WuniTabla.Close;

  USDnyitoPanel.Caption := Forintform(_usdNyito);
  HUFnyitoPanel.Caption := Forintform(_hufNyito);
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
//  AfaUKiPanel.Caption := Forintform(_AfaKi);
  AfaUKiPanel.Caption := Forintform(_AfaUKi);

  UsdPBePanel.Caption := Forintform(_usdPBe);
  HufPBePanel.Caption := Forintform(_hufPBe);
 // AfaPBePanel.Caption := Forintform(_AfaPBe);
  AfaPBePanel.Caption := ForintForm(_afabe);

  UsdPKiPanel.Caption := Forintform(_usdPKi);
  HufPKIPanel.Caption := Forintform(_hufPKi);
  AfaPKiPanel.Caption := Forintform(_AfaPKi);


  USDZaroPanel.Caption := Forintform(_usdZaro);
  HUFzaroPanel.Caption := Forintform(_hufZaro);
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




end.
