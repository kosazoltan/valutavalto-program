unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Strutils, IBDatabase, DB, IBCustomDataSet,
  IBQuery, ComCtrls;

type
  TGETLETTER = class(TForm)
    KILEPOTIMER: TTimer;
    REMOTEQUERY: TIBQuery;
    REMOTEDBASE: TIBDatabase;
    REMOTETRANZ: TIBTransaction;
    CSIK: TProgressBar;
    Label1: TLabel;

   
    procedure FormActivate(Sender: TObject);
    procedure KILEPOTIMERTimer(Sender: TObject);
    procedure MunkaFileBedolgozas;
    procedure RemoteParancs(_ukaz: string);
    procedure StornoTranzakcio;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETLETTER: TGETLETTER;
  _remoteAddress: string = 'www.dekanysoft.co.uk:/var/lib/firebird/2.1/data/valuta.gdb';
  
  _mResult : byte;
  _pcs : string;
  _sorveg: string = chr(13)+chr(10);
  _db,_qq,_owner,_tarspt,_code,_ss,_dnemdb,_bankjegy,_recno: integer;
  _maildir : string = 'c:\receptor\mail\mailstor';
  _srec: TsearchRec;
  _minta: string;
  _markernev: array[0..200] of string;
  _aktMarkernev,_markerPath,_mintafilenev,_munkafileNev,_munkapath: string;
  _bizonylatszam,_pts,_tipus,_tarspts,_dnemdbs,_aktdnems,_veges: string;
  _biztipus,_valutanem,_filter: string;
  _dn: array[0..22] of string;
  _bj: array[0..22] of integer;

  _olvas: Textfile;
  _aktidos,_mamas: string;

implementation

{$R *.dfm}


// =============================================================================
           procedure TGETLETTER.FormActivate(Sender: TObject);
// =============================================================================

var _mNev: string;
    _ido: Tdatetime;

begin
  _mResult := 2;
  _minta := _maildir + '\*.m';
  _mamas := leftstr(datetostr(date),10);
  _ido := Time;
  _aktidos := timetostr(_ido);
  if midstr(_aktidos,2,1)=':' then
     _aktidos := '0' + _aktidos;
  _aktidos := leftstr(_aktidos,8);


  _db := 0;
  if FindFirst(_minta,faAnyfile,_srec)=0 then
    begin
      repeat
        _mNev := _srec.Name;
        _markernev[_db] := _mNev;
        inc(_db)
      until Findnext(_sRec)<>0;
      FindClose(_sRec);
    end else
    begin
      KilepoTimer.enabled := True;
      exit;
    end;

  _qq := 0;
  Csik.Position := 0;
  Csik.Max := _db;
  while _qq<_db do
    begin
      _aktmarkernev := _markernev[_qq];
      _markerPAth := _maildir + '\' + _aktmarkernev;
      _mintafilenev := Leftstr(_aktmarkernev,8)+'*';
      _minta := 'c:\receptor\mail\mailstor\'+_mintafilenev;
      if Findfirst(_minta,faAnyFile,_srec)<>0 then
        begin
          DeleteFile(_markerPath);
        end else
        begin
          _munkaFileNev := _srec.name;
          _munkaPath := _maildir + '\' + _munkaFileNev;
          MunkaFileBedolgozas;
          FindClose(_srec);
          DeleteFile(_munkapath);
          DeleteFile(_markerPath);
        end;
      inc(_qq);
      Csik.Position := _qq;
      
    end;
  _mResult := 1;
  KilepoTimer.Enabled := true;
end;


// =============================================================================
                  procedure TGetLetter.MunkafileBedolgozas;
// =============================================================================


var _dnemsor,_bjegys: string;

