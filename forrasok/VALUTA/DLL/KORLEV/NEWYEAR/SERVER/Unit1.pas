unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  IBTable, idglobal, ExtCtrls;

type
  TForm1 = class(TForm)
    KQUERY: TIBQuery;
    KDBASE: TIBDatabase;
    KTRANZ: TIBTransaction;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    ktabla: TIBTable;
    KILEPO: TTimer;
    Memo1: TMemo;
    Panel1: TPanel;
    Shape1: TShape;
    SQUERY: TIBQuery;
    SDBASE: TIBDatabase;
    STRANZ: TIBTransaction;
    PTQUERY: TIBQuery;
    PTDBASE: TIBDatabase;
    PTTRANZ: TIBTransaction;

    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);

    procedure Kparancs(_ukaz: string);
    procedure copysign(_stabla,_tTabla: string);
    procedure Ptparancs(_ukaz: string);

    procedure KILEPOTimer(Sender: TObject);
    procedure CopyRecords(_sTabla,_tTabla: string);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _fdbPath,_pcs,_alapdir,_archdir,_lastdir,_minta,_aktfile,_aktpath: string;
  _targpath: string;

  _sorveg: string = chr(13)+chr(10);

  _SORSZAM,_dolgsorszam,_letter: INTEGER;
  _tartalom,_iktato,_filenev,_datum,_mikor: string;

  _file: array[1..500] of string;

  _srec: Tsearchrec;

  _fileDb,_y: word;


implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _fdbpath := 'c:\receptor\database\korlevel.fdb';

  sdbase.close;
  sdbase.DatabaseName := _fdbPath;

  Kdbase.close;
  Kdbase.DatabaseName := _fdbPath;

  // ---------------------------------------------------------------------------

  _pcs := 'DELETE FROM ARCHIVE';
  Kparancs(_pcs);

  Memo1.Lines.Add('Múlt évi rekordok archiválása');

  CopyRecords('LASTYEAR','ARCHIVE');
  _pcs := 'DELETE FROM LASTYEAR';
  KParancs(_pcs);

  Memo1.Lines.Add('Körlevelek rekordjai múlt évbe másolása');

  CopyRecords('KORLEVEL','LASTYEAR');
  _pcs := 'DELETE FROM KORLEVEL';
  KParancs(_pcs);

   // ---------------------------------------------------------------------------

  _pcs := 'DELETE FROM Z_ARCHIVE';
  Kparancs(_pcs);

  Memo1.Lines.Add('Zálog rekordok archiválása');

  CopyRecords('Z_LASTYEAR','Z_ARCHIVE');
  _pcs := 'DELETE FROM Z_LASTYEAR';
  KParancs(_pcs);

  Memo1.Lines.Add('Zálog rekordok múlt évbe másolása');

  CopyRecords('ZALOGLEVEL','Z_LASTYEAR');
  _pcs := 'DELETE FROM ZALOGLEVEL';
  KParancs(_pcs);

     // ---------------------------------------------------------------------------

  _pcs := 'DELETE FROM V_ARCHIVE';
  Kparancs(_pcs);

  Memo1.Lines.Add('VIP évi rekordok archiválása');

  CopyRecords('V_LASTYEAR','V_ARCHIVE');
  _pcs := 'DELETE FROM V_LASTYEAR';
  KParancs(_pcs);

  Memo1.Lines.Add('VIP rekordok múlt évbe másolása');

  CopyRecords('VIPLEVEL','V_LASTYEAR');
  _pcs := 'DELETE FROM VIPLEVEL';
  KParancs(_pcs);

  // ---------------------------------------------------------------------------


  _pcs := 'DELETE FROM SIGN_ARCHIVE';
  Kparancs(_pcs);

  Memo1.Lines.Add('A múlt évi signal archiválása');

  CopySign('SIGN_LASTYEAR','SIGN_ARCHIVE');
  _pcs := 'DELETE FROM SIGN_LASTYEAR';
  KParancs(_pcs);

  Memo1.Lines.Add('A signal múlt évbe másolasa');

  CopySign('SIGNAL','SIGN_LASTYEAR');
  _pcs := 'DELETE FROM SIGNAL';
  KParancs(_pcs);

    // ---------------------------------------------------------------------------

  _pcs := 'DELETE FROM Z_SIGN_ARCHIVE';
  KParancs(_pcs);
  Copysign('Z_SIGN_LASTYEAR','Z_SIGN_ARCHIVE');
  _PCS := 'DELETE FROM Z_SIGN_LASTYEAR';

  Memo1.Lines.Add('Múlt évi zalog rekordok archiválása');

  CopySign('ZSIGNAL','Z_SIGN_LASTYEAR');
  _pcs := 'DELETE FROM ZSIGNAL';
  KParancs(_pcs);

     // ---------------------------------------------------------------------------

  _PCS := 'DELETE FROM VSIGN_ARCHIVE';
  KParancs(_pcs);

  CopySign('VSIGN_LASTYEAR','VSIGN_ARCHIVE');
  Memo1.Lines.Add('VIP rekordok másolása last-yearbe');

  _pcs := 'DELETE FROM VSIGN_LASTYEAR';
  Kparancs(_pcs);

  CopySign('VIPSIGNAL','VSIGN_LASTYEAR');
  _pcs := 'DELETE FROM VIPSIGNAL';
  KParancs(_pcs);

  Memo1.Lines.Add('Sorszámok nullázáa');

  _pcs := 'UPDATE ADATOK SET UTSORSZAM=0,UTVIPSORSZAM=0,UTZALOGSORSZAM=0';
  KParancs(_pcs);

  Memo1.Lines.Add('oLVASOTT LEVELEK NULLÁZÁSA');

  _PCS := 'Update penztarosok set LASTREADLETTER=0';
  PtParancs(_pcs);


  Memo1.Lines.Add('A KÖRLEVELEK ÉV ELEJI NYITÁSA MEGTÖRTÉNT');
  Kilepo.enabled := true;

