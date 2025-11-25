unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, unit1, dateutils, ExtCtrls, strutils;

type
  TGETIDOSZAK = class(TForm)
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    TOLCOMBO: TComboBox;
    IGCOMBO: TComboBox;
    RENDBENGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    Shape1: TShape;
    Label3: TLabel;
    Shape2: TShape;
    Shape3: TShape;
    FUGGONY: TPanel;
    procedure RENDBENGOMBClick(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
    procedure TOLCOMBOChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure IGCOMBOChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETIDOSZAK: TGETIDOSZAK;
  _ev,_ho: word;

implementation

{$R *.dfm}


// =============================================================================
            procedure TGETIDOSZAK.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;
begin
  Fuggony.Visible := True;
  
  Top := 230;
  Left := 280;

  Evcombo.Items.clear;
  Hocombo.Items.Clear;

  Evcombo.Clear;
  Hocombo.clear;

  evcombo.Items.add(inttostr(_maiev-1));
  evcombo.Items.Add(inttostr(_maiev));

  for i := 1 to 12 do Hocombo.Items.Add(_honev[i]);

  Evcombo.ItemIndex := _evindex;
  Hocombo.ItemIndex := _hoindex;

  _kertev   := _maiev - 1 + _evindex;
  _kertho   := 1 + _hoindex;

  _havinap := daysinamonth(_kertev,_kertho);
  Tolcombo.items.clear;
  Igcombo.Items.clear;

  for i := 1 to _havinap do
    begin
      Tolcombo.Items.Add(inttostr(i));
      Igcombo.Items.Add(inttostr(i));
    end;

  _tolindex := 0;
  _igIndex  := _havinap-1;

  Tolcombo.ItemIndex := _tolIndex;
  Igcombo.ItemIndex  := _igIndex;

  Fuggony.Visible := false;
  ActiveControl := RendbenGomb;
end;


// =============================================================================
              procedure TGETIDOSZAK.RENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  _evindex  := evcombo.ItemIndex;
  _hoIndex  := Hocombo.itemindex;
  _tolIndex := Tolcombo.itemindex;
  _igIndex  := IgCombo.ItemIndex;

  _kertev   := _maiev - 1 + _evindex;
  _kertho   := 1 + _hoindex;
  _tolnap   := 1 + _tolIndex;
  _ignap    := _tolnap + _igindex;

  _kezdonaps := inttostr(_kertev)+'.'+ Form1.Nulele(_kertho)+'.'+form1.Nulele(_tolnap);
  _vegsonaps := leftstr(_kezdonaps,8)+Form1.nulele(_ignap);
  if _kezdonaps>_vegsonaps then
    begin
      ShowMessage('ÉRVÉNYTELEN IDÕ INTERVALLUM');
      Modalresult := 2;
      exit;
    end;
  _farok := midstr(_kezdonaps,3,2)+midstr(_kezdonaps,6,2);
  _eTablanev := 'EFEJ' + _farok;


  Modalresult := 1;
end;

// =============================================================================
           procedure TGETIDOSZAK.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
           procedure TGETIDOSZAK.EVCOMBOChange(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _evIndex := Evcombo.Itemindex;
  _hoIndex := HoCombo.Itemindex;

  _ev := _maiev - 1 + _evIndex;
  _ho := 1 + _hoindex;
  _havinap := daysinamonth(_ev,_ho);

  Tolcombo.items.clear;
  Igcombo.Items.clear;

  for i := 1 to _havinap do
    begin
      tolcombo.Items.Add(inttostr(i));
      igcombo.Items.Add(inttostr(i));
    end;

  _tolindex := 0;
  _igIndex  := _havinap-1;

  Tolcombo.ItemIndex := _tolIndex;
  Igcombo.ItemIndex  := _igIndex;

  Activecontrol := rendbengomb;
end;

// =============================================================================
             procedure TGETIDOSZAK.TOLCOMBOChange(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _evindex  := Evcombo.Itemindex;
  _hoIndex  := Hocombo.itemindex;
  _tolIndex := Tolcombo.ItemIndex;

  _ev := _maiev-1+_evIndex;
  _ho := 1 + _hoindex;
  _havinap := daysinamonth(_ev,_ho);
  _tolnap := 1 + _tolindex;

  Igcombo.Items.clear;

  for i := _tolnap to _havinap do igcombo.Items.Add(inttostr(i));

  Igcombo.ItemIndex := 0;
  Activecontrol := rendbengomb;
end;

// =============================================================================
              procedure TGETIDOSZAK.IGCOMBOChange(Sender: TObject);
// =============================================================================

begin
  Activecontrol := Rendbengomb;
end;

end.
