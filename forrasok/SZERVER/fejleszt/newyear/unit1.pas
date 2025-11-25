unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls,idglobal, ComCtrls;

type
  TForm1 = class(TForm)
    SQUERY: TIBQuery;
    SDBASE: TIBDatabase;
    STRANZ: TIBTransaction;
    TQUERY: TIBQuery;
    TDBASE: TIBDatabase;
    TTRANZ: TIBTransaction;
    KILEPO: TTimer;
    Label1: TLabel;
    Label2: TLabel;
    Shape1: TShape;
    Memo: TMemo;
    CSIK: TProgressBar;


    procedure Dirdel(_aktdir: string);
    procedure Zap(_dPath: string);
    procedure fCopy(_sPath: string;_tPath: string);
    procedure rCopy(_sTabla: string; _tTabla: string);
    procedure SParancs(_ukaz: string);
    procedure TParancs(_ukaz: string);
    procedure KilepoTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure SigCopy(_sTabla: string;_tTabla: string);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _kdir : string = 'c:\receptor\mail\korlevel';
  _pcs,_minta,_findfile,_delFile,_delPath,_aktfile,_source,_target: string;
  _datum,_tartalom,_filenev,_MIKOR,_iktato: string;
  _sorveg: string = chr(13)+chr(10);
  _sorszam,_height,_width,_top,_left,_lettnum,_dolgsors: word;
  _qdb,_findsize,_qq: word;
  _srec: TSearchrec;
  _qFile: array[1..1024] of string;
  _recno: integer;



implementation

{$R *.dfm}

