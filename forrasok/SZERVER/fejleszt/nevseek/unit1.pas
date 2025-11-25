unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls, IBTable,
  ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    ListBox1: TListBox;
    dbquery: TIBQuery;
    dbdbase: TIBDatabase;
    dbtranz: TIBTransaction;
    dataquery: TIBQuery;
    datadbase: TIBDatabase;
    datatranz: TIBTransaction;
    dbtabla: TIBTable;
    datumpanel: TPanel;
    penztarpanel: TPanel;
    DATATABLA: TIBTable;
    procedure Button1Click(Sender: TObject);
    procedure egytabla(_tnev: string);
    procedure Egypenztar(_ptszam: integer);
    function Nulele(_int: integer): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _ev,_ho: word;
  _sorveg: string = chr(13)+chr(10);
  _pcs,_farok,_mezo,_jel,_tabla: string;
  _ptar,_recno: integer;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  _ev := 2012;
  _ho := 1;
  _farok := inttostr(_ev-2000)+nulele(_ho);
  while _farok<='1205' do
    begin
      _tabla := 'DAYB' + _farok;
      Datumpanel.Caption := _tabla;
      Datumpanel.Repaint;
      dbdbase.close;
      dbtabla.close;
      dbdbase.Connected := true;
      dbtabla.TableName := _tabla;
      if dbtabla.Exists then egyTabla(_tabla);
      inc(_ho);
      if _ho>12 then
        begin
          inc(_ev);
          _ho := 1;
        end;
      _farok := inttostr(_ev-2000)+nulele(_ho);
    end;
end;

procedure TForm1.egytabla(_tnev: string);

var i: integer;

begin
  dbdbase.close;
  dbtabla.TableName := _tnev;
  dbdbase.Connected := true;
  _pcs := 'SELECT * FROM ' + _tnev;
  dbtabla.open;
  dbtabla.first;

  while not dbtabla.eof do
    begin
      _ptar := DbTabla.fieldByName('PENZTAR').asInteger;
      Penztarpanel.caption := inttostr(_ptar);
      Penztarpanel.repaint;
      for i := 1 to 31 do
        begin
          _mezo := 'N' + inttostr(i);
          _jel := DbTabla.FieldbyName(_mezo).asstring;
          if _jel='B' then
            begin
              egypenztar(_ptar);
              Break;
            end;
        end;
      dbTabla.next;
    end;
  DbTabla.close;
  dbdbase.close;
end;

procedure TForm1.Egypenztar(_ptszam: integer);

var _nev,_datum,_sor,_fejtabla: string;

begin
  _fejTabla := 'BF' + _FAROK;


  datadbase.close;
  datadbase.databasename := 'c:\receptor\database\v'+INTTOSTR(_PTSZAM)+'.gdb';
  DATATABLA.CLOSE;
  datatabla.TableName := _fejtabla;
  datadbase.connected := True;
  if not datatabla.Exists then
    begin
      datadbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+_fejtabla + _sorveg;
  _pcs := _pcs + 'WHERE UGYFELNEV LIKE ' + chr(39)+'TORZSOK%' + chr(39);

  with dataquery do
    begin
      CLOSE;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
    end;

  if _recno=0 THEN
    begin
      dataquery.close;
      datadbase.close;
      exit;
    end;
  while not dataquery.eof do
    begin
      _nev := Dataquery.fieldbyname('UGYFELNEV').asString;
      _datum := Dataquery.FieldByName('DATUM').asstring;
      _sor := inttostr(_ptszam)+'. '+trim(_nev)+':'+_DATUM;
      ListBOX1.ITEMS.ADD(_SOR);
      Listbox1.repaint;
      dataquery.next;
    end;
  dataquery.close;
  datadbase.close;
end;



function TForm1.Nulele(_int: integer): string;

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

end.
