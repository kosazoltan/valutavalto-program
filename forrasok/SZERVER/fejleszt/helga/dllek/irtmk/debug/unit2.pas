unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, IBDatabase, IBCustomDataSet, IBQuery, Grids,
  DBGrids, ExtCtrls, Buttons, jpeg, IBTable;

type
  TForm2 = class(TForm)
    GOMBTAKAROPANEL     : TPanel;
    IRSZAMEDITPANEL     : TPanel;
    KERDEZOPANEL        : TPanel;
    Panel1              : TPanel;
    Panel2              : TPanel;
    UJPENZTARTAKAROPANEL: TPanel;
    UZLETPANEL          : TPanel;

    NEVEDIT             : TEdit;
    IRODACIMEDIT        : TEdit;
    IRODASZAMEDIT       : TEdit;
    BOLTNEVEDIT         : TEdit;
    BANKKODEDIT         : TEdit;
    ROVIDNEVEDIT        : TEdit;
    TELEFONEDIT         : TEdit;

    ELOIRODABOX         : TCheckBox;
    SATURBOX            : TCheckBox;
    SUNBOX              : TCheckBox;
    CLOSEDBOX           : TCheckBox;
    VALFORGBOX          : TCheckBox;
    WUBOX               : TCheckBox;
    EKERBOX             : TCheckBox;

    KFTCOMBO            : TComboBox;
    KORZETCOMBO         : TComboBox;
    KFTMODCOMBO         : TComboBox;
    KORZETMODCOMBO      : TComboBox;

    Label1              : TLabel;
    Label2              : TLabel;
    Label3              : TLabel;
    Label4              : TLabel;
    Label5              : TLabel;
    Label6              : TLabel;
    Label7              : TLabel;
    Label8              : TLabel;
    Label9              : TLabel;
    Label10             : TLabel;
    Label11             : TLabel;
    Label12             : TLabel;
    Label13             : TLabel;
    Label14             : TLabel;
    Label15             : TLabel;
    Label16             : TLabel;
    Label17             : TLabel;

    Shape1              : TShape;
    Shape2              : TShape;
    Shape5              : TShape;
    Shape3              : TShape;
    Shape4              : TShape;

    MODOKEGOMB          : TBitBtn;
    MODMEGSEMGOMB       : TBitBtn;
    megsemujirodagomb   : TBitBtn;
    IGENGOMB            : TBitBtn;
    megsemgomb          : TBitBtn;
    KILEPESGOMB         : TBitBtn;
    UPOKEGOMB           : TBitBtn;
    UPMEGSEMGOMB        : TBitBtn;

    ARTQUERY            : TIBQuery;
    ARTDBASE            : TIBDatabase;
    ARTTRANZ            : TIBTransaction;

    RECEPTORQUERY       : TIBQuery;
    RECEPTORDBASE       : TIBDatabase;
    RECEPTORTRANZ       : TIBTransaction;

    UJQUERY             : TIBQuery;
    UJDBASE             : TIBDatabase;
    UJTRANZ             : TIBTransaction;
    UJTABLA             : TIBTable;

    WQUERY              : TIBQuery;
    WDBASE              : TIBDatabase;
    WTRANZ              : TIBTransaction;

    ARTIRODASOURCE      : TDataSource;
    IRODASOURCE         : TDataSource;

    PTARRADIO           : TRadioButton;
    ETARRADIO           : TRadioButton;

    GroupBox1           : TGroupBox;

    Image1              : TImage;

    IRODARACS           : TDBGrid;

    procedure KILEPESGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KFTCOMBOChange(Sender: TObject);
    procedure KORZETCOMBOChange(Sender: TObject);
    procedure KORZETCOMBOClick(Sender: TObject);
    procedure KFTCOMBOClick(Sender: TObject);
    procedure IrodaValtozott;
    procedure IRODARACSCellClick(Column: TColumn);
    function ScanEtarszam(_etsz: byte): integer;
    procedure IRODARACSKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ELOIRODABOXClick(Sender: TObject);
    procedure DataReadOnly(_tf: boolean);
    procedure ADATMODOSITOGOMBClick(Sender: TObject);
    procedure Wparancs(_ukaz: string);
    procedure AdatbazisKrealas;
    procedure MakemainCurr;
    procedure MakeElohavi;
    procedure MakeElonapi;
    procedure ArtIrodaKezelo;
    procedure ArtIrodaValtozott;
    procedure ArtParancs(_ukaz: string);

    procedure MODMEGSEMGOMBClick(Sender: TObject);
    procedure NEVEDITEnter(Sender: TObject);
    procedure NEVEDITExit(Sender: TObject);
    procedure NEVEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MODOKEGOMBClick(Sender: TObject);
    function Getvaros(_nn: string): string;

    procedure UJPENZTARGOMBClick(Sender: TObject);
    procedure IRODASZAMEDITEnter(Sender: TObject);
    procedure IRODASZAMEDITKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure IGENGOMBClick(Sender: TObject);
    procedure megsemgombClick(Sender: TObject);
    procedure UjPenztarFelvetel;

    function IrodaszamControl(_newnum: byte):integer;
    procedure megsemujirodagombClick(Sender: TObject);
    procedure UPMEGSEMGOMBClick(Sender: TObject);
    procedure UPOKEGOMBClick(Sender: TObject);
    procedure KORZETMODCOMBOClick(Sender: TObject);


    private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _korzetnev: array[0..8] of string = ('Szekszárd','Szeged','Kecskemét',
               'Debrecen','Nyíregyház','Nékéscsaba','Pécs','Kaposvár','Zálog');
  _korzetszam: array[0..8] of byte = (10,20,40,50,63,75,120,145,180);

  _kftnev: array[0..1] of string = ('Exclusive Best Change Kft','Express Ékeszerház és Minibank Kft');

  _kftrovidnev: array[0..1] of string = ('Best Change','Expressz Kft');
  _kftbetuk: array[0..1] of string = ('B','Z');

  _kftkorzet: array[0..8] of byte = (2,0,0,1,1,1,2,2,3);

  _etar: array[0..1,0..7] of byte;
  _host : string = '185.43.207.99';

  _bedit: array[1..6] of TEdit;
  Ujdatabase: TIBdatabase;

  _kftindex,_kindex,_ess,_code,_irOke,_recno: integer;
  _aktertekTar,_wu,_vvaltas,_uzlet,_y,_kftss,_ujirodaszam: byte;

  _aktedit: Tedit;

  _pcs,_keszletnev,_rovidnev,_irodacim,_boltnev,_telefon,_bankkod,_irnums: string;
  _sundayclose,_saturdayclose,_closed,_cb,_eker,_status,_varos,_aktnev: string;
  _adatbazisnev,_adatbazisPath: string;
  _sorveg: string = chr(13)+chr(10);

  _ezUjptar,_ezexpressz: boolean;


