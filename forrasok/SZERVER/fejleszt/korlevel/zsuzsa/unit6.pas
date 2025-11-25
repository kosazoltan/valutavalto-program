unit Unit6;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable, StdCtrls,
  Buttons, Grids, DBGrids, ExtCtrls, unit1, strutils;

type
  TGetIDkod = class(TForm)
    ProsQuery     : TIBQuery;
    ProsDbase     : TIBDatabase;
    ProsTranz     : TIBTransaction;

    Panel1        : TPanel;
    ProsRacs      : TDBGrid;
    Label1        : TLabel;

    ProsSource    : TDataSource;

    EzVagyokGomb  : TBitBtn;
    NemTalalomGomb: TBitBtn;

    procedure EzVagyokGombClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure Megvagyok;
    procedure NemTalalomGombClick(Sender: TObject);
    procedure ProsRacsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    function Commless(_kod: byte): string;
    function Ektelenito(_ekes: string): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  GetIDkod     : TGetIDkod;
  _sign1,_sign2: string;

implementation

{$R *.dfm}

// =============================================================================
             procedure TGetIDkod.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top  := 210;
  Left := 460;

  // A szerveren megnyitom a pénztáros adatbázist:

  Prosdbase.Close;
  Prosdbase.DatabaseName := _serverProsPath;
  Prosdbase.Connected := True;

  _pcs := 'SELECT * FROM PENZTAROSOK' + _sorveg;
  _pcs := _pcs + 'ORDER BY PENZTAROSNEV';

  with ProsQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  // A nevek közül kiválaszthatja magát a dolgozó:
  Activecontrol := ProsRacs;
end;


// =============================================================================
           procedure TGetidKod.EzVagyokGombClick(Sender: TObject);
// =============================================================================

//           EZ VAGYOK ÉN GOMBRA KLIKKELT, VAGY A NÉVRE DOUBLECLICK

begin
  Megvagyok;
end;

// =============================================================================
       procedure TGetidkod.ProsRacsKeyDown(Sender: TObject; var Key: Word;
                                                         Shift: TShiftState);
// =============================================================================

//              ENTERT ADOTT A NÉVSOR EGYIK REKORDJÁRA

begin
  if ord(key)<>13 then exit;
  Megvagyok;
end;

// =============================================================================
                           procedure TGetidkod.Megvagyok;
// =============================================================================

//                    KIVÁLASZTOTTA MAGÁT A NÉVSORBAN:

var _iras: textfile;

begin

  // A rácsban megtalálta magát és ki is választotta: Itt a saját adatai:

  _dolgSorszam := ProsQuery.FieldByNAme('SORSZAM').asInteger;
  _dolgnev     := trim(Prosquery.fieldByName('PENZTAROSNEV').asString);
  _idstring    := inttostr(_dolgSorszam) + ',' + _dolgnev;

  ProsQuery.close;
  Prosdbase.close;

  // BEIRJA A NEVÉT ÉS SORSZÁMÁT AZ ID.TXT -BE:

  assignfile(_iras,_idPath);
  rewrite(_iras);
  write(_iras,_idstring);
  CLoseFile(_iras);

  // ----------- MOST MEGCSINÁLJA A SZIGNO-FILE-T IS: -----------

  // Megkeresi a Keresztnevet a teljes névben:

  _pos := Pos(CHR(32),_dolgNev);
  if _pos=0 then
    begin
      sysutils.DeleteFile(_idPath);
      Application.Terminate;
      exit;
    end;

  // Sign1 = A családi név elsö két betüje:

  _sign1 := leftstr(_dolgnev,2);

  //  Sign2 = A keresztnev elsü két betüje:

  _pos := Pos(chr(32),_dolgnev);
  _sign2 := midstr(_dolgnev,_pos+1,2);

  // A szigno elsö betüjének meghatározása: (Lehet kettõs betü is)

  _sign1 := ektelenito(_sign1);

  // A szigno hétsó betüjének meghatározása: (Lehet kettõs betü is)

  _sign2 := ektelenito(_sign2);

  // Ime itt kész a szigno:

  _sign := _sign1 + _sign2;


  // A szignot feljegyzi a SIGN.TXT file-ban

  Assignfile(_iras,_signPath);
  rewrite(_iras);
  Write(_iras,_sign);
  Closefile(_iras);

  // Az azonositás rendben - visszatérés 1-gyel:

  Modalresult := 1;
end;

// =============================================================================
          function TgetidKod.Ektelenito(_ekes: string): string;
// =============================================================================

//                A név elsõ két betüjének feldolgozása:


var _kb,_kb2: byte;

begin

  _kb := ord(_ekes[1]);    // elsö betü asc-kódja
  _kb2:= ord(_ekes[2]);    // második betü asc-kódja

  // HA a betü ékezetes magyar betü -> konvertálja angol betüre:

  if (_kb>90) then
    begin
      result := Commless(_kb);
      exit;
    end;

  // A kettõs betük lekezelése: CS, ZS

  if (_kb=67) or (_kb=90) then  // C vagy Z - van utana S ?
    begin
      if _kb2=83 then result := chr(_kb)+'S'    // S
      else result := chr(_kb);
      exit;
    end;

  // A kettõs betük lekezelése: NY, GY, TY

 if (_kb=78) or (_kb=71) OR (_KB=84) then     // NGT
   begin
     if _kb2=89 then result := chr(_kb)+'Y'
     else result := chr(_kb);
     exit;
   end;

   // A kettõs betük lekezelése: SZ

  if _kb=83 then   // S
    begin
      if _kb2=90 then result := 'SZ'
      else result := chr(_kb);
      exit;
    end;

  // eZ SIMA ANGOL BETÜ:

  result := chr(_kb);
end;

// =============================================================================
              function TGetidkod.Commless(_kod: byte): string;
// =============================================================================


// Magyar ékezetes betü átkonvertálása angol betüre:

var _minta,_angol: string;
    _y: byte;

begin
  _MINTA := 'ÁÉÍÓÖÕÚÜÛ';
  _ANGOL := 'AEIOOOUUU';

  result := chr(_kod);

  _y := 1;
  while _y<=9 do
    begin
      if ord(_minta[_y])=_kod then
        begin
          result := midstr(_angol,_y,1);
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
               procedure TGetIDkod.NemTalalomGombClick(Sender: TObject);
// =============================================================================

// Nem találta magát a dolgozói adatbázisban:

begin
  ProsQuery.close;
  Prosdbase.close;
  ShowMessage('FEL KELL VENNI A NEVEDET A DOLGOZÓI ADATBÁZISBA');
  Modalresult := 2;
end;

end.
