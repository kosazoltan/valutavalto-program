unit Unit32;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, IBCustomDataSet, IBDatabase, IBTable,
  Grids, DBGrids, ExtCtrls, unit1;

type
  TJUTALEKSZAZALEK = class(TForm)
    Panel1: TPanel;
    jutalekracs: TDBGrid;
    JUTALEKTABLA: TIBTable;
    JUTALEKDBASE: TIBDatabase;
    JUTALEKTRANZ: TIBTransaction;
    JUTALEKSOURCE: TDataSource;
    Label1: TLabel;
    JUTALEKTABLAPENZTAR: TIntegerField;
    JUTALEKTABLASZAZALEK: TFloatField;
    JUTALEKTABLAIRODANEV: TIBStringField;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    Shape3: TShape;
    procedure FormActivate(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure jutalekracsKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure jutalekracsEnter(Sender: TObject);
    procedure jutalekracsExit(Sender: TObject);
    procedure BitBtn1Enter(Sender: TObject);
    procedure BitBtn1Exit(Sender: TObject);
    procedure BitBtn1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure jutalekracsMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  JUTALEKSZAZALEK: TJUTALEKSZAZALEK;
  _qq : integer;
  _aktptnev: string;

implementation

{$R *.dfm}

procedure TJUTALEKSZAZALEK.FormActivate(Sender: TObject);
begin
  Top := 220;
  Left := 190; 

  JutalekSource.Enabled := False;
  Jutalekdbase.Close;
  JutalekDbase.Connected := True;
  if jutalekTranz.InTransaction then JutalekTranz.Commit;
  JutalekTranz.StartTransaction;

  JutalekTabla.IndexFieldNames := 'PENZTAR';
  JutalekTabla.Open;
  JutalekTabla.First;

  _qq := 0;
  while _qq<_irodaDarab do
    begin
      _aktPt := _irodaszam[_qq];
      _aktptnev := _irodanev[_aktpt];
      _megvan := Jutalektabla.Locate('PENZTAR',_aktpt,[]);

      if not _Megvan then
        begin
          with JutalekTabla do
            begin
              Append;
              edit;
              FieldByName('PENZTAR').asInteger := _aktpt;
              FieldByName('IRODANEV').asstring := _aktptnev;
              Post;
            end;
        end;
      inc(_qq);
    end;
  JutalekTranz.Commit;

  JutalekDbase.Connected := True;
  if jutalekTranz.InTransaction then JutalekTranz.Commit;
  JutalekTranz.StartTransaction;

  JutalekTabla.Open;
  JutalekTabla.First;
  JutalekSource.Enabled := True;
  Jutalekracs.SelectedIndex := 2;
  Activecontrol := Jutalekracs;
end;

procedure TJUTALEKSZAZALEK.BitBtn2Click(Sender: TObject);
begin
  ModalResult := 1;
end;

procedure TJUTALEKSZAZALEK.jutalekracsKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);

var _bill,_oszlop: integer;
  
begin
  _bill := ord(key);
  _oszlop := Jutalekracs.selectedIndex;
  if _oszlop<2 then
    begin
      Jutalekracs.selectedindex := 2;
      Exit;
    end;
  if _bill=13 then
    begin
      JutalekTabla.next;
      Exit;
    end;    
end;

procedure TJUTALEKSZAZALEK.jutalekracsEnter(Sender: TObject);
begin
  Jutalekracs.Color := $d0ffff;
end;

procedure TJUTALEKSZAZALEK.jutalekracsExit(Sender: TObject);
begin
  Jutalekracs.Color := clWIndow;
end;

procedure TJUTALEKSZAZALEK.BitBtn1Enter(Sender: TObject);
begin
  with TBitbtn(sender).Font do
    begin
      color := clNavy;
      Style := [fsBold,fsItalic];
    end;
end;

procedure TJUTALEKSZAZALEK.BitBtn1Exit(Sender: TObject);
begin
   with TBitbtn(sender).Font do
    begin
      color := clGray;
      Style := [];
    end;
end;

procedure TJUTALEKSZAZALEK.BitBtn1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := TBitbtn(Sender);
end;

procedure TJUTALEKSZAZALEK.jutalekracsMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := Jutalekracs;
end;

end.
