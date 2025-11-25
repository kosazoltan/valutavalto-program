unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery, dateUtils, strutils;

type
  TRendeloForm = class(TForm)
    AlapPanel      : TPanel;
    AranyPanel     : TPanel;
    Fuggony        : TPanel;
    RDnemPanel     : TPanel;
    RendForintPanel: TPanel;

    Label1         : TLabel;
    Label2         : TLabel;
    Label3         : TLabel;
    Label4         : TLabel;
    Label5         : TLabel;
    Label6         : TLabel;
    Label7         : TLabel;
    Label8         : TLabel;

    DnemCombo      : TComboBox;
    FDnemCombo     : TComboBox;

    ArfolyamEdit   : TEdit;
    BjegyEdit      : TEdit;
    FoglaloEdit    : TEdit;
    HidoEdit       : TEdit;

    Shape1         : TShape;
    Shape2         : TShape;
    Shape3         : TShape;

    EladasGomb     : TBitBtn;
    RendbenGomb    : TBitBtn;
    MegsemGomb     : TBitBtn;
    VetelGomb      : TBitBtn;

    FQuery         : TIBQuery;
    FDbase         : TIBDatabase;
    FTranz         : TIBTransaction;

    procedure Arfolyambetoltes;
    procedure ArfolyamEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ArfolyamBedolgozas;
    procedure BankjegyBedolgozas;
    procedure BJegyEditEnter(Sender: TObject);
    procedure BJegyEditExit(Sender: TObject);
    procedure BJegyEditKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure DnemComboChange(Sender: TObject);
    procedure EladasGombClick(Sender: TObject);
    procedure FParancs(_ukaz: string);
    procedure FormActivate(Sender: TObject);
    procedure FDnemComboChange(Sender: TObject);
    procedure FoglaloEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FoglaloBedolgozas;
    procedure HidoEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HidoEditEnter(Sender: TObject);
    procedure HidoBedolgozas;
    procedure MegsemGombClick(Sender: TObject);
    procedure RendbenGombClick(Sender: TObject);
    procedure StartProgram;
    procedure VetelGombClick(Sender: TObject);
    procedure Vegszamitas;

    function Diffmake(_ujhatidos: string): extended;
    function Ftform(_ft: integer): string;
    function Kerekito(_int:integer): integer;
    function Nulele(_b: byte): string;

    procedure ARFOLYAMEDITExit(Sender: TObject);
    procedure FOGLALOEDITExit(Sender: TObject);
    procedure HIDOEDITExit(Sender: TObject);
    procedure ARFOLYAMEDITEnter(Sender: TObject);
    procedure FOGLALOEDITEnter(Sender: TObject);
    procedure FDNEMCOMBOEnter(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  RendeloForm: TRendeloForm;

  _dnem: array[0..26] of string;
  _vetarf,_eladarf: array[0..26] of integer;

  _hev,_hho,_hnap,_ujev,_ujho,_ujnap: word;

  _holnap,_ujhatido: TDateTime;

  _hufindex,_findex,_dnemdarab: byte;
  _height,_width,_top,_left,_y: word;

  _pcs,_aktdnem,_foglalodnem,_tipus,_hatarido,_foglstr: string;
  _sorveg: string = chr(13)+chr(10);
  _bankjegy,_foglalo,_forintertek,_aktindex,_aktarfolyam,_code: integer;
  _farfolyam,_spk,_origindex: integer;

  _bjegyflag,_arfflag,_hidoflag,_foglaloFlag: boolean;

function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll';
function foglalorendeles: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
              function foglalorendeles: integer; stdcall;
// =============================================================================

begin
  rendeloform := TRendeloForm.Create(Nil);
  result := rendeloform.showmodal;
  rendeloform.Free;
end;

// =============================================================================
            procedure TRENDELOFORM.FormActivate(Sender: TObject);
// =============================================================================

begin

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;
  _top    := round((_height-768)/2);
  _left   := round((_width-1024)/2);

  Top     := _top+280;
  Left    := _left+235;

  Rendbengomb.Enabled := False;

  _bjegyflag   := False;
  _arfflag     := False;
  _hidoflag    := False;
  _foglaloflag := False;

  ArfolyamBetoltes;
  _holnap := Date+1;
  _hev := yearof(_holnap);
  _hho := monthof(_holnap);
  _hnap:= dayof(_holnap);

  _hatarido := inttostr(_hev)+'.'+nulele(_hho)+'.'+nulele(_hnap);

  HidoEdit.Text := _hatarido;
  Hidoedit.Repaint;

  _aktdnem := _dnem[0];
  rdnemPanel.Caption := _aktdnem;
  rdnemPanel.repaint;

  with Fuggony do
    begin
      top     := 60;
      left    := 8;
      Visible := True;
      repaint;
    end;
  Activecontrol := Vetelgomb;
end;

// =============================================================================
         procedure TRENDELOFORM.RENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  if _foglalo=0 then
    begin
      rendbengomb.Enabled := False;
      exit;
    end;

  _pcs := 'DELETE FROM VTEMP';
  FParancs(_pcs);

  _pcs := 'INSERT INTO VTEMP (TIPUS)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _tipus + chr(39)+')';
  Fparancs(_pcs);

  _pcs := 'UPDATE VTEMP SET VALUTANEM=' + chr(39) + _aktdnem + chr(39);
  _pcs := _pcs + ',BANKJEGY='+inttostr(_bankjegy);
  _pcs := _pcs + ',ARFOLYAM='+inttostr(_aktarfolyam);
  _pcs := _pcs + ',FORINTERTEK=' + inttostr(_forintertek);
  _pcs := _pcs + ',DATUM=' + chr(39) + _hatarido + chr(39);
  _pcs := _pcs + ',FIZETENDO=' + inttostr(_foglalo);
  _pcs := _pcs + ',MEGJEGYZES=' + chr(39) + _foglalodnem + chr(39);
  FParancs(_pcs);

  Modalresult := 1;