end;




procedure TForm1.CopyRecords(_sTabla,_tTabla: string);

begin
  _pcs := 'SELECT * FROM ' + _sTabla;

  sdbase.connected := true;
  with Squery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  while not squery.eof do
    begin
      _sorszam := Squery.fieldByNAme('SORSZAM').asInteger;
      _tartalom := trim(Squery.FieldByName('TARTALOM').asString);
      _datum := Squery.FieldByNAme('DATUM').asString;
      _filenev := trim(Squery.FieldByName('FILENEV').asString);
      _iktato := trim(Squery.FieldByNAme('IKTATOSZAM').asString);

      _pcs := 'INSERT INTO '+ _tTabla + ' (SORSZAM,TARTALOM,DATUM,FILENEV,IKTATOSZAM)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_sorszam)+',';
      _pcs := _pcs + chr(39)+_tartalom+chr(39) + ',';
      _pcs := _pcs + chr(39)+_datum+chr(39) + ',';
      _pcs := _pcs + chr(39) + _filenev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _iktato + chr(39)+')';
      Kparancs(_pcs);

      Squery.next;
    end;
  Squery.close;
  Sdbase.close;
end;

procedure TForm1.Kparancs(_ukaz: string);

begin
  Kdbase.connected := True;
  if ktranz.InTransaction then KTranz.commit;
  Ktranz.StartTransaction;
  with Kquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Ktranz.Commit;
  Kdbase.close;
end;


procedure TForm1.Ptparancs(_ukaz: string);

begin
  Ptdbase.connected := True;
  if Pttranz.InTransaction then PtTranz.commit;
  Pttranz.StartTransaction;
  with Ptquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  Pttranz.Commit;
  Ptdbase.close;
end;


procedure TForm1.KILEPOTimer(Sender: TObject);
begin
  kILEPO.Enabled := False;
  Application.Terminate;
end;

procedure TForm1.copysign(_stabla,_tTabla: string);

begin
  _pcs := 'SELECT * FROM ' + _sTabla;
   sdbase.connected := true;
  with Squery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  while not squery.eof do
    begin
      _dolgsorszam := Squery.fieldbyname('DOLGSORSZAM').asInteger;
      _letter := Squery.FieldByName('LETTERNUM').asInteger;
      _mikor := Squery.FieldByName('MIKOR').ASsTRING;

      mEMO1.Lines.Add(_MIKOR);

      _pcs := 'INSERT INTO ' + _tTabla + ' (DOLGSORSZAM,LETTERNUM,MIKOR)'+_SORVEG;
      _pcs := _pcs + 'VALUES (' + inttostr(_dolgsorszam) + ',';
      _pcs := _pcs + inttostr(_letter) + ',';
      _pcs := _pcs + chr(39)+_mikor + chr(39) + ')';
      Kparancs(_pcs);

      Squery.next;
    end;
  Squery.close;
  Sdbase.close;

end;


end.
