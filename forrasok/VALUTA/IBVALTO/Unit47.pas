unit Unit47;

interface

uses
  Buttons, Classes, Controls, Dialogs, ExtCtrls, Forms, Graphics, Jpeg,
  Messages, SysUtils, StdCtrls, Unit1, Variants, Windows;

type

  TFomenuForm = class(TForm)

    BalrolJobbraGomb: TPanel;
    JobbrolBalraGomb: TPanel;
    MenuTakaro      : TPanel;
    MenuBar1        : TPanel;
    MenuBar2        : TPanel;
    MenuBar3        : TPanel;
    MenuBar4        : TPanel;
    MenuBar5        : TPanel;
    MenuBar6        : TPanel;
    MenuBar7        : TPanel;
    MenuBar8        : TPanel;
    MenuBar9        : TPanel;
    Panel3          : TPanel;

    Label1          : TLabel;

    procedure BalrolJobbra(sender: TObject);
    procedure EscapeGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure JobbrolBalra(sender: TObject);
    procedure MenuBar1Click(Sender: TObject);
    procedure MenuBar1Enter(Sender: TObject);
    procedure MenuBar1Exit(Sender: TObject);
    procedure MenutValasztott(_ss: byte);
    procedure SetMenuNevek;

  private

    { Private declarations }
  public
    { Public declarations }
  end;

var
  FomenuForm: TFomenuForm;

  _menubar: array[1..9] of TPanel;

  _aktmenupont,_fomenuoldal: byte;
  _wait: byte = 10;

implementation

{$R *.dfm}

// =============================================================================
           procedure TFomenuForm.MenuBar1Click(Sender: TObject);
// =============================================================================

begin
  _aktmenupont := TPanel(sender).tag;
  MenutValasztott(_aktmenupont);
end;

// =============================================================================
           procedure TFomenuForm.Menubar1Enter(Sender: TObject);
// =============================================================================

begin
  Tpanel(sender).Color := $B0FFFF;
  _aktmenuPont := TPanel(Sender).Tag;
  with TPanel(Sender).Font do
    begin
      Color:= clBlack;
      Size := 16;
    end;
end;

// =============================================================================
             procedure TFomenuForm.Menubar1Exit(Sender: TObject);
// =============================================================================

begin
   Tpanel(sender).Color := clwhite;
   with TPanel(Sender).Font do
    begin
      Color := clBlack;
      Size  := 14;
    end;
end;


// =============================================================================
              procedure TFomenuForm.FormActivate(Sender: TObject);
// =============================================================================

begin

  Top    := _top+ 8;
  Left   := _left + 345;
  Height := 335;
  Width  := 662;

  _fomenuoldal := 1;

  MenuTakaro.Visible := False;
  Form1.repaint;
  MenuTakaro.Caption := _cegnev;

  _aktmenupont := _fomenupont;

   Keypreview := True;

  _menubar[1] := menubar1;
  _menubar[2] := menubar2;
  _menubar[3] := menubar3;
  _menubar[4] := menubar4;
  _menubar[5] := menubar5;
  _menubar[6] := menubar6;
  _menubar[7] := menubar7;
  _menubar[8] := menubar8;
  _menubar[9] := menubar9;

  SetmenuNevek;
end;

// =============================================================================
                   procedure TFomenuform.SetmenuNevek;
// =============================================================================

