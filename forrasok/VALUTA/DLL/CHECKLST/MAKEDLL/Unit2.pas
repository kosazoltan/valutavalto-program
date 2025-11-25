unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, Grids, Calendar, strUtils,dateutils,
  IBDatabase, DB, IBCustomDataSet, IBQuery, Printers;

type
  TTASKCTRL = class(TForm)
    Panel1: TPanel;
    M1: TPanel;
    M2: TPanel;
    M6: TPanel;
    M13: TPanel;
    M5: TPanel;
    M8: TPanel;
    M9: TPanel;
    M7: TPanel;
    M4: TPanel;
    M10: TPanel;
    M15: TPanel;
    M11: TPanel;
    M17: TPanel;
    M18: TPanel;
    M19: TPanel;
    M3: TPanel;
    M12: TPanel;
    M14: TPanel;
    M16: TPanel;
    K1: TShape;
    K2: TShape;
    K3: TShape;
    K4: TShape;
    K16: TShape;
    K17: TShape;
    K19: TShape;
    K14: TShape;
    K18: TShape;
    K15: TShape;
    K13: TShape;
    K12: TShape;
    K7: TShape;
    K5: TShape;
    K6: TShape;
    K8: TShape;
    K9: TShape;
    K10: TShape;
    K11: TShape;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit13: TEdit;
    Edit14: TEdit;
    Edit15: TEdit;
    Edit16: TEdit;
    Edit17: TEdit;
    Edit18: TEdit;
    Edit19: TEdit;
    Label1: TLabel;
    VISSZAGOMB: TBitBtn;
    ROGZITOGOMB: TBitBtn;
    Label2: TLabel;
    Label3: TLabel;
    Aktnappanel: TPanel;
    PROSEDIT: TEdit;
    NAPTARPANEL: TPanel;
    NAPTAR: TCalendar;
    Label4: TLabel;
    DATUMPANEL: TPanel;
    ELOZOHO: TBitBtn;
    KOVETKEZOHO: TBitBtn;
    Shape1: TShape;
    fuggony: TPanel;
    Label5: TLabel;
    IBQuery: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    superkeys: TPanel;
    NYOMTATOGOMB: TBitBtn;
    VISSZA2GOMB: TBitBtn;
    KILEPO: TTimer;

    procedure Sorjeloles(_t: byte);
    procedure Oszlopixelo;
    procedure ChangeCheckJel;
  
    procedure FormActivate(Sender: TObject);
    procedure Edit1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Edit1Exit(Sender: TObject);

    procedure VISSZAGOMBClick(Sender: TObject);
    procedure SuperControl;
    procedure NAPTARChange(Sender: TObject);
    procedure Label5Click(Sender: TObject);
    procedure ELOZOHOClick(Sender: TObject);
    procedure KOVETKEZOHOClick(Sender: TObject);
    procedure NAPTARDblClick(Sender: TObject);
    procedure Gepadatok;
    procedure Edit1Click(Sender: TObject);
    procedure ROGZITOGOMBClick(Sender: TObject);
    procedure NYOMTATOGOMBClick(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    function Hundatetostr(_caldat: TDatetime): string;
    function Nulele(_b: byte): string;
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TASKCTRL: TTASKCTRL;
  _m,_w: array[1..19] of string;
  _ed: array[1..19] of TEdit;
  _kk: array[1..19] of TShape;
  _chk: array[1..19] of Byte;
  _tag,_spk,_zz: integer;
  _mamas,_aktnaps,_chkfile,_chkPath,_pcs,_prosnev: string;
  _aktdatum: TDatetime;
  _Paratipus: integer;
  _checkdir: string = 'c:\valuta\check';
  _bytetomb: array[1..255] of byte;
  _LFile: textfile;
  _sorveg: string = chr(13)+chr(10);
  _top,_left,_height,_width,_printer: word;
  _mresult : integer;

  // chekfile : 'CH YY MM DD . CHK'

function checkcontrol(_para: integer):integer; stdcall;
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';


implementation

{$R *.dfm}



function checkcontrol(_para: integer):integer; stdcall;
begin
  TaskCtrl := TTaskCtrl.Create(Nil);
  _paratipus := _para;
  result := TaskCtrl.showModal;
  TaskCtrl.Free;
end;



procedure TTASKCTRL.FormActivate(Sender: TObject);

var i: integer;

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top := _top +50;
  Left := _left +95;

  NaptarPanel.Visible := false;
  SuperKeys.Visible := False;
  _mamas := Hundatetostr(date);


  if not DirectoryExists(_checkdir) then CreateDir(_checkdir);

  _m[1] := 'Minden pénztár készlete feltöltve (címletek, fém euró)';
  _m[2] := 'Esetleges helyettesítéskor kollégának minden infó átadólapon átadva.';
  _m[3] := 'Grafikon kitöltve, kifüggesztve érintetteknek továbbitva.';
  _m[4] := 'Konkurencia árfolyamainak, készleteinek figyelemmel követése.';
  _m[5] := 'Konkurencia jelentés megirása  (eseti)';
  _m[6] := 'Próbaváltás (eseti)';
  _m[7] := 'Havi beszámoló megirása (eseti).';
  _m[8] := 'Bizonylatok párosítása, lefûzése.';
  _m[9] := 'Kktg beszedése, befizetése (eseti)';
 _m[10] := 'E-ker beszedése, befizetése (eseti)';
 _m[11] := 'Jutalék befizetése  (eseti)';
 _m[12] := 'TRB tábla kitöltése';
 _m[13] := 'Egyedi árfolyamos tábla kitöltése, továbbítása az érintetetteknek (eseti)';
 _m[14] := 'Egyedi árfolyamok ellenõrzése, továbbítása az érintetetteknek';
 _m[15] := 'Nagy ügyféltáblák begyüjtése, összesítése, továbbítása érintetteknek (eseti)';
 _m[16] := 'Könyvelések lenyomtatása, lefûzése, adatainak ellenõrzése';
 _m[17] := 'Hóvégi egyeztetés területekkel (eseti)';
 _m[18] := 'Hóvégi egyeztetés pénztárakkal  (eseti)';
 _m[19] := 'Napi jelentések jelszavainak elküldése SMS-ben a pénztáraknak, értéktárosoknak stb.  (eseti)';

  _w[1] := 'Minden penztar keszlete feltoltve (címletek, fem euro)';
  _w[2] := 'Esetleges helyettesíteskor kolleganak minden info atadolapon atadva.';
  _w[3] := 'Grafikon kitoltve, kifuggesztve erintetteknek tovabbitva.';
  _w[4] := 'Konkurencia arfolyamainak, keszleteinek figyelemmel kovetese.';
  _w[5] := 'Konkurencia jelentes megirasa  (eseti)';
  _w[6] := 'Probavaltas (eseti)';
  _w[7] := 'Havi beszamolo megirasa (eseti).';
  _w[8] := 'Bizonylatok parositasa, lefuzese.';
  _w[9] := 'Kktg beszedese, befizetese (eseti)';
 _w[10] := 'E-ker beszedese, befizetese (eseti)';
 _w[11] := 'Jutalek befizetese  (eseti)';
 _w[12] := 'TRB tabla kitoltese';
 _w[13] := 'Egyedi arfolyamos tabla kitoltese, tovabbitasa az erintetetteknek (eseti)';
 _w[14] := 'Egyedi arfolyamok ellenorzese, tovabbitasa az erintetetteknek';
 _w[15] := 'Nagy ugyfeltablak begyujtese, osszesítése, tovabbitasa erintetteknek (eseti)';
 _w[16] := 'Konyvelesek lenyomtatasa, lefuzese, adatainak ellenorzese';
 _w[17] := 'Hovegi egyeztetes teruletekkel (eseti)';
 _w[18] := 'Hovegi egyeztetes penztarakkal  (eseti)';
 _w[19] := 'Napi jelentesek jelszavainak elkuldese SMS-ben a penztaraknak, ertektarosoknak stb.  (eseti)';




 _ed[1] := Edit1;
 _ed[2] := Edit2;
 _ed[3] := Edit3;
 _ed[4] := Edit4;
 _ed[5] := Edit5;
 _ed[6] := Edit6;
 _ed[7] := Edit7;
 _ed[8] := Edit8;
 _ed[9] := Edit9;
 _ed[10]:= Edit10;
 _ed[11]:= Edit11;
 _ed[12]:= Edit12;
 _ed[13]:= Edit13;
 _ed[14]:= Edit14;
 _ed[15]:= Edit15;
 _ed[16]:= Edit16;
 _ed[17]:= Edit17;
 _ed[18]:= Edit18;
 _ed[19]:= Edit19;

 _kk[1] := k1;
 _kk[2] := k2;
 _kk[3] := k3;
 _kk[4] := k4;
 _kk[5] := k5;
 _kk[6] := k6;
 _kk[7] := k7;
 _kk[8] := k8;
 _kk[9] := k9;
 _kk[10]:= k10;
 _kk[11]:= k11;
 _kk[12]:= k12;
 _kk[13]:= k13;
 _kk[14]:= k14;
 _kk[15]:= k15;
 _kk[16]:= k16;
 _kk[17]:= k17;
 _kk[18]:= k18;
 _kk[19]:= k19;

 for i := 1 to 19  do
   begin
     _ed[i].Text := _m[i];
     _chk[i] := 0;
   end;

  if _paratipus=0 then
    begin
      Gepadatok;
      AktnapPanel.Caption := _aktnaps;
      Prosedit.Text := _prosnev;
      Fuggony.visible := false;
      exit;
    end else
    begin
      with Fuggony do
        begin
          Top := 48;
          Left := 48;
          Visible := true;
        end;
      Supercontrol;
    end;
end;

procedure TTASKCTRL.Supercontrol;

begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then
    begin
      _Mresult := 2;
      Kilepo.Enabled := true;
      exit;
    end;

  Naptar.CalendarDate := date;
  DatumPanel.Caption := _mamas;

  with NaptarPanel do
    begin
      top := 232;
      Left := 216;
      Visible := True;
    end;
end;


procedure TTASKCTRL.Edit1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);

