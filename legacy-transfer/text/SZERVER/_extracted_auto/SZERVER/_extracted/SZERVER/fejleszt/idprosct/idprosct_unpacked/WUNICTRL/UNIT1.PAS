unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, IBTable, StdCtrls,
  ExtCtrls,strutils;

type
  TForm1 = class(TForm)
    PTQUERY: TIBQuery;
    PTDBASE: TIBDatabase;
    pttranz: TIBTransaction;
    Button1: TButton;
    VTABLA: TIBTable;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    NEVPANEL: TPanel;
    IDPANEL: TPanel;
    PENZTARPANEL: TPanel;
    DATUMPANEL: TPanel;
    Label1: TLabel;
    kezdoedit: TEdit;
    Label2: TLabel;
    hoedit: TEdit;
    Label3: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Feldolgozas(_nv,_id: string);
    function Nulele(_int: byte): string;
    function Scanid(_i: string): integer;
    function ScanNev(_i: string): integer;
    function ezetar(_e: byte): boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _honap: integer;
  _pts,_hos: string;

  _xnev,_xid: array[0..999] of string;

  _ETAR: array[1..8] of integer = (10,20,40,50,63,75,120,145);

  _prosdarab,_code: integer;
  _pcs,_pnev,_pid,_farok,_bftablanev,_wutablanev,_gdbpath,_datum: string;
  _aktprosnev,_aktidkod: string;
  _sorveg: string = chr(13)+chr(10);
  _cc,_penztar,_xx,_yy: integer;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';
  PTDBASE.Connected := TRUE;
  with ptquery do
    begin
      Close;
      sql.clear;
      sql.add(_PCS);
      Open;
      First;
    end;

  _cc := 0;
  while not ptquery.Eof do
    begin
      _pnev := trim(ptquery.fieldByName('PENZTAROSNEV').asstring);
      _pid  := ptquery.fieldByname('IDKOD').asstring;
      _xNev[_cc] := _pnev;
      _xId[_cc] := _pid;
      inc(_cc);
      ptquery.next;
    end;
  ptquery.close;
  ptdbase.close;
  _prosdarab := _cc;
end;




procedure TForm1.Button1Click(Sender: TObject);
begin
  _HOS := TRIM(HOEDIT.Text);
  val(_hos,_honap,_code);
  if _code<>0 then _honap := 6;

  _farok := '13' + nulele(_honap);
  _bftablanev := 'BF' + _farok;
  _wuTablanev := 'WUNI' + _farok;


  _PTS := trim(kezdoedit.Text);
  val(_pts,_penztar,_code);
  if _code<>0 then _penztar := 3;

  while _penztar<=150 do
    begin
       if ezetar(_penztar) then
         begin
           inc(_penztar);
           continue;
         end;  

      _gdbpath := 'c:\receptor\database\v' + inttostr(_penztar)+'.gdb';
      if not FileExists(_gdbPath) then
        begin
          inc(_penztar);
          continue;
        end;

      vdbase.close;
      vtabla.close;

      vdbase.DatabaseName := _gdbpath;
      vtabla.TableName := _wutablanev;
      vdbase.connected := true;
      if not vtabla.Exists then
        begin
          vdbase.close;
          inc(_penztar);
          continue;
        end;
      _pcs := 'SELECT * FROM '+_wuTABLANEV + _sorveg;
      _pcs := _pcs + 'WHERE (STORNO=1) AND (UGYFELTIPUS='+chr(39)+'U'+chr(39)+')';
      
      with vQuery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Open;
          First;
        end;

      while not vquery.Eof do
        begin
          _datum := vquery.fieldbyname('DATUM').asString;
          _aktprosnev := trim(vquery.fieldbyname('PENZTAROSNEV').asString);
          _aktidkod   := vquery.fieldbyname('IDKOD').asString;

          Feldolgozas(_aktprosnev,_aktidkod);
          vquery.next;
        end;
      vquery.close;
      vdbase.close;

      inc(_penztar);
    end;
end;

procedure TForm1.Feldolgozas(_nv,_id: string);

begin
   PenztarPanel.Caption := inttostr(_penztar);
   DatumPanel.Caption := _datum;
   Nevpanel.caption := _nv;
   Idpanel.caption := _id;

   Penztarpanel.repaint;
   DatumPanel.Repaint;
   Nevpanel.Repaint;
   idpanel.Repaint;

   if _id='' then
     begin
       showmessage('HIÁNYZÓ IDKOD');
       EXIT;
     end;

   if _nv='' then
     begin
       Showmessage('HIÁNYZÓ NÉV');
       EXIT;
     END;

   _xx := scanid(_id);
   if _xx=-1 then
     begin
       showmessage('Érvénytelen id-kód:'+ _id);
       exit;
     end;

   _yy := scanNev(_nv);
   if _yy=-1 then
     begin
       ShowMessage('Érvénytelen pénztárosnév');
       exit;
     end;

   if _xID[_YY]<>_ID then
     begin
       ShowMessage('Nem megfelelő id-név páros:'+_nv );
       exit;
     end;
  // id és név rendben
end;

function TForm1.Nulele(_int: byte): string;

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

function TForm1.Scanid(_i: string): integer;

var _y: integer;

begin
  result := -1;
  _y := 0;
  while _y<_prosdarab do
    begin
      if _xid[_y]=_i then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

function TForm1.ScanNev(_i: string): integer;

var _y: integer;

begin
  result := -1;
  _y := 0;
  while _y<_prosdarab do
    begin
      if _xnev[_y]=_i then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

function TForm1.ezetar(_e: byte): boolean;

var i: integer;

begin
  result := True;
  for i := 1 to 6 do if _etar[i]=_e then exit;
  result := False;
end;

end.
