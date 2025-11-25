unit Unit2;


interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, StrUtils, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TARFOLYAMVALTOZTATAS = class(TForm)

    IbQuery          : TibQuery;
    IbDbase          : TibDatabase;
    IbTranz          : TibTransaction;

    AlapArfolyamPanel: TPanel;
    KedvTextPanel    : TPanel;
    Panel2           : TPanel;
    Panel7           : TPanel;
    SzazalekPanel    : TPanel;
    ValutaNevPanel   : TPanel;

    UjArfolyamEdit   : TEdit;

    ArfModiOkeGomb   : TBitBtn;
    ArfModiCancelGomb: TBitBtn;
    EngedelyGomb     : TBitBtn;

    Label1           : TLabel;
    Label2           : TLabel;

    procedure FormActivate(Sender: TObject);
    procedure ArfModiOkeGombClick(Sender: TObject);
    procedure ArfModiCancelGombClick(Sender: TObject);

    procedure EngedelyGombClick(Sender: TObject);
    procedure UjArfolyamEditEnter(Sender: TObject);
    procedure UjArfolyamEditExit(Sender: TObject);
    procedure UjArfolyamEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ArfolyamValtoztatas: TArfolyamValtoztatas;

  _sorveg: string = chr(13)+chr(10);

  _spk: byte;

  _top,_left,_width,_height: word;

  _aktdnem,_aktdnev,_szazs,_ujarfs,_pcs,_elojel,_tipus: string;

  _workarfolyam,_minarfolyam,_maxarfolyam,_elszamarf,_aktarfolyam,_code: integer;
  _mresult,_szaz: integer;

  _jelszavas: boolean;

Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';
function supervisorjelszo(_para: byte): integer;stdcall;
                    external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';

function arfvaltrutin(_para: string): integer; stdcall;

implementation

{$R *.dfm}


// =============================================================================
         function arfvaltrutin(_para: string): integer; stdcall;
// =============================================================================

begin
  ArfolyamValtoztatas := TarfolyamValtoztatas.Create(Nil);
  _aktdnem := _para;
  result := Arfolyamvaltoztatas.ShowModal;
  Arfolyamvaltoztatas.Free;
end;


// =============================================================================
          procedure TARFOLYAMVALTOZTATAS.FormActivate(Sender: TObject);
// =============================================================================

begin
 ///////// _aktdnem := 'EUR';

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top  := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);


  Top    := 230 + _top;
  Left   := 320 + _left;

  Height := 270;
  Width  := 411;

  _mresult := -1;

  ArfModiOkeGomb.Enabled  := False;
  EngedelyGomb.Enabled    := False;
  UjarfolyamEdit.Text     := '';
  Ujarfolyamedit.ReadOnly := False;

  logirorutin(pchar('Egy tétel árfolyamára klikkelt. Módositani akarja'));

  _pcs := 'SELECT * FROM VTEMP WHERE VALUTANEM=' +chr(39)+_aktdnem+chr(39);
  ibdbase.Connected := true;
  with ibquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _aktarfolyam := Fieldbyname('ARFOLYAM').asInteger;
      _elszamarf   := FieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
      _tipus       := FieldByNAme('TIPUS').asString;
      _aktdnev     := trim(FieldByNAme('VALUTANEV').asString);
      close;
    end;
  ibdbase.close;

  ValutanevPanel.Caption := _aktdnev;
  AlaparfolyamPanel.Caption := inttostr(_aktArfolyam);
  AlaparfolyamPanel.repaint;

  UjarfolyamEdit.clear;
  ActiveControl := Ujarfolyamedit;
end;

// =============================================================================
     procedure TARFOLYAMVALTOZTATAS.UJARFOLYAMEDITKeyDown(Sender: TObject;
                                            var Key: Word; Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _ujarfs := trim(Ujarfolyamedit.text);
  if _ujarfs='' then exit;

  val(_ujarfs,_workarfolyam,_code);
  if _code<>0 then _workArfolyam := 0;
  if _workarfolyam=0 then exit;

  if (_workarfolyam>=_elszamarf) and (_tipus='V') then
     begin
       Showmessage('Kedvezményes árfolyam nem lehet nagyobb az elszámolásinál');
       exit;
     end;

   if (_workarfolyam<=_elszamarf) and (_Tipus='E') then
     begin
       Showmessage('Kedvezményes árfolyam nem lehet kisebb az elszámolásinál');
       exit;
     end;

   if (_workarfolyam<=_aktarfolyam) and (_Tipus='V') then
     begin
       Showmessage('Ez nem kedvezmény');
       exit;
     end;

   if (_workarfolyam>=_aktarfolyam) and (_Tipus='E') then
     begin
       Showmessage('Ez nem kedvezmény');
       exit;
     end;

  if _Tipus='V' then
    begin
      _szaz  := trunc(100*((_workarfolyam/_aktarfolyam)-1));
      _szazs := leftstr(inttostr(_szaz),4)+' %)';
    end else
    begin
      _szaz := trunc(100*((_aktarfolyam/_workarfolyam)-1));
      _szazs := leftstr(inttostr(_szaz),4)+' %)';
    end;

  SzazalekPanel.Caption := _szazs;
  EngedelyGomB.Enabled  := True;
  Activecontrol         := EngedelyGomb;
end;


// =============================================================================
        procedure TARFOLYAMVALTOZTATAS.UJARFOLYAMEDITEnter(Sender: TObject);
// =============================================================================

begin
  Ujarfolyamedit.Color := clYellow;
end;

// =============================================================================
      procedure TARFOLYAMVALTOZTATAS.UJARFOLYAMEDITExit(Sender: TObject);
// =============================================================================

begin
  Ujarfolyamedit.Color := clWhite;
end;

// =============================================================================
     procedure TarfolyamValtoztatas.ArfModiCancelGombClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('Mégsem módosit gombra kattint'));
  ModalResult := -1;
end;

// =============================================================================
       procedure TARFOLYAMVALTOZTATAS.ENGEDELYGOMBClick(Sender: TObject);
// =============================================================================

begin
  _spk := supervisorjelszo(1);
  if _spk<>1 then
    begin
      Modalresult := -1;
      Exit;
    end;

  KedvTextPanel.Visible := True;
  SzazalekPanel.Visible := True;
  EngedelyGomb.Visible := False;

  if _szaz>2 then
    begin
      ShowMessage('A kedvezény meghaladja a 2 %-ot. Igy újabb jelszó szükséges');
      _spk := supervisorjelszo(1);
      if _spk<>1 then
        begin
          Modalresult := -1;
          Exit;
        end;
    end;

  ArfmodiOkegomb.Enabled := True;
  ActiveControl          := ArfmodiOkegomb;
end;

// =============================================================================
      procedure TArfolyamValtoztatas.ArfModiOkeGombClick(Sender: TObject);
// =============================================================================

begin
  logirorutin(pchar('Modositott arfolyam rendben gombra kattint'));

  _pcs := 'UPDATE VTEMP SET KEDVEZMENYESARFOLYAM='+inttostr(_WORKarfolyam);
  _pcs := _pcs + ',SORENGEDMENY=8';
  _pcs := _pcs + ',ARFOLYAM=' + inttostr(_workarfolyam)+_sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);

  ibdbase.Connected := true;
  if ibtranz.InTransaction then ibtranz.commit;
  ibtranz.StartTransaction;
  with ibquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      ExecSql;
    end;
  ibtranz.commit;
  ibdbase.close;
  ModalResult := 1;
end;
end.

