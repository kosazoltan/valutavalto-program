unit Unit22;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons,unit1, DB, IBDatabase, IBCustomDataSet,
  IBTable, ExtCtrls, Grids, DBGrids;

type
  TSTORNODISP = class(TForm)
    BitBtn1: TBitBtn;
    Label1: TLabel;
    FEJRACS: TDBGrid;
    TETELPANEL: TPanel;
    TETELRACS: TDBGrid;
    BitBtn2: TBitBtn;
    Label2: TLabel;
    STORNOTETELTABLA: TIBTable;
    STORNOTETELDBASE: TIBDatabase;
    STORNOTETELTRANZ: TIBTransaction;
    STORNOFEJTABLA: TIBTable;
    STORNOFEJDBASE: TIBDatabase;
    STORNOFEJTRANZ: TIBTransaction;
    FEJSOURCE: TDataSource;
    TETELSOURCE: TDataSource;
    STORNOTETELTABLAIRODASZAM: TIntegerField;
    STORNOTETELTABLABIZONYLATSZAM: TIBStringField;
    STORNOTETELTABLAVALUTANEM: TIBStringField;
    STORNOTETELTABLABANKJEGY: TFloatField;
    STORNOTETELTABLAFORINTERTEK: TFloatField;
    Shape1: TShape;
    Shape2: TShape;
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FEJRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BitBtn2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  STORNODISP: TSTORNODISP;

implementation

{$R *.dfm}

procedure TSTORNODISP.FormActivate(Sender: TObject);
begin
  Top := _top + 128;
  Left := _left + 148;
  Height := 514;
  Width := 734;

  TetelPanel.Visible := false;

  StornoTetelDbase.close;
  stornoTetelDbase.Connected := true;
  with stornoTetelTabla do
    begin
      Open;
      Refresh;
    end;

  StornoFejdbase.close;
  StornoFejDbase.connected := true;
  with StornoFejtabla do
    begin
      Open;
      Refresh;
      First;
    end;
  if stornofejTabla.Eof then
    begin
      ShowMessage('NEM VOLT STORNÓBIZONYLAT A KÉRT IDÖSZAKBAN');
      STORNOFejTabla.close;
      StornoTetelTabla.Close;
      ModalResult := 1;
      exit;
    end;

  activeControl := fejRacs;

end;

procedure TSTORNODISP.BitBtn1Click(Sender: TObject);
begin
  StornoFejTabla.Close;
  StornoTeteltabla.Close;
  ModalResult := 1;
end;

procedure TSTORNODISP.FEJRACSKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var _biz: string;
begin
  if ord(key)<>13 then exit;
  _irszam := StornoFejTabla.FieldByName('IRODASZAM').asInteger;
  _biz := StornofejTabla.FieldByName('BIZONYLATSZAM').asString;
  _szuro := '(BIZONYLATSZAM='+chr(39)+_biz+chr(39);
  _szuro := _szuro + ') AND (IRODASZAM='+INTTOSTR(_IRSZAM)+')';
  with StornoTetelTabla do
    begin
      Filtered := false;
      Filter := _szuro;
      Filtered := True;
      First;
    end;
    
  with TetelPanel do
    begin
      Top := 110;
      Left := 80;
      Visible := true;
    end;
  Activecontrol := TetelRacs;
end;

procedure TSTORNODISP.BitBtn2Click(Sender: TObject);
begin
  TetelPanel.Visible := False; 
end;

end.
