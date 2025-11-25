unit Unit5;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, ExtCtrls, unit1,StrUtils;

type
  TSZAMSUMMA = class(TForm)
    Panel1: TPanel;
    SZAMRACS: TStringGrid;
    BitBtn1: TBitBtn;
    STARTTIMER: TTimer;
    Label1: TLabel;

    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure STARTTIMERTimer(Sender: TObject);
    function ForintForm(_float:real):string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SZAMSUMMA: TSZAMSUMMA;
  _numdb: integer;
  _mt: string;
  _numnev: array[1..150] of string;
  _sumnum: array[1..150] of real;

implementation

{$R *.dfm}

procedure TSZAMSUMMA.BitBtn1Click(Sender: TObject);
begin
  ModalResult := 1;
end;


procedure TSZAMSUMMA.FormActivate(Sender: TObject);
begin
  Top := _top + 140;
  Left := _left + 420;

  StartTimer.Enabled := true;
end;



procedure TSZAMSUMMA.STARTTIMERTimer(Sender: TObject);
var i: integer;
    _aktmezo: string;
    _aktnum: real;
begin
  StartTimer.Enabled := false;
  _numdb := 0;
  for i := 1 to _mezodarab do
    begin
      _mt := _mezotipus[i];
      if _mt<>'SZÖVEG' then
        begin
          inc(_numdb);
          _numnev[_numdb] := _mezonev[i];
        end;
    end;

  if _numdb=0 then
    begin
      ShowMessage('NINCS EGYETLEN SZÁMADAT SEM A TÁBLÁBAN');
      ModalResult := 2;
      Exit;
    end;

  Szamracs.RowCount := _numDb+1;

  for i := 1 to _numdb do _sumnum[i] := 0;

  Form1.IBTABLA.First;

  while not Form1.IBTABLA.Eof do
    begin
      for i := 1 to _numdb do
        begin
          _aktmezo := _numnev[i];
          _aktnum := Form1.IBtabla.fieldBynAme(_aktMezo).asFloat;
          _sumnum[i] := _sumnum[i] + _aktnum;
        end;
      Form1.Ibtabla.Next;
    end;
  for i := 1 to _numdb do
    begin
      Szamracs.cells[0,i] := _numnev[i];
      Szamracs.Cells[1,i] := ForintForm(_sumnum[i]);
    end;

  Szamracs.Cells[0,0] := '     MEZÕ MEGNEVEZÉSE';
  Szamracs.cells[1,0] := '  ÖSSZEGEZÉS';
  Activecontrol := Szamracs;
end;

// ==========================================================
       function TSzamsumma.ForintForm(_float:real):string;
// ==========================================================

var _slen,_pp,_osszeg: integer;
    _ejel : string;

begin
  result := '                 -';
  _osszeg := trunc(_float);

  if _osszeg=0 then exit;

  _ejel := '';

  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;
  result := inttostr(_osszeg);

  if _osszeg<1000 then
    begin
      result := _ejel + result;
      while length(result)<18  do  result := ' ' + result;
      exit;
    end;

  _slen := length(result);
  if _osszeg>999999 then
    begin
      _pp := _slen-5;
      result := _ejel + midstr(result,1,_pp-1)+' '+midstr(result,_pp,3)+' '+midstr(result,_pp+3,3);
      while length(result)<18 do  result := ' '+result;
      exit;
    end;
  _pp := _slen-2;
  result := _ejel + midstr(result,1,_pp-1)+' '+midstr(result,_pp,3);
  while length(result)<18 do  result := ' '+result;

end;




end.
