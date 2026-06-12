unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Grids, DB, DBGrids, DBTables, StrUtils,
  IBDatabase, IBCustomDataSet, IBTable, IBQuery, Printers;

type
  TNAPIFORGALOMFORM = class(TForm)
    ESCAPEGOMB: TBitBtn;
    HZARSOURCE: TDataSource;
    ADATRACS: TDBGrid;
    Label1: TLabel;
    NYOMTATOGOMB: TBitBtn;
    HAVIZARTABLA: TIBTable;
    HAVIZARDBASE: TIBDatabase;
    HAVIZARTRANZ: TIBTransaction;
    HAVIZARTABLAVALUTANEM: TIBStringField;
    HAVIZARTABLANYITO: TIntegerField;
    HAVIZARTABLAELADAS: TIntegerField;
    HAVIZARTABLAZARO: TIntegerField;
    HAVIZARTABLAZAROFORINTERTEK: TIntegerField;
    HAVIZARTABLAVALUTANEV: TIBStringField;
    HAVIZARTABLAVETELIARFOLYAM: TFloatField;
    HAVIZARTABLAELADASIARFOLYAM: TFloatField;
    HAVIZARTABLAELSZAMOLASIARFOLYAM: TFloatField;
    HAVIZARTABLAVETEL: TIntegerField;
    HAVIZARTABLAATVETEL: TIntegerField;
    HAVIZARTABLAATADAS: TIntegerField;
    VALUTAQUERY: TIBQuery;
    VALUTATABLA: TIBTable;
    VALUTADBASE: TIBDatabase;
    VALUTATRANZ: TIBTransaction;
    VALDATATABLA: TIBTable;
    VALDATAQUERY: TIBQuery;
    VALDATADBASE: TIBDatabase;
    VALDATATRANZ: TIBTransaction;

    procedure ESCAPEGOMBClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure NapiForgalomJob;
    procedure Nyomtatas;
    procedure NYOMTATOGOMBClick(Sender: TObject);

    procedure GetHaviNyitok;
    procedure GetHaviForgalom;
    procedure GetNapiNyitok;
    procedure GetNapiforgalom;
    procedure HzarBeiras;
    procedure Zaroszamitas;
    procedure ValutaParancs(_ukaz: string);
    procedure AlapadatBeolvasas;
    procedure Blokkfocimiro;
    procedure TextKiiro;
    procedure KozepreIr(_szoveg: string);

    function Scandnem(_dn: string): byte;
    function Elokieg(_szo: string;_hh: integer):string;
    function Nulele(_b: byte): string;
    function FormKiir(_in: integer):string;
    function ForintForm(_osszeg:integer):string;
    function Getidos: string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  NAPIFORGALOMFORM: TNAPIFORGALOMFORM;
  _penztarnak,_penztartol: integer;
  _pillertek,_aktbankjegy,_aktertek,_code,_bk,_bkktsg: integer;
  _aktzaro,_aktvetel,_akteladas,_aktatadas,_aktatvetel: integer;
  _aktnyito: integer;

  _LFile: textfile;

  _top,_left,_height,_width: word;
  _stornojel,_hufindex,_xx,_printer,_postterm: byte;
  _homepenztarkod,_homepenztarnev,_homepenztarcim: string;
  _aktdnem,_elojel,_bizonylatszam,_megnyitottnap,_farok,_elofarok,_pcs: string;
  _hzTablanev,_haviteteltablanev,_tipus,_idos,_kftnev: string;
  _sorveg: string = chr(13)+chr(10);

   _valutadarab: byte = 27;
   _dnem: array[1..27] of string = ('AUD','BAM','BGN','BRL','CAD','CHF','CNY',
                       'CZK','DKK','EUR','GBP','HRK','HUF','ILS','JPY','MXN',
                       'NOK','NZD','PLN','RON','RSD','RUB','SEK','THB','TRY',
                       'UAH','USD');

  _dnev: array[1..27] of string = ('Ausztral dollar','Bosnyak marka','Bolgar leva',
         'Brazil real','Kanadai dollar','Svajci frank','Kinai juan','Cseh korona',
         'Dan korona','Euro','Angol font','Horvat kuna','Magyar forint','Izraeli shakel',
         'Japan jen','Mexikoi peso','Norveg korona','Ujzelandi dollar',
         'Lengyel zloty','Roman lei','Szerb dinar','Orosz rubel','Sved korona',
         'Thai bath','Torok lira','Ukran hrivnya','Usa dollar');

   _hnyito,_vetel,_eladas,_zaro,_nNyito,_atvetel,_atadas: array[1..27] of integer;      

