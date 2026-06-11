unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    SSEDIT: TEdit;
    Label1: TLabel;
    BACKPANEL: TPanel;
    Label2: TLabel;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _cimss: string;
  _cim: byte;
  _back,_code: integer;


function kcimletrutin(_para: byte): integer; stdcall; external
           'c:\valuta\bin\kcimlet.dll' name 'kcimletrutin';  

implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  BACKPANEL.Caption := '';
  _cimss := trim(Ssedit.Text);
  val(_cimss,_cim,_code);
  if _code<>0 then _cim := 0;
  if (_cim=0) or (_cim>27) then exit;
  _back := kcimletrutin(_cim);
  Backpanel.caption := inttostr(_back);

end;

end.
