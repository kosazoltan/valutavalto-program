unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IBTable, IBDatabase, DB, IBCustomDataSet, IBQuery,
  ExtCtrls, strutils, DateUtils, Buttons, Grids, Calendar, printers;

type

  TKEZDDEKAD = class(TForm)

    NaploQuery    : TIBQuery;
    NaploDbase    : TIBDatabase;
    NaploTranz    : TIBTransaction;

    ValutaTranz   : TIBTransaction;
    ValutaDbase   : TIBDatabase;
    ValutaQuery   : TIBQuery;

    ValdataTabla  : TIBTable;
    ValdataQuery  : TIBQuery;
    ValdataDbase  : TIBDatabase;
    ValdataTranz  : TIBTransaction;

    DekadCombo    : TComboBox;
    EvCombo       : TComboBox;
    HoCombo       : TComboBox;

    DekadPrintGomb: TBitBtn;
    VisszaGomb    : TBitBtn;

    Label5        : TLabel;
    Label6        : TLabel;
    Label7        : TLabel;
    Label8        : TLabel;
    Label9        : TLabel;

    Shape1        : TShape;
    Shape2        : TShape;

    TakaroPanel   : TPanel;

    KilepoTimer   : TTimer;

    procedure DekadNyomtatas;
    procedure DekadPrintGombClick(Sender: TObject);
    procedure Dekadszamitas;
    procedure Doskozep(_txt: string);
    procedure EvComboChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure KilepoTimerTimer(Sender: TObject);
    procedure LastsorszamRogzito;
    procedure NaploBejegyzes;
    procedure NaploParancs(_ukaz: string);
    procedure PenztarAdatBeolvaso;
    procedure ValutaParancs(_ukaz: string);
    procedure VonalHuzas;
    procedure VisszaGombClick(Sender: TObject);

    function Form11(_int: integer): string;
    function GetdekadNyito: integer;
    function GetKezdoSorszam: integer;
    function Nulele(_n: byte): string;
    function NulKieg(_i,_hh: integer): string;
    function PtarKepzo(_pts: string): string;

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  KezdDekad: TKezdDekad;

  _dekadPath : string = 'c:\valuta\aktlst.txt';
  _honev: array[1..12] of string  = ('január','február','március','április','május',
                  'junius','július','augusztus','szeptember','október','november',
                  'december');

  _sorveg : string = chr(13)+chr(10);
  _kotojel: string = '    -      ';
  _adatsor: array[0..25] of string;

  _textiras,
  _textolvas,
  _nyomtat: textfile;

  _storno: byte;

  _aktdekad,
  _feszkoz,
  _printer,
  _ssindex,
  _kertdekad: byte;

  _aktev,
  _aktho,
  _aktnap,
  _eloev,
  _eloho,
  _height,
  _kertev,
  _kertho,
  _houtolsonap,
  _width:word;

  _aktkezelesidij,
  _aktsorszam,
  _bankkartyas,
  _code,
  _kezdosorszam,
  _kezelesidij,
  _lastsorszam,
  _nyito,
  _osszbevetel,
  _osszeg,
  _osszesen,
  _osszkezdij,
  _osszkiadas,
  _gepfunkcio,
  _recno,
  _zaro: integer;

  _aktadatsor,
  _aktdatums,
  _aktdekadstart,
  _aktdekadend,
  _bfFilenev,
  _bizonylat,
  _datum,
  _datstring,
  _dekadeleje,
  _elofarok,
  _elojel,
  _farok,
  _hzfilenev,
  _istring,
  _kertdekadstart,
  _kertdekadend,
  _kertelostart,
  _kerteloend,
  _kezdfilenev,
  _mondat,
  _penztarkod,
  _penztarnev,
  _penztarcim,
  _megnyitottnap,
  _lezartnap,
  _mamas,
  _penztar,
  _pcs,
  _sortext,
  _ss,
  _tipus: string;


  function kezelesidijdekad: integer; stdcall;
  function supervisorjelszo(_para: integer): integer;stdcall; external 'c:\valuta\bin\super.dll' name 'supervisorjelszo';

implementation

{$R *.dfm}


// =============================================================================
              function kezelesidijdekad: integer; stdcall;
// =============================================================================