function irodakarbantarto: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
               function irodakarbantarto: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  form2.free;
end;



// =============================================================================
                 procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top    := 158;
  Left   := 208;
  Height := 684;
  Width  := 864;

  _ezexpressz := False;

  _etar[0,0] := 20;
  _etar[0,1] := 40;
  _etar[0,2] := 50;
  _etar[0,3] := 63;
  _etar[0,4] := 75;
  _etar[0,5] := 10;
  _etar[0,6] := 120;
  _etar[0,7] := 145;
  _etar[1,0] := 180;

  _Bedit[1] := NevEdit;
  _Bedit[2] := RovidNevEdit;
  _Bedit[3] := IrodacimEdit;
  _Bedit[4] := BoltnevEdit;
  _Bedit[5] := Telefonedit;
  _Bedit[6] := BankkodEdit;

  Datareadonly(True);
  _ezujptar := False;

  KftModcombo.Items.clear;

  _y := 0;
  while _y<4 do
    begin
      _aktnev := _kftrovidnev[_y];
      Kftmodcombo.Items.add(_aktnev);
      inc(_y);
    end;
  Kftmodcombo.ItemIndex := -1;

  KorzetModcombo.Items.clear;
  _y := 0;
  while _y<9 do
    begin
      _aktnev := _korzetnev[_y];
      KorzetModcombo.items.add(_aktnev);
      inc(_y);
    end;

  KorzetModCombo.ItemIndex := -1;
  Kftcombo.ItemIndex := 0;
  KFTCOmboChange(Nil);
end;

// =============================================================================
              procedure TForm2.KILEPESGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;


// =============================================================================
                procedure TForm2.KFTCOMBOChange(Sender: TObject);
// =============================================================================

