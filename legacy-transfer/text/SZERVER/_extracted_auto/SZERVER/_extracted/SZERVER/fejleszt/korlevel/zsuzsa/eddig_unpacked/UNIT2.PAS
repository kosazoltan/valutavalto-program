unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery, Grids, DBGrids, IBTable;

type
  Tsuperform = class(TForm)

    BanPanel        : TPanel;
    DelPanel        : TPanel;
    FolyamatPanel   : TPanel;
    InsPanel        : TPanel;
    KismenuPanel    : TPanel;
    ValasztottPanel : TPanel;

    Label1          : TLabel;
    Label2          : TLabel;
    Label3          : TLabel;
    Label4          : TLabel;
    Label5          : TLabel;

    BanSign         : TBitBtn;
    DelReturnGomb   : TBitBtn;
    InsertGomb      : TBitBtn;
    KlDelete        : TBitBtn;
    KlInsert        : TBitBtn;
    KlReadList      : TBitBtn;
    KilepoGomb      : TBitBtn;
    MegsemTiltGomb  : TBitBtn;
    RemoveGomb      : TBitBtn;
    Tiltogomb       : TBitBtn;
    ValasztoGomb    : TBitBtn;
    VisszaGomb      : TBitBtn;

    Shape1          : TShape;

    KorlQuery       : TIBQuery;
    KorlDbase       : TIBDatabase;
    KorlTranz       : TIBTransaction;
    KorlTabla       : TIBTable;

    DelRacs         : TDBGrid;
    InsRacs         : TDBGrid;

    DelSource       : TDataSource;
    InsSource       : TDataSource;

    OpenDialog1     : TOpenDialog;

    Szignoedit      : TEdit;

    procedure BanSignClick(Sender: TObject);
    procedure DelReturnGombClick(Sender: TObject);
    procedure FolyamatDisplay;
    procedure FormActivate(Sender: TObject);
    procedure InsertGombClick(Sender: TObject);
    procedure KilepoGombClick(Sender: TObject);
    procedure KismenuStart;
    procedure KlDeleteClick(Sender: TObject);
    procedure KlInsertClick(Sender: TObject);
    procedure KlReadLISTClick(Sender: TObject);
    procedure KorlOpen;
    procedure RemoveGombClick(Sender: TObject);
    procedure SzignoEditEnter(Sender: TObject);
    procedure SzignoeditExit(Sender: TObject);
    procedure SzignoeditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure TiltogombClick(Sender: TObject);
    procedure ValasztoGombClick(Sender: TObject);
    procedure VisszaGombClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  superform: Tsuperform;

  _sorveg: string = chr(13)+chr(10);

  _insFilePath,
  _pcs,
  _tiltottszigno: string;

  _aktorder,
  _aktsorszam,
  _aktsorrend,
  _dIndex,
  _lastsorrend,
  _sr: word;

  _storno: byte;

implementation

uses Unit1, Unit3;

{$R *.dfm}


// =============================================================================
              procedure Tsuperform.FormActivate(Sender: TObject);
// =============================================================================

begin

  BanPanel.visible := False;
  DelPanel.Visible := False;
  InsPanel.Visible := False;
  FolyamatPanel.Visible := False;
  KismenuStart;

end;

// =============================================================================
            procedure Tsuperform.KLINSERTClick(Sender: TObject);
// =============================================================================

begin
  InsertGomb.Enabled := False;
  Valasztogomb.Enabled := True;
  KismenuPanel.Visible := False;

  KorlOpen;

  with InsPanel do
    begin
      Top  := 16;
      Left := 128;
      Visible := True;
    end;
  InsSource.Enabled := true;
  InsRacs.SetFocus;
end;

// =============================================================================
             procedure Tsuperform.KilepoGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
               procedure Tsuperform.KlDeleteClick(Sender: TObject);
// =============================================================================

begin
  KismenuPanel.Visible := False;
  KorlOpen;

  with DelPanel do
    begin
      Top  := 16;
      Left := 128;
      Visible := True;
    end;
  DelSource.Enabled := true;
  DelRacs.SetFocus;

end;

// =============================================================================
               procedure Tsuperform.DelReturnGombClick(Sender: TObject);
// =============================================================================

begin
  KorlQuery.close;
  KorlDbase.close;
  DelPanel.Visible := False;
  Kismenustart;
end;


// =============================================================================
                          procedure TsuperForm.KorlOpen;
// =============================================================================

begin
   _pcs := 'SELECT * FROM '+_currLettName + _sorveg;
  _pcs := _pcs + 'WHERE STORNO<2' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORREND';

  KorlDbase.close;
  Korldbase.DatabaseName := _serverFdbPath;
  KorlDbase.Connected := true;
  with KorlQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _Lastsorrend := FieldByName('SORREND').asInteger;
      First;
    end;
end;


