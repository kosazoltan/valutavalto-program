unit Unit10;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, Unit1, ComCtrls,  strutils,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP;

type
  TPAYSAFEFORM = class(TForm)

    InfoText     : TLabel;
    Label1       : TLabel;
    Label2       : TLabel;
    Label3       : TLabel;
    Label4       : TLabel;

    Shape1       : TShape;
    Shape2       : TShape;

    IgenyGomb    : TBitBtn;
    MegsemGomb   : TBitbtn;
    PSOkeGomb    : TBitBtn;
    TearGomb     : TBitBtn;
    VisszaGomb   : TBitBtn;

    FTPanel1     : TPanel;
    FTPanel2     : TPanel;
    FTPanel3     : TPanel;
    FTPanel4     : TPanel;
    IgenyPanel   : TPanel;
    SajatPanel   : TPanel;
    SikerPanel   : TPanel;
    TearDownPanel: TPanel;
    VEGSZALAG: TPanel;
    varopanel: TPanel;
    Label5: TLabel;
    Label6: TLabel;
    varomemo: TMemo;

    procedure FormActivate(Sender: TObject);
    procedure FTPanel1Enter(Sender: TObject);
    procedure FTPanel1Exit(Sender: TObject);
    procedure FTPanel1Click(Sender: TObject);
    procedure FTPanel1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure IgenyGombClick(Sender: TObject);
    procedure MegsemGOMBClick(Sender: TObject);
    procedure PSOkeGombClick(Sender: TObject);
    procedure SajatpeldanyNyomtatas;
    procedure TearGombClick(Sender: TObject);
    procedure VevopeldanyNyomtatas;
    procedure VisszaGombClick(Sender: TObject);
    procedure Konyveles;

    function Replyread: boolean;
    function Adatkereso(_kulcs: string): string;
    function Keresem(_mit: string): string;
    function Adatkinyero: boolean;
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PAYSAFEFORM: TPAYSAFEFORM;

  _ftPanel  : array[1..4] of TPanel;
  _ftcszam  : array[1..4] of integer = (304,301,302,303);
  _ftOsszeg : array[1..4] of Integer = (2000,5000,10000,25000);

  _chartomb: array[1..2048] of char;

  _lineDarab,_p1len,_y,_kifizosszeg,_backosszeg,_backsum: integer;
  _tiras: Textfile;

  _mondat,_paysfile,_xrprint1,_pinkod,_ige,_serialnums: string;
  _mondelo,_osszegs,_serial,_idos,_infotext: string;
  _statusDesc,_transId,_backsums: string;

  _mondatdarab,_pp: byte;
  _aktmondat : string;
  _repMondat: array[1..99] of string;
  _txtolvas: textfile;
  _xx : byte;

  _tetel   : Byte;
  _aktPanel: TPanel;
  _maymove : boolean;

  _olvas: File of char;

implementation


{$R *.dfm}

// =============================================================================
               procedure TPAYSAFEFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := _top+8;
  Left := _left+8;

  Vegszalag.Visible     := False;
  IgenyPanel.Visible    := False;
  SikerPanel.Visible    := False;
  TearDownPanel.Visible := False;
  SajatPanel.Visible    := False;
  _maymove              := True;

  VisszaGomb.Visible := True;

  _ftPanel[1] := FtPanel1;    // 2 ezer forint
  _ftPanel[2] := FtPanel2;    // 5 ezer forint
  _ftPanel[3] := FtPanel3;    // 10 ezer forint
  _ftPanel[4] := FtPanel4;    // 25 ezer forint

  _ezPaySafeCard := True;

  _farok := midstr(_mamas,3,2)+midstr(_mamas,6,2);
  _tablanev := 'TRAD' + _farok;

  Activecontrol := FTPanel1;  // 2 ezer forintos
end;

// =============================================================================
           procedure TPAYSAFEFORM.FTPANEL1Click(Sender: TObject);
// =============================================================================

var _infotext: string;

