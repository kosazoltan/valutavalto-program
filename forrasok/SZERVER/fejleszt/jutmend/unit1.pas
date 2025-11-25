unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  DateUtils, IBTable, strutils, ExtCtrls;

type
  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    EVEDIT: TEdit;
    Label3: TLabel;
    HOEDIT: TEdit;
    HONAPOKEGOMB: TBitBtn;
    VQUERY: TIBQuery;
    PQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    PDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    PTRANZ: TIBTransaction;
    PTABLA: TIBTable;
    VTABLA: TIBTable;
    Shape1: TShape;
    MESSPANEL: TPanel;

    procedure EgyPenztarJavitasa;
    procedure BFAdatbazisJavitasa;
    procedure WuniAdatbazisJavitasa;

    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure EVEDITEnter(Sender: TObject);
    procedure EVEDITExit(Sender: TObject);
    procedure HONAPOKEGOMBClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);

    function Nulele(_b: byte): string;
    function Scanid(_sId: string): integer;
    function Marasorban(_IDX: word): boolean;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _pcs,_pnev,_idkod,_farok,_kevs,_khos,_bf,_wuni,_aktfdb,_prosnev: string;
  _goodpros,_goodid,_mess,_aktpros,_aktid,_hasnev: string;
  _sorveg: string = chr(13)+chr(10);
  _bHibass,_wHibass,_idxx,_aktidxx: word;
  _aktev,_aktho,_kertev,_kertho,_cc,_pt,_xx,_yy,_prosdarab: word;
  _hibass,_y,_z: word;
  _pros,_pid : array[1..1600] of string;
  _code,_hiba,_hibadb,_aktxx: integer;
  _Hibasor: array[1..3000] of word;

implementation

{$R *.dfm}



// =============================================================================
              procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  top := 100;
  Left := 420;

  Repaint;

  _pcs := 'SELECT * FROM PENZTAROSOK ORDER BY IDKOD';
  pdbase.connected := true;
  with Pquery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  _cc := 0;
  while not Pquery.Eof do
    begin
      _pnev := trim(Pquery.FieldByNAme('PENZTAROSNEV').asString);
      _idkod  := pquery.FieldByNAme('IDKOD').asString;
      inc(_cc);
      _pros[_cc] := _pnev;
      _pid[_cc]  := _idkod;

      Messpanel.Caption := _pnev+' - ' + _idkod;
      Messpanel.Repaint;

      Pquery.next;

    end;
  Pquery.close;
  Pdbase.close;

  _prosdarab := _cc;

  _aktev := yearof(Date);
  _aktho := monthof(Date);

  evedit.Text := inttostr(_aktev);
  hoedit.Text := inttostr(_aktho);

  MessPanel.Caption := '';

  Activecontrol := HonapOkeGomb;
end;

// =============================================================================
             procedure TForm1.HONAPOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _kevs := trim(evedit.Text);
  _khos := trim(hoedit.Text);

  val(_kevs,_kertev,_code);
  val(_khos,_kertho,_code);

  _kevs := midstr(_kevs,3,2);
  _farok := _kevs+nulele(_kertho);
  _bf := 'BF' + _farok;
  _wuni := 'WUNI' + _farok;

  _PT :=4;
  while _pt<=168 do
    begin
      _aktfdb := 'c:\receptor\database\v' +  inttostr(_pt)+'.FDB';
      if not FileExists(_aktfdb) then
        begin
          inc(_pt);
          Continue;
        end;

      vdbase.close;
      vdbase.DatabaseName := _aktfdb;
      vdbase.Connected := true;

      MessPanel.Caption := _aktfdb;

      MessPanel.Repaint;

      // ----------- PÉNZTÁR ADATBÁZISA BEKAPCSOLVA ----------------------------

      EgyPenztarJavitasa;


      inc(_pt);
    end;

  MessPanel.caption := 'A HIBÁKAT KIJAVITOTTAM';
  MessPanel.repaint;
end;

// =============================================================================
                  procedure TForm1.EgyPenztarJavitasa;
// =============================================================================


begin
  BFadatbazisJavitasa;
  WuniadatbazisJavitasa;
end;


// =============================================================================
                  procedure TForm1.BFadatbazisJavitasa;
// =============================================================================

