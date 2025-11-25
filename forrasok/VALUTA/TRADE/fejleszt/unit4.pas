unit Unit4;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, unit1, StrUtils, IBDatabase, DB,
  IBCustomDataSet, IBQuery;

type
  TMATRICANYOMTATO = class(TForm)
    BitBtn1: TBitBtn;
    MATQUERY: TIBQuery;
    MATDBASE: TIBDatabase;
    MATTRANZ: TIBTransaction;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MATRICANYOMTATO: TMATRICANYOMTATO;
  _mattipus,_matkat,_matStartDatums,_matEndDatums,_matRendszam,_matCountry: string;
  _matRefer,_matTranzakcio,_matPros,_matIdos,_matUgyfNev,_matUgyfCim: string;
  _matFizet,_matugyfszam: integer;

implementation

{$R *.dfm}

procedure TMATRICANYOMTATO.BitBtn1Click(Sender: TObject);
begin
  Modalresult := 1;
end;

procedure TMATRICANYOMTATO.FormCreate(Sender: TObject);
begin
  _farok := midstr(_matdatums,3,2)+midstr(_matdatums,6,2);
  _tablanev := 'TRAD' + _farok;

  _pcs := 'SELECT * FROM ' + _tablanev + _sorveg;
  _pcs := _pcs + 'WHERE BIZONYLATSZAM=' + chr(39)+_matBizonylat+chr(39);

  matdbase.connected := true;
  with MatQuery do
    begin
      CLose;
      Sql.Clear;
      Sql.add(_pcs);
      Open;
      _matTipus       := FieldByName('TIPUS').asString;
      _matkat         := trim(FieldByName('KATEGORIA').asString);
      _matStartdatums := fieldByName('STARTDATUM').asString;
      _matEnddatums   := fieldByName('ENDDATUM').asString;
      _matRendszam    := trim(FieldByName('RENDSZAM').asString);
      _matCountry     := trim(FieldByName('COUNTRYNAME').asString);
      _matRefer       := trim(FieldByName('REFERENCEID').asString);
      _matTranzakcio  := trim(FieldByNAme('TRANZAKCIO').asString);
      _matFizet       := FieldByName('FIZETENDO').asInteger;
      _matPros        := trim(FieldByName('PENZTAROSNEV').asstring);
      _matidos        := FieldByNAme('IDO').asString;
      _matUgyfszam    := FieldByNAme('UGYFELSZAM').asInteger;
      _matUgyfnev     := trim(FieldByNAme('UGYFELNEV').asString);
      _matUgyfcim     := trim(FieldByName('UGYFELCIM').asString);
      close;
    end;
  Matdbase.close;

  // -------------------------------------------

  BlokkFocimIro;

  Kozepreir('E-matrica  / E-vignette');
  Kozepreir('Ellenorzo szelveny/Counterfoil');
  Kozepreir('Elado peldanya / Seller'#39's copy');

  // ------------------------------------------------

  WriteLn(_Lfile,' ');
  KozepreIr('Eladohely / Terminal id : '+_terminalid);
  WriteLn(_Lfile,' ');

  // -------------------------------------------------

  Kozepreir('Rendszam/Registration number:;
  WideKozepreir(_matRendszam);
  WriteLn(_Lfile,' ');

  // -------------------------------------------

  Kozepreir('Orszag/Country: ');
  WideKozepreir(_matCountryName);
  WriteLn(_Lfile,' ');

  // ----------------------------------------

  Kozepreir('Tipus/Type: ');
  wideKozepreIr(_matkat);
  WriteLn(_LFile,' ');

  // -----------------------------------------

  Kozepreir(Ervenyesseg kezdete/valid from:');
  _ssor := _matstartDatums+ '  ';
  if _matstartdatums=_matdatums then _idos := _matidos
  else _idos := '00:00:00';
  _ssor := _ssor + _idos;
  WideKozepreir(_ssor);
  WriteLn(_LFile,' ');

  // ------------------------------------------

  Kozepreir(Ervenyesseg vege/end of validity:');
  WideKozepreir(_matendDatums+'  23:59:59');
  WriteLn(_LFile,' ');

  // ------------------------------------------








end;


// =============================================================================
                        procedure TMatricaNyomtato.Blokknyitas;
// =============================================================================

begin
  assignFile(_LFile,'C:\valuta\aktlst.txt');
  Rewrite(_LFile);
  write(_LFile,#27#64);
end;

// ============================================================================
             procedure TMatricaNyomtato.BlokkFocimIro(_kellnyitni: boolean) ;
// ============================================================================

// Blokknyomtatás fejléce

begin

  BlokkNyitas;
  writeLn(_LFile,dupestring('=',39));
  if _penztarszam<151 then
    begin
      wideKozepreir('EXCLUSIVE BEST');
      WideKozepreir('CHANGE ZRT');
    end else
    begin
      wideKozepreir('EXPRESSZ EKSZERHAZ');
      WideKotepreir('ES MINIBANK KFT');
    End;

  writeLn(_lFile,' ');
  write(_LFile,_homePenztarNev);
  writeLN(_LFile,_homePenztarszam);
  writeLn(_LFile,_homePenztarCim);
  writeLn(_lFile,'Adoszam       : ' + _adoszam);
  WriteLn(_LFile,'Terminal ID   : '+_terminalId);
  writeLn(_LFile,'Bizonylatszam : '+ _bizonylatszam);

  writeLn(_LFile,dupestring('=',39));
end;



// =============================================================================
                     procedure TMatricaNyomtato.matrica1Blokk;
// =============================================================================


begin

 // BlokkNyitas;


  writeLn(_LFile,'      Ar/Price: '+ #14 + ftform(_fizetendo)+ #20#13#10);

  Kozepreir('Ervenyes/Valid:');
  if _ezmegye then Kozepreir(_aktmegyenev+' VARMEGYE/COUNTY')
  else Kozepreir('Az egesz orszagban/All of Hungary');


  Kozepreir('Ervenyesseg kezdete/Valid from:');
  Kozepreir(_startdatums);
  KozepreIr('Vasarlas idopontja/Purchase time:');
  KozepreIr(_mamas+'  '+_idos);
  KozepreIr('Tranzakcio azonosito/Transaction ID:');
  Kozepreir(_tranzakcio);
  writeLn(_LFile,' ');
  WriteLn(_LFile,'Alairasommal elismerem a fenti adatok');
  WriteLn(_LFile,'helyesseget/I acknowledge the correct-');
  KozepreIr('ness of the above data with');
  Kozepreir('my signature');
  WriteLn(_LFile,'  '+chr(13)+chr(10));
  writeLn(_LFile,dupestring('.',39));
  KozepreIr('Alairas/Signature');
  writeLn(_Lfile,' '+chr(13)+chr(10));
  writeLn(_LFile,' Nem adougyi bizonylat/');
  writeLn(_LFile,'                Not a taxation voucher'#13#10);
  KozepreIr('Ez az eladoi peldany uthasznalatra nem');
  KozepreIr('jogosit/This seller'#39's copy doesn'#39't');
  KozepreIr('entitle you to use roads');
  WriteLn(_LFile,' ');
  StartNyomtatas;
end;






// =============================================================================
                 procedure TMatricaNyomtato.matrica2Blokk;
// =============================================================================


begin
  // BlokkNyitas;
  BlokkFocimiro(True);
  Kozepreir('E-matrica  / E-vignette');
  writeLn(_Lfile,' ');
  Kozepreir('Ellenorzo szelveny /Counter foil');
  KozepreIr('Vevo peldanya /  Costumer'#39's copy');

  WriteLn(_Lfile,' ');
  if _penztarszam<151 then
       kozepreir('Exclusive Best Change Zrt')
  else Kozepreir('Expressz Ekszerhaz es Minibank Kft.');
  kozepreir(trim(_homePenztarnev));
  KozepreIr(trim(_homePenztarcim));
  writeLn(_Lfile,' ');
  Kozepreir('Rendszam/Registration number:');
  writeLn(_LFile,'             '+#14+_rendszam+#20#13#10);
  KozepreIr('Orszag/Country:');
  Kozepreir(_countryname);
  Kozepreir('Tipus / Type:');
  Kozepreir(_aktmatricanev);
  WriteLn(_LFile,'      Ar/Price: '+#14+ftform(_fizetendo)+#20#13#10);

  Kozepreir('Ervenyes/Valid:');
  if _ezmegye then Kozepreir(_aktmegyenev+' VARMEGYE/COUNTY')
  else Kozepreir('Az egesz orszagban/All of Hungary');

  KozepreIr('Ervenyesseg kezdete/Start of validity:');
  Kozepreir(_startdatums+'  ' +  _startPerc);
  Kozepreir('Ervenyesseg vege/End of validity:');
  Kozepreir(_enddatums+'  23:59:59');
  WriteLn(_Lfile,' ');
  Kozepreir('Vasarlas idopontja/Purchasing time:');
  Kozepreir(_mamas+'  '+ _idos);
  KozepreIr('Tranzakcio azonosito/Transaction ID:');
  Kozepreir(_tranzakcio);
  Kozepreir('Sorszam / Serial number:');
  Kozepreir(_referenceid);
  WriteLn(_Lfile,' ');
  Kozepreir('Lejarat utan kerjuk a bizonylatot ket');
  Kozepreir('evig megorizni / Please keep it for');
  Kozepreir('two years after its expiration');
  WriteLn(_Lfile,' ');

  writeLn(_LFile,'Problema eseten forduljon ugyfelszolga-');
  writeLn(_LFile,'latunkhoz/If you have any problem please');
  writeLn(_LFile,'     contact our costumer service');
  writeLn(_LFile,'Ugyfelszolgalatunk telefonszama:/The phone');
  writeLn(_LFile,'   number of our costumer service is:');
  writeLn(_LFile,'            +36-1-766-45-19');
  writeLn(_LFile,' ');

  writeLn(_Lfile,' Nem adougyi bizonylat/');
  writeLn(_LFile,'                Not a taxation voucher');
  writeLn(_lfile,#13#10#13#10);
  Kozepreir('Eladohely p.h/Seller'#39's stamp');
  startNyomtatas;
end;

// =============================================================================
                procedure TMatricaNyomtato.AfasSzamla;
// =============================================================================

begin
  _kategoriastr := leftstr(_cikknev[_cikkszam],21);
  Blokknyitas;
  BlokkFocimiro;
  writeln(_LFile,chr(13)+chr(10));
  KozepreIr('EGYSZERUSITETT SZAMLA');
  WriteLn(_LFile,' elektromos autopalya matrica vetelerol');
  writeln(_LFile,' ');
  write(_LFile,'Szamlaszam: AM-' + midstr(_bizonylatszam,3,6));
  writeLn(_LFile,' Keszult: 2 pld-ban');
  writeLn(_LFile,dupestring(' ',30)+'1. peldany');
  writeln(_LFile,' ');
  if _penztarszam<151 then
            WriteLn(_LFile,'Szallito: Exclusive Best Change Zrt.')
  else WriteLn(_LFile,'Szallito: Expressz Ekszerhaz es Minibank Kft.');
  writeln(_LFile,'     Nev: '+leftstr(_homepenztarnev,30));
  writeLn(_LFile,'     Cim: '+leftstr(_homePenztarcim,30));
  writeLn(_LFile,' Adoszam: '+_adoszam);
  writeln(_LFile,' ');
  writeln(_LFile,'    Vevo: '+leftstr(_ugyfelnev,30));
  writeLn(_LFile,'    Cime: '+leftstr(_ugyfelcim,30));
  writeln(_LFile,' ');
  writeln(_LFile,'Cikk megnevezese: '+ _kategoriastr);
  writeLn(_LFile,'       Egysegara: '+ ftform(_fizetendo));
  writeLn(_LFile,'      Mennyisege: 1 db');
  writeLn(_LFile,'       Fizetendo: ' + ftform(_fizetendo));
  writeLn(_LFile,' ');
  writeLn(_LFile,'A szamla vegosszege 21 % AFA-t tartalmaz');
  writeLn(_LFile,' ');
  Kozepreir('Lejarat utan kerjuk a bizonylatot ket');
  Kozepreir('evig megorizni / Please keep it for');
  Kozepreir('two years after its expiration');
  WriteLn(_Lfile,' ');
  KozepreIr('Szamla kelte: ' + _mamas);
  writeLn(_LFile,' ');
  writeLn(_LFile,' ');
  writeln(_LFile,dupestring('.',38));
  KozepreIr('Alairas');
  writeLn(_LFile,' ');
  Startnyomtatas;
end;






end;

end.
