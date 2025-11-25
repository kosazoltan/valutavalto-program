unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons, IBDatabase, DB, IBCustomDataSet,
  IBQuery, strutils;

type
  TForm2 = class(TForm)
    CITIPANEL: TPanel;
    ORSZAGPANEL: TPanel;
    Label1: TLabel;
    CITICOMBO: TComboBox;
    CITIOKEGOMB: TBitBtn;
    CITIMEGSEMGOMB: TBitBtn;
    Label2: TLabel;
    COUNTRYCOMBO: TComboBox;
    COUNTRYOKEGOMB: TBitBtn;
    COUNTRYMEGSEMGOMB: TBitBtn;
    Shape1: TShape;
    Shape2: TShape;
    ISOQUERY: TIBQuery;
    ISODBASE: TIBDatabase;
    ISOTRANZ: TIBTransaction;
    VALUTAQUERY: TIBQuery;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    KILEPO: TTimer;

    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure VParancs(_ukaz: string);

    function TipusBeolvasas: string;
    procedure AdatBeolvasas;
    procedure KILEPOTimer(Sender: TObject);
    procedure COUNTRYMEGSEMGOMBClick(Sender: TObject);
    procedure COUNTRYCOMBOChange(Sender: TObject);
    procedure CITICOMBOChange(Sender: TObject);
    procedure COUNTRYOKEGOMBClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  _countiso,_citiziso: array[0..251] of string;
  _countnev,_citiznev: array[0..251] of string;
  _pp: word;
  _iso,_ctry,_ctz,_TIPUS,_pcs,_cnev,_totiso: string;
  _mResult,_cIndex: integer;
  _sorveg: string = chr(13)+chr(10);


function getisorutin: integer; stdcall;

implementation

{$R *.dfm}

function getisorutin: integer; stdcall;

begin
  Form2 := TForm2.Create(Nil);
  result := Form2.showmodal;
  Form2.free;
end;  



// =============================================================================
             procedure TForm2.Button1Click(Sender: TObject);
// =============================================================================

begin
  mODALRESULT := 1;
end;


// =============================================================================
                procedure TForm2.FormActivate(Sender: TObject);
// =============================================================================

begin
  _tipus := TipusBeolvasas;
  if (_tipus<>'O') AND (_tipus<>'A') then
    begin
      _pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+'XX'+chr(39);
      Vparancs(_pcs);
      Kilepo.enabled := true;
      exit;
    end;

  AdatBeolvasas;
  if _tipus='A' THEN
    begin
      with CitiPanel do
        begin
          top := 0;
          left:= 0;
          Visible := true;
          repaint;
        end;

      Citicombo.ItemIndex := _cIndex;
      ActiveControl := CitiOkeGomb;
    end else
    begin
      with orszagpanel do
        begin
          top := 0;
          left := 0;
          Visible := true;
          repaint;
        end;
      Countrycombo.ItemIndex := _cIndex;
      Activecontrol := CountryoKEgOMB;
    end;
end;


// =============================================================================
                        function TForm2.TipusBeolvasas: string;
// =============================================================================

begin
  ValutaDbase.connected := true;
  with Valutaquery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM VTEMP');
      Open;
      result := trim(FieldByNAme('MEGJEGYZES').asString);
      Close;
    end;
  ValutaQuery.close;
  Valutadbase.close;
end;

// =============================================================================
                      procedure TForm2.Adatbeolvasas;
// =============================================================================

begin

  CountryCombo.Items.clear;

  _pcs := 'SELECT * FROM COUNTRIES';

  isodbase.connected := true;
  with IsoQuery do
    begin
      Close;
      sql.clear;
      sql.add(_PCS);
      Open;
    end;

  _pp := 0;
  while not IsoQuery.eof do
    begin
      _iso := IsoQuery.FieldByNAme('ISO').asString;
      _ctry := trim(IsoQuery.FieldBynAme('COUNTRY').asString);

      _countiso[_pp] := _iso;
      _countnev[_pp] := _ctry;
      CountryCOmbo.Items.Add(_ctry);
      if _iso='HU' then _cindex := _pp;

      inc(_pp);

      isoquery.next;
    end;

  // ---------------------------------------------------------

  _pcs := 'SELECT * FROM CITIZENS';

  Citicombo.items.clear;
  with IsoQuery do
    begin
      Close;
      sql.clear;
      sql.add(_PCS);
      Open;
    end;

  _pp := 0;
  while not IsoQuery.eof do
    begin
      _iso := IsoQuery.FieldByNAme('ISO').asString;
      _ctZ := trim(IsoQuery.FieldBynAme('CITIZEN').asString);

      _citiziso[_pp] := _iso;
      _citizNev[_pp] := uppercase(_ctz);
      CitiCombo.Items.add(_ctz);
      if _iso='HU' then _cindex := _pp;

      inc(_pp);

      isoquery.next;
    end;

  isoquery.close;
  isodbase.close;
end;

procedure TForm2.VParancs(_ukaz: string);
begin
  Valutadbase.connected := True;
  if valutatranz.InTransaction then valutatranz.commit;
  Valutatranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_ukaz);
      Execsql;
    end;
  ValutaTranz.Commit;
  Valutadbase.close;
end;


procedure TForm2.KILEPOTimer(Sender: TObject);
begin
  kILEPO.Enabled := fALSE;
  Modalresult := _mResult;
end;

procedure TForm2.COUNTRYMEGSEMGOMBClick(Sender: TObject);
begin
  _pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+'XX'+chr(39);
  Vparancs(_pcs);
  _MrESULT := 2;
  Kilepo.Enabled := true;
end;

procedure TForm2.COUNTRYCOMBOChange(Sender: TObject);
begin
  _cIndex := CountryCombo.itemindex;
  _iso := _countiso[_cIndex];
  _cNev := _countnev[_cIndex];
  ActiveControl := CountryOkeGomb;
end;

procedure TForm2.CITICOMBOChange(Sender: TObject);
begin
  _cIndex := CitiCombo.itemindex;
  _iso := _citiziso[_cIndex];
  _cnev := _citiznev[_cIndex];
  Activecontrol := citiokegomb;
end;

procedure TForm2.COUNTRYOKEGOMBClick(Sender: TObject);
begin
  if _tipus='A' then
    begin
      _cindex := Citicombo.itemindex;
      _cnev   := Citicombo.Items[_cIndex];
      _iso    := _citiziso[_cIndex];
    end else
    begin
      _cindex := CountryCombo.ItemIndex;
      _cnev := countrycombo.Items[_cIndex];
      _iso := _countiso[_cIndex];
    end;
  _cnev := uppercase(leftstr(_cnev,23));
  _totiso := _iso + _cnev;
  _pcs := 'UPDATE VTEMP SET MEGJEGYZES='+chr(39)+_totISO+chr(39);
  Vparancs(_pcs);

  _mResult := 1;
  Kilepo.Enabled := True;
end;

end.