function napiforgalomrutin: integer; stdcall;

implementation

{$R *.dfm}

function napiforgalomrutin: integer; stdcall;
begin
  NapiforgalomForm := TNapiforgalomform.create(Nil);
  result := Napiforgalomform.showmodal;
  Napiforgalomform.Free;
end; 


// =============================================================================
           procedure TNAPIFORGALOMFORM.FormActivate(Sender: TObject);
// =============================================================================

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := round((_height-768)/2);
  _left := round((_width-1024)/2);

  Top    := _top;
  Left   := _left;
  Width  := 1024;
  Height := 768;

  _hufindex := scAndnem('HUF');

  Alapadatbeolvasas;

  HZarSource.Enabled := False;
  AdatRacs.Visible := False;
  
  NapiForgalomJob;
end;


function TnapiForgalomForm.Scandnem(_dn: string): byte;

var _y : byte;

begin
  result := 0;
  _y := 1;
  while _y<=_valutadarab do
    begin
      if _dnem[_y] = _dn then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;



// =============================================================================
                    procedure TNapiForgalomForm.NapiForgalomJob;
// =============================================================================

begin
  GetHavinyitok;
  GetHaviForgalom;
  GetNapinyitok;
  GetNapiforgalom;
  Zaroszamitas;
  HzarBeiras;
  HavizarDbase.Connected := true;
  HavizarTabla.Open;
  HzarSource.Enabled := True;
  AdatRacs.Visible := True;
  ActiveControl := AdatRacs;
end;


// =============================================================================
         procedure TNAPIFORGALOMFORM.NYOMTATOGOMBClick(Sender: TObject);
// =============================================================================

begin
  Nyomtatas;
end;


// =============================================================================
        procedure TNAPIFORGALOMFORM.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
  HavizarTabla.close;
  Havizardbase.close;
  ModalResult := 2;
end;

// =============================================================================
      procedure TNAPIFORGALOMFORM.GetHavinyitok;
// =============================================================================

var _evtizes,_hos: string;
    _akttized,_aktho,_elotized,_eloho: word;
    _y: byte;

begin
   for _y := 1 to _valutadarab do _hnyito[_y] := 0;

  _evtizes := midstr(_megnyitottnap,3,2);
  _hos := midstr(_megnyitottnap,6,2);

  _farok := _evtizes + _hos;


  val(_evtizes,_akttized,_code);
  val(_hos,_aktho,_code);

  _elotized := _akttized;
  _eloho    := _aktho;

  dec(_eloho);
  if _eloho<1 then
    begin
      _eloho := 12;
      dec(_elotized);
    end;
  _elofarok := inttostr(_elotized)+nulele(_eloho);
  _hztablanev := 'HZ' + _elofarok;
  _haviteteltablanev := 'BT' + _FAROK;

  Valdatadbase.connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      Sql.add('SELECT * FROM ' + _hztablanev);
      Open;
    end;

  while not ValdataQuery.eof do
    begin
      _aktdnem := ValdataQuery.fieldByName('VALUTANEM').asstring;
      _aktzaro := ValdataQuery.FieldByName('ZARO').asInteger;
      _xx := scandnem(_aktdnem);
      _hnyito[_xx] := _aktzaro;
      ValdataQuery.next;
    end;
  ValdataQuery.close;
  Valdatadbase.close;
end;

// =============================================================================
              procedure TNapiForgalomForm.GetHaviforgalom;
// =============================================================================

var _y: byte;

