unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, Buttons,
  ExtCtrls,wininet, strutils, dateutils, IBTable;

type
  TGetArfolyam = class(TForm)

    SarfQuery    : TIBQuery;
    SarfDbase    : TIBDatabase;
    SarfTranz    : TIBTransaction;
    SarfTabla    : TIBTable;

    ValutaQuery  : TibQuery;
    ValutaDbase  : TibDatabase;
    ValutaTranz  : TibTransaction;

    MemoTabla    : TMemo;

    Label1       : TLabel;
    Label2       : TLabel;
    Label3       : TLabel;
    Label4       : TLabel;

    Shape1       : TShape;
    Shape2       : TShape;
    Shape3       : TShape;

    ChangePanel  : TPanel;
    NoChangePanel: TPanel;

    ChangeGomb   : TBitBtn;
    NochangeGomb : TBitBtn;

    Changebox    : TListBox;
    Kilepo       : TTimer;

    procedure FormActivate(Sender: TObject);

    procedure Arfolyamregiszter;
    procedure CsoportDekod;
    procedure CurRateReading;
    procedure FTPszerverbeBelep;
    procedure GetGepParameters;
    procedure Makesarf(_s: string);
    procedure Nochangedisplay;
    procedure Hasonlitas;
    procedure NochangeGombClick(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure OldRateFileRemove;
    procedure PcsSzerkeszto;
    procedure ValutaParancs(_ukaz: string);

    function GetCsoportszam: byte;
    function DownLoadRemoteFile: boolean;
    function DnemDekoder(_dkod: word):string;
    function GetCurRateName: string;
    function GetNewRateName: string;
    function Getword: word;
    function GetByte: byte;
    function GetMamas: string;
    function Getidos: string;
    function Nulele(_b: byte): string;
    function Scandnem(_dn: string): byte;
    function ScanUjDnem(_adn: string): byte;
    function Vaninternet: boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Getarfolyam: TGetarfolyam;

  _bytetomb: array[1..32768] of byte;
  _chngsor : array[1..30] of string;

  _hNet,_hFTP,_hSearch: HINTERNET;
  _findData: WIN32_FIND_DATA;

  _curdnem : array[1..28] of string;
  _newdnem : array[1..23] of string;
  _ujDnemDarab : byte =23;

  _ujdnem: array[1..23] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
             'CZK','EUA','EUR','GBP','ILS','JPY','MXN','NZD','PLN','RON','RSD',
             'RUB','THB','TRY','UAH','USD');

  _newcrt,_crt  : array[1..23,1..9] of word;

  _arfolyamDir  : string = '\EXCHANGE';
  _chnglist     : string = 'c:\valuta\ratechng.txt';

   _ftpPort     : Integer = 21100;
   _host        : String;           //  = '185.43.207.99';
   _userId      : String  = 'ebc-10%';
   _ftpPassword : String  = 'klc+45%';

  _localPath    : string;
  _sorveg: string = chr(13)+chr(10);

  _mResult,_fSize: integer;
  _olvas,_iras   : File of byte;
  _textOlvas     : textfile;

  _limit         : array[1..3] of integer;

  _vetel,_eladas,_L1vetel,_L1eladas,_L2vetel,_L2eladas,_aktelszam: word;

  _width,_height : word;
  _csoportHossz  : word;
  _startword     : word;
  _ctrsum        : word;
  _pp            : word;
  _dnemkod       : word;
  _lim           : word;

  _code          : integer;

  _penztarszam   : byte;
  _csoportszam   : byte;
  _dnemss        : byte;
  _c1,_c2,_c3,_y : byte;
  _valss,_lo,_hi : byte;
  _friss         : byte;
  _oldss         : byte;
  _curDnemDarab  : byte;
  _newDnemDarab  : byte;
  _valt          : byte;

  _curRateName   : string;
  _newRateName   : string;
  _aktdnem,_pcs  : string;
  _mondat        : string;
  _aktnewdnem    : string;
  _sarf,_farok   : string;
  _mamas,_idos   : string;

  _newMidrate,_newBuyrate,_newSellRate,_newBuy1Rate,_newSell1Rate: word;
  _newBuy2Rate,_newSell2Rate,_newOwnBuyRate,_newOwnSellRate: word;

  _oldMidrate,_oldBuyrate,_oldSellRate,_oldBuy1Rate,_oldSell1Rate: word;
  _oldBuy2Rate,_oldSell2Rate,_oldOwnBuyRate,_oldOwnSellRate: word;


  _sikeres: boolean;

