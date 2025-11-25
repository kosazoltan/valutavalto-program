unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, DBGrids, ExtCtrls, DB, StrUtils, WININET,
  DBTables, IBDatabase, IBCustomDataSet, IBTable, IBQuery,printers;

type
  TARFOLYAMFORM = class(TForm)

    ARFOLYAMSOURCE: TDataSource;

           Panel1: TPanel;

    ARFOLYAMRACS: TDBGrid;
        ESCAPEGOMB: TBitBtn;

        Label1: TLabel;
    ETARDBASE: TIBDatabase;
    ETARTRANZ: TIBTransaction;
    ETARQUERY: TIBQuery;
    GOMBTAKAROPANEL: TPanel;
    PTARCOMBO: TComboBox;
    SERVERQUERY: TIBQuery;
    SERVERDBASE: TIBDatabase;
    SERVERTRANZ: TIBTransaction;
    ARFOLYAMQUERY: TIBQuery;
    ARFOLYAMDBASE: TIBDatabase;
    ARFOLYAMTRANZ: TIBTransaction;
    Label2: TLabel;
    ARFOLYAMQUERYVALUTANEM: TIBStringField;
    ARFOLYAMQUERYVALUTANEV: TIBStringField;
    ARFOLYAMQUERYELSZAMOLASIARFOLYAM: TIntegerField;
    ARFOLYAMQUERYVETELIARFOLYAM: TIntegerField;
    ARFOLYAMQUERYELADASIARFOLYAM: TIntegerField;


    function Nul3(_n: byte): string;

    procedure Aparancs(_ukaz: string);
    function Intdekodol(_bs: byte): integer;

    procedure AlapadatBeolvasas;
    procedure FormCreate(Sender: TObject);
    procedure ArfolyamBeolvasas;
    procedure FTPSzerverbeBelep;
    procedure crsTorlese;

    function Elokieg(_s: string;_hh: byte): string;
    function Kieg(_s: string; _hh: byte): string;
    function Validalo(_reals: string): integer;

    function DuplaSupkod():boolean;
    procedure IrodaAdatBeolvasas;
    function GetCurrate: string;

    function Getidos: string;
    procedure ESCAPEGOMBClick(Sender: TObject);
    procedure PTARCOMBOChange(Sender: TObject);

    function wCurrateFeldolgozas: boolean;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ARFOLYAMFORM: TARFOLYAMFORM;

  _hNet,_hFtp,_hSearch: HINTERNET;
  _findData: WIN32_FIND_DATA;

  _valnem:array[1..27] of string = ('EUR','USD','GBP','CHF','AUD','CAD','DKK',
           'JPY','NOK','SEK','CZK','HRK','PLN','RON','RSD','BGN','ILS','UAH',
           'RUB','EUA','TRY','CNY','BAM','THB','BRL','MXN','NZD');

  _valnev: array[1..27] of string = ('EURÓ','USA DOLLÁR','ANGOL FONT','SVÁJCI FRANK',
           'AUSZTRÁL DOLLÁR','KANADAI DOLLÁR','DÁN KORONA','JAPÁN JEN','NORVÉG KORONA',
           'SVÉD KORONA','CSEH KORONA','HORVÁT KUNA','LENGYEL ZLOTY','ROMÁN LEJ',
           'SZERB DINÁR','BOLGÁR LEVA','IZRAELI SHAKEL','UKRÁN HRIVNYA','OROSZ RUBEL',
           'EURÓ ÉRME','TÖRÖK LÍRA','KÍNAI JÜAN','BOSNYÁK MÁRKA','THAI BATH',
           'BRAZIL REÁL','MEXIKÓI PESO','ÚJZÉLANDI DOLLÁR');

  _arfolyamdir: string = '\ARFOLYAM';

  _bytetomb: array[1..200] of byte;

  _elszarf,_vetarf,_eladarf: array[1..27] of integer;
  _olvas: file of byte;


  _eddigedit,_ujdnem,_ujdnev,_pcs,_aktdnem,_aktdnev,_megnyitottnap: string;
  _idos,_kftnev,_cegnev,_aktptnev,_lastCr,_currate,_ujwpath: string;
  _homepenztarkod,_homepenztarnev,_homepenztarcim: string;

  _orivarf,_oriearf,_code,_pix,_aktptnum,_aktelsz,_aktvet,_aktelad: integer;
  _oke,_aktvarf,_aktearf,_aktelszarf,_nyito,_bevetel,_Kiadas,_zaro: integer;

  _printer,_homepenztarszam,_qq,_sajcsoport: byte;
  _sorveg: string = chr(13)+chr(10);

  _toltes,_sikeres: boolean;

  _top,_left,_height,_width,_ptindex,_PTDARAB: word;
  _LFile: textfile;

  _ptnev: array[1..30] of string;
  _ptnum: array[1..30] of byte;

  _ftpPassword : String  = 'klc+45%';
  _ftpPort     : Integer = 21100;
  _host        : String;
  _userId      : String  = 'ebc-10%';

