unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, IBTable, DB, IBCustomDataSet, IBQuery,
  Strutils, ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTABLA: TIBTable;
    IBTRANZ: TIBTransaction;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    function Nulele(_b: byte): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pt,_ev,_ho: word;
  _recno: integer;
  _aktfdbpath,_evhos,_bf,_mondat,_biz,_nev,_datum,_farok,_pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _txtiro: textfile;

implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  AssignFile(_txtiro,'c:\8\police.txt');
  Rewrite(_txtiro);

  _pt := 3;
  while _pt<=150 do
    begin
      _aktfdbPath := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb';
      if not fileExists(_aktfdbpath) then
        begin
          inc(_pt);
          Continue;
        end;

      ibdbase.close;
      ibdbase.DatabaseName := _aktfdbpath;
      Panel1.Caption := _aktfdbpath;
      Panel1.Repaint;

      _ev := 2014;
      _ho := 7;
      _evhos := '201407';
      while _evhos<='201503' do
        begin
          _farok := midstr(_evhos,3,4);
          _bf := 'BF' + _farok;

          Panel2.Caption := _bf;
          Panel2.Repaint;

          ibtabla.close;
          ibtabla.TableName := _bf;
          ibdbase.Connected := true;
          if not ibtabla.Exists then
            begin
              ibdbase.close;
              inc(_ho);
              if _ho>12 then
                begin
                  _ho := 1;
                  inc(_ev);
                end;
              _evhos := inttostr(_ev)+nulele(_ho);
              Continue;
            end;
          _pcs := 'SELECT * FROM '+_bf + _sorveg;
          _pcs := _pcs + 'WHERE UGYFELNEV LIKE '+chr(39)+'GÁL%'+chr(39);
          with ibQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              First;
              _recno := recno;
            end;

          if _recno>0 then
            begin
              while not ibquery.eof do
                begin
                  _datum := Ibquery.fieldbyname('DATUM').asstring;
                  _biz   := Ibquery.fieldByName('BIZONYLATSZAM').asString;
                  _nev   := trim(ibquery.fieldbyname('UGYFELNEV').AsString);
                  _mondat := inttostr(_pt)+'. penztar = ';
                  _mondat := _mondat + _nev + ' '+_datum+'/'+_biz;
                  Panel3.caption := _mondat;
                  Panel3.repaint;

                  writeLn(_txtiro,_mondat);
                  ibquery.next;
                end;
            end;
          ibquery.close;
          ibdbase.close;
          inc(_ho);
          if _ho>12 then
            begin
              _ho := 1;
              inc(_ev);
            end;
          _evhos := inttostr(_ev)+nulele(_ho);
        end;
      inc(_pt);
    end;
  Closefile(_txtiro);
  ShowMessage('Kész vagyok');
  Application.terminate;
end;  


function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;



end;

end.
