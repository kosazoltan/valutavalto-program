unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, wininet, winsock, strutils, jpeg,
  PicShow,idGlobal, COmObj, ShlObj,ActiveX, IBDatabase, DB, DateUtils,
  IBCustomDataSet, IBQuery, ComCtrls, IBTable;

type
  TForm1 = class(TForm)
    TELEPITOGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    Panel1: TPanel;
    Panel2: TPanel;
    Label1: TLabel;
    KEREMLABEL: TLabel;
    Panel3: TPanel;
    emblema: TPicShow;
    Label4: TLabel;
    Bevel1: TBevel;
    Panel4: TPanel;
    Memo1: TMemo;
    ibquery: TIBQuery;
    ibdbase: TIBDatabase;
    ibtranz: TIBTransaction;
    Panel5: TPanel;
    CSIK: TProgressBar;
    FLY: TAnimate;
    Shape1: TShape;
    Label2: TLabel;
    VERZIOPANEL: TPanel;
    Label5: TLabel;
    ibtabla: TIBTable;
    Label6: TLabel;
    Label7: TLabel;
    VALUTATABLA: TIBTable;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    JELSZOPANEL: TPanel;
    Label3: TLabel;
    VINFPANEL: TPanel;
    Label8: TLabel;
    PWEDIT: TEdit;
    pwokegomb: TBitBtn;
    nopwgomb: TBitBtn;
    Shape2: TShape;

      procedure TELEPITOGOMBClick(Sender: TObject);
    procedure Errorexit(_hibauzenet: string);
    procedure SzerverreLepes;
    procedure Changemblema;
    procedure NewfieldsParaRead;
    procedure OneNewTableRead;
    procedure GetmezoAdatok;
    procedure GettablaAdatok;
    procedure MezoHozzaAdas;
    procedure DDparaRead;
    procedure TablaTorles;
    procedure JelszoBekero;
    procedure JelszoRendben(Sender: TObject);

    function Vaninternet: boolean;
    procedure FormActivate(Sender: TObject);
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure Inifeldolgozas;
    function getNemuresMondat: string;
    function Evaulate(_mm: string): string;
    procedure ReadTablaMezok;
    function ScanMezo(_mnev: string): integer;
    procedure newtableinsert;
    function FileMasolas: boolean;
    procedure NewFieldsInsert;
    function ScanTabla(_tnev: string): integer;
    procedure nopwgombClick(Sender: TObject);
    procedure PWEDITEnter(Sender: TObject);
    procedure PWEDITExit(Sender: TObject);
    procedure PWEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _mezonev,_mezotipus,_mezochar: array of string;
  _mezohossz: array of integer;
  _tablanev: array of string;

  _baseDir: string = 'c:\ertektar';
  _aktdir,_dbs,_remoteDir,_aktfdbpath,_akttablanev: string;
  _subdir: array of string;
  _targetdir,_rDir: array[0..25] of string;
  _fileTomb: array[0..25,0..30] of string;
  _tombDarab: array[0..25] of integer;
  _olvas: Textfile;
  _mondat,_kodword: string;
  _hNet,_hFTP: HINTERNET;
  _findData   : WIN32_FIND_DATA;
  _ftpPort    : integer = 21100;
  _host       : string = '185.43.207.99';

  _ftpPassword: string = 'klc+45%';
  _tab        : char = chr(9);
  _userid     : string = 'ebc-10%';
  _SIKERES    : boolean;

  _remoteFile,_localPath,_pDir,_remotePath,_mamas,_knaps,_pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _subdirdb,_code,_qq,_dirdarab,_filedarab,_equjel,_FF: integer;
  _subdirdarab,_aktfileDarab,_tabladarab: integer;
  _aktev,_aktho,_aktnap,_utdekad,_utev,_utho: word;
  _top,_left,_width,_height,_pp,_mezosorszam,_mezodarab: integer;
  _st: array[1..9] of integer = (1,136,13,18,21,31,41,120,130);
  _nffname,_nfftype: array[0..50] of string;
  _verzio,_mm,_fdbpath,_aktmezonev,_aktmezotipus: string;
  _copydb,_cc,_ntbdb,_nt,_ntdb,_nfdb,_nf,_spk,_deltabdb,_dt: integer;
  _copyfile,_nPath,_nttname,_ntpath,_nfPath: array[0..50] of string;
  _nftname,_ddpath,_ddname: array[0..50] of string;
  _aktfieldDb,_db,_tablasorszam,_csikmax,_lepcso: integer;
  _ntfdb: array[0..50] of integer;
  _ntftype,_ntfname,_ntfcollate: array[0..50,0..50] of string;
  _ntflen: array[0..50,0..50] of integer;
  _aktfile,_aktPath: string;