begin

  // Szabad választani:

  if not _maymove then exit;

  Visszagomb.Visible := False; // nincs vissza ut

  _tetel    := TPanel(Sender).Tag;   // Tétel: 1 2 3 4
  _maymove  := False;                // Nincs tovább választás
  _cikkszam := _ftCszam[_tetel];     // A kért a cikkszám
  _psosszeg := _ftOsszeg[_tetel];    // A kért foritösszeg

  _infoText := 'Az ügyfél igényel egy '+ form1.ftform(_psosszeg)
                                         + ' forintos paysafecard kódot';

  Form1.Logbair(_infotext);

  Infotext.caption := _infotext;
  Infotext.repaint;

  with IgenyPanel do
    begin
      Top     := 496;
      Left    := 185;
      Visible := True;
      repaint;
    end;
  ActiveControl := Megsemgomb;  // Igény Gomb - Mégsem gomb
end;

// ======================== IGÉNYLÉS ÖSSZEÁLLITÁSA =============================
// =============================================================================
              procedure TPAYSAFEFORM.IgenyGombClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Igénylö gombra kattintott - tehat keri a card-ot');

  _reqrow[1] := '<Message>';
  _reqrow[2] := '<MessageType>PAYSAFECARD</MessageType>';
  _reqrow[3] := '<TerminalId>' + _terminalid + '</TerminalId>';
  _reqrow[4] := '<UserName>' + _username + '</UserName>';
  _reqrow[5] := '<UserPassword>' + _password + '</UserPassword>';
  _reqrow[6] := '<ProductId>'+inttostr(_cikkszam)+'</ProductId>';
  _reqrow[7] := '</Message>';

  _reqpieces := 7;    // ENNYI SORA  VAN AZ XML-NEK

  Form1.Logbair('Az igénylés ('+ inttostr(_cikkszam)+' számú)-cikkre elküldve');
  Form1.Logbair('Az igénylö csomag rendben elküldve -  Válaszra vár a gép');

  Form1.CsomagKuldes;
  IgenyPanel.Visible := false;

  varomemo.Clear;
  varomemo.Lines.Clear;
  with Varopanel do
    begin
      top := 496;
      left := 185;
      Visible := true;
      repaint;
    end;

  if not ReplyRead then
    begin
      Form1.Logbair('Nem jött válasz-file - kilépés');
      _hibauzenet := 'Nem jött válasz !';
      ShowMessage(_hibauzenet);
      ModalResult := 2;
      Exit;
    end;

  Form1.Logbair('Megjött a válasz a paysafecard kérelemre');

  // A következõ adatok kerülnek kinyerésre:
  // _pinkod, _serial, _backsum, _status, _statusdesc, _transid

  if not adatkinyero then
    begin
      Form1.Logbair('Hibás válasz: ' + _hibauzenet );
      Showmessage('Hibás válasz: ' + _hibauzenet);
      Modalresult := 2;
      exit;
    end;

  Shape1.repaint;
  Form1.Logbair('SIKERES PAYSAFECARD TRANZAKCIÓ');

  with SikerPanel do
    begin
      Top     := 175;
      Left    := 170;
      Visible := True;
      Bringtofront;
      Repaint;
    end;

  inc(_lastTelefon);
  _bizonylatszam := 'P' + form1.HatNulele(_lastTelefon);

  Form1.Logbair('Kinyomtatja a vevö példányát');
  VevoPeldanyNyomtatas;
  Shape1.repaint;

  with TeardownPanel do
    begin
      Top := 494;
      Left := 112;
      Visible := true;
      Bringtofront;
    end;

  Form1.Logbair('Kiirja: Tépje le a vevö példányát és adja oda');
  Activecontrol := Teargomb;
end;

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
  Form1.Logbair('Kiirja: A saját példányt alá kell iratni az ügyféllel');
  Form1.Logbair('Most megnyomhatja a rendben gombot');
  PSOkeGomb.Enabled := True;
  Activecontrol := PSOKEGOMB;
end;


// =============================================================================
           procedure TPAYSAFEFORM.PSOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  SajatPanel.Visible := false;
  Shape1.Repaint;
  with Vegszalag do
    begin
      top := 624;
      left := 232;
      Visible := true;
      repaint;
    end;

  Form1.Logbair('Megnyomta a rendben gombot - Paysafecard könyvelése indul');
  Konyveles;

  Form1.Logbair('A könyvelést rendben elvégezte');
  sleep(2500);
  _fizetendo  := 0;
  Modalresult := 1;
end;

//  ======================== VÉGE A PROGRAMNAK =================================


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
              procedure TPaysafeForm.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  Form1.Logbair('Mégsem kérnek paysafecard-ot.  Vissza a menüre');
  Form1.Logbair(dupestring('-',80));
  ModalResult := 1;
