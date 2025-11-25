unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery, IBTable,
  StrUtils, Buttons, Grids, ExtCtrls, dateUtils;

type
  TArfolyamTarolo = class(TForm)

    ArfolyamQuery     : TIBQuery;
    ArfolyamDbase     : TIBDatabase;
    ArfolyamTranz     : TIBTransaction;
    ArfolyamTabla     : TIBTable;

    ValutaQuery       : TIBQuery;
    ValutaDbase       : TIBDatabase;
    ValutaTranz       : TIBTransaction;

    ArfolyamCimPanel  : TPanel;
    DatumValasztoPanel: TPanel;
    ReadPanel         : TPanel;
    HonapKeroPanel    : TPanel;
    IdoValasztoPanel  : TPanel;
    Panel1            : TPanel;
    Panel2            : TPanel;

    Label4            : TLabel;
    Label5            : TLabel;
    Label1            : TLabel;
    Label2            : TLabel;
    Label3            : TLabel;

    Racs              : TStringGrid;

    Kilepo            : TTimer;

    HonapRendbenGomb  : TBitBtn;
    BitBtn3           : TBitBtn;
    MasikDatumGomb    : TBitBtn;
    VisszaGomb        : TBitBtn;
    MasikIdoGomb      : TBitBtn;
    MasikHonapGomb    : TBitBtn;

    EvCombo           : TComboBox;
    HoCombo           : TComboBox;

    Shape3            : TShape;
    Shape4            : TShape;
    Shape1            : TShape;
    Shape2            : TShape;

    DatumBox          : TListBox;
    IdoBox            : TListBox;

    procedure FormActivate(Sender: TObject);

    procedure Archivecontrol;
    procedure ArfParancs(_ukaz: string);
    procedure EgyracsDisplay;
    procedure KilepoTimer(Sender: TObject);
    procedure OneTimeLoading;
    procedure RacsTakarito;
    procedure HonapComboToltes;
    procedure IdoBoxDblClick(Sender: TObject);
    procedure MasikIdoGombClick(Sender: TObject);
    procedure VisszaGombClick(Sender: TObject);
    procedure MasikDatumGombClick(Sender: TObject);
    procedure HonapRendbenGombClick(Sender: TObject);
    procedure MasikHonapGombClick(Sender: TObject);
    procedure DatumBoxDblClick(Sender: TObject);

    function RealToStr(_rr: real): string;
    function Nulele(_int: integer): string;
    function RealFormat(_real: real): string;
    function OneMonthLoading: boolean;
    function HunDatetostr(_caldat: TDateTime): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ArfolyamTarolo: TArfolyamTarolo;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                 'MÁJUS','JUNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER',
                 'OKTÓBER','NOVEMBER','DECEMBER');

  _yVet,_yelad,_y1vet,_y1elad,_y2vet,_y2elad,_yelszam: array[1..28] of real;

  _sorveg : string = #13#10;
  _bytetomb: array[1..4096] of byte;
  _yDnem: array[1..29] of string;

  _ratedatum: array[1..31] of string;
  _rateIdo: array[1..31,1..12] of string;

  _datumido: array[1..31] of byte;

  _datumdb,_idodb,_havinap,_kertnap: byte;
  _aktev,_aktho,_aktnap,_kertev,_kertho: word;
  _aktvalutaDarab,_height,_left,_top,_width: word;

  _kertDatum,_kertido,_sarfTabla,_lastDatum,_lastIdo,_datum,_ido: string;
  _aktdnem,_farok,_foc,_mamas,_pcs,_tablanev,_lastloaded: string;

  _datumIndex,_idoIndex,_mresult,_qq: integer;


function arfolyamregiszter: integer;stdcall;

implementation

{$R *.dfm}

// =============================================================================
        function arfolyamregiszter: integer;stdcall;
// =============================================================================

begin
  ArfolyamTarolo := Tarfolyamtarolo.Create(Nil);
  result := ArfolyamTarolo.ShowModal;
  ArfolyamTarolo.Free;
end;

// =============================================================================
            procedure TARFOLYAMTAROLO.FormActivate(Sender: TObject);
// =============================================================================

