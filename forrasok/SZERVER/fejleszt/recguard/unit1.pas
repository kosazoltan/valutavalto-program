unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, TlHelp32, Strutils, IBDatabase, DB, IBCustomDataSet,
  IBQuery;

type
  TForm1 = class(TForm)
    Ciklus     : TTimer;

    ReceptDbase: TIBDatabase;
    ReceptQuery: TIBQuery;
    ReceptTranz: TIBTransaction;
    JEL: TPanel;
    KAMERAQUERY: TIBQuery;
    KAMERADBASE: TIBDatabase;
    KAMERATRANZ: TIBTransaction;

    procedure CiklusTimer(Sender: TObject);
    procedure FormActivate(Sender: TObject);

    procedure GarbageCollection;
    procedure Futascontrol;
    procedure GepujraInditas;
    procedure GetDatumIdo;
    procedure ReceptorLeallitas;

    procedure Logbair(_mess: string);
    procedure RunReceptor;
    procedure CsomagClear;
    procedure ReceptParancs(_ukaz: string);

    function Futareceptor: boolean;

    function GetCamDatum(_cf: string): string;
    function MukodikAReceptor: boolean;
    function Percszamito(_idos: string): integer;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1       : TForm1;

  _ddir       : array[0..149] of string;
  _bytetomb   : array[1..2] of byte;

  _binolvas   : file of byte;
  _txtiras    : Textfile;

  _rebootPath : string = 'c:\receptor\reboot.flg';
  _kameradir  : string = 'd:\kamera\upload\kamera';
  _signPath   : string = 'c:\receptor\sign.data';
  _breakPath  : string = 'c:\receptor\break';
  _logdir     : string = 'c:\receptor\log';
  _ctrlFile   : string = 'WRECEPT.EXE';

  _camClear,_pcs : string;
  _sorveg     : string = chr(13) + chr(10);

  proc        : PROCESSENTRY32;
  _handle     : HWND;
  _Looper     : BOOL;

  _srec       : TSearchrec;
  _szin       : TColor;
  _bszin      : Tcolor;


  _aktword,
  _lastword   : word;

  _dirdb,
  _futascount,
  _qq         : integer;

  _elinditva  : boolean;

  _aktdir,
  _aktidos,
  _aktoras,
  _camfile,
  _camdatums,
  _condLastDays,
  _delpath,
  _idos,
  _lastgoodDays,
  _lgdys,
  _mamas,
  _minta,
  _oname,
  _oPath      : string;

  _fut        : boolean;


function WindowsExit(RebootParam: Longword): Boolean;

implementation

{$R *.dfm}

// =============================================================================
                procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin

  // Kis négyzet a bal-felsõ sarokban:

  Top    := 0;
  Left   := 0;
  width  := 25;
  Height := 25;

  _futascount := 6;   // fél percenként futáscontrol

  // Két string beolvasás: Pl. _mamas='2014.08.12' _aktoras='09'

  GetdatumIdo;

  // Törli a reboot flaget, jelzi, hogy volt ma már reboot;
  // RebootPath = 'c:\receptor\reboot.flg'

  if fileExists(_rebootPath) then Sysutils.DeleteFile(_rebootPath);

  _szin     := clwhite;

  Logbair('Recguard elindult');
//  Csomagclear;
  Logbair('Csomagnev törölve a rendszer táblában');

  FutasControl;
  GarbageCollection;

   // Elinditja a ciklustimert: 10 másodpercenként indul

  Ciklus.Enabled := true;

end;

// =============================================================================
                procedure TForm1.CIKLUSTimer(Sender: TObject);
// =============================================================================

