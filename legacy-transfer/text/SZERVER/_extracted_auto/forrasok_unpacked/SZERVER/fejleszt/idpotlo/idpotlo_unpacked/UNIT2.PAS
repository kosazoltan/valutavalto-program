unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1;

type
  TJONEVETVALASZT = class(TForm)
    BitBtn1: TBitBtn;
    JONEVLISTA: TListBox;
    NEVPANEL: TPanel;
    Label1: TLabel;
    Label2: TLabel;

    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure JONEVLISTADblClick(Sender: TObject);
    procedure JONEVLISTAKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  JONEVETVALASZT: TJONEVETVALASZT;
  _index: integer;

implementation

{$R *.dfm}

procedure TJONEVETVALASZT.BitBtn1Click(Sender: TObject);
begin
  _jopenztarosnev := '';
  _jopenztaroskod := '';
  ModalResult := 2;
end;

procedure TJONEVETVALASZT.FormActivate(Sender: TObject);

var _z: integer;
    _aktpnev: string;

begin

  Top    := _top+280;
  Left   := _left +24;
  Height := 280;
  Width  := 460;

  JonevLista.Items.clear;
  jonevlista.clear;

  NevPanel.Caption := _keresettnev;
  Nevpanel.Repaint;

  _z := 0;
  while _z<_prosnevdarab do
    begin
      _aktpnev := _tprosnev[_z];
      Jonevlista.Items.Add(_aktpnev);
      inc(_z);
    end;

  Jonevlista.Visible := true;
  Jonevlista.ItemIndex := 0;
  Activecontrol := JonevLista;
  Jonevlista.SetFocus;
end;



procedure TJONEVETVALASZT.JONEVLISTADblClick(Sender: TObject);
begin
  _index := JonevLista.itemindex;
  _jopenztarosnev := _Tprosnev[_index];
  _jopenztaroskod := _tIdkod[_index];
  Modalresult := 1;
end;

procedure TJONEVETVALASZT.JONEVLISTAKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
   _index := JonevLista.itemindex;
  _jopenztarosnev := _Tprosnev[_index];
  _jopenztaroskod := _tIdkod[_index];
  Modalresult := 1;

end;

end.
