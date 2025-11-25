unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, DBGrids, ExtCtrls, unit1, strutils;

type
  TKONTROLFORM = class(TForm)
    Button1: TButton;
    NAGYFUGGONY: TPanel;
    KISFUGGONY: TPanel;
    STARTPANEL: TPanel;
    PENZTARCOMBO: TComboBox;
    EVCOMBO: TComboBox;
    HONAPCOMBO: TComboBox;
    ESCAPEGOMB: TPanel;
    ARFEPANEL: TPanel;
    ENGPANEL: TPanel;
    NAPHOPANEL: TPanel;
    ENGVALPANEL: TPanel;
    VALVALPANEL: TPanel;
    TRANZVALPANEL: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    ARFERACS: TDBGrid;
    ENGRACS: TDBGrid;
    FOCIMPANEL: TPanel;
    PENZTARPANEL: TPanel;
    DATUMPANEL: TPanel;
    TENYPANEL: TPanel;
    PERMPANEL: TPanel;
    BARFPANEL: TPanel;
    BKDIJPANEL: TPanel;
    JARFPANEL: TPanel;
    JKDIJPANEL: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure Button1Click(Sender: TObject);
       procedure FormActivate(Sender: TObject);
    procedure IrodakBetoltese;
    function Nul3(_b: byte):string;
    procedure PENZTARCOMBOChange(Sender: TObject);
    procedure StartGombClick(Sender: TObject);
    procedure IndatumTomb(_d: string);
    procedure InDnemTomb(_d: string);

    procedure NAPCOMBOChange(Sender: TObject);
    procedure EGYNAPRADIOClick(Sender: TObject);
    procedure TOTHORADIOClick(Sender: TObject);
    procedure OSSZESRADIOClick(Sender: TObject);
    procedure FILTERRADIOClick(Sender: TObject);
    procedure OSSZVALRADIOClick(Sender: TObject);
    procedure OSSZTRANZRADIOClick(Sender: TObject);

    procedure JobbRacsOpen;
    function BalracsOpen: boolean;
    procedure EGYVALRADIOClick(Sender: TObject);
    procedure DNEMCOMBOChange(Sender: TObject);
    procedure EGYTRANZRADIOClick(Sender: TObject);
    procedure TRANZCOMBOChange(Sender: TObject);
    procedure ERADIOClick(Sender: TObject);
    procedure URADIOClick(Sender: TObject);
    procedure FRADIOClick(Sender: TObject);
    procedure JRADIOClick(Sender: TObject);
    procedure ONLYFEERADIOClick(Sender: TObject);
    procedure FELEZESRADIOClick(Sender: TObject);
    procedure ELENGEDESRADIOClick(Sender: TObject);
    procedure CSOKKENTESRADIOClick(Sender: TObject);
    procedure ONLYRATERADIOClick(Sender: TObject);
    procedure Dekodolas(_k: word);
    procedure PermitChange;
    procedure ARFERACSCellClick(Column: TColumn);

    procedure ARFERACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ENGRACSKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure STARTGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ESCAPEGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure STARTPANELMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ENGRACSCellClick(Column: TColumn);
    procedure SAVOSRADIOClick(Sender: TObject);
    procedure SHKRADIOClick(Sender: TObject);
    procedure VIPRADIOClick(Sender: TObject);





  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KONTROLFORM: TKONTROLFORM;
  _szerver: string = '185.43.207.99:';

  _qPenztar: integer;
  _qtranz,_qFilter,_qDnemFilter,_tranzFilter,_engFdbPath: string;

  _engtablanev,_arfeTablanev,_kertpenztar,_aktfdbPath,_qDatums,_qdnem: string;
  _engFilter,_arfeFilter,_dnemFilter,_dekarf,_dekkezd: string;

  _ptIndex,_kertpenztarnum,_recno,_tix: integer;

  _datTomb  : array[1..31] of string;
  _qdnemTomb: array[1..23] of string;

  _datumdarab,_qdnemdarab: byte;
  _kerthonap,_permitkod,_aktev: word;

  _egyNap,_egyDnem,_egyTranz,_vanFilter,_vanpermit: boolean;
  _lobyte,_hibyte,_pkod,_hib,_lob,_ktop,_kleft: WORD;





implementation

{$R *.dfm}