function arfolyamletoltes: integer; stdcall;

function fenyujsagfrissito: integer; stdcall; external 'c:\valuta\bin\fnyujsag.dll' name 'fenyujsagfrissito';
Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';


implementation

{$R *.dfm}

// =============================================================================
            function arfolyamletoltes: integer; stdcall;
// =============================================================================

begin
  GetArfolyam := TGetArfolyam.Create(Nil);
  Result := GetArfolyam.ShowModal;
  GetArfolyam.Free;
end;

// =============================================================================
             procedure TGETARFOLYAM.FormActivate(Sender: TObject);
// =============================================================================

begin

  Kilepo.Enabled := False;
  logirorutin(pchar('Arfolyam lekérés indul'));

  // Eredmény-jelzõk ektüntetése:

  ChangePanel.Visible   := False;
  NochangePanel.Visible := False;

  // Kiteszi az ablakot a képernyõre:

  _width  := Screen.Monitors[0].Width;
  _height := Screen.Monitors[0].Height;

  Top  := trunc((_height-313)/2);
  Left := trunc((_width-401)/2);

  // A változás-listát elöször is kitörli:

  if FileExists(_chngList) then DeleteFile(_chngList);

  GetGepParameters;  // host és pénztárszám meghatározása
  If _penztarszam=0 then
    begin
      ShowMessage('HIÁNYZIK A GÉPEN A PÉNZTÁRSZÁM');

      _mResult := -1;
      Kilepo.Enabled := True;
      Exit;
    end;

  _curRateName := GetCurRateName;
  _curRateName := UpperCase(trim(_curRateName));

  _newRateName := GetNewRateName;
  _newRateName := upperCase(trim(_newRateName));

  // Ha nincs újabb árfolyamfile a szerveren, akkor nincs árfolyamváltozás:

  if (_newRateName=_curRateName) OR (_newRateName='') then
    begin
      NoChangeDisplay;
      _mResult := 1;
      Kilepo.Enabled := True;
      Exit;
    end;

  // ------------ Innentõl árfolyamváltozás történt  ---------------------------

  _mamas := GetMamas;
  _idos  := GetIdos;

  // Kettös tömbökbe olvassa az összes árfolyamot a Valuta.fdb-böl:
  CurRateReading;

  // A lokális árfolyam könyvtárba másolja az árfolyamfile-t a szerverröl:

  if not DownLoadRemoteFile then
    begin
      // Nem sikerült letölteni az új árfolyamfile-t - ergo  nincs változás
      NoChangeDisplay;
      _mResult := 1;
      Kilepo.Enabled := True;
      Exit;
    end;

  // A letöltött teljes érfolyam file-ból kiolvassa, hogy hány valutanem
  // lett kiküldve és meghatározza a csoportja számát a pénztárszám alapján:

  _csoportszam  := Getcsoportszam;

  // Kiszámitja, hogy honnan kezdödik a pémztár adattömbje:

  _csoportHossz := 7+trunc(20*_newDnemDarab);
  _startWord    := 204+trunc((_csoportszam-1)*_csoportHossz);

  // A letöltött árfolyamfileból bytetomb-be tölti a pénztár érfolyamait:

  Assignfile(_olvas,'c:\valuta\arfolyam\' + _newRateName);
  reset(_olvas);
  Seek(_olvas,_startWord-1);
  Blockread(_olvas,_bytetomb,_csoportHossz);
  CloseFile(_olvas);

  if _byteTomb[1]<>_csoportszam then
    begin

      ShowMessage('HIBÁS ÁRFOLYAMFILE !');
      _mResult := -1;
      Kilepo.Enabled := True;
      Exit;
    end;

  CsoportDekod;
  Hasonlitas;

  ChangeBox.items.clear;
  Changebox.clear;

  if _valt=0 then
    begin
      NoChangeDisplay;
      _mResult := 1;
      Kilepo.Enabled := True;
      Exit;
    end;

  ChangeBox.Items.Clear;
  Changebox.Items.add('      AZ ÚJ ÁRFOLYAMOK:');
  ChangeBox.Items.Add('  ');

  _y := 1;
  while _y<=_valt do
    begin
      Changebox.Items.add(_chngsor[_y]);
      inc(_y);
    end;

  Changebox.Repaint;
  with ChangePanel do
    begin
      Top := 16;
      Left := 16;
      Visible := true;
      Repaint;
    end;

  Arfolyamregiszter;  

  logirorutin(pchar('Az arfolyamok megvaltoztak !'));

  _pcs := 'UPDATE HARDWARE SET KEZIARFOLYAM=0';
  ValutaParancs(_PCS);

  ActiveControl := ChangeGomb;
end;


// =============================================================================
                function TGetArfolyam.DownLoadRemoteFile: boolean;
// =============================================================================


begin
  result := False;

  FTPSzerverbeBelep;
  if _hFTP=Nil then
    begin
      InternetCloseHandle(_hNet);
      exit;
    end;

  // --------- Change directory -----------------

  result :=  FTPSetCurrentDirectory(_hFTP,pchar(_arfolyamdir));
  if not result then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  OldRateFileRemove;

  _localPath := 'C:\valuta\arfolyam\' + _newRateName;

  result := ftpgetfile(_hftp,pchar(_newRateName),pchar(_localPath),False,0,FTP_TRANSFER_TYPE_BINARY,0);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  if not result then exit;

  Assignfile(_olvas,_localPath);
  reset(_olvas);
  _fsize := FileSize(_olvas);
  Seek(_olvas,_fSize-3);
  Blockread(_olvas,_bytetomb,3);
  CloseFile(_olvas);

  _c1 := _bytetomb[1];
  _c2 := _bytetomb[2];
  _c3 := _bytetomb[3];

  _ctrsum := _c1+_c2+_c3;
  if _ctrsum<>765 then
    begin
      ShowMessage('HIBÁS ÁRFOLYAMFILE');
      Sysutils.DeleteFile(_localpath);
      result := False;
    end;
end;

// =============================================================================
                     procedure TGetArfolyam.CsoportDekod;
// =============================================================================

begin
 _valSs := 1;
 _pp    := 2;
 while _valSs<=_newDnemDarab do
   begin
     _dnemKod := GetWord;
     _aktDnem := dnemDekoder(_dnemKod);
     _newdnem[_valss] := _aktdnem;

     _y := 1;
     while _y<=9 do
       begin
         _newCrt[_valss,_y] := getWord;
         inc(_y);
       end;
      inc(_valss);
    end;
 _lim      := GetWord;
 _limit[1] := trunc(1000*_lim);

 _lim      := GetWord;
 _limit[2] := trunc(1000*_lim);

 _lim     := getWord;
 _limit[3]:= trunc(1000*_lim);

end;

// =============================================================================
                function TGetArfolyam.DnemDekoder(_dkod: word):string;
// =============================================================================


var _b1,_b2,_r1,_r2,_r3: byte;

begin
  _b2 := trunc(_dkod/256);
  _b1 := _dkod-trunc(256*_dkod);

  _r1 := trunc(_b1/4);
  _r2 := trunc(_b1*64);
  _r2 := trunc(_r2/8)+trunc(_b2/32);
  _r3 := trunc(_b2*8);
  _r3 := trunc(_r3/8);
  result := chr(_r1+64)+chr(_r2+64)+chr(_r3+64);
end;

// =============================================================================
                         function TGetarfolyam.GetByte: byte;
// =============================================================================

begin
  result := _bytetomb[_pp];
  inc(_pp);
end;

// =============================================================================
                      function TGetArfolyam.Getword: word;
// =============================================================================

begin
  _lo := _bytetomb[_pp];

  inc(_pp);
  _hi := _bytetomb[_pp];

  inc(_pp);

  result := _lo + trunc(256*_hi);

end;

// =============================================================================
                  function TGETARFOLYAM.GetCsoportszam: byte;
// =============================================================================

begin
  Assignfile(_olvas,'c:\valuta\arfolyam\' + _newRateName);
  reset(_olvas);

  Blockread(_olvas,_bytetomb,3);
  _newDnemDarab := _bytetomb[3];

  Blockread(_olvas,_bytetomb,200);
  CloseFile(_olvas);

  result := _bytetomb[_penztarszam];
end;

// =============================================================================
                procedure Tgetarfolyam.CurRateReading;
// =============================================================================

// Kettös tömbökbe olvassa a jelenlegi összes árfolyamot a Valuta.fdb adatvázisból

begin
  _pcs := 'SELECT * FROM ARFOLYAM ORDER BY VALUTANEM';
  ValutaDbase.connected := True;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _valss := 0;
  while not ValutaQuery.eof do
    begin
      _aktdnem := trim(ValutaQuery.FieldByName('VALUTANEM').asString);
      _Dnemss := ScanUjDnem(_aktdnem);
      if _dnemss=0 then
        begin
          ValutaQuery.next;
          Continue;
        end;

      inc(_valss);
      _curdnem[_valss] := _aktdnem;
      _crt[_valss,1]   := ValutaQuery.FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
      _crt[_valss,2]   := ValutaQuery.FieldByName('VETELIARFOLYAM').asInteger;
      _crt[_valss,3]   := ValutaQuery.FieldByName('ELADASIARFOLYAM').asInteger;
      _crt[_valss,4]   := ValutaQuery.FieldByName('K1VETEL').asInteger;
      _crt[_valss,5]   := ValutaQuery.FieldByName('K1ELADAS').asInteger;
      _crt[_valss,6]   := ValutaQuery.FieldByName('K2VETEL').asInteger;
      _crt[_valss,7]   := ValutaQuery.FieldByName('K2ELADAS').asInteger;
      _crt[_valss,8]   := ValutaQuery.FieldByName('SHKVETARFOLYAM').asInteger;
      _crt[_valss,9]   := ValutaQuery.FieldByName('SHKELADARFOLYAM').asInteger;
      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;

  _CurDnemDarab := _valss;

end;


// =============================================================================
                  function Tgetarfolyam.GetCurRateName: string;
// =============================================================================

var _srec: Tsearchrec;
    _minta : string;

begin
  result := '';

  _minta := 'c:\valuta\arfolyam\RM*.arf';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then result := _srec.name;
  FindClose(_srec);
end;

// =============================================================================
                    procedure TGetarfolyam.OldRateFileRemove;
// =============================================================================

var _minta,_delFile,_delPath: string;
    _srec: TSearchRec;

begin
  _minta := 'C:\valuta\arfolyam\RM*.ARF';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then
    begin
      repeat
        _delFile := _srec.Name;
        _delPath := 'c:\valuta\arfolyam\'+_delfile;
        deleteFile(_delPath);
      until FindNext(_srec) <> 0;
      FindClose(_srec);
    end;
end;

// =============================================================================
            function TGetArfolyam.GetNewRateName: string;
// =============================================================================

begin
  result := '';

  FTPSzerverbeBelep;
  if _hFTP=Nil then
    begin
      InternetCloseHandle(_hNet);
      exit;
    end;
  // --------- Change directory -----------------

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar(_arfolyamdir));
  if not _sikeres then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  _hSearch := FTPFindFirstFile(_hFTP,'RM*.ARF',_findData,0,0);
  if _hsearch=NIL then exit;

  result := _findData.cFileName;
  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;


// =============================================================================
                      procedure TGetArfolyam.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := Nil;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);

  if _hNet=nil then exit;

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------

  if _hFTP=nil then
    begin
      InternetCloseHandle(_hNet);
    end;