function arfolyamletoltes(_para: integer): integer;stdcall; external 'c:\ertektar\bin\getarf.dll' name 'arfolyamletoltes';
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\ertektar\bin\super.dll' name 'supervisorjelszo';
function irodaarfolyamrutin: integer; stdcall; external 'c:\ertektar\bin\irarfoly.dll' name 'irodaarfolyamrutin';

function arfolyamrutin: integer; stdcall;

implementation

{$R *.dfm}


function arfolyamrutin: integer; stdcall;

begin
  ArfolyamForm := Tarfolyamform.Create(Nil);
  result := ArfolyamForm.showmodal;
  Arfolyamform.free;
end;  



// =============================================================================
               procedure TARFOLYAMFORM.FormCreate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  Height := 768;
  Width  := 1024;

  GombTakaroPanel.Visible := False;

  _toltes := true;
  AlapAdatBeolvasas;
  IrodaAdatBeolvasas;
  Arfolyambeolvasas;
  _toltes := False;
  Ptarcombo.ItemIndex := 0;
  PtarcomboChange(Nil);
end;



function TARFOLYAMFORM.Getidos: string;

begin
  result := timetostr(Time);
  if midstr(result,2,1)=':' then result := '0' + result;
end;

function TARFOLYAMFORM.Kieg(_s: string; _hh: byte): string;

begin
  while length(_s)<_hh do _s := _s + ' ';
  result := _s;
end;

function TARFOLYAMFORM.Elokieg(_s: string;_hh: byte): string;

begin
  while length(_s)<_hh do _s:= ' '+_s;
  result := _s;
end;


// =============================================================================
        function TARFOLYAMFORM.Validalo(_reals: string): integer;
// =============================================================================


var _ww,i,_kod: integer;
    _rst: string;

begin

   result := 0;
   _reals := trim(_reals);
   _ww := length(_reals);
   if _ww=0 then exit;

   _rst := '';
   for i := 1 to _ww do
     begin
       _kod := ord(_reals[i]);
       if _kod=44 then _kod := 46;
       _rst := _rst + chr(_kod);
     end;

  val(_rst,result,_code);
  if _code<>0 then result := 0;
end;



// =============================================================================
                function TARFOLYAMFORM.DuplaSupkod():boolean;
// =============================================================================

var _oke: integer;

begin
  Result := false;
  _OKE := supervisorjelszo(0);
  if _oke<>1 then exit;

  _OKE := supervisorjelszo(0);
  if _oke<>1 then exit;
  Result := True;
end;

procedure TARFOLYAMFORM.AlapadatBeolvasas;

begin
  Etardbase.connected := true;
  with EtarQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := FieldByNAme('MEGNYITOTTNAP').asString;
      _kftnev := trim(FieldByNAme('KFTNEV').AsString);
      _host := trim(FieldByNAme('HOST').asString);

      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homepenztarkod := trim(FieldByNAme('PENZTARKOD').asString);
      Close;
    end;
  Etardbase.close;

  val(_homepenztarkod,_homepenztarszam,_code);
  _cegnev := 'EXCLUSIVE BEST CHANGE ZRT';

end;


//==============================================================================
                 procedure TArfolyamForm.IrodaAdatBeolvasas;
// =============================================================================

var _uzlet: byte;
    _uznev: string;

