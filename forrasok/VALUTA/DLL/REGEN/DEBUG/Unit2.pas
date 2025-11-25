unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StrUtils, ExtCtrls, StdCtrls, ComCtrls, IBQuery, IBDatabase, DB,
  IBCustomDataSet, IBTable, DateUtils;

type
  TREGENERALO = class(TForm)
    IDOZITO: TTimer;
    Panel1: TPanel;
    CSIK: TProgressBar;
    FASTCSIK: TProgressBar;
    regeninfopanel: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Shape1: TShape;
    Shape2: TShape;
    IBTABLA: TIBTable;
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;

  procedure FormActivate(Sender: TObject);
  procedure IdozitoTimer(Sender: TObject);
  procedure PillAllRegen;
  procedure WuniRegen;
  procedure DnemTolto;
  procedure ForgalomBedolgozas;
  procedure NyitoBetoltes;
  procedure EgyenlegBemasolas;
  procedure WuniNyitoBe;
  procedure WuniMozgasBe(_hn: string);
  procedure MetroMozgasBe(_hn: string);
  procedure TescoMozgasBe(_hn: string);
  procedure KezdijRegeneralo;
  procedure Kezdijregister;
  procedure HianyzoBizonylat;
  procedure RontottJeloles(_tnev: string);
  procedure TombbeOlvasas(_tnev: string);
  procedure iBParancs(_ukaz: string);
  procedure GetHardwareData;


  function Nulele(_int,_hh: integer): string;
  function Kerekites(_r: real): real;
  function Dnemscan(_egydnem:string): integer;
  function RealToStr(_rr: real): string;
  function Scanbiz(_bb: string):integer;
  function HunDatetostr(_caldat: TDateTime): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  REGENERALO: TREGENERALO;

  _dnem,_dnev: array of string;

  _aktValdataPath : string = 'c:\valuta\database\valdata.fdb';
  _aktValutaPath  : string = 'c:\valuta\database\valuta.fdb';

  _rnyito,_rZaro: array of real;
  _rkiadas,_rbevetel: array of real;

  _ub,_uk,_hb,_hk,_mb,_mk,_tb,_tk: array[1..31] of integer;
  _mv,_tv,_ukd: array[1..31] of integer;

  _uny,_hny,_tny,_mny,_uz,_hz,_tz,_mz,_ftss,_atadveszdij: integer;
  _valss,_max,_bankjegy,_wnap,_khavinyito,_knapinyito,_handfee: integer;
  _teteltombnev,_fnev,_tnev,_eloWzaroNev,_wzaroNev,_path: string;
  _top,_left,_height,_width,_cc,_gepfunkcio,_ertektar,_bkktsg: integer;
  _napNyitas,_farok,_elofarok,_zaroDstring,_pcs,_valutanem: string;
  _sorveg: string = chr(13)+chr(10);
  _aktdnem,_bizonylatszam,_elojel,_tipus,_datum,_ttipus,_biz: string;
  _aktBankjegy,_aktertek,_bankkartya,_kerekites: integer;
  _aktev,_aktho,_eloev,_eloho: word;
  _valutaDarab,_nyito,_zaro,_recno,_kezdij,_skezdij: integer;
  _ppp,_kezdijzaro,_utbevet,_napiatadatvetkezdij: integer;
  _napikezdijforgalom,_havikezdijforgalom: integer;
  _aktdnev,_havinapi,_bizonylat,_fejtombnev,_kezdtombnev: string;
  _volt: boolean;
  _biztomb: array[1..650] of string;
  _khavizaro,_knapizaro,_bizdb,_xx,_fizetoeszkoz: integer;
  _havikezdij,_napikezdij,_haviatad,_napiatad,_haviatvet,_napiatvet: integer;
  _feszkoz,_ftindex: byte;
  _utbizonylat: string;
  _iras: textfile;
  _notfree: string = 'c:\valuta\NOTFREE';

Function logirorutin(_para: pchar): integer; stdcall; external 'c:\valuta\bin\logiro.dll' name 'logirorutin';
function regeneralorutin(_cimpara: integer): integer; stdcall;


implementation

{$R *.dfm}

// =============================================================================
       function regeneralorutin(_cimpara: integer): integer; stdcall;
// =============================================================================


begin
  _ppp := _cimpara;
  Regeneralo := TRegeneralo.Create(Nil);
  result := Regeneralo.ShowModal;
  Regeneralo.Free;
end;



// =========================================================================
        procedure TREGENERALO.FormActivate(Sender: TObject);
// =========================================================================

var z: integer;

begin
// _ppp=1 -> pill. állás, _ppp=2 -> W.Union, _ppp=0 -> BOTH