end;

// =============================================================================
                   procedure TGetarfolyam.GetGepParameters;
// =============================================================================

//  A pénztárszám beolvasása:

var _ptkods: string;

begin
  ValutaDbase.Connected := True;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;

      _host := trim(FieldByNAme('HOST').asString);
      Close;

      Sql.Clear;
      Sql.Add('SELECT * FROM PENZTAR');
      Open;
      _ptkods := trim(FieldByName('PENZTARKOD').asstring);
      Close;
    end;
  ValutaDbase.Close;

  val(_ptKods,_penztarSzam,_code);
  If _code<>0 then _penztarszam := 0;
end;


// =============================================================================
                      procedure TGetarfolyam.Hasonlitas;
// =============================================================================

begin
  _y := 1;

  _pcs := '';
  _valt := 0;

  while _y<=_newDnemDarab do
    begin
      _aktNewDnem := _newDnem[_y];

      _newMidRate  := _newCrt[_y,1];
      _newBuyRate  := _newcrt[_y,2];
      _newSellRate := _newcrt[_y,3];

      _newBuy1Rate  := _newcrt[_y,4];
      _newSell1Rate := _newcrt[_y,5];

      _newBuy2Rate  := _newcrt[_y,6];
      _newSell2Rate := _newcrt[_y,7];

      _newOwnBuyRate  := _newcrt[_y,8];
      _newOwnSellRate := _newcrt[_y,9];

      _oldSs := ScanDnem(_aktNewDnem);

      _oldMidRate  := _Crt[_oldSS,1];
      _oldBuyRate  := _crt[_oldSS,2];
      _oldSellRate := _crt[_oldSS,3];

      _oldBuy1Rate  := _crt[_oldSS,4];
      _oldSell1Rate := _crt[_oldSS,5];

      _oldBuy2Rate  := _crt[_oldSS,6];
      _oldSell2Rate := _crt[_oldSS,7];

      _oldOwnBuyRate  := _crt[_oldSS,8];
      _oldOwnSellRate := _crt[_oldSS,9];

      if (_newBuyRate<>_oldBuyRate) or (_newSellRate<>_oldSellRate) then
        begin
          inc(_valt);
          _chngsor[_valt] := _aktNewDnem + ' új árfolyama = ' + inttostr(_newBuyRate)+'/'+inttostr(_newSellRate);
        end;
      PcsSzerkeszto;
      inc(_y);
    end;