begin
  if _paratipus=1 then exit;
  _tag := TEdit(sender).Tag;
  SorJeloles(_tag);

end;


procedure TTASKCTRL.Sorjeloles(_t: byte);

begin
  _ed[_tag].Color := $B0FFFF;
  Activecontrol := _ed[_tag];
end;




procedure TTASKCTRL.Edit1Exit(Sender: TObject);
begin
  if _paratipus=1 then exit;
  _tag := Tedit(Sender).Tag;
  _ed[_tag].Color := clWindow;
end;


procedure TTASKCTRL.VISSZAGOMBClick(Sender: TObject);
begin
  _MResult := 2;
  Kilepo.Enabled := true;
end;

procedure TTASKCTRL.NAPTARChange(Sender: TObject);
begin
  _aktdatum := Naptar.CalendarDate;
  _aktnaps := Hundatetostr(_aktdatum);
  Datumpanel.Caption := _aktnaps;
end;

procedure TTASKCTRL.Label5Click(Sender: TObject);
begin
  _Mresult := 2;
  Kilepo.Enabled := True;
end;

procedure TTASKCTRL.ELOZOHOClick(Sender: TObject);
begin
  Naptar.PrevMonth; 
end;

procedure TTASKCTRL.KOVETKEZOHOClick(Sender: TObject);
begin
  Naptar.NextMonth;