begin
  _ptindex := 1;

  while _ptindex<=30 do
    begin
      _ptnev[_ptindex]  := '';
      _ptnum[_ptindex]  := 0;
      inc(_ptindex);
    end;

  Ptarcombo.Items.clear;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (CLOSED<>'+chr(39)+'X'+chr(39)+')';
  _pcs := _pcs + ' AND (STATUS='+chr(39)+'P'+chr(39)+')';
  _pcs := _pcs + ' AND (ERTEKTAR=' +inttostr(_homePenztarSzam)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  with ServerDbase do
    begin
      Close;
      DatabaseName := '185.43.207.99:C:\RECEPTOR\DATABASE\RECEPTOR.FDB';
      Connected := true;
    end;

  with ServerQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;


  _ptIndex := 0;
  Ptarcombo.Items.Clear;
  while not ServerQuery.Eof do
    begin
      _uzlet := Serverquery.FieldbyName('UZLET').asInteger;
      _uznev := uppercase(trim(ServerQuery.fieldByName('KESZLETNEV').AsString));

      inc(_ptindex);

      _ptnum[_ptindex] := _uzlet;
      _ptnev[_ptindex] := _uznEV;

      ptarcombo.Items.add(nul3(_uzlet)+' '+_uznev);


      ServerQuery.next;
    end;
  ServerQuery.close;
  Serverdbase.close;
  _ptdarab:= _ptindex;

end;

function TArfolyamForm.Nul3(_n: byte): string;

begin
  result := inttostr(_n);
  while length(result)<3 do result := '0'+result;
end;

procedure TARFOLYAMFORM.ESCAPEGOMBClick(Sender: TObject);
begin
  ArfolyamQuery.Close;
  Arfolyamdbase.close;
  Modalresult := 1;
end;

procedure TARFOLYAMFORM.PTARCOMBOChange(Sender: TObject);

var _ptnums: string;

begin
  if _toltes then exit;

  _pix := Ptarcombo.ItemIndex;
  _aktptnev := Ptarcombo.Items[_pix];
  _ptnums := leftstr(_aktptnev,3);
  val(_ptnums,_aktptnum,_code);

  // ----------------------------------------------------------

  ArfolyamSource.Enabled := False;
  Arfolyamquery.close;
  Arfolyamdbase.close;

  if wCurratefeldolgozas then
    begin
      _pcs := 'DELETE FROM ARFOLYAM';
      aParancs(_pcs);

      _qq := 1;
      while _qq<=27 do
        begin
           _aktdnem := _valnem[_qq];
           _aktdnev := _valnev[_qq];
           _aktelsz := _elszarf[_qq];
           _aktvet  := _vetarf[_qq];
           _aktelad := _eladarf[_qq];

           _pcs := 'INSERT INTO ARFOLYAM (VALUTANEM,VALUTANEV,ELSZAMOLASIARFOLYAM,';
           _pcs := _pcs + 'VETELIARFOLYAM,ELADASIARFOLYAM)'+_sorveg;
           _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
           _pcs := _pcs + chr(39) + _aktdnev + chr(39) + ',';
           _pcs := _pcs + inttostr(_aktelsz) + ',';
           _pcs := _pcs + inttostr(_aktvet) + ',';
           _pcs := _pcs + inttostr(_aktelad)+')';
           aParancs(_pcs);

           inc(_qq);
        end;
    end;
  ArfolyamDbase.connected := true;
  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  with ArfolyamQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  Arfolyamsource.enabled := true;
  Activecontrol := Arfolyamracs;
end;

procedure TArfolyamform.Arfolyambeolvasas;

begin
  _currate := GetCurrate;
  _currate := uppercase(trim(_currate));

  FTPSzerverbeBelep;
  if _hFTP=Nil then exit;

  // --------- Change directory -----------------

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar(_arfolyamdir));
  if not _sikeres then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  _hSearch := FTPFindFirstFile(_hFTP,'NR*.DAT',_findData,0,0);

  if _hsearch=NIL then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;

  _Lastcr := _finddata.cFileName;
  InternetCloseHandle(_hsearch);

  _lastCr := uppercase(trim(_lastcr));

  if _lastcr=_currate then
    begin
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      exit;
    end;

  Crstorlese;

  _ujwPath := 'C:\ERTEKTAR\ARFOLYAM\' + _lastCr;

  _sikeres := ftpgetfile(_hftp,pchar(_lastCr),pchar(_ujwPath),False,0,FTP_TRANSFER_TYPE_BINARY,0);
  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);
