unit Unit13;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Grids, Calendar,DateUtils;

type
  TLOGOLVASAS = class(TForm)
    NAPTAR: TCalendar;
    DATUMPANEL: TPanel;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    Label1: TLabel;
    LOGLISTA: TListBox;
    Label2: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure NAPTARChange(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  LOGOLVASAS: TLOGOLVASAS;
  _top1,_left1,_aktev,_aktho,_aktnap,_kertev,_kertho,_kertnap: word;
  _mondat,_kertlogfile: string;
  _olvas: textfile;

implementation

uses Unit1;

{$R *.dfm}

procedure TLOGOLVASAS.BitBtn1Click(Sender: TObject);
begin
  mODALrESULT := 1;
end;

procedure TLOGOLVASAS.FormActivate(Sender: TObject);
begin

  Loglista.Items.clear;
  Loglista.clear;

  _top1 := Form1.top;
  _left1:= Form1.left;

  top := _top1 + 40;
  Left:= _left1+60;

  _aktev := yearof(Date);
  _aktho := monthof(date);
  _aktnap:= dayof(date);

  Naptar.Year := _aktev;
  Naptar.Month := _aktho;
  Naptar.Day := _aktnap;
  NaptarChange(Nil);
end;

procedure TLOGOLVASAS.BitBtn2Click(Sender: TObject);
begin
  nAPTAR.PrevMonth;
end;

procedure TLOGOLVASAS.BitBtn3Click(Sender: TObject);
begin
  naptar.NextMonth;
end;

procedure TLOGOLVASAS.NAPTARChange(Sender: TObject);

var _datumstr: string;

begin
  _kertEV := Naptar.Year;
  _kertho := Naptar.Month;
  _kertnap := Naptar.day;

  _datumstr := inttostr(_kertev)+' '+_honev[_kertho]+' '+inttostr(_kertnap);
  Datumpanel.Caption := _datumstr;
  DatumPanel.Repaint;
end;

procedure TLOGOLVASAS.BitBtn4Click(Sender: TObject);
begin
  _kertlogfile := 'XL' + inttostr(_kertev-2000)+Form1.nulele(_kertho)+Form1.nulele(_kertnap)+'.log';
  _logpath := _tradeLogDir + '\' + _kertlogfile;

  if not fileExists(_logpath) then
    begin
      ShowMessage('NINCS ERRŐL A NAPRÓL LOG-FILE');
      Modalresult := 1;
      exit;
    end;

  Assignfile(_olvas,_logpath);
  reset(_olvas);
  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      _mondat := Form1.Kodxor(_mondat);
      Loglista.Items.add(_mondat);
    end;
  Closefile(_olvas);
  Loglista.ItemIndex := 0;
  Activecontrol := Loglista;
end;

end.