//_ppp:=0;

  _top    := 0;
  _left   := 0;
  _width  := Screen.Monitors[0].width;
  _height := Screen.Monitors[0].Height;

  if _width>1024 then _left := trunc((_width-1024)/2);
  if _height>768 then _top  := trunc((_height-768)/2);

   // _NAPNYITAS STRING NAPJÁT KELL REGENERÁLNI

  Top    := _top + 290;
  Left   := _left + 270;

  Width  := 540;
  Height := 333;

  while fileExists(_notfree) do sleep(2000);
  logirorutin(pchar('Regeneráló rutin elindul...'));

  DnemTolto;

  GetHardwareData;

  _aktev := strtoint(leftstr(_napnyitas,4));
  _aktho := strtoint(midstr(_napnyitas,6,2));

  _eloEv := _aktev;
  _eloHo := _akthO-1;

  if _eloHo<1 then
    begin
      _eloHo := 12;
      dec(_eloev);
    end;

  _farok := midstr(_napnyitas,3,2)+midstr(_napnyitas,6,2);
  _zaroDstring := _napnyitas;

  _tetelTombNev := 'BT'+ _farok;
  _fejtombNev   := 'BF'+ _farok;
  _kezdtombnev  := 'KEZD' + _farok;

  _eloFarok := inttostr(_eloev-2000)+Nulele(_eloho,2);

  setlength(_rNyito,_valutaDarab);
  Setlength(_rZaro,_valutadarab);
  Setlength(_rBevetel,_valutadarab);
  Setlength(_rKiadas,_valutadarab);

  _bankkartya := 0;
  _bkktsg := 0;
  for z := 0 to _valutadarab-1 do
    begin
      _rNyito[z]   := 0;
      _rBevetel[z] := 0;
      _rKiadas[z]  := 0;
      _rZaro[z]    := 0;
    end;

  Idozito.Enabled := True;

end;

// ===================================================================
         procedure TRegeneralo.IdozitoTimer(Sender: TObject);
// ===================================================================

begin
  // Itt indul a regenerálás ténylegesen:

  Idozito.Enabled := False;     // Idözitö kikapcsolva

  if _ppp<2  then PillAllRegen; // Pillanatnyi allás regenerálása
  if (_ppp=0) OR (_ppp=2) then WuniRegen; // Western és Afa regenerálás

  logirorutin(pchar('Regenerálás befejezve'));


  ModalResult := 1;
end;

// ========================================================
           procedure TRegeneralo.PillAllRegen;
// ========================================================

var z: integer;

begin
  // Csikhuzás alapra állitva:

  // A forint indexét meg kell határozni:
  _ftSs := Dnemscan('HUF');

  Csik.Max := 90;
  FastCsik.Position := 0;
  FastCsik.Visible  := True;

// A havi nyitó értékek beolvasása

  Csik.Position := 0;

  // havi nyitó összegek betöltése _rnyito tömbökbe
  // a HUF mellett betölti _kezdijnyito értékét:

  NyitoBetoltes;
  Csik.Position := 20;

  // A havi adatok bedolgozása  bevétel, kiadás mezökbe:

  _havinapi := 'H';
  ForgalomBedolgozas;
  Csik.Position := 30;

  // A ma reggeli nyitók kiszámitása, a többi mezõ nullázva:
   for z := 0 to _valutaDarab-1 do
    begin
      _rnyito[z] := _rnyito[z] + _rbevetel[z] - _rkiadas[z];
      _rbevetel[z] := 0;
      _rkiadas[z]  := 0;
    end;

  Csik.Position := 40;

  // A mai napi forgalmak bedolgozása a bevétel, kiadás mezõibe

  _havinapi := 'N';
  ForgalomBedolgozas;
  Csik.Position := 50;

  // A pillanatnyi zárókészletek kiszámitása:

  for z := 0 to _valutadarab-1 do
           _rzaro[z] := _rnyito[z] + _rBevetel[z] - _rKiadas[z];

  Csik.Position := 60;

 // Az adatai átmásolása az árfolyámtáblába:

  EgyenlegBemasolas;
  Csik.Position := 0;
  KezdijRegeneralo;
  Csik.Position := 70;
  Kezdijregister;

  RegenInfoPanel.Caption := 'FÉLLÁBAS TÉTELEK ÉRVÉNYTELENÍTÉSE ..';
  RegenInfoPanel.Repaint;

  HianyzoBizonylat;
  Csik.Position := 90;
  sleep(100);
end;

// =============================================================================
                     procedure TRegeneralo.NyitoBetoltes;
// =============================================================================

var _nyitonev: string;

begin
  RegenInfoPanel.Caption := 'A HÓ ELEJI NYITÓKÉSZLETEK BEMÁSOLÁSA ..';
  RegenInfoPanel.Repaint;

  _nyitoNev := 'HZ' + _elofarok;

  ibdbase.close;
  ibdbase.DatabaseName := _aktvaldataPath;
  ibDbase.Connected := true;
  ibTabla.TableName := _nyitoNev;

  if not ibTabla.exists then
    begin
      ibdbase.close;
      ibdbase.DatabaseName := _aktvalutaPath;
      ibDbase.Connected := true;
      _nyitonev := 'PENZTARNYITO';
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _nyitonev;
  with ibQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _khaviNyito := 0;
  while not ibQuery.Eof do
    begin
      _nyito       := 0;
      with ibQuery do
        begin
          _aktdnem := FieldByName('VALUTANEM').asString;
          if _aktdnem='HUF' then _khavinyito := FieldByName('KEZDIJZARO').asInteger;
          _nyito   := FieldByName('ZARO').asInteger;
        end;

      _valss := DnemScan(_aktdnem);
      _rnyito[_valss] := _nyito;

      ibQuery.next;
    end;

  ibQuery.Close;
  ibdbase.close;
end;


// =============================================================================
           procedure TRegeneralo.ForgalomBedolgozas;
// =============================================================================

var _idsznev: string;
    _a: byte;
   
