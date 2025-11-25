unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TGETPLOMBASZAM = class(TForm)
    Panel1: TPanel;
    SZALLNEVEDIT: TEdit;
    PLOMBAEDIT: TEdit;
    MEGJEGYZESEDIT: TEdit;
    KONYVELHETOGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    TARSSZAMPANEL: TPanel;
    TARSNEVPANEL: TPanel;
    Shape1: TShape;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    procedure FormActivate(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure SZALLNEVEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure PLOMBAEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MEGJEGYZESEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure KONYVELHETOGOMBClick(Sender: TObject);
    procedure SZALLNEVEDITEnter(Sender: TObject);
    procedure SZALLNEVEDITExit(Sender: TObject);
    procedure Penztarbeolvasas;
    procedure EmptyControl;


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETPLOMBASZAM: TGETPLOMBASZAM;
  _top,_left,_height,_width: word;
  _szallitonev,_plombaszam,_megjegyzes,_aktpenztarszam,_aktPenztarnev: string;
  _pcs: string;
  _sorveg: string = chr(13)+chr(10);
  _recno: integer;


function getplombarutin: integer; stdcall;

implementation

{$R *.dfm}


function getplombarutin: integer; stdcall;

begin
  GetPlombaszam := TGetplombaszam.Create(Nil);
  result := Getplombaszam.ShowModal;
  GetPlombaszam.Free;
end;  


// =============================================================================
             procedure TGETPLOMBASZAM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _top  := trunc((_height-144)/2);
  _left := trunc((_width-520)/2);

  Top   := _top;
  Left  := _left;
  height:= 144;
  Width := 520;

  _szallitonev := '';
  _plombaszam := '';
  _megjegyzes := '';

  PenztarBeolvasas;

  TarsszamPanel.Caption := _aktpenztarszam;
  TarsNevPanel.Caption  := _aktPenztarNev;
  Szallnevedit.Clear;
  PlombaEdit.Clear;
  MegjegyzesEdit.Clear;
  ActiveControl := Szallnevedit;
end;

// =============================================================================
             procedure TGETPLOMBASZAM.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;

// =============================================================================
        procedure TGETPLOMBASZAM.SZALLNEVEDITKeyDown(Sender: TObject;
                                          var Key: Word; Shift: TShiftState);
// =============================================================================

var _bill: byte;

begin
  _bill := ord(key);
  if (_bill<>13) and (_bill<>40) then exit;
  ActiveControl := PlombaEdit;
end;

// =============================================================================
    procedure TGETPLOMBASZAM.PLOMBAEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

var _bill: byte;

begin
  _bill := ord(key);
  if (_bill=38) then
    begin
      ActiveControl := Szallnevedit;
      Exit;
    end;

  if (_bill=13) or (_bill=40) then
    begin
      ActiveControl := Megjegyzesedit;
      Exit;
    end;
end;

// =============================================================================
        procedure TGETPLOMBASZAM.MEGJEGYZESEDITKeyDown(Sender: TObject;
                                           var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  ActiveControl := KonyvelhetoGomb;
end;

// =============================================================================
          procedure TGETPLOMBASZAM.KONYVELHETOGOMBClick(Sender: TObject);
// =============================================================================

begin
  _szallitonev := Szallnevedit.Text;
  if _szallitonev='' then
    begin
      ActiveControl := Szallnevedit;
      exit;
    end;

  _plombaszam := Plombaedit.Text;
  if _plombaszam='' then
    begin
      ActiveControl := Plombaedit;
      Exit;
    end;

  _megjegyzes := TRIM(Megjegyzesedit.Text);

  EmptyControl;

  _pcs := 'UPDATE VTEMP SET SZALLITONEV='+chr(39)+_szallitonev+chr(39);
  _pcs := _pcs + ',PLOMBASZAM='+chr(39)+_plombaszam+chr(39);
  _pcs := _pcs + ',MEGJEGYZES=' + chr(39)+ _megjegyzes + chr(39);

  ValutaDbase.connected := true;
  if valutaTranz.InTransaction then ValutaTranz.commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      ExecSql;
    end;
  ValutaTranz.Commit;
  Valutadbase.close;

  ModalResult := 1;
end;

// =============================================================================
           procedure TGETPLOMBASZAM.SZALLNEVEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).color := $B0FFFF;
end;

// =============================================================================
           procedure TGETPLOMBASZAM.SZALLNEVEDITExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWindow;
end;

procedure TGetPlombaszam.Penztarbeolvasas;

begin
  _pcs := 'SELECT * FROM VTEMP';
  ValutaDbase.Connected := True;
  with valutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _aktpenztarszam := trim(FieldByNAme('PENZTARKOD').AsString);
      _aktpenztarnev  := trim(FieldByNAme('TARSPENZTARNEV').AsString);
      Close;
    end;
  Valutadbase.close;
end;

procedure TGetPlombaszam.EmptyControl;

begin
  Valutadbase.connected := true;
  if Valutatranz.InTransaction then valutatranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      First;
      _recno := recno;
      Close;
    end;
   if _recno=0 then
     begin
       _pcs := 'INSERT INTO VTEMP (MENET)' + _sorveg;
       _pcs := _pcs + 'VALUES (1)';
       with ValutaQuery do
         begin
           Close;
           sql.clear;
           sql.Add(_pcs);
           Execsql;
         end;
     end;
   ValutaTranz.commit;
   valutadbase.close;
end;

end.
