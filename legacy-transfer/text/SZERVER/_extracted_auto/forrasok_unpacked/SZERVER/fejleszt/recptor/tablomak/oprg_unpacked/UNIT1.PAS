unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, strutils, dateutils;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    STARTGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    Label2: TLabel;
    DATUMEDIT: TEdit;
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure DATUMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure STARTGOMBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _munkanap,_mamas,_tegnaps: string;
  _munkadatum: TDateTime;


function makehavitablo(_para: string): integer; stdcall; external 'c:\receptor\maktablo.dll' name 'makehavitablo';


implementation

{$R *.dfm}

procedure TForm1.KILEPOGOMBClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.DATUMEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

begin
  if ord(key)<>13 then exit;

  _munkanap := datumedit.text;
  if _munkanap>=_mamas then exit;

  try
    _munkadatum := strtodate(_munkanap);
  except
     exit;
  end;

  Startgomb.Enabled := true;
  ActiveControl := startgomb;

end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  _mamas := leftstr(datetostr(now),10);
  _tegnaps := leftstr(dateTOstr(yesterday),10);
  Datumedit.Text := _tegnaps;
end;

procedure TForm1.STARTGOMBClick(Sender: TObject);
begin
  makehavitablo(_munkanap);
  Application.Terminate;
end;

end.
