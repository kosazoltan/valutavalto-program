unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  DateUtils, ExtCtrls, IBTable, strutils;

type
  TForm1 = class(TForm)
    STARTGOMB: TButton;
    PQuery: TIBQuery;
    PDBASE: TIBDatabase;
    PTRANZ: TIBTransaction;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    KILEPOGOMB: TBitBtn;
    Label1: TLabel;
    ListBox: TListBox;
    Label2: TLabel;
    PENZTARPANEL: TPanel;
    VTABLA: TIBTable;

    procedure STARTGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KodtablaBeolvasas;

    function Nulele(_int: byte): string;
    function Ezertektar(_ptn: integer): boolean;
    function ProsCompare(_pid,_pnev: string): boolean;
    function GetCtrlNev(_ctid: string): string;
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _honev: array[1..12] of string = ('január','február','március','április',
                'május','június','július','augusztus','szeptember','október',
                                           'november','december');

  _QQ: integer;
  _ptnev,_ptid: array[0..800] of string;
  _penztarosdarab: integer;
  _pcs,_aktfdbPath,_bftabla,_wutabla,_farok,_hasnev: string;
  _aktev,_aktho,_kertev,_kertho: word;
  _sorveg: string = chr(13) + chr(10);

implementation

{$R *.dfm}

procedure TForm1.FormActivate(Sender: TObject);

var i: integer;

begin
  _aktev := yearof(date);
  _aktho := monthof(Date);

  evcombo.Items.clear;
  hocombo.Items.clear;

  evcombo.Items.Add(inttostr(_aktev-1));
  evcombo.Items.Add(inttostr(_aktev));

  for i := 1 to 12 do hocombo.Items.Add(_honev[i]);

  evcombo.ItemIndex := 1;
  hocombo.ItemIndex := _aktho-1;

  Activecontrol := StartGomb;
end;



procedure TForm1.STARTGOMBClick(Sender: TObject);

var _prosnev,_prosid,_sor: string;
    _azonos: boolean;

begin
  _kertev := (_aktev - 1) + evcombo.itemindex;
  _kertho := 1 + hocombo.itemindex;

  _farok := inttostr(_kertev-2000)+nulele(_kertho);
  _bftabla := 'BF' + _farok;
  _wuTabla := 'WUNI' + _farok;

  KodtablaBeolvasas;

  _qq := 1;
  while _qq<=150 do
    begin

      if ezErtektar(_qq) then
        begin
          inc(_qq);
          continue;
        end;

      _aktfdbPath := 'c:\receptor\database\v' + inttostr(_qq) + '.fdb';
      if not FileExists(_aktfdbPath) then
        begin
          inc(_qq);
          Continue;
        end;

      vtabla.close;
      vdbase.close;
      vdbase.DatabaseName := _aktfdbPath;
      vdbase.connected := true;
      vtabla.TableName := _bftabla;
      if not Vtabla.Exists then
        begin
          vdbase.close;
          inc(_qq);
          Continue;
        end;

      Penztarpanel.Caption := inttostr(_qq);
      PenztarPanel.Repaint;

      _pcs := 'SELECT * FROM ' + _bftabla + _sorveg;
      _pcs := _pcs + 'WHERE (STORNO=1) AND (TIPUS<>' + chr(39)+'F'+chr(39)+')';
      _pcs := _pcs + ' AND (TIPUS<>' + chr(39)+'U'+chr(39)+')';

      with vquery do
        begin
          CLose;
          sql.clear;
          sql.add(_pcs);
          Open;
          First;
        end;

      while not vQuery.eof do
        begin
          _prosnev := vquery.fieldByName('PENZTAROSNEV').asString;
          _prosid  := vquery.FieldByname('IDKOD').asString;

          _azonos := ProsCompare(_prosid,_prosnev);
          if not _azonos then
            begin
              _sor := inttostr(_qq)+': '+_hasnev+'-'+_prosid+'/BF' ;
              Listbox.Items.add(_sor);
            end;
          vquery.next;
        end;

      vquery.close;

      // -----------------------------------------------------------------------

      vtabla.TableName := _wutabla;
      if not Vtabla.Exists then
        begin
          vdbase.close;
          inc(_qq);
          Continue;
        end;

      _pcs := 'SELECT * FROM ' + _wutabla + _sorveg;
      _pcs := _pcs + 'WHERE (STORNO=1) AND (UGYFELTIPUS=' + chr(39)+'U'+chr(39)+')';

      with vquery do
        begin
          CLose;
          sql.clear;
          sql.add(_pcs);
          Open;
          First;
        end;

      while not vQuery.eof do
        begin
          _prosnev := vquery.fieldByName('PENZTAROSNEV').asString;
          _prosid  := vquery.FieldByname('IDKOD').asString;

          _azonos := ProsCompare(_prosid,_prosnev);
          if not _azonos then
            begin
              _sor := inttostr(_qq)+': '+_hasnev+'-'+_prosid + '/WU';
              Listbox.Items.add(_sor);
            end;
          vquery.next;
        end;

      vquery.close;
      vdbase.close;
      inc(_qq);
    end;
  Listbox.Items.add('--------------------');
  Listbox.Items.add('VIZSGÁLAT VÉGE');
end;

function TForm1.Ezertektar(_ptn: integer): boolean;

begin
  result := false;
  if (_ptn=10) or (_ptn=20) or (_ptn=40) or (_ptn=50) or (_ptn=63) then
    begin
      result := True;
      exit;
    end;

  if (_ptn=63) or (_ptn=75) or (_ptn=120) or (_ptn=145) then result := true;
end;



function TForm1.ProsCompare(_pid,_pnev: string): boolean;

var _wpn: byte;
    _ctrlnev: string;

begin
  result := false;
  if _pid='00000' then
    begin
      result := true;
      exit;
    end;

  _pnev := trim(_pnev);
  _wpn := length(_pnev);

  if _wpn>15 then _wpn:=15;

  _hasnev := leftstr(_pnev,_wpn);
  _ctrlNev := GetctrlNev(_pid);

  if leftstr(_ctrlnev,_wpn)=_hasnev then result := True;
end;

function TForm1.GetCtrlNev(_ctid: string): string;

var _y: integer;

begin
  _y := 0;
  result := '?';
  while _y<_penztarosdarab do
    begin
      if _ptid[_y]=_ctid then
        begin
          result := _ptnev[_y];
          exit;
        end;
      inc(_y);
    end;
end;









procedure TForm1.KodtablaBeolvasas;

var _pros,_idkod: string;

begin
  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  pdbase.Connected := true;
  with Pquery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _qq := 0;
  while not pQuery.Eof do
    begin
      _pros := Pquery.FieldByNAme('PENZTAROSNEV').asString;
      _idkod:= Pquery.FieldByName('IDKOD').asString;

      _ptnev[_qq] := _pros;
      _ptid[_qq] := _idkod;

      inc(_qq);
      Pquery.Next;
    end;
  pquery.close;
  pdbase.close;
  _penztarosdarab := _qq;
end;


function TForm1.Nulele(_int: byte): string;

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

procedure TForm1.KILEPOGOMBClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.EVCOMBOChange(Sender: TObject);
begin
  Activecontrol := startgomb;
end;

end.
