unit Unit19;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1, DB, DBTables, IBDatabase,
  IBCustomDataSet, IBTable;

type
  TCIMLETLISTA = class(TForm)

    V1: TPanel;
    V2: TPanel;
    V3: TPanel;
    V4: TPanel;
    V5: TPanel;
    V6: TPanel;
    V7: TPanel;
    V8: TPanel;
    V9: TPanel;
    V10: TPanel;
    V11: TPanel;
    V12: TPanel;
    V13: TPanel;

    E1: TPanel;
    V25: TPanel;
    V26: TPanel;
    V19: TPanel;
    V20: TPanel;
    V21: TPanel;
    V22: TPanel;
    V23: TPanel;
    V24: TPanel;
    V18: TPanel;
    V17: TPanel;
    V16: TPanel;
    V15: TPanel;
    V14: TPanel;
    E14: TPanel;
    E2: TPanel;
    E3: TPanel;
    E4: TPanel;
    E5: TPanel;
    E6: TPanel;
    E7: TPanel;
    E8: TPanel;
    E9: TPanel;
    E10: TPanel;
    E11: TPanel;
    E12: TPanel;
    E13: TPanel;
    E15: TPanel;
    E16: TPanel;
    E17: TPanel;
    E18: TPanel;
    E19: TPanel;
    E20: TPanel;
    E21: TPanel;
    E22: TPanel;
    E23: TPanel;
    E24: TPanel;
    E25: TPanel;
    E26: TPanel;

    Label1: TLabel;
    Panel53: TPanel;
    Panel54: TPanel;
    Panel55: TPanel;
    Panel56: TPanel;

    Cimletokegomb: TBitBtn;
    Folytatomgomb: TBitBtn;
    POTCIMLETTABLA: TIBTable;
    POTCIMLETDBASE: TIBDatabase;
    POTCIMLETTRANZ: TIBTransaction;

    procedure CimletOkeGombClick(Sender: TObject);
    procedure FolytatomGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CimletLista: TCimletLista;
  Vt,Et: array[1..26] of TPanel;
  _aktvPanel,_aktePanel: TPanel;


implementation

uses Unit13;

{$R *.dfm}



// =======================================================================
       procedure TCimletLista.FormActivate(Sender: TObject);
// =======================================================================


var i,_osszesen: integer;
begin
  Top := 80;
  Left := 190;
  Vt[1] := v1;
  Vt[2] := v2;
  Vt[3] := v3;
  Vt[4] := v4;
  Vt[5] := v5;
  Vt[6] := v6;
  Vt[7] := v7;
  Vt[8] := v8;
  Vt[9] := v9;

  Vt[10] := v10;
  Vt[11] := v11;
  Vt[12] := v12;
  Vt[13] := v13;
  Vt[14] := v14;
  Vt[15] := v15;
  Vt[16] := v16;
  Vt[17] := v17;
  Vt[18] := v18;
  Vt[19] := v19;
  Vt[20] := v20;
  Vt[21] := v21;
  Vt[22] := v22;
  Vt[23] := v23;
  Vt[24] := v24;
  Vt[25] := v25;
  Vt[26] := v26;

  Et[1] := e1;
  Et[2] := e2;
  Et[3] := e3;
  Et[4] := e4;
  Et[5] := e5;
  Et[6] := e6;
  Et[7] := e7;
  Et[8] := e8;
  Et[9] := e9;

  Et[10] := e10;
  Et[11] := e11;
  Et[12] := e12;
  Et[13] := e13;
  Et[14] := e14;
  Et[15] := e15;
  Et[16] := e16;
  Et[17] := e17;
  Et[18] := e18;
  Et[19] := e19;
  Et[20] := e20;
  Et[21] := e21;
  Et[22] := e22;
  Et[23] := e23;
  Et[24] := e24;
  Et[25] := e25;
  Et[26] := e26;

  for i:= 1 to 26 do
    begin
      _aktVPanel := Vt[i];
      _aktEpanel := Et[i];
      _aktvPanel.Caption := '';
      _aktePanel.Caption := '';
    end;

  PotCimletTabla.Open;
  PotCimletTabla.First;

  if PotCimletTabla.Eof then
    begin
      PotCimletTabla.Close;
      Exit;
    end;

  _cc := 1;
  while not PotCimletTabla.Eof do
    begin
        _aktdnev := potCimletTabla.FieldByName('VALUTANEV').AsString;
       _osszesen := potcimletTabla.FieldByName('OSSZESFORINTERTEK').asInteger;
      _aktVpanel := Vt[_cc];
      _aktEPanel := Et[_cc];

      _aktVpanel.Caption := _aktdnev;
      _aktepanel.caption := Form1.ForintForm(_osszesen);
      inc(_cc);
      PotCimletTabla.Next;
    end;
  PotCimletTabla.Close;
end;

// =======================================================================
       procedure TCimletLista.CimletOkeGombClick(Sender: TObject);
// =======================================================================

begin
  ModalResult := 1;
end;

// =======================================================================
       procedure TCimletLista.FolytatomGombClick(Sender: TObject);
// =======================================================================

begin
  ModalResult := 2;
end;

end.
