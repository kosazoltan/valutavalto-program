unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery;

type
  TForm2 = class(TForm)
    ALAPLAP: TPanel;
    Label1: TLabel;
    VALUTANEVPANEL: TPanel;
    ARFNEVLABEL: TLabel;
    AKTARFOLYAMPANEL: TPanel;
    Label3: TLabel;
    KEDVARFOLYAMEDIT: TEdit;
    Label4: TLabel;
    ELSZAMOLOPANEL: TPanel;
    JELSZOKEROGOMB: TBitBtn;
    ENGEDELYGOMB: TBitBtn;
    MEGSEMGOMB: TBitBtn;
    Shape1: TShape;
    UZENOPANEL: TPanel;
    Label5: TLabel;
    SZAZALEKPANEL: TPanel;
    KQUERY: TIBQuery;
    KDBASE: TIBDatabase;
    KTRANZ: TIBTransaction;
    KILEPO: TTimer;
    fuggony: TPanel;
    BIGPERCENTPANEL: TPanel;
    Label2: TLabel;
    Label6: TLabel;

    procedure FormActivate(Sender: TObject);
    procedure MEGSEMGOMBClick(Sender: TObject);
    procedure Bigszazalekrutin;

    function AdatBeolvasasVtempbol: boolean;
    procedure KEDVARFOLYAMEDITEnter(Sender: TObject);
    procedure KEDVARFOLYAMEDITExit(Sender: TObject);
    procedure AdatKijelzes;
    procedure KILEPOTimer(Sender: TObject);
    procedure Kparancs(_ukaz: string);

    procedure KEDVARFOLYAMEDITKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure JELSZOKEROGOMBClick(Sender: TObject);
    procedure ENGEDELYGOMBClick(Sender: TObject);

    function ArfolyamKontrol: boolean;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _aktsoreng,_bill: byte;
  _top,_left,_height,_width: word;
  _mResult,_recno,_aktarfolyam,_aktelszarf,_code,_kedvarfolyam,_szazalek,_SPK: integer;
  _ok: boolean;
  _pcs,_aktdnem,_aktdnev,_akttipus,_mess: string;
  _sorveg: string = chr(13)+chr(10);


function bigarfolyamkedvezmeny: integer; stdcall;
Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll';
function supervisorjelszo(_para: byte): integer;stdcall;
                    external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';


implementation

{$R *.dfm}

// =============================================================================
           function bigarfolyamkedvezmeny: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  Form2.Free;
end;


// =============================================================================
                procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top  := round((_height-460)/2);
  _left := round((_width-557)/2);

  Top      := _top;
  Left     := _Left;
  Width    := 557;
  Height   := 460;

  with Fuggony do
    begin
      Top     := 64;
      Left    := 24;
      Visible := True;
      Repaint;
    end;

  _mResult := -1;
  Repaint;

  _ok := AdatBeolvasasVtempbol;
  if not _ok then
    begin
      Kilepo.Enabled := True;
      Exit;
    end;

   AdatKijelzes;
   ActiveControl := KedvArfolyamEdit;
end;

// =============================================================================
           procedure TForm2.MegsemGombClick(Sender: TObject);
// =============================================================================

begin
  ModalResult := -1;
end;

// =============================================================================
              function TForm2.AdatBeolvasasVtempbol: boolean;
// =============================================================================

begin
  Result := False;
  _pcs := 'SELECT * FROM VTEMP WHERE MEGJEGYZES='+chr(39)+'!' + chr(39);

  Kdbase.Connected := true;
  with KQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      _recno := Recno;
    end;

  if _recno=0 then
    begin
      KQuery.close;
      Kdbase.close;
      UzenoPanel.Caption := 'Nincs valuta kijelölve';
      UzenoPanel.repaint;
      Sleep(2500);
      Exit;
    end;

  _aktDnem     := trim(KQuery.fieldbyname('VALUTANEM').asString);
  _aktDnev     := trim(KQuery.fieldbyname('VALUTANEV').asString);
  _aktArfolyam := Kquery.fieldByName('ARFOLYAM').asInteger;
  _aktelszarf  := KQuery.fieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
  _aktTipus    := Kquery.FieldByNAme('TIPUS').asString;
  _aktSoreng   := KQuery.FieldByNAme('SORENGEDMENY').asInteger;
  if _aktsoreng>0 then
    begin
      UzenoPanel.caption := 'A kijelölt arfolyam már kedvezményes';
      UzenoPanel.repaint;
      Sleep(2500);
      Exit;
    end;
   Result := True;
end;

// =============================================================================
           procedure TForm2.KedvArfolyamEditEnter(Sender: TObject);
// =============================================================================

begin
  TEdit(sender).Color := clYellow;
end;

// =============================================================================
           procedure TForm2.KedvArfolyamEditExit(Sender: TObject);
// =============================================================================

begin
  TEdit(Sender).Color := clWindow;
end;

// =============================================================================
                   procedure Tform2.AdatKijelzes;
// =============================================================================