end;

// =============================================================================
            procedure TRendeloform.FParancs(_ukaz: string);
// =============================================================================

begin
  Fdbase.connected := True;
  if Ftranz.InTransaction then Ftranz.Commit;
  ftranz.StartTransaction;
  with Fquery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  FTranz.commit;
  fdbase.close;
end;

// =============================================================================
             procedure TRENDELOFORM.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := -1;
end;

// =============================================================================
                       procedure TRendeloForm.Arfolyambetoltes;
// =============================================================================

begin
  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'WHERE (VALUTANEM<>'+chr(39)+'EUA'+chr(39);
  _pcs := _pcs + ') AND (VALUTANEM<>'+chr(39)+'RCH'+CHR(39)+')'+_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  Fdbase.connected := true;
  with FQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;

  _y := 0;
  while not FQuery.eof do
    begin
      _aktdnem  := FQuery.FieldByName('VALUTANEM').asString;
      _dnem[_y] := _aktdnem;

      if _aktdnem='HUF' then _hufindex := _y;

      _vetarf[_y]  := FQuery.FieldByNAme('VETELIARFOLYAM').asinteger;
      _Eladarf[_y] := FQuery.FieldByNAme('ELADASIARFOLYAM').asinteger;

      FQuery.next;
      inc(_y);
    end;

  FQuery.close;
  Fdbase.close;
  _dnemdarab := _y;

  Dnemcombo.items.clear;
  dnemcombo.clear;

  FDnemCombo.items.clear;
  Fdnemcombo.clear;

  _y := 0;
  while _y<_dnemdarab do
    begin
      _aktdnem := _dnem[_y];

      dnemcombo.items.add(_aktdnem);
      FDnemcombo.items.add(_aktdnem);

      inc(_y);
    end;
end;

// =============================================================================
          procedure TRENDELOFORM.VETELGOMBClick(Sender: TObject);
// =============================================================================

begin
  _tipus := 'V';
  StartProgram;
end;

// =============================================================================
             procedure TRENDELOFORM.ELADASGOMBClick(Sender: TObject);
// =============================================================================

begin
  _tipus := 'E';
  StartProgram;
end;

// =============================================================================
                  procedure TRendeloForm.StartProgram;
// =============================================================================

begin
  _bankjegy := 0;
  if _tipus='V' then _aktarfolyam := _vetarf[0]
  else _aktarfolyam := _eladarf[0];

  Arfolyamedit.Text := inttostr(_aktarfolyam);
  arfolyamedit.Repaint;

  Aranypanel.Caption := '100 '+_aktdnem + '/HUF';
  AranyPanel.Repaint;

  dnemcombo.ItemIndex  := 0;
  fdnemCombo.ItemIndex := _hufindex;

  Fuggony.visible := False;
  Activecontrol := Bjegyedit;
end;




// =============================================================================
          procedure TRENDELOFORM.DNEMCOMBOChange(Sender: TObject);
// =============================================================================

