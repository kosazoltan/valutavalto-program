unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Panel1: TPanel;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _ok: integer;


function penztarosbeleptetes: integer; stdcall; external 'c:\valuta\bin\prosbe.dll' name 'penztarosbeleptetes';

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  aPPLICATION.TERMINATE;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  _OK := penztarosbeleptetes;
  Panel1.Caption := inttostr(_ok);
end;

end.
