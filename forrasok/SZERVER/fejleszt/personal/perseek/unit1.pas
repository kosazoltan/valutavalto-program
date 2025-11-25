unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,Strutils,
  IBTable, ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    FEJQUERY: TIBQuery;
    FEJDBASE: TIBDatabase;
    FEJTRANZ: TIBTransaction;
    GQUERY: TIBQuery;
    GDBASE: TIBDatabase;
    GTRANZ: TIBTransaction;
    TETQUERY: TIBQuery;
    TETDBASE: TIBDatabase;
    TETTRANZ: TIBTransaction;
    fejtabla: TIBTable;
    Label1: TLabel;
    keredit: TEdit;
    Panel1: TPanel;
    Panel2: TPanel;
    BitBtn3: TBitBtn;


    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure Gparancs(_ukaz: string);
    function Nulele(_b: byte): string;
    function Ezertektar(_p: byte): boolean;
    procedure FormActivate(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pcs,_dat,_nev,_biz,_fdbPath,_farok,_bf,_bt,_kernev,_dnem: string;
  _osz,_pt,_recno,_bj: integer;
  _sorveg: string = chr(13)+chr(10);
  _ev,_ho: word;

implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
 

  _kernev := trim(keredit.Text);
  if _kernev='' then
    begin
      Activecontrol := keredit;
      exit;
    end;



  _pt := 3;
  while _pt<=150 do
    begin
      if ezErtektar(_pt) then
        begin
          inc(_pt);
          Continue;
        end;

      _fdbPath := 'c:\receptor\database\v' + INTTOSTR(_PT)+'.FDB';
      if not fileexists(_fdbPath) then
        begin
          inc(_pt);
          Continue;
        end;

      Panel1.Caption := _fdbPath;
      Panel1.repaint;

      Fejdbase.close;
      tetdbase.close;

      fejdbase.DatabaseName := _fdbPath;
      tetdbase.DatabaseName := _fdbPath;

      _ev := 11;
      _ho := 1;
      _farok := '1101';
      while _farok<='1311' do
        begin
          Panel2.Caption := _farok;
          Panel2.repaint; 

          _bf := 'BF' + _farok;
          _bt := 'BT' + _farok;
          Fejtabla.close;
          Fejtabla.TableName := _bf;
          Fejdbase.Connected := true;
          if not Fejtabla.Exists then
            begin
              Fejdbase.close;
              inc(_ho);
              if _ho>12 then
                begin
                  _ho := 1;
                  inc(_ev);
                end;
              _farok := inttostr(_ev)+nulele(_ho);
              continue;
            end;

          _pcs := 'SELECT * FROM ' + _bf + _sorveg;
          _pcs := _pcs + 'WHERE UGYFELNEV LIKE ' + chr(39) +_kernev + '%' + CHR(39);
          with FejQuery do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              First;
              _recno := recno;
            end;

          if _recno=0 then
            begin
              Fejquery.close;
              Fejdbase.close;

              inc(_ho);
              if _ho>12 then
                begin
                  _ho := 1;
                  inc(_ev);
                end;
              _farok := inttostr(_ev)+nulele(_ho);
              continue;
            end;

          while not Fejquery.eof do
            begin
              _nev := Fejquery.FieldByName('UGYFELNEV').asString;
              _biz := Fejquery.FieldByNAme('BIZONYLATSZAM').asstring;
              _osz := Fejquery.FieldByName('OSSZESEN').asInteger;
              _dat := Fejquery.FieldByName('DATUM').asString;

              if leftstr(_biz,1)='K' then
                begin
                  Fejquery.next;
                  continue;
                end;

              _pcs := 'SELECT * FROM ' + _bt + _sorveg;
              _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_biz+chr(39);
              Tetdbase.Connected := true;
              with tetquery do
                begin
                  close;
                  sql.clear;
                  sql.add(_pcs);
                  Open;
                  _bj := FieldByNAme('BANKJEGY').ASiNTEGER;
                  _dnem := FieldByNAme('VALUTANEM').asString;
                  close;
                end;
              Tetdbase.close;

              _pcs := 'INSERT INTO TALALATOK (PENZTAR,DATUM,BIZONYLATSZAM,OSSZESEN,';
              _PCS := _pcs + 'VALUTANEM,BANKJEGY,UGYFELNEV)'+_sorveg;
              _pcs := _pcs + 'VALUES (' + inttostr(_pt) + ',';
              _pcs := _pcs + chr(39) + _dat + chr(39) + ',';
              _pcs := _pcs + chr(39) + _biz + chr(39) + ',';
              _pcs := _pcs + inttostr(_osz) + ',';
              _pcs := _pcs + chr(39) + _dnem + chr(39) + ',';
              _pcs := _pcs + inttostr(_bj) + ',';
              _pcs := _pcs + chr(39) + _nev + chr(39) + ')';
              Gparancs(_pcs);
              fejquery.next;
            end;
          Fejquery.close;
          Fejdbase.close;
          
          inc(_ho);
          if _ho>12 then
            begin
              _ho := 1;
              inc(_ev);
            end;
          _farok := inttostr(_ev)+nulele(_ho);
        end;
      inc(_pt);
    end;
  ShowMessage('VÉGE VAN');
END;


procedure TForm1.Gparancs(_ukaz: string);

begin
  gdbase.connected := true;
  if gtranz.InTransaction then gtranz.commit;
  gtranz.StartTransaction;
  with gquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Gtranz.commit;
  gdbase.close;
end;


function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + RESULT;
end;


function TForm1.Ezertektar(_p: byte): boolean;

begin
  result := True;
  if (_p=10) or (_p=20) or (_p=40) or (_p=50) or (_p=63) then exit;
  if (_p=75) or (_p=120) or (_p=145) then exit;
  result := False;
end;





procedure TForm1.FormActivate(Sender: TObject);
begin
  Keredit.clear;
  Activecontrol := keredit;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  _PCS := 'DELETE FROM TALALATOK';
  gParancs(_pcs);
end;

end.
