unit Unit10;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, Unit1, ComCtrls, IdIntercept,
  IdSSLIntercept, IdSSLOpenSSL, IdBaseComponent, IdComponent, strutils,
  IdTCPConnection, IdTCPClient, IdHTTP;

type
  TPAYSAFEFORM = class(TForm)
    Label1: TLabel;
    Shape1: TShape;
    visszagomb: TBitBtn;
    PAYSAFETIMER: TTimer;
    PSREPLYTIMER: TTimer;
    Shape2: TShape;
    FTPANEL1: TPanel;
    FTPANEL2: TPanel;
    FTPANEL3: TPanel;
    FTPANEL4: TPanel;
    Label2: TLabel;
    IGENYPANEL: TPanel;
    INFOTEXT: TLabel;
    IGENYGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    LISTABOX: TListBox;
    FAKLYA: TAnimate;
    KILEPOTIMER: TTimer;
    IdHTTP1: TIdHTTP;
    SSL: TIdConnectionInterceptOpenSSL;
    SIKERPANEL: TPanel;
    Label3: TLabel;
    TEARGOMB: TBitBtn;
    TEARDOWNPANEL: TPanel;
    SAJATPANEL: TPanel;
    Label4: TLabel;
    PSOKEGOMB: TBitBtn;

    procedure FormActivate(Sender: TObject);
    procedure visszagombClick(Sender: TObject);
    function Getmondat: string;
    procedure PAYSAFETIMERTimer(Sender: TObject);
    procedure FTPANEL1Enter(Sender: TObject);
    procedure FTPANEL1Exit(Sender: TObject);
    function Print1Kibontas: boolean;
    procedure Csomagelkuldes;
    procedure FTPANEL1Click(Sender: TObject);
    procedure FaklyaOff;
    procedure KILEPOTIMERTimer(Sender: TObject);
    procedure SSLGetPassword(var Password: String);
    procedure Valasztott;
    procedure FTPANEL1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure IGENYGOMBClick(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure PSREPLYTIMERTimer(Sender: TObject);
    function GetxrAdatok: boolean;


    procedure VevopeldanyNyomtatas;
    procedure SajatpeldanyNyomtatas;

    function EvalPrint1: boolean;
    procedure TEARGOMBClick(Sender: TObject);
    procedure PSOKEGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PAYSAFEFORM: TPAYSAFEFORM;
  _ftPanel: array[1..4] of TPanel;
  _ftcszam: array[1..4] of integer = (304,301,302,303);
  _ftOsszeg: array[1..4] of Integer = (2000,5000,10000,25000);
  _lineDarab,_p1len,_y,_kifizosszeg,_backosszeg: integer;
  _tiras: Textfile;
  _mondat,_paysfile,_xrprint1,_pinkod,_ige,_serialnums: string;
  _mondelo,_osszegs,_serial,_idos: string;
  _tetel,_INTERNETOKE: byte;
  _aktPanel: TPanel;
  _maymove: boolean;

implementation


{$R *.dfm}

// =============================================================================
               procedure TPAYSAFEFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := _top+8;
  Left := _left+8;

  ListaBox.Visible      := False;
  IgenyPanel.Visible    := False;
  SikerPanel.Visible    := False;
  TearDownPanel.Visible := False;
  SajatPanel.Visible    := False;
  Visszagomb.Visible    := True;
  _maymove              := True;

  Faklya.Enabled := False;
  Faklya.Visible := False;

  _ftPanel[1] := FtPanel1;
  _ftPanel[2] := FtPanel2;
  _ftPanel[3] := FtPanel3;
  _ftPanel[4] := FtPanel4;

  idHttp1.Intercept        := SSL;
  idhttp1.InterceptEnabled := True;

  ssl.SSLOptions.CertFile := 'CERTIFIC.PEM';
  ssl.SSLOptions.KeyFile  := 'PRIVKEY.PEM';

  Activecontrol := FTPanel1;
end;

// =============================================================================
          procedure TPAYSAFEFORM.FTPANEL1Click(Sender: TObject);
// =============================================================================

begin
  if not _maymove then exit;
  _tetel := TPanel(Sender).Tag;
  Valasztott;
end;

// =============================================================================
                        procedure TPaysafeForm.Valasztott;
// =============================================================================


var _infotext : string;

begin
  _maymove  := False;
  _cikkszam := _ftCszam[_tetel];
  _psosszeg := _ftOsszeg[_tetel];

  _INFOTEXT := 'Az ügyfél igényel egy '+ form1.ftform(_psosszeg)
                                         + ' forintos paysafecard kódot';

  Form1.Logbair(_infotext);
  Infotext.caption := _infotext;
  Infotext.repaint;
  with IgenyPanel do
    begin
      Top     := 496;
      Left    := 185;
      Visible := True;
    end;
  ActiveControl := Megsemgomb;
end;

// =============================================================================
              procedure TPAYSAFEFORM.IGENYGOMBClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Igenylö gombra kattintott');
  with Faklya do
    begin
      Visible := True;
      Active  := True;
      Repaint;
    end;

  PaysafeTimer.Enabled := true;

end;


// =============================================================================
          procedure TPAYSAFEFORM.PAYSAFETIMERTimer(Sender: TObject);
// =============================================================================


// Paysafecard kérés elküldése:

var i: integer;

begin
  PaySafeTimer.Enabled := False;

  with ListaBox do
    begin
      Clear;
      Items.clear;
      Items.add('<Message>');
      Items.add('<MessageType>PAYSAFECARD</MessageType>');
      Items.add('<TerminalId>' + _terminalid + '</TerminalId>');
      Items.add('<UserName>' + _username + '</UserName>');
      Items.add('<UserPassword>' + _password + '</UserPassword>');
      Items.add('<ProductId>'+inttostr(_cikkszam)+'</ProductId>');
      Items.add('</Message>');
    end;

  _lineDarab := Listabox.Items.Count;
  _paysFile := 'PREQUEST.TXT';

  AssignFile(_tiras,_paysfile);
  Rewrite(_tiras);
  for i := 0 to _linedarab-1 do
    begin
      _mondat := Listabox.Items[i];
      WriteLn(_tiras,_mondat);
    end;
  CloseFile(_tiras);

  _replyFile := 'PAYSRPLY.TXT';

  Form1.Logbair('Az igénylés ('+ INTTOSTR(_cikkszam)+' számú)-cikkre elküldve');
  CsomagElkuldes;
  if not _sikeres then
    begin
      Form1.Logbair('HTTP HIBA - kilépés');
      _hibauzenet := 'HTTP HIBA !';
      sHOWMESSAGE(_hibauzenet);
      ModalResult := 2;
      Exit;
    end;

  Form1.Logbair('Az igénylö csomag rendben elküldve -  Válaszra vár a gép');
  _counter := 10;
  psReplyTimer.Enabled := true;
end;


// =============================================================================
               procedure TPaySafeForm.CsomagElkuldes;
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
           procedure TPAYSAFEFORM.PSREPLYTIMERTimer(Sender: TObject);
// =============================================================================

begin
  PsreplyTimer.Enabled := False;
  if not FileExists(_replyfile) then
    begin
      dec(_counter);
      if _counter<1 then
        begin
          psReplyTimer.Enabled := False;
          _hibaUzenet := 'SIKERTELEN TRANZAKCIÓ ! Nem jött meg a válasz idöben';
          ShowMessage(_hibauzenet);
          Form1.Logbair('SIKERTELEN TRANZAKCIÓ ! Nem jött meg a válasz idöben');
          FaklyaOff;
          Modalresult := 2;
          exit;
        end;
      Form1.Logbair('A számláló még= '+inttostr(_counter)+', tehát tovább várok');
      PsReplyTimer.Enabled := true;
      exit;
    end;

  Form1.Logbair('Megjött a válasz a paysafecard kérelemre');

  Assignfile(_olvas,_replyFile);
  Reset(_olvas);
  _meret := FileSize(_olvas);

  if _meret = 0 then
    begin
      CloseFile(_olvas);
      _hibaUzenet := 'SIKERTELEN TRANZAKCIÓ ! Üres válasz érkezett';
      Form1.Logbair(_hibauzenet);
      ShowMessage(_hibaUzenet);
      FaklyaOff;
      Modalresult := 2;
      Exit;
    end;

  Blockread(_olvas,_charTomb,_meret);
  CloseFile(_olvas);

  Form1.Logbair('Visszajött adatok feldolgozása');
  if not GetxRAdatok then
    begin
      FaklyaOff;
      _hibaUzenet := 'SIKERTELEN TRANZAKCIÓ ! '+_xrStatusDescription;
      ShowMessage(_hibaUzenet);
      Form1.Logbair(_hibauzenet+' - kilépés');
      Modalresult := 2;
      exit;
    end;

  FaklyaOff;
  IgenyPanel.Visible := false;
  Shape1.repaint;
  Form1.Logbair('SIKERES PAYSAFECARD TRANZAKCIÓ');
  with SikerPanel do
    begin
      Top := 175;
      Left := 170;
      Visible := True;
      Bringtofront;
      Repaint;
    end;

  inc(_lastTelefon);
  _bizonylatszam := 'P' + form1.HatNulele(_lastTelefon);

  fORM1.Logbair('Kinyomtatja a vevö példányát');
  VevoPeldanyNyomtatas;
  Shape1.repaint;
  with TeardownPanel do
    begin
      Top := 494;
      Left := 112;
      Visible := true;
      Bringtofront;
    end;

  Visszagomb.Visible := False;

  Form1.Logbair('Kiirja: Tépje le a vevö példányát és adja oda');
  Activecontrol := Teargomb;

end;


// =============================================================================
             procedure TPAYSAFEFORM.FTPANEL1Enter(Sender: TObject);
// =============================================================================

begin
  if not _mayMove then exit;

  _aktpanel := TPanel(sender);
  with _aktpanel do
    begin
      Color := clWhite;
      Font.Color := clred;
      Font.Style := [fsbold,fsItalic];
    end;
end;

// =============================================================================
               procedure TPAYSAFEFORM.FTPANEL1Exit(Sender: TObject);
// =============================================================================

begin
  if not _mayMove then exit;

  _aktpanel := TPanel(sender);
  with _aktpanel do
    begin
      Color := clBtnFace;
      Font.Color := clBlack;
      Font.Style := [fsItalic];
    end;
end;



// =============================================================================
                   procedure TPaySafeForm.FaklyaOff;
// =============================================================================

begin
  Faklya.active := false;
  Faklya.visible := false;
end;


// =============================================================================
            procedure TPAYSAFEFORM.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := false;
  ModalResult := 1;
end;



// =============================================================================
      procedure TPaySafeForm.SSLGetPassword(var Password: String);
// =============================================================================

begin
  Password := 'SIGMA';
end;



// =============================================================================
        procedure TPAYSAFEFORM.FTPANEL1MouseMove(Sender: TObject;
                                            Shift: TShiftState; X, Y: Integer);
// =============================================================================

begin
  _aktpanel := TPanel(Sender);
  Activecontrol := _aktpanel;
end;




// =============================================================================
             procedure TPAYSAFEFORM.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  IgenyPanel.Visible := false;
end;



// =============================================================================
              procedure TPAYSAFEFORM.visszagombClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Mégsem kérnek paysafecard-ot.  Vissza a menüre');
  Form1.Logbair(dupestring('-',80));
  ModalResult := 1;
end;

// =============================================================================
                  function TPaySafeForm.GetxrAdatok: boolean;
// =============================================================================


begin
  result := False;

  _xrStatusId          := trim(Form1.Getmezo('StatusId'));
  _xrStatusDescription := trim(Form1.Getmezo('StatusDescription'));
  _xrTransactionId     := trim(Form1.Getmezo('TransactionId'));
  _xrPrint1            := trim(Form1.Getmezo('Print1'));

  _status := _xrStatusId;
  If leftstr(_status,4)<>'00OK' then
    begin
     _HibaUzenet := _xrStatusDescription;
    end
    else
    begin
      _tranzakcio := _xrTransactionId;
      result := Print1Kibontas;
    end
end;

// =============================================================================
             function TPaySafeForm.Print1Kibontas: boolean;
// =============================================================================

begin
  result := False;
  _p1Len := length(_xrPrint1);
  _y := 1;
  while _y<(_p1Len-6) do
    begin
      if ord(_xrPrint1[_y])=42 then
        begin
          _MONDAT := midstr(_xrPrint1,_y,8);
          if _mondat='*PRINT2*' then
            begin
              _y := _y + 8;
              result := EvalPrint1;
            end;
          break;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                   function TPaysafeForm.EvalPrint1: boolean;
// =============================================================================

begin
  Result := False;
  while _y<(_p1len-6) do
    begin
      _mondat := Getmondat;
      _mondelo := leftstr(_mondat,6);
      if _mondelo='Összeg' then
        begin
          _osszegs := midstr(_mondat,8,length(_mondat)-7);
          _osszegs := trim(leftstr(_osszegs,length(_osszegs)-4));
          val(_osszegs,_backOsszeg,_code);
          if _code<>0 then exit;
          if (_psosszeg<>_backOsszeg) then
            begin
              ShowMessage('A VISSZAIGAZOLT ÖSSZEG ELTÉR A KÉRTTŐL !');
              exit;
            END;
        end;

      if _mondelo='Soroza' then
        begin
          _serial := midstr(_mondat,13,length(_mondat)-12);
        end;

      if _mondelo='PIN-CO' then
        begin
          _pinkod := midstr(_mondat,11,19);
          Result := True;
          Break;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                function TpaysafeForm.Getmondat: string;
// =============================================================================

var _asc: byte;

begin
  result := '';
  while _y<(_p1Len-6) do
    begin
      _asc := Ord(_xrPrint1[_y]);
      if _asc=10 then
        begin
          if length(result)>6 then break;
          result := '';
        end else result := result + chr(_asc);
      inc(_y);
    end;
  inc(_y);
end;


// =============================================================================
             procedure TPaysafeForm.VevoPeldanyNyomtatas;
// =============================================================================

begin
  _idos := timetostr(Time);
  Form1.BlokkFocimIro(True);

  writeLn(_LFile,_sorveg+'          PAYSAFECARD CLASSIC');
  writeLn(_LFile,_sorveg+'Terminal - ID: '+ _terminalid);
  writeLn(_LFile,'Tranzakcio ID: ' + _xrTransactionId+_sorveg);
  writeLn(_LFile,'Dátum : ' + _mamas+' Ido: ' + _idos);
  writeLn(_LFile,'Osszeg: ' + Form1.ftForm(_psosszeg));
  writeLn(_LFile,'S.szám: ' + _serial);
  writeLn(_LFile,'B.szám: ' + _bizonylatszam);

  writeLn(_lfile,_sorveg);

  writeLn(_lfile,dupestring('-',39));
  writeLn(_LFile,'    PIN-KÓD: ' + _pinkod);
  writeLn(_lfile,dupestring('-',39)+_sorveg);

  writeLn(_lfile,'               FIGYELEM!'+_sorveg);

  writeLn(_lfile,' A PIN-Kód készpénz is egyben, ezért');
  writeLn(_lfile,'tilos telefonon keresztül bárkinek is');
  writeLn(_lfile,'megadni ! A paysafecard kupon kizáro-');
  writeLn(_lfile,'lag a paysafecard szerzödéses partne-');
  writeLn(_lfile,'reinél használható fel online fizetés');
  writeLn(_lfile,'            eszközként.'+_sorveg);
  writeLn(_lfile,' A paysafecard kupont soha nem szabad');
  writeLn(_lfile,'idegeneknek átadni,vagy a paysafecard');
  writeLn(_lfile,'által elfogadott szerzödéses partnere-');
  writeLn(_lfile,'ken kívül más kifizetésekre használni.'+_sorveg);

  writeLn(_lfile,'A PIN-kod megadására vonatkozó telefo-');
  writeLn(_lfile,'nos vagy e-mailes felszólitásnak soha-');
  writeLn(_lfile,'       sem szabad eleget tenni.'+_sorveg);

  writeLn(_lfile,'   Help: www.paysafecard.com/help');
  writeLn(_lfile,'   Hetfö-Péntek: 09:30 - 15:30 óráig');
  writeLn(_lfile,'   E-Mail: info.hu@paysafecard.com'+_sorveg);

  writeLn(_lfile,'A paysafecard kereskedelemben történö');
  writeLn(_lfile,'továbbértékesítése tilos.Az általános');
  writeLn(_lfile,'üzleti feltetelek www.paysafecard.com');
  writeLn(_lfile,'        weboldalon talalhatok.'+_sorveg);

  writeLn(_lfile,'A paysafecard fizetö eszköz, melynek');
  writeLn(_lfile,'           kibocsájtója a');
  writeLn(_lfile,'  Prepaid Services Company Ltd. UK'+_sorveg+_sorveg);
  Form1.StartNyomtatas;
end;


// =============================================================================
               procedure TPaysafeForm.SajatPeldanyNyomtatas;
// =============================================================================

begin
  Form1.BlokkFocimIro(True);
  writeLn(_LFile,_sorveg+'          PAYSAFECARD CLASSIC');
  writeLn(_LFile,_sorveg+'Terminal - ID: '+ _terminalid);
  writeLn(_LFile,'Tranzakcio ID: ' + _xrTransactionId+_sorveg);
  writeLn(_LFile,'Datum : ' + _mamas+'  Ido: '+_idos);
  writeLn(_LFile,'Osszeg: ' + Form1.ftForm(_psosszeg));
  writeLn(_LFile,'S.szam: ' + _serial);
  writeLn(_LFile,'B.szam: ' + _bizonylatszam);
  writeLn(_LFile,_sorveg+_sorveg+'    2 peldany nyomtatvanyt atvettem');
  writeLn(_lfile,_sorveg+_sorveg);
  writeln(_LFile,'........................................');

  Form1.StartNyomtatas;
end;


  { 12345678901234567890123456789012345678
    BLOKKFOCIM

              PAYSAFECARD CLASSIC

    Terminal - ID: 1234
    Tranzakcio ID: 1234567890

    Datum : 2014.01.01
    Osszeg: 25.000 Ft
    S.szam: 12345

    Ugyfel peldanya:
    --------------------------------------
    BLOKKFOCIM
    Terminal - ID: 1234
    Tranzakcio ID: 1234567890

    Datum : 2014.01.01
    Osszeg: 25.000 Ft
    S.szam: 12345

    ======================================
         PIN-KOD: 1234-1234-1234-1234
    ======================================

                  FIGYELEM!

      A PIN-Kód készpénz is egyben, ezért
     tilos telefonon keresztül bárkinek is
     megadni ! A paysafecard kupon kizáró-
     lag a paysafecard szerződéses partne-
     reinél használható fel online fizetési
                 eszközként.
      A paysafecard kupont soha nem szabad
     idegeneknek átadni, vagy a paysafecard
     által elfogadott szerződéses partnere-
     ken kívül más kifizetésekre használni.

      A PIN-kód megadására vonatkozó telefo-
     nos vagy e-mailes felszólításnak soha-
            sem szabad eleget tenni.

        Help: www.paysafecard.com/help
        Hétfö-Péntek: 09:30 - 15:30 óráig
        E-Mail: info.hu@paysafecard.com

     A paysafecard kereskedelemben történő
     továbbértékesítése tilos.Az általános
     üzleti feltételek www.paysafecard.com
           weboldalon találhatók.

     A paysafecard fizető eszköz, melynek
                kibocsájtója a
      Prepaid Services Company Ltd. UK

}


// =============================================================================
           procedure TPAYSAFEFORM.TEARGOMBClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Letépte a vevö példányát és odaadta');
  TeardownPanel.Visible := False;
  Form1.Logbair('Saját példányát nyomtatja');
  SajatPeldanyNyomtatas;

  with SajatPanel do
    begin
      Top := 494;
      Left := 112;
      Bringtofront;
      Visible := true;
    end;
  Visszagomb.Visible := false;
  Form1.Logbair('Kiirja: A saját példányt alá kell iratni az ügyféllel');
  PSOkeGomb.Enabled := True;
  Activecontrol := PSOKEGOMB;
end;

// =============================================================================
           procedure TPAYSAFEFORM.PSOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  SajatPanel.Visible := false;
  Shape1.Repaint;

  _tranzakcio := _serial;

  Form1.Logbair('Megnyomta a rendben gombot - Paysafecard könyvelése indul');
  Form1.Konyveles('P');

  Sleep(2500);
  _fizetendo := 0;
  Modalresult := 1;
end;

end.