procedure TKONTROLFORM.Button1Click(Sender: TObject);
begin
  mODALRESULT := 1;
end;


// =============================================================================
             procedure TKONTROLFORM.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _ktop := trunc((_height-768)/2);
  _kLeft := trunc((_width-1024)/2);
  Top  := _ktop;
  Left := _kleft;
  Height := 768;
  Width := 1024;

  Focimpanel.Visible    := False;
  NapHoPanel.Visible    := False;
  EngValPanel.Visible   := False;
  TranzValPanel.Visible := False;
  ValvalPanel.Visible   := False;

  TenyPanel.Visible := False;
  PermPanel.Visible := False;

  _egynap   := False;
  _egyTranz := False;
  _egydnem  := False;
  _vanPermit:= False;

  with Kisfuggony do
    begin
      Top := 632;
      Left := 8;
      Visible := true;
    end;

  with NagyFuggony do
    begin
      Top := 140;
      Left := 8;
      Visible := true;
    end;

  _datumdarab := 0;
  _qDNemDarab := 0;
  _permitkod  := 0;

  _aktev := strtoint(leftstr(_megnyitottnap,4));
  _aktho := strtoint(midstr(_megnyitottnap,6,2));

  IrodakBetoltese;

  Evcombo.Items.Clear;
  evcombo.Items.Add(inttostr(_aktev-1));
  evcombo.Items.add(inttostr(_aktev));
  Evcombo.ItemIndex := 1;

  HonapCombo.Items.clear;

  i := 1;
  while i<=12 do
    begin
      Honapcombo.Items.add(_honapnev[i]);
      inc(i);
    end;

  Honapcombo.ItemIndex := _aktho-1;

  // ----------------------------------------

  Tranzcombo.Items.clear;
  Tranzcombo.Items.add('   V…TEL   ');
  Tranzcombo.Items.add('  ELAD¡S   ');
  Tranzcombo.Items.add(' KONVERZI” ');
  TranzCombo.ItemIndex := 0;

  // -----------------------------------------

  with startPanel do
    begin
      Top := 60;
      Left := 240;
      Visible := true;
    end;
  Penztarcombo.ItemIndex := 0;

//  Activecontrol := StartGomb;
  StartGombclick(Nil);

end;

// =============================================================================
                 procedure TKontrolForm.IrodakBetoltese;
// =============================================================================

var _ptarnum: integer;
    _aktpnev,_pcombonev,_closed: string;

begin

  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'WHERE (STATUS=' + chr(39)+ 'P' + CHR(39) + ') AND (';
  _pcs := _pcs + 'ERTEKTAR=' +inttostr(_ertektar) + ')' + _sorveg;
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

  while not Recquery.eof do
    begin
      _closed  := trim(Recquery.FieldByName('CLOSED').asString);
      if _closed<>'X' then
        begin
          _ptarnum := RecQuery.FieldByName('UZLET').asInteger;
          _aktpnev := trim(Recquery.FieldByname('KESZLETNEV').asString);
          _pcombonev := nul3(_ptarnum)+'. '+_aktpnev;
          PenztarCombo.Items.Add(_pcombonev);
        end;

      Recquery.next;
    end;
  Recquery.close;
  Recdbase.close;
  Penztarcombo.ItemIndex := 0;

end;

// =============================================================================
                function TKontrolForm.Nul3(_b: byte):string;
// =============================================================================

begin
  result := inttostr(_b);
  while length(result)<3 do result := '0' + result;
end;


// =============================================================================
         procedure TKONTROLFORM.PENZTARCOMBOChange(Sender: TObject);
// =============================================================================

begin
  StartGombClick(Nil);
end;

// =============================================================================
            procedure TKONTROLFORM.StartGombClick(Sender: TObject);
// =============================================================================

var _y: byte;

