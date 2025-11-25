unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, strutils, IBDatabase, DB,printers,
  IBCustomDataSet, IBQuery, DateUtils;

type
  TForm2 = class(TForm)
    BEKEROPANEL: TPanel;
    HIDEEDIT: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    ZFTPANEL: TPanel;
    ZFTRENDBENGOMB: TBitBtn;
    ZOLDPANEL: TPanel;
    Label3: TLabel;
    Label4: TLabel;
    NAVOKEGOMB: TBitBtn;
    PIROSPANEL: TPanel;
    Label5: TLabel;
    Label6: TLabel;
    MEGJEGYZES: TMemo;
    PIROSTOVABBGOMB: TBitBtn;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALDATAQUERY: TIBQuery;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;

    procedure FormActivate(Sender: TObject);
    procedure ZFTPANELClick(Sender: TObject);
    procedure HIDEEDITEnter(Sender: TObject);
    procedure HIDEEDITExit(Sender: TObject);
    procedure HIDEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    function FtForm(_ft: integer): string;
    procedure ZFTRENDBENGOMBClick(Sender: TObject);
    function GetZaroForint: integer;
    procedure NAVOKEGOMBClick(Sender: TObject);
    procedure PIROSTOVABBGOMBClick(Sender: TObject);
    procedure MakeXML;
    procedure XMLBemasolas;
    procedure TitkosEmail;
    function Angolra(_huName: string): string;
    procedure KozepreIr(_szoveg: string);
    function HutoGb(_kod: byte): byte;
    procedure GetEmailcimek;
    function Nulele(_b: byte): string;
    procedure ValutaParancs(_ukaz: string);
    procedure Pillnyomtatas;
    function Getidos: string;
    procedure Kezdijnyomtatas;
    procedure Blokkfocimiro;
    procedure TextKiiro;
    function FormKiir(_in: integer):string;
    
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _bill,_w,_f1,_ertektar,_y,_etar,_etss,_printer: byte;
  _height,_width,_top,_left,_memsordb,_chardb: word;
  _sFt,_zFt,_code,_navzaroforint,_cimletezett,_kdij,_nyito: integer;
  _bevetel,_kiadas,_zaro,_egyenleg,_aktbkkdij: integer;
  _bkartya,_bkkdij: integer;

  _zFts,_fts,_pcs,_znap,_msor,_remoteFile,_localpath,_body,_aktdnem: string;
  _homepenztarkod,_aktidos,_homepenztarnev,_homepenztarcim,_farok,_bf: string;
  _sorveg: string = chr(13)+chr(10);
  _memsor: array[0..16] of string;

  _LFile: textfile;

  _etszam : array[1..9] of byte  = (10,20,40,50,63,75,120,145,180);
  _chiefs : array[1..9,1..3] of byte;

  _PIRAS  : string;
  _adr    : array[1..6] of string;


function navzarocontrol: integer; stdcall;
function copyfiletoftprutin: integer; stdcall; external 'c:\valuta\bin\copy2ftp.dll' name 'copyfiletoftprutin';

implementation

{$R *.dfm}


// =============================================================================
                  function navzarocontrol: integer; stdcall;
// =============================================================================

begin
  
  Form2 := TForm2.create(NIL);
  result := Form2.showmodal;
  Form2.Free;
end;


// =============================================================================
             procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].height;
  _width  := Screen.Monitors[0].width;

  _top := round((_height-768)/2);
  _left:= round((_width-1014)/2);

  Top :=  _top + 213;
  Left:= _left + 158;
  Height := 300;
  Width  := 690;

  ZftPanel.Caption := '';
  HideEdit.Text := '';
  _zft := 0;
  _zfts := '';

  with BekeroPanel do
    begin
      top := 5;
      left := 5;
      Visible := true;
    end;
  Activecontrol := Hideedit;

end;

// =============================================================================
               procedure TForm2.ZFTPANELClick(Sender: TObject);
// =============================================================================

begin
  _zft := 0;
  _zfts := '';
  ActiveControl := HideEdit;
