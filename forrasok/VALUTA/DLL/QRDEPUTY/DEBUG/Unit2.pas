unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, DelphiZXingQRCode, ExtCtrls,strUtils,
  StdCtrls, ComCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery;

type
  TForm2 = class(TForm)
    AlapPanel  : TPanel;
    MEHETGOMB: TBitBtn;
    QrTakaro   : TPanel;

    Shape1     : TShape;

    Label1     : TLabel;
    Label2     : TLabel;
    Label3     : TLabel;
    MeretPanel : TPanel;

    ValutaQuery: TIBQuery;
    ValutaDbase: TIBDatabase;
    ValutaTranz: TIBTransaction;
    MEGSEMGOMB: TBitBtn;
    N1PANEL: TPanel;
    Shape2: TShape;
    Label4: TLabel;
    Label6: TLabel;
    TRANZPANEL: TPanel;
    Label7: TLabel;
    VALPANEL: TPanel;
    Label8: TLabel;
    HUFPANEL: TPanel;
    Label9: TLabel;
    KILEPO: TTimer;
    N2PANEL: TPanel;
    DISPLAYGOMB: TBitBtn;
    MEMOPANEL: TPanel;
    MEMO: TMemo;
    SUREPANEL: TPanel;
    Label5: TLabel;
    IGENRENDBENGOMB: TBitBtn;
    UJRAKULDOGOMB: TBitBtn;
    MRGSEMGOMB: TBitBtn;

    procedure Clear_All_currencies;
    procedure Install_currencies;
    procedure Day_close;
    procedure Day_open;
    procedure Pay_in;
    procedure Pay_out;
    procedure Buying;
    procedure Selling;
    procedure Cancellation;
    procedure QrParamBeolvasas;
    procedure MEHETGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimer(Sender: TObject);
    procedure ValutaBeolvasas;

    function Scandnem(_xDnem: string): integer;
    function Nulele(_b: byte): string;
    function Konvdnem(_zDnem: string): string;
    function Arfform(_yArf: integer): string;

    function Konv(_b: byte): byte;
    function Commless(_s: string): string;
    function SendsequentToNav: boolean;
    function OpenCOMPort: Boolean;
    function SetupCOMPort: Boolean;
    function Ftform(_nu: integer): string;
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure DISPLAYGOMBClick(Sender: TObject);
    procedure UJRAKULDOGOMBClick(Sender: TObject);
    procedure IGENRENDBENGOMBClick(Sender: TObject);
    procedure MRGSEMGOMBClick(Sender: TObject);
   

  private
    { private deckaration}

  public
    { public declaration}

  end;


var
  Form2: TForm2;
  _comfile: THandle;
  _mResult: integer;
  _valsor,_portnev: string;
  _aktsorszam,_dnemdarab: byte;
  _sorveg: string = chr(13)+chr(10);

  _reklam: string = 'Raiffeisen Bank ugynoke';
  _dnem: array[0..30] of string;
  _zk,_arf: array[0..30] of integer;

  _number,_y,_z,_tetel,_kulfoldi,_openMenet,_navcom: byte;
  _bytefileHossz,_qq,_byteswritten: dword;
  _xx,_zaro,_aktbjegy,_kezdij,_aktarf,_fizetendo,_recnum: integer;
  _bytetomb: array[1..2054] of byte;
  _iras: File of Byte;

  _yDnem: array[1..26] of string;
  _bjegy: array[1..26] of integer;
  _earf: array[0..26] of integer;

  _initstring: string = 'http://www.fiscat.com/AEE';
  _pcs,_pacs,_aktdnem,_bizonylatszam,_okmanytipus,_azonosito: string;
  _penztarkod,_message: string;
  _portname: Pchar;

  _top,_left,_height,_width: word;

  _randnum,_penztarszam,_code: integer;

Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll';
function qrdisplayrutin: integer; stdcall;


implementation

{$R *.dfm}

function qrdisplayrutin: integer; stdcall;
begin
  Form2 := TForm2.Create(NIL);
  result := Form2.showmodal;
  Form2.Free;
end;

