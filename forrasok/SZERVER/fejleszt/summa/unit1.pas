unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ExtCtrls, StdCtrls, Buttons, IBDatabase, DB,strUtils,
  IBCustomDataSet, IBQuery, IBTable,dateUtils, jpeg;

type
  TForm1 = class(TForm)
    TOLNAPTAR: TMonthCalendar;
    IGNAPTAR: TMonthCalendar;
    Label1: TLabel;
    Shape3: TShape;
    Label2: TLabel;
    Shape4: TShape;
    Label3: TLabel;
    Shape5: TShape;
    Shape6: TShape;
    STARTGOMB: TBitBtn;
    ESCAPEGOMB: TBitBtn;
    PENZTARPANEL: TPanel;
    DATUMPANEL: TPanel;
    Shape12: TShape;
    PENZTARCSIK: TProgressBar;
    Shape13: TShape;
    Shape14: TShape;
    Label11: TLabel;
    VQUERY: TIBQuery;
    VDBASE: TIBDatabase;
    VTRANZ: TIBTransaction;
    VTABLA: TIBTable;
    REKORDCSIK: TProgressBar;
    Shape15: TShape;
    TOLLABEL: TPanel;
    IGLABEL: TPanel;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    V2QUERY: TIBQuery;
    V2DBASE: TIBDatabase;
    V2TRANZ: TIBTransaction;
    TRANZQUERY: TIBQuery;
    TRANZDBASE: TIBDatabase;
    TRANZTRANZ: TIBTransaction;
    TRANZTABLA: TIBTable;
    Shape7: TShape;
    Image1: TImage;

    procedure PenztarBeolvasas;
    procedure Adatnullazas;
    procedure ForgalomLegyujtes;
    procedure Profitlegyujtes;
    procedure WuLegyujtes;
    procedure AfaLegyujtes;
    procedure Ekerlegyujtes;
    procedure Axalegyujtes;
    procedure TranzadoLegyujtes;

    procedure STARTGOMBClick(Sender: TObject);
    procedure ESCAPEGOMBClick(Sender: TObject);
    procedure DatumDisplay;

    procedure TOLNAPTARClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    function Vesszokivono(_nfts: string): string;
    function Forintform(_ft: integer): string;
 
    function Nulele(_b: byte): string;
    function WideDatum(_ds: string): string;
    function ScanKorzet(_kz: byte): byte;
  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _toldatum,_igdatum: Tdatetime;
  _tols,_igs,_mamas,_fdbpath,_pcs,_elsofarok,_lastfarok,_status,_tipus: string;
  _aktptn,_tetels,_akttetel,_aktpenztarnums,_aktceg,_kftbetu: string;
  _minforint,_maxforint,_recno,_cc,_brutto,_vevoszam,_aktft,_ftert: integer;
  _code,_ertektar,_ertss,_tetss,_aktpenztar,_aktkorzet: integer;
  _mins,_maxs,_bf,_bt,_aktfarok,_datum,_utbs,_aktbs,_cegbetu,_aktstatus: string;
  _sorveg: string = chr(13)+chr(10);
  _ptTerulet: array[1..150] of byte;
  _tolev,_tolho,_igev,_igho,_aktev,_aktho: word;
  _pt,_penztar,_korzetss: byte;
  _aktpt,_kellkorzet,_kellpenztar: byte;
  _evhostol,_evhosig: string;
  _tolnap,_ignap: byte;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
             'MÁJUS','JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                                'NOVEMBER','DECEMBER');


 
  _korzetnev: array[1..8] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
                   'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR');

  _korzetszam: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _korzetIrodaDb: array[1..8] of byte;
  _korzetIrodaszam: array[1..8,1..40] of byte;

  _penztarnevek: array[1..150] of string;

  _forgalom,_vetel,_eladas,_wuusd,_wuhuf,_afaforgalom: array[1..150] of real;
  _automatrica,_paysafeCard,_telefon: array[1..150] of real;
  _axaforgalom,_tranzado,_kezelesidij,_profit: array[1..150] of real;

  _vevok,_eladok,_valtougyfel,_wuugyfel,_axaugyfel: array[1..150] of integer;
  _afaugyfel,_ekerugyfel: array[1..150] of integer;

  _netto,_kezdij: integer;
  _bizonylatszam: string;
  _korzet,_utkorzet,_darab: byte;

  _top,_height,_left,_width: word;



