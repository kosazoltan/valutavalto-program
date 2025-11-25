unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, jpeg, Buttons, IBDatabase, DB, IBQuery,
  IBCustomDataSet, IBTable, DelphiTwain, strUtils, idGlobal;

type
  TForm2 = class(TForm)

    DispPanel    : TPanel;
    MessPanel    : TPanel;
    Panel1       : TPanel;

    BalNyil      : TImage;
    JobbNyil     : TImage;
    ImDisplay    : TImage;

    ValutaTabla  : TIBTable;
    ValutaQuery  : TIBQuery;
    ValutaDbase  : TIBDatabase;
    ValutaTranz  : TIBTransaction;

    Shape1       : TShape;
    Shape2       : TShape;
    Shape3       : TShape;

    ScanGomb     : TBitBtn;
    VisszaGomb   : TBitBtn;

    Label2       : TLabel;
    Label3       : TLabel;
    Label4       : TLabel;
    Label5       : TLabel;

    Twain        : TDelphiTwain;

    FileNevEdit  : TEdit;
    UgyfelNevEdit: TEdit;
    ResultPanel  : TPanel;
    Label1       : TLabel;
    IgenGomb     : TBitBtn;
    RetryGomb    : TBitBtn;
    MegsemGomb   : TBitBtn;
    Shape4       : TShape;
    Label6       : TLabel;
    SdbPanel     : TPanel;
    DriverCombo  : TComboBox;
    Label7       : TLabel;
    SourcePanel  : TPanel;
    Label8       : TLabel;
    CheckVisible : TCheckBox;

    procedure AdatBeolvasas;
    procedure VisszaGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure OldDocsDisplay;
    procedure JobbNyilClick(Sender: TObject);
    procedure BalNyilClick(Sender: TObject);
    procedure ScanGombClick(Sender: TObject);
    procedure SourceManagerBetoltes;
    procedure KepHelyreMasolas;
    procedure IgenGOMBClick(Sender: TObject);
    procedure MegsemGombClick(Sender: TObject);
    procedure RetryGombClick(Sender: TObject);
    procedure DriverComboClick(Sender: TObject);

    function BMPkonvertalo: boolean;
    function WinExecAndWait32(Path: PChar; Visibility: Word): integer;


  private
    { Private declarations }
    TransferMode: TTwainTransferMode;

  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _bedir: string = 'c:\valuta\in';
  _tempOkmanyPath : string = 'c:\valuta\in\okmany.bmp';
  _tempJpegPath : string = 'c:\valuta\in\okmany.jpg';
  _okmfile: array[0..99] of string;

  _srec: TSearchRec;

  _ugyfelszam,_mbszam,_aktsource,_sourceDarab,_ss,_mResult,_aktindex: integer;
  _height,_width,_top,_left,_aktJpgSs,_jpgDb,_hplus,_wPlus,_sdb: word;

  _usz,_ugyfeltipus,_minta,_ugyfeldir,_ugyfelnev: string;
  _aktOkmFile,_aktOkmPath,_prName,_targetfile,_targetPath: string;
  _targetnev,_sourcePath,_aktsourcenev,_pcs: string;

  _pacs: pchar;
  _ujdir,_siker,_driveroke,_lathato: boolean;


function ujokmanyszkennelo: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
              function ujokmanyszkennelo: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.ShowModal;
  Form2.Free;
end;

// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _top  := round((_height-670)/2);
  _left := round((_width-871)/2);

  Top    := _top;
  Left   := _left;
  Height := 670;
  Width  := 871;

  if not DirectoryExists(_bedir) then CreateDir(_bedir);
  _mResult := -1;

  if FileExists(_tempOkmanyPath) then Sysutils.DeleteFile(_tempOkmanyPath);
  if FileExists(_tempJpegPath) then Sysutils.DeleteFile(_tempJpegPath);

  Adatbeolvasas;

  If (_ugyfelszam=0) or (_ugyfeltipus='') then
    begin
      ShowMessage('NINCS ÜGYFÉLSZÁM - NEM LEHET SZKENNELNI');
      VisszagombClick(Nil);
      Exit;
    end;

  SourceManagerBetoltes;
  if _sdb=0 then
    begin
      showMessage('NEM TUDOK SZKENNELNI ! NINCS FORRÁS');
      VisszagombClick(Nil);
      exit;
    end;

  _usz := inttostr(_ugyfelszam);
  Balnyil.Visible  := False;
  Jobbnyil.Visible := False;

  if _ugyfelnev<>'' then
    begin
      UgyfelnevEdit.text := _ugyfelnev;
      Ugyfelnevedit.repaint;
    end;

  if _ugyfeltipus='W' then _usz := 'W' + _USZ;
  if _ugyfeltipus='J' then _usz := inttostr(_mbszam);

  _ujdir := False;
  _ugyfeldir := 'c:\valuta\scans\'+_usz;
  if not DirectoryExists(_ugyfeldir) then
    begin
      CreateDir(_ugyfeldir);
      _ujdir := True;
    end;

  _jpgDb := 0;
  if not _ujdir then
    begin
      _minta := _ugyfeldir + '\*.jpg';
      if FindFirst(_minta,faAnyFile,_srec)=0 then
        begin
          repeat
            _okmfile[_jpgDb] := _srec.name;
            inc(_jpgDb);
          Until Findnext(_srec)<>0;
          Findclose(_srec);
        end;
    end;

  _aktJpgSs := 0;
  if not _ujdir then
    begin
      if _jpgDb>0 then
        begin
          OldDocsDisplay;
        end;
    end;
  ActiveControl := ScanGomb;
