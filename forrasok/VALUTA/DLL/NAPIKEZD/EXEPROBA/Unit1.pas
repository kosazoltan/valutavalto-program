unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    RESULTPANEL: TPanel;
    Label1: TLabel;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _ok : integer;

function napikezdijrutin: integer; stdcall; external 'c:\valuta\bin\napikezd.dll' name 'napikezdijrutin';


implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
   _OK := napikezdijrutin;
   resultPanel.Caption := inttostr(_ok);
   resultPanel.repaint;
end;

end.