begin
  KezdDekad := TKezdDekad.Create(Nil);
  result    := KezdDekad.ShowModal;
  KezdDekad.free;
end;


// =============================================================================
                procedure TKezdDekad.FormActivate(Sender: TObject);
// =============================================================================

var _y: integer;

Begin

  Takaropanel.Visible := false;

  _height := screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].width;

  top     := trunc((_height-400)/2);
  left    := trunc((_width-700)/2);

  // Alapadatok beállítása:

  PenztaradatBeolvaso;

  if _gepfunkcio=2 then
    begin
      ShowMessage('Csak péntári gépen futtatható');
      KilepoTimer.Enabled := true;
      exit;
    end;

  _aktev     := yearof(date);
  _aktho     := monthof(date);
  _aktnap    := dayof(date);

  _aktdatums := inttostr(_aktev)+'.'+nulele(_aktho)+'.'+nulele(_aktnap);

  _aktdekad  := 3;

  if _aktnap<11 then _aktdekad := 1 ELSE
  if _aktnap<21 then _aktdekad := 2;

  EvCombo.Items.clear;
  EvCombo.Items.Add(inttostr(_aktev-1));
  EvCombo.Items.Add(inttostr(_aktev));
  EvCombo.ItemIndex := 1;

  HoCombo.Items.Clear;

  _y := 1;
  while _y<=12 do
    begin
      HoCombo.Items.Add(_honev[_y]);
      inc(_y);
    end;

  HoCombo.ItemIndex := (_aktho-1);

  DekadCombo.Items.clear;
  _y := 1;
  while _y<=3 do
    begin
      DekadCombo.Items.Add(inttostr(_y)+'. DEKÁD');
      inc(_y);
    end;

  DekadCombo.itemIndex := _aktDekad-1;
  Repaint;
  ActiveControl := DekadPrintGomb;
end;


// =============================================================================
          procedure TKezdDekad.DekadPrintGombClick(Sender: TObject);
// =============================================================================

// A kért dekád nyomtatási idöszakának beállítása után ide kattint:

var _spk: integer;

begin

  DekadPrintGomb.Enabled := False;
  VisszaGomb.Enabled     := False;

  _kertEv := _aktEv-1 + EvCombo.ItemIndex;
  _kertHo := 1 + HoCombo.itemindex;

  _kertDekad   := 1 + DekadCombo.itemindex;
  _hoUtolsoNap := daysInAMonth(_kertEv,_kertHo);

  _dekadEleje := inttostr(_kertev)+'.'+nulele(_kertho)+'.';

  if _kertDekad=1 then
    begin
      _kertDekadStart := _dekadEleje + '01';
      _kertDekadEnd   := _dekadEleje + '10';
    end;

  if _kertDekad=2 then
    begin
      _kertDekadStart := _dekadEleje + '11';
      _kertDekadEnd   := _dekadEleje + '20';
    end;

  if _kertDekad=3 then
    begin
      _kertDekadStart := _dekadEleje + '21';
      _kertDekadEnd   := _dekadEleje + nulele(_hoUtolsoNap);
    end;

  // ------------------- DEKÁD KÉRÉS KIÉRTÉKELÉSE ------------------------------

  if _kertDekadStart>_aktDatums then
    begin
      ShowMessage('A KÉRT DEKÁD A JÖVÕBEN LESZ !');
       KilepoTimer.Enabled := True;
       exit;
    end;

  if _kertDekadEnd>_aktDatums then
    begin
      if _lezartNap='' then
         begin
           _pcs := 'SELECT * FROM BLOKKFEJ';
           ValutaDbase.Connected := true;
           with ValutaQuery do
             begin
               Close;
               Sql.Clear;
               Sql.Add(_pcs);
               Open;
               _recno := recno;
               Close;
             end;
           ValutaDbase.close;

           if _recno>0 then
             begin
               ShowMessage('NINCS LEZÁRVA A MAI NAP');
               ModalResult := 2;
               exit;
             end;
         end;
      DekadNyomtatas;
      exit;
    end;

  if _kertDekadEnd<_aktDatums then
    begin
      _spk := supervisorjelszo(0);
      if _spk<>1 then
         begin
           ModalResult := 2;
           exit;
         end;
    end;
  DekadNyomtatas;
