unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls, Buttons,
  IBTable, ComCtrls, ComObj, ExtCtrls, wininet;

type
  TForm1 = class(TForm)
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    VTABLA: TIBTable;
    csik: TProgressBar;
    KILEPOGOMB: TBitBtn;
    STARTGOMB: TBitBtn;
    Label1: TLabel;
    KILEPOTIMER: TTimer;

    procedure FormActivate(Sender: TObject);
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure RangefontKeszlet(_rstr,_fnev: string;_fsize: byte;_bold,_italic: boolean);
   
    procedure GetFoglalasok;
    procedure ExcelKeszites;
    function Scanetar(_et: integer): integer;
    procedure STARTGOMBClick(Sender: TObject);
    function ScanIroda(_aktir: byte):byte;
    function Getbyte: byte;
    function GetInteger: integer;
    function GetString: string;
    function AdatAthozatal: boolean;
    procedure KILEPOTIMERTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _ptNumTomb: array[1..150] of byte;
  _ptNevTomb: array[1..150] of string;
  _ptEtTomb : array[1..150] of byte;
  _fogdarab : array[1..150] of integer;
  _fogDnem: array[1..150,0..4] of string;
  _foglalo: array[1..150,0..4] of integer;
  _bytetomb: array[1..255] of byte;

  _binOlvas: file of byte;

  _penztardarab,_ss,_qq,_vKesz: integer;
  _pcs,_fdbPath,_vmezo,_kmezo,_vdnem,_nev,_kztnev,_rangestr: string;
  _aktPtnev: string;

  _aktPenztarNum,_valutaDarab,_vv,_num,_ett,_xx,_edss,_korzetindex: byte;
  _tetelsor,_lastsor,_aktsor,_aktptnum,_aktptxx,_aktdarab,_koszlop: byte;

  _etptNumsor: array[1..8,1..150] of byte;
  _ettdarab: array[1..8] of byte;

  _etNum: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _korzetnevek: array[1..8] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
            'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR');

  _oxl,_owb,_range: oleVariant;
  _vanexcel,_sikeres: boolean;

  _remotefile,_localpath,_munkadir: string;

  _foglaloPath: string;

   _host: string = '185.43.207.99';
  _userid: string = 'ebc-10%';
  _ftpPassword: string = 'klc+45%';
  _ftpPort: integer = 21100;

  _hnet,_hftp: HINTERNET;


implementation

{$R *.dfm}

procedure TForm1.FormActivate(Sender: TObject);

var i,j: integer;

begin
  top := 150;
  Left := 200;
  
  _munkadir := getcurrentdir;
  _foglaloPath := _munkadir + '\foglalo.dat';
  for i := 1 to 150 do
    begin
      _ptNumTomb[i] := 0;
      _ptnevtomb[i] := '';
      _ptetTomb[i]  := 0;
      _fogdarab[i] := 0;
      for j := 0 to 4 do
        begin
          _fogdnem[i,j] := '';
          _foglalo[i,j] := 0;
        end;
    end;
  for i := 1 to 8 do _ettDarab[i] := 0;

  _penztarDarab := 0;
  _vanexcel := false;
  StartGomb.Enabled := True;

end;
  // ---------------------------------------------------------------------------

procedure TForm1.STARTGOMBClick(Sender: TObject);
begin
  if not adatAtHozatal then
    begin
      KilepoTimer.enabled := true;
      exit;
    end;
  Getfoglalasok;
  ExcelKeszites;
end;


// =============================================================================
                        procedure TForm1.GetFoglalasok;
// =============================================================================


var _fdb,_ptnum: byte;

