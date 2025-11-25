unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, comobj,TlHelp32, dateutils;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    HONAPCOMBO: TComboBox;
    EVCOMBO: TComboBox;
    DATUMPANEL: TPanel;
    HOOKEGOMB: TBitBtn;
    KILEPOGOMB: TBitBtn;
    Shape1: TShape;
    Shape2: TShape;
    Label2: TLabel;

    procedure Button1Click(Sender: TObject);
 
    function Nulele(_b: byte): string;
    procedure FormActivate(Sender: TObject);
    function TabDekoder(_akttabpath: string): boolean;
    function Getbyte: byte;
    function Getword: word;
    function Getreal: real;
    function Getstring: string;
    function GetInteger: Integer;
 
    procedure ExcelKill;
    procedure MakeExcel;
    procedure HOOKEGOMBClick(Sender: TObject);
    procedure EVCOMBOChange(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  _bytetomb: array[1..4096] of byte;
  _etarak: array[1..8] of byte = (10,20,40,50,63,75,120,145);
  _tabalap,_ids,_rangestr,_kertevhos: string;
  _kertev,_kertho: word;
  _ok,_vanexcel: boolean;
  _binolvas: file of byte;
  _tablonap,_pt,_penztardarab,_penztarszazalek,_lastday,_nn,_vk: byte;
  _napivetel,_napieladas: array[1..31] of real;
  _num: real;
  _cc,_a,_b,_c,_ptn,_nap,_sor,_osz,_utolsonap: byte;
  _vchf,_echf,_veur,_eeur,_vusd,_eusd,_vgbp: array[1..31] of real;
  _egbp,_vron,_eron,_vhrk,_ehrk: array[1..31] of real;
  _controlsum,_v,_e,_aktvv,_aktve: integer;
  _OXL,_owb: variant;
  proc : PROCESSENTRY32;
  _handle : HWND;
  _Looper : BOOL;
  _vv,_ve: array[1..6] of integer;
  _top,_height,_left,_width,_aktev,_aktho: word;

  _HONAPNEV: array[1..12] of string = ('JANUÁR','FEBRUÁR','MÁRCIUS','ÁPRILIS',
                 'MÁJUS','JÚNIUS','JÚLIUS','AUGUSZTUS','SZEPTEMBER','OKTÓBER',
                                    'NOVEMBER','DECEMBER');


implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  if _vanexcel then
    begin
      _oxl.Quit;
      _oxl :=Unassigned;
    end;

  ExcelKill;

  Application.Terminate;
end;

procedure TForm1.FormActivate(Sender: TObject);

var i: integer;

begin
  _height := screen.Monitors[0].Height;
  _width  := Screen.Monitors[0].Width;

  _top := trunc((_height - 285)/2);
  _left:= trunc((_width-407)/2);

  Top := _top;
  Left := _left;

  _vanexcel := False;
  _utolsonap := 0;

  for i := 1 to 31 do
    begin
      _napivetel[i] := 0;
      _napieladas[i]:= 0;

      _vchf[i] := 0;
      _echf[i] := 0;

      _veur[i] := 0;
      _eeur[i] := 0;

      _vusd[i] := 0;
      _eusd[i] := 0;

      _vron[i] := 0;
      _eron[i] := 0;

      _vgbp[i] := 0;
      _egbp[i] := 0;

      _vhrk[i] := 0;
      _ehrk[i] := 0;
   end;

  _aktev := yearof(date);
  _aktho := monthof(date);

  evcombo.Items.clear;
  honapcombo.Items.Clear;

  for i := 1 to 12 do honapcombo.Items.add(_honapnev[i]);
  for i := 0 to 4 do evcombo.Items.add(inttostr(_aktev-i));

  evcombo.ItemIndex := 0;
  honapcombo.ItemIndex := _aktho-1;

  Activecontrol := HoOkegomb;
end;


procedure TForm1.HOOKEGOMBClick(Sender: TObject);

var _etarss: byte;
    _aktetar: byte;
    _tabname,_tabpath: string;


begin
  _kertev := _aktev - (evcombo.ItemIndex);
  _kertho := (honapcombo.ItemIndex) + 1;
  Datumpanel.Caption := inttostr(_kertev)+' '+ _honapnev[_kertho];
  DatumPanel.Repaint;

  _kertevhos := inttostr(_kertev)+'.'+nulele(_kertho);
  _tabalap := 'TAB_'+inttostr(_kertev-2000)+nulele(_kertho);
  _etarss :=1;
  while _etarss<=8 do
    begin
      _aktetar := _etarak[_etarss];
      _tabname := _tabalap + '.' + inttostr(_aktetar);
      _tabpath := 'c:\receptor\mail\tablo\' + _tabname;
      if not fileexists(_tabpath) then
        begin
          ShowMessage('NINCS ADAT A KÉRT HÓNAPRÓL');
          exit;
        end;
      _ok := Tabdekoder(_tabpath);
      inc(_etarss);
    end;

  MakeExcel;
end;



// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
            function TForm1.TabDekoder(_akttabpath: string): boolean;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


//  A tabló-file dekódólása adatokká


begin
  Result := False;

  // Megnyitja a kódolt Tablo-file-t:

  AssignFile(_binolvas,_akttabpath);
  Reset(_binolvas);

  //  Beolvassa a tablófile identitás-kódját = 'NT'

  Blockread(_binolvas,_bytetomb,2);
  _ids := chr(_bytetomb[1])+chr(_bytetomb[2]);
  if _ids<>'NX' then
    begin
      Closefile(_binolvas);
      exit;
    end;

  // ------------- Ez az utolsó nap a tablóban  --------------------------------

  _tabloNap := GetByte;
  // _tabloDatums := inttostr(_aktev)+'.'+nulele(_aktho)+'.'+nulele(_tablonap);

  // ------------ Ennyi pénztár van a körzetben --------------------------------

  _penztardarab := GetByte;

  // ----------- Végigmegy a körzet pénztárain ---------------------------------

  _pt := 1;
  while _pt<=_penztardarab do
    begin

      // ----- Beolvassa a pénztár számát a pénztárszámok tömbjébe -------------

      _ptn := Getbyte;  // penztarszam

     // _penztarSzamok[_pt] := _penztarszam;

      // ----- Elözõ havi adatok 1..150 megfelelö tömbjébe ---------------------

      GetByte;   //  _elozoHavimunkanapok[_pt]
      GetReal;   //  _elozoHaviVetel[_pt]
      GetReal;   //  _elozoHaviEladas[_pt]
      GetWord;   //  _elozohaviVugyfel[_pt]
      GetWord;   //  _elozohaviEugyfel[_pt]

      // ------- Az aktuális havi munkanap az aktuális pénztár tömbjében -------

      GetByte;    // _HaviMunkanapok[_pt]

      // Ennek a pénztárnak az utolsómunkanapja --------------------------------

      _lastDay                  := GetByte;
      if _lastday>_utolsonap then _utolsonap := _lastday;

      // _utolsolezartnap[_pt]     := _lastDay;

      // ------------- Az összes munkanap adatainak tömbbe olvasása ------------

      _nn := 1;
      while _nn<=_lastDay do
        begin
          // Az aktuális pénztár, aktuális napi vétel- és eladás forgalma ------

          _num := Getreal;
          _napivetel[_nn] := _napivetel[_nn] + _num;

           _num := Getreal;
          _napieladas[_nn] := _napieladas[_nn] + _num;


          // ------- Az aktuális nap vételi és eladási ügyfelei ----------------

          GetWord;  //  _vetelugyfeldarab[_pt,_nn]  :=
          GetWord;  //  _eladasugyfelDarab[_pt,_nn] :=

          // --------- Az adott napon dolgozó ID-kódja  ------------------------

          GetString;    //  _penztarosId[_pt,_nn] :=

          // ------------ ---  A napi vétel/eladás az 6 fõ devizánál: ----------

          _num := Getreal;
          _vchf[_nn] := _vchf[_nn] + _num;

           _num := Getreal;
          _echf[_nn] := _echf[_nn] + _num;

           _num := Getreal;
          _veur[_nn] := _veur[_nn] + _num;

           _num := Getreal;
          _eeur[_nn] := _eeur[_nn] + _num;

           _num := Getreal;
          _vgbp[_nn] := _vgbp[_nn] + _num;

           _num := Getreal;
          _egbp[_nn] := _egbp[_nn] + _num;

          _num := Getreal;
          _vhrk[_nn] := _vhrk[_nn] + _num;

           _num := Getreal;
          _ehrk[_nn] := _ehrk[_nn] + _num;

           _num := Getreal;
          _vusd[_nn] := _vusd[_nn] + _num;

           _num := Getreal;
          _eusd[_nn] := _eusd[_nn] + _num;

          _num := Getreal;
          _vron[_nn] := _vron[_nn] + _num;

           _num := Getreal;
          _eron[_nn] := _eron[_nn] + _num;

          inc(_nn);
        end;


     //  ----------- A valuták készleteinek beolvasása -------------------------

      _vk := 1;
      while _vk<=27 do
        begin

          //  --- A 24 valuta nyitó és záró készletei az utolsó munkanapon -----

          getinteger;   //  _nyitokeszlet[_pt,_vv] :=
          getinteger;   //  _zarokeszlet[_pt,_vv]  :=

          _cc := 1;

          //_csor := '';

          // -------- Az aktuális valuta 14 cimletének beolvasása --------------

          while _cc<=14 do
            begin
              getword;     //        _cm :=

              // _hi := trunc(_cm/256);
              // _lo := _cm-trunc(256*_hi);
              // _csor := _csor + chr(_lo)+chr(_hi);

              inc(_cc);
            end;

          //  _cimletsor[_pt,_vv] := _csor;

          inc(_vk);

        end;

      // ---------- Az adott pénztár w.u. és afa készlete ----------------------

      getinteger;   //      _wuniusd[_pt] :=
      getinteger;   //      _wunihuf[_pt] :=
      getinteger;   //      _afahuf[_pt]  :=

      Getreal; //      _evChf[_pt] :=
      Getreal; //      _eeChf[_pt] :=
      Getreal; //      _evEur[_pt] :=
      Getreal; //      _eeEur[_pt] :=
      Getreal; //      _evGbp[_pt] :=
      Getreal; //      _eeGbp[_pt] :=
      Getreal; //      _evHrk[_pt] :=
      Getreal; //      _eeHrk[_pt] :=
      Getreal; //      _evUsd[_pt] :=
      Getreal; //      _eeUsd[_pt] :=
      Getreal; //      _evRon[_pt] :=
      Getreal; //      _eeRon[_pt] :=

      GetInteger;   //   _euerme[_pt] :=
      inc(_pt);
    end;

  // -------------- A kontrolsumma ellenörzése ---------------------------------

  _a := Getbyte;
  _b := Getbyte;
  _c := Getbyte;

  _controlsum := _a +_b +_c;
  Closefile(_binolvas);
  if _controlsum=765 then  result := True;

end;


function Tform1.Nulele(_b: byte): string;

begin
  result := inttostr(_b);
  if _b<10 then result := '0' + result;
end;






// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                        function TForm1.getbyte: byte;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

begin
  blockread(_binolvas,_bytetomb,1);
  result := _bytetomb[1];
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                   function TForm1.Getword: word;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

var _lo,_hi: byte;

begin
  Blockread(_binolvas,_bytetomb,2);
  _lo := _bytetomb[1];
  _hi := _bytetomb[2];
  result := _lo + trunc(256*_hi);
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                      function TForm1.GetInteger: Integer;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

var _lo,_hi,_hlo,_hhi: byte;

begin
  Blockread(_binolvas,_bytetomb,4);
  _lo := _bytetomb[1];
  _hi := _bytetomb[2];
  _hlo:= _bytetomb[3];
  _hhi:= _bytetomb[4];
  result := _lo + trunc(256*_hi)+trunc(65536*_hlo)+trunc(_hhi*16777216);
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                       function TForm1.GetReal: real;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§

var _lo,_hi,_hlo,_hhi: byte;

begin
  Blockread(_binolvas,_bytetomb,4);
  _lo := _bytetomb[1];
  _hi := _bytetomb[2];
  _hlo:= _bytetomb[3];
  _hhi:= _bytetomb[4];
  result := _lo + (256*_hi)+(65536*_hlo)+(_hhi*16777216);
end;

// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§
                         function TForm1.getstring: string;
// §§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§§


var _len,_y,_kod: byte;

begin
  result := '';
  Blockread(_binolvas,_bytetomb,1);
  _len := _bytetomb[1];
  if _len=0 then exit;

  Blockread(_binolvas,_bytetomb,_len);
  _y := 1;
  while _y<=_len do
    begin
      _kod := 255 - _bytetomb[_y];
      result := result + chr(_kod);
      inc(_y);
    end;
end;


procedure TForm1.MakeExcel;

var i,_y: integer;

begin

  _oxl := CreateOleObject('Excel.Application');
  _owb := _oxl.workbooks.add[1];

  _oxl.Range['A3:O35'].HorizontalAlignment := -4108;

  _rangestr := 'B5:O35';
  _oxl.range[_RANGESTR].NumberFormat := '### ### ###';

  _oxl.Range['A1:A1'].columnWidth := 12;
  _oxl.Range['B1:B1'].columnWidth := 12;
  _oxl.Range['C1:C1'].columnWidth := 12;
  _oxl.Range['D1:D1'].columnWidth := 12;
  _oxl.Range['E1:E1'].columnWidth := 12;
  _oxl.Range['F1:F1'].columnWidth := 12;
  _oxl.Range['G1:G1'].columnWidth := 12;
  _oxl.Range['H1:H1'].columnWidth := 12;
  _oxl.Range['I1:I1'].columnWidth := 12;
  _oxl.Range['J1:J1'].columnWidth := 12;
  _oxl.Range['K1:K1'].columnWidth := 12;
  _oxl.Range['L1:L1'].columnWidth := 12;
  _oxl.Range['M1:M1'].columnWidth := 12;
  _oxl.Range['N1:N1'].columnWidth := 12;
  _oxl.Range['O1:O1'].columnWidth := 12;

  _oxl.Range['D3:E3'].MergeCells := True;
  _oxl.Range['F3:G3'].MergeCells := True;
  _oxl.Range['H3:I3'].MergeCells := True;
  _oxl.Range['J3:K3'].MergeCells := True;
  _oxl.Range['L3:M3'].MergeCells := True;
  _oxl.Range['N3:o3'].MergeCells := True;

  _rangestr := 'A3:A4';
  _oxl.Range[_rangestr].MergeCells := True;
  _oxl.Range[_rangestr].VerticalAligNment := -4108;
  _oxl.Range[_rangestr].Font.Bold := True;

  _rangestr := 'B3:B4';
  _oxl.Range[_rangestr].MergeCells := True;
  _oxl.Range[_rangestr].VerticalAlignment := -4108;
  _oxl.Range[_rangestr].Font.Bold := True;

  _rangestr := 'C3:C4';
  _oxl.Range[_rangestr].MergeCells := True;
  _oxl.Range[_rangestr].VerticalAlignment := -4108;
  _oxl.Range[_rangestr].Font.Bold := True;

   _oxl.Range['D3:N3'].Font.Bold := True;

   _oxl.cells[3,1] := 'DÁTUM';
   _oxl.cells[3,2] := 'VÁSÁRLÁS';
   _oxl.cells[3,3] := 'ELADÁS';
   _oxl.cells[3,4] := 'SVÁJCI FRANK';
   _oxl.cells[3,6] := 'EURÓ';
   _oxl.cells[3,8] := 'ANGOL FONT';
   _oxl.cells[3,10]:= 'HORVÁT KUNA';
   _oxl.cells[3,12]:= 'USA DOLLÁR';
   _oxl.cells[3,14]:= 'ROMÁN LEI';

   _oxl.cells[4,4]:= 'VÉTEL';
   _oxl.cells[4,5]:= 'ELADÁS';

   _oxl.cells[4,6]:= 'VÉTEL';
   _oxl.cells[4,7]:= 'ELADÁS';

   _oxl.cells[4,8]:= 'VÉTEL';
   _oxl.cells[4,9]:= 'ELADÁS';

   _oxl.cells[4,10]:= 'VÉTEL';
   _oxl.cells[4,11]:= 'ELADÁS';

   _oxl.cells[4,12]:= 'VÉTEL';
   _oxl.cells[4,13]:= 'ELADÁS';

   _oxl.cells[4,14]:= 'VÉTEL';
   _oxl.cells[4,15]:= 'ELADÁS';

   // ---------------------------------------

   _nap := 1;
   while _nap<=_utolsonap do
     begin
       _sor := 4 + _nap;
       i := _nap;

       _oxl.cells[_sor,1] := _kertevhos+'.'+nulele(_nap);

       _v := trunc(_napivetel[_nap]);
       _e := trunc(_napieladas[_nap]);

       _vv[1] := trunc(_vchf[i]);
       _ve[1] := trunc(_echf[i]);

       _vv[2] := trunc(_veur[i]);
       _ve[2] := trunc(_eeur[i]);

       _vv[3] := trunc(_vgbp[i]);
       _ve[3] := trunc(_egbp[i]);

       _vv[4] := trunc(_vhrk[i]);
       _ve[4] := trunc(_ehrk[i]);

       _vv[5] := trunc(_vusd[i]);
       _ve[5] := trunc(_eusd[i]);

       _vv[6] := trunc(_vron[i]);
       _ve[6] := trunc(_eron[i]);

       if _v>0 then _oxl.cells[_sor,2] := inttostr(_v);
       if _e>0 then _oxl.cells[_sor,3] := inttostr(_e);

       _y := 1;
       while _y<=6 do
         begin
           _aktvv := _vv[_y];
           _osz :=  2+trunc(2*_y);
           if _aktvv>0 then _oxl.cells[_sor,_osz] := inttostr(_aktvv);

           _aktve := _ve[_y];
           if _aktve>0 then _oxl.cells[_sor,_osz+1] := inttostr(_aktve);

           inc(_y);
         end;
       inc(_nap);
     end;

   // ---------------------------------------

   _oxl.visible := true;
   _vanexcel := true;

END;


// =============================================================================
                  procedure TForm1.ExcelKill;
// =============================================================================


var
  _fileName,_filePath: String;

begin

  Proc.dwSize := SizeOf(Proc);
  _handle := CreateToolhelp32Snapshot(TH32CS_SNAPALL,0);
  _Looper := Process32First(_handle,proc);

  while Integer(_Looper) <> 0 do
    begin
      _filepath := Proc.szExeFile;
      _fileName := UpperCase(ExtractFileName(_filepath));

      if _fileName = 'EXCEL.EXE' then
        begin
          TerminateProcess(OpenProcess(1,Bool(1),proc.th32ProcessID),0);
          break;
        end;

      _Looper := Process32Next(_handle,proc);
    end;
  CloseHandle(_handle);
end;



procedure TForm1.EVCOMBOChange(Sender: TObject);
begin
  ActiveControl := Hookegomb;
end;

end.
