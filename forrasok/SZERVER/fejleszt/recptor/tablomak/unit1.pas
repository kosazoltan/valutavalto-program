unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    MUNKANAPEDIT: TEdit;
    MEHETGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    Shape1: TShape;
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure MEHETGOMBClick(Sender: TObject);
    procedure MUNKANAPEDITEnter(Sender: TObject);
    procedure MUNKANAPEDITExit(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _munkanap: string;

function makehavitablo(_para: string): integer; stdcall; external 'c:\receptor\maktablo.dll' name 'makehavitablo';


implementation

{$R *.dfm}

procedure TForm1.MEGSEMGOMBClick(Sender: TObject);
begin
  aPPLICATION.TERMINATE;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
    ibdbase.Connected := true;
    with ibquery do
      begin
        close;
        Sql.clear;
        sql.add('SELECT * FROM RENDSZER');
        Open;
        _munkanap := FieldByName('MUNKANAP').asString;
        close;
      end;
    ibdbase.close;
    Munkanapedit.Text :=_munkanap;
    ActiveControl := MehetGomb;    
end;

procedure TForm1.MEHETGOMBClick(Sender: TObject);
begin
  _munkanap := MunkanapEdit.text;
  makehavitablo(_munkanap);
  Application.Terminate;
end;

procedure TForm1.MUNKANAPEDITEnter(Sender: TObject);
begin
  Munkanapedit.color := $b0ffff;
end;

procedure TForm1.MUNKANAPEDITExit(Sender: TObject);
begin
   Munkanapedit.Color := clwindow;
end;

end.
