unit Unit5;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, unit1, ExtCtrls, IBDatabase, DB, IBCustomDataSet, IBQuery,
  StdCtrls, ComCtrls, IBTable;

type
  TUJPENZTARFORGALOM = class(TForm)
    START: TTimer;
    BLOKKQUERY: TIBQuery;
    BLOKKDBASE: TIBDatabase;
    BLOKKTRANZ: TIBTransaction;
    Label1: TLabel;
    PENZTARPANEL: TPanel;
    SMALLCSIK: TProgressBar;
    HIGHCSIK: TProgressBar;
    honappanel: TPanel;
    BLOKKTABLA: TIBTable;

    procedure FormActivate(Sender: TObject);
    procedure STARTTimer(Sender: TObject);

    function Blokknyitas: integer;



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  UJPENZTARFORGALOM: TUJPENZTARFORGALOM;
  _ERTEK: integer;
  _valutanem : string;

implementation



{$R *.dfm}

// =============================================================================
             procedure TUjPenztarForgalom.FormActivate(Sender: TObject);
// =============================================================================

begin
  Top := _top + 108;
  Left := _left + 228;
  width := 423;
  Height := 232;
  Start.Enabled := true;
  Start.enabled := true;
end;


// =============================================================================
              procedure TUjPenztarForgalom.StartTimer(Sender: TObject);
// =============================================================================

var i: byte;

begin
  Start.Enabled := false;

  for i := 1 to 150 do _ptarforg[i] := 0;

  HonapPanel.Caption := inttostr(_gyujtoev)+ ' év '+inttostr(_gyujtohonap)+' hó';
  HonapPanel.Repaint;

  // A hónap ismeretében a változók kialakítása:

  _farok        := inttostr(_gyujtoev-2000)+Form1.nulele(_gyujtohonap);
  _bfTablaNev   := 'BF' + _farok;
  _btTablaNev   := 'BT' + _farok;

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
      if form1.ezErtektar(_penztar) then
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

      uJPenztarforgalom.Repaint;
      PenztarPanel.Caption := _irodanevtomb[_penztar];
      Penztarpanel.Repaint;

      // HA nincs a kért hónapra blokkfejtábla, a pénztárt átlépi a program:

      BlokkDbase.close;
      BlokkDbase.DatabaseName := _aktfdbPath;
      BlokkDbase.Connected := true;
      BlokkTabla.close;

      BlokkTabla.TableName := _bfTablaNev;
      form1.TPANEL.caption := _bfTablanev;
      Form1.TPANEL.repaint;
      if BlokkTabla.Exists then
        begin
           Blokkdbase.close;

           // Létezõ pénztár, létezõ blokkfej tábláját megnyitja:

           _recno := Blokknyitas;
           Smallcsik.max := _recno;

           _cc := 0;

           //  A megnyitott blokkokon végigmegy a program:

           while not BlokkQuery.Eof do
             begin
               inc(_cc);
               smallcsik.Position := _cc;

               // A blokkok adatait változókba olvassa:

               with BlokkQuery do
                 begin
                   _ertek         := FieldByName('FORINTERTEK').asInteger;
                   _valutanem     := FieldByName('VALUTANEM').asString;
                 end;

              if _valutanem<>'HUF' then
                      _ptarforg[_penztar] := _ptarforg[_penztar] + _ertek;

               // Jöhet a következõ bizonylat:

               BlokkQuery.next;
             end;

           // Az összes valutaváltó bizonylat be van itt summázva a tömbökbe:

           BlokkQuery.close;
           BlokkDbase.close;
         end;
      inc(_penztar);
    end;
  Modalresult := 1;
end;



// =============================================================================
             function TUjpenztarForgalom.Blokknyitas: integer;
// =============================================================================

begin
  _pcs := 'SELECT FEJ.*,TET.*' + _sorveg;
  _pcs := _pcs + 'FROM '+ _bfTablaNev + ' FEJ JOIN ' + _btTablaNev + ' TET' + _sorveg;
  _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (FEJ.STORNO=1) AND ((TIPUS='+chr(39)+'V'+chr(39)+')';
  _pcs := _pcs + ' OR (TIPUS=' + chr(39) + 'E'+ chr(39)+') OR (TIPUS=';
  _pcs := _pcs + chr(39) + 'K' + CHR(39)+'))';

  Blokkdbase.connected := true;
  with BlokkQuery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      Result := recno;
      First;
    end;
end;

end.
