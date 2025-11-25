unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, jpeg, ExtCtrls;

type
  TForm1 = class(TForm)
    KILEPOGOMB: TBitBtn;
    Image1: TImage;
    Label1: TLabel;
    STARTGOMB: TBitBtn;
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure STARTGOMBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


function horvatkunarutinok: integer; stdcall; external 'c:\receptor\newdll\hrk.dll';  

implementation

{$R *.dfm}

procedure TForm1.KILEPOGOMBClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.STARTGOMBClick(Sender: TObject);
begin
  horvatkunarutinok;
end;

end.
