unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGrids, ExtCtrls, StdCtrls, DB, IBCustomDataSet,
  IBTable, IBDatabase, Buttons, IBQuery, strutils, jpeg;

type
  TPROSTMK = class(TForm)
    Panel1: TPanel;
    PROSRACS: TDBGrid;
    Adatlap: TPanel;
    KorzetszamPanel: TPanel;
    KorzetPanel: TPanel;
    PenztaroskodPanel: TPanel;
    PenztarosnevPanel: TPanel;
    KilepettPanel: TPanel;
    PROSTRANZ: TIBTransaction;
    PROSDBASE: TIBDatabase;
    PROSTABLA: TIBTable;
    PROSSOURCE: TDataSource;
    UjPenztarosGomb: TBitBtn;
    TorloGomb: TBitBtn;
    KilepoGomb: TBitBtn;
    ModositoGomb: TBitBtn;
    UjpenztarosPanel: TPanel;
    Label2: TLabel;
    NevEdit: TEdit;
    Label3: TLabel;
    KorzetCombo: TComboBox;
    Label4: TLabel;
    Label5: TLabel;
    Shape1: TShape;
    Id1: TPanel;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    Shape6: TShape;
    Panel3: TPanel;
    Id3: TPanel;
    Id4: TPanel;
    Id5: TPanel;
    Id2: TPanel;
    Shape5: TShape;
    UjOkeGomb: TBitBtn;
    UjNemokeGomb: TBitBtn;
    HideEdit: TEdit;
    Takaro: TPanel;
    TorloPanel: TPanel;
    Label6: TLabel;
    NevCsik: TPanel;
    DelokeGomb: TBitBtn;
    DelMegsemGomb: TBitBtn;
    Label7: TLabel;
    GombTakaro: TPanel;
    Label8: TLabel;
    ModifyPanel: TPanel;
    NevModEdit: TEdit;
    Label9: TLabel;
    Label11: TLabel;
    ModokeGomb: TBitBtn;
    ModMegsemGomb: TBitBtn;
    Mentespanel: TPanel;
    KileptetoGomb: TBitBtn;
    BIZTOSKILEPPANEL: TPanel;
    SUREKILEPGOMB: TBitBtn;
    nosurekilepgomb: TBitBtn;
    Label12: TLabel;
    KILEPONEVPANEL: TPanel;
    Shape8: TShape;
    idkodpanel: TPanel;
    RENAMEEDIT: TEdit;
    Label10: TLabel;
    Label13: TLabel;
    korzetnumpanel: TPanel;
    Shape9: TShape;
    Label14: TLabel;
    Label15: TLabel;
    PROSQUERY: TIBQuery;
    Image1: TImage;

    procedure AdatKimentes;
    procedure DelMegsemGombClick(Sender: TObject);
    procedure DelOkeGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure HideEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure ProsParancs(_ukaz: string);
    procedure PROSRACSCellClick(Column: TColumn);
    procedure PROSRACSKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure Id4Click(Sender: TObject);
    procedure Id4Exit(Sender: TObject);
    procedure Id5Click(Sender: TObject);
    procedure Id5Exit(Sender: TObject);


    procedure KilepoGombClick(Sender: TObject);
    procedure KorzetComboChange(Sender: TObject);
 
    procedure ModMegsemGombClick(Sender: TObject);
    procedure ModOkeGombClick(Sender: TObject);
    procedure ModositoGombClick(Sender: TObject);
    procedure NevEditEnter(Sender: TObject);
    procedure NevEditExit(Sender: TObject);
    procedure NevEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure NevModEditEnter(Sender: TObject);
    procedure NevModEditExit(Sender: TObject);
    procedure NevModEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure PenztarosChange;
    procedure RacsNyitas;
    procedure TorloGombClick(Sender: TObject);
    procedure UjNemokeGombClick(Sender: TObject);
    procedure UjOkeGombClick(Sender: TObject);
    procedure UjPenztarosGombClick(Sender: TObject);

    function GetkorzetIndex(_ksz: string): integer;
    function IdControl(_kod: string): boolean;
    function Nulele(_i: integer): string;
  
    procedure KILEPTETOGOMBClick(Sender: TObject);

    procedure nosurekilepgombClick(Sender: TObject);
    procedure SUREKILEPGOMBClick(Sender: TObject);
    procedure RENAMEEDITEnter(Sender: TObject);
    procedure RENAMEEDITExit(Sender: TObject);
    procedure RENAMEEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  
  
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ProsTMK: TProsTMK;

  _height,_width: word;

  _korzetnev: array[0..9] of string = ('KÖZPONT','SZEKSZÁRD','SZEGED','KECSKEMÉT',
  'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR','EXPRESSZ');

  _korzetkod: array[0..9] of string = ('000','010','020','040','050','063',
                                            '075','120','145','500');

  _sorveg: string = chr(13)+chr(10);

  _korzetszam,_penztarosnev,_idKod,_ujprosnev,_aktkorzetkod,_lastnums: string;
  _ujkorzetkod,_pcs,_ujidkod,_sorszam,_ujidkods,_korzetnums,_kb,_ujnums: string;

  _xx,_kilepett,_zz,_korzetIndex,_idp,_recno,_utsorszam,_ujsorszam: integer;
  _utidnum,_goodidnum,_idnum,_utnum,_ujnum,_code: integer;
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

  _voltValtozas             := False;
  KilepettPanel.caption     := '';
  MentesPanel.Visible       := False;
  BiztoskilepPanel.Visible  := False;
  TorloPanel.Visible        := False;
  ModifyPanel.Visible       := False;
  KorzetSzampanel.Caption   := '';
  UjpenztarosPanel.Visible  := False;
  KorzetPanel.Caption       := '';
  PenztarosKodPanel.Caption := '';
  PenztarosNevPanel.Caption := '';
  GombTakaro.Visible        := False;
  Prostabla.Filtered          := false;

  KorzetCombo.Items.clear;
  Korzetcombo.clear;
  KorzetCombo.Items.Add('  NINCS KÖRZET');

  _zz := 0;
  while _zz<=9 do
    begin
      KorzetCombo.Items.Add(_korzetnev[_zz]);
      inc(_zz);
    end;

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
  _pcs := _pcs + 'WHERE KILEPETT=0' + _sorveg;
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
                   procedure TProstmk.PenztarosChange;