//function supervisorjelszo: integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';

implementation

{$R *.dfm}


// =============================================================================
              procedure TForm1.TELEPITOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Telepitogomb.Enabled := false;
  Keremlabel.Font.Color := clGray;
  KeremLabel.Repaint;

  if not DirectoryExists(_baseDir) then
    begin
      ShowMessage('AZ ÉRTÉKTÁRI PROGRAM MÉG NINCS TELEPÍTVE');
      Application.Terminate;
      Exit;
    end;

  KilepoGomb.Enabled := False;
  Memo1.Lines.add('Az internet ellenõrzése .....');
  if not VanInternet then
    begin
      ShowMessage('NINCS INTERNET ! A TELEPÍTÉSNEK SZÜKSÉGE VAN INTERNETRE');
      aPPLICATION.Terminate;
      exit;
    end;

  Form1.Repaint;

  SzerverreLepes;
  if _hNet = nil then
    begin
      ShowMessage('Nem tudtam fellépni az internetre ...');
      Application.Terminate;
      exit;
    end;

  // ---------------------------------------------------------------------------

   IF _hFTP = nil then
    begin
      ShowMessage('Itt sem sikerült csatlakozni a szerverhez !');
      InternetCloseHandle(_hNet);
      Application.Terminate;
      Exit;
    end;

  // ----------------------- Change directory ---*****************--------------

  Changemblema;
  Memo1.Lines.Add('Belépési kisérlet a Frissito könyvtárba ...');
  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('\ETFRISSITO'));
  if not _sikeres then
    begin
      ErrorExit('Nem sikerült belépni a Frissitö könyvtárba !');
      Exit;
    end;

  // --------ENDNEWPRG ---------------------------------------------------------

  _remoteFile := 'FRISSITO.INI';
  _localPath  := 'C:\ertektar\bin\frissito.ini';

  Fly.Active := true;
  Fly.Visible := true;

  if Fileexists(_localpath) then DeleteFile(_localpath);

  Memo1.Lines.Add('Frissito.ini letöltése a szerverrõl ...');
  _SIKERES := FtpGetfile(_hFTP,pchar(_remoteFile),pchar(_localPath),
                                           False,0,FTP_TRANSFER_TYPE_BINARY,0);

  if not _sikeres then
    begin
      Errorexit('Hiba történt a letöltés közben. Nem tudok frissíteni');
      Exit;
    end;

  // --------------------------------------------------------------------------
  Memo1.Lines.Add('A frissito.ini rendben betöltödött ...');

  Changemblema;
  Memo1.Lines.Add('A frissítés folyamata megkezdödött ...');

  _copydb := 0;  // Másolandó file-ok
  _ntdb   := 0;  // New Table darab
  _nfdb   := 0;  // New Field darab
  _deltabdb := 0;  // delete ibtable darab

  Inifeldolgozas;
  IF _KODWORD<>'' THEN JelszoBekero ELSE Jelszorendben(Nil);
end;


procedure TForm1.Jelszobekero;

begin
  Pwedit.clear;
  PwOkeGomb.enabled := False;
  VinfPanel.Caption := _verzio+' verzió';
  VinfPanel.repaint;
  with JelszoPanel do
    begin
      Top  := 240;
      Left := 24;
      Visible := True;
    end;
  Activecontrol := Pwedit;
end;


procedure TForm1.JelszoRendben(Sender: TObject);