implementation

uses Unit2;

{$R *.dfm}


// =============================================================================
                    procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var i: byte;

begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  _top := trunc((_height-410)/2);
  _left:= trunc((_width-964)/2);

  Top := _top;
  Left := _left;



  for i := 1 to 150 do _penztarnevek[i] := '?';
  _mamas := datetostr(date);
  AdatNullazas;

  Tolnaptar.Date := Date;
  Ignaptar.Date  := Date;

  Datumdisplay;

  PenztarBeolvasas;
  Activecontrol := Startgomb;
end;


// =============================================================================
              procedure TForm1.STARTGOMBClick(Sender: TObject);
// =============================================================================

begin
  // Kezdõ és végsõ dátumok feldolgozása:

  DatumDisplay;
  if _toldatum>_igdatum then
    begin
      ShowMessage('A KEZDÕ-DÁTUM NAGYOBB AZ UTOLSÓ DÁTUMNÁL !');
      Exit;
    end;

  if _igs>=_mamas then
    begin
      ShowMessage('AZ UTOLSÓ NAP MAXIMUMA A TEGNAPI NAP !');
      exit;
    end;

  // ---------------------------------------------------

  StartGomb.Enabled := false;
  eSCAPEGOMB.Enabled := false;

  _evhostol := midstr(_tols,3,2)+midstr(_tols,6,2);
  _evhosig  := midstr(_igs,3,2)+midstr(_igs,6,2);

  _tolnap := strtoint(midstr(_tols,9,2));
  _ignap  := strtoint(midstr(_igs,9,2));

  _elsofarok := midstr(_tols,3,2)+midstr(_tols,6,2);
  _lastfarok := midstr(_igs,3,2)+midstr(_igs,6,2);

  _tolev := yearof(_toldatum);
  _tolho := monthof(_toldatum);

  _igev := yearof(_igdatum);
  _igho := monthof(_igdatum);

  // ---------------------------------------------------------------------------

  // Végig megyünk az összes pénztáron

   _pt := 1;
   Penztarcsik.Max := 150;

   while _pt<=150 do
     begin
       Penztarcsik.Position := _pt;
       Form1.Repaint;

       // Az aktuális adatbázist elérõ útvonal:

       _fdbPath := 'c:\receptor\database\v' + inttostr(_pt)+'.fdb';

       // Ha nincs adatbázis - jöhet a következõ pénztár:

       if not FileExists(_fdbPath) then
         begin
           inc(_pt);
           continue;
         end;

       // Kijelezzük az aktuális pénztár nevét:

       PenztarPanel.Caption := inttostr(_pt)+'. '+_penztarnevek[_pt];
       PenztarPanel.Repaint;

       Vdbase.close;
       Vdbase.DatabaseName := _fdbpath;

       V2dbase.close;
       V2dbase.DatabaseName := _fdbPath;

       // -----------------------------------------------------------------

       _aktev    := _tolev;
       _aktho    := _tolho;
       _aktfarok := _elsofarok;

       // Az összes idõszakra esõ adatbázist meg kell vizsgálni:

       while _aktfarok<=_lastfarok do
         begin
           _bf := 'BF' + _aktfarok;
           _bt := 'BT' + _aktfarok;

           ForgalomLegyujtes;
           ProfitLegyujtes;
           WuLegyujtes;
           Afalegyujtes;
           EkerLegyujtes;
           AxaLegyujtes;
         
           inc(_aktho);
           if _aktho>12 then
             begin
               _aktho := 1;
               inc(_aktev);
             end;
           _aktfarok := inttostr(_aktev-2000)+nulele(_aktho);
         end;
       inc(_pt);
     end;

   _aktev    := _tolev;
   _aktho    := _tolho;
   _aktfarok := _elsofarok;

       // Az összes idõszakra esõ adatbázist meg kell vizsgálni:

   PenztarPanel.caption := 'TRANZAKCIÓS ADÓ LEGYÜJTÉSE';
   PenztarPanel.Repaint;

   while _aktfarok<=_lastfarok do
     begin
       TranzadoLegyujtes;
       inc(_aktho);
       if _aktho>12 then
         begin
           _aktho := 1;
           inc(_aktev);
         end;
       _aktfarok := inttostr(_aktev-2000)+nulele(_aktho);
     end;

  MakeExcel.showmodal;
  Escapegomb.Enabled := True;

