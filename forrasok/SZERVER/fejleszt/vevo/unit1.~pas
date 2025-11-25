unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, ExtCtrls, StdCtrls, Buttons, IBDatabase, DB,strUtils,
  IBCustomDataSet, IBQuery, IBTable,dateUtils;

type
  TForm1 = class(TForm)
    TOLNAPTAR: TMonthCalendar;
    IGNAPTAR: TMonthCalendar;
    Label1: TLabel;
    Shape1: TShape;
    Shape2: TShape;
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
    IBQUERY: TIBQuery;
    IBDBASE: TIBDatabase;
    IBTRANZ: TIBTransaction;
    IBTABLA: TIBTable;
    REKORDCSIK: TProgressBar;
    Shape15: TShape;
    TOLLABEL: TPanel;
    IGLABEL: TPanel;

    procedure PenztarBeolvasas;
    procedure PenztartValasztott;
    procedure STARTGOMBClick(Sender: TObject);
    procedure MINFORINTEnter(Sender: TObject);
    procedure MINFORINTExit(Sender: TObject);
    procedure ESCAPEGOMBClick(Sender: TObject);
    procedure DatumDisplay;
    procedure VevoLepteto;
    function LFormat(_ft: integer): string;
    procedure TOLNAPTARClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    function Vesszokivono(_nfts: string): string;
    function Forintform(_ft: integer): string;
    procedure MINFORINTKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MAXFORINTKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    function Nulele(_b: byte): string;
    function WideDatum(_ds: string): string;
    procedure Allgombclear;
    procedure AllgombDisable;
    procedure AllgombEnable;
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure mindengombMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure KFTGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure KORZETGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PENZTARGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure mindengombClick(Sender: TObject);
    procedure KFTGOMBClick(Sender: TObject);
    procedure KORZETGOMBClick(Sender: TObject);
    procedure PENZTARGOMBClick(Sender: TObject);
    function Scanetar(_kz: byte): byte;
    procedure ChooseKft;
    procedure ChooseKorzet;
    procedure ChoosePenztar;
    function Nul3(_nn: byte): string;
    procedure k1gombClick(Sender: TObject);
    procedure BGOMBClick(Sender: TObject);
    procedure PENZTARLISTADblClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure UJSZAMOLASGOMBClick(Sender: TObject);
    procedure PENZTARLISTAKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
   

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
  _penztarnev,_ptstatus,_ptkft: array[1..150] of string;
  _ptTerulet: array[1..150] of byte;
  _tolev,_tolho,_igev,_igho,_aktev,_aktho: word;
  _pt,_filtertipus,_kft,_korzet,_penztar,_korzetss,_kftss,_penztardarab: byte;
  _aktpt,_kellkorzet,_kellpenztar: byte;

  _honev: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
             'MÁJUS','JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                                'NOVEMBER','DECEMBER');


  _kftnev: array[1..3] of string = ('BEST','EAST','PANNON');
  _korzetnev: array[1..8] of string = ('SZEKSZÁRD','SZEGED','KECSKEMÉT',
                   'DEBRECEN','NYÍREGYHÁZA','BÉKÉSCSABA','PÉCS','KAPOSVÁR');

  _korzetszam: array[1..8] of byte = (10,20,40,50,63,75,120,145);

  _ptnevsor: array[1..150] of string;
  _ptnumsor: array[1..150] of byte;


  _allgombclosed,_nolimit: boolean;

implementation

{$R *.dfm}


// =============================================================================
                    procedure TForm1.FormActivate(Sender: TObject);
// =============================================================================

var i: byte;

begin
  PenztarChoosePanel.Visible := false;
  KorzetChoosePanel.Visible  := False;
  KftChoosePanel.Visible     := False;

  for i := 1 to 150 do _penztarnev[i] := '?';
  _mamas := datetostr(date);
  Datumdisplay;
  Minforint.clear;
  MaxForint.clear;
  _minforint := 0;
  _maxforint := 0;
  _vevoszam := 0;
  _filtertipus := 0;
  Ujszamolasgomb.Visible := False;
  _allgombclosed := False;
  PenztarBeolvasas;
  Activecontrol := Minforint;
end;

// =============================================================================
                           procedure TForm1.Datumdisplay;
