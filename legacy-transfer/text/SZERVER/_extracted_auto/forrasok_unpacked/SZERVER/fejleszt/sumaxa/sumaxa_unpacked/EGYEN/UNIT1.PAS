unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBQuery, IBDatabase, DB, IBCustomDataSet, IBTable;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    IBTABLA: TIBTable;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    IBQuery: TIBQuery;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _CSNYITO,_cszaro,_ftnyito,_ftzaro,_elad,_eladft: integer;
  _csad,_cskap,_ftad,_ftkap,_back,_backft,_utpenztar,_aktpenztar: integer;

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  ibdbase.Connected := true;
  if ibtranz.InTransaction then ibtranz.Commit;
  ibtranz.StartTransaction;
  ibtabla.Open;
  ibtabla.first;
  _cszaro := 0;
  _ftzaro := 0;
  _utpenztar :=0;
  while not ibtabla.Eof do
    begin
      with ibtabla do
        begin
          _aktpenztar := FieldByName('PENZTAR').asInteger;
          _cskap := FieldByname('CSOMAGATVETEL').asInteger;
          _csad  := Fieldbyname('CSOMAGATADAS').asInteger;
          _ftkap := FieldByName('FORINTATVETEL').asInteger;
          _ftad  := FieldByName('FORINTATADAS').asInteger;
          _elad  := FieldByName('ERTEKESITES').asInteger;
          _eladft:= FieldByName('ERTEKFT').asInteger;
          _back  := FieldByname('VISSZAVALTAS').asInteger;
          _backft:= FieldByName('VISSZAFT').asInteger;
        end;

      if _aktpenztar>_utpenztar then
        begin
          _utpenztar := _aktpenztar;
          _cszaro := 0;
          _ftzaro := 0;
        end;
      _ftnyito := _ftzaro;
      _csNyito := _csZaro;

      _ftzaro := _ftnyito + _ftkap - _ftad + _eladft - _backft;
      _cszaro := _csNyito + _cskap - _csad - _elad + _back;
      ibtabla.Edit;
      ibtabla.FieldByName('CSOMAGNYITO').AsInteger := _csNyito;
      ibtabla.FieldByName('CSOMAGZARO').asInteger := _cszaro;
      ibtabla.FieldByName('FORINTNYITO').asinteger := _ftnyito;
      ibtabla.FieldByName('FORINTZARO').asInteger := _ftzaro;
      ibtabla.post;
      ibtabla.next;
    end;
  ibtranz.commit;
  ibdbase.close;
  Showmessage('KESZEN VAN !!!');
END;


end.
