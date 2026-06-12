unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ExtCtrls, StdCtrls, jpeg;

type
  TTOLTOFORM = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    UZENOPANEL: TPanel;
    CSIK: TProgressBar;
    Shape1: TShape;
    Image1: TImage;
    Image2: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    procedure FormActivate(Sender: TObject);
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TOLTOFORM: TTOLTOFORM;
  _top,_left,_width,_height: word;

implementation

{$R *.dfm}





procedure TTOLTOFORM.FormActivate(Sender: TObject);
begin
  _height := Screen.Monitors[0].height;
  _width  := Screen.Monitors[0].width;
  _top    := round((_height-250)/2);
  _left   := round((_width-780)/2);

  Top  := _top;
  left := _left;

end;



end.
