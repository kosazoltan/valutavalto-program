unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, unit1, Buttons, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type

  TSetRateType = class(TForm)
     Panel1: TPanel;

         Label1: TLabel;
    GOMB3: TBitBtn;
    GOMB4: TBitBtn;
    Label2: TLabel;
    Panel2: TPanel;
    GOMB5: TBitBtn;
    GOMB6: TBitBtn;
    GOMB7: TBitBtn;
    Label3: TLabel;
    GOMB11: TBitBtn;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    valutatranz: TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure GOMB1Enter(Sender: TObject);
    procedure GOMB1Exit(Sender: TObject);
    procedure GOMB1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure GOMB1Click(Sender: TObject);

    procedure BEADTAGOMBClick(Sender: TObject);
    procedure NEMADTABEGOMBClick(Sender: TObject);
    procedure GOMB5Click(Sender: TObject);
    procedure GOMB6Click(Sender: TObject);
    procedure GOMB7Click(Sender: TObject);
    procedure GOMB4Click(Sender: TObject);
    procedure GOMB3Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SetRateType: TSetRateType;
  _aktgomb : TBitbtn;
  _pcs: string;

implementation

{$R *.dfm}

// =============================================================================
             procedure TSetRateType.FormActivate(Sender: TObject);
// =============================================================================

begin

    Left := 340 + _left;
     Top := 170 + _top;
  Height := 240;
   Width := 376;


  Gomb11.Enabled := True;
  Gomb3.Enabled  := True;
  Gomb4.Enabled  := True;

  Panel2.Visible := False;
  ActiveControl  := Gomb11;
end;


// =============================================================================
                procedure TSetRateType.Gomb1Enter(Sender: TObject);
// =============================================================================

begin
  _aktGomb := tBitbtn(sender);
  _aktgomb.Font.Style := [fsBold];
end;

// =============================================================================
              procedure TSetRateType.Gomb1Exit(Sender: TObject);
// =============================================================================

begin
  _aktGomb := TBitbtn(sender);
  _aktgomb.Font.Style := [];
end;


// =============================================================================
   procedure TSetRateType.Gomb1MouseMove(Sender: TObject; Shift: TShiftState;
                                                                X, Y: Integer);
// =============================================================================

begin
  _AktGomb := Tbitbtn(Sender);
  ActiveControl := _aktGomb;
end;

// =============================================================================
              procedure TSetRateType.Gomb1Click(Sender: TObject);
// =============================================================================

begin
  Modalresult := 8;
end;


procedure TSetRateType.BEADTAGOMBClick(Sender: TObject);
begin
  _kartyaBeadva := 1;
  ModalResult := 10;
end;

procedure TSetRateType.NEMADTABEGOMBClick(Sender: TObject);
begin
  _kartyabeadva := 0;
  ModalResult := 10;
end;

procedure TSetRateType.Gomb5Click(Sender: TObject);
begin
  Modalresult := 64;
end;

procedure TSetRateType.Gomb6Click(Sender: TObject);
begin
  Modalresult := 32;
end;

procedure TSetRateType.Gomb7Click(Sender: TObject);
begin
  Modalresult := 16;
end;

procedure TSetRateType.Gomb4Click(Sender: TObject);
begin
   Modalresult := 128;
end;

procedure TSetRateType.GOMB3Click(Sender: TObject);
begin
  SetrateType.Height := 353;

  Gomb3.Enabled  := False;
  Gomb11.Enabled := False;
  Panel2.Visible := True;
  ActiveControl  := gomb5;
end;

end.