// =============================================================================

// az aktuális dolgozói adatlap kijelzése:

begin
  IF prosQuery.Eof THEN exit;

  with prosQuery do
    begin
      _korzetszam   := FieldByName('KORZETSZAM').asString;
      _penztarosnev := trim(FieldByName('PENZTAROSNEV').asstring);
      _idKod        := FieldByName('IDKOD').asString;
      _kilepett     := FieldByNAme('KILEPETT').asInteger;
    end;

  _xx := GetKorzetIndex(_korzetszam);

  KorzetszamPanel.Caption   := _korzetszam;
  IF _xx>-1 then KorzetPanel.Caption       := _korzetnev[_xx]+ ' KÖRZET';
  PenztarosKodPanel.caption := _idKod;
  PenztarosnevPanel.caption := _penztarosnev;
  PenztarosnevPanel.Repaint;

  if _kilepett>0 then kilepettpanel.Caption := 'KILÉPETT !'
  else KilepettPanel.Caption := '';
  Adatlap.Repaint;
end;

// =============================================================================
             function Tprostmk.GetkorzetIndex(_ksz: string): integer;
// =============================================================================

var _y: integer;

begin
  result := -1;
  _y := 0;
  while _y<=8 do
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
             procedure TProsTmk.UjPenztarosGombClick(Sender: TObject);
// =============================================================================

begin
  Gombtakaro.Visible := true;

  prosQuery.close;
  prosdbase.close;
  
  // ----------------------------

  nevedit.clear;
  id1.Caption := '';
  id2.Caption := '';
  id3.Caption := '';
  id4.Caption := '';
  id5.Caption := '';

  KorzetCombo.ItemIndex := 0;

  with Ujpenztarospanel do
    begin
      Top     := 56;
      Left    := 24;
      Visible := true;
    end;

  UjokeGomb.Enabled := False;
  ActiveControl := Nevedit;
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
      procedure TProsTMK.NevEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _ujprosnev := trim(nevedit.Text);
  if _ujprosnev='' then exit;

  Activecontrol := KorzetCombo;
end;


// =============================================================================
               procedure TProsTMK.KorzetComboChange(Sender: TObject);
// =============================================================================


