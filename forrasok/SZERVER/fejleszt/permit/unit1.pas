unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, jpeg, strutils, IBDatabase, DB,
  IBCustomDataSet, IBQuery, IBTable;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    ENGEDELYEZOGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    Panel2: TPanel;
    DATUMCOMBO: TComboBox;
    PENZTARCOMBO: TComboBox;
    Panel3: TPanel;
    DNEMCOMBO: TComboBox;
    TRANZCOMBO: TComboBox;
    BANKJEGYEDIT: TEdit;
    Panel4: TPanel;
    FRADIO: TRadioButton;
    URADIO: TRadioButton;
    JRADIO: TRadioButton;
    FELEZESRADIO: TRadioButton;
    ELENGEDESRADIO: TRadioButton;
    CSOKKENTESRADIO: TRadioButton;
    ARFOLYAMEDIT: TEdit;
    ARFOLYAMRADIO: TRadioButton;
    KEZDIJRADIO: TRadioButton;
    MINDKETTORADIO: TRadioButton;
    Label1: TLabel;
    Shape1: TShape;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    DNEMPANEL1: TPanel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    DNEMPANEL2: TPanel;
    Label10: TLabel;
    MENUFUGGONY: TPanel;
    Label11: TLabel;
    Shape2: TShape;
    Image1: TImage;
    PERMITGOMB: TBitBtn;
    CONTROLGOMB: TBitBtn;
    ESCAPEGOMB: TBitBtn;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    PERMQUERY: TIBQuery;
    PERMDBASE: TIBDatabase;
    PERMTRANZ: TIBTransaction;
    PERMTABLA: TIBTable;


  procedure FormActivate(Sender: TObject);
  procedure Fomenu;
  procedure DatumComboTolto;
  procedure IrodakBetoltese;
    function Nul3(_b: byte):string;
    procedure PENZTARCOMBOChange(Sender: TObject);
    procedure KILEPOGOMBClick(Sender: TObject);
    procedure BANKJEGYEDITEnter(Sender: TObject);
    procedure BANKJEGYEDITExit(Sender: TObject);
    procedure DNEMCOMBOChange(Sender: TObject);
    procedure CreatePerm(_ptn: string);

    procedure ARFOLYAMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure engedelygombClick(Sender: TObject);

    procedure ARFOLYAMEDITEnter(Sender: TObject);
    procedure ARFOLYAMEDITExit(Sender: TObject);

    procedure FRADIOClick(Sender: TObject);
    procedure ARFOLYAMRADIOClick(Sender: TObject);
    procedure KEZDIJRADIOClick(Sender: TObject);
    procedure MINDKETTORADIOClick(Sender: TObject);
    procedure BANKJEGYEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure JRADIOClick(Sender: TObject);
    procedure ESCAPEGOMBClick(Sender: TObject);
    procedure PERMITGOMBClick(Sender: TObject);

    function Getidos: string;
    procedure CONTROLGOMBClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _XDNEM: array[1..22] of string = ('AUD','BAM','BGN','CAD','CHF','CNY','CZK','DKK',
                  'EUR','GBP','HRK','ILS','JPY','NOK','PLN','RON','RSD','RUB',
                  'SEK','TRY','UAH','USD');

  _etar: array[0..149] of byte;                
  _2,_3,_p1,_p2,_cc,_bss,_kezdijtorles,_jutmentes,_ertektar: byte;
  _snum,_jpw,_dnemindex,_itemindex,_aktpenztar,_bankjegy,_code: integer;
  _ujarfolyam,_ujkezdij,_qbankjegy,_qpenztar,_qarfolyam: integer;
  _qhnap,_qnap,_qho,_qev,_permitType: word;
  _aktdatum: TDatetime;
  _engBetu,_permNev,_qdnem,_qtranzjel: string;
  _ezArfolyam,_ezKezdij: boolean;
  _loByte,_hiByte: word;
  _arfolyams,_farok,_ptablanev,_ptarsor,_qdatums,_text: string;
  _pcs,_aktdnem,_tranzjel: string;
  _sorveg: string = chr(13)+chr(10);
  _tranzstr: array[1..3] of string = ('VALUTA VÉTEL','VALUTA ELADÁS',
                                                           'VALUTA KONVERZIÓ');

  _trjel: array[1..3] of string = ('V','E','K');

  _top,_left,_width,_height: word;


implementation

uses Unit2;

{$R *.dfm}



// =============================================================================
               procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