begin
  for _y := 1 to _valutadarab do
    begin
      _vetel[_y] := 0;
      _eladas[_y] := 0;
      _atvetel[_y] := 0;
      _atadas[_y] := 0;
    end;


  _pcs := 'SELECT * FROM ' + _haviteteltablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM<' +chr(39) + _megnyitottnap + chr(39) +') AND (';
  _pcs := _pcs + 'STORNO=1)';

  ValdataDbase.connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  while not ValdataQuery.eof do
    begin
      _bizonylatszam := ValdataQuery.FieldbyName('BIZONYLATSZAM').asString;
      _aktdnem := ValdataQuery.FieldByNAme('VALUTANEM').asString;
      _aktbankjegy := ValdataQuery.FieldByNAme('BANKJEY').asInteger;
      _aktertek := ValdataQuery.FieldByNAme('FORINTERTEK').asInteger;
      _tipus := leftstr(_bizonylatszam,1);

      _xx := Scandnem(_aktdnem);

      if _tipus='V' then
        begin
          _vetel[_xx] := _vetel[_xx] + _aktbankjegy;
          _eladas[_hufindex] := _eladas[_hufindex] + _aktertek;
        end;

      if _tipus='E' then
        begin
          _eladas[_xx] := _eladas[_xx] + _aktbankjegy;
          if _xx<>_hufindex then
                _vetel[_hufindex] := _vetel[_hufindex] + _aktertek;
        end;

      if _tipus='U' then _atvetel[_xx] := _atvetel[_xx] + _aktbankjegy;
      if _tipus='F' then _atadas[_xx] := _atadas[_xx] + _aktbankjegy;

      ValdataQuery.next;
    end;
  valdatadbase.close;
end;

// =============================================================================
               procedure TNapiForgalomForm.Getnapinyitok;
// =============================================================================

var _y: byte;

begin
  for _y := 1 to _valutadarab do _nNyito[_y] := 0;

  _xx := 1;
  while _xx<=_valutadarab do
    begin
      _nNyito[_xx] := _Hnyito[_xx]+_vetel[_xx]-_eladas[_xx]+_atvetel[_xx]-_atadas[_xx];
      inc(_xx);
    end;
end;

// =============================================================================
              procedure TNapiForgalomForm.GetNapiforgalom;
// =============================================================================

var _y: byte;

begin
  for _y := 1 to _valutadarab do
    begin
      _vetel[_y] := 0;
      _eladas[_y] := 0;
      _atvetel[_y] := 0;
      _atadas[_y] := 0;
    end;
  _pcs := 'SELECT * FROM ' + _haviteteltablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM=' + chr(39)+_megnyitottnap+chr(39)+')';
  _pcs := _pcs + ' AND (STORNO=1)';

  ValdataDbase.connected := true;
  with ValdataQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  while not Valdataquery.eof do
    begin
      _bizonylatszam := ValdataQuery.FieldbyName('BIZONYLATSZAM').asString;
      _aktdnem := ValdataQuery.FieldByNAme('VALUTANEM').asString;
      _aktbankjegy := ValdataQuery.FieldByNAme('BANKJEY').asInteger;
      _aktertek := ValdataQuery.FieldByNAme('FORINTERTEK').asInteger;
      _tipus := leftstr(_bizonylatszam,1);

      _xx := Scandnem(_aktdnem);

      if _tipus='V' then
        begin
          _vetel[_xx] := _vetel[_xx] + _aktbankjegy;
          _eladas[_hufindex] := _eladas[_hufindex] + _aktertek;
        end;

      if _tipus='E' then
        begin
          _eladas[_xx] := _eladas[_xx] + _aktbankjegy;
          if _xx<>_hufindex then
                _vetel[_hufindex] := _vetel[_hufindex] + _aktertek;
        end;

      if _tipus='U' then _atvetel[_xx] := _atvetel[_xx] + _aktbankjegy;
      if _tipus='F' then _atadas[_xx] := _atadas[_xx] + _aktbankjegy;

      ValdataQuery.next;
    end;
  valdatadbase.close;

  // ---------------------------------------------------------------------------

  _pcs := 'SELECT * FROM BLOKKTETEL' + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM=' + chr(39)+_megnyitottnap+chr(39)+')';
  _pcs := _pcs + ' AND (STORNO=1)';

  ValUtaDbase.connected := true;
  with ValUtaQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
    end;

  while not Valutaquery.eof do
    begin
      _bizonylatszam := ValutaQuery.FieldbyName('BIZONYLATSZAM').asString;
      _aktdnem := ValUtaQuery.FieldByNAme('VALUTANEM').asString;
      _aktbankjegy := ValutaQuery.FieldByNAme('BANKJEGY').asInteger;
      _aktertek := ValutaQuery.FieldByNAme('FORINTERTEK').asInteger;
      _tipus := leftstr(_bizonylatszam,1);

      _xx := Scandnem(_aktdnem);

      if _tipus='V' then
        begin
          _vetel[_xx] := _vetel[_xx] + _aktbankjegy;
          _eladas[_hufindex] := _eladas[_hufindex] + _aktertek;
        end;

      if _tipus='E' then
        begin
          _eladas[_xx] := _eladas[_xx] + _aktbankjegy;
          if _xx<>_hufindex then
                _vetel[_hufindex] := _vetel[_hufindex] + _aktertek;
        end;

      if _tipus='U' then _atvetel[_xx] := _atvetel[_xx] + _aktbankjegy;
      if _tipus='F' then _atadas[_xx] := _atadas[_xx] + _aktbankjegy;

      ValutaQuery.next;
    end;
  valutadbase.close;
end;