// =============================================================================
                procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _width := screen.Monitors[0].Width;
  _height := screen.Monitors[0].Height;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);


  Top  := _top + 100;
  Left := _left + 100;

  shape1.repaint;

  TranzPanel.caption := '';
  ValPanel.Caption := '';
  Hufpanel.Caption := '';

  AlapPanel.repaint;
  Repaint;

  _kulfoldi       := 0;
  MehetGomb.Enabled := False;
  ValutaBeolvasas;

  QrParamBeolvasas;
  if (_navcom=0) or (_number=0) then
    begin
      Showmessage('NINCS BEÁLLITVA A NAV-OS GÉP COM-PORTJA !');
      _mResult := -1;
      Kilepo.Enabled := True;
      exit;
    end;

  case _number of
    1: Clear_all_currencies;
    2: Install_Currencies;
    3: Day_close;
    4: Day_Open;
    5: Pay_in;
    6: Pay_out;
    7: Buying;
    8: Selling;
    9: Cancellation;
  end;


end;

// =============================================================================
                 procedure Tform2.Clear_All_currencies;
// =============================================================================

begin
  TranzPanel.caption := 'ÖSSZES VALUTA TÖRLÉSE';
  TranzPanel.repaint;

  _pacs := _initstring + '|CCL';

  MehetGomb.enabled := True;
  ActiveControl := MehetGomb;
end;


// =============================================================================
                procedure Tform2.Install_currencies;
// =============================================================================

begin
  TranzPanel.caption := 'VALUTÁK FELVITELE';
  TranzPanel.repaint;

  _pacs := _initstring + '|CYS';
  _Y := 2;
  while _y<_dnemDarab do
    begin
      _aktdnem := _dnem[_y];
      _pacs := _Pacs + '|CY'+nulele(_y-1)+'|'+_aktdnem+'|1|1|'+_aktdnem+'|0';
      inc(_y);
    end;
  MehetGomb.enabled := True;
  ActiveControl := MehetGomb;
end;

// =============================================================================
                          procedure Tform2.Day_close;
// =============================================================================

begin
  TranzPanel.caption := 'A NAP ZÁRÁSA';
  TranzPanel.repaint;

  _pacs := _initstring + '|DC|0|0|1|1|';

  MehetGomb.enabled := True;
  ActiveControl := MehetGomb;
end;

// =============================================================================
                          procedure Tform2.Day_open;
// =============================================================================

begin

  TranzPanel.Caption := 'NAP MEGNYITÁSA';
  TranzPanel.Repaint;

  _pacs := _initstring + '|OP|LOCA|100.0000|'+inttostr(_zk[0]);

  _y := 0;
  while _y<(_dnemdarab-1) do
    begin
      _aktarf   := _arf[_y+1];
      _aktbjegy := _zk[_y+1];

      _pacs := _pacs + '|CY'+nulele(_y);
      _pacs := _pacs + '|' + arfform(_aktarf);
      _pacs := _pacs + '|' +inttostr(_aktbjegy);

      inc(_y);
    end;

  MehetGomb.Enabled := True;
  ActiveControl := MehetGomb;
end;

// =============================================================================
                          procedure Tform2.Pay_in;
// =============================================================================

begin
  TranzPanel.caption := 'PÉNZ ÁTVÉTELE';
  TranzPanel.repaint;

  _valsor := '';
  _pacs := _initstring + '|RA|08|'+_bizonylatszam;
  _y := 1;
  while _y<=_tetel do
    begin
      _aktdnem := _yDnem[_y];
      _aktbjegy := _bjegy[_y];

      _pacs := _pacs + '|' + konvdnem(_aktdnem);
      _pacs := _pacs + '|' + inttostr(_aktbjegy)+'|1';

      if _aktdnem='HUF' then
         begin
           Hufpanel.Caption := ftform(_aktbjegy)+' HUF';
           Hufpanel.repaint;
         end else
         begin
            _valsor := _valsor + ftform(_aktbjegy)+' '+_aktdnem+' ';
         end;

      inc(_y);
    end;

  if _valsor<>'' then
    begin
      Valpanel.Caption := _valsor;
      Valpanel.Repaint;
    end;

  MehetGomb.enabled := True;
  ActiveControl := MehetGomb;
end;

