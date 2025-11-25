unit Unit35;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Grids, DBGrids, StdCtrls, DB, IBDatabase, StrUtils,
  IBCustomDataSet, IBQuery, Buttons, ComCtrls, IBTable, unit1, DBCtrls;

type
  TKEDVEZMENYLISTA = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    KORZETPANEL: TPanel;
    Panel4: TPanel;
    IDOSZAKPANEL: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel10: TPanel;
    VETELPANEL: TPanel;
    ELADPANEL: TPanel;
    SKEDVPANEL: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    ETARPANEL: TPanel;
    FOERTPANEL: TPanel;
    UGYVEZPANEL: TPanel;
    SAVOSPANEL: TPanel;
    UGYFCARDPANEL: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    KEDVEZRACS: TDBGrid;
    BitBtn1: TBitBtn;
    KEDVEZDBASE: TIBDatabase;
    KEDVEZTRANZ: TIBTransaction;
    kedvezsource: TDataSource;
    KEDVEZTABLA: TIBTable;
    Bevel1: TBevel;
    Bevel2: TBevel;
    KILEPOTIMER: TTimer;
    KEDVEZTABLAIRODA: TSmallintField;
    KEDVEZTABLAERTEKTAR: TSmallintField;
    KEDVEZTABLADATUM: TIBStringField;
    KEDVEZTABLAVALUTANEM: TIBStringField;
    KEDVEZTABLAARFOLYAM: TFloatField;
    KEDVEZTABLAUJARFOLYAM: TFloatField;
    KEDVEZTABLAPENZTAROSNEV: TIBStringField;
    KEDVEZTABLABIZONYLATSZAM: TIBStringField;
    KEDVEZTABLABANKJEGY: TFloatField;
    KEDVEZTABLARATETYPE: TSmallintField;
    KEDVEZTABLAENGEDMENY: TFloatField;
    engokpanel: TPanel;
    Label3: TLabel;
    DBText1: TDBText;
    KEDVEZTABLAENGEDMENYOK: TIBStringField;
    Shape1: TShape;
    Panel3: TPanel;
    PENZTAROSPANEL: TPanel;
    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure KILEPOTIMERTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KEDVEZMENYLISTA: TKEDVEZMENYLISTA;
  _sugyfel,_ssavos,_sfoertek,_sertek,_svetel,_seladas,_spenztaros: integer;
  _bizonylat: string;
  _ratetype,_engedmeny: integer;

implementation

{$R *.dfm}

procedure TKEDVEZMENYLISTA.FormActivate(Sender: TObject);
begin
    Top := _top+120;
  Left := _left+140;
  Height := 530;
  Width := 750;

  KedvezSource.Enabled := false;
  KorzetPanel.Caption := _displayFocim;
  IdoszakPanel.Caption := _tolstring+' - '+_igstring;

  case _displaytipus of
    1: _szuro := '';
    2: _szuro := 'ERTEKTAR='+inttostr(_aktkorzet);
    3: _szuro := 'IRODA='+inttostr(_aktpenztar);
    4: _szuro := 'CEGBETU='+chr(39)+ _cegbetuk[_cbSors] +CHR(39);
  end;

  Kedvezdbase.Close;
  Kedvezdbase.Connected := true;
  if KedvezTranz.InTransaction then Kedveztranz.Commit;
  KedvezTabla.Open;
  if _szuro<>'' then
    begin
      KedvezTabla.Filter := _szuro;
      Kedveztabla.Filtered := True;
    end else
    begin
      Kedveztabla.Filtered := false;
      Kedveztabla.Filter := '';
    end;

  KedvezTabla.First;

  _sugyfel := 0;
  _ssavos := 0;
  _sPenztaros := 0;
  _sfoertek := 0;
  _sertek := 0;
  _sVetel := 0;
  _sEladas := 0;

  while not KedvezTabla.eof do
    begin
      with KedvezTabla do
        begin
          _bizonylat := FieldByName('BIZONYLATSZAM').asstring;
          _ratetype := FieldByname('RATETYPE').asInteger;
          _engedmeny := FieldByName('ENGEDMENY').AsInteger;
        end;

      _tipus := leftstr(_bizonylat,1);
      if _tipus='V' then _svetel := _svetel + _engedmeny
      else _seladas := _sEladas + _engedmeny;

      case _ratetype of
        10: _sugyfel := _sUgyfel + _engedmeny;
        12: _spenztaros := _sPenztaros + _engedmeny;
        20: _ssavos := _ssavos + _engedmeny;
        31: _sugyfel := _sugyfel + _engedmeny;
        32: _sfoertek := _sfoertek + _engedmeny;
        33: _sertek := _sertek + _engedmeny;
        34: _sugyfel := _sugyfel + _engedmeny;
      end;
      KedvezTabla.next;
    end;

  VetelPanel.Caption := Form1.ForintForm(_sVetel)+' Ft';
  EladPanel.Caption := Form1.ForintForm(_sEladas)+' Ft';
  skedvPanel.Caption := Form1.ForintForm(_sVetel+_sEladas)+' Ft';
  UgyfCardpanel.Caption := Form1.ForintForm(_sUgyfel)+' Ft';
  Penztarospanel.Caption := Form1.ForintForm(_sPenztaros)+' Ft';

  SavosPanel.Caption := Form1.ForintForm(_ssavos)+' Ft';
  Ugyvezpanel.Caption := Form1.ForintForm(_sugyfel)+' Ft';
  Foertpanel.Caption := Form1.ForintForm(_sfoertek)+' Ft';
  EtarPanel.Caption := Form1.ForintForm(_sertek)+' Ft';

  KedvezTabla.First;
  Kedvezsource.Enabled := true;
  ActiveControl := Kedvezracs;
end;

procedure TKEDVEZMENYLISTA.BitBtn1Click(Sender: TObject);
begin
  KilepoTimer.Enabled := True;
end;

procedure TKEDVEZMENYLISTA.KILEPOTIMERTimer(Sender: TObject);
begin
  KilepoTimer.Enabled := False;
  KedvezTabla.Close;
  ModalResult := 1;
end;

end.