begin
  _kerthonap := 1 + HonapCombo.itemindex;
  _kertev := _aktev-1+Evcombo.itemindex;
  _farok := inttostr(_kertev-2000)+Form1.nulele(_kerthonap,2);

  _ptIndex := PenztarCombo.Itemindex;
  _kertPenztar := PenztarCombo.Items[_ptIndex];
  _kertPenztarNum := Strtoint(leftstr(_kertpenztar,3));
  _aktfdbPath := _szerver+'c:\receptor\database\v'+inttostr(_kertpenztarnum)+'.FDB';

  _arfeTablanev := 'ARFE' + _farok;
  ArfeDbase.close;
  Arfedbase.DatabaseName := _aktfdbpath;
  ArfeDbase.Connected := true;
  ArfeTabla.close;
  arfeTabla.TableName := _arfetablanev;
  if not Arfetabla.Exists then
    begin
      Arfedbase.close;
      ShowMessage('NINCS ADAT A K…RT H”NAPR”L');
      ActiveControl := EscapeGomb;
      exit;
    end;

   {
  PenztarPanel.Caption := _kertpenztar;
  DatumPanel.Caption := inttostr(_kertev)+' '+ _honapnev[_kerthonap];
  Datumpanel.Repaint;
  with Focimpanel do
    begin
      Top := 60;
      Left := 210;
      Visible := True;
    end;
  }

  ArfeSource.Enabled := False;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM '+ _arfeTablaNev + _sorveg;
  _pcs := _pcs + 'WHERE ENGEDMENYTIPUS>8' + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  with ArfeQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ArfeQuery.eof do
    begin
      _qDatums := ArfeQuery.FieldByname('DATUM').asString;
      _qDnem   := ArfeQuery.FieldByName('VALUTANEM').asString;
      InDatumTomb(_qdatums);
      IndnemTomb(_qDnem);
      ArfeQuery.next;
    end;

  Napcombo.Items.Clear;
  _y := 1;
  while _y<=_datumDarab do
    begin
      Napcombo.Items.Add(_dattomb[_y]);
      inc(_y);
    end;
  Napcombo.ItemIndex := 0;

  // -----------------------------------------------------------

  DNemCombo.Items.Clear;
  _y := 1;
  while _y<=_qDnemDarab do
    begin
      DnemCombo.Items.Add(_qdnemtomb[_y]);
      inc(_y);
    end;
  Dnemcombo.ItemIndex := 0;

  // -------------------------------------------------------------

  ArfeQuery.First;
  ArfeSource.Enabled := True;

  // ----------------------------------------------

  if not BalracsOpen then exit;

  JobbRacsOpen;

  // --------------------------------------------------------------------------

  TothoRadio.Checked     := True;
  OsszesRadio.Checked    := true;
  OsszValRadio.Checked   := True;
  OsszTranzRadio.Checked := True;

  with NapHopanel do
    begin
      Top := 576;
      Left := 10;
      Visible := true;
    end;

  with Engvalpanel do
    begin
      Top := 576;
      Left := 496;
      Visible := True;
    end;

  with ValValPanel do
    begin
      Top := 606;
      Left := 10;
      Visible := true;
    end;

  with TranzValPanel do
    begin
      Top := 606;
      Left := 488;
      Visible := true;
    end;

  Nagyfuggony.Visible := False;
  Engsource.Enabled   := True;
  Activecontrol := ArfeRacs;

end;

// =============================================================================
             procedure TKontrolForm.IndatumTomb(_d: string);
// =============================================================================

var _y: byte;

begin
  if _datumdarab=0 then
    begin
      _datTomb[1] := _d;
      _datumdarab := 1;
      exit;
    end;

  _y := 1;
  while _y<=_datumdarab do
    begin
      if _datTomb[_y]=_d then exit;
      inc(_y);
    end;

  inc(_datumdarab);
  _datTomb[_datumdarab] := _d;
end;

// =============================================================================
               procedure TKontrolForm.InDnemTomb(_d: string);
// =============================================================================

var _y: byte;

begin
  if _qdnemdarab=0 then
    begin
      _qdnemTomb[1] := _d;
      _qdnemdarab := 1;
      exit;
    end;

  _y := 1;
  while _y<=_qdnemdarab do
    begin
      if _qdnemTomb[_y]=_d then exit;
      inc(_y);
    end;

  inc(_qdNemdarab);
  _qdnemTomb[_qdnemdarab] := _d;
end;


// =============================================================================
           procedure TKONTROLFORM.NAPCOMBOChange(Sender: TObject);
// =============================================================================

var _nix: integer;

