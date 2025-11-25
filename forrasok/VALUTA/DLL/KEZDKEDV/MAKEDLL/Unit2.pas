unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, strutils, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TForm2 = class(TForm)
    ALAPLAP: TPanel;
    FELEZOPANEL: TPanel;
    ELENGEDOPANEL: TPanel;
    EXTRAPANEL: TPanel;
    PERMDEL: TPanel;
    CARDDEL: TPanel;
    PERMHALF: TPanel;
    ACTHALF: TPanel;
    CARDHALF: TPanel;
    EGYEDI: TPanel;
    ANYTAX: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Panel2: TPanel;
    INFOPANEL: TPanel;
    CARDPANEL: TPanel;
    Label9: TLabel;
    CARDNUMEDIT: TEdit;
    Shape1: TShape;
    MEGSEMGOMB: TBitBtn;
    FORINTPANEL: TPanel;
    RENDBENGOMB: TBitBtn;
    TEXTPANEL: TPanel;
    GETKDPANEL: TPanel;
    Label10: TLabel;
    KEZDIJEDIT: TEdit;
    Label11: TLabel;
    TAKARO: TPanel;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    KILEPO: TTimer;

    procedure Button1Click(Sender: TObject);
    procedure AlapAdatBeolvasas;
    procedure PerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ClearAll;
    procedure TakaroFel;
    procedure Finish;
    procedure FormActivate(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure ALAPLAPMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PERMHALFClick(Sender: TObject);

    function FtForm(_ft: integer): string;
    procedure Label5Click(Sender: TObject);
    procedure CARDNUMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PERMDELClick(Sender: TObject);
    procedure Label7Click(Sender: TObject);
    procedure KEZDIJEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure RENDBENGOMBClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
    procedure KILEPOTimer(Sender: TObject);
    function kerekito(_int: integer): integer;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _aktPanel,_tempPanel: TPanel;
  _gomb: array[1..7] of TPanel;
  _mess: array[1..7] of string;
  _tag: byte;
  _kezdij: word;
  _cardnum,_pcs: string;
  _top,_left,_width,_height: word;

  _origkezdij,_spk,_code,_minkezdij,_kezdijmax,_netto,_realezrelek: integer;
  _napikezdij: byte;

function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll'
function kezdijkedvezmeny: integer; stdcall;


implementation

{$R *.dfm}


function kezdijkedvezmeny: integer; stdcall;
begin
   Form2 := TForm2.Create(Nil);
   result := Form2.showmodal;
   Form2.free;
end;


procedure TForm2.FormActivate(Sender: TObject);
begin

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-381)/2);
  _left := round((_width-681)/2);

  Top      := _top;
  Left     := _left;

  _gomb[1] := PermHalf;
  _gomb[2] := ActHalf;
  _gomb[3] := CardHalf;
  _gomb[4] := PermDel;
  _gomb[5] := Carddel;
  _gomb[6] := Egyedi;
  _gomb[7] := AnyTax;

  _mess[1] := 'KEZEL…SI DÕJ FELEZ…SE ‹GYVEZET’ VAGY F’…RT…KT¡ROS ENGED…LY…VEL';
  _mess[2] := 'KEZEL…SI DÕJ FELEZ…SE AKCI” KERET…BEN';
  _mess[3] := 'K¡RTY¡S KEZEL…SI DÕJ FELEZ…S';
  _mess[4] := 'KEZEL…SI DÕJ ELENGED…SE ‹GYVEZ VAGY F’…RT…KT¡ROS ENGED…LY…VEL';
  _mess[5] := 'K¡RTY¡S KEZEL…SI DÕJ ELENGED…SE';
  _mess[6] := 'EGYEDI KEZEL…SI DIJ (Max: 3 %)';
  _mess[7] := 'SPECI¡LIS KEZEL…SI DÕJ';

  AlapAdatBeolvasas;
  _spk := supervisorjelszo(0);
  if _spk<>1 then
    begin
      Kilepo.enabled := True;
      exit;
    end;
end;



// =============================================================================
      procedure TForm2.PERMouseMove(Sender: TObject; Shift: TShiftState; X,
                                                                   Y: Integer);
// =============================================================================

begin

  _aktpanel := TPanel(Sender);
  _tag := _aktPanel.Tag;
  ClearAll;
  _aktpanel.Color := clYellow;
  InfoPanel.Caption := _mess[_tag];

end;

// =============================================================================
                      procedure TForm2.ClearAll;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  while _y<=7 do
    begin
      _tempPanel := _gomb[_y];
      _tempPanel.Color := clWhite;
      inc(_y);
    end;
end;

