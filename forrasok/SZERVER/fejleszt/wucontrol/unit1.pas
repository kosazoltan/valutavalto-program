unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBQuery, IBCustomDataSet,
  IBTable, strutils;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    WUTABLA: TIBTable;
    WUQUERY: TIBQuery;
    WUDBASE: TIBDatabase;
    WUTRANZ: TIBTransaction;
    WZTABLA: TIBTable;
    WZQUERY: TIBQuery;
    WZDBASE: TIBDatabase;
    WZTRANZ: TIBTransaction;
    Memo2: TMemo;
    Memo1: TMemo;

    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    function Nulele(_b: byte): string;
  


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _aktfdbpath,_farok,_elofarok,_wutablanev,_wztablanev,_elowztablanev: string;
  _pcs,_zDatum,_mess,_ttip,_aktdnem: string;
  _sorveg: string = chr(13)+chr(10);
  _utHufzaro,_utUsdZaro,_zHufnyito,_zUsdNyito,_zHufZaro,_zUsdZaro: integer;
  _zHufbe,_zUsdbe,_zHufki,_zUsdki,_szamUsdZaro,_szamHufZaro: integer;
  _wUsdBe,_wUsdki,_wHufbe,_wHufki,_bjegy: integer;
  _kertev,_kertho,_eloev,_eloho: word;
  _penztar,_HIBA: byte;


implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  _kertev  := 2022;
  _kertHo  := 1;
  _penztar := 126;

  _hiba := 0;
  _aktfdbPath := 'c:\receptor\database\v'+inttostr(_penztar)+'.FDB';
  wudbase.Close;
  wzdbase.close;
  wudbase.DatabaseName := _aktfdbPAth;
  wzdbase.DatabaseName := _aktfdbpath;

  wudbase.Connected := True;
  wzdbase.connected := True;

  _eloev := _kertev;
  _eloho := _kertho-1;

  if _eloho=0 then
    begin
      _eloho := 12;
      dec(_eloev);
    end;

  _utUSdZaro := 0;
  _utHufZaro := 0;

  _farok := midstr(inttostr(_kertev),3,2) + nulele(_kertho);
  _elofarok := midstr(inttostr(_eloev),3,2) + nulele(_eloho);

  _wutablanev := 'WUNI'+_farok;
  _wztablanev := 'WZAR'+ _farok;

  _elowztablanev := 'WZAR' + _elofarok;

  Wztabla.close;
  Wztabla.TableName := _eloWzTablanev;
  if not WzTabla.Exists then exit;

  _pcs := 'SELECT * FROM ' + _elowztablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with wzQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _utUsdZaro := FieldByName('USDZARO').asInteger;
      _utHufZaro := FieldByName('HUFZARO').asInteger;
      Close;
    end;
end;



procedure TForm1.BitBtn1Click(Sender: TObject);
begin

  _pcs := 'SELECT * FROM '+ _wzTablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with wzquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not wzquery.Eof do
    begin
      with wzQuery do
        begin
          _zdatum    := FieldByName('DATUM').asString;
          _zHufnyito := FieldbyName('HUFNYITO').asInteger;
          _zUsdNyito := FieldByNAme('USDNYITO').asInteger;
          _zHufZaro  := FieldByName('HUFZARO').asInteger;
          _zUsdZaro  := FieldByNAme('USDZARO').asInteger;
          _zHufbe    := FieldByNAme('HUFBE').asInteger;
          _zUsdBe    := FieldByNAme('USDBE').asInteger;
          _zUsdKi    := FieldByNAme('USDKI').asInteger;
          _zHufKi    := FieldByNAme('HUFKI').asInteger;
        end;

      memo1.Lines.add('Vizsgált nap: ' + _zdatum);
      If _zHufnyito<>_utHufZaro then
        begin
          _mess := _ZdATUM+': Napi HUF nyitó nem egyezik elözõ napii záróval';
          Memo2.Lines.Add(_mess);
          inc(_hiba);
        end;

      If _zUsdnyito<>_utUsdZaro then
        begin
          _mess := _ZDATUM+': Napi USD nyitó nem egyezik elözõ napi záróval';
          Memo2.Lines.Add(_mess);
          inc(_hiba);
        end;

      _utUsdZaro := _zUsdZaro;
      _utHufZaro := _zHufZaro;

      _szamUsdZaro := _zusdNyito+_zUsdbe-_zUsdki;
      _szamHUFZaro := _zhufNyito+_zHufbe-_zHufki;

      if _szamUsdZaro<>_zUsdZaro then
        begin
          Memo2.lines.add(_zDatum+': USD záró számitása helytelen');
          inc(_hiba);
        end;

      if _szamHufZaro<>_zHufZaro then
        begin
          Memo2.lines.add(_zdatum+': HUF záró számitása helytelen');
          inc(_hiba);
        end;

      // -----------------------------------------------------------------------

      _pcs := 'SELECT * FROM '+_wuTablanev + _sorveg;
      _pcs := _pcs + 'WHERE (STORNO=1) AND (DATUM='+chr(39)+_zDatum+chr(39)+')';

      with wuquery do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
        end;

      _wusdbe := 0;
      _wusdki := 0;
      _whufbe := 0;
      _whufki := 0;

      while not wuquery.Eof do
        begin
          _ttip    := wuquery.FieldByNAme('TRANZAKCIOTIPUS').asString;
          _bjegy   := wuquery.FieldbyNAme('BANKJEGY').asInteger;
          _aktdnem := wuquery.FieldByNAme('VALUTANEM').asString;

          if _ttip='+B' then
            begin
              if _aktdnem='USD' then _wusdbe := _wusdbe + _bjegy;
              if _aktdnem='HUF' then _whufbe := _whufbe + _bjegy;
            end;

          if _ttip='-K' then
            begin
              if _aktdnem='USD' then _wusdki := _wusdki + _bjegy;
              if _aktdnem='HUF' then _whufki := _whufki + _bjegy;
            end;

          wuQuery.next;
        end;

      wuQuery.close;

      if _wUsdbe<>_zUsdbe then
        begin
          Memo2.Lines.add(_zdatum+': Az Usd bevétel nem egyezik');
          inc(_hiba);
        end;

      if _wUsdki<>_zUsdki then
        begin
          Memo2.Lines.add(_zdatum+': Az Usd kiadás nem egyezik');
          inc(_hiba);
        end;

      if _wHufbe<>_zHufbe then
        begin
          Memo2.Lines.add(_zdatum+': A Huf bevétel nem egyezik');
          inc(_hiba);
        end;

      if _wHufki<>_zHufki then
        begin
          Memo2.Lines.add(_zdatum+': A Huf kiadás nem egyezik');
          inc(_hiba);
        end;
      wzquery.next;
    end;
  wzdbase.close;
  wudbase.close;
  Memo2.Lines.add('   ');
  if _hiba=0 then
      Memo2.Lines.add('A HAVI ADATBÁZISOK HIBÁTLANOK')
  else Memo2.Lines.Add(inttostr(_hiba)+' darab hibás adat van az adatbázisokban');

end;

function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0'+ result;
end;





end.
