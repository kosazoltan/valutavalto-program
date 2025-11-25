unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls,idglobal, ComCtrls;

type
  TForm1 = class(TForm)
    KILEPO: TTimer;
    Label1: TLabel;
    Label2: TLabel;
    Shape1: TShape;
    Memo: TMemo;
    CSIK: TProgressBar;


    procedure Dirdel(_aktdir: string);
//    procedure Zap(_dPath: string);
    procedure fCopy(_sPath: string;_tPath: string);
//    procedure rCopy(_sTabla: string; _tTabla: string);
//    procedure SParancs(_ukaz: string);
//    procedure TParancs(_ukaz: string);
    procedure KilepoTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _kdir : string = 'c:\korlevel';
  _pcs,_minta,_findfile,_delFile,_delPath,_aktfile,_source,_target: string;
  _datum,_iktato,_tartalom,_filenev: string;
  _sorveg: string = chr(13)+chr(10);
  _sorszam,_height,_width,_top,_left: word;
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

  // -------------------------------------------
  {
  Memo.lines.add('Archive tabla törlése');
  zap('ARCHIVE');

  Memo.Lines.Add('Múlt évi nytartás másolása');
  rCopy('LASTYEAR','ARCHIVE');

  Memo.Lines.Add('Lastyear tábla törlése');
  zap('LASTYEAR');

  Memo.Lines.Add('Iktató másolása LastYear táblába');
  rCopy('IKTATO','LASTYEAR');

  Memo.Lines.Add('Iktató-tábla felszabaditása');
  zap('IKTATO');


  Csik.Position := 0;

  Memo.Lines.add('Utolsó sorszám nullázása');
  _pcs := 'UPDATE PARAMETERS SET LASTSORSZAM=0';
  sParancs(_pcs);

  }


  Memo.Lines.add('AZ ÉVNYITÁS SIKERESEM MEGTÖRTÉNT');
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


{
// =============================================================================
                    procedure TForm1.Zap(_dPath: string);
// =============================================================================

begin
  Csik.Position := 0;
  _pcs := 'DELETE FROM '+_dPath;
  sParancs(_pcs);
end;
}

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


{
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
      _pcs := _pcs + 'FILENEV)' + _sorveg;

      _pcs := _pcs + 'VALUES (' + chr(39) + _datum + chr(39) + ',';
      _pcs := _pcs + chr(39) + _iktato + chr(39) + ',';
      _pcs := _pcs + inttostr(_sorszam) + ',';
      _pcs := _pcs + chr(39) + _tartalom + chr(39) + ',';
      _pcs := _pcs + chr(39) + _filenev + chr(39) + ')';
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
}

// =============================================================================
               procedure TForm1.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Application.terminate;
end;


end.
