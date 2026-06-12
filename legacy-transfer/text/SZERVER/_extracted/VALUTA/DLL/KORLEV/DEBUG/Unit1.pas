unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _kortype: byte;

implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  APPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _korType := 1;
  Korlevel.SHOWMODAL;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  _kortype := 2;
  Korlevel.showmodal;
end;



end.