end;

// =============================================================================
              procedure TForm2.HIDEEDITEnter(Sender: TObject);
// =============================================================================

begin
  ZftPanel.color := clYellow;
end;

// =============================================================================
                 procedure TForm2.HIDEEDITExit(Sender: TObject);
// =============================================================================

begin
  Hideedit.Color := clBtnFace;
end;

// =============================================================================
      procedure TForm2.HIDEEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin

  _bill := ord(key);
  if (_bill>95) AND (_bill<106) then _bill := _bill-48;

  if _bill= 13 then
    begin
    //  if _zft=0 then exit;
      Activecontrol := ZftRendbenGomb;
      exit;
    end;

  if _bill= 8 then
    begin
      _w := length(_zFts);
      if _w=0 then exit;

      if _w=1 then
        begin
          _zfts := '';
          Hideedit.Text := '';
          ZFTPanel.Caption := '';
          _zft := 0;
          exit;
        end;

      _zFts := leftstr(_zFts,_w-1);
      Hideedit.Text := '';
      val(_zfts,_zft,_code);
      ZftPanel.caption := FtForm(_zFt) + ' Ft';
      ZftPanel.repaint;
      exit;
    end;

  if (_bill>47) and (_bill<58) then
    begin
      HideEdit.Text := '';

      _zfts := _zFts + chr(_bill);
      val(_zfts,_zft,_code);

      ZftPanel.Caption := FtForm(_zFt) + ' Ft';
      ZftPanel.repaint;
      exit;
    end;
end;

// =============================================================================
               function TForm2.FtForm(_ft: integer): string;
// =============================================================================

begin
  result := '';
  if _ft=0 then
    begin
      result := '0';
      exit;
    end;  

  _fts := inttostr(_ft);
  if _ft<1000 then
    begin
      result := _fts;
      exit;
    end;

  _w := length(_fts);
  if _w>6 then
    begin
      _f1 := _w-6;
      result := leftstr(_fts,_f1)+' '+midstr(_fts,_f1+1,3)+' '+midstr(_fts,_f1+4,3);
      exit;
    end;

  _f1 := _w-3;
  result := leftstr(_fts,_f1)+' '+midstr(_fts,_f1+1,3);
end;


// =============================================================================
              procedure TForm2.ZFTRENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  {
  if _zft=0 then
    begin
      ZftPanelClick(Nil);
      exit;
    end;
  }

  _navzaroforint := _zFt;
  _cimletezett := GetZaroForint;

  if (_navzaroForint=_cimletezett) then
    begin
      with ZoldPanel do
        begin
          Top := 0;
          Left := 0;
          Visible := True;
          repaint;
        end;
      Activecontrol := NavokeGomb;
      exit;
    end;

  TITKOSEMAIL;

  with PirosPanel do
    begin
      Top := 0;
      left := 0;
      Visible := True;
      repaint;
    end;

  Pillnyomtatas;
  KezdijNyomtatas;

  Activecontrol := Megjegyzes;

end;

// =============================================================================
               function TForm2.GetZaroForint: integer;
// =============================================================================

begin
  Valutadbase.connected := true;
  _pcs :=  'SELECT * FROM HARDWARE';
  with ValutaQuery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _znap := FieldByNAme('MEGNYITOTTNAP').asString;
      _ertektar := FieldByNAme('ERTEKTAR').asINteger;
      _printer := FieldByNAme('PRINTER').asInteger;
      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homePenztarkod := trim(FieldByNAme('PENZTARKOD').AsString);
      _homepenztarnev := trim(FieldByNAme('PENZTARNEV').asString);
      _homePenztarcim := trim(FieldByNAme('PENZTARCIM').AsString);
      Close;
    end;

  _pcs := 'SELECT * FROM CIMINI' + _sorveg;
  _pcs := _pcs + 'WHERE (VALUTANEM=' + chr(39)+'HUF'+chr(39) + ')';
  _pcs := _pcs + ' AND (CIMLETTYPE=1)';

  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _sft := FieldByNAme('AKTKESZLET').asInteger;
      Close;
    end;

  _pcs := 'SELECT * FROM NAPIKEZELESIDIJ WHERE DATUM='+CHR(39)+_znap+chr(39);
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _kdij := FieldByNAme('KEZELESIDIJ').asInteger;
      Close;
    end;
  Valutadbase.close;
  result := (_sft+_kdij);
