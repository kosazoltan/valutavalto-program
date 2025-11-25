unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, Grids, DBGrids, ExtCtrls, IBDatabase,
  IBCustomDataSet, IBTable, unit1, IBQuery,strutils;

type
  TPENZTARKOZOTTIDISPLAY = class(TForm)

    ParaQuery     : TIBQuery;
    ParaDbase     : TIBDatabase;
    ParaTranz     : TIBTransaction;

    Label1        : TLabel;

    IdoszakPanel  : TPanel;

    PTKoztRacs    : TDBGrid;
    PtKoztSource  : TDataSource;

    Shape1        : TShape;

    MasAdatokGomb : TBitBtn;
    MasEgysegGOMB : TBitBtn;
    MasIdoszakGOMB: TBitBtn;
    QuitGomb      : TBitBtn;

    Kilepo        : TTimer;
    PARAQUERYVALUTANEM: TIBStringField;
    PARAQUERYKULDO: TIntegerField;
    PARAQUERYFOGADO: TIntegerField;
    PARAQUERYKULDOTT: TFloatField;
    PARAQUERYFOGADOTT: TFloatField;
    PARAQUERYSTATUS: TIBStringField;
    PARAQUERYKULDODNEMFOGADO: TIBStringField;
    PARATABLA: TIBTable;

    procedure FormActivate(Sender: TObject);
    procedure ParameterBeolvasas;
    procedure QuitGombClick(Sender: TObject);
    procedure StatuszBeiro;

    procedure MasAdatokGombClick(Sender: TObject);
    procedure MasEgysegGombClick(Sender: TObject);
    procedure MasIdoszakGombClick(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PENZTARKOZOTTIDISPLAY: TPENZTARKOZOTTIDISPLAY;

  _irodanev: array[1..180] of string;
  _korzetszam: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _korzetnev: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
           'DEBRECEN','NYIREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR','ZÁLOG');

  _honev: array[1..12] of string = ('január','február','március','április',
                 'május','junius','július','augusztus','szeptember',
                          'október','november','december');

  _betusor: array[1..4] of string = ('B','P','E','Z');

  _cegnevsor: array[1..4] of string =('BEST CHANGE','PANNON CHANGE','EAST CHANGE',
                                           'EXPRESSZ ZÁLOG');

  _pcs,_filter,_aktcegbetu,_tolstring,_igstring,_evs,_hos: string;
  _tolnaps,_ignaps,_idsz,_aktegyseg,_cegnev: string;
  _sorveg: string = chr(13)+chr(10);
  _egysegtipus,_aktkorzet,_aktpenztar,_code,_mResult: integer;
  _aktho,_tolnap,_ignap,_bss,_korzss: word;

function ptkforgdisplayrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
          function ptkforgdisplayrutin: integer; stdcall;
// =============================================================================

begin
  penztarkozottidisplay := TPenztarKozottiDisplay.create(Nil);
  result := penztarkozottidisplay.showmodal;
  penztarkozottidisplay.free;
end;


// =============================================================================
        procedure TPenztarKozottiDisplay.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := 230;
  Left := 208;

  StatuszBeiro;

  _pcs := 'SELECT * FROM PENZTARKOZOTT' + _sorveg;
  _pcs := _pcs + 'ORDER BY KULDO';

  ParaDbase.Connected := True;
  with ParaQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;
  ptkoztSource.Enabled := true;
  PtKoztracs.setfocus;
end;

// =============================================================================
                procedure TPenztarKozottiDisplay.ParameterBeolvasas;
// =============================================================================

begin
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
        procedure TPenztarKozottiDisplay.MasAdatokGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  Kilepo.enabled := True;
end;

// =============================================================================
       procedure TPenztarKozottiDisplay.MasEgysegGombClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 2;
  Kilepo.enabled := True;
end;

// =============================================================================
        procedure TPenztarKozottiDisplay.MasIdoszakGombClick(Sender: TObject);
// =============================================================================

begin
  _mresult := 3;
  Kilepo.enabled := True;
end;

// =============================================================================
         procedure TPenztarKozottiDisplay.QuitGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := -1;
  Kilepo.enabled := true;
end;


// =============================================================================
          procedure TPenztarKozottiDisplay.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  ParaQuery.close;
  ParaDbase.close;
  Modalresult := _mResult;
end;

// =============================================================================
          procedure TPenztarKozottiDisplay.Statuszbeiro;
// =============================================================================

var _status: string;
    _kuldott,_fogadott: integer;

begin
  Paradbase.connected := True;
  if paratranz.InTransaction then paratranz.commit;
  PARATRANZ.StartTransaction;
  Paratabla.close;
  Paratabla.TableName := 'PENZTARKOZOTT';
  ParaTabla.Open;
  while not Paratabla.Eof do
    begin
      _kuldott := Paratabla.FieldByName('KULDOTT').asInteger;
      _fogadott:= Paratabla.FieldByName('FOGADOTT').asInteger;
      if _kuldott=_fogadott then _status := 'OK' else _status := '?';
      Paratabla.edit;
      Paratabla.FieldByName('STATUS').AsString := _status;
      Paratabla.Post;
      ParaTabla.next;
    end;
  ParaTranz.commit;
  Paradbase.close;
  Paratabla.close;
end;

end.
