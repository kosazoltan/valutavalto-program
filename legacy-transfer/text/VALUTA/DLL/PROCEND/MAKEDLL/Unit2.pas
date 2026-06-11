unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery;

type

  TProcEndForm = class(TForm)
    Panel1: TPanel;
    HIDEEDIT: TEdit;

    procedure FormActivate(Sender: TObject);
//    procedure AktualNullazo;
    procedure Panel1Click(Sender: TObject);
    procedure HIDEEDITKeyPress(Sender: TObject; var Key: Char);
    procedure HIDEEDITEnter(Sender: TObject);
    procedure HIDEEDITExit(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ProcEndForm: TProcEndForm;
  _top,_left,_height,_width: word;
  _pcs: string;

function procendrutin: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
               function procendrutin: integer; stdcall;
// =============================================================================

begin
  Procendform := TProcendForm.Create(Nil);
  result := ProcendForm.showmodal;
  Procendform.Free;
end;




// =============================================================================
            procedure TProcEndForm.FormActivate(Sender: TObject);
// =============================================================================


begin
  _width := Screen.Monitors[0].Width;
  _height := screen.Monitors[0].Height;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top := _top + 290;
  Left := _left + 360;
  Height := 60;
  Width := 300;
  Panel1.Repaint;
  Hideedit.Clear;
  ActiveControl := HideEdit;
end;


{
// =============================================================================
                      procedure TProcEndForm.AktualNullazo;
// =============================================================================

begin
  _pcs := 'UPDATE UTOLSOBLOKKOK SET AKTUALISBIZONYLATSZAM='+CHR(39)+CHR(39);
  ibdbase.connected := true;
  if ibtranz.InTransaction then ibtranz.commit;
  ibtranz.StartTransaction;
  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      ExecSql;
    end;
  ibTranz.Commit;
  ibdbase.close;
end;
}


procedure TProcEndForm.Panel1Click(Sender: TObject);
begin
  Activecontrol := Hideedit;
end;

procedure TProcEndForm.HIDEEDITKeyPress(Sender: TObject; var Key: Char);
begin
  IF ord(key)=32 then
    begin
      Keypreview := False;
  //    AktualNullazo;
      Modalresult := 1;
    end;
end;

procedure TProcEndForm.HIDEEDITEnter(Sender: TObject);
begin
  Panel1.Font.Color := clYellow;
end;

procedure TProcEndForm.HIDEEDITExit(Sender: TObject);
begin
  Panel1.Font.Color := clWhite;
end;

end.
