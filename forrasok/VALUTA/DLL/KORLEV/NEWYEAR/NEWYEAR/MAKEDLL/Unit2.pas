unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBQuery,idGlobal,
  IBCustomDataSet, IBTable;

type
  TForm2 = class(TForm)

    AlapPanel: TPanel;
    Memo1    : TMemo;
    Label1   : TLabel;
    KTabla   : TIBTable;
    KQuery   : TIBQuery;
    KDbase   : TIBDatabase;
    KTranz   : TIBTransaction;
    SQuery   : TIBQuery;
    SDbase   : TIBDatabase;
    STranz   : TIBTransaction;
    Kilepo   : TTimer;

    procedure FormActivate(Sender: TObject);
    procedure Dirdelete(_aktdir: string);
    procedure CopyDir(_source,_target: string);
    procedure CopyRecords(_sTabla,_tTabla: string);
    procedure Kparancs(_ukaz: string);
    procedure Maketabla(_tPath: string);
    procedure KilepoTimer(Sender: TObject);
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _height,_width,_top,_left: word;
  _fdbPath,_pcs,_alapdir,_archdir,_lastdir,_minta,_aktfile,_aktpath: string;
  _targpath: string;

  _sorveg: string = chr(13)+chr(10);
  _sorszam: integer;
  _tartalom,_iktato,_filenev,_datum: string;
  _file: array[1..1500] of string;

  _srec: Tsearchrec;

  _fileDb,_y: word;


function newyearsletter: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
            function newyearsletter: integer; stdcall;
// =============================================================================

begin
  form2 := Tform2.Create(Nil);
  result := Form2.ShowModal;
  form2.free;
end;



// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].height;
  _width  := Screen.Monitors[0].width;
  _top    := round((_height-453)/2);
  _left   := round((_width-444)/2);

  Top     := _top;
  Left    := _left;
  repaint;

  _fdbpath := 'c:\valuta\database\korlevel.fdb';
  Repaint;
  sdbase.close;
  sdbase.DatabaseName := _fdbPath;

  Kdbase.close;
  Kdbase.DatabaseName := _fdbPath;

  // ---------------------------------------------------------------------------

  Kdbase.Connected := true;

  Ktabla.Close;
  Ktabla.TableName := 'ARCHIVE';
  IF not Ktabla.Exists then MakeTabla('ARCHIVE');
  Kdbase.close;

  _pcs := 'DELETE FROM ARCHIVE';
  Kparancs(_pcs);

  // ---------------------------------------------------------------------------

  Kdbase.Connected := true;

  Ktabla.Close;
  Ktabla.TableName := 'LASTYEAR';
  IF not Ktabla.Exists then MakeTabla('LASTYEAR');
  Kdbase.close;

  // ---------------------------------------------------------------------------

  _AlapDir := 'C:\KORLEVEL';
  _ArchDir := _alapdir+'\ARCHIVE';
  _LastDir := _alapdir+'\LASTYEAR';

  if not directoryexists(_alapdir) then Createdir(_alapdir);
  if not directoryexists(_archdir) then Createdir(_archdir);
  if not directoryexists(_lastdir) then Createdir(_lastdir);

  // ---------------------------------------------------------------------------

  DirDelete(_archdir);
  Copydir(_lastdir,_archdir);

  Dirdelete(_lastdir);
  CopyDir(_alapdir,_lastdir);

  Dirdelete(_alapdir);

  // ---------------------------------------------------------------------------

  Memo1.Lines.Add('MÚLT ÉVI LEVELEK ARHIVÁLÁSA');

  CopyRecords('LASTYEAR','ARCHIVE');
  _pcs := 'DELETE FROM LASTYEAR';
  KParancs(_pcs);

  Memo1.Lines.Add('A LEVELEK ÁTMÁSOLÁSA A LASTYEAR TÁBLÁBA');

  CopyRecords('IKTATO','LASTYEAR');
  _pcs := 'DELETE FROM IKTATO';
  KParancs(_pcs);

  // ---------------------------------------------------------------------------

  _pcs := 'UPDATE PARAMETERS SET LASTSORSZAM=0';
  kParancs(_pcs);

  Memo1.Lines.Add('A KÖRLEVELEK ÉV ELEJI NYITÁSA MEGTÖRTÉNT');
  Kilepo.enabled := true;

end;

// =============================================================================
               procedure TForm2.Dirdelete(_aktdir: string);
// =============================================================================

begin
  Memo1.Lines.Add(_aktdir+ ' törlése');

  _filedb := 0;
  _minta := _aktdir + '\*.*';
  if FindFirst(_minta,faArchive,_srec) = 0 then
    begin
      repeat
         _aktfile := _srec.Name;
         if _aktfile>'.' then
           begin
             inc(_filedb);
             _file[_filedb] := _aktfile;
           end;
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  if _filedb>0 then
    begin
      _y := 1;
      while _y<=_filedb do
        begin
          _aktfile := _file[_y];
          _aktpath := _aktdir + '\' + _aktfile;
          sysutils.DeleteFile(_aktpath);
          inc(_y);
        end;
    end;
end;

// =============================================================================
             procedure TForm2.CopyDir(_source,_target: string);
// =============================================================================

begin
  Memo1.Lines.Add(_source + ' BEMÁSOLÁSA ' + _target + ' KÖNYVTÁRBA');
  _filedb := 0;
  _minta := _source + '\*.*';
  if FindFirst(_minta,faArchive,_srec) = 0 then
    begin
      repeat
         _aktfile := _srec.Name;
         if _aktfile>'.' then
           begin
             inc(_filedb);
             _file[_filedb] := _aktfile;
           end;
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

    if _filedb>0 then
    begin
      _y := 1;
      while _y<=_filedb do
        begin
          _aktfile := _file[_y];
          _aktpath := _source + '\' + _aktfile;
          _targpath := _target + '\' + _aktfile;
          copyfileto(_aktpath,_targpath);
          inc(_y);
        end;
    end;
end;

// =============================================================================
           procedure TForm2.CopyRecords(_sTabla,_tTabla: string);
// =============================================================================

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


// =============================================================================
            procedure TForm2.Kparancs(_ukaz: string);
// =============================================================================

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

// =============================================================================
               procedure TForm2.Maketabla(_tPath: string);
// =============================================================================

begin
  _pcs := 'CREATE TABLE ' + _tPath + ' ('+ _sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+ _sorveg;
  _pcs := _pcs + 'IKTATOSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+ _sorveg;
  _pcs := _pcs + 'SORREND SMALLINT,'+ _sorveg;
  _pcs := _pcs + 'SORSZAM SMALLINT,'+ _sorveg;
  _pcs := _pcs + 'FILENEV CHAR (15) CHARACTER SET WIN1250 COLLATE WIN1250,'+ _sorveg;
  _pcs := _pcs + 'TARTALOM CHAR (80) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+ _sorveg;
  _pcs := _pcs + 'STORNO SMALLINT,'+ _sorveg;
  _pcs := _pcs + 'SORTEMP SMALLINT)';
  kParancs(_Pcs);
end;

// =============================================================================
           procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  kILEPO.Enabled := False;
  Application.Terminate;
end;







end.
