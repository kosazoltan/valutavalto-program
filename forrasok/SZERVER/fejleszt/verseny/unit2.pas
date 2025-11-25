unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UNIT1, IBDatabase, DB, IBQuery, IBCustomDataSet, IBTable, Strutils,
  ExtCtrls, ComCtrls, StdCtrls;

type
  TJUTALEK = class(TForm)
    VFEJTABLA: TIBTable;
    VFEJQUERY: TIBQuery;
    VFEJDBASE: TIBDatabase;
    VFEJTRANZ: TIBTransaction;
    VTETQUERY: TIBQuery;
    VTETDBASE: TIBDatabase;
    VTETTRANZ: TIBTransaction;
    PROSNEVPANEL: TPanel;
    VALTOPANEL: TPanel;
    START: TTimer;
    highcsik: TProgressBar;
    smallcsik: TProgressBar;
    Label1: TLabel;
    honappanel: TPanel;
    IPANEL: TPanel;
    npanel: TPanel;

    procedure FormActivate(Sender: TObject);
    function BlokkNyitas: integer;
    
    function CompareIdPros(_i,_n: string): boolean;
    function Scanid(_id: string): integer;

    procedure STARTTimer(Sender: TObject);
    
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  JUTALEK: TJUTALEK;
  _vprosnev,_aktpros,_nPara: string;

implementation

{$R *.dfm}


// =============================================================================
               procedure TJUTALEK.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := _top +108;
  Left := _left +228;
  width := 423;
  Height := 232;
  Start.Enabled := true;
end;


// =============================================================================
              procedure TJUTALEK.STARTTimer(Sender: TObject);
// =============================================================================

var i: integer;

