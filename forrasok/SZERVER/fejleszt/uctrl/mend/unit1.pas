unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    XQUERY: TIBQuery;
    XDBASE: TIBDatabase;
    XTRANZ: TIBTransaction;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _betu: byte;
  _sum,_utsum,_max,_sdb: array[1..5000] of integer;
  _utdat: array[1..5000] of string;
  _ss,_darab: word;

  _ft,_szamdb,_heti,_maxi: integer;
  _biztabla,_nevtabla,_pcs,_dt: string;
  _sorveg: string = chr(13)+chr(10);

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  aPPLICATION.TERMINATE;
end;

procedure TForm1.Button1Click(Sender: TObject);

var i: word;

begin
  _Betu := 65;
  while _betu<=90 do
    begin
      for i := 1 to 5000 do
        begin
          _sum[i] := 0;
          _utdat[i]:= '2000.01.01';
          _utsum[i]:= 0;
          _max[i] := 0;
          _sdb[i] := 0;
        end;

      _biztabla := chr(_betu)+'BIZ';
      _nevtabla := chr(_betu)+'NEV';

      Panel1.Caption := _nevtabla;
      Panel1.repaint;

      _pcs := 'SELECT * FROM '+_BIZTABLA + _sorveg;
      _pcs := _pcs + 'ORDER BY DATUM';
      XDBASE.Connected := true;
      with xquery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      _darab := 0;
      while not xquery.Eof do
        begin
          _ss := Xquery.FieldByNAme('SORSZAM').asInteger;
          _ft := xquery.FieldByNAme('FIZETENDO').asInteger;
          _dt := xquery.FieldbyNAme('DATUM').asString;
          if _ft>_max[_ss] then _max[_ss] := _ft;

          _sdb[_ss] := _sdb[_ss] + 1;
          _sum[_ss] := _sum[_ss] + _ft;
          _utdat[_ss] := _dt;
          _utsum[_ss] := _ft;
          if _ss>_darab then _darab := _ss;

          xquery.Next;
        end;

      xquery.close;
      xdbase.close;

      xdbase.Connected := true;
      if xtranz.InTransaction then xtranz.commit;
      xtranz.StartTransaction;

      _ss := 1;
      while _ss<=_darab do
        begin
          _ft := _sum[_ss];
          _dt := _utdat[_ss];
          _szamdb := _sdb[_ss];
          _heti := _utsum[_ss];
          _maxi := _max[_ss];

          _pcs := 'UPDATE '+_NEVTABLA + ' SET FORINTOSSZEG='+inttostr(_ft);
          _pcs := _pcs + ',EVIMAX='+inttostr(_maxi)+',TRANZAKCIODB='+INTTOSTR(_SZAMDB);
          _pcs := _pcs + ',HETIOSSZ='+inttostr(_heti)+',DATUM='+chr(39)+_dt+chr(39)+_sorveg;
          _pcs := _pcs + 'WHERE SORSZAM='+inttostr(_ss);

          Panel2.Caption := _dt;
          Panel2.repaint;

          with xquery do
            begin
              Close;
              sql.clear;
              sql.Add(_pcs);
              Execsql;
            end;
          inc(_ss);
        end;
      Xtranz.commit;
      xdbase.close;
      inc(_betu);
    end;

 Showmessage('KÉSZEN VAGYOK');
end;

end.