begin
  vdbase.connected := true;
  vtabla.close;
  vtabla.tablename := _bf;
  if not vtabla.exists then
    begin
      Vdbase.close;
      exit;
    end;



  _pcs := 'SELECT * FROM ' + _BF + _sorveg;
  _pcs := _pcs + 'WHERE ((TIPUS=' + chr(39)+'V' + chr(39)+')';
  _pcs := _pcs + ' OR (TIPUS='+chr(39)+'E'+chr(39)+'))';
  _pcs := _pcs + ' AND (STORNO=1)';

  with VQuery do
    begin
      CLose;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _hibass := 0;
  while not vQuery.Eof do
    begin
      _prosnev := trim(VQuery.FieldByNAme('PENZTAROSNEV').asString);
      _idkod   := trim(Vquery.FieldByNAme('IDKOD').AsString);
      _idxx := ScanId(_idkod);

      if _idxx=0 then
        begin
          Halt;
          Application.Terminate;
          exit;
        end;
      _hasnev := _pros[_idxx];
      if _hasnev<>_prosnev then
        begin
          if not marasorban(_idxx) then
            begin
              inc(_hibass);
              _hibasor[_hibass] := _idxx;
            end;
        end;
      vquery.next;
    end;
  Vquery.close;
  Vdbase.close;

  if _hibass=0 then exit;

  _y := 1;
  while _y<=_hibass do
    begin
      _aktidxx := _hibasor[_y];
      _aktpros := _pros[_aktidxx];
      _aktid   := _pid[_aktidxx];
      MessPanel.caption := _aktpros;
      MessPanel.Repaint;
      _pcs := 'UPDATE ' + _bf + ' SET PENZTAROSNEV=' + chr(39)+_aktpros+chr(39)+_sorveg;
      _pcs := _pcs + 'WHERE IDKOD=' + chr(39)+_aktid+chr(39);
      ValutaParancs(_pcs);
      inc(_y);
    end;
end;

// =============================================================================
                 procedure TForm1.WuniadatbazisJavitasa;
// =============================================================================

begin
  vdbase.connected := true;
  vtabla.close;
  vtabla.tablename := _wuni;
  if not vtabla.exists then
    begin
      Vdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _wuni + _sorveg;
   _pcs := _pcs + 'WHERE (UGYFELTIPUS=' + CHR(39)+'U'+chr(39)+')';
  _pcs := _pcs + ' AND (STORNO=1)';

  with VQuery do
    begin
      CLose;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _hibass := 0;
  while not vQuery.Eof do
    begin
      _prosnev := trim(VQuery.FieldByNAme('PENZTAROSNEV').asString);
      _idkod   := trim(Vquery.FieldByNAme('IDKOD').AsString);
      _idxx := ScanId(_idkod);

      if _idxx=0 then
        begin
          Halt;
          Application.Terminate;
          exit;
        end;
      _hasnev := _pros[_idxx];
      if _hasnev<>_prosnev then
        begin
          if not marasorban(_idxx) then
            begin
              inc(_hibass);
              _hibasor[_hibass] := _idxx;
            end;

        end;
      vquery.next;
    end;
  Vquery.close;
  Vdbase.close;

  if _hibass=0 then exit;

  _y := 1;
  while _y<=_hibass do
    begin
      _aktidxx := _hibasor[_y];
      _aktpros := _pros[_aktidxx];
      _aktid   := _pid[_aktidxx];
      MessPanel.Caption := _aktpros;
      MessPanel.repaint;
      _pcs := 'UPDATE ' + _wuni + ' SET PENZTAROSNEV=' + chr(39)+_aktpros+chr(39)+_sorveg;
      _pcs := _pcs + 'WHERE IDKOD=' + chr(39)+_aktid+chr(39);
      ValutaParancs(_pcs);
      inc(_y);
    end;
end;


function TForm1.Marasorban(_IDX: word): boolean;

var _w: word;

begin
  result := False;
  if _hibass=0 then exit;

  _w  := 1;
  while _w<=_hibass do
    begin
      if _idx=_hibasor[_w] then
        begin
          result := True;
          exit;
        end;
      inc(_w);
    end;
end;




// =============================================================================
              function TForm1.Scanid(_sId: string): integer;
// =============================================================================

begin
  result := 0;
  _y := 1;
  while _y<=_prosdarab do
    begin
      if _pid[_y]=_sid then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
  Showmessage('HIBAS ID-KÓD: '+_SID);
end;

// =============================================================================
              procedure TForm1.EVEDITEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clyellow;
end;

// =============================================================================
             procedure TForm1.EVEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).color := clWhite;
end;


// =============================================================================
              procedure TForm1.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  vdbase.close;
  vdbase.connected := true;
  if vtranz.InTransaction then vtranz.Commit;
  Vtranz.StartTransaction;
  with vquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  vtranz.commit;
  vdbase.close;
end;

// =============================================================================
               function TForm1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' +result;
end;

// =============================================================================
              procedure TForm1.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;


end.
