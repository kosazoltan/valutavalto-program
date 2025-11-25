unit Unit7;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, DBTables, Grids, Buttons, ExtCtrls, Unit1,
  IBDatabase, IBCustomDataSet, IBTable, DBGrids;

type
  THIBAKDISPLAY = class(TForm)
    Panel1: TPanel;
    VISSZAGOMB: TBitBtn;
    Label1: TLabel;
    HIBAKTABLA: TIBTable;
    HIBAKDBASE: TIBDatabase;
    HIBAKTRANZ: TIBTransaction;
    HIBAKRACS: TDBGrid;
    HIBAKSource: TDataSource;
    HIBAKTABLAIRODA: TIntegerField;
    HIBAKTABLAIRODANEV: TIBStringField;
    HIBAKTABLAVALUTANEM: TIBStringField;
    HIBAKTABLAELTERES: TFloatField;
    Shape1: TShape;
    Shape2: TShape;

    procedure FormActivate(Sender: TObject);
    procedure VISSZAGOMBClick(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HIBAKDISPLAY: THIBAKDISPLAY;

  _cells,_uzlet,_rcount: integer;
  _aktPtnev,_ht: string;

implementation

{$R *.dfm}



procedure THIBAKDISPLAY.FormActivate(Sender: TObject);

begin
  top := _top +120;
  Left := _left +140;
  height := 530;
  Width := 750;
  _rcount := 10;

  HibakDbase.Close;
  HibakDbase.Connected := true;
  HibakTabla.Open;
  HibakTabla.Refresh;
  HibakTabla.First;

  Activecontrol := HibakRacs;
  HibakRacs.SetFocus;
end;

procedure THIBAKDISPLAY.VISSZAGOMBClick(Sender: TObject);
begin
  HibakTabla.close;
  ModalResult := 1;
end;



end.
