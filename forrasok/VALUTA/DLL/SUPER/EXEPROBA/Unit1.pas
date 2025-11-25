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
    Button3: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _oke: integer;

function supervisorjelszo(_para: integer): integer; stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  _oke := supervisorjelszo(0);
  if _oke=1 then Showmessage('A JELSZÓT ELTALÁLTAD')
  else Showmessage('NEM ISMERED A JELSZÓT !');
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
   _oke := supervisorjelszo(1);
  if _oke=1 then Showmessage('A JELSZÓT ELTALÁLTAD')
  else Showmessage('NEM ISMERED A JELSZÓT !');
end;

end.
