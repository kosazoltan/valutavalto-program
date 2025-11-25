unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls, IBTable;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    RECQUERY: TIBQuery;
    recdbase: TIBDatabase;
    rectranz: TIBTransaction;
    KDQUERY: TIBQuery;
    KDDBASE: TIBDatabase;
    KDTRANZ: TIBTransaction;
    KDTABLA: TIBTable;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _cbetu: array[1..150] of string;
  _bkod: array[1..150] of integer;
  _u,_bk,_pt: integer;
  _cb,_bks,_Tnev: string;

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  RECDBASE.Connected := TRUE;
  with recquery do
    begin
      Close;
      sql.clear;
      sql.Add('SELECT * FROM IRODAK');
      oPEN;
      First;
    end;

  while not recquery.Eof do
    begin
      _u := Recquery.fieldByname('UZLET').asInteger;
      _cb := Recquery.FieldByNAme('CEGBETU').asString;
      _bks := trim(recquery.FieldByname('BANKKOD').asString);
      if _bks<>'' then
        begin
      _bk := strtoint(_bks);
      _cbetu[_u] := _cb;
      _bkod[_u] := _bk;
        end;
      recquery.next;
    end;
  recquery.close;
  recdbase.close;

  _TNEV := 'KEZD1505';

  KDTABLA.TableName := _TNEV;
  KDDBASE.Connected := TRUE;
  IF KDTRANZ.InTransaction THEN KDTRANZ.Commit;
  KDTRANZ.StartTransaction;
  KDTABLA.OPEN;
  KDTABLA.First;
  WHILE NOT KDTABLA.EOF DO
    begin
      _pt := Kdtabla.FieldByName('PENZTAR').asInteger;
      _cb := _cbetu[_pt];
      _bk := _bkod[_pt];
      Kdtabla.edit;
      Kdtabla.FieldByName('BANKKOD').asInteger := _bk;
      Kdtabla.FieldByName('CEGBETU').ASSTRING := _CB;
      kDTABLA.POST;
      KDTABLA.NEXT;
    END;
  KDTRANZ.COMMIT;
  KDDBASE.CLOSE;
  KDTABLA.CLOSE;
  SHOWMESSAGE('készen van');
end;

end.
