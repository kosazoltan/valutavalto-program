unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBCustomDataSet, IBQuery, StdCtrls, Buttons,
  IBTable, DateUtils, Comobj, Comctrls, ExtCtrls;

type
  TForm1 = class(TForm)
    EVCOMBO: TComboBox;
    HOCOMBO: TComboBox;
    HOOKEGOMB: TBitBtn;
    KILEPESGOMB: TBitBtn;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    TDTRANZ: TIBTransaction;
    TDDBASE: TIBDatabase;
    TDQUERY: TIBQuery;
    TDTABLA: TIBTable;
    KILEPOTIMER: TTimer;
    Label1: TLabel;
    Shape1: TShape;
    Shape2: TShape;
    Label2: TLabel;
    Shape3: TShape;
    Shape4: TShape;
    takaropanel: TPanel;
    gomb: TBitBtn;
    KDQUERY: TIBQuery;
    KDDBASE: TIBDatabase;
    KDTRANZ: TIBTransaction;
    kdtabla: TIBTable;

    procedure HOOKEGOMBClick(Sender: TObject);
    procedure IrodakBeolvasasa;
    procedure FormActivate(Sender: TObject);
    procedure TranzdijBeolvasasa;
    procedure MakeExcel;

    function Nulele(_byte: byte): string;
    function Scanetar(_kk: byte): byte;
    function ScanPenztar(_pnum: byte): byte;
    function SCantpt(_pnum: byte):byte;
    procedure KILEPOTIMERTimer(Sender: TObject);
    procedure KILEPESGOMBClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);
    procedure Kezelesidijbeolvasasa;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _aktev,_aktho,_kertev,_kertho: word;

  _etarnum: array[1..8] of byte = (20,40,50,63,75,10,120,145);
  _korzetnev: array[1..8] of string = ('Szeged','Kecskemét','Debrecen',
                'Nyíregyháza','Békéscsaba','Szekszárd','....Pécs','Kaposvár');

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS','MÁJUS',
                        'JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                        'NOVEMBER','DECEMBER');

  _height,_width: word;
  _penztarDarab: byte;
  _vanexcel: boolean;
  
  _pcs,_farok,_tablanev,_aktptnev,_formula: string;
  _sorveg : string = chr(13) + chr(10);

  _ptnum: array[1..150] of byte;
  _ptnev: array[1..150] of string;
  _ptKorzet: array[1..150] of byte;
  _ptfirm: array[1..150] of string;
  _transfee,_havikd: array[1..150] of integer;

  _aktptnum,_aktkorzet,_xx,_yy: byte;
  _aktfirm: string;
  _aktfee,_tdDarab,_qq,_tptdb,_tenypenztarDarab,_aktkorzetdb: integer;
  _korzetdb: array[1..8] of byte;
  _korzetpt: array[1..8,1..150] of byte;
  _tnum,_tkor: array[1..150] of byte;
  _tnev,_tceg: array[1..150] of string;
  _tfee: array[1..150] of integer;

  _oxl,_owb,_range: OleVariant;

  _eMezo,_vMezo: string;
  _kk,_sor,_kdb,_pt,_kezdet,_veg,_aktkdv,_aktkde,_ptkd: integer;
  _bk,_bv,_ek,_ev,_pk,_pv,_nn: byte;

implementation

{$R *.dfm}

// =============================================================================
              procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var i: integer;

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  top := trunc((_height-300)/2);
  left := trunc((_width-460)/2);


  for i := 1 to 150 do _transfee[i] := 0;
  for i := 1 to 8 do _korzetdb[i] := 0;

  _aktEv := yearof(Date);
  _aktHo := Monthof(Date);

  evcombo.clear;
  for i := -2 to 0 do Evcombo.Items.Add(inttostr(_aktev+i));

  HoCombo.Clear;
  for i := 1 to 12 do Hocombo.Items.Add(_honev[i]);



  evcombo.ItemIndex := 2;
  Hocombo.ItemIndex := _aktho-1;

  Activecontrol := HoOkegomb;
