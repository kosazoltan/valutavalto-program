unit Unit3;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, strutils;

type
  TReadTimeForm = class(TForm)

    Panel1        : TPanel;
    DolgozoLista  : TListBox;
    TartalomLista : TListBox;
    VisszaGomb    : TBitBtn;
    SignQuery     : TIBQuery;
    SignDbase     : TIBDatabase;
    SignTranz     : TIBTransaction;
    Label1        : TLabel;
    Label2        : TLabel;
    Label3        : TLabel;
    ReadEdit      : TEdit;

    procedure AdatValtozas;
    procedure FormActivate(Sender: TObject);
    procedure DolgozoListaClick(Sender: TObject);
    procedure DolgozoListaKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure Readtimedisplay;
    procedure VisszaGombClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ReadTimeForm: TReadTimeForm;

  _aktdolgozosorszam,_aktTartalomSorszam: word;
  _dIndex,_tIndex: word;

  _lett: array[0..500] of word;
  _when: array[0..500] of string;

implementation

uses Unit1;

{$R *.dfm}

// ============================================================================
          procedure TReadTimeForm.visszagombClick(Sender: TObject);
// ============================================================================

begin
  SignQuery.close;
  Signdbase.close;
  ModalResult := 1;
end;

// ============================================================================
         procedure TREADTIMEFORM.FormActivate(Sender: TObject);
// ============================================================================

var _y: word;

begin
  Form1.DolgozokTombbe;
  Form1.TartalomTombbe;

  SignDbase.close;
  SignDbase.DatabaseName := _serverFdbPath;
  SignDbase.Connected := true;

  Dolgozolista.Items.Clear;
  DolgozoLista.Clear;

  _y := 0;
  while _y<_dolgozoDarab do
    begin
      DolgozoLista.Items.add(_pnev[_y]);
      inc(_y);
    end;
  DolgozoLista.ItemIndex := 0;
  _aktdolgozoSorszam := _psor[0];

  //--------------------------------------------------

  Tartalomlista.clear;
  Tartalomlista.Items.clear;
  _y := 0;
  while _y<_tartalomdarab do
    begin
      Tartalomlista.Items.add(_kltart[_y]);
      inc(_y);
    end;
  Tartalomlista.ItemIndex := 0;
  _aktTartalomsorszam := _klsors[0];

  ReadTimeDisplay;

  Activecontrol := Dolgozolista;
  Dolgozolista.SetFocus;

end;

// ============================================================================
            procedure TReadTimeForm.Readtimedisplay;
// ============================================================================

var _readstring,_whenstring: string;

begin
  _readstring := 'NEM OLVASTA';

  _pcs := 'SELECT * FROM ' + _readSignName + _sorveg;
  _pcs := _pcs + 'WHERE (DOLGSORSZAM=' + inttostr(_aktDolgozoSorszam)+')';
  _pcs := _pcs + ' AND (LETTERNUM=' + inttostr(_aktTartalomsorszam)+')';

  with SignQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _recno := recno;
    end;
  if _recno>0 then
    begin
      _whenstring := trim(Signquery.fieldbyname('MIKOR').asstring);
      _readstring := inttostr(_aktev)+'.'+leftstr(_whenstring,2)+'.'+midstr(_whenstring,3,2)+'-n ';
      _readstring := _readstring + midstr(_whenstring,5,2)+' óra '+midstr(_whenstring,7,2)+' perckor';
    end;
  Signquery.close;
  Readedit.text := _readstring;
  readEdit.repaint;
end;

// ============================================================================
        procedure TREADTIMEFORM.DOLGOZOLISTAClick(Sender: TObject);
// ============================================================================

begin
  adatValtozas;
end;

// ============================================================================
   procedure TREADTIMEFORM.DOLGOZOLISTAKeyDown(Sender: TObject; var Key: Word;
                                                    Shift: TShiftState);
// ============================================================================

begin
  Adatvaltozas;
end;

// ============================================================================
                     procedure TReadTimeForm.AdatValtozas;
// ============================================================================

begin
  _dIndex := DolgozoLista.itemindex;
  _aktdolgozosorszam := _psor[_dIndex];

  _tIndex := TartalomLista.itemindex;
  _aktTartalomsorszam := _klSors[_tIndex];

  ReadTimeDisplay;
end;

end.