// =============================================================================
                   procedure TNapiForgalomForm.Zaroszamitas;
// =============================================================================

var _y: byte;

begin
  for _y := 1 to _valutadarab do _Zaro[_y] := 0;

  _xx := 1;
  while _xx<=_valutadarab do
    begin
      _zaro[_xx] := _nNyito[_xx]+_vetel[_xx]-_eladas[_xx]+_atvetel[_xx]-_atadas[_xx];
      inc(_xx);
    end;
end;

// =============================================================================
                  procedure TNapiForgalomForm.HzarBeiras;
// =============================================================================

begin
  _pcs := 'DELETE FROM HAVIZAR';
  ValutaParancs(_pcs);

  _xx := 1;
  while _xx<=_valutadarab do
    begin
      _aktDnem  := _dnem[_xx];
      _aktnyito := _nNyito[_xx];
      _aktvetel := _vetel[_xx];
      _akteladas := _eladas[_xx];
      _aktatvetel := _atvetel[_xx];
      _aktatadas := _atadas[_xx];
      _aktzaro := _zaro[_xx];

      if (_aktnyito=0) and (_aktvetel=0) and (_akteladas=0) then
        begin
          if (_aktatvetel=0) and (_aktatadas=0) then
             begin
               inc(_xx);
               Continue;
             end;
        end;
      _pcs := 'INSERT INTO HAVIZAR (VALUTANEM,NYITO,VETEL,ELADAS,ATVETEL,ATADAS,ZARO)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + chr(39) + _aktdnem + chr(39) + ',';
      _pcs := _pcs + inttostr(_aktnyito)+',';
      _pcs := _pcs + inttostr(_aktvetel) + ',';
      _pcs := _pcs + inttostr(_akteladas) + ',';
      _pcs := _pcs + inttostr(_aktatvetel) + ',';
      _pcs := _pcs + inttostr(_aktatadas) + ',';
      _pcs := _pcs + inttostr(_aktzaro) + ')';
      ValutaParancs(_pcs);
      inc(_xx);
    end;
end;

// =============================================================================
                    procedure TNapiForgalomForm.Nyomtatas;
// =============================================================================

begin
  BlokkFocimIro;
  _idos := GetIdos;

  writeLn(_LFile,'    NAPI FORGALOM KIMUTATASA - I.');
  writeln(_LFile,dupestring('-',40));
  writeLn(_LFile,'Datum     (DATE)'+dupestring(' ',10)+':   '+_megnyitottnap);
  writeLN(_LFile,'Ido       (TIME)'+dupestring(' ',10)+':    '+_idos);
  writeln(_LFile,dupestring('-',40));
  writeLn(_Lfile,'DNEM     NYITO       VETEL      ELADAS');
  writeln(_LFile,dupestring('-',40));

  Havizartabla.First;
  while not HavizarTabla.eof do
    begin
      with HavizarTabla do
        begin
          _aktdnem := FieldByname('VALUTANEM').ASsTRING;
          _aktnyito := FieldByNAme('NYITO').asInteger;
          _akteladas := FieldByName('ELADAS').asInteger;
          _aktvetel := FieldByName('VETEL').asInteger;
        end;

      write(_LFile,_aktdnem+' ');
      write(_Lfile,FormKiir(_aktnyito)+'  ');
      write(_Lfile,Formkiir(_aktvetel)+'  ');
      writeLn(_LFile,Formkiir(_akteladas));
      HavizarTabla.next;
    end;

  writeln(_LFile,dupestring('-',40));
  writeLn(_Lfile,'    NAPI FORGALOM KIMUTATASA - II.');
  writeln(_LFile,dupestring('-',40));

  writeLn(_Lfile,'DNEM ATAD-PTNAK ATVET-PTTOL      ZARO');
  writeln(_LFile,dupestring('-',40));

  HavizarTabla.First;
  while not HavizarTabla.eof do
    begin
      with HaviZarTabla do
        begin
          _aktdnem := FieldByName('VALUTANEM').asString;
          _aktatadas := FieldByName('ATADAS').asInteger;
          _aktatvetel := FieldByName('ATVETEL').asInteger;
          _aktzaro := FieldByName('ZARO').asInteger;
        end;

      write(_Lfile,_aktdnem+' ');
      write(_LFile,formKiir(_aktatadas)+' ');
      write(_LFile,FormKiir(_aktatvetel)+' ');
      writeLn(_LFile,FormKiir(_aktzaro));
      HavizarTabla.Next;

    end;

  writeln(_LFile,dupestring('-',40));
  writeLn(_LFile,_sorveg+_sorveg+_sorveg);
  CloseFile(_LFile);
  TextKiiro;