end;



// =============================================================================
             procedure TForm1.HOOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  HookeGomb.Enabled := false;
  Form1.WindowState := wsminimized;
  _kertev := (_aktev-2)+(evcombo.itemindex);
  _kertho := (Hocombo.itemindex)+1;

  _farok := inttostr(_kertev-2000)+nulele(_kertho);
  _tablanev := 'TRANZDIJ' + _farok;

  TDDBASE.Connected := true;
  tdTabla.close;
  TDTABLA.TableName := _tablanev;
  if not tdtabla.Exists then
    begin
      ShowMessage('NINCSENEK ADATOK A KÉRT HÓNAPRÓL !');
      TDDBASE.CLOSE;
      Application.Terminate;
      exit;
    end;
  tddbase.close;
  IrodakBeolvasasa;
  Tranzdijbeolvasasa;

  // -----------------------------

  KezelesiDijBeolvasasa;

  // -----------------------------

  MakeExcel;
  _vanexcel := true;
  _oxl.visible := true;
  Form1.WindowState := wsNormal;
  with takaropanel do
    begin
      Top := 62;
      Left := 10;
      Visible := True;
      Repaint;
    end;
  Gomb.Repaint;
  Kilepesgomb.Repaint;
  Activecontrol := Kilepesgomb;

end;


procedure TForm1.KezelesidijBeolvasasa;

var i: byte;

begin

  for i := 1 to 150 do _havikd[i]:= 0;

  _tablanev := 'KEZD' + _farok;

  Kddbase.Connected := true;
  KdTabla.close;
  Kdtabla.TableName := _tablanev;

  if not KdTabla.Exists then
    begin
      kdDbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _tablanev + ' ORDER BY PENZTAR';

  with kdQuery do
    begin
      Close;
      Sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not KdQuery.Eof do
    begin
      _pt   := KdQuery.FieldByName('PENZTAR').asInteger;
      _ptkd := 0;

      _nn := 1;
      while _nn<=31 do
        begin
          _vMezo  := 'KDV' + inttostr(_nn);
          _eMezo  := 'KDE' + inttostr(_nn);

          _aktkdv := KdQuery.FieldByName(_vmezo).asInteger;
          _aktkde := Kdquery.FieldbyName(_emezo).asInteger;

          _ptkd := _ptkd + _aktkdv + _aktkde;
          inc(_nn);
        end;
      _havikd[_pt] := _ptkd;
      Kdquery.Next;
    end;

  KdQuery.close;
  Kddbase.close;
end;



// =============================================================================
                 procedure TForm1.TranzdijBeolvasasa;
// =============================================================================


begin
  _pcs := 'SELECT * FROM ' + _tablanev;
  TdDbase.connected := true;
  with TdQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _tdDarab := recno;
      First;
    end;

  while not TDQuery.Eof do
    begin
      with TdQuery do
        begin
          _aktptnum := FieldByName('CASHIER').asInteger;
          _aktkorzet:= FieldByName('DISTRICT').asInteger;
          _aktfirm  := FieldByName('FIRMLETTER').asString;
          _aktfee   := FieldByName('TRANSFEE').asInteger;
        end;

      _xx := ScanPenztar(_aktptnum);
      _ptkorzet[_xx] := _aktkorzet;
      _ptfirm[_xx]   := _aktfirm;
      _transfee[_xx] := _transfee[_xx] + _aktfee;

      TDQuery.Next;
    end;
  TdQuery.Close;
  TdDbase.close;

  // ---------------------------------------------------------------------------

  _qq := 1;
  _tptdb := 0;
  while _qq<=_penztarDarab do
    begin
      _aktfee := _transfee[_qq];
      if _aktfee>0 then
        begin
          _aktptnum := _ptnum[_qq];
          _aktptnev := _ptnev[_qq];
          _aktkorzet:= _ptkorzet[_qq];
          _aktfirm  := _ptfirm[_qq];

          _yy := scanetar(_aktkorzet);
          _aktkorzetdb := 1+_korzetdb[_yy];
          _korzetdb[_yy] := _aktkorzetdb;
          _korzetPt[_yy,_aktkorzetdb] := _aktptnum;

          inc(_tptdb);

          _tnum[_tptdb] := _aktptnum;
          _tnev[_tptdb] := _aktptnev;
          _tkor[_tptdb] := _aktkorzet;
          _tceg[_tptdb] := _aktfirm;
          _tfee[_tptdb] := _aktfee;
        end;
      inc(_qq);
    end;
  _tenyPenztardarab := _tptdb;