end;




// =============================================================================
                procedure TForm1.ESCAPEGOMBClick(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;

// =============================================================================
                 procedure TForm1.TOLNAPTARClick(Sender: TObject);
// =============================================================================

begin
  Datumdisplay;
end;

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// =============================================================================
                       procedure TForm1.AdatNullazas;
// =============================================================================


var i,j: integer;

begin

  for i := 1 to 150 do
    begin

      // Valutaváltás:

      _vevok[i]       := 0;
      _eladok[i]      := 0;
      _valtougyfel[i] := 0;

      _vetel[i]       := 0;
      _eladas[i]      := 0;
      _forgalom[i]    := 0;

      // Western Union:

      _wuhuf[i]       := 0;
      _wuusd[i]       := 0;
      _wuugyfel[i]    := 0;

      // Afa:

      _afaforgalom[i] := 0;
      _afaUgyfel[i]   := 0;

      // E-kereskedelem:

      _ekerugyfel[i]  := 0;

      _telefon[i]     := 0;
      _automatrica[i] := 0;
      _paysafeCard[i] := 0;

      // Axa :

      _axaforgalom[i] := 0;
      _axaugyfel[i]   := 0;

      // Adók és díjak:

      _kezelesidij[i] := 0;
      _tranzado[i]    := 0;

      _profit[i]      := 0;
    end;

  for i := 1 to 8 do
    begin
      for j := 1 to 40 do _korzetirodaszam[i,j] := 0;
      _korzetirodadb[i] := 0;
    end;
end;



// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// =============================================================================
                       procedure TForm1.PenztarBeolvasas;
// =============================================================================

var _aktpt: byte;
    _aktptn: string;

begin
  _fdbPath := 'c:\receptor\database\receptor.fdb';

  recDbase.Connected := true;
  _pcs := 'SELECT * FROM IRODAK'+_sorveg;
  _pcs := _pcs + 'ORDER BY ERTEKTAR,UZLET';

  with recquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _cc := 0;
  _utkorzet := 0;
  _korzetss := 0;
  while not recquery.Eof do
    begin
      _status   := recquery.FieldByName('STATUS').asString;
      _ertektar := recquery.FieldByname('ERTEKTAR').asInteger;
      _aktpt    := recquery.FieldByName('UZLET').asInteger;
      _aktptn   := trim(recquery.FieldByName('KESZLETNEV').asString);
      _korzet   := scanKorzet(_ertektar);
      _penztarnevek[_aktpt] := _aktptn;
      if _status='P' then
        begin
          _darab := _korzetIrodadb[_korzet]+1;
          _korzetIrodaSzam[_korzet,_darab] := _aktpt;
          _korzetIrodaDb[_korzet] := _darab;
        end;
      recquery.next;
    end;
  recquery.close;
  recdbase.close;

end;

// =============================================================================
            function TForm1.Vesszokivono(_nfts: string): string;
// =============================================================================

var _y,_ww,_betu: byte;

begin
  _nfts := trim(_nfts);
  _ww := length(_nfts);
  _y := 1;
  result := '';
  while _y<=_ww do
    begin
      _betu := ord(_nfts[_y]);
      if (_betu>47) and (_betu<58) then result := result + chr(_betu);
      inc(_y);
    end;
end;


// =============================================================================
                  function Tform1.ScanKorzet(_kz: byte): byte;
// =============================================================================


var _y: byte;

begin
  result := 0;
  _y := 1;
  while _y<=8 do
    begin
      if _korzetszam[_y]=_kz then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;
end;

// =============================================================================
                 function TForm1.Nulele(_b: byte): string;
// =============================================================================

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;


// =============================================================================
          function TForm1.Forintform(_ft: integer): string;
// =============================================================================

var _fts: string;
    _ww,_f1: byte;

begin
  _fts := inttostr(_ft);
  _ww := length(_fts);

  if _ww>3 then
    begin
      if _ww>6 then
        begin
          _f1 := _ww-6;
          _fts := leftstr(_fts,_f1)+','+midstr(_fts,_f1+1,3)+','+midstr(_fts,_f1+4,3);
        end else
        begin
          _f1 := _ww-3;
          _fts := leftstr(_fts,_f1)+','+midstr(_fts,_f1+1,3);
        end;
    end;
  result := _fts;
end;

// =============================================================================
                function Tform1.WideDatum(_ds: string): string;
// =============================================================================

var _xho,_xnap,_code: integer;

begin
  val(midstr(_ds,6,2),_xho,_code);
  if _code<>0 then _xho := 0;

  val(midstr(_ds,9,2),_xnap,_code);
  if _code<>0 then _xnap := 0;

  result := '';

  if (_xho=0) or (_xnap=0) then exit;
  result := leftstr(_ds,4)+' '+_honev[_xho]+' '+inttostr(_xNap);
end;


// =============================================================================
                           procedure TForm1.Datumdisplay;
// =============================================================================

begin
  _toldatum := Tolnaptar.Date;
  _igDatum  := IgNaptar.Date;

  _tols := leftstr(datetostr(_toldatum),10);
  _igs  := leftstr(datetostr(_igdatum),10);

  Tollabel.Caption := _tols+'-TÓL';
  IgLabel.Caption  := _igs+'-IG';

  Tollabel.Repaint;
  IgLabel.Repaint;
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
// =============================================================================
                      procedure TForm1.Forgalomlegyujtes;
// =============================================================================

var _sft,_ft: integer;

begin

  VDbase.close;
  Vdbase.Connected := True;
  Vtabla.close;
  VTabla.TableName := _bf;

  // Ha nem volt ebben a hónapban váltás - jöhet a következõ hónap

  if not Vtabla.Exists then
    begin
      Vdbase.close;
      exit;
    end;

  // Megnyitjuk a Blokfejeket az idõszakon belül.(VEK tipusokra, storno=1)

  _pcs := 'SELECT * FROM ' + _BF + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>='+chr(39)+_tols+chr(39)+')';
  _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igs+chr(39)+')';
  _pcs := _pcs + ' AND (STORNO=1) AND ((TIPUS='+chr(39)+'V'+chr(39)+')';
  _pcs := _pcs + ' OR (TIPUS='+chr(39)+'E'+chr(39)+')';
  _pcs := _pcs + ' OR (TIPUS='+CHR(39)+'K'+chr(39)+'))';

  with VQuery do
    begin
      Close;
      sql.clear;
      sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      VQuery.close;
      Vdbase.close;
      exit;
    end;

  RekordCsik.Max := _recno;
  _cc := 0;

  while not VQuery.Eof do
    begin
      inc(_cc);
      Rekordcsik.Position := _cc;

      _bizonylatszam := VQuery.FieldByName('BIZONYLATSZAM').asstring;
      _datum         := VQuery.FieldByName('DATUM').asstring;
      _tipus         := Vquery.FieldByName('TIPUS').asString;
      _netto         := VQuery.FieldByName('OSSZESEN').asInteger;
      _kezdij        := abs(Vquery.FieldByName('KEZELESIDIJ').asInteger);

      _kezelesidij[_pt] := _kezelesidij[_pt] + _kezdij;

      datumpanel.Caption := widedatum(_datum);
      datumpanel.Repaint;

      if _tipus='V' then
        begin
          _eladok[_pt] := _eladok[_pt] + 1;
          _vetel[_pt] := _vetel[_pt] + _netto;
        end;

      if _tipus='E' then
        begin
          _vevok[_pt] := _vevok[_pt] + 1;
          _eladas[_pt] := _eladas[_pt] + _netto;
        end;

      if _tipus='K' then
        begin
          _vevok[_pt] := _vevok[_pt] + 1;
          _eladok[_pt]:= _eladok[_pt] + 1;

          _pcs := 'SELECT * FROM ' + _BT + _sorveg;
          _pcs := _pcs + 'WHERE (BIZONYLATSZAM='+chr(39)+_bizonylatszam+chr(39)+')';
          _pcs := _pcs + ' AND (ELOJEL='+chr(39)+'+'+chr(39)+')';

          V2dbase.connected := True;
          with V2Query do
            begin
              Close;
              sql.clear;
              sql.add(_pcs);
              Open;
              First;
            end;

          _sft := 0;
          while not V2Query.eof do
            begin
              _ft := V2Query.FieldByname('FORINTERTEK').asInteger;
              _sft := _sFt + _ft;
              V2Query.next;
            end;

          v2query.close;
          v2dbase.close;
          _vetel[_pt]  := _vetel[_pt]  + _sFt;
          _eladas[_pt] := _eladas[_pt] + _sFt;
        end;
      Vquery.next;
    end;
  Vquery.close;
  Vdbase.close;
