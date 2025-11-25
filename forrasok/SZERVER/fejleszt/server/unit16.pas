unit Unit16;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, DB, IBDatabase, IBCustomDataSet,
  IBTable, Grids, DBGrids, unit1, IBQuery, StrUtils, DateUtils;

type
  TIRODATMK = class(TForm)
    VISSZAGOMB: TBitBtn;
    IRODARACS: TDBGrid;
    IRODATABLA: TIBTable;
    IRODADBASE: TIBDatabase;
    IRODATRANZ: TIBTransaction;
    IRODASOURCE: TDataSource;
    Label1: TLabel;
    IRODAKARTON: TPanel;
    IRODASZAMEDIT: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    VAROSEDIT: TEdit;
    Label4: TLabel;
    BOLTNEVEDIT: TEdit;
    GroupBox1: TGroupBox;
    RADIOPTAR: TRadioButton;
    RADIETAR: TRadioButton;
    Label6: TLabel;
    BANKKODEDIT: TEdit;
    Label7: TLabel;
    ERTEKTAREDIT: TEdit;
    SUNDAYBOX: TCheckBox;
    Bevel1: TBevel;
    Bevel2: TBevel;
    UJIRODAGOMB: TBitBtn;
    TORLOGOMB: TBitBtn;
    MODOSITOGOMB: TBitBtn;
    MENTESGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    TOROLPANEL: TPanel;
    Label8: TLabel;
    IRNEVPANEL: TPanel;
    IGENGOMB: TBitBtn;
    NEMGOMB: TBitBtn;
    IRODAQUERY: TIBQuery;
    DAYBOOKTABLA: TIBTable;
    DAYBOOKDBASE: TIBDatabase;
    DAYBOOKTRANZ: TIBTransaction;
    Shape1: TShape;
    CEGPANEL: TPanel;
    Shape2: TShape;
    CEGVALTOGOMB: TBitBtn;
    Shape3: TShape;
    GroupBox2: TGroupBox;
    RBEST: TRadioButton;
    RPANNON: TRadioButton;
    REAST: TRadioButton;
    TELEFONEDIT: TEdit;
    Label5: TLabel;
    Shape4: TShape;
    CLOSEDBOX: TCheckBox;
    Shape5: TShape;
    RZALOG: TRadioButton;

    procedure VISSZAGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure IRODARACSKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure IRODASZAMEDITEnter(Sender: TObject);
    procedure IRODASZAMEDITExit(Sender: TObject);
    procedure MENTESGOMBClick(Sender: TObject);
    procedure IRODASZAMEDITChange(Sender: TObject);
    procedure RADIOPTARClick(Sender: TObject);
    procedure EgyIrodaRead;
    procedure EgyirodaGet;
    procedure IrodaModify;
    procedure VAROSEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BOLTNEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure BANKKODEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ERTEKTAREDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MODOSITOGOMBClick(Sender: TObject);
    procedure IRODARACSDblClick(Sender: TObject);
    procedure TORLOGOMBClick(Sender: TObject);
    procedure IGENGOMBClick(Sender: TObject);
    procedure NEMGOMBClick(Sender: TObject);
    procedure UJIRODAGOMBClick(Sender: TObject);

    function IrodaVanIlyen(_isz: integer): boolean;
    function BKodVanilyen(_bk: string): boolean;
    procedure IRODASZAMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MakeIrodaFdb;
    procedure Vparancs(_ukaz: string);

    procedure MakeArfe(_fdbNev: string; _dnev: string);
    procedure MakeTesc(_fdbNev: string; _dnev: string);

    procedure MakeBF(_fdbNev: string; _dnev: string);
    procedure MakeBT(_fdbNev: string; _dnev: string);
    procedure MakeCimt(_fdbNev: string; _dnev: string);
    procedure MakeNarf(_fdbNev: string; _dNev: string);
    procedure MakeWafa(_fdbNev: string; _dNev: string);
    procedure MakeWuni(_fdbNev: string; _dNev: string);
    procedure MakeWzar(_fdbNev: string; _dNev: string);
    procedure MakeElohavi(_fdbNev: string; _DNEV:string);
    procedure MakeEloNapi(_fdbNev: string; _dnev:string);
    procedure DayBookWrite;
    procedure OneWordWrite(_szo: string);
    procedure MakeIrodaDat;
    procedure IrodaNyitas;
    procedure CEGVALTOGOMBClick(Sender: TObject);
    procedure TELEFONEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure UJIRODAGOMBEnter(Sender: TObject);
    procedure UJIRODAGOMBExt(Sender: TObject);
    procedure UJIRODAGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);

    procedure MakeJogi;
    procedure MakeUgyfel;
    procedure MakeMainCurr;  
    

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  IRODATMK: TIRODATMK;
  _uzlet: integer;
  _aktfdbPath: string;
  _town,_shop,_status,_sunday,_bkod,_aktdbfNev,_adatpath: string;
  _voltValtozas,_kellbeolvasni,_ujiroda: boolean;
  _iras: File of Byte;
  _byteTomb: array[1..63] of Byte;
  _RADIO: array[0..2] of TRadioButton;
  _aktRadio: TRadioButton;

