unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    startgomb: TBitBtn;
    MESSEDIT: TEdit;
    procedure startgombClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure MESSEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MESSEDITEnter(Sender: TObject);
    procedure MESSEDITExit(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _mess: string;
  _messpara: pchar;


function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll'
                                        name 'logirorutin';

implementation

{$R *.dfm}

procedure TForm1.startgombClick(Sender: TObject);
begin
  _MESS := TRIM(MESSEDIT.Text);
  if _mess<>'' then
    begin
      _messpara := pchar(_mess);
      logirorutin(_messpara);
      messedit.clear;
    end;
   Activecontrol := messedit;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  Messedit.clear;
  activecontrol := messedit;
end;

procedure TForm1.MESSEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  Activecontrol := startgomb;

end;

procedure TForm1.MESSEDITEnter(Sender: TObject);
begin
   Messedit.Color := clYellow;
end;

procedure TForm1.MESSEDITExit(Sender: TObject);
begin
  Messedit.Color := clWindow;
end;

end.