begin
  JelszoPanel.Visible := False;
  
  _csikmax := _copydb + _ntdb + _nfdb + _deltabdb;
  Csik.Max := _csikmax;
  Csik.Position := 0;
  _lepcso := 0;
  Csik.Visible := true;

  if _copydb>0 then
    begin
      _sikeres := Filemasolas;
      if not _sikeres then
        begin
          ShowMessage('NEM SIKERÜLT A FRISSITÉS !');
          InternetCloseHandle(_hFTP);
          InternetCloseHandle(_hNet);
          Application.Terminate;
          exit;
        end;
     end;

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  if _ntdb>0 then NewTableInsert;
  if _nfdb>0 then NewFieldsInsert;
  if _deltabdb>0 then TablaTorles;

  Fly.Active := false;
  Fly.Visible := False;
  Csik.Visible := False;
  Memo1.Lines.Add('A valutaprogram sikeresen frissitve lett');
  Kilepogomb.Enabled := True;
end;


// =============================================================================
              procedure TForm1.Errorexit(_hibauzenet: string);
// =============================================================================


begin
  ShowMessage(_hibaUzenet);
  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
  Application.Terminate;
end;



// =============================================================================
                 function TForm1.Vaninternet: boolean;
// =============================================================================

var
  _dwConnType: integer;

begin
   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := true;
   except
   end;
end;

// =============================================================================
              procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _aktdir := getcurrentdir;
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;
  _top := trunc((_height-640)/2);
  _left := trunc((_width-870)/2);

  Jelszopanel.Visible := False;

  Top := _top;
  Left := _left;
  _pp := 0;
  Changemblema;

  _mamas := leftstr(datetostr(date),10);
  _aktev := yearof(date);
  _aktho := monthof(date);
  _aktnap:= dayof(date);
  _KODWORD :='';
end;


// =============================================================================
                        procedure TForm1.SzerverreLepes;
// =============================================================================


begin
  if _hFTP<>Nil then InternetcloseHandle(_hFTP);
  _hFTP := Nil;

  if _hNet<>Nil then InternetCloseHandle(_hNet);
  _hNet := Nil;


  Memo1.Lines.add('Fellépés az Internetre');
  _hnet := InternetOpen(pchar('LoadFormServer'),INTERNET_OPEN_TYPE_DIRECT,nil,nil,0);

  if _hNet = nil then
    begin
      ShowMessage('Nem tudtam fellépni az internetre ...');
      exit;
    end;

   Memo1.Lines.Add('Csatlakozási kisérlet a szerverhez ...');
  _hFTP := InternetConnect(_hNet,Pchar(_Host),_ftpPort,Pchar(_userId),
                           PChar(_ftpPassword),INTERNET_SERVICE_FTP,
                           INTERNET_FLAG_PASSIVE,
                           0);

end;


// =============================================================================
              procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;



// =============================================================================
                    procedure TForm1.Changemblema;
// =============================================================================


var _aktstyle: integer;

begin
  inc(_pp);
  if _pp>9 then _pp := 1;
  _aktstyle := _st[_pp];

  with Emblema do
    begin
      stop;
      Clear;
      repaint;
    end;
  Form1.repaint;
  Sleep(100);
  with Emblema do
    begin
      Style := _aktstyle;
      Execute;
      repaint;
    end;

end;


// =============================================================================
                procedure TForm1.Inifeldolgozas;
// =============================================================================


begin

  Memo1.Lines.Add('A frissítés folyamata megkezdödött ...');

  AssignFile(_olvas,_localPath);
  Reset(_olvas);

  _mondat := GetnemuresMondat;

  // ----------------- feldolgozó ciklus ---------------------------------------

  while true do
    begin
      if _mondat='@end' then break;
      _Mondat := eVAULATE(_mondat);
    end;
  Closefile(_olvas);
end;


// =============================================================================
           function TForm1.Evaulate(_mm: string): string;
// =============================================================================


