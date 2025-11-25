unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, strutils, dateutils;

type
  TForm1 = class(TForm)
    startgomb: TButton;
    QUITGOMB: TButton;
    Label1: TLabel;
    DATUMEDIT: TEdit;
    Label2: TLabel;
    Shape1: TShape;
    procedure QUITGOMBClick(Sender: TObject);
    procedure startgombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _munkanap,_tegnaps: string;

implementation

uses Unit2;

{$R *.dfm}

procedure TForm1.QUITGOMBClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.startgombClick(Sender: TObject);
begin
  _munkanap := trim(Datumedit.Text);
  if length(_munkanap)<10 then
    begin
      Datumedit.Text := '';
      Activecontrol := datumedit;
      exit;
    end;
  UjTabloKeszites.Showmodal;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  _tegnaps := leftstr(datetostr(yesterday),10);
  DatumEdit.Text := _Tegnaps;
  Activecontrol := StartGomb;
end;


end.