begin
  _nix := Napcombo.itemindex;
  _qdatums := Napcombo.Items[_nix];
  _egynap := True;

  _pcs := 'SELECT * FROM ' + _arfeTablanev + _sorveg;
  _pcs := _pcs +'WHERE (ENGEDMENYTIPUS>8) AND (DATUM='+chr(39)+_qdatums+chr(39)+')';
  with ArfeQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _pcs := 'SELECT * FROM '+ _engtablanev + _sorveg;
  _pcs := _pcs + 'WHERE DATUM='+chr(39)+_qdatums+chr(39);
  with engquery do
   begin
     Close;
     sql.Clear;
     sql.Add(_pcs);
     Open;
     first;
   end;
 Activecontrol := Arferacs;


end;

// =============================================================================
         procedure TKONTROLFORM.EGYNAPRADIOClick(Sender: TObject);
// =============================================================================

begin
  Napcombo.ItemIndex := 0;
  NapCombo.Visible := true;
  Activecontrol := Napcombo;
end;

// =============================================================================
          procedure TKONTROLFORM.TOTHORADIOClick(Sender: TObject);
// =============================================================================

begin
  Napcombo.Visible := false;
  if _egynap then
    begin
      _egynap := False;
      Balracsopen;
      Jobbracsopen;
    end;  
  Activecontrol := ArfeRacs;
end;

// =============================================================================
       procedure TKONTROLFORM.OSSZESRADIOClick(Sender: TObject);
// =============================================================================

begin

  with Kisfuggony do
    begin
      top := 632;
      Left := 8;
      Visible := True;
    end;
  _vanPermit := False;
  _permitKod := 0;
  BalRacsOpen;
  JobbracsOpen;
  ActiveControl := Arferacs;
end;

// =============================================================================
          procedure TKONTROLFORM.FILTERRADIOClick(Sender: TObject);
// =============================================================================

begin
  ERadio.checked := False;
  FRadio.checked := False;
  URadio.checked := False;
  JRadio.checked := False;

  Onlyfeeradio.Checked  := False;
  OnlyrateRadio.Checked := False;

  FelezesRadio.Checked   := False;
  ElengedesRadio.Checked := False;
  CsokkentesRadio.Checked:= False;

  _loByte := 0;
  _hiByte := 0;

  Kisfuggony.visible := False;
end;

// =============================================================================
        procedure TKONTROLFORM.OSSZVALRADIOClick(Sender: TObject);
// =============================================================================

begin
  Dnemcombo.Visible := false;
  if _egydnem then
    begin
      _egydnem := False;
      Balracsopen;
      Jobbracsopen;
    end;
  Activecontrol := ArfeRacs;
end;



// =============================================================================
                procedure TKontrolForm.JobbRacsOpen;
// =============================================================================


begin
  _engtablanev := 'ENG' + _farok;
  EngSource.enabled := False;

  _engfilter := '(PENZTAR=' + inttostr(_qPenztar)+')';

  if _egynap then _engfilter := _engFilter + ' AND (DATUM='+chr(39)+_qDatums+chr(39)+')';
  if _egydnem then _engfilter := _engFilter + ' AND (VALUTANEM='+chr(39)+_qdnem+chr(39)+')';
  if _egyTranz then _engFilter := _engFilter + ' AND (TRANZAKCIO='+chr(39)+_qTranz+chr(39)+')';
  if _vanPermit then _engfilter := _engfilter + ' AND (PERMITTYPE='+inttostr(_permitKod)+')';

  _pcs := 'SELECT * FROM ' + _engtablanev + _sorveg;
  _pcs := _pcs + 'WHERE ' + _engfilter + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  _engFdbPath := _szerver + 'c:\receptor\database\rateperm.fdb';
  Engsource.Enabled := False;
  EngDbase.close;
  Engdbase.DatabaseName := _engFdbPath;
  EngDbase.Connected := true;
  with EngQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
      _recno := Recno;
    end;
  if _recno>0 then
    begin
      _pkod := EngQuery.fieldbyname('PERMITTYPE').asInteger;
      Dekodolas(_pkod);
    end else
    begin
      _dekarf := '-';
      _dekkezd := '-';
    end;

  PermPanel.Visible := True;
  Jarfpanel.Caption  := _dekarf;
  JkdijPanel.Caption := _dekkezd;

  Engsource.Enabled := true;
end;


// =============================================================================
            function TKontrolForm.BalRacsOpen: boolean;
// =============================================================================