begin
  if leftstr(_mm,7)='@verzio' then
    begin
      _verzio := midstr(_mm,9,length(_mm)-8);
      VerzioPanel.caption := _verzio;
      Verziopanel.repaint;
      result := getNemUresMondat;
      exit;
    end;

  // -------------------- jelszó beolvasás -------------------------------------

  if leftstr(_mm,9)='@password' then
    begin
      _kodword := midstr(_mm,11,length(_mm)-10);
      result := getNemUresMondat;
      exit;
    end;

  // --------------- másolandó file-ok -----------------------------------------

  if leftstr(_mm,4)='@bin' then
    begin
      _copydb := strtoint(midstr(_mm,6,length(_mm)-5));
      Memo1.Lines.add('A frissitendõ file-ok listája');
      _cc := 0;
      while true do
        begin
          _mondat := getNemuresMondat;
          _copyfile[_cc] := _mondat;
          Memo1.Lines.add(_mondat);
          inc(_cc);
          if _cc=_copyDb then break;
        end;
      result := GetnemuresMondat;
      exit;
    end;

  // -------------------- ûj táblák --------------------------------------------

  if leftstr(_mm,9)='@newtable' then
    begin
      Memo1.Lines.add('Az új táblák listája');
      _ntdb := strtoint(midstr(_mm,11,length(_mm)-10));
      _nt := 0;
      while _nt<_ntdb do
        begin
          OneNewTableRead;
          inc(_nt);
        end;
      result := GetnemuresMondat;
      exit;
    end;

   // -------------------- új mezõk --------------------------------------------

  if leftstr(_mm,9)='@newfield' then
    begin
      Memo1.Lines.add('Az új adatmezõk listája');
      _nfdb := strtoint(midstr(_mm,11,length(_mm)-10));
      _nf := 0;
      while _nf<_nfdb do
        begin
          NewfieldsParaRead;
          inc(_nf);
        end;
      result := getnemuresMondat;
      exit;
     end;

  if leftstr(_mm,12)='@deletetable' then
    begin
      Memo1.Lines.Add('Adattábla törlése');
      _deltabdb := strtoint(midstr(_mm,14,length(_mm)-13));
      _dt := 0;
      while _dt<_deltabdb do
        begin
          DDparaRead;
          inc(_dt);
        end;
      result := GetnemUresMondat;
      exit;
    end;
end;


// =============================================================================
                    procedure TForm1.OneNewTableRead;
// =============================================================================


begin
  _mm := GetnemuresMondat; // {

  while true do
    begin
      _mm := GetnemuresMondat;
      if _mm='}' then break;

      if leftstr(_mm,4)='path' then
        begin
          _mm := midstr(_mm,6,length(_mm)-5);
          _ntPath[_nt] := _mm;
          continue;
        end;

      if leftstr(_mm,9)='tablename' then
        begin
          _mm := midstr(_mm,11,length(_mm)-10);
          _nttname[_nt] := _mm;
          Memo1.Lines.add(_mm);
          continue;
        end;

      if leftstr(_mm,10)='fieldcount' then
        begin
          _aktfielddb := strtoint(midstr(_mm,12,length(_mm)-11));
          _ntfdb[_nt] := _aktfielddb;
          Continue;
        end;

      if _mm='<' then
        begin
          _ff := 0;
          ReadTablamezok;
          Continue;
        end;
    end;
end;

// =============================================================================
                     procedure TForm1.ReadTablaMezok;
// =============================================================================


begin
  while _ff<_aktfielddb do
    begin
      _mm := GetNemuresMondat;
      if _mm = '>' then
        begin
          inc(_ff);
          continue;
        end;
      if leftstr(_mm,9)= 'fieldname' then
        begin
          _mm := midstr(_mm,11,length(_mm)-10);
          _ntfname[_nt,_ff] := _mm;
          Memo1.Lines.add(_mm);
          continue;
        end;

      if leftstr(_mm,9)='fieldtype' then
        begin
          _mm := midstr(_mm,11,length(_mm)-10);
          _ntftype[_nt,_ff] := _mm;
          continue;
        end;

      if leftstr(_mm,8)='fieldlen' then
        begin
          _mm := midstr(_mm,10,length(_mm)-9);
          _db := strtoint(_mm);
          _ntflen[_nt,_ff] := _db;
          continue;
        end;

      if leftstr(_mm,7)='collate' then
        begin
          _mm := midstr(_mm,9,length(_mm)-8);
          _ntfcollate[_nt,_ff] := _mm;
          continue;
        end;
    end;