end;

procedure TTASKCTRL.NAPTARDblClick(Sender: TObject);

var _binolvas: file of byte;
    _meret: byte;

begin
  _CHKFILE := 'CH' + midstr(_aktnaps,3,2)+midstr(_aktnaps,6,2)+midstr(_aktnaps,9,2)+'.chk';
  _chkPath := 'c:\valuta\check\' + _chkfile;
  if not FileExists(_chkPath) then
    begin
      ShowMessage('A KÉRT NAPRÓL NINCS CHECKLISTA');
      exit;
    end;

  AssignFile(_binolvas,_chkPath);
  reset(_binolvas);
  _meret := Filesize(_binolvas);

  blockread(_binolvas,_bytetomb,_meret);
  _zz := 1;
  while _zz<=19 do
    begin
      _chk[_zz] := _bytetomb[_zz]-88;
      inc(_zz);
    end;
  _prosnev := '';
  while _zz<=_meret do
    begin
      _prosnev := _prosnev + chr(255 - _bytetomb[_zz]);
      inc(_zz);
    end;

  OszlopIxelo;  
  NaptarPanel.Visible := False;

   AktnapPanel.Caption := _aktnaps;
   Prosedit.Text := _prosnev;
   with SuperKeys do
     begin
       Top := 600;
       Left := 216;
       Visible := True;
     end;

   Fuggony.visible := false;
