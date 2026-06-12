unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TKELLCIMLET = class(TForm)
    alappanel: TPanel;
    Shape1: TShape;
    Label1: TLabel;
    KELLGOMB: TBitBtn;
    NEMKELLGOMB: TBitBtn;
    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KELLGOMBClick(Sender: TObject);
    procedure NEMKELLGOMBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KELLCIMLET: TKELLCIMLET;
  _top,_left,_width,_height: word;

implementation

{$R *.dfm}

procedure TKELLCIMLET.Button1Click(Sender: TObject);
begin
  mODALRESULT := 1;
end;

procedure TKELLCIMLET.FormActivate(Sender: TObject);
begin

  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].width;

  _top    := trunc((_height-110)/2);
  _left   := Trunc((_width-390)/2);

  Top := _top;
  Left := _left;

  Height := 110;
  Width  := 390;

  Activecontrol := Nemkellgomb;

end;

procedure TKELLCIMLET.KELLGOMBClick(Sender: TObject);
begin
  Modalresult := 1;
end;

procedure TKELLCIMLET.NEMKELLGOMBClick(Sender: TObject);
begin
  Modalresult :=2;
end;

end.