begin
  if _havinapi='H' then
    begin
      _idsznev := 'HAVI';
      _tNev := 'BT' + _farok;
      _fnev := 'BF' + _farok;

      with ibDbase do
        begin
          Close;
          DatabaseName := _aktvaldataPath;
          Connected := True;
        end;
    end
    else // -------------------------- Napi blokkok ----------------------------
    begin
      _idsznev := 'NAPI';
      _tNev := 'BLOKKTETEL';
      _fnev := 'BLOKKFEJ';
       with ibDbase do
        begin
          Close;
          DatabaseName := _aktvalutaPath;
          Connected := True;
        end;
    end;

  RegenInfoPanel.Caption := _idsznev+' FORGALMI ADATOK BEDOLGOZÁSA ..';
  RegenInfoPanel.Repaint;

  FastCsik.Position := 0;

  _pcs := 'SELECT * FROM '+ _tNEV + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1';


  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM '+ _fNev+' FEJ JOIN ' + _tNev+' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE FEJ.STORNO=1';

  with ibQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _max := recno;
    end;

  if _max = 0 then
    begin
      ibQuery.Close;
      Exit;
    end;

  FastCsik.Max := _max;
  _cc := 0;

  _bankkartya := 0;
  _bkktsg     := 0;
  _utbizonylat:='XXXXXXX';

  ibQuery.First;
  while not ibQuery.Eof do
    begin
      inc(_cc);
      FastCsik.Position := _cc;

      with ibQuery do
        begin
          _datum         := TRIM(FieldByName('DATUM').asString);
          _bizonylat     := FieldByName('BIZONYLATSZAM').asString;
          _tipus         := FieldByName('TIPUS').asstring;
          _aktDnem       := Fieldbyname('VALUTANEM').asString;
          _aktBankJegy   := FieldByname('BANKJEGY').AsInteger;
          _elojel        := FieldByName('ELOJEL').AsString;
          _aktertek      := FieldByname('FORINTERTEK').asinteger;
          _handfee       := FieldByName('KEZELESIDIJ').asInteger;
          _fizetoeszkoz  := FieldByName('FIZETOESZKOZ').asInteger;
          _kerekites     := FieldByName('KEREKITES').asInteger;
        end;

      _valss := Dnemscan(_aktdnem);

      // ha ilyen valuta nincs is, akkor ezt ignorálni

      if _valss=-1 then
        begin
          ibQuery.Next;
          Continue;
        end;

      If (_tipus='E') and (_aktdnem='HUF') then _a:= 1
      else begin


      // Bevétel vagy kiadás növekedik:
      if _elojel='+' then _rbevetel[_valss] := _rbevetel[_valss] + _aktbankjegy
      else _rkiadas[_valss] := _rkiadas[_valss] + _aktbankjegy;

      end;

      // Vételnél és eladásnál a forint a valutával ellentétesen nõ vagy csökken

      if _tipus='V' then
        begin
         _rkiadas[_ftss] := _rkiadas[_ftss] + _aktertek;
         if _utbizonylat<>_bizonylat then _rkiadas[_ftss] := _rKiadas[_ftss]+_kerekites;
        end;

      if (_tipus='E') and (_aktdnem<>'HUF') then
        begin
          if _fizetoeszkoz=1 then
            begin
              _rbevetel[_ftss] := _rbevetel[_ftss] + _aktertek;
              if _utbizonylat<>_bizonylat then _rbevetel[_ftss] := _rBevetel[_ftss]+_kerekites;
            end;

          if _fizetoeszkoz=2 then
            begin
              if (_datum=_napnyitas) then
                begin
                  _bankkartya := _bankkartya + _aktertek;
                  if (_utbizonylat<>_bizonylat) then _bkktsg := _bkktsg + _handfee+_kerekites;
                end;
            end;
        end;
      _utbizonylat := _bizonylat;
      ibQuery.Next;
    end;

  ibQuery.Close;
  ibDbase.close;
end;

// =============================================================================
                  procedure TRegeneralo.EgyenlegBemasolas;
// =============================================================================

var i: integer;
    _ftNyito,_ftBevetel,_ftKiadas,_ftZaro: real;


begin
  RegenInfoPanel.Caption := 'PILLANATNYI ÁLLÁS BEMÁSOLÁSA ..';
  RegenInfoPanel.Repaint;

  _ftNyito   := _rnyito[_ftIndex];
  _ftBevetel := _rBevetel[_ftIndex];
  _ftKiadas  := _rKiadas[_ftIndex];
  _ftZaro    := _rZaro[_ftIndex];

  _rNyito[_ftIndex]  := kerekites(_ftNyito);
  _rBevetel[_ftIndex]:= kerekites(_ftBevetel);
  _rKiadas[_ftIndex] := kerekites(_ftKiadas);
  _rZaro[_ftIndex]   := kerekites(_ftZaro);

  with ibDbase do
    begin
      Close;
      DatabaseName := _aktValutaPath;
    end;

  for i := 0 to _valutadarab-1 do
    begin
      _aktdnem := _dnem[i];

      _pcs := 'UPDATE ARFOLYAM ';

      _pcs := _pcs + 'SET NYITO=' + realtostr(_rnyito[i]) + ',';
      _pcs := _pcs + 'BEVETEL='   + realtostr(_rbevetel[i]) + ',';
      _pcs := _pcs + 'KIADAS='    + realtostr(_rkiadas[i]) + ',';
      _pcs := _pcs + 'ZARO='      + realtostr(_rzaro[i]) + _sorveg;
      _pcs := _pcs + 'WHERE VALUTANEM=' + chr(39) + _aktdnem + chr(39);
      ibParancs(_pcs);
    end;

  _pcs := 'UPDATE HARDWARE SET BANKKARTYA=' + inttostr(_bankkartya);
  _pcs := _pcs + ',BKKOLTSEG='+inttostr(_bkktsg);
  
  ibParancs(_pcs);
