unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, dateUtils, IBDatabase, DB, IBCustomDataSet, IBTable, IBQuery,
  ExtCtrls;

type
  TForm2 = class(TForm)
    VALDATATABLA: TIBTable;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;
    VALDATAQUERY: TIBQuery;
    INDITOTIMER: TTimer;

    procedure FormActivate(Sender: TObject);

    function Nulele(_int: integer):string;
    function TablaExists(_ptName: string): boolean;

    procedure SetFileNevek;

    procedure BlokkfejMake;
    procedure BlokktetMake;
    procedure CimtarMake;
    procedure NarfMake;

    procedure KezdijMake;
    procedure KDataMake;

    procedure EkerMake;
    procedure EdatMake;

    procedure WuAfaMake;
    procedure WzaroMake;
   
    procedure IbParancs(_ukaz: string);
    procedure InditoTimerTimer(Sender: TObject);
    procedure CimletCfgControl;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

  _aktev,_akthonap: word;

  _fejFileNev,_tetFileNev,_narfFileNev,_ctFileNev,_ekerNev,_eDatnev: string;
  _kezdijnev,_kDatnev,_wuFileNev,_wzFileNev,_farok,_pcs: string;
  _sorveg: string = chr(13)+chr(10);

  _charsor: string = ' CHARACTER SET WIN1250';
  _collate: string = ' COLLATE WIN1250';
  _vSorveg: string = #44#13#10;


function makeibtablak: integer; stdcall;

implementation


{$R *.dfm}

// =============================================================================
                     function makeibtablak: integer; stdcall;
// =============================================================================

begin
  Form2 := TForm2.create(Nil);
  Result := Form2.Showmodal;
  Form2.Free;
end;


procedure TForm2.FormActivate(Sender: TObject);
begin
  Form2.Visible := False;
  InditoTimer.enabled := true;
end;



// =============================================================================
        procedure TForm2.INDITOTIMERTimer(Sender: TObject);
// =============================================================================

begin
  InditoTimer.Enabled := False;
 
  SetfileNevek;

  BlokkFejMake;
  BlokkTetMake;

  CimtarMake;
  NarfMake;

  KezdijMake;
  KDataMake;

  EkerMake;
  EdatMake;

  WuafaMake;
  WzaroMake;

  CimletCfgControl;
  ModalResult := 1;
end;


// =============================================================================
                          procedure TFORM2.SetFileNevek;
// =============================================================================

begin
  _aktEv := yearOf(Date);
  _aktHonap := monthof(Date);

  _Farok := Nulele(_aktEv-2000) + Nulele(_aktHonap);

  _fejFileNev  := 'BF' + _farok;
  _tetFileNev  := 'BT' + _farok;
  _narfFileNev := 'NARF' + _farok;
  _ctFileNev   := 'CIMT' + _farok;

  _ekerNev     := 'EKER' + _farok;
  _edatNev     := 'EDAT' + _farok;

  _kezdijnev   := 'KEZD' + _farok;
  _kdatnev     := 'KDAT' + _farok;

  _wuFileNev   := 'WUNI' + _farok;
  _wzFileNev   := 'WZAR' + _farok;
end;

// =============================================================================
                           procedure TFORM2.BlokkfejMake;
// =============================================================================

