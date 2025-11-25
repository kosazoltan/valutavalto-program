unit Unit24;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DB, IBDatabase, IBCustomDataSet, IBTable,
  Grids, DBGrids, Buttons, unit1, strUtils;

type
  TKESZLETDISPLAY = class(TForm)
    Label1: TLabel;
    Panel1: TPanel;
    IDOSZAKPANEL: TPanel;
    KESZLETRACS: TDBGrid;
    KESZLETTABLA: TIBTable;
    KESZLETDBASE: TIBDatabase;
    keszlettranz: TIBTransaction;
    KESZLETSOURCE: TDataSource;
    Panel3: TPanel;
    BitBtn2: TBitBtn;
    KESZLETTABLAIRODASZAM: TIntegerField;
    KESZLETTABLAERTEKTAR: TIntegerField;
    KESZLETTABLAVALUTANEM: TIBStringField;
    KESZLETTABLAELSZAMOLASIARFOLYAM: TFloatField;
    KESZLETTABLAFORINTERTEK: TFloatField;
    KESZLETTABLAKESZLET: TFloatField;
    KESZLETTABLACIMLET1: TIntegerField;
    KESZLETTABLACIMLET2: TIntegerField;
    KESZLETTABLACIMLET3: TIntegerField;
    KESZLETTABLACIMLET5: TIntegerField;
    KESZLETTABLACIMLET6: TIntegerField;
    KESZLETTABLACIMLET7: TIntegerField;
    KESZLETTABLACIMLET8: TIntegerField;
    KESZLETTABLACIMLET9: TIntegerField;
    KESZLETTABLACIMLET10: TIntegerField;
    KESZLETTABLACIMLET11: TIntegerField;
    KESZLETTABLACIMLET12: TIntegerField;
    KESZLETTABLACIMLET13: TIntegerField;
    KESZLETTABLACIMLET14: TIntegerField;
    KESZLETTABLACIMLET4: TIntegerField;
    VALUTAPANEL: TPanel;
    FORINTPANEL: TPanel;
    Panel5: TPanel;
    OSSZESPANEL: TPanel;
    POSTAGOMB: TBitBtn;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;

    procedure BitBtn2Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    function arFFormat(_rr:real): string;
    function FFormat(_rr:real): string;
    procedure PostabaTesz(sender: TObject);
    procedure VonalHuzo;
    procedure Kozepreir(_mm: string);
    procedure POSTAGOMBEnter(Sender: TObject);
    procedure POSTAGOMBExit(Sender: TObject);
    procedure POSTAGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KESZLETDISPLAY: TKESZLETDISPLAY;
  _sumertek,_valertek,_hufertek,_aktarfolyam,_sForint,_ftertek: real;
  _iras: Textfile;

implementation

{$R *.dfm}

procedure TKESZLETDISPLAY.BitBtn2Click(Sender: TObject);
begin
  KeszletTabla.Close;
  ModalResult := 1;
end;

procedure TKESZLETDISPLAY.FormActivate(Sender: TObject);


begin
  Top := _top +195;
  Left := _left + 170;
  PostaGomb.Visible := True;
  iDOSZAKPANEL.Caption := 'VIZSGÁLT IDÖSZAK :'+_idoszakLabel;

  case _displaytipus of
    1: _szuro := '(IRODASZAM=0) AND (ERTEKTAR=0)';
    2: _szuro := '(IRODASZAM=0) AND (ERTEKTAR='+chr(39)+inttostr(_aktkorzet)+chr(39)+')';
    3: _szuro := 'IRODASZAM='+chr(39)+inttostr(_aktpenztar)+chr(39);
    4: _szuro := '(IRODASZAM=-1) AND (ERTEKTAR='+inttostr(_cbsors)+')';
  end;

  KeszletSource.Enabled := false;

  KeszletDbase.Close;
  KeszletDbase.Connected := True;
  if Keszlettranz.InTransaction then keszlettranz.Commit;
  with KeszletTabla do
    begin
      Open;
      Refresh;
      Filtered := False;
      Filter := _szuro;
      Filtered := True;
      First;
    end;

  _hufertek := 0;
  _valertek := 0;
  _sumertek := 0;
  while not KeszletTabla.Eof do
    begin
      with KeszletTabla do
        begin
          _elszarfolyam := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _keszlet := FieldByName('KESZLET').asInteger;
          _valutanem := FieldByName('VALUTANEM').asstring;
          _ftertek := FieldByName('FORINTERTEK').asInteger;
        end;
      if _valutanem='HUF' then _hufertek :=  _keszlet
      else _valertek := _valertek + _ftErtek;             //(_elszarfolyam*_keszlet/100);
      KeszLetTabla.Next;
    end;

  _sumErtek := _valertek+_hufertek;

  Valutapanel.Caption := FormatFloat('###,###,###',_valertek);
  ForintPanel.Caption := FormatFloat('###,###,###',_hufertek);
  OsszesPanel.Caption := FormatFloat('###,###,###',_sumertek);


  KeszletTabla.First;
  KeszletSource.Enabled := true;
