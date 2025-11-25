unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons,DB,StrUtils;
  

type
  TROGZITESFORM = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    ROGZITSDGOMB: TBitBtn;
    NEROGZITSDGOMB: TBitBtn;
    procedure ROGZITSDGOMBEnter(Sender: TObject);
    procedure ROGZITSDGOMBExit(Sender: TObject);
    procedure NEROGZITSDGOMBClick(Sender: TObject);
    procedure ROGZITSDGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure RekordRogzites;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ROGZITESFORM: TROGZITESFORM;
  _KJELZO: TBookMark;

implementation

uses Unit1;

{$R *.dfm}

// =========================================================================
        procedure TROGZITESFORM.ROGZITSDGOMBEnter(Sender: TObject);
// =========================================================================

begin
  TBitBtn(Sender).font.Color := clBlue;
  TbitBtn(Sender).Font.Style := [fsBold];
end;

// =========================================================================
          procedure TROGZITESFORM.ROGZITSDGOMBExit(Sender: TObject);
// =========================================================================

begin
  TBitBtn(Sender).font.Color := clGray;
  TbitBtn(Sender).Font.Style := [];
end;

// =========================================================================
        procedure TROGZITESFORM.NEROGZITSDGOMBClick(Sender: TObject);
// =========================================================================

begin
  _rekordValtozas := False;
  ModalResult := 2;
end;

// =========================================================================
          procedure TROGZITESFORM.ROGZITSDGOMBClick(Sender: TObject);
// =========================================================================


begin
  RekordRogzites;
  _rekordValtozas := False;
  ModalResult := 1;
end;

// =========================================================================
          procedure TROGZITESFORM.FormActivate(Sender: TObject);
// =========================================================================

begin
   top := _top + 310;
   Left := _left + 290;
   ActiveControl := NerogzitsdGomb;
end;

// =========================================================
          procedure TRogzitesForm.RekordRogzites;
// =========================================================

var i,_integer,_code: integer;
    _float: real;
   

begin

  _kjelzo := Form1.Ibtabla.Getbookmark;
  Form1.IBTabla.Close;

  Form1.IBDBASE.close;
  Form1.IBDbase.Connected := True;
  if Form1.IBTranz.InTransaction then Form1.IBTRANZ.Commit;
  Form1.IBTranz.StartTransaction;
  with Form1.IBTabla do
    begin
      ReadOnly := false;
      Open;
      GotoBookMark(_kjelzo);
      Edit;
    end;

  for i := 1 to _mezodarab do
    begin
      _aktmezonev := _mezonev[i];
      _aktdata := _mezoData[i];
      _aktMezoTip := _mezotipus[i];
      _aktMezoHossz := _mezoHossz[i];

      if _aktmezoTip='SZÖVEG' then
        begin
          if length(_aktdata)>_aktMezohossz then _aktData := leftstr(_aktdata,_aktMezoHossz);
          _mezoData[i] := _aktdata;
          Form1.IbTabla.FieldByName(_aktmezoNev).asString := _aktdata;
        end;

      if (_aktMezoTip='EGÉSZ SZÁM') or (_aktMezoTip='KIS EGÉSZ SZÁM') then
        begin
          val(_aktdata,_integer,_code);
          if _code<>0 then _integer := 0;
          _mezodata[i] := inttostr(_integer);
          Form1.IbTabla.FieldByName(_aktmezonev).AsInteger := _integer;
        end;

      if _aktMezoTip='TIZEDES TÖRT' then
        begin
          val(_aktdata,_float,_code);
          if _code<>0 then _float := 0;
          _mezodata[i] := floattostr(_float);
          Form1.Ibtabla.FieldByName(_aktmezonev).asFloat := _float;
        end;
    end;
  Form1.IBtabla.Post;
  Form1.IBtabla.Close;
  Form1.IBTRANZ.Commit;

  with Form1.IBTABLA do
    begin
      ReadOnly := True;
      Open;
      GotoBookMark(_kjelzo);
      FreeBookMark(_kjelzo)
    end;

end;
end.