implementation

{$R *.dfm}


procedure TIRODATMK.VISSZAGOMBClick(Sender: TObject);
begin
  if irodaTranz.InTransaction then IrodaTranz.commit;
  IrodaTabla.Close;
  if _kellbeolvasni then
    begin
      MakeIrodaDat;
      Form1.IrodaBetolto;
    end;
  ModalResult := 1;
end;

procedure TIRODATMK.FormActivate(Sender: TObject);
begin
  Top  := _top + 120;
  Left := _left + 140;
  hEIGHT := 530;
  Width := 750;

  IrodaKarton.Visible := False;
  TorolPanel.Visible  := False;

  _radio[0] := rbest;
  _radio[1] := rpannon;
  _radio[2] := reast;

  _aktdatums := leftstr(Form1.hdatetostr(date),10);
  _farok     := midstr(_aktdatums,3,2)+midstr(_aktdatums,6,2);

  _voltValtozas  := False;
  _kellbeolvasni := false;
  _ujiroda       := False;
  _Cegss := 0;
  Irodanyitas;
end;

// =============================================================================
                        procedure TIrodaTmk.Irodanyitas;
// =============================================================================


begin

  if _cegss<3 then _aktcegnev := 'EXCLUSIVE ' + _subdir[_cegss] + ' CHANGE'
  else _aktcegnev := 'EXPRESSZ ÉKSZERHÁZ';
  _aktcegbetu := _cegbetuk[_cegss];

  Cegpanel.Caption := _aktcegnev;
  
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE CEGBETU='+chr(39)+ _aktcegbetu + chr(39) + _sorveg;
  _pcs := _pcs +'ORDER BY UZLET';

  with IrodaDbase do
    begin
      Close;
      DatabaseName := 'c:\receptor\database\receptor.fdb';
      Connected := true;
    end;

  if irodaTranz.InTransaction then irodaTranz.Commit;
  with Irodaquery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;
  ActiveControl := IrodaRacs;
end;


procedure TIRODATMK.IRODARACSKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var _bill: integer;

begin
  _bill := ord(key);
  IF _bill=13 then IrodaModify;

end;

procedure TIRODATMK.MEGSEMGOMBClick(Sender: TObject);
begin
  _ujIroda := false;
  Irodakarton.Visible := false;
  ActiveControl := IrodaRacs;
end;

procedure TIRODATMK.IRODASZAMEDITEnter(Sender: TObject);
begin
  TEdit(Sender).color := clYellow;
end;

procedure TIRODATMK.IRODASZAMEDITExit(Sender: TObject);
begin
  TEdit(sender).Color := clwindow;
end;

// =============================================================================
            procedure TIRODATMK.MENTESGOMBClick(Sender: TObject);
// =============================================================================


var _double: boolean;
    _kesznev: string;

