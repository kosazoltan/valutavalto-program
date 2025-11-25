unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label1: TLabel;
    resultpanel: TPanel;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _ok: integer;


function napiforgalomrutin: integer; stdcall; external 'c:\valuta\bin\napiforg.dll' name 'napiforgalomrutin';
  

implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _ok := napiforgalomrutin;
  resultpanel.caption := inttostr(_ok);
  resultpanel.repaint;
end;

end.