var _mb: integer;
begin

  _mb := _fomenuPont;
  if _mb>8 then _mb := _mb-9;
  if _mb=0 then inc(_mb);

  if _fomenuoldal=1 then
    begin
      menubar1.caption := 'VALUTA VÉTEL';
      menubar2.caption := 'VALUTA ELADÁS';
      menubar3.caption := 'VALUTA KONVERZIÓ';
      menubar4.caption := 'PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL';
      menubar5.caption := '';
      menubar5.enabled := false;
      menubar6.caption := 'MAI BIZONYLAT SZTORNÓJA';
      menubar7.caption := 'ÁRFOLYAM BEÁLLITÁSOK';
      menubar8.caption := 'A PILLANATNYI PÉNZTÁR ÁLLÁSA';
      menubar9.caption := 'VALUTA FORGALOM ÖSSZESITÕJE';
    end else

    begin
      menubar1.caption := 'A NAPI- ÉS HAVIZÁRÁS VÉGREHAJTÁSA, CIMLETEZÉS';
      menubar2.caption := 'BIZONYLATOK MEGTEKINTÉSE A KÉPERNYÕN';
      menubar3.caption := 'TÁRSPÉNZTÁRAK KARBANTARTÁSA';
      menubar4.caption := 'KÜLÖNFÉLE LISTÁK NYOMTATÁSA';
      menubar5.caption := 'PÉNZTÁROSOK, JELSZAVAK KARBANTARTÁSA';
      menubar5.enabled := True;
      menubar6.caption := 'NAPI FORGALOM KIMUTATÁSA';
      menubar7.caption := 'RÉGEBBI NAP ZÁRÁS ÚJRANYOMTATÁSA';
      menubar8.caption := 'A PILLANATNYI ÁLLÁS REGENERÁLÁSA';
      menubar9.caption := 'EGYÉB BEÁLLITÁSOK ÉS PROGRAMOK';
    end;

  if (_mb=5) and (_fomenuoldal=1) then _mb := 4;

  _aktmenupont := _mb;
  ActiveControl := _Menubar[_mb];
end;

// =============================================================================
       procedure TFomenuForm.FormKeyDown(Sender: TObject; var Key: Word;
                                                 Shift: TShiftState);
// =============================================================================

begin
  _bill := ord(key);

  if _bill=13 then
    begin
      _fomenupont := _aktmenupont;
      Menutvalasztott(_fomenupont);
    end;
end;

// =============================================================================
           procedure TFomenuForm.EscapeGombClick(Sender: TObject);
// =============================================================================

begin
  Close;
end;

// =============================================================================
                 procedure TFomenuForm.FormCreate(Sender: TObject);
// =============================================================================

begin
   Top := _top+8;
  Left := _left+345;
end;

// =============================================================================
            procedure TFomenuform.BalrolJobbra(sender: TObject);
// =============================================================================

var _mtl: integer;

begin
  _mtl := -720;

  MenuTakaro.Left := -720;
  MenuTakaro.Visible := True;

  while _mtl<0 do
    begin
       _mtl := _mtl + 30;
      Menutakaro.Left := _mtl;
      MenuTakaro.Repaint;
      sleep(_wait);
    end;

  if _fomenuoldal=1 then _fomenuoldal :=2 else _fomenuoldal := 1;

  Setmenunevek;

  while _mtl<720 do
    begin
      _mtl := _mtl + 30;
      MenuTakaro.Left  := _mtl;
      MenuTakaro.Repaint;
      sleep(_wait);
    end;
  Menutakaro.Visible := false;
end;

// =============================================================================
              procedure TFomenuform.JobbrolBalra(sender: TObject);
// =============================================================================

var _mtl: integer;

begin

  _mtl := 720;

  MenuTakaro.Left := 720;
  MenuTakaro.Visible := True;

  while _mtl>0 do
    begin
      _mtl := _mtl -30;
      MenuTakaro.Left := _mtl;
      MenuTakaro.Repaint;
      sleep(_wait);
    end;

  if _fomenuoldal=1 then _fomenuoldal :=2 else _fomenuoldal := 1;

  Setmenunevek;

  while _mtl>-720 do
    begin
      _mtl := _mtl - 30;
      MenuTakaro.Left := _mtl;
      MenuTakaro.Repaint;
      sleep(_wait);
    end;
  Menutakaro.Visible := false;
end;

// =============================================================================
              procedure TFomenuForm.MenutValasztott(_ss: byte);
// =============================================================================

begin
  _fomenupont := _ss;
  if _fomenuOldal=2 then _fomenupont := _ss+9;
  Close;
  Form1.MenuInditoTimer.Enabled := true;
end;

// =============================================================================
     procedure TFomenuForm.FormKeyUp(Sender: TObject; var Key: Word;
                                                       Shift: TShiftState);
// =============================================================================

begin
  _bill := ord(Key);
  if _bill=37 then
    begin
      JobbrolBalra(Nil);
      exit;
    end;

  if _bill=39 then
    begin
      BalrolJobbra(Nil);
      exit;
    end;

  if _bill=27 then close;

end;
end.
