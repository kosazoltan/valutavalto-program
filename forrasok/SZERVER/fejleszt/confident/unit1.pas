unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Strutils, ExtCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    BEJELENTESLISTA: TListBox;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    DISPABLAK: TListBox;
    Label1: TLabel;
    Label2: TLabel;

    procedure ConfiKezeles;
    procedure BejelentesListaDblClick(Sender: TObject);
    procedure UzenetKijelzese;

    function Confikereso: integer;
    function BejelentesDekodolo(_kodstr: string): String;

    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);

    function Datumdekod(_kodstr: string): string;
    function Nulele(_b: byte): string;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _confi: array[0..100] of string;
  _decod: array[1..50] of string;
  _olvas: file of byte;
  _bytetomb: array[1..4096] of  byte;

  _betu: byte;
  _filelen,_confidb,_y,_textlen,_ss,_sdb,_pp,_e,_h,_n: word;
  _confifile,_confiPath,_text,_bPara,_dekstr,_datums,_para: string;
  _listindex: integer;
  _kellszokoz: boolean;

  _sordb,_sor,_sorlen: byte;
  _bb: word;


implementation

{$R *.dfm}


procedure TForm1.FormActivate(Sender: TObject);
begin
  ConfiKezeles;
end;

// =============================================================================
                      procedure TForm1.ConfiKezeles;
// =============================================================================

begin
  BejelentesLista.Items.clear;
  BejelentesLista.clear;

  DispAblak.Items.clear;
  DispAblak.Clear;

  _confidb := Confikereso;
  if _confidb=0 then
    begin
      Showmessage('NINCS OLVASATLAN BIZALMAS BEJELENTÉS');
      exit;
    end;

  _y := 0;
  while _y<_confidb do
    begin
      _confifile := _confi[_y]; //  CONF TRL A . COF
      _datums    := Datumdekod(midstr(_confifile,5,3));
      _para := _confifile + '-' + _datums;
      BejelentesLista.items.add(_para);
      inc(_y);
    end;

  BejelentesLista.ItemIndex := 0;
  BejelentesLista.SetFocus;

end;

// =============================================================================
                 function TForm1.Confikereso: integer;
// =============================================================================

var _q: integer;
    _srec: Tsearchrec;
    _minta: string;

begin
  _q := 0;
  _minta := 'c:\receptor\mail\conf\conf*.cXf';
   if FindFirst(_minta, faAnyfile,_srec) = 0 then
    begin
      repeat
        _confi[_q] := _srec.Name;
        inc(_q);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
  result := _q;
end;


procedure TForm1.BEJELENTESLISTADblClick(Sender: TObject);
begin
  UzenetKijelzese;
end;

procedure TForm1.UzenetKijelzese;

begin

  _listIndex := BejelentesLista.itemindex;
  _confifile := _confi[_listindex];
  _confiPath := 'c:\receptor\mail\CONF\'+_confifile;



  _y := 1;
  while _y<=50 do
    begin
      _decod[_y] := '';
      inc(_y);
    end;

  DispAblak.Items.clear;
  DispAblak.clear;

  assignFile(_olvas,_confiPath);
  reset(_olvas);

  _filelen := filesize(_olvas);
  blockread(_olvas,_bytetomb,_filelen);

  CloseFile(_olvas);
  _bpara := '';

  _y := 1;
  while _y<=_filelen do
    begin
      _bpara := _bpara + chr(_bytetomb[_y]);
      inc(_y);
    end;

  _text := Bejelentesdekodolo(_bpara);
  _textLen := length(_text);

  _y   := 1;
  _ss  := 1;
  _sdb := 1;
  _pp  := 0;

  _kellszokoz := False;
  while _y<=_textlen do
    begin
      _betu := ord(_text[_y]);
      inc(_pp);
      if _pp>60 then
        begin
          _kellszokoz := true;
          _pp := 0;
        end;

      if (_kellSzokoz) and (_betu=32) then
        begin
          _kellszokoz := False;
          inc(_sdb);
          _pp := 1;
        end;

      _decod[_sdb] := _decod[_sdb] + chr(_betu);
      inc(_y);
    end;

  _y := 1;
  while _y<=_sdb do
    begin
      dispAblak.Items.Add(_decod[_y]);
      inc(_y);
    end;

  DispAblak.ItemIndex := 0;
  DispAblak.setfocus;
end;

function TForm1.BejelentesDekodolo(_kodstr: string): String;

begin
  _Dekstr := '';
  if _kodstr='' then exit;

  _sordb := 255 - ord(_kodstr[1]);
  _pp := 8;
  _sor := 1;
  while _sor<=_sordb do
    begin
      _sorlen := ord(_kodstr[_pp]);
      _bb := 1;
      inc(_pp);
      while _bb<=_SORLEN do
        begin
          _betu := 255-ord(_kodstr[_pp]);
          _dekstr := _DEKSTR + chr(_betu);
          inc(_pp);
          inc(_bb);
        end;
      inc(_sor);
    end;
  RESULT := _dekstr;

end;


function Tform1.datumdekod(_kodstr: string): string;

begin
  _n := ord(_kodstr[1])-48;
  if _n>9 then _n := _n-7;

  _e := 2000 + (ord(_kodstr[2])-64);
  _h := ord(_kodstr[3])-64;
  _h := trunc(_h/2);

  result := inttostr(_e)+'.'+nulele(_h)+'.'+nulele(_n);
end;


function TForm1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;  

procedure TForm1.BitBtn4Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  UzenetKijelzese;
end;

end.
