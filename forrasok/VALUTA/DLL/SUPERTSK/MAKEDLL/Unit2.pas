unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, DB, Grids, DBGrids, ExtCtrls, DBTables,
  IBDatabase, IBCustomDataSet, IBTable, DateUtils, sTRuTILS, IBQuery;

type
  TSUPERVISORFORM = class(TForm)
    Panel1: TPanel;
    Shape1: TShape;
    Label2: TLabel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    XTRANZGOMB: TBitBtn;
    Shape2: TShape;
    checklistgomb: TBitBtn;
    BitBtn4: TBitBtn;
    SZUNETPANEL: TPanel;
    IBRACS: TDBGrid;
    VISSZAGOMB: TBitBtn;
    Label1: TLabel;
    ibdbase: TIBDatabase;
    IBTRANZ: TIBTransaction;
    IBSOURCE: TDataSource;
    IBTABLA: TIBTable;
    IBQuery: TIBQuery;
    BitBtn5: TBitBtn;
    
    procedure FormActivate(Sender: TObject);
    procedure ESCAPEGOMBClick(Sender: TObject);
    procedure NYITOGOMBEnter(Sender: TObject);
    procedure NYITOGOMBExit(Sender: TObject);

    procedure CIMLETSETUPGOMBClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure XTRANZGOMBClick(Sender: TObject);
    procedure checklistgombClick(Sender: TObject);
    procedure VISSZAGOMBClick(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure AlapadatBeolvasas;
    procedure ValutaParancs(_ukaz: string);
    procedure BitBtn5Click(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SUPERVISORFORM: TSUPERVISORFORM;
  _top,_left,_width,_height: word;
  _megnyitottnap,_szDatum,_sEvs,_pcs: string;


function extratranzdijdisp: integer; stdcall; external 'c:\valuta\bin\xtranz.dll' name 'extratranzdijdisp';
function cimletbeallito: integer; stdcall; external 'c:\valuta\bin\cimsetup.dll' name 'cimletbeallito';
function checkcontrol(_para: integer): integer; stdcall; external 'c:\valuta\bin\checklst.dll' name 'checkcontrol';
function logdisplayrutin: integer; stdcall; external 'c:\valuta\bin\logdisp.dll' name 'logdisplayrutin';
function otpterminallog: integer; stdcall; external 'c:\valuta\bin\otplog.dll' name 'otpterminallog'

function supervisorrutin: integer; stdcall;


implementation

function supervisorrutin: integer; stdcall;
begin
  supervisorForm := TsupervisorForm.create(Nil);
  result := supervisorForm.showmodal;
  SupervisorForm.Free;
end;  


{$R *.dfm}

// =============================================================================
              procedure TSUPERVISORFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top    := round((_height-768)/2);
  _left   := round((_width-1024)/2);


  Top     := _Top + 160;
  Left    := _Left + 350;
  Width   := 609;
  Height  := 417;

  AlapadatBeolvasas;

  SzunetPanel.Visible := false;
 
  Activecontrol := xtranzGomb;
end;


procedure TSUPERVISORFORM.AlapadatBeolvasas;

begin
  ibdbase.connected := true;
  with Ibquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := trim(FieldByName('MEGNYITOTTNAP').asString);
      Close;
    end;
  Ibdbase.close;
end;



// =============================================================================
         procedure TSUPERVISORFORM.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := 1;
end;

// =============================================================================
            procedure TSUPERVISORFORM.NYITOGOMBEnter(Sender: TObject);
// =============================================================================

begin
  with Tbitbtn(sender).Font do
    begin
      Color := clRed;
      Style := [fsBold];
    end;
end;

// =============================================================================
            procedure TSUPERVISORFORM.NYITOGOMBExit(Sender: TObject);
// =============================================================================

begin
  with TBitbtn(Sender).Font do
    begin
      Color := clGray;
      Style := [];
    end;  
end;



// =============================================================================
        procedure TSUPERVISORFORM.CIMLETSETUPGOMBClick(Sender: TObject);
// =============================================================================

begin
  cimletbeallito;
end;

// =============================================================================
            procedure TSUPERVISORFORM.FormCreate(Sender: TObject);
// =============================================================================

begin
  Top := _Top + 260;
  Left := _Left + 350;
  Width := 410;
  Height := 350;
end;



(*
// =============================================================================
          procedure TSUPERVISORFORM.STORNOGOMBClick(Sender: TObject);
// =============================================================================

var i: integer;

begin
  Top := 60+_top;
  Left := 130+_left;

  width := 765;
  Height := 645;

  _aktev := yearof(Date);
  _aktho := monthof(Date);

  EvCombo.Clear;
  Hocombo.Clear;

  for i := -2 to 0 do Evcombo.Items.Add(inttostr(_aktev+i));
  for i := 1 to 12 do Hocombo.Items.add(_honapnev[i]);

  evcombo.ItemIndex := 2;
  Hocombo.ItemIndex := _aktho-1;

  Fejracs.Visible := False;
  TetRacs.Visible := False;

  DatumOkeGomb.Visible := True;
  Megsemgomb.Visible := True;
  evcombo.Visible := True;
  Hocombo.Visible := True;

  with StornoPanel do
    begin
      Top := 5;
      Left := 5;
      Visible := True;
    end;
  DatumOkeGomb.Enabled := True;
  ActiveControl := DatumOkegomb;

end;



// =============================================================================
         procedure TSUPERVISORFORM.DATUMOKEGOMBClick(Sender: TObject);
// =============================================================================

var _kerev,_kerho: integer;
    _bfTabla,_btTabla: string;

begin
  DatumOkeGomb.Visible := false;
  Megsemgomb.Visible := false;
  evcombo.Visible := false;
  Hocombo.Visible := false;

  _kerev := (_aktev -2) + Evcombo.Itemindex;
  _kerho := 1+HOcombo.Itemindex;
  _farok := Form1.Nulele(_kerev-2000,2)+Form1.Nulele(_kerho,2);

  _bftabla := 'BF'+_farok;
  _btTabla := 'BT'+_farok;

  BfTabla.close;
  BFTabla.TableName := _bfTabla;
  if not Bftabla.Exists then
    begin
   
      ActiveControl := megsemgomb;
      exit;
    end;
  BtTabla.Close;
  BtTabla.TableName := _btTabla;

  BfDbase.Close;
  BfDbase.Connected := true;
  BFTabla.Open; //*
  BFTabla.Refresh;

  BfTabla.Filter := 'STORNO=2';
  Bftabla.Filtered := True;
  BfTabla.First;

  BtDbase.close;
  BtDbase.Connected := True;
  with BtTabla do
    BEGIN
      IndexFieldNames := 'BIZONYLATSZAM';
      Open;   //*
      Refresh;
      Mastersource := Fejsource;
      MasterFields := 'BIZONYLATSZAM';
    end;

  Tetracs.Visible := true;
  FejRacs.Visible := true;
  ActiveControl := FejRacs;
  Fejracs.SetFocus;
end;

// =============================================================================
          procedure TSUPERVISORFORM.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  BfTabla.Close;
  BtTabla.Close;
  StornoPanel.Visible := False;
  Top := _Top + 260;
  Left := _Left + 350;
  Width := 410;
  Height := 350;
  ActiveControl := Stornogomb;
end;



// =============================================================================
          procedure TSUPERVISORFORM.DATUMOKEGOMBEnter(Sender: TObject);
// =============================================================================

begin
  TBitbtn(sender).Font.Color := clBlue;
end;

// =============================================================================
         procedure TSUPERVISORFORM.DATUMOKEGOMBExit(Sender: TObject);
// =============================================================================

begin
  TBitbtn(Sender).Font.Color := clGray;
end;



// =============================================================================
           procedure TSUPERVISORFORM.EVKOMBOChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := HonapOkeGomb;
end;




// =============================================================================
         procedure TSUPERVISORFORM.LOGFILEBACKClick(Sender: TObject);
// =============================================================================

begin
  LogfilePanel.Visible := False;

  Activecontrol := xtranzGomb;
end;




*)


procedure TSUPERVISORFORM.XTRANZGOMBClick(Sender: TObject);
begin
  Visible := false;
  extratranzdijdisp;
  Visible := true;
end;


procedure TSUPERVISORFORM.checklistgombClick(Sender: TObject);
begin
  checkcontrol(1);
end;

procedure TSUPERVISORFORM.VISSZAGOMBClick(Sender: TObject);
begin
  ibtabla.close;
  ibdbase.close;
  Szunetpanel.Visible := False;
end;

procedure TSUPERVISORFORM.BitBtn4Click(Sender: TObject);

var _idens: string;

begin
  _idens := leftstr(_megnyitottnap,4);
  _pcs := 'DELETE FROM PAUSES WHERE (DATUM='+chr(39)+CHR(39)+') OR (';
  _pcs := _pcs + 'DATUM<' + chr(39) + _idens + chr(39) + ')';
  ValutaParancs(_pcs);

  ibdbase.connected := true;
  ibtabla.close;
  ibtabla.TableName := 'PAUSES';
  ibtabla.IndexFieldNames := 'DATUM;TOL';
  ibtabla.Open;
  ibtabla.first;

  with SzunetPanel do
    begin
      top  := 8;
      Left := 8;
      Visible := true;
    end;
  Activecontrol := IBRACS;
  Ibracs.SetFocus;
end;


procedure TSUPERVISORFORM.BitBtn1Click(Sender: TObject);
begin
  logdisplayrutin;
end;

procedure TSUPERVISORFORM.ValutaParancs(_ukaz: string);

begin
  ibdbase.connected := true;
  if ibtranz.InTransaction then ibtranz.Commit;
  ibtranz.StartTransaction;
  with ibquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ibtranz.commit;
  ibdbase.close;
end;

procedure TSUPERVISORFORM.BitBtn5Click(Sender: TObject);
begin
  otpterminallog;
end;

end.