end;


// =============================================================================
                 procedure TForm1.NewfieldsParaRead;
// =============================================================================


begin
  while true do
    begin
      _mm := getnemuresMondat;

      if _mm='<' then continue;

      if leftstr(_mm,4)='path' then
        begin
          _mm := midstr(_mm,6,length(_mm)-5);
          _nfpath[_nf] := _mm;
          continue;
        end;

      if leftstr(_mm,9)='tablename' then
        begin
          _mm := midstr(_mm,11,length(_mm)-10);
          _nftname[_nf] := _mm;
          continue;
        end;

      if leftstr(_mm,9)='fieldname' then
        begin
          _mm := midstr(_mm,11,length(_mm)-10);
          _nffname[_nf] := _mm;
          continue;
        end;


      if leftstr(_mm,9)='fieldtype' then
        begin
          _mm := midstr(_mm,11,length(_mm)-10);
          _nfftype[_nf] := _mm;
          continue;
        end;

      if _mm='>' then break;

    end;
end;


procedure TForm1.DDparaRead;

begin
  _mm := GetnemUresMondat;  // {
  while true do
    begin
      _mm := GetnemUresMondat;
      if _mm='}' then Break;

      if leftstr(_mm,4)='path' then
        begin
          _mm := midstr(_mm,6,length(_mm)-5);
          _ddPath[_dt] := _mm;
          continue;
        end;

      if leftstr(_mm,9)='tablename' then
        begin
          _mm := midstr(_mm,11,length(_mm)-10);
          _ddname[_dt] := _mm;
          Memo1.Lines.add(_mm);
          continue;
        end;
    end;
end;


// =============================================================================
                    function TForm1.getNemuresMondat: string;
// =============================================================================

var _res: string;

begin
  _res := '';
  while _res='' do readLn(_olvas,_res);
  result := trim(lowercase(_res));
end;

// =============================================================================
              function TForm1.Filemasolas: boolean;
// =============================================================================

begin
  result := false;

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('\ETFRISSITO'));
  if not _sikeres then
    begin
      ErrorExit('Nem sikerült belépni a Frissitö könyvtárba !');
      Exit;
    end;

  _qq := 0;
  while _qq<_copydb do
    begin
      _aktfile := _copyfile[_qq];
      Memo1.Lines.add(_aktfile + ' másolása ...');
      inc(_lepcso);
      csik.Position := _lepcso;
      csik.repaint;
      Changemblema;

      _aktpath := 'c:\ERTEKTAR\bin\'+_aktfile;
      if Fileexists(_aktPath) then DeleteFile(_aktpath);
      _SIKERES := FtpGetfile(_hFTP,pchar(_aktFile),pchar(_aktPath),
                                           False,0,FTP_TRANSFER_TYPE_BINARY,0);

      if not _sikeres then exit;
      inc(_qq);
    end;
  result := true;
end;


procedure TForm1.TablaTorles;


var _ddss: integer;

begin
  _ddss := 0;
  while _ddss<_deltabdb do
    begin
      _aktfdbpath := _ddpath[_ddss];
      _aktfile    := uppercase(_ddname[_ddss]);
      ibdbase.close;
      ibdbase.DatabaseName := _aktfdbPath;
      ibdbase.Connected := True;
      ibtabla.close;
      ibtabla.TableName := _aktfile;
      if ibtabla.Exists then
        begin
          Memo1.Lines.add(_aktfile + ' törlése ...');
          inc(_lepcso);
          csik.Position := _lepcso;
          csik.repaint;

          _pcs := 'DROP TABLE ' + _aktfile;
          if ibtranz.InTransaction then ibtranz.Commit;
          ibtranz.StartTransaction;
          with ibquery do
            begin
              Close;
              Sql.Clear;
              sql.Add(_pcs);
              Execsql;
            end;
          ibtranz.Commit;
        end;
      ibdbase.close;
      inc(_ddss);
    end;
