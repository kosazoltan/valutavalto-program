unit Unit17;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, DBTables, StdCtrls, Buttons, Grids, DBGrids, ExtCtrls, unit1,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery;

type
  TMNBLISTADISPLAY = class(TForm)
    Panel1: TPanel;
    MNBRACS: TDBGrid;
    FOCIMPANEL: TPanel;
    DISPLAYQUIT: TBitBtn;
    DISPLAYSOURCE: TDataSource;
    toligpanel: TPanel;
    nyomtatogomb: TBitBtn;
    DNEM1PANEL: TPanel;
    DNEM2PANEL: TPanel;
    DISPLAYTABLA: TIBTable;
    DISPLAYDBASE: TIBDatabase;
    DISPLAYTRANZ: TIBTransaction;
    DISPLAYTABLAIRODASZAM: TIntegerField;
    DISPLAYTABLAERTEKTAR: TIntegerField;
    DISPLAYTABLAVALUTANEM: TIBStringField;
    DISPLAYTABLANYITO: TFloatField;
    DISPLAYTABLAVETEL: TFloatField;
    DISPLAYTABLAELADAS: TFloatField;
    DISPLAYTABLAHIANY: TFloatField;
    DISPLAYTABLATOBBLET: TFloatField;
    DISPLAYTABLABANKIATVETEL: TFloatField;
    DISPLAYTABLABANKIATADAS: TFloatField;
    DISPLAYTABLAPENZTARIKIADAS: TFloatField;
    DISPLAYTABLAPENZTARIATVETEL: TFloatField;
    DISPLAYTABLAZARO: TFloatField;
    DISPLAYTABLASZAMITOTTZARO: TFloatField;
    DISPLAYTABLAVETELDARAB: TIntegerField;
    DISPLAYTABLAELADASDARAB: TIntegerField;
    DISPLAYTABLAIRODADNEM: TIBStringField;
    DISPLAYTABLAMEGJEGYZES: TIBStringField;
    DISPLAYTABLAVISSZAPLUSZ: TFloatField;
    DISPLAYTABLAVISSZAMINUSZ: TFloatField;
    DISPLAYQUERY: TIBQuery;
    Panel2: TPanel;
    Panel3: TPanel;
    Label1: TLabel;
    Label2: TLabel;

    procedure FormActivate(Sender: TObject);
    procedure DISPLAYQUITClick(Sender: TObject);
    procedure MNBRACSColEnter(Sender: TObject);
    procedure Ujvalutadisp;
    procedure MNBRACSDblClick(Sender: TObject);
    procedure MNBRACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MNBRACSDrawDataCell(Sender: TObject; const Rect: TRect;
      Field: TField; State: TGridDrawState);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MNBLISTADISPLAY: TMNBLISTADISPLAY;
  _sVetel,_sElad: integer;

implementation

{$R *.dfm}

// =============================================================================
           procedure TMNBLISTADISPLAY.FormActivate(Sender: TObject);
// =============================================================================

var _tigCaption : string;
begin
  Top := _top + 123;
  Left := _left + 143;
  Height := 524;
  Width := 744;

  DisplayDbase.Close;
  DisplayDbase.Connected := true;
  if displayTranz.InTransaction then DisplayTranz.Commit;

  with DisplayTabla do
    begin
      Open;
      Refresh;
      Filtered := False;
    end;

  Focimpanel.Caption := _displayFocim;
  _tigCaption := inttostr(_kertev)+' '+_honapnev[_kertho] + ' '+_tols+' ÉS '+ _IGS + ' KÖZÖTT';
  ToligPanel.Caption := _tigCaption;

  case _displaytipus of
    1: _szuro := '(IRODASZAM=0) AND (ERTEKTAR=0)';
    2: _szuro := '(IRODASZAM=0) AND (ERTEKTAR='+chr(39)+inttostr(_aktkorzet)+chr(39)+')';
    3: _szuro := 'IRODASZAM='+chr(39)+inttostr(_aktpenztar)+chr(39);
    4: _szuro := '(IRODASZAM=-1) AND (CEGBETU='+chr(39)+'B'+CHR(39)+')';
    5: _szuro := '(IRODASZAM=-1) AND (CEGBETU='+chr(39)+'P'+CHR(39)+')';
    6: _szuro := '(IRODASZAM=-1) AND (CEGBETU='+chr(39)+'E'+CHR(39)+')';
  end;

  DisplayTabla.Close;
  _pcs := 'SELECT SUM(VETELDARAB),SUM(ELADASDARAB) FROM MNB'+_sorveg;
  _pcs := _pcs + 'WHERE '+_szuro;
  with DisplayQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
    end;

  _sVetel := DisplayQuery.FieldByName('SUM').asInteger;
  _sElad := DisplayQuery.FieldByName('SUM1').asInteger;

  DisplayQuery.Close;
  Panel2.Caption := Form1.ForintForm(_sVetel);
  Panel3.Caption := Form1.FtForm(_selad);


  with DisplayTabla do
    begin
      Open;
      Filter := _szuro;
      Filtered := True;
      Refresh;
      First;
    end;
  UjvalutaDisp;
  ActiveControl := MNbRacs;

end;

// =============================================================================
        procedure TMNBLISTADISPLAY.DISPLAYQUITClick(Sender: TObject);
// =============================================================================

begin
  DisplayTabla.Close;
  ModalResult := 1;
end;


// =============================================================================
           procedure TMNBLISTADISPLAY.MNBRACSColEnter(Sender: TObject);
// =============================================================================

begin
  Ujvalutadisp;
end;

// =============================================================================
                procedure TMNBListaDisplay.UjvalutaDisp;
// =============================================================================

var _aktdnem: string;
begin
  _aktdnem := MNBracs.Fields[0].AsString;
  Dnem1Panel.Caption := _aktdnem;
  Dnem2Panel.Caption := _aktdnem;
end;

// =============================================================================
         procedure TMNBLISTADISPLAY.MNBRACSDblClick(Sender: TObject);
// =============================================================================

begin
  Ujvalutadisp;
end;

// =============================================================================
      procedure TMNBLISTADISPLAY.MNBRACSKeyUp(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  Ujvalutadisp;
end;

// =============================================================================
       procedure TMNBLISTADISPLAY.MNBRACSDrawDataCell(Sender: TObject;
                     const Rect: TRect; Field: TField; State: TGridDrawState);
// =============================================================================

begin
  Ujvalutadisp;
end;

end.
