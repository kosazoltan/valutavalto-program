unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, IBDatabase, IBCustomDataSet, IBQuery, Grids,
  DBGrids, ExtCtrls, Buttons, IBTable;

type
  TForm2 = class(TForm)
    Panel1: TPanel;
    Label1: TLabel;
    NATURPANEL: TPanel;
    NATURGOMB: TBitBtn;
    JOGIGOMB: TBitBtn;
    Shape1: TShape;
    NATURRACS: TDBGrid;
    Label2: TLabel;
    NATURQUERY: TIBQuery;
    NATURDBASE: TIBDatabase;
    NATURTRANZ: TIBTransaction;
    NATURFORRAS: TDataSource;
    DELETEGOMB: TBitBtn;
    RETURNGOMB: TBitBtn;
    JOGIPANEL: TPanel;
    JOGIRACS: TDBGrid;
    Label3: TLabel;
    JOGIQUERY: TIBQuery;
    JOGIDBASE: TIBDatabase;
    JOGITRANZ: TIBTransaction;
    JOGIFORRAS: TDataSource;
    JOGITORLOGOMB: TBitBtn;
    backgomb: TBitBtn;
    JOGITABLA: TIBTable;
    NATURTABLA: TIBTable;
    Shape2: TShape;

    procedure NATURGOMBClick(Sender: TObject);
    procedure JOGIGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure RETURNGOMBClick(Sender: TObject);
    procedure JOGITORLOGOMBClick(Sender: TObject);
    procedure DELETEGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _pcs: string;
  _width,_left,_height,_top: word;

function ugyfeltmkrutin: integer; stdcall;

implementation

{$R *.dfm}

function ugyfeltmkrutin: integer; stdcall;
begin
  Form2 := Tform2.create(Nil);
  result := Form2.showmodal;
  Form2.Free;
end;



procedure TForm2.FormActivate(Sender: TObject);
begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top := _top;
  Left := _left;
  
  NaturgombClick(Nil);
end;


procedure TForm2.NATURGOMBClick(Sender: TObject);
begin

  NaturGomb.Enabled := false;
  JogiGomb.Enabled := true;

  if Jogitranz.InTransaction then Jogitranz.commit;
  JogiTabla.close;
  JogiDbase.close;

  JogiPanel.Visible := false;

  NaturDbase.Connected := true;
  if NaturTranz.InTransaction then Naturtranz.Commit;
  NaturTranz.StartTransaction;
  Naturtabla.Open;

  with NaturPanel do
    begin
      Top := 136;
      left := 8;
      Visible := true;
      Repaint;
    end;
  Activecontrol := NaturRacs;
end;

procedure TForm2.JOGIGOMBClick(Sender: TObject);
begin

   JogiGomb.Enabled := false;
   Naturgomb.Enabled := true;

   if NaturTranz.InTransaction then Naturtranz.Commit;
   NaturTabla.close;
   Naturdbase.close;

   Jogidbase.Connected := true;
   if Jogitranz.InTransaction then Jogitranz.commit;
   Jogitranz.StartTransaction;
   Jogitabla.open;

   with JogiPanel do
    begin
      Top := 136;
      left := 8;
      Visible := true;
      Repaint;
    end;
  Activecontrol := JogiRacs;
end;


procedure TForm2.RETURNGOMBClick(Sender: TObject);
begin
   NaturTabla.close;
   Naturdbase.close;

   JogiTabla.close;
   JogiDbase.close;

   ModalResult := 1;
end;

procedure TForm2.JOGITORLOGOMBClick(Sender: TObject);
begin
  Jogitabla.Delete;
end;

procedure TForm2.DELETEGOMBClick(Sender: TObject);
begin
  Naturtabla.delete;
end;

end.