end;




// =============================================================================
                  procedure TForm1.newtableinsert;
// =============================================================================


var _ntss,_aktlen: integer;
    _tablanev,_akttype,_aktcol,_plus: string;

begin
  _ntss := 0;
  while _ntss<_ntdb do
    begin
      inc(_lepcso);
      Csik.Position := _lepcso;
      Csik.repaint;
      _fdbpath := _ntpath[_ntss];
      if not fileExists(_fdbpath) then
        begin
          inc(_ntss);
          continue;
        end;

      Valutadbase.Close;
      Valutadbase.DatabaseName := _fdbpath;

      _tablanev := _nttName[_ntss];
      valutadbase.Connected := true;
      Valutatabla.close;

      Valutatabla.TableName := uppercase(_tablanev);
      if Valutatabla.Exists then
        begin
          Valutadbase.close;
          exit;
        end;

      Memo1.Lines.add('Új tábla készitése: ' +_tablanev);
      _fdbpath  := _ntpath[_ntss];
      _aktfielddb := _ntfdb[_ntss];
      _pcs := 'CREATE TABLE '+ _tablanev + ' (' + _sorveg;
      _ff := 0;
      while _ff<_aktfielddb do
        begin
          _pcs := _pcs + _ntfname[_ntss,_ff]+' ';
          _akttype := uppercase(_ntftype[_ntss,_ff]);
          if _akttype='CHAR' then
            begin
              _aktlen := _ntflen[_ntss,_ff];
              _aktcol := _ntfcollate[_ntss,_ff];
              _plus := 'CHAR ('+inttostr(_aktlen)+') CHARACTER SET WIN1250 COLLATE ';
              _plus := _plus + _aktcol;
            end else _plus := _akttype;
          _pcs := _pcs + _plus;
          inc(_ff);
          if _ff=_aktfieldDb then _pcs := _pcs + ')'
          else _pcs := _pcs + ',' + _sorveg;
        end;

      Valutadbase.close;
      valutadbase.databasename := _fdbpath;
      Valutadbase.connected := true;
      if valutatranz.InTransaction then valutatranz.Commit;
      Valutatranz.StartTransaction;
      with ValutaQuery do
        begin
          Close;
          sql.Clear;
          Sql.add(_pcs);
          Execsql;
        end;
      Valutatranz.Commit;
      Valutadbase.close;
      inc(_ntss);
    end;
end;


// =============================================================================
                 procedure TForm1.NewFieldsInsert;
// =============================================================================


begin
  _qq := 0;
  while _qq<_nfdb do
    begin
      inc(_lepcso);
      Csik.Position := _lepcso;
      Csik.Repaint;
      _aktfdbpath := _nfpath[_qq];
      if not fileExists(_aktfdbpath) then
        begin
          inc(_qq);
          continue;
        end;

      _aktTablaNev := uppercase(_nftname[_qq]);
      _aktmezonev  := uppercase(_nffname[_qq]);
      Memo1.Lines.add('Új mezõ hozzáadása: ' + _aktmezonev);
      _aktmezotipus := uppercase(_nffType[_qq]);
      MezoHozzaAdas;
      inc(_qq);
    end;
end;

// =============================================================================
                      procedure TForm1.MezoHozzaAdas;
// =============================================================================

begin

  GetTablaAdatok;
  _tablaSorszam := ScanTabla(_aktTablanev);
  if _TablaSorszam>-1 then
    begin
      GetMezoAdatok;
      _mezosorszam := ScanMezo(_aktMezoNev);
      if _mezosorszam<0 then
        begin
          with ValutaDbase do
            begin
              Close;
              DatabaseName := _aktFdbPath;
            end;

          _pcs := 'ALTER TABLE '+ _aktTablaNev + _sorveg;
          _pcs := _pcs + 'ADD '+ _aktmezonev+ ' '+ _aktMezoTipus;
          Valutadbase.Connected := true;
          if valutatranz.InTransaction then valutatranz.commit;
          Valutatranz.StartTransaction;
          with ValutaQuery do
            begin
              Close;
              sql.clear;
              sql.Add(_pcs);
              Execsql;
            end;
          ValutaTranz.commit;
          Valutadbase.close;
        end;
    end;
