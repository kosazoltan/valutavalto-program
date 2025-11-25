unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, IBDatabase, DB, IBCustomDataSet, IBQuery,
  IBTable, strutils, ExtCtrls, ComCtrls, jpeg;

type
  TForm1 = class(TForm)
    BitBtn2: TBitBtn;
    BLOKKQUERY: TIBQuery;
    BLOKKDBASE: TIBDatabase;
    BLOKKTRANZ: TIBTransaction;
    BLOKKTABLA: TIBTable;
    PNEVPANEL: TPanel;
    PENZTARPANEL: TPanel;
    TARSPANEL: TPanel;
    BANKJEGYPANEL: TPanel;
    PTQUERY: TIBQuery;
    PTDBASE: TIBDatabase;
    PTTRANZ: TIBTransaction;
    IRANYPANEL: TPanel;
    BALPANEL: TPanel;
    JOBBPANEL: TPanel;
    tranzakciopanel: TPanel;
    CSIK: TProgressBar;
    Label1: TLabel;
    PTTABLA: TIBTable;
    INDITO: TTimer;
    EREDMENYGOMB: TBitBtn;
    RECQUERY: TIBQuery;
    RECDBASE: TIBDatabase;
    RECTRANZ: TIBTransaction;
    FOCSIK: TProgressBar;
    Shape1: TShape;
    keppanel: TPanel;
    Image1: TImage;
    KILEPO: TTimer;

    procedure BitBtn2Click(Sender: TObject);
    procedure Ptarbeolvasas;
    function Tree(_n: byte): string;
   
    procedure PtParancs(_ukaz: string);
    function Nulele(_byte: byte): string;
    procedure FormActivate(Sender: TObject);
    procedure INDITOTimer(Sender: TObject);
    function ScanKVar(_kminta: string): integer;
    function ScanFVar(_fminta: string): integer;
    procedure EREDMENYGOMBClick(Sender: TObject);
    procedure KILEPOTimer(Sender: TObject);

  

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  _kdata,_fdata: array[0..3999] of integer;
  _ktomb,_ftomb: array[0..3999] of string;
  _knap,_fnap  : array[0..3999] of byte;
  _kvar,_fvar,_kdatum,_fdatum,_kerthos: string;

  _farok,_fejtablanev,_tetTablanev,_fdbpath,_pcs,_tablanev,_feltetel: string;
  _datum,_tipus,_bizonylatszam,_penztars,_valutanem: string;
  _bankjegy,_code,_eddig,_aktsorszam,_sorszam,_kx,_fx,_kvardb,_fvardb: integer;
  _sorveg: string = chr(13)+chr(10);
  _pt,_recno,_cc,_HIBAS,_kb,_fb,_diff: integer;
  _penztar,_kuldo,_fogado,_aktnap,_kn,_fn: byte;
  _kertev,_kertho: word;
  _ptnev: array[1..150] of string;
  _Jobbra: string = '>>>>>';
  _balra : string = '<<<<<';


   _dnem: array[1..23] of string = ('AUD','BAM','BGN','CAD','CHF','CNY','CZK','DKK',
                        'EUR','GBP','HRK','HUF','ILS','JPY','NOK','PLN','RON',
                        'RSD','RUB','SEK','TRY','UAH','USD');

  _pAtad,_pAtvet: array[1..150,1..23] of integer;
  _height,_width,_top,_left,_hooke: word;


implementation

uses Unit2, Unit4;

{$R *.dfm}

// =============================================================================
              procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================


begin
  _height := Screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := trunc((_height-444)/2);
  _left:= trunc((_width-454)/2);

  Top := _top;
  Left := _left;

  _hooke := Hobekero.ShowModal;
  if _hooke=2 then
    begin
      Kilepo.enabled := True;
      exit;
    end;

  EredmenyGomb.Enabled := false;

  Ptarbeolvasas;
  _pcs := 'DELETE FROM COMPARE';
  ptParancs(_pcs);
  Indito.Enabled := TRUE;
end;


// =============================================================================
                   procedure TForm1.INDITOTimer(Sender: TObject);
// =============================================================================

var _y,_kbj,_fbj,_diff,_xx: integer;
    _var,_bizonylat: string;
    _txtiro: textfile;