begin
  if not _voltvaltozas then
    begin
      _ujIroda := false;
      Irodakarton.Visible := false;
      ActiveControl := IrodaRacs;
      exit;
    end;

  EgyirodaGet;

  if _ujIroda then
    begin
      _double := IrodaVanilyen(_irszam);
      if _double=True then
        begin
          Showmessage('ILYEN SZÁMU IRODA MÁR VAN !');
          ActiveControl := Irodaszamedit;
          exit;
        end;
    end;

  if _irszam=0 then
    begin
      Irodaszamedit.Enabled := true;
      ActiveControl := IrodaszamEdit;
      Exit;
    end;

  // ---------------------------------------------------------------------------

  if _ujiroda then
    begin
      _double := BkodVanilyen(_bKod);
      if _double=True then
        begin
          ShowMessage('ILYEN SZÁMÚ BANKKÓD MÁR VAN !');
          ActiveControl := BankKodedit;
          exit;
        end;
    end;

  if _bkod='' then
    begin
      ActiveControl := Bankkodedit;
      Exit;
    end;

  // ---------------------------------------------------------------------------

  if _ertekTar=0 then
    begin
      ActiveControl := ErtekTarEdit;
      Exit;
    end;

  if _ujIroda then
    begin
      _uzlet := _irszam;
      IrodaDbase.Connected := true;
      if irodaTranz.InTransaction then IrodaTranz.Commit;
      irodatranz.StartTransaction;
      _pcs := 'INSERT INTO IRODAK (UZLET)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_uzlet)+')';
      with IrodaQuery do
        begin
          Close;
          Sql.Clear;
          sql.Add(_pcs);
          ExecSql;
        end;
      IrodaTranz.Commit;
      IrodaDbase.Close;
    end;

  _kesznev := leftstr(_town+' '+_shop,24);
  irodaDbase.Connected := true;
  if IrodaTranz.InTransaction then Irodatranz.Commit;
  IrodaTranz.StartTransaction;

  _pcs := 'UPDATE IRODAK SET VAROS='+chr(39)+_town+chr(39)+',';
  _pcs := _pcs + 'BOLTNEV='+chr(39)+_shop+chr(39)+',';
  _pcs := _pcs + 'STATUS='+CHR(39)+_status+chr(39)+',';
  _pcs := _pcs + 'ERTEKTAR='+inttostr(_ertektar)+',';
  _pcs := _pcs + 'BANKKOD='+chr(39)+_bkod+chr(39)+',';
  _pcs := _pcs + 'CEGBETU='+chr(39)+_aktcegbetu+chr(39)+',';
  _pcs := _pcs + 'KESZLETNEV='+chr(39)+_kesznev+chr(39)+',';
  _pcs := _pcs + 'SUNDAYCLOSE='+chr(39)+_sunday+chr(39) +  ',';
  _pcs := _pcs + 'CLOSED='+chr(39)+_closed+chr(39)+_sorveg;
  _pcs := _pcs + 'WHERE UZLET='+inttostr(_irszam);
  with IrodaQuery do
    begin
      CLose;
      Sql.Clear;
      Sql.Add(_pcs);
      Execsql;
    end;

  IrodaTranz.commit;
  irodaDbase.Close;

  Form1.IrodaBetolto;

  IF _UJIRODA THEN MakeIrodaFdb;

  _kellBeolvasni := true;
  _voltValtozas := false;
  _ujiroda := false;

  Irodakarton.Visible := False;
  IrodaNyitas;
end;



// =============================================================================
            procedure TIRODATMK.IRODASZAMEDITChange(Sender: TObject);
// =============================================================================

begin
  _voltvaltozas := True;
end;

// =============================================================================
            procedure TIRODATMK.RADIOPTARClick(Sender: TObject);
// =============================================================================

begin
  _voltValtozas := true;
  if IrodaKarton.Visible= False then exit;
  Mentesgomb.enabled := True;
  Activecontrol := MentesGomb;
end;

// =============================================================================
                     procedure TIrodatmk.EgyirodaRead;
// =============================================================================


begin
  with IrodaQuery do
    begin
      _irszam   := FieldByName('UZLET').asInteger;
      _town     := trim(FieldByName('VAROS').asstring);
      _shop     := trim(FieldByName('BOLTNEV').asString);
      _status   := FieldByNAme('STATUS').asstring;
      _ertektar := FieldByName('ERTEKTAR').asInteger;
      _bkod     := trim(FieldByName('BANKKOD').asString);
      _sunday   := FieldByName('SUNDAYCLOSE').asstring;
      _closed   := FieldByName('CLOSED').asString;
      _aktcegbetu := FieldByName('CEGBETU').AsString;
    end;
end;

// =============================================================================
                         procedure TIrodaTmk.EgyirodaGet;
// =============================================================================

begin
  val(IrodaszamEdit.Text,_irszam,_code);
  if _code<>0 then _irszam := 0;

  _town   := trim(VarosEdit.Text);
  _shop   := trim(BoltnevEdit.Text);
  _telefon:= trim(Telefonedit.text);

  _status := 'E';
  if radioptar.Checked then _status := 'P';
  if Rbest.Checked then _aktcegbetu := 'B';
  if RPannon.Checked then _aktcegbetu := 'P';
  if Reast.Checked then _aktcegbetu := 'E';
  if RZalog.Checked then _aktcegbetu := 'Z';

  _bkod := trim(Bankkodedit.Text);
  _sunday := '';
  _closed := '';
  if sundayBox.Checked then _sunday := 'X';
  if Closedbox.Checked then _closed := 'X';

  val(Ertektaredit.Text,_ertektar,_Code);
  if _code<>0 then _ertektar := 0;
end;

// =============================================================================
      procedure TIRODATMK.VAROSEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if (ord(key)= 13) OR (ord(key)=40) then
    begin
      ActiveControl := BoltNevEdit;
      Exit;
    end;
  if (ord(key)=38) then
    begin
      ActiveControl := Bankkodedit;
      exit;
    end;
end;

// =============================================================================
     procedure TIRODATMK.BOLTNEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if (ord(key)=13) or (ord(key)=40) then
    begin
      ActiveControl := Telefonedit;
      exit;
    end;

  if (ord(key)=38) then
    begin
      ActiveControl := Varosedit;
      Exit;
    end;
end;

// =============================================================================
    procedure TIRODATMK.BANKKODEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================
begin
  if (ord(key)=13) or (ord(key)=40) then ActiveControl := Varosedit;
