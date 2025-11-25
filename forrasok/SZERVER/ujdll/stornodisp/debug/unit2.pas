unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons,unit1, DB, IBDatabase, IBCustomDataSet,
  IBTable, ExtCtrls, Grids, DBGrids, IBQuery;

type
  TSTORNODISPLAY = class(TForm)
    QuitGomb        : TBitBtn;
    visszagomb: TBitBtn;

    FejRacs         : TDBGrid;
    TetelPanel      : TPanel;
    TetelRacs       : TDBGrid;

    Label1          : TLabel;
    Label2          : TLabel;
    Label3          : TLabel;

    StornoTetelQuery: TIBQuery;
    StornoTetelDbase: TIBDatabase;
    StornoTetelTranz: TIBTransaction;

    StornoFejTabla  : TIBTable;
    StornoFejQuery  : TIBQuery;
    StornoFejDbase  : TIBDatabase;
    StornoFejTranz  : TIBTransaction;

    FejSource       : TDataSource;
    TetelSource     : TDataSource;

    Shape1          : TShape;
    Shape2          : TShape;


    Kilepo          : TTimer;
    masadatokgomb: TBitBtn;
    masegyseggomb: TBitBtn;
    masidoszakgomb: TBitBtn;

    StornoTetelQueryIrodaszam          : TIntegerField;
    StornoTetelQueryBizonylatszam      : TIBStringField;
    StornoTetelQueryValutanem          : TIBStringField;
    StornoTetelQueryBankjegy           : TFloatField;
    StornoTetelQueryForintertek        : TFloatField;
    StornoTetelQueryArfolyam           : TFloatField;
    StornoTetelQueryElszamolasiArfolyam: TFloatField;
    StornoTetelQueryCegbetu            : TIBStringField;


    procedure FormActivate(Sender: TObject);
    procedure QuitGombClick(Sender: TObject);
    procedure FejRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure visszagombClick(Sender: TObject);
    procedure TeteltValasztott;
    procedure FEJRACSDblClick(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure masadatokgombClick(Sender: TObject);
    procedure masegyseggombClick(Sender: TObject);
    procedure masidoszakgombClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  STORNODISPLAY: TSTORNODISPLAY;
  _pcs,_szuro,_biz: string;
  _irszam,_recno,_mResult: integer;
  _sorveg: string = chr(13)+chr(10);


function stornodisplayrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
               function stornodisplayrutin: integer; stdcall;
// =============================================================================

begin
  stornodisplay := TStornodisplay.Create(Nil);
  result := Stornodisplay.showmodal;
  Stornodisplay.Free;
end;

// =============================================================================
          procedure TSTORNODISPLAY.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := 230;
  Left := 208;

  TetelPanel.Visible := False;

  StornoTetelDbase.Connected := True;
  StornoFejDbase.connected   := True;

  _pcs := 'SELECT * FROM STORNOFEJ'+_sorveg;
  _pcs := _pcs + 'ORDER BY IRODASZAM';

  with StornoFejQuery do
    begin
      close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      ShowMessage('NEM VOLT STORNÓBIZONYLAT A KÉRT IDÖSZAKBAN');
      _mResult := 1;
      Kilepo.enabled := true;
      exit;
    end;

  Fejracs.SetFocus;
end;

// =============================================================================
           procedure TSTORNODISPLAY.QUITGOMBClick(Sender: TObject);
// =============================================================================

begin
  StornoFejTabla.Close;
  StornoTetelQuery.Close;
  ModalResult := 1;
end;

// =============================================================================
     procedure TSTORNODISPLAY.FEJRACSKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  TeteltValasztott;
end;

// =============================================================================
                   procedure TStornodisplay.TeteltValasztott;
// =============================================================================

begin
  _irszam := StornoFejQuery.FieldByName('IRODASZAM').asInteger;
  _biz    := StornofejQuery.FieldByName('BIZONYLATSZAM').asString;

  _pcs := 'SELECT * FROM STORNOTETEL' + _sorveg;
  _pcs := _pcs + 'WHERE (BIZONYLATSZAM='+chr(39)+_biz+chr(39)+') ';
  _pcs := _pcs + ' AND (IRODASZAM='+inttostr(_irszam)+')';

  with StornotetelQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  with TetelPanel do
    begin
      Top := 180;
      Left := 140;
      Visible := true;
    end;
  Activecontrol := TetelRacs;
end;

// =============================================================================
           procedure TSTORNODISPLAY.visszagombClick(Sender: TObject);
// =============================================================================

begin
  TetelPanel.Visible := False;
end;

// =============================================================================
           procedure TSTORNODISPLAY.FEJRACSDblClick(Sender: TObject);
// =============================================================================

begin
   TeteltValasztott;
end;

// =============================================================================
           procedure TSTORNODISPLAY.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  StornofejQuery.close;
  Stornofejdbase.close;

  stornoTeteldbase.close;
  StornoTetelquery.close;

  Modalresult := _mResult;

end;

// =============================================================================
           procedure TSTORNODISPLAY.masadatokgombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  Kilepo.Enabled := true;
end;

// =============================================================================
           procedure TSTORNODISPLAY.masegyseggombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 2;
  Kilepo.Enabled := true;
end;

// =============================================================================
           procedure TSTORNODISPLAY.masidoszakgombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 3;
  Kilepo.Enabled := true;
end;

end.