// =============================================================================

begin
  _toldatum := Tolnaptar.Date;
  _igDatum := IgNaptar.Date;

  _tols := datetostr(_toldatum);
  _igs  := datetostr(_igdatum);

  Tollabel.Caption := _tols+'-TÓL';
  IgLabel.Caption  := _igs+'-IG';

  Tollabel.Repaint;
  IgLabel.Repaint;
end;


// =============================================================================
           procedure TForm1.MINFORINTEnter(Sender: TObject);
// =============================================================================

begin
  TEDIT(Sender).Color := clYellow;
end;

// =============================================================================
             procedure TForm1.MINFORINTExit(Sender: TObject);
// =============================================================================

begin
  Tedit(sender).Color := clWhite;
end;

// =============================================================================
       procedure TForm1.MINFORINTKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================

begin
  if ord(key)<>13 then exit;

  _mins := Vesszokivono(MINFORINT.Text);
  val(_mins,_minforint,_code);
  if _code<>0 then _minforint := 0;

  Minforint.Text := Lformat(_minForint);
  Activecontrol := MAxforint;
end;


// =============================================================================
       procedure TForm1.MAXFORINTKeyDown(Sender: TObject; var Key: Word;
                                                           Shift: TShiftState);
// =============================================================================


begin
  if ord(Key)<>13 then exit;

  _maxs := VesszoKivono(MAXFORINT.Text);
  val(_maxs,_maxforint,_code);
  if _code<>0 then _maxforint := 0;

  if (_maxforint<_minforint) and (_maxforint>0) then
    begin
      Maxforint.Clear;
      Activecontrol := MaxForint;
      exit;
    end;

  Maxforint.Text := LFormat(_maxForint);
  Activecontrol := Startgomb;
end;


// =============================================================================
              function TForm1.LFormat(_ft: integer): string;
// =============================================================================

begin
  if _ft=0 then
    begin
       result := 'nincs';
       exit;
     end;
  result := Forintform(_ft);
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
              procedure TForm1.STARTGOMBClick(Sender: TObject);
// =============================================================================