end;


// =============================================================================
     procedure TIRODATMK.ERTEKTAREDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if (ord(key)=13) or (ord(key)=40) then
    begin
      ActiveControl := MentesGomb;
      exit;
    end;
  if (ord(key)=38) then ActiveControl := Boltnevedit;
end;

// =============================================================================
                   procedure TIrodaTmk.IrodaModify;
// =============================================================================

// eGY IRODÁBAN AZ EGYIK ADATOT MODOSITANI AKARJUK

begin
  EgyIrodaRead; // az aktuális rekord mezõi változókba kerülnek

  IrodaszamEdit.Text    := inttostr(_irszam);
  Irodaszamedit.Enabled := False;  // az irodaszám nem módositható

  BankkodEdit.Text   := _bkod;
  VarosEdit.Text     := _town;
  Boltnevedit.Text   := _shop;
  Telefonedit.Text   := _telefon;

  if _status='P' then Radioptar.Checked := True else Radietar.Checked := True;
  if _aktCegBetu='B' then RBest.Checked := true;
  if _aktCegBetu='P' then RPannon.Checked := true;
  if _aktCegBetu='E' then REast.Checked := true;
  
  Ertektaredit.Text := inttostr(_ertektar);
  SundayBox.Checked := False;
  ClosedBox.Checked := False;


  if uppercase(_sunday)='X' then SundayBox.Checked := true;
  if uppercase(_closed)='X' then Closedbox.Checked := True;
  ClosedBox.Repaint;

  _voltValtozas := False;

  with Irodakarton do
    begin
      Top     := 8;
      Left    := 8;
      Visible := True;
    end;
  ActiveControl := VarosEdit;
end;

// =============================================================================
            procedure TIRODATMK.MODOSITOGOMBClick(Sender: TObject);
// =============================================================================

begin
  IrodaModify;
end;

procedure TIRODATMK.IRODARACSDblClick(Sender: TObject);
begin
  irodaModify;
end;

// =============================================================================
           procedure TIRODATMK.TORLOGOMBClick(Sender: TObject);
// =============================================================================

begin
   eGYIRODAREAD;
  IrnevPanel.Caption := _irodanev[_irszam];
  with Torolpanel do
    begin
      Top := 170;
      Left := 130;
      Visible := True;
    end;
  ActiveControl := NemGomb;
end;

// =============================================================================
             procedure TIRODATMK.IGENGOMBClick(Sender: TObject);
// =============================================================================

begin

  Irodadbase.Connected := True;
  if irodaTranz.InTransaction then irodatranz.Commit;
  IrodaTranz.StartTransaction;
  _pcs := 'DELETE FROM IRODAK WHERE UZLET='+CHR(39)+INTTOSTR(_irszam)+chr(39);

  with Irodaquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      ExecSql;
    end;

  IrodaTranz.Commit;
  IrodaQuery.close;

  _KellBeolvasni := True;
  TorolPanel.Visible := false;
  Irodanyitas;
end;

procedure TIRODATMK.NEMGOMBClick(Sender: TObject);
begin
  TorolPanel.Visible := False;
  ActiveControl := IrodaRacs;
end;

// =============================================================================
            procedure TIRODATMK.UJIRODAGOMBClick(Sender: TObject);
// =============================================================================

begin
  _ujiroda := true;

  IrodaSzamEdit.clear;
  BankKodedit.Clear;
  Varosedit.Clear;
  Boltnevedit.Clear;
  Telefonedit.Clear;
  RadioPtar.Checked := true;
  ErtekTarEdit.Clear;
  SundayBox.Checked := False;
  _aktradio := _radio[_cegss];
  _aktradio.Checked := True;

  with Irodakarton do
    begin
      Top := 8;
      Left := 8;
      Visible := True;
    end;

  Irodaszamedit.Enabled := True;
  ActiveControl := IrodaszamEdit;
end;


// =============================================================================
       function TIrodaTmk.IrodaVanIlyen(_isz: integer): boolean;
// =============================================================================

var z: integer;

begin
  Result := false;
  for z := 0 to _irodaDarab-1 do
    begin
      if _irodaszam[z]=_isz then
        begin
          result := True;
          Break;
        end;
    end;
end;

// ========================================================================
        function TIrodaTMK.BKodVanilyen(_bk: string): boolean;
// ========================================================================

var z,_ii: integer;

begin
  Result := False;
  for z := 0 to _irodaDarab-1 do
    begin
      _ii := _irodaszam[z];
      if _bankkod[_ii]=_bk then
        begin
          Result := true;
          Break;
        end;
    end;
end;


procedure TIRODATMK.IRODASZAMEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);

begin
  IF (ORD(key)=13) or (ord(key)=40) then ActiveControl := BankKodedit;
end;

