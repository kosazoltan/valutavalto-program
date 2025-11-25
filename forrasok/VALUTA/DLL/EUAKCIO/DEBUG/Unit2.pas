unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    IGENGOMB: TBitBtn;
    NEMGOMB: TBitBtn;
    Shape1: TShape;

    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure IGENGOMBClick(Sender: TObject);
    procedure NEMGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _top,_left,_height,_width: word;

implementation

{$R *.dfm}

procedure TForm2.Button1Click(Sender: TObject);
begin
  mODALRESULT := 1;
end;

procedure TForm2.FormActivate(Sender: TObject);
begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  top := _top + 320;
  left := _left +320;

  ActiveControl := IgenGomb;
end;


procedure TForm2.IGENGOMBClick(Sender: TObject);
begin
  Modalresult := 1;
end;

procedure TForm2.NEMGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;

end.