end;


// =============================================================================
                  function TForm1.Scanetar(_kk: byte): byte;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  result := 0;
  while _y<=8 do
    begin
      if _etarnum[_y]=_kk then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
            function TForm1.ScanPenztar(_pnum: byte): byte;
// =============================================================================

var _y: byte;

begin
  _y := 0;
  result := 0;
  while _y<=_penztardarab do
    begin
      if _ptNum[_y]=_pnum then
        begin
          result := _y;
          break;
        end;
      inc(_y);
    end;
end;


// =============================================================================
                 procedure TForm1.IrodakBeolvasasa;
// =============================================================================

var _pdb: byte;

begin
  _pcs := 'SELECT * FROM IRODAK' + _sorveg;
  _pcs := _pcs + 'ORDER BY CEGBETU,ERTEKTAR';

  recdbase.Connected := True;
  with Recquery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  _pdb := 0;
  while not recquery.Eof do
    begin
      inc(_pdb);
      _ptnum[_pdb] := RecQuery.fieldByName('UZLET').asInteger;
      _ptnev[_pdb] := trim(RecQuery.FieldByName('KESZLETNEV').asString);
      Recquery.Next;
    end;
  RecQuery.close;
  Recdbase.close;
  _penztarDarab := _pdb;
end;


// =============================================================================
               function TForm1.Nulele(_byte: byte): string;
// =============================================================================

begin
  result := inttostr(_byte);
  if _byte<10 then result := '0' + result;
end;


// =============================================================================
                         procedure TForm1.MakeExcel;
// =============================================================================

var _aktkezdij: integer;

