unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery;

type
  TForm2 = class(TForm)
    ValutaQuery: TIBQuery;
    ValutaDbase: TIBDatabase;
    ValutaTranz: TIBTransaction;
    Label6: TLabel;
    ALAPLAP: TPanel;
    UZENOPANEL: TPanel;
    Label4: TLabel;
    Label5: TLabel;
    Label10: TLabel;
    FORRASCOMBO: TComboBox;
    EGYEBEDIT: TEdit;
    ENGEDELYEZOEDIT: TEdit;
    Label3: TLabel;
    RENDBENGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    Shape2: TShape;
    EGYEBTAKARO: TPanel;
    STRATEGIAPANEL: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    YESGOMB: TBitBtn;
    NOGOMB: TBitBtn;
    KILEPO: TTimer;


    procedure FormActivate(Sender: TObject);
    procedure ENGEDELYEZOEDITEnter(Sender: TObject);
    procedure ENGEDELYEZOEDITExit(Sender: TObject);
    procedure ENGEDELYEZOEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FORRASCOMBOChange(Sender: TObject);
    procedure EGYEBEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure RENDBENGOMBClick(Sender: TObject);
    procedure ValutaParancs(_ukaz: string);
    procedure NOGOMBClick(Sender: TObject);
    procedure YESGOMBClick(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _top,_left,_width,_height: word;
  _engedelyezo,_pcs,_egyebforras,_forras,_mess: string;
  _back,_forrasindex,_etipus,_mresult: integer;

  _etext: array[0..5] of string = ('Az ügyfél kiemelt közszereplö',
                      'Az ügyfél stratégiai hiányosságú országból jött',
                      'Idén másodszor vált 8 millió felett',
                      'Negyedévben 4-szer vált, már túl 25 millión',
                      'Az ügyfél 10 millió felett vált',
                      'Az ügyfél 50 millió felett vált');


Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';
function getengedelyrutin(_para: integer): integer; stdcall;

implementation

{$R *.dfm}


// Paraméter:
//
//     _eTipus = 0 -> nem kell vizsgálni
//     _etipus = 1 -> ez közszereplõ
//     _etipus = 2 -> külfõldi
//     _etipus = 3 -> idén 2-szor 8 milliós váltás
//     _etipus = 4 -> negyedévben 4 tranzakció 25 millió
//     _etipus = 5 -> 10 milla felett vált
//     _etipus = 6 -> 50 milla felett vált
//
// Visszatérés: -1= nem engedélyezett,
//               1=engedélyezett VTEMPBE: forras,engedélyezõ


// =============================================================================
           function getengedelyrutin(_para: integer): integer; stdcall;
// =============================================================================

begin
  form2 := TForm2.Create(Nil);
  _etipus := _para;
  result := Form2.showmodal;
  form2.free;
end;

// =============================================================================
                procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin

//  _etipus := 6;  ////   TESZT  !!!!!!!!!!!!!!!

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top  := 35+round((_height-273)/2);
  _left := round((_width-441)/2);

  Top   := _top;
  Left  := _left;
  with EgyebTakaro do
    begin
      Top  := 152;
      left := 16;
    end;

  logirorutin(pchar('==================== GETENGED.DLL INDUL =================='));
  case _etipus of
     0: _mess := 'nincs semmi ok';
     1: _mess := 'közszereplö';
     2: _mess := 'külföldi ügyfél';
     3: _mess := '2-szor 8 milliót vált az évben';
     4: _mess := 'negyedévben, 4 alkalommal, 25 millió felett vált';
     5: _mess := '10 millió felett vált';
     6: _mess := '50 millió felett vált';
   end;

  logirorutin(pchar('Az engedelyezõ megadásának indoka: '+ _mess));

  dec(_etipus);

  if _etipus<0 then
    begin
      _mresult := 1;
      Kilepo.Enabled := True;
      exit;
    end;

  if _etipus=1 then
    begin
      with strategiaPanel do
        begin
          top := 64;
          left := 16;
          Visible := True;
          repaint
        end;
    end;

  _engedelyezo := '';
  _egyebforras := '';
  _forras      := '';

  // vTEMP nullázása:

  _pcs := 'UPDATE VTEMP SET ENGEDELYEZO='+chr(39)+chr(39)+',FORRAS='+CHR(39)+CHR(39);
  ValutaParancs(_pcs);

  Forrascombo.ItemIndex := 0;
  Egyebedit.clear;
  Engedelyezoedit.clear;
  Rendbengomb.Enabled := False;
  Uzenopanel.Caption := _etext[_etipus];
  UzenoPanel.repaint;

  Alaplap.repaint;
  repaint;

  if _etipus=1 then ActiveControl := Nogomb
  else Activecontrol := engedelyezoedit;
end;


// =============================================================================
           procedure TForm2.ENGEDELYEZOEDITEnter(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clYellow;
end;

// =============================================================================
           procedure TForm2.ENGEDELYEZOEDITExit(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clWindow;
end;

// =============================================================================
     procedure TForm2.ENGEDELYEZOEDITKeyDown(Sender: TObject; var Key: Word;
                                                            Shift: TShiftState);
// =============================================================================

begin
  if ord(Key)<>13 then exit;

  _engedelyezo := trim(EngedelyezoEdit.Text);
  if _engedelyezo='' then
    begin
      Activecontrol := engedelyezoEdit;
      exit;
    end;
  Rendbengomb.Enabled := True;
  Activecontrol := RendbenGomb;
end;

// =============================================================================
              procedure TForm2.FORRASCOMBOChange(Sender: TObject);
// =============================================================================

begin
  _forrasindex := ForrasCombo.itemIndex;
  if _forrasIndex<8 then
    begin
      if _engedelyezo<>'' then
        begin
          ActiveControl := Rendbengomb;
          exit;
        end;
     end else
     begin
       EgyebEdit.Text := '';
       EgyebTakaro.Visible := False;
       Activecontrol := Egyebedit;
       exit;
     end;
   Activecontrol := engedelyezoedit;
end;

// =============================================================================
              procedure Tform2.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  Valutadbase.connected := True;
  if valutaTranz.InTransaction then valutaTranz.Commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.Clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.commit;
  Valutadbase.close;
end;


// =============================================================================
          procedure TForm2.EGYEBEDITKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;
  _egyebforras := trim(EgyebEdit.Text);
  if _egyebForras='' then
    begin
      Activecontrol := Egyebedit;
      exit;
    end;
  if _engedelyezo='' then Activecontrol := Engedelyezoedit
  else Activecontrol := RendbenGomb;
end;

// =============================================================================
               procedure TForm2.MEGSEMGOMBClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('- nem kapott engedélyt'));
  Modalresult := -1;
end;

// =============================================================================
               procedure TForm2.RENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('Az engedélyezés rendben gombot nyomta'));
  _forrasindex := ForrasCombo.ItemIndex;
  _engedelyezo := trim(EngedelyezoEdit.Text);
  _egyebForras := trim(EgyebEdit.text);

  if (_forrasindex=8) AND (_egyebForras='') then
    begin
      ActiveControl := EgyebEdit;
      exit;
    end;

  if _engedelyezo='' then
    begin
      ActiveControl := EngedelyezoEdit;
      exit;
    end;

  if _forrasindex=8 then _forras := _egyebForras
  else _forras := trim(Forrascombo.Items[_forrasIndex]);

  _pcs := 'UPDATE VTEMP SET FORRAS='+chr(39)+_forras+chr(39);
  _pcs := _pcs + ',ENGEDELYEZO='+chr(39)+_engedelyezo+chr(39);

  _mess := 'Forrás= '+lowercase(_forras)+', Engedélyezõ= '+lowercase(_engedelyezo);
  logirorutin(pchar(_mess));

  ValutaParancs(_pcs);
  ModalResult := 1;
end;


// =============================================================================
               procedure TForm2.NOGOMBClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('Nem hiányos stratégiai országból jött'));
  Modalresult := 1;
end;

// =============================================================================
               procedure TForm2.YESGOMBClick(Sender: TObject);
// =============================================================================

begin
  StrategiaPanel.visible := False;
  UzenoPanel.Caption := _eText[1];
  Uzenopanel.repaint;

  Alaplap.repaint;
  Activecontrol := EngedelyezoEdit;

end;

// =============================================================================
               procedure TForm2.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

end.