end;


// =============================================================================
               function TPaysafeForm.Replyread: boolean;
// =============================================================================

var  _count : byte;
    _megjott: boolean;

begin
  result := false;
  Form1.Logbair('Várok a válaszra 1. probalkozas');
  Varomemo.Lines.Add('1. próbálkozás ...');

  _megjott := False;
  _count := 1;
  while _count<=3 do
    begin
      if fileExists(_replyPath) then
        begin
          _megjott := True;
          break;
        end;

      sleep(3000);
      inc(_count);
      Form1.Logbair(' - ' + inttostr(_count)+'. probalkozas');
      VAroMemo.Lines.Add(inttostr(_count)+'. próbálkozás ...');
    end;

  VaroPanel.Visible := False;
  Shape1.repaint;  

  if not _megjott then
    begin
      Form1.Logbair('Nem jött válasz 3 probálkozás után sem');
      exit;
    end;

  Form1.Logbair('A válasz megérkezett !');

  _xx := 0;

  Assignfile(_txtolvas,_replypath);
  reset(_txtOlvas);
  while not eof(_txtolvas) do
    begin
      readln(_txtolvas,_aktmondat);
      if _aktMondat<>'' then
        begin
          inc(_xx);
          _repMondat[_xx] := _aktmondat;
        end;
    end;
  closeFile(_txtOlvas);
  _mondatdarab := _xx;
  if _xx>0 then result := True else Form1.Logbair('Üres válasz érkezett');

end;

// =============================================================================
               function TPaysafeform.AdatKinyero: boolean;
// =============================================================================

begin
  result := false;

  _status    := Adatkereso('<StatusId>');
  _statusDesc:= Adatkereso('<StatusDescription>');
  _TransId   := Adatkereso('<TransactionId>');

  If leftstr(_status,4)<>'00OK' then
    begin
       Form1.Logbair('A válasz negativ: '+_statusdesc);
      _HibaUzenet := _StatusDesc;
      exit;
    end;
  _pinkod   := Keresem('PIN-CODE: ');
  _serial   := Keresem('Sorozatszám: ');
  _backsums := Keresem('Összeg: ');
  _backsums := leftstr(_backsums,length(_backsums)-4);
  val(_backsums,_backsum,_code);
  if _code<>0 then _backsum := 0;

  result := true;

end;

// =============================================================================
           function TPaysafeform.Adatkereso(_kulcs: string): string;
// =============================================================================

var _asc,_wk,_wm: byte;

begin
  _wk := length(_kulcs);
  _xx := 1;
  while _xx<10 do
    begin
      _aktmondat := _repMondat[_xx];
      _wm := length(_aktmondat);
      if leftstr(_aktmondat,_wk) = _kulcs then
        begin
          result := '';
          _pp := _wk+1;
          while _pp<_wm do
            begin
              _asc := ord(_aktmondat[_pp]);
              if _asc=60 then exit;

              result := result + chr(_asc);
              inc(_pp);
            end;
        end;
      inc(_xx);
    end;
end;

// =============================================================================
            function TPaysafeForm.Keresem(_mit: string): string;
// =============================================================================

var _mw: byte;

begin
  result := '';
  _xx := 10;
  while _xx<=_mondatdarab do
    begin
      _mw := length(_mit);
      _aktmondat := _repmondat[_xx];
      _wm := length(_aktmondat);

      if leftstr(_aktmondat,_mw)=_mit then
        begin
          result := midstr(_aktmondat,_mw+1,_wm-_mw);
          exit;
        end;
      inc(_xx);
    end;
end;


// ========================== NYOMTZATVÁNYOK ===================================
// =============================================================================
             procedure TPaysafeForm.VevoPeldanyNyomtatas;
// =============================================================================

begin
  _idos := timetostr(Time);
  Form1.BlokkNyitas;
  Form1.BlokkFocimIro;

  Form1.Logbair('A vevöpéldányt nyomtatrja');
  Form1.Logbair('  - tranzakció ID: ' + _transid);
  Form1.Logbair('  - sorozatszaám : ' + _serial);
  Form1.Logbair('  - bizonylatszam: ' + _bizonylatszam);
  Form1.Logbair('  - paysafepinkod: ' + _pinkod);

  writeLn(_LFile,_sorveg+'          PAYSAFECARD CLASSIC');
  writeLn(_LFile,_sorveg+'Terminal - ID: '+ _terminalid);
  writeLn(_LFile,'Tranzakcio ID: ' + _TransId+_sorveg);
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

  Form1.Logbair('Sikeresen kinyomtatatta a vevõ példányát');
