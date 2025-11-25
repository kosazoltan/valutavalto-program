unit Unit27;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, Grids, DBGrids, ExtCtrls, IBDatabase,
  IBCustomDataSet, IBTable, unit1;

type
  TPENZTARKOZOTTIDISPLAY = class(TForm)
    BitBtn1: TBitBtn;
    PTKOZTTABLA: TIBTable;
    PTKOZTDBASE: TIBDatabase;
    PTKOZTTRANZ: TIBTransaction;
    Label1: TLabel;
    IDOSZAKPANEL: TPanel;
    PTKOZTRACS: TDBGrid;
    PTKOZTSOURCE: TDataSource;
    PTKOZTTABLAVALUTANEM: TIBStringField;
    PTKOZTTABLAKULDO: TIntegerField;
    PTKOZTTABLAFOGADO: TIntegerField;
    PTKOZTTABLAKULDOTT: TFloatField;
    PTKOZTTABLAFOGADOTT: TFloatField;
    PTKOZTTABLASTATUS: TIBStringField;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PENZTARKOZOTTIDISPLAY: TPENZTARKOZOTTIDISPLAY;

implementation

{$R *.dfm}

procedure TPENZTARKOZOTTIDISPLAY.BitBtn1Click(Sender: TObject);
begin
  PtkoztTabla.Close; 
  mODALRESULT := 1;
end;

procedure TPENZTARKOZOTTIDISPLAY.FormActivate(Sender: TObject);
begin
  Top := _top + 120;
  Left := _left + 140;
  Height := 530;
  Width := 750;
  
  IdoszakPanel.Caption := _idoszakLabel;

  PtkoztDbase.Close;
  PtkoztDbase.Connected := True;
  PtkoztTabla.open;
  PtKoztTabla.Refresh;
  PtkoztTabla.First;
end;

end.
