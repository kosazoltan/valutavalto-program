unit Unit13;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Grids, Calendar,DateUtils,idGlobal;

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
    procedure ValaszFeldolgozas;
    procedure DelHeadRow;
   

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  LOGOLVASAS: TLOGOLVASAS;
  _top1,_left1,_kertev,_kertho,_kertnap: word;
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
      ShowMessage('NINCS ERRÕL A NAPRÓL LOG-FILE');
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

// =============================================================================
                    procedure TLogolvasas.ValaszFeldolgozas;
// =============================================================================

var _lastreply: string;

begin

  sleep(1500);  
  if not FileExists(_replyPath) then exit;

  _lastreply := 'c:\valuta\temp\lastreply.xml';

  if fileExists(_lastreply) then sysutils.DeleteFile(_lastreply);
  copyfileto('c:\valuta\temp\reply.xml',_lastreply);

  AssignFile(_binolvas,_replyPath);
  reset(_binolvas);
  _filehossz := filesize(_binolvas);


  Blockread(_binolvas,_bytetomb,_filehossz);
  CloseFile(_binolvas);

  Form1.Logbair('A válaszfile hossza: ' + inttostr(_filehossz));

  _z := 1;
  _aktreprow := '';
  _vegjel    := false;
  _rowss     := 0;

  // Az információs fejléc törlése a _z mutatót <Message> utáni byte-ra teszi:

  DelHeadRow;

  // A _rep nevü választömbbe reppieces darab sorba rendezi a válasz XML-t

  while _z<=_filehossz do
    begin
      _asc := _bytetomb[_z];
      if (_asc=32) or (_asc=10) or (_asc=13) then
        begin
          inc(_z);
          continue;
        end;

      _aktreprow := _aktreprow + chr(_asc);

      if _asc=60 then
        begin
          inc(_z);
          _asc := _bytetomb[_z];
          _aktreprow := _aktreprow+chr(_asc);
          if _asc=47 then _vegjel := true;
        end;

      if (_asc=62) and (_vegjel=True) then
        begin
          _vegjel := False;
          inc(_rowss);
          _reprow[_rowss] := _aktreprow;
          _aktreprow := '';
        end;
      inc(_z);
    end;

  _reppieces := _rowss;

  Form1.Logbair('A válaszfile sorszáma: ' + inttostr(_rowss));

end;

// =============================================================================
                      procedure TLogolvasas.DelHeadRow;
// =============================================================================

//  Az információs fejléc törlése - a _z mutatót <Message> utáni bytra állitja

begin
  _z := 1;
  while _z<=_filehossz do
    begin
      _asc := _bytetomb[_z];
      if _asc=60 then
        begin
          inc(_z);
          _asc := _bytetomb[_z];
          if _asc=77 then
            begin
              inc(_z);
              if _bytetomb[_z]=101 then break;
            end;
        end;
      inc(_z);
    end;
  _z := _z+7;
end;



end.
