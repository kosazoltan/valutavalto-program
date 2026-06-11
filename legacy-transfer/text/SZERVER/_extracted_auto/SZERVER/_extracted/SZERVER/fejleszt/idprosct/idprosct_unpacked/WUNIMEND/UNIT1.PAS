unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls, IBTable,
  ExtCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    hoedit: TEdit;
    PQUERY: TIBQuery;
    PDBASE: TIBDatabase;
    PTRANZ: TIBTransaction;
    WQUERY: TIBQuery;
    WDBASE: TIBDatabase;
    WTRANZ: TIBTransaction;
    BFQUERY: TIBQuery;
    BFDBASE: TIBDatabase;
    BFTRANZ: TIBTransaction;
    Button2: TButton;
    Label1: TLabel;
    wtabla: TIBTable;
    BFTABLA: TIBTable;
    penztarpanel: TPanel;
    datumpanel: TPanel;
    statuspanel: TPanel;
    KESZPANEL: TPanel;

    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure wparancs(_ukaz: string);
    procedure AdatkikeresBfBol;

    function Munkamenet: boolean;
    function adatokrendben: boolean;
    function Nulele(_int: integer): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _pcs,_hos,_farok,_bfnev,_wunev,_aktgdb,_wdatum,_wpros,_wid,_wsorszam: string;
  _bfid,_bfpros: string;

  _sorveg: string = chr(13)+chr(10);
  _cc,_tombdarab,_code,_akthonap,_penztar,_nevxx: integer;

  _tombnev,_tombid: array[0..500] of string;


  _kilep,_megvan: boolean;



implementation

{$R *.dfm}

procedure TForm1.Button2Click(Sender: TObject);
begin
  Application.Terminate;
end;

function TForm1.Nulele(_int: integer): string;

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;


procedure TForm1.wparancs(_ukaz: string);

begin
  wdbase.close;
  wdbase.connected := true;
  if wtranz.InTransaction then wtranz.commit;
  wtranz.StartTransaction;

  with wquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  wtranz.commit;
  wdbase.close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  pdbase.Connected := true;
  with pquery do
    begin
      close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      First;
    end;
  _cc := 0;

  while not pquery.eof do
    begin
      _tombnev[_cc] := trim(pquery.fieldByName('PENZTAROSNEV').asString);
      _tombid[_cc]  := pquery.fieldbyNAme('IDKOD').asString;
      inc(_cc);
      pquery.next;
    end;
  pquery.Close;
  pdbase.close;

  _tombdarab := _cc;

  // ---------------------------------------------------------------------------

 

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
   _hos := Hoedit.text;
  val(_hos,_akthonap,_Code);
  if _code<>0 then _akthonap := 6;
  _penztar := 1;






  while true do
    begin
      if munkamenet then exit;
    end;

  kESZPANEL.Visible := TRUE;
  KESZPANEL.REPAINT;
end;      


function Tform1.Munkamenet: boolean;

begin
  Result := False;

  _farok := '13' + nulele(_akthonap);
  _bfnev := 'BF'+_FAROK;
  _wunev := 'WUNI' + _farok;

  while _penztar<=150 do
    begin
      _aktgdb := 'c:\receptor\database\v'+inttostr(_penztar)+'.gdb';
      if not fileExists(_aktgdb) then
        begin
          inc(_penztar);
          continue;
        end;
      Penztarpanel.Caption := _aktgdb;
      Penztarpanel.repaint;

      BFDBASE.CLOSE;
      bfdbase.DatabaseName := _aktgdb;
      wdbase.DatabaseName := _aktgdb;

      bfdbase.Connected := true;
      bftabla.close;
      bftabla.TableName := _bfnev;
      if not bftabla.Exists then
        begin
          bfdbase.close;
          inc(_penztar);
          continue;
        end;

      wdbase.Connected := true;
      wtabla.close;
      wtabla.TableName := _wunev;
      if not wtabla.Exists then
        begin
          bfdbase.close;
          wdbase.close;
          inc(_penztar);
          continue;
        end;
      bfdbase.close;

      _pcs := 'SELECT * FROM '+ _WUNEV + _sorveg;
      _pcs := _pcs + 'WHERE (STORNO=1) AND (UGYFELTIPUS='+chr(39)+'U'+chr(39)+')';

      with wquery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Open;
          First;
        end;
      _kilep := false;
      while not wquery.Eof do
        begin
          with wquery do
            begin
              _wdatum := fieldbyname('DATUM').asString;
              _wpros  := TRIM(FieldByNAme('PENZTAROSNEV').asString);
              _wid    := trim(fieldByNAme('IDKOD').asString);
              _WSORSZAM := TRIM(Fieldbyname('SORSZAM').asstring);
            end;

          Datumpanel.Caption := _wdatum;
          datumpanel.Repaint;

          if not adatokrendben then
            begin
              AdatkikeresBfbol;
              _pcs := 'UPDATE ' + _wunev + ' SET IDKOD='+chr(39)+_bfid+chr(39)+',';
              _pcs := _pcs + 'PENZTAROSNEV='+chr(39)+_bfpros+chr(39)+_sorveg;
              _pcs := _pcs + 'WHERE SORSZAM='+chr(39)+_wsorszam+chr(39);

              wparancs(_pcs);

              _PCS := 'UPDATE '+_WUNEV + ' SET IDKOD='+chr(39)+_bfid+chr(39)+_SORVEG;
              _PCS := _PCS + 'WHERE PENZTAROSNEV='+chr(39)+_bfpros+chr(39);
              wparancs(_pcs);

              _kilep := true;

              statuspanel.Caption := 'MEGJAVITVA !';
              STATUSPANEL.Repaint;
              SLEEP(250);

              exit;
            end;
          wquery.next;
        end;
      wquery.close;
      wdbase.close;
      if _kilep then exit;

      STATUSPANEL.CAPTION := 'EZ RENDBEN VAN';
      STATUSPANEL.Repaint;
      SLEEP(250);

      inc(_penztar);
    end;
  result := true;
end;

function TForm1.adatokrendben: boolean;

var _y: integer;

begin
  // wpros,wid ellenörzése;

  result := false;

  if _wpros='' then exit;
  if _wid='' then exit;

  _megvan := False;
  for _y := 0 to _tombdarab-1 do
    begin
      if _tombnev[_y]=_wpros then
        begin
          _megvan := True;
          break;
        end;
    end;
  if not _megvan then exit;        



  _y := 0;

  _megvan := False;
  while _y<_tombdarab do
    begin
      if _tombnev[_y]= _wpros then
        begin
          _megvan := true;
          _nevxx := _y;
          break;
        end;
      inc(_y);
    end;
  if not _megvan then exit;

  if _wid<>_tombid[_nevxx] then exit;

  result := True;
end;


procedure TForm1.AdatkikeresBfBol;

begin
  bfdbase.connected := true;
  _pcs := 'SELECT * FROM ' + _BFNEV + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_wdatum+chr(39);

  with bfquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _bfpros := trim(bfquery.fieldbyname('PENZTAROSNEV').asString);
      _bfid := bfquery.FieldByNAme('IDKOD').asstring;
      close;
    end;
  bfdbase.close;
end;  


end.