end;

// =============================================================================
                      procedure TForm2.Adatbeolvasas;
// =============================================================================

begin
  valutadbase.connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      _ugyfelszam  := FieldByName('UGYFELSZAM').asInteger;
      _ugyfeltipus := FieldByNAME('UGYFELTIPUS').asString;
      _ugyfelnev   := trim(FieldByName('UGYFELNEV').AsString);
      _mbszam      := FieldBynAme('MEGBIZOSZAM').asInteger;
      Close;
    end;
  Valutadbase.close;
end;

// =============================================================================
                       procedure TForm2.OldDocsDisplay;
// =============================================================================

begin
  Balnyil.Visible  := False;
  Jobbnyil.Visible := False;

  _aktOkmFile := _okmfile[_aktJpgSs];
  _aktOkmPath := _ugyfeldir + '\' + _aktOkmFile;
  ImDisplay.Picture.LoadFromFile(_aktOkmPath);

  FileNevEdit.Text := _aktOkmFile;
  FileNevEdit.repaint;

  if _jpgDb=1 then exit;

  if _jpgDb>(1+_aktJpgSs) then JobbNyil.Visible := True;
  if _aktJpgSs>0 then Balnyil.Visible := True;
end;

// =============================================================================
                procedure TForm2.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  with ResultPanel do
    begin
      top := 400;
      left:= 136;
      Visible := True;
      Repaint;
    end;

  if _mresult=1 then Activecontrol := Igengomb
  else ActiveControl := Megsemgomb;
end;

// =============================================================================
            procedure TForm2.JOBBNYILClick(Sender: TObject);
// =============================================================================

begin
  inc(_aktJpgSs);
  OldDocsDisplay;
end;

// =============================================================================
              procedure TForm2.BALNYILClick(Sender: TObject);
// =============================================================================

begin
  dec(_aktJpgSs);
  OldDocsDisplay;
end;

// =============================================================================
               procedure TForm2.SCANGOMBClick(Sender: TObject);
// =============================================================================

begin
  MessPanel.Caption  := 'Szkennelés folyamatban ...';
  MessPanel.repaint;

  _lathato := True;
  if not checkvisible.checked then _lathato := False;

  ScanGomb.Enabled   := False;

  if FileExists(_tempOkmanyPath) then Sysutils.DeleteFile(_tempOkmanyPath);

  Twain.Source[_aktSource].Loaded := TRUE;
  Twain.Source[_aktSource].TransferMode := Self.TransferMode;  {Enable source}

 // Twain.Source[_aktSource].SetIXResolution(400);
 // Twain.Source[_aktSource].SetIYResolution(700);

  // Twain.Source[_aktSource].SetImagelayoutFrame(0,0,400,700);

 Twain.Source[_aktsource].setupFileTransfer(_tempOkmanyPath,tfBmp);

  TRY
    Twain.Source[_aktSource].EnableSource(_lathato,False);
    while Twain.Source[_aktSource].Enabled do Application.ProcessMessages;
  EXCEPT
    on E: exception do showmessage(e.ClassName+' error '+e.Message);
  END;

  sleep(5000);

  ScanGomb.Enabled := True;

  if fileExists(_tempOkmanyPath) then
    begin
      KepHelyreMasolas;
      if _siker then
        begin
          MessPanel.caption := 'SIKERES OKMÁNY BEOLVASÁS';
          IMDisplay.Picture.LoadFromFile(_tempOkmanyPath);
          _mResult := 1;
        end else _mResult := -1;
    end else
    begin
       MessPanel.caption := 'SIKERTELEN OKMÁNY SZKENNELÉS';
       _mResult := -1;
    end;
   MessPanel.Repaint;