end;

// =============================================================================
                      procedure TarfolyamForm.FTPszerverbeBelep;
// =============================================================================

begin
  _hFtp := Nil;
  _hNet := InternetOpen('Szerverbe',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet=nil then EXIT;

  // ---------------------------------------------------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_host),_ftpPort,pchar(_userId),
           Pchar(_ftpPassword),INTERNET_SERVICE_FTP,INTERNET_FLAG_PASSIVE,0);

  // ---------------------------------------------------------------------------

  if _hFTP=nil then InternetCloseHandle(_hNet);

end;

procedure TarfolyamForm.crsTorlese;

var _minta,_delFile,_delPath: string;
    _srec: TSearchRec;

begin
  _minta := 'C:\VALUTA\ARFOLYAM\NR*.DAT';
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
                  function TarfolyamForm.GetCurrate: string;
// =============================================================================

var _srec: Tsearchrec;
    _minta : string;

begin
  result := 'NR000000.DAT';
  _minta := 'c:\ertektar\arfolyam\NR*.dat';
  if FindFirst(_minta, faAnyFile, _srec) = 0 then result := _srec.name;
  FindClose(_srec);
end;


// =============================================================================
               function TArfolyamForm.wCurrateFeldolgozas: boolean;
// =============================================================================

var _kezdet,_fhossz: integer;


begin

  result := False;

  Assignfile(_olvas,_ujwPath);
  Reset(_olvas);

  Blockread(_olvas,_bytetomb,1);  // verzió száma  = 15
  If _bytetomb[1]<>15 then
    begin
      CloseFile(_olvas);
      exit;
    end;

  Blockread(_olvas,_bytetomb,200);
  if _aktptnum=0 then
     begin
       Closefile(_olvas);
       Exit;
     end;

   _sajcsoport := _bytetomb[_aktptnum];
   if (_sajcsoport<1) or (_sajcsoport>54) then
     begin
       CloseFile(_olvas);
       Exit;
     end;

   _kezdet := 201+trunc((_sajcsoport-1)*1221);
   reset(_olvas);

   _fhossz := Filesize(_olvas);
   if _kezdet>_fhossz then
     begin
       CloseFile(_olvas);
       exit;
     end;

   seek(_olvas,_kezdet);

   _qq := 1;
   while _qq<=27 do
     begin
       Blockread(_olvas,_bytetomb,45);

       _elszarf[_qq]   := intdekodol(1);
       _vetarf[_qq]    := intdekodol(6);
       _eladarf[_qq]   := intdekodol(11);
       if _valnem[_qq]='JPY' then
         begin
           _elszarf[_qq]  := trunc(_elszarf[_qq]/10);
           _vetarf[_qq]   := trunc(_vetarf[_qq]/10);
           _eladarf[_qq]  := trunc(_eladarf[_qq]/10);
         end;
       inc(_qq);
     end;

   closeFile(_olvas);
   result := true;
end;


procedure TArfolyamForm.Aparancs(_ukaz: string);

begin
  arfolyamdbase.connected := True;
  if arfolyamtranz.InTransaction then Arfolyamtranz.Commit;
  arfolyamtranz.StartTransaction;
  with arfolyamQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_ukaz);
      Execsql;
    end;
  Arfolyamtranz.commit;
  Arfolyamdbase.close;
end;

// =============================================================================
           function Tarfolyamform.Intdekodol(_bs: byte): integer;
// =============================================================================

var _b1,_b2,_b3,_b4,_b5: byte;
    _res: real;

begin
   _b1 := _bytetomb[_bs];
   _b2 := _bytetomb[_bs+1];
   _b3 := _bytetomb[_bs+2];
   _b4 := _bytetomb[_bs+3];
   _b5 := _bytetomb[_bs+4];

   _res := _b5*65536*65536;
   _res := _res + (_b4*65536*256);
   _res := _res + (65536*_b3);
   _res := _res + (256*_b2);
   result := trunc(_res + _b1);
end;


end.
