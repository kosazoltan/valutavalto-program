unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls, Buttons,
  DateUtils, strutils, idglobal, ExtCtrls;

type
  TForm1 = class(TForm)
    STARTGOMB: TBitBtn;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    ENDGOMB: TButton;
    Shape1: TShape;
    Label1: TLabel;
    Memo1: TMemo;
    Label2: TLabel;
    Shape2: TShape;

    procedure STARTGOMBClick(Sender: TObject);
    procedure getTablaNevek;
    procedure ibparancs(_ukaz: string);
    procedure ENDGOMBClick(Sender: TObject);

    procedure FormActivate(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _tablanevek: array[0..600] of string;
  _tablaDarab,_tablanevhossz,_arctabla: integer;
  _arcdir: string = 'c:\valuta\archive';
  _sourcepath: string = 'c:\valuta\database\valdata.fdb';
  _aktev,_utjoev,_arcev: word;
  _arcfile,_targetpath,_elsojofarok,_akttablanev,_aktfarok,_pcs: string;
  _oke: boolean;
  _farokasc: byte;
  _height,_width,_top,_left: word;

implementation

{$R *.dfm}

procedure TForm1.STARTGOMBClick(Sender: TObject);
var _qq: integer;
begin
  StartGomb.Enabled := False;
  EndGomb.Enabled := false;
  
  if not DirectoryExists(_arcdir) then CreateDir(_arcdir);

  _aktev := yearof(date);
  _utjoev := _aktev-1;
  _arcev := _utjoev-1;
  _arcfile := 'VDAT' + inttostr(_arcev)+'.fdb';

  _targetPath := _arcdir + '\' + _arcfile;
  _elsojofarok := midstr(inttostr(_utjoev),3,2)+'01';

  if Fileexists(_targetPath) then
    begin
      ShowMessage('AZ IDEI ARCHIVÁLÁS MÁR MEGTÖRTÉNT !');
      Application.Terminate;
      exit;
    end;

  _oke := copyFileto(_sourcepath,_targetPath);
  if not _oke then
    begin
      ShowMessage('NEM SIKERÜLT A VALDATA.FDB-T ELMÁSOLNI !');
      Application.Terminate;
      Exit;
    end;

  _tabladarab := 0;
  GetTablaNevek;

  if _tablaDarab=0 then
    begin
      ShowMessage('NEM TALÁLT EGYETLEN TÁBLÁT SEM A VALDATÁBAN !?');
      Application.Terminate;
      Exit;
    end;

  // ------------------------------------------------------------------

  _arcTabla := 0;
  _qq := 1;
  while _qq<_tablaDarab do
    begin
      _aktTablanev := _tablaNevek[_qq];
      _tablanevHossz := length(_aktTablanev);
      _aktfarok := midstr(_aktTablanev,(_tablanevhossz-3),4);
      _farokAsc := ord(_aktfarok[1]);
      if _farokAsc<57 then
        begin
          if _aktfarok<_elsojofarok then
            begin
              _pcs := 'DROP TABLE ' + _akttablanev;
              IbParancs(_pcs);

              memo1.Lines.add(_akttablanev+chr(9)+'archiválva ...');
              Memo1.Repaint;

              inc(_arcTabla);
            end;
        end;
      inc(_qq);
    end;
  Memo1.Lines.add('ADATTÁBLÁK ARCHIVÁLVA !');
  mEMO1.REPAINT;
  ShowMessage(inttostr(_arctabla)+ ' DARAB ADATTÁBLÁT ARCHIVÁLTAM');
  Application.Terminate;
end;


procedure TForm1.ibparancs(_ukaz: string);

begin
  ibdbase.connected := True;
  if ibtranz.InTransaction then IbTranz.Commit;
  ibtranz.StartTransaction;
  with ibquery do
    begin
      Close;
      sql.clear;
      sql.Add(_ukaz);
      execSql;
    end;
  ibtranz.commit;
  ibdbase.close;
end;


procedure TForm1.getTablaNevek;

var _cc: integer;

begin
  _pcs := 'SELECT RDB$RELATION_NAME FROM RDB$RELATIONS ';
  _pcs := _pcs + 'WHERE RDB$FLAGS=1';

  ibDbase.connected :=False;
  ibDbase.DatabaseName := _sourcePath;
  ibDbase.Connected := true;
  with IbQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  // A FDB-ben talált táblázatokat a Tablanevek-tömbbe irja:
  // A táblák darabszámát a TABLADARAB változóba teszi:

  _cc := 0;
  while not ibquery.Eof do
    begin
      _tablanevek[_cc] := trim(ibQuery.FieldbyName('RDB$RELATION_NAME').asString);
      inc(_cc);
      ibQuery.Next;
    end;
  _tablaDarab := _cc;
  ibQuery.Close;
  ibDbase.close;

end;

procedure TForm1.ENDGOMBClick(Sender: TObject);
begin
  Application.Terminate;
end;


procedure TForm1.FormActivate(Sender: TObject);
begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top := round((_height-640)/2);
  _left := round((_width-870)/2);
  Top := _top;
  Left := _left;
  ActiveControl := startgomb;

end;

end.