begin
  _ezexpressz := False; 
  _kftindex := KFTcombo.itemindex;
  case _kftindex of
    0: begin
         Korzetcombo.Items.clear;
         KorzetCombo.Items.Add('SZEGEDI KÖRZET');
         KorzetCombo.Items.Add('KECSKEMÉTI KÖRZET');

         KorzetCombo.Items.Add('DEBRECENI KÖRZET');
         KorzetCombo.Items.Add('NYÍREGYHÁZI KÖRZET');
         KorzetCombo.Items.Add('BÉKÉSCSABAI KÖRZET');

         KorzetCombo.Items.Add('SZEKSZÁRDI KÖRZET');
         KorzetCombo.Items.Add('PÉCSI KÖRZET');
         KorzetCombo.Items.Add('KAPOSVÁRI KÖRZET');
       end;

    1: begin
         Korzetcombo.Items.clear;
         KorzetCombo.Items.Add('ZÁLOGHÁZI KÖRZET');
         _ezexpressz := True;
       end;
   end;
   Korzetcombo.ItemIndex := 0;
   Korzetcomboclick(Nil);
end;

// =============================================================================
              procedure TForm2.KORZETCOMBOChange(Sender: TObject);
// =============================================================================

begin
  Irodasource.Enabled := False;
  
  if (_ezexpressz) then
    begin
      ArtIrodaKezelo;
      exit;
    end;

  DataReadOnly(False);
  UjpenztarTakaroPanel.Visible := False;

  _kindex := KorzetCombo.itemindex;
  _aktertektar := _etar[_kftIndex,_kindex];

   _pcs := 'SELECT * FROM IRODAK' + _sorveg;
   _pcs := _pcs + 'WHERE (ERTEKTAR=' + inttostr(_aktertektar)+')';
   if EloirodaBox.Checked then _pcs := _pcs + ' AND (CLOSED='+chr(39)+'N'+chr(39)+')';
   _pcs := _pcs + _sorveg;
   _pcs := _pcs + 'ORDER BY UZLET';

   ReceptorDbase.Connected := true;
   with ReceptorQuery do
     begin
       Close;
       sql.clear;
       sql.Add(_pcs);
       Open;
     end;
   IrodaValtozott;
   Irodaracs.DataSource := irodasource;
   Irodasource.Enabled := true;
   Irodaracs.SetFocus;
end;

procedure Tform2.artirodaKezelo;

begin
  _ezexpressz := True;
  irodaSource.Enabled := False;

  DataReadOnly(False);
  UjpenztarTakaroPanel.Visible := False;


  _aktertektar := 180;

   _pcs := 'SELECT * FROM IRODAK' + _sorveg;
   if EloirodaBox.Checked then _pcs := _pcs + 'WHERE CLOSED='+chr(39)+'N'+chr(39)+_sorveg;
   _pcs := _pcs + 'ORDER BY UZLET';

   ArtDbase.Connected := true;
   with ArtQuery do
     begin
       Close;
       sql.clear;
       sql.Add(_pcs);
       Open;
     end;
   ArtIrodaValtozott;
   Irodaracs.DataSource := Artirodasource;
   ArtIrodasource.Enabled := true;
   Irodaracs.SetFocus;
END;



// =============================================================================
                 procedure TForm2.KORZETCOMBOClick(Sender: TObject);
// =============================================================================

begin
  Korzetcombochange(Nil);
end;

// =============================================================================
               procedure TForm2.KFTCOMBOClick(Sender: TObject);
// =============================================================================

begin
  Korzetcomboclick(nil);
end;

// =============================================================================
            procedure TForm2.IRODARACSCellClick(Column: TColumn);
// =============================================================================

begin
  Irodavaltozott;
end;

// =============================================================================
                       procedure TForm2.IrodaValtozott;
// =============================================================================

