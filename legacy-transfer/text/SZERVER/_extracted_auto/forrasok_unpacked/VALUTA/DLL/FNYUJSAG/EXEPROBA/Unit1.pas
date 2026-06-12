unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


function  fenyujsagfrissito: integer; stdcall; external 'c:\valuta\bin\fnyujsag.dll' name 'fenyujsagfrissito'; 

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  fenyujsagfrissito;
  Application.Terminate;
end;

end.