end;

// =============================================================================
                     procedure TForm1.ProfitLegyujtes;
// =============================================================================

VAR _sprofit,_aktprofit,_arfolyam,_elszarf,_aktbjegy,_diff: integer;
    _aktdnem,_bizszam,_elojel: string;

begin
  vdbase.Connected := true;
  vTabla.TableName := _bt;
  if not vtabla.Exists then
    begin
      vdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _bt + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>='+chr(39)+_tols+chr(39)+')';
  _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igs+chr(39)+')';
  _pcs := _pcs + ' AND (STORNO=1)';

   with vQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      vQuery.close;
      vdbase.close;
      exit;
    end;

  RekordCsik.Max := _recno;
  _cc := 0;
  _sProfit := 0;
  while not vquery.eof do
    begin
      inc(_cc);
      Rekordcsik.Position := _cc;

      _elszarf := Vquery.fieldByNAme('ELSZAMOLASIARFOLYAM').asInteger;
      _arfolyam:= Vquery.FieldByName('ARFOLYAM').asInteger;
      _aktbjegy:= Vquery.FieldByName('BANKJEGY').asInteger;
      _aktdnem := Vquery.FieldByName('VALUTANEM').asString;
      _bizSzam := Vquery.FieldByName('BIZONYLATSZAM').asstring;
      _elojel  := Vquery.FieldByName('ELOJEL').asString;
      _tipus := Leftstr(_bizSzam,1);

      _aktprofit := 0;
      
      if _tipus='V' then
        begin
          _diff := _elszarf-_arfolyam;
          _aktprofit := round(_aktbjegy*_diff/100);
          if _aktdnem='JPY' then _aktprofit := round(_aktprofit*100);
        end;

      if _tipus='E' then
        begin
          _diff := _arfolyam-_elszarf;
          _aktprofit := round(_aktbjegy*_diff/100);
          if _aktdnem='JPY' then _aktprofit := round(_aktprofit*100);
        end;

      if (_tipus='K') and (_elojel='+') then
        begin
          _diff := _elszarf-_arfolyam;
          _aktprofit := round(_aktbjegy*_diff/100);
          if _aktdnem='JPY' then _aktprofit := round(_aktprofit*100);
        end;

     if (_tipus='K') and (_elojel='-') AND (_aktdnem<>'HUF') then
        begin
          _diff := _arfolyam-_elszarf;
          _aktprofit := round(_aktbjegy*_diff/100);
          if _aktdnem='JPY' then _aktprofit := round(_aktprofit*100);
        end;

     _sProfit := _sProfit + _aktprofit;
     Vquery.Next
   end;
  _profit[_pt] := _sProfit;