// =============================================================================
              procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-392)/2);
  _left := round((_width-336)/2);

  Top := _top;
  Left := _left;
  repaint;


  Memo.Lines.Add('Archive könyvtár törlése');
  dirdel(_kdir+'\ARCHIVE');

  Memo.Lines.add('Múlt évi levelek archiválása');
  fCopy(_kdir+'\LASTYEAR',_kdir+'\archive');

  Memo.Lines.Add('Mult évi levéltár felszabaditása');
  dirdel(_kdir+'\lastyear');

  Memo.Lines.add('Levelek áttöltése a múlt évi tárolóba');
  fCopy(_kdir,_kdir+'\lastyear');

  Memo.Lines.Add('Körlevél könyvtár felszabaditása');
  dirdel(_kdir);

  // ************

    Memo.Lines.Add('VIP_archive könyvtár törlése');
  dirdel(_kdir+'\V_ARCHIVE');

  Memo.Lines.add('VIP múlt évi levelek archiválása');
  fCopy(_kdir+'\V_LASTYEAR',_kdir+'\v_archive');

  Memo.Lines.Add('VIP mult évi levéltár felszabaditása');
  dirdel(_kdir+'\v_lastyear');

  Memo.Lines.add('VIP levelek áttöltése a múlt évi tárolóba');
  fCopy(_kdir+'\vip',_kdir+'\v_lastyear');

  Memo.Lines.Add('VIP könyvtár felszabaditása');
  dirdel(_kdir+'\vip');

  // ******************

    Memo.Lines.Add('Zalog archive könyvtár törlése');
  dirdel(_kdir+'\Z_ARCHIVE');

  Memo.Lines.add('Zálog múlt évi levelek archiválása');
  fCopy(_kdir+'\Z_LASTYEAR',_kdir+'\z_archive');

  Memo.Lines.Add('Zálog mult évi levéltár felszabaditása');
  dirdel(_kdir+'\z_lastyear');

  Memo.Lines.add('Zálog levelek áttöltése a múlt évi tárolóba');
  fCopy(_kdir+'\zalog',_kdir+'\z_lastyear');

  Memo.Lines.Add('Zálog könyvtár felszabaditása');
  dirdel(_kdir+'\zalog');

  // =====================================================

  Memo.lines.add('Archive tabla törlése');
  zap('ARCHIVE');

  Memo.Lines.Add('Múlt évi nytartás másolása');
  rCopy('LASTYEAR','ARCHIVE');

  Memo.Lines.Add('Lastyear tábla törlése');
  zap('LASTYEAR');

  Memo.Lines.Add('Iktató másolása LastYear táblába');
  rCopy('KORLEVEL','LASTYEAR');

  Memo.Lines.Add('Iktató-tábla felszabaditása');
  zap('KORLEVEL');

  // *********

  Memo.lines.add('Zálog archive tabla törlése');
  zap('Z_ARCHIVE');

  Memo.Lines.Add('Zálog múlt évi nytartás másolása');
  rCopy('Z_LASTYEAR','Z_ARCHIVE');

  Memo.Lines.Add('Zálog lastyear tábla törlése');
  zap('Z_LASTYEAR');

  Memo.Lines.Add('Záloglevél másolása LastYear táblába');
  rCopy('ZALOGLEVEL','Z_LASTYEAR');

  Memo.Lines.Add('Zálog-tábla felszabaditása');
  zap('ZALOGLEVEL');

  // *********

  Memo.lines.add('VIP archive tabla törlése');
  zap('V_ARCHIVE');

  Memo.Lines.Add('VIP múlt évi nytartás másolása');
  rCopy('V_LASTYEAR','V_ARCHIVE');

  Memo.Lines.Add('VIP lastyear tábla törlése');
  zap('V_LASTYEAR');

  Memo.Lines.Add('Viplevél másolása LastYear táblába');
  rCopy('VIPLEVEL','V_LASTYEAR');

  Memo.Lines.Add('Viplevél-tábla felszabaditása');
  zap('VIPLEVEL');

  // *********

  zap('SIGN_ARCHIVE');
  sigcopy('SIGN_LASTYEAR','SIGN_ARCHIVE');
  ZAP('SIGN_LASTYEAR');

  sigcopy('SIGNAL','SIGN_LASTYEAR');
  ZAP('SIGNAL');

  // ------------------------------------

  zap('Z_SIGN_ARCHIVE');
  sigcopy('Z_SIGN_LASTYEAR','Z_SIGN_ARCHIVE');
  ZAP('Z_SIGN_LASTYEAR');

  sigcopy('ZSIGNAL','Z_SIGN_LASTYEAR');
  ZAP('ZSIGNAL');

  // ------------------------------------
  zap('VSIGN_ARCHIVE');
  sigcopy('VSIGN_LASTYEAR','VSIGN_ARCHIVE');
  ZAP('VSIGN_LASTYEAR');

  sigcopy('VIPSIGNAL','VSIGN_LASTYEAR');
  ZAP('VIPSIGNAL');

  // ------------------------------------

  Csik.Position := 0;

  Memo.Lines.add('Utolsó sorszámOK nullázása');
  _pcs := 'UPDATE ADATOK SET UTSORSZAM=0,UTVIPSORSZAM=0,UTZALOGSORSZAM=0';
  sParancs(_pcs);
  Memo.Lines.add('KÖRLEVELEK SIKERESEN MEGNYITVA');
  Kilepo.enabled := True;
end;

// =============================================================================
                 procedure TForm1.Dirdel(_aktdir: string);
// =============================================================================

begin
  Csik.Position := 0;
  _minta := _aktdir + '\*.*';
  _qdb := 0;
  if FindFirst(_minta, faAnyFile, _sRec) = 0 then
  begin
    repeat
      _findfile := _srec.name;
      _findsize := _srec.size;
      if _findsize>3 then
        begin
          inc(_qdb);
          _qFile[_qdb] := _findfile;
        end;
    until FindNext(_srec) <> 0;
    FindClose(_srec);
  end;
  if _qdb=0 then exit;

  Csik.Max := _qdb;
  _qq := 1;
  while _qq<=_qdb do
    begin
      Csik.Position := _qq;
      _delfile := _qFile[_qq];
      _delPath := _aktdir + '\' + _delFile;
      sysutils.DeleteFile(_delPath);
      inc(_qq);
    end;
end;


// =============================================================================
                    procedure TForm1.Zap(_dPath: string);
// =============================================================================

begin
  Csik.Position := 0;
  _pcs := 'DELETE FROM '+_dPath;
  sParancs(_pcs);
end;


// =============================================================================
           procedure TForm1.fCopy(_sPath: string;_tPath: string);
// =============================================================================