// =============================================================================
                      procedure TSuperForm.KismenuStart;
// =============================================================================

begin
  with KismenuPanel do
    begin
      top  := 160;
      left := 230;
      Visible := True;
    end;
end;

// =============================================================================
            procedure Tsuperform.RemoveGombClick(Sender: TObject);
// =============================================================================

begin
  _aktsorszam := Korlquery.fieldByName('SORSZAM').asInteger;
  _aktSorrend := Korlquery.FieldByName('SORREND').asInteger;
  Korlquery.Close;
  Korldbase.close;

  _pcs := 'UPDATE ' + _currLettName + ' SET STORNO=2' + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + inttostr(_aktsorszam);

  fORM1.SERVERParancs(_pcs);
  DelSource.Enabled := False;

  Form1.SorrendRegen;
  DelPanel.Visible := false;
  Kismenustart;

end;


// =============================================================================
               procedure Tsuperform.ValasztoGombClick(Sender: TObject);
// =============================================================================

begin
  if not OpenDialog1.Execute then exit;

  Valasztogomb.Enabled := false;
  _localPath := Opendialog1.FileName;

  Form1.SetvalasztottFile;

  ValasztottPanel.Caption := _tartalom;
  Insertgomb.Enabled := True;
  Insracs.SetFocus;
end;


// =============================================================================
             procedure Tsuperform.InsertGombClick(Sender: TObject);
// =============================================================================

begin
  if _localPath='' then exit;

  Folyamatdisplay;

  _aktorder := KorlQuery.FieldByName('SORREND').asInteger;

  KorlQuery.close;
  Korldbase.close;

  Insertgomb.Enabled := False;
  VisszaGomb.Enabled := false;

  if not Form1.SendRoundletter then exit;

  _pcs := 'INSERT INTO ' + _currLettName + ' (IKTATOSZAM,DATUM,TARTALOM,';
  _pcs := _pcs + 'SORSZAM,SORREND,STORNO,FILENEV)'+ _sorveg;

  _pcs := _pcs + 'VALUES (' + CHR(39) + _iktatostring + chr(39) + ',';
  _pcs := _pcs + chr(39) + _mamas + chr(39) + ',';
  _pcs := _pcs + chr(39) + _tartalom + chr(39) + ',';
  _pcs := _pcs + inttostr(_IKTATOSZAM) + ',';
  _pcs := _pcs + inttostr(_aktOrder+1) + ',1,';
  _pcs := _pcs + chr(39) + _remotefile + chr(39)+')';

  Form1.ServerParancs(_pcs);

  _pcs := 'UPDATE IKTATOSZAM SET IKTATOSZAM='+inttostr(_iktatoszam);
  Form1.ServerParancs(_pcs);

  Form1.SorrendRegen;

  Form1.Ertesites;

  InsPanel.Visible := False;
  Visszagomb.Enabled := True;
  Folyamatpanel.Visible := false;
  KismenuStart;

end;

// =============================================================================
           procedure Tsuperform.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  KorlQuery.close;
  Korldbase.close;
  InsPanel.Visible := False;
  KismenuStart;
end;


// =============================================================================
                    procedure TsuperForm.FolyamatDisplay;
// =============================================================================

begin
  with FolyamatPanel do
    begin
      Top     := 328;
      Left    := 192;
      Visible := True;
      repaint;
    end;
end;


procedure Tsuperform.BANSIGNClick(Sender: TObject);
begin
  szignoedit.clear;
  with BanPanel do
    begin
      Top := 400;
      Left := 224;
      Visible := True;
    end;
  Activecontrol := szignoedit;
end;

// =============================================================================
           procedure Tsuperform.szignoeditEnter(Sender: TObject);
// =============================================================================

begin
  SzignoEdit.Color := clyellow;
end;

// =============================================================================
          procedure Tsuperform.szignoeditExit(Sender: TObject);
// =============================================================================

begin
  Szignoedit.Color := clwhite;
end;

// =============================================================================
    procedure Tsuperform.szignoeditKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

begin
  if ord(Key)<>13 then exit;
  Activecontrol := Tiltogomb;
end;


// =============================================================================
           procedure Tsuperform.tiltogombClick(Sender: TObject);
// =============================================================================

begin
  _tiltottszigno := trim(Szignoedit.Text);
  if _tiltottszigno='' then exit;

  Banpanel.Visible := False;
  _pcs := 'INSERT INTO TILTOTT (SZIGNO)'+_sorveg;
  _pcs := _pcs + 'VALUES ('+chr(39)+_tiltottszigno+chr(39)+')';
  Form1.serverParancs(_pcs);
  Form1.GetTiltott;
end;

// =============================================================================
             procedure Tsuperform.KlReadListClick(Sender: TObject);
// =============================================================================

begin
  ReadTimeForm.Showmodal;
end;
end.