begin
  Indito.Enabled := False;

  Focsik.Max := 4;
  Focsik.Position := 0;

  _kvardb := 0;
  _fvardb := 0;
  Csik.max := 150;

  _kerthos := inttostr(_kertev)+'.'+nulele(_kertho);

  _farok := inttostr(_kertev-2000)+nulele(_kertho);
  _fejtablanev := 'BF' + _farok;
  _tetTablaNev := 'BT' + _farok;

  TranzakcioPanel.Caption := 'ADÁS-VÉTEL LEGYÜJTÉSE';
  TranzakcioPanel.Repaint;

  _pt := 3;    /// itt 3 kell
  while _pt<=150 do
    begin

      Csik.Position := _pt;

      Form1.Repaint;
      _fdbpath := 'c:\receptor\database\v'+inttostr(_pt)+'.fdb';
      if not FileExists(_fdbPath) then
        begin
          inc(_pt);
          continue;
        end;

     BlokkDbase.close;
     Blokktabla.close;
     Blokkdbase.DatabaseName := _fdbPath;

     Blokktabla.TableName := _fejtablanev;
     Blokkdbase.Connected := True;

     if not Blokktabla.Exists then
       begin
         Blokkdbase.close;
         inc(_pt);
         Continue;
       end;

     PnevPanel.Caption := _ptnev[_pt];
     PnevPanel.Repaint;

     PenztarPanel.Caption := inttostr(_pt);
     PenztarPanel.Repaint;

     _pcs := 'SELECT FEJ.*, TET.*' + _sorveg;
     _pcs := _pcs +'FROM '+_fejtablanev+' FEJ JOIN '+_tettablanev+' TET'+_sorveg;
     _pcs := _pcs + 'ON FEJ.BIZONYLATSZAM=TET.BIZONYLATSZAM'+_sorveg;

     _pcs := _pcs + 'WHERE (FEJ.STORNO=1) AND ((FEJ.TIPUS=';
     _pcs := _pcs + chr(39) + 'F' + chr(39)+') OR (FEJ.TIPUS=';
     _pcs := _pcs + chr(39) + 'U' + chr(39) + '))';

     with BlokkQuery do
       begin
         Close;
         Sql.clear;
         sql.add(_pcs);
         Open;
         Last;
         _recno := recno;
         First;
       end;

     if _recno=0 then
       begin
         Blokkquery.close;
         Blokkdbase.close;
         inc(_pt);
         continue;
       end;

     while not BlokkQuery.Eof do
       begin
         _tipus     := BlokkQuery.FieldByName('TIPUS').asString;
         _penztars  := trim(BlokkQuery.FieldByNAme('PENZTAR').asString);
         _valutanem := BlokkQuery.FieldByName('VALUTANEM').asString;
         _bankjegy  := BlokkQuery.FieldByName('BANKJEGY').asInteger;
         _datum     := BlokkQuery.FieldByName('DATUM').asString;

         val(_penztars,_penztar,_code);
         if _code<>0 then _penztar := 0;

         // 0 és 1-es pénztár nem kell:

         if _penztar<2 then
           begin
             Blokkquery.Next;
             continue;
           end;

         _aktnap := strtoint(midstr(_datum,9,2));


         PenztarPanel.Caption := inttostr(_pt);
         TarsPanel.Caption := inttostr(_penztar);

         PenztarPanel.Repaint;
         Tarspanel.Repaint;

         if _tipus='F' then
           begin
             iranypanel.Caption := _jobbra;
             Balpanel.Caption   := 'KÜLDÕ';
             Jobbpanel.Caption  := 'FOGADÓ';

             _kuldo  := _pt;
             _fogado := _penztar;
             _kvar := 'K'+tree(_pt)+tree(_penztar)+_valutanem;

             _xx := scanKvar(_kvar);
             _kData[_xx] := _kData[_xx] + _bankjegy;
             _knap[_xx] := _aktnap;
           end
         else
           begin
             Iranypanel.Caption := _balra;
             Balpanel.Caption   := 'FOGADÓ';
             JobbPanel.Caption := 'KÜLDÕ';

             _kuldo  := _penztar;
             _fogado := _pt;

             _fvar := 'F'+tree(_penztar)+tree(_pt)+_valutanem;
             _xx := scanFvar(_fvar);
             _fData[_xx] := _fData[_xx] + _bankjegy;
             _fnap[_xx] := _aktnap;
           end;

         Iranypanel.Repaint;
         Balpanel.Repaint;
         Jobbpanel.Repaint;

         BlokkQuery.next;
       end;

      BlokkQuery.close;
      Blokkdbase.close;
      inc(_pt);
    end;

  Focsik.Position := 1;

  // ---------------------------------------------------------------------------

  with KepPanel do
    begin
      top := 168;
      left := 40;
      height := 89;
      width := 385;
      repaint;
    end;

  Tranzakciopanel.Caption := 'KÜLDÖTT ADATOK RÖGZITÉSE';
  tRANZAKCIOPANEL.Repaint;

  Csik.Max := _kvardb;
  _y := 0;
  while _y<_Kvardb do
    begin
      Csik.Position := _y;

      _kvar := _Ktomb[_y];
      _kuldo := strtoint(midstr(_kvar,2,3));
      _fogado := strtoint(midstr(_kvar,5,3));
      _valutanem := midstr(_kvar,8,3);

      _kbj := _kdata[_y];
      _kn := _knap[_y];
      _kdatum := _kerthos + '.' + nulele(_kn);

      BankjegyPanel.Caption := inttostr(_kbj)+' '+ _valutanem;
      BankjegyPanel.Repaint;

      Pnevpanel.Caption := _ptnev[_kuldo];
      PnevPanel.Repaint;

      _pcs := 'INSERT INTO COMPARE (KULDO,FOGADO,VALUTANEM,DATUM,';
      _pcs := _pcs + 'KULDOTTBANKJEGY,FOGADOTTBANKJEGY)'+_sorveg;
      _pcs := _pcs + 'VALUES (' + inttostr(_kuldo)+',';
      _pcs := _pcs + inttostr(_fogado) + ',';
      _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
      _PCS := _pcs + chr(39) + _kdatum + chr(39) + ',';
      _pcs := _pcs + inttostr(_kbj) + ',0)';

      ptparancs(_pcs);
      inc(_y);
    end;

  Focsik.Position := 2;

   Tranzakciopanel.Caption := 'FOGADOTT ADATOK RÖGZITÉSE';
  tRANZAKCIOPANEL.Repaint;

  // ---------------------------------------------------------------------------

  Csik.Max := _fvardb;
  _y := 0;
  while _y<_fvardb do
    begin
      Csik.position := _y;
      _fvar := _fTomb[_y];

      _kuldo := strtoint(midstr(_fvar,2,3));
      _fogado := strtoint(midstr(_fvar,5,3));
      _valutanem := midstr(_fvar,8,3);
      _fbj := _fdata[_y];
      _fn := _fnap[_y];
      _fdatum := _kerthos + '.' + nulele(_fn);

      BankjegyPanel.Caption := inttostr(_fbj)+' '+ _valutanem;
      BankjegyPanel.Repaint;


      Pnevpanel.Caption := _ptnev[_fogado];
      PnevPanel.Repaint;


      _feltetel := 'WHERE (KULDO='+inttostr(_kuldo)+') AND (FOGADO=';
      _feltetel := _feltetel + inttostr(_fogado)+') AND (VALUTANEM=';
      _feltetel := _feltetel + chr(39)+_valutanem+chr(39)+')';

      _pcs := 'SELECT * FROM COMPARE' + _sorveg + _feltetel;

      Ptdbase.Connected := true;
      with Ptquery do
        begin
          Close;
          sql.clear;
          sql.Add(_pcs);
          Open;
          First;
          _recno := recno;
          close;
        end;
      Ptdbase.close;

      if _recno=0 then
        begin
          _pcs := 'INSERT INTO COMPARE (KULDO,FOGADO,VALUTANEM,DATUM,';
          _pcs := _pcs + 'FOGADOTTBANKJEGY,KULDOTTBANKJEGY)'+_sorveg;
          _pcs := _pcs + 'VALUES (' + inttostr(_kuldo)+',';
          _pcs := _pcs + inttostr(_fogado) + ',';
          _pcs := _pcs + chr(39) + _valutanem + chr(39) + ',';
          _pcs := _pcs + chr(39) + _fdatum + chr(39) + ',';
          _pcs := _pcs + inttostr(_Fbj) + ',0)';
        end else
        begin
          _pcs := 'UPDATE COMPARE SET FOGADOTTBANKJEGY='+inttostr(_fbj)+_sorveg;
          _pcs := _pcs + _feltetel;
        end;

      ptparancs(_pcs);
      inc(_y);
    end;

  Focsik.Position := 3;

  PnevPanel.Caption := '';
  Pnevpanel.Repaint;

  Tranzakciopanel.Caption := 'TRANZAKCIÓK ÖSSZEHASONLÍTÁSA';
  TranzakcioPanel.Repaint;

  Ptdbase.Connected := true;
  if pttranz.InTransaction then pttranz.Commit;
  Pttranz.StartTransaction;
  Pttabla.Open;
  PtTabla.First;
  _y := 0;
  while not PtTabla.Eof do
    begin
      inc(_y);
      Csik.Position := _y;
      _kbj := Pttabla.fieldbyname('KULDOTTBANKJEGY').asInteger;
      _fbj := Pttabla.Fieldbyname('FOGADOTTBANKJEGY').asInteger;
      _diff := _fbj - _kbj;

      BankjegyPanel.Caption := inttostr(_diff);
      BankjegyPanel.Repaint;

      Pttabla.edit;
      Pttabla.FieldByName('DIFFRENT').AsInteger := _diff;
      Pttabla.post;
      Pttabla.Next;
    end;
  Pttranz.Commit;
  Ptdbase.Close;
  Pttabla.close;
  Focsik.Position := 4;
  Sleep(1500);

  Csik.Visible := False;
  Focsik.Visible := False;
  
  BankjegyPanel.Caption := '';
  BankjegyPanel.Repaint;

  EredmenyGomb.Enabled := True;
  Activecontrol := Eredmenygomb;