end;

// =============================================================================
                   procedure TForm2.SourceManagerBetoltes;
// =============================================================================

begin
  Twain.SourceManagerLoaded := TRUE;
  _sourceDarab := TWain.SourceCount;
  _sdb := _sourceDarab;

  SDBPanel.caption := inttostr(_sDb);
  SdbPanel.Repaint;
  if _sdb=0 then
    begin
      MessPanel.Caption := 'NEM TALÁLTAM TWAIN FORRÁST !';
      MessPanel.repaint;
      exit;
    end;

  _aktSource := 0;
  drivercombo.Items.clear;
  drivercombo.clear;

  _driverOke := False;
  _ss := 0;
  while _ss<_sourceDarab do
    begin
      _prName := Twain.Source[_ss].productname;
      drivercombo.Items.add(_prname);
      if LEFTSTR(_prName,12)='WIA-CanoScan' then _aktsource := _ss;
      inc(_ss);
    end;
  Drivercombo.ItemIndex := _sdb-1;
  driverComboClick(Nil);

end;

// =============================================================================
                   procedure TForm2.KepHelyreMasolas;
// =============================================================================

begin
  _siker := False;
  _targetnev := _usz+'-'+inttostr(_jpgDb)+'.jpg';
  if not BmpKonvertalo then exit;

  FileNevEdit.Text := _targetnev;
  Filenevedit.repaint;

  inc(_jpgDb);

  _targetpath := _ugyfelDir + '\' + _targetnev;
  _sourcepath := _tempOkmanyPath;

  _siker := copyfileto(_sourcePath,_targetPath);
end;

// =============================================================================
              procedure TForm2.IGENGOMBClick(Sender: TObject);
// =============================================================================

begin
  Twain.UnloadLibrary;
  Modalresult := 1;
end;

// =============================================================================
             procedure TForm2.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Twain.UnloadLibrary;
  Modalresult := -1;
end;

// =============================================================================
             procedure TForm2.RETRYGOMBClick(Sender: TObject);
// =============================================================================

begin
  ResultPanel.Visible := False;
  ScanGombClick(Nil);
end;

// =============================================================================
               procedure TForm2.DRIVERCOMBOClick(Sender: TObject);
// =============================================================================

begin
  _aktindex  := drivercombo.itemindex;
  _aktsourcenev := drivercombo.Items[_aktindex];
  SourcePanel.Caption := _aktsourcenev;
  Sourcepanel.repaint;
  Scangomb.Enabled := true;
end;

// =============================================================================
   function TForm2.WinExecAndWait32(Path: PChar; Visibility: Word): integer;
// =============================================================================

var Msg: TMsg;
    lpExitCode: cardinal;
    StartupInfo: TStartupInfo;
    ProcessInfo: TProcessInformation;

begin
  FillChar(StartupInfo, SizeOf(TStartupInfo), 0);
  with StartupInfo do
    begin
      cb := SizeOf(TStartupInfo);
      dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
      wShowWindow := visibility; {you could pass sw_show or sw_hide as parameter}
    end;

  if CreateProcess(nil, path, nil, nil, False, NORMAL_PRIORITY_CLASS,
                                      nil, nil, StartupInfo,ProcessInfo) then

    begin
      repeat
        while PeekMessage(Msg, 0, 0, 0, pm_Remove) do
          begin
            if Msg.Message = wm_Quit then Halt(Msg.WParam);
            TranslateMessage(Msg);
            DispatchMessage(Msg);
          end;

        GetExitCodeProcess(ProcessInfo.hProcess,lpExitCode);
      until lpExitCode <> Still_Active;

    with ProcessInfo do {not sure this is necessary but seen in in some code elsewhere}
      begin
        CloseHandle(hThread);
        CloseHandle(hProcess);
      end;

    Result := 0; {success}
  end else Result := GetLastError;
end;

function TForm2.BMPkonvertalo: boolean;

begin
  result := False;
  if FileExists(_targetnev) then sysutils.DeleteFile(_targetnev);
  if not FileExists(_tempOkmanyPath) then exit;

  _pcs := 'c:\valuta\bin\nconvert.exe -out jpeg -quiet -o ' + _targetnev;
  _pcs := _pcs + ' ' + _tempJpegPath;

  _pacs := pchar(_pcs);
  WinexecAndWait32(_pacs,sw_hide);
  result := True;
end;
end.
