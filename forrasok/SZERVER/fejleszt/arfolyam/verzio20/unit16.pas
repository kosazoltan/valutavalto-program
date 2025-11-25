unit Unit16;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, Unit1, ExtCtrls, strutils;

type
  TIRODANEVLISTA = class(TForm)
    VISSZAGOMB: TBitBtn;
    Label1: TLabel;
    IRODAVALASZTOGOMB: TBitBtn;
    ListBox1: TListBox;
    KILEPO: TTimer;
    Shape1: TShape;
    UJPENZTARGOMB: TBitBtn;
    UJPPANEL: TPanel;
    Label2: TLabel;
    SZAMEDIT: TEdit;
    NEVEDIT: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    ujptokegomb: TBitBtn;
    ujmegsemgomb: TBitBtn;
    Shape2: TShape;
    procedure FormActivate(Sender: TObject);
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure ListBoxFeltoltes;


    procedure IRODAVALASZTOGOMBClick(Sender: TObject);

    procedure IrodatValasztott;
    procedure KILEPOTimer(Sender: TObject);
    function Haromstr(_b: byte):string;
    procedure ListBox1DblClick(Sender: TObject);
    procedure ListBox1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UJPENZTARGOMBClick(Sender: TObject);
    procedure ujmegsemgombClick(Sender: TObject);
    procedure ujptokegombClick(Sender: TObject);
    function VanIlyenIrodaszam(_isz: byte): boolean;
    procedure SZAMEDITEnter(Sender: TObject);
    procedure SZAMEDITExit(Sender: TObject);
    procedure SZAMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  IRODANEVLISTA: TIRODANEVLISTA;
  _index,_irodaszam,_ss,_y,_mresult: integer;
  _isz,_inev,_icim,_text: string;
  _aktcsop,_freepenztardb,_ptsz: byte;

implementation

{$R *.dfm}

// =============================================================================
           procedure TIRODANEVLISTA.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := _top+150;
  Left := _left+220;
  Ujppanel.Visible := false;

  _mResult := -1;
  ListboxFeltoltes;

  _freePenztardb := Listbox1.count;
  if _freePenztardb>0 then
    begin
      Listbox1.ItemIndex := 0;
      Listbox1.SetFocus;
    end else Activecontrol := UjpenztarGomb;
end;


procedure TIrodaNevLista.Listboxfeltoltes;

begin
  ListBox1.Items.clear;
  Listbox1.clear;

  _y := 1;
  while _y<=_irodadarab do
    begin
      _aktcsop := _ptarcsop[_y];
      if _aktcsop=0 then
        begin
          _ptsz := _ptarszam[_y];
          _text := Haromstr(_ptsz)+' - ' + _ptarnev[_y];
          Listbox1.Items.Add(_text);
        end;
      inc(_y);
    end;
end;



// =============================================================================
         procedure TIRODANEVLISTA.ListBox1DblClick(Sender: TObject);
// =============================================================================

begin
  IrodatValasztott;
end;

// =============================================================================
     procedure TIRODANEVLISTA.ListBox1KeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Irodatvalasztott;
end;

// =============================================================================
       procedure TIRODANEVLISTA.IRODAVALASZTOGOMBClick(Sender: TObject);
// =============================================================================

begin
  irodatvalasztott;
end;

// =============================================================================
                  procedure TIrodaNevLista.IrodatValasztott;
// =============================================================================

var _irodas: string;
    _iroda: integer;
    
begin
  _index := Listbox1.ItemIndex;
  _text := Listbox1.Items[_index];
  _irodas := leftstr(_text,3);
  val(_irodas,_iroda,_code);
  if _code<>0 then _iroda := 0;
  if _iroda>0 then _mResult := _iroda else _mResult := -1;
  Kilepo.Enabled := true;
end;

// =============================================================================
         procedure TIRODANEVLISTA.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  _Mresult := -1;
  Kilepo.Enabled := true;
end;

// =============================================================================
          procedure TIRODANEVLISTA.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.enabled := false;
  Modalresult := _mResult;
end;

// =============================================================================
           function TIrodanevLista.Haromstr(_b: byte):string;
// =============================================================================

begin
  result := inttostr(_b);
  while length(result)<3 do result := '0' + result;
end;





procedure TIRODANEVLISTA.UJPENZTARGOMBClick(Sender: TObject);
begin

  Szamedit.Clear;
  Nevedit.clear;

  with UjpPanel do
    begin
      Top := 312;
      Left := 16;
      Visible := true;
    end;
  Activecontrol := Szamedit;
end;

procedure TIRODANEVLISTA.ujmegsemgombClick(Sender: TObject);
begin
  Ujppanel.Visible := false;
end;

procedure TIRODANEVLISTA.ujptokegombClick(Sender: TObject);

var _ujnums,_ujnev: string;
    _ujnum: byte;

begin
  _ujnums := trim(szamedit.Text);
  val(_ujnums,_ujnum,_code);
  if _code<>0 then _ujnum := 0;
  if (_ujnum=0) or (_ujnum>170) then
    begin
      Szamedit.clear;
      Activecontrol := Szamedit;
      exit;
    end;

  if VanilyenIrodaszam(_ujnum) then
    begin
      ShowMessage('ILYEN SZÁMÚ IRODA MÁR VAN !');
      Szamedit.clear;
      Activecontrol := Szamedit;
      exit;
    end;

  _ujnev := trim(nevedit.Text);

  if _ujnev='' then
    begin
      Nevedit.clear;
      Activecontrol := Nevedit;
      exit;
    end;
  inc(_irodadarab);
  _ptarszam[_irodadarab] := _ujnum;
  _ptarnev[_irodadarab]  := _ujnev;
  _ptarcsop[_irodadarab] := 0;
  UjpPanel.Visible := false;
  ListboxFeltoltes;
  Listbox1.ItemIndex := 0;
  Listbox1.SetFocus;
end;

function TIrodanevLista.VanIlyenIrodaszam(_isz: byte): boolean;

var _y: byte;

begin
  result := False;
  _y := 1;
  while _y<=_irodadarab do
    begin
      if _ptarszam[_y]=_isz then
        begin
          result := true;
          exit;
        end;
      inc(_y);
    end;
end;

procedure TIRODANEVLISTA.SZAMEDITEnter(Sender: TObject);
begin
  TEdit(sender).Color := clYellow;
end;

procedure TIRODANEVLISTA.SZAMEDITExit(Sender: TObject);
begin
  Tedit(sender).Color := clwhite;
end;

procedure TIRODANEVLISTA.SZAMEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  Activecontrol := Nevedit;
end;

procedure TIRODANEVLISTA.NEVEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  Activecontrol := UjPtOkeGomb;
end;

end.
