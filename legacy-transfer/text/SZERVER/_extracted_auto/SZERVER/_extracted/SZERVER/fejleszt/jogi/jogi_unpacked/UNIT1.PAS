unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls, IBTable;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    JOGIQUERY: TIBQuery;
    JOGIDBASE: TIBDatabase;
    JOGITRANZ: TIBTransaction;
    PTQUERY: TIBQuery;
    PTDBASE: TIBDatabase;
    PTTRANZ: TIBTransaction;
    pttabla: TIBTable;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _QQ,_recno: integer;
  _sorveg: string = chr(13)+chr(10);
  _pcs,_jnev,_jcim,_gdbpath: string;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  jogidbase.Connected := true;
  if jogitranz.InTransaction then jogitranz.Commit;
  jogitranz.StartTransaction;

  _QQ := 1;
  WHILE _QQ<151 DO
    begin
      _gdbpath := 'c:\receptor\database\v' + inttostr(_qq)+'.gdb';
      if not fileexists(_gdbPath) then
        begin
          inc(_qq);
          continue;
        end;

      Ptdbase.close;
      ptdbase.DatabaseName := _gdbPath;
      ptdbase.Connected := true;
      ptTabla.close;
      pttabla.TableName := 'UGYFELEK';
      IF not Pttabla.Exists then
        begin
          ptdbase.close;
          inc(_qq);
          continue;
        end;

      _pcs := 'SELECT * FROM UGYFELEK'+_sorveg;
      _pcs := _pcs + 'WHERE UGYFELTIPUS=' + chr(39)+ 'J' + CHR(39);
      with ptquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          first;
          _recno := recno;
        end;

      if _recno=0 then
        begin
          ptquery.close;
          ptdbase.close;
          inc(_qq);
          continue;
        end;

      while not ptquery.eof do
        begin
          _jnev := ptquery.fieldbyname('NEV').asstring;
          _jcim := ptquery.fieldbyname('TELEPHELYCIM').asstring;

          _pcs := 'INSERT INTO CEGEK (PENZTARSZAM,JOGISZEMELYNEV,TELEPHELYCIM)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + INTTOSTR(_QQ)+',';
          _pcs := _pcs + chr(39) + _jnev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _jcim + chr(39) + ')';

          with jogiQuery do
            begin
              Close;
              sql.clear;
              sql.Add(_pcs);
              ExecSql;
            end;
          ptQuery.next;
        end;
      Ptquery.close;
      ptdbase.close;

      inc(_qq);
    end;
  Jogitranz.Commit;
  Jogidbase.close;
  Showmessage('KÉSZEN VAGYOK !');
  aPPLICATION.Terminate;

end;

end.
