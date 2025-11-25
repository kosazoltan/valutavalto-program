unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, StrUtils, Buttons, Psock, ExtCtrls,ShellAPI,
  OleCtrls, WININET, ComCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery;

type
  TNifFileValaszto = class(TForm)

    Csik          : TProgressBar;
    Label1        : TLabel;

    EscapeGomb    : TBitBtn;
    FrissitoGomb  : TBitBtn;
    KivalasztoGomb: TBitBtn;

    KilepoTimer   : TTimer;
    FileLista     : TListBox;

    MemoTabla     : TMemo;
    ValasztoLISTA : TListBox;

    ValQuery      : TIBQuery;
    ValDbase      : TIBDatabase;
    ValTranz      : TIBTransaction;


    procedure EscapeGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FrissitoGombClick(Sender: TObject);
    procedure FTPszerverbeBelep;
    procedure GetPenztarPara;
    procedure KilepoTimerTimer(Sender: TObject);
    procedure NifetValasztott;
    procedure NifValasztas;
    procedure ValasztoListaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ValasztoListaDblClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);

    function GetzaroDatum: string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NifFileValaszto: TNifFileValaszto;

  _findData    : WIN32_FIND_DATA;
  _iras: file of byte;
  _puffer  : array[0..65535] of byte;

  _host       : string;
  _ftpPort    : integer = 21100;
  _userId     : string  = 'ebc-10%';
  _ftpPassword: string  = 'klc+45%';

  _index,_nifDb,_irodaszam: integer;
  _nifTomb,_ftomb: array of string;
  _isor,_minta,_zd,_mintaAlap,_niffilenev,_aktNifFileNev,_pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _jelentesdb,i,_mResult: integer;
  _remote,_local,_zarodstring,_homepenztarszam,_remoteFile,_localFile: string;
  _kapcsolodva,_sikeres: boolean;

  _top,_left,_height,_width,_cc,_wcc: word;
  _srec: TsearchRec;
  _hiWord: pdword;
  _beolvasva: dword;

  _hnet,_hFtp,_hSearch,_hFile: HINTERNET;
  _puffermeret: integer;
  _filemeret: cardinal;


function nifvalasztorutin: integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
             function nifvalasztorutin: integer; stdcall;
// =============================================================================

begin
  niffilevalaszto := TNiffileValaszto.Create(NIL);
  result := niffilevalaszto.showmodal;
  niffilevalaszto.free;
end;


// =============================================================================
          procedure TNIFFILEVALASZTO.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  // Ki kell választani az egyik váltó zarodstring napi jelntését:

  Top      := _top + 180;
  Left     := _left + 180;
  Height   := 500;
  Width    := 680;
  _mresult := 2;

  _kapcsolodva := False;

  KilepoTimer.Enabled := False;
  MemoTabla.Visible := false;

  GetPenztarPara;
  _zarodstring := GetZaroDatum;

     _zd := _zaroDstring;
  _nifDB := 0;

  _mintaAlap := '*'+ midstr(_zD,3,2)+midstr(_zd,6,2)+midstr(_zd,9,2)+'.'+_homepenztarszam;
  _minta := 'c:\ERTEKTAR\jelentes\' + _mintaAlap;

  // Megnézem, hogy van-e egyáltalán jelentés a helyi gépen

  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        inc(_nifDb);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  // Ha egyetlen jelentés sincs a mai napra, akkor frissiteni kell:

  if _nifDb=0 then
    begin
      Showmessage('NEM TALÁLTAM NAPIJELENTÉST. KÉREM FRISSITENI');
      ActiveControl := FrissitoGomb;
      Exit;
    end;

  // Lehet választani a gépen rögzitett NIF-fileok közül:

  NifValasztas;
end;

// =============================================================================
                procedure TNifFileValaszto.NifValasztas;
// =============================================================================

var i: integer;
    _tizes,_egyes: byte;

