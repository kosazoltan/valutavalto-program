unit Unit7;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IdIntercept, IdSSLIntercept, IdSSLOpenSSL,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  ExtCtrls, strUtils, ComCtrls;

type
  TTELEFONHTTPSRUTINOK = class(TForm)
    IdHTTP1: TIdHTTP;
    SSL: TIdConnectionInterceptOpenSSL;
    INDITO: TTimer;
    REPLYTIMER: TTimer;
    LISTABOX: TListBox;
    FAKLYA: TAnimate;
    Label1: TLabel;
    Label2: TLabel;
    TESTTOPUPTIMER: TTimer;
    LIVETOPUPTIMER: TTimer;
    CANCELTOPUPTIMER: TTimer;
    KILEPOTIMER: TTimer;

    procedure FormActivate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure SSLGetPassword(var Password: String);
    procedure CsomagElkuldes;
    procedure FaklyaOff;
   
    procedure REPLYTIMERTimer(Sender: TObject);
    procedure TestTopupTimerTimer(Sender: TObject);
    procedure KilepoTimerTimer(Sender: TObject);
    function GetxrAdatok: boolean;
    procedure LIVETOPUPTIMERTimer(Sender: TObject);
    procedure CANCELTOPUPTIMERTimer(Sender: TObject);
   

 //   procedure TestCsomagElkuldes;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TelefonHTTPSRutinok: TTelefonHTTPSRutinok;
  _rtelefonszam,_testFile,_mondat: string;
  _internetOke,_linedarab: integer;
  _tIras: TextFile;
  _akcio: string;

implementation

uses Unit2, Unit1;

{$R *.dfm}

// =============================================================================
                procedure TTelefonHTTPSRutinok.FormActivate(Sender: TObject);
// =============================================================================

Begin
  top := _TOP + 430;
  left := _left + 280;
  Width := 681;
  
  ListaBox.Visible := false;

  with Faklya do
    begin
      Visible := true;
      Active := True;
      Repaint;
    end;

 // _HTTPtipusok := 'TEST TOPUP','LIVE TOPUP','CANCEL TOPUP'

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

  if _httpTipus = 'TEST TOPUP' then TESTTOPUPTIMER.enabled := True;
  if _httpTipus = 'LIVE TOPUP' then LIVETOPUPTIMER.enabled := True;
  if _httpTipus = 'CANCEL TOPUP' then CANCELTOPUPTIMER.enabled := True;
end;

// =============================================================================
        procedure TTelefonHTTPSRutinok.TestTopupTimerTimer(Sender: TObject);
// =============================================================================


// Mobilfeltöltö TEST kérés elküldése:

var i: integer;

begin
  TestTopUpTimer.Enabled := False;
  _AKCIO := 'TEST';
  with ListaBox do
    begin
      Clear;
      Items.clear;
      Items.add('<Message>');
      Items.add('<MessageType>TEST TOPUP</MessageType>');
      Items.add('<TerminalId>' + _terminalid + '</TerminalId>');
      Items.add('<UserName>' + _username + '</UserName>');
      Items.add('<UserPassword>' + _password + '</UserPassword>');
      Items.add('<ProductId>'+inttostr(_cikkszam)+'</ProductId>');
      if _loss=3 then Items.add('<Amount>'+inttostr(_fizetendo)+'</Amount>');
      Items.add('<PhoneNumber>'+_telefonszam+'</PhoneNumber>');
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

  CsomagElkuldes;
  if not _sikeres then
    begin
      _hibauzenet := 'HTTP HIBA !';
      _mResult := 2;
      KilepoTimer.Enabled := true;
      Exit;
    end;

  _counter := 10;
  ReplyTimer.Enabled := true;
end;


// =============================================================================
        procedure TTELEFONHTTPSRUTINOK.REPLYTIMERTimer(Sender: TObject);
// =============================================================================

var _tszam: string;
begin
  replyTimer.Enabled := False;
  if not FileExists(_replyfile) then
    begin
      dec(_counter);
      if _counter<1 then
        begin
          ReplyTimer.Enabled := False;
          _hibaUzenet := 'NEM JÖTT VÁLASZ IDÖBEN';
          FaklyaOff;
          _mResult := 2;
          KilepoTimer.Enabled := true;
        end;
      ReplyTimer.Enabled := true;
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
      _MResult := 2;
      KilepoTimer.Enabled := true;
      exit;
    end;
  FaklyaOff;
  if _akcio='TEST' then
    begin
      val(_xrAmount,_fizetendo,_code);
      if _code<>0 then _fizetendo := 0;
      with TelefonForm.FizetendoPanel do
        begin
          Font.Color := clBlue;
          Caption := Form1.FtForm(_Fizetendo);
          Visible := true;
          Repaint;
        end;
    end;


  if _akcio='LIVE' then
    begin
      val(_xrAmount,_Fizetendo,_code);
      if _code<>0 then _Fizetendo := 0;

      _tszam := _xrPhoneNumber;

      if _Fizetendo=0 then
        begin
          _hibaUzenet := 'ÉRTÉK NÉLKÜLI VÁLASZ ÉRKEZETT';
          _MResult := 2;
          KilepoTimer.Enabled := true;
          Exit;
        end;


      with TelefonForm.FizetendoPanel do
        begin
          Font.Color := clRed;
          Caption := Form1.FtForm(_Fizetendo);
          Repaint;
        end;
    END;

  _mResult := 1;
  KilepoTimer.Enabled := true;