begin

  // Ciklustimer leállítva:

  Ciklus.Enabled := False;
  if _szin=clwhite then
    begin
      _szin := clBlack;
      _bszin:= clWhite;
    end
    else
    begin
      _szin := clwhite;
      _bszin := clBlack;
    end;

  dec(_futascount);

  Jel.Color := _szin;
  Jel.Font.color := _bszin;
  Jel.Caption := inttostr(_futascount);
  Jel.repaint;

  if _futascount<1 then FutasControl;

  // Meghatározza a pillanatnyi napot és órát:

  GetDatumIdo;  // _mamas,_aktidos,_aktoras

  // Ha éjjel 1 óra és 2 óra között van az idõ és még nem kérte az újrainditást
  // akkor jelzi, hogy a gépet majd 3 után inditani kell:

  if (_aktoras='01') then
    begin
      if not FileExists(_rebootPath) then
        begin
          Assignfile(_txtiras,_rebootPath);
          Rewrite(_txtiras);
          WriteLn(_txtiras,'Kell reboot');
          Closefile(_txtiras);
          Logbair('1 óra elmúlt - ûjrainditást elöjegyezni !');
          Logbair('Újra-inditás jelzö felirva ! (c:\receptor\reboot.flg)');
        end;
    end;

  // Ha elmúlt éjjel 2 óra és az újrainditás kérelmezve van akkor
  // a gépet tényleg újrainditja:

  GetDatumIdo;
  if (_aktoras='02') then
    begin
      if FileExists(_rebootPath) then
        begin
          Logbair('2 óra elmúlt. Hajnali munkákat kell elvégezni:');
          GarbageCollection;
          Sysutils.DeleteFile(_rebootPath);
          ReceptorLeallitas;
          Logbair('Gépet újra inditja most ...');
          GepUjrainditas;
          exit;
        end;
    end;

  Ciklus.Enabled := True;
end;


// =============================================================================
                      procedure TForm1.RunReceptor;
// =============================================================================

begin
  Logbair('Receptor gépi inditása');
  Winexec(pchar('c:\receptor\wrecept.exe'),sw_shownormal);
end;


// =============================================================================
              procedure TForm1.GarbageCollection;
// =============================================================================

var _lastgood: TDateTime;
    _hatardatums: string;

begin
  Logbair('Indul a garbage-collector');

  receptdbase.connected := true;
  with ReceptQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM RENDSZER');
      Open;
      _camclear := FieldByName('CAMCLEAR').asString;
      Close;
    end;
  ReceptDbase.close;

  Logbair(_camclear + ' = '+ _mamas);
  if _camclear = _mamas then
    begin
      Logbair('Ma már volt szemétgyüjtés - Kilépek');
      exit;
    end;

  Logbair('Régi kamera fileok törlésének kezdete');
   // Az utolsó tárolandó kamera nap a 10 nappal ezelötti:

  _lastgood := Date-3;
  _lgdys := leftstr(datetostr(_lastgood),10);
  _condLastDAys := midstr(_lgdys,3,2)+midstr(_lgdys,6,2)+midstr(_lgdys,9,2);
  Logbair('Az utolsó jó tömöritett dátum: ' + _condlastDays);
  _minta    := _kameradir + '\*.*';

  // ----- Megszámolja, hány kamera directory van ------------------------------

  _dirdb := 0;
  if FindFirst(_minta,faDirectory, _srec)= 0 then
    begin
      repeat
        if _srec.Attr = 16 then
          begin
            _ddir[_dirdb] := _srec.Name;
            inc(_dirdb);
          end;
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  Logbair('Összesen ' + inttostr(_dirdb)+ ' kamera pénztárt találtam');

  // ---------- Végigmegy az összes kameradirectoryn ---------------------------

  _qq := 0;
  while _qq<_dirdb do
    begin
      _aktdir := _kameradir + '\'+ _ddir[_qq];
      _minta  := _aktdir + '\*.C1';

      Logbair(inttostr(_qq)+'. Directory: '+ _minta);

      // Az aktdirbõl törli a régi 'C1'-kiterjesztésü fileokat, ha azok
      // 4 napnál régebbiek:

      if FindFirst(_minta,faanyFile,_srec)=0 then
        begin
          repeat
            _camfile := _srec.Name;
            _camDatums := getcamdatum(_camfile);

            if _camdatums<_condLastDays then
              begin
                _delpath := _aktdir + '\' + _camfile;
                Sysutils.DeleteFile(_delPath);
                Logbair('Törlöm: '+_delPath);

              end;
          until FindNext(_srec)<>0;
          FindClose(_sRec);
        end;

      Logbair('------------------------------');  
      Logbair('Következö pénztár ...');
      // Következõ kamera directory;
      inc(_qq);
    end;

  Logbair('Régi (4 napos) kamerafile-k törölve.');

  _pcs := 'UPDATE RENDSZER SET CAMCLEAR='+chr(39)+_mamas+chr(39);
  ReceptParancs(_pcs);

  Logbair('Utolsó garbage-collection végrehajtva: ' + _mamas+'-i napon');
