unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  IBTable;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    U19QUERY: TIBQuery;
    U19DBASE: TIBDatabase;
    U19TRANZ: TIBTransaction;
    U20QUERY: TIBQuery;
    U20DBASE: TIBDatabase;
    U20TRANZ: TIBTransaction;
    U20TABLA: TIBTable;
    Memo1: TMemo;
    Memo2: TMemo;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _betu: byte;
  _nevtabla,_pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _recno,_SORSZAM: integer;
  _nev,_anyjaneve,_szuletesihely,_lakcim,_szuletesiido,_okmanytip: string;
  _azonosito,_lakcimkartya,_ISO,_mezo: string;

implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Application.terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin

  _betu := 65;
  while _betu<=90 do
    begin
      _nevtabla := chr(_betu)+'NEV';
      Memo1.Lines.add(_nevtabla);

      _PCS := 'SELECT * FROM '+_NEVTABLA +_sorveg;
      _pcs := _pcs + 'WHERE TILTVA=1';

      U19DBASE.CONNECTED := tRUE;
      WITH u19query do
        begin
          close;
          sql.clear;
          sql.add(_pcs);
          Open;
          _recno := recno;
        end;

      if _recno=0 then
        begin
          u19dbase.close;
          u19query.close;
          inc(_betu);
          continue;
        end;

      while not u19query.eof do
        begin
          _nev := trim(u19query.fieldbyname('NEV').asString);
          _anyjaneve := trim(u19query.fieldbyname('ANYJANEVE').asString);
          _SZULETESIHELY := trim(u19query.fieldbyname('SZULETESIHELY').asString);
          _lakcim := trim(u19query.fieldbyname('LAKCIM').asString);
          _OKMANYTIP := trim(u19query.fieldbyname('OKMANYTIP').asString);
          _azonosito := trim(u19query.fieldbyname('AZONOSITO').asString);
          _LAKCIMKARTYA := trim(u19query.fieldbyname('LAKCIMKARTYA').asString);
          _SZULETESIIDO := U19QUERY.fieldbyname('SZULETESIIDO').asString;

          Memo1.Lines.add(_nev+' - '+_szuletesiido);
          _ISO := U19Query.Fieldbyname('ISO').asString;

          _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
          _pcs := _pcs + 'WHERE (NEV='+chr(39)+_nev+chr(39)+') AND (';
          _pcs := _pcs + 'SZULETESIIDO='+chr(39)+_szuletesiido+chr(39)+')';

          U20dbase.connected := true;
          if u20tranz.intransaction then u20tranz.commit;
          with U20query do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              _recno := recno;
            end;

          if _recno>1 then
            begin
              Memo1.Lines.Add('idén is vásárolt');
              Memo2.Lines.add(_nev);
              _sorszam:=U20Query.FieldByNAme('SORSZAM').asInteger;
              U20Query.close;
              _pcs := 'UPDATE ' + _nevtabla + ' SET TILTVA=1' + _sorveg;
              _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
              with U20Query do
                begin
                  Close;
                  sql.clear;
                  sql.add(_pcs);
                  execsql;
                end;
              U20Tranz.commit;
              u20dbase.close;
            end else
            begin
              Memo1.Lines.add('Idén még nem vásárolt');
              u20tabla.close;
              u20tabla.TableName := 'LASTNUMS';
              U20TABLA.OPEN;
              _MEZO := CHR(_BETU)+'LAST';
              _sorszam := u20tabla.fieldbyname(_mezo).asInteger;
              inc(_sorszam);
              U20tabla.edit;
              u20tabla.FieldByName(_mezo).AsInteger := _sorszam;
              U20Tabla.Post;

              _pcs := 'INSERT INTO ' + _NEVTABLA + ' (SORSZAM,NEV,ANYJANEVE,';
              _pcs := _pcs + 'SZULETESIHELY,SZULETESIIDO,LAKCIM,OKMANYTIP,';
              _pcs := _pcs + 'AZONOSITO,LAKCIMKARTYA,TILTVA,ISO)'+_sorveg;
              _pcs := _pcs + 'VALUES (' + inttostr(_sorszam) + ',';
              _pcs := _pcs + chr(39)+_nev+chr(39)+',';
              _pcs := _pcs + chr(39)+ _anyjaneve + chr(39) + ',';
              _pcs := _pcs + chr(39)+ _szuletesihely + chr(39) + ',';
              _pcs := _pcs + chr(39)+ _szuletesiido + chr(39) + ',';
              _pcs := _pcs + chr(39)+ _lakcim + chr(39) + ',';
              _pcs := _pcs + chr(39)+ _okmanytip + chr(39) + ',';
              _pcs := _pcs + chr(39)+ _azonosito + chr(39) + ',';
              _pcs := _pcs + chr(39)+ _lakcimkartya + chr(39) + ',';
              _pcs := _pcs + '1,' + chr(39)+ _iso + chr(39) + ')';
              with U20query do
                begin
                  close;
                  sql.clear;
                  sql.add(_pcs);
                  Execsql;
                end;
              U20tranz.commit;
              U20dbase.close;
            end;
          u19query.next;
        end;
      u19query.close;
      u19dbase.close;
      inc(_betu);
    end;

  ShowMessage('KÉSZEN VAGYOK');
end;

end.
