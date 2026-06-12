unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


function arfolyamregiszter(_para:integer):integer;stdcall;external 'c:\valuta\bin\arfreg.dll' name 'arfolyamregiszter';


implementation

{$R *.dfm}

procedure TForm1.Button3Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  arfolyamregiszter(1);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  arfolyamregiszter(2);
end;

end.
