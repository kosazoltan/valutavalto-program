unit Unit6;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, wininet, strutils, Buttons, dateutils,
  Psock;

type
  TAdatSzetkuldes = class(TForm)

    Indito      : TTimer;
    ErrorPanel  : TPanel;
    Panel1      : TPanel;
    RendbenPanel: TPanel;

    Label1      : TLabel;
    Label2      : TLabel;

    ListBox1    : TListBox;

    procedure FormActivate(Sender: TObject);
    procedure InditoTimer(Sender: TObject);

    procedure ujDataFileWrite;
    procedure RemoteFileDelete;

    function UploadFiles: boolean;
    function Nulele(_b: byte): string;

    procedure ArfolyamKiiro(_ddb: integer);
    procedure ByteIras(_bb: byte);
    procedure FloatIras(_rr: real;_vs: integer);
    procedure WordIras(_ww: word);

    procedure KonfirmGombClick(Sender: TObject);
    function VanInternet: boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AdatSzetkuldes: TAdatSzetkuldes;

  _hSearch: Hinternet;

  _arfs : array[1..9] of string;
  _pcsop: array[1..200] of byte;
  _iras : File of byte;

  _aktcs,
  _aktport,
  _mresult,
  _valss,
  _xx,
  _zz: integer;

  _aktarfs,
  _akthost,
  _mess,
  _pontosIdostring,
  _ujdataName,
  _ujdataPath: string;
  

  _aktarfolyam: real;

  _aktword,
  _ora,
  _perc,
  _masodperc,
  _evtized,
  _honap,
  _nap: word;

  _pecsOke,
  _bcsabaOke: boolean;


implementation

uses Unit1, Unit12;

{$R *.dfm}

// =============================================================================
          procedure TADATSZETKULDES.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := 230;
  Left := 460;

  ErrorPanel.Visible   := False;
  RendbenPanel.Visible := False;

  Indito.Enabled := true;
end;

// =============================================================================
             procedure TADATSZETKULDES.INDITOTimer(Sender: TObject);
// =============================================================================

var i: integer;

begin
  Indito.Enabled := False;
  _mresult := 4;

  Listbox1.Items.clear;
  Listbox1.Clear;

  // A munkakönyvtárba beállítja a temp-fileokat:

  _ujdataPath  := _workdir + '\ujdata.dat';

  // ---------------------------------------------------------------------------

  // A 200 byte-os csoport tömb meghatározása: -> _pCSop[1..200] 0-54 között

  for i := 1 to 200 do
    begin
      _xx := Form1.ScanIrSors(i);
      _aktcs := 0;
      if _xx>0 then _aktcs := _ptarcsop[_xx];
      _pcsop[i] := _aktcs;
    end;

  // ---------------------------------------------------------------------------

  // Elkésziti a szétküldendö file-t:

  Listbox1.Items.add('Az árfolyamfile összeállítása');
  Listbox1.Repaint;

  // Elkésziti az újtipusú NR - file
  ujDataFileWrite;

  // ---------------------------------------------------------------------------
  // A két file-t megpróbálja feltölteni a szerverre:

  Listbox1.Items.Add('Az árfolyamok szerverre töltése');
  ListBox1.Repaint;

  if not VanInternet then
    begin
      ShowMessage('Nincs internetkapcsolat ! A feltöltés nem lehetséges');
      ModalResult := 4; // 4 jelzi hogy egyikre sikerült feltölteni
      exit;
    end;

  _hnet := InternetOpen('SaveToServer',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);

  if _hNet = nil then
    begin
      Listbox1.Items.Add('Nem tudtam fellépni az internetre ...');
      Listbox1.Repaint;
      Sleep(200);
      Modalresult := 4;  // 4= egyikre sem sikerült feltölteni
      exit;
    end;

  _BcsabaOke:= UpLoadFiles;

  if (not _bcsabaOke) then
    begin
      ErrorPanel.Caption := 'SIKERTELEN ÁRFOLYAMTERÍTÉS';
      _mResult := 4;
      ErrorPanel.Visible := true;
      ErrorPanel.Repaint;

      sleep(3000);
      ModalResult := 4;

      exit;
    end;


  // ---------------- ITT MINDEN RENDBEN KI VAN IRVA ---------------------------

  RendbenPanel.Visible := True;
  RendbenPanel.Repaint;

  Modalresult := 1;