begin
  _korzetIndex := Korzetcombo.itemindex;
  if _korzetIndex=0  then exit;

  dec(_korzetIndex);
  _aktkorzetkod := _korzetKod[_korzetIndex];

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY SORSZAM';

  prosDbase.Connected := true;
  with prosQuery do
    begin
      close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _utSorszam := FieldByNAme('SORSZAM').asInteger;
      Close;
    end;
  prosdbase.close;
  _ujsorszam := _utsorszam + 1;

  // ----------------------------------------

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'WHERE KORZETSZAM='+chr(39) + _AKTKORZETKOD + chr(39) +_sorveg;
  _pcs := _pcs + 'ORDER BY IDKOD';

  prosDbase.Connected := true;
  with prosQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _idKod := FieldByName('IDKOD').asString;
      close;
    end;

  prosdbase.close;
  _lastnums := midstr(_idkod,3,3);
  _kb := leftstr(_lastnums,1);

  if _aktKorzetkod='063' then
    begin
      if _kb='3' then _lastnums := '0'+midstr(_lastnums,2,2);
    end;

 if (_aktKorzetkod='075') or (_aktkorzetkod='145') then
    begin
      if _kb='5' then _lastnums := '0'+midstr(_lastnums,2,2);
    end;

 val(_lastnums,_utnum,_code);
 if _code<>0 then _utnum :=0;

 _ujnum := _utnum+1;
 _ujnums := inttostr(_ujnum);
 while length(_ujnums)<3 do _ujnums := '0' + _ujnums;

 _ujidkod := leftstr(_aktkorzetkod,2) + _ujnums;


  id1.Caption := leftstr(_ujidkod,1);
  id2.caption := midstr(_ujidkod,2,1);
  id3.caption := midstr(_ujidkod,3,1);
  id4.caption := midstr(_ujidkod,4,1);
  id5.Caption := midstr(_ujidkod,5,1);
  UjOkeGomb.Enabled := true;
  Activecontrol := UjokeGomb;
end;


// =============================================================================
              function Tprostmk.Nulele(_i: integer): string;
// =============================================================================

begin
  result := inttostr(_i);
  if _i<10 then result := '0' + result;
end;


// =============================================================================
     procedure TProsTMK.HideEditKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================


var _bill: integer;

begin
  _bill := ord(key);
  if (_bill<48) or (_bill>57) then exit;

  if _idp=1 then
    begin
      id4.Caption := chr(_bill);
      id4.Color := clWhite;
      if id5.Caption>'/' then
        begin
          UjokeGomb.Enabled := true;
          Activecontrol := UjOkeGomb;
          exit;
        end;
      id5.Color := $b0ffff;
      _idp:=2;
      Activecontrol := HideEdit;
    end else
    begin
      id5.caption := chr(_bill);
      id5.Color := clwhite;
      if id4.Caption>'/' then
        begin
          UjokeGomb.Enabled := true;
          Activecontrol := UjOkeGomb;
          exit;
        end;
      id4.Color := $B0FFFF;
      _idp := 1;
      Activecontrol := HideEdit;
    end;
end;

// =============================================================================
           procedure TProsTMK.UjnemOkeGombClick(Sender: TObject);
// =============================================================================

begin
  GombTakaro.Visible := false;
  UjpenztarosPanel.Visible := false;

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
              procedure TProsTMK.Id4Click(Sender: TObject);
// =============================================================================

begin
  _idp :=1;
  id4.Color := $b0ffff;
  ActiveControl := HideEdit;
end;

// =============================================================================
               procedure TProsTmk.Id5Click(Sender: TObject);
// =============================================================================

begin
  _idp := 2;
  id5.Color := $b0ffff;
  Activecontrol := Hideedit;
end;

// =============================================================================
                procedure TProsTMK.Id4Exit(Sender: TObject);
// =============================================================================

begin
  Id4.Color := clWindow;
end;

// =============================================================================
               procedure TProsTMK.Id5Exit(Sender: TObject);
// =============================================================================

begin
  Id5.Color := CLWINDOW;
end;

// =============================================================================
              procedure TProsTMK.UjokeGombClick(Sender: TObject);
// =============================================================================

begin
  _ujProsNev := trim(nevedit.Text);
  if _ujprosnev='' then
    begin
      Activecontrol := Nevedit;
      exit;
    end;

  _xx := Korzetcombo.ItemIndex;
  if _xx=0 then
    begin
      Activecontrol := KorzetCombo;
      Exit;
    end;
  dec(_xx);

  _ujkorzetKod := _korzetkod[_xx];
  if idcontrol(_ujidkod) then
    begin
      ShowMessage('ILYEN SZÁMÚ ID-KÓD MÁR LÉTEZIK !');
      Id4.Caption := '';
      Id5.CAPTION := '';

      _IdP := 1;

      Id4.Color := $B0FFFF;
      Activecontrol := HideEdit;
      exit;
    end;

  _pcs := 'INSERT INTO PENZTAROSOK (IDKOD,PENZTAROSNEV,';
  _pcs := _pcs + 'KORZETSZAM,KILEPETT,SORSZAM)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _ujidkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ujprosnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ujkorzetkod + chr(39) + ',0,';
  _pcs := _pcs + inttostr(_ujsorszam)+')';

  // ---------------------------------------------------------------------------

  ProsParancs(_pcs);

  UjPenztarosPanel.Visible := false;
  Gombtakaro.Visible := false;

  _voltvaltozas := True;
  RacsNyitas;

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
             procedure TProsTMK.TorloGombClick(Sender: TObject);