end;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

//                                 WESTERN UNION
//

// =============================================================================
                        procedure TRegeneralo.WuniRegen;
// =============================================================================

var _maidays,_datelo: string;
    z,_maiday,_day: integer;

begin
   // Az elözö- és folyó-havi Wzaro meghatározása:

   _eloWzaroNev := 'WZAR' + _eloFarok;
      _wzaroNev := 'WZAR' + _farok;

   for z := 1 to 31 do
     begin
       _ub[z] := 0;
       _hb[z] := 0;
       _mb[z] := 0;
       _tb[z] := 0;

       _uk[z] := 0;
       _hk[z] := 0;
       _mk[z] := 0;
       _tk[z] := 0;

       _mv[z] := 0;
       _tv[z] := 0;
      _ukd[z] := 0;
     end;

   _uny := 0;
   _hNy := 0;
   _tny := 0;
   _mny := 0;

   _uz  := 0;
   _hz  := 0;
   _tz  := 0;
   _mz  := 0;

   WuniNyitoBe;

   WuniMozgasbe('H');
   MetroMozgasBe('H');
   TescoMozgasBe('H');

   WuniMozgasbe('N');
   MetroMozgasBe('N');
   TescoMozgasBe('N');

   _maiDay := dayof(Now);
   _maiDays := HunDatetostr(Now);
   _datelo := leftstr(_maiDays,8);

    _tnev := 'WZAR' + _farok;

    with ibDbase do
     begin
       Close;
       DatabaseName := _aktValdATAPath;
     end;

   _pcs := 'DELETE FROM '+ _tnev;
   ibparancs(_pcs);

   for _day := 1 to _maiDay do
     begin
       _datum := _datelo + nulele(_day,2);

       _uz := _uny + _ub[_day] - _uk[_day];
       _hz := _hny + _hb[_day] - _hk[_day];
       _tz := _tny + _tb[_day] - _tk[_day] - _tV[_day];
       _mz := _mny + _mb[_day] - _mk[_day] - _mV[_day];

       _pcs := 'INSERT INTO ' + _tNev + ' (DATUM,USDNYITO,HUFNYITO,METRONYITO,TESCONYITO,';
       _pcs := _pcs + 'USDZARO,HUFZARO,METROZARO,TESCOZARO,USDBEVETEL,HUFBEVETEL,';
       _pcs := _pcs + 'METROBEVETEL,TESCOBEVETEL,USDKIADAS,HUFKIADAS,METROKIADAS,';
       _pcs := _pcs + 'TESCOKIADAS,METROVISSZA,TESCOVISSZA,UGYKEZELESIDIJ)'+ _sorveg;

       _pcs := _pcs + 'VALUES ('+chr(39)+_datum+chr(39)+',';
       _pcs := _pcs + inttostr(_uny)+',';
       _pcs := _pcs + inttostr(_hny)+',';
       _pcs := _pcs + inttostr(_mny)+',';
       _pcs := _pcs + inttostr(_tny)+',';
       _pcs := _pcs + inttostr(_uz)+',';
       _pcs := _pcs + inttostr(_hz)+',';
       _pcs := _pcs + inttostr(_mz)+',';
       _pcs := _pcs + inttostr(_tz)+',';
       _pcs := _pcs + inttostr(_ub[_day])+',';
       _pcs := _pcs + inttostr(_hb[_day])+',';
       _pcs := _pcs + inttostr(_mb[_day])+',';
       _pcs := _pcs + inttostr(_tb[_day])+',';
       _pcs := _pcs + inttostr(_uk[_day])+',';
       _pcs := _pcs + inttostr(_hk[_day])+',';
       _pcs := _pcs + inttostr(_mk[_day])+',';
       _pcs := _pcs + inttostr(_tk[_day])+',';
       _pcs := _pcs + inttostr(_mv[_day])+',';
       _pcs := _pcs + inttostr(_tv[_day])+',';
       _pcs := _pcs + inttostr(_ukd[_day]) + ')';

       _uny := _uz;
       _hny := _hz;
       _tny := _tz;
       _mny := _mz;

       ibParancs(_pcs);
     end;

    with ibDbase do
     begin
       Close;
       DatabaseName := _aktValUTAPath;
     end;

   _pcs := 'UPDATE WUAFAADATOK SET WUDOLLARKESZLET='+inttostr(_uz) + ',';
   _pcs := _pcs + 'WUFORINTKESZLET=' + inttostr(_hz) + ',';
   _pcs := _pcs + 'METROAFAKESZLET='+inttostr(_mz)+',';
   _pcs := _pcs + 'TESCOAFAKESZLET=' + inttostr(_tz) + ',';
   _pcs := _pcs + 'OSSZESAFAKESZLET='+inttostr(_mz+_tz);
   ibparancs(_pcs);
end;



// =============================================================================
                        procedure Tregeneralo.WuniNyitoBe;