begin
  Csik.Position := 0;
  _minta := _spath + '\*.*';
  _qdb := 0;
  if FindFirst(_minta, faAnyFile, _sRec) = 0 then
  begin
    repeat
      _findfile := _srec.name;
      _findsize := _srec.size;
      if _findsize>3 then
        begin
          inc(_qdb);
          _qFile[_qdb] := _findfile;
        end;
    until FindNext(_srec) <> 0;
    FindClose(_srec);
  end;

  if _qdb=0 then exit;
  Csik.Max := _qdb;

  _qq := 1;
  while _qq<=_qdb do
    begin
      Csik.Position := _qq;
      _aktfile := _qfile[_qq];
      _source := _spath + '\' + _aktfile;
      _target := _tpath + '\' + _aktfile;
      copyfileto(_source,_target);
      inc(_qq);
    end;
end;




// =============================================================================
              procedure TForm1.RCopy(_sTabla: string;_tTabla: string);
// =============================================================================

begin
  Csik.Position := 0;
  _pcs := 'SELECT * FROM ' + _sTabla;
  sdbase.connected := True;
  with Squery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      Squery.close;
      Sdbase.close;
      exit;
    end;

  Csik.Max := _recno;
  _qq := 0;
  while not squery.eof do
    begin
      inc(_qq);
      Csik.Position := _qq;

      _datum    := Squery.fieldbyname('DATUM').asString;
      _iktato   := trim(Squery.FieldByName('IKTATOSZAM').asString);
      _sorszam  := Squery.FieldByName('SORSZAM').asInteger;
      _tartalom := trim(Squery.FieldByName('TARTALOM').asString);
      _filenev  := trim(Squery.Fieldbyname('FILENEV').asString);

      _PCS := 'INSERT INTO ' + _tTabla + ' (DATUM,IKTATOSZAM,SORSZAM,TARTALOM,';
      _pcs := _pcs + 'FILENEV,STORNO)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _iktato + chr(39) + ',';
      _pcs := _pcs + inttostr(_sorszam) + ',';
      _pcs := _pcs + chr(39) + _tartalom + chr(39) + ',';
      _pcs := _pcs + chr(39) + _filenev + chr(39) + ',1)';
      tParancs(_pcs);

      Squery.next;
    end;
  Squery.close;
  Sdbase.close;
end;


// =============================================================================
              procedure TForm1.SigCopy(_sTabla: string;_tTabla: string);
// =============================================================================

begin
  Csik.Position := 0;
  _pcs := 'SELECT * FROM ' + _sTabla;
  sdbase.connected := True;
  with Squery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      Squery.close;
      Sdbase.close;
      exit;
    end;

  Csik.Max := _recno;
  _qq := 0;
  while not squery.eof do
    begin
      inc(_qq);
      Csik.Position := _qq;

      _mikor    := Squery.fieldbyname('MIKOR').asString;
      _LETTNUM  := Squery.FieldByName('LETTERNUM').asInteger;
      _DOLGSORS := Squery.FieldByName('DOLGSORSZAM').asInteger;

      _PCS := 'INSERT INTO ' + _tTabla + ' (MIKOR,DOLGSORSZAM,LETTERNUM)'+_sorveg;

      _pcs := _pcs + 'VALUES (' + chr(39) + _mikor + chr(39) + ',';
      _pcs := _pcs + inttostr(_dolgsors) + ',';
      _pcs := _pcs + inttostr(_lettnum) + ')';
      tParancs(_pcs);

      Squery.next;
    end;
  Squery.close;
  Sdbase.close;
end;




// =============================================================================
                procedure TForm1.SParancs(_ukaz: string);
// =============================================================================

begin
   Sdbase.connected := true;
   if Stranz.InTransaction then STranz.commit;
   Stranz.StartTransaction;
   with SQuery do
     begin
       Close;
       sql.clear;
       sql.add(_ukaz);
       Execsql;
     end;
   Stranz.commit;
   Sdbase.close;
end;

// =============================================================================
                  procedure TForm1.TParancs(_ukaz: string);
// =============================================================================

begin
   Tdbase.connected := true;
   if ttranz.InTransaction then TTranz.commit;
   ttranz.StartTransaction;
   with TQuery do
     begin
       Close;
       sql.clear;
       sql.add(_ukaz);
       Execsql;
     end;
   ttranz.commit;
   tdbase.close;
end;


// =============================================================================
               procedure TForm1.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Application.terminate;
end;


end.
