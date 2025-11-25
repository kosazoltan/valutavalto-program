unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, OleCtrls, SHDocVw, ExtCtrls, jpeg,
  IdBaseComponent, IdMessage, activex, IBDatabase, DB, IBCustomDataSet,
  IBQuery, ComCtrls;

type
  TForm1 = class(TForm)

    StartGomb     : TBitBtn;
    KilepoGomb    : TBitBtn;

    WebBrowser1   : TWebBrowser;

    Label1        : TLabel;
    Label2        : TLabel;
    Label3        : TLabel;
    Label4        : TLabel;
    Label5        : TLabel;

    FinishPanel   : TPanel;
    KatPanel      : TPanel;
    MemoPanel     : TPanel;
    NyilTorloPanel: TPanel;

    Nyil          : TImage;

    IBQuery       : TIBQuery;
    IBDbase       : TIBDatabase;
    IBTranz       : TIBTransaction;

    Memo1         : TMemo;


    Shape1        : TShape;
    Shape2        : TShape;
    Shape3        : TShape;
    UZENOPANEL: TPanel;
    XMLGOMB: TBitBtn;
    csikpanel: TPanel;
    csik: TProgressBar;

    procedure FormActivate(Sender: TObject);
    procedure StartGombClick(Sender: TObject);
    procedure TParancs(_ukaz: string);
    procedure XmlMaking;
    procedure FDBMaking;
    procedure MakeRutin;
    procedure KilepoGombClick(Sender: TObject);


    function GetZarojel: string;
    function GetNev: string;
    function Betukiemelo(_s: string): string;

    procedure XMLGOMBClick(Sender: TObject);
    procedure WebBrowser1DocumentComplete(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _urL1   : string = 'https://www.un.org/securitycouncil/content/un-sc-consolidated-list';
  _xmlPath: string = 'c:\temp\terrorlist.xml';
  _sorveg : string = chr(13)+chr(10);
  _workdir: STRING = 'c:\temp';
  _host   : string = '185.43.207.99';

  _bytetomb: array[1..8] of byte;

  _betu,_complett: byte;
  _name_count,_item,_hossz,_nevdarab: integer;

  _sss,_text,_pcs,_zarojel,_fnev,_sNev,_tnev,_aktnev: string;

  _iras : textfile;
  _olvas: file of byte;
  _doc  : variant;

  _may: boolean;

implementation

{$R *.dfm}

// =============================================================================
               procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin
  _complett := 0;

  if not directoryExists(_workdir) then createdir(_workdir);
  if fileExists(_xmlPath) then Sysutils.DeleteFile(_xmlPath);
  ActiveControl := startGomb;
end;

// =============================================================================
             procedure TForm1.StartGombClick(Sender: TObject);
// =============================================================================

begin
  NyiltorloPanel.Visible := True;
  StartGomb.Visible      := False;
  WebBrowser1.Navigate(_urL1);
end;

// =============================================================================
                      procedure TForm1.XmlMaking;
// =============================================================================

begin
   UzenoPanel.Caption := 'A dokumentum rögzitése a TEMP könyvtárba ...';
   Uzenopanel.Visible := True;
   UzenoPanel.repaint;

   _doc := WebBrowser1.Document;
   with TStringList.Create do
     try
       _Text := _doc.Body.InnerText;
       AssignFile(_iras,_xmlPath);
       Rewrite(_iras);
       write(_iras,_text);
       closefile(_iras);
     finally
       Free;
     end;

   sleep(2200);
   Makerutin;
end;

// =============================================================================
                         procedure TForm1.MakeRutin;
// =============================================================================

begin
  FdbMaking;
  UzenoPanel.Caption := 'Az adatbázis fel lett frissitve !';
  Uzenopanel.repaint;
  MemoPanel.Visible   := False;
  FinishPanel.Visible := True;
  Activecontrol       := KilepoGomb;
end;


// =============================================================================
                        procedure TForm1.FdbMaking;
// =============================================================================

begin
  UzenoPanel.Caption := 'A nevek kiemelése az Xml file-ból';
  UzenoPanel.repaint;

  MemoPanel.Visible :=true;
  MemoPanel.Repaint;

  AssignFile(_olvas,_xmlPath);
  reset(_olvas);

  _zarojel := getZarojel;
  _fnev := '';

  while _zarojel<>'/INDIVIDUALS' do
    begin
      _zarojel := getZarojel;
      if _zarojel='FIRST_NAME' then
         begin
           if _fnev<>'' then Memo1.Lines.Add(_fnev);
           _fnev := getnev;
         end;

      if _zarojel='SECOND_NAME' then
         begin
           _snev := getnev;
           if _fnev<>'' then _fnev := _fnev+' '+_snev;
         end;

      if _zarojel='THIRD_NAME' then
         begin
           _tnev := getnev;
           if _fnev<>'' then _fnev := _fnev + ' ' + _tnev
         end;
    end;
  Closefile(_olvas);
  if _fnev<>'' then Memo1.Lines.Add(_fnev);

  _nevdarab := Memo1.Lines.Count;

  Csik.Max := _nevdarab;
  Csik.Position := 0;

  // --------------------------------------------------------

  Uzenopanel.Caption := 'A nevek bemásolása az UNOLIST adatbázisba ...';
  Uzenopanel.repaint;

  _pcs := 'DELETE FROM UNOLIST';
  TParancs(_pcs);

  ibdbase.Connected := True;
  if ibtranz.InTransaction then ibtranz.commit;
  ibtranz.StartTransaction;

  _item := 1;
  CsikPanel.Visible := True;
  while _item<=_nevdarab do
    begin
      Csik.Position := _item;

      _aktnev := Memo1.lines[_item];
      _aktnev := Betukiemelo(_aktnev);
      _pcs := 'INSERT INTO UNOLIST (TERROR_NAME)'+_sorveg;
      _pcs := _pcs +'VALUES (' + chr(39) + _aktnev + chr(39) + ')';

      with IbQuery do
        begin
          Close;
          sql.clear;
          sql.add(_pcs);
          Execsql;
        end;
      inc(_item);
    end;
  ibtranz.commit;
  ibdbase.close;  
end;

// =============================================================================
                      function TForm1.getzarojel: string;
// =============================================================================

begin
  _may := False;
  result := '';

  while true do
    begin
      Blockread(_olvas,_BYTETOMB,1);
      _betu := _bytetomb[1];
      if _betu=62 then break;
      if _may then result := result + chr(_betu);
      if _betu=60 then _may := True;
    end;
end;

// =============================================================================
                      function TForm1.getnev: string;
// =============================================================================

begin
  result := '';
  while true do
    begin
      Blockread(_olvas,_bytetomb,1);
      _betu := _bytetomb[1];
      if _betu=60 then break;
      if (_betu>96) and (_betu<123) then _betu := _betu-32;
      if (_betu>64) and (_betu<91) then result := result + chr(_betu);
    end;
end;


// =============================================================================
                    procedure TForm1.Tparancs(_ukaz: string);
// =============================================================================

begin
  ibdbase.close;
  ibdbase.DatabaseName := _host + ':C:\RECEPTOR\DATABASE\TERRORISTS.FDB';
  ibdbase.connected := True;
  if ibtranz.InTransaction then Ibtranz.Commit;
  ibtranz.StartTransaction;
  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ibtranz.Commit;
  ibdbase.close;
end;


{
// =============================================================================
      procedure TForm1.WebBrowser1ProgressChange(Sender: TObject; Progress,
                                                          ProgressMax: Integer);
// =============================================================================

begin
  inc(_progress);
  Progpanel.Caption := inttostr(_progress);
  ProgPanel.repaint;
  if _progress=5 then NyiltorloPanel.Visible := False;
  if _progress=6 then NyiltorloPanel.Visible := true;
  if _progress=8 then Xmlgomb.Visible := True;
//  uzeno.Caption := inttostr(_progress)+'. Progress change';
//  uzeno.repaint;
end;

// =============================================================================
        procedure TForm1.WebBrowser1PropertyChange(Sender: TObject;
                                                const szProperty: WideString);
// =============================================================================

begin
  inc(_property);
  PropPanel.Caption := inttostr(_property);
  PropPanel.repaint;


//  uzeno.Caption := inttostr(_property)+'. Property change';
//  uzeno.repaint;
end;
}

// =============================================================================
            procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;


procedure TForm1.XMLGOMBClick(Sender: TObject);
begin
  xmlgomb.Visible := False;
  XmlMaking;
end;



procedure TForm1.WebBrowser1DocumentComplete(Sender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
begin
  inc(_complett);
  if _complett=1 then
    begin
      Nyiltorlopanel.Visible := False;

      Nyil.Visible     := true;
      KatPAnel.Visible := true;
      Nyil.repaint;
      KatPanel.repaint;
      Nyiltorlopanel.repaint;

      sleep (2500);
      NyiltorloPanel.visible := True;
      Nyiltorlopanel.repaint;
      exit;
    end;
  if _complett>1 then
    begin
      Xmlgomb.Visible := True;
      xmlgomb.Repaint;
    end;  
end;

function TForm1.Betukiemelo(_s: string): string;

var _ws,_pp: byte;

begin
  _s := trim(_s);
  _ws := length(_s);
  result := '';
  _pp := 1;
  while _pp<=_ws do
    begin
      _betu := ord(_s[_pp]);
      if (_betu>64) and (_betu<91) then result := result + chr(_betu);
      inc(_pp);
    end;
end;



end.
