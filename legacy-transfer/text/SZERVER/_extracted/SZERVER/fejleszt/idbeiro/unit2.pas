unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, unit1, Strutils;

type
  TSELECTPENZTAROS = class(TForm)
    PROSBOX: TListBox;
    KERNEVPANEL: TPanel;
    EZAJOKODGOMB: TBitBtn;
    LESZAMOLTGOMB: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure EZAJOKODGOMBClick(Sender: TObject);
    procedure LESZAMOLTGOMBClick(Sender: TObject);
    procedure PROSBOXKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
   
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SELECTPENZTAROS: TSELECTPENZTAROS;
  _cc,_prosindex,_lenitem: integer;
  _aktitem: string;


implementation

{$R *.dfm}



procedure TSELECTPENZTAROS.FormCreate(Sender: TObject);
begin
  tOP := _TOP+50;
  Left := _left + 150;

  Prosbox.Items.clear;
  _cc := 0;
  while _cc<_prosdarab do
    begin
      Prosbox.Items.Add(_mixed[_cc]);
      inc(_cc);
    end;
end;

procedure TSELECTPENZTAROS.FormActivate(Sender: TObject);
begin
  KernevPanel.Caption := _keresettnev;
  Prosbox.ItemIndex := _lastrec;
  Activecontrol := ProsBox;
  Prosbox.SetFocus;
end;

procedure TSELECTPENZTAROS.EZAJOKODGOMBClick(Sender: TObject);
begin
  _prosindex := Prosbox.itemindex;
  _lastrec := _prosindex;
  _aktitem := trim(Prosbox.items[_prosindex]);
  _lenitem := length(_aktitem);
  _joPenztarosnev := midstr(_aktitem,9,_lenitem-8);
  _joidkod := Leftstr(_aktitem,5);
  Modalresult := 1;

end;

procedure TSELECTPENZTAROS.LESZAMOLTGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;


procedure TSELECTPENZTAROS.PROSBOXKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  Ezajokodgombclick(Nil);
end;

end.
