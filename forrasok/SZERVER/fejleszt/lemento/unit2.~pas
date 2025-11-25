unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, DBTables, Grids, DBGrids, StdCtrls, ExtCtrls, Buttons, Unit1,
  IBDatabase, IBCustomDataSet, IBTable;

type
  TGYUJTESDISPLAY = class(TForm)
    Panel1: TPanel;
    TOLPANEL: TPanel;
    IGPANEL: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    FORRAS: TDataSource;
    racs: TDBGrid;
    BitBtn1: TBitBtn;
    LEMENTOTABLA: TIBTable;
    LEMENTODBASE: TIBDatabase;
    LEMENTOTRANZ: TIBTransaction;
    LEMENTOTABLADATUM: TIBStringField;
    LEMENTOTABLAIDO: TIBStringField;
    LEMENTOTABLABIZONYLATSZAM: TIBStringField;
    LEMENTOTABLABANKJEGY: TFloatField;
    LEMENTOTABLAVALUTANEM: TIBStringField;
    LEMENTOTABLAFORINTERTEK: TFloatField;
    LEMENTOTABLAKEDVEZOARFOLYAM: TFloatField;
    LEMENTOTABLAELSZAMOLASIARFOLYAM: TFloatField;
    LEMENTOTABLANEV: TIBStringField;
    LEMENTOTABLAAZONOSITO: TIBStringField;
    LEMENTOTABLASTORNO: TSmallintField;
    Panel2: TPanel;
    indito: TTimer;
    Shape1: TShape;

    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ListaGombClick(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GYUJTESDISPLAY: TGYUJTESDISPLAY;

implementation

{$R *.dfm}

procedure TGYUJTESDISPLAY.BitBtn1Click(Sender: TObject);
begin
  LementoTabla.Close;
  Forras.Enabled := False;
  ModalResult := 1;
end;

procedure TGYUJTESDISPLAY.FormCreate(Sender: TObject);
begin
  tOP := _TOP;
  lEFT := _left;
  HEIGHT := 485;
  WIDTH := 535;
  Panel2.Caption := _ptnev;
  Indito.enabled := true;
 
end;

procedure TGYUJTESDISPLAY.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if LementoTabla.Active then LementoTabla.Close;
  Forras.Enabled := False;
end;

procedure TGYUJTESDISPLAY.ListaGombClick(Sender: TObject);
begin
   Indito.Enabled := false;
   TolPanel.Caption := _tolDatumString;
   IgPanel.Caption := _igDatumString;

   LementoDbase.close;
   Lementodbase.DatabaseName := _lementoPath;
   LementoDbase.Connected := true;

   if lementoTranz.InTransaction then lementoTranz.Commit;
   With LementoTabla do
     begin
       Open;
       Refresh;
       First;
     end;
   Forras.Enabled := True;
   Racs.Visible := True;
   ActiveControl := racs;
end;



end.
