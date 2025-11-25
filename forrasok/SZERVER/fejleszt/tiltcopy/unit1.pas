unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBQuery, IBDatabase, DB, IBCustomDataSet,
  IBTable, ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    SOURCETABLA: TIBTable;
    SOURCEDBASE: TIBDatabase;
    SOURCETRANZ: TIBTransaction;
    TARGETQUERY: TIBQuery;
    TARGETDBASE: TIBDatabase;
    targetTRANZ: TIBTransaction;
    Panel1: TPanel;
    Panel2: TPanel;
    Label1: TLabel;
    Shape1: TShape;

    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure TargetParancs(_ukaz: string);

    function Marrogzitvevan: boolean;
    function Getsorszam: integer;
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _BETU: BYTE;
  _pcs,_nevtabla,_nev,_szulhely,_szulido,_elozo,_anyja,_leany,_allamp: string;
  _tarthely,_lcimcard,_iso,_okmtip,_azonosito,_lakcim,_mezo: string;
  _sorveg: string = chr(13)+chr(10);
  _sorszam,_kulf,_recno,_ss: integer;

implementation

{$R *.dfm}

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  _Betu := 65;
  Sourcedbase.Connected := true;
  while _betu<=90 do
    begin
      _nevtabla := chr(_betu)+'NEV';
      sourceTabla.close;
      Sourcetabla.Filter := 'TILTVA=1';
      sourcetabla.TableName := _nevtabla;

      Panel1.Caption := _nevtabla;
      Panel1.repaint;

      SourcetablA.open;
      SOURCETABLA.Filtered := true;
      SourceTabla.First;

      while not sourcetabla.eof do
        begin
          _nev := trim(Sourcetabla.fieldByName('NEV').asString);
          _szulhely := trim(Sourcetabla.fieldbyname('SZULETESIHELY').asString);
          _szulido := trim(Sourcetabla.fieldByName('SZULETESIIDO').asString);

          Panel2.Caption := _nev;
          Panel2.repaint;

          if marRogzitvevan then
            begin
              _pcs := 'UPDATE ' + _nevtabla +' SET TILTVA=1' + _sorveg;
              _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
              TargetParancs(_pcs);
              SourceTabla.next;
              Continue;
            end;

          _elozo := trim(sourcetabla.fieldByNAme('ELOZONEV').asString);
          _anyja := trim(SourceTabla.fieldbyname('ANYJANEVE').asString);
          _leany := trim(Sourcetabla.fieldByNAme('LEANYKORI').asString);
          _allamp := trim(SourceTabla.fieldByNAme('ALLAMPOLGAR').asstring);
          _lakcim := trim(SourceTabla.fieldByNAme('LAKCIM').asstring);
          _OKMTIP := trim(SourceTabla.fieldByNAme('OKMANYTIP').asstring);
          _azonosito := trim(SourceTabla.fieldByNAme('AZONOSITO').asstring);
          _tarthely := trim(SourceTabla.fieldByNAme('TARTOZKODASIHELY').asstring);
          _LCIMCARD := trim(SourceTabla.fieldByNAme('LAKCIMKARTYA').asstring);
          _ISO := trim(SourceTabla.fieldByNAme('ISO').asstring);
          _kulf := Sourcetabla.fieldByNAme('KULFOLDI').asInteger;


          _sorszam := getsorszam;

          _pcs := 'INSERT INTO ' + _nevtabla + ' (SORSZAM,NEV,ELOZONEV,ANYJANEVE,';
          _pcs := _pcs + 'LEANYKORI,SZULETESIHELY,SZULETESIIDO,ALLAMPOLGAR,';
          _pcs := _pcs + 'LAKCIM,OKMANYTIP,AZONOSITO,TARTOZKODASIHELY,KULFOLDI,';
          _pcs := _pcs + 'LAKCIMKARTYA,ISO,TILTVA)' + _sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(_sorszam) + ',';
          _pcs := _pcs + chr(39) + _nev + chr(39) + ',';
          _pcs := _pcs + chr(39) + _elozo + chr(39) + ',';
          _pcs := _pcs + chr(39) + _anyja + chr(39) + ',';
          _pcs := _pcs + chr(39) + _leany + chr(39) + ',';
          _pcs := _pcs + chr(39) + _szulhely + chr(39) + ',';
          _pcs := _pcs + chr(39) + _szulido + chr(39) + ',';
          _pcs := _pcs + chr(39) + _allamp + chr(39) + ',';
          _pcs := _pcs + chr(39) + _lakcim + chr(39) + ',';
          _pcs := _pcs + chr(39) + _okmtip + chr(39) + ',';
          _pcs := _pcs + chr(39) + _azonosito + chr(39) + ',';
          _pcs := _pcs + chr(39) + _tarthely + chr(39) + ',';
          _pcs := _pcs + inttostr(_kulf) + ',';
          _pcs := _pcs + chr(39) + _lcimcard + chr(39) + ',';
          _pcs := _pcs + chr(39) + _iso + chr(39) + ',1)';
          TargetParancs(_pcs);

          Sourcetabla.next;
        end;
      Sourcetabla.close;
      inc(_betu);
    end;
  Sourcedbase.close;
  Showmessage('KÉSZEN VAN');
end;


function TForm1.Marrogzitvevan: boolean;

begin
  result := False;


  TargetDbase.connected := true;
  _pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
  _pcs := _pcs + 'WHERE (NEV='+chr(39)+_nev+chr(39)+') AND (';
  _pcs := _pcs + 'SZULETESIHELY='+chr(39) + _szulhely + chr(39)+') AND (';
  _pcs := _pcs + 'SZULETESIIDO=' + chr(39) + _szulido + chr(39)+')';
  with Targetquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;
  if _recno>0 then
    begin
      _sorszam := TargetQuery.FieldByNAme('SORSZAM').asInteger;
      result := True;
    end;
  TargetQuery.close;
  Targetdbase.close;
end;      

procedure TForm1.TargetParancs(_ukaz: string);
begin
  targetdbase.connected := True;
  if targettranz.InTransaction then targettranz.Commit;
  TargetTranz.StartTransaction;
  with Targetquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  TargetTranz.commit;
  Targetdbase.close;
end;



function TForm1.Getsorszam: integer;

begin
 
  _mezo := chr(_betu)+'LAST';
  _pcs := 'SELECT * FROM LASTNUMS';
  TARGETDBASE.CONNECTED := TRUE;
  with Targetquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _SS := fieldbyName(_mezo).asInteger;
      Close;
    end;
  Targetdbase.close;

  RESULT := _ss+1;
  _pcs := 'UPDATE LASTNUMS SET ' + _MEZO + '=' +inttostr(RESULT);
  TargetParancs(_pcs);
end;




end.
