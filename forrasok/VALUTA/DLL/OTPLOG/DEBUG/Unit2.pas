unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery,
  Buttons, Grids, Calendar, strutils;

type
  TForm2 = class(TForm)
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    Label2: TLabel;
    NAPTARPANEL: TPanel;
    NAPTAR: TCalendar;
    Label1: TLabel;
    PREHONAP: TBitBtn;
    DATUMPANEL: TPanel;
    NEXTHONAP: TBitBtn;
    NAPOKEGOMB: TBitBtn;
    NAPTARVISSZAGOMB: TBitBtn;
    KILEPO: TTimer;
    LOGPANEL: TPanel;
    LOGBOX: TListBox;
    logPanelcim: TPanel;
    ujnapgomb: TBitBtn;
    Shape1: TShape;

    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure PreHonapClick(Sender: TObject);
    procedure NextHonapClick(Sender: TObject);
    procedure NaptarChange(Sender: TObject);

    function Nulele(_b: byte): string;
    procedure KILEPOTimer(Sender: TObject);
    procedure NAPTARVISSZAGOMBClick(Sender: TObject);
    procedure NAPOKEGOMBClick(Sender: TObject);
    procedure ujnapgombClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _honev: array[1..12] of string = ('január','február','március','április','május',
                   'junius','július','augusztus','szeptember','október','november',
                                                      'december');

  _napnev: array[1..7] of string = ('vasárnap','hétfõ','kedd','szerda','csütörtök',
                                         'péntek','szombat');

  _kdate: TDateTime;
  _Posterm,_termtip,_ctrl,_hnap: byte;
  _kev,_kHo,_knap: word;
  _datum,_kertfilenev,_mondat,_cim: string;
  _olvas: textfile;

  _top,_left,_height,_width: word;

function otpterminallog: integer; stdcall; 


implementation

{$R *.dfm}

function otpterminallog: integer; stdcall;

begin
  Form2 := Tform2.Create(Nil);
  result := Form2.ShowModal;
  Form2.Free;
end;

procedure TForm2.Button1Click(Sender: TObject);
begin
  mODALRESULT := 1;
end;

procedure TForm2.FormActivate(Sender: TObject);
begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-490)/2);
  _left := round((_width-840)/2);

  Top := _top;
  Left := _left;

  LogPanel.Visible := False;
  Naptar.CalendarDate := Date;

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _posterm := FieldByNAme('POSTTERM').asInteger;
      Close;
    end;
  Valutadbase.close;

  _ctrl := _posterm + _termtip;

  if _posterm<>1 then
    begin
      Showmessage('Nincs beállitva OTP-terminál');
      Kilepo.enabled := True;
      exit;
    end;
  Activecontrol := Naptar;
end;

procedure TForm2.PREHONAPClick(Sender: TObject);
begin
  Naptar.PrevMonth;
end;

procedure TForm2.NEXTHONAPClick(Sender: TObject);
begin
  Naptar.NextMonth;
end;

procedure TForm2.NAPTARChange(Sender: TObject);
begin
  _kDate := Naptar.CalendarDate;
  _hnap := dayofweek(_kDate);

  _kev := Naptar.Year;
  _kho := Naptar.Month;
  _knap:= Naptar.Day;

  _datum := inttostr(_kev)+'.'+nulele(_kHo)+'.'+nulele(_kNap);
  DatumPanel.Caption := _datum;
  DatumPanel.Repaint;
end;

function TForm2.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

procedure TForm2.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := False;
end;

procedure TForm2.NAPTARVISSZAGOMBClick(Sender: TObject);
begin
  Modalresult := 2;
end;

procedure TForm2.NAPOKEGOMBClick(Sender: TObject);
begin
  _kertFileNev := 'POS' + midstr(_datum,3,2)+midstr(_datum,6,2)+midstr(_datum,9,2)+'.log';

  Setcurrentdir('c:\valuta\log');
  if not FileExists(_kertFilenev) then
    begin
      Showmessage('A KÉRT NAPRÓL NINCSENEK ADATOK RÖGZITVE');
      exit;
    end;

  _cim:= 'Az OTP terminál '+inttostr(_kev)+' '+_honev[_kho]+' '+ inttostr(_knap);
  _cim := _cim + ' '+_napnev[_hnap]+'i logfile-ja';

  LogPanelCim.Caption := _cim;
  LogpanelCim.repaint;
  with LogPanel do
    begin
      top := 80;
      Left := 10;
      Visible := True;
      Repaint;
    end;

  Assignfile(_olvas,_kertfilenev);
  reset(_olvas);
  while not Eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      Logbox.Items.Add(_mondat);
    end;
  Closefile(_olvas);
  Logbox.ItemIndex := 0;
  Activecontrol := Logbox;


end;

procedure TForm2.ujnapgombClick(Sender: TObject);
begin
  Logpanel.Visible := False;
  Activecontrol := Naptar;
end;

end.
