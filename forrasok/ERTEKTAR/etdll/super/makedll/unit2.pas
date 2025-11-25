unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, dateUtils;

type
  Tform2 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    PASSWORDEDIT: TEdit;
    Label2: TLabel;
    REFERPANEL: TPanel;
    Label3: TLabel;
    Shape1: TShape;

    procedure FormActivate(Sender: TObject);
    procedure PASSWORDEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    function Melysor(_betu:char):byte;
    function Betuertek(_rnum: byte): integer;

    procedure Hibafutty;
  
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: Tform2;
  _joPassword: string;
  _billsor: array[1..3] of string;
  _top,_left,_width,_height,_maiNap,_pwTipus: integer;
  _maganhangzo: array[1..5] of integer = (65,69,73,79,85);

function supervisorjelszo(_para: integer): integer; stdcall;

implementation

{$R *.dfm}


function supervisorjelszo(_para: integer): integer; stdcall;

begin
  form2 := TForm2.create(nil);
  _pwTipus := _para;
  result := Form2.ShowModal;
  Form2.Free;
end;


// =============================================================================
              procedure Tform2.FormActivate(Sender: TObject);
// =============================================================================

var _1,_2,_3,_4,_p1,_p2,_snum: byte;
    _jpw,_hnap: integer;
    _a,_b,_c,_d: char;
    _referszo: string;

begin

  _Top := 0;
  _Left := 0;
  _width := Screen.Monitors[0].Width;
  _height  := Screen.Monitors[0].Height;

  if _width>1024 then _left := trunc((_width-1024)/2);
  if _height>768 then _top := trunc((_height-768)/2);

  Top := _top+290;
  Left := _left+290;

  _billsor[1] := 'QWERTZUIOP';
  _billsor[2] := 'ASDFGHJKL';
  _billsor[3] := 'YXCVBNM';

  PassWordedit.Clear;
  Randomize;
  _1 := random(25);
  _2 := random(25);
  _3 := random(25);
  _4 := random(25);

  _a := chr(65+_1);
  _b := chr(65+_2);
  _c := chr(65+_3);
  _d := chr(65+_4);

  _referSzo := _a+_b+_c+_d;
  referPanel.Caption := _referszo;

  _maiNap := dayof(date);
  _hNap := dayoftheweek(date);

  if _pwTipus=0 then
    begin
      // A  jó jelszó =
      // 10-szer az elsõ betü sora + harmadik betü sora  + nap
      // a fenti eredmény kétszer + 3
       _jpw := 10*melysor(_A)+melysor(_C)+_mainap;
       _jpw := trunc(2*_jpw);
       _jpw := _jpw + 3;
    end else
    begin
       _p1 := Betuertek(_2);
       _p2 := Betuertek(_3);
       _snum := trunc(10*_p1)+_p2;
       _jpw := _mainap + _hnap + trunc(2*_snum);
    end;

  _joPassword := inttostr(_jpw);
  ActiveControl := PassWordEdit;

end;

function TForm2.Betuertek(_rnum: byte): integer;

var i: integer;

begin
  result := 0;
  _rnum := _rnum + 65;
  for i:= 1 to 5 do
    begin
      if _maganhangzo[i] = _rnum then exit;
    end;
  inc(result);
  if _rnum>75 then inc(result);
end;


// =============================================================================
      procedure Tform2.PASSWORDEDITKeyDown(Sender: TObject; var Key: Word;
                                               Shift: TShiftState);
// =============================================================================

var _bepass: string;
begin
   if ord(key)=27 then
     begin
       Modalresult := 2;
       Exit;
     end;

   if ord(Key)<>13 then exit;
   _bepass := PassWordedit.Text;
   if (_bePass=_joPassword) or (_bePass='949') then
     begin
       ShowMessage('JELSZÓ RENDBEN !');
       ModalResult := 1;
     end else
     begin
       HibaFutty;
       ShowMessage('ÉRVÉNYTELEN JELSZÓ');
       ModalResult := 2;
     end;
end;

// =============================================================================
                  function Tform2.Melysor(_betu:char):byte;
// =============================================================================

var _qq: byte;
    _aktbillsor: pchar;
begin
  result := 0;
  _qq := 1;

  while _qq<4 do
    begin

      _aktbillsor := pchar(_billsor[_qq]);

      if StrScan(_aktbillsor,_betu)<>nil then
        begin
          result := _qq;
          exit;
        end;
      inc(_qq);
    end;
end;



// =============================================================================
                          procedure TFORM2.Hibafutty;
// =============================================================================

begin

  windows.Beep(2100,100);
  windows.Beep(1300,80);
  windows.Beep(2100,100);

end;

end.