begin

  _width := Screen.Monitors[0].Width;
  _height:= Screen.Monitors[0].Height;

  _top := trunc((_height-446)/2);
  _left:= trunc((_width-812)/2);

  Top  := _top;
  Left := _left;
  Width := 814;
  Height:= 448;
  Fomenu;
end;


procedure TForm1.Fomenu;

begin
  with Menufuggony do
    begin
      top := 5;
      Left := 5;
      Visible := true;
    end;

  ActiveControl := Permitgomb;
end;

procedure TForm1.PERMITGOMBClick(Sender: TObject);

var i: integer;

begin
  Menufuggony.Visible := False;
  
  BankjegyEdit.Clear;
  ArfolyamEdit.clear;

  _bankJegy    := 0;
  _ujarfolyam  := 0;
  _ujkezdij    := 0;


  Elengedesradio.Checked  := False;
  elengedesRadio.Enabled  := False;

  CsokkentesRadio.Checked := False;
  CsokkentesRadio.Enabled := false;

  FelezesRadio.Checked    := False;
  FelezesRadio.Enabled    := False;

  Arfolyamradio.checked   := True;
  _ezArfolyam := True;
  _eZKezdij   := False;
  Fradio.Checked := true;

  DatumComboTolto;

  Tranzcombo.Items.Clear;
  for i := 1 to 3 do Tranzcombo.Items.add(_tranzstr[i]);
  Tranzcombo.ItemIndex := 0;

  IrodakBetoltese;
  DnemCombo.Items.clear;
  DnemCombo.Clear;
  for i := 1 to 22 do DnemCombo.Items.Add(_Xdnem[i]);
  DnemCombo.ItemIndex := 8;
  ActiveControl := BankjegyEdit;
end;


procedure TForm1.DatumComboTolto;

var _y: integer;
    _aktdatum :TDAtetime;
    _aktdums,_aktoras: string;
    _aktora: word;

begin
  _aktdatum := date;
  _aktdums := datetostr(_aktdatum);
  Datumcombo.Items.clear;

  _aktoras := leftstr(Form1.GetIdos,2);
  _aktora := strtoint(_aktoras);
  if _aktora>9 then
    begin
      Datumcombo.Items.add(_aktdums);
      Datumcombo.ItemIndex := 0;
      exit;
    end;

  _y := 2;
  while _y>=0 do
    begin
      _aktdatum := date-_y;
      _aktdums := datetostr(_aktdatum);
      DatumCombo.Items.add(_aktdums);
      dec(_y);
    end;
  DatumCombo.ItemIndex := 2;
end;



// =============================================================================
            procedure TForm1.BANKJEGYEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;

// =============================================================================
             procedure TForm1.BANKJEGYEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWindow;
  _text := trim(BankjegyEdit.Text);
  Val(_text,_qbankjegy,_code);
  if _code<>0 then
    begin
      _qbankjegy := 0;
      exit;
    end;
  Activecontrol := EngedelyEZOGomb;
end;



// =============================================================================
                 procedure TForm1.IrodakBetoltese;
// =============================================================================

var _ptarnum,_ss: integer;
    _aktpnev,_pcombonev,_closed: string;

begin
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (STATUS=' + chr(39)+ 'P' + CHR(39) + ')'+ _sorveg;
  _pcs := _pcs + 'ORDER BY UZLET';

  Recdbase.connected := true;
  with Recquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  PenztarCombo.Items.clear;
  Penztarcombo.Clear;
  _ss := 0;

  while not Recquery.eof do
    begin
      _closed  := trim(Recquery.FieldByName('CLOSED').asString);
      if _closed<>'X' then
        begin
          _ptarnum   := RecQuery.FieldByName('UZLET').asInteger;
          _aktpnev   := trim(Recquery.FieldByname('KESZLETNEV').asString);
          _ertektar  := recquery.FieldByName('ERTEKTAR').asInteger;
          _pcombonev := nul3(_ptarnum)+'. '+_aktpnev;
          _etar[_ss] := _ertektar;
          inc(_ss);

          PenztarCombo.Items.Add(_pcombonev);
        end;

      Recquery.next;
    end;
  Recquery.close;
  Recdbase.close;
  Penztarcombo.ItemIndex := 0;

end;

// =============================================================================
                function TForm1.Nul3(_b: byte):string;
// =============================================================================

begin
  result := inttostr(_b);
  while length(result)<3 do result := '0' + result;
end;


// =============================================================================
         procedure TForm1.PENZTARCOMBOChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := EngedelyezoGomb;
end;

// =============================================================================
           procedure TForm1.KILEPOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;



