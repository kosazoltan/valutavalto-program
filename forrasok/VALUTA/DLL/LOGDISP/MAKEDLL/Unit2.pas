unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, Calendar, ExtCtrls, dateutils;

type
  TForm2 = class(TForm)
    ALAPPANEL: TPanel;
    Label1: TLabel;
    NAPTARPANEL: TPanel;
    NAPTAR: TCalendar;
    Label2: TLabel;
    ELOHOGOMB: TBitBtn;
    KOVHOGOMB: TBitBtn;
    VALASZTOGOMB: TBitBtn;
    DESCAPEGOMB: TBitBtn;
    datumpanel: TPanel;
    DISPPANEL: TPanel;
    ListBox1: TListBox;
    FODATUMPANEL: TPanel;
    masiknapgomb: TBitBtn;
    visszagomb: TBitBtn;
    Shape1: TShape;

  
    procedure dekodolas(_lp: string);
    function Nulele(_b: byte): string;
    procedure VALASZTOGOMBClick(Sender: TObject);
    procedure ELOHOGOMBClick(Sender: TObject);
    procedure KOVHOGOMBClick(Sender: TObject);
    procedure NAPTARChange(Sender: TObject);
    procedure DESCAPEGOMBClick(Sender: TObject);
    procedure masiknapgombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure NAPTARKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _top,_left,_width,_height: word;

  _HONEV: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                 'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                 'NOVEMBER','DECEMBER');
  _NAPNEV: array[1..7] of string = ('HÉTFÕ','KEDD','SZERDA','CSÜTÖRTÖK',
                                  'PÉNTEK','SZOMBAT','VASÁRNAP');               

  _olvas: file of byte;
  _sor,_item,_lFile,_lpath,_maindstring,_dstring: string;
  _sorlen,_asc: byte;
  _kertev,_kertho,_kertnap,_hnap: word;
  _ora,_perc,_sec: byte;
  _dlen,_y,_p: integer;
  _bytetomb: array[1..768000] of byte;
  _nYear,_nMonth,_nDay: word;
  _nDatum: TDateTime;

function logdisplayrutin: integer; stdcall;


implementation

{$R *.dfm}

function logdisplayrutin: integer; stdcall;
begin
  Form2 := TForm2.create(Nil);
  result := Form2.showmodal;
  Form2.Free;
end;

procedure TForm2.dekodolas(_lp: string);

begin
  Listbox1.Clear;
  Listbox1.Items.Clear;

  Assignfile(_olvas,_lp);
  reset(_olvas);
  _dlen := filesize(_olvas);
  blockread(_olvas,_bytetomb,_dlen);
  Closefile(_olvas);

  _p := 1;
  while _p<=_dlen do
    begin
      _ora := _bytetomb[_p];
      _perc := _bytetomb[_p+1];
      _sec := _bytetomb[_p+2];
      _sorlen := _bytetomb[_p+3];
      _p := _p+4;
      _sor := '';

      if _sorlen>0 then
        begin
          _y := 1;
          while _y<=_sorlen do
            begin
              _asc := 255-_bytetomb[_p];
              _sor := _sor + chr(_asc);
              inc(_p);
              inc(_y);
            end;
        end;
      _item := nulele(_ora)+':'+nulele(_perc)+':'+nulele(_sec)+'= ' + _sor;
      Listbox1.Items.add(_item);
    end;
end;

function TForm2.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

procedure TForm2.VALASZTOGOMBClick(Sender: TObject);

begin
  _kertev := Naptar.Year;
  _kertho := Naptar.month;
  _kertnap:= Naptar.day;

  _lfile := 'L' +inttostr(_kertev-2000)+nulele(_kertho)+nulele(_kertnap)+'.log';
  _lPath := 'c:\valuta\log\' + _lfile;

  if not fileExists(_lpath) then
    begin
      Showmessage('A KÉRT NAPRÓL NINCS FELJEGYZÉS');
      ActiveControl := Naptar;
      exit;
    end;  

  Dekodolas(_lPath);

  Naptarchange(Nil);
  with DispPanel do
    begin
      top := 80;
      left := 36;
      Visible := true;
      repaint;
    end;
   Listbox1.ItemIndex := 0;
   Listbox1.SetFocus;

end;

procedure TForm2.ELOHOGOMBClick(Sender: TObject);
begin
  nAPTAR.PrevMonth;
  Activecontrol := Naptar;
end;

procedure TForm2.KOVHOGOMBClick(Sender: TObject);
begin
  Naptar.NextMonth;
  Activecontrol := Naptar;
end;

procedure TForm2.NAPTARChange(Sender: TObject);
begin
  _Nyear  := NAPTAR.year;
  _nMonth := Naptar.Month;
  _nDay   := Naptar.Day;
  _nDatum := Naptar.CalendarDate;
  _dstring := inttostr(_nYear)+'.'+nulele(_nMonth)+'.'+nulele(_nDay);
  DatumPanel.Caption := _dString;
  Datumpanel.Repaint;

  _maindstring := inttostr(_nyear)+' '+_honev[_nmonth]+' '+inttostr(_nday)+' ';
  _hnap := dayoftheweek(_nDatum);
  _maindstring := _maindstring + _napnev[_hnap];

  Fodatumpanel.caption := _maindstring;
  FodatumPanel.repaint;
end;

procedure TForm2.DESCAPEGOMBClick(Sender: TObject);
begin
  Modalresult := 1;
end;

procedure TForm2.masiknapgombClick(Sender: TObject);
begin
  Disppanel.visible := false;
  Activecontrol := Naptar;
end;

procedure TForm2.FormActivate(Sender: TObject);
begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;
  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);
  Top := _top;
  Left := _left;
  Activecontrol := Naptar;
end;

procedure TForm2.NAPTARKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  Valasztogombclick(Nil);
end;



end.