// =============================================================================
                          procedure Tform2.Pay_out;
// =============================================================================

begin
  TranzPanel.caption := 'PÉNZ ÁTADÁSA';
  TranzPanel.repaint;

  _valsor := '';
  _pacs := _initstring + '|PO|11|'+_bizonylatszam;
  _y := 1;
  while _y<=_tetel do
    begin
      _aktdnem := _yDnem[_y];
      _aktbjegy := _bjegy[_y];

      _pacs := _pacs + '|' + konvdnem(_aktdnem);
      _pacs := _pacs + '|' + inttostr(_aktbjegy)+'|1';

      if _aktdnem='HUF' then
         begin
           Hufpanel.Caption := ftform(_aktbjegy)+' HUF';
           Hufpanel.repaint;
         end else
         begin
            _valsor := _valsor + ftform(_aktbjegy)+' '+_aktdnem+' ';
         end;
      inc(_y);
    end;

  if _valsor<>'' then
    begin
      Valpanel.Caption := _valsor;
      Valpanel.Repaint;
    end;

  MehetGomb.enabled := True;
  ActiveControl := MehetGomb;
end;


// =============================================================================
                          procedure Tform2.Buying;
// =============================================================================

begin
  TranzPanel.caption := 'VALUTA VÁSÁRLÁSA';
  TranzPanel.Repaint;

   _pacs := _initstring + '|CY-LO||'+_reklam+'|||';
   _pacs := _pacs + '|' + inttostr(_tetel);

   _valsor := '';
   _y := 1;
   while _y<=_tetel do
     begin
       _aktdnem  :=  _ydnem[_y];
       _aktarf   := _arf[_y];
       _aktbjegy := _bjegy[_y];

       _pacs := _pacs + '|'+konvdnem(_aktdnem)+'|'+arfform(_aktarf);
       _pacs := _pacs + '|'+inttostr(_aktbjegy);

       _valsor := _valsor + ftform(_aktbjegy)+ ' ' + _aktdnem;

       inc(_y);
     end;
  _pacs := _pacs + '|' + inttostr(_kezdij);
  _pacs := _pacs + '|' + inttostr(1+_kulfoldi);

   if _kulfoldi=1 then
    begin
      if _okmanytipus='' then _okmanytipus := 'NN';
      if _azonosito='' then _azonosito := '0000';
      _pacs := _pacs + '|' + _okmanytipus + '|'+_azonosito;
    end else _pacs := _pacs + '||';

  _pacs := _pacs + '|' + _bizonylatszam + '||NN|0000|NN|NN|0';

  ValPanel.Caption := _valsor;
  ValPanel.repaint;

  HufPanel.Caption := ftform(_fizetendo);
  Hufpanel.Repaint;

  MehetGomb.enabled := True;
  ActiveControl := MehetGomb;
end;

// =============================================================================
                          procedure Tform2.Selling;
// =============================================================================

begin
  TranzPanel.caption := 'VALUTA ELADÁSA';
  TranzPanel.repaint;

  _pacs := _initstring + '|LO-CY||'+ _reklam + '||||'+inttostr(_fizetendo);
  _pacs := _pacs + '|' + inttostr(_kezdij)+'|'+inttostr(_tetel);

  _valsor := '';
  _y := 1;
  while _y<=_tetel do
    begin
      _aktdnem :=  _ydnem[_y];
      _aktarf  := _arf[_y];
      _aktbjegy := _bjegy[_y];

      _pacs := _pacs + '|'+ konvdnem(_aktdnem) +'|'+arfform(_aktarf)+'|'+inttostr(_aktbjegy);
      _valsor := _valsor + ftform(_aktbjegy)+ ' ' + _aktdnem;
      inc(_y);
    end;
  _pacs := _pacs + '|'+inttostr(1+_kulfoldi);

  if _kulfoldi=1 then
    begin
      if _okmanytipus='' then _okmanytipus := 'NN';
      if _azonosito='' then _azonosito := '0000';
      _pacs := _pacs + '|' + _okmanytipus + '|'+_azonosito;
    end else _pacs := _pacs + '||';


  _pacs := _pacs + '|'+_bizonylatszam+'||NN|0000|NN|NN';

  ValPanel.caption := _valsor;
  Valpanel.repaint;

  HufPanel.Caption := ftform(_fizetendo);
  Hufpanel.Repaint;

  MehetGomb.enabled := True;
  ActiveControl := MehetGomb;