begin
  if TablaExists(_fejFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _fejfileNev + ' (' + _sorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR(10)'+ _charsor+_collate+_vSorveg;
  _pcs := _pcs + 'TIPUS CHAR (1)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'DATUM CHAR(10)'+ _charsor + _vSorveg;
  _pcs := _pcs + 'IDO CHAR (8)'+_vsorveg;
  _pcs := _pcs + 'FORINTERTEK INTEGER'+_vsorveg;
  _pcs := _pcs + 'TETEL SMALLINT' + _vsorveg;
  _pcs := _pcs + 'TRBPENZTAR CHAR (3)' + _vsorveg;
  _pcs := _pcs + 'TARSPENZTARKOD CHAR (4)' + _vsorveg;
  _pcs := _pcs + 'PENZTAROSNEV CHAR (24)' + _vSorveg;
  _pcs := _pcs + 'IDKOD CHAR (5)' + _vsorveg;
  _pcs := _pcs + 'PLOMBASZAM CHAR (10)' + _vSorveg;
  _pcs := _pcs + 'SZALLITONEV CHAR(20)' + _vSorveg;
  _pcs := _pcs + 'STORNO SMALLINT' + _vsorveg;
  _pcs := _pcs + 'STORNOBIZONYLAT CHAR (10))';
  IbParancs(_pcs);

  _pcs := 'CREATE INDEX ' + 'X'+ _fejFileNev + _sorveg;
  _pcs := _pcs + 'ON '+ _fejFileNev + '(DATUM)';
  ibParancs(_pcs);
end;


// =============================================================================
                       procedure TFORM2.BlokktetMake;
// =============================================================================

begin
  if TablaExists(_tetFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _tetfileNev + ' (' +_sorveg ;
  _pcs := _pcs + 'DATUM CHAR(10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'BIZONYLATSZAM CHAR(10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3)' + _vsorveg;
  _pcs := _pcs + 'ARFOLYAM INTEGER' + _vsorveg;
  _PCS := _pcs + 'ELSZAMOLASIARFOLYAM INTEGER' + _VSORVEG;
  _pcs := _pcs + 'BANKJEGY INTEGER' + _vsorveg;
  _pcs := _pcs + 'FORINTERTEK INTEGER' + _vsorveg;
  _pcs := _pcs + 'ELOJEL CHAR (1)' + _vsorveg;
  _pcs := _pcs + 'TORTRESZ CHAR (4)' + _vsorveg;
  _pcs := _pcs + 'STORNO SMALLINT)';
  iBParancs(_pcs);

  _pcs := 'CREATE INDEX ' + 'X'+_tetfileNev + _SORVEG;
  _pcs := _pcs + 'ON ' + _tetFileNev + ' (BIZONYLATSZAM)';
  ibParancs(_pcs);
end;

// =============================================================================
                         procedure TFORM2.CimtarMake;
// =============================================================================

begin
  if TablaExists(_ctFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _ctfileNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10)' + _vsorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3)' + _vsorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER' + _vsorveg;
  _pcs := _pcs + 'PROSSZAM SMALLINT' + _vsorveg;
  _pcs := _pcs + 'CIMLET1 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET2 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET3 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET4 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET5 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET6 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET7 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET8 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET9 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET10 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET11 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET12 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET13 INTEGER'+ _vsorveg;
  _pcs := _pcs + 'CIMLET14 INTEGER)';
  ibParancs(_pcs);

   _pcs := 'CREATE INDEX X' + _ctfileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _ctfileNev + ' (VALUTANEM)';
  ibParancs(_pcs);
end;

// =============================================================================
                               procedure TFORM2.NarfMake;
// =============================================================================

begin
  if TablaExists(_narfFilenev) then exit;

  _pcs := 'CREATE TABLE ' + _narffileNev + ' ('+_sorveg;
  _pcs := _pcs + 'DATUM CHAR (10)' + _vsorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3)' + _vSorveg;
  _pcs := _pcs + 'ELSZAMOLASIARFOLYAM INTEGER' + _vsorveg;
  _pcs := _pcs + 'NYITO INTEGER'+_vsorveg;
  _pcs := _pcs + 'ZARO INTEGER)';
  ibParancs(_pcs);

  _pcs := 'CREATE INDEX X' + _narffileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _narffileNev + ' (DATUM)';
  ibParancs(_pcs);
end;


// =============================================================================
                       procedure TFORM2.KezdijMake;
// =============================================================================

begin
  if TablaExists(_kezdijnev) then exit;

  _pcs := 'CREATE TABLE ' + _kezdijNev + ' (' +_sorveg ;
  _pcs := _pcs + 'DATUM CHAR(10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'BIZONYLAT CHAR (8)' + _charsor + _vsorveg;
  _pcs := _pcs + 'ELOJEL CHAR (1)' + _charsor + _vsorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER' + _vsorveg;
  _pcs := _pcs + 'STORNO SMALLINT' + _vsorveg;
  _pcs := _pcs + 'PENZTAR CHAR (4))';

  iBParancs(_pcs);

  _pcs := 'CREATE INDEX ' + 'X'+_KEZDIJNev + _SORVEG;
  _pcs := _pcs + 'ON ' + _kezdijNev + ' (BIZONYLAT)';
  ibParancs(_pcs);
end;


// =============================================================================
                       procedure TFORM2.KDataMake;
// =============================================================================

begin
  if TablaExists(_kdatnev) then exit;

  _pcs := 'CREATE TABLE ' + _kdatNev + ' (' +_sorveg ;
  _pcs := _pcs + 'DATUM CHAR(10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'NYITO INTEGER' + _vSorveg;
  _pcs := _pcs + 'BEVETEL INTEGER' + _vSorveg;
  _pcs := _pcs + 'KIADAS INTEGER' + _vSorveg;
  _pcs := _pcs + 'ZARO INTEGER)';
  ibParancs(_pcs);
end;


// =============================================================================
                       procedure TFORM2.EkerMake;
// =============================================================================

begin
  if TablaExists(_ekernev) then exit;

  _pcs := 'CREATE TABLE ' + _ekerNev + ' (' +_sorveg ;
  _pcs := _pcs + 'DATUM CHAR(10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'BIZONYLAT CHAR (10)' + _charsor + _vsorveg;
  _pcs := _pcs + 'ELOJEL CHAR (1)' + _charsor + _vsorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER' + _vsorveg;
  _pcs := _pcs + 'STORNO SMALLINT' + _vsorveg;
  _pcs := _pcs + 'PENZTAR CHAR (4))';

  iBParancs(_pcs);
end;


// =============================================================================
                       procedure TFORM2.EDatMake;
// =============================================================================

begin
  if TablaExists(_edatnev) then exit;

  _pcs := 'CREATE TABLE ' + _edatNev + ' (' +_sorveg ;
  _pcs := _pcs + 'DATUM CHAR(10)'+ _charsor+_vSorveg;
  _pcs := _pcs + 'NYITO INTEGER' + _vSorveg;
  _pcs := _pcs + 'BEVETEL INTEGER' + _vSorveg;
  _pcs := _pcs + 'KIADAS INTEGER' + _vSorveg;
  _pcs := _pcs + 'ZARO INTEGER)';
  ibParancs(_pcs);
end;


// =============================================================================
                       procedure TFORM2.WuAfaMake;
// =============================================================================

begin
  if TablaExists(_wufilenev) then exit;

  _pcs := 'CREATE TABLE ' + _wufileNev + '(';
  _pcs := _pcs + 'DATUM CHAR (10)' + _vSorveg;
  _pcs := _pcs + 'VALUTANEM CHAR (3)' + _vsorveg;
  _pcs := _pcs + 'BIZONYLAT CHAR (10)' + _vSorveg;
  _pcs := _pcs + 'BANKJEGY INTEGER' + _vSorveg;
  _pcs := _pcs + 'ELOJEL CHAR (1)'+ _vsorveg;
  _pcs := _pcs + 'PENZTAR CHAR (4)' + _vSorveg;
  _pcs := _pcs + 'STORNO SMALLINT' + _vSorveg;
  _pcs := _pcs + 'BIZTIPUS CHAR (2))';
  ibParancs(_pcs);

   _pcs := 'CREATE INDEX X' + _wufileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _wufileNev + ' (DATUM)';
  ibParancs(_pcs);

end;


// =============================================================================
                                procedure TFORM2.WZaroMake;
// =============================================================================

begin
  if TablaExists(_wzfilenev) then exit;

  _pcs := 'CREATE TABLE ' + _wzfileNev + '(';
  _pcs := _pcs + 'DATUM CHAR (10)' + _vsorveg;
  _pcs := _pcs + 'USDNYITO INTEGER' + _vsorveg;
  _pcs := _pcs + 'HUFNYITO INTEGER' + _vsorveg;
  _pcs := _pcs + 'AFANYITO INTEGER' + _vsorveg;

  _pcs := _pcs + 'USDZARO INTEGER'+_vsorveg;
  _pcs := _pcs + 'HUFZARO INTEGER'+_vsorveg;
  _pcs := _pcs + 'AFAZARO INTEGER'+_vsorveg;

  _pcs := _pcs + 'USDBEVETEL INTEGER'+_vsorveg;
  _pcs := _pcs + 'HUFBEVETEL INTEGER'+_vsorveg;
  _pcs := _pcs + 'AFABEVETEL INTEGER'+_vsorveg;

  _pcs := _pcs + 'USDKIADAS INTEGER'+_vsorveg;
  _pcs := _pcs + 'HUFKIADAS INTEGER'+_vsorveg;
  _pcs := _pcs + 'AFAKIADAS INTEGER)';

  ibParancs(_pcs);

   _pcs := 'CREATE INDEX X' + _wzfileNev + _sorveg;
  _pcs := _pcs + 'ON ' + _wzfileNev + ' (DATUM)';
  ibParancs(_pcs);

end;


function TForm2.Nulele(_int: integer):string;

begin
  result := inttostr(_int);
  if _int<10 then result := '0' + result;
end;

// =============================================================================
           function TForm2.TablaExists(_ptName: string): boolean;
// =============================================================================


begin
  Valdatadbase.connected := true;
  result := True;
  ValdataTabla.close;
  ValdataTabla.tablename := _ptname;
  if ValdataTabla.Exists then
    begin
      ValdataTabla.Close;
      ValdataDbase.close;
      exit;
    end;
  ValdataTabla.close;
  ValdataDbase.close;
  Result := False;
end;

// =============================================================================
                    procedure TForm2.Ibparancs(_ukaz: string);
// =============================================================================

begin
  ValdataDbase.connected := true;
  if ValdataTranz.InTransaction then ValdataTranz.Commit;
  ValdataTranz.StartTransaction;
  with ValdataQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_ukaz);
      ExecSql;
    end;
  ValdataTranz.Commit;
  ValdataDbase.close;