// =============================================================================


begin
   with ibDbase do
     begin
       Close;
       DatabaseName := _aktValdataPath;
       Connected := True;
     end;

   ibTabla.Close;
   ibTabla.TableName := _eloWzaroNev;
   if not ibTabla.Exists then Exit;

   _pcs := 'SELECT * FROM '+_eloWzaronev + _sorveg;
   _pcs := _pcs + 'ORDER BY DATUM';

   with ibQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       Last;
     end;

   if ibQuery.Recno=0 then
     begin
       ibQuery.close;
       Exit;
     end;

   with ibQuery do
     begin
       _uny := FieldByName('USDZARO').asInteger;
       _hny := FieldByName('HUFZARO').asInteger;
       _mny := FieldByName('METROZARO').asInteger;
       _tny := FieldByName('TESCOZARO').asInteger;
     end;

   ibQuery.Close;
   ibdbase.close;
end;


// =============================================================================
             procedure TRegeneralo.WuniMozgasBe(_hn: string);
// =============================================================================

begin
   if _Hn='H' then  // Havi adatok
     begin
       _path := _aktValDataPath;
       _tnev := 'WUNI' + _farok;
     end
     else  // ---------------------- Napi adatok -------------------------------
     begin
       _path := _aktValutaPath;
       _tnev := 'WUMOZGAS';
     end;

   with ibDbase do
     begin
       Close;
       DatabaseName := _Path;
       Connected := True;
     end;

   with ibTabla do
     Begin
       Close;
       TableName := _tnev;
     end;
   if not ibTabla.Exists then exit;

   _pcs := 'SELECT * FROM ' + _tnev + _sorveg;
   _pcs := _pcs + 'WHERE STORNO<2' + _sorveg;
   _pcs := _pcs + 'ORDER BY DATUM';

   with ibQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       First;
       _recno := recno;
     end;

   if _Recno=0 then
     begin
       ibQuery.Close;
       ibDbase.close;
       Exit;
     end;

   while not ibQuery.Eof do
     begin
       with ibQuery do
         begin
           _datum     := TRIM(FieldByName('DATUM').asString);
           _bankjegy  := FieldByname('BANKJEGY').asInteger;
           _ttipus    := FieldByName('TRANZAKCIOTIPUS').asString;
           _valutanem := FieldByName('VALUTANEM').asString;
         end;

       _wnap := strtoint(midstr(_datum,9,2));
       if _valutanem='USD' then
         begin
           if leftstr(_ttipus,1)='+' then _ub[_wnap] := _ub[_wnap] + _bankjegy
           else _uk[_wnap] := _uk[_wnap] + _bankjegy;
         end
         else  // ---------------------forint tranzakció -----------------------
         begin
           if leftstr(_ttipus,1)='+' then _hb[_wnap] := _hb[_wnap] + _bankjegy
           else _hk[_wnap] := _hk[_wnap] + _bankjegy;
         end;

       ibQuery.next;
     end;
   ibQuery.Close;
   ibDbase.Close;
end;

// =============================================================================
               procedure TRegeneralo.MetroMozgasBe(_hn: string);
// =============================================================================

var _foegyseg,_ellatmany,_kifizetett: integer;

begin
   if _Hn='H' then
     begin
       _path := _aktValDataPath;
       _tnev := 'WAFA' + _farok;
     end
     else   // -------------------------- napi mozgások ------------------------
     begin
       _path := _aktValutaPath;
       _tnev := 'METROAFAMOZGAS';
     end;

   with ibDbase do
     begin
       Close;
       DatabaseName := _Path;
       Connected := True;
     end;

   with ibTabla do
     Begin
       Close;
       TableName := _tnev;
     end;
   if not ibTabla.Exists then exit;

   _pcs := 'SELECT * FROM ' +  _tnev + _sorveg;
   _pcs := _pcs + 'WHERE STORNO<2'+ _sorveg;
   _pcs := _pcs + 'ORDER BY DATUM';

   with ibQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       First;
       _recno := recno;
     end;

   if _Recno=0 then
     begin
       ibQuery.Close;
       ibDbase.Close;
       Exit;
     end;

   while not ibQuery.Eof do
     begin
       with ibQuery do
         begin
           _datum      := TRIM(FieldByName('DATUM').asString);
           _foegyseg   := FieldByName('FOEGYSEGSZAM').asInteger;
           _ellatmany  := FieldByname('ELLATMANYFORINT').asInteger;
           _kifizetett := FieldByName('KIFIZETETTOSSZEG').asInteger;
           _ttipus     := FieldByName('TRANZAKCIOTIPUS').asString;
         end;

       _wnap   := strtoint(midstr(_datum,9,2));
       _ttipus := leftstr(_ttipus,1);

       if _foegyseg=6 then
         begin
           _mv[_wnap] := _mv[_wnap] + _kifizetett;
         end
         else
         begin
           if _ttipus='+' then _mb[_wnap] := _mb[_wnap] + _ellatmany
           else _mk[_wnap] := _mk[_wnap] + _ellatmany;
         end;
       ibQuery.next;
     end;
   ibQuery.Close;
   ibDbase.close;
end;

// =============================================================================
               procedure TRegeneralo.TescoMozgasBe(_hn: string);
// =============================================================================


