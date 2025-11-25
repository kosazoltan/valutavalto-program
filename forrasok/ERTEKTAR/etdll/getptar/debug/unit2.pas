unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, DBGrids, DB, DBTables,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery, ExtCtrls;

type
  TPenztarValasztoForm = class(TForm)

    PTarValCancelGomb: TBitBtn;
       PtarValOkeGomb: TBitBtn;
    Label1: TLabel;
    PENZTARSOURCE: TDataSource;
    PENZTARRACS: TDBGrid;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    Shape1: TShape;
    UJPENZTARGOMB: TBitBtn;
    UJPENZTARPANEL: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    PSZAMEDIT: TEdit;
    PNEVEDIT: TEdit;
    PCIMEDIT: TEdit;
    PTELEDIT: TEdit;
    ujptokegomb: TBitBtn;
    UJPTMEGSEMGOMB: TBitBtn;
    Shape2: TShape;
    TRBBEKEROPANEL: TPanel;
    Label7: TLabel;
    TRBPTEDIT: TEdit;
    TRBPTOKEGOMB: TBitBtn;
    TRBPTMEGSEMGOMB: TBitBtn;
    Shape3: TShape;

    procedure FormActivate(Sender: TObject);
    procedure PenztarRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PenztarRacsDblClick(Sender: TObject);
    procedure PtarValCancelGombClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure UJPENZTARGOMBClick(Sender: TObject);
    procedure PSZAMEDITEnter(Sender: TObject);
    procedure PSZAMEDITExit(Sender: TObject);
    procedure PSZAMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ujptokegombClick(Sender: TObject);
    procedure Racsmegnyitas;
    procedure UJPTMEGSEMGOMBClick(Sender: TObject);
 
    procedure TRBPTEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TRBPTOKEGOMBClick(Sender: TObject);
    procedure TRBPTMEGSEMGOMBClick(Sender: TObject);
    procedure TRBBekeres;
    procedure SelectedtoVtemp;
    procedure TRBPTEDITEnter(Sender: TObject);
    procedure TRBPTEDITExit(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  PenztarValasztoForm: TPenztarValasztoForm;
  _qq,_recno,_code: integer;
  _height,_width,_top,_left,_editss,_trbPenztar: word;
  _pcs,_homePenztarszam,_aktPenztarszam,_aktPenztarNev,_aktText: string;
  _pnums,_pnev,_pcim,_ptel,_trbpts: string;
  _sorveg: string = chr(13) + chr(10);

  _PEDIT: array[1..4] of TEdit;
  _aktedit: TEdit;

function supervisorjelszo(_para: integer): integer;stdcall; external
                             'c:\ertektar\bin\super.dll' name 'supervisorjelszo';  

  function penztarrutin: integer; stdcall;

implementation

{$R *.dfm}

// =============================================================================
                function penztarrutin: integer; stdcall;
// =============================================================================

begin
  PenztarValasztoForm := TPenztarValasztoForm.Create(NIL);
  result := PenztarValasztoForm.ShowModal;
  PenztarValasztoForm.Free;
end;  


// =============================================================================
          procedure TPenztarValasztoForm.FormActivate(Sender: TObject);
// =============================================================================

begin
   _height := Screen.Monitors[0].Height;
   _width  := Screen.Monitors[0].Width;

   _top := trunc((_height-563)/2);
   _left := trunc((_width-660)/2);

    Top   := _top;
   Left   := _left;
   width  := 660;
   Height := 563;

   _pedit[1] := PSzamEdit;
   _pedit[2] := PnevEdit;
   _pedit[3] := PcimEdit;
   _pedit[4] := PtelEdit;
   _trbpts   := '';

   ValutaDbase.Connected := True;
   _pcs := 'SELECT * FROM PENZTAR';
   with ValutaQuery do
     begin
       Close;
       sql.clear;
       sql.add(_pcs);
       Open;
       _homepenztarszam := trim(fieldbyName('PENZTARKOD').AsString);
       Close;
     end;
   RacsMegnyitas;
end;


procedure TPenztarValasztoForm.RacsMegnyitas;

begin
   _pcs := 'SELECT * FROM PENZTAR' + _sorveg;
   _pcs := _pcs + 'WHERE PENZTARKOD<>'+chr(39)+_homepenztarszam + chr(39);

   with ValutaQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       First;
     end;
   ActiveControl := PenztarRacs;
end;

// =============================================================================
      procedure TPenztarValasztoForm.PtarValCancelGombClick(Sender: TObject);
// =============================================================================

begin
  ValutaQuery.close;
  Valutadbase.Close;
  Modalresult := 2;
end;


// =============================================================================
       procedure TPenztarValasztoForm.PenztarRacsDblClick(Sender: TObject);
// =============================================================================


begin
  with ValutaQuery do
    begin
      _aktPenztarszam := FieldByName('PENZTARKOD').asString;
      _aktPenzTarnev := trim(FieldByName('PENZTARNEV').asstring);
      Close;
    end;
  _akTPenztarszam := trim(_aktpenztarszam);
  if _aktpenztarszam='TRB' then
    begin
      Trbbekeres;
      exit;
    end;
  SelectedToVtemp;
end;


procedure TPenztarValasztoForm.SelectedtoVtemp;

begin
  _pcs := 'SELECT * FROM VTEMP';
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.Add(_pcs);
      Open;
      _recno := Recno;
      close;
    end;

  if _recno=0 then
    begin
      _pcs := 'INSERT INTO VTEMP (PENZTARKOD,TARSPENZTARNEV,TRBPENZTAR)' + _sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktpenztarszam + chr(39) + ',';
      _pcs := _pcs + chr(39) + _aktpenztarnev + chr(39) + ',';
      _pcs := _pcs + chr(39) + _trbpts + chr(39) + ')';
    end else
    begin
      _pcs := 'UPDATE VTEMP SET PENZTARKOD='+CHR(39)+_aktpenztarszam+chr(39);
      _pcs := _pcs + ',TARSPENZTARNEV='+chr(39)+_aktpenztarnev+chr(39);
      _pcs := _pcs + ',TRBPENZTAR='+CHR(39)+_trbpts+chr(39);
    end;
  if Valutatranz.InTransaction then ValutaTranz.Commit;
  ValutaTranz.StartTransaction;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      ExecSql;
    end;
  Valutatranz.commit;
  ValutaDbase.close;

  ModalResult := 1;
end;



// =============================================================================
      procedure TPenztarValasztoForm.PenztarRacsKeyDown(Sender: TObject;
                                          var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if Ord(Key)<>13 then exit;
  PenztarRacsDBlclick(PenztarRacs);
end;


// =============================================================================
            procedure TPenztarValasztoForm.FormCreate(Sender: TObject);
// =============================================================================

begin
    Top := _top+ 150;
   Left := _left + 275;
end;



procedure TPenztarValasztoForm.UJPENZTARGOMBClick(Sender: TObject);

var i: byte;
    _spk: integer;

begin
  ValutaQuery.close;
  ValutaDbase.close;
  _spk := supervisorjelszo(0);
  if _spk<>1 then
    begin
      Modalresult := 2;
      exit;
    end;

  for i := 1 to 4 do _pedit[i].clear;
  
  with UjpenztarPanel do
    begin
      top := 224;
      Left:= 10;
      Visible := true;
      Repaint;
    end;
  activecontrol := PSzamEdit;

end;

procedure TPenztarValasztoForm.PSZAMEDITEnter(Sender: TObject);
begin
  _editss := TEdit(Sender).Tag;
  _aktedit := _Pedit[_editss];
  _aktedit.color := clYellow;
end;

procedure TPenztarValasztoForm.PSZAMEDITExit(Sender: TObject);
begin
  Tedit(Sender).Color := clWindow;
end;

procedure TPenztarValasztoForm.PSZAMEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);


var _bill: byte;  

begin
   _bill := ord(Key);
  _editss := TEdit(sender).tag;

  if (_bill=38) and (_editss>1) then
    begin
      dec(_editss);
      _aktedit := _pedit[_editss];
      ActiveControl := _aktedit;
      exit;
    end;

  if (_bill=40) and (_editss<4) then
    begin
      inc(_editss);
      _aktedit := _pedit[_editss];
      ActiveControl := _aktedit;
      exit;
    end;

  if _bill<>13 then exit;
  if _editss<4 then
    begin
      inc(_editss);
      _aktedit := _pedit[_editss];
      ActiveControl := _aktedit;
    end else ActiveControl := UjptOkeGomb;
end;

procedure TPenztarValasztoForm.ujptokegombClick(Sender: TObject);

var _y: byte;

begin
  _y := 1;
  while _y<=3 do
    begin
      _aktedit := _pedit[_y];
      _aktText := trim(_aktedit.text);
      if _aktText='' then
        begin
          ActiveControl := _aktedit;
          exit;
        end;
      inc(_y);
    end;

  _pnums := trim(Pszamedit.text);
  _pcs := 'SELECT * FROM PENZTAR WHERE PENZTARKOD='+chr(39)+_pNums+chr(39);

  ValutaDbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
      Close;
    end;
  ValutaDbase.close;

  if _recno>0 then
    begin
      ShowMessage('ILYEN SZÁMÚ PÉNZTÁR MÁR LÉTEZIK');
      aCTIVECONTROL := PszamEdit;
      exit;
    end;

  _pnums := trim(pszamedit.text);
  _pnev  := trim(pnevedit.text);
  _pcim  := trim(pcimedit.text);
  _ptel  := trim(pteledit.text);

  _pcs := 'INSERT INTO PENZTAR (PENZTARKOD,PENZTARNEV,PENZTARCIM,TELEFONSZAM)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + chr(39) + _pnums + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pnev + chr(39) + ',';
  _pcs := _pcs + chr(39) + _pcim + chr(39) + ',';
  _pcs := _pcs + chr(39) + _ptel + chr(39) + ')';

  Valutadbase.connected := True;
  if ValutaTranz.Intransaction then ValutaTranz.commit;
  ValutaTranz.StartTransaction;

  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      ExecSql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;

  // ---------------------------------------------------------------------------

  UjPenztarPanel.Visible := False;

  Valutadbase.connected := true;
  RacsMegnyitas;
end;


procedure TPenztarValasztoForm.UJPTMEGSEMGOMBClick(Sender: TObject);
begin
  UjPenztarPanel.visible := False;
  ValutaDbase.Connected := True;
  Racsmegnyitas;
end;

procedure TpenztarValasztoForm.TRbBekeres;

begin
  TrbPtedit.clear;
  with TrbBekeroPanel do
    begin
      top := 200;
      left := 144;
      Visible := true;
    end;
    
  Activecontrol := TrbPtedit;
end;


procedure TPenztarValasztoForm.TRBPTEDITKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  IF ord(key)<>13 then exit;
  Activecontrol := TrbPtOkegomb;
end;

procedure TPenztarValasztoForm.TRBPTOKEGOMBClick(Sender: TObject);
begin
  _trbpts := trim(TrbPtEdit.text);
  val(_trbpts,_trbpenztar,_code);
  if _code<>0 then _trbpenztar := 0;

  if _trbPenztar=0 then
    begin
      Modalresult := 2;
      exit;
    end;
  TrbBekeroPanel.Visible := False;
  SelectedToVtemp;
end;

procedure TPenztarValasztoForm.TRBPTMEGSEMGOMBClick(Sender: TObject);
begin
  TrbBekeroPanel.Visible := False;
  _trbpts := '';
  Modalresult := 2;
end;

procedure TPenztarValasztoForm.TRBPTEDITEnter(Sender: TObject);
begin
  TrbPtedit.Color := $B0FFFF;
end;

procedure TPenztarValasztoForm.TRBPTEDITExit(Sender: TObject);
begin
  TrbPtedit.Color := clWindow;
end;

end.
