unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, ExtCtrls, IBDatabase, DB, IBTable,
  IBCustomDataSet, IBQuery, strutils;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    KILEPO: TTimer;
    BLOKKQUERY: TIBQuery;
    BLOKKDBASE: TIBDatabase;
    BLOKKTRANZ: TIBTransaction;
    EXTRANZ: TIBTransaction;
    EXDBASE: TIBDatabase;
    EXQUERY: TIBQuery;
    REMQUERY: TIBQuery;
    REMDBASE: TIBDatabase;
    REMTRANZ: TIBTransaction;
    Memo1: TMemo;
    procedure BitBtn2Click(Sender: TObject);
    procedure ExParancs(_ukaz: string);

    procedure BitBtn1Click(Sender: TObject);
 
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _honap,_wpl: byte;
  _bankjegy,_ftertek: integer;
  _bf,_bt,_pcs,_datum,_bizonylat,_ido,_PLOMBASZAM,_nevtabla,_sors: string;
  _ugyfeltipus,_nev,_cim,_anyja,_szulido,_szulhely: string;
  _sorveg : string = chr(13)+chr(10);
  _host: string = '185.43.207.99';


implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  application.Terminate;
end;


procedure TForm1.BitBtn1Click(Sender: TObject);
begin



  REMdbase.close;
  remdbase.DatabaseName := _host + ':C:\RECEPTOR\DATABASE\UGYFEL19.FDB';

  _PCS := 'DELETE FROM KERES';
  exparancs(_pcs);


  _HONAP :=8;
  while _honap<=9 do
    begin
      _bf := 'BT190'+CHR(48+_honap);
      _bt := 'BF190'+chr(48+_honap);
      _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
      _pcs := _pcs + 'FROM ' +_BF+ ' FEJ JOIN ' + _BT+' TET'+_sorveg;
      _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
      _pcs := _pcs + 'WHERE (FEJ.STORNO=1) AND (FEJ.BIZONYLATSZAM LIKE ';
      _pcs := _pcs + chr(39)+'V%' + chr(39)+') AND (VALUTANEM='+chr(39)+'EUR'+chr(39)+')';
      _pcs := _pcs + ' AND (UGYFELSZAM>0)'+_SORVEG;
      _pcs := _pcs + 'ORDER BY FEJ.DATUM';

      Blokkdbase.Connected := true;
      with BlokkQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Open;
          fIRST;
        end;

      while not BlokkQuery.Eof do
        begin
          _datum := Blokkquery.FieldByNAme('Datum').asString;
          _bankjegy := BlokkQuery.FieldByName('BANKJEGY').asInteger;
          _ido := TRIM(Blokkquery.FieldByNAme('IDO').ASString);
          _bizonylat := Blokkquery.FieldByNAme('BIZONYLATSZAM').asString;
          _ftertek := Blokkquery.FieldByName('FORINTERTEK').asInteger;
          _plombaszam := trim(Blokkquery.fieldByName('PLOMBASZAM').AsString);

          mEMO1.Lines.Add(_datum+' '+_bizonylat);

          if _datum>'2019.09.01' then break;

          _wpl := length(_plombaszam);

          _nev := '';
          _cim := '';
          _anyja := '';
          _szulido := '';
          _szulhely := '';
          _ugyfeltipus := '';

          if _wpl>4 then
            begin
              _nevtabla := leftstr(_plombaszam,4);
              _sors := midstr(_plombaszam,5,_wpl-4);

              _pcs := 'SELECT * FROM ' +_nevtabla + _sorveg;
              _pcs := _pcs + 'WHERE SORSZAM='+_sors;

              remdbase.Connected := true;
              with remquery do
                begin
                  close;
                  sql.clear;
                  sql.add(_pcs);
                  Open;
                end;

              _ugyfeltipus:='N';
              if _nevtabla='JOGI' then
                begin
                  _ugyfeltipus:= 'J';
                  _nev := trim(remquery.fieldbyname('JOGISZEMELYNEV').asString);
                  _cim := trim(remquery.FieldByName('TELEPHELYCIM').AsString);
                end else
                begin
                  _nev := trim(remquery.Fieldbyname('NEV').AsString);
                  _cim := trim(remquery.FieldByName('LAKCIM').ASSTRING);
                  _anyja := trim(remquery.fieldByName('ANYJANEVE').asString);
                  _szulido := remquery.fieldByName('SZULETESIIDO').ASSTRING;
                  _szulhely:= remquery.fieldByNAme('SZULETESIHELY').asString;
                end;
            end;

          _pcs := 'INSERT INTO KERES (DATUM,IDO,BIZONYLATSZAM,BANKJEGY,';
          _pcs := _pcs + 'FORINTERTEK,NEV,LAKCIM,ANYJANEVE,SZULETESIIDO,';
          _pcs := _pcs + 'SZULETESIHELY)' + _sorveg;

          _pcs := _pcs + 'VALUES (' + CHR(39)+ _datum +chr(39) + ',';
          _pcs := _pcs + chr(39)+ _ido + chr(39) + ',';
          _pcs := _pcs + chr(39) + _bizonylat + chr(39) + ',';
          _pcs := _pcs + inttostr(_bankjegy) + ',';
          _pcs := _pcs + inttostr(_ftertek) + ',';
          _pcs := _pcs + chr(39) + _nev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _cim + chr(39);


          _pcs := _pcs + ',' + chr(39) + _ANYJA + chr(39) + ',';
          _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
          _pcs := _pcs + chr(39) + _szulhely + chr(39);
    
          _pcs := _pcs + ')';
          exParancs(_pcs);

          BlokkQuery.Next;
        end;

      blokkquery.close;
      BlokkDbase.close;
      inc(_honap);
    end;
  Memo1.Lines.Add('KÉSZEN VAGYOK !');  
end;


procedure TForm1.ExParancs(_ukaz: string);

begin
  exdbase.connected := True;
  if extranz.InTransaction then extranz.commit;
  extranz.StartTransaction;

  with exquery do
    begin
      Close;
      sql.clear;
      sql.Add(_ukaz);
      Execsql;
    end;
  extranz.commit;
  exdbase.close;
end;

end.
