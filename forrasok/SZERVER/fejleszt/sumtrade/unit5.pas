unit Unit5;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Grids, DBGrids, DB,
  IBCustomDataSet, IBDatabase, IBQuery, unit1, IBTable;

type
  TEREDMENYKIJELZES = class(TForm)
    TRADESOURCE: TDataSource;
    TRADEQUERY: TIBQuery;
    TRADEDBASE: TIBDatabase;
    TRADETRANZ: TIBTransaction;
    DBGrid1: TDBGrid;
    TOLPANEL: TPanel;
    IGPANEL: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    BitBtn1: TBitBtn;
    Shape1: TShape;
    KILEPO: TTimer;
    TRADEQUERYPENZTAR: TIntegerField;
    TRADEQUERYSTATUS: TIBStringField;
    TRADEQUERYSZAMZARO: TIntegerField;
    TRADEQUERYZARO: TIntegerField;
    TRADEQUERYATVETEL: TIntegerField;
    TRADEQUERYATADAS: TIntegerField;
    TRADEQUERYTELEFON: TIntegerField;
    TRADEQUERYMATRICA: TIntegerField;
    TRADEQUERYNYITO: TIntegerField;
    TRADEQUERYIRODASZAM: TSmallintField;
    TRADEQUERYERTEKTAR: TSmallintField;
    TRADEQUERYVODAFON: TIntegerField;
    TRADEQUERYPAYSAFECARD: TIntegerField;
    TRADEQUERYTELENOR: TIntegerField;
    BitBtn2: TBitBtn;
    
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure TablaDisplay;
    procedure BitBtn2Click(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EREDMENYKIJELZES: TEREDMENYKIJELZES;

implementation

uses Unit3;

{$R *.dfm}

// =============================================================================
           procedure TEREDMENYKIJELZES.FormActivate(Sender: TObject);
// =============================================================================

begin
   top := 155;
   Left := 40;
   Tolpanel.Caption := _kezdonaps;
   igpanel.Caption  := _vegsonaps;
   Kilepo.enabled := false;

   Tolpanel.Repaint;
   IgPanel.Repaint;

  _pcs := 'SELECT * FROM SUMTRADE'+_sorveg;
  _pcs := _pcs + 'ORDER BY IRODASZAM,ERTEKTAR';

  Tradedbase.Connected := True;
  with Tradequery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
      close;
    end;
  Tradedbase.close;
  Kilepo.enabled := true;
end;



procedure TeredmenyKijelzes.TablaDisplay;

begin
  _pcs := 'SELECT * FROM SUMTRADE'+_sorveg;
  _pcs := _pcs + 'ORDER BY IRODASZAM,ERTEKTAR';

  Tradedbase.Connected := True;
  with Tradequery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;
  dbGrid1.Refresh;
  dbgrid1.Repaint;
  Activecontrol := Dbgrid1;
end;




// =============================================================================
          procedure TEREDMENYKIJELZES.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  Tradequery.close;
  TradeDbase.close;
  ModalResult := 1;
end;

procedure TEREDMENYKIJELZES.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  TablaDisplay;
end;



procedure TEREDMENYKIJELZES.BitBtn2Click(Sender: TObject);
begin
  Tradequery.close;
  TradeDbase.close;
  Mexcel.showmodal;
  Modalresult := 1;
end;

end.
