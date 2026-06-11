unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, jpeg, unit1;

type
  TAUTOMOTORFORM = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    AUTOGOMB: TBitBtn;
    MOTORGOMB: TBitBtn;
    EGYIKSEMGOMB: TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure EGYIKSEMGOMBClick(Sender: TObject);
    procedure AUTOGOMBClick(Sender: TObject);
    procedure MOTORGOMBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AUTOMOTORFORM: TAUTOMOTORFORM;

implementation

{$R *.dfm}

// =============================================================================
            procedure TAUTOMOTORFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
   tOP := _TOP +360;
   Left := _left + 216;
   ActiveControl := Autogomb;
end;

// =============================================================================
         procedure TAUTOMOTORFORM.EGYIKSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Se autót, se motort nem választott');
  Modalresult := 3;
end;

// =============================================================================
            procedure TAUTOMOTORFORM.AUTOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Autót választott');
  Modalresult := 1;
end;

// =============================================================================
           procedure TAUTOMOTORFORM.MOTORGOMBClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Motort választott');
  Modalresult := 2;
end;

end.
