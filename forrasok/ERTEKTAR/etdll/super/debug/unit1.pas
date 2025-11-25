unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    respanel: TPanel;
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _res: integer;

  _pwtipus: integer;

implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.Button3Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  _pwtipus := 1;
  _res := form2.showmodal;
  ResPanel.Caption := inttostr(_res);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
   _pwtipus := 0;
  _res := form2.showmodal;
  ResPanel.Caption := inttostr(_res);
end;

end.
