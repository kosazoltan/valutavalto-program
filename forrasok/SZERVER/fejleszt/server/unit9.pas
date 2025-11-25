unit Unit9;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons,DateUtils, StrUtils, ExtCtrls;

type
  TIDOSZAKBEFORM = class(TForm)
    Label1: TLabel;
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    TOLCOMBO: TComboBox;
    Label2: TLabel;
    IGCOMBO: TComboBox;
    Label3: TLabel;
    IDSZOKEGOMB: TBitBtn;
    IDSZCANCELGOMB: TBitBtn;
    Shape1: TShape;
    procedure FormActivate(Sender: TObject);
    procedure IDSZOKEGOMBClick(Sender: TObject);
    procedure IDSZCANCELGOMBClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
    procedure TOLCOMBOChange(Sender: TObject);
    procedure IGCOMBOChange(Sender: TObject);
    procedure IDSZOKEGOMBEnter(Sender: TObject);
    procedure IDSZOKEGOMBExit(Sender: TObject);
    procedure IDSZOKEGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  IDOSZAKBEFORM: TIDOSZAKBEFORM;

implementation

uses Unit1;

{$R *.dfm}

procedure TIDOSZAKBEFORM.FormActivate(Sender: TObject);
var i: integer;
begin
  Top := _TOP +270;
  Left := _left + 180;
  ActiveControl := IdszOkeGomb;

  EVCOMBO.Clear;
  HoCombo.Clear;
  tolcombo.Clear;
  Igcombo.Clear;

  _aktev := yearof(date);
  _aktho := monthof(date);

  for i := -2 to 0 do  Evcombo.Items.add(inttostr(_aktev+i));
  for i := 1 to 12 do HoCombo.Items.Add(_honapnev[i]);
  _houtnap := daysinamonth(_aktev,_aktho);
  for i := 1 to _houtnap do
    begin
      tolcombo.Items.Add(inttostr(i));
      igCombo.Items.Add(inttostr(i));
    end;
  evcombo.ItemIndex := 2;
  hocombo.ItemIndex := _aktho-1;
  tolcombo.ItemIndex := 0;
  igCombo.ItemIndex := _houtnap-1;
  ActiveControl := idszokeGomb;
end;

procedure TIDOSZAKBEFORM.IDSZOKEGOMBClick(Sender: TObject);

var _hos: string;
    _tolindex,_igindex: integer;

begin
  _tolindex := tolcombo.itemindex;
  _igIndex := igCombo.ItemIndex;
  _kertev := (_aktev-2)+ evcombo.itemindex;
  _kertho := Hocombo.Itemindex + 1;
  _tols := tolcombo.items[_tolindex];
  _igs := Igcombo.Items[_igindex];

  if length(_tols)=1 then _tols := '0'+_tols;
  if length(_igs)=1 then _igs := '0'+_igs;
  _hos := inttostr(_kertho);

  if length(_hos)=1 then _hos := '0' + _hos;

  _tolstring := inttostr(_kertev)+'.'+ _hos + '.' + _tols;
  _igstring := leftstr(_tolstring,8)+_igs;
  _datumtols := _tolstring;
  _datumigs := _igstring;

  if _tolstring=_igstring then
    begin
      _ezegynap := True;
      _idoszakSzuro := 'DATUM='+chr(39)+_tolstring+chr(39);
    end else
    begin
      _ezegynap := False;
      _idoszakSzuro := 'DATUM BETWEEN '+chr(39)+_tolstring+chr(39)+' AND '+chr(39)+_igstring+chr(39);
    end;

  _farok := midstr(_tolstring,3,2)+midstr(_tolstring,6,2);  
  ModalResult := 1;
end;

procedure TIDOSZAKBEFORM.IDSZCANCELGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;

procedure TIDOSZAKBEFORM.EVCOMBOChange(Sender: TObject);
var i: integer;
begin
  _kertev := (_aktev-2)+ evcombo.Itemindex;
  _kertho := Hocombo.Itemindex + 1;
  _houtnap := DAysInAMonth(_kertev,_kertho);
  tolcombo.clear;
  Igcombo.Clear;
  for i := 1 to _houtnap do
    begin
      tolcombo.Items.add(inttostr(i));
      igcombo.Items.Add(inttostr(i));
    end;
  Tolcombo.Itemindex := 0;
  Igcombo.ItemIndex := _houtnap-1;
  ActiveControl := IdszOkeGomb;
end;

procedure TIDOSZAKBEFORM.TOLCOMBOChange(Sender: TObject);

var i: integer;

begin
  _tolnap := tolcombo.itemindex +1;
  igcombo.Clear;
  for i := _tolnap to _houtnap do IgCombo.Items.add(inttostr(i));
  Igcombo.ItemIndex := 0;
  ActiveControl := IdszOkeGomb;
end;

procedure TIDOSZAKBEFORM.IGCOMBOChange(Sender: TObject);
begin
  Activecontrol := IdszokeGomb;
end;

procedure TIDOSZAKBEFORM.IDSZOKEGOMBEnter(Sender: TObject);
begin
  TBitbtn(sender).Font.color := clBlack;
end;

procedure TIDOSZAKBEFORM.IDSZOKEGOMBExit(Sender: TObject);
begin
  TBitbtn(sender).font.Color := clGray;
end;

procedure TIDOSZAKBEFORM.IDSZOKEGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := TBitbtn(Sender);
end;

end.
