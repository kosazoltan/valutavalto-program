unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button4: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


function backuprestore: integer; stdcall; external 'c:\valuta\bin\mentes.dll' name 'backuprestore';  

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  backuprestore;
end;


procedure TForm1.Button4Click(Sender: TObject);
begin
  Application.Terminate;
end;

end.