begin

  Readpanel.Visible := false;

  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := trunc((_height-768)/2);
  _left := trunc((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  Height := 725;
  Width  := 1010;

  _mamas := Hundatetostr(date);

  ArchiveControl;
  HonapComboToltes;

  _kertev  := _aktev;
  _kertho  := _aktho;

  if OneMonthLoading then
    begin
      _datumIndex := _datumdb;
      _idoIndex   := _idodb;
      _kertDatum  := _rateDatum[_datumIndex];
      _kertido    := _rateIdo[_datumIndex,_idoIndex];
    end;

  with ReadPanel do
    begin
      top := 5;
      Left := 5;
      Visible := True;
      Repaint;
    end;

  OneTimeLoading;
  EgyRacsDisplay;
end;


// =============================================================================
               procedure TArfolyamtarolo.HonapComboToltes;
// =============================================================================

var _z: byte;

begin
  evcombo.Items.Clear;
  evcombo.Items.Add(inttostr(_aktev-1));
  evcombo.Items.Add(inttostr(_aktev));
  evcombo.ItemIndex := 1;

  Hocombo.Items.Clear;
  _z := 1;
  while _z<=12 do
    begin
      hocombo.Items.add(_honev[_z]);
      inc(_z);
    end;
  Hocombo.ItemIndex := _aktho-1;
end;

// =============================================================================
          procedure TARFOLYAMTAROLO.VISSZAGOMBClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 1;
end;

// =============================================================================
         procedure TARFOLYAMTAROLO.MASIKDATUMGOMBClick(Sender: TObject);
// =============================================================================

var _z: byte;

begin
  Datumbox.Items.Clear;
  _z := 1;
  while _z<=_datumdb do
    begin
      Datumbox.Items.Add(_ratedatum[_z]);
      inc(_z);
    end;
  datumbox.ItemIndex := 0;

  with DatumvalasztoPanel do
    begin
      top  := 180;
      left := 430;
      Visible := True;
      Repaint;
    end;
end;


// =============================================================================
            procedure TARFOLYAMTAROLO.HONAPRENDBENGOMBClick(Sender: TObject);
// =============================================================================

begin
  _kertev := _aktev-1+evcombo.itemindex;
  _kertho := 1+ hocombo.itemindex;

  HonapkeroPanel.visible := False;

  if OneMonthLoading then
    begin
      _kertDatum := _rateDatum[1];
      _kertido   := _rateIdo[1,1];
      OneTimeLoading;
      EgyracsDisplay;
    end;
end;

// =============================================================================
         procedure TArfolyamTarolo.MasikHonapGombClick(Sender: TObject);
// =============================================================================

begin
  with HonapKeroPanel do
    begin
      top     := 192;
      left    := 352;
      Visible := True;
      Repaint;
    end;
  ActiveControl := HonapRendbenGomb;
end;

// =============================================================================
         procedure TArfolyamTarolo.DatumBoxDblClick(Sender: TObject);
// =============================================================================

begin
  _datumindex := 1 + datumbox.ItemIndex;
  _kertDatum  := _rateDatum[_datumIndex];

  if not OneMonthLoading then exit;
  HonapKeroPanel.Visible := False;
  MasikidoGombClick(Nil);
END;


// =============================================================================
           procedure TArfolyamtarolo.MasikIdoGombClick(Sender: TObject);
// =============================================================================

var _z,_zveg: byte;

begin
  idobox.Items.Clear;
  _zveg := _datumido[_datumindex];
  _z := 1;
  while _z<=_zVeg do
    begin
      Idobox.Items.add(_rateido[_datumindex,_z]);
      inc(_z);
    end;
  Idobox.ItemIndex := 0;

  with IdovalasztoPanel do
    begin
      top := 210;
      left := 440;
      Visible := True;
      repaint;
    end;
  Idobox.SetFocus;
end;

// =============================================================================
              function TArfolyamTarolo.OneMonthLoading: boolean;
// =============================================================================

// Kertev és kertho paraméterek alapján megnyitja az adatbázist (ha van ilyen)

begin
  // Default: Van ilyen havi adatbázist:

  Result := True;

  // Meghatározza a kért honap nevét:
  _sarfTabla := 'SARF' + inttostr(_kertEv-2000)+nulele(_kertHo);

  // Ha ennek az adatbázisnak az elemei már br vannak olvasva, akkor ennyi
  if _sarftabla=_lastLoaded then exit;

  // A default most: Nincs ilyen adatbázis
  Result := False;

  // Megvizsgálja, hogy létezik-e az adatbázist:
  ArfolyamTabla.Close;
  ArfolyamTabla.TableName := _sarfTabla;
  ArfolyamDbase.Connected := True;

  //  Ha nem létezik az adatbázis - akkor ennyi ...
  if not ArfolyamTabla.exists then
    begin
      ArfolyamDbase.close;
      ShowMessage('NINCS ADAT A KÉRT HÓNAPRÓL');
      Exit;
    end;

  // Megnyitjuk a kért havi adatbazist indexelve, nem szürve:
  _pcs := 'SELECT * FROM ' + _sarfTabla + ' ORDER BY DATUM,IDO';
  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
      _datum := ArfolyamQuery.FieldByName('DATUM').asString;
      _ido   := ArfolyamQuery.FieldByName('IDO').asString;
    end;

  _lastDatum := '';
  _lastIdo   := '';

  _datumDb   := 0;
  _idoDb     := 0;

  while not ArfolyamQuery.Eof do
    begin
      _datum := ArfolyamQuery.FieldByName('DATUM').asString;
      _ido   := ArfolyamQuery.FieldByName('IDO').asString;

      if _datum<>_lastDatum then
        begin
          _datumIdo[_datumdb] := _idodb;
          inc(_datumDb);
          _idodb := 0;
          _rateDatum[_datumdb] := _datum;
          _lastDatum := _datum;
        end;

      if _ido<>_lastido then
        begin
          inc(_idodb);
          _rateido[_datumdb,_idodb] := _ido;
          _lastido := _ido;
        end;
      ArfolyamQuery.next;
    end;
  Arfolyamdbase.close;

  // Három tömb van itt felépitve:
  //   _ratedatum[1.._datumdb] - a havi adatbázisban lévõ dátumok nevei (string)
  //   _datumido[1.._datumdb] - ez egyes napokon ennyi változás történt (byte)
  //   _rateido[1.._datumdb,1..idodb] - a napi változások idöpontjai (string)


  // A kielemezett havi adatbázis neve elmentve a _lastloaded változóba
  _lastLoaded := _sarfTabla;

  // Vissza= Minden rendben
  result := True;
end;

// =============================================================================
                procedure TarfolyamTarolo.OneTimeLoading;
// =============================================================================

// A kert-datum és kert-ido -nek megfelelõ adatok beolvasása és betöltése
//                   az 'y' - kezdetû tömbökbe:

begin
  // A 'SARFTABLA'-ból újra megnyitja kertdatum és kertidõ szüréssel:

  _pcs := 'SELECT * FROM ' + _sarfTabla + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM=' + chr(39)+ _kertDatum + chr(39);
  _pcs := _pcs + ') AND (IDO=' + chr(39) + _kertido + chr(39) + ')' +_sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  ArfolyamDbase.Connected := true;
  with ArfolyamQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  // Az adatok betöltése a szürt adatbázisból az 'y' - kezdetû törmbökbe:
  _qq := 1;
  while not ArfolyamQuery.eof do
    begin
      with ArfolyamQuery do
        begin
          _yDnem[_qq]  := FieldByName('VALUTANEM').asString;
          _yvet[_qq]   := FieldByName('ALAPVETEL').asFloat;
          _yelad[_qq]  := FieldByName('ALAPELADAS').asFloat;
          _y1vet[_qq]  := FieldByName('LIM1VETEL').asFloat;
          _y1elad[_qq] := FieldByName('LIM1ELADAS').asFloat;
          _y2vet[_qq]  := FieldByName('LIM2VETEL').asFloat;
          _y2elad[_qq] := FieldByName('LIM2ELADAS').asFloat;
          _yelszam[_qq]:= FieldByName('ELSZAMOLASIARFOLYAM').asFloat;
        end;
      _aktvalutaDarab := _qq;
      inc(_qq);
      ArfolyamQuery.Next;
    end;
  Arfolyamquery.close;
  ArfolyamDbase.close;
end;

// =============================================================================
                   procedure TarfolyamTarolo.EgyracsDisplay;
// =============================================================================

var _evs,_naps: string;
    _ho: word;

begin
  // Fõcim összeállitás: dátum és idõ:
   _evs  := leftstr(_kertdatum,4);
  _ho    := strtoint(midstr(_kertdatum,6,2));
  _naps  := midstr(_kertdatum,9,2);

  _foc := _evs + ' '+ _honev[_ho] + ' '+ _naps +'-N ('+ _kertido + '-KOR) ';
  _foc := _foc + ' KIADOTT ÁRFOLYAMTÁBLA';

  ArfolyamCimPanel.Caption := _foc;
  ArfolyamCimPanel.Repaint;

  // A rács adatainak kitörlése:
  RacsTakarito;


  //  A rács fejlécének kialakitésa:

  Racs.Cells[0,0] := '   VALUTANEM';
  Racs.cells[1,0] := '  Vételi árfolyam';
  Racs.Cells[2,0] := '  Eladási árfolyam';
  Racs.Cells[3,0] := '  1. Kedvm. vétel';
  Racs.Cells[4,0] := '  1. Kedvm.eladás';
  Racs.Cells[5,0] := '  2. Kedvm. vétel';
  Racs.Cells[6,0] := '  2. Kedvm.eladás';
  Racs.Cells[7,0] := '  Elszámolási árf';

  // A valutadarabnyi cellak feltöltése a 'y'-nal kezdödõ tömbök adataival:

  _qq := 1;
  while _qq<=_aktValutaDarab do
    begin
      _aktdnem := _yDnem[_qq];
      Racs.cells[0,_qq] := '         ' + _aktdnem;
      Racs.cells[1,_qq] := realformat(_yvet[_qq]);
      Racs.cells[2,_qq] := realformat(_yelad[_qq]);
      Racs.cells[3,_qq] := RealFormat(_y1vet[_qq]);
      Racs.cells[4,_qq] := RealFormat(_y1elad[_qq]);
      Racs.Cells[5,_qq] := RealFormat(_y2vet[_qq]);
      Racs.Cells[6,_qq] := RealFormat(_y2elad[_qq]);
      Racs.cells[7,_qq] := realformat(_yelszam[_qq]);
      inc(_qq);
    end;

  // A récsot kiteszi a képernyõre:

  with Racs do
    begin
      left := 8;
      Visible := true;
    end;
  ActiveControl     := Racs;
end;


// =============================================================================
         procedure TARFOLYAMTAROLO.IDOBOXDblClick(Sender: TObject);
// =============================================================================

begin
  _idoindex := idobox.ItemIndex;
  _kertido := idobox.items[_idoindex];
  IdovalasztoPanel.Visible := False;
  DatumValasztoPanel.visible := False;
  OneTimeLoading;
  EgyracsDisplay;

end;


// =============================================================================
////////////////////////////////////////////////////////////////////////////////
///////////////////    EGYÉB PROGRAMOK ÉS FUNKCIÓK     /////////////////////////
////////////////////////////////////////////////////////////////////////////////
// =============================================================================
// =============================================================================
          procedure TARFOLYAMTAROLO.kilepoTimer(Sender: TObject);
// =============================================================================

begin
  Kilepo.Enabled := false;
  ModalResult := _mResult;
end;

// =============================================================================
      function TarfolyamTarolo.HunDatetostr(_caldat: TDateTime): string;
// =============================================================================

begin
  _aktev := yearof(_caldat);
  _aktho := monthof(_caldat);
  _aktnap:= dayof(_caldat);

  result := inttostr(_aktev)+'.'+nulele(_aktho)+'.'+nulele(_aktnap);
end;

// =============================================================================
            function TArfolyamTarolo.Nulele(_int: integer): string;
// =============================================================================


begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

// =============================================================================
          function TarfolyamTarolo.RealFormat(_real: real): string;
// =============================================================================

begin
  if _aktdnem='JPY' then _real := _real/10;
  result := '            '+ Formatfloat('### ###.#',_real);
end;

// =============================================================================
               procedure TarfolyamTarolo.RacsTakarito;
// =============================================================================
begin
  _qq := 1;
  while _qq<=24 do
    begin
      racs.cells[0,_qq]:= ' ';
      racs.cells[1,_qq]:= ' ';
      racs.cells[2,_qq]:= ' ';
      racs.cells[3,_qq]:= ' ';
      racs.cells[4,_qq]:= ' ';
      racs.cells[5,_qq]:= ' ';
      racs.cells[6,_qq]:= ' ';
      racs.cells[7,_qq]:= ' ';
      inc(_qq);
    end;
end;

// =============================================================================
                 procedure TArfolyamtarolo.Archivecontrol;
// =============================================================================

var _oev,_oho: word;
    _oFarok,_sarfTabla: string;

begin
  _oev := _aktev-1;
  _oho :=  _aktho;
  while true do
    begin
      _oFarok := midstr(inttostr(_oev),3,2)+ nulele(_oho);
      _sarftabla := 'SARF' + _oFarok;
      ArfolyamDbase.close;
       ArfolyamTabla.close;
      ArfolyamTabla.TableName := _sarfTabla;
      ArfolyamDbase.Connected := True;

      if ArfolyamTabla.Exists then
        begin
          Arfolyamdbase.close;
          _pcs := 'DROP TABLE ' + _sarfTabla;
          ArfParancs(_pcs);
          dec(_oho);
          if _oho<1 then
            begin
              _oHo := 12;
              dec(_oev);
            end;
        end else
        begin
          ArfolyamDbase.close;
          Break;
        end;
    end;
end;

// =============================================================================
                 procedure TArfolyamtarolo.ArfParancs(_ukaz: string);
// =============================================================================

begin
  Arfolyamdbase.connected := True;
  if arfolyamTranz.InTransaction then ArfolyamTranz.Commit;
  ArfolyamTranz.StartTransaction;

  with ArfolyamQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_ukaz);
      Execsql;
    end;
  Arfolyamtranz.Commit;
  Arfolyamdbase.close;
end;

// =============================================================================
                  function TArfolyamTarolo.RealToStr(_rr: real): string;
// =============================================================================

var _pos: integer;

begin
  Result := '0';
  if _rr=0 then exit;

  Result := Floattostr(_rr);
  _pos := pos(chr(44),result);
  if _pos>0 then result[_pos] := chr(46);
end;







end.
