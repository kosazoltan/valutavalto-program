unit Unit5;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TTRYAGAINFORM = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    YESGOMB: TBitBtn;
    NOGOMB: TBitBtn;
    Shape1: TShape;
    procedure FormActivate(Sender: TObject);
    procedure YESGOMBClick(Sender: TObject);
    procedure NOGOMBClick(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TRYAGAINFORM: TTRYAGAINFORM;
  _top,_left,_width,_height: word;

implementation

{$R *.dfm}

// =============================================================================
            procedure TTRYAGAINFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;
  _top    := round((_height-270)/2);
  _left   := round((_width-480)/2);

  top     := _top;
  left    := _left;
  width   := 480;
  height  := 270;

  repaint;

  Activecontrol := yesgomb;
end;

// =============================================================================
              procedure TTRYAGAINFORM.YESGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
               procedure TTRYAGAINFORM.NOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

end.
