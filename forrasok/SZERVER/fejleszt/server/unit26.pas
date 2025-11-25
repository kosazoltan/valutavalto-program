unit Unit26;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, IBDatabase, IBCustomDataSet, IBTable, Grids, DBGrids,
  ExtCtrls, StdCtrls, Buttons, unit1;

type
  TBANKFORGALOMDISPLAY = class(TForm)
    BitBtn1: TBitBtn;
    Label1: TLabel;
    idoszakpanel: TPanel;
    BANKFORGTABLA: TIBTable;
    BANKFORGDBASE: TIBDatabase;
    BANKFORGTRANZ: TIBTransaction;
    bankforgsource: TDataSource;
    DBGrid1: TDBGrid;
    BANKFORGTABLAVALUTANEM: TIBStringField;
    BANKFORGTABLAFELVETTKP: TFloatField;
    BANKFORGTABLABEFIZETETTKP: TFloatField;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BANKFORGALOMDISPLAY: TBANKFORGALOMDISPLAY;

implementation

{$R *.dfm}

procedure TBANKFORGALOMDISPLAY.BitBtn1Click(Sender: TObject);
begin
  BankForgTabla.Close;
  ModalResult := 1;
end;

procedure TBANKFORGALOMDISPLAY.FormActivate(Sender: TObject);
begin
  Top := _top +195;
  Left := _left + 170;
  IdoszakPanel.Caption := _idoszakLabel;
  BankForgDbase.Close;
  BankforgDbase.Connected := True;
  BankForgtabla.Open;
  BankForgTabla.Refresh;
  BankForgtabla.First;
end;

end.