end;






// =============================================================================
                              procedure TForm1.Wulegyujtes;
// =============================================================================

var _wutablanev,_valutanem: string;
    _bankjegy: integer;

begin
  _wutablanev := 'WUNI' + _aktfarok;
  vdbase.Connected := true;
  vTabla.TableName := _wutablanev;
  if not vtabla.Exists then
    begin
      vdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _wutablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>='+chr(39)+_tols+chr(39)+')';
  _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igs+chr(39)+')';
  _pcs := _pcs + ' AND (STORNO=1) AND (UGYFELTIPUS='+chr(39)+'U'+chr(39)+')';

  with vQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      vQuery.close;
      vdbase.close;
      exit;
    end;

  RekordCsik.Max := _recno;
  _cc := 0;

  while not vquery.eof do
    begin
      inc(_cc);
      Rekordcsik.Position := _cc;

      _bankjegy := Vquery.fieldByNAme('BANKJEGY').asInteger;
      _valutanem:= Vquery.FieldByName('VALUTANEM').asstring;

      if _valutanem='USD' then _wuusd[_pt] := _wuusd[_pt] + _bankjegy;
      if _valutanem='HUF' then _wuHUF[_pt] := _wuHUF[_pt] + _bankjegy;

      _wuUgyfel[_pt] := _wuUgyfel[_pt] + 1;

      vquery.next;
    end;
  Vquery.close;
  Vdbase.close;