begin
   if _Hn='H' then
     begin
       _path := _aktValDataPath;
       _tnev := 'TESC' + _farok;
     end
     else  // -------------------- napi tesco mozgas ---------------------------
     begin
       _path := _aktValutaPath;
       _tnev := 'TESCO';
     end;

   with ibDbase do
     begin
       Close;
       DatabaseName := _PATH;
       Connected := True;
     end;

   with ibTabla do
     Begin
       Close;
       TableName := _tNev;
     end;
   if not ibTabla.Exists then exit;

   _pcs := 'SELECT * FROM ' + _tNev + _sorveg;
   _pcs := _pcs + 'WHERE STORNO=1' + _sorveg;
   _pcs := _pcs + 'ORDER BY DATUM';

   with ibQuery do
     begin
       Close;
       Sql.Clear;
       Sql.Add(_pcs);
       Open;
       First;
       _recno := Recno;
     end;

   if _Recno=0 then
     begin
       ibQuery.Close;
       ibDbase.close;
       Exit;
     end;

   while not ibQuery.Eof do
     begin
       with ibQuery do
         begin
           _datum    := trim(FieldByName('DATUM').asString);
           _bankjegy := FieldByName('OSSZESFORINT').asInteger;
           _ttipus   := FieldByName('BIZONYLATTIPUS').asString;
         end;

       _wnap := strtoint(midstr(_datum,9,2));

       if _ttipus='B' then _Tb[_wnap] := _Tb[_wnap] + _bankjegy;
       if _ttipus='K' then _tk[_wnap] := _tk[_wnap] + _bankjegy;
       if _ttipus='V' then _tv[_wnap] := _tv[_wnap] + _bankjegy;

       ibQuery.next;
     end;
   ibQuery.Close;
   ibdbase.Close;
end;

// =============================================================================
                   procedure Tregeneralo.GetHardwareData;
// =============================================================================


begin

  ibdbase.close;
  ibdbase.DatabaseName := _aktValutaPath;
  ibDbase.Connected := true;

  with ibQuery do
    begin
      Close;
      Sql.Clear;
      sql.Add('SELECT * FROM HARDWARE');
      Open;
      _napnyitas := trim(FieldByName('MEGNYITOTTNAP').asString);
      _gepfunkcio := FieldByName('GEPFUNKCIO').asInteger;
      _ertektar := FieldByNAme('ERTEKTAR').asInteger;
      Close;
    end;
  ibDbase.close;
end;




// =============================================================================
              function TRegeneralo.Nulele(_int,_hh: integer): string;
//==============================================================================

begin
  result := inttostr(_int);
  while length(result)<_hh do result := '0' + result;
end;

// =============================================================================
         procedure TRegeneralo.DnemTolto;
// =============================================================================

begin

  ibDbase.close;
  ibDbase.DatabaseName := 'C:\VALUTA\DATABASE\VALUTA.FDB';
  ibDbase.Connected := True;

  _pcs := 'SELECT * FROM ARFOLYAM' + _sorveg;
  _pcs := _pcs + 'ORDER BY VALUTANEM';

  with ibQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _valutaDarab := Recno;
    end;

  Setlength(_dnem,_valutaDarab);
  Setlength(_dnev,_valutaDarab);

  _cc := 0;

  ibQuery.First;
  while not ibQuery.Eof do
    begin
      with ibQuery do
        begin
          _aktdnem := FieldByName('VALUTANEM').asString;
          _aktdnev := FieldByName('VALUTANEV').asString;
          _zaro := FieldByName('ZARO').asInteger;
        end;

      _dnem[_cc] := _aktDnem;
      _dnev[_cc] := trim(_aktDnev);

      if _aktdnem='HUF' then _ftIndex := _cc;

      inc(_cc);
      ibQuery.Next;
    end;
  ibQuery.Close;
  ibDbase.Close;
end;


// =============================================================================
     function TRegeneralo.Dnemscan(_egydnem:string): integer;
// =============================================================================

var y: integer;

begin
  Result := -1;
  y := 0;

  while y<_valutaDarab do
    begin
      if _egyDnem=_dnem[y] then
        begin
          Result := y;
          Exit;
        end;
      inc(y);
     end;
end;


// =============================================================================
    function TRegeneralo.RealToStr(_rr: real): string;
// =============================================================================

var _pos: integer;

begin
  Result := '0';
  if _rr=0 then exit;

  Result := Floattostr(_rr);
  _pos := pos(chr(44),result);
  if _pos>0 then result[_pos] := chr(46);
end;


// =============================================================================
                procedure TRegeneralo.ibParancs(_ukaz: string);
// =============================================================================

begin
  ibDbase.connected := true;
  if ibtranz.InTransaction then ibtranz.Commit;
  ibtranz.StartTransaction;
  with ibquery do
    begin
      Close;
      sql.Clear;
      Sql.add(_ukaz);
      ExecSql;
    end;
  ibtranz.commit;
  ibdbase.close;
end;

// =============================================================================
                  procedure Tregeneralo.Kezdijregeneralo;
// =============================================================================


begin
  _havikezdij := 0;
  _napikezdij := 0;
  _haviatad   := 0;
  _haviatvet  := 0;
  _napiatvet  := 0;
  _napiatad   := 0;