begin
   Assignfile(_binolvas,_foglalopath);
   reset(_binolvas);

   _penztardarab := getbyte;

   _qq := 1;
    while _qq<=_penztardarab do
      begin
        _ptnumtomb[_qq] := getbyte;
        _ptNevTomb[_qq] := getstring;
        _ptettomb[_qq]  := getbyte;
        _fdb := getByte;
        _fogdarab[_qq] := _fdb;
        if _fdb>0 then
          begin
            _vv := 0;
            while _vv<_fdb do
              begin
                _foglalo[_qq,_vv] := getInteger;
                _fogdnem[_qq,_vv] := getstring;
                inc(_vv);
              end;
          end;
        getbyte;  //_zbyte  
        inc(_qq);
      end;
   closefile(_binolvas);

   // --------------------------------------------------------------------------

  _qq := 1;
  while _qq<=_penztarDarab do
    begin
      Csik.Position := _qq;
      _ptnum := _ptnumtomb[_qq];
      _ett := _ptetTomb[_qq];
      _xx := Scanetar(_ett);
      _edss := _ettDarab[_xx];
      inc(_edss);
      _ettdarab[_xx] := _edss;
      _etPtNumsor[_xx,_edss] := _ptnum;
      inc(_qq);
    end;
end;


// =============================================================================
                      function TForm1.Getbyte: byte;
// =============================================================================

begin
  blockread(_binOlvas,_bytetomb,1);
  result := _bytetomb[1];
end;

// =============================================================================
                      function TForm1.GetInteger: integer;
// =============================================================================


begin
  Blockread(_binOlvas,_bytetomb,4);

  result := trunc(16777216*_bytetomb[4])+trunc(65536*_bytetomb[3]);
  result := result + trunc(256*_bytetomb[2]) + _bytetomb[1];
end;


// =============================================================================
                      function TForm1.GetString: string;
// =============================================================================

var _hossz,_pp,_kod: byte;

begin
  Blockread(_binolvas,_bytetomb,1);
  _hossz := _bytetomb[1];
  result := '';
  if _hossz=0 then exit;
  Blockread(_binOlvas,_bytetomb,_hossz);
  _pp := 1;
  while _pp<=_hossz do
    begin
      _kod := 255 - _bytetomb[_pp];
      result := result + chr(_kod);
      inc(_pp);
    end;
end;      

// =============================================================================
                      procedure TForm1.excelkeszites;
// =============================================================================


var i: integer;
    _betu: string;