// ==================================================
           procedure TirodaTmk.MakeIrodaFdb;
// ==================================================


var ValutaFdb: TibDatabase;

begin
  _aktFdbpath := 'C:\RECEPTOR\DATABASE\V' + inttostr(_irszam)+'.FDB';

  if Fileexists(_aktfdbPath) then exit;

  ValutaFdb := TIbDatabase.Create(nil);
  with ValutaFdb do
    begin
      Connected := False;
      DatabaseName := _aktfdbPath;

      Params.Add('USER ''SYSDBA''PASSWORD ''dek@nySo''');
      Params.Add('DEFAULT CHARACTER SET WIN1250');

      SqlDialect := 3;
      LoginPrompt := False;
      CreateDatabase;
    end;

  ValutaFdb.Free;

  _aktdbfnev := 'arfe'+_farok;
  MakeArfe(_aktfdbpath,_aktdbfNev);

  // ----------------------------------------------

  _aktdbfnev := 'BF'+_farok;
  MakeBF(_aktfdbpath,_aktdbfNev);

   // ----------------------------------------------

  _aktdbfnev := 'BT'+_farok;
  MakeBT(_aktfdbpath,_aktdbfNev);

  // ----------------------------------------------

  _aktdbfnev := 'CIMT'+_farok;
  MakeCimt(_aktfdbpath,_aktdbfNev);

  // ----------------------------------------------

  _aktdbfnev := 'NARF'+_farok;
  MakeNarf(_aktfdbpath,_aktdbfNev);

  // ----------------------------------------------

  _aktdbfnev := 'TESC'+_farok;
  MakeTesc(_aktfdbpath,_aktdbfNev);

   // ----------------------------------------------

  _aktdbfnev := 'WAFA'+_farok;
  MakeWafa(_aktfdbpath,_aktdbfNev);

  // ----------------------------------------------

  _aktdbfnev := 'WUNI'+_farok;
  MakeWuni(_aktfdbpath,_aktdbfNev);

  // ----------------------------------------------

  _aktdbfnev := 'WZAR'+_farok;
  MakeWzar(_aktfdbpath,_aktdbfNev);

  // ----------------------------------------------

  _aktdbfnev := 'ELOHAVI';
  MakeElohavi(_aktfdbPath,_aktdbfNev);

  // ---------------------------------------------

  _aktdbfnev := 'ELONAPI';
  MakeEloNAPI(_aktfdbPath,_aktdbfNev);

  Makejogi;
  MakeUgyfel;
  MakemainCurr;


  DayBookwrite;
end;

// ==================================================================
     procedure TIrodaTmk.MakeArfe(_fdbNev: string; _dnev: string);
// ==================================================================

begin
    ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE '+ _dNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'ARFOLYAM DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'UJARFOLYAM DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'PENZTAROSNEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUNDC,'+_sorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER,'+_sorveg;
  _pcs := _pcs + 'ELSZAMARFOLYAM DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'PENZTAROSIMAX DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'ENGEDMENYTIPUS SMALLINT)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX IDX_'+_dnev+' ON  '+_dnev + ' (VALUTANEM)';
  VParancs(_pcs);
end;

// ==========================================================
    procedure TIrodaTmk.MakeBf(_fdbNev: string; _dNev: string);
// ==========================================================

begin
  ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE '+_dnev+' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'IDO CHAR (8) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'TIPUS CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'OSSZESEN INTEGER,'+_sorveg;
  _pcs := _pcs + 'IDKOD CHAR (5) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'UGYFELTIPUS CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'UGYFELSZAM INTEGER,'+_sorveg;
  _pcs := _pcs + 'UGYFELNEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'TETEL INTEGER,'+_sorveg;
  _pcs := _pcs + 'PENZTAROSNEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'PENZTAR CHAR (4) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'TRBPENZTAR CHAR (4) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'PLOMBASZAM CHAR (30) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'SZALLITONEV CHAR (30) CHARACTER SET WIN1250 COLLATE PXW_HUNDC,'+_sorveg;
  _pcs := _pcs + 'STORNO SMALLINT,'+_sorveg;
  _pcs := _pcs + 'STORNOBIZONYLAT CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX  IDX_'+_dnev+' ON '+_dnev+' (DATUM)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX  IDX_A'+_dnev+' ON '+_dnev+' (BIZONYLATSZAM)';
  VParancs(_pcs);
end;

// =============================================================
       procedure TIrodaTmk.MakeBt(_fdbNev: string; _dnev: string);
// =============================================================