// =============================================================================
             procedure TForm1.DNEMCOMBOChange(Sender: TObject);
// =============================================================================

begin
  _dnemindex := DnemCombo.Itemindex;
  _qdnem := DnemCombo.items[_dnemindex];

  DnemPanel1.Caption := _qdnem;
  DnemPanel2.Caption := _qdnem;
  Dnempanel1.Repaint;
  DnemPanel2.Repaint;
  Activecontrol := engedelyezoGomb;
end;


// =============================================================================
    procedure TForm1.ARFOLYAMEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Activecontrol := EngedelyezoGomb;
end;


// =============================================================================
             procedure TForm1.CreatePerm(_ptn: string);
// =============================================================================

begin

  _pcs := 'CREATE TABLE ' + _ptN + ' ('+_sorveg;

  _pcs := _pcs + 'PERMITTYPE SMALLINT,' + _sorveg;
  _pcs := _pcs + 'ERTEKTAR SMALLINT,' + _sorveg;
  _pcs := _pcs + 'PENZTAR SMALLINT,' + _sorveg;

  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'TRANZAKCIO CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER,'+_sorveg;
  _pcs := _pcs + 'UJARFOLYAM INTEGER,'+_sorveg;
  _pcs := _pcs + 'ENGEDELYEZO CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'KONTROL CHAR (2) CHARACTER SET WIN1250 COLLATE WIN1250)';
  Permdbase.Connected := true;
  if PermTranz.InTransaction then Permtranz.Commit;
  Permtranz.StartTransaction;

  with Permquery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  Permtranz.Commit;
  Permdbase.close;
end;



procedure TFORM1.ARFOLYAMEDITEnter(Sender: TObject);
begin
   Arfolyamedit.Color := clYellow;
end;

procedure TFORM1.ARFOLYAMEDITExit(Sender: TObject);
begin
  Arfolyamedit.Color := clWindow;
  _text := trim(Arfolyamedit.Text);
  val(_text,_qarfolyam,_code);
  if _code<>0 then
    begin
      _qarfolyam := 0;
      exit;
    end;
  ActiveControl := EngedelyezoGomb;
end;



procedure TFORM1.FRADIOClick(Sender: TObject);
begin
  if (Fradio.Checked) or (URADIO.Checked) then
    begin
      if Fradio.Checked then _engBetu := 'F';
      if URadio.Checked then _engbetu := 'U';
      if _ezkezdij then ElengedesRadio.Enabled := true;
    end;
end;


procedure TFORM1.ARFOLYAMRADIOClick(Sender: TObject);
begin
  if (Arfolyamradio.Checked) then
    begin
      _ezArfolyam := True;
      _ezKezdij := False;
      Jradio.Enabled := True;
      FelezesRadio.Enabled := False;
      ElengedesRadio.Enabled := False;
      Csokkentesradio.Enabled := False;
      Arfolyamedit.Enabled := True;
      Arfolyamedit.Color := clWindow;
    end;
end;

procedure TFORM1.KEZDIJRADIOClick(Sender: TObject);
begin
  if (Kezdijradio.Checked) then
    begin
      _ezarfolyam := False;
      _ezkezdij := True;
      Jradio.Enabled := False;
      Arfolyamedit.Enabled := false;
      Arfolyamedit.Color := $888888;
      if (Fradio.Checked) or (Uradio.Checked) then Elengedesradio.Enabled := true;
      FelezesRadio.Enabled := True;
      CsokkentesRadio.Enabled := true;
    end;
end;



procedure TFORM1.MINDKETTORADIOClick(Sender: TObject);
begin
  if mindkettoRadio.Checked then
    begin
      _ezarfolyam := True;
      _ezkezdij := True;
      JRadio.Enabled := True;
      Arfolyamedit.Enabled := true;
      Arfolyamedit.Color := clWindow;
      if (Fradio.Checked) or (Uradio.Checked) then Elengedesradio.Enabled := true;
      FelezesRadio.Enabled := True;
      CsokkentesRadio.Enabled := true;
    end;
end;

// =============================================================================
             procedure TForm1.engedelygombClick(Sender: TObject);
// =============================================================================


var _dx: integer;