end;

// =============================================================================
                        procedure TForm1.GetTablaAdatok;
// =============================================================================


var _tNev: string;

begin

  _pcs := 'SELECT RDB$RELATION_NAME FROM RDB$RELATIONS ';
  _pcs := _pcs + 'WHERE RDB$FLAGS=1';

  Valutadbase.connected :=False;
  ValutaDbase.DatabaseName := _aktFdbPath;
  Valutadbase.Connected := true;

  with Valutaquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
    end;
  _tablaDarab := ValutaQuery.recno;

  SetLength(_tablanev,_tabladarab);

  // A FDB-ben talált táblázatokat a Tablanev-tömbbe irja:
  // A táblák darabszámát a TABLADARAB változóba teszi:

  _cc := 0;
  ValutaQuery.first;
  while not ValutaQuery.Eof do
    begin
      _tnev := Valutaquery.FieldbyName('RDB$RELATION_NAME').asString;
      _tablanev[_cc] := trim(_tnev);
      inc(_cc);
      Valutaquery.Next;
    end;
  ValutaQuery.first;
end;

// =============================================================================
               function Tform1.ScanTabla(_tnev: string): integer;
// =============================================================================

var i: integer;

begin
  result := -1;
  for i := 0 to (_tabladarab-1) do
    begin
      if _tnev=_tablanev[i] then
        begin
          result := i;
          Break;
        end;
    end;
end;

// =============================================
       procedure TForm1.GetMezoAdatok;
// =============================================

var _mnev,_mTipus,_mChar: string;
    _mHossz: integer;