begin

  // Nifdb darab tétel közül lehet választani:

  _nifdb := 0;
  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        inc(_nifdb);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  Setlength(_niftomb,_nifDb);
  Setlength(_ftomb,_nifDb);

  // A jelentés könyvtárban lévõ kért-dátumú file-okat tömbbe válogatja

  _cc := 0;
  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        _nifTomb[_cc] := _srec.Name;
        inc(_cc);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;

  // A tömbökbe tett fileneveket értelmesebb nevtömbbe másolja: _ftomb

  for i := 0 to (_nifDb-1) do
    begin
      _nifFilenev := _nifTomb[i];
      _tizes := ord(_nifFilenev[1])-48;
      _egyes := ord(_nifFilenev[2])-48;

      if _tizes>9 then _tizes := _tizes-7;

      _irodaszam := trunc(10*_tizes)+_egyes;
      _isor := '                    '+inttostr(_irodaszam)+' SZÁMU IRODA '+_zd+ ' NAPI JELENTÉSE';
      _ftomb[i] := _isor;
     end;

   // Feltölti a választólistát:

  ValasztoLista.Clear;
  for i := 0 to (_nifDb-1) do ValasztoLista.Items.Add(_ftomb[i]);

  // Tessék választani:

  ValasztoLista.ItemIndex := 0;
  ActiveControl := Valasztolista;
end;

// ===========================================================================
         procedure TNifFileValaszto.EscapeGombClick(Sender: TObject);
// ===========================================================================

begin
  Modalresult := 2;
end;

// ===========================================================================
     procedure TNIFFILEVALASZTO.VALASZTOLISTAKeyDown(Sender: TObject;
                                       var Key: Word; Shift: TShiftState);
// ===========================================================================

begin
  if ord(key)=13 then Nifetvalasztott;
end;

// ===========================================================================
               procedure TNIfFileValaszto.NifetValasztott;
// ===========================================================================

begin
  _index := ValasztoLista.ItemIndex;
  _aktNifFileNev := _niftomb[_index];
  _pcs := 'DELETE FROM MEDIA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO MEDIA (STTFILE)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39)+trim(_aktNifFileNev)+chr(39)+')';
  ValutaParancs(_pcs);

  Modalresult := 1;
end;

// ===========================================================================
       procedure TNIFFILEVALASZTO.VALASZTOLISTADblClick(Sender: TObject);
// ===========================================================================

begin
  NifetValasztott;
end;

// $$$$$$$$$$$$$$$$$$$$$$$  ADATFRISSITÉS $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// ===========================================================================
       procedure TNIFFILEVALASZTO.FRISSITOGOMBClick(Sender: TObject);
// ===========================================================================

var i,_jelentesdarab,_jdb: integer;
    _fname,_aktfile: string;