end;


function TNapiForgalomForm.Getidos: string;

begin
  result := timetostr(Time);
  if midstr(result,2,1)=':' then result := '0' + result;
end;


function TNapiForgalomForm.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


procedure TNapiForgalomForm.ValutaParancs(_ukaz: string);

begin
  Valutadbase.connected := True;
  if Valutatranz.InTransaction then Valutatranz.Commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_ukaz);
      ExecSql;
    end;
  ValutaTranz.Commit;
  ValutaDbase.close;
end;


// =============================================================================
                  function TNapiForgalomForm.FormKiir(_in: integer):string;
// =============================================================================
begin
  Result := ForintForm(_in);
  Result := EloKieg(Result,11);
end;


// =============================================================================
         procedure TNapiForgalomForm.KozepreIr(_szoveg: string);
// =============================================================================

var _oo: integer;

begin
  _szoveg := trim(_szoveg);
  _oo := trunc((40-length(_szoveg))/2);
  writeLn(_LFile,dupestring(' ',_oo)+_szoveg);
end;




// =============================================================================
           function TNapiForgalomForm.Elokieg(_szo: string;_hh: integer):string;
// =============================================================================

begin
  if length(_szo)>=_hh then
    begin
      Result := leftStr(_szo,_hh);
      exit;
    end;

  while length(_szo)<_hh do _szo := ' '+_szo;

  Result := _szo;
end;




// =============================================================================
             function TNapiForgalomForm.ForintForm(_osszeg:integer):string;
// =============================================================================

var _slen,_pp: integer;
    _ejel : string;

begin
  Result := '-';

  if _osszeg=0 then exit;

  _ejel := '';

  if _osszeg<0 then
    begin
      _ejel := '-';
      _osszeg := abs(_osszeg);
    end;

  Result := intTostr(_osszeg);

  if _osszeg<1000 then
    begin
      Result := _ejel + Result;
      Exit;
    end;

  _sLen := length(Result);
  if _osszeg>999999 then
    begin
      _pp := _sLen-5;
      Result := _ejel + midStr(Result,1,_pp-1)+','+midStr(Result,_pp,3)+','+midStr(Result,_pp+3,3);
      Exit;
    end;

  _pp := _sLen-2;
  Result := _ejel + midStr(result,1,_pp-1)+','+midStr(result,_pp,3);

end;

// =============================================================================
                  procedure TNapiForgalomForm.TextKiiro;
// =============================================================================

var _mondat: string;
    _nyomtat,_olvas: textFile;

begin

  if _printer<>1 then AssignFile(_nyomtat,'LPT1')
  else AssignPrn(_nyomtat);
  Rewrite(_nyomtat);
  AssignFile(_olvas,'c:\valuta\aktlst.txt');
  Reset(_olvas);

  while not eof(_olvas) do
    begin
      readln(_olvas,_mondat);
      writeln(_nyomtat,_mondat);
    end;
  System.closeFile(_nyomtat);
  System.CloseFile(_olvas);
end;

procedure TNapiforgalomForm.AlapadatBeolvasas;

begin
  Valutadbase.connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      sql.add('SELECT * FROM HARDWARE');
      Open;
      _megnyitottnap := FieldByNAme('MEGNYITOTTNAP').asString;
      _printer := FieldByName('PRINTER').asInteger;
      _kftnev := trim(FieldByNAme('KFTNEV').AsString);
      _postterm:= FieldByNAme('POSTTERM').asInteger;
      _bk := Fieldbyname('BANKKARTYA').asInteger;
      _bkktsg := Fieldbyname('BKKOLTSEG').asInteger;

      Close;
      sql.clear;
      sql.add('SELECT * FROM PENZTAR');
      Open;
      _homepenztarkod := trim(FieldByNAme('PENZTARKOD').asString);
      _homePenztarnev := trim(FieldByNAme('PENZTARNEV').asString);
      _homePenztarCim := trim(FieldByNAme('PENZTARCIM').asString);
      Close;
    end;
  Valutadbase.close;
end;

// =============================================================================
                 procedure  TNapiforgalomForm.Blokkfocimiro;
// =============================================================================

begin
  Assignfile(_LFile,'c:\valuta\aktlst.txt');
  rewrite(_LFile);
  Kozepreir('EXCLUSIVE BEST CHANGE ZRT');
  Kozepreir(_homePenztarkod+' '+_homepenztarnev);
  Kozepreir(_homepenztarcim);
  writeLN(_LFile,dupestring('-',40));
end;



end.
