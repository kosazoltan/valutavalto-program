unit Unit11;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OleCtrls, SHDocVw, UNIT1, StdCtrls, Buttons;

type
  TINTERNETBONGESZO = class(TForm)
    WebBrowser1: TWebBrowser;
    Label1: TLabel;
    BROWSERBACKGOMB: TBitBtn;
    WEBCLOSEGOMB: TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure BROWSERBACKGOMBClick(Sender: TObject);
    procedure WEBCLOSEGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  INTERNETBONGESZO: TINTERNETBONGESZO;

implementation

{$R *.dfm}

// =============================================================================
        procedure TINTERNETBONGESZO.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := _top;
  Left := _left;
  Width := 1366;
  Height := 768;

  if not _NyitottWeblap then
    begin
      WebBrowser1.Navigate(_akturl);
      _nyitottWebLap := True;
    end;
end;

// =============================================================================
      procedure TInternetBongeszo.WEBCLOSEGOMBClick(Sender: TObject);
// =============================================================================

begin
  WebBrowser1.Stop;
  _nyitottWeblap := False;
  ModalResult := 1;
end;

// =============================================================================
       procedure TINTERNETBONGESZO.BROWSERBACKGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

end.