begin
    ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE ' + _dNev + ' ('+_sorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER,'+_sorveg;
  _pcs := _pcs + 'ARFOLYAM DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'ELSZAMOLASIARFOLYAM DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'FORINTERTEK INTEGER,'+_sorveg;
  _pcs := _pcs + 'ELOJEL CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'COIN  CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'STORNO SMALLINT)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX  IDX_'+_dnev+' ON '+_dnev+' (BIZONYLATSZAM)';
  VParancs(_pcs);
end;

// ==========================================================
    procedure TIrodaTmk.MakeCimt(_fdbNev: string; _dNev: string);
// ==========================================================


begin
    ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE ' + _dNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'OSSZESEN INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET1 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET2 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET3 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET4 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET5 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET6 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET7 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET8 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET9 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET10 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET11 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET12 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET13 INTEGER,'+_sorveg;
  _pcs := _pcs + 'CIMLET14 INTEGER)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX IDX_'+_dnev+' ON '+_dnev+' (VALUTANEM)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX  IDX_1'+_dnev+' ON '+_dnev+' (DATUM)';
  VParancs(_pcs);
end;

// ==================================================================
       procedure TIrodaTmk.MakeElohavi(_fdbNev: string; _DNEV:string);
// ==================================================================


begin
    ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE ELOHAVI ('+_sorveg;
  _pcs := _pcs + 'EVHOSTRING CHAR (6) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'NAPOK INTEGER,'+_sorveg;
  _pcs := _pcs + 'VETEL DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'ELADAS DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'VETELUGYFELDARAB INTEGER,'+_sorveg;
  _pcs := _pcs + 'ELADASUGYFELDARAB INTEGER)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX IDX_ELOHAVI ON ELOHAVI (EVHOSTRING)';
  VParancs(_pcs);

end;

// ===================================================================
       procedure TIrodaTmk.MakeEloNapi(_fdbNev: string; _dnev:string);
// ===================================================================


begin
    ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE ELONAPI ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'OSSZESEN DOUBLE PRECISION)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX IDX_ELONAPI ON ELONAPI (DATUM)';
  VParancs(_pcs);
end;

// ==========================================================
    procedure TIrodaTMK.MakeNarf(_fdbNev: string; _dNev: string);
// ==========================================================


begin
  ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE ' + _dNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'VETELIARFOLYAM DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'ELADASIARFOLYAM DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'ELSZAMOLASIARFOLYAM DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'NYITO DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'ZARO DOUBLE PRECISION)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX IDX_'+_dnev+' ON '+_dnev+' (VALUTANEM)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX IDX1_'+_dnev+' ON '+_dnev+' (DATUM)';
  VParancs(_pcs);
end;

// ==========================================================
    procedure TIrodaTMK.MakeTesc(_fdbNev: string; _dnev: string);
// ==========================================================


begin
  ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE ' + _dNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'TIPUS CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'UGYFELSZAM INTEGER,'+_sorveg;
  _pcs := _pcs + 'UGYFELNEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'SZAMLASZAM CHAR (25) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'BRUTTO INTEGER,'+_sorveg;
  _pcs := _pcs + 'AFA5 INTEGER,'+_sorveg;
  _pcs := _pcs + 'AFA INTEGER,'+_sorveg;
  _pcs := _pcs + 'OSSZESEN INTEGER)';
  VParancs(_pcs);
end;


// ==========================================================
    procedure TIrodaTMK.MakeWafa(_fdbNev: string; _dNev: string);
// ==========================================================


begin
    ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE ' + _dNev + ' ('+_sorveg;
  _pcs := _pcs + 'FOEGYSEG SMALLINT,'+_sorveg;
  _pcs := _pcs + 'PENZTARSZAM INTEGER,'+_sorveg;
  _pcs := _pcs + 'UGYFELSZAM INTEGER,'+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'SORSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'SZAMLASZAM CHAR (25) CHARACTER SET WIN1250 COLLATE PXW_HUN,'+_sorveg;
  _pcs := _pcs + 'BRUTTO INTEGER,'+_sorveg;
  _pcs := _pcs + 'AFA INTEGER,'+_sorveg;
  _pcs := _pcs + 'KEZELESISZAZALEK DOUBLE PRECISION,'+_sorveg;
  _pcs := _pcs + 'UGYKEZELESIDIJ INTEGER,'+_sorveg;
  _pcs := _pcs + 'KIFIZETVE INTEGER,'+_sorveg;
  _pcs := _pcs + 'ELLATMANY INTEGER,'+_sorveg;
  _pcs := _pcs + 'TRANZAKCIOTIPUS CHAR (2) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'STORNO SMALLINT,'+_sorveg;
  _pcs := _pcs + 'STORNOBIZONYLAT CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250)';
  VParancs(_pcs);
end;

// ==========================================================
   procedure TIrodaTMK.MakeWuni(_fdbNev: string; _dnev: string);
// ==========================================================


begin
    ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE ' + _dNev + ' (' + _sorveg;
  _pcs := _pcs + 'FOEGYSEG SMALLINT,' + _sorveg;
  _pcs := _pcs + 'PENZTARSZAM INTEGER,' + _sorveg;
  _pcs := _pcs + 'UGYFELSZAM INTEGER,' + _sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'SORSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER,' + _sorveg;
  _pcs := _pcs + 'TRANZAKCIOTIPUS CHAR (2) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'UGYFELTIPUS CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'MTCNSZAM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'PENZTAROSNEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _sorveg;
  _pcs := _pcs + 'IDKOD CHAR (5) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'STORNO SMALLINT,' + _sorveg;
  _pcs := _pcs + 'STORNOBIZONYLAT CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250)';
  VParancs(_pcs);
end;

// ==========================================================
    procedure TIrodaTMK.MakeWZar(_fdbNev: string; _dnev: string);
// ==========================================================


begin
    ibdbase.close;
  ibdbase.DatabaseName := _fdbnev;

  _pcs := 'CREATE TABLE ' + _dNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,'+_sorveg;
  _pcs := _pcs + 'USDNYITO INTEGER,'+_sorveg;
  _pcs := _pcs + 'HUFNYITO INTEGER,'+_sorveg;
  _pcs := _pcs + 'METRONYITO INTEGER,'+_sorveg;
  _pcs := _pcs + 'TESCONYITO INTEGER,'+_sorveg;
  _pcs := _pcs + 'USDBE INTEGER,'+_sorveg;
  _pcs := _pcs + 'HUFBE INTEGER,'+_sorveg;
  _pcs := _pcs + 'METROBE INTEGER,'+_sorveg;
  _pcs := _pcs + 'TESCOBE INTEGER,'+_sorveg;
  _pcs := _pcs + 'USDKI INTEGER,'+_sorveg;
  _pcs := _pcs + 'HUFKI INTEGER,'+_sorveg;
  _pcs := _pcs + 'METROKI INTEGER,'+_sorveg;
  _pcs := _pcs + 'TESCOKI INTEGER,'+_sorveg;
  _pcs := _pcs + 'USDZARO INTEGER,'+_sorveg;
  _pcs := _pcs + 'HUFZARO INTEGER,'+_sorveg;
  _pcs := _pcs + 'METROZARO INTEGER,'+_sorveg;
  _pcs := _pcs + 'TESCOZARO INTEGER,'+_sorveg;
  _pcs := _pcs + 'METROVISSZA INTEGER,'+_sorveg;
  _pcs := _pcs + 'TESCOVISSZA INTEGER,'+_sorveg;
  _pcs := _pcs + 'UGYKEZELESIDIJ INTEGER)';
  VParancs(_pcs);

  _pcs := 'CREATE INDEX IDX_'+_dnev+' ON '+_dnev+' (DATUM)';
  VParancs(_pcs);
end;

procedure TIrodatmk.Makejogi;
begin

  _pcs := 'CREATE TABLE JOGISZEMELY (' + _SORVEG;
  _pcs := _Pcs + 'UGYFELSZAM INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'JOGISZEMELYNEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'TELEPHELYCIM CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'OKIRATSZAM CHAR (30) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'FOTEVEKENYSEG CHAR (35) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'KEPVISELONEV CHAR (45) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'MEGBIZOTTBEOSZTASA CHAR (30) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'KEPVISBEO CHAR (30) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'FELADVA SMALLINT)';
  VParancs(_pcs);
end;

procedure TIrodaTmk.Makeugyfel;

begin

  _pcs := 'CREATE TABLE UGYFELEK (' + _SORVEG;
  _pcs := _Pcs + 'UGYFELTIPUS CHAR (1) CHARACTER SET WIN1250 COLLATE WIN1250,' + _SORVEG;
  _pcs := _Pcs + 'UGYFELSZAM INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'NEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'ELOZONEV CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'ANYJANEVE CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'LEANYKORI CHAR (40) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'SZULETESIHELY CHAR (41) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'SZULETESIIDO CHAR (11) CHARACTER SET WIN1250 COLLATE WIN1250,' + _SORVEG;
  _pcs := _Pcs + 'ALLAMPOLGAR CHAR (35) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'LAKCIM CHAR (51) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'OKMANYTIPUS CHAR (20) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'AZONOSITO CHAR (20) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'TARTOZKODASIHELY CHAR (53) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'LAKCIMKARTYA CHAR (25) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'TELEFONSZAM CHAR (25) CHARACTER SET WIN1250 COLLATE PXW_HUN,' + _SORVEG;
  _pcs := _Pcs + 'FELADVA SMALLINT)';
  Vparancs(_pcs);
end;


procedure TIrodatmk.MakemainCurr;

begin


  _pcs := 'CREATE TABLE MAINCURR (' + _SORVEG;
  _pcs := _Pcs + 'EV SMALLINT,' + _SORVEG;
  _pcs := _Pcs + 'HONAP SMALLINT,' + _SORVEG;
  _pcs := _Pcs + 'VCHF INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'ECHF INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'VEUR INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'EEUR INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'VHRK INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'EHRK INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'VGBP INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'EGBP INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'VUSD INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'EUSD INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'VRON INTEGER,' + _SORVEG;
  _pcs := _Pcs + 'ERON INTEGER)';
  Vparancs(_pcs);
end;

procedure TIrodaTMK.Vparancs(_ukaz: string);

begin
  ibDbase.connected := true;
  if ibTranz.InTransaction then ibtranz.commit;
  ibtranz.StartTransaction;
  with ibquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ibtranz.commit;
  ibdbase.close;
end;























procedure TIrodaTmk.DaybookWrite;

var _mainap,j: integer;

begin
  _mainap := dayof(Date);
  DayBookDbase.close;
  DayBookDbase.connected := True;

  if DayBookTranz.InTransaction then DayBookTranz.Commit;
  DayBookTranz.StartTransaction;

  with dayBookTabla do
    begin
      IndexFieldNames := 'PENZTAR';
      TableName := 'DAYB'+_farok;
      Open;
      Refresh;
    end;

  _megvan := DayBookTabla.Locate('PENZTAR',_IRSZAM,[]);
  if _megvan then
    begin
      DayBookTranz.Commit;
      Daybooktabla.Close;
      Exit;
    end;
  with DayBookTabla do
    begin
      Append;
      edit;
      FieldByName('PENZTAR').AsInteger := _irszam;
    end;
  for j := 1 to _maiNap do
    begin
      _tema := 'N' + inttostr(j);
      DayBookTabla.FieldByName(_tema).asstring := 'X';
    end;

  DayBookTabla.Post;
  DayBookTranz.Commit;
  DayBookTabla.Close;
end;

// =============================================================================
                          procedure TIrodaTmk.MakeirodaDat;
// =============================================================================


var _dvaros,_dboltnev: string;

begin

  _irodaDarab := 0;
  IrodaDbase.Connected := true;
  if irodaTranz.InTransaction then irodaTranz.Commit;

  with Irodaquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM IRODAK ORDER BY UZLET');
      Open;
      Last;
    end;
  _irodaDarab := IrodaQuery.Recno;
  _adatPath := 'c:\receptor\mail\IRODAK\irodak.dat';

  AssignFile(_iras,_adatpath);
  Rewrite(_iras);

  _byteTomb[1] := _IrodaDarab;
  BlockWrite(_iras,_byteTomb,1);

  IrodaQuery.First;

  while not irodaQuery.Eof do
    begin
      
       with irodaQuery do
         begin
           _uzlet := FieldByName('UZLET').asInteger;
           _ertekTar := FieldByName('ERTEKTAR').asInteger;
           _dvaros := FieldByName('VAROS').asString;
           _dboltNev := FieldByName('BOLTNEV').asString;
         end;

       _byteTomb[1] := _uzlet;
       _byteTomb[2] := _ertektar;
       BlockWrite(_iras,_byteTomb,2);
       OneWordWrite(_dvaros);
       OnewordWrite(_dboltnev);

      IrodaQuery.Next;
    end;
  CloseFile(_iras);
  IrodaQuery.Close;
  irodaDbase.Close;
end;

// =============================================================================
                procedure TIrodaTmk.OneWordWrite(_szo: string);
// =============================================================================

var _hszo,i,_kod: integer;

begin
  _szo := trim(_szo);
  _hszo := length(_szo);
  _bytetomb[1] := _hszo;
  BlockWrite(_iras,_bytetomb,1);
  if _hszo=0 then exit;
  for i := 1 to _hszo do
    begin
      _kod := 255-ord(_szo[i]);
      _bytetomb[i] := _kod;
    end;
  BlockWrite(_iras,_bytetomb,_hszo);
end;

// =============================================================================
            procedure TIRODATMK.CEGVALTOGOMBClick(Sender: TObject);
// =============================================================================

begin
  inc(_cegss);
  if _cegss>3 then _cegss := 0;
  IrodaNyitas;
end;

// =============================================================================
    procedure TIRODATMK.TELEFONEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
   if (ord(key)=13) or (ord(key)=40) then
    begin
      ActiveControl := MentesGomb;
      exit;
    end;

  if (ord(key)=38) then
    begin
      ActiveControl := Telefonedit;
      Exit;
    end;
end;

procedure TIRODATMK.UJIRODAGOMBEnter(Sender: TObject);
begin
  TBitbtn(sender).Font.Color := clBlack;
end;

procedure TIRODATMK.UJIRODAGOMBExt(Sender: TObject);
begin
  TBitbtn(sender).font.Color := clGray;
end;

procedure TIRODATMK.UJIRODAGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  ActiveControl := TBitbtn(sender);
end;




end.
