unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  IBTable, ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    IBTABLA: TIBTable;
    PQUERY: TIBQuery;
    PDBASE: TIBDatabase;
    PTRANZ: TIBTransaction;
    Panel1: TPanel;
    Panel2: TPanel;

    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure PParancs(_ukaz: string);

    function Nulele(_b: byte): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _delnev : array[1..16] of string = ('ARFE','AXA','BF','BT','CIMT','COIN',
      'CSIM','EFEJ','ETET','FAXA','KEZD','NARF','TRADE','WUNI','WZAR','XKEZ');

  _pt,_ev,_ho,_delpp: byte;
  _dPath,_pcs,_farok,_akttnev,_tnev: string;
  _sorveg : string = chr(13)+chr(10);   


implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  application.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _pt := 152;
  while _pt<=169 do
    begin
      _dPath := 'c:\CARTCASH\database\V' + inttostr(_pt) + '.FDB';
      IF not fileExists(_dPath) then
        begin
          inc(_pt);
          Continue;
        end;

      ibdbase.close;
      ibdbase.DatabaseName := _dPath;
      ibdbase.Connected := true;

      panel1.Caption := _dPath;
      panel1.Repaint;

      _EV := 15;
      _HO := 1;
      _FAROK := '1501';
      while _farok<='1811' do
        begin
          _DELPP :=1;
          while _delpp<=16 do
            begin

              _akttnev := _delnev[_delpp];
              _tnev := _akttnev + _farok;

              ibtabla.close;
              ibtabla.TableName := _tnev;
              if ibtabla.Exists then
                begin
                  _pcs := 'DROP TABLE ' + _tnev;
                  PParancs(_pcs);
                end;
              inc(_delpp);
            end;
          inc(_ho);
          if _ho>12 then
            begin
              _ho := 1;
              inc(_ev);
            end;
          _farok := inttostr(_ev)+nulele(_ho);
        end;
      ibdbase.close;

      _Pcs := 'DELETE FROM ELOHAVI'+_SORVEG;
      _pcs := _pcs + 'WHERE EVHOSTRING<'+chr(39)+'201901'+chr(39);
      Pparancs(_pcs);

      _Pcs := 'DELETE FROM ELONAPI'+_sorveg;
      _pcs := _pcs + 'WHERE DATUM<'+chr(39)+'2019.01.01'+chr(39);
      Pparancs(_pcs);

      _Pcs := 'DELETE FROM MAINCURR'+_sorveg;
      _pcs := _pcs + 'WHERE EV<2019';
      Pparancs(_pcs);

      ibdbase.close;

      INC(_PT);
    end;

  // ---------------------------------------------------------------------

  Showmessage('KÉSZEN VAGYOK');
END;

procedure TForm1.PParancs(_ukaz: string);

begin
  panel2.caption := _ukaz;
  panel2.Repaint;

  pdbase.close;
  pdbase.databasename := _dpath;
  pdbase.connected := true;

  if ptranz.InTransaction then Ptranz.Commit;
  ptranz.StartTransaction;

  with pquery do
    begin
      Close;
      sql.Clear;
      sql.add(_pcs);
      Execsql;
    end;
  Ptranz.commit;
  Pdbase.close;
end;


function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


end.