begin
  // _OWNER = A pénztár, amely kiadta a bizonylatot amely száma a file neve:

  _bizonylatszam := leftstr(_munkafileNev,7);
  _pts := midstr(_munkafilenev,9,length(_munkafilenev)-8);
  _owner := strtoint(_pts);

  // Megnyitja a bejegyzést:

  Assignfile(_olvas,_munkapath);
  Reset(_olvas);
  readln(_olvas,_tipus);

  // Ha a tipus='ST', tehát az adott bizonylatszámot stornozni kell:

  if leftstr(_tipus,2)='ST' then
    begin
      _bizonylatszam := leftstr(_bizonylatszam,6)+midstr(_tipus,3,1);
      StornoTranzakcio;
      closeFile(_olvas);
      exit;
    end;

  // Beolvasa a társpénztár számstringét:
  readln(_olvas,_tarspts);

  // Beolvassa, hány tételbõl áll a bizonylat:
  readln(_olvas,_dnemdbs);

  // Társpénztárszám dekódolása:
  val(_tarspts,_tarspt,_code);
  if _code<>0 then _tarspt:=0;

  // Ha nincs társpénztár, akkor nincs semmi
  if _tarspt=0 then
    begin
      CloseFile(_olvas);
      exit;
    end;

 // A bizonylat tételek dekódolása:

  val(_dnemdbs,_dnemdb,_code);
  if _code<>0 then _dnemdb := 0;
  if _dnemdb=0 then
    begin
      CLoseFile(_olvas);
      exit;
    end;

  // Most a tételeket tömbökbe tölti:
  _ss := 0;
  while _ss<_dnemDb do
    begin
      readln(_olvas,_dnemsor);
      _aktdnems := leftstr(_dnemsor,3);

      _bjegys := midstr(_dnemsor,5,length(_dnemsor)-4);
      val(_bjegys,_bankjegy,_code);
      if _code<>0 then _bankjegy := 0;
      _bj[_ss] := _bankjegy;
      _dn[_ss] := _aktdnems;
      inc(_ss);
    end;
  readln(_olvas,_veges);
  closeFile(_olvas);

  // A file-nak 'END' felirattal kell végzödnie, különben semmi:
  if _veges<>'END' then exit;

  // ---------------------------------------------------------------------------

  // Az adatok bedolgozása a távoli serverre:

  // A tranzakció alaptipusának meghatározása:
  _biztipus := leftstr(_bizonylatszam,1);  // F=küldés, U=fogadás

  _ss := 0;
  while _ss<_dnemdb do
    begin
      // A két adat: a valutanem és a mennyisége:
      _valutanem := _dn[_ss];
      _bankjegy  := _bj[_ss];

      // Küldés esetén:
      if _biztipus='F' then  // küldés
        begin
          _filter := '(CIMZETT='+inttostr(_tarspt)+')';
          _filter := _filter + ' AND (KULDO='+inttostr(_owner)+')';
        end else  // fogadás
        begin
          _filter := '(CIMZETT='+inttostr(_owner)+')';
          _filter := _filter + ' AND (KULDO='+inttostr(_tarspt)+')';
        end;

      _filter := _filter + ' AND (VALUTANEM='+CHR(39)+_valutanem+chr(39)+')';
      _filter := _filter + ' AND (BANKJEGY='+inttostr(_bankjegy)+')';
      _filter := _filter + ' AND (RENDBEN=0)';

      _pcs := 'SELECT * FROM DAILYMAIL' + _sorveg;
      _pcs := _pcs + 'WHERE ' + _filter;

      remotedbase.close;
      remotedbase.Databasename := _remoteAddress;
      remotedbase.connected := true;

      with Remotequery do
        begin
          Close;
          Sql.Clear;
          sql.Add(_pcs);
          Open;
          First;
          _recno := recno;
          Close;
        end;

      Remotedbase.close;

      // Nincs még bejegyzés erröl a cikkröl:
      if _recno=0 then
        begin
          _pcs := 'INSERT INTO DAILYMAIL (CIMZETT,KULDO,KULDESIDEJE,ATVETELIDEJE,';
          _pcs := _pcs + 'KULDOBIZONYLAT,ATVEVOBIZONYLAT,';
          _pcs := _pcs + 'VALUTANEM,DATUM,RENDBEN,BANKJEGY,STORNO)'+_sorveg;

          if  _biztipus='F' then  // kuldes
            begin
              _pcs := _pcs + 'VALUES (' + inttostr(_tarspt)+',';
              _pcs := _pcs + inttostr(_owner)+',';
              _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
              _pcs := _pcs + chr(39)+chr(39)+',';
              _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
              _pcs := _pcs + chr(39) + chr(39) + ',';
            end else       // fogadas
            begin
              _pcs := _pcs + 'VALUES (' + inttostr(_owner)+',';
              _pcs := _pcs + inttostr(_tarspt)+',';
              _pcs := _pcs + chr(39) + chr(39) + ',';
              _pcs := _pcs + chr(39) + _aktidos + chr(39) + ',';
              _pcs := _pcs + chr(39) + chr(39) + ',';
              _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
            end;

          _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
          _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
          _pcs := _pcs + '0,';
          _pcs := _pcs + inttostr(_bankjegy)+',';
          _pcs := _pcs + '1)';
        end else
        begin     // Ellenoldal már be van jegyezve

          IF _biztipus='F' then  // küldés
            begin
              _pcs := 'UPDATE DAILYMAIL SET KULDESIDEJE='+chr(39)+_aktidos+chr(39)+',';
              _pcs := _pcs + 'KULDOBIZONYLAT='+CHR(39)+_bizonylatszam+chr(39) + ',';
              _pcs := _pcs + 'RENDBEN=1'+_sorveg;
            end else
            begin            // fogadás
              _pcs := 'UPDATE DAILYMAIL SET ATVETELIDEJE='+chr(39)+_aktidos+chr(39)+',';
              _pcs := _pcs + 'ATVEVOBIZONYLAT='+chr(39)+_bizonylatszam+chr(39)+',';
              _pcs := _pcs + 'RENDBEN=1'+_sorveg;
            end;
          _pcs := _pcs + 'WHERE '+ _filter;
        end;
      RemoteParancs(_pcs);
      inc(_ss);
    end;
end;

// =============================================================================
          procedure TGetLetter.RemoteParancs(_ukaz: string);
// =============================================================================

begin
  remotedbase.close;
  remotedbase.Databasename := _remoteAddress;
  remotedbase.connected := true;

  if remoteTranz.intransaction then RemoteTranz.Commit;
  RemoteTranz.startTransaction;
  with Remotequery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_ukaz);
      ExecSql;
    end;
  RemoteTranz.commit;
  Remotedbase.close;
end;


// =============================================================================
          procedure TGETLETTER.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  Kilepotimer.Enabled := false;
  ModalResult := _mResult;
end;

// =============================================================================
                 procedure TGetletter.StornoTranzakcio;
// =============================================================================


begin
  _biztipus := leftstr(_bizonylatszam,1);
  if _biztipus='F' then  // küldes
    begin
      _filter := '(KULDOBIZONYLAT='+chr(39)+_bizonylatszam+chr(39)+')';
      _filter := _filter + ' AND (KULDO=' + inttostr(_owner) + ')';
    end else        //  FOGADÁS
    begin
      _filter := '(ATVEVOBIZONYLAT='+chr(39)+_bizonylatszam+chr(39)+')';
      _filter := _filter + ' AND (CIMZETT=' + inttostr(_owner)+')';
    end;
  _pcs := 'DELETE FROM DAILYMAIL' + _sorveg;
  _pcs := _pcs + 'WHERE '+ _filter;
  RemoteParancs(_pcs);
end;
end.