end;


// =============================================================================
              procedure TKezdDekad.Dekadnyomtatas;
// =============================================================================

var _y: byte;

begin

  _farok := midstr(_kertdekadstart,3,2)+midstr(_kertdekadstart,6,2);

  with TakaroPanel do
    begin
      Top := 272;
      Left := 24;
      Visible := true;
      Repaint;
    end;

  Dekadszamitas;

 // ---------------------------------------------------------------------------

  AssignFile(_textIras,_dekadPath);
  Rewrite(_textIras);

  DosKozep(_penztarKod+'. PENZTAR');
  DosKozep(_penztarNev);
  DosKozep(_penztarCim);

  VonalHuzas;

  _datString := inttostr(_kertEv)+' '+ uppercase(_honev[_kertHo])+' HAVI ';
  _datString := _datString + chr(48+_kertDekad)+'. DEKAD KEZ-I DIJAK';
  DosKozep(_datString);

  _iString := _kertDekadstart + ' - ' + _kertdekadEnd;
  Doskozep(_iString);

  VonalHuzas;

  WriteLn(_textiras,' Sors Np Bizony.  Ft.atvetel   Ft.atadas');
  VonalHuzas;

  _y := 0;
  while _y<_ssindex do
    begin
      _aktadatsor := _adatsor[_y];
       writeLn(_textIras,_aktadatsor);
       inc(_Y);
     end;

   _sorText := nulKieg(_kezdoSorszam+_ssindex,5)+' Kezelesidij'+ Form11(_osszkezdij);
   _sortext := _sortext + ' ' +_kotojel;
   writeLn(_textIras,_sorText);

   if _bankkartyas>0 then
     begin
       inc(_ssindex);
       _sortext := nulkieg(_kezdosorszam+_ssindex,5)+' Bankkartyas'+Form11(_bankkartyas);
       _sortext := _sortext + ' ' + _kotojel;
       writeLn(_textiras,_sortext);
     end;

    _lastsorszam := _kezdosorszam+_ssIndex;

    VonalHuzas;

   // --------------------------------------------------------------------------

   _osszbevetel := _osszbevetel + _osszkezdij;
   _zaro := _nyito + _osszbevetel - _osszkiadas;

   _sorText := 'Dekad forgalom:  ' + Form11(_osszBevetel)+' '+ Form11(_osszKiadas);
   writeLn(_textIras,_sorText);

   _sorText := '  Nyito forint:  ' + Form11(_nyito) + ' ###########';
   writeLn(_textIras,_sorText);

   _sorText := '   Zaro forint:  ########### ' + form11(_zaro);
   writeLn(_textIras,_sorText);

   _osszesen := _osszBevetel + _nyito;

   _sorText := ' Osszes forint:  ' + form11(_osszesen)+' '+ form11(_osszesen);
   writeLn(_textIras,_sorText);

   VonalHuzas;

   writeLn(_textIras,_sorVeg);

   _sorText := _aktdatums + '     ' + dupestring('.',24);
   writeLn(_textIras,_sorText);

   _sorText := dupestring(chr(32),25)+ 'penztaros';
   writeLn(_textIras,_sorText);
   writeLn(_textIras,_sorVeg+_sorVeg+_sorVeg+chr(26));
   closefile(_textIras);

   // ------------------------------------------------------

   if _printer<>1 then AssignFile(_nyomtat,'LPT1')
   else assignprn(_nyomtat);

   Rewrite(_nyomtat);

   AssignFile(_textOlvas,'c:\valuta\aktlst.txt');
   Reset(_textOlvas);

   while not eof(_textOlvas) do
     begin
       readLn(_textOlvas,_mondat);
       writeLn(_nyomtat,_mondat);
     end;

   System.CloseFile(_nyomtat);
   System.CloseFile(_textOlvas);

   // -------------------------------------------

   LastsorszamRogzito;
   NaploBejegyzes;
   Modalresult := 1;
end;

// =============================================================================
                   procedure TKezdDekad.DekadSzamitas;
// =============================================================================

