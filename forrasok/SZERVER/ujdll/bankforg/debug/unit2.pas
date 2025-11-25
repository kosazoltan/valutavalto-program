unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, IBDatabase, IBCustomDataSet, IBTable, Grids, DBGrids,
  ExtCtrls, StdCtrls, Buttons, unit1, IBQuery, strutils;

type
  TBANKFORGALOMDISPLAY = class(TForm)
    QuitGomb             : TBitBtn;

    Label1               : TLabel;

    Idoszakpanel         : TPanel;

    ParaDBase            : TIBDatabase;
    ParaTranz            : TIBTransaction;

    BankQuery            : TIBQuery;
    BankDBase            : TIBDatabase;
    BankTranz            : TIBTransaction;
    Bankforgsource       : TDataSource;
    BankRacs             : TDBGrid;
    Shape1               : TShape;
    ParaQuery            : TIBQuery;
    Kilepo               : TTimer;

    MasAdatokGomb        : TBitBtn;
    MasEgysegGomb        : TBitBtn;
    MasikIdoszakGomb     : TBitBtn;
    BankQueryValutanem   : TIBStringField;
    BankQueryFelvettKP   : TFloatField;
    BankQueryBefizetettKp: TFloatField;
    BankQueryCegbetu     : TIBStringField;

    procedure QuitGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure ParameterBeolvasas;
    procedure KilepoTimer(Sender: TObject);
    procedure MasAdatokGombClick(Sender: TObject);
    procedure MasEgysegGombClick(Sender: TObject);
    procedure MasikIdoszakGombClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BANKFORGALOMDISPLAY: TBANKFORGALOMDISPLAY;
  _honev: array[1..12] of string = ('január','február','március','április',
                 'május','junius','július','augusztus','szeptember',
                          'október','november','december');
                          
  _pcs,_tolstring,_igstring,_evs,_hos,_tolnaps,_ignaps,_idsz: string;
  _mResult,_code: integer;
  _aktho,_tolnap,_ignap: word;
  _sorveg: string = chr(13)+chr(10);



function bankiforgdisplayrutin: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
           function bankiforgdisplayrutin: integer; stdcall;
// =============================================================================

begin
  BankForgalomDisplay := TBankforgalomDisplay.Create(Nil);
  result := Bankforgalomdisplay.Showmodal;
  Bankforgalomdisplay.Free;
end;

// =============================================================================
         procedure TBANKFORGALOMDISPLAY.QUITGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := -1;
  Kilepo.Enabled := True;
end;

// =============================================================================
          procedure TBANKFORGALOMDISPLAY.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := 230;
  Left := 208;
  ParameterBeOlvasas;

  _pcs := 'SELECT * FROM SUMBANKFORGALOM'+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  BankDbase.Connected := True;
  with BankQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
    end;
  BankRacs.SetFocus;
end;

// =============================================================================
                procedure TBankForgalomDisplay.ParameterBeolvasas;
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
           procedure TBankForgalomDisplay.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Paraquery.close;
  Paradbase.close;
  Modalresult := _mResult;
end;


// =============================================================================
      procedure TBANKFORGALOMDISPLAY.MASADATOKGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  Kilepo.Enabled := true;
end;

// =============================================================================
       procedure TBANKFORGALOMDISPLAY.MASEGYSEGGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 2;
  Kilepo.Enabled := true;
end;

// =============================================================================
    procedure TBANKFORGALOMDISPLAY.MASIKIDOSZAKGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 3;
  Kilepo.Enabled := true;
end;

end.
