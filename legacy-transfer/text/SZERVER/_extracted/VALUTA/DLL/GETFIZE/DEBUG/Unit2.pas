unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, Grids, DBGrids;

type
  TGETFIZETOESZKOZ = class(TForm)
    Label4: TLabel;
    KPGOMB: TBitBtn;
    BKGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    Shape3: TShape;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    noprosbennpanel: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    BELEPGOMB: TBitBtn;
    NEMLEPBEGOMB: TBitBtn;


    procedure FormActivate(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);


    procedure BKGOMBClick(Sender: TObject);
    procedure KPGOMBClick(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure BELEPGOMBClick(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETFIZETOESZKOZ: TGETFIZETOESZKOZ;
  _TOP,_height,_left,_width: word;
  _posterm,_prosbenn,_otpoke: integer;
  _pcs : string;


function otpterminal: integer; stdcall; external 'c:\valuta\bin\otp.dll' name 'otpterminal';
function fizetoeszkozrutin: integer; stdcall;


implementation

{$R *.dfm}


function fizetoeszkozrutin: integer; stdcall;

begin
  Getfizetoeszkoz := TGetfizetoeszkoz.create(Nil);
  result := getfizetoeszkoz.ShowModal;
  Getfizetoeszkoz.free;
end;


// =============================================================================
            procedure TGETFIZETOESZKOZ.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  top := _top+250;
  Left := _left + 160;

  valutadbase.Connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _posterm := FieldByName('POSTTERM').asInteger;
      _prosbenn := FieldByName('OTPOPEN').asInteger;
      Close;
    end;

  Valutadbase.close;

  if _posterm=0 then Bkgomb.Enabled := False else BKgomb.Enabled := True;

  Activecontrol := KpGomb;
end;



procedure TGETFIZETOESZKOZ.BKGOMBClick(Sender: TObject);
begin
  if _prosbenn=1 then
    begin
      Modalresult := 2;
      exit;
    end;

  with noprosbennPanel do
    begin
      top := 5;
      left:= 5;
      Visible := true;
      repaint;
    end ;
  Activecontrol := BelepGomb;
end;


procedure TGETFIZETOESZKOZ.KPGOMBClick(Sender: TObject);
begin
  Modalresult := 1;
end;

procedure TGETFIZETOESZKOZ.MEGSEMGOMBClick(Sender: TObject);
begin
  Modalresult := -1;
end;

procedure TGETFIZETOESZKOZ.BELEPGOMBClick(Sender: TObject);
begin
  _pcs := 'UPDATE VTEMP SET OTPFUNCTYPE=50';
  ValutaParancs(_pcs);
  NoProsbennPanel.Visible := False;

  _otpOke := otpterminal;
  if _otpOke=1 then
    begin
      _pcs := 'UPDATE HARDWARE SET OTPOPEN=1';
      ValutaParancs(_pcs);
      Modalresult := 2;
      exit;
    end;
  Bkgomb.Enabled := False;
end;



procedure TGetFizetoEszkoz.ValutaParancs(_ukaz: string);

begin
  Valutadbase.Connected := True;
  if valutaTranz.InTransaction then valutaTranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_ukaz);
      Execsql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;

end.
