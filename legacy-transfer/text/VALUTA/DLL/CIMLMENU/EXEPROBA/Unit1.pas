unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Panel1: TPanel;
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
  _back: integer;


function cimletmenurutin: integer; stdcall; external
                     'c:\valuta\bin\cimlmenu.dll' name 'cimletmenurutin';
                     

implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  aPPlication.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _back := cimletmenurutin;
  Panel1.caption := inttostr(_back);
end;

end.