begin
   Start.Enabled := false;
   for i := 1 to 500 do
     begin
       _prosforg[i]   := 0;
       _proswuni[i]   := 0;
       _proskezdij[i] := 0;
     end;

  HonapPanel.Caption := inttostr(_gyujtoev)+ ' év '+inttostr(_gyujtohonap)+' hó';
  HonapPanel.Repaint;

  // A hónap ismeretében a változók kialakítása:

  _farok        := inttostr(_gyujtoev-2000)+Form1.nulele(_gyujtohonap);
  _bfTablaNev   := 'BF' + _farok;
  _btTablaNev   := 'BT' + _farok;
  _wuniTablaNev := 'WUNI' + _farok;
  _narfTablaNev := 'NARF' + _farok;
  _arfeTablaNev := 'ARFE' + _farok;

  // ---------------------------------------------------------------------------

  // Beolvassa minden egyes nap USD árfolyamát, (a WU jutalék érdekében)

  Form1.Arfolyambeolvasas;  // A napi usd árfolyamok 1..31

  // ---------------------------------------------------------------------------

  // Az 1-es pénztártól a 150-ik pénztárig megy végig a program:

   _penztar := 1;
   while _penztar<=150 do
     begin
       if _oev then
         begin
           if (_penztar=78) or (_penztar=79) then
             begin
               inc(_penztar);
               Continue;
             end;
         end else
         begin
           if (_penztar=72) or (_penztar=73) then
             begin
               inc(_penztar);
               Continue;
             end;
         end;
         
       Highcsik.Position := _penztar;
       if Form1.ezErtektar(_penztar) then
         begin
           inc(_penztar);
           continue;
         end;

       //  Ha nincs ilyen pénztár, akkor ezt is átlépi:

       _aktfdbPath := 'c:\receptor\database\v' + inttostr(_penztar)+'.fdb';
       if not FileExists(_aktfdbPAth) then
         begin
           inc(_penztar);
           Continue;
         end;

       // HA nincs a kért hónapra blokkfejtábla, a pénztárt átlépi a program:

       Jutalek.Repaint;

       ProsnevPanel.Caption := _irodanevtomb[_penztar];
       Prosnevpanel.Repaint;

       ValtoPanel.Caption := 'VALUTAVÁLTÁS';
       ValtoPanel.Repaint;

       vFejDbase.close;
       vFejDbase.DatabaseName := _aktfdbPath;
       vFejDbase.Connected := true;
       vFejTabla.close;

       vFejTabla.TableName := _bfTablaNev;
       Form1.Tpanel.caption := _bftablanev;
       Form1.TPANEL.Repaint;
       if vFejTabla.Exists then
         begin

           // A kért hónap jutalékmentes bizonylatait tömbbe olvassa:

           _jfreebizDarab := 0;

           Form1.JutfreeBizonylatok;  // A 34-es engedménytipusu bizonylatszamok tömbbe olvasás

           // Most megnyitja a blokkok tábláját (storno=1,tipus=V-E-K,idõintervallum)

           vFEJdbase.close;

            // Létezõ pénztár, létezõ blokkfej tábláját megnyitja:

           _recno := Blokknyitas;
           Smallcsik.Max := _recno;
           _cc := 0;

           //  A megnyitott blokkokon végigmegy a program:

           while not vFejQuery.Eof do
             begin
               inc(_cc);
               Smallcsik.Position := _cc;

               // A blokkok adatait változókba olvassa:

               with VFejQuery do
                 begin
                   _tipus         := FieldByName('TIPUS').asString;
                   _idKod         := FieldByName('IDKOD').asString;
                   _osszeg        := FieldByName('OSSZESEN').asInteger;
                   _kezdij        := abs(FieldbyName('KEZELESIDIJ').asInteger);
                   _vProsnev      := trim(FieldByNAme('PENZTAROSNEV').asString);

                   _bizonylatszam := FieldByName('BIZONYLATSZAM').asString;
                 end;

               Form1.BizPanel.caption := _bizonylatszam;
               Form1.Bizpanel.repaint;

               if _idkod='00000' then
                 begin
                   VFejQuery.next;
                   Continue;
                 end;


               if not CompareIdpros(_idKod,_vProsnev) then
                 begin
                   VFejTabla.close;
                   VFejDbase.close;

                   ShowMessage('HIBÁS ID-KÓD: '+_vprosnev+' - '+_idKod);
                   ModalResult := 2;
                   Exit;
                 end;

               // A konverzió esetén: a forintérték kétszerese számít !

               if (_tipus='K') THEN _osszeg := Form1.GetKonvOsszeg(_bizonylatszam);
                // and (_elojel='+') then _osszeg := _osszeg + trunc(2*_ftErtek);

               //  A bizonylatszám alapján megnézi, nem-e jutalékmentes a tranzakció ?

               _ezJutFree := Form1.JutalekFree(_bizonylatszam);

               // Az idkod és pénztár index alapján megkeresi az adat sorszámát:
               // A visszatérés a tömb indexét adja.
               // Az idpointer a következõ elemre mutat, ha ez egy új elem:
               //


               _xx := scanid(_idKod);
               if _xx>0 then
                 begin


               // Ha jutalékmentes ez a bizonylat, akkor itt summmázza
               // Ha nem, akkor a forgalom és kezelési dij tömbbe summázódik

                   if not _ezjutfree then
                     begin
                       _prosforg[_xx] := _prosforg[_xx] + _osszeg;
                       _proskezdij[_xx]:= _proskezdij[_xx] + _kezdij;
                     end;
                 end;

               // Jöhet a következõ bizonylat:

               VFejQuery.next;
             end;

           // Az összes valutaváltó bizonylat be van itt summázva a tömbökbe:

           VFejQuery.close;
           vFejDbase.close;
         end

         //  Nincsen ennek a péntárnak a kért havi blokkfejtáblája
         // Igy jöhet a következõ pénztár:

         else
         begin
           vFejdbase.close;
           inc(_penztar);
           continue;
         end;

       // ----------------------------------------------------------------------

       //  A Western Union jutalékok kiszámítása, illetve tömbbe gyüjtése:
       vfejdbase.close;
       vfejdbase.DatabaseName := _aktfdbpath;
       vFejDbase.Connected := True;
       vFejTabla.TableName := _wunitablanev;

       Form1.TPANEL.Caption := _wunitablanev;
       Form1.TPANEL.repaint;

       // Ha ennek a pénztárnak van Western Unionja, akkor kigyüjti az afatokat

       if vFejTabla.Exists then
         begin

            Valtopanel.Caption := 'WESTERN UNION';
            ValtoPanel.Repaint;

           // Megnyitja a WUNIyymm táblát napintervallumban,storno=1
           // ugyfeltipus='U' feltételekkel:

           _pcs := 'SELECT * FROM ' + _wunitablanev + _sorveg;
           _pcs := _pcs + 'WHERE (STORNO=1)';
           _pcs := _pcs + ' AND (UGYFELTIPUS='+chr(39)+'U'+chr(39)+')';

           with vFejQuery do
             begin
               Close;
               Sql.clear;
               sql.add(_pcs);
               Open;
               Last;
               _recno := recno;
               First;
             end;

           Smallcsik.Max := _recno;
           _cc := 0;

           // Végig megy az összes rekordokon:

           while not vFejQuery.eof do
             begin
               inc(_cc);
               SmallCsik.Position := _cc;
               with vFejQuery do
                 begin
                   _idkod := FieldByName('IDKOD').asstring;
                   _vnem  := FieldByName('VALUTANEM').asstring;
                   _bjegy := FieldByName('BANKJEGY').asInteger;
                   _datum := FieldByName('DATUM').asstring;
                   _vprosnev := FieldByNAme('PENZTAROSNEV').asString;
                 end;

               if (_idkod='00000') OR (trim(_idkod)='') then
                 begin
                   vfejquery.next;
                   Continue;
                 end;

               Form1.BizPanel.caption := _datum+'-'+_vnem;
               Form1.Bizpanel.repaint;

               if not CompareIdpros(_idKod,_vProsnev) then
                 begin
                   Vfejtabla.close;
                   Vfejdbase.close;
                   ShowMessage('HIBÁS ID-KÓD: '+trim(_vprosnev)+' - '+_idKod);
                   ModalResult := 2;
                   Exit;
                 end;

               //  A dátumból kiszedi a napot:

               _naps := midstr(_datum,9,2);
               val(_naps,_nap,_code);
               if _code<>0 then _nap := 1;

               // Ha a tranzakció forintban van az összeg a banykjegy mezõ
               // Ha dollárban van, akkor átszámítja forintra

               if _vnem='HUF' then _osszeg := _bjegy
               else _osszeg := trunc(_usdarf[_nap]*_bjegy/100);

               // Megkeresi a idkod-penztar indexet

               _xx := scanid(_idkod);

               // A tömbbe begyüjti a wu forgalmat az index alapjáb

               if _xx>0 then _prosWuni[_xx] := _proswuni[_xx] + _osszeg;

               // Jöhet a következö wu. bizonylat:

               vFejquery.next;
             end;

           // A Wu bizonylatok be vannak itt summázva a _swuni tömbbe:

           vFejquery.close;
           vFejdbase.close;
         end;

       // ----------------------------------------------------------------------

       //  Jöhet a következõ pénztár:

       inc(_penztar);
     end;
  Modalresult := 1;

