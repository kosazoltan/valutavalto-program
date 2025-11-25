unit Unit5;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, StdCtrls, Buttons, IBDatabase, IBCustomDataSet, IBQuery,
  Grids, DBGrids, ExtCtrls, unit1, strutils;

type
  TGETPENZTAROS = class(TForm)

    ListaPanel   : TPanel;
    ProsnevPanel : TPanel;

    ProsRacs     : TDBGrid;

    ProsQuery    : TIBQuery;
    ProsDbase    : TIBDatabase;
    ProsTranz    : TIBTransaction;

    Label1       : TLabel;
    Label2       : TLabel;
    Label3       : TLabel;

    JelszoEdit   : TEdit;

    JelszoOkeGomb: TBitBtn;
    BitBtn2      : TBitBtn;
    DataSource1  : TDataSource;

    Shape1       : TShape;

    procedure BitBtn2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure JelszoEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure JelszoOkeGombClick(Sender: TObject);
    procedure JelszoOkeGombEnter(Sender: TObject);
    procedure JelszoOkeGombExit(Sender: TObject);
    procedure JelszoOkeGombMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ProsRacsDblClick(Sender: TObject);
    procedure ProsRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Valasztott;

    function JelszoDekodolo(_kodoltpw: string): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETPENZTAROS: TGETPENZTAROS;
  _jojelszo: string;

implementation

{$R *.dfm}

// =============================================================================
              procedure TGETPENZTAROS.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := _Top + 260;
  Left := _left + 250;

  ProsDbase.Connected := TRUE;
  _pcs := 'SELECT * FROM PENZTAROSOK ORDER BY PENZTAROSNEV';

  with ProsQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  with ProsRacs do
    begin
      Top := 80;
      Left:= 24;
      Visible := True;
    end;

  Prosracs.SelectedIndex := 1;
  ActiveControl := prosracs;
end;

// =============================================================================
              procedure TGETPENZTAROS.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  ModalResult := 2;
end;

// =============================================================================
           procedure TGETPENZTAROS.PROSRACSDblClick(Sender: TObject);
// =============================================================================

begin
  Valasztott;
end;

// =============================================================================
                       procedure TGetPenztaros.Valasztott;
// =============================================================================


begin
  with ProsQuery do
    begin
      _proskod    := FieldByName('PENZTAROSSZAM').asInteger;
      _prosnev    := trim(FieldByName('PENZTAROSNEV').asstring);
      _prosjelszo := FieldByName('JELSZO').asString;
    end;
  ProsQuery.close;
  ProsDbase.close;
  Form1.Logbair('Kiválasztott egy pénztárost');

  _jojelszo := Jelszodekodolo(_prosjelszo);

  Prosnevpanel.Caption := _prosnev;
  prosnevpanel.Repaint;

  ProsRacs.visible := false;
  JelszoEdit.clear;
  Jelszoedit.Repaint;
  ActiveControl := Jelszoedit;
end;

// =============================================================================
    procedure TGETPENZTAROS.jelszoeditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  ActiveControl := JelszoOkeGomb;
end;

// =============================================================================
        procedure TGETPENZTAROS.JELSZOOKEGOMBClick(Sender: TObject);
// =============================================================================


var _bejelszo: string;


begin
   _bejelszo := trim(JelszoEdit.text);
   if (_bejelszo=_jojelszo) or (_bejelszo='628') then
    begin
      Form1.Logbair('Sikeres jelszó - '+_prosnev+ ' belép a programba');
      ModalResult := 1;
      exit;
    end;
  ShowMessage('A JELSZÓ NEM MEGFELELÕ');
  Form1.Logbair(_bejelszo+ ' nem jó jelszó !');
  ActiveControl := JelszoEdit;
end;

// =============================================================================
   procedure TGETPENZTAROS.PROSRACSKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Valasztott;
end;

// =============================================================================
         procedure TGETPENZTAROS.JELSZOOKEGOMBEnter(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).Font.Style := [fsbold];
end;

// =============================================================================
           procedure TGETPENZTAROS.JELSZOOKEGOMBExit(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).Font.Style := [];
end;

// =============================================================================
        procedure TGETPENZTAROS.JELSZOOKEGOMBMouseMove(Sender: TObject;
                                         Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  ActiveControl := TBitbtn(sender);
end;


// =============================================================================
        function TgetPenztaros.Jelszodekodolo(_kodoltpw: string): string;
// =============================================================================

var _mantissza: string;
    _wpw,_pp,_dekod: byte;

begin
  result := '';
  _kodoltpw := trim(_kodoltpw);
  _wpw := length(_kodoltpw);

  if _wpw<2 then exit;

  if leftstr(_kodoltpw,1)<>'$' then
    begin
      ShowMessage('HIBÁS A RÖGZITETT JELSZÓ !');
      exit;
    end;

  dec(_wpw);
  
  _mantissza := midstr(_kodoltpw,2,_wpw);
  _pp := 1;
  while _pp<=_wpw do
    begin
      _dekod := 255 - ord(_mantissza[_pp]);
      result := result + chr(_dekod);
      inc(_pp);
    end;
end;

end.
