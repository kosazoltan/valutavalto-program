unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, DBGrids, DB, IBDatabase, IBTable,
  IBCustomDataSet, IBQuery, ExtCtrls, UNIT1;

type
  TEREDMENYFORM = class(TForm)
    VISSZAGOMB: TBitBtn;
    EREDMENYQUERY: TIBQuery;
    EREDMENYTABLA: TIBTable;
    EREDMENYDBASE: TIBDatabase;
    EREDMENYTRANZ: TIBTransaction;
    EREDMENYSOURCE: TDataSource;
    EREDMENYRACS: TDBGrid;
    infopanel: TPanel;
    FELLABGOMB: TBitBtn;
    OSSZESGOMB: TBitBtn;
    Shape1: TShape;
    FOCIMPANEL: TPanel;
    EREDMENYTABLAKULDO: TSmallintField;
    EREDMENYTABLAFOGADO: TSmallintField;
    EREDMENYTABLAVALUTANEM: TIBStringField;
    EREDMENYTABLAKULDOTTBANKJEGY: TIntegerField;
    EREDMENYTABLAFOGADOTTBANKJEGY: TIntegerField;
    EREDMENYTABLADIFFRENT: TIntegerField;
    EREDMENYTABLADATUM: TIBStringField;
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure EREDMENYRACSCellClick(Column: TColumn);
    procedure EREDMENYRACSDblClick(Sender: TObject);
    procedure FELLABGOMBClick(Sender: TObject);
    procedure OSSZESGOMBClick(Sender: TObject);
    procedure EREDMENYRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EREDMENYFORM: TEREDMENYFORM;
  _etop,_eleft: word;

implementation

uses Unit3;

{$R *.dfm}

procedure TEREDMENYFORM.VISSZAGOMBClick(Sender: TObject);
begin
  EredmenyDbase.close;
  EredmenyTabla.Close;
  Modalresult := 1;
end;

procedure TEREDMENYFORM.FormActivate(Sender: TObject);
begin
  _etop := trunc((_height-640)/2);
  _eleft:= trunc((_width-870)/2);
  Top := _eTop;
  Left := _eLeft;

  FellabGombClick(Nil);
end;

procedure TEREDMENYFORM.EREDMENYRACSCellClick(Column: TColumn);



begin
  _kuldo := EredmenyTabla.fieldbyname('KULDO').asInteger;
  _fogado := EredmenyTabla.Fieldbyname('FOGADO').asInteger;
  _valutanem := EredmenyTabla.fieldbyname('VALUTANEM').asString;

  BemutatO.SHOWMODAL;
end;

procedure TEREDMENYFORM.EREDMENYRACSDblClick(Sender: TObject);
begin
   _kuldo := EredmenyTabla.fieldbyname('KULDO').asInteger;
  _fogado := EredmenyTabla.Fieldbyname('FOGADO').asInteger;
  _valutanem := EredmenyTabla.fieldbyname('VALUTANEM').asString;

  BemutatO.SHOWMODAL;
end;

procedure TEREDMENYFORM.FELLABGOMBClick(Sender: TObject);
begin
  FellabGomb.Enabled := False;

  FocimPanel.Caption := 'FÉLLÁBAS TRANZAKCIÓK KIMUTATÁSA';
  FocimPanel.Repaint;

  EredmenyDbase.close;
  Eredmenytabla.close;
  EredmenyTabla.Filtered := false;
  EredmenyTabla.Filter := 'DIFFRENT<>0';
  EredmenyTabla.Filtered := True;
  EredmenyDbase.Connected := True;
  EredmenyTabla.Open;

  Osszesgomb.Enabled := True;

  EredmenyTabla.First;
  Eredmenyracs.SetFocus;
end;

procedure TEREDMENYFORM.OSSZESGOMBClick(Sender: TObject);
begin
  OsszesGomb.Enabled := False;

  FocimPanel.Caption := 'AZ ÖSSZES TRANZAKCIÓ KIJELZÉSE';
  FocimPanel.Repaint;

  EredmenyDbase.close;
  Eredmenytabla.close;
  EredmenyTabla.Filtered := false;
  EredmenyDbase.Connected := True;
  EredmenyTabla.Open;

  FellabGomb.Enabled := True;

  EredmenyTabla.First;
  Eredmenyracs.SetFocus;
end;

procedure TEREDMENYFORM.EREDMENYRACSKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  _kuldo := EredmenyTabla.fieldbyname('KULDO').asInteger;
  _fogado := EredmenyTabla.Fieldbyname('FOGADO').asInteger;
  _valutanem := EredmenyTabla.fieldbyname('VALUTANEM').asString;

  BemutatO.SHOWMODAL;

end;

end.
