unit Unit14;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ComCtrls, DB, DBTables,StrUtils, StdCtrls, Buttons,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery;

type
  TMNBLEGYUJTO = class(TForm)
    KILEPO: TTimer;

    procedure FormActivate(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MNBLEGYUJTO: TMNBLEGYUJTO;
  _fPath,_cimtar,_regiBlokk,_stBlokk,_tBlokkNum,_datum,_megj: string;

  _aktKorzet,_aktptar,_etss: integer;
  _fejTablaNev,_tetTablanev,_cimtarTablaNev,_elotablanev: string;
  _mnbDb,_mnbtempdb,_kerekites: integer;
  _elocimtar,_elopath,_aktcegbetu,_utbiz,_bizonylat: string;
  _ii,_jj,_ee: integer;

  _vDarab,_eDarab,_valss,_ftss,_irqq,_fizetoeszkoz: integer;

  _mVet,_mElad,_mHiany,_mTobblet,_mvisszp,_mvisszm: array of array of integer;
  _mbankbol,_mbankba,_mptarba,_mptarbol,_mbankkartya: array of array of integer;
  _mvdb,_medb: array of array of integer;
  _mnyito,_mzaro: array of array of integer;
  _mvanadat: array of array of integer;
  _osszkeszlet: integer;
  _visszap,_visszam,_bankba,_bankbol,_ptarba,_ptarbol,_bankkartya: integer;

  _enyito,_ezaro,_evetel,_eeladas,_etobblet,_ehiany: array of array of integer;
  _evisszap,_evisszam,_ebankba,_ebankbol,_eptarba,_eptarbol: array of array of integer;
  _evdarab,_eedarab,_eBankkartya: array of array of integer;

  _kftnyito,_kftzaro,_kftvetel,_kfteladas,_kfttobblet,_kfthiany: array of array of integer;
  _kftvisszap,_kftvisszam,_kftbankba,_kftbankbol,_kftptarba,_kftptarbol: array of array of integer;
  _kftvdarab,_kftedarab,_kftbankkartya: array of array of integer;


  _snyito,_szaro,_svetel,_seladas,_stobblet,_shiany: array of integer;
  _svisszap,_svisszam,_sbankba,_sbankbol,_sbankartya: array of integer;
  _sptarba,_sptarbol,_sbankkartya: array of integer;
  _svdarab,_sedarab: array of integer;
  _tolev,_tolho : integer;
  _korzetbetu: string;

  _voltadat: boolean;


implementation

uses Unit1, Unit6;

{$R *.dfm}


// ===================================================================
        procedure TMNBLEGYUJTO.FormActivate(Sender: TObject);
// ===================================================================

  // Forgalmi adatokat gyüjt le datumtols - datumigs

begin
  Top := _top + 330;
  Left := _left + 230;
  Width := 585;

  Kilepo.Enabled := true;
end;

procedure TMNBLEGYUJTO.KILEPOTimer(Sender: TObject);
begin
  kILEPO.Enabled := FALSE;
  Modalresult := 1;
end;

end.