end;

// =============================================================================
                          procedure Tform2.Cancellation;
// =============================================================================

begin
  TranzPanel.caption := 'BIZONYLAT STORNOZÁSA';
  TranzPanel.repaint;

  _pacs := _initstring + '|STORNO||'+inttostr(_recnum)+'|0||NN|0000|NN|NN';

  MehetGomb.enabled := True;
  ActiveControl := MehetGomb;
end;

// =============================================================================
            procedure TForm2.MEHETGOMBClick(Sender: TObject);
// =============================================================================


var _kikuldve: boolean;

begin
  _kikuldve := SendSequentToNav;
  with surePanel do
    begin
      top := 328;
      left := 8;
      Visible := True;
      Repaint;
    end;
  igenrendbengomb.Enabled := True;

  if _kikuldve then Activecontrol := igenrendbengomb
  else igenRendbenGomb.enabled := False;
end;

// =============================================================================
           procedure TForm2.IGENRENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  SurePanel.visible := False;
  Modalresult :=1;
end;


// =============================================================================
              procedure TForm2.UJRAKULDOGOMBClick(Sender: TObject);
// =============================================================================

begin
  SurePanel.Visible := False;
  Sleep(600);
  MehetGombCLick(Nil);
end;

// =============================================================================
             procedure TForm2.MRGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  SurePanel.visible := False;
  ModalresulT := -1;
end;

// =============================================================================
                 function TForm2.SendsequentToNav: boolean;
// =============================================================================


var _b: byte;

begin
  result := False;

  _bytefilehossz := length(_pacs);
  _qq := 1;
  while _qq<=_bytefileHossz do
    begin
      _b := ord(_pacs[_qq]);
      _byteTomb[_qq] := _b;
      inc(_qq);
    end;

  _portnev  := 'COM'+inttostr(_navcom)+':';
  _portName := pchar(_portnev);

  if not OpenComPort then exit;
  if not SetupCOmport then
    begin
      CloseHandle(_comFile);
      exit;
    end;


  _message := '';
  _qq := 1;
  while _qq<=_bytefileHossz do
    begin
      _message := _message + chr(_bytetomb[_qq]);
      inc(_qq);
    end;

  WriteFile(_ComFile, _message[1], _bytefilehossz, _BytesWritten, nil);
  if _byteswritten=_bytefileHossz then
    begin
      Showmessage('AZ ADATOKAT SIKERESEN KIKÜLDTEM A NAV-OS PÉNZTÁRGÉPRE');
      result := True;
    end else Showmessage('SIKERTELEN ADATKIKÜLDÉS A NAV-OS PÉNZTÁRGÉPRE');
  CloseHandle(_Comfile);
end;

// =============================================================================
                  function TForm2.OpenCOMPort: Boolean;
// =============================================================================

var
   DeviceName: array[0..80] of Char;

begin
    { First step is to open the communications device for read/write.
      This is achieved using the Win32 'CreateFile' function.
      If it fails, the function returns false.

      Wir versuchen, COM1 zu öffnen.
      Sollte dies fehlschlagen, gibt die Funktion false zurück.
    }
  // StrPCopy(DeviceName, 'COM2:');

   StrCopy(DeviceName,_portName);
   _ComFile := CreateFile(DeviceName,
     GENERIC_READ or GENERIC_WRITE,
     0,
     nil,
     OPEN_EXISTING,
     FILE_ATTRIBUTE_NORMAL,
     0);

   if _ComFile = INVALID_HANDLE_VALUE then
     begin
       Showmessage('NEM TUDTAM MEGNYITNI '+ _portnev + ' PORTOT');
       Result := False;
     end else Result := True;
end;

// =============================================================================
                 function TForm2.SetupCOMPort: Boolean;
// =============================================================================

const
   RxBufferSize = 256;
   TxBufferSize = 256;
var
   DCB: TDCB;
   Config: string;
   CommTimeouts: TCommTimeouts;

