unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Shape1: TShape;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

function pillkeszletbekuldo:integer;stdcall; external 'c:\valuta\bin\keszup.dll' name 'pillkeszletbekuldo';

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  pillkeszletbekuldo;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

end.