end;


// =============================================================================
               function TGetarfolyam.Scandnem(_dn: string): byte;
// =============================================================================

var _z: byte;

begin
  _z := 1;
  result := 0;
  while _z<=_curDnemDarab do
    begin
      if _curdnem[_z] = _dn then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;


// =============================================================================
                    procedure TGetarfolyam.PcsSzerkeszto;
// =============================================================================

begin
  _pcs := 'UPDATE ARFOLYAM SET ELSZAMOLASIARFOLYAM=' + inttostr(_newMidRate)+',';

  _pcs := _pcs + 'VETELIARFOLYAM='+inttostr(_newBuyRate)+',';
  _pcs := _pcs + 'ELADASIARFOLYAM='+inttostr(_newSellRate)+',';

  _pcs := _pcs + 'K1VETEL='+inttostr(_newBuy1Rate)+',';
  _pcs := _pcs + 'K2VETEL='+inttostr(_newBuy2Rate)+',';

  _pcs := _pcs + 'K1ELADAS='+inttostr(_newSell1Rate)+',';
  _pcs := _pcs + 'K2ELADAS='+inttostr(_newSell2Rate)+',';

  _pcs := _pcs + 'SHKVETARFOLYAM='+inttostr(_newOwnBuyRate)+',';
  _pcs := _pcs + 'SHKELADARFOLYAM='+inttostr(_newOwnSellRate)+_sorveg;

  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktnewDnem + chr(39);
  ValutaParancs(_pcs);