end;

// =============================================================================
                function TJutalek.Scanid(_id: string): integer;
// =============================================================================

begin
  result := 0;
  if trim(_id)='' then exit;
  if _idDarab=0 then
    begin
      _idsequ[1] := _id;
      _idDarab := 1;
      result := 1;
      exit;
    end;

  while result<_idDarab do
    begin
      if _idSequ[result]=_id then exit;
      inc(result);
    end;
  _idsequ[result] := _id;
  inc(_idDarab);
end;





// =============================================================================
                      function TJUtalek.BlokkNyitas: integer;
// =============================================================================

begin
  vfejDbase.close;
  VFejdbase.DatabaseName := _aktfdbPath;
  vFejDbase.Connected := True;
  _pcs := 'SELECT * FROM '+ _bfTablaNev + _sorveg;

  _pcs := _pcs + 'WHERE (STORNO=1) AND ((TIPUS='+chr(39)+'V'+CHR(39)+')';
  _pcs := _pcs + ' OR (TIPUS='+chr(39)+'E'+CHR(39)+')';
  _pcs := _pcs + ' OR (TIPUS='+chr(39)+'K'+chr(39)+'))';

  with vFejQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      result := Recno;
      First;
    end;
end;


// =============================================================================
         function TJutalek.CompareIdPros(_i,_n: string): boolean;
// =============================================================================

var _z: integer;
  

begin
  _z := 1;
  result := false;
  ipanel.caption := trim(_i);
  npanel.Caption := trim(_n);
  ipanel.repaint;
  npanel.repaint;
  _n := trim(_n);
  _i := trim(_i);
  if (_n='') or (_i='') then
    begin
      _vprosnev := 'Üres idkód vagy pénztárosnév ('+inttostr(_penztar)+' pénztárban)';
      exit;
    end;

  _nPara := uppercase(leftstr(_n,11));
  _nPara := Form1.angolra(_nPara);
  while _z<=_penztarosdarab do
    begin
      if _idtomb[_z]=_i then break;
      inc(_z);
    end;
  if _z>_penztarosdarab then exit;
  _aktpros := trim(uppercase(leftstr(_prostomb[_z],11)));
  if _aktpros=_nPara then result := true;
end;




end.