begin
  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add[1];

   // ---  A 8 fül létrehozása és elnevezése, sor fagyasztása ------------------

  _oxl.workbooks[1].sheets.add(,,8);
  Csik.Max := 16;

  _korzetIndex := 1;
  while _korzetIndex<=8 do
    begin
      Csik.Position := _korzetindex;

      // ------------------------------------------------
      //  A fülek megnevezése, és ablaktábla rögzitése:

      _kztnev := _korzetnevek[_korzetindex];
      _kZTNev := _kztnev+'I KÖRZET';

      _oxl.workbooks[1].worksheets[_korzetindex].name := _kztNev;
      _oxl.workbooks[1].worksheets[_korzetindex].select;
      _range := _oxl.range['A6','A6'];
      _range.select;
      _oxl.Activewindow.FreezePanes := True;

      // ---------------------------------------------------------
      // Az oszlopok szélességének meghatározása:

      _rangestr := 'A1:A1';
      _oxl.worksheets[_korzetIndex].range[_rangestr].columnwidth := 8;

      _rangestr := 'B1:B1';
      _oxl.worksheets[_korzetIndex].range[_rangestr].columnwidth := 30;

      _rangestr := 'C1:C1';
      _oxl.worksheets[_korzetIndex].range[_rangestr].columnwidth := 5;

      i:=1;
      while i<11 do
        begin
          _betu := chr(67+i);
          _rangestr := _Betu+'1:'+_betu+'1';
          _oxl.worksheets[_korzetIndex].range[_rangestr].columnwidth := 10;

          _betu := chr(68+i);
          _rangestr := _Betu+'1:'+_betu+'1';
          _oxl.worksheets[_korzetIndex].range[_rangestr].columnwidth := 6;
          i := i +2;
        end;


      // -----------------------------------------------------------------------
      // A fõcim kejelzése:

      _rangestr := 'A3:M3';
      _oxl.worksheets[_korzetIndex].range[_rangestr].HorizontalAlignment := -4108;
      _oxl.worksheets[_korzetIndex].range[_rangestr].MergeCells := True;
      Rangefontkeszlet(_rangestr,'Times New Roman',16,False,True);
      _oxl.worksheets[_korzetIndex].cells[3,1] := _kztnev + ' FOGLALÓ ÖSSZEGEI';


      // -----------------------------------------------------------------------
      // A fejléc (5. sor) összeállítása:

      _rangestr := 'A5:M5';
       _oxl.worksheets[_korzetIndex].range[_rangestr].HorizontalAlignment := -4108;
      Rangefontkeszlet(_rangestr,'Times New Roman',12,True,True);
      _oxl.worksheets[_korzetIndex].Cells[5,1] := 'SZÁM';
      _oxl.worksheets[_korzetIndex].Cells[5,2] := 'PÉNZTÁR NEVE';
      _oxl.worksheets[_korzetIndex].Cells[5,3] := 'DB';

      _rangestr := 'D5:E5';
      _oxl.worksheets[_korzetIndex].range[_rangestr].mergecells := true;
      _oxl.worksheets[_korzetIndex].Cells[5,4] := '1.FOGLALÓ';

      _rangestr := 'F5:G5';
      _oxl.worksheets[_korzetIndex].range[_rangestr].mergecells := true;
      _oxl.worksheets[_korzetIndex].Cells[5,6] := '2.FOGLALÓ';

      _rangestr := 'H5:I5';
      _oxl.worksheets[_korzetIndex].range[_rangestr].mergecells := true;
      _oxl.worksheets[_korzetIndex].Cells[5,8] := '3.FOGLALÓ';

      _rangestr := 'J5:K5';
      _oxl.worksheets[_korzetIndex].range[_rangestr].mergecells := true;
      _oxl.worksheets[_korzetIndex].Cells[5,10] := '4.FOGLALÓ';

      _rangestr := 'L5:M5';
      _oxl.worksheets[_korzetIndex].range[_rangestr].mergecells := true;
      _oxl.worksheets[_korzetIndex].Cells[5,12] := '5.FOGLALÓ';
      inc(_korzetIndex);
    end;

  _korzetIndex := 1;
  while _korzetIndex<=8 do
    begin

      Csik.Position := 8 + _korzetindex;

      _Tetelsor := _ettDarab[_korzetIndex];

      _lastSor := _tetelsor+5;
      _aktsor := 6;

      while _aktsor<=_lastSor do
        begin
          _aktptnum := _etPtNumsor[_korzetindex,_aktsor-5];
          _aktptxx  := scaniroda(_aktptnum);
          _aktptnev := _ptnevtomb[_aktptxx];
          _aktdarab := _fogdarab[_aktptxx];

          _rangestr := 'A' + inttostr(_aktsor)+':M' + inttostr(_aktsor);
          Rangefontkeszlet(_rangestr,'Arial',10,False,True);

          // ------------------------- Pénztár száma ---------------------------

          _oxl.worksheets[_korzetIndex].Cells[_aktsor,1].HorizontalAlignment := -4108;
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,1] := inttostr(_aktptnum);

          // -------------- Pénztár neve  --------------------------------------

          _oxl.worksheets[_korzetIndex].Cells[_aktsor,2] := _aktptnev;

          // -------------- Valuta darabszáma -----------------------------------

          _oxl.worksheets[_korzetIndex].Cells[_aktsor,3].HorizontalAlignment := -4108;
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,3] := inttostr(_aktdarab);

          // ---------------- 0. foglaló ---------------------------------------

          _oxl.worksheets[_korzetIndex].Cells[_aktsor,4].Numberformat := '### ### ###';
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,4] := _foglalo[_aktptxx,0];
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,5] := _fogdnem[_aktptxx,0];

          // ---------------- 1.-sõ foglaló ------------------------------------

          _oxl.worksheets[_korzetIndex].Cells[_aktsor,6].Numberformat := '### ### ###';
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,6] := _foglalo[_aktptxx,1];
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,7] := _fogdnem[_aktptxx,1];

          // ----------------- 2-ik foglaló ------------------------------------

          _oxl.worksheets[_korzetIndex].Cells[_aktsor,8].Numberformat := '### ### ###';
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,8] := _foglalo[_aktptxx,2];
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,9] := _fogdnem[_aktptxx,2];

          // ----------------- 3-ik foglaló -------------------------------------

           _oxl.worksheets[_korzetIndex].Cells[_aktsor,10].Numberformat := '### ### ###';
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,10] := _foglalo[_aktptxx,3];
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,11] := _fogdnem[_aktptxx,3];

          // ------------------ 4-ik foglaló -----------------------------------

          _oxl.worksheets[_korzetIndex].Cells[_aktsor,12].Numberformat := '### ### ###';
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,12] := _foglalo[_aktptxx,4];
          _oxl.worksheets[_korzetIndex].Cells[_aktsor,13] := _fogdnem[_aktptxx,4];
          inc(_aktsor);
        end;
      inc(_korzetIndex);
    end;


  Csik.Visible := false;
  _oxl.visible := true;
  _vanexcel := True;