begin
  if ArfolyamRadio.Checked then _ezarfolyam := True;
  if KezdijRadio.Checked   then _ezkezdij   := True;

  if MindkettoRadio.Checked then
    begin
      _ezarfolyam := true;
      _ezkezdij   := true;
    end;

  _dx      := Datumcombo.Itemindex;
  _qdatums := leftstr(DatumCOmbo.items[_dx],10);

  _dnemindex := DnemCombo.Itemindex;
  _qdnem := DnemCombo.items[_dnemindex];

  // -------------------------------------

  _itemindex := PenztarCombo.itemindex;
  _ptarsor   := PenztarCombo.items[_itemindex];
  _qpenztar  := strtoint(leftstr(_ptarsor,3));
  _ertektar  := _etar[_itemindex];

  // ---------------------------------------

  _itemindex := Tranzcombo.itemindex;
  _qtranzjel := _trjel[1+_itemindex];

  // ----------------------------------------

  if _qBankjegy=0 then
    begin
      Showmessage('IRJA BE A VÁLTOTT VALUTA MENNYISÉGÉT !');
      Bankjegyedit.clear;
      Activecontrol := Bankjegyedit;
      exit;
    end;

  // -----------------------------------------------------

  if _ezArfolyam then
    begin
      if _qArfolyam=0 then
        begin
          ShowMessage('IRJA BE A KEDVEZMÉNYES ÁRFOLYAMOT !');
          Arfolyamedit.clear;
          Activecontrol := ArfolyamEdit;
          exit;
        end;
    end;

  // ---------------------------------------------------------

  if _ezKezdij then
    begin
      if (felezesRadio.Checked=False) and (Csokkentesradio.Checked=false) and (elengedesradio.Checked=False) then
         begin
           ShowMessage('JELÖLJE KI A KEZELÉSI DÍJ KEDVEZMÉNY MÉRTÉKÉT !');
           EXIT;
         end;
     end;

  _farok := midstr(_qdatums,3,2)+midstr(_qdatums,6,2);
  _permNev := 'ENG' + _farok;

  PermTabla.Close;
  Permtabla.tablename := _permNev;
  Permdbase.Connected := true;

  if not Permtabla.Exists then
    begin
      Permdbase.close;
      CreatePerm(_permNev);
    end else Permdbase.close;

   // -----------------------------------------------------------------

   _loByte := 0;
   _hibyte := 0;

   if _ezarfolyam then
     begin
       if FRadio.Checked then _loByte := 32;
       if Uradio.Checked then _lobyte := 64;
       if Jradio.Checked then _lobyte := 128;
     end;

   if _ezkezdij then
     begin
       if felezesRadio.Checked    then _hiByte := 256;
       if ElengedesRadio.Checked  then _hiByte := 1024;
       if CsokkentesRadio.Checked then _hiByte := 2048;
     end;

  _permitType := _loByte+_hiByte;

  _pcs := 'INSERT INTO ' + _permNev + ' (PERMITTYPE,ERTEKTAR,PENZTAR,DATUM,';
  _pcs := _pcs + 'VALUTANEM,TRANZAKCIO,BANKJEGY,UJARFOLYAM,';
  _pcs := _pcs + 'ENGEDELYEZO)'+_sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_permittype)+',';
  _pcs := _pcs + inttostr(_ertektar)+',';
  _pcs := _pcs + inttostr(_qpenztar) + ',';
  _pcs := _pcs + chr(39) + _qdatums +chr(39) + ',';
  _pcs := _pcs + chr(39) + _qdnem + chr(39) + ',';
  _pcs := _pcs + chr(39) + _qtranzjel + chr(39) + ',';
  _pcs := _pcs + inttostr(_qbankjegy) + ',';
  _pcs := _pcs + inttostr(_qarfolyam)+',';
  _pcs := _pcs + chr(39) + _engBetu + CHR(39) + ')';

  Permdbase.Connected := true;
  if PermTranz.InTransaction then Permtranz.Commit;
  Permtranz.StartTransaction;

  with Permquery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  Permtranz.Commit;
  Permdbase.close;

  with Menufuggony do
    begin
      top := 5;
      Left := 5;
      Visible := true;
    end;
end;

procedure TFORM1.BANKJEGYEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  ActiveControl := Arfolyamedit;
  Arfolyamedit.SetFocus;
end;

procedure TFORM1.JRADIOClick(Sender: TObject);
begin
  if JRadio.Checked then _engbetu := 'J';
end;

procedure TForm1.ESCAPEGOMBClick(Sender: TObject);
begin
  Application.Terminate;
end;

function TForm1.Getidos: string;

begin
  result := timetostr(Time);
  if midstr(result,2,1)=':' then result := '0' + result;
end;

procedure TForm1.CONTROLGOMBClick(Sender: TObject);
begin
  KontrolForm.showmodal;
end;

end.
