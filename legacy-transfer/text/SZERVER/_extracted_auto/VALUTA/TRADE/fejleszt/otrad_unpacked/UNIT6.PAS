unit Unit6;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, unit1, ComCtrls, IdIntercept, strutils,
  IdSSLIntercept, IdSSLOpenSSL, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP;

type
  TMATRICAHTTPSRUTINOK = class(TForm)
    KILEPOTIMER: TTimer;
    Panel1: TPanel;
    LISTABOX: TListBox;
    IdHTTP1: TIdHTTP;
    SSL: TIdConnectionInterceptOpenSSL;
    REPLYTIMER: TTimer;
    TESTAAKTIMER: TTimer;
    LIVEAAKTIMER: TTimer;
    CANCELAAKTIMER: TTimer;
    FAKLYA: TAnimate;


    procedure FormActivate(Sender: TObject);
    procedure SSLGetPassword(var Password: String);
    procedure Csomagelkuldes;
    procedure FaklyaOff;

    procedure LiveCsomagszerkesztes;

    procedure TESTAAKTIMERTimer(Sender: TObject);
    procedure REPLYTIMERTimer(Sender: TObject);
    procedure LIVEAAKTIMERTimer(Sender: TObject);
    procedure KILEPOTimerTimer(Sender: TObject);