begin
  StartGomb.Enabled := false;
  DatumDisplay;
  if _toldatum>_igdatum then
    begin
      ShowMessage('A KEZDÕ-DÁTUM NAGYOBB AZ UTOLSÓ DÁTUMNÁL !');
      Exit;
    end;

  if _tols<'2014.01.01' then
    begin
      ShowMessage('A KEZDÕNAP MINIMUMA 2014.01.01 LEHET !');
      exit;
    end;

  if _igs>=_mamas then
    begin
      ShowMessage('AZ UTOLSÓ NAP MAXIMUMA A TEGNAPI NAP !');
      exit;
    end;

  // ---------------------------------------------------

  _mins := vesszokivono(MINFORINT.text);
  val(_mins,_minforint,_code);
  if _code<>0 then _minforint := 0;

  _maxs := vesszokivono(MAXFORINT.Text);
  val(_maxs,_maxforint,_code);
  if _code<>0 then _maxforint := 0;

  if (_maxforint<_minforint) and (_maxforint>0) then
    begin
      Showmessage('HIBÁS ÖSSZEGHATÁROK !');
      ActiveControl := MaxForint;
      Exit;
    end;

  _noLimit := False;

  if (_maxforint=0) then
    begin
      if _minforint=0 then _noLimit := True else _maxforint := 500000000;
    end;

  _elsofarok := midstr(_tols,3,2)+midstr(_tols,6,2);
  _lastfarok := midstr(_igs,3,2)+midstr(_igs,6,2);

  _tolev := yearof(_toldatum);
  _tolho := monthof(_toldatum);

  _igev := yearof(_igdatum);
  _igho := monthof(_igdatum);

  // ---------------------------------------------------------------------------

   _pt := 1;
   Penztarcsik.Max := 150;
   while _pt<=150 do
     begin
       Penztarcsik.Position := _pt;
       _aktstatus := _ptstatus[_pt];
       _aktceg    := _ptkft[_pt];
       _aktkorzet := _ptterulet[_pt];

       if _aktstatus<>'P' then
         begin
           inc(_pt);
           Continue;
         end;

       if _filtertipus=1 then
         begin
           if _aktceg<>_kftBetu then
             begin
               inc(_pt);
               Continue;
             end;
         end;

       if _filtertipus=2 then
         begin
           if _kellkorzet<>_aktkorzet then
             begin
               inc(_pt);
               Continue;
             end;
         end;

       if _filtertipus=3 then
         begin
           if _kellPenztar<>_pt then
             begin
               inc(_pt);
               Continue;
             end;
         end;      

       _fdbPath := 'c:\receptor\database\v' + inttostr(_pt)+'.fdb';
       if not FileExists(_fdbPath) then
         begin
           inc(_pt);
           continue;
         end;

       PenztarPanel.Caption := inttostr(_pt)+'. '+_penztarnev[_pt];
       PenztarPanel.Repaint;

       ibdbase.close;
       ibdbase.DatabaseName := _fdbpath;

       // -----------------------------------------------------------------

       _aktev    := _tolev;
       _aktho    := _tolho;
       _aktfarok := _elsofarok;
       while _aktfarok<=_lastfarok do
         begin
           _bf := 'BF' + _aktfarok;
           _bt := 'BT' + _aktfarok;

           ibdbase.Connected := True;
           ibtabla.close;
           ibtabla.TableName := _bf;
           if not ibtabla.Exists then
             begin
               ibdbase.close;
               inc(_aktho);
               if _aktho>12 then
                 begin
                   _aktho := 1;
                   inc(_aktev);
                 end;
               _aktfarok := inttostr(_aktev-2000)+nulele(_aktho);
               COntinue;
             end;

           _pcs := 'SELECT * FROM ' + _BF + _sorveg;
           _pcs := _pcs + 'WHERE (DATUM>='+chr(39)+_tols+chr(39)+')';
           _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igs+chr(39)+')';
           _pcs := _pcs + ' AND (STORNO=1) AND ((TIPUS='+chr(39)+'V'+chr(39)+')';
           _pcs := _pcs + ' OR (TIPUS='+chr(39)+'E'+chr(39)+')';

           if _nolimit then _pcs := _pcs + ' OR (TIPUS='+CHR(39)+'K'+chr(39)+')';
           _pcs := _pcs + ')';

           with IbQuery do
             begin
               Close;
               sql.clear;
               sql.Add(_pcs);
               Open;
               Last;
               _recno := recno;
               First;
             end;

           if _recno>0 then
             begin
               RekordCsik.Max := _recno;
               _cc := 0;

               while not IbQuery.Eof do
                 begin
                   inc(_cc);
                   Rekordcsik.Position := _cc;

                   _datum  := ibQuery.FieldByName('DATUM').asstring;
                   _tipus  := ibquery.FieldByName('TIPUS').asString;

                   datumpanel.Caption := widedatum(_datum);
                   datumpanel.Repaint;
                   if _nolimit then Vevolepteto
                   else
                   begin
                     _brutto := ibQuery.FieldByname('OSSZESEN').asInteger;
                     if (_brutto>=_minforint) and (_brutto<=_maxforint) then VevoLepteto;
                   end;
                   if _tipus='K' then VevoLepteto;
                   ibquery.Next;
                 end;
               ibquery.close;
             end;

           if not _nolimit then
             begin
               _pcs := 'SELECT * FROM ' + _BT + _sorveg;
               _pcs := _pcs + 'WHERE (DATUM>='+chr(39)+_tols+chr(39)+')';
               _pcs := _pcs + ' AND (DATUM<='+chr(39)+_igs+chr(39)+')';
               _pcs := _pcs + ' AND (STORNO=1) AND (BIZONYLATSZAM LIKE ';
               _pcs := _pcs + chr(39) + 'K%' + CHR(39) + ')';
               _pcs := _pcs + ' AND (ELOJEL='+chr(39)+'+'+chr(39)+')';

               with ibquery do
                 begin
                   Close;
                   sql.clear;
                   sql.add(_pcs);
                   Open;
                   _recno := recno;
                 end;

               if _recno>0 then
                 begin
                   _utbs := 'x';
                   _aktFt := 0;
                   _utbs := Ibquery.FieldbyName('BIZONYLATSZAM').asString;
                   while not ibQuery.Eof do
                     begin
                       _aktbs := Ibquery.FieldbyName('BIZONYLATSZAM').asString;
                       _ftert := ibquery.FieldbyName('FORINTERTEK').asInteger;
                       if _utbs=_aktbs then
                         begin
                           _aktft := _aktft + _ftert;
                         end else
                         begin
                           if (_aktft>=_minforint) and (_aktft<=_maxforint) then
                             begin
                               VevoLepteto;
                               VevoLepteto;
                             end;
                           _aktft := 0;
                           _utbs := _aktbs;
                         end;
                       ibquery.Next;
                     end;
                     
                   if (_aktft>=_minforint) and (_aktft<=_maxforint) then
                     begin
                       VevoLepteto;
                       VevoLepteto;
                     end;
                 end;

               ibquery.close;
               ibdbase.close;
             end;

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
   VevoShape.Brush.Color := clRed;
   VevoPanel.Font.Color := clWhite;
   Vevopanel.Color := clRed;

   UjszamolasGomb.Visible := true;

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
                       procedure TForm1.PenztarBeolvasas;
