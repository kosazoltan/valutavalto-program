unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBQuery,
  IBCustomDataSet, IBTable;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Label1: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel4: TPanel;
    VTABLA: TIBTable;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    UTRANZ: TIBTransaction;
    UDBASE: TIBDatabase;
    UQUERY: TIBQuery;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure HaviCIklus;
    procedure KukacBeiras;

    function GetSorszam(_ns: string): integer;
    function ezertektar(_p: byte): boolean;
    function Nulele(_b: byte): string;
    function HutoGb(_kod: byte): byte;
    procedure FormActivate(Sender: TObject);

    
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _filter,_fdbpath,_farok,_bf,_bizonylat,_unev,_utip,_nevtabla,_biztabla: string;
  _cs,_kukac: string;
  _sorveg: string = chr(13)+chr(10);
  _pt,_ho,_asc: Byte;
  _recno,_sorszam: integer;


implementation

{$R *.dfm}


procedure TForm1.FormActivate(Sender: TObject);
begin
  _filter := '(TIPUS=' + chr(39)+'V'+chr(39)+')';
  _filter := _filter + ' AND (STORNO=1) AND (OSSZESEN>299999)';
  _filter := _filter + ' AND (PLOMBASZAM='+chr(39)+chr(39)+')';
end;



procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  aPPLICATION.Terminate;
end;

procedure TForm1.BitBtn1Click(Sender: TObject);
begin

  _pt := 1;
  while _pt<=150 do
    begin

      // Értéktár kiszürése:

      if ezertektar(_pt) then
        begin
          inc(_pt);
          continue;
        end;

      // Nem létezõ adatbázis kiszürése:

      _fdbPath := 'c:\receptor\database\v'+inttostr(_pt)+'.FDB';
      if not fileexists(_fdbPath) then
        begin
          inc(_pt);
          Continue;
        end;

      // V adatbázis megnyitása:

      vdbase.close;
      vdbase.databasename := _fdbPath;
      vdbase.connected := True;

      Panel1.Caption := _fdbPath;
      Panel1.repaint;

      if vtranz.intransaction then vtranz.commit;
      Vtranz.startTransaction;

      // Havi ciklus indul

      _ho :=1;
      while _ho<=12 do
        begin
          HaviCiklus;
          inc(_ho);
        end;

      Vtranz.commit;
      Vdbase.close;
      inc(_pt);
    end;
  ShowMessage('KÉSZEN VAGYOK');
end;


procedure TForm1.Haviciklus;

begin

  _farok := '18' + NULELE(_HO);
  _bf := 'BF' + _farok;

  // Havi tábla hiányának kiszürése:

  vtabla.close;
  vtabla.TableName := _bf;

  if not vtabla.exists then exit;

  // Vtabla nyitása, filter beállitása:

  with VTabla do
    begin
      Filtered := False;
      Open;
      TableName := _BF;
      Filter    := _filter;
      Filtered  := True;
      First;
      _recno    := Recno;
    end;

  // Üres vtábla kiszürése;

  if _recno=0 then
    begin
      Vtabla.close;
      exit;
    end;

  Panel2.Caption := _BF;
  Panel2.repaint;

  // Vtabla adat ciklusa:

  while not vtabla.eof do
    begin
      _bizonylat := VTabla.FieldByNAme('BIZONYLATSZAM').asString;
      _unev      := trim(VTabla.Fieldbyname('UGYFELNEV').asString);
      _utip      := VTabla.FieldByName('UGYFELTIPUS').asString;

      Panel4.Caption := _unev;
      Panel4.repaint;

      // Ha nincs nev ---> akkor a következõ

      if _Unev<>'' then
        begin
          _sorszam := GetSorszam(_unev);
          KukacBeiras;
        end;

      VTabla.Next;
    end;
  Vtabla.close;
end;

procedure TForm1.KukacBeiras;

begin
  _kukac := _nevtabla + inttostr(_sorszam);
  with VTabla do
    begin
      Edit;
      FieldByNAme('PLOMBASZAM').asString := _kukac;
      Post;
    end;
end;




function TForm1.GetSorszam(_ns: string): integer;

begin
  result := 0;

  // Meghatározza a nev- és biztáblát:

  _asc := ord(_ns[1]);
  if _asc>90 then _asc := Hutogb(_asc);

  if _utip='N' then
    begin
      _nevtabla := chr(_asc)+'NEV';
      _biztabla := chr(_asc)+'BIZ';
    end else
    begin
      _nevtabla := 'JOGI';
      _biztabla := 'JOGIBIZ';
    end;

  // ------------------------------------------------

   udbase.connected := true;

   _cs := 'SELECT * FROM ' + _biztabla + _sorveg;
   _cs := _cs + 'WHERE BIZONYLATSZAM='+chr(39)+_bizonylat+chr(39);

   with uquery do
     begin
       Close;
       Sql.clear;
       Sql.add(_cs);
       Open;
       _recno := recno;
     end;

   if _recno>0 then result := uquery.FieldByname('SORSZAM').asInteger;

   Uquery.close;
   Udbase.close;

end;




// =============================================================================
                   function TForm1.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;

function TForm1.ezertektar(_p: byte): boolean;

begin
  result := False;
  if (_p=10) or (_p=20) or (_p=40) or (_p=50) or (_p=63) or (_p=75) then result := True;
  if (_p=120) or (_p=145) then result := True;
end;


function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;



end.
