unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, IBDatabase, IBCustomDataSet, IBQuery, Buttons,
  Grids, DBGrids, ExtCtrls, strutils;

type
  TMNBDISPLAY = class(TForm)
    Button1: TButton;
    RACSPANEL: TPanel;
    MNBRACS: TDBGrid;
    KFTPANEL: TPanel;
    KORZETPANEL: TPanel;
    IRODANEVPANEL: TPanel;
    DATUMPANEL: TPanel;
    MNBQUERY: TIBQuery;
    MNBDBASE: TIBDatabase;
    MNBTRANZ: TIBTransaction;
    MNBSOURCE: TDataSource;
    MNBQUERYIRODASZAM: TIntegerField;
    MNBQUERYERTEKTAR: TIntegerField;
    MNBQUERYVALUTANEM: TIBStringField;
    MNBQUERYNYITO: TFloatField;
    MNBQUERYVETEL: TFloatField;
    MNBQUERYELADAS: TFloatField;
    MNBQUERYHIANY: TFloatField;
    MNBQUERYTOBBLET: TFloatField;
    MNBQUERYBANKIATVETEL: TFloatField;
    MNBQUERYBANKIATADAS: TFloatField;
    MNBQUERYPENZTARIKIADAS: TFloatField;
    MNBQUERYPENZTARIATVETEL: TFloatField;
    MNBQUERYZARO: TFloatField;
    MNBQUERYSZAMITOTTZARO: TFloatField;
    MNBQUERYVETELDARAB: TIntegerField;
    MNBQUERYELADASDARAB: TIntegerField;
    MNBQUERYIRODADNEM: TIBStringField;
    MNBQUERYVISSZAPLUSZ: TFloatField;
    MNBQUERYVISSZAMINUSZ: TFloatField;
    MNBQUERYMEGJEGYZES: TIBStringField;
    MNBQUERYCEGBETU: TIBStringField;
    MNBQUERYBANKKARTYA: TIntegerField;
    KILEPESGOMB: TBitBtn;
    KILEPO: TTimer;
    RECEPTORQUERY: TIBQuery;
    RECEPTORDBASE: TIBDatabase;
    RECEPTORTRANZ: TIBTransaction;
    ARTQUERY: TIBQuery;
    ARTDBASE: TIBDatabase;
    ARTTRANZ: TIBTransaction;
    MASEGYSEGGOMB: TBitBtn;
    BitBtn2: TBitBtn;
    Shape1: TShape;

    procedure Button1Click(Sender: TObject);
    procedure KILEPESGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);
    procedure IdoszakDisplay;
    procedure FejlecDisplay;
    procedure KFTDisplay;
    procedure IrodaBetoltes;

    function Getfilter: string;
    function GetIdoszak: boolean;
    function ScanKorzet(_k: byte): string;
    procedure MASEGYSEGGOMBClick(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MNBDISPLAY: TMNBDISPLAY;
  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
             'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
             'NOVEMBER','DECEMBER');

  _knev: array[1..9] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT','DEBRECEN',
           'NYÍREGYHÁZ','BÉKÉSCSABA','PÉCS','KAPOSVÁR','ZÁLOGHÁZ');

  _kszam: array[1..9] of byte = (10,20,40,50,63,75,120,145,180);
  _pTarnev: array[1..180] of string;

  _filter,_pcs,_datumtols,_datumigs,_ceg,_korzetnev,_irodanev,_fceg: string;
  _korzet: integer;
  _iroda,_ftipus,_firoda: byte;
  _fkorzet: integer;

  _sorveg: string = chr(13)+chr(10);

  _mResult,_code: integer;



function datadisplay: integer; stdcall;

implementation

function datadisplay: integer; stdcall;

begin
  mnbdisplay := TMNBdisplay.create(Nil);
  result := mnbdisplay.showmodal;
  mnbdisplay.free;
end;




{$R *.dfm}