// =============================================================================

var _aktpt,i: byte;
    _aktptn: string;

begin
  for i := 1 to 150 do
    begin
      _ptstatus[i]  := '0';
      _ptTerulet[i] := 0;
      _ptkft[i]     := '0';
    end;

  _fdbPath := 'c:\receptor\database\receptor.fdb';
  ibdbase.close;
  ibdbase.DatabaseName := _FdbPath;
  ibdbase.Connected := true;
  _pcs := 'SELECT * FROM IRODAK';

  with ibquery do
    begin
      close;
      sql.clear;
      sql.add(_pcs);
      Open;
      First;
    end;

  _cc := 0;
  while not ibquery.Eof do
    begin
      _status := ibquery.FieldByName('STATUS').asString;
      _cegbetu:= ibquery.FieldByName('CEGBETU').asString;
      _ertektar := ibquery.FieldByname('ERTEKTAR').asInteger;
      _aktpt  := ibquery.FieldByName('UZLET').asInteger;

      _aktptn := trim(ibquery.FieldByName('KESZLETNEV').asString);
      if _status='P' then
        begin
           inc(_cc);
          _penztarnev[_aktpt] := _aktptn;
          _ptnumsor[_cc]      := _aktpt;
          _ptnevsor[_cc]      := _aktptn;
        end;

      _ptstatus[_aktpt] := _status;
      _ptterulet[_aktpt]:= _ertektar;
      _ptKft[_aktpt] := _cegbetu;
      ibquery.next;
    end;
  ibquery.close;
  ibdbase.close;
  _penztardarab := _cc;
end;

function Tform1.Scanetar(_kz: byte): byte;

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
                           procedure TForm1.VevoLepteto;
// =============================================================================

begin
  inc(_vevoszam);
  VevoPanel.caption := Forintform(_vevoszam)+ ' FÕ';
  VevoPanel.repaint;
end;  

procedure TForm1.Allgombclear;

begin
  if _allgombclosed then exit;
  Mindengomb.Color := clWhite;
  kftgomb.Color := clwhite;
  Korzetgomb.Color := clWhite;
  Penztargomb.Color := clWhite;
end;


procedure TForm1.AllgombDisable;

begin
  Mindengomb.enabled := false;
  kftgomb.enabled := false;
  Korzetgomb.enabled := false;
  Penztargomb.enabled := false;
end;


procedure TForm1.AllgombEnable;

begin
  Mindengomb.enabled  := True;
  kftgomb.enabled     := True;
  Korzetgomb.enabled  := True;
  Penztargomb.enabled := True;
end;




procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  Allgombclear;
end;

procedure TForm1.mindengombMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  Allgombclear;
  Mindengomb.Color := clYellow;
end;

procedure TForm1.KFTGOMBMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  Allgombclear;
  Kftgomb.Color := clYellow;
end;

procedure TForm1.KORZETGOMBMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  Allgombclear;
  Korzetgomb.Color := clYellow;
end;

procedure TForm1.PENZTARGOMBMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  Allgombclear;
  Penztargomb.Color := clYellow;
end;

procedure TForm1.mindengombClick(Sender: TObject);
begin
  allgombdisable;
  Egysegpanel.Caption := 'A TELJES HÁLÓZAT';
  _filtertipus := 0;
