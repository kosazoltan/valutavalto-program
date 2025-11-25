unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, UNIT1, strutils;

type

    TGetFuggveny = class(TForm)
    Panel1           : TPanel;

    FuggvenyShape    : TShape;
    ErtekShape       : TShape;
    MintaHatter      : TShape;

    Label1           : TLabel;
    Label2           : TLabel;
    MintaBetu        : TLabel;

    BetuszinGomb     : TBitBtn;
    HatterSzinGomb   : TBitBtn;
    MegsemGomb       : TBitBtn;
    RendbenGomb      : TBitBtn;
    ERTEKEDIT: TEdit;

    ColorDialog1     : TColorDialog;
    fuggvenyedit: TEdit;

    procedure FormActivate(Sender: TObject);
    procedure BetuszinGombClick(Sender: TObject);

    procedure ERTEKEDITEnter(Sender: TObject);
    procedure ERTEKEDITExit(Sender: TObject);
    procedure ERTEKEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  
    procedure FuggvenyEditEnter(Sender: TObject);
    procedure FuggvenyEditExit(Sender: TObject);
    procedure FuggvenyEditChange(Sender: TObject);
    procedure FuggvenyEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    
    procedure HatterSzinGombClick(Sender: TObject);
    procedure MegsemGombClick(Sender: TObject);
    procedure RendbenGombClick(Sender: TObject);

    function Besorol(_kod:integer):integer;
    function Fit(_e: integer; _a: integer):boolean;
    function FuggvenyCtrl(_exp: string): boolean;
    function JoBetu(_ab: integer):boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GetFuggveny: TGetFuggveny;

  _smFuggveny,
  _smErtek,
  _ujfuggvenystring: string;

  _ok,
  _ezracs: boolean;

  _akt,
  _aktB,
  _elozo,
  _explen,
  _fjel,
  _hbetu,
  _kjel,
  _pont,
  _qq,
  _zjel: integer;


implementation

{$R *.dfm}

// =============================================================================
              procedure TGetFuggveny.FormActivate(Sender: TObject);
// =============================================================================

begin
  if _getfy<8 then _getfy := 8;
  if _getfy>600 then _getfy := 600;
  if _getfx>736 then _getfx := 736;

  Top    := _top  + _getfy;
  Left   := _left + _getfx;

  Height := 104;
  Width  := 274;

  Mintahatter.Brush.Color := _akthatterszin;
  Mintabetu.Font.Color    := _aktbetuszin;
  
  FuggvenyEdit.text   := _aktfuggvenystring;
  ErtekEdit.Text      := _aktertekString;

  _smErtek            := _aktErtekstring;
  _smFuggveny         := trim(_aktFuggvenyString);
  
  if _smFuggveny='' then Activecontrol := Ertekedit
  else Activecontrol := FuggvenyEdit;


end;

// =============================================================================
            procedure TGetFuggveny.BetuSzinGombClick(Sender: TObject);
// =============================================================================

begin
  if colorDialog1.Execute then
    begin
      _aktbetuszin := ColorDialog1.Color;
      MintaBetu.Font.Color := _aktbetuszin;
    end;
end;


// =============================================================================
          procedure TGetFuggveny.HatterSzinGombClick(Sender: TObject);
// =============================================================================

begin
  if colorDialog1.Execute then
     begin
       _akthatterszin := ColorDialog1.Color;
       MintaHatter.Brush.Color := _akthatterszin;
     end;
end;

// $$$$$$$$$$$$$$$  ÉRTÉKPANEL $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



// =============================================================================
           procedure TGetFuggveny.ERTEKEDITEnter(Sender: TObject);
// =============================================================================

begin
  ErtekEdit.Color := $B0FFFF;
  ErtekShape.Brush.Color := $B0FFFF;
end;

// =============================================================================
             procedure TGetFuggveny.ERTEKEDITExit(Sender: TObject);
// =============================================================================

begin
  ErtekEdit.Color := clWhite;
  ErtekShape.Brush.Color := clWhite;
end;


// =============================================================================
   procedure TGETFUGGVENY.ERTEKEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  if Ertekedit.Text = '' then ActiveControl := MegsemGomb
  else ActiveControl := RendbenGomb;
end;


// $$$$$$$$$$$$$$$  FÜGGVÉNYPANEL $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


// =============================================================================
          procedure TGetFuggveny.FuggvenyEditChange(Sender: TObject);
// =============================================================================

var _flen: integer;
    _ujFuggvenyString: string;

begin
  _ujFuggvenyString := FuggvenyEdit.Text;
  _ok := FuggvenyCtrl(_ujFuggvenyString);

  if not _ok then
    begin
      _flen := length(_aktfuggvenystring);
      if _flen=1 then _ujFuggvenyString := ''
      else _ujFuggvenystring := leftstr(_ujFuggvenyString,_flen-1);
      FuggvenyEdit.Text := _ujFuggvenyString;
    end;
  Fuggvenyedit.Text := _ujFuggvenyString;
