unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBTable, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, strutils;

type
  TForm2 = class(TForm)
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    REMOTEQUERY: TIBQuery;
    REMOTEDBASE: TIBDatabase;
    REMOTETRANZ: TIBTransaction;
    KILEPO: TTimer;
    Panel1: TPanel;

    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure RemoteParancs(_ukaz: string);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _sorszam,_tranzdb,_sfto: integer;
  _evimax,_fto: integer;

  _nevtabla,_pcs,_megnyitottnap,_bizonylatszam,_evtizeds,_ugyffdb: string;
  _kezdoBetu,_biztabla,_remotepath,_host: string;
  _sorveg: string = chr(13)+chr(10);


function gongyvisszavonas: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
               function gongyvisszavonas: integer; stdcall;
// =============================================================================

begin
  Form2 := Tform2.Create(Nil);
  result := Form2.showmodal;
  Form2.Free;
end;


// =============================================================================
             procedure TForm2.Button1Click(Sender: TObject);
// =============================================================================

begin
  mODALRESULT := 1;
end;

// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  Panel1.repaint;

  ValutaDbase.Connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _sorszam       := FieldByNAme('SORSZAM').asInteger;
      _nevtabla      := trim(FieldByName('NEVTABLA').asString);
      _bizonylatszam := FieldByNAme('BIZONYLATSZAM').asString;

      close;
      Sql.clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := FieldByNAme('MEGNYITOTTNAP').asString;
      _host := trim(FieldByName('HOST').asString);
      Close;
    end;
  Valutadbase.close;

  // ---------------------------------------------------------------

   _evtizeds := midstr(_megnyitottnap,3,2);
   _ugyffdb := 'UGYFEL' + _evtizeds + '.FDB';

///////////////////   _remotePath := 'C:\RECEPTOR\DATABASE\' + _ugyffdb;
   _remotePath := _host + ':C:\RECEPTOR\DATABASE\' + _ugyffdb;

   RemoteDbase.close;
   Remotedbase.DatabaseName := _remotePath;

  // ---------------------------------------------------------------------------

  if (_nevtabla='') OR (_sorszam=0) then
    begin
      Kilepo.enabled := true;
      exit;
    end;

  // -*-------------------------------------------------------------------------

  if _nevtabla<>'JOGI' then
    begin
      _kezdoBetu := leftstr(_nevtabla,1);
      _biztabla := _kezdobetu + 'BIZ';
    end else _biztabla := 'JOGIBIZ';

  // ---------------------------------------------------------------------------

  _pcs := 'DELETE FROM ' + _biztabla + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39);
  RemoteParancs(_pcs);

  _pcs := 'SELECT * FROM ' + _biztabla + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  Remotedbase.Connected := true;
  with RemoteQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _tranzDb := 0;
  _sfto    := 0;
  _evimax  := 0;

  while not remoteQuery.Eof do
    begin
      inc(_tranzdb);
      _fto := RemoteQuery.fieldByNAme('FIZETENDO').asInteger;
      _sfto := _sfto + _fto;
      if _fto>_evimax then _evimax := _fto;
      RemoteQuery.next;
    end;
  RemoteQuery.close;
  remotedbase.close;

  // ---------------------------------------------------------------------

  _pcs := 'UPDATE ' + _nevtabla +' SET FORINTOSSZEG=' + inttostr(_sfto);
  _pcs := _pcs + ',TRANZAKCIODB='+inttostr(_tranzdb);
  _pcs := _pcs + ',EVIMAX='+inttostr(_evimax);
  _pcs := _pcs + ',HETIOSSZ=0,DATUM='+chr(39)+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_sorszam);
  RemoteParancs(_pcs);
  Kilepo.enabled := true;
end;



// =============================================================================
             procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := 1;
end;


// =============================================================================
              procedure TForm2.RemoteParancs(_ukaz: string);
// =============================================================================

begin
   RemoteDbase.Connected := True;
   if RemoteTranz.InTransaction then RemoteTranz.commit;
   RemoteTranz.StartTransaction;
   with RemoteQuery do
     begin
       Close;
       Sql.clear;
       sql.add(_ukaz);
       Execsql;
     end;
   RemoteTranz.Commit;
   RemoteDbase.close;
end;


end.