end;




// =============================================================================
             procedure TadatSzetkuldes.UjDataFileWrite;
// =============================================================================

var _aktidos: string;

begin
  {
    arfolyamfile neve = 'NRddhhmm.dat'

    1 Byte   = verzió = 15
    200 byte = pénztárak csoportkódja
    54 csoport= 28 valutanem - 9 munka oszlopa - 5 byton = 1260
                + 6 byteon a 3 limit
                1 csoport összesen = 1266 byte
    Összes csoport összesen: 54 * 1266 = 68040 byte

    Teljes file : 1 (verzió) + 200 (csoport) + 65934 (árfolyam+limit) + 3 byte (záró)

    Teljes file hossz = 68244

    Csoport kezdöbyte= 201 + (csoport-1)*1266

  }

  _aktIdos := trim(timetostr(now));
  if midstr(_aktidos,2,1)=':' then _aktidos := '0' + _aktidos;
  _nap := dayof(Date);

  _ujDataName := 'NR' + nulele(_nap)+ leftstr(_aktidos,2)+midstr(_aktidos,4,2)+'.DAT';

  Assignfile(_iras,_ujDataPath);
  Rewrite(_iras);

  _bytetomb[1] := 16;  //   16-es verzió
  Blockwrite(_iras,_bytetomb,1);

  // ---------------------------------------------------------------------------

  // A 200 hosszú csoportbyte füzér felirása

  BlockWrite(_iras,_pcsop,200);

  // Végigmegy az összes aktiv munkacsoporton:

  _aktcsoport := 1;
  while _aktcsoport<=54 do
    begin

      ArfolyamKiiro(28); // 28 valutanem 7-7 árfolyamát irja ki !  byte

      //  Kedvezmény limitek az aktuális munkacsoportra 3*2 byte = 6 byte

      _zz := 1;
      while _zz<=3 do
        begin
          _aktword := _kLimit[_aktcsoport,_zz];
          WordIras(_aktword);
          inc(_zz);
        end;
      inc(_aktcsoport);
    end;

  // A file végét jelzõ 3 byte kiirása:

  Byteiras(255);
  Byteiras(255);
  Byteiras(255);

  System.CloseFile(_iras);
end;



function TAdatSzetKUldes.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;




// =============================================================================
        function TadatSzetKuldes.UploadFiles: boolean;
// =============================================================================


var _mess: string;

begin

  _mess    := 'Békéscsabai';
  _akthost := _bcsabaHost;
  _aktport := _bcsabaPort;


  result := false;

  if not VanInternet then
    begin
      ShowMessage('NINCS INTERNET !');
      exit;
    end;

  Listbox1.Items.add('Fellépés az Internetre');
  _hnet := InternetOpen(pchar('LoadFormServer'),INTERNET_OPEN_TYPE_DIRECT,nil,nil,0);

  if _hNet = nil then
    begin
      Listbox1.Items.Add('Nem tudtam fellépni az internetre ...');
      exit;
    end;

  ListBox1.Items.Add('Csatlakozási kisérlet a ' + _mess + ' szerverhez ...');
  ListBox1.Repaint;

  _hFTP := InternetConnect(_hNet,Pchar(_aktHost),_aktPort,Pchar(_userId),
                           PChar(_ftpPassword),INTERNET_SERVICE_FTP,
                           INTERNET_FLAG_PASSIVE,
                           0);

  IF _hFTP = nil then
    begin
      ListBox1.Items.add('Nem sikerült csatlakozni a szerverhez !');
      InternetCloseHandle(_hNet);
      Sleep(200);
      Exit;
    end;

  // ----------------------- Change directory ---*****************--------------

  ListBox1.Items.Add('Belépési kisérlet az árfolyam könyvtárba ...');
  ListBox1.Repaint;

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar(_ARFOLYAMDIR));
  if not _sikeres then
    begin
      Listbox1.Items.Add('Nem tudtam belépni az árfolyam könyvtárba');
      Listbox1.Repaint;
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Sleep(200);
      Exit;
    end;

  // ---------------------------------------------------------------------------

  RemoteFileDelete;

  // ===========================================================================

  _localPath  := _ujdataPath;
  _remoteFile := _ujdataName;
  Result := FtpPutfile(_hFTP,pchar(_localpath),pchar(_remotefile),
                                               FTP_TRANSFER_TYPE_BINARY,0);
  // ===========================================================================

  InternetCloseHandle(_hFTP);
  InternetcloseHandle(_hNet);
