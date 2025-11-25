unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, Grids, DBGrids, IBDatabase, IBCustomDataSet,
  IBQuery, ExtCtrls, Buttons, strutils;

type
  TForm2 = class(TForm)
    EQUERY: TIBQuery;
    EDBASE: TIBDatabase;
    ETRANZ: TIBTransaction;
    ESOURCE: TDataSource;
    RACSPANEL: TPanel;
    TEAORRACS: TDBGrid;
    Label1: TLabel;
    BitBtn1: TBitBtn;
    Label2: TLabel;
    KERESOEDIT: TEdit;
    Shape1: TShape;


   
    procedure FormActivate(Sender: TObject);
    procedure TEAORRACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BitBtn1Click(Sender: TObject);
    procedure TEAORRACSDblClick(Sender: TObject);
    function Betuvalto(_be: byte): byte;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _keres,_ujkeres,_tipus,_aktTeaors: string;
  _bill,_wk: byte;
  _oke: boolean;
  _code,_mResult: integer;
  _height,_width,_top,_left: word;


function teaorvalasztas: integer; stdcall;

implementation

{$R *.dfm}

function teaorvalasztas: integer; stdcall;

begin
  form2 := TForm2.Create(Nil);
  result := form2.showmodal;
  form2.free;
end;  


procedure TForm2.FormActivate(Sender: TObject);
begin
  _height := Screen.Monitors[0].Height;
  _width := Screen.Monitors[0].width;

  _top := round((_height-345)/2);
  _left := round((_width-505)/2);

  Top := _top;
  Left:= _left;

  _keres := '';
  eDbase.Connected := true;
  with eQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM TEAORTABLA ORDER BY TEAOR');
      Open;
    end;
  Activecontrol := Teaorracs;
end;

procedure TForm2.TEAORRACSKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

begin
  _bill := ord(key);
  if (_bill>96) and (_bill<123) then _bill := _bill-32;
  if _bill>190 then _bill := betuvalto(_bill);
  if (_bill>47) and (_bill<58) and (_keres='') then
    begin
      with eQuery do
        begin
          Close;
          Sql.clear;
          sql.Add('SELECT * FROM TEAORTABLA ORDER BY TEAOR');
          Open;
        end;
      _tipus := 'NUM';
      _keres := chr(_bill);
      KeresoEdit.Text := _keres;
      eQuery.Locate('TEAOR',_keres,[loPartialkey,loCaseInsensitive]);
      Activecontrol := Teaorracs;
      exit;
    end;

  if (_bill>64) and (_keres='') then
    begin
      with eQuery do
        begin
          Close;
          Sql.clear;
          sql.Add('SELECT * FROM TEAORTABLA ORDER BY TEAORNEV');
          Open;
        end;
      _TIPUS := 'NEV';
      _keres := chr(_bill);
      Keresoedit.Text := _keres;
      eQuery.Locate('TEAORNEV',_keres,[loPartialkey,loCaseInsensitive]);
      Activecontrol := Teaorracs;
      exit;
    end;

  if (_bill>64) AND (_tipus='NEV') then
    begin
      _ujkeres := _keres + chr(_bill);
      _oke := eQuery.Locate('TEAORNEV',_ujkeres,[loPartialkey,loCaseInsensitive]);
      if _oke then
        begin
          _keres := _ujkeres;
          KeresoEdit.Text := _keres;
          Activecontrol := Teaorracs;
          exit;
        end;
    end;

  if (_bill>47) and (_bill<58) AND (_tipus='NUM') then
    begin
      _ujkeres := _keres + chr(_bill);
      _oke := eQuery.Locate('TEAOR',_ujkeres,[loPartialkey,loCaseInsensitive]);
      if _oke then
        begin
          _keres := _ujkeres;
          KeresoEdit.Text := _keres;
          Activecontrol := Teaorracs;
          exit;
        end;
    end;

  if (_bill>36) and (_bill<41) then
    begin
      _keres := '';
      KeresoEdit.text := '';
      ActiveControl := TeaorRacs;
      exit;
    end;

  if (_bill=8) and (_keres<>'') then
    begin
      _wk := length(_keres);
      if _wk=1 then
        begin
          _keres := '';
          KeresoEdit.text := '';
          TeaorRacs.setfocus;
          exit;
        end;
      _keres := leftstr(_keres,_wk-1);
      Keresoedit.text := _keres;
      eQuery.Locate('TEAORNEV',_keres,[loPartialkey,loCaseInsensitive]);
      TeaorRacs.setfocus;
      exit;
    end;

  if _bill=13 then
    begin
      _aktteaors := trim(eQuery.FieldByNAme('TEAOR').asString);
      val(_aktTeaors,_mResult,_code);
      if _code<>0 then _mResult := -1;
      eQuery.close;
      edbase.close;
      Modalresult := _mResult;
      exit;
    end;
end;

procedure TForm2.BitBtn1Click(Sender: TObject);
begin
  eQuery.close;
  eDbase.close;
  Modalresult := -1;
end;

procedure TForm2.TEAORRACSDblClick(Sender: TObject);
begin
  _aktteaors := trim(eQuery.FieldByNAme('TEAOR').asString);
  val(_aktTeaors,_mResult,_code);
  if _code<>0 then _mResult := -1;
  eQuery.close;
  edbase.close;
  Modalresult := _mResult;
end;


function TForm2.Betuvalto(_be: byte): byte;

begin
  result := _be;
  case _be of
    222: result := 160;
    186: result := 130;
    192: result := 148;
    219: result := 148;
    221: result := 163;
    191: result := 147;
    220: result := 147;
    226: result := 161;
  end;
end;
end.
