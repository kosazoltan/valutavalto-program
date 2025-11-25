unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, Dateutils, unit1, strutils;

type
  TGetIdoszak = class(TForm)

    AlapPanel  : TPanel;
    IdszRendben: TBitBtn;
    IdszMegsem : TBitBtn;
    EvCombo    : TComboBox;
    HoCombo    : TComboBox;
    TolCombo   : TComboBox;
    IgCombo    : TComboBox;
    Label1     : TLabel;
    Label2     : TLabel;
    Label3     : TLabel;
    Shape1     : TShape;

    procedure IdszMegsemClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure IdszRendbenClick(Sender: TObject);
    procedure EvComboChange(Sender: TObject);
    procedure TolComboChange(Sender: TObject);
    procedure IgComboChange(Sender: TObject);
    function Nulele(_b: byte): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETIDOSZAK: TGETIDOSZAK;

  _top,_left,_aktev,_aktho,_havinapok,_currYear,_y: word;

implementation

{$R *.dfm}


// =============================================================================
               procedure TGetIdoszak.IdszMegsemClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
                procedure TGetIdoszak.FormActivate(Sender: TObject);
// =============================================================================

begin
  _top  := Form1.top;
  _left := Form1.left;

  Top   := _top + 110;
  Left  := _left + 230;

  Repaint;

   // --------------------------------------------

  _aktev := yearof(date);
  Evcombo.Items.clear;
  _currYear := 2018;

  while _currYear<=_aktev do
    begin
      Evcombo.Items.Add(inttostr(_curryear));
      inc(_curryear);
    end;
  Evcombo.ItemIndex := _curryear-_aktev;

  // --------------------------------------------

  _aktho := monthof(date);
  Hocombo.Items.Clear;
  _y := 1;
  while _y<=12 do
    begin
      Hocombo.Items.add(_honev[_y]);
      inc(_y);
    end;
  Hocombo.ItemIndex := _aktho-1;

  // --------------------------------------------

  _havinapok := daysinamonth(_aktev,_aktho);

  Tolcombo.clear;
  IgCombo.clear;
  _y := 1;
  while _y<=_havinapok do
    begin
      tolcombo.Items.Add(inttostr(_y));
      igcombo.Items.Add(inttostr(_y));
      inc(_y);
    end;
  Tolcombo.ItemIndex := 0;
  IgCombo.ItemIndex := _havinapok-1;


end;

// =============================================================================
            procedure TGetIdoszak.IdszRendbenClick(Sender: TObject);
// =============================================================================

begin
  _evindex := Evcombo.itemindex;
  _kertevs := Evcombo.items[_evindex];
  val(_kertevs,_kertev,_code);

  _hoindex := Hocombo.itemindex;
  _kertho := 1 + _hoindex;

  _tolindex := Tolcombo.itemindex;
  _igindex  := Igcombo.itemindex;

  _tolnap := 1+_tolindex;
  _ignaps := igcombo.items[_igindex];
  val(_ignaps,_ignap,_code);

  _KertDatums := inttostr(_kertev)+' '+_honev[_kertho]+' '+inttostr(_tolnap)+'-'+inttostr(_ignap);
  _toldatums := inttostr(_kertev)+'.'+nulele(_kertho)+'.'+nulele(_tolnap);
  _igDatums  := leftstr(_toldatums,8)+nulele(_ignap);
  Modalresult := 1;
end;


function TGetidoszak.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
               procedure TGetIdoszak.EvComboChange(Sender: TObject);
// =============================================================================

begin
  _evindex := Evcombo.itemindex;
  _kertevs := Evcombo.items[_evindex];
  val(_kertevs,_kertev,_code);

  _hoindex := Hocombo.itemindex;
  _kertho := 1 + _hoindex;

  _havinapok := daysinamonth(_kertev,_kertho);

  tolcombo.Items.Clear;
  igcombo.Items.Clear;

  _y := 1;
  while _y<=_havinapok do
    begin
      tolcombo.Items.Add(inttostr(_y));
      igcombo.Items.add(inttostr(_y));
      inc(_y);
    end;
  tolcombo.ItemIndex := 0;
  igcombo.ItemIndex := _havinapok-1;

  Activecontrol :=IdszRendben;
end;

// =============================================================================
              procedure TGetIdoszak.TolComboChange(Sender: TObject);
// =============================================================================

begin
  _tolindex := tolcombo.itemindex;
  _tolnap := 1+_tolindex;

  igcombo.Items.clear;

  _y := _tolnap;
  while _y<=_havinapok do
    begin
      igcombo.Items.Add(inttostr(_y));
      inc(_y);
    end;
  igcombo.ItemIndex := 0;
  Activecontrol := Idszrendben;
end;

// =============================================================================
              procedure TGetIdoszak.IgComboChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := Idszrendben;
end;

end.