end;

procedure TForm1.KFTGOMBClick(Sender: TObject);
begin
  AllgombDisable;
  ChooseKft;
end;

procedure TForm1.KORZETGOMBClick(Sender: TObject);
begin
  Allgombdisable;
  chooseKorzet;
end;

procedure TForm1.PENZTARGOMBClick(Sender: TObject);
begin
  AllGombDisable;
  choosePenztar;
end;


procedure TForm1.ChoosePenztar;

var _y: byte;

begin
  PenztarLista.Items.clear;
  _y := 1;
  while _y<=_penztardarab do
    begin
      _aktptn := _ptnevsor[_y];
      _aktpt  := _ptnumsor[_y];
      _tetels  := nul3(_aktpt)+'. '+_aktptn;
      PenztarLista.Items.Add(_tetels);
      inc(_y);
    end;
  PenztarLista.ItemIndex := 0;

  with PenztarChoosePanel do
    begin
      Top := 8;
      Left := 96;
      Visible := True;
    end;
  ActiveControl := Penztarlista;  
end;


function TForm1.Nul3(_nn: byte): string;

begin
  result := inttostr(_nn);
  while length(result)<3 do result := '0' + result;
end;


procedure TForm1.ChooseKft;

begin
  with kftChoosePanel do
    begin
      Top := 200;
      left := 32;
      Visible := True;
    end;
  ActiveControl := BGomb;
end;


procedure TForm1.ChooseKorzet;

begin
  with KorzetChoosePanel do
    begin
      Top  := 224;
      Left := 144;
      Visible := true;
    end;
  Activecontrol := k1gomb;

END;


procedure TForm1.k1gombClick(Sender: TObject);
begin
  _korzetss := TBitbtn(sender).Tag;
  KorzetChoosePanel.Visible := False;
  if _korzetss=0 then exit;

  _allgombclosed := True;
  KorzetGomb.Color := clYellow;
  EgysegPanel.Caption := _korzetnev[_korzetss]+'I KORZET';
  _kellkorzet  := _korzetszam[_korzetss];
  _FilterTipus := 2;
end;

procedure TForm1.BGOMBClick(Sender: TObject);
begin
  _kftss := TBitbtn(sender).tag;
  KftChoosePanel.Visible := False;
  if _kftss=0 then exit;

  _allgombclosed := True;
  KftGomb.Color := clYellow;
  EgysegPanel.Caption := 'EXCLUSIVE '+_kftnev[_kftss]+' CHANGE';

  _kftbetu := leftstr(_kftnev[_kftss],1);
  _filterTipus := 1;

end;

procedure TForm1.PENZTARLISTADblClick(Sender: TObject);
begin
   PenztartValasztott;
end;



procedure TForm1.PenztartValasztott;

begin
  _tetss := PenztarLista.itemindex;
  _aktTetel := PenztarLista.items[_tetss];
  PenztarChoosePanel.Visible := false;
  _aktpenztarnums := leftstr(_akttetel,3);
  val(_aktpenztarnums,_kellpenztar,_code);
  if _code<>0 then _aktpenztar := 0;
  if _kellpenztar=0 then exit;

  _allgombclosed := True;
  Egysegpanel.Caption := _akttetel;
  Penztargomb.Color := clYellow;
  _filtertipus := 3;
end;


procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  PenztarchoosePanel.Visible := False;
end;

procedure TForm1.UJSZAMOLASGOMBClick(Sender: TObject);
begin
  AllGombEnable;
  AllgombClear;
  _Allgombclosed := false;
  _vevoszam := 0;
  _filtertipus := 0;

  Vevopanel.caption := '0 FÕ';
  VevoPanel.Color := clWhite;
  VevoShape.Brush.Color := clwhite;
  VevoPanel.Font.color := clBlack;
  VevoPanel.Repaint;

  EgysegPanel.Caption := '';
  PenztarPanel.Caption := '';
  DatumPanel.Caption := '';
  Penztarcsik.Position := 0;
  Rekordcsik.Position := 0;

  Startgomb.Enabled := true;


end;

procedure TForm1.PENZTARLISTAKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ord(key)<>13 then exit;
  PenztartValasztott;
end;

end.