begin
  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add[1];


  _range := _oxl.range['A3:I3'];
  _range.select;
  _range.mergecells  := true;
  _range.horizontalalignment := -4108;

  _range.Font.Name   := 'Arial';
  _range.Font.Size   := 18;
  _range.Font.Italic := true;
  _range.Font.Bold   := False;

  _oxl.cells[1,1].columnwidth := 14;
  _oxl.cells[1,2].columnwidth := 16;
  _oxl.cells[1,3].columnwidth := 15;
  _oxl.cells[1,4].columnwidth := 33;
  _oxl.cells[1,5].columnwidth := 21;
  _oxl.cells[1,6].columnwidth := 21;
  _oxl.cells[1,7].columnwidth := 19;
  _oxl.cells[1,8].columnwidth := 18;
  _oxl.cells[1,9].columnwidth := 24;

  _oxl.cells[3,1] := 'AZ EXCLUSIVE CHANGE '+INTTOSTR(_KERTEV)+' '+_honev[_kertho]+ ' HAVI TRANZAKCIÓ DÍJAK LISTÁJA';

  _range := _oxl.range['A5:I5'];
  _range.select;
  _range.Font.Name   := 'Arial';
  _range.Font.Size   := 12;
  _range.Font.Bold   := True;
  _range.Font.Italic := True;
  _range.HorizontalAlignment := -4108;

  _oxl.cells[5,1] := 'CÉG NEVE';
  _oxl.cells[5,2] := 'KÖRZET NEVE';
  _oxl.cells[5,3] := 'PTÁR SZÁM';
  _oxl.cells[5,4] := 'PÉNZTÁR MEGNEVEZÉSE';
  _oxl.cells[5,5] := 'TRANZAKCIÓ DÍJ';
  _oxl.cells[5,6] := 'BEJÖTT KEZ-I DÍJ';
  _oxl.cells[5,7] := 'KÖRZET ÖSSZ.';
  _oxl.cells[5,8] := 'KFT ÖSSZ.';
  _oxl.cells[5,9] := 'EXCLUSIVE ÖSSZ.';

  _range := _oxl.range['B7:F'+inttostr(6+_tenypenztardarab)];
  _range.Select;
  _range.Font.name := 'Times New Roman';
  _range.Font.Size := 16;
  _range.Font.Bold := False;
  _range.Font.Italic := True;

  _range := _oxl.range['C7:C'+inttostr(6+_tenypenztardarab)];
  _range.Select;
  _range.HorizontalAlignment := -4108;

  _range := _oxl.range['E7:F'+inttostr(6+_tenypenztardarab)];
  _range.Select;
  _range.numberformat := '### ### ###';

  _veg := 6;
  _kk := 1;
  while _kk<=8 do
    begin
      _kezdet := _veg+1;
      _veg := _kezdet + _korzetdb[_kk] - 1;
      _range := _oxl.range['B'+inttostr(_kezdet)+':B'+inttostr(_veg)];
      _range.Mergecells := true;
      _range.VerticalAlignment := -4108;
      _range.HorizontalAlignment := -4117;
      _oxl.cells[_kezdet,2] := _korzetnev[_kk]+ ' körzet';

      _range := _oxl.range['G'+inttostr(_kezdet)+':G'+inttostr(_veg)];
      _range.Mergecells := true;
      _range.VerticalAlignment := -4108;
      _range.HorizontalAlignment := -4108;
      _range.Font.size := 14;
      _range.Font.Bold := true;
      _range.Font.Italic := True;

      _formula := '=SUM(E'+inttostr(_kezdet)+':E'+inttostr(_veg)+')';
      _oxl.cells[_kezdet,7].formula := _formula;

      inc(_kk);
    end;

  _kk := 1;
  _sor := 7;
  while _kk<=8 do
    begin
      _kdb := _korzetdb[_kk];
      _pt := 1;
      while _pt<=_kdb do
        begin
          _aktptnum := _korzetPt[_kk,_pt];
          _aktkezdij := _havikd[_aktptnum];
          _xx := Scantpt(_aktptnum);
          _aktptnev := _tnev[_xx];
          _aktfee   := _tfee[_xx];
          _oxl.cells[_sor,3] := inttostr(_aktptnum);
          _oxl.cells[_sor,4] := _aktptnev;
          _oxl.cells[_sor,5] := inttostr(_aktfee);
          _oxl.cells[_sor,6] := inttostr(_aktkezdij);

          inc(_pt);
          inc(_sor);
        end;
      inc(_kk);
    end;

  // Cégdisplay -----

  _bk := 7;
  _bv := _bk + _korzetdb[1] + _korzetdb[2] -1;

  _ek := _bv + 1;
  _ev := _ek + _korzetdb[3] + _korzetdb[4] + _korzetdb[5] - 1;

  _pk := _ev + 1;
  _pv := 6 + _tenyPenztardarab;

  // ---------------------------------------------------------------------------

  _range := _oxl.range['A' +inttostr(_bk)+':A'+inttostr(_bv)];
  _range.mergecells := true;
  _range.verticalAlignment := -4108;
  _range.HorizontalAlignment := -4117;
  _range.font.Name := 'Times New Roman';
  _range.font.size := 14;
  _range.font.bold := True;
  _range.Font.Italic := True;
  _oxl.cells[_bk,1] := 'Exlusive Best Change';

  _range := _oxl.range['H' +inttostr(_bk)+':H'+inttostr(_bv)];
  _range.mergecells := true;
  _range.verticalAlignment := -4108;
  _range.HorizontalAlignment := -4108;
  _range.font.Name := 'Times New Roman';
  _range.font.size := 16;
  _range.font.bold := fALSE;
  _range.Font.Italic := True;
  _range.NumberFormat := '### ### ###';
  _formula := '=SUM(E'+ inttostr(_bk)+':E'+inttostr(_bv)+')';
  _oxl.cells[_bk,8].formula := _formula;

  // ===========================================================================

  _range := _oxl.range['A' +inttostr(_ek)+':A'+inttostr(_ev)];
  _range.mergecells := true;
  _range.verticalAlignment := -4108;
  _range.HorizontalAlignment := -4117;
  _range.font.Name := 'Times New Roman';
  _range.font.size := 14;
  _range.font.bold := True;
  _range.Font.Italic := True;
  _oxl.cells[_ek,1] := 'Exlusive East Change';

  _range := _oxl.range['H' +inttostr(_ek)+':H'+inttostr(_ev)];
  _range.mergecells := true;
  _range.verticalAlignment := -4108;
  _range.HorizontalAlignment := -4108;
  _range.font.Name := 'Times New Roman';
  _range.font.size := 16;
  _range.font.bold := fALSE;
  _range.Font.Italic := True;
  _range.NumberFormat := '### ### ###';
  _formula := '=SUM(E'+ inttostr(_ek)+':E'+inttostr(_ev)+')';
  _oxl.cells[_ek,8].formula := _formula;

  // ===========================================================================

  _range := _oxl.range['A' +inttostr(_pk)+':A'+inttostr(_pv)];
  _range.mergecells := true;
  _range.verticalAlignment := -4108;
  _range.HorizontalAlignment := -4117;
  _range.font.Name := 'Times New Roman';
  _range.font.size := 14;
  _range.font.bold := True;
  _range.Font.Italic := True;
  _oxl.cells[_pk,1] := 'Exlusive Pannon Change';

  _range := _oxl.range['H' +inttostr(_pk)+':H'+inttostr(_pv)];
  _range.mergecells := true;
  _range.verticalAlignment := -4108;
  _range.HorizontalAlignment := -4108;
  _range.font.Name := 'Times New Roman';
  _range.font.size := 16;
  _range.font.bold := fALSE;
  _range.Font.Italic := True;
  _range.NumberFormat := '### ### ###';
  _formula := '=SUM(E'+ inttostr(_pk)+':E'+inttostr(_pv)+')';
  _oxl.cells[_pk,8].formula := _formula;

  // ===========================================================================

  _range := _oxl.range['I' +inttostr(_bk)+':I'+inttostr(_pv)];
  _range.mergecells := true;
  _range.verticalAlignment := -4108;
  _range.HorizontalAlignment := -4108;
  _range.font.Name := 'Times New Roman';
  _range.font.size := 18;
  _range.font.bold := True;
  _range.Font.Italic := True;
  _range.NumberFormat := '### ### ###';
  _formula := '=SUM(E'+ inttostr(_bk)+':E'+inttostr(_pv)+')';
  _oxl.cells[_Bk,9].formula := _formula;

   _range := _oxl.range['A6','A6'];
   _range.select;
   _oxl.Activewindow.FreezePanes := True;

end;

// =============================================================================
                   function TForm1.SCantpt(_pnum: byte):byte;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  result := 0;
  while _y<=_tenypenztardarab do
    begin
      if _tnum[_y]=_pnum then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
             procedure TForm1.KILEPOTIMERTimer(Sender: TObject);
// =============================================================================

begin
   KilepoTimer.Enabled := false;
  if _vanexcel then
    begin
      _owb := unassigned;
      _oxl.quit;
      _oxl := unassigned;
    end;
  aPPLICATION.Terminate;
end;

// =============================================================================
               procedure TForm1.KILEPESGOMBClick(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := true;
end;

procedure TForm1.EVCOMBOChange(Sender: TObject);
begin
  Activecontrol := Hookegomb;
end;

end.