begin
    { We assume that the setup to configure the setup works fine.
      Otherwise the function returns false.
    }

   if not SetupComm(_ComFile, RxBufferSize, TxBufferSize) then
     begin
       Result := False;
       exit;
     end;

   if not GetCommState(_ComFile, DCB) then
     begin
       Result := False;
       exit;
     end;

   // define the baudrate, parity,...

   Config := 'baud=9600 parity=n data=8 stop=1';

   if not BuildCommDCB(@Config[1], DCB) then
     begin
       Result := False;
       exit;
     end;

   if not SetCommState(_ComFile, DCB) then
     begin
       Result := False;
       exit;
     end;

   with CommTimeouts do
   begin
     ReadIntervalTimeout         := 0;
     ReadTotalTimeoutMultiplier  := 0;
     ReadTotalTimeoutConstant    := 1000;
     WriteTotalTimeoutMultiplier := 0;
     WriteTotalTimeoutConstant   := 1000;
   end;

   if not SetCommTimeouts(_ComFile, CommTimeouts) then
     begin
       ShowMessage('NEM TUDTAM BEÁLLITANI A ' + _portnev + ' PORTOT');
       Result := False;
     end else result := true;
end;

// =============================================================================
                function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
               function Tform2.Scandnem(_xDnem: string): integer;
// =============================================================================

begin
  result := 0;
  while result<=26 do
    begin
      if _xdnem=_dnem[result] then exit;
      inc(result);
    end;
end;

// =============================================================================
                      procedure TForm2.QrParamBeolvasas;
// =============================================================================

begin
  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.Add('SELECT * FROM PENZTAR');
      Open;
      _penztarkod := trim(FieldByNAme('PENZTARKOD').AsString);

      Close;
      Sql.Clear;
      Sql.add('SELECT * FROM HARDWARE');
      Open;
      _navcom  := FieldByNAme('NAVCOM').asInteger;

      close;
      sql.clear;
      sql.add('SELECT * FROM QRPARAMS');
      Open;
      First;
      _number := FieldByNAme('NUMBER').asInteger;
    end;

  val(_penztarkod,_penztarszam,_code);
  if _penztarSzam<151 then
    begin
      n1Panel.Caption := 'EXCLUSIVE';
      n2Panel.Caption := 'CHANGE';
    end else
    begin
      n1Panel.Caption := 'EXPRESSZ';
      n2Panel.Caption := 'EKSZERHAZ';
    end;

  n1Panel.repaint;
  n2Panel.repaint;

  if _number<5 then
    begin
      ValutaQuery.close;
      ValutaDbase.close;
      exit;
    end;

  if _number=9 then
    begin
      _recnum := ValutaQuery.FieldByName('RECNUM').asInteger;
      ValutaQuery.close;
      Valutadbase.close;
      exit;
    end;

  _bizonylatszam := trim(ValutaQuery.FieldByName('BIZONYLATSZAM').asString);
  _kulfoldi      := ValutaQuery.FieldbyNAme('KULFOLDI').asInteger;
  _fizetendo     := ValutaQuery.FieldByNAme('FIZETENDO').asInteger;
  _okmanytipus   := trim(ValutaQuery.FieldbyNAme('OKMANYTIPUS').asstring);
  _azonosito     := trim(ValutaQuery.FieldByName('AZONOSITO').asString);
  _kezdij        := ValutaQuery.FieldByNAme('KEZELESIDIJ').asInteger;
  _kezdij        := abs(_kezdij);

  _okmanytipus := Commless(_okmanytipus);
  _azonosito   := Commless(_azonosito);


  _tetel := 0;
  while not valutaquery.eof do
    begin
      inc(_tetel);
      _yDnem[_tetel] := ValutaQuery.FieldbyName('VALUTANEM').asstring;
      _bjegy[_tetel] := ValutaQuery.FieldByNAme('BANKJEGY').asInteger;
      if _number>6 then _arf[_tetel] := ValutaQuery.FieldByNAme('ARFOLYAM').asInteger;
      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;
end;

// =============================================================================
           function TForm2.Konvdnem(_zDnem: string): string;
// =============================================================================