end;


// =============================================================================
        procedure TTELEFONHTTPSRUTINOK.LIVETOPUPTIMERTimer(Sender: TObject);
// =============================================================================

// Mobilfeltöltö LIVE kérésének elküldése:

var i: integer;

begin
  LiveTopupTimer.Enabled := false;
  _akcio := 'LIVE';
  with ListaBox do
    begin
      Clear;
      Items.clear;
      Items.add('<Message>');
      Items.add('<MessageType>LIVE TOPUP</MessageType>');
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
  if not _sikeres then
    begin
      _hibauzenet := 'HTTP HIBA !';
      _mResult := 2;
      KilepoTimer.Enabled := true;
      Exit;
    end;

  _counter := 10;
  ReplyTimer.Enabled := true;
end;


// =============================================================================
      procedure TTelefonHTTPsRutinok.SSLGetPassword(var Password: String);
// =============================================================================

begin
  Password := 'SIGMA';
end;


// =============================================================================
           procedure TTelefonHTTPSRutinok.BitBtn1Click(Sender: TObject);
// =============================================================================

begin
  _hibaUzenet := 'A FELHASZNÁLÓ MEGSZAKÍTOTTA A TRANZAKCIÓT';
  Modalresult := 2;
end;

// =============================================================================
               procedure TTelefonHTTPSRutinok.CsomagElkuldes;
// =============================================================================

begin
 
  if FileExists(_replyFile) then DeleteFile(_replyFile);

  _letter := Listabox.Items;
  _tfs := TFilestream.Create(_replyFile,fmCreate);
  _sikeres := False;
  TRY
    idHttp1.Post(_url,_LETTER,_tfs);
    _sikeres := True;
  finally
    _TFS.free;
  END;
end;


// =============================================================================
                  function TTelefonHTTPSRutinok.GetxrAdatok: boolean;
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
  _xrPhoneNumber       := trim(Form1.Getmezo('PhoneNumber'));

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
        procedure TTELEFONHTTPSRUTINOK.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := false;
  ModalResult := _mResult;
end;

// =============================================================================
                   procedure TTelefonHTTPsRutinok.FaklyaOff;
// =============================================================================

begin
  Faklya.active := false;
  Faklya.visible := false;
end;

// =============================================================================
     procedure TTELEFONHTTPSRUTINOK.CANCELTOPUPTIMERTimer(Sender: TObject);
// =============================================================================

begin
  CancelTopupTimer.Enabled := false;
  with ListaBox do
    begin
      Clear;
      Items.clear;
      Items.add('<Message>');
      Items.add('<MessageType>CANCEL TOPUP</MessageType>');
      Items.Add('<TransactionId>'+_xrTransactionId+'</TransactionId)');
      Items.add('</Message>');
    end;

  _lineDarab := Listabox.Items.Count;
  _replyFile := 'CANCRPLY.TXT';

  CsomagElkuldes;
  if not _sikeres then
    begin
      _hibauzenet := 'HTTP HIBA !';
      _mResult := 2;
      KilepoTimer.Enabled := true;
      Exit;
    end;

  _counter := 10;
  ReplyTimer.Enabled := true;
end;


// Innen mindent törölni kell 
(*

// =============================================================================
              procedure TTELEFONHTTPSRUTINOK.Testcsomagelkuldes;
// =============================================================================


var _talap,_tfile,_tsz,_cikksz,_cnev: string;
    _fiz,_tlen: integer;
    _xiras: textfile;

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
  _cnev := _Cikknev[_cikkszam];
  _tsz := Form1.Getmezo('PhoneNumber');


  if _talap= 'TEST' then
    begin
      _pcs := '<Message><MessageType>TEST TOPUP</MessageType>';
      _pcs := _pcs + '<TerminalId>966</TerminalId>';
      _pcs := _pcs + '<OperatorId>012345</OperatorId>';
      _pcs := _pcs + '<ProductId>'+_cikksz+'</ProductId>';
      _pcs := _pcs + '<ProductName>'+_cnev+'</ProductName>';
      _pcs := _pcs + '<Amount>'+inttostr(_fiz)+'</Amount>';
      _PCS := _PCS + '<PhoneNumber>'+_tsz+'</PhoneNumber>';
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
      _pcs := _pcs + '<MessageType>LIVE TOPUP</MessageType>';
      _pcs := _pcs + '<OutletName>izishop     </OutletName>';
      _pcs := _pcs + '<Outletaddress>1234 Pécs, Kossuth tér 123  </OutletAddress>';
      _pcs := _pcs + '<OutletTaxNo>123456-7-89 </OutletTaxNo>';
      _pcs := _pcs + '<ProductName>'+_cnev+'  </PoductName>';
      _pcs := _PCS + '<Amount>00015400</Amount>';
      _pcs := _pcs + '<PhoneNumber>'+_tsz+'</PhoneNumber>';
      _pcs := _pcs + '<TransactionId>0002240895</TransactionId>';
      _pcs := _pcs + '<ReferenceId>00001230560   </ReferenceId>';
      _pcs := _pcs + '<TransactionDate>20100212013033 </TransactionDate>';
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




end.
