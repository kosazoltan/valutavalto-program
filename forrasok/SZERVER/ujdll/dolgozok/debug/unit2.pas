unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGrids, ExtCtrls, StdCtrls, DB, IBCustomDataSet,
  IBTable, IBDatabase, Buttons, IBQuery, strutils, jpeg;

type
  TPROSTMK = class(TForm)

    ProsTranz        : TIBTransaction;
    ProsQuery        : TIBQuery;
    ProsDbase        : TIBDatabase;
    ProsTabla        : TIBTable;
    ProsSource       : TDataSource;
    ProsRacs         : TDBGrid;

    AlapPanel        : TPanel;
    Adatlap          : TPanel;
    BiztosKilepPanel : TPanel;
    Id1              : TPanel;
    KilepoNevPanel   : TPanel;
    KorzetPanel      : TPanel;
    Mentespanel      : TPanel;
    ModifyPanel      : TPanel;
    PenztaroskodPanel: TPanel;
    PenztarosnevPanel: TPanel;
    SorszamPanel     : TPanel;
    Panel3           : TPanel;
    Id3              : TPanel;
    Id4              : TPanel;
    Id5              : TPanel;
    Id2              : TPanel;
    TorloPanel       : TPanel;
    NevCsik          : TPanel;
    KorlevelSorszam  : TPanel;
    UjpenztarosPanel : TPanel;

    UjPenztarosGomb  : TBitBtn;
    KilepoGomb       : TBitBtn;
    DelokeGomb       : TBitBtn;
    DelMegsemGomb    : TBitBtn;
    ModokeGomb       : TBitBtn;
    ModMegsemGomb    : TBitBtn;
    KileptetoGomb    : TBitBtn;
    UjOkeGomb        : TBitBtn;
    UjNemokeGomb     : TBitBtn;

    Label2           : TLabel;
    Label3           : TLabel;
    Label4           : TLabel;
    Label5           : TLabel;
    Label7           : TLabel;

    Shape1           : TShape;
    Shape2           : TShape;
    Shape3           : TShape;
    Shape4           : TShape;
    Shape6           : TShape;
    Shape5           : TShape;
    Shape8           : TShape;
    Shape9           : TShape;
    Shape7           : TShape;
    Shape10          : TShape;

    ModositoGomb     : TBitBtn;
    SureKilepGomb    : TBitBtn;
    NoSureKilepGomb  : TBitBtn;

    NevEdit          : TEdit;
    RenameEdit       : TEdit;

    Label1           : TLabel;
    Label10          : TLabel;
    Label14          : TLabel;
    Label15          : TLabel;
    Label12          : TLabel;
    Label6           : TLabel;
    Label8           : TLabel;
    Label16          : TLabel;
    Label17          : TLabel;

    Image1           : TImage;
    KorzetCombo      : TComboBox;

    procedure AdatKimentes;
    procedure DelMegsemGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure ProsParancs(_ukaz: string);
    procedure ProsRacsCellClick(Column: TColumn);
    procedure ProsRacsKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure KilepoGombClick(Sender: TObject);
    procedure KorzetComboChange(Sender: TObject);
    procedure ModMegsemGombClick(Sender: TObject);
    procedure ModOkeGombClick(Sender: TObject);
    procedure ModositoGombClick(Sender: TObject);
    procedure NevEditEnter(Sender: TObject);
    procedure NevEditExit(Sender: TObject);
    procedure NevEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure PenztarosChange;
    procedure RacsNyitas;
    procedure UjNemokeGombClick(Sender: TObject);
    procedure UjOkeGombClick(Sender: TObject);
    procedure UjPenztarosGombClick(Sender: TObject);
    procedure KileptetoGombClick(Sender: TObject);
    procedure NoSureKilepGombClick(Sender: TObject);
    procedure SureKilepGombClick(Sender: TObject);
    procedure RenameEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    function GetkorzetIndex(_ksz: string): integer;
    function IdControl(_kod: string): boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ProsTMK: TProsTMK;

  _height,_width: word;

  _korzetnev: array[0..10] of string = ('???','KÖZPONT','SZEKSZÁRD','SZEGED','KECSKEMÉT',
  'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR','EXPRESSZ');

  _korzetkod: array[0..10] of string = ('999','000','010','020','040','050','063',
                                            '075','120','145','500');

  _sorveg: string = chr(13)+chr(10);

  _korzetszam,_penztarosnev,_idKod,_ujprosnev,_aktkorzetkod,_lastnums: string;
  _ujkorzetkod,_pcs,_ujidkod,_sorszam,_ujidkods,_korzetnums,_kb,_ujnums: string;

  _xx,_kilepett,_zz,_korzetIndex,_recno,_utsorszam,_ujsorszam: integer;
  _utidnum,_goodidnum,_idnum,_utnum,_ujnum,_code: integer;
  _lastletter: word;
  _sors,_aktsors: byte;
  _voltvaltozas: boolean;


 function dolgozokarbantarto: integer;stdcall;

