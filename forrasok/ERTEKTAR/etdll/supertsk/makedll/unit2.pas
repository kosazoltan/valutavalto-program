unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, Grids, DBGrids, ExtCtrls, DBTables,
  IBDatabase, IBCustomDataSet, IBTable, DateUtils, sTRuTILS, IBQuery;

type
  TSUPERVISORFORM = class(TForm)
    Panel1: TPanel;
    Shape1: TShape;
    Label2: TLabel;
    LOGFILEGOMB: TBitBtn;
    CIMLETSETUPGOMB: TBitBtn;
    ESCAPEGOMB: TBitBtn;
    Shape2: TShape;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    
    procedure FormActivate(Sender: TObject);
    procedure ESCAPEGOMBClick(Sender: TObject);

    procedure CIMLETSETUPGOMBClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

    procedure LOGFILEGOMBClick(Sender: TObject);
    procedure AlapadatBeolvasas;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SUPERVISORFORM: TSUPERVISORFORM;
  _top,_left,_width,_height: word;
  _megnyitottnap: string;


function cimletbeallito: integer; stdcall; external 'c:\ertektar\bin\cimsetup.dll' name 'cimletbeallito';
function logdisplayrutin: integer; stdcall; external 'c:\ertektar\bin\logdisp.dll' name 'logdisplayrutin';

function supervisorrutin: integer; stdcall;


implementation

function supervisorrutin: integer; stdcall;
begin
  supervisorForm := TsupervisorForm.create(Nil);
  result := supervisorForm.showmodal;
  SupervisorForm.Free;
end;  


{$R *.dfm}

// =============================================================================
              procedure TSUPERVISORFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top    := round((_height-768)/2);
  _left   := round((_width-1024)/2);


  Top     := _Top + 160;
  Left    := _Left + 350;
  Width   := 609;
  Height  := 417;

  AlapadatBeolvasas;
 
  Activecontrol := CimletSetupGomb;
end;


procedure TSUPERVISORFORM.AlapadatBeolvasas;

begin
  ibdbase.connected := true;
  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
      Close;
    end;
  Ibdbase.close;
end;



// =============================================================================
         procedure TSUPERVISORFORM.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;



// =============================================================================
        procedure TSUPERVISORFORM.CIMLETSETUPGOMBClick(Sender: TObject);
// =============================================================================

begin
  cimletbeallito;
end;

// =============================================================================
            procedure TSUPERVISORFORM.FormCreate(Sender: TObject);
// =============================================================================

begin
  Top := _Top + 260;
  Left := _Left + 350;
  Width := 410;
  Height := 350;
end;



procedure TSUPERVISORFORM.LOGFILEGOMBClick(Sender: TObject);
begin
  logdisplayrutin;
end;

end.
