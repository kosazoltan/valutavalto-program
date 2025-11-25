unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, IBDatabase, IBCustomDataSet, IBTable,
  Grids, DBGrids, unit1, ExtCtrls, IBQuery, strutils;

type
  TTRBDISPLAY = class(TForm)

    Label1        : TLabel;
    TRBRacs       : TDBGrid;

    TRBSource     : TDataSource;

    IdoszakPanel  : TPanel;
    Shape1        : TShape;
    Shape2        : TShape;

    TRBQuery      : TIBQuery;
    TRBDbase      : TIBDatabase;
    TRBTranz      : TIBTransaction;

    ParaQuery     : TIBQuery;
    ParaDbase     : TIBDatabase;
    ParaTranz     : TIBTransaction;

    MasAdatGomb   : TBitBtn;
    MasEgysegGomb : TBitBtn;
    MasIdoszakGomb: TBitBtn;
    QuitGomb      : TBitBtn;

    Kilepo        : TTimer;
    TRBQUERYVALUTANEM: TIBStringField;
    TRBQUERYKULDO: TIntegerField;
    TRBQUERYFOGADO: TIntegerField;
    TRBQUERYKULDOTT: TFloatField;
    TRBQUERYFOGADOTT: TFloatField;
    TRBQUERYSTATUS: TIBStringField;
    TRBQUERYCEGBETU: TIBStringField;
    TRBTABLA: TIBTable;

    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure MasAdatGombClick(Sender: TObject);
    procedure MasEgysegGombClick(Sender: TObject);
    procedure MasIdoszakGombClick(Sender: TObject);
    procedure ParameterBeolvasas;
    procedure QuitGombClick(Sender: TObject);
    procedure StatuszBeiro;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TRBDISPLAY: TTRBDISPLAY;

  _honev: array[1..12] of string = ('január','február','március','április',
                 'május','junius','július','augusztus','szeptember',
                          'október','november','december');

  _pcs,_tolstring,_igstring,_evs,_hos,_tolnaps,_ignaps,_idsz,_cegnev: string;

  _aktho,_ignap,_tolnap,_bss: word;
  _code,_mResult: integer;


// =============================================================================
              function trbforgdisplayrutin: integer; stdcall;
// =============================================================================


implementation

{$R *.dfm}

// =============================================================================
             function trbforgdisplayrutin: integer; stdcall;
// =============================================================================

begin
  trbdisplay := TTrbdisplay.Create(Nil);
  result := trbdisplay.showmodal;
  trbdisplay.free;
end;

// =============================================================================
           procedure TTRBDISPLAY.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := 230;
  Left := 208;

  parameterbeolvasas;

  Statuszbeiro;

  _pcs := 'SELECT * FROM TRBGYUJTO';

  TrbDbase.Connected := true;
  with TrbQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  TRBRacs.SetFocus;
end;


// =============================================================================
                procedure TTRBDisplay.ParameterBeolvasas;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ADATATADO';

  ParaDbase.Connected := True;
  with ParaQuery do
    begin
      Close;
      Sql.clear;
      sql.add('SELECT * FROM IDOSZAK');
      Open;

      _tolstring := FieldByName('STARTDATE').asString;
      _igstring := FieldByName('ENDDATE').asString;
      Close;
    end;
  Paradbase.close;

  _evs     := leftstr(_tolstring,4);
  _hos     := midstr(_tolstring,6,2);
  _tolnaps := midstr(_tolstring,9,2);
  _ignaps  := midstr(_igstring,9,2);

  val(_hos,_aktho,_code);
  val(_tolnaps,_tolnap,_code);
  val(_ignaps,_ignap,_code);

  _idsz := _evs + ' '+_honev[_aktho] + ' ' + inttostr(_tolnap)+' - '+inttostr(_ignap);
  IdoszakPanel.Caption := _idsz;
  IdoszakPanel.repaint;
end;

// =============================================================================
         procedure TTRBDisplay.QuitGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := -1;
  Kilepo.enabled := True;
end;

// =============================================================================
           procedure TTRBDisplay.MasAdatGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult :=1;
  Kilepo.enabled := True;
end;

// =============================================================================
           procedure TTRBDISPLAY.MasEgysegGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 2;
  Kilepo.enabled := True;
end;

// =============================================================================
          procedure TTRBDISPLAY.MasIdoszakGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 3;
  Kilepo.enabled := True;
end;

// =============================================================================
            procedure TTRBDisplay.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  TRBQuery.Close;
  TRBDbase.close;
  ModalResult := _mResult;
end;

// =============================================================================
          procedure TtrbDisplay.Statuszbeiro;
// =============================================================================

var _status: string;
    _kuldott,_fogadott: integer;

begin
  trbdbase.connected := True;
  if Trbtranz.InTransaction then TRBtranz.commit;
  TRBTRANZ.StartTransaction;
  TRBtabla.close;
  TRBtabla.TableName := 'TRBGYUJTO';
  TRBTabla.Open;
  while not TRBtabla.Eof do
    begin
      _kuldott := TRBtabla.FieldByName('KULDOTT').asInteger;
      _fogadott:= TRBtabla.FieldByName('FOGADOTT').asInteger;
      if _kuldott=_fogadott then _status := 'OK' else _status := '?';
      TRBtabla.edit;
      TRBtabla.FieldByName('STATUS').AsString := _status;
      TRBtabla.Post;
      TRBTabla.next;
    end;
  TRBTranz.commit;
  TRBdbase.close;
  TRBtabla.close;
end;
end.