implementation

{$R *.dfm}


// =============================================================================
                function dolgozokarbantarto: integer;stdcall;
// =============================================================================

begin
  Prostmk := Tprostmk.Create(Nil);
  result := prostmk.showmodal;
  prostmk.free;
end;

// =============================================================================
               procedure TPROSTMK.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := 158;
  Left := 208;
  Width := 864;
  Height := 684;

  with AlapPanel do
    begin
      Top     := 104;
      Left    := 128;
      Visible := true;
      Repaint;
    end;

  _voltValtozas             := False;
  MentesPanel.Visible       := False;
  BiztoskilepPanel.Visible  := False;
  TorloPanel.Visible        := False;
  ModifyPanel.Visible       := False;

  UjpenztarosPanel.Visible  := False;
  KorzetPanel.Caption       := '';
  PenztarosKodPanel.Caption := '';
  PenztarosNevPanel.Caption := '';

  Prostabla.Filtered        := false;

  KorzetCombo.Items.clear;
  Korzetcombo.clear;

  _zz := 0;
  while _zz<=10 do
    begin
      KorzetCombo.Items.Add(_korzetnev[_zz]);
      inc(_zz);
    end;
  KorzetCombo.ItemIndex := 1;

  RacsNyitas;
end;

// =============================================================================
                   procedure TProstmk.RacsNyitas;
// =============================================================================

begin

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  ProsDbase.Connected := true;
  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  PenztarosChange;
  ProsRacs.SetFocus;
end;


// =============================================================================
                   procedure TProstmk.PenztarosChange;
// =============================================================================

// az aktuális dolgozói adatlap kijelzése:

begin
  with prosQuery do
    begin
      _korzetszam   := FieldByName('KORZETSZAM').asString;
      _penztarosnev := trim(FieldByName('PENZTAROSNEV').asstring);
      _idKod        := FieldByName('IDKOD').asString;
      _sorszam      := FieldByNAme('SORSZAM').asString;
      _lastletter   := FieldByNAme('LASTREADLETTER').asInteger;
    end;

  _xx := GetKorzetIndex(_korzetszam);

  PenztarosnevPanel.Caption := _penztarosnev;
  IF _xx>-1 then KorzetPanel.Caption := _korzetnev[_xx]+ ' KÖRZET';

  PenztarosKodPanel.caption := _idKod;
  SorszamPanel.Caption      := _sorszam;
  KorlevelSorszam.Caption   := inttostr(_lastletter);
  PenztarosNevPanel.Repaint;

  Adatlap.Repaint;
end;

// =============================================================================
             procedure TProsTmk.UjPenztarosGombClick(Sender: TObject);
// =============================================================================

begin

  prosQuery.close;
  prosdbase.close;


  NevEdit.clear;
  id1.Caption := '';
  id2.Caption := '';
  id3.Caption := '';
  id4.Caption := '';
  id5.Caption := '';

  KorzetCombo.ItemIndex := 1;
  AlapPanel.Visible := False;

  with Ujpenztarospanel do
    begin
      Top     := 108;
      Left    := 176;
      Visible := true;
    end;

  UjokeGomb.Enabled := False;
  ActiveControl := Nevedit;
end;

// =============================================================================
      procedure TProsTMK.NevEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _ujProsNev := trim(nevedit.Text);
  if _ujProsNev='' then exit;

  KorzetCombo.ItemIndex := 1;
  ActiveControl := KorzetCombo;
end;

// =============================================================================
               procedure TProsTMK.KorzetComboChange(Sender: TObject);
// =============================================================================