end;


// =============================================================================
             function TForm1.ScanKVar(_kminta: string): integer;
// =============================================================================

var
    _y: integer;

begin
  if _kvardb=0 then
    begin
      _ktomb[0] := _kminta;
      _kdata[0]  := 0;
      _kvardb := 1;
      result := 0;
      exit;
    end;

  _y := 0;
  while _y<_kvardb do
    begin
      if _ktomb[_y]=_kminta then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;

  _ktomb[_kvardb] := _kminta;
  _kdata[_kvardb]  := 0;
  result := _kvardb;
  inc(_kvardb);
end;


// =============================================================================
             function TForm1.ScanFVar(_fminta: string): integer;
// =============================================================================

var
    _y: integer;

begin
  if _fvardb=0 then
    begin
      _ftomb[0] := _fminta;
      _fdata[0]  := 0;
      _fvardb := 1;
      result := 0;
      exit;
    end;

  _y := 0;
  while _y<_fvardb do
    begin
      if _ftomb[_y]=_fminta then
        begin
          result := _y;
          exit;
        end;
      inc(_y);
    end;

  _ftomb[_fvardb] := _fminta;
  _fdata[_fvardb]  := 0;
  result := _fvardb;
  inc(_fvardb);
end;



// =============================================================================
              function TForm1.Nulele(_byte: byte): string;