end;


procedure TTASKCTRL.Gepadatok;

begin
  _pcs := 'SELECT * FROM HARDWARE';
  ibdbase.connected := true;
  with ibquery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      _aktnaps := FieldByName('MEGNYITOTTNAP').asString;
      _prosnev := trim(FieldByname('PENZTAROSNEV').asstring);
      _printer := FieldByNAme('PRINTER').asInteger;
      Close;
    end;
  ibdbase.close;
end;


procedure TTASKCTRL.Edit1Click(Sender: TObject);
begin
  if _paratipus=1 then exit;
  _tag := Tedit(Sender).tag;
  ChangeCheckJel;
end;


PROCEDURE TTASKCTRL.Oszlopixelo;

var _p: byte;

begin
  _p := 1;
  while _p<=19 do
    begin
      if _chk[_p]=1 then _kk[_p].Brush.Color := clred
      else _kk[_p].Brush.Color := clWhite;
      inc(_p);
    end;
end;


procedure TTASKCTRL.ChangeCheckJel;

begin
  if _chk[_tag]=1 then _chk[_tag] := 0 else _chk[_tag] := 1;
  Oszlopixelo;
end;



procedure TTASKCTRL.ROGZITOGOMBClick(Sender: TObject);

var _biniras: File of byte;
    _wp,_kod: byte;

begin
  _CHKFile := 'CH'+midstr(_aktnaps,3,2)+midstr(_aktnaps,6,2)+midstr(_aktnaps,9,2)+'.CHK';
  _chkPath := _checkdir + '\' + _chkFile;
  if Fileexists(_chkPath) then
    begin
      ShowMessage('A NAPI CHECKFILE MÁR RÖGZITVE VAN !');
      exit;
    end;

  Assignfile(_biniras,_chkpath);
  rewrite(_biniras);

  _zz := 1;
  while _zz<=19 do
     begin
       _bytetomb[_zz] := 88+_chk[_zz];
       inc(_zz);
     end;

  _wp := length(_prosnev);
  _zz := 1;

  while _zz<=_wp do
    begin
      _kod := 255-ord(_prosnev[_zz]);
      _bytetomb[_zz+19] := _kod;
      inc(_zz);
    end;

  _wp := _zz+18;
  blockwrite(_biniras,_bytetomb,_wp);
  CloseFile(_biniras);

  ShowMessage('A CSEKKLISTÁT SIKERESEN RÖGZITETTEM');

  with SuperKeys do
     begin
       Top := 600;
       Left := 216;
       Visible := True;
     end;
end;




procedure TTASKCTRL.NYOMTATOGOMBClick(Sender: TObject);

var _nyomtat,_olvas: textfile;
   _mondat: string;

begin
  Assignfile(_LFile,'c:\valuta\aktlst.txt');
  rewrite(_LFile);

  writeLn(_LFile,_aktnaps+'-i csekklista'+_sorveg);

  writeLn(_LFile,'Penztaros: ' + _prosnev+ _sorveg);

  writeLn(_LFile,'Vegrehajtott feladatok:');
  _zz := 1;
  while _zz<=19 do
    begin
      if _chk[_zz]=1 then
        begin
          writeln(_LFile,'  - '+ leftstr(_w[_zz],32)+' ...');
        end;
      inc(_zz);
    end;
  writeLn(_LFile,_sorveg + _sorveg);
  closeFile(_LFile);

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else AssignPrn(_nyomtat);
  
  Rewrite(_nyomtat);

  AssignFile(_olvas,'c:\valuta\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;

procedure TTASKCTRL.KILEPOTimer(Sender: TObject);
begin
  kILEPO.Enabled := false;
  Modalresult := _mResult;
end;

function TTaskCtrl.HunDatetostr(_caldat: TDateTime): string;

var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho)+'.'+nulele(_h_nap);
end;

function TTaskctrl.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


end.