end;


procedure TForm1.AfaLegyujtes;

var _watablanev: string;
    _kifizetve: integer;

begin
  _watablanev := 'WAFA' + _aktfarok;
  vdbase.Connected := true;
  vTabla.TableName := _watablanev;
  if not vtabla.Exists then
    begin
      vdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _watablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>='+chr(39)+_tols+chr(39)+')';
  _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igs+chr(39)+')';
  _pcs := _pcs + ' AND (STORNO=1) AND (TRANZAKCIOTIPUS='+chr(39)+'-V'+chr(39)+')';

  with vQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      vQuery.close;
      vdbase.close;
      exit;
    end;

  RekordCsik.Max := _recno;
  _cc := 0;

  while not vquery.eof do
    begin
      inc(_cc);
      Rekordcsik.Position := _cc;

      _kifizetve := vquery.fieldbyName('KIFIZETVE').asInteger;
      _afaugyfel[_pt] := _afaugyfel[_pt] + 1;
      _afaforgalom[_pt] := _afaforgalom[_pt] + _kifizetve;

      vquery.Next;
    end;
  VQuery.close;
  Vdbase.close;

  // ---------------------------------------------------------------------------

  _watablanev := 'TESC' + _aktfarok;
  vdbase.Connected := true;
  vTabla.TableName := _watablanev;
  if not vtabla.Exists then
    begin
      vdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _watablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>='+chr(39)+_tols+chr(39)+')';
  _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igs+chr(39)+')';
  _pcs := _pcs + ' AND (TIPUS='+chr(39)+'V'+chr(39)+')';

  with vQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      vQuery.close;
      vdbase.close;
      exit;
    end;

  RekordCsik.Max := _recno;
  _cc := 0;

  while not vquery.eof do
    begin
      inc(_cc);
      Rekordcsik.Position := _cc;

      _kifizetve := vquery.fieldbyName('OSSZESEN').asInteger;
      _afaugyfel[_pt] := _afaugyfel[_pt] + 1;
      _afaforgalom[_pt] := _afaforgalom[_pt] + _kifizetve;

      vquery.Next;
    end;
  VQuery.close;
  Vdbase.close;




end;


procedure TForm1.Ekerlegyujtes;

var _ekertablanev: string;
    _xMat,_xTel,_xVod,_xPay: integer;