begin
  _xx := scandnem(_zDnem);
  result := 'LOCA';
  if _xx=0 then exit;

  result := 'CY'+nulele(_xx-1);
end;

// =============================================================================
               function TForm2.Arfform(_yArf: integer): string;
// =============================================================================

var _f1: byte;

begin
  if _yArf<100 then
    begin
      result := '0.'+nulele(_yArf)+'00';
      exit;
    end;

  result := inttostr(_yArf);
  if _aktdnem='JPY' then
    begin
      result := leftstr(result,1)+'.'+midstr(result,2,3)+'0';
      exit;
    end;

  _f1 := length(result)-2;
  result := leftstr(result,_f1)+'.'+midstr(result,_f1+1,2)+'00';
end;

// =============================================================================
               function TFORM2.Commless(_s: string): string;
// =============================================================================

var _ls,_z,_asc: byte;

begin
  result := '';
  _s := trim(_s);
  _ls := length(_s);
  if _Ls=0 then exit;

  _s := uppercase(_s);
  _z := 1;
  while _z<=_Ls do
    begin
      _asc := ord(_s[_z]);
      if _asc>190 then _asc := konv(_asc);
      result := result + chr(_asc);
      inc(_z);
    end;
end;

// =============================================================================
               function TFORM2.Konv(_b: byte): byte;
// =============================================================================

begin
  case _b of
    193: _b := 65;
    201: _b := 69;
    205: _b := 73;
    211: _b := 79;
    213: _b := 79;
    214: _b := 79;
    218: _b := 85;
    219: _b := 85;
    220: _b := 85;

    225: _b := 65;
    233: _b := 69;
    237: _b := 73;
    243: _b := 79;
    245: _b := 79;
    246: _b := 79;
    250: _b := 85;
    251: _b := 85;
    252: _b := 85;
  end;
  result := _b;
end;

// =============================================================================
              function TForm2.ftform(_nu: integer): string;
// =============================================================================

var _wlen: word;
    _rs  : string;
    _f1  : byte;

begin
  result := inttostr(_nu);
  _wlen  := length(result);
  if _wlen<4 then exit;

  _rs := inttostr(_nu);
  if _wLen>6 then
    begin
      _f1 := _wLen - 6;
      result := leftstr(_rs,_f1)+' '+midstr(_rs,_f1+1,3)+' '+midstr(_rs,_f1+4,3);
      exit;
    end;

  _f1 := _wlen-3;
  result := leftstr(_rs,_f1)+' '+midstr(_rs,_f1+1,3);
end;


// =============================================================================
              procedure TForm2.ValutaBeolvasas;
// =============================================================================

var i: byte;
    _elszarf: word;

begin
  for i := 0 to 30 do _zk[i] := 0;

  _pcs := 'SELECT * FROM ARFOLYAM'+_sorveg;
  _pcs := _pcs + 'WHERE NAVSORSZAM>0' + _sorveg;
  _pcs := _pcs + 'ORDER BY NAVSORSZAM';

  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _dnemdarab := recno;
      First;
    end;

  while not ValutaQuery.eof do
    begin
      with ValutaQuery do
        begin
          _aktdnem    := FieldByName('VALUTANEM').asstring;
          _aktsorszam := FieldByName('NAVSORSZAM').asInteger;
          _elszarf    := FieldByName('ELSZAMOLASIARFOLYAM').asInteger;
          _zaro       := FieldbyName('ZARO').asInteger;
        end;

      _xx := _aktsorszam-1;

      _dnem[_xx] := _aktdnem;
      _arf[_xx]  := _elszarf;
      _zk[_xx]   := _zaro;

      ValutaQuery.next;
    end;
  ValutaQuery.close;
  Valutadbase.close;
end;

// =============================================================================
              procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

// =============================================================================
               procedure TForm2.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  MemoPanel.Visible := False;
   _mResult := -1;
  Kilepo.Enabled := True;
end;

// =============================================================================
             procedure TForm2.DISPLAYGOMBClick(Sender: TObject);
// =============================================================================

begin
  Memo.Lines.add(_PACS);
  with Memopanel do
    begin
      Left := 8;
      Top  := 8;
      Visible := True;
      Repaint;
    end;  
end;








end.