begin
  _aktindex := dnemCombo.itemindex;
  _aktdnem  := dnemCombo.Items[_aktindex];

  if _tipus='V' then _aktarfolyam := _vetarf[_aktindex]
  else _aktarfolyam := _eladarf[_aktindex];

  Arfolyamedit.Text := inttostr(_aktarfolyam);
  arfolyamedit.Repaint;

  RdnemPanel.Caption := _aktdnem;
  rdnemPanel.Repaint;
  Aranypanel.Caption := '100 '+_aktdnem+'/HUF';
  AranyPanel.repaint;
  if _bankjegy>0 then Vegszamitas
  else Activecontrol := BjegyEdit;
end;

// =============================================================================
              function TrendeloForm.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
                function TRendeloform.Kerekito(_int:integer): integer;
// =============================================================================

var _str: string;
    _ww,_utbetu: integer;
begin
  result := 0;
  if _int=0 then exit;

  result  := _int;
  _str    := inttostr(result);
  _ww     := length(_str);
  _utbetu := ord(_str[_ww])-48;
  if (_utbetu=0) or (_utbetu=5) then exit;

  if _utbetu<5 then result := result - _utbetu
  else result := result + (10-_utbetu);
end;

// =============================================================================
             function TRendeloForm.Ftform(_ft: integer): string;
// =============================================================================

var _fts: string;
    _wfts,_f1: byte;

begin
  result := '-';
  _fts := inttostr(_ft);
  if _ft=0 then exit;

  result := _fts;
  _wfts := length(_fts);

  if _wfts<4 then exit;


  if _wfts>6 then
    begin
      _f1 := _wfts - 6;
      result := leftstr(_fts,_f1)+'.' +midstr(_fts,_f1+1,3)+'.'+midstr(_fts,_f1+4,3);
      exit;
    end;

  _f1 := _wfts - 3;
  result := leftstr(_fts,_f1)+'.' +midstr(_fts,_f1+1,3);
end;




// =============================================================================
                procedure TrendeloForm.Vegszamitas;
// =============================================================================

begin
  _forintErtek := round(_aktarfolyam/100*_bankjegy);

  RendForintpanel.Caption := ftform(_forintErtek)+' Ft';
  RendForintPanel.Repaint;

  _foglalo := round(0.05*_forintertek);
  _foglalo := kerekito(_foglalo);
  _findex  := fdnemcombo.itemindex;

  if _findex<>_hufindex then
    begin
      if _tipus='V' then _farfolyam := _vetarf[_findex]
      else _farfolyam := _eladarf[_findex];
      _foglalo := round(_foglalo/_farfolyam*100);
      _foglalo := kerekito(_foglalo);
    end;
  _foglalodnem := _dnem[_findex];

  foglaloedit.Text := inttostr(_foglalo);
  RendbenGomb.Enabled := true;
  Activecontrol := RendbenGomb;
end;

// =============================================================================
          procedure TRendeloForm.FDnemComboChange(Sender: TObject);
// =============================================================================

begin
  _spk := supervisorjelszo(0);
  if _spk<>1 then fdnemcombo.ItemIndex := _origindex;
  _findex := fdnemcombo.itemindex;
  _foglalodnem := _dnem[_findex];
  vegszamitas;
end;




// =============================================================================
         function TRendeloForm.Diffmake(_ujhatidos: string): extended;
// =============================================================================

var _ujevs,_ujhos,_ujnaps: string;

begin
  result := -1;
  _ujevs := leftstr(_ujhatidos,4);
  _ujhos := midstr(_ujhatidos,6,2);
  _ujnaps:= midstr(_ujhatidos,9,2);

  val(_ujevs,_ujev,_code);
  if _code<>0 then exit;

  val(_ujhos,_ujho,_code);
  if _code<>0 then exit;

  val(_ujnaps,_ujnap,_code);
  if _code<>0 then exit;

  if _ujev>(_hev+1) then exit;
  if _ujho>12 then exit;
  if _ujnap>31 then exit;

  _ujhatido := encodeDate(_ujev,_ujho,_ujnap);
  result := _ujhatido-date;
end;

// =============================================================================
           procedure TRENDELOFORM.BJEGYEDITEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clyellow;
  Rendbengomb.Enabled := False;
  _BjegyFlag := true;
end;

// =============================================================================
           procedure TRENDELOFORM.BJEGYEDITExit(Sender: TObject);
// =============================================================================

begin  TEdit(sender).Color := clWindow;
  Bankjegybedolgozas;
end;

// =============================================================================
     procedure TRendeloForm.BJEGYEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  Bankjegybedolgozas;
end;


// =============================================================================
              procedure TrendeloForm.BankjegyBedolgozas;
// =============================================================================

var _bjegys: string;