end;

// =============================================================================
               procedure TAdatszetkuldes.ByteIras(_bb: byte);
// =============================================================================

begin
  _bytetomb[1] := _bb;
  BlockWrite(_iras,_bytetomb,1);
end;

// =============================================================================
                procedure TAdatSzetkuldes.WordIras(_ww: word);
// =============================================================================

var _hi,_lo: byte;

begin
  _hi := trunc(_ww/256);
  _lo := _ww - trunc(256*_hi);
  _bytetomb[1] := _lo;
  _bytetomb[2] := _hi;
  Blockwrite(_iras,_bytetomb,2);
end;

// =============================================================================
               procedure TAdatszetkuldes.FloatIras(_rr: real;_vs: integer);
// =============================================================================

var _b1,_b2,_b3,_b4,_b5: byte;
    _tmp: real;

begin
  if _vs=8 then _rr := (1000*_rr)+0.2
  else _rr := (100*_rr)+0.02;

  _tmp := _rr/65536;
  _b5  := trunc(_tmp/65536);
  _rr  := _rr - trunc(_b5*(sqr(65536)));

  _tmp := _rr/65536;
  _b4  := trunc(_tmp/256);
  _rr  := _rr - trunc(_b4*256*65536);

  _b3  := trunc(_rr/65536);
  _rr  := _rr - trunc(_b3*65536);

  _b2  := trunc(_rr/256);
  _b1  := trunc(_rr -(256*_b2));

  _bytetomb[1] := _b1;
  _bytetomb[2] := _b2;
  _bytetomb[3] := _b3;
  _bytetomb[4] := _b4;
  _bytetomb[5] := _b5;
  Blockwrite(_iras,_bytetomb,5);
end;


// =============================================================================
          procedure TADATSZETKULDES.KONFIRMGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := _mResult;
end;



// =============================================================================
             procedure TAdatSzetkuldes.ArfolyamKiiro(_ddb: integer);
// =============================================================================

var _arfdarab: integer;

begin
  _valss := 1;
  _arfdarab := 9;
  while _valss<=_ddb do
    begin
      _arfs[1] := _jErtek[_aktcsoport,_valss];
      _arfs[2] := _lErtek[_aktcsoport,_valss];
      _arfs[3] := _mErtek[_aktcsoport,_valss];
      _arfs[4] := _nErtek[_aktcsoport,_valss];
      _arfs[5] := _oErtek[_aktcsoport,_valss];
      _arfs[6] := _pErtek[_aktcsoport,_valss];
      _arfs[7] := _qErtek[_aktcsoport,_valss];
      _arfs[8] := _rErtek[_aktcsoport,_valss];
      _arfs[9] := _sErtek[_aktcsoport,_valss];

      _zz := 1;
      while _zz<=_arfdarab do
        begin
          _aktarfs := _arfs[_zz];
          _aktarfs := trim(form1.VesszobolPont(_aktarfs));

          val(_aktarfs,_aktarfolyam,_code);

          if _code<>0 then _aktarfolyam := 0;
          floatIras(_aktarfolyam,_valss);
          inc(_zz);
        end;
      inc(_valss);
    end;
end;


// =============================================================================
                   function TAdatszetkuldes.VanInternet: boolean;
// =============================================================================

var

    _dwConnType: integer;

begin

   Result := False;
   TRY
     _dwConntype := 7;
     if InternetGetConnectedState(@_dwConnType,0) then result := true;
   except
   end;

end;


// =============================================================================
                   procedure TAdatszetkuldes.RemoteFileDelete;
// =============================================================================

var _filenev: string;

begin
  // Oldcr törlése  .....

  // Az új NF törlése ...

   _hSearch := FtpFindFirstFile(_hFtp,'NR*.DAT',_findData,0,0);
  if _hsearch<>NIL then
    begin
      repeat
        _fileNev := _findData.cFileName;
        FtpdeleteFile(_hFTP,pchar(_filenev));

      until not InternetFindNextFile(_hsearch,@_findData);
      InternetCloseHandle(_hsearch);
    end;


end;


end.