begin

  result          := False;

  _ptIndex     := PenztarCombo.Itemindex;
  _kertPenztar := PenztarCombo.Items[_ptIndex];
  _qPenztar    := Strtoint(leftstr(_kertpenztar,3));
  _aktfdbPath  := _szerver+'c:\receptor\database\v'+inttostr(_qpenztar)+'.FDB';

  _arfeTablanev := 'ARFE' + _farok;

  ArfeDbase.close;
  ArfeDbase.DatabaseName := _aktfdbpath;
  ArfeDbase.Connected := true;

  ArfeTabla.close;
  arfeTabla.TableName := _arfetablanev;
  if not Arfetabla.Exists then
    begin
      Arfedbase.close;
      ShowMessage('NINCS ADAT A K…RT H”NAPR”L');
      exit;
    end;

  _arfeFilter := '';
  _dnemFilter := '';
  _tranzFilter:= '';

  _arfefilter := '(ENGEDMENYTIPUS>8)';
  if _vanPermit then _arfefilter := '(ENGEDMENYTIPUS='+inttostr(_permitKod)+')';

  if _egynap then
       _arfeFilter := _arfefilter + ' AND (DATUM='+chr(39)+_qDatums+chr(39)+')';
  if _egydnem then
       _arfefilter := _arfefilter + ' AND (VALUTANEM='+chr(39)+_qdnem+chr(39)+')';
  if _egyTranz then
       _arfeFilter := _arfefilter + ' AND (BIZONYLATSZAM LIKE '+chr(39)+_qTranz+'%'+ chr(39)+')';

  _pcs := 'SELECT * FROM ' + _arfetablanev + _sorveg;
  _pcs := _pcs + 'WHERE ' + _arfefilter + _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  ArfeSource.Enabled := False;
  ArfeDbase.Connected := true;
  with ArfeQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  if _recno>0 then
    begin
      _pkod := ArfeQuery.Fieldbyname('ENGEDMENYTIPUS').asInteger;
      Dekodolas(_pkod);
    end else
    begin
      _dekarf := '-';
      _dekkezd := '-';
    end;

  if not tenyPanel.Visible then
    begin
      with Tenypanel do
        begin
          Top := 48;
          Left := 24;
          Visible := true;
        end;
    end;

  Barfpanel.Caption  := _dekarf;
  BkdijPanel.Caption := _dekkezd;

  Arfesource.Enabled := true;
  Result := true;
end;  

// =============================================================================
         procedure TKONTROLFORM.EGYVALRADIOClick(Sender: TObject);
// =============================================================================

begin
  dnemCombo.ItemIndex := 0;
  dnemcombo.Visible := true;
  Activecontrol := dnemcombo;
end;

// =============================================================================
             procedure TKONTROLFORM.DNEMCOMBOChange(Sender: TObject);
// =============================================================================


var _dix: integer;

begin
  _dix := DnemCombo.itemindex;
  _qdnem := DnemCombo.Items[_dix];
  _egydnem := True;
  Balracsopen;
  Jobbracsopen;
  Activecontrol := ArfeRacs;
end;

// =============================================================================
       procedure TKONTROLFORM.EGYTRANZRADIOClick(Sender: TObject);
// =============================================================================

begin
  Tranzcombo.ItemIndex := 0;
  Tranzcombo.Visible := True;
end;

// =============================================================================
          procedure TKONTROLFORM.TRANZCOMBOChange(Sender: TObject);
// =============================================================================



begin
  _tix := Tranzcombo.ItemIndex;
  _qTranz := trim(TranzCombo.Items[_tix]);
  _qtranz := leftstr(_qTranz,1);
  _egytranz := True;
  Balracsopen;
  Jobbracsopen;
  Activecontrol := ArfeRacs;
end;

// =============================================================================
         procedure TKONTROLFORM.OSSZTRANZRADIOClick(Sender: TObject);
// =============================================================================

begin
  Tranzcombo.Visible := False;
  if _egyTranz then
    begin
      _egytranz := False;
      Balracsopen;
      Jobbracsopen;
    end;
  Activecontrol := ArfeRacs;
end;



procedure TKONTROLFORM.ERADIOClick(Sender: TObject);
begin
  _loByte := 16;
  PermitChange;
end;


procedure TKONTROLFORM.URADIOClick(Sender: TObject);
begin
  _LoByte :=32;
  PermitChange;
end;