begin
  if not _bjegyFlag then exit;

  _bjegyflag := False;

  _bjegys := trim(Bjegyedit.Text);
  val(_bjegys,_bankjegy,_code);
  if _code<>0 then _bankjegy := 0;
  if _bankjegy=0 then exit;

  Vegszamitas;
end;

/// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// =============================================================================
           procedure TRendeloForm.ARFOLYAMEDITEnter(Sender: TObject);
// =============================================================================

begin
  ArfolyamEdit.Color  := clyellow;
  RendbenGomb.Enabled := False;
  _ArfFlag := True;
end;

// =============================================================================
          procedure TRendeloForm.ARFOLYAMEDITExit(Sender: TObject);
// =============================================================================

begin
  ArfolyamEdit.Color := clWindow;
  Arfolyambedolgozas;
end;

// =============================================================================
   procedure TRendeloForm.ARFOLYAMEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  ArfolyamBedolgozas;
end;


// =============================================================================
                 procedure TRendeloForm.ArfolyamBedolgozas;
// =============================================================================

var _ujarfolyam: integer;
    _arfs: string;

begin
  if not _arfflag then exit;

  _arfflag := False;
  _arfs := trim(arfolyamedit.Text);
  val(_arfs,_ujarfolyam,_code);
  if _code<>0 then _ujarfolyam := 0;
  if _ujarfolyam=0 then exit;
  _aktarfolyam := _ujarfolyam;
  Vegszamitas;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// =============================================================================
            procedure TRendeloForm.HidoEditEnter(Sender: TObject);
// =============================================================================

begin
  Hidoedit.color := clYellow;
  RendbenGomb.Enabled := False;
  _Hidoflag := True;
end;

// =============================================================================
           procedure TRendeloForm.HIDOEDITExit(Sender: TObject);
// =============================================================================

begin
  Hidoedit.Color := clWIndow;
  HidoBedolgozas;
end;

// =============================================================================
    procedure TRendeloForm.HidoEditKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  HidoBedolgozas;
end;

// =============================================================================
                procedure TRendeloform.HidoBedolgozas;
// =============================================================================

var _terms: string;
    _diff: extended;

begin
  if not _hidoflag then exit;

  _hidoflag := False;
  _terms := trim(Hidoedit.Text);

  if length(_terms)<>10 then exit;
  if _terms<_hatarido then exit;
  _diff := diffmake(_terms);
  if _diff=-1 then
    begin
      HidoEdit.Text := _hatarido;
      Rendbengomb.enabled := true;
      Activecontrol := rendbengomb;
      exit;
    end;

  if _diff>10 then
    begin
      Showmessage('Ez túl távoli idõpont');
    end else
    begin
      if _diff>5 then
        begin
          _spk := supervisorjelszo(0);
          if _spk=1 then _hatarido := _terms;
        end;
    end;
  if _diff<6 then _hatarido := _terms;

  Hidoedit.Text := _hatarido;
  Hidoedit.Repaint;

  Rendbengomb.enabled := true;
  Activecontrol := rendbengomb;
end;

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// =============================================================================
            procedure TRendeloForm.FOGLALOEDITEnter(Sender: TObject);
// =============================================================================

begin
  FoglaloEdit.color := clYellow;
  RendbenGomb.Enabled := False;
  _foglaloflag := True;
  _foglstr := trim(Foglaloedit.Text);
end;


// =============================================================================
          procedure TRendeloForm.FOGLALOEDITExit(Sender: TObject);
// =============================================================================

begin
  FoglaloEdit.Color := clWindow;
  FoglaloBedolgozas;
end;

// =============================================================================
   procedure TRendeloForm.FOGLALOEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _spk := supervisorjelszo(0);
  if _spk<>1 then
    begin
      Foglaloedit.Text :=_foglStr;
      Rendbengomb.Enabled := true;
      Activecontrol := Rendbengomb;
      exit;
    end;

  FoglaloBedolgozas;
end;

// =============================================================================
              procedure TRendeloForm.FoglaloBedolgozas;
// =============================================================================

var _ujfoglalo: integer;
    _fogls: string;

begin
  if not _foglaloFlag then exit;

  _foglaloflag := False;
  _fogls :=trim(Foglaloedit.Text);
  val(_fogls,_ujfoglalo,_code);
  if _code<>0 then _ujfoglalo := 0;
  if _ujfoglalo<100 then exit;
  _foglalo := _ujfoglalo;
  Rendbengomb.Enabled := true;
  Activecontrol := Rendbengomb;
end;

procedure TRendeloForm.FDNEMCOMBOEnter(Sender: TObject);
begin
  _origindex := Fdnemcombo.itemindex;
end;

end.