end;


// =============================================================================
               procedure TForm2.NAVOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;


// =============================================================================
              procedure TForm2.PIROSTOVABBGOMBClick(Sender: TObject);
// =============================================================================

begin
  _Memsordb := Megjegyzes.Lines.Count;
  _chardb := 0;
  _y := 0;
  while _y<_memsordb do
    begin
      _msor := trim(Megjegyzes.Lines[_y]);
      _chardb := _chardb + length(_msor);
      _memsor[_y] := _Msor;
      inc(_y);
    end;

  if _chardb<20 then
    begin
      ShowMessage('LEGALÁBB 20 KARAKTER KELL A MEGJEGYZÉSBEN');
      ActiveControl := Megjegyzes;
      exit;
    end;

  GetEmailcimek;
  MakeXml;
  XMLBemasolas;
  Modalresult := 2;

end;

// =============================================================================
                        procedure TForm2.MakeXml;
// =============================================================================

var
    _ora,_perc: word;
    _mailstring,_hpts,_mSor: string;
    _hpt,_m,_aktchief: BYTE;
    _piras: textfile;

begin
  _ora  := Hourof(Time);
  _perc := Minuteof(Time);
  _hpts := _homepenztarkod;

  val(_hpts,_hpt,_code);

  if _hpt>150 then _etar := 180;

  _remoteFile := 'E' + _hpts + nulele(_ora)+nulele(_perc)+'.xml';
  _localPath := _remotefile;

  _body := 'A '+_hpts+' penztarban a '+_znap+'-i zaraskor elteres volt a navos penztargep'+_sorveg;
  _body := _body + '    zaro forint ertekevel: ('+inttostr(_navzaroforint)+' nem egyenlo '+inttostr(_cimletezett)+')'+_sorveg;

  if _memsordb>0 then
    begin
      _body := _body + '    Penztaros megjegyzese:' + _sorveg;
      _m := 0;
      while _m<_memsordb do
        begin
          _msor := angolra(trim(_memsor[_m]));
          _body := _body + '    '+ _mSor +_sorveg;
          inc(_m);
        end;
    end;

  _m := 1;
  _etss := 6;
  while _m<=9 do
    begin
      if _etszam[_m]=_ertektar then
        begin
          _etss := _m;
          break;
        end;
      inc(_m);
    end;

  _mailstring := '<mail>' + _sorveg;
  _mailstring := _mailstring + '  <addresses>' + _sorveg;

  _m := 1;
  while _m<=3 do
    begin
      _aktchief := _chiefs[_etss,_m];
      if _aktchief=0 then break;

      _mailstring := _mailstring + '    <address>' + _sorveg;
      _mailstring := _mailstring + '      ' + _adr[_aktchief] +_sorveg;
      _mailstring := _mailstring + '    </address>'+_sorveg;

      inc(_m);
    end;

  _mailstring := _mailstring + '  </addresses>' + _sorveg;
  _mailstring := _mailstring + '  <subject>' + _sorveg;
  _mailstring := _mailstring + '     NAV-os forint elteres'+_sorveg;
  _mailstring := _mailstring + '  </subject>'+_sorveg;
  _mailstring := _mailstring + '  <message>'+ _sorveg;
  _mailstring := _mailstring + '    ' +_body + _sorveg;
  _mailstring := _mailstring + '  </message>' + _sorveg;
  _mailstring := _mailstring + '</mail>';

  AssignFile(_pIras,'c:\valuta\' + _localPath);
  rewrite(_pIras);
  write(_piras,_mailstring);
  closefile(_piras);

end;

// =============================================================================
          procedure TForm2.XMLBemasolas;
// =============================================================================

var _sendoke: byte;

begin
  _PCS := 'DELETE FROM MEDIA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO MEDIA (REMOTEDIR,REMOTEFILE,LOCALPATH)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + 'SENDMAIL' + chr(39) + ',';
  _pcs := _pcs + chr(39) + _remotefile + chr(39) + ',';
  _pcs := _pcs + chr(39) + _localpath + chr(39) + ')';
  ValutaParancs(_pcs);

  _sendoke := copyfiletoftprutin;
  if _sendoke=1 then
    begin
      ShowMessage('AZ E-MAILEKET SIKERESEN ELKÜLDTEM');

      Sysutils.DeleteFile(_localPath);
    end else
    begin
      Showmessage('SIKERTELEN E-MAIL KÜLDÉS');

    end;
end;

// =============================================================================
                 function TForm2.Angolra(_huName: string): string;
// =============================================================================

var _whn,_z,_asc: byte;

begin
  result  := '';

  _huname := uppercase(trim(_huname));
  _whn    := length(_huname);

  if _whn=0 then exit;

  _z := 1;
  while _z<=_whn do
    begin
      _asc := ord(_huname[_z]);
      _asc := HutoGb(_asc);

      result := result + chr(_asc);
      inc(_z);
    end;

end;


// =============================================================================
                   function TForm2.HutoGb(_kod: byte): byte;
// =============================================================================

var _r: byte;

begin
  _r := _kod;
  case _kod of
    186: _r := 69;  // E
    187: _r := 79;  // O
    193: _r := 65;  // A
    201: _r := 69;  // E
    211: _r := 79;  // O
    213: _r := 79;  // O
    214: _r := 79;  // O
    218: _r := 85;  // U
    219: _r := 85;  // U
    220: _r := 85;  // U
    222: _r := 65;  // A
    226: _r := 73;  // I
    205: _r := 73;  // I

    225: _r := 97;  // a
    233: _r := 101; // e
    237: _r := 105; // i
    243: _r := 111; // o
    246: _r := 111; // o
    245: _r := 111; // o
    250: _r := 117; // u
    252: _r := 117; // u
    251: _r := 117; // u
  end;
  result := _r;
end;


// =============================================================================
                       procedure TForm2.GetEmailcimek;
// =============================================================================

begin
  _adr[1] := 'fabulyazsuzsa.eec@gmail.com';
  _adr[2] := 'kecskemettv@bestchange.hu';
  _adr[3] := 'bekescsaba.ebc@gmail.com';
  _adr[4] := 'veress.eva.eec@gmail.com';
  _adr[5] := 'hrabina.krisztian.eec@gmail.com';
  _adr[6] := 'teruletivezeto.pecs@gmail.com';

  // szekszard

  _chiefs[1,1] := 1;
  _chiefs[1,2] := 2;
  _chiefs[1,3] := 0;

  // szeged

  _chiefs[2,1] := 1;
  _chiefs[2,2] := 2;
  _chiefs[2,3] := 0;

  // kecskemet

  _chiefs[3,1] := 1;
  _chiefs[3,2] := 2;
  _chiefs[3,3] := 0;

  // debrecen

  _chiefs[4,1] := 1;
  _chiefs[4,2] := 2;
  _chiefs[4,3] := 4;

  // nyiregyhaza

  _chiefs[5,1] := 1;
  _chiefs[5,2] := 2;
  _chiefs[5,3] := 5;

  // bekescsaba

  _chiefs[6,1] := 1;
  _chiefs[6,2] := 2;
  _chiefs[6,3] := 0;

  // pecs

  _chiefs[7,1] := 1;
  _chiefs[7,2] := 2;
  _chiefs[7,3] := 6;

  // kaposvar

  _chiefs[8,1] := 1;
  _chiefs[8,2] := 2;
  _chiefs[8,3] := 6;

  // zálogház

  _chiefs[9,1] := 1;
  _chiefs[9,2] := 2;
  _chiefs[9,3] := 0;

end;


// =============================================================================
                  function TForm2.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;

// =============================================================================
             procedure TForm2.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.Close;
  ValutaDbase.Connected := True;
  if ValutaTranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;
  with Valutaquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.Commit;
  ValutaDbase.close;
end;

// =============================================================================
                    procedure TForm2.PillNyomtatas;
// =============================================================================

begin
  _aktidos := GetIdos;
  BlokkFoCimIro;
  writeLn(_Lfile,_znap+' '+leftStr(_aktidos,5)+' perci penztar allas:');
  writeLN(_LFile,dupestring('-',40));
  writeLn(_LFile,'Val.   Nyito     Forgalom      Penztar');
  writeLn(_LFile,'nem   osszeg     egyenlege      allas');
  writeLN(_LFile,dupestring('-',40));

  ValutaDbase.Close;
  ValutaDbase.Connected := true;
  _pcs := 'SELECT * FROM ARFOLYAM' + _SORVEG;
  _pcs := _pcs + 'WHERE ZARO<>0' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValutaQuery.Eof do
    begin
      with ValutaQuery do
        begin
          _aktdnem := FieldByNAme('VALUTANEM').AsString;
            _nyito := FieldByName('NYITO').AsInteger;
          _bevetel := FieldByName('BEVETEL').asInteger;
           _kiadas := FieldByName('KIADAS').AsInteger;
             _zaro := FieldByName('ZARO').AsInteger;
        end;

      _egyenleg := _bevetel-_kiadas;

      if (_zaro<>0) or (_nyito<>0) or (_egyenleg<>0) then
        begin
          write(_LFile,_aktdnem+' '+FormKiir(_nyito)+' ');
          writeLn(_LFile,FormKiir(_egyenleg)+' '+FormKiir(_zaro));
        end;

      ValutaQuery.Next;
    end;

  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      oPEN;
      _bkartya := FieldByName('BANKKARTYA').asInteger;
      _bkkdij  := FieldByNAme('BKKOLTSEG').asInteger;
      close;
    end;
  Valutadbase.close;
  writeLN(_LFile,dupestring('-',40));
  writeLn(_Lfile,'Bankkartyaval: '+formkiir(_bkartya)+' Ft');
  writeLn(_Lfile,'(bk kez-i dij: '+formkiir(_bkkdij)+' Ft)');

  writeLN(_LFile,dupestring('-',40));
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  Closefile(_LFile);
  TextKiiro;
end;

// =============================================================================
                            procedure TForm2.TextKiiro;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin
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

// =============================================================================
                       function TForm2.Getidos: string;
// =============================================================================

begin
  result := timetostr(Time);
  if midstr(result,2,1)=':' then result := '0' + result;
end;

// =============================================================================
                  procedure TForm2.KezdijNyomtatas;
// =============================================================================

var _kdnyito,_kdkezdij,_kdatvet,_kdatadas,_kdzaro: integer;

begin

  _pcs := 'SELECT * FROM NAPIKEZELESIDIJ' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+ chr(39) + _znap + CHR(39);

  Valutadbase.Connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      _kdnyito := FieldByName('NYITO').asInteger;
      _kdkezdij:= FieldByName('KEZELESIDIJ').asInteger;
      _kdatvet := FieldByName('KEZELESIDIJATVETEL').asInteger;
      _kdatadas:= FieldbyName('KEZELESIDIJATADAS').asInteger;
      _kdZaro  := FieldByName('ZARO').asInteger;
      Close;
    end;
  Valutadbase.close;

  // ---------------------------------------------------------------------------

  _aktidos := GetIdos;
  BlokkFoCimIro;
  writeLn(_Lfile,_znap+' '+leftStr(_aktidos,5)+'-i kez-i dij egyenlege:');
  writeLN(_LFile,dupestring('-',40));
  write(_LFile,'Napi nyito kez-i dij ..:  ');
  writeLn(_LFile,FormKiir(_kdnyito)+' Ft');

  write(_LFile,'A mai napon beszedve ..:  ');
  writeLn(_LFile,FormKiir(_kdkezdij)+' Ft');

  write(_Lfile,'(ebbõl bankkártyás) ...:  ');
  writeLn(_lFile,Formkiir(_bkkdij)+' Ft');

  write(_LFile,'Kezelesi dij atvetel ..:  ');
  writeLn(_LFile,FormKiir(_kdatvet)+' Ft');

  write(_LFile,'Kezelesi dij atadasa ..:  ');
  writeLn(_LFile,FormKiir(_kdatadas)+' Ft');

  write(_LFile,'Pillanatnyi zaro osszeg:  ');
  writeLn(_LFile,FormKiir(_kdzaro)+' Ft');
  writeLN(_LFile,dupestring('-',40));

  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  Closefile(_LFile);
  TextKiiro;
end;

// =============================================================================
                         procedure  TForm2.Blokkfocimiro;
// =============================================================================

begin
  Assignfile(_LFile,'c:\valuta\aktlst.txt');
  rewrite(_LFile);
  Kozepreir(_homePenztarkod+' '+_homepenztarnev);
  Kozepreir(_homepenztarcim);
  writeLN(_LFile,dupestring('-',40));
end;

// =============================================================================
                  function TForm2.FormKiir(_in: integer):string;
// =============================================================================
begin
  Result := FtForm(_in);
  while length(result)<11 do result := ' '+result;
end;


// =============================================================================
         procedure TForm2.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;

// =============================================================================
                      procedure TForm2.TitkosEmail;
// =============================================================================

var
    _ora,_perc: word;
    _mailstring,_hpts: string;
    _hpt: BYTE;
    _piras: textfile;

begin
  _ora  := Hourof(Time);
  _perc := Minuteof(Time);
  _hpts := _homepenztarkod;

  val(_hpts,_hpt,_code);

  if _hpt>150 then _etar := 180;

  _remoteFile := 'E' + _hpts + nulele(_ora)+nulele(_perc)+'.xml';
  _localPath := _remotefile;

  _body := 'A '+_hpts+' penztarban a '+_znap+'-i zaraskor elteres volt a navos penztargep'+_sorveg;
  _body := _body + '    zaro forint ertekevel: ('+inttostr(_navzaroforint)+' nem egyenlo '+inttostr(_cimletezett)+')'+_sorveg;


  _mailstring := '<mail>' + _sorveg;
  _mailstring := _mailstring + '  <addresses>' + _sorveg;

  _mailstring := _mailstring + '    <address>' + _sorveg;
  _mailstring := _mailstring + '      fabulyazsuzsa.eec@gmail.com' +_sorveg;
  _mailstring := _mailstring + '    </address>'+_sorveg;

  _mailstring := _mailstring + '    <address>' + _sorveg;
  _mailstring := _mailstring + '      kecskemettv@bestchange.hu' +_sorveg;
  _mailstring := _mailstring + '    </address>'+_sorveg;

  _mailstring := _mailstring + '  </addresses>' + _sorveg;
  _mailstring := _mailstring + '  <subject>' + _sorveg;
  _mailstring := _mailstring + '     NAV-os forint elteres'+_sorveg;
  _mailstring := _mailstring + '  </subject>'+_sorveg;
  _mailstring := _mailstring + '  <message>'+ _sorveg;
  _mailstring := _mailstring + '    ' +_body + _sorveg;
  _mailstring := _mailstring + '  </message>' + _sorveg;
  _mailstring := _mailstring + '</mail>';

  AssignFile(_pIras,'c:\valuta\' + _localPath);
  rewrite(_pIras);
  write(_piras,_mailstring);
  closefile(_piras);

  _PCS := 'DELETE FROM MEDIA';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO MEDIA (REMOTEDIR,REMOTEFILE,LOCALPATH)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + 'SENDMAIL' + chr(39) + ',';
  _pcs := _pcs + chr(39) + _remotefile + chr(39) + ',';
  _pcs := _pcs + chr(39) + _localpath + chr(39) + ')';
  ValutaParancs(_pcs);

  copyfiletoftprutin;

  Sysutils.DeleteFile(_localPath);
end;
end.
