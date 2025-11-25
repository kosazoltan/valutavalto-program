unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, IBDatabase, DB, IBCustomDataSet,
  IBQuery, jpeg;

type
  TGETNYUGTA = class(TForm)
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    KEZIPANEL: TPanel;
    TOVABBGOMB: TBitBtn;
    Label7: TLabel;
    ALAPPANEL: TPanel;
    ZCOUNTEDIT: TEdit;
    RECNUMEDIT: TEdit;
    Label2: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    NINCSNYUGTAGOMB: TBitBtn;
    NYOKEGOMB: TBitBtn;
    Shape4: TShape;
    Image2: TImage;
    Shape5: TShape;
    Label8: TLabel;
    Shape1: TShape;
    Label1: TLabel;
  
    procedure FormActivate(Sender: TObject);
    procedure NYOKEGOMBClick(Sender: TObject);
  
    procedure RECNUMEDITKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ZCOUNTEDITKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  
    procedure SorszamFeliro;
    procedure TOVABBGOMBClick(Sender: TObject);
    procedure NINCSNYUGTAGOMBClick(Sender: TObject);
   
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GETNYUGTA: TGETNYUGTA;
  _TOP,_left,_width,_height: word;
  _zcounts,_recnums,_pcs,_utrecnums: string;
  _sorveg: string = chr(13)+chr(10);
  _code,_recnum: integer;


function getnyugtarutin: integer; stdcall;
function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';

implementation

{$R *.dfm}

// =============================================================================
                 function getnyugtarutin: integer; stdcall;
// =============================================================================

begin
  getnyugta := TGetnyugta.Create(Nil);
  result := Getnyugta.showmodal;
  Getnyugta.Free;
end;



// =============================================================================
           procedure TGETNYUGTA.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top    := _top+140;
  Left   := _left+480;
  Width  := 450;
  Height := 490;

  Nyokegomb.Enabled := False;
  KeziPanel.Visible := False;

  _zcounts := '';
  _recnums := '';
  ZCountedit.Text := '';
  Recnumedit.Text := '';
  ActiveControl   := ZcountEdit;
end;


// =============================================================================
      procedure TGETNYUGTA.ZCOUNTEDITKeyUp(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================


var _bill: byte;
    _wz: byte;

begin
  _bill := ord(key);
  if _bill=27 then exit;

  if (_bill>95) and (_bill<106) then _bill := _bill-48;

  if (_bill>47) and (_bill<58) then
    begin
      _zcounts := trim(Zcountedit.Text);
      _wz := length(_zCounts);
      if _wz=4 then
        begin
          Activecontrol := recnumedit;
          exit;
        end;
    end;

end;


// =============================================================================
      procedure TGETNYUGTA.RECNUMEDITKeyUp(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================


var _bill: byte;
    _wr: byte;

begin
  _bill := ord(Key);
  if _bill=27 then exit;

  if (_bill>95) and (_bill<106) then _bill := _bill-48;

  if (_bill>47) and (_bill<58) then
    begin
      _recnums := trim(Recnumedit.Text);
      _wr := length(_recnums);
      if _wr=5 then
        begin
          Nyokegomb.Enabled := true;
          Activecontrol := NyokeGomb;
          exit;
        end;
    end;

  if _bill=8 then
    begin
       _recnums := trim(Recnumedit.Text);
       if _recnums='' then
         begin
           Activecontrol := Zcountedit;
           exit;
         end;
    end;
end;


// =============================================================================
             procedure TGETNYUGTA.NYOKEGOMBClick(Sender: TObject);
// =============================================================================

begin
  _zcounts := trim(Zcountedit.Text);
  _recnums := trim(Recnumedit.Text);
  SorszamFeliro;
  Modalresult := 1;
end;


// =============================================================================
                    procedure TGetnyugta.SorszamFeliro;
// =============================================================================

begin

  _pcs := 'UPDATE VTEMP SET ZCOUNTS=' + chr(39)+_zcounts + chr(39);
  _pcs := _pcs + ',RECNUMS='+chr(39)+_recnums+chr(39);

  Valutadbase.connected := True;
  if ValutaTranz.InTransaction then Valutatranz.Commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      ExecSql;
    end;

  ValutaTranz.commit;
  Valutadbase.close;
end;


procedure TGETNYUGTA.TOVABBGOMBClick(Sender: TObject);
begin
  _zcounts := '0000';
  _recnums := '00000';
  SorszamFeliro;
  ModalResult := 2;
end;

procedure TGETNYUGTA.NINCSNYUGTAGOMBClick(Sender: TObject);
begin
  with Kezipanel do
    begin
      top := 296;
      left := 44;
      Visible := True;
    end;
  Activecontrol := TovabbGomb;

end;

end.