begin
  _ekertablanev := 'EFEJ' + _aktfarok;

  vdbase.Connected := true;
  vTabla.TableName := _ekertablanev;
  if not vtabla.Exists then
    begin
      vdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _ekertablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>='+chr(39)+_tols+chr(39)+')';
  _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igs+chr(39)+')';

  with vQuery do
    begin
      Close;
      sql.clear;
      Sql.Add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      vQuery.close;
      vdbase.close;
      exit;
    end;

  RekordCsik.Max := _recno;
  _cc := 0;

  while not vQuery.eof do
    begin
      inc(_cc);
      Rekordcsik.Position := _cc;

      _xmat := vquery.fieldbyname('MATRICA').asInteger;
      _xtel := vquery.FieldByName('TELEFON').asInteger;
      _xVod := vQuery.FieldByName('VODAFON').asInteger;
      _xPay := vQuery.FieldByName('PAYSAFECARD').asInteger;

      _ekerugyfel[_pt] := _ekerugyfel[_pt] + 1;
      _automatrica[_pt]:= _automatrica[_pt] + _xmat;
      _telefon[_pt] := _telefon[_pt] + _xVod + _xTel;
      _paysafecard[_pt] := _paysafecard[_pt] + _xPay;
      Vquery.next;
    end;
  Vquery.close;
  Vdbase.close;

end;

procedure TForm1.Axalegyujtes;

var _axaTablanev: string;
    _ertek: integer;

begin
  _axatablanev := 'FAXA' + _aktfarok;
  vdbase.Connected := true;
  vTabla.TableName := _AXAtablanev;
  if not vtabla.Exists then
    begin
      vdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM ' + _axatablanev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>='+chr(39)+_tols+chr(39)+')';
  _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igs+chr(39)+')';
  _pcs := _pcs + ' AND (MOZGAS=21)';

  with vQuery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      vQuery.close;
      vdbase.close;
      exit;
    end;

  RekordCsik.Max := _recno;
  _cc := 0;

  while not vQuery.eof do
    begin
      inc(_cc);
      Rekordcsik.Position := _cc;

      _ertek := vquery.fieldbYnAME('ERTEK').asInteger;
      _axaUgyfel[_pt] := _axaUgyfel[_pt] + 1;
      _axaforgalom[_pt] := _axaForgalom[_pt] + _ertek;

      vquery.Next;
    end;
  Vquery.close;
  vdbase.close;
end;

procedure TForm1.TranzadoLegyujtes;

var _tranztablanev: string;
    _tdij,_nk,_nv,_aktnap: integer;

begin
  _tranztablanev := 'TRANZDIJ' + _aktfarok;
  _nk := 1;
  _nv := 31;

  if (_aktfarok=_evhostol) then _nk := _tolnap;
  if (_aktfarok=_evhosig) then _nv := _ignap;

  Tranzdbase.Connected := true;
  TranzTabla.TableName := _tranztablanev;
  if not Tranztabla.Exists then
    begin
      Tranzdbase.close;
      exit;
    end;

  _pcs := 'SELECT * FROM '+ _tranztablanev + _sorveg;
  _pcs := _pcs + 'ORDER BY CASHIER';

  with Tranzquery do
    begin
      Close;
      sql.clear;
      sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
      First;
    end;

  if _recno=0 then
    begin
      Tranzquery.close;
      Tranzdbase.close;
      exit;
    end;

  RekordCsik.Max := _recno;
  _cc := 0;

  while not TranzQuery.eof do
    begin
      inc(_cc);
      Rekordcsik.Position := _cc;
      _aktnap := TranzQuery.FieldByname('NAP').asInteger;
      _tdij := Tranzquery.fieldbyname('TRANSFEE').asInteger;
      _aktpt:= TranzQuery.Fieldbyname('CASHIER').asInteger;
      if (_aktnap>=_nk) and (_aktnap<=_nv) then
                        _tranzado[_aktpt] := _tranzado[_aktpt] + _tdij;
      TranzQuery.Next;
    end;
  Tranzquery.close;
  Tranzdbase.close;
end;




end.
