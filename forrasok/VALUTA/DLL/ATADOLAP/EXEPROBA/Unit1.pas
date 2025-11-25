unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


function atadolaprutin: integer; stdcall; external 'c:\valuta\dll\atadolap\makedll\atadolap.dll' name 'atadolaprutin';

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  atadolaprutin;
end;

end.