// =============================================================================
           procedure TForm2.Button1Click(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;




procedure TForm2.MEGSEMGOMBClick(Sender: TObject);
begin
  Modalresult := -1;
end;

procedure TForm2.ALAPLAPMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  Clearall;
end;

procedure TForm2.PERMHALFClick(Sender: TObject);
begin
  _tag := TPanel(sender).Tag;
  _gomb[_tag].Color := clWhite;

  if (_tag=6) and (_napikezdij>2) then
    begin
      ShowMessage('A napi egyedi kezdij lehetısÈge kimer¸lt');
      Modalresult := -1;
      exit;
    end;

  if (_tag=3) then
    begin
      Takarofel;
      CardNumedit.Clear;
      Cardpanel.Visible := True;
      ActiveControl := CardNumEdit;
      exit;
    end;

  if _tag>5 then
    begin
      TakaroFel;
      Kezdijedit.clear;
      GetkdPanel.Visible := true;
      Activecontrol := Kezdijedit;
      exit;
    end;


  if _tag<4 then _kezdij := round(_origkezdij/2)
  else _kezdij := 0;
  Finish;
end;


procedure TForm2.Finish;

begin
  Takarofel;

  Forintpanel.Caption := FtForm(_kezdij)+' Ft';
  TextPanel.visible := true;
  ForintPanel.Visible := true;
  RendbenGomb.Enabled := true;
  Activecontrol := RendbenGomb;
end;

function Tform2.FtForm(_ft: integer): string;
begin
  result := inttostr(_ft);
  if _ft<1000 then exit;
  result := leftstr(result,1)+' '+midstr(result,2,3);
end;

procedure TForm2.Label5Click(Sender: TObject);
begin
  permHalfCLick(PermHalf);
end;

procedure TForm2.CARDNUMEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  _cardnum := trim(CardnumEdit.Text);
  if _cardnum='' then exit;
  CardnumEdit.Color := clWhite;
  if _tag=3 then _kezdij := round(_origkezdij/2);
  Finish;
end;

procedure TForm2.PERMDELClick(Sender: TObject);
begin
  PermHalfclick(Permdel);
end;



procedure TForm2.TakaroFel;

begin
  with Takaro do
    begin
      left := 16;
      top  := 64;
      visible := true;
    end;
end;
procedure TForm2.Label7Click(Sender: TObject);
begin
  PermHalfclick(Permdel);
end;

procedure TForm2.KEZDIJEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var _ks: string;

begin
  if ord(key)<>13 then exit;
  _ks := trim(kezdijedit.Text);
  if _ks='' then exit;
  val(_ks,_kezdij,_code);
  if _code<>0 then exit;
  Getkdpanel.visible := False;
  Finish;
end;

procedure TForm2.AlapadatBeolvasas;

begin
  Valutadbase.connected := true;
  with valutaQuery do
    begin
      close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _kezdijmax := FieldByNAme('KEZDIJMAX').asInteger;
      _realezrelek := FieldByNAme('REALEZRELEK').asInteger;
      _napikezdij := FieldByNAme('NAPIEGYEDIKEZDIJ').asInteger;
      close;

      Sql.clear;
      Sql.add('SELECT * FROM VTEMP');
      Open;
      _netto := FieldByName('NETTO').asInteger;
      _origkezdij := FieldByName('ORIGKEZDIJ').asInteger;
      close;
    end;
  Valutadbase.close;
  _minkezdij := trunc(0.003*_netto);
end;

procedure TForm2.RENDBENGOMBClick(Sender: TObject);
begin
  if _kezdij>_kezdijmax then _kezdij := _kezdijmax;
  if (_tag=6) AND (_kezdij<_minkezdij) then _kezdij := _minkezdij;

  _kezdij := kerekito(_kezdij);

  _pcs := 'UPDATE VTEMP SET KEZELESIDIJ='+inttostr(_kezdij);
  _pcs := _pcs + ',KDKEDVKOD='+inttostr(_tag);
  if (_tag=3) then _pcs := _pcs + ',KARTYASZAM='+chr(39)+_cardnum+chr(39);

  ValutaParancs(_pcs);
  Modalresult := _tag;
end;

procedure TForm2.ValutaParancs(_ukaz: string);
begin
  valutadbase.connected := true;
  if valutatranz.InTransaction then valutaTranz.commit;
  valutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;      

procedure TForm2.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
  Modalresult := -1;
end;


// =============================================================================
           function TForm2.kerekito(_int: integer): integer;
// =============================================================================

var _nums: string;
    _utdig,_wnums: Byte;

begin
  result := _int;
  _nums := inttostr(_int);
  _wnums := length(_nums);
  _utdig := ord(_nums[_wnums])-48;
  if (_utdig<>0) and (_utdig<>5) then
    begin
      if (_utdig=1) or (_utdig=2) then result := _int-_utdig;
      if (_utdig=6) or (_utdig=7) then result := _int-(_utdig-5);
      if (_utdig=3) or (_utdig=4) then result := _int+(5-_utdig);
      if (_utdig=8) or (_utdig=9) then result := _int+10-_utdig;
    end;
end;


end.