end;


// =============================================================================
procedure TForm1.RangefontKeszlet(_rstr,_fnev: string;_fsize: byte;_bold,_italic: boolean);
// =============================================================================


begin
  _oxl.worksheets[_korzetIndex].Range[_rstr].Font.Name   := _fnev;
  _oxl.worksheets[_korzetIndex].Range[_rstr].Font.Bold   := _bold;
  _oxl.worksheets[_korzetIndex].Range[_rstr].Font.Italic := _italic;
  _oxl.worksheets[_korzetIndex].Range[_rstr].Font.Size   := _fsize;
end;

// =============================================================================
               function TForm1.ScanIroda(_aktir: byte):byte;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  result := 0;
  while _y<=_penztarDarab do
    begin
      if _aktir=_ptNumtomb[_y] then
        begin
          result := _y;
          break;
        end;
      inc(_y);
    end;
end;

// =============================================================================
               procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
   if _vanexcel then
    begin
      _owb := unassigned;
      _oxl.quit;
      _oxl := unassigned;
    end;
  application.Terminate;
end;

function TForm1.Scanetar(_et: integer): integer;

var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=8 do
    begin
      if _etnum[_y]=_et then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;


// =============================================================================
                        function Tform1.AdatAthozatal: boolean;
// =============================================================================

begin
  Result := False;

  _hnet := InternetOpen('LoadFormServer',INTERNET_OPEN_TYPE_PRECONFIG,nil,nil,0);
  if _hNet = nil then
    begin
      Showmessage('Nem tudtam fellépni az internetre ...');
      exit;
    end;

  // -------------------  connect to the server  -------------------------------

  _hFTP := InternetConnect(_hNet,Pchar(_Host),_ftpPort,Pchar(_userId),
                           PChar(_ftpPassword),INTERNET_SERVICE_FTP,
                           INTERNET_FLAG_PASSIVE,
                           0);

  // ---------------------------------------------------------------------------

  IF _hFTP = nil then
    begin
      ShowMessage('Nem sikerült csatlakozni a szerverhez !');
      InternetCloseHandle(_hNet);
      Exit;
    end;

  // ----------------------- Change directory PILLKESZ -------------------------

  // Belép a PILLKESZ köbnyvtárba a szerveren

  _sikeres :=  FTPSetCurrentDirectory(_hFTP,pchar('\FOGLALO'));
  if not _sikeres then
    begin
      ShowMessage('Nem sikerült belépni a FOGLALO-könyvtárába !');
      InternetCloseHandle(_hFTP);
      InternetCloseHandle(_hNet);
      Exit;
    end;

  _remotefile := 'FOGLALO.DAT';

  _localpath := _munkadir + '\' + _remotefile;

  if Fileexists(_localPath) then DeleteFile(_localpath);
  _sikeres := FTPGetFile(_hFTP,pchar(_remoteFile),pchar(_localpath),
                                  False,0,FTP_TRANSFER_TYPE_BINARY,0);

  InternetCloseHandle(_hFTP);
  InternetCloseHandle(_hNet);

  // Ha egyet sem töltött le, akkor result=FALSE

  if fileExists(_localPath) then Result := true;

end;




procedure TForm1.KILEPOTIMERTimer(Sender: TObject);
begin
   KilepoTimer.Enabled := false;
  if _vanexcel then
    begin
      _owb := unassigned;
      _oxl.quit;
      _oxl := unassigned;
    end;  
  application.Terminate;
end;

end.



















