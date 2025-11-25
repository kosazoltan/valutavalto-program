unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1, dateUtils,Strutils;

type
  TIDOSZAKKEROFORM = class(TForm)
    Shape1: TShape;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    TOLNAPCOMBO: TComboBox;
    IGNAPCOMBO: TComboBox;
    IDOSZAKOKEGOMB: TBitBtn;
    KILEPESGOMB: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;

    procedure FormActivate(Sender: TObject);
    procedure KILEPESGOMBClick(Sender: TObject);
    procedure evcomboChange(Sender: TObject);
    procedure TOLNAPCOMBOChange(Sender: TObject);
    procedure IGNAPCOMBOChange(Sender: TObject);
    procedure napCombokToltese;
    procedure Ignaptolto;
    procedure IDOSZAKOKEGOMBClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  IDOSZAKKEROFORM: TIDOSZAKKEROFORM;

implementation

uses Unit2;

{$R *.dfm}

procedure TIDOSZAKKEROFORM.FormActivate(Sender: TObject);

var i: integer;

begin
  Top    := _top +336;
  Left   := _left +224;
  Width  := 537;
  Height := 169;

  _aktev := yearof(date);
  _aktho := monthof(date);
  _aktnap := dayof(date);
  _fullMonth := False;

  evcombo.clear;
  evcombo.Items.Clear;
  for i := -2 to 0 do evcombo.Items.add(inttostr(_aktev+i));
  evcombo.ItemIndex := 2;
  _Kertev := _aktev;

  hocombo.clear;
  hocombo.Items.clear;
  for i := 1 to 12 do Hocombo.Items.add(_honev[i]);
  hocombo.itemindex := _aktho-1;
  _kertho := _aktho;
  Tolnapcombo.Items.clear;
  Ignapcombo.Items.clear;

  Napcomboktoltese;
  Activecontrol := idoszakokegomb;
end;

procedure TIDOSZAKKEROFORM.KILEPESGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;

procedure TIdoszakkeroForm.evcomboChange(Sender: TObject);
begin
  _evindex := evcombo.itemindex;
  _hoindex := hocombo.itemindex;
  _kertev := _aktev + _evindex - 2;
  _kertho := 1 + _hoindex;
  Napcomboktoltese;
  Activecontrol := idoszakokegomb;
end;

procedure TIdoszakKeroForm.TOLNAPCOMBOChange(Sender: TObject);
begin
  _tolindex := tolnapcombo.itemindex;
  _kerttolnap := 1 + _tolindex;
  IgnapTolto;
  ActiveControl := idoszakokegomb;
end;

procedure TIdoszakKeroForm.IGNAPCOMBOChange(Sender: TObject);
begin
  Activecontrol := idoszakokegomb;
end;

procedure TIdoszakkeroForm.napCombokToltese;

var i: integer;

begin
  _utolsonap := daysinamonth(_kertev,_kertho);
  tolnapcombo.Clear;

  for i := 1 to _utolsonap do tolnapcombo.items.add(inttostr(i));
  Tolnapcombo.itemindex :=0;
  _kerttolnap := 1;
  Ignaptolto;
end;

procedure TIdoszakKeroForm.Ignaptolto;

var i: integer;

begin
  ignapcombo.clear;
  for i := _kerttolnap to _utolsonap do ignapcombo.items.add(inttostr(i));
  ignapcombo.itemindex := _utolsonap-_kerttolnap;
end;





procedure TIDOSZAKKEROFORM.IDOSZAKOKEGOMBClick(Sender: TObject);
begin
  _evindex := evcombo.itemindex;
  _hoindex := hocombo.itemindex;
  _tolindex := tolnapcombo.itemindex;
  _igindex := ignapcombo.itemindex;

  _kertev := _evindex + _aktev -2;
  _kertho := 1 + _hoindex;
  _tolnap := 1 + _tolindex;
  _ignap  := _tolnap + _igindex;

  _kdatums := inttostr(_kertev)+'.'+Form1.Nulele(_kertho)+'.'+Form1.Nulele(_tolnap);
  _vDatums := leftstr(_kdatums,8)+Form1.Nulele(_ignap);

  if (_ignap=_utolsonap) and (_tolnap=1) then _fullMonth := true;
  _farok := Form1.nulele(_kertev-2000)+Form1.nulele(_kertho);

  ModalResult := 1;
end;

end.
