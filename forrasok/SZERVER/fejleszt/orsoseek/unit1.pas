unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBTable, IBCustomDataSet,
  IBQuery, ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    ListBox1: TListBox;
    IBQUERY: TIBQuery;
    IBTABLA: TIBTable;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    Panel1: TPanel;
    FAROK: TPanel;
    
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    function Ezertar(_p: byte): boolean;
    function Nulele(_b: byte): string;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pt: byte;
  _fdbPath,_farok,_bf,_pcs,_datum,_biz,_unev: string;
  _ev,_ho: byte;
  _recno: integer;

implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  application.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _pt := 3;
  while _pt<=150 do
    begin
      if ezertar(_pt) then
        begin
          inc(_pt);
          Continue;
        end;

      _fdbPath := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb';
      if not fileExists(_fdbPath) then
        begin
          inc(_pt);
          Continue;
        end;

      Panel1.Caption := inttostr(_pt);
      Panel1.repaint;

      ibdbase.close;
      ibdbase.databasename :=_fdbPath;
      ibdbase.connected := true;


      _ho := 1;
      _EV := 13;
      _farok := '1301';
      while _farok<='1412' do
        begin
          Farok.caption := _farok;
          farok.repaint;

          SLEEP(50);
          _bf := 'BF' + _farok;
          ibtabla.tablename := _bf;
          if not ibTabla.exists then
            begin
              inc(_ho);
              IF _HO>12 then
                begin
                  _ho := 1;
                  inc(_ev);
                end;

              _farok := inttostr(_ev)+nulele(_ho);
              continue;
            end;

          _pcs := 'SELECT * FROM ' + _BF + ' WHERE UGYFELNEV LIKE ' +chr(39);
          _pcs := _pcs + 'ORS%' + chr(39);

          with ibQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              _recno := recno;
            end;

          if _recno>0 then
            begin
              _datum := ibquery.Fieldbyname('DATUM').asString;
              _UNEV  := ibquery.FieldByName('UGYFELNEV').asString;
              _biz := ibquery.fieldByNAme('BIZONYLATSZAM').asString;
              Listbox1.Items.add(inttostr(_pt)+'. '+_unev+'='+_biz+ ' ('+_datum + ')');
            end;

          Ibquery.close;
          inc(_ho);
          if _ho>12 then
            begin
              _ho := 1;
              inc(_ev);
            end;
          _farok := inttostr(_ev)+nulele(_ho);
        end;
      ibdbase.close;
      inc(_pt);
    end;
  ShowMessage('KÉSZEN VAN');

end;

FUNCTION TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;  

function TForm1.Ezertar(_p: byte): boolean;

begin
  result := False;
  if (_p=10) or (_p=20) or (_p=40) or (_p=63) or (_p=75) then result := True;
  if (_p=50) or (_p=120) or (_p=145) then result := true;
end;


end.