end;


// =============================================================================
            procedure TgetArfolyam.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  valutadbase.connected := true;
  if Valutatranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.commit;
  Valutadbase.Close;
end;

// =============================================================================
                   procedure Tgetarfolyam.Nochangedisplay;
// =============================================================================

begin
  with NoChangePanel do
    begin
      Top     := 64;
      Left    := 16;
      Visible := True;
      Repaint;
    end;

  logirorutin(pchar('Nem volt arfolyamvaltozas'));
  Activecontrol := NochangeGomb;
end;

// =============================================================================
             procedure TGETARFOLYAM.NochangeGombClick(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  Modalresult := 1;
end;


// =============================================================================
                 function TGetarfolyam.Vaninternet: boolean;
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
            function TGetarfolyam.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
            procedure TGetArfolyam.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

// =============================================================================
             function Tgetarfolyam.ScanUjDnem(_adn: string): byte;
// =============================================================================

var _z: byte;

begin
  result := 0;
  _z := 1;
  while _z<=23 do
    begin
      if _ujdnem[_z]=_adn then
        begin
          result := _z;
          exit;
        end;
      inc(_z);
    end;
end;

// =============================================================================
                  procedure TGetArfolyam.ArfolyamRegiszter;
// =============================================================================

var _z: byte;

begin
  _farok := midstr(_mamas,3,2)+midstr(_mamas,6,2);
  _sarf := 'SARF' + _farok;

  Sarfdbase.connected := True;
  sarfTabla.close;
  SarfTabla.TableName := _sarf;
  if NOT SarfTablA.exists  then MakeSarf(_sarf);

  SarfDbase.Connected := True;
  if SarfTranz.InTransaction then SarfTranz.Commit;
  SarfTranz.StartTransaction;

  _z := 1;
  while _z<=_newDnemDarab do
    begin
      _aktDnem   := _newDnem[_z];
      _aktElszam := _newcrt[_z,1];
      _vetel     := _Newcrt[_z,2];
      _eladas    := _Newcrt[_z,3];
      _L1Vetel   := _Newcrt[_z,4];
      _L1eladas  := _Newcrt[_z,5];
      _L2vetel   := _Newcrt[_z,6];
      _L2eladas  := _Newcrt[_z,7];

      _pcs := 'INSERT INTO ' + _sarf + ' (DATUM,IDO,VALUTANEM,LIMIT1,LIMIT2,';
      _pcs := _pcs + 'LIMIT3,ALAPVETEL,ALAPELADAS,LIM1VETEL,LIM1ELADAS,';
      _pcs := _pcs + 'LIM2VETEL,LIM2ELADAS,ELSZAMOLASIARFOLYAM)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _mamas + chr(39) + ',';
      _pcs := _pcs + chr(39) + _idos +  chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_Limit[1]) + ',';
      _pcs := _pcs + inttostr(_Limit[2]) + ',';
      _pcs := _pcs + inttostr(_Limit[3]) + ',';
      _pcs := _pcs + inttostr(_vetel) + ',';
      _pcs := _pcs + inttostr(_eladas) + ',';
      _pcs := _pcs + inttostr(_L1vetel) + ',';
      _pcs := _pcs + inttostr(_L1eladas) + ',';
      _pcs := _pcs + inttostr(_L2vetel) + ',';
      _pcs := _pcs + inttostr(_L2eladas) + ',';
      _pcs := _pcs + inttostr(_aktelszam)+')';
      with SarfQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          ExecSql;
        end;
      inc(_z);
    end;
  SarfTranz.commit;
  SarfDbase.close;
