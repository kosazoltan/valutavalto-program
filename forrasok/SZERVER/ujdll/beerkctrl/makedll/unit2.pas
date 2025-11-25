unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable,
  ExtCtrls, DateUtils, Strutils, Buttons;

type
  TForm2 = class(TForm)
    ATABLA: TIBTable;
    AQUERY: TIBQuery;
    ADBASE: TIBDatabase;
    ATRANZ: TIBTransaction;
    MISSPANEL: TPanel;
    KILEPO: TTimer;
    Label1: TLabel;
    Label2: TLabel;
    MISSDBPANEL: TPanel;
    NAPPANEL: TPanel;
    MISSLIST: TListBox;
    TOVABBGOMB: TBitBtn;
    Label3: TLabel;
    Label4: TLabel;
    Shape1: TShape;

    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure SearchMiss;
    procedure KilepoTimer(Sender: TObject);
    procedure PenztarnevBeolvasas;

    function Date2str(_dd: Tdatetime): string;
    function Nulele(_b: byte): string;
    procedure TOVABBGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _penztarnev: array[1..170] of string;

  _tegnap: TDatetime;
  _fdbPath,_tegnaps,_farok,_daybook,_napmezo,_pcs,_status,_uznev: string;
  _miss,_penztar,_uzlet,_y: byte;
  _mResult: integer;
  _tnap,_ev,_ho,_nap: word;
  _misspt: array[1..120] of byte;


function tegnapcontrol: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
              function tegnapcontrol: integer; stdcall;
// =============================================================================

begin
  form2  := TForm2.Create(Nil);
  result := Form2.showmodal;
  Form2.free;
end;

// =============================================================================
              procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := 400;
  Left := 500;
  Repaint;

  MissPanel.Visible := False;

  PenztarnevBeolvasas;
  SearchMiss;

  if _miss=0 then
    begin
      _mResult := -1;
      Kilepo.enabled := true;
      exit;
    end;
end;

// =============================================================================
                         procedure TForm2.SearchMiss;
// =============================================================================

begin
  _tegnap  := yesterday;
  _tegnaps := Date2str(_tegnap);
  _tnap    := dayof(_tegnap);

  _farok   := midstr(_tegnaps,3,2)+midstr(_tegnaps,6,2);
  _daybook := 'DAYB'+_farok;
  _napmezo := 'N'+ inttostr(_tNap);

  _fdbPath := 'C:\receptor\database\daybook.fdb';
  with adbase do
    begin
      Close;
      DatabaseName := _fdbpath;
      Connected := true;
    end;

  _pcs := 'SELECT * FROM ' + _daybook + ' ORDER BY PENZTAR';

  with aQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not aquery.Eof do
    begin
      _penztar:= aQuery.FieldByNAme('PENZTAR').asInteger;
      _status := trim(aQuery.FieldByNAme(_napmezo).asString);
      if _status='' then
        begin
          inc(_miss);
          _misspt[_miss] := _penztar;
        end;
      aquery.next;
    end;
  aQuery.close;

  // ------------------------------------------------------

  _fdbPath := 'C:\cartcash\database\daybook.fdb';
  with adbase do
    begin
      Close;
      DatabaseName := _fdbpath;
      Connected := true;
    end;

  _pcs := 'SELECT * FROM ' + _daybook + ' ORDER BY PENZTAR';

  with aQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not aquery.Eof do
    begin
      _penztar:= aQuery.FieldByNAme('PENZTAR').asInteger;
      _status := trim(aQuery.FieldByNAme(_napmezo).asString);
      if _status='' then
        begin
          inc(_miss);
          _misspt[_miss] := _penztar;
        end;
      aquery.next;
    end;
  aQuery.close;
  adbase.close;

  if _miss=0 then
    begin
      _mResult := -1;
      exit;
    end;

  MissList.Clear;
  Misslist.Items.clear;
  _y := 1;
  while _y<=_miss do
    begin
      _penztar := _misspt[_y];
      _uznev := _penztarnev[_penztar];
      MissList.Items.add(_uznev);
      inc(_y);
    end;

  MissdbPanel.caption := inttostr(_miss);
  Nappanel.caption := _tegnaps;

  with MissPanel do
    begin
      top := 0;
      left := 0;
      Visible := True;
      repaint;
    end;

  Misslist.ItemIndex := 0;  
  ActiveControl := Misslist;
  _mResult := _miss;

end;

// =============================================================================
               function TForm2.Date2str(_dd: Tdatetime): string;
// =============================================================================

begin
  _ev := yearof(_dd);
  _ho := monthof(_dd);
  _nap:= dayof(_dd);
  result := inttostr(_ev)+'.'+nulele(_ho)+'.'+nulele(_nap);
end;

// =============================================================================
                procedure TForm2.Button1Click(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
                   procedure TForm2.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

// =============================================================================
                 function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
                procedure TForm2.PenztarnevBeolvasas;
// =============================================================================

begin
  _fdbPath := 'C:\receptor\database\receptor.fdb';
  with adbase do
    begin
      Close;
      DatabaseName := _fdbpath;
      Connected := true;
    end;

  _pcs := 'SELECT * FROM IRODAK ORDER BY UZLET';
  with aQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not aquery.Eof do
    begin
      _uzlet := aQuery.FieldByNAme('UZLET').asInteger;
      _uznev := trim(aQuery.FieldByNAme('KESZLETNEV').asString);
      _penztarnev[_uzlet] := _uznev;
      aQuery.next;
    end;

  //  -------  ZÁLOG ----------------

  _fdbPath := 'C:\cartcash\database\artcash.fdb';
  with adbase do
    begin
      Close;
      DatabaseName := _fdbpath;
      Connected := true;
    end;

  _pcs := 'SELECT * FROM IRODAK ORDER BY UZLET';
  with aQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  while not aquery.Eof do
    begin
      _uzlet := aQuery.FieldByNAme('UZLET').asInteger;
      _uznev := trim(aQuery.FieldByNAme('KESZLETNEV').asString);
      _penztarnev[_uzlet] := _uznev;
      aQuery.next;
    end;
  aQuery.close;
  aDbase.close;
end;
procedure TForm2.TOVABBGOMBClick(Sender: TObject);
begin
  Modalresult := _mResult;
end;

end.
