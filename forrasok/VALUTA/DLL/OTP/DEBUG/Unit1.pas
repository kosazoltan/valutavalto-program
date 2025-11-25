unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery;

type
  TForm1 = class(TForm)
    XQUERY: TIBQuery;
    XDBASE: TIBDatabase;
    XTRANZ: TIBTransaction;
    Panel1: TPanel;
    comctrlgomb: TBitBtn;
    prosbegomb: TBitBtn;
    KISVALTOGOMB: TBitBtn;
    NAGYVALTOGOMB: TBitBtn;
    PROSKIGOMB: TBitBtn;
    TERMZAROGOMB: TBitBtn;
    STORNOGOMB: TBitBtn;
    KILEPGOMB: TBitBtn;
    Label1: TLabel;
    VISSZAVETGOMB: TBitBtn;
    PARALETOLTGOMB: TBitBtn;
    REPLYCOMGOMB: TBitBtn;
    REPRINTGOMB: TBitBtn;


    procedure Menet;
    procedure comctrlgombClick(Sender: TObject);
    procedure Xparancs(_ukaz: string);
    procedure KILEPGOMBClick(Sender: TObject);
    procedure prosbegombClick(Sender: TObject);
    procedure KISVALTOGOMBClick(Sender: TObject);
    procedure NAGYVALTOGOMBClick(Sender: TObject);
    procedure STORNOGOMBClick(Sender: TObject);
    procedure PROSKIGOMBClick(Sender: TObject);
    procedure TERMZAROGOMBClick(Sender: TObject);
    procedure VISSZAVETGOMBClick(Sender: TObject);
    procedure PARALETOLTGOMBClick(Sender: TObject);
    procedure REPLYCOMGOMBClick(Sender: TObject);
    procedure REPRINTGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _toke  : integer;
  _sorveg: string = chr(13)+chr(10);
  _pcs   : string;
  

implementation

uses Unit2;

{$R *.dfm}

// =============================================================================
                           procedure TForm1.Menet;
// =============================================================================

begin
  _toke := oTPTERM.showmodal;
  if _toke=1 then showmessage('TRANZAKCIÓ RENDBEN');
  if _toke=2 then showmessage('SIKERTELEN TRANZAKCIÓ');
  if _toke=3 then Showmessage('INKÁBB KÉSZPÉNZZEL FIZET');
end;

// =============================================================================
           procedure TForm1.comctrlgombClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (95)';
  xParancs(_pcs);

  Menet;
end;

// =============================================================================
                  procedure TForm1.Xparancs(_ukaz: string);
// =============================================================================

begin
  xdbase.Connected := true;
  if xtranz.InTransaction then xtranz.commit;
  xtranz.StartTransaction;
  with xquery do
    begin
      close;
      sql.clear;
      sql.Add(_ukaz);
      Execsql;
    end;
  xtranz.commit;
  xdbase.close;
end;

// =============================================================================
            procedure TForm1.KILEPGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.terminate;
end;

// =============================================================================
            procedure TForm1.prosbegombClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE HARDWARE SET PENZTAROSNEV='+chr(39)+'DÉKÁNY ANTAL'+chr(39);
  _pcs := _pcs + ',IDKOD=' + chr(39) + '10949' + chr(39);
  xParancs(_pcs);

  _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (50)';
  xParancs(_pcs);

  Menet;
end;

// =============================================================================
           procedure TForm1.KISVALTOGOMBClick(Sender: TObject);
// =============================================================================

begin
    _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (FIZETENDO,BIZONYLATSZAM,OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (4500,';
  _pcs := _pcs + chr(39) + 'V143500894'  + CHR(39) + ',0)';
  xParancs(_pcs);
  Menet;
end;


// =============================================================================
            procedure TForm1.NAGYVALTOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (FIZETENDO,BIZONYLATSZAM,OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (330000,';
  _pcs := _pcs + chr(39) + 'E113000123'  + CHR(39) + ',0)';

  xParancs(_pcs);
  Menet;

end;

// =============================================================================
           procedure TForm1.STORNOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (BIZONYLATSZAM,FIZETENDO,OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39)+'E194962800' + chr(39) + ',';
  _pcs := _pcs + '56400,';
  _pcs := _pcs + '100)';
  xParancs(_pcs);

  Menet;
end;

// =============================================================================
              procedure TForm1.PROSKIGOMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE HARDWARE SET PENZTAROSNEV='+chr(39)+'DÉKÁNY ANTAL'+chr(39);
  _pcs := _pcs + ',IDKOD=' + chr(39) + '10949' + chr(39);
  xParancs(_pcs);

  _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (51)';
  xParancs(_pcs);

  Menet;

end;

// =============================================================================
            procedure TForm1.TERMZAROGOMBClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (60)';
  xParancs(_pcs);

  Menet;
end;

// =============================================================================
              procedure TForm1.VISSZAVETGOMBClick(Sender: TObject);
// =============================================================================

begin
   _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (FIZETENDO,OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + chr(39) + 'E113000123'  + CHR(39) + ',4)';

  xParancs(_pcs);
  Menet;

end;

// =============================================================================
           procedure TForm1.PARALETOLTGOMBClick(Sender: TObject);
// =============================================================================

begin
   _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (90)';

  xParancs(_pcs);
  Menet;

end;

procedure TForm1.REPLYCOMGOMBClick(Sender: TObject);
begin
  _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (101)';
  xParancs(_pcs);

  Menet;

end;

procedure TForm1.REPRINTGOMBClick(Sender: TObject);
begin
  _pcs := 'DELETE FROM VTEMP';
  xParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (OTPFUNCTYPE)' + _sorveg;
  _pcs := _pcs + 'VALUES (102)';
  xParancs(_pcs);

  Menet;
end;

end.