// =============================================================================
             procedure TMNBDISPLAY.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top    := 158;
  Left   := 208;
  Height := 684;
  Width  := 1080;

  MNBsource.Enabled := False;

  _filter := Getfilter;

  if _filter='' then
    begin
      Showmessage('Nincs kijelölt egység !');
      _mResult := 1;
      Kilepo.enabled := true;
      exit;
    end;

  if not Getidoszak then
    begin
      Showmessage('Nincs megadva az idõszak');
      _mResult := 2;
      Kilepo.enabled := true;
      exit;
    end;

   IrodaBetoltes;
   IdoszakDisplay;
   
  _pcs := 'SELECT * FROM MNB' + _sorveg;
  _pcs := _pcs + 'WHERE ' + _filter + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  MNBDbase.Connected := true;
  with MNBquery do
    begin
      CLose;
      sql.clear;
      sql.add(_pcs);
      Open;
    end;
  MNBSource.Enabled := True;
  Fejlecdisplay;
  MNBracs.SetFocus;
end;

// =============================================================================
                   function TMNBDisplay.Getfilter: string;
// =============================================================================

var _ffilter: string;

begin
  _pcs := 'SELECT * FROM ADATATADO' + _sorveg;

  ReceptorDbase.connected :=  True;
  with ReceptorQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _ftipus := FieldByNAme('TIPUS').asInteger;
      _firoda := FieldByName('IRODA').asInteger;
      _fkorzet:= FieldByNAme('KORZET').asInteger;
      _fceg   := trim(FieldByNAme('CEGBETU').asString);
      _ffilter:= trim(FieldByName('SZURO').AsString);
      close;
    end;
  ReceptorDbase.close;
  if _ftipus=3 then _ffilter := _ffilter + chr(39)+_fceg+chr(39)+')';

  result := _ffilter;

{

  // -----------------------------------------------------------------

  result := '';

  case _ftipus of
    1: result := '(IRODASZAM='+inttostr(_firoda)+') AND (ERTEKTAR>0)';
    2: result := '(ERTEKTAR=-1)';
    3: result := '(CEGBETU=' + chr(39)+_fceg+chr(39)+') AND (ERTEKTAR=0)';
    4: result := '(IRODASZAM=0) AND (ERTEKTAR=' +inttostr(_fkorzet)+')';
  end;


}

end;

// =============================================================================
               function TMNBDisplay.GetIdoszak: boolean;
// =============================================================================

begin
  RESULT := FALSE;

  _pcs := 'SELECT * FROM IDOSZAK' + _sorveg;

  Receptordbase.connected :=  True;
  with ReceptorQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      _datumtols := FieldByNAme('STARTDATE').asString;
      _datumigs  := FieldByNAme('ENDDATE').asString;
      close;
    end;
  ReceptorDbase.close;

  if (_datumtols='') or (_datumigs='') then exit;
  result := true;


end;

// =============================================================================
                  procedure TMNBDisplay.IdoszakDisplay;
// =============================================================================

var _evs,_tols,_igs,_hos,_idszcim: string;
    _ho,_tol,_ig: byte;

begin
  _evs := leftstr(_datumtols,4);
  _hos := midstr(_datumtols,6,2);
  _tols := midstr(_datumtols,9,2);
  _igs := midstr(_datumigs,9,2);
  val(_hos,_ho,_code);
  val(_tols,_tol,_code);
  val(_igs,_ig,_code);
  _idszcim := _evs+' '+_honev[_ho]+' '+inttostr(_tol)+' ÉS '+inttostr(_ig)+' KÖZÖTT';
  DatumPanel.caption := _idszcim;
  Datumpanel.repaint;
end;

// =============================================================================
            procedure TMNBDISPLAY.Button1Click(Sender: TObject);
// =============================================================================

begin
  mODALRESULT := 1;
end;

// =============================================================================
          procedure TMNBDISPLAY.KILEPESGOMBClick(Sender: TObject);
// =============================================================================

begin
  _mResult := -1;
  Kilepo.Enabled := true;
