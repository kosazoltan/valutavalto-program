unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, unit1, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TUjKonverzio = class(TForm)

    AlapPanel         : TPanel;
    EladasInfoPanel   : TPanel;
    EladasFtPanel     : TPanel;
    FizetendoPanel    : TPanel;
    MeghiusultPanel   : TPanel;
    VasarFTPanel      : TPanel;
    VasarInfoPanel    : TPanel;
    VasarOkePanel     : TPanel;
    VisszajaroFTPanel : TPanel;
    VisszajaroPanel   : TPanel;

    Shape1            : TShape;

    Label1            : TLabel;
    Label2            : TLabel;
    Label3            : TLabel;

    EladasGomb        : TBitBtn;
    ReturnGomb        : TBitBtn;
    VasarGomb         : TBitBtn;

    ValutaQuery       : TIBQuery;
    ValutaDbase       : TIBDatabase;
    ValutaTranz       : TIBTransaction;

    procedure EladasGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure ReturnGombClick(Sender: TObject);
    procedure VasarGombClick(Sender: TObject);

    function GetFizetendo: integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  UjKonverzio: TUJKonverzio;

  _vok       : integer;
  _uzenet    : string;


function eladasrutin: integer; stdcall; external 'c:\valuta\bin\eladas.dll' name 'eladasrutin';
function vasarlasrutin: integer; stdcall; external 'c:\valuta\bin\vasarlas.dll' name 'vasarlasrutin';

implementation


{$R *.dfm}

// =============================================================================
             procedure TUjkonverzio.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := _top  + 270;
  Left := _left + 275;

  _konvertin := 0;
  _konvertout:= 0;

 

  if not _ezkonverzio then
    begin
      EladasFtPanel.Visible     := False;
      Eladasgomb.Visible        := False;
      EladasInfoPanel.Visible   := False;
      MegHiusultPanel.Visible   := False;
      VasarFtPanel.Visible      := False;
      VasarInfoPanel.Visible    := False;
      VasarOkepanel.Visible     := False;
      VisszajaroFtPanel.Visible := False;
      VisszajaroPanel.visible   := False;

      AlapPanel.Repaint;

      _ezKonverzio               := True;
      Vasargomb.Enabled          := true;
      Activecontrol              := Vasargomb;
    end;

end;

// =============================================================================
           procedure TUJKonverzio.ReturnGombClick(Sender: TObject);
// =============================================================================

begin
  _ezkonverzio := False;
  Modalresult  := 1;
end;

// =============================================================================
             procedure TUJKonverzio.VasarGombClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('Konverziós tranzakcióba kezd'));

  Vasargomb.Enabled := false;
  Form1.Vtempelokeszites(1);
  _vok := vasarlasrutin;

  Alappanel.Repaint;

  if _vok<>1 then
    begin
      _ezkonverzio := False;
      VasarokePanel.Caption := 'CANCEL';
      VasarOkePanel.Visible := True;
      VasarOkePanel.Repaint;
      sleep(2800);
      logirorutin(pchar('Sikertelen konverziós vásárlás'));
      Modalresult := 2;
      exit;
    end;


  _konvertin := GetFizetendo;

  VasarokePanel.Caption := 'RENDBEN';
  VasarOkePanel.Visible := True;
  VasarOkePanel.Repaint;

  VasarinfoPanel.visible := True;
  VasarFtPanel.caption := Form1.forintform(_konvertin)+' Ft';
  VasarFtPanel.visible := True;
  VasarftPanel.repaint;

  logirorutin(pchar('A vásárolt valuta értéke: '+ inttostr(_konvertin)));

  ReturnGomb.Enabled := False;
  Eladasgomb.Visible := true;
  Eladasgomb.Enabled := True;
end;

// =============================================================================
          procedure TUJKonverzio.EladasGombClick(Sender: TObject);
// =============================================================================

var _eok: integer;

begin
  eladasgomb.Enabled := False;
  Returngomb.Enabled := true;
  _eok := eladasrutin;
  if _eok<>1 then
    begin
      logirorutin(pchar('Sikertelen konverziós eladás'));
      fizetendoPanel.Caption := Form1.ForintForm(_konvertin)+' forintot';
      _ezkonverzio := False;
      with meghiusultPanel do
        begin
          Top := 96;
          Left := 24;
          Visible := True;
          repaint;
        end;
      exit;
    end;

 _konvertout := Getfizetendo;

  _egyenleg := _konvertin - _konvertout;
  _uzenet := 'A vevõnek visszajár';

  if _egyenleg<0 then _uzenet := 'A vevõnek fizetni kell';
  VisszaJaroPanel.Caption     := _uzenet;
  EladasftPanel.Caption       := form1.ForintForm(_konvertout)+' Ft';

  _egyenleg := abs(_egyenleg);
  VisszaJaroFtPanel.Caption := Form1.ForintForm(_egyenleg)+' Ft';

  logirorutin(pchar('A vevõnek vissza kell adni '+inttostr(_egyenleg)+' forintot'));

  EladasInfoPanel.Visible   := True;
  EladasFtPanel.Visible     := True;
  VisszajaroPanel.Visible   := True;
  VisszajaroFtPanel.Visible := true;
  AlapPanel.Repaint;
end;

// =============================================================================
              function TUJKonverzio.GetFizetendo: integer;
// =============================================================================

begin
  Valutadbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      result := FieldByName('FIZETENDO').asInteger;
      Close;
    end;
  Valutadbase.close;
end;
end.