begin
  _kezdosorszam := GetkezdoSorszam;
  _nyito := GetdekadNyito;
  _osszkezdij := 0;
  _osszbevetel := 0;
  _osszkiadas := 0;

  _bfFileNev := 'BF' + _farok;

  _pcs := 'SELECT * FROM ' + _bfFileNev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>=' + chr(39) + _kertdekadstart + chr(39) + ')';
  _pcs := _pcs + ' AND (DATUM<=' + CHR(39) + _kertdekadEnd + chr(39) + ')';
  _pcs := _pcs + ' AND (STORNO=1) AND ((TIPUS='+CHR(39)+'V' + chr(39) + ')';
  _pcs := _pcs + ' OR (TIPUS=' +chr(39)+ 'E' + chr(39) + '))';

  ValdataDbase.Connected := true;
  with ValdataQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  while not ValDataQuery.Eof do
    begin
      with ValDataQuery do
        begin
          _kezelesidij := FieldByName('KEZELESIDIJ').asInteger;
          _feszkoz     := FieldByNAme('FIZETOESZKOZ').asInteger;
          _tipus       := FieldByName('TIPUS').asString;
        end;

      if _feszkoz=2 then _bankkartyas := _bankkartyas + abs(_kezelesidij)
      else _osszkezdij := _osszkezdij + abs(_kezelesidij);

      ValdataQuery.next;
    end;

  ValdataQuery.close;
  ValdataDbase.close;

  // --------------------------------------------------------------------------

  _kezdFileNev := 'KEZD' + _farok;

  _pcs := 'SELECT * FROM ' + _kezdFileNev + _sorveg;
  _pcs := _pcs + 'WHERE (DATUM>=' + chr(39) + _kertdekadstart + chr(39) + ')';
  _pcs := _pcs + ' AND (DATUM<=' + CHR(39) + _kertDekadEnd + chr(39) + ')';

  ValDataDbase.Connected := True;
  with ValDataQuery do
    begin
      Close;
      Sql.clear;
      Sql.Add(_pcs);
      Open;
      First;
    end;

  _ssindex := 0;
  while not ValDataQuery.Eof do
    begin
      with ValDataQuery do
        begin
          _elojel    := FieldByNAme('ELOJEL').asString;
          _osszeg    := FieldByName('KEZELESIDIJ').asInteger;
          _datum     := FieldByName('DATUM').asString;
          _penztar   := FieldByName('PENZTAR').asString;
          _bizonylat := FieldByName('BIZONYLAT').asstring;
          _storno    := FieldByNAme('STORNO').asInteger;
        end;

      _bizonylat := leftstr(_bizonylat,1)+midstr(_bizonylat,3,6);
      _sorText   := nulKieg(_kezdoSorszam+_ssindex,5)+' '+midstr(_datum,9,2) + ' ' + _bizonylat + ' ';

      if _storno<>1 then _osszeg := 0;

      if _elojel = '+' then
         begin
           _osszbevetel := _osszbevetel + _osszeg;
           if _storno<>1 then _ss := '   storno bizonylat'
           else _ss := Form11(_osszeg)+ ' ' + ptarKepzo(_Penztar);
         end else
         begin
           _osszkiadas := _osszkiadas + _osszeg;
           if _storno<>1 then _ss := '   storno bizonylat'
           else _ss := PtarKepzo(_Penztar) + ' ' + Form11(_osszeg);
         end;

      _sorText := _sorText + _ss;
      _adatsor[_ssindex] := _sorText;

       inc(_ssIndex);
       ValdataQuery.Next;
     end;

   ValdataQuery.close;
   ValdataDbase.close;
end;

// =============================================================================
                 function TKezdDekad.GetDekadnyito: integer;
// =============================================================================

var _nyss: string;

begin
  _pcs := 'SELECT * FROM NAPIKEZELESIDIJ' + _sorveg;
  _pcs := _pcs + 'WHERE DATUM<'+chr(39)+_kertdekadstart+chr(39)+ _sorveg;
  _pcs := _pcs + 'ORDER BY DATUM';

  Valutadbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.add(_pcs);
      Open;
      Last;
      _recno := recno;
    end;

  if _recno>0 then
    begin
      result := ValutaQuery.FieldByName('ZARO').asInteger;
      ValutaQuery.Close;
      ValutaDbase.close;
      exit;
    end;

  ValutaQuery.close;
  Valutadbase.close;

  _nyss := inputbox('DEKÁD NYITÓ','Kérem a dekád nyitó összegét: ','0');
  val(_nyss,result,_code);
  if _code<>0 then result := 0;