end;


procedure TKeszletDisplay.PostabaTesz(sender: Tobject);

var _listaPath: string;


begin
   PostaGomb.visible := False;
   _listaPath := 'c:\receptor\mail\posta\Keszlet.txt';
   if fileExists(_listaPath) then DeleteFile(_ListaPath);

   _sforint := 0;

   AssignFile(_iras,_listaPath);
   Rewrite(_iras);
   writeln(_iras,chr(13)+chr(10));
   writeln(_iras,chr(13)+chr(10));
   writeln(_iras,chr(13)+chr(10));

   writeLn(_iras,'                    NAPI VALUTAKESZLET KIMUTATASA');

   WriteLn(_iras,'        '+_displayfocim+'              '+_idoszaklabel);
   VonalHuzo;

   WriteLn(_iras,'      VALUTA        MENNYISEG         ARFOLYAM        FORINTERTEK');
   VonalHuzo;
   KeszletTabla.First;
   while not keszlettabla.eof do
     begin
       _valutanem := Keszlettabla.FieldByName('VALUTANEM').asString;
       _keszlet := KeszletTabla.FieldByNAme('KESZLET').asInteger;
       _aktarfolyam := KeszletTabla.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
       _ertek := KeszletTabla.FieldByName('FORINTERTEK').asInteger;
       _sforint := _sforint + _ertek;

       write(_iras,'       '+_valutanem);
       write(_iras,'         ');
       write(_iras,fformat(_keszlet));
       write(_iras,'         ');
       write(_iras,arfformat(_aktarfolyam)+'       ');
       writeLn(_iras,fformat(_ertek));
       Keszlettabla.Next;
     end;
   Vonalhuzo;
   writeln(_iras,'                     Osszes forintertek: '+ fformat(_sforint)+' Ft');
   closefile(_iras);
   Keszlettabla.First;
   ShowMessage('A KÉSZLETET KITETTEM A POSTÁBA >> KESZLET.TXT << NÉVEN');
end;

procedure TKeszletDisplay.VonalHuzo;

begin
  writeLn(_iras,'     '+dupestring('-',63));
end;

procedure TKeszletDisplay.Kozepreir(_mm: string);

var _len,_marad: integer;

begin
  _len := length(_mm);
  _marad := trunc((80-_len)/2);
  writeLn(_iras,dupestring(chr(32),_marad)+_mm);
end;

function TKeszletDisplay.FFormat(_rr:real): string;

begin
  result := formatfloat('### ### ###',_rr);
  while length(result)<11 do Result := ' '+Result;
end;

function TKeszletDisplay.arFFormat(_rr:real): string;

begin
  result := formatfloat('## ###.00',_rr);
  while length(result)<9 do result := ' '+result;
end;




procedure TKESZLETDISPLAY.POSTAGOMBEnter(Sender: TObject);
begin
  TBitbtn(sender).Font.Color := clBlack;
end;

procedure TKESZLETDISPLAY.POSTAGOMBExit(Sender: TObject);
begin
  TBitbtn(sender).Font.Color := clGray;
end;

procedure TKESZLETDISPLAY.POSTAGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := TBitbtn(sender);
end;

end.
