unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

type
  TGetDisplay = class(TForm)
    AlapPanel: TPanel;
    Label1   : TLabel;
    MP1      : TPanel;
    MP8      : TPanel;
    MP7      : TPanel;
    MP6      : TPanel;
    MP2      : TPanel;
    MP3      : TPanel;
    MP4      : TPanel;
    MP5      : TPanel;
    Shape1   : TShape;
    Kilepo   : TTimer;

    procedure KilepoTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure MP8DblClick(Sender: TObject);
    procedure MP1Exit(Sender: TObject);
    procedure MP1Enter(Sender: TObject);
    procedure MP1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETDISPLAY: TGETDISPLAY;

  _y,_tag: byte;
  _mResult: integer;
  _aktpanel: TPanel;


// =============================================================================
                function getdisplaymenu: integer; stdcall;
// =============================================================================

implementation

{$R *.dfm}


// =============================================================================
                function getdisplaymenu: integer; stdcall;
// =============================================================================

begin
  getdisplay := TGetdisplay.Create(Nil);
  result := getdisplay.ShowModal;
  getdisplay.free;
end;

// =============================================================================
       procedure TGetDisplay.MP1MouseMove(Sender: TObject; Shift: TShiftState;
                                                             X, Y: Integer);
// =============================================================================

begin
  _aktpanel := TPanel(Sender);
  Activecontrol := _aktpanel;
end;


// =============================================================================
           procedure TGetDisplay.kilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

// =============================================================================
            procedure TGetDisplay.FormActivate(Sender: TObject);
// =============================================================================

begIN
  Top := 308;
  Left := 438;
  Activecontrol := MP1;

end;

// =============================================================================
             procedure TGetDisplay.MP8DblClick(Sender: TObject);
// =============================================================================

begin
  _mResult := Tpanel(Sender).tag;
  if _MRESULT=8 then _mResult := -1;
  Kilepo.Enabled := True;
end;

// =============================================================================
              procedure TGetDisplay.MP1Exit(Sender: TObject);
// =============================================================================

begin
   _aktpanel := Tpanel(sender);
   _aktpanel.Color := clWhite;
   _aktpanel.Font.Color := clSilver;
end;

// =============================================================================
            procedure TGetDisplay.MP1Enter(Sender: TObject);
// =============================================================================

begin
  _aktpanel := TPanel(sender);
  _aktPanel.Color := clYellow;
  _aktpanel.Font.Color := clRed;

end;



end.