begin
  if _ezexpressz then
    begin
      ArtIrodaValtozott;
      exit;
    end;

  DatareadOnly(True);
  Gombtakaropanel.Visible := False;

  with ReceptorQuery do
    begin
      _uzlet         := FieldByName('UZLET').asInteger;
      _keszletnev    := trim(FieldByName('KESZLETNEV').asString);
      _rovidnev      := trim(FieldByName('EXCELNEV').asString);
      _irodacim      := trim(fieldByName('IRODACIM').asString);
      _boltnev       := trim(FieldByNAme('BOLTNEV').asString);
      _telefon       := trim(FieldByNAme('TELEFON').asString);
      _bankkod       := trim(FieldByNAme('BANKKOD').asString);
      _sundayclose   := FieldByNAme('SUNDAYCLOSE').asString;
      _saturdayclose := FieldByNAme('SATURDAYCLOSE').asString;
      _closed        := FieldByName('CLOSED').asstring;
      _cb            := FieldByNAme('CEGBETU').asString;
      _wu            := FieldByName('WESTERNUNION').asInteger;
      _eker          := trim(FieldByNAme('EKERESKEDELEM').asString);
      _vvaltas       := FieldByName('VALUTAVALTAS').asInteger;
      _status        := FieldByName('STATUS').asString;
      _varos         := trim(FieldByNAme('VAROS').asstring);
    end;

      // --------------------------------------------------

    UzletPanel.Caption    := inttostr(_uzlet);
    KftmodCombo.ItemIndex := _kftindex;

    Nevedit.Text      := _keszletnev;
    Rovidnevedit.Text := _rovidnev;
    Irodacimedit.Text := _irodacim;
    Boltnevedit.Text  := _boltnev;
    Telefonedit.Text  := _telefon;
    Bankkodedit.Text  := _bankkod;

    _ess := scanetarszam(_aktertektar);
    KorzetModcombo.ItemIndex := _ess;

    if _status='P' then PtarRadio.Checked := true
    else Etarradio.Checked := true;

    if _saturdayclose='X' then saturbox.Checked := true
    else SaturBox.checked := False;

    if _sundayclose='X' then sunbox.Checked := true
    else SunBox.checked := False;

    if _closed='X' then closedbox.checked := true
    else ClosedBox.Checked := False;

    if _vvaltas=1 then Valforgbox.checked := true
    else Valforgbox.checked := False;

    if _wu=1 then wubox.Checked := true else wubox.checked := False;
    if _eker = 'X' then ekerbox.checked := true else ekerbox.checked :=False;
end;


// =============================================================================
                       procedure TForm2.ArtIrodaValtozott;
// =============================================================================

begin
  DatareadOnly(True);
  Gombtakaropanel.Visible := False;
  with ArtQuery do
    begin
      _uzlet         := FieldByName('UZLET').asInteger;
      _keszletnev    := trim(FieldByName('KESZLETNEV').asString);
      _rovidnev      := trim(FieldByName('EXCELNEV').asString);
      _irodacim      := trim(fieldByName('IRODACIM').asString);
      _boltnev       := trim(FieldByNAme('BOLTNEV').asString);
      _telefon       := trim(FieldByNAme('TELEFON').asString);
      _bankkod       := trim(FieldByNAme('BANKKOD').asString);
    //  _saturdayclose := FieldByNAme('SATURDAYCLOSE').asString;
      _closed        := FieldByName('CLOSED').asstring;
   //   _cb            := FieldByNAme('CEGBETU').asString;
      _wu            := FieldByName('WESTERNUNION').asInteger;
      _eker          := trim(FieldByNAme('EKERESKEDELEM').asString);
      _vvaltas       := FieldByName('VALUTAVALTAS').asInteger;
   //  _status        := FieldByName('STATUS').asString;
      _varos         := trim(FieldByNAme('VAROS').asstring);
    end;

      // --------------------------------------------------

    UzletPanel.Caption    := inttostr(_uzlet);
    KftmodCombo.ItemIndex := _kftindex;

    Nevedit.Text      := _keszletnev;
    Rovidnevedit.Text := _rovidnev;
    Irodacimedit.Text := _irodacim;
    Boltnevedit.Text  := _boltnev;
    Telefonedit.Text  := _telefon;
    Bankkodedit.Text  := _bankkod;

    _ess := scanetarszam(_aktertektar);
    KorzetModcombo.ItemIndex := _ess;

    PtarRadio.Checked := true;
    SaturBox.checked  := True;
    SunBox.checked    := True;

    if _closed='X' then closedbox.checked := true
    else ClosedBox.Checked := False;

    if _vvaltas=1 then Valforgbox.checked := true
    else Valforgbox.checked := False;

    if _wu=1 then wubox.Checked := true else wubox.checked := False;
    if _eker = 'X' then ekerbox.checked := true else ekerbox.checked :=False;
end;