end;


// =============================================================================
            procedure TMNBDISPLAY.KILEPOTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := False;
  Modalresult := _mResult;
end;

// =============================================================================
                    procedure TMNBDisplay.FejlecDisplay;
// =============================================================================

begin
  with MNBQuery do
    begin
      _ceg := FieldByNAme('CEGBETU').asString;
      _korzet := FieldByNAme('ERTEKTAR').asInteger;
      _iroda := FieldByName('IRODASZAM').asInteger;
    end;

  if _korzet>0 then _korzetnev := ScanKorzet(_korzet);

  // A teljes cég (zálog nélkül):

  if _korzet = -1 then
    begin
      irodanevPanel.caption := 'A TELJES CÉG';
      korzetPanel.caption := 'ÖSSZES KÖRZET';
      kftpanel.caption := 'EXCLUSIVE CHANGE';
      Racspanel.repaint;
      exit;
    end;

  // Egy kft adatai:

  if (_korzet=0) then
    begin
      KorzetPanel.caption := '';
      Kftdisplay;
      RacsPanel.repaint;
      IrodanevPanel.caption := '';
      exit;
    end;

  // Egy körzet adatai:

  if _iroda=0 then
    begin
      KorzetPanel.caption := _korzetnev + 'I KÖRZET';
      Irodanevpanel.caption := '';
      KftDisplay;
      exit;
    end;

  // Egy pénztár adatai:

  _irodanev := _ptarnev[_iroda];
  IrodanevPanel.Caption := inttostr(_iroda)+'. '+_irodanev;
  KorzetPanel.caption := _korzetnev + 'I KÖRZET';
  KftDisplay;
end;

// =============================================================================
              function TMNBDisplay.ScanKorzet(_k: byte): string;
// =============================================================================

var _y: byte;

begin
  _y := 1;
  while _y<=9 do
    begin
      if _k=_kszam[_y] then
        begin
          result := _knev[_y];
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                     procedure TMNBDisplay.KftDisplay;
// =============================================================================

begin
  if _ceg='' then
    begin
      KFTPANEL.caption := '';
      KftPanel.repaint;
      exit;
    end;

  if _ceg='B' then _ceg := 'BEST';
  if _ceg='E' then _ceg := 'EAST';
  if _ceg='P' then _ceg := 'PANNON';
  if _ceg='Z' then _ceg := 'EXPRESSZ';

  KftPanel.caption := _ceg + ' KFT';
  KftPanel.repaint;
end;

procedure TMNBDisplay.Irodabetoltes;

var _u: byte;
    _s: string;

begin
  ReceptorDbase.connected := True;
  _pcs := 'SELECT * FROM IRODAK';
  with ReceptorQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
    end;

  while not ReceptorQuery.Eof do
    begin
      _u := ReceptorQuery.FieldByName('UZLET').asInteger;
      _s := trim(ReceptorQuery.FieldByName('KESZLETNEV').asString);
      _ptarnev[_u] := _s;
      ReceptorQuery.next;
    end;
  receptorQuery.close;
  receptordbase.close;

  // ---------------------------------------------------

  ArtDbase.connected := True;
  with ArtQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
    end;

  while not ArtQuery.Eof do
    begin
      _u := ArtQuery.FieldByName('UZLET').asInteger;
      _s := trim(ArtQuery.FieldByName('KESZLETNEV').asString);
      _ptarnev[_u] := _s;
      ArtQuery.next;
    end;
  ArtQuery.close;
  Artdbase.close;
end;


procedure TMNBDISPLAY.MasEgysegGombClick(Sender: TObject);
begin
  MNBQuery.close;
  MNBdbase.close;
  _mresult := 1;
  Kilepo.enabled := true;
end;

procedure TMNBDISPLAY.BitBtn2Click(Sender: TObject);
begin
  MNBQuery.close;
  MNBdbase.close;
  _mresult := 2;
  Kilepo.enabled := true;
end;

end.
