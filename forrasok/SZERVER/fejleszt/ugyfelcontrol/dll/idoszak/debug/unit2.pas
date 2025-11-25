unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, Dateutils, unit1, strutils,
  IBDatabase, DB, IBCustomDataSet, IBQuery;

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
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;

    procedure IdszMegsemClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure IdszRendbenClick(Sender: TObject);
    procedure EvComboChange(Sender: TObject);
    procedure TolComboChange(Sender: TObject);
    procedure IgComboChange(Sender: TObject);
    procedure Parancs(_ukaz: string);

    function Nulele(_b: byte): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Getidoszak: TGetidoszak;

  _height,_width,_top,_left: word;

  _honev: array[1..12] of string = ('január','február','március','április',
            'május','junius','július','augusztus','szeptember','október',
            'november','december');


  _aktev,_aktho,_havinapok,_currYear,_y,_kertho,_tolnap: word;
  _kertev,_ignap: word;
  _evindex,_hoindex,_tolindex,_igindex,_code: integer;
  _kertevs,_ignaps,_toldatums,_igdatums,_pcs: string;
  _sorveg: string = chr(13)+chr(10);


function idoszaksetting: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
              function idoszaksetting: integer; stdcall;
// =============================================================================

begin
  Getidoszak := TGetidoszak.Create(Nil);
  result := Getidoszak.ShowModal;
  Getidoszak.Free;
end;


// =============================================================================
               procedure TGetIdoszak.IdszMegsemClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

// =============================================================================
                procedure TGetIdoszak.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top  := round((_height-200)/2);
  _left := round((_width-420)/2);

  Top   := _top-200;
  Left  := _left;

  Repaint;

  _pcs := 'DELETE FROM IDOSZAK';
  Parancs(_pcs);

   // --------------------------------------------

  _aktev := yearof(date);
  Evcombo.Items.clear;
  _currYear := _AKTEV-2;

  while _currYear<=_aktev do
    begin
      Evcombo.Items.Add(inttostr(_curryear));
      inc(_curryear);
    end;
  Evcombo.ItemIndex := 2;

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

  _toldatums := inttostr(_kertev)+'.'+nulele(_kertho)+'.'+nulele(_tolnap);
  _igDatums  := leftstr(_toldatums,8)+nulele(_ignap);

  _pcs := 'INSERT INTO IDOSZAK (KERTEV,KERTHO,TOLNAP,IGNAP,TOLSTRING,IGSTRING)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_kertev) + ',';
  _pcs := _pcs + inttostr(_kertho) + ',';
  _pcs := _pcs + inttostr(_tolnap) + ',';
  _pcs := _pcs + inttostr(_ignap) + ',';

  _pcs := _pcs + chr(39) + _toldatums + chr(39) + ',';
  _pcs := _pcs + chr(39) + _igdatums + chr(39) + ')';
  Parancs(_pcs);

  Modalresult := 1;
end;

// =============================================================================
           procedure TGetidoszak.Parancs(_ukaz: string);
// =============================================================================

begin
  ibdbase.connected := true;
  if ibtranz.InTransaction then ibtranz.Commit;
  Ibtranz.StartTransaction;
  with ibquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ibtranz.commit;
  ibdbase.close;
end;


// =============================================================================
           function TGetidoszak.Nulele(_b: byte): string;
// =============================================================================

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
