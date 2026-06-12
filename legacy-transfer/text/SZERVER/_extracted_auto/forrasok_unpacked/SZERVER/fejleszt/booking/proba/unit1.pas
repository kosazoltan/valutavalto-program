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
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


function advetexcelrutin: integer; stdcall; external 'c:\booking\advetex.dll';
function forgalomexcelrutin: integer; stdcall; external 'c:\booking\forgex.dll';  

implementation

{$R *.dfm}

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  advetexcelrutin;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  forgalomexcelrutin;
end;

end.