begin

   Valutadbase.close;
   ValutaDbase.DatabaseName := _aktfdbPath;
   ValutaDbase.Connected := True;

   if ValutaTranz.InTransaction then ValutaTranz.Commit;
   Valutatabla.TableName := _aktTablaNev;
   ValutaTabla.Open;

  // Egy új Tábla strukturájának meghatározása:

   _mezoDarab := ValutaTabla.FieldCount;
   ValutaTabla.Close;

  // A Tábla strukturájának és adatainak tömbjét:

   Setlength(_mezonev,_mezodarab);
   SetLength(_mezotipus,_mezodarab);
   SetLength(_mezoHossz,_mezodarab);
   Setlength(_mezochar,_mezodarab);

  // Az SQL parancs-sor összeállitása:

   _pcs := 'SELECT r.RDB$FIELD_NAME AS FIELD_NAME,'+_sorveg;
   _pcs := _pcs + 'f.RDB$FIELD_LENGTH AS FIELD_LENGTH,'+_sorveg;
   _pcs := _pcs + 'case f.RDB$Field_type'+_sorveg;
   _pcs := _pcs + 'WHEN 14 THEN ' + chr(39)+ 'SZÖVEG' + chr(39)+_sorveg;
   _pcs := _pcs + 'WHEN 27 THEN ' + chr(39)+ 'TIZEDES TÖRT' + chr(39)+_sorveg;
   _pcs := _pcs + 'WHEN 8 THEN ' + chr(39)+ 'EGÉSZ SZÁM' + chr(39)+_sorveg;
   _pcs := _pcs + 'WHEN 7 THEN ' + chr(39)+ 'EGÉSZ SZÁM' + chr(39)+_sorveg;
   _pcs := _pcs + 'WHEN 12 THEN ' + chr(39)+ 'DÁTUM' + chr(39)+_sorveg;
   _pcs := _pcs + 'WHEN 13 THEN ' + chr(39)+ 'IDÕ' + chr(39)+_sorveg;
   _pcs := _pcs + 'ELSE ' + chr(39) + 'ISMERTELEN' + chr(39)+_sorveg;
   _pcs := _pcs + 'END AS FIELD_TYPE,'+ _sorveg;
   _pcs := _pcs + 'cset.RDB$CHARACTER_SET_NAME AS FIELD_CHARSET' + _sorveg;
   _pcs := _pcs + 'FROM RDB$RELATION_FIELDS r' + _sorveg;
   _pcs := _pcs + 'LEFT JOIN RDB$FIELDS f ON r.RDB$FIELD_SOURCE=F.RDB$FIELD_NAME' + _sorveg;
   _pcs := _pcs + 'LEFT JOIN RDB$COLLATIONS COLL on r.RDB$COLLATION_ID=COLL.RDB$COLLATION_ID' + _sorveg;
   _pcs := _pcs + 'AND f.RDB$CHARACTER_SET_ID = coll.RDB$CHARACTER_SET_ID' + _sorveg;
   _pcs := _pcs + 'LEFT JOIN RDB$CHARACTER_SETS CSET ON f.RDB$CHARACTER_SET_ID=cset.RDB$CHARACTER_SET_ID'+_sorveg;
   _pcs := _pcs + 'WHERE r.RDB$RELATION_NAME=' + chr(39) + _aktTablaNev + chr(39) + _sorveg;
   _pcs := _pcs + 'ORDER BY r.RDB$FIELD_POSITION' + _sorveg;

  // A struktura meghatározása az SQL parancs segitségével:

  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  // A struktura adatok tömbökbe másolása a QUERYTÁBLÁBÓL:

  _cc := 0;
  while not ValutaQuery.Eof do
    begin
      with ValutaQuery do
        begin
          _mNev := FieldByName('FIELD_NAME').AsString;
          _mTipus:= FieldByName('FIELD_TYPE').AsString;
          _mHossz := FieldByName('FIELD_LENGTH').asinteger;
          _mchar := FieldByName('FIELD_CHARSET').asString;
        end;
      _mnev := trim(_mnev);
      _mezoNev[_cc] := _mNev;
      _mezotipus[_cc] := trim(_mTipus);
      _mezoHossz[_cc] := _mHossz;
      _mezochar[_cc] := trim(_mchar);
      inc(_cc);
      ValutaQuery.Next;
    end;
  ValutaQuery.First;
end;



// =============================================================================
               function Tform1.ScanMezo(_mnev: string): integer;
// =============================================================================

var i: integer;

begin
  result := -1;
  for i := 0 to (_mezodarab-1) do
    begin
      if _mnev=_mezoNev[i] then
        begin
          result := i;
          Break;
        end;
    end;
end;


procedure TForm1.nopwgombClick(Sender: TObject);
begin
  ShowMessage('NEM ISMERI A JELSZÓT ! Frissités nem lehetséges');
  Application.Terminate;
end;

procedure TForm1.PWEDITEnter(Sender: TObject);
begin
  Pwedit.Color := $B0FFFF;
end;

procedure TForm1.PWEDITExit(Sender: TObject);
begin
  Pwedit.Color := clWindow;
end;

procedure TForm1.PWEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var _bejelszo,_pws: string;
    _wbj,_y,_byte,_obyte,_df: byte;

begin
  if ord(key)<>13 then exit;
  _BeJelszo := trim(Pwedit.Text);
  _wbj := length(_bejelszo);
  if _wbj=0 then exit;

  // ---- jelszó dekodolás:

  _pws := '';
  _y := 1;
  while _y<=_wbj do
    begin
      _obyte := ord(_bejelszo[_y]);
      _byte := _oByte+10;
      if _byte>90 then
        begin
          _df := _byte-90;
          _byte := 65+_df;
        end;
      _pws := _pws + chr(_byte);
      inc(_y);
    end;

  if _pws=UPPERCASE(_kodword) then
    begin
      pwOkegomb.Enabled := True;
      Activecontrol := pwOkeGomb;
      exit;
    end;

  Pwedit.clear;
  Activecontrol := Pwedit;
end;

end.



