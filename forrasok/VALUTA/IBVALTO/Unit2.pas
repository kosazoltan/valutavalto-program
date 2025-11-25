unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1;

type
  TOpenKerdoForm = class(TForm)
    Panel1  : TPanel;
    Shape1  : TShape;
    Label1  : TLabel;
    IgenGomb: TBitBtn;
    UjraGomb: TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure IgenGombClick(Sender: TObject);
    procedure NemGombClick(Sender: TObject);
    procedure UjraGombClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OpenKerdoForm: TOpenKerdoForm;

implementation

{$R *.dfm}

// =============================================================================
           procedure TOpenKerdoForm.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := _top + 312;
  Left := _left + 368;
  ActiveControl := IgenGomb;
end;

// =============================================================================
          procedure TOpenKerdoForm.IGENGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
          procedure TOpenKerdoForm.NEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := -1;
end;

// =============================================================================
           procedure TOpenKerdoForm.UJRAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;



end.
