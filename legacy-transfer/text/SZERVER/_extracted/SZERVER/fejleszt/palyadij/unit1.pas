unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, IBCustomDataSet, IBDatabase, IBQuery,
  Grids, DBGrids, jpeg, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    ALAPPANEL: TPanel;
    Image1: TImage;
    Label2: TLabel;
    RACS: TDBGrid;
    MQUERY: TIBQuery;
    MDBASE: TIBDatabase;
    MTRANZ: TIBTransaction;
    DataSource1: TDataSource;
    MQUERYPENZTAR: TSmallintField;
    MQUERYDATUM: TIBStringField;
    MQUERYIDO: TIBStringField;
    MQUERYMATRICATIPUS: TIBStringField;
    MQUERYFIZETENDO: TIntegerField;
    MQUERYUGYFELNEVE: TIBStringField;
    MQUERYUGYFELCIME: TIBStringField;
    MQUERYADOSZAMA: TIBStringField;
    MQUERYSENDEMAIL: TSmallintField;
    BitBtn1: TBitBtn;
    Image2: TImage;
    Label1: TLabel;
    procedure Button2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pcs: string;

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.terminate;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  top := 0;
  left := 0;
  width := 1380;
  height := 768;

  _pcs := 'SELECT * FROM AUTOPALYA ORDER BY DATUM,IDO';

  MDbase.Connected := true;
  with Mquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  Racs.SetFocus;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  Mquery.close;
  Mdbase.close;
  Application.Terminate;
end;

end.