// =============================================================================

begin
  GombTakaro.Visible := true;
  prosQuery.close;
  prosDbase.close;
  Nevcsik.Caption := _penztarosnev+'t';

  with TorloPanel do
    begin
      Top  := 56;
      Left := 24;
      Visible := True;
    end;

  ActiveControl := Delokegomb;
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
  Gombtakaro.Visible := false;

  PenztarosChange;
end;

// =============================================================================
             procedure TProsTMK.DelOkeGombClick(Sender: TObject);
// =============================================================================

begin

  _pcs := 'DELETE FROM PENZTAROSOK'+_sorveg;
  _pcs := _pcs + 'WHERE IDKOD='+chr(39)+_idkod+chr(39);
  prosParancs(_pcs);

  prosDbase.Connected := true;
  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  TorloPanel.Visible := False;
  GombTakaro.Visible := False;
  PenztarosChange;
end;


// =============================================================================
               procedure TProsTMK.ModositoGombClick(Sender: TObject);
// =============================================================================



begin
  if _kilepett>0 then exit;

  GombTakaro.Visible := True;
  Nevmodedit.Text := _penztarosnev;

  idkodpanel.Caption := _IDKOD;
  Korzetnumpanel.Caption := leftstr(_idkod,3);

  with ModifyPanel do
    begin
      top := 104;
      Left := 320;
      Visible := true;
    end;
  Activecontrol := RenameEdit;
end;

// =============================================================================
            procedure TProsTMK.NevModEditEnter(Sender: TObject);
// =============================================================================

begin
  NevModEdit.Color := $b0ffff;
end;

// =============================================================================
              procedure TProsTMK.NevModEditExit(Sender: TObject);
// =============================================================================

begin
  NevModEdit.Color := clWindow;
end;

// =============================================================================
      procedure TProsTMK.NevModEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _ujprosnev := trim(nevmodedit.Text);
  if _ujprosnev='' then exit;

  ActiveControl := ModokeGomb;
end;



// =============================================================================
            procedure TPROSTMK.MODMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModifyPanel.Visible := false;
  Gombtakaro.Visible := False;
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
  _korzetszam := Korzetnumpanel.caption;

  _pcs := 'INSERT INTO PENZTAROSOK (IDKOD,PENZTAROSNEV,KORZETSZAM,KILEPETT)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + CHR(39) + _IDKOD + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ujProsnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _korzetszam + chr(39) + ',0)';

  ProsParancs(_pcs);

  prosDbase.Connected := true;
  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  ModifyPanel.visible := False;
  GombTakaro.visible := False;

  PenztarosChange;
  ProsRacs.SetFocus;
end;


procedure TPROSTMK.KILEPTETOGOMBClick(Sender: TObject);
begin
  KileponevPanel.Caption := _penztarosnev;
    with BiztoskilepPanel do
    begin
      Top := 100;
      Left := 130;
      Visible := True;
    end;
  Activecontrol := NoSureKilepGomb;
end;

procedure TPROSTMK.nosurekilepgombClick(Sender: TObject);
begin
  BiztoskilepPanel.Visible := false;
  ProsRacs.setfocus;
end;



procedure TPROSTMK.SUREKILEPGOMBClick(Sender: TObject);
begin
  _pcs := 'UPDATE PENZTAROSOK SET KILEPETT=1'+_sorveg;
  _pcs := _pcs + 'WHERE IDKOD=' + chr(39) + _idkod + chr(39);

  ProsQuery.close;
  Prosdbase.close;

  Prosparancs(_pcs);

  prosDbase.Connected := true;
  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  PenztarosChange;

  BiztoskilepPanel.visible := false;
  ProsRacs.setfocus;
end;



procedure TPROSTMK.RENAMEEDITEnter(Sender: TObject);
begin
  RenameEdit.Color := clYellow;
end;

procedure TPROSTMK.RENAMEEDITExit(Sender: TObject);
begin
  RenameEdit.Color := clWindow;
end;

procedure TPROSTMK.RENAMEEDITKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  Activecontrol := Modokegomb;
end;


procedure TProstmk.RacsNyitas;
begin

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'WHERE KILEPETT=0' + _sorveg;
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

end.
