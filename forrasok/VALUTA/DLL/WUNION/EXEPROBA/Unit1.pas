unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

function westernunionrutin: integer; stdcall; external 'c:\valuta\bin\wunion.dll' name 'westernunionrutin';


implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  westernunionrutin;
end;

end.