end;

// =============================================================================
               procedure TPaysafeForm.SajatPeldanyNyomtatas;
// =============================================================================

begin
  Form1.Logbair('Itt kezdi nyomtatni a saját példányt');
  Form1.Logbair('  - bizszam: ' + _bizonylatszam);
  Form1.Logbair('  - osszeg : ' + inttostr(_psosszeg));

  Form1.Blokknyitas;
  Form1.BlokkFocimIro;
  writeLn(_LFile,_sorveg+'          PAYSAFECARD CLASSIC');
  writeLn(_LFile,_sorveg+'Terminal - ID: '+ _terminalid);
  writeLn(_LFile,'Tranzakcio ID: ' + _TransId+_sorveg);
  writeLn(_LFile,'Datum : ' + _mamas+'  Ido: '+_idos);
  writeLn(_LFile,'Osszeg: ' + Form1.ftForm(_psosszeg));
  writeLn(_LFile,'S.szam: ' + _serial);
  writeLn(_LFile,'B.szam: ' + _bizonylatszam);
  writeLn(_LFile,_sorveg+_sorveg+'    2 peldany nyomtatvanyt atvettem');
  writeLn(_lfile,_sorveg+_sorveg);
  writeln(_LFile,'........................................');

  Form1.StartNyomtatas;

  Form1.Logbair('Sikeresen befejezte a saját példány nyomtatását');

end;


procedure TPaysafeForm.Konyveles;

begin

  Form1.Logbair('Paysafecard konyvelese');

  Form1.Logbair('  - bizonylat: '+_bizonylatszam);
  Form1.Logbair('  - fizetendö: '+ inttostr(_psOsszeg));

  _pcs := 'INSERT INTO ' + _tablanev + ' (TIPUS,BIZONYLATSZAM,TRANZAKCIO,';
  _pcs := _pcs + 'FIZETENDO,PENZTAROSNEV,DATUM,IDO,SZOLGALTATO,SZOLGALTATAS,ELKULDVE)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + 'P' +chr(39)+',';
  _pcs := _pcs + chr(39) + _bizonylatszam + chr(39) + ',';
  _pcs := _pcs + chr(39) + _serial + chr(39) + ',';

  _pcs := _pcs + inttostr(_psOsszeg) + ',';
  _pcs := _pcs + chr(39) + trim(_prosnev) + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _idos + chr(39)+ ',';
  _pcs := _pcs + chr(39) + 'PREPAID' +chr(39) +',';
  _pcs := _pcs + chr(39) + 'PaySafeCard' + chr(39)+',';
  _pcs := _pcs + inttostr(_cikkszam)+')';

  Form1.TradeParancs(_pcs);
  Form1.Logbair('Sikeresen lekönyveltem '+_bizonylatszam + ' szamu bizonylatot');

  _pcs := 'UPDATE PARAMETERS SET LASTTELEFON='+inttostr(_lasttelefon);
  Form1.TradeParancs(_pcs);
  Form1.Logbair('Rogzitettem az utolsó bizonylatszam szamat');
end;




////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////




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
     lag a paysafecard szerzõdéses partne-
     reinél használható fel online fizetési
                 eszközként.
      A paysafecard kupont soha nem szabad
     idegeneknek átadni, vagy a paysafecard
     által elfogadott szerzõdéses partnere-
     ken kívül más kifizetésekre használni.

      A PIN-kód megadására vonatkozó telefo-
     nos vagy e-mailes felszólításnak soha-
            sem szabad eleget tenni.

        Help: www.paysafecard.com/help
        Hétfö-Péntek: 09:30 - 15:30 óráig
        E-Mail: info.hu@paysafecard.com

     A paysafecard kereskedelemben történõ
     továbbértékesítése tilos.Az általános
     üzleti feltételek www.paysafecard.com
           weboldalon találhatók.

     A paysafecard fizetõ eszköz, melynek
                kibocsájtója a
      Prepaid Services Company Ltd. UK

}







end.