// =================== KERESÉS A BFyymm GYÜTÖADATBÁZISBAN ======================

  ibdbase.close;
  ibdbase.DatabaseName := _aktvaldataPath;
  ibDbase.Connected := true;

  _pcs := 'SELECT * FROM '+ _fejtombnev + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1) AND (FIZETOESZKOZ<>2)';
  with Ibquery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ibQuery.eof do
    begin
      _datum := trim(ibquery.fieldByName('DATUM').asstring);
      _kezdij := ibquery.FieldByName('KEZELESIDIJ').asInteger;
      if _datum<_napnyitas then _havikezdij := _havikezdij + abs(_kezdij)
      else _napikezdij := _napikezdij + abs(_kezdij);
      ibquery.next;
    end;
  ibQuery.close;
  Csik.Position := 20;

  // ---------------- KERESÉS A BLOKKFEJBEN ------------------------------------

  ibdbase.close;
  ibdbase.DatabaseName := _aktvalutaPath;
  ibDbase.Connected := true;
  _pcs := 'SELECT * FROM BLOKKFEJ' + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1)';

   with Ibquery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ibQuery.eof do
    begin
      _kezdij := ibquery.FieldByName('KEZELESIDIJ').asInteger;
      _datum  := trim(ibquery.FieldByName('DATUM').asString);
      _feszkoz := ibquery.FieldByName('FIZETOESZKOZ').asInteger;
      if _feszkoz=2 then
        begin
          Ibquery.next;
          continue;
        end;

      if _datum<_napnyitas then _havikezdij := _havikezdij + abs(_kezdij)
      else _napikezdij := _napikezdij + abs(_kezdij);
      ibquery.next;
    end;
  ibQuery.close;
  Csik.Position := 30;

  // ------------------ KERESÉS A KEZDYYMM ADATBÁZISBAN ------------------------

  ibdbase.close;
  ibdbase.DatabaseName := _aktvaldataPath;
  ibDbase.Connected := true;

  _pcs := 'SELECT * FROM '+ _kezdtombnev + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1) AND (MOZGAS>1)';

  with Ibquery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ibquery.eof do
    begin
      _datum  := trim(ibquery.fieldByName('DATUM').asstring);
      _kezdij := ibquery.FieldByNAme('KEZELESIDIJ').asInteger;
      _elojel := ibquery.FieldByName('ELOJEL').asString;

      if _elojel='+' then
        begin
          if _datum=_napnyitas then _napiatvet := _napiatvet + _kezdij
          else _haviatvet := _haviatvet + _kezdij;
        end else
        begin
          if _datum=_napnyitas then _napiatad := _napiatad + _kezdij
          else _haviatad := _haviatad + _kezdij;
        end;
      ibQuery.next;
    end;
  ibQuery.close;
  Csik.Position := 40;

  // --------------------- KERESÉS A KEZELESIDIJ ADATBÁZISBAN ------------------

  ibdbase.close;
  ibdbase.DatabaseName := _aktvalutaPath;
  ibDbase.Connected := true;

  _pcs := 'SELECT * FROM KEZELESIDIJ' + _sorveg;
  _pcs := _pcs + 'WHERE (STORNO=1) AND (MOZGAS>1)';

  with Ibquery do
    begin
      Close;
      Sql.Clear;
      sql.Add(_pcs);
      Open;
      First;
    end;

  while not ibquery.eof do
    begin
      _datum  := trim(ibquery.fieldByName('DATUM').asstring);
      _kezdij := ibquery.FieldByNAme('KEZELESIDIJ').asInteger;
      _elojel := ibquery.FieldByName('ELOJEL').asString;

      if _elojel='+' then
        begin
          if _datum=_napnyitas then _napiatvet := _napiatvet + _kezdij
          else _haviatvet := _haviatvet + _kezdij;
        end else
        begin
          if _datum=_napnyitas then _napiatad := _napiatad + _kezdij
          else _haviatad := _haviatad + _kezdij;
        end;
      ibQuery.next;
    end;
  ibQuery.close;
  ibdbase.close;

  Csik.Position := 50;
end;


// =============================================================================
                 procedure Tregeneralo.Kezdijregister;
// =============================================================================


var _honap: word;

