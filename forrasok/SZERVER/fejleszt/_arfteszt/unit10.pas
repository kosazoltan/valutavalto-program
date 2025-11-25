unit Unit10;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, UNIT1, ExtCtrls, Buttons;

type
  THELPFORM = class(TForm)
    Label1: TLabel;
    Shape1: TShape;
    Label2: TLabel;
    Shape2: TShape;
    Label3: TLabel;
    Label4: TLabel;
    Shape3: TShape;
    Label5: TLabel;
    Label6: TLabel;
    Shape4: TShape;
    Label7: TLabel;
    Label8: TLabel;
    Shape5: TShape;
    Label9: TLabel;
    Label10: TLabel;
    Shape6: TShape;
    Label11: TLabel;
    Label12: TLabel;
    Shape7: TShape;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Shape8: TShape;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    BitBtn1: TBitBtn;
    
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HELPFORM: THELPFORM;

implementation

{$R *.dfm}

// =============================================================================
             procedure THELPFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top   := _top;
  Left  := _left;
  Height := 729;
  Width := 1366;
end;

procedure THELPFORM.BitBtn1Click(Sender: TObject);
begin
  Modalresult := 1;
end;


end.
