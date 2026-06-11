unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBQuery, IBDatabase, DB, IBCustomDataSet, IBTable, StdCtrls,
  Buttons, strutils;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    kilepgomb: TBitBtn;
    TRADETABLA: TIBTable;
    TRADEDBASE: TIBDatabase;
    TRADETRANZ: TIBTransaction;
    HAVIQUERY: TIBQuery;
    HAVIDBASE: TIBDatabase;
    HAVITRANZ: TIBTransaction;
    procedure BitBtn1Click(Sender: TObject);
    function Nulele(_int: integer): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _ehonap,_eev,_irodaszam,_ertektar,_befizetve: integer;
  _farok,_tablanev,_tipus,_pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _recno,_matrica,_telefon,_atadas,_atvetel: integer;

implementation

{$R *.dfm}

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  HAVIDBASE.Connected := TRUE;
  IF havitranz.InTransaction then Havitranz.Commit;
  Havitranz.StartTransaction;
  with Haviquery do
    begin
      Close;
      sql.clear;
      sql.Add('DELETE FROM HAVITRADE');
      eXECSQL;
    END;
  havitranz.commit;
  Havidbase.close;


  _Ehonap := 4;
  _Eev := 2010;
  while _ehonap<>2 do
    begin
      _farok := midstr(inttostr(_Eev),3,2)+nulele(_Ehonap);
      _tablanev := 'TRADE'+_farok;
      TradeDbase.Connected := True;
      TradeTabla.TableName := _tablanev;
      TradeTabla.open;
      Tradetabla.First;

      while not Tradetabla.eof do
        begin
          with Tradetabla do
            begin
              _irodaszam := FieldByName('IRODASZAM').asInteger;
              _ertekTar := FieldByName('ERTEKTAR').asInteger;
              _tipus := FieldByName('TIPUS').asString;
              _befizetve := FieldByName('BEFIZETVE').asInteger;
            end;

          HaviDbase.Connected := true;
          _pcs := 'SELECT * FROM HAVITRADE'+_sorveg;
          _pcs := _pcs + 'WHERE (IRODASZAM='+INTTOSTR(_IRODASZAM)+') AND (EV='+INTTOSTR(_EEV)+') AND (HONAP='+inttostr(_ehonap)+')';

          with HaviQuery do
            begin
               Close;
               Sql.Clear;
               Sql.Add(_pcs);
               Open;
               first;
               _recno := recno;
             end;

          if _recno>0 then
            begin
              with haviQuery do
                begin
                  _matrica := FieldByName('MATRICA').asInteger;
                  _telefon := FieldByName('TELEFON').asInteger;
                  _atadas := FieldByName('ATADAS').asInteger;
                end;

              _pcs := '';
              if _tipus='M' then _pcs := 'UPDATE HAVITRADE SET MATRICA='+inttostr(_matrica+_befizetve);
              if _tipus='T' then _pcs := 'UPDATE HAVITRADE SET TELEFON='+inttostr(_telefon+_befizetve);
              if (_tipus='F') then
                   _pcs := 'UPDATE HAVITRADE SET ATADAS='+INTTOSTR(_ATADAS+_befizetve);
              if length(_pcs)>5 then
                begin
                  _pcs := _pcs + _sorveg + 'WHERE (IRODASZAM='+INTTOSTR(_irodaszam)+
                        ') AND (EV='+INTTOSTR(_EEV)+') AND (HONAP='+ INTTOSTR(_EHONAP)+')';
                end;
            end else
            begin
              _pcs  := 'INSERT INTO HAVITRADE (IRODASZAM,ERTEKTAR,EV,HONAP,';
              if _tipus='M' then _pcs := _pcs + 'MATRICA)'+_sorveg;
              if _tipus='T' then _pcs := _pcs + 'TELEFON)'+_sorveg;
              if (_tipus='F') and (_befizetve<=0) then _pcs := _pcs + 'ATADAS)';
              _pcs := _pcs + _sorveg;
              _pcs := _pcs + 'VALUES (' + inttostr(_irodaszam)+',';
              _pcs := _pcs + inttostr(_ertektar) + ',';
              _pcs := _pcs + inttostr(_eev) + ',';
              _pcs := _pcs + inttostr(_ehonap) + ',';
              _pcs := _pcs + inttostr(_BEFIZETVE)+')';
            end;

          IF HaviTranz.InTransaction then Havitranz.Commit;
          Havitranz.StartTransaction;
          with HaviQuery do
            begin
              Close;
              Sql.Clear;
              sql.Add(_pcs);
              Execsql;
            end;
          Havitranz.Commit;
          Havidbase.close;
          tradeTabla.Next;
        end;
      TradeTabla.close;
      TradeDbase.close;

      inc(_ehonap);
      if _ehonap>12 then  break;
    end;




  Kilepgomb.Visible := True;
end;

function TForm1.Nulele(_int: integer): string;

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

end.