end;


// =============================================================================
                  function TKEZDDEKAD.Nulele(_n: byte): string;
// =============================================================================


begin
  result := inttostr(_n);
  if _n<10 then result := '0' + result;
end;

// =============================================================================
              function TKEZDDEKAD.NulKieg(_i,_hh: integer): string;
// =============================================================================

var _s: string;

begin
  _s := inttostr(_i);
  _s := trim(_s);
  while length(_s)<_hh do _s := '0' + _s;
  result := _s;
end;

// =============================================================================
          function TKEZDDEKAD.PtarKepzo(_pts: string): string;
// =============================================================================

begin
  result := '   ('+trim(_pts)+')';
  while length(result)<11 do result := result + ' ';
end;

// =============================================================================
             function TKezdDekad.Form11(_int: integer): string;
// =============================================================================

var _res: string;
    _wRes,_p1: integer;

begin

  Result := _kotojel;
  if _int=0 then exit;

  _res  := inttostr(_int);
  _wRes := length(_res);

  if _wres>6 then
    begin
      _p1 := _wRes-6;
      _res := leftstr(_res,_p1)+'.'+midstr(_res,_p1+1,3)+'.'+midstr(_res,_p1+4,3);
    end else
    begin
      if _wRes>3 then
        begin
          _p1 := _wRes-3;
          _res := leftstr(_res,_p1)+'.'+midstr(_res,_p1+1,3);
        end;
    end;
  while length(_res)<11 do _res := ' ' + _res;
  result := _res;
end;

// =============================================================================
                 procedure TKezdDekad.Doskozep(_txt: string);
// =============================================================================

var _ww,_oo: integer;

begin
  _txt := trim(_txt);
  _ww  := length(_txt);

  if _ww=0 then exit;

  _oo  := trunc((40-_ww)/2);
  _txt := dupestring(chr(32),_oo)+_txt;

  writeLn(_textiras,_txt);
end;

// =============================================================================
                        procedure TKezdDekad.VonalHuzas;
// =============================================================================

var _stext: string;

begin
  _stext := Dupestring('-',40);
  writeLn(_textiras,_stext);
end;


// =============================================================================
            procedure TKezdDekad.KilepoTimerTimer(Sender: TObject);
// =============================================================================

begin
  KilepoTimer.Enabled := false;
  Modalresult := 2;
end;

// =============================================================================
            procedure TKezdDekad.EvComboChange(Sender: TObject);
// =============================================================================

begin
  ActiveControl := DekadPrintGomb;
end;

// =============================================================================
           procedure TKezdDekad.VisszaGombClick(Sender: TObject);
// =============================================================================

begin
  Modalresult := 2;
end;


// =============================================================================
               function TKezdDekad.GetKezdoSorszam: integer;
// =============================================================================

var _kss: string;
    _ekertev,_ekertho,_ekertdekad: word;

begin
  if (_kertho=1) and (_kertdekad=1) then
     begin
       result := 1;
       exit;
     end;  

  _ekertev    := _kertev;
  _ekertho    := _kertho;
  _ekertdekad := _kertdekad-1;

  if _ekertdekad<1 then
    begin
      dec(_ekertho);
      if _ekertho<1 then
        begin
          _ekertHo := 12;
          dec(_ekertev);
        end;
      _ekertdekad := 3;  
    end;

  _pcs := 'SELECT * FROM KEZDIJSORSZAM WHERE (EV='+inttostr(_ekertev)+')';
  _pcs := _pcs + ' AND (HONAP='+inttostr(_ekertho)+')';
  _pcs := _pcs + ' AND (DEKAD='+inttostr(_ekertdekad)+')';

  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  if _recno>0 then
    begin
      result := ValutaQuery.FieldByName('UTOLSOSORSZAM').asInteger;
      result := result + 1;
      ValutaQuery.Close;
      ValutaDbase.Close;
      exit;
    end;

  ValutaQuery.close;
  ValutaDbase.Close;

  _kss := inputbox('KEZDÕSORSZÁM','Kérem a kezdõsorszámot: ','0');
  val(_kss,result,_code);
  if _code<>0 then result := 0;