begin
  // Korzetindex = 1..10-ig

  _korzetIndex := KorzetCombo.ItemIndex;
  if _korzetIndex=0 then exit;

  _aktKorzetKod := _korzetKod[_korzetIndex];

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM';

  ProsDbase.Connected := True;
  with ProsQuery do
    begin
      close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _utSorszam := FieldByNAme('SORSZAM').asInteger;
      Close;
    end;
  ProsDbase.close;
  _ujSorszam := _utSorszam + 1;

  // ----------------------------------------

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'WHERE KORZETSZAM='+chr(39) + _AKTKORZETKOD + chr(39) +_sorveg;
  _pcs := _pcs + 'ORDER BY IDKOD';

  ProsDbase.Connected := True;
  with ProsQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _idKod := FieldByName('IDKOD').asString;
      Close;
    end;
  ProsDbase.Close;

  _lastNums := midstr(_idkod,3,3);
  _kb := leftstr(_idKod,2);
  val(_lastNums,_utNum,_code);
  if _code<>0 then Exit;

  _ujNum := _utNum+1;
  _ujNums := inttostr(_ujNum);
  while length(_ujNums)<3 do _ujNums := '0' + _ujNums;

 _ujIdKod := _KB + _ujNums;

  id1.Caption := leftstr(_ujidkod,1);
  id2.Caption := midstr(_ujidkod,2,1);
  id3.Caption := midstr(_ujidkod,3,1);
  id4.Caption := midstr(_ujidkod,4,1);
  id5.Caption := midstr(_ujidkod,5,1);

  UjOkeGomb.Enabled := True;
  Activecontrol     := UjokeGomb;
end;

// =============================================================================
              procedure TProsTMK.UjokeGombClick(Sender: TObject);
// =============================================================================

begin
  _ujProsNev := trim(NevEdit.Text);
  if _ujProsNev='' then
    begin
      ActiveControl := NevEdit;
      Exit;
    end;

  _xx := KorzetCombo.ItemIndex;
  if _xx=0 then
    begin
      ActiveControl := KorzetCombo;
      Exit;
    end;

  _ujKorzetKod := _korzetKod[_xx];
  if idControl(_ujIdKod) then
    begin
      ShowMessage('ILYEN SZÁMÚ ID-KÓD MÁR LÉTEZIK !');

      Id1.Caption := '';
      Id2.Caption := '';
      Id3.Caption := '';
      Id4.Caption := '';
      Id5.Caption := '';
      AlapPanel.Visible := True;
      exit;
    end;

  _pcs := 'INSERT INTO PENZTAROSOK (IDKOD,PENZTAROSNEV,';
  _pcs := _pcs + 'KORZETSZAM,SORSZAM)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _ujidkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ujprosnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ujkorzetkod + chr(39) + ',';
  _pcs := _pcs + inttostr(_ujsorszam)+')';

  // ---------------------------------------------------------------------------

  ProsParancs(_pcs);

  UjPenztarosPanel.Visible := false;
  _voltvaltozas := True;

  AlapPanel.Visible := True;
  RacsNyitas;
end;

// =============================================================================
            procedure TProsTMK.KileptetoGombClick(Sender: TObject);
// =============================================================================

begin
  KileponevPanel.Caption := _penztarosnev;
  with BiztosKilepPanel do
    begin
      Top     := 165;
      Left    := 230;
      Visible := True;
    end;
  ActiveControl := NoSureKilepGomb;
end;

// =============================================================================
             procedure TProsTMK.NoSureKilepGombClick(Sender: TObject);
// =============================================================================

begin
  BiztosKilepPanel.Visible := False;
  ProsRacs.setfocus;
end;

// =============================================================================
          procedure TProsTMK.SureKilepGombClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'DELETE FROM PENZTAROSOK WHERE SORSZAM=' + chr(39) + _sorszam + chr(39);
  ProsQuery.close;
  Prosdbase.close;

  Prosparancs(_pcs);
  BiztoskilepPanel.visible := False;
  _voltvaltozas := True;
  RacsNyitas;
end;

// =============================================================================
              procedure TProsTMK.KilepoGombClick(Sender: TObject);
// =============================================================================

begin
  ProsQuery.close;
  Prosdbase.close;
  if _voltValtozas then AdatKimentes;
  ModalResult := 1;
end;

// =============================================================================
                       procedure TProsTmk.Adatkimentes;
// =============================================================================

var _mFile,_mPath,_prosnev,_idkod,_kszams,_rekord: string;
    _txtiras: Textfile;

