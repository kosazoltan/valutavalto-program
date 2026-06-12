unit Unit11;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, Unit1, StrUtils;

type
  THIANYZOZARASOKFORM = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    TOVABBGOMB: TBitBtn;
    HIANYLIST: TListBox;
    Shape1: TShape;
    Bevel1: TBevel;

    procedure FormActivate(Sender: TObject);
    procedure TOVABBGOMBClick(Sender: TObject);
    
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HIANYZOZARASOKFORM: THIANYZOZARASOKFORM;

implementation

{$R *.dfm}

procedure THIANYZOZARASOKFORM.FormActivate(Sender: TObject);
var _point,_xx,_ss,_ww,_code: integer;
    _tar: string;
    _betu: char;

begin
  Top := _top +300;
  Left := _left +250;
  hianyList.Clear;
  _Tar := '';
  _hianystring := trim(_Hianystring);
  _ww := length(_hianyString);
  for _point := 1 to _ww do
    begin
      _betu := _hianyString[_point];
      if _betu=',' then
        begin
          val(_tar,_ss,_code);
          if _code=0 then _xx := _ss else _xx :=-1;

          if _xx>-1 then
               HianyList.Items.Add(_irodanev[_xx]);
          _tar := '';
        end else _tar := _tar + _betu;
    end;
 
  Activecontrol := HianyList;
  HianyList.SetFocus;
end;

procedure THIANYZOZARASOKFORM.TOVABBGOMBClick(Sender: TObject);
begin
  Modalresult := 1;
end;

end.