// =============================================================================

begin
  result := inttostr(_byte);
  if _byte<10 then result := '0' + result;
end;

// =============================================================================
               procedure Tform1.PtParancs(_ukaz: string);
// =============================================================================

begin
  PtDbase.close;
  PtDbase.connected := true;
  if PtTranz.InTransaction then PtTranz.Commit;
  PtTranz.StartTransaction;
  with PtQuery do
    begin
      Close;
      sql.clear;
      sql.add(_ukaz);
      ExecSql;
    end;
  PtTranz.commit;
  PtDbase.close;
end;


procedure TForm1.PtarBeolvasas;

var _pt : byte;
   _pn : string;

begin

  Recdbase.connected := true;
  _pcs := 'SELECT * FROM IRODAK ORDER BY UZLET';

  with REcquery do
    begin
      Close;
      Sql.clear;
      Sql.add(_pcs);
      Open;
      First;
    end;

  while not Recquery.Eof do
    begin
      _pt := Recquery.FieldByName('UZLET').asInteger;
      IF _PT>150 THEN BREAK;
      
      _pn := trim(Recquery.FieldByName('KESZLETNEV').asString);
      _ptnev[_pt] := _pn;
      Recquery.next;
    end;
  Recquery.close;
  Recdbase.close;
end;








// =============================================================================
               procedure TForm1.BitBtn2Click(Sender: TObject);
// =============================================================================

begin
  Application.Terminate;
end;


// =============================================================================
              function TForm1.Tree(_n: byte): string;
// =============================================================================


begin
  result := inttostr(_n);
  while length(result)<3 do result := '0' + result;
end;




// =============================================================================
          procedure TForm1.EREDMENYGOMBClick(Sender: TObject);
// =============================================================================

begin
   EredmenyForm.ShowModal;
end;

procedure TForm1.KILEPOTimer(Sender: TObject);
begin
  Kilepo.Enabled := false;
  Application.terminate;
end;

end.
