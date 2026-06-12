unit Unit30;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, IBDatabase, IBCustomDataSet, IBTable,
  Grids, DBGrids, unit1, ExtCtrls;

type
  TTRBDISPLAY = class(TForm)
    BitBtn1: TBitBtn;
    Label1: TLabel;
    TRBRACS: TDBGrid;
    TRBTABLA: TIBTable;
    trbdbase: TIBDatabase;
    TRBTRANZ: TIBTransaction;
    TRBSOURCE: TDataSource;
    TRBTABLAVALUTANEM: TIBStringField;
    TRBTABLAKULDO: TIntegerField;
    TRBTABLAFOGADO: TIntegerField;
    TRBTABLAKULDOTT: TFloatField;
    TRBTABLAFOGADOTT: TFloatField;
    TRBTABLASTATUS: TIBStringField;
    IDOSZAKPANEL: TPanel;
    Shape1: TShape;
    Shape2: TShape;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TRBDISPLAY: TTRBDISPLAY;

implementation

{$R *.dfm}

procedure TTRBDISPLAY.BitBtn1Click(Sender: TObject);
begin
  TRBtabla.Close;
  mODALRESULT := 1;
end;

procedure TTRBDISPLAY.FormActivate(Sender: TObject);
begin
  Top := _top + 120;
  Left := _left + 140;
  hEIGHT := 530;
  Width := 750;
  
  iDOSZAKpANEL.Caption := _IdoszakLabel;

  TRBDbase.close;
  TRBDbase.Connected := true;
  with TRBTabla do
    begin
      Open;
      Refresh;
      First;
    end;
  ActiveControl :=  trbrACS;
end;

end.