begin
   MentesPanel.Visible := true;
   Mentespanel.Repaint;

  _mfile := 'ptarosok.txt';
  _mPath := 'c:\receptor\mail\ptarosok\' + _mfile;

  Assignfile(_txtiras,_mPath);
  Rewrite(_txtiras);

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  prosDbase.Connected := true;
  with prosQuery do
    begin
      Close;
      Sql.clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not prosQuery.eof do
    begin
      with prosQuery do
        begin
          _prosnev := trim(FieldByName('PENZTAROSNEV').asstring);
          _idkod   := FieldByName('IDKOD').asstring;
          _kszams  := FieldByName('KORZETSZAM').asstring;
        end;

      _rekord := _kszams+_idkod+_prosnev;
      writeLn(_txtiras,_rekord);
      prosQuery.Next;
    end;
   CloseFile(_txtIras);
   prosQuery.close;
   prosDbase.Close;
   Sleep(1000);
   MentesPanel.Visible := False;
end;

// =============================================================================
             function Tprostmk.GetkorzetIndex(_ksz: string): integer;
// =============================================================================

var _y: integer;

begin
  result := -1;
  _y := 0;
  while _y<=10 do
    begin
      if _ksz=_korzetkod[_y] then
        begin
          result := _y;
          Break;
        end;
      inc(_y);
    end;
end;

// =============================================================================
        procedure TPROSTMK.PROSRACSKeyUp(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  PenztarosChange;
end;

// =============================================================================
               procedure TProsTMK.PROSRACSCellClick(Column: TColumn);
// =============================================================================

begin
  Penztaroschange;
end;

// =============================================================================
             procedure TProsTMK.NevEditEnter(Sender: TObject);
// =============================================================================

begin
  Nevedit.Color := $B0FFFF;
end;

// =============================================================================
              procedure TProsTMK.NevEditExit(Sender: TObject);
// =============================================================================

begin
  Nevedit.Color := clWindow;
end;

// =============================================================================
           procedure TProsTMK.UjnemOkeGombClick(Sender: TObject);
// =============================================================================

begin

  UjpenztarosPanel.Visible := false;
  alapPanel.Visible := True;
  AlapPanel.repaint;

  prosdbase.Connected := true;
  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
    end;
  prosRacs.SetFocus;
end;

// =============================================================================
              function TProstmk.idcontrol(_kod: string): boolean;
// =============================================================================

begin
  result := False;
  prosQuery.close;
  prosDbase.close;

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'WHERE IDKOD=' + chr(39) + _kod + chr(39);

  prosdbase.connected := true;
  with prosQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
      _recno := recno;
      close;
    end;
  prosdbase.close;
  if _recno>0 then Result := True;
end;

// =============================================================================
              procedure TProsTmk.ProsParancs(_ukaz: string);
// =============================================================================

begin
  prosDbase.Connected := true;
  if prosTranz.InTransaction then prosTranz.Commit;
  prosTranz.StartTransaction;
  with prosQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  prosTranz.commit;
  prosDbase.close;
end;


// =============================================================================
             procedure TProsTMK.DelMegsemGombClick(Sender: TObject);
// =============================================================================

begin
  prosDbase.Connected := true;
  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  TorloPanel.Visible := False;
 
  PenztarosChange;
end;


// =============================================================================
               procedure TProsTMK.ModositoGombClick(Sender: TObject);
// =============================================================================

begin
  ReNameEdit.Text := '';
  with ModifyPanel do
    begin
      top  := 192;
      Left := 432;
      Visible := True;
    end;
  Activecontrol := RenameEdit;
end;


// =============================================================================
      procedure TProsTMK.RenameEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _ujprosnev := trim(RenameEdit.Text);
  if _ujprosnev='' then exit;
  ActiveControl := ModokeGomb;
end;

// =============================================================================
            procedure TPROSTMK.MODMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModifyPanel.Visible := false;
end;

// =============================================================================
               procedure TPROSTMK.MODOKEGOMBClick(Sender: TObject);
// =============================================================================

begin

  _ujprosnev := trim(RenameEdit.Text);
  if _ujprosnev='' then
    begin
      ActiveControl := RenameEdit;
      exit;
    end;

  _pcs := 'UPDATE PENZTAROSOK SET PENZTAROSNEV=' +CHR(39) + _ujProsNev + chr(39) + _sorveg;
  _pcs := _pcs + 'WHERE SORSZAM=' + chr(39) + _sorszam + chr(39);

  ProsParancs(_pcs);
  ModifyPanel.visible := False;
  _voltvaltozas := True;
  RacsNyitas;
end;


end.