end;

// =============================================================================
            function TForm1.GetCamDatum(_cf: string): string;
// =============================================================================

var _pos: byte;

begin
  _pos := Pos('.',_cf);
  _pos := _pos - 9;
  result := midstr(_cf,_pos,6);
end;

// =============================================================================
                     procedure TForm1.GepUjraInditas;
// =============================================================================

begin
  WindowsExit(EWX_REBOOT or EWX_FORCE)
end;

// =============================================================================
              function WindowsExit(RebootParam: Longword): Boolean;
// =============================================================================

var
   TTokenHd: THandle;
   TTokenPvg: TTokenPrivileges;
   cbtpPrevious: DWORD;
   rTTokenPvg: TTokenPrivileges;
   pcbtpPreviousRequired: DWORD;
   tpResult: Boolean;

const
   SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';

begin
   if Win32Platform = VER_PLATFORM_WIN32_NT then
   begin
     tpResult := OpenProcessToken(GetCurrentProcess(),
       TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY,
       TTokenHd) ;
     if tpResult then
     begin
       tpResult := LookupPrivilegeValue(nil,
                                        SE_SHUTDOWN_NAME,
                                        TTokenPvg.Privileges[0].Luid) ;
       TTokenPvg.PrivilegeCount := 1;
       TTokenPvg.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
       cbtpPrevious := SizeOf(rTTokenPvg) ;
       pcbtpPreviousRequired := 0;
       if tpResult then
         Windows.AdjustTokenPrivileges(TTokenHd,
                                       False,
                                       TTokenPvg,
                                       cbtpPrevious,
                                       rTTokenPvg,
                                       pcbtpPreviousRequired) ;
     end;
   end;
   Result := ExitWindowsEx(RebootParam, 0) ;
end;


// =============================================================================
                        procedure TForm1.Getdatumido;
// =============================================================================

begin
  _mamas := leftstr(datetostr(date),10);
  _aktidos := timetostr(Time);
  if midstr(_aktidos,2,1)=':' then _aktidos := '0' + _aktidos;
  _aktoras := leftstr(_aktidos,2);
end;


// =============================================================================
                  procedure TForm1.Logbair(_mess: string);
// =============================================================================

var _vanlog: boolean;
    _logfile,_logpath: string;
    _textiras: TextFile;

begin
  GetDatumido;
  _logfile := 'RG' + midstr(_mamas,3,2)+midstr(_mamas,6,2)+midstr(_mamas,9,2)+'.txt';
  _logPath := 'c:\receptor\log\' + _logfile;
  _vanlog := False;
  if FileExists(_logpath) then _vanlog := True;

  Assignfile(_textiras,_logpath);
  if _vanlog then append(_textiras) else Rewrite(_textIras);
  writeln(_textiras,_aktidos+': '+_mess);
  CloseFile(_textiras);
end;

// =============================================================================
                  function TForm1.MukodikAReceptor: boolean;
// =============================================================================

var _csomag,_feldstartido: string;
    _eltelt,_munkaperc: integer;
    _sumaktperc,_sumMunkaPerc: integer;
    
