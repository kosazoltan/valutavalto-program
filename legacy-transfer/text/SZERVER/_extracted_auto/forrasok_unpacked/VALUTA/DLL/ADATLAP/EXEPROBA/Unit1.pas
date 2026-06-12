unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Label1: TLabel;
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
  _oke: integer;

function adatlaprutin: integer; stdcall; external 'c:\valuta\bin\Adatlap.dll' name 'adatlaprutin';

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  _oke := adatlaprutin;
  if _oke=1 then showmessage('ADATLAPOK RENDBEN') ELSE ShowMessage('HIBA');
end;

end.