//    procedure TestCsomagelkuldes;

    function GetxrAdatok: boolean;
    function Pontoz(_dstring: string):string;
    procedure CANCELAAKTIMERTimer(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MATRICAHTTPSRUTINOK: TMATRICAHTTPSRUTINOK;
  _InternetOke,_lineDarab: INTEGER;
  _tIras: textFile;
  _testFile,_mondat,_akcio: string;
  _sikeres: boolean;

implementation

uses Unit3;

{$R *.dfm}

// =============================================================================
          procedure TMATRICAHTTPSRUTINOK.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := _top + 550;
  Left := _left + 120;
  _mResult := 2;

  ListaBox.Visible := false;
  with Faklya do
    begin
      Visible := true;
      Active  := True;
      Repaint;
    end;

   // _HTTPtipusok := 'TEST AAK','LIVE AAK','CANCEL AAK'

  if not Form1.Vaninternet then
    begin
      FaklyaOff;
      _hibaUzenet := 'NINCS INTERNETKAPCSOLAT';
      _MResult := 2;
      KilepoTimer.Enabled := true;
      Exit;
    end;

  idHttp1.Intercept := SSL;
  idhttp1.InterceptEnabled := true;

  ssl.SSLOptions.CertFile := 'CERTIFIC.PEM';
  ssl.SSLOptions.KeyFile := 'PRIVKEY.PEM';

  if _httpTipus = 'TEST AAK' then
    begin
      TestAAKTimer.enabled := True;
      exit;
    end;
  if _httpTipus = 'LIVE AAK' then
    begin
      LiveAAKTimer.enabled := True;
      exit;
    end;

  if _httpTipus = 'CANCEL AAK' then CancelAAKTimer.enabled := True;

end;

// =============================================================================
        procedure TMATRICAHTTPSRUTINOK.TESTAAKTIMERTimer(Sender: TObject);
// =============================================================================

// Matrica TEST csomag küldése:

var i: integer;

begin
  TestAAkTimer.Enabled := False;
  _AKCIO := 'TEST';
  with ListaBox do
    begin
      Clear;
      Items.clear;
      Items.add('<Message>');
      Items.add('<MessageType>TEST AAK</MessageType>');
      Items.add('<TerminalId>' + _terminalId + '</TerminalId>');
      Items.add('<UserName>' + _username + '</UserName>');
      Items.add('<UserPassword>' + _password + '</UserPassword>');
      Items.add('<ProductId>'+inttostr(_cikkszam)+'</ProductId>');
      Items.add('<RegistrationNumber>'+_rendszam+'</RegistrationNumber>');
      Items.Add('<CountryCode>'+inttostr(_countryCode)+'</CountryCode>');
      Items.Add('<VFD>' + _vfd + '</VFD>');
      Items.add('<LimitCheck>Y</LimitCheck>');
      Items.add('</Message>');
    end;

  _lineDarab := Listabox.Items.Count;
  _testFile := 'TEST.TXT';

  AssignFile(_tiras,_testfile);
  Rewrite(_tiras);
  for i := 0 to _linedarab-1 do
    begin
      _mondat := Listabox.Items[i];
      WriteLn(_tiras,_mondat);
    end;
  CloseFile(_tiras);

  _replyFile := 'TESTRPLY.TXT';

  CsomagElkuldes;                  //ez itt teszt !!!!!!
  if not _sikeres then
   begin
      _hibauzenet := 'HTTP HIBA !';
      _mResult := 2;
      KilepoTimer.Enabled := true;
      Exit;
    end;

  _counter := 10;
  ReplyTimer.Enabled := True;      
end;

// =============================================================================
               procedure TMatricaHTTPSRutinok.CsomagElkuldes;
// =============================================================================

begin

//  Ez csak a test módban kell kikommentelni !!!!!!!!!!!!!!!!!!!!!!!!!!!
  if FileExists(_replyFile) then DeleteFile(_replyFile);

  _letter := Listabox.Items;
  _tfs := TFilestream.Create(_replyFile,fmCreate);
  _sikeres := False;
  TRY
    idHttp1.Post(_url,_LETTER,_tfs);
    _sikeres := true;
  finally
    _TFS.free;
  END;

end;


// =============================================================================
                  function TMatricaHTTPSRutinok.GetxrAdatok: boolean;
// =============================================================================


begin
  result := False;

  _xrMessageType       := trim(Form1.GetMezo('MessageType'));
  _xrStatusId          := trim(Form1.Getmezo('StatusId'));
  _xrStatusDescription := trim(Form1.Getmezo('StatusDescription'));
  _xrTransactionId     := trim(Form1.Getmezo('TransactionId'));
  _xrTransactionDate   := trim(Form1.Getmezo('TransactionDate'));

  _xrProductId         := trim(Form1.Getmezo('ProductId'));
  _xrProductName       := trim(Form1.Getmezo('ProductName'));
  _xrAmount            := trim(Form1.Getmezo('Amount'));
  _xrRegistrationNumber:= trim(Form1.Getmezo('RegistrationNumber'));
  _xrCountryName       := trim(Form1.Getmezo('Countryname'));
  _xrVFD               := trim(Form1.Getmezo('VFD'));
  _xrVTD               := trim(Form1.Getmezo('VTD'));
  _xrReferenceId       := trim(Form1.Getmezo('ReferenceId'));

  _xrOutletName        := trim(Form1.Getmezo('OutletName'));
  _xrOutletAddress     := trim(Form1.Getmezo('OutletAddress'));
  _xrOutletTaxNo       := trim(Form1.Getmezo('OutletTaxNo'));

  _xrOperatorId        := trim(Form1.Getmezo('OperatorID'));
  _xrReceiptNumber     := trim(Form1.Getmezo('ReceiptNumber'));
  _xrPrintReceipt      := trim(Form1.Getmezo('PrintReceipt'));

  _status := _xrStatusId;

  If leftstr(_status,4)<>'00OK' then
    begin
     _HibaUzenet := _xrStatusDescription;
    end
    else
    begin
      _tranzakcio := _xrTransactionId;
      result := true;
    end
end;


// =============================================================================
       procedure TMATRICAHTTPSRUTINOK.SSLGetPassword(var Password: String);
// =============================================================================

begin
  Password := 'SIGMA';
end;


// =============================================================================
              procedure TMatricaHTTPSRUTINOK.LiveCsomagszerkesztes;
// =============================================================================

var _lineDarab,i: integer;
    _tiras: Textfile;
    _mondat,_liveFile: string;

begin
  with ListaBox do
    begin
      Clear;
      Items.clear;
      Items.add('<Message>');
      Items.Add('<MessageType>LIVE AAK</MessageType>');
      Items.add('<TransactionId>'+_tranzakcio+'</TransactionId>');
      Items.add('</Message>');
    end;

  _lineDarab := ListaBox.Items.Count;
  _LiveFile := 'LIVE.TXT';

  AssignFile(_tiras,_livefile);
  Rewrite(_Tiras);
  for i := 0 to _linedarab-1 do
    begin
      _mondat := ListaBox.Items[i];
      WriteLn(_tiras,_mondat);
    end;
  CloseFile(_tiras);
end;


// =============================================================================
       procedure TMatricaHTTPSRutinok.KILEPOTimerTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := False;
  Modalresult := _mResult;
end;


// =============================================================================
                 procedure TMatricaHTTPsRutinok.FaklyaOff;
// =============================================================================

begin
  Faklya.active := false;
  Faklya.visible := false;
end;

// =============================================================================
         procedure TMATRICAHTTPSRUTINOK.REPLYTIMERTimer(Sender: TObject);
// =============================================================================

begin
  ReplyTimer.Enabled := False;
  if not FileExists(_replyfile) then
    begin
      dec(_counter);
      if _counter<1 then
        begin

          _hibaUzenet := 'NEM JÖTT VÁLASZ IDÖBEN';
          FaklyaOff;
          _mResult := 2;
          KilepoTimer.Enabled := true;
          exit;
        end;
       replyTimer.Enabled := True;
       exit;
    end;


  Assignfile(_olvas,_replyFile);
  Reset(_olvas);
  _meret := FileSize(_olvas);

  if _meret = 0 then
    begin
      CloseFile(_olvas);
      _hibaUzenet := 'ÜRES VÁLASZ ÉRKEZETT';
      FaklyaOff;
      _Mresult := 2;
      KilepoTimer.Enabled := true;
      Exit;
    end;

  Blockread(_olvas,_charTomb,_meret);
  CloseFile(_olvas);

  if not GetxRAdatok then
    begin
      FaklyaOff;
      _hibaUzenet := 'HIBÁS VISSZAJELZÉS !';
      _MResult := 2;
      KilepoTimer.Enabled := true;
      exit;
    end;

  FaklyaOff;
  if _akcio = 'TEST' then
    begin
      val(_xrAmount,_Fizetendo,_code);
      if _code<>0 then _Fizetendo := 0;
      with AutopalyaForm.KifizetendoPanel do
        begin
          Font.color := clWhite;
          Color := clRed;
          Caption := Form1.FtForm(_fizetendo);
          Repaint;
        end;
    end;



  IF _akcio = 'LIVE' then
    begin
      val(_xrAmount,_Fizetendo,_code);
      if _code<>0 then _Fizetendo := 0;

      _rendszam := _xrRegistrationNumber;
      _referenceId := _xrReferenceId;
      _startDatums := Pontoz(_xrVFD);
      _endDatums   := Pontoz(_xrVTD);

      val(leftstr(_xrVFD,4),_startev,_code);
      if _code<>0 then _startev := 0;

      val(midstr(_xrVFD,5,2),_startho,_code);
      if _code<>0 then _startho := 0;

      val(midstr(_xrVFD,7,2),_startnap,_code);
      if _code<>0 then _startnap := 0;

      val(leftstr(_xrVTD,4),_endev,_code);
      if _code<>0 then _endev := 0;

      val(midstr(_xrVTD,5,2),_endho,_code);
      if _code<>0 then _endho := 0;

      val(midstr(_xrVTD,7,2),_endnap,_code);
      if _code<>0 then _endnap := 0;

      if (_startev=0) or (_startho=0) or (_startNap=0) then
        begin
          _mResult := 2;
          _hibauzenet := 'HIBÁS KEZDŐNAP LETT VISSZAIGAZOLVA';
          Kilepotimer.Enabled := True;
          Exit;
        end;

      if (_endev=0) or (_endho=0) or (_endNap=0) then
        begin
          _mResult := 2;
          _hibauzenet := 'HIBÁS ZÁRÓNAP LETT VISSZAIGAZOLVA';
          Kilepotimer.Enabled := True;
          Exit;
        end;

      if _fizetendo=0 then
        begin
          _mResult := 2;
          _hibauzenet := 'HIBÁS EGYSÉGÁRRAL LETT VISSZAIGAZOLVA';
          Kilepotimer.Enabled := true;
          Exit;
        end;
       if _rendszam='' then
         begin
          _mResult := 2;
          _hibauzenet := 'HIBÁS RENDSZÁM LETT VISSZAIGAZOLVA';
          Kilepotimer.Enabled := true;
          Exit;
        end;

        AutopalyaForm.KiFizetendoPanel.Font.Color := clBlack;
        AutopalyaForm.KiFizetendoPanel.Color := clWhite;
        Autopalyaform.KifizetendoPanel.Caption := Form1.FtForm(_fizetendo);
        AutoPalyaForm.IdoIntervalumDisplay;
      end;

  _mresult := 1;
  _hibaUzenet := '';
  Kilepotimer.Enabled := true;
end;

// =============================================================================
        procedure TMATRICAHTTPSRUTINOK.LIVEAAKTIMERTimer(Sender: TObject);
// =============================================================================

var i: integer;

begin
  LiveAAkTimer.Enabled := false;
  _akcio := 'LIVE';
  with ListaBox do
    begin
      Clear;
      Items.clear;
      Items.add('<Message>');
      Items.add('<MessageType>LIVE AAK</MessageType>');
      Items.Add('<TransactionId>'+_xrTransactionId+'</TransactionId)');
      Items.add('</Message>');
    end;

  _lineDarab := Listabox.Items.Count;
  _testFile := 'LIVE.TXT';

  AssignFile(_tiras,_testfile);
  Rewrite(_tiras);
  for i := 0 to _linedarab-1 do
    begin
      _mondat := Listabox.Items[i];
      WriteLn(_tiras,_mondat);
    end;
  CloseFile(_tiras);
  _replyFile := 'LIVERPLY.TXT';

  CsomagElkuldes;
  _counter := 10;
  ReplyTimer.Enabled := true;

end;

// Innen tovább minden törlendö
(*
// =============================================================================
            procedure TmatricaHTTPsRutinok.TestCsomagelkuldes;
// =============================================================================

var _talap,_tfile,_cikksz,_validfrom,_cnev: string;
    _fiz,_tlen: integer;
    _xiras: Textfile;

begin
  if FileExists(_replyFile) then DeleteFile(_replyFile);

  _talap := LeftStr(_replyFile,4);
  _tfile := _tAlap + '.TXT';

  Assignfile(_olvas,_tFile);
  Reset(_olvas);
  _meret := FileSize(_olvas);

  Blockread(_olvas,_charTomb,_meret);
  CloseFile(_olvas);

  _cikksz   := Form1.Getmezo('ProductId');
  val(_cikksz,_cikkszam,_code);
  _fiz      := _cikkar[_cikkszam];
  _validfrom := Form1.Getmezo('VFD');
  _cnev := _Cikknev[_cikkszam];


  if _talap= 'TEST' then
    begin
      _pcs := '<Message><MessageType>TEST AAK</MessageType>';
      _pcs := _pcs + '<TerminalId>966</TerminalId>';
      _pcs := _pcs + '<OperatorId>012345</OperatorId>';
      _pcs := _pcs + '<ProductId>'+_cikksz+'</ProductId>';
      _pcs := _pcs + '<ProductName>'+_cnev+'</ProductName>';
      _pcs := _pcs + '<RegistrationNumber>'+_rendszam+'</RegistrationNumber>';
      _pcs := _pcs + '<CountryName>H - Magyarország </CountryName>';
      _pcs := _pcs + '<Amount>'+inttostr(_fiz)+'</Amount>';
      _pcs := _pcs + '<VFD>'+_validfrom+'</VFD>';
      _pcs := _pcs + '<TransactionId>0002240895</TransactionId>';
      _pcs := _pcs + '<TransactionDate>20100131135108</TransactionDate>';
      _pcs := _pcs + '<OutletName>izishop     </OutletName>';
      _pcs := _pcs + '<Outletaddress>1234 Pécs, Kossuth tér 123  </OutletAddress>';
      _pcs := _pcs + '<ReceiptNumber>2010.02.11/12     </ReceiptNumber>';
      _pcs := _pcs + '<StatusId>00OK    </StatusId>';
      _pcs := _pcs + '<StatusDescription>Sikeres tranzakció    </StatusDescription>';
      _pcs := _pcs + '</Message>';
    end;

  if _talap = 'LIVE' then
    begin
      _pcs := '<Message>';
      _pcs := _pcs + '<MessageType>LIVE AAK</MessageType>';
      _pcs := _pcs + '<OutletName>izishop     </OutletName>';
      _pcs := _pcs + '<Outletaddress>1234 Pécs, Kossuth tér 123  </OutletAddress>';
      _pcs := _pcs + '<OutletTaxNo>123456-7-89 </OutletTaxNo>';
      _pcs := _pcs + '<ProductName>'+_cnev+'  </PoductName>';
      _pcs := _PCS + '<Amount>00015400</Amount>';
      _pcs := _pcs + '<RegistrationNumber>'+_rendszam+'</RegistrationNumber>';
      _pcs := _pcs + '<CountryName>H - Magyarország </CountryName>';
      _pcs := _pcs + '<VFD>20100202124530</VFD>';
      _pcs := _pcs + '<VTD>20100215151140</VTD>';
      _pcs := _pcs + '<TransactionId>0002240895</TransactionId>';
      _pcs := _pcs + '<ReferenceId>00001230560   </ReferenceId>';
      _pcs := _pcs + '<TransactionDate>20100212013033 </TransactionDate>';
      _pcs := _pcs + '<TerminalId>966</TerminalId>';
      _pcs := _pcs + '<StatusId>00OK   </StatusId>';
      _pcs := _pcs + '<StatusDescription>sikeres tranzakció  </StatusDescription>';
      _pcs := _pcs + '</Message>';
    end;

  _tlen := length(_pcs);

  Assignfile(_xiras,_replyFile);
  Rewrite(_xiras);
  write(_xiras,_pcs,_tlen);
  closeFile(_xIras);
  Sleep(5000);
  _sikeres := true;
end;
*)


// =============================================================================
         function TmatricaHTTPsRutinok.Pontoz(_dstring: string):string;
// =============================================================================

begin
  result := leftstr(_dstring,8);
  result := leftstr(result,4)+'.'+midstr(result,5,2)+'.'+midstr(result,7,2);
end;


// =============================================================================
        procedure TMATRICAHTTPSRUTINOK.CANCELAAKTIMERTimer(Sender: TObject);
// =============================================================================

var i: integer;

begin
  CancelAAkTimer.Enabled := false;
  _akcio := 'CANCEL';
  with ListaBox do
    begin
      Clear;
      Items.clear;
      Items.add('<Message>');
      Items.add('<MessageType>CANCEL AAK</MessageType>');
      Items.Add('<TransactionId>'+_xrTransactionId+'</TransactionId)');
      Items.add('</Message>');
    end;

  _lineDarab := Listabox.Items.Count;
  _testFile := 'CANCEL.TXT';

  AssignFile(_tiras,_testfile);
  Rewrite(_tiras);
  for i := 0 to _linedarab-1 do
    begin
      _mondat := Listabox.Items[i];
      WriteLn(_tiras,_mondat);
    end;
  CloseFile(_tiras);
  _replyFile := 'CANCRPLY.TXT';

  CsomagElkuldes;
  _counter := 10;
  ReplyTimer.Enabled := true;
end;

end.
