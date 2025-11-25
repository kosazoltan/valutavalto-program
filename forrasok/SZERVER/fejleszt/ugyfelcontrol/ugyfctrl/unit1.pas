unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBQuery, IBCustomDataSet,
  IBTable, DateUtils, ExtCtrls, Grids, DBGrids, StrUtils, jpeg, wininet,
  ComCtrls;

type
  TForm1 = class(TForm)
    NTABLA         : TIBTable;
    NQUERY         : TIBQuery;
    NDBASE         : TIBDatabase;
    NTRANZ         : TIBTransaction;
    NATURSOURCE    : TDataSource;
    Label2         : TLabel;
    JOGISOURCE     : TDataSource;
    Shape1         : TShape;
    Panel1         : TPanel;
    Panel2         : TPanel;
    BIZSOURCE      : TDataSource;
    FOMENUPANEL: TPanel;
    Label71: TLabel;
    IDOSZAKKERESOGOMB: TBitBtn;
    UGYFELKERESOGOMB: TBitBtn;
    EXITGOMB: TBitBtn;
    Shape8: TShape;
    EVIMAXGOMB: TBitBtn;
    TERRORNAPLOGOMB: TBitBtn;
    UJIMPORTGOMB: TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure FoMenube;
    procedure ExitGombClick(Sender: TObject);


    procedure UGYFELKERESOGOMBClick(Sender: TObject);
    procedure IDOSZAKKERESOGOMBClick(Sender: TObject);
    procedure FOMENUREGOMBClick(Sender: TObject);


    procedure EVIMAXGOMBClick(Sender: TObject);
    procedure TERRORNAPLOGOMBClick(Sender: TObject);
    procedure UJIMPORTGOMBClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _height,_width,_left,_top: word;

function terrornaplorutin: integer; stdcall; external 'c:\uctrl\bin\terrnaplo.dll';
function evimaxtranzakciok: integer; stdcall; external 'c:\uctrl\bin\evimax.dll';
function keresotiltorutin: integer; stdcall; external 'c:\uctrl\bin\kereso.dll';
function adatlistazorutin: integer; stdcall; external 'c:\uctrl\BIN\lista.dll';
function ujimportkeszito: integer; stdcall; external 'c:\uctrl\bin\ujimport.dll';

implementation



{$R *.dfm}

// =============================================================================
                procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _left := round((_width-1000)/2);
  _top  := round((_height-537)/2);

  Top := _top-155;
  left:= _left-10;
  Repaint;

  FoMenuBe;
end;

// =============================================================================
                           procedure TForm1.Fomenube;
// =============================================================================

begin
  with FomenuPanel do
    begin
      top     := 160;
      left    := 288;
      Visible := true;
      repaint;
    end;

  ActiveControl := IdoszakKeresoGomb;
end;


// =============================================================================
            procedure TForm1.FOMENUREGOMBClick(Sender: TObject);
// =============================================================================

begin
  Fomenube;
end;


//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$




// =============================================================================
            procedure TForm1.UgyfelKeresoGombClick(Sender: TObject);
// =============================================================================

begin
  FomenuPanel.visible := False;
  keresotiltorutin;
  FoMenube;
end;



// =============================================================================
                procedure TForm1.EVIMAXGOMBClick(Sender: TObject);
// =============================================================================

begin
  FomenuPanel.Visible := False;
  evimaxtranzakciok;
  Fomenube;
end;

// =============================================================================
             procedure TForm1.IdoszakKeresoGombClick(Sender: TObject);
// =============================================================================

begin
  FoMenuPanel.Visible := False;
  adatlistazorutin;
  Fomenube;
end;

// =============================================================================
                  procedure TForm1.ExitGombClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;


procedure TForm1.TERRORNAPLOGOMBClick(Sender: TObject);
begin
  FomenuPanel.Visible := False;
  terrornaplorutin;
  Fomenube;
end;

procedure TForm1.UJIMPORTGOMBClick(Sender: TObject);
begin
  ujimportkeszito;
end;

end.