end;

// =============================================================================
       procedure TGetFuggveny.FuggvenyEditEnter(Sender: TObject);
// =============================================================================

begin
  Fuggvenyedit.Color := $B0FFFF;
  Fuggvenyshape.Brush.Color := $B0FFFF;
end;

// =============================================================================
           procedure TGetFuggveny.FuggvenyEditExit(Sender: TObject);
// =============================================================================

begin
  FuggvenyEdit.Color := clWhite;
  Fuggvenyshape.Brush.Color := clWhite;
end;

// =============================================================================
      procedure TGetFuggveny.FuggvenyEditKeyDown(Sender: TObject;
                                            var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _ujFuggvenyString := Form1.VesszobolPont(Fuggvenyedit.Text);
  if _ujFuggvenyString<>'' then
    begin
      _ok := FuggvenyCtrl(_ujFuggvenyString);
      if not _ok then
        begin
          FuggvenyEdit.Text := '';
          Exit;
        end;
     end;   
  Activecontrol := RendbenGomb;
end;


// =============================================================================
             procedure TGetFuggveny.RendbenGombClick(Sender: TObject);
// =============================================================================


begin
  _arfdatavaltozott := true;
  _aktFuggvenyString := Form1.VesszobolPont(fuggvenyedit.text);
  _aktertekString    := Form1.VesszobolPont(ErtekEdit.text);
  ModalResult    := 1;
end;

// =============================================================================
          procedure TGetFuggveny.MegsemGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
             function TGetFuggveny.FuggvenyCtrl(_exp: string): boolean;
// =============================================================================

var _ok: boolean;

begin
  result := False;
  if _exp='' then exit;

  _explen := length(_exp);
  _elozo  := 0;
  _qq     := 0;
  _zjel   := 0;
  _fjel   := 0;
  _pont   := 0;
  _kjel   := 0;

  while _qq<_explen do
    begin
      inc(_qq);
      _aktB := ord(_exp[_qq]);
      if _aktB=32 then continue;

      _akt := Besorol(_aktB);

      _ok := Fit(_elozo,_akt);
      if not _ok then exit;
      _elozo := _akt;
    end;
  Result := True;
end;

// =============================================================================
            function TGetFuggveny.Fit(_e: integer; _a: integer):boolean;
// =============================================================================


begin
  Result := false;
  case _elozo of
    0: begin

         if (_a=3) or (_a=6) or (_a=7) then exit;
         if (_a=5) then inc(_zjel);
         if (_a=4) then inc(_fjel);
         if (_a=8) then inc(_kjel);
         if (_a=1) and not Jobetu(_aktb) then exit;
       end;

    1: Begin
         if (_a=2) or (_a=4) or (_a=5) or (_a=7) or (_a=8) then exit;
         if (_a=6) and (_zjel=0) then exit;
         if (_a=6) then dec(_zjel);
         if (_a=1) and (_fjel=0) then exit;
         if (_a=6) then dec(_zjel);
       end;

     2: Begin
          if (_a=4) or (_a=5) or (_a=8) then exit;
          if (_a=7) and (_pont=1) then exit;
          if (_a=6) and (_zjel=0) then exit;
          if (_a=7) then _pont := 1;
          if (_a=6) then dec(_zjel);
          if (_a=1) and (_kjel=0) then exit;
        end;

     3: Begin
          if (_a=3) or (_a=6) or (_a=7) then exit;
          if (_a=1) and not Jobetu(_aktb) then exit;
          if (_a=5) and (_zjel>0) then exit;
          if (_a=4) and (_fjel=1) then exit;
          if (_a=4) then _fjel := 1;
          if (_a=5) then inc(_zjel);
          if (_a=8) then inc (_kjel);
        end;

     4: Begin
          if (_a>1) then exit;
          if not Jobetu(_aktb) then exit;
        end;

     5: begin
          if (_a=3) or (_a=5) or (_a=6) or (_a=7) then exit;
          if (_a=1) and not Jobetu(_aktb) then exit;
          if (_a=4) and (_fjel=1) then exit;
          if (_a=4) then _fjel := 1;
          if (_a=8) then inc(_kjel);
        end;

     6: begin
          if (_a<>3) then exit;
        end;

     7,8: begin
          if (_a<>2) then exit;
        end;
     end;
   Result := True;
end;

// =============================================================================
          function TGetFuggveny.JoBetu(_ab: integer):boolean;
// =============================================================================

begin
  result := False;
  if (_ab<65) or (_ab>81) then exit;
  if (_ab=68) or (_ab=75) then exit;
  result := true;
end;


// =============================================================================
                function TGetFuggveny.Besorol(_kod:integer):integer;
// =============================================================================


begin
  Result := 0;
  case _kod of
    65..90: result := 1;
    48..57: result := 2;
    44,46 : result := 7;
    42,43,45,47: result := 3;
        33: result := 4;
        40: result := 5;
        41: result := 6;
        35: result := 8;
   end;
end;


end.