begin
  result := false;
  if Futareceptor=False then exit;
  Logbair('A receptor fut');

  _pcs := 'SELECT * FROM RENDSZER';
  ReceptDbase.Connected := true;
  with ReceptQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _csomag := trim(FieldByName('CSOMAGNEV').asstring);
      _feldStartido := trim(FieldByName('FELDSTARTIDO').asstring);
      close;
    end;
  Receptdbase.close;

  Logbair('A futó neve: ' + _csomag + '  Kezdte: '+_feldStartIdo);

  // ---------------------------------------------------------------------------

  result := true;
  if _csomag='' then exit;
  if _feldstartido='' then exit;

  _munkaperc := 2;
  if _csomag='MENTES' then _munkaperc := 40;
  if (_csomag='TABLO') or (_csomag='KEDVEZMENY') then _munkaperc := 6;
  if _csomag='EGYEB' then _munkaperc :=3;
  Getdatumido;
  _sumaktperc := percszamito(_aktidos);
  _sumMunkaperc := percszamito(_feldstartido);

  _eltelt := abs(_sumaktperc-_sumMunkaperc);
  jel.color := clyellow;
  jel.Caption := inttostr(_eltelt);
  jel.Repaint;
  sleep(2500);
  Logbair('Eltelt: '+inttostr(_eltelt)+' Munkaperc: '+inttostr(_munkaperc));
  if _eltelt>_munkaperc then result := False;
end;

// =============================================================================
            function TForm1.Percszamito(_idos: string): integer;
// =============================================================================

var _qora,_qperc: integer;

begin
  _qora := strtoint(leftstr(_idos,2));
  _qperc:= strtoint(midstr(_idos,4,2));

  result := _qperc + trunc(60*_qora);
end;

// =============================================================================
              function Tform1.FutaReceptor: boolean;
// =============================================================================


var
  _fileName,_filePath: String;

begin

  Result := False;
  Proc.dwSize := SizeOf(Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,proc);

  while Integer(_Looper) <> 0 do
    begin
       _filepath := Proc.szExeFile;
      _fileName := ExtractFileName(_filepath);
      if uppercase(_fileName) = _ctrlFile then
        begin
          Result := True;
          exit;
        end;
      _Looper := Process32Next(_handle,proc);
    end;
  CloseHandle(_handle);
  Logbair('A receptor nem fut a rendszerben !');
end;

// =============================================================================
                     procedure TForm1.Futascontrol;
// =============================================================================

begin
  _futascount := 6;
  Logbair('Futás-kontrol indul');
  if MukodikaReceptor then exit;

  Logbair('A receptor leállt. Újrainditás szükséges !');

  ReceptorLeallitas;
  sleep(2500);
  Runreceptor;
//  CsomagClear;
  _futascount := 6;
end;

// =============================================================================
                   procedure TForm1.ReceptorLeallitas;
// =============================================================================

var
  _fName,_filePath: String;

begin

  Proc.dwSize := SizeOf(Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,proc);

  while Integer(_Looper) <> 0 do
    begin
       _filepath := Proc.szExeFile;
      _fName := uppercase(ExtractFileName(_filepath));
      if (_fName='WRECEPT.EXE')  then
        begin
          Logbair('A receptort leállitom');
          TerminateProcess(OpenProcess(1,Bool(1),proc.th32ProcessID),0);
          Break;
        end;

      _Looper := Process32Next(_handle,proc);
    end;
  CloseHandle(_handle);
end;


// =============================================================================
                 procedure TForm1.ReceptParancs(_ukaz: string);
// =============================================================================


begin
  ReceptDbase.Connected := true;
  if ReceptTranz.InTransaction then recepttranz.Commit;
  ReceptTranz.StartTransaction;
  with ReceptQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ReceptTranz.commit;
  Receptdbase.close;
end;

// =============================================================================
                       procedure TForm1.Csomagclear;
// =============================================================================

begin
  _pcs := 'UPDATE RENDSZER SET CSOMAGNEV='+CHR(39)+CHR(39)+',FELDSTARTIDO='+chr(39)+chr(39);
  ReceptParancs(_pcs);
end;
end.