end;

// =============================================================================
                    procedure TKezdDekad.LastsorszamRogzito;
// =============================================================================

begin
  _pcs := 'DELETE FROM KEZDIJSORSZAM' + _sorveg;
  _pcs := _pcs + 'WHERE (EV=' + inttostr(_kertev)+') AND ';
  _pcs := _pcs + '(HONAP='+inttostr(_kertho)+') AND ';
  _pcs := _pcs + '(DEKAD=' + inttostr(_kertdekad)+')';
  ValutaParancs(_pcs);

  _pcs := 'INSERT INTO KEZDIJSORSZAM (EV,HONAP,DEKAD,UTOLSOSORSZAM)'+_sorveg;
  _pcs := _pcs + 'VALUES (' + inttostr(_kertev) + ',';
  _pcs := _pcs + inttostr(_kertho) + ',';
  _pcs := _pcs + inttostr(_kertdekad) + ',';
  _pcs := _pcs + inttostr(_lastsorszam) + ')';
  ValutaParancs(_pcs);
end;

// =============================================================================
                procedure TKezdDekad.PenztarAdatBeolvaso;
// =============================================================================

begin
  ValutaDbase.Connected := true;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add('SELECT * FROM PENZTAR');
      Open;
      First;
      _penztarkod := trim(FieldByName('PENZTARKOD').AsString);
      _penztarnev := trim(FieldByName('PENZTARNEV').AsString);
      _penztarcim := trim(FieldByName('PENZTARCIM').AsString);
      close;
    end;

  with ValutaQuery do
    begin
      Close;
      sql.clear;
      Sql.Add('SELECT * FROM HARDWARE');
      Open;

      _gepfunkcio := FieldByNAme('GEPFUNKCIO').AsInteger;
      _printer    := FieldByName('PRINTER').asInteger;
      _lezartnap  := trim(Fieldbyname('LEZARTNAP').asstring);
      close;
    end;

  ValutaDbase.close;
end;

// =============================================================================
                    procedure TKezdDekad.NaploBejegyzes;
// =============================================================================

var _datumdekad: string;
    _dk: byte;

begin
  _datumdekad := inttostr(_kertev)+nulele(_kertho)+nulele(_kertdekad);

  _pcs := 'SELECT * FROM PRINTCONTROL' + _sorveg;
  _pcs := _pcs + 'WHERE DATUMDEKAD=' + chr(39)+_datumdekad+chr(39);

  NaploDbase.Connected := true;
  with NaploQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_pcs);
      Open;
      _recno := recno;
    end;

  _dk := 0;
  if _recno>0 then _dk := NaploQuery.FieldByName('DEKADPRINT').asInteger;

  NaploQuery.Close;
  NaploDbase.Close;

  _pcs := 'DELETE FROM PRINTCONTROL' + _sorveg;
  _pcs := _pcs + 'WHERE DATUMDEKAD=' + chr(39) + _datumdekad + chr(39);
  NaploParancs(_pcs);

  _pcs := 'INSERT INTO PRINTCONTROL (KEZDIJPRINT,DEKADPRINT,DATUMDEKAD)' + _sorveg;
  _pcs := _pcs + 'VALUES (1,' + inttostr(_dk)+',';
  _pcs := _pcs + chr(39)+_datumdekad + chr(39)+')';
  NaploParancs(_pcs);
end;

// =============================================================================
            procedure TKezdDekad.ValutaParancs(_ukaz: string);
// =============================================================================

begin
  ValutaDbase.connected := true;
  if ValutaTranz.InTransaction then valutaTranz.commit;
  ValutaTranz.StartTransaction;
  with ValutaQuery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      Execsql;
    end;
  ValutaTranz.commit;
  ValutaDbase.close;

end;

// =============================================================================
             procedure TKezdDekad.NaploParancs(_ukaz: string);
// =============================================================================

begin
  NaploDbase.Connected := true;
  if NaploTranz.InTransaction then NaploTranz.commit;
  NaploTranz.StartTransaction;
  with Naploquery do
    begin
      Close;
      Sql.Clear;
      Sql.Add(_ukaz);
      Execsql;
    end;
  NaploTranz.commit;
  NaploDbase.close;
end;
end.