end;      

// =============================================================================
                      procedure TFORM2.CimletCfgControl;
// =============================================================================

var _cimletcfg: string;
    _cfg :textfile;
begin
  _cimletcfg := 'c:\ertektar\cimlet.cfg';
  if fileExists(_cimletCfg) then exit;

  AssignFile(_cfg,_cimletcfg);
  Rewrite(_cfg);
  writeLN(_cfg,'AUDFIJKLM');
  writeLN(_cfg,'BGNHIJKLMNO');
  writeLN(_cfg,'CADFIJKLM');
  writeLN(_cfg,'CHFHFGHIJKL');
  writeLN(_cfg,'CZKIDEFGHIJK');
  writeLN(_cfg,'DKKFFGHIJ');
  writeLN(_cfg,'EURJGHIJKLMNO');
  writeLN(_cfg,'GBPEJKLM');
  writeLN(_cfg,'HRKIFGHIJKLM');
  writeLN(_cfg,'HUFMBCDEFGHIJKLM');
  writeLN(_cfg,'ILSEHIJK');
  writeLN(_cfg,'JPYECDEF');
  writeLN(_cfg,'NOKFFGHIJ');
  writeLN(_cfg,'PLNFHIJKL');
  writeLN(_cfg,'RONHGHIJLMO');
  writeLN(_cfg,'RSDIDFGHIJKL');
  writeLN(_cfg,'RUBHDFGIJLM');
  writeLN(_cfg,'SEKFFGIJK');
  writeLN(_cfg,'SKKHDFGHIJK');
  writeLN(_cfg,'UAHHHIJKLMN');
  writeLN(_cfg,'USDHIJKLMNO');
  WriteLn(_cfg,'HUFMBCDEFGHUJKLM');
  CloseFile(_cfg);
  ShowMessage('A CIMLET KONFIGURÁCIÓS ÁLLOMÁNYÁT BEÁLLITOTTAM');
end;

end.