begin
   ValutanevPanel.caption := _aktdnev;
   if _akttipus='V' then ArfNevLabel.caption := ' VÉTELI ÁRFOLYAM:'
   else ArfNevLabel.Caption := 'ELADÁSI ÁRFOLYAM';

   AktArfolyamPanel.Caption := inttostr(_aktArfolyam);
   ElszamoloPanel.Caption := inttostr(_aktElszarf);
   Fuggony.Visible := false;
   Repaint;
end;

// =============================================================================
           procedure TForm2.KilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  ModalResult := _mResult;
end;

// =============================================================================
     procedure TForm2.KEDVARFOLYAMEDITKeyDown(Sender: TObject; var Key: Word;
                                                          Shift: TShiftState);
// =============================================================================

var _kedvs: string;

begin
  _bill := ord(key);
  if (_bill>47) and (_bill<58) then exit;

  if _bill=13 then
    begin
      _kedvs := trim(KedvArfolyamEdit.Text);
      val(_kedvs,_kedvarfolyam,_code);
      if _code<>0 then exit;
      if _Kedvarfolyam<1 then exit;

      if not arfolyamkontrol then
        begin
          Kedvarfolyamedit.Clear;
          Activecontrol := Kedvarfolyamedit;
          exit;
        end;

      _szazalek := round(100*(_kedvarfolyam/_aktarfolyam)-100);
      _szazalek := abs(_szazalek);

      SzazalekPanel.Caption := inttostr(_szazalek)+' %';
      JelszoKerogomb.Enabled := True;
      ActiveControl := JelszoKeroGomb;
    end;
end;


// =============================================================================
              function TForm2.ArfolyamKontrol: boolean;
// =============================================================================

begin
  result := False;
  if _akttipus='V' then
    begin
      if _kedvarfolyam>_aktelszarf then
        begin
          _mess := 'Vételi árfolyam nem lehet nagyobb az elsz-i árfolyamnál';
          ShowMessage(_mess);
          exit;
        end;

      if _kedvarfolyam<_aktarfolyam then
        begin
          _mess := 'Ez nem kedvezmény !';
          ShowMessage(_mess);
          Kedvarfolyamedit.Clear;
          ActiveControl := KedvArfolyamedit;
          exit;
        end;
    end;

  // ------------------------------------------------------------------

  if _akttipus='E' then
    begin
      if _kedvarfolyam<_aktelszarf then
        begin
          _mess := 'Eladási árfolyam nem lehet kisebb az elsz-i árfolyamnál';
          ShowMessage(_mess);
          Kedvarfolyamedit.Clear;
          ActiveControl := KedvArfolyamedit;
          exit;
        end;

      if _kedvarfolyam>_aktarfolyam then
        begin
          _mess := 'Ez nem kedvezmény !';
          ShowMessage(_mess);
          Kedvarfolyamedit.Clear;
          ActiveControl := KedvArfolyamedit;
          exit;
        end;
    end;

  result := True;

end;

// =============================================================================
           procedure TForm2.JelszokeroGombClick(Sender: TObject);
// =============================================================================

var _spk: integer;

begin
  JelszokeroGomb.Enabled := False;
  _spk := supervisorjelszo(1);
  if _spk<>1 then
    begin
      Kilepo.enabled := true;
      Exit;
    end;

  If _szazalek>=2 then
    begin
      BigSzazalekRutin;
      exit;
    end;

  EngedelyGomb.enabled := true;
  ActiveControl := EngedelyGomb;
end;

// =============================================================================
                      procedure TForm2.Bigszazalekrutin;
// =============================================================================

begin
  with BigPercentPanel do
    begin
      top := 10;
      Left := 32;
      Visible := True;
      repaint;
    end;

  _spk := supervisorjelszo(1);
  if _spk<>1 then
    begin
      BigPercentPanel.visible := False;
      Kilepo.enabled := true;
      Exit;
    end;

  BigPercentPanel.visible := False;  
  EngedelyGomb.enabled := true;
  ActiveControl := EngedelyGomb;
end;
      



// =============================================================================
           procedure TForm2.EngedelyGombClick(Sender: TObject);
// =============================================================================

begin
  _pcs := 'UPDATE VTEMP SET ARFOLYAM=' + inttostr(_kedvArfolyam);
  _pcs := _pcs + ',KEDVEZMENYESARFOLYAM=' + inttostr(_kedvArfolyam);
  _pcs := _pcs + ',SORENGEDMENY=8' + _sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktDnem + chr(39);
  KParancs(_pcs);

  _pcs := 'UPDATE VTEMP SET RATETYPE=8';
  KParancs(_pcs);

  _mResult := 1;
  UzenoPanel.Caption := 'Az engedmény megadva';
  UzenoPanel.repaint;

  _mess := 'Arfolyam kedvezmény jelszóval: ' +_aktdnem + ' új árf: '+inttostr(_kedvarfolyam);
  logirorutin(pchar(_mess));

  Sleep(500);
  Kilepo.Enabled := True;
end;

// =============================================================================
                  procedure TForm2.KParancs(_ukaz: string);
// =============================================================================

begin
  Kdbase.Connected := true;
  if Ktranz.InTransaction then KTranz.Commit;
  Ktranz.StartTransaction;
  with KQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_ukaz);
      Execsql;
    end;
  KTranz.Commit;
  Kdbase.close;
end;

end.