// =============================================================================
          procedure TForm2.IRODARACSKeyUp(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  Irodavaltozott;
end;

// =============================================================================
             function TForm2.ScanEtarszam(_etsz: byte): integer;
// =============================================================================

var _z: integer;

begin
  result := -1;
  _z :=0;
  while _z<9 do
    begin
      if _korzetszam[_z]=_etsz then
        begin
          result := _z;
          exit;
        end;
       inc(_z);
    end;
end;


// =============================================================================
           procedure TForm2.ELOIRODABOXClick(Sender: TObject);
// =============================================================================

begin
   KFTcomboCLick(Nil);
end;

// =============================================================================
                procedure TFORM2.DataReadOnly(_tf: boolean);
// =============================================================================

begin
  Nevedit.ReadOnly      := _tf;
  rovidnevedit.ReadOnly := _tf;
  Irodacimedit.ReadOnly := _tf;
  Boltnevedit.ReadOnly  := _tf;
  Telefonedit.readOnly  := _tf;
  Bankkodedit.ReadOnly  := _tf;

  if _tf then _tf := False else _tf := true;

  Ptarradio.Enabled      := _tf;
  Etarradio.Enabled      := _tf;
  Saturbox.Enabled       := _tf;
  Sunbox.Enabled         := _tf;
  ClosedBox.Enabled      := _tf;
  Valforgbox.enabled     := _tf;
  wubox.Enabled          := _tf;
  ekerbox.Enabled        := _tf;
  KorzetModcombo.Enabled := _tf;
end;

// =============================================================================
           procedure TForm2.ADATMODOSITOGOMBClick(Sender: TObject);
// =============================================================================

begin
  DataReadOnly(False);
  with GombtakaroPanel do
    begin
      top := 400;
      Left := 4;
      Visible := true;
      repaint;
    end;
  Activecontrol := Nevedit;
end;

// =============================================================================
             procedure TForm2.MODMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  GombTakaroPanel.visible := False;
  Kftcomboclick(Nil);
end;

// =============================================================================
                procedure TForm2.NEVEDITEnter(Sender: TObject);
// =============================================================================

begin
  if TEdit(Sender).ReadOnly then exit;
  TEdit(sender).Color := clYellow;
end;

// =============================================================================
                procedure TForm2.NEVEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clwindow;
end;

// =============================================================================
         procedure TForm2.NEVEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

var _tag: byte;

begin
  if ord(key)<>13 then exit;

  _aktedit := Tedit(sender);
  _tag := _aktedit.tag;
  if _tag=6 then
    begin
      if _ezujptar then Activecontrol := UpOkeGomb
      else activecontrol := Modokegomb;
      exit;
    end;
  inc(_tag);
  Activecontrol:= _Bedit[_tag];

end;

// =============================================================================
             procedure TForm2.MODOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _keszletnev  := trim(Nevedit.Text);
  _rovidnev    := trim(Rovidnevedit.Text);
  _irodacim    := trim(Irodacimedit.Text);
  _boltnev     := trim(Boltnevedit.Text);
  _telefon     := trim(Telefonedit.Text);
  _bankkod     := trim(Bankkodedit.Text);
  _kindex      := Korzetmodcombo.ItemIndex;
  _aktertektar := _korzetszam[_kindex];
  _kindex      := Scanetarszam(_aktertektar);
  _kftss       := _kftkorzet[_kindex];
  _cb          := _kftbetuk[_kftss];

  _status := 'P';
  IF etarradio.Checked then _status := 'E';

  _wu := 0;
  if wubox.Checked then _wu := 1;

  _vvaltas := 0;
  if valforgbox.Checked then _vvaltas :=1;

  _eker := 'N';
  if ekerbox.Checked then _eker := 'X';

  _saturdayclose := 'N';
  if saturbox.Checked then _saturdayclose := 'X';

  _sundayclose := 'N';
  if sunbox.Checked then _sundayclose := 'X';

  _closed := 'N';
  if closedBox.Checked then _closed := 'X';

  _pcs := 'UPDATE IRODAK SET KESZLETNEV='+chr(39)+_keszletnev+chr(39);
  _pcs := _pcs + ',EXCELNEV='+chr(39)+_rovidnev+chr(39);
  _pcs := _pcs + ',IRODACIM='+chr(39)+_irodacim+chr(39);
  _pcs := _pcs + ',BOLTNEV=' + chr(39) + _boltnev + chr(39);
  _pcs := _pcs + ',TELEFON='+chr(39)+_telefon+chr(39);
  _pcs := _pcs + ',BANKKOD='+chr(39)+_bankkod+chr(39);
  _pcs := _pcs + ',SUNDAYCLOSE='+CHR(39)+_sundayclose+chr(39);
  _pcs := _pcs + ',SATURDAYCLOSE='+chr(39)+_saturdayclose+chr(39);
  _pcs := _pcs + ',CLOSED=' + chr(39)+_closed + chr(39);
  _pcs := _pcs + ',CEGBETU='+chr(39)+_cb+chr(39);
  _pcs := _pcs + ',WESTERNUNION='+inttostr(_wu);
  _pcs := _pcs + ',EKERESKEDELEM='+chr(39)+_eker+chr(39);
  _pcs := _pcs + ',VALUTAVALTAS='+inttostr(_vvaltas);
  _pcs := _pcs + _sorveg;
  _pcs := _pcs + 'WHERE UZLET='+INTTOSTR(_UZLET);

  if _ezexpressz then ArtParancs(_pcs) else Wparancs(_pcs);


  GombTakaroPanel.visible := False;
  Kftcomboclick(Nil);
end;

// =============================================================================
                     procedure TForm2.Wparancs(_ukaz: string);
// =============================================================================

begin
  wdbase.Connected := true;
  if wtranz.InTransaction then wtranz.commit;
  wtranz.StartTransaction;
  with wquery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  wtranz.commit;
  wdbase.close;

end;


// =============================================================================
                     procedure TForm2.ArtParancs(_ukaz: string);
// =============================================================================

begin
  ArtDbase.Connected := true;
  if ArtTranz.InTransaction then ArtTranz.commit;
  ArtTranz.StartTransaction;
  with ArtQuery do
    begin
      close;
      sql.clear;
      sql.add(_ukaz);
      Execsql;
    end;
  ArtTranz.commit;
  ArtDbase.close;
end;



// =============================================================================
             procedure TForm2.UJPENZTARGOMBClick(Sender: TObject);
// =============================================================================

begin
  with IrszamEditPanel do
    begin
      top     := 80;
      left    := 392;
      Visible := true;
      repaint;
    end;
  irodaszamedit.clear;
  Activecontrol :=IrodaszamEdit;
end;

// =============================================================================
              procedure TForm2.IRODASZAMEDITEnter(Sender: TObject);
// =============================================================================

begin
  IrodaszamEdit.Color := clYEllow;
end;

// =============================================================================
     procedure TForm2.IRODASZAMEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _irnums := trim(irodaszamEdit.Text);
  val(_irnums,_ujirodaszam,_code);
  if _code<>0 then _ujirodaszam := 0;
  if (_ujirodaszam<1) or (_ujirodaszam>180) then
    begin
      ShowMessage('Hibás pénztárszám !');
      Irodaszamedit.clear;
      Activecontrol := IrodaszamEdit;
      exit;
    end;

  _irOke := IrodaszamControl(_ujirodaszam);

  if _iroke=-1 then
    begin
      IrodaszamEdit.clear;
      Activecontrol := IrodaszamEdit;
      exit;
    end;

  if _iroke=2 then
    begin
      with KerdezoPanel do
        begin
          Top     := 128;
          left    := 392;
          Visible := true;
          repaint;
        end;
      Activecontrol := IgenGomb;
      exit;
    end;
  UjpenztarFelvetel;
end;

// =============================================================================
           function TForm2.IrodaszamCOntrol(_newnum: byte): integer;
// =============================================================================

begin
  result := -1;

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE UZLET=' + inttostr(_newnum);

  wdbase.connected := true;
  with wQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno=0 then
    begin
      Wquery.close;
      wdbase.close;
      result := 1;
      exit;
    end;

  _closed := Wquery.fieldbyname('CLOSED').asString;
  if _closed='N' then
    begin
      wquery.close;
      wdbase.close;
      Showmessage('ILYEN SZÁMÚ PÉNZTÁR MÁR LÉTEZIK');
      exit;
    end;
  result := 2;
end;

// =============================================================================
                procedure TForm2.IGENGOMBClick(Sender: TObject);
// =============================================================================

begin
  KerdezoPanel.visible := False;
  UjpenztarFelvetel;
end;

// =============================================================================
              procedure TForm2.megsemgombClick(Sender: TObject);
// =============================================================================

begin
  KerdezoPanel.visible := false;
end;

// =============================================================================
            procedure TForm2.megsemujirodagombClick(Sender: TObject);
// =============================================================================

begin
  IrszamEditpanel.Visible := False;
end;

// =============================================================================
                       procedure TForm2.UJpenztarFelvetel;
// =============================================================================

begin
  with UjPenztarTakaroPanel do
    begin
      top := 464;
      left := 392;
      Visible := true;
      repaint;
    end;
  _ezUjptar               := True;
  UzletPanel.Caption      := inttostr(_ujirodaszam);
  IrszamEditPanel.Visible := False;
  KftModcombo.ItemIndex   := 0;
  _y := 1;
  while _y<=6 do
    begin
      _bedit[_y].clear;
      inc(_y);
    end;

  Ptarradio.Checked  := True;
  Saturbox.checked   := False;
  Sunbox.Checked     := False;
  closedBox.Checked  := False;
  Valforgbox.Checked := True;
  Wubox.Checked      := False;
  Ekerbox.Checked    := False;

  DataReadOnly(False);
  Activecontrol := Nevedit;
END;

// =============================================================================
               procedure TForm2.UPMEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  _ezUjptar := false;
  UjpenztarTakaropanel.visible := False;
  KFTcomboclick(Nil);
end;

// =============================================================================
               procedure TForm2.UPOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _keszletnev := trim(Nevedit.Text);
  _rovidnev := trim(Rovidnevedit.Text);
  _irodacim := trim(Irodacimedit.Text);

  if (_keszletnev='') then
     begin
       activecontrol := Nevedit;
       exit;
     end;


  _boltnev     := trim(Boltnevedit.Text);
  _telefon     := trim(Telefonedit.Text);
  _bankkod     := trim(Bankkodedit.Text);
  _kindex      := Korzetmodcombo.ItemIndex;
  _aktertektar := _korzetszam[_kindex];
  _kindex      := Scanetarszam(_aktertektar);
  _kftss       := _kftkorzet[_kindex];
  _cb          := _kftbetuk[_kftss];

  _status := 'P';
  IF etarradio.Checked then _status := 'E';

  _wu := 0;
  if wubox.Checked then _wu := 1;

  _vvaltas := 0;
  if valforgbox.Checked then _vvaltas :=1;

  _eker := 'N';
  if ekerbox.Checked then _eker := 'X';

  _saturdayclose := 'N';
  if saturbox.Checked then _saturdayclose := 'X';

  _sundayclose := 'N';
  if sunbox.Checked then _sundayclose := 'X';

  _closed := 'N';
  if closedBox.Checked then _closed := 'X';

  _varos := getvaros(_keszletnev);

  _pcs := 'INSERT INTO IRODAK (UZLET,KESZLETNEV,EXCELNEV,IRODACIM,BOLTNEV,TELEFON,';
  _pcs := _pcs + 'BANKKOD,VAROS,STATUS,SUNDAYCLOSE,SATURDAYCLOSE,CLOSED,CEGBETU,';
  _pcs := _pcs + 'WESTERNUNION,EKERESKEDELEM,VALUTAVALTAS,ERTEKTAR)' + _sorveg;

  _pcs := _pcs + 'VALUES (' + inttostr(_ujirodaszam)+',';
  _pcs := _pcs + chr(39) + _keszletnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _rovidnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _irodacim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _boltnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _telefon + chr(39) + ',';
  _pcs := _pcs + chr(39) + _bankkod + chr(39) + ',';
  _pcs := _pcs + chr(39) + _varos + chr(39) + ',';
  _pcs := _pcs + chr(39) + _status + chr(39) + ',';
  _pcs := _pcs + chr(39) + _sundayclose + chr(39) + ',';
  _pcs := _pcs + chr(39) + _saturdayclose + chr(39) + ',';
  _pcs := _pcs + chr(39) + _closed + chr(39) + ',';
  _pcs := _pcs + chr(39) + _cb + chr(39) + ',';
  _pcs := _pcs + inttostr(_wu) + ',';
  _pcs := _pcs + chr(39) + _eker + chr(39) + ',';
  _pcs := _pcs + inttostr(_vvaltas) + ',';
  _pcs := _pcs + inttostr(_aktertektar) + ')';
  WParancs(_pcs);

  Adatbaziskrealas;
  MakeMainCurr;
  MakeElohavi;
  MakeElonapi;
  UjpenztarTakaroPanel.Visible := False;
  Modalresult := 1;
end;

// =============================================================================
                       procedure TForm2.AdatBazisKrealas;
// =============================================================================

begin
  _adatbazisnev := 'V' + inttostr(_ujirodaszam)+'.FDB';
  _adatBazisPath := _host + ':c:\receptor\database\' + _adatbazisnev;

  if not fileexists(_adatbazispath) then
    begin
      ujdatabase := TibDatabase.Create(Nil);
      with ujdatabase do
        begin
          Connected := False;
          DataBaseName := _adatBazisPath;
          Params.add('USER ''SYSDBA''PASSWORD ''dek@nySo''');
          Params.add('DEFAULT CHARACTER SET WIN1250');
          SqlDialect := 3;
          LoginPrompt := False;
          CreateDatabase;
        end;
    end;
end;

// =============================================================================
                           procedure TForm2.MakeMainCurr;
// =============================================================================

begin
  with UjDbase do
    begin
      Close;
      DatabaseName := _adatbazisPath;
      Connected := True;
    end;

  Ujtabla.close;
  Ujtabla.TableName := 'MAINCURR';
  If Ujtabla.exists then
    begin
      Ujdbase.close;
      exit;
    end;
  if ujTranz.Intransaction then ujTranz.Commit;
  ujTranz.startTransaction;

  _pcs := 'CREATE TABLE MAINCURR ('+_sorveg;
  _pcs := _pcs + 'EV SMALLINT,' + _sorveg;
  _pcs := _pcs + 'HONAP SMALLINT,' + _sorveg;
  _pcs := _pcs + 'VCHF INTEGER,' + _sorveg;
  _pcs := _pcs + 'ECHF INTEGER,' + _sorveg;
  _pcs := _pcs + 'VEUR INTEGER,' + _sorveg;
  _pcs := _pcs + 'EEUR INTEGER,' + _sorveg;
  _pcs := _pcs + 'VHRK INTEGER,' + _sorveg;
  _pcs := _pcs + 'EHRK INTEGER,' + _sorveg;
  _pcs := _pcs + 'VGBP INTEGER,' + _sorveg;
  _pcs := _pcs + 'EGBP INTEGER,' + _sorveg;
  _pcs := _pcs + 'VUSD INTEGER,' + _sorveg;
  _pcs := _pcs + 'EUSD INTEGER,' + _sorveg;
  _pcs := _pcs + 'VRON INTEGER,' + _sorveg;
  _pcs := _pcs + 'ERON INTEGER)';

  with Ujquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  Ujtranz.commit;
  Ujdbase.close;
end;

// =============================================================================
                        procedure TForm2.MakeElohavi;
// =============================================================================

begin
  Ujdbase.close;
  Ujdbase.databaseName := _adatbazisPath;
  Ujdbase.connected := True;

  Ujtabla.close;
  Ujtabla.tablename := 'ELOHAVI';
  If Ujtabla.exists then
    begin
      Ujdbase.close;
      exit;
    end;
  if ujtranz.intransaction then ujtranz.commit;
  Ujtranz.startTransaction;

  _pcs := 'CREATE TABLE ELOHAVI (' + _sorveg;
  _pcs := _pcs + 'EVHOSTRING CHAR (6) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'NAPOK INTEGER,' + _sorveg;
  _pcs := _pcs + 'VETEL DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'ELADAS DOUBLE PRECISION,' + _sorveg;
  _pcs := _pcs + 'VETELUGYFELDARAB INTEGER,' + _sorveg;
  _pcs := _pcs + 'ELADASUGYFELDARAB INTEGER)';

  with Ujquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;
  Ujtranz.commit;
  Ujdbase.close;
end;

// =============================================================================
                           procedure TForm2.MakeElonapi;
// =============================================================================

begin
  Ujdbase.close;
  Ujdbase.databaseName := _adatbazisPath;
  Ujdbase.connected := True;

  Ujtabla.close;
  Ujtabla.tablename := 'ELONAPI';
  If Ujtabla.exists then
    begin
      Ujdbase.close;
      exit;
    end;
  if ujtranz.intransaction then ujtranz.commit;
  Ujtranz.startTransaction;

  _pcs := 'CREATE TABLE ELONAPI (' + _sorveg;
  _pcs := _pcs + 'DATUM CHAR (10) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3) CHARACTER SET WIN1250 COLLATE WIN1250,' + _sorveg;
  _pcs := _pcs + 'OSSZESEN DOUBLE PRECISION)';

  with Ujquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Execsql;
    end;

  Ujtranz.commit;
  Ujdbase.close;
end;

// =============================================================================
              procedure TForm2.KORZETMODCOMBOClick(Sender: TObject);
// =============================================================================

begin
  _kindex := KorzetModCombo.ItemIndex;
  _kindex := _Kftkorzet[_kindex];
  KftModCombo.ItemIndex := _kindex;
end;

// =============================================================================
                function TForm2.Getvaros(_nn: string): string;
// =============================================================================

var _ww,_asc,_y: byte;

begin
  result := '';
  _nn    := trim(_nn);
  _ww    := length(_nn);

  _y := 1;
  while _y<=_ww do
    begin
      _asc := ord(_nn[_y]);
      if _asc=32 then break;
      result := result + chr(_asc);
      inc(_y);
    end;
end;

//procedure TForm2.Parancs(_ukaz: string);

//begin





end.
