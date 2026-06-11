unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, DBGrids, DB, IBDatabase, IBCustomDataSet,
  IBTable, ExtCtrls, IBQuery;

type
  TSETSZORZO = class(TForm)
    Button1: TButton;
    IBTABLA: TIBTable;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    JUTALEKSOURCE: TDataSource;
    jutalekracs: TDBGrid;
    Label1: TLabel;
    Shape1: TShape;
    RECEPTORQUERY: TIBQuery;
    RECEPTORDBASE: TIBDatabase;
    RECEPTORTRANZ: TIBTransaction;
    IBQuery: TIBQuery;


    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure IrodaBetolto;
    procedure IrodaBeiro;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SETSZORZO: TSETSZORZO;
  _width,_height: word;
  _irodanev: array[1..180] of string;
  _pcs,_xnev,_aktnev: string;
  _sorveg: string = chr(13)+chr(10);
  _uzlet,_isz: byte;


function jutalekszorzo: integer; stdcall;

implementation

{$R *.dfm}


function jutalekszorzo: integer; stdcall;
begin
  Setszorzo := Tsetszorzo.create(Nil);
  Result    := Setszorzo.Showmodal;
  Setszorzo.Free;
end;



procedure TSETSZORZO.Button1Click(Sender: TObject);
begin
  if ibtranz.InTransaction then ibtranz.Commit;
  ibdbase.close;
  ibtabla.close;
  Modalresult := 1;
end;

procedure TSETSZORZO.FormActivate(Sender: TObject);
begin
  _width  := Screen.Monitors[0].Width;
  _height := screen.Monitors[0].Height;

  top  := trunc((_height-700)/2);
  left := trunc((_width-580)/2);

  IrodaBetolto;
  Irodabeiro;

  ibdbase.Connected := true;
  if ibtranz.InTransaction then ibtranz.Commit;
  ibtranz.StartTransaction;
  ibtabla.Open;
  Jutaleksource.Enabled := True;

  Jutalekracs.SelectedIndex := 2;
  Activecontrol := JutalekRacs;

end;

// =============================================================================
                 procedure TSetSzorzo.IrodaBetolto;
// =============================================================================

var i: byte;

begin

  for i := 1 to 180 do _irodanev[i] := '-';

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE CLOSED=' + chr(39) + 'N' + chr(39) + _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  ReceptorDbase.Connected := true;
  with ReceptorQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not ReceptorQuery.Eof do
    begin
      with ReceptorQuery do
        begin
          _uzlet     := FieldByName('UZLET').asInteger;
          _xnev      := trim(FieldByNAme('KESZLETNEV').asString);
        end;

      _irodanev[_uzlet] := _xNev;
      ReceptorQuery.next;
    end;

  ReceptorQuery.close;
  Receptordbase.close;
end;

procedure TSetszorzo.Irodabeiro;

begin
  JutalekSource.Enabled := False;
  ibdbase.connected := true;
  if ibtranz.InTransaction then ibtranz.commit;
  ibtranz.StartTransaction;
  ibtabla.Open;
  while not ibtabla.Eof do
    begin
      _isz := ibtabla.fieldByName('IRODASZAM').asInteger;
      _aktnev := _irodanev[_isz];

      if _aktnev<>'-' then
        begin
          ibtabla.edit;
          ibtabla.FieldByName('IRODANEV').asString := _aktnev;
          ibtabla.Post;
        end;
      ibtabla.Next;
    end;
  ibtranz.commit;
  ibdbase.close;
  ibTabla.close;
end;


end.