begin

  _mresult := 2;

   Label1.Repaint;
   Memotabla.Visible := True;
   MemoTabla.Repaint;

   // ------------ **************** --------------------------------------------

   _hNet := InternetOpen('JelentesLista',
                         INTERNET_OPEN_TYPE_PRECONFIG,
                         nil,
                         nil,
                         0);

  if _hNet=nil then
    begin
      MemoTabla.Lines.Add('NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT');
      Memotabla.Repaint;
      KIlepoTimer.Enabled := True;
      Exit;
    end;

  // ---------------------------------------------------------------------------

  Memotabla.Lines.add('BELÉPEK A KÖZPONTI SZERVERRE');
  MemoTabla.Repaint;

  FTPSzerverbeBelep;
  if _hFtp=Nil then
    begin
      KilepoTimer.Enabled := true;
      exit;
    end;

  // ---------------------------------------------------------------------------

  Memotabla.Lines.add('BELÉPEK A JELENTÉS KÖNYVTÁRBA');
  Memotabla.Repaint;
  _sikeres := FTPSetCurrentDirectory(_hFTP,pchar('\JELENTES'));
  if not _sikeres then
    begin
      Memotabla.Lines.add('NEM TUDTAM BELÉPNI A JELENTES KÖNYVTÁRBA');
      Memotabla.Repaint;
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      KIlepoTimer.Enabled := True;
      Exit;
    end;

  FileLista.Clear;
  FileLista.Items.Clear;

  Memotabla.Lines.Add('KERESEM A JELENTÉSEKET A SZERVEREN');
  Memotabla.Repaint;

  _hSearch := FTPFindFirstFile(_hFTP,pchar(_mintaAlap),_findData,0,0);
  if _hSearch=nil then
    begin
      MemoTabla.Lines.Add('NEM TALÁLTAM MENTETT JELENTÉST');
      Memotabla.Repaint;
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      KIlepoTimer.Enabled := True;
      Exit;
    end;

  repeat
     _Fname := _findData.cFileName;
     Filelista.Items.Add(_fname);
  until not InternetFindNextFile(_hSearch,@_findData);
  InternetCloseHandle(_hSearch);

  _jelentesdarab := FileLista.Count;
  if _jelentesDarab=0 then
    begin
      Memotabla.Lines.add('NEM TALÁLTAM MENTETT JELENTÉST');
      Memotabla.Repaint;

      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      KIlepoTimer.Enabled := True;
      Exit;
    end;
  _jdb := _jelentesDarab-1;
  _jelentesdarab := 0;
  for i := 0 to _jdb do
    begin
      _aktfile    := FileLista.items[i];
      _remoteFile := _aktfile;
      _localFile  := 'c:\ERTEKTAR\jelentes\' + _aktfile;

      Memotabla.Lines.add(_remotefile + ' LETÖLTÉSE ...');
      Memotabla.Repaint;

      _hFile := FTPOpenFile(_hFTP,
                           pchar(_remotefile),
                           GENERIC_READ,
                           FTP_TRANSFER_TYPE_BINARY,
                           0);

      if _hFile <> nil then
        begin
          _fileMeret := FTPGetFileSize(_hFile,_hiWord);
          Csik.Max := _filemeret;
          Csik.Position := 0;
          Csik.Repaint;

          assignFile(_iras, _localfile);
          rewrite(_iras);

          if IOResult<>0 then
            begin
              InternetCloseHandle(_hFile);
              Continue;
            end;

          _sikeres := True;
          _wcc := 0;
          while (_fileMeret>0) do
            begin
              if _filemeret>=4096 then _puffermeret := 4096 else _puffermeret := _filemeret;
              if not InternetReadFile(_hFile,@_puffer,_puffermeret,_beolvasva) then
                begin
                  _sikeres := False;
                  break;
                end;
              BlockWrite(_iras,_puffer,_beolvasva);
              _fileMeret := _filemeret - _beolvasva;
              _wcc := _wcc + _beolvasva;
              Csik.Position := _wcc;
              Csik.Repaint;
            end;

          CLoseFile(_iras);
          InternetCloseHandle(_hFile);
          if _sikeres then  inc(_Jelentesdarab);
        end;  // _hFile end
    end;  // For ciklus vége till JELETESdarab-1

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  MemoTabla.Lines.Add(inttostr(_JelentesDarab)+' JELENTÉST LETÖLTÖTTEM');
  MemoTabla.Repaint;
  Sleep(1800);

   // ------------ **************** --------------------------------------------

  Memotabla.Visible := False;
  NifValasztas;
end;

// =============================================================================
        procedure TNifFileValaszto.KilepoTimerTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := False;
  ModalResult := _mResult;
end;

// =============================================================================
              function TNifFileValaszto.GetZaroDatum: string;
// =============================================================================

begin
  Valdbase.Connected := true;
  with ValQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      result:= trim(FieldByNAme('DATUM').AsString);
      Close;
    end;
  Valdbase.close;
end;

// =============================================================================
              procedure TNifFileValaszto.GetPenztarPara;
// =============================================================================

begin
  Valdbase.Connected := true;
  with ValQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _host := trim(FieldByNAme('HOST').asString);
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homepenztarszam := trim(FieldByNAme('PENZTARKOD').asstring);
      close;
    end;
  Valdbase.close;
end;

// =============================================================================
              procedure TNifFileValaszto.ValutaParancs(_ukaz: string);
// =============================================================================

begin
 Valdbase.connected := true;
 if valtranz.InTransaction then valtranz.Commit;
 Valtranz.StartTransaction;
 with Valquery do
   begin
     Close;
     sql.clear;
     sql.add(_ukaz);
     ExecSql;
   end;
 Valtranz.Commit;
 Valdbase.close;
end;

// =============================================================================
                      procedure TnIFfILEvALASZTO.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := Nil;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then
    begin
      ShowMessage('NEM TALÁLOM A WININET.DLL KÖNYVTÁRAT');
      Exit;
    end;

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------

  if _hFTP=nil then
    begin
      ShowMessage('A KÖZPONTI SZERVER NEM ÉRHETÕ EL');
      InternetCloseHandle(_hNet);
    end;
end;
end.