end;


// =============================================================================
                  function TGetarfolyam.Getmamas: string;
// =============================================================================

VAR  _ev,_ho,_nap   : word;

begin
  _ev := yearof(date);
  _ho := monthof(date);
  _nap := dayof(Date);
  result := inttostr(_ev)+'.'+nulele(_ho)+'.'+nulele(_nap);
end;

// =============================================================================
                 function TGetarfolyam.GetIdos: string;
// =============================================================================

var _ora,_perc,_sec: word;

begin
  _ora := Hourof(Time);
  _perc := Minuteof(Time);
  _sec  := Secondof(Time);

  result := nulele(_ora)+':'+nulele(_perc)+':'+nulele(_sec);
end;


// =============================================================================
                procedure TGetarfolyam.Makesarf(_s: string);
// =============================================================================

begin
  _pcs := 'CREATE TABLE ' + _S + ' (' + _sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'IDO CHAR (8) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'LIMIT1 INTEGER,' + _sorveg;
  _pcs := _pcs + 'LIMIT2 INTEGER,' + _sorveg;
  _pcs := _pcs + 'LIMIT3 INTEGER,' + _sorveg;
  _pcs := _pcs + 'ALAPVETEL DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'ALAPELADAS DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'LIM1VETEL DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'LIM1ELADAS DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'LIM2VETEL DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'LIM2ELADAS DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'ELSZAMOLASIARFOLYAM DOUBLE PRECISION)';

  SarfDbase.Connected := true;
  if SarfTranz.InTransaction then SarfTranz.Commit;
  SarfTranz.StartTransaction;
  with SarfQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      execSql;
    end;

  _pcs := 'CREATE INDEX IDX_' + _S + _sorveg;
  _pcs := _pcs + 'ON ' + _S + ' (DATUM,IDO)';

  with SarfQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      execSql;
    end;

  SarfTranz.Commit;
  SarfDbase.close;
end;

end.
