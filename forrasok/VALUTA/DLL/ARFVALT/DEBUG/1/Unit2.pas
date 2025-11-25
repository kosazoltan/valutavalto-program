unit Unit2;


interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, StrUtils;

type
  TARFOLYAMVALTOZTATAS = class(TForm)
    Panel2: TPanel;
    VALUTANEVPANEL: TPanel;
    Label2: TLabel;
    ALAPARFOLYAMPANEL: TPanel;
    Panel7: TPanel;
    UJARFOLYAMEDIT: TEdit;
    ARFMODIOKEGOMB: TBitBtn;
    ARFMODICANCELGOMB: TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure ARFMODIOKEGOMBClick(Sender: TObject);
    procedure ARFMODICANCELGOMBClick(Sender: TObject);
    function Arfform(_r: real): string;


//   function FtForm(_int: integer): string;



    procedure UJARFOLYAMEDITEnter(Sender: TObject);
    procedure UJARFOLYAMEDITExit(Sender: TObject);
    procedure UJARFOLYAMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ARFOLYAMVALTOZTATAS: TARFOLYAMVALTOZTATAS;
  _workarfolyam,_minarfolyam,_maxarfolyam: integer;
  _tol,_ig: real;
  _mresult: integer;
  _ujarfs: string;
  _pos: integer;


implementation

uses Unit1;

{$R *.dfm}

// =============================================================================
          procedure TARFOLYAMVALTOZTATAS.FormActivate(Sender: TObject);
// =============================================================================


begin
  Top    := 230 + _top;
  Left   := 320 + _left;
  Height := 260;
  Width  := 410;

  _mresult := -1;

  ArfmodiOkegomb.Enabled := False;
  Ujarfolyamedit.ReadOnly := false;


  ValutanevPanel.Caption := _aktdnev;

  AlaparfolyamPanel.Caption := Arfform(_aktArfolyam);

  UjarfolyamEdit.clear;
  ActiveControl := Ujarfolyamedit;
end;


function TarfolyamValtoztatas.Arfform(_r: real): string;

var _rs: string;
    _ps: byte;
begin
  _rs := floattostr(_r);
  _ps := length(_rs)-2;
  result := leftstr(_rs,_ps)+','+midstr(_rs,_ps+1,2);
end;


// =============================================================================
     procedure TARFOLYAMVALTOZTATAS.UJARFOLYAMEDITKeyDown(Sender: TObject;
                                            var Key: Word; Shift: TShiftState);
// =============================================================================


var _wujs: byte;

begin
  if ord(key)<>13 then exit;

  _ujarfs := trim(Ujarfolyamedit.text);
  if _ujarfs='' then
    begin
      ActiveControl := ArfModiCancelGomb;
      Exit;
    end;

  _pos := pos(chr(44),_ujarfs);
  if _pos>0 then
    begin
      _wujs := length(_ujarfs);
      _ujarfs := leftstr(_ujarfs,_pos-1)+midstr(_ujarfs,_pos+1,_wujs-_pos);
    end;

  val(_ujarfs,_workarfolyam,_code);
  if _code<>0 then _workArfolyam := 0;

  if _workarfolyam=0 then
    begin
      ActiveControl := ArfModiCancelGomb;
      Exit;
    end;

  _ujarfolyam := (1*_workArfolyam);
  UjarfolyamEdit.Text := Arfform(_ujarfolyam);
  _spk := supervisorjelszo(1);
  if _spk<>1 then
    begin
      Activecontrol := ArfModiCancelGomb;
      Exit;
    end;

  _jelszavas := True;

  _mresult := 8;

  UjarfolyamEdit.ReadOnly := true;
  ArfmodiOkegomb.Enabled := true;
  ActiveControl := ArfmodiOkegomb;
end;

// =============================================================================
        procedure TARFOLYAMVALTOZTATAS.UJARFOLYAMEDITEnter(Sender: TObject);
// =============================================================================

begin
  Ujarfolyamedit.Color := $B0FFFF;
end;

// =============================================================================
      procedure TARFOLYAMVALTOZTATAS.UJARFOLYAMEDITExit(Sender: TObject);
// =============================================================================

begin
  Ujarfolyamedit.Color := clWhite;
end;


{
// =============================================================================
       function TArfolyamValtoztatas.FtForm(_int: integer): string;
// =============================================================================

var _wlen,_pp: integer;

begin
  result := inttostr(_int);
  if _int>=1000 then
    begin
      _wlen := length(result);
      _pp := _wlen-3;
      result := leftstr(result,_pp)+','+midstr(result,_pp+1,3);
    end;
  while length(result)<6 do result := ' '+ result;
end;
}


// =============================================================================
      procedure TArfolyamValtoztatas.ArfModiOkeGombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := _mresult;
end;

// =============================================================================
     procedure TarfolyamValtoztatas.ArfModiCancelGombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := -1;
end;

end.