begin
  ibdbase.close;
  ibdbase.DatabaseName := _aktvalutaPath;
  ibDbase.Connected := true;

  _pcs := 'UPDATE ARFOLYAM SET KEZELESIDIJ='+inttostr(_napikezdij)+_sorveg;
  _pcs := _pcs + 'WHERE VALUTANEM='+chr(39)+'HUF'+chr(39);
  ibparancs(_pcs);

  _khavizaro := _khavinyito+_havikezdij+_napikezdij+_haviatvet+_napiatvet;
  _khavizaro := _khavizaro - _haviatad - _napiatad;

  _knapinyito := _khavinyito+_havikezdij+_haviatvet-_haviatad;
  _knapizaro  := _knapinyito + _napikezdij + _napiatvet - _napiatad;

  _pcs := 'UPDATE KEZELESIDATA SET AKTKEZELESIDIJ='+inttostr(_khavizaro);
  _PCS := _pcs + ',NAPIKEZELESIDIJ='+inttostr(_napikezdij);
  ibparancs(_pcs);

  //------------ HAVI ÉS NAPI EGYENLEK RÖGZITÉSE -------------------------------

  _honap := strtoint(midstr(_napnyitas,6,2));

  _pcs := 'DELETE FROM HAVIKEZELESIDIJ'+ _sorveg;
  _pcs := _pcs + 'WHERE HONAP='+inttostr(_honap);
  ibparancs(_PCS);

  _pcs := 'INSERT INTO HAVIKEZELESIDIJ (HONAP,NYITO,KEZELESIDIJ,KEZELESIDIJATVETEL,';
  _pcs := _pcs + 'KEZELESIDIJATADAS,ZARO)' + _sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_honap) + ',';
  _pcs := _pcs + inttostr(_khavinyito)+',';
  _pcs := _pcs + inttostr(_havikezdij+_napikezdij) + ',';
  _pcs := _pcs + inttostr(_haviatvet+_napiatvet) + ',';
  _pcs := _pcs + inttostr(_haviatad+_napiatad)+ ',';
  _pcs := _pcs + inttostr(_khaviZaro)+')';
  ibParancs(_pcs);

  _pcs := 'DELETE FROM NAPIKEZELESIDIJ' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM=' + chr(39) + _napnyitas + chr(39);
  ibParancs(_pcs);

  _pcs := 'INSERT INTO NAPIKEZELESIDIJ (DATUM,NYITO,KEZELESIDIJ,KEZELESIDIJATVETEL,';
  _pcs := _pcs + 'KEZELESIDIJATADAS,ZARO)';
  _pcs := _pcs + 'VALUES (' + chr(39) + _napnyitas + chr(39) + ',';
  _pcs := _pcs + inttostr(_knapinyito) + ',';
  _pcs := _pcs + inttostr(_napikezdij) + ',';
  _pcs := _pcs + inttostr(_napiatvet) + ',';
  _pcs := _pcs + inttostr(_napiatad) + ',';
  _pcs := _pcs + inttostr(_knapizaro)+')';
  ibparancs(_pcs);
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// =============================================================================
                    procedure TRegeneralo.HianyzoBizonylat;
// =============================================================================


begin
  ibdbase.close;
  ibdbase.databasename := _aktvalutaPath;

  Tombbeolvasas('BLOKKTETEL');
  Rontottjeloles('BLOKKFEJ');

  TombbeOlvasas('BLOKKFEJ');
  RontottJeloles('BLOKKTETEL');
end;





// =============================================================================
               procedure TRegeneralo.TombbeOlvasas(_tnev: string);
// =============================================================================

begin
  _pcs := 'SELECT * FROM ' + _tnev + _sorveg;
  _pcs := _pcs + 'WHERE STORNO=1';

  ibdbase.Connected := true;
  with Ibquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  _bizdb := 0;
  while not IbQuery.Eof do
    begin
      _biz := IbQuery.fieldByName('BIZONYLATSZAM').asString;
      _xx := scanbiz(_biz);
      if _xx=0 then
        begin
          inc(_bizdb);
          _biztomb[_bizdb] := _biz;
        end;
      ibquery.next;
    end;
  ibquery.close;
  ibdbase.close;
end;

// =============================================================================
              function TRegeneralo.scanbiz(_bb: string):integer;
// =============================================================================

var _y: integer;

begin
  result := 0;
  if _bizdb=0 then exit;

  _y := 1;
  while _y<=_bizdb do
    begin
      if _biztomb[_y]=_bb then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
               procedure TRegeneralo.RontottJeloles(_tnev: string);
// =============================================================================

begin

  ibdbase.Connected := true;
  if ibtranz.InTransaction then ibtranz.Commit;
  ibtranz.StartTransaction;

  with Ibtabla do
    begin
      close;
      TableName := _Tnev;
      Open;
      Filter := 'STORNO=1';
      Filtered := True;
      First;
    end;

  while not ibtabla.Eof do
    begin
      _biz := Ibtabla.fieldbyname('BIZONYLATSZAM').asString;
      _xx := scanbiz(_biz);
      if _xx=0 then
        begin
          ibtabla.edit;
          ibtabla.fieldbyname('STORNO').asInteger := 4;
          if _tnev = 'BLOKKFEJ' then
               ibtabla.FieldByName('UGYFELNEV').AsString := 'RONTOTT BIZONYLAT';
          ibtabla.Post;
        end;
      ibtabla.next;
    end;

  ibTranz.commit;
  ibdbase.close;
  ibtabla.close;
end;


function TRegeneralo.HunDatetostr(_caldat: TDateTime): string;

var _h_ev,_h_ho,_h_nap: word;
begin
  _h_ev := yearof(_caldat);
  _h_ho := monthof(_caldat);
  _h_nap:= dayof(_caldat);

  result := inttostr(_h_ev)+'.'+nulele(_h_ho,2)+'.'+nulele(_h_nap,2);
end;

function TRegeneralo.Kerekites(_r: real): real;

var _rint,_rintslen: integer;
    _rints: string;
    _lastasc: byte;

begin
  _rint     := trunc(_r);
  _rints    := inttostr(_rint);
  _rintslen := length(_rints);           //  0  1  2  3  4  5  6  7  8  9
  _lastasc  := ord(_rints[_rintslen]);   // 48,49,50,51,52,53,54,55,56,57

  case _lastasc of
    49: _rint := _rint-1;
    50: _rint := _rint-2;
    51: _rint := _rint+2;
    52: _rint := _rint+1;

    54: _rint := _rint-1;
    55: _rint := _rint-2;
    56: _rint := _rint+2;
    57: _rint := _rint+1;
  end;
  result := 1*_rint;
end;

end.
