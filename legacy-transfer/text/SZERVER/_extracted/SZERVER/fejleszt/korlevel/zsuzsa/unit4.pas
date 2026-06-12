unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons;

type
  TGETVIPFORM = class(TForm)
    Panel1: TPanel;
    ALLGOMB: TBitBtn;
    Shape1: TShape;
    CHIEFGOMB: TBitBtn;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    procedure FormActivate(Sender: TObject);
    procedure ALLGOMBClick(Sender: TObject);
    procedure CHIEFGOMBClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETVIPFORM: TGETVIPFORM;
  _vheight,_vWidth,_vTop,_vLeft: word;

implementation

{$R *.dfm}

procedure TGETVIPFORM.FormActivate(Sender: TObject);
begin

  Top := 380;
  Left:= 350;

  Activecontrol := Allgomb;

end;

procedure TGETVIPFORM.ALLGOMBClick(Sender: TObject);
begin
  ModalResult := 1;
end;

procedure TGETVIPFORM.CHIEFGOMBClick(Sender: TObject);
begin
  Modalresult := 3;
end;

procedure TGETVIPFORM.BitBtn1Click(Sender: TObject);
begin
  Modalresult := 2;
end;



procedure TGETVIPFORM.BitBtn2Click(Sender: TObject);
begin
  Modalresult := -1;
end;

end.
