unit Unit31;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, IBDatabase, DB, IBCustomDataSet, IBTable, StdCtrls, StrUtils,
  Buttons, unit1, Grids, DBGrids, ExtCtrls, IBQuery;

type
  TJUTSZAM = class(TForm)
    Label1: TLabel;
    KILEPO: TTimer;

    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  JUTSZAM: TJUTSZAM;



function jutalekszamitas: integer; stdcall; external 'c:\receptor\jutalek.dll' name 'jutalekszamitas';

implementation


{$R *.dfm}

// ========================================================================
          procedure TJUTSZAM.FormActivate(Sender: TObject);
// ========================================================================

begin

  Top  := 0;
  Left := 0;

  jutalekszamitas;
  Kilepo.enabled := true;
end;


procedure TJUTSZAM.KILEPOTimer(Sender: TObject);
begin
  kILEPO.Enabled := FALSE;
  Modalresult := 1;
end;

end.
