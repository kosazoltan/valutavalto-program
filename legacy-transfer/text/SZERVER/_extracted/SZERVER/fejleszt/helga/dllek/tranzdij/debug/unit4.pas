unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, unit2;

type
  Thovalasztoform = class(TForm)
    EVCOMBO: TComboBox;
    HONAPCOMBO: TComboBox;
    Label1: TLabel;
    HOOKEGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    Shape1: TShape;
    BANDISP: TCheckBox;
    procedure FormActivate(Sender: TObject);
    procedure HOOKEGOMBClick(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  hovalasztoform: Thovalasztoform;
  _hHeight,_hWidth: word;

implementation

{$R *.dfm}

procedure Thovalasztoform.FormActivate(Sender: TObject);

var i: integer;

begin
   _hWidth  := Screen.Monitors[0].Width;
   _hHeight := screen.Monitors[0].Height;

    Top := trunc((_Hheight-232)/2);
   Left := trunc((_hWidth-424)/2);


  evcombo.items.clear;
  evcombo.clear;

  for i := -2 to 0 do evcombo.items.add(inttostr(_aktev+i));

  Honapcombo.items.clear;
  Honapcombo.clear;

  for i := 1 to 12 do honapcombo.items.add(_honev[i]);

  evcombo.itemindex := 2;
  Honapcombo.itemindex := _aktho-1;

  ActiveControl := HoOkeGomb;
end;

procedure Thovalasztoform.HOOKEGOMBClick(Sender: TObject);
begin
  _kertev := (_aktev-2) + (evCombo.ItemIndex);
  _kerthonap := 1 + (Honapcombo.itemindex);
  if Bandisp.Checked then _bandisp := true;
  ModalResult := 1;
end;

procedure Thovalasztoform.MEGSEMGOMBClick(Sender: TObject);
begin
  ModalResult := 2;
end;

procedure Thovalasztoform.EVCOMBOChange(Sender: TObject);
begin
  ActiveControl := HoOkeGomb;
end;

end.