procedure TKONTROLFORM.FRADIOClick(Sender: TObject);
begin
  _loByte := 64;
  PermitChange;
end;

procedure TKONTROLFORM.JRADIOClick(Sender: TObject);
begin
  _loByte := 128;
  PermitChange;
end;

procedure TKONTROLFORM.ONLYFEERADIOClick(Sender: TObject);
begin
  _loBYTE := 0;
  PermitChange;
end;

procedure TKONTROLFORM.FELEZESRADIOClick(Sender: TObject);
begin
  _hiByte := 256;
  PermitChange;
end;

procedure TKONTROLFORM.ELENGEDESRADIOClick(Sender: TObject);
begin
  _hiByte := 1024;
  PermitChange;
end;

procedure TKONTROLFORM.CSOKKENTESRADIOClick(Sender: TObject);
begin
  _hibyte := 2048;
  PermitChange;
end;

procedure TKONTROLFORM.ONLYRATERADIOClick(Sender: TObject);
begin
  _hiByte := 0;
  PermitChange;
end;

procedure TKontrolForm.PermitChange;

begin
  _permitKod := _lobyte + _hibyte;

  if _permitkod>0 then _vanPermit := true else _vanPermit := FAlse;
   Balracsopen;
  Jobbracsopen;
  Activecontrol := ArfeRacs;
end;



procedure TKONTROLFORM.ARFERACSKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);

begin
  _pkod := ArfeQuery.fieldbyname('ENGEDMENYTIPUS').asInteger;
  Dekodolas(_pkod);
  Barfpanel.Caption  := _dekarf;
  BkdijPanel.Caption := _dekkezd;
end;

procedure TKONTROLFORM.ARFERACSCellClick(Column: TColumn);

var _pkod: word;

begin
  _pkod := ArfeQuery.fieldbyname('ENGEDMENYTIPUS').asInteger;
  Dekodolas(_pkod);
  Barfpanel.Caption  := _dekarf;
  BkdijPanel.Caption := _dekkezd;
end;


procedure TKONTROLFORM.ENGRACSKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);

var _pkod: word;

begin
  _pkod := EngQuery.fieldbyname('PERMITTYPE').asInteger;
  Dekodolas(_pkod);
  Jarfpanel.Caption  := _dekarf;
  JkdijPanel.Caption := _dekkezd;
end;


procedure TKontrolForm.Dekodolas(_k: word);

begin
  _hib := trunc(_k/256);
  _lob := _k - trunc(256*_hib);
  _hib := trunc(256*_hib);

  case _lob of
     0: _dekarf := '-';
    16: _dekarf := '…RT…KT¡ROSI';
    32: _dekarf := 'F’…RT…KT¡ROSI';
    64: _dekarf := '‹GYVEZET’I';
   128: _dekarf := 'JUTAL…KMENTES';
  end;

  case _hib of
     0: _dekkezd := '-';
     256: _dekkezd := 'FELEZ…S';
     1024: _dekkezd := 'ELENGED…S';
     2048: _dekkezd := 'CS÷KKENT…S';
   end;
end;


procedure TKONTROLFORM.STARTGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
 // StartGomb.Color := clYellow;
  EscapeGomb.Color := clWhite;
end;



procedure TKONTROLFORM.ESCAPEGOMBMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
 //  StartGomb.Color := clWhite;
  EscapeGomb.Color := clYellow;
end;

procedure TKONTROLFORM.STARTPANELMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  // StartGomb.Color := clWhite;
  EscapeGomb.Color := clWhite;
end;

procedure TKONTROLFORM.ENGRACSCellClick(Column: TColumn);

var _pkod: word;

begin
  _pkod := EngQuery.fieldbyname('PERMITTYPE').asInteger;
  Dekodolas(_pkod);
  Jarfpanel.Caption  := _dekarf;
  JkdijPanel.Caption := _dekkezd;
end;

procedure TKONTROLFORM.SAVOSRADIOClick(Sender: TObject);
begin
  _loByte := 1;
  PermitChange;
end;

procedure TKONTROLFORM.SHKRADIOClick(Sender: TObject);
begin
  _loByte := 2;
  PermitChange;
end;

procedure TKONTROLFORM.VIPRADIOClick(Sender: TObject);
begin
  _loByte := 8;
  Permitchange;
end;



end.
