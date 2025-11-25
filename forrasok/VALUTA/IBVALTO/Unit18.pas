unit Unit18;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1, DB, DBTables, StrUtils,
  DateUtils, ComCtrls, IBDatabase, IBCustomDataSet, IBTable, IBQuery, jpeg;

type

    TZarasForm = class(TForm)

       FomenuPanel: TPanel;
    CimletezesGomb: TBitBtn;
     HavizarasGomb: TBitBtn;
     NapizarasGomb: TBitBtn;
    VISSZAGOMB: TBitBtn;

    NAPIZARPANEL: TPanel;

    TerminalGomb: TBitBtn;
      CancelGomb: TBitBtn;
    Shape3: TShape;
    SUNSET: TImage;
    BitBtn1: TBitBtn;
    Label1: TLabel;

    procedure CancelGombClick(Sender: TObject);
    procedure CimletezesGombEnter(Sender: TObject);
    procedure CimletezesGombExit(Sender: TObject);
    procedure CimletezesGombClick(Sender: TObject);
    procedure EscapeGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure HaviZarasGombClick(Sender: TObject);
 
    procedure NapizarasGombClick(Sender: TObject);
    procedure TerminalGombClick(Sender: TObject);
  

    procedure VISSZAGOMBClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ZarasForm: TZarasForm;


function napzarrutin: integer; stdcall; external 'c:\valuta\bin\napzar.dll' name 'napzarrutin';
function havizarorutin: integer; stdcall; external 'c:\valuta\bin\havizar.dll' name 'havizarorutin';
function cimletnyomtatorutin: integer; stdcall; external 'c:\valuta\bin\cimlnyom.dll' name 'cimletnyomtatorutin';

implementation


{$R *.dfm}


// =============================================================================
                procedure TZarasForm.FormCreate(Sender: TObject);
// =============================================================================

begin
    Top  := _top;
    Left := _left;
   Width := 1024;
  Height := 768;

  NapiZarPanel.Visible := False;
end;


// =============================================================================
             procedure TZARASFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
     Top := _top;
    Left := _left;
   Width := 1024;
  Height := 768;

  NapiZarPanel.Visible := False;

  with FomenuPanel do
    begin
      top     := 460;
      Left    := 16;
      Visible := True;
    end;
  ActiveControl := CimletezesGomb;
end;

// =============================================================================
            procedure TZarasForm.NapiZarasGombClick(Sender: TObject);
// =============================================================================


var _ZOK: integer;

begin
  logirorutin(pchar('Napi-zárás gombra klikkelt'));

  FomenuPanel.Visible   := False;

  // Beküldi a pillanatnyi állást

  _pcs := 'DELETE FROM VTEMP';
  Form1.ValutaParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (DATUM)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _megnyitottnap + chr(39) + ')';
  Form1.ValutaParancs(_pcs);

  // A napzárás végrehajtása:

  _ZOk := napzarrutin;

  // HA nem volt sikeres a napzárás, akkor itt visszalép:

  if _ZOK<>1 then
    begin
      logirorutin(pchar('Napzárás során valami hiba történt'));
      ShowMessage('A NAPZÁRÁS SORÁN HIBA LÉPETT FEL !');
      FomenuPanel.Visible := true;
      Exit;
    end;

  logirorutin(pchar('Sikeres zárás - adatok beküldhetõk'));
  ShowMessage('A NAPI ZÁRÁST SIKERESEN VÉGREHAJTOTTAM ! ADATOK BEKÜLDHETÕK !');

  with NapizarPanel do
    begin
      Top := 650;
      Left := 560;
      Visible := true;
    end;
  ActiveControl := TerminalGomb;
end;

// =============================================================================
      procedure TZARASFORM.HAVIZARASGOMBClick(Sender: TObject);
// =============================================================================

begin
   logirorutin(pchar('Havi-zárás gombra klikkelt'));
   havizarorutin;
   ModalResult := 1;
end;

// =============================================================================
         procedure TZARASFORM.cancelgombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

// =============================================================================
       procedure TZarasForm.TerminalGombClick(Sender: TObject);
// =============================================================================

begin
   terminalrutin;
   ModalResult := 1;
end;

// =============================================================================
            procedure TZarasForm.EscapeGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
          procedure TZARASFORM.CIMLETEZESGOMBEnter(Sender: TObject);
// =============================================================================

begin
  TBitBtn(sender).Font.Style:= [fsItalic,fsbold];
end;

// =============================================================================
             procedure TZARASFORM.CIMLETEZESGOMBExit(Sender: TObject);
// =============================================================================

begin
  TBitBtn(Sender).Font.Style := [fsItalic];
end;

// =============================================================================
            procedure TZARASFORM.CIMLETEZESGOMBClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('Cimletezni szeretne'));
  _freeIrq := False;
  regeneralorutin(0);
  cimletmenurutin;
  _freeIrq := True;
end;


// =============================================================================
             procedure TZarasForm.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

// =============================================================================
              procedure TZarasForm.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('Cimletnyomtató gombra klikkelt'));
  cimletnyomtatorutin;
end;

end.