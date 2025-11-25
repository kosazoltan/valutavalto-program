unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, strutils, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TForm2 = class(TForm)
    CIMLETEZOPANEL: TPanel;
    Label1: TLabel;
    E1: TEdit;
    E2: TEdit;
    E3: TEdit;
    E4: TEdit;
    E5: TEdit;
    E6: TEdit;
    E7: TEdit;
    P1: TPanel;
    P2: TPanel;
    P3: TPanel;
    P4: TPanel;
    P5: TPanel;
    P6: TPanel;
    P7: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    KESZLETPANEL: TPanel;
    CIMLETPANEL: TPanel;
    CIMOKEGOMB: TBitBtn;
    CIMMEGSEMGOMB: TBitBtn;
    Shape1: TShape;
    HRKQUERY: TIBQuery;
    HRKDBASE: TIBDatabase;
    HRKTRANZ: TIBTransaction;
    KILEPO: TTimer;

    procedure FormActivate(Sender: TObject);
    procedure Vegigszamol;
    procedure E1Enter(Sender: TObject);
    procedure E1Exit(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure TombBetoltes;
    procedure CimOkeGombClick(Sender: TObject);
    procedure CimMegsemGombClick(Sender: TObject);
    procedure E1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    function Ftform(_n: integer): string;
    function GetHaziZaro: integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _aktedit: TEdit;
  _aktbjs : string;

  _cimlet : array[1..7] of word = (1000,500,200,100,50,20,10);
  _cert   : array[1..7] of integer;
  _edit   : array[1..7] of TEdit;
  _panel  : array[1..7] of TPanel;

  _hazizaro,_aktbj,_aktcert,_code,_sumcert,_mResult: integer;
  _y,_top,_left,_height,_width: word;
  _tag,_bill: byte;


function kunacimletezes: integer; stdcall;

implementation

{$R *.dfm}

function kunacimletezes: integer; stdcall;
begin
  Form2 := TForm2.Create(Nil);
  result := Form2.ShowModal;
  form2.Free;
end;  

// =============================================================================
                 procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;


  _top := round((_height-415)/2);
  _left:= round((_width-423)/2);

  Top := _top;
  Left:= _left;
  repaint;

  _hazizaro := getHaziZaro;
  if _haziZaro=0 then
    begin
      _mResult := 2;
      Kilepo.enabled := true;
      exit;
    end;

  TombBetoltes;  
  _y := 1;
  while _y<=7 do
    begin
      _edit[_y].Text := '';
      _panel[_y].Caption := '0';
      _cert[_y] := 0;
      inc(_y);
    end;

  CimletPanel.Caption := '0';
  KeszletPanel.caption := Ftform(_haziZaro);
  with CimletezoPanel do
    begin
      top := 0;
      left :=0;
      Visible := true;
      BringtoFront;
      Repaint;
    end;
  Activecontrol := E1;
end;

// =============================================================================
                  function TForm2.GetHaziZaro: integer;
// =============================================================================

begin
  Hrkdbase.connected := True;
  with HrkQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HRKDATA');
      Open;
      result := FieldByNAme('AKTKESZLET').asInteger;
      Close;
    end;
  Hrkdbase.close;
end;


// =============================================================================
             function TForm2.Ftform(_n: integer): string;
// =============================================================================

var _f1,_wlen: byte;

begin
  result := inttostr(_n);
  _wlen := length(result);
  if _wlen<4 then exit;

  if _wlen>6 then
    begin
      _f1 := _wlen-6;
      result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3)+' '+midstr(result,_f1+4,3);
      exit;
    end;
  _f1 := _wlen-3;
  result := leftstr(result,_f1)+' '+midstr(result,_f1+1,3);
end;

// =============================================================================
        procedure TForm2.E1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  _tag := Tedit(Sender).Tag;
  _bill := ord(key);
  if _bill=40 then
    begin
      Vegigszamol;
      if _tag<7 then inc(_tag) else _tag := 1;
      _aktedit := _edit[_tag];
      Activecontrol := _aktEdit;
      exit;
    end;

  if _bill=38 then
    begin
      Vegigszamol;
      if _tag>1 then dec(_tag) else _tag := 7;
      _aktedit := _edit[_tag];
      Activecontrol := _aktEdit;
      exit;
    end;

  if ord(key)<>13 then exit;

  VegigSzamol;

  inc(_tag);
  if _tag>7 then _tag := 1;
  _aktedit := _edit[_tag];
  Activecontrol := _aktedit;
end;

// =============================================================================
                   procedure TForm2.Vegigszamol;
// =============================================================================

begin
 _aktedit  := _edit[_tag];
  _aktbjs  := trim(_aktedit.Text);
  val(_aktbjs,_aktbj,_code);

  _aktcert := trunc(_aktbj*_cimlet[_tag]);
  _panel[_tag].Caption := FtForm(_aktcert);

  _cert[_tag] := _aktcert;
  _sumcert := 0;

  _y := 1;
  while _y<=7 do
    begin
      _sumcert := _sumcert + _cert[_y];
      inc(_y);
    end;

  Cimletpanel.Caption := ftform(_sumcert);

  if _sumcert = _haziZaro then
    begin
      Cimletpanel.Font.Color := clRed;
      Keszletpanel.Font.Color := clRed;
      CimOkeGomb.Enabled := True;
    end else
    begin
      Cimletpanel.Font.Color := clBlack;
      Keszletpanel.Font.Color := clBlack;
      CimOkeGomb.Enabled := False;
    end;
end;


// =============================================================================
               procedure TForm2.E1Enter(Sender: TObject);
// =============================================================================

begin
  Tedit(Sender).Color := clYellow;
end;

// =============================================================================
                procedure TForm2.E1Exit(Sender: TObject);
// =============================================================================

begin
  tEdit(sender).Color := clWhite;
end;

// =============================================================================
                    procedure TForm2.TombBetoltes;
// =============================================================================

begin
  _edit[1] := E1;
  _edit[2] := E2;
  _edit[3] := E3;
  _edit[4] := E4;
  _edit[5] := E5;
  _edit[6] := E6;
  _edit[7] := E7;

  _panel[1] := P1;
  _panel[2] := P2;
  _panel[3] := P3;
  _panel[4] := P4;
  _panel[5] := P5;
  _panel[6] := P6;
  _panel[7] := P7;
end;

// =============================================================================
            procedure TForm2.CIMOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := 1;
  Kilepo.Enabled := true;
end;

// =============================================================================
           procedure TForm2.CIMMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := -1;
  Kilepo.Enabled := true;
end;

// =============================================================================
                procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;


end.
