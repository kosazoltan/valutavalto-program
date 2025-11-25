unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1;

type
  TINTERNETTMKFORM = class(TForm)
    Panel1: TPanel;
    Shape1: TShape;
    UJINTERNETGOMB: TBitBtn;
    INTERNETDELETEGOMB: TBitBtn;
    VISSZAGOMB: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
    UJINTERNETPANEL: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    INTERNETCIMEDIT: TEdit;
    Label5: TLabel;
    GOMBFELIRATEDIT: TEdit;
    Label6: TLabel;
    GOMBSZAMEDIT: TEdit;
    UJURLOKEGOMB: TBitBtn;
    UJURLMEGSEMGOMB: TBitBtn;
    URLTORLOPANEL: TPanel;
    INTERNETCIMLISTA: TListBox;
    Label7: TLabel;
    DELCIMPANEL: TPanel;
    Label8: TLabel;
    TORLOGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    TAKAROPANEL: TPanel;
    procedure UJURLMEGSEMGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure INTERNETCIMEDITEnter(Sender: TObject);
    procedure INTERNETCIMEDITExit(Sender: TObject);
    procedure UJINTERNETGOMBEnter(Sender: TObject);
    procedure UJINTERNETGOMBExit(Sender: TObject);
    procedure UJINTERNETGOMBMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure UJINTERNETGOMBClick(Sender: TObject);
    procedure INTERNETCIMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure GOMBFELIRATEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure GOMBSZAMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UJURLOKEGOMBClick(Sender: TObject);
    procedure INTERNETDELETEGOMBClick(Sender: TObject);
    procedure INTERNETCIMLISTADblClick(Sender: TObject);
    procedure TORLOGOMBClick(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  INTERNETTMKFORM: TINTERNETTMKFORM;
  _cims,_gombcims,_gombs: string;
  _gombszam,_index: integer;

implementation

{$R *.dfm}

procedure TINTERNETTMKFORM.UJURLMEGSEMGOMBClick(Sender: TObject);
begin
  UjinternetPanel.Visible := false;
  Activecontrol := Ujinternetgomb;
end;

procedure TINTERNETTMKFORM.FormActivate(Sender: TObject);
begin
  top := _top + 140;
  Left := _left + 60;
  UjInternetPanel.Visible := False;
  UrlTorlopanel.Visible := False;
  Takaropanel.visible := true;
  Activecontrol := UjinternetGomb;
end;

procedure TINTERNETTMKFORM.INTERNETCIMEDITEnter(Sender: TObject);
begin
  TEdit(sender).color := $B0FFFF;
end;

procedure TINTERNETTMKFORM.INTERNETCIMEDITExit(Sender: TObject);
begin
   TEdit(sender).color := clwhite;
end;

procedure TINTERNETTMKFORM.UJINTERNETGOMBEnter(Sender: TObject);
begin
  with TBitbtn(Sender).Font do
    begin
      Color := clNavy;
      Style := [fsItalic];
    end;
end;

procedure TINTERNETTMKFORM.UJINTERNETGOMBExit(Sender: TObject);
begin
   with TBitbtn(Sender).Font do
    begin
      Color := clBlack;
      Style := [];
    end;
end;

procedure TINTERNETTMKFORM.UJINTERNETGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := TBitBtn(sender);
end;

procedure TINTERNETTMKFORM.VISSZAGOMBClick(Sender: TObject);
begin
  ModalResult := 1;
end;

procedure TINTERNETTMKFORM.UJINTERNETGOMBClick(Sender: TObject);
begin
  if _urldarab=_dnemdarab then
    begin
      Showmessage('NINCS TÖBB SZABAD INTERNETBILLENTYÜ !');
      exit;
    end;

  InternetCimedit.Clear;
  Gombfeliratedit.Clear;
  Gombszamedit.clear;
  UjinternetPanel.Visible := True;
  ActiveControl := internetcimedit;
end;

procedure TINTERNETTMKFORM.INTERNETCIMEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  _cims := trim(InternetCimEdit.text);
  if _cims='' then exit;
  ActiveControl := GombfeliratEdit;
end;

procedure TINTERNETTMKFORM.GOMBFELIRATEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ord(key)=38 then
    begin
      activeControl := Internetcimedit;
      exit;
    end;
  if ord(key)<>13 then exit;
  _gombcims := trim(GombFeliratedit.text);
  if _gombcims='' then exit;
  Activecontrol := Gombszamedit;
end;


procedure TINTERNETTMKFORM.GOMBSZAMEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if ord(Key)=38 then
    begin
      ActiveControl := Gombfeliratedit;
      exit;
    end;
  if ord(key)<>13 then exit;
  _gombs := trim(GombszamEdit.text);

  val(_gombs,_gombszam,_code);
  if _code<>0 then _gombszam := 0;

  if (_gombszam>20) then
    begin
      Showmessage('MAXIMUM 20 LEHET A GOMBSZÁM !');
      gOMBSZAMEDIT.CLEAR;
      ActiveControl := GombSzamedit;
      exit;
    end;
  ActiveControl := UjUrlOkeGomb;
end;

procedure TINTERNETTMKFORM.UJURLOKEGOMBClick(Sender: TObject);
begin
  _arfDataValtozott := true;
  _cims := trim(InternetCimEdit.text);
  _gombcims := trim(GombFeliratedit.text);
  _gombs := trim(GombszamEdit.text);
  val(_gombs,_gombszam,_code);
  if _code<>0 then _gombszam := 0;

  if _cims='' then
    begin
      ActiveControl := Internetcimedit;
      Exit;
    end;

  if _gombcims='' then
    begin
      ActiveControl := GombfeliratEdit;
      Exit;
    end;
  _qq := 0;
  while _qq<_urlDarab do
    begin
      if _urlgombszam[_qq]=_gombszam then
        begin
          Showmessage(inttostr(_gombszam)+' SZÁMU GOMB MÁR KI VAN OSZTVA. vÁLASSZON MÁSIKAT');
          ActiveControl := GombszamEdit;
          exit;
        end;
      inc(_qq);
    end;
  _urlgombszam[_urldarab] := _gombszam;
  _urlgombnevek[_urldarab] := _gombcims;
  _urlnevek[_urldarab] := _cims;
  inc(_urldarab);
  Ujinternetpanel.Visible := false;
  ActiveControl := VisszaGomb;
end;


procedure TINTERNETTMKFORM.INTERNETDELETEGOMBClick(Sender: TObject);

var _text: string;

begin
  // INTERNETCIM TÖRLÉSE
  internetcimlista.Items.clear;
  internetcimlista.Clear;
  _qq := 0;
  while _qq<=_urldarab do
    begin
      _text := _urlgombnevek[_qq]+' -> '+ _urlnevek[_qq];
      InternetCimLista.Items.add(_text);
      inc(_qq);
    end;
  with UrlTorloPanel do
    begin
      Top  := 200;
      Left := 8;
      Visible := true;
    end;
  ActiveControl := Internetcimlista;
end;

procedure TINTERNETTMKFORM.INTERNETCIMLISTADblClick(Sender: TObject);
var _gombnev: string;

begin
  _index := InternetCimlista.ItemIndex;
  _gombnev := _urlGombNevek[_index];
  Delcimpanel.Caption := _gombnev;
  TakaroPanel.Visible := false;
  ActiveControl := Torlogomb;
end;

procedure TINTERNETTMKFORM.TORLOGOMBClick(Sender: TObject);

var _gsz: integer;
    _un,_gn: string;
begin
  _arfdatavaltozott := true;

  _qq := _index+1;
  if _qq<_urldarab then
    begin
        while _qq<_urldarab do
          begin
            _gsz := _urlgombszam[_qq];
            _gn  := _urlgombnevek[_qq];
            _un  := _urlnevek[_qq];
            _urlgombszam[_qq-1] := _gsz;
            _urlgombnevek[_qq-1] := _gn;
            _urlNevek[_qq-1] := _un;
            inc(_qq);
          end;
    end;

  _urlgombszam[_qq] := 0;
  _urlGombnevek[_qq] := '';
  _urlnevek[_qq] := '';

  dec(_urldarab);
  Urltorlopanel.Visible := false;
  ActiveControl := VisszaGomb;
end;

procedure TINTERNETTMKFORM.MEGSEMGOMBClick(Sender: TObject);
begin
  Urltorlopanel.Visible := false;
  ActiveControl := VisszaGomb;
end;

end.
